include ../config.mk

# Enforce Nix Shell
ifndef IN_NIX_SHELL
  $(error This Makefile must be run inside the nix-shell environment. Run ./env.sh first to enter the nix-shell)
endif

# Verilog-A gate.
#
# ESPice compiles a model itself from the `.hdl "<model>.va"` card a Schemify espice netlist
# carries, with VerA linked in, so there is no .osdi to build. What is left is the proof:
# `vera --check` parses, elaborates and type-checks the device each model generates, so a
# broken model fails here instead of mid-simulation. The stamp under checked/ makes an
# unchanged model free on the next run.
VERA = vera

VA_DIR = ../../va
CHECK_DIR = checked
VA_SRCS = $(wildcard $(VA_DIR)/*.va)
CHECKS = $(patsubst $(VA_DIR)/%.va,$(CHECK_DIR)/%.ok,$(VA_SRCS))

.PHONY: all va clean

all: va

## va - vera --check every ../../va/*.va
va: $(CHECKS)
	@if [ -z "$(VA_SRCS)" ]; then \
		echo "No .va models in $(VA_DIR)/ — nothing to check."; \
	else \
		echo "Verilog-A models check clean"; \
	fi

$(CHECK_DIR)/%.ok: $(VA_DIR)/%.va
	@mkdir -p $(CHECK_DIR)
	@echo "Checking $<"
	@$(VERA) --check -I $(VA_DIR) $<
	@touch $@

clean:
	@rm -rf $(CHECK_DIR)
	@echo "Clean complete"
