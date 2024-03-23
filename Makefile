CONFIGURATION ?= Debug

all: build/${CONFIGURATION}/hear hear.1.html

build/${CONFIGURATION}/hear:
	xcodebuild \
		-project "hear.xcodeproj" \
		-target "hear" \
		-configuration "$(CONFIGURATION)" \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO \
		$${BUILD_ARGS} \
		clean build

hear.1.html: hear.1
	echo /usr/bin/man $< | ./cat2html > $@

.PHONY: clean
clean:
	xcodebuild -project hear.xcodeproj clean