#!/usr/bin/perl

unless($ARGV[0] eq "now")
{
  my $sleep = int(rand(40)) + 10;
  print "\nsleeping $sleep\s...";
  sleep($sleep);
}

$| = 1;

use lib '/home/pi/lib';
use Conf;

my $conf = new Conf;

#
#
#

my $out;

#
#
#

my $date = &run("/bin/date");

$out .= "\n#\n" . "# date" . "\n#";
$out .= "\n\n" . $date . "\n";

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

my $model = $conf->pi_model();
$out .= "\n#" . "\n# model -- https://elinux.org/RPi_HardwareHistory" . "\n#";
$out .= "\n\n$model\n";

#
#
#

my $os = &run("/bin/cat /etc/os-release");

$out .= "\n#\n" . "# os-release" . "\n#";
$out .= "\n\n" . $os . "\n";

#
#
#

my $uptime = &run("/usr/bin/uptime");

$out .= "\n#\n" . "# uptime" . "\n#";
$out .= "\n\n" . $uptime . "\n";

#
# temp
#

my $vcgencmd = &run("/opt/vc/bin/vcgencmd measure_temp");

my $temp;
if($vcgencmd =~ /^temp=(.*)'C/) {
  $temp = sprintf "%.1f", (($1 * 9) / 5) + 32;

  $out .= "\n#\n" . "# temp" . "\n#";
  $out .= "\n\n" . $temp . "\n";

  push(@graph, $hostname . "_temp=$temp");
}

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

      if($out =~ /Signal level=(\d\d?\d?)\/100/) {
        push(@graph, $hostname . "_signal_level_pct=$1");
      }
      elsif($out =~ /Signal level=\-(\d\d?\d?) dBm/) {
        push(@graph, $hostname . "_signal_level_dbm=$1");
      }
    }
  }
}

$out .= "\n#\n" . "# netstat" . "\n#";
$out .= "\n\n" . $netstat . "\n";

#
#
#

if(-e "/usr/sbin/mopicli")
{
  my $mopicli = &run("/usr/sbin/mopicli -e");

  $out .= "\n#\n" . "# mopicli" . "\n#";
  $out .= "\n\n" . $mopicli . "\n";

  if($mopicli =~ /Current source voltage: (\d+)/m) {
    push(@graph, $hostname . "_voltage=$1");
  }
}

#
#
#

if($netstat =~ /192.168.2.1\s/m)
{
  my $login = `/usr/bin/curl -s -k "https://192.168.2.1/api/login?username=admin&password=ekst3rr\@"`;
  if($login =~ /"token" : "(.*?)"/m)
  {
    my $ppp = &run("/usr/bin/curl -s -k \"https://192.168.2.1/api/stats/ppp?token=$1\"");

    $out .= "\n#\n" . "# ppp" . "\n#";
    $out .= "\n\n" . $ppp . "\n";

    if($ppp =~ /"rssi" : "(\d+)"/m) {
      push(@graph, $hostname . "_rssi=$1");
    }
  }
}

#
#
#

if(-e "/usr/bin/iperf3")
{
  my $iperf3 = &run("/usr/bin/iperf3 -c 35.162.236.91 -n5000000 -fK");

  $out .= "\n#\n" . "# iperf3" . "\n#";
  $out .= "\n\n" . $iperf3 . "\n";

  if($iperf3 =~ /(\d+) KBytes\/sec\s.*?\ssender/m) {
    push(@graph, $hostname . "_bandwidth=$1");
  }
}

#
#
#

my $uvolt = &run("/bin/grep Under-voltage /var/log/syslog");

$out .= "\n#\n" . "# uvolt" . "\n#";
$out .= "\n\n" . $uvolt . "\n";

#
#
#

my $top = &run("/usr/bin/top -b -n1 | /usr/bin/head -30");

$out .= "\n#\n" . "# top" . "\n#";
$out .= "\n\n" . $top . "\n";

#
#
#

print "$out\n";

#
# copy files
#

print "\n#\n", "# copy files", "\n#\n\n";

my $time = time();

my $file = "$time.txt";

mkdir("/home/pi/status") unless(-e "/home/pi/status");
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

print "\n#\n", "# graph", "\n#\n\n";

my $cmd = "/usr/bin/ssh uaws2 www/vhosts/ixnay/bin/graph4.pl $time " . join(" ", @graph);
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

  #print "$cmd\n";
  my $out = `$cmd 2>&1`;
  chomp($out);
  #print "out=$out\n";

  return $out;
}

