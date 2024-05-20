# compute this dir, knowing that this file is included from a makefile
# which is 2 levels below (letter/game). I haven't found a better way...
THIS_DIR := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))/../../

# change to your includes base
HDBASE = K:\jff\AmigaHD\amiga39_JFF_OS\include
# unpack whdload dev in this dir at start
WHDBASE = $(THIS_DIR)

# standard date gen & build commands
WDATE = wdate.py> datetime
VASM_NOPIC = vasmm68k_mot -DDATETIME -I$(HDBASE) -I$(WHDBASE) -devpac -nosym -Fhunkexe
VASM = $(VASM_NOPIC) -pic
