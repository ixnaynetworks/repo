#!/usr/bin/perl

my $out;

#
#
#

my $hostname = &run("/bin/hostname");

$out .= "\n#\n" . "# hostname" . "\n#";
$out .= "\n\n" . $hostname . "\n";

#
#
#

my $cpuinfo = &run("/bin/cat /proc/cpuinfo");

my $model;
if($cpuinfo =~ /Revision\s+: (\w+)/s) {
  my $revision = $1;
  if($revision eq "0010") {
    $model = "$revision: B+ // 700 MHz // 512mb";
  }
  elsif($revision =~ /a[02]2082/) {
    $model = "$revision: 3 Model B // 1200 MHz // 1gb";
  }
}
$out .= "\n#\n" . "# model" . "\n#";
$out .= "\n\n" . $model . "\n";

#
#
#

my $date = &run("/bin/date");

$out .= "\n#\n" . "# date" . "\n#";
$out .= "\n\n" . $date . "\n";

#
#
#

my $uptime = &run("/usr/bin/uptime");

$out .= "\n#\n" . "# uptime" . "\n#";
$out .= "\n\n" . $uptime . "\n";

#
#
#

my $df = &run("/bin/df -h /");

$out .= "\n#\n" . "# df" . "\n#";
$out .= "\n\n" . $df . "\n";

#
#
#

my $ifconfig = &run("/sbin/ifconfig wlan");

$out .= "\n#\n" . "# ifconfig" . "\n#";
$out .= "\n\n" . $ifconfig . "\n";

#
#
#

my $netstat = &run("/bin/netstat -rn");

$out .= "\n#\n" . "# netstat" . "\n#";
$out .= "\n\n" . $netstat . "\n";

#
#
#

print $out;

exit;

#
#
#

sub run
{
  my($cmd) = @_;

  #print "cmd=$cmd\n";
  my $out = `$cmd 2>&1`;
  chomp($out);
  #print "out=$out\n";

  return $out;
}

