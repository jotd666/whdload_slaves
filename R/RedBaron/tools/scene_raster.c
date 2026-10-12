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
/* FC4: convex, already-clipped polygons. Native clipping and degenerate/
 * non-convex polygons retain their existing path. The packet contains a
 * closed native word-coordinate list, count and workspace (200 row pairs).
 * No coverage bitmap, fill pass or per-plane edge traversal is required. */
INLINE s32 coord(u32 list,u32 n) {return (short)get(list+n*2);}
INLINE u32 polygon(u32 *p) {
    u32 dst=p[1],v=p[2],n=p[3],rows=p[4],colour=p[7];
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
        if(left<=right)span(dst+y*40,left,right-left+1,colour);
    }
    return 0;
}
API u32 rb_scene(u32 *p) {
    if(p[0]==3)return polygon(p);
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
