-- The plugins every analog block's Schemify project uses. `schemify cmd --trust` (what the
-- block's Makefiles run) or the editor's trust dialog downloads what is missing into
-- .schemify/pack/ and pins it in schemify-pack.lock beside this file; commit that lock.
--
-- interop: xschem co-operation, `make -C build/schematic xschem` exports the cells.
-- cktimg: a SPICE deck to a placed schematic, `make -C build/schematic import`.
-- pdk-manager: `pdk.install`/`pdk.use` put a PDK's devices and models in the project.
-- schemify-themes: editor colour themes.
schemify.pack.add {
  {
    src = "https://github.com/OpenFAT/Interoperate",
    name = "interop",
    grant = { "read_project", "write_project" },
    fuel = 100000000000,
  },
  {
    src = "https://github.com/OpenFAT/cktImg",
    name = "cktimg",
    grant = { "read_project", "write_project" },
    fuel = 100000000000,
  },
  {
    src = "https://github.com/OpenFAT/PDK-Manager",
    name = "pdk-manager",
    grant = {
      "read_project", "write_project",
      "spawn:ciel", "spawn:schemify-interop", -- sky130, gf180mcu, ihp-sg13g2
      "spawn:git", -- asap7
      "spawn:curl", "spawn:tar", -- freepdk45
    },
  },
  {
    src = "https://github.com/OpenFAT/Schemify-Themes",
    name = "schemify-themes",
  },
}
