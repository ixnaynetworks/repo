#!/usr/bin/perl

#$gw = "192.168.1.1";
$gw = "192.168.2.1";

if($ARGV[0] eq "start")
{
  #print "starting wifi...\n";
  `/usr/bin/logger "starting wifi..."`;
  `/sbin/ifup wlan0 > /dev/null 2>&1`;
}
elsif($ARGV[0] eq "stop")
{
  #print "stopping wifi...\n";
  `/usr/bin/logger "stopping wifi..."`;
  `/sbin/ifdown --force wlan0`;
}
elsif($ARGV[0] eq "check")
{
  unless(&ping()) {
    #print "restarting wifi...\n";
    `/usr/bin/logger "restarting wifi..."`;
    `/sbin/ifdown --force wlan0`;
    sleep 10;
    `/sbin/ifup wlan0 > /dev/null 2>&1`;
  }

  ## if that didn't work... might just need to reboot...
  sleep 10;
  unless(&ping()) {
    #print "rebooting...\n";
    `/usr/bin/logger -t wifi_cmd "rebooting..."`;
    sleep 10;
    `/sbin/shutdown -r now`;
  }
}
else
{
  die "bad cmd: $ARGV[0]";
}

exit;

#
#
#

sub ping
{
  my $ping = `/bin/ping -c4 -w1 $gw`;
  #print "$ping\n";

  if($ping =~ /1 received/) {
    return 1;
  }
  else {
    return 0;
  }
}

