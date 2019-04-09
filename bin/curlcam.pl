#!/usr/bin/perl

# /usr/bin/curl -s 'http://192.168.2.30/cgi-bin/nph-zms?mode=single&monitor=27&user=admin&pass=cpr.pass01' -o /home/pi/test.jpg

my($num, $file) = @ARGV;

my $cmd = "/usr/bin/curl -s 'http://192.168.2.30/cgi-bin/nph-zms?mode=single&monitor=$num&user=admin&pass=cpr.pass01' -o /home/pi/curl/$file";
print "$cmd\n";
my $out = `$cmd`;
print "$out\n";

if(-s "/home/pi/curl/$file")
{
  my $cmd = "/usr/bin/scp /home/pi/curl/$file uaws2:cams/cp/$file";
  print "$cmd\n";
  my $out = `$cmd`;
  print "$out\n";
}

