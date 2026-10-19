# vasm build with the shared WHDLoad 20.0 SDK and NDK (override as needed).
WHDLOAD ?= $(HOME)/.local/share/amiga/WHDLoad
NDK ?= $(HOME)/.local/share/amiga/ndk/Include_I
VASM ?= $(HOME)/.local/vasmm68k_mot
VASMFLAGS ?=
OUTDIR ?= .
INCDIR = $(OUTDIR)/include
SOURCE = GrandPrixCircuitHD.s

.PHONY: all clean
all: OUTPUT = GrandPrixCircuit.slave
# Phony targets always rebuild when flags change and allow spaces in OUTDIR.
all: $(SOURCE) render.s render-subunit.s simulation.s
	mkdir -p "$(OUTDIR)" "$(INCDIR)/lvo"
	@for lib in dos exec graphics expansion; do \
	  printf ' IFND GPC_LVO_%s\nGPC_LVO_%s SET 1\n INCLUDE "lvo/%s_lib.i"\n ENDC\n' $$lib $$lib $$lib > "$(INCDIR)/lvo/$$lib.i"; \
	done
	"$(VASM)" -m68000 -pic -x -devpac -Fhunkexe -nosym $(VASMFLAGS) -I"$(INCDIR)" -I"$(WHDLOAD)/Include" -I"$(WHDLOAD)/Src/sources" -I"$(NDK)" -L "$(OUTDIR)/$(OUTPUT).lst" -o "$(OUTDIR)/$(OUTPUT)" $(SOURCE)

clean:
	rm -f "$(OUTDIR)/GrandPrixCircuit.slave" "$(OUTDIR)/GrandPrixCircuit.slave.lst"
