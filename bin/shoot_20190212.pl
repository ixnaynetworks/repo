#!/usr/bin/perl

use lib '/home/pi/lib';
use Conf;

#
# am i already running?
#

$0 =~ /(.*\/)?(.*)/;
my $myself = $2;
my $count = `/usr/bin/pgrep -c $myself`;
if($count > 1) {
  die "another $myself is already running!";
}

use DateTime;
use DateTime::Event::Sunrise;

#
# get latest configs
#

my $conf = new Conf;

#$conf->refresh();

my $cam = $conf->name();

#
# stream or still?
#

my $args = `/bin/cat /home/pi/conf/raspistill`;
chomp($args);

my $mogrify = `/bin/cat /home/pi/conf/mogrify`;
chomp($mogrify);

my $file;

my $streaming = $conf->streaming();
print "streaming=$streaming\n";

if($streaming)
{
  if(&upload_scheduled()) {
    &stream_stop();
    sleep 2;  ## let the cam recover?
    $file = &shoot();
  }

  unless(&stream_pid()) {
    &stream_start($streaming);
  }
}
else
{
  if(&stream_pid())
  {
    ## the stream just got switched to another cam
    sleep 15;
  }
  &stream_stop();
  $file = &shoot();
}

#
# upload
#

if(&upload_scheduled()) {
  #&upload($daytime, $file);
  &upload_stamped($daytime, $file);
}

#
# after, stuff
#   record background brightness?
#   record shutter speed

if($file) {

my $cmd = "/usr/bin/jhead /home/pi/raw/$file";
print "$cmd\n";
my $out = `$cmd`;
print "$out\n";

if($out =~ /Exposure time: (\d+\.\d+) s/s) {
  print "ex time? $1\n";
  open(SS, ">/home/pi/vals/ss");
  print SS "$1";
  close(SS);
}

}

#
# rsync config, with random sleep?
#

#my $sleep_num = sprintf("%0.1f", rand(10));
#print "sleeping $sleep_num...\n";
#sleep $sleep_num;

exit;

#
#
#

sub upload_scheduled
{
  my $upload = 0;

  my($min, $hr) = (localtime(time))[1,2];

  if(($ARGV[0] eq "upload") or ($ARGV[0] eq "up")) {
    $upload = 1;
  }
  #elsif(-e "/home/pi/conf/streaming") {
  #  ## only interrupt long-running stream
  #  if(time() - (stat("/home/pi/conf/streaming"))[9] > 630) {
  #    ## upload every-10-minutes during stream
  #    if($min =~ /0$/) {
  #      $upload = 1;
  #    }
  #  }
  #}
  elsif(($hr < 6) or ($hr > 21)) {
    if($min =~ /0$/) {
      ## upload every-10-minutes before 6am and after 10pm
      $upload = 1;
    }
  }
  elsif(-e "/home/pi/conf/upload_02m") {
    $upload = 1 if($min =~ /[02468]$/);
  }
  elsif(-e "/home/pi/conf/upload_05m") {
    $upload = 1 if($min =~ /[05]$/);
  }
  elsif(-e "/home/pi/conf/upload_20m") {
    $upload = 1 if($min =~ /^0|20|40$/);
  }
  elsif($min =~ /0$/) {
    ## upload every-10-minutes by default
    $upload = 1;
  }
  return $upload;
}

#
#
#

sub stream_pid
{
  my $pid;

  my $pid = `/usr/bin/pgrep ffmpeg`;
  chomp($pid);

  return $pid;
}

sub stream_stop
{
  my $pid = &stream_pid();

  if($pid)
  {
    print "ffmpeg is running ($pid)!";
    `/bin/kill $pid`;

    ## sleep here because if no process was found it is unnecessary
    #sleep 1;
  }
}

sub stream_start
{
  my($key) = @_;

  #
  # fix rotation
  #

  $args =~ /\-rot(?:ation)? (\d+)/;
  my $rot = $1;
  if($rot < 180) {
    $rot += 180;
  }
  else {
    $rot -= 180;
  }

  #
  # get key
  #

  #my $key = `/bin/cat /home/pi/conf/streaming`;
  #chomp($key);

  #
  # logo
  #

  my $logo;
  if(-e "/home/pi/vals/bg_bright") {
    $logo = "/home/pi/conf/logo_day.png";
  }
  else {
    $logo = "/home/pi/conf/logo_night.png";
  }

  #
  # find binary
  #

  my $ffmpeg;
  if(-e "/usr/local/bin/ffmpeg") {
    $ffmpeg = "/usr/local/bin/ffmpeg";
  }
  else {
    $ffmpeg = "ffmpeg";
  }

  #
  # start
  #
 
  my $try;
  while($try <= 3) {
    $try++;
    sleep 1;

    ## 1500000 == 1.5Mbps
    ## https://teradek.com/blogs/articles/what-is-the-optimal-bitrate-for-your-resolution
    ## a little low by this standard

    #
    # build streaming command
    #

    ## raspivid, 8000... probably too high
    my $cmd = "/usr/bin/raspivid -o - -t 0 -vf -hf -b 8000000 -fps 30 -rot $rot -w 1280 -h 720 -a 1036";
    #my $cmd = "/usr/bin/raspivid -o - -t 0 -vf -hf -b 8000000 -fps 30 -rot $rot -w 1280 -h 960 -a 1024 -a \"\%n\%n\%n\%n\%n\%n\%X\"";

    ## https://trac.ffmpeg.org/wiki/EncodingForStreamingSites
    ## -f <format>



    ## ffmpeg
    $cmd .= " | $ffmpeg -loglevel panic";

    ## fake audio input?
    $cmd .= " -re -ar 44100 -ac 2 -acodec pcm_s16le -f s16le -ac 2 -i /dev/zero";

    ## video input, from pipe
    $cmd .= " -f h264 -i -";

## old

    $cmd .= " -vcodec copy";

## begin new

    ## logo input, and params
    #$cmd .= " -i " . $conf->video_logo();

    ## video output params, -g twice framerate
    #$cmd .= " -c:v libx264 -preset ultrafast -tune zerolatency -g 60 -acodec aac -ab 128k";

    ## add the logo, with pos
    #$cmd .= " -filter_complex " . $conf->video_logo_pos();

## end new

    ## no flag, so this is the output
    $cmd .= " -f flv rtmp://a.rtmp.youtube.com/live2/$key";



    #
    #
    #

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
}

#
#
#

sub shoot
{
  #
  # day or night?
  #

  my $sun = DateTime::Event::Sunrise->new(longitude => -111.75547, latitude => +41.92683);
  my $dt = DateTime->now(time_zone => 'America/Denver');

  ## switch to night vision 1:20 after sunset until 1:20 before sunrise.
  my $daytime = 0;
  if(($dt->epoch < ($sun->sunset_datetime($dt)->epoch + 0)) and ($dt->epoch > ($sun->sunrise_datetime($dt)->epoch - 0))) {
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

  my $night_exposure_time;
  if(-e "/home/pi/conf/night_skiing") {
    ## delay longer exposure times for night skiing
    use Time::Local qw( timelocal );
    $night_exposure_time = timelocal(0, 0, 21, $day, $mon-1, $year);
  }
  else {
    ## otherwise one hour after sunset
    $night_exposure_time = $sun->sunset_datetime($dt)->epoch + 3600;
  }
  print "night_exposure_time=$night_exposure_time\n";

  ## stop long exposures one hour before sunrise
  if(($dt->epoch < ($sun->sunrise_datetime($dt)->epoch - 3600)) or ($dt->epoch > $night_exposure_time)) {
    $args .= " -ss 1000000";
  }

  ## if dt-epoch < sunrise
  ##   if dt-epoch < sunrise-1hr
  ##     hard night
  ##     set 6
  ##   else
  ##     sun is coming up
  ##     read
  ##     step down by 0.1

  ## elsif(dt-epoch is > sunset)
  ##   could check for night skiing here, if nightskiing, do nothing?
  ##     if less than 9pm do nothing?
  ##   if dt-epoch < sunset +1hr
  ##     sunset
  ##     read
  ##     step up by 0.1
  ##   else
  ##     hard night?
  ##     set 6

  mkdir("/home/pi/raw") unless(-e "/home/pi/raw");
  my $cmd = "/usr/bin/raspistill -v -n $args -o /home/pi/raw/$file";
  print "cmd=$cmd\n";
  my $out = `$cmd 2>&1`;

## need to preserve shutter speed
## a Vals object?
## record value here
## write value after everything is done?

  print "$out\n";
  print "\n";

  if($mogrify)
  {
    my $cmd = "/usr/bin/mogrify $mogrify /home/pi/raw/$file";
    print "cmd=$cmd\n";
    my $out = `$cmd`;
    print "mogrify=$out\n";
    print "\n";
  }

  #
  # call the stamp.pl
  #

  ## calculate w,h
  my($w, $h);
  if($mogrify =~ /.* (\d+)x(\d+)/) {
    $w = $1; $h = $2;
  }
  else {
    $args =~ /\-w (\d+) \-h (\d+)/;
    $w = $1; $h = $2;
  }

  ## stamp
  my $cmd = "/home/pi/bin/format_20181030.pl /home/pi/raw/$file $w $h $logo";
  print "cmd=$cmd\n";
  my $out = `$cmd`;
  print "out=$out\n";
  print "\n";

  return $file;
}

#
#
#

sub upload
{
  my($daytime, $file) = @_;

  #
  # upload filename to ixnay, and a dir computed from the hostname
  #

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

  my($w, $h);
  if($mogrify =~ /.* (\d+)x(\d+)/) {
    $w = $1; $h = $2;
  }
  else {
    $args =~ /\-w (\d+) \-h (\d+)/;
    $w = $1; $h = $2;
  }

  if($daytime) {
    $logo = "logo_day.png";
  }
  else {
    $logo = "logo_night.png";
  }
  my $cmd = "/usr/bin/ssh uaws www/vhosts/ixnay/bin/stamp_20180309.pl $cam/raw/$file $w $h $logo";
  print "cmd=$cmd\n";
  my $out = `$cmd`;
  print "out=$out\n";
  print "\n";
}

sub upload_stamped
{
  my($daytime, $file) = @_;

  #
  # call the stamp.pl
  #

#  my($w, $h);
#  if($mogrify =~ /crop (\d+)x(\d+)/) {
#    $w = $1; $h = $2;
#  }
#  else {
#    $args =~ /\-w (\d+) \-h (\d+)/;
#    $w = $1; $h = $2;
#  }

#  if($daytime) {
#    $logo = "logo_day.png";
#  }
#  else {
#    $logo = "logo_night.png";
#  }
#  my $cmd = "/home/pi/bin/stamp.pl /home/pi/raw/$file $w $h $logo";
#  print "cmd=$cmd\n";
#  my $out = `$cmd`;
#  print "out=$out\n";
#  print "\n";

  #
  # upload filename to ixnay, and a dir computed from the hostname
  #

  print "file=$file\n";
  my $cam = `/bin/hostname`;
  chomp($cam);
  #my $cmd = "/usr/bin/scp /home/pi/arc/$file uaws:www/vhosts/ixnay/htdocs/cams/$cam/arc";
  mkdir("/home/pi/upload") unless(-e "/home/pi/upload");
  my $cmd = "/bin/cp /home/pi/arc/$file /home/pi/upload/$cam\_$file ; /usr/bin/rsync --timeout=10 -avz --remove-source-files /home/pi/upload/* uaws:www/vhosts/ixnay/htdocs/cams/upload";
  print "cmd=$cmd\n";
  my $out = `$cmd`;
  print "out=$out\n";
  print "\n";

  #
  # copy to current
  #

  ## current2.pl on uaws2 now handles this...
}

