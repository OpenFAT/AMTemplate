include ../config.mk

# Enforce Nix Shell
ifndef IN_NIX_SHELL
  $(error This Makefile must be run inside the nix-shell environment. Run ./env.sh first to enter the nix-shell)
endif

# Run the block's Schemify benches.
#
# A testbench is a .shbench anywhere in the block (test/ by convention). `schemify run`
# netlists it in BACKEND's dialect and simulates every corner and sweep it names; the runs
# land in analog/<block>/.schemify/runs/. A bench's Verilog-A goes in as `.hdl "<model>.va"`
# under espice, which compiles it itself (VerA linked in), so build/va has nothing to hand
# over. Sizing loops (gm/Id, optimisers) are bench sweeps or plugins, not a target here.

SCHEMIFY = schemify
BENCHES = $(shell find ../.. -name '*.shbench' -not -path '*/.schemify/*' -not -path '*/build/*' | sort)

.PHONY: all sim test list clean

all: sim

## sim - run every .shbench in the block on BACKEND
sim: test

test:
	@if [ -z "$(BENCHES)" ]; then echo "No .shbench in this block."; exit 0; fi
	@for b in $(BENCHES); do \
		echo "=== $$b (backend: $(BACKEND)) ==="; \
		$(SCHEMIFY) run --dialect $(BACKEND) "$$b" || exit 1; \
	done

## list - which simulators this environment can actually reach
list:
	@echo "BACKEND = $(BACKEND)"
	@for s in schemify espice vera ngspice; do \
		if command -v $$s >/dev/null 2>&1; then echo "  $$s: available"; \
		else echo "  $$s: not on PATH"; fi; \
	done

clean:
	@rm -rf ../../.schemify/runs
	@echo "Clean complete"
