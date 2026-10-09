/* Exhaustive G1 magnitude normalizer check, all 2^32 inputs at both widths.
 * Build: cc -O3 -std=c99 check_projection_norm.c -o <local-output>
 * Reference follows the original one-bit loops; candidate follows the byte LUT.
 * This checks arithmetic, not assembly register preservation (the CPU twin does).
 */
#include <stdint.h>
#include <inttypes.h>
#include <stdio.h>

static unsigned char lengths[256];
static uint32_t reference(uint32_t v, int top, int *e) {
    *e=0;
    if (!v) return 0;
    uint32_t hi=1u<<top, lo=hi>>1;
    if (v>=hi) {
        do {v>>=1; ++*e;} while (v>=hi);
    } else {
        while (v<lo) {v=(v<<1)&65535; --*e;}
    }
    return v;
}
static uint32_t candidate(uint32_t v, int top, int *e) {
    *e=0;
    if (v<65536) {
        if (!v) return 0;
        if (top==15) {
            if (v>=32768) {*e=1; return v>>1;}
            if (v>=16384) return v;
        } else {
            if (v>=32768) return v;
            if (v>=16384) {*e=-1; return (v<<1)&65535;}
        }
        uint32_t byte=v;
        *e=-top;
        if (byte>=256) {byte>>=8; *e+=8;}
        *e+=lengths[byte];
        return (v<<(-*e))&65535;
    }
    uint32_t byte=v>>16;
    *e=16-top;
    if (byte>=256) {byte>>=8; *e+=8;}
    *e+=lengths[byte];
    return v>>*e;
}
int main(void) {
    for (unsigned i=0;i<256;++i) {
        unsigned v=i;
        while(v) {++lengths[i];v>>=1;}
    }
    for (int top=15;top<=16;++top) {
        for (uint64_t i=0;i<UINT64_C(4294967296);++i) {
            int re,ce;
            uint32_t rn=reference((uint32_t)i,top,&re);
            uint32_t cn=candidate((uint32_t)i,top,&ce);
            if (rn!=cn || re!=ce) {
                fprintf(stderr,"width %d input %08" PRIx64 ": %u/%d != %u/%d\n",top,i,rn,re,cn,ce);
                return 1;
            }
        }
        printf("width %d: 4294967296 inputs, zero mismatches\n",top);
        fflush(stdout);
    }
    return 0;
}
