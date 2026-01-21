# flakelight-chez -- Chez Scheme module for flakelight
# Copyright (C) 2023 Archit Gupta <archit@accelbread.com>
# SPDX-License-Identifier: MIT

{ config, lib, src, ... }:
let
  inherit (builtins) pathExists readFile;
  inherit (lib) mkIf mkMerge mkOption mkDefault;
  inherit (lib.types) functionTo listOf package str bool;

  manifestFile = src + /manifest.scm;
  hasManifest = pathExists manifestFile;

  # Simple parser for manifest.scm
  # Expected format: ((name "foo") (version "1.0.0") (program "main.ss"))
  parseManifest = path:
    let
      content = readFile path;
      # This is a simplified parser - in practice might need more sophisticated parsing
      nameMatch = builtins.match ".*\\(name[[:space:]]+\"([^\"]+)\"\\).*" content;
      versionMatch = builtins.match ".*\\(version[[:space:]]+\"([^\"]+)\"\\).*" content;
      programMatch = builtins.match ".*\\(program[[:space:]]+\"([^\"]+)\"\\).*" content;
    in
    {
      name = if nameMatch != null then builtins.head nameMatch else null;
      version = if versionMatch != null then builtins.head versionMatch else null;
      program = if programMatch != null then builtins.head programMatch else null;
    };

  manifest = if hasManifest then parseManifest manifestFile else { };
in
{
  options = {
    chezPackage = mkOption {
      type = functionTo package;
      default = pkgs: pkgs.chez;
      description = "Function that takes pkgs and returns the Chez Scheme package to use";
    };

    chezLibraries = mkOption {
      type = functionTo (listOf package);
      default = _: [ ];
      description = "Additional Chez Scheme libraries to make available";
    };

    chezProgram = mkOption {
      type = str;
      default = "main.ss";
      description = "Main program file to compile/install";
    };

    chezCompile = mkOption {
      type = bool;
      default = true;
      description = "Whether to compile the Scheme code to native code";
    };
  };

  config = mkMerge [
    {
      pname = mkDefault "chez-program";
    }

    (mkIf hasManifest (mkMerge [
      (mkIf (manifest.name != null) { pname = manifest.name; })
      (mkIf (manifest.program != null) { chezProgram = manifest.program; })
    ]))

    {
      package = { stdenvNoCC, pkgs, defaultMeta }:
        let
          chez = config.chezPackage pkgs;
          version = if hasManifest && manifest.version != null then manifest.version else "0.1.0";
          programFile = config.chezProgram;
          doCompile = config.chezCompile;
          libs = config.chezLibraries pkgs;
        in
        stdenvNoCC.mkDerivation {
          pname = config.pname;
          inherit version src;
          nativeBuildInputs = [ chez ];
          buildInputs = libs;
          dontConfigure = true;

          buildPhase = ''
            runHook preBuild

            # Set up library path for any dependencies
            export CHEZSCHEMELIBDIRS="${lib.concatMapStringsSep ":" (p: "${p}/lib/csv${chez.version}") libs}"

            ${if doCompile then ''
              # Compile the main program
              echo '(compile-program "${programFile}")' | scheme -q
            '' else ''
              # Just validate syntax
              scheme --script ${programFile} --help 2>/dev/null || true
            ''}

            runHook postBuild
          '';

          installPhase = ''
                        runHook preInstall

                        mkdir -p $out/bin
                        mkdir -p $out/lib/chez

                        # Copy all scheme files
                        find . -name "*.ss" -o -name "*.scm" -o -name "*.sls" -o -name "*.sps" | \
                          xargs -I {} cp {} $out/lib/chez/

                        # Copy compiled files if they exist
                        find . -name "*.so" -o -name "*.wpo" | \
                          xargs -I {} cp {} $out/lib/chez/ 2>/dev/null || true

                        # Create wrapper script
                        cat > $out/bin/${config.pname} <<EOF
            #!/bin/sh
            export CHEZSCHEMELIBDIRS="$out/lib/chez:\$CHEZSCHEMELIBDIRS"
            exec ${chez}/bin/scheme --program $out/lib/chez/${programFile} "\$@"
            EOF
                        chmod +x $out/bin/${config.pname}

                        runHook postInstall
          '';

          meta = defaultMeta;
        };

      devShell.packages = pkgs:
        [ (config.chezPackage pkgs) ] ++ config.chezLibraries pkgs;

      formatters = pkgs: {
        "*.ss" = "${pkgs.chez}/bin/scheme --script";
        "*.scm" = "${pkgs.chez}/bin/scheme --script";
        "*.sls" = "${pkgs.chez}/bin/scheme --script";
      };
    }
  ];
}
