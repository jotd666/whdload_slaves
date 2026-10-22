; CPU SET descriptors in optional public RAM; pixel bitplanes stay Chip.
; Twelve low-memory owners have 2 KiB slots (4-byte reload pointer + header).
; Three fixed-address sets have 8 KiB slots. All 22 relevant asset files were
; unpacked and checked: at most 106 images in low-owner sets, 497 in fixed sets.
; A descriptor is count.w followed by count 14-byte records. All pixel offsets
; begin after the descriptor array; they become original Chip pointers here.
; $467c/$467e also serve as blank-sprite words: retain the original Chip copy.
; The helper is installed only after a validated public main-image relocation.
 IFGT $50000+12*2048+3*8192-$5c000
 FAIL public_asset_slots_exceed_allocation
 ENDC
; Preserve native pixel pointers in Chip; translate a reload back to its
; original destination before native size/depack logic reads the owner again.
public_asset_relocate:
 ; Embedded SET headers follow the CPU image, but their pixel offsets must
 ; resolve against the retained original Chip copy. Dynamic SETs already
 ; arrive in Chip RAM (including the menu's temporary actor-storage overlay).
 movem.l d1/a1,-(a7)
 move.l a0,a1
 move.l a0,d1
 sub.l public_asset_image(pc),d1
 cmpi.l #$39108,d1
 beq .embedded
 cmpi.l #$39c90,d1
 beq .embedded
 cmpi.l #$3a2a0,d1
 beq .embedded
 cmpi.l #$3ab02,d1
 beq .embedded
 cmpi.l #$3ad72,d1
 bne .relocate
.embedded:
 addi.l #$80000,d1
 move.l d1,a1
.relocate:
 ; Native $afd9c register/CCR results, with the correct DMA pixel base.
 move.w (a0),d7
 subq.w #1,d7
 bmi .native_done
 lea 2(a0),a2
.native:
 move.l (a2),d0
 add.l a1,d0
 move.l d0,(a2)
 lea 14(a2),a2
 dbf d7,.native
.native_done:
 movem.l (a7)+,d1/a1
 move.w sr,-(a7)
 movem.l d0-d2/a0-a3,-(a7)
 lea e_masks_dirty(pc),a1
 move.w #1,(a1)
 move.l public_asset_pool(pc),a1
 cmpa.l #0,a1
 beq .done
 lea $432,a3
 moveq #11,d2
.owner:
 cmpa.l (a3),a0
 beq .copy
 addq.l #4,a3
 adda.l #2048,a1
 dbf d2,.owner
 bra .fixed
.copy:
 move.w #2044,d2
 bra .copy_header
.fixed:
 bsr public_menu_relocate
 move.l public_asset_image(pc),d0
 beq .done
 lea public_asset_fixed(pc),a3
 move.l public_asset_pool(pc),a1
 adda.l #$6000,a1
 moveq #2,d2
.fixed_next:
 cmpa.l (a3),a0
 beq .fixed_copy
 addq.l #8,a3
 adda.l #$2000,a1
 dbf d2,.fixed_next
 bra .done
.fixed_copy:
 addq.l #4,a3
 move.w #8188,d2
.copy_header:
 moveq #0,d0
 move.w (a0),d0
 beq .capacity_fail
 mulu.w #14,d0
 addq.l #2,d0
 cmp.l d2,d0
 bhi .capacity_fail
 move.l a0,(a1)+
 move.l a1,d1
 lsr.w #1,d0
 subq.w #1,d0
.words:
 move.w (a0)+,(a1)+
 dbf d0,.words
 move.l d1,(a3)
 cmpa.l #$1000,a3
 bcs .done
 bsr public_asset_publish_fixed
 bra .done
.capacity_fail:
 ; A later larger fixed-address asset must not retain an earlier Fast header.
 cmpa.l #$1000,a3
 bcs .done
 move.l a0,(a3)
 bsr public_asset_publish_fixed
.done:
 movem.l (a7)+,d0-d2/a0-a3
 move.w (a7)+,ccr
 rts

public_asset_load_destination:
 movem.l d0-d1/a0/a2-a3,-(a7)
 move.l public_asset_pool(pc),a0
 cmpa.l #0,a0
 beq .done
 addq.l #4,a0
 lea $432,a3
 moveq #11,d0
.next:
 cmpa.l a0,a1
 beq .restore
 adda.l #2048,a0
 addq.l #4,a3
 dbf d0,.next
 bra .done
.restore:
 move.l -4(a0),a1
 move.l a1,(a3)
.done:
 movem.l (a7)+,d0-d1/a0/a2-a3
 rts
public_asset_pool:
 dc.l 0

; Descriptor readers retain direct LEA operands. Loader/depacker addresses
; stay Chip. Preflight all sites once before permitting reader publication.
; These rendering consumers are outside every separate C code-copy span.
public_asset_init:
 movem.l d0-d2/a0-a3,-(a7)
 lea public_asset_readers(pc),a0
.check:
 move.l (a0)+,d0
 bmi .install
 move.l a5,a1
 adda.l d0,a1
 move.w (a0)+,d1
 cmp.w (a1),d1
 bne .done
 move.l (a0)+,d1
 cmp.l 2(a1),d1
 bne .done
 addq.l #4,a0
 bra .check
.install:
 lea public_asset_image(pc),a0
 move.l a5,(a0)
.done:
 movem.l (a7)+,d0-d2/a0-a3
 rts
public_asset_image:
 dc.l 0
; Called only while loading a fixed SET, after the complete descriptor copy.
; Retain direct LEA operands for frame-time speed; publish and flush all typed
; reader operands together. The enclosing relocation wrapper saves registers.
public_asset_publish_fixed:
 move.l public_asset_image(pc),a3
 cmpa.l #0,a3
 beq .done
 lea public_asset_readers(pc),a0
.next:
 move.l (a0)+,d0
 bmi .flush
 move.l a3,a1
 adda.l d0,a1
 addq.l #6,a0
 move.l (a0)+,d0
 lea _base(pc),a2
 adda.l d0,a2
 move.l (a2),2(a1)
 bra .next
.flush:
 move.l _resload(pc),a2
 jsr (resload_FlushCache,a2)
.done:
 rts
public_asset_fixed:
 dc.l $19a7e,$19a7e
 dc.l $38c84,$38c84
 dc.l $5c2cc,$5c2cc
public_asset_readers:
 dc.l $30520
 dc.w $43f9
 dc.l $00019a7e,public_asset_fixed+4-_base
 dc.l $30538
 dc.w $43f9
 dc.l $00019a7e,public_asset_fixed+4-_base
 dc.l $3032c
 dc.w $43f9
 dc.l $00038c84,public_asset_fixed+12-_base
 dc.l $303fa
 dc.w $45f9
 dc.l $00038c84,public_asset_fixed+12-_base
 dc.l $30e80
 dc.w $41f9
 dc.l $00038c84,public_asset_fixed+12-_base
 dc.l $31de8
 dc.w $41f9
 dc.l $00038c84,public_asset_fixed+12-_base
 dc.l $31e3c
 dc.w $41f9
 dc.l $00038c84,public_asset_fixed+12-_base
 dc.l $2fe94
 dc.w $43f9
 dc.l $0005c2cc,public_asset_fixed+20-_base
 dc.l $2ff80
 dc.w $45f9
 dc.l $0005c2cc,public_asset_fixed+20-_base
 dc.l $30e1e
 dc.w $41f9
 dc.l $0005c2cc,public_asset_fixed+20-_base
 dc.l $31ee6
 dc.w $41f9
 dc.l $0005c2cc,public_asset_fixed+20-_base
 dc.l $31f2c
 dc.w $41f9
 dc.l $0005c2cc,public_asset_fixed+20-_base
 dc.l -1
