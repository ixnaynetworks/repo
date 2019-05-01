
package Conf;

#
#
#

sub new
{
  my($class) = @_;
  my($self) = {};

  bless $self, $class;
  return $self;
}

#
#
#

sub name
{
  my($self) = @_;

  unless($self->{'name'})
  {
    $self->{'name'} = `/bin/hostname`;
    chomp($self->{'name'});
  }

  return $self->{'name'};
}

#
# load from server
#

sub refresh
{
  my($self) = @_;

  #
  # test if refresh is necessary
  #

  ## client
  my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size, $atime,$mtime,$ctime,$blksize,$blocks) = stat("/home/pi/conf");
  my($sec, $min, $hour, $mday, $mon, $year) = localtime($mtime);
  my $client = sprintf("%s-%02d-%02d %02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min);
  print "client=$client\n";

  ## server
  my $cmd = "/usr/bin/curl -s https://www.ixnay.net/cams/" . $self->name() . "/";
  my $html = `$cmd`;
  my $server;
  if($html =~ /<td><a href="conf\/">conf\/<\/a><\/td><td align="right">(\d+\-\d+\-\d+ \d+:\d+)\s+<\/td>/s) {
    $server = $1;
  }
  print "server=$server\n";

  #
  # rsync?
  #

  if($server and $client) {
    if($server ne $client) {
      my $cmd = "/usr/bin/rsync --timeout=10 -avz --delete uaws2:www/vhosts/ixnay/htdocs/cams/" . $self->{'name'} . "/conf /home/pi";
      print "$cmd\n";
      my $out = `$cmd`;
      print "$out\n\n";
    }
  }
}

#
# returns a standard date string
#

sub date
{
  my($self) = @_;

  unless($self->{'date'})
  {
    my($sec, $min, $hr, $day, $mon, $year) = localtime(time);
    $year += 1900;
    $mon++;
    $self->{'date'} = sprintf("%4d%02d%02d%02d%02d%02d", $year, $mon, $day, $hr, $min, $sec);
  }

  return $self->{'date'};
}

#
#
#

sub raspistill
{
  my($self) = @_;

  unless($self->{'raspistill'}) {
    open(FILE, "/home/pi/conf/raspistill");
    $self->{'raspistill'} = <FILE>;
    close(FILE);
  }

  return $self->{'raspistill'};
}

sub mogrify
{
  my($self) = @_;

  unless($self->{'mogrify'}) {
    open(FILE, "/home/pi/conf/mogrify");
    $self->{'mogrify'} = <FILE>;
    close(FILE);
  }

  return $self->{'mogrify'};
}

sub width
{
  my($self) = @_;

  unless($self->{'width'}) {
    if($self->raspistill() =~ /\-w (\d+)/) {
      $self->{'width'} = $1;
    }
    else {
      $self->{'width'} = 1280;
    }
  }

  return $self->{'width'};
}

sub height
{
  my($self) = @_;

  unless($self->{'height'}) {
    if($self->raspistill() =~ /\-h (\d+)/) {
      $self->{'height'} = $1;
    }
    else {
      $self->{'height'} = 720;
    }
  }

  return $self->{'height'};
}

sub rot
{
  my($self) = @_;

  unless($self->{'rot'}) {
    if($self->raspistill() =~ /\-\-?rot(?:ation)? (\d+)/) {
      $self->{'rot'} = $1;
    }
    else {
      $self->{'rot'} = 0;
    }
  }

  return $self->{'rot'};
}

#
#
#

sub streaming
{
  my($self) = @_;

  my $cmd = "/usr/bin/curl -s 'https://www.ixnay.net/cams/" . $self->name() . "/conf/streaming'";
  print "$cmd\n";
  my $out = `$cmd`;
  print "$out\n";

  my $key;
  unless($out =~ /404 Not Found/s) {
    $key = $out;
    chomp($key);
  }

  return $key;
}

## remove this after pmv is updated
sub logo_video
{
  my($self) = @_;

  unless($self->{'logo_video'}) {
    if(-e "/home/pi/vals/bg_bright") {
      $self->{'logo_video'} = "/home/pi/conf/logo_day.png";
    }
    else {
      $self->{'logo_video'} = "/home/pi/conf/logo_night.png";
    }
  }

  return $self->{'logo_video'};
}

sub video_logo
{
  my($self) = @_;

  unless($self->{'video_logo'}) {
    if(-e "/home/pi/vals/bg_bright") {
      $self->{'video_logo'} = "/home/pi/conf/logo_day.png";
    }
    else {
      $self->{'video_logo'} = "/home/pi/conf/logo_night.png";
    }
  }

  return $self->{'video_logo'};
}

sub video_logo_pos
{

  my($self) = @_;

  unless($self->{'video_logo_pos'}) {
    if(-e "/home/pi/conf/logo_northeast") {
      ## main_w is the video dimension.  overlay_w is the image dimension
      $self->{'video_logo_pos'} = "'overlay=main_w-overlay_w-10:10'";
    }
    else {
      $self->{'video_logo_pos'} = "'overlay=10:10'";
    }
  }

  return $self->{'video_logo_pos'};
}

#
#
#

sub format
{
  my($self, $arg, $w, $h) = @_;

  $arg =~ /(.*)\/(.*)\/(.*)/;
print "arg=$arg\n";
  ## do i care?
  my $cam = $1;
  my $img = $3;
  my $base = "/home/pi";
  my $file = $base . "/$2/$img";

  unless($cam and $img and -e $file) {
    die "no such file: $file";
  }

  #
  # logo stuff
  #

  my $logo_pos = "northwest";
  if(-e "$base/conf/logo_northeast") {
    $logo_pos = "northeast";
  }
  elsif(-e "$base/etc/logo_northeast") {
    $logo_pos = "northeast";
  }

  my $offset = 0;
  if($logo_pos eq "northeast") {
    $offset = $w - 200;
  }

  #
  # pick day/night logo
  #

  ## convert raw/20180413204005.jpg[200x200+1080+0] -colorspace Gray -format "%[fx:image.mean]" info:
  my $brightness_cmd = "/usr/bin/convert $file\[200x200+$offset+0\] -colorspace Gray -format \"%[fx:image.mean]\" info:";
  print "\n\n$brightness_cmd";
  my $brightness = `$brightness_cmd`;
  chomp($brightness);
  print "\n$brightness";

  my $thresh;
  if(-e "$base/vals/bg_dark") {
    $thresh = 0.3;
  }
  else {
    $thresh = 0.2;
  }

  my $logo;
  mkdir "$base/vals" unless(-e "$base/vals");
  if($brightness > $thresh) {
    $logo = "$base/conf/logo_day.png";
    unlink("$base/vals/bg_dark");
    `/usr/bin/touch $base/vals/bg_bright`;
  }
  else {
    $logo = "$base/conf/logo_night.png";
    unlink("$base/vals/bg_bright");
    `/usr/bin/touch $base/vals/bg_dark`;
  }
  print "\n\nlogo=$logo";

  #
  # caption stuff
  #

  my $label = $cam;
  if(-e "$base/conf/caption") {
    my $caption = `/bin/cat $base/conf/caption`;
    chomp $caption;
    $label = $caption;
  }
  print "\n";

  my $temp;
  if(-e "/home/pi/temp.txt")
  {
    open(TEMP, "/home/pi/temp.txt");
    $temp = <TEMP>;
    close(TEMP);
    chomp($temp);
  }

  my $bulb;
  if(-e "/home/pi/bulb.txt")
  {
    open(BULB, "/home/pi/bulb.txt");
    $bulb = <BULB>;
    close(BULB);
    chomp($bulb);
  }

  if($temp and $bulb) {
    $label .= " // Air: $temp" . "°f // Wet Bulb: $bulb" . "°f";
  }
  #if($bulb) {
  #  $label .= " // Wet Bulb: $bulb" . "°f";
  #}
  elsif($temp) {
    $label .= " // $temp" . "°f";
  }

  #
  # compute dimensions of bottom bar
  #

  ## 720 - 45 = 675
  ## 720 - 15 = 705
  my $rectangle = "0," . ($h - 45) . ",$w,$h";
  my $baseline = $h - 15;

  #
  # first convert
  #

  mkdir("$base/tmp") unless(-e "$base/tmp");

  my $cmd = "/usr/bin/convert $file -fill '#000A' -draw 'rectangle $rectangle' -fill '#CCCCCC' -pointsize 20 -font Courier-Bold -annotate +15+$baseline '$label'";
  if($logo) {
    $cmd .= " $logo -gravity $logo_pos -composite";
  }
  $cmd .= " $base/conf/rpi.png -gravity southeast -geometry +135+10 -composite $base/tmp/left_bottom_label.jpg";
  print "cmd=$cmd\n";
  $out = `$cmd`;
  print "out=$out\n";
  print "\n";

  #
  # compute timestamp
  # 

  $img =~ /(\d{4})(\d\d)(\d\d)(\d\d)(\d\d)/;
  my $timestamp = "$1/$2/$3 $4:$5";

  #
  # final processing
  #

  mkdir("$base/arc") unless(-e "$base/arc");
  my $cmd = "/usr/bin/convert -background '#00000000' -fill '#CCCCCC' -pointsize 20 -font Courier-Bold label:'$timestamp    ixnay.net' miff:- | composite -gravity southeast -geometry +15+9 - $base/tmp/left_bottom_label.jpg $base/arc/$img";
  print "cmd=$cmd\n";
  $out = `$cmd`;
  print "out=$out\n";
  print "\n";
}

#
#
#

sub pi_model
{
  my($self) = @_;

  unless($self->{'pi_model'})
  {
    my $cpuinfo = &cmd_run("/bin/cat /proc/cpuinfo");

    ## https://elinux.org/RPi_HardwareHistory
    if($cpuinfo =~ /Revision\s+: (\w+)/s) {
print "here\n";
      if($1 eq "0010") {
        $self->{'pi_model'} = "$1: B+ // 700 MHz // 512mb";
      }
      elsif($1 =~ /a[02]2082/) {
        $self->{'pi_model'} = "$1: 3 Model B // 1200 MHz // 1gb";
      }
      elsif($1 eq "a020d3") {
        $self->{'pi_model'} = "$1: 3 Model B+ // 1400 MHz // 1gb";
      }
      elsif($1 eq "0012") {
        $self->{'pi_model'} = "$1: A+ // 700 MHz // 256mb";
      }
    }
  }

  return $self->{'pi_model'};
}

sub cmd_run
{
  my($cmd) = @_;

  #print "$cmd\n";
  my $out = `$cmd 2>&1`;
  chomp($out);
  #print "out=$out\n";

  return $out;
}

1;

