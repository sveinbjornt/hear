class Hear < Formula
  desc "Command line interface for the built-in speech recognition and transcription capabilities in macOS."
  homepage "https://github.com/sveinbjornt/hear"
  url "https://github.com/sveinbjornt/hear/archive/refs/tags/0.7.tar.gz"
  sha256 "c3384115f11e59ec2744b257c1c1a5e0c0013c6813d8f34b8ba749833cb0f5f9"
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
