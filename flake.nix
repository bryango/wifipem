{
  inputs.nixpkgs.url = "nixpkgs";

  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = lib.genAttrs supportedSystems;
      systemsPkgs = forAllSystems (system: nixpkgs.legacyPackages.${system});

      pyproject = lib.importTOML ./pyproject.toml;
      inherit (pyproject.tool.poetry) name version;
      pname = name;

      mkPackage = pkgs: lib.fix (self: {
        default = pkgs.python3Packages.callPackage
          (
            { buildPythonPackage, poetry-core, tshark, pyshark }:
            buildPythonPackage {
              src = ./.;
              pyproject = true;
              inherit pname version;
              ## build and dev environment
              nativeBuildInputs = [ poetry-core tshark.out ];
              propagatedBuildInputs = [ pyshark ];
            }
          )
          { };

        live-capture = pkgs.writeShellApplication {
          name = "wifipem-live-capture";
          runtimeInputs = with pkgs; [
            tshark.out
            gnugrep
            iproute2
            libcap # for `getcap` and `setcap`
            ## the system `sudo` may be used for priviledge escalation
            (python3.withPackages (python3Packages: [
              self.default
            ]))
          ];
          text = builtins.readFile ./live-capture.sh;
        };
      });
      packages = builtins.mapAttrs (system: mkPackage) systemsPkgs;
    in
    {
      inherit
        lib
        packages;

      ## for easy access in dev repl
      inherit (nixpkgs) legacyPackages;
    };
}
