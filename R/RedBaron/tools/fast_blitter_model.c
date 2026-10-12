/* Fast-memory planar drawing backend. The native renderer supplies the same
 * register descriptions it used for its blitter. No chunky conversion.
 * This unit is freestanding, PC-relative 68020 code: no OS calls or globals.
 */
typedef unsigned char u8;
typedef unsigned short u16;
typedef signed short s16;
typedef unsigned int u32;
typedef signed int s32;
#define INLINE static __attribute__((always_inline)) inline
#define W(off) r[(off)/2]
#define P(off) (*(u32 *)(r+(off)/2))

#ifdef RB_HOST_TEST
unsigned char *rb_test_memory;
#define API
INLINE u16 read16(u32 at) { return ((u16)rb_test_memory[at]<<8)|rb_test_memory[at+1]; }
INLINE void write16(u32 at,u16 value) { rb_test_memory[at]=value>>8;rb_test_memory[at+1]=value; }
#else
#define API __attribute__((section(".text.entry")))
INLINE u16 read16(u32 at) { return *(u16 *)at; }
INLINE void write16(u32 at,u16 value) { *(u16 *)at=value; }
#endif

INLINE u32 read32(u32 at) {
#ifdef RB_HOST_TEST
    return ((u32)read16(at)<<16)|read16(at+2);
#else
    return *(u32 *)at;
#endif
}
INLINE void write32(u32 at,u32 value) {
#ifdef RB_HOST_TEST
    write16(at,value>>16);write16(at+2,value);
#else
    *(u32 *)at=value;
#endif
}

/* Full-word solid interiors use aligned long stores. Only the two edges
 * require a destination read; both masks apply when the width is one word. */
INLINE void solid(u16 *r,u16 width,u16 height) {
    u32 dp=P(0x54),cp=P(0x48),fill=(W(0x40)&255)==0xfa ? ~0u:0;
    u16 c_dma=W(0x40)&0x200;
    s32 dstride=width*2+(s16)W(0x66),cstride=width*2+(s16)W(0x60);
    for(u16 y=0;y<height;y++) {
        u32 at=dp;u16 n=width;
        if(c_dma)W(0x70)=read16(cp+(width-1)*2);
        if(width==1) {
            u16 mask=W(0x44)&W(0x46);
            write16(at,(read16(at)&~mask)|(fill&mask));
        } else {
            if(W(0x44)!=65535) {
                u16 mask=W(0x44);
                write16(at,(read16(at)&~mask)|(fill&mask));at+=2;n--;
            }
            if(W(0x46)!=65535)n--;
            if(n && (at&2)){write16(at,fill);at+=2;n--;}
            while(n>=2){write32(at,fill);at+=4;n-=2;}
            if(n){write16(at,fill);at+=2;}
            if(W(0x46)!=65535) {
                u16 mask=W(0x46);
                write16(at,(read16(at)&~mask)|(fill&mask));
            }
        }
        dp+=dstride;if(c_dma)cp+=cstride;
    }
    P(0x54)=dp;P(0x48)=cp;
}

INLINE void merge_word(u32 src,u32 dst,u16 white) {
    u16 mask=read16(src);
    if(mask==0)return;
    if(mask==65535){write16(dst,white?65535:0);return;}
    u16 old=read16(dst);write16(dst,white?old|mask:old&~mask);
}
INLINE void merge(u16 *r,u16 width,u16 height) {
    u32 ap=P(0x50),dp=P(0x54),cp=P(0x48);u16 white=(W(0x40)&255)==0xfa;
    s32 astride=width*2+(s16)W(0x64),dstride=width*2+(s16)W(0x66),cstride=width*2+(s16)W(0x60);
    for(u16 y=0;y<height;y++) {
        u32 src=ap+2,dst=dp+2;u16 n=width;
        W(0x74)=read16(ap-(width-1)*2);W(0x70)=read16(cp-(width-1)*2);
        if(n && (dst&2)){src-=2;dst-=2;merge_word(src,dst,white);n--;}
        while(n>=2) {
            src-=4;dst-=4;u32 mask=read32(src);
            if(mask==~0u)write32(dst,white?~0u:0);
            else if(mask){u32 old=read32(dst);write32(dst,white?old|mask:old&~mask);}
            n-=2;
        }
        if(n)merge_word(src-2,dst-2,white);
        ap-=astride;dp-=dstride;cp-=cstride;
    }
    P(0x50)=ap;P(0x54)=dp;P(0x48)=cp;
}

INLINE u16 logic(u16 a,u16 b,u16 c,u16 fn) {
    switch (fn & 255) {
    case 0: return 0;
    case 255: return 65535;
    case 0xf0: return a;
    case 0xca: return (a & b) | (~a & c);
    case 0xfa: return a | c;
    case 0x0a: return ~a & c;
    case 0x5a: return a ^ c;
    case 0xaa: return c;
    case 0xcc: return b;
    default: {
        u16 value=0;
        if(fn&1)value|=~a & ~b & ~c;
        if(fn&2)value|=~a & ~b & c;
        if(fn&4)value|=~a & b & ~c;
        if(fn&8)value|=~a & b & c;
        if(fn&16)value|=a & ~b & ~c;
        if(fn&32)value|=a & ~b & c;
        if(fn&64)value|=a & b & ~c;
        if(fn&128)value|=a & b & c;
        return value;
    }}
}

INLINE u16 filled(u16 v,u16 *carry,u16 con1) {
    /* Fill proceeds from the least significant (rightmost) pixel. */
    u32 p=v;
    p ^= p<<1; p ^= p<<2; p ^= p<<4; p ^= p<<8;
    u16 before=(p<<1)^(*carry ? 65535:0);
    *carry ^= (p>>15)&1;
    return con1&8 ? v|before : v^before;
}

INLINE void line(u16 *r) {
    u16 control=W(0x42),con0=W(0x40),shift=con0>>12;
    u16 count=W(0x58)>>6;
    if(!count)count=1024;
    s16 err=P(0x50),amod=W(0x64),bmod=W(0x62),pitch=W(0x60);
    s32 pos=P(0x48);
    u16 texture=W(0x72),bshift=control>>12,negative=(control&64)!=0;
    u16 one_dot=(control&2)!=0,drawn=0;
    for(u16 i=0;i<count;i++) {
        u16 a=W(0x74)>>shift;
        if(one_dot && drawn)a=0;
        u16 b=(texture & (1u<<bshift)) ? 65535:0;
        write16(pos,logic(a,b,read16(pos),con0));
        drawn=1;
        u16 conditional=!negative;
        err=(s16)(err+(negative?bmod:amod));
        negative=err<0;
        s16 dx=0,dy=0;
        if(control&16) { /* x major; conditional y step */
            dx=control&4?-1:1;
            if(conditional)dy=control&8?-pitch:pitch;
        } else { /* y major; conditional x step */
            dy=control&4?-pitch:pitch;
            if(conditional)dx=control&8?-1:1;
        }
        if(dx<0) { if(shift==0){shift=15;pos-=2;}else shift--; }
        if(dx>0) { if(shift==15){shift=0;pos+=2;}else shift++; }
        pos+=dy;
        if(dy)drawn=0;
        bshift=(bshift+1)&15;
    }
    P(0x48)=pos;P(0x54)=pos;
    P(0x50)=(P(0x50)&0xffff0000u)|(u16)err;
    W(0x40)=(con0&4095)|(shift<<12);
    W(0x42)=(control&0x0fbf)|(bshift<<12)|(negative?64:0);
}

/* Public entry is kept first in its section by the linker script. */
API u32 rb_blit(u16 *r) {
    u16 con0=W(0x40),con1=W(0x42);
    if(con1&1){line(r);return 0;}
    u16 width=W(0x58)&63,height=W(0x58)>>6;
    if(!width)width=64;
    if(!height)height=1024;
    u16 fn=con0&255;
    if(con1==0 && (con0&0xf000)==0 && !(con0&0xc00) && (con0&0x100)
       && W(0x74)==65535 && (fn==0xfa || fn==0x0a)
       && P(0x48)==P(0x54) && W(0x60)==W(0x66)
       && ((con0&0x200) || (W(0x44)==65535 && W(0x46)==65535))) {
        solid(r,width,height);return 0;
    }
    if(con1==2 && (con0&0xff00)==0xb00 && (fn==0xfa || fn==0x0a)
       && W(0x44)==65535 && W(0x46)==65535 && P(0x48)==P(0x54)
       && W(0x60)==W(0x66) && !((P(0x50)^P(0x54))&2)) {
        merge(r,width,height);return 0;
    }
    /* Native polygon scratch: clear and inclusive area fill need neither
     * channel dispatch nor minterm/shift emulation per word. Keep the register
     * postconditions because later native operations reuse this description. */
    if(con0==0x0100 && con1==2) {
        u32 at=P(0x54);s32 stride=width*2+(s16)W(0x66);
        for(u16 y=0;y<height;y++) {
            u32 end=at;u16 n=width;
            if((end&2)==0 && n){write16(end,0);end-=2;n--;}
            while(n>=2){write32(end-2,0);end-=4;n-=2;}
            if(n)write16(end,0);
            at-=stride;
        }
        P(0x54)=at;return 0;
    }
    if(con0==0x09f0 && con1==10 && W(0x44)==65535 && W(0x46)==65535
       && P(0x50)==P(0x54) && W(0x64)==W(0x66)) {
        u32 at=P(0x54);s32 stride=width*2+(s16)W(0x66);
        for(u16 y=0;y<height;y++) {
            u16 carry=0;
            for(u16 x=0;x<width;x++) {
                u32 word=at-x*2;u16 value=read16(word);
                W(0x74)=value;
                write16(word,filled(value,&carry,10));
            }
            at-=stride;
        }
        P(0x50)=at;P(0x54)=at;return 0;
    }
    s32 step=con1&2?-2:2;
    s32 ap=P(0x50),bp=P(0x4c),cp=P(0x48),dp=P(0x54);
    s32 am=(s16)W(0x64),bm=(s16)W(0x62),cm=(s16)W(0x60),dm=(s16)W(0x66);
    if(step<0){am=-am;bm=-bm;cm=-cm;dm=-dm;}
    u16 ahold=0,bhold=0,ashift=con0>>12,bshift=con1>>12;
    for(u16 y=0;y<height;y++) {
        u16 carry=(con1>>2)&1;
        for(u16 x=0;x<width;x++) {
            u16 av=W(0x74),bv=W(0x72),cv=W(0x70);
            if(con0&0x800){av=read16(ap);ap+=step;W(0x74)=av;}
            if(con0&0x400){bv=read16(bp);bp+=step;W(0x72)=bv;}
            if(con0&0x200){cv=read16(cp);cp+=step;W(0x70)=cv;}
            if(x==0)av&=W(0x44);
            if(x==width-1)av&=W(0x46);
            u16 a,b;
            if(step>0) {
                a=(((u32)ahold<<16)|av)>>ashift;
                b=(((u32)bhold<<16)|bv)>>bshift;
            } else {
                a=((((u32)av<<16)|ahold)<<ashift)>>16;
                b=((((u32)bv<<16)|bhold)<<bshift)>>16;
            }
            ahold=av;bhold=bv;
            u16 out=logic(a,b,cv,con0);
            if(con1&24)out=filled(out,&carry,con1);
            if(con0&0x100){write16(dp,out);dp+=step;}
        }
        if(con0&0x800)ap+=am;
        if(con0&0x400)bp+=bm;
        if(con0&0x200)cp+=cm;
        if(con0&0x100)dp+=dm;
    }
    P(0x50)=ap;P(0x4c)=bp;P(0x48)=cp;P(0x54)=dp;
    return 0;
}
