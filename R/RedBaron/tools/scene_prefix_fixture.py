"""Generate an isolated VERIFY startup fixture for R2; never edit release source.

Assemble the emitted source with the usual includes and -DVERIFY=1, then run it
with WHDLoad CoreDump. Success is the explicit 'R2 prefix replay PASS' abort.
Tests execute the actual assembly guard and private blit entry, including the
captured DFCA/D000, 1FFF mask, 1-word x 10-row operation. Input pixels are synthetic.
"""
import argparse
from pathlib import Path


def fixture(root):
    # Offset, changed register word, value, expected guard result.
    cases = [(-2, 0, 0, 1), (-4, 0, 0, 0), (-1, 0, 0, 0),
             (48000, 0, 0, 0), (-2, 0x40, 0xdff0, 0),
             (-2, 0x40, 0xdeca, 0), (-2, 0x42, 0xd002, 0),
             (-2, 0x42, 0xd001, 0), (-2, 0x42, 0xd008, 0),
             (-2, 0x44, 0x3fff, 0), (-2, 0x48, 0, 0),
             (-2, 0x58, 640, 0), (-2, 0x58, 661, 0),
             (-2, 0x58, 1, 0), (-2, 0x58, 201*64+1, 0),
             (-2, 0x60, 36, 0), (-2, 0x66, 36, 0),
             (-2, 0x40, 0xffca, 1)]
    masks = [(0x73b9*i+0xd137)&65535 for i in range(20)]
    pixels = [(0x137b*i+0x59f1)&65535 for i in range(10)]
    expected = []
    ahold = bhold = 0
    for row in range(10):
        av = masks[row*2] & 0x1fff
        bv = pixels[row]
        # Independent per-bit A-selects-B-else-C truth rule.
        value = 0
        for bit in range(16):
            index = bit+13
            a = ((av if index < 16 else ahold) >> (index % 16)) & 1
            b = ((bv if index < 16 else bhold) >> (index % 16)) & 1
            value |= (b if a else (0xa55a >> bit) & 1) << bit
        expected.append(value)
        ahold, bhold = av, bv
    assert expected[0] == 0xa55a
    def words(values):return ' dc.w '+','.join(f'${v:04x}' for v in values)+'\n'
    body = '''
 IFND VERIFY
 FAIL "R2 fixture requires VERIFY"
 ENDC
r2_fixture:
 lea r2_cases(pc),a5
 moveq #CASE_COUNT-1,d7
.case
 bsr r2_seed
 move.l (a5)+,d0
 move.w (a5)+,d1
 move.w (a5)+,0(a4,d1.w)
 lea .check(pc),a6
.check
 adda.l #scene_frame_prefix_check-.check,a6
 jsr (a6)
 cmp.w (a5)+,d0
 bne r2_fail
 dbf d7,.case
 ; Replay through the real SF_BLIT wrapper, not just the guard function.
 bsr r2_seed
 lea r2_screen(pc),a0
 move.w #24032-1,d7
.fill
 move.w #$a55a,(a0)+
 dbf d7,.fill
 lea r2_screen+PERF_SCENE_PREFIX(pc),a0
 lea .buffer(pc),a1
.buffer
 adda.l #scene_frame_buffer-.buffer,a1
 move.l a0,(a1)
 move.l a4,a3
 lea .blit(pc),a6
.blit
 adda.l #scene_frame_blit_a3-.blit,a6
 jsr (a6)
 lea r2_screen+PERF_SCENE_PREFIX-2(pc),a0
 lea r2_expected(pc),a1
 moveq #9,d7
.compare
 move.w (a0),d0
 cmp.w (a1)+,d0
 bne r2_fail
 adda.w #40,a0
 dbf d7,.compare
 lea r2_screen(pc),a0
 moveq #7,d7
.prefix
 cmpi.w #$a55a,(a0)+
 bne r2_fail
 dbf d7,.prefix
 pea r2_pass_message(pc)
 bra r2_exit
r2_fail:
 pea r2_fail_message(pc)
r2_exit:
 pea TDREASON_FAILMSG
 lea .res(pc),a2
.res
 adda.l #_resload-.res,a2
 move.l (a2),a2
 jmp resload_Abort(a2)
r2_seed:
 lea .custom(pc),a4
.custom
 adda.l #scene_frame_custom-.custom,a4
 move.l a4,a0
 moveq #63,d6
.zero
 clr.l (a0)+
 dbf d6,.zero
 move.l #$dfcad000,$40(a4)
 move.l #$1fffffff,$44(a4)
 lea r2_screen+PERF_SCENE_PREFIX-2(pc),a0
 move.l a0,$48(a4)
 move.l a0,$54(a4)
 lea r2_masks(pc),a0
 move.l a0,$50(a4)
 lea r2_pixels(pc),a0
 move.l a0,$4c(a4)
 move.w #$0281,$58(a4)
 move.w #38,$60(a4)
 move.w #2,$64(a4)
 move.w #38,$66(a4)
 rts
r2_pass_message: dc.b "R2 prefix replay PASS",0
r2_fail_message: dc.b "R2 prefix replay FAIL",0
 even
r2_cases:
'''.replace('CASE_COUNT',str(len(cases)))
    for offset,word,value,passed in cases:
        body += f' dc.l {offset}\n dc.w {word},{value},{passed}\n'
    body += 'r2_masks:\n'+words(masks)+'r2_pixels:\n'+words(pixels)
    body += 'r2_expected:\n'+words(expected)+'r2_screen: dcb.b 48064,0\n'
    source = (root/'usr/source/RedBaronHD.s').read_text()
    needle = '_bootdos\n\tbsr perf_read_options'
    assert source.count(needle) == 1
    source = source.replace(needle, '_bootdos\n lea .r2(pc),a0\n.r2\n adda.l #r2_fixture-.r2,a0\n jmp (a0)\n\tbsr perf_read_options')
    return source+'\n'+body

if __name__ == '__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('output',type=Path);a=p.parse_args()
    a.output.write_text(fixture(Path(__file__).resolve().parents[1]))
