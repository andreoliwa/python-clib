#!/usr/bin/perl

# http://www.linuxquestions.org/questions/programming-9/perl-with-bash-environment-vars-456340/
# http://www.unix.com/shell-programming-scripting/66293-passing-variable-bash-perl-bash-script.html
# http://www.perlmonks.org/?node_id=684685

print "Connects to your work VPN through snx, using the following environment variables for server, user and password:\n" ;
print "Server..: $ENV{'G_WORK_VPN_SERVER'}\n" ;
print "User....: $ENV{'G_WORK_VPN_USER'}\n" ;
print "Password: $ENV{'G_WORK_VPN_PASSWORD'}\n" ;
print "Connecting...\n" ;

$pid = open( PIPE , "| snx -s $ENV{'G_WORK_VPN_SERVER'} -u $ENV{'G_WORK_VPN_USER'}" ) or die "Error: snx is not working: $!\n" ;
print PIPE "$ENV{'G_WORK_VPN_PASSWORD'}" ;
close( PIPE ) ;
