;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;MOTOROLA MICROPROCESSOR & MEMORY TECHNOLOGY GROUP
;M68000 Hi-Performance Microprocessor Division
;M68060 Software Package
;Production Release P1.00 -- October 10, 1994
;
;M68060 Software Package Copyright � 1993, 1994 Motorola Inc.  All rights reserved.
;
;THE SOFTWARE is provided on an "AS IS" basis and without warranty.
;To the maximum extent permitted by applicable law,
;MOTOROLA DISCLAIMS ALL WARRANTIES WHETHER EXPRESS OR IMPLIED,
;INCLUDING IMPLIED WARRANTIES OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE
;and any warranty against infringement with regard to the SOFTWARE
;(INCLUDING ANY MODIFIED VERSIONS THEREOF) and any accompanying written materials.
;
;To the maximum extent permitted by applicable law,
;IN NO EVENT SHALL MOTOROLA BE LIABLE FOR ANY DAMAGES WHATSOEVER
;(INCLUDING WITHOUT LIMITATION, DAMAGES FOR LOSS OF BUSINESS PROFITS,
;BUSINESS INTERRUPTION, LOSS OF BUSINESS INFORMATION, OR OTHER PECUNIARY LOSS)
;ARISING OF THE USE OR INABILITY TO USE THE SOFTWARE.
;Motorola assumes no responsibility for the maintenance and support of the SOFTWARE.
;
;You are hereby granted a copyright license to use, modify, and distribute the SOFTWARE
;so long as this entire notice is retained without alteration in any modified and/or
;redistributed versions, and that such modified versions are clearly identified as such.
;No licenses are granted by implication, estoppel or otherwise under any patents
;or trademarks of Motorola, Inc.
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; os.s
;
; This file contains:
;	- example "Call-Out"s required by both the ISP and FPSP.
;


;################################
; EXAMPLE CALL-OUTS		#
;				#
; _060_dmem_write()		#
; _060_dmem_read()		#
; _060_imem_read()		#
; _060_dmem_read_byte()		#
; _060_dmem_read_word()		#
; _060_dmem_read_long()		#
; _060_imem_read_word()		#
; _060_imem_read_long()		#
; _060_dmem_write_byte()	#
; _060_dmem_write_word()	#
; _060_dmem_write_long()	#
;				#
; _060_real_trace()		#
; _060_real_access()		#
;################################

;
; Each IO routine checks to see if the memory write/read is to/from user
; or supervisor application space. The examples below use simple "move"
; instructions for supervisor mode applications and call _copyin()/_copyout()
; for user mode applications.
; When installing the 060SP, the _copyin()/_copyout() equivalents for a
; given operating system should be substituted.
;
; The addresses within the 060SP are guaranteed to be on the stack.
; The result is that Unix processes are allowed to sleep as a consequence
; of a page fault during a _copyout.
;
; Linux/68k: The _060_[id]mem_{read,write}_{byte,word,long} functions
; (i.e. all the known length <= 4) are implemented by single moves
; statements instead of (more expensive) copy{in,out} calls, if
; working in user space

;
; _060_dmem_write():
;
; Writes to data memory while in supervisor mode.
;
; INPUTS:
;	a0 - supervisor source address
;	a1 - user destination address
;	d0 - number of bytes to write
;	$4(a6),bit5 - 1 = supervisor mode, 0 = user mode
; OUTPUTS:
;	d1 - 0 = success, !0 = failure
;
	;|.global		_060_dmem_write
_060_dmem_write:
	subq.l		#1,d0
super_write:
	move.b		(a0)+,(a1)+		; copy 1 byte
	dbra		d0,super_write		; quit if --ctr < 0
	clr.l		d1			; return success
	rts


;
; _060_imem_read(), _060_dmem_read():
;
; Reads from data/instruction memory while in supervisor mode.
;
; INPUTS:
;	a0 - user source address
;	a1 - supervisor destination address
;	d0 - number of bytes to read
;	$4(a6),bit5 - 1 = supervisor mode, 0 = user mode
; OUTPUTS:
;	d1 - 0 = success, !0 = failure
;
	;|.global		_060_imem_read
	;|.global		_060_dmem_read
_060_imem_read:
_060_dmem_read:
	subq.l		#1,d0
super_read:
	move.b		(a0)+,(a1)+		; copy 1 byte
	dbra		d0,super_read		; quit if --ctr < 0
	clr.l		d1			; return success
	rts


;
; _060_dmem_read_byte():
;
; Read a data byte from user memory.
;
; INPUTS:
;	a0 - user source address
;	$4(a6),bit5 - 1 = supervisor mode, 0 = user mode
; OUTPUTS:
;	d0 - data byte in d0
;	d1 - 0 = success, !0 = failure
;
	;|.global		_060_dmem_read_byte
_060_dmem_read_byte:
	clr.l		d0			; clear whole longword
	clr.l		d1			; assume success
dmrbs:	move.b		(a0),d0		; fetch super byte
	rts

;
; _060_dmem_read_word():
;
; Read a data word from user memory.
;
; INPUTS:
;	a0 - user source address
;	$4(a6),bit5 - 1 = supervisor mode, 0 = user mode
; OUTPUTS:
;	d0 - data word in d0
;	d1 - 0 = success, !0 = failure
;
; _060_imem_read_word():
;
; Read an instruction word from user memory.
;
; INPUTS:
;	a0 - user source address
;	$4(a6),bit5 - 1 = supervisor mode, 0 = user mode
; OUTPUTS:
;	d0 - instruction word in d0
;	d1 - 0 = success, !0 = failure
;
	;|.global		_060_dmem_read_word
	;|.global		_060_imem_read_word
_060_dmem_read_word:
_060_imem_read_word:
	clr.l		d1			; assume success
	clr.l		d0			; clear whole longword
dmrws:	move.w		(a0),d0		; fetch super word
	rts

;
; _060_dmem_read_long():
;

;
; INPUTS:
;	a0 - user source address
;	$4(a6),bit5 - 1 = supervisor mode, 0 = user mode
; OUTPUTS:
;	d0 - data longword in d0
;	d1 - 0 = success, !0 = failure
;
; _060_imem_read_long():
;
; Read an instruction longword from user memory.
;
; INPUTS:
;	a0 - user source address
;	$4(a6),bit5 - 1 = supervisor mode, 0 = user mode
; OUTPUTS:
;	d0 - instruction longword in d0
;	d1 - 0 = success, !0 = failure
;
	;|.global		_060_dmem_read_long
	;|.global		_060_imem_read_long
_060_dmem_read_long:
_060_imem_read_long:
	clr.l		d1			; assume success
dmrls:	move.l		(a0),d0		; fetch super longword
	rts

;
; _060_dmem_write_byte():
;
; Write a data byte to user memory.
;
; INPUTS:
;	a0 - user destination address
;	d0 - data byte in d0
;	$4(a6),bit5 - 1 = supervisor mode, 0 = user mode
; OUTPUTS:
;	d1 - 0 = success, !0 = failure
;
	;|.global		_060_dmem_write_byte
_060_dmem_write_byte:
	clr.l		d1			; assume success
dmwbs:	move.b		d0,(a0)		; store super byte
	rts

;
; _060_dmem_write_word():
;
; Write a data word to user memory.
;
; INPUTS:
;	a0 - user destination address
;	d0 - data word in d0
;	$4(a6),bit5 - 1 = supervisor mode, 0 = user mode
; OUTPUTS:
;	d1 - 0 = success, !0 = failure
;
	;|.global		_060_dmem_write_word
_060_dmem_write_word:
	clr.l		d1			; assume success
	btst		#$5,$4(a6)		; check for supervisor state
dmwws:	move.w		d0,(a0)		; store super word
dmwwr:	clr.l		d1			; return success
	rts

;
; _060_dmem_write_long():
;
; Write a data longword to user memory.
;
; INPUTS:
;	a0 - user destination address
;	d0 - data longword in d0
;	$4(a6),bit5 - 1 = supervisor mode, 0 = user mode
; OUTPUTS:
;	d1 - 0 = success, !0 = failure
;
	;|.global		_060_dmem_write_long
_060_dmem_write_long:
	clr.l		d1			; assume success
dmwls:	move.l		d0,(a0)		; store super longword
	rts




;###########################################################################

;
; _060_real_trace():
;
; This is the exit point for the 060FPSP when an instruction is being traced
; and there are no other higher priority exceptions pending for this instruction
; or they have already been processed.
;
; The sample code below simply executes an "rte".
;
	;|.global		_060_real_trace
_060_real_trace:
	bra.l	trap

;
; _060_real_access():
;
; This is the exit point for the 060FPSP when an access error exception
; is encountered. The routine below should point to the operating system
; handler for access error exceptions. The exception stack frame is an
; 8-word access error frame.
;
; The sample routine below simply executes an "rte" instruction which
; is most likely the incorrect thing to do and could put the system
; into an infinite loop.
;
	;|.global		_060_real_access
_060_real_access:
	bra.l	buserr


