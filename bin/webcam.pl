#!/usr/bin/perl

$| = 1;

#do '/home/pi/cnf/webcam.pl';

my($cam, $label) = @ARGV;

unless($cam) {
  die "bad cam: $cam";
}

$remote_srvr = "uaws";

#
# take photo
#

## compute filename
($sec, $min, $hr, $day, $mon, $year) = localtime(time);
$year += 1900;
$mon++;
$file = sprintf("%4d%02d%02d%02d%02d%02d.jpg", $year, $mon, $day, $hr, $min, $sec);
$timestamp = sprintf("%4d/%02d/%02d %02d:%02d", $year, $mon, $day, $hr, $min);
print "\nfile=$file\n";
print "\n";

## take picture, to a tmp location
$com = "/usr/bin/raspistill -v -n -q 95 -ex snow -o /home/pi/tmp/$file";
print "com=$com\n";
$out = `$com`;
print "$out\n";
print "\n";

## add caption and image
#$com = "/usr/bin/convert /home/pi/tmp/$file -resize 960x720 -fill '#0008' -draw 'rectangle 0,690,960,720' -fill '#CCCCCC' -pointsize 15 -font Courier-Bold -annotate +10+710 '$label' logo.png -gravity northwest -geometry +20+0 -composite rpi.png -gravity southeast -geometry +20+50 -composite left_bottom_label.jpg";

## 960x720
## 720-675 = 45

## 1440x1080

## can i do 1280x720?
## just crop the top?

## original image 2592x1944

$x = 1280;
$y =  720;

$resize = "-resize " . $x . "x" . (2592 * ($x / 1944));
$crop = "-crop " . $x . "x" . $y . "+0+" . ($resize_y - 720);

$cmd = "/usr/bin/convert /home/pi/tmp/$file $resize $crop";

$com = "/usr/bin/convert /home/pi/tmp/$file -resize 960x720 -fill '#0008' -draw 'rectangle 0,675,960,720' -fill '#CCCCCC' -pointsize 20 -font Courier-Bold -annotate +15+705 '$label' /home/pi/img/logo.png -gravity northwest -geometry +20+0 -composite /home/pi/img/rpi.png -gravity southeast -geometry +15+10 -composite /home/pi/img/left_bottom_label.jpg";
print "com=$com\n";
$out = `$com`;
print "out=$out\n";
print "\n";

#$com = "/usr/bin/convert -background '#00000000' -fill '#CCCCCC' -pointsize 15 -font Courier-Bold label:'$timestamp' miff:- | composite -gravity southeast -geometry +10+5 - left_bottom_label.jpg /var/www/arc/$file";
$com = "/usr/bin/convert -background '#00000000' -fill '#CCCCCC' -pointsize 20 -font Courier-Bold label:'$timestamp' miff:- | composite -gravity southeast -geometry +45+9 - /home/pi/img/left_bottom_label.jpg /var/www/arc/$file";
print "com=$com\n";
$out = `$com`;
print "out=$out\n";
print "\n";

## upload picture
if($remote_srvr) {
  $com = "/usr/bin/scp -v /var/www/arc/$file $remote_srvr:www/vhosts/ixnay/htdocs/cams/$cam/arc";
  print "com=$com\n";
  $out = `$com`;
  print "out=$out\n";
  print "\n";
}

if($remote_srvr) {
  $com = "/usr/bin/ssh -v $remote_srvr /bin/cp www/vhosts/ixnay/htdocs/cams/$cam/arc/$file www/vhosts/ixnay/htdocs/cams/$cam/current.jpg";
  print "com=$com\n";
  $out = `$com`;
  print "out=$out\n";
  print "\n";
}

