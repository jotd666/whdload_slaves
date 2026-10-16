include ../../options.mk

PROGNAME = PrinceOfPersia


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s


.PHONY: all verify
all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE)
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)

DEPS = PrinceOfPersiaFast.s PrinceOfPersiaVersions.i PrinceOfPersiaVersions.s \
       PrinceOfPersiaVerify.s ReadJoypad.s savegame.s xen_8.bin

$(WHDLOADER): $(SOURCE) $(DEPS)
	$(VASM) $(ASMFLAGS) -o $@ $(SOURCE)

verify: $(PROGNAME)-verify.slave

$(PROGNAME)-verify.slave: $(SOURCE) $(DEPS)
	$(VASM) $(ASMFLAGS) -DVERIFY -o $@ $(SOURCE)
