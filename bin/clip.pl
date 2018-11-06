#!/usr/bin/perl

$| = 1;

my $base = "/home/pi";

use lib '/home/pi/lib';
use Conf;

my $conf = new Conf;

#
# build raspivid command
#

my $raspivid = "/usr/bin/raspivid -t 5000";

$raspivid .= " -w " . $conf->width() . " -h " . $conf->height();

$raspivid .= " -rot " . $conf->rot();

$raspivid .= " -o /home/pi/clip/" . $conf->date() . ".h264";

print "$raspivid\n";
my $out = `$raspivid`;
print "$out\n";

#
# build ffmpeg command
#

my $ffmpeg;
if(-e "/usr/bin/ffmpeg") {
  $ffmpeg = "/usr/bin/ffmpeg";
}
else {
  $ffmpeg = "/usr/local/bin/ffmpeg";
}

## not sure why i'm doing this
$ffmpeg .= " -framerate 24";

$ffmpeg .= " -i $base/clip/" . $conf->date() . ".h264";

#$ffmpeg .= " -c copy";

## logo and crop
$ffmpeg .= " -i " . $conf->logo_video();
$ffmpeg .= " -c:v libx264 -g 60";
$ffmpeg .= " -filter_complex '";
if($conf->mogrify() =~ /\-crop \d+x\d+\+(\d+)\+(\d+)/) {
  $ffmpeg .= "crop=1280:720:$1:$2, ";
}
$ffmpeg .= "overlay=main_w-overlay_w-10:10'";

$ffmpeg .= " $base/clip/" . $conf->date() . ".mp4";

print "$ffmpeg\n";
my $out = `$ffmpeg`;
print "$out\n";

my $scp = "/usr/bin/scp $base/clip/" . $conf->date() . ".mp4 uaws2:cams/" . `/bin/hostname`;
print "$scp\n";

exit;

