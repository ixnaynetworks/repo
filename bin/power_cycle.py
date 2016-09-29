#!/usr/bin/python
import sys
import RPi.GPIO as GPIO
import time

pin = int(sys.argv[1])
GPIO.setmode(GPIO.BCM)

GPIO.setup(pin, GPIO.OUT) 
time.sleep(2); 
GPIO.output(pin, GPIO.HIGH)

# time to sleep between operations in the main loop

try:
  GPIO.output(pin, GPIO.LOW)
  print "POWER CYCLE..."
  time.sleep(2); 
  GPIO.cleanup()
  print "Good bye!"

# End program cleanly with keyboard
except KeyboardInterrupt:
  print "  Quit"

  # Reset GPIO settings
  GPIO.cleanup()

