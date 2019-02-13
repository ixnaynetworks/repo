
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

1;

