# https://ertt.ca/nix/shell-scripts/
{
  description = "Mozid - retrieve Firefox add-on IDs";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        my-name = "mozid";
        my-buildInputs = with pkgs; [ curl wget unzip gnugrep jq ];
        my-script = (pkgs.writeScriptBin my-name (builtins.readFile ./mozid.sh)).overrideAttrs(old: {
          buildCommand = "${old.buildCommand}\n patchShebangs $out";
        });
      in rec {
        defaultPackage = packages.mozid;
        packages.mozid = pkgs.symlinkJoin {
          name = my-name;
          paths = [ my-script ] ++ my-buildInputs;
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = "wrapProgram $out/bin/${my-name} --prefix PATH : $out/bin";
        };
      }
    );
}
