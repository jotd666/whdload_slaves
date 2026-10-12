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
INLINE void paint(u32 at,u16 coverage,u32 colour) {
    /* One coverage traversal supplies all five planes. */
    for(u32 plane=0;plane<5;plane++,at+=8000,colour>>=1) {
        u16 value=colour&1 ? coverage : 0;
        if(coverage!=65535)value|=get(at)&~coverage;
        put(at,value);
    }
}
INLINE void span(u32 row,s32 x,s32 width,u32 colour) {
    s32 last=x+width-1;
    u32 first=(u32)x>>4,end=(u32)last>>4;
    u16 left=65535u>>(x&15),right=65535u<<(15-(last&15));
    if(first==end){paint(row+first*2,left&right,colour);return;}
    paint(row+first*2,left,colour);
    for(u32 word=first+1;word<end;word++)paint(row+word*2,65535,colour);
    paint(row+end*2,right,colour);
}
API u32 rb_scene(u32 *p) {
    u32 op=p[0],dst=p[1],colour=p[7];
    s32 x=p[3],y=p[4],w=p[5],h=p[6];
    if(op==0) {
        if(x<0||y<0||w<1||h<1||x+w>320||y+h>200)return 1;
        u32 at=dst+y*40;
        for(s32 n=0;n<h;n++,at+=40)span(at,x,w,colour);
    } else if(op==1) {
        if(x<0||x>=320||y<0||y>=200||w<0||w>=320||h<y||h>=200)return 1;
        s32 dx=w-x,dy=h-y,sx=dx<0?-1:1;if(dx<0)dx=-dx;
        s32 major=dx>dy?dx:dy,minor=dx>dy?dy:dx;
        s32 error=4*minor-2*major,positive=4*(minor-major),negative=4*minor;
        /* Native blitter tie rule, including both endpoints and all octants. */
        for(s32 n=0;n<=major;n++) {
            paint(dst+y*40+(x>>4)*2,32768u>>(x&15),colour);
            s32 step=error>=0;error+=step?positive:negative;
            if(dx>dy){x+=sx;if(step)y++;}else{y++;if(step)x+=sx;}
        }
    } else if(op==2) {
        if(x<0||(x&1)||y<1||y>20||w<1||w>200||x-(w-1)*40-(y-1)*2<0||x+2>8000)return 1;
        u32 mask=p[2];
        for(s32 row=0;row<w;row++)for(s32 word=0;word<y;word++) {
            s32 offset=x-row*40-word*2;
            u16 coverage=get(mask+offset);
            if(coverage)paint(dst+offset,coverage,colour);
        }
    } else return 1;
    return 0;
}
