#!/usr/bin/perl

my %conf;
$conf{'SCHED'} = "*/5";
$conf{'RARGS'} = "-w 1870 -h 940 -q 95 --saturation 25 --sharpness 15";

#
# args, i should just read this ish in from a config file
#

my $sched;
if($ARGV[0]) {
  $sched = $ARGV[0];
}
else {
  $sched = $conf{'SCHED'};
}

my $r_args;
if($ARGV[1]) {
  $r_args = $ARGV[1];
}
else {
  $r_args = $conf{'RARGS'};
}

#
# what time is it?
#

sleep 1;
my $time = time;
print "time=$time\n";
print "\n";

#
# am i already running?
#

my $cmd = "/bin/ps auxww | /bin/grep -v grep | /bin/grep raspistill";
print "cmd=$cmd\n";
my $out = `$cmd`;
print "$out\n";
print "\n";

if($out) {
  die "another raspistill is already running!";
}

#
# compute filename
#

my($sec, $min, $hr, $day, $mon, $year) = localtime($time);
$year += 1900;
$mon++;
my $file = sprintf("%4d%02d%02d%02d%02d%02d.jpg", $year, $mon, $day, $hr, $min, $sec);
print "\nfile=$file\n";
print "\n";

#
# take the pic and save it to an archive somewhere
#

my $cmd = "/usr/bin/raspistill -v -n $r_args -o /home/pi/tmp/$file";
print "cmd=$cmd\n";
my $out = `$cmd`;
print "$out\n";
print "\n";

#
# timestamp stuff
#

$r_args =~ /\-w (\d+) \-h (\d+)/;
my $rectangle = "0," . ($2 - 45) . ",$1,$2";
my $baseline = $2 - 15;
my $base = "/home/pi";
my $label = "Peak Cam // 8,225 ft // Northwest View";

my $cmd = "/usr/bin/convert $base/tmp/$file -fill '#0008' -draw 'rectangle $rectangle' -fill '#CCCCCC' -pointsize 20 -font Courier-Bold -annotate +15+$baseline '$label' $base/img/logo.png -gravity northwest -geometry +20+0 -composite $base/img/rpi.png -gravity southeast -geometry +15+10 -composite $base/img/left_bottom_label.jpg";
print "cmd=$cmd\n";
$out = `$cmd`;
print "out=$out\n";
print "\n";

my $timestamp = sprintf("%4d/%02d/%02d %02d:%02d", $year, $mon, $day, $hr, $min);

my $cmd = "/usr/bin/convert -background '#00000000' -fill '#CCCCCC' -pointsize 20 -font Courier-Bold label:'$timestamp' miff:- | composite -gravity southeast -geometry +45+9 - $base/img/left_bottom_label.jpg $base/arc/$file";
print "cmd=$cmd\n";
$out = `$cmd`;
print "out=$out\n";
print "\n";

#
# upload?
#

$sched =~ /\*\/(\d+)/;
if(($min % $1) == 0)
{
  my $remote_srvr = "uaws";
  my $cam = `/bin/hostname`;
  chomp($cam);
  print "cam=$cam\n";
  print "\n";

  my $cmd = "/usr/bin/scp $base/arc/$file $remote_srvr:www/vhosts/ixnay/htdocs/cams/$cam/arc";
  print "cmd=$cmd\n";
  $out = `$cmd`;
  print "out=$out\n";
  print "\n";

  my $cmd = "/usr/bin/ssh $remote_srvr /bin/cp www/vhosts/ixnay/htdocs/cams/$cam/arc/$file www/vhosts/ixnay/htdocs/cams/$cam/current.jpg";
  print "cmd=$cmd\n";
  $out = `$cmd`;
  print "out=$out\n";
  print "\n";
}

#
# write a timelapse still image?
#

opendir(AVC, "$base/avc");
my @avc = sort grep(/^file\-\d+\.jpg$/, readdir(AVC));
closedir(AVC);

my $poster = sprintf("$base/avc/file-%03d.jpg", $#avc + 1);

my $cmd = "/usr/bin/convert $base/arc/$file -resize x360 $poster";
print "cmd=$cmd\n";
$out = `$cmd`;
print "out=$out\n";
print "\n";

my $cmd = "/bin/cp $poster $base/img/poster.jpg";
print "cmd=$cmd\n";
$out = `$cmd`;
print "out=$out\n";
print "\n";
exit;

