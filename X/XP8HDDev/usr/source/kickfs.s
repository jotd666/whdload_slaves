;*---------------------------------------------------------------------------
;  :Modul.	kickfs.s
;  :Contents.	filesystem handler for kick emulation under WHDLoad
;  :Author.	Wepl
;  :Version.	$Id: kickfs.s 1.3 2002/05/09 14:19:15 wepl Exp wepl $
;  :History.	17.04.02 separated from kick13.s
;		02.05.02 _cb_dosRead added
;		09.05.02 symbols moved to the top for Asm-One/Pro
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly 2.9, Asm-Pro 1.16, PhxAss 4.38
;  :To Do.	.buildname: support for relative paths
;		more dos packets (maybe)
;---------------------------------------------------------------------------*

	INCLUDE	lvo/expansion.i
	INCLUDE	dos/dosextens.i
	INCLUDE	dos/filehandler.i
	INCLUDE	exec/resident.i
	INCLUDE	libraries/configvars.i
	INCLUDE	libraries/expansionbase.i

;---------------------------------------------------------------------------*
;
; BootNode
; 08 LN_TYPE = NT_BOOTNODE
; 0a LN_NAME -> ConfigDev
;		10 cd_Rom+er_Type = ERTF_DIAGVALID
;		1c cd_Rom+er_Reserved0c -> DiagArea
;					   00 da_Config = DAC_CONFIGTIME
;					   06 da_BootPoint -> .bootcode
;					   0e da_SIZEOF
;		44 cd_SIZEOF
; 10 bn_DeviceNode -> DeviceNode (exp.MakeDosNode)
*		      04 dn_Type = 2
;		      24 dn_SegList -> .seglist
;		      2c dn_SIZEOF
; 14 bn_SIZEOF

	IFND	HD_Cyls
HD_Cyls			= 80
	ENDC
HD_Surfaces		= 2
HD_BlocksPerTrack	= 11
HD_NumBlocksRes		= 2
HD_NumBlocks		= HD_Cyls*HD_Surfaces*HD_BlocksPerTrack-HD_NumBlocksRes
HD_NumBlocksUsed	= HD_NumBlocks/2
HD_BytesPerBlock	= 512
HD_NumBuffers		= 5

	;file locking is not implemented! no locklist is used
	;fl_Key is used for the filename which makes it impossible to compare two locks for equality!

	STRUCTURE MyLock,fl_SIZEOF
		LONG	mfl_pos			;position in file
		STRUCT	mfl_fib,fib_Reserved	;FileInfoBlock
	IFD IOCACHE
		LONG	mfl_cpos		;fileoffset cache points to
		LONG	mfl_clen		;amount data in cache (valid only on write cache)
		LONG	mfl_iocache
	ENDC
		LABEL	mfl_SIZEOF

		movem.l	d0-a6,-(a7)

		moveq	#ConfigDev_SIZEOF,d0
		move.l	#MEMF_CLEAR,d1
		move.l	(4),a6
		jsr	(_LVOAllocMem,a6)
		move.l	d0,a5				;A5 = ConfigDev
		bset	#ERTB_DIAGVALID,(cd_Rom+er_Type,a5)
		lea	(.diagarea,pc),a0
		move.l	a0,(cd_Rom+er_Reserved0c,a5)

		lea	(.expansionname,pc),a1
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a4				;A4 = expansionbase

		lea	(.parameterPkt+4,pc),a0
		lea	(.handlername,pc),a1
		move.l	a1,-(a0)
		move.l	a4,a6
		jsr	(_LVOMakeDosNode,a6)
		move.l	d0,a3				;A3 = DeviceNode
		lea	(.seglist,pc),a1
		move.l	a1,d1
		lsr.l	#2,d1
		move.l	d1,(dn_SegList,a3)
		move.l	a2,(dn_GlobalVec,a3)		;no BCPL shit (A2 = -1)

		bsr	.create_fssm

		moveq	#BootNode_SIZEOF,d0
		move.l	#MEMF_CLEAR,d1
		move.l	(4),a6
		jsr	(_LVOAllocMem,a6)
		move.l	d0,a1				;BootNode
		move.b	#NT_BOOTNODE,(LN_TYPE,a1)
		move.l	a5,(LN_NAME,a1)			;ConfigDev
		move.l	a3,(bn_DeviceNode,a1)

		lea	(eb_MountList,a4),a0
		jsr	(_LVOEnqueue,a6)

		movem.l	(a7)+,d0-a6
		rts

; JOTD

.create_fssm
		movem.l	d0-a6,-(A7)
		move.l	#FileSysStartupMsg_SIZEOF,d0
		move.l	#MEMF_CLEAR,d1
		move.l	(4),a6
		jsr	(_LVOAllocMem,a6)
		move.l	d0,a2
		lsr.l	#2,d0
		move.l	D0,(dn_Startup,a3)	; it is a BPTR

		move.l	#0,(a2)+	; fssm_Unit
		lea	.hddevname(pc),a1
		move.l	a1,d0
		lsr.l	#2,d0
		move.l	d0,(a2)+	; fssm_Device

		lea	.envec(pc),a1
		move.l	a1,d0
		lsr.l	#2,d0
		move.l	d0,(a2)+	; fssm_Environ

		move.l	#0,(A2)+	; fssm_Flags

		movem.l	(a7)+,d0-a6
		rts


	CNOP	0,4

	; "environment" for the device
.envec
	dc.l	DE_DOSTYPE		; Size of Environment vector (in longwords)
	dc.l	HD_BytesPerBlock/4	; in longwords: standard value is 128
	dc.l	0			; not used; must be 0
	dc.l	HD_Surfaces		; # of heads (surfaces). drive specific
	dc.l	1			; not used; must be 1
	dc.l	HD_BlocksPerTrack	; blocks per track. drive specific
	dc.l	HD_NumBlocksRes		; DOS reserved blocks at start of partition.
	dc.l	2			; DOS reserved blocks at end of partition
	dc.l	0			; usually 0
	dc.l	0			; starting cylinder. typically 0
	dc.l	HD_Cyls-1		; max cylinder. drive specific
	dc.l	HD_NumBuffers		; Initial # DOS of buffers.
	dc.l	MEMF_PUBLIC		; type of mem to allocate for buffers
	dc.l	$00100000		; Max number of bytes to transfer at a time
	dc.l	$7ffffffe		; Address Mask to block out certain memory
	dc.l	0			; Boot priority for autoboot (doesn't work)
	dc.l	ID_DOS_DISK+1		; ASCII (HEX) string showing filesystem type;
			     ; 0X444F5300 is old filesystem,
			     ; 0X444F5301 is fast file system

	CNOP	0,4
.hddevname:
	dc.b	11,"jotd.device",0

	CNOP	0,4
.diagarea	dc.b	DAC_CONFIGTIME		;da_Config
		dc.b	0			;da_Flags
		dc.w	0			;da_Size
		dc.w	0			;da_DiagPoint
		dc.w	.bootcode-.diagarea	;da_BootPoint
		dc.w	0			;da_Name
		dc.w	0			;da_Reserved01
		dc.w	0			;da_Reserved02

	CNOP	0,4
.parameterPkt	dc.l	0			;name of dos handler
		dc.l	0			;name of exec device
		dc.l	0			;unit number for OpenDevice
		dc.l	0			;flags for OpenDevice
		dc.l	11			;amount following longwords
		dc.l	HD_BytesPerBlock/4	;longs per block
		dc.l	0			;sector start, unused
		dc.l	HD_Surfaces		;surfaces
		dc.l	1			;sectors per block, unused
		dc.l	HD_BlocksPerTrack	;blocks per track
		dc.l	HD_NumBlocksRes		;reserved blocks
		dc.l	0			;unused
		dc.l	0			;interleave
		dc.l	0			;lower cylinder
		dc.l	HD_Cyls-1		;upper cylinder
		dc.l	HD_NumBuffers		;buffers

.bootcode	lea	(_dosname,pc),a1
		jsr	(_LVOFindResident,a6)
		move.l	d0,a0
		move.l	(RT_INIT,a0),a0
		jmp	(a0)			;init dos.library

	CNOP 0,4
		dc.l	16			;segment length
.seglist	dc.l	0			;next segment

	;get own message port
		move.l	(4),a6			;A6 = execbase
		sub.l	a1,a1
		jsr	(_LVOFindTask,a6)
		move.l	d0,a1
		lea	(pr_MsgPort,a1),a5	;A5 = MsgPort

	;init volume structure
		lea	(.volumename,pc),a0
		move.l	a0,d0
		lsr.l	#2,d0
		move.l	d0,-(a7)		;dl_Name
		clr.l	-(a7)			;dl_unused
		move.l	#ID_DOS_DISK,-(a7)	;dl_DiskType (is normally 0!)
		clr.l	-(a7)			;dl_LockList
		clr.l	-(a7)			;dl_VolumeDate
		clr.l	-(a7)			;dl_VolumeDate
		clr.l	-(a7)			;dl_VolumeDate
		clr.l	-(a7)			;dl_Lock
		move.l	a5,-(a7)		;dl_Task (MsgPort)
		move.l	#DLT_VOLUME,-(a7)	;dl_Type
		clr.l	-(a7)			;dl_Next
		move.l	a7,d0
		lsr.l	#2,d0
		move.l	d0,a3			;A3 = Volume (BPTR)
	;add to the system
		lea	(_dosname,pc),a1
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a0
		move.l	(dl_Root,a0),a0
		move.l	(rn_Info,a0),a0
		add.l	a0,a0
		add.l	a0,a0
		move.l	(di_DevInfo,a0),(dol_Next,a7)
		move.l	a3,(di_DevInfo,a0)

		move.l	(_resload,pc),a2	;A2 = resload

	;fetch and reply startup message
		move.l	a5,a0
		jsr	(_LVOWaitPort,a6)
		move.l	a5,a0
		jsr	(_LVOGetMsg,a6)
		move.l	d0,a4
		move.l	(LN_NAME,a4),a4		;A4 = DosPacket
		moveq	#-1,d0			;success
		bra	.reply1

	;loop on receiving new packets
.mainloop	move.l	a5,a0
		jsr	(_LVOWaitPort,a6)
		move.l	a5,a0
		jsr	(_LVOGetMsg,a6)
		move.l	d0,a4
		move.l	(LN_NAME,a4),a4		;A4 = DosPacket

	;find and call appropriate action
		moveq	#0,d0
		move.l	(dp_Type,a4),d2
		lea	(.action,pc),a0
.next		movem.w	(a0)+,d0-d1
	IFD DEBUG
		tst.l	d0
		beq	_debug1			;unknown packet
	ENDC
		cmp.l	d0,d2
		bne	.next
		jmp	(.action,pc,d1.w)

;---------------
; reply dos-packet
; IN:	D0 = res1
;	D1 = res2

.reply2		move.l	d1,(dp_Res2,a4)

;---------------
; reply dos-packet
; IN:	D0 = res1

.reply1		move.l	d0,(dp_Res1,a4)
		move.l	(dp_Port,a4),a0
		move.l	(dp_Link,a4),a1
		move.l	a5,(dp_Port,a4)
		jsr	(_LVOPutMsg,a6)
		bra	.mainloop

.action		dc.w	ACTION_LOCATE_OBJECT,.a_locate_object-.action		;8	8
		dc.w	ACTION_FREE_LOCK,.a_free_lock-.action			;f	15
		dc.w	ACTION_DELETE_OBJECT,.a_delete_object-.action		;10	16
		dc.w	ACTION_COPY_DIR,.a_copy_dir-.action			;13	19
		dc.w	ACTION_SET_PROTECT,.a_set_protect-.action		;15	21
		dc.w	ACTION_EXAMINE_OBJECT,.a_examine_object-.action		;17	23
		dc.w	ACTION_EXAMINE_NEXT,.a_examine_next-.action		;18	24
		dc.w	ACTION_DISK_INFO,.a_disk_info-.action			;19	25
		dc.w	ACTION_INFO,.a_info-.action				;1a	26
		dc.w	ACTION_FLUSH,.a_flush-.action				;1b	27
		dc.w	ACTION_INHIBIT,.a_inhibit-.action			;1f	31
		dc.w	ACTION_PARENT,.a_parent-.action				;29	41
		dc.w	ACTION_READ,.a_read-.action				;52	82
		dc.w	ACTION_WRITE,.a_write-.action				;57	87
		dc.w	ACTION_FINDUPDATE,.a_findupdate-.action			;3ec	1004
		dc.w	ACTION_FINDINPUT,.a_findinput-.action			;3ed	1005
		dc.w	ACTION_FINDOUTPUT,.a_findoutput-.action			;3ee	1006
		dc.w	ACTION_END,.a_end-.action				;3ef	1007
		dc.w	ACTION_SEEK,.a_seek-.action				;3f0	1008
		dc.w	ACTION_CREATE_DIR,.a_create_dir-.action			;16	22	(JOTD)
		dc.w	ACTION_FH_FROM_LOCK,.a_fh_from_lock-.action		;402	1026	(JOTD)	
		dc.w	ACTION_EXAMINE_FH,.a_examine_fh-.action			;40A	1034	(JOTD)
		dc.w	0

	; conventions for action functions:
	; IN:	a2 = resload
	;	a3 = BPTR volume node
	;	a4 = packet
	;	a5 = MsgPort
	;	a6 = execbase

;---------------

.a_examine_fh:
		move.l	(dp_Arg1,a4),a0		;filehandle
		bsr	.getarg2		;fileinfoblock
		move.l	d7,a1
		move.l	(fl_Key,a0),a0		;filename
		jsr	(resload_Examine,a2)
		tst.l	d0
		bne.b	.ok
		ILLEGAL		; should not happen
.ok
	;return
		moveq	#DOSTRUE,d0
		bra	.reply1

;---------------

.a_fh_from_lock:
		bsr	.getarg1		;handle
		move.l	d7,a0
		bsr	.getarg2		;lock
		move.l	d7,d1
		move.l	d1,(fh_Arg1,a0)		;using the lock we refer the filename later
	;return
		moveq	#DOSTRUE,d0
		bra	.reply1

;---------------

.a_create_dir:
		bsr	.getarg1		;lock
		move.l	d7,d0
		bsr	.getarg2		;name
		move.l	d7,d1

	; WHDLoad does not support directory creation right now

		tst	-1
		illegal

;---------------

.a_locate_object
		bsr	.getarg1		;lock
		move.l	d7,d0
		bsr	.getarg2		;name
		move.l	d7,d1

		move.l	(dp_Arg3,a4),d2		;mode
		bsr	.lock
		lsr.l	#2,d0			;APTR > BPTR
		bne	.reply1
		bra	.reply2

;---------------

.a_free_lock	bsr	.getarg1
		move.l	d7,d0
		bsr	.unlock
		moveq	#DOSTRUE,d0
		bra	.reply1

;---------------

.a_delete_object
		bsr	.getarg1		;lock
		move.l	d7,d0
		bsr	.getarg2		;name
		move.l	d7,d1
		move.l	#ACCESS_READ,d2
		bsr	.lock
		move.l	d0,d2
		beq	.reply2
		move.l	d0,a0
		move.l	(fl_Key,a0),a0
		jsr	(resload_DeleteFile,a2)
		move.l	d2,d0
		bsr	.unlock
		moveq	#DOSTRUE,d0
		bra	.reply1

;---------------

.a_copy_dir	bsr	.getarg1
	IFD DEBUG
		beq	_debug2
	ENDC
		move.l	d7,a0
		move.l	(fl_Key,a0),d1
		moveq	#0,d0
		move.l	#ACCESS_READ,d2
		bsr	.lock
		IFD	KICK31
		lsr.l	#2,d0			;APTR > BPTR
		ENDC
		tst.l	d0
		bne	.reply1
		bra	.reply2

;---------------

.a_examine_object
		bsr	.getarg1
		move.l	d7,a0			;a0 = APTR lock
		bsr	.getarg2		;d7 = APTR fib
		move.l	a0,d0
		beq	.examine_root

	IFD	_bootdos
		movem.l	a0,-(A7)
		lea	(bootname_exe,pc),a1	; fake exe name
		move.l	(fl_Key,a0),a0
		bsr	.specfile_chk
		bne	.specfile_not_locked

	; whdboot.exe file found (does not happen in kick 1.x)
	; copy some fake examine result

		add.w	#mfl_fib,a0
		move.l	d7,a1

		move.l  #$00000000,$00(a1)
		move.l  #$fffffffd,$04(a1)
		move.l  #$61616100,$08(a1)	; name: 'aaa', we don't care
		move.l  #$00000000,$74(a1)
		move.l  #$fffffffd,$78(a1)
		move.l  #$00038368,$7c(a1)	; size
		move.l  #$00000000,$80(a1)
		move.l  #$00002247,$84(a1)
		move.l  #$00000585,$88(a1)
		move.l  #$00000455,$8c(a1)
		move.l  #$00eeeeee,$90(a1)
		move.l  #$00000000,$e4(a1)
		move.l  #$00000000,$e8(a1)
		move.l  #$00000000,$ec(a1)
		move.l  #$00000108,$f4(a1)
		move.l  #$fffffffe,$f8(a1)


		move.l	(A7)+,a0
		bra.b	.examine_adj
.specfile_not_locked
		move.l	(A7)+,a0
	ENDC

	;copy whdload's examine result
		add.w	#mfl_fib,a0
		move.l	d7,a1
		moveq	#fib_Reserved/4-1,d0
.examine_fib	move.l	(a0)+,(a1)+
		dbf	d0,.examine_fib
	;adjust
.examine_adj
	;convert CSTR -> BSTR
		move.l	d7,a1
		lea	(fib_FileName,a1),a0
		bsr	.bstr
		lea	(fib_Comment,a1),a0
		bsr	.bstr
	;return
		moveq	#DOSTRUE,d0
		bra	.reply1
	;special handling of NULL lock
.examine_root	clr.l	-(a7)
		move.l	a7,a0
		move.l	d7,a1
		jsr	(resload_Examine,a2)
		addq.l	#4,a7
		lea	(.volumename+1,pc),a0	;CPTR
		move.l	d7,a1
		add.w	#fib_FileName,a1
.examine_root2	move.b	(a0)+,(a1)+
		bne	.examine_root2
		bra	.examine_adj

;---------------

.a_examine_next
		bsr	.getarg2
		move.l	d7,a0			;a0 = APTR fib
		jsr	(resload_ExNext,a2)
		move.l	d7,a1
	;convert CSTR -> BSTR
		lea	(fib_FileName,a1),a0
		bsr	.bstr
		lea	(fib_Comment,a1),a0
		bsr	.bstr
		bra	.reply2

;---------------

.a_info		
		bsr	.getarg2
		bra	.a_disk_info_1

;---------------

.a_disk_info	bsr	.getarg1
.a_disk_info_1	move.l	d7,a0
		clr.l	(a0)+			;id_NumSoftErrors
		clr.l	(a0)+			;id_UnitNumber
		move.l	#ID_VALIDATED,(a0)+	;id_DiskState
		move.l	#HD_NumBlocks,(a0)+	;id_NumBlocks
		move.l	#HD_NumBlocksUsed,(a0)+	;id_NumBlocksUsed
		move.l	#HD_BytesPerBlock,(a0)+	;id_BytesPerBlock
		move.l	#ID_DOS_DISK,(a0)+	;id_DiskType
		move.l	a3,(a0)+		;id_VolumeNode
		clr.l	(a0)+			;id_InUse

;---------------

.a_set_protect
.a_flush
.a_inhibit	moveq	#DOSTRUE,d0
		bra	.reply1

;---------------

.a_parent	bsr	.getarg1
		beq	.parent_root
		move.l	d7,a0			;d7 = lock
		move.l	(fl_Key,a0),a0
		tst.b	(a0)
		beq	.parent_root
	;get string length
		moveq	#-1,d0
.parent_strlen	addq.l	#1,d0
		tst.b	(a0)+
		bne	.parent_strlen		;d0 = strlen
	;search for "/"
		move.l	d7,a0
		move.l	(fl_Key,a0),a0
		lea	(a0,d0.l),a1
.parent_search	cmp.b	#"/",-(a1)
		beq	.parent_slash
		cmp.l	a0,a1
		bne	.parent_search
	;no slash found, so we are locking root
	;lock the parent directory
.parent_slash
	;build temporary bstr
		move.l	a1,d0
		sub.l	a0,d0			;length
		move.l	d0,d3
		addq.l	#4,d3			;+1 and align4
		and.b	#$fc,d3
		sub.l	d3,a7
		move.l	a7,a1
		move.b	d0,(a1)+
.parent_cpy	move.b	(a0)+,(a1)+
		subq.l	#1,d0
		bhi	.parent_cpy
	;lock it
		moveq	#0,d0			;lock
		move.l	a7,d1			;name
		move.l	#ACCESS_READ,d2		;mode
		bsr	.lock
		add.l	d3,a7
		lsr.l	#2,d0			;APTR > BPTR
		bne	.reply1
		bra	.reply2
	;that is a special case!
.parent_root	moveq	#0,d0
		moveq	#0,d1
		bra	.reply2

;---------------

.a_read		move.l	(dp_Arg1,a4),a0			;a0 = APTR lock
	IFD DEBUG
		cmp.l	#ACCESS_READ,(fl_Access,a0)
		bne	_debug4
	ENDC
		move.l	(dp_Arg3,a4),d3			;d3 = readsize
	IFD IOCACHE
		moveq	#0,d4				;d4 = readcachesize
	ENDC
		move.l	(mfl_pos,a0),d5			;d5 = pos
	;correct readsize if necessary
		move.l	(mfl_fib+fib_Size,a0),d2
		sub.l	d5,d2				;d2 = bytes left in file
		cmp.l	d2,d3
		bls	.read_ok
		move.l	d2,d3				;d3 = readsize
.read_ok	tst.l	d3
		beq	.read_end			;eof
		add.l	d3,(mfl_pos,a0)
	IFD _bootdos
	;special files
		move.l	(fl_Key,a0),a0			;name
		bsr	.specialfile
		tst.l	d0
		beq	.read_nospec
		move.l	d0,a0
		add.l	d5,a0				;source
		move.l	(dp_Arg2,a4),a1			;destination
		move.l	d3,d0
.read_spec	move.b	(a0)+,(a1)+
		subq.l	#1,d0
		bne	.read_spec
		bra	.read_end
.read_nospec	move.l	(dp_Arg1,a4),a0
	ENDC
	IFND IOCACHE
	;read direct
		move.l	d3,d0				;length
		move.l	d5,d1				;offset
		move.l	(fl_Key,a0),a0			;name
		move.l	(dp_Arg2,a4),a1			;buffer
		jsr	(resload_LoadFileOffset,a2)
	;finish
.read_end	move.l	d3,d0				;bytes read
	IFD _cb_dosRead
		movem.l	d0-a6,-(a7)
		move.l	(dp_Arg1,a4),a0
		move.l	(mfl_pos,a0),d1
		sub.l	d0,d1				;file pos
		move.l	(fl_Key,a0),a0			;name
		move.l	(dp_Arg2,a4),a1			;buffer
		bsr	_cb_dosRead
		movem.l	(a7)+,d0-a6
	ENDC
		bra	.reply1
	ELSE
		move.l	(mfl_cpos,a0),d6		;d6 = cachepos
		move.l	#IOCACHE,d7			;d7 = IOCACHE
	;try from cache
		tst.l	(mfl_iocache,a0)		;buffer allocated?
		beq	.read_1
		cmp.l	d5,d6
		bhi	.read_1
		move.l	d7,d0
		add.l	d6,d0
		sub.l	d5,d0
		bls	.read_1
		move.l	d0,d4				;d4 = readcachesize
		cmp.l	d4,d3
		bhi	.read_2
		move.l	d3,d4
.read_2		move.l	(mfl_iocache,a0),a0
		add.l	d5,a0
		sub.l	d6,a0				;source
		move.l	(dp_Arg2,a4),a1			;destination
		move.l	d4,d0
.read_3		move.b	(a0)+,(a1)+
		subq.l	#1,d0
		bne	.read_3
		add.l	d4,d5
		sub.l	d4,d2
		sub.l	d4,d3
		beq	.read_end
	;decide if read through cache or direct
.read_1		cmp.l	d2,d3
		beq	.read_d				;read remaining/complete file -> doesn't make sense to cache it
		cmp.l	d7,d3
		blo	.read_c
	;read direct
.read_d		move.l	d3,d0				;length
		move.l	d5,d1				;offset
		move.l	(dp_Arg1,a4),a0
		move.l	(fl_Key,a0),a0			;name
		move.l	(dp_Arg2,a4),a1			;buffer
		add.l	d4,a1
		jsr	(resload_LoadFileOffset,a2)
		bra	.read_end
	;read through cache
.read_c
	;get memory if necessary
		move.l	(dp_Arg1,a4),a0
		move.l	(mfl_iocache,a0),d0
		bne	.read_c1
		move.l	d7,d0
		moveq	#MEMF_ANY,d1
		jsr	(_LVOAllocMem,a6)
		move.l	(dp_Arg1,a4),a0
		move.l	d0,(mfl_iocache,a0)
		beq	.read_d
	;read into cache
.read_c1	move.l	d0,a1				;buffer
		move.l	(mfl_fib+fib_Size,a0),d0
		sub.l	d5,d0				;length
		cmp.l	d7,d0
		bls	.read_c2
		move.l	d7,d0				;length
.read_c2	move.l	d5,d1				;offset
		move.l	(fl_Key,a0),a0			;name
		jsr	(resload_LoadFileOffset,a2)
		move.l	(dp_Arg1,a4),a0
		move.l	d5,(mfl_cpos,a0)
	;copy from cache
		move.l	(mfl_iocache,a0),a0		;source
		move.l	(dp_Arg2,a4),a1
		add.l	d4,a1				;destination
		move.l	d3,d0
.read_c3	move.b	(a0)+,(a1)+
		subq.l	#1,d0
		bne	.read_c3
	;finish
.read_end	move.l	d3,d0
		add.l	d4,d0
	IFD _cb_dosRead
		movem.l	d0-a6,-(a7)
		move.l	(dp_Arg1,a4),a0
		move.l	(mfl_pos,a0),d1
		sub.l	d0,d1				;file pos
		move.l	(fl_Key,a0),a0			;name
		move.l	(dp_Arg2,a4),a1			;buffer
		bsr	_cb_dosRead
		movem.l	(a7)+,d0-a6
	ENDC
		bra	.reply1
	ENDC

;---------------

.a_write	move.l	(dp_Arg1,a4),a0			;APTR lock
	IFD DEBUG
		cmp.l	#ACCESS_WRITE,(fl_Access,a0)
		bne	_debug5
	ENDC
	IFND IOCACHE
		move.l	(dp_Arg3,a4),d0			;len
		move.l	(mfl_pos,a0),d1			;offset
		move.l	d1,d2
		add.l	d0,d2
		move.l	d2,(mfl_pos,a0)
		cmp.l	(mfl_fib+fib_Size,a0),d2
		bls	.write1
		move.l	d2,(mfl_fib+fib_Size,a0)	;new length
.write1		move.l	(fl_Key,a0),a0			;name
		move.l	(dp_Arg2,a4),a1			;buffer
		jsr	(resload_SaveFileOffset,a2)
		move.l	(dp_Arg3,a4),d0			;bytes written
		bra	.reply1
	ELSE
	;set new pos and correct size if necessary
		move.l	#IOCACHE,d4			;d4 = IOCACHE
		move.l	(dp_Arg2,a4),d5			;d5 = buffer
		move.l	(dp_Arg3,a4),d6			;d6 = len
		beq	.write_end
		move.l	(mfl_pos,a0),d7			;d7 = offset
		move.l	d6,d0
		add.l	d7,d0
		move.l	d0,(mfl_pos,a0)
		cmp.l	(mfl_fib+fib_Size,a0),d0
		bls	.write_1
		move.l	d0,(mfl_fib+fib_Size,a0)	;new length
.write_1
	;check if fits into cache
		move.l	d4,d0
		move.l	(mfl_cpos,a0),d1
		add.l	(mfl_clen,a0),d1
		cmp.l	d1,d7				;offsets match?
		bne	.write2
		add.l	d0,d0
		sub.l	(mfl_clen,a0),d0
.write2		cmp.l	(dp_Arg3,a4),d0
		blo	.write_direct
	;get memory if necessary
.write_cache	move.l	(mfl_iocache,a0),d0
		bne	.write_memok
		move.l	d4,d0
		moveq	#MEMF_ANY,d1
		jsr	(_LVOAllocMem,a6)
		move.l	(dp_Arg1,a4),a0			;lock
		move.l	d0,(mfl_iocache,a0)
		beq	.write_direct
	;into cache
.write_memok	move.l	(mfl_cpos,a0),d1
		add.l	(mfl_clen,a0),d1
		cmp.l	d1,d7				;offsets match?
		beq	.write_posok
		tst.l	(mfl_clen,a0)			;any data stored?
		bne	.write_flush
		move.l	d7,(mfl_cpos,a0)
.write_posok	move.l	d0,a1
		move.l	d4,d0
		sub.l	(mfl_clen,a0),d0		;free space in cache
		beq	.write_flush
		cmp.l	d0,d6
		bhs	.write_4
		move.l	d6,d0
.write_4	add.l	(mfl_clen,a0),a1
		add.l	d0,(mfl_clen,a0)
		sub.l	d0,d6
		add.l	d0,d7
		move.l	d5,a0
.write_cpy	move.b	(a0)+,(a1)+
		subq.l	#1,d0
		bne	.write_cpy
		move.l	a0,d5
		tst.l	d6
		beq	.write_end
	;flush buffer
.write_flush	move.l	(dp_Arg1,a4),a0			;lock
		move.l	(mfl_clen,a0),d0		;len
		move.l	(mfl_cpos,a0),d1		;offset
		move.l	(mfl_iocache,a0),a1		;buffer
		move.l	(fl_Key,a0),a0			;name
		jsr	(resload_SaveFileOffset,a2)
		move.l	(dp_Arg1,a4),a0			;lock
		clr.l	(mfl_clen,a0)
		clr.l	(mfl_cpos,a0)
		bra	.write_cache
	;write without cache
.write_direct	move.l	d6,d0				;len
		move.l	d7,d1				;offset
		move.l	(fl_Key,a0),a0			;name
		move.l	d5,a1				;buffer
		jsr	(resload_SaveFileOffset,a2)
.write_end	move.l	(dp_Arg3,a4),d0			;bytes written
		bra	.reply1
	ENDC

;---------------

.a_findinput	moveq	#ACCESS_READ,d2		;mode
		bra	.a_findall
.a_findupdate	moveq	#ACCESS_WRITE,d2	;mode
.a_findall
	;check exist and lock it
		bsr	.getarg2
		move.l	d7,d0			;APTR lock
		bsr	.getarg3
		move.l	d7,d1			;BSTR name
		bsr	.lock
		tst.l	d0			;APTR lock
		beq	.reply2
	;init fh
		bsr	.getarg1
		move.l	d7,a0			;fh
		move.l	d0,(fh_Arg1,a0)		;using the lock we refer the filename later
	;return
		moveq	#DOSTRUE,d0
		bra	.reply1

.a_findoutput	bsr	.getarg2
		move.l	d7,d0			;APTR lock
		bsr	.getarg3
		move.l	d7,d1			;BSTR name
		bsr	.buildname
		move.l	d0,d2			;d2 = name
		beq	.reply2
	;create an empty file
		move.l	d2,a0
		sub.l	a1,a1
		moveq	#0,d0
		jsr	(resload_SaveFile,a2)
	;free the name
		move.l	d2,a1
		move.l	-(a1),d0
		jsr	(_LVOFreeMem,a6)
		bra	.a_findupdate

;---------------

.a_end
	IFD IOCACHE
	;flush write buffer
		move.l	(dp_Arg1,a4),a0			;lock
		move.l	(mfl_clen,a0),d0		;len
		beq	.end_nocache
		move.l	(mfl_cpos,a0),d1		;offset
		move.l	(mfl_iocache,a0),a1		;buffer
		move.l	(fl_Key,a0),a0			;name
		jsr	(resload_SaveFileOffset,a2)
.end_nocache
	ENDC
		move.l	(dp_Arg1,a4),d0		;APTR lock
		bsr	.unlock
		moveq	#DOSTRUE,d0
		bra	.reply1

;---------------

.a_seek		move.l	(dp_Arg1,a4),a0		;APTR lock
		move.l	(dp_Arg2,a4),d2		;offset
		move.l	(dp_Arg3,a4),d1		;mode
	;calculate new position
		beq	.seek_cur
		bmi	.seek_beg
.seek_end	add.l	(mfl_fib+fib_Size,a0),d2
		bra	.seek_chk
.seek_cur	add.l	(mfl_pos,a0),d2
.seek_beg
.seek_chk
	;validate new position
		cmp.l	(mfl_fib+fib_Size,a0),d2
		bhi	.seek_err
	;set new
		move.l	(mfl_pos,a0),d0
		move.l	d2,(mfl_pos,a0)
		bra	.reply1
.seek_err	move.l	#-1,d0
		move.l	#ERROR_SEEK_ERROR,d1
		bra	.reply2

;---------------
; these functions get the respective arg converted from a BPTR to a APTR in D7

.getarg1	move.l	(dp_Arg1,a4),d7
		lsl.l	#2,d7
		rts
.getarg2	move.l	(dp_Arg2,a4),d7
		lsl.l	#2,d7
		rts
.getarg3	move.l	(dp_Arg3,a4),d7
		lsl.l	#2,d7
		rts

;---------------
; convert c-string into bcpl-string
; IN:	a0 = CSTR
; OUT:	-

.bstr		movem.l	d0-d2,-(a7)
		moveq	#-1,d0
		move.b	(a0)+,d2
.bstr_1		addq.l	#1,d0
		move.b	d2,d1
		move.b	(a0),d2
		move.b	d1,(a0)+
		bne	.bstr_1
		sub.l	d0,a0
		move.b	d0,(-2,a0)
		movem.l	(a7)+,d0-d2
		rts

;---------------
; lock a disk object
; IN:	d0 = APTR lock
;	d1 = BSTR name
;	d2 = LONG mode
; OUT:	d0 = APTR lock
;	d1 = LONG errcode

.lock:		movem.l	d4/a4,-(a7)
	;get name
		bsr	.buildname
		tst.l	d0
		beq	.lock_quit
		move.l	d0,d4			;D4 = name
	;get memory for lock
		move.l	#mfl_SIZEOF,d0
		move.l	#MEMF_CLEAR,d1
		jsr	(_LVOAllocMem,a6)
		tst.l	d0
		beq	.lock_nomem
		move.l	d0,a4			;A4 = myfilelock
	;special
	IFD _bootdos
		move.l	d4,a0
		bsr	.specialfile
		tst.l	d0
		beq	.lock_nospec
		move.l	d1,(mfl_fib+fib_Size,a4)
		bra	.lock_spec
.lock_nospec
	ENDC
	;examine
		move.l	d4,a0			;name
		lea	(mfl_fib,a4),a1		;fib
		jsr	(resload_Examine,a2)
		tst.l	d0
		beq	.lock_notfound
.lock_spec
	;set return values
		move.l	a4,d0
		moveq	#0,d1
	;fill lock structure
		addq.l	#4,a4			;fl_Link
		move.l	d4,(a4)+		;fl_Key (name)
		move.l	d2,(a4)+		;fl_Access
		move.l	a5,(a4)+		;fl_Task (MsgPort)
		move.l	a3,(a4)+		;fl_Volume
.lock_quit	movem.l	(a7)+,d4/a4
.rts		rts
.lock_notfound	move.l	#mfl_SIZEOF,d0
		move.l	a4,a1
		jsr	(_LVOFreeMem,a6)
		pea	ERROR_OBJECT_NOT_FOUND
		bra	.lock_err
.lock_nomem	pea	ERROR_NO_FREE_STORE
	;on error free the name
.lock_err	move.l	d4,a1
		move.l	-(a1),d0
		jsr	(_LVOFreeMem,a6)
		move.l	(a7)+,d1
		moveq	#DOSFALSE,d0
		bra	.lock_quit

;---------------
; free a lock
; IN:	d0 = APTR lock
; OUT:	-

.unlock		tst.l	d0
		beq	.rts
		move.l	d0,a1
		move.l	(fl_Key,a1),-(a7)	;name
	IFD IOCACHE
		move.l	(mfl_iocache,a1),-(a7)
	ENDC
		move.l	#mfl_SIZEOF,d0
		jsr	(_LVOFreeMem,a6)
	IFD IOCACHE
		move.l	(a7)+,d0
		beq	.unlock1
		move.l	d0,a1
		move.l	#IOCACHE,d0
		jsr	(_LVOFreeMem,a6)
.unlock1
	ENDC
		move.l	(a7)+,a1
		move.l	-(a1),d0
		jmp	(_LVOFreeMem,a6)

;---------------
; build name for disk object
; IN:	d0 = APTR lock (can represent a directory or a file)
;	d1 = BSTR name (an object name relative to the lock, may contain assign or volume in front)
; OUT:	d0 = APTR name (size=-(d0), must be freed via exec.FreeMem)
;	d1 = LONG errcode

.buildname	movem.l	d3-d7,-(a7)
		moveq	#0,d6			;d6 = length path
		moveq	#0,d7			;d7 = length name
	;get length of lock
		tst.l	d0
		beq	.buildname_nolock
		move.l	d0,a0
		move.l	(fl_Key,a0),a0
		move.l	a0,d4			;d4 = ptr path
		moveq	#-1,d6
.buildname_cl	addq.l	#1,d6
		tst.b	(a0)+
		bne	.buildname_cl
.buildname_nolock
	;get length of name
		move.l	d1,a0			;BSTR
		move.b	(a0)+,d7		;length
		beq	.buildname_noname
	;remove trailing "/"
		cmp.b	#1,d7
		beq	.buildname_nots
		cmp.b	#"/",(-1,a0,d7.l)
		bne	.buildname_nots
		subq.l	#1,d7
.buildname_nots
	;remove leading "xxx:"
		lea	(a0,d7.l),a1		;end
.buildname_col	cmp.b	#":",-(a1)
		beq	.buildname_fc
		cmp.l	a0,a1
		bne	.buildname_col
		subq.l	#1,a1
.buildname_fc	addq.l	#1,a1
		sub.l	a1,d7
		add.l	a0,d7
		move.l	a1,d5			;d5 = ptr name
.buildname_noname
	;allocate memory for object name
		moveq	#1+1+4,d0		;the possible seperator "/", 0 terminator, length
		add.l	d6,d0
		add.l	d7,d0
		move.l	d0,d3			;d3 = memlen
		move.l	#MEMF_ANY,d1
		jsr	(_LVOAllocMem,a6)
		tst.l	d0
		beq	.buildname_nomem
		move.l	d0,a0
		move.l	d3,(a0)+
		move.l	a0,d0			;d0 = new object memory
	;copy name
		move.l	d4,a1
		move.l	d6,d1
		beq	.buildname_name
.buildname_cp	move.b	(a1)+,(a0)+
		subq.l	#1,d1
		bne	.buildname_cp
	;add seperator
		tst.l	d7
		beq	.buildname_name
		move.b	#"/",(a0)+
	;copy path
.buildname_name	move.l	d5,a1
		move.l	d7,d1
		beq	.buildname_ok
		cmp.b	#'/',(a1)		; JOTD
		bne.b	.buildname_cn		; JOTD
		addq.l	#1,a1			; JOTD ("WHDLoad:/xxx" happens)
.buildname_cn	move.b	(a1)+,(a0)+
		subq.l	#1,d1
		bne	.buildname_cn
	;finish
.buildname_ok	clr.b	(a0)			;terminate
		moveq	#0,d1			;errorcode
.buildname_quit	movem.l	(a7)+,d3-d7
		rts

.buildname_nomem
		moveq	#DOSFALSE,d0
		move.l	#ERROR_NO_FREE_STORE,d1
		bra	.buildname_quit

;---------------
; check for special internal files
; IN:	a0 = CSTR name
; OUT:	d0 = APTR filedata
;	d1 = LONG filelength

	IFD _bootdos
.specialfile
		lea	(bootfile_ss,pc),a1	; command line with fake exe
		move.l	a1,d0
		move.l	#bootfile_ss_e-bootfile_ss,d1
		lea	(bootname_ss,pc),a1
		bsr	.specfile_chk
		beq	.specfile_found_rts

		lea	(bootfile_exe,pc),a1	; fake exe contents
		move.l	a1,d0
		move.l	#bootfile_exe_e-bootfile_exe,d1
		lea	(bootname_exe,pc),a1	; fake exe name
		bsr	.specfile_chk
		beq	.specfile_found_rts

		moveq	#0,d0
		rts

.specfile_chk	move.l	a0,-(a7)

.specfile_cmp	cmpm.b	(a0)+,(a1)+
		bne	.specfile_end
		tst.b	(-1,a0)
		bne	.specfile_cmp

.specfile_end	move.l	(a7)+,a0

.specfile_found_rts:
.specfile_rts	rts
	ENDC

;---------------

	CNOP 0,4
.volumename	dc.b	7,"WHDLoad",0		;BSTR (here with the exception that it must be 0-terminated!)
	CNOP 0,4
.handlername	dc.b	"DH0",0
	CNOP 0,4
.expansionname	dc.b	"expansion.library",0
	CNOP 0,4
_dosname	dc.b	"dos.library",0
	EVEN

