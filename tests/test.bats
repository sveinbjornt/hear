#!/usr/bin/env bats

BIN=dist/release/hear

function setup() {
    bats_require_minimum_version "1.8.0"
    bats_load_library bats-support
    bats_load_library bats-assert
}

@test "bin is available" {
    run -0 which $BIN
}

@test "transcribe test.wav" {
    run $BIN -d -i ./test.wav
    assert_success
    assert_output "The rain in Spain stays mainly in the plain"
}
