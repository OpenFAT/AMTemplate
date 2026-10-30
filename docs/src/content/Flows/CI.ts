export const metadata = {
    title: "CI/CD Workflows",
    order: 5
}

export const content = `
# CI/CD Workflows

**Push. Build. Verify.**

## Automatic Detection
On every push to \`analog/\`, \`digital/\` or \`top/\`, the CI detects your project type:

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

## Triggers
- **Auto**: Push to \`analog/**\`, \`digital/**\`, \`top/**\` or \`.github/workflows/**\`; push to \`main\` touching \`docs/**\` redeploys the docs
- **Manual**: Workflow dispatch from Actions tab
`
