; d0 = x0, d1 = y0, d2 = x1, d3 = y1, d4 = color, a0 = dest
DrawRect:
        move.w  d1,d5
        mulu.w  #ROWDELTA,d5
        add.l   d5,a0
        sub.w   d1,d3

        ; Enter with d3 = ycount-1
DrawRectYHandled:

        lea     PP32(pc),a1
        lea     PM32(pc),a2

        and.w   #$ff,d4
        lsl.w   #5,d4
        add.w   d4,a1
        add.w   d4,a2

        add.w   #1,d2           ; Make x1 inclusive

        moveq   #-32,d1
        move.w  d0,d5
        and.w   d1,d5           ; d5 = x0&-32
        and.w   d2,d1           ; d1 = x1&-32
        eor.w   d5,d0           ; d0 = x0&31
        eor.w   d1,d2           ; d2 = x1&31
        sub.w   d5,d1           ; d1 = (x1&-32)-(x0&-32)
        lsr.w   #5,d1           ; d1 = xcount-1
        lsr.w   #3,d5
        add.w   d5,a0           ; a0 += (x0&-32)>>3

        moveq   #-1,d4
        lsr.l   d0,d4           ; d4 = first word mask
        move.l  #1<<31,d5
        asr.l   d2,d5           ; d5 = last word mask

        ; d1 = xcount-1, d3 = ycount-1, d4/d5 first/last word mask

        move.w  .loops(pc,d1.w*2),d1
        jmp     .loops(pc,d1.w)
.loops
        dc.w    horiz1-.loops
        dc.w    horiz2-.loops
        dc.w    horiz3-.loops
        dc.w    horiz4-.loops
        dc.w    horiz5-.loops
        dc.w    horiz6-.loops
        dc.w    horiz7-.loops
        dc.w    horiz8-.loops
        dc.w    horiz9-.loops
        dc.w    horiz10-.loops
        dc.w    horiz11-.loops

horiz1
        and.l   d5,d4
        move.l  d4,d6
        move.l  d4,d7
        not.l   d7
.y
        jsr     (a2)
        add.w   #ROWDELTA-4,a0
        dbf     d3,.y
        rts

MAKE_HORIZ MACRO
horiz\<horiz_n>
        moveq   #-1,d0
        move.l  d4,d1
        move.l  d4,d2
        not.l   d2
        move.l  d5,d4
        not.l   d5
.y
        move.l  d1,d6
        move.l  d2,d7
        jsr     (a2)

        REPT horiz_n-2
        jsr     (a1)
        ENDR

        move.l  d4,d6
        move.l  d5,d7
        jsr     (a2)

        add.w   #ROWDELTA-horiz_n*4,a0
        dbf     d3,.y

        rts

        ENDM

        REPT 9
horiz_n set REPTN+2
        MAKE_HORIZ
        ENDR

horiz11
        moveq   #-1,d0
.y
        REPT 10
        jsr     (a1)
        ENDR
        add.w   #ROWDELTA-PLANEDELTA,a0
        dbf     d3,.y
        rts


PP32
.color set 0
        REPT 256
        IFNE (.color&1)
        move.l  d0,(a0)+
        ELSE
        clr.l   (a0)+
        ENDC
        REPT 7
        IFNE ((.color>>(REPTN+1))&1)
        move.l  d0,(REPTN+1)*PLANEDELTA-4(a0)
        ELSE
        clr.l   (REPTN+1)*PLANEDELTA-4(a0)
        ENDC
        ENDR
        rts
.color set .color+1
        ENDR


        IFNE (*-PP32)-256*32
        ERROR Invalid size!
        ENDC

PM32
.color set 0
        REPT 256
        IFNE (.color&1)
        or.l    d6,(a0)+
        ELSE
        and.l   d7,(a0)+
        ENDC
        REPT 7
        IFNE ((.color>>(REPTN+1))&1)
        or.l    d6,(REPTN+1)*PLANEDELTA-4(a0)
        ELSE
        and.l   d7,(REPTN+1)*PLANEDELTA-4(a0)
        ENDC
        ENDR
        rts
.color set .color+1
        ENDR


        IFNE (*-PM32)-256*32
        ERROR Invalid size!
        ENDC

; d0 = X0, d1 = X1, d4 = color, a0 = dest
DrawHorizLine:
        move.l  d1,d2
        moveq   #0,d3
        bra     DrawRectYHandled

; d0 = x0, d2 = x1, d3 = mask, d4 = color
SemiTransparentHLine
        lea     PM32(pc),a3
        and.w   #$ff,d4
        lsl.w   #5,d4
        add.w   d4,a3
SemiTransparentHLine_GotFunc
        add.w   #1,d2           ; Make x1 inclusive

        moveq   #-32,d1
        move.w  d0,d5
        and.w   d1,d5           ; d5 = x0&-32
        and.w   d2,d1           ; d1 = x1&-32
        eor.w   d5,d0           ; d0 = x0&31
        eor.w   d1,d2           ; d2 = x1&31
        sub.w   d5,d1           ; d1 = (x1&-32)-(x0&-32)
        lsr.w   #5,d1           ; d1 = xcount-1
        lsr.w   #3,d5
        add.w   d5,a0           ; a0 += (x0&-32)>>3

        moveq   #-1,d4
        lsr.l   d0,d4           ; d4 = first word mask
        move.l  #1<<31,d5
        asr.l   d2,d5           ; d5 = last word mask

        ; d1 = xcount-1, d3 = mask, d4/d5 first/last word mask

        sub.w   #1,d1
        bmi     .one

        move.l  d4,d6
        and.l   d3,d6
        move.l  d6,d7
        not.l   d7
        jsr     (a3)
        bra     .iter
.loop
        move.l  d3,d7
        move.l  d3,d6
        not.l   d7
        jsr     (a3)
.iter
        subq.w  #1,d1
        bpl     .loop

        move.l  d5,d6
        and.l   d3,d6
        move.l  d6,d7
        not.l   d7
        jmp     (a3)
.one:
        and.l   d5,d4
        and.l   d3,d4
        move.l  d4,d6
        move.l  d4,d7
        not.l   d7
        jmp     (a3)

; A0 = Dest, A1 = Left Edges, A2 = Right Edges, D0 = Y0, D7 = Y1
DrawSemiTransparentPoly
        move.l  #$aaaaaaaa,d3
        btst.l  #0,d0
        beq     .even
        ror.l   #1,d3
.even
        lea     PM32(pc),a3
        and.w   #$ff,d4
        lsl.w   #5,d4
        add.w   d4,a3

        move.w  d0,d1
        mulu.w  #ROWDELTA,d1
        lea     (a0,d1.l),a4
        lea     (a1,d0.w*2),a1
        lea     (a2,d0.w*2),a2
        sub.w   d0,d7
.y
        move.w  d7,a5
        move.l  a4,a0
        move.w  (a1)+,d0
        move.w  (a2)+,d2
        cmp.w   d0,d2
        bgt     .noswap
        exg     d0,d2
.noswap
        bsr     SemiTransparentHLine_GotFunc
        move.w  a5,d7
        ror.l   #1,d3
        add.w   #ROWDELTA,a4
        dbf     d7,.y
        rts

DrawSemiTransparentPoly2
        move.l  #$aaaaaaaa,d3
        btst.l  #0,d0
        beq     .even
        ror.l   #1,d3
.even
        lea     PM32(pc),a3
        and.w   #$ff,d4
        lsl.w   #5,d4
        add.w   d4,a3

        move.w  d0,d1
        mulu.w  #ROWDELTA,d1
        lea     (a0,d1.l),a4
        lea     (a1,d0.w*2),a1
        lea     (a2,d0.w*2),a2
        sub.w   d0,d7
.y
        move.w  d7,a5
        move.l  a4,a0
        move.w  (a1)+,d0
        move.w  (a2)+,d2
        cmp.w   d0,d2
        bgt     .noswap
        exg     d0,d2
.noswap
        bsr     SemiTransparentHLine_GotFunc
        move.w  a5,d7
        subq.w  #1,d7
        blt     .out
        addq.w  #2,a1
        addq.w  #2,a2
        ror.l   #1,d3
        add.w   #2*ROWDELTA,a4
        dbf     d7,.y
.out
        rts


