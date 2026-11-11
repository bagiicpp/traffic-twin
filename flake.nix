{
  description = "TrafficTwin ML development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          python313
          uv
          gcc
          stdenv.cc.cc.lib
          zlib
          glib
          libffi
          openssl
          fish
        ];

        shellHook = ''
          export NIX_LD_LIBRARY_PATH="${
            pkgs.lib.makeLibraryPath [
              pkgs.stdenv.cc.cc.lib
              pkgs.zlib
              pkgs.glib
              pkgs.libffi
              pkgs.openssl
            ]
          }"

          export LD_LIBRARY_PATH="$NIX_LD_LIBRARY_PATH"

          export BROWSER="${pkgs.writeShellScript "jupyter-browser" ''
            unset LD_LIBRARY_PATH
            exec zen "$@"
          ''}"

          echo "TrafficTwin ML environment ready"
        '';
      };
    };
}
