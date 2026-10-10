;*---------------------------------------------------------------------------
;  :Program.	4dsportsDrivinghd.asm
;  :Contents.	Slave for "4D Sports Driving" from Mindscape
;  :Author.	JOTD
;  :Original	v1 JOTD
;  :Version.	$Id: battleisle.asm 0.5 2000/11/26 21:13:41 jah Exp $
;  :History.	23.05.01 started
;		23.05.01 finished
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"4DSportsDriving.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC


;============================================================================

 IFD SIM_MANUAL
 IFND VERIFY
 FAIL "SIM_MANUAL requires the development VERIFY build"
 ENDC
 IFND SIM_MODE_MENU
 FAIL "SIM_MANUAL requires SIM_MODE_MENU"
 ENDC
 IFD SIM_FIXTURE
 FAIL "SIM_MANUAL excludes synthetic input/state fixtures"
 ENDC
 ENDC

 IFD SIM_LIVE_DRIVE
 IFND SIM_MODE_MENU
 FAIL "SIM_LIVE_DRIVE requires SIM_MODE_MENU"
 ENDC
 IFD SIM_FIXTURE
 FAIL "SIM_LIVE_DRIVE excludes synthetic simulation fixtures"
 ENDC
 ENDC

 IFD SIM_REPLAY_MENU
 IFND SIM_MODE_MENU
 FAIL "SIM_REPLAY_MENU requires SIM_MODE_MENU"
 ENDC
 IFND SIM_A4000
 FAIL "SIM_REPLAY_MENU requires SIM_A4000"
 ENDC
 ENDC

;USE_PROFILING

	IFD	USE_PROFILING
CHIP_ONLY	
	ENDC
	
;CHIP_ONLY

	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $FF000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
;INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
;STACKSIZE = 10000
BOOTDOS
;CACHE
; cache everywhere, to avoid slowdowns on Vampire which
; doesn't have a MMU so whdload doesn't enable caches at all
; despite CACHE define (which doesn't cache chipmem)
CACHECHIPDATA


;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.3-beta"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

slv_CurrentDir		dc.b	"data",0
slv_name		dc.b	"4D Sports Driving"
			IFD	CHIP_ONLY
			dc.b	" (DEBUG/CHIP MODE)"
			ENDC
			dc.b	0
slv_copy		dc.b	"1992 Distinctive/Mindscape",0
slv_info		dc.b	"Installed & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

slv_config
	dc.b "C2:X:Experimental rendering optimizations:0;",0
	even

program:
	dc.b	"stunts",0
args:
	dc.b	10
args_end:
	dc.b	0
	even

	;initialize kickstart and environment

_bootdos
		clr.l	$0.W

	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	(_resload,pc),a2		;A2 = resload

	;get tags
		lea	(tag,pc),a0
		jsr	(resload_Control,a2)
		IFD SIM_SCHEDULE
		; The field accumulator is validated for PAL only. Reject unsupported
		; video timing before loading the game or installing any clock hooks.
		move.l sim_monitor_id(pc),d0
		cmp.l #PAL_MONITOR_ID,d0
		beq .pal_clock
		pea TDREASON_MUSTPAL
		jmp (resload_Abort,a2)
.pal_clock:
		ENDC
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
		
        IFD	CHIP_ONLY
        movem.l a6,-(a7)
        move.l  4,A6
        move.l  #MEMF_CHIP,d1
        move.l  #$00004AF8,d0
        jsr (_LVOAllocMem,a6)
        movem.l (a7)+,a6
        ENDC
        
		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_main(pc),a5
		bsr	load_exe
	
	;quit
.quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

patch_main
	bsr perf_init
	IFD VERIFY
	movem.l d0-a6,-(sp)
	lea patch_main(pc),a0
	adda.l #tape_game-patch_main,a0
	move.l d7,(a0)
	addq.l #4,(a0)
	IFD SIM_A4000
	bsr sim_a4000_prepare
	lea patch_main(pc),a0
	adda.l #sim_aux_prepare-patch_main,a0
	jsr (a0)
	lea patch_main(pc),a0
	adda.l #sim_sound_prepare-patch_main,a0
	jsr (a0)
	lea patch_main(pc),a0
	adda.l #sim_camera_prepare-patch_main,a0
	jsr (a0)
	ENDC
	IFD SIM_PHYSICS
	lea patch_main(pc),a0
	adda.l #sim_physics_selftest-patch_main,a0
	jsr (a0)
	ENDC
	IFD SIM_SCHEDULE
	bsr sim_schedule_reset_selftest
	bsr sim_schedule_modal_selftest
	bsr sim_schedule_replay_selftest
	IFD SIM_A4000
	bsr sim_results_selftest
	bsr sim_results_summary_selftest
	bsr sim_results_ui_selftest
	bsr sim_events_selftest
	lea patch_main(pc),a0
	adda.l #sim_aux_selftest-patch_main,a0
	jsr (a0)
	lea patch_main(pc),a0
	adda.l #sim_sound_selftest-patch_main,a0
	jsr (a0)
	bsr sim_average_selftest
	bsr sim_score_selftest
	bsr sim_score_rank_selftest
	bsr sim_score_display_selftest
	bsr sim_score_file_selftest
	bsr sim_score_open_selftest
	IFD SIM_SCORE_IO_TEST
	bsr sim_score_io_selftest
	ENDC
	bsr sim_history_selftest
	bsr sim_capacity_selftest
	lea patch_main(pc),a0
	adda.l #sim_time_selftest-patch_main,a0
	jsr (a0)
	ENDC
	ENDC
	IFD SIM_MANUAL
	; Enable the live clock without creating the keyboard automation task.
	lea patch_main(pc),a0
	adda.l #tape_configured-patch_main,a0
	move.l #1,(a0)
	IFD SIM_LIVE_INPUT_TEST
	lea patch_main(pc),a0
	adda.l #tape_start-patch_main,a0
	jsr (a0)
	ENDC
	ELSE
	lea patch_main(pc),a0
	adda.l #tape_start-patch_main,a0
	jsr (a0)
	ENDC
	IFD SIM_PROBE
	bsr sim_clock_install
	IFD SIM_LIVE_INPUT_TEST
	; Exercise the real Exec removal and fresh registration before live input.
	bsr sim_clock_remove
	bsr sim_clock_install
	ENDC
	ENDC
	movem.l (sp)+,d0-a6
	ENDC
	IFD	USE_PROFILING
	move.l	#$10000,d0
	lea		$100.W,a1
	bsr		init_allocated_address	
	bsr		install_profiler_vbl_hook
	ENDC
	
	move.l	D7,A1
	addq.l	#4,A1

	lea	pl_main(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	bsr perf_patch
	rts

    
after_dma_write_d1:
	btst	#15,d1
	beq.b	.out

	; DMA sound enable: wait

    bsr sound_wait

.out
	MOVE	#$0000,12(A0)	; stolen
	rts
    
sound_wait:
	movem.l	D0,-(A7)
	moveq.l	#6,D0

.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1

	movem.l	(A7)+,D0
    rts

dma_write_1
	MOVE	#$0001,$DFF096
    bra.b   sound_wait
dma_write_2
	MOVE	#$0002,$DFF096
    bra.b   sound_wait
dma_write_4
	MOVE	#$0004,$DFF096
    bra.b   sound_wait
dma_write_8
	MOVE	#$0008,$DFF096
    bra.b   sound_wait
    
;dma_write_8001
;	MOVE	#$8001,$DFF096
;    bra.b   sound_wait
;dma_write_8002
;	MOVE	#$8002,$DFF096
;    bra.b   sound_wait
;dma_write_8004
;	MOVE	#$8004,$DFF096
;    bra.b   sound_wait
;dma_write_8008
;	MOVE	#$8008,$DFF096
;    bra.b   sound_wait
    
;---------------

;  sed -n "s#.**800\(.\),150(A\(.\)).**;\(.**\): .**#PL_PS $\3,dma_sound_wait_a\2_\1#p"

pl_main
    PL_START
    IFD VERIFY
    IFD TAPE_OPPONENT
    PL_PSS $32B0,tape_opponent_main_observe_stub,2
    PL_PSS $4DC6,tape_opponent_menu_observe_stub,2
    PL_PSS $179B4,tape_restart_observe_stub,2
    PL_PS $9CE8,tape_restart_result_stub
    ENDC
    IFD SIM_PROBE
    PL_P $E5F2,sim_probe_entry_stub
    IFD SIM_FIXTURE_INVERTED
    PL_PS $C614,sim_inverted_wheels_stub
    ENDC
    IFD SIM_A4000
    PL_P $1033A,sim_a4000_steering
    PL_PSS $7984,sim_sound_consume_stub,64
    PL_PS $10904,sim_sound_publish_stub
    PL_PSS $7E9C,sim_camera_vertical_stub,24
    PL_PSS $7F6E,sim_camera_horizontal_stub,32
    PL_PSS $7FA0,sim_camera_x_stub,2
    PL_PSS $7FD0,sim_camera_z_stub,2
    PL_PSS $11A20,sim_aux_birth_stub,2
    PL_PSS $11B80,sim_aux_move_stub,94
    PL_PSS $11C38,sim_aux_retire_stub,10
    PL_PSS $11C50,sim_aux_rotate_stub,26
    PL_PSS $C326,sim_a4000_distance,26
    PL_PSS $F60C,sim_a4000_acceleration,10
    PL_PSS $F29E,sim_a4000_gear38,66
    PL_PSS $F310,sim_a4000_gear34,66
    PL_PSS $F36E,sim_a4000_gear_middle,66
    PL_PSS $CB48,sim_a4000_wheel,142
    PL_PSS $CC9E,sim_a4000_wheel_contact,2
    PL_PSS $D1B0,sim_a4000_wheel_contact,2
    PL_PSS $10234,sim_a4000_extension_capped,14
    PL_PSS $1024A,sim_a4000_extension_variable,16
    PL_PSS $10030,sim_a4000_suspension_bias,158
    PL_PSS $1011C,sim_a4000_suspension_return,256
    PL_PSS $F4BC,sim_a4000_engine_decay,8
    PL_PS $F5E4,sim_a4000_delay5
    PL_PS $F6CA,sim_a4000_delay5
    PL_PS $F784,sim_a4000_delay30
    PL_PS $F7A6,sim_a4000_delay10
    PL_PSS $F842,sim_a4000_terrain,42
    PL_PSS $F974,sim_a4000_heading,80
    PL_PS $FD64,sim_a4000_skid_loss
    PL_PSS $F7DA,sim_a4000_spin_begin,2
    PL_PS $FD46,sim_a4000_spin_slip
    PL_PSS $C3C4,sim_a4000_spin_test,2
    PL_PS $C3E0,sim_a4000_spin_rotate
    PL_PSS $FBEC,sim_a4000_spin_filter,26
    PL_PSS $FC2A,sim_a4000_spin_filter,26
    PL_PSS $FC10,sim_a4000_spin_inactive,2
    PL_PSS $FCBA,sim_a4000_spin_alternate,16
    PL_PSS $FCD0,sim_a4000_slip_gate,2
    PL_PSS $FCEE,sim_a4000_slip_relax,16
    PL_PS $C620,sim_a4000_slip_impulse_fixed
    PL_PS $C9CE,sim_a4000_slip_impulse_dynamic
    PL_PSS $FD2E,sim_a4000_spin_slip_test,2
    PL_PSS $C06E,sim_a4000_opponent_steering,36
    PL_PSS $C098,sim_a4000_opponent_brake_gate,2
    PL_PSS $C0BA,sim_a4000_opponent_brake,30
    PL_PSS $CB06,sim_a4000_wheel_pass,2
    PL_PSS $CF9E,sim_a4000_contact_distance,2
    PL_PSS $E07A,sim_history_new_race_stub,4
    PL_PSS $E548,sim_history_seek_zero_stub,2
    PL_PS $5698,sim_results_ui_player_pop8_stub
    PL_PSS $5720,sim_results_ui_penalty_pop12_stub,2
    PL_PS $57E8,sim_results_ui_opponent_bne_stub
    PL_PSS $5830,sim_results_ui_player_pop16_stub,2
    PL_PS $5842,sim_results_ui_player_beq10_stub
    PL_PSS $5848,sim_results_ui_compare_stub,2
    PL_PSS $58C6,sim_results_ui_player_pop24_stub,2
    PL_PS $5C00,sim_results_ui_player_beq20_stub
    PL_PSS $5C8C,sim_results_ui_player_pop14_stub,2
    PL_PS $5F6C,sim_results_ui_player_beq42_stub
    PL_PS $11680,sim_events_record_player_stub
    PL_PS $11678,sim_events_record_opponent_stub
    PL_PS $20DEA,sim_events_local_player_stub
    PL_PS $20DDA,sim_events_local_opponent_stub
    PL_PSS $593A,sim_events_summary_compare_stub,2
    PL_PSS $5960,sim_events_average_test_stub,2
    PL_PSS $5970,sim_events_average_divisor_stub,8
    PL_PSS $E852,sim_average_accumulate_stub,4
    PL_PS $597E,sim_average_finish_stub
    PL_PSS $3956,sim_score_load_stub,2
    PL_PSS $39DC,sim_score_reset_stub,2
    PL_PSS $5F72,sim_score_eligibility_stub,36
    PL_PSS $3E02,sim_score_insert_stub,4
    PL_PSS $4028,sim_score_save_stub,2
    PL_PSS $3558,sim_score_top_guard_stub,18
    PL_PS $5F56,sim_score_autocreate_stub
    IFD SIM_SCORE_AUTOCREATE_TEST
    PL_P $5F66,sim_score_autocreate_test_return_stub
    ENDC
    IFD SIM_SCORE_INSERT_TEST
    PL_PSS $3F16,sim_score_insert_test_finish_stub,2
    PL_PSS $3FB0,sim_score_insert_test_reject_stub,2
    ENDC
    PL_PSS $116AA,sim_results_summary_copy_stub,2
    PL_PS $E27C,sim_results_reset_stub
    PL_PSS $E976,sim_results_award_stub,14
    PL_PSS $E994,sim_results_accumulate_stub,2
    PL_PSS $1161A,sim_results_player_stub,10
    PL_PSS $11632,sim_results_opponent_stub,6
    PL_PSS $770E,sim_time_sum_consumer_stub,2
    PL_PSS $92F6,sim_time_sum_recorded_stub,2
    PL_PSS $936C,sim_time_sum_seek_stub,2
    PL_PSS $9332,sim_time_cache_key_stub,2
    PL_PSS $934E,sim_time_cache_key_stub,2
    PL_PSS $20EF6,sim_time_sum_producer_stub,2
    PL_P $1A46E,sim_time_format_entry_stub
    PL_NOP $1A474,2
    PL_PS $2412,sim_history_input_buffer_stub
    PL_PSS $7C0A,sim_history_producer_limit_stub,12
    PL_PSS $775A,sim_history_consumer_limit_stub,12
    PL_PSS $E56E,sim_history_seek_bound_stub,8
    PL_PS $E65A,sim_history_save_stub
    PL_PS $E5DA,sim_history_restore_stub
    PL_PSS $7D08,sim_history_rotate_stub,2
    ENDC
    IFD SIM_SCHEDULE
    PL_PS $1A788,sim_schedule_modal_enter
    PL_PS $7908,sim_schedule_reset_history
    PL_PSS $70E0,sim_schedule_poll,2
    PL_PS $7A04,sim_schedule_timer
    PL_PSS $7C0A,sim_schedule_input,2
    ENDC
    ENDC
    ; Complete original instruction: bchg #0,$3b(a4), six bytes.
    IFD SIM_MODE_MENU
    PL_P $1AAD6,sim_mode_dialog_stub
    PL_PS $16C9E,sim_preferences_load_stub
 IFD SIM_REPLAY_MENU
 PL_P $80EE,sim_replay_load_entry_stub
 PL_NOP $80F4,2
 PL_PS $E50E,sim_replay_init_tail_stub
 PL_PS $9E50,sim_replay_load_result_stub
 PL_PS $8174,sim_replay_save_direct_stub
 PL_NOP $817A,2
 PL_PS $1B1B2,sim_replay_save_dialog_stub
 PL_NOP $1B1B8,2
 ENDC
    ELSE
    PL_PS $1AAD6,tape_dialog_enter_stub
    ENDC
    PL_PS $74FA,tape_frame_stub
    IFD TAPE_PIXELS
    PL_PSS $20C3A,tape_draw_complete_stub,2
    ENDC
    ENDC
	PL_W	$2E77A-$6568,$9E	; fix move to intreqr
	PL_NOP	$6D36,2		; removes protection

    ;;PL_PSS  $1AFCC,cpu_dep_loop,6
    PL_I    $1AFCC  ; temp illegal
    ; write 000x
    
    PL_PS   $28196,after_dma_write_d1
    PL_PS   $28460,dma_write_1
    PL_PS   $28490,dma_write_2
    PL_PS   $284C0,dma_write_4
    PL_PS   $284F0,dma_write_8
    
    PL_PS   $282EA,dma_write_1
    PL_PS   $28328,dma_write_2
    PL_PS   $28366,dma_write_4
    PL_PS   $283A4,dma_write_8

    PL_PSS  $315A2,text_call,2
    PL_PSS  $3165A,text_call,2
    PL_PSS  $31732,text_call,2
    PL_PSS  $33B0E,bltclear_call,2
    PL_PSS  $34576,bltbitmap_call,4
    ; write 800x
    ;PL_PS   $28356,dma_write_8001
    ;PL_PS   $28350,dma_write_8002
    ;PL_PS   $2838E,dma_write_8004
    ;PL_PS   $283CC,dma_write_8008
    
    ; avoid a stop channel loop that lasts too long
    ; (and probably highly unnecessary now)
    ; because we have added a proper delay after dma write
    ; caused a super long wait after losing or ending the race
    
    PL_R    $28224
	PL_END

bltclear_call
	JSR	_LVOBltClear(A6)	;(graphics.library)
	MOVEA.L	8(A5),A0		;33B12: 206D0008
    bsr wait_blit
    rts
bltbitmap_call
	JSR	_LVOBltBitMap(A6)	;(graphics.library)
	MOVEM.L	-24(A5),D4-D7/A2	;3457A: 4CED04F0FFE8
    bsr wait_blit
    rts
    
text_call
	MOVE.L	D7,-(A7)		;315A2: 2F07
	JSR	_LVOText(A6)	;(graphics.library)
	MOVE.L	(A7)+,D7		;315A8: 2E1F
    bsr wait_blit
    rts

wait_blit
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
    rts
    
; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)


load_exe:
	movem.l	d0-a6,-(a7)
	move.l	d0,d2
	move.l	a0,a3
	move.l	a1,a4
	move.l	a0,d1
	jsr	(_LVOLoadSeg,a6)
	move.l	d0,d7			;D7 = segment
	beq	.end			;file not found

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	movem.l	d2/d7/a4,-(a7)
	add.l	d7,d7
	add.l	d7,d7
	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d2/d7/a4
.skip
	;call
	move.l	d7,a3
	add.l	a3,a3
	add.l	a3,a3

	move.l	a4,a0

	movem.l	d7/a6,-(a7)

	move.l	d2,d0			; argument string length
	move.l	_stacksize(pc),-(a7)	; original stack format
	movem.l	(_saveregs,pc),d1-d7/a1-a2/a4-a6	; original registers (BCPL stuff)
	jsr	(4,a3)		; call program
	addq.l	#4,a7

	movem.l	(a7)+,d7/a6

	; Stop the field server before UnLoadSeg releases the game data it reads.
	IFD VERIFY
	IFD SIM_PROBE
	bsr sim_clock_remove
	ENDC
	ENDC
	;remove exe

	move.l	d7,d1
	jsr	(_LVOUnLoadSeg,a6)

	movem.l	(a7)+,d0-a6
	rts

.end
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

	IFD	USE_PROFILING
	include	profiler.s
	ENDC
	
_saveregs
		ds.l	16,0
_stacksize
		dc.l	0

;---------------

tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
		dc.l	WHDLTAG_CUSTOM5_GET
_custom5	dc.l	0
		dc.l	WHDLTAG_ATTNFLAGS_GET
perf_attnflags	dc.l	0
		IFD SIM_SCHEDULE
		dc.l WHDLTAG_MONITOR_GET
sim_monitor_id: dc.l 0
		ENDC
		dc.l	0

;============================================================================

	IFD VERIFY
; WHDLoad patch offsets are signed words. Keep entry stubs close to pl_main,
; independent of verification-table size. MOVEM preserves all flags including
; X; the reserved stack slot transfers to the target with the original SP.
	IFD SIM_A4000
sim_results_ui_player_pop8_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_results_ui_player_pop8_stub(pc),a0
 adda.l #sim_results_ui_player_pop8-sim_results_ui_player_pop8_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_results_ui_penalty_pop12_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_results_ui_penalty_pop12_stub(pc),a0
 adda.l #sim_results_ui_penalty_pop12-sim_results_ui_penalty_pop12_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_results_ui_opponent_bne_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_results_ui_opponent_bne_stub(pc),a0
 adda.l #sim_results_ui_opponent_bne-sim_results_ui_opponent_bne_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_results_ui_player_pop16_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_results_ui_player_pop16_stub(pc),a0
 adda.l #sim_results_ui_player_pop16-sim_results_ui_player_pop16_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_results_ui_player_beq10_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_results_ui_player_beq10_stub(pc),a0
 adda.l #sim_results_ui_player_beq10-sim_results_ui_player_beq10_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_results_ui_compare_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_results_ui_compare_stub(pc),a0
 adda.l #sim_results_ui_compare-sim_results_ui_compare_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_camera_vertical_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_camera_vertical_stub(pc),a0
 adda.l #sim_camera_vertical-sim_camera_vertical_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_camera_horizontal_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_camera_horizontal_stub(pc),a0
 adda.l #sim_camera_horizontal-sim_camera_horizontal_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_camera_x_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_camera_x_stub(pc),a0
 adda.l #sim_camera_x-sim_camera_x_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_camera_z_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_camera_z_stub(pc),a0
 adda.l #sim_camera_z-sim_camera_z_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_sound_consume_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_sound_consume_stub(pc),a0
 adda.l #sim_sound_consume-sim_sound_consume_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_sound_publish_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_sound_publish_stub(pc),a0
 adda.l #sim_sound_publish-sim_sound_publish_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_aux_birth_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_aux_birth_stub(pc),a0
 adda.l #sim_aux_birth-sim_aux_birth_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_aux_move_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_aux_move_stub(pc),a0
 adda.l #sim_aux_move-sim_aux_move_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_aux_retire_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_aux_retire_stub(pc),a0
 adda.l #sim_aux_retire-sim_aux_retire_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_aux_rotate_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_aux_rotate_stub(pc),a0
 adda.l #sim_aux_rotate-sim_aux_rotate_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_results_ui_player_pop24_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_results_ui_player_pop24_stub(pc),a0
 adda.l #sim_results_ui_player_pop24-sim_results_ui_player_pop24_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_results_ui_player_beq20_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_results_ui_player_beq20_stub(pc),a0
 adda.l #sim_results_ui_player_beq20-sim_results_ui_player_beq20_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_results_ui_player_pop14_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_results_ui_player_pop14_stub(pc),a0
 adda.l #sim_results_ui_player_pop14-sim_results_ui_player_pop14_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_results_ui_player_beq42_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_results_ui_player_beq42_stub(pc),a0
 adda.l #sim_results_ui_player_beq42-sim_results_ui_player_beq42_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_events_record_player_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_events_record_player_stub(pc),a0
 adda.l #sim_events_record_player-sim_events_record_player_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_events_record_opponent_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_events_record_opponent_stub(pc),a0
 adda.l #sim_events_record_opponent-sim_events_record_opponent_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_events_local_player_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_events_local_player_stub(pc),a0
 adda.l #sim_events_local_player-sim_events_local_player_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_events_local_opponent_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_events_local_opponent_stub(pc),a0
 adda.l #sim_events_local_opponent-sim_events_local_opponent_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_events_summary_compare_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_events_summary_compare_stub(pc),a0
 adda.l #sim_events_summary_compare-sim_events_summary_compare_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_events_average_test_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_events_average_test_stub(pc),a0
 adda.l #sim_events_average_test-sim_events_average_test_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_events_average_divisor_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_events_average_divisor_stub(pc),a0
 adda.l #sim_events_average_divisor-sim_events_average_divisor_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_average_accumulate_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_average_accumulate_stub(pc),a0
 adda.l #sim_average_accumulate-sim_average_accumulate_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
 IFD SIM_SCORE_INSERT_TEST
sim_score_insert_test_reject_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_score_insert_test_reject_stub(pc),a0
 adda.l #sim_score_insert_test_reject-sim_score_insert_test_reject_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_score_insert_test_finish_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_score_insert_test_finish_stub(pc),a0
 adda.l #sim_score_insert_test_finish-sim_score_insert_test_finish_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
 ENDC
sim_score_autocreate_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_score_autocreate_stub(pc),a0
 adda.l #sim_score_autocreate-sim_score_autocreate_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
 IFD SIM_SCORE_AUTOCREATE_TEST
; Terminal fixture replaces the eligibility continuation with a return to
; the controlled caller. The complete load/fallback/disable branch ran first.
sim_score_autocreate_test_return_stub:
 rts
 ENDC
sim_score_top_guard_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_score_top_guard_stub(pc),a0
 adda.l #sim_score_top_guard-sim_score_top_guard_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_score_eligibility_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_score_eligibility_stub(pc),a0
 adda.l #sim_score_eligibility-sim_score_eligibility_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_score_insert_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_score_insert_stub(pc),a0
 adda.l #sim_score_insert_entry-sim_score_insert_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_score_save_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_score_save_stub(pc),a0
 adda.l #sim_score_save_hook-sim_score_save_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_score_load_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_score_load_stub(pc),a0
 adda.l #sim_score_load_hook-sim_score_load_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_score_reset_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_score_reset_stub(pc),a0
 adda.l #sim_score_reset_hook-sim_score_reset_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_average_finish_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_average_finish_stub(pc),a0
 adda.l #sim_average_finish-sim_average_finish_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_results_summary_copy_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_results_summary_copy_stub(pc),a0
 adda.l #sim_results_summary_copy-sim_results_summary_copy_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_results_reset_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_results_reset_stub(pc),a0
 adda.l #sim_results_reset-sim_results_reset_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_results_award_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_results_award_stub(pc),a0
 adda.l #sim_results_award-sim_results_award_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_results_accumulate_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_results_accumulate_stub(pc),a0
 adda.l #sim_results_accumulate-sim_results_accumulate_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_results_player_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_results_player_stub(pc),a0
 adda.l #sim_results_player-sim_results_player_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_results_opponent_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_results_opponent_stub(pc),a0
 adda.l #sim_results_opponent-sim_results_opponent_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_time_cache_key_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_time_cache_key_stub(pc),a0
 adda.l #sim_time_cache_key-sim_time_cache_key_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_time_sum_consumer_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_time_sum_consumer_stub(pc),a0
 adda.l #sim_time_sum_consumer-sim_time_sum_consumer_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_time_sum_recorded_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_time_sum_recorded_stub(pc),a0
 adda.l #sim_time_sum_recorded-sim_time_sum_recorded_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_time_sum_seek_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_time_sum_seek_stub(pc),a0
 adda.l #sim_time_sum_seek-sim_time_sum_seek_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_time_sum_producer_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_time_sum_producer_stub(pc),a0
 adda.l #sim_time_sum_producer-sim_time_sum_producer_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_time_format_entry_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_time_format_entry_stub(pc),a0
 adda.l #sim_time_format_entry-sim_time_format_entry_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_history_input_buffer_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_history_input_buffer_stub(pc),a0
 adda.l #sim_history_input_buffer-sim_history_input_buffer_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_history_producer_limit_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_history_producer_limit_stub(pc),a0
 adda.l #sim_history_producer_limit-sim_history_producer_limit_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_history_consumer_limit_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_history_consumer_limit_stub(pc),a0
 adda.l #sim_history_consumer_limit-sim_history_consumer_limit_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_history_seek_bound_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_history_seek_bound_stub(pc),a0
 adda.l #sim_history_seek_bound-sim_history_seek_bound_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_history_new_race_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_history_new_race_stub(pc),a0
 adda.l #sim_history_new_race-sim_history_new_race_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_history_seek_zero_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_history_seek_zero_stub(pc),a0
 adda.l #sim_history_seek_zero-sim_history_seek_zero_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_history_save_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_history_save_stub(pc),a0
 adda.l #sim_history_save-sim_history_save_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_history_restore_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_history_restore_stub(pc),a0
 adda.l #sim_history_restore-sim_history_restore_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_history_rotate_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_history_rotate_stub(pc),a0
 adda.l #sim_history_rotate-sim_history_rotate_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
	ENDC
	IFD SIM_PROBE
 IFD SIM_FIXTURE_INVERTED
sim_inverted_wheels_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_inverted_wheels_stub(pc),a0
 adda.l #sim_inverted_wheels-sim_inverted_wheels_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
 ENDC
sim_probe_entry_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_probe_entry_stub(pc),a0
 adda.l #sim_probe_entry-sim_probe_entry_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
	ENDC
 IFD SIM_MODE_MENU
 IFD SIM_REPLAY_MENU
sim_replay_save_direct_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_replay_save_direct_stub(pc),a0
 adda.l #sim_replay_save_direct-sim_replay_save_direct_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_replay_save_dialog_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_replay_save_dialog_stub(pc),a0
 adda.l #sim_replay_save_dialog-sim_replay_save_dialog_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_replay_load_entry_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_replay_load_entry_stub(pc),a0
 adda.l #sim_replay_load_entry-sim_replay_load_entry_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_replay_init_tail_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_replay_init_tail_stub(pc),a0
 adda.l #sim_replay_init_tail-sim_replay_init_tail_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_replay_load_result_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_replay_load_result_stub(pc),a0
 adda.l #sim_replay_load_result-sim_replay_load_result_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
 ENDC
sim_preferences_load_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_preferences_load_stub(pc),a0
 adda.l #sim_preferences_load-sim_preferences_load_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
sim_mode_dialog_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea sim_mode_dialog_stub(pc),a0
 adda.l #sim_mode_dialog-sim_mode_dialog_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
 ENDC
tape_dialog_enter_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea tape_dialog_enter_stub(pc),a0
 adda.l #tape_dialog_enter-tape_dialog_enter_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
tape_frame_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea tape_frame_stub(pc),a0
 adda.l #tape_frame-tape_frame_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
	IFD TAPE_PIXELS
tape_draw_complete_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea tape_draw_complete_stub(pc),a0
 adda.l #tape_draw_complete-tape_draw_complete_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
	ENDC
	IFD TAPE_OPPONENT
tape_opponent_main_observe_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea tape_opponent_main_observe_stub(pc),a0
 adda.l #tape_opponent_main_observe-tape_opponent_main_observe_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
tape_opponent_menu_observe_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea tape_opponent_menu_observe_stub(pc),a0
 adda.l #tape_opponent_menu_observe-tape_opponent_menu_observe_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
tape_restart_observe_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea tape_restart_observe_stub(pc),a0
 adda.l #tape_restart_observe-tape_restart_observe_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
tape_restart_result_stub:
 subq.l #4,sp
 movem.l a0,-(sp)
 lea tape_restart_result_stub(pc),a0
 adda.l #tape_restart_result-tape_restart_result_stub,a0
 movem.l a0,4(sp)
 movem.l (sp)+,a0
 rts
	ENDC
	ENDC

	include "performance.s"

	IFD VERIFY
	IFD SIM_PROBE
	include "simulation_clock.s"
	IFD SIM_SCHEDULE
	include "simulation_schedule.s"
	ENDC
	ENDC
	IFD SIM_PHYSICS
	include "simulation_physics.s"
	IFD SIM_A4000
	IFD SIM_MODE_MENU
	include "simulation_mode.s"
	include "simulation_preferences.s"
	ENDC
	include "simulation_score_file.s"
	include "simulation_score_file_verify.s"
	include "simulation_score_records.s"
	include "simulation_score_insert.s"
	include "simulation_score_insert_verify.s"
	include "simulation_score_display.s"
	include "simulation_score_display_verify.s"
	include "simulation_a4000.s"
	include "simulation_results.s"
	include "simulation_results_ui.s"
	include "simulation_events.s"
	include "simulation_average.s"
	include "simulation_scores.s"
	include "simulation_history.s"
	include "simulation_capacity.s"
	include "simulation_time.s"

	ENDC
	include "simulation_physics_verify.s"
 IFD SIM_A4000
	include "simulation_replay_file.s"
 include "simulation_replay_io.s"
 include "simulation_replay_install.s"
 IFD SIM_REPLAY_MENU
 include "simulation_replay_menu.s"
 include "simulation_replay_save.s"
 IFD SIM_REPLAY_SAVE_TEST
 include "simulation_replay_save_verify.s"
 ENDC
 IFD SIM_REPLAY_LOAD_ERROR_TEST
 include "simulation_replay_error_verify.s"
 ENDC
 ENDC
 IFD SIM_REPLAY_RELOAD_TEST
 include "simulation_replay_reload_verify.s"
 ENDC
 IFD SIM_REPLAY_FILE_TEST
 include "simulation_replay_file_verify.s"
 IFD SIM_REPLAY_IO_TEST
 include "simulation_replay_io_verify.s"
 ENDC
 ENDC
 ENDC
	ENDC
	include "driving_tape.s"
	IFD SIM_PROBE
	include "simulation_verify.s"
	ENDC
	ENDC

 IFD VERIFY
 IFD SIM_A4000
 include "simulation_history_data.s"
 include "simulation_camera.s"
 include "simulation_camera_native_verify.s"
 include "simulation_sound.s"
 include "simulation_auxiliary.s"
 include "simulation_auxiliary_native_verify.s"
 include "simulation_auxiliary_verify.s"
 ; Separate input storage: native bulk layout reserves only 12,000 bytes.
 ; Keep at the end so it cannot push code/table PC-relative references apart.
 even
 dc.b "4DHINPUT"
 dc.l 30000
sim_history_inputs: dcb.b 30000,0
 dc.b "4DGUARD!"
sim_results_test_arena: dcb.b $1660,0
 include "simulation_results_ui_cases.s"
 IFD SIM_REPLAY_MENU
 even
 dc.l $4d4e5531
sim_replay_pending_file: dcb.b SIM_REPLAY_BYTES+2,0
 dc.l $4d4e5532
sim_replay_save_readback: dcb.b SIM_REPLAY_BYTES+2,0
 dc.l $53415645
 ENDC
 IFD SIM_REPLAY_RELOAD_TEST
 even
sim_replay_reload_marker:
 dc.b "4DRPLLOD"
 IFD SIM_REPLAY_MENU
 dc.w 4,0
 ELSE
 dc.w 2,0
 ENDC
 dc.l 0,-1,-1,-1,-1
 dc.l $4c4f4431
sim_replay_reload_buffer: dcb.b SIM_REPLAY_BYTES+2,0
 dc.l $4c4f4432
 ENDC
 IFD SIM_REPLAY_FILE_TEST
 even
sim_replay_test_marker:
 dc.b "4DRPLTST"
 dc.w 2,31
 dc.l 0
 dcb.l 5,0
 dc.l $52504c31
sim_replay_test_file: dcb.b SIM_REPLAY_BYTES,0
 dc.l $52504c32
sim_replay_test_out: dcb.b SIM_REPLAY_CRC_OFFSET-SIM_REPLAY_HEADER+4,0
 dc.l $52504c33
 IFD SIM_REPLAY_IO_TEST
sim_replay_io_marker:
 dc.b "4DRPLIO!"
 dc.w 1,12
 dc.l 0
 dc.l $494f3031
sim_replay_io_buffer: dcb.b SIM_REPLAY_BYTES+2,0
 dc.l $494f3032
sim_replay_io_readback: dcb.b SIM_REPLAY_BYTES+2,0
 dc.l $494f3033
 ENDC
 ENDC
 ENDC
 ENDC
 IFD SIM_SCHEDULE
 even
 dcb.b $1738,0
sim_schedule_replay_native: dcb.b $a9e,0
 ENDC
	END
