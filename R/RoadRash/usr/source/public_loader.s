; Bootstrap CPU code/data in the existing optional 320 KiB public allocation.
; $00000..$04fff: main stack/guards; $05000..$413eb: main image (later).
; $42000..$48fcf: lomain + external-call stubs; $49000..$4d01f: boot stack.
; Low shared control cells, loader entry address $4c98 and copper remain Chip.
; A3 returns the public entry. Do not overwrite $400 with a trampoline:
; its six bytes would destroy the fixed control cell at $404.
; The separate boot stack survives the main-stack initializer filling its guards.
 IFGT $42000+$6fb0+4*8-$49000
 FAIL public_loader_overlaps_boot_stack
 ENDC
 IFGT $49000+$4020-$50000
 FAIL public_boot_stack_exceeds_allocation
 ENDC
public_loader_init:
 movem.l d0-d7/a0-a2/a4-a6,-(a7)
 move.l _enhanced_framerate(pc),d0
 beq .done
 move.l _expmem(pc),a5
 cmpa.l #$200000,a5
 bcs .done
 cmpa.l #$a00000,a5
 bcs .placement
 cmpa.l #$1000000,a5
 bcs .done
.placement:
 cmpi.l #$6000431e,$400
 bne .done
 lea _base(pc),a0
 adda.l #public_loader_check-_base,a0
 lea $400,a1
 bsr public_boot_validate
 bne .done
 move.l a5,a4
 adda.l #$42000,a4
 lea $400,a0
 move.l a4,a1
 move.w #$6fb0/2-1,d0
.copy:
 move.w (a0)+,(a1)+
 dbf d0,.copy
 move.l a4,d7
 sub.l #$400,d7
 lea _base(pc),a6
 adda.l #public_loader_refs-_base,a6
.fix:
 moveq #0,d0
 move.w (a6)+,d0
 cmpi.w #-1,d0
 beq .relative
 move.l a4,a1
 adda.l d0,a1
 move.l (a1),d1
 cmpi.l #$4720,d1
 bcs .fix
 cmpi.l #$73b0,d1
 bhi .fix
 add.l d7,(a1)
 bra .fix
.relative:
 lea _base(pc),a6
 adda.l #public_loader_relative-_base,a6
.next:
 moveq #0,d0
 move.w (a6)+,d0
 cmpi.w #-1,d0
 beq .stack
 move.l a4,a1
 adda.l d0,a1
 moveq #0,d1
 move.w (a6)+,d1
 move.l a4,a2
 adda.l d1,a2
 sub.w d0,d1
 subq.w #2,d1
 move.w #$6100,(a1)+
 move.w d1,(a1)
 move.l (a6)+,(a2)+
 move.l (a6)+,(a2)
 bra .next
.stack:
 move.l a4,a1
 adda.l #$6014,a1
 cmpi.l #$08f90001,(a1)
 bne .audio_done
 move.l a4,d0
 addi.l #$68ec,d0
 cmp.l 4(a1),d0
 bne .audio_done
 lea public_audio_boot(pc),a0
 move.w #$4ef9,(a1)
 move.l a0,2(a1)
 move.w #$4e71,6(a1)
.audio_done:
 move.l a5,a0
 adda.l #$49000,a0
 move.w #$4020/4-1,d0
.guard:
 move.l #$a55aa55a,(a0)+
 dbf d0,.guard
 suba.w #16,a0
 move.l a0,$433a(a4)
 move.l a4,a3
 move.l _resload(pc),a2
 jsr (resload_FlushCache,a2)
.done:
 movem.l (a7)+,d0-d7/a0-a2/a4-a6
 rts
