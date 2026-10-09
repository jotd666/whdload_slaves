; VERIFY runtime copies for future twins. No game code bytes are embedded here.
; Copy after relocation, before any performance patch. Relative branches stay
; inside each body; absolute data/callback references retain the game's context.
ORIG_MIRROR_SIZE = $30572-$304d0
ORIG_PROJECT_SIZE = $38dcc-$38c82
ORIG_CLIP_SIZE = $39ecc-$39df2

verify_copy_originals:
	movem.l d0-a6,-(sp)
	move.l a1,a3
	lea originals_header(pc),a4
	move.l a3,a0
	adda.l #$304d0,a0
	lea original_mirror(pc),a2
	move.l a2,24(a4)
	move.w #ORIG_MIRROR_SIZE/2-1,d0
	bsr.b .copy
	move.l a3,a0
	adda.l #$38c82,a0
	lea original_project(pc),a2
	move.l a2,36(a4)
	move.w #ORIG_PROJECT_SIZE/2-1,d0
	bsr.b .copy
	move.l a3,a0
	adda.l #$39df2,a0
	lea original_clip(pc),a2
	move.l a2,48(a4)
	move.w #ORIG_CLIP_SIZE/2-1,d0
	bsr.b .copy
	move.l _resload(pc),a2
	jsr resload_FlushCache(a2)
	movem.l (sp)+,d0-a6
	rts
.copy
	move.w (a0)+,(a2)+
	dbf d0,.copy
	rts
	CNOP 0,4
originals_header:
	dc.b "RBORIG01"
	dc.l 1,3
	dc.l $304d0,ORIG_MIRROR_SIZE,0
	dc.l $38c82,ORIG_PROJECT_SIZE,0
	dc.l $39df2,ORIG_CLIP_SIZE,0
original_mirror: dcb.b ORIG_MIRROR_SIZE,0
original_project: dcb.b ORIG_PROJECT_SIZE,0
original_clip: dcb.b ORIG_CLIP_SIZE,0
