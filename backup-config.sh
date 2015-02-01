#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Back up some system and personal configuration files.

OPTIONS
-h  Help"
	exit $1
}

while getopts "h" V_ARG ; do
	case $V_ARG in
		h)	usage 1 ;;
		?)	usage 2 ;;
	esac
done

V_LINUX_VERSION=$(lsb_release -d -s | sed 's/ /-/g')
V_CONFIG_DIR=$G_DROPBOX_DIR/linux/$HOSTNAME-$V_LINUX_VERSION
mkdir -p $V_CONFIG_DIR

save_if_needed() {
	V_FILE=$1
	V_MESSAGE=$2
	V_CMD=$3

	V_EXTENSION="${V_FILE##*.}"
	V_FULL_PATH="$V_CONFIG_DIR/$V_FILE"

	# Let's create the file if:
	# - it doesn't exist, or
	# - it was last modified a while ago (more than 2 days).
	if [ ! -f $V_FULL_PATH ] || [ -z "$(find $V_FULL_PATH -type f -mmin -2880 2>/dev/null)" ] ; then
		echo "Saving $V_MESSAGE in $V_FULL_PATH"
		if [ "$V_EXTENSION" = 'txt' ] ; then
			eval $V_CMD &> $V_FULL_PATH
		else
			eval $V_CMD
		fi
	fi
}

save_if_needed etc-all.tar "all configuration files from /etc" "sudo tar -czf $V_CONFIG_DIR/etc-all.tar -C / etc"

echo "Saving some config files (bash, git, beets) in $V_CONFIG_DIR"
cp -ruvL ~/.bash* ~/.config/beets/config.yaml ~/.git* $V_CONFIG_DIR

save_if_needed ifconfig.txt "IP and Ethernet configuration" "ifconfig -a -v"
save_if_needed dpkg-get-selections.txt "list of installed packages" "dpkg --get-selections"
save_if_needed apt-get-install-manual.txt "list of manually installed packages" "cat ~/.bash_history | grep 'apt-get install' | grep -v grep | cut -b 22- | sed -e 's/ \+/\n/g' | sort -u"
save_if_needed apt-key-exportall.txt "keys" "apt-key exportall"

V_IGNORE_LIST='.teamviewer;google-chrome;chromium;.pulse;share;.adobe;.kde;autostart'
V_IMPLODE_IGNORE_LIST="-wholename */${V_IGNORE_LIST//;/\/* -or -wholename *\/}/*"
save_if_needed symbolic-links.txt "symbolic links" "find ~ -type l -not \( $V_IMPLODE_IGNORE_LIST \) -exec ls -l --color=auto '{}' \;"
# [ -d "/net" ] && save_if_needed net-directory.txt "/net/ directory structure" "find /net/ -mindepth 2 -maxdepth 2 -type d | sort -u"
save_if_needed pip-freeze.txt "pip modules" "pip freeze --local"
save_if_needed user-crontab.txt "user crontab" "crontab -l"
save_if_needed gtimelog.tar "gtimelog files" "tar -czf $V_CONFIG_DIR/gtimelog.tar $HOME/.gtimelog/*"

V_FILES_TO_BACKUP="/etc/hosts /etc/crontab /etc/resolv.conf /etc/environment /etc/fstab /etc/lynx-cur/lynx.cfg /etc/apt/sources.list /etc/apt/sources.list.d/ /etc/samba/smb.conf /boot/grub/grub.cfg /etc/grub.d/40_custom /etc/default/couchpotato /etc/apache2/sites-available/* ~/.config/rubyripper/settings"
[ -f etc/crypttab ] && V_FILES_TO_BACKUP="$V_FILES_TO_BACKUP etc/crypttab"
save_if_needed etc.tar "some configuration files" "tar -czf $V_CONFIG_DIR/etc.tar -C / $V_FILES_TO_BACKUP"

# Pidgin log compression should be in the crontab someday
#pidgin-tar-logs.sh

echo "Done."
