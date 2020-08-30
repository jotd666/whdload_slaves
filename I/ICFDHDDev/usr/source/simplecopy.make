EXE=simplecopy

OBJ= $(EXE).o

OPT= -3.1

$(EXE): $(OBJ)
    dcc $(OPT) $(OBJ) -o $(EXE)


$(EXE).o: $(EXE).c
	dcc $(OPT) -c $(EXE).c

