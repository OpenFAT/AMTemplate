include ../config.mk

# Enforce Nix Shell
ifndef IN_NIX_SHELL
  $(error This Makefile must be run inside the nix-shell environment. Run ./env.sh first to enter the nix-shell)
endif

# This directory holds the block's Schemify manifest (schemify.project) and plugins
# (project.lua). The manifest's `root ../..` makes the block directory the project, and its
# `place` rules write cells to ../../schematics/ and benches to ../../test/. A cell does not
# sit under the manifest, so every call names it with --project. Schemify draws and
# netlists, ESPice simulates; xschem is never called, it gets the cells through the
# interop plugin's export.
# --clean skips the user's init.lua and packages (a personal `schemify.sim` path would
# otherwise redirect the simulator); the project's own plugins still load.
SCHEMIFY = schemify --project . --clean
ESPICE = espice
NETLIST_DIR = ../../netlist
TOP_CELL = ../../schematics/$(TOP_SCHEMATIC).shcomp
# Plugin arguments are paths from the project root (the block directory). --trust trusts
# project.lua first, downloading any plugin it lists that is missing.
PLUGIN = $(SCHEMIFY) cmd --trust .

.PHONY: schematic spice lvs_netlist xschem clean netlist import deps

## schematic - open the top cell in the Schemify editor (the project, if it is not drawn yet)
schematic:
	@if [ -z "$$DISPLAY" ] && [ -z "$$WAYLAND_DISPLAY" ]; then \
		echo "No DISPLAY set — Schemify's editor is a GUI and will not start."; \
		echo "Over SSH use 'ssh -X'; under WSL make sure WSLg or an X server is running."; \
		exit 1; \
	fi
	$(SCHEMIFY) edit $(if $(wildcard $(TOP_CELL)),$(TOP_CELL),.)

## spice - run every netlist/*.spice deck through ESPice
spice:
	@ls $(NETLIST_DIR)/*.spice >/dev/null 2>&1 || { echo "No SPICE decks in $(NETLIST_DIR)/"; exit 0; }
	@for file in $(NETLIST_DIR)/*.spice; do \
		echo "Running simulation: $$file"; \
		$(ESPICE) -b "$$file" || exit 1; \
	done

## lvs_netlist - netlist the top cell to spice/$(TOP_SCHEMATIC).spice, the deck validation/ compares
# CDL, Schemify's LVS dialect: the top cell as a .SUBCKT with *.PININFO, no code blocks.
lvs_netlist:
	@[ -f $(TOP_CELL) ] || { echo "No top cell $(TOP_CELL) — draw it with 'make schematic'."; exit 1; }
	@mkdir -p spice
	$(SCHEMIFY) netlist $(TOP_CELL) --dialect cdl -o spice/$(TOP_SCHEMATIC).spice

## xschem - export every cell to xschem (.sch/.sym and an xschemrc fragment) in xschem/
xschem:
	@cells=$$(cd ../.. && ls schematics/*.shcomp test/*.shbench 2>/dev/null); \
	[ -n "$$cells" ] || { echo "No Schemify cells in ../../schematics/ or ../../test/."; exit 1; }; \
	$(PLUGIN) interop.xschem_export $$cells build/schematic/xschem
	@echo "Exported to xschem/ (report: xschem/xschem-export.report.md)"

# Run every DeSpice circuit under netlist/ and capture the deck it prints.
# The convention is deliberately "the script writes a netlist to stdout" rather than an
# API contract: it holds for `print(circuit)` and for `print(bench.netlist())` alike, so a
# testbench script and a plain circuit script are the same kind of thing to this Makefile.
netlist:
	@mkdir -p $(NETLIST_DIR)
	@found=0; for f in $(NETLIST_DIR)/*.py; do \
		[ -f "$$f" ] || continue; found=1; \
		out="$${f%.py}.spice"; \
		echo "Generating $$out"; \
		python3 "$$f" > "$$out" || { echo "  failed: $$f"; rm -f "$$out"; exit 1; }; \
	done; \
	if [ $$found -eq 0 ]; then echo "No .py circuits in $(NETLIST_DIR)/"; fi

# Place a deck with the cktimg plugin: netlist/<stem>.spice -> one .shcomp per .subckt and a
# .shbench for the top level. cktimg writes beside the deck, and `place` routes only bare
# names, so the deck is copied to the block root for the import: its cells then land where
# the manifest's `place` rules say (schematics/, test/). cktimg never overwrites a cell.
import:
	$(if $(NETLIST),,$(error Usage: make import NETLIST=<name>  # for $(NETLIST_DIR)/<name>.spice))
	@[ -f "$(NETLIST_DIR)/$(NETLIST).spice" ] || { \
		echo "No such deck: $(NETLIST_DIR)/$(NETLIST).spice"; \
		echo "Run 'make netlist' first if it comes from a DeSpice script."; exit 1; }
	cp $(NETLIST_DIR)/$(NETLIST).spice ../../$(NETLIST).spice
	$(PLUGIN) cktimg.import $(NETLIST).spice; s=$$?; rm -f ../../$(NETLIST).spice; exit $$s
	@echo "Cells in ../../schematics/, the bench in ../../test/ — open one with: make schematic TOP_SCHEMATIC=<cell>"

## deps - build the blocks this one is built from, in the order they are listed
#
# One level only, deliberately: a dependency that itself has dependencies builds them
# when you run this in that block. Recursing here would need cycle detection to avoid
# hanging on a mutual dependency, which is a lot of Makefile for a tree that is usually
# two deep. Run it per level, or say so and it becomes a real topological walk.
deps:
	@if [ -z "$(DEPENDS)" ]; then echo "$(BLOCK): no dependencies"; exit 0; fi
	@for d in $(DEPENDS); do \
		echo "=== building dependency: $$d ==="; \
		$(MAKE) -C ../../../$$d/build/va va || exit 1; \
		$(MAKE) -C ../../../$$d/build/schematic netlist || exit 1; \
	done
	@echo "$(BLOCK): dependencies built"

clean:
	@echo "Cleaning generated files..."
	@rm -rf ../../netlist/*.spice spice xschem
	@echo "Clean complete"