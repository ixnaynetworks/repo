#!/usr/bin/perl

$ARGV[0] =~ /(.*)\/(.*)\/(.*)/;
## do i care?
my $cam = $1;
my $img = $3;
my $base = "/home/pi";
my $file = $base . "/$2/$img";

my $w = $ARGV[1];
my $h = $ARGV[2];

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

## convert raw/20180413204005.jpg[200x200+1080+0] -colorspace Gray -format "%[fx:image.mean]" info:
my $brightness_cmd = "/usr/bin/convert $file\[200x200+$offset+0\] -colorspace Gray -format \"%[fx:image.mean]\" info:";
print "\n\n$brightness_cmd";
my $brightness = `$brightness_cmd`;
chomp($brightness);
print "\n$brightness";

my $logo;
mkdir "$base/vals" unless(-e "$base/vals");
if($brightness > 0.3) {
  $logo = "$base/conf/logo_day.png";
  `/bin/rm $base/vals/bg_dark ; /usr/bin/touch $base/vals/bg_bright`;
}
else {
  $logo = "$base/conf/logo_night.png";
  `/bin/rm $base/vals/bg_bright ; /usr/bin/touch $base/vals/bg_dark`;
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

## the temp will get inserted on the server side...

#open(TEMP, "/home/michael/www/vhosts/ixnay/htdocs/cams/cherrypeak/temp.txt");
#$temp = <TEMP>;
#close(TEMP);
#chomp($temp);

#if($temp) {
#  $label .= " // $temp" . "°f";
#}

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

#my $cmd = "/usr/bin/convert $file -fill '#0008' -draw 'rectangle 0,675,960,720' -fill '#CCCCCC' -pointsize 20 -font Courier-Bold -annotate +15+705 '$label' $base/img/logo.png -gravity northwest -geometry +20+0 -composite $base/img/rpi.png -gravity southeast -geometry +15+10 -composite $base/img/left_bottom_label.jpg";
#my $cmd = "/usr/bin/convert $file -fill '#0008' -draw 'rectangle $rectangle' -fill '#CCCCCC' -pointsize 20 -font Courier-Bold -annotate +15+$baseline '$label' $base/img/logo.png -gravity northwest -geometry +20+0 -composite $base/img/rpi.png -gravity southeast -geometry +15+10 -composite $base/img/left_bottom_label.jpg";
#my $cmd = "/usr/bin/convert $file -fill '#0008' -draw 'rectangle $rectangle' -fill '#CCCCCC' -pointsize 20 -font Courier-Bold -annotate +15+$baseline '$label' $logo -gravity $logo_pos -composite $base/conf/rpi.png -gravity southeast -geometry +15+10 -composite $base/img/left_bottom_label.jpg";

my $cmd = "/usr/bin/convert $file -fill '#000A' -draw 'rectangle $rectangle' -fill '#CCCCCC' -pointsize 20 -font Courier-Bold -annotate +15+$baseline '$label'";
if($logo) {
  $cmd .= " $logo -gravity $logo_pos -composite";
}
mkdir("$base/tmp") unless(-e "$base/tmp");
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

