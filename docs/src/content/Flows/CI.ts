export const metadata = {
    title: "CI/CD Workflows",
    order: 5
}

export const content = `
# CI/CD Workflows

**Push. Build. Verify.**

## Automatic Detection
On every push to \`analog/\`, \`digital/\` or \`caravel/\`, the CI detects your project type:

| Directories | Type | Workflows |
|-------------|------|-----------|
| \`digital/\` | digital | test, GDS |
| \`analog/\` | analog | none (deploy-docs publishes the viewer) |
| Both | mixed | test, GDS |

\`lint.yaml\` runs on every push regardless.

## Workflows

### test.yaml
Runs Verilator + Cocotb for each module in \`digital/\`.

- Auto-discovers modules with \`build/verification/Makefile\`
- Runs in parallel per module
- Uploads VCD waveforms as artifacts

### gds.yaml
Hardens each module in \`digital/\` with OpenLane 2 (\`make harden\`) inside the nix shell and uploads the run, GDS included. The die comes from \`DIE_AREA\` or \`DEF_TEMPLATE\` in the module's \`build/config.mk\`.

### deploy-docs.yaml
Builds this docs site and publishes it to GitHub Pages.

### schemify.yaml
Publishes every block in \`analog/\` to the docs site at \`/schemify/\`, so anyone can browse the schematics without installing xschem.

- Converts each block's xschem \`schematics/\` and \`symbols/\` (plus its \`DEPENDS\` blocks) to [Schemify](https://github.com/OpenFAT/Schemify)
- Simulates every testbench with ngspice and sky130 (\`<bench>.shbench.results.txt\` next to each bench)
- Opens each block in Schemify's browser editor: view, edit, netlist. The browser cannot simulate yet; CI does that on push
- Runs on push to \`main\` touching \`analog/**\`, through \`deploy-docs.yaml\`

## Triggers
- **Auto**: Push to \`analog/**\`, \`digital/**\`, \`caravel/**\` or \`.github/workflows/**\`; push to \`main\` touching \`analog/**\` or \`docs/**\` redeploys the docs and the schematic viewer
- **Manual**: Workflow dispatch from Actions tab
`
