# https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/mobile/xcodeenv/build-app.nix
# https://github.com/nix-community/nur-combined/blob/6bbc96b767dc06c59c6eb73f9eae589cc86f40e7/repos/Samuel-Martineau/pkgs/latexit/default.nix#L35
# https://github.com/nix-community/nur-combined/blob/master/repos/Samuel-Martineau/pkgs/latexit/default.nix

{ stdenv, xcodeenv, pkgs }:
let
  # frameworks = pkgs.darwin.apple_sdk.frameworks;
  xcodewrapper = xcodeenv.composeXcodeWrapper {
    version = "15.2";
    allowHigher = true;
  };
in
stdenv.mkDerivation{
  meta = {
    description = "Command line speech recognition and transcription for macOS";
    homepage = "https://github.com/sveinbjornt/hear";
  };
  src = ../../.;
  pname = "hear";
  version = "0.5";

  nativeBuildInputs =
    [
      xcodewrapper
      # https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/darwin/apple-sdk/frameworks.nix
      # frameworks.MediaToolbox
    ];

  buildInputs = [ ];

  buildPhase = ''
    export PATH=${xcodewrapper}/bin:$PATH

    runHook preBuild
    export LD=$CXX

    mkdir -p derivedData

    xcodebuild clean build \
      -project hear.xcodeproj \
      -scheme hear \
      -configuration Debug \
      -derivedDataPath ./derivedData \
      -verbose \
      CONFIGURATION_BUILD_DIR="products" \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO \
      CODE_SIGNING_ALLOWED=NO

    runHook postBuild
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp hear $out/bin
  '';
}