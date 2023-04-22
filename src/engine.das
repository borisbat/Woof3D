module engine

require files
require game
require rast2d
require entities

require math

let DRAW_PLAYER_POSITION = false

let DRAW_VISIBILITY = false

let DRAW_COLLISION = false

def drawWalls ( level:Level; var bmp:Bitmap8# )
    for i in range(bmp.size.x)
        // current column position on the camera plane
        let shift = fov * (float(i << 1) - pixelWidth) / (pixelWidth)
        // direction of the ray
        var dx = player.dir.x - shift * player.dir.y
        var dy = player.dir.y + shift * player.dir.x
        var tres = trace(player.pos.x,player.pos.y,dx,dy,FLT_MAX,true)
        zIndex[i] = tres.t
        lock_u8(WallPics[tres.textureIndex].data) <| $ ( tex )
            drawWallPixels(i,tres.t,tres.tx,tex,bmp) // causes bug in jit. why?

def drawWallPixels ( i:int; t,tx:float; tex:array<uint8>#; var bmp:Bitmap8# )
    var h = wallHeight / (2. * t)
    let y = floori(pixelHeight / 2. - h)
    let ymin = max(0, y)
    let ymax = min(floori(pixelHeight / 2. + h), bmp.size.y)
    let dh = 0.5 /  (h+1.)
    var uvY = (float(ymin - y) * dh) * 64.0
    let dUVY = dh * 64.0
    let texelOffset = 64 * floori(63. * clamp(tx,0.,1.))
    rast_hspan(bmp.data,i*bmp.size.y+ymin,tex,texelOffset,uvY,dUVY,ymax-ymin)

def isVisible(x,y:float)
    let f = floori(float2(x,y)-float2(0.45))
    let t = floori(float2(x,y)+float2(0.45))
    for Y in range(f.y,t.y+1)
        for X in range(f.x,t.x+1)
            if visibility_plane[X][Y]
                return true
    return false

def drawThings ( var bmp:Bitmap8# )
    var things : array<Entity?>
    things |> reserve ( enemies|>length + objects|>length )
    for enemy in enemies
        var prc = getPlayerRelativeCoordinates(enemy.pos)
        if prc.rpos.x>0.05 && abs(prc.rpos.y)<prc.rpos.x + 1.
            let epos = floori(enemy.pos)
            if visibility_plane[epos.x][epos.y]
                enemy.prc = prc
                things |> push ( enemy )
    for object in objects
        var prc = getPlayerRelativeCoordinates(object.pos)
        if prc.rpos.x>0.05 && abs(prc.rpos.y)<prc.rpos.x + 1.
            let opos = floori(object.pos)
            if visibility_plane[opos.x][opos.y]
                object.prc = prc
                things |> push ( object )
    things |> sort <| $ ( a,b : Entity? )
        if a.category != b.category
            let ai = floori(a.pos)
            let bi = floori(b.pos)
            if ai==bi
                return int(a.category) < int(b.category)
        return a.prc.rpos.x > b.prc.rpos.x
    for thing in things
        drawThing(thing.prc.rpos.x,thing.prc.rpos.y,thing.prc.opos.x,thing.prc.opos.y,*thing,bmp)

def getEntityAngle( Direction : float2 ) : int
    var EntityAngle = floori((8.0f * atan2(Direction.y, Direction.x) / (2.0f * PI)) + 0.5f)
    if EntityAngle < 0
        EntityAngle = 8 - ((-EntityAngle) & 7)
    return EntityAngle & 7

def drawThing(rx,ry,orx,ory:float; OBJ:Entity; var bmp:Bitmap8# )
    // draw
    let th = wallHeight / rx
    let tx = floori((ry / rx + fov) * wallHeight - th / 2.)
    let ty = floori((pixelHeight - th) / 2.)
    var index = OBJ.spriteIndex
    if OBJ.orientable && (OBJ.animation==null || OBJ.animation.orientable)
        let PlayerAngle = getEntityAngle(float2(orx,ory))
        var Angle = getEntityAngle(OBJ.dir)
        index = OBJ.spriteIndex + (Angle - PlayerAngle + 12) % 8
    drawSprite(tx, ty, th, rx, Sprites[index], bmp)

def drawSprite ( x,y: int; h:float; dist:float; sprite:SpriteTexture; var bmp:Bitmap8# )
    lock(sprite.data) <| $ ( tspan )
        let height = int(h)
        let xmin = max(0, x)
        let xmax = min(x+height, bmp.size.x-1)
        if xmin > xmax
            return
        let dh = 1. /  (h+1.)
        var uvX = (float(xmin - x) * dh) * 64.0
        let dUVX = dh * 64.0
        for X in range(xmin,xmax)
            if zIndex[X]>dist
                let col = int(uvX)
                if col >= sprite.firstCol && col <= sprite.lastCol
                    var pixelOffset = sprite.pixelOffset[col]
                    var colOffset = sprite.colOffset[col]
                    while true
                        let endRow = sprite.spans[colOffset].endRow
                        if endRow == 0
                            break
                        let startRow = sprite.spans[colOffset].startRow
                        colOffset ++
                        let ystart = y + floori(float(startRow) * h / 64.)
                        let ymin = max(ystart, 0)
                        let ymax = min(y + floori(float(endRow) * h / 64.), bmp.size.y-1)
                        if ymin < ymax
                            var uv0 = float(ymin - ystart) * dUVX
                            rast_hspan(bmp.data,X*bmp.size.y+ymin,tspan,pixelOffset,uv0,dUVX,ymax-ymin)
                        pixelOffset += endRow - startRow
            uvX += dUVX

def draw2DElement ( x,y,w,h:int; var pic:Picture; var bmp:Bitmap8# )
    var u = 0.
    let du = 1. / float(w+1)
    let dv = 1. / float(h+1)
    var DV = dv * float(pic.height)
    lock(pic.data) <| $ ( tspan )
        for X in range(x,x+w)
            let px = floori(u * float(pic.width))
            rast_hspan(bmp.data,y+X*bmp.size.y,tspan,px*pic.height,0.,DV,h)
            u += du

def drawBackground ( var bmp:Bitmap8# )
    let h = bmp.size.y / 2
    rast_fillRect(bmp,0,0,bmp.size.x,h,29u8)
    rast_fillRect(bmp,0,h,bmp.size.x,h,25u8)

def drawWeapon ( var bmp:Bitmap8# )
    let height = bmp.size.y
    drawSprite(
            bmp.size.x / 2 - height / 2,
            0,
            float(height),
            0.,
            Sprites[player.weaponSprite],
            bmp)

var hudFactor = 1.

def drawHUDElement(x,y,w,h:int; var pic:Picture; var bmp:Bitmap8# )
    var minx = max(floori(float(x)*hudFactor), 0)
    var maxx = min(floori(float(x+w)*hudFactor), bmp.size.x)
    var miny = max(floori(float(y)*hudFactor), 0)
    var maxy = min(floori(float(y+h)*hudFactor), bmp.size.y)
    if minx>maxx || miny>maxy
        return
    draw2DElement(minx,miny,maxx-minx,maxy-miny,pic,bmp)

def drawHUDNum(x,y:int; num:int; var bmp:Bitmap8# )
    let txt = "{num}"
    for Ch,i in txt,count()
        drawHUDElement(x+i*8,y,8,16,Pictures[Ch-'0'+105],bmp)

def getHUDCharSpriteIndex ( chu:int )
    if chu==':'
        return 50
    elif chu>='0' && chu<='9'
        return chu-'0'+51
    elif chu=='%'
        return 61
    elif chu>='A' && chu<='Z'
        return chu-'A'+62
    elif chu>='a' && chu<='z'
        return chu-'a'+62
    elif chu=='!'
        return 88
    elif chu==39    // '
        return 89
    else
        return 0

def getHUDTextDim(text:string) : tuple<width:int;height:int>
    var X = 0
    var H = 0
    for chu in text
        if chu==' '
            X += 8
            continue
        var index = getHUDCharSpriteIndex(chu)
        if index==0
            continue
        H = max(H,Pictures[index].height)
        X += Pictures[index].width
    return [[auto X,H]]

def drawHUDText(x,y:int; text:string; var bmp:Bitmap8# )
    var X = x
    for chu in text
        if chu==' '
            X += 8
            continue
        var index = getHUDCharSpriteIndex(chu)
        if index==0
            continue
        let W = Pictures[index].width
        drawHUDElement(X,y,W,Pictures[index].height,Pictures[index],bmp)
        X += W

def drawHUD ( var bmp:Bitmap8# )
    // health head (24x32)
    var frame = 0
    if playerHealth <= 0.
        frame = 136  // dead
    elif playerHealth > 1.
        frame = 137 // >100%
    else
        let hpIndex = floori(6.*clamp(1.-playerHealth,0.,1.))
        frame = floori(playerHoodTime * 3.) + hpIndex*3 + 115
    drawHUDElement(1,200-33,24,32,Pictures[frame],bmp)
    // gold and silver keys (8x16)
    if player.goldKey
        drawHUDElement(1+24,200-33,8,16,Pictures[102],bmp)
    if player.silverKey
        drawHUDElement(1+24+8,200-33,8,16,Pictures[103],bmp)
    // ammo
    drawHUDNum(1+24,200-17,player.ammo,bmp)
    // hud
    if !empty(hudMessage)
        let dim = getHUDTextDim(hudMessage)
        drawHUDText(160-dim.width/2,2,hudMessage,bmp)

def drawVisibility ( var bmp:Bitmap8# )
    for x in range(64)
        for y in range(64)
            var col = visibility_plane[x][y] ? 0u8 : 255u8
            rast_fillRect(bmp,bmp.size.y - 64*4 - 10 + x*4,10 + y*4,4,4,col)
    for e in enemies
        if e.category == Category enemy
            rast_fillRect(bmp,bmp.size.y - 64*4 - 10 + floori(e.pos.x)*4,10 + floori(e.pos.y)*4,4,4,32u8)

def drawCollision ( var bmp:Bitmap8# )
    for x in range(64)
        for y in range(64)
            var col = collision_plane[x][y] ? 0u8 : 255u8
            rast_fillRect(bmp, bmp.size.y - 64*4 - 10 + x*4,10 + y*4,4,4,col)
    for e in enemies
        if e.category == Category enemy
            rast_fillRect(bmp, bmp.size.y - 64*4 - 10 + floori(e.pos.x)*4,10 + floori(e.pos.y)*4,4,4,32u8)

def draw ( level:Level; var bmp:Bitmap8# )
    hudFactor = max(float(bmp.size.y)/200.,1.)
    pixelWidth = float(bmp.size.x)
    pixelHeight = float(bmp.size.y)
    wallHeight = float(pixelWidth) / (2. * fov)
    zIndex |> resize(bmp.size.x)
    for vy in visibility_plane
        for v in vy
            v = false
    drawBackground(bmp)
    drawWalls(level, bmp)
    drawThings(bmp)
    if dLevelFade == 0.
        drawWeapon(bmp)
        drawHUD(bmp)
    if DRAW_VISIBILITY
        drawVisibility(bmp)
    if DRAW_COLLISION
        drawCollision(bmp)
    if DRAW_PLAYER_POSITION
        let text = "{floori(player.x)} {floori(player.y)}"
        let dim = getHUDTextDim(text)
        drawHUDText(160-dim.width/2,200-16,text,bmp)



