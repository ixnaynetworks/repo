#!/usr/bin/perl

$| = 1;

require '/home/pi/bin/ppp.pl';

open(LOG, ">/home/pi/log/ppp_disable");

$token = &get_token();

if(&ppp_enabled($token) and &network_detected())
{
  ## disabling ppp
  print LOG "\ndisabling ppp...\n";
  $cmd = "/usr/bin/curl -s -1 -k -X PUT -H \"Content-Type: application/json\" -d '{ \"enabled\" : false }' 'https://192.168.2.1/api/ppp?token=$token'";
  $out = `$cmd`;
  print LOG "\n$cmd\n$out\n";

  &rcell_restart($token);
}
else
{
  print LOG "\nnothing to do\n";
}

close(LOG);

