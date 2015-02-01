#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [-hancdfjpvw]
A single script to do all backups.

OPTIONS
-n  Dry-run
-k  Kill files when using rsync (--del)
-a  All options below
-c  Configuration files (calls backup-config.sh)
-d  Deja-dup files (backup tool)
-f  Home folder and source code
-j  Jaque
-p  Pictures (/pix directory)
-v  Videos
-w  Windows 7 files
-h  Help"
	exit $1
}

V_DRY_RUN=
V_KILL=
V_ALL=
V_CONFIG=
V_DEJA_DUP=
V_CODE=
V_VIDEOS=
V_WINDOWS=
V_SOMETHING_CHOSEN=
V_JAQUE=
V_PIX=
while getopts "nkacdfjpvwh" V_ARG ; do
	case $V_ARG in
	n)	V_DRY_RUN=-n ;;
	k)	V_KILL=--del ;;
	a)	V_SOMETHING_CHOSEN=1 ; V_ALL=1 ;;
	c)	V_SOMETHING_CHOSEN=1 ; V_CONFIG=1 ;;
	d)	V_SOMETHING_CHOSEN=1 ; V_DEJA_DUP=1 ;;
	f)	V_SOMETHING_CHOSEN=1 ; V_CODE=1 ;;
	v)	V_SOMETHING_CHOSEN=1 ; V_VIDEOS=1 ;;
	w)	V_SOMETHING_CHOSEN=1 ; V_WINDOWS=1 ;;
	j)	V_SOMETHING_CHOSEN=1 ; V_JAQUE=1 ;;
	p)	V_SOMETHING_CHOSEN=1 ; V_PIX=1 ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done
if [ -z $V_SOMETHING_CHOSEN ] ; then
	usage 3
fi

if [ -n "$V_DRY_RUN" ] ; then
	echo "This is only a test (DRY RUN)"
fi

if [ -n "$V_ALL" ] || [ -n "$V_CONFIG" ] ; then
	backup-config.sh
fi

V_LINUX_VERSION=$(lsb_release -d -s | sed 's/ /-/g')
V_BACKUP_EXTERNAL_DIR="$G_EXTERNAL_HDD/backup/linux"
if [ -d $V_BACKUP_EXTERNAL_DIR ] ; then
	V_BACKUP_EXTERNAL_DIR=$V_BACKUP_EXTERNAL_DIR/$HOSTNAME-$V_LINUX_VERSION
	mkdir -p $V_BACKUP_EXTERNAL_DIR
else
	echo "External backup directory not found: $V_BACKUP_EXTERNAL_DIR"
fi

if [ -n "$V_ALL" ] || [ -n "$V_DEJA_DUP" ] ; then
	if [ -d $V_BACKUP_EXTERNAL_DIR ] ; then
		echo "Syncing /var/backups/$HOSTNAME/ to $V_BACKUP_EXTERNAL_DIR/"
		if [ -d $V_BACKUP_EXTERNAL_DIR ] ; then
			V_CMD="rsync -htrOvz $V_DRY_RUN --progress --modify-window=2 /var/backups/$HOSTNAME/ $V_BACKUP_EXTERNAL_DIR/"
			[ -n "$V_DRY_RUN" ] && echo && echo "(DRY RUN) $V_CMD"
			eval "$V_CMD"
		fi
		echo "Done."
	fi
fi

if [ -n "$V_ALL" ] || [ -n "$V_VIDEOS" ] ; then
	if [ -d $V_BACKUP_EXTERNAL_DIR ] ; then
		echo "Linux videos backup (Stanford and others)"
		mkdir -p $V_BACKUP_EXTERNAL_DIR/Videos/
		V_CMD="rsync -htrOvz $V_DRY_RUN $V_KILL --progress --modify-window=2 ~/Videos/ $V_BACKUP_EXTERNAL_DIR/Videos/"
		[ -n "$V_DRY_RUN" ] && echo && echo "(DRY RUN) $V_CMD"
		eval "$V_CMD"
	fi
fi

if [ -n "$V_ALL" ] || [ -n "$V_CODE" ] ; then
	if [ ! -d "$V_BACKUP_EXTERNAL_DIR" ] ; then
		echo "Directory not found: $V_BACKUP_EXTERNAL_DIR"
	else
		echo "Home folder backup..."
		mkdir -p "${V_BACKUP_EXTERNAL_DIR}${HOME}"
		V_CMD="rsync $V_DRY_RUN -trOlhDuzv $V_KILL --modify-window=2 --progress --exclude-from=$(dirname $0)/backup-full-exclude-from-home.txt /home/ ${V_BACKUP_EXTERNAL_DIR}/home/"
		[ -n "$V_DRY_RUN" ] && echo && echo "(DRY RUN) $V_CMD"
		eval "$V_CMD"

		if [ $HOSTNAME = $G_WORK_COMPUTER ] ; then
			if [ ! -d "$G_WORK_SRC_DIR/" ]; then
			 	echo "Directory not found: $G_WORK_SRC_DIR/"
			else
				echo "Source code backup from $G_WORK_SRC_DIR/ to $V_BACKUP_EXTERNAL_DIR/src/"
				V_CMD="rsync $V_DRY_RUN -trOlhDuzv $V_KILL --modify-window=2 --progress $G_WORK_SRC_DIR/ $V_BACKUP_EXTERNAL_DIR/src/"
				#--exclude=*.pack
				[ -n "$V_DRY_RUN" ] && echo && echo "(DRY RUN) $V_CMD"
				eval "$V_CMD"
			fi
		fi
	fi
fi

function sync_dir() {
	for V_DESTINATION_DIR in $V_BACKUP_DIRS ; do
		echo
		if [ -d "$V_DESTINATION_DIR" ] ; then
			echo "Backing up $V_SOURCE_DIR/$1 directory in $V_DESTINATION_DIR/$1"
			V_SYNC="rsync $V_DRY_RUN -trOlhDuzv $V_KILL --modify-window=2 --progress --exclude=lost+found/ --exclude=.dropbox.cache --exclude=.Trash-*"
			echo $V_SYNC \"$V_SOURCE_DIR/$1/\" \"$V_DESTINATION_DIR/$1/\"
			mkdir -p "$V_DESTINATION_DIR/$1/"
			$V_SYNC "$V_SOURCE_DIR/$1/" "$V_DESTINATION_DIR/$1/"
		else
			echo "Destination root not found: $V_DESTINATION_DIR"
		fi
	done
}

if [ -n "$V_ALL" ] || [ -n "$V_PIX" ] ; then
	echo "Pictures backup"

	V_SOURCE_DIR='/home/wagner/Pictures'
	V_BACKUP_DIRS=$G_EXTERNAL_HDD/backup
	sync_dir 'shotwell'
fi

if [ -n "$V_ALL" ] || [ -n "$V_WINDOWS" ] ; then
	V_SOURCE_DIR='/mnt/windows7'
	V_BACKUP_DIRS=$G_EXTERNAL_HDD/backup
	if [ ! -d "$V_SOURCE_DIR" ] ; then
		echo "Windows directory not mounted: $V_SOURCE_DIR"
	else
		sync_dir "Users/Public/Documents"
		sync_dir "Users/Public/Pictures"
		sync_dir "Users/Wagner/Documents"
		#sync_dir "Users/Wagner/Dropbox"
		sync_dir "Users/Wagner/Favorites"
		sync_dir "Users/Wagner/Music"
		sync_dir "Users/Wagner/Pictures"
		sync_dir "Users/Wagner/Videos"
	fi
fi

if [ -n "$V_JAQUE" ] ; then
	V_SOURCE_DIR='/media/OS'
	V_BACKUP_DIRS=$G_EXTERNAL_HDD/backup
	if [ ! -d "$V_SOURCE_DIR" ] ; then
		echo "Windows directory (Jaque) not mounted: $V_SOURCE_DIR"
	else
		sync_dir "Users/Public/Documents"
		sync_dir "Users/Public/Music"
		sync_dir "Users/Public/Pictures"
		sync_dir "Users/Public/Videos"

		sync_dir "Users/Jaqueline/Desktop"
		sync_dir "Users/Jaqueline/Documents"
		sync_dir "Users/Jaqueline/Downloads"
		sync_dir "Users/Jaqueline/Favorites"
		sync_dir "Users/Jaqueline/Music"
		sync_dir "Users/Jaqueline/Pictures"
		sync_dir "Users/Jaqueline/Videos"
	fi
fi

# MY_EXCLUDE_FILE=~/bin/backup-full-exclude.txt
# MY_CURRENT_DATE=$(date +%Y-%m-%d_%H%M)
# MY_BACKUP_FILE=/var/backups/$HOSTNAME/backup-wagner-incremental-$MY_CURRENT_DATE.tar.gz
# mkdir -p /var/backups/$HOSTNAME
# chmod a+w /var/backups/$HOSTNAME
# #tar -czv $* --listed-incremental=/var/log/wagner-tar-snapshot.snar --preserve-permissions --seek --exclude-from $MY_EXCLUDE_FILE -f $MY_BACKUP_FILE $HOME/
# tar -czv $* --listed-incremental=/var/log/wagner-tar-snapshot.snar --preserve-permissions --seek --exclude-from $MY_EXCLUDE_FILE - $HOME/ | split -b 1000m - $MY_BACKUP_FILE
