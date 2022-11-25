; converted to motorola syntax by JOTD in december 2020/january 2021
;
; concatenated all sources together  too
; motorola syntax converted from MIT syntax with mit2mot.py
; (from my github https://github.com/jotd666/amiga68ktools)
;
; also fixed the duplicate symbols (code was in separate files then
; linked together but my aim was to make it relocatable so I tried to
; create a big block of code. I failed to make it relocatable, but I left
; it as is because it saves a lot of hassle with xref/xdef and also saved
; a few bytes by removing some duplicate constants
;
;	fpsp.h 3.3 3.3
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;	fpsp.h --- stack frame offsets during FPSP exception handling
;
;	These equates are used to access the exception frame, the fsave
;	frame and any local variables needed by the FPSP package.
;	
;	All FPSP handlers begin by executing:
;
;		link	a6,#-LOCAL_SIZE
;		fsave	-(a7)
;		movem.l	d0-d1/a0-a1,USER_DA(a6)
;		fmovem.x fp0-fp3,USER_FP0(a6)
;		fmove.l	fpsr/fpcr/fpiar,USER_FPSR(a6)
;
;	After initialization, the stack looks like this:
;
;	A7 --->	+-------------------------------+
;		; 			; ;		; FPU fsave area		; ;		; 			; ;		+-------------------------------+
;		; 			; ;		; FPSP Local Variables	; ;		;      including		; ;		;   saved registers	; ;		; 			; ;		+-------------------------------+
;	A6 --->	; Saved A6		; ;		+-------------------------------+
;		; 			; ;		; Exception Frame		; ;		; 			; ;		; 			; ;
;	Positive offsets from A6 refer to the exception frame.  Negative
;	offsets refer to the Local Variable area and the fsave area.
;	The fsave frame is also accessible 'from the top' via A7.
;
;	On exit, the handlers execute:
;
;		movem.l	USER_DA(a6),d0-d1/a0-a1
;		fmovem.x USER_FP0(a6),fp0-fp3
;		fmove.l	USER_FPSR(a6),fpsr/fpcr/fpiar
;		frestore (a7)+
;		unlk	a6
;
;	and then either 'bra fpsp_done' if the exception was completely
;	handled	by the package, or 'bra real_xxxx' which is an external
;	label to a routine that will process a real exception of the
;	type that was generated.  Some handlers may omit the 'frestore'
;	if the FPU state after the exception is idle.
;
;	Sometimes the exception handler will transform the fsave area
;	because it needs to report an exception back to the user.  This
;	can happen if the package is entered for an unimplemented float
;	instruction that generates (say) an underflow.  Alternatively,
;	a second fsave frame can be pushed onto the stack and the
;	handler	exit code will reload the new frame and discard the old.
;
;	The registers d0, d1, a0, a1 and fp0-fp3 are always saved and
;	restored from the 'local variable' area and can be used as
;	temporaries.  If a routine needs to change any
;	of these registers, it should modify the saved copy and let
;	the handler exit code restore the value.
;
;----------------------------------------------------------------------
;
;	Local Variables on the stack
;
LOCAL_SIZE = 192	; bytes needed for local variables
LV = -LOCAL_SIZE	; convenient base value
;
USER_DA = LV+0	; save space for D0-D1,A0-A1
USER_D0 = LV+0	; saved user D0
USER_D1 = LV+4	; saved user D1
USER_A0 = LV+8	; saved user A0
USER_A1 = LV+12	; saved user A1
USER_FP0 = LV+16	; saved user FP0
USER_FP1 = LV+28	; saved user FP1
USER_FP2 = LV+40	; saved user FP2
USER_FP3 = LV+52	; saved user FP3
USER_FPCR = LV+64	; saved user FPCR
FPCR_ENABLE = USER_FPCR+2	; FPCR exception enable 
FPCR_MODE = USER_FPCR+3	; FPCR rounding mode control
USER_FPSR = LV+68	; saved user FPSR
FPSR_CC = USER_FPSR+0	; FPSR condition code
FPSR_QBYTE = USER_FPSR+1	; FPSR quotient
FPSR_EXCEPT = USER_FPSR+2	; FPSR exception
FPSR_AEXCEPT = USER_FPSR+3	; FPSR accrued exception
USER_FPIAR = LV+72	; saved user FPIAR
FP_SCR1 = LV+76	; room for a temporary float value
FP_SCR2 = LV+92	; room for a temporary float value
L_SCR1 = LV+108	; room for a temporary long value
L_SCR2 = LV+112	; room for a temporary long value
STORE_FLG = LV+116
BINDEC_FLG = LV+117	; used in bindec
DNRM_FLG = LV+118	; used in res_func
RES_FLG = LV+119	; used in res_func
DY_MO_FLG = LV+120	; dyadic/monadic flag
UFLG_TMP = LV+121	; temporary for uflag errata
CU_ONLY = LV+122	; cu-only flag
VER_TMP = LV+123	; temp holding for version number
L_SCR3 = LV+124	; room for a temporary long value
FP_SCR3 = LV+128	; room for a temporary float value
FP_SCR4 = LV+144	; room for a temporary float value
FP_SCR5 = LV+160	; room for a temporary float value
FP_SCR6 = LV+176
;
;NEXT		equ	LV+192		;need to increase LOCAL_SIZE
;
;--------------------------------------------------------------------------
;
;	fsave offsets and bit definitions
;
;	Offsets are defined from the end of an fsave because the last 10
;	words of a busy frame are the same as the unimplemented frame.
;
CU_SAVEPC = LV-92	; micro-pc for CU (1 byte)
FPR_DIRTY_BITS = LV-91	; fpr dirty bits
;
WBTEMP = LV-76	; write back temp (12 bytes)
WBTEMP_EX = WBTEMP	; wbtemp sign and exponent (2 bytes)
WBTEMP_HI = WBTEMP+4	; wbtemp mantissa [63:32] (4 bytes)
WBTEMP_LO = WBTEMP+8	; wbtemp mantissa [31:00] (4 bytes)
;
WBTEMP_SGN = WBTEMP+2	; used to store sign
;
FPSR_SHADOW = LV-64	; fpsr shadow reg
;
FPIARCU = LV-60	; Instr. addr. reg. for CU (4 bytes)
;
CMDREG2B = LV-52	; cmd reg for machine 2
CMDREG3B = LV-48	; cmd reg for E3 exceptions (2 bytes)
;
NMNEXC = LV-44	; NMNEXC (unsup,snan bits only)
nmn_unsup_bit = 1
nmn_snan_bit = 0
;
NMCEXC = LV-43	; NMNEXC & NMCEXC
nmn_operr_bit = 7
nmn_ovfl_bit = 6
nmn_unfl_bit = 5
nmc_unsup_bit = 4
nmc_snan_bit = 3
nmc_operr_bit = 2
nmc_ovfl_bit = 1
nmc_unfl_bit = 0
;
STAG = LV-40	; source tag (1 byte)
WBTEMP_GRS = LV-40	; alias wbtemp guard, round, sticky
guard_bit = 1	; guard bit is bit number 1
round_bit = 0	; round bit is bit number 0
stag_mask = $E0	; upper 3 bits are source tag type
denorm_bit = 7	; bit determins if denorm or unnorm
etemp15_bit = 4	; etemp exponent bit #15
wbtemp66_bit = 2	; wbtemp mantissa bit #66
wbtemp1_bit = 1	; wbtemp mantissa bit #1
wbtemp0_bit = 0	; wbtemp mantissa bit #0
;
STICKY = LV-39	; holds sticky bit
sticky_bit = 7
;
CMDREG1B = LV-36	; cmd reg for E1 exceptions (2 bytes)
kfact_bit = 12	; distinguishes static/dynamic k-factor
;					;on packed move outs.  NOTE: this
;					;equate only works when CMDREG1B is in
;					;a register.
;
CMDWORD = LV-35	; command word in cmd1b
direction_bit = 5	; bit 0 in opclass
size_bit2 = 12	; bit 2 in size field
;
DTAG = LV-32	; dest tag (1 byte)
dtag_mask = $E0	; upper 3 bits are dest type tag
fptemp15_bit = 4	; fptemp exponent bit #15
;
WB_BYTE = LV-31	; holds WBTE15 bit (1 byte)
wbtemp15_bit = 4	; wbtemp exponent bit #15
;
E_BYTE = LV-28	; holds E1 and E3 bits (1 byte)
E1 = 2		; which bit is E1 flag
E3 = 1		; which bit is E3 flag
SFLAG = 0		; which bit is S flag
;
T_BYTE = LV-27	; holds T and U bits (1 byte)
XFLAG = 7		; which bit is X flag
UFLAG = 5		; which bit is U flag
TFLAG = 4		; which bit is T flag
;
FPTEMP = LV-24	; fptemp (12 bytes)
FPTEMP_EX = FPTEMP	; fptemp sign and exponent (2 bytes)
FPTEMP_HI = FPTEMP+4	; fptemp mantissa [63:32] (4 bytes)
FPTEMP_LO = FPTEMP+8	; fptemp mantissa [31:00] (4 bytes)
;
FPTEMP_SGN = FPTEMP+2	; used to store sign
;
ETEMP = LV-12	; etemp (12 bytes)
ETEMP_EX = ETEMP	; etemp sign and exponent (2 bytes)
ETEMP_HI = ETEMP+4	; etemp mantissa [63:32] (4 bytes)
ETEMP_LO = ETEMP+8	; etemp mantissa [31:00] (4 bytes)
;
ETEMP_SGN = ETEMP+2	; used to store sign
;
EXC_SR = 4	; exception frame status register
EXC_PC = 6	; exception frame program counter
EXC_VEC = 10	; exception frame vector (format+vector#)
EXC_EA = 12	; exception frame effective address
;
;--------------------------------------------------------------------------
;
;	FPSR/FPCR bits
;
neg_bit = 3	; negative result
z_bit = 2		; zero result
inf_bit = 1	; infinity result
nan_bit = 0	; not-a-number result
;
q_sn_bit = 7	; sign bit of quotient byte
;
bsun_bit = 7	; branch on unordered
snan_bit = 6	; signalling nan
operr_bit = 5	; operand error
ovfl_bit = 4	; overflow
unfl_bit = 3	; underflow
dz_bit = 2	; divide by zero
inex2_bit = 1	; inexact result 2
inex1_bit = 0	; inexact result 1
;
aiop_bit = 7	; accrued illegal operation
aovfl_bit = 6	; accrued overflow
aunfl_bit = 5	; accrued underflow
adz_bit = 4	; accrued divide by zero
ainex_bit = 3	; accrued inexact
;
;	FPSR individual bit masks
;
neg_mask = $08000000
z_mask = $04000000
inf_mask = $02000000
nan_mask = $01000000
;
bsun_mask = $00008000
snan_mask = $00004000
operr_mask = $00002000
ovfl_mask = $00001000
unfl_mask = $00000800
dz_mask = $00000400
inex2_mask = $00000200
inex1_mask = $00000100
;
aiop_mask = $00000080	; accrued illegal operation
aovfl_mask = $00000040	; accrued overflow
aunfl_mask = $00000020	; accrued underflow
adz_mask = $00000010	; accrued divide by zero
ainex_mask = $00000008	; accrued inexact
;
;	FPSR combinations used in the FPSP
;
dzinf_mask = inf_mask+dz_mask+adz_mask
opnan_mask = nan_mask+operr_mask+aiop_mask
nzi_mask = $01ffffff	; clears N, Z, and I
unfinx_mask = unfl_mask+inex2_mask+aunfl_mask+ainex_mask
unf2inx_mask = unfl_mask+inex2_mask+ainex_mask
ovfinx_mask = ovfl_mask+inex2_mask+aovfl_mask+ainex_mask
inx1a_mask = inex1_mask+ainex_mask
inx2a_mask = inex2_mask+ainex_mask
snaniop_mask = nan_mask+snan_mask+aiop_mask
naniop_mask = nan_mask+aiop_mask
neginf_mask = neg_mask+inf_mask
infaiop_mask = inf_mask+aiop_mask
negz_mask = neg_mask+z_mask
opaop_mask = operr_mask+aiop_mask
unfl_inx_mask = unfl_mask+aunfl_mask+ainex_mask
ovfl_inx_mask = ovfl_mask+aovfl_mask+ainex_mask
;
;--------------------------------------------------------------------------
;
;	FPCR rounding modes
;
x_mode = $00	; round to extended
s_mode = $40	; round to single
d_mode = $80	; round to double
;
rn_mode = $00	; round nearest
rz_mode = $10	; round to zero
rm_mode = $20	; round to minus infinity
rp_mode = $30	; round to plus infinity
;
;--------------------------------------------------------------------------
;
;	Miscellaneous equates
;
signan_bit = 6	; signalling nan bit in mantissa
sign_bit = 7
;
rnd_stky_bit = 29	; round/sticky bit of mantissa
;				this can only be used if in a data register
sx_mask = $01800000	; set s and x bits in word $48
;
LOCAL_EX = 0
LOCAL_SGN = 2
LOCAL_HI = 4
LOCAL_LO = 8
LOCAL_GRS = 12	; valid ONLY for FP_SCR1, FP_SCR2
;
;
norm_tag = $00	; tag bits in {7:5} position
zero_tag = $20
inf_tag = $40
nan_tag = $60
dnrm_tag = $80
;
;	fsave sizes and formats
;
VER_4 = $40	; fpsp compatible version numbers
;					are in the $40s {$40-$4f}
VER_40 = $40	; original version number
VER_41 = $41	; revision version number
;
BUSY_SIZE = 100	; size of busy frame
BUSY_FRAME = LV-BUSY_SIZE	; start of busy frame
;
UNIMP_40_SIZE = 44	; size of orig unimp frame
UNIMP_41_SIZE = 52	; size of rev unimp frame
;
IDLE_SIZE = 4	; size of idle frame
IDLE_FRAME = LV-IDLE_SIZE	; start of idle frame
;
;	exception vectors
;
TRACE_VEC = $2024	; trace trap
FLINE_VEC = $002C	; 'real' F-line
UNIMP_VEC = $202C	; unimplemented
INEX_VEC = $00C4
;
dbl_thresh = $3C01
sgl_thresh = $3F81
;
;
;	bindec.sa 3.4 1/3/91
;
;	bindec
;
;	Description:
;		Converts an input in extended precision format
;		to bcd format.
;
;	Input:
;		a0 points to the input extended precision value
;		value in memory; d0 contains the k-factor sign-extended
;		to 32-bits.  The input may be either normalized,
;		unnormalized, or denormalized.
;
;	Output:	result in the FP_SCR1 space on the stack.
;
;	Saves and Modifies: D2-D7,A2,FP2
;
;	Algorithm:
;
;	A1.	Set RM and size ext;  Set SIGMA = sign of input.  
;		The k-factor is saved for use in d7. Clear the
;		BINDEC_FLG for separating normalized/denormalized
;		input.  If input is unnormalized or denormalized,
;		normalize it.
;
;	A2.	Set X = abs(input).
;
;	A3.	Compute ILOG.
;		ILOG is the log base 10 of the input value.  It is
;		approximated by adding e + 0.f when the original 
;		value is viewed as 2^^e * 1.f in extended precision.  
;		This value is stored in d6.
;
;	A4.	Clr INEX bit.
;		The operation in A3 above may have set INEX2.  
;
;	A5.	Set ICTR = 0;
;		ICTR is a flag used in A13.  It must be set before the 
;		loop entry A6.
;
;	A6.	Calculate LEN.
;		LEN is the number of digits to be displayed.  The
;		k-factor can dictate either the total number of digits,
;		if it is a positive number, or the number of digits
;		after the decimal point which are to be included as
;		significant.  See the 68882 manual for examples.
;		If LEN is computed to be greater than 17, set OPERR in
;		USER_FPSR.  LEN is stored in d4.
;
;	A7.	Calculate SCALE.
;		SCALE is equal to 10^ISCALE, where ISCALE is the number
;		of decimal places needed to insure LEN integer digits
;		in the output before conversion to bcd. LAMBDA is the
;		sign of ISCALE, used in A9. Fp1 contains
;		10^^(abs(ISCALE)) using a rounding mode which is a
;		function of the original rounding mode and the signs
;		of ISCALE and X.  A table is given in the code.
;
;	A8.	Clr INEX; Force RZ.
;		The operation in A3 above may have set INEX2.  
;		RZ mode is forced for the scaling operation to insure
;		only one rounding error.  The grs bits are collected in 
;		the INEX flag for use in A10.
;
;	A9.	Scale X -> Y.
;		The mantissa is scaled to the desired number of
;		significant digits.  The excess digits are collected
;		in INEX2.
;
;	A10.	Or in INEX.
;		If INEX is set, round error occurred.  This is
;		compensated for by 'or-ing' in the INEX2 flag to
;		the lsb of Y.
;
;	A11.	Restore original FPCR; set size ext.
;		Perform FINT operation in the user's rounding mode.
;		Keep the size to extended.
;
;	A12.	Calculate YINT = FINT(Y) according to user's rounding
;		mode.  The FPSP routine sintd0 is used.  The output
;		is in fp0.
;
;	A13.	Check for LEN digits.
;		If the int operation results in more than LEN digits,
;		or less than LEN -1 digits, adjust ILOG and repeat from
;		A6.  This test occurs only on the first pass.  If the
;		result is exactly 10^LEN, decrement ILOG and divide
;		the mantissa by 10.
;
;	A14.	Convert the mantissa to bcd.
;		The binstr routine is used to convert the LEN digit 
;		mantissa to bcd in memory.  The input to binstr is
;		to be a fraction; i.e. (mantissa)/10^LEN and adjusted
;		such that the decimal point is to the left of bit 63.
;		The bcd digits are stored in the correct position in 
;		the final string area in memory.
;
;	A15.	Convert the exponent to bcd.
;		As in A14 above, the exp is converted to bcd and the
;		digits are stored in the final string.
;		Test the length of the final exponent string.  If the
;		length is 4, set operr.
;
;	A16.	Write sign bits to final string.
;
;	Implementation Notes:
;
;	The registers are used as follows:
;
;		d0: scratch; LEN input to binstr
;		d1: scratch
;		d2: upper 32-bits of mantissa for binstr
;		d3: scratch;lower 32-bits of mantissa for binstr
;		d4: LEN
;      		d5: LAMBDA/ICTR
;		d6: ILOG
;		d7: k-factor
;		a0: ptr for original operand/final result
;		a1: scratch pointer
;		a2: pointer to FP_X; abs(original value) in ext
;		fp0: scratch
;		fp1: scratch
;		fp2: scratch
;		F_SCR1:
;		F_SCR2:
;		L_SCR1:
;		L_SCR2:

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;BINDEC    idnt    2,1 ; Motorola 040 Floating Point Software Package

	

	;section	8

; Constants in extended precision
LOG2EXT: 	dc.l	$3FFD0000,$9A209A84,$FBCFF798,$00000000
LOG2UP1:	dc.l	$3FFD0000,$9A209A84,$FBCFF799,$00000000

; Constants in single precision
FONE: 	dc.l	$3F800000,$00000000,$00000000,$00000000
FTWO:	dc.l	$40000000,$00000000,$00000000,$00000000
FTEN: 	dc.l	$41200000,$00000000,$00000000,$00000000
F4933:	dc.l	$459A2800,$00000000,$00000000,$00000000

RBDTBL: 	dc.b	0,0,0,0
	dc.b	3,3,2,2
	dc.b	3,2,2,3
	dc.b	2,3,3,2

	;xref	binstr
	;xref	sintdo
	;xref	ptenrn,ptenrm,ptenrp

	;|.global	bindec
	;|.global	sc_mul
bindec:
	movem.l	d2-d7/a2,-(a7)
	fmovem.x fp0-fp2,-(a7)

; A1. Set RM and size ext. Set SIGMA = sign input;
;     The k-factor is saved for use in d7.  Clear BINDEC_FLG for
;     separating  normalized/denormalized input.  If the input
;     is a denormalized number, set the BINDEC_FLG memory word
;     to signal denorm.  If the input is unnormalized, normalize
;     the input and test for denormalized result.  
;
	fmove.l	#rm_mode,FPCR	;set RM and ext
	move.l	(a0),L_SCR2(a6)	;save exponent for sign check
	move.l	d0,d7		;move k-factor to d7
	clr.b	BINDEC_FLG(a6)	;clr norm/denorm flag
	move.w	STAG(a6),d0	;get stag
	andi.w	#$e000,d0	;isolate stag bits
	beq	A2_str		;if zero, input is norm
;
; Normalize the denorm
;
un_de_norm:
	move.w	(a0),d0
	andi.w	#$7fff,d0	;strip sign of normalized exp
	move.l	4(a0),d1
	move.l	8(a0),d2
norm_loop:
	sub.w	#1,d0
	lsl.l	#1,d2
	roxl.l	#1,d1
	tst.l	d1
	bge.s	norm_loop
;
; Test if the normalized input is denormalized
;
	tst.w	d0
	bgt.s	pos_exp		;if greater than zero, it is a norm
	st	BINDEC_FLG(a6)	;set flag for denorm
pos_exp:
	andi.w	#$7fff,d0	;strip sign of normalized exp
	move.w	d0,(a0)
	move.l	d1,4(a0)
	move.l	d2,8(a0)

; A2. Set X = abs(input).
;
A2_str:
	move.l	(a0),FP_SCR2(a6) ; move input to work space
	move.l	4(a0),FP_SCR2+4(a6) ; move input to work space
	move.l	8(a0),FP_SCR2+8(a6) ; move input to work space
	andi.l	#$7fffffff,FP_SCR2(a6) ;create abs(X)

; A3. Compute ILOG.
;     ILOG is the log base 10 of the input value.  It is approx-
;     imated by adding e + 0.f when the original value is viewed
;     as 2^^e * 1.f in extended precision.  This value is stored
;     in d6.
;
; Register usage:
;	Input/Output
;	d0: k-factor/exponent
;	d2: x/x
;	d3: x/x
;	d4: x/x
;	d5: x/x
;	d6: x/ILOG
;	d7: k-factor/Unchanged
;	a0: ptr for original operand/final result
;	a1: x/x
;	a2: x/x
;	fp0: x/float(ILOG)
;	fp1: x/x
;	fp2: x/x
;	F_SCR1:x/x
;	F_SCR2:Abs(X)/Abs(X) with $3fff exponent
;	L_SCR1:x/x
;	L_SCR2:first word of X packed/Unchanged

	tst.b	BINDEC_FLG(a6)	;check for denorm
	beq.s	A3_cont		;if clr, continue with norm
	move.l	#-4933,d6	;force ILOG = -4933
	bra.s	A4_str
A3_cont:
	move.w	FP_SCR2(a6),d0	;move exp to d0
	move.w	#$3fff,FP_SCR2(a6) ;replace exponent with $3fff
	fmove.x	FP_SCR2(a6),fp0	;now fp0 has 1.f
	sub.w	#$3fff,d0	;strip off bias
	fadd.w	d0,fp0		;add in exp
	fsub.s	FONE(pc),fp0	;subtract off 1.0
	fbge	pos_res		;if pos, branch 
	fmul.x	LOG2UP1(pc),fp0	;if neg, mul by LOG2UP1
	fmove.l	fp0,d6		;put ILOG in d6 as a lword
	bra.s	A4_str		;go move out ILOG
pos_res:
	fmul.x	LOG2EXT(pc),fp0	;if pos, mul by LOG2
	fmove.l	fp0,d6		;put ILOG in d6 as a lword


; A4. Clr INEX bit.
;     The operation in A3 above may have set INEX2.  

A4_str:	
	fmove.l	#0,FPSR		;zero all of fpsr - nothing needed


; A5. Set ICTR = 0;
;     ICTR is a flag used in A13.  It must be set before the 
;     loop entry A6. The lower word of d5 is used for ICTR.

	clr.w	d5		;clear ICTR


; A6. Calculate LEN.
;     LEN is the number of digits to be displayed.  The k-factor
;     can dictate either the total number of digits, if it is
;     a positive number, or the number of digits after the
;     original decimal point which are to be included as
;     significant.  See the 68882 manual for examples.
;     If LEN is computed to be greater than 17, set OPERR in
;     USER_FPSR.  LEN is stored in d4.
;
; Register usage:
;	Input/Output
;	d0: exponent/Unchanged
;	d2: x/x/scratch
;	d3: x/x
;	d4: exc picture/LEN
;	d5: ICTR/Unchanged
;	d6: ILOG/Unchanged
;	d7: k-factor/Unchanged
;	a0: ptr for original operand/final result
;	a1: x/x
;	a2: x/x
;	fp0: float(ILOG)/Unchanged
;	fp1: x/x
;	fp2: x/x
;	F_SCR1:x/x
;	F_SCR2:Abs(X) with $3fff exponent/Unchanged
;	L_SCR1:x/x
;	L_SCR2:first word of X packed/Unchanged

A6_str:	
	tst.l	d7		;branch on sign of k
	ble.s	k_neg		;if k <= 0, LEN = ILOG + 1 - k
	move.l	d7,d4		;if k > 0, LEN = k
	bra.s	len_ck		;skip to LEN check
k_neg:
	move.l	d6,d4		;first load ILOG to d4
	sub.l	d7,d4		;subtract off k
	addq.l	#1,d4		;add in the 1
len_ck:
	tst.l	d4		;LEN check: branch on sign of LEN
	ble.s	LEN_ng		;if neg, set LEN = 1
	cmp.l	#17,d4		;test if LEN > 17
	ble.s	A7_str		;if not, forget it
	move.l	#17,d4		;set max LEN = 17
	tst.l	d7		;if negative, never set OPERR
	ble.s	A7_str		;if positive, continue
	or.l	#opaop_mask,USER_FPSR(a6) ;set OPERR & AIOP in USER_FPSR
	bra.s	A7_str		;finished here
LEN_ng:
	moveq.l	#1,d4		;min LEN is 1


; A7. Calculate SCALE.
;     SCALE is equal to 10^ISCALE, where ISCALE is the number
;     of decimal places needed to insure LEN integer digits
;     in the output before conversion to bcd. LAMBDA is the sign
;     of ISCALE, used in A9.  Fp1 contains 10^^(abs(ISCALE)) using
;     the rounding mode as given in the following table (see
;     Coonen, p. 7.23 as ref.; however, the SCALE variable is
;     of opposite sign in bindec.sa from Coonen).
;
;	Initial					USE
;	FPCR[6:5]	LAMBDA	SIGN(X)		FPCR[6:5]
;	----------------------------------------------
;	 RN	00	   0	   0		00/0	RN
;	 RN	00	   0	   1		00/0	RN
;	 RN	00	   1	   0		00/0	RN
;	 RN	00	   1	   1		00/0	RN
;	 RZ	01	   0	   0		11/3	RP
;	 RZ	01	   0	   1		11/3	RP
;	 RZ	01	   1	   0		10/2	RM
;	 RZ	01	   1	   1		10/2	RM
;	 RM	10	   0	   0		11/3	RP
;	 RM	10	   0	   1		10/2	RM
;	 RM	10	   1	   0		10/2	RM
;	 RM	10	   1	   1		11/3	RP
;	 RP	11	   0	   0		10/2	RM
;	 RP	11	   0	   1		11/3	RP
;	 RP	11	   1	   0		11/3	RP
;	 RP	11	   1	   1		10/2	RM
;
; Register usage:
;	Input/Output
;	d0: exponent/scratch - final is 0
;	d2: x/0 or 24 for A9
;	d3: x/scratch - offset ptr into PTENRM array
;	d4: LEN/Unchanged
;	d5: 0/ICTR:LAMBDA
;	d6: ILOG/ILOG or k if ((k<=0)&(ILOG<k))
;	d7: k-factor/Unchanged
;	a0: ptr for original operand/final result
;	a1: x/ptr to PTENRM array
;	a2: x/x
;	fp0: float(ILOG)/Unchanged
;	fp1: x/10^ISCALE
;	fp2: x/x
;	F_SCR1:x/x
;	F_SCR2:Abs(X) with $3fff exponent/Unchanged
;	L_SCR1:x/x
;	L_SCR2:first word of X packed/Unchanged

A7_str:	
	tst.l	d7		;test sign of k
	bgt.s	k_pos		;if pos and > 0, skip this
	cmp.l	d6,d7		;test k - ILOG
	blt.s	k_pos		;if ILOG >= k, skip this
	move.l	d7,d6		;if ((k<0) & (ILOG < k)) ILOG = k
k_pos:	
	move.l	d6,d0		;calc ILOG + 1 - LEN in d0
	addq.l	#1,d0		;add the 1
	sub.l	d4,d0		;sub off LEN
	swap	d5		;use upper word of d5 for LAMBDA
	clr.w	d5		;set it zero initially
	clr.w	d2		;set up d2 for very small case
	tst.l	d0		;test sign of ISCALE
	bge.s	iscale		;if pos, skip next inst
	addq.w	#1,d5		;if neg, set LAMBDA true
	cmp.l	#$ffffecd4,d0	;test iscale <= -4908
	bgt.s	no_inf		;if false, skip rest
	addi.l	#24,d0		;add in 24 to iscale
	move.l	#24,d2		;put 24 in d2 for A9
no_inf:	
	neg.l	d0		;and take abs of ISCALE
iscale:	
	fmove.s	FONE(pc),fp1	;init fp1 to 1
	bfextu	USER_FPCR(a6){26:2},d1 ;get initial rmode bits
	lsl.w	#1,d1		;put them in bits 2:1
	add.w	d5,d1		;add in LAMBDA
	lsl.w	#1,d1		;put them in bits 3:1
	tst.l	L_SCR2(a6)	;test sign of original x
	bge.s	.x_pos		;if pos, don't set bit 0
	addq.l	#1,d1		;if neg, set bit 0
.x_pos:
	lea.l	RBDTBL(pc),a2	;load rbdtbl base
	move.b	(a2,d1),d3	;load d3 with new rmode
	lsl.l	#4,d3		;put bits in proper position
	fmove.l	d3,fpcr		;load bits into fpu
	lsr.l	#4,d3		;put bits in proper position
	tst.b	d3		;decode new rmode for pten table
	bne.s	not_rn		;if zero, it is RN
	lea.l	PTENRN(pc),a1	;load a1 with RN table base
	bra.s	rmode		;exit decode
not_rn:
	lsr.b	#1,d3		;get lsb in carry
	bcc.s	.not_rp		;if carry clear, it is RM
	lea.l	PTENRP(pc),a1	;load a1 with RP table base
	bra.s	rmode		;exit decode
.not_rp:
	lea.l	PTENRM(pc),a1	;load a1 with RM table base
rmode:
	clr.l	d3		;clr table index
.e_loop:	
	lsr.l	#1,d0		;shift next bit into carry
	bcc.s	.e_next		;if zero, skip the mul
	fmul.x	(a1,d3),fp1	;mul by 10**(d3_bit_no)
.e_next:	
	add.l	#12,d3		;inc d3 to next pwrten table entry
	tst.l	d0		;test if ISCALE is zero
	bne.s	.e_loop		;if not, loop


; A8. Clr INEX; Force RZ.
;     The operation in A3 above may have set INEX2.  
;     RZ mode is forced for the scaling operation to insure
;     only one rounding error.  The grs bits are collected in 
;     the INEX flag for use in A10.
;
; Register usage:
;	Input/Output

	fmove.l	#0,FPSR		;clr INEX 
	fmove.l	#rz_mode,FPCR	;set RZ rounding mode


; A9. Scale X -> Y.
;     The mantissa is scaled to the desired number of significant
;     digits.  The excess digits are collected in INEX2. If mul,
;     Check d2 for excess 10 exponential value.  If not zero, 
;     the iscale value would have caused the pwrten calculation
;     to overflow.  Only a negative iscale can cause this, so
;     multiply by 10^(d2), which is now only allowed to be 24,
;     with a multiply by 10^8 and 10^16, which is exact since
;     10^24 is exact.  If the input was denormalized, we must
;     create a busy stack frame with the mul command and the
;     two operands, and allow the fpu to complete the multiply.
;
; Register usage:
;	Input/Output
;	d0: FPCR with RZ mode/Unchanged
;	d2: 0 or 24/unchanged
;	d3: x/x
;	d4: LEN/Unchanged
;	d5: ICTR:LAMBDA
;	d6: ILOG/Unchanged
;	d7: k-factor/Unchanged
;	a0: ptr for original operand/final result
;	a1: ptr to PTENRM array/Unchanged
;	a2: x/x
;	fp0: float(ILOG)/X adjusted for SCALE (Y)
;	fp1: 10^ISCALE/Unchanged
;	fp2: x/x
;	F_SCR1:x/x
;	F_SCR2:Abs(X) with $3fff exponent/Unchanged
;	L_SCR1:x/x
;	L_SCR2:first word of X packed/Unchanged

A9_str:	
	fmove.x	(a0),fp0	;load X from memory
	fabs.x	fp0		;use abs(X)
	tst.w	d5		;LAMBDA is in lower word of d5
	bne.s	sc_mul		;if neg (LAMBDA = 1), scale by mul
	fdiv.x	fp1,fp0		;calculate X / SCALE -> Y to fp0
	bra.s	A10_st		;branch to A10

sc_mul:
	tst.b	BINDEC_FLG(a6)	;check for denorm
	beq.s	A9_norm		;if norm, continue with mul
	fmovem.x fp1-fp1,-(a7)	;load ETEMP with 10^ISCALE
	move.l	8(a0),-(a7)	;load FPTEMP with input arg
	move.l	4(a0),-(a7)
	move.l	(a0),-(a7)
	move.l	#18,d3		;load count for busy stack
A9_loop:
	clr.l	-(a7)		;clear lword on stack
	dbf	d3,A9_loop	
	move.b	VER_TMP(a6),(a7) ;write current version number
	move.b	#BUSY_SIZE-4,1(a7) ;write current busy size 
	move.b	#$10,$44(a7)	;set fcefpte[15] bit
	move.w	#$0023,$40(a7)	;load cmdreg1b with mul command
	move.b	#$fe,$8(a7)	;load all 1s to cu savepc
	frestore (a7)+		;restore frame to fpu for completion
	fmul.x	36(a1),fp0	;multiply fp0 by 10^8
	fmul.x	48(a1),fp0	;multiply fp0 by 10^16
	bra.s	A10_st
A9_norm:
	tst.w	d2		;test for small exp case
	beq.s	A9_con		;if zero, continue as normal
	fmul.x	36(a1),fp0	;multiply fp0 by 10^8
	fmul.x	48(a1),fp0	;multiply fp0 by 10^16
A9_con:
	fmul.x	fp1,fp0		;calculate X * SCALE -> Y to fp0


; A10. Or in INEX.
;      If INEX is set, round error occurred.  This is compensated
;      for by 'or-ing' in the INEX2 flag to the lsb of Y.
;
; Register usage:
;	Input/Output
;	d0: FPCR with RZ mode/FPSR with INEX2 isolated
;	d2: x/x
;	d3: x/x
;	d4: LEN/Unchanged
;	d5: ICTR:LAMBDA
;	d6: ILOG/Unchanged
;	d7: k-factor/Unchanged
;	a0: ptr for original operand/final result
;	a1: ptr to PTENxx array/Unchanged
;	a2: x/ptr to FP_SCR2(a6)
;	fp0: Y/Y with lsb adjusted
;	fp1: 10^ISCALE/Unchanged
;	fp2: x/x

A10_st:	
	fmove.l	FPSR,d0		;get FPSR
	fmove.x	fp0,FP_SCR2(a6)	;move Y to memory
	lea.l	FP_SCR2(a6),a2	;load a2 with ptr to FP_SCR2
	btst.l	#9,d0		;check if INEX2 set
	beq.s	A11_st		;if clear, skip rest
	ori.l	#1,8(a2)	;or in 1 to lsb of mantissa
	fmove.x	FP_SCR2(a6),fp0	;write adjusted Y back to fpu


; A11. Restore original FPCR; set size ext.
;      Perform FINT operation in the user's rounding mode.  Keep
;      the size to extended.  The sintdo entry point in the sint
;      routine expects the FPCR value to be in USER_FPCR for
;      mode and precision.  The original FPCR is saved in L_SCR1.

A11_st:	
	move.l	USER_FPCR(a6),L_SCR1(a6) ;save it for later
	andi.l	#$00000030,USER_FPCR(a6) ;set size to ext, 
;					;block exceptions


; A12. Calculate YINT = FINT(Y) according to user's rounding mode.
;      The FPSP routine sintd0 is used.  The output is in fp0.
;
; Register usage:
;	Input/Output
;	d0: FPSR with AINEX cleared/FPCR with size set to ext
;	d2: x/x/scratch
;	d3: x/x
;	d4: LEN/Unchanged
;	d5: ICTR:LAMBDA/Unchanged
;	d6: ILOG/Unchanged
;	d7: k-factor/Unchanged
;	a0: ptr for original operand/src ptr for sintdo
;	a1: ptr to PTENxx array/Unchanged
;	a2: ptr to FP_SCR2(a6)/Unchanged
;	a6: temp pointer to FP_SCR2(a6) - orig value saved and restored
;	fp0: Y/YINT
;	fp1: 10^ISCALE/Unchanged
;	fp2: x/x
;	F_SCR1:x/x
;	F_SCR2:Y adjusted for inex/Y with original exponent
;	L_SCR1:x/original USER_FPCR
;	L_SCR2:first word of X packed/Unchanged

A12_st:
	movem.l	d0-d1/a0-a1,-(a7)	;save regs used by sintd0	
	move.l	L_SCR1(a6),-(a7)
	move.l	L_SCR2(a6),-(a7)
	lea.l	FP_SCR2(a6),a0		;a0 is ptr to F_SCR2(a6)
	fmove.x	fp0,(a0)		;move Y to memory at FP_SCR2(a6)
	tst.l	L_SCR2(a6)		;test sign of original operand
	bge.s	do_fint			;if pos, use Y 
	or.l	#$80000000,(a0)		;if neg, use -Y
do_fint:
	move.l	USER_FPSR(a6),-(a7)
	bsr	sintdo			;sint routine returns int in fp0
	move.b	(a7),USER_FPSR(a6)
	add.l	#4,a7
	move.l	(a7)+,L_SCR2(a6)
	move.l	(a7)+,L_SCR1(a6)
	movem.l	(a7)+,d0-d1/a0-a1	;restore regs used by sint	
	move.l	L_SCR2(a6),FP_SCR2(a6)	;restore original exponent
	move.l	L_SCR1(a6),USER_FPCR(a6) ;restore user's FPCR


; A13. Check for LEN digits.
;      If the int operation results in more than LEN digits,
;      or less than LEN -1 digits, adjust ILOG and repeat from
;      A6.  This test occurs only on the first pass.  If the
;      result is exactly 10^LEN, decrement ILOG and divide
;      the mantissa by 10.  The calculation of 10^LEN cannot
;      be inexact, since all powers of ten upto 10^27 are exact
;      in extended precision, so the use of a previous power-of-ten
;      table will introduce no error.
;
;
; Register usage:
;	Input/Output
;	d0: FPCR with size set to ext/scratch final = 0
;	d2: x/x
;	d3: x/scratch final = x
;	d4: LEN/LEN adjusted
;	d5: ICTR:LAMBDA/LAMBDA:ICTR
;	d6: ILOG/ILOG adjusted
;	d7: k-factor/Unchanged
;	a0: pointer into memory for packed bcd string formation
;	a1: ptr to PTENxx array/Unchanged
;	a2: ptr to FP_SCR2(a6)/Unchanged
;	fp0: int portion of Y/abs(YINT) adjusted
;	fp1: 10^ISCALE/Unchanged
;	fp2: x/10^LEN
;	F_SCR1:x/x
;	F_SCR2:Y with original exponent/Unchanged
;	L_SCR1:original USER_FPCR/Unchanged
;	L_SCR2:first word of X packed/Unchanged

A13_st:	
	swap	d5		;put ICTR in lower word of d5
	tst.w	d5		;check if ICTR = 0
	bne	not_zr		;if non-zero, go to second test
;
; Compute 10^(LEN-1)
;
	fmove.s	FONE(pc),fp2	;init fp2 to 1.0
	move.l	d4,d0		;put LEN in d0
	subq.l	#1,d0		;d0 = LEN -1
	clr.l	d3		;clr table index
l_loop:	
	lsr.l	#1,d0		;shift next bit into carry
	bcc.s	l_next		;if zero, skip the mul
	fmul.x	(a1,d3),fp2	;mul by 10**(d3_bit_no)
l_next:
	add.l	#12,d3		;inc d3 to next pwrten table entry
	tst.l	d0		;test if LEN is zero
	bne.s	l_loop		;if not, loop
;
; 10^LEN-1 is computed for this test and A14.  If the input was
; denormalized, check only the case in which YINT > 10^LEN.
;
	tst.b	BINDEC_FLG(a6)	;check if input was norm
	beq.s	A13_con		;if norm, continue with checking
	fabs.x	fp0		;take abs of YINT
	bra	test_2
;
; Compare abs(YINT) to 10^(LEN-1) and 10^LEN
;
A13_con:
	fabs.x	fp0		;take abs of YINT
	fcmp.x	fp2,fp0		;compare abs(YINT) with 10^(LEN-1)
	fbge	test_2		;if greater, do next test
	subq.l	#1,d6		;subtract 1 from ILOG
	move.w	#1,d5		;set ICTR
	fmove.l	#rm_mode,FPCR	;set rmode to RM
	fmul.s	FTEN(pc),fp2	;compute 10^LEN 
	bra	A6_str		;return to A6 and recompute YINT
test_2:
	fmul.s	FTEN(pc),fp2	;compute 10^LEN
	fcmp.x	fp2,fp0		;compare abs(YINT) with 10^LEN
	fblt	A14_st		;if less, all is ok, go to A14
	fbgt	fix_ex		;if greater, fix and redo
	fdiv.s	FTEN(pc),fp0	;if equal, divide by 10
	addq.l	#1,d6		; and inc ILOG
	bra.s	A14_st		; and continue elsewhere
fix_ex:
	addq.l	#1,d6		;increment ILOG by 1
	move.w	#1,d5		;set ICTR
	fmove.l	#rm_mode,FPCR	;set rmode to RM
	bra	A6_str		;return to A6 and recompute YINT
;
; Since ICTR <> 0, we have already been through one adjustment, 
; and shouldn't have another; this is to check if abs(YINT) = 10^LEN
; 10^LEN is again computed using whatever table is in a1 since the
; value calculated cannot be inexact.
;
not_zr:
	fmove.s	FONE(pc),fp2	;init fp2 to 1.0
	move.l	d4,d0		;put LEN in d0
	clr.l	d3		;clr table index
z_loop:
	lsr.l	#1,d0		;shift next bit into carry
	bcc.s	z_next		;if zero, skip the mul
	fmul.x	(a1,d3),fp2	;mul by 10**(d3_bit_no)
z_next:
	add.l	#12,d3		;inc d3 to next pwrten table entry
	tst.l	d0		;test if LEN is zero
	bne.s	z_loop		;if not, loop
	fabs.x	fp0		;get abs(YINT)
	fcmp.x	fp2,fp0		;check if abs(YINT) = 10^LEN
	fbne	A14_st		;if not, skip this
	fdiv.s	FTEN(pc),fp0	;divide abs(YINT) by 10
	addq.l	#1,d6		;and inc ILOG by 1
	addq.l	#1,d4		; and inc LEN
	fmul.s	FTEN(pc),fp2	; if LEN++, the get 10^^LEN


; A14. Convert the mantissa to bcd.
;      The binstr routine is used to convert the LEN digit 
;      mantissa to bcd in memory.  The input to binstr is
;      to be a fraction; i.e. (mantissa)/10^LEN and adjusted
;      such that the decimal point is to the left of bit 63.
;      The bcd digits are stored in the correct position in 
;      the final string area in memory.
;
;
; Register usage:
;	Input/Output
;	d0: x/LEN call to binstr - final is 0
;	d1: x/0
;	d2: x/ms 32-bits of mant of abs(YINT)
;	d3: x/ls 32-bits of mant of abs(YINT)
;	d4: LEN/Unchanged
;	d5: ICTR:LAMBDA/LAMBDA:ICTR
;	d6: ILOG
;	d7: k-factor/Unchanged
;	a0: pointer into memory for packed bcd string formation
;	    /ptr to first mantissa byte in result string
;	a1: ptr to PTENxx array/Unchanged
;	a2: ptr to FP_SCR2(a6)/Unchanged
;	fp0: int portion of Y/abs(YINT) adjusted
;	fp1: 10^ISCALE/Unchanged
;	fp2: 10^LEN/Unchanged
;	F_SCR1:x/Work area for final result
;	F_SCR2:Y with original exponent/Unchanged
;	L_SCR1:original USER_FPCR/Unchanged
;	L_SCR2:first word of X packed/Unchanged

A14_st:	
	fmove.l	#rz_mode,FPCR	;force rz for conversion
	fdiv.x	fp2,fp0		;divide abs(YINT) by 10^LEN
	lea.l	FP_SCR1(a6),a0
	fmove.x	fp0,(a0)	;move abs(YINT)/10^LEN to memory
	move.l	4(a0),d2	;move 2nd word of FP_RES to d2
	move.l	8(a0),d3	;move 3rd word of FP_RES to d3
	clr.l	4(a0)		;zero word 2 of FP_RES
	clr.l	8(a0)		;zero word 3 of FP_RES
	move.l	(a0),d0		;move exponent to d0
	swap	d0		;put exponent in lower word
	beq.s	no_sft		;if zero, don't shift
	subi.l	#$3ffd,d0	;sub bias less 2 to make fract
	tst.l	d0		;check if > 1
	bgt.s	no_sft		;if so, don't shift
	neg.l	d0		;make exp positive
m_loop:
	lsr.l	#1,d2		;shift d2:d3 right, add 0s 
	roxr.l	#1,d3		;the number of places
	dbf	d0,m_loop	;given in d0
no_sft:
	tst.l	d2		;check for mantissa of zero
	bne.s	no_zr		;if not, go on
	tst.l	d3		;continue zero check
	beq.s	zer_m		;if zero, go directly to binstr
no_zr:
	clr.l	d1		;put zero in d1 for addx
	addi.l	#$00000080,d3	;inc at bit 7
	addx.l	d1,d2		;continue inc
	andi.l	#$ffffff80,d3	;strip off lsb not used by 882
zer_m:
	move.l	d4,d0		;put LEN in d0 for binstr call
	addq.l	#3,a0		;a0 points to M16 byte in result
	bsr	binstr		;call binstr to convert mant


; A15. Convert the exponent to bcd.
;      As in A14 above, the exp is converted to bcd and the
;      digits are stored in the final string.
;
;      Digits are stored in L_SCR1(a6) on return from BINDEC as:
;
;  	 32               16 15                0
;	-----------------------------------------
;  	;  0 ; e3 ; e2 ; e1 ; e4 ;  X ;  X ;  X ; ;	-----------------------------------------
;
; And are moved into their proper places in FP_SCR1.  If digit e4
; is non-zero, OPERR is signaled.  In all cases, all 4 digits are
; written as specified in the 881/882 manual for packed decimal.
;
; Register usage:
;	Input/Output
;	d0: x/LEN call to binstr - final is 0
;	d1: x/scratch (0);shift count for final exponent packing
;	d2: x/ms 32-bits of exp fraction/scratch
;	d3: x/ls 32-bits of exp fraction
;	d4: LEN/Unchanged
;	d5: ICTR:LAMBDA/LAMBDA:ICTR
;	d6: ILOG
;	d7: k-factor/Unchanged
;	a0: ptr to result string/ptr to L_SCR1(a6)
;	a1: ptr to PTENxx array/Unchanged
;	a2: ptr to FP_SCR2(a6)/Unchanged
;	fp0: abs(YINT) adjusted/float(ILOG)
;	fp1: 10^ISCALE/Unchanged
;	fp2: 10^LEN/Unchanged
;	F_SCR1:Work area for final result/BCD result
;	F_SCR2:Y with original exponent/ILOG/10^4
;	L_SCR1:original USER_FPCR/Exponent digits on return from binstr
;	L_SCR2:first word of X packed/Unchanged

A15_st:	
	tst.b	BINDEC_FLG(a6)	;check for denorm
	beq.s	not_denorm
	ftst.x	fp0		;test for zero
	fbeq	den_zero	;if zero, use k-factor or 4933
	fmove.l	d6,fp0		;float ILOG
	fabs.x	fp0		;get abs of ILOG
	bra.s	convrt
den_zero:
	tst.l	d7		;check sign of the k-factor
	blt.s	use_ilog	;if negative, use ILOG
	fmove.s	F4933(pc),fp0	;force exponent to 4933
	bra.s	convrt		;do it
use_ilog:
	fmove.l	d6,fp0		;float ILOG
	fabs.x	fp0		;get abs of ILOG
	bra.s	convrt
not_denorm:
	ftst.x	fp0		;test for zero
	fbne	.not_zero	;if zero, force exponent
	fmove.s	FONE(pc),fp0	;force exponent to 1
	bra.s	convrt		;do it
.not_zero:	
	fmove.l	d6,fp0		;float ILOG
	fabs.x	fp0		;get abs of ILOG
convrt:
	fdiv.x	24(a1),fp0	;compute ILOG/10^4
	fmove.x	fp0,FP_SCR2(a6)	;store fp0 in memory
	move.l	4(a2),d2	;move word 2 to d2
	move.l	8(a2),d3	;move word 3 to d3
	move.w	(a2),d0		;move exp to d0
	beq.s	x_loop_fin	;if zero, skip the shift
	subi.w	#$3ffd,d0	;subtract off bias
	neg.w	d0		;make exp positive
x_loop:
	lsr.l	#1,d2		;shift d2:d3 right 
	roxr.l	#1,d3		;the number of places
	dbf	d0,x_loop	;given in d0
x_loop_fin:
	clr.l	d1		;put zero in d1 for addx
	addi.l	#$00000080,d3	;inc at bit 6
	addx.l	d1,d2		;continue inc
	andi.l	#$ffffff80,d3	;strip off lsb not used by 882
	move.l	#4,d0		;put 4 in d0 for binstr call
	lea.l	L_SCR1(a6),a0	;a0 is ptr to L_SCR1 for exp digits
	bsr	binstr		;call binstr to convert exp
	move.l	L_SCR1(a6),d0	;load L_SCR1 lword to d0 
	move.l	#12,d1		;use d1 for shift count
	lsr.l	d1,d0		;shift d0 right by 12
	bfins	d0,FP_SCR1(a6){4:12} ;put e3:e2:e1 in FP_SCR1
	lsr.l	d1,d0		;shift d0 right by 12
	bfins	d0,FP_SCR1(a6){16:4} ;put e4 in FP_SCR1 
	tst.b	d0		;check if e4 is zero
	beq.s	A16_st		;if zero, skip rest
	or.l	#opaop_mask,USER_FPSR(a6) ;set OPERR & AIOP in USER_FPSR


; A16. Write sign bits to final string.
;	   Sigma is bit 31 of initial value; RHO is bit 31 of d6 (ILOG).
;
; Register usage:
;	Input/Output
;	d0: x/scratch - final is x
;	d2: x/x
;	d3: x/x
;	d4: LEN/Unchanged
;	d5: ICTR:LAMBDA/LAMBDA:ICTR
;	d6: ILOG/ILOG adjusted
;	d7: k-factor/Unchanged
;	a0: ptr to L_SCR1(a6)/Unchanged
;	a1: ptr to PTENxx array/Unchanged
;	a2: ptr to FP_SCR2(a6)/Unchanged
;	fp0: float(ILOG)/Unchanged
;	fp1: 10^ISCALE/Unchanged
;	fp2: 10^LEN/Unchanged
;	F_SCR1:BCD result with correct signs
;	F_SCR2:ILOG/10^4
;	L_SCR1:Exponent digits on return from binstr
;	L_SCR2:first word of X packed/Unchanged

A16_st:
	clr.l	d0		;clr d0 for collection of signs
	andi.b	#$0f,FP_SCR1(a6) ;clear first nibble of FP_SCR1 
	tst.l	L_SCR2(a6)	;check sign of original mantissa
	bge.s	mant_p		;if pos, don't set SM
	moveq.l	#2,d0		;move 2 in to d0 for SM
mant_p:
	tst.l	d6		;check sign of ILOG
	bge.s	wr_sgn		;if pos, don't set SE
	addq.l	#1,d0		;set bit 0 in d0 for SE 
wr_sgn:
	bfins	d0,FP_SCR1(a6){0:2} ;insert SM and SE into FP_SCR1

; Clean up and restore all registers used.

	fmove.l	#0,FPSR		;clear possible inex2/ainex bits
	fmovem.x (a7)+,fp0-fp2
	movem.l	(a7)+,d2-d7/a2
	rts

	;end
;
;	binstr.sa 3.3 12/19/90
;
;
;	Description: Converts a 64-bit binary integer to bcd.
;
;	Input: 64-bit binary integer in d2:d3, desired length (LEN) in
;          d0, and a  pointer to start in memory for bcd characters
;          in d0. (This pointer must point to byte 4 of the first
;          lword of the packed decimal memory string.)
;
;	Output:	LEN bcd digits representing the 64-bit integer.
;
;	Algorithm:
;		The 64-bit binary is assumed to have a decimal point before
;		bit 63.  The fraction is multiplied by 10 using a mul by 2
;		shift and a mul by 8 shift.  The bits shifted out of the
;		msb form a decimal digit.  This process is iterated until
;		LEN digits are formed.
;
;	A1. Init d7 to 1.  D7 is the byte digit counter, and if 1, the
;		digit formed will be assumed the least significant.  This is
;		to force the first byte formed to have a 0 in the upper 4 bits.
;
;	A2. Beginning of the loop:
;		Copy the fraction in d2:d3 to d4:d5.
;
;	A3. Multiply the fraction in d2:d3 by 8 using bit-field
;		extracts and shifts.  The three msbs from d2 will go into
;		d1.
;
;	A4. Multiply the fraction in d4:d5 by 2 using shifts.  The msb
;		will be collected by the carry.
;
;	A5. Add using the carry the 64-bit quantities in d2:d3 and d4:d5
;		into d2:d3.  D1 will contain the bcd digit formed.
;
;	A6. Test d7.  If zero, the digit formed is the ms digit.  If non-
;		zero, it is the ls digit.  Put the digit in its place in the
;		upper word of d0.  If it is the ls digit, write the word
;		from d0 to memory.
;
;	A7. Decrement d6 (LEN counter) and repeat the loop until zero.
;
;	Implementation Notes:
;
;	The registers are used as follows:
;
;		d0: LEN counter
;		d1: temp used to form the digit
;		d2: upper 32-bits of fraction for mul by 8
;		d3: lower 32-bits of fraction for mul by 8
;		d4: upper 32-bits of fraction for mul by 2
;		d5: lower 32-bits of fraction for mul by 2
;		d6: temp for bit-field extracts
;		d7: byte digit formation word;digit count {0,1}
;		a0: pointer into memory for packed bcd string formation
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;BINSTR    idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	

	;|.global	binstr
binstr:
	movem.l	d0-d7,-(a7)
;
; A1: Init d7
;
	moveq.l	#1,d7			;init d7 for second digit
	subq.l	#1,d0			;for dbf d0 would have LEN+1 passes
;
; A2. Copy d2:d3 to d4:d5.  Start loop.
;
loop:
	move.l	d2,d4			;copy the fraction before muls
	move.l	d3,d5			;to d4:d5
;
; A3. Multiply d2:d3 by 8; extract msbs into d1.
;
	bfextu	d2{0:3},d1		;copy 3 msbs of d2 into d1
	asl.l	#3,d2			;shift d2 left by 3 places
	bfextu	d3{0:3},d6		;copy 3 msbs of d3 into d6
	asl.l	#3,d3			;shift d3 left by 3 places
	or.l	d6,d2			;or in msbs from d3 into d2
;
; A4. Multiply d4:d5 by 2; add carry out to d1.
;
	asl.l	#1,d5			;mul d5 by 2
	roxl.l	#1,d4			;mul d4 by 2
	swap	d6			;put 0 in d6 lower word
	addx.w	d6,d1			;add in extend from mul by 2
;
; A5. Add mul by 8 to mul by 2.  D1 contains the digit formed.
;
	add.l	d5,d3			;add lower 32 bits
	nop				;ERRATA ; FIX #13 (Rev. 1.2 6/6/90)
	addx.l	d4,d2			;add with extend upper 32 bits
	nop				;ERRATA ; FIX #13 (Rev. 1.2 6/6/90)
	addx.w	d6,d1			;add in extend from add to d1
	swap	d6			;with d6 = 0; put 0 in upper word
;
; A6. Test d7 and branch.
;
	tst.w	d7			;if zero, store digit & to loop
	beq.s	first_d			;if non-zero, form byte & write
sec_d:
	swap	d7			;bring first digit to word d7b
	asl.w	#4,d7			;first digit in upper 4 bits d7b
	add.w	d1,d7			;add in ls digit to d7b
	move.b	d7,(a0)+		;store d7b byte in memory
	swap	d7			;put LEN counter in word d7a
	clr.w	d7			;set d7a to signal no digits done
	dbf	d0,loop		;do loop some more!
	bra.s	end_bstr		;finished, so exit
first_d:
	swap	d7			;put digit word in d7b
	move.w	d1,d7			;put new digit in d7b
	swap	d7			;put LEN counter in word d7a
	addq.w	#1,d7			;set d7a to signal first digit done
	dbf	d0,loop		;do loop some more!
	swap	d7			;put last digit in string
	lsl.w	#4,d7			;move it to upper 4 bits
	move.b	d7,(a0)+		;store it in memory string
;
; Clean up and return with result in fp0.
;
end_bstr:
	movem.l	(a7)+,d0-d7
	rts
	;end
;
;	bugfix.sa 3.2 1/31/91
;
;
;	This file contains workarounds for bugs in the 040
;	relating to the Floating-Point Software Package (FPSP)
;
;	Fixes for bugs: 1238
;
;	Bug: 1238 
;
;
;    /* The following dirty_bit clear should be left in
;     * the handler permanently to improve throughput.
;     * The dirty_bits are located at bits [23:16] in
;     * longword $08 in the busy frame $4x60.  Bit 16
;     * corresponds to FP0, bit 17 corresponds to FP1,
;     * and so on.
;     */
;    if  (E3_exception_just_serviced)   {
;         dirty_bit[cmdreg3b[9:7]] = 0;
;         }
;
;    if  (fsave_format_version != $40)  {goto NOFIX}
;
;    if !(E3_exception_just_serviced)   {goto NOFIX}
;    if  (cupc == 0000000)              {goto NOFIX}
;    if  ((cmdreg1b[15:13] != 000) &&
;         (cmdreg1b[15:10] != 010001))  {goto NOFIX}
;    if (((cmdreg1b[15:13] != 000) |; ((cmdreg1b[12:10] != cmdreg2b[9:7]) &&
;				      (cmdreg1b[12:10] != cmdreg3b[9:7]))  ) &&
;	 ((cmdreg1b[ 9: 7] != cmdreg2b[9:7]) &&
;	  (cmdreg1b[ 9: 7] != cmdreg3b[9:7])) )  {goto NOFIX}
;
;    /* Note: for 6d43b or 8d43b, you may want to add the following code
;     * to get better coverage.  (If you do not insert this code, the part
;     * won't lock up; it will simply get the wrong answer.)
;     * Do NOT insert this code for 10d43b or later parts.
;     *
;     *  if (fpiarcu == integer stack return address) {
;     *       cupc = 0000000;
;     *       goto NOFIX;
;     *       }
;     */
;
;    if (cmdreg1b[15:13] != 000)   {goto FIX_OPCLASS2}
;    FIX_OPCLASS0:
;    if (((cmdreg1b[12:10] == cmdreg2b[9:7]) |; ;	 (cmdreg1b[ 9: 7] == cmdreg2b[9:7])) &&
;	(cmdreg1b[12:10] != cmdreg3b[9:7]) &&
;	(cmdreg1b[ 9: 7] != cmdreg3b[9:7]))  {  /* xu conflict only */
;	/* We execute the following code if there is an
;	   xu conflict and NOT an nu conflict */
;
;	/* first save some values on the fsave frame */
;	stag_temp     = STAG[fsave_frame];
;	cmdreg1b_temp = CMDREG1B[fsave_frame];
;	dtag_temp     = DTAG[fsave_frame];
;	ete15_temp    = ETE15[fsave_frame];
;
;	CUPC[fsave_frame] = 0000000;
;	FRESTORE
;	FSAVE
;
;	/* If the xu instruction is exceptional, we punt.
;	 * Otherwise, we would have to include OVFL/UNFL handler
;	 * code here to get the correct answer.
;	 */
;	if (fsave_frame_format == $4060) {goto KILL_PROCESS}
;
;	fsave_frame = /* build a long frame of all zeros */
;	fsave_frame_format = $4060;  /* label it as long frame */
;
;	/* load it with the temps we saved */
;	STAG[fsave_frame]     =  stag_temp;
;	CMDREG1B[fsave_frame] =  cmdreg1b_temp;
;	DTAG[fsave_frame]     =  dtag_temp;
;	ETE15[fsave_frame]    =  ete15_temp;
;
;	/* Make sure that the cmdreg3b dest reg is not going to
;	 * be destroyed by a FMOVEM at the end of all this code.
;	 * If it is, you should move the current value of the reg
;	 * onto the stack so that the reg will loaded with that value.
;	 */
;
;	/* All done.  Proceed with the code below */
;    }
;
;    etemp  = FP_reg_[cmdreg1b[12:10]];
;    ete15  = ~ete14;
;    cmdreg1b[15:10] = 010010;
;    clear(bug_flag_procIDxxxx);
;    FRESTORE and return;
;
;
;    FIX_OPCLASS2:
;    if ((cmdreg1b[9:7] == cmdreg2b[9:7]) &&
;	(cmdreg1b[9:7] != cmdreg3b[9:7]))  {  /* xu conflict only */
;	/* We execute the following code if there is an
;	   xu conflict and NOT an nu conflict */
;
;	/* first save some values on the fsave frame */
;	stag_temp     = STAG[fsave_frame];
;	cmdreg1b_temp = CMDREG1B[fsave_frame];
;	dtag_temp     = DTAG[fsave_frame];
;	ete15_temp    = ETE15[fsave_frame];
;	etemp_temp    = ETEMP[fsave_frame];
;
;	CUPC[fsave_frame] = 0000000;
;	FRESTORE
;	FSAVE
;
;
;	/* If the xu instruction is exceptional, we punt.
;	 * Otherwise, we would have to include OVFL/UNFL handler
;	 * code here to get the correct answer.
;	 */
;	if (fsave_frame_format == $4060) {goto KILL_PROCESS}
;
;	fsave_frame = /* build a long frame of all zeros */
;	fsave_frame_format = $4060;  /* label it as long frame */
;
;	/* load it with the temps we saved */
;	STAG[fsave_frame]     =  stag_temp;
;	CMDREG1B[fsave_frame] =  cmdreg1b_temp;
;	DTAG[fsave_frame]     =  dtag_temp;
;	ETE15[fsave_frame]    =  ete15_temp;
;	ETEMP[fsave_frame]    =  etemp_temp;
;
;	/* Make sure that the cmdreg3b dest reg is not going to
;	 * be destroyed by a FMOVEM at the end of all this code.
;	 * If it is, you should move the current value of the reg
;	 * onto the stack so that the reg will loaded with that value.
;	 */
;
;	/* All done.  Proceed with the code below */
;    }
;
;    if (etemp_exponent == min_sgl)   etemp_exponent = min_dbl;
;    if (etemp_exponent == max_sgl)   etemp_exponent = max_dbl;
;    cmdreg1b[15:10] = 010101;
;    clear(bug_flag_procIDxxxx);
;    FRESTORE and return;
;
;
;    NOFIX:
;    clear(bug_flag_procIDxxxx);
;    FRESTORE and return;
;


;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;BUGFIX    idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	

	;xref	fpsp_fmt_error

	;|.global	b1238_fix
b1238_fix:
;
; This code is entered only on completion of the handling of an 
; nu-generated ovfl, unfl, or inex exception.  If the version 
; number of the fsave is not $40, this handler is not necessary.
; Simply branch to fix_done and exit normally.
;
	cmpi.b	#VER_40,4(a7)
	bne	fix_done
;
; Test for cu_savepc equal to zero.  If not, this is not a bug
; #1238 case.
;
	move.b	CU_SAVEPC(a6),d0
	andi.b	#$FE,d0
	beq 	fix_done	;if zero, this is not bug #1238

;
; Test the register conflict aspect.  If opclass0, check for
; cu src equal to xu dest or equal to nu dest.  If so, go to 
; op0.  Else, or if opclass2, check for cu dest equal to
; xu dest or equal to nu dest.  If so, go to tst_opcl.  Else,
; exit, it is not the bug case.
;
; Check for opclass 0.  If not, go and check for opclass 2 and sgl.
;
	move.w	CMDREG1B(a6),d0
	andi.w	#$E000,d0		;strip all but opclass
	bne	op2sgl			;not opclass 0, check op2
;
; Check for cu and nu register conflict.  If one exists, this takes
; priority over a cu and xu conflict. 
;
	bfextu	CMDREG1B(a6){3:3},d0	;get 1st src 
	bfextu	CMDREG3B(a6){6:3},d1	;get 3rd dest
	cmp.b	d0,d1
	beq.s	op0			;if equal, continue bugfix
;
; Check for cu dest equal to nu dest.  If so, go and fix the 
; bug condition.  Otherwise, exit.
;
	bfextu	CMDREG1B(a6){6:3},d0	;get 1st dest 
	cmp.b	d0,d1			;cmp 1st dest with 3rd dest
	beq.s	op0			;if equal, continue bugfix
;
; Check for cu and xu register conflict.
;
	bfextu	CMDREG2B(a6){6:3},d1	;get 2nd dest
	cmp.b	d0,d1			;cmp 1st dest with 2nd dest
	beq.s	op0_xu			;if equal, continue bugfix
	bfextu	CMDREG1B(a6){3:3},d0	;get 1st src 
	cmp.b	d0,d1			;cmp 1st src with 2nd dest
	beq	op0_xu
	bne	fix_done		;if the reg checks fail, exit
;
; We have the opclass 0 situation.
;
op0:
	bfextu	CMDREG1B(a6){3:3},d0	;get source register no
	move.l	#7,d1
	sub.l	d0,d1
	clr.l	d0
	bset.l	d1,d0
	fmovem.x d0,ETEMP(a6)		;load source to ETEMP

	move.b	#$12,d0
	bfins	d0,CMDREG1B(a6){0:6}	;opclass 2, extended
;
;	Set ETEMP exponent bit 15 as the opposite of ete14
;
	btst	#6,ETEMP_EX(a6)		;check etemp exponent bit 14
	beq	setete15
	bclr	#etemp15_bit,STAG(a6)
	bra	finish
setete15:
	bset	#etemp15_bit,STAG(a6)
	bra	finish

;
; We have the case in which a conflict exists between the cu src or
; dest and the dest of the xu.  We must clear the instruction in 
; the cu and restore the state, allowing the instruction in the
; xu to complete.  Remember, the instruction in the nu
; was exceptional, and was completed by the appropriate handler.
; If the result of the xu instruction is not exceptional, we can
; restore the instruction from the cu to the frame and continue
; processing the original exception.  If the result is also
; exceptional, we choose to kill the process.
;
;	Items saved from the stack:
;	
;		$3c stag     - L_SCR1
;		$40 cmdreg1b - L_SCR2
;		$44 dtag     - L_SCR3
;
; The cu savepc is set to zero, and the frame is restored to the
; fpu.
;
op0_xu:
	move.l	STAG(a6),L_SCR1(a6)	
	move.l	CMDREG1B(a6),L_SCR2(a6)	
	move.l	DTAG(a6),L_SCR3(a6)
	andi.l	#$e0000000,L_SCR3(a6)
	move.b	#0,CU_SAVEPC(a6)
	move.l	(a7)+,d1		;save return address from bsr
	frestore (a7)+
	fsave	-(a7)
;
; Check if the instruction which just completed was exceptional.
; 
	cmp.w	#$4060,(a7)
	beq	op0_xb
; 
; It is necessary to isolate the result of the instruction in the
; xu if it is to fp0 - fp3 and write that value to the USER_FPn
; locations on the stack.  The correct destination register is in 
; cmdreg2b.
;
	bfextu	CMDREG2B(a6){6:3},d0	;get dest register no
	cmpi.l	#3,d0
	bgt.s	op0_xi
	beq.s	op0_fp3
	cmpi.l	#1,d0
	blt.s	op0_fp0
	beq.s	op0_fp1
op0_fp2:
	fmovem.x fp2-fp2,USER_FP2(a6)
	bra.s	op0_xi
op0_fp1:
	fmovem.x fp1-fp1,USER_FP1(a6)
	bra.s	op0_xi
op0_fp0:
	fmovem.x fp0-fp0,USER_FP0(a6)
	bra.s	op0_xi
op0_fp3:
	fmovem.x fp3-fp3,USER_FP3(a6)
;
; The frame returned is idle.  We must build a busy frame to hold
; the cu state information and setup etemp.
;
op0_xi:
	move.l	#22,d0		;clear 23 lwords
	clr.l	(a7)
op0_loop:
	clr.l	-(a7)
	dbf	d0,op0_loop
	move.l	#$40600000,-(a7)
	move.l	L_SCR1(a6),STAG(a6)
	move.l	L_SCR2(a6),CMDREG1B(a6)
	move.l	L_SCR3(a6),DTAG(a6)
	move.b	#$6,CU_SAVEPC(a6)
	move.l	d1,-(a7)		;return bsr return address
	bfextu	CMDREG1B(a6){3:3},d0	;get source register no
	move.l	#7,d1
	sub.l	d0,d1
	clr.l	d0
	bset.l	d1,d0
	fmovem.x d0,ETEMP(a6)		;load source to ETEMP

	move.b	#$12,d0
	bfins	d0,CMDREG1B(a6){0:6}	;opclass 2, extended
;
;	Set ETEMP exponent bit 15 as the opposite of ete14
;
	btst	#6,ETEMP_EX(a6)		;check etemp exponent bit 14
	beq	op0_sete15
	bclr	#etemp15_bit,STAG(a6)
	bra	finish
op0_sete15:
	bset	#etemp15_bit,STAG(a6)
	bra	finish

;
; The frame returned is busy.  It is not possible to reconstruct
; the code sequence to allow completion.  We will jump to 
; fpsp_fmt_error and allow the kernel to kill the process.
;
op0_xb:
	bra	fpsp_fmt_error

;
; Check for opclass 2 and single size.  If not both, exit.
;
op2sgl:
	move.w	CMDREG1B(a6),d0
	andi.w	#$FC00,d0		;strip all but opclass and size
	cmpi.w	#$4400,d0		;test for opclass 2 and size=sgl
	bne	fix_done		;if not, it is not bug 1238
;
; Check for cu dest equal to nu dest or equal to xu dest, with 
; a cu and nu conflict taking priority an nu conflict.  If either,
; go and fix the bug condition.  Otherwise, exit.
;
	bfextu	CMDREG1B(a6){6:3},d0	;get 1st dest 
	bfextu	CMDREG3B(a6){6:3},d1	;get 3rd dest
	cmp.b	d0,d1			;cmp 1st dest with 3rd dest
	beq	op2_com			;if equal, continue bugfix
	bfextu	CMDREG2B(a6){6:3},d1	;get 2nd dest 
	cmp.b	d0,d1			;cmp 1st dest with 2nd dest
	bne	fix_done		;if the reg checks fail, exit
;
; We have the case in which a conflict exists between the cu src or
; dest and the dest of the xu.  We must clear the instruction in 
; the cu and restore the state, allowing the instruction in the
; xu to complete.  Remember, the instruction in the nu
; was exceptional, and was completed by the appropriate handler.
; If the result of the xu instruction is not exceptional, we can
; restore the instruction from the cu to the frame and continue
; processing the original exception.  If the result is also
; exceptional, we choose to kill the process.
;
;	Items saved from the stack:
;	
;		$3c stag     - L_SCR1
;		$40 cmdreg1b - L_SCR2
;		$44 dtag     - L_SCR3
;		etemp        - FP_SCR2
;
; The cu savepc is set to zero, and the frame is restored to the
; fpu.
;
op2_xu:
	move.l	STAG(a6),L_SCR1(a6)	
	move.l	CMDREG1B(a6),L_SCR2(a6)	
	move.l	DTAG(a6),L_SCR3(a6)	
	andi.l	#$e0000000,L_SCR3(a6)
	move.b	#0,CU_SAVEPC(a6)
	move.l	ETEMP(a6),FP_SCR2(a6)
	move.l	ETEMP_HI(a6),FP_SCR2+4(a6)
	move.l	ETEMP_LO(a6),FP_SCR2+8(a6)
	move.l	(a7)+,d1		;save return address from bsr
	frestore (a7)+
	fsave	-(a7)
;
; Check if the instruction which just completed was exceptional.
; 
	cmp.w	#$4060,(a7)
	beq	op2_xb
; 
; It is necessary to isolate the result of the instruction in the
; xu if it is to fp0 - fp3 and write that value to the USER_FPn
; locations on the stack.  The correct destination register is in 
; cmdreg2b.
;
	bfextu	CMDREG2B(a6){6:3},d0	;get dest register no
	cmpi.l	#3,d0
	bgt.s	op2_xi
	beq.s	op2_fp3
	cmpi.l	#1,d0
	blt.s	op2_fp0
	beq.s	op2_fp1
op2_fp2:
	fmovem.x fp2-fp2,USER_FP2(a6)
	bra.s	op2_xi
op2_fp1:
	fmovem.x fp1-fp1,USER_FP1(a6)
	bra.s	op2_xi
op2_fp0:
	fmovem.x fp0-fp0,USER_FP0(a6)
	bra.s	op2_xi
op2_fp3:
	fmovem.x fp3-fp3,USER_FP3(a6)
;
; The frame returned is idle.  We must build a busy frame to hold
; the cu state information and fix up etemp.
;
op2_xi:
	move.l	#22,d0		;clear 23 lwords
	clr.l	(a7)
op2_loop:
	clr.l	-(a7)
	dbf	d0,op2_loop
	move.l	#$40600000,-(a7)
	move.l	L_SCR1(a6),STAG(a6)
	move.l	L_SCR2(a6),CMDREG1B(a6)
	move.l	L_SCR3(a6),DTAG(a6)
	move.b	#$6,CU_SAVEPC(a6)
	move.l	FP_SCR2(a6),ETEMP(a6)
	move.l	FP_SCR2+4(a6),ETEMP_HI(a6)
	move.l	FP_SCR2+8(a6),ETEMP_LO(a6)
	move.l	d1,-(a7)
	bra	op2_com

;
; We have the opclass 2 single source situation.
;
op2_com:
	move.b	#$15,d0
	bfins	d0,CMDREG1B(a6){0:6}	;opclass 2, double

	cmp.w	#$407F,ETEMP_EX(a6)	;single +max
	bne.s	case2
	move.w	#$43FF,ETEMP_EX(a6)	;to double +max
	bra	finish
case2:	
	cmp.w	#$C07F,ETEMP_EX(a6)	;single -max
	bne.s	case3
	move.w	#$C3FF,ETEMP_EX(a6)	;to double -max
	bra	finish
case3:	
	cmp.w	#$3F80,ETEMP_EX(a6)	;single +min
	bne.s	case4
	move.w	#$3C00,ETEMP_EX(a6)	;to double +min
	bra	finish
case4:
	cmp.w	#$BF80,ETEMP_EX(a6)	;single -min
	bne	fix_done
	move.w	#$BC00,ETEMP_EX(a6)	;to double -min
	bra	finish
;
; The frame returned is busy.  It is not possible to reconstruct
; the code sequence to allow completion.  fpsp_fmt_error causes
; an fline illegal instruction to be executed.
;
; You should replace the jump to fpsp_fmt_error with a jump
; to the entry point used to kill a process. 
;
op2_xb:
	bra	fpsp_fmt_error

;
; Enter here if the case is not of the situations affected by
; bug #1238, or if the fix is completed, and exit.
;
finish:
fix_done:
	rts

	;end
;
;	decbin.sa 3.3 12/19/90
;
;	Description: Converts normalized packed bcd value pointed to by
;	register A6 to extended-precision value in FP0.
;
;	Input: Normalized packed bcd value in ETEMP(a6).
;
;	Output:	Exact floating-point representation of the packed bcd value.
;
;	Saves and Modifies: D2-D5
;
;	Speed: The program decbin takes ??? cycles to execute.
;
;	Object Size:
;
;	External Reference(s): None.
;
;	Algorithm:
;	Expected is a normal bcd (i.e. non-exceptional; all inf, zero,
;	and NaN operands are dispatched without entering this routine)
;	value in 68881/882 format at location ETEMP(A6).
;
;	A1.	Convert the bcd exponent to binary by successive adds and muls.
;	Set the sign according to SE. Subtract 16 to compensate
;	for the mantissa which is to be interpreted as 17 integer
;	digits, rather than 1 integer and 16 fraction digits.
;	Note: this operation can never overflow.
;
;	A2. Convert the bcd mantissa to binary by successive
;	adds and muls in FP0. Set the sign according to SM.
;	The mantissa digits will be converted with the decimal point
;	assumed following the least-significant digit.
;	Note: this operation can never overflow.
;
;	A3. Count the number of leading/trailing zeros in the
;	bcd string.  If SE is positive, count the leading zeros;
;	if negative, count the trailing zeros.  Set the adjusted
;	exponent equal to the exponent from A1 and the zero count
;	added if SM = 1 and subtracted if SM = 0.  Scale the
;	mantissa the equivalent of forcing in the bcd value:
;
;	SM = 0	a non-zero digit in the integer position
;	SM = 1	a non-zero digit in Mant0, lsd of the fraction
;
;	this will insure that any value, regardless of its
;	representation (ex. 0.1E2, 1E1, 10E0, 100E-1), is converted
;	consistently.
;
;	A4. Calculate the factor 10^exp in FP1 using a table of
;	10^(2^n) values.  To reduce the error in forming factors
;	greater than 10^27, a directed rounding scheme is used with
;	tables rounded to RN, RM, and RP, according to the table
;	in the comments of the pwrten section.
;
;	A5. Form the final binary number by scaling the mantissa by
;	the exponent factor.  This is done by multiplying the
;	mantissa in FP0 by the factor in FP1 if the adjusted
;	exponent sign is positive, and dividing FP0 by FP1 if
;	it is negative.
;
;	Clean up and return.  Check if the final mul or div resulted
;	in an inex2 exception.  If so, set inex1 in the fpsr and 
;	check if the inex1 exception is enabled.  If so, set d7 upper
;	word to $0100.  This will signal unimp.sa that an enabled inex1
;	exception occurred.  Unimp will fix the stack.
;	

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;DECBIN    idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	

;
;	PTENRN, PTENRM, and PTENRP are arrays of powers of 10 rounded
;	to nearest, minus, and plus, respectively.  The tables include
;	10**{1,2,4,8,16,32,64,128,256,512,1024,2048,4096}.  No rounding
;	is required until the power is greater than 27, however, all
;	tables include the first 5 for ease of indexing.
;
	;xref	PTENRN
	;xref	PTENRM
	;xref	PTENRP

RTABLE:	dc.b	0,0,0,0
	dc.b	2,3,2,3
	dc.b	2,3,3,2
	dc.b	3,2,2,3

	;|.global	decbin
	;|.global	calc_e
	;|.global	pwrten
	;|.global	calc_m
	;|.global	norm
	;|.global	ap_st_z
	;|.global	ap_st_n
;
FNIBS = 7
FSTRT = 0
;
ESTRT = 4
EDIGITS = 2	; 
;
; Constants in single precision
;FZERO: 	dc.l	$00000000
TEN = 10

;
decbin:
	; fmovel	#0,FPCR		;clr real fpcr
	movem.l	d2-d5,-(a7)
;
; Calculate exponent:
;  1. Copy bcd value in memory for use as a working copy.
;  2. Calculate absolute value of exponent in d1 by mul and add.
;  3. Correct for exponent sign.
;  4. Subtract 16 to compensate for interpreting the mant as all integer digits.
;     (i.e., all digits assumed left of the decimal point.)
;
; Register usage:
;
;  calc_e:
;	(*)  d0: temp digit storage
;	(*)  d1: accumulator for binary exponent
;	(*)  d2: digit count
;	(*)  d3: offset pointer
;	( )  d4: first word of bcd
;	( )  a0: pointer to working bcd value
;	( )  a6: pointer to original bcd value
;	(*)  FP_SCR1: working copy of original bcd value
;	(*)  L_SCR1: copy of original exponent word
;
calc_e:
	move.l	#EDIGITS,d2	;# of nibbles (digits) in fraction part
	moveq.l	#ESTRT,d3	;counter to pick up digits
	lea.l	FP_SCR1(a6),a0	;load tmp bcd storage address
	move.l	ETEMP(a6),(a0)	;save input bcd value
	move.l	ETEMP_HI(a6),4(a0) ;save words 2 and 3
	move.l	ETEMP_LO(a6),8(a0) ;and work with these
	move.l	(a0),d4	;get first word of bcd
	clr.l	d1		;zero d1 for accumulator
e_gd:
	mulu.l	#TEN,d1	;mul partial product by one digit place
	bfextu	d4{d3:4},d0	;get the digit and zero extend into d0
	add.l	d0,d1		;d1 = d1 + d0
	addq.b	#4,d3		;advance d3 to the next digit
	dbf	d2,e_gd	;if we have used all 3 digits, exit loop
	btst	#30,d4		;get SE
	beq.s	e_pos		;don't negate if pos
	neg.l	d1		;negate before subtracting
e_pos:
	sub.l	#16,d1		;sub to compensate for shift of mant
	bge.s	e_save		;if still pos, do not neg
	neg.l	d1		;now negative, make pos and set SE
	or.l	#$40000000,d4	;set SE in d4,
	or.l	#$40000000,(a0)	;and in working bcd
e_save:
	move.l	d1,L_SCR1(a6)	;save exp in memory
;
;
; Calculate mantissa:
;  1. Calculate absolute value of mantissa in fp0 by mul and add.
;  2. Correct for mantissa sign.
;     (i.e., all digits assumed left of the decimal point.)
;
; Register usage:
;
;  calc_m:
;	(*)  d0: temp digit storage
;	(*)  d1: lword counter
;	(*)  d2: digit count
;	(*)  d3: offset pointer
;	( )  d4: words 2 and 3 of bcd
;	( )  a0: pointer to working bcd value
;	( )  a6: pointer to original bcd value
;	(*) fp0: mantissa accumulator
;	( )  FP_SCR1: working copy of original bcd value
;	( )  L_SCR1: copy of original exponent word
;
calc_m:
	moveq.l	#1,d1		;word counter, init to 1
	fmove.s	FZERO(pc),fp0	;accumulator
;
;
;  Since the packed number has a long word between the first & second parts,
;  get the integer digit then skip down & get the rest of the
;  mantissa.  We will unroll the loop once.
;
	bfextu	(a0){28:4},d0	;integer part is ls digit in long word
	fadd.b	d0,fp0		;add digit to sum in fp0
;
;
;  Get the rest of the mantissa.
;
loadlw:
	move.l	(a0,d1.L*4),d4	;load mantissa longword into d4
	moveq.l	#FSTRT,d3	;counter to pick up digits
	moveq.l	#FNIBS,d2	;reset number of digits per a0 ptr
md2b:
	fmul.s	FTEN(pc),fp0	;fp0 = fp0 * 10
	bfextu	d4{d3:4},d0	;get the digit and zero extend
	fadd.b	d0,fp0	;fp0 = fp0 + digit
;
;
;  If all the digits (8) in that long word have been converted (d2=0),
;  then inc d1 (=2) to point to the next long word and reset d3 to 0
;  to initialize the digit offset, and set d2 to 7 for the digit count;
;  else continue with this long word.
;
	addq.b	#4,d3		;advance d3 to the next digit
	dbf	d2,md2b		;check for last digit in this lw
nextlw:
	addq.l	#1,d1		;inc lw pointer in mantissa
	cmp.l	#2,d1		;test for last lw
	ble	loadlw		;if not, get last one
	
;
;  Check the sign of the mant and make the value in fp0 the same sign.
;
m_sign:
	btst	#31,(a0)	;test sign of the mantissa
	beq.s	ap_st_z		;if clear, go to append/strip zeros
	fneg.x	fp0		;if set, negate fp0
	
;
; Append/strip zeros:
;
;  For adjusted exponents which have an absolute value greater than 27*,
;  this routine calculates the amount needed to normalize the mantissa
;  for the adjusted exponent.  That number is subtracted from the exp
;  if the exp was positive, and added if it was negative.  The purpose
;  of this is to reduce the value of the exponent and the possibility
;  of error in calculation of pwrten.
;
;  1. Branch on the sign of the adjusted exponent.
;  2p.(positive exp)
;   2. Check M16 and the digits in lwords 2 and 3 in descending order.
;   3. Add one for each zero encountered until a non-zero digit.
;   4. Subtract the count from the exp.
;   5. Check if the exp has crossed zero in #3 above; make the exp abs
;	   and set SE.
;	6. Multiply the mantissa by 10**count.
;  2n.(negative exp)
;   2. Check the digits in lwords 3 and 2 in descending order.
;   3. Add one for each zero encountered until a non-zero digit.
;   4. Add the count to the exp.
;   5. Check if the exp has crossed zero in #3 above; clear SE.
;   6. Divide the mantissa by 10**count.
;
;  *Why 27?  If the adjusted exponent is within -28 < expA < 28, than
;   any adjustment due to append/strip zeros will drive the resultant
;   exponent towards zero.  Since all pwrten constants with a power
;   of 27 or less are exact, there is no need to use this routine to
;   attempt to lessen the resultant exponent.
;
; Register usage:
;
;  ap_st_z:
;	(*)  d0: temp digit storage
;	(*)  d1: zero count
;	(*)  d2: digit count
;	(*)  d3: offset pointer
;	( )  d4: first word of bcd
;	(*)  d5: lword counter
;	( )  a0: pointer to working bcd value
;	( )  FP_SCR1: working copy of original bcd value
;	( )  L_SCR1: copy of original exponent word
;
;
; First check the absolute value of the exponent to see if this
; routine is necessary.  If so, then check the sign of the exponent
; and do append (+) or strip (-) zeros accordingly.
; This section handles a positive adjusted exponent.
;
ap_st_z:
	move.l	L_SCR1(a6),d1	;load expA for range test
	cmp.l	#27,d1		;test is with 27
	ble	pwrten		;if abs(expA) <28, skip ap/st zeros
	btst	#30,(a0)	;check sign of exp
	bne.s	ap_st_n		;if neg, go to neg side
	clr.l	d1		;zero count reg
	move.l	(a0),d4		;load lword 1 to d4
	bfextu	d4{28:4},d0	;get M16 in d0
	bne.s	ap_p_fx		;if M16 is non-zero, go fix exp
	addq.l	#1,d1		;inc zero count
	moveq.l	#1,d5		;init lword counter
	move.l	(a0,d5.L*4),d4	;get lword 2 to d4
	bne.s	ap_p_cl		;if lw 2 is zero, skip it
	addq.l	#8,d1		;and inc count by 8
	addq.l	#1,d5		;inc lword counter
	move.l	(a0,d5.L*4),d4	;get lword 3 to d4
ap_p_cl:
	clr.l	d3		;init offset reg
	moveq.l	#7,d2		;init digit counter
ap_p_gd:
	bfextu	d4{d3:4},d0	;get digit
	bne.s	ap_p_fx		;if non-zero, go to fix exp
	addq.l	#4,d3		;point to next digit
	addq.l	#1,d1		;inc digit counter
	dbf	d2,ap_p_gd	;get next digit
ap_p_fx:
	move.l	d1,d0		;copy counter to d2
	move.l	L_SCR1(a6),d1	;get adjusted exp from memory
	sub.l	d0,d1		;subtract count from exp
	bge.s	ap_p_fm		;if still pos, go to pwrten
	neg.l	d1		;now its neg; get abs
	move.l	(a0),d4		;load lword 1 to d4
	or.l	#$40000000,d4	; and set SE in d4
	or.l	#$40000000,(a0)	; and in memory
;
; Calculate the mantissa multiplier to compensate for the striping of
; zeros from the mantissa.
;
ap_p_fm:
	move.l	#PTENRN,a1	;get address of power-of-ten table
	clr.l	d3		;init table index
	fmove.s	FONE(pc),fp1	;init fp1 to 1
	moveq.l	#3,d2		;init d2 to count bits in counter
ap_p_el:
	asr.l	#1,d0		;shift lsb into carry
	bcc.s	ap_p_en		;if 1, mul fp1 by pwrten factor
	fmul.x	(a1,d3),fp1	;mul by 10**(d3_bit_no)
ap_p_en:
	add.l	#12,d3		;inc d3 to next rtable entry
	tst.l	d0		;check if d0 is zero
	bne.s	ap_p_el		;if not, get next bit
	fmul.x	fp1,fp0		;mul mantissa by 10**(no_bits_shifted)
	bra.s	pwrten		;go calc pwrten
;
; This section handles a negative adjusted exponent.
;
ap_st_n:
	clr.l	d1		;clr counter
	moveq.l	#2,d5		;set up d5 to point to lword 3
	move.l	(a0,d5.L*4),d4	;get lword 3
	bne.s	ap_n_cl		;if not zero, check digits
	sub.l	#1,d5		;dec d5 to point to lword 2
	addq.l	#8,d1		;inc counter by 8
	move.l	(a0,d5.L*4),d4	;get lword 2
ap_n_cl:
	move.l	#28,d3		;point to last digit
	moveq.l	#7,d2		;init digit counter
ap_n_gd:
	bfextu	d4{d3:4},d0	;get digit
	bne.s	ap_n_fx		;if non-zero, go to exp fix
	subq.l	#4,d3		;point to previous digit
	addq.l	#1,d1		;inc digit counter
	dbf	d2,ap_n_gd	;get next digit
ap_n_fx:
	move.l	d1,d0		;copy counter to d0
	move.l	L_SCR1(a6),d1	;get adjusted exp from memory
	sub.l	d0,d1		;subtract count from exp
	bgt.s	ap_n_fm		;if still pos, go fix mantissa
	neg.l	d1		;take abs of exp and clr SE
	move.l	(a0),d4		;load lword 1 to d4
	and.l	#$bfffffff,d4	; and clr SE in d4
	and.l	#$bfffffff,(a0)	; and in memory
;
; Calculate the mantissa multiplier to compensate for the appending of
; zeros to the mantissa.
;
ap_n_fm:
	move.l	#PTENRN,a1	;get address of power-of-ten table
	clr.l	d3		;init table index
	fmove.s	FONE(pc),fp1	;init fp1 to 1
	moveq.l	#3,d2		;init d2 to count bits in counter
ap_n_el:
	asr.l	#1,d0		;shift lsb into carry
	bcc.s	ap_n_en		;if 1, mul fp1 by pwrten factor
	fmul.x	(a1,d3),fp1	;mul by 10**(d3_bit_no)
ap_n_en:
	add.l	#12,d3		;inc d3 to next rtable entry
	tst.l	d0		;check if d0 is zero
	bne.s	ap_n_el		;if not, get next bit
	fdiv.x	fp1,fp0		;div mantissa by 10**(no_bits_shifted)
;
;
; Calculate power-of-ten factor from adjusted and shifted exponent.
;
; Register usage:
;
;  pwrten:
;	(*)  d0: temp
;	( )  d1: exponent
;	(*)  d2: {FPCR[6:5],SM,SE} as index in RTABLE; temp
;	(*)  d3: FPCR work copy
;	( )  d4: first word of bcd
;	(*)  a1: RTABLE pointer
;  calc_p:
;	(*)  d0: temp
;	( )  d1: exponent
;	(*)  d3: PWRTxx table index
;	( )  a0: pointer to working copy of bcd
;	(*)  a1: PWRTxx pointer
;	(*) fp1: power-of-ten accumulator
;
; Pwrten calculates the exponent factor in the selected rounding mode
; according to the following table:
;	
;	Sign of Mant  Sign of Exp  Rounding Mode  PWRTEN Rounding Mode
;
;	ANY	  ANY	RN	RN
;
;	 +	   +	RP	RP
;	 -	   +	RP	RM
;	 +	   -	RP	RM
;	 -	   -	RP	RP
;
;	 +	   +	RM	RM
;	 -	   +	RM	RP
;	 +	   -	RM	RP
;	 -	   -	RM	RM
;
;	 +	   +	RZ	RM
;	 -	   +	RZ	RM
;	 +	   -	RZ	RP
;	 -	   -	RZ	RP
;
;
pwrten:
	move.l	USER_FPCR(a6),d3 ;get user's FPCR
	bfextu	d3{26:2},d2	;isolate rounding mode bits
	move.l	(a0),d4		;reload 1st bcd word to d4
	asl.l	#2,d2		;format d2 to be
	bfextu	d4{0:2},d0	; {FPCR[6],FPCR[5],SM,SE}
	add.l	d0,d2		;in d2 as index into RTABLE
	lea.l	RTABLE(pc),a1	;load rtable base
	move.b	(a1,d2),d0	;load new rounding bits from table
	clr.l	d3			;clear d3 to force no exc and extended
	bfins	d0,d3{26:2}	;stuff new rounding bits in FPCR
	fmove.l	d3,FPCR		;write new FPCR
	asr.l	#1,d0		;write correct PTENxx table
	bcc.s	not_rp		;to a1
	lea.l	PTENRP(pc),a1	;it is RP
	bra.s	calc_p		;go to init section
not_rp:
	asr.l	#1,d0		;keep checking
	bcc.s	not_rm
	lea.l	PTENRM(pc),a1	;it is RM
	bra.s	calc_p		;go to init section
not_rm:
	lea.l	PTENRN(pc),a1	;it is RN
calc_p:
	move.l	d1,d0		;copy exp to d0;use d0
	bpl.s	no_neg		;if exp is negative,
	neg.l	d0		;invert it
	or.l	#$40000000,(a0)	;and set SE bit
no_neg:
	clr.l	d3		;table index
	fmove.s	FONE(pc),fp1	;init fp1 to 1
e_loop:
	asr.l	#1,d0		;shift next bit into carry
	bcc.s	e_next		;if zero, skip the mul
	fmul.x	(a1,d3),fp1	;mul by 10**(d3_bit_no)
e_next:
	add.l	#12,d3		;inc d3 to next rtable entry
	tst.l	d0		;check if d0 is zero
	bne.s	e_loop		;not zero, continue shifting
;
;
;  Check the sign of the adjusted exp and make the value in fp0 the
;  same sign. If the exp was pos then multiply fp1*fp0;
;  else divide fp0/fp1.
;
; Register Usage:
;  norm:
;	( )  a0: pointer to working bcd value
;	(*) fp0: mantissa accumulator
;	( ) fp1: scaling factor - 10**(abs(exp))
;
norm:
	btst	#30,(a0)	;test the sign of the exponent
	beq.s	mul		;if clear, go to multiply
div:
	fdiv.x	fp1,fp0		;exp is negative, so divide mant by exp
	bra.s	end_dec
mul:
	fmul.x	fp1,fp0		;exp is positive, so multiply by exp
;
;
; Clean up and return with result in fp0.
;
; If the final mul/div in decbin incurred an inex exception,
; it will be inex2, but will be reported as inex1 by get_op.
;
end_dec:
	fmove.l	FPSR,d0		;get status register	
	bclr.l	#inex2_bit+8,d0	;test for inex2 and clear it
	fmove.l	d0,FPSR		;return status reg w/o inex2
	beq.s	.no_exc		;skip this if no exc
	or.l	#inx1a_mask,USER_FPSR(a6) ;set inex1/ainex
.no_exc:
	movem.l	(a7)+,d2-d5
	rts
	;end
;
;	do_func.sa 3.4 2/18/91
;
; Do_func performs the unimplemented operation.  The operation
; to be performed is determined from the lower 7 bits of the
; extension word (except in the case of fmovecr and fsincos).
; The opcode and tag bits form an index into a jump table in 
; tbldo.sa.  Cases of zero, infinity and NaN are handled in 
; do_func by forcing the default result.  Normalized and
; denormalized (there are no unnormalized numbers at this
; point) are passed onto the emulation code.  
;
; CMDREG1B and STAG are extracted from the fsave frame
; and combined to form the table index.  The function called
; will start with a0 pointing to the ETEMP operand.  Dyadic
; functions can find FPTEMP at -12(a0).
;
; Called functions return their result in fp0.  Sincos returns
; sin(x) in fp0 and cos(x) in fp1.
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

DO_FUNC:	;idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	

	;xref	t_dz2
	;xref	t_operr
	;xref	t_inx2
	;xref 	t_resdnrm
	;xref	dst_nan
	;xref	src_nan
	;xref	nrm_set
	;xref	sto_cos

	;xref	tblpre
	;xref	slognp1,slogn,slog10,slog2
	;xref	slognd,slog10d,slog2d
	;xref	smod,srem
	;xref	sscale
	;xref	smovcr

PONE:	dc.l	$3fff0000,$80000000,$00000000	;+1
MONE:	dc.l	$bfff0000,$80000000,$00000000	;-1
PZERO:	dc.l	$00000000,$00000000,$00000000	;+0
MZERO:	dc.l	$80000000,$00000000,$00000000	;-0
PINF:	dc.l	$7fff0000,$00000000,$00000000	;+inf
MINF:	dc.l	$ffff0000,$00000000,$00000000	;-inf
QNAN:	dc.l	$7fff0000,$ffffffff,$ffffffff	;non-signaling nan
;PPIBY2:  dc.l	$3FFF0000,$C90FDAA2,$2168C235	;+PI/2
MPIBY2:  dc.l	$bFFF0000,$C90FDAA2,$2168C235	;-PI/2

	;|.global	do_func
do_func:
	clr.b	CU_ONLY(a6)
;
; Check for fmovecr.  It does not follow the format of fp gen
; unimplemented instructions.  The test is on the upper 6 bits;
; if they are $17, the inst is fmovecr.  Call entry smovcr
; directly.
;
	bfextu	CMDREG1B(a6){0:6},d0 ;get opclass and src fields
	cmpi.l	#$17,d0		;if op class and size fields are $17, 
;				;it is FMOVECR; if not, continue
	bne.s	.not_fmovecr
	bra	smovcr		;fmovecr; jmp directly to emulation

.not_fmovecr:
	move.w	CMDREG1B(a6),d0
	and.l	#$7F,d0
	cmpi.l	#$38,d0		;if the extension is >= $38, 
	bge.s	serror		;it is illegal
	bfextu	STAG(a6){0:3},d1
	lsl.l	#3,d0		;make room for STAG
	add.l	d1,d0		;combine for final index into table
	lea.l	tblpre(pc),a1	;start of monster jump table
	move.l	(a1,d0.w*4),a1	;real target address
	lea.l	ETEMP(a6),a0	;a0 is pointer to src op
	move.l	USER_FPCR(a6),d1
	and.l	#$FF,d1		; discard all but rounding mode/prec
	fmove.l	#0,fpcr
	jmp	(a1)
;
;	ERROR
;
	;|.global	serror
serror:
	st	STORE_FLG(a6)
	rts
;
; These routines load forced values into fp0.  They are called
; by index into tbldo.
;
; Load a signed zero to fp0 and set inex2/ainex
;
	;|.global	snzrinx
snzrinx:
	btst.b	#sign_bit,LOCAL_EX(a0)	;get sign of source operand
	bne.s	ld_mzinx	;if negative, branch
	bsr	ld_pzero	;bsr so we can return and set inx
	bra	t_inx2		;now, set the inx for the next inst
ld_mzinx:
	bsr	ld_mzero	;if neg, load neg zero, return here
	bra	t_inx2		;now, set the inx for the next inst
;
; Load a signed zero to fp0; do not set inex2/ainex 
;
	;|.global	szero
szero:
	btst.b	#sign_bit,LOCAL_EX(a0) ;get sign of source operand
	bne	ld_mzero	;if neg, load neg zero
	bra	ld_pzero	;load positive zero
;
; Load a signed infinity to fp0; do not set inex2/ainex 
;
	;|.global	sinf
sinf:
	btst.b	#sign_bit,LOCAL_EX(a0)	;get sign of source operand
	bne	ld_minf			;if negative branch
	bra	ld_pinf
;
; Load a signed one to fp0; do not set inex2/ainex 
;
	;|.global	sone
sone:
	btst.b	#sign_bit,LOCAL_EX(a0)	;check sign of source
	bne	ld_mone
	bra	ld_pone
;
; Load a signed pi/2 to fp0; do not set inex2/ainex 
;
	;|.global	spi_2
spi_2:
	btst.b	#sign_bit,LOCAL_EX(a0)	;check sign of source
	bne	ld_mpi2
	bra	ld_ppi2
;
; Load either a +0 or +inf for plus/minus operand
;
	;|.global	szr_inf
szr_inf:
	btst.b	#sign_bit,LOCAL_EX(a0)	;check sign of source
	bne	ld_pzero
	bra	ld_pinf
;
; Result is either an operr or +inf for plus/minus operand
; [Used by slogn, slognp1, slog10, and slog2]
;
	;|.global	sopr_inf
sopr_inf:
	btst.b	#sign_bit,LOCAL_EX(a0)	;check sign of source
	bne	t_operr
	bra	ld_pinf
;
;	FLOGNP1 
;
	;|.global	sslognp1
sslognp1:
	fmovem.x (a0),fp0-fp0
	fcmp.b	#-1,fp0
	fbgt	slognp1		
	fbeq	t_dz2		;if = -1, divide by zero exception
	fmove.l	#0,FPSR		;clr N flag
	bra	t_operr		;take care of operands < -1
;
;	FETOXM1
;
	;|.global	setoxm1i
setoxm1i:
	btst.b	#sign_bit,LOCAL_EX(a0)	;check sign of source
	bne	ld_mone
	bra	ld_pinf
;
;	FLOGN
;
; Test for 1.0 as an input argument, returning +zero.  Also check
; the sign and return operr if negative.
;
	;|.global	sslogn
sslogn:
	btst.b	#sign_bit,LOCAL_EX(a0) 
	bne	t_operr		;take care of operands < 0
	cmpi.w	#$3fff,LOCAL_EX(a0) ;test for 1.0 input
	bne	slogn
	cmpi.l	#$80000000,LOCAL_HI(a0)
	bne	slogn
	tst.l	LOCAL_LO(a0)
	bne	slogn
	fmove.x	PZERO(pc),fp0
	rts

	;|.global	sslognd
sslognd:
	btst.b	#sign_bit,LOCAL_EX(a0) 
	beq	slognd
	bra	t_operr		;take care of operands < 0

;
;	FLOG10
;
	;|.global	sslog10
sslog10:
	btst.b	#sign_bit,LOCAL_EX(a0)
	bne	t_operr		;take care of operands < 0
	cmpi.w	#$3fff,LOCAL_EX(a0) ;test for 1.0 input
	bne	slog10
	cmpi.l	#$80000000,LOCAL_HI(a0)
	bne	slog10
	tst.l	LOCAL_LO(a0)
	bne	slog10
	fmove.x	PZERO(pc),fp0
	rts

	;|.global	sslog10d
sslog10d:
	btst.b	#sign_bit,LOCAL_EX(a0) 
	beq	slog10d
	bra	t_operr		;take care of operands < 0

;
;	FLOG2
;
	;|.global	sslog2
sslog2:
	btst.b	#sign_bit,LOCAL_EX(a0)
	bne	t_operr		;take care of operands < 0
	cmpi.w	#$3fff,LOCAL_EX(a0) ;test for 1.0 input
	bne	slog2
	cmpi.l	#$80000000,LOCAL_HI(a0)
	bne	slog2
	tst.l	LOCAL_LO(a0)
	bne	slog2
	fmove.x	PZERO(pc),fp0
	rts

	;|.global	sslog2d
sslog2d:
	btst.b	#sign_bit,LOCAL_EX(a0) 
	beq	slog2d
	bra	t_operr		;take care of operands < 0

;
;	FMOD
;
pmodt:
;				;$21 fmod
;				;dtag,stag
	dc.l	smod		;  00,00  norm,norm = normal
	dc.l	smod_oper	;  00,01  norm,zero = nan with operr
	dc.l	smod_fpn	;  00,10  norm,inf  = fpn
	dc.l	smod_snan	;  00,11  norm,nan  = nan
	dc.l	smod_zro	;  01,00  zero,norm = +-zero
	dc.l	smod_oper	;  01,01  zero,zero = nan with operr
	dc.l	smod_zro	;  01,10  zero,inf  = +-zero
	dc.l	smod_snan	;  01,11  zero,nan  = nan
	dc.l	smod_oper	;  10,00  inf,norm  = nan with operr
	dc.l	smod_oper	;  10,01  inf,zero  = nan with operr
	dc.l	smod_oper	;  10,10  inf,inf   = nan with operr
	dc.l	smod_snan	;  10,11  inf,nan   = nan
	dc.l	smod_dnan	;  11,00  nan,norm  = nan
	dc.l	smod_dnan	;  11,01  nan,zero  = nan
	dc.l	smod_dnan	;  11,10  nan,inf   = nan
	dc.l	smod_dnan	;  11,11  nan,nan   = nan

	;|.global	pmod
pmod:
	clr.b	FPSR_QBYTE(a6) ; clear quotient field
	bfextu	STAG(a6){0:3},d0 ;stag = d0
	bfextu	DTAG(a6){0:3},d1 ;dtag = d1

;
; Alias extended denorms to norms for the jump table.
;
	bclr.l	#2,d0
	bclr.l	#2,d1

	lsl.b	#2,d1
	or.b	d0,d1		;d1{3:2} = dtag, d1{1:0} = stag
;				;Tag values:
;				;00 = norm or denorm
;				;01 = zero
;				;10 = inf
;				;11 = nan
	lea	pmodt(pc),a1
	move.l	(a1,d1.w*4),a1
	jmp	(a1)

smod_snan:
	bra	src_nan
smod_dnan:
	bra	dst_nan
smod_oper:
	bra	t_operr
smod_zro:
	move.b	ETEMP(a6),d1	;get sign of src op
	move.b	FPTEMP(a6),d0	;get sign of dst op
	eor.b	d0,d1		;get exor of sign bits
	btst.l	#7,d1		;test for sign
	beq.s	smod_zsn	;if clr, do not set sign big
	bset.b	#q_sn_bit,FPSR_QBYTE(a6) ;set q-byte sign bit
smod_zsn:
	btst.l	#7,d0		;test if + or -
	beq	ld_pzero	;if pos then load +0
	bra	ld_mzero	;else neg load -0
	
smod_fpn:
	move.b	ETEMP(a6),d1	;get sign of src op
	move.b	FPTEMP(a6),d0	;get sign of dst op
	eor.b	d0,d1		;get exor of sign bits
	btst.l	#7,d1		;test for sign
	beq.s	smod_fsn	;if clr, do not set sign big
	bset.b	#q_sn_bit,FPSR_QBYTE(a6) ;set q-byte sign bit
smod_fsn:
	tst.b	DTAG(a6)	;filter out denormal destination case
	bpl.s	smod_nrm	;
	lea.l	FPTEMP(a6),a0	;a0<- addr(FPTEMP)
	bra	t_resdnrm	;force UNFL(but exact) result
smod_nrm:
	fmove.l USER_FPCR(a6),fpcr ;use user's rmode and precision
	fmove.x FPTEMP(a6),fp0	;return dest to fp0
	rts
		
;
;	FREM
;
premt:
;				;$25 frem
;				;dtag,stag
	dc.l	srem		;  00,00  norm,norm = normal
	dc.l	srem_oper	;  00,01  norm,zero = nan with operr
	dc.l	srem_fpn	;  00,10  norm,inf  = fpn
	dc.l	srem_snan	;  00,11  norm,nan  = nan
	dc.l	srem_zro	;  01,00  zero,norm = +-zero
	dc.l	srem_oper	;  01,01  zero,zero = nan with operr
	dc.l	srem_zro	;  01,10  zero,inf  = +-zero
	dc.l	srem_snan	;  01,11  zero,nan  = nan
	dc.l	srem_oper	;  10,00  inf,norm  = nan with operr
	dc.l	srem_oper	;  10,01  inf,zero  = nan with operr
	dc.l	srem_oper	;  10,10  inf,inf   = nan with operr
	dc.l	srem_snan	;  10,11  inf,nan   = nan
	dc.l	srem_dnan	;  11,00  nan,norm  = nan
	dc.l	srem_dnan	;  11,01  nan,zero  = nan
	dc.l	srem_dnan	;  11,10  nan,inf   = nan
	dc.l	srem_dnan	;  11,11  nan,nan   = nan

	;|.global	prem
prem:
	clr.b	FPSR_QBYTE(a6)   ;clear quotient field
	bfextu	STAG(a6){0:3},d0 ;stag = d0
	bfextu	DTAG(a6){0:3},d1 ;dtag = d1
;
; Alias extended denorms to norms for the jump table.
;
	bclr	#2,d0
	bclr	#2,d1

	lsl.b	#2,d1
	or.b	d0,d1		;d1{3:2} = dtag, d1{1:0} = stag
;				;Tag values:
;				;00 = norm or denorm
;				;01 = zero
;				;10 = inf
;				;11 = nan
	lea	premt(pc),a1
	move.l	(a1,d1.w*4),a1
	jmp	(a1)
	
srem_snan:
	bra	src_nan
srem_dnan:
	bra	dst_nan
srem_oper:
	bra	t_operr
srem_zro:
	move.b	ETEMP(a6),d1	;get sign of src op
	move.b	FPTEMP(a6),d0	;get sign of dst op
	eor.b	d0,d1		;get exor of sign bits
	btst.l	#7,d1		;test for sign
	beq.s	srem_zsn	;if clr, do not set sign big
	bset.b	#q_sn_bit,FPSR_QBYTE(a6) ;set q-byte sign bit
srem_zsn:
	btst.l	#7,d0		;test if + or -
	beq	ld_pzero	;if pos then load +0
	bra	ld_mzero	;else neg load -0
	
srem_fpn:
	move.b	ETEMP(a6),d1	;get sign of src op
	move.b	FPTEMP(a6),d0	;get sign of dst op
	eor.b	d0,d1		;get exor of sign bits
	btst.l	#7,d1		;test for sign
	beq.s	srem_fsn	;if clr, do not set sign big
	bset.b	#q_sn_bit,FPSR_QBYTE(a6) ;set q-byte sign bit
srem_fsn:
	tst.b	DTAG(a6)	;filter out denormal destination case
	bpl.s	srem_nrm	;
	lea.l	FPTEMP(a6),a0	;a0<- addr(FPTEMP)
	bra	t_resdnrm	;force UNFL(but exact) result
srem_nrm:
	fmove.l USER_FPCR(a6),fpcr ;use user's rmode and precision
	fmove.x FPTEMP(a6),fp0	;return dest to fp0
	rts
;
;	FSCALE
;
pscalet:
;				;$26 fscale
;				;dtag,stag
	dc.l	sscale		;  00,00  norm,norm = result
	dc.l	sscale		;  00,01  norm,zero = fpn
	dc.l	scl_opr		;  00,10  norm,inf  = nan with operr
	dc.l	scl_snan	;  00,11  norm,nan  = nan
	dc.l	scl_zro		;  01,00  zero,norm = +-zero
	dc.l	scl_zro		;  01,01  zero,zero = +-zero
	dc.l	scl_opr		;  01,10  zero,inf  = nan with operr
	dc.l	scl_snan	;  01,11  zero,nan  = nan
	dc.l	scl_inf		;  10,00  inf,norm  = +-inf
	dc.l	scl_inf		;  10,01  inf,zero  = +-inf
	dc.l	scl_opr		;  10,10  inf,inf   = nan with operr
 	dc.l	scl_snan	;  10,11  inf,nan   = nan
 	dc.l	scl_dnan	;  11,00  nan,norm  = nan
 	dc.l	scl_dnan	;  11,01  nan,zero  = nan
 	dc.l	scl_dnan	;  11,10  nan,inf   = nan
	dc.l	scl_dnan	;  11,11  nan,nan   = nan

	;|.global	pscale
pscale:
	bfextu	STAG(a6){0:3},d0 ;stag in d0
	bfextu	DTAG(a6){0:3},d1 ;dtag in d1
	bclr.l	#2,d0		;alias  denorm into norm
	bclr.l	#2,d1		;alias  denorm into norm
	lsl.b	#2,d1
	or.b	d0,d1		;d1{4:2} = dtag, d1{1:0} = stag
;				;dtag values     stag values:
;				;000 = norm      00 = norm
;				;001 = zero	 01 = zero
;				;010 = inf	 10 = inf
;				;011 = nan	 11 = nan
;				;100 = dnrm
;
;
	lea.l	pscalet(pc),a1	;load start of jump table
	move.l	(a1,d1.w*4),a1	;load a1 with label depending on tag
	jmp	(a1)		;go to the routine

scl_opr:
	bra	t_operr

scl_dnan:
	bra	dst_nan

scl_zro:
	btst.b	#sign_bit,FPTEMP_EX(a6)	;test if + or -
	beq	ld_pzero		;if pos then load +0
	bra	ld_mzero		;if neg then load -0
scl_inf:
	btst.b	#sign_bit,FPTEMP_EX(a6)	;test if + or -
	beq	ld_pinf			;if pos then load +inf
	bra	ld_minf			;else neg load -inf
scl_snan:
	bra	src_nan
;
;	FSINCOS
;
	;|.global	ssincosz
ssincosz:
	btst.b	#sign_bit,ETEMP(a6)	;get sign
	beq.s	sincosp
	fmove.x	MZERO(pc),fp0
	bra.s	sincoscom
sincosp:
	fmove.x PZERO(pc),fp0
sincoscom:
  	fmovem.x PONE(pc),fp1-fp1	;do not allow FPSR to be affected
	bra	sto_cos		;store cosine result

	;|.global	ssincosi
ssincosi:
	fmove.x QNAN(pc),fp1	;load NAN
	bsr	sto_cos		;store cosine result
	fmove.x QNAN(pc),fp0	;load NAN
	bra	t_operr

	;|.global	ssincosnan
ssincosnan:
	move.l	ETEMP_EX(a6),FP_SCR1(a6)
	move.l	ETEMP_HI(a6),FP_SCR1+4(a6)
	move.l	ETEMP_LO(a6),FP_SCR1+8(a6)
	bset.b	#signan_bit,FP_SCR1+4(a6)
	fmovem.x FP_SCR1(a6),fp1-fp1
	bsr	sto_cos
	bra	src_nan
;
; This code forces default values for the zero, inf, and nan cases 
; in the transcendentals code.  The CC bits must be set in the
; stacked FPSR to be correctly reported.
;
;**Returns +PI/2
	;|.global	ld_ppi2
ld_ppi2:
	fmove.x PPIBY2(pc),fp0		;load +pi/2
	bra	t_inx2			;set inex2 exc

;**Returns -PI/2
	;|.global	ld_mpi2
ld_mpi2:
	fmove.x MPIBY2(pc),fp0		;load -pi/2
	or.l	#neg_mask,USER_FPSR(a6)	;set N bit
	bra	t_inx2			;set inex2 exc

;**Returns +inf
	;|.global	ld_pinf
ld_pinf:
	fmove.x PINF(pc),fp0		;load +inf
	or.l	#inf_mask,USER_FPSR(a6)	;set I bit
	rts

;**Returns -inf
	;|.global	ld_minf
ld_minf:
	fmove.x MINF(pc),fp0		;load -inf
	or.l	#neg_mask+inf_mask,USER_FPSR(a6)	;set N and I bits
	rts

;**Returns +1
	;|.global	ld_pone
ld_pone:
	fmove.x PONE(pc),fp0		;load +1
	rts

;**Returns -1
	;|.global	ld_mone
ld_mone:
	fmove.x MONE(pc),fp0		;load -1
	or.l	#neg_mask,USER_FPSR(a6)	;set N bit
	rts

;**Returns +0
	;|.global	ld_pzero
ld_pzero:
	fmove.x PZERO(pc),fp0		;load +0
	or.l	#z_mask,USER_FPSR(a6)	;set Z bit
	rts

;**Returns -0
	;|.global	ld_mzero
ld_mzero:
	fmove.x MZERO(pc),fp0		;load -0
	or.l	#neg_mask+z_mask,USER_FPSR(a6)	;set N and Z bits
	rts

	;end
;
;	gen_except.sa 3.7 1/16/92
;
;	gen_except --- FPSP routine to detect reportable exceptions
;	
;	This routine compares the exception enable byte of the
;	user_fpcr on the stack with the exception status byte
;	of the user_fpsr. 
;
;	Any routine which may report an exceptions must load
;	the stack frame in memory with the exceptional operand(s).
;
;	Priority for exceptions is:
;
;	Highest:	bsun
;			snan
;			operr
;			ovfl
;			unfl
;			dz
;			inex2
;	Lowest:		inex1
;
;	Note: The IEEE standard specifies that inex2 is to be
;	reported if ovfl occurs and the ovfl enable bit is not
;	set but the inex2 enable bit is.  
;
;
;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

GEN_EXCEPT:    ;idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section 8

	

	;xref	real_trace
	;xref	fpsp_done
	;xref	fpsp_fmt_error

exc_tbl:
	dc.l	bsun_exc
	dc.l	commonE1
	dc.l	commonE1
	dc.l	ovfl_unfl
	dc.l	ovfl_unfl
	dc.l	commonE1
	dc.l	commonE3
	dc.l	commonE3
	dc.l	no_match

	;|.global	gen_except
gen_except:
	cmpi.b	#IDLE_SIZE-4,1(a7)	;test for idle frame
	beq	do_check		;go handle idle frame
	cmpi.b	#UNIMP_40_SIZE-4,1(a7)	;test for orig unimp frame
	beq.s	unimp_x			;go handle unimp frame
	cmpi.b	#UNIMP_41_SIZE-4,1(a7)	;test for rev unimp frame
	beq.s	unimp_x			;go handle unimp frame
	cmpi.b	#BUSY_SIZE-4,1(a7)	;if size <> $60, fmt error
	bne.l	fpsp_fmt_error
	lea.l	BUSY_SIZE+LOCAL_SIZE(a7),a1 ;init a1 so fpsp.h
;					;equates will work
; Fix up the new busy frame with entries from the unimp frame
;
	move.l	ETEMP_EX(a6),ETEMP_EX(a1) ;copy etemp from unimp
	move.l	ETEMP_HI(a6),ETEMP_HI(a1) ;frame to busy frame
	move.l	ETEMP_LO(a6),ETEMP_LO(a1) 
	move.l	CMDREG1B(a6),CMDREG1B(a1) ;set inst in frame to unimp
	move.l	CMDREG1B(a6),d0		;fix cmd1b to make it
	and.l	#$03c30000,d0		;work for cmd3b
	bfextu	CMDREG1B(a6){13:1},d1	;extract bit 2
	lsl.l	#5,d1			
	swap	d1
	or.l	d1,d0			;put it in the right place
	bfextu	CMDREG1B(a6){10:3},d1	;extract bit 3,4,5
	lsl.l	#2,d1
	swap	d1
	or.l	d1,d0			;put them in the right place
	move.l	d0,CMDREG3B(a1)		;in the busy frame
;
; Or in the FPSR from the emulation with the USER_FPSR on the stack.
;
	fmove.l	FPSR,d0		
	or.l	d0,USER_FPSR(a6)
	move.l	USER_FPSR(a6),FPSR_SHADOW(a1) ;set exc bits
	or.l	#sx_mask,E_BYTE(a1)
	bra	do_clean

;
; Frame is an unimp frame possible resulting from an fmove <ea>,fp0
; that caused an exception
;
; a1 is modified to point into the new frame allowing fpsp equates
; to be valid.
;
unimp_x:
	cmpi.b	#UNIMP_40_SIZE-4,1(a7)	;test for orig unimp frame
	bne.s	test_rev
	lea.l	UNIMP_40_SIZE+LOCAL_SIZE(a7),a1
	bra.s	unimp_con
test_rev:
	cmpi.b	#UNIMP_41_SIZE-4,1(a7)	;test for rev unimp frame
	bne.l	fpsp_fmt_error		;if not $28 or $30
	lea.l	UNIMP_41_SIZE+LOCAL_SIZE(a7),a1
	
unimp_con:
;
; Fix up the new unimp frame with entries from the old unimp frame
;
	move.l	CMDREG1B(a6),CMDREG1B(a1) ;set inst in frame to unimp
;
; Or in the FPSR from the emulation with the USER_FPSR on the stack.
;
	fmove.l	FPSR,d0		
	or.l	d0,USER_FPSR(a6)
	bra	do_clean

;
; Frame is idle, so check for exceptions reported through
; USER_FPSR and set the unimp frame accordingly.  
; A7 must be incremented to the point before the
; idle fsave vector to the unimp vector.
;
	
do_check:
	add.l	#4,a7			;point A7 back to unimp frame
;
; Or in the FPSR from the emulation with the USER_FPSR on the stack.
;
	fmove.l	FPSR,d0		
	or.l	d0,USER_FPSR(a6)
;
; On a busy frame, we must clear the nmnexc bits.
;
	cmpi.b	#BUSY_SIZE-4,1(a7)	;check frame type
	bne.s	check_fr		;if busy, clr nmnexc
	clr.w	NMNEXC(a6)		;clr nmnexc & nmcexc
	btst.b	#5,CMDREG1B(a6)		;test for fmove out
	bne.s	frame_com
	move.l	USER_FPSR(a6),FPSR_SHADOW(a6) ;set exc bits
	or.l	#sx_mask,E_BYTE(a6)
	bra.s	frame_com
check_fr:
	cmp.b	#UNIMP_40_SIZE-4,1(a7)
	beq.s	frame_com
	clr.w	NMNEXC(a6)
frame_com:
	move.b	FPCR_ENABLE(a6),d0	;get fpcr enable byte
	and.b	FPSR_EXCEPT(a6),d0	;and in the fpsr exc byte
	bfffo	d0{24:8},d1		;test for first set bit
	lea.l	exc_tbl(pc),a0		;load jmp table address
	subi.b	#24,d1			;normalize bit offset to 0-8
	move.l	(a0,d1.w*4),a0		;load routine address based
;					;based on first enabled exc
	jmp	(a0)			;jump to routine
;
; Bsun is not possible in unimp or unsupp
;
bsun_exc:
	bra	do_clean
;
; The typical work to be done to the unimp frame to report an 
; exception is to set the E1/E3 byte and clr the U flag.
; commonE1 does this for E1 exceptions, which are snan, 
; operr, and dz.  commonE3 does this for E3 exceptions, which 
; are inex2 and inex1, and also clears the E1 exception bit
; left over from the unimp exception.
;
commonE1:
	bset.b	#E1,E_BYTE(a6)		;set E1 flag
	bra	commonE			;go clean and exit

commonE3:
	tst.b	UFLG_TMP(a6)		;test flag for unsup/unimp state
	bne.s	unsE3
uniE3:
	bset.b	#E3,E_BYTE(a6)		;set E3 flag
	bclr.b	#E1,E_BYTE(a6)		;clr E1 from unimp
	bra	commonE

unsE3:
	tst.b	RES_FLG(a6)
	bne.s	unsE3_0	
unsE3_1:
	bset.b	#E3,E_BYTE(a6)		;set E3 flag
unsE3_0:
	bclr.b	#E1,E_BYTE(a6)		;clr E1 flag
	move.l	CMDREG1B(a6),d0
	and.l	#$03c30000,d0		;work for cmd3b
	bfextu	CMDREG1B(a6){13:1},d1	;extract bit 2
	lsl.l	#5,d1			
	swap	d1
	or.l	d1,d0			;put it in the right place
	bfextu	CMDREG1B(a6){10:3},d1	;extract bit 3,4,5
	lsl.l	#2,d1
	swap	d1
	or.l	d1,d0			;put them in the right place
	move.l	d0,CMDREG3B(a6)		;in the busy frame

commonE:
	bclr.b	#UFLAG,T_BYTE(a6)	;clr U flag from unimp
	bra	do_clean		;go clean and exit
;
; No bits in the enable byte match existing exceptions.  Check for
; the case of the ovfl exc without the ovfl enabled, but with
; inex2 enabled.
;
no_match:
	btst.b	#inex2_bit,FPCR_ENABLE(a6) ;check for ovfl/inex2 case
	beq.s	no_exc			;if clear, exit
	btst.b	#ovfl_bit,FPSR_EXCEPT(a6) ;now check ovfl
	beq.s	no_exc			;if clear, exit
	bra.s	ovfl_unfl		;go to unfl_ovfl to determine if
;					;it is an unsupp or unimp exc
	
; No exceptions are to be reported.  If the instruction was 
; unimplemented, no FPU restore is necessary.  If it was
; unsupported, we must perform the restore.
no_exc:
	tst.b	UFLG_TMP(a6)	;test flag for unsupp/unimp state
	beq.s	uni_no_exc
uns_no_exc:
	tst.b	RES_FLG(a6)	;check if frestore is needed
	bne	do_clean 	;if clear, no frestore needed
uni_no_exc:
	movem.l	USER_DA(a6),d0-d1/a0-a1
	fmovem.x USER_FP0(a6),fp0-fp3
	fmovem.l USER_FPCR(a6),fpcr/fpsr/fpiar
	unlk	a6
	bra	finish_up
;
; Unsupported Data Type Handler:
; Ovfl:
;   An fmoveout that results in an overflow is reported this way.
; Unfl:
;   An fmoveout that results in an underflow is reported this way.
;
; Unimplemented Instruction Handler:
; Ovfl:
;   Only scosh, setox, ssinh, stwotox, and scale can set overflow in 
;   this manner.
; Unfl:
;   Stwotox, setox, and scale can set underflow in this manner.
;   Any of the other Library Routines such that f(x)=x in which
;   x is an extended denorm can report an underflow exception. 
;   It is the responsibility of the exception-causing exception 
;   to make sure that WBTEMP is correct.
;
;   The exceptional operand is in FP_SCR1.
;
ovfl_unfl:
	tst.b	UFLG_TMP(a6)	;test flag for unsupp/unimp state
	beq.s	ofuf_con
;
; The caller was from an unsupported data type trap.  Test if the
; caller set CU_ONLY.  If so, the exceptional operand is expected in
; FPTEMP, rather than WBTEMP.
;
	tst.b	CU_ONLY(a6)		;test if inst is cu-only
	beq	unsE3
;	move.w	#$fe,CU_SAVEPC(a6)
	clr.b	CU_SAVEPC(a6)
	bset.b	#E1,E_BYTE(a6)		;set E1 exception flag
	move.w	ETEMP_EX(a6),FPTEMP_EX(a6)
	move.l	ETEMP_HI(a6),FPTEMP_HI(a6)
	move.l	ETEMP_LO(a6),FPTEMP_LO(a6)
	bset.b	#fptemp15_bit,DTAG(a6)	;set fpte15
	bclr.b	#UFLAG,T_BYTE(a6)	;clr U flag from unimp
	bra	do_clean		;go clean and exit

ofuf_con:
	move.b	(a7),VER_TMP(a6)	;save version number
	cmpi.b	#BUSY_SIZE-4,1(a7)	;check for busy frame
	beq.s	busy_fr			;if unimp, grow to busy
	cmpi.b	#VER_40,(a7)		;test for orig unimp frame
	bne.s	try_41			;if not, test for rev frame
	moveq.l	#13,d0			;need to zero 14 lwords
	bra.s	ofuf_fin
try_41:
	cmpi.b	#VER_41,(a7)		;test for rev unimp frame
	bne.l	fpsp_fmt_error		;if neither, exit with error
	moveq.l	#11,d0			;need to zero 12 lwords

ofuf_fin:
	clr.l	(a7)
.loop1:
	clr.l	-(a7)			;clear and dec a7
	dbra	d0,.loop1
	move.b	VER_TMP(a6),(a7)
	move.b	#BUSY_SIZE-4,1(a7)		;write busy fmt word.
busy_fr:
	move.l	FP_SCR1(a6),WBTEMP_EX(a6)	;write
	move.l	FP_SCR1+4(a6),WBTEMP_HI(a6)	;exceptional op to
	move.l	FP_SCR1+8(a6),WBTEMP_LO(a6)	;wbtemp
	bset.b	#E3,E_BYTE(a6)			;set E3 flag
	bclr.b	#E1,E_BYTE(a6)			;make sure E1 is clear
	bclr.b	#UFLAG,T_BYTE(a6)		;clr U flag
	move.l	USER_FPSR(a6),FPSR_SHADOW(a6)
	or.l	#sx_mask,E_BYTE(a6)
	move.l	CMDREG1B(a6),d0		;fix cmd1b to make it
	and.l	#$03c30000,d0		;work for cmd3b
	bfextu	CMDREG1B(a6){13:1},d1	;extract bit 2
	lsl.l	#5,d1			
	swap	d1
	or.l	d1,d0			;put it in the right place
	bfextu	CMDREG1B(a6){10:3},d1	;extract bit 3,4,5
	lsl.l	#2,d1
	swap	d1
	or.l	d1,d0			;put them in the right place
	move.l	d0,CMDREG3B(a6)		;in the busy frame

;
; Check if the frame to be restored is busy or unimp.
;** NOTE *** Bug fix for errata (0d43b #3)
; If the frame is unimp, we must create a busy frame to 
; fix the bug with the nmnexc bits in cases in which they
; are set by a previous instruction and not cleared by
; the save. The frame will be unimp only if the final 
; instruction in an emulation routine caused the exception
; by doing an fmove <ea>,fp0.  The exception operand, in
; internal format, is in fptemp.
;
do_clean:
	cmpi.b	#UNIMP_40_SIZE-4,1(a7)
	bne.s	do_con
	moveq.l	#13,d0			;in orig, need to zero 14 lwords
	bra.s	do_build
do_con:
	cmpi.b	#UNIMP_41_SIZE-4,1(a7)
	bne.s	do_restore		;frame must be busy
	moveq.l	#11,d0			;in rev, need to zero 12 lwords

do_build:
	move.b	(a7),VER_TMP(a6)
	clr.l	(a7)
.loop2:
	clr.l	-(a7)			;clear and dec a7
	dbra	d0,.loop2
;
; Use a1 as pointer into new frame.  a6 is not correct if an unimp or
; busy frame was created as the result of an exception on the final
; instruction of an emulation routine.
;
; We need to set the nmcexc bits if the exception is E1. Otherwise,
; the exc taken will be inex2.
;
	lea.l	BUSY_SIZE+LOCAL_SIZE(a7),a1	;init a1 for new frame
	move.b	VER_TMP(a6),(a7)	;write busy fmt word
	move.b	#BUSY_SIZE-4,1(a7)
	move.l	FP_SCR1(a6),WBTEMP_EX(a1) 	;write
	move.l	FP_SCR1+4(a6),WBTEMP_HI(a1)	;exceptional op to
	move.l	FP_SCR1+8(a6),WBTEMP_LO(a1)	;wbtemp
;	btst.b	#E1,E_BYTE(a1)
;	beq.b	do_restore
	bfextu	USER_FPSR(a6){17:4},d0	;get snan/operr/ovfl/unfl bits
	bfins	d0,NMCEXC(a1){4:4}	;and insert them in nmcexc
	move.l	USER_FPSR(a6),FPSR_SHADOW(a1) ;set exc bits
	or.l	#sx_mask,E_BYTE(a1)
	
do_restore:
	movem.l	USER_DA(a6),d0-d1/a0-a1
	fmovem.x USER_FP0(a6),fp0-fp3
	fmovem.l USER_FPCR(a6),fpcr/fpsr/fpiar
	frestore (a7)+
	tst.b	RES_FLG(a6)	;RES_FLG indicates a "continuation" frame
	beq.s	.cont
	bsr	bug1384
.cont:
	unlk	a6
;
; If trace mode enabled, then go to trace handler.  This handler 
; cannot have any fp instructions.  If there are fp inst's and an 
; exception has been restored into the machine then the exception 
; will occur upon execution of the fp inst.  This is not desirable 
; in the kernel (supervisor mode).  See MC68040 manual Section 9.3.8.
;
finish_up:
	btst.b	#7,(a7)		;test T1 in SR
	bne.s	g_trace
	btst.b	#6,(a7)		;test T0 in SR
	bne.s	g_trace
	bra.l	fpsp_done
;
; Change integer stack to look like trace stack
; The address of the instruction that caused the
; exception is already in the integer stack (is
; the same as the saved friar)
;
; If the current frame is already a 6-word stack then all
; that needs to be done is to change the vector# to TRACE.
; If the frame is only a 4-word stack (meaning we got here
; on an Unsupported data type exception), then we need to grow
; the stack an extra 2 words and get the FPIAR from the FPU.
;
g_trace:
	bftst	EXC_VEC-4(sp){0:4}
	bne	g_easy

	sub.w	#4,sp		; make room
	move.l	4(sp),(sp)
	move.l	8(sp),4(sp)
	sub.w	#BUSY_SIZE,sp
	fsave	(sp)
	fmove.l	fpiar,BUSY_SIZE+EXC_EA-4(sp)
	frestore (sp)
	add.w	#BUSY_SIZE,sp

g_easy:
	move.w	#TRACE_VEC,EXC_VEC-4(a7)
	bra.l	real_trace
;
;  This is a work-around for hardware bug 1384.
;
bug1384:
	link	a5,#0
	fsave	-(sp)
	cmpi.b	#$41,(sp)	; check for correct frame
	beq	frame_41
	bgt	nofix		; if more advanced mask, do nada

frame_40:
	tst.b	1(sp)		; check to see if idle
	bne	notidle
idle40:
	clr.l	(sp)		; get rid of old fsave frame
        move.l  d1,USER_D1(a6)  ; save d1
	move.w	#8,d1		; place unimp frame instead
loop40:	clr.l	-(sp)
	dbra	d1,loop40
        move.l  USER_D1(a6),d1  ; restore d1
	move.l	#$40280000,-(sp)
	frestore (sp)+
	unlk  	a5	
	rts

frame_41:
	tst.b	1(sp)		; check to see if idle
	bne	notidle	
idle41:
	clr.l	(sp)		; get rid of old fsave frame
        move.l  d1,USER_D1(a6)  ; save d1
	move.w	#10,d1		; place unimp frame instead
loop41:	clr.l	-(sp)
	dbra	d1,loop41
        move.l  USER_D1(a6),d1  ; restore d1
	move.l	#$41300000,-(sp)
	frestore (sp)+
	unlk	a5	
	rts

notidle:
	bclr.b	#etemp15_bit,-40(a5) 
	frestore (sp)+
	unlk	a5	
	rts

nofix:
	frestore (sp)+
	unlk	a5	
	rts

	;end
;
;	get_op.sa 3.6 5/19/92
;
;	get_op.sa 3.5 4/26/91
;
;  Description: This routine is called by the unsupported format/data
; type exception handler ('unsupp' - vector 55) and the unimplemented
; instruction exception handler ('unimp' - vector 11).  'get_op'
; determines the opclass (0, 2, or 3) and branches to the
; opclass handler routine.  See 68881/2 User's Manual table 4-11
; for a description of the opclasses.
;
; For UNSUPPORTED data/format (exception vector 55) and for
; UNIMPLEMENTED instructions (exception vector 11) the following
; applies:
;
; - For unnormalized numbers (opclass 0, 2, or 3) the
; number(s) is normalized and the operand type tag is updated.
;		
; - For a packed number (opclass 2) the number is unpacked and the
; operand type tag is updated.
;
; - For denormalized numbers (opclass 0 or 2) the number(s) is not
; changed but passed to the next module.  The next module for
; unimp is do_func, the next module for unsupp is res_func.
;
; For UNSUPPORTED data/format (exception vector 55) only the
; following applies:
;
; - If there is a move out with a packed number (opclass 3) the
; number is packed and written to user memory.  For the other
; opclasses the number(s) are written back to the fsave stack
; and the instruction is then restored back into the '040.  The
; '040 is then able to complete the instruction.
;
; For example:
; fadd.x fpm,fpn where the fpm contains an unnormalized number.
; The '040 takes an unsupported data trap and gets to this
; routine.  The number is normalized, put back on the stack and
; then an frestore is done to restore the instruction back into
; the '040.  The '040 then re-executes the fadd.x fpm,fpn with
; a normalized number in the source and the instruction is
; successful.
;		
; Next consider if in the process of normalizing the un-
; normalized number it becomes a denormalized number.  The
; routine which converts the unnorm to a norm (called mk_norm)
; detects this and tags the number as a denorm.  The routine
; res_func sees the denorm tag and converts the denorm to a
; norm.  The instruction is then restored back into the '040
; which re_executes the instruction.
;
;
;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

GET_OP:    ;idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	

	;|.global	PIRN,PIRZRM,PIRP
	;|.global	SMALRN,SMALRZRM,SMALRP
	;|.global	BIGRN,BIGRZRM,BIGRP

PIRN:
	dc.l $40000000,$c90fdaa2,$2168c235    ;pi
PIRZRM:
	dc.l $40000000,$c90fdaa2,$2168c234    ;pi
PIRP:
	dc.l $40000000,$c90fdaa2,$2168c235    ;pi

;round to nearest
SMALRN:
	dc.l $3ffd0000,$9a209a84,$fbcff798    ;log10(2)
	dc.l $40000000,$adf85458,$a2bb4a9a    ;e
	dc.l $3fff0000,$b8aa3b29,$5c17f0bc    ;log2(e)
	dc.l $3ffd0000,$de5bd8a9,$37287195    ;log10(e)
	dc.l $00000000,$00000000,$00000000    ;0.0
; round to zero;round to negative infinity
SMALRZRM:
	dc.l $3ffd0000,$9a209a84,$fbcff798    ;log10(2)
	dc.l $40000000,$adf85458,$a2bb4a9a    ;e
	dc.l $3fff0000,$b8aa3b29,$5c17f0bb    ;log2(e)
	dc.l $3ffd0000,$de5bd8a9,$37287195    ;log10(e)
	dc.l $00000000,$00000000,$00000000    ;0.0
; round to positive infinity
SMALRP:
	dc.l $3ffd0000,$9a209a84,$fbcff799    ;log10(2)
	dc.l $40000000,$adf85458,$a2bb4a9b    ;e
	dc.l $3fff0000,$b8aa3b29,$5c17f0bc    ;log2(e)
	dc.l $3ffd0000,$de5bd8a9,$37287195    ;log10(e)
	dc.l $00000000,$00000000,$00000000    ;0.0

;round to nearest
BIGRN:
	dc.l $3ffe0000,$b17217f7,$d1cf79ac    ;ln(2)
	dc.l $40000000,$935d8ddd,$aaa8ac17    ;ln(10)
	dc.l $3fff0000,$80000000,$00000000    ;10 ^ 0

	;|.global	PTENRN
PTENRN:
	dc.l $40020000,$A0000000,$00000000    ;10 ^ 1
	dc.l $40050000,$C8000000,$00000000    ;10 ^ 2
	dc.l $400C0000,$9C400000,$00000000    ;10 ^ 4
	dc.l $40190000,$BEBC2000,$00000000    ;10 ^ 8
	dc.l $40340000,$8E1BC9BF,$04000000    ;10 ^ 16
	dc.l $40690000,$9DC5ADA8,$2B70B59E    ;10 ^ 32
	dc.l $40D30000,$C2781F49,$FFCFA6D5    ;10 ^ 64
	dc.l $41A80000,$93BA47C9,$80E98CE0    ;10 ^ 128
	dc.l $43510000,$AA7EEBFB,$9DF9DE8E    ;10 ^ 256
	dc.l $46A30000,$E319A0AE,$A60E91C7    ;10 ^ 512
	dc.l $4D480000,$C9767586,$81750C17    ;10 ^ 1024
	dc.l $5A920000,$9E8B3B5D,$C53D5DE5    ;10 ^ 2048
	dc.l $75250000,$C4605202,$8A20979B    ;10 ^ 4096
;round to minus infinity
BIGRZRM:
	dc.l $3ffe0000,$b17217f7,$d1cf79ab    ;ln(2)
	dc.l $40000000,$935d8ddd,$aaa8ac16    ;ln(10)
	dc.l $3fff0000,$80000000,$00000000    ;10 ^ 0

	;|.global	PTENRM
PTENRM:
	dc.l $40020000,$A0000000,$00000000    ;10 ^ 1
	dc.l $40050000,$C8000000,$00000000    ;10 ^ 2
	dc.l $400C0000,$9C400000,$00000000    ;10 ^ 4
	dc.l $40190000,$BEBC2000,$00000000    ;10 ^ 8
	dc.l $40340000,$8E1BC9BF,$04000000    ;10 ^ 16
	dc.l $40690000,$9DC5ADA8,$2B70B59D    ;10 ^ 32
	dc.l $40D30000,$C2781F49,$FFCFA6D5    ;10 ^ 64
	dc.l $41A80000,$93BA47C9,$80E98CDF    ;10 ^ 128
	dc.l $43510000,$AA7EEBFB,$9DF9DE8D    ;10 ^ 256
	dc.l $46A30000,$E319A0AE,$A60E91C6    ;10 ^ 512
	dc.l $4D480000,$C9767586,$81750C17    ;10 ^ 1024
	dc.l $5A920000,$9E8B3B5D,$C53D5DE5    ;10 ^ 2048
	dc.l $75250000,$C4605202,$8A20979A    ;10 ^ 4096
;round to positive infinity
BIGRP:
	dc.l $3ffe0000,$b17217f7,$d1cf79ac    ;ln(2)
	dc.l $40000000,$935d8ddd,$aaa8ac17    ;ln(10)
	dc.l $3fff0000,$80000000,$00000000    ;10 ^ 0

	;|.global	PTENRP
PTENRP:
	dc.l $40020000,$A0000000,$00000000    ;10 ^ 1
	dc.l $40050000,$C8000000,$00000000    ;10 ^ 2
	dc.l $400C0000,$9C400000,$00000000    ;10 ^ 4
	dc.l $40190000,$BEBC2000,$00000000    ;10 ^ 8
	dc.l $40340000,$8E1BC9BF,$04000000    ;10 ^ 16
	dc.l $40690000,$9DC5ADA8,$2B70B59E    ;10 ^ 32
	dc.l $40D30000,$C2781F49,$FFCFA6D6    ;10 ^ 64
	dc.l $41A80000,$93BA47C9,$80E98CE0    ;10 ^ 128
	dc.l $43510000,$AA7EEBFB,$9DF9DE8E    ;10 ^ 256
	dc.l $46A30000,$E319A0AE,$A60E91C7    ;10 ^ 512
	dc.l $4D480000,$C9767586,$81750C18    ;10 ^ 1024
	dc.l $5A920000,$9E8B3B5D,$C53D5DE6    ;10 ^ 2048
	dc.l $75250000,$C4605202,$8A20979B    ;10 ^ 4096

	;xref	nrm_zero
	;xref	decbin
	;xref	round

	;|.global    get_op
	;|.global    uns_getop
	;|.global    uni_getop
get_op:
	clr.b	DY_MO_FLG(a6)
	tst.b	UFLG_TMP(a6)	;test flag for unsupp/unimp state
	beq.s	uni_getop

uns_getop:
	btst.b	#direction_bit,CMDREG1B(a6)
	bne	opclass3_	;branch if a fmove out (any kind)
	btst.b	#6,CMDREG1B(a6)
	beq.s	uns_notpacked

	bfextu	CMDREG1B(a6){3:3},d0
	cmp.b	#3,d0
	beq	pack_source	;check for a packed src op, branch if so
uns_notpacked:
	bsr	chk_dy_mo	;set the dyadic/monadic flag
	tst.b	DY_MO_FLG(a6)
	beq.s	src_op_ck	;if monadic, go check src op
;				;else, check dst op (fall through)

	btst.b	#7,DTAG(a6)
	beq.s	src_op_ck	;if dst op is norm, check src op
	bra.s	dst_ex_dnrm	;else, handle destination unnorm/dnrm

uni_getop:
	bfextu	CMDREG1B(a6){0:6},d0 ;get opclass and src fields
	cmpi.l	#$17,d0		;if op class and size fields are $17, 
;				;it is FMOVECR; if not, continue
;
; If the instruction is fmovecr, exit get_op.  It is handled
; in do_func and smovecr.sa.
;
	bne	not_fmovecr	;handle fmovecr as an unimplemented inst
	rts

not_fmovecr:
	btst.b	#E1,E_BYTE(a6)	;if set, there is a packed operand
	bne	pack_source	;check for packed src op, branch if so

; The following lines of are coded to optimize on normalized operands
	move.b	STAG(a6),d0
	or.b	DTAG(a6),d0	;check if either of STAG/DTAG msb set
	bmi.s	dest_op_ck	;if so, some op needs to be fixed
	rts

dest_op_ck:
	btst.b	#7,DTAG(a6)	;check for unsupported data types in
	beq.s	src_op_ck	;the destination, if not, check src op
	bsr	chk_dy_mo	;set dyadic/monadic flag
	tst.b	DY_MO_FLG(a6)	;
	beq.s	src_op_ck	;if monadic, check src op
;
; At this point, destination has an extended denorm or unnorm.
;
dst_ex_dnrm:
	move.w	FPTEMP_EX(a6),d0 ;get destination exponent
	andi.w	#$7fff,d0	;mask sign, check if exp = 0000
	beq.s	src_op_ck	;if denorm then check source op.
;				;denorms are taken care of in res_func 
;				;(unsupp) or do_func (unimp)
;				;else unnorm fall through
	lea.l	FPTEMP(a6),a0	;point a0 to dop - used in mk_norm
	bsr	mk_norm		;go normalize - mk_norm returns:
;				;L_SCR1{7:5} = operand tag 
;				;	(000 = norm, 100 = denorm)
;				;L_SCR1{4} = fpte15 or ete15 
;				;	0 = exp >  $3fff
;				;	1 = exp <= $3fff
;				;and puts the normalized num back 
;				;on the fsave stack
;
	move.b L_SCR1(a6),DTAG(a6) ;write the new tag & fpte15 
;				;to the fsave stack and fall 
;				;through to check source operand
;
src_op_ck:
	btst.b	#7,STAG(a6)
	beq	end_getop	;check for unsupported data types on the
;				;source operand
	btst.b	#5,STAG(a6)
	bne.s	src_sd_dnrm	;if bit 5 set, handle sgl/dbl denorms
;
; At this point only unnorms or extended denorms are possible.
;
src_ex_dnrm:
	move.w	ETEMP_EX(a6),d0 ;get source exponent
	andi.w	#$7fff,d0	;mask sign, check if exp = 0000
	beq	end_getop	;if denorm then exit, denorms are 
;				;handled in do_func
	lea.l	ETEMP(a6),a0	;point a0 to sop - used in mk_norm
	bsr	mk_norm		;go normalize - mk_norm returns:
;				;L_SCR1{7:5} = operand tag 
;				;	(000 = norm, 100 = denorm)
;				;L_SCR1{4} = fpte15 or ete15 
;				;	0 = exp >  $3fff
;				;	1 = exp <= $3fff
;				;and puts the normalized num back 
;				;on the fsave stack
;
	move.b	L_SCR1(a6),STAG(a6) ;write the new tag & ete15 
	rts			;end_getop

;
; At this point, only single or double denorms are possible.
; If the inst is not fmove, normalize the source.  If it is,
; do nothing to the input.
;
src_sd_dnrm:
	btst.b	#4,CMDREG1B(a6)	;differentiate between sgl/dbl denorm
	bne.s	is_double
is_single:
	move.w	#$3f81,d1	;write bias for sgl denorm
	bra.s	common		;goto the common code
is_double:
	move.w	#$3c01,d1	;write the bias for a dbl denorm
common:
	btst.b	#sign_bit,ETEMP_EX(a6) ;grab sign bit of mantissa
	beq.s	pos	
	bset	#15,d1		;set sign bit because it is negative
pos:
	move.w	d1,ETEMP_EX(a6)
;				;put exponent on stack

	move.w	CMDREG1B(a6),d1
	and.w	#$e3ff,d1	;clear out source specifier
	or.w	#$0800,d1	;set source specifier to extended prec
	move.w	d1,CMDREG1B(a6)	;write back to the command word in stack
;				;this is needed to fix unsupp data stack
	lea.l	ETEMP(a6),a0	;point a0 to sop
	
	bsr	mk_norm		;convert sgl/dbl denorm to norm
	move.b	L_SCR1(a6),STAG(a6) ;put tag into source tag reg - d0
	rts			;end_getop
;
; At this point, the source is definitely packed, whether
; instruction is dyadic or monadic is still unknown
;
pack_source:
	move.l	FPTEMP_LO(a6),ETEMP(a6)	;write ms part of packed 
;				;number to etemp slot
	bsr	chk_dy_mo	;set dyadic/monadic flag
	bsr	unpack

	tst.b	DY_MO_FLG(a6)
	beq.s	end_getop	;if monadic, exit
;				;else, fix FPTEMP
pack_dya:
	bfextu	CMDREG1B(a6){6:3},d0 ;extract dest fp reg
	move.l	#7,d1
	sub.l	d0,d1
	clr.l	d0
	bset.l	d1,d0		;set up d0 as a dynamic register mask
	fmovem.x d0,FPTEMP(a6)	;write to FPTEMP

	btst.b	#7,DTAG(a6)	;check dest tag for unnorm or denorm
	bne	dst_ex_dnrm	;else, handle the unnorm or ext denorm
;
; Dest is not denormalized.  Check for norm, and set fpte15 
; accordingly.
;
	move.b	DTAG(a6),d0
	andi.b	#$f0,d0		;strip to only dtag:fpte15
	tst.b	d0		;check for normalized value
	bne.s	end_getop	;if inf/nan/zero leave get_op
	move.w	FPTEMP_EX(a6),d0
	andi.w	#$7fff,d0
	cmpi.w	#$3fff,d0	;check if fpte15 needs setting
	bge.s	end_getop	;if >= $3fff, leave fpte15=0
	or.b	#$10,DTAG(a6)
	bra.s	end_getop

;
; At this point, it is either an fmoveout packed, unnorm or denorm
;
opclass3_:
	clr.b	DY_MO_FLG(a6)	;set dyadic/monadic flag to monadic
	bfextu	CMDREG1B(a6){4:2},d0
	cmpi.b	#3,d0
	bne	src_ex_dnrm	;if not equal, must be unnorm or denorm
;				;else it is a packed move out
;				;exit
end_getop:
	rts

;
; Sets the DY_MO_FLG correctly. This is used only on if it is an
; unsupported data type exception.  Set if dyadic.
;
chk_dy_mo:
	move.w	CMDREG1B(a6),d0	
	btst.l	#5,d0		;testing extension command word
	beq.s	set_mon		;if bit 5 = 0 then monadic
	btst.l	#4,d0		;know that bit 5 = 1
	beq.s	set_dya		;if bit 4 = 0 then dyadic
	andi.w	#$007f,d0	;get rid of all but extension bits {6:0}
	cmpi.w 	#$0038,d0	;if extension = $38 then fcmp (dyadic)
	bne.s	set_mon
set_dya:
	st	DY_MO_FLG(a6)	;set the inst flag type to dyadic
	rts
set_mon:
	clr.b	DY_MO_FLG(a6)	;set the inst flag type to monadic
	rts
;
;	MK_NORM
;
; Normalizes unnormalized numbers, sets tag to norm or denorm, sets unfl
; exception if denorm.
;
; CASE opclass $0 unsupp
;	mk_norm till msb set
;	set tag = norm
;
; CASE opclass $0 unimp
;	mk_norm till msb set or exp = 0
;	if integer bit = 0
;	   tag = denorm
;	else
;	   tag = norm
;
; CASE opclass 011 unsupp
;	mk_norm till msb set or exp = 0
;	if integer bit = 0
;	   tag = denorm
;	   set unfl_nmcexe = 1
;	else
;	   tag = norm
;
; if exp <= $3fff
;   set ete15 or fpte15 = 1
; else set ete15 or fpte15 = 0

; input:
;	a0 = points to operand to be normalized
; output:
;	L_SCR1{7:5} = operand tag (000 = norm, 100 = denorm)
;	L_SCR1{4}   = fpte15 or ete15 (0 = exp > $3fff, 1 = exp <=$3fff)
;	the normalized operand is placed back on the fsave stack
mk_norm:	
	clr.l	L_SCR1(a6)
	bclr.b	#sign_bit,LOCAL_EX(a0)
	sne	LOCAL_SGN(a0)	;transform into internal extended format

	cmpi.b	#$2c,1+EXC_VEC(a6) ;check if unimp
	bne.s	uns_data	;branch if unsupp
	bsr	uni_inst	;call if unimp (opclass $0)
	bra.s	reload
uns_data:
	btst.b	#direction_bit,CMDREG1B(a6) ;check transfer direction
	bne.s	bit_set		;branch if set (opclass 011)
	bsr	uns_opx		;call if opclass $0
	bra.s	reload
bit_set:
	bsr	uns_op3		;opclass 011
reload:
	cmp.w	#$3fff,LOCAL_EX(a0) ;if exp > $3fff
	bgt.s	end_mk		;   fpte15/ete15 already set to 0
	bset.b	#4,L_SCR1(a6)	;else set fpte15/ete15 to 1
;				;calling routine actually sets the 
;				;value on the stack (along with the 
;				;tag), since this routine doesn't 
;				;know if it should set ete15 or fpte15
;				;ie, it doesn't know if this is the 
;				;src op or dest op.
end_mk:
	bfclr	LOCAL_SGN(a0){0:8}
	beq.s	end_mk_pos
	bset.b	#sign_bit,LOCAL_EX(a0) ;convert back to IEEE format
end_mk_pos:
	rts
;
;     CASE opclass 011 unsupp
;
uns_op3:
	bsr	nrm_zero	;normalize till msb = 1 or exp = zero
	btst.b	#7,LOCAL_HI(a0)	;if msb = 1
	bne.s	no_unfl		;then branch
set_unfl:
	or.w	#dnrm_tag,L_SCR1(a6) ;set denorm tag
	bset.b	#unfl_bit,FPSR_EXCEPT(a6) ;set unfl exception bit
no_unfl:
	rts
;
;     CASE opclass $0 unsupp
;
uns_opx:
	bsr	nrm_zero	;normalize the number
	btst.b	#7,LOCAL_HI(a0)	;check if integer bit (j-bit) is set 
	beq.s	uns_den		;if clear then now have a denorm
uns_nrm:
	or.b	#norm_tag,L_SCR1(a6) ;set tag to norm
	rts
uns_den:
	or.b	#dnrm_tag,L_SCR1(a6) ;set tag to denorm
	rts
;
;     CASE opclass $0 unimp
;
uni_inst:
	bsr	nrm_zero
	btst.b	#7,LOCAL_HI(a0)	;check if integer bit (j-bit) is set 
	beq.s	uni_den		;if clear then now have a denorm
uni_nrm:
	or.b	#norm_tag,L_SCR1(a6) ;set tag to norm
	rts
uni_den:
	or.b	#dnrm_tag,L_SCR1(a6) ;set tag to denorm
	rts

;
;	Decimal to binary conversion
;
; Special cases of inf and NaNs are completed outside of decbin.  
; If the input is an snan, the snan bit is not set.
; 
; input:
;	ETEMP(a6)	- points to packed decimal string in memory
; output:
;	fp0	- contains packed string converted to extended precision
;	ETEMP	- same as fp0
unpack:
	move.w	CMDREG1B(a6),d0	;examine command word, looking for fmove's
	and.w	#$3b,d0
	beq	move_unpack	;special handling for fmove: must set FPSR_CC

	move.w	ETEMP(a6),d0	;get word with inf information
	bfextu	d0{20:12},d1	;get exponent into d1
	cmpi.w	#$0fff,d1	;test for inf or NaN
	bne.s	try_zero	;if not equal, it is not special
	bfextu	d0{17:3},d1	;get SE and y bits into d1
	cmpi.w	#7,d1		;SE and y bits must be on for special
	bne.s	try_zero	;if not on, it is not special
;input is of the special cases of inf and NaN
	tst.l	ETEMP_HI(a6)	;check ms mantissa
	bne.s	fix_nan		;if non-zero, it is a NaN
	tst.l	ETEMP_LO(a6)	;check ls mantissa
	bne.s	fix_nan		;if non-zero, it is a NaN
	bra	finish2		;special already on stack
fix_nan:
	btst.b	#signan_bit,ETEMP_HI(a6) ;test for snan
	bne	finish2
	or.l	#snaniop_mask,USER_FPSR(a6) ;always set snan if it is so
	bra	finish2
try_zero:
	move.w	ETEMP_EX+2(a6),d0 ;get word 4
	andi.w	#$000f,d0	;clear all but last ni(y)bble
	tst.w	d0		;check for zero.
	bne	not_spec
	tst.l	ETEMP_HI(a6)	;check words 3 and 2
	bne	not_spec
	tst.l	ETEMP_LO(a6)	;check words 1 and 0
	bne	not_spec
	tst.l	ETEMP(a6)	;test sign of the zero
	bge.s	pos_zero
	move.l	#$80000000,ETEMP(a6) ;write neg zero to etemp
	clr.l	ETEMP_HI(a6)
	clr.l	ETEMP_LO(a6)
	bra	finish2
pos_zero:
	clr.l	ETEMP(a6)
	clr.l	ETEMP_HI(a6)
	clr.l	ETEMP_LO(a6)
	bra	finish2

not_spec:
	fmovem.x fp0-fp1,-(a7)	;save fp0 - decbin returns in it
	bsr	decbin
	fmove.x fp0,ETEMP(a6)	;put the unpacked sop in the fsave stack
	fmovem.x (a7)+,fp0-fp1
	fmove.l	#0,FPSR		;clr fpsr from decbin
	bra	finish2

;
; Special handling for packed move in:  Same results as all other
; packed cases, but we must set the FPSR condition codes properly.
;
move_unpack:
	move.w	ETEMP(a6),d0	;get word with inf information
	bfextu	d0{20:12},d1	;get exponent into d1
	cmpi.w	#$0fff,d1	;test for inf or NaN
	bne.s	mtry_zero	;if not equal, it is not special
	bfextu	d0{17:3},d1	;get SE and y bits into d1
	cmpi.w	#7,d1		;SE and y bits must be on for special
	bne.s	mtry_zero	;if not on, it is not special
;input is of the special cases of inf and NaN
	tst.l	ETEMP_HI(a6)	;check ms mantissa
	bne.s	mfix_nan		;if non-zero, it is a NaN
	tst.l	ETEMP_LO(a6)	;check ls mantissa
	bne.s	mfix_nan		;if non-zero, it is a NaN
;input is inf
	or.l	#inf_mask,USER_FPSR(a6) ;set I bit
	tst.l	ETEMP(a6)	;check sign
	bge	finish2
	or.l	#neg_mask,USER_FPSR(a6) ;set N bit
	bra	finish2		;special already on stack
mfix_nan:
	or.l	#nan_mask,USER_FPSR(a6) ;set NaN bit
	move.b	#nan_tag,STAG(a6)	;set stag to NaN
	btst.b	#signan_bit,ETEMP_HI(a6) ;test for snan
	bne.s	mn_snan
	or.l	#snaniop_mask,USER_FPSR(a6) ;set snan bit
	btst.b	#snan_bit,FPCR_ENABLE(a6) ;test for snan enabled
	bne.s	mn_snan
	bset.b	#signan_bit,ETEMP_HI(a6) ;force snans to qnans
mn_snan:
	tst.l	ETEMP(a6)	;check for sign
	bge	finish2		;if clr, go on
	or.l	#neg_mask,USER_FPSR(a6) ;set N bit
	bra	finish2

mtry_zero:
	move.w	ETEMP_EX+2(a6),d0 ;get word 4
	andi.w	#$000f,d0	;clear all but last ni(y)bble
	tst.w	d0		;check for zero.
	bne.s	mnot_spec
	tst.l	ETEMP_HI(a6)	;check words 3 and 2
	bne.s	mnot_spec
	tst.l	ETEMP_LO(a6)	;check words 1 and 0
	bne.s	mnot_spec
	tst.l	ETEMP(a6)	;test sign of the zero
	bge.s	mpos_zero
	or.l	#neg_mask+z_mask,USER_FPSR(a6) ;set N and Z
	move.l	#$80000000,ETEMP(a6) ;write neg zero to etemp
	clr.l	ETEMP_HI(a6)
	clr.l	ETEMP_LO(a6)
	bra.s	finish2
mpos_zero:
	or.l	#z_mask,USER_FPSR(a6) ;set Z
	clr.l	ETEMP(a6)
	clr.l	ETEMP_HI(a6)
	clr.l	ETEMP_LO(a6)
	bra.s	finish2

mnot_spec:
	fmovem.x fp0-fp1,-(a7)	;save fp0 ,fp1 - decbin returns in fp0
	bsr	decbin
	fmove.x fp0,ETEMP(a6)
;				;put the unpacked sop in the fsave stack
	fmovem.x (a7)+,fp0-fp1

finish2:
	move.w	CMDREG1B(a6),d0	;get the command word
	and.w	#$fbff,d0	;change the source specifier field to 
;				;extended (was packed).
	move.w	d0,CMDREG1B(a6)	;write command word back to fsave stack
;				;we need to do this so the 040 will 
;				;re-execute the inst. without taking 
;				;another packed trap.

fix_stag:
;Converted result is now in etemp on fsave stack, now set the source 
;tag (stag) 
;	if (ete =$7fff) then INF or NAN
;		if (etemp = $x.0----0) then
;			stag = INF
;		else
;			stag = NAN
;	else
;		if (ete = $0000) then
;			stag = ZERO
;		else
;			stag = NORM
;
; Note also that the etemp_15 bit (just right of the stag) must
; be set accordingly.  
;
	move.w		ETEMP_EX(a6),d1
	andi.w		#$7fff,d1   ;strip sign
	cmp.w  		#$7fff,d1
	bne.s  		z_or_nrm
	move.l		ETEMP_HI(a6),d1
	bne.s		is_nan
	move.l		ETEMP_LO(a6),d1
	bne.s		is_nan
is_inf:
	move.b		#$40,STAG(a6)
	move.l		#$40,d0
	rts
is_nan:
	move.b		#$60,STAG(a6)
	move.l		#$60,d0
	rts
z_or_nrm:
	tst.w		d1  
	bne.s		is_nrm
is_zro:
; For a zero, set etemp_15
	move.b		#$30,STAG(a6)
	move.l		#$20,d0
	rts
is_nrm:
; For a norm, check if the exp <= $3fff; if so, set etemp_15
	cmpi.w		#$3fff,d1
	ble.s		set_bit15
	move.b		#0,STAG(a6)
	bra.s		end_is_nrm
set_bit15:
	move.b		#$10,STAG(a6)
end_is_nrm:
	move.l		#0,d0
end_fix:
	rts
 
end_get:
	rts
	;end
;
;	kernel_ex.sa 3.3 12/19/90 
;
; This file contains routines to force exception status in the 
; fpu for exceptional cases detected or reported within the
; transcendental functions.  Typically, the t_xx routine will
; set the appropriate bits in the USER_FPSR word on the stack.
; The bits are tested in gen_except.sa to determine if an exceptional
; situation needs to be created on return from the FPSP. 
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

KERNEL_EX:    ;idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section    8

	

mns_inf:  dc.l $ffff0000,$00000000,$00000000
pls_inf:  dc.l $7fff0000,$00000000,$00000000
nan:      dc.l $7fff0000,$ffffffff,$ffffffff
huge:     dc.l $7ffe0000,$ffffffff,$ffffffff

	;xref	  ovf_r_k
	;xref	  unf_sub
	;xref	  nrm_set

	;|.global   	  t_dz
	;|.global      t_dz2
	;|.global      t_operr
	;|.global      t_unfl
	;|.global      t_ovfl
	;|.global      t_ovfl2
	;|.global      t_inx2
	;|.global	  t_frcinx
	;|.global	  t_extdnrm
	;|.global	  t_resdnrm
	;|.global	  dst_nan
	;|.global	  src_nan
;
;	DZ exception
;
;
;	if dz trap disabled
;		store properly signed inf (use sign of etemp) into fp0
;		set FPSR exception status dz bit, condition code 
;		inf bit, and accrued dz bit
;		return
;		frestore the frame into the machine (done by unimp_hd)
;
;	else dz trap enabled
;		set exception status bit & accrued bits in FPSR
;		set flag to disable sto_res from corrupting fp register
;		return
;		frestore the frame into the machine (done by unimp_hd)
;
; t_dz2 is used by monadic functions such as flogn (from do_func).
; t_dz is used by monadic functions such as satanh (from the 
; transcendental function).
;
t_dz2:
	bset.b	#neg_bit,FPSR_CC(a6)	;set neg bit in FPSR
	fmove.l	#0,FPSR			;clr status bits (Z set)
	btst.b	#dz_bit,FPCR_ENABLE(a6)	;test FPCR for dz exc enabled
	bne.s	dz_ena_end
	bra.s	m_inf			;flogx always returns -inf
t_dz:
	fmove.l	#0,FPSR			;clr status bits (Z set)
	btst.b	#dz_bit,FPCR_ENABLE(a6)	;test FPCR for dz exc enabled
	bne.s	dz_ena
;
;	dz disabled
;
	btst.b	#sign_bit,ETEMP_EX(a6)	;check sign for neg or pos
	beq.s	p_inf			;branch if pos sign

m_inf:
	fmovem.x mns_inf(pc),fp0-fp0		;load -inf
	bset.b	#neg_bit,FPSR_CC(a6)	;set neg bit in FPSR
	bra.s	set_fpsr
p_inf:
	fmovem.x pls_inf(pc),fp0-fp0		;load +inf
set_fpsr:
	or.l	#dzinf_mask,USER_FPSR(a6) ;set I,DZ,ADZ
	rts
;
;	dz enabled
;
dz_ena:
	btst.b	#sign_bit,ETEMP_EX(a6)	;check sign for neg or pos
	beq.s	dz_ena_end
	bset.b	#neg_bit,FPSR_CC(a6)	;set neg bit in FPSR
dz_ena_end:
	or.l	#dzinf_mask,USER_FPSR(a6) ;set I,DZ,ADZ
	st	STORE_FLG(a6)
	rts
;
;	OPERR exception
;
;	if (operr trap disabled)
;		set FPSR exception status operr bit, condition code 
;		nan bit; Store default NAN into fp0
;		frestore the frame into the machine (done by unimp_hd)
;	
;	else (operr trap enabled)
;		set FPSR exception status operr bit, accrued operr bit
;		set flag to disable sto_res from corrupting fp register
;		frestore the frame into the machine (done by unimp_hd)
;
t_operr:
	or.l	#opnan_mask,USER_FPSR(a6) ;set NaN, OPERR, AIOP

	btst.b	#operr_bit,FPCR_ENABLE(a6) ;test FPCR for operr enabled
	bne.s	op_ena

	fmovem.x nan(pc),fp0-fp0		;load default nan
	rts
op_ena:
	st	STORE_FLG(a6)		;do not corrupt destination
	rts

;
;	t_unfl --- UNFL exception
;
; This entry point is used by all routines requiring unfl, inex2,
; aunfl, and ainex to be set on exit.
;
; On entry, a0 points to the exceptional operand.  The final exceptional
; operand is built in FP_SCR1 and only the sign from the original operand
; is used.
;
t_unfl:
	clr.l	FP_SCR1(a6)		;set exceptional operand to zero
	clr.l	FP_SCR1+4(a6)
	clr.l	FP_SCR1+8(a6)
	tst.b	(a0)			;extract sign from caller's exop
	bpl.s	unfl_signok
	bset	#sign_bit,FP_SCR1(a6)
unfl_signok:
	lea.l	FP_SCR1(a6),a0
	or.l	#unfinx_mask,USER_FPSR(a6)
;					;set UNFL, INEX2, AUNFL, AINEX
unfl_con:
	btst.b	#unfl_bit,FPCR_ENABLE(a6)
	beq.s	unfl_dis

unfl_ena:
	bfclr	STAG(a6){5:3}		;clear wbtm66,wbtm1,wbtm0
	bset.b	#wbtemp15_bit,WB_BYTE(a6) ;set wbtemp15
	bset.b	#sticky_bit,STICKY(a6)	;set sticky bit

	bclr.b	#E1,E_BYTE(a6)

unfl_dis:
	bfextu	FPCR_MODE(a6){0:2},d0	;get round precision
	
	bclr.b	#sign_bit,LOCAL_EX(a0)
	sne	LOCAL_SGN(a0)		;convert to internal ext format

	bsr	unf_sub			;returns IEEE result at a0
;					;and sets FPSR_CC accordingly
	
	bfclr	LOCAL_SGN(a0){0:8}	;convert back to IEEE ext format
	beq.s	unfl_fin

	bset.b	#sign_bit,LOCAL_EX(a0)
	bset.b	#sign_bit,FP_SCR1(a6)	;set sign bit of exc operand

unfl_fin:
	fmovem.x (a0),fp0-fp0		;store result in fp0
	rts
	

;
;	t_ovfl2 --- OVFL exception (without inex2 returned)
;
; This entry is used by scale to force catastrophic overflow.  The
; ovfl, aovfl, and ainex bits are set, but not the inex2 bit.
;
t_ovfl2:
	or.l	#ovfl_inx_mask,USER_FPSR(a6)
	move.l	ETEMP(a6),FP_SCR1(a6)
	move.l	ETEMP_HI(a6),FP_SCR1+4(a6)
	move.l	ETEMP_LO(a6),FP_SCR1+8(a6)
;
; Check for single or double round precision.  If single, check if
; the lower 40 bits of ETEMP are zero; if not, set inex2.  If double,
; check if the lower 21 bits are zero; if not, set inex2.
;
	move.b	FPCR_MODE(a6),d0
	andi.b	#$c0,d0
	beq	t_work		;if extended, finish ovfl processing
	cmpi.b	#$40,d0		;test for single
	bne.s	t_dbl
t_sgl:
	tst.b	ETEMP_LO(a6)
	bne.s	t_setinx2
	move.l	ETEMP_HI(a6),d0
	andi.l	#$ff,d0		;look at only lower 8 bits
	bne.s	t_setinx2
	bra	t_work
t_dbl:
	move.l	ETEMP_LO(a6),d0
	andi.l	#$7ff,d0	;look at only lower 11 bits
	beq	t_work
t_setinx2:
	or.l	#inex2_mask,USER_FPSR(a6)
	bra.s	t_work
;
;	t_ovfl --- OVFL exception
;
;** Note: the exc operand is returned in ETEMP.
;
t_ovfl:
	or.l	#ovfinx_mask,USER_FPSR(a6)
t_work:
	btst.b	#ovfl_bit,FPCR_ENABLE(a6) ;test FPCR for ovfl enabled
	beq.s	ovf_dis

ovf_ena:
	clr.l	FP_SCR1(a6)		;set exceptional operand
	clr.l	FP_SCR1+4(a6)
	clr.l	FP_SCR1+8(a6)

	bfclr	STAG(a6){5:3}		;clear wbtm66,wbtm1,wbtm0
	bclr.b	#wbtemp15_bit,WB_BYTE(a6) ;clear wbtemp15
	bset.b	#sticky_bit,STICKY(a6)	;set sticky bit

	bclr.b	#E1,E_BYTE(a6)
;					;fall through to disabled case

; For disabled overflow call 'ovf_r_k'.  This routine loads the
; correct result based on the rounding precision, destination
; format, rounding mode and sign.
;
ovf_dis:
	bsr	ovf_r_k			;returns unsigned ETEMP_EX
;					;and sets FPSR_CC accordingly.
	bfclr	ETEMP_SGN(a6){0:8}	;fix sign
	beq.s	ovf_pos
	bset.b	#sign_bit,ETEMP_EX(a6)
	bset.b	#sign_bit,FP_SCR1(a6)	;set exceptional operand sign
ovf_pos:
	fmovem.x ETEMP(a6),fp0-fp0		;move the result to fp0
	rts


;
;	INEX2 exception
;
; The inex2 and ainex bits are set.
;
t_inx2:
	or.l	#inx2a_mask,USER_FPSR(a6) ;set INEX2, AINEX
	rts

;
;	Force Inex2
;
; This routine is called by the transcendental routines to force
; the inex2 exception bits set in the FPSR.  If the underflow bit
; is set, but the underflow trap was not taken, the aunfl bit in
; the FPSR must be set.
;
t_frcinx:
	or.l	#inx2a_mask,USER_FPSR(a6) ;set INEX2, AINEX
	btst.b	#unfl_bit,FPSR_EXCEPT(a6) ;test for unfl bit set
	beq.s	no_uacc1		;if clear, do not set aunfl
	bset.b	#aunfl_bit,FPSR_AEXCEPT(a6)
no_uacc1:
	rts

;
;	DST_NAN
;
; Determine if the destination nan is signalling or non-signalling,
; and set the FPSR bits accordingly.  See the MC68040 User's Manual 
; section 3.2.2.5 NOT-A-NUMBERS.
;
dst_nan:
	btst.b	#sign_bit,FPTEMP_EX(a6) ;test sign of nan
	beq.s	dst_pos			;if clr, it was positive
	bset.b	#neg_bit,FPSR_CC(a6)	;set N bit
dst_pos:
	btst.b	#signan_bit,FPTEMP_HI(a6) ;check if signalling 
	beq.s	dst_snan		;branch if signalling

	fmove.l	d1,fpcr			;restore user's rmode/prec
	fmove.x FPTEMP(a6),fp0		;return the non-signalling nan
;
; Check the source nan.  If it is signalling, snan will be reported.
;
	move.b	STAG(a6),d0
	andi.b	#$e0,d0
	cmpi.b	#$60,d0
	bne.s	no_snan
	btst.b	#signan_bit,ETEMP_HI(a6) ;check if signalling 
	bne.s	no_snan
	or.l	#snaniop_mask,USER_FPSR(a6) ;set NAN, SNAN, AIOP
no_snan:
	rts	

dst_snan:
	btst.b	#snan_bit,FPCR_ENABLE(a6) ;check if trap enabled 
	beq.s	dst_dis			;branch if disabled

	or.b	#nan_tag,DTAG(a6)	;set up dtag for nan
	st	STORE_FLG(a6)		;do not store a result
	or.l	#snaniop_mask,USER_FPSR(a6) ;set NAN, SNAN, AIOP
	rts

dst_dis:
	bset.b	#signan_bit,FPTEMP_HI(a6) ;set SNAN bit in sop 
	fmove.l	d1,fpcr			;restore user's rmode/prec
	fmove.x FPTEMP(a6),fp0		;load non-sign. nan 
	or.l	#snaniop_mask,USER_FPSR(a6) ;set NAN, SNAN, AIOP
	rts

;
;	SRC_NAN
;
; Determine if the source nan is signalling or non-signalling,
; and set the FPSR bits accordingly.  See the MC68040 User's Manual 
; section 3.2.2.5 NOT-A-NUMBERS.
;
src_nan:
	btst.b	#sign_bit,ETEMP_EX(a6) ;test sign of nan
	beq.s	.src_pos			;if clr, it was positive
	bset.b	#neg_bit,FPSR_CC(a6)	;set N bit
.src_pos:
	btst.b	#signan_bit,ETEMP_HI(a6) ;check if signalling 
	beq.s	.src_snan		;branch if signalling
	fmove.l	d1,fpcr			;restore user's rmode/prec
	fmove.x ETEMP(a6),fp0		;return the non-signalling nan
	rts	

.src_snan:
	btst.b	#snan_bit,FPCR_ENABLE(a6) ;check if trap enabled 
	beq.s	src_dis			;branch if disabled
	bset.b	#signan_bit,ETEMP_HI(a6) ;set SNAN bit in sop 
	or.b	#norm_tag,DTAG(a6)	;set up dtag for norm
	or.b	#nan_tag,STAG(a6)	;set up stag for nan
	st	STORE_FLG(a6)		;do not store a result
	or.l	#snaniop_mask,USER_FPSR(a6) ;set NAN, SNAN, AIOP
	rts

src_dis:
	bset.b	#signan_bit,ETEMP_HI(a6) ;set SNAN bit in sop 
	fmove.l	d1,fpcr			;restore user's rmode/prec
	fmove.x ETEMP(a6),fp0		;load non-sign. nan 
	or.l	#snaniop_mask,USER_FPSR(a6) ;set NAN, SNAN, AIOP
	rts

;
; For all functions that have a denormalized input and that f(x)=x,
; this is the entry point
;
t_extdnrm:
	or.l	#unfinx_mask,USER_FPSR(a6)
;					;set UNFL, INEX2, AUNFL, AINEX
	bra.s	xdnrm_con
;
; Entry point for scale with extended denorm.  The function does
; not set inex2, aunfl, or ainex.  
;
t_resdnrm:
	or.l	#unfl_mask,USER_FPSR(a6)

xdnrm_con:
	btst.b	#unfl_bit,FPCR_ENABLE(a6)
	beq.s	xdnrm_dis

;
; If exceptions are enabled, the additional task of setting up WBTEMP
; is needed so that when the underflow exception handler is entered,
; the user perceives no difference between what the 040 provides vs.
; what the FPSP provides.
;
xdnrm_ena:
	move.l	a0,-(a7)

	move.l	LOCAL_EX(a0),FP_SCR1(a6)
	move.l	LOCAL_HI(a0),FP_SCR1+4(a6)
	move.l	LOCAL_LO(a0),FP_SCR1+8(a6)

	lea	FP_SCR1(a6),a0

	bclr.b	#sign_bit,LOCAL_EX(a0)
	sne	LOCAL_SGN(a0)		;convert to internal ext format
	tst.w	LOCAL_EX(a0)		;check if input is denorm
	beq.s	xdnrm_dn		;if so, skip nrm_set
	bsr	nrm_set			;normalize the result (exponent
;					;will be negative
xdnrm_dn:
	bclr.b	#sign_bit,LOCAL_EX(a0)	;take off false sign
	bfclr	LOCAL_SGN(a0){0:8}	;change back to IEEE ext format
	beq.s	xdep
	bset.b	#sign_bit,LOCAL_EX(a0)
xdep:	
	bfclr	STAG(a6){5:3}		;clear wbtm66,wbtm1,wbtm0
	bset.b	#wbtemp15_bit,WB_BYTE(a6) ;set wbtemp15
	bclr.b	#sticky_bit,STICKY(a6)	;clear sticky bit
	bclr.b	#E1,E_BYTE(a6)
	move.l	(a7)+,a0
xdnrm_dis:
	bfextu	FPCR_MODE(a6){0:2},d0	;get round precision
	bne.s	not_ext_			;if not round extended, store
;					;IEEE defaults
is_ext:
	btst.b	#sign_bit,LOCAL_EX(a0)
	beq.s	xdnrm_store

	bset.b	#neg_bit,FPSR_CC(a6)	;set N bit in FPSR_CC

	bra.s	xdnrm_store

not_ext_:
	bclr.b	#sign_bit,LOCAL_EX(a0)
	sne	LOCAL_SGN(a0)		;convert to internal ext format
	bsr	unf_sub			;returns IEEE result pointed by
;					;a0; sets FPSR_CC accordingly
	bfclr	LOCAL_SGN(a0){0:8}	;convert back to IEEE ext format
	beq.s	xdnrm_store
	bset.b	#sign_bit,LOCAL_EX(a0)
xdnrm_store:
	fmovem.x (a0),fp0-fp0		;store result in fp0
	rts

;
; This subroutine is used for dyadic operations that use an extended
; denorm within the kernel. The approach used is to capture the frame,
; fix/restore.
;
	;|.global	t_avoid_unsupp
t_avoid_unsupp:
	link	a2,#-LOCAL_SIZE		;so that a2 fpsp.h negative 
;					;offsets may be used
	fsave	-(a7)
	tst.b	1(a7)			;check if idle, exit if so
	beq	idle_end
	btst.b	#E1,E_BYTE(a2)		;check for an E1 exception if
;					;enabled, there is an unsupp
	beq	end_avun		;else, exit
	btst.b	#7,DTAG(a2)		;check for denorm destination
	beq.s	src_den			;else, must be a source denorm
;
; handle destination denorm
;
	lea	FPTEMP(a2),a0
	btst.b	#sign_bit,LOCAL_EX(a0)
	sne	LOCAL_SGN(a0)		;convert to internal ext format
	bclr.b	#7,DTAG(a2)		;set DTAG to norm
	bsr	nrm_set			;normalize result, exponent
;					;will become negative
	bclr.b	#sign_bit,LOCAL_EX(a0)	;get rid of fake sign
	bfclr	LOCAL_SGN(a0){0:8}	;convert back to IEEE ext format
	beq.s	ck_src_den		;check if source is also denorm
	bset.b	#sign_bit,LOCAL_EX(a0)
ck_src_den:
	btst.b	#7,STAG(a2)
	beq.s	end_avun
src_den:
	lea	ETEMP(a2),a0
	btst.b	#sign_bit,LOCAL_EX(a0)
	sne	LOCAL_SGN(a0)		;convert to internal ext format
	bclr.b	#7,STAG(a2)		;set STAG to norm
	bsr	nrm_set			;normalize result, exponent
;					;will become negative
	bclr.b	#sign_bit,LOCAL_EX(a0)	;get rid of fake sign
	bfclr	LOCAL_SGN(a0){0:8}	;convert back to IEEE ext format
	beq.s	den_com
	bset.b	#sign_bit,LOCAL_EX(a0)
den_com:
	move.b	#$fe,CU_SAVEPC(a2)	;set continue frame
	clr.w	NMNEXC(a2)		;clear NMNEXC
	bclr.b	#E1,E_BYTE(a2)
;	fmove.l	FPSR,FPSR_SHADOW(a2)
;	bset.b	#SFLAG,E_BYTE(a2)
;	bset.b	#XFLAG,T_BYTE(a2)
end_avun:
	frestore (a7)+
	unlk	a2
	rts
idle_end:
	add.l	#4,a7
	unlk	a2
	rts
	;end
;
;	res_func.sa 3.9 7/29/91
;
; Normalizes denormalized numbers if necessary and updates the
; stack frame.  The function is then restored back into the
; machine and the 040 completes the operation.  This routine
; is only used by the unsupported data type/format handler.
; (Exception vector 55).
;
; For packed move out (fmove.p fpm,<ea>) the operation is
; completed here; data is packed and moved to user memory. 
; The stack is restored to the 040 only in the case of a
; reportable exception in the conversion.
;
;
;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

RES_FUNC:    ;idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	

sp_bnds:	dc.w	$3f81,$407e
		dc.w	$3f6a,$0000
dp_bnds:	dc.w	$3c01,$43fe
		dc.w	$3bcd,$0000

	;xref	mem_write
	;xref	bindec
	;xref	get_fline
	;xref	round
	;xref	denorm
	;xref	dest_ext
	;xref	dest_dbl
	;xref	dest_sgl
	;xref	unf_sub
	;xref	nrm_set
	;xref	dnrm_lp
	;xref	ovf_res
	;xref	reg_dest
	;xref	t_ovfl
	;xref	t_unfl

	;|.global	res_func
	;|.global 	p_move

res_func:
	clr.b	DNRM_FLG(a6)
	clr.b	RES_FLG(a6)
	clr.b	CU_ONLY(a6)
	tst.b	DY_MO_FLG(a6)
	beq.s	monadic
dyadic:
	btst.b	#7,DTAG(a6)	;if dop = norm=000, zero=001,
;				;inf=010 or nan=011
	beq.s	monadic		;then branch
;				;else denorm
; HANDLE DESTINATION DENORM HERE
;				;set dtag to norm
;				;write the tag & fpte15 to the fstack
	lea.l	FPTEMP(a6),a0

	bclr.b	#sign_bit,LOCAL_EX(a0)
	sne	LOCAL_SGN(a0)

	bsr	nrm_set		;normalize number (exp will go negative)
	bclr.b	#sign_bit,LOCAL_EX(a0) ;get rid of false sign
	bfclr	LOCAL_SGN(a0){0:8}	;change back to IEEE ext format
	beq.s	dpos
	bset.b	#sign_bit,LOCAL_EX(a0)
dpos:
	bfclr	DTAG(a6){0:4}	;set tag to normalized, FPTE15 = 0
	bset.b	#4,DTAG(a6)	;set FPTE15
	or.b	#$0f,DNRM_FLG(a6)
monadic:
	lea.l	ETEMP(a6),a0
	btst.b	#direction_bit,CMDREG1B(a6)	;check direction
	bne	opclass3			;it is a mv out
;
; At this point, only opclass 0 and 2 possible
;
	btst.b	#7,STAG(a6)	;if sop = norm=000, zero=001,
;				;inf=010 or nan=011
	bne	mon_dnrm	;else denorm
	tst.b	DY_MO_FLG(a6)	;all cases of dyadic instructions would
	bne	normal		;require normalization of denorm

; At this point:
;	monadic instructions:	fabs  = $18  fneg   = $1a  ftst   = $3a
;				fmove = $00  fsmove = $40  fdmove = $44
;				fsqrt = $05* fssqrt = $41  fdsqrt = $45
;				(*fsqrt reencoded to $05)
;
	move.w	CMDREG1B(a6),d0	;get command register
	andi.l	#$7f,d0			;strip to only command word
;
; At this point, fabs, fneg, fsmove, fdmove, ftst, fsqrt, fssqrt, and 
; fdsqrt are possible.
; For cases fabs, fneg, fsmove, and fdmove goto spos (do not normalize)
; For cases fsqrt, fssqrt, and fdsqrt goto nrm_src (do normalize)
;
	btst.l	#0,d0
	bne	normal			;weed out fsqrt instructions
;
; cu_norm handles fmove in instructions with normalized inputs.
; The routine round is used to correctly round the input for the
; destination precision and mode.
;
cu_norm:
	st	CU_ONLY(a6)		;set cu-only inst flag
	move.w	CMDREG1B(a6),d0
	andi.b	#$3b,d0		;isolate bits to select inst
	tst.b	d0
	beq.l	cu_nmove	;if zero, it is an fmove
	cmpi.b	#$18,d0
	beq.l	cu_nabs		;if $18, it is fabs
	cmpi.b	#$1a,d0
	beq.l	cu_nneg		;if $1a, it is fneg
;
; Inst is ftst.  Check the source operand and set the cc's accordingly.
; No write is done, so simply rts.
;
cu_ntst:
	move.w	LOCAL_EX(a0),d0
	bclr.l	#15,d0
	sne	LOCAL_SGN(a0)
	beq.s	cu_ntpo
	or.l	#neg_mask,USER_FPSR(a6) ;set N
cu_ntpo:
	cmpi.w	#$7fff,d0	;test for inf/nan
	bne.s	cu_ntcz
	tst.l	LOCAL_HI(a0)
	bne.s	cu_ntn
	tst.l	LOCAL_LO(a0)
	bne.s	cu_ntn
	or.l	#inf_mask,USER_FPSR(a6)
	rts
cu_ntn:
	or.l	#nan_mask,USER_FPSR(a6)
	move.l	ETEMP_EX(a6),FPTEMP_EX(a6)	;set up fptemp sign for 
;						;snan handler

	rts
cu_ntcz:
	tst.l	LOCAL_HI(a0)
	bne.l	cu_ntsx
	tst.l	LOCAL_LO(a0)
	bne.l	cu_ntsx
	or.l	#z_mask,USER_FPSR(a6)
cu_ntsx:
	rts
;
; Inst is fabs.  Execute the absolute value function on the input.
; Branch to the fmove code.  If the operand is NaN, do nothing.
;
cu_nabs:
	move.b	STAG(a6),d0
	btst.l	#5,d0			;test for NaN or zero
	bne	wr_etemp		;if either, simply write it
	bclr.b	#7,LOCAL_EX(a0)		;do abs
	bra.s	cu_nmove		;fmove code will finish
;
; Inst is fneg.  Execute the negate value function on the input.
; Fall though to the fmove code.  If the operand is NaN, do nothing.
;
cu_nneg:
	move.b	STAG(a6),d0
	btst.l	#5,d0			;test for NaN or zero
	bne	wr_etemp		;if either, simply write it
	bchg.b	#7,LOCAL_EX(a0)		;do neg
;
; Inst is fmove.  This code also handles all result writes.
; If bit 2 is set, round is forced to double.  If it is clear,
; and bit 6 is set, round is forced to single.  If both are clear,
; the round precision is found in the fpcr.  If the rounding precision
; is double or single, round the result before the write.
;
cu_nmove:
	move.b	STAG(a6),d0
	andi.b	#$e0,d0			;isolate stag bits
	bne	wr_etemp		;if not norm, simply write it
	btst.b	#2,CMDREG1B+1(a6)	;check for rd
	bne	cu_nmrd
	btst.b	#6,CMDREG1B+1(a6)	;check for rs
	bne	cu_nmrs
;
; The move or operation is not with forced precision.  Test for
; nan or inf as the input; if so, simply write it to FPn.  Use the
; FPCR_MODE byte to get rounding on norms and zeros.
;
cu_nmnr:
	bfextu	FPCR_MODE(a6){0:2},d0
	tst.b	d0			;check for extended
	beq	cu_wrexn		;if so, just write result
	cmpi.b	#1,d0			;check for single
	beq	cu_nmrs			;fall through to double
;
; The move is fdmove or round precision is double.
;
cu_nmrd:
	move.l	#2,d0			;set up the size for denorm
	move.w	LOCAL_EX(a0),d1		;compare exponent to double threshold
	and.w	#$7fff,d1	
	cmp.w	#$3c01,d1
	bls	cu_nunfl
	bfextu	FPCR_MODE(a6){2:2},d1	;get rmode
	or.l	#$00020000,d1		;or in rprec (double)
	clr.l	d0			;clear g,r,s for round
	bclr.b	#sign_bit,LOCAL_EX(a0)	;convert to internal format
	sne	LOCAL_SGN(a0)
	bsr.l	round
	bfclr	LOCAL_SGN(a0){0:8}
	beq.s	cu_nmrdc
	bset.b	#sign_bit,LOCAL_EX(a0)
cu_nmrdc:
	move.w	LOCAL_EX(a0),d1		;check for overflow
	and.w	#$7fff,d1
	cmp.w	#$43ff,d1
	bge	cu_novfl		;take care of overflow case
	bra	cu_wrexn
;
; The move is fsmove or round precision is single.
;
cu_nmrs:
	move.l	#1,d0
	move.w	LOCAL_EX(a0),d1
	and.w	#$7fff,d1
	cmp.w	#$3f81,d1
	bls	cu_nunfl
	bfextu	FPCR_MODE(a6){2:2},d1
	or.l	#$00010000,d1
	clr.l	d0
	bclr.b	#sign_bit,LOCAL_EX(a0)
	sne	LOCAL_SGN(a0)
	bsr.l	round
	bfclr	LOCAL_SGN(a0){0:8}
	beq.s	cu_nmrsc
	bset.b	#sign_bit,LOCAL_EX(a0)
cu_nmrsc:
	move.w	LOCAL_EX(a0),d1
	and.w	#$7FFF,d1
	cmp.w	#$407f,d1
	blt	cu_wrexn
;
; The operand is above precision boundaries.  Use t_ovfl to
; generate the correct value.
;
cu_novfl:
	bsr	t_ovfl
	bra	cu_wrexn
;
; The operand is below precision boundaries.  Use denorm to
; generate the correct value.
;
cu_nunfl:
	bclr.b	#sign_bit,LOCAL_EX(a0)
	sne	LOCAL_SGN(a0)
	bsr	denorm
	bfclr	LOCAL_SGN(a0){0:8}	;change back to IEEE ext format
	beq.s	cu_nucont
	bset.b	#sign_bit,LOCAL_EX(a0)
cu_nucont:
	bfextu	FPCR_MODE(a6){2:2},d1
	btst.b	#2,CMDREG1B+1(a6)	;check for rd
	bne	inst_d
	btst.b	#6,CMDREG1B+1(a6)	;check for rs
	bne	inst_s
	swap	d1
	move.b	FPCR_MODE(a6),d1
	lsr.b	#6,d1
	swap	d1
	bra	inst_sd
inst_d:
	or.l	#$00020000,d1
	bra	inst_sd
inst_s:
	or.l	#$00010000,d1
inst_sd:
	bclr.b	#sign_bit,LOCAL_EX(a0)
	sne	LOCAL_SGN(a0)
	bsr.l	round
	bfclr	LOCAL_SGN(a0){0:8}
	beq.s	cu_nuflp
	bset.b	#sign_bit,LOCAL_EX(a0)
cu_nuflp:
	btst.b	#inex2_bit,FPSR_EXCEPT(a6)
	beq.s	cu_nuninx
	or.l	#aunfl_mask,USER_FPSR(a6) ;if the round was inex, set AUNFL
cu_nuninx:
	tst.l	LOCAL_HI(a0)		;test for zero
	bne.s	cu_nunzro
	tst.l	LOCAL_LO(a0)
	bne.s	cu_nunzro
;
; The mantissa is zero from the denorm loop.  Check sign and rmode
; to see if rounding should have occurred which would leave the lsb.
;
	move.l	USER_FPCR(a6),d0
	andi.l	#$30,d0		;isolate rmode
	cmpi.l	#$20,d0
	blt.s	cu_nzro
	bne.s	cu_nrp
cu_nrm:
	tst.w	LOCAL_EX(a0)	;if positive, set lsb
	bge.s	cu_nzro
	btst.b	#7,FPCR_MODE(a6) ;check for double
	beq.s	cu_nincs
	bra.s	cu_nincd
cu_nrp:
	tst.w	LOCAL_EX(a0)	;if positive, set lsb
	blt.s	cu_nzro
	btst.b	#7,FPCR_MODE(a6) ;check for double
	beq.s	cu_nincs
cu_nincd:
	or.l	#$800,LOCAL_LO(a0) ;inc for double
	bra	cu_nunzro
cu_nincs:
	or.l	#$100,LOCAL_HI(a0) ;inc for single
	bra	cu_nunzro
cu_nzro:
	or.l	#z_mask,USER_FPSR(a6)
	move.b	STAG(a6),d0
	andi.b	#$e0,d0
	cmpi.b	#$40,d0		;check if input was tagged zero
	beq.s	cu_numv
cu_nunzro:
	or.l	#unfl_mask,USER_FPSR(a6) ;set unfl
cu_numv:
	move.l	(a0),ETEMP(a6)
	move.l	4(a0),ETEMP_HI(a6)
	move.l	8(a0),ETEMP_LO(a6)
;
; Write the result to memory, setting the fpsr cc bits.  NaN and Inf
; bypass cu_wrexn.
;
cu_wrexn:
	tst.w	LOCAL_EX(a0)		;test for zero
	beq.s	cu_wrzero
	cmp.w	#$8000,LOCAL_EX(a0)	;test for zero
	bne.s	cu_wreon
cu_wrzero:
	or.l	#z_mask,USER_FPSR(a6)	;set Z bit
cu_wreon:
	tst.w	LOCAL_EX(a0)
	bpl	wr_etemp
	or.l	#neg_mask,USER_FPSR(a6)
	bra	wr_etemp

;
; HANDLE SOURCE DENORM HERE
;
;				;clear denorm stag to norm
;				;write the new tag & ete15 to the fstack
mon_dnrm:
;
; At this point, check for the cases in which normalizing the 
; denorm produces incorrect results.
;
	tst.b	DY_MO_FLG(a6)	;all cases of dyadic instructions would
	bne.s	nrm_src		;require normalization of denorm

; At this point:
;	monadic instructions:	fabs  = $18  fneg   = $1a  ftst   = $3a
;				fmove = $00  fsmove = $40  fdmove = $44
;				fsqrt = $05* fssqrt = $41  fdsqrt = $45
;				(*fsqrt reencoded to $05)
;
	move.w	CMDREG1B(a6),d0	;get command register
	andi.l	#$7f,d0			;strip to only command word
;
; At this point, fabs, fneg, fsmove, fdmove, ftst, fsqrt, fssqrt, and 
; fdsqrt are possible.
; For cases fabs, fneg, fsmove, and fdmove goto spos (do not normalize)
; For cases fsqrt, fssqrt, and fdsqrt goto nrm_src (do normalize)
;
	btst.l	#0,d0
	bne.s	nrm_src		;weed out fsqrt instructions
	st	CU_ONLY(a6)	;set cu-only inst flag
	bra	cu_dnrm		;fmove, fabs, fneg, ftst 
;				;cases go to cu_dnrm
nrm_src:
	bclr.b	#sign_bit,LOCAL_EX(a0)
	sne	LOCAL_SGN(a0)
	bsr	nrm_set		;normalize number (exponent will go 
;				; negative)
	bclr.b	#sign_bit,LOCAL_EX(a0) ;get rid of false sign

	bfclr	LOCAL_SGN(a0){0:8}	;change back to IEEE ext format
	beq.s	spos
	bset.b	#sign_bit,LOCAL_EX(a0)
spos:
	bfclr	STAG(a6){0:4}	;set tag to normalized, FPTE15 = 0
	bset.b	#4,STAG(a6)	;set ETE15
	or.b	#$f0,DNRM_FLG(a6)
normal:
	tst.b	DNRM_FLG(a6)	;check if any of the ops were denorms
	bne	ck_wrap		;if so, check if it is a potential
;				;wrap-around case
fix_stk:
	move.b	#$fe,CU_SAVEPC(a6)
	bclr.b	#E1,E_BYTE(a6)

	clr.w	NMNEXC(a6)

	st	RES_FLG(a6)	;indicate that a restore is needed
	rts

;
; cu_dnrm handles all cu-only instructions (fmove, fabs, fneg, and
; ftst) completely in software without an frestore to the 040. 
;
cu_dnrm:
	st	CU_ONLY(a6)
	move.w	CMDREG1B(a6),d0
	andi.b	#$3b,d0		;isolate bits to select inst
	tst.b	d0
	beq.l	cu_dmove	;if zero, it is an fmove
	cmpi.b	#$18,d0
	beq.l	cu_dabs		;if $18, it is fabs
	cmpi.b	#$1a,d0
	beq.l	cu_dneg		;if $1a, it is fneg
;
; Inst is ftst.  Check the source operand and set the cc's accordingly.
; No write is done, so simply rts.
;
cu_dtst:
	move.w	LOCAL_EX(a0),d0
	bclr.l	#15,d0
	sne	LOCAL_SGN(a0)
	beq.s	cu_dtpo
	or.l	#neg_mask,USER_FPSR(a6) ;set N
cu_dtpo:
	cmpi.w	#$7fff,d0	;test for inf/nan
	bne.s	cu_dtcz
	tst.l	LOCAL_HI(a0)
	bne.s	cu_dtn
	tst.l	LOCAL_LO(a0)
	bne.s	cu_dtn
	or.l	#inf_mask,USER_FPSR(a6)
	rts
cu_dtn:
	or.l	#nan_mask,USER_FPSR(a6)
	move.l	ETEMP_EX(a6),FPTEMP_EX(a6)	;set up fptemp sign for 
;						;snan handler
	rts
cu_dtcz:
	tst.l	LOCAL_HI(a0)
	bne.l	cu_dtsx
	tst.l	LOCAL_LO(a0)
	bne.l	cu_dtsx
	or.l	#z_mask,USER_FPSR(a6)
cu_dtsx:
	rts
;
; Inst is fabs.  Execute the absolute value function on the input.
; Branch to the fmove code.
;
cu_dabs:
	bclr.b	#7,LOCAL_EX(a0)		;do abs
	bra.s	cu_dmove		;fmove code will finish
;
; Inst is fneg.  Execute the negate value function on the input.
; Fall though to the fmove code.
;
cu_dneg:
	bchg.b	#7,LOCAL_EX(a0)		;do neg
;
; Inst is fmove.  This code also handles all result writes.
; If bit 2 is set, round is forced to double.  If it is clear,
; and bit 6 is set, round is forced to single.  If both are clear,
; the round precision is found in the fpcr.  If the rounding precision
; is double or single, the result is zero, and the mode is checked
; to determine if the lsb of the result should be set.
;
cu_dmove:
	btst.b	#2,CMDREG1B+1(a6)	;check for rd
	bne	cu_dmrd
	btst.b	#6,CMDREG1B+1(a6)	;check for rs
	bne	cu_dmrs
;
; The move or operation is not with forced precision.  Use the
; FPCR_MODE byte to get rounding.
;
cu_dmnr:
	bfextu	FPCR_MODE(a6){0:2},d0
	tst.b	d0			;check for extended
	beq	cu_wrexd		;if so, just write result
	cmpi.b	#1,d0			;check for single
	beq	cu_dmrs			;fall through to double
;
; The move is fdmove or round precision is double.  Result is zero.
; Check rmode for rp or rm and set lsb accordingly.
;
cu_dmrd:
	bfextu	FPCR_MODE(a6){2:2},d1	;get rmode
	tst.w	LOCAL_EX(a0)		;check sign
	blt.s	cu_dmdn
	cmpi.b	#3,d1			;check for rp
	bne	cu_dpd			;load double pos zero
	bra	cu_dpdr			;load double pos zero w/lsb
cu_dmdn:
	cmpi.b	#2,d1			;check for rm
	bne	cu_dnd			;load double neg zero
	bra	cu_dndr			;load double neg zero w/lsb
;
; The move is fsmove or round precision is single.  Result is zero.
; Check for rp or rm and set lsb accordingly.
;
cu_dmrs:
	bfextu	FPCR_MODE(a6){2:2},d1	;get rmode
	tst.w	LOCAL_EX(a0)		;check sign
	blt.s	cu_dmsn
	cmpi.b	#3,d1			;check for rp
	bne	cu_spd			;load single pos zero
	bra	cu_spdr			;load single pos zero w/lsb
cu_dmsn:
	cmpi.b	#2,d1			;check for rm
	bne	cu_snd			;load single neg zero
	bra	cu_sndr			;load single neg zero w/lsb
;
; The precision is extended, so the result in etemp is correct.
; Simply set unfl (not inex2 or aunfl) and write the result to 
; the correct fp register.
cu_wrexd:
	or.l	#unfl_mask,USER_FPSR(a6)
	tst.w	LOCAL_EX(a0)
	beq	wr_etemp
	or.l	#neg_mask,USER_FPSR(a6)
	bra	wr_etemp
;
; These routines write +/- zero in double format.  The routines
; cu_dpdr and cu_dndr set the double lsb.
;
cu_dpd:
	move.l	#$3c010000,LOCAL_EX(a0)	;force pos double zero
	clr.l	LOCAL_HI(a0)
	clr.l	LOCAL_LO(a0)
	or.l	#z_mask,USER_FPSR(a6)
	or.l	#unfinx_mask,USER_FPSR(a6)
	bra	wr_etemp
cu_dpdr:
	move.l	#$3c010000,LOCAL_EX(a0)	;force pos double zero
	clr.l	LOCAL_HI(a0)
	move.l	#$800,LOCAL_LO(a0)	;with lsb set
	or.l	#unfinx_mask,USER_FPSR(a6)
	bra	wr_etemp
cu_dnd:
	move.l	#$bc010000,LOCAL_EX(a0)	;force pos double zero
	clr.l	LOCAL_HI(a0)
	clr.l	LOCAL_LO(a0)
	or.l	#z_mask,USER_FPSR(a6)
	or.l	#neg_mask,USER_FPSR(a6)
	or.l	#unfinx_mask,USER_FPSR(a6)
	bra	wr_etemp
cu_dndr:
	move.l	#$bc010000,LOCAL_EX(a0)	;force pos double zero
	clr.l	LOCAL_HI(a0)
	move.l	#$800,LOCAL_LO(a0)	;with lsb set
	or.l	#neg_mask,USER_FPSR(a6)
	or.l	#unfinx_mask,USER_FPSR(a6)
	bra	wr_etemp
;
; These routines write +/- zero in single format.  The routines
; cu_dpdr and cu_dndr set the single lsb.
;
cu_spd:
	move.l	#$3f810000,LOCAL_EX(a0)	;force pos single zero
	clr.l	LOCAL_HI(a0)
	clr.l	LOCAL_LO(a0)
	or.l	#z_mask,USER_FPSR(a6)
	or.l	#unfinx_mask,USER_FPSR(a6)
	bra	wr_etemp
cu_spdr:
	move.l	#$3f810000,LOCAL_EX(a0)	;force pos single zero
	move.l	#$100,LOCAL_HI(a0)	;with lsb set
	clr.l	LOCAL_LO(a0)
	or.l	#unfinx_mask,USER_FPSR(a6)
	bra	wr_etemp
cu_snd:
	move.l	#$bf810000,LOCAL_EX(a0)	;force pos single zero
	clr.l	LOCAL_HI(a0)
	clr.l	LOCAL_LO(a0)
	or.l	#z_mask,USER_FPSR(a6)
	or.l	#neg_mask,USER_FPSR(a6)
	or.l	#unfinx_mask,USER_FPSR(a6)
	bra	wr_etemp
cu_sndr:
	move.l	#$bf810000,LOCAL_EX(a0)	;force pos single zero
	move.l	#$100,LOCAL_HI(a0)	;with lsb set
	clr.l	LOCAL_LO(a0)
	or.l	#neg_mask,USER_FPSR(a6)
	or.l	#unfinx_mask,USER_FPSR(a6)
	bra	wr_etemp
	
;
; This code checks for 16-bit overflow conditions on dyadic
; operations which are not restorable into the floating-point
; unit and must be completed in software.  Basically, this
; condition exists with a very large norm and a denorm.  One
; of the operands must be denormalized to enter this code.
;
; Flags used:
;	DY_MO_FLG contains 0 for monadic op, $ff for dyadic
;	DNRM_FLG contains $00 for neither op denormalized
;	                  $0f for the destination op denormalized
;	                  $f0 for the source op denormalized
;	                  $ff for both ops denormalized
;
; The wrap-around condition occurs for add, sub, div, and cmp
; when 
;
;	abs(dest_exp - src_exp) >= $8000
;
; and for mul when
;
;	(dest_exp + src_exp) < $0
;
; we must process the operation here if this case is true.
;
; The rts following the frcfpn routine is the exit from res_func
; for this condition.  The restore flag (RES_FLG) is left clear.
; No frestore is done unless an exception is to be reported.
;
; For fadd: 
;	if(sign_of(dest) != sign_of(src))
;		replace exponent of src with $3fff (keep sign)
;		use fpu to perform dest+new_src (user's rmode and X)
;		clr sticky
;	else
;		set sticky
;	call round with user's precision and mode
;	move result to fpn and wbtemp
;
; For fsub:
;	if(sign_of(dest) == sign_of(src))
;		replace exponent of src with $3fff (keep sign)
;		use fpu to perform dest+new_src (user's rmode and X)
;		clr sticky
;	else
;		set sticky
;	call round with user's precision and mode
;	move result to fpn and wbtemp
;
; For fdiv/fsgldiv:
;	if(both operands are denorm)
;		restore_to_fpu;
;	if(dest is norm)
;		force_ovf;
;	else(dest is denorm)
;		force_unf:
;
; For fcmp:
;	if(dest is norm)
;		N = sign_of(dest);
;	else(dest is denorm)
;		N = sign_of(src);
;
; For fmul:
;	if(both operands are denorm)
;		force_unf;
;	if((dest_exp + src_exp) < 0)
;		force_unf:
;	else
;		restore_to_fpu;
;
; local equates:
addcode = $22
subcode = $28
mulcode = $23
divcode = $20
cmpcode = $38
ck_wrap:
	; tstb	DY_MO_FLG(a6)	;check for fsqrt
	beq	fix_stk		;if zero, it is fsqrt
	move.w	CMDREG1B(a6),d0
	andi.w	#$3b,d0		;strip to command bits
	cmpi.w	#addcode,d0
	beq	wrap_add
	cmpi.w	#subcode,d0
	beq	wrap_sub
	cmpi.w	#mulcode,d0
	beq	wrap_mul
	cmpi.w	#cmpcode,d0
	beq	wrap_cmp
;
; Inst is fdiv.  
;
wrap_div:
	cmp.b	#$ff,DNRM_FLG(a6) ;if both ops denorm, 
	beq	fix_stk		 ;restore to fpu
;
; One of the ops is denormalized.  Test for wrap condition
; and force the result.
;
	cmp.b	#$0f,DNRM_FLG(a6) ;check for dest denorm
	bne.s	div_srcd
div_destd:
	bsr.l	ckinf_ns
	bne	fix_stk
	bfextu	ETEMP_EX(a6){1:15},d0	;get src exp (always pos)
	bfexts	FPTEMP_EX(a6){1:15},d1	;get dest exp (always neg)
	sub.l	d1,d0			;subtract dest from src
	cmp.l	#$7fff,d0
	blt	fix_stk			;if less, not wrap case
	clr.b	WBTEMP_SGN(a6)
	move.w	ETEMP_EX(a6),d0		;find the sign of the result
	move.w	FPTEMP_EX(a6),d1
	eor.w	d1,d0
	andi.w	#$8000,d0
	beq	force_unf
	st	WBTEMP_SGN(a6)
	bra	force_unf

ckinf_ns:
	move.b	STAG(a6),d0		;check source tag for inf or nan
	bra	ck_in_com
ckinf_nd:
	move.b	DTAG(a6),d0		;check destination tag for inf or nan
ck_in_com:	
	andi.b	#$60,d0			;isolate tag bits
	cmp.b	#$40,d0			;is it inf?
	beq	nan_or_inf		;not wrap case
	cmp.b	#$60,d0			;is it nan?
	beq	nan_or_inf		;yes, not wrap case?
	cmp.b	#$20,d0			;is it a zero?
	beq	nan_or_inf		;yes
	clr.l	d0
	rts				;then ; it is either a zero of norm,
;					;check wrap case
nan_or_inf:
	moveq.l	#-1,d0
	rts



div_srcd:
	bsr.l	ckinf_nd
	bne	fix_stk
	bfextu	FPTEMP_EX(a6){1:15},d0	;get dest exp (always pos)
	bfexts	ETEMP_EX(a6){1:15},d1	;get src exp (always neg)
	sub.l	d1,d0			;subtract src from dest
	cmp.l	#$8000,d0
	blt	fix_stk			;if less, not wrap case
	clr.b	WBTEMP_SGN(a6)
	move.w	ETEMP_EX(a6),d0		;find the sign of the result
	move.w	FPTEMP_EX(a6),d1
	eor.w	d1,d0
	andi.w	#$8000,d0
	beq.s	force_ovf
	st	WBTEMP_SGN(a6)
;
; This code handles the case of the instruction resulting in 
; an overflow condition.
;
force_ovf:
	bclr.b	#E1,E_BYTE(a6)
	or.l	#ovfl_inx_mask,USER_FPSR(a6)
	clr.w	NMNEXC(a6)
	lea.l	WBTEMP(a6),a0		;point a0 to memory location
	move.w	CMDREG1B(a6),d0
	btst.l	#6,d0			;test for forced precision
	beq.s	frcovf_fpcr
	btst.l	#2,d0			;check for double
	bne.s	frcovf_dbl
	move.l	#$1,d0			;inst is forced single
	bra.s	frcovf_rnd
frcovf_dbl:
	move.l	#$2,d0			;inst is forced double
	bra.s	frcovf_rnd
frcovf_fpcr:
	bfextu	FPCR_MODE(a6){0:2},d0	;inst not forced - use fpcr prec
frcovf_rnd:

; The 881/882 does not set inex2 for the following case, so the 
; line is commented out to be compatible with 881/882
;	tst.b	d0
;	beq.b	frcovf_x
;	or.l	#inex2_mask,USER_FPSR(a6) ;if prec is s or d, set inex2

;frcovf_x:
	bsr.l	ovf_res			;get correct result based on
;					;round precision/mode.  This 
;					;sets FPSR_CC correctly
;					;returns in external format
	bfclr	WBTEMP_SGN(a6){0:8}
	beq	frcfpn
	bset.b	#sign_bit,WBTEMP_EX(a6)
	bra	frcfpn
;
; Inst is fadd.
;
wrap_add:
	cmp.b	#$ff,DNRM_FLG(a6) ;if both ops denorm, 
	beq	fix_stk		 ;restore to fpu
;
; One of the ops is denormalized.  Test for wrap condition
; and complete the instruction.
;
	cmp.b	#$0f,DNRM_FLG(a6) ;check for dest denorm
	bne.s	add_srcd
add_destd:
	bsr.l	ckinf_ns
	bne	fix_stk
	bfextu	ETEMP_EX(a6){1:15},d0	;get src exp (always pos)
	bfexts	FPTEMP_EX(a6){1:15},d1	;get dest exp (always neg)
	sub.l	d1,d0			;subtract dest from src
	cmp.l	#$8000,d0
	blt	fix_stk			;if less, not wrap case
	bra	add_wrap
add_srcd:
	bsr.l	ckinf_nd
	bne	fix_stk
	bfextu	FPTEMP_EX(a6){1:15},d0	;get dest exp (always pos)
	bfexts	ETEMP_EX(a6){1:15},d1	;get src exp (always neg)
	sub.l	d1,d0			;subtract src from dest
	cmp.l	#$8000,d0
	blt	fix_stk			;if less, not wrap case
;
; Check the signs of the operands.  If they are unlike, the fpu
; can be used to add the norm and 1.0 with the sign of the
; denorm and it will correctly generate the result in extended
; precision.  We can then call round with no sticky and the result
; will be correct for the user's rounding mode and precision.  If
; the signs are the same, we call round with the sticky bit set
; and the result will be correct for the user's rounding mode and
; precision.
;
add_wrap:
	move.w	ETEMP_EX(a6),d0
	move.w	FPTEMP_EX(a6),d1
	eor.w	d1,d0
	andi.w	#$8000,d0
	beq	add_same
;
; The signs are unlike.
;
	cmp.b	#$0f,DNRM_FLG(a6) ;is dest the denorm?
	bne.s	add_u_srcd
	move.w	FPTEMP_EX(a6),d0
	andi.w	#$8000,d0
	or.w	#$3fff,d0	;force the exponent to +/- 1
	move.w	d0,FPTEMP_EX(a6) ;in the denorm
	move.l	USER_FPCR(a6),d0
	andi.l	#$30,d0
	fmove.l	d0,fpcr		;set up users rmode and X
	fmove.x	ETEMP(a6),fp0
	fadd.x	FPTEMP(a6),fp0
	lea.l	WBTEMP(a6),a0	;point a0 to wbtemp in frame
	fmove.l	fpsr,d1
	or.l	d1,USER_FPSR(a6) ;capture cc's and inex from fadd
	fmove.x	fp0,WBTEMP(a6)	;write result to memory
	lsr.l	#4,d0		;put rmode in lower 2 bits
	move.l	USER_FPCR(a6),d1
	andi.l	#$c0,d1
	lsr.l	#6,d1		;put precision in upper word
	swap	d1
	or.l	d0,d1		;set up for round call
	clr.l	d0		;force sticky to zero
	bclr.b	#sign_bit,WBTEMP_EX(a6)
	sne	WBTEMP_SGN(a6)
	bsr.l	round		;round result to users rmode & prec
	bfclr	WBTEMP_SGN(a6){0:8}	;convert back to IEEE ext format
	beq	frcfpnr
	bset.b	#sign_bit,WBTEMP_EX(a6)
	bra	frcfpnr
add_u_srcd:
	move.w	ETEMP_EX(a6),d0
	andi.w	#$8000,d0
	or.w	#$3fff,d0	;force the exponent to +/- 1
	move.w	d0,ETEMP_EX(a6) ;in the denorm
	move.l	USER_FPCR(a6),d0
	andi.l	#$30,d0
	fmove.l	d0,fpcr		;set up users rmode and X
	fmove.x	ETEMP(a6),fp0
	fadd.x	FPTEMP(a6),fp0
	fmove.l	fpsr,d1
	or.l	d1,USER_FPSR(a6) ;capture cc's and inex from fadd
	lea.l	WBTEMP(a6),a0	;point a0 to wbtemp in frame
	fmove.x	fp0,WBTEMP(a6)	;write result to memory
	lsr.l	#4,d0		;put rmode in lower 2 bits
	move.l	USER_FPCR(a6),d1
	andi.l	#$c0,d1
	lsr.l	#6,d1		;put precision in upper word
	swap	d1
	or.l	d0,d1		;set up for round call
	clr.l	d0		;force sticky to zero
	bclr.b	#sign_bit,WBTEMP_EX(a6)
	sne	WBTEMP_SGN(a6)	;use internal format for round
	bsr.l	round		;round result to users rmode & prec
	bfclr	WBTEMP_SGN(a6){0:8}	;convert back to IEEE ext format
	beq	frcfpnr
	bset.b	#sign_bit,WBTEMP_EX(a6)
	bra	frcfpnr
;
; Signs are alike:
;
add_same:
	cmp.b	#$0f,DNRM_FLG(a6) ;is dest the denorm?
	bne.s	add_s_srcd
add_s_destd:
	lea.l	ETEMP(a6),a0
	move.l	USER_FPCR(a6),d0
	andi.l	#$30,d0
	lsr.l	#4,d0		;put rmode in lower 2 bits
	move.l	USER_FPCR(a6),d1
	andi.l	#$c0,d1
	lsr.l	#6,d1		;put precision in upper word
	swap	d1
	or.l	d0,d1		;set up for round call
	move.l	#$20000000,d0	;set sticky for round
	bclr.b	#sign_bit,ETEMP_EX(a6)
	sne	ETEMP_SGN(a6)
	bsr.l	round		;round result to users rmode & prec
	bfclr	ETEMP_SGN(a6){0:8}	;convert back to IEEE ext format
	beq.s	add_s_dclr
	bset.b	#sign_bit,ETEMP_EX(a6)
add_s_dclr:
	lea.l	WBTEMP(a6),a0
	move.l	ETEMP(a6),(a0)	;write result to wbtemp
	move.l	ETEMP_HI(a6),4(a0)
	move.l	ETEMP_LO(a6),8(a0)
	tst.w	ETEMP_EX(a6)
	bgt	add_ckovf
	or.l	#neg_mask,USER_FPSR(a6)
	bra	add_ckovf
add_s_srcd:
	lea.l	FPTEMP(a6),a0
	move.l	USER_FPCR(a6),d0
	andi.l	#$30,d0
	lsr.l	#4,d0		;put rmode in lower 2 bits
	move.l	USER_FPCR(a6),d1
	andi.l	#$c0,d1
	lsr.l	#6,d1		;put precision in upper word
	swap	d1
	or.l	d0,d1		;set up for round call
	move.l	#$20000000,d0	;set sticky for round
	bclr.b	#sign_bit,FPTEMP_EX(a6)
	sne	FPTEMP_SGN(a6)
	bsr.l	round		;round result to users rmode & prec
	bfclr	FPTEMP_SGN(a6){0:8}	;convert back to IEEE ext format
	beq.s	add_s_sclr
	bset.b	#sign_bit,FPTEMP_EX(a6)
add_s_sclr:
	lea.l	WBTEMP(a6),a0
	move.l	FPTEMP(a6),(a0)	;write result to wbtemp
	move.l	FPTEMP_HI(a6),4(a0)
	move.l	FPTEMP_LO(a6),8(a0)
	tst.w	FPTEMP_EX(a6)
	bgt	add_ckovf
	or.l	#neg_mask,USER_FPSR(a6)
add_ckovf:
	move.w	WBTEMP_EX(a6),d0
	andi.w	#$7fff,d0
	cmpi.w	#$7fff,d0
	bne	frcfpnr
;
; The result has overflowed to $7fff exponent.  Set I, ovfl,
; and aovfl, and clr the mantissa (incorrectly set by the
; round routine.)
;
	or.l	#inf_mask+ovfl_inx_mask,USER_FPSR(a6)	
	clr.l	4(a0)
	bra	frcfpnr
;
; Inst is fsub.
;
wrap_sub:
	cmp.b	#$ff,DNRM_FLG(a6) ;if both ops denorm, 
	beq	fix_stk		 ;restore to fpu
;
; One of the ops is denormalized.  Test for wrap condition
; and complete the instruction.
;
	cmp.b	#$0f,DNRM_FLG(a6) ;check for dest denorm
	bne.s	sub_srcd
sub_destd:
	bsr.l	ckinf_ns
	bne	fix_stk
	bfextu	ETEMP_EX(a6){1:15},d0	;get src exp (always pos)
	bfexts	FPTEMP_EX(a6){1:15},d1	;get dest exp (always neg)
	sub.l	d1,d0			;subtract src from dest
	cmp.l	#$8000,d0
	blt	fix_stk			;if less, not wrap case
	bra	sub_wrap
sub_srcd:
	bsr.l	ckinf_nd
	bne	fix_stk
	bfextu	FPTEMP_EX(a6){1:15},d0	;get dest exp (always pos)
	bfexts	ETEMP_EX(a6){1:15},d1	;get src exp (always neg)
	sub.l	d1,d0			;subtract dest from src
	cmp.l	#$8000,d0
	blt	fix_stk			;if less, not wrap case
;
; Check the signs of the operands.  If they are alike, the fpu
; can be used to subtract from the norm 1.0 with the sign of the
; denorm and it will correctly generate the result in extended
; precision.  We can then call round with no sticky and the result
; will be correct for the user's rounding mode and precision.  If
; the signs are unlike, we call round with the sticky bit set
; and the result will be correct for the user's rounding mode and
; precision.
;
sub_wrap:
	move.w	ETEMP_EX(a6),d0
	move.w	FPTEMP_EX(a6),d1
	eor.w	d1,d0
	andi.w	#$8000,d0
	bne	sub_diff
;
; The signs are alike.
;
	cmp.b	#$0f,DNRM_FLG(a6) ;is dest the denorm?
	bne.s	sub_u_srcd
	move.w	FPTEMP_EX(a6),d0
	andi.w	#$8000,d0
	or.w	#$3fff,d0	;force the exponent to +/- 1
	move.w	d0,FPTEMP_EX(a6) ;in the denorm
	move.l	USER_FPCR(a6),d0
	andi.l	#$30,d0
	fmove.l	d0,fpcr		;set up users rmode and X
	fmove.x	FPTEMP(a6),fp0
	fsub.x	ETEMP(a6),fp0
	fmove.l	fpsr,d1
	or.l	d1,USER_FPSR(a6) ;capture cc's and inex from fadd
	lea.l	WBTEMP(a6),a0	;point a0 to wbtemp in frame
	fmove.x	fp0,WBTEMP(a6)	;write result to memory
	lsr.l	#4,d0		;put rmode in lower 2 bits
	move.l	USER_FPCR(a6),d1
	andi.l	#$c0,d1
	lsr.l	#6,d1		;put precision in upper word
	swap	d1
	or.l	d0,d1		;set up for round call
	clr.l	d0		;force sticky to zero
	bclr.b	#sign_bit,WBTEMP_EX(a6)
	sne	WBTEMP_SGN(a6)
	bsr.l	round		;round result to users rmode & prec
	bfclr	WBTEMP_SGN(a6){0:8}	;convert back to IEEE ext format
	beq	frcfpnr
	bset.b	#sign_bit,WBTEMP_EX(a6)
	bra	frcfpnr
sub_u_srcd:
	move.w	ETEMP_EX(a6),d0
	andi.w	#$8000,d0
	or.w	#$3fff,d0	;force the exponent to +/- 1
	move.w	d0,ETEMP_EX(a6) ;in the denorm
	move.l	USER_FPCR(a6),d0
	andi.l	#$30,d0
	fmove.l	d0,fpcr		;set up users rmode and X
	fmove.x	FPTEMP(a6),fp0
	fsub.x	ETEMP(a6),fp0
	fmove.l	fpsr,d1
	or.l	d1,USER_FPSR(a6) ;capture cc's and inex from fadd
	lea.l	WBTEMP(a6),a0	;point a0 to wbtemp in frame
	fmove.x	fp0,WBTEMP(a6)	;write result to memory
	lsr.l	#4,d0		;put rmode in lower 2 bits
	move.l	USER_FPCR(a6),d1
	andi.l	#$c0,d1
	lsr.l	#6,d1		;put precision in upper word
	swap	d1
	or.l	d0,d1		;set up for round call
	clr.l	d0		;force sticky to zero
	bclr.b	#sign_bit,WBTEMP_EX(a6)
	sne	WBTEMP_SGN(a6)
	bsr.l	round		;round result to users rmode & prec
	bfclr	WBTEMP_SGN(a6){0:8}	;convert back to IEEE ext format
	beq	frcfpnr
	bset.b	#sign_bit,WBTEMP_EX(a6)
	bra	frcfpnr
;
; Signs are unlike:
;
sub_diff:
	cmp.b	#$0f,DNRM_FLG(a6) ;is dest the denorm?
	bne.s	sub_s_srcd
sub_s_destd:
	lea.l	ETEMP(a6),a0
	move.l	USER_FPCR(a6),d0
	andi.l	#$30,d0
	lsr.l	#4,d0		;put rmode in lower 2 bits
	move.l	USER_FPCR(a6),d1
	andi.l	#$c0,d1
	lsr.l	#6,d1		;put precision in upper word
	swap	d1
	or.l	d0,d1		;set up for round call
	move.l	#$20000000,d0	;set sticky for round
;
; Since the dest is the denorm, the sign is the opposite of the
; norm sign.
;
	eori.w	#$8000,ETEMP_EX(a6)	;flip sign on result
	tst.w	ETEMP_EX(a6)
	bgt.s	sub_s_dwr
	or.l	#neg_mask,USER_FPSR(a6)
sub_s_dwr:
	bclr.b	#sign_bit,ETEMP_EX(a6)
	sne	ETEMP_SGN(a6)
	bsr.l	round		;round result to users rmode & prec
	bfclr	ETEMP_SGN(a6){0:8}	;convert back to IEEE ext format
	beq.s	sub_s_dclr
	bset.b	#sign_bit,ETEMP_EX(a6)
sub_s_dclr:
	lea.l	WBTEMP(a6),a0
	move.l	ETEMP(a6),(a0)	;write result to wbtemp
	move.l	ETEMP_HI(a6),4(a0)
	move.l	ETEMP_LO(a6),8(a0)
	bra	sub_ckovf
sub_s_srcd:
	lea.l	FPTEMP(a6),a0
	move.l	USER_FPCR(a6),d0
	andi.l	#$30,d0
	lsr.l	#4,d0		;put rmode in lower 2 bits
	move.l	USER_FPCR(a6),d1
	andi.l	#$c0,d1
	lsr.l	#6,d1		;put precision in upper word
	swap	d1
	or.l	d0,d1		;set up for round call
	move.l	#$20000000,d0	;set sticky for round
	bclr.b	#sign_bit,FPTEMP_EX(a6)
	sne	FPTEMP_SGN(a6)
	bsr.l	round		;round result to users rmode & prec
	bfclr	FPTEMP_SGN(a6){0:8}	;convert back to IEEE ext format
	beq.s	sub_s_sclr
	bset.b	#sign_bit,FPTEMP_EX(a6)
sub_s_sclr:
	lea.l	WBTEMP(a6),a0
	move.l	FPTEMP(a6),(a0)	;write result to wbtemp
	move.l	FPTEMP_HI(a6),4(a0)
	move.l	FPTEMP_LO(a6),8(a0)
	tst.w	FPTEMP_EX(a6)
	bgt	sub_ckovf
	or.l	#neg_mask,USER_FPSR(a6)
sub_ckovf:
	move.w	WBTEMP_EX(a6),d0
	andi.w	#$7fff,d0
	cmpi.w	#$7fff,d0
	bne	frcfpnr
;
; The result has overflowed to $7fff exponent.  Set I, ovfl,
; and aovfl, and clr the mantissa (incorrectly set by the
; round routine.)
;
	or.l	#inf_mask+ovfl_inx_mask,USER_FPSR(a6)	
	clr.l	4(a0)
	bra	frcfpnr
;
; Inst is fcmp.
;
wrap_cmp:
	cmp.b	#$ff,DNRM_FLG(a6) ;if both ops denorm, 
	beq	fix_stk		 ;restore to fpu
;
; One of the ops is denormalized.  Test for wrap condition
; and complete the instruction.
;
	cmp.b	#$0f,DNRM_FLG(a6) ;check for dest denorm
	bne.s	cmp_srcd
cmp_destd:
	bsr.l	ckinf_ns
	bne	fix_stk
	bfextu	ETEMP_EX(a6){1:15},d0	;get src exp (always pos)
	bfexts	FPTEMP_EX(a6){1:15},d1	;get dest exp (always neg)
	sub.l	d1,d0			;subtract dest from src
	cmp.l	#$8000,d0
	blt	fix_stk			;if less, not wrap case
	tst.w	ETEMP_EX(a6)		;set N to ~sign_of(src)
	bge	cmp_setn
	rts
cmp_srcd:
	bsr.l	ckinf_nd
	bne	fix_stk
	bfextu	FPTEMP_EX(a6){1:15},d0	;get dest exp (always pos)
	bfexts	ETEMP_EX(a6){1:15},d1	;get src exp (always neg)
	sub.l	d1,d0			;subtract src from dest
	cmp.l	#$8000,d0
	blt	fix_stk			;if less, not wrap case
	tst.w	FPTEMP_EX(a6)		;set N to sign_of(dest)
	blt	cmp_setn
	rts
cmp_setn:
	or.l	#neg_mask,USER_FPSR(a6)
	rts

;
; Inst is fmul.
;
wrap_mul:
	cmp.b	#$ff,DNRM_FLG(a6) ;if both ops denorm, 
	beq	force_unf	;force an underflow (really!)
;
; One of the ops is denormalized.  Test for wrap condition
; and complete the instruction.
;
	cmp.b	#$0f,DNRM_FLG(a6) ;check for dest denorm
	bne.s	mul_srcd
mul_destd:
	bsr.l	ckinf_ns
	bne	fix_stk
	bfextu	ETEMP_EX(a6){1:15},d0	;get src exp (always pos)
	bfexts	FPTEMP_EX(a6){1:15},d1	;get dest exp (always neg)
	add.l	d1,d0			;subtract dest from src
	bgt	fix_stk
	bra	force_unf
mul_srcd:
	bsr.l	ckinf_nd
	bne	fix_stk
	bfextu	FPTEMP_EX(a6){1:15},d0	;get dest exp (always pos)
	bfexts	ETEMP_EX(a6){1:15},d1	;get src exp (always neg)
	add.l	d1,d0			;subtract src from dest
	bgt	fix_stk
	
;
; This code handles the case of the instruction resulting in 
; an underflow condition.
;
force_unf:
	bclr.b	#E1,E_BYTE(a6)
	or.l	#unfinx_mask,USER_FPSR(a6)
	clr.w	NMNEXC(a6)
	clr.b	WBTEMP_SGN(a6)
	move.w	ETEMP_EX(a6),d0		;find the sign of the result
	move.w	FPTEMP_EX(a6),d1
	eor.w	d1,d0
	andi.w	#$8000,d0
	beq.s	frcunfcont
	st	WBTEMP_SGN(a6)
frcunfcont:
	lea	WBTEMP(a6),a0		;point a0 to memory location
	move.w	CMDREG1B(a6),d0
	btst.l	#6,d0			;test for forced precision
	beq.s	frcunf_fpcr
	btst.l	#2,d0			;check for double
	bne.s	frcunf_dbl
	move.l	#$1,d0			;inst is forced single
	bra.s	frcunf_rnd
frcunf_dbl:
	move.l	#$2,d0			;inst is forced double
	bra.s	frcunf_rnd
frcunf_fpcr:
	bfextu	FPCR_MODE(a6){0:2},d0	;inst not forced - use fpcr prec
frcunf_rnd:
	bsr.l	unf_sub			;get correct result based on
;					;round precision/mode.  This 
;					;sets FPSR_CC correctly
	bfclr	WBTEMP_SGN(a6){0:8}	;convert back to IEEE ext format
	beq.s	frcfpn
	bset.b	#sign_bit,WBTEMP_EX(a6)
	bra	frcfpn

;
; Write the result to the user's fpn.  All results must be HUGE to be
; written; otherwise the results would have overflowed or underflowed.
; If the rounding precision is single or double, the ovf_res routine
; is needed to correctly supply the max value.
;
frcfpnr:
	move.w	CMDREG1B(a6),d0
	btst.l	#6,d0			;test for forced precision
	beq.s	frcfpn_fpcr
	btst.l	#2,d0			;check for double
	bne.s	frcfpn_dbl
	move.l	#$1,d0			;inst is forced single
	bra.s	frcfpn_rnd
frcfpn_dbl:
	move.l	#$2,d0			;inst is forced double
	bra.s	frcfpn_rnd
frcfpn_fpcr:
	bfextu	FPCR_MODE(a6){0:2},d0	;inst not forced - use fpcr prec
	tst.b	d0
	beq.s	frcfpn			;if extended, write what you got
frcfpn_rnd:
	bclr.b	#sign_bit,WBTEMP_EX(a6)
	sne	WBTEMP_SGN(a6)
	bsr.l	ovf_res			;get correct result based on
;					;round precision/mode.  This 
;					;sets FPSR_CC correctly
	bfclr	WBTEMP_SGN(a6){0:8}	;convert back to IEEE ext format
	beq.s	frcfpn_clr
	bset.b	#sign_bit,WBTEMP_EX(a6)
frcfpn_clr:
	or.l	#ovfinx_mask,USER_FPSR(a6)
; 
; Perform the write.
;
frcfpn:
	bfextu	CMDREG1B(a6){6:3},d0	;extract fp destination register
	cmpi.b	#3,d0
	ble.s	frc0123			;check if dest is fp0-fp3
	move.l	#7,d1
	sub.l	d0,d1
	clr.l	d0
	bset.l	d1,d0
	fmovem.x WBTEMP(a6),d0
	rts
frc0123:
	cmpi.b	#0,d0
	beq.s	frc0_dst
	cmpi.b	#1,d0
	beq.s	frc1_dst 
	cmpi.b	#2,d0
	beq.s	frc2_dst 
frc3_dst:
	move.l	WBTEMP_EX(a6),USER_FP3(a6)
	move.l	WBTEMP_HI(a6),USER_FP3+4(a6)
	move.l	WBTEMP_LO(a6),USER_FP3+8(a6)
	rts
frc2_dst:
	move.l	WBTEMP_EX(a6),USER_FP2(a6)
	move.l	WBTEMP_HI(a6),USER_FP2+4(a6)
	move.l	WBTEMP_LO(a6),USER_FP2+8(a6)
	rts
frc1_dst:
	move.l	WBTEMP_EX(a6),USER_FP1(a6)
	move.l	WBTEMP_HI(a6),USER_FP1+4(a6)
	move.l	WBTEMP_LO(a6),USER_FP1+8(a6)
	rts
frc0_dst:
	move.l	WBTEMP_EX(a6),USER_FP0(a6)
	move.l	WBTEMP_HI(a6),USER_FP0+4(a6)
	move.l	WBTEMP_LO(a6),USER_FP0+8(a6)
	rts

;
; Write etemp to fpn.
; A check is made on enabled and signalled snan exceptions,
; and the destination is not overwritten if this condition exists.
; This code is designed to make fmoveins of unsupported data types
; faster.
;
wr_etemp:
	btst.b	#snan_bit,FPSR_EXCEPT(a6)	;if snan is set, and
	beq.s	fmoveinc		;enabled, force restore
	btst.b	#snan_bit,FPCR_ENABLE(a6) ;and don't overwrite
	beq.s	fmoveinc		;the dest
	move.l	ETEMP_EX(a6),FPTEMP_EX(a6)	;set up fptemp sign for 
;						;snan handler
	tst.b	ETEMP(a6)		;check for negative
	blt.s	snan_neg
	rts
snan_neg:
	or.l	#neg_bit,USER_FPSR(a6)	;snan is negative; set N
	rts
fmoveinc:
	clr.w	NMNEXC(a6)
	bclr.b	#E1,E_BYTE(a6)
	move.b	STAG(a6),d0		;check if stag is inf
	andi.b	#$e0,d0
	cmpi.b	#$40,d0
	bne.s	fminc_cnan
	or.l	#inf_mask,USER_FPSR(a6) ;if inf, nothing yet has set I
	tst.w	LOCAL_EX(a0)		;check sign
	bge.s	fminc_con
	or.l	#neg_mask,USER_FPSR(a6)
	bra	fminc_con
fminc_cnan:
	cmpi.b	#$60,d0			;check if stag is NaN
	bne.s	fminc_czero
	or.l	#nan_mask,USER_FPSR(a6) ;if nan, nothing yet has set NaN
	move.l	ETEMP_EX(a6),FPTEMP_EX(a6)	;set up fptemp sign for 
;						;snan handler
	tst.w	LOCAL_EX(a0)		;check sign
	bge.s	fminc_con
	or.l	#neg_mask,USER_FPSR(a6)
	bra	fminc_con
fminc_czero:
	cmpi.b	#$20,d0			;check if zero
	bne.s	fminc_con
	or.l	#z_mask,USER_FPSR(a6)	;if zero, set Z
	tst.w	LOCAL_EX(a0)		;check sign
	bge.s	fminc_con
	or.l	#neg_mask,USER_FPSR(a6)
fminc_con:
	bfextu	CMDREG1B(a6){6:3},d0	;extract fp destination register
	cmpi.b	#3,d0
	ble.s	.fp0123			;check if dest is fp0-fp3
	move.l	#7,d1
	sub.l	d0,d1
	clr.l	d0
	bset.l	d1,d0
	fmovem.x ETEMP(a6),d0
	rts

.fp0123:
	cmpi.b	#0,d0
	beq.s	fp0_dst
	cmpi.b	#1,d0
	beq.s	fp1_dst 
	cmpi.b	#2,d0
	beq.s	fp2_dst 
fp3_dst:
	move.l	ETEMP_EX(a6),USER_FP3(a6)
	move.l	ETEMP_HI(a6),USER_FP3+4(a6)
	move.l	ETEMP_LO(a6),USER_FP3+8(a6)
	rts
fp2_dst:
	move.l	ETEMP_EX(a6),USER_FP2(a6)
	move.l	ETEMP_HI(a6),USER_FP2+4(a6)
	move.l	ETEMP_LO(a6),USER_FP2+8(a6)
	rts
fp1_dst:
	move.l	ETEMP_EX(a6),USER_FP1(a6)
	move.l	ETEMP_HI(a6),USER_FP1+4(a6)
	move.l	ETEMP_LO(a6),USER_FP1+8(a6)
	rts
fp0_dst:
	move.l	ETEMP_EX(a6),USER_FP0(a6)
	move.l	ETEMP_HI(a6),USER_FP0+4(a6)
	move.l	ETEMP_LO(a6),USER_FP0+8(a6)
	rts

opclass3:
	st	CU_ONLY(a6)
	move.w	CMDREG1B(a6),d0	;check if packed moveout
	andi.w	#$0c00,d0	;isolate last 2 bits of size field
	cmpi.w	#$0c00,d0	;if size is 011 or 111, it is packed
	beq	pack_out	;else it is norm or denorm
	bra	mv_out

	
;
;	MOVE OUT
;

mv_tbl:
	dc.l	li
	dc.l 	sgp
	dc.l 	xp
	dc.l 	mvout_end	;should never be taken
	dc.l 	wi
	dc.l 	dp
	dc.l 	bi
	dc.l 	mvout_end	;should never be taken
mv_out:
	bfextu	CMDREG1B(a6){3:3},d1	;put source specifier in d1
	lea.l	mv_tbl(pc),a0
	move.l	(a0,d1.l*4),a0
	jmp	(a0)

;
; This exit is for move-out to memory.  The aunfl bit is 
; set if the result is inex and unfl is signalled.
;
mvout_end:
	btst.b	#inex2_bit,FPSR_EXCEPT(a6)
	beq.s	no_aufl
	btst.b	#unfl_bit,FPSR_EXCEPT(a6)
	beq.s	no_aufl
	bset.b	#aunfl_bit,FPSR_AEXCEPT(a6)
no_aufl:
	clr.w	NMNEXC(a6)
	bclr.b	#E1,E_BYTE(a6)
	fmove.l	#0,FPSR			;clear any cc bits from res_func
;
; Return ETEMP to extended format from internal extended format so
; that gen_except will have a correctly signed value for ovfl/unfl
; handlers.
;
	bfclr	ETEMP_SGN(a6){0:8}
	beq.s	mvout_con
	bset.b	#sign_bit,ETEMP_EX(a6)
mvout_con:
	rts
;
; This exit is for move-out to int register.  The aunfl bit is 
; not set in any case for this move.
;
mvouti_end:
	clr.w	NMNEXC(a6)
	bclr.b	#E1,E_BYTE(a6)
	fmove.l	#0,FPSR			;clear any cc bits from res_func
;
; Return ETEMP to extended format from internal extended format so
; that gen_except will have a correctly signed value for ovfl/unfl
; handlers.
;
	bfclr	ETEMP_SGN(a6){0:8}
	beq.s	mvouti_con
	bset.b	#sign_bit,ETEMP_EX(a6)
mvouti_con:
	rts
;
; li is used to handle a long integer source specifier
;

li:
	moveq.l	#4,d0		;set byte count

	btst.b	#7,STAG(a6)	;check for extended denorm
	bne	int_dnrm	;if so, branch

	fmovem.x ETEMP(a6),fp0-fp0
	fcmp.d	#$41dfffffffc00000,fp0
; 41dfffffffc00000 in dbl prec = 401d0000fffffffe00000000 in ext prec
	fbge	lo_plrg	
	fcmp.d	#$c1e0000000000000,fp0
; c1e0000000000000 in dbl prec = c01e00008000000000000000 in ext prec
	fble	lo_nlrg
;
; at this point, the answer is between the largest pos and neg values
;
	move.l	USER_FPCR(a6),d1	;use user's rounding mode
	andi.l	#$30,d1
	fmove.l	d1,fpcr
	fmove.l	fp0,L_SCR1(a6)	;let the 040 perform conversion
	fmove.l fpsr,d1
	or.l	d1,USER_FPSR(a6)	;capture inex2/ainex if set
	bra	int_wrt


lo_plrg:
	move.l	#$7fffffff,L_SCR1(a6)	;answer is largest positive int
	fbeq	int_wrt			;exact answer
	fcmp.d	#$41dfffffffe00000,fp0
; 41dfffffffe00000 in dbl prec = 401d0000ffffffff00000000 in ext prec
	fbge	int_operr		;set operr
	bra	int_inx			;set inexact

lo_nlrg:
	move.l	#$80000000,L_SCR1(a6)
	fbeq	int_wrt			;exact answer
	fcmp.d	#$c1e0000000100000,fp0
; c1e0000000100000 in dbl prec = c01e00008000000080000000 in ext prec
	fblt	int_operr		;set operr
	bra	int_inx			;set inexact

;
; wi is used to handle a word integer source specifier
;

wi:
	moveq.l	#2,d0		;set byte count

	btst.b	#7,STAG(a6)	;check for extended denorm
	bne	int_dnrm	;branch if so

	fmovem.x ETEMP(a6),fp0-fp0
	fcmp.s	#$46fffe00,fp0
; 46fffe00 in sgl prec = 400d0000fffe000000000000 in ext prec
	fbge	wo_plrg	
	fcmp.s	#$c7000000,fp0
; c7000000 in sgl prec = c00e00008000000000000000 in ext prec
	fble	wo_nlrg

;
; at this point, the answer is between the largest pos and neg values
;
	move.l	USER_FPCR(a6),d1	;use user's rounding mode
	andi.l	#$30,d1
	fmove.l	d1,fpcr
	fmove.w	fp0,L_SCR1(a6)	;let the 040 perform conversion
	fmove.l fpsr,d1
	or.l	d1,USER_FPSR(a6)	;capture inex2/ainex if set
	bra	int_wrt

wo_plrg:
	move.w	#$7fff,L_SCR1(a6)	;answer is largest positive int
	fbeq	int_wrt			;exact answer
	fcmp.s	#$46ffff00,fp0
; 46ffff00 in sgl prec = 400d0000ffff000000000000 in ext prec
	fbge	int_operr		;set operr
	bra	int_inx			;set inexact

wo_nlrg:
	move.w	#$8000,L_SCR1(a6)
	fbeq	int_wrt			;exact answer
	fcmp.s	#$c7000080,fp0
; c7000080 in sgl prec = c00e00008000800000000000 in ext prec
	fblt	int_operr		;set operr
	bra	int_inx			;set inexact

;
; bi is used to handle a byte integer source specifier
;

bi:
	moveq.l	#1,d0		;set byte count

	btst.b	#7,STAG(a6)	;check for extended denorm
	bne	int_dnrm	;branch if so

	fmovem.x ETEMP(a6),fp0-fp0
	fcmp.s	#$42fe0000,fp0
; 42fe0000 in sgl prec = 40050000fe00000000000000 in ext prec
	fbge	by_plrg	
	fcmp.s	#$c3000000,fp0
; c3000000 in sgl prec = c00600008000000000000000 in ext prec
	fble	by_nlrg

;
; at this point, the answer is between the largest pos and neg values
;
	move.l	USER_FPCR(a6),d1	;use user's rounding mode
	andi.l	#$30,d1
	fmove.l	d1,fpcr
	fmove.b	fp0,L_SCR1(a6)	;let the 040 perform conversion
	fmove.l fpsr,d1
	or.l	d1,USER_FPSR(a6)	;capture inex2/ainex if set
	bra	int_wrt

by_plrg:
	move.b	#$7f,L_SCR1(a6)		;answer is largest positive int
	fbeq	int_wrt			;exact answer
	fcmp.s	#$42ff0000,fp0
; 42ff0000 in sgl prec = 40050000ff00000000000000 in ext prec
	fbge	int_operr		;set operr
	bra	int_inx			;set inexact

by_nlrg:
	move.b	#$80,L_SCR1(a6)
	fbeq	int_wrt			;exact answer
	fcmp.s	#$c3008000,fp0
; c3008000 in sgl prec = c00600008080000000000000 in ext prec
	fblt	int_operr		;set operr
	bra	int_inx			;set inexact

;
; Common integer routines
;
; int_drnrm---account for possible nonzero result for round up with positive
; operand and round down for negative answer.  In the first case (result = 1)
; byte-width (store in d0) of result must be honored.  In the second case,
; -1 in L_SCR1(a6) will cover all contingencies (FMOVE.B/W/L out).

int_dnrm:
	move.l	#0,L_SCR1(a6)	; initialize result to 0
	bfextu	FPCR_MODE(a6){2:2},d1	; d1 is the rounding mode
	cmp.b	#2,d1		
	bmi.s	int_inx		; if RN or RZ, done
	bne.s	int_rp		; if RP, continue below
	tst.w	ETEMP(a6)	; RM: store -1 in L_SCR1 if src is negative
	bpl.s	int_inx		; otherwise result is 0
	move.l	#-1,L_SCR1(a6)
	bra.s	int_inx
int_rp:
	tst.w	ETEMP(a6)	; RP: store +1 of proper width in L_SCR1 if
;				; source is greater than 0
	bmi.s	int_inx		; otherwise, result is 0
	lea	L_SCR1(a6),a1	; a1 is address of L_SCR1
	adda.l	d0,a1		; offset by destination width -1
	suba.l	#1,a1		
	bset.b	#0,(a1)		; set low bit at a1 address
int_inx:
	ori.l	#inx2a_mask,USER_FPSR(a6)
	bra.s	int_wrt
int_operr:
	fmovem.x fp0-fp0,FPTEMP(a6)	;FPTEMP must contain the extended
;				;precision source that needs to be
;				;converted to integer this is required
;				;if the operr exception is enabled.
;				;set operr/aiop (no inex2 on int ovfl)

	ori.l	#opaop_mask,USER_FPSR(a6)
;				;fall through to perform int_wrt
int_wrt: 
	move.l	EXC_EA(a6),a1	;load destination address
	tst.l	a1		;check to see if it is a dest register
	beq.s	.wrt_dn		;write data register 
	lea	L_SCR1(a6),a0	;point to supervisor source address
	bsr.l	mem_write
	bra	mvouti_end

.wrt_dn:
	move.l	d0,-(sp)	;d0 currently contains the size to write
	bsr.l	get_fline	;get_fline returns Dn in d0
	andi.w	#$7,d0		;isolate register
	move.l	(sp)+,d1	;get size
	cmpi.l	#4,d1		;most frequent case
	beq.s	sz_long
	cmpi.l	#2,d1
	bne.s	sz_con
	or.l	#8,d0		;add 'word' size to register#
	bra.s	sz_con
sz_long:
	or.l	#$10,d0		;add 'long' size to register#
sz_con:
	move.l	d0,d1		;reg_dest expects size:reg in d1
	bsr.l	reg_dest	;load proper data register
	bra	mvouti_end 
xp:
	lea	ETEMP(a6),a0
	bclr.b	#sign_bit,LOCAL_EX(a0)
	sne	LOCAL_SGN(a0)
	btst.b	#7,STAG(a6)	;check for extended denorm
	bne	xdnrm
	clr.l	d0
	bra.s	do_fp		;do normal case
sgp:
	lea	ETEMP(a6),a0
	bclr.b	#sign_bit,LOCAL_EX(a0)
	sne	LOCAL_SGN(a0)
	btst.b	#7,STAG(a6)	;check for extended denorm
	bne	sp_catas	;branch if so
	move.w	LOCAL_EX(a0),d0
	lea	sp_bnds(pc),a1
	cmp.w	(a1),d0
	blt	sp_under
	cmp.w	2(a1),d0
	bgt	sp_over
	move.l	#1,d0		;set destination format to single
	bra.s	do_fp		;do normal case
dp:
	lea	ETEMP(a6),a0
	bclr.b	#sign_bit,LOCAL_EX(a0)
	sne	LOCAL_SGN(a0)

	btst.b	#7,STAG(a6)	;check for extended denorm
	bne	dp_catas	;branch if so

	move.w	LOCAL_EX(a0),d0
	lea	dp_bnds(pc),a1

	cmp.w	(a1),d0
	blt	dp_under
	cmp.w	2(a1),d0
	bgt	dp_over
	
	move.l	#2,d0		;set destination format to double
;				;fall through to do_fp
;
do_fp:
	bfextu	FPCR_MODE(a6){2:2},d1	;rnd mode in d1
	swap	d0			;rnd prec in upper word
	add.l	d0,d1			;d1 has PREC/MODE info
	
	clr.l	d0			;clear g,r,s 

	bsr.l	round			;round 

	move.l	a0,a1
	move.l	EXC_EA(a6),a0

	bfextu	CMDREG1B(a6){3:3},d1	;extract destination format
;					;at this point only the dest
;					;formats sgl, dbl, ext are
;					;possible
	cmp.b	#2,d1
	bgt.s	ddbl			;double=5, extended=2, single=1
	bne.s	dsgl
;					;fall through to dext
dext:
	bsr.l	dest_ext
	bra	mvout_end
dsgl:
	bsr.l	dest_sgl
	bra	mvout_end
ddbl:
	bsr.l	dest_dbl
	bra	mvout_end

;
; Handle possible denorm or catastrophic underflow cases here
;
xdnrm:
	bsr	set_xop		;initialize WBTEMP
	bset.b	#wbtemp15_bit,WB_BYTE(a6) ;set wbtemp15

	move.l	a0,a1
	move.l	EXC_EA(a6),a0	;a0 has the destination pointer
	bsr.l	dest_ext	;store to memory
	bset.b	#unfl_bit,FPSR_EXCEPT(a6)
	bra	mvout_end
	
sp_under:
	bset.b	#etemp15_bit,STAG(a6)

	cmp.w	4(a1),d0
	blt.s	sp_catas	;catastrophic underflow case	

	move.l	#1,d0		;load in round precision
	move.l	#sgl_thresh,d1	;load in single denorm threshold
	bsr.l	dpspdnrm	;expects d1 to have the proper
;				;denorm threshold
	bsr.l	dest_sgl	;stores value to destination
	bset.b	#unfl_bit,FPSR_EXCEPT(a6)
	bra	mvout_end	;exit

dp_under:
	bset.b	#etemp15_bit,STAG(a6)

	cmp.w	4(a1),d0
	blt.s	dp_catas	;catastrophic underflow case
		
	move.l	#dbl_thresh,d1	;load in double precision threshold
	move.l	#2,d0		
	bsr.l	dpspdnrm	;expects d1 to have proper
;				;denorm threshold
;				;expects d0 to have round precision
	bsr.l	dest_dbl	;store value to destination
	bset.b	#unfl_bit,FPSR_EXCEPT(a6)
	bra	mvout_end	;exit

;
; Handle catastrophic underflow cases here
;
sp_catas:
; Temp fix for z bit set in unf_sub
	move.l	USER_FPSR(a6),-(a7)

	move.l	#1,d0		;set round precision to sgl

	bsr.l	unf_sub		;a0 points to result

	move.l	(a7)+,USER_FPSR(a6)

	move.l	#1,d0
	sub.w	d0,LOCAL_EX(a0) ;account for difference between
;				;denorm/norm bias

	move.l	a0,a1		;a1 has the operand input
	move.l	EXC_EA(a6),a0	;a0 has the destination pointer
	
	bsr.l	dest_sgl	;store the result
	ori.l	#unfinx_mask,USER_FPSR(a6)
	bra	mvout_end
	
dp_catas:
; Temp fix for z bit set in unf_sub
	move.l	USER_FPSR(a6),-(a7)

	move.l	#2,d0		;set round precision to dbl
	bsr.l	unf_sub		;a0 points to result

	move.l	(a7)+,USER_FPSR(a6)

	move.l	#1,d0
	sub.w	d0,LOCAL_EX(a0) ;account for difference between 
;				;denorm/norm bias

	move.l	a0,a1		;a1 has the operand input
	move.l	EXC_EA(a6),a0	;a0 has the destination pointer
	
	bsr.l	dest_dbl	;store the result
	ori.l	#unfinx_mask,USER_FPSR(a6)
	bra	mvout_end

;
; Handle catastrophic overflow cases here
;
sp_over:
; Temp fix for z bit set in unf_sub
	move.l	USER_FPSR(a6),-(a7)

	move.l	#1,d0
	lea.l	FP_SCR1(a6),a0	;use FP_SCR1 for creating result
	move.l	ETEMP_EX(a6),(a0)
	move.l	ETEMP_HI(a6),4(a0)
	move.l	ETEMP_LO(a6),8(a0)
	bsr.l	ovf_res

	move.l	(a7)+,USER_FPSR(a6)

	move.l	a0,a1
	move.l	EXC_EA(a6),a0
	bsr.l	dest_sgl
	or.l	#ovfinx_mask,USER_FPSR(a6)
	bra	mvout_end

dp_over:
; Temp fix for z bit set in ovf_res
	move.l	USER_FPSR(a6),-(a7)

	move.l	#2,d0
	lea.l	FP_SCR1(a6),a0	;use FP_SCR1 for creating result
	move.l	ETEMP_EX(a6),(a0)
	move.l	ETEMP_HI(a6),4(a0)
	move.l	ETEMP_LO(a6),8(a0)
	bsr.l	ovf_res

	move.l	(a7)+,USER_FPSR(a6)

	move.l	a0,a1
	move.l	EXC_EA(a6),a0
	bsr.l	dest_dbl
	or.l	#ovfinx_mask,USER_FPSR(a6)
	bra	mvout_end

;
; 	DPSPDNRM
;
; This subroutine takes an extended normalized number and denormalizes
; it to the given round precision. This subroutine also decrements
; the input operand's exponent by 1 to account for the fact that
; dest_sgl or dest_dbl expects a normalized number's bias.
;
; Input: a0  points to a normalized number in internal extended format
;	 d0  is the round precision (=1 for sgl; =2 for dbl)
;	 d1  is the the single precision or double precision
;	     denorm threshold
;
; Output: (In the format for dest_sgl or dest_dbl)
;	 a0   points to the destination
;   	 a1   points to the operand
;
; Exceptions: Reports inexact 2 exception by setting USER_FPSR bits
;
dpspdnrm:
	move.l	d0,-(a7)	;save round precision
	clr.l	d0		;clear initial g,r,s
	bsr.l	dnrm_lp		;careful with d0, it's needed by round

	bfextu	FPCR_MODE(a6){2:2},d1 ;get rounding mode
	swap	d1
	move.w	2(a7),d1	;set rounding precision 
	swap	d1		;at this point d1 has PREC/MODE info
	bsr.l	round		;round result, sets the inex bit in
;				;USER_FPSR if needed

	move.w	#1,d0
	sub.w	d0,LOCAL_EX(a0) ;account for difference in denorm
;				;vs norm bias

	move.l	a0,a1		;a1 has the operand input
	move.l	EXC_EA(a6),a0	;a0 has the destination pointer
	add.w	#4,a7		;pop stack
	rts
;
; SET_XOP initialized WBTEMP with the value pointed to by a0
; input: a0 points to input operand in the internal extended format
;
set_xop:
	move.l	LOCAL_EX(a0),WBTEMP_EX(a6)
	move.l	LOCAL_HI(a0),WBTEMP_HI(a6)
	move.l	LOCAL_LO(a0),WBTEMP_LO(a6)
	bfclr	WBTEMP_SGN(a6){0:8}
	beq.s	sxop
	bset.b	#sign_bit,WBTEMP_EX(a6)
sxop:
	bfclr	STAG(a6){5:4}	;clear wbtm66,wbtm1,wbtm0,sbit
	rts
;
;	P_MOVE
;
p_movet:
	dc.l	p_move
	dc.l	p_movez
	dc.l	p_movei
	dc.l	p_moven
	dc.l	p_move
p_regd:
	dc.l	p_dyd0
	dc.l	p_dyd1
	dc.l	p_dyd2
	dc.l	p_dyd3
	dc.l	p_dyd4
	dc.l	p_dyd5
	dc.l	p_dyd6
	dc.l	p_dyd7

pack_out:
 	lea.l	p_movet(pc),a0	;load jmp table address
	move.w	STAG(a6),d0	;get source tag
	bfextu	d0{16:3},d0	;isolate source bits
	move.l	(a0,d0.w*4),a0	;load a0 with routine label for tag
	jmp	(a0)		;go to the routine

p_write:
	move.l	#$0c,d0 	;get byte count
	move.l	EXC_EA(a6),a1	;get the destination address
	bsr 	mem_write	;write the user's destination
	move.b	#0,CU_SAVEPC(a6) ;set the cu save pc to all 0's

;
; Also note that the dtag must be set to norm here - this is because 
; the 040 uses the dtag to execute the correct microcode.
;
        bfclr    DTAG(a6){0:3}  ;set dtag to norm

	rts

; Notes on handling of special case (zero, inf, and nan) inputs:
;	1. Operr is not signalled if the k-factor is greater than 18.
;	2. Per the manual, status bits are not set.
;

p_move:
	move.w	CMDREG1B(a6),d0
	btst.l	#kfact_bit,d0	;test for dynamic k-factor
	beq.s	statick		;if clear, k-factor is static
dynamick:
	bfextu	d0{25:3},d0	;isolate register for dynamic k-factor
	lea	p_regd(pc),a0
	move.l	(a0,d0.l*4),a0
	jmp	(a0)
statick:
	andi.w	#$007f,d0	;get k-factor
	bfexts	d0{25:7},d0	;sign extend d0 for bindec
	lea.l	ETEMP(a6),a0	;a0 will point to the packed decimal
	bsr.l	bindec		;perform the convert; data at a6
	lea.l	FP_SCR1(a6),a0	;load a0 with result address
	bra.l	p_write
p_movez:
	lea.l	ETEMP(a6),a0	;a0 will point to the packed decimal
	clr.w	2(a0)		;clear lower word of exp
	clr.l	4(a0)		;load second lword of ZERO
	clr.l	8(a0)		;load third lword of ZERO
	bra	p_write		;go write results
p_movei:
	fmove.l	#0,FPSR		;clear aiop
	lea.l	ETEMP(a6),a0	;a0 will point to the packed decimal
	clr.w	2(a0)		;clear lower word of exp
	bra	p_write		;go write the result
p_moven:
	lea.l	ETEMP(a6),a0	;a0 will point to the packed decimal
	clr.w	2(a0)		;clear lower word of exp
	bra	p_write		;go write the result

;
; Routines to read the dynamic k-factor from Dn.
;
p_dyd0:
	move.l	USER_D0(a6),d0
	bra.s	statick
p_dyd1:
	move.l	USER_D1(a6),d0
	bra.s	statick
p_dyd2:
	move.l	d2,d0
	bra.s	statick
p_dyd3:
	move.l	d3,d0
	bra.s	statick
p_dyd4:
	move.l	d4,d0
	bra.s	statick
p_dyd5:
	move.l	d5,d0
	bra.s	statick
p_dyd6:
	move.l	d6,d0
	bra	statick
p_dyd7:
	move.l	d7,d0
	bra	statick

	;end
;
;	round.sa 3.4 7/29/91
;
;	handle rounding and normalization tasks
;
;
;
;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;ROUND	idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	

;
;	round --- round result according to precision/mode
;
;	a0 points to the input operand in the internal extended format 
;	d1(high word) contains rounding precision:
;		ext = $000$xxx
;		sgl = $0001xxxx
;		dbl = $0002xxxx
;	d1(low word) contains rounding mode:
;		RN  = $xxxx0000
;		RZ  = $xxxx0001
;		RM  = $xxxx0010
;		RP  = $xxxx0011
;	d0{31:29} contains the g,r,s bits (extended)
;
;	On return the value pointed to by a0 is correctly rounded,
;	a0 is preserved and the g-r-s bits in d0 are cleared.
;	The result is not typed - the tag field is invalid.  The
;	result is still in the internal extended format.
;
;	The INEX bit of USER_FPSR will be set if the rounded result was
;	inexact (i.e. if any of the g-r-s bits were set).
;

	;|.global	round
round:
; If g=r=s=0 then result is exact and round is done, else set 
; the inex flag in status reg and continue.  
;
	bsr.s	ext_grs			;this subroutine looks at the 
;					:rounding precision and sets 
;					;the appropriate g-r-s bits.
	tst.l	d0			;if grs are zero, go force
	bne	rnd_cont		;lower bits to zero for size
	
	swap	d1			;set up d1.w for round prec.
	bra	truncate

rnd_cont:
;
; Use rounding mode as an index into a jump table for these modes.
;
	or.l	#inx2a_mask,USER_FPSR(a6) ;set inex2/ainex
	lea	mode_tab(pc),a1
	move.l	(a1,d1.w*4),a1
	jmp	(a1)
;
; Jump table indexed by rounding mode in d1.w.  All following assumes
; grs != 0.
;
mode_tab:
	dc.l	rnd_near
	dc.l	rnd_zero
	dc.l	rnd_mnus
	dc.l	rnd_plus
;
;	ROUND PLUS INFINITY
;
;	If sign of fp number = 0 (positive), then add 1 to l.
;
rnd_plus:
	swap 	d1			;set up d1 for round prec.
	tst.b	LOCAL_SGN(a0)		;check for sign
	bmi	truncate		;if positive then truncate
	move.l	#$ffffffff,d0		;force g,r,s to be all f's
	lea	add_to_l(pc),a1
	move.l	(a1,d1.w*4),a1
	jmp	(a1)
;
;	ROUND MINUS INFINITY
;
;	If sign of fp number = 1 (negative), then add 1 to l.
;
rnd_mnus:
	swap 	d1			;set up d1 for round prec.
	tst.b	LOCAL_SGN(a0)		;check for sign	
	bpl	truncate		;if negative then truncate
	move.l	#$ffffffff,d0		;force g,r,s to be all f's
	lea	add_to_l(pc),a1
	move.l	(a1,d1.w*4),a1
	jmp	(a1)
;
;	ROUND ZERO
;
;	Always truncate.
rnd_zero:
	swap 	d1			;set up d1 for round prec.
	bra	truncate
;
;
;	ROUND NEAREST
;
;	If (g=1), then add 1 to l and if (r=s=0), then clear l
;	Note that this will round to even in case of a tie.
;
rnd_near:
	swap 	d1			;set up d1 for round prec.
	asl.l	#1,d0			;shift g-bit to c-bit
	bcc	truncate		;if (g=1) then
	lea	add_to_l(pc),a1
	move.l	(a1,d1.w*4),a1
	jmp	(a1)

;
;	ext_grs --- extract guard, round and sticky bits
;
; Input:	d1 =		PREC:ROUND
; Output:  	d0{31:29}=	guard, round, sticky
;
; The ext_grs extract the guard/round/sticky bits according to the
; selected rounding precision. It is called by the round subroutine
; only.  All registers except d0 are kept intact. d0 becomes an 
; updated guard,round,sticky in d0{31:29}
;
; Notes: the ext_grs uses the round PREC, and therefore has to swap d1
;	 prior to usage, and needs to restore d1 to original.
;
ext_grs:
	swap	d1			;have d1.w point to round precision
	cmpi.w	#0,d1
	bne.s	sgl_or_dbl
	bra.s	end_ext_grs
 
sgl_or_dbl:
	movem.l	d2/d3,-(a7)		;make some temp registers
	cmpi.w	#1,d1
	bne.s	grs_dbl
grs_sgl:
	bfextu	LOCAL_HI(a0){24:2},d3	;sgl prec. g-r are 2 bits right
	move.l	#30,d2			;of the sgl prec. limits
	lsl.l	d2,d3			;shift g-r bits to MSB of d3
	move.l	LOCAL_HI(a0),d2		;get word 2 for s-bit test
	andi.l	#$0000003f,d2		;s bit is the or of all other 
	bne.s	st_stky			;bits to the right of g-r
	tst.l	LOCAL_LO(a0)		;test lower mantissa
	bne.s	st_stky			;if any are set, set sticky
	tst.l	d0			;test original g,r,s
	bne.s	st_stky			;if any are set, set sticky
	bra.s	end_sd			;if words 3 and 4 are clr, exit
grs_dbl:    
	bfextu	LOCAL_LO(a0){21:2},d3	;dbl-prec. g-r are 2 bits right
	move.l	#30,d2			;of the dbl prec. limits
	lsl.l	d2,d3			;shift g-r bits to the MSB of d3
	move.l	LOCAL_LO(a0),d2		;get lower mantissa  for s-bit test
	andi.l	#$000001ff,d2		;s bit is the or-ing of all 
	bne.s	st_stky			;other bits to the right of g-r
	tst.l	d0			;test word original g,r,s
	bne.s	st_stky			;if any are set, set sticky
	bra.s	end_sd			;if clear, exit
st_stky:
	bset	#rnd_stky_bit,d3
end_sd:
	move.l	d3,d0			;return grs to d0
	movem.l	(a7)+,d2/d3		;restore scratch registers
end_ext_grs:
	swap	d1			;restore d1 to original
	rts

;*******************  Local Equates
ad_1_sgl = $00000100	;  constant to add 1 to l-bit in sgl prec
ad_1_dbl = $00000800	;  constant to add 1 to l-bit in dbl prec


;Jump table for adding 1 to the l-bit indexed by rnd prec

add_to_l:
	dc.l	add_ext
	dc.l	add_sgl
	dc.l	add_dbl
	dc.l	add_dbl
;
;	ADD SINGLE
;
add_sgl:
	add.l	#ad_1_sgl,LOCAL_HI(a0)
	bcc.s	scc_clr			;no mantissa overflow
	roxr.w  LOCAL_HI(a0)		;shift v-bit back in
	roxr.w  LOCAL_HI+2(a0)		;shift v-bit back in
	add.w	#$1,LOCAL_EX(a0)	;and incr exponent
scc_clr:
	tst.l	d0			;test for rs = 0
	bne.s	sgl_done
	andi.w  #$fe00,LOCAL_HI+2(a0)	;clear the l-bit
sgl_done:
	andi.l	#$ffffff00,LOCAL_HI(a0) ;truncate bits beyond sgl limit
	clr.l	LOCAL_LO(a0)		;clear d2
	rts

;
;	ADD EXTENDED
;
add_ext:
	addq.l  #1,LOCAL_LO(a0)		;add 1 to l-bit
	bcc.s	xcc_clr			;test for carry out
	addq.l  #1,LOCAL_HI(a0)		;propagate carry
	bcc.s	xcc_clr
	roxr.w  LOCAL_HI(a0)		;mant is 0 so restore v-bit
	roxr.w  LOCAL_HI+2(a0)		;mant is 0 so restore v-bit
	roxr.w	LOCAL_LO(a0)
	roxr.w	LOCAL_LO+2(a0)
	add.w	#$1,LOCAL_EX(a0)	;and inc exp
xcc_clr:
	tst.l	d0			;test rs = 0
	bne.s	add_ext_done
	andi.b	#$fe,LOCAL_LO+3(a0)	;clear the l bit
add_ext_done:
	rts
;
;	ADD DOUBLE
;
add_dbl:
	add.l	#ad_1_dbl,LOCAL_LO(a0)
	bcc.s	dcc_clr
	addq.l	#1,LOCAL_HI(a0)		;propagate carry
	bcc.s	dcc_clr
	roxr.w	LOCAL_HI(a0)		;mant is 0 so restore v-bit
	roxr.w	LOCAL_HI+2(a0)		;mant is 0 so restore v-bit
	roxr.w	LOCAL_LO(a0)
	roxr.w	LOCAL_LO+2(a0)
	add.w	#$1,LOCAL_EX(a0)	;incr exponent
dcc_clr:
	tst.l	d0			;test for rs = 0
	bne.s	dbl_done
	andi.w	#$f000,LOCAL_LO+2(a0)	;clear the l-bit

dbl_done:
	andi.l	#$fffff800,LOCAL_LO(a0) ;truncate bits beyond dbl limit
	rts

;error:
;	rts
;
; Truncate all other bits
;
trunct:
	dc.l	end_rnd
	dc.l	sgl_done
	dc.l	dbl_done
	dc.l	dbl_done

truncate:
	lea	trunct(pc),a1
	move.l	(a1,d1.w*4),a1
	jmp	(a1)

end_rnd:
	rts

;
;	NORMALIZE
;
; These routines (nrm_zero & nrm_set) normalize the unnorm.  This 
; is done by shifting the mantissa left while decrementing the 
; exponent.
;
; NRM_SET shifts and decrements until there is a 1 set in the integer 
; bit of the mantissa (msb in d1).
;
; NRM_ZERO shifts and decrements until there is a 1 set in the integer 
; bit of the mantissa (msb in d1) unless this would mean the exponent 
; would go less than 0.  In that case the number becomes a denorm - the 
; exponent (d0) is set to 0 and the mantissa (d1 & d2) is not 
; normalized.
;
; Note that both routines have been optimized (for the worst case) and 
; therefore do not have the easy to follow decrement/shift loop.
;
;	NRM_ZERO
;
;	Distance to first 1 bit in mantissa = X
;	Distance to 0 from exponent = Y
;	If X < Y
;	Then
;	  nrm_set
;	Else
;	  shift mantissa by Y
;	  set exponent = 0
;
;input:
;	FP_SCR1 = exponent, ms mantissa part, ls mantissa part
;output:
;	L_SCR1{4} = fpte15 or ete15 bit
;
	;|.global	nrm_zero
nrm_zero:
	move.w	LOCAL_EX(a0),d0
	cmp.w   #64,d0          ;see if exp > 64 
	bmi.s	d0_less
	bsr	nrm_set		;exp > 64 so exp won't exceed 0 
	rts
d0_less:
	movem.l	d2/d3/d5/d6,-(a7)
	move.l	LOCAL_HI(a0),d1
	move.l	LOCAL_LO(a0),d2

	bfffo	d1{0:32},d3	;get the distance to the first 1 
;				;in ms mant
	beq.s	ms_clr		;branch if no bits were set
	cmp.w	d3,d0		;of X>Y
	bmi.s	greater		;then exp will go past 0 (neg) if 
;				;it is just shifted
	bsr	nrm_set		;else exp won't go past 0
	movem.l	(a7)+,d2/d3/d5/d6
	rts	
greater:
	move.l	d2,d6		;save ls mant in d6
	lsl.l	d0,d2		;shift ls mant by count
	lsl.l	d0,d1		;shift ms mant by count
	move.l	#32,d5
	sub.l	d0,d5		;make op a denorm by shifting bits 
	lsr.l	d5,d6		;by the number in the exp, then 
;				;set exp = 0.
	or.l	d6,d1		;shift the ls mant bits into the ms mant
	move.l	#0,d0		;same as if decremented exp to 0 
;				;while shifting
	move.w	d0,LOCAL_EX(a0)
	move.l	d1,LOCAL_HI(a0)
	move.l	d2,LOCAL_LO(a0)
	movem.l	(a7)+,d2/d3/d5/d6
	rts
ms_clr:
	bfffo	d2{0:32},d3	;check if any bits set in ls mant
	beq.s	all_clr		;branch if none set
	add.w	#32,d3
	cmp.w	d3,d0		;if X>Y
	bmi.s	greater		;then branch
	bsr	nrm_set		;else exp won't go past 0
	movem.l	(a7)+,d2/d3/d5/d6
	rts
all_clr:
	move.w	#0,LOCAL_EX(a0)	;no mantissa bits set. Set exp = 0.
	movem.l	(a7)+,d2/d3/d5/d6
	rts
;
;	NRM_SET
;
	;|.global	nrm_set
nrm_set:
	move.l	d7,-(a7)
	bfffo	LOCAL_HI(a0){0:32},d7 ;find first 1 in ms mant to d7)
	beq.s	lower		;branch if ms mant is all 0's

	move.l	d6,-(a7)

	sub.w	d7,LOCAL_EX(a0)	;sub exponent by count
	move.l	LOCAL_HI(a0),d0	;d0 has ms mant
	move.l	LOCAL_LO(a0),d1 ;d1 has ls mant

	lsl.l	d7,d0		;shift first 1 to j bit position
	move.l	d1,d6		;copy ls mant into d6
	lsl.l	d7,d6		;shift ls mant by count
	move.l	d6,LOCAL_LO(a0)	;store ls mant into memory
	moveq.l	#32,d6
	sub.l	d7,d6		;continue shift
	lsr.l	d6,d1		;shift off all bits but those that will
;				;be shifted into ms mant
	or.l	d1,d0		;shift the ls mant bits into the ms mant
	move.l	d0,LOCAL_HI(a0)	;store ms mant into memory
	movem.l	(a7)+,d7/d6	;restore registers
	rts

;
; We get here if ms mant was = 0, and we assume ls mant has bits 
; set (otherwise this would have been tagged a zero not a denorm).
;
lower:
	move.w	LOCAL_EX(a0),d0	;d0 has exponent
	move.l	LOCAL_LO(a0),d1	;d1 has ls mant
	sub.w	#32,d0		;account for ms mant being all zeros
	bfffo	d1{0:32},d7	;find first 1 in ls mant to d7)
	sub.w	d7,d0		;subtract shift count from exp
	lsl.l	d7,d1		;shift first 1 to integer bit in ms mant
	move.w	d0,LOCAL_EX(a0)	;store ms mant
	move.l	d1,LOCAL_HI(a0)	;store exp
	clr.l	LOCAL_LO(a0)	;clear ls mant
	move.l	(a7)+,d7
	rts
;
;	denorm --- denormalize an intermediate result
;
;	Used by underflow.
;
; Input: 
;	a0	 points to the operand to be denormalized
;		 (in the internal extended format)
;		 
;	d0: 	 rounding precision
; Output:
;	a0	 points to the denormalized result
;		 (in the internal extended format)
;
;	d0 	is guard,round,sticky
;
; d0 comes into this routine with the rounding precision. It 
; is then loaded with the denormalized exponent threshold for the 
; rounding precision.
;

	;|.global	denorm
denorm:
	btst.b	#6,LOCAL_EX(a0)	;check for exponents between $7fff-$4000
	beq.s	no_sgn_ext	
	bset.b	#7,LOCAL_EX(a0)	;sign extend if it is so
no_sgn_ext:

	cmpi.b	#0,d0		;if 0 then extended precision
	bne.s	.not_ext		;else branch

	clr.l	d1		;load d1 with ext threshold
	clr.l	d0		;clear the sticky flag
	bsr	dnrm_lp		;denormalize the number
	tst.b	d1		;check for inex
	beq	no_inex		;if clr, no inex
	bra.s	dnrm_inex	;if set, set inex

.not_ext:
	cmpi.l	#1,d0		;if 1 then single precision
	beq.s	load_sgl	;else must be 2, double prec

load_dbl:
	move.w	#dbl_thresh,d1	;put copy of threshold in d1
	move.l	d1,d0		;copy d1 into d0
	sub.w	LOCAL_EX(a0),d0	;diff = threshold - exp
	cmp.w	#67,d0		;if diff > 67 (mant + grs bits)
	bpl.s	chk_stky	;then branch (all bits would be 
;				; shifted off in denorm routine)
	clr.l	d0		;else clear the sticky flag
	bsr	dnrm_lp		;denormalize the number
	tst.b	d1		;check flag
	beq.s	no_inex		;if clr, no inex
	bra.s	dnrm_inex	;if set, set inex

load_sgl:
	move.w	#sgl_thresh,d1	;put copy of threshold in d1
	move.l	d1,d0		;copy d1 into d0
	sub.w	LOCAL_EX(a0),d0	;diff = threshold - exp
	cmp.w	#67,d0		;if diff > 67 (mant + grs bits)
	bpl.s	chk_stky	;then branch (all bits would be 
;				; shifted off in denorm routine)
	clr.l	d0		;else clear the sticky flag
	bsr	dnrm_lp		;denormalize the number
	tst.b	d1		;check flag
	beq.s	no_inex		;if clr, no inex
	bra.s	dnrm_inex	;if set, set inex

chk_stky:
	tst.l	LOCAL_HI(a0)	;check for any bits set
	bne.s	set_stky
	tst.l	LOCAL_LO(a0)	;check for any bits set
	bne.s	set_stky
	bra.s	clr_mant
set_stky:
	or.l	#inx2a_mask,USER_FPSR(a6) ;set inex2/ainex
	move.l	#$20000000,d0	;set sticky bit in return value
clr_mant:
	move.w	d1,LOCAL_EX(a0)		;load exp with threshold
	move.l	#0,LOCAL_HI(a0) 	;set d1 = 0 (ms mantissa)
	move.l	#0,LOCAL_LO(a0)		;set d2 = 0 (ms mantissa)
	rts
dnrm_inex:
	or.l	#inx2a_mask,USER_FPSR(a6) ;set inex2/ainex
no_inex:
	rts

;
;	dnrm_lp --- normalize exponent/mantissa to specified threshold
;
; Input:
;	a0		points to the operand to be denormalized
;	d0{31:29} 	initial guard,round,sticky
;	d1{15:0}	denormalization threshold
; Output:
;	a0		points to the denormalized operand
;	d0{31:29}	final guard,round,sticky
;	d1.b		inexact flag:  all ones means inexact result
;
; The LOCAL_LO and LOCAL_GRS parts of the value are copied to FP_SCR2
; so that bfext can be used to extract the new low part of the mantissa.
; Dnrm_lp can be called with a0 pointing to ETEMP or WBTEMP and there 
; is no LOCAL_GRS scratch word following it on the fsave frame.
;
	;|.global	dnrm_lp
dnrm_lp:
	move.l	d2,-(sp)		;save d2 for temp use
	btst.b	#E3,E_BYTE(a6)		;test for type E3 exception
	beq.s	not_E3			;not type E3 exception
	bfextu	WBTEMP_GRS(a6){6:3},d2	;extract guard,round, sticky  bit
	move.l	#29,d0
	lsl.l	d0,d2			;shift g,r,s to their positions
	move.l	d2,d0
not_E3:
	move.l	(sp)+,d2		;restore d2
	move.l	LOCAL_LO(a0),FP_SCR2+LOCAL_LO(a6)
	move.l	d0,FP_SCR2+LOCAL_GRS(a6)
	move.l	d1,d0			;copy the denorm threshold
	sub.w	LOCAL_EX(a0),d1		;d1 = threshold - uns exponent
	ble.s	no_lp			;d1 <= 0
	cmp.w	#32,d1			
	blt.s	case_1			;0 = d1 < 32 
	cmp.w	#64,d1
	blt.s	case_2			;32 <= d1 < 64
	bra	case_3			;d1 >= 64
;
; No normalization necessary
;
no_lp:
	clr.b	d1			;set no inex2 reported
	move.l	FP_SCR2+LOCAL_GRS(a6),d0	;restore original g,r,s
	rts
;
; case (0<d1<32)
;
case_1:
	move.l	d2,-(sp)
	move.w	d0,LOCAL_EX(a0)		;exponent = denorm threshold
	move.l	#32,d0
	sub.w	d1,d0			;d0 = 32 - d1
	bfextu	LOCAL_EX(a0){d0:32},d2
	bfextu	d2{d1:d0},d2		;d2 = new LOCAL_HI
	bfextu	LOCAL_HI(a0){d0:32},d1	;d1 = new LOCAL_LO
	bfextu	FP_SCR2+LOCAL_LO(a6){d0:32},d0	;d0 = new G,R,S
	move.l	d2,LOCAL_HI(a0)		;store new LOCAL_HI
	move.l	d1,LOCAL_LO(a0)		;store new LOCAL_LO
	clr.b	d1
	bftst	d0{2:30}	
	beq.s	c1nstky
	bset.l	#rnd_stky_bit,d0
	st	d1
c1nstky:
	move.l	FP_SCR2+LOCAL_GRS(a6),d2	;restore original g,r,s
	andi.l	#$e0000000,d2		;clear all but G,R,S
	tst.l	d2			;test if original G,R,S are clear
	beq.s	grs_clear
	or.l	#$20000000,d0		;set sticky bit in d0
grs_clear:
	andi.l	#$e0000000,d0		;clear all but G,R,S
	move.l	(sp)+,d2
	rts
;
; case (32<=d1<64)
;
case_2:
	move.l	d2,-(sp)
	move.w	d0,LOCAL_EX(a0)		;unsigned exponent = threshold
	sub.w	#32,d1			;d1 now between 0 and 32
	move.l	#32,d0
	sub.w	d1,d0			;d0 = 32 - d1
	bfextu	LOCAL_EX(a0){d0:32},d2
	bfextu	d2{d1:d0},d2		;d2 = new LOCAL_LO
	bfextu	LOCAL_HI(a0){d0:32},d1	;d1 = new G,R,S
	bftst	d1{2:30}
	bne.s	c2_sstky		;bra if sticky bit to be set
	bftst	FP_SCR2+LOCAL_LO(a6){d0:32}
	bne.s	c2_sstky		;bra if sticky bit to be set
	move.l	d1,d0
	clr.b	d1
	bra.s	end_c2
c2_sstky:
	move.l	d1,d0
	bset.l	#rnd_stky_bit,d0
	st	d1
end_c2:
	clr.l	LOCAL_HI(a0)		;store LOCAL_HI = 0
	move.l	d2,LOCAL_LO(a0)		;store LOCAL_LO
	move.l	FP_SCR2+LOCAL_GRS(a6),d2	;restore original g,r,s
	andi.l	#$e0000000,d2		;clear all but G,R,S
	tst.l	d2			;test if original G,R,S are clear
	beq.s	clear_grs		
	or.l	#$20000000,d0		;set sticky bit in d0
clear_grs:
	andi.l	#$e0000000,d0		;get rid of all but G,R,S
	move.l	(sp)+,d2
	rts
;
; d1 >= 64 Force the exponent to be the denorm threshold with the
; correct sign.
;
case_3:
	move.w	d0,LOCAL_EX(a0)
	tst.w	LOCAL_SGN(a0)
	bge.s	c3con
c3neg:
	or.l	#$80000000,LOCAL_EX(a0)
c3con:
	cmp.w	#64,d1
	beq.s	sixty_four
	cmp.w	#65,d1
	beq.s	sixty_five
;
; Shift value is out of range.  Set d1 for inex2 flag and
; return a zero with the given threshold.
;
	clr.l	LOCAL_HI(a0)
	clr.l	LOCAL_LO(a0)
	move.l	#$20000000,d0
	st	d1
	rts

sixty_four:
	move.l	LOCAL_HI(a0),d0
	bfextu	d0{2:30},d1
	andi.l	#$c0000000,d0
	bra.s	c3com
	
sixty_five:
	move.l	LOCAL_HI(a0),d0
	bfextu	d0{1:31},d1
	andi.l	#$80000000,d0
	lsr.l	#1,d0			;shift high bit into R bit

c3com:
	tst.l	d1
	bne.s	c3ssticky
	tst.l	LOCAL_LO(a0)
	bne.s	c3ssticky
	tst.b	FP_SCR2+LOCAL_GRS(a6)
	bne.s	c3ssticky
	clr.b	d1
	bra.s	c3end

c3ssticky:
	bset.l	#rnd_stky_bit,d0
	st	d1
c3end:
	clr.l	LOCAL_HI(a0)
	clr.l	LOCAL_LO(a0)
	rts

	;end
;
;	skeleton.sa 3.2 4/26/91
;
;	This file contains code that is system dependent and will
;	need to be modified to install the FPSP.
;
;	Each entry point for exception 'xxxx' begins with a 'jmp fpsp_xxxx'.
;	Put any target system specific handling that must be done immediately
;	before the jump instruction.  If there no handling necessary, then
;	the 'fpsp_xxxx' handler entry point should be placed in the exception
;	table so that the 'jmp' can be eliminated. If the FPSP determines that the
;	exception is one that must be reported then there will be a
;	return from the package by a 'jmp real_xxxx'.  At that point
;	the machine state will be identical to the state before
;	the FPSP was entered.  In particular, whatever condition
;	that caused the exception will still be pending when the FPSP
;	package returns.  Thus, there will be system specific code
;	to handle the exception.
;
;	If the exception was completely handled by the package, then
;	the return will be via a 'jmp fpsp_done'.  Unless there is 
;	OS specific work to be done (such as handling a context switch or
;	interrupt) the user program can be resumed via 'rte'.
;
;	In the following skeleton code, some typical 'real_xxxx' handling
;	code is shown.  This code may need to be moved to an appropriate
;	place in the target system, or rewritten.
;	

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;
;	Modified for Linux-1.3.x by Jes Sorensen (jds@kom.auc.dk)
;



;SKELETON	idnt    2,1 ; Motorola 040 Floating Point Software Package

	

;
;	Divide by Zero exception
;
;	All dz exceptions are 'real', hence no fpsp_dz entry point.
;
	;|.global	_fpspEntry_dz
_fpspEntry_dz:
	link		a6,#-LOCAL_SIZE
	fsave		-(sp)
	bclr.b		#E1,E_BYTE(a6)
	frestore	(sp)+
	unlk		a6
	jmp		([M68040FPSPUserExceptionHandlers+3*4],za0)

;
;	Inexact exception
;
;	All inexact exceptions are real, but the 'real' handler
;	will probably want to clear the pending exception.
;	The provided code will clear the E3 exception (if pending), 
;	otherwise clear the E1 exception.  The frestore is not really
;	necessary for E1 exceptions.
;
; Code following the 'inex' label is to handle bug #1232.  In this
; bug, if an E1 snan, ovfl, or unfl occurred, and the process was
; swapped out before taking the exception, the exception taken on
; return was inex, rather than the correct exception.  The snan, ovfl,
; and unfl exception to be taken must not have been enabled.  The
; fix is to check for E1, and the existence of one of snan, ovfl,
; or unfl bits set in the fpsr.  If any of these are set, branch
; to the appropriate  handler for the exception in the fpsr.  Note
; that this fix is only for d43b parts, and is skipped if the
; version number is not $40.
; 
;
	;|.global	_fpspEntry_inex
	;|.global	real_inex
_fpspEntry_inex:
	link		a6,#-LOCAL_SIZE
	fsave		-(sp)
	cmpi.b		#VER_40,(sp)		;test version number
	bne.s		not_fmt40
	fmove.l		fpsr,-(sp)
	btst.b		#E1,E_BYTE(a6)		;test for E1 set
	beq.s		not_b1232
	btst.b		#snan_bit,2(sp) ;test for snan
	beq		inex_ckofl
	add.l		#4,sp
	frestore	(sp)+
	unlk		a6
	bra		snan
inex_ckofl:
	btst.b		#ovfl_bit,2(sp) ;test for ovfl
	beq		inex_ckufl 
	add.l		#4,sp
	frestore	(sp)+
	unlk		a6
	bra		_fpspEntry_ovfl
inex_ckufl:
	btst.b		#unfl_bit,2(sp) ;test for unfl
	beq		not_b1232
	add.l		#4,sp
	frestore	(sp)+
	unlk		a6
	bra		_fpspEntry_unfl

;
; We do not have the bug 1232 case.  Clean up the stack and call
; real_inex.
;
not_b1232:
	add.l		#4,sp
	frestore	(sp)+
	unlk		a6

real_inex:
	link		a6,#-LOCAL_SIZE
	fsave		-(sp)
not_fmt40:
	bclr.b		#E3,E_BYTE(a6)		;clear and test E3 flag
	beq.s		inex_cke1
;
; Clear dirty bit on dest resister in the frame before branching
; to b1238_fix.
;
	movem.l		d0/d1,USER_DA(a6)
	bfextu		CMDREG1B(a6){6:3},d0		;get dest reg no
	bclr.b		d0,FPR_DIRTY_BITS(a6)	;clr dest dirty bit
	bsr.l		b1238_fix		;test for bug1238 case
	movem.l		USER_DA(a6),d0/d1
	bra.s		inex_done
inex_cke1:
	bclr.b		#E1,E_BYTE(a6)
inex_done:
	frestore	(sp)+
	unlk		a6
	jmp	([M68040FPSPUserExceptionHandlers+2*4],za0)
	
;
;	Overflow exception
;
	;|.global	_fpspEntry_ovfl
	;|.global	real_ovfl
_fpspEntry_ovfl:
	bra	fpsp_ovfl
real_ovfl:
	link		a6,#-LOCAL_SIZE
	fsave		-(sp)
	bclr.b		#E3,E_BYTE(a6)		;clear and test E3 flag
	bne.s		ovfl_done
	bclr.b		#E1,E_BYTE(a6)
ovfl_done:
	frestore	(sp)+
	unlk		a6
	jmp	([M68040FPSPUserExceptionHandlers+6*4],za0)
	
;
;	Underflow exception
;
	;|.global	_fpspEntry_unfl
	;|.global	real_unfl
_fpspEntry_unfl:
	bra	fpsp_unfl
real_unfl:
	link		a6,#-LOCAL_SIZE
	fsave		-(sp)
	bclr.b		#E3,E_BYTE(a6)		;clear and test E3 flag
	bne.s		.unfl_done
	bclr.b		#E1,E_BYTE(a6)
.unfl_done:
	frestore	(sp)+
	unlk		a6
	jmp	([M68040FPSPUserExceptionHandlers+4*4],za0)
	
;
;	Signalling NAN exception
;
	;|.global	_fpspEntry_snan
	;|.global	real_snan
_fpspEntry_snan:
snan:
	bra	fpsp_snan
real_snan:
	link		a6,#-LOCAL_SIZE
	fsave		-(sp)
	bclr.b		#E1,E_BYTE(a6)	;snan is always an E1 exception
	frestore	(sp)+
	unlk		a6
	jmp	([M68040FPSPUserExceptionHandlers+7*4],za0)

;
;	Operand Error exception
;
	;|.global	_fpspEntry_operr
	;|.global	real_operr
_fpspEntry_operr:
	bra	fpsp_operr
real_operr:
	link		a6,#-LOCAL_SIZE
	fsave		-(sp)
	bclr.b		#E1,E_BYTE(a6)	;operr is always an E1 exception
	frestore	(sp)+
	unlk		a6
	jmp	([M68040FPSPUserExceptionHandlers+5*4],za0)
	
;
;	BSUN exception
;
;	This sample handler simply clears the nan bit in the FPSR.
;
	;|.global	_fpspEntry_bsun
	;|.global	real_bsun
_fpspEntry_bsun:
	bra	fpsp_bsun
real_bsun:
	link		a6,#-LOCAL_SIZE
	fsave		-(sp)
	bclr.b		#E1,E_BYTE(a6)	;bsun is always an E1 exception
	fmove.l		FPSR,-(sp)
	bclr.b		#nan_bit,(sp)
	fmove.l		(sp)+,FPSR
	frestore	(sp)+
	unlk		a6
	jmp	([M68040FPSPUserExceptionHandlers+1*4],za0)

;
;	F-line exception
;
;	A 'real' F-line exception is one that the FPSP is not supposed to 
;	handle. E.g. an instruction with a co-processor ID that is not 1.
;
	;|.global	_fpspEntry_fline
	;|.global	real_fline
_fpspEntry_fline:
	bra	fpsp_fline
real_fline:
	jmp	([M68040FPSPUserExceptionHandlers+0*4],za0)

;
;	Unsupported data type exception
;
	;|.global	_fpspEntry_unsupp
	;|.global	real_unsupp
_fpspEntry_unsupp:
	bra	fpsp_unsupp
real_unsupp:
	link		a6,#-LOCAL_SIZE
	fsave		-(sp)
	bclr.b		#E1,E_BYTE(a6)	;unsupp is always an E1 exception
	frestore	(sp)+
	unlk		a6
	jmp	([M68040FPSPUserExceptionHandlers+8*4],za0)

;
;	Trace exception
;
	;|.global	real_trace
real_trace:
	trap	#10

;
;	fpsp_fmt_error --- exit point for frame format error
;
;	The fpu stack frame does not match the frames existing
;	or planned at the time of this writing.  The fpsp is
;	unable to handle frame sizes not in the following
;	version:size pairs:
;
;	{4060, 4160} - busy frame
;	{4028, 4130} - unimp frame
;	{4000, 4100} - idle frame
;
	;|.global	fpsp_fmt_error
fpsp_fmt_error:
	trap	#11

;
;	fpsp_done --- FPSP exit point
;
;	The exception has been handled by the package and we are ready
;	to return to user mode, but there may be OS specific code
;	to execute before we do.  If there is, do it now.
;
; For now, the RTEMS does not bother looking at the
; possibility that it is time to reschedule....
;

	;|.global	fpsp_done
fpsp_done:
	rte

;
;	mem_write --- write to user or supervisor address space
;
; Writes to memory while in supervisor mode.
;
;	a0 - supervisor source address
;	a1 - user/supervisor destination address
;	d0 - number of bytes to write (maximum count is 12)
;
	;|.global	mem_write
mem_write:
	btst.b	#5,EXC_SR(a6)	;check for supervisor state
	beq.s	user_write
super_write:
	move.b	(a0)+,(a1)+
	subq.l	#1,d0
	bne.s	super_write
	rts
user_write:
	move.l	d1,-(sp)	;preserve d1 just in case
	move.l	d0,-(sp)
	move.l	a1,-(sp)
	move.l	a0,-(sp)
	bsr		copyout
	add.w	#12,sp
	move.l	(sp)+,d1
	rts
;
;	mem_read --- read from user or supervisor address space
;
; Reads from memory while in supervisor mode.
;
; The FPSP calls mem_read to read the original F-line instruction in order
; to extract the data register number when the 'Dn' addressing mode is
; used.
;
;Input:
;	a0 - user/supervisor source address
;	a1 - supervisor destination address
;	d0 - number of bytes to read (maximum count is 12)
;
; Like mem_write, mem_read always reads with a supervisor 
; destination address on the supervisor stack.  Also like mem_write,
; the EXC_SR is checked and a simple memory copy is done if reading
; from supervisor space is indicated.
;
	;|.global	mem_read
mem_read:
	btst.b	#5,EXC_SR(a6)	;check for supervisor state
	beq.s	user_read
super_read:
	move.b	(a0)+,(a1)+
	subq.l	#1,d0
	bne.s	super_read
	rts
user_read:
	move.l	d1,-(sp)	;preserve d1 just in case
	move.l	d0,-(sp)
	move.l	a1,-(sp)
	move.l	a0,-(sp)
	bsr		copyin
	add.w	#12,sp
	move.l	(sp)+,d1
	rts

;
; Use these routines if your kernel does not have copyout/copyin equivalents.
; Assumes that D0/D1/A0/A1 are scratch registers. copyout overwrites DFC,
; and copyin overwrites SFC.
;
copyout:
	move.l	4(sp),a0	; source
	move.l	8(sp),a1	; destination
	move.l	12(sp),d0	; count
	sub.l	#1,d0		; dec count by 1 for dbra
	move.l	#1,d1
	movec	d1,DFC		; set dfc for user data space
moreout:
	move.b	(a0)+,d1	; fetch supervisor byte
	moves.b	d1,(a1)+	; write user byte
	dbf	d0,moreout
	rts

copyin:
	move.l	4(sp),a0	; source
	move.l	8(sp),a1	; destination
	move.l	12(sp),d0	; count
	sub.l	#1,d0		; dec count by 1 for dbra
	move.l	#1,d1
	movec	d1,SFC		; set sfc for user space
morein:
	moves.b	(a0)+,d1	; fetch user byte
	move.b	d1,(a1)+	; write supervisor byte
	dbf	d0,morein
	rts

	;end
;
;	sacos.sa 3.3 12/19/90
;
;	Description: The entry point sAcos computes the inverse cosine of
;		an input argument; sAcosd does the same except for denormalized
;		input.
;
;	Input: Double-extended number X in location pointed to
;		by address register a0.
;
;	Output: The value arccos(X) returned in floating-point register Fp0.
;
;	Accuracy and Monotonicity: The returned result is within 3 ulps in
;		64 significant bit, i.e. within 0.5001 ulp to 53 bits if the
;		result is subsequently rounded to double precision. The 
;		result is provably monotonic in double precision.
;
;	Speed: The program sCOS takes approximately 310 cycles.
;
;	Algorithm:
;
;	ACOS
;	1. If |X; >= 1, go to 3.
;
;	2. (|X; < 1) Calculate acos(X) by
;		z := (1-X) / (1+X)
;		acos(X) = 2 * atan( sqrt(z) ).
;		Exit.
;
;	3. If |X; > 1, go to 5.
;
;	4. (|X; = 1) If X > 0, return 0. Otherwise, return Pi. Exit.
;
;	5. (|X; > 1) Generate an invalid operation by 0 * infinity.
;		Exit.
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;SACOS	idnt	2,1 ; Motorola 040 Floating Point Software Package

	;section	8

PI:	dc.l $40000000,$C90FDAA2,$2168C235,$00000000
PIBY2:	dc.l $3FFF0000,$C90FDAA2,$2168C235,$00000000

	;xref	t_operr
	;xref	t_frcinx
	;xref	satan

	;|.global	sacosd
sacosd:
;--ACOS(X) = PI/2 FOR DENORMALIZED X
	fmove.l		d1,fpcr		; ...load user's rounding mode/precision
	fmove.x		PIBY2(pc),fp0
	bra		t_frcinx

	;|.global	sacos
sacos:
	fmove.x		(a0),fp0	; ...LOAD INPUT

	move.l		(a0),d0		; ...pack exponent with upper 16 fraction
	move.w		4(a0),d0
	andi.l		#$7FFFFFFF,d0
	cmpi.l		#$3FFF8000,d0
	bge.s		ACOSBIG

;--THIS IS THE USUAL CASE, |X; < 1
;--ACOS(X) = 2 * ATAN(	SQRT( (1-X)/(1+X) )	)

	fmove.s		#$3F800000,fp1
	fadd.x		fp0,fp1	 	; ...1+X
	fneg.x		fp0	 	; ... -X
	fadd.s		#$3F800000,fp0	; ...1-X
	fdiv.x		fp1,fp0	 	; ...(1-X)/(1+X)
	fsqrt.x		fp0		; ...SQRT((1-X)/(1+X))
	fmovem.x	fp0-fp0,(a0)	; ...overwrite input
	move.l		d1,-(sp)	;save original users fpcr
	clr.l		d1
	bsr		satan		; ...ATAN(SQRT([1-X]/[1+X]))
	fmove.l		(sp)+,fpcr	;restore users exceptions
	fadd.x		fp0,fp0	 	; ...2 * ATAN( STUFF )
	bra		t_frcinx

ACOSBIG:
	fabs.x		fp0
	fcmp.s		#$3F800000,fp0
	fbgt		t_operr		;cause an operr exception

;--|X; = 1, ACOS(X) = 0 OR PI
	move.l		(a0),d0		; ...pack exponent with upper 16 fraction
	move.w		4(a0),d0
	cmp.l		#0,d0		;D0 has original exponent+fraction
	bgt.s		ACOSP1

;--X = -1
;Returns PI and inexact exception
	fmove.x		PI(pc),fp0
	fmove.l		d1,FPCR
	fadd.s		#$00800000,fp0	;cause an inexact exception to be put
;					;into the 040 - will not trap until next
;					;fp inst.
	bra		t_frcinx

ACOSP1:
	fmove.l		d1,FPCR
	fmove.s		#$00000000,fp0
	rts				;Facos ; of +1 is exact	

	;end
;
;	sasin.sa 3.3 12/19/90
;
;	Description: The entry point sAsin computes the inverse sine of
;		an input argument; sAsind does the same except for denormalized
;		input.
;
;	Input: Double-extended number X in location pointed to
;		by address register a0.
;
;	Output: The value arcsin(X) returned in floating-point register Fp0.
;
;	Accuracy and Monotonicity: The returned result is within 3 ulps in
;		64 significant bit, i.e. within 0.5001 ulp to 53 bits if the
;		result is subsequently rounded to double precision. The 
;		result is provably monotonic in double precision.
;
;	Speed: The program sASIN takes approximately 310 cycles.
;
;	Algorithm:
;
;	ASIN
;	1. If |X; >= 1, go to 3.
;
;	2. (|X; < 1) Calculate asin(X) by
;		z := sqrt( [1-X][1+X] )
;		asin(X) = atan( x / z ).
;		Exit.
;
;	3. If |X; > 1, go to 5.
;
;	4. (|X; = 1) sgn := sign(X), return asin(X) := sgn * Pi/2. Exit.
;
;	5. (|X; > 1) Generate an invalid operation by 0 * infinity.
;		Exit.
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;SASIN	idnt	2,1 ; Motorola 040 Floating Point Software Package

	;section	8

;PIBY2:	dc.l $3FFF0000,$C90FDAA2,$2168C235,$00000000

	;xref	t_operr
	;xref	t_frcinx
	;xref	t_extdnrm
	;xref	satan

	;|.global	sasind
sasind:
;--ASIN(X) = X FOR DENORMALIZED X

	bra		t_extdnrm

	;|.global	sasin
sasin:
	fmove.x		(a0),fp0	; ...LOAD INPUT

	move.l		(a0),d0
	move.w		4(a0),d0
	andi.l		#$7FFFFFFF,d0
	cmpi.l		#$3FFF8000,d0
	bge.s		asinbig

;--THIS IS THE USUAL CASE, |X; < 1
;--ASIN(X) = ATAN( X / SQRT( (1-X)(1+X) ) )

	fmove.s		#$3F800000,fp1
	fsub.x		fp0,fp1		; ...1-X
	fmovem.x	fp2-fp2,-(a7)
	fmove.s		#$3F800000,fp2
	fadd.x		fp0,fp2		; ...1+X
	fmul.x		fp2,fp1		; ...(1+X)(1-X)
	fmovem.x	(a7)+,fp2-fp2
	fsqrt.x		fp1		; ...SQRT([1-X][1+X])
	fdiv.x		fp1,fp0	 	; ...X/SQRT([1-X][1+X])
	fmovem.x	fp0-fp0,(a0)
	bsr		satan
	bra		t_frcinx

asinbig:
	fabs.x		fp0	 ; ...|X; 	fcmp.s		#$3F800000,fp0
	fbgt		t_operr		;cause an operr exception

;--|X; = 1, ASIN(X) = +- PI/2.

	fmove.x		PIBY2(pc),fp0
	move.l		(a0),d0
	andi.l		#$80000000,d0	; ...SIGN BIT OF X
	ori.l		#$3F800000,d0	; ...+-1 IN SGL FORMAT
	move.l		d0,-(sp)	; ...push SIGN(X) IN SGL-FMT
	fmove.l		d1,FPCR		
	fmul.s		(sp)+,fp0
	bra		t_frcinx

	;end
;
;	satan.sa 3.3 12/19/90
;
;	The entry point satan computes the arctangent of an
;	input value. satand does the same except the input value is a
;	denormalized number.
;
;	Input: Double-extended value in memory location pointed to by address
;		register a0.
;
;	Output:	Arctan(X) returned in floating-point register Fp0.
;
;	Accuracy and Monotonicity: The returned result is within 2 ulps in
;		64 significant bit, i.e. within 0.5001 ulp to 53 bits if the
;		result is subsequently rounded to double precision. The
;		result is provably monotonic in double precision.
;
;	Speed: The program satan takes approximately 160 cycles for input
;		argument X such that 1/16 < |X; < 16. For the other arguments,
;		the program will run no worse than 10% slower.
;
;	Algorithm:
;	Step 1. If |X; >= 16 or |X; < 1/16, go to Step 5.
;
;	Step 2. Let X = sgn * 2**k * 1.xxxxxxxx...x. Note that k = -4, -3,..., or 3.
;		Define F = sgn * 2**k * 1.xxxx1, i.e. the first 5 significant bits
;		of X with a bit-1 attached at the 6-th bit position. Define u
;		to be u = (X-F) / (1 + X*F).
;
;	Step 3. Approximate arctan(u) by a polynomial poly.
;
;	Step 4. Return arctan(F) + poly, arctan(F) is fetched from a table of values
;		calculated beforehand. Exit.
;
;	Step 5. If |X; >= 16, go to Step 7.
;
;	Step 6. Approximate arctan(X) by an odd polynomial in X. Exit.
;
;	Step 7. Define X' = -1/X. Approximate arctan(X') by an odd polynomial in X'.
;		Arctan(X) = sign(X)*Pi/2 + arctan(X'). Exit.
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;satan	idnt	2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	
	
BOUNDS1:	dc.l $3FFB8000,$4002FFFF

ONE:	dc.l $3F800000

	dc.l $00000000

ATANA3:	dc.l $BFF6687E,$314987D8
ATANA2:	dc.l $4002AC69,$34A26DB3

ATANA1:	dc.l $BFC2476F,$4E1DA28E
ATANB6:	dc.l $3FB34444,$7F876989

ATANB5:	dc.l $BFB744EE,$7FAF45DB
ATANB4:	dc.l $3FBC71C6,$46940220

ATANB3:	dc.l $BFC24924,$921872F9
ATANB2:	dc.l $3FC99999,$99998FA9

ATANB1:	dc.l $BFD55555,$55555555
ATANC5:	dc.l $BFB70BF3,$98539E6A

ATANC4:	dc.l $3FBC7187,$962D1D7D
ATANC3:	dc.l $BFC24924,$827107B8

ATANC2:	dc.l $3FC99999,$9996263E
ATANC1:	dc.l $BFD55555,$55555536

PPIBY2:	dc.l $3FFF0000,$C90FDAA2,$2168C235,$00000000
NPIBY2:	dc.l $BFFF0000,$C90FDAA2,$2168C235,$00000000
PTINY:	dc.l $00010000,$80000000,$00000000,$00000000
NTINY:	dc.l $80010000,$80000000,$00000000,$00000000

ATANTBL:
	dc.l	$3FFB0000,$83D152C5,$060B7A51,$00000000
	dc.l	$3FFB0000,$8BC85445,$65498B8B,$00000000
	dc.l	$3FFB0000,$93BE4060,$17626B0D,$00000000
	dc.l	$3FFB0000,$9BB3078D,$35AEC202,$00000000
	dc.l	$3FFB0000,$A3A69A52,$5DDCE7DE,$00000000
	dc.l	$3FFB0000,$AB98E943,$62765619,$00000000
	dc.l	$3FFB0000,$B389E502,$F9C59862,$00000000
	dc.l	$3FFB0000,$BB797E43,$6B09E6FB,$00000000
	dc.l	$3FFB0000,$C367A5C7,$39E5F446,$00000000
	dc.l	$3FFB0000,$CB544C61,$CFF7D5C6,$00000000
	dc.l	$3FFB0000,$D33F62F8,$2488533E,$00000000
	dc.l	$3FFB0000,$DB28DA81,$62404C77,$00000000
	dc.l	$3FFB0000,$E310A407,$8AD34F18,$00000000
	dc.l	$3FFB0000,$EAF6B0A8,$188EE1EB,$00000000
	dc.l	$3FFB0000,$F2DAF194,$9DBE79D5,$00000000
	dc.l	$3FFB0000,$FABD5813,$61D47E3E,$00000000
	dc.l	$3FFC0000,$8346AC21,$0959ECC4,$00000000
	dc.l	$3FFC0000,$8B232A08,$304282D8,$00000000
	dc.l	$3FFC0000,$92FB70B8,$D29AE2F9,$00000000
	dc.l	$3FFC0000,$9ACF476F,$5CCD1CB4,$00000000
	dc.l	$3FFC0000,$A29E7630,$4954F23F,$00000000
	dc.l	$3FFC0000,$AA68C5D0,$8AB85230,$00000000
	dc.l	$3FFC0000,$B22DFFFD,$9D539F83,$00000000
	dc.l	$3FFC0000,$B9EDEF45,$3E900EA5,$00000000
	dc.l	$3FFC0000,$C1A85F1C,$C75E3EA5,$00000000
	dc.l	$3FFC0000,$C95D1BE8,$28138DE6,$00000000
	dc.l	$3FFC0000,$D10BF300,$840D2DE4,$00000000
	dc.l	$3FFC0000,$D8B4B2BA,$6BC05E7A,$00000000
	dc.l	$3FFC0000,$E0572A6B,$B42335F6,$00000000
	dc.l	$3FFC0000,$E7F32A70,$EA9CAA8F,$00000000
	dc.l	$3FFC0000,$EF888432,$64ECEFAA,$00000000
	dc.l	$3FFC0000,$F7170A28,$ECC06666,$00000000
	dc.l	$3FFD0000,$812FD288,$332DAD32,$00000000
	dc.l	$3FFD0000,$88A8D1B1,$218E4D64,$00000000
	dc.l	$3FFD0000,$9012AB3F,$23E4AEE8,$00000000
	dc.l	$3FFD0000,$976CC3D4,$11E7F1B9,$00000000
	dc.l	$3FFD0000,$9EB68949,$3889A227,$00000000
	dc.l	$3FFD0000,$A5EF72C3,$4487361B,$00000000
	dc.l	$3FFD0000,$AD1700BA,$F07A7227,$00000000
	dc.l	$3FFD0000,$B42CBCFA,$FD37EFB7,$00000000
	dc.l	$3FFD0000,$BB303A94,$0BA80F89,$00000000
	dc.l	$3FFD0000,$C22115C6,$FCAEBBAF,$00000000
	dc.l	$3FFD0000,$C8FEF3E6,$86331221,$00000000
	dc.l	$3FFD0000,$CFC98330,$B4000C70,$00000000
	dc.l	$3FFD0000,$D6807AA1,$102C5BF9,$00000000
	dc.l	$3FFD0000,$DD2399BC,$31252AA3,$00000000
	dc.l	$3FFD0000,$E3B2A855,$6B8FC517,$00000000
	dc.l	$3FFD0000,$EA2D764F,$64315989,$00000000
	dc.l	$3FFD0000,$F3BF5BF8,$BAD1A21D,$00000000
	dc.l	$3FFE0000,$801CE39E,$0D205C9A,$00000000
	dc.l	$3FFE0000,$8630A2DA,$DA1ED066,$00000000
	dc.l	$3FFE0000,$8C1AD445,$F3E09B8C,$00000000
	dc.l	$3FFE0000,$91DB8F16,$64F350E2,$00000000
	dc.l	$3FFE0000,$97731420,$365E538C,$00000000
	dc.l	$3FFE0000,$9CE1C8E6,$A0B8CDBA,$00000000
	dc.l	$3FFE0000,$A22832DB,$CADAAE09,$00000000
	dc.l	$3FFE0000,$A746F2DD,$B7602294,$00000000
	dc.l	$3FFE0000,$AC3EC0FB,$997DD6A2,$00000000
	dc.l	$3FFE0000,$B110688A,$EBDC6F6A,$00000000
	dc.l	$3FFE0000,$B5BCC490,$59ECC4B0,$00000000
	dc.l	$3FFE0000,$BA44BC7D,$D470782F,$00000000
	dc.l	$3FFE0000,$BEA94144,$FD049AAC,$00000000
	dc.l	$3FFE0000,$C2EB4ABB,$661628B6,$00000000
	dc.l	$3FFE0000,$C70BD54C,$E602EE14,$00000000
	dc.l	$3FFE0000,$CD000549,$ADEC7159,$00000000
	dc.l	$3FFE0000,$D48457D2,$D8EA4EA3,$00000000
	dc.l	$3FFE0000,$DB948DA7,$12DECE3B,$00000000
	dc.l	$3FFE0000,$E23855F9,$69E8096A,$00000000
	dc.l	$3FFE0000,$E8771129,$C4353259,$00000000
	dc.l	$3FFE0000,$EE57C16E,$0D379C0D,$00000000
	dc.l	$3FFE0000,$F3E10211,$A87C3779,$00000000
	dc.l	$3FFE0000,$F919039D,$758B8D41,$00000000
	dc.l	$3FFE0000,$FE058B8F,$64935FB3,$00000000
	dc.l	$3FFF0000,$8155FB49,$7B685D04,$00000000
	dc.l	$3FFF0000,$83889E35,$49D108E1,$00000000
	dc.l	$3FFF0000,$859CFA76,$511D724B,$00000000
	dc.l	$3FFF0000,$87952ECF,$FF8131E7,$00000000
	dc.l	$3FFF0000,$89732FD1,$9557641B,$00000000
	dc.l	$3FFF0000,$8B38CAD1,$01932A35,$00000000
	dc.l	$3FFF0000,$8CE7A8D8,$301EE6B5,$00000000
	dc.l	$3FFF0000,$8F46A39E,$2EAE5281,$00000000
	dc.l	$3FFF0000,$922DA7D7,$91888487,$00000000
	dc.l	$3FFF0000,$94D19FCB,$DEDF5241,$00000000
	dc.l	$3FFF0000,$973AB944,$19D2A08B,$00000000
	dc.l	$3FFF0000,$996FF00E,$08E10B96,$00000000
	dc.l	$3FFF0000,$9B773F95,$12321DA7,$00000000
	dc.l	$3FFF0000,$9D55CC32,$0F935624,$00000000
	dc.l	$3FFF0000,$9F100575,$006CC571,$00000000
	dc.l	$3FFF0000,$A0A9C290,$D97CC06C,$00000000
	dc.l	$3FFF0000,$A22659EB,$EBC0630A,$00000000
	dc.l	$3FFF0000,$A388B4AF,$F6EF0EC9,$00000000
	dc.l	$3FFF0000,$A4D35F10,$61D292C4,$00000000
	dc.l	$3FFF0000,$A60895DC,$FBE3187E,$00000000
	dc.l	$3FFF0000,$A72A51DC,$7367BEAC,$00000000
	dc.l	$3FFF0000,$A83A5153,$0956168F,$00000000
	dc.l	$3FFF0000,$A93A2007,$7539546E,$00000000
	dc.l	$3FFF0000,$AA9E7245,$023B2605,$00000000
	dc.l	$3FFF0000,$AC4C84BA,$6FE4D58F,$00000000
	dc.l	$3FFF0000,$ADCE4A4A,$606B9712,$00000000
	dc.l	$3FFF0000,$AF2A2DCD,$8D263C9C,$00000000
	dc.l	$3FFF0000,$B0656F81,$F22265C7,$00000000
	dc.l	$3FFF0000,$B1846515,$0F71496A,$00000000
	dc.l	$3FFF0000,$B28AAA15,$6F9ADA35,$00000000
	dc.l	$3FFF0000,$B37B44FF,$3766B895,$00000000
	dc.l	$3FFF0000,$B458C3DC,$E9630433,$00000000
	dc.l	$3FFF0000,$B525529D,$562246BD,$00000000
	dc.l	$3FFF0000,$B5E2CCA9,$5F9D88CC,$00000000
	dc.l	$3FFF0000,$B692CADA,$7ACA1ADA,$00000000
	dc.l	$3FFF0000,$B736AEA7,$A6925838,$00000000
	dc.l	$3FFF0000,$B7CFAB28,$7E9F7B36,$00000000
	dc.l	$3FFF0000,$B85ECC66,$CB219835,$00000000
	dc.l	$3FFF0000,$B8E4FD5A,$20A593DA,$00000000
	dc.l	$3FFF0000,$B99F41F6,$4AFF9BB5,$00000000
	dc.l	$3FFF0000,$BA7F1E17,$842BBE7B,$00000000
	dc.l	$3FFF0000,$BB471285,$7637E17D,$00000000
	dc.l	$3FFF0000,$BBFABE8A,$4788DF6F,$00000000
	dc.l	$3FFF0000,$BC9D0FAD,$2B689D79,$00000000
	dc.l	$3FFF0000,$BD306A39,$471ECD86,$00000000
	dc.l	$3FFF0000,$BDB6C731,$856AF18A,$00000000
	dc.l	$3FFF0000,$BE31CAC5,$02E80D70,$00000000
	dc.l	$3FFF0000,$BEA2D55C,$E33194E2,$00000000
	dc.l	$3FFF0000,$BF0B10B7,$C03128F0,$00000000
	dc.l	$3FFF0000,$BF6B7A18,$DACB778D,$00000000
	dc.l	$3FFF0000,$BFC4EA46,$63FA18F6,$00000000
	dc.l	$3FFF0000,$C0181BDE,$8B89A454,$00000000
	dc.l	$3FFF0000,$C065B066,$CFBF6439,$00000000
	dc.l	$3FFF0000,$C0AE345F,$56340AE6,$00000000
	dc.l	$3FFF0000,$C0F22291,$9CB9E6A7,$00000000
X = FP_SCR1
XDCARE1 = X+2
XFRAC1 = X+4
XFRACLO = X+8
ATANF = FP_SCR2
ATANFHI = ATANF+4
ATANFLO = ATANF+8


	; xref	t_frcinx
	;xref	t_extdnrm

	;|.global	satand
satand:
;--ENTRY POINT FOR ATAN(X) FOR DENORMALIZED ARGUMENT

	bra		t_extdnrm

	;|.global	satan
satan:
;--ENTRY POINT FOR ATAN(X), HERE X IS FINITE, NON-ZERO, AND NOT NAN'S

	fmove.x		(a0),fp0	; ...LOAD INPUT

	move.l		(a0),d0
	move.w		4(a0),d0
	fmove.x		fp0,X(a6)
	andi.l		#$7FFFFFFF,d0

	cmpi.l		#$3FFB8000,d0		; ...|X; >= 1/16?
	bge.s		ATANOK1
	bra		ATANSM

ATANOK1:
	cmpi.l		#$4002FFFF,d0		; ...|X; < 16 ?
	ble.s		ATANMAIN
	bra		ATANBIG


;--THE MOST LIKELY CASE, |X; IN [1/16, 16). WE USE TABLE TECHNIQUE
;--THE IDEA IS ATAN(X) = ATAN(F) + ATAN( [X-F] / [1+XF] ).
;--SO IF F IS CHOSEN TO BE CLOSE TO X AND ATAN(F) IS STORED IN
;--A TABLE, ALL WE NEED IS TO APPROXIMATE ATAN(U) WHERE
;--U = (X-F)/(1+XF) IS SMALL (REMEMBER F IS CLOSE TO X). IT IS
;--TRUE THAT A DIVIDE IS NOW NEEDED, BUT THE APPROXIMATION FOR
;--ATAN(U) IS A VERY SHORT POLYNOMIAL AND THE INDEXING TO
;--FETCH F AND SAVING OF REGISTERS CAN BE ALL HIDED UNDER THE
;--DIVIDE. IN THE END THIS METHOD IS MUCH FASTER THAN A TRADITIONAL
;--ONE. NOTE ALSO THAT THE TRADITIONAL SCHEME THAT APPROXIMATE
;--ATAN(X) DIRECTLY WILL NEED TO USE A RATIONAL APPROXIMATION
;--(DIVISION NEEDED) ANYWAY BECAUSE A POLYNOMIAL APPROXIMATION
;--WILL INVOLVE A VERY LONG POLYNOMIAL.

;--NOW WE SEE X AS +-2^K * 1.BBBBBBB....B <- 1. + 63 BITS
;--WE CHOSE F TO BE +-2^K * 1.BBBB1
;--THAT IS IT MATCHES THE EXPONENT AND FIRST 5 BITS OF X, THE
;--SIXTH BITS IS SET TO BE 1. SINCE K = -4, -3, ..., 3, THERE
;--ARE ONLY 8 TIMES 16 = 2^7 = 128 |F|'S. SINCE ATAN(-|F|) IS
;-- -ATAN(|F|), WE NEED TO STORE ONLY ATAN(|F|).

ATANMAIN:

	move.w		#$0000,XDCARE1(a6)	; ...CLEAN UP X JUST IN CASE
	andi.l		#$F8000000,XFRAC1(a6)	; ...FIRST 5 BITS
	ori.l		#$04000000,XFRAC1(a6)	; ...SET 6-TH BIT TO 1
	move.l		#$00000000,XFRACLO(a6)	; ...LOCATION OF X IS NOW F

	fmove.x		fp0,fp1			; ...FP1 IS X
	fmul.x		X(a6),fp1		; ...FP1 IS X*F, NOTE THAT X*F > 0
	fsub.x		X(a6),fp0		; ...FP0 IS X-F
	fadd.s		#$3F800000,fp1		; ...FP1 IS 1 + X*F
	fdiv.x		fp1,fp0			; ...FP0 IS U = (X-F)/(1+X*F)

;--WHILE THE DIVISION IS TAKING ITS TIME, WE FETCH ATAN(|F|)
;--CREATE ATAN(F) AND STORE IT IN ATANF, AND
;--SAVE REGISTERS FP2.

	move.l		d2,-(a7)	; ...SAVE d2 TEMPORARILY
	move.l		d0,d2		; ...THE EXPO AND 16 BITS OF X
	andi.l		#$00007800,d0	; ...4 VARYING BITS OF F'S FRACTION
	andi.l		#$7FFF0000,d2	; ...EXPONENT OF F
	subi.l		#$3FFB0000,d2	; ...K+4
	asr.l		#1,d2
	add.l		d2,d0		; ...THE 7 BITS IDENTIFYING F
	asr.l		#7,d0		; ...INDEX INTO TBL OF ATAN(|F|)
	lea		ATANTBL(pc),a1
	adda.l		d0,a1		; ...ADDRESS OF ATAN(|F|)
	move.l		(a1)+,ATANF(a6)
	move.l		(a1)+,ATANFHI(a6)
	move.l		(a1)+,ATANFLO(a6)	; ...ATANF IS NOW ATAN(|F|)
	move.l		X(a6),d0		; ...LOAD SIGN AND EXPO. AGAIN
	andi.l		#$80000000,d0	; ...SIGN(F)
	or.l		d0,ATANF(a6)	; ...ATANF IS NOW SIGN(F)*ATAN(|F|)
	move.l		(a7)+,d2	; ...RESTORE d2

;--THAT'S ALL I HAVE TO DO FOR NOW,
;--BUT ALAS, THE DIVIDE IS STILL CRANKING!

;--U IN FP0, WE ARE NOW READY TO COMPUTE ATAN(U) AS
;--U + A1*U*V*(A2 + V*(A3 + V)), V = U*U
;--THE POLYNOMIAL MAY LOOK STRANGE, BUT IS NEVERTHELESS CORRECT.
;--THE NATURAL FORM IS U + U*V*(A1 + V*(A2 + V*A3))
;--WHAT WE HAVE HERE IS MERELY	A1 = A3, A2 = A1/A3, A3 = A2/A3.
;--THE REASON FOR THIS REARRANGEMENT IS TO MAKE THE INDEPENDENT
;--PARTS A1*U*V AND (A2 + ... STUFF) MORE LOAD-BALANCED

	
	fmove.x		fp0,fp1
	fmul.x		fp1,fp1
	fmove.d		ATANA3(pc),fp2
	fadd.x		fp1,fp2		; ...A3+V
	fmul.x		fp1,fp2		; ...V*(A3+V)
	fmul.x		fp0,fp1		; ...U*V
	fadd.d		ATANA2(pc),fp2	; ...A2+V*(A3+V)
	fmul.d		ATANA1(pc),fp1	; ...A1*U*V
	fmul.x		fp2,fp1		; ...A1*U*V*(A2+V*(A3+V))
	
	fadd.x		fp1,fp0		; ...ATAN(U), FP1 RELEASED
	fmove.l		d1,FPCR		;restore users exceptions
	fadd.x		ATANF(a6),fp0	; ...ATAN(X)
	bra		t_frcinx

ATANBORS:
;--|X; IS IN d0 IN COMPACT FORM. FP1, d0 SAVED.
;--FP0 IS X AND |X; <= 1/16 OR |X; >= 16.
	cmpi.l		#$3FFF8000,d0
	bgt		ATANBIG	; ...I.E. |X; >= 16

ATANSM:
;--|X; <= 1/16
;--IF |X; < 2^(-40), RETURN X AS ANSWER. OTHERWISE, APPROXIMATE
;--ATAN(X) BY X + X*Y*(B1+Y*(B2+Y*(B3+Y*(B4+Y*(B5+Y*B6)))))
;--WHICH IS X + X*Y*( [B1+Z*(B3+Z*B5)] + [Y*(B2+Z*(B4+Z*B6)] )
;--WHERE Y = X*X, AND Z = Y*Y.

	cmpi.l		#$3FD78000,d0
	blt		ATANTINY
;--COMPUTE POLYNOMIAL
	fmul.x		fp0,fp0	; ...FP0 IS Y = X*X

	
	move.w		#$0000,XDCARE1(a6)

	fmove.x		fp0,fp1
	fmul.x		fp1,fp1		; ...FP1 IS Z = Y*Y

	fmove.d		ATANB6(pc),fp2
	fmove.d		ATANB5(pc),fp3

	fmul.x		fp1,fp2		; ...Z*B6
	fmul.x		fp1,fp3		; ...Z*B5

	fadd.d		ATANB4(pc),fp2	; ...B4+Z*B6
	fadd.d		ATANB3(pc),fp3	; ...B3+Z*B5

	fmul.x		fp1,fp2		; ...Z*(B4+Z*B6)
	fmul.x		fp3,fp1		; ...Z*(B3+Z*B5)

	fadd.d		ATANB2(pc),fp2	; ...B2+Z*(B4+Z*B6)
	fadd.d		ATANB1(pc),fp1	; ...B1+Z*(B3+Z*B5)

	fmul.x		fp0,fp2		; ...Y*(B2+Z*(B4+Z*B6))
	fmul.x		X(a6),fp0		; ...X*Y

	fadd.x		fp2,fp1		; ...[B1+Z*(B3+Z*B5)]+[Y*(B2+Z*(B4+Z*B6))]
	

	fmul.x		fp1,fp0	; ...X*Y*([B1+Z*(B3+Z*B5)]+[Y*(B2+Z*(B4+Z*B6))])

	fmove.l		d1,FPCR		;restore users exceptions
	fadd.x		X(a6),fp0

	bra		t_frcinx

ATANTINY:
;--|X; < 2^(-40), ATAN(X) = X
	move.w		#$0000,XDCARE1(a6)

	fmove.l		d1,FPCR		;restore users exceptions
	fmove.x		X(a6),fp0	;last inst - possible exception set

	bra		t_frcinx

ATANBIG:
;--IF |X; > 2^(100), RETURN	SIGN(X)*(PI/2 - TINY). OTHERWISE,
;--RETURN SIGN(X)*PI/2 + ATAN(-1/X).
	cmpi.l		#$40638000,d0
	bgt		ATANHUGE

;--APPROXIMATE ATAN(-1/X) BY
;--X'+X'*Y*(C1+Y*(C2+Y*(C3+Y*(C4+Y*C5)))), X' = -1/X, Y = X'*X'
;--THIS CAN BE RE-WRITTEN AS
;--X'+X'*Y*( [C1+Z*(C3+Z*C5)] + [Y*(C2+Z*C4)] ), Z = Y*Y.

	fmove.s		#$BF800000,fp1	; ...LOAD -1
	fdiv.x		fp0,fp1		; ...FP1 IS -1/X

	
;--DIVIDE IS STILL CRANKING

	fmove.x		fp1,fp0		; ...FP0 IS X'
	fmul.x		fp0,fp0		; ...FP0 IS Y = X'*X'
	fmove.x		fp1,X(a6)		; ...X IS REALLY X'

	fmove.x		fp0,fp1
	fmul.x		fp1,fp1		; ...FP1 IS Z = Y*Y

	fmove.d		ATANC5(pc),fp3
	fmove.d		ATANC4(pc),fp2

	fmul.x		fp1,fp3		; ...Z*C5
	fmul.x		fp1,fp2		; ...Z*B4

	fadd.d		ATANC3(pc),fp3	; ...C3+Z*C5
	fadd.d		ATANC2(pc),fp2	; ...C2+Z*C4

	fmul.x		fp3,fp1		; ...Z*(C3+Z*C5), FP3 RELEASED
	fmul.x		fp0,fp2		; ...Y*(C2+Z*C4)

	fadd.d		ATANC1(pc),fp1	; ...C1+Z*(C3+Z*C5)
	fmul.x		X(a6),fp0		; ...X'*Y

	fadd.x		fp2,fp1		; ...[Y*(C2+Z*C4)]+[C1+Z*(C3+Z*C5)]
	

	fmul.x		fp1,fp0		; ...X'*Y*([B1+Z*(B3+Z*B5)]
;					...	+[Y*(B2+Z*(B4+Z*B6))])
	fadd.x		X(a6),fp0

	fmove.l		d1,FPCR		;restore users exceptions
	
	btst.b		#7,(a0)
	beq.s		pos_big

neg_big:
	fadd.x		NPIBY2(pc),fp0
	bra		t_frcinx

pos_big:
	fadd.x		PPIBY2(pc),fp0
	bra		t_frcinx

ATANHUGE:
;--RETURN SIGN(X)*(PIBY2 - TINY) = SIGN(X)*PIBY2 - SIGN(X)*TINY
	btst.b		#7,(a0)
	beq.s		pos_huge

neg_huge:
	fmove.x		NPIBY2(pc),fp0
	fmove.l		d1,fpcr
	fsub.x		NTINY(pc),fp0
	bra		t_frcinx

pos_huge:
	fmove.x		PPIBY2(pc),fp0
	fmove.l		d1,fpcr
	fsub.x		PTINY(pc),fp0
	bra		t_frcinx
	
	;end
;
;	satanh.sa 3.3 12/19/90
;
;	The entry point satanh computes the inverse
;	hyperbolic tangent of
;	an input argument; satanhd does the same except for denormalized
;	input.
;
;	Input: Double-extended number X in location pointed to
;		by address register a0.
;
;	Output: The value arctanh(X) returned in floating-point register Fp0.
;
;	Accuracy and Monotonicity: The returned result is within 3 ulps in
;		64 significant bit, i.e. within 0.5001 ulp to 53 bits if the
;		result is subsequently rounded to double precision. The 
;		result is provably monotonic in double precision.
;
;	Speed: The program satanh takes approximately 270 cycles.
;
;	Algorithm:
;
;	ATANH
;	1. If |X; >= 1, go to 3.
;
;	2. (|X; < 1) Calculate atanh(X) by
;		sgn := sign(X)
;		y := |X; ;		z := 2y/(1-y)
;		atanh(X) := sgn * (1/2) * logp1(z)
;		Exit.
;
;	3. If |X; > 1, go to 5.
;
;	4. (|X; = 1) Generate infinity with an appropriate sign and
;		divide-by-zero by	
;		sgn := sign(X)
;		atan(X) := sgn / (+0).
;		Exit.
;
;	5. (|X; > 1) Generate an invalid operation by 0 * infinity.
;		Exit.
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;satanh	idnt	2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	;xref	t_dz
	;xref	t_operr
	;xref	t_frcinx
	;xref	t_extdnrm
	;xref	slognp1

	;|.global	satanhd
satanhd:
;--ATANH(X) = X FOR DENORMALIZED X

	bra		t_extdnrm

	;|.global	satanh
satanh:
	move.l		(a0),d0
	move.w		4(a0),d0
	andi.l		#$7FFFFFFF,d0
	cmpi.l		#$3FFF8000,d0
	bge.s		ATANHBIG

;--THIS IS THE USUAL CASE, |X; < 1
;--Y = |X|, Z = 2Y/(1-Y), ATANH(X) = SIGN(X) * (1/2) * LOG1P(Z).

	fabs.x		(a0),fp0	; ...Y = |X; 	fmove.x		fp0,fp1
	fneg.x		fp1		; ...-Y
	fadd.x		fp0,fp0		; ...2Y
	fadd.s		#$3F800000,fp1	; ...1-Y
	fdiv.x		fp1,fp0		; ...2Y/(1-Y)
	move.l		(a0),d0
	andi.l		#$80000000,d0
	ori.l		#$3F000000,d0	; ...SIGN(X)*HALF
	move.l		d0,-(sp)

	fmovem.x	fp0-fp0,(a0)	; ...overwrite input
	move.l		d1,-(sp)
	clr.l		d1
	bsr		slognp1		; ...LOG1P(Z)
	fmove.l		(sp)+,fpcr
	fmul.s		(sp)+,fp0
	bra		t_frcinx

ATANHBIG:
	fabs.x		(a0),fp0	; ...|X; 	fcmp.s		#$3F800000,fp0
	fbgt		t_operr
	bra		t_dz

	;end
;
;	scale.sa 3.3 7/30/91
;
;	The entry point sSCALE computes the destination operand
;	scaled by the source operand.  If the absolute value of
;	the source operand is (>= 2^14) an overflow or underflow
;	is returned.
;
;	The entry point sscale is called from do_func to emulate
;	the fscale unimplemented instruction.
;
;	Input: Double-extended destination operand in FPTEMP, 
;		double-extended source operand in ETEMP.
;
;	Output: The function returns scale(X,Y) to fp0.
;
;	Modifies: fp0.
;
;	Algorithm:
;		
;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;SCALE    idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	

	;xref	t_ovfl2
	;xref	t_unfl
	;xref	round
	;xref	t_resdnrm

SRC_BNDS: dc.w	$3fff,$400c

;
; This entry point is used by the unimplemented instruction exception
; handler.
;
;
;
;	FSCALE
;
	;|.global	sscale
sscale:
	fmove.l		#0,fpcr		;clr user enabled exc
	clr.l		d1
	move.w		FPTEMP(a6),d1	;get dest exponent
	smi		L_SCR1(a6)	;use L_SCR1 to hold sign
	andi.l		#$7fff,d1	;strip sign
	move.w		ETEMP(a6),d0	;check src bounds
	andi.w		#$7fff,d0	;clr sign bit
	cmp2.w		SRC_BNDS,d0
	bcc.s		src_in
	cmpi.w		#$400c,d0	;test for too large
	bge		src_out
;
; The source input is below 1, so we check for denormalized numbers
; and set unfl.
;
src_small:
	move.b		DTAG(a6),d0
	andi.b		#$e0,d0
	tst.b		d0
	beq.s		no_denorm
	st		STORE_FLG(a6)	;dest already contains result
	or.l		#unfl_mask,USER_FPSR(a6) ;set UNFL
den_done:
	lea.l		FPTEMP(a6),a0
	bra		t_resdnrm
no_denorm:
	fmove.l		USER_FPCR(a6),FPCR
	fmove.x		FPTEMP(a6),fp0	;simply return dest
	rts


;
; Source is within 2^14 range.  To perform the int operation,
; move it to d0.
;
src_in:
	fmove.x		ETEMP(a6),fp0	;move in src for int
	fmove.l		#rz_mode,fpcr	;force rz for src conversion
	fmove.l		fp0,d0		;int src to d0
	fmove.l		#0,FPSR		;clr status from above
	tst.w		ETEMP(a6)	;check src sign
	blt		src_neg
;
; Source is positive.  Add the src to the dest exponent.
; The result can be denormalized, if src = 0, or overflow,
; if the result of the add sets a bit in the upper word.
;
src_pos:
	tst.w		d1		;check for denorm
	beq		dst_dnrm
	add.l		d0,d1		;add src to dest exp
	beq.s		denorm_		;if zero, result is denorm
	cmpi.l		#$7fff,d1	;test for overflow
	bge.s		ovfl
	tst.b		L_SCR1(a6)
	beq.s		spos_pos
	or.w		#$8000,d1
spos_pos:
	move.w		d1,FPTEMP(a6)	;result in FPTEMP
	fmove.l		USER_FPCR(a6),FPCR
	fmove.x		FPTEMP(a6),fp0	;write result to fp0
	rts
ovfl:
	tst.b		L_SCR1(a6)
	beq.s		sovl_pos
	or.w		#$8000,d1
sovl_pos:
	move.w		FPTEMP(a6),ETEMP(a6)	;result in ETEMP
	move.l		FPTEMP_HI(a6),ETEMP_HI(a6)
	move.l		FPTEMP_LO(a6),ETEMP_LO(a6)
	bra		t_ovfl2

denorm_:
	tst.b		L_SCR1(a6)
	beq.s		den_pos
	or.w		#$8000,d1
den_pos:
	tst.l		FPTEMP_HI(a6)	;check j bit
	blt.s		nden_exit	;if set, not denorm
	move.w		d1,ETEMP(a6)	;input expected in ETEMP
	move.l		FPTEMP_HI(a6),ETEMP_HI(a6)
	move.l		FPTEMP_LO(a6),ETEMP_LO(a6)
	or.l		#unfl_bit,USER_FPSR(a6)	;set unfl
	lea.l		ETEMP(a6),a0
	bra		t_resdnrm
nden_exit:
	move.w		d1,FPTEMP(a6)	;result in FPTEMP
	fmove.l		USER_FPCR(a6),FPCR
	fmove.x		FPTEMP(a6),fp0	;write result to fp0
	rts

;
; Source is negative.  Add the src to the dest exponent.
; (The result exponent will be reduced).  The result can be
; denormalized.
;
src_neg:
	add.l		d0,d1		;add src to dest
	beq.s		denorm_		;if zero, result is denorm
	blt.s		fix_dnrm	;if negative, result is 
;					;needing denormalization
	tst.b		L_SCR1(a6)
	beq.s		sneg_pos
	or.w		#$8000,d1
sneg_pos:
	move.w		d1,FPTEMP(a6)	;result in FPTEMP
	fmove.l		USER_FPCR(a6),FPCR
	fmove.x		FPTEMP(a6),fp0	;write result to fp0
	rts


;
; The result exponent is below denorm value.  Test for catastrophic
; underflow and force zero if true.  If not, try to shift the 
; mantissa right until a zero exponent exists.
;
fix_dnrm:
	cmpi.w		#$ffc0,d1	;lower bound for normalization
	blt		fix_unfl	;if lower, catastrophic unfl
	move.w		d1,d0		;use d0 for exp
	move.l		d2,-(a7)	;free d2 for norm
	move.l		FPTEMP_HI(a6),d1
	move.l		FPTEMP_LO(a6),d2
	clr.l		L_SCR2(a6)
fix_loop:
	add.w		#1,d0		;drive d0 to 0
	lsr.l		#1,d1		;while shifting the
	roxr.l		#1,d2		;mantissa to the right
	bcc.s		no_carry
	st		L_SCR2(a6)	;use L_SCR2 to capture inex
no_carry:
	tst.w		d0		;it is finished when
	blt.s		fix_loop	;d0 is zero or the mantissa
	tst.b		L_SCR2(a6)
	beq.s		tst_zero
	or.l		#unfl_inx_mask,USER_FPSR(a6)
;					;set unfl, aunfl, ainex
;
; Test for zero. If zero, simply use fmove to return +/- zero
; to the fpu.
;
tst_zero:
	clr.w		FPTEMP_EX(a6)
	tst.b		L_SCR1(a6)	;test for sign
	beq.s		tst_con
	or.w		#$8000,FPTEMP_EX(a6) ;set sign bit
tst_con:
	move.l		d1,FPTEMP_HI(a6)
	move.l		d2,FPTEMP_LO(a6)
	move.l		(a7)+,d2
	tst.l		d1
	bne.s		not_zero
	tst.l		FPTEMP_LO(a6)
	bne.s		not_zero
;
; Result is zero.  Check for rounding mode to set lsb.  If the
; mode is rp, and the zero is positive, return smallest denorm.
; If the mode is rm, and the zero is negative, return smallest
; negative denorm.
;
	btst.b		#5,FPCR_MODE(a6) ;test if rm or rp
	beq.s		no_dir
	btst.b		#4,FPCR_MODE(a6) ;check which one
	beq.s		zer_rm
zer_rp:
	tst.b		L_SCR1(a6)	;check sign
	bne.s		no_dir		;if set, neg op, no inc
	move.l		#1,FPTEMP_LO(a6) ;set lsb
	bra.s		sm_dnrm
zer_rm:
	tst.b		L_SCR1(a6)	;check sign
	beq.s		no_dir		;if clr, neg op, no inc
	move.l		#1,FPTEMP_LO(a6) ;set lsb
	or.l		#neg_mask,USER_FPSR(a6) ;set N
	bra.s		sm_dnrm
no_dir:
	fmove.l		USER_FPCR(a6),FPCR
	fmove.x		FPTEMP(a6),fp0	;use fmove to set cc's
	rts

;
; The rounding mode changed the zero to a smallest denorm. Call 
; t_resdnrm with exceptional operand in ETEMP.
;
sm_dnrm:
	move.l		FPTEMP_EX(a6),ETEMP_EX(a6)
	move.l		FPTEMP_HI(a6),ETEMP_HI(a6)
	move.l		FPTEMP_LO(a6),ETEMP_LO(a6)
	lea.l		ETEMP(a6),a0
	bra		t_resdnrm

;
; Result is still denormalized.
;
not_zero:
	or.l		#unfl_mask,USER_FPSR(a6) ;set unfl
	tst.b		L_SCR1(a6)	;check for sign
	beq.s		fix_exit
	or.l		#neg_mask,USER_FPSR(a6) ;set N
fix_exit:
	bra.s		sm_dnrm

	
;
; The result has underflowed to zero. Return zero and set
; unfl, aunfl, and ainex.
;
fix_unfl:
	or.l		#unfl_inx_mask,USER_FPSR(a6)
	btst.b		#5,FPCR_MODE(a6) ;test if rm or rp
	beq.s		no_dir2
	btst.b		#4,FPCR_MODE(a6) ;check which one
	beq.s		zer_rm2
zer_rp2:
	tst.b		L_SCR1(a6)	;check sign
	bne.s		no_dir2		;if set, neg op, no inc
	clr.l		FPTEMP_EX(a6)
	clr.l		FPTEMP_HI(a6)
	move.l		#1,FPTEMP_LO(a6) ;set lsb
	bra.s		sm_dnrm		;return smallest denorm
zer_rm2:
	tst.b		L_SCR1(a6)	;check sign
	beq.s		no_dir2		;if clr, neg op, no inc
	move.w		#$8000,FPTEMP_EX(a6)
	clr.l		FPTEMP_HI(a6)
	move.l		#1,FPTEMP_LO(a6) ;set lsb
	or.l		#neg_mask,USER_FPSR(a6) ;set N
	bra		sm_dnrm		;return smallest denorm

no_dir2:
	tst.b		L_SCR1(a6)
	bge.s		pos_zero_
neg_zero:
	clr.l		FP_SCR1(a6)	;clear the exceptional operand
	clr.l		FP_SCR1+4(a6)	;for gen_except.
	clr.l		FP_SCR1+8(a6)
	fmove.s		#$80000000,fp0	
	rts
pos_zero_:
	clr.l		FP_SCR1(a6)	;clear the exceptional operand
	clr.l		FP_SCR1+4(a6)	;for gen_except.
	clr.l		FP_SCR1+8(a6)
	fmove.s		#$00000000,fp0
	rts

;
; The destination is a denormalized number.  It must be handled
; by first shifting the bits in the mantissa until it is normalized,
; then adding the remainder of the source to the exponent.
;
dst_dnrm:
	movem.l		d2/d3,-(a7)	
	move.w		FPTEMP_EX(a6),d1
	move.l		FPTEMP_HI(a6),d2
	move.l		FPTEMP_LO(a6),d3
dst_loop:
	tst.l		d2		;test for normalized result
	blt.s		dst_norm	;exit loop if so
	tst.l		d0		;otherwise, test shift count
	beq.s		dst_fin		;if zero, shifting is done
	subi.l		#1,d0		;dec src
	lsl.l		#1,d3
	roxl.l		#1,d2
	bra.s		dst_loop
;
; Destination became normalized.  Simply add the remaining 
; portion of the src to the exponent.
;
dst_norm:
	add.w		d0,d1		;dst is normalized; add src
	tst.b		L_SCR1(a6)
	beq.s		dnrm_pos
	or.l		#$8000,d1
dnrm_pos:
	movem.w		d1,FPTEMP_EX(a6)
	movem.l		d2,FPTEMP_HI(a6)
	movem.l		d3,FPTEMP_LO(a6)
	fmove.l		USER_FPCR(a6),FPCR
	fmove.x		FPTEMP(a6),fp0
	movem.l		(a7)+,d2/d3
	rts

;
; Destination remained denormalized.  Call t_excdnrm with
; exceptional operand in ETEMP.
;
dst_fin:
	tst.b		L_SCR1(a6)	;check for sign
	beq.s		dst_exit
	or.l		#neg_mask,USER_FPSR(a6) ;set N
	or.l		#$8000,d1
dst_exit:
	movem.w		d1,ETEMP_EX(a6)
	movem.l		d2,ETEMP_HI(a6)
	movem.l		d3,ETEMP_LO(a6)
	or.l		#unfl_mask,USER_FPSR(a6) ;set unfl
	movem.l		(a7)+,d2/d3
	lea.l		ETEMP(a6),a0
	bra		t_resdnrm

;
; Source is outside of 2^14 range.  Test the sign and branch
; to the appropriate exception handler.
;
src_out:
	tst.b		L_SCR1(a6)
	beq.s		scro_pos
	or.l		#$8000,d1
scro_pos:
	move.l		FPTEMP_HI(a6),ETEMP_HI(a6)
	move.l		FPTEMP_LO(a6),ETEMP_LO(a6)
	tst.w		ETEMP(a6)
	blt.s		res_neg
res_pos:
	move.w		d1,ETEMP(a6)	;result in ETEMP
	bra		t_ovfl2
res_neg:
	move.w		d1,ETEMP(a6)	;result in ETEMP
	lea.l		ETEMP(a6),a0
	bra		t_unfl
	;end
;
;	scosh.sa 3.1 12/10/90
;
;	The entry point sCosh computes the hyperbolic cosine of
;	an input argument; sCoshd does the same except for denormalized
;	input.
;
;	Input: Double-extended number X in location pointed to
;		by address register a0.
;
;	Output: The value cosh(X) returned in floating-point register Fp0.
;
;	Accuracy and Monotonicity: The returned result is within 3 ulps in
;		64 significant bit, i.e. within 0.5001 ulp to 53 bits if the
;		result is subsequently rounded to double precision. The
;		result is provably monotonic in double precision.
;
;	Speed: The program sCOSH takes approximately 250 cycles.
;
;	Algorithm:
;
;	COSH
;	1. If |X; > 16380 log2, go to 3.
;
;	2. (|X; <= 16380 log2) Cosh(X) is obtained by the formulae
;		y = |X|, z = exp(Y), and
;		cosh(X) = (1/2)*( z + 1/z ).
;		Exit.
;
;	3. (|X; > 16380 log2). If |X; > 16480 log2, go to 5.
;
;	4. (16380 log2 < |X; <= 16480 log2)
;		cosh(X) = sign(X) * exp(|X|)/2.
;		However, invoking exp(|X|) may cause premature overflow.
;		Thus, we calculate sinh(X) as follows:
;		Y	:= |X; ;		Fact	:=	2**(16380)
;		Y'	:= Y - 16381 log2
;		cosh(X) := Fact * exp(Y').
;		Exit.
;
;	5. (|X; > 16480 log2) sinh(X) must overflow. Return
;		Huge*Huge to generate overflow and an infinity with
;		the appropriate sign. Huge is the largest finite number in
;		extended format. Exit.
;
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;SCOSH	idnt	2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	;xref	t_ovfl
	;xref	t_frcinx
	;xref	setox

;T1:	dc.l $40C62D38,$D3D64634 ; ... 16381 LOG2 LEAD
;T2:	dc.l $3D6F90AE,$B1E75CC7 ; ... 16381 LOG2 TRAIL

TWO16380: dc.l $7FFB0000,$80000000,$00000000,$00000000

	;|.global	scoshd
scoshd:
;--COSH(X) = 1 FOR DENORMALIZED X

	fmove.s		#$3F800000,fp0

	fmove.l		d1,FPCR
	fadd.s		#$00800000,fp0
	bra		t_frcinx

	;|.global	scosh
scosh:
	fmove.x		(a0),fp0	; ...LOAD INPUT

	move.l		(a0),d0
	move.w		4(a0),d0
	andi.l		#$7FFFFFFF,d0
	cmpi.l		#$400CB167,d0
	bgt.s		COSHBIG

;--THIS IS THE USUAL CASE, |X; < 16380 LOG2
;--COSH(X) = (1/2) * ( EXP(X) + 1/EXP(X) )

	fabs.x		fp0		; ...|X; 
	move.l		d1,-(sp)
	clr.l		d1
	fmovem.x	fp0-fp0,(a0)	;pass parameter to setox
	bsr		setox		; ...FP0 IS EXP(|X|)
	fmul.s		#$3F000000,fp0	; ...(1/2)EXP(|X|)
	move.l		(sp)+,d1

	fmove.s		#$3E800000,fp1	; ...(1/4)
	fdiv.x		fp0,fp1	 	; ...1/(2 EXP(|X|))

	fmove.l		d1,FPCR
	fadd.x		fp1,fp0

	bra		t_frcinx

COSHBIG:
	cmpi.l		#$400CB2B3,d0
	bgt.s		COSHHUGE

	fabs.x		fp0
	fsub.d		T1(pc),fp0		; ...(|X|-16381LOG2_LEAD)
	fsub.d		T2(pc),fp0		; ...|X; - 16381 LOG2, ACCURATE

	move.l		d1,-(sp)
	clr.l		d1
	fmovem.x	fp0-fp0,(a0)
	bsr		setox
	fmove.l		(sp)+,fpcr

	fmul.x		TWO16380(pc),fp0
	bra		t_frcinx

COSHHUGE:
	fmove.l		#0,fpsr		;clr N bit if set by source
	bclr.b		#7,(a0)		;always return positive value
	fmovem.x	(a0),fp0-fp0
	bra		t_ovfl

	;end
;
;	setox.sa 3.1 12/10/90
;
;	The entry point setox computes the exponential of a value.
;	setoxd does the same except the input value is a denormalized
;	number.	setoxm1 computes exp(X)-1, and setoxm1d computes
;	exp(X)-1 for denormalized X.
;
;	INPUT
;	-----
;	Double-extended value in memory location pointed to by address
;	register a0.
;
;	OUTPUT
;	------
;	exp(X) or exp(X)-1 returned in floating-point register fp0.
;
;	ACCURACY and MONOTONICITY
;	-------------------------
;	The returned result is within 0.85 ulps in 64 significant bit, i.e.
;	within 0.5001 ulp to 53 bits if the result is subsequently rounded
;	to double precision. The result is provably monotonic in double
;	precision.
;
;	SPEED
;	-----
;	Two timings are measured, both in the copy-back mode. The
;	first one is measured when the function is invoked the first time
;	(so the instructions and data are not in cache), and the
;	second one is measured when the function is reinvoked at the same
;	input argument.
;
;	The program setox takes approximately 210/190 cycles for input
;	argument X whose magnitude is less than 16380 log2, which
;	is the usual situation.	For the less common arguments,
;	depending on their values, the program may run faster or slower --
;	but no worse than 10% slower even in the extreme cases.
;
;	The program setoxm1 takes approximately ???/??? cycles for input
;	argument X, 0.25 <= |X; < 70log2. For |X; < 0.25, it takes
;	approximately ???/??? cycles. For the less common arguments,
;	depending on their values, the program may run faster or slower --
;	but no worse than 10% slower even in the extreme cases.
;
;	ALGORITHM and IMPLEMENTATION NOTES
;	----------------------------------
;
;	setoxd
;	------
;	Step 1.	Set ans := 1.0
;
;	Step 2.	Return	ans := ans + sign(X)*2^(-126). Exit.
;	Notes:	This will always generate one exception -- inexact.
;
;
;	setox
;	-----
;
;	Step 1.	Filter out extreme cases of input argument.
;		1.1	If |X; >= 2^(-65), go to Step 1.3.
;		1.2	Go to Step 7.
;		1.3	If |X; < 16380 log(2), go to Step 2.
;		1.4	Go to Step 8.
;	Notes:	The usual case should take the branches 1.1 -> 1.3 -> 2.
;		 To avoid the use of floating-point comparisons, a
;		 compact representation of |X; is used. This format is a
;		 32-bit integer, the upper (more significant) 16 bits are
;		 the sign and biased exponent field of |X|; the lower 16
;		 bits are the 16 most significant fraction (including the
;		 explicit bit) bits of |X|. Consequently, the comparisons
;		 in Steps 1.1 and 1.3 can be performed by integer comparison.
;		 Note also that the constant 16380 log(2) used in Step 1.3
;		 is also in the compact form. Thus taking the branch
;		 to Step 2 guarantees |X; < 16380 log(2). There is no harm
;		 to have a small number of cases where |X; is less than,
;		 but close to, 16380 log(2) and the branch to Step 9 is
;		 taken.
;
;	Step 2.	Calculate N = round-to-nearest-int( X * 64/log2 ).
;		2.1	Set AdjFlag := 0 (indicates the branch 1.3 -> 2 was taken)
;		2.2	N := round-to-nearest-integer( X * 64/log2 ).
;		2.3	Calculate	J = N mod 64; so J = 0,1,2,..., or 63.
;		2.4	Calculate	M = (N - J)/64; so N = 64M + J.
;		2.5	Calculate the address of the stored value of 2^(J/64).
;		2.6	Create the value Scale = 2^M.
;	Notes:	The calculation in 2.2 is really performed by
;
;			Z := X * constant
;			N := round-to-nearest-integer(Z)
;
;		 where
;
;			constant := single-precision( 64/log 2 ).
;
;		 Using a single-precision constant avoids memory access.
;		 Another effect of using a single-precision "constant" is
;		 that the calculated value Z is
;
;			Z = X*(64/log2)*(1+eps), |eps; <= 2^(-24).
;
;		 This error has to be considered later in Steps 3 and 4.
;
;	Step 3.	Calculate X - N*log2/64.
;		3.1	R := X + N*L1, where L1 := single-precision(-log2/64).
;		3.2	R := R + N*L2, L2 := extended-precision(-log2/64 - L1).
;	Notes:	a) The way L1 and L2 are chosen ensures L1+L2 approximate
;		 the value	-log2/64	to 88 bits of accuracy.
;		 b) N*L1 is exact because N is no longer than 22 bits and
;		 L1 is no longer than 24 bits.
;		 c) The calculation X+N*L1 is also exact due to cancellation.
;		 Thus, R is practically X+N(L1+L2) to full 64 bits.
;		 d) It is important to estimate how large can |R; be after
;		 Step 3.2.
;
;			N = rnd-to-int( X*64/log2 (1+eps) ), |eps|<=2^(-24)
;			X*64/log2 (1+eps)	=	N + f,	|f; <= 0.5
;			X*64/log2 - N	=	f - eps*X 64/log2
;			X - N*log2/64	=	f*log2/64 - eps*X
;
;
;		 Now |X; <= 16446 log2, thus
;
;			|X - N*log2/64; <= (0.5 + 16446/2^(18))*log2/64
;					<= 0.57 log2/64.
;		 This bound will be used in Step 4.
;
;	Step 4.	Approximate exp(R)-1 by a polynomial
;			p = R + R*R*(A1 + R*(A2 + R*(A3 + R*(A4 + R*A5))))
;	Notes:	a) In order to reduce memory access, the coefficients are
;		 made as "short" as possible: A1 (which is 1/2), A4 and A5
;		 are single precision; A2 and A3 are double precision.
;		 b) Even with the restrictions above,
;			|p - (exp(R)-1); < 2^(-68.8) for all |R; <= 0.0062.
;		 Note that 0.0062 is slightly bigger than 0.57 log2/64.
;		 c) To fully utilize the pipeline, p is separated into
;		 two independent pieces of roughly equal complexities
;			p = [ R + R*S*(A2 + S*A4) ]	+
;				[ S*(A1 + S*(A3 + S*A5)) ]
;		 where S = R*R.
;
;	Step 5.	Compute 2^(J/64)*exp(R) = 2^(J/64)*(1+p) by
;				ans := T + ( T*p + t)
;		 where T and t are the stored values for 2^(J/64).
;	Notes:	2^(J/64) is stored as T and t where T+t approximates
;		 2^(J/64) to roughly 85 bits; T is in extended precision
;		 and t is in single precision. Note also that T is rounded
;		 to 62 bits so that the last two bits of T are zero. The
;		 reason for such a special form is that T-1, T-2, and T-8
;		 will all be exact --- a property that will give much
;		 more accurate computation of the function EXPM1.
;
;	Step 6.	Reconstruction of exp(X)
;			exp(X) = 2^M * 2^(J/64) * exp(R).
;		6.1	If AdjFlag = 0, go to 6.3
;		6.2	ans := ans * AdjScale
;		6.3	Restore the user FPCR
;		6.4	Return ans := ans * Scale. Exit.
;	Notes:	If AdjFlag = 0, we have X = Mlog2 + Jlog2/64 + R,
;		 |M; <= 16380, and Scale = 2^M. Moreover, exp(X) will
;		 neither overflow nor underflow. If AdjFlag = 1, that
;		 means that
;			X = (M1+M)log2 + Jlog2/64 + R, |M1+M; >= 16380.
;		 Hence, exp(X) may overflow or underflow or neither.
;		 When that is the case, AdjScale = 2^(M1) where M1 is
;		 approximately M. Thus 6.2 will never cause over/underflow.
;		 Possible exception in 6.4 is overflow or underflow.
;		 The inexact exception is not generated in 6.4. Although
;		 one can argue that the inexact flag should always be
;		 raised, to simulate that exception cost to much than the
;		 flag is worth in practical uses.
;
;	Step 7.	Return 1 + X.
;		7.1	ans := X
;		7.2	Restore user FPCR.
;		7.3	Return ans := 1 + ans. Exit
;	Notes:	For non-zero X, the inexact exception will always be
;		 raised by 7.3. That is the only exception raised by 7.3.
;		 Note also that we use the FMOVEM instruction to move X
;		 in Step 7.1 to avoid unnecessary trapping. (Although
;		 the FMOVEM may not seem relevant since X is normalized,
;		 the precaution will be useful in the library version of
;		 this code where the separate entry for denormalized inputs
;		 will be done away with.)
;
;	Step 8.	Handle exp(X) where |X; >= 16380log2.
;		8.1	If |X; > 16480 log2, go to Step 9.
;		(mimic 2.2 - 2.6)
;		8.2	N := round-to-integer( X * 64/log2 )
;		8.3	Calculate J = N mod 64, J = 0,1,...,63
;		8.4	K := (N-J)/64, M1 := truncate(K/2), M = K-M1, AdjFlag := 1.
;		8.5	Calculate the address of the stored value 2^(J/64).
;		8.6	Create the values Scale = 2^M, AdjScale = 2^M1.
;		8.7	Go to Step 3.
;	Notes:	Refer to notes for 2.2 - 2.6.
;
;	Step 9.	Handle exp(X), |X; > 16480 log2.
;		9.1	If X < 0, go to 9.3
;		9.2	ans := Huge, go to 9.4
;		9.3	ans := Tiny.
;		9.4	Restore user FPCR.
;		9.5	Return ans := ans * ans. Exit.
;	Notes:	Exp(X) will surely overflow or underflow, depending on
;		 X's sign. "Huge" and "Tiny" are respectively large/tiny
;		 extended-precision numbers whose square over/underflow
;		 with an inexact result. Thus, 9.5 always raises the
;		 inexact together with either overflow or underflow.
;
;
;	setoxm1d
;	--------
;
;	Step 1.	Set ans := 0
;
;	Step 2.	Return	ans := X + ans. Exit.
;	Notes:	This will return X with the appropriate rounding
;		 precision prescribed by the user FPCR.
;
;	setoxm1
;	-------
;
;	Step 1.	Check |X; ;		1.1	If |X; >= 1/4, go to Step 1.3.
;		1.2	Go to Step 7.
;		1.3	If |X; < 70 log(2), go to Step 2.
;		1.4	Go to Step 10.
;	Notes:	The usual case should take the branches 1.1 -> 1.3 -> 2.
;		 However, it is conceivable |X; can be small very often
;		 because EXPM1 is intended to evaluate exp(X)-1 accurately
;		 when |X; is small. For further details on the comparisons,
;		 see the notes on Step 1 of setox.
;
;	Step 2.	Calculate N = round-to-nearest-int( X * 64/log2 ).
;		2.1	N := round-to-nearest-integer( X * 64/log2 ).
;		2.2	Calculate	J = N mod 64; so J = 0,1,2,..., or 63.
;		2.3	Calculate	M = (N - J)/64; so N = 64M + J.
;		2.4	Calculate the address of the stored value of 2^(J/64).
;		2.5	Create the values Sc = 2^M and OnebySc := -2^(-M).
;	Notes:	See the notes on Step 2 of setox.
;
;	Step 3.	Calculate X - N*log2/64.
;		3.1	R := X + N*L1, where L1 := single-precision(-log2/64).
;		3.2	R := R + N*L2, L2 := extended-precision(-log2/64 - L1).
;	Notes:	Applying the analysis of Step 3 of setox in this case
;		 shows that |R; <= 0.0055 (note that |X; <= 70 log2 in
;		 this case).
;
;	Step 4.	Approximate exp(R)-1 by a polynomial
;			p = R+R*R*(A1+R*(A2+R*(A3+R*(A4+R*(A5+R*A6)))))
;	Notes:	a) In order to reduce memory access, the coefficients are
;		 made as "short" as possible: A1 (which is 1/2), A5 and A6
;		 are single precision; A2, A3 and A4 are double precision.
;		 b) Even with the restriction above,
;			|p - (exp(R)-1); <	|R; * 2^(-72.7)
;		 for all |R; <= 0.0055.
;		 c) To fully utilize the pipeline, p is separated into
;		 two independent pieces of roughly equal complexity
;			p = [ R*S*(A2 + S*(A4 + S*A6)) ]	+
;				[ R + S*(A1 + S*(A3 + S*A5)) ]
;		 where S = R*R.
;
;	Step 5.	Compute 2^(J/64)*p by
;				p := T*p
;		 where T and t are the stored values for 2^(J/64).
;	Notes:	2^(J/64) is stored as T and t where T+t approximates
;		 2^(J/64) to roughly 85 bits; T is in extended precision
;		 and t is in single precision. Note also that T is rounded
;		 to 62 bits so that the last two bits of T are zero. The
;		 reason for such a special form is that T-1, T-2, and T-8
;		 will all be exact --- a property that will be exploited
;		 in Step 6 below. The total relative error in p is no
;		 bigger than 2^(-67.7) compared to the final result.
;
;	Step 6.	Reconstruction of exp(X)-1
;			exp(X)-1 = 2^M * ( 2^(J/64) + p - 2^(-M) ).
;		6.1	If M <= 63, go to Step 6.3.
;		6.2	ans := T + (p + (t + OnebySc)). Go to 6.6
;		6.3	If M >= -3, go to 6.5.
;		6.4	ans := (T + (p + t)) + OnebySc. Go to 6.6
;		6.5	ans := (T + OnebySc) + (p + t).
;		6.6	Restore user FPCR.
;		6.7	Return ans := Sc * ans. Exit.
;	Notes:	The various arrangements of the expressions give accurate
;		 evaluations.
;
;	Step 7.	exp(X)-1 for |X; < 1/4.
;		7.1	If |X; >= 2^(-65), go to Step 9.
;		7.2	Go to Step 8.
;
;	Step 8.	Calculate exp(X)-1, |X; < 2^(-65).
;		8.1	If |X; < 2^(-16312), goto 8.3
;		8.2	Restore FPCR; return ans := X - 2^(-16382). Exit.
;		8.3	X := X * 2^(140).
;		8.4	Restore FPCR; ans := ans - 2^(-16382).
;		 Return ans := ans*2^(140). Exit
;	Notes:	The idea is to return "X - tiny" under the user
;		 precision and rounding modes. To avoid unnecessary
;		 inefficiency, we stay away from denormalized numbers the
;		 best we can. For |X; >= 2^(-16312), the straightforward
;		 8.2 generates the inexact exception as the case warrants.
;
;	Step 9.	Calculate exp(X)-1, |X; < 1/4, by a polynomial
;			p = X + X*X*(B1 + X*(B2 + ... + X*B12))
;	Notes:	a) In order to reduce memory access, the coefficients are
;		 made as "short" as possible: B1 (which is 1/2), B9 to B12
;		 are single precision; B3 to B8 are double precision; and
;		 B2 is double extended.
;		 b) Even with the restriction above,
;			|p - (exp(X)-1); < |X; 2^(-70.6)
;		 for all |X; <= 0.251.
;		 Note that 0.251 is slightly bigger than 1/4.
;		 c) To fully preserve accuracy, the polynomial is computed
;		 as	X + ( S*B1 +	Q ) where S = X*X and
;			Q	=	X*S*(B2 + X*(B3 + ... + X*B12))
;		 d) To fully utilize the pipeline, Q is separated into
;		 two independent pieces of roughly equal complexity
;			Q = [ X*S*(B2 + S*(B4 + ... + S*B12)) ] +
;				[ S*S*(B3 + S*(B5 + ... + S*B11)) ]
;
;	Step 10.	Calculate exp(X)-1 for |X; >= 70 log 2.
;		10.1 If X >= 70log2 , exp(X) - 1 = exp(X) for all practical
;		 purposes. Therefore, go to Step 1 of setox.
;		10.2 If X <= -70log2, exp(X) - 1 = -1 for all practical purposes.
;		 ans := -1
;		 Restore user FPCR
;		 Return ans := ans + 2^(-126). Exit.
;	Notes:	10.2 will always create an inexact and return -1 + tiny
;		 in the user rounding precision and mode.
;
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;setox	idnt	2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	

L2:	dc.l	$3FDC0000,$82E30865,$4361C4C6,$00000000

EXPA3_:	dc.l	$3FA55555,$55554431
EXPA2_:	dc.l	$3FC55555,$55554018

HUGE:	dc.l	$7FFE0000,$FFFFFFFF,$FFFFFFFF,$00000000
TINY:	dc.l	$00010000,$FFFFFFFF,$FFFFFFFF,$00000000

EM1A4:	dc.l	$3F811111,$11174385
EM1A3:	dc.l	$3FA55555,$55554F5A

EM1A2:	dc.l	$3FC55555,$55555555,$00000000,$00000000

EM1B8:	dc.l	$3EC71DE3,$A5774682
EM1B7:	dc.l	$3EFA01A0,$19D7CB68

EM1B6:	dc.l	$3F2A01A0,$1A019DF3
EM1B5:	dc.l	$3F56C16C,$16C170E2

EM1B4:	dc.l	$3F811111,$11111111
EM1B3:	dc.l	$3FA55555,$55555555

EM1B2:	dc.l	$3FFC0000,$AAAAAAAA,$AAAAAAAB
	dc.l	$00000000

TWO140:	dc.l	$48B00000,$00000000
TWON140:	dc.l	$37300000,$00000000

EXPTBL_:
	dc.l	$3FFF0000,$80000000,$00000000,$00000000
	dc.l	$3FFF0000,$8164D1F3,$BC030774,$9F841A9B
	dc.l	$3FFF0000,$82CD8698,$AC2BA1D8,$9FC1D5B9
	dc.l	$3FFF0000,$843A28C3,$ACDE4048,$A0728369
	dc.l	$3FFF0000,$85AAC367,$CC487B14,$1FC5C95C
	dc.l	$3FFF0000,$871F6196,$9E8D1010,$1EE85C9F
	dc.l	$3FFF0000,$88980E80,$92DA8528,$9FA20729
	dc.l	$3FFF0000,$8A14D575,$496EFD9C,$A07BF9AF
	dc.l	$3FFF0000,$8B95C1E3,$EA8BD6E8,$A0020DCF
	dc.l	$3FFF0000,$8D1ADF5B,$7E5BA9E4,$205A63DA
	dc.l	$3FFF0000,$8EA4398B,$45CD53C0,$1EB70051
	dc.l	$3FFF0000,$9031DC43,$1466B1DC,$1F6EB029
	dc.l	$3FFF0000,$91C3D373,$AB11C338,$A0781494
	dc.l	$3FFF0000,$935A2B2F,$13E6E92C,$9EB319B0
	dc.l	$3FFF0000,$94F4EFA8,$FEF70960,$2017457D
	dc.l	$3FFF0000,$96942D37,$20185A00,$1F11D537
	dc.l	$3FFF0000,$9837F051,$8DB8A970,$9FB952DD
	dc.l	$3FFF0000,$99E04593,$20B7FA64,$1FE43087
	dc.l	$3FFF0000,$9B8D39B9,$D54E5538,$1FA2A818
	dc.l	$3FFF0000,$9D3ED9A7,$2CFFB750,$1FDE494D
	dc.l	$3FFF0000,$9EF53260,$91A111AC,$20504890
	dc.l	$3FFF0000,$A0B0510F,$B9714FC4,$A073691C
	dc.l	$3FFF0000,$A2704303,$0C496818,$1F9B7A05
	dc.l	$3FFF0000,$A43515AE,$09E680A0,$A0797126
	dc.l	$3FFF0000,$A5FED6A9,$B15138EC,$A071A140
	dc.l	$3FFF0000,$A7CD93B4,$E9653568,$204F62DA
	dc.l	$3FFF0000,$A9A15AB4,$EA7C0EF8,$1F283C4A
	dc.l	$3FFF0000,$AB7A39B5,$A93ED338,$9F9A7FDC
	dc.l	$3FFF0000,$AD583EEA,$42A14AC8,$A05B3FAC
	dc.l	$3FFF0000,$AF3B78AD,$690A4374,$1FDF2610
	dc.l	$3FFF0000,$B123F581,$D2AC2590,$9F705F90
	dc.l	$3FFF0000,$B311C412,$A9112488,$201F678A
	dc.l	$3FFF0000,$B504F333,$F9DE6484,$1F32FB13
	dc.l	$3FFF0000,$B6FD91E3,$28D17790,$20038B30
	dc.l	$3FFF0000,$B8FBAF47,$62FB9EE8,$200DC3CC
	dc.l	$3FFF0000,$BAFF5AB2,$133E45FC,$9F8B2AE6
	dc.l	$3FFF0000,$BD08A39F,$580C36C0,$A02BBF70
	dc.l	$3FFF0000,$BF1799B6,$7A731084,$A00BF518
	dc.l	$3FFF0000,$C12C4CCA,$66709458,$A041DD41
	dc.l	$3FFF0000,$C346CCDA,$24976408,$9FDF137B
	dc.l	$3FFF0000,$C5672A11,$5506DADC,$201F1568
	dc.l	$3FFF0000,$C78D74C8,$ABB9B15C,$1FC13A2E
	dc.l	$3FFF0000,$C9B9BD86,$6E2F27A4,$A03F8F03
	dc.l	$3FFF0000,$CBEC14FE,$F2727C5C,$1FF4907D
	dc.l	$3FFF0000,$CE248C15,$1F8480E4,$9E6E53E4
	dc.l	$3FFF0000,$D06333DA,$EF2B2594,$1FD6D45C
	dc.l	$3FFF0000,$D2A81D91,$F12AE45C,$A076EDB9
	dc.l	$3FFF0000,$D4F35AAB,$CFEDFA20,$9FA6DE21
	dc.l	$3FFF0000,$D744FCCA,$D69D6AF4,$1EE69A2F
	dc.l	$3FFF0000,$D99D15C2,$78AFD7B4,$207F439F
	dc.l	$3FFF0000,$DBFBB797,$DAF23754,$201EC207
	dc.l	$3FFF0000,$DE60F482,$5E0E9124,$9E8BE175
	dc.l	$3FFF0000,$E0CCDEEC,$2A94E110,$20032C4B
	dc.l	$3FFF0000,$E33F8972,$BE8A5A50,$2004DFF5
	dc.l	$3FFF0000,$E5B906E7,$7C8348A8,$1E72F47A
	dc.l	$3FFF0000,$E8396A50,$3C4BDC68,$1F722F22
	dc.l	$3FFF0000,$EAC0C6E7,$DD243930,$A017E945
	dc.l	$3FFF0000,$ED4F301E,$D9942B84,$1F401A5B
	dc.l	$3FFF0000,$EFE4B99B,$DCDAF5CC,$9FB9A9E3
	dc.l	$3FFF0000,$F281773C,$59FFB138,$20744C05
	dc.l	$3FFF0000,$F5257D15,$2486CC2C,$1F773A19
	dc.l	$3FFF0000,$F7D0DF73,$0AD13BB8,$1FFE90D5
	dc.l	$3FFF0000,$FA83B2DB,$722A033C,$A041ED22
	dc.l	$3FFF0000,$FD3E0C0C,$F486C174,$1F853F3A
ADJFLAG = L_SCR2
SCALE = FP_SCR1
ADJSCALE = FP_SCR2
SC = FP_SCR3
ONEBYSC = FP_SCR4

	; xref	t_frcinx
	;xref	t_extdnrm
	;xref	t_unfl
	;xref	t_ovfl

	;|.global	setoxd
setoxd:
;--entry point for EXP(X), X is denormalized
	move.l		(a0),d0
	andi.l		#$80000000,d0
	ori.l		#$00800000,d0		; ...sign(X)*2^(-126)
	move.l		d0,-(sp)
	fmove.s		#$3F800000,fp0
	fmove.l		d1,fpcr
	fadd.s		(sp)+,fp0
	bra		t_frcinx

	;|.global	setox
setox:
;--entry point for EXP(X), here X is finite, non-zero, and not NaN's

;--Step 1.
	move.l		(a0),d0	 ; ...load part of input X
	andi.l		#$7FFF0000,d0	; ...biased expo. of X
	cmpi.l		#$3FBE0000,d0	; ...2^(-65)
	bge.s		EXPC1		; ...normal case
	bra		EXPSM

EXPC1:
;--The case |X; >= 2^(-65)
	move.w		4(a0),d0	; ...expo. and partial sig. of |X; 	cmpi.l		#$400CB167,d0	; ...16380 log2 trunc. 16 bits
	blt.s		EXPMAIN	 ; ...normal case
	bra		EXPBIG

EXPMAIN:
;--Step 2.
;--This is the normal branch:	2^(-65) <= |X; < 16380 log2.
	fmove.x		(a0),fp0	; ...load input from (a0)

	fmove.x		fp0,fp1
	fmul.s		#$42B8AA3B,fp0	; ...64/log2 * X
	fmovem.x	fp2-fp2/fp3,-(a7)		; ...save fp2
	move.l		#0,ADJFLAG(a6)
	fmove.l		fp0,d0		; ...N = int( X * 64/log2 )
	lea		EXPTBL_(pc),a1
	fmove.l		d0,fp0		; ...convert to floating-format

	move.l		d0,L_SCR1(a6)	; ...save N temporarily
	andi.l		#$3F,d0		; ...D0 is J = N mod 64
	lsl.l		#4,d0
	adda.l		d0,a1		; ...address of 2^(J/64)
	move.l		L_SCR1(a6),d0
	asr.l		#6,d0		; ...D0 is M
	addi.w		#$3FFF,d0	; ...biased expo. of 2^(M)
	move.w		L2(pc),L_SCR1(a6)	; ...prefetch L2, no need in CB

EXPCONT1:
;--Step 3.
;--fp1,fp2 saved on the stack. fp0 is N, fp1 is X,
;--a0 points to 2^(J/64), D0 is biased expo. of 2^(M)
	fmove.x		fp0,fp2
	fmul.s		#$BC317218,fp0	; ...N * L1, L1 = lead(-log2/64)
	fmul.x		L2(pc),fp2		; ...N * L2, L1+L2 = -log2/64
	fadd.x		fp1,fp0	 	; ...X + N*L1
	fadd.x		fp2,fp0		; ...fp0 is R, reduced arg.
;	MOVE.W		#$3FA5,EXPA3_	...load EXPA3 in cache

;--Step 4.
;--WE NOW COMPUTE EXP(R)-1 BY A POLYNOMIAL
;-- R + R*R*(A1 + R*(A2 + R*(A3 + R*(A4 + R*A5))))
;--TO FULLY UTILIZE THE PIPELINE, WE COMPUTE S = R*R
;--[R+R*S*(A2+S*A4)] + [S*(A1+S*(A3+S*A5))]

	fmove.x		fp0,fp1
	fmul.x		fp1,fp1	 	; ...fp1 IS S = R*R

	fmove.s		#$3AB60B70,fp2	; ...fp2 IS A5
;	MOVE.W		#0,2(a1)	...load 2^(J/64) in cache

	fmul.x		fp1,fp2	 	; ...fp2 IS S*A5
	fmove.x		fp1,fp3
	fmul.s		#$3C088895,fp3	; ...fp3 IS S*A4

	fadd.d		EXPA3_(pc),fp2	; ...fp2 IS A3+S*A5
	fadd.d		EXPA2_(pc),fp3	; ...fp3 IS A2+S*A4

	fmul.x		fp1,fp2	 	; ...fp2 IS S*(A3+S*A5)
	move.w		d0,SCALE(a6)	; ...SCALE is 2^(M) in extended
	clr.w		SCALE+2(a6)
	move.l		#$80000000,SCALE+4(a6)
	clr.l		SCALE+8(a6)

	fmul.x		fp1,fp3	 	; ...fp3 IS S*(A2+S*A4)

	fadd.s		#$3F000000,fp2	; ...fp2 IS A1+S*(A3+S*A5)
	fmul.x		fp0,fp3	 	; ...fp3 IS R*S*(A2+S*A4)

	fmul.x		fp1,fp2	 	; ...fp2 IS S*(A1+S*(A3+S*A5))
	fadd.x		fp3,fp0	 	; ...fp0 IS R+R*S*(A2+S*A4),
;					...fp3 released

	fmove.x		(a1)+,fp1	; ...fp1 is lead. pt. of 2^(J/64)
	fadd.x		fp2,fp0	 	; ...fp0 is EXP(R) - 1
;					...fp2 released

;--Step 5
;--final reconstruction process
;--EXP(X) = 2^M * ( 2^(J/64) + 2^(J/64)*(EXP(R)-1) )

	fmul.x		fp1,fp0	 	; ...2^(J/64)*(Exp(R)-1)
	fmovem.x	(a7)+,fp2-fp2/fp3	; ...fp2 restored
	fadd.s		(a1),fp0	; ...accurate 2^(J/64)

	fadd.x		fp1,fp0	 	; ...2^(J/64) + 2^(J/64)*...
	move.l		ADJFLAG(a6),d0

;--Step 6
	tst.l		d0
	beq.s		NORMAL
ADJUST:
	fmul.x		ADJSCALE(a6),fp0
NORMAL:
	fmove.l		d1,FPCR	 	; ...restore user FPCR
	fmul.x		SCALE(a6),fp0	; ...multiply 2^(M)
	bra		t_frcinx

EXPSM:
;--Step 7
	fmovem.x	(a0),fp0-fp0	; ...in case X is denormalized
	fmove.l		d1,FPCR
	fadd.s		#$3F800000,fp0	; ...1+X in user mode
	bra		t_frcinx

EXPBIG:
;--Step 8
	cmpi.l		#$400CB27C,d0	; ...16480 log2
	bgt.s		EXP2BIG
;--Steps 8.2 -- 8.6
	fmove.x		(a0),fp0	; ...load input from (a0)

	fmove.x		fp0,fp1
	fmul.s		#$42B8AA3B,fp0	; ...64/log2 * X
	fmovem.x	 fp2-fp2/fp3,-(a7)		; ...save fp2
	move.l		#1,ADJFLAG(a6)
	fmove.l		fp0,d0		; ...N = int( X * 64/log2 )
	lea		EXPTBL_(pc),a1
	fmove.l		d0,fp0		; ...convert to floating-format
	move.l		d0,L_SCR1(a6)			; ...save N temporarily
	andi.l		#$3F,d0		 ; ...D0 is J = N mod 64
	lsl.l		#4,d0
	adda.l		d0,a1			; ...address of 2^(J/64)
	move.l		L_SCR1(a6),d0
	asr.l		#6,d0			; ...D0 is K
	move.l		d0,L_SCR1(a6)			; ...save K temporarily
	asr.l		#1,d0			; ...D0 is M1
	sub.l		d0,L_SCR1(a6)			; ...a1 is M
	addi.w		#$3FFF,d0		; ...biased expo. of 2^(M1)
	move.w		d0,ADJSCALE(a6)		; ...ADJSCALE := 2^(M1)
	clr.w		ADJSCALE+2(a6)
	move.l		#$80000000,ADJSCALE+4(a6)
	clr.l		ADJSCALE+8(a6)
	move.l		L_SCR1(a6),d0			; ...D0 is M
	addi.w		#$3FFF,d0		; ...biased expo. of 2^(M)
	bra		EXPCONT1		; ...go back to Step 3

EXP2BIG:
;--Step 9
	fmove.l		d1,FPCR
	move.l		(a0),d0
	bclr.b		#sign_bit,(a0)		; ...setox always returns positive
	cmpi.l		#0,d0
	blt		t_unfl
	bra		t_ovfl

	;|.global	setoxm1d
setoxm1d:
;--entry point for EXPM1(X), here X is denormalized
;--Step 0.
	bra		t_extdnrm


	;|.global	setoxm1
setoxm1:
;--entry point for EXPM1(X), here X is finite, non-zero, non-NaN

;--Step 1.
;--Step 1.1
	move.l		(a0),d0	 ; ...load part of input X
	andi.l		#$7FFF0000,d0	; ...biased expo. of X
	cmpi.l		#$3FFD0000,d0	; ...1/4
	bge.s		EM1CON1	 ; ...|X; >= 1/4
	bra		EM1SM

EM1CON1:
;--Step 1.3
;--The case |X; >= 1/4
	move.w		4(a0),d0	; ...expo. and partial sig. of |X; 	cmpi.l		#$4004C215,d0	; ...70log2 rounded up to 16 bits
	ble.s		EM1MAIN	 ; ...1/4 <= |X; <= 70log2
	bra		EM1BIG

EM1MAIN:
;--Step 2.
;--This is the case:	1/4 <= |X; <= 70 log2.
	fmove.x		(a0),fp0	; ...load input from (a0)

	fmove.x		fp0,fp1
	fmul.s		#$42B8AA3B,fp0	; ...64/log2 * X
	fmovem.x	fp2-fp2/fp3,-(a7)		; ...save fp2
;	MOVE.W		#$3F81,EM1A4		...prefetch in CB mode
	fmove.l		fp0,d0		; ...N = int( X * 64/log2 )
	lea		EXPTBL_(pc),a1
	fmove.l		d0,fp0		; ...convert to floating-format

	move.l		d0,L_SCR1(a6)			; ...save N temporarily
	andi.l		#$3F,d0		 ; ...D0 is J = N mod 64
	lsl.l		#4,d0
	adda.l		d0,a1			; ...address of 2^(J/64)
	move.l		L_SCR1(a6),d0
	asr.l		#6,d0			; ...D0 is M
	move.l		d0,L_SCR1(a6)			; ...save a copy of M
;	MOVE.W		#$3FDC,L2		...prefetch L2 in CB mode

;--Step 3.
;--fp1,fp2 saved on the stack. fp0 is N, fp1 is X,
;--a0 points to 2^(J/64), D0 and a1 both contain M
	fmove.x		fp0,fp2
	fmul.s		#$BC317218,fp0	; ...N * L1, L1 = lead(-log2/64)
	fmul.x		L2(pc),fp2		; ...N * L2, L1+L2 = -log2/64
	fadd.x		fp1,fp0	 ; ...X + N*L1
	fadd.x		fp2,fp0	 ; ...fp0 is R, reduced arg.
;	MOVE.W		#$3FC5,EM1A2		...load EM1A2 in cache
	addi.w		#$3FFF,d0		; ...D0 is biased expo. of 2^M

;--Step 4.
;--WE NOW COMPUTE EXP(R)-1 BY A POLYNOMIAL
;-- R + R*R*(A1 + R*(A2 + R*(A3 + R*(A4 + R*(A5 + R*A6)))))
;--TO FULLY UTILIZE THE PIPELINE, WE COMPUTE S = R*R
;--[R*S*(A2+S*(A4+S*A6))] + [R+S*(A1+S*(A3+S*A5))]

	fmove.x		fp0,fp1
	fmul.x		fp1,fp1		; ...fp1 IS S = R*R

	fmove.s		#$3950097B,fp2	; ...fp2 IS a6
;	MOVE.W		#0,2(a1)	...load 2^(J/64) in cache

	fmul.x		fp1,fp2		; ...fp2 IS S*A6
	fmove.x		fp1,fp3
	fmul.s		#$3AB60B6A,fp3	; ...fp3 IS S*A5

	fadd.d		EM1A4(pc),fp2	; ...fp2 IS A4+S*A6
	fadd.d		EM1A3(pc),fp3	; ...fp3 IS A3+S*A5
	move.w		d0,SC(a6)		; ...SC is 2^(M) in extended
	clr.w		SC+2(a6)
	move.l		#$80000000,SC+4(a6)
	clr.l		SC+8(a6)

	fmul.x		fp1,fp2		; ...fp2 IS S*(A4+S*A6)
	move.l		L_SCR1(a6),d0		; ...D0 is	M
	neg.w		d0		; ...D0 is -M
	fmul.x		fp1,fp3		; ...fp3 IS S*(A3+S*A5)
	addi.w		#$3FFF,d0	; ...biased expo. of 2^(-M)
	fadd.d		EM1A2(pc),fp2	; ...fp2 IS A2+S*(A4+S*A6)
	fadd.s		#$3F000000,fp3	; ...fp3 IS A1+S*(A3+S*A5)

	fmul.x		fp1,fp2		; ...fp2 IS S*(A2+S*(A4+S*A6))
	ori.w		#$8000,d0	; ...signed/expo. of -2^(-M)
	move.w		d0,ONEBYSC(a6)	; ...OnebySc is -2^(-M)
	clr.w		ONEBYSC+2(a6)
	move.l		#$80000000,ONEBYSC+4(a6)
	clr.l		ONEBYSC+8(a6)
	fmul.x		fp3,fp1		; ...fp1 IS S*(A1+S*(A3+S*A5))
;					...fp3 released

	fmul.x		fp0,fp2		; ...fp2 IS R*S*(A2+S*(A4+S*A6))
	fadd.x		fp1,fp0		; ...fp0 IS R+S*(A1+S*(A3+S*A5))
;					...fp1 released

	fadd.x		fp2,fp0		; ...fp0 IS EXP(R)-1
;					...fp2 released
	fmovem.x	(a7)+,fp2-fp2/fp3	; ...fp2 restored

;--Step 5
;--Compute 2^(J/64)*p

	fmul.x		(a1),fp0	; ...2^(J/64)*(Exp(R)-1)

;--Step 6
;--Step 6.1
	move.l		L_SCR1(a6),d0		; ...retrieve M
	cmpi.l		#63,d0
	ble.s		MLE63
;--Step 6.2	M >= 64
	fmove.s		12(a1),fp1	; ...fp1 is t
	fadd.x		ONEBYSC(a6),fp1	; ...fp1 is t+OnebySc
	fadd.x		fp1,fp0		; ...p+(t+OnebySc), fp1 released
	fadd.x		(a1),fp0	; ...T+(p+(t+OnebySc))
	bra.s		EM1SCALE
MLE63:
;--Step 6.3	M <= 63
	cmpi.l		#-3,d0
	bge.s		MGEN3
MLTN3:
;--Step 6.4	M <= -4
	fadd.s		12(a1),fp0	; ...p+t
	fadd.x		(a1),fp0	; ...T+(p+t)
	fadd.x		ONEBYSC(a6),fp0	; ...OnebySc + (T+(p+t))
	bra.s		EM1SCALE
MGEN3:
;--Step 6.5	-3 <= M <= 63
	fmove.x		(a1)+,fp1	; ...fp1 is T
	fadd.s		(a1),fp0	; ...fp0 is p+t
	fadd.x		ONEBYSC(a6),fp1	; ...fp1 is T+OnebySc
	fadd.x		fp1,fp0		; ...(T+OnebySc)+(p+t)

EM1SCALE:
;--Step 6.6
	fmove.l		d1,FPCR
	fmul.x		SC(a6),fp0

	bra		t_frcinx

EM1SM:
;--Step 7	|X; < 1/4.
	cmpi.l		#$3FBE0000,d0	; ...2^(-65)
	bge.s		EM1POLY

EM1TINY:
;--Step 8	|X; < 2^(-65)
	cmpi.l		#$00330000,d0	; ...2^(-16312)
	blt.s		EM12TINY
;--Step 8.2
	move.l		#$80010000,SC(a6)	; ...SC is -2^(-16382)
	move.l		#$80000000,SC+4(a6)
	clr.l		SC+8(a6)
	fmove.x		(a0),fp0
	fmove.l		d1,FPCR
	fadd.x		SC(a6),fp0

	bra		t_frcinx

EM12TINY:
;--Step 8.3
	fmove.x		(a0),fp0
	fmul.d		TWO140(pc),fp0
	move.l		#$80010000,SC(a6)
	move.l		#$80000000,SC+4(a6)
	clr.l		SC+8(a6)
	fadd.x		SC(a6),fp0
	fmove.l		d1,FPCR
	fmul.d		TWON140(pc),fp0

	bra		t_frcinx

EM1POLY:
;--Step 9	exp(X)-1 by a simple polynomial
	fmove.x		(a0),fp0	; ...fp0 is X
	fmul.x		fp0,fp0		; ...fp0 is S := X*X
	fmovem.x	fp2-fp2/fp3,-(a7)	; ...save fp2
	fmove.s		#$2F30CAA8,fp1	; ...fp1 is B12
	fmul.x		fp0,fp1		; ...fp1 is S*B12
	fmove.s		#$310F8290,fp2	; ...fp2 is B11
	fadd.s		#$32D73220,fp1	; ...fp1 is B10+S*B12

	fmul.x		fp0,fp2		; ...fp2 is S*B11
	fmul.x		fp0,fp1		; ...fp1 is S*(B10 + ...

	fadd.s		#$3493F281,fp2	; ...fp2 is B9+S*...
	fadd.d		EM1B8(pc),fp1	; ...fp1 is B8+S*...

	fmul.x		fp0,fp2		; ...fp2 is S*(B9+...
	fmul.x		fp0,fp1		; ...fp1 is S*(B8+...

	fadd.d		EM1B7(pc),fp2	; ...fp2 is B7+S*...
	fadd.d		EM1B6(pc),fp1	; ...fp1 is B6+S*...

	fmul.x		fp0,fp2		; ...fp2 is S*(B7+...
	fmul.x		fp0,fp1		; ...fp1 is S*(B6+...

	fadd.d		EM1B5(pc),fp2	; ...fp2 is B5+S*...
	fadd.d		EM1B4(pc),fp1	; ...fp1 is B4+S*...

	fmul.x		fp0,fp2		; ...fp2 is S*(B5+...
	fmul.x		fp0,fp1		; ...fp1 is S*(B4+...

	fadd.d		EM1B3(pc),fp2	; ...fp2 is B3+S*...
	fadd.x		EM1B2(pc),fp1	; ...fp1 is B2+S*...

	fmul.x		fp0,fp2		; ...fp2 is S*(B3+...
	fmul.x		fp0,fp1		; ...fp1 is S*(B2+...

	fmul.x		fp0,fp2		; ...fp2 is S*S*(B3+...)
	fmul.x		(a0),fp1	; ...fp1 is X*S*(B2...

	fmul.s		#$3F000000,fp0	; ...fp0 is S*B1
	fadd.x		fp2,fp1		; ...fp1 is Q
;					...fp2 released

	fmovem.x	(a7)+,fp2-fp2/fp3	; ...fp2 restored

	fadd.x		fp1,fp0		; ...fp0 is S*B1+Q
;					...fp1 released

	fmove.l		d1,FPCR
	fadd.x		(a0),fp0

	bra		t_frcinx

EM1BIG:
;--Step 10	|X; > 70 log2
	move.l		(a0),d0
	cmpi.l		#0,d0
	bgt		EXPC1
;--Step 10.2
	fmove.s		#$BF800000,fp0	; ...fp0 is -1
	fmove.l		d1,FPCR
	fadd.s		#$00800000,fp0	; ...-1 + 2^(-126)

	bra		t_frcinx

	;end
;
;	sgetem.sa 3.1 12/10/90
;
;	The entry point sGETEXP returns the exponent portion 
;	of the input argument.  The exponent bias is removed
;	and the exponent value is returned as an extended 
;	precision number in fp0.  sGETEXPD handles denormalized
;	numbers.
;
;	The entry point sGETMAN extracts the mantissa of the 
;	input argument.  The mantissa is converted to an 
;	extended precision number and returned in fp0.  The
;	range of the result is [1.0 - 2.0).
;
;
;	Input:  Double-extended number X in the ETEMP space in
;		the floating-point save stack.
;
;	Output:	The functions return exp(X) or man(X) in fp0.
;
;	Modified: fp0.
;
;
;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;SGETEM	idnt	2,1 ; Motorola 040 Floating Point Software Package

	;section 8

	

	;xref	nrm_set

;
; This entry point is used by the unimplemented instruction exception
; handler.  It points a0 to the input operand.
;
;
;
;	SGETEXP
;

	;|.global	sgetexp
sgetexp:
	move.w	LOCAL_EX(a0),d0	;get the exponent
	bclr.l	#15,d0		;clear the sign bit
	sub.w	#$3fff,d0	;subtract off the bias
	fmove.w  d0,fp0		;move the exp to fp0
	rts

	;|.global	sgetexpd
sgetexpd:
	bclr.b	#sign_bit,LOCAL_EX(a0)
	bsr	nrm_set		;normalize (exp will go negative)
	move.w	LOCAL_EX(a0),d0	;load resulting exponent into d0
	sub.w	#$3fff,d0	;subtract off the bias
	fmove.w	d0,fp0		;move the exp to fp0
	rts
;
;
; This entry point is used by the unimplemented instruction exception
; handler.  It points a0 to the input operand.
;
;
;
;	SGETMAN
;
;
; For normalized numbers, leave the mantissa alone, simply load
; with an exponent of +/- $3fff.
;
	;|.global	sgetman
sgetman:
	move.l	USER_FPCR(a6),d0
	andi.l	#$ffffff00,d0	;clear rounding precision and mode
	fmove.l	d0,fpcr		;this fpcr setting is used by the 882
	move.w	LOCAL_EX(a0),d0	;get the exp (really just want sign bit)
	or.w	#$7fff,d0	;clear old exp
	bclr.l	#14,d0	 	;make it the new exp +-3fff
	move.w	d0,LOCAL_EX(a0)	;move the sign & exp back to fsave stack
	fmove.x	(a0),fp0	;put new value back in fp0
	rts

;
; For denormalized numbers, shift the mantissa until the j-bit = 1,
; then load the exponent with +/1 $3fff.
;
	;|.global	sgetmand
sgetmand:
	move.l	LOCAL_HI(a0),d0	;load ms mant in d0
	move.l	LOCAL_LO(a0),d1	;load ls mant in d1
	bsr	shft		;shift mantissa bits till msbit is set
	move.l	d0,LOCAL_HI(a0)	;put ms mant back on stack
	move.l	d1,LOCAL_LO(a0)	;put ls mant back on stack
	bra.s	sgetman

;
;	SHFT
;
;	Shifts the mantissa bits until msbit is set.
;	input:
;		ms mantissa part in d0
;		ls mantissa part in d1
;	output:
;		shifted bits in d0 and d1
shft:
	tst.l	d0		;if any bits set in ms mant
	bne.s	upper		;then branch
;				;else no bits set in ms mant
	tst.l	d1		;test if any bits set in ls mant
	bne.s	.cont		;if set then continue
	bra.s	shft_end	;else return
.cont:
	move.l	d3,-(a7)	;save d3
	exg	d0,d1		;shift ls mant to ms mant
	bfffo	d0{0:32},d3	;find first 1 in ls mant to d0
	lsl.l	d3,d0		;shift first 1 to integer bit in ms mant
	move.l	(a7)+,d3	;restore d3
	bra.s	shft_end
upper:

	movem.l	d3/d5/d6,-(a7)	;save registers
	bfffo	d0{0:32},d3	;find first 1 in ls mant to d0
	lsl.l	d3,d0		;shift ms mant until j-bit is set
	move.l	d1,d6		;save ls mant in d6
	lsl.l	d3,d1		;shift ls mant by count
	move.l	#32,d5
	sub.l	d3,d5		;sub 32 from shift for ls mant
	lsr.l	d5,d6		;shift off all bits but those that will
;				;be shifted into ms mant
	or.l	d6,d0		;shift the ls mant bits into the ms mant
	movem.l	(a7)+,d3/d5/d6	;restore registers
shft_end:
	rts

	;end
;
;	sint.sa 3.1 12/10/90
;
;	The entry point sINT computes the rounded integer 
;	equivalent of the input argument, sINTRZ computes 
;	the integer rounded to zero of the input argument.
;
;	Entry points sint and sintrz are called from do_func
;	to emulate the fint and fintrz unimplemented instructions,
;	respectively.  Entry point sintdo is used by bindec.
;
;	Input: (Entry points sint and sintrz) Double-extended
;		number X in the ETEMP space in the floating-point
;		save stack.
;	       (Entry point sintdo) Double-extended number X in
;		location pointed to by the address register a0.
;	       (Entry point sintd) Double-extended denormalized
;		number X in the ETEMP space in the floating-point
;		save stack.
;
;	Output: The function returns int(X) or intrz(X) in fp0.
;
;	Modifies: fp0.
;
;	Algorithm: (sint and sintrz)
;
;	1. If exp(X) >= 63, return X. 
;	   If exp(X) < 0, return +/- 0 or +/- 1, according to
;	   the rounding mode.
;	
;	2. (X is in range) set rsc = 63 - exp(X). Unnormalize the
;	   result to the exponent $403e.
;
;	3. Round the result in the mode given in USER_FPCR. For
;	   sintrz, force round-to-zero mode.
;
;	4. Normalize the rounded result; store in fp0.
;
;	For the denormalized cases, force the correct result
;	for the given sign and rounding mode.
;
;		        Sign(X)
;		RMODE   +    -
;		-----  --------
;		 RN    +0   -0
;		 RZ    +0   -0
;		 RM    +0   -1
;		 RP    +1   -0
;
;
;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;SINT    idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	

	;xref	dnrm_lp
	;xref	nrm_set
	;xref	round
	;xref	t_inx2
	;xref	ld_pone
	;xref	ld_mone
	;xref	ld_pzero
	;xref	ld_mzero
	;xref	snzrinx

;
;	FINT
;
	;|.global	sint
sint:
	bfextu	FPCR_MODE(a6){2:2},d1	;use user's mode for rounding
;					;implicitly has extend precision
;					;in upper word. 
	move.l	d1,L_SCR1(a6)		;save mode bits
	bra.s	sintexc			

;
;	FINT with extended denorm inputs.
;
	;|.global	sintd
sintd:
	btst.b	#5,FPCR_MODE(a6)
	beq	snzrinx		;if round nearest or round zero, +/- 0
	btst.b	#4,FPCR_MODE(a6)
	beq.s	rnd_mns
rnd_pls:
	btst.b	#sign_bit,LOCAL_EX(a0)
	bne.s	sintmz
	bsr	ld_pone		;if round plus inf and pos, answer is +1
	bra	t_inx2
rnd_mns:
	btst.b	#sign_bit,LOCAL_EX(a0)
	beq.s	sintpz
	bsr	ld_mone		;if round mns inf and neg, answer is -1
	bra	t_inx2
sintpz:
	bsr	ld_pzero
	bra	t_inx2
sintmz:
	bsr	ld_mzero
	bra	t_inx2

;
;	FINTRZ
;
	;|.global	sintrz
sintrz:
	move.l	#1,L_SCR1(a6)		;use rz mode for rounding
;					;implicitly has extend precision
;					;in upper word. 
	bra.s	sintexc			
;
;	SINTDO
;
;	Input:	a0 points to an IEEE extended format operand
; 	Output:	fp0 has the result 
;
; Exceptions:
;
; If the subroutine results in an inexact operation, the inx2 and
; ainx bits in the USER_FPSR are set.
;
;
	;|.global	sintdo
sintdo:
	bfextu	FPCR_MODE(a6){2:2},d1	;use user's mode for rounding
;					;implicitly has ext precision
;					;in upper word. 
	move.l	d1,L_SCR1(a6)		;save mode bits
;
; Real work of sint is in sintexc
;
sintexc:
	bclr.b	#sign_bit,LOCAL_EX(a0)	;convert to internal extended
;					;format
	sne	LOCAL_SGN(a0)		
	cmp.w	#$403e,LOCAL_EX(a0)	;check if (unbiased) exp > 63
	bgt.s	out_rnge			;branch if exp < 63
	cmp.w	#$3ffd,LOCAL_EX(a0)	;check if (unbiased) exp < 0
	bgt	in_rnge			;if 63 >= exp > 0, do calc
;
; Input is less than zero.  Restore sign, and check for directed
; rounding modes.  L_SCR1 contains the rmode in the lower byte.
;
un_rnge:
	btst.b	#1,L_SCR1+3(a6)		;check for rn and rz
	beq.s	un_rnrz
	tst.b	LOCAL_SGN(a0)		;check for sign
	bne.s	un_rmrp_neg
;
; Sign is +.  If rp, load +1.0, if rm, load +0.0
;
	cmpi.b	#3,L_SCR1+3(a6)		;check for rp
	beq.s	un_ldpone		;if rp, load +1.0
	bsr	ld_pzero		;if rm, load +0.0
	bra	t_inx2
un_ldpone:
	bsr	ld_pone
	bra	t_inx2
;
; Sign is -.  If rm, load -1.0, if rp, load -0.0
;
un_rmrp_neg:
	cmpi.b	#2,L_SCR1+3(a6)		;check for rm
	beq.s	un_ldmone		;if rm, load -1.0
	bsr	ld_mzero		;if rp, load -0.0
	bra	t_inx2
un_ldmone:
	bsr	ld_mone
	bra	t_inx2
;
; Rmode is rn or rz; return signed zero
;
un_rnrz:
	tst.b	LOCAL_SGN(a0)		;check for sign
	bne.s	un_rnrz_neg
	bsr	ld_pzero
	bra	t_inx2
un_rnrz_neg:
	bsr	ld_mzero
	bra	t_inx2
	
;
; Input is greater than 2^63.  All bits are significant.  Return
; the input.
;
out_rnge:
	bfclr	LOCAL_SGN(a0){0:8}	;change back to IEEE ext format
	beq.s	intps
	bset.b	#sign_bit,LOCAL_EX(a0)
intps:
	fmove.l	fpcr,-(sp)
	fmove.l	#0,fpcr
	fmove.x LOCAL_EX(a0),fp0	;if exp > 63
;					;then return X to the user
;					;there are no fraction bits
	fmove.l	(sp)+,fpcr
	rts

in_rnge:
; 					;shift off fraction bits
	clr.l	d0			;clear d0 - initial g,r,s for
;					;dnrm_lp
	move.l	#$403e,d1		;set threshold for dnrm_lp
;					;assumes a0 points to operand
	bsr	dnrm_lp
;					;returns unnormalized number
;					;pointed by a0
;					;output d0 supplies g,r,s
;					;used by round
	move.l	L_SCR1(a6),d1		;use selected rounding mode
;
;
	bsr	round			;round the unnorm based on users
;					;input	a0 ptr to ext X
;					;	d0 g,r,s bits
;					;	d1 PREC/MODE info
;					;output a0 ptr to rounded result
;					;inexact flag set in USER_FPSR
;					;if initial grs set
;
; normalize the rounded result and store value in fp0
;
	bsr	nrm_set			;normalize the unnorm
;					;Input: a0 points to operand to
;					;be normalized
;					;Output: a0 points to normalized
;					;result
	bfclr	LOCAL_SGN(a0){0:8}
	beq.s	nrmrndp
	bset.b	#sign_bit,LOCAL_EX(a0)	;return to IEEE extended format
nrmrndp:
	fmove.l	fpcr,-(sp)
	fmove.l	#0,fpcr
	fmove.x LOCAL_EX(a0),fp0	;move result to fp0
	fmove.l	(sp)+,fpcr
	rts

	;end
;
;	slog2.sa 3.1 12/10/90
;
;       The entry point slog10 computes the base-10 
;	logarithm of an input argument X.
;	slog10d does the same except the input value is a 
;	denormalized number.  
;	sLog2 and sLog2d are the base-2 analogues.
;
;       INPUT:	Double-extended value in memory location pointed to 
;		by address register a0.
;
;       OUTPUT: log_10(X) or log_2(X) returned in floating-point 
;		register fp0.
;
;       ACCURACY and MONOTONICITY: The returned result is within 1.7 
;		ulps in 64 significant bit, i.e. within 0.5003 ulp 
;		to 53 bits if the result is subsequently rounded 
;		to double precision. The result is provably monotonic 
;		in double precision.
;
;       SPEED:	Two timings are measured, both in the copy-back mode. 
;		The first one is measured when the function is invoked 
;		the first time (so the instructions and data are not 
;		in cache), and the second one is measured when the 
;		function is reinvoked at the same input argument.
;
;       ALGORITHM and IMPLEMENTATION NOTES:
;
;       slog10d:
;
;       Step 0.   If X < 0, create a NaN and raise the invalid operation
;                 flag. Otherwise, save FPCR in D1; set FpCR to default.
;       Notes:    Default means round-to-nearest mode, no floating-point
;                 traps, and precision control = double extended.
;
;       Step 1.   Call slognd to obtain Y = log(X), the natural log of X.
;       Notes:    Even if X is denormalized, log(X) is always normalized.
;
;       Step 2.   Compute log_10(X) = log(X) * (1/log(10)).
;            2.1  Restore the user FPCR
;            2.2  Return ans := Y * INV_L10.
;
;
;       slog10: 
;
;       Step 0.   If X < 0, create a NaN and raise the invalid operation
;                 flag. Otherwise, save FPCR in D1; set FpCR to default.
;       Notes:    Default means round-to-nearest mode, no floating-point
;                 traps, and precision control = double extended.
;
;       Step 1.   Call sLogN to obtain Y = log(X), the natural log of X.
;
;       Step 2.   Compute log_10(X) = log(X) * (1/log(10)).
;            2.1  Restore the user FPCR
;            2.2  Return ans := Y * INV_L10.
;
;
;       sLog2d:
;
;       Step 0.   If X < 0, create a NaN and raise the invalid operation
;                 flag. Otherwise, save FPCR in D1; set FpCR to default.
;       Notes:    Default means round-to-nearest mode, no floating-point
;                 traps, and precision control = double extended.
;
;       Step 1.   Call slognd to obtain Y = log(X), the natural log of X.
;       Notes:    Even if X is denormalized, log(X) is always normalized.
;
;       Step 2.   Compute log_10(X) = log(X) * (1/log(2)).
;            2.1  Restore the user FPCR
;            2.2  Return ans := Y * INV_L2.
;
;
;       sLog2:
;
;       Step 0.   If X < 0, create a NaN and raise the invalid operation
;                 flag. Otherwise, save FPCR in D1; set FpCR to default.
;       Notes:    Default means round-to-nearest mode, no floating-point
;                 traps, and precision control = double extended.
;
;       Step 1.   If X is not an integer power of two, i.e., X != 2^k,
;                 go to Step 3.
;
;       Step 2.   Return k.
;            2.1  Get integer k, X = 2^k.
;            2.2  Restore the user FPCR.
;            2.3  Return ans := convert-to-double-extended(k).
;
;       Step 3.   Call sLogN to obtain Y = log(X), the natural log of X.
;
;       Step 4.   Compute log_2(X) = log(X) * (1/log(2)).
;            4.1  Restore the user FPCR
;            4.2  Return ans := Y * INV_L2.
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;SLOG2    idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	;xref	t_frcinx	
	;xref	t_operr
	;xref	slogn
	;xref	slognd

INV_L10:  dc.l $3FFD0000,$DE5BD8A9,$37287195,$00000000

INV_L2:   dc.l $3FFF0000,$B8AA3B29,$5C17F0BC,$00000000

	;|.global	slog10d
slog10d:
;--entry point for Log10(X), X is denormalized
	move.l		(a0),d0
	blt		invalid
	move.l		d1,-(sp)
	clr.l		d1
	bsr		slognd			; ...log(X), X denorm.
	fmove.l		(sp)+,fpcr
	fmul.x		INV_L10(pc),fp0
	bra		t_frcinx

	;|.global	slog10
slog10:
;--entry point for Log10(X), X is normalized

	move.l		(a0),d0
	blt		invalid
	move.l		d1,-(sp)
	clr.l		d1
	bsr		slogn			; ...log(X), X normal.
	fmove.l		(sp)+,fpcr
	fmul.x		INV_L10(pc),fp0
	bra		t_frcinx


	;|.global	slog2d
slog2d:
;--entry point for Log2(X), X is denormalized

	move.l		(a0),d0
	blt		invalid
	move.l		d1,-(sp)
	clr.l		d1
	bsr		slognd			; ...log(X), X denorm.
	fmove.l		(sp)+,fpcr
	fmul.x		INV_L2(pc),fp0
	bra		t_frcinx

	;|.global	slog2
slog2:
;--entry point for Log2(X), X is normalized
	move.l		(a0),d0
	blt		invalid

	move.l		8(a0),d0
	bne.s		continue		; ...X is not 2^k

	move.l		4(a0),d0
	and.l		#$7FFFFFFF,d0
	tst.l		d0
	bne.s		continue

;--X = 2^k.
	move.w		(a0),d0
	and.l		#$00007FFF,d0
	sub.l		#$3FFF,d0
	fmove.l		d1,fpcr
	fmove.l		d0,fp0
	bra		t_frcinx

continue:
	move.l		d1,-(sp)
	clr.l		d1
	bsr		slogn			; ...log(X), X normal.
	fmove.l		(sp)+,fpcr
	fmul.x		INV_L2(pc),fp0
	bra		t_frcinx

invalid:
	bra		t_operr

	;end
;
;	slogn.sa 3.1 12/10/90
;
;	slogn computes the natural logarithm of an
;	input value. slognd does the same except the input value is a
;	denormalized number. slognp1 computes log(1+X), and slognp1d
;	computes log(1+X) for denormalized X.
;
;	Input: Double-extended value in memory location pointed to by address
;		register a0.
;
;	Output:	log(X) or log(1+X) returned in floating-point register Fp0.
;
;	Accuracy and Monotonicity: The returned result is within 2 ulps in
;		64 significant bit, i.e. within 0.5001 ulp to 53 bits if the
;		result is subsequently rounded to double precision. The 
;		result is provably monotonic in double precision.
;
;	Speed: The program slogn takes approximately 190 cycles for input 
;		argument X such that |X-1; >= 1/16, which is the the usual 
;		situation. For those arguments, slognp1 takes approximately
;		 210 cycles. For the less common arguments, the program will
;		 run no worse than 10% slower.
;
;	Algorithm:
;	LOGN:
;	Step 1. If |X-1; < 1/16, approximate log(X) by an odd polynomial in
;		u, where u = 2(X-1)/(X+1). Otherwise, move on to Step 2.
;
;	Step 2. X = 2**k * Y where 1 <= Y < 2. Define F to be the first seven
;		significant bits of Y plus 2**(-7), i.e. F = 1.xxxxxx1 in base
;		2 where the six "x" match those of Y. Note that |Y-F; <= 2**(-7).
;
;	Step 3. Define u = (Y-F)/F. Approximate log(1+u) by a polynomial in u,
;		log(1+u) = poly.
;
;	Step 4. Reconstruct log(X) = log( 2**k * Y ) = k*log(2) + log(F) + log(1+u)
;		by k*log(2) + (log(F) + poly). The values of log(F) are calculated
;		beforehand and stored in the program.
;
;	lognp1:
;	Step 1: If |X; < 1/16, approximate log(1+X) by an odd polynomial in
;		u where u = 2X/(2+X). Otherwise, move on to Step 2.
;
;	Step 2: Let 1+X = 2**k * Y, where 1 <= Y < 2. Define F as done in Step 2
;		of the algorithm for LOGN and compute log(1+X) as
;		k*log(2) + log(F) + poly where poly approximates log(1+u),
;		u = (Y-F)/F. 
;
;	Implementation Notes:
;	Note 1. There are 64 different possible values for F, thus 64 log(F)'s
;		need to be tabulated. Moreover, the values of 1/F are also 
;		tabulated so that the division in (Y-F)/F can be performed by a
;		multiplication.
;
;	Note 2. In Step 2 of lognp1, in order to preserved accuracy, the value
;		Y-F has to be calculated carefully when 1/2 <= X < 3/2. 
;
;	Note 3. To fully exploit the pipeline, polynomials are usually separated
;		into two parts evaluated independently before being added up.
;	

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;slogn	idnt	2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	

BOUNDS1_:  dc.l $3FFEF07D,$3FFF8841
BOUNDS2:  dc.l $3FFE8000,$3FFFC000

LOGOF2:	dc.l $3FFE0000,$B17217F7,$D1CF79AC,$00000000

one:	dc.l $3F800000
zero:	dc.l $00000000
infty:	dc.l $7F800000
negone:	dc.l $BF800000

LOGA6:	dc.l $3FC2499A,$B5E4040B
LOGA5:	dc.l $BFC555B5,$848CB7DB

LOGA4:	dc.l $3FC99999,$987D8730
LOGA3:	dc.l $BFCFFFFF,$FF6F7E97

LOGA2:	dc.l $3FD55555,$555555a4
LOGA1:	dc.l $BFE00000,$00000008

LOGB5:	dc.l $3F175496,$ADD7DAD6
LOGB4:	dc.l $3F3C71C2,$FE80C7E0

LOGB3:	dc.l $3F624924,$928BCCFF
LOGB2:	dc.l $3F899999,$999995EC

LOGB1:	dc.l $3FB55555,$55555555
TWO:	dc.l $40000000,$00000000

LTHOLD:	dc.l $3f990000,$80000000,$00000000,$00000000

LOGTBL:
	dc.l  $3FFE0000,$FE03F80F,$E03F80FE,$00000000
	dc.l  $3FF70000,$FF015358,$833C47E2,$00000000
	dc.l  $3FFE0000,$FA232CF2,$52138AC0,$00000000
	dc.l  $3FF90000,$BDC8D83E,$AD88D549,$00000000
	dc.l  $3FFE0000,$F6603D98,$0F6603DA,$00000000
	dc.l  $3FFA0000,$9CF43DCF,$F5EAFD48,$00000000
	dc.l  $3FFE0000,$F2B9D648,$0F2B9D65,$00000000
	dc.l  $3FFA0000,$DA16EB88,$CB8DF614,$00000000
	dc.l  $3FFE0000,$EF2EB71F,$C4345238,$00000000
	dc.l  $3FFB0000,$8B29B775,$1BD70743,$00000000
	dc.l  $3FFE0000,$EBBDB2A5,$C1619C8C,$00000000
	dc.l  $3FFB0000,$A8D839F8,$30C1FB49,$00000000
	dc.l  $3FFE0000,$E865AC7B,$7603A197,$00000000
	dc.l  $3FFB0000,$C61A2EB1,$8CD907AD,$00000000
	dc.l  $3FFE0000,$E525982A,$F70C880E,$00000000
	dc.l  $3FFB0000,$E2F2A47A,$DE3A18AF,$00000000
	dc.l  $3FFE0000,$E1FC780E,$1FC780E2,$00000000
	dc.l  $3FFB0000,$FF64898E,$DF55D551,$00000000
	dc.l  $3FFE0000,$DEE95C4C,$A037BA57,$00000000
	dc.l  $3FFC0000,$8DB956A9,$7B3D0148,$00000000
	dc.l  $3FFE0000,$DBEB61EE,$D19C5958,$00000000
	dc.l  $3FFC0000,$9B8FE100,$F47BA1DE,$00000000
	dc.l  $3FFE0000,$D901B203,$6406C80E,$00000000
	dc.l  $3FFC0000,$A9372F1D,$0DA1BD17,$00000000
	dc.l  $3FFE0000,$D62B80D6,$2B80D62C,$00000000
	dc.l  $3FFC0000,$B6B07F38,$CE90E46B,$00000000
	dc.l  $3FFE0000,$D3680D36,$80D3680D,$00000000
	dc.l  $3FFC0000,$C3FD0329,$06488481,$00000000
	dc.l  $3FFE0000,$D0B69FCB,$D2580D0B,$00000000
	dc.l  $3FFC0000,$D11DE0FF,$15AB18CA,$00000000
	dc.l  $3FFE0000,$CE168A77,$25080CE1,$00000000
	dc.l  $3FFC0000,$DE1433A1,$6C66B150,$00000000
	dc.l  $3FFE0000,$CB8727C0,$65C393E0,$00000000
	dc.l  $3FFC0000,$EAE10B5A,$7DDC8ADD,$00000000
	dc.l  $3FFE0000,$C907DA4E,$871146AD,$00000000
	dc.l  $3FFC0000,$F7856E5E,$E2C9B291,$00000000
	dc.l  $3FFE0000,$C6980C69,$80C6980C,$00000000
	dc.l  $3FFD0000,$82012CA5,$A68206D7,$00000000
	dc.l  $3FFE0000,$C4372F85,$5D824CA6,$00000000
	dc.l  $3FFD0000,$882C5FCD,$7256A8C5,$00000000
	dc.l  $3FFE0000,$C1E4BBD5,$95F6E947,$00000000
	dc.l  $3FFD0000,$8E44C60B,$4CCFD7DE,$00000000
	dc.l  $3FFE0000,$BFA02FE8,$0BFA02FF,$00000000
	dc.l  $3FFD0000,$944AD09E,$F4351AF6,$00000000
	dc.l  $3FFE0000,$BD691047,$07661AA3,$00000000
	dc.l  $3FFD0000,$9A3EECD4,$C3EAA6B2,$00000000
	dc.l  $3FFE0000,$BB3EE721,$A54D880C,$00000000
	dc.l  $3FFD0000,$A0218434,$353F1DE8,$00000000
	dc.l  $3FFE0000,$B92143FA,$36F5E02E,$00000000
	dc.l  $3FFD0000,$A5F2FCAB,$BBC506DA,$00000000
	dc.l  $3FFE0000,$B70FBB5A,$19BE3659,$00000000
	dc.l  $3FFD0000,$ABB3B8BA,$2AD362A5,$00000000
	dc.l  $3FFE0000,$B509E68A,$9B94821F,$00000000
	dc.l  $3FFD0000,$B1641795,$CE3CA97B,$00000000
	dc.l  $3FFE0000,$B30F6352,$8917C80B,$00000000
	dc.l  $3FFD0000,$B7047551,$5D0F1C61,$00000000
	dc.l  $3FFE0000,$B11FD3B8,$0B11FD3C,$00000000
	dc.l  $3FFD0000,$BC952AFE,$EA3D13E1,$00000000
	dc.l  $3FFE0000,$AF3ADDC6,$80AF3ADE,$00000000
	dc.l  $3FFD0000,$C2168ED0,$F458BA4A,$00000000
	dc.l  $3FFE0000,$AD602B58,$0AD602B6,$00000000
	dc.l  $3FFD0000,$C788F439,$B3163BF1,$00000000
	dc.l  $3FFE0000,$AB8F69E2,$8359CD11,$00000000
	dc.l  $3FFD0000,$CCECAC08,$BF04565D,$00000000
	dc.l  $3FFE0000,$A9C84A47,$A07F5638,$00000000
	dc.l  $3FFD0000,$D2420487,$2DD85160,$00000000
	dc.l  $3FFE0000,$A80A80A8,$0A80A80B,$00000000
	dc.l  $3FFD0000,$D7894992,$3BC3588A,$00000000
	dc.l  $3FFE0000,$A655C439,$2D7B73A8,$00000000
	dc.l  $3FFD0000,$DCC2C4B4,$9887DACC,$00000000
	dc.l  $3FFE0000,$A4A9CF1D,$96833751,$00000000
	dc.l  $3FFD0000,$E1EEBD3E,$6D6A6B9E,$00000000
	dc.l  $3FFE0000,$A3065E3F,$AE7CD0E0,$00000000
	dc.l  $3FFD0000,$E70D785C,$2F9F5BDC,$00000000
	dc.l  $3FFE0000,$A16B312E,$A8FC377D,$00000000
	dc.l  $3FFD0000,$EC1F392C,$5179F283,$00000000
	dc.l  $3FFE0000,$9FD809FD,$809FD80A,$00000000
	dc.l  $3FFD0000,$F12440D3,$E36130E6,$00000000
	dc.l  $3FFE0000,$9E4CAD23,$DD5F3A20,$00000000
	dc.l  $3FFD0000,$F61CCE92,$346600BB,$00000000
	dc.l  $3FFE0000,$9CC8E160,$C3FB19B9,$00000000
	dc.l  $3FFD0000,$FB091FD3,$8145630A,$00000000
	dc.l  $3FFE0000,$9B4C6F9E,$F03A3CAA,$00000000
	dc.l  $3FFD0000,$FFE97042,$BFA4C2AD,$00000000
	dc.l  $3FFE0000,$99D722DA,$BDE58F06,$00000000
	dc.l  $3FFE0000,$825EFCED,$49369330,$00000000
	dc.l  $3FFE0000,$9868C809,$868C8098,$00000000
	dc.l  $3FFE0000,$84C37A7A,$B9A905C9,$00000000
	dc.l  $3FFE0000,$97012E02,$5C04B809,$00000000
	dc.l  $3FFE0000,$87224C2E,$8E645FB7,$00000000
	dc.l  $3FFE0000,$95A02568,$095A0257,$00000000
	dc.l  $3FFE0000,$897B8CAC,$9F7DE298,$00000000
	dc.l  $3FFE0000,$94458094,$45809446,$00000000
	dc.l  $3FFE0000,$8BCF55DE,$C4CD05FE,$00000000
	dc.l  $3FFE0000,$92F11384,$0497889C,$00000000
	dc.l  $3FFE0000,$8E1DC0FB,$89E125E5,$00000000
	dc.l  $3FFE0000,$91A2B3C4,$D5E6F809,$00000000
	dc.l  $3FFE0000,$9066E68C,$955B6C9B,$00000000
	dc.l  $3FFE0000,$905A3863,$3E06C43B,$00000000
	dc.l  $3FFE0000,$92AADE74,$C7BE59E0,$00000000
	dc.l  $3FFE0000,$8F1779D9,$FDC3A219,$00000000
	dc.l  $3FFE0000,$94E9BFF6,$15845643,$00000000
	dc.l  $3FFE0000,$8DDA5202,$37694809,$00000000
	dc.l  $3FFE0000,$9723A1B7,$20134203,$00000000
	dc.l  $3FFE0000,$8CA29C04,$6514E023,$00000000
	dc.l  $3FFE0000,$995899C8,$90EB8990,$00000000
	dc.l  $3FFE0000,$8B70344A,$139BC75A,$00000000
	dc.l  $3FFE0000,$9B88BDAA,$3A3DAE2F,$00000000
	dc.l  $3FFE0000,$8A42F870,$5669DB46,$00000000
	dc.l  $3FFE0000,$9DB4224F,$FFE1157C,$00000000
	dc.l  $3FFE0000,$891AC73A,$E9819B50,$00000000
	dc.l  $3FFE0000,$9FDADC26,$8B7A12DA,$00000000
	dc.l  $3FFE0000,$87F78087,$F78087F8,$00000000
	dc.l  $3FFE0000,$A1FCFF17,$CE733BD4,$00000000
	dc.l  $3FFE0000,$86D90544,$7A34ACC6,$00000000
	dc.l  $3FFE0000,$A41A9E8F,$5446FB9F,$00000000
	dc.l  $3FFE0000,$85BF3761,$2CEE3C9B,$00000000
	dc.l  $3FFE0000,$A633CD7E,$6771CD8B,$00000000
	dc.l  $3FFE0000,$84A9F9C8,$084A9F9D,$00000000
	dc.l  $3FFE0000,$A8489E60,$0B435A5E,$00000000
	dc.l  $3FFE0000,$83993052,$3FBE3368,$00000000
	dc.l  $3FFE0000,$AA59233C,$CCA4BD49,$00000000
	dc.l  $3FFE0000,$828CBFBE,$B9A020A3,$00000000
	dc.l  $3FFE0000,$AC656DAE,$6BCC4985,$00000000
	dc.l  $3FFE0000,$81848DA8,$FAF0D277,$00000000
	dc.l  $3FFE0000,$AE6D8EE3,$60BB2468,$00000000
	dc.l  $3FFE0000,$80808080,$80808081,$00000000
	dc.l  $3FFE0000,$B07197A2,$3C46C654,$00000000
ADJK = L_SCR1
X1 = FP_SCR1
XDCARE2 = X1+2
XFRAC2 = X1+4
F = FP_SCR2
FFRAC = F+4
KLOG2 = FP_SCR3
SAVEU = FP_SCR4

	; xref	t_frcinx
	;xref	t_extdnrm
	;xref	t_operr
	;xref	t_dz

	;|.global	slognd
slognd:
;--ENTRY POINT FOR LOG(X) FOR DENORMALIZED INPUT

	move.l		#-100,ADJK(a6)	; ...INPUT = 2^(ADJK) * FP0

;----normalize the input value by left shifting k bits (k to be determined
;----below), adjusting exponent and storing -k to  ADJK
;----the value TWOTO100 is no longer needed.
;----Note that this code assumes the denormalized input is NON-ZERO.

     movem.l	d2-d7,-(a7)		; ...save some registers 
     move.l	#$00000000,d3		; ...D3 is exponent of smallest norm. #
     move.l	4(a0),d4
     move.l	8(a0),d5		; ...(D4,D5) is (Hi_X,Lo_X)
     clr.l	d2			; ...D2 used for holding K

     tst.l	d4
     bne.s	HiX_not0

.HiX_0:
     move.l	d5,d4
     clr.l	d5
     move.l	#32,d2
     clr.l	d6
     bfffo      d4{0:32},d6
     lsl.l      d6,d4
     add.l	d6,d2			; ...(D3,D4,D5) is normalized

     move.l	d3,X1(a6)
     move.l	d4,XFRAC2(a6)
     move.l	d5,XFRAC2+4(a6)
     neg.l	d2
     move.l	d2,ADJK(a6)
     fmove.x	X1(a6),fp0
     movem.l	(a7)+,d2-d7		; ...restore registers
     lea	X1(a6),a0
     bra.s	LOGBGN			; ...begin regular log(X)


HiX_not0:
     clr.l	d6
     bfffo	d4{0:32},d6		; ...find first 1
     move.l	d6,d2			; ...get k
     lsl.l	d6,d4
     move.l	d5,d7			; ...a copy of D5
     lsl.l	d6,d5
     neg.l	d6
     addi.l	#32,d6
     lsr.l	d6,d7
     or.l	d7,d4			; ...(D3,D4,D5) normalized

     move.l	d3,X1(a6)
     move.l	d4,XFRAC2(a6)
     move.l	d5,XFRAC2+4(a6)
     neg.l	d2
     move.l	d2,ADJK(a6)
     fmove.x	X1(a6),fp0
     movem.l	(a7)+,d2-d7		; ...restore registers
     lea	X1(a6),a0
     bra.s	LOGBGN			; ...begin regular log(X)


	;|.global	slogn
slogn:
;--ENTRY POINT FOR LOG(X) FOR X FINITE, NON-ZERO, NOT NAN'S

	fmove.x		(a0),fp0	; ...LOAD INPUT
	move.l		#$00000000,ADJK(a6)

LOGBGN:
;--FPCR SAVED AND CLEARED, INPUT IS 2^(ADJK)*FP0, FP0 CONTAINS
;--A FINITE, NON-ZERO, NORMALIZED NUMBER.

	move.l	(a0),d0
	move.w	4(a0),d0

	move.l	(a0),X1(a6)
	move.l	4(a0),X1+4(a6)
	move.l	8(a0),X1+8(a6)

	cmpi.l	#0,d0		; ...CHECK IF X IS NEGATIVE
	blt	LOGNEG		; ...LOG OF NEGATIVE ARGUMENT IS INVALID
	cmp2.l	BOUNDS1_(pc),d0	; ...X IS POSITIVE, CHECK IF X IS NEAR 1
	bcc	LOGNEAR1	; ...BOUNDS IS ROUGHLY [15/16, 17/16]

LOGMAIN:
;--THIS SHOULD BE THE USUAL CASE, X NOT VERY CLOSE TO 1

;--X = 2^(K) * Y, 1 <= Y < 2. THUS, Y = 1.XXXXXXXX....XX IN BINARY.
;--WE DEFINE F = 1.XXXXXX1, I.E. FIRST 7 BITS OF Y AND ATTACH A 1.
;--THE IDEA IS THAT LOG(X) = K*LOG2 + LOG(Y)
;--			 = K*LOG2 + LOG(F) + LOG(1 + (Y-F)/F).
;--NOTE THAT U = (Y-F)/F IS VERY SMALL AND THUS APPROXIMATING
;--LOG(1+U) CAN BE VERY EFFICIENT.
;--ALSO NOTE THAT THE VALUE 1/F IS STORED IN A TABLE SO THAT NO
;--DIVISION IS NEEDED TO CALCULATE (Y-F)/F. 

;--GET K, Y, F, AND ADDRESS OF 1/F.
	asr.l	#8,d0
	asr.l	#8,d0		; ...SHIFTED 16 BITS, BIASED EXPO. OF X
	subi.l	#$3FFF,d0 	; ...THIS IS K
	add.l	ADJK(a6),d0	; ...ADJUST K, ORIGINAL INPUT MAY BE  DENORM.
	lea	LOGTBL(pc),a0 	; ...BASE ADDRESS OF 1/F AND LOG(F)
	fmove.l	d0,fp1		; ...CONVERT K TO FLOATING-POINT FORMAT

;--WHILE THE CONVERSION IS GOING ON, WE GET F AND ADDRESS OF 1/F
	move.l	#$3FFF0000,X1(a6)	; ...X IS NOW Y, I.E. 2^(-K)*X
	move.l	XFRAC2(a6),FFRAC(a6)
	andi.l	#$FE000000,FFRAC(a6) ; ...FIRST 7 BITS OF Y
	ori.l	#$01000000,FFRAC(a6) ; ...GET F: ATTACH A 1 AT THE EIGHTH BIT
	move.l	FFRAC(a6),d0	; ...READY TO GET ADDRESS OF 1/F
	andi.l	#$7E000000,d0	
	asr.l	#8,d0
	asr.l	#8,d0
	asr.l	#4,d0		; ...SHIFTED 20, D0 IS THE DISPLACEMENT
	adda.l	d0,a0		; ...A0 IS THE ADDRESS FOR 1/F

	fmove.x	X1(a6),fp0
	move.l	#$3fff0000,F(a6)
	clr.l	F+8(a6)
	fsub.x	F(a6),fp0		; ...Y-F
	fmovem.x fp2-fp2/fp3,-(sp)	; ...SAVE FP2 WHILE FP0 IS NOT READY
;--SUMMARY: FP0 IS Y-F, A0 IS ADDRESS OF 1/F, FP1 IS K
;--REGISTERS SAVED: FPCR, FP1, FP2

LP1CONT1:
;--AN RE-ENTRY POINT FOR LOGNP1
	fmul.x	(a0),fp0	; ...FP0 IS U = (Y-F)/F
	fmul.x	LOGOF2(pc),fp1	; ...GET K*LOG2 WHILE FP0 IS NOT READY
	fmove.x	fp0,fp2
	fmul.x	fp2,fp2		; ...FP2 IS V=U*U
	fmove.x	fp1,KLOG2(a6)	; ...PUT K*LOG2 IN MEMORY, FREE FP1

;--LOG(1+U) IS APPROXIMATED BY
;--U + V*(A1+U*(A2+U*(A3+U*(A4+U*(A5+U*A6))))) WHICH IS
;--[U + V*(A1+V*(A3+V*A5))]  +  [U*V*(A2+V*(A4+V*A6))]

	fmove.x	fp2,fp3
	fmove.x	fp2,fp1	

	fmul.d	LOGA6(pc),fp1	; ...V*A6
	fmul.d	LOGA5(pc),fp2	; ...V*A5

	fadd.d	LOGA4(pc),fp1	; ...A4+V*A6
	fadd.d	LOGA3(pc),fp2	; ...A3+V*A5

	fmul.x	fp3,fp1		; ...V*(A4+V*A6)
	fmul.x	fp3,fp2		; ...V*(A3+V*A5)

	fadd.d	LOGA2(pc),fp1	; ...A2+V*(A4+V*A6)
	fadd.d	LOGA1(pc),fp2	; ...A1+V*(A3+V*A5)

	fmul.x	fp3,fp1		; ...V*(A2+V*(A4+V*A6))
	adda.l	#16,a0		; ...ADDRESS OF LOG(F)
	fmul.x	fp3,fp2		; ...V*(A1+V*(A3+V*A5)), FP3 RELEASED

	fmul.x	fp0,fp1		; ...U*V*(A2+V*(A4+V*A6))
	fadd.x	fp2,fp0		; ...U+V*(A1+V*(A3+V*A5)), FP2 RELEASED

	fadd.x	(a0),fp1	; ...LOG(F)+U*V*(A2+V*(A4+V*A6))
	fmovem.x  (sp)+,fp2-fp2/fp3	; ...RESTORE FP2
	fadd.x	fp1,fp0		; ...FP0 IS LOG(F) + LOG(1+U)

	fmove.l	d1,fpcr
	fadd.x	KLOG2(a6),fp0	; ...FINAL ADD
	bra	t_frcinx


LOGNEAR1:
;--REGISTERS SAVED: FPCR, FP1. FP0 CONTAINS THE INPUT.
	fmove.x	fp0,fp1
	fsub.s	one(pc),fp1		; ...FP1 IS X-1
	fadd.s	one(pc),fp0		; ...FP0 IS X+1
	fadd.x	fp1,fp1		; ...FP1 IS 2(X-1)
;--LOG(X) = LOG(1+U/2)-LOG(1-U/2) WHICH IS AN ODD POLYNOMIAL
;--IN U, U = 2(X-1)/(X+1) = FP1/FP0

LP1CONT2:
;--THIS IS AN RE-ENTRY POINT FOR LOGNP1
	fdiv.x	fp0,fp1		; ...FP1 IS U
	fmovem.x fp2-fp2/fp3,-(sp)	 ; ...SAVE FP2
;--REGISTERS SAVED ARE NOW FPCR,FP1,FP2,FP3
;--LET V=U*U, W=V*V, CALCULATE
;--U + U*V*(B1 + V*(B2 + V*(B3 + V*(B4 + V*B5)))) BY
;--U + U*V*(  [B1 + W*(B3 + W*B5)]  +  [V*(B2 + W*B4)]  )
	fmove.x	fp1,fp0
	fmul.x	fp0,fp0	; ...FP0 IS V
	fmove.x	fp1,SAVEU(a6) ; ...STORE U IN MEMORY, FREE FP1
	fmove.x	fp0,fp1	
	fmul.x	fp1,fp1	; ...FP1 IS W

	fmove.d	LOGB5(pc),fp3
	fmove.d	LOGB4(pc),fp2

	fmul.x	fp1,fp3	; ...W*B5
	fmul.x	fp1,fp2	; ...W*B4

	fadd.d	LOGB3(pc),fp3 ; ...B3+W*B5
	fadd.d	LOGB2(pc),fp2 ; ...B2+W*B4

	fmul.x	fp3,fp1	; ...W*(B3+W*B5), FP3 RELEASED

	fmul.x	fp0,fp2	; ...V*(B2+W*B4)

	fadd.d	LOGB1(pc),fp1 ; ...B1+W*(B3+W*B5)
	fmul.x	SAVEU(a6),fp0 ; ...FP0 IS U*V

	fadd.x	fp2,fp1	; ...B1+W*(B3+W*B5) + V*(B2+W*B4), FP2 RELEASED
	fmovem.x (sp)+,fp2-fp2/fp3 ; ...FP2 RESTORED

	fmul.x	fp1,fp0	; ...U*V*( [B1+W*(B3+W*B5)] + [V*(B2+W*B4)] )

	fmove.l	d1,fpcr
	fadd.x	SAVEU(a6),fp0		
	bra	t_frcinx
	rts

LOGNEG:
;--REGISTERS SAVED FPCR. LOG(-VE) IS INVALID
	bra	t_operr

	;|.global	slognp1d
slognp1d:
;--ENTRY POINT FOR LOG(1+Z) FOR DENORMALIZED INPUT
; Simply return the denorm

	bra	t_extdnrm

	;|.global	slognp1
slognp1:
;--ENTRY POINT FOR LOG(1+X) FOR X FINITE, NON-ZERO, NOT NAN'S

	fmove.x	(a0),fp0	; ...LOAD INPUT
	fabs.x	fp0		;test magnitude
	fcmp.x	LTHOLD(pc),fp0	;compare with min threshold
	fbgt	LP1REAL		;if greater, continue
	fmove.l	#0,fpsr		;clr N flag from compare
	fmove.l	d1,fpcr
	fmove.x	(a0),fp0	;return signed argument
	bra	t_frcinx

LP1REAL:
	fmove.x	(a0),fp0	; ...LOAD INPUT
	move.l	#$00000000,ADJK(a6)
	fmove.x	fp0,fp1	; ...FP1 IS INPUT Z
	fadd.s	one(pc),fp0	; ...X := ROUND(1+Z)
	fmove.x	fp0,X1(a6)
	move.w	XFRAC2(a6),XDCARE2(a6)
	move.l	X1(a6),d0
	cmpi.l	#0,d0
	ble	LP1NEG0	; ...LOG OF ZERO OR -VE
	cmp2.l	BOUNDS2(pc),d0
	bcs	LOGMAIN	; ...BOUNDS2 IS [1/2,3/2]
;--IF 1+Z > 3/2 OR 1+Z < 1/2, THEN X, WHICH IS ROUNDING 1+Z,
;--CONTAINS AT LEAST 63 BITS OF INFORMATION OF Z. IN THAT CASE,
;--SIMPLY INVOKE LOG(X) FOR LOG(1+Z).

LP1NEAR1:
;--NEXT SEE IF EXP(-1/16) < X < EXP(1/16)
	cmp2.l	BOUNDS1_(pc),d0
	bcs.s	LP1CARE

LP1ONE16:
;--EXP(-1/16) < X < EXP(1/16). LOG(1+Z) = LOG(1+U/2) - LOG(1-U/2)
;--WHERE U = 2Z/(2+Z) = 2Z/(1+X).
	fadd.x	fp1,fp1	; ...FP1 IS 2Z
	fadd.s	one(pc),fp0	; ...FP0 IS 1+X
;--U = FP1/FP0
	bra	LP1CONT2

LP1CARE:
;--HERE WE USE THE USUAL TABLE DRIVEN APPROACH. CARE HAS TO BE
;--TAKEN BECAUSE 1+Z CAN HAVE 67 BITS OF INFORMATION AND WE MUST
;--PRESERVE ALL THE INFORMATION. BECAUSE 1+Z IS IN [1/2,3/2],
;--THERE ARE ONLY TWO CASES.
;--CASE 1: 1+Z < 1, THEN K = -1 AND Y-F = (2-F) + 2Z
;--CASE 2: 1+Z > 1, THEN K = 0  AND Y-F = (1-F) + Z
;--ON RETURNING TO LP1CONT1, WE MUST HAVE K IN FP1, ADDRESS OF
;--(1/F) IN A0, Y-F IN FP0, AND FP2 SAVED.

	move.l	XFRAC2(a6),FFRAC(a6)
	andi.l	#$FE000000,FFRAC(a6)
	ori.l	#$01000000,FFRAC(a6)	; ...F OBTAINED
	cmpi.l	#$3FFF8000,d0	; ...SEE IF 1+Z > 1
	bge.s	KISZERO

KISNEG1:
	fmove.s	TWO(pc),fp0
	move.l	#$3fff0000,F(a6)
	clr.l	F+8(a6)
	fsub.x	F(a6),fp0	; ...2-F
	move.l	FFRAC(a6),d0
	andi.l	#$7E000000,d0
	asr.l	#8,d0
	asr.l	#8,d0
	asr.l	#4,d0		; ...D0 CONTAINS DISPLACEMENT FOR 1/F
	fadd.x	fp1,fp1		; ...GET 2Z
	fmovem.x fp2-fp2/fp3,-(sp)	; ...SAVE FP2 
	fadd.x	fp1,fp0		; ...FP0 IS Y-F = (2-F)+2Z
	lea	LOGTBL(pc),a0	; ...A0 IS ADDRESS OF 1/F
	adda.l	d0,a0
	fmove.s	negone(pc),fp1	; ...FP1 IS K = -1
	bra	LP1CONT1

KISZERO:
	fmove.s	one(pc),fp0
	move.l	#$3fff0000,F(a6)
	clr.l	F+8(a6)
	fsub.x	F(a6),fp0		; ...1-F
	move.l	FFRAC(a6),d0
	andi.l	#$7E000000,d0
	asr.l	#8,d0
	asr.l	#8,d0
	asr.l	#4,d0
	fadd.x	fp1,fp0		; ...FP0 IS Y-F
	fmovem.x fp2-fp2/fp3,-(sp)	; ...FP2 SAVED
	lea	LOGTBL(pc),a0
	adda.l	d0,a0	 	; ...A0 IS ADDRESS OF 1/F
	fmove.s	zero(pc),fp1	; ...FP1 IS K = 0
	bra	LP1CONT1

LP1NEG0:
;--FPCR SAVED. D0 IS X IN COMPACT FORM.
	cmpi.l	#0,d0
	blt.s	LP1NEG
LP1ZERO:
	fmove.s	negone(pc),fp0

	fmove.l	d1,fpcr
	bra t_dz

LP1NEG:
	fmove.s	zero(pc),fp0

	fmove.l	d1,fpcr
	bra	t_operr

	;end
;
;	smovecr.sa 3.1 12/10/90
;
;	The entry point sMOVECR returns the constant at the
;	offset given in the instruction field.
;
;	Input: An offset in the instruction word.
;
;	Output:	The constant rounded to the user's rounding
;		mode unchecked for overflow.
;
;	Modified: fp0.
;
;
;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;SMOVECR	idnt	2,1 ; Motorola 040 Floating Point Software Package

	;section 8

	

	;xref	nrm_set
	;xref	round
	;xref	PIRN
	;xref	PIRZRM
	;xref	PIRP
	;xref	SMALRN
	;xref	SMALRZRM
	;xref	SMALRP
	;xref	BIGRN
	;xref	BIGRZRM
	;xref	BIGRP

FZERO:	dc.l	00000000
;
;	FMOVECR 
;
	;|.global	smovcr
smovcr:
	bfextu	CMDREG1B(a6){9:7},d0 ;get offset
	bfextu	USER_FPCR(a6){26:2},d1 ;get rmode
;
; check range of offset
;
	tst.b	d0		;if zero, offset is to pi
	beq.s	PI_TBL		;it is pi
	cmpi.b	#$0a,d0		;check range $01 - $0a
	ble.s	Z_VAL		;if in this range, return zero
	cmpi.b	#$0e,d0		;check range $0b - $0e
	ble.s	SM_TBL		;valid constants in this range
	cmpi.b	#$2f,d0		;check range $10 - $2f
	ble.s	Z_VAL		;if in this range, return zero 
	cmpi.b	#$3f,d0		;check range $30 - $3f
	ble  	BG_TBL		;valid constants in this range
Z_VAL:
	fmove.s	FZERO(pc),fp0
	rts
PI_TBL:
	tst.b	d1		;offset is zero, check for rmode
	beq.s	PI_RN		;if zero, rn mode
	cmpi.b	#$3,d1		;check for rp
	beq.s	PI_RP		;if 3, rp mode
PI_RZRM:
	lea.l	PIRZRM(pc),a0	;rmode is rz or rm, load PIRZRM in a0
	bra	set_finx
PI_RN:
	lea.l	PIRN(pc),a0		;rmode is rn, load PIRN in a0
	bra	set_finx
PI_RP:
	lea.l	PIRP(pc),a0		;rmode is rp, load PIRP in a0
	bra	set_finx
SM_TBL:
	subi.l	#$b,d0		;make offset in 0 - 4 range
	tst.b	d1		;check for rmode
	beq.s	SM_RN		;if zero, rn mode
	cmpi.b	#$3,d1		;check for rp
	beq.s	SM_RP		;if 3, rp mode
SM_RZRM:
	lea.l	SMALRZRM(pc),a0	;rmode is rz or rm, load SMRZRM in a0
	cmpi.b	#$2,d0		;check if result is inex
	ble	set_finx	;if 0 - 2, it is inexact
	bra	no_finx		;if 3, it is exact
SM_RN:
	lea.l	SMALRN(pc),a0	;rmode is rn, load SMRN in a0
	cmpi.b	#$2,d0		;check if result is inex
	ble	set_finx	;if 0 - 2, it is inexact
	bra	no_finx		;if 3, it is exact
SM_RP:
	lea.l	SMALRP(pc),a0	;rmode is rp, load SMRP in a0
	cmpi.b	#$2,d0		;check if result is inex
	ble	set_finx	;if 0 - 2, it is inexact
	bra	no_finx		;if 3, it is exact
BG_TBL:
	subi.l	#$30,d0		;make offset in 0 - f range
	tst.b	d1		;check for rmode
	beq.s	BG_RN		;if zero, rn mode
	cmpi.b	#$3,d1		;check for rp
	beq.s	BG_RP		;if 3, rp mode
BG_RZRM:
	lea.l	BIGRZRM(pc),a0	;rmode is rz or rm, load BGRZRM in a0
	cmpi.b	#$1,d0		;check if result is inex
	ble	set_finx	;if 0 - 1, it is inexact
	cmpi.b	#$7,d0		;second check
	ble	no_finx		;if 0 - 7, it is exact
	bra	set_finx	;if 8 - f, it is inexact
BG_RN:
	lea.l	BIGRN(pc),a0	;rmode is rn, load BGRN in a0
	cmpi.b	#$1,d0		;check if result is inex
	ble	set_finx	;if 0 - 1, it is inexact
	cmpi.b	#$7,d0		;second check
	ble	no_finx		;if 0 - 7, it is exact
	bra	set_finx	;if 8 - f, it is inexact
BG_RP:
	lea.l	BIGRP(pc),a0	;rmode is rp, load SMRP in a0
	cmpi.b	#$1,d0		;check if result is inex
	ble	set_finx	;if 0 - 1, it is inexact
	cmpi.b	#$7,d0		;second check
	ble	no_finx		;if 0 - 7, it is exact
;	bra	set_finx	;if 8 - f, it is inexact
set_finx:
	or.l	#inx2a_mask,USER_FPSR(a6) ;set inex2/ainex
no_finx:
	mulu.l	#12,d0			;use offset to point into tables
	move.l	d1,L_SCR1(a6)		;load mode for round call
	bfextu	USER_FPCR(a6){24:2},d1	;get precision
	tst.l	d1			;check if extended precision
;
; Precision is extended
;
	bne.s	not_ext			;if extended, do not call round
	fmovem.x (a0,d0),fp0-fp0		;return result in fp0
	rts
;
; Precision is single or double
;
not_ext:
	swap	d1			;rnd prec in upper word of d1
	add.l	L_SCR1(a6),d1		;merge rmode in low word of d1
	move.l	(a0,d0),FP_SCR1(a6)	;load first word to temp storage
	move.l	4(a0,d0),FP_SCR1+4(a6)	;load second word
	move.l	8(a0,d0),FP_SCR1+8(a6)	;load third word
	clr.l	d0			;clear g,r,s
	lea	FP_SCR1(a6),a0
	btst.b	#sign_bit,LOCAL_EX(a0)
	sne	LOCAL_SGN(a0)		;convert to internal ext. format
	
	bsr	round			;go round the mantissa

	bfclr	LOCAL_SGN(a0){0:8}	;convert back to IEEE ext format
	beq.s	fin_fcr
	bset.b	#sign_bit,LOCAL_EX(a0)
fin_fcr:
	fmovem.x (a0),fp0-fp0
	rts

	;end
;
;	srem_mod.sa 3.1 12/10/90
;
;      The entry point sMOD computes the floating point MOD of the
;      input values X and Y. The entry point sREM computes the floating
;      point (IEEE) REM of the input values X and Y.
;
;      INPUT
;      -----
;      Double-extended value Y is pointed to by address in register
;      A0. Double-extended value X is located in -12(A0). The values
;      of X and Y are both nonzero and finite; although either or both
;      of them can be denormalized. The special cases of zeros, NaNs,
;      and infinities are handled elsewhere.
;
;      OUTPUT
;      ------
;      FREM(X,Y) or FMOD(X,Y), depending on entry point.
;
;       ALGORITHM
;       ---------
;
;       Step 1.  Save and strip signs of X and Y: signX := sign(X),
;                signY := sign(Y), X := |X|, Y := |Y|, 
;                signQ := signX EOR signY. Record whether MOD or REM
;                is requested.
;
;       Step 2.  Set L := expo(X)-expo(Y), k := 0, Q := 0.
;                If (L < 0) then
;                   R := X, go to Step 4.
;                else
;                   R := 2^(-L)X, j := L.
;                endif
;
;       Step 3.  Perform MOD(X,Y)
;            3.1 If R = Y, go to Step 9.
;            3.2 If R > Y, then { R := R - Y, Q := Q + 1}
;            3.3 If j = 0, go to Step 4.
;            3.4 k := k + 1, j := j - 1, Q := 2Q, R := 2R. Go to
;                Step 3.1.
;
;       Step 4.  At this point, R = X - QY = MOD(X,Y). Set
;                Last_Subtract := false (used in Step 7 below). If
;                MOD is requested, go to Step 6. 
;
;       Step 5.  R = MOD(X,Y), but REM(X,Y) is requested.
;            5.1 If R < Y/2, then R = MOD(X,Y) = REM(X,Y). Go to
;                Step 6.
;            5.2 If R > Y/2, then { set Last_Subtract := true,
;                Q := Q + 1, Y := signY*Y }. Go to Step 6.
;            5.3 This is the tricky case of R = Y/2. If Q is odd,
;                then { Q := Q + 1, signX := -signX }.
;
;       Step 6.  R := signX*R.
;
;       Step 7.  If Last_Subtract = true, R := R - Y.
;
;       Step 8.  Return signQ, last 7 bits of Q, and R as required.
;
;       Step 9.  At this point, R = 2^(-j)*X - Q Y = Y. Thus,
;                X = 2^(j)*(Q+1)Y. set Q := 2^(j)*(Q+1),
;                R := 0. Return signQ, last 7 bits of Q, and R.
;
;                
             
;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

SREM_MOD:    ;idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section    8

	
Mod_Flag = L_SCR3
SignY = FP_SCR3+4
SignX = FP_SCR3+8
SignQ = FP_SCR3+12
Sc_Flag = FP_SCR4
Y = FP_SCR1
Y_Hi = Y+4
Y_Lo = Y+8
R = FP_SCR2
R_Hi = R+4
R_Lo = R+8


Scale:     dc.l	$00010000,$80000000,$00000000,$00000000

	;xref	t_avoid_unsupp

        ;|.global        smod
smod:

   move.l               #0,Mod_Flag(a6)
   bra.s                Mod_Rem

        ;|.global        srem
srem:

   move.l               #1,Mod_Flag(a6)

Mod_Rem:
;..Save sign of X and Y
   movem.l              d2-d7,-(a7)     ; ...save data registers
   move.w               (a0),d3
   move.w               d3,SignY(a6)
   andi.l               #$00007FFF,d3   ; ...Y := |Y; 
;
   move.l               4(a0),d4
   move.l               8(a0),d5        ; ...(D3,D4,D5) is |Y; 
   tst.l                d3
   bne.s                Y_Normal

   move.l               #$00003FFE,d3	; ...$3FFD + 1
   tst.l                d4
   bne.s                HiY_not0

HiY_0:
   move.l               d5,d4
   clr.l                d5
   subi.l               #32,d3
   clr.l                d6
   bfffo                d4{0:32},d6
   lsl.l                d6,d4
   sub.l                d6,d3           ; ...(D3,D4,D5) is normalized
;                                       ...with bias $7FFD
   bra.s                Chk_X

HiY_not0:
   clr.l                d6
   bfffo                d4{0:32},d6
   sub.l                d6,d3
   lsl.l                d6,d4
   move.l               d5,d7           ; ...a copy of D5
   lsl.l                d6,d5
   neg.l                d6
   addi.l               #32,d6
   lsr.l                d6,d7
   or.l                 d7,d4           ; ...(D3,D4,D5) normalized
;                                       ...with bias $7FFD
   bra.s                Chk_X

Y_Normal:
   addi.l               #$00003FFE,d3   ; ...(D3,D4,D5) normalized
;                                       ...with bias $7FFD

Chk_X:
   move.w               -12(a0),d0
   move.w               d0,SignX(a6)
   move.w               SignY(a6),d1
   eor.l                d0,d1
   andi.l               #$00008000,d1
   move.w               d1,SignQ(a6)	; ...sign(Q) obtained
   andi.l               #$00007FFF,d0
   move.l               -8(a0),d1
   move.l               -4(a0),d2       ; ...(D0,D1,D2) is |X;    tst.l                d0
   bne.s                X_Normal
   move.l               #$00003FFE,d0
   tst.l                d1
   bne.s                .HiX_not0

.HiX_0:
   move.l               d2,d1
   clr.l                d2
   subi.l               #32,d0
   clr.l                d6
   bfffo                d1{0:32},d6
   lsl.l                d6,d1
   sub.l                d6,d0           ; ...(D0,D1,D2) is normalized
;                                       ...with bias $7FFD
   bra.s                Init

.HiX_not0:
   clr.l                d6
   bfffo                d1{0:32},d6
   sub.l                d6,d0
   lsl.l                d6,d1
   move.l               d2,d7           ; ...a copy of D2
   lsl.l                d6,d2
   neg.l                d6
   addi.l               #32,d6
   lsr.l                d6,d7
   or.l                 d7,d1           ; ...(D0,D1,D2) normalized
;                                       ...with bias $7FFD
   bra.s                Init

X_Normal:
   addi.l               #$00003FFE,d0   ; ...(D0,D1,D2) normalized
;                                       ...with bias $7FFD

Init:
;
   move.l               d3,L_SCR1(a6)   ; ...save biased expo(Y)
   move.l		d0,L_SCR2(a6)	;save d0
   sub.l                d3,d0           ; ...L := expo(X)-expo(Y)
;   Move.L               D0,L            ...D0 is j
   clr.l                d6              ; ...D6 := carry <- 0
   clr.l                d3              ; ...D3 is Q
   movea.l              #0,a1           ; ...A1 is k; j+k=L, Q=0

;..(Carry,D1,D2) is R
   tst.l                d0
   bge.s                Mod_Loop

;..expo(X) < expo(Y). Thus X = mod(X,Y)
;
   move.l		L_SCR2(a6),d0	;restore d0
   bra                Get_Mod

;..At this point  R = 2^(-L)X; Q = 0; k = 0; and  k+j = L


Mod_Loop:
   tst.l                d6              ; ...test carry bit
   bgt.s                R_GT_Y

;..At this point carry = 0, R = (D1,D2), Y = (D4,D5)
   cmp.l                d4,d1           ; ...compare hi(R) and hi(Y)
   bne.s                R_NE_Y
   cmp.l                d5,d2           ; ...compare lo(R) and lo(Y)
   bne.s                R_NE_Y

;..At this point, R = Y
   bra                Rem_is_0

R_NE_Y:
;..use the borrow of the previous compare
   bcs.s                R_LT_Y          ; ...borrow is set iff R < Y

R_GT_Y:
;..If Carry is set, then Y < (Carry,D1,D2) < 2Y. Otherwise, Carry = 0
;..and Y < (D1,D2) < 2Y. Either way, perform R - Y
   sub.l                d5,d2           ; ...lo(R) - lo(Y)
   subx.l               d4,d1           ; ...hi(R) - hi(Y)
   clr.l                d6              ; ...clear carry
   addq.l               #1,d3           ; ...Q := Q + 1

R_LT_Y:
;..At this point, Carry=0, R < Y. R = 2^(k-L)X - QY; k+j = L; j >= 0.
   tst.l                d0              ; ...see if j = 0.
   beq.s                PostLoop

   add.l                d3,d3           ; ...Q := 2Q
   add.l                d2,d2           ; ...lo(R) = 2lo(R)
   roxl.l               #1,d1           ; ...hi(R) = 2hi(R) + carry
   scs                  d6              ; ...set Carry if 2(R) overflows
   addq.l               #1,a1           ; ...k := k+1
   subq.l               #1,d0           ; ...j := j - 1
;..At this point, R=(Carry,D1,D2) = 2^(k-L)X - QY, j+k=L, j >= 0, R < 2Y.

   bra.s                Mod_Loop

PostLoop:
;..k = L, j = 0, Carry = 0, R = (D1,D2) = X - QY, R < Y.

;..normalize R.
   move.l               L_SCR1(a6),d0           ; ...new biased expo of R
   tst.l                d1
   bne.s                HiR_not0

HiR_0:
   move.l               d2,d1
   clr.l                d2
   subi.l               #32,d0
   clr.l                d6
   bfffo                d1{0:32},d6
   lsl.l                d6,d1
   sub.l                d6,d0           ; ...(D0,D1,D2) is normalized
;                                       ...with bias $7FFD
   bra.s                Get_Mod

HiR_not0:
   clr.l                d6
   bfffo                d1{0:32},d6
   bmi.s                Get_Mod         ; ...already normalized
   sub.l                d6,d0
   lsl.l                d6,d1
   move.l               d2,d7           ; ...a copy of D2
   lsl.l                d6,d2
   neg.l                d6
   addi.l               #32,d6
   lsr.l                d6,d7
   or.l                 d7,d1           ; ...(D0,D1,D2) normalized

;
Get_Mod:
   cmpi.l		#$000041FE,d0
   bge.s		No_Scale
Do_Scale:
   move.w		d0,R(a6)
   clr.w		R+2(a6)
   move.l		d1,R_Hi(a6)
   move.l		d2,R_Lo(a6)
   move.l		L_SCR1(a6),d6
   move.w		d6,Y(a6)
   clr.w		Y+2(a6)
   move.l		d4,Y_Hi(a6)
   move.l		d5,Y_Lo(a6)
   fmove.x		R(a6),fp0		; ...no exception
   move.l		#1,Sc_Flag(a6)
   bra.s		ModOrRem
No_Scale:
   move.l		d1,R_Hi(a6)
   move.l		d2,R_Lo(a6)
   subi.l		#$3FFE,d0
   move.w		d0,R(a6)
   clr.w		R+2(a6)
   move.l		L_SCR1(a6),d6
   subi.l		#$3FFE,d6
   move.l		d6,L_SCR1(a6)
   fmove.x		R(a6),fp0
   move.w		d6,Y(a6)
   move.l		d4,Y_Hi(a6)
   move.l		d5,Y_Lo(a6)
   move.l		#0,Sc_Flag(a6)

;


ModOrRem:
   move.l               Mod_Flag(a6),d6
   beq.s                Fix_Sign

   move.l               L_SCR1(a6),d6           ; ...new biased expo(Y)
   subq.l               #1,d6           ; ...biased expo(Y/2)
   cmp.l                d6,d0
   blt.s                Fix_Sign
   bgt.s                Last_Sub

   cmp.l                d4,d1
   bne.s                Not_EQ
   cmp.l                d5,d2
   bne.s                Not_EQ
   bra                Tie_Case

Not_EQ:
   bcs.s                Fix_Sign

Last_Sub:
;
   fsub.x		Y(a6),fp0		; ...no exceptions
   addq.l               #1,d3           ; ...Q := Q + 1

;

Fix_Sign:
;..Get sign of X
   move.w               SignX(a6),d6
   bge.s		Get_Q
   fneg.x		fp0

;..Get Q
;
Get_Q:
   clr.l		d6		
   move.w               SignQ(a6),d6        ; ...D6 is sign(Q)
   move.l               #8,d7
   lsr.l                d7,d6           
   andi.l               #$0000007F,d3   ; ...7 bits of Q
   or.l                 d6,d3           ; ...sign and bits of Q
   swap                 d3
   fmove.l              fpsr,d6
   andi.l               #$FF00FFFF,d6
   or.l                 d3,d6
   fmove.l              d6,fpsr         ; ...put Q in fpsr

;
Restore:
   movem.l              (a7)+,d2-d7
   fmove.l              USER_FPCR(a6),fpcr
   move.l               Sc_Flag(a6),d0
   beq.s                Finish
   fmul.x		Scale(pc),fp0	; ...may cause underflow
   bra			t_avoid_unsupp	;check for denorm as a
;					;result of the scaling

Finish:
	fmove.x		fp0,fp0		;capture exceptions & round
	rts

Rem_is_0:
;..R = 2^(-j)X - Q Y = Y, thus R = 0 and quotient = 2^j (Q+1)
   addq.l               #1,d3
   cmpi.l               #8,d0           ; ...D0 is j 
   bge.s                Q_Big

   lsl.l                d0,d3
   bra.s                Set_R_0

Q_Big:
   clr.l                d3

Set_R_0:
   fmove.s		#$00000000,fp0
   move.l		#0,Sc_Flag(a6)
   bra                Fix_Sign

Tie_Case:
;..Check parity of Q
   move.l               d3,d6
   andi.l               #$00000001,d6
   tst.l                d6
   beq                Fix_Sign	; ...Q is even

;..Q is odd, Q := Q + 1, signX := -signX
   addq.l               #1,d3
   move.w               SignX(a6),d6
   eori.l               #$00008000,d6
   move.w               d6,SignX(a6)
   bra                Fix_Sign

   ;end
;
;	ssin.sa 3.3 7/29/91
;
;	The entry point sSIN computes the sine of an input argument
;	sCOS computes the cosine, and sSINCOS computes both. The
;	corresponding entry points with a "d" computes the same
;	corresponding function values for denormalized inputs.
;
;	Input: Double-extended number X in location pointed to
;		by address register a0.
;
;	Output: The function value sin(X) or cos(X) returned in Fp0 if SIN or
;		COS is requested. Otherwise, for SINCOS, sin(X) is returned
;		in Fp0, and cos(X) is returned in Fp1.
;
;	Modifies: Fp0 for SIN or COS; both Fp0 and Fp1 for SINCOS.
;
;	Accuracy and Monotonicity: The returned result is within 1 ulp in
;		64 significant bit, i.e. within 0.5001 ulp to 53 bits if the
;		result is subsequently rounded to double precision. The
;		result is provably monotonic in double precision.
;
;	Speed: The programs sSIN and sCOS take approximately 150 cycles for
;		input argument X such that |X; < 15Pi, which is the the usual
;		situation. The speed for sSINCOS is approximately 190 cycles.
;
;	Algorithm:
;
;	SIN and COS:
;	1. If SIN is invoked, set AdjN := 0; otherwise, set AdjN := 1.
;
;	2. If |X; >= 15Pi or |X; < 2**(-40), go to 7.
;
;	3. Decompose X as X = N(Pi/2) + r where |r; <= Pi/4. Let
;		k = N mod 4, so in particular, k = 0,1,2,or 3. Overwrite
;		k by k := k + AdjN.
;
;	4. If k is even, go to 6.
;
;	5. (k is odd) Set j := (k-1)/2, sgn := (-1)**j. Return sgn*cos(r)
;		where cos(r) is approximated by an even polynomial in r,
;		1 + r*r*(B1+s*(B2+ ... + s*B8)),	s = r*r.
;		Exit.
;
;	6. (k is even) Set j := k/2, sgn := (-1)**j. Return sgn*sin(r)
;		where sin(r) is approximated by an odd polynomial in r
;		r + r*s*(A1+s*(A2+ ... + s*A7)),	s = r*r.
;		Exit.
;
;	7. If |X; > 1, go to 9.
;
;	8. (|X|<2**(-40)) If SIN is invoked, return X; otherwise return 1.
;
;	9. Overwrite X by X := X rem 2Pi. Now that |X; <= Pi, go back to 3.
;
;	SINCOS:
;	1. If |X; >= 15Pi or |X; < 2**(-40), go to 6.
;
;	2. Decompose X as X = N(Pi/2) + r where |r; <= Pi/4. Let
;		k = N mod 4, so in particular, k = 0,1,2,or 3.
;
;	3. If k is even, go to 5.
;
;	4. (k is odd) Set j1 := (k-1)/2, j2 := j1 (EOR) (k mod 2), i.e.
;		j1 exclusive or with the l.s.b. of k.
;		sgn1 := (-1)**j1, sgn2 := (-1)**j2.
;		SIN(X) = sgn1 * cos(r) and COS(X) = sgn2*sin(r) where
;		sin(r) and cos(r) are computed as odd and even polynomials
;		in r, respectively. Exit
;
;	5. (k is even) Set j1 := k/2, sgn1 := (-1)**j1.
;		SIN(X) = sgn1 * sin(r) and COS(X) = sgn1*cos(r) where
;		sin(r) and cos(r) are computed as odd and even polynomials
;		in r, respectively. Exit
;
;	6. If |X; > 1, go to 8.
;
;	7. (|X|<2**(-40)) SIN(X) = X and COS(X) = 1. Exit.
;
;	8. Overwrite X by X := X rem 2Pi. Now that |X; <= Pi, go back to 2.
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;SSIN	idnt	2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	

;BOUNDS1:	dc.l $3FD78000,$4004BC7E
;TWOBYPI:	dc.l $3FE45F30,$6DC9C883

SINA7:	dc.l $BD6AAA77,$CCC994F5
SINA6:	dc.l $3DE61209,$7AAE8DA1

SINA5:	dc.l $BE5AE645,$2A118AE4
SINA4:	dc.l $3EC71DE3,$A5341531

SINA3:	dc.l $BF2A01A0,$1A018B59,$00000000,$00000000

SINA2:	dc.l $3FF80000,$88888888,$888859AF,$00000000

SINA1:	dc.l $BFFC0000,$AAAAAAAA,$AAAAAA99,$00000000

COSB8:	dc.l $3D2AC4D0,$D6011EE3
COSB7:	dc.l $BDA9396F,$9F45AC19

COSB6:	dc.l $3E21EED9,$0612C972
COSB5:	dc.l $BE927E4F,$B79D9FCF

COSB4:	dc.l $3EFA01A0,$1A01D423,$00000000,$00000000

COSB3:	dc.l $BFF50000,$B60B60B6,$0B61D438,$00000000

COSB2:	dc.l $3FFA0000,$AAAAAAAA,$AAAAAB5E
COSB1:	dc.l $BF000000

;INVTWOPI: dc.l $3FFC0000,$A2F9836E,$4E44152A

;TWOPI1:	dc.l $40010000,$C90FDAA2,$00000000,$00000000
;TWOPI2:	dc.l $3FDF0000,$85A308D4,$00000000,$00000000

	;xref	PITBL
INARG1 = FP_SCR4
X2 = FP_SCR5
XDCARE3 = X2+2
XFRAC3 = X2+4
RPRIME = FP_SCR1
SPRIME = FP_SCR2
POSNEG1 = L_SCR1
TWOTO63 = L_SCR1
ENDFLAG = L_SCR2
N2 = L_SCR2
ADJN = L_SCR3

	; xref	t_frcinx
	;xref	t_extdnrm
	;xref	sto_cos

	;|.global	ssind
ssind:
;--SIN(X) = X FOR DENORMALIZED X
	bra		t_extdnrm

	;|.global	scosd
scosd:
;--COS(X) = 1 FOR DENORMALIZED X

	fmove.s		#$3F800000,fp0
;
;	9D25B Fix: Sometimes the previous fmove.s sets fpsr bits
;
	fmove.l		#0,fpsr
;
	bra		t_frcinx

	;|.global	ssin
ssin:
;--SET ADJN TO 0
	move.l		#0,ADJN(a6)
	bra.s		SINBGN

	;|.global	scos
scos:
;--SET ADJN TO 1
	move.l		#1,ADJN(a6)

SINBGN:
;--SAVE FPCR, FP1. CHECK IF |X; IS TOO SMALL OR LARGE

	fmove.x		(a0),fp0	; ...LOAD INPUT

	move.l		(a0),d0
	move.w		4(a0),d0
	fmove.x		fp0,X2(a6)
	andi.l		#$7FFFFFFF,d0		; ...COMPACTIFY X

	cmpi.l		#$3FD78000,d0		; ...|X; >= 2**(-40)?
	bge.s		SOK1
	bra		SINSM

SOK1:
	cmpi.l		#$4004BC7E,d0		; ...|X; < 15 PI?
	blt.s		SINMAIN
	bra		REDUCEX

SINMAIN:
;--THIS IS THE USUAL CASE, |X; <= 15 PI.
;--THE ARGUMENT REDUCTION IS DONE BY TABLE LOOK UP.
	fmove.x		fp0,fp1
	fmul.d		TWOBYPI(pc),fp1	; ...X*2/PI

;--HIDE THE NEXT THREE INSTRUCTIONS
	lea		PITBL+$200,a1 ; ...TABLE OF N*PI/2, N = -32,...,32
	

;--FP1 IS NOW READY
	fmove.l		fp1,N2(a6)		; ...CONVERT TO INTEGER

	move.l		N2(a6),d0
	asl.l		#4,d0
	adda.l		d0,a1	; ...A1 IS THE ADDRESS OF N*PIBY2
;				...WHICH IS IN TWO PIECES Y1 & Y2

	fsub.x		(a1)+,fp0	; ...X-Y1
;--HIDE THE NEXT ONE
	fsub.s		(a1),fp0	; ...FP0 IS R = (X-Y1)-Y2

SINCONT:
;--continuation from REDUCEX

;--GET N+ADJN AND SEE IF SIN(R) OR COS(R) IS NEEDED
	move.l		N2(a6),d0
	add.l		ADJN(a6),d0	; ...SEE IF D0 IS ODD OR EVEN
	ror.l		#1,d0	; ...D0 WAS ODD IFF D0 IS NEGATIVE
	cmpi.l		#0,d0
	blt		COSPOLY

SINPOLY:
;--LET J BE THE LEAST SIG. BIT OF D0, LET SGN := (-1)**J.
;--THEN WE RETURN	SGN*SIN(R). SGN*SIN(R) IS COMPUTED BY
;--R' + R'*S*(A1 + S(A2 + S(A3 + S(A4 + ... + SA7)))), WHERE
;--R' = SGN*R, S=R*R. THIS CAN BE REWRITTEN AS
;--R' + R'*S*( [A1+T(A3+T(A5+TA7))] + [S(A2+T(A4+TA6))])
;--WHERE T=S*S.
;--NOTE THAT A3 THROUGH A7 ARE STORED IN DOUBLE PRECISION
;--WHILE A1 AND A2 ARE IN DOUBLE-EXTENDED FORMAT.
	fmove.x		fp0,X2(a6)	; ...X IS R
	fmul.x		fp0,fp0	; ...FP0 IS S
;---HIDE THE NEXT TWO WHILE WAITING FOR FP0
	fmove.d		SINA7(pc),fp3
	fmove.d		SINA6(pc),fp2
;--FP0 IS NOW READY
	fmove.x		fp0,fp1
	fmul.x		fp1,fp1	; ...FP1 IS T
;--HIDE THE NEXT TWO WHILE WAITING FOR FP1

	ror.l		#1,d0
	andi.l		#$80000000,d0
;				...LEAST SIG. BIT OF D0 IN SIGN POSITION
	eor.l		d0,X2(a6)	; ...X IS NOW R'= SGN*R

	fmul.x		fp1,fp3	; ...TA7
	fmul.x		fp1,fp2	; ...TA6

	fadd.d		SINA5(pc),fp3 ; ...A5+TA7
	fadd.d		SINA4(pc),fp2 ; ...A4+TA6

	fmul.x		fp1,fp3	; ...T(A5+TA7)
	fmul.x		fp1,fp2	; ...T(A4+TA6)

	fadd.d		SINA3(pc),fp3 ; ...A3+T(A5+TA7)
	fadd.x		SINA2(pc),fp2 ; ...A2+T(A4+TA6)

	fmul.x		fp3,fp1	; ...T(A3+T(A5+TA7))

	fmul.x		fp0,fp2	; ...S(A2+T(A4+TA6))
	fadd.x		SINA1(pc),fp1 ; ...A1+T(A3+T(A5+TA7))
	fmul.x		X2(a6),fp0	; ...R'*S

	fadd.x		fp2,fp1	; ...[A1+T(A3+T(A5+TA7))]+[S(A2+T(A4+TA6))]
;--FP3 RELEASED, RESTORE NOW AND TAKE SOME ADVANTAGE OF HIDING
;--FP2 RELEASED, RESTORE NOW AND TAKE FULL ADVANTAGE OF HIDING
	

	fmul.x		fp1,fp0		; ...SIN(R')-R'
;--FP1 RELEASED.

	fmove.l		d1,FPCR		;restore users exceptions
	fadd.x		X2(a6),fp0		;last inst - possible exception set
	bra		t_frcinx


COSPOLY:
;--LET J BE THE LEAST SIG. BIT OF D0, LET SGN := (-1)**J.
;--THEN WE RETURN	SGN*COS(R). SGN*COS(R) IS COMPUTED BY
;--SGN + S'*(B1 + S(B2 + S(B3 + S(B4 + ... + SB8)))), WHERE
;--S=R*R AND S'=SGN*S. THIS CAN BE REWRITTEN AS
;--SGN + S'*([B1+T(B3+T(B5+TB7))] + [S(B2+T(B4+T(B6+TB8)))])
;--WHERE T=S*S.
;--NOTE THAT B4 THROUGH B8 ARE STORED IN DOUBLE PRECISION
;--WHILE B2 AND B3 ARE IN DOUBLE-EXTENDED FORMAT, B1 IS -1/2
;--AND IS THEREFORE STORED AS SINGLE PRECISION.

	fmul.x		fp0,fp0	; ...FP0 IS S
;---HIDE THE NEXT TWO WHILE WAITING FOR FP0
	fmove.d		COSB8(pc),fp2
	fmove.d		COSB7(pc),fp3
;--FP0 IS NOW READY
	fmove.x		fp0,fp1
	fmul.x		fp1,fp1	; ...FP1 IS T
;--HIDE THE NEXT TWO WHILE WAITING FOR FP1
	fmove.x		fp0,X2(a6)	; ...X IS S
	ror.l		#1,d0
	andi.l		#$80000000,d0
;			...LEAST SIG. BIT OF D0 IN SIGN POSITION

	fmul.x		fp1,fp2	; ...TB8
;--HIDE THE NEXT TWO WHILE WAITING FOR THE XU
	eor.l		d0,X2(a6)	; ...X IS NOW S'= SGN*S
	andi.l		#$80000000,d0

	fmul.x		fp1,fp3	; ...TB7
;--HIDE THE NEXT TWO WHILE WAITING FOR THE XU
	ori.l		#$3F800000,d0	; ...D0 IS SGN IN SINGLE
	move.l		d0,POSNEG1(a6)

	fadd.d		COSB6(pc),fp2 ; ...B6+TB8
	fadd.d		COSB5(pc),fp3 ; ...B5+TB7

	fmul.x		fp1,fp2	; ...T(B6+TB8)
	fmul.x		fp1,fp3	; ...T(B5+TB7)

	fadd.d		COSB4(pc),fp2 ; ...B4+T(B6+TB8)
	fadd.x		COSB3(pc),fp3 ; ...B3+T(B5+TB7)

	fmul.x		fp1,fp2	; ...T(B4+T(B6+TB8))
	fmul.x		fp3,fp1	; ...T(B3+T(B5+TB7))

	fadd.x		COSB2(pc),fp2 ; ...B2+T(B4+T(B6+TB8))
	fadd.s		COSB1(pc),fp1 ; ...B1+T(B3+T(B5+TB7))

	fmul.x		fp2,fp0	; ...S(B2+T(B4+T(B6+TB8)))
;--FP3 RELEASED, RESTORE NOW AND TAKE SOME ADVANTAGE OF HIDING
;--FP2 RELEASED.
	

	fadd.x		fp1,fp0
;--FP1 RELEASED

	fmul.x		X2(a6),fp0

	fmove.l		d1,FPCR		;restore users exceptions
	fadd.s		POSNEG1(a6),fp0	;last inst - possible exception set
	bra		t_frcinx


SINBORS:
;--IF |X; > 15PI, WE USE THE GENERAL ARGUMENT REDUCTION.
;--IF |X; < 2**(-40), RETURN X OR 1.
	cmpi.l		#$3FFF8000,d0
	bgt.s		REDUCEX
        

SINSM:
	move.l		ADJN(a6),d0
	cmpi.l		#0,d0
	bgt.s		COSTINY

SINTINY:
	move.w		#$0000,XDCARE3(a6)	; ...JUST IN CASE
	fmove.l		d1,FPCR		;restore users exceptions
	fmove.x		X2(a6),fp0		;last inst - possible exception set
	bra		t_frcinx


COSTINY:
	fmove.s		#$3F800000,fp0

	fmove.l		d1,FPCR		;restore users exceptions
	fsub.s		#$00800000,fp0	;last inst - possible exception set
	bra		t_frcinx


REDUCEX:
;--WHEN REDUCEX IS USED, THE CODE WILL INEVITABLY BE SLOW.
;--THIS REDUCTION METHOD, HOWEVER, IS MUCH FASTER THAN USING
;--THE REMAINDER INSTRUCTION WHICH IS NOW IN SOFTWARE.

	fmovem.x	fp2-fp5,-(a7)	; ...save FP2 through FP5
	move.l		d2,-(a7)
        fmove.s         #$00000000,fp1
;--If compact form of abs(arg) in d0=$7ffeffff, argument is so large that
;--there is a danger of unwanted overflow in first LOOP iteration.  In this
;--case, reduce argument by one remainder step to make subsequent reduction
;--safe.
	cmpi.l	#$7ffeffff,d0		;is argument dangerously large?
	bne.s	LOOP_
	move.l	#$7ffe0000,FP_SCR2(a6)	;yes
;					;create 2**16383*PI/2
	move.l	#$c90fdaa2,FP_SCR2+4(a6)
	clr.l	FP_SCR2+8(a6)
	ftst.x	fp0			;test sign of argument
	move.l	#$7fdc0000,FP_SCR3(a6)	;create low half of 2**16383*
;					;PI/2 at FP_SCR3
	move.l	#$85a308d3,FP_SCR3+4(a6)
	clr.l   FP_SCR3+8(a6)
	fblt	.red_neg
	or.w	#$8000,FP_SCR2(a6)	;positive arg
	or.w	#$8000,FP_SCR3(a6)
.red_neg:
	fadd.x  FP_SCR2(a6),fp0		;high part of reduction is exact
	fmove.x  fp0,fp1		;save high result in fp1
	fadd.x  FP_SCR3(a6),fp0		;low part of reduction
	fsub.x  fp0,fp1			;determine low component of result
	fadd.x  FP_SCR3(a6),fp1		;fp0/fp1 are reduced argument.

;--ON ENTRY, FP0 IS X, ON RETURN, FP0 IS X REM PI/2, |X; <= PI/4.
;--integer quotient will be stored in N
;--Intermediate remainder is 66-bit long; (R,r) in (FP0,FP1)

LOOP_:
	fmove.x		fp0,INARG1(a6)	; ...+-2**K * F, 1 <= F < 2
	move.w		INARG1(a6),d0
        move.l          d0,a1		; ...save a copy of D0
	andi.l		#$00007FFF,d0
	subi.l		#$00003FFF,d0	; ...D0 IS K
	cmpi.l		#28,d0
	ble.s		.LASTLOOP
;CONTLOOP:
	subi.l		#27,d0	 ; ...D0 IS L := K-27
	move.l		#0,ENDFLAG(a6)
	bra.s		.WORK
.LASTLOOP:
	clr.l		d0		; ...D0 IS L := 0
	move.l		#1,ENDFLAG(a6)

.WORK:
;--FIND THE REMAINDER OF (R,r) W.R.T.	2**L * (PI/2). L IS SO CHOSEN
;--THAT	INT( X * (2/PI) / 2**(L) ) < 2**29.

;--CREATE 2**(-L) * (2/PI), SIGN(INARG1)*2**(63),
;--2**L * (PIby2_1), 2**L * (PIby2_2)

	move.l		#$00003FFE,d2	; ...BIASED EXPO OF 2/PI
	sub.l		d0,d2		; ...BIASED EXPO OF 2**(-L)*(2/PI)

	move.l		#$A2F9836E,FP_SCR1+4(a6)
	move.l		#$4E44152A,FP_SCR1+8(a6)
	move.w		d2,FP_SCR1(a6)	; ...FP_SCR1 is 2**(-L)*(2/PI)

	fmove.x		fp0,fp2
	fmul.x		FP_SCR1(a6),fp2
;--WE MUST NOW FIND INT(FP2). SINCE WE NEED THIS VALUE IN
;--FLOATING POINT FORMAT, THE TWO FMOVE'S	FMOVE.L FP <--> N
;--WILL BE TOO INEFFICIENT. THE WAY AROUND IT IS THAT
;--(SIGN(INARG1)*2**63	+	FP2) - SIGN(INARG1)*2**63 WILL GIVE
;--US THE DESIRED VALUE IN FLOATING POINT.

;--HIDE SIX CYCLES OF INSTRUCTION
        move.l		a1,d2
        swap		d2
	andi.l		#$80000000,d2
	ori.l		#$5F000000,d2	; ...D2 IS SIGN(INARG1)*2**63 IN SGL
	move.l		d2,TWOTO63(a6)

	move.l		d0,d2
	addi.l		#$00003FFF,d2	; ...BIASED EXPO OF 2**L * (PI/2)

;--FP2 IS READY
	fadd.s		TWOTO63(a6),fp2	; ...THE FRACTIONAL PART OF FP1 IS ROUNDED

;--HIDE 4 CYCLES OF INSTRUCTION; creating 2**(L)*Piby2_1  and  2**(L)*Piby2_2
        move.w		d2,FP_SCR2(a6)
	clr.w           FP_SCR2+2(a6)
	move.l		#$C90FDAA2,FP_SCR2+4(a6)
	clr.l		FP_SCR2+8(a6)		; ...FP_SCR2 is  2**(L) * Piby2_1	

;--FP2 IS READY
	fsub.s		TWOTO63(a6),fp2		; ...FP2 is N

	addi.l		#$00003FDD,d0
        move.w		d0,FP_SCR3(a6)
	clr.w           FP_SCR3+2(a6)
	move.l		#$85A308D3,FP_SCR3+4(a6)
	clr.l		FP_SCR3+8(a6)		; ...FP_SCR3 is 2**(L) * Piby2_2

	move.l		ENDFLAG(a6),d0

;--We are now ready to perform (R+r) - N*P1 - N*P2, P1 = 2**(L) * Piby2_1 and
;--P2 = 2**(L) * Piby2_2
	fmove.x		fp2,fp4
	fmul.x		FP_SCR2(a6),fp4		; ...W = N*P1
	fmove.x		fp2,fp5
	fmul.x		FP_SCR3(a6),fp5		; ...w = N*P2
	fmove.x		fp4,fp3
;--we want P+p = W+w  but  |p; <= half ulp of P
;--Then, we need to compute  A := R-P   and  a := r-p
	fadd.x		fp5,fp3			; ...FP3 is P
	fsub.x		fp3,fp4			; ...W-P

	fsub.x		fp3,fp0			; ...FP0 is A := R - P
        fadd.x		fp5,fp4			; ...FP4 is p = (W-P)+w

	fmove.x		fp0,fp3			; ...FP3 A
	fsub.x		fp4,fp1			; ...FP1 is a := r - p

;--Now we need to normalize (A,a) to  "new (R,r)" where R+r = A+a but
;--|r; <= half ulp of R.
	fadd.x		fp1,fp0			; ...FP0 is R := A+a
;--No need to calculate r if this is the last loop
	cmpi.l		#0,d0
	bgt		RESTORE

;--Need to calculate r
	fsub.x		fp0,fp3			; ...A-R
	fadd.x		fp3,fp1			; ...FP1 is r := (A-R)+a
	bra		LOOP_

RESTORE:
        fmove.l		fp2,N2(a6)
	move.l		(a7)+,d2
	fmovem.x	(a7)+,fp2-fp5

	
	move.l		ADJN(a6),d0
	cmpi.l		#4,d0

	blt		SINCONT
	bra.s		SCCONT

	;|.global	ssincosd
ssincosd:
;--SIN AND COS OF X FOR DENORMALIZED X

	fmove.s		#$3F800000,fp1
	bsr		sto_cos		;store cosine result
	bra		t_extdnrm

	;|.global	ssincos
ssincos:
;--SET ADJN TO 4
	move.l		#4,ADJN(a6)

	fmove.x		(a0),fp0	; ...LOAD INPUT

	move.l		(a0),d0
	move.w		4(a0),d0
	fmove.x		fp0,X2(a6)
	andi.l		#$7FFFFFFF,d0		; ...COMPACTIFY X

	cmpi.l		#$3FD78000,d0		; ...|X; >= 2**(-40)?
	bge.s		SCOK1
	bra		SCSM

SCOK1:
	cmpi.l		#$4004BC7E,d0		; ...|X; < 15 PI?
	blt.s		SCMAIN
	bra		REDUCEX


SCMAIN:
;--THIS IS THE USUAL CASE, |X; <= 15 PI.
;--THE ARGUMENT REDUCTION IS DONE BY TABLE LOOK UP.
	fmove.x		fp0,fp1
	fmul.d		TWOBYPI(pc),fp1	; ...X*2/PI

;--HIDE THE NEXT THREE INSTRUCTIONS
	lea		PITBL+$200,a1 ; ...TABLE OF N*PI/2, N = -32,...,32
	

;--FP1 IS NOW READY
	fmove.l		fp1,N2(a6)		; ...CONVERT TO INTEGER

	move.l		N2(a6),d0
	asl.l		#4,d0
	adda.l		d0,a1		; ...ADDRESS OF N*PIBY2, IN Y1, Y2

	fsub.x		(a1)+,fp0	; ...X-Y1
        fsub.s		(a1),fp0	; ...FP0 IS R = (X-Y1)-Y2

SCCONT:
;--continuation point from REDUCEX

;--HIDE THE NEXT TWO
	move.l		N2(a6),d0
	ror.l		#1,d0
	
	cmpi.l		#0,d0		; ...D0 < 0 IFF N IS ODD
	bge		NEVEN

;NODD:
;--REGISTERS SAVED SO FAR: D0, A0, FP2.

	fmove.x		fp0,RPRIME(a6)
	fmul.x		fp0,fp0	 ; ...FP0 IS S = R*R
	fmove.d		SINA7(pc),fp1	; ...A7
	fmove.d		COSB8(pc),fp2	; ...B8
	fmul.x		fp0,fp1	 ; ...SA7
	move.l		d2,-(a7)
	move.l		d0,d2
	fmul.x		fp0,fp2	 ; ...SB8
	ror.l		#1,d2
	andi.l		#$80000000,d2

	fadd.d		SINA6(pc),fp1	; ...A6+SA7
	eor.l		d0,d2
	andi.l		#$80000000,d2
	fadd.d		COSB7(pc),fp2	; ...B7+SB8

	fmul.x		fp0,fp1	 ; ...S(A6+SA7)
	eor.l		d2,RPRIME(a6)
	move.l		(a7)+,d2
	fmul.x		fp0,fp2	 ; ...S(B7+SB8)
	ror.l		#1,d0
	andi.l		#$80000000,d0

	fadd.d		SINA5(pc),fp1	; ...A5+S(A6+SA7)
	move.l		#$3F800000,POSNEG1(a6)
	eor.l		d0,POSNEG1(a6)
	fadd.d		COSB6(pc),fp2	; ...B6+S(B7+SB8)

	fmul.x		fp0,fp1	 ; ...S(A5+S(A6+SA7))
	fmul.x		fp0,fp2	 ; ...S(B6+S(B7+SB8))
	fmove.x		fp0,SPRIME(a6)

	fadd.d		SINA4(pc),fp1	; ...A4+S(A5+S(A6+SA7))
	eor.l		d0,SPRIME(a6)
	fadd.d		COSB5(pc),fp2	; ...B5+S(B6+S(B7+SB8))

	fmul.x		fp0,fp1	 ; ...S(A4+...)
	fmul.x		fp0,fp2	 ; ...S(B5+...)

	fadd.d		SINA3(pc),fp1	; ...A3+S(A4+...)
	fadd.d		COSB4(pc),fp2	; ...B4+S(B5+...)

	fmul.x		fp0,fp1	 ; ...S(A3+...)
	fmul.x		fp0,fp2	 ; ...S(B4+...)

	fadd.x		SINA2(pc),fp1	; ...A2+S(A3+...)
	fadd.x		COSB3(pc),fp2	; ...B3+S(B4+...)

	fmul.x		fp0,fp1	 ; ...S(A2+...)
	fmul.x		fp0,fp2	 ; ...S(B3+...)

	fadd.x		SINA1(pc),fp1	; ...A1+S(A2+...)
	fadd.x		COSB2(pc),fp2	; ...B2+S(B3+...)

	fmul.x		fp0,fp1	 ; ...S(A1+...)
	fmul.x		fp2,fp0	 ; ...S(B2+...)

	

	fmul.x		RPRIME(a6),fp1	; ...R'S(A1+...)
	fadd.s		COSB1(pc),fp0	; ...B1+S(B2...)
	fmul.x		SPRIME(a6),fp0	; ...S'(B1+S(B2+...))

	move.l		d1,-(sp)	;restore users mode & precision
	andi.l		#$ff,d1		;mask off all exceptions
	fmove.l		d1,FPCR
	fadd.x		RPRIME(a6),fp1	; ...COS(X)
	bsr		sto_cos		;store cosine result
	fmove.l		(sp)+,FPCR	;restore users exceptions
	fadd.s		POSNEG1(a6),fp0	; ...SIN(X)

	bra		t_frcinx


NEVEN:
;--REGISTERS SAVED SO FAR: FP2.

	fmove.x		fp0,RPRIME(a6)
	fmul.x		fp0,fp0	 ; ...FP0 IS S = R*R
	fmove.d		COSB8(pc),fp1			; ...B8
	fmove.d		SINA7(pc),fp2			; ...A7
	fmul.x		fp0,fp1	 ; ...SB8
	fmove.x		fp0,SPRIME(a6)
	fmul.x		fp0,fp2	 ; ...SA7
	ror.l		#1,d0
	andi.l		#$80000000,d0
	fadd.d		COSB7(pc),fp1	; ...B7+SB8
	fadd.d		SINA6(pc),fp2	; ...A6+SA7
	eor.l		d0,RPRIME(a6)
	eor.l		d0,SPRIME(a6)
	fmul.x		fp0,fp1	 ; ...S(B7+SB8)
	ori.l		#$3F800000,d0
	move.l		d0,POSNEG1(a6)
	fmul.x		fp0,fp2	 ; ...S(A6+SA7)

	fadd.d		COSB6(pc),fp1	; ...B6+S(B7+SB8)
	fadd.d		SINA5(pc),fp2	; ...A5+S(A6+SA7)

	fmul.x		fp0,fp1	 ; ...S(B6+S(B7+SB8))
	fmul.x		fp0,fp2	 ; ...S(A5+S(A6+SA7))

	fadd.d		COSB5(pc),fp1	; ...B5+S(B6+S(B7+SB8))
	fadd.d		SINA4(pc),fp2	; ...A4+S(A5+S(A6+SA7))

	fmul.x		fp0,fp1	 ; ...S(B5+...)
	fmul.x		fp0,fp2	 ; ...S(A4+...)

	fadd.d		COSB4(pc),fp1	; ...B4+S(B5+...)
	fadd.d		SINA3(pc),fp2	; ...A3+S(A4+...)

	fmul.x		fp0,fp1	 ; ...S(B4+...)
	fmul.x		fp0,fp2	 ; ...S(A3+...)

	fadd.x		COSB3(pc),fp1	; ...B3+S(B4+...)
	fadd.x		SINA2(pc),fp2	; ...A2+S(A3+...)

	fmul.x		fp0,fp1	 ; ...S(B3+...)
	fmul.x		fp0,fp2	 ; ...S(A2+...)

	fadd.x		COSB2(pc),fp1	; ...B2+S(B3+...)
	fadd.x		SINA1(pc),fp2	; ...A1+S(A2+...)

	fmul.x		fp0,fp1	 ; ...S(B2+...)
	fmul.x		fp2,fp0	 ; ...s(a1+...)

	

	fadd.s		COSB1(pc),fp1	; ...B1+S(B2...)
	fmul.x		RPRIME(a6),fp0	; ...R'S(A1+...)
	fmul.x		SPRIME(a6),fp1	; ...S'(B1+S(B2+...))

	move.l		d1,-(sp)	;save users mode & precision
	andi.l		#$ff,d1		;mask off all exceptions
	fmove.l		d1,FPCR
	fadd.s		POSNEG1(a6),fp1	; ...COS(X)
	bsr		sto_cos		;store cosine result
	fmove.l		(sp)+,FPCR	;restore users exceptions
	fadd.x		RPRIME(a6),fp0	; ...SIN(X)

	bra		t_frcinx

SCBORS:
	cmpi.l		#$3FFF8000,d0
	bgt		REDUCEX
        

SCSM:
	move.w		#$0000,XDCARE3(a6)
	fmove.s		#$3F800000,fp1

	move.l		d1,-(sp)	;save users mode & precision
	andi.l		#$ff,d1		;mask off all exceptions
	fmove.l		d1,FPCR
	fsub.s		#$00800000,fp1
	bsr		sto_cos		;store cosine result
	fmove.l		(sp)+,FPCR	;restore users exceptions
	fmove.x		X2(a6),fp0
	bra		t_frcinx

	;end
;
;	ssinh.sa 3.1 12/10/90
;
;       The entry point sSinh computes the hyperbolic sine of
;       an input argument; sSinhd does the same except for denormalized
;       input.
;
;       Input: Double-extended number X in location pointed to 
;		by address register a0.
;
;       Output: The value sinh(X) returned in floating-point register Fp0.
;
;       Accuracy and Monotonicity: The returned result is within 3 ulps in
;               64 significant bit, i.e. within 0.5001 ulp to 53 bits if the
;               result is subsequently rounded to double precision. The
;               result is provably monotonic in double precision.
;
;       Speed: The program sSINH takes approximately 280 cycles.
;
;       Algorithm:
;
;       SINH
;       1. If |X; > 16380 log2, go to 3.
;
;       2. (|X; <= 16380 log2) Sinh(X) is obtained by the formulae
;               y = |X|, sgn = sign(X), and z = expm1(Y),
;               sinh(X) = sgn*(1/2)*( z + z/(1+z) ).
;          Exit.
;
;       3. If |X; > 16480 log2, go to 5.
;
;       4. (16380 log2 < |X; <= 16480 log2)
;               sinh(X) = sign(X) * exp(|X|)/2.
;          However, invoking exp(|X|) may cause premature overflow.
;          Thus, we calculate sinh(X) as follows:
;             Y       := |X; ;             sgn     := sign(X)
;             sgnFact := sgn * 2**(16380)
;             Y'      := Y - 16381 log2
;             sinh(X) := sgnFact * exp(Y').
;          Exit.
;
;       5. (|X; > 16480 log2) sinh(X) must overflow. Return
;          sign(X)*Huge*Huge to generate overflow and an infinity with
;          the appropriate sign. Huge is the largest finite number in
;          extended format. Exit.
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;SSINH	idnt	2,1 ; Motorola 040 Floating Point Software Package

	;section	8

T1:	dc.l $40C62D38,$D3D64634 ; ... 16381 LOG2 LEAD
T2:	dc.l $3D6F90AE,$B1E75CC7 ; ... 16381 LOG2 TRAIL

	;xref	t_frcinx
	;xref	t_ovfl
	;xref	t_extdnrm
	;xref	setox
	;xref	setoxm1

	;|.global	ssinhd
ssinhd:
;--SINH(X) = X FOR DENORMALIZED X

	bra	t_extdnrm

	;|.global	ssinh
ssinh:
	fmove.x	(a0),fp0	; ...LOAD INPUT

	move.l	(a0),d0
	move.w	4(a0),d0
	move.l	d0,a1		; save a copy of original (compacted) operand
	and.l	#$7FFFFFFF,d0
	cmp.l	#$400CB167,d0
	bgt.s	SINHBIG

;--THIS IS THE USUAL CASE, |X; < 16380 LOG2
;--Y = |X|, Z = EXPM1(Y), SINH(X) = SIGN(X)*(1/2)*( Z + Z/(1+Z) )

	fabs.x	fp0		; ...Y = |X; 
	movem.l	a1/d1,-(sp)
	fmovem.x fp0-fp0,(a0)
	clr.l	d1
	bsr	setoxm1	 	; ...FP0 IS Z = EXPM1(Y)
	fmove.l	#0,fpcr
	movem.l	(sp)+,a1/d1

	fmove.x	fp0,fp1
	fadd.s	#$3F800000,fp1	; ...1+Z
	fmove.x	fp0,-(sp)
	fdiv.x	fp1,fp0		; ...Z/(1+Z)
	move.l	a1,d0
	and.l	#$80000000,d0
	or.l	#$3F000000,d0
	fadd.x	(sp)+,fp0
	move.l	d0,-(sp)

	fmove.l	d1,fpcr
	fmul.s	(sp)+,fp0	;last fp inst - possible exceptions set

	bra	t_frcinx

SINHBIG:
	cmp.l	#$400CB2B3,d0
	bgt	t_ovfl
	fabs.x	fp0
	fsub.d	T1(pc),fp0	; ...(|X|-16381LOG2_LEAD)
	move.l	#0,-(sp)
	move.l	#$80000000,-(sp)
	move.l	a1,d0
	and.l	#$80000000,d0
	or.l	#$7FFB0000,d0
	move.l	d0,-(sp)	; ...EXTENDED FMT
	fsub.d	T2(pc),fp0	; ...|X; - 16381 LOG2, ACCURATE

	move.l	d1,-(sp)
	clr.l	d1
	fmovem.x fp0-fp0,(a0)
	bsr	setox
	fmove.l	(sp)+,fpcr

	fmul.x	(sp)+,fp0	;possible exception
	bra	t_frcinx

	;end
;
;	stan.sa 3.3 7/29/91
;
;	The entry point stan computes the tangent of
;	an input argument;
;	stand does the same except for denormalized input.
;
;	Input: Double-extended number X in location pointed to
;		by address register a0.
;
;	Output: The value tan(X) returned in floating-point register Fp0.
;
;	Accuracy and Monotonicity: The returned result is within 3 ulp in
;		64 significant bit, i.e. within 0.5001 ulp to 53 bits if the
;		result is subsequently rounded to double precision. The
;		result is provably monotonic in double precision.
;
;	Speed: The program sTAN takes approximately 170 cycles for
;		input argument X such that |X; < 15Pi, which is the the usual
;		situation.
;
;	Algorithm:
;
;	1. If |X; >= 15Pi or |X; < 2**(-40), go to 6.
;
;	2. Decompose X as X = N(Pi/2) + r where |r; <= Pi/4. Let
;		k = N mod 2, so in particular, k = 0 or 1.
;
;	3. If k is odd, go to 5.
;
;	4. (k is even) Tan(X) = tan(r) and tan(r) is approximated by a
;		rational function U/V where
;		U = r + r*s*(P1 + s*(P2 + s*P3)), and
;		V = 1 + s*(Q1 + s*(Q2 + s*(Q3 + s*Q4))),  s = r*r.
;		Exit.
;
;	4. (k is odd) Tan(X) = -cot(r). Since tan(r) is approximated by a
;		rational function U/V where
;		U = r + r*s*(P1 + s*(P2 + s*P3)), and
;		V = 1 + s*(Q1 + s*(Q2 + s*(Q3 + s*Q4))), s = r*r,
;		-Cot(r) = -V/U. Exit.
;
;	6. If |X; > 1, go to 8.
;
;	7. (|X|<2**(-40)) Tan(X) = X. Exit.
;
;	8. Overwrite X by X := X rem 2Pi. Now that |X; <= Pi, go back to 2.
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;STAN	idnt	2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	

;BOUNDS1:	dc.l $3FD78000,$4004BC7E
TWOBYPI:	dc.l $3FE45F30,$6DC9C883

TANQ4:	dc.l $3EA0B759,$F50F8688
TANP3:	dc.l $BEF2BAA5,$A8924F04

TANQ3:	dc.l $BF346F59,$B39BA65F,$00000000,$00000000

TANP2:	dc.l $3FF60000,$E073D3FC,$199C4A00,$00000000

TANQ2:	dc.l $3FF90000,$D23CD684,$15D95FA1,$00000000

TANP1:	dc.l $BFFC0000,$8895A6C5,$FB423BCA,$00000000

TANQ1:	dc.l $BFFD0000,$EEF57E0D,$A84BC8CE,$00000000

INVTWOPI: dc.l $3FFC0000,$A2F9836E,$4E44152A,$00000000

TWOPI1:	dc.l $40010000,$C90FDAA2,$00000000,$00000000
TWOPI2:	dc.l $3FDF0000,$85A308D4,$00000000,$00000000

;--N*PI/2, -32 <= N <= 32, IN A LEADING TERM IN EXT. AND TRAILING
;--TERM IN SGL. NOTE THAT PI IS 64-BIT LONG, THUS N*PI/2 IS AT
;--MOST 69 BITS LONG.
	;|.global	PITBL
PITBL:
  dc.l  $C0040000,$C90FDAA2,$2168C235,$21800000
  dc.l  $C0040000,$C2C75BCD,$105D7C23,$A0D00000
  dc.l  $C0040000,$BC7EDCF7,$FF523611,$A1E80000
  dc.l  $C0040000,$B6365E22,$EE46F000,$21480000
  dc.l  $C0040000,$AFEDDF4D,$DD3BA9EE,$A1200000
  dc.l  $C0040000,$A9A56078,$CC3063DD,$21FC0000
  dc.l  $C0040000,$A35CE1A3,$BB251DCB,$21100000
  dc.l  $C0040000,$9D1462CE,$AA19D7B9,$A1580000
  dc.l  $C0040000,$96CBE3F9,$990E91A8,$21E00000
  dc.l  $C0040000,$90836524,$88034B96,$20B00000
  dc.l  $C0040000,$8A3AE64F,$76F80584,$A1880000
  dc.l  $C0040000,$83F2677A,$65ECBF73,$21C40000
  dc.l  $C0030000,$FB53D14A,$A9C2F2C2,$20000000
  dc.l  $C0030000,$EEC2D3A0,$87AC669F,$21380000
  dc.l  $C0030000,$E231D5F6,$6595DA7B,$A1300000
  dc.l  $C0030000,$D5A0D84C,$437F4E58,$9FC00000
  dc.l  $C0030000,$C90FDAA2,$2168C235,$21000000
  dc.l  $C0030000,$BC7EDCF7,$FF523611,$A1680000
  dc.l  $C0030000,$AFEDDF4D,$DD3BA9EE,$A0A00000
  dc.l  $C0030000,$A35CE1A3,$BB251DCB,$20900000
  dc.l  $C0030000,$96CBE3F9,$990E91A8,$21600000
  dc.l  $C0030000,$8A3AE64F,$76F80584,$A1080000
  dc.l  $C0020000,$FB53D14A,$A9C2F2C2,$1F800000
  dc.l  $C0020000,$E231D5F6,$6595DA7B,$A0B00000
  dc.l  $C0020000,$C90FDAA2,$2168C235,$20800000
  dc.l  $C0020000,$AFEDDF4D,$DD3BA9EE,$A0200000
  dc.l  $C0020000,$96CBE3F9,$990E91A8,$20E00000
  dc.l  $C0010000,$FB53D14A,$A9C2F2C2,$1F000000
  dc.l  $C0010000,$C90FDAA2,$2168C235,$20000000
  dc.l  $C0010000,$96CBE3F9,$990E91A8,$20600000
  dc.l  $C0000000,$C90FDAA2,$2168C235,$1F800000
  dc.l  $BFFF0000,$C90FDAA2,$2168C235,$1F000000
  dc.l  $00000000,$00000000,$00000000,$00000000
  dc.l  $3FFF0000,$C90FDAA2,$2168C235,$9F000000
  dc.l  $40000000,$C90FDAA2,$2168C235,$9F800000
  dc.l  $40010000,$96CBE3F9,$990E91A8,$A0600000
  dc.l  $40010000,$C90FDAA2,$2168C235,$A0000000
  dc.l  $40010000,$FB53D14A,$A9C2F2C2,$9F000000
  dc.l  $40020000,$96CBE3F9,$990E91A8,$A0E00000
  dc.l  $40020000,$AFEDDF4D,$DD3BA9EE,$20200000
  dc.l  $40020000,$C90FDAA2,$2168C235,$A0800000
  dc.l  $40020000,$E231D5F6,$6595DA7B,$20B00000
  dc.l  $40020000,$FB53D14A,$A9C2F2C2,$9F800000
  dc.l  $40030000,$8A3AE64F,$76F80584,$21080000
  dc.l  $40030000,$96CBE3F9,$990E91A8,$A1600000
  dc.l  $40030000,$A35CE1A3,$BB251DCB,$A0900000
  dc.l  $40030000,$AFEDDF4D,$DD3BA9EE,$20A00000
  dc.l  $40030000,$BC7EDCF7,$FF523611,$21680000
  dc.l  $40030000,$C90FDAA2,$2168C235,$A1000000
  dc.l  $40030000,$D5A0D84C,$437F4E58,$1FC00000
  dc.l  $40030000,$E231D5F6,$6595DA7B,$21300000
  dc.l  $40030000,$EEC2D3A0,$87AC669F,$A1380000
  dc.l  $40030000,$FB53D14A,$A9C2F2C2,$A0000000
  dc.l  $40040000,$83F2677A,$65ECBF73,$A1C40000
  dc.l  $40040000,$8A3AE64F,$76F80584,$21880000
  dc.l  $40040000,$90836524,$88034B96,$A0B00000
  dc.l  $40040000,$96CBE3F9,$990E91A8,$A1E00000
  dc.l  $40040000,$9D1462CE,$AA19D7B9,$21580000
  dc.l  $40040000,$A35CE1A3,$BB251DCB,$A1100000
  dc.l  $40040000,$A9A56078,$CC3063DD,$A1FC0000
  dc.l  $40040000,$AFEDDF4D,$DD3BA9EE,$21200000
  dc.l  $40040000,$B6365E22,$EE46F000,$A1480000
  dc.l  $40040000,$BC7EDCF7,$FF523611,$21E80000
  dc.l  $40040000,$C2C75BCD,$105D7C23,$20D00000
  dc.l  $40040000,$C90FDAA2,$2168C235,$A1800000
INARG2 = FP_SCR4

;	.set	TWOTO63,L_SCR1
;	.set	ENDFLAG,L_SCR2
N3 = L_SCR3

	; xref	t_frcinx
	;xref	t_extdnrm

	;|.global	stand
stand:
;--TAN(X) = X FOR DENORMALIZED X

	bra		t_extdnrm

	;|.global	stan
stan:
	fmove.x		(a0),fp0	; ...LOAD INPUT

	move.l		(a0),d0
	move.w		4(a0),d0
	andi.l		#$7FFFFFFF,d0

	cmpi.l		#$3FD78000,d0		; ...|X; >= 2**(-40)?
	bge.s		TANOK1
	bra		TANSM
TANOK1:
	cmpi.l		#$4004BC7E,d0		; ...|X; < 15 PI?
	blt.s		TANMAIN
	bra		REDUCEX_


TANMAIN:
;--THIS IS THE USUAL CASE, |X; <= 15 PI.
;--THE ARGUMENT REDUCTION IS DONE BY TABLE LOOK UP.
	fmove.x		fp0,fp1
	fmul.d		TWOBYPI(pc),fp1	; ...X*2/PI

;--HIDE THE NEXT TWO INSTRUCTIONS
	lea.l		PITBL+$200,a1 ; ...TABLE OF N*PI/2, N = -32,...,32

;--FP1 IS NOW READY
	fmove.l		fp1,d0		; ...CONVERT TO INTEGER

	asl.l		#4,d0
	adda.l		d0,a1		; ...ADDRESS N*PIBY2 IN Y1, Y2

	fsub.x		(a1)+,fp0	; ...X-Y1
;--HIDE THE NEXT ONE

	fsub.s		(a1),fp0	; ...FP0 IS R = (X-Y1)-Y2

	ror.l		#5,d0
	andi.l		#$80000000,d0	; ...D0 WAS ODD IFF D0 < 0

TANCONT:

	cmpi.l		#0,d0
	blt		NODD

	fmove.x		fp0,fp1
	fmul.x		fp1,fp1	 	; ...S = R*R

	fmove.d		TANQ4(pc),fp3
	fmove.d		TANP3(pc),fp2

	fmul.x		fp1,fp3	 	; ...SQ4
	fmul.x		fp1,fp2	 	; ...SP3

	fadd.d		TANQ3(pc),fp3	; ...Q3+SQ4
	fadd.x		TANP2(pc),fp2	; ...P2+SP3

	fmul.x		fp1,fp3	 	; ...S(Q3+SQ4)
	fmul.x		fp1,fp2	 	; ...S(P2+SP3)

	fadd.x		TANQ2(pc),fp3	; ...Q2+S(Q3+SQ4)
	fadd.x		TANP1(pc),fp2	; ...P1+S(P2+SP3)

	fmul.x		fp1,fp3	 	; ...S(Q2+S(Q3+SQ4))
	fmul.x		fp1,fp2	 	; ...S(P1+S(P2+SP3))

	fadd.x		TANQ1(pc),fp3	; ...Q1+S(Q2+S(Q3+SQ4))
	fmul.x		fp0,fp2	 	; ...RS(P1+S(P2+SP3))

	fmul.x		fp3,fp1	 	; ...S(Q1+S(Q2+S(Q3+SQ4)))
	

	fadd.x		fp2,fp0	 	; ...R+RS(P1+S(P2+SP3))
	

	fadd.s		#$3F800000,fp1	; ...1+S(Q1+...)

	fmove.l		d1,fpcr		;restore users exceptions
	fdiv.x		fp1,fp0		;last inst - possible exception set

	bra		t_frcinx

NODD:
	fmove.x		fp0,fp1
	fmul.x		fp0,fp0	 	; ...S = R*R

	fmove.d		TANQ4(pc),fp3
	fmove.d		TANP3(pc),fp2

	fmul.x		fp0,fp3	 	; ...SQ4
	fmul.x		fp0,fp2	 	; ...SP3

	fadd.d		TANQ3(pc),fp3	; ...Q3+SQ4
	fadd.x		TANP2(pc),fp2	; ...P2+SP3

	fmul.x		fp0,fp3	 	; ...S(Q3+SQ4)
	fmul.x		fp0,fp2	 	; ...S(P2+SP3)

	fadd.x		TANQ2(pc),fp3	; ...Q2+S(Q3+SQ4)
	fadd.x		TANP1(pc),fp2	; ...P1+S(P2+SP3)

	fmul.x		fp0,fp3	 	; ...S(Q2+S(Q3+SQ4))
	fmul.x		fp0,fp2	 	; ...S(P1+S(P2+SP3))

	fadd.x		TANQ1(pc),fp3	; ...Q1+S(Q2+S(Q3+SQ4))
	fmul.x		fp1,fp2	 	; ...RS(P1+S(P2+SP3))

	fmul.x		fp3,fp0	 	; ...S(Q1+S(Q2+S(Q3+SQ4)))
	

	fadd.x		fp2,fp1	 	; ...R+RS(P1+S(P2+SP3))
	fadd.s		#$3F800000,fp0	; ...1+S(Q1+...)
	

	fmove.x		fp1,-(sp)
	eori.l		#$80000000,(sp)

	fmove.l		d1,fpcr	 	;restore users exceptions
	fdiv.x		(sp)+,fp0	;last inst - possible exception set

	bra		t_frcinx

TANBORS:
;--IF |X; > 15PI, WE USE THE GENERAL ARGUMENT REDUCTION.
;--IF |X; < 2**(-40), RETURN X OR 1.
	cmpi.l		#$3FFF8000,d0
	bgt.s		REDUCEX_

TANSM:

	fmove.x		fp0,-(sp)
	fmove.l		d1,fpcr		 ;restore users exceptions
	fmove.x		(sp)+,fp0	;last inst - possible exception set

	bra		t_frcinx


REDUCEX_:
;--WHEN REDUCEX IS USED, THE CODE WILL INEVITABLY BE SLOW.
;--THIS REDUCTION METHOD, HOWEVER, IS MUCH FASTER THAN USING
;--THE REMAINDER INSTRUCTION WHICH IS NOW IN SOFTWARE.

	fmovem.x	fp2-fp5,-(a7)	; ...save FP2 through FP5
	move.l		d2,-(a7)
        fmove.s         #$00000000,fp1

;--If compact form of abs(arg) in d0=$7ffeffff, argument is so large that
;--there is a danger of unwanted overflow in first LOOP iteration.  In this
;--case, reduce argument by one remainder step to make subsequent reduction
;--safe.
	cmpi.l	#$7ffeffff,d0		;is argument dangerously large?
	bne.s	LOOP
	move.l	#$7ffe0000,FP_SCR2(a6)	;yes
;					;create 2**16383*PI/2
	move.l	#$c90fdaa2,FP_SCR2+4(a6)
	clr.l	FP_SCR2+8(a6)
	ftst.x	fp0			;test sign of argument
	move.l	#$7fdc0000,FP_SCR3(a6)	;create low half of 2**16383*
;					;PI/2 at FP_SCR3
	move.l	#$85a308d3,FP_SCR3+4(a6)
	clr.l   FP_SCR3+8(a6)
	fblt	.red_neg
	or.w	#$8000,FP_SCR2(a6)	;positive arg
	or.w	#$8000,FP_SCR3(a6)
.red_neg:
	fadd.x  FP_SCR2(a6),fp0		;high part of reduction is exact
	fmove.x  fp0,fp1		;save high result in fp1
	fadd.x  FP_SCR3(a6),fp0		;low part of reduction
	fsub.x  fp0,fp1			;determine low component of result
	fadd.x  FP_SCR3(a6),fp1		;fp0/fp1 are reduced argument.

;--ON ENTRY, FP0 IS X, ON RETURN, FP0 IS X REM PI/2, |X; <= PI/4.
;--integer quotient will be stored in N
;--Intermediate remainder is 66-bit long; (R,r) in (FP0,FP1)

LOOP:
	fmove.x		fp0,INARG2(a6)	; ...+-2**K * F, 1 <= F < 2
	move.w		INARG2(a6),d0
        move.l          d0,a1		; ...save a copy of D0
	andi.l		#$00007FFF,d0
	subi.l		#$00003FFF,d0	; ...D0 IS K
	cmpi.l		#28,d0
	ble.s		LASTLOOP
;CONTLOOP:
	subi.l		#27,d0	 ; ...D0 IS L := K-27
	move.l		#0,ENDFLAG(a6)
	bra.s		WORK
LASTLOOP:
	clr.l		d0		; ...D0 IS L := 0
	move.l		#1,ENDFLAG(a6)

WORK:
;--FIND THE REMAINDER OF (R,r) W.R.T.	2**L * (PI/2). L IS SO CHOSEN
;--THAT	INT( X * (2/PI) / 2**(L) ) < 2**29.

;--CREATE 2**(-L) * (2/PI), SIGN(INARG2)*2**(63),
;--2**L * (PIby2_1), 2**L * (PIby2_2)

	move.l		#$00003FFE,d2	; ...BIASED EXPO OF 2/PI
	sub.l		d0,d2		; ...BIASED EXPO OF 2**(-L)*(2/PI)

	move.l		#$A2F9836E,FP_SCR1+4(a6)
	move.l		#$4E44152A,FP_SCR1+8(a6)
	move.w		d2,FP_SCR1(a6)	; ...FP_SCR1 is 2**(-L)*(2/PI)

	fmove.x		fp0,fp2
	fmul.x		FP_SCR1(a6),fp2
;--WE MUST NOW FIND INT(FP2). SINCE WE NEED THIS VALUE IN
;--FLOATING POINT FORMAT, THE TWO FMOVE'S	FMOVE.L FP <--> N
;--WILL BE TOO INEFFICIENT. THE WAY AROUND IT IS THAT
;--(SIGN(INARG2)*2**63	+	FP2) - SIGN(INARG2)*2**63 WILL GIVE
;--US THE DESIRED VALUE IN FLOATING POINT.

;--HIDE SIX CYCLES OF INSTRUCTION
        move.l		a1,d2
        swap		d2
	andi.l		#$80000000,d2
	ori.l		#$5F000000,d2	; ...D2 IS SIGN(INARG2)*2**63 IN SGL
	move.l		d2,TWOTO63(a6)

	move.l		d0,d2
	addi.l		#$00003FFF,d2	; ...BIASED EXPO OF 2**L * (PI/2)

;--FP2 IS READY
	fadd.s		TWOTO63(a6),fp2	; ...THE FRACTIONAL PART OF FP1 IS ROUNDED

;--HIDE 4 CYCLES OF INSTRUCTION; creating 2**(L)*Piby2_1  and  2**(L)*Piby2_2
        move.w		d2,FP_SCR2(a6)
	clr.w           FP_SCR2+2(a6)
	move.l		#$C90FDAA2,FP_SCR2+4(a6)
	clr.l		FP_SCR2+8(a6)		; ...FP_SCR2 is  2**(L) * Piby2_1	

;--FP2 IS READY
	fsub.s		TWOTO63(a6),fp2		; ...FP2 is N

	addi.l		#$00003FDD,d0
        move.w		d0,FP_SCR3(a6)
	clr.w           FP_SCR3+2(a6)
	move.l		#$85A308D3,FP_SCR3+4(a6)
	clr.l		FP_SCR3+8(a6)		; ...FP_SCR3 is 2**(L) * Piby2_2

	move.l		ENDFLAG(a6),d0

;--We are now ready to perform (R+r) - N*P1 - N*P2, P1 = 2**(L) * Piby2_1 and
;--P2 = 2**(L) * Piby2_2
	fmove.x		fp2,fp4
	fmul.x		FP_SCR2(a6),fp4		; ...W = N*P1
	fmove.x		fp2,fp5
	fmul.x		FP_SCR3(a6),fp5		; ...w = N*P2
	fmove.x		fp4,fp3
;--we want P+p = W+w  but  |p; <= half ulp of P
;--Then, we need to compute  A := R-P   and  a := r-p
	fadd.x		fp5,fp3			; ...FP3 is P
	fsub.x		fp3,fp4			; ...W-P

	fsub.x		fp3,fp0			; ...FP0 is A := R - P
        fadd.x		fp5,fp4			; ...FP4 is p = (W-P)+w

	fmove.x		fp0,fp3			; ...FP3 A
	fsub.x		fp4,fp1			; ...FP1 is a := r - p

;--Now we need to normalize (A,a) to  "new (R,r)" where R+r = A+a but
;--|r; <= half ulp of R.
	fadd.x		fp1,fp0			; ...FP0 is R := A+a
;--No need to calculate r if this is the last loop
	cmpi.l		#0,d0
	bgt		.RESTORE

;--Need to calculate r
	fsub.x		fp0,fp3			; ...A-R
	fadd.x		fp3,fp1			; ...FP1 is r := (A-R)+a
	bra		LOOP

.RESTORE:
        fmove.l		fp2,N3(a6)
	move.l		(a7)+,d2
	fmovem.x	(a7)+,fp2-fp5

	
	move.l		N3(a6),d0
        ror.l		#1,d0


	bra		TANCONT

	;end
;
;	stanh.sa 3.1 12/10/90
;
;	The entry point sTanh computes the hyperbolic tangent of
;	an input argument; sTanhd does the same except for denormalized
;	input.
;
;	Input: Double-extended number X in location pointed to
;		by address register a0.
;
;	Output: The value tanh(X) returned in floating-point register Fp0.
;
;	Accuracy and Monotonicity: The returned result is within 3 ulps in
;		64 significant bit, i.e. within 0.5001 ulp to 53 bits if the
;		result is subsequently rounded to double precision. The
;		result is provably monotonic in double precision.
;
;	Speed: The program stanh takes approximately 270 cycles.
;
;	Algorithm:
;
;	TANH
;	1. If |X; >= (5/2) log2 or |X; <= 2**(-40), go to 3.
;
;	2. (2**(-40) < |X; < (5/2) log2) Calculate tanh(X) by
;		sgn := sign(X), y := 2|X|, z := expm1(Y), and
;		tanh(X) = sgn*( z/(2+z) ).
;		Exit.
;
;	3. (|X; <= 2**(-40) or |X; >= (5/2) log2). If |X; < 1,
;		go to 7.
;
;	4. (|X; >= (5/2) log2) If |X; >= 50 log2, go to 6.
;
;	5. ((5/2) log2 <= |X; < 50 log2) Calculate tanh(X) by
;		sgn := sign(X), y := 2|X|, z := exp(Y),
;		tanh(X) = sgn - [ sgn*2/(1+z) ].
;		Exit.
;
;	6. (|X; >= 50 log2) Tanh(X) = +-1 (round to nearest). Thus, we
;		calculate Tanh(X) by
;		sgn := sign(X), Tiny := 2**(-126),
;		tanh(X) := sgn - sgn*Tiny.
;		Exit.
;
;	7. (|X; < 2**(-40)). Tanh(X) = X.	Exit.
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;STANH	idnt	2,1 ; Motorola 040 Floating Point Software Package

	;section	8
	
	
X3 = FP_SCR5
XDCARE4 = X3+2
XFRAC4 = X3+4
SGN = L_SCR3
V = FP_SCR6

BOUNDS1__:	dc.l $3FD78000,$3FFFDDCE ; ... 2^(-40), (5/2)LOG2

	;xref	t_frcinx
	;xref	t_extdnrm
	;xref	setox
	;xref	setoxm1

	;|.global	stanhd
stanhd:
;--TANH(X) = X FOR DENORMALIZED X

	bra		t_extdnrm

	;|.global	stanh
stanh:
	fmove.x		(a0),fp0	; ...LOAD INPUT

	fmove.x		fp0,X3(a6)
	move.l		(a0),d0
	move.w		4(a0),d0
	move.l		d0,X3(a6)
	and.l		#$7FFFFFFF,d0
	cmp2.l		BOUNDS1__(pc),d0	; ...2**(-40) < |X; < (5/2)LOG2 ?
	bcs.s		TANHBORS

;--THIS IS THE USUAL CASE
;--Y = 2|X|, Z = EXPM1(Y), TANH(X) = SIGN(X) * Z / (Z+2).

	move.l		X3(a6),d0
	move.l		d0,SGN(a6)
	and.l		#$7FFF0000,d0
	add.l		#$00010000,d0	; ...EXPONENT OF 2|X3; 	move.l		d0,X3(a6)
	and.l		#$80000000,SGN(a6)
	fmove.x		X3(a6),fp0		; ...FP0 IS Y = 2|X; 
	move.l		d1,-(a7)
	clr.l		d1
	fmovem.x	fp0-fp0,(a0)
	bsr		setoxm1	 	; ...FP0 IS Z = EXPM1(Y)
	move.l		(a7)+,d1

	fmove.x		fp0,fp1
	fadd.s		#$40000000,fp1	; ...Z+2
	move.l		SGN(a6),d0
	fmove.x		fp1,V(a6)
	eor.l		d0,V(a6)

	fmove.l		d1,FPCR		;restore users exceptions
	fdiv.x		V(a6),fp0
	bra		t_frcinx

TANHBORS:
	cmp.l		#$3FFF8000,d0
	blt		TANHSM

	cmp.l		#$40048AA1,d0
	bgt		TANHHUGE

;-- (5/2) LOG2 < |X; < 50 LOG2,
;--TANH(X) = 1 - (2/[EXP(2X)+1]). LET Y = 2|X|, SGN = SIGN(X),
;--TANH(X) = SGN -	SGN*2/[EXP(Y)+1].

	move.l		X3(a6),d0
	move.l		d0,SGN(a6)
	and.l		#$7FFF0000,d0
	add.l		#$00010000,d0	; ...EXPO OF 2|X; 	move.l		d0,X3(a6)		; ...Y = 2|X; 	and.l		#$80000000,SGN(a6)
	move.l		SGN(a6),d0
	fmove.x		X3(a6),fp0		; ...Y = 2|X; 
	move.l		d1,-(a7)
	clr.l		d1
	fmovem.x	fp0-fp0,(a0)
	bsr		setox		; ...FP0 IS EXP(Y)
	move.l		(a7)+,d1
	move.l		SGN(a6),d0
	fadd.s		#$3F800000,fp0	; ...EXP(Y)+1

	eor.l		#$C0000000,d0	; ...-SIGN(X)*2
	fmove.s		d0,fp1		; ...-SIGN(X)*2 IN SGL FMT
	fdiv.x		fp0,fp1	 	; ...-SIGN(X)2 / [EXP(Y)+1 ]

	move.l		SGN(a6),d0
	or.l		#$3F800000,d0	; ...SGN
	fmove.s		d0,fp0		; ...SGN IN SGL FMT

	fmove.l		d1,FPCR		;restore users exceptions
	fadd.x		fp1,fp0

	bra		t_frcinx

TANHSM:
	move.w		#$0000,XDCARE4(a6)

	fmove.l		d1,FPCR		;restore users exceptions
	fmove.x		X3(a6),fp0		;last inst - possible exception set

	bra		t_frcinx

TANHHUGE:
;---RETURN SGN(X) - SGN(X)EPS
	move.l		X3(a6),d0
	and.l		#$80000000,d0
	or.l		#$3F800000,d0
	fmove.s		d0,fp0
	and.l		#$80000000,d0
	eor.l		#$80800000,d0	; ...-SIGN(X)*EPS

	fmove.l		d1,FPCR		;restore users exceptions
	fadd.s		d0,fp0

	bra		t_frcinx

	;end
;
;	sto_res.sa 3.1 12/10/90
;
;	Takes the result and puts it in where the user expects it.
;	Library functions return result in fp0.	If fp0 is not the
;	users destination register then fp0 is moved to the the
;	correct floating-point destination register.  fp0 and fp1
;	are then restored to the original contents. 
;
;	Input:	result in fp0,fp1 
;
;		d2 & a0 should be kept unmodified
;
;	Output:	moves the result to the true destination reg or mem
;
;	Modifies: destination floating point register
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

STO_RES:	;idnt	2,1 ; Motorola 040 Floating Point Software Package


	;section	8

	

	;|.global	sto_cos
sto_cos:
	bfextu		CMDREG1B(a6){13:3},d0	;extract cos destination
	cmpi.b		#3,d0		;check for fp0/fp1 cases
	ble.s		c_fp0123
	fmovem.x	fp1-fp1,-(a7)
	moveq.l		#7,d1
	sub.l		d0,d1		;d1 = 7- (dest. reg. no.)
	clr.l		d0
	bset.l		d1,d0		;d0 is dynamic register mask
	fmovem.x	(a7)+,d0
	rts
c_fp0123:
	cmpi.b		#0,d0
	beq.s		c_is_fp0
	cmpi.b		#1,d0
	beq.s		c_is_fp1
	cmpi.b		#2,d0
	beq.s		c_is_fp2
c_is_fp3:
	fmovem.x	fp1-fp1,USER_FP3(a6)
	rts
c_is_fp2:
	fmovem.x	fp1-fp1,USER_FP2(a6)
	rts
c_is_fp1:
	fmovem.x	fp1-fp1,USER_FP1(a6)
	rts
c_is_fp0:
	fmovem.x	fp1-fp1,USER_FP0(a6)
	rts


	;|.global	sto_res
sto_res:
	bfextu		CMDREG1B(a6){6:3},d0	;extract destination register
	cmpi.b		#3,d0		;check for fp0/fp1 cases
	ble.s		fp0123
	fmovem.x	fp0-fp0,-(a7)
	moveq.l		#7,d1
	sub.l		d0,d1		;d1 = 7- (dest. reg. no.)
	clr.l		d0
	bset.l		d1,d0		;d0 is dynamic register mask
	fmovem.x	(a7)+,d0
	rts
fp0123:
	cmpi.b		#0,d0
	beq.s		is_fp0
	cmpi.b		#1,d0
	beq.s		is_fp1
	cmpi.b		#2,d0
	beq.s		is_fp2
is_fp3:
	fmovem.x	fp0-fp0,USER_FP3(a6)
	rts
is_fp2:
	fmovem.x	fp0-fp0,USER_FP2(a6)
	rts
is_fp1:
	fmovem.x	fp0-fp0,USER_FP1(a6)
	rts
is_fp0:
	fmovem.x	fp0-fp0,USER_FP0(a6)
	rts

	;end
;
;	stwotox.sa 3.1 12/10/90
;
;	stwotox  --- 2**X
;	stwotoxd --- 2**X for denormalized X
;	stentox  --- 10**X
;	stentoxd --- 10**X for denormalized X
;
;	Input: Double-extended number X in location pointed to
;		by address register a0.
;
;	Output: The function values are returned in Fp0.
;
;	Accuracy and Monotonicity: The returned result is within 2 ulps in
;		64 significant bit, i.e. within 0.5001 ulp to 53 bits if the
;		result is subsequently rounded to double precision. The
;		result is provably monotonic in double precision.
;
;	Speed: The program stwotox takes approximately 190 cycles and the
;		program stentox takes approximately 200 cycles.
;
;	Algorithm:
;
;	twotox
;	1. If |X; > 16480, go to ExpBig.
;
;	2. If |X; < 2**(-70), go to ExpSm.
;
;	3. Decompose X as X = N/64 + r where |r; <= 1/128. Furthermore
;		decompose N as
;		 N = 64(M + M') + j,  j = 0,1,2,...,63.
;
;	4. Overwrite r := r * log2. Then
;		2**X = 2**(M') * 2**(M) * 2**(j/64) * exp(r).
;		Go to expr to compute that expression.
;
;	tentox
;	1. If |X; > 16480*log_10(2) (base 10 log of 2), go to ExpBig.
;
;	2. If |X; < 2**(-70), go to ExpSm.
;
;	3. Set y := X*log_2(10)*64 (base 2 log of 10). Set
;		N := round-to-int(y). Decompose N as
;		 N = 64(M + M') + j,  j = 0,1,2,...,63.
;
;	4. Define r as
;		r := ((X - N*L1)-N*L2) * L10
;		where L1, L2 are the leading and trailing parts of log_10(2)/64
;		and L10 is the natural log of 10. Then
;		10**X = 2**(M') * 2**(M) * 2**(j/64) * exp(r).
;		Go to expr to compute that expression.
;
;	expr
;	1. Fetch 2**(j/64) from table as Fact1 and Fact2.
;
;	2. Overwrite Fact1 and Fact2 by
;		Fact1 := 2**(M) * Fact1
;		Fact2 := 2**(M) * Fact2
;		Thus Fact1 + Fact2 = 2**(M) * 2**(j/64).
;
;	3. Calculate P where 1 + P approximates exp(r):
;		P = r + r*r*(A1+r*(A2+...+r*A5)).
;
;	4. Let AdjFact := 2**(M'). Return
;		AdjFact * ( Fact1 + ((Fact1*P) + Fact2) ).
;		Exit.
;
;	ExpBig
;	1. Generate overflow by Huge * Huge if X > 0; otherwise, generate
;		underflow by Tiny * Tiny.
;
;	ExpSm
;	1. Return 1 + X.
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;STWOTOX	idnt	2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	

;;BOUNDS1_:	dc.l $3FB98000,$400D80C0 ; ... 2^(-70),16480
;;BOUNDS2_:	dc.l $3FB98000,$400B9B07 ; ... 2^(-70),16480 LOG2/LOG10

L2TEN64:	dc.l $406A934F,$0979A371 ; ... 64LOG10/LOG2
L10TWO1:	dc.l $3F734413,$509F8000 ; ... LOG2/64LOG10

L10TWO2:	dc.l $BFCD0000,$C0219DC1,$DA994FD2,$00000000

LOG10:	dc.l $40000000,$935D8DDD,$AAA8AC17,$00000000

LOG2:	dc.l $3FFE0000,$B17217F7,$D1CF79AC,$00000000

EXPA5:	dc.l $3F56C16D,$6F7BD0B2
EXPA4:	dc.l $3F811112,$302C712C
EXPA3:	dc.l $3FA55555,$55554CC1
EXPA2:	dc.l $3FC55555,$55554A54
EXPA1:	dc.l $3FE00000,$00000000,$00000000,$00000000

;HUGE:	dc.l $7FFE0000,$FFFFFFFF,$FFFFFFFF,$00000000
;TINY:	dc.l $00010000,$FFFFFFFF,$FFFFFFFF,$00000000

EXPTBL:
	dc.l  $3FFF0000,$80000000,$00000000,$3F738000
	dc.l  $3FFF0000,$8164D1F3,$BC030773,$3FBEF7CA
	dc.l  $3FFF0000,$82CD8698,$AC2BA1D7,$3FBDF8A9
	dc.l  $3FFF0000,$843A28C3,$ACDE4046,$3FBCD7C9
	dc.l  $3FFF0000,$85AAC367,$CC487B15,$BFBDE8DA
	dc.l  $3FFF0000,$871F6196,$9E8D1010,$3FBDE85C
	dc.l  $3FFF0000,$88980E80,$92DA8527,$3FBEBBF1
	dc.l  $3FFF0000,$8A14D575,$496EFD9A,$3FBB80CA
	dc.l  $3FFF0000,$8B95C1E3,$EA8BD6E7,$BFBA8373
	dc.l  $3FFF0000,$8D1ADF5B,$7E5BA9E6,$BFBE9670
	dc.l  $3FFF0000,$8EA4398B,$45CD53C0,$3FBDB700
	dc.l  $3FFF0000,$9031DC43,$1466B1DC,$3FBEEEB0
	dc.l  $3FFF0000,$91C3D373,$AB11C336,$3FBBFD6D
	dc.l  $3FFF0000,$935A2B2F,$13E6E92C,$BFBDB319
	dc.l  $3FFF0000,$94F4EFA8,$FEF70961,$3FBDBA2B
	dc.l  $3FFF0000,$96942D37,$20185A00,$3FBE91D5
	dc.l  $3FFF0000,$9837F051,$8DB8A96F,$3FBE8D5A
	dc.l  $3FFF0000,$99E04593,$20B7FA65,$BFBCDE7B
	dc.l  $3FFF0000,$9B8D39B9,$D54E5539,$BFBEBAAF
	dc.l  $3FFF0000,$9D3ED9A7,$2CFFB751,$BFBD86DA
	dc.l  $3FFF0000,$9EF53260,$91A111AE,$BFBEBEDD
	dc.l  $3FFF0000,$A0B0510F,$B9714FC2,$3FBCC96E
	dc.l  $3FFF0000,$A2704303,$0C496819,$BFBEC90B
	dc.l  $3FFF0000,$A43515AE,$09E6809E,$3FBBD1DB
	dc.l  $3FFF0000,$A5FED6A9,$B15138EA,$3FBCE5EB
	dc.l  $3FFF0000,$A7CD93B4,$E965356A,$BFBEC274
	dc.l  $3FFF0000,$A9A15AB4,$EA7C0EF8,$3FBEA83C
	dc.l  $3FFF0000,$AB7A39B5,$A93ED337,$3FBECB00
	dc.l  $3FFF0000,$AD583EEA,$42A14AC6,$3FBE9301
	dc.l  $3FFF0000,$AF3B78AD,$690A4375,$BFBD8367
	dc.l  $3FFF0000,$B123F581,$D2AC2590,$BFBEF05F
	dc.l  $3FFF0000,$B311C412,$A9112489,$3FBDFB3C
	dc.l  $3FFF0000,$B504F333,$F9DE6484,$3FBEB2FB
	dc.l  $3FFF0000,$B6FD91E3,$28D17791,$3FBAE2CB
	dc.l  $3FFF0000,$B8FBAF47,$62FB9EE9,$3FBCDC3C
	dc.l  $3FFF0000,$BAFF5AB2,$133E45FB,$3FBEE9AA
	dc.l  $3FFF0000,$BD08A39F,$580C36BF,$BFBEAEFD
	dc.l  $3FFF0000,$BF1799B6,$7A731083,$BFBCBF51
	dc.l  $3FFF0000,$C12C4CCA,$66709456,$3FBEF88A
	dc.l  $3FFF0000,$C346CCDA,$24976407,$3FBD83B2
	dc.l  $3FFF0000,$C5672A11,$5506DADD,$3FBDF8AB
	dc.l  $3FFF0000,$C78D74C8,$ABB9B15D,$BFBDFB17
	dc.l  $3FFF0000,$C9B9BD86,$6E2F27A3,$BFBEFE3C
	dc.l  $3FFF0000,$CBEC14FE,$F2727C5D,$BFBBB6F8
	dc.l  $3FFF0000,$CE248C15,$1F8480E4,$BFBCEE53
	dc.l  $3FFF0000,$D06333DA,$EF2B2595,$BFBDA4AE
	dc.l  $3FFF0000,$D2A81D91,$F12AE45A,$3FBC9124
	dc.l  $3FFF0000,$D4F35AAB,$CFEDFA1F,$3FBEB243
	dc.l  $3FFF0000,$D744FCCA,$D69D6AF4,$3FBDE69A
	dc.l  $3FFF0000,$D99D15C2,$78AFD7B6,$BFB8BC61
	dc.l  $3FFF0000,$DBFBB797,$DAF23755,$3FBDF610
	dc.l  $3FFF0000,$DE60F482,$5E0E9124,$BFBD8BE1
	dc.l  $3FFF0000,$E0CCDEEC,$2A94E111,$3FBACB12
	dc.l  $3FFF0000,$E33F8972,$BE8A5A51,$3FBB9BFE
	dc.l  $3FFF0000,$E5B906E7,$7C8348A8,$3FBCF2F4
	dc.l  $3FFF0000,$E8396A50,$3C4BDC68,$3FBEF22F
	dc.l  $3FFF0000,$EAC0C6E7,$DD24392F,$BFBDBF4A
	dc.l  $3FFF0000,$ED4F301E,$D9942B84,$3FBEC01A
	dc.l  $3FFF0000,$EFE4B99B,$DCDAF5CB,$3FBE8CAC
	dc.l  $3FFF0000,$F281773C,$59FFB13A,$BFBCBB3F
	dc.l  $3FFF0000,$F5257D15,$2486CC2C,$3FBEF73A
	dc.l  $3FFF0000,$F7D0DF73,$0AD13BB9,$BFB8B795
	dc.l  $3FFF0000,$FA83B2DB,$722A033A,$3FBEF84B
	dc.l  $3FFF0000,$FD3E0C0C,$F486C175,$BFBEF581
N1 = L_SCR1
X4 = FP_SCR1
XDCARE5 = X4+2
XFRAC5 = X4+4
ADJFACT = FP_SCR2
FACT1 = FP_SCR3
FACT1HI = FACT1+4
FACT1LOW = FACT1+8
FACT2 = FP_SCR4
FACT2HI = FACT2+4
FACT2LOW = FACT2+8

	; xref	t_unfl
	;xref	t_ovfl
	;xref	t_frcinx

	;|.global	stwotoxd
stwotoxd:
;--ENTRY POINT FOR 2**(X) FOR DENORMALIZED ARGUMENT

	fmove.l		d1,fpcr		; ...set user's rounding mode/precision
	fmove.s		#$3F800000,fp0  ; ...RETURN 1 + X
	move.l		(a0),d0
	or.l		#$00800001,d0
	fadd.s		d0,fp0
	bra		t_frcinx

	;|.global	stwotox
stwotox:
;--ENTRY POINT FOR 2**(X), HERE X IS FINITE, NON-ZERO, AND NOT NAN'S
	fmovem.x	(a0),fp0-fp0	; ...LOAD INPUT, do not set cc's

	move.l		(a0),d0
	move.w		4(a0),d0
	fmove.x		fp0,X4(a6)
	andi.l		#$7FFFFFFF,d0

	cmpi.l		#$3FB98000,d0		; ...|X; >= 2**(-70)?
	bge.s		TWOOK1
	bra		EXPBORS

TWOOK1:
	cmpi.l		#$400D80C0,d0		; ...|X; > 16480?
	ble.s		TWOMAIN
	bra		EXPBORS
	

TWOMAIN:
;--USUAL CASE, 2^(-70) <= |X; <= 16480

	fmove.x		fp0,fp1
	fmul.s		#$42800000,fp1  ; ...64 * X
	
	fmove.l		fp1,N1(a6)		; ...N = ROUND-TO-INT(64 X)
	move.l		d2,-(sp)
	lea		EXPTBL(pc),a1 	; ...LOAD ADDRESS OF TABLE OF 2^(J/64)
	fmove.l		N1(a6),fp1		; ...N --> FLOATING FMT
	move.l		N1(a6),d0
	move.l		d0,d2
	andi.l		#$3F,d0		; ...D0 IS J
	asl.l		#4,d0		; ...DISPLACEMENT FOR 2^(J/64)
	adda.l		d0,a1		; ...ADDRESS FOR 2^(J/64)
	asr.l		#6,d2		; ...d2 IS L, N = 64L + J
	move.l		d2,d0
	asr.l		#1,d0		; ...D0 IS M
	sub.l		d0,d2		; ...d2 IS M', N = 64(M+M') + J
	addi.l		#$3FFF,d2
	move.w		d2,ADJFACT(a6) 	; ...ADJFACT IS 2^(M')
	move.l		(sp)+,d2
;--SUMMARY: a1 IS ADDRESS FOR THE LEADING PORTION OF 2^(J/64),
;--D0 IS M WHERE N = 64(M+M') + J. NOTE THAT |M; <= 16140 BY DESIGN.
;--ADJFACT = 2^(M').
;--REGISTERS SAVED SO FAR ARE (IN ORDER) FPCR, D0, FP1, a1, AND FP2.

	fmul.s		#$3C800000,fp1  ; ...(1/64)*N
	move.l		(a1)+,FACT1(a6)
	move.l		(a1)+,FACT1HI(a6)
	move.l		(a1)+,FACT1LOW(a6)
	move.w		(a1)+,FACT2(a6)
	clr.w		FACT2+2(a6)

	fsub.x		fp1,fp0	 	; ...X - (1/64)*INT(64 X)

	move.w		(a1)+,FACT2HI(a6)
	clr.w		FACT2HI+2(a6)
	clr.l		FACT2LOW(a6)
	add.w		d0,FACT1(a6)
	
	fmul.x		LOG2(pc),fp0	; ...FP0 IS R
	add.w		d0,FACT2(a6)

	bra		expr

EXPBORS:
;--FPCR, D0 SAVED
	cmpi.l		#$3FFF8000,d0
	bgt.s		.EXPBIG

.EXPSM:
;--|X; IS SMALL, RETURN 1 + X

	fmove.l		d1,FPCR		;restore users exceptions
	fadd.s		#$3F800000,fp0  ; ...RETURN 1 + X

	bra		t_frcinx

.EXPBIG:
;--|X; IS LARGE, GENERATE OVERFLOW IF X > 0; ELSE GENERATE UNDERFLOW
;--REGISTERS SAVE SO FAR ARE FPCR AND  D0
	move.l		X4(a6),d0
	cmpi.l		#0,d0
	blt.s		EXPNEG

	bclr.b		#7,(a0)		;t_ovfl expects positive value
	bra		t_ovfl

EXPNEG:
	bclr.b		#7,(a0)		;t_unfl expects positive value
	bra		t_unfl

	;|.global	stentoxd
stentoxd:
;--ENTRY POINT FOR 10**(X) FOR DENORMALIZED ARGUMENT

	fmove.l		d1,fpcr		; ...set user's rounding mode/precision
	fmove.s		#$3F800000,fp0  ; ...RETURN 1 + X
	move.l		(a0),d0
	or.l		#$00800001,d0
	fadd.s		d0,fp0
	bra		t_frcinx

	;|.global	stentox
stentox:
;--ENTRY POINT FOR 10**(X), HERE X IS FINITE, NON-ZERO, AND NOT NAN'S
	fmovem.x	(a0),fp0-fp0	; ...LOAD INPUT, do not set cc's

	move.l		(a0),d0
	move.w		4(a0),d0
	fmove.x		fp0,X4(a6)
	andi.l		#$7FFFFFFF,d0

	cmpi.l		#$3FB98000,d0		; ...|X; >= 2**(-70)?
	bge.s		TENOK1
	bra		EXPBORS

TENOK1:
	cmpi.l		#$400B9B07,d0		; ...|X; <= 16480*log2/log10 ?
	ble.s		TENMAIN
	bra		EXPBORS

TENMAIN:
;--USUAL CASE, 2^(-70) <= |X; <= 16480 LOG 2 / LOG 10

	fmove.x		fp0,fp1
	fmul.d		L2TEN64(pc),fp1	; ...X*64*LOG10/LOG2
	
	fmove.l		fp1,N1(a6)		; ...N=INT(X*64*LOG10/LOG2)
	move.l		d2,-(sp)
	lea		EXPTBL(pc),a1 	; ...LOAD ADDRESS OF TABLE OF 2^(J/64)
	fmove.l		N1(a6),fp1		; ...N --> FLOATING FMT
	move.l		N1(a6),d0
	move.l		d0,d2
	andi.l		#$3F,d0		; ...D0 IS J
	asl.l		#4,d0		; ...DISPLACEMENT FOR 2^(J/64)
	adda.l		d0,a1		; ...ADDRESS FOR 2^(J/64)
	asr.l		#6,d2		; ...d2 IS L, N = 64L + J
	move.l		d2,d0
	asr.l		#1,d0		; ...D0 IS M
	sub.l		d0,d2		; ...d2 IS M', N = 64(M+M') + J
	addi.l		#$3FFF,d2
	move.w		d2,ADJFACT(a6) 	; ...ADJFACT IS 2^(M')
	move.l		(sp)+,d2

;--SUMMARY: a1 IS ADDRESS FOR THE LEADING PORTION OF 2^(J/64),
;--D0 IS M WHERE N = 64(M+M') + J. NOTE THAT |M; <= 16140 BY DESIGN.
;--ADJFACT = 2^(M').
;--REGISTERS SAVED SO FAR ARE (IN ORDER) FPCR, D0, FP1, a1, AND FP2.

	fmove.x		fp1,fp2

	fmul.d		L10TWO1(pc),fp1	; ...N*(LOG2/64LOG10)_LEAD
	move.l		(a1)+,FACT1(a6)

	fmul.x		L10TWO2(pc),fp2	; ...N*(LOG2/64LOG10)_TRAIL

	move.l		(a1)+,FACT1HI(a6)
	move.l		(a1)+,FACT1LOW(a6)
	fsub.x		fp1,fp0		; ...X - N L_LEAD
	move.w		(a1)+,FACT2(a6)

	fsub.x		fp2,fp0		; ...X - N L_TRAIL

	clr.w		FACT2+2(a6)
	move.w		(a1)+,FACT2HI(a6)
	clr.w		FACT2HI+2(a6)
	clr.l		FACT2LOW(a6)

	fmul.x		LOG10(pc),fp0	; ...FP0 IS R
	
	add.w		d0,FACT1(a6)
	add.w		d0,FACT2(a6)

expr:
;--FPCR, FP2, FP3 ARE SAVED IN ORDER AS SHOWN.
;--ADJFACT CONTAINS 2**(M'), FACT1 + FACT2 = 2**(M) * 2**(J/64).
;--FP0 IS R. THE FOLLOWING CODE COMPUTES
;--	2**(M'+M) * 2**(J/64) * EXP(R)

	fmove.x		fp0,fp1
	fmul.x		fp1,fp1		; ...FP1 IS S = R*R

	fmove.d		EXPA5(pc),fp2	; ...FP2 IS A5
	fmove.d		EXPA4(pc),fp3	; ...FP3 IS A4

	fmul.x		fp1,fp2		; ...FP2 IS S*A5
	fmul.x		fp1,fp3		; ...FP3 IS S*A4

	fadd.d		EXPA3(pc),fp2	; ...FP2 IS A3+S*A5
	fadd.d		EXPA2(pc),fp3	; ...FP3 IS A2+S*A4

	fmul.x		fp1,fp2		; ...FP2 IS S*(A3+S*A5)
	fmul.x		fp1,fp3		; ...FP3 IS S*(A2+S*A4)

	fadd.d		EXPA1(pc),fp2	; ...FP2 IS A1+S*(A3+S*A5)
	fmul.x		fp0,fp3		; ...FP3 IS R*S*(A2+S*A4)

	fmul.x		fp1,fp2		; ...FP2 IS S*(A1+S*(A3+S*A5))
	fadd.x		fp3,fp0		; ...FP0 IS R+R*S*(A2+S*A4)
	
	fadd.x		fp2,fp0		; ...FP0 IS EXP(R) - 1
	

;--FINAL RECONSTRUCTION PROCESS
;--EXP(X) = 2^M*2^(J/64) + 2^M*2^(J/64)*(EXP(R)-1)  -  (1 OR 0)

	fmul.x		FACT1(a6),fp0
	fadd.x		FACT2(a6),fp0
	fadd.x		FACT1(a6),fp0

	fmove.l		d1,FPCR		;restore users exceptions
	clr.w		ADJFACT+2(a6)
	move.l		#$80000000,ADJFACT+4(a6)
	clr.l		ADJFACT+8(a6)
	fmul.x		ADJFACT(a6),fp0	; ...FINAL ADJUSTMENT

	bra		t_frcinx

	;end
;
;	tbldo.sa 3.1 12/10/90
;
; Modified:
;	8/16/90	chinds	The table was constructed to use only one level
;			of indirection in do_func for monadic
;			functions.  Dyadic functions require two
;			levels, and the tables are still contained
;			in do_func.  The table is arranged for 
;			index with a 10-bit index, with the first
;			7 bits the opcode, and the remaining 3
;			the stag.  For dyadic functions, all
;			valid addresses are to the generic entry
;			point. 
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;TBLDO	idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	;xref	ld_pinf,ld_pone,ld_ppi2
	;xref	t_dz2,t_operr
	;xref	serror,sone,szero,sinf,snzrinx
	;xref	sopr_inf,spi_2,src_nan,szr_inf

	;xref	smovcr
	;xref	pmod,prem,pscale
	;xref	satanh,satanhd
	;xref	sacos,sacosd,sasin,sasind,satan,satand
	;xref	setox,setoxd,setoxm1,setoxm1d,setoxm1i
	;xref	sgetexp,sgetexpd,sgetman,sgetmand
	;xref	sint,sintd,sintrz
	;xref	ssincos,ssincosd,ssincosi,ssincosnan,ssincosz
	;xref	scos,scosd,ssin,ssind,stan,stand
	;xref	scosh,scoshd,ssinh,ssinhd,stanh,stanhd
	;xref	sslog10,sslog2,sslogn,sslognp1
	;xref	sslog10d,sslog2d,sslognd,slognp1d
	;xref	stentox,stentoxd,stwotox,stwotoxd

;	instruction		;opcode-stag Notes
	;|.global	tblpre
tblpre:
	dc.l	smovcr		;$00-0 fmovecr all
	dc.l	smovcr		;$00-1 fmovecr all
	dc.l	smovcr		;$00-2 fmovecr all
	dc.l	smovcr		;$00-3 fmovecr all
	dc.l	smovcr		;$00-4 fmovecr all
	dc.l	smovcr		;$00-5 fmovecr all
	dc.l	smovcr		;$00-6 fmovecr all
	dc.l	smovcr		;$00-7 fmovecr all

	dc.l	sint		;$01-0 fint norm
	dc.l	szero		;$01-1 fint zero 
	dc.l	sinf		;$01-2 fint inf
	dc.l	src_nan		;$01-3 fint nan
	dc.l	sintd		;$01-4 fint denorm inx
	dc.l	serror		;$01-5 fint ERROR
	dc.l	serror		;$01-6 fint ERROR
	dc.l	serror		;$01-7 fint ERROR

	dc.l	ssinh		;$02-0 fsinh norm
	dc.l	szero		;$02-1 fsinh zero
	dc.l	sinf		;$02-2 fsinh inf
	dc.l	src_nan		;$02-3 fsinh nan
	dc.l	ssinhd		;$02-4 fsinh denorm
	dc.l	serror		;$02-5 fsinh ERROR
	dc.l	serror		;$02-6 fsinh ERROR
	dc.l	serror		;$02-7 fsinh ERROR

	dc.l	sintrz		;$03-0 fintrz norm
	dc.l	szero		;$03-1 fintrz zero
	dc.l	sinf		;$03-2 fintrz inf
	dc.l	src_nan		;$03-3 fintrz nan
	dc.l	snzrinx		;$03-4 fintrz denorm inx
	dc.l	serror		;$03-5 fintrz ERROR
	dc.l	serror		;$03-6 fintrz ERROR
	dc.l	serror		;$03-7 fintrz ERROR

	dc.l	serror		;$04-0 ERROR - illegal extension
	dc.l	serror		;$04-1 ERROR - illegal extension
	dc.l	serror		;$04-2 ERROR - illegal extension
	dc.l	serror		;$04-3 ERROR - illegal extension
	dc.l	serror		;$04-4 ERROR - illegal extension
	dc.l	serror		;$04-5 ERROR - illegal extension
	dc.l	serror		;$04-6 ERROR - illegal extension
	dc.l	serror		;$04-7 ERROR - illegal extension

	dc.l	serror		;$05-0 ERROR - illegal extension
	dc.l	serror		;$05-1 ERROR - illegal extension
	dc.l	serror		;$05-2 ERROR - illegal extension
	dc.l	serror		;$05-3 ERROR - illegal extension
	dc.l	serror		;$05-4 ERROR - illegal extension
	dc.l	serror		;$05-5 ERROR - illegal extension
	dc.l	serror		;$05-6 ERROR - illegal extension
	dc.l	serror		;$05-7 ERROR - illegal extension

	dc.l	sslognp1	;$06-0 flognp1 norm
	dc.l	szero		;$06-1 flognp1 zero
	dc.l	sopr_inf	;$06-2 flognp1 inf
	dc.l	src_nan		;$06-3 flognp1 nan
	dc.l	slognp1d	;$06-4 flognp1 denorm
	dc.l	serror		;$06-5 flognp1 ERROR
	dc.l	serror		;$06-6 flognp1 ERROR
	dc.l	serror		;$06-7 flognp1 ERROR

	dc.l	serror		;$07-0 ERROR - illegal extension
	dc.l	serror		;$07-1 ERROR - illegal extension
	dc.l	serror		;$07-2 ERROR - illegal extension
	dc.l	serror		;$07-3 ERROR - illegal extension
	dc.l	serror		;$07-4 ERROR - illegal extension
	dc.l	serror		;$07-5 ERROR - illegal extension
	dc.l	serror		;$07-6 ERROR - illegal extension
	dc.l	serror		;$07-7 ERROR - illegal extension

	dc.l	setoxm1		;$08-0 fetoxm1 norm
	dc.l	szero		;$08-1 fetoxm1 zero
	dc.l	setoxm1i	;$08-2 fetoxm1 inf
	dc.l	src_nan		;$08-3 fetoxm1 nan
	dc.l	setoxm1d	;$08-4 fetoxm1 denorm
	dc.l	serror		;$08-5 fetoxm1 ERROR
	dc.l	serror		;$08-6 fetoxm1 ERROR
	dc.l	serror		;$08-7 fetoxm1 ERROR

	dc.l	stanh		;$09-0 ftanh norm
	dc.l	szero		;$09-1 ftanh zero
	dc.l	sone		;$09-2 ftanh inf
	dc.l	src_nan		;$09-3 ftanh nan
	dc.l	stanhd		;$09-4 ftanh denorm
	dc.l	serror		;$09-5 ftanh ERROR
	dc.l	serror		;$09-6 ftanh ERROR
	dc.l	serror		;$09-7 ftanh ERROR

	dc.l	satan		;$0a-0 fatan norm
	dc.l	szero		;$0a-1 fatan zero
	dc.l	spi_2		;$0a-2 fatan inf
	dc.l	src_nan		;$0a-3 fatan nan
	dc.l	satand		;$0a-4 fatan denorm
	dc.l	serror		;$0a-5 fatan ERROR
	dc.l	serror		;$0a-6 fatan ERROR
	dc.l	serror		;$0a-7 fatan ERROR

	dc.l	serror		;$0b-0 ERROR - illegal extension
	dc.l	serror		;$0b-1 ERROR - illegal extension
	dc.l	serror		;$0b-2 ERROR - illegal extension
	dc.l	serror		;$0b-3 ERROR - illegal extension
	dc.l	serror		;$0b-4 ERROR - illegal extension
	dc.l	serror		;$0b-5 ERROR - illegal extension
	dc.l	serror		;$0b-6 ERROR - illegal extension
	dc.l	serror		;$0b-7 ERROR - illegal extension

	dc.l	sasin		;$0c-0 fasin norm
	dc.l	szero		;$0c-1 fasin zero
	dc.l	t_operr		;$0c-2 fasin inf
	dc.l	src_nan		;$0c-3 fasin nan
	dc.l	sasind		;$0c-4 fasin denorm
	dc.l	serror		;$0c-5 fasin ERROR
	dc.l	serror		;$0c-6 fasin ERROR
	dc.l	serror		;$0c-7 fasin ERROR

	dc.l	satanh		;$0d-0 fatanh norm
	dc.l	szero		;$0d-1 fatanh zero
	dc.l	t_operr		;$0d-2 fatanh inf
	dc.l	src_nan		;$0d-3 fatanh nan
	dc.l	satanhd		;$0d-4 fatanh denorm
	dc.l	serror		;$0d-5 fatanh ERROR
	dc.l	serror		;$0d-6 fatanh ERROR
	dc.l	serror		;$0d-7 fatanh ERROR

	dc.l	ssin		;$0e-0 fsin norm
	dc.l	szero		;$0e-1 fsin zero
	dc.l	t_operr		;$0e-2 fsin inf
	dc.l	src_nan		;$0e-3 fsin nan
	dc.l	ssind		;$0e-4 fsin denorm
	dc.l	serror		;$0e-5 fsin ERROR
	dc.l	serror		;$0e-6 fsin ERROR
	dc.l	serror		;$0e-7 fsin ERROR

	dc.l	stan		;$0f-0 ftan norm
	dc.l	szero		;$0f-1 ftan zero
	dc.l	t_operr		;$0f-2 ftan inf
	dc.l	src_nan		;$0f-3 ftan nan
	dc.l	stand		;$0f-4 ftan denorm
	dc.l	serror		;$0f-5 ftan ERROR
	dc.l	serror		;$0f-6 ftan ERROR
	dc.l	serror		;$0f-7 ftan ERROR

	dc.l	setox		;$10-0 fetox norm
	dc.l	ld_pone		;$10-1 fetox zero
	dc.l	szr_inf		;$10-2 fetox inf
	dc.l	src_nan		;$10-3 fetox nan
	dc.l	setoxd		;$10-4 fetox denorm
	dc.l	serror		;$10-5 fetox ERROR
	dc.l	serror		;$10-6 fetox ERROR
	dc.l	serror		;$10-7 fetox ERROR

	dc.l	stwotox		;$11-0 ftwotox norm
	dc.l	ld_pone		;$11-1 ftwotox zero
	dc.l	szr_inf		;$11-2 ftwotox inf
	dc.l	src_nan		;$11-3 ftwotox nan
	dc.l	stwotoxd	;$11-4 ftwotox denorm
	dc.l	serror		;$11-5 ftwotox ERROR
	dc.l	serror		;$11-6 ftwotox ERROR
	dc.l	serror		;$11-7 ftwotox ERROR

	dc.l	stentox		;$12-0 ftentox norm
	dc.l	ld_pone		;$12-1 ftentox zero
	dc.l	szr_inf		;$12-2 ftentox inf
	dc.l	src_nan		;$12-3 ftentox nan
	dc.l	stentoxd	;$12-4 ftentox denorm
	dc.l	serror		;$12-5 ftentox ERROR
	dc.l	serror		;$12-6 ftentox ERROR
	dc.l	serror		;$12-7 ftentox ERROR

	dc.l	serror		;$13-0 ERROR - illegal extension
	dc.l	serror		;$13-1 ERROR - illegal extension
	dc.l	serror		;$13-2 ERROR - illegal extension
	dc.l	serror		;$13-3 ERROR - illegal extension
	dc.l	serror		;$13-4 ERROR - illegal extension
	dc.l	serror		;$13-5 ERROR - illegal extension
	dc.l	serror		;$13-6 ERROR - illegal extension
	dc.l	serror		;$13-7 ERROR - illegal extension

	dc.l	sslogn		;$14-0 flogn norm
	dc.l	t_dz2		;$14-1 flogn zero
	dc.l	sopr_inf	;$14-2 flogn inf
	dc.l	src_nan		;$14-3 flogn nan
	dc.l	sslognd		;$14-4 flogn denorm
	dc.l	serror		;$14-5 flogn ERROR
	dc.l	serror		;$14-6 flogn ERROR
	dc.l	serror		;$14-7 flogn ERROR

	dc.l	sslog10		;$15-0 flog10 norm
	dc.l	t_dz2		;$15-1 flog10 zero
	dc.l	sopr_inf	;$15-2 flog10 inf
	dc.l	src_nan		;$15-3 flog10 nan
	dc.l	sslog10d	;$15-4 flog10 denorm
	dc.l	serror		;$15-5 flog10 ERROR
	dc.l	serror		;$15-6 flog10 ERROR
	dc.l	serror		;$15-7 flog10 ERROR

	dc.l	sslog2		;$16-0 flog2 norm
	dc.l	t_dz2		;$16-1 flog2 zero
	dc.l	sopr_inf	;$16-2 flog2 inf
	dc.l	src_nan		;$16-3 flog2 nan
	dc.l	sslog2d		;$16-4 flog2 denorm
	dc.l	serror		;$16-5 flog2 ERROR
	dc.l	serror		;$16-6 flog2 ERROR
	dc.l	serror		;$16-7 flog2 ERROR

	dc.l	serror		;$17-0 ERROR - illegal extension
	dc.l	serror		;$17-1 ERROR - illegal extension
	dc.l	serror		;$17-2 ERROR - illegal extension
	dc.l	serror		;$17-3 ERROR - illegal extension
	dc.l	serror		;$17-4 ERROR - illegal extension
	dc.l	serror		;$17-5 ERROR - illegal extension
	dc.l	serror		;$17-6 ERROR - illegal extension
	dc.l	serror		;$17-7 ERROR - illegal extension

	dc.l	serror		;$18-0 ERROR - illegal extension
	dc.l	serror		;$18-1 ERROR - illegal extension
	dc.l	serror		;$18-2 ERROR - illegal extension
	dc.l	serror		;$18-3 ERROR - illegal extension
	dc.l	serror		;$18-4 ERROR - illegal extension
	dc.l	serror		;$18-5 ERROR - illegal extension
	dc.l	serror		;$18-6 ERROR - illegal extension
	dc.l	serror		;$18-7 ERROR - illegal extension

	dc.l	scosh		;$19-0 fcosh norm
	dc.l	ld_pone		;$19-1 fcosh zero
	dc.l	ld_pinf		;$19-2 fcosh inf
	dc.l	src_nan		;$19-3 fcosh nan
	dc.l	scoshd		;$19-4 fcosh denorm
	dc.l	serror		;$19-5 fcosh ERROR
	dc.l	serror		;$19-6 fcosh ERROR
	dc.l	serror		;$19-7 fcosh ERROR

	dc.l	serror		;$1a-0 ERROR - illegal extension
	dc.l	serror		;$1a-1 ERROR - illegal extension
	dc.l	serror		;$1a-2 ERROR - illegal extension
	dc.l	serror		;$1a-3 ERROR - illegal extension
	dc.l	serror		;$1a-4 ERROR - illegal extension
	dc.l	serror		;$1a-5 ERROR - illegal extension
	dc.l	serror		;$1a-6 ERROR - illegal extension
	dc.l	serror		;$1a-7 ERROR - illegal extension

	dc.l	serror		;$1b-0 ERROR - illegal extension
	dc.l	serror		;$1b-1 ERROR - illegal extension
	dc.l	serror		;$1b-2 ERROR - illegal extension
	dc.l	serror		;$1b-3 ERROR - illegal extension
	dc.l	serror		;$1b-4 ERROR - illegal extension
	dc.l	serror		;$1b-5 ERROR - illegal extension
	dc.l	serror		;$1b-6 ERROR - illegal extension
	dc.l	serror		;$1b-7 ERROR - illegal extension

	dc.l	sacos		;$1c-0 facos norm
	dc.l	ld_ppi2		;$1c-1 facos zero
	dc.l	t_operr		;$1c-2 facos inf
	dc.l	src_nan		;$1c-3 facos nan
	dc.l	sacosd		;$1c-4 facos denorm
	dc.l	serror		;$1c-5 facos ERROR
	dc.l	serror		;$1c-6 facos ERROR
	dc.l	serror		;$1c-7 facos ERROR

	dc.l	scos		;$1d-0 fcos norm
	dc.l	ld_pone		;$1d-1 fcos zero
	dc.l	t_operr		;$1d-2 fcos inf
	dc.l	src_nan		;$1d-3 fcos nan
	dc.l	scosd		;$1d-4 fcos denorm
	dc.l	serror		;$1d-5 fcos ERROR
	dc.l	serror		;$1d-6 fcos ERROR
	dc.l	serror		;$1d-7 fcos ERROR

	dc.l	sgetexp		;$1e-0 fgetexp norm
	dc.l	szero		;$1e-1 fgetexp zero
	dc.l	t_operr		;$1e-2 fgetexp inf
	dc.l	src_nan		;$1e-3 fgetexp nan
	dc.l	sgetexpd	;$1e-4 fgetexp denorm
	dc.l	serror		;$1e-5 fgetexp ERROR
	dc.l	serror		;$1e-6 fgetexp ERROR
	dc.l	serror		;$1e-7 fgetexp ERROR

	dc.l	sgetman		;$1f-0 fgetman norm
	dc.l	szero		;$1f-1 fgetman zero
	dc.l	t_operr		;$1f-2 fgetman inf
	dc.l	src_nan		;$1f-3 fgetman nan
	dc.l	sgetmand	;$1f-4 fgetman denorm
	dc.l	serror		;$1f-5 fgetman ERROR
	dc.l	serror		;$1f-6 fgetman ERROR
	dc.l	serror		;$1f-7 fgetman ERROR

	dc.l	serror		;$20-0 ERROR - illegal extension
	dc.l	serror		;$20-1 ERROR - illegal extension
	dc.l	serror		;$20-2 ERROR - illegal extension
	dc.l	serror		;$20-3 ERROR - illegal extension
	dc.l	serror		;$20-4 ERROR - illegal extension
	dc.l	serror		;$20-5 ERROR - illegal extension
	dc.l	serror		;$20-6 ERROR - illegal extension
	dc.l	serror		;$20-7 ERROR - illegal extension

	dc.l	pmod		;$21-0 fmod all
	dc.l	pmod		;$21-1 fmod all
	dc.l	pmod		;$21-2 fmod all
	dc.l	pmod		;$21-3 fmod all
	dc.l	pmod		;$21-4 fmod all
	dc.l	serror		;$21-5 fmod ERROR
	dc.l	serror		;$21-6 fmod ERROR
	dc.l	serror		;$21-7 fmod ERROR

	dc.l	serror		;$22-0 ERROR - illegal extension
	dc.l	serror		;$22-1 ERROR - illegal extension
	dc.l	serror		;$22-2 ERROR - illegal extension
	dc.l	serror		;$22-3 ERROR - illegal extension
	dc.l	serror		;$22-4 ERROR - illegal extension
	dc.l	serror		;$22-5 ERROR - illegal extension
	dc.l	serror		;$22-6 ERROR - illegal extension
	dc.l	serror		;$22-7 ERROR - illegal extension

	dc.l	serror		;$23-0 ERROR - illegal extension
	dc.l	serror		;$23-1 ERROR - illegal extension
	dc.l	serror		;$23-2 ERROR - illegal extension
	dc.l	serror		;$23-3 ERROR - illegal extension
	dc.l	serror		;$23-4 ERROR - illegal extension
	dc.l	serror		;$23-5 ERROR - illegal extension
	dc.l	serror		;$23-6 ERROR - illegal extension
	dc.l	serror		;$23-7 ERROR - illegal extension

	dc.l	serror		;$24-0 ERROR - illegal extension
	dc.l	serror		;$24-1 ERROR - illegal extension
	dc.l	serror		;$24-2 ERROR - illegal extension
	dc.l	serror		;$24-3 ERROR - illegal extension
	dc.l	serror		;$24-4 ERROR - illegal extension
	dc.l	serror		;$24-5 ERROR - illegal extension
	dc.l	serror		;$24-6 ERROR - illegal extension
	dc.l	serror		;$24-7 ERROR - illegal extension

	dc.l	prem		;$25-0 frem all
	dc.l	prem		;$25-1 frem all
	dc.l	prem		;$25-2 frem all
	dc.l	prem		;$25-3 frem all
	dc.l	prem		;$25-4 frem all
	dc.l	serror		;$25-5 frem ERROR
	dc.l	serror		;$25-6 frem ERROR
	dc.l	serror		;$25-7 frem ERROR

	dc.l	pscale		;$26-0 fscale all
	dc.l	pscale		;$26-1 fscale all
	dc.l	pscale		;$26-2 fscale all
	dc.l	pscale		;$26-3 fscale all
	dc.l	pscale		;$26-4 fscale all
	dc.l	serror		;$26-5 fscale ERROR
	dc.l	serror		;$26-6 fscale ERROR
	dc.l	serror		;$26-7 fscale ERROR

	dc.l	serror		;$27-0 ERROR - illegal extension
	dc.l	serror		;$27-1 ERROR - illegal extension
	dc.l	serror		;$27-2 ERROR - illegal extension
	dc.l	serror		;$27-3 ERROR - illegal extension
	dc.l	serror		;$27-4 ERROR - illegal extension
	dc.l	serror		;$27-5 ERROR - illegal extension
	dc.l	serror		;$27-6 ERROR - illegal extension
	dc.l	serror		;$27-7 ERROR - illegal extension

	dc.l	serror		;$28-0 ERROR - illegal extension
	dc.l	serror		;$28-1 ERROR - illegal extension
	dc.l	serror		;$28-2 ERROR - illegal extension
	dc.l	serror		;$28-3 ERROR - illegal extension
	dc.l	serror		;$28-4 ERROR - illegal extension
	dc.l	serror		;$28-5 ERROR - illegal extension
	dc.l	serror		;$28-6 ERROR - illegal extension
	dc.l	serror		;$28-7 ERROR - illegal extension

	dc.l	serror		;$29-0 ERROR - illegal extension
	dc.l	serror		;$29-1 ERROR - illegal extension
	dc.l	serror		;$29-2 ERROR - illegal extension
	dc.l	serror		;$29-3 ERROR - illegal extension
	dc.l	serror		;$29-4 ERROR - illegal extension
	dc.l	serror		;$29-5 ERROR - illegal extension
	dc.l	serror		;$29-6 ERROR - illegal extension
	dc.l	serror		;$29-7 ERROR - illegal extension

	dc.l	serror		;$2a-0 ERROR - illegal extension
	dc.l	serror		;$2a-1 ERROR - illegal extension
	dc.l	serror		;$2a-2 ERROR - illegal extension
	dc.l	serror		;$2a-3 ERROR - illegal extension
	dc.l	serror		;$2a-4 ERROR - illegal extension
	dc.l	serror		;$2a-5 ERROR - illegal extension
	dc.l	serror		;$2a-6 ERROR - illegal extension
	dc.l	serror		;$2a-7 ERROR - illegal extension

	dc.l	serror		;$2b-0 ERROR - illegal extension
	dc.l	serror		;$2b-1 ERROR - illegal extension
	dc.l	serror		;$2b-2 ERROR - illegal extension
	dc.l	serror		;$2b-3 ERROR - illegal extension
	dc.l	serror		;$2b-4 ERROR - illegal extension
	dc.l	serror		;$2b-5 ERROR - illegal extension
	dc.l	serror		;$2b-6 ERROR - illegal extension
	dc.l	serror		;$2b-7 ERROR - illegal extension

	dc.l	serror		;$2c-0 ERROR - illegal extension
	dc.l	serror		;$2c-1 ERROR - illegal extension
	dc.l	serror		;$2c-2 ERROR - illegal extension
	dc.l	serror		;$2c-3 ERROR - illegal extension
	dc.l	serror		;$2c-4 ERROR - illegal extension
	dc.l	serror		;$2c-5 ERROR - illegal extension
	dc.l	serror		;$2c-6 ERROR - illegal extension
	dc.l	serror		;$2c-7 ERROR - illegal extension

	dc.l	serror		;$2d-0 ERROR - illegal extension
	dc.l	serror		;$2d-1 ERROR - illegal extension
	dc.l	serror		;$2d-2 ERROR - illegal extension
	dc.l	serror		;$2d-3 ERROR - illegal extension
	dc.l	serror		;$2d-4 ERROR - illegal extension
	dc.l	serror		;$2d-5 ERROR - illegal extension
	dc.l	serror		;$2d-6 ERROR - illegal extension
	dc.l	serror		;$2d-7 ERROR - illegal extension

	dc.l	serror		;$2e-0 ERROR - illegal extension
	dc.l	serror		;$2e-1 ERROR - illegal extension
	dc.l	serror		;$2e-2 ERROR - illegal extension
	dc.l	serror		;$2e-3 ERROR - illegal extension
	dc.l	serror		;$2e-4 ERROR - illegal extension
	dc.l	serror		;$2e-5 ERROR - illegal extension
	dc.l	serror		;$2e-6 ERROR - illegal extension
	dc.l	serror		;$2e-7 ERROR - illegal extension

	dc.l	serror		;$2f-0 ERROR - illegal extension
	dc.l	serror		;$2f-1 ERROR - illegal extension
	dc.l	serror		;$2f-2 ERROR - illegal extension
	dc.l	serror		;$2f-3 ERROR - illegal extension
	dc.l	serror		;$2f-4 ERROR - illegal extension
	dc.l	serror		;$2f-5 ERROR - illegal extension
	dc.l	serror		;$2f-6 ERROR - illegal extension
	dc.l	serror		;$2f-7 ERROR - illegal extension

	dc.l	ssincos		;$30-0 fsincos norm
	dc.l	ssincosz	;$30-1 fsincos zero
	dc.l	ssincosi	;$30-2 fsincos inf
	dc.l	ssincosnan	;$30-3 fsincos nan
	dc.l	ssincosd	;$30-4 fsincos denorm
	dc.l	serror		;$30-5 fsincos ERROR
	dc.l	serror		;$30-6 fsincos ERROR
	dc.l	serror		;$30-7 fsincos ERROR

	dc.l	ssincos		;$31-0 fsincos norm
	dc.l	ssincosz	;$31-1 fsincos zero
	dc.l	ssincosi	;$31-2 fsincos inf
	dc.l	ssincosnan	;$31-3 fsincos nan
	dc.l	ssincosd	;$31-4 fsincos denorm
	dc.l	serror		;$31-5 fsincos ERROR
	dc.l	serror		;$31-6 fsincos ERROR
	dc.l	serror		;$31-7 fsincos ERROR

	dc.l	ssincos		;$32-0 fsincos norm
	dc.l	ssincosz	;$32-1 fsincos zero
	dc.l	ssincosi	;$32-2 fsincos inf
	dc.l	ssincosnan	;$32-3 fsincos nan
	dc.l	ssincosd	;$32-4 fsincos denorm
	dc.l	serror		;$32-5 fsincos ERROR
	dc.l	serror		;$32-6 fsincos ERROR
	dc.l	serror		;$32-7 fsincos ERROR

	dc.l	ssincos		;$33-0 fsincos norm
	dc.l	ssincosz	;$33-1 fsincos zero
	dc.l	ssincosi	;$33-2 fsincos inf
	dc.l	ssincosnan	;$33-3 fsincos nan
	dc.l	ssincosd	;$33-4 fsincos denorm
	dc.l	serror		;$33-5 fsincos ERROR
	dc.l	serror		;$33-6 fsincos ERROR
	dc.l	serror		;$33-7 fsincos ERROR

	dc.l	ssincos		;$34-0 fsincos norm
	dc.l	ssincosz	;$34-1 fsincos zero
	dc.l	ssincosi	;$34-2 fsincos inf
	dc.l	ssincosnan	;$34-3 fsincos nan
	dc.l	ssincosd	;$34-4 fsincos denorm
	dc.l	serror		;$34-5 fsincos ERROR
	dc.l	serror		;$34-6 fsincos ERROR
	dc.l	serror		;$34-7 fsincos ERROR

	dc.l	ssincos		;$35-0 fsincos norm
	dc.l	ssincosz	;$35-1 fsincos zero
	dc.l	ssincosi	;$35-2 fsincos inf
	dc.l	ssincosnan	;$35-3 fsincos nan
	dc.l	ssincosd	;$35-4 fsincos denorm
	dc.l	serror		;$35-5 fsincos ERROR
	dc.l	serror		;$35-6 fsincos ERROR
	dc.l	serror		;$35-7 fsincos ERROR

	dc.l	ssincos		;$36-0 fsincos norm
	dc.l	ssincosz	;$36-1 fsincos zero
	dc.l	ssincosi	;$36-2 fsincos inf
	dc.l	ssincosnan	;$36-3 fsincos nan
	dc.l	ssincosd	;$36-4 fsincos denorm
	dc.l	serror		;$36-5 fsincos ERROR
	dc.l	serror		;$36-6 fsincos ERROR
	dc.l	serror		;$36-7 fsincos ERROR

	dc.l	ssincos		;$37-0 fsincos norm
	dc.l	ssincosz	;$37-1 fsincos zero
	dc.l	ssincosi	;$37-2 fsincos inf
	dc.l	ssincosnan	;$37-3 fsincos nan
	dc.l	ssincosd	;$37-4 fsincos denorm
	dc.l	serror		;$37-5 fsincos ERROR
	dc.l	serror		;$37-6 fsincos ERROR
	dc.l	serror		;$37-7 fsincos ERROR

	;end
;
;	util.sa 3.7 7/29/91
;
;	This file contains routines used by other programs.
;
;	ovf_res: used by overflow to force the correct
;		 result. ovf_r_k, ovf_r_x2, ovf_r_x3 are 
;		 derivatives of this routine.
;	get_fline: get user's opcode word
;	g_dfmtou: returns the destination format.
;	g_opcls: returns the opclass of the float instruction.
;	g_rndpr: returns the rounding precision. 
;	reg_dest: write byte, word, or long data to Dn
;
;
;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

;UTIL	idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	

	;xref	mem_read

	;|.global	g_dfmtou
	;|.global	g_opcls
	;|.global	g_rndpr
	;|.global	get_fline
	;|.global	reg_dest

;
; Final result table for ovf_res. Note that the negative counterparts
; are unnecessary as ovf_res always returns the sign separately from
; the exponent.
;					;+inf
EXT_PINF:	dc.l	$7fff0000,$00000000,$00000000,$00000000	
;					;largest +ext
EXT_PLRG:	dc.l	$7ffe0000,$ffffffff,$ffffffff,$00000000	
;					;largest magnitude +sgl in ext
SGL_PLRG:	dc.l	$407e0000,$ffffff00,$00000000,$00000000	
;					;largest magnitude +dbl in ext
DBL_PLRG:	dc.l	$43fe0000,$ffffffff,$fffff800,$00000000	
;					;largest -ext

tblovfl:
	dc.l	EXT_RN
	dc.l	EXT_RZ
	dc.l	EXT_RM
	dc.l	EXT_RP
	dc.l	SGL_RN
	dc.l	SGL_RZ
	dc.l	SGL_RM
	dc.l	SGL_RP
	dc.l	DBL_RN
	dc.l	DBL_RZ
	dc.l	DBL_RM
	dc.l	DBL_RP
	dc.l	error
	dc.l	error
	dc.l	error
	dc.l	error


;
;	ovf_r_k --- overflow result calculation
;
; This entry point is used by kernel_ex.  
;
; This forces the destination precision to be extended
;
; Input:	operand in ETEMP
; Output:	a result is in ETEMP (internal extended format)
;
	;|.global	ovf_r_k
ovf_r_k:
	lea	ETEMP(a6),a0	;a0 points to source operand	
	bclr.b	#sign_bit,ETEMP_EX(a6)
	sne	ETEMP_SGN(a6)	;convert to internal IEEE format

;
;	ovf_r_x2 --- overflow result calculation
;
; This entry point used by x_ovfl.  (opclass 0 and 2)
;
; Input		a0  points to an operand in the internal extended format
; Output	a0  points to the result in the internal extended format
;
; This sets the round precision according to the user's FPCR unless the
; instruction is fsgldiv or fsglmul or fsadd, fdadd, fsub, fdsub, fsmul,
; fdmul, fsdiv, fddiv, fssqrt, fsmove, fdmove, fsabs, fdabs, fsneg, fdneg.
; If the instruction is fsgldiv of fsglmul, the rounding precision must be
; extended.  If the instruction is not fsgldiv or fsglmul but a force-
; precision instruction, the rounding precision is then set to the force
; precision.

	;|.global	ovf_r_x2
ovf_r_x2:
	btst.b	#E3,E_BYTE(a6)		;check for nu exception
	beq.l	ovf_e1_exc		;it is cu exception
ovf_e3_exc:
	move.w	CMDREG3B(a6),d0		;get the command word
	andi.w	#$00000060,d0		;clear all bits except 6 and 5
	cmpi.l	#$00000040,d0
	beq.l	ovff_sgl		;force precision is single
	cmpi.l	#$00000060,d0
	beq.l	ovff_dbl		;force precision is double
	move.w	CMDREG3B(a6),d0		;get the command word again
	andi.l	#$7f,d0			;clear all except operation
	cmpi.l	#$33,d0			
	beq.l	ovf_fsgl		;fsglmul or fsgldiv
	cmpi.l	#$30,d0
	beq.l	ovf_fsgl		
	bra	ovf_fpcr		;instruction is none of the above
;					;use FPCR
ovf_e1_exc:
	move.w	CMDREG1B(a6),d0		;get command word
	andi.l	#$00000044,d0		;clear all bits except 6 and 2
	cmpi.l	#$00000040,d0
	beq.l	ovff_sgl		;the instruction is force single
	cmpi.l	#$00000044,d0
	beq.l	ovff_dbl		;the instruction is force double
	move.w	CMDREG1B(a6),d0		;again get the command word
	andi.l	#$0000007f,d0		;clear all except the op code
	cmpi.l	#$00000027,d0
	beq.l	ovf_fsgl		;fsglmul
	cmpi.l 	#$00000024,d0
	beq.l	ovf_fsgl		;fsgldiv
	bra	ovf_fpcr		;none of the above, use FPCR
; 
;
; Inst is either fsgldiv or fsglmul.  Force extended precision.
;
ovf_fsgl:
	clr.l	d0
	bra.s	ovf_res

ovff_sgl:
	move.l	#$00000001,d0		;set single
	bra.s	ovf_res
ovff_dbl:
	move.l	#$00000002,d0		;set double
	bra.s	ovf_res
;
; The precision is in the fpcr.
;
ovf_fpcr:
	bfextu	FPCR_MODE(a6){0:2},d0 ;set round precision
	bra.s	ovf_res
	
;
;
;	ovf_r_x3 --- overflow result calculation
;
; This entry point used by x_ovfl. (opclass 3 only)
;
; Input		a0  points to an operand in the internal extended format
; Output	a0  points to the result in the internal extended format
;
; This sets the round precision according to the destination size.
;
	;|.global	ovf_r_x3
ovf_r_x3:
	bsr	g_dfmtou	;get dest fmt in d0{1:0}
;				;for fmovout, the destination format
;				;is the rounding precision

;
;	ovf_res --- overflow result calculation
;
; Input:
;	a0 	points to operand in internal extended format
; Output:
;	a0 	points to result in internal extended format
;
	;|.global	ovf_res
ovf_res:
	lsl.l	#2,d0		;move round precision to d0{3:2}
	bfextu	FPCR_MODE(a6){2:2},d1 ;set round mode
	or.l	d1,d0		;index is fmt:mode in d0{3:0}
	lea.l	tblovfl(pc),a1	;load a1 with table address
	move.l	(a1,d0.l*4),a1	;use d0 as index to the table
	jmp	(a1)		;go to the correct routine
;
;case DEST_FMT = EXT
;
EXT_RN:
	lea.l	EXT_PINF(pc),a1	;answer is +/- infinity
	bset.b	#inf_bit,FPSR_CC(a6)
	bra	set_sign	;now go set the sign	
EXT_RZ:
	lea.l	EXT_PLRG(pc),a1	;answer is +/- large number
	bra	set_sign	;now go set the sign
EXT_RM:
	tst.b	LOCAL_SGN(a0)	;if negative overflow
	beq.s	e_rm_pos
e_rm_neg:
	lea.l	EXT_PINF(pc),a1	;answer is negative infinity
	or.l	#neginf_mask,USER_FPSR(a6)
	bra	end_ovfr
e_rm_pos:
	lea.l	EXT_PLRG(pc),a1	;answer is large positive number
	bra	end_ovfr
EXT_RP:
	tst.b	LOCAL_SGN(a0)	;if negative overflow
	beq.s	e_rp_pos
e_rp_neg:
	lea.l	EXT_PLRG(pc),a1	;answer is large negative number
	bset.b	#neg_bit,FPSR_CC(a6)
	bra	end_ovfr
e_rp_pos:
	lea.l	EXT_PINF(pc),a1	;answer is positive infinity
	bset.b	#inf_bit,FPSR_CC(a6)
	bra	end_ovfr
;
;case DEST_FMT = DBL
;
DBL_RN:
	lea.l	EXT_PINF(pc),a1	;answer is +/- infinity
	bset.b	#inf_bit,FPSR_CC(a6)
	bra	set_sign
DBL_RZ:
	lea.l	DBL_PLRG(pc),a1	;answer is +/- large number
	bra	set_sign	;now go set the sign
DBL_RM:
	tst.b	LOCAL_SGN(a0)	;if negative overflow
	beq.s	d_rm_pos
d_rm_neg:
	lea.l	EXT_PINF(pc),a1	;answer is negative infinity
	or.l	#neginf_mask,USER_FPSR(a6)
	bra	end_ovfr	;inf is same for all precisions (ext,dbl,sgl)
d_rm_pos:
	lea.l	DBL_PLRG(pc),a1	;answer is large positive number
	bra	end_ovfr
DBL_RP:
	tst.b	LOCAL_SGN(a0)	;if negative overflow
	beq.s	d_rp_pos
d_rp_neg:
	lea.l	DBL_PLRG(pc),a1	;answer is large negative number
	bset.b	#neg_bit,FPSR_CC(a6)
	bra	end_ovfr
d_rp_pos:
	lea.l	EXT_PINF(pc),a1	;answer is positive infinity
	bset.b	#inf_bit,FPSR_CC(a6)
	bra	end_ovfr
;
;case DEST_FMT = SGL
;
SGL_RN:
	lea.l	EXT_PINF(pc),a1	;answer is +/-  infinity
	bset.b	#inf_bit,FPSR_CC(a6)
	bra.s	set_sign
SGL_RZ:
	lea.l	SGL_PLRG(pc),a1	;answer is +/- large number
	bra.s	set_sign
SGL_RM:
	tst.b	LOCAL_SGN(a0)	;if negative overflow
	beq.s	s_rm_pos
s_rm_neg:
	lea.l	EXT_PINF(pc),a1	;answer is negative infinity
	or.l	#neginf_mask,USER_FPSR(a6)
	bra.s	end_ovfr
s_rm_pos:
	lea.l	SGL_PLRG(pc),a1	;answer is large positive number
	bra.s	end_ovfr
SGL_RP:
	tst.b	LOCAL_SGN(a0)	;if negative overflow
	beq.s	s_rp_pos
s_rp_neg:
	lea.l	SGL_PLRG(pc),a1	;answer is large negative number
	bset.b	#neg_bit,FPSR_CC(a6)
	bra.s	end_ovfr
s_rp_pos:
	lea.l	EXT_PINF(pc),a1	;answer is positive infinity
	bset.b	#inf_bit,FPSR_CC(a6)
	bra.s	end_ovfr

set_sign:
	tst.b	LOCAL_SGN(a0)	;if negative overflow
	beq.s	end_ovfr
neg_sign:
	bset.b	#neg_bit,FPSR_CC(a6)

end_ovfr:
	move.w	LOCAL_EX(a1),LOCAL_EX(a0) ;do not overwrite sign
	move.l	LOCAL_HI(a1),LOCAL_HI(a0)
	move.l	LOCAL_LO(a1),LOCAL_LO(a0)
	rts


;
;	ERROR
;
error:
	rts
;
;	get_fline --- get f-line opcode of interrupted instruction
;
;	Returns opcode in the low word of d0.
;
get_fline:
	move.l	USER_FPIAR(a6),a0	;opcode address
	move.l	#0,-(a7)	;reserve a word on the stack
	lea.l	2(a7),a1	;point to low word of temporary
	move.l	#2,d0		;count
	bsr.l	mem_read
	move.l	(a7)+,d0
	rts
;
; 	g_rndpr --- put rounding precision in d0{1:0}
;	
;	valid return codes are:
;		00 - extended 
;		01 - single
;		10 - double
;
; begin
; get rounding precision (cmdreg3b{6:5})
; begin
;  case	opclass = 011 (move out)
;	get destination format - this is the also the rounding precision
;
;  case	opclass = $0
;	if E3
;	    *case RndPr(from cmdreg3b{6:5} = 11  then RND_PREC = DBL
;	    *case RndPr(from cmdreg3b{6:5} = 10  then RND_PREC = SGL
;	     case RndPr(from cmdreg3b{6:5} = 00 ; 01
;		use precision from FPCR{7:6}
;			case 00 then RND_PREC = EXT
;			case 01 then RND_PREC = SGL
;			case 10 then RND_PREC = DBL
;	else E1
;	     use precision in FPCR{7:6}
;	     case 00 then RND_PREC = EXT
;	     case 01 then RND_PREC = SGL
;	     case 10 then RND_PREC = DBL
; end
;
g_rndpr:
	bsr	g_opcls		;get opclass in d0{2:0}
	cmp.w	#$0003,d0	;check for opclass 011
	bne.s	op_$0

;
; For move out instructions (opclass 011) the destination format
; is the same as the rounding precision.  Pass results from g_dfmtou.
;
	bsr 	g_dfmtou	
	rts
op_$0:
	btst.b	#E3,E_BYTE(a6)
	beq.l	unf_e1_exc	;branch to e1 underflow
unf_e3_exc:
	move.l	CMDREG3B(a6),d0	;rounding precision in d0{10:9}
	bfextu	d0{9:2},d0	;move the rounding prec bits to d0{1:0}
	cmpi.l	#$2,d0
	beq.l	unff_sgl	;force precision is single
	cmpi.l	#$3,d0		;force precision is double
	beq.l	unff_dbl
	move.w	CMDREG3B(a6),d0	;get the command word again
	andi.l	#$7f,d0		;clear all except operation
	cmpi.l	#$33,d0			
	beq.l	unf_fsgl	;fsglmul or fsgldiv
	cmpi.l	#$30,d0
	beq.l	unf_fsgl	;fsgldiv or fsglmul
	bra	unf_fpcr
unf_e1_exc:
	move.l	CMDREG1B(a6),d0	;get 32 bits off the stack, 1st 16 bits
;				;are the command word
	andi.l	#$00440000,d0	;clear all bits except bits 6 and 2
	cmpi.l	#$00400000,d0
	beq.l	unff_sgl	;force single
	cmpi.l	#$00440000,d0	;force double
	beq.l	unff_dbl
	move.l	CMDREG1B(a6),d0	;get the command word again
	andi.l	#$007f0000,d0	;clear all bits except the operation
	cmpi.l	#$00270000,d0
	beq.l	unf_fsgl	;fsglmul
	cmpi.l	#$00240000,d0
	beq.l	unf_fsgl	;fsgldiv
	bra	unf_fpcr

;
; Convert to return format.  The values from cmdreg3b and the return
; values are:
;	cmdreg3b	return	     precision
;	--------	------	     ---------
;	  00,01		  0		ext
;	   10		  1		sgl
;	   11		  2		dbl
; Force single
;
unff_sgl:
	move.l	#1,d0		;return 1
	rts
;
; Force double
;
unff_dbl:
	move.l	#2,d0		;return 2
	rts
;
; Force extended
;
unf_fsgl:
	move.l	#0,d0		
	rts
;
; Get rounding precision set in FPCR{7:6}.
;
unf_fpcr:
	move.l	USER_FPCR(a6),d0 ;rounding precision bits in d0{7:6}
	bfextu	d0{24:2},d0	;move the rounding prec bits to d0{1:0}
	rts
;
;	g_opcls --- put opclass in d0{2:0}
;
g_opcls:
	btst.b	#E3,E_BYTE(a6)
	beq.s	opc_1b		;if set, go to cmdreg1b
opc_3b:
	clr.l	d0		;if E3, only opclass $0 is possible
	rts
opc_1b:
	move.l	CMDREG1B(a6),d0
	bfextu	d0{0:3},d0	;shift opclass bits d0{31:29} to d0{2:0}
	rts
;
;	g_dfmtou --- put destination format in d0{1:0}
;
;	If E1, the format is from cmdreg1b{12:10}
;	If E3, the format is extended.
;
;	Dest. Fmt.	
;		extended  010 -> 00
;		single    001 -> 01
;		double    101 -> 10
;
g_dfmtou:
	btst.b	#E3,E_BYTE(a6)
	beq.s	op011
	clr.l	d0		;if E1, size is always ext
	rts
op011:
	move.l	CMDREG1B(a6),d0
	bfextu	d0{3:3},d0	;dest fmt from cmdreg1b{12:10}
	cmp.b	#1,d0		;check for single
	bne.s	not_sgl
	move.l	#1,d0
	rts
not_sgl:
	cmp.b	#5,d0		;check for double
	bne.s	not_dbl
	move.l	#2,d0
	rts
not_dbl:
	clr.l	d0		;must be extended
	rts

;
;
; Final result table for unf_sub. Note that the negative counterparts
; are unnecessary as unf_sub always returns the sign separately from
; the exponent.
;					;+zero
EXT_PZRO:	dc.l	$00000000,$00000000,$00000000,$00000000	
;					;+zero
SGL_PZRO:	dc.l	$3f810000,$00000000,$00000000,$00000000	
;					;+zero
DBL_PZRO:	dc.l	$3c010000,$00000000,$00000000,$00000000	
;					;smallest +ext denorm
EXT_PSML:	dc.l	$00000000,$00000000,$00000001,$00000000	
;					;smallest +sgl denorm
SGL_PSML:	dc.l	$3f810000,$00000100,$00000000,$00000000	
;					;smallest +dbl denorm
DBL_PSML:	dc.l	$3c010000,$00000000,$00000800,$00000000	
;
;	UNF_SUB --- underflow result calculation
;
; Input:
;	d0 	contains round precision
;	a0	points to input operand in the internal extended format
;
; Output:
;	a0 	points to correct internal extended precision result.
;

tblunf:
	dc.l	uEXT_RN
	dc.l	uEXT_RZ
	dc.l	uEXT_RM
	dc.l	uEXT_RP
	dc.l	uSGL_RN
	dc.l	uSGL_RZ
	dc.l	uSGL_RM
	dc.l	uSGL_RP
	dc.l	uDBL_RN
	dc.l	uDBL_RZ
	dc.l	uDBL_RM
	dc.l	uDBL_RP
	dc.l	uDBL_RN
	dc.l	uDBL_RZ
	dc.l	uDBL_RM
	dc.l	uDBL_RP

	;|.global	unf_sub
unf_sub:
	lsl.l	#2,d0		;move round precision to d0{3:2}
	bfextu	FPCR_MODE(a6){2:2},d1 ;set round mode
	or.l	d1,d0		;index is fmt:mode in d0{3:0}
	lea.l	tblunf(pc),a1	;load a1 with table address
	move.l	(a1,d0.l*4),a1	;use d0 as index to the table
	jmp	(a1)		;go to the correct routine
;
;case DEST_FMT = EXT
;
uEXT_RN:
	lea.l	EXT_PZRO(pc),a1	;answer is +/- zero
	bset.b	#z_bit,FPSR_CC(a6)
	bra	uset_sign	;now go set the sign	
uEXT_RZ:
	lea.l	EXT_PZRO(pc),a1	;answer is +/- zero
	bset.b	#z_bit,FPSR_CC(a6)
	bra	uset_sign	;now go set the sign
uEXT_RM:
	tst.b	LOCAL_SGN(a0)	;if negative underflow
	beq.s	ue_rm_pos
ue_rm_neg:
	lea.l	EXT_PSML(pc),a1	;answer is negative smallest denorm
	bset.b	#neg_bit,FPSR_CC(a6)
	bra	end_unfr
ue_rm_pos:
	lea.l	EXT_PZRO(pc),a1	;answer is positive zero
	bset.b	#z_bit,FPSR_CC(a6)
	bra	end_unfr
uEXT_RP:
	tst.b	LOCAL_SGN(a0)	;if negative underflow
	beq.s	ue_rp_pos
ue_rp_neg:
	lea.l	EXT_PZRO(pc),a1	;answer is negative zero
	ori.l	#negz_mask,USER_FPSR(a6)
	bra	end_unfr
ue_rp_pos:
	lea.l	EXT_PSML(pc),a1	;answer is positive smallest denorm
	bra	end_unfr
;
;case DEST_FMT = DBL
;
uDBL_RN:
	lea.l	DBL_PZRO(pc),a1	;answer is +/- zero
	bset.b	#z_bit,FPSR_CC(a6)
	bra	uset_sign
uDBL_RZ:
	lea.l	DBL_PZRO(pc),a1	;answer is +/- zero
	bset.b	#z_bit,FPSR_CC(a6)
	bra	uset_sign	;now go set the sign
uDBL_RM:
	tst.b	LOCAL_SGN(a0)	;if negative overflow
	beq.s	ud_rm_pos
ud_rm_neg:
	lea.l	DBL_PSML(pc),a1	;answer is smallest denormalized negative
	bset.b	#neg_bit,FPSR_CC(a6)
	bra	end_unfr
ud_rm_pos:
	lea.l	DBL_PZRO(pc),a1	;answer is positive zero
	bset.b	#z_bit,FPSR_CC(a6)
	bra	end_unfr
uDBL_RP:
	tst.b	LOCAL_SGN(a0)	;if negative overflow
	beq.s	ud_rp_pos
ud_rp_neg:
	lea.l	DBL_PZRO(pc),a1	;answer is negative zero
	ori.l	#negz_mask,USER_FPSR(a6)
	bra	end_unfr
ud_rp_pos:
	lea.l	DBL_PSML(pc),a1	;answer is smallest denormalized negative
	bra	end_unfr
;
;case DEST_FMT = SGL
;
uSGL_RN:
	lea.l	SGL_PZRO(pc),a1	;answer is +/- zero
	bset.b	#z_bit,FPSR_CC(a6)
	bra.s	uset_sign
uSGL_RZ:
	lea.l	SGL_PZRO(pc),a1	;answer is +/- zero
	bset.b	#z_bit,FPSR_CC(a6)
	bra.s	uset_sign
uSGL_RM:
	tst.b	LOCAL_SGN(a0)	;if negative overflow
	beq.s	us_rm_pos
us_rm_neg:
	lea.l	SGL_PSML(pc),a1	;answer is smallest denormalized negative
	bset.b	#neg_bit,FPSR_CC(a6)
	bra.s	end_unfr
us_rm_pos:
	lea.l	SGL_PZRO(pc),a1	;answer is positive zero
	bset.b	#z_bit,FPSR_CC(a6)
	bra.s	end_unfr
uSGL_RP:
	tst.b	LOCAL_SGN(a0)	;if negative overflow
	beq.s	us_rp_pos
us_rp_neg:
	lea.l	SGL_PZRO(pc),a1	;answer is negative zero
	ori.l	#negz_mask,USER_FPSR(a6)
	bra.s	end_unfr
us_rp_pos:
	lea.l	SGL_PSML(pc),a1	;answer is smallest denormalized positive
	bra.s	end_unfr

uset_sign:
	tst.b	LOCAL_SGN(a0)	;if negative overflow
	beq.s	end_unfr
uneg_sign:
	bset.b	#neg_bit,FPSR_CC(a6)

end_unfr:
	move.w	LOCAL_EX(a1),LOCAL_EX(a0) ;be careful not to overwrite sign
	move.l	LOCAL_HI(a1),LOCAL_HI(a0)
	move.l	LOCAL_LO(a1),LOCAL_LO(a0)
	rts
;
;	reg_dest --- write byte, word, or long data to Dn
;
;
; Input:
;	L_SCR1: Data 
;	d1:     data size and dest register number formatted as:
;
;	32		5    4     3     2     1     0
;       -----------------------------------------------
;       ;        0        ;    Size   ;  Dest Reg #   ; ;       -----------------------------------------------
;
;	Size is:
;		0 - Byte
;		1 - Word
;		2 - Long/Single
;
pregdst:
	dc.l	byte_d0
	dc.l	byte_d1
	dc.l	byte_d2
	dc.l	byte_d3
	dc.l	byte_d4
	dc.l	byte_d5
	dc.l	byte_d6
	dc.l	byte_d7
	dc.l	word_d0
	dc.l	word_d1
	dc.l	word_d2
	dc.l	word_d3
	dc.l	word_d4
	dc.l	word_d5
	dc.l	word_d6
	dc.l	word_d7
	dc.l	long_d0
	dc.l	long_d1
	dc.l	long_d2
	dc.l	long_d3
	dc.l	long_d4
	dc.l	long_d5
	dc.l	long_d6
	dc.l	long_d7

reg_dest:
	lea.l	pregdst(pc),a0
	move.l	(a0,d1.l*4),a0
	jmp	(a0)

byte_d0:
	move.b	L_SCR1(a6),USER_D0+3(a6)
	rts
byte_d1:
	move.b	L_SCR1(a6),USER_D1+3(a6)
	rts
byte_d2:
	move.b	L_SCR1(a6),d2
	rts
byte_d3:
	move.b	L_SCR1(a6),d3
	rts
byte_d4:
	move.b	L_SCR1(a6),d4
	rts
byte_d5:
	move.b	L_SCR1(a6),d5
	rts
byte_d6:
	move.b	L_SCR1(a6),d6
	rts
byte_d7:
	move.b	L_SCR1(a6),d7
	rts
word_d0:
	move.w	L_SCR1(a6),USER_D0+2(a6)
	rts
word_d1:
	move.w	L_SCR1(a6),USER_D1+2(a6)
	rts
word_d2:
	move.w	L_SCR1(a6),d2
	rts
word_d3:
	move.w	L_SCR1(a6),d3
	rts
word_d4:
	move.w	L_SCR1(a6),d4
	rts
word_d5:
	move.w	L_SCR1(a6),d5
	rts
word_d6:
	move.w	L_SCR1(a6),d6
	rts
word_d7:
	move.w	L_SCR1(a6),d7
	rts
long_d0:
	move.l	L_SCR1(a6),USER_D0(a6)
	rts
long_d1:
	move.l	L_SCR1(a6),USER_D1(a6)
	rts
long_d2:
	move.l	L_SCR1(a6),d2
	rts
long_d3:
	move.l	L_SCR1(a6),d3
	rts
long_d4:
	move.l	L_SCR1(a6),d4
	rts
long_d5:
	move.l	L_SCR1(a6),d5
	rts
long_d6:
	move.l	L_SCR1(a6),d6
	rts
long_d7:
	move.l	L_SCR1(a6),d7
	rts
	;end
;
;	x_bsun.sa 3.3 7/1/91
;
;	fpsp_bsun --- FPSP handler for branch/set on unordered exception
;
;	Copy the PC to FPIAR to maintain 881/882 compatibility
;
;	The real_bsun handler will need to perform further corrective
;	measures as outlined in the 040 User's Manual on pages
;	9-41f, section 9.8.3.
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

X_BSUN:	;idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	

	;xref	real_bsun

	;|.global	fpsp_bsun
fpsp_bsun:
;
	link		a6,#-LOCAL_SIZE
	fsave		-(a7)
	movem.l		d0-d1/a0-a1,USER_DA(a6)
	fmovem.x	fp0-fp3,USER_FP0(a6)
	fmovem.l	fpcr/fpsr/fpiar,USER_FPCR(a6)

;
	move.l		EXC_PC(a6),USER_FPIAR(a6)
;
	movem.l		USER_DA(a6),d0-d1/a0-a1
	fmovem.x	USER_FP0(a6),fp0-fp3
	fmovem.l	USER_FPCR(a6),fpcr/fpsr/fpiar
	frestore	(a7)+
	unlk		a6
	bra.l		real_bsun
;
	;end
;
;	x_fline.sa 3.3 1/10/91
;
;	fpsp_fline --- FPSP handler for fline exception
;
;	First determine if the exception is one of the unimplemented
;	floating point instructions.  If so, let fpsp_unimp handle it.
;	Next, determine if the instruction is an fmovecr with a non-zero
;	<ea> field.  If so, handle here and return.  Otherwise, it
;	must be a real F-line exception.
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

X_FLINE:	;idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	

	;xref	real_fline
	;xref	fpsp_unimp
	;xref	uni_2
	;xref	mem_read
	;xref	fpsp_fmt_error

	;|.global	fpsp_fline
fpsp_fline:
;
;	check for unimplemented vector first.  Use EXC_VEC-4 because
;	the equate is valid only after a 'link a6' has pushed one more
;	long onto the stack.
;
	cmp.w	#UNIMP_VEC,EXC_VEC-4(a7)
	beq.l	fpsp_unimp

;
;	fmovecr with non-zero <ea> handling here
;
	sub.l	#4,a7		;4 accounts for 2-word difference
;				;between six word frame (unimp) and
;				;four word frame
	link	a6,#-LOCAL_SIZE
	fsave	-(a7)
	movem.l	d0-d1/a0-a1,USER_DA(a6)
	movea.l	EXC_PC+4(a6),a0	;get address of fline instruction
	lea.l	L_SCR1(a6),a1	;use L_SCR1 as scratch
	move.l	#4,d0
	add.l	#4,a6		;to offset the sub.l #4,a7 above so that
;				;a6 can point correctly to the stack frame 
;				;before branching to mem_read
	bsr.l	mem_read
	sub.l	#4,a6
	move.l	L_SCR1(a6),d0	;d0 contains the fline and command word
	bfextu	d0{4:3},d1	;extract coprocessor id
	cmpi.b	#1,d1		;check if cpid=1
	bne	not_mvcr	;exit if not
	bfextu	d0{16:6},d1
	cmpi.b	#$17,d1		;check if it is an FMOVECR encoding
	bne	not_mvcr	
;				;if an FMOVECR instruction, fix stack
;				;and go to FPSP_UNIMP
fix_stack:
	cmpi.b	#VER_40,(a7)	;test for orig unimp frame
	bne.s	ck_rev
	sub.l	#UNIMP_40_SIZE-4,a7 ;emulate an orig fsave
	move.b	#VER_40,(a7)
	move.b	#UNIMP_40_SIZE-4,1(a7)
	clr.w	2(a7)
	bra.s	fix_con
ck_rev:
	cmpi.b	#VER_41,(a7)	;test for rev unimp frame
	bne.l	fpsp_fmt_error	;if not $40 or $41, exit with error
	sub.l	#UNIMP_41_SIZE-4,a7 ;emulate a rev fsave
	move.b	#VER_41,(a7)
	move.b	#UNIMP_41_SIZE-4,1(a7)
	clr.w	2(a7)
fix_con:
	move.w	EXC_SR+4(a6),EXC_SR(a6) ;move stacked sr to new position
	move.l	EXC_PC+4(a6),EXC_PC(a6) ;move stacked pc to new position
	fmove.l	EXC_PC(a6),FPIAR ;point FPIAR to fline inst
	move.l	#4,d1
	add.l	d1,EXC_PC(a6)	;increment stacked pc value to next inst
	move.w	#$202c,EXC_VEC(a6) ;reformat vector to unimp
	clr.l	EXC_EA(a6)	;clear the EXC_EA field
	move.w	d0,CMDREG1B(a6) ;move the lower word into CMDREG1B
	clr.l	E_BYTE(a6)
	bset.b	#UFLAG,T_BYTE(a6)
	movem.l	USER_DA(a6),d0-d1/a0-a1 ;restore data registers
	bra.l	uni_2

not_mvcr:
	movem.l	USER_DA(a6),d0-d1/a0-a1 ;restore data registers
	frestore (a7)+
	unlk	a6
	add.l	#4,a7
	bra.l	real_fline

	;end
;
;	x_operr.sa 3.5 7/1/91
;
;	fpsp_operr --- FPSP handler for operand error exception
;
;	See 68040 User's Manual pp. 9-44f
;
; Note 1: For trap disabled 040 does the following:
; If the dest is a fp reg, then an extended precision non_signaling
; NAN is stored in the dest reg.  If the dest format is b, w, or l and
; the source op is a NAN, then garbage is stored as the result (actually
; the upper 32 bits of the mantissa are sent to the integer unit). If
; the dest format is integer (b, w, l) and the operr is caused by
; integer overflow, or the source op is inf, then the result stored is
; garbage.
; There are three cases in which operr is incorrectly signaled on the 
; 040.  This occurs for move_out of format b, w, or l for the largest 
; negative integer (-2^7 for b, -2^15 for w, -2^31 for l).
;
;	  On opclass = 011 fmove.(b,w,l) that causes a conversion
;	  overflow -> OPERR, the exponent in wbte (and fpte) is:
;		byte    56 - (62 - exp)
;		word    48 - (62 - exp)
;		long    32 - (62 - exp)
;
;			where exp = (true exp) - 1
;
;  So, wbtemp and fptemp will contain the following on erroneously
;	  signalled operr:
;			fpts = 1
;			fpte = $4000  (15 bit externally)
;		byte	fptm = $ffffffff ffffff80
;		word	fptm = $ffffffff ffff8000
;		long	fptm = $ffffffff 80000000
;
; Note 2: For trap enabled 040 does the following:
; If the inst is move_out, then same as Note 1.
; If the inst is not move_out, the dest is not modified.
; The exceptional operand is not defined for integer overflow 
; during a move_out.
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

X_OPERR:	;idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	

	;xref	mem_write
	;xref	real_operr
	;xref	real_inex
	;xref	get_fline
	;xref	fpsp_done
	;xref	reg_dest

	;|.global	fpsp_operr
fpsp_operr:
;
	link		a6,#-LOCAL_SIZE
	fsave		-(a7)
	movem.l		d0-d1/a0-a1,USER_DA(a6)
	fmovem.x	fp0-fp3,USER_FP0(a6)
	fmovem.l	fpcr/fpsr/fpiar,USER_FPCR(a6)

;
; Check if this is an opclass 3 instruction.
;  If so, fall through, else branch to operr_end
;
	btst.b	#TFLAG,T_BYTE(a6)
	beq.s	operr_end

;
; If the destination size is B,W,or L, the operr must be 
; handled here.
;
	move.l	CMDREG1B(a6),d0
	bfextu	d0{3:3},d0	;0=long, 4=word, 6=byte
	cmpi.b	#0,d0		;determine size; check long
	beq	operr_long
	cmpi.b	#4,d0		;check word
	beq	operr_word
	cmpi.b	#6,d0		;check byte
	beq	operr_byte

;
; The size is not B,W,or L, so the operr is handled by the 
; kernel handler.  Set the operr bits and clean up, leaving
; only the integer exception frame on the stack, and the 
; fpu in the original exceptional state.
;
operr_end:
	bset.b		#operr_bit,FPSR_EXCEPT(a6)
	bset.b		#aiop_bit,FPSR_AEXCEPT(a6)

	movem.l		USER_DA(a6),d0-d1/a0-a1
	fmovem.x	USER_FP0(a6),fp0-fp3
	fmovem.l	USER_FPCR(a6),fpcr/fpsr/fpiar
	frestore	(a7)+
	unlk		a6
	bra.l		real_operr

operr_long:
	moveq.l	#4,d1		;write size to d1
	move.b	STAG(a6),d0	;test stag for nan
	andi.b	#$e0,d0		;clr all but tag
	cmpi.b	#$60,d0		;check for nan
	beq	operr_nan	
	cmpi.l	#$80000000,FPTEMP_LO(a6) ;test if ls lword is special
	bne.s	chklerr		;if not equal, check for incorrect operr
	bsr	check_upper	;check if exp and ms mant are special
	tst.l	d0
	bne.s	chklerr		;if d0 is true, check for incorrect operr
	move.l	#$80000000,d0	;store special case result
	bsr	operr_store
	bra	not_enabled	;clean and exit
;
;	CHECK FOR INCORRECTLY GENERATED OPERR EXCEPTION HERE
;
chklerr:
	move.w	FPTEMP_EX(a6),d0
	and.w	#$7FFF,d0	;ignore sign bit
	cmp.w	#$3FFE,d0	;this is the only possible exponent value
	bne.s	chklerr2
fixlong:
	move.l	FPTEMP_LO(a6),d0
	bsr	operr_store
	bra	not_enabled
chklerr2:
	move.w	FPTEMP_EX(a6),d0
	and.w	#$7FFF,d0	;ignore sign bit
	cmp.w	#$4000,d0
	bcc	store_max	;exponent out of range

	move.l	FPTEMP_LO(a6),d0
	and.l	#$7FFF0000,d0	;look for all 1's on bits 30-16
	cmp.l	#$7FFF0000,d0
	beq.s	fixlong

	tst.l	FPTEMP_LO(a6)
	bpl.s	chklepos
	cmp.l	#$FFFFFFFF,FPTEMP_HI(a6)
	beq.s	fixlong
	bra	store_max
chklepos:
	tst.l	FPTEMP_HI(a6)
	beq.s	fixlong
	bra	store_max

operr_word:
	moveq.l	#2,d1		;write size to d1
	move.b	STAG(a6),d0	;test stag for nan
	andi.b	#$e0,d0		;clr all but tag
	cmpi.b	#$60,d0		;check for nan
	beq	operr_nan	
	cmpi.l	#$ffff8000,FPTEMP_LO(a6) ;test if ls lword is special
	bne.s	chkwerr		;if not equal, check for incorrect operr
	bsr	check_upper	;check if exp and ms mant are special
	tst.l	d0
	bne.s	chkwerr		;if d0 is true, check for incorrect operr
	move.l	#$80000000,d0	;store special case result
	bsr	operr_store
	bra	not_enabled	;clean and exit
;
;	CHECK FOR INCORRECTLY GENERATED OPERR EXCEPTION HERE
;
chkwerr:
	move.w	FPTEMP_EX(a6),d0
	and.w	#$7FFF,d0	;ignore sign bit
	cmp.w	#$3FFE,d0	;this is the only possible exponent value
	bne.s	store_max
	move.l	FPTEMP_LO(a6),d0
	swap	d0
	bsr	operr_store
	bra	not_enabled

operr_byte:
	moveq.l	#1,d1		;write size to d1
	move.b	STAG(a6),d0	;test stag for nan
	andi.b	#$e0,d0		;clr all but tag
	cmpi.b	#$60,d0		;check for nan
	beq.s	operr_nan	
	cmpi.l	#$ffffff80,FPTEMP_LO(a6) ;test if ls lword is special
	bne.s	chkberr		;if not equal, check for incorrect operr
	bsr	check_upper	;check if exp and ms mant are special
	tst.l	d0
	bne.s	chkberr		;if d0 is true, check for incorrect operr
	move.l	#$80000000,d0	;store special case result
	bsr	operr_store
	bra	not_enabled	;clean and exit
;
;	CHECK FOR INCORRECTLY GENERATED OPERR EXCEPTION HERE
;
chkberr:
	move.w	FPTEMP_EX(a6),d0
	and.w	#$7FFF,d0	;ignore sign bit
	cmp.w	#$3FFE,d0	;this is the only possible exponent value
	bne.s	store_max
	move.l	FPTEMP_LO(a6),d0
	asl.l	#8,d0
	swap	d0
	bsr	operr_store
	bra	not_enabled

;
; This operr condition is not of the special case.  Set operr
; and aiop and write the portion of the nan to memory for the
; given size.
;
operr_nan:
	or.l	#opaop_mask,USER_FPSR(a6) ;set operr & aiop

	move.l	ETEMP_HI(a6),d0	;output will be from upper 32 bits
	bsr	operr_store
	bra	end_operr
;
; Store_max loads the max pos or negative for the size, sets
; the operr and aiop bits, and clears inex and ainex, incorrectly
; set by the 040.
;
store_max:
	or.l	#opaop_mask,USER_FPSR(a6) ;set operr & aiop
	bclr.b	#inex2_bit,FPSR_EXCEPT(a6)
	bclr.b	#ainex_bit,FPSR_AEXCEPT(a6)
	fmove.l	#0,FPSR
	
	tst.w	FPTEMP_EX(a6)	;check sign
	blt.s	load_neg
	move.l	#$7fffffff,d0
	bsr	operr_store
	bra	end_operr
load_neg:
	move.l	#$80000000,d0
	bsr	operr_store
	bra	end_operr

;
; This routine stores the data in d0, for the given size in d1,
; to memory or data register as required.  A read of the fline
; is required to determine the destination.
;
operr_store:
	move.l	d0,L_SCR1(a6)	;move write data to L_SCR1
	move.l	d1,-(a7)	;save register size
	bsr.l	get_fline	;fline returned in d0
	move.l	(a7)+,d1
	bftst	d0{26:3}		;if mode is zero, dest is Dn
	bne.s	dest_mem
;
; Destination is Dn.  Get register number from d0. Data is on
; the stack at (a7). D1 has size: 1=byte,2=word,4=long/single
;
	andi.l	#7,d0		;isolate register number
	cmpi.l	#4,d1
	beq.s	op_long		;the most frequent case
	cmpi.l	#2,d1
	bne.s	op_con
	or.l	#8,d0
	bra.s	op_con
op_long:
	or.l	#$10,d0
op_con:
	move.l	d0,d1		;format size:reg for reg_dest
	bra.l	reg_dest	;call to reg_dest returns to caller
;				;of operr_store
;
; Destination is memory.  Get <ea> from integer exception frame
; and call mem_write.
;
dest_mem:
	lea.l	L_SCR1(a6),a0	;put ptr to write data in a0
	move.l	EXC_EA(a6),a1	;put user destination address in a1
	move.l	d1,d0		;put size in d0
	bsr.l	mem_write
	rts
;
; Check the exponent for $c000 and the upper 32 bits of the 
; mantissa for $ffffffff.  If both are true, return d0 clr
; and store the lower n bits of the least lword of FPTEMP
; to d0 for write out.  If not, it is a real operr, and set d0.
;
check_upper:
	cmpi.l	#$ffffffff,FPTEMP_HI(a6) ;check if first byte is all 1's
	bne.s	true_operr	;if not all 1's then was true operr
	cmpi.w	#$c000,FPTEMP_EX(a6) ;check if incorrectly signalled
	beq.s	not_true_operr	;branch if not true operr
	cmpi.w	#$bfff,FPTEMP_EX(a6) ;check if incorrectly signalled
	beq.s	not_true_operr	;branch if not true operr
true_operr:
	move.l	#1,d0		;signal real operr
	rts
not_true_operr:
	clr.l	d0		;signal no real operr
	rts

;
; End_operr tests for operr enabled.  If not, it cleans up the stack
; and does an rte.  If enabled, it cleans up the stack and branches
; to the kernel operr handler with only the integer exception
; frame on the stack and the fpu in the original exceptional state
; with correct data written to the destination.
;
end_operr:
	btst.b		#operr_bit,FPCR_ENABLE(a6)
	beq.s		not_enabled
enabled:
	movem.l		USER_DA(a6),d0-d1/a0-a1
	fmovem.x	USER_FP0(a6),fp0-fp3
	fmovem.l	USER_FPCR(a6),fpcr/fpsr/fpiar
	frestore	(a7)+
	unlk		a6
	bra.l		real_operr

not_enabled:
;
; It is possible to have either inex2 or inex1 exceptions with the
; operr.  If the inex enable bit is set in the FPCR, and either
; inex2 or inex1 occurred, we must clean up and branch to the
; real inex handler.
;
.ck_inex:
	move.b	FPCR_ENABLE(a6),d0
	and.b	FPSR_EXCEPT(a6),d0
	andi.b	#$3,d0
	beq	operr_exit
;
; Inexact enabled and reported, and we must take an inexact exception.
;
.take_inex:
	move.b		#INEX_VEC,EXC_VEC+1(a6)
	move.l		USER_FPSR(a6),FPSR_SHADOW(a6)
	or.l		#sx_mask,E_BYTE(a6)
	movem.l		USER_DA(a6),d0-d1/a0-a1
	fmovem.x	USER_FP0(a6),fp0-fp3
	fmovem.l	USER_FPCR(a6),fpcr/fpsr/fpiar
	frestore	(a7)+
	unlk		a6
	bra.l		real_inex
;
; Since operr is only an E1 exception, there is no need to frestore
; any state back to the fpu.
;
operr_exit:
	movem.l		USER_DA(a6),d0-d1/a0-a1
	fmovem.x	USER_FP0(a6),fp0-fp3
	fmovem.l	USER_FPCR(a6),fpcr/fpsr/fpiar
	unlk		a6
	bra.l		fpsp_done

	;end
;
;	x_ovfl.sa 3.5 7/1/91
;
;	fpsp_ovfl --- FPSP handler for overflow exception
;
;	Overflow occurs when a floating-point intermediate result is
;	too large to be represented in a floating-point data register,
;	or when storing to memory, the contents of a floating-point
;	data register are too large to be represented in the
;	destination format.
;		
; Trap disabled results
;
; If the instruction is move_out, then garbage is stored in the
; destination.  If the instruction is not move_out, then the
; destination is not affected.  For 68881 compatibility, the
; following values should be stored at the destination, based
; on the current rounding mode:
;
;  RN	Infinity with the sign of the intermediate result.
;  RZ	Largest magnitude number, with the sign of the
;	intermediate result.
;  RM   For pos overflow, the largest pos number. For neg overflow,
;	-infinity
;  RP   For pos overflow, +infinity. For neg overflow, the largest
;	neg number
;
; Trap enabled results
; All trap disabled code applies.  In addition the exceptional
; operand needs to be made available to the users exception handler
; with a bias of $6000 subtracted from the exponent.
;
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

X_OVFL:	;idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	

	;xref	ovf_r_x2
	;xref	ovf_r_x3
	;xref	store
	;xref	real_ovfl
	;xref	real_inex
	;xref	fpsp_done
	;xref	g_opcls
	;xref	b1238_fix

	;|.global	fpsp_ovfl
fpsp_ovfl:
	link		a6,#-LOCAL_SIZE
	fsave		-(a7)
	movem.l		d0-d1/a0-a1,USER_DA(a6)
	fmovem.x	fp0-fp3,USER_FP0(a6)
	fmovem.l	fpcr/fpsr/fpiar,USER_FPCR(a6)

;
;	The 040 doesn't set the AINEX bit in the FPSR, the following
;	line temporarily rectifies this error.
;
	bset.b	#ainex_bit,FPSR_AEXCEPT(a6)
;
	bsr.l	ovf_adj		;denormalize, round & store interm op
;
;	if overflow traps not enabled check for inexact exception
;
	btst.b	#ovfl_bit,FPCR_ENABLE(a6)
	beq.s	ck_inex_	
;
	btst.b		#E3,E_BYTE(a6)
	beq.s		.no_e3_1
	bfextu		CMDREG3B(a6){6:3},d0	;get dest reg no
	bclr.b		d0,FPR_DIRTY_BITS(a6)	;clr dest dirty bit
	bsr.l		b1238_fix
	move.l		USER_FPSR(a6),FPSR_SHADOW(a6)
	or.l		#sx_mask,E_BYTE(a6)
.no_e3_1:
	movem.l		USER_DA(a6),d0-d1/a0-a1
	fmovem.x	USER_FP0(a6),fp0-fp3
	fmovem.l	USER_FPCR(a6),fpcr/fpsr/fpiar
	frestore	(a7)+
	unlk		a6
	bra.l		real_ovfl
;
; It is possible to have either inex2 or inex1 exceptions with the
; ovfl.  If the inex enable bit is set in the FPCR, and either
; inex2 or inex1 occurred, we must clean up and branch to the
; real inex handler.
;
ck_inex_:
;	move.b		FPCR_ENABLE(a6),d0
;	and.b		FPSR_EXCEPT(a6),d0
;	andi.b		#$3,d0
	btst.b		#inex2_bit,FPCR_ENABLE(a6)
	beq.s		ovfl_exit
;
; Inexact enabled and reported, and we must take an inexact exception.
;
.take_inex:
	btst.b		#E3,E_BYTE(a6)
	beq.s		.no_e3_2
	bfextu		CMDREG3B(a6){6:3},d0	;get dest reg no
	bclr.b		d0,FPR_DIRTY_BITS(a6)	;clr dest dirty bit
	bsr.l		b1238_fix
	move.l		USER_FPSR(a6),FPSR_SHADOW(a6)
	or.l		#sx_mask,E_BYTE(a6)
.no_e3_2:
	move.b		#INEX_VEC,EXC_VEC+1(a6)
	movem.l		USER_DA(a6),d0-d1/a0-a1
	fmovem.x	USER_FP0(a6),fp0-fp3
	fmovem.l	USER_FPCR(a6),fpcr/fpsr/fpiar
	frestore	(a7)+
	unlk		a6
	bra.l		real_inex
	
ovfl_exit:
	bclr.b	#E3,E_BYTE(a6)	;test and clear E3 bit
	beq.s	e1_set
;
; Clear dirty bit on dest resister in the frame before branching
; to b1238_fix.
;
	bfextu		CMDREG3B(a6){6:3},d0	;get dest reg no
	bclr.b		d0,FPR_DIRTY_BITS(a6)	;clr dest dirty bit
	bsr.l		b1238_fix		;test for bug1238 case

	move.l		USER_FPSR(a6),FPSR_SHADOW(a6)
	or.l		#sx_mask,E_BYTE(a6)
	movem.l		USER_DA(a6),d0-d1/a0-a1
	fmovem.x	USER_FP0(a6),fp0-fp3
	fmovem.l	USER_FPCR(a6),fpcr/fpsr/fpiar
	frestore	(a7)+
	unlk		a6
	bra.l		fpsp_done
e1_set:
	movem.l		USER_DA(a6),d0-d1/a0-a1
	fmovem.x	USER_FP0(a6),fp0-fp3
	fmovem.l	USER_FPCR(a6),fpcr/fpsr/fpiar
	unlk		a6
	bra.l		fpsp_done

;
;	ovf_adj
;
ovf_adj:
;
; Have a0 point to the correct operand. 
;
	btst.b	#E3,E_BYTE(a6)	;test E3 bit
	beq.s	ovf_e1

	lea	WBTEMP(a6),a0
	bra.s	ovf_com
ovf_e1:
	lea	ETEMP(a6),a0

ovf_com:
	bclr.b	#sign_bit,LOCAL_EX(a0)
	sne	LOCAL_SGN(a0)

	bsr.l	g_opcls		;returns opclass in d0
	cmpi.w	#3,d0		;check for opclass3
	bne.s	.not_opc011

;
; FPSR_CC is saved and restored because ovf_r_x3 affects it. The
; CCs are defined to be 'not affected' for the opclass3 instruction.
;
	move.b	FPSR_CC(a6),L_SCR1(a6)
 	bsr.l	ovf_r_x3	;returns a0 pointing to result
	move.b	L_SCR1(a6),FPSR_CC(a6)
	bra.l	store		;stores to memory or register
	
.not_opc011:
	bsr.l	ovf_r_x2	;returns a0 pointing to result
	bra.l	store		;stores to memory or register

	;end
;
;	x_snan.sa 3.3 7/1/91
;
; fpsp_snan --- FPSP handler for signalling NAN exception
;
; SNAN for float -> integer conversions (integer conversion of
; an SNAN) is a non-maskable run-time exception.
;
; For trap disabled the 040 does the following:
; If the dest data format is s, d, or x, then the SNAN bit in the NAN
; is set to one and the resulting non-signaling NAN (truncated if
; necessary) is transferred to the dest.  If the dest format is b, w,
; or l, then garbage is written to the dest (actually the upper 32 bits
; of the mantissa are sent to the integer unit).
;
; For trap enabled the 040 does the following:
; If the inst is move_out, then the results are the same as for trap 
; disabled with the exception posted.  If the instruction is not move_
; out, the dest. is not modified, and the exception is posted.
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

X_SNAN:	;idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	

	;xref	get_fline
	;xref	mem_write
	;xref	real_snan
	;xref	real_inex
	;xref	fpsp_done
	;xref	reg_dest

	;|.global	fpsp_snan
fpsp_snan:
	link		a6,#-LOCAL_SIZE
	fsave		-(a7)
	movem.l		d0-d1/a0-a1,USER_DA(a6)
	fmovem.x	fp0-fp3,USER_FP0(a6)
	fmovem.l	fpcr/fpsr/fpiar,USER_FPCR(a6)

;
; Check if trap enabled
;
	btst.b		#snan_bit,FPCR_ENABLE(a6)
	bne.s		ena		;If enabled, then branch

	bsr.l		move_out	;else SNAN disabled
;
; It is possible to have an inex1 exception with the
; snan.  If the inex enable bit is set in the FPCR, and either
; inex2 or inex1 occurred, we must clean up and branch to the
; real inex handler.
;
.ck_inex:
	move.b	FPCR_ENABLE(a6),d0
	and.b	FPSR_EXCEPT(a6),d0
	andi.b	#$3,d0
	beq	end_snan
;
; Inexact enabled and reported, and we must take an inexact exception.
;
.take_inex:
	move.b		#INEX_VEC,EXC_VEC+1(a6)
	movem.l		USER_DA(a6),d0-d1/a0-a1
	fmovem.x	USER_FP0(a6),fp0-fp3
	fmovem.l	USER_FPCR(a6),fpcr/fpsr/fpiar
	frestore	(a7)+
	unlk		a6
	bra.l		real_inex
;
; SNAN is enabled.  Check if inst is move_out.
; Make any corrections to the 040 output as necessary.
;
ena:
	btst.b		#5,CMDREG1B(a6) ;if set, inst is move out
	beq		not_out

	bsr.l		move_out

report_snan:
	move.b		(a7),VER_TMP(a6)
	cmpi.b		#VER_40,(a7)	;test for orig unimp frame
	bne.s		.ck_rev
	moveq.l		#13,d0		;need to zero 14 lwords
	bra.s		rep_con
.ck_rev:
	moveq.l		#11,d0		;need to zero 12 lwords
rep_con:
	clr.l		(a7)
loop1:
	clr.l		-(a7)		;clear and dec a7
	dbra		d0,loop1
	move.b		VER_TMP(a6),(a7) ;format a busy frame
	move.b		#BUSY_SIZE-4,1(a7)
	move.l		USER_FPSR(a6),FPSR_SHADOW(a6)
	or.l		#sx_mask,E_BYTE(a6)
	movem.l		USER_DA(a6),d0-d1/a0-a1
	fmovem.x	USER_FP0(a6),fp0-fp3
	fmovem.l	USER_FPCR(a6),fpcr/fpsr/fpiar
	frestore	(a7)+
	unlk		a6
	bra.l		real_snan
;
; Exit snan handler by expanding the unimp frame into a busy frame
;
end_snan:
	bclr.b		#E1,E_BYTE(a6)

	move.b		(a7),VER_TMP(a6)
	cmpi.b		#VER_40,(a7)	;test for orig unimp frame
	bne.s		ck_rev2
	moveq.l		#13,d0		;need to zero 14 lwords
	bra.s		rep_con2
ck_rev2:
	moveq.l		#11,d0		;need to zero 12 lwords
rep_con2:
	clr.l		(a7)
loop2:
	clr.l		-(a7)		;clear and dec a7
	dbra		d0,loop2
	move.b		VER_TMP(a6),(a7) ;format a busy frame
	move.b		#BUSY_SIZE-4,1(a7) ;write busy size
	move.l		USER_FPSR(a6),FPSR_SHADOW(a6)
	or.l		#sx_mask,E_BYTE(a6)
	movem.l		USER_DA(a6),d0-d1/a0-a1
	fmovem.x	USER_FP0(a6),fp0-fp3
	fmovem.l	USER_FPCR(a6),fpcr/fpsr/fpiar
	frestore	(a7)+
	unlk		a6
	bra.l		fpsp_done

;
; Move_out 
;
move_out:
	move.l		EXC_EA(a6),a0	;get <ea> from exc frame

	bfextu		CMDREG1B(a6){3:3},d0 ;move rx field to d0{2:0}
	cmpi.l		#0,d0		;check for long
	beq.s		sto_long	;branch if move_out long
	
	cmpi.l		#4,d0		;check for word
	beq.s		sto_word	;branch if move_out word
	
	cmpi.l		#6,d0		;check for byte
	beq.s		sto_byte	;branch if move_out byte
	
;
; Not byte, word or long
;
	rts
;	
; Get the 32 most significant bits of etemp mantissa
;
sto_long:
	move.l		ETEMP_HI(a6),d1
	move.l		#4,d0		;load byte count
;
; Set signalling nan bit
;
	bset.l		#30,d1			
;
; Store to the users destination address
;
	tst.l		a0		;check if <ea> is 0
	beq.s		wrt_dn		;destination is a data register
	
	move.l		d1,-(a7)	;move the snan onto the stack
	move.l		a0,a1		;load dest addr into a1
	move.l		a7,a0		;load src addr of snan into a0
	bsr.l		mem_write	;write snan to user memory
	move.l		(a7)+,d1	;clear off stack
	rts
;
; Get the 16 most significant bits of etemp mantissa
;
sto_word:
	move.l		ETEMP_HI(a6),d1
	move.l		#2,d0		;load byte count
;
; Set signalling nan bit
;
	bset.l		#30,d1			
;
; Store to the users destination address
;
	tst.l		a0		;check if <ea> is 0
	beq.s		wrt_dn		;destination is a data register

	move.l		d1,-(a7)	;move the snan onto the stack
	move.l		a0,a1		;load dest addr into a1
	move.l		a7,a0		;point to low word
	bsr.l		mem_write	;write snan to user memory
	move.l		(a7)+,d1	;clear off stack
	rts
;
; Get the 8 most significant bits of etemp mantissa
;
sto_byte:
	move.l		ETEMP_HI(a6),d1
	move.l		#1,d0		;load byte count
;
; Set signalling nan bit
;
	bset.l		#30,d1			
;
; Store to the users destination address
;
	tst.l		a0		;check if <ea> is 0
	beq.s		wrt_dn		;destination is a data register
	move.l		d1,-(a7)	;move the snan onto the stack
	move.l		a0,a1		;load dest addr into a1
	move.l		a7,a0		;point to source byte
	bsr.l		mem_write	;write snan to user memory
	move.l		(a7)+,d1	;clear off stack
	rts

;
;	wrt_dn --- write to a data register
;
;	We get here with D1 containing the data to write and D0 the
;	number of bytes to write: 1=byte,2=word,4=long.
;
wrt_dn:
	move.l		d1,L_SCR1(a6)	;data
	move.l		d0,-(a7)	;size
	bsr.l		get_fline	;returns fline word in d0
	move.l		d0,d1
	andi.l		#$7,d1		;d1 now holds register number
	move.l		(sp)+,d0	;get original size
	cmpi.l		#4,d0
	beq.s		wrt_long
	cmpi.l		#2,d0
	bne.s		wrt_byte
wrt_word:
	or.l		#$8,d1
	bra.l		reg_dest
wrt_long:
	or.l		#$10,d1
	bra.l		reg_dest
wrt_byte:
	bra.l		reg_dest
;
; Check if it is a src nan or dst nan
;
not_out:
	move.l		DTAG(a6),d0	
	bfextu		d0{0:3},d0	;isolate dtag in lsbs

	cmpi.b		#3,d0		;check for nan in destination
	bne.s		.issrc		;destination nan has priority
;dst_nan:
	btst.b		#6,FPTEMP_HI(a6) ;check if dest nan is an snan
	bne.s		.issrc		;no, so check source for snan
	move.w		FPTEMP_EX(a6),d0
	bra.s		.cont
.issrc:
	move.w		ETEMP_EX(a6),d0
.cont:
	btst.l		#15,d0		;test for sign of snan
	beq.s		.clr_neg
	bset.b		#neg_bit,FPSR_CC(a6)
	bra		report_snan
.clr_neg:
	bclr.b		#neg_bit,FPSR_CC(a6)
	bra		report_snan

	;end
;
;	x_store.sa 3.2 1/24/91
;
;	store --- store operand to memory or register
;
;	Used by underflow and overflow handlers.
;
;	a6 = points to fp value to be stored.
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

X_STORE:	;idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section	8

fpreg_mask:
	dc.b	$80,$40,$20,$10,$08,$04,$02,$01

	

	;xref	mem_write
	;xref	get_fline
	;xref	g_opcls
	;xref	g_dfmtou
	;xref	reg_dest

	;|.global	dest_ext
	;|.global	dest_dbl
	;|.global	dest_sgl

	;|.global	store
store:
	btst.b	#E3,E_BYTE(a6)
	beq.s	E1_sto
E3_sto:
	move.l	CMDREG3B(a6),d0
	bfextu	d0{6:3},d0		;isolate dest. reg from cmdreg3b
sto_fp:
	lea	fpreg_mask(pc),a1
	move.b	(a1,d0.w),d0		;convert reg# to dynamic register mask
	tst.b	LOCAL_SGN(a0)
	beq.s	is_pos
	bset.b	#sign_bit,LOCAL_EX(a0)
is_pos:
	fmovem.x (a0),d0		;move to correct register
;
;	if fp0-fp3 is being modified, we must put a copy
;	in the USER_FPn variable on the stack because all exception
;	handlers restore fp0-fp3 from there.
;
	cmp.b	#$80,d0		
	bne.s	not_fp0
	fmovem.x fp0-fp0,USER_FP0(a6)
	rts
not_fp0:
	cmp.b	#$40,d0
	bne.s	not_fp1
	fmovem.x fp1-fp1,USER_FP1(a6)
	rts
not_fp1:
	cmp.b	#$20,d0
	bne.s	not_fp2
	fmovem.x fp2-fp2,USER_FP2(a6)
	rts
not_fp2:
	cmp.b	#$10,d0
	bne.s	not_fp3
	fmovem.x fp3-fp3,USER_FP3(a6)
	rts
not_fp3:
	rts

E1_sto:
	bsr.l	g_opcls		;returns opclass in d0
	cmpi.b	#3,d0
	beq	.opc011		;branch if opclass 3
	move.l	CMDREG1B(a6),d0
	bfextu	d0{6:3},d0	;extract destination register
	bra.s	sto_fp

.opc011:
	bsr.l	g_dfmtou	;returns dest format in d0
;				;ext=00, sgl=01, dbl=10
	move.l	a0,a1		;save source addr in a1
	move.l	EXC_EA(a6),a0	;get the address
	cmpi.l	#0,d0		;if dest format is extended
	beq	dest_ext	;then branch
	cmpi.l	#1,d0		;if dest format is single
	beq.s	dest_sgl	;then branch
;
;	fall through to dest_dbl
;

;
;	dest_dbl --- write double precision value to user space
;
;Input
;	a0 -> destination address
;	a1 -> source in extended precision
;Output
;	a0 -> destroyed
;	a1 -> destroyed
;	d0 -> 0
;
;Changes extended precision to double precision.
; Note: no attempt is made to round the extended value to double.
;	dbl_sign = ext_sign
;	dbl_exp = ext_exp - $3fff(ext bias) + $7ff(dbl bias)
;	get rid of ext integer bit
;	dbl_mant = ext_mant{62:12}
;
;	    	---------------   ---------------    ---------------
;  extended ->  |s;    exp    ;   |1; ms mant   ;    ; ls mant     ; ;	    	---------------   ---------------    ---------------
;	   	 95	    64    63 62	      32      31     11	  0
;				     ; 		     ; ;				     ; 		     ; ;				     ; 		     ; ;		 	             v   		     v
;	    		      ---------------   ---------------
;  double   ->  	      |s|exp; mant  ;   ;  mant       ; ;	    		      ---------------   ---------------
;	   	 	      63     51   32   31	       0
;
dest_dbl:
	clr.l	d0		;clear d0
	move.w	LOCAL_EX(a1),d0	;get exponent
	sub.w	#$3fff,d0	;subtract extended precision bias
	cmp.w	#$4000,d0	;check if inf
	beq.s	inf		;if so, special case
	add.w	#$3ff,d0	;add double precision bias
	swap	d0		;d0 now in upper word
	lsl.l	#4,d0		;d0 now in proper place for dbl prec exp
	tst.b	LOCAL_SGN(a1)	
	beq.s	get_mant	;if positive, go process mantissa
	bset.l	#31,d0		;if negative, put in sign information
;				; before continuing
	bra.s	get_mant	;go process mantissa
inf:
	move.l	#$7ff00000,d0	;load dbl inf exponent
	clr.l	LOCAL_HI(a1)	;clear msb
	tst.b	LOCAL_SGN(a1)
	beq.s	dbl_inf		;if positive, go ahead and write it
	bset.l	#31,d0		;if negative put in sign information
dbl_inf:
	move.l	d0,LOCAL_EX(a1)	;put the new exp back on the stack
	bra.s	dbl_wrt
get_mant:
	move.l	LOCAL_HI(a1),d1	;get ms mantissa
	bfextu	d1{1:20},d1	;get upper 20 bits of ms
	or.l	d1,d0		;put these bits in ms word of double
	move.l	d0,LOCAL_EX(a1)	;put the new exp back on the stack
	move.l	LOCAL_HI(a1),d1	;get ms mantissa
	move.l	#21,d0		;load shift count
	lsl.l	d0,d1		;put lower 11 bits in upper bits
	move.l	d1,LOCAL_HI(a1)	;build lower lword in memory
	move.l	LOCAL_LO(a1),d1	;get ls mantissa
	bfextu	d1{0:21},d0	;get ls 21 bits of double
	or.l	d0,LOCAL_HI(a1)	;put them in double result
dbl_wrt:
	move.l	#$8,d0		;byte count for double precision number
	exg	a0,a1		;a0=supervisor source, a1=user dest
	bsr.l	mem_write	;move the number to the user's memory
	rts
;
;	dest_sgl --- write single precision value to user space
;
;Input
;	a0 -> destination address
;	a1 -> source in extended precision
;
;Output
;	a0 -> destroyed
;	a1 -> destroyed
;	d0 -> 0
;
;Changes extended precision to single precision.
;	sgl_sign = ext_sign
;	sgl_exp = ext_exp - $3fff(ext bias) + $7f(sgl bias)
;	get rid of ext integer bit
;	sgl_mant = ext_mant{62:12}
;
;	    	---------------   ---------------    ---------------
;  extended ->  |s;    exp    ;   |1; ms mant   ;    ; ls mant     ; ;	    	---------------   ---------------    ---------------
;	   	 95	    64    63 62	   40 32      31     12	  0
;				     ;    ; ;				     ;    ; ;				     ;    ; ;		 	             v     v
;	    		      ---------------
;  single   ->  	      |s|exp; mant  ; ;	    		      ---------------
;	   	 	      31     22     0
;
dest_sgl:
	clr.l	d0
	move.w	LOCAL_EX(a1),d0	;get exponent
	sub.w	#$3fff,d0	;subtract extended precision bias
	cmp.w	#$4000,d0	;check if inf
	beq.s	.sinf		;if so, special case
	add.w	#$7f,d0		;add single precision bias
	swap	d0		;put exp in upper word of d0
	lsl.l	#7,d0		;shift it into single exp bits
	tst.b	LOCAL_SGN(a1)	
	beq.s	get_sman	;if positive, continue
	bset.l	#31,d0		;if negative, put in sign first
	bra.s	get_sman	;get mantissa
.sinf:
	move.l	#$7f800000,d0	;load single inf exp to d0
	tst.b	LOCAL_SGN(a1)
	beq.s	sgl_wrt		;if positive, continue
	bset.l	#31,d0		;if negative, put in sign info
	bra.s	sgl_wrt

get_sman:
	move.l	LOCAL_HI(a1),d1	;get ms mantissa
	bfextu	d1{1:23},d1	;get upper 23 bits of ms
	or.l	d1,d0		;put these bits in ms word of single

sgl_wrt:
	move.l	d0,L_SCR1(a6)	;put the new exp back on the stack
	move.l	#$4,d0		;byte count for single precision number
	tst.l	a0		;users destination address
	beq.s	sgl_Dn		;destination is a data register
	exg	a0,a1		;a0=supervisor source, a1=user dest
	lea.l	L_SCR1(a6),a0	;point a0 to data
	bsr.l	mem_write	;move the number to the user's memory
	rts
sgl_Dn:
	bsr.l	get_fline	;returns fline word in d0
	and.w	#$7,d0		;isolate register number
	move.l	d0,d1		;d1 has size:reg formatted for reg_dest
	or.l	#$10,d1		;reg_dest wants size added to reg#
	bra.l	reg_dest	;size is X, rts in reg_dest will
;				;return to caller of dest_sgl
	
dest_ext:
	tst.b	LOCAL_SGN(a1)	;put back sign into exponent word
	beq.s	dstx_cont
	bset.b	#sign_bit,LOCAL_EX(a1)
dstx_cont:
	clr.b	LOCAL_SGN(a1)	;clear out the sign byte

	move.l	#$0c,d0		;byte count for extended number
	exg	a0,a1		;a0=supervisor source, a1=user dest
	bsr.l	mem_write	;move the number to the user's memory
	rts

	;end
;
;	x_unfl.sa 3.4 7/1/91
;
;	fpsp_unfl --- FPSP handler for underflow exception
;
; Trap disabled results
;	For 881/2 compatibility, sw must denormalize the intermediate 
; result, then store the result.  Denormalization is accomplished 
; by taking the intermediate result (which is always normalized) and 
; shifting the mantissa right while incrementing the exponent until 
; it is equal to the denormalized exponent for the destination 
; format.  After denormalization, the result is rounded to the 
; destination format.
;		
; Trap enabled results
; 	All trap disabled code applies.	In addition the exceptional 
; operand needs to made available to the user with a bias of $6000 
; added to the exponent.
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

X_UNFL:	;idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	

	;xref	denorm
	;xref	round
	;xref	store
	;xref	g_rndpr
	;xref	g_opcls
	;xref	g_dfmtou
	;xref	real_unfl
	;xref	real_inex
	;xref	fpsp_done
	;xref	b1238_fix

	;|.global	fpsp_unfl
fpsp_unfl:
	link		a6,#-LOCAL_SIZE
	fsave		-(a7)
	movem.l		d0-d1/a0-a1,USER_DA(a6)
	fmovem.x	fp0-fp3,USER_FP0(a6)
	fmovem.l	fpcr/fpsr/fpiar,USER_FPCR(a6)

;
	bsr.l		unf_res	;denormalize, round & store interm op
;
; If underflow exceptions are not enabled, check for inexact
; exception
;
	btst.b		#unfl_bit,FPCR_ENABLE(a6)
	beq.s		ck_inex

	btst.b		#E3,E_BYTE(a6)
	beq.s		no_e3_1
;
; Clear dirty bit on dest resister in the frame before branching
; to b1238_fix.
;
	bfextu		CMDREG3B(a6){6:3},d0	;get dest reg no
	bclr.b		d0,FPR_DIRTY_BITS(a6)	;clr dest dirty bit
	bsr.l		b1238_fix		;test for bug1238 case
	move.l		USER_FPSR(a6),FPSR_SHADOW(a6)
	or.l		#sx_mask,E_BYTE(a6)
no_e3_1:
	movem.l		USER_DA(a6),d0-d1/a0-a1
	fmovem.x	USER_FP0(a6),fp0-fp3
	fmovem.l	USER_FPCR(a6),fpcr/fpsr/fpiar
	frestore	(a7)+
	unlk		a6
	bra.l		real_unfl
;
; It is possible to have either inex2 or inex1 exceptions with the
; unfl.  If the inex enable bit is set in the FPCR, and either
; inex2 or inex1 occurred, we must clean up and branch to the
; real inex handler.
;
ck_inex:
	move.b		FPCR_ENABLE(a6),d0
	and.b		FPSR_EXCEPT(a6),d0
	andi.b		#$3,d0
	beq.s		unfl_done

;
; Inexact enabled and reported, and we must take an inexact exception
;	
.take_inex:
	btst.b		#E3,E_BYTE(a6)
	beq.s		no_e3_2
;
; Clear dirty bit on dest resister in the frame before branching
; to b1238_fix.
;
	bfextu		CMDREG3B(a6){6:3},d0	;get dest reg no
	bclr.b		d0,FPR_DIRTY_BITS(a6)	;clr dest dirty bit
	bsr.l		b1238_fix		;test for bug1238 case
	move.l		USER_FPSR(a6),FPSR_SHADOW(a6)
	or.l		#sx_mask,E_BYTE(a6)
no_e3_2:
	move.b		#INEX_VEC,EXC_VEC+1(a6)
	movem.l         USER_DA(a6),d0-d1/a0-a1
	fmovem.x        USER_FP0(a6),fp0-fp3
	fmovem.l        USER_FPCR(a6),fpcr/fpsr/fpiar
	frestore        (a7)+
	unlk            a6
	bra.l		real_inex

unfl_done:
	bclr.b		#E3,E_BYTE(a6)
	beq.s		.e1_set		;if set then branch
;
; Clear dirty bit on dest resister in the frame before branching
; to b1238_fix.
;
	bfextu		CMDREG3B(a6){6:3},d0		;get dest reg no
	bclr.b		d0,FPR_DIRTY_BITS(a6)	;clr dest dirty bit
	bsr.l		b1238_fix		;test for bug1238 case
	move.l		USER_FPSR(a6),FPSR_SHADOW(a6)
	or.l		#sx_mask,E_BYTE(a6)
	movem.l		USER_DA(a6),d0-d1/a0-a1
	fmovem.x	USER_FP0(a6),fp0-fp3
	fmovem.l	USER_FPCR(a6),fpcr/fpsr/fpiar
	frestore	(a7)+
	unlk		a6
	bra.l		fpsp_done
.e1_set:
	movem.l		USER_DA(a6),d0-d1/a0-a1
	fmovem.x	USER_FP0(a6),fp0-fp3
	fmovem.l	USER_FPCR(a6),fpcr/fpsr/fpiar
	unlk		a6
	bra.l		fpsp_done
;
;	unf_res --- underflow result calculation
;
unf_res:
	bsr.l		g_rndpr		;returns RND_PREC in d0 0=ext,
;					;1=sgl, 2=dbl
;					;we need the RND_PREC in the
;					;upper word for round
	move.w		#0,-(a7)	
	move.w		d0,-(a7)	;copy RND_PREC to stack
;
;
; If the exception bit set is E3, the exceptional operand from the
; fpu is in WBTEMP; else it is in FPTEMP.
;
	btst.b		#E3,E_BYTE(a6)
	beq.s		unf_E1
unf_E3:
	lea		WBTEMP(a6),a0	;a0 now points to operand
;
; Test for fsgldiv and fsglmul.  If the inst was one of these, then
; force the precision to extended for the denorm routine.  Use
; the user's precision for the round routine.
;
	move.w		CMDREG3B(a6),d1	;check for fsgldiv or fsglmul
	andi.w		#$7f,d1
	cmpi.w		#$30,d1		;check for sgldiv
	beq.s		unf_sgl
	cmpi.w		#$33,d1		;check for sglmul
	bne.s		unf_cont	;if not, use fpcr prec in round
unf_sgl:
	clr.l		d0
	move.w		#$1,(a7)	;override g_rndpr precision
;					;force single
	bra.s		unf_cont
unf_E1:
	lea		FPTEMP(a6),a0	;a0 now points to operand
unf_cont:
	bclr.b		#sign_bit,LOCAL_EX(a0)	;clear sign bit
	sne		LOCAL_SGN(a0)		;store sign

	bsr.l		denorm		;returns denorm, a0 points to it
;
; WARNING:
;				;d0 has guard,round sticky bit
;				;make sure that it is not corrupted
;				;before it reaches the round subroutine
;				;also ensure that a0 isn't corrupted

;
; Set up d1 for round subroutine d1 contains the PREC/MODE
; information respectively on upper/lower register halves.
;
	bfextu		FPCR_MODE(a6){2:2},d1	;get mode from FPCR
;						;mode in lower d1
	add.l		(a7)+,d1		;merge PREC/MODE
;
; WARNING: a0 and d0 are assumed to be intact between the denorm and
; round subroutines. All code between these two subroutines
; must not corrupt a0 and d0.
;
;
; Perform Round	
;	Input:		a0 points to input operand
;			d0{31:29} has guard, round, sticky
;			d1{01:00} has rounding mode
;			d1{17:16} has rounding precision
;	Output:		a0 points to rounded operand
;

	bsr.l		round		;returns rounded denorm at (a0)
;
; Differentiate between store to memory vs. store to register
;
unf_store:
	bsr.l		g_opcls		;returns opclass in d0{2:0}
	cmpi.b		#$3,d0
	bne.s		not_opc011
;
; At this point, a store to memory is pending
;
.opc011:
	bsr.l		g_dfmtou
	tst.b		d0
	beq.s		ext_opc011	;If extended, do not subtract
; 				;If destination format is sgl/dbl, 
	tst.b		LOCAL_HI(a0)	;If rounded result is normal,don't
;					;subtract
	bmi.s		ext_opc011
	subq.w		#1,LOCAL_EX(a0)	;account for denorm bias vs.
;				;normalized bias
;				;          normalized   denormalized
;				;single       $7f           $7e
;				;double       $3ff          $3fe
;
ext_opc011:
	bsr.l		store		;stores to memory
	bra.s		unf_done	;finish up

;
; At this point, a store to a float register is pending
;
not_opc011:
	bsr.l		store	;stores to float register
;				;a0 is not corrupted on a store to a
;				;float register.
;
; Set the condition codes according to result
;
	tst.l		LOCAL_HI(a0)	;check upper mantissa
	bne.s		ck_sgn
	tst.l		LOCAL_LO(a0)	;check lower mantissa
	bne.s		ck_sgn
	bset.b		#z_bit,FPSR_CC(a6) ;set condition codes if zero
ck_sgn:
	btst.b 		#sign_bit,LOCAL_EX(a0)	;check the sign bit
	beq.s		unf_done
	bset.b		#neg_bit,FPSR_CC(a6)

;
; Finish.  
;
unf_done:
	btst.b		#inex2_bit,FPSR_EXCEPT(a6)
	beq.s		no_aunfl
	bset.b		#aunfl_bit,FPSR_AEXCEPT(a6)
no_aunfl:
	rts

	;end
;
;	x_unimp.sa 3.3 7/1/91
;
;	fpsp_unimp --- FPSP handler for unimplemented instruction	
;	exception.
;
; Invoked when the user program encounters a floating-point
; op-code that hardware does not support.  Trap vector# 11
; (See table 8-1 MC68030 User's Manual).
;
; 
; Note: An fsave for an unimplemented inst. will create a short
; fsave stack.
;
;  Input: 1. Six word stack frame for unimplemented inst, four word
;            for illegal
;            (See table 8-7 MC68030 User's Manual).
;         2. Unimp (short) fsave state frame created here by fsave
;            instruction.
;
;
;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

X_UNIMP:	;idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	

	;xref	get_op
	;xref	do_func
	;xref	sto_res
	;xref	gen_except
	;xref	fpsp_fmt_error

	;|.global	fpsp_unimp
	;|.global	uni_2
fpsp_unimp:
	link		a6,#-LOCAL_SIZE
	fsave		-(a7)
uni_2:
	movem.l		d0-d1/a0-a1,USER_DA(a6)
	fmovem.x	fp0-fp3,USER_FP0(a6)
	fmovem.l	fpcr/fpsr/fpiar,USER_FPCR(a6)
	move.b		(a7),d0		;test for valid version num
	andi.b		#$f0,d0		;test for $4x
	cmpi.b		#VER_4,d0	;must be $4x or exit
	bne.l		fpsp_fmt_error
;
;	Temporary D25B Fix
;	The following lines are used to ensure that the FPSR
;	exception byte and condition codes are clear before proceeding
;
	move.l		USER_FPSR(a6),d0
	and.l		#$FF00FF,d0	;clear all but accrued exceptions
	move.l		d0,USER_FPSR(a6)
	fmove.l		#0,FPSR ;clear all user bits
	fmove.l		#0,FPCR	;clear all user exceptions for FPSP

	clr.b		UFLG_TMP(a6)	;clr flag for unsupp data

	bsr.l		get_op		;go get operand(s)
	clr.b		STORE_FLG(a6)
	bsr.l		do_func		;do the function
	fsave		-(a7)		;capture possible exc state
	tst.b		STORE_FLG(a6)
	bne.s		no_store	;if STORE_FLG is set, no store
	bsr.l		sto_res		;store the result in user space
no_store:
	bra.l		gen_except	;post any exceptions and return

	;end
;
;	x_unsupp.sa 3.3 7/1/91
;
;	fpsp_unsupp --- FPSP handler for unsupported data type exception
;
; Trap vector #55	(See table 8-1 Mc68030 User's manual).	
; Invoked when the user program encounters a data format (packed) that
; hardware does not support or a data type (denormalized numbers or un-
; normalized numbers).
; Normalizes denorms and unnorms, unpacks packed numbers then stores 
; them back into the machine to let the 040 finish the operation.  
;
; Unsupp calls two routines:
; 	1. get_op -  gets the operand(s)
; 	2. res_func - restore the function back into the 040 or
; 			if fmove.p fpm,<ea> then pack source (fpm)
; 			and store in users memory <ea>.
;
;  Input: Long fsave stack frame
;
;

;		Copyright (C) Motorola, Inc. 1990
;			All Rights Reserved
;
;	THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF MOTOROLA 
;	The copyright notice above does not evidence any  
;	actual or intended publication of such source code.

X_UNSUPP:	;idnt    2,1 ; Motorola 040 Floating Point Software Package

	;section	8

	

	;xref	get_op
	;xref	res_func
	;xref	gen_except
	;xref	fpsp_fmt_error

	;|.global	fpsp_unsupp
fpsp_unsupp:
;
	link		a6,#-LOCAL_SIZE
	fsave		-(a7)
	movem.l		d0-d1/a0-a1,USER_DA(a6)
	fmovem.x	fp0-fp3,USER_FP0(a6)
	fmovem.l	fpcr/fpsr/fpiar,USER_FPCR(a6)


	move.b		(a7),VER_TMP(a6) ;save version number
	move.b		(a7),d0		;test for valid version num
	andi.b		#$f0,d0		;test for $4x
	cmpi.b		#VER_4,d0	;must be $4x or exit
	bne.l		fpsp_fmt_error

	fmove.l		#0,FPSR		;clear all user status bits
	fmove.l		#0,FPCR		;clear all user control bits
;
;	The following lines are used to ensure that the FPSR
;	exception byte and condition codes are clear before proceeding,
;	except in the case of fmove, which leaves the cc's intact.
;
unsupp_con:
	move.l		USER_FPSR(a6),d1
	btst		#5,CMDREG1B(a6)	;looking for fmove out
	bne		.fmove_con
	and.l		#$FF00FF,d1	;clear all but aexcs and qbyte
	bra.s		.end_fix
.fmove_con:
	and.l		#$0FFF40FF,d1	;clear all but cc's, snan bit, aexcs, and qbyte
.end_fix:
	move.l		d1,USER_FPSR(a6)

	st		UFLG_TMP(a6)	;set flag for unsupp data

	bsr.l		get_op		;everything okay, go get operand(s)
	bsr.l		res_func	;fix up stack frame so can restore it
	clr.l		-(a7)
	move.b		VER_TMP(a6),(a7) ;move idle fmt word to top of stack
	bra.l		gen_except
;
	;end
