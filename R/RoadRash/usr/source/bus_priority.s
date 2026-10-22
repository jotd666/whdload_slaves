; Race-only CPU/blitter sharing on 040/060. The enhanced-path gate has
; already selected CPU and Fast RAM. The caller saves all registers.
; Native startup's temporary copper list sets BLTPRI; save its value once
; across prepare/reset and restore it on each native race/demo hook removal.
step_priority_begin:
	btst #3,cpu_attention+3(pc) ; AFF_68040 also applies to 060
	beq .done
	lea step_priority_saved(pc),a0
	tst.w (a0)
	bmi .clear
	move.w $dff002,d0       ; read DMACONR, never write-only DMACON
	andi.w #$0400,d0
	ori.w #$8000,d0        ; active, including a previously clear priority bit
	move.w d0,(a0)
.clear:
	move.w #$0400,$dff096
.done:
	rts

step_priority_end:
	movem.l d0-d1/a0,-(a7)
	lea step_priority_saved(pc),a0
	move.w (a0),d0
	bpl .done
	move.w #$0400,d1
	btst #10,d0
	beq .restore
	ori.w #$8000,d1
.restore:
	move.w d1,$dff096
	clr.w (a0)
.done:
	movem.l (a7)+,d0-d1/a0
	clr.l $a5916           ; original instruction, including condition codes
public_ref_25 equ *-4
	rts
step_priority_saved:
	dc.w 0
