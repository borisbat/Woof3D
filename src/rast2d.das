module rast2d private

require math

struct public Bitmap8
    //! single surface
    size : int2
    data : array<uint8>

def public lock_u8 ( dim:auto[]; blk:block<(var arg:array<uint8>#):void> )
    let num_elem = typeinfo(sizeof dim)
    unsafe
        map_to_array(addr(dim[0]), num_elem, blk)

[sideeffects,jit,hint(unsafe_range_check,noalias=span,noalias=tspan)]
def public rast_hspan ( var Span:array<uint8>#; SpanOffset:int; Tspan:array<uint8>#; TSpanOffset:int; uvY,dUVY:float; _count:int )
    unsafe
        if SpanOffset<0 || SpanOffset+_count>length(Span)
            panic("rast_hspan: span out of range {SpanOffset}+{_count} > {length(Span)}")
        var span = addr(Span[SpanOffset])
        var tspan = addr(Tspan[TSpanOffset])        // TODO: check range
        var count = _count
        var count4 = count >> 2
        count &= 3
        var PSP = span
        var uv4 = float4(uvY) + float4(0.,1.,2.,3.) * float4(dUVY)
        var duv4 = float4(dUVY) * 4.
        for P in range(count4)
            u8x4_gather_store(PSP,tspan,int4(uv4))
            PSP += 4
            uv4 += duv4
        var uvYT = uv4.x
        for P in range(count)
            PSP[P] = tspan[int(uvYT)]
            uvYT += dUVY

[sideeffects,jit,hint(unsafe_range_check,noalias=bmp)]
def public rast_fillRect ( var bmp:Bitmap8#; x,y,w,h:int; color:uint8 )
    let xmin = max(0,x)
    let xmax = min(bmp.size.x,x+w)
    if xmax <= xmin
        return
    let ymin = max(0,y)
    let ymax = min(bmp.size.y,y+h)
    if ymax <= ymin
        return
    let H = ymax-ymin
    for X in range(xmin,xmax)
        unsafe
            memset8(addr(bmp.data[X*bmp.size.y+y]),color,H)
