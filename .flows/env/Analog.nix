{
  pkgs,
  schemify,
  espice,
  vera,
}:
let
  # The shared-library build of ngspice. The Rust analog crates link against it, which
  # plain `ngspice` (a binary only) cannot satisfy.
  ngspiceShared = pkgs.libngspice;

  # Hands KLayout a pandas for its interpreter since SKY130 PDK's KLayout macros import
  # pandas but KLayout runs its own embedded Python different from the shell's. KLayout
  # ignores PYTHONPATH; KLAYOUT_PYTHONPATH is the variable it reads.
  klayoutPython = pkgs.python3.withPackages (ps: [ ps.pandas ]);
  klayout = pkgs.symlinkJoin {
    name = "klayout-with-pandas";
    paths = [ pkgs.klayout ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/klayout \
        --prefix KLAYOUT_PYTHONPATH : ${klayoutPython}/${pkgs.python3.sitePackages}
    '';
  };
in
{
  packages = [
    # EDA tools, straight from nixpkgs. xschem and ngspice stay for cross-checks; the flow
    # calls Schemify and ESPice instead.
    pkgs.xschem
    # Wrapped version of pkgs.klayout defined above
    klayout
    ngspiceShared
    pkgs.ngspice
    pkgs.magic-vlsi

    # Schemify: `schemify` and its editor `schemify-gui`. Its plugins (interop for xschem,
    # cktimg) come from each block's project.lua; the web editor bundle is built on demand
    # by `make -C .flows SchemifySite`.
    schemify.packages.${pkgs.system}.schemify

    # ESPice built from source (it has no release binaries yet); VerA's newest release
    # binary. Both wrap the Zig they compile Verilog-A device code with.
    espice.packages.${pkgs.system}.espice
    vera.packages.${pkgs.system}.latest

    # Rust toolchain from nixpkgs
    pkgs.cargo
    pkgs.rustc
    pkgs.rust-analyzer
    pkgs.rustfmt
    pkgs.clippy
  ];
  shellHook = ''
    # === Analog Tools Configuration ===
    export BINDGEN_EXTRA_CLANG_ARGS="-I${ngspiceShared}/include $BINDGEN_EXTRA_CLANG_ARGS"
    export CPATH="${ngspiceShared}/include:$CPATH"
    export NIX_LD_LIBRARY_PATH="${ngspiceShared}/lib:$NIX_LD_LIBRARY_PATH"
    export PKG_CONFIG_PATH="${ngspiceShared}/lib/pkgconfig:$PKG_CONFIG_PATH"
    export KLAYOUT_PATH="$PDK_ROOT/$PDK/libs.tech/klayout"
    export XSCHEM_USER_LIBRARY_PATH="$PDK_ROOT/$PDK/libs.tech/xschem"
    export XSCHEM_LIBRARY_PATH="$PDK_ROOT/$PDK/libs.tech/xschem:${pkgs.xschem}/share/xschem/xschem_library"

    # === Rust Build Config ===
    export LIBCLANG_PATH="${pkgs.llvmPackages.libclang.lib}/lib"
    export BINDGEN_EXTRA_CLANG_ARGS="-I${pkgs.glibc.dev}/include $BINDGEN_EXTRA_CLANG_ARGS"
    export CPATH="${pkgs.python312}/include/python3.12:$CPATH"
    export NIX_LD_LIBRARY_PATH="${pkgs.python312}/lib:$NIX_LD_LIBRARY_PATH"

    pip install maturin pytest
    for pkg in analog/library/dep_library/gmid analog/library/dep_library/UWASIC-ALG; do
        if [ -d "$PROJECT_ROOT/$pkg" ]; then
            echo "Installing editable package: $pkg"
            python -m pip install -e "$PROJECT_ROOT/$pkg"
        fi
    done
  '';
}
