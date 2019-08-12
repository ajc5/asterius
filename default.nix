#
# The defaul.nix file. This will generate targets for all
# buildables.  These include anything from stack.yaml
# (via nix-tools:stack-to-nix) or cabal.project (via
# nix-tools:plan-to-nix). As well as custom definitions
# on top.
#
# nix-tools stack-to-nix or plan-to-nix will generate
# the `nix/plan.nix` file. Where further customizations
# outside of the ones in stack.yaml/cabal.project can
# be specified as needed for nix/ci.
#

# We will need to import the local lib, which will
# give us the iohk-nix tooling, which also includes
# the nix-tools tooling.
{ config ? {}
, system ? builtins.currentSystem
, crossSystem ? null
, ... }@args:
let
  localLib = import ./nix/lib.nix { inherit config system crossSystem; };

# This file needs to export a function that takes
# the arguments it is passed and forwards them to
# the default-nix template from iohk-nix. This is
# important so that the release.nix file can properly
# parameterize this file when targetting different
# hosts.
# We will instantiate the defaul-nix template with the
# nix/pkgs.nix file...
  default-nix = localLib.nix-tools.default-nix ./nix/default.nix args;
  inherit (default-nix.nix-tools-raw) plan-nix pkgs hsPkgs nodePkgs nodejs;
  cabalSystem = builtins.replaceStrings ["-darwin"] ["-osx"] pkgs.stdenv.system;

  # Use this to set the version of asterius to be booted in the shell.
  # By pinning this we avoid re running ahc-boot for every change.
  cached = import (pkgs.fetchgit {
    url = "https://github.com/input-output-hk/asterius";
    rev = "bed3bf7a34b5540aa953cbccd6ae04824fce8253";
    sha256 = "155r0q4c246f0sv5ppgm0d7qgfdvl5nn2rmd2gp52jxc2psq1y3p";
    fetchSubmodules = true;
  }) {};
  shells = {
    ghc = (hsPkgs.shellFor {
      # Shell will provide the dependencies of asterius, but not asterius itself.
      packages = ps: with ps; [
        asterius
        binaryen
        ghc-toolkit
        wabt
        ghc-toolkit
        inline-js
        inline-js-core
        wabt
        wasm-toolkit ];
    }).overrideAttrs (oldAttrs: {
      buildInputs = oldAttrs.buildInputs ++ [
        pkgs.haskellPackages.hpack
        pkgs.wabt
        nodejs
        nodePkgs.parcel-bundler
        nodePkgs.todomvc-app-css
        nodePkgs.todomvc-common ];
      shellHook = (oldAttrs.shellHook or "") + ''
        unset CABAL_CONFIG
        export asterius_bootdir=${cached.nix-tools-raw.asterius-boot}/boot
        find . -name package.yaml -exec hpack "{}" \;
        export asterius_datadir=$(pwd)/asterius
        export binaryen_datadir=$(pwd)/binaryen
        export ghc_toolkit_datadir=$(pwd)/ghc-toolkit
        # export sandbox_ghc_lib_dir=$(ghc --print-libdir) # does not include `indclude` dir
        export sandbox_ghc_lib_dir=$(${default-nix.nix-tools-raw.ghc-compiler}/bin/ghc --print-libdir)
        export inline_js_datadir=$(pwd)/inline-js/inline-js
        export inline_js_core_datadir=$(pwd)/inline-js/inline-js-core
        export wabt_datadir=$(pwd)/wabt
        export wasm_toolkit_datadir=$(pwd)/wasm-toolkit
        export boot_libs_path=${default-nix.nix-tools-raw.ghc865.boot-libs}
        mkdir -p asterius-cabal-bin
        cd asterius-cabal-bin
        export asterius_bindir=$(pwd)
        export PATH=$(pwd):$PATH
        ''
        + pkgs.lib.concatMapStrings (exe: ''
          ln -sf ../dist-newstyle/build/${cabalSystem}/ghc-8.6.4/asterius-0.0.1/build/${exe}/${exe} ${exe}
        '') ["ahc" "ahc-boot" "ahc-cabal" "ahc-dist" "ahc-ld" "ahc-link" "ahc-pkg"]
        + ''
        cd ..
      '';
    });
  };
in
  default-nix //
    { inherit plan-nix shells; }
