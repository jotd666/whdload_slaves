; V1.1 to 1.2 Dark Angel
; V1.3 Updated by CFou! on 13.03.05 (another version supported)
    IFD	BARFLY
        OUTPUT  dh2:ParasolStars/ParasolStars.slave
;        OPT     O+ OG+                  ;enable optimizing
	ENDC
	
   INCDIR   Include:
   INCLUDE  whdload.i
   INCLUDE  whdmacros.i

CHIPMEMSIZE = $80000
FASTMEMSIZE = $0

BASEMEM=CHIPMEMSIZE
EXPMEM=FASTMEMSIZE

dec1=$1e4
dec2=$102
dec3=$2c8

; adapt 2nd player
; adapt 2nd version
; levelskip avec joypad


;_ExtractFiles  ; set it to extract files
;_DecompFiles

_base
    SLAVE_HEADER           ;ws_Security + ws_ID
      dc.w  17             ;ws_Version
      dc.w  WHDLF_NoError|WHDLF_EmulTrap ;|WHDLF_EmulTrap|WHDLF_NoKbd  ;ws_flags
      dc.l  BASEMEM        ;ws_BaseMemSize
      dc.l  0              ;ws_ExecInstall
      dc.w  _start-_base      ;ws_GameLoader
      dc.w  _data-_base    ;ws_CurrentDir
      dc.w  0              ;ws_DontCache
_keydebug
      dc.b  $5f            ;ws_keydebug
_keyexit
      dc.b  $5d            ;ws_keyexit = *
_expmem
      dc.l  EXPMEM         ;ws_ExpMem
      dc.w  _name-_base    ;ws_name
      dc.w  _copy-_base    ;ws_copy
      dc.w  _info-_base    ;ws_info
    dc.w    0     ; kickstart name
    dc.l    $0         ; kicksize
    dc.w    $0         ; kickcrc
    dc.w    _config-_base
;============================================================================

   IFD BARFLY
   DOSCMD   "WDate  >T:date"
   ENDC
DECL_VERSION:MACRO
	dc.b	"1.5"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
_data    dc.b  0
_name    dc.b  "Parasol Stars",0
_copy    dc.b  "1992 Ocean",0
_info    dc.b  "Adapted by Dark Angel, CFou! & JOTD",10
      dc.b  "Version "
	  DECL_VERSION
      dc.b  0
	  
_config
	dc.b    "C1:X:F1 or fwd+green skips levels:0;"
	dc.b    "C1:X:trainer:1;"
	dc.b    "C2:X:second button jumps player 1:0;"
	dc.b    "C2:X:second button jumps player 2:1;"
	dc.b	0
;====================================================================== 
 even
IGNORE_JOY_DIRECTIONS
 	INCLUDE ReadJoyPad.s

;====================================================================== 
_start   ;       A0 = resident loader
;====================================================================== 
		lea     _resload(pc),a1
		move.l  a0,(a1)

		lea     tags(pc),a0
		move.l  _resload(pc),a6
		jsr     resload_Control(a6)
		bsr _install_cbswitch
		
		bsr	_detect_controller_types

		move.l  #22*512,d0
		move.l  #276*512,d1
		moveq   #1,d2
		lea     $10000,a0
		move.l  a0,a5
		move.l  _resload(pc),a6
		jsr     resload_DiskLoad(a6)

		move.l  a5,a0
		move.l  #276*512,d0
		jsr     resload_CRC16(a6)
		lea version(pc),a6
		move.l #1,(a6)
		cmp.w   #$87e2,d0 ;v1
		beq     .ok
		cmp.w   #$8de2,d0 ; v2
		bne     Unsupported
		move.l #2,(a6)
		; version 2 has a lot of variables shifted by 2 bytes
		lea _c1(pc),a6
		sub.l #2,(a6)     ; set good copperlist adress if os swap
		lea _ktable(pc),a6
		sub.l #2,(a6)     ; keyboard table
		lea _scores_address(pc),a6
		sub.l #2,(a6)     ; address of hiscores
		lea _scores_offset(pc),a6
		sub.l #2,(a6)     ; address of hiscores
.ok
		patch   $1001e,Trace
		
		bsr   _flushcaches
		lea     $10000,a6
		jmp     (a6)

Trace           lea     $a000,a7
		add.l   10(a6),a6

		lea     trcadr(pc),a4
		move.l  (a4),a3
		move.l  a3,-(sp)
.tlp            addq.l  #2,a3

		cmp.l   #$1b5d6,a3
		beq.b   .over

		cmp.l   #$46fc2700,(a3)
		bne.b   .tlp
		cmp.l   #$ddee000a,4(a3)
		bne.b   .tlp

		move.l  a3,(a4)

		move    #$4ef9,(a3)+
		lea     Trace(pc),a4
		move.l  a4,(a3)

		move.l  (sp)+,a3
		bsr.w   _flushcaches
		jmp     8(a3)

.over           patch   $1b5d6,.part1
		bsr.w   _flushcaches

		move.l d0,-(a7)
		move.l version(pc),d0
		cmp.l #2,d0
		beq .v2_
.v1_
		move.w  #$4e75,$3157e           ;cacr
		bra .commun_
.v2_
		move.w  #$4e75,$312b6           ;cacr
.commun_
		move.l (a7)+,d0
		bsr.w   _flushcaches
		jmp     $1b5a6


.part1
		move.l d0,-(a7)
		move.l version(pc),d0
		cmp.l #2,d0
		beq .v2
.v1
		patch   $40978,.part2
		bra .commun
.v2
		patch   $40978-2,.part2
.commun
		move.l (a7)+,d0
		bsr.w   _flushcaches

		jmp     $40000

.part2          
.trans          move.b  (a0)+,(a1)+
		subq.l  #1,d0
		bne.b   .trans
		movem.l d0,-(a7)
		move.l version(pc),d0
		cmp.l #2,d0
		movem.l (a7)+,d0
		beq _V2
_V1
	bsr.w   load_score


	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	sub.l	a1,a1
	lea	.pl_version1(pc),a0
	jsr	(resload_Patch,a2)
	movem.l	(a7)+,d0-d1/a0-a2
	
	jmp     (a6)

.pl_version1:
	PL_START
	; trainer
	PL_IFC1X	1
	PL_W	$16b2c+dec3,$6030
	PL_R	$16b66+dec3
	PL_ENDIF

	PL_IFC2X	0
	PL_PSS	$1BB2,_read_joypads_button_jump,2
	PL_ELSE
	PL_PSS	$1BB2,_read_joypads_up_jump,2
	PL_ENDIF
	PL_IFC2X	1
	PL_PSS	$1A4A,_read_joypads_button_jump_p2,2
	PL_ENDIF
	
	PL_R	$6726                    ; no ext. mem

	PL_P   $8be0,.rn1
	PL_P   $9fec,.rn2
	PL_PS  $ef90,.rn31                     ; hook encoded rn

	PL_L  	$1b90,$4e717000           ; kill ordinary check sums
	PL_W	$8b90,$7000
	PL_W	$9602,$7000
	PL_W	$9a5e,$7000
	PL_L	$9ec2,$4e717000
	PL_W	$abc4,$7000
	PL_W	$b0e6,$7000
	PL_L	$b12c,$4e717000
	PL_W	$c350,$7000
	PL_L	$16ab4,$4e717000
	PL_L	$1701a,$4e717000
	PL_L	$170b2,$4e717000
	PL_L	$17172,$4e717000
	PL_L	$40b90,$4e717000

	PL_W	$c44a,$538e ; kill check sums [subq.l #1,a6]
	PL_W	$108a4,$538e

	PL_PS  $1404c,.cs11                    ; catch encoded check sums
	PL_PS  $1500e,.cs21
	PL_PS  $16182,.cs31
	PL_PS  $16b24,.cs41
	PL_PS  $16bc4,.cs51

	PL_PS  $10362,.dec11                   ; hook double encoded check sum
	PL_P   $17e2,_rram                   ; catch ram read
	PL_PS  $1d7a,_cia
	PL_P   $5b28,_loader
	PL_PS  $b65e,save_score

; snoop patch asked by Codetapper ;)
	PL_W	$6712,$600a
	PL_END

;--- fake rn protections

.rn1            move.l  #$4c295007,d0
                bsr.w   _flushcaches
                jmp     $951a
				
;-------------- v1
.rn2            lea     $9fec,a0
                bsr.w   .restor

                move.l  #$4c295007,d0
                move.l  d0,$60.w
                move.l  d0,$183fc
                move.l  d0,$18414
                move.l  d0,$184aa
                bsr.w   _flushcaches
                jmp     $a926
.rn31lp         bsr.w   .getov
.rn31           sub     d2,(a0)+
                dbf     d0,.rn31lp
                patch   $efc6,.rn32
                bra.w   _flushcaches

.rn32           lea     $efc6,a0
                bsr.b   .restor

                patchs  $f9d0,.rn33

                move.l  #$4c295007,d0
                bsr.w   _flushcaches
                jmp     $f900

.rn33lp         bsr.w   .getov
.rn33           add     d2,(a0)+
                dbf     d0,.rn33lp

                lea     $f9d0,a0
                move    #$d558,(a0)+
                move.l  #$51c8fffa,(a0)
                bra.w   _flushcaches

.restor         move    #$4283,(a0)+
                move.l  #$487a000a,(a0)
                bra.w   _flushcaches
;----------------- V1

.cs11           move    #$7000,$14086
                patchs  $14088,.cs12
                bra.w   _flushcaches

.cs12           lea     $14052,a0
                moveq   #25,d0
                move.w  #$9150,$14086
                move.w  #$41fa,$14088
                move.l  #$ffc87019,$1408a
                bra.w   _flushcaches

.cs21           move    #$7000,$15044

                patchs  $1504a,.cs22
                bra.w   _flushcaches

.cs22           moveq   #30,d0
                move    #$d150,$15044
                move    #$203c,$1504a
                move.l  #$0000001e,$1504c
                bra.w   _flushcaches

.cs31           move    #$7000,$161bc
                patchs  $161c2,.cs32
                bra.w   _flushcaches

.cs32           moveq   #32,d0
                move    #$9150,$161bc
                move    #$203c,$161c2
                move.l  #$00000020,$161c4
                bra.w   _flushcaches

.cs41           move    #$7000,$16b5e
                patchs  $16b6a,.cs42
                bra.w   _flushcaches

.cs42           moveq   #35,d0
                move    #$9150,$16b5e
                move    #$203c,$16b6a
                move.l  #$00000023,$16b6c
                bra.w   _flushcaches

.cs51           move.l  #$4e717000,$16c0a

                patchs  $16c2c,.cs52
                bra.w   _flushcaches

.cs52           lea     $16bca,a0
                moveq   #47,d0
                move.l  #$b16b5eec,$16c0a
                move    #$702f,$16c2c
                move.l  #$41faff9a,$16c2e
                bra.w   _flushcaches

;--- patch double encoded check sum  v1

.d11lp  bsr.w   .getov
.dec11  sub     d2,(a0)+
        dbf     d0,.d11lp
        patchs  $103a2,.dec12
        bra.w   _flushcaches
;---

.d12lp  move    (a0),d2
        eor     d1,(a0)+
.dec12  move    d2,d1
        dbf     d0,.d12lp

        move    #$3202,$103a2             ; remove .dec12 hook
        move.l  #$51c8fff8,$103a4
        move    #$7000,$10464

        patchs  $104ec,.dec13
        bra.w   _flushcaches
;---

.dec13  move.l  #$a3,d0

        move    #$203c,$104ec            ; remove .dec13 hook
        move.l  #$000000a3,$104ee

        move    #$d150,$10464

        patchs  $1050c,.dec14
        bra.w   _flushcaches
;---

.d14lp  bsr.b   .getov
.dec14  add     d2,(a0)+
        dbf     d0,.d14lp

        move    #$d558,$1050c             ; remove .dec14 hook
        move.l  #$51c8fffa,$1050e
        bra.w   _flushcaches


;--- fake ram read to original values

.getov  cmp.l   #$8be0,a1                 ; $8be0 x 3.w
        bne.b   .nov1
        move    #$4283,d2
        addq.l  #2,a1
        bra.b   .ovfnd
.nov1   cmp.l   #$8be2,a1
        bne.b   .nov2
        move    #$487a,d2
        addq.l  #2,a1
        bra.b   .ovfnd
.nov2   cmp.l   #$8be4,a1
        bne.b   .nov3
        move    #$000a,d2
        addq.l  #2,a1
        bra.b   .ovfnd
.nov3   cmp.l   #$8b90,a1                       ; $8b90.w
        bne.b   .nov4
        move    #$9082,d2
        addq.l  #2,a1
        bra.b   .ovfnd
.nov4   move    (a1)+,d2
.ovfnd  rts
				
;------------------------------------------------

_V2
	bsr.w   load_score	; was load_score but doesn't match addresses from save!

	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	sub.l	a1,a1
	lea	.pl_version2(pc),a0
	jsr	(resload_Patch,a2)
	movem.l	(a7)+,d0-d1/a0-a2
	
	jmp     (a6)

.pl_version2:
	PL_START
	; trainer
	PL_IFC1X	1
	PL_W	$16b2c,$6030
	PL_R	$16b66
	PL_ENDIF

	PL_IFC2X	0
	PL_PSS	$1BB0,_read_joypads_button_jump,2
	PL_ELSE
	PL_PSS	$1BB0,_read_joypads_up_jump,2
	PL_ENDIF
	PL_IFC2X	1
	PL_PSS	$1A48,_read_joypads_button_jump_p2,2
	PL_ENDIF

	PL_R	$6726-$20       ; no ext. mem

	PL_P   $8be0-$40,.rn1_V2
	PL_P   $9fec-$12e,.rn2_V2     
	PL_PS  $ef90-dec1-2,.rn31_V2  ; hook encoded rn
	PL_P   $6412,.rn4_Multi_V2_prep

	PL_L	$1b90-2,$4e717000                        ; kill ordinary check sums
	PL_L	$9ec2-dec2,$4e717000
	PL_L	$b12c-dec1,$4e717000
	PL_L	$16ab4-dec3,$4e717000
	PL_L	$1701a-dec3,$4e717000
	PL_L	$170b2-dec3,$4e717000
	PL_L	$17172-$2cc,$4e717000
	PL_L	$40b90-2,$4e717000
	PL_W	$8b90-$30,$7000
	PL_W	$9602-dec2,$7000
	PL_W	$9a5e-dec2,$7000
	PL_W	$abc4-dec1,$7000
	PL_W	$b0e6-dec1,$7000
	PL_W	$c350-dec1-2,$7000

	PL_W	$c44a-dec1-2,$538e                    ; kill check sums [subq.l #1,a6]
	PL_W	$108a4-dec3,$538e

	PL_PS  $1404c-dec3,.cs11_V2 ; ok ; catch encoded check sums
	PL_PS  $1500e-dec3,.cs21_V2 ; ok
	PL_PS  $16182-dec3,.cs31_V2 ; ok
	PL_PS  $16b24-dec3,.cs41_V2 ; ok
	PL_PS  $16bc4-dec3,.cs51_V2 ; ok

	; test just here
	PL_PS  $10362-dec3,.dec11_V2  ; hook double encoded check sum
	PL_P   $17e2-2,_rram_V2     ; catch ram read
	PL_PS  $1d7a-2,_cia         ; idem v1 & v2
	PL_P   $5b28-2,_loader      ; idem v1 & v2
	PL_PS  $b65e-dec1,save_score  ; ok
	IFD _ExtractFiles
		   PL_PS  $681e,.ExtractFiles
	IFD _DecompFiles
		   PL_PS  $3f4a,.DecrunchFiles
	ENDC
	ENDC
	PL_W	$6712-$20,$600a  ; snoop patch asked by Codetapper ;)
	PL_END


  IFD _ExtractFiles
.ExtractFiles
       movem.l d0-a6,-(a7)
        cmp.w #$6988,(a1)
        beq .pasj
        movem.l d1-a6,-(a7)
        move.l $68a6,a0
        move.l (_resload,pc),a2
        jsr (resload_GetFileSize,a2)
        movem.l (a7)+,d1-a6
        tst.l d0
        bne .pasj
        clr.l d0
        exg.l d0,d1
        move.l (_resload,pc),a2
        jsr (resload_SaveFileOffset,a2)
.pasj
      movem.l (a7)+,d0-a6
      tst.b $68a1
      rts

.DecrunchFiles
        jsr $1773c
        movem.l d0-a6,-(a7)
        movem.l d1-a6,-(a7)
        move.l $68a6,a0
        move.l (_resload,pc),a2
        jsr (resload_GetFileSize,a2)
        movem.l (a7)+,d1-a6
        tst.l d0
        bne .nof
        move.l $68a6,a1
        exg.l a1,a0
        clr.l d0
        exg.l d0,d1
        move.l (_resload,pc),a2
        jsr (resload_SaveFileOffset,a2)
.nof
      movem.l (a7)+,d0-a6
      rts
   ENDC



.Protect
 movem.l d0-a6,-(a7)
        lea $1376,a0
        move.l #4,d0
        move.l  _resload(pc),a6
        jsr     resload_ProtectWrite(a6)
 movem.l (a7)+,d0-a6
 rts

COPYLOCK_ID_V2=$4c295007
.rn1_V2      
;    move.l #$48e7ffff,$8be0-$40
;    move.w #$487a,$8be0-$40+4
    bra .Copylock


.rn2_V2
    move.l #$21fc0000,$9fec-$12e
    move.w #$a7ec,$9fec-$12e+4
.Copylock       movem.l d0-d7/a0-a7,-(a7)       ;Deprotect the game
                move.l  #$3d742cf1,(a7)
                move.l  (a7),$60.w
                lea     8(a7),a0
                lea     $24(a7),a1
                move.l  #COPYLOCK_ID_V2,d0         ;Copylock serial number
                moveq   #2,d2
                move.l  d0,d3
                lsl.l   #2,d0
.AlterRegLoop   move.l  (a0)+,d1
                sub.l   d0,d1
                move.l  d1,(a1)+
                add.l   d0,d0
                addq.b  #1,d2
                cmp.b   #8,d2
                bne.s   .AlterRegLoop
                move.l  d3,(a1)+                ;Move copylock ID to stack
                movem.l (a7)+,d0-d7/a0
                rts



;-------------- v2
.rn31lp_V2      bsr.w   .getov_V2
.rn31_V2        sub     d2,(a0)+
                dbf     d0,.rn31lp_V2
                patch   $edd0,.rn32_V2
              bra.w   _flushcaches

.rn32_V2
.rn3_V2
                move.l #$48e7ffff,$edd0
                move.w #$487a,$edd0
 ;               move.l  #COPYLOCK_ID_V2,$1832c
                patchs  $f708,.rn33_V2
                bra .Copylock


.rn33lp_V2       bsr.w   .getov_V2
.rn33_V2         add     d2,(a0)+
                 dbf     d0,.rn33lp_V2
                 lea     $f708,a0
                 move    #$d558,(a0)+
                 move.l  #$51c8fffa,(a0)
                 bra.w   _flushcaches


.rn4_Multi_V2_prep
    cmp.l #$48e7ffff,$36(a0)
    beq .ok
; bad
   nop
.ok
    pea .rn4_V2(pc)
    move.w #$4ef9,$36(a0)
    move.l (a7)+,$36+2(a0)
    jsr (a0)
    move.w #$64,$68ea
    movem.l (a7)+,d0/d2-d7/a0-a6
    rts
.rn4_V2
;    move.l #$48e7ffff,$76396
;    move.w #$487a,$76396+2
    bra .Copylock




;-------------- v2
.cs11_V2        move    #$7000,$14086-dec3
                patchs  $14088-dec3,.cs12_V2
                bra.w   _flushcaches
.cs12_V2        lea     $14052-dec3,a0
                moveq   #25,d0
                move.w  #$9150,$14086-dec3
                move.w  #$41fa,$14088-dec3
                move.l  #$ffc87019,$1408a-dec3
                bra.w   _flushcaches

.cs21_V2        move    #$7000,$15044-dec3
                patchs  $1504a-dec3,.cs22_V2
                bra.w   _flushcaches
.cs22_V2        moveq   #30,d0
                move.W  #$d150,$15044-dec3
                move.W  #$203c,$1504a-dec3
                move.l  #$0000001e,$1504c-dec3
                bra.w   _flushcaches

.cs31_V2        move    #$7000,$161bc-dec3
                patchs  $161c2-dec3,.cs32_V2
                bra.w   _flushcaches
.cs32_V2        moveq   #32,d0
                move    #$9150,$161bc-dec3
                move    #$203c,$161c2-dec3
                move.l  #$00000020,$161c4-dec3
                bra.w   _flushcaches

.cs41_V2        move    #$7000,$16b5e-dec3
                patchs  $16b6a-dec3,.cs42_V2
                bra.w   _flushcaches
.cs42_V2        moveq   #35,d0
                move    #$9150,$16b5e-dec3
                move    #$203c,$16b6a-dec3
                move.l  #$00000023,$16b6c-dec3
                bra.w   _flushcaches

.cs51_V2        move.l  #$4e717000,$16c0a-dec3
                patchs  $16c2c-dec3,.cs52_V2
                bra.w   _flushcaches
.cs52_V2        lea     $16bca-dec3,a0
                moveq   #47,d0
                move.l  #$b16b5eec,$16c0a-dec3
                move    #$702f,$16c2c-dec3
                move.l  #$41faff9a,$16c2e-dec3
                bra.w   _flushcaches



;--- patch double encoded check sum  v2

.d11lp_V2   bsr     .getov_V2
.dec11_V2   sub     d2,(a0)+
            dbf     d0,.d11lp_V2
            patchs  $103a2-dec3,.dec12_V2 ; warning to patch
            bra.w   _flushcaches

.d12lp_V2   move    (a0),d2
           eor     d1,(a0)+
.dec12_V2  move    d2,d1
           dbf     d0,.d12lp_V2

        move    #$3202,$103a2-dec3        ; remove .dec12 hook
        move.l  #$51c8fff8,$103a4-dec3

        move    #$7000,$10464-dec3        ; remove checksum
        patchs  $104ec-dec3,.dec13_V2
        bra.w   _flushcaches
;---

.dec13_V2  move.l  #$a3,d0

        move    #$203c,$104ec-dec3       ; remove .dec13 hook
        move.l  #$000000a3,$104ee-dec3

        move    #$d150,$10464-dec3       ; restore checksum

        patchs  $1050c-dec3,.dec14_V2
        bra.w   _flushcaches
;---

.d14lp_V2  bsr    .getov_V2
.dec14_V2  add     d2,(a0)+
           dbf     d0,.d14lp_V2

        move    #$d558,$1050c-dec3       ; remove .dec14 hook
        move.l  #$51c8fffa,$1050e-dec3
        bra.w   _flushcaches



;--- fake ram read to original values

.getov_V2
        cmp.l   #$8be0-$40,a1                       ; $8ba0 x 3.w
        bne.b   .nov1b
        move    #$48e7,d2
        addq.l  #2,a1
        bra.b   .ovfndb
.nov1b  cmp.l   #$8be0-$40+2,a1
        bne.b   .nov2b
        move    #$ffff,d2
        addq.l  #2,a1
        bra.b   .ovfndb
.nov2b  cmp.l   #$8be0-$40+4,a1
        bne.b   .nov3b
        move    #$487a,d2
        addq.l  #2,a1
        bra.b   .ovfndb
.nov3b  cmp.l   #$8b90-$30,a1                    ; $8b60.w
        bne.b   .nov4b
        move    #$9082,d2
        addq.l  #2,a1
        bra.b   .ovfndb
.nov4b
;---------- modif CFou
        cmp.l   #$8af0,a1                    ; $8b60.w
        bne.b   .nov5b1
        move    #$d3b9,d2
        addq.l  #2,a1
        bra.b   .ovfndb
.nov5b1
        cmp.l   #$8af0+2,a1                    ; $8b60.w
        bne.b   .nov5b2
        move    #$0000,d2
        addq.l  #2,a1
        bra.b   .ovfndb
.nov5b2
        cmp.l   #$8af0+4,a1                    ; $8b60.w
        bne.b   .nov5b3
        move    #$1372,d2
        addq.l  #2,a1
        bra.b   .ovfndb
.nov5b3

       move    (a1)+,d2
.ovfndb rts


;--- correct ram reading
_rram_V2
        bsr.w   _flushcaches
        cmp.l   #$8b90-$30,a4
        beq   _rr1
        cmp.l   #$9a5e-dec2,a4
        beq   _rr2
        cmp.l   #$9ec2-dec2,a4
        beq   _rr31
        cmp.l   #$9ec4-dec2,a4
        beq   _rr32
        cmp.l   #$9ec6-dec2,a4
        beq   _rr8
        cmp.l   #$abc4-dec1,a4
        beq   _rr4
        cmp.l   #$b0e6-dec1,a4
        beq   _rr2
        cmp.l   #$b12c-dec1,a4
        beq   _rr31
        cmp.l   #$b12e-dec1,a4
        beq   _rr32
        cmp.l   #$b130-dec1,a4
        beq   _rr9
        cmp.l   #$c350-dec1-2,a4
        beq   _rr4
        cmp.l   #$c44a-dec1-2,a4
        beq   _rr5
        cmp.l   #$8be0-$40,a4
        beq   _rr61_V2
        cmp.l   #$8be2-$40,a4
        beq   _rr62_V2
        cmp.l   #$8be4-$40,a4
        beq   _rr63_V2
        cmp.l   #$9602-dec2,a4
        beq   _rr4
        cmp.l   #$8a94,a4 ; no change now need
        beq   _rr7
        cmp.l   #$b65e-dec1,a4 ; save game
        beq   _rra1
        cmp.l   #$b65e-dec1+2,a4 ; save game
        beq   _rra2
        cmp.l   #$b65e-dec1+4,a4 ; save game
        beq   _rra3_V2
 
; modif CFou!
        cmp.l   #$6412,a4 ; Rob northen 4
        beq   _rra4a_V2
        cmp.l   #$6412+2,a4 ;
        beq   _rra4b_V2
        cmp.l   #$6412+4,a4 ;
        beq   _rra4c_V2
; snoop
        cmp.l   #$6712-$20,a4
        beq   _rra5


        move    (a4),2(a6,d1.w)
        rts


_rra4a_V2  move    #$4e90,2(a6,d1.w)
          rts
_rra4b_V2  move    #$33fc,2(a6,d1.w)
          rts
_rra4c_V2  move    #$0064,2(a6,d1.w)
          rts

_rram   bsr.w   _flushcaches

        cmp.l   #$8b90,a4
        beq   _rr1
        cmp.l   #$9a5e,a4
        beq   _rr2
        cmp.l   #$9ec2,a4
        beq   _rr31
        cmp.l   #$9ec4,a4
        beq   _rr32
        cmp.l   #$9ec6,a4
        beq   _rr8
        cmp.l   #$abc4,a4
        beq   _rr4
        cmp.l   #$b0e6,a4
        beq   _rr2
        cmp.l   #$b12c,a4
        beq   _rr31
        cmp.l   #$b12e,a4
        beq   _rr32
        cmp.l   #$c350,a4
        beq   _rr4
        cmp.l   #$c44a,a4
        beq   _rr5
        cmp.l   #$8be0,a4
        beq   _rr61
        cmp.l   #$8be2,a4
        beq   _rr62
        cmp.l   #$8be4,a4
        beq   _rr63
        cmp.l   #$9602,a4
        beq   _rr4
        cmp.l   #$8ab4,a4 ; no change now need
        beq   _rr7
        cmp.l   #$b130,a4
        beq   _rr9
        cmp.l   #$b65e,a4
        beq   _rra1
        cmp.l   #$b65e+2,a4
        beq   _rra2
        cmp.l   #$b65e+4,a4
        beq   _rra3
; snoop
        cmp.l   #$6712,a4
        beq   _rra5

        move    (a4),2(a6,d1.w)
        rts
;---

_rra5   move    #$08d5,2(a6,d1.w)
        rts

_rr1    move    #$9082,2(a6,d1.w)
        rts
;---

_rr2    move    #$9150,2(a6,d1.w)
        rts
;---

_rr31   move    #$d168,2(a6,d1.w)
        rts
_rr32   move    #$0064,2(a6,d1.w)
        rts
;---

_rr4    move    #$d150,2(a6,d1.w)
        rts
;---

_rr5    move    #$dd66,2(a6,d1.w)
        rts
;--- V1

_rr61   move    #$4283,2(a6,d1.w)
        rts
_rr62   move    #$487A,2(a6,d1.w)
        rts
_rr63   move    #$000A,2(a6,d1.w)
        rts
;--- V2

_rr61_V2 move    #$48e7,2(a6,d1.w)
         rts
_rr62_V2 move    #$ffff,2(a6,d1.w)
         rts
_rr63_V2 move    #$487a,2(a6,d1.w)
         rts

;---

_rr7    move    #$db98,2(a6,d1.w)
        rts
;---

_rr8    move    #$343a,2(a6,d1.w)
        rts
;---

_rr9    move    #$600a,2(a6,d1.w)
        rts
;---

_rra1   move    #$d0b9,2(a6,d1.w)
        rts
_rra2   move    #$0000,2(a6,d1.w)
        rts
_rra3   move    #$2efe,2(a6,d1.w)
        rts
_rra3_V2 move    #$2efe-2,2(a6,d1.w)
         rts

;--- hook keyboard access   V1 & V2

_cia    move.b  #1,$c00(a1)

        move.l  a0,-(sp)

		cmp.b	_keyexit(pc),d2
		beq		_quit
		
        lea     custom1(pc),a0
        btst   #0,(3,a0)
        bne.b   .ciabye

        cmp.b   #$50,d2                         ; f1 ; jump level
        bne.b   .ciabye
        bsr	_level_completed

.ciabye move.l  (sp)+,a0
        rts
_level_completed
	clr     $12ea.w                         ; clear monster counter, same for both versions
	rts
_read_joypads_up_jump:
	bsr	_read_common_controls
	move.w	($C,A6),d0	; original
	BTST #$0001,D0	; original code
	rts
_read_joypads_button_jump_p2:
	bsr	_read_common_controls
	bsr	_load_joydat_0
	BTST #$0001,D0	; original code
	rts

_read_joypads_button_jump:
	bsr	_read_common_controls
	bsr	_load_joydat_1
	BTST #$0001,D0	; original code
	rts
	
_read_common_controls
	movem.l	d0-d1/a0,-(a7)
	move.l	_ktable(pc),a0
	bsr	_read_joysticks_buttons
	; now handle pause & levelskip
	move.l	joy1_buttons(pc),d0
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.nojpquit
	btst	#JPB_BTN_GRN,d0
	beq.b	.nolevelskip
	bsr	_level_completed
.nolevelskip
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.nojpquit
	st.b	($45,a0)
	btst	#JPB_BTN_PLAY,d0
	bne		_quit
	bra.b	.jprest
.nojpquit
	clr.b	($45,a0)

.jprest
	
	btst	#JPB_BTN_PLAY,d0
	beq.b	.nopause

	; keyboard table @ $2090/8e +$5F : help (pause)
	st.b	($5F,a0)
	bra.b	.pauseout
.nopause
	clr.b	($5F,a0)
.pauseout
	; save previous button data
	movem.l	(a7)+,d0-d1/a0
	rts

_load_joydat_0
	move.w	#0,d0
	bra.b	_load_joydat_xx
_load_joydat_1
	move.w	#2,d0
_load_joydat_xx
	; using 2nd button data, tamper with JOYxDAT value
	movem.l	a0/d1-d2,-(a7)
	lea	$DFF00A,A0
	move.w	(A0,d0.w),d1	; joyxdat value
	lea	joy0_buttons(pc),a0
	add.w	d0,a0
	move.l	(a0,d0.w),d2	; read buttons value
	
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,d1
	btst	#9,d1
	beq.b	.noneed
	bset	#8,d1	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d2
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,d1
	btst	#9,d1
	bne.b	.no_blue
	bset	#8,d1	; xor 8 and 9 yields 1 cos bit9=0
.no_blue:
	move.w	d1,d0		; store the tampered-with value
	movem.l	(a7)+,a0/d1-d2
	RTS	


;--- load highscores V1

load_score       movem.l d0-d7/a0-a6,-(sp)
                lea     scores(pc),a0
                move.l  _resload(pc),a6
                jsr     resload_GetFileSize(a6)
                tst.l   d0
                beq.b   .nohs

                lea     scores(pc),a0
                move.l	_scores_address(pc),a1
                move.l  _resload(pc),a6
                jsr     resload_LoadFile(a6)

.nohs        movem.l (sp)+,d0-d7/a0-a6
                bra.w   _flushcaches

;--- save highscores V2



;--- save highscores V1

save_score add.l   _scores_offset(pc),d0
                 movem.l d0-d7/a0-a6,-(sp)
                lea     custom1(pc),a0                  ; uncheated only
                tst.l   (a0)
                bne.b   .nosave

        lea     scores(pc),a0
        move.l	_scores_address(pc),a1
        moveq   #60,d0
        move.l  _resload(pc),a6
        jsr     resload_SaveFile(a6)

   ;     move.l  #$22a6,$dff080

.nosave         movem.l (sp)+,d0-d7/a0-a6
                bra.w   _flushcaches


;--- universal loader

_loader         movem.l d0-d7/a0-a6,-(sp)
                move    d1,d0
                mulu    #512,d0
                move    d2,d1
                mulu    #512,d1
                moveq   #1,d2
                move.l  _resload(pc),a6
                jsr     resload_DiskLoad(a6)
                movem.l (sp)+,d0-d7/a0-a6
                moveq   #0,d0
                bra.w   _flushcaches

Unsupported     pea     TDREASON_WRONGVER
_end            move.l  (_resload,pc),-(a7)
                add.l   #resload_Abort,(a7)
                rts
_quit
	pea	TDREASON_OK
	bra.b	_end

_flushcaches
                movem.l d0-d7/a0-a6,-(sp)
                move.l  _resload(pc),a6
                jsr     resload_FlushCache(a6)
                movem.l (sp)+,d0-d7/a0-a6
                rts
_install_cbswitch
                clr.l   -(a7)                           ;TAG_DONE
                pea     (_cbswitch,pc)                  ;function
                move.l  #WHDLTAG_CBSWITCH_SET,-(a7)
                move.l  a7,a0
                move.l  (_resload,pc),a2
                jsr     (resload_Control,a2)
                lea     (12,a7),a7                      ;restore sp
   rts
_cbswitch  move.l  (_c1,pc),(_custom+cop1lc)
           jmp     (a0)
_c1        dc.l    $22a6         ; v1 for v2 $22a6-2
_ktable		dc.l	$2090		; v1 for v2 $208E
_scores_address	dc.l     $15e4
_scores_offset 	dc.l	$2efe

_resload        dc.l    0
version         dc.l    0
trcadr          dc.l    $1001e
tags            dc.l    WHDLTAG_CUSTOM1_GET
custom1         dc.l    0,0

;--- file names

savfile         dc.b    'Disk.1',0
scores          dc.b    'Highs',0

  even
  end



