#!/bin/bash
#
# Test binary by running various commands
#

EXPECTED="The rain in Spain stays mainly in the plane "

OUT=$(products/hear -i "test/test.wav" -d)

if [ "$OUT" != "$EXPECTED" ]; then
    echo "Unexpected output"
    exit 1
else
    exit 0
fi

# cat "test/test.wav" | products/hear -i '-' -f 'wav'
