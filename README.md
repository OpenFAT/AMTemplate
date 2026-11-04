# AMTemplate

A template for analog and mixed-signal ASIC design on open-source tools: automated
workflows for digital, analog and mixed-signal blocks, for any tapeout or standalone block.

Derived from the UWASIC TinyTapeout template.

## Project structure

The template itself is the flow; your design lives in directories the flow creates beside it.

```
AMtemplate/
├── env.sh           enter the nix shell every flow runs in
├── .flows/          the template: owns every Makefile, Nix environment and tool script
│   ├── Makefile     project targets (make -C .flows help)
│   ├── env/         shell.nix, Analog.nix, Digital.nix: the pinned tools
│   ├── analog/      per-block flow, copied into each analog block
│   ├── digital/     per-module flow, copied into each digital module
│   └── top/         tapeout skeleton CreateTop starts from
├── docs/            user documentation (bun run dev)
├── analog/          created by CreateProject / AddAnalogBlock
├── digital/         created by CreateProject / AddDigitalModule
└── top/             created by CreateTop
```

`make -C .flows CreateProject PROJECT_NAME=amp PROJECT_TYPE=<analog|digital|mixed>`
creates the first block or module. More are added with `AddAnalogBlock` and
`AddDigitalModule`. A flow fix lands in `.flows/` and never in a copied `build/` directory.

### Analog block: `analog/<block>/`

Each block is a [Schemify](https://github.com/OpenFAT/Schemify) project. Its manifest sits in
`build/schematic/` and says `root ../..`, so the block directory is the project: cells go to
`schematics/` and testbenches to `test/` by the manifest's `place` rules.

```
analog/
├── library/              UW-ASIC AnalogLibrary, one clone shared by every block
└── <block>/
    ├── schematics/       Schemify cells (.shcomp, .shprim)
    ├── test/             testbenches (.shbench, tb_*.shcomp)
    ├── netlist/          SPICE decks; `make import` places one as a schematic
    ├── va/               Verilog-A models
    ├── layout/           Magic / KLayout layout
    ├── output/           def/, gds/, lef/: what CreateTop collects
    └── build/
        ├── config.mk     block settings: DEPENDS, BACKEND, layout outline
        ├── schematic/    schemify edit, ESPice, cktimg import, xschem export, LVS netlist
        │   ├── schemify.project  manifest: root, libraries (own + DEPENDS schematics/), place rules
        │   ├── project.lua       plugins: interop, cktimg, pdk-manager, schemify-themes
        │   └── .schemify/        generated: plugins, netlists, runs (git-ignored)
        ├── sim/          schemify run on every test/*.shbench (ESPice by default)
        ├── va/           vera --check on every model
        ├── layout/       layout outline and place-and-route
        └── validation/   DRC and LVS
```

Each step is `make -C analog/<block>/build/<step> <target>`.

### Digital module: `digital/<module>/`

```
digital/<module>/
├── src/<module>.v        RTL
├── test/                 cocotb test, Verilog testbench, requirements.txt
└── build/
    ├── config.mk
    ├── lint/             make lint
    ├── verification/     make verification
    ├── des_tb/           Verilator RTL simulation (make test-rtl)
    └── synthesis/        OpenLane hardening
```

### Tapeout: `top/`

`CreateTop` copies every digital module's `src/` and `test/`, and every analog block's
`output/{def,gds,lef}`, into `top/`.

## Documentation

**Full documentation is available in the [`docs/`](./docs) directory.**

Please refer to the documentation for:

- [Environment Setup](./docs/src/content/Environment)
- [Digital Workflow](./docs/src/content/Flows/Digital.ts)
- [Analog Workflow](./docs/src/content/Flows/Analog.ts)
- [Mixed-Signal Workflow](./docs/src/content/Flows/Mixed-Signal.ts)

### Quick Start Docs

To view the documentation locally:

```bash
cd docs/
bun install
bun run dev
```
