; VERIFY-only W6 experiment. CUSTOM4 forces the primary dt at each flight
; input checkpoint. Zero is observation-only. Secondary dt, menus and original
; clock arithmetic remain unchanged. Never use forced runs for FPS claims.
; a1 is h3; preserve every input register. No additional sim-code hook.
time_probe_step:
	movem.l d0/a0,-(sp)
	; CUSTOM5 bit 18: one synthetic low-altitude descent at first flight.
	; Deliberately changes initial conditions; never a normal mission sample.
	move.l tape_game_steps(pc),d0
	cmp.l #1,d0
	bne.b .clock
	btst #2,perf_custom5+1(pc)
	beq.b .clock
	move.l $4578(a1),a0
	move.l #512,16(a0)
	move.w #-1024,$f8(a0)
	move.w #-1024,$fe(a0)
	move.w #-220,$ce(a0)
	move.w #-220,$d4(a0)
	clr.w $104(a0)
.clock
	move.l perf_custom4(pc),d0
	beq.b .done
	cmp.l #100,d0
	beq.b .force
	cmp.l #225,d0
	beq.b .force
	cmp.l #450,d0
	beq.b .force
	cmp.l #900,d0
	beq.b .force
	cmp.l #2200,d0
	beq.b .force
	pea perf_mismatch(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
.force
	move.w d0,$4834(a1)
.done
	; CUSTOM5 bit 19: hold the native fire key for projectile tests.
	btst #3,perf_custom5+1(pc)
	beq.b .return
	move.l tape_keybase(pc),a0
	move.b #1,$40(a0)
.return
	movem.l (sp)+,d0/a0
	rts
