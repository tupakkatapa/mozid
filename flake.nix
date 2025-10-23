{
  description = "Mozid - retrieve Firefox add-on IDs";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    {
      # System-agnostic library (uses only builtins, no pkgs dependency)
      lib = import ./lib.nix { };
    }
    // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Create a package with lib.nix in share directory
        package = pkgs.stdenv.mkDerivation {
          name = "mozid";
          src = ./.;

          buildInputs = [ pkgs.makeWrapper ];

          installPhase = ''
            mkdir -p $out/bin $out/share/mozid

            # Install lib.nix
            cp ${./lib.nix} $out/share/mozid/lib.nix

            # Create wrapper script
            substitute ${./mozid.sh} $out/bin/mozid \
              --replace '@lib@' "$out/share/mozid/lib.nix"

            chmod +x $out/bin/mozid

            # Wrap to ensure nix is in PATH
            wrapProgram $out/bin/mozid \
              --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.nix ]}
          '';
        };
      in
      {
        packages.default = package;
        packages.mozid = package;
      }
    );
}
