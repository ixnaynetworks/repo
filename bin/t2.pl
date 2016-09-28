#!/usr/bin/perl

my $time = time;
my $base = "/home/pi";
my $remote_srvr = "uaws";

## if files in avc
##   clear out avc_tmp
##   move avc files to avc_tmp
## else
##   quit

#
# check avc dir
#

my $cmd = "/bin/ls -1 $base/avc/file-*.jpg";
print "cmd=$cmd\n";
$out = `$cmd`;
print $out;
unless($out) {
  die "no files: $!";
}

#
# move avc files to avc_tmp
#

my $cmd = "/bin/rm $base/avc_tmp/file-*.jpg ; /bin/mv $base/avc/file-*.jpg $base/avc_tmp";
print "\n## clear out the avc dir\n";
print "cmd=$cmd\n";
$out = `$cmd`;
print $out;
print "\n";

#
# compute filename
#

my($sec, $min, $hr, $day, $mon, $year) = localtime($time);
$year += 1900;
$mon++;
my $file = sprintf("%4d%02d%02d%02d%02d%02d.mpeg", $year, $mon, $day, $hr, $min, $sec);
print "\n## compute filename\n";
print "file=$file";
print "\n";

#
# create the video
#

$cmd = "/usr/bin/nice /usr/bin/avconv -framerate 4 -i $base/avc_tmp/file-%03d.jpg -r 15 -vcodec libx264 -y $base/mpeg/$file 2>\&1";
print "\n## create the video\n";
print "cmd=$cmd\n";
$out = `$cmd`;
print $out;
print "\n";

#
# upload
#

my $cam = `/bin/hostname`;
chomp($cam);

my $cmd = "/usr/bin/scp $base/mpeg/$file $remote_srvr:www/vhosts/ixnay/htdocs/cams/$cam/mpeg";
print "\n## upload\n";
print "cmd=$cmd\n";
$out = `$cmd`;
print $out;
print "\n";

#
# merge command
#

my $cmd = "/usr/bin/ssh $remote_srvr www/vhosts/ixnay/bin/t2.pl $cam";
print "\n## merge timelapse files\n";
print "cmd=$cmd\n";
$out = `$cmd`;
print $out;
print "\n";

#
# bye
#

print "\## time elapsed\n";
print time - $time, "s\n\n";

