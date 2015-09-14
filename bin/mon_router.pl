#!/usr/bin/perl

$| = 1;

#require '/home/pi/bin/ppp.pl';

my($file) = @ARGV;

#
# open output file, or STDOUT if none is specified
#

my($sh);

if($file) {
  open($sh, ">", $file);
}
else {
  open($sh, ">-");
}

#
# run some commands
#

$token = &my_get_token();
print $sh "token=$token\n";

print $sh "\n##########\n\n";
&cmd_router_print($token, "stats/radio");

#
# upload
#

if($file)
{
  my($name) = `/bin/hostname`;
  chomp($name);

  my($cmd) = "/usr/bin/scp $file uaws:www/vhosts/ixnay/htdocs/cams/$name/status_router.txt";
  print "$cmd\n";
  $out = `$cmd`;
  print "$out\n";
}

exit;

#
#
#

sub my_get_token
{
  my($token);

  print $sh "\ngetting token...\n";
  my $cmd = "/usr/bin/curl -s -1 -k 'https://192.168.2.1/api/logout?username=admin&password=admin'";
  my $out = `$cmd`;
  print $sh "\n$cmd\n$out\n";

  print $sh "\nlogging in...\n";
  $cmd = "/usr/bin/curl -s -1 -k 'https://192.168.2.1/api/login?username=admin&password=admin'";
  $out = `$cmd`;
  print $sh "\n$cmd\n$out\n";
  if($out =~ /"token" : "(.*?)"/) {
    $token = $1;
  }

  return $token;
}

sub cmd_router_print
{
  my($token, $str) = @_;

  my $cmd = "/usr/bin/curl -s -1 -k 'https://192.168.2.1/api/$str?token=$token'";
  my $out = `$cmd`;
  print $sh "\n$cmd\n$out\n";
}

