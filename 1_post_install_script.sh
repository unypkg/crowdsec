#!/usr/bin/env bash
# shellcheck disable=SC2034,SC1091,SC2154,SC1003,SC2005

current_dir="$(pwd)"
unypkg_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
unypkg_root_dir="$(cd -- "$unypkg_script_dir"/.. &>/dev/null && pwd)"

cd "$unypkg_root_dir" || exit

#############################################################################################
### Start of script

if ! command -v envsubst >/dev/null; then
    unyp install gettext
    unyp system-install gettext
fi

[ -L /usr/bin/crowdsec ] && rm -f /usr/bin/crowdsec
[ -L /usr/bin/cscli ] && rm -f /usr/bin/cscli

./wizard.sh -i --unattended

#if [ ! -f /etc/systemd/system/uny-crowdsec.service ]; then
#    if systemctl is-active crowdsec -q; then
#        systemctl stop crowdsec
#        if systemctl is-enabled crowdsec -q; then
#            systemctl disable crowdsec
#        fi
#    fi
#fi

#cp -f config/crowdsec.service /etc/systemd/system/uny-crowdsec.service
#sed "s|.*Alias=.*||g" -i /etc/systemd/system/uny-crowdsec.service
#sed -e '/\[Install\]/a\' -e 'Alias=crowdsec.service cs.service' -i /etc/systemd/system/uny-crowdsec.service
#systemctl daemon-reload

#############################################################################################
### End of script

cd "$current_dir" || exit
