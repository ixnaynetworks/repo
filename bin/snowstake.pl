#!/usr/bin/perl

## compute file name

my($sec, $min, $hr, $day, $mon, $year) = localtime(time);
$year += 1900;
$mon++;
my $file = sprintf("%4d%02d%02d%02d%02d%02d.jpg", $year, $mon, $day, $hr, $min, $sec);
print "\nfile=$file\n";
print "\n";

## fetch image

my $cmd = "/usr/bin/curl -s --connect-timeout 10 'http://10.222.6.184/cgi-bin/video_snapshot.cgi?user=admin&pwd=admin' > /home/pi/snowstake/$file";
print "$cmd\n";
my $out = `$cmd`;
print "$out\n";

## formatting?
## copy up to queue

my $cmd = "/usr/bin/scp /home/pi/snowstake/$file uaws2:cams/upload/cp_snowstake_$file";
print "$cmd\n";
my $out = `$cmd`;
print "$out\n";

