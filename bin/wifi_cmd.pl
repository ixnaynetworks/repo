#!/usr/bin/perl

$gw = "192.168.1.1";

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
  $ping = `/bin/ping -c4 $gw`;
  #print "$ping\n";

  if($ping =~ /100% packet loss/) {
    #print "restarting wifi...\n";
    `/usr/bin/logger "restarting wifi..."`;
    `/sbin/ifdown --force wlan0`;
    sleep 10;
    `/sbin/ifup wlan0 > /dev/null 2>&1`;
  }
}
else
{
  die "bad cmd: $ARGV[0]";
}

