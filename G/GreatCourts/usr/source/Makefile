PROGNAME = GreatCourtsHD
RIPPERNAME = gc2file

all : GreatCourts.slave GreatCourts.islave

GreatCourts.slave: $(PROGNAME).asm
	basm $(PROGNAME).asm

GreatCourts.islave: GreatCourts.islave.s
	basm GreatCourts.islave.s

$(PROGNAME) : $(PROGNAME).asm
	phxass $(PROGNAME).asm I=include:


$(RIPPERNAME): $(RIPPERNAME).o decode.o
	slink FROM LIB:c.o "$(RIPPERNAME).o"+"jst:objs/readdostrack.o"+"decode.o" TO "$(RIPPERNAME)" LIB lib:sc.lib lib:amiga.lib


decode.o : decode.asm
	phxass decode.asm NOEXE I=include:


$(RIPPERNAME).o: $(RIPPERNAME).c
	sc $(RIPPERNAME).c NOLINK NODEBUG
