{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    ghc
    cabal-install
    haskellPackages.brick
    haskellPackages.vty
    haskellPackages.vty-crossplatform
    haskellPackages.microlens
    haskellPackages.microlens-th
    haskellPackages.microlens-mtl
    zlib
  ];
}

