#!/usr/bin/perl

my @ip = split(/\s+/, `/sbin/ip route | /bin/grep default`);
my $gw = $ip[2];
my $dev = $ip[4];

print "gw=$gw\n";
print "dev=$dev\n";

#
# ping gateway
#

if(&ping($gw)) {
  print "\nnetwork is up\n";
  exit;
}

#
# try again
#

sleep 5;
if(&ping($gw)) {
  print "\nnetwork is up\n";
  exit;
}

#
# restart my interface
#

print "\nrestarting network...\n";
&cmd("/sbin/ifdown --force $dev");
sleep 10;
&cmd("/sbin/ifup $dev > /dev/null 2>&1");
sleep 10;

if(&ping($gw)) {
  print "successful networking restart\n";
  exit;
}

#
# did i reboot in the past hour?
#

my $uptime = &cmd("/bin/cat /proc/uptime");
$uptime =~ /(\d+)\./;
my $sec = $1;
print "sec=$sec\n";
if($sec < 3600) {
  print "\nalready rebooted in the past hour\n";
  exit;
}

#
# reboot
#

print "\nrebooting...\n";
exit;
`/sbin/reboot`;

exit;

#
#
#

sub ping
{
  my($addr) = @_;

  my $ping = &cmd("/bin/ping -c4 -w1 $addr");
  if($ping =~ /1 received/s) {
    return 1;
  }
  else {
    return 0;
  }
}

sub cmd
{
  my($cmd) = @_;

  print "\ncmd=$cmd\n";
  my $out = `$cmd`;
  print "out=$out\n";
  
  return $out;
}


