#!/usr/bin/perl

$ping = `/bin/ping -c4 192.168.2.1`;
print "$ping\n";

if($ping =~ /100% packet loss/) {
  print "restarting wifi...\n";
  `/usr/bin/logger "restarting wifi..."`
  `/sbin/ifdown --force wlan0`;
  sleep 10;
  `/sbin/ifup wlan0`;
}

