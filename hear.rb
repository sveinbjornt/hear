class Hear < Formula
  desc "Command line interface for the built-in speech recognition and transcription capabilities in macOS."
  homepage "https://github.com/sveinbjornt/hear"
  url "https://github.com/sveinbjornt/hear/archive/refs/tags/0.8.tar.gz"
  sha256 "27ca9cb067721e22dfac2db888dc962ad4fe1b079a5f8e03ff13279ce0892e34"
  license "BSD-3-Clause"

  depends_on xcode: ["10.0", :build]
  depends_on macos: :ventura

  def install
    system "xcodebuild", "-project", "hear.xcodeproj",
           "-target", "hear",
           "-configuration", "Release",
           "SYMROOT=build",
           "CODE_SIGN_IDENTITY=",
           "CODE_SIGNING_REQUIRED=NO",
           "CODE_SIGNING_ALLOWED=NO"
    
    bin.install "build/Release/hear"
    man1.install "hear.1"
  end

  test do
    system "bin/\"hear\"", "--version"
  end
end
