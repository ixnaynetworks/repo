#!/usr/bin/perl

print "sleeping 50s...\n";
sleep 50;

my $date = `/bin/date +"%Y%m%d"`;
chomp($date);

my $cmd = "/bin/cp /home/pi/log/shoot /home/pi/log/shoot_$date";
print "$cmd\n";
my $out = `$cmd`;
print "$out\n";

my $cmd = "/bin/cp /dev/null /home/pi/log/shoot";
print "$cmd\n";
my $out = `$cmd`;
print "$out\n";

my $cmd = "/usr/bin/find /home/pi/log -name \"shoot*\" -mtime +90 -delete";
print "$cmd\n";
my $out = `$cmd`;
print "$out\n";

