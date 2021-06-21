{
  description = "A package and module for using GNU Guix on Nix(OS)";

  # we want frequent updates, but not on master.
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
  inputs.flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };

  outputs = { self, nixpkgs, flake-compat }:
    let
      forAllSystems =
        nixpkgs.lib.genAttrs [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
    in {

      overlay = final: prev:
        let guilePackages = prev.callPackages ./guile { };
        in rec {
          guix = prev.callPackage ./package { inherit guilePackages; };
          inherit (guilePackages)
            guile-gnutls guile-gcrypt guile-git guile-json guile-sqlite3
            guile-ssh;
          scheme-bytestructures = guilePackages.bytestructures;
        };

      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in self.overlay pkgs pkgs);

      defaultPackage = forAllSystems (system: self.packages.${system}.guix);

      nixosModules = { guix = import ./module; };

      devShell = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        pkgs.mkShell {
          name = "nixos-guix-cli-devShell";
          nativeBuildInputs = with pkgs; [ git guile];
        }
      );

    };
}
