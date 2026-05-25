# Freya — developer tasks.
#
# Default runner is SBCL (the open dev/CI reference). AllegroCL is the deployment
# target (ADR-0011); run the same scripts with: alisp -L scripts/<x>.lisp -- ARGS
#
# Usage:
#   make checked         # load + strict type/perf gate (checked profile)
#   make test            # run the test suite (checked profile)
#   make release         # load + strict gate (release profile)
#   make release-test    # run tests in the release profile
#   make telemetry-test  # run tests with :freya-telemetry enabled
#   make clean           # drop the fasl cache

SBCL ?= sbcl
SCRIPT = $(SBCL) --script

.PHONY: checked release test release-test telemetry-test all clean

all: checked test

checked:
	$(SCRIPT) scripts/build.lisp strict

release:
	$(SCRIPT) scripts/build.lisp release strict

test:
	$(SCRIPT) scripts/test.lisp

release-test:
	$(SCRIPT) scripts/test.lisp release

telemetry-test:
	$(SCRIPT) scripts/test.lisp telemetry

clean:
	rm -rf $(HOME)/.cache/common-lisp .cache
