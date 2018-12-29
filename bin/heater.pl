#!/usr/bin/perl

if(-e "/home/pi/conf/heater") {
  `/home/pi/bin/23_heater_on.py`;
}
else {
  `/home/pi/bin/23_heater_off.py`;
}

