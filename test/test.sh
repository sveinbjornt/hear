#!/bin/bash
#
# Test binary by running various commands
#

abs_path_to_enclosing_dir () {
   echo "$(dirname $(cd $(dirname "$1");pwd)/$(basename "$1"))"
}

TEST_ROOT=$(abs_path_to_enclosing_dir $0)
BIN_PATH="products/hear"

EXPECTED_OUTPUT="The rain in Spain stays mainly in the plain"
                 
test_transcribe_file() {
    OUTPUT=$("$BIN_PATH" -d -i "$1")
    if [ "$OUTPUT" != "$EXPECTED_OUTPUT" ]; then
        echo "Unexpected output: ${OUTPUT}"
        exit 1
    fi
}

WAV_PATH="$TEST_ROOT/test.wav"
test_transcribe_file $WAV_PATH

WAV_PATH="$TEST_ROOT/test.mp3"
test_transcribe_file $WAV_PATH
