PROGNAME = SkidMarks2
EXE=rebuild_track

all : $(PROGNAME).slave $(PROGNAME).islave $(EXE)

$(PROGNAME).slave : $(PROGNAME)HD.asm
	basm $?

$(PROGNAME).islave : $(PROGNAME).islave.s
	basm $?


OPT= -3.1

$(EXE): $(EXE).c
	dcc $(OPT) $(EXE).c

