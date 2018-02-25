#!/usr/bin/perl

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

my $cam = `/bin/hostname`;
chomp($cam);

`/usr/bin/rsync -avz --delete uaws2:www/vhosts/ixnay/htdocs/cams/$cam/conf /home/pi`;

#
# stream or still?
#

my $min = (localtime(time))[1];

my $args = `/bin/cat /home/pi/conf/raspistill`;
chomp($args);

my $mogrify = `/bin/cat /home/pi/conf/mogrify`;
chomp($mogrify);

my $file;

if(-e "/home/pi/conf/streaming")
{
  if(&upload_scheduled()) {
    &stream_stop();
    ($daytime, $file) = &shoot();
  }

  unless(&stream_pid()) {
    &stream_start();
  }
}
else
{
  &stream_stop();
  ($daytime, $file) = &shoot();
}

#
# upload
#

if(&upload_scheduled()) {
  &upload($daytime, $file);
}

exit;

#
#
#

sub upload_scheduled
{
  my $upload = 0;

  if($ARGV[0] eq "upload") {
    $upload = 1;
  }
  elsif(-e "/home/pi/conf/streaming") {
    if($min =~ /0$/) {
      ## upload every-10-minutes during stream
      $upload = 1;
    }
  }
  elsif(($min =~ /[02468]$/) and (-e "/home/pi/conf/upload_02m")) {
    $upload = 1;
  }
  elsif(($min =~ /[05]$/) and (-e "/home/pi/conf/upload_05m")) {
    $upload = 1;
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

  if($pid) {
    print "ffmpeg is running ($pid)!";
    `/bin/kill $pid`;
    ## sleep here because if no process was found it is unnecessary
    sleep 1;
  }
}

sub stream_start
{
  ##raspivid -o - -t 0 -vf -hf -fps 30 -b 6000000 -rot 90 | ffmpeg -re -ar 44100 -ac 2 -acodec pcm_s16le -f s16le -ac 2 -i /dev/zero -f h264 -i - -vcodec copy -acodec aac -ab 128k -g 50 -strict experimental -f flv rtmp://a.rtmp.youtube.com/live2/amz7-tkk8-fdek-8hhw

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

  my $key = `/bin/cat /home/pi/conf/streaming`;
  chomp($key);

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

    my $cmd = "/usr/bin/raspivid -o - -t 0 -vf -hf -b 1500000 -fps 30 -rot $rot -w 1280 -h 720 -a 1036 | /usr/local/bin/ffmpeg -loglevel panic -re -ar 44100 -ac 2 -acodec pcm_s16le -f s16le -ac 2 -i /dev/zero -f h264 -i - -vcodec copy -acodec aac -ab 128k -g 50 -strict experimental -f flv rtmp://a.rtmp.youtube.com/live2/$key";

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

  my $cmd = "/usr/bin/raspistill -v -n $args -o /home/pi/tmp/$file";
  print "cmd=$cmd\n";
  my $out = `$cmd`;
  print "$out\n";
  print "\n";

  if($mogrify)
  {
    my $cmd = "/usr/bin/mogrify $mogrify /home/pi/tmp/$file";
    print "cmd=$cmd\n";
    my $out = `$cmd`;
    print "$out\n";
    print "\n";
  }

  return $daytime, $file;
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
  if($mogrify =~ /crop (\d+)x(\d+)/) {
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
  my $cmd = "/usr/bin/ssh uaws www/vhosts/ixnay/bin/stamp_config.pl $cam/raw/$file $w $h $logo";
  print "cmd=$cmd\n";
  my $out = `$cmd`;
  print "out=$out\n";
  print "\n";
}

