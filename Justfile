export bin := "hear"
export version := `git describe --tags --abbrev=0`

[private]
@default:
	just --list --unsorted

# Build the project for development
build:
	make

# Remove the build artifacts
clean:
	make clean

# Run unit tests
test:
	bats tests/*.bats

[private]
build-signed:
	make \
		BUILD_ARGS="-parallelizeTargets" \
		CONFIGURATION="Release"

[private]
package:
	#!/usr/bin/env bash
	test -f build/Release/{{ bin }} || exit 1
	archive="{{ bin }}-{{ version }}.zip"
	rm -rf $archive
	mkdir -p dist
	cp \
		build/Release/{{ bin }} \
		{{ bin }}.1 \
		install.sh \
		dist/
	zip -qy --symlinks $archive -j dist/*
	unzip $archive -d dist/release

# Package the release
@release: build-signed package
	echo
	du -sh "dist/release/{{ bin }}"
	du -sh "{{ bin }}-{{ version }}.zip"