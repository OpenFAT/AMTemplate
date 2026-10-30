-- Schemify config for this template (`schemify -u .flows/schemify/init.lua …`, which the
-- `SchemifySite` target in .flows/Makefile uses). `schemify pack sync` installs what it lists
-- and pins it in schemify-pack.lock beside this file.
--
-- interop imports the xschem blocks. It reads only the directories named here, each one an
-- environment variable the nix shell exports (.flows/env/Analog.nix): the blocks, xschem's
-- own library, and the PDK, whichever PDK $PDK_ROOT holds.
schemify.pack.add {
  {
    src = "https://github.com/OpenFAT/Interoperate",
    name = "interop",
    grant = {
      "read_project",
      "write_project",
      "read:ANALOG_ROOT",
      "read:XSCHEM_LIBRARY",
      "read:PDK_ROOT",
    },
    fuel = 100000000000,
  },
}
