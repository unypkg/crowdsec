#!/usr/bin/env bash
# shellcheck disable=SC2034,SC1091,SC2154

set -vx

######################################################################################################################
### Setup Build System and GitHub

##apt install -y autopoint

wget -qO- uny.nu/pkg | bash -s buildsys

### Installing build dependencies
unyp install go re2/2023.03.01 abseil-cpp/20220623.1 git sqlite
#icu

#pip3_bin=(/uny/pkg/python/*/bin/pip3)
#"${pip3_bin[0]}" install --upgrade pip
#"${pip3_bin[0]}" install docutils pygments

### Getting Variables from files
UNY_AUTO_PAT="$(cat UNY_AUTO_PAT)"
export UNY_AUTO_PAT
GH_TOKEN="$(cat GH_TOKEN)"
export GH_TOKEN

source /uny/git/unypkg/fn
uny_auto_github_conf

######################################################################################################################
### Timestamp & Download

uny_build_date

mkdir -pv /uny/sources
cd /uny/sources || exit

pkgname="crowdsec"
pkggit="https://github.com/crowdsecurity/crowdsec.git refs/tags/*"
gitdepth="--depth=1"

### Get version info from git remote
# shellcheck disable=SC2086
latest_head="$(git ls-remote --refs --tags --sort="v:refname" $pkggit | grep -E "v[0-9.]+$" | tail --lines=1)"
latest_ver="$(echo "$latest_head" | grep -o "v[0-9.].*" | sed "s|v||")"
latest_commit_id="$(echo "$latest_head" | cut --fields=1)"

version_details

# Release package no matter what:
echo "newer" >release-"$pkgname"

git_clone_source_repo

cd "$pkg_git_repo_dir" || exit
make BUILD_STATIC=1 vendor
rm -fv vendor.tgz
cd /uny/sources || exit

keep_git_dir=yes

archiving_source

######################################################################################################################
### Build

# unyc - run commands in uny's chroot environment
# shellcheck disable=SC2154
unyc <<"UNYEOF"
set -vx
source /uny/git/unypkg/fn

pkgname="crowdsec"

version_verbose_log_clean_unpack_cd
get_env_var_values
get_include_paths

####################################################
### Start of individual build script

#unset LD_RUN_PATH

make DEFAULT_CONFIGDIR=/etc/uny/crowdsec BUILD_VERSION=v"$pkgver" build #BUILD_STATIC=1
#make BUILD_VERSION=v"$pkgver" -j"$(nproc)" test

dest_dir="/uny/pkg/$pkgname/$pkgver"

mkdir -pv "$dest_dir"/cmd/{crowdsec,crowdsec-cli}
cp -a cmd/crowdsec/crowdsec "$dest_dir"/cmd/crowdsec/
cp -a cmd/crowdsec-cli/cscli "$dest_dir"/cmd/crowdsec-cli/

for plugin in cmd/notification-*/notification-*; do
    base_name="$(basename "$plugin")"
    plugin_name="${base_name/notification-/}"
    mkdir -p "$dest_dir"/cmd/"$base_name"
    cp -a "$plugin" "$dest_dir"/cmd/"$base_name"/
    cp -a cmd/"$base_name"/"$plugin_name".yaml "$dest_dir"/cmd/"$base_name"/
done

sed -r "s|=/bin/(.*)|=/usr/bin/env bash -c \"\1\"|" -i config/crowdsec.service
sed '/\[Install\]/a\' -e 'Alias=crowdsec.service cs.service' -i config/crowdsec.service
mv -v config/crowdsec.service config/uny-crowdsec.service

cp -a config "$dest_dir"/
find "$dest_dir"/config/ -type f -exec sed -i -e "s|/etc/crowdsec|/etc/uny/crowdsec|g" -e "s|/usr/local|/uny/pkg/$pkgname/$pkgver|g" {} +
sed "s|listen_uri: 127.0.0.1:8080|listen_uri: 127.0.0.1:6066|" -i "$dest_dir"/config/config.yaml

cp -a scripts "$dest_dir"/

cp -a wizard.sh "$dest_dir"/
sed -e "s|CROWDSEC_USR_DIR=.*|CROWDSEC_USR_DIR=$dest_dir|" \
    -e "s|BIN_INSTALL_PATH=.*|BIN_INSTALL_PATH=$dest_dir/bin|" \
    -e "s|/etc/crowdsec|/etc/uny/crowdsec|g" \
    -e "s|crowdsec.service|uny-crowdsec.service|g" \
    -i "$dest_dir"/wizard.sh

####################################################
### End of individual build script

add_to_paths_files
dependencies_file_and_unset_vars
cleanup_verbose_off_timing_end
UNYEOF

######################################################################################################################
### Packaging

package_unypkg
