#!/usr/bin/perl

sub get_token
{
  $token = $ARGV[0];

  unless($token)
  {
    ## get token
    print LOG "\ngetting token...\n";
    $cmd = "/usr/bin/curl -s -1 -k 'https://192.168.2.1/api/logout?username=admin&password=admin'";
    $out = `$cmd`;
    print LOG "\n$cmd\n$out\n";

    print LOG "\nlogging in...\n";
    $cmd = "/usr/bin/curl -s -1 -k 'https://192.168.2.1/api/login?username=admin&password=admin'";
    $out = `$cmd`;
    print LOG "\n$cmd\n$out\n";
    $out =~ /"token" : "(.*?)"/;
    $token = $1;
  }

  return $token;
}

sub ppp_enabled
{
  my($token) = @_;

  $enabled = 0;

  print LOG "\nppp enabled?\n";
  $cmd = "/usr/bin/curl -s -1 -k 'https://192.168.2.1/api/ppp/enabled?token=$token'";
  $out = `$cmd`;
  print LOG "\n$cmd\n$out\n";
  if($out =~ /"result" : true,/) {
    $enabled = 1;
  }

  return $enabled;
}

sub network_detected
{
  my $detected = 0;

  print LOG "\ndetecting network...\n";

  my $cmd = "/usr/bin/lynx -source http://www.pinecreekskiresort.com/webcam/conf/network_status";
  my $out = `$cmd`;
  print LOG "\n$cmd\n$out\n";

  if($out =~ /^success/) {
    $detected = 1;
  }

  return $detected;
}

sub rcell_restart
{
  my($token) = @_;

  print LOG "\nrestarting...\n";
  $cmd = "/usr/bin/curl -s -1 -k -X POST -d \"\" 'https://192.168.2.1/api/command/save_restart?token=$token'";
  $out = `$cmd`;
  print LOG "\n$cmd\n$out\n";
}

sub openvpn_restart
{
  print LOG "\nrestarting openvpn...\n";
  $cmd = "/usr/sbin/service openvpn restart";
  $out = `$cmd`;
  print LOG "\n$cmd\n$out\n";
}

1;

