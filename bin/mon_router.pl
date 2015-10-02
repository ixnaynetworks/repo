#!/usr/bin/perl

$| = 1;

#require '/home/pi/bin/ppp.pl';

my($file) = @ARGV;

#
# open output file, or STDOUT if none is specified
#

my($sh);

my $remote;
if($file)
{
  ## compute filename
  my($sec, $min, $hr, $day, $mon, $year) = localtime(time);
  $year += 1900;
  $mon++;
  $remote = sprintf("%4d%02d%02d%02d%02d%02d.txt", $year, $mon, $day, $hr, $min, $sec);

  open($sh, ">", "/var/www/status_router/$remote");
}
else
{
  open($sh, ">-");
}

#
# run some commands
#

$token = &my_get_token();
print $sh "token=$token\n";

print $sh "\n##########\n\n";
&cmd_router_print($token, "system/uptime");

print $sh "\n##########\n\n";
&cmd_router_print($token, "stats/radio");

#
# upload
#

if($file)
{
  my($name) = `/bin/hostname`;
  chomp($name);

  my($cmd) = "/usr/bin/scp /var/www/status_router/$remote uaws:www/vhosts/ixnay/htdocs/cams/$name/status_router/$remote";
  print "$cmd\n";
  $out = `$cmd`;
  print "$out\n";

  #
  # archive remote file
  #

  $cmd = "/usr/bin/ssh uaws /bin/cp www/vhosts/ixnay/htdocs/cams/$name/status_router/$remote www/vhosts/ixnay/htdocs/cams/$name/$file";
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
  $cmd =~ s/password=.*'/password=password'/;
  $out =~ s/permission" : ".*"/permission : "password"/;
  print $sh "\n$cmd";
  print $sh "\n$out";

  print $sh "\nlogging in...\n";
  $cmd = "/usr/bin/curl -s -1 -k 'https://192.168.2.1/api/login?username=admin&password=admin'";
  $out = `$cmd`;
  $cmd =~ s/password=.*'/password=password'/;
  $out =~ s/permission" : ".*"/permission : "password"/;
  print $sh "\n$cmd";
  print $sh "\n$out";
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

