; Native 040 arithmetic for transcendental instructions.
; Range reduction uses a split pi/2; atan uses two half-angle reductions.
; FPSP remains available for exceptional arguments / non-default FPCR.
; Trig fast range: |x| <= 2^20. Sine degree 17, cosine degree 18.
; Atan reduces to |x| <= tan(pi/16), then uses degree 31.
; Preserve FPCR, CCR, all GPRs and every non-destination FPU register.
        mc68040
native_tan:
        move.w ccr,-(sp)
        movem.l d0-d2/a0,-(sp)
        fmovem.x fp0-fp7,-(sp)
        fmove.l fpcr,-(sp)
        fmove.x fp7,fp0
        tst.l (sp)
        bne .fallback
        fmove.x fp0,-(sp)
        move.w (sp),d0
        lea 12(sp),sp
        and.w #$7fff,d0
        cmp.w #$7fff,d0
        beq .fallback
        fabs.x fp0,fp1
        fcmp.s #1048576,fp1
        fbgt .fallback
        ftst.x fp0
        fbeq .zero
        bsr math_tan
        fmove.x fp0,4(sp)
        fmove.l fpsr,d0
        or.l #$208,d0
        fmove.l d0,fpsr
        bra .restore
.zero:
        fmove.x fp0,4(sp)
.restore:
        fmove.l (sp)+,fpcr
        fmovem.x (sp)+,fp0-fp7
        movem.l (sp)+,d0-d2/a0
        move.w (sp)+,ccr
        rts
.fallback:
        fmove.l (sp)+,fpcr
        fmovem.x (sp)+,fp0-fp7
        movem.l (sp)+,d0-d2/a0
        move.w (sp)+,ccr
        dc.w $f200,$1c0f
        rts

native_sin:
        move.w ccr,-(sp)
        movem.l d0-d2/a0,-(sp)
        fmovem.x fp0-fp7,-(sp)
        fmove.l fpcr,-(sp)
        fmove.x fp7,fp0
        tst.l (sp)
        bne .fallback
        fmove.x fp0,-(sp)
        move.w (sp),d0
        lea 12(sp),sp
        and.w #$7fff,d0
        cmp.w #$7fff,d0
        beq .fallback
        fabs.x fp0,fp1
        fcmp.s #1048576,fp1
        fbgt .fallback
        ftst.x fp0
        fbeq .zero
        bsr math_sin
        fmove.x fp0,4(sp)
        fmove.l fpsr,d0
        or.l #$208,d0
        fmove.l d0,fpsr
        bra .restore
.zero:
        fmove.x fp0,4(sp)
.restore:
        fmove.l (sp)+,fpcr
        fmovem.x (sp)+,fp0-fp7
        movem.l (sp)+,d0-d2/a0
        move.w (sp)+,ccr
        rts
.fallback:
        fmove.l (sp)+,fpcr
        fmovem.x (sp)+,fp0-fp7
        movem.l (sp)+,d0-d2/a0
        move.w (sp)+,ccr
        dc.w $f200,$1c0e
        rts

native_cos:
        move.w ccr,-(sp)
        movem.l d0-d2/a0,-(sp)
        fmovem.x fp0-fp7,-(sp)
        fmove.l fpcr,-(sp)
        fmove.x fp7,fp0
        tst.l (sp)
        bne .fallback
        fmove.x fp0,-(sp)
        move.w (sp),d0
        lea 12(sp),sp
        and.w #$7fff,d0
        cmp.w #$7fff,d0
        beq .fallback
        fabs.x fp0,fp1
        fcmp.s #1048576,fp1
        fbgt .fallback
        ftst.x fp0
        fbeq .zero
        bsr math_cos
        fmove.x fp0,4(sp)
        fmove.l fpsr,d0
        or.l #$208,d0
        fmove.l d0,fpsr
        bra .restore
.zero:
        fmove.s #1,fp0
        fmove.x fp0,4(sp)
.restore:
        fmove.l (sp)+,fpcr
        fmovem.x (sp)+,fp0-fp7
        movem.l (sp)+,d0-d2/a0
        move.w (sp)+,ccr
        rts
.fallback:
        fmove.l (sp)+,fpcr
        fmovem.x (sp)+,fp0-fp7
        movem.l (sp)+,d0-d2/a0
        move.w (sp)+,ccr
        dc.w $f200,$1c1d
        rts

native_atan2:
        move.w ccr,-(sp)
        movem.l d0-d2/a0,-(sp)
        fmovem.x fp0-fp7,-(sp)
        fmove.l fpcr,-(sp)
        fmove.x fp1,fp0
        tst.l (sp)
        bne .fallback
        fmove.x fp0,-(sp)
        move.w (sp),d0
        lea 12(sp),sp
        and.w #$7fff,d0
        cmp.w #$7fff,d0
        beq .fallback
        ftst.x fp0
        fbeq .zero
        bsr math_atan
        fmove.x fp0,64(sp)
        fmove.l fpsr,d0
        or.l #$208,d0
        fmove.l d0,fpsr
        bra .restore
.zero:
        fmove.x fp0,64(sp)
.restore:
        fmove.l (sp)+,fpcr
        fmovem.x (sp)+,fp0-fp7
        movem.l (sp)+,d0-d2/a0
        move.w (sp)+,ccr
        rts
.fallback:
        fmove.l (sp)+,fpcr
        fmovem.x (sp)+,fp0-fp7
        movem.l (sp)+,d0-d2/a0
        move.w (sp)+,ccr
        dc.w $f200,$068a
        rts

native_atan:
        move.w ccr,-(sp)
        movem.l d0-d2/a0,-(sp)
        fmovem.x fp0-fp7,-(sp)
        fmove.l fpcr,-(sp)
        fmove.x fp7,fp0
        tst.l (sp)
        bne .fallback
        fmove.x fp0,-(sp)
        move.w (sp),d0
        lea 12(sp),sp
        and.w #$7fff,d0
        cmp.w #$7fff,d0
        beq .fallback
        ftst.x fp0
        fbeq .zero
        bsr math_atan
        fmove.x fp0,4(sp)
        fmove.l fpsr,d0
        or.l #$208,d0
        fmove.l d0,fpsr
        bra .restore
.zero:
        fmove.x fp0,4(sp)
.restore:
        fmove.l (sp)+,fpcr
        fmovem.x (sp)+,fp0-fp7
        movem.l (sp)+,d0-d2/a0
        move.w (sp)+,ccr
        rts
.fallback:
        fmove.l (sp)+,fpcr
        fmovem.x (sp)+,fp0-fp7
        movem.l (sp)+,d0-d2/a0
        move.w (sp)+,ccr
        dc.w $f200,$1c0a
        rts

native_asin:
        move.w ccr,-(sp)
        movem.l d0-d2/a0,-(sp)
        fmovem.x fp0-fp7,-(sp)
        fmove.l fpcr,-(sp)
        fmove.x fp7,fp0
        tst.l (sp)
        bne .fallback
        fmove.x fp0,-(sp)
        move.w (sp),d0
        lea 12(sp),sp
        and.w #$7fff,d0
        cmp.w #$7fff,d0
        beq .fallback
        fabs.x fp0,fp1
        fcmp.s #1,fp1
        fbgt .fallback
        ftst.x fp0
        fbeq .zero
        bsr math_asin
        fmove.x fp0,4(sp)
        fmove.l fpsr,d0
        or.l #$208,d0
        fmove.l d0,fpsr
        bra .restore
.zero:
        fmove.x fp0,4(sp)
.restore:
        fmove.l (sp)+,fpcr
        fmovem.x (sp)+,fp0-fp7
        movem.l (sp)+,d0-d2/a0
        move.w (sp)+,ccr
        rts
.fallback:
        fmove.l (sp)+,fpcr
        fmovem.x (sp)+,fp0-fp7
        movem.l (sp)+,d0-d2/a0
        move.w (sp)+,ccr
        dc.w $f200,$1c0c
        rts

math_sin:
        bsr math_sincos
        rts
math_cos:
        bsr math_sincos
        fmove.x fp1,fp0
        rts
math_tan:
        bsr math_sincos
        fdiv.x fp1,fp0
        rts
; fp0 angle -> fp0 sine, fp1 cosine; |angle| <= 2^20, FPCR=0.
math_sincos:
        fmove.x fp0,fp2
        fmul.d math_invpio2(pc),fp2
        fmove.l fp2,d0
        fmove.l d0,fp2
        fmove.x fp2,fp3
        fmul.d math_pio2_hi(pc),fp3
        fsub.x fp3,fp0
        fmul.d math_pio2_lo(pc),fp2
        fsub.x fp2,fp0
        fmove.l d0,fp3
        fmul.d math_pio2_tail(pc),fp3
        fsub.x fp3,fp0
        fmove.x fp0,fp2
        fmul.x fp0,fp2
        fmove.d math_sin8(pc),fp3
        fmul.x fp2,fp3
        fadd.d math_sin7(pc),fp3
        fmul.x fp2,fp3
        fadd.d math_sin6(pc),fp3
        fmul.x fp2,fp3
        fadd.d math_sin5(pc),fp3
        fmul.x fp2,fp3
        fadd.d math_sin4(pc),fp3
        fmul.x fp2,fp3
        fadd.d math_sin3(pc),fp3
        fmul.x fp2,fp3
        fadd.d math_sin2(pc),fp3
        fmul.x fp2,fp3
        fadd.d math_sin1(pc),fp3
        fmul.x fp2,fp3
        fadd.s #1,fp3
        fmul.x fp0,fp3
        fmove.d math_cos9(pc),fp1
        fmul.x fp2,fp1
        fadd.d math_cos8(pc),fp1
        fmul.x fp2,fp1
        fadd.d math_cos7(pc),fp1
        fmul.x fp2,fp1
        fadd.d math_cos6(pc),fp1
        fmul.x fp2,fp1
        fadd.d math_cos5(pc),fp1
        fmul.x fp2,fp1
        fadd.d math_cos4(pc),fp1
        fmul.x fp2,fp1
        fadd.d math_cos3(pc),fp1
        fmul.x fp2,fp1
        fadd.d math_cos2(pc),fp1
        fmul.x fp2,fp1
        fadd.d math_cos1(pc),fp1
        fmul.x fp2,fp1
        fadd.s #1,fp1
        fmove.x fp3,fp0
        and.w #3,d0
        beq .out
        cmp.w #2,d0
        beq .negate
        fmove.x fp0,fp2
        fmove.x fp1,fp0
        fmove.x fp2,fp1
        cmp.w #1,d0
        bne .third
        fneg.x fp1
        rts
.third:
        fneg.x fp0
        rts
.negate:
        fneg.x fp0
        fneg.x fp1
.out:
        rts
; atan: reciprocal for |x|>1, then two exact half-angle identities.
math_atan:
        fmove.x fp0,fp6
        fabs.x fp0
        moveq #0,d1
        fcmp.s #1,fp0
        fble .small
        fmove.s #1,fp1
        fdiv.x fp0,fp1
        fmove.x fp1,fp0
        moveq #1,d1
.small:
        moveq #1,d2
.half:
        fmove.x fp0,fp1
        fmul.x fp0,fp1
        fadd.s #1,fp1
        fsqrt.x fp1
        fadd.s #1,fp1
        fdiv.x fp1,fp0
        dbf d2,.half
        fmove.x fp0,fp2
        fmul.x fp0,fp2
        fmove.d math_atan15(pc),fp1
        fmul.x fp2,fp1
        fadd.d math_atan14(pc),fp1
        fmul.x fp2,fp1
        fadd.d math_atan13(pc),fp1
        fmul.x fp2,fp1
        fadd.d math_atan12(pc),fp1
        fmul.x fp2,fp1
        fadd.d math_atan11(pc),fp1
        fmul.x fp2,fp1
        fadd.d math_atan10(pc),fp1
        fmul.x fp2,fp1
        fadd.d math_atan9(pc),fp1
        fmul.x fp2,fp1
        fadd.d math_atan8(pc),fp1
        fmul.x fp2,fp1
        fadd.d math_atan7(pc),fp1
        fmul.x fp2,fp1
        fadd.d math_atan6(pc),fp1
        fmul.x fp2,fp1
        fadd.d math_atan5(pc),fp1
        fmul.x fp2,fp1
        fadd.d math_atan4(pc),fp1
        fmul.x fp2,fp1
        fadd.d math_atan3(pc),fp1
        fmul.x fp2,fp1
        fadd.d math_atan2(pc),fp1
        fmul.x fp2,fp1
        fadd.d math_atan1(pc),fp1
        fmul.x fp2,fp1
        fadd.s #1,fp1
        fmul.x fp1,fp0
        fmul.s #4,fp0
        tst.w d1
        beq .sign
        fmove.x math_pio2(pc),fp1
        fsub.x fp0,fp1
        fmove.x fp1,fp0
.sign:
        fmove.x fp6,-(sp)
        move.w (sp),d0
        lea 12(sp),sp
        tst.w d0
        bpl .out
        fneg.x fp0
.out:
        rts
math_asin:
        fabs.x fp0,fp1
        fcmp.s #1,fp1
        fbne .regular
        fmul.x math_pio2(pc),fp0
        rts
.regular:
        fmove.s #1,fp1
        fsub.x fp0,fp1
        fmove.s #1,fp2
        fadd.x fp0,fp2
        fmul.x fp2,fp1
        fsqrt.x fp1
        fdiv.x fp1,fp0
        bra math_atan
math_invpio2: dc.l $3fe45f30,$6dc9c883
math_pio2_hi: dc.l $3ff921fb,$54400000
math_pio2_lo: dc.l $3dd0b461,$1a626331
math_pio2_tail: dc.l $3a71701b,$839a2520
math_sin1: dc.l $bfc55555,$55555555
math_sin2: dc.l $3f811111,$11111111
math_sin3: dc.l $bf2a01a0,$1a01a01a
math_sin4: dc.l $3ec71de3,$a556c734
math_sin5: dc.l $be5ae645,$67f544e4
math_sin6: dc.l $3de61246,$13a86d09
math_sin7: dc.l $bd6ae7f3,$e733b81f
math_sin8: dc.l $3ce952c7,$7030ad4a
math_cos1: dc.l $bfe00000,$00000000
math_cos2: dc.l $3fa55555,$55555555
math_cos3: dc.l $bf56c16c,$16c16c17
math_cos4: dc.l $3efa01a0,$1a01a01a
math_cos5: dc.l $be927e4f,$b7789f5c
math_cos6: dc.l $3e21eed8,$eff8d898
math_cos7: dc.l $bda93974,$a8c07c9d
math_cos8: dc.l $3d2ae7f3,$e733b81f
math_cos9: dc.l $bca68278,$63b97d97
math_atan1: dc.l $bfd55555,$55555555
math_atan2: dc.l $3fc99999,$9999999a
math_atan3: dc.l $bfc24924,$92492492
math_atan4: dc.l $3fbc71c7,$1c71c71c
math_atan5: dc.l $bfb745d1,$745d1746
math_atan6: dc.l $3fb3b13b,$13b13b14
math_atan7: dc.l $bfb11111,$11111111
math_atan8: dc.l $3fae1e1e,$1e1e1e1e
math_atan9: dc.l $bfaaf286,$bca1af28
math_atan10: dc.l $3fa86186,$18618618
math_atan11: dc.l $bfa642c8,$590b2164
math_atan12: dc.l $3fa47ae1,$47ae147b
math_atan13: dc.l $bfa2f684,$bda12f68
math_atan14: dc.l $3fa1a7b9,$611a7b96
math_atan15: dc.l $bfa08421,$08421084
math_pio2: dc.l $3fff0000,$c90fdaa2,$2168c235
        mc68020

; Bounded exp(x): |x| <= 64, FPCR=0; otherwise retain original FPSP.
; Reduce x = k*ln(2)+r, evaluate degree-17 exp(r), multiply by exact 2^k.
        mc68040
native_exp:
        move.w ccr,-(sp)
        movem.l d0-d2/a0,-(sp)
        fmovem.x fp0-fp7,-(sp)
        fmove.l fpcr,-(sp)
        fmove.x fp7,fp0
        tst.l (sp)
        bne .fallback
        fmove.x fp0,-(sp)
        move.w (sp),d0
        lea 12(sp),sp
        and.w #$7fff,d0
        cmp.w #$7fff,d0
        beq .fallback
        fabs.x fp0,fp1
        fcmp.s #64,fp1
        fbgt .fallback
        ftst.x fp0
        fbeq .zero
        bsr math_exp
        fmove.x fp0,4(sp)
        fmove.l fpsr,d0
        or.l #$208,d0
        fmove.l d0,fpsr
        bra .restore
.zero:
        fmove.s #1,fp0
        fmove.x fp0,4(sp)
.restore:
        fmove.l (sp)+,fpcr
        fmovem.x (sp)+,fp0-fp7
        movem.l (sp)+,d0-d2/a0
        move.w (sp)+,ccr
        rts
.fallback:
        fmove.l (sp)+,fpcr
        fmovem.x (sp)+,fp0-fp7
        movem.l (sp)+,d0-d2/a0
        move.w (sp)+,ccr
        dc.w $f200,$1c10 ; original fetox.x fp7,fp0
        rts
math_exp:
        fmove.x fp0,fp1
        fmul.d math_exp_invln2(pc),fp1
        fmove.l fp1,d0
        fmove.l d0,fp1
        fmove.x fp1,fp2
        fmul.d math_exp_ln2_hi(pc),fp2
        fsub.x fp2,fp0
        fmove.x fp1,fp2
        fmul.d math_exp_ln2_lo(pc),fp2
        fsub.x fp2,fp0
        fmul.d math_exp_ln2_tail(pc),fp1
        fsub.x fp1,fp0
        fmove.d math_exp_c17(pc),fp1
        fmul.x fp0,fp1
        fadd.d math_exp_c16(pc),fp1
        fmul.x fp0,fp1
        fadd.d math_exp_c15(pc),fp1
        fmul.x fp0,fp1
        fadd.d math_exp_c14(pc),fp1
        fmul.x fp0,fp1
        fadd.d math_exp_c13(pc),fp1
        fmul.x fp0,fp1
        fadd.d math_exp_c12(pc),fp1
        fmul.x fp0,fp1
        fadd.d math_exp_c11(pc),fp1
        fmul.x fp0,fp1
        fadd.d math_exp_c10(pc),fp1
        fmul.x fp0,fp1
        fadd.d math_exp_c9(pc),fp1
        fmul.x fp0,fp1
        fadd.d math_exp_c8(pc),fp1
        fmul.x fp0,fp1
        fadd.d math_exp_c7(pc),fp1
        fmul.x fp0,fp1
        fadd.d math_exp_c6(pc),fp1
        fmul.x fp0,fp1
        fadd.d math_exp_c5(pc),fp1
        fmul.x fp0,fp1
        fadd.d math_exp_c4(pc),fp1
        fmul.x fp0,fp1
        fadd.d math_exp_c3(pc),fp1
        fmul.x fp0,fp1
        fadd.d math_exp_c2(pc),fp1
        fmul.x fp0,fp1
        fadd.s #1,fp1
        fmul.x fp1,fp0
        fadd.s #1,fp0
        suba.w #12,sp
        add.w #16383,d0
        move.w d0,(sp)
        clr.w 2(sp)
        move.l #$80000000,4(sp)
        clr.l 8(sp)
        fmove.x (sp)+,fp1
        fmul.x fp1,fp0
        rts
math_exp_invln2: dc.l $3ff71547,$652b82fe
math_exp_ln2_hi: dc.l $3fe62e42,$00000000
math_exp_ln2_lo: dc.l $3e9fdf47,$3de6af28
math_exp_ln2_tail: dc.l $bb3c4c67,$fc0d0951
math_exp_c2: dc.l $3fe00000,$00000000
math_exp_c3: dc.l $3fc55555,$55555555
math_exp_c4: dc.l $3fa55555,$55555555
math_exp_c5: dc.l $3f811111,$11111111
math_exp_c6: dc.l $3f56c16c,$16c16c17
math_exp_c7: dc.l $3f2a01a0,$1a01a01a
math_exp_c8: dc.l $3efa01a0,$1a01a01a
math_exp_c9: dc.l $3ec71de3,$a556c734
math_exp_c10: dc.l $3e927e4f,$b7789f5c
math_exp_c11: dc.l $3e5ae645,$67f544e4
math_exp_c12: dc.l $3e21eed8,$eff8d898
math_exp_c13: dc.l $3de61246,$13a86d09
math_exp_c14: dc.l $3da93974,$a8c07c9d
math_exp_c15: dc.l $3d6ae7f3,$e733b81f
math_exp_c16: dc.l $3d2ae7f3,$e733b81f
math_exp_c17: dc.l $3ce952c7,$7030ad4a
        mc68020
