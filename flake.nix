{
  inputs.nixpkgs.url = "nixpkgs";

  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = lib.genAttrs supportedSystems;
      systemsPkgs = forAllSystems (system: nixpkgs.legacyPackages.${system});

      mkPackage = pkgs:
        let
          pyproject = lib.importTOML ./pyproject.toml;
          inherit (pyproject.tool.poetry) name version;
          pname = name;
        in
        {
          default = pkgs.python3Packages.callPackage
            (
              { buildPythonPackage, poetry-core, tshark, pyshark }:
              buildPythonPackage {
                src = ./.;
                pyproject = true;
                inherit pname version;
                nativeBuildInputs = [ poetry-core ];
                propagatedBuildInputs = [ tshark pyshark ];
              }
            )
            { };
        };
      packages = builtins.mapAttrs (system: mkPackage) systemsPkgs;
    in
    {
      inherit
        lib
        packages;
      inherit (nixpkgs) legacyPackages;
    };
}
