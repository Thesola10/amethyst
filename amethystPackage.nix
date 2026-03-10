{ pkgs, stdenv, lib, amethyst, amber-lang

  # Name of the project
, pname ? ""

  # Version of the project
, version ? ""

  # Name of the resulting package
, name ? if (version == "") then pname else "${pname}-${version}"

  # Path to the project source code.
, src

  # Result hash for vendored Amethyst dependencies.
  # Don't know what to put in here? Leave it empty and Nix will give you the
  # correct hash.
, vendorHash
, ... }:

let
  vendor = stdenv.mkDerivation {
    inherit src;

    name = "${name}-vendor";
    outputHash = vendorHash;
    outputHashAlgo = "sha256";
    outputHashMode = "nar";

    dontPatchShebangs = true;

    phases = [ "unpackPhase" "buildPhase" "installPhase" ];

    nativeBuildInputs = [
      amethyst
      amber-lang
      pkgs.cacert
    ];

    buildPhase = ''
      amethyst install
      rm -rf amethyst_modules/*.git/hooks/
      rm -rf amethyst_modules/*.git/worktrees/*
    '';

    installPhase = ''
      mkdir -p $out
      cp -r amethyst_modules vendor $out/
    '';
  };
in
stdenv.mkDerivation {
  inherit pname name version src;

  nativeBuildInputs = [
    amethyst
    amber-lang
  ];

  configurePhase = ''
    ln -s ${vendor}/vendor vendor
    ln -s ${vendor}/amethyst_modules amethyst_modules
  '';

  buildPhase = ''
    HOME=/tmp amethyst build
  '';

  installPhase = ''
    install -Dm755 target/${name}.sh $out/bin/${name}
  '';

  passthru = { inherit vendor; };
}
