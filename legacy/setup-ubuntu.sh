#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Automated Ubuntu/Xubuntu setup for home and work computers.

Before executing this script for the first time:
- Install your flavor of Ubuntu in a PC or VM;
- Inside the VM, install also VBox Guest Additions (so you can share the host computer's directories) and activate USB devices.

How to restore packages:
sudo apt-get update
sudo apt-get dist-upgrade
dpkg --set-selections < dpkg-get-selections.txt
sudo dselect

-a  Execute all options below.
-r  Add and remove PPA repositories.
-u  Execute upgrade and dist-upgrade.
-i  Install/remove packages.
-h  Help"
	exit $1
}

V_ALL=
V_PPA=
V_UPDATE=
V_UPGRADE=
V_INSTALL_PACKAGES=
V_SYMBOLIC_LINKS=
V_SOMETHING_CHOSEN=
while getopts "aruilh" V_ARG ; do
	case $V_ARG in
	a)	V_ALL=1
		V_SOMETHING_CHOSEN=1 ;;
	r)	V_PPA=1
		V_SOMETHING_CHOSEN=1 ;;
	u)	V_UPGRADE=1
		V_SOMETHING_CHOSEN=1 ;;
	i)	V_INSTALL_PACKAGES=1
		V_SOMETHING_CHOSEN=1 ;;
	l)	V_SYMBOLIC_LINKS=1
		V_SOMETHING_CHOSEN=1 ;;
	h)	usage 1 ;;
	?)	usage 1 ;;
	esac
done

if [ -z $V_SOMETHING_CHOSEN ] ; then
	usage 2
fi

V_BASH_UTILS_DIR=$(dirname $0)

show_header() {
	echo '========================================================================================================================'
	echo $1
	echo '========================================================================================================================'
}

remove_comments() {
	echo "$1" | sed 's/#.\+//g' | tr -s '\n' ' '
}

show_error() {
	if [ $? -gt 0 ] ; then
		echo -e "${COLOR_LIGHT_RED}There was an error while ${1}.\nFix them before continuing.${COLOR_NONE}"

		# Abort only on package installation
		if [ -z "${2}" -o "${2}" == 'install' ] ; then
			exit
		fi
	fi
}

call_aptget() {
	V_ACTION=$1
	V_MESSAGE=$2
	V_PACKAGES=$(remove_comments "$3")

	for V_ONE_PACKAGE in $V_PACKAGES ; do
		# To avoid 'unable to locate' errors
		sudo apt-get --yes $V_ACTION $V_ONE_PACKAGE
	done

	if [ -n "$V_MESSAGE" ] ; then
		show_error $V_MESSAGE $V_ACTION
	fi
}

repo_partner() {
	V_PARTNER_REPO=/etc/apt/sources.list.d/canonical_partner.list
	if [ -z "$(grep -o 'saucy partner' $V_PARTNER_REPO 2>/dev/null)" ] ; then
		show_header "Adding Canonical partners repository"
		sudo sh -c "echo 'deb http://archive.canonical.com/ubuntu/ saucy partner' >> $V_PARTNER_REPO"
	fi
}

common_packages() {
	show_header 'Installing common packages'
	call_aptget install 'installing or upgrading some of the packages' "
		bash-completion nautilus-open-terminal synaptic gdebi gdebi-core alien gparted mutt curl wget wmctrl xdotool
			gconf-editor dconf-tools grub-customizer boot-repair tree tasksel rcconf samba system-config-samba
			iftop bum udisks
		xubuntu-desktop gnome-terminal indicator-weather indicator-workspaces python-wnck gnome-do
			indicator-multiload imwheel # Desktop
		sublime-text-installer vim vim-gui-common exuberant-ctags meld # Dev tools
		git git-core git-doc git-svn git-gui gitk
		python-pip python-dev python-matplotlib
		chromium-browser lynx-cur # Browser
		oracle-java8-installer # Java
		rhythmbox id3 id3tool id3v2 lame-doc easytag nautilus-script-audio-convert cd-discid cdparanoia flac lame
			mp3gain ruby-gnome2 vorbisgain eyed3 python-eyed3 soundconverter gstreamer0.10-plugins-ugly libcdio-utils
			k3b transcode nautilus-image-converter # Media
		y-ppa-manager unsettings # Tweak
		unace unrar zip unzip p7zip-full p7zip-rar sharutils rar uudeview mpack lha arj cabextract
			file-roller # Archive tools
		keepassx gtimelog backintime-gnome gtg tmux htop calibre # Util

		indicator-messages pidgin pidgin-awayonlock pidgin-data pidgin-extprefs pidgin-guifications pidgin-hotkeys
			pidgin-lastfm pidgin-libnotify pidgin-otr pidgin-plugin-pack pidgin-ppa pidgin-privacy-please
			pidgin-themes pidgin-dev pidgin-dbg
			pidgin-skype # Pidgin plugin: http://askubuntu.com/a/9068

		gimp gimp-data gimp-plugin-registry gimp-data-extras
		handbrake-cli handbrake-gtk
		sqlite3
		postfix
		filezilla"
}

purge_packages() {
	show_header 'Purging unused packages (not used at home neither at work), one at a time, and ignoring eventual errors'
	call_aptget purge '' "gnome-panel gnome-shell gnome-session-fallback gnome-tweak-tool docker kdebase-workspace-bin # Gnome
		ubuntuone-client ubuntuone-client-gnome ubuntuone-control-panel ubuntuone-couch ubuntuone-installer # Ubuntu One
		gwibber gwibber-service gwibber-service-facebook gwibber-service-identica gwibber-service-twitter libgwibber-gtk2 libgwibber2 # Gwibber
		empathy empathy-common nautilus-sendto-empathy # Empathy
		tagtool wallch subdownloader rubyripper cortina # Media
		thunderbird gcstar
		classicmenu-indicator recoll # Unity
		keepass2 ubuntu-tweak # Util
		php5-cli php-pear php5-xsl apache2-utils graphviz graphviz-doc phpmyadmin php5-sqlite php-apc php5-intl php5-xdebug
		mysql-client mysql-common mysql-server mysql-workbench libmysqlclient-dev libmysqlclient18
		subversion
		php5-curl php5-dev jenkins
		mongodb-clients
		openjdk-6-jre icedtea6-plugin # Java
		sabnzbdplus sabnzbdplus-theme-mobile transmission # Torrent
		ejecter unity-lens-pidgin recoll-lens unity-lens-utilities unity-scope-calculator google-chrome-stable non-free-codecs # Unable to locate
		$(dpkg --get-selections | grep -e lubuntu -e openbox | cut -f 1) # Removing LUbuntu e OpenBox"
}

if [ -n "$V_ALL" ] || [ -n "$V_PPA" ] ; then
	V_OLD_IFS="$IFS"
	IFS='
'
	V_PPA_REMOVE='
deb http://download.virtualbox.org/virtualbox/debian precise contrib
deb http://pkg.jenkins-ci.org/debian binary/
deb http://ppa.launchpad.net/geod/ppa-geod/ubuntu natty main
ppa:aheck/ppa
ppa:atareao/atareao
ppa:cs-sniffer/cortina
ppa:diesch/testing
ppa:do-testers/ppa
ppa:gcstar/ppa
ppa:indicator-multiload/stable-daily
ppa:jcfp/ppa
ppa:recoll-backports/recoll-1.15-on
ppa:scopes-packagers/ppa
ppa:tualatrix/ppa
ppa:webupd8team/rhythmbox
ppa:webupd8team/sublime-text-2
'
	for V_PPA in $V_PPA_REMOVE ; do
		show_header "Removing repository $V_PPA"
		sudo add-apt-repository --remove --yes $V_PPA
	done

	V_PPA_INSTALL='
deb http://ppa.launchpad.net/do-testers/ppa/ubuntu precise main
deb http://ppa.launchpad.net/midnightflash/ppa/ubuntu natty main
deb http://ppa.launchpad.net/stebbins/handbrake-releases/ubuntu oneiric main
ppa:danielrichter2007/grub-customizer
ppa:git-core/ppa
ppa:indicator-multiload/daily
ppa:pidgin-developers/ppa
ppa:videolan/stable-daily
ppa:webupd8team/java
ppa:webupd8team/jupiter
ppa:webupd8team/sublime-text-3
ppa:webupd8team/y-ppa-manager
ppa:yannubuntu/boot-repair
ppa:yorba/ppa
'
	for V_PPA in $V_PPA_INSTALL ; do
		show_header "Adding repository $V_PPA"
		sudo add-apt-repository --yes $V_PPA
	done

	IFS=$V_OLD_IFS

	V_MEDIBUNTU_FILE=/etc/apt/sources.list.d/medibuntu.list
	if [ ! -f "$V_MEDIBUNTU_FILE" ] ; then
		show_header "Adding Medibuntu repository $V_MEDIBUNTU_FILE"
		sudo -E wget --output-document=$V_MEDIBUNTU_FILE http://www.medibuntu.org/sources.list.d/$(lsb_release -cs).list
		sudo apt-get --quiet update
		sudo apt-get --yes --quiet --allow-unauthenticated install medibuntu-keyring
	fi

	V_GETDEB_INSTALLED="$(dpkg --get-selections | grep -i getdeb-repository)"
	if [ -z "$V_GETDEB_INSTALLED" ] ; then
		show_header 'Adding GetDeb repository'
		V_GETDEB_FILE=getdeb-repository_0.1-1~getdeb1_all.deb
		cd $G_DOWNLOAD_DIR
		wget http://archive.getdeb.net/install_deb/$V_GETDEB_FILE
		sudo dpkg -i $V_GETDEB_FILE
	fi

	# Oracle Virtual Box
	# https://www.virtualbox.org/wiki/Linux_Downloads
	wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | sudo apt-key add -

	# http://pkg.jenkins-ci.org/debian/
	show_header 'Adding Jenkins key'
	wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -

	# Install MongoDB on Ubuntu (10Gen)
	# http://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/
	show_header 'Installing MongoDB'
	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
	echo "deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen" > /tmp/10gen.list
	sudo mv /tmp/10gen.list /etc/apt/sources.list.d/10gen.list

	repo_partner

	V_UPDATE=1
fi

if [ -n "$V_ALL" ] || [ -n "$V_UPGRADE" ] ; then
	V_UPDATE=1
fi

if [ -n "$V_ALL" ] || [ -n "$V_UPDATE" ] ; then
	show_header 'Updating repositories'
	sudo apt-get update

	# Close the "Software Update" window after the update
	pkill -9 update-manager
fi

autoremove_packages() {
	show_header "Autoremoving unused packages"
	V_ACTION=autoremove
	sleep 1 && sudo apt-get --yes $V_ACTION
	show_error 'autoremoving some of the packages' $V_ACTION
}

if [ -n "$V_ALL" ] || [ -n "$V_UPGRADE" ] ; then
	show_header 'Upgrading regular packages'
	V_ACTION=upgrade
	sudo apt-get --yes $V_ACTION
	show_error 'upgrading some of the packages' $V_ACTION

	show_header 'Upgrading distribution packages'
	V_ACTION=dist-upgrade
	sudo apt-get --yes $V_ACTION
	show_error 'upgrading some of the distribution packages' $V_ACTION

	autoremove_packages
fi

if [ -n "$V_ALL" ] || [ -n "$V_INSTALL_PACKAGES" ] ; then
	common_packages

	V_DIR='/usr/local/bin'
	show_header "The nautilus-compare package needs the $V_DIR directory in order to work"
	sudo mkdir -p "$V_DIR"
	sleep 1 && sudo apt-get --yes install nautilus-compare

	if [ -z "$(type -p beet)" ] ; then
		# https://github.com/sampsyo/beets/issues/915
		sudo pip install -U beets discogs-client==1.1.1 pylast
	fi

	#------------------------------------------------------------------------------------------------------------------------
	# WORK
	#------------------------------------------------------------------------------------------------------------------------
	if [ $HOSTNAME = $G_WORK_COMPUTER ] ; then
		show_header 'Installing packages for working only'
		V_ACTION=install
	else
		show_header 'Removing packages for working only'
		V_ACTION=purge
	fi
	V_SYSTEM='rdesktop wine'
	V_SHARE='nfs-common cifs-utils'
	V_TORRENT='deluge deluge-gtk'
	V_INDICATOR='calendar-indicator'
	sleep 1 && sudo apt-get --yes $V_ACTION $V_SYSTEM $V_SHARE $V_TORRENT $V_INDICATOR
	show_error 'installing or removing some of the packages for working only' $V_ACTION

	#------------------------------------------------------------------------------------------------------------------------
	# HOME
	#------------------------------------------------------------------------------------------------------------------------
	if [ $HOSTNAME = $G_HOME_COMPUTER ] ; then
		show_header 'Installing packages for home only'
		V_ACTION=install
	else
		show_header 'Removing packages for home only'
		V_ACTION=purge
	fi
	V_CODECS='libxine1-ffmpeg gxine mencoder totem-mozilla icedax mpg321'
	V_PROGRAMMING='bzr'
	V_MEDIA='vlc vlc-nox libaudiofile1 libmad0 normalize-audio feh'
	sleep 1 && sudo apt-get --yes $V_ACTION $V_CODECS $V_PROGRAMMING $V_MEDIA
	show_error 'installing or removing some of the packages for home only' $V_ACTION

	purge_packages
	autoremove_packages

	# http://www.webupd8.org/2012/04/things-to-tweak-after-installing-ubuntu.html
	show_header 'Make all autostart items show up in Startup Applications dialog'
	sudo sed -i 's/NoDisplay=true/NoDisplay=false/g' /etc/xdg/autostart/*.desktop

	#V_COUCHPOTATO_DIR=/opt/couchpotato
	#if [ ! -d "$V_COUCHPOTATO_DIR" ] ; then
	#	show_header 'Installing Couch Potato'
	#	# https://github.com/RuudBurger/CouchPotato/blob/master/README.md
	#	sudo mkdir $V_COUCHPOTATO_DIR
	#	chmod -R 777 $V_COUCHPOTATO_DIR
	#	git clone https://github.com/RuudBurger/CouchPotato.git $V_COUCHPOTATO_DIR
	#	cd $V_COUCHPOTATO_DIR
	#	sudo cp initd.ubuntu /etc/init.d/couchpotato
	#	V_ETC_DEFAULT_COUCHPOTATO=/etc/default/couchpotato
	#	sudo cp default.ubuntu $V_ETC_DEFAULT_COUCHPOTATO
	#	sudo sed -i 's#^\(APP_PATH=\).*#\1/opt/couchpotato#' $V_ETC_DEFAULT_COUCHPOTATO
	#	sudo sed -i 's#^\(RUN_AS=\).*#\1wagner#' $V_ETC_DEFAULT_COUCHPOTATO
	#	sudo chmod a+x /etc/init.d/couchpotato
	#	sudo update-rc.d couchpotato defaults
	#fi

	# Using type instead of which, according to this answer: http://stackoverflow.com/a/677212/1391315
	if [ -z "$(type -p teamviewer)" ] ; then
		show_header 'Installing Teamviewer'
		V_DEB=$G_DOWNLOAD_DIR/teamviewer_linux_x64.deb
		wget -O $V_DEB http://www.teamviewer.com/download/teamviewer_linux_x64.deb
		sudo dpkg --install "$V_DEB"
		sudo apt-get --yes --fix-broken install
	fi

	if [ $HOSTNAME = $G_HOME_COMPUTER ] ; then
		show_header 'Bazaar autocomplete'
		eval "$(bzr bash-completion)"
	fi
fi
