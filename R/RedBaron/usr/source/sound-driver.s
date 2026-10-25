; sound S3: exact quotient for a product of two unsigned bytes.
; File offsets use sound: notation; loaded hunk 0 starts at sound:0028.
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
