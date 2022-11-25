;*****************************************************************
;**************** Sub-routine for decryption of Rob northen loader or file
;**************** Creaded by CFou! on 21/11/2004 v1.0
;**************** Update 17/02/2005 v1.0a : Astaroth & BallGame support added
;**************** Update 13/09/2005 v1.0b : BetterMaths&JuniorTypist support added
;**************** D7 and D5 are calculated
;*****************************************************************
; Usage:
; A6: register must contain adress of start of Rob Northen code ($6000.00xx)
;
;*** Warning!!! for executable encrypted file you must first use:
; LoadSeg function of dos.library
;------------------------------------------------------------------
; example of call for 'Return of the jedi'
;
;_jedi ; to select this file parametters
;
;                lea     (_program,pc),a0
;                move.l  a0,d1
;                jsr     (_LVOLoadSeg,a6)
;                move.l  d0,d7                   ;D7 = segment
;                beq     .program_err
;                lsl.l #2,d0
;                addq.l #4,d0
;                move.l d0,a6
;                bsr _RNDecryptionGeneric ; decryption
;                jmp (a6) ; Start decoded datas
;                ...
;
;            include 'RNDecryptionGeneric.i'
;
;Remark:        -> decoded file relocated at adress in (a6)
;               -> all hunks are decrypted and relocated
;-----------------------------------------------------------------

;*****************************************************************
;************************  some used LABEL (description)
;*****************************************************************
;_Calculate_D5      ; set this label if you want calculate d5 register (0-$1f)
;_WaitAfterFound    ; set it to wait on red screen after to have found d5 register
;_ReserveMemBuffer ; set if to reserve memory for buffer if not-> at $80000

;*****************************************************************
;************************  supported files
;*****************************************************************
; 3dpool (3dfire) / Astaroth (Astaroth.bin) / BallGame / BetterMaths
; JuniorTypist(test)
; Darkside / Zynaps / Lombard Rally / Return of the Jedi
; Crazy cars (main) / Captain blood / Tiger Road / Xenon / Arkanoid 2 
; Led Storm (Led) / Dragon Spirit / Battle Valley / Exolon / Total Eclipse
; Onslaught / Stunt Man / Steel empire (steel1981) / Rick Dangerous
; TimeScanner / APB / Waterloo (battlecode) / Kick Off / NitroBoostChallenge
; Steigar/ Thai Boxing / ThunderCats / Vader

;*****************************************************************
;************************ Parameter list
;*****************************************************************
; If you use CopyLockDecoder it can calculate needed informations (hunk structure)
;  key=$d                          ; Calculated if you set label '_Calculate_D5'
;
;  By example Led Storm  | H=$20 : Lenght of executable head structure
;  -------------------------------------------------------------------
;;_RelocFile  ; set this label is encrypted file is relocated
; Offset_AdrStartRelocTable=$C5C-H ; a0 or a0-Lenght of executable head structure
; LgFirstHunk=$425b                ; d0
; NbHunk=1                         ; d1
; RelativePositionStart=$359c-H    ; a2 or a3-Lenght of executable head structur
; NbHunkToskip=0                   ; it's seems all time 0


;********************************* Classical $6000.00c4 parameters
;----------------------------- Parameters: Led storm
 IFD _led
_RelocFile
;;_BraAdrStart=$c4                   ; rob file start by $6000.00c4
Offset_AdrStartRelocTable=$C5C-$20     ; only know with $c4
key=$d                             ; You must try  0 to 31
LgFirstHunk=$425b
NbHunk=1
RelativePositionStart=$359c-$20
NbHunkToskip=0
LgFile=71116  ; not need
 ENDC
;******************************************************************

;********************************* Classical $6000.007a parameters v1
;----------------------------- Parameters: battle valley (Warning not executable file
 IFD _battlevalley
_BraAdrStart=$7a                   ; rob file start by $6000.007a
Offset_AdrStartRelocTable=$c88     ; classical values for : Bra.l $7a v1
key=3                              ; You must try  0 to 31
LgFirstHunk=$10a
NbHunk=1
RelativePositionStart=$c8c
NbHunkToskip=0
LgFile=4608  ; not need
 ENDC
;----------------------------- Parameters: onslaught (Warning not executable file
 IFD _onslaught
_BraAdrStart=$7a                   ; rob file start by $6000.007a
Offset_AdrStartRelocTable=$c88     ; classical values for : Bra.l $7a v1
key=$b                             ; You must try  0 to 31
LgFirstHunk=$10a
NbHunk=1
RelativePositionStart=$c8c
NbHunkToskip=0
LgFile=4608  ; not need
 ENDC
;******************************************************************

;********************************* Classical $6000.007a parameters v2
;----------------------------- Parameters: Stuntman Master (Warning not executable file
 IFD _stunt
_BraAdrStart=$7a                   ; rob file start by $6000.007a
Offset_AdrStartRelocTable=$c88+$10 ;  classical values for : Bra.l $7a v2
key=$1e                              ; You must try  0 to 31
LgFirstHunk=$22b6
NbHunk=1
RelativePositionStart=$c8c+$10
NbHunkToskip=0
LgFile=38912  ; not need
 ENDC
;----------------------------- Parameters: steel empire
 IFD _steel
_RelocFile
_BraAdrStart=$7a                   ; rob file start by $6000.007a
Offset_AdrStartRelocTable=$c88+$10 ; classical values for : Bra.l $7a v2
key=$a                             ; You must try  0 to 31
LgFirstHunk=$1abc
NbHunk=3
RelativePositionStart=$2524-$28
NbHunkToskip=0
LgFile=4608  ; not need
 ENDC
;******************************************************************

;********************************* Classical $6000.00c6 parameters
;----------------------------- Parameters: Return Of the Jedi
 IFD _jedi
_RelocFile
_BraAdrStart=$c6                       ; rob file start by $6000.00c6
Offset_AdrStartRelocTable=$b90         ; classical values for : Bra.l $c6
key=7                                  ; You must try  0 to 31
LgFirstHunk=$26ec
NbHunk=$1c
RelativePositionStart=$2da8
NbHunkToskip=0
lgfile=58200  ; not need
 ENDC
;----------------------------- Parameters: Lombard Rally 2 disk version
 IFD _lombard
_RelocFile
_BraAdrStart=$c6                       ; rob file start by $6000.00c6
Offset_AdrStartRelocTable=$b90         ; classical values for : Bra.l $c6
key=4
LgFirstHunk=$2e48
NbHunk=1
RelativePositionStart=$f0c
NbHunkToskip=0
lgfile=50388  ; not need
 ENDC
;******************************************************************

;********************************* Classical $6000.00c8 parameter v1
;----------------------------- Parameters: Thunder cats
 IFD _thundercats
_RelocFile
_BraAdrStart=$c8                     ; rob file start by $6000.00c8
Offset_AdrStartRelocTable=$C98       ; classical values for : Bra.l $c8
key=$18                               ; You must try  0 to 31
LgFirstHunk=$5caa
NbHunk=3
RelativePositionStart=$4710-$28
NbHunkToskip=0
lgfile=321920  ; not need
 ENDC
;----------------------------- Parameters: Crazy cars
 IFD _crazycars
_RelocFile
_BraAdrStart=$c8                      ; rob file start by $6000.00c8
Offset_AdrStartRelocTable=$C98        ; classical values for : Bra.l $c8
key=27                                ; You must try  0 to 31
LgFirstHunk=$3ef8
NbHunk=3
RelativePositionStart=$40a4
NbHunkToskip=0
lgfile=72156  ; not need
 ENDC
;----------------------------- Parameters: Captain Blood
 IFD _blood
_RelocFile
_BraAdrStart=$c8                     ; rob file start by $6000.00c8
Offset_AdrStartRelocTable=$C98       ; classical values for : Bra.l $c8
key=31                               ; You must try  0 to 31
LgFirstHunk=$2682
NbHunk=3
RelativePositionStart=$159c
NbHunkToskip=0
lgfile=77508  ; not need
 ENDC
;----------------------------- Parameters: Arkanoid 2 (Warning not executable file
 IFD _arkanoid2
_BraAdrStart=$c8                    ; rob file start by $6000.00c8
Offset_AdrStartRelocTable=$C98      ; classical values for : Bra.l $c8
key=24                              ; You must try  0 to 31
LgFirstHunk=$108
NbHunk=1
RelativePositionStart=$c9c
NbHunkToskip=0
LgFile=4608  ; not need
 ENDC
;----------------------------- Parameters: Xenon (Warning not executable file
 IFD _xenon
_BraAdrStart=$c8                    ; rob file start by $6000.00c8
Offset_AdrStartRelocTable=$C98      ; classical values for : Bra.l $c8
key=7                              ; You must try  0 to 31
LgFirstHunk=$108
NbHunk=1
RelativePositionStart=$c9c
NbHunkToskip=0
LgFile=4608  ; not need
 ENDC
;----------------------------- Parameters: Tiger Road (Warning not executable file
 IFD _tigerroad
_BraAdrStart=$c8                    ; rob file start by $6000.00c8
Offset_AdrStartRelocTable=$C98      ; classical values for : Bra.l $c8
key=27                              ; You must try  0 to 31
LgFirstHunk=$108
NbHunk=1
RelativePositionStart=$c9c
NbHunkToskip=0
LgFile=4608  ; not need
 ENDC
;******************************************************************

;********************************* Classical $6000.00c8 parameter v2
;----------------------------- Parameters: Total Eclipse
 IFD _totaleclipse
_RelocFile                           ; set if relocate table
_BraAdrStart=$c8 ; not classical     ; rob file start by $6000.00c8 v2
Offset_AdrStartRelocTable=$CCC       ; classical values for : Bra.l $c8 v2
key=10                               ; You must try  0 to 31
LgFirstHunk=$575f
NbHunk=1
RelativePositionStart=$e34
NbHunkToskip=0
lgfile=92780  ; not need
 ENDC
;----------------------------- Parameters: Dark Side
 IFD _darkside
_RelocFile
_BraAdrStart=$c8 ;not classical       ; rob file start by $6000.00c8 v2
Offset_AdrStartRelocTable=$CCC        ; classical values for : Bra.l $c8 v2
key=25                                ; You must try  0 to 31
LgFirstHunk=$4f9a
NbHunk=1
RelativePositionStart=$e3c
NbHunkToskip=0
lgfile=84824  ; not need
 ENDC
;----------------------------- Parameters: Time Scanner (Warning not executable file
 IFD _timescanner
;_RelocFile
_BraAdrStart=$c8 ;not classical      ; rob file start by $6000.00c8 v2
Offset_AdrStartRelocTable=$CCC       ; classical values for : Bra.l $c8 v2
key=0                                ; You must try  0 to 31
LgFirstHunk=$10a
NbHunk=1
RelativePositionStart=$cd0
NbHunkToskip=0
lgfile=4608  ; not need
 ENDC
;******************************************************************

;********************************* Classical $6000.00cc parameters
;----------------------------- Parameters: vader
 IFD _vader
_RelocFile
_BraAdrStart=$cc                       ; rob file start by $6000.00cc
Offset_AdrStartRelocTable=$d00         ; classical values for : Bra.l $cc
key=$1C                                 ; You must try  0 to 31
LgFirstHunk=$127
NbHunk=2
RelativePositionStart=$dd0-$24
NbHunkToskip=0
lgfile=4560  ; not need
 ENDC
;----------------------------- Parameters: 3d Pool (3dfire)
 IFD _3dpool
_BraAdrStart=$cc                       ; rob file start by $6000.00cc
Offset_AdrStartRelocTable=$d00         ; classical values for : Bra.l $cc
key=20                                  ; You must try  0 to 31
LgFirstHunk=$5756
NbHunk=$1
RelativePositionStart=$d04
NbHunkToskip=0
lgfile=92796  ; not need
 ENDC
;----------------------------- Parameters: Thai Boxing
 IFD _thaiboxing
_RelocFile
_BraAdrStart=$cc                       ; rob file start by $6000.00cc
Offset_AdrStartRelocTable=$d00         ; classical values for : Bra.l $cc
key=7                                  ; You must try  0 to 31
LgFirstHunk=$1977
NbHunk=2
RelativePositionStart=$1c6c-$24
NbHunkToskip=0
lgfile=29465  ; not need
 ENDC
;----------------------------- Parameters: Kick Off (Warning not executable file
 IFD _kickoff
_BraAdrStart=$cc                       ; rob file start by $6000.00cc
Offset_AdrStartRelocTable=$d00         ; classical values for : Bra.l $cc
key=9                                  ; You must try  0 to 31
LgFirstHunk=$4706
NbHunk=$1
RelativePositionStart=$d04
NbHunkToskip=0
lgfile=76056  ; not need
 ENDC
;----------------------------- Parameters: Rick dangerous (Warning not executable file
 IFD _rick1
_BraAdrStart=$cc                       ; rob file start by $6000.00cc
Offset_AdrStartRelocTable=$d00         ; classical values for : Bra.l $cc
key=$1a                                  ; You must try  0 to 31
LgFirstHunk=$10a
NbHunk=$1
RelativePositionStart=$d04
NbHunkToskip=0
lgfile=4608  ; not need
 ENDC
;******************************************************************

;********************************* Classical $6000.00d0 parameters
;----------------------------- Parameters: Steigar
 IFD _steigar
_RelocFile
_BraAdrStart=$d0                    ; rob file start by $6000.00d0
Offset_AdrStartRelocTable=$CFC      ; classical values for : Bra.l $D0
key=$1a                             ; You must try  0 to 31
LgFirstHunk=$2060
NbHunk=2
RelativePositionStart=$22f4-$24
NbHunkToskip=0
LgFile=36528  ; not need
 ENDC
;----------------------------- Parameters: Waterloo (battlecode)
 IFD _waterloo
_RelocFile
_BraAdrStart=$d0                    ; rob file start by $6000.00d0
Offset_AdrStartRelocTable=$CFC      ; classical values for : Bra.l $D0
key=$1d                              ; You must try  0 to 31
LgFirstHunk=$c1d9
NbHunk=3
RelativePositionStart=$5d68-$28
NbHunkToskip=0
LgFile=210440  ; not need
 ENDC
;----------------------------- Parameters: BetterMaths
 IFD _bettermaths
_RelocFile
_BraAdrStart=$d0                    ; rob file start by $6000.00d0
Offset_AdrStartRelocTable=$CFC      ; classical values for : Bra.l $D0
key=28                              ; You must try  0 to 31
LgFirstHunk=$33b8
NbHunk=3
RelativePositionStart=$13d4-$28
NbHunkToskip=0
LgFile=62752  ; not need
 ENDC
;----------------------------- Parameters: JuniorTypist
 IFD _juniortypist
_RelocFile
_BraAdrStart=$d0                    ; rob file start by $6000.00d0
Offset_AdrStartRelocTable=$CFC      ; classical values for : Bra.l $D0
key=3                              ; You must try  0 to 31
LgFirstHunk=$2ccd
NbHunk=3
RelativePositionStart=$1358-$28
NbHunkToskip=0
LgFile=56216  ; not need
 ENDC
;----------------------------- Parameters: Astaroth (Warning not executable file
 IFD _astaroth
;_RelocFile
_BraAdrStart=$d0                    ; rob file start by $6000.00d0
Offset_AdrStartRelocTable=$CFC      ; classical values for : Bra.l $D0
key=$1f                              ; You must try  0 to 31
LgFirstHunk=$10a
NbHunk=1
RelativePositionStart=$d00
NbHunkToskip=0
LgFile=$1200  ; not need
 ENDC
;----------------------------- Parameters: APB (Warning not executable file
 IFD _apb
;_RelocFile
_BraAdrStart=$d0                    ; rob file start by $6000.00d0
Offset_AdrStartRelocTable=$CFC      ; classical values for : Bra.l $D0
key=$1c                              ; You must try  0 to 31
LgFirstHunk=$10a
NbHunk=1
RelativePositionStart=$d00
NbHunkToskip=0
LgFile=4608  ; not need
 ENDC
;----------------------------- Parameters: Zynaps
 IFD _zynaps
_RelocFile
_BraAdrStart=$d0                       ; rob file start by $6000.00d0
Offset_AdrStartRelocTable=$CFC         ; classical values for : Bra.l $D0
key=$1                                  ; You must try  0 to 31
LgFirstHunk=$2466
NbHunk=$2
RelativePositionStart=$20a4
NbHunkToskip=0
lgfile=44300  ; not need
 ENDC
;----------------------------- Parameters: Dragon Spirit
 IFD _dragonspirit
_RelocFile
_BraAdrStart=$d0                    ; rob file start by $6000.00d0
Offset_AdrStartRelocTable=$CFC      ; classical values for : Bra.l $D0
key=23                              ; You must try  0 to 31
LgFirstHunk=$9b
NbHunk=1
RelativePositionStart=$da4-$20
NbHunkToskip=0
LgFile=3980  ; not need
 ENDC
;******************************************************************


;********************************* Custom parameters
;----------------------------- Parameters: Exolon (Warning not executable file
 IFD _exolon
_BraAdrStart=$c8 ;not classical     ; rob file start by $6000.00c8
Offset_AdrStartRelocTable=$CE8      ; not classical
key=14                              ; You must try  0 to 31
LgFirstHunk=$10a
NbHunk=1
RelativePositionStart=$cec
NbHunkToskip=0
LgFile=4608  ; not need
 ENDC
;----------------------------- Parameters: Nitro Boost challenge
 IFD _nitroboostchallenge
_RelocFile
_BraAdrStart=$d0                    ; rob file start by $6000.00d0
Offset_AdrStartRelocTable=$964-$28 ; not classical values ($cfc) for : Bra.l $D0
key=7                              ; You must try  0 to 31
LgFirstHunk=$1ebc
NbHunk=3
RelativePositionStart=$2138-$28
NbHunkToskip=0
LgFile=42684  ; not need
 ENDC
;******************************************************************
;***************************************


;***************************************
;***************************************
;*********************** Start of file = dest adr in A6 ***************************

_RNDecryptionGeneric
;        Lea _startRN_coded,a6

        movem.l d0-a6,-(a7)
        clr.l d4
        clr.l d5
        clr.l d6
        clr.l d7
 ; set needed datas used to calculate checksum register(d7)
 lea Offset_LgFirstHunk(pc),a0       ; lg hunk 1
 MOVE.L  #LgFirstHunk,(a0)
 lea Offset_NbHunk(pc),a0
 MOVE.L  #NbHunk,(a0)                ; nb de hunk
 lea Offset_PositionStartFirstHunk(pc),a0
 MOVE.L  #RelativePositionStart,(a0) ; first hunk data
 lea Offset_NbHunkToSkip(pc),a0
 MOVE.L  #NbHunkToskip,(a0)          ;  0

        nop
 IFD _Calculate_D5
        bsr _Calcul_D5
 ENDC

        bsr _DecodeFile1

 IFD _RelocFile
        bsr _FileReloc    ; not needed for tiger Road
 ENDC

        bsr _Copy_Result
        nop
        movem.l (a7)+,d0-a6
        rts
              

 
;------------------  *********************
;------------------  ******** decryption routine -> key calculated
;------------------  *********************
;Offset_AdrStartRelocTable+4 ; Ca4   ; a0

Offset_AdrStartSecondHunk=-4         ; a1

;Offset_AdrStartRelocTable+4 ; Ca4   ; a2

Offset_LgFirstHunk:                  ; d0
 dc.l 0
Offset_NbHunk                        ; d1
 dc.l 0
Offset_PositionStartFirstHunk  ; d2
 dc.l 0
Offset_StartOfFile_DestAdr=0

Offset_NbHunkToSkip:
 dc.l 0
_Key_D5:
  dc.l key

_DecodeFile1


 ; $195c ; offset fin table oac/debut data

        LEA     Offset_AdrStartRelocTable(a6),A0     ; debut Table reloc / First Data to decrypt
        LEA     Offset_AdrStartSecondHunk(a6),A1      ; debut file -4(adresse hunk suivant/4) (sans structure
        LEA     Offset_AdrStartRelocTable+4(a6),A2
        MOVE.L  Offset_LgFirstHunk(pc),D0     ; lg hunk 1
        MOVE.L  Offset_NbHunk(pc),D1     ; nb de hunk
        MOVE.L  Offset_PositionStartFirstHunk(pc),D2   ; $195c ; offset fin table reloac/debut data
        nop
;        LEA     -8(a6),A3 ; bug
       lea (a6),a3
       nop

;.t     bra .t

; Calcul for RN Key
        move.l a0,d3 ;
        sub.l a3,d3  ;

        cmp.l d2,d3
        blo .ok
        exg.l d3,d2    ; debug
.ok
        sub.l d3,d2  ; $f0c-$9b0
        lsr.l #2,d2    ;   = / 4
        move.l d0,d4   ; lg hunk+oc $2e48
        sub.l d2,d4   ;= $6d69 ; first data


        move.l (a0),d3 ; first data coded
        sub.l d3,d4    ; first key
;        LSR.L #1,d4
;        sub.l #1,d4 debug
        move.l d4,d7
; end of calcul of key

;        move.l #key,d5 ; between  0 & 31
        move.l _Key_D5(pc),d5
   nop
       and.l #31,d5
       clr.l d6
       move.b d5,d6
       add.b #$16,d6
       bra .start ; debug
        NOP

; decode 1 hunk
.nextHunk
.nextWord
.00016
        LSL.L   #1,D7
        BTST    D5,D7
        BEQ.S   .00022
        BTST    D6,D7
        BEQ.S   .00026
        BRA.S   .00028

.00022
        BTST    D6,D7
        BEQ.S   .00028
.00026
        ADDQ.L  #1,D7
.00028
.start
        ADD.L   D7,(A0)
        ADD.L   (A0)+,D7
        SUBQ.L  #1,D0
        Bne.S   .nextWord
; ok Curent hunk decoded

;.tt bra .tt
        NOP
.skiphunk_loop
        SUBQ.L  #1,D1  ; next hunk ?
        beq .fin
        nop
; set next hunk values
        move.l (a1),a1
        add.l a1,a1
        add.l a1,a1
        move.l a1,a0
        add.l #4,a0
        move.l (a2)+,d0
        bne .nextHunk
        bra .skiphunk_loop

.fin
        rts
                


_FileReloc
;$998
;        lea _dest+$20,a6
        move.l a6,a0
        lea -8(a6),a5

        MOVE.L  Offset_NbHunk(pc),D0 ; nb hunk
        LSL.L   #2,D0
        LEA     Offset_AdrStartRelocTable(a6),A2 ; debug decoded data hunk 0
        ADDA.L  D0,A2
        LEA     Offset_StartOfFile_DestAdr(a6),A3
        ADDA.L  Offset_PositionStartFirstHunk(pc),A3 ; debug data after table oc?

.0ABC
       CMP.L   A2,A3   ; fin tablr oc?
.0ABE
        BEQ.S   .fin
        MOVE.L  (A2)+,D0
        BSR   .0AFC

        MOVE.L  A0,A1
        TST.L   -4(A2)
        BNE.S   .0AD2
        ADD.L  Offset_PositionStartFirstHunk(pc),A0
        MOVE.L  A0,A1

.0AD2
        MOVE.L  (A2)+,D1
        BEQ.S   .0ABC
        BCS.S   .0ABE
        move.l (a2)+,d0  ; debug missing
        SUB.L   Offset_NbHunkToSkip(pc),D0  ; hunk to skip
        BSR   .0AFC
        MOVE.L  A0,D2

.0AE4
        MOVE.L  (A2)+,D0
        ADD.L   D2,(A1,D0.L)
        SUBQ.L  #1,D1
        BNE.B   .0AE4
;.0AEE
       bra.b .0AD2
.0AF0
        NOP
        NOP

.fin
;good fin oc
   clr.l d0
   rts


.0AFC
        LEA     Offset_AdrStartSecondHunk(a6),A0
        TST.L   D0
        BEQ.B   .0B0E
.0B04
        MOVEA.L (A0),A0
        ADDA.L  A0,A0
        ADDA.L  A0,A0
        SUBQ.L  #1,D0
        BNE.B   .0B04
.0B0E
        ADDQ.L  #4,A0
        RTS


;------------------  *********************
;------------------  *********************
;------------------  *********************
;---------------------------------------



_Copy_Result
        LEA     Offset_AdrStartRelocTable(a6),A0
        move.l (a0),d0
        lsl.l #2,d0 ; lg data first hunk

       lea Offset_StartOfFile_DestAdr(a6),a0
       add.l Offset_PositionStartFirstHunk(pc),a0      ; $195c ; offset fi

       lea Offset_StartOfFile_DestAdr(a6),a1

        move.l a0,a2
        add.l d0,a2

.B72    MOVE.L  (A0)+,(A1)+
        CMP.L   A2,A0
        BLT.S   .B72
.B78
        CLR.L   (A1)+   , clear oc tabke
        CMP.L   A0,A1
        BLT.S   .B78
        rts


 rts


;------------------  *********************
;------------------  *********************
;------------------  *********************
;---------------------------------------
 IFD _Calculate_D5

_ReserveMemoryBuffer
  movem.l d0-a6,-(a7)
        MOVE.L  Offset_LgFirstHunk(pc),D0     ; lg hunk 1
       add.l #2,d0
       lsl.l #2,d0
       move.l #$10000,d1  ; Fast or Chip +clear
       move.l 4,a6
       jsr -$c6(a6) ;AllocMem
       beq .err
       lea BufferAdr(pc),a0
       move.l d0,(a0)
       lea ReservedMemBuffer(pc),a0
       move.l d0,(a0)
.err
  movem.l (a7)+,d0-a6
  rts

_FreeMemoryBuffer
  movem.l d0-a6,-(a7)
        move.l ReservedMemBuffer(pc),d0
        tst.l d0
        beq .err
        move.l d0,a1
        MOVE.L  Offset_LgFirstHunk(pc),D0     ; lg hunk 1
       add.l #2,d0
       lsl.l #2,d0
       move.l 4,a6
       jsr -$d2(a6) ; FreeMem
       lea ReservedMemBuffer(pc),a0
       move.l #0,(a0)
.err
  movem.l (a7)+,d0-a6
  rts

_Calcul_D5

  IFD _ReserveMemBuffer
    bsr _ReserveMemoryBuffer
  ENDC

    clr.l d5
.enc
    movem.l d5,-(a7)
    Bsr _copy_buffer
    BSR _DecodeBuffer
    bsr _Calcul_D5_Try
    beq .ok
    movem.l (a7)+,d5
    add.l #1,d5
    cmp.l #$20,d5
    bne .enc
    bsr _FreeMemoryBuffer
    move.l #-1,d0
    rts

.ok
    lea _Key_D5(pc),a0
    move.l (a0),d6

 IFD _WaitAfterFound
.t
  illegal
  move.w #$f00,$dff180
  btst #6,$bfe001
  bne .t
 ENDC
    move.l d5,(a0)
    movem.l (a7)+,d5
    bsr _FreeMemoryBuffer
    clr.l d0
    rts



_Calcul_D5_Try
       LEA     Offset_AdrStartRelocTable(a6),A0     ; debut Table reloc / First Data to decrypt
       MOVE.L  Offset_PositionStartFirstHunk(pc),D2   ; $195c ; offset fin table reloac/debut data
       add.l a6,d2
       sub.l a0,d2

      move.l BufferAdr(pc),a0
      add.l d2,a0

       move.l #BufferSize/2,d0
      ;  MOVE.L  Offset_LgFirstHunk(pc),D0     ; lg hunk 1
.enc
       move.l (a0),d1
   
;       cmp.w #$4e75,(a0)
;       beq .ok
       cmp.l #$41f90000,d1 ; lea $0000xxxx,(a0)
        beq .ok
       cmp.l #$4ef90000,d1 ; JMP $0000xxxx
       beq .ok
       cmp.l #$4eB90000,d1 ; JSR $0000xxxx
       beq .ok
   ;    cmp.l #$4ee8000c,d1 ; jmp $c(a0) ; bad only for APB
   ;    beq .ok
       cmp.l #$4eaefe38,d1 ; jsr -$1c8(a6)
       beq .ok
       cmp.l #$4e722700,d1 ; stop $2700
       beq .ok
       and.l #$fffffff0,d1
       cmp.l #$4ef90000,d1 ; JMP $000xxxxx
       beq .ok
       cmp.l #$41f90000,d1 ; lea $000xxxxx,(a0)
       beq .ok
       cmp.l #$43f90000,d1 ; lea $000xxxxx,(a1)
       beq .ok
       tst.w (a0)+
       dbf d0,.enc

    move.l #-1,d0
   rts
.ok
   clr.l d0
   rts

_DecodeBuffer

 ; $195c ; offset fin table oac/debut data
        LEA     Offset_AdrStartRelocTable(a6),A0     ; debut Table reloc / First Data to decrypt
   ;     LEA     Offset_AdrStartSecondHunk(a6),A1      ; debut file -4(adresse hunk suivant/4) (sans structure
        LEA     Offset_AdrStartRelocTable+4(a6),A2
        MOVE.L  Offset_LgFirstHunk(pc),D0     ; lg hunk 1
  ;      MOVE.L  Offset_NbHunk(pc),D1     ; nb de hunk
        MOVE.L  Offset_PositionStartFirstHunk(pc),D2   ; $195c ; offset fin table reloac/debut data
        nop
;        LEA     -8(a6),A3 ; bug
       lea (a6),a3
        nop

; Calcul for RN Key
        move.l a0,d3 ;
        sub.l a3,d3  ;

        cmp.l d2,d3
        blo .ok
        exg.l d3,d2    ; debug
.ok
        sub.l d3,d2  ; $f0c-$9b0
        lsr.l #2,d2    ;   = / 4
        move.l d0,d4   ; lg hunk+oc $2e48
        sub.l d2,d4   ;= $6d69 ; first data


        move.l (a0),d3 ; first data coded
        sub.l d3,d4    ; first key
        move.l d4,d7
; end of calcul of key

;        move.l #key,d5 ; between  0 & 31
;        move.l _Key_D5(pc),d5
   nop
       and.l #31,d5
       clr.l d6
       move.b d5,d6
       add.b #$16,d6
       move.l BufferAdr(pc),a0
       bra .start ; debug
        NOP
; decode 1 hunk
.nextHunk
.nextWord
.00016
        LSL.L   #1,D7
        BTST    D5,D7
        BEQ.S   .00022
        BTST    D6,D7
        BEQ.S   .00026
        BRA.S   .00028

.00022
        BTST    D6,D7
        BEQ.S   .00028
.00026
        ADDQ.L  #1,D7
.00028
.start  ADD.L   D7,(A0)
        ADD.L   (A0)+,D7
        SUBQ.L  #1,D0
        Bne.S   .nextWord
; ok Curent hunk decoded

        rts

Buffer=$80000
BufferSize=$400

_copy_buffer
        LEA     Offset_AdrStartRelocTable(a6),A0
        move.l  BufferAdr(pc),a1
        MOVE.L  Offset_LgFirstHunk(pc),D0     ; lg hunk 1
.enc
      move.l (a0)+,(a1)+
      dbf d0,.enc
  rts
BufferAdr
  dc.l Buffer
ReservedMemBuffer
  dc.l 0
                
 ENDC



