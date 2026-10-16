# Build with vasm and the WHDLoad/Amiga NDK include directories:
# make WHDLOAD=/path/to/WHDLoad NDK=/path/to/ndk
VASM ?= vasmm68k_mot
PROGNAME = PrinceOfPersia
WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s
DEPS = PrinceOfPersiaFast.s PrinceOfPersiaVersions.i PrinceOfPersiaVersions.s \
       PrinceOfPersiaVerify.s ReadJoypad.s savegame.s xen_8.bin
ASMFLAGS = -quiet -devpac -nosym -Fhunkexe -pic \
           -I$(WHDLOAD)/Include -I$(WHDLOAD)/Src -I$(NDK)/Include_I -I.

.PHONY: all verify
all: $(WHDLOADER)

$(WHDLOADER): $(SOURCE) $(DEPS)
	$(VASM) $(ASMFLAGS) -o $@ $(SOURCE)

verify: $(PROGNAME)-verify.slave

$(PROGNAME)-verify.slave: $(SOURCE) $(DEPS)
	$(VASM) $(ASMFLAGS) -DVERIFY -o $@ $(SOURCE)
