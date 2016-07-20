#!/usr/bin/perl

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
# take the pic and save it to an archive somewhere
#

#my $cmd = "/usr/bin/raspistill -v -w 960 -h 720 -n -q 95 --saturation 25 --sharpness 15 -o /home/pi/tmp/$file";
my $cmd = "/usr/bin/raspistill -v " . $ARGV[0] . " -o /home/pi/tmp/$file";
print "cmd=$cmd\n";
my $out = `$cmd`;
print "$out\n";
print "\n";

#
# upload filename to ixnay, and a dir computed from the hostname
#

my $cam = `/bin/hostname`;
chomp($cam);
my $cmd = "/usr/bin/scp -v /home/pi/tmp/$file uaws:www/vhosts/ixnay/htdocs/cams/$cam/raw";
print "cmd=$cmd\n";
my $out = `$cmd`;
print "out=$out\n";
print "\n";

#
# call the stamp.pl on ixnay to do the rest
#

my $cmd = "/usr/bin/ssh -v uaws www/vhosts/ixnay/bin/stamp.pl $cam/raw/$file";
print "cmd=$cmd\n";
my $out = `$cmd`;
print "out=$out\n";
print "\n";

