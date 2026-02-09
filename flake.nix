{
  description = "Mozid - retrieve Firefox add-on IDs";

  outputs = { self, nixpkgs }: let
    systems = [ "aarch64-linux" "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
    forEachSystem = nixpkgs.lib.genAttrs systems;
  in {
      # System-agnostic library (uses only builtins, no pkgs dependency)
      lib = import ./lib.nix { };

      packages = forEachSystem (system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = self.packages.${system}.mozid;
        # Create a package with lib.nix in share directory
        mozid = pkgs.stdenv.mkDerivation {
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
      });
    };
}
