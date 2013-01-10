#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Automated Ubuntu setup for home and work computers.
Antes de executar este script pela primeira vez:
- Instale o Linux (Ubuntu ou Mint) em um PC ou VM;
- Na VM, instale tambem o VBox Guest Additions (para poder compartilhar diretorios) e ative dispositivos USB.

  -a  Executa todas as opcoes abaixo.
  -r  Atualiza repositorios PPA.
  -u  Executa upgrade e dist-upgrade.
  -i  Instala/desinstala pacotes.
  -f  Testa o FlexGet.
  -h  Help"
	exit $1
}

V_PPA=
V_UPDATE=
V_UPGRADE=
V_INSTALL_PACKAGES=
V_TEST_FLEXGET=
V_ALL=
V_SOMETHING_CHOSEN=
while getopts "ruifah" OPTION
do
	case $OPTION in
		r)	V_PPA=1
			V_SOMETHING_CHOSEN=1 ;;
		u)	V_UPGRADE=1
			V_SOMETHING_CHOSEN=1 ;;
		i)	V_INSTALL_PACKAGES=1
			V_SOMETHING_CHOSEN=1 ;;
		f)	V_TEST_FLEXGET=1
			V_SOMETHING_CHOSEN=1 ;;
		a)	V_ALL=1
			V_SOMETHING_CHOSEN=1 ;;
		h)	usage 1 ;;
		?)	usage 1 ;;
	esac
done

if [ -z $V_SOMETHING_CHOSEN ] ; then
	usage 2
fi

if [ -n "$V_ALL" ] || [ -n "$V_PPA" ] ; then
	V_OLD_IFS="$IFS"
	IFS='
'
	V_PPA_INSTALL='
ppa:atareao/atareao
ppa:cs-sniffer/cortina
ppa:danielrichter2007/grub-customizer
ppa:diesch/testing
ppa:gcstar/ppa
ppa:git-core/ppa
ppa:indicator-multiload/stable-daily
ppa:jcfp/ppa
ppa:pidgin-developers/ppa
ppa:tualatrix/ppa
ppa:webupd8team/java
ppa:webupd8team/jupiter
ppa:webupd8team/sublime-text-2
ppa:webupd8team/y-ppa-manager
ppa:yannubuntu/boot-repair
deb http://ppa.launchpad.net/geod/ppa-geod/ubuntu natty main
deb http://ppa.launchpad.net/midnightflash/ppa/ubuntu natty main
deb http://ppa.launchpad.net/stebbins/handbrake-releases/ubuntu oneiric main
'
	for V_PPA in $V_PPA_INSTALL ; do
		echo "Adicionando repositorio $V_PPA"
		sudo add-apt-repository --yes $V_PPA
	done

	V_PPA_REMOVE='
ppa:aheck/ppa
ppa:recoll-backports/recoll-1.15-on
ppa:scopes-packagers/ppa
ppa:webupd8team/rhythmbox
deb http://pkg.jenkins-ci.org/debian binary/
'
	for V_PPA in $V_PPA_REMOVE ; do
		echo "Removendo repositorio $V_PPA"
		sudo add-apt-repository --remove --yes $V_PPA
	done

	IFS=$V_OLD_IFS

	# Repositório Medibuntu
	V_MEDIBUNTU_FILE=/etc/apt/sources.list.d/medibuntu.list
	if [ ! -f "$V_MEDIBUNTU_FILE" ] ; then
		echo "Adicionando repositorio $V_MEDIBUNTU_FILE"
		sudo -E wget --output-document=$V_MEDIBUNTU_FILE http://www.medibuntu.org/sources.list.d/$(lsb_release -cs).list
		sudo apt-get --quiet update
		sudo apt-get --yes --quiet --allow-unauthenticated install medibuntu-keyring
	fi

	# Repositório GetDeb
	V_GETDEB_INSTALLED="$(dpkg --get-selections | grep -i getdeb-repository)"
	if [ -z "$V_GETDEB_INSTALLED" ] ; then
		V_GETDEB_FILE=getdeb-repository_0.1-1~getdeb1_all.deb
		cd $G_DOWNLOAD_DIR
		wget http://archive.getdeb.net/install_deb/$V_GETDEB_FILE
		sudo dpkg -i $V_GETDEB_FILE
	fi

	# http://pkg.jenkins-ci.org/debian/
	wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -

	# Install MongoDB on Ubuntu (10Gen)
	# http://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/
	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
	echo "deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen" > /tmp/10gen.list
	sudo mv /tmp/10gen.list /etc/apt/sources.list.d/10gen.list

	V_UPDATE=1
fi

if [ -n "$V_ALL" ] || [ -n "$V_UPGRADE" ] ; then
	V_UPDATE=1
fi

if [ -n "$V_ALL" ] || [ -n "$V_UPDATE" ] ; then
	sudo apt-get update
fi

if [ -n "$V_ALL" ] || [ -n "$V_UPGRADE" ] ; then
	sudo apt-get --yes upgrade
	sudo apt-get --yes dist-upgrade
fi

setup_python() {
	echo 'Instalando coisas do Python'

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

	V_PIP_NLTK=$(pip freeze | grep nltk)
	if [ -z "$V_PIP_NLTK" ] ; then
		# http://nltk.org/install.html
		echo 'Instalando Python NLP'
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
	# Common
	echo 'Instalando pacotes comuns'
	V_SYSTEM='bash-completion nautilus-open-terminal nautilus-dropbox synaptic gdebi gdebi-core alien gparted mutt curl wget wmctrl xdotool gconf-editor dconf-tools grub-customizer boot-repair tree tasksel rcconf samba system-config-samba iftop bum'
	V_DEV='sublime-text-dev vim vim-gui-common exuberant-ctags meld'
	V_GIT='git git-core git-doc git-svn git-gui gitk'
	V_PYTHON='python-pip python-dev python-matplotlib'
	V_BROWSER='chromium-browser google-chrome-stable lynx-cur'
	V_VIRTUALBOX='virtualbox virtualbox-guest-x11 virtualbox-guest-utils virtualbox-qt'
	V_JAVA='openjdk-6-jre icedtea6-plugin'
	V_AUDIO='rhythmbox id3 id3tool id3v2 lame-doc easytag nautilus-script-audio-convert cd-discid cdparanoia flac lame mp3gain ruby-gnome2 ruby vorbisgain eyed3 python-eyed3 rubyripper gcstar'
	V_UNITY='indicator-weather'
	# lo-menubar
	V_TWEAK='ubuntu-tweak myunity y-ppa-manager unsettings'
	V_ARCHIVE='unace unrar zip unzip p7zip-full p7zip-rar sharutils rar uudeview mpack lha arj cabextract file-roller'
	V_UTIL='keepassx gtimelog cortina backintime-gnome gtg'
	V_WORKSPACES='indicator-workspaces python-wnck'
	V_GIMP='gimp gimp-data gimp-plugin-registry gimp-data-extras'
	V_HANDBRAKE='handbrake-cli handbrake-gtk'
	V_PHP='php5-cli php-pear php5-xsl apache2-utils graphviz graphviz-doc phpmyadmin'
	V_PIDGIN='indicator-messages pidgin pidgin-awayonlock pidgin-data pidgin-extprefs pidgin-guifications pidgin-hotkeys pidgin-lastfm pidgin-libnotify pidgin-otr pidgin-plugin-pack pidgin-ppa pidgin-privacy-please pidgin-themes pidgin-dev pidgin-dbg'
	V_MYSQL='mysql-client mysql-common mysql-server mysql-workbench libmysqlclient-dev libmysqlclient18 sqlite3'
	V_SUBVERSION='subversion'
	V_USENET='sabnzbdplus sabnzbdplus-theme-mobile'
	V_RESCUE_TIME='xprintidle gtk2-engines-pixbuf'
	V_CI='php5-curl php-pear php5-dev jenkins postfix'
	V_ALL="$V_SYSTEM $V_DEV $V_GIT $V_PYTHON $V_BROWSER $V_VIRTUALBOX $V_JAVA $V_AUDIO $V_UNITY $V_TWEAK $V_ARCHIVE $V_UTIL $V_WORKSPACES $V_GIMP $V_HANDBRAKE $V_PHP $V_PIDGIN $V_MYSQL $V_SUBVERSION $V_USENET $V_RESCUE_TIME $V_CI"
	sleep 1 && sudo apt-get --yes install $V_ALL
	if [ $? -gt 0 ] ; then
		echo -e "${COLOR_LIGHT_RED}No package was installed nor upgraded, because there was an error in some of the packages. Fix them before continuing."
		exit
	fi

	V_DIR='/usr/local/bin'
	echo "O pacote nautilus-compare precisa do diretorio $V_DIR para funcionar"
	sudo mkdir -p "$V_DIR"
	sleep 1 && sudo apt-get --yes install nautilus-compare

	if [ -z "$(type -p beet)" ] ; then
		sudo pip install -U beets
	fi

	# Work
	if [ $HOSTNAME = $G_WORK_COMPUTER ] ; then
		echo 'Instalando pacotes exclusivos para trabalho'
		V_ACTION=install

		if [ -z "$(type -p flexget)" ] ; then
			sudo pip install -U flexget
		fi
	else
		echo 'Removendo pacotes exclusivos para trabalho'
		V_ACTION=purge
	fi
	V_SYSTEM='rdesktop wine'
	V_SHARE='nfs-common cifs-utils'
	V_EMAIL='thunderbird'
	V_TORRENT='deluge deluge-gtk'
	V_FTP='filezilla'
	V_INDICATOR='calendar-indicator'
	sleep 1 && sudo apt-get --yes $V_ACTION $V_SYSTEM $V_SHARE $V_EMAIL $V_TORRENT $V_FTP $V_INDICATOR

	# Home
	if [ $HOSTNAME = $G_HOME_COMPUTER ] ; then
		echo 'Instalando pacotes exclusivos para casa'
		V_ACTION=install
	else
		echo 'Removendo pacotes exclusivos para casa'
		V_ACTION=purge
	fi
	V_CODECS='non-free-codecs libxine1-ffmpeg gxine mencoder totem-mozilla icedax mpg321'
	V_PROGRAMMING='ruby1.9.1 bzr'
	V_MEDIA='vlc-nox k3b'
	# mpg123libjpeg-progs
	# libaudiofile1 libmad0 normalize-audio
	sleep 1 && sudo apt-get --yes $V_ACTION $V_CODECS $V_PROGRAMMING $V_MEDIA

	# Pacotes a remover
	echo 'Removendo pacotes nao usados (nem em casa, nem no trabalho)'
	V_GNOME='gnome-panel gnome-shell gnome-session-fallback gnome-tweak-tool docker kdebase-workspace-bin ejecter'
	V_UBUNTU_ONE='ubuntuone-client ubuntuone-client-gnome ubuntuone-control-panel ubuntuone-couch ubuntuone-installer'
	V_GWIBBER='gwibber gwibber-service gwibber-service-facebook gwibber-service-identica gwibber-service-twitter libgwibber-gtk2 libgwibber2'
	V_EMPATHY='empathy empathy-common nautilus-sendto-empathy'
	V_PIDGIN='unity-lens-pidgin'
	V_MEDIA='tagtool'
	V_UNITY='classicmenu-indicator recoll-lens recoll unity-lens-utilities unity-scope-calculator'
	V_UTIL='keepass2'
	V_MONGO='mongodb-clients'
	sleep 1 && sudo apt-get --yes purge $V_GNOME $V_UBUNTU_ONE $V_GWIBBER $V_EMPATHY $V_PIDGIN $V_MEDIA $V_UNITY $V_UTIL $V_MONGO
	sleep 1 && sudo apt-get --yes autoremove

	# http://www.webupd8.org/2012/04/things-to-tweak-after-installing-ubuntu.html
	echo 'Make all autostart items show up in Startup Applications dialog'
	sudo sed -i 's/NoDisplay=true/NoDisplay=false/g' /etc/xdg/autostart/*.desktop

	#V_DIR=/usr/local/bin/indicator-places/
	#if [ ! -d "$V_DIR" ] ; then
	#	echo 'Instalando indicador de lugares (places indicator)'
	#	V_ZIP=$G_DOWNLOAD_DIR/indicator-places.tar.gz
	#	wget -O $V_ZIP https://github.com/shamil/indicator-places/tarball/master
	#	sudo mkdir -p $V_DIR
	#	cd $V_DIR
	#	sudo tar -xvf $V_ZIP
	#	V_CREATED_DIR=$(ls -1 .)
	#	sudo mv $V_CREATED_DIR/* .
	#	sudo rm -rvf $V_CREATED_DIR
	#	rm $V_ZIP
	#	# @todo Adicionar no autostart automaticamente se não existir
	#fi

	setup_python

	V_RESCUE_TIME="$(type -p rescuetime)"
	if [ -z "$V_RESCUE_TIME" ] ; then
		xdg-open https://www.rescuetime.com/setup/installer?os=amd64deb
		zenity --info --text='Faça login na página do Rescue Time antes de continuar'
		sudo dpkg -i $G_DOWNLOAD_DIR/rescuetime_current_amd64.deb
		zenity --info --text='Install RescueTime plugins in all browsers'
		V_RESCUE_TIME_URL=https://www.rescuetime.com/setup/download
		xdg-open $V_RESCUE_TIME_URL
		firefox $V_RESCUE_TIME_URL
	fi

	#V_COUCHPOTATO_DIR=/opt/couchpotato
	#if [ ! -d "$V_COUCHPOTATO_DIR" ] ; then
	#	echo 'Instalando Couch Potato'
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
		echo 'Instalando Teamviewer'
		V_DEB=$G_DOWNLOAD_DIR/teamviewer_linux_x64.deb
		wget -O $V_DEB http://www.teamviewer.com/download/teamviewer_linux_x64.deb
		sudo dpkg --install "$V_DEB"
		sudo apt-get --yes --fix-broken install
	fi

	if [ $HOSTNAME = $G_WORK_COMPUTER ] ; then
		echo 'Instalando Oracle instant client @todo'
		echo 'Instalando squirrel @todo'
	fi

	if [ $HOSTNAME = $G_HOME_COMPUTER ] ; then
		echo 'Autocomplete para o Bazaar'
		eval "$(bzr bash-completion)"

		V_EPSON_INSTALLED="$(dpkg --get-selections | grep -i epson-inkjet)"
		if [ -z "$V_EPSON_INSTALLED" ] ; then
			echo 'Instalando impressora Epson'
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
		fi
	fi
fi

if [ -n "$V_ALL" ] || [ -n "$V_TEST_FLEXGET" ] ; then
	echo "Testando funcionamento do Flexget"
	if [ -n "$(type -p flexget)" ] ; then
		echo "  Flexget nao instalado"
	else
		flexget --check
		flexget --test
	fi
fi

####################
# Ambos
####################

# Impressora multifuncional Epson e software para escanear
#sudo apt-get --yes install xsane libsane-extras xsltproc
# sudo dpkg --install iscan-data_1.6.0-0_all.deb
# sudo dpkg --install iscan_2.26.1-3.ltdl7_i386.deb

####################
# Primeira instalacao
####################

# Links simbolicos que dependem do DropBox
#ln -s $HOME/Dropbox/Apps/Sublime\ Text\ 2/Data/ $HOME/.config/sublime-text-2
#ln -s $HOME/Dropbox/Apps/PidginPortable/Data/settings/.purple/ $HOME/
#ln -s $HOME/Dropbox/linux/flexget-config.yml config.yml

# ***** Restore packages *****
# sudo apt-get update
# sudo apt-get dist-upgrade
# dpkg --set-selections < dpkg-get-selections.txt
# sudo dselect
