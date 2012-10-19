#!/bin/bash
sudo ls /etc/crontab &> /dev/null

V_LINUX_VERSION=$(lsb_release -d -s | sed 's/ /-/g')
V_CONFIG_DIR=~/Dropbox/linux/$HOSTNAME-$V_LINUX_VERSION
mkdir -p $V_CONFIG_DIR

echo "Saving some config files (bash, git, beets) in $V_CONFIG_DIR"
cp -ruvL ~/.bash* ~/.beetsconfig ~/.git* $V_CONFIG_DIR

V_FILE=$V_CONFIG_DIR/dpkg-get-selections.txt
echo "Saving list of installed packages in $V_FILE"
dpkg --get-selections &> $V_FILE

V_FILE=$V_CONFIG_DIR/apt-get-install-manual.txt
echo "Saving list of manually installed packages in $V_FILE"
cat ~/.bash_history | grep 'apt-get install' | grep -v grep | cut -b 22- | sed -e 's/ \+/\n/g' | sort | uniq &> $V_FILE

V_FILE=$V_CONFIG_DIR/apt-key-exportall.txt
echo "Saving keys in $V_FILE"
apt-key exportall &> $V_FILE

V_FILE=$V_CONFIG_DIR/symbolic-links.txt
echo "Gravando links simbolicos em $V_FILE"
V_IGNORE_LIST='.teamviewer;google-chrome;.pulse;share;.adobe;.kde;autostart'
V_IMPLODE_IGNORE_LIST="-wholename */${V_IGNORE_LIST//;/\/* -or -wholename *\/}/*"
find . -type l -not \( $V_IMPLODE_IGNORE_LIST \) -exec ls -l --color=auto '{}' \; &> $V_FILE

if [ -d "/net" ] ; then
	V_FILE=$V_CONFIG_DIR/net-directory.txt
	echo "Saving /net/ directory structure in $V_FILE"
	find /net/ -mindepth 2 -maxdepth 2 -type d | sort | uniq &> $V_FILE
fi

V_FILE=$V_CONFIG_DIR/pip-freeze.txt
echo "Saving pip modules in $V_FILE"
pip freeze --local &> $V_FILE

V_FILE=$V_CONFIG_DIR/user-crontab.txt
echo "Saving user crontab in $V_FILE"
crontab -l &> $V_FILE

V_FILE=$V_CONFIG_DIR/gtimelog.tar
echo "Backup do gtimelog em $V_FILE"
tar -czf $V_FILE $HOME/.gtimelog/*

V_FILE=$V_CONFIG_DIR/etc.tar
echo "Gravando arquivos de configuração em $V_FILE"
V_FILES_TO_BACKUP="/etc/hosts /etc/crontab /etc/resolv.conf /etc/environment /etc/fstab /etc/lynx-cur/lynx.cfg /etc/apt/sources.list /etc/apt/sources.list.d/ /etc/samba/smb.conf /boot/grub/grub.cfg /etc/grub.d/40_custom /etc/default/couchpotato /etc/apache2/sites-available/*"
[ -f etc/crypttab ] && V_FILES_TO_BACKUP="$V_FILES_TO_BACKUP etc/crypttab"
tar -czf $V_FILE -C / $V_FILES_TO_BACKUP

V_FILE=$V_CONFIG_DIR/etc-all.tar
echo "Backing up all configuration files from /etc in $V_FILE"
sudo tar -czf $V_FILE -C / etc

# Fazer isso so no cron...
#pidgin-tar-logs.sh

echo "Done."
