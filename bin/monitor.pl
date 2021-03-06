#!/usr/bin/perl

$| = 1;

#require '/home/pi/bin/ppp.pl';

$upload = $ARGV[0];

my($name) = `/bin/hostname`;
chomp($name);

my $time = time;

#
# open output file, or STDOUT if none is specified
#

my($sec, $min, $hr, $day, $mon, $year) = localtime($time);
$year += 1900;
$mon++;
my $file = sprintf("%4d%02d%02d%02d%02d%02d.txt", $year, $mon, $day, $hr, $min, $sec);

open(TXT, ">", "/home/pi/status_pi/$file");

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
# wifi signal
#

$cmd = "/sbin/iwconfig wlan0 2>&1";
$out = `$cmd`;
print TXT "\n##########\n\n", "$cmd\n", $out;

if($out !~ /No such device/) {
  my $wifi = 0;
  if($out =~ /Signal level=(\d\d?\d?)\/100/) {
    $wifi = $1;
  }
  elsif($out =~ /Signal level=(\-\d\d\d?) dBm/) {
    if($1 > -50) {
      $wifi = 100;
    }
    elsif($1 > -100) {
      $wifi = (2 * $1) + 100;
    }
  }
  &record_dat("wifi.txt", $wifi);
}

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

&record_dat("net.txt", $net);

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

&record_dat("temp.txt", $temp);

#
# mopicli
#

$cmd = "/usr/sbin/mopicli -e";
$out = `$cmd`;
print TXT "\n##########\n\n", "$cmd\n", $out;

my($volt);
if($out =~ /Source #1 voltage: (\d+)/) {
  $volt = $1;
}

&record_dat("volt.txt", $volt);

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

&record_dat("disk.txt", $disk);

#
# memory
#

$cmd = "/usr/bin/free";
$out = `$cmd`;
print TXT "\n##########\n\n", "$cmd\n", $out;

#
# python processes
#

$cmd = "/bin/ps auxww | /bin/grep python";
$out = `$cmd`;
print TXT "\n##########\n\n", "$cmd\n", $out;

#
# top
#

$cmd = "/usr/bin/top -b -n1 | /usr/bin/head -30";
$out = `$cmd`;
print TXT "\n##########\n\n", "$cmd\n", $out;

#
#
#

close(TXT);

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
  $cmd .= " /home/pi/status_pi/$file";
  $cmd .= " uaws:$dir/status_pi/$file";

  #print "$cmd\n";
  $out = `$cmd`;
  #print "$out\n";

  #$cmd  = "/usr/bin/scp";
  #$cmd .= " /var/www/html/graphs2/net.txt";
  #$cmd .= " /var/www/html/graphs2/wifi.txt";
  #$cmd .= " /var/www/html/graphs2/temp.txt";
  #$cmd .= " /var/www/html/graphs2/disk.txt";
  #$cmd .= " /var/www/html/graphs2/volt.txt";
  #$cmd .= " uaws:$dir/graphs";

  #print "$cmd\n";
  #$out = `$cmd`;
  #print "$out\n";

  $cmd  = "/usr/bin/ssh uaws";
  $cmd .= " '";
  $cmd .= "  www/vhosts/ixnay/bin/graph.pl $name";
  $cmd .= "; /bin/cp $dir/status_pi/$file $dir/status_pi.txt";
  $cmd .= " '";

  #print "$cmd\n";
  $out = `$cmd`;
  #print "$out\n";
}

exit;

#
#
#

sub record_dat
{
  my($dfile, $data) = @_;
 
  my $dir = "/home/pi/graphs";

  ## check times for potential gap
  my $mtime = (stat("$dir/$dfile"))[9];
  my $gap;
  if(($time - $mtime) > 3600) {
    $gap = "\n";
  }

  ## write local
  open(NET, ">>$dir/$dfile");
  print NET $gap, "$date $data\n";
  close(NET);

  if($upload)
  {
    ## do a remote write here?
    $dir = "www/vhosts/ixnay/htdocs/cams/$name/graphs";
    $gap = "\\n" if($gap);
    my $cmd = "/usr/bin/ssh uaws '/usr/bin/printf \"$gap$date $data\\n\" >> $dir/$dfile'";
    #print "cmd=$cmd\n";
    `$cmd`;
  }

  ## archive
  #$dfile =~ /(.*)\.txt/;
  #my $dir = $1;
  #`/bin/cp $dfile $dir/$file`;
}

