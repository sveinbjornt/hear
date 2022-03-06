#!/bin/bash
#
# Test binary by running various commands
#

products/hear -i "test/test.wav"
cat "test/test.wav" | hear -i '-' -f 'wav'
