#!/usr/bin/perl

## compute filename
#my $file = time() . ".txt";
my($sec, $min, $hr, $day, $mon, $year) = localtime(time);
$year += 1900;
$mon++;
my $file = sprintf("%4d%02d%02d%02d%02d%02d.txt", $year, $mon, $day, $hr, $min, $sec);

&traceroute();
&df();
&vcgencmd();
&mopicli();
&router();

print "\n";
my $hostname = `/bin/hostname`;
chomp($hostname);

my $rsync = "/usr/bin/rsync -avz --delete /home/pi/graphs3/ uaws2:www/vhosts/ixnay/htdocs/cams/$hostname/graphs3/uploads";
print "$rsync\n";
my $out = `$rsync`;
print "$out\n";

my $graph3 = "/usr/bin/ssh uaws2 /home/michael/www/vhosts/ixnay/bin/graph3.pl $hostname";
print "$graph3\n";
my $out = `$graph3`;
print "$out\n";

exit;

#
#
#

sub traceroute
{
  print "\n";
  my $traceroute = "/usr/bin/sudo /usr/sbin/traceroute -T -n 35.162.236.91 >> /home/pi/graphs3/traceroute/$file";
  print "$traceroute\n";
  my $out = `$traceroute`;
  print "$out\n";
}

sub df
{
  print "\n";
  my $df = "/bin/df -h >> /home/pi/graphs3/df/$file";
  print "$df\n";
  my $out = `$df`;
  print "$out\n";
}

sub vcgencmd
{
  print "\n";
  my $vcgencmd = "/opt/vc/bin/vcgencmd measure_temp >> /home/pi/graphs3/vcgencmd/$file";
  print "$vcgencmd\n";
  my $out = `$vcgencmd`;
  print "$out\n";
}

sub mopicli
{
  print "\n";
  my $mopicli = "/usr/sbin/mopicli -e >> /home/pi/graphs3/mopicli/$file";
  print "$mopicli\n";
  my $out = `$mopicli`;
  print "$out\n";
}

sub router
{
  my($sh);
  open($sh, ">", "/home/pi/graphs3/router/$file");

  my($cmd, $out);

  my($token);
  print $sh "\nlogging out...\n";
  $cmd = "/usr/bin/curl -s -1 -k 'https://192.168.2.1/api/logout?username=admin&password=ekst3rr\@'";
  $out = `$cmd`;
  $cmd =~ s/password=.*'/password=password'/;
  $out =~ s/permission" : ".*"/permission : "password"/;
  print $sh "\n$cmd";
  print $sh "\n$out";

  print $sh "\nlogging in...\n";
  $cmd = "/usr/bin/curl -s -1 -k 'https://192.168.2.1/api/login?username=admin&password=ekst3rr\@'";
  $out = `$cmd`;
  $cmd =~ s/password=.*'/password=password'/;
  $out =~ s/permission" : ".*"/permission : "password"/;
  print $sh "\n$cmd";
  print $sh "\n$out";
  if($out =~ /"token" : "(.*?)"/)
  {
    $token = $1;
    print $sh "token=$token\n";

    print $sh "\n##########\n\n";
    $cmd = "/usr/bin/curl -s -1 -k 'https://192.168.2.1/api/system/uptime?token=$token'";
    $out = `$cmd`;
    print $sh "\n$cmd\n$out\n";

    print $sh "\n##########\n\n";
    $cmd = "/usr/bin/curl -s -1 -k 'https://192.168.2.1/api/stats/radio?token=$token'";
    $out = `$cmd`;
    print $sh "\n$cmd\n$out\n";
  }

  close($sh);
}

