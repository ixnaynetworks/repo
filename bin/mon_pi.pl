#!/usr/bin/perl

$| = 1;

#require '/home/pi/bin/ppp.pl';

my($file) = @ARGV;

#
# open output file, or STDOUT if none is specified
#

my($sh);

if($file) {
  open($sh, ">", "/var/www/mon/$file");
}
else {
  open($sh, ">-");
}

#
# run some commands
#

&cmd_print($sh, "/bin/date");

print $sh "\n##########\n\n";
&cmd_print($sh, "/usr/bin/uptime");

print $sh "\n##########\n\n";
&cmd_print($sh, "/bin/df -h");

print $sh "\n##########\n\n";
&cmd_print($sh, "/usr/bin/top -b -n1");

#
# upload
#

if($file)
{
  my($name) = `/bin/hostname`;
  chomp($name);

  my($cmd) = "/usr/bin/scp /var/www/mon/$file uaws:www/vhosts/ixnay/htdocs/cams/$name/$file";
  print "$cmd\n";
  $out = `$cmd`;
  print "$out\n";
}

exit;

#
#
#

sub cmd_print
{
  my($sh, $cmd) = @_;
  print $sh "$cmd\n";
  $out = `$cmd`;
  print $sh "$out\n";
}

