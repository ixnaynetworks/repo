#!/usr/bin/perl


my $out;

#
#
#

my $hostname = &run("/bin/hostname");
chomp($hostname);

$out .= "\n#\n" . "# hostname" . "\n#";
$out .= "\n\n" . $hostname . "\n";

#
#
#

my $cpuinfo = &run("/bin/cat /proc/cpuinfo");

my $model;
if($cpuinfo =~ /Revision\s+: (\w+)/s) {
  if($1 eq "0010") {
    $model = "B+ // 700 MHz // 512mb";
  }
  elsif($1 eq "a02082") {
    $model = "3 Model B // 1200 MHz // 1gb";
  }
  elsif($1 eq "a020d3") {
    $model = "3 Model B+ // 1400 MHz // 1gb";
  }
  elsif($1 eq "0012") {
    $model = "A+ // 700 MHz // 256mb";
  }
}
$out .= "\n#" . "\n# model -- https://elinux.org/RPi_HardwareHistory" . "\n#";
$out .= "\n\n$1: $model\n";

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

my $netstat = &run("/bin/netstat -rn");
foreach my $line (split(/\n/, $netstat)) {
  if($line =~ /^\d.*?(\w+)$/) {
    unless(grep(/^$1$/, @interface)) {
      push(@interface, $1);
    }
  }
}

$out .= "\n#\n" . "# ifconfig" . "\n#";
$out .= "\n";

foreach my $interface (sort @interface) {
  my $ifconfig = &run("/sbin/ifconfig $interface");
  $out .= "\n" . $ifconfig;
}

if($netstat =~ /wlan\d/)
{
  $out .= "\n#\n" . "# iwconfig" . "\n#";
  $out .= "\n";

  foreach my $interface (sort @interface) {
    if($interface =~ /^w/)
    {
      my $iwconfig = &run("/sbin/iwconfig $interface");
      $out .= "\n" . $iwconfig;

      $out =~ /Link Quality=(\d\d?)/;
      push(@graph, $hostname . "_link_quality=$1");
    }
  }
}

$out .= "\n#\n" . "# netstat" . "\n#";
$out .= "\n\n" . $netstat . "\n";

#
#
#

if(-e "/usr/sbin/mopicli") {
  my $mopicli = &run("/usr/sbin/mopicli -e");
  $out .= "\n#\n" . "# mopicli" . "\n#";
  $out .= "\n\n" . $mopicli . "\n";
}

#
#
#

print "$out\n";

#
# copy files
#

my $time = time();

my $file = "$time.txt";
open(FILE, ">/home/pi/status/$file");
print FILE $out;
close(FILE);

my $cmd = "/usr/bin/rsync --timeout=10 -avz /home/pi/status uaws2:cams/$hostname ; /usr/bin/ssh uaws2 /bin/cp cams/$hostname/status/$file cams/$hostname/status.txt";
print "$cmd\n";
my $out = `$cmd`;
print "$out\n";

#
# graph?
#

my $cmd = "/usr/bin/ssh uaws2 www/vhosts/ixnay/bin/graph4.pl $time " . join(" ", join("=", @graph));
print "$cmd\n";
my $out = `$cmd`;
print "$out\n";

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

