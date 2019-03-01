#!/usr/bin/perl

my $sec = rand(50);
sleep $sec;

my $cmd = "/usr/bin/curl -s 'http://www.skicherrypeak.com/rpt/?snow-report'";
#print "$cmd\n";
my $out = `$cmd`;
#print "$out\n";

my($station) = @ARGV;
if($out =~ /$station.*?Air Temperature: <\/span><span class="Normal_text xr_s8" style="">(\d\d)\./si) {
  open(FILE, ">/home/pi/temp.txt");
  print FILE $1;
  close(FILE);
}

