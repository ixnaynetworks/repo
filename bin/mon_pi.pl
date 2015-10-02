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

  open($sh, ">", "/var/www/status_pi/$remote");
}
else
{
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
&cmd_print($sh, "/usr/sbin/mopicli -e");

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

  my($cmd) = "/usr/bin/scp /var/www/status_pi/$remote uaws:www/vhosts/ixnay/htdocs/cams/$name/status_pi/$remote";
  print "$cmd\n";
  $out = `$cmd`;
  print "$out\n";

  #
  # archive remote file
  #

  $cmd = "/usr/bin/ssh uaws /bin/cp www/vhosts/ixnay/htdocs/cams/$name/status_pi/$remote www/vhosts/ixnay/htdocs/cams/$name/$file";
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

