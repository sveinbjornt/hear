#!/usr/bin/env bash
#
# Test binary by running various commands
#

abs_path_to_enclosing_dir () {
   echo "$(dirname $(cd $(dirname "$1");pwd)/$(basename "$1"))"
}

TEST_ROOT=$(abs_path_to_enclosing_dir $0)
BIN_PATH="products/hear"

                 
test_transcribe_file() {
    OUTPUT=$("$BIN_PATH" -d -i "$1" -l "$2")
    if [ "$OUTPUT" != "$3" ]; then
        echo "Unexpected output: ${OUTPUT}"
        exit 1
    fi
}

# en-US
EXPECTED_OUTPUT="The rain in Spain stays mainly in the plain"
LOCALE="en-US"

WAV_PATH="$TEST_ROOT/en-US.wav"
test_transcribe_file $WAV_PATH $LOCALE "$EXPECTED_OUTPUT"

MP3_PATH="$TEST_ROOT/en-US.mp3"
test_transcribe_file $MP3_PATH $LOCALE "$EXPECTED_OUTPUT"

# fr-FR
EXPECTED_OUTPUT="Ça soir je vais à la maison"
LOCALE="fr-FR"

WAV_PATH="$TEST_ROOT/fr-FR.wav"
test_transcribe_file $WAV_PATH $LOCALE "$EXPECTED_OUTPUT"

