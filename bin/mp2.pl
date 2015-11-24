#!/usr/bin/perl

$| = 1;

#require '/home/pi/bin/ppp.pl';

$upload = $ARGV[0];

$time = time();

#
# open output file, or STDOUT if none is specified
#

my($sec, $min, $hr, $day, $mon, $year) = localtime($time);
my $year += 1900;
my $mon++;
my $file = sprintf("%4d%02d%02d%02d%02d%02d.txt", $year, $mon, $day, $hr, $min, $sec);

open(TXT, ">", "/var/www/graphs2/status_pi/$file");
print "file=$file\n";

#
# run some commands
#

my($cmd, $out);

#
# date
#

$cmd = "/bin/date +\"%Y/%m/%d %T\"";
my $date = `$cmd`;
print TXT "\n$cmd\n", $date;

## for later use...
chomp($date);

#
# uptime
#

$cmd = "/usr/bin/uptime";
$out = `$cmd`;
print TXT "\n##########\n\n", "$cmd\n", $out;

#
# traceroute
#

$cmd = "/usr/bin/sudo /usr/sbin/traceroute -T -n 54.69.208.7";
$out = `$cmd`;
print TXT "\n##########\n\n", "$cmd\n", $out;

my($sum, $num, $net);
if($out =~ /\n[\s\d].*54.69.208.7(.*)/s) {
  foreach (split(/\s+/, $1)) {
    if(/^[\d\.]+$/) {
      $sum += $_;
      $num++;
    }
  }
  $net = $sum / $num;
}

&record_dat("/var/www/html/graphs2/net.txt", $net);

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

print TXT "\n##########\n\n", "$cmd\n", $out;

&record_dat("/var/www/html/graphs2/temp.txt", $temp);

#
# mopicli
#

#$cmd = "/usr/sbin/mopicli -e";
#$out = `$cmd`;
#print $sh "\n##########\n\n", "$cmd\n", $out;

#
# df
#

$cmd = "/bin/df -h";
$out = `$cmd`;
print TXT "\n##########\n\n", "$cmd\n", $out;

my $disk;
if($out =~ /dev\/root.* (\d\d?)\%/) {
  $disk = $1;
}

&record_dat("/var/www/html/graphs2/disk.txt", $disk);

#
# top
#

$cmd = "/usr/bin/top -b -n1 | /usr/bin/head -30";
$out = `$cmd`;
print TXT "\n##########\n\n", "$cmd\n", $out;


#
# upload
#

if($upload)
{
  my($name) = `/bin/hostname`;
  chomp($name);

  my $dir = "www/vhosts/ixnay/htdocs/cams/$name";

  my $cmd;

  $cmd  = "/usr/bin/scp";
  $cmd .= " /var/www/html/graphs2/status_pi/$file";
  $cmd .= " uaws:$dir/status_pi/$file";

  print "$cmd\n";
  $out = `$cmd`;
  print "$out\n";

  $cmd  = "/usr/bin/scp";
  $cmd .= " /var/www/html/graphs2/net.txt";
  $cmd .= " /var/www/html/graphs2/temp.txt";
  $cmd .= " /var/www/html/graphs2/disk.txt";
  $cmd .= " uaws:$dir/graphs2";

  print "$cmd\n";
  $out = `$cmd`;
  print "$out\n";

  $cmd  = "/usr/bin/ssh uaws";
  $cmd .= "  www/vhosts/ixnay/bin/graphs4.pl";
  $cmd .= "; /bin/cp $dir/status_pi/$file $dir/status_pi.txt";

  print "$cmd\n";
  $out = `$cmd`;
  print "$out\n";
}

exit;

#
#
#

sub record_dat
{
  my($dfile, $data) = @_;
 
  ## check times for potential gap
  my $mtime = (stat($dfile))[9];
  my $gap;
  if(($mtime - $time) > 3600) {
    $gap = "\n";
  }

  ## write
  open(NET, ">>$dfile");
  print NET $gap, "$date $data\n";
  close(NET);

  ## archive
  $dfile =~ /(.*)\.txt/;
  my $dir = $1;
  `/bin/cp $dfile $dir/$file`;
}

