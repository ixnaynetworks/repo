#!/usr/bin/perl

$| = 1;

#require '/home/pi/cnf/webcam.pl';
require '/home/pi/bin/ppp.pl';

open(LOG, ">/home/pi/log/ppp_enable");

$token = &get_token();

if(&ppp_enabled($token) and &network_detected())
{
  print LOG "\nnothing more to do\n";
}
else
{
  ## enabling ppp
  print LOG "\nenabling ppp...\n";
  $cmd = "/usr/bin/curl -s -1 -k -X PUT -H \"Content-Type: application/json\" -d '{ \"enabled\" : true }' 'https://192.168.2.1/api/ppp?token=$token'";
  $out = `$cmd`;
  print LOG "\n$cmd\n$out\n";

  &rcell_restart($token);

  &openvpn_restart();
}

close(LOG);

#$cmd = "/usr/bin/scp -v /home/pi/log/ppp_enable uaws:www/vhosts/pinecreek/htdocs/webcam/conf/$cam/ppp_enable_log";
#$out = `$cmd`;
#print LOG "\n$cmd\n$out\n";

