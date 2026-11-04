export const metadata = {
    title: "Analog Flow",
    order: 3
}

export const content = `
# Analog Flow

**Schematic. Layout. Simulate.**

## 1. Create Project
Initialize the analog workspace.

\`\`\`bash
make CreateProject PROJECT_NAME=my_amp PROJECT_TYPE=analog
\`\`\`

## 2. Structure
*   \`schematics/\`: **Circuit Design**. Schemify cells (\`.shcomp\`).
*   \`test/\`: **Testbenches** (\`.shbench\`).
*   \`build/schematic/\`: the block's Schemify manifest (\`schemify.project\`, \`root ../..\`) and \`project.lua\` (its plugins).
*   \`layout/\`: **Physical Design**. KLayout/Magic files (\`.gds\`, \`.mag\`).
*   \`build/\`: **Work Area**. Makefiles for tools.

## 3. Schematic Design
Draw your circuit in Schemify.

\`\`\`bash
cd analog/my_amp/build/schematic
make schematic
\`\`\`

*   **Simulate**: \`make -C ../sim\` (runs every \`.shbench\` on ESPice); \`make spice\` runs ESPice on \`netlist/*.spice\`.
*   **Netlist to schematic**: \`make import NETLIST=<name>\` (the cktimg plugin).
*   **xschem**: \`make xschem\` exports every cell to \`xschem/\` (the interop plugin).
*   **Verilog-A**: \`make -C ../va\` checks every \`va/*.va\` with VerA.

## 4. Layout Design
Draw your layout in KLayout.

\`\`\`bash
cd .flows/analog/build/layout
make layout
\`\`\`

*   **Initialize**: \`make init_layout\` (Creates the cell outline and pins from \`DIE_AREA\`/\`PINS\` in \`build/config.mk\`, or from your \`DEF_TEMPLATE\`).
*   **Convert**: \`make mag2gds\` (Converts Magic files to GDSII).

## 5. Validation
Run DRC and LVS to ensure your layout matches your schematic and rules.

\`\`\`bash
cd .flows/analog/build/validation
make drc
make lvs
\`\`\`
`
