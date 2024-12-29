#!/usr/bin/env bash
# shellcheck disable=SC2034,SC1091,SC2154,SC1003,SC2005

current_dir="$(pwd)"
unypkg_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
unypkg_root_dir="$(cd -- "$unypkg_script_dir"/.. &>/dev/null && pwd)"

cd "$unypkg_root_dir" || exit

#############################################################################################
### Start of script

./wizard.sh -i

systemctl disable crowdsec
systemctl stop crowdsec

mv -f /etc/systemd/system/crowdsec.service /etc/systemd/system/uny-crowdsec.service
sed "s|.*Alias=.*||g" -i /etc/systemd/system/uny-mariadb.service
sed -e '/\[Install\]/a\' -e 'Alias=crowdsec.service' -i /etc/systemd/system/uny-crowdsec.service
systemctl daemon-reload

#############################################################################################
### End of script

cd "$current_dir" || exit
