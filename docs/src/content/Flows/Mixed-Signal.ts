export const metadata = {
    title: "Mixed-Signal Flow",
    order: 4
}

export const content = `
# Mixed-Signal Flow

**Best of both worlds.**

## 1. Create Project
Initialize a workspace with both analog and digital capabilities.

\`\`\`bash
make CreateProject PROJECT_NAME=my_mixed_chip PROJECT_TYPE=mixed
\`\`\`

## 2. Structure
You get complete environments for both domains:

*   \`analog/\`: **Analog Core**. Schematics and Layouts.
*   \`digital/\`: **Digital Logic**. Verilog and Cocotb tests.

## 3. Workflow
1.  **Digital Design**: Build and verify your digital blocks in \`digital/\`.
2.  **Analog Design**: Build your analog circuits in \`analog/\`.
3.  **Integration**:
    *   Harden digital blocks to GDS.
    *   Import digital GDS into the analog layout (or vice-versa).
    *   Connect them at the top level.

## 4. Top-Level Strategy
The tapeout needs one top-level wrapper. \`make CreateCaravel PROJECT_NAME=<top>\` collects every block's outputs into \`caravel/\` and writes \`caravel/src/project.v\`, a module named \`<top>\`. Pick a name no block already uses.

*   **Digital Top**: Instantiate analog macros as blackboxes in Verilog.
*   **Analog Top**: Use the analog wrapper and place digital blocks as macros.
*   **Pins**: Declare them as ports of the wrapper. Each block's die size and pins come from its \`build/config.mk\` (\`DIE_AREA\`, \`PINS\`), or from a DEF you were given (\`DEF_TEMPLATE\`).
`
