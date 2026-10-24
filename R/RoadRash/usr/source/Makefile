AMIGA_SHARE ?= $(HOME)/.local/share/amiga
VASM ?= $(HOME)/.local/vasmm68k_mot
VASMFLAGS = -quiet -devpac -nosym -Fhunkexe -pic -I"$(AMIGA_SHARE)/WHDLoad/Include" -I"$(AMIGA_SHARE)/WHDLoad/Src" -I"$(AMIGA_SHARE)/ndk/Include_I" -I.

.PHONY: all clean
all: RoadRash.slave

RoadRash.slave: $(wildcard *.s)
	"$(VASM)" $(VASMFLAGS) -o "$@" RoadRashHD.s

clean:
	rm -f RoadRash.slave
