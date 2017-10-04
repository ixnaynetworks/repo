#!/usr/bin/perl

#my($base, $date) = @ARGV;
my($date) = @ARGV;

unless($date)
{
  use POSIX qw(strftime);
  $date = strftime("%Y%m%d", localtime(time));
}

#
# create avconv source files
#

## since i'm using imagemagick here, maybe i can add a timestamp?

my $base = "/home/pi";

opendir(DH, "$base/tmp");
my @file = readdir(DH);
closedir(DH);
#print "files=@file\n";

foreach my $file (sort @file) {
  if($file =~ /^$date/) {
    #print "file=$base/tl_thumb/$file\n";
    unless(-e "$base/tl_thumb/$file")
    {
      $com = "/usr/bin/convert $base/tmp/$file -resize x360 $base/tl_thumb/$file 2>&1";
      print "$com\n";
      #$out = `$com`;
      #print $out;

      ## error, back it out
      if($out =~ /Empty input file|Premature end of JPEG file/) {
        $com = "/bin/rm $base/tl_thumb/$file";
        print "$com\n";
        #$out = `$com`;
        #print $out;
      }
    }
  }
}

#
# create the links in AVC
#

$com = "/bin/rm -f $base/tl_avc/*";
print "$com\n";
#$out = `$com`;
#print $out;

opendir(DH, "$base/tl_thumb");
my @file = readdir(DH);
closedir(DH);

my $i;
foreach my $file (sort @file) {
  if($file =~ /^$date/) {
    $com = sprintf("/bin/ln -s $base/tl_thumb/$file $base/tl_avc/file-%03d.jpg", $i);
    print "$com\n";
    #$out = `$com`;
    #print $out;

    $i++;
  }
  elsif($file =~ /^\d{10}/) {
    ## remove old files
    $com = "/bin/rm $base/tl_thumb/$file";
    #print "$com\n";
    $out = `$com`;
    #print $out;
  }
}

