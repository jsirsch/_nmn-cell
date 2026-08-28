{
  description = "NMN Cell Simulation - Intracellular Nicotinamide Mononucleotide synthesis TUI in Haskell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        haskellPackages = pkgs.haskellPackages;

        packageName = "nmn-cell";

        nmnCellPkg = haskellPackages.callCabal2nix packageName ./. {};
      in
      {
        packages = {
          default = nmnCellPkg;
          nmn-cell = nmnCellPkg;
        };

        apps = {
          default = {
            type = "app";
            program = "${nmnCellPkg}/bin/nmn-cell-tui";
          };
          nmn-cell-tui = {
            type = "app";
            program = "${nmnCellPkg}/bin/nmn-cell-tui";
          };
        };

        devShells.default = haskellPackages.shellFor {
          packages = p: [ nmnCellPkg ];
          buildInputs = with haskellPackages; [
            cabal-install
            haskell-language-server
            hlint
            ghcid
          ] ++ (with pkgs; [
            zlib
          ]);
          withHoogle = true;
        };
      }
    );
}

