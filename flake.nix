{
  inputs.nixpkgs.url = "nixpkgs";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      allPackages = forAllSystems (system: nixpkgs.legacyPackages.${system});
    in
    {
      packages = builtins.mapAttrs (system: pkgs: {
        default = pkgs.stdenvNoCC.mkDerivation {
          pname = "wifipem";
          version = "0.1.0";
          buildInputs = with pkgs; [
            tshark
            (python3.withPackages (pythonPkgs: with pythonPkgs; [
              pyshark
            ]))
          ];
          src = ./.;
          postBuild = "touch $out";
        };
      }) allPackages;
    };
}
