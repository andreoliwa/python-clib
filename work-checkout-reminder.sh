#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Remind the worker to checkout. Can be called in the crontab file.

How to install the script in your crontab, for automatic execution:

1) Put this line in your ~/.bashrc file:
xhost local:\$(whoami) > /dev/null
(based on info from http://askubuntu.com/questions/85612/how-to-call-zenity-from-cron-script)

2) Edit your user's crontab:
$ crontab -e

3) Insert this line at the end, so the script runs two minutes to midnight:
58 23 * * * $0 -u http://write-your-checkout-url-here -t 300

4) Confirm your crontab is set:
$ crontab -l

OPTIONS
-u  Checkout URL (default: $G_WORK_TIMECLOCK_URL)
-t  Timeout in seconds (default: 10)
-h  Help"
	exit $1
}

V_TIMEOUT=10
V_URL=
while getopts "t:u:h" V_ARG ; do
	case $V_ARG in
	t)	V_TIMEOUT=$OPTARG ;;
	u)	V_URL=$OPTARG ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

V_HTML_FILE=/tmp/$(basename $0).html

if [ -z "$V_URL" ] ; then
	# Load the global variables (needed when run from crontab)
	source ~/bin/my-variables
	V_URL=$G_WORK_TIMECLOCK_URL
fi

echo "<h1>Don't forget to checkout!!!</h1>
<p>Checkout page: <a href='$V_URL'>$V_URL</a>" > $V_HTML_FILE

zenity --title="Checkout before it's too late" --text-info --filename=$V_HTML_FILE --html --timeout=$V_TIMEOUT --width=1000 --height=500 --display=:0.0

rm $V_HTML_FILE
