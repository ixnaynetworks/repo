#!/usr/bin/perl

use DateTime;
use DateTime::Event::Sunrise;

my $args = $ARGV[0];
my $key = $ARGV[1];

#
# am i already running?
#

my $pid = `/usr/bin/pgrep shoot.pl`;
if($pid) {
  chomp($pid);
  die "another shoot.pl ($pid) is already running!";
}

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
#$daytime = 1;

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
# stop stream?
#

my $pid = `/usr/bin/pgrep ffmpeg`;
if($pid) {
  chomp($pid);
  print "ffmpeg is running ($pid)!";
  `/bin/kill $pid`;
  ## sleep here because if no process was found it is unnecessary
  sleep 1;
}

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

#
# start stream?
#

##raspivid -o - -t 0 -vf -hf -fps 30 -b 6000000 -rot 90 | ffmpeg -re -ar 44100 -ac 2 -acodec pcm_s16le -f s16le -ac 2 -i /dev/zero -f h264 -i - -vcodec copy -acodec aac -ab 128k -g 50 -strict experimental -f flv rtmp://a.rtmp.youtube.com/live2/amz7-tkk8-fdek-8hhw

$args =~ /\-rot(?:ation)? (\d+)/;
my $rot = $1;

my $try;
while($try <= 3) {
  $try++;
  sleep 1;

  my $cmd = "/usr/bin/raspivid -o - -t 0 -vf -hf -b 25000000 -rot $rot -w 1280 -h 720 --exposure night -fps 30 | /usr/local/bin/ffmpeg -loglevel panic -re -ar 44100 -ac 2 -acodec pcm_s16le -f s16le -ac 2 -i /dev/zero -f h264 -i - -vcodec copy -acodec aac -ab 128k -g 50 -strict experimental -f flv rtmp://a.rtmp.youtube.com/live2/$key";
  #my $cmd = "/usr/bin/raspivid -o - -t 0 -vf -hf -b 25000000 -rot 270 -w 1280 -h 720 --framerate 30 --exposure night | /usr/local/bin/ffmpeg -loglevel panic -re -ar 44100 -ac 2 -acodec pcm_s16le -f s16le -ac 2 -i /dev/zero -f h264 -i - -i /home/pi/logo_night.png -vcodec copy -acodec aac -ab 128k -g 50 -strict experimental -f flv rtmp://a.rtmp.youtube.com/live2/$key";
  print "$cmd\n";
  system("$cmd &");

  my $pid = `/usr/bin/pgrep raspivid`;
  if($pid) {
    chomp($pid);
    print "\nraspivid is running ($pid)...\n\n";
    last;
  }
  else {
    print "\nraspivid is NOT running, will try to start it ", (3 - $try), " more times...\n\n";
  }
}

#
# upload filename to ixnay, and a dir computed from the hostname
#

unless(-e "/home/pi/tmp/$file") {
  die "photo didn't take!"
}

my $cam = `/bin/hostname`;
chomp($cam);
my $cmd = "/usr/bin/scp /home/pi/tmp/$file uaws2:www/vhosts/ixnay/htdocs/cams/$cam/raw";
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
my $cmd = "/usr/bin/ssh uaws2 www/vhosts/ixnay/bin/stamp_config.pl $cam/raw/$file $w $h $logo";
print "cmd=$cmd\n";
my $out = `$cmd`;
print "out=$out\n";
print "\n";

#
#
#

exit;

