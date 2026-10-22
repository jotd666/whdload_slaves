; Simulation-only road geometry. Rendering keeps the complete
; native routine. Called only after the master toggle/CPU/Fast selection.
; Keep centre, height and occlusion used by world-object collision projection;
; omit width and edge arrays rebuilt by native geometry before rendering.

step_collision_geometry_init:
	lea step_collision_geometry_code(pc),a0
	lea $8970e,a1
public_ref_104 equ *-4
	move.w #($8984e-$8970e)/2-1,d0
.copy:
	move.w (a1)+,(a0)+
	dbf d0,.copy
	lea $8989e,a1
public_ref_105 equ *-4
	move.w #($898e2-$8989e)/2-1,d0
.tail:
	move.w (a1)+,(a0)+
	dbf d0,.tail
; Only the loop-back DBF crosses the omitted 80-byte span. All other
; branches stay within their copied span; data references remain absolute.
	lea step_collision_geometry_code+$898ca-$8970e-$50(pc),a0
	move.w #$ff64,(a0)
	move.l _resload(pc),a2
	jsr (resload_FlushCache,a2)
	rts
	cnop 0,4
step_collision_geometry_code:
	ds.b $898e2-$8970e-$50
