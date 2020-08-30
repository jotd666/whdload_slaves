;*---------------------------------------------------------------------------
;  :Modul.	keyboard.s
;  :Contents.	routine to setup an keyboard handler
;  :Version.	$Id: keyboard.s 1.16 2016/02/14 16:43:11 wepl Exp wepl $
;  :History.	30.08.97 extracted from some slave sources
;		17.11.97 _keyexit2 added
;		23.12.98 _key_help added
;		07.10.99 some cosmetic changes, documentation improved
;		24.10.99 _keycode added
;		15.05.03 better interrupt acknowledge
;		04.03.04 clearing sdr removed, seems not required/causing
;			 problems
;		19.08.06 _key_check added (DJ Mike)
;		15.02.10 restructured and made _KeyboardHandle a global
;			 routine which doesn't affect interrupt acknowledge
;			 to be able to call it from an existing PORTS
;			 interrupt handler (PygmyProjects_Extension)
;		21.03.12 pc-relative for _resload access removed, because W.O.C. uses absolut
;  :Requires.	_keydebug	byte variable containing rawkey code
;		_keyexit	byte variable containing rawkey code
;  :Optional.	_keyexit2	byte variable containing rawkey code
;		_key_help	function to execute on help pressed
;		_debug		function to quit with debug
;		_exit		function to quit
;		_keycode	variable/memory filled with rawkey
;		_key_check	routine will be called with rawkey in d0
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*
; this routine setups a keyboard handler, realizing quit and quit-with-debug
; feature by pressing the appropriate key. the following variables must be
; defined:
;	_keyexit
;	_keydebug
; the labels should refer to the Slave structure, so user definable quit- and
; debug-key will be supported
;
; the optional variable:
;	_keyexit2
; can be used to specify a second quit-key, if a quit by two different keys
; should be supported
;
; the optional function:
;	_key_help
; will be called when the 'help' key is pressed, the function must return via
; 'rts' and must not change any registers
;
; the optional function:
;	_key_check
; will be called after ANY key is pressed. The keycode will be in d0.
; The function must return using 'rts' and must not modify any registers
;
; the optional variable:
;	 _keycode
; will be filled with the last rawkeycode
;
; IN:	-
; OUT:	-

_SetupKeyboard
	;set the interrupt vector
		pea	(.int,pc)
		move.l	(a7)+,($68)
	;allow interrupts from the keyboard
		move.b	#CIAICRF_SETCLR|CIAICRF_SP,(ciaicr+_ciaa)
	;clear all ciaa-interrupts
		tst.b	(ciaicr+_ciaa)
	;set input mode
		and.b	#~(CIACRAF_SPMODE),(ciacra+_ciaa)
	;clear ports interrupt
		move.w	#INTF_PORTS,(intreq+_custom)
	;allow ports interrupt
		move.w	#INTF_SETCLR|INTF_INTEN|INTF_PORTS,(intena+_custom)
		rts

	;check if keyboard has caused interrupt
.int		btst	#INTB_PORTS,(intreqr+1+_custom)
		beq	.end
		btst	#CIAICRB_SP,(ciaicr+_ciaa)
		beq	.end

		bsr	_KeyboardHandle

.end		move.w	#INTF_PORTS,(intreq+_custom)
	;to avoid timing problems on very fast machines we do another
	;custom access
		tst.w	(intreqr+_custom)
		rte

_KeyboardHandle	movem.l	d0-d1/a0-a1,-(a7)
		lea	(_custom),a0
		lea	(_ciaa),a1
	;read keycode
		move.b	(ciasdr,a1),d0
	;set output mode (handshake)
		or.b	#CIACRAF_SPMODE,(ciacra,a1)
	;calculate rawkeycode
		not.b	d0
		ror.b	#1,d0

		cmp.b	(_keydebug,pc),d0
		bne	.1
		movem.l	(a7)+,d0-d1/a0-a1		;restore
	;transform stackframe to resload_Abort arguments
		move.w	(a7),(6,a7)			;sr
		move.l	(2,a7),(a7)			;pc
		clr.w	(4,a7)				;ext.l sr
	IFD _debug
		bra	_debug
	ELSE
		bra	.debug
	ENDC

.1		cmp.b	(_keyexit,pc),d0
	IFD _exit
		beq	_exit
	ELSE
		beq	.exit
	ENDC

	IFD _keyexit2
		cmp.b	(_keyexit2,pc),d0
	IFD _exit
		beq	_exit
	ELSE
		beq	.exit
	ENDC
	ENDC

	IFD _key_help
		cmp.b	#$5f,d0
		bne	.2
		bsr	_key_help
.2
	ENDC

	IFD _key_check
		bsr	_key_check
	ENDC

	IFD _keycode
		move.l	a0,-(a7)
		lea	(_keycode),a0			;no ',pc' because used absolut sometimes
		move.b	d0,(a0)
		move.l	(a7)+,a0
	ENDC

	;better would be to use the cia-timer to wait, but we aren't know if
	;they are otherwise used, so using the rasterbeam
	;required minimum waiting is 85 탎, one rasterline is 63.5 탎
	;a loop of 3 results in min=127탎 max=190.5탎
		moveq	#3-1,d1
.wait1		move.b	(vhposr,a0),d0
.wait2		cmp.b	(vhposr,a0),d0
		beq	.wait2
		dbf	d1,.wait1

	;set input mode
		and.b	#~(CIACRAF_SPMODE),(ciacra,a1)
		movem.l	(a7)+,d0-d1/a0-a1
		rts

	IFND _exit
.debug		pea	TDREASON_DEBUG.w
.quit		move.l	(_resload,pc),-(a7)		;no ',pc' because used absolut sometimes: JOTD: fuck it!
		addq.l	#resload_Abort,(a7)
		rts
.exit		pea	TDREASON_OK.w
		bra	.quit
	ENDC

