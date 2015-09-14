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
&cmd_temp_print($sh);

print $sh "\n##########\n\n";
&cmd_print($sh, "/bin/df -h");

print $sh "\n##########\n\n";
&cmd_print($sh, "/usr/bin/top -b -n1");
#&cmd_print($sh, "/usr/bin/top -b -n1 | /usr/bin/head -30");

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

sub cmd_temp_print
{
  my($sh) = @_;

  my($cmd) = "/opt/vc/bin/vcgencmd measure_temp";
  print $sh "$cmd\n";
  $out = `$cmd`;
  print $sh "$out";

  if($out =~ /^temp=(.*)'C/) {
    my($f) = (($1 * 9) / 5) + 32;
    printf $sh "temp=%.1f'F\n", $f;
  }
}

