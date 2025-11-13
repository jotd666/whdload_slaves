* $Id: freeanim.s 1.2 2019/01/01 21:01:53 wepl Exp wepl $
**************************************************************************
*   FREEANIM-LIBRARY                                                     *
**************************************************************************
**************************************************************************
*   INITIALIZATION                                                       *
**************************************************************************

	include	lvo/intuition.i

FRANINIT	move.l	_franbase(pc),d0
		beq	.init
		rts

.init		
		move.l	#10,d0		; at random
		move.l	#2,d1		; at random
		lea	_franname(pc),a0
		bsr	_InitLibrary
		lea	_franbase(pc),a0
		move.l	d0,(a0)
		move.l	d0,a0
		
		rts

