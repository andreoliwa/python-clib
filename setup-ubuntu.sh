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
-l  Setup symbolic links
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

show_error() {
	if [ $? -gt 0 ] ; then
		echo -e "${COLOR_LIGHT_RED}There was an error while ${1}.\nFix them before continuing.${COLOR_NONE}"

		# Abort only on package installation
		if [ -z "${2}" -o "${2}" == 'install' ] ; then
			exit
		fi
	fi
}

if [ -n "$V_ALL" ] || [ -n "$V_PPA" ] ; then
	V_OLD_IFS="$IFS"
	IFS='
'
	V_PPA_REMOVE='
deb http://download.virtualbox.org/virtualbox/debian precise contrib
deb http://pkg.jenkins-ci.org/debian binary/
ppa:aheck/ppa
ppa:do-testers/ppa
ppa:indicator-multiload/stable-daily
ppa:recoll-backports/recoll-1.15-on
ppa:scopes-packagers/ppa
ppa:webupd8team/rhythmbox
ppa:webupd8team/sublime-text-2
'
	for V_PPA in $V_PPA_REMOVE ; do
		show_header "Removing repository $V_PPA"
		sudo add-apt-repository --remove --yes $V_PPA
	done

	V_PPA_INSTALL='
deb http://ppa.launchpad.net/do-testers/ppa/ubuntu precise main
deb http://ppa.launchpad.net/geod/ppa-geod/ubuntu natty main
deb http://ppa.launchpad.net/midnightflash/ppa/ubuntu natty main
deb http://ppa.launchpad.net/stebbins/handbrake-releases/ubuntu oneiric main
ppa:atareao/atareao
ppa:cs-sniffer/cortina
ppa:danielrichter2007/grub-customizer
ppa:diesch/testing
ppa:gcstar/ppa
ppa:git-core/ppa
ppa:indicator-multiload/daily
ppa:jcfp/ppa
ppa:pidgin-developers/ppa
ppa:tualatrix/ppa
ppa:webupd8team/java
ppa:webupd8team/jupiter
ppa:webupd8team/y-ppa-manager
ppa:yannubuntu/boot-repair
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

if [ -n "$V_ALL" ] || [ -n "$V_UPGRADE" ] ; then
	show_header 'Upgrading regular packages'
	V_ACTION=upgrade
	sudo apt-get --yes $V_ACTION
	show_error 'upgrading some of the packages' $V_ACTION

	show_header 'Upgrading distribution packages'
	V_ACTION=dist-upgrade
	sudo apt-get --yes $V_ACTION
	show_error 'upgrading some of the distribution packages' $V_ACTION
fi

setup_python() {
	show_header 'Installing Python stuff'

	# Using type instead of which, according to this answer: http://stackoverflow.com/a/677212/1391315
	if [ -z "$(type -p pylint)" ] ; then
		cd $G_DOWNLOAD_DIR
		V_ZIP_BASENAME=pylint-0.25.2
		V_ZIP=$V_ZIP_BASENAME.tar.gz
		wget http://pypi.python.org/packages/source/p/pylint/$V_ZIP
		tar -xzvf $V_ZIP
		cd $V_ZIP_BASENAME/
		sudo python setup.py install
	fi

	if [ -z "$(type -p pep8)" ] ; then
		sudo pip install -U pep8
	fi

	V_PIP_NLTK=$(sudo pip freeze | grep nltk)
	if [ -z "$V_PIP_NLTK" ] ; then
		# http://nltk.org/install.html
		show_header 'Installing Python NLP'
		V_SETUPTOOLS_EGG_BASENAME=setuptools-0.6c11-py2.7.egg
		V_SETUPTOOLS_EGG=$G_DOWNLOAD_DIR/$V_SETUPTOOLS_EGG_BASENAME
		rm -v $V_SETUPTOOLS_EGG
		wget -O $V_SETUPTOOLS_EGG http://pypi.python.org/packages/2.7/s/setuptools/$V_SETUPTOOLS_EGG_BASENAME
		sudo sh $V_SETUPTOOLS_EGG
		sudo pip install -U numpy pyyaml nltk
		python -c 'import nltk
nltk.download()'
	fi
}

if [ -n "$V_ALL" ] || [ -n "$V_INSTALL_PACKAGES" ] ; then
	#------------------------------------------------------------------------------------------------------------------------
	# COMMON
	#------------------------------------------------------------------------------------------------------------------------
	show_header 'Installing common packages'
	V_SYSTEM='bash-completion nautilus-open-terminal synaptic gdebi gdebi-core alien gparted mutt curl wget wmctrl xdotool gconf-editor dconf-tools grub-customizer boot-repair tree tasksel rcconf samba system-config-samba iftop bum'
	#nautilus-dropbox
	V_DESKTOP='xubuntu-desktop indicator-weather indicator-workspaces python-wnck cortina gnome-do indicator-multiload imwheel'
	V_DEV='vim vim-gui-common exuberant-ctags meld'
	V_GIT='git git-core git-doc git-svn git-gui gitk'
	V_PYTHON='python-pip python-dev python-matplotlib'
	V_BROWSER='chromium-browser lynx-cur'
	V_VIRTUALBOX='dkms virtualbox-guest-x11 virtualbox-guest-utils' # virtualbox-4.2
	V_JAVA='openjdk-6-jre icedtea6-plugin'
	V_AUDIO='rhythmbox id3 id3tool id3v2 lame-doc easytag nautilus-script-audio-convert cd-discid cdparanoia flac lame mp3gain ruby-gnome2 vorbisgain eyed3 python-eyed3 rubyripper gcstar'
	# lo-menubar
	# Libre Office menu bar
	# Some packages could not be installed. This may mean that you have
	# requested an impossible situation or if you are using the unstable
	# distribution that some required packages have not yet been created
	# or been moved out of Incoming.
	# The following information may help to resolve the situation:
	#
	# The following packages have unmet dependencies:
	#  lo-menubar : Depends: libreoffice-gtk but it is not going to be installed
	# E: Unable to correct problems, you have held broken packages.
	V_TWEAK='ubuntu-tweak y-ppa-manager unsettings' # myunity
	V_ARCHIVE='unace unrar zip unzip p7zip-full p7zip-rar sharutils rar uudeview mpack lha arj cabextract file-roller'
	V_UTIL='keepassx gtimelog backintime-gnome gtg thunderbird tmux'
	V_GIMP='gimp gimp-data gimp-plugin-registry gimp-data-extras'
	V_HANDBRAKE='handbrake-cli handbrake-gtk'
	V_PHP='php5-cli php-pear php5-xsl apache2-utils graphviz graphviz-doc phpmyadmin php5-sqlite php-apc'
	V_PIDGIN='indicator-messages pidgin pidgin-awayonlock pidgin-data pidgin-extprefs pidgin-guifications pidgin-hotkeys pidgin-lastfm pidgin-libnotify pidgin-otr pidgin-plugin-pack pidgin-ppa pidgin-privacy-please pidgin-themes pidgin-dev pidgin-dbg'
	V_MYSQL='mysql-client mysql-common mysql-server mysql-workbench libmysqlclient-dev libmysqlclient18 sqlite3'
	V_SUBVERSION='subversion'
	V_USENET='sabnzbdplus sabnzbdplus-theme-mobile'
	V_RESCUETIME='xprintidle gtk2-engines-pixbuf'
	V_CI='php5-curl php5-dev jenkins postfix'
	V_ALL_PACKAGES="$V_SYSTEM $V_DESKTOP $V_DEV $V_GIT $V_PYTHON $V_BROWSER $V_VIRTUALBOX $V_JAVA $V_AUDIO $V_TWEAK $V_ARCHIVE $V_UTIL $V_GIMP $V_HANDBRAKE $V_PHP $V_PIDGIN $V_MYSQL $V_SUBVERSION $V_USENET $V_RESCUETIME $V_CI"
	V_ACTION=install
	sleep 1 && sudo apt-get --yes $V_ACTION $V_ALL_PACKAGES
	show_error 'installing or upgrading some of the packages' $V_ACTION

	V_DIR='/usr/local/bin'
	show_header "The nautilus-compare package needs the $V_DIR directory in order to work"
	sudo mkdir -p "$V_DIR"
	sleep 1 && sudo apt-get --yes install nautilus-compare

	if [ -z "$(type -p beet)" ] ; then
		sudo pip install -U beets
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
	V_FTP='filezilla'
	V_INDICATOR='calendar-indicator'
	sleep 1 && sudo apt-get --yes $V_ACTION $V_SYSTEM $V_SHARE $V_TORRENT $V_FTP $V_INDICATOR
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
	V_MEDIA='vlc-nox k3b libaudiofile1 libmad0 normalize-audio'
	sleep 1 && sudo apt-get --yes $V_ACTION $V_CODECS $V_PROGRAMMING $V_MEDIA
	show_error 'installing or removing some of the packages for home only' $V_ACTION

	#------------------------------------------------------------------------------------------------------------------------
	# REMOVE
	#------------------------------------------------------------------------------------------------------------------------
	show_header 'Purging unused packages (not used at home neither at work) '
	V_GNOME='gnome-panel gnome-shell gnome-session-fallback gnome-tweak-tool docker kdebase-workspace-bin'
	V_UBUNTU_ONE='ubuntuone-client ubuntuone-client-gnome ubuntuone-control-panel ubuntuone-couch ubuntuone-installer'
	V_GWIBBER='gwibber gwibber-service gwibber-service-facebook gwibber-service-identica gwibber-service-twitter libgwibber-gtk2 libgwibber2'
	V_EMPATHY='empathy empathy-common nautilus-sendto-empathy'
	V_MEDIA='tagtool wallch subdownloader'
	V_UNITY='classicmenu-indicator recoll'
	V_UTIL='keepass2'
	V_MONGO='mongodb-clients'
	V_TORRENT='transmission'
	V_ACTION=purge
	sleep 1 && sudo apt-get --yes $V_ACTION $V_GNOME $V_UBUNTU_ONE $V_GWIBBER $V_EMPATHY $V_MEDIA $V_UNITY $V_UTIL $V_MONGO $V_TORRENT
	show_error 'purging some of the packages' $V_ACTION

	#------------------------------------------------------------------------------------------------------------------------
	# PURGING
	#------------------------------------------------------------------------------------------------------------------------
	show_header "Purging 'unable to locate' packages, one at a time, and ignoring eventual errors"
	V_UNABLE_TO_LOCATE='ejecter unity-lens-pidgin recoll-lens unity-lens-utilities unity-scope-calculator google-chrome-stable non-free-codecs'
	for V_PURGE_ONE_PACKAGE in $V_UNABLE_TO_LOCATE ; do
		sudo apt-get --yes purge $V_PURGE_ONE_PACKAGE
	done

	show_header "Autoremoving unused packages"
	V_ACTION=autoremove
	sleep 1 && sudo apt-get --yes $V_ACTION
	show_error 'autoremoving some of the packages' $V_ACTION

	# http://www.webupd8.org/2012/04/things-to-tweak-after-installing-ubuntu.html
	show_header 'Make all autostart items show up in Startup Applications dialog'
	sudo sed -i 's/NoDisplay=true/NoDisplay=false/g' /etc/xdg/autostart/*.desktop

	#V_DIR=/usr/local/bin/indicator-places/
	#if [ ! -d "$V_DIR" ] ; then
	#	show_header 'Installing places indicator'
	#	V_ZIP=$G_DOWNLOAD_DIR/indicator-places.tar.gz
	#	wget -O $V_ZIP https://github.com/shamil/indicator-places/tarball/master
	#	sudo mkdir -p $V_DIR
	#	cd $V_DIR
	#	sudo tar -xvf $V_ZIP
	#	V_CREATED_DIR=$(ls -1 .)
	#	sudo mv $V_CREATED_DIR/* .
	#	sudo rm -rvf $V_CREATED_DIR
	#	rm $V_ZIP
	#	# @todo Add to autostart if it doesn't exist
	#fi

	setup_python

	#V_RESCUETIME="$(type -p rescuetime)"
	#if [ -z "$V_RESCUETIME" ] ; then
	#	xdg-open https://www.rescuetime.com/setup/installer?os=amd64deb
	#	zenity --info --text='Faça login na página do Rescue Time antes de continuar'
	#	sudo dpkg -i $G_DOWNLOAD_DIR/rescuetime_current_amd64.deb
	#	zenity --info --text='Install RescueTime plugins in all browsers'
	#	V_RESCUETIME_URL=https://www.rescuetime.com/setup/download
	#	xdg-open $V_RESCUETIME_URL
	#	firefox $V_RESCUETIME_URL
	#fi

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

	# http://www.webupd8.org/2012/09/subliminal-command-line-tool-to.html
	V_SUBLIMINAL="$(type -p subliminal)"
	if [ -z "$V_SUBLIMINAL" ] ; then
		sudo pip install -U beautifulsoup4 guessit requests enzyme html5lib lxml
		cd $G_DOWNLOAD_DIR
		git clone https://github.com/Diaoul/subliminal.git
		cd subliminal
		sudo python setup.py install
	fi

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

		V_EPSON_INSTALLED="$(dpkg --get-selections | grep -i epson-inkjet)"
		if [ -z "$V_EPSON_INSTALLED" ] ; then
			show_header 'Installing Epson printer'
			V_DOWNLOAD_LINK=http://linux.avasys.jp/drivers/lsb/epson-inkjet/stable/debian/dists/lsb3.2/main/binary-amd64/epson-inkjet-printer-201101w_1.0.0-1lsb3.2_amd64.deb
			V_PACKAGE="$G_DOWNLOAD_DIR/$(basename $V_DOWNLOAD_LINK)"
			if [ ! -f "$V_PACKAGE" ] ; then
				wget --output-document="$V_PACKAGE" "$V_DOWNLOAD_LINK"
			fi
			if [ -f "$V_PACKAGE" ] ; then
				sudo dpkg -i $V_PACKAGE
				sudo apt-get install lsb
				sudo apt-get -f install
				sudo dpkg -i $V_PACKAGE
			fi

			# Scanning software... didn't work the last time
			# sudo apt-get --yes install xsane libsane-extras xsltproc
			# sudo dpkg --install iscan-data_1.6.0-0_all.deb
			# sudo dpkg --install iscan_2.26.1-3.ltdl7_i386.deb
		fi
	fi
fi

create_link() {
	V_LINK_NAME="$1"
	V_TARGET="$2"

	mkdir -p "$(dirname $V_LINK_NAME)"

	# Create if the target exists and the link doesn't
	[ -e "$V_TARGET" ] && [ ! -e "$V_LINK_NAME" ] && ln -s "$V_TARGET" "$V_LINK_NAME"
	ls -lad --color=auto "$V_LINK_NAME"
}

if [ -n "$V_ALL" -o -n "$V_SYMBOLIC_LINKS" ] ; then
	#------------------------------------------------------------------------------------------------------------------------
	# SYMBOLIC LINKS
	#------------------------------------------------------------------------------------------------------------------------
	show_header 'Creating common symbolic links for files'
	create_link $HOME/.bashrc $V_BASH_UTILS_DIR/.bashrc
	[ -f "$HOME/.beetsconfig" ] && rm $HOME/.beetsconfig
	create_link $HOME/.config/beets/config.yaml $G_DROPBOX_DIR/linux/beets-config.yaml
	create_link $HOME/.imwheelrc $V_BASH_UTILS_DIR/.imwheelrc
	create_link $HOME/.ssh/config $G_DROPBOX_DIR/linux/ssh-config
	create_link $HOME/.tmux.conf $V_BASH_UTILS_DIR/.tmux.conf
	create_link $HOME/.vimrc $V_BASH_UTILS_DIR/.vimrc
	#create_link $HOME/.inputrc $V_BASH_UTILS_DIR/.inputrc

	show_header 'Creating common symbolic links for directories'
	create_link $HOME/.config/gcstar $G_DROPBOX_DIR/linux/config-gcstar/
	create_link $HOME/.config/sublime-text-2 "$G_DROPBOX_DIR/Apps/Sublime\ Text\ 2/Data/"
	create_link $HOME/.config/sublime-text-3 $G_DROPBOX_DIR/Apps/sublime-text-3/
	create_link $HOME/.purple $G_DROPBOX_DIR/Apps/PidginPortable/Data/settings/.purple
	create_link $HOME/bin $G_DROPBOX_DIR/linux/bin/
	create_link $HOME/music-external-hdd $G_EXTERNAL_HDD/.audio/music/

	if [ $HOSTNAME = $G_HOME_COMPUTER ] ; then
		show_header 'Creating home symbolic links for files'
		create_link $HOME/.config/flexget/config.yml $G_DROPBOX_DIR/linux/flexget-config-imdb.yml
		create_link $HOME/.gitconfig $G_DROPBOX_DIR/linux/.gitconfig

		show_header 'Creating home symbolic links for directories'
		create_link $HOME/.xbmc $G_MOVIES_HDD/.xbmc/
		create_link $HOME/Music/hd $G_EXTERNAL_HDD/.audio/music/
		create_link $HOME/Pictures/dropbox $G_DROPBOX_DIR/Photos/
		create_link $HOME/Pictures/pix /pix/
		create_link $HOME/Pictures/wallpapers $G_DROPBOX_DIR/Photos/wallpapers/
		create_link $HOME/src/local $G_EXTERNAL_HDD/.backup/linux/$G_WORK_COMPUTER-Ubuntu-12.04.2-LTS/src/
	else
		show_header 'Creating work symbolic links for directories'
		create_link $HOME/Music/in $G_EXTERNAL_HDD/.audio/music/in
		create_link $HOME/Music/unknown $G_EXTERNAL_HDD/.audio/music/unknown
	fi
fi
