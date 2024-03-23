;--------------------------------

	; version dependency handling

;----------

VD_START:	MACRO
	VD_CODE
	CNOP	0,4
_vd_VER:	dc.l	0
_vd_TAB:	equ	*
	ENDM

;----------

VD_END:	MACRO
_vd_SIZEOF:	equ	*-_vd_TAB
	ENDM

;----------

VD_VERSION_START: MACRO
_vd_DAT:	equ	*
	ENDM

;----------

VD_VERSION:	MACRO
	dc.w	\1,\2
	ENDM

;----------

VD_VERSION_END: MACRO
	dc.w	-1,-1
	ENDM

;--------------------------------

VD_CODE:	MACRO

;--------------------------------

_vd_Initialise:
	movem.l	d0-7/a0-6,-(a7)

;-----
	IFD	VD_DISK_OFS

	; determine game version from disk image

	IFND	VD_DISK_LEN
	FAIL	"VD_DISK_LEN not defined"
	ENDC
	IFND	VD_DISK_BUF
VD_DISK_BUF:	equ	$10000
	ENDC

	move.l	#VD_DISK_OFS,d0
	move.l	#VD_DISK_LEN,d1
	moveq	#1,d2
	lea	VD_DISK_BUF,a0
	move.l	_resload(pc),a2
	movem.l	d1/a0/a2,-(a7)
	jsr	resload_DiskLoad(a2)
	movem.l	(a7)+,d0/a0/a2
	jsr	resload_CRC16(a2)

	ELSE

	; determine game version from file

	IFND	VD_FILE_LEN
	FAIL	"VD_FILE_LEN not defined"
	ENDC
	IFND	VD_FILE_BUF
VD_FILE_BUF:	equ	$10000
	ENDC

	lea	VD_FILE_NAM(pc),a0
	move.l	#VD_FILE_BUF,a1
	move.l	_resload(pc),a2
	movem.l	a1/a2,-(a7)
	jsr	resload_LoadFileDecrunch(a2)
	movem.l	(a7)+,a0/a2
	move.l	#VD_FILE_LEN,d0
	jsr	resload_CRC16(a2)
	ENDC
;-----

	; get version number & dependency data pointer
	; d0.w=CRC value

	lea	_vd_DAT(pc),a0
.vdi_getgamver:
	move.l	(a0)+,d1		; d1=version number,CRC
	bmi	_badver
	cmp.w	d1,d0		; compare CRC
	beq.s	.vdi_gotgamver
	lea	_vd_SIZEOF(a0),a0
	bra.s	.vdi_getgamver

.vdi_gotgamver:
	lea	_vd_VER(pc),a1	; set game version
	clr.w	d1
	swap	d1
	move.l	d1,(a1)+

	moveq	#_vd_SIZEOF>>2-1,d0	; copy vd data to master variables
.vdi_inigamver:
	move.l	(a0)+,(a1)+
	dbf	d0,.vdi_inigamver

	movem.l	(a7)+,d0-7/a0-6	; all done
	rts

;--------------------------------

	ENDM	; VD_CODE
