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

my($cmd, $out);

#
# date
#

$cmd = "/bin/date +\"%D %T\"";
my $date = `$cmd`;
print $sh "\n$cmd\n", $date;

#
# uptime
#

$cmd = "/usr/bin/uptime";
$out = `$cmd`;
print $sh "\n##########\n\n", "$cmd\n", $out;

#
# traceroute
#

$cmd = "/usr/bin/sudo /usr/sbin/traceroute -T -n 54.69.208.7";
$out = `$cmd`;
print $sh "\n##########\n\n", "$cmd\n", $out;

my $net;
if($out =~ /54.69.208.7\s+([\d\.]+) ms\s+([\d\.]+) ms\s+([\d\.]+) ms/) {
  $net = ($1 + $2 + $3) / 3;
}

#
# temp
#

$cmd = "/opt/vc/bin/vcgencmd measure_temp";
$out = `$cmd`;

my $temp;
if($out =~ /^temp=(.*)'C/) {
  $temp = sprintf "%.1f", (($1 * 9) / 5) + 32;
  $out =~ s/^temp=.*'C/temp=$temp\'F/;
}

print $sh "\n##########\n\n", "$cmd\n", $out;

#
# mopicli
#

$cmd = "/usr/sbin/mopicli -e";
$out = `$cmd`;
print $sh "\n##########\n\n", "$cmd\n", $out;

#
# df
#

$cmd = "/bin/df -h";
$out = `$cmd`;
print $sh "\n##########\n\n", "$cmd\n", $out;

my $disk;
if($out =~ /dev\/root.* (\d\d?)\%/) {
  $disk = $1;
}

#
# top
#

$cmd = "/usr/bin/top -b -n1 | /usr/bin/head -30";
$out = `$cmd`;
print $sh "\n##########\n\n", "$cmd\n", $out;

exit;


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

  $ssh = "/usr/bin/ssh uaws ";

  $cmd = "$ssh /bin/cp www/vhosts/ixnay/htdocs/cams/$name/status_pi/$remote www/vhosts/ixnay/htdocs/cams/$name/$file";
  print "$cmd\n";
  $out = `$cmd`;
  print "$out\n";

  #
  # write them to the dat files on the server...
  #

  chomp($date);
  $cam = `/usr/bin/hostname`;
  $base = "/home/michael/www/vhosts/ixnay/htdocs/cams/$cam/graphs";

  $cmd = $ssh;
  $cmd .= "  echo \"$date $temp\" >> $base/temp.dat";
  $cmd .= "; echo \"$date $net\"  >> $base/net.dat";
  $cmd .= "; echo \"$date $disk\" >> $base/disk.dat";

  print "$cmd\n";
  $out = `$cmd`;
  print "$out\n";
}

exit;

