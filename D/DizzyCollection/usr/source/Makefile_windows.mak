include ../../options.mk

PROGNAME = Disk



OPTS = -DDATETIME -I$(HDBASE)/amiga39_JFF_OS/include -I$(WHDBASE)/WHDload/Include -I$(WHDBASE) -devpac -nosym -Fhunkexe

all :  $(PROGNAME)1.slave $(PROGNAME)2.slave 

$(PROGNAME)1.slave : $(PROGNAME)1HD.s
	$(WDATE)
	vasmm68k_mot $(OPTS) -o $(PROGNAME)1.slave $(PROGNAME)1HD.s
$(PROGNAME)2.slave : $(PROGNAME)2HD.s
	$(WDATE)
	vasmm68k_mot $(OPTS) -o $(PROGNAME)2.slave $(PROGNAME)2HD.s
