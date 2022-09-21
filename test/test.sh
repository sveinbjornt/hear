#!/bin/bash
#
# Test binary by running various commands
#

abs_path_to_enclosing_dir () {
   echo "$(dirname $(cd $(dirname "$1");pwd)/$(basename "$1"))"
}

TEST_ROOT=$(abs_path_to_enclosing_dir $0)

BIN_PATH="products/hear"
WAV_PATH="$TEST_ROOT/test.wav"

EXPECTED_OUTPUT="The rain in Spain stays mainly in the plane"

OUTPUT=$("$BIN_PATH" -i "$WAV_PATH" -d)

if [ "$OUTPUT" != "$EXPECTED_OUTPUT" ]; then
    echo "Unexpected output"
    exit 1
else
    exit 0
fi

# cat "test/test.wav" | products/hear -i '-' -f 'wav'
