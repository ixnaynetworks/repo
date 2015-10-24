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

$cmd = "/bin/date +\"%Y/%m/%d %T\"";
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

my $sum, $num, $net;
if($out =~ /\n[\s\d].*54.69.208.7(.*)/s) {
  foreach (split(/\s+/, $1)) {
    if(/^[\d\.]+$/) {
      $sum += $_;
      $num++;
    }
  }
  $net = $sum / $num;
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

#
# upload
#

if($file)
{
  my($name) = `/bin/hostname`;
  chomp($name);

  $base = "www/vhosts/ixnay/htdocs/cams/$name";

  my($cmd) = "/usr/bin/scp /var/www/status_pi/$remote uaws:$base/status_pi/$remote";
  print "$cmd\n";
  $out = `$cmd`;
  print "$out\n";

  #
  # archive remote file
  #

  $ssh = "/usr/bin/ssh uaws ";

  $cmd = "$ssh /bin/cp $base/status_pi/$remote $base/$file";
  print "$cmd\n";
  $out = `$cmd`;
  print "$out\n";

  #
  # write them to the graph files on the server, and rebuild graphs?
  #

  chomp($date);

  $cmd = $ssh;
  $cmd .= "' echo \"$date $temp\" >> $base/graphs/temp.txt";
  $cmd .= "; echo \"$date $net\"  >> $base/graphs/net.txt";
  $cmd .= "; echo \"$date $disk\" >> $base/graphs/disk.txt";
  $cmd .= "; www/vhosts/ixnay/bin/graph3.pl $name";
  $cmd .= "'";

  print "$cmd\n";
  $out = `$cmd`;
  print "$out\n";
}

exit;

