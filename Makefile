# Makefile for Sloth app

XCODE_PROJ := "hear.xcodeproj"
PROGRAM_NAME := "hear"
BUILD_DIR := "products"
VERSION := "0.4"

all: clean build_unsigned

release: clean build_signed archive size

test: clean build_unsigned runtests

build_unsigned:
	mkdir -p $(BUILD_DIR)
	xcodebuild	-project "$(XCODE_PROJ)" \
	            -target "$(PROGRAM_NAME)" \
	            -configuration "Debug" \
	            CONFIGURATION_BUILD_DIR="$(BUILD_DIR)" \
	            CODE_SIGN_IDENTITY="" \
	            CODE_SIGNING_REQUIRED=NO \
	            CODE_SIGNING_ALLOWED=NO \
	            build

build_signed:
	mkdir -p $(BUILD_DIR)
	xcodebuild  -parallelizeTargets \
	            -project "$(XCODE_PROJ)" \
	            -target "$(PROGRAM_NAME)" \
	            -configuration "Release" \
	            CONFIGURATION_BUILD_DIR="$(BUILD_DIR)" \
	            CODE_SIGNING_REQUIRED=YES \
	            CODE_SIGNING_ALLOWED=YES \
	            build

archive:
	@mkdir "$(BUILD_DIR)/$(PROGRAM_NAME)-$(VERSION)"
	@cp "$(BUILD_DIR)/$(PROGRAM_NAME)" "$(BUILD_DIR)/$(PROGRAM_NAME)-$(VERSION)/"
	@cp "$(PROGRAM_NAME).1" "$(BUILD_DIR)/$(PROGRAM_NAME)-$(VERSION)/"
	@cp "install.sh" "$(BUILD_DIR)/$(PROGRAM_NAME)-$(VERSION)/"
	@cd "$(BUILD_DIR)"; zip -qy --symlinks "$(PROGRAM_NAME)-$(VERSION).zip" -r "$(PROGRAM_NAME)-$(VERSION)"
	@cd "$(BUILD_DIR)"; rm -r "$(PROGRAM_NAME)-$(VERSION)"

size:
	@echo "Binary size:"
	@stat -f %z "$(BUILD_DIR)/$(PROGRAM_NAME)"
	@echo "Archive size:"
	@cd "$(BUILD_DIR)"; du -hs "$(PROGRAM_NAME)-$(VERSION).zip"

runtests:
# The tests don't work in CI env due to missing permissions from macOS
#	@echo "Running tests"
#	@bash "test/test.sh"
	@"$(BUILD_DIR)/$(PROGRAM_NAME)" --version

clean:
	xcodebuild -project "$(XCODE_PROJ)" clean
	rm -rf products/* 2> /dev/null
