{
  description = "cli application for fetching and reading light novels";

  inputs = {
    # Core and Infrastructure Inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    # Python Environment Inputs
    # https://github.com/pyproject-nix/uv2nix/tree/master/templates/hello-world
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, systems, uv2nix, pyproject-nix
    , pyproject-build-systems, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import systems;
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          inherit (nixpkgs) lib;
          workspace =
            uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

          overlay =
            workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };

          pyprojectOverrides = _final: _prev:
            {
              # - https://pyproject-nix.github.io/uv2nix/FAQ.html
              # Implement build fixups here.
            };

          # Use Python 3.12 from nixpkgs
          python = pkgs.python312;

          # Construct package set
          pythonSet = (pkgs.callPackage pyproject-nix.build.packages {
            inherit python;
          }).overrideScope (lib.composeManyExtensions [
            pyproject-build-systems.overlays.default
            overlay
            pyprojectOverrides
          ]);

        in {
          packages.default =
            pythonSet.mkVirtualEnv "novels-env" workspace.deps.default;

          # Make novels runnable with `nix run`
          apps.${system} = {
            default = {
              type = "app";
              program = "${self.packages.${system}.default}/bin/novels";
            };
          };

          devShells = {
            default = pkgs.mkShell {
              packages = [ python pkgs.uv ];
              env = {
                # Prevent uv from managing Python downloads
                UV_PYTHON_DOWNLOADS = "never";
                # Force uv to use nixpkgs Python interpreter
                UV_PYTHON = python.interpreter;
              } // lib.optionalAttrs pkgs.stdenv.isLinux {
                # Python libraries often load native shared objects using dlopen(3).
                # Setting LD_LIBRARY_PATH makes the dynamic library loader aware of libraries without using RPATH for lookup.
                LD_LIBRARY_PATH =
                  lib.makeLibraryPath pkgs.pythonManylinuxPackages.manylinux1;
              };
              shellHook = ''
                unset PYTHONPATH
              '';
            };
          };
        };
    };
}
