; Optional VERIFY_OVERLAY_KEY_EXPERIMENT tests for the shared guard.
overlay_key_selftest:
 movem.l d0-a6,-(sp)
 lea overlay_key_result(pc),a5
 clr.l (a5)
 lea overlay_key_cases(pc),a3
 moveq #OVERLAY_KEY_CASES-1,d7
.case
 moveq #31,d6
.flags
 lea overlay_key_fixture(pc),a4
 move.l a4,a0
 moveq #19,d0
.clear
 clr.l (a0)+
 dbf d0,.clear
 move.w #1,(a4)
 move.w #3,2(a4)
 move.w #2,4(a4)
 lea 48(a4),a0
 move.l a0,8(a4)
 lea 64(a4),a0
 move.l a0,12(a4)
 move.w #4,16(a4)
 lea 52(a4),a0
 move.l a0,20(a4)
 lea 68(a4),a0
 move.l a0,24(a4)
 move.w #8,28(a4)
 moveq #11,d1
 moveq #32,d0
 lea 48(a4),a0
 lea 64(a4),a1
.fill
 move.b d0,(a0)+
 move.b d0,(a1)+
 addq.b #1,d0
 dbf d1,.fill
 move.w (a3),d1
 move.w 2(a3),d0
 move.b d0,0(a4,d1.w)
 move.l #$12345678,d1
 move.l #$87654321,d2
 move.l #$11223344,d3
 lea 60(a4),a1
 lea 64(a4),a2
 move.l a4,a0
 moveq #3,d0
 move.w d6,ccr
 bsr overlay_key_matches
 cmp.w 4(a3),d0
 bne overlay_key_bad
 cmpi.l #1,d0
 bhi overlay_key_bad
 cmpi.l #$12345678,d1
 bne overlay_key_bad
 cmpi.l #$87654321,d2
 bne overlay_key_bad
 cmpi.l #$11223344,d3
 bne overlay_key_bad
 cmpa.l a4,a0
 bne overlay_key_bad
 lea 60(a4),a0
 cmpa.l a0,a1
 bne overlay_key_bad
 lea 64(a4),a0
 cmpa.l a0,a2
 bne overlay_key_bad
 moveq #0,d0
 move.w 6(a3),d0
 cmp.l overlay_key_reads(pc),d0
 bne overlay_key_bad
 addq.l #1,(a5)
 dbf d6,.flags
 addq.l #8,a3
 dbf d7,.case
 movem.l (sp)+,d0-a6
 rts
overlay_key_bad:
 pea .message(pc)
 pea TDREASON_FAILMSG
 lea .resload_base(pc),a2
.resload_base
 adda.l #_resload-.resload_base,a2
 move.l (a2),a2
 jmp resload_Abort(a2)
.message: dc.b "Red Baron: private overlay key mismatch",0
 even
overlay_key_cases:
 include "overlay-key-cases.i"
overlay_key_cases_end:
OVERLAY_KEY_CASES = (overlay_key_cases_end-overlay_key_cases)/8
overlay_key_result: dc.l 0
overlay_key_reads: dc.l 0
overlay_key_fixture: dcb.b 80,0
