/* Scene primitives write final planar colours in Fast RAM. They do not emulate
 * blitter registers or repeat clipping/rasterization for each bitplane.
 * Packet: op, destination, coverage, x, y, width/x2, height/y2, colour.
 * merge uses x=bottom word offset, y=words, width=rows (descending coverage).
 * Freestanding 68020 code; fixed native 320x200, five planes, 40-byte rows.
 */
typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;
typedef signed int s32;
#define INLINE static __attribute__((always_inline)) inline
#ifdef RB_HOST_TEST
u8 *rb_test_memory;
#define API
INLINE u16 get(u32 p) {return ((u16)rb_test_memory[p]<<8)|rb_test_memory[p+1];}
INLINE void put(u32 p,u16 v) {rb_test_memory[p]=v>>8;rb_test_memory[p+1]=v;}
#else
#define API __attribute__((section(".text.entry")))
INLINE u16 get(u32 p) {return *(u16 *)p;}
INLINE void put(u32 p,u16 v) {*(u16 *)p=v;}
#endif
INLINE void paint(u32 at,u16 coverage,const u32 *ink) {
    /* Colour selection is already expanded once for the primitive. */
    if(coverage==65535) {
        for(u32 plane=0;plane<5;plane++,at+=8000)put(at,ink[plane]);
    } else {
        for(u32 plane=0;plane<5;plane++,at+=8000)
            put(at,(get(at)&~coverage)|(ink[plane]&coverage));
    }
}
INLINE void putlong(u32 at,u32 value) {
#ifdef RB_HOST_TEST
    put(at,value>>16);put(at+2,value);
#else
    *(u32 *)at=value;
#endif
}
INLINE void solid(u32 at,u32 words,u32 value) {
    if((at&2) && words){put(at,value);at+=2;words--;}
    u32 longs=words>>1;
#ifndef RB_HOST_TEST
    u32 groups=longs>>2;
    if(groups) {
        groups--;
        __asm__ volatile("1: move.l %2,(%0)+\n\tmove.l %2,(%0)+\n\t"
                         "move.l %2,(%0)+\n\tmove.l %2,(%0)+\n\tdbra %1,1b"
                         : "+a"(at), "+&d"(groups) : "d"(value) : "memory", "cc");
    }
    longs&=3;
#endif
    while(longs--){putlong(at,value);at+=4;}
    if(words&1)put(at,value);
}
INLINE void span(u32 row,s32 x,s32 width,const u32 *ink) {
    s32 last=x+width-1;
    u32 first=(u32)x>>4,end=(u32)last>>4;
    u16 left=65535u>>(x&15),right=65535u<<(15-(last&15));
    if(first==end){paint(row+first*2,left&right,ink);return;}
    u32 interior=end-first-1;
    /* Only edge words read old pixels. Opaque interiors use aligned longword
     * runs; the native loop writes four longs per DBRA. */
    for(u32 plane=0;plane<5;plane++,row+=8000) {
        u32 value=ink[plane],at=row+first*2,stop=row+end*2;
        put(at,(get(at)&~left)|(value&left));
        solid(at+2,interior,value);
        put(stop,(get(stop)&~right)|(value&right));
    }
}
/* Each colour selects five BSET/BCLR instructions once per line. The native
 * error walk runs once, with no per-pixel plane loop or coverage scratch. */
#ifdef RB_HOST_TEST
#define DOT(C,A,B,D,E,F) do { \
    for(u32 plane=0;plane<5;plane++) { \
        u32 byte=at+plane*8000;u8 mask=1u<<(bit&7); \
        rb_test_memory[byte]=(rb_test_memory[byte]&~mask)|((C>>plane&1)?mask:0); \
    } \
} while(0)
#else
#define DOT(C,A,B,D,E,F) __asm__ volatile( \
    A " %[bit],(%[at])\n\t" B " %[bit],8000(%[at])\n\t" \
    D " %[bit],16000(%[at])\n\t" E " %[bit],24000(%[at])\n\t" \
    F " %[bit],32000(%[at])" : : [bit] "d"(bit), [at] "a"(at) : "memory", "cc")
#endif
#define LINE(C,A,B,D,E,F) \
static __attribute__((noinline)) void line_##C(u32 dst,s32 position,s32 straight, \
    s32 diagonal,s32 error,s32 positive,s32 negative,s32 major) { \
    for(s32 n=0;n<=major;n++) { \
        u32 at=dst+(position>>3),bit=~position; \
        DOT(C,A,B,D,E,F); \
        position+=straight; \
        s32 step=error>=0;error+=step?positive:negative; \
        if(step)position+=diagonal; \
    } \
}
LINE(0,"bclr","bclr","bclr","bclr","bclr")
LINE(1,"bset","bclr","bclr","bclr","bclr")
LINE(2,"bclr","bset","bclr","bclr","bclr")
LINE(3,"bset","bset","bclr","bclr","bclr")
LINE(4,"bclr","bclr","bset","bclr","bclr")
LINE(5,"bset","bclr","bset","bclr","bclr")
LINE(6,"bclr","bset","bset","bclr","bclr")
LINE(7,"bset","bset","bset","bclr","bclr")
LINE(8,"bclr","bclr","bclr","bset","bclr")
LINE(9,"bset","bclr","bclr","bset","bclr")
LINE(10,"bclr","bset","bclr","bset","bclr")
LINE(11,"bset","bset","bclr","bset","bclr")
LINE(12,"bclr","bclr","bset","bset","bclr")
LINE(13,"bset","bclr","bset","bset","bclr")
LINE(14,"bclr","bset","bset","bset","bclr")
LINE(15,"bset","bset","bset","bset","bclr")
LINE(16,"bclr","bclr","bclr","bclr","bset")
LINE(17,"bset","bclr","bclr","bclr","bset")
LINE(18,"bclr","bset","bclr","bclr","bset")
LINE(19,"bset","bset","bclr","bclr","bset")
LINE(20,"bclr","bclr","bset","bclr","bset")
LINE(21,"bset","bclr","bset","bclr","bset")
LINE(22,"bclr","bset","bset","bclr","bset")
LINE(23,"bset","bset","bset","bclr","bset")
LINE(24,"bclr","bclr","bclr","bset","bset")
LINE(25,"bset","bclr","bclr","bset","bset")
LINE(26,"bclr","bset","bclr","bset","bset")
LINE(27,"bset","bset","bclr","bset","bset")
LINE(28,"bclr","bclr","bset","bset","bset")
LINE(29,"bset","bclr","bset","bset","bset")
LINE(30,"bclr","bset","bset","bset","bset")
LINE(31,"bset","bset","bset","bset","bset")
#undef LINE
#undef DOT
INLINE void line(u32 dst,s32 x,s32 y,s32 x2,s32 y2,u32 colour) {
    s32 dx=x2-x,dy=y2-y,sx=dx<0?-1:1;if(dx<0)dx=-dx;
    s32 major=dx>dy?dx:dy,minor=dx>dy?dy:dx;
    s32 error=4*minor-2*major,positive=4*(minor-major),negative=4*minor;
    s32 position=y*320+x,straight=dx>dy?sx:320,diagonal=dx>dy?320:sx;
    switch(colour&31) {
    case 0:line_0(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 1:line_1(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 2:line_2(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 3:line_3(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 4:line_4(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 5:line_5(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 6:line_6(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 7:line_7(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 8:line_8(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 9:line_9(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 10:line_10(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 11:line_11(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 12:line_12(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 13:line_13(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 14:line_14(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 15:line_15(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 16:line_16(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 17:line_17(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 18:line_18(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 19:line_19(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 20:line_20(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 21:line_21(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 22:line_22(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 23:line_23(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 24:line_24(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 25:line_25(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 26:line_26(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 27:line_27(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 28:line_28(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 29:line_29(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 30:line_30(dst,position,straight,diagonal,error,positive,negative,major);break;
    case 31:line_31(dst,position,straight,diagonal,error,positive,negative,major);break;
    }
}
/* FC4: convex, already-clipped polygons. Native clipping and degenerate/
 * non-convex polygons retain their existing path. The packet contains a
 * closed native word-coordinate list, count and workspace (200 row pairs).
 * No coverage bitmap, fill pass or per-plane edge traversal is required. */
INLINE s32 coord(u32 list,u32 n) {return (short)get(list+n*2);}
INLINE u32 polygon(u32 *p,const u32 *ink) {
    u32 dst=p[1],v=p[2],n=p[3],rows=p[4];
    s32 minx=p[8],maxx=p[9],miny=p[10],maxy=p[11];
    if(n<3||n>32||minx<0||maxx>319||miny<0||maxy>199)return 1;
    s32 direction=0,top=200,bottom=-1;
    /* Bound every coordinate before cross-products; no signed overflow on
     * rejected native offscreen input. */
    for(u32 i=0;i<n;i++) {
        s32 x=coord(v,i*2),y=coord(v,i*2+1);
        if(x<minx||x>maxx||y<miny||y>maxy)return 1;
        if(y<top)top=y;if(y>bottom)bottom=y;
    }
    if(coord(v,0)!=coord(v,n*2)||coord(v,1)!=coord(v,n*2+1))return 1;
    /* Prove convexity including self-intersections before any output write. */
    for(u32 i=0;i<n;i++) {
        s32 x=coord(v,i*2),y=coord(v,i*2+1);
        s32 x2=coord(v,(i+1)*2),y2=coord(v,(i+1)*2+1);
        for(u32 j=0;j<n;j++) {
            s32 cross=(x2-x)*(coord(v,j*2+1)-y)-(y2-y)*(coord(v,j*2)-x);
            if(cross) {s32 sign=cross<0?-1:1;
                if(direction && direction!=sign)return 1;direction=sign;}
            else if(j<i && x==coord(v,j*2) && y==coord(v,j*2+1))return 1;
        }
    }
    if(!direction)return 1;
    for(s32 y=top;y<=bottom;y++){put(rows+y*4,320);put(rows+y*4+2,0);}
    /* The native fill excludes the first dot of each downward edge, then
     * ORs complete edges back in. For convex coverage the result is exactly
     * the interval between its extreme native line pixels on each row. */
    for(u32 i=0;i<n;i++) {
        s32 x=coord(v,i*2),y=coord(v,i*2+1);
        s32 x2=coord(v,(i+1)*2),y2=coord(v,(i+1)*2+1);
        if(y2<y){s32 t=x;x=x2;x2=t;t=y;y=y2;y2=t;}
        s32 dx=x2-x,dy=y2-y,sx=dx<0?-1:1;if(dx<0)dx=-dx;
        s32 major=dx>dy?dx:dy,minor=dx>dy?dy:dx;
        s32 error=4*minor-2*major,positive=4*(minor-major),negative=4*minor;
        s32 first=x;
        for(s32 k=0;k<=major;k++) {
            s32 last=x,oldy=y,step=error>=0;
            error+=step?positive:negative;
            if(dx>dy){x+=sx;if(step)y++;}else{y++;if(step)x+=sx;}
            if(y!=oldy || k==major) {
                s32 lo=first<last?first:last,hi=first>last?first:last;
                u32 at=rows+oldy*4;
                if(lo<get(at))put(at,lo);if(hi>get(at+2))put(at+2,hi);
                first=x;
            }
        }
    }
    for(s32 y=top;y<=bottom;y++) {
        s32 left=get(rows+y*4),right=get(rows+y*4+2);
        if(left<=right)span(dst+y*40,left,right-left+1,ink);
    }
    return 0;
}
API u32 rb_scene(u32 *p) {
    u32 ink[5];
    for(u32 plane=0;plane<5;plane++)ink[plane]=0u-((p[7]>>plane)&1);
    if(p[0]==3)return polygon(p,ink);
    u32 op=p[0],dst=p[1];
    s32 x=p[3],y=p[4],w=p[5],h=p[6];
    if(op==0) {
        if(x<0||y<0||w<1||h<1||x+w>320||y+h>200)return 1;
        u32 at=dst+y*40;
        for(s32 n=0;n<h;n++,at+=40)span(at,x,w,ink);
    } else if(op==1) {
        if(x<0||x>=320||y<0||y>=200||w<0||w>=320||h<y||h>=200)return 1;
        line(dst,x,y,w,h,p[7]);
    } else if(op==2) {
        if(x<0||(x&1)||y<1||y>20||w<1||w>200||x-(w-1)*40-(y-1)*2<0||x+2>8000)return 1;
        u32 mask=p[2];
        for(s32 row=0;row<w;row++)for(s32 word=0;word<y;word++) {
            s32 offset=x-row*40-word*2;
            u16 coverage=get(mask+offset);
            if(coverage)paint(dst+offset,coverage,ink);
        }
    } else return 1;
    return 0;
}
