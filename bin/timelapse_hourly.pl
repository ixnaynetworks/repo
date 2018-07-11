#!/usr/bin/perl

my($date) = @ARGV;

my $base = "/home/pi";

## switch this back to date
## have this script maintain the whole day's worth of thumbs and links

unless($date)
{
  use POSIX qw(strftime);
  $date = strftime("%Y%m%d", localtime(time));
}
print "date=$date\n";

#
# create avconv source files
#

opendir(DH, "$base/arc");
my @file = readdir(DH);
closedir(DH);
#print "files=@file\n";

my @hour;
my $thumb;
foreach my $file (sort @file) {
  if($file =~ /^$date/) {
    #print "file=$base/tl_thumb/$file\n";
    unless(-e "$base/tl_thumb/$file")
    {
      $cmd = "/usr/bin/convert $base/arc/$file -resize x360 $base/tl_thumb/$file 2>&1";
      print "$cmd\n";
      $out = `$cmd`;
      print $out;

      if($out !~ /Empty input file|Premature end of JPEG file/) {
        $thumb = $file;
        my $hour = substr($file, 0, 10);
        push(@hour, $hour) unless(grep(/^$hour$/, @hour));
      }
      else {
        ## error, back it out
        $cmd = "/bin/rm $base/tl_thumb/$file";
        print "$cmd\n";
        $out = `$cmd`;
        print $out;
      }
    }
  }
}


foreach my $num (0..24)
{
  my $hour = sprintf("$date" . "%02d", $num);
  print "hour=$hour\n";

  if(-e "$base/tl_mp4_hourly/$hour.mp4") {
    next unless(grep(/^$hour$/, @hour));
  }

  #
  # create the links in AVC
  #

  $cmd = "/bin/rm -f $base/tl_avc/*";
  print "$cmd\n";
  $out = `$cmd`;
  print $out;

  opendir(DH, "$base/tl_thumb");
  my @file = readdir(DH);
  closedir(DH);

  my $i;
  foreach my $file (sort @file) {
    if($file =~ /^$hour/) {
      $com = sprintf("/bin/ln -s $base/tl_thumb/$file $base/tl_avc/file-%03d.jpg", $i);
      print "$com\n";
      $out = `$com`;
      print $out;

      $i++;
    }
  }

  ## no links
  print "i=$i\n";
  next unless($i);

  #
  # create the video
  #

  #print "\ncreating the mp4 slideshow video...\n\n";

  my $r = 30;
  #print "r=$r\n";

  $com = "/usr/bin/avconv -y -r $r -i $base/tl_avc/file-%03d.jpg -vcodec libx264 -y $base/tl_mp4_hourly/$hour.mp4 2>\&1";
  print "$com\n";
  $out = `$com`;
  print "$out\n";
}

#
# upload today's filenames to ixnay, and a dir computed from the hostname
#

print "file=$file\n";
my $cam = `/bin/hostname`;
chomp($cam);
my $cmd = "/usr/bin/rsync -avz $base/tl_mp4_hourly/$date* uaws:www/vhosts/ixnay/htdocs/cams/$cam/tl_mp4_hourly";
print "cmd=$cmd\n";
my $out = `$cmd`;
print "out=$out\n";
print "\n";

#
# copy thumb
#

my $cmd = "/usr/bin/scp $base/tl_thumb/$thumb uaws:www/vhosts/ixnay/htdocs/cams/$cam/poster.jpg";
print "cmd=$cmd\n";
my $out = `$cmd`;
print "out=$out\n";
print "\n";

#
# merge and copy to current
#

my $cmd = "/usr/bin/ssh uaws2 www/vhosts/ixnay/bin/timelapse_daily.pl " . `/bin/hostname`;
print "cmd=$cmd\n";
my $out = `$cmd`;
print "out=$out\n";
print "\n";

exit;

