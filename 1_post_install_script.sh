#!/usr/bin/env bash
# shellcheck disable=SC2034,SC1091,SC2154,SC1003,SC2005

current_dir="$(pwd)"
unypkg_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
unypkg_root_dir="$(cd -- "$unypkg_script_dir"/.. &>/dev/null && pwd)"

cd "$unypkg_root_dir" || exit

#############################################################################################
### Start of script

CROWDSEC_LIB_DIR="/var/lib/crowdsec"
CROWDSEC_USR_DIR="$unypkg_root_dir"
CROWDSEC_DATA_DIR="${CROWDSEC_LIB_DIR}/data"
CROWDSEC_DB_PATH="${CROWDSEC_DATA_DIR}/crowdsec.db"
CROWDSEC_CONFIG_PATH="/etc/uny/crowdsec"
CROWDSEC_PLUGIN_DIR="${CROWDSEC_USR_DIR}/plugins"
CROWDSEC_CONSOLE_DIR="${CROWDSEC_CONFIG_PATH}/console"

if [[ ! -d /etc/uny/crowdsec ]]; then
    cd etc || exit
    find patterns -type f -exec install -Dm 644 "{}" "${CROWDSEC_CONFIG_PATH}/{}" \;
    cd ../ || exit

    mkdir -pv "${CROWDSEC_CONFIG_PATH}"/{acquis.d,scenarios,postoverflows,collections,patterns,appsec-configs,appsec-rules,contexts,notifications,hub,console}
    mkdir -pv /tmp/data

    install -v -m 600 -D etc/local_api_credentials.yaml "${CROWDSEC_CONFIG_PATH}"
    install -v -m 600 -D etc/online_api_credentials.yaml "${CROWDSEC_CONFIG_PATH}"
    install -v -m 600 -D etc/config.yaml "${CROWDSEC_CONFIG_PATH}"
    install -v -m 644 -D etc/dev.yaml "${CROWDSEC_CONFIG_PATH}"
    install -v -m 644 -D etc/user.yaml "${CROWDSEC_CONFIG_PATH}"
    install -v -m 644 -D etc/acquis.yaml "${CROWDSEC_CONFIG_PATH}"
    install -v -m 644 -D etc/profiles.yaml "${CROWDSEC_CONFIG_PATH}"
    install -v -m 644 -D etc/simulation.yaml "${CROWDSEC_CONFIG_PATH}"
    install -v -m 644 -D etc/console.yaml "${CROWDSEC_CONFIG_PATH}"
    install -v -m 644 -D etc/context.yaml "${CROWDSEC_CONSOLE_DIR}"

    for yaml in plugins/*.yaml; do
        mv -v "$yaml" "${CROWDSEC_CONFIG_PATH}"/notifications/
    done
fi

for plugin in bin/notification-*; do
    cp -a "$plugin" plugins/
done

sed -r "s|=/bin/(.*)|=/usr/bin/env bash -c \"\1\"|" -i etc/crowdsec.service
cp -a etc/crowdsec.service /etc/systemd/system/uny-crowdsec.service
#sed "s|.*Alias=.*||g" -i /etc/systemd/system/uny-mariadb.service
sed -e '/\[Install\]/a\' -e 'Alias=crowdsec.service' -i /etc/systemd/system/uny-crowdsec.service
systemctl daemon-reload

#############################################################################################
### End of script

cd "$current_dir" || exit
