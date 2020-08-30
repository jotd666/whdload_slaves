;*---------------------------------------------------------------------------
;  :Modul.	nonvolatile.s
;  :Contents.	reimplementation of nonvolatile.library
;		will be constructed directly in memory
;		all data will be written to single file 'nvram'
;  :Author.	Wepl
;  :Version.	$Id: nonvolatile.s 1.2 2018/08/21 01:23:59 wepl Exp wepl $
;  :History.	22.03.18 created for game UFO
;		17.08.18 made compatible to vasm
;		21.08.18 _GetNVInfo fixed
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	BASM 2.16, ASM-One 1.44, Asm-Pro 1.17, PhxAss 4.38
;  :To Do.
;---------------------------------------------------------------------------*

	INCLUDE	exec/initializers.i
	INCLUDE	libraries/nonvolatile.i

;============================================================================
; this creates the library, must be called once at startup

_nonvolatile_init
		movem.l	a2/a6,-(a7)
		lea	(.name,pc),a0
		lea	(.struct_name+2,pc),a1
		move.l	a0,(a1)
		move.l	#LIB_SIZE,d0		;data size
		moveq	#0,d1			;segment list
		lea	(.vectors,pc),a0
		lea	(.structure,pc),a1
		sub.l	a2,a2
		move.l	(4),a6
		jsr	(_LVOMakeLibrary,a6)
		move.l	d0,a1
		jsr	(_LVOAddLibrary,a6)
		movem.l	(a7)+,a2/a6
		rts

.structure	INITBYTE LN_TYPE,NT_LIBRARY
.struct_name	INITLONG LN_NAME,0
		INITBYTE LIB_FLAGS,LIBF_CHANGED|LIBF_SUMUSED
		INITWORD LIB_VERSION,40
		dc.w	0

.vectors	dc.w	-1
		dc.w	_nv_Open-.vectors
		dc.w	_nv_Close-.vectors
		dc.w	_nv_Expunge_ExtFunc-.vectors
		dc.w	_nv_Expunge_ExtFunc-.vectors
		dc.w	_GetCopyNV-.vectors
		dc.w	_FreeNVData-.vectors
		dc.w	_StoreNV-.vectors
		dc.w	_DeleteNV-.vectors
		dc.w	_GetNVInfo-.vectors
		dc.w	_GetNVList-.vectors
		dc.w	_SetNVProtection-.vectors
		dc.w	-1

.name		dc.b	"nonvolatile.library",0
_nv_filename	dc.b	"nvram",0
	EVEN

_nv_Open	addq	#1,(LIB_OPENCNT,a6)
		move.l	a6,d0
		rts
_nv_Close	subq	#1,(LIB_OPENCNT,a6)
_nv_Expunge_ExtFunc
		moveq	#0,d0
		rts

	STRUCTURE wnv_entry,0			;file structure used
		STRUCT	wnv_app,32
		STRUCT	wnv_item,32
		ULONG	wnv_length
		LABEL	wnv_SIZEOF

;-----------------------
; return a copy of an item stored in nonvolatile storage
; IN:	A0 = CPTR appName
;	A1 = CPTR itemName
;	D1 = BOOL killRequesters
; OUT:	D0 = APTR data

_GetCopyNV	movem.l	d6-d7/a0-a3/a6,-(a7)
		bsr	_nv_load
		move.l	d0,d6			;D6 = memory
		beq	.quit
		move.l	d0,d7			;D7 = length
	;search
		move.l	d7,d0
		move.l	(8,a7),a0
		move.l	(12,a7),a1
		move.l	d6,a2
		bsr	_nv_search
		tst.l	d0
		bne	.found
	;free memory
		move.l	d6,a1
		jsr	(_LVOFreeVec,a6)
		moveq	#0,d0
		bra	.quit
	;set return
.found		move.l	d0,a0
		move.l	(wnv_length,a0),d1
		addq.l	#4,d1
		add	#wnv_SIZEOF,a0
		move.l	a0,d0
		move.l	d1,-(a0)		;compatibility size+4
		move.l	d6,-(a0)		;for FreeNVData
.quit		movem.l	(a7)+,d6-d7/a0-a3/a6
		rts

;-----------------------
; load nvram
; IN:	-
; OUT:	D0 = APTR  data
;	D1 = ULONG length

_nv_load	movem.l	d6-d7/a3/a6,-(a7)
		lea	(_nv_filename,pc),a0
		move.l	(_resload,pc),a3
		jsr	(resload_GetFileSize,a3)
		beq	.quit
		move.l	d0,d7			;D7 = length
		moveq	#MEMF_ANY,d1
		move.l	(4),a6
		jsr	(_LVOAllocVec,a6)
		move.l	d0,d6			;D6 = memory
		beq	.quit
		lea	(_nv_filename,pc),a0
		move.l	d6,a1
		jsr	(resload_LoadFile,a3)
		move.l	d6,d0
		move.l	d7,d1
.quit		movem.l	(a7)+,d6-d7/a3/a6
		rts

;-----------------------
; search app/item in loaded nvram
; IN:	A0 = CPTR  appName
;	A1 = CPTR  itemName
;	A2 = APTR  loaded nvram
;	D0 = ULONG size of loaded nvram
; OUT:	D0 = APTR  data

_nv_search	movem.l	a0-a3,-(a7)
		lea	(a2,d0.l),a3		;A3 = end of nvram
.loop		move.l	(a7),a0
		lea	(wnv_app,a2),a1
.cmpapp		move.b	(a0)+,d0
		cmp.b	(a1)+,d0
		bne	.next
		tst.b	d0
		bne	.cmpapp
		move.l	(4,a7),a0
		lea	(wnv_item,a2),a1
.cmpitem	move.b	(a0)+,d0
		cmp.b	(a1)+,d0
		bne	.next
		tst.b	d0
		bne	.cmpitem
		move.l	a2,d0
		bra	.quit
.next		add.l	(wnv_length,a2),a2
		add	#wnv_SIZEOF,a2
		cmp.l	a2,a3
		bhi	.loop
		moveq	#0,d0
.quit		movem.l	(a7)+,a0-a3
		rts

;-----------------------
; release the memory allocated by a function of this library
; IN:	A0 = APTR data
; OUT:	-

_FreeNVData	move.l	a6,-(a7)
		move.l	a0,d0
		beq	.quit
		move.l	(-8,a0),a1
		move.l	(4),a6
		jsr	(_LVOFreeVec,a6)
.quit		move.l	(a7)+,a6
		rts

;-----------------------
; store data in nonvolatile storage
; IN:	A0 = CPTR  appName
;	A1 = CPTR  itemName
;	A2 = APTR  data
;	D0 = ULONG length
;	D1 = BOOL  killRequesters
; OUT:	D0 = UWORD error

_StoreNV	movem.l	d5-d7/a0-a2/a6,-(a7)
		moveq	#0,d7			;D7 = length
		move.l	d0,d5
		mulu	#10,d5			;D5 = new length
		bsr	_nv_load
		move.l	d0,d6			;D6 = memory
		beq	.new
		move.l	d1,d7			;D7 = length
	;search
		move.l	(3*4,a7),a0		;app
		move.l	(4*4,a7),a1		;item
		move.l	d6,a2
		move.l	d7,d0
		bsr	_nv_search
		tst.l	d0
		beq	.append
		move.l	d0,a2
		cmp.l	(wnv_length,a2),d5
		bne	.mismatch
	;replace
		move.l	d5,d0			;length
		move.l	a2,d1
		add.l	#wnv_SIZEOF,d1
		sub.l	d6,d1			;offset
		lea	(_nv_filename,pc),a0
		move.l	(5*4,a7),a1
		move.l	(_resload,pc),a6
		jsr	(resload_SaveFileOffset,a6)
	;free
		move.l	d6,a1
		move.l	(4),a6
		jsr	(_LVOFreeVec,a6)
.success	moveq	#0,d0
.quit		movem.l	(a7)+,d5-d7/a0-a2/a6
		rts

.append		move.l	d6,a1
		move.l	(4),a6
		jsr	(_LVOFreeVec,a6)
.new		move.l	#wnv_SIZEOF,d0
		move.l	#MEMF_CLEAR,d1
		move.l	(4),a6
		jsr	(_LVOAllocVec,a6)
		move.l	d0,d6			;D6 = memory
		beq	.failed
		move.l	d0,a2
		move.l	(3*4,a7),a0
		lea	(wnv_app,a2),a1
.cpyapp		move.b	(a0)+,(a1)+
		bne	.cpyapp
		move.l	(4*4,a7),a0
		lea	(wnv_item,a2),a1
.cpyitem	move.b	(a0)+,(a1)+
		bne	.cpyitem
		move.l	d5,(wnv_length,a2)

		move.l	#wnv_SIZEOF,d0		;length
		move.l	d7,d1			;offset
		lea	(_nv_filename,pc),a0
		move.l	a2,a1
		move.l	(_resload,pc),a6
		jsr	(resload_SaveFileOffset,a6)

		move.l	d5,d0			;length
		moveq	#wnv_SIZEOF,d1
		add.l	d7,d1			;offset
		lea	(_nv_filename,pc),a0
		move.l	(5*4,a7),a1
		jsr	(resload_SaveFileOffset,a6)

		move.l	d6,a1
		move.l	(4),a6
		jsr	(_LVOFreeVec,a6)
		bra	.success

.mismatch
.failed		illegal

;-----------------------
; remove an entry from nonvoltatile storage
; IN:	A0 = CPTR appName
;	A1 = CPTR itemName
;	D1 = BOOL killRequesters
; OUT:	D0 = BOOL success

_DeleteNV	moveq	#0,d0			;not implemented, always fails
		rts

;-----------------------
; report information on the current nonvolatile storage
; IN:	D1 = BOOL killRequesters
; OUT:	D0 = APTR struct NVInfo

_GetNVInfo	move.l	a6,-(a7)
		move.l	#8+NVINFO_SIZE,d0
		move.l	#MEMF_ANY,d1
		move.l	(4),a6
		jsr	(_LVOAllocVec,a6)
		tst.l	d0
		beq	.quit
		move.l	d0,a0
		move.l	a0,(a0)+		;for FreeNVData
		moveq	#12,d1
		move.l	d1,(a0)+		;data length
		move.l	a0,d0
		move.l	#100000,(a0)+		;nvi_MaxStorage
		move.l	#100000,(a0)+		;nvi_FreeStorage
.quit		move.l	(a7)+,a6
		rts

;-----------------------
; return a list of the items stored in nonvolatile storage
; IN:	A0 = CPTR appName
;	D1 = BOOL killRequesters
; OUT:	D0 = APTR struct MinList

_GetNVList	movem.l	d4-d7/a0/a2-a4/a6,-(a7)
	;load nvram
		bsr	_nv_load
		move.l	d0,d6			;D6 = memory
		beq	.quit
		move.l	d0,d7			;D7 = length
	;count entries
		moveq	#0,d5			;D5 = count
		move.l	d6,a2
		lea	(a2,d7.l),a3		;A3 = end of nvram
.count		move.l	(4*4,a7),a0
		lea	(wnv_app,a2),a1
.cmpapp		move.b	(a0)+,d0
		cmp.b	(a1)+,d0
		bne	.next
		tst.b	d0
		bne	.cmpapp
		addq.l	#1,d5
.next		add.l	(wnv_length,a2),a2
		add	#wnv_SIZEOF,a2
		cmp.l	a2,a3
		bhi	.count
	;alloc
		moveq	#NVENTRY_SIZE+32,d0	;entry + item name
		mulu	d5,d0
		add.l	#8+MLH_SIZE,d0		;header + min list header
		move.l	#MEMF_CLEAR,d1
		move.l	(4),a6
		jsr	(_LVOAllocVec,a6)
		tst.l	d0
		beq	.ill
		move.l	d0,a4			;A4 = memory
	;fill
		move.l	a4,(a4)+		;for FreeNVData
		clr.l	(a4)+
		move.l	a4,d4			;D4 = list, rc
		NEWLIST	a4
		add	#MLH_SIZE,a4
	;loop
		move.l	d6,a2
		lea	(a2,d7.l),a3		;A3 = end of nvram
.copy		move.l	(4*4,a7),a0
		lea	(wnv_app,a2),a1
.cmpapp2	move.b	(a0)+,d0
		cmp.b	(a1)+,d0
		bne	.next2
		tst.b	d0
		bne	.cmpapp2
	;add item
		lea	(wnv_item,a2),a0
		move.l	a4,a1
.cpyitem	move.b	(a0)+,(a1)+
		bne	.cpyitem
		move.l	a4,(32+nve_Name,a4)
		add.w	#32,a4			;item name
		move.l	(wnv_length,a2),(nve_Size,a4)
		move.l	d4,a0			;list
		move.l	a4,a1			;node
		ADDTAIL
		add.w	#NVENTRY_SIZE,a4
	;next
.next2		add.l	(wnv_length,a2),a2
		add	#wnv_SIZEOF,a2
		cmp.l	a2,a3
		bhi	.copy
	;free nvram
		move.l	d6,a1
		jsr	(_LVOFreeVec,a6)
		move.l	d4,d0
.quit		movem.l	(a7)+,d4-d7/a0/a2-a4/a6
		rts

.ill		illegal

;-----------------------
; set the protection flags
; IN:	A0 = CPTR appName
;	A1 = CPTR itemName
;	D1 = BOOL killRequesters
;	D2 = LONG mask
; OUT:	D0 = BOOL success

_SetNVProtection
		moveq	#0,d0		;not implemented, always fails
		rts

;============================================================================

