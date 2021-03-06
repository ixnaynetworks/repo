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

my $cmd = "/bin/ps auxww | /bin/grep -v grep | /bin/grep perl | /bin/grep upload";
print "cmd=$cmd\n";
my $out = `$cmd`;
print "$out\n";
print "\n";

my @proc = split(/\n/, $out);
if($#proc > 0) {
  die "another upload.pl is already running!";
}

## in order to apply the "stamp" below we just need to know the time is before/after sunset

#
# day or night?
#

my $sun = DateTime::Event::Sunrise->new(longitude => -111.75547, latitude => +41.92683);
my $dt = DateTime->now(time_zone => 'America/Denver');

my $daytime = 0;
if(($dt->epoch > $sun->sunrise_datetime($dt)->epoch) and ($dt->epoch < $sun->sunset_datetime($dt)->epoch)) {
  print "daytime: yes\n";
  $daytime = 1;
}
else {
  print "daytime: no\n";
}

#
# wait till shoot is done
#

while(1)
{
  sleep 1;

  my $cmd = "/bin/ps auxww | /bin/grep -v grep | /bin/grep perl | /bin/grep shoot";
  print "cmd=$cmd\n";
  my $out = `$cmd`;
  print "$out\n";
  print "\n";

  last unless($out);
}

#
# upload filename to ixnay, and a dir computed from the hostname
#

my $file = `/bin/ls -1 /home/pi/tmp/*.jpg | /usr/bin/tail -1`;
$file =~ s/.*\/(.*)\n/$1/;
print "file=$file\n";
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

