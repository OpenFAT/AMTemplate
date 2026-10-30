ANALOG_LIB_REPO := https://github.com/UW-ASIC/AnalogLibrary.git
ANALOG_DIR := ../analog
DIGITAL_DIR := ../digital
TOP_DIR := ../top

HAS_ANALOG := $(shell [ -d "$(ANALOG_DIR)" ] && echo "1" || echo "0")
HAS_DIGITAL := $(shell [ -d "$(DIGITAL_DIR)" ] && echo "1" || echo "0")
HAS_TOP := $(shell [ -d "$(TOP_DIR)" ] && echo "1" || echo "0")
# top/ is output collected from the blocks, so it does not change the project type.
STATE_KEY := $(HAS_ANALOG)$(HAS_DIGITAL)
PROJECT_STATE := $(strip \
	$(if $(filter 00,$(STATE_KEY)),none, \
	$(if $(filter 11,$(STATE_KEY)),mixed, \
	$(if $(filter 01,$(STATE_KEY)),digital, \
	analog))))

include utility.mk

.PHONY: CreateProject AddAnalogBlock AddDigitalModule CreateTop DeleteAll status help _create_analog_block _create_digital_structure SchemifySite

help:
	@echo "Project Management Makefile"
	@echo "=========================="
	@echo "Current state: $(PROJECT_STATE)"
	@echo ""
	@echo "Project Creation:"
	@echo "  CreateProject PROJECT_NAME=name PROJECT_TYPE=<analog,digital,mixed>"
	@echo ""
	@echo "Module Addition:"
	@echo "  AddAnalogBlock BLOCK_NAME=name [DEPENDS=\"blk1 blk2\"]"
	@echo "  AddDigitalModule MODULE_NAME=name"
	@echo ""
	@echo "Top-level Integration (collects block outputs into top/):"
	@echo "  CreateTop PROJECT_NAME=name"
	@echo ""
	@echo "Schemify (online schematic viewer):"
	@echo "  SchemifySite - import every analog block, simulate its benches, build the site"
	@echo "                 in .tools/schemify-site (serve it: python3 -m http.server -d .tools/schemify-site)"
	@echo ""
	@echo "Utilities:"
	@echo "  status - Show current project state"
	@echo "  help - Show this message"

# Validation functions using Make's $(error) and $(if)
check-param = $(if $(value $(1)),,$(error $(1) is required. Usage: $(2)))
check-state = $(if $(filter $(PROJECT_STATE),$(1)),,$(error Invalid state '$(PROJECT_STATE)'. Expected: $(1)))
check-type = $(if $(filter $(PROJECT_TYPE),analog digital mixed),,$(error PROJECT_TYPE must be analog, digital, or mixed))
COMMA := ,

CreateProject:
	@echo "Creating Project: $(PROJECT_NAME)"
	$(call check-param,PROJECT_NAME,make CreateProject PROJECT_NAME=myproject PROJECT_TYPE=<analog|digital|mixed>)
	$(call check-param,PROJECT_TYPE,make CreateProject PROJECT_NAME=myproject PROJECT_TYPE=<analog|digital|mixed>)
	$(call check-state,none)
	$(call check-type)
	$(if $(filter analog mixed,$(PROJECT_TYPE)),$(MAKE) _create_analog_block BLOCK_NAME=$(PROJECT_NAME);)
	$(if $(filter digital mixed,$(PROJECT_TYPE)),$(MAKE) _create_digital_structure MODULE_NAME=$(PROJECT_NAME);)
	@echo "Project $(PROJECT_NAME) created successfully!"

AddAnalogBlock:
	@echo "Adding Analog Block: $(BLOCK_NAME)"
	$(call check-param,BLOCK_NAME,make AddAnalogBlock BLOCK_NAME=name [DEPENDS="a b"])
	$(if $(filter none,$(PROJECT_STATE)),$(error No project exists. Run CreateProject first))
	$(if $(filter digital,$(PROJECT_STATE)),$(error Cannot add analog blocks to a digital-only project))
	$(if $(wildcard $(ANALOG_DIR)/$(BLOCK_NAME)),$(error Block $(BLOCK_NAME) already exists))
	@for d in $(DEPENDS); do \
		[ -d "$(ANALOG_DIR)/$$d" ] || { echo "Dependency block '$$d' does not exist"; exit 1; }; \
	done
	@$(MAKE) _create_analog_block BLOCK_NAME=$(BLOCK_NAME) DEPENDS="$(DEPENDS)"
	@echo "Block $(BLOCK_NAME) added successfully!"

AddDigitalModule:
	@echo "Adding Digital Module: $(MODULE_NAME)"
	$(call check-param,MODULE_NAME,make AddDigitalModule MODULE_NAME=name)
	$(if $(filter none,$(PROJECT_STATE)),$(error No project exists. Run CreateProject first))
	$(if $(filter analog,$(PROJECT_STATE)),$(error Cannot add digital modules to analog-only project))
	$(if $(PARENT),$(if $(wildcard $(DIGITAL_DIR)/$(PARENT)),,$(error Parent module $(PARENT) not found)))
	@$(MAKE) _create_digital_structure MODULE_NAME=$(MODULE_NAME)
	@echo "Module $(MODULE_NAME) added successfully!"

CreateTop:
	@echo "Creating top-level integration directory"
	$(call check-param,PROJECT_NAME,make CreateTop PROJECT_NAME=myproject)
	$(if $(filter none,$(PROJECT_STATE)),$(error No project exists. Create a project first))
	@mkdir -p $(TOP_DIR)
	@cp -r top/* $(TOP_DIR)/ 2>/dev/null || true
	@sed -i 's/@PROJECT_NAME@/$(PROJECT_NAME)/g' $(TOP_DIR)/src/project.v
	$(if $(filter digital,$(PROJECT_STATE)),@rm -rf $(TOP_DIR)/{def$(COMMA)gds$(COMMA)lef};)
	$(if $(filter mixed digital,$(PROJECT_STATE)),\
		@mkdir -p $(TOP_DIR)/src $(TOP_DIR)/test; \
		for srcdir in $(DIGITAL_DIR)/*/src; do \
			[ -d "$$srcdir" ] && cp -r "$$srcdir"/* $(TOP_DIR)/src/ 2>/dev/null || true; \
		done; \
		for testdir in $(DIGITAL_DIR)/*/test; do \
			[ -d "$$testdir" ] && cp -r "$$testdir"/* $(TOP_DIR)/test/ 2>/dev/null || true; \
		done;)
	$(if $(filter analog mixed,$(PROJECT_STATE)),\
		@for blk in $(ANALOG_DIR)/*/; do \
			[ "$$(basename $$blk)" = "library" ] && continue; \
			[ -d "$$blk/output" ] || continue; \
			for kind in def gds lef; do \
				[ -d "$$blk/output/$$kind" ] && mkdir -p $(TOP_DIR)/$$kind && \
					cp -r "$$blk/output/$$kind"/* $(TOP_DIR)/$$kind/ 2>/dev/null || true; \
			done; \
		done;)
	@echo "Top project created successfully!"

DeleteAll:
	@echo "Deleting all project files..."
	@rm -rf $(ANALOG_DIR) $(DIGITAL_DIR) $(TOP_DIR)
	@echo "All project files deleted successfully!"

status:
	@echo "Project Status: $(PROJECT_STATE)"
	@echo ""
	@if [ "$(PROJECT_STATE)" = "none" ]; then \
		echo "No projects found."; \
		exit 0; \
	fi
	@echo "Modules:"
	@echo "=================="
	@$(MAKE) -s _status_analog
	@$(MAKE) -s _status_digital
	@echo ""
	@echo "Top Status:"
	@echo "=============="
	@$(MAKE) -s _status_top

# =======================================================================
# Schemify: every analog block online
# =======================================================================
#
# Each block is imported by the interop plugin (installed from schemify/init.lua) into its
# own Schemify project, its testbenches are simulated with ngspice, and `schemify publish`
# lays the projects out beside the web editor. The search path is the block's xschemrc one:
# its schematics and symbols, its DEPENDS blocks, analog/library, xschem's library, the PDK.
# `${NAME}` paths are the plugin's (`read:<NAME>` grants), so they stay single-quoted here.
SCHEMIFY := schemify -u $(CURDIR)/schemify/init.lua
SCHEMIFY_WORK ?= $(CURDIR)/../.tools/schemify
SCHEMIFY_SITE ?= $(CURDIR)/../.tools/schemify-site
# The web editor bundle: a flake output (Schemify's `web` package), or a directory already
# holding one (index.html + pkg/).
SCHEMIFY_WEB ?= github:OpenFAT/Schemify\#web

SchemifySite:
	$(call check-param,PDK_ROOT,run inside the nix shell (./env.sh))
	$(SCHEMIFY) pack sync
	@rm -rf $(SCHEMIFY_WORK) $(SCHEMIFY_SITE) && mkdir -p $(SCHEMIFY_WORK)
	@for blk in $(ANALOG_DIR)/*/; do \
		b=$$(basename $$blk); \
		[ "$$b" = library ] && continue; \
		[ -d "$$blk/schematics" ] || continue; \
		deps=$$(sed -n 's/^DEPENDS *= *//p' $$blk/build/config.mk 2>/dev/null); \
		roots=""; \
		for d in $$deps; do \
			roots="$$roots --root \$${ANALOG_ROOT}/$$d/schematics --root \$${ANALOG_ROOT}/$$d/symbols"; \
		done; \
		echo "=== $$b"; \
		mkdir -p $(SCHEMIFY_WORK)/$$b && printf 'schemify 1 project\n' > $(SCHEMIFY_WORK)/$$b/schemify.project; \
		$(SCHEMIFY) cmd $(SCHEMIFY_WORK)/$$b interop.xschem_import \
			"\$${ANALOG_ROOT}/$$b/schematics" "\$${ANALOG_ROOT}/$$b/symbols" $$roots \
			--root '$${ANALOG_ROOT}/library' --root '$${XSCHEM_LIBRARY}' \
			--root "\$${PDK_ROOT}/$$PDK/libs.tech/xschem" \
			--xschemrc "\$${PDK_ROOT}/$$PDK/libs.tech/xschem/xschemrc" -o . || exit 1; \
		(cd $(SCHEMIFY_WORK)/$$b && find . -name '*.shbench' | sort | while read -r bench; do \
			echo "--- $$bench"; $(SCHEMIFY) run "$$bench" || true; \
		done); \
	done
	$(SCHEMIFY) publish $(SCHEMIFY_WORK)/* -o $(SCHEMIFY_SITE)
	@web='$(SCHEMIFY_WEB)'; [ -d "$$web" ] || \
		web=$$(nix build --no-link --print-out-paths --extra-experimental-features 'nix-command flakes' "$$web"); \
	cp -r "$$web/." $(SCHEMIFY_SITE)
	@chmod -R u+w $(SCHEMIFY_SITE)
	@echo "Site: $(SCHEMIFY_SITE)/projects/ (python3 -m http.server -d $(SCHEMIFY_SITE))"

# =======================================================================
# Helper Functions
# =======================================================================

# Internal target to create one analog block.
#
# Blocks live at analog/<BLOCK_NAME>/, the same depth digital modules live at, so the two
# trees agree and a relative path means the same thing in both. Only library/ stays up at
# analog/: it is one clone shared by every block, and a copy per block is how copies drift.
_create_analog_block:
	@mkdir -p $(ANALOG_DIR)/$(BLOCK_NAME)/build \
		$(ANALOG_DIR)/$(BLOCK_NAME)/layout \
		$(ANALOG_DIR)/$(BLOCK_NAME)/schematics \
		$(ANALOG_DIR)/$(BLOCK_NAME)/symbols \
		$(ANALOG_DIR)/$(BLOCK_NAME)/netlist \
		$(ANALOG_DIR)/$(BLOCK_NAME)/va \
		$(ANALOG_DIR)/$(BLOCK_NAME)/test \
		$(ANALOG_DIR)/$(BLOCK_NAME)/output
	@if [ ! -d "$(ANALOG_DIR)/library" ]; then \
		mkdir -p $(ANALOG_DIR)/library && \
		git clone $(ANALOG_LIB_REPO) $(ANALOG_DIR)/library/; \
	fi
	@sed -e 's/@BLOCK_NAME@/$(BLOCK_NAME)/g' -e 's/@BLOCK_DEPENDS@/$(DEPENDS)/g' \
		analog/build/config.mk.template > $(ANALOG_DIR)/$(BLOCK_NAME)/build/config.mk
	@cd $(ANALOG_DIR)/$(BLOCK_NAME)/build && \
		mkdir -p layout schematic validation sim va && \
		cp -r ../../../.flows/analog/build/layout/* ./layout/ 2>/dev/null || true && \
		cp -r ../../../.flows/analog/build/schematic/* ./schematic/ 2>/dev/null || true && \
		cp -r ../../../.flows/analog/build/validation/* ./validation/ 2>/dev/null || true && \
		cp -r ../../../.flows/analog/build/sim/* ./sim/ 2>/dev/null || true && \
		cp -r ../../../.flows/analog/build/va/* ./va/ 2>/dev/null || true

# Internal target to create digital structure
_create_digital_structure:
	@mkdir -p $(DIGITAL_DIR)/$(MODULE_NAME)/build $(DIGITAL_DIR)/$(MODULE_NAME)/src $(DIGITAL_DIR)/$(MODULE_NAME)/test
	@sed 's/@MODULE_NAME@/$(MODULE_NAME)/g' digital/build/config.mk.template > $(DIGITAL_DIR)/$(MODULE_NAME)/build/config.mk
	@cd $(DIGITAL_DIR)/$(MODULE_NAME)/build && \
		mkdir -p des_tb lint synthesis verification && \
		cp -r ../../../.flows/digital/build/des_tb/* ./des_tb/ 2>/dev/null || true && \
		cp -r ../../../.flows/digital/build/lint/* ./lint/ 2>/dev/null || true && \
		cp -r ../../../.flows/digital/build/synthesis/* ./synthesis/ 2>/dev/null || true && \
		cp -r ../../../.flows/digital/build/verification/* ./verification/ 2>/dev/null || true
	@printf '%s\n' \
		'`default_nettype none' \
		'module $(MODULE_NAME)(' \
		'	input  wire       clk,' \
		'	input  wire       rst_n,    // active-low reset' \
		'	input  wire [7:0] data_in,' \
		'	output wire [7:0] data_out' \
		');' \
		'	assign data_out = data_in;' \
		'	// List all unused inputs to prevent warnings' \
		'	wire _unused = &{clk, rst_n, 1'\''b0};' \
		'endmodule' \
		> $(DIGITAL_DIR)/$(MODULE_NAME)/src/$(MODULE_NAME).v
	@touch $(DIGITAL_DIR)/$(MODULE_NAME)/test/{test_$(MODULE_NAME).py,tb_$(MODULE_NAME).v,requirements.txt}
	@printf 'pytest==8.3.4\ncocotb==1.9.2\n' > $(DIGITAL_DIR)/$(MODULE_NAME)/test/requirements.txt
