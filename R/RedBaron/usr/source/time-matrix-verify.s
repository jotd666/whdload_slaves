; W6 private orientation candidate and native twins, VERIFY only.
; No game hook: original sim:3648c remains installed until timing/ABI gates pass.
TIME_MATRIX_SIZE = $3688e-$3648c

time_matrix_install:
 movem.l d0-a6,-(sp)
 move.l a1,a0
 adda.l #$3648c,a0
 cmpi.l #$4e550000,(a0)
 bne time_matrix_bad
 cmpi.l #$48e73e30,4(a0)
 bne time_matrix_bad
 lea time_matrix_original(pc),a3
 lea time_matrix_candidate(pc),a4
 move.w #TIME_MATRIX_SIZE/2-1,d0
.copy
 move.w (a0)+,d1
 move.w d1,(a3)+
 move.w d1,(a4)+
 dbf d0,.copy
 move.l a1,d0
 addi.l #$36d58,d0
 lea time_matrix_table(pc),a0
 move.l d0,(a0)
 lea time_matrix_candidate(pc),a4
 move.w #-$6,2(a4)
 ; Each replacement branches over the remaining original bytes in its slot.
 lea $364ce-$3648c(a4),a0
 lea time_matrix_plus(pc),a3
 bsr time_matrix_call_patch
 move.w #$3f00,6(a0)
 lea $364f6-$3648c(a4),a3
 lea 8(a0),a0
 bsr time_matrix_branch_patch
 lea $364f6-$3648c(a4),a0
 lea time_matrix_minus(pc),a3
 bsr time_matrix_call_patch
 lea $3651c-$3648c(a4),a3
 lea 6(a0),a0
 bsr time_matrix_branch_patch
 lea $3654c-$3648c(a4),a0
 lea time_matrix_quarter(pc),a3
 bsr time_matrix_call_patch
 lea $36576-$3648c(a4),a3
 lea 6(a0),a0
 bsr time_matrix_branch_patch
 lea $365a6-$3648c(a4),a0
 move.l #$302dfffa,(a0)
 lea $365d0-$3648c(a4),a3
 lea 4(a0),a0
 bsr time_matrix_branch_patch
 lea $365d4-$3648c(a4),a0
 move.l #$302dfffe,(a0)
 move.w #$3f00,4(a0)
 lea $365fc-$3648c(a4),a3
 lea 6(a0),a0
 bsr time_matrix_branch_patch
 lea $365fc-$3648c(a4),a0
 move.l #$302dfffc,(a0)
 lea $36622-$3648c(a4),a3
 lea 4(a0),a0
 bsr time_matrix_branch_patch
 ; MOVE SR is user-readable only on 68000. Match existing native twin policy.
 lea .attn_base(pc),a0
.attn_base
 adda.l #perf_attnflags+3-.attn_base,a0
 btst #0,(a0)
 beq .cpu_ready
 lea time_matrix_ccr1(pc),a0
 move.w #$42c0,(a0)
 lea time_matrix_ccr2(pc),a0
 move.w #$42c0,(a0)
.cpu_ready
 jsr resload_FlushCache(a2)
 bsr time_matrix_selftest
time_matrix_ready:
 movem.l (sp)+,d0-a6
 rts
time_matrix_call_patch
 move.w #$4eb9,(a0)
 move.l a3,2(a0)
 rts
time_matrix_branch_patch
 move.w #$6000,(a0)
 move.l a3,d0
 sub.l a0,d0
 subq.l #2,d0
 move.w d0,2(a0)
 rts

; Preserve the original word expressions and individual ASR rounding.
time_matrix_plus:
 move.w 2(a2),d0
 add.w 4(a2),d0
 bsr time_matrix_half
 move.w d0,-2(a5)
 rts
time_matrix_minus:
 move.w 2(a2),d0
 sub.w 4(a2),d0
 bsr time_matrix_half
 move.w d0,-4(a5)
 rts
time_matrix_quarter:
 move.w 4(a2),d0
 add.w 2(a2),d0
 addi.w #$c000,d0
 bsr time_matrix_half
 move.w d0,-6(a5)
 rts
time_matrix_half:
 lsr.w #4,d0
 btst #11,d0
 beq .index
 move.w #4096,d1
 sub.w d0,d1
 move.w d1,d0
.index
 add.w d0,d0
 move.l time_matrix_table(pc),a0
 adda.w d0,a0
 move.w (a0),d0
 asr.w #1,d0
 rts

time_matrix_selftest:
 movem.l d0-a6,-(sp)
 lea time_matrix_result(pc),a0
 clr.l (a0)
 lea time_matrix_cases(pc),a3
 moveq #TIME_MATRIX_CASES-1,d7
.case
 lea time_matrix_input(pc),a0
 move.l (a3),(a0)
 move.w 4(a3),4(a0)
 moveq #31,d6
.flags
 lea time_matrix_flags(pc),a0
 move.w d6,(a0)
 bsr time_matrix_twin
 lea time_matrix_result(pc),a0
 addq.l #1,(a0)
 dbf d6,.flags
 addq.l #6,a3
 dbf d7,.case
 movem.l (sp)+,d0-a6
 rts

time_matrix_twin:
 movem.l d0-a6,-(sp)
 bsr time_matrix_clear
 pea time_matrix_output(pc)
 pea time_matrix_input(pc)
 movem.l time_matrix_seed(pc),d0-a6
 move.w time_matrix_flags(pc),ccr
 bsr time_matrix_original
 movem.l d0-a6,-(sp)
time_matrix_ccr1:
 move.w sr,d0
 lea time_matrix_ccr_expected(pc),a0
 move.w d0,(a0)
 move.l sp,a0
 lea time_matrix_regs1(pc),a1
 moveq #14,d0
.copy_first
 move.l (a0)+,(a1)+
 dbf d0,.copy_first
 lea 60(sp),sp
 addq.l #8,sp
 lea time_matrix_output(pc),a0
 lea time_matrix_expected(pc),a1
 moveq #4,d0
.save
 move.l (a0)+,(a1)+
 dbf d0,.save
 bsr time_matrix_clear
 pea time_matrix_output(pc)
 pea time_matrix_input(pc)
 movem.l time_matrix_seed(pc),d0-a6
 move.w time_matrix_flags(pc),ccr
 bsr time_matrix_candidate
 movem.l d0-a6,-(sp)
time_matrix_ccr2:
 move.w sr,d0
 move.w time_matrix_ccr_expected(pc),d1
 eor.w d1,d0
 andi.w #31,d0
 bne time_matrix_bad
 move.l sp,a0
 lea time_matrix_regs2(pc),a1
 moveq #14,d0
.copy_second
 move.l (a0)+,(a1)+
 dbf d0,.copy_second
 lea 60(sp),sp
 addq.l #8,sp
 lea time_matrix_regs1(pc),a0
 lea time_matrix_regs2(pc),a1
 moveq #14,d0
.regs
 move.l (a0)+,d1
 cmp.l (a1)+,d1
 bne time_matrix_bad
 dbf d0,.regs
 lea time_matrix_expected(pc),a0
 lea time_matrix_output(pc),a1
 moveq #4,d0
.output
 move.l (a0)+,d1
 cmp.l (a1)+,d1
 bne time_matrix_bad
 dbf d0,.output
 movem.l (sp)+,d0-a6
 rts

time_matrix_clear:
 lea time_matrix_output(pc),a0
 moveq #4,d0
.loop
 move.l #$a5a5a5a5,(a0)+
 dbf d0,.loop
 rts

time_matrix_bad:
 pea .message(pc)
 pea TDREASON_FAILMSG
 lea .resload_base(pc),a2
.resload_base
 adda.l #_resload-.resload_base,a2
 move.l (a2),a2
 jmp resload_Abort(a2)
.message: dc.b "Red Baron: W6 matrix twin mismatch",0
 even
time_matrix_table: dc.l 0
time_matrix_flags: dc.w 0
time_matrix_ccr_expected: dc.w 0
time_matrix_input: dcb.b 6,0
time_matrix_output: dcb.b 20,0
time_matrix_expected: dcb.b 20,0
time_matrix_regs1: dcb.l 15,0
time_matrix_regs2: dcb.l 15,0
time_matrix_seed:
 dc.l $13579bdf,$fedc2468,$89abcdef,$76543210,$10203040,$50607080,$90a0b0c0,$d0e0f000
 dc.l $11111110,$22222220,$33333330,$44444440,$55555550,$66666660,$77777770
time_matrix_result: dc.l 0
 cnop 0,4
time_matrix_original: dcb.b TIME_MATRIX_SIZE,0
 cnop 0,4
time_matrix_candidate: dcb.b TIME_MATRIX_SIZE,0
 cnop 0,4
TIME_MATRIX_CASES = 64
time_matrix_cases:
 dc.w $0000,$0000,$0000
 dc.w $0000,$0000,$0001
 dc.w $0000,$0000,$4000
 dc.w $0000,$0000,$ffff
 dc.w $0001,$0000,$0000
 dc.w $0000,$0001,$0000
 dc.w $8000,$ffff,$000f
 dc.w $000f,$0001,$0010
 dc.w $7fff,$8000,$ffff
 dc.w $ffff,$ffff,$ffff
 dc.w $b4a5,$e306,$25d3
 dc.w $17ac,$2928,$66c2
 dc.w $b219,$4c06,$d7e4
 dc.w $9384,$49e9,$971d
 dc.w $3817,$ef90,$8b7e
 dc.w $23d0,$fe09,$c6c1
 dc.w $01ca,$cbd6,$eae4
 dc.w $eeed,$9bcb,$5e41
 dc.w $dcbe,$0179,$9498
 dc.w $c78e,$9859,$f1cd
 dc.w $82cb,$db72,$1492
 dc.w $ecb7,$2f0f,$178d
 dc.w $1e9d,$1880,$e8ee
 dc.w $3099,$eed7,$30cf
 dc.w $bfc5,$fee3,$69ae
 dc.w $3b0b,$abcc,$dc9f
 dc.w $aeb1,$c0ee,$da8d
 dc.w $1173,$ace4,$3a9d
 dc.w $0fe6,$b7ee,$d40d
 dc.w $e9d2,$468c,$6d6c
 dc.w $aacf,$3166,$99b6
 dc.w $51ec,$4d7f,$da11
 dc.w $0ef9,$f33d,$38fa
 dc.w $4f9d,$2fe1,$acbb
 dc.w $302d,$2785,$15a0
 dc.w $0471,$b0c8,$2b4f
 dc.w $edd9,$6376,$e3ae
 dc.w $b239,$119b,$9822
 dc.w $ef7a,$a05f,$61b4
 dc.w $9893,$9494,$b838
 dc.w $968e,$b94d,$4aa3
 dc.w $219d,$89bb,$d851
 dc.w $9129,$b547,$7120
 dc.w $f47c,$32e7,$4d6f
 dc.w $1093,$8075,$0814
 dc.w $ac14,$997d,$7e41
 dc.w $2380,$0c49,$12e2
 dc.w $2f02,$5528,$0080
 dc.w $b032,$2352,$2171
 dc.w $5f8b,$3762,$b513
 dc.w $f4f5,$d77c,$eb8f
 dc.w $5727,$fd55,$f6af
 dc.w $bd04,$f6bc,$7bfe
 dc.w $1058,$d247,$c87b
 dc.w $6820,$5130,$1ea0
 dc.w $e1bc,$f820,$45d1
 dc.w $a295,$d8a3,$586e
 dc.w $feba,$edb4,$e2c0
 dc.w $3eb2,$5655,$9df5
 dc.w $fc42,$23b0,$62ae
 dc.w $67e5,$34fc,$05de
 dc.w $5b4b,$9f00,$3eb9
 dc.w $1b38,$bc0c,$a6e6
 dc.w $652d,$b322,$62f1
