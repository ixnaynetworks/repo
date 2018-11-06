
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

1;

