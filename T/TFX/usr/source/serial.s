        IFEQ SER_OUTPUT
PRINT_MSG macro
        endm
PRINT_REGS macro
        endm
        ELSE
SerPutchar:
        btst.b  #13-8,$dff000+serdatr
        move.l  d0,-(sp)
        and.w   #$ff,d0
        or.w    #$100,d0       ; stop bit
        move.w  d0,$dff030
        move.l  (sp)+,d0
        rts
	
SerPutMsg:
        movem.l  d0/a0,-(sp)
spLoop:
        move.b  (a0)+,d0
        beq     spDone
        bsr     SerPutchar
        bra     spLoop
spDone:
        movem.l  (sp)+,d0/a0
        rts
SerPutCrLf:
        move.l  d0,-(sp)
        moveq   #13,d0
        bsr     SerPutchar
        moveq   #10,d0
        bsr     SerPutchar
        move.l  (sp)+,d0
        rts
SerPutSpace:
        move.l  d0,-(sp)
        moveq   #' ',d0
        bsr     SerPutchar
        move.l  (sp)+,d0
        rts
SerPutNum:
        movem.l d0-d2,-(sp)
        move.l  d0,d1
        moveq   #7,d2
spnLoop:
        rol.l   #4,d1
        move.w  d1,d0
        and.b   #$f,d0
        add.b   #$30,d0
        cmp.b   #$39,d0
        ble.b   spnPrint
        add.b   #39,d0
spnPrint:
        bsr     SerPutchar
        dbf     d2,spnLoop
        movem.l (sp)+,d0-d2
        rts

PRINT_MSG macro
        move.l  a0,-(sp)
        lea     .msg\@(pc),a0
        bsr     SerPutMsg
        move.l  (sp)+,a0
        bra .out\@
.msg\@:
        dc.b \1
        dc.b 0
        even
.out\@:
        endm
PRINT_NUM macro
        move.l  d0,-(sp)
        move.l  \1,d0
        bsr     SerPutNum
        move.l  (sp)+,d0
        endm
PR macro
        PRINT_MSG <\1,'='>
        PRINT_NUM \2
        endm
PRINT_REGS macro
        PR "D0",d0
        bsr SerPutSpace
        PR "D1",d1
        bsr SerPutSpace
        PR "D2",d2
        bsr SerPutSpace
        PR "D3",d3
        bsr SerPutCrLf
        PR "D4",d4
        bsr SerPutSpace
        PR "D5",d5
        bsr SerPutSpace
        PR "D6",d6
        bsr SerPutSpace
        PR "D7",d7
        bsr SerPutCrLf
        PR "A0",a0
        bsr SerPutSpace
        PR "A1",a1
        bsr SerPutSpace
        PR "A2",a2
        bsr SerPutSpace
        PR "A3",a3
        bsr SerPutCrLf
        PR "A4",a4
        bsr SerPutSpace
        PR "A5",a5
        bsr SerPutSpace
        PR "A6",a6
        bsr SerPutSpace
        PR "A7",a7
        bsr SerPutCrLf
        endm
        ENDC ; SER_OUTPUT

