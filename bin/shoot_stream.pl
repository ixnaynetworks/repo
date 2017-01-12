#!/usr/bin/perl

my $args = $ARGV[0];
my $key = $ARGV[1];

#
# am i already running?
#

my $cmd = "/bin/ps auxww | /bin/grep -v grep | /bin/grep perl | /bin/grep shoot";
print "cmd=$cmd\n";
my $out = `$cmd`;
print "$out\n";
print "\n";

my @proc = split(/\n/, $out);
if($#proc > 0) {
  die "another shoot.pl is already running!";
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
# stop stream?
#

my $cmd = "/bin/ps -ef | /bin/grep -v grep | /bin/grep ffmpeg";
print "cmd=$cmd\n";
my $out = `$cmd`;
print "$out\n";
print "\n";

#my @proc = split(/\n/, $out);
#if($#proc > -1) {
if($out =~ /(\d+) /) {
  print "ffmpeg is running!";
  print "pid=$1\n";
  `/bin/kill $1`;
  ## sleep here because if no process was found it is unnecessary
  sleep 3;
}

#
# take the pic and save it to an archive somewhere
#

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

sleep 3;
my $cmd = "/usr/bin/raspivid -o - -t 0 -vf -hf -fps 30 -b 25000000 -rot 90 -w 1280 -h 720 | /usr/local/bin/ffmpeg -loglevel panic -re -ar 44100 -ac 2 -acodec pcm_s16le -f s16le -ac 2 -i /dev/zero -f h264 -i - -vcodec copy -acodec aac -ab 128k -g 50 -strict experimental -f flv rtmp://a.rtmp.youtube.com/live2/$key";
system("$cmd &");

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
my $cmd = "/usr/bin/ssh uaws2 www/vhosts/ixnay/bin/stamp_config.pl $cam/raw/$file $w $h";
print "cmd=$cmd\n";
my $out = `$cmd`;
print "out=$out\n";
print "\n";

