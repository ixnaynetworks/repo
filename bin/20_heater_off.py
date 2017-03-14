#!/usr/bin/python

import RPi.GPIO as GPIO
from time import sleep

# The script as below using BCM GPIO 00..nn numbers
GPIO.setmode(GPIO.BCM)

# Set relay pins as output
GPIO.setup(20, GPIO.OUT)

## off
GPIO.output(20, GPIO.LOW)

