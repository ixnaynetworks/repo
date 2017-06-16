#!/usr/bin/perl

use DateTime;
use DateTime::Event::Sunrise;

#my $args = $ARGV[0];
my $args = `/bin/cat /home/pi/config`;
chomp($args);
unless($args) {
  $args = "--rotation 0 -w 1280 -h 720 -n -q 95 --saturation 15 --sharpness 15";
}
print "\nargs=$args\n";

#
# am i already running?
#

my $cmd = "/bin/ps auxww | /bin/grep -v grep | /bin/grep perl | /bin/grep s2";
print "\ncmd=$cmd\n";
my $out = `$cmd`;
print "$out\n";
print "\n";

my @proc = split(/\n/, $out);
if($#proc > 0) {
  die "another shoot.pl is already running!";
}

#
# day or night?
#

## this "shoot" script will switch to night vision 1:20 after sunset until 1:20 before sunrise.

my $sun = DateTime::Event::Sunrise->new(longitude => -111.75547, latitude => +41.92683);
my $dt = DateTime->now(time_zone => 'America/Denver');

my $daytime = 0;
if(($dt->epoch < ($sun->sunset_datetime($dt)->epoch + 4800)) and ($dt->epoch > ($sun->sunrise_datetime($dt)->epoch - 4800))) {
  print "daytime: yes\n";
  $daytime = 1;
}
else {
  print "daytime: no\n";
}

#
# compute filename
#

my($sec, $min, $hr, $day, $mon, $year) = localtime(time);
$year += 1900;
$mon++;
my $file = sprintf("%4d%02d%02d%02d%02d%02d.jpg", $year, $mon, $day, $hr, $min, $sec);
print "\nfile=$file\n";
print "\n";

#
# take the pic and save it to an archive somewhere
#

unless($daytime) {
  $args .= " --exposure night";
}
#my $cmd = "/usr/bin/raspistill -v -w 960 -h 720 -n -q 95 --saturation 25 --sharpness 15 -o /home/pi/tmp/$file";
my $cmd = "/usr/bin/raspistill -v -n $args -o /home/pi/tmp/$file";
print "cmd=$cmd\n";
my $out = `$cmd`;
print "$out\n";
print "\n";

## done here?

exit;

#
# upload filename to ixnay, and a dir computed from the hostname
#

my $cam = `/bin/hostname`;
chomp($cam);
my $cmd = "/usr/bin/scp /home/pi/tmp/$file uaws:www/vhosts/ixnay/htdocs/cams/$cam/raw";
print "cmd=$cmd\n";
my $out = `$cmd`;
print "out=$out\n";
print "\n";

#
# call the stamp.pl on ixnay to do the rest
#

$args =~ /\-w (\d+) \-h (\d+)/;
my $w = $1;
my $h = $2;
if($daytime) {
  $logo = "logo_day.png";
}
else {
  $logo = "logo_night.png";
}
my $cmd = "/usr/bin/ssh uaws www/vhosts/ixnay/bin/stamp_config.pl $cam/raw/$file $w $h $logo";
print "cmd=$cmd\n";
my $out = `$cmd`;
print "out=$out\n";
print "\n";

