{
  description = "devenv.cangjie";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-old.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-25.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-old, nixpkgs-25, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
    let
        pkgs = import nixpkgs { inherit system; };
        pkgs-old = import nixpkgs-old { inherit system; };
        pkgs-25 = import nixpkgs-25 { inherit system; };

        arch-cmd = pkgs.writeShellScriptBin "arch" ''
            uname -m
        '';
        sysroot = pkgs.symlinkJoin {
            name = "sysroot";
            paths = with pkgs; [
              glibc
              libgcc
              stdenv.cc.cc
            ];
          };
    in {
        devShells.default = pkgs.mkShell {
            hardeningDisable = [ "all" ];
            buildInputs = with pkgs; [
                git
                pkgs-old.llvmPackages_15.clang
                python3
                cmake
                ninja
                lldb
                clang-tools
                ccache
                
                libxcrypt
                openssl
                pcre2

                gtest
                libffi

                # cjdb
                ncurses
                libedit
                swig

                # for $(arch) in envsetup.sh
                arch-cmd
            ];
            
            CMAKE_CXX_COMPILER_LAUNCHER="${pkgs.ccache}/bin/ccache";
            CMAKE_C_COMPILER_LAUNCHER="${pkgs.ccache}/bin/ccache";
            # use correct glibc
            LIBRARY_PATH = "${sysroot}/lib";


            shellHook = ''
                echo "~~ cangjie dev ~~"
            '';
        };
    });
}
