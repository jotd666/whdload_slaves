        IFND SER_OUTPUT
SER_OUTPUT=0
        ENDC

        IFEQ SER_OUTPUT
SERPRINTF macro
        endm
        ELSE
SerPutchar:
        tst.b   d0
        beq.b   .out
        btst.b  #13-8,(a3)
        beq.b   SerPutchar
        and.w   #$ff,d0
        or.w    #$100,d0       ; stop bit
        move.w  d0,serdat-serdatr(a3)
.out:
        rts

        ; TODO: Use resload_VSNPrintF
SERPRINTF       macro
        movem.l d0-d1/a0-a3/a6,-(sp)
        if NARG>=9
        move.l  \9,-(sp)
        endc
        if NARG>=8
        move.l  \8,-(sp)
        endc
        if NARG>=7
        move.l  \7,-(sp)
        endc
        if NARG>=6
        move.l  \6,-(sp)
        endc
        if NARG>=5
        move.l  \5,-(sp)
        endc
        if NARG>=4
        move.l  \4,-(sp)
        endc
        if NARG>=3
        move.l  \3,-(sp)
        endc
        if NARG>=2
        move.l  \2,-(sp)
        endc
        lea     .fmt\@(pc),a0
        move.l  sp,a1
        lea     SerPutchar(pc),a2
        lea     $dff000+serdatr,a3
        move.l  $4.w,a6
        jsr     _LVORawDoFmt(a6)
        add     #4*(NARG-1),sp
        movem.l (sp)+,d0-d1/a0-a3/a6
        bra     .done\@
.fmt\@: dc.b    \1,0
        even
.done\@:
        endm
	
        ENDC ; SER_OUTPUT

