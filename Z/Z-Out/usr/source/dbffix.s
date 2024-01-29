;*---------------------------------------------------------------------------
;  :Modul.	dbffix.s
;  :Contents.	routine to fix empty dbf loops
;		the dbf loop will be replaced by a wait based on the vertical
;		raster position
;  :Version.	$Id: dbffix.s 1.3 1999/10/07 20:23:38 jah Exp wepl $
;  :History.	19.03.99 written based on the stfix routine
;		07.10.99 some documentation mistakes fixed
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*
;
; this will patch sequences of the following form:
;		move.w	#$xxxx,dn	;3x3c xxxx
;	.loop	dbf	dn,.loop	;51cx fffe
;
; if a label PATCHCOUNT does exist, the amount of patches will be count in
; the memory region specified in A2
;
; IN:	A0 = APTR start of memory to patch
;	A1 = APTR end of memory to patch
;	A2 = APTR space for patch routine (only if PATCHCOUNT is used)
; OUT:	A2 = APTR points to the end of patch routine (if PATCHCOUNT is used)

_dbffix		movem.l	d0-d1/a0-a1,-(a7)

	IFD PATCHCOUNT
		clr.l	(a2)+			;counters = 0
		clr.l	(a2)+			;counters = 0
	ENDC

		subq.l	#6,a1
.loop		cmp.w	#$fffe,(6,a0)		;loop distance
		bne	.next
		move.w	(a0),d0
		and.w	#$f1ff,d0
		cmp.w	#$303c,d0		;move.w #$xxxx,d0
		bne	.next
		move.w	(a0),d0
		and.w	#$0e00,d0		;register number
		rol.w	#7,d0
		or.w	#$51c8,d0		;dbf d0,_xxx
		cmp.w	(4,a0),d0
		bne	.next

	IFD PATCHCOUNT
		and.w	#7,d0			;register number
		addq.b	#1,(-8,a2,d0.w)
	ENDC

		moveq	#0,d1			;clear high word
		move.w	(2,a0),d1		;loop counter
		divu	#34,d1
		move.w	#$4eb9,(a0)+		;JSR (xxxxxxxx.L)
		pea	(.wait,pc)
		move.l	(a7)+,(a0)+
		move.w	d1,(a0)

.next		addq.l	#2,a0
		cmp.l	a0,a1
		bhi	.loop

		movem.l	(a7)+,d0-d1/a0-a1
		rts

.wait		movem.l	d0-d1/a0,-(a7)
		move.l	(12,a7),a0		;return PC
		move.w	(a0)+,d1		;loop counter
		move.l	a0,(12,a7)		;return PC
.1		move.b	($dff006),d0
.2		cmp.b	($dff006),d0
		beq	.2
		dbf	d1,.1
		movem.l	(a7)+,d0-d1/a0
		rts

