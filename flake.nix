{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin" # only tested with this system
      ];
      perSystem = { config, pkgs, ... }:
        let
          frameworks = pkgs.darwin.apple_sdk.frameworks;
          hear = pkgs.callPackage ./nix/pkgs/hear.nix { };
          xcode = pkgs.xcodeenv.composeXcodeWrapper {
            version = "15.2";
            allowHigher = true;
          };
        in
        {
          packages = {
            inherit hear;
            default = hear;
          };
          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              (bats.withLibraries (libexec: with libexec; [
                bats-support
                bats-assert
              ]))
              just
              xcode
              xcpretty
              frameworks.Foundation
              frameworks.AppKit
              frameworks.Speech
            ];
          };
        };
    };
}
