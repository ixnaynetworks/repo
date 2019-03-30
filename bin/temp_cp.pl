#!/usr/bin/perl

my $sec = rand(50);
#sleep $sec;

my $cmd = "/usr/bin/curl -s 'http://www.skicherrypeak.com/rpt/?snow-report'";
#print "$cmd\n";
my $out = `$cmd`;
#print "$out\n";

use Time::Local;

my($station) = @ARGV;
my $temp;

if($out =~ /(20\d\d)\-(\d\d)\-(\d\d) (\d\d):(\d\d).*?$station.*?Air Temperature: <\/span><span class="Normal_text xr_s8" style="">(\d\d)\./si) {
  my $stime = timelocal(0, $5, $4, $3, $2 - 1, $1 - 1900);
  if((time() - $stime) < 3600) {
    $temp = $6;
  }
}

my $bulb;

if($temp) {
  if($out =~ /$station.*?We[bt] Bulb: <\/span><span class="Normal_text xr_s8" style="">(\d\d)\./si) {
    $bulb = $1;
  }
}

if($temp) {
  open(FILE, ">/home/pi/temp.txt");
  print FILE $temp;
  close(FILE);
}
else {
  unlink("/home/pi/temp.txt");
}

if($bulb) {
  open(FILE, ">/home/pi/bulb.txt");
  print FILE $bulb;
  close(FILE);
}
else {
  unlink("/home/pi/bulb.txt");
}
