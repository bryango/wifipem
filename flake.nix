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
            tcpdump
            (python3.withPackages (python3Packages: with python3Packages; [
              pyshark
              (let name = "kamene"; in buildPythonPackage {
                inherit name;
                src = fetchFromGitHub {
                  owner = "phaethon";
                  repo = name;
                  rev = "master";
                  hash = "sha256-fZJxNZuk48T1w93ltBuUBaPqtzMsRpxFhjPCW18TE8s=";
                };
                doCheck = false;
              })
            ]))
          ];
          src = ./.;
          postBuild = "touch $out";
        };
      }) allPackages;
    };
}
