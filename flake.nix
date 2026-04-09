{
  description = "devenv.cangjie";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-old.url = "github:nixos/nixpkgs/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-old, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
    let
        pkgs = import nixpkgs { inherit system; };
        pkgs-old = import nixpkgs-old { inherit system; };

        clang15 = pkgs-old.llvmPackages_15.clang;

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

                jdk17

                # for $(arch) in envsetup.sh
                arch-cmd
            ];

            CC = "${clang15}/bin/clang";
            CXX = "${clang15}/bin/clang++";
            
            CMAKE_CXX_COMPILER_LAUNCHER="${pkgs.ccache}/bin/ccache";
            CMAKE_C_COMPILER_LAUNCHER="${pkgs.ccache}/bin/ccache";
            # use correct glibc
            LIBRARY_PATH = "${sysroot}/lib";
            GNU_LD = "${sysroot}/lib/ld-linux-x86-64.so.2";
            GNU_TOOLCHAIN = "${sysroot}";

            shellHook = ''
                echo "~~ cangjie dev ~~"
            '';
        };
    });
}
