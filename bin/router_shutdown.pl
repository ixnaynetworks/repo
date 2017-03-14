#!/usr/bin/perl

$| = 1;

require '/home/pi/bin/router.pl';

open(LOG, ">/home/pi/log/router");

my $token = &get_token();

print LOG "\nrestarting...\n";
$cmd = "/usr/bin/curl -s -1 -k -X POST -d \"\" 'https://192.168.2.1/api/command/save_restart?token=$token'";
$out = `$cmd`;
print LOG "\n$cmd\n$out\n";

close(LOG);


sub rcell_restart
{
  my($token) = @_;

}


