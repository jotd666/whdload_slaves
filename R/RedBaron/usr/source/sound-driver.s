; W3 S3: exact quotient for a product of two unsigned bytes.
; File offsets use sound: notation; loaded hunk 0 starts at sound:0028.
; PERF_RANGE sound:00c50 10 bit=12
; PERF_RANGE sound:00c76 10 bit=12
; PERF_RANGE sound:00c9a 10 bit=12
sound_driver_loadseg:
	movem.l d0-a6,-(sp)
	lsl.l #2,d0
	move.l d0,a0
	; Any other executable starts a new scope. Only perf_apply_v1 authorizes
	; patches again; menu sound and unsupported sim versions stay original.
	cmp.b #12,(a0)+
	bne .reset
	lea sound_driver_name(pc),a1
	moveq #11,d2
.name
	cmpm.b (a0)+,(a1)+
	bne .reset
	dbf d2,.name
	lsl.l #2,d1
	addq.l #4,d1
	lea sound_driver_code(pc),a0
	move.l d1,(a0)
	IFD VERIFY
	lea sound_load_header(pc),a0
	addq.l #1,12(a0)
	move.l d1,16(a0)
	ENDC
	bsr sound_driver_install
	bra.b .done
.reset
	lea sound_sim_active(pc),a1
	clr.w (a1)
	lea sound_driver_code(pc),a1
	clr.l (a1)
.done
	movem.l (sp)+,d0-a6
	rts
sound_driver_name: dc.b "amigasnd.drv"
	even
sound_sim_active: dc.w 0
sound_driver_code: dc.l 0

sound_driver_install:
	movem.l d0-a6,-(sp)
	move.w sound_sim_active(pc),d0
	beq .done
	btst #4,perf_mask+2(pc)
	beq .done
	move.l sound_driver_code(pc),d0
	beq .done
	move.l d0,a1
	move.l _resload(pc),a2
	; Check the operand masks/product as well as the replaced ten bytes.
	lea sound_div_expected(pc),a0
	moveq #20,d1
	move.l #$c46-$28,d0
	bsr perf_check_bytes
	move.l #$c6c-$28,d0
	bsr perf_check_bytes
	move.l #$c90-$28,d0
	bsr perf_check_bytes
	IFD VERIFY
	btst #7,perf_custom5+2(pc) ; CUSTOM5 bit 15
	beq .fast
	bsr sound_div_selftest
	move.l sound_driver_code(pc),a1
	lea sound_div_verify_patch(pc),a0
	bsr sound_install_patch
	bra .flush
.fast
	ENDC
	lea sound_div_patch(pc),a0
	bsr sound_install_patch
.flush
	jsr resload_FlushCache(a2)
.done
	movem.l (sp)+,d0-a6
	rts

; Install interrupt code atomically even when called from a live flight anchor.
; Exec's nesting keeps a previously disabled caller disabled on return.
sound_install_patch:
	movem.l d0-a6,-(sp)
	move.l 4.w,a6
	jsr _LVODisable(a6)
	movem.l (sp),d0-a6
	jsr resload_Patch(a2)
	jsr resload_FlushCache(a2)
	move.l 4.w,a6
	jsr _LVOEnable(a6)
	movem.l (sp)+,d0-a6
	rts

SOUND_DIV_QUOTIENT:MACRO
	addq.w #1,d4
	mulu.w #$1041,d4
	swap d4
	lsr.w #2,d4
	ENDM
sound_div_patch:
	PL_START
	PL_DATA $c50-$28,10
	SOUND_DIV_QUOTIENT
	PL_DATA $c76-$28,10
	SOUND_DIV_QUOTIENT
	PL_DATA $c9a-$28,10
	SOUND_DIV_QUOTIENT
	PL_END
sound_div_expected:
	and.w #255,d3
	and.w #255,d4
	mulu.w d3,d4
	swap d4
	clr.w d4
	swap d4
	divu.w #63,d4
sound_div_fast:
	SOUND_DIV_QUOTIENT
sound_div_fast_end:
	IFNE sound_div_fast_end-sound_div_fast-10
	FAIL "S3 must fit the original ten-byte range"
	ENDC
	rts

	IFD VERIFY
sound_div_verify_patch:
	PL_START
	PL_PSS $c50-$28,sound_div_twin,4
	PL_PSS $c76-$28,sound_div_twin,4
	PL_PSS $c9a-$28,sound_div_twin,4
	PL_END
; This local twin consumes the actual product at every executed divide. It
; checks the observable quotient before any driver state or hardware write.
; The high word of d4 and flags are dead: the next arithmetic masks its byte,
; the VOL writer uses its word, and the caller's ADDQ overwrites X before use.
sound_div_twin:
	movem.l d0/a0,-(sp)
	cmp.l #65025,d4
	bhi sound_div_fail
	move.l d4,d0
	divu.w #63,d0
	bsr sound_div_fast
	cmp.w d0,d4
	bne sound_div_fail
	lea sound_div_header(pc),a0
	addq.l #1,12(a0)
	movem.l (sp)+,d0/a0
	rts
sound_div_selftest:
	movem.l d0-a6,-(sp)
	move.l #65025,d5
.case
	move.l d5,d4
	bsr sound_div_twin
	subq.l #1,d5
	bpl.b .case
	lea sound_div_header(pc),a0
	add.l #65026,16(a0)
	movem.l (sp)+,d0-a6
	rts
sound_div_fail:
	pea sound_div_message(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
sound_div_message: dc.b "Red Baron: sound volume division mismatch",0
	even
sound_div_header: dc.b "RBSDIV01"
	dc.l 1,0,0 ; version, all successful twins, exhaustive synthetic twins
sound_load_header: dc.b "RBSLOAD1"
	dc.l 1,0,0 ; version, LoadSeg count, most recent sound:0028 entry
	ENDC
