class Hear < Formula
  desc "Command line interface for the built-in speech recognition and transcription capabilities in macOS."
  homepage "https://github.com/sveinbjornt/hear"
  url "https://github.com/sveinbjornt/hear/archive/refs/tags/0.6.tar.gz"
  sha256 "a6487df045a031c5aae6bfdcb6f9feba187d9456841242aa2aaf31d854a974ca"
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
