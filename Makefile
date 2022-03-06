# Makefile for Sloth app

XCODE_PROJ := "hear.xcodeproj"
PROGRAM_NAME := "hear"
BUILD_DIR := "products"

all: clean build_unsigned

release: clean build_signed

build_unsigned:
	mkdir -p $(BUILD_DIR)
	xcodebuild	-project "$(XCODE_PROJ)" \
	            -target "$(PROGRAM_NAME)" \
	            -configuration "Debug" \
	            CONFIGURATION_BUILD_DIR="$(BUILD_DIR)" \
	            CODE_SIGN_IDENTITY="" \
	            CODE_SIGNING_REQUIRED=NO \
	            build

build_signed:
	mkdir -p $(BUILD_DIR)
	xcodebuild  -parallelizeTargets \
	            -project "$(XCODE_PROJ)" \
	            -target "$(PROGRAM_NAME)" \
	            -configuration "Release" \
	            CONFIGURATION_BUILD_DIR="$(BUILD_DIR)" \
	            build
clean:
	xcodebuild -project "$(XCODE_PROJ)" clean
	rm -rf products/* 2> /dev/null
