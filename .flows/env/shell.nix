{
  type ? "mixed",
  # nixos-25.11, pinned by commit and content hash.
  pkgs ?
    import (builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/b6018f87da91d19d0ab4cf979885689b469cdd41.tar.gz";
      sha256 = "0ln4yw7z3g9lb0x081hc0pd2j1wsx2qqf6bgmwwvdbkcl4bcy1dp";
    }) { },
}:
let
  # Every flake is pinned by commit (each one's flake.lock pins its own inputs). Bump a
  # rev here, never drop it: an unpinned flake reaches every project the moment it lands.
  # Schemify: the schematic editor each analog block is a project of, and the online
  # viewer's tools (`make -C .flows SchemifySite`). Its plugins come from each block's
  # project.lua, never from here.
  schemify = builtins.getFlake "github:OpenFAT/Schemify/3ccd6a308f2d0351318a5110d4919f2013508a0a";
  # ESPice: the SPICE simulator (`BACKEND = espice`). VerA: the Verilog-A compiler ESPice's
  # models come through.
  espice = builtins.getFlake "github:OpenFAT/ESPice/39aa1823c6421cf2cdc5689d24c8ecd0e468f1dc";
  vera = builtins.getFlake "github:OpenFAT/VerA/d26fe7f1144d2e0fbcff4a3618adadc2f794454b";
  # VLSI netgen for LVS, which nixpkgs lacks (`pkgs.netgen` is an unrelated mesh generator).
  # Cached at https://nix-cache.fossi-foundation.org; without that substituter it compiles.
  nixEda = builtins.getFlake "github:fossi-foundation/nix-eda/8375faf1454a0ba007ad0d810bd59f3bf05a1e6a";
  analog = import ./Analog.nix { inherit pkgs schemify espice vera nixEda; };
  digital = import ./Digital.nix { inherit pkgs; };

  useAnalog = type == "analog" || type == "mixed";
  useDigital = type == "digital" || type == "mixed";

  commonPackages = with pkgs; [
    # Builds
    gnumake
    git
    gh
    python312
    ccache

    # C compilation dependencies
    gcc
    clang
    llvmPackages.libclang
    libffi.dev
    fftw

    # Python deps
    python312Packages.pip
    python312Packages.numpy
    python312Packages.setuptools
    python312Packages.wheel

    # Graphics/GUI support
    xorg.libX11
    xorg.libXpm
    xorg.libXt
    cairo
    xterm
    xorg.fontutil
    xorg.fontmiscmisc
    xorg.fontcursormisc
    dejavu_fonts
    liberation_ttf
    inkscape
    vim

    # Viewing docs locally
    bun
  ];

in
pkgs.mkShell {
  name = "eda-env";

  buildInputs =
    commonPackages
    ++ (if useAnalog then analog.packages else [ ])
    ++ (if useDigital then digital.packages else [ ]);

  env = {
    NIX_ENFORCE_PURITY = "0";
  };

  shellHook = ''
    export PROJECT_ROOT="$(pwd)"

    # === Environment Variables Setup ===
    export CC="ccache gcc"
    export CXX="ccache g++"
    export CCACHE_DIR="$PROJECT_ROOT/.tools/ccache"

    # === PDK Configuration ===
    export PDK="sky130A"
    export PDK_VERSION="fa87f8f4bbcc7255b6f0c0fb506960f531ae2392"
    export PDK_ROOT="$HOME/.volare"

    # === Python Dependencies Installation ===
    export VENV_DIR="$PROJECT_ROOT/.venv"
    if [ -z "$VIRTUAL_ENV" ] || [ "$VIRTUAL_ENV" != "$VENV_DIR" ]; then
      if [ ! -d "$VENV_DIR" ]; then
        echo "Creating Python virtual environment..."
        python3 -m venv "$VENV_DIR"
      fi
      source "$VENV_DIR/bin/activate"
    fi

    # === PDK SETUP WITH VOLARE ===
    pip install --upgrade pip==24.2 setuptools==75.1.0 wheel==0.44.0 >/dev/null 2>&1
    pip install volare==0.20.6  >/dev/null 2>&1 || true

    if [ -d "$PDK_ROOT/volare/sky130/versions" ]; then
      echo "Cleaning up old PDK versions (keeping $PDK_VERSION)..."
      cd "$PDK_ROOT/volare/sky130/versions"
      find . -maxdepth 1 -mindepth 1 -type d ! -name "$PDK_VERSION" -exec echo "  Removing old version: {}" \; -exec rm -rf {} \;
      if [ ! -d "$PDK_ROOT/$PDK" ]; then
        echo "  Removing potentially invalid cache link: ~/.volare"
        rm -rf "$HOME/.volare"
      fi
      cd "$PROJECT_ROOT"
    fi

    # Enable the PDK with volare
    volare enable --pdk sky130 "$PDK_VERSION"

    # === Mode Specific Hooks ===
    ${if useAnalog then analog.shellHook else ""}
    ${if useDigital then digital.shellHook else ""}

    echo "=== EDA Environment ==="
    echo "Mode: ${type}"
    echo ""
    echo "System tools available:"
    echo "  - Python: $(python --version)"

    if [ "${type}" = "analog" ] || [ "${type}" = "mixed" ]; then
      echo "  - xschem: $(xschem --version 2>/dev/null | head -n 1 || echo 'custom build')"
      echo "  - magic: $(magic --version 2>/dev/null || echo 'from nixpkgs')"
      echo "  - espice: $(command -v espice >/dev/null && echo ok || echo 'not found')"
      echo "  - vera: $(command -v vera >/dev/null && echo ok || echo 'not found')"
      echo "  - schemify: $(command -v schemify >/dev/null && echo ok || echo 'not found')"
    fi

    if [ "${type}" = "digital" ] || [ "${type}" = "mixed" ]; then
      echo "  - yosys: $(yosys -V 2>/dev/null | head -1 || echo 'not found')"
      echo "  - verilator: $(verilator --version 2>/dev/null | head -1 || echo 'not found')"
      echo "  - openroad: $(openroad -version 2>/dev/null | head -1 || echo 'not found')"
      echo "  - openlane: $(openlane --version 2>/dev/null || echo 'not found')"
    fi

    echo "  - PDK: $PDK in $PDK_ROOT"
    echo ""
  '';
}
