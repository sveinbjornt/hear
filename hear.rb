class Hear < Formula
  desc "Command-line speech recognition and transcription for macOS"
  homepage "https://github.com/sveinbjornt/hear"
  url "https://github.com/sveinbjornt/hear/archive/refs/tags/0.5.tar.gz"
  sha256 "b38d2a84511e7decebe007f2b073a69ccc1092a8014efb33610e134eca19c038"
  license "BSD-3-Clause"

  depends_on xcode: ["10.0", :build]
  depends_on macos: :catalina

  def install
    mkdir "#{buildpath}/dst"
    xcodebuild "SYMROOT=build", "DSTROOT=#{buildpath}/dst",
               "-project", "hear.xcodeproj",
               "-target", "hear",
               "CODE_SIGN_IDENTITY=",
               "CODE_SIGNING_REQUIRED=NO",
               "CODE_SIGNING_ALLOWED=NO",
               "clean", "install"
    man1.install "hear.1"
    bin.install "dst/hear" => "hear"
  end

  test do
    system "#{bin}/hear", "--version"
  end
end
