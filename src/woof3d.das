module woof3d

require math
require fio
require strings

require daslib/array_boost
require daslib/random
require daslib/algorithm
require daslib/raster_boost
require daslib/jobque_boost

require medialib/dasbox_sound_utils
require medialib/opl3

// -------------------- global configuation --------------------

let WL6_FILES_ROOT = "../data"

let ENABLE_CHEAT_CODEDS = true
let ENABLE_HINT_SECRET_WALLS = true
let ENABLE_MAP = true

let MOUSE_SENSETIVITY = 0.2

// -------------------- application --------------------

class Application
    // controls
    shootButton : bool
    activateButton : bool
    weapon1Button : bool
    weapon2Button : bool
    weapon3Button : bool
    weapon4Button : bool
    leftButton : bool
    rightButton : bool
    forwardButton : bool
    backwardButton : bool
    strafeLeftButton : bool
    strafeRightButton : bool
    mapButton : bool
    // mouse
    mouseDelta : float2
    // cheat codes
    cheatGiveEverything : bool
    cheat1 : bool                   // spawn enemy?
    cheat2 : bool                   // spawn obstacle?
    cheat3 : bool                   // teleport player to interesting place?
    cheatSwitchLevel : bool         // any switch to next level
    cheatSwitchLevelShift : bool    // switch to specific level (shift pressed?)
    // button pressed
    okButtonPressed : bool
    cancelButtonPressed : bool
    upButtonPressed : bool
    downButtonPressed : bool

    def abstract play_app_music ( wave:array<float2>; freq:int ) : void
    def abstract play_app_sound ( wave:array<float>; freq:int ) : void
    def abstract play_app_sound_2d ( pos:float2; radius:float; wave:array<float>; freq:int ) : void
    def abstract set_palette ( pal : uint[256] ) : void
    def abstract set_app_sound_position ( xy:float2; dxy:float2 ) : void
    def abstract quit : void

var application : Application?

// -------------------- resource files --------------------

let USE_ADLIB = true
let SOUND_SAMPLE_RATE = 7000
let ADLIB_SAMPLE_RATE = 44100
let MUSIC_SAMPLE_RATE = 44100

let TOTAL_LEVELS = 60

let HUFFMAN_TREE_NODE_COUNT = 255
let HUFFMAN_TREE_ROOT = 254

let NUMBER_OF_PIC_CHUNKS = 149

let NUMSOUNDS = 87
let NUMMUS = 26
let STARTPCSOUNDS = 0
let STARTADLIBSOUNDS = 87
let STARTDIGISOUNDS = 174
let STARTMUSIC = 261
let PC_RATE = 140
let PC_BASE_TIMER = 1193181
let PC_VOLUME = 20

let PIC_COUNT = 141
let PIC_STARTS = 3
let PIC_ENDS = 134

var at_app_start = false

let ElevatorBackTo = [[auto 1;1;7;3;5;3]]

struct HuffmanNode
    node_0, node_1 : int

var HuffmanTree : HuffmanNode[HUFFMAN_TREE_NODE_COUNT]

var rlewTag : uint16
var mapHead : uint[TOTAL_LEVELS]

struct Level
    plane0 : int[64][64]
    plane1 : int[64][64]

var Levels : Level[TOTAL_LEVELS]

struct WallTexture
    data : uint8[64*64]

var WallPics : array<WallTexture>

struct SpriteSpan
    endRow   : int
    startRow : int

struct SpriteTexture
    data : array<uint8>
    firstCol, lastCol : int
    colOffset : int[64]
    pixelOffset : int[64]
    spans : array<SpriteSpan>

var Sprites : array<SpriteTexture>

struct Sound
    data : array<uint8>

var Sounds : array<Sound>

var Audio : array<Sound>

struct AdlibSound
    data : array<uint16>

var AdlibAudio : array<AdlibSound>

struct AdlibMusic
    data : array<uint16>    // stereo

var Music : array<AdlibMusic>

var PicOffsets : int[NUMBER_OF_PIC_CHUNKS]

struct Picture
    width, height : int
    texels : array<uint8>
    data : array<uint8>

var Pictures : array<Picture>

struct Font
    height : int
    width : int[256]
    letters : Picture? [256]

var Fonts : array<Font>

let GamePalette = [[uint
    0xff000000; 0xffa80000; 0xff00a800; 0xffa8a800; 0xff0000a8; 0xffa800a8; 0xff0054a8; 0xffa8a8a8;
    0xff545454; 0xfffc5454; 0xff54fc54; 0xfffcfc54; 0xff5454fc; 0xfffc54fc; 0xff54fcfc; 0xfffcfcfc;
    0xffececec; 0xffdcdcdc; 0xffd0d0d0; 0xffc0c0c0; 0xffb4b4b4; 0xffa8a8a8; 0xff989898; 0xff8c8c8c;
    0xff7c7c7c; 0xff707070; 0xff646464; 0xff545454; 0xff484848; 0xff383838; 0xff2c2c2c; 0xff202020;
    0xff0000fc; 0xff0000ec; 0xff0000e0; 0xff0000d4; 0xff0000c8; 0xff0000bc; 0xff0000b0; 0xff0000a4;
    0xff000098; 0xff000088; 0xff00007c; 0xff000070; 0xff000064; 0xff000058; 0xff00004c; 0xff000040;
    0xffd8d8fc; 0xffb8b8fc; 0xff9c9cfc; 0xff7c7cfc; 0xff5c5cfc; 0xff4040fc; 0xff2020fc; 0xff0000fc;
    0xff5ca8fc; 0xff4098fc; 0xff2088fc; 0xff0078fc; 0xff006ce4; 0xff0060cc; 0xff0054b4; 0xff004c9c;
    0xffd8fcfc; 0xffb8fcfc; 0xff9cfcfc; 0xff7cfcfc; 0xff5cf8fc; 0xff40f4fc; 0xff20f4fc; 0xff00f4fc;
    0xff00d8e4; 0xff00c4cc; 0xff00acb4; 0xff009c9c; 0xff008484; 0xff006c70; 0xff005458; 0xff004040;
    0xff5cfcd0; 0xff40fcc4; 0xff20fcb4; 0xff00fca0; 0xff00e490; 0xff00cc80; 0xff00b474; 0xff009c60;
    0xffd8fcd8; 0xffb8fcbc; 0xff9cfc9c; 0xff7cfc80; 0xff5cfc60; 0xff40fc40; 0xff20fc20; 0xff00fc00;
    0xff00fc00; 0xff00ec00; 0xff00e000; 0xff00d400; 0xff00c804; 0xff00bc04; 0xff00b004; 0xff00a404;
    0xff009804; 0xff008804; 0xff007c04; 0xff007004; 0xff006404; 0xff005804; 0xff004c04; 0xff004004;
    0xfffcfcd8; 0xfffcfcb8; 0xfffcfc9c; 0xfff8fc7c; 0xfffcfc5c; 0xfffcfc40; 0xfffcfc20; 0xfffcfc00;
    0xffe4e400; 0xffcccc00; 0xffb4b400; 0xff9c9c00; 0xff848400; 0xff707000; 0xff585800; 0xff404000;
    0xfffcbc5c; 0xfffcb040; 0xfffca820; 0xfffc9c00; 0xffe48c00; 0xffcc7c00; 0xffb46c00; 0xff9c5c00;
    0xfffcd8d8; 0xfffcbcb8; 0xfffc9c9c; 0xfffc807c; 0xfffc605c; 0xfffc4040; 0xfffc2420; 0xfffc0400;
    0xfffc0000; 0xffec0000; 0xffe00000; 0xffd40000; 0xffc80000; 0xffbc0000; 0xffb00000; 0xffa40000;
    0xff980000; 0xff880000; 0xff7c0000; 0xff700000; 0xff640000; 0xff580000; 0xff4c0000; 0xff400000;
    0xff282828; 0xff34e0fc; 0xff24d4fc; 0xff18ccfc; 0xff08c0fc; 0xff00b4fc; 0xfffc20b4; 0xfffc00a8;
    0xffe40098; 0xffcc0080; 0xffb40074; 0xff9c0060; 0xff840050; 0xff700044; 0xff580034; 0xff400028;
    0xfffcd8fc; 0xfffcb8fc; 0xfffc9cfc; 0xfffc7cfc; 0xfffc5cfc; 0xfffc40fc; 0xfffc20fc; 0xfffc00fc;
    0xffe400e0; 0xffcc00c8; 0xffb400b4; 0xff9c009c; 0xff840084; 0xff70006c; 0xff580058; 0xff400040;
    0xffdce8fc; 0xffd0e0fc; 0xffc4d8fc; 0xffbcd4fc; 0xffb0ccfc; 0xffa4c4fc; 0xff9cbcfc; 0xff90b8fc;
    0xff80b0fc; 0xff70a4fc; 0xff609cfc; 0xff5c94f0; 0xff588ce8; 0xff5488dc; 0xff5080d0; 0xff4c7cc8;
    0xff4878bc; 0xff4470b4; 0xff4068a8; 0xff3c64a0; 0xff38609c; 0xff345c90; 0xff305888; 0xff2c5080;
    0xff284c74; 0xff24486c; 0xff20405c; 0xff1c3c54; 0xff183848; 0xff183040; 0xff142c38; 0xff0c2028;
    0xff640060; 0xff646400; 0xff606000; 0xff1c0000; 0xff2c0000; 0xff102430; 0xff480048; 0xff500050;
    0xff340000; 0xff1c1c1c; 0xff4c4c4c; 0xff5c5c5c; 0xff404040; 0xff303030; 0xff343434; 0xfff4f4d8;
    0xffe8e8b8; 0xffdcdc9c; 0xffc8c874; 0xffc0c048; 0xffb4b420; 0xffb0b020; 0xffa4a400; 0xff989800;
    0xff8c8c00; 0xff848400; 0xff7c7c00; 0xff787800; 0xff747400; 0xff707000; 0xff6c6c00; 0xff880098]]

let ceilingColors = [[auto
    0x1d;0x1d;0x1d;0x1d;0x1d;0x1d;0x1d;0x1d;0x1d;0xbf;
    0x4e;0x4e;0x4e;0x1d;0x8d;0x4e;0x1d;0x2d;0x1d;0x8d;
    0x1d;0x1d;0x1d;0x1d;0x1d;0x2d;0xdd;0x1d;0x1d;0x98;
    0x1d;0x9d;0x2d;0xdd;0xdd;0x9d;0x2d;0x4d;0x1d;0xdd;
    0x7d;0x1d;0x2d;0x2d;0xdd;0xd7;0x1d;0x1d;0x1d;0x2d;
    0x1d;0x1d;0x1d;0x1d;0xdd;0xdd;0x7d;0xdd;0xdd;0xdd
]]

enum PictureIndex
    NONE = -1
    WOFLENSTEIN = 10
    ID_LOGO = 13
    OPTIONS = 18
    CURSOR_A = 19
    CURSOR_B = 20
    CHECKBOX_UNCHECKED = 21
    CHECKBOX_CHECKED = 22
    MENU_HINT = 26
    DIFFICULTY_1 = 27
    DIFFICULTY_2 = 28
    DIFFICULTY_3 = 29
    DIFFICULTY_4 = 30
    EPISODE_1 = 38
    EPISODE_2 = 39
    EPISODE_3 = 40
    EPISODE_4 = 41
    EPISODE_5 = 42
    EPISODE_6 = 43
    TITLE_SCREEN = 93
    PC13_LOGO = 94
    CREDITS_SCREEN = 95

enum Color : uint8
    RED_VERY_DARK = 47u8
    RED_DARK = 46u8
    RED_BACKGROUND = 45u8
    RED_4 = 44u8
    RED_5 = 43u8
    RED_6 = 42u8
    RED_7 = 41u8
    RED_8 = 40u8
    RED_9 = 39u8
    RED_10 = 4u8
    RED_11 = 38u8
    RED_12 = 37u8
    RED_13 = 36u8
    RED_14 = 35u8
    RED_15 = 34u8
    RED_16 = 33u8
    RED_17 = 32u8
    LIGHT_CYAN = 3u8
    LIGHT_GREY = 7u8
    VERY_LIGHT_GREY = 16u8
    DARK_GREY = 8u8
    BACKGROUND_RED = 45u8
    YELLOW = 71u8
    DARK_YELLOW = 6u8
    BRIGHT_YELLOW = 235u8
    VERY_DARK_BLUE = 227u8

def LoadBytes ( filename : string )
    var bytes : array<uint8>
    fopen("{WL6_FILES_ROOT}/{filename}", "rb") <| $ ( fr )
        fmap(fr) <| $ ( data )
            bytes := data
    if empty(bytes)
        panic("failed to load file: {filename}")
    return <- bytes

def getUInt8 ( bytes : array<uint8>; offset : int ) : uint8
    return bytes[offset]

def getUInt8 ( bytes : array<uint8>#; offset : int ) : uint8
    return bytes[offset]

def getUInt16 ( bytes : array<uint8>; offset : int ) : uint16
    return uint16(uint(bytes[offset]) + (uint(bytes[offset+1]) << 8u))

def getUInt16 ( bytes : array<uint8>#; offset : int ) : uint16
    return uint16(uint(bytes[offset]) + (uint(bytes[offset+1]) << 8u))

def getUInt32 ( bytes : array<uint8>; offset : int ) : uint
    return uint(bytes[offset]) + (uint(bytes[offset+1]) << 8u) + (uint(bytes[offset+2]) << 16u) + (uint(bytes[offset+3]) << 24u)

def getUInt32 ( bytes : array<uint8>#; offset : int ) : uint
    return uint(bytes[offset]) + (uint(bytes[offset+1]) << 8u) + (uint(bytes[offset+2]) << 16u) + (uint(bytes[offset+3]) << 24u)

def setUInt8 ( var bytes : array<uint8>; offset : int; value : uint8 )
    bytes[offset] = value

def setUInt16 ( var bytes : array<uint8>; offset : int; value : uint16 )
    bytes[offset] = uint8(uint(value) & 0xFFu)
    bytes[offset+1] = uint8((uint(value) >> 8u) & 0xFFu)

def rlewDecode ( bytes : array<uint8> )
    var buffer : array<uint16>
    let rlewSize = getUInt16(bytes, 0)
    buffer |> resize(int(rlewSize)/2)
    var inOffset = 2
    var outOffset = 0
    let bytesSize = bytes |> length
    while inOffset < bytesSize
        var w = getUInt16(bytes, inOffset)
        inOffset += 2
        if w == rlewTag
            var n = getUInt16(bytes, inOffset)
            var x = getUInt16(bytes, inOffset + 2)
            inOffset += 4
            for i in range(uint(n))
                buffer[outOffset] = x
                outOffset ++
        else
            buffer[outOffset] = w
            outOffset++
    return <- buffer

def carmackDecode ( bytes : array<uint8># )
    let size = getUInt16(bytes, 0)
    var outView : array<uint8>
    outView |> resize(int(size))
    var inOffset = 2
    var outOffset = 0
    let bytesSize = bytes |> length
    while inOffset < bytesSize
        let x = getUInt8(bytes, inOffset + 1)
        if x == 0xA7u8 || x == 0xA8u8
            // possibly a pointer
            var n = getUInt8(bytes, inOffset)
            if n == 0u8
                // exception (not really a pointer)
                setUInt8(outView, outOffset, getUInt8(bytes, inOffset + 2))
                setUInt8(outView, outOffset + 1, x)
                inOffset += 3
                outOffset += 2
            elif x == 0xA7u8
                // near pointer
                let offset = 2 * int(getUInt8(bytes, inOffset + 2))
                for i in range(uint(n))
                    setUInt16(outView, outOffset, getUInt16(outView, outOffset - offset))
                    outOffset += 2
                inOffset += 3
            else
                // far pointer
                let offset = 2 * int(getUInt16(bytes, inOffset + 2))
                for i in range(uint(n))
                    setUInt16(outView, outOffset, getUInt16(outView, offset + 2 * i))
                    outOffset += 2
                inOffset += 4
        else
            // not a pointer
            setUInt16(outView, outOffset, getUInt16(bytes, inOffset))
            inOffset += 2
            outOffset += 2
    return <- outView

def InitMapHead()
    var bytes <- LoadBytes("MAPHEAD.WL6")
    rlewTag = bytes |> getUInt16(0)
    assert(uint(rlewTag) == 0xABCD, "invalid rlew tag")
    for i in range(TOTAL_LEVELS)
        mapHead[i] = bytes |> getUInt32(2 + i*4)

def InitGameMap()
    var bytes <- LoadBytes("GAMEMAPS.WL6")
    for level in range(TOTAL_LEVELS)
        let offset = mapHead[level]
        array_view(bytes, int(offset), 42) <| $ ( header )
            let plane0Offset = header |> getUInt32(0)
            let plane0Size = header |> getUInt16(12)
            let plane1Offset = header |> getUInt32(4)
            let plane1Size = header |> getUInt16(14)
            array_view(bytes, int(plane0Offset), int(plane0Size)) <| $ ( plane0View )
                var cdec <- carmackDecode(plane0View)
                var rdec <- rlewDecode(cdec)
                for x in range(64)
                    for y in range(64)
                        Levels[level].plane0[x][y] = int(rdec[x+y*64])
            array_view(bytes, int(plane1Offset), int(plane1Size)) <| $ ( plane1View )
                var cdec <- carmackDecode(plane1View)
                var rdec <- rlewDecode(cdec)
                for x in range(64)
                    for y in range(64)
                        Levels[level].plane1[x][y] = int(rdec[x+y*64])

def prepareSprite ( var sprite : SpriteTexture )
    sprite.firstCol = int(sprite.data |> getUInt16(0))
    sprite.lastCol = int(sprite.data |> getUInt16(2))
    let nbCol = sprite.lastCol - sprite.firstCol + 1
    var pixelOffset = 4 + 2 * nbCol
    for col in range(sprite.firstCol, sprite.lastCol + 1)
        var colOffset = int(sprite.data |> getUInt16(4 + 2 * (col - sprite.firstCol)))
        sprite.pixelOffset[col] = pixelOffset
        sprite.colOffset[col] = sprite.spans |> length
        while true
            let endRow = int(sprite.data |> getUInt16(colOffset)) / 2
            if endRow == 0
                sprite.spans |> push([[SpriteSpan startRow=0, endRow=0]])
                break
            let startRow = int(sprite.data |> getUInt16(colOffset + 4)) / 2
            sprite.spans |> push([[SpriteSpan startRow=startRow, endRow=endRow]])
            colOffset += 6
            for row in range(startRow, endRow)
                pixelOffset ++

def InitResources()
    var bytes <- LoadBytes("VSWAP.WL6")
    let totalChunks = int(getUInt16(bytes, 0))
    let firstSpriteChunk = int(getUInt16(bytes, 2))
    let wallChunks = firstSpriteChunk
    let firstSoundChunk = int(getUInt16(bytes, 4))
    let spriteChunks = firstSoundChunk - firstSpriteChunk
    let soundChunks = totalChunks - firstSoundChunk
    WallPics |> resize(wallChunks)
    let wallsOffset = getUInt32(bytes, 6)
    for i in range(wallChunks)
        let wallSize = int(bytes |> getUInt16(6 + totalChunks*4 + i*2))
        array_view(bytes, int(wallsOffset) + i*4096, 4096) <| $ ( view )
            for s,d in view, WallPics[i].data
                d = s
    Sprites |> resize(spriteChunks)
    for i in range(spriteChunks)
        let spriteOffset = int(getUInt32(bytes, 6 + (firstSpriteChunk + i)*4))
        let spriteSize = int(bytes |> getUInt16(6 + totalChunks*4 + (firstSpriteChunk + i)*2))
        array_view(bytes, spriteOffset, spriteSize) <| $ ( view )
            Sprites[i].data := view
            prepareSprite(Sprites[i])
    Sounds |> resize(soundChunks)
    for i in range(soundChunks)
        let soundOffset = int(getUInt32(bytes, 6 + (firstSoundChunk + i)*4))
        let soundSize = int(bytes |> getUInt16(6 + totalChunks*4 + (firstSoundChunk + i)*2))
        array_view(bytes, soundOffset, soundSize) <| $ ( view )
            Sounds[i].data := view

def convertPcSoundToWave ( src:array<uint8>#; hertz:int )
    var dst : array<uint8>
    dst |> resize(src |> length * hertz / PC_RATE)
    var dstOut = 0
    var sign = -1
    var phase_tic = 0
    for tone in src
        let phase_length = (hertz * int(tone) * 60) / (2 * PC_BASE_TIMER)
        for i in range(hertz / PC_RATE)
            if tone != 0u8
                dst[dstOut++] = uint8(128 + sign * PC_VOLUME)
                if phase_tic >= phase_length
                    sign = -sign
                    phase_tic = 0
                phase_tic += 1
            else
                phase_tic = 0
                dst[dstOut++] = 128u8
    return <- dst

var private chip : Opl3Chip

def convertAdlibToWave ( src:array<uint8> | #; hertz:int )
    let ldata = int(getUInt32(src, 0))
    let instrument_offset = 6
    var data : array<uint16>
    OPL3_Reset(chip, hertz)
    OPL3_WriteReg ( chip, 0x20, src[instrument_offset+0] )    // mChar
    OPL3_WriteReg ( chip, 0x40, src[instrument_offset+2] )    // mScale
    OPL3_WriteReg ( chip, 0x60, src[instrument_offset+4] )    // mAttack
    OPL3_WriteReg ( chip, 0x80, src[instrument_offset+6] )    // mSust
    OPL3_WriteReg ( chip, 0xE0, src[instrument_offset+8] )    // mWave
    OPL3_WriteReg ( chip, 0x23, src[instrument_offset+1] )    // cChar
    OPL3_WriteReg ( chip, 0x43, src[instrument_offset+3] )    // cScale
    OPL3_WriteReg ( chip, 0x63, src[instrument_offset+5] )    // cAttack
    OPL3_WriteReg ( chip, 0x83, src[instrument_offset+7] )    // cSust
    OPL3_WriteReg ( chip, 0xE3, src[instrument_offset+9] )    // cWave
    // OPL3_WriteReg ( chip, 0xC0, src[instrument_offset+10] )   // nConn
    OPL3_WriteReg ( chip, 0xC0, 0u8 )   // nConn
    let blk = (uint(src[instrument_offset+16+1]) & 7u) << 2u
    var note = false
    let bytes = hertz / 140 // we write in 140hz chunks
    for i in range(ldata)
        let nb = src[i + instrument_offset + 16 + 2]
        if nb==0u8
            OPL3_WriteReg ( chip, 0xB0, uint8(blk) )
            note = false
        else
            OPL3_WriteReg ( chip, 0xA0, nb )
            if !note
                OPL3_WriteReg ( chip, 0xB0, uint8(blk | 0x20) )
                note = true
        var tmp : array<uint16>
        tmp |> resize_no_init(bytes)
        OPL3_GenerateStreamMono(chip, tmp)
        let ld = length(data)
        data |> resize ( length(data) + bytes )
        for t,tb in count(),tmp
            data[ld+t] = tb
    return <- data

def convertIMFToWave ( src:array<uint8> | #; hertz:int )
    var data : array<uint16>
    let llength = int(getUInt16(src, 0))
    OPL3_Reset(chip, hertz)
    let delay_1 = hertz / 700
    for i in range(llength/4)
        let reg = src |> getUInt8(2+i*4+0)
        let rdata = src |> getUInt8(2+i*4+1)
        let delay = int(src |> getUInt16(2+i*4+2))
        if reg != 0u8
            OPL3_WriteReg ( chip, uint(reg), rdata )
        if delay != 0
            let samples = delay * delay_1 * 2
            var tmp : array<uint16>
            tmp |> resize_no_init(samples)
            OPL3_GenerateStream(chip, tmp)
            let ld = length(data)
            data |> resize ( length(data) + samples )
            for t,tb in count(),tmp
                data[ld+t] = tb
    return <- data

struct AudioData
    index : int
    data : array<uint16>

def InitAudio()
    with_job_que <|
        var audioHeader <- LoadBytes("AUDIOHED.WL6")
        var audioData <- LoadBytes("AUDIOT.WL6")
        for i in range(NUMSOUNDS)
            let offset = getUInt32(audioHeader, (i+STARTPCSOUNDS)*4)
            let size = getUInt32(audioHeader, (i+1+STARTPCSOUNDS)*4) - offset
            array_view(audioData, int(offset), int(size)) <| $ ( view )
                var snd <- [[Sound data <- convertPcSoundToWave(view, SOUND_SAMPLE_RATE)]]
                Audio |> emplace(snd)
        with_channel(NUMSOUNDS) <| $ ( channel )
            for i in range(NUMSOUNDS)
                let offset = getUInt32(audioHeader, (i+STARTADLIBSOUNDS)*4)
                let size = getUInt32(audioHeader, (i+1+STARTADLIBSOUNDS)*4) - offset
                array_view(audioData, int(offset), int(size)) <| $ ( view )
                    var cdata : array<uint8> := view
                    new_job <| @ [[:=cdata]]
                        var wave <- convertAdlibToWave(cdata, ADLIB_SAMPLE_RATE)
                        delete cdata
                        channel |> push_clone ( [[AudioData index=i, data<-wave]] )
                        channel |> notify_and_release
                    delete cdata
            AdlibAudio |> resize(NUMSOUNDS)
            for jb in each(channel,type<AudioData>)
                AdlibAudio[jb.index].data := jb.data
        with_channel(NUMMUS) <| $ ( channel )
            for i in range(NUMMUS)
                let offset = getUInt32(audioHeader, (i+STARTMUSIC)*4)
                let size = getUInt32(audioHeader, (i+1+STARTMUSIC)*4) - offset
                array_view(audioData, int(offset), int(size)) <| $ ( view )
                    var cdata : array<uint8> := view
                    new_job <| @ [[:=cdata]]
                        var wave <- convertIMFToWave(cdata, MUSIC_SAMPLE_RATE)
                        delete cdata
                        channel |> push_clone ( [[AudioData index=i, data<-wave]] )
                        channel |> notify_and_release
                    delete cdata
            Music |> resize(NUMMUS)
            for jb in each(channel,type<AudioData>)
                Music[jb.index].data := jb.data

def InitHuffmanTree
    var bytes <- LoadBytes("VGADICT.WL6")
    for n in range(HUFFMAN_TREE_NODE_COUNT)
        HuffmanTree[n].node_0 = int(bytes |> getUInt16(n*4))
        HuffmanTree[n].node_1 = int(bytes |> getUInt16(n*4+2))

def InitPicOffsets
    var bytes <- LoadBytes("VGAHEAD.WL6")
    for n in range(NUMBER_OF_PIC_CHUNKS)
        let b0 = int(bytes |> getUInt8(n*3))
        let b1 = int(bytes |> getUInt8(n*3+1))
        let b2 = int(bytes |> getUInt8(n*3+2))
        let ofs = b0 + (b1 << 8) + (b2 << 16)
        PicOffsets[n] = ofs!=int(0x00ffffff) ? ofs : -1

def huffman_expand ( src:array<uint8>#; length:int )
    var dst : array<uint8>
    dst |> resize(length)
    var read = 0
    var write = 0
    var mask = 0x01
    var input = src[read++]
    var node_value = 0
    var node = HUFFMAN_TREE_ROOT
    while true
        if (uint(input) & mask) == 0u
            node_value = HuffmanTree[node].node_0
        else
            node_value = HuffmanTree[node].node_1
        if mask == 0x80
            mask = 0x01
            input = src[read++]
        else
            mask <<= 1u
        if node_value <= int(0xff)
            dst[write++] = uint8(node_value)
            node = HUFFMAN_TREE_ROOT
            if write == length
                break
        else
            node = node_value - 256
    return <- dst

def ExtractPic ( bytes:array<uint8>; magic_number:int; var expand_length:int& )
    var next_index = magic_number + 1
    while PicOffsets[next_index] == -1 && next_index < PIC_COUNT
        next_index += 1
    var compressed_length = PicOffsets[next_index] - PicOffsets[magic_number]
    expand_length = int(bytes |> getUInt32(PicOffsets[magic_number]))
    var texels : array<uint8>
    array_view(bytes, PicOffsets[magic_number]+4, compressed_length) <| $ ( view )
        texels <- huffman_expand(view, expand_length)
    return <- texels

def ExtractTexels ( bytes:array<uint8>; w,h:int )
    var texels : array<uint8>
    texels |> resize(w*h)
    for y in range(h)
        for x in range(w)
            let ofs = (y*(w>>2)+(x>>2))+(x&3)*(w>>2)*h
            let b = bytes[ofs]
            texels[y*w+x] = b
    return <- texels

def FlipTexels ( bytes:array<uint8>; w,h:int )
    var texels : array<uint8>
    texels |> resize(w*h)
    for y in range(h)
        for x in range(w)
            texels[x*h+y] = bytes[x+y*w]
    return <- texels

def InitPics
    InitHuffmanTree()
    InitPicOffsets()
    var bytes <- LoadBytes("VGAGRAPH.WL6")
    var compressed_length = PicOffsets[1] - PicOffsets[0]
    var expand_length = int(bytes |> getUInt32(0))
    var exp_buf : array<uint8>
    array_view(bytes, 4, compressed_length) <| $ ( cbuf )
        exp_buf <- huffman_expand(cbuf, expand_length)
    Pictures |> resize(PIC_COUNT)
    for picture,i in Pictures,count()
        picture.width = int(exp_buf[4*i  ]) | int(exp_buf[4*i+1])
        picture.height = int(exp_buf[4*i+2]) | int(exp_buf[4*i+3])
        var eps = 0
        var texels <- ExtractPic(bytes, i+PIC_STARTS,eps)
        picture.width = eps / picture.height
        picture.texels <- texels |> ExtractTexels(picture.width,picture.height)
        picture.data <- FlipTexels(picture.texels, picture.width, picture.height)
    for i in range(PIC_ENDS, NUMBER_OF_PIC_CHUNKS-1)
        var cl = PicOffsets[i+1] - PicOffsets[i]
        var el = int(bytes |> getUInt32(PicOffsets[i]))
    for i in range(1,PIC_STARTS)
        var font : Font
        var cl = PicOffsets[i+1] - PicOffsets[i]
        var el = int(bytes |> getUInt32(PicOffsets[i]))
        array_view(bytes, PicOffsets[i+1]+4, cl) <| $ ( view )
            var eps = 0
            var data <- ExtractPic(bytes, i, eps)
            let height = int(data |> getUInt16(0))
            font.height = height
            for ii in range(256)
                let ofs = int(data |> getUInt16(2+ii*2))
                let width = int(data |> getUInt8(2+256*2+ii))
                font.width[ii] = width
                if width != 0
                    var pic = new [[Picture width=width, height=height]]
                    pic.texels |> resize(width*height)
                    for y in range(height)
                        for x in range(width)
                            pic.texels[y*width+x] = data[ofs+y*width+x]
                    pic.data <- FlipTexels(pic.texels, pic.width, pic.height)
                    font.letters[ii] = pic
            Fonts |> emplace(font)

def InitFilesFirst
    InitPics()

def InitFiles
    InitMapHead()
    InitGameMap()
    InitResources()
    InitAudio()

// -------------------- sound system --------------------

enum SoundName
    NONE =                  -1;     ACHTUNG =                0;     DOGBARK =                2;     OPENDOORSND =            3;
    CLOSEDOORSND =           8;     ATKMACHINEGUNSND =       11;    ATKPISTOLSND =           12;    ATKGATLINGSND =          13;
	SCHUTZADSND =            14;    GUTENTAGSND =            16;    MUTTISND =               18;    BOSSFIRESND =            20;
	SSFIRESND =              23;    DEATHSCREAM1SND =        25;    DEATHSCREAM2SND =        26;    DEATHSCREAM3SND =        27;
    TAKEDAMAGESND =          28;    PUSHWALLSND =            35;    AHHHGSND =               36;    DIESND =                 38;
    EVASND =                 41;    LEBENSND =               45;    NAZIFIRESND =            47;    SLURPIESND =             50;
    TOT_HUNDSND =            53;    MEINGOTTSND =            55;    SCHABBSHASND =           62;    HITLERHASND =            66;
    SPIONSND =               70;    NEINSOVASSND =           72;    DOGATTACKSND =           75;    LEVELDONESND =           77;
    MECHSTEPSND =            79;    YEAHSND =                81;    SCHEISTSND =             83;    DEATHSCREAM4SND =        85;
    DEATHSCREAM5SND =        87;    DONNERSND =              89;    EINESND =                92;    ERLAUBENSND =            97;
    DEATHSCREAM6SND =        103;   FART =                   103;   DEATHSCREAM7SND =        104;   DEATHSCREAM8SND =        106;
	DEATHSCREAM9SND =        108;   KEINSND =                110;   MEINSND =                113;   ROSESND =                116;
// audio
    HITWALLSND = 1000;              SELECTWPNSND;                   SELECTITEMSND;                  HEARTBEATSND;
    MOVEGUN2SND;                    MOVEGUN1SND;                    NOWAYSND;                       NAZIHITPLAYERSND;
    SCHABBSTHROWSND;                PLAYERDEATHSND;                 DOGDEATHSND;                    ATKGATLINGSND_;
    GETKEYSND;                      NOITEMSND;                      WALK1SND;                       WALK2SND;
    TAKEDAMAGESND_;                 GAMEOVERSND;                    OPENDOORSND_;                   CLOSEDOORSND_;
    DONOTHINGSND;                   HALTSND;                        DEATHSCREAM2SND_;               ATKKNIFESND;
    ATKPISTOLSND_;                  DEATHSCREAM3SND_;               ATKMACHINEGUNSND_;              HITENEMYSND;
    SHOOTDOORSND;                   DEATHSCREAM1SND_;               GETMACHINESND;                  GETAMMOSND;
    SHOOTSND;                       HEALTH1SND;                     HEALTH2SND;                     BONUS1SND;
    BONUS2SND;                      BONUS3SND;                      GETGATLINGSND;                  ESCPRESSEDSND;
    LEVELDONESND_;                  DOGBARKSND;                     ENDBONUS1SND;                   ENDBONUS2SND;
    BONUS1UPSND;                    BONUS4SND;                      PUSHWALLSND_;                   NOBONUSSND;
    PERCENT100SND;                  BOSSACTIVESND;                  MUTTISND_;                      SCHUTZADSND_;
    AHHHGSND_;                      DIESND_;                        EVASND_;                        GUTENTAGSND_;
    LEBENSND_;                      SCHEISTSND_;                    NAZIFIRESND_;                   BOSSFIRESND_;
    SSFIRESND_;                     SLURPIESND_;                    TOT_HUNDSND_;                   MEINGOTTSND_;
    SCHABBSHASND_;                  HITLERHASND_;                   SPIONSND_;                      NEINSOVASSND_;
    DOGATTACKSND_;                  FLAMETHROWERSND;                MECHSTEPSND_;                   GOOBSSND;
    YEAHSND_;                       DEATHSCREAM4SND_;               DEATHSCREAM5SND_;               DEATHSCREAM6SND_;
    DEATHSCREAM7SND_;               DEATHSCREAM8SND_;               DEATHSCREAM9SND_;               DONNERSND_;
    EINESND_;                       ERLAUBENSND_;                   KEINSND_;                       MEINSND_;
    ROSESND_;                       MISSILEFIRESND;                 MISSILEHITSND;

enum MusicName
	CORNER_MUS;                 	DUNGEON_MUS;                	WARMARCH_MUS;               	GETTHEM_MUS;
	HEADACHE_MUS;               	HITLWLTZ_MUS;                   INTROCW3_MUS;                   NAZI_NOR_MUS;
	NAZI_OMI_MUS;                   POW_MUS;                        SALUTE_MUS;                     SEARCHN_MUS;
	SUSPENSE_MUS;                   VICTORS_MUS;                    WONDERIN_MUS;                   FUNKYOU_MUS;
	ENDLEVEL_MUS;                   GOINGAFT_MUS;                   PREGNANT_MUS;                   ULTIMATE_MUS;
	NAZI_RAP_MUS;                   ZEROHOUR_MUS;                   TWELFTH_MUS;                    ROSTER_MUS;
	URAHERO_MUS;                    VICMARCH_MUS;                   PACMAN_MUS;


def get_sound_data ( name:SoundName; var playback_rate:int&; max_seq:int=INT_MAX )
    var index = int(name)
    var data : array<float>
    if index >= 1000
        index -= 1000
        if USE_ADLIB
            data |> reserve ( AdlibAudio[index].data |> length )
            for i in AdlibAudio[index].data
                let I = int16(i)
                data |> push(float(I)/32768.)
            playback_rate = ADLIB_SAMPLE_RATE
        else
            data |> reserve ( Audio[index].data |> length )
            for i in Audio[index].data
                data |> push(float(i)/128.0-1.0)
            playback_rate = SOUND_SAMPLE_RATE
    else
        while index < length(Sounds)
            let next = Sounds[index].data |> length
            let cur = data |> length
            data |> reserve ( data|>length + next )
            for i in Sounds[index].data
                data |> push(float(i)/128.0-1.0)
            if next != 4096
                break
            index ++
        playback_rate = SOUND_SAMPLE_RATE
    return <- data

def play_game_music ( name:MusicName )
    var data : array<float2>
    assume music = Music[int(name)]
    data |> resize( length(music.data)/2 )
    for i in range(length(data))
        let Il = int16(music.data[i*2])
        let Ir = int16(music.data[i*2+1])
        data[i] = float2(float(Il)/32768., float(Ir)/32768.)
    application->play_app_music(data, MUSIC_SAMPLE_RATE)

def play_game_sound_2d ( name:SoundName; xy:float2; r:float; rfactor:float = 1.0 )
    if name != SoundName NONE
        var rate = 0
        application->play_app_sound_2d(xy, r, get_sound_data(name,rate), int(float(rate)*rfactor))

def play_game_sound ( name:SoundName; rfactor:float = 1.0 )
    if name != SoundName NONE
        var rate = 0
        application->play_app_sound(get_sound_data(name,rate), int(float(rate)*rfactor))

// -------------------- entities --------------------

enum Collectible
    DogFood = 29;           KeyGold = 43;           KeySilver = 44;         Food = 47;
    Medkit = 48;            AmmoClip = 49;          MachineGun = 50;        Chaingun = 51;
    TreasureCross = 52;     TreasureChalice = 53;   TreasureChest = 54;     TreasureCrown = 55;
    LifeUp = 56;            SkeletonBlood = 57;     Blood = 61;

enum Props
    GreenBarrel = 24;       TableAndChairs = 25;    FloorLamp = 26;         HangedSkeleton = 28;
    WhitePillar = 30;       Tree = 31;              Sink = 33;              PottedPlant = 34;
    Urn = 35;               BareTable = 36;         SuitOfArmor = 39;       HangingCage = 40;
    SkeletonInCage = 41;    Bed = 45;               Barrel = 58;            Well = 59;
    EmptyWell = 60;         Flag = 62;              CallApogee = 63;        Stove = 68;
    Spears = 69;

def isKey ( m1:int )
    return m1==43 || m1==44

def isHpRestore ( m1:int )
    return m1==29 || m1==47 || m1==48 || m1==57 || m1==61

def getPlayerDirection(dm:int; var dx,dy:float& )
    if dm==0
        dx = 0.0;   dy = -1.0
    elif dm==1
        dx = 1.0;   dy = 0.0
    elif dm==2
        dx = 0.0;   dy = 1.0
    elif dm==3
        dx = -1.0;  dy = 0.0

def getEntityDirection(dm:int; var dx,dy:float& )
    if dm==0
        dx = 1.0;   dy = 0.0
    elif dm==1
        dx = 0.0;   dy = -1.0
    elif dm==2
        dx = -1.0;  dy = 0.0
    elif dm==3
        dx = 0.0;   dy = 1.0

def isDoor(m0:int)
    return m0>=90 && m0<=101

def isGoldDoor(m0:int)
    return (m0==92 || m0==93)

def isSilverDoor(m0:int)
    return (m0==94 || m0==95)

def isRegularDoor(m0:int)
    return (m0==90 || m0==91 || m0==96 || m0==97 || m0==98 || m0==99 || m0==100 || m0==101)

def isPlayer(m1:int)
    return m1>=19 && m1<=22

def isProp(m1:int)
    return m1>=23 && m1<=70

def isPushWall(m1:int)
    return m1==98

def isElevator(m1:int)
    return (m1==21)

def isSecretElevator(m1:int)
    return m1==107

def isDeadGuard(m1:int)
    return m1==124

def isTreasure(m1:int)
    return (m1==52 || m1==53 || m1==54 || m1==55)

def isCollectible(m1:int)
    return (m1==29 || m1==43 || m1==44 || m1==47 || m1==48 || m1==49 || m1==50 || m1==51 || m1==52 || m1==53 || m1==54 || m1==55 || m1==56 || m1==57 || m1==61)

def isBlocking(m1:int)
    return (m1==24 || m1==25 || m1==26 || m1==28 || m1==30 || m1==31 || m1==33 || m1==34 || m1==35 || m1==36 || m1==39 || m1==40 || m1==41 || m1==45 || m1==58 || m1==59 || m1==60 || m1==62 || m1==63 || m1==68 || m1==69)

def isEnemy(m1:int)
    return (m1>=108 && m1<=259)

def isStandingGuard(m1:int)
    return (m1>=108 && m1<=111 || m1>=144 && m1<=147 || m1>=180 && m1<=183)

def isPatrollingGuard(m1:int)
    return (m1>=112 && m1<=115 || m1>=148 && m1<=151 || m1>=184 && m1<=187)

def isStandingOfficer(m1:int)
    return (m1>=116 && m1<=119 || m1>=152 && m1<=155 || m1>=188 && m1<=191)

def isPtrollingOfficer(m1:int)
    return (m1>=120 && m1<=123 || m1>=156 && m1<=159 || m1>=192 && m1<=195)

def isStandingSS(m1:int)
    return (m1>=126 && m1<=129 || m1>=162 && m1<=165 || m1>=198 && m1<=201)

def isPatrollingSS(m1:int)
    return (m1>=130 && m1<=133 || m1>=166 && m1<=169 || m1>=202 && m1<=205)

def isStandingDog(m1:int)
    return (m1>=134 && m1<=137 || m1>=170 && m1<=173 || m1>=206 && m1<=209)

def isPatrollingDog(m1:int)
    return (m1>=138 && m1<=141 || m1>=174 && m1<=177 || m1>=210 && m1<=213)

def isStandingMutant(m1:int)
    return (m1>=216 && m1<=219 || m1>=234 && m1<=237 || m1>=252 && m1<=255)

def isPatrollingMutant(m1:int)
    return (m1>=220 && m1<=223 || m1>=238 && m1<=241 || m1>=256 && m1<=259)

def isFakeHitler(m1:int)
    return (m1==160)

def isHitler(m1:int)
    return (m1==178)

def isGeneralFettgesicht(m1:int)
    return (m1==179)

def isDoctorSchabbs(m1:int)
    return (m1==196)

def isGretelGrosse(m1:int)
    return (m1==197)

def isHansGrosse(m1:int)
    return (m1==214)

def isOttoGiftmacher(m1:int)
    return (m1==215)

def isRedPacManGhost(m1:int)
    return (m1==224)

def isPinkPacManGhost(m1:int)
    return (m1==225)

def isOrangePacManGhost(m1:int)
    return (m1==226)

def isBluePacManGhost(m1:int)
    return (m1==227)

// -------------------- gameplay --------------------

enum GameMode
    loadScreen0 // red, with mouse\mem
    loadScreen1 // rating
    loadScreen2 // title
    loadScreen3 // credits
    mainMenu    // main menu (new game\save\load\etc)
    episodeMenu // episode menu (1-6)
    difficultyMenu // difficulty menu
    playing

var gameMode = GameMode loadScreen0

var cursorTimer = 0.
var splashTimer = 0.
var mainMenuSelection = 0
var episodeMenuSelection = 0
var difficultyMenuSelection = 0

var frame_time = 0.66

let CHEAT_DISABLE_ENEMIES = false

let DEAD_BODY_REMOVE_DISTANCE = 10. // how far away from player dead bodies are removed

let SHOT_ALERT_RADIUS = 10. // how far away from player enemies are alerted by shots

let DISABLE_AGRO = false    // if enemies should be agro at all
let AGRO_TIME = 20.         // they stay agro even if they can't see you for that many seconds

let LEVEL_FADE_TIME = 1.
let LEVEL_FADE_FACTOR = 2. / LEVEL_FADE_TIME / 60.
let DEFAULT_SPLASH_TIMER = 3.

let PAIN_SOUND_RADIUS = 64.
let SHOT_SOUND_RADIUS = 64.
let AGRO_SOUND_RADIUS = 64.

let DOOR_SOUND_RADIUS = 20.      // how far away door sound can be heard (in tiles)
let DOOR_OPEN_SPEED = 2.0        // how fast door opens (in tiles per second)
let DOOR_CLOSE_SPPED = 2.0       // how fast door closes (in tiles per second)
let DOOR_STAYS_CLOSED = 3.0      // how long door stays closed (in seconds)

var playerHoodTime = 0.
var playerHeartbeatTime = 0.
var playerHealth = 1.

var hudMessage = ""
var hudMessageTime = 0.

struct Animation
    sprites : array<int>
    spriteIndex : int
    timer : float
    loop : bool
    orientable : bool
    rate : float

enum Category
    nothing
    prop
    deadBody
    enemy

struct PlayerRelativeCoordinates
    rpos:float2
    opos:float2

struct Entity
    category : Category
    mapItem      : int
    spriteIndex  : int
    animation    : Animation?
    orientable   : bool
    pos          : float2
    dir          : float2
    prc          : PlayerRelativeCoordinates

var objects : array<Entity?>

enum EnemyCategory
    guard
    dog
    officer
    ss
    mutant
// bosses
    hansGrosse

struct EnemyClass
    enemyCategory : EnemyCategory
    spriteIndex : int
    runSprites : array<int>
    deathSprites : array<int>
    damageSprites : array<int>
    attackSprites : array<int>
    orientable : bool
// movement and location
    radius : float          // how big enemy is
    speed : float           // how fast enemy moves
// everything hp
    hp : int                // how much hp enemy has
// everything attack
    attackDamage : int      // how much damage it does on each attack
    attackFireRate : float  // how fast it attacks
    attackDistance : float  // how far away from player enemy can attack
    comfortDistance : float // how far away from player enemy stops chasing
    attackDelay : float2    // min, max - between attacks
    attackReaction : float2 // min, max - before 1st attack
    attackSound : SoundName // sound played when enemy attacks
    deathSound : SoundName  // sound played when enemy dies
    agroSound : SoundName   // sound played when enemy sees player
// everything ai
    points : int            // how many points player gets for killing enemy
    canOpenDoors : bool     // can enemy open doors

let enemyClasses <- [[EnemyClass
// guard
    hp = 25,
    points = 100,
    radius = .25,
    speed = 0.065 * 0.35,
    canOpenDoors = true,
    attackDamage = 15,
    comfortDistance = 3.,
    attackDistance = 5.,
    attackFireRate = 2.5,
    attackReaction = float2(0.5, 1.),
    attackDelay = float2(1., 2.),
    attackSound = SoundName ATKPISTOLSND,
    agroSound = SoundName ACHTUNG,
    deathSound = SoundName DEATHSCREAM9SND,
    spriteIndex = 50,
    runSprites <- [{auto 58; 66; 74}],
    deathSprites <- [{auto 90; 91; 92; 93; 95}],
    damageSprites <- [{auto 90; 94; 50}],
    attackSprites <- [{auto 96; 97; -98; 97; 50}];
// dog
    hp = 1,
    points = 50,
    radius = .3,
    speed = 0.065 / 2.,
    canOpenDoors = false,
    attackDamage = 10,
    attackDistance = 1.5,
    comfortDistance = 1.5,
    attackFireRate = 3.5,
    attackReaction = float2(0., 5.),
    attackDelay = float2(0.2, 0.5),
    attackSound = SoundName DOGATTACKSND,
    agroSound = SoundName DOGBARK,
    deathSound = SoundName DOGDEATHSND,
    spriteIndex = 99,
    runSprites <- [{auto 107; 115; 123}],
    deathSprites <- [{auto 131; 132; 133; 134}],
    damageSprites <- [{auto 131; 99}],
    attackSprites <- [{auto 135; 136; -137; 136; 99}];
// officer
    hp = 50,
    points = 400,
    radius = .3,
    speed = 0.065 * 0.5,
    canOpenDoors = true,
    attackDamage = 30,
    attackDistance = 7.,
    comfortDistance = 5.,
    attackFireRate = 2.5,
    attackReaction = float2(0.3, 8.),
    attackDelay = float2(0.5, 1.),
    attackSound = SoundName ATKPISTOLSND,
    agroSound = SoundName SPIONSND,
    deathSound = SoundName NEINSOVASSND,
    spriteIndex = 238,
    runSprites <- [{auto 246; 254; 262}],
    deathSprites <- [{auto 279; 280; 281; 283; 284}],
    damageSprites <- [{auto 279; 282; 238}],
    attackSprites <- [{auto 285; 286; -287; 286; 238}];
// ss
    hp = 50,
    points = 500,
    radius = .3,
    speed = 0.065 * 0.5,
    canOpenDoors = true,
    attackDamage = 45,
    attackDistance = 7.,
    comfortDistance = 3.,
    attackFireRate = 2.5,
    attackReaction = float2(0.5, 1.),
    attackDelay = float2(0.8, 1.5),
    attackSound = SoundName SSFIRESND,
    agroSound = SoundName SCHUTZADSND,
    deathSound = SoundName LEBENSND,
    spriteIndex = 138,
    runSprites <- [{auto 146; 154; 162}],
    deathSprites <- [{auto 179; 180; 181; 183}],
    damageSprites <- [{auto 179; 182; 138}],
    attackSprites <- [{auto 184; 185; -186; 185; 138}];
// mutant
    hp = 45,
    points = 700,
    radius = .4,
    speed = 0.065 * 0.35,
    canOpenDoors = true,
    attackDamage = 45,
    attackDistance = 3.,
    comfortDistance = 1.5,
    attackFireRate = 2.5,
    attackReaction = float2(0.5, 1.),
    attackDelay = float2(1., 2.),
    attackSound = SoundName ATKGATLINGSND,
    agroSound = SoundName NONE,
    deathSound = SoundName AHHHGSND,
    spriteIndex = 187,
    runSprites <- [{auto 195; 203; 211}],
    deathSprites <- [{auto 228; 229; 230; 232; 233}],
    damageSprites <- [{auto 228; 231; 187}],
    attackSprites <- [{auto 234; -235; 236; -237; 236; 187}];
// hansGrosse
    hp = 800,
    points = 5000,
    radius = .4,
    speed = 0.065 * 0.35,
    canOpenDoors = true,
    attackDamage = 45,
    attackDistance = 10.,
    comfortDistance = 5.,
    attackFireRate = 2.5,
    attackReaction = float2(1., 2.),
    attackDelay = float2(2., 3.),
    attackSound = SoundName BOSSFIRESND,
    agroSound = SoundName GUTENTAGSND,
    deathSound = SoundName MUTTISND,
    spriteIndex = 296,
    runSprites <- [{auto 296; 297; 298; 299}],
    deathSprites <- [{auto 304; 305; 306; 303}],
    // damageSprites <- [{auto 228; 231; 187}],
    attackSprites <- [{auto 300; 300; 300; -301; -302; -301; -302; 300}]
]]

struct Enemy : Entity
    enemyCategory : EnemyCategory
    patrolling : bool
    health : int = 100
    attackTimer : float = 0.
    agroTimer : float = 0.
    running : bool = false
    run : float2
    radius : float

var enemies : array<Enemy?>

var seed = random_seed(13)

enum WeaponType
    knife = 0
    pistol = 1
    machineGun = 2
    chainGun = 3

struct Player
    pos : float2
    dir : float2
    health : int = 100
    lives : int = 5
    score : int = 0
    silverKey : bool
    goldKey : bool
    ammo : int = 8
    speed : float = 0.065
    speed_a : float = 0.05
    radius : float = 0.25
    moveForwars : bool = false
    moveBackward : bool = false
    strafeLeft : bool = false
    strafeRight : bool = false
    turnLeft : bool = false
    turnRight : bool = false
    turnAngle : float = 0.0
    weaponSprite : int = 421
    weaponAnimation : Animation?
    weaponType : WeaponType = WeaponType pistol
    hasWeapon : bool[4] = [[bool true; true; false; false ]]
    weaponSounds : SoundName[4] = [[SoundName
        SoundName ATKMACHINEGUNSND;
        SoundName ATKPISTOLSND;
        SoundName ATKMACHINEGUNSND;
        SoundName ATKGATLINGSND]]
    weaponFireRate : float[4] = [[float 2.5; 2.5; 7.1; 14.2]]
    weaponDamage : int[4] = [[int 16; 18; 18; 18]]

let random_take_damage_snd = [[SoundName
    SoundName DEATHSCREAM1SND;
    SoundName DEATHSCREAM2SND;
    SoundName DEATHSCREAM3SND]]

let treasureAudio = [[SoundName
    SoundName BONUS1SND;
    SoundName BONUS2SND;
    SoundName BONUS3SND;
    SoundName BONUS3SND]]

var player = Player()

struct Timer
    t : float
    dx, dy : int
    steps : int
    opening : bool
    active : bool
    isDoor : bool
    isWall : bool

var timer_plane : Timer[64][64]

var collision_plane : bool[64][64]

var pathing_plane : bool[64][64]

var visibility_plane : bool[64][64]

var zIndex : array<float>

var fov = 1.
var pixelWidth = 320.
var pixelHeight = 200.
var wallHeight = float(pixelWidth) / (2. * fov)

var level : Level
var levelIndex = 0
var nextLevelIndex = 0
var levelFade = 1.
var dLevelFade = 0.
var becauseOfDeath = false

var flashFactor = float4(1.,1.,1.,1.)
var flashBase = float4(0.,0.,0.,0.)
var flashTime = 0.

def hudText ( text:string; time:float )
    hudMessage = text
    hudMessageTime = time

def clearHud
    hudMessage = ""
    hudMessageTime = 0.

def Animation ( SPRITES:array<int>; LOOP:bool=false; ORIENTABLE:bool=false; RATE:float=1.0/6.0 )
    var self : Animation
    with self
        sprites := SPRITES
        spriteIndex = 0
        timer = 0.
        loop = LOOP
        orientable = ORIENTABLE
        rate = RATE
    return <- self

def startAnimation ( var entity:Entity; ANIMATION:Animation? )
    entity.animation = ANIMATION
    entity.spriteIndex = abs(entity.animation.sprites[0])

def takeDamage ( var self:Enemy; DAMAGE:int )
    with self
        if !DISABLE_AGRO
            agroTimer = AGRO_TIME   // getting shot sets up agro timer
        health -= DAMAGE
        if health <= 0
            category = Category deadBody
            self |> die()
        else
            if animation == null
                if !empty(enemyClasses[int(enemyCategory)].damageSprites)
                    self |> startAnimation(new Animation(enemyClasses[int(enemyCategory)].damageSprites,false,false))
            play_game_sound_2d(random_take_damage_snd[ random_int(seed) % 3], pos, PAIN_SOUND_RADIUS)
            self |> rotateTowardsPlayer()

def die ( var self:Enemy )
    with self
        health = -100
        orientable = false
        self |> startAnimation(new Animation(enemyClasses[int(enemyCategory)].deathSprites))
        play_game_sound_2d(enemyClasses[int(enemyCategory)].deathSound, pos, PAIN_SOUND_RADIUS)
        player |> gainPoints(enemyClasses[int(enemyCategory)].points)
        if enemyCategory==EnemyCategory dog
            // self |> dropLoot(cx,cy,Collectible dogBone)
            pass
        elif enemyCategory==EnemyCategory guard
            dropLoot(pos,Collectible AmmoClip, player.ammo < 8 ? 1. : 0.25)
        elif enemyCategory==EnemyCategory officer
            dropLoot(pos,Collectible AmmoClip, player.ammo < 8 ? 1. : 0.5)
        elif enemyCategory==EnemyCategory ss
            dropLoot(pos,Collectible MachineGun, 1.)
        elif enemyCategory==EnemyCategory mutant
            dropLoot(pos,Collectible Chaingun, 1.)
        elif enemyCategory==EnemyCategory hansGrosse
            dropLoot(pos,Collectible KeyGold, 1., true)


def dropLoot ( XY : float2; loot:Collectible; chanceToDrop:float; force:bool = false ) : bool
    let drop = random_float(seed)
    if drop <= chanceToDrop
        objects |> push <| new [[Entity
            category = Category prop,
            mapItem = int(loot),
            spriteIndex = int(loot)-21,
            pos = XY]]                        // TODO: randomize position?
    return true

def getPlayerRelativeCoordinates ( xy:float2 )
    let o = xy - player.pos
    return [[PlayerRelativeCoordinates
        rpos=float2(o.x * player.dir.x + o.y * player.dir.y, -o.x * player.dir.y + o.y * player.dir.x),
        opos=o]]

def trace ( px,py,pdx,pdy,maxDist:float; writeVis:bool ) : tuple<t:float; tx:float; textureIndex:int>
    // direction of the ray
    var dx = pdx
    var dy = pdy
    // direction in which the ray moves along each axis
    let stepx = dx >= 0. ? 1 : -1
    let stepy = dy >= 0. ? 1 : -1
    // take absolute values of ray direction
    dx = float(stepx) * dx
    dy = float(stepy) * dy
    // cell position of the ray on the map (starting from the player position)
    var cx = floori(px)
    var cy = floori(py)
    // remaining fractional distance from the ray position to the next cell (0 < rfx, rfy <= 1)
    var rfx = stepx > 0 ? 1. - (px % 1.) : px % 1.
    if rfx == 0.
        rfx = 1.
        cx += stepx
    var rfy = stepy > 0 ? 1. - (py % 1.) : py % 1.
    if rfy == 0.
        rfy = 1.
        cy += stepy
    // total time traveled by the ray
    var t = 0.
    // plane0 value of the cell visited by the ray
    var m0 : int
    // coordinate on the wall tile where the ray hit (0 <= tx <= 1)
    var tx : float
    // index of tile to display
    var textureIndex : int
    // ray casting loop
    while t < maxDist
        if writeVis
            visibility_plane[cx][cy] = true
        m0 = level.plane0[cx][cy]
        if m0 <= 63
            // hit a wall
            var wallShift = 0.
            let m1 = level.plane1[cx][cy]
            if m1 == 98
                // pushwall
                assume timer = timer_plane[cx][cy]
                if timer.active
                    wallShift = timer.t
                    if timer.dx != 0
                        // wall moves horizontally
                        if dx * rfy >= dy * wallShift
                            // ray hits wall
                            let dt = wallShift / dx
                            t += dt
                            rfy -= dt * dy
                            rfx -= wallShift
                        else
                            // ray moves to next cell
                            let dt = rfy / dy
                            t += dt
                            rfy = 1.
                            cy += stepy
                            rfx -= dt * dx
                            continue
                    else
                        // wall moves vertically
                        if dy * rfx >= dx * wallShift
                            // ray hits wall
                            let dt = wallShift / dy
                            t += dt
                            rfx -= dt * dx
                            rfy -= wallShift
                        else
                            // ray moves to next cell
                            let dt = rfx / dx
                            t += dt
                            rfx = 1.
                            cx += stepx
                            rfy -= dt * dy
                            continue
            if rfx == 1. - wallShift
                // NS wall
                textureIndex = 2 * m0 - 1
                // fix texture orientation depending on ray direction
                tx = stepx * stepy > 0 ? 1. - rfy : rfy
            else
                // EW wall
                textureIndex = 2 * m0 - 2
                // fix texture orientation depending on ray direction
                tx = stepx * stepy < 0 ? 1. - rfx : rfx
            break
        elif m0 <= 101
            // hit a door
            var doorShfit = 0.
            assume timer = timer_plane[cx][cy]
            if timer.active
                doorShfit = timer.t
            if (m0 & 1) == 0
                // NS door
                if rfx >= .5 && (rfx - .5) * dy < rfy * dx
                    // ray hits the central door line
                    let dt = (rfx - .5) / dx
                    t += dt
                    rfy -= dt * dy
                    rfx = .5
                    tx = stepy > 0 ? 1. - rfy : rfy
                    tx -= doorShfit
                    if tx >= 0.
                        // ray hits the door
                        if m0 == 90
                            textureIndex = 99
                        elif m0 == 92
                            textureIndex = 105
                        elif m0 == 94
                            textureIndex = 105
                        elif m0 == 100
                            textureIndex = 103
                        else
                            assert(false,"we should not be here?")
                        break
                if rfx * dy >= rfy * dx
                    // hit the side wall
                    let dt = rfy / dy
                    t += dt
                    rfx -= dt * dx
                    rfy = 1.
                    cy += stepy
                    textureIndex = 100
                    tx = stepx > 0 ? 1. - rfx : rfx
                    break
                else
                    // pass through
                    let dt = rfx / dx
                    t += dt
                    rfy -= dt * dy
                    rfx = 1.
                    cx += stepx
                    continue
            else
                // EW door
                if rfy >= .5 && (rfy - .5) * dx < rfx * dy
                    // ray hits the central door line
                    let dt = (rfy - .5) / dy
                    t += dt
                    rfx -= dt * dx
                    rfy = .5
                    tx = stepx > 0 ? 1. - rfx : rfx
                    tx -= doorShfit
                    if tx >= 0.
                        // ray hits the door
                        if m0 == 91
                            textureIndex = 98
                        elif m0 == 93
                            textureIndex = 104
                        elif m0 == 95
                            textureIndex = 104
                        elif m0 == 101
                            textureIndex = 102
                        else
                            assert(false,"we should not be here?")
                        break
                if rfy * dx >= rfx * dy
                    // hit the side wall
                    let dt = rfx / dx
                    t += dt
                    rfy -= dt * dy
                    rfx = 1.
                    cx += stepx
                    textureIndex = 101
                    tx = stepy > 0 ? 1. - rfy : rfy
                    break
                else
                    // pass through
                    let dt = rfy / dy
                    t += dt
                    rfx -= dt * dx
                    rfy = 1.
                    cy += stepy
                    continue
        // move to the next cell
        if rfx * dy <= rfy * dx
            // move to next cell horizontally
            let dt = rfx / dx
            t += dt
            rfx = 1.
            cx += stepx
            rfy -= dt * dy
        else
            // move to next cell vertically
            let dt = rfy / dy
            t += dt
            rfy = 1.
            cy += stepy
            rfx -= dt * dx
    return [[auto t, tx, textureIndex]]

def switchWeapon ( var self:Player; WEAPON_TYPE:WeaponType )
    with self
        if !hasWeapon[int(WEAPON_TYPE)]
            return
        weaponType = WEAPON_TYPE
        weaponSprite = 416 + int(weaponType) * 5

def canMoveTo ( self:Player; XY:float2 )
    for enemy in enemies
        if enemy.category == Category enemy
            let dist = length(enemy.pos - XY)
            if dist < self.radius + enemy.radius
                return false
    return canMoveTo(XY,self.radius)

def canMoveTo ( XY:float2;r:float )
    let f = fract(XY)
    let i = floori(XY)
    if collision_plane[i.x][i.y]
        return false
    if f.x < r
        if collision_plane[i.x-1][i.y]
            return false
        if f.y < r && collision_plane[i.x-1][i.y-1]
            return false
        if f.y > 1.-r && collision_plane[i.x-1][i.y+1]
            return false
    if f.x > 1.-r
        if collision_plane[i.x+1][i.y]
            return false
        if f.y < r && collision_plane[i.x+1][i.y-1]
            return false
        if f.y > 1.-r && collision_plane[i.x+1][i.y+1]
            return false
    if f.y < r && collision_plane[i.x][i.y-1]
        return false
    if f.y > 1.-r && collision_plane[i.x][i.y+1]
        return false
    return true

def move ( var self:Player; length,sideways:float )
    with self
        let oldxy = floori(pos)
        let XY = pos + dir*length + dir.yx*float2(-sideways,sideways)
        if self |> canMoveTo(float2(XY.x, pos.y))
            pos.x = XY.x
        if self |> canMoveTo(float2(pos.x, XY.y))
            pos.y = XY.y
        let newxy = floori(pos)
        if newxy != oldxy
            player |> collect(newxy)

def gainLifeUp ( var self:Player )
    with self
        health = 100
        lives ++
        ammo = min(99,ammo+25)
        play_game_sound(SoundName BONUS1UPSND)
        hudText("You now have {lives} lives", 2.)

def gainPoints ( var self:Player; points:int; hud:bool=false )
    with self
        score += points
        if score >= 30000           // todo: at the end of the level
            score -= 30000
            self |> gainLifeUp()
        elif hud
            hudText("Score {score}", 2.)

def gainTreasure ( var self:Player; m1:int; col:Collectible )
    with self
        play_game_sound(treasureAudio[m1-52])
        flashScreen(float4(0.,0.,1.,1.),float4(255.,255.,0.,0.), 3. / 60.)
        if col==Collectible TreasureCross
            player |> gainPoints(100,true)
        elif col==Collectible TreasureChalice
            player |> gainPoints(500,true)
        elif col==Collectible TreasureChest
            player |> gainPoints(1000,true)
        elif col==Collectible TreasureCrown
            player |> gainPoints(5000,true)

def collect ( var self:Player; XY:int2 )
    with self
    // WE TRIGGER LEVEL SWITCHES HERE AFTER BOSSES
        if levelIndex==8 && XY.y<8
            // hans grosse level, we see the 'run away' wall around line 7
            switchLevel(levelIndex+1)
            return
    // WE GO WITH NORMAL PICKUPS
        var collected : array<int>
        for obj,index in objects,count()
            if floori(obj.pos)!=XY
                continue
            var m1 = obj.spriteIndex + 21
            if isCollectible(m1)
                var col : Collectible
                for c in each_enum(type<Collectible>)
                    if int(c)==m1
                        col = c
                        break
                if isHpRestore(m1)
                    if health < 100
                        collected |> push(index)
                        if col==Collectible DogFood
                            health += 4
                            play_game_sound(SoundName FART)
                        elif col==Collectible Food
                            play_game_sound(SoundName HEALTH1SND)
                            health += 10
                        elif col==Collectible Medkit
                            play_game_sound(SoundName HEALTH2SND)
                            health += 24
                        elif col==Collectible SkeletonBlood || col==Collectible Blood
                            if health < 10
                                play_game_sound(SoundName SLURPIESND)
                                health += 1
                            else
                                collected |> pop()
                        health = min(health, 100)
                elif col==Collectible LifeUp
                    self |> gainLifeUp()
                    collected |> push(index)
                elif isKey(m1)
                    if col==Collectible KeySilver
                        silverKey = true
                    elif col==Collectible KeyGold
                        goldKey = true
                    collected |> push(index)
                    play_game_sound(SoundName GETKEYSND)
                elif col==Collectible AmmoClip
                    if ammo < 99
                        collected |> push(index)
                        ammo = min(99,ammo+8)
                        play_game_sound(SoundName GETAMMOSND)
                elif isTreasure(m1)
                    collected |> push(index)
                    self |> gainTreasure(m1,col)
                elif col == Collectible MachineGun || col == Collectible Chaingun
                    let wep = (col==Collectible MachineGun) ? WeaponType machineGun : WeaponType chainGun
                    if !hasWeapon[int(wep)] || ammo<99
                        collected |> push(index)
                        ammo = min(99,ammo+25)
                        if !hasWeapon[int(wep)]
                            play_game_sound((col==Collectible MachineGun) ? SoundName GETMACHINESND : SoundName GETGATLINGSND)
                            hasWeapon[int(wep)] = true
                            self |> switchWeapon(wep)
        collected |> sort
        reverse(collected)
        for i in collected
            objects |> erase(i)
        if ENABLE_HINT_SECRET_WALLS
            for x in range(-1,2)
                for y in range(-1,2)
                    if !(x==0 && y==0) && isPushWall(level.plane1[x+XY.x][y+XY.y]) && collision_plane[x+XY.x][y+XY.y]
                        play_game_sound(SoundName HEALTH2SND)


def turn ( var self:Player; alpha:float )
    with self
        let sa = sin(alpha)
        let ca = cos(alpha)
        dir = normalize(float2(dir.x * ca - dir.y * sa,dir.x * sa + dir.y * ca))

def update ( var self:Player )
    with self
        if health <= 0
            if application.activateButton
                switchLevel(levelIndex, true)
            return
        var changed = false
        if weaponAnimation == null
            if application.weapon1Button
                self |> switchWeapon(WeaponType knife)
            elif application.weapon2Button
                self |> switchWeapon(WeaponType pistol)
            elif application.weapon3Button
                self |> switchWeapon(WeaponType machineGun)
            elif application.weapon4Button
                self |> switchWeapon(WeaponType chainGun)
        if application.rightButton
            turnAngle += 1.
        if application.leftButton
            turnAngle -= 1.
        turnAngle += application.mouseDelta.x * MOUSE_SENSETIVITY
        if turnAngle != 0.
            self |> turn(turnAngle * speed_a * frame_time)
            turnAngle = 0.
            changed = true
        var forward = 0.
        var sideways = 0.
        if application.forwardButton
            forward += speed
        if application.backwardButton
            forward -= speed
        if application.strafeLeftButton
            sideways -= speed
        if application.strafeRightButton
            sideways += speed
        if forward != 0.
            if sideways != 0.
                self |> move(frame_time * forward / sqrt(2.), frame_time * sideways / sqrt(2.))
            else
                self |> move(frame_time * forward, 0.)
            changed = true
        elif sideways != 0.
            self |> move(0., frame_time * sideways)
            changed = true
        if weaponAnimation != null
            assume a = weaponAnimation
            a.timer += weaponFireRate[int(weaponType)] / 16. * frame_time
            if a.timer >= 1.
                a.timer = 0.
                if a.spriteIndex >= a.sprites |> length - 1
                    weaponAnimation = null
                    weaponSprite = 416 + int(weaponType) * 5
                else
                    a.spriteIndex += 1
                    weaponSprite = a.sprites[a.spriteIndex]
        if application.activateButton
            player |> activate()
        if application.shootButton
            player |> shoot()

def alert ( xy:float2; radius:float )
    if DISABLE_AGRO
        return
    for enemy in enemies
        if enemy.category == Category enemy
            if length(enemy.pos - xy) < radius
                enemy.agroTimer = AGRO_TIME

def shoot ( var self:Player )
    with self
        if weaponAnimation == null
            if weaponType!=WeaponType knife && ammo==0
                return
            if weaponType == WeaponType knife
                play_game_sound(SoundName ATKKNIFESND)
            else
                ammo -= weaponType == WeaponType chainGun ? 2 : 1
                play_game_sound(weaponSounds[int(weaponType)])
                alert(pos,SHOT_ALERT_RADIUS)
            weaponAnimation = new Animation([{for frame in range(4); frame+416+int(weaponType)*5}])
            var d = zIndex[int(pixelWidth) / 2]
            if weaponType == WeaponType knife
                d = min(d,1.) // one meter?
            for enemy in enemies
                if enemy.category != Category enemy
                    continue
                let epos = floori(enemy.pos)
                if !visibility_plane[epos.x][epos.y]
                    continue
                var prc = getPlayerRelativeCoordinates(enemy.pos)
                if prc.rpos.x < 0.
                    continue
                if prc.rpos.x >= d
                    continue
                if abs(prc.rpos.y) <= .3
                    *enemy |> takeDamage(weaponDamage[int(weaponType)])

def isTooCloseToDoor ( var self:Player; XY:int2 )
    with self
        if XY==floori(pos)
            return true
        let fxy = abs(float2(XY)+float2(0.5)-pos)
        let rext = radius + 0.5
        if fxy.x<=rext && fxy.y<=rext
            return true
        return false

def openDoor ( X,Y:int )
    assume timer = timer_plane[X][Y]
    if !timer.active
        timer = [[Timer
            t = 0.,
            opening = true,
            active = true,
            isDoor = true
        ]]
        play_game_sound_2d(SoundName OPENDOORSND, float2(X,Y)+float2(0.5), DOOR_SOUND_RADIUS, 2.5)

def activate ( var self:Player )
    with self
        var X = floori(pos.x)
        var Y = floori(pos.y)
        var DX, DY : int
        if abs(dir.x) >= abs(dir.y)
            DX = dir.x >= 0. ? 1 : -1
            X += DX
        else
            DY = dir.y >= 0. ? 1 : -1
            Y += DY
        let m0 = level.plane0[X][Y]
        let m1 = level.plane1[X][Y]
        if isElevator(m0) && DX!=0
            var toLevel = 0
            let sublevel = levelIndex % 10  // level index in the episode
            if  isSecretElevator(level.plane0[X-DX][Y])                     // now, we are looking at elevator door, not push-wall
                toLevel = levelIndex - sublevel + 9 // to secret level
            elif sublevel==9
                toLevel = levelIndex - sublevel + ElevatorBackTo[levelIndex / 10]   // back from secret level
            else
                toLevel = levelIndex + 1    // to next level
            switchLevel(toLevel)
        elif isDoor(m0)
            // door
            if isGoldDoor(m0) && !goldKey
                // gold-locked door
                play_game_sound_2d(SoundName HALTSND, float2(X,Y)+float2(0.5), DOOR_SOUND_RADIUS)
                hudText("Golden key is required!", 2.)
                return
            if isSilverDoor(m0) && !silverKey
                // silver-locked door
                play_game_sound_2d(SoundName HALTSND, float2(X,Y)+float2(0.5), DOOR_SOUND_RADIUS)
                hudText("Sivler key is required!", 2.)
                return
            openDoor(X,Y)
        elif m1 == 98
            // pushwall
            assume timer = timer_plane[X][Y]
            if !timer.active && level.plane0[X+DX][Y+DY] >= 106
                // there is no active timer for this wall, and it can move backwards
                timer = [[Timer
                    t = 0.,
                    dx = DX,
                    dy = DY,
                    steps = 2,
                    opening = true,
                    active = true,
                    isWall = true
                ]]
                play_game_sound_2d(SoundName OPENDOORSND, float2(X,Y)+float2(0.5), DOOR_SOUND_RADIUS)
                self |> gainPoints(1000)
        else
            assume timer = timer_plane[X][Y]
            if !timer.active
                timer = [[Timer
                    t = 0.5,
                    active = true
                ]]
                play_game_sound_2d(SoundName DONOTHINGSND, float2(X,Y)+float2(0.5), DOOR_SOUND_RADIUS)

def clearKeys ( var self:Player )
    with self
        goldKey = false
        silverKey = false

def die ( var self:Player )
    with self
        health = 0
        lives --
        play_game_sound(SoundName DEATHSCREAM5SND)

def takeDamage ( var self:Player; DAMAGE:int )
    with self
        flashScreen(float4(0.,1.,1.,1.),float4(255.,0.,0.,0.), 3. / 60.)
        health -= DAMAGE
        if health <= 0
            self |> die()
        else
            play_game_sound(random_take_damage_snd[ random_int(seed) % 3])

def switchLevel ( index:int; reasonBecauseOfDeath = false )
    clearHud()
    becauseOfDeath = reasonBecauseOfDeath
    play_game_sound(SoundName LEVELDONESND)
    levelFade = 1.
    dLevelFade = - LEVEL_FADE_FACTOR
    nextLevelIndex = index

def flashScreen ( ff,fb:float4; ft:float )
    flashFactor = ff
    flashBase = fb
    flashTime = ft

def heartbeat(x:float)
    let p_x = PI * x
    let s1 = pow(sin(p_x),100.)
    let s2 = sin(4.*p_x)
    return clamp ( s1*0.9 + s2*0.1 + 0.1, 0., 1.)

def nextGameMode
    if gameMode==GameMode loadScreen0
        gameMode = GameMode loadScreen1
    elif gameMode == GameMode loadScreen1
        gameMode = GameMode loadScreen2
    elif gameMode == GameMode loadScreen2
        gameMode = GameMode loadScreen3
    elif gameMode == GameMode loadScreen3
        gameMode = GameMode mainMenu
    elif gameMode == GameMode mainMenu
        if mainMenuSelection == 0           // new game
            gameMode = GameMode episodeMenu
        elif mainMenuSelection == 5         // quit
            application->quit()
        // TODO: support other menu options
    elif gameMode == GameMode episodeMenu
        gameMode = GameMode difficultyMenu
    elif gameMode == GameMode difficultyMenu
        nextLevelIndex = episodeMenuSelection * 10
        levelIndex = nextLevelIndex
        setupLevel(nextLevelIndex)
        gameMode = GameMode playing
        // TODO: support other game modes
    splashTimer = DEFAULT_SPLASH_TIMER

def updatePalette
    // udpate flash
    if flashTime > 0.
        flashTime -= 1./60. * frame_time
        if flashTime < 0.
            flashFactor = float4(1.,1.,1.,1.)
            flashBase = float4(0.,0.,0.,0.)
            flashTime = 0.
    if dLevelFade != 0.
        // fade between levels
        var pal : uint[256]
        if becauseOfDeath && dLevelFade < 0.
            for p,d in GamePalette, pal
                d = pack_float_to_byte ( float4(255.,0.,0.,255.0) * levelFade )
        else
            for p,d in GamePalette, pal
                d = pack_float_to_byte ( unpack_byte_to_float(p) * levelFade )
        application->set_palette(pal)
        levelFade += dLevelFade * frame_time
        if dLevelFade > 0. && levelFade >= 1.
            dLevelFade = 0.
            levelFade = 1.
        elif dLevelFade < 0. && levelFade <= 0.
            if gameMode == GameMode playing
                levelIndex = nextLevelIndex
                setupLevel(nextLevelIndex)
            else
                nextGameMode()
            levelFade = 0.
            dLevelFade = LEVEL_FADE_FACTOR
    elif (player.health>0 && player.health <= 25) || flashTime > 0.
        // health fading to red + flash
        playerHeartbeatTime += 1./60. * frame_time
        if playerHeartbeatTime > 2.
            playerHeartbeatTime -= 2.
        var ifactor = 1.
        if player.health <= 0
            ifactor = 0.
        elif player.health <= 25
            let hb = heartbeat(playerHeartbeatTime*0.5)
            var factor = max(0., 1. - float(player.health) / 25. )
            ifactor = lerp(1., hb, factor)
        var pal : uint[256]
        for p,d in GamePalette,pal
            let fc = unpack_byte_to_float(p) * flashFactor + flashBase
            let tc = float4(255.,fc.y*ifactor,fc.z*ifactor,fc.w)
            let rc = lerp(fc, tc, float4(1.-ifactor))
            d = pack_float_to_byte ( clamp(rc, float4(0.), float4(255.)) )
        application->set_palette(pal)
    else
        application->set_palette(GamePalette)

def setupLevel ( var index:int )
    to_log(LOG_INFO, "LOADING LEVEL {index}\n}")
    level := Levels[index]
    delete objects
    delete enemies
    for by in collision_plane
        for b in by
            b = false
    for ty in timer_plane
        for t in ty
            t.active = false
    if becauseOfDeath
        var oldLives = player.lives
        if player.lives==0
            index = 0
            oldLives = 5
        player = Player()
        player.lives = oldLives
    else
        player |> clearKeys()
    for y in range(64)
        for x in range(64)
            // structual
            let m0 = level.plane0[x][y]
            if m0 <= 63
                // wall
                collision_plane[x][y] = true
            elif 90 <= m0 && m0 <= 101
                // door
                collision_plane[x][y] = true
            // entities
            let m1 = level.plane1[x][y]
            if isPlayer(m1)
                // player
                player.pos = float2(x,y) + float2(0.5)
                getPlayerDirection(m1-19,player.dir.x,player.dir.y)
            elif isProp(m1)
                objects |> push <| new [[Entity
                    category = Category prop,
                    mapItem = m1,
                    spriteIndex = m1-21,
                    pos = float2(x,y) + float2(0.5)
                ]]
                if isBlocking(m1)
                    collision_plane[x][y] = true
            elif isPushWall(m1)
                pass
                // pushwall
                // score.totalSecrets ++
            elif isDeadGuard(m1)
                // dead guard
                objects |> push <| new [[Entity
                    category = Category prop,
                    mapItem = 95 - 21,
                    spriteIndex = 95,
                    pos = float2(x,y) + float2(0.5)
                ]]
            elif !CHEAT_DISABLE_ENEMIES && isEnemy(m1)   // disabled enemies for now
                var category : EnemyCategory
                var patrolling = false
                var orientable = true
                if isStandingGuard(m1)
                    category = EnemyCategory guard
                elif isPatrollingGuard(m1)
                    category = EnemyCategory guard
                    patrolling = true
                elif isStandingDog(m1)
                    category = EnemyCategory dog
                elif isPatrollingDog(m1)
                    category = EnemyCategory dog
                    patrolling = true
                elif isStandingSS(m1)
                    category = EnemyCategory ss
                elif isPatrollingSS(m1)
                    category = EnemyCategory ss
                    patrolling = true
                elif isStandingMutant(m1)
                    category = EnemyCategory mutant
                elif isPatrollingMutant(m1)
                    category = EnemyCategory mutant
                    patrolling = true
                elif isFakeHitler(m1)
                    print("FAKE HITLER AT {x},{y}\n")
                elif isHitler(m1)
                    print("HITLER AT {x},{y}\n")
                elif isGeneralFettgesicht(m1)
                    print("GENERAL FETTGESICHT AT {x},{y}\n")
                elif isDoctorSchabbs(m1)
                    print("DOCTOR SCHABBS AT {x},{y}\n")
                elif isGretelGrosse(m1)
                    print("GRETEL GROSSE AT {x},{y}\n")
                elif isHansGrosse(m1)
                    print("HANS GROSSE AT {x},{y}\n")
                    category = EnemyCategory hansGrosse
                    orientable = false
                    // ey = 30
                elif isOttoGiftmacher(m1)
                    print("OTTO GIFTMACHER AT {x},{y}\n")
                elif isRedPacManGhost(m1)
                    print("RED PACMAN GHOST AT {x},{y}\n")
                elif isPinkPacManGhost(m1)
                    print("PINK PACMAN GHOST AT {x},{y}\n")
                elif isOrangePacManGhost(m1)
                    print("ORANGE PACMAN GHOST AT {x},{y}\n")
                elif isBluePacManGhost(m1)
                    print("BLUE PACMAN GHOST AT {x},{y}\n")
                else
                    print("UNKNOWN ENEMY AT {x},{y}\n")
                // todo: add bosses
                var edx, edy : float
                getEntityDirection(m1 & 3,edx,edy)
                enemies |> push <| new [[Enemy
                    pos = float2(x,y) + float2(0.5),
                    dir = float2(edx, edy),
                    category = Category enemy,
                    enemyCategory = category,
                    patrolling = patrolling,
                    mapItem = m1,
                    spriteIndex = enemyClasses[int(category)].spriteIndex,
                    health = enemyClasses[int(category)].hp,
                    radius = enemyClasses[int(category)].radius,
                    orientable = orientable
                ]]

def rotateTowardsPlayer ( var self:Enemy )
    self.dir = normalize(player.pos - self.pos)

def shoot ( var self:Enemy )
    with self
        assume eclass = enemyClasses[int(enemyCategory)]
        play_game_sound_2d(eclass.attackSound, pos, PAIN_SOUND_RADIUS)
        var dxy = player.pos - pos
        let dist = length(dxy)
        dxy /= dist
        let tres = trace(pos.x,pos.y,dxy.x,dxy.y,dist,false)
        if tres.t >= dist
            let attackDamage = eclass.attackDamage
            let attackDistance = eclass.attackDistance
            let distanceFactor = clamp(1. -  dist / attackDistance, 0., 1.)
            let randomFactor = random_float(seed) * 0.3 // todo: tune?
            let damage = float(attackDamage) * (distanceFactor + randomFactor)
            let finalDamage = clamp ( int(damage), 3, attackDamage )
            player |> takeDamage(finalDamage)

def attack ( var self:Enemy )
    with self
        assume eclass = enemyClasses[int(enemyCategory)]
        let delay = eclass.attackDelay
        attackTimer = delay.x + random_float(seed)*(delay.y-delay.x)
        running = false
        let fireRate = eclass.attackFireRate / 16.
        self |> startAnimation(new Animation(eclass.attackSprites,false,false,fireRate))
        rotateTowardsPlayer(self)

def canMoveTo ( self:Enemy; XY:float2 )
    with self
        let dplayer = length(player.pos - XY)
        if (dplayer < (radius + player.radius))
            // can't move into player slot, period
            return false
        // can't move into other enemies
        var ipos = floori(XY)
        if floori(pos) != ipos
            if pathing_plane[ipos.x][ipos.y]
                return false
        return canMoveTo(XY,radius)

def move ( var self:Enemy; length,sideways:float )
    with self
        let oldxy = pos
        let XY = pos + dir*length + dir.yx*float2(-sideways,sideways)
        if self |> canMoveTo(float2(XY.x, pos.y))
            pos.x = XY.x
        if self |> canMoveTo(float2(pos.x, XY.y))
            pos.y = XY.y
        let newxy = floori(pos)
        let pcxy = floori(player.pos)
        let dplayer = length(player.pos - pos)
        if (newxy==pcxy) || (dplayer < radius + player.radius)
            pos = oldxy
            return

def getPrimaryDirection(dir:float2) : int2
    if abs(dir.x) > abs(dir.y)
        return dir.x > 0. ? int2(1,0) : int2(-1,0)
    else
        return dir.y > 0. ? int2(0,1) : int2(0,-1)

def getSecondaryDirection(dir:float2) : int2
    if abs(dir.x) > abs(dir.y)
        return dir.y > 0. ? int2(0,1) : int2(0,-1)
    else
        return dir.x > 0. ? int2(1,0) : int2(-1,0)

def getPathDir ( ipos:int2 ) : float2
    let ICONARROWS = 90
    let spot = level.plane1[ipos.x][ipos.y] - ICONARROWS
    if spot==0                  // east
        return float2( 1, 0)
    elif spot==1                // north-east
        return float2( 1,-1)
    elif spot==2                // north
        return float2( 0,-1)
    elif spot==3               // north-west
        return float2(-1,-1)
    elif spot==4               // wet
        return float2(-1, 0)
    elif spot==5               // south-west
        return float2(-1, 1)
    elif spot==6               // south
        return float2( 0, 1)
    elif spot==7               // south-east
        return float2( 1, 1)
    else
        return float2( 0, 0)

def keepDoorsOpen ( var self:Enemy; irun:int2 )
    with self
        if !isDoor(level.plane0[irun.x][irun.y])
            return
        if !enemyClasses[int(enemyCategory)].canOpenDoors
            return
        let m0 = level.plane0[irun.x][irun.y]
        if isRegularDoor(m0)
            openDoor(irun.x,irun.y)

def update ( var self:Enemy )
    with self
        attackTimer = max ( attackTimer - 1. / 60. * frame_time, 0. )
        agroTimer = max ( agroTimer - 1. / 60. * frame_time, 0. )
        // agro resets if we see the player regardless of what we are doing
        let ipos = floori(pos)
        if !DISABLE_AGRO && visibility_plane[ipos.x][ipos.y]   // player sees us, so we may (or may not) be able to see them
            var dxy = normalize(player.pos - pos)
            var angle = dot(dxy,dir)
            if !orientable || angle>=0.1
                if agroTimer == 0.
                    let delay = enemyClasses[int(enemyCategory)].attackReaction
                    attackTimer = random_float(seed) * (delay.y-delay.x) + delay.x
                    let agroSound = enemyClasses[int(enemyCategory)].agroSound
                    play_game_sound_2d(agroSound, pos, AGRO_SOUND_RADIUS)
                agroTimer = AGRO_TIME
        if animation == null || running
            if agroTimer!=0. && attackTimer==0. && player.health>0 && visibility_plane[ipos.x][ipos.y]
                // we try to shoot, if we are at the right distance
                let dist = length(player.pos - pos)
                let attackDistance = enemyClasses[int(enemyCategory)].attackDistance
                if dist>0. && dist<=attackDistance
                    self |> attack()
                    return
            if agroTimer!=0. && player.health>0 //  && visibility_plane[ipos.x][ipos.y]
                // we rotate towards player
                let dist = length(player.pos - pos)
                let comfortDistance = enemyClasses[int(enemyCategory)].comfortDistance
                if dist > comfortDistance || !visibility_plane[ipos.x][ipos.y]
                    // if we too far, or we don't see player - we run and try keeping doors open
                    self |> keepDoorsOpen(floori(float2(floori(pos)) + float2(0.5) + normalize(player.pos - pos)))
                    running = true
                else
                    // if we comfortable, we do nada
                    spriteIndex = enemyClasses[int(enemyCategory)].spriteIndex
                    animation = null
                    running = false
            if agroTimer==0.
                if patrolling
                    // if we are patrolling, we check direciton
                    if !running || run.xy == float2(0.)
                        let pdir = getPathDir(floori(pos))
                        if pdir!=float2(0,0)
                            dir = pdir
                        run = float2(floori(pos)) + float2(0.5) + dir
                        let irun = floori(run)
                        self |> keepDoorsOpen(floori(run))
                        if pathing_plane[irun.x][irun.y]
                            // if we can't go there (blocked), we just stand and wait
                            spriteIndex = enemyClasses[int(enemyCategory)].spriteIndex
                            animation = null
                            running = false
                        else
                            running = true
                else
                    // if we are not agroed and not patrolling, we just stand
                    spriteIndex = enemyClasses[int(enemyCategory)].spriteIndex
                    animation = null
                    running = false
        if running
            if animation == null
                self |> startAnimation(new Animation(enemyClasses[int(enemyCategory)].runSprites,true,orientable))
            if !run(self)
                // if we can't move, we just stand and watch player
                rotateTowardsPlayer(self)
                spriteIndex = enemyClasses[int(enemyCategory)].spriteIndex
                animation = null
                running = false

def run ( var self:Enemy )
    with self
        let speed = enemyClasses[int(enemyCategory)].speed * frame_time
        var tgt : float2
        if run.x==0.
            tgt = player.pos
        else
            tgt = run
        var runDir = tgt-pos
        let dist = length(runDir)
        runDir /= dist
        if run.x!=0.
            if dist<=speed
                // we reached the side target
                pos = run
                run = float2(0.)
                return true
            else
                // running to side target (todo: check if it became taken)
                dir = runDir
                self |> move(speed, 0.)
                return true
        var mainPos = pos + runDir * 0.5
        if self |> canMoveTo( mainPos )
            dir = runDir
            self |> move(speed, 0.)
            return true
        // we pick side target
        var primDir = getPrimaryDirection(runDir)
        var primPos = floor(pos) + float2(0.5) + float2(primDir)
        if self |> canMoveTo( primPos )
            run = primPos
            return true
        var secDir = getSecondaryDirection(runDir)
        var secPos = floor(pos) + float2(0.5) + float2(secDir)
        if self |> canMoveTo( secPos )
            run = secPos
            return true
        return false

def updateEnemies
    // fill pathing
    for y in range(64)
        for x in range(64)
            if isDoor(level.plane0[x][y])
                pathing_plane[x][y] = collision_plane[x][y]
            else
                pathing_plane[x][y] = false
    for enemi in enemies
        if enemi.category == Category enemy
            let ipos = floori(enemi.pos)
            pathing_plane[ipos.x][ipos.y] = true
    // update enemies
    for enemy in enemies
        // very basic AI
        if enemy.category == Category enemy
            *enemy |> update()
        // animation
        if enemy.animation != null
            enemy.animation.timer += enemy.animation.rate * frame_time
            if enemy.animation.timer >= 1.0
                enemy.animation.timer = 0.
                if enemy.animation.spriteIndex >= enemy.animation.sprites |> length - 1
                    if enemy.animation.loop
                        // animation loops
                        enemy.animation.spriteIndex = 0
                    else
                        // animation ended (delete?)
                        enemy.spriteIndex = abs(enemy.animation.sprites |> back)
                        enemy.animation = null
                        return
                else
                    enemy.animation.spriteIndex += 1
                let nextSprite = enemy.animation.sprites[enemy.animation.spriteIndex]
                let nextSpriteIndex = abs(nextSprite)
                if nextSpriteIndex != enemy.spriteIndex
                    enemy.spriteIndex = nextSpriteIndex
                    if nextSprite < 0
                        *enemy |> shoot()

def updateTimers
    for Y in range(64)
        for X in range(64)
            assume timer = timer_plane[X][Y]
            if !timer.active
                continue
            let XY = int2(X,Y)
            if timer.isDoor
                if timer.opening
                    if timer.t < 1.
                        timer.t += DOOR_OPEN_SPEED / 64. * frame_time
                    else
                        timer.t += 1. / 60. * frame_time
                    if timer.t >= 1.
                        collision_plane[X][Y] = false
                    if timer.t >= DOOR_STAYS_CLOSED
                        timer.t = DOOR_STAYS_CLOSED
                        timer.opening = false
                else
                    if timer.t < 1.
                        timer.t -= DOOR_CLOSE_SPPED / 64. * frame_time
                    else
                        timer.t -= 1./ 60. * frame_time
                    if timer.t <= 1.
                        if !collision_plane[X][Y]
                            var enemyTooCloseToDoor = false
                            for enemy in enemies
                                if floori(enemy.pos)==XY
                                    enemyTooCloseToDoor = true
                                    break
                            if enemyTooCloseToDoor || player|>isTooCloseToDoor(XY)
                                timer.t = DOOR_STAYS_CLOSED
                            else
                                collision_plane[X][Y] = true
                                play_game_sound_2d(SoundName CLOSEDOORSND, float2(XY)+float2(0.5), DOOR_SOUND_RADIUS, 2.5)
                    if timer.t <= 0.
                        timer.t = 0.
                        timer.active = false
                        assert(collision_plane[X][Y])
            elif timer.isWall
                timer.t += 1. / 60. * frame_time
                if timer.t >= 1.
                    let DX = timer.dx
                    let DY = timer.dy
                    let wallValue = level.plane0[X][Y]
                    level.plane0[X][Y] = level.plane0[X-DX][Y-DY]
                    level.plane0[X+DX][Y+DY] = wallValue
                    level.plane1[X][Y] = 0
                    collision_plane[X][Y] = false
                    collision_plane[X+DX][Y+DY] = true
                    timer.steps -= 1
                    if timer.steps>0 && !collision_plane[X+DX+DX][Y+DY+DY]
                        // wall moves one more step
                        level.plane1[X+DX][Y+DY] = 98
                        timer.t = 0.
                        timer_plane[X+DX][Y+DY] = timer
                    timer.active = false
            else
                // any random timer
                timer.t -= 1. / 60. * frame_time
                if timer.t <= 0.
                    timer.t = 0.
                    timer.active = false

def updatePlayer
    player |> update()
    // update hud
    playerHoodTime += 1./60./10. * frame_time
    if playerHoodTime > 1.
        playerHoodTime -= 1.
    playerHealth = clamp(float(player.health) / 100., 0., 1.0)
    // note: the section bellow is for debugging only. It allows to save and load player position
    if !ENABLE_CHEAT_CODEDS
        return
    if application.cheatGiveEverything
        to_log(LOG_INFO, "player was given everything\n")
        player.goldKey = true
        player.silverKey = true
        player.hasWeapon[int(WeaponType machineGun)] = true
        player.hasWeapon[int(WeaponType chainGun)] = true
        player.ammo = 199
        player.health = 200
    if application.cheat1
        // spawn an enemy at 34-60
        let X = 34
        let Y = 61
        var category = EnemyCategory dog
        enemies |> push <| new [[Enemy
            pos = float2(X,Y) + float2(0.5),
            dir = float2(1,0),
            category = Category enemy,
            enemyCategory = category,
            patrolling = true,
            spriteIndex = enemyClasses[int(category)].spriteIndex,
            health = enemyClasses[int(category)].hp,
            orientable = true
        ]]
    if application.cheat2
        // spawn column
        let X = 34
        let Y = 60
        objects |> push <| new [[Entity
            category = Category prop,
            pos = float2(X,Y) + float2(0.5),
            spriteIndex = int(Props Tree) - 21
        ]]
        collision_plane[X][Y] = true
    if application.cheat3
        player.pos = float2(12.5,51.5)
        player.dir = float2(0,1)
    if application.cheatSwitchLevel
        if application.cheatSwitchLevelShift
            if levelIndex<8
                switchLevel(8)  // HANS GROSSE
            else
                switchLevel(18) // DOCTOR SCHABBS
        else
            switchLevel(levelIndex+1)

def updateHud
    hudMessageTime -= 1./60. * frame_time
    if hudMessageTime < 0.
        hudMessageTime = 0.
        hudMessage = ""

def updateGame(dt:float)
    frame_time = min( dt / 16.0, 4.0 )  // at very low fps (spf?) things 'teleport'
    updatePalette()
    if dLevelFade != 0.
        return
    updateHud()
    updatePlayer()
    updateTimers()
    updateEnemies()

// -------------------- rasterization --------------------

let DEBUG_PLAYER_POSITION = false
let DEBUG_VISIBILITY = false

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
    rast_hspan_u8(bmp.data,i*bmp.size.y+ymin,tex,texelOffset,uvY,dUVY,ymax-ymin)

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
                            rast_hspan_u8(bmp.data,X*bmp.size.y+ymin,tspan,pixelOffset,uv0,dUVX,ymax-ymin)
                        pixelOffset += endRow - startRow
            uvX += dUVX

def draw2DElement ( x,y,w,h:int; var pic:Picture; var bmp:Bitmap8#; masked:bool = false )
    var u = 0.
    let du = 1. / float(w+1)
    let dv = 1. / float(h+1)
    var DV = dv * float(pic.height)
    lock(pic.data) <| $ ( tspan )
        for X in range(x,x+w)
            let px = floori(u * float(pic.width))
            if masked
                rast_hspan_masked_u8(bmp.data,y+X*bmp.size.y,tspan,px*pic.height,0.,DV,h)
            else
                rast_hspan_u8(bmp.data,y+X*bmp.size.y,tspan,px*pic.height,0.,DV,h)
            u += du

def draw2DSubElement ( x,y,w,h:int; x0,y0,x1,y1:int; var pic:Picture; var bmp:Bitmap8# )
    var u = 0.
    let du = float(x1-x0) / float(pic.width) / float(w)
    let dv = float(y1-y0) / float(pic.height) / float(h)
    var DV = dv * float(pic.height)
    lock(pic.data) <| $ ( tspan )
        for X in range(x,x+w)
            let px = floori(u * float(pic.width))
            rast_hspan_u8(bmp.data,y+X*bmp.size.y,tspan,px*pic.height+y0,0.,DV,h)
            u += du

def drawBackground ( var bmp:Bitmap8# )
    let h = bmp.size.y / 2
    rast_fillRect(bmp,0,0,bmp.size.x,h,uint8(ceilingColors[levelIndex]))
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

var hudFactor = float2(1.)

def fillHUDRect(x,y,w,h:int; col:uint8; var bmp:Bitmap8# )
    var minx = max(floori(float(x)*hudFactor.x), 0)
    var maxx = min(floori(float(x+w)*hudFactor.x), bmp.size.x)
    var miny = max(floori(float(y)*hudFactor.y), 0)
    var maxy = min(floori(float(y+h)*hudFactor.y), bmp.size.y)
    if minx>maxx || miny>maxy
        return
    rast_fillRect(bmp,minx,miny,maxx-minx,maxy-miny,col)

def drawHUDElement(x,y,w,h:int; var pic:Picture; var bmp:Bitmap8# )
    drawHUDSubElement(x,y,w,h,0,0,w,h,pic,bmp)

def drawHUDSubElement(x,y,w,h:int; x0,y0,x1,y1:int; var pic:Picture; var bmp:Bitmap8# )
    // TODO: fix clipping for sub-elements
    var minx = max(floori(float(x)*hudFactor.x), 0)
    var maxx = min(floori(float(x+w)*hudFactor.x), bmp.size.x)
    var miny = max(floori(float(y)*hudFactor.y), 0)
    var maxy = min(floori(float(y+h)*hudFactor.y), bmp.size.y)
    if minx>maxx || miny>maxy
        return
    draw2DSubElement(minx,miny,maxx-minx,maxy-miny,x0,y0,x1,y1,pic,bmp)

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

def getFontTextDim(text:string; font:Font) : tuple<width:int;height:int>
    var X = 0
    for chu in text
        X += font.width[chu]
    return [[auto X,font.height]]

def draw2DSolidSubElement ( solid:uint8; x,y,w,h:int; x0,y0,x1,y1:int; var pic:Picture; var bmp:Bitmap8# )
    var u = 0.
    let du = float(x1-x0) / float(pic.width) / float(w)
    let dv = float(y1-y0) / float(pic.height) / float(h)
    var DV = dv * float(pic.height)
    lock(pic.data) <| $ ( tspan )
        for X in range(x,x+w)
            let px = floori(u * float(pic.width))
            rast_hspan_masked_solid_u8(solid, bmp.data,y+X*bmp.size.y,tspan,px*pic.height+y0,0.,DV,h)
            u += du

def drawFontText(x,y:int; text:string; color:Color; var bmp:Bitmap8#; var font:Font )
    var X = x
    for chu in text
        let W = font.width[chu]
        let H = font.height
        var minx = max(floori(float(X)*hudFactor.x), 0)
        var maxx = min(floori(float(X+W)*hudFactor.x), bmp.size.x)
        var miny = max(floori(float(y)*hudFactor.y), 0)
        var maxy = min(floori(float(y+H)*hudFactor.y), bmp.size.y)
        X += W
        if minx>maxx || miny>maxy
            continue
        draw2DSolidSubElement(uint8(color),minx,miny,maxx-minx,maxy-miny,0,0,W,H,*font.letters[chu],bmp)

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
        let dim = getFontTextDim(hudMessage,Fonts[0])
        drawFontText(160-dim.width/2,2,hudMessage,Color BRIGHT_YELLOW,bmp,Fonts[0])

def drawDebugVisibility ( var bmp:Bitmap8# )
    for x in range(64)
        for y in range(64)
            var col = visibility_plane[x][y] ? 0u8 : 255u8
            rast_fillRect(bmp,bmp.size.x/2 - 32*4 - 10 + x*4,10 + y*4,4,4,col)
    for e in enemies
        if e.category == Category enemy
            rast_fillRect(bmp,bmp.size.x/2 - 32*4 - 10 + floori(e.pos.x)*4,10 + floori(e.pos.y)*4,4,4,32u8)

def drawMap ( var bmp:Bitmap8# )
    for x in range(64)
        for y in range(64)
            var col = collision_plane[x][y] ? 0u8 : 225u8
            if level.plane0[x][y]==21
                col = 1u8
            elif level.plane0[x][y]==107
                col = 5u8
            rast_fillRect(bmp, bmp.size.x/2 - 32*4 - 10 + x*4,10 + y*4,4,4,col)
    for e in enemies
        if e.category == Category enemy
            rast_fillRect(bmp, bmp.size.x/2 - 32*4 - 10 + floori(e.pos.x)*4,10 + floori(e.pos.y)*4,4,4,32u8)
    rast_fillRect(bmp, bmp.size.x/2 - 32*4 - 10 + floori(player.pos.x)*4,10 + floori(player.pos.y)*4,4,4,15u8)

def beforeDraw ( var bmp:Bitmap8# )
    hudFactor = max(float2(bmp.size)/float2(320.,200.),float2(1.))
    pixelWidth = float(bmp.size.x)
    pixelHeight = float(bmp.size.y)
    wallHeight = float(pixelWidth) / (2. * fov)

def draw ( level:Level; var bmp:Bitmap8# )
    beforeDraw(bmp)
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
    if player.health == 0
        rast_fillRect(bmp,0,0,bmp.size.x,bmp.size.y,32u8)    // right red?
        let text = player.lives!=0 ? "{player.lives} LIVES LEFT" : "YOU DIED"
        let dim = getHUDTextDim(text)
        drawHUDText(160-dim.width/2,100-dim.height/20-8,text,bmp)
    if DEBUG_VISIBILITY
        drawDebugVisibility(bmp)
    if ENABLE_MAP && application.mapButton
        drawMap(bmp)
    if DEBUG_PLAYER_POSITION
        let text = "{floori(player.pos.x)} {floori(player.pos.y)}"
        let dim = getFontTextDim(text,Fonts[0])
        drawFontText(160-dim.width/2,200-16,text,Color YELLOW,bmp,Fonts[0])

// -------------------------------- HUD --------------------------------

def defaultSplash ( _dt:float )
    let dt = min(_dt,1./60.)
    splashTimer -= dt * frame_time
    if splashTimer < 0.
        splashTimer = 0.
        dLevelFade = -LEVEL_FADE_FACTOR

def loadScreen0 ( dt:float; var bmp:Bitmap8# )
    if dLevelFade==0. && !at_app_start
        at_app_start = true
        InitFiles()
        play_game_music(MusicName NAZI_NOR_MUS)
    defaultSplash(dt)
    updatePalette()
    beforeDraw(bmp)
    rast_fillRect(bmp,0,0,bmp.size.x,bmp.size.y,uint8(Color RED_5))
    fillHUDRect(10,70,140,106,uint8(Color RED_BACKGROUND),bmp)
    assume wpic = Pictures[int(PictureIndex WOFLENSTEIN)]
    drawHUDSubElement(
        160-wpic.width/2,10,wpic.width,wpic.height,
        0,0,wpic.width-5,wpic.height-9,
        wpic,bmp)
    assume lpic = Pictures[int(PictureIndex ID_LOGO)]
    drawHUDSubElement(
        10,10,lpic.width,lpic.height,
        0,0,lpic.width-2,lpic.height,
        lpic,bmp)
    drawHUDSubElement(
        320-lpic.width-10,10,lpic.width,lpic.height,
        0,0,lpic.width-2,lpic.height,
        lpic,bmp)
    assume font = Fonts[0]
    let text = "Powered by daScript"
    let dim = getFontTextDim(text,font)
    drawFontText(160-dim.width/2,200-dim.height-2,text,Color VERY_DARK_BLUE,bmp,font)
    drawFontText(15,75,"ALLOCATED MEMORY",Color LIGHT_CYAN,bmp,font)
    let hba = heap_bytes_allocated()
    drawFontText(15,90,"{int64(hba)} heap",Color LIGHT_GREY,bmp,font)
    assume fontr = Fonts[0]
    assume cbpic = Pictures[int(PictureIndex CHECKBOX_CHECKED)]
    let iH = 22
    let i0 = 70
    for i in range(5)
        fillHUDRect(160+10,i0+i*iH,140,iH-4,uint8(Color RED_BACKGROUND),bmp)
        drawHUDSubElement(
            160+15,i0+5+i*iH,cbpic.width,cbpic.height,
            0,0,cbpic.width,cbpic.height,
            cbpic,bmp)
        drawFontText(160+10+cbpic.width+5,i0+4+i*iH,"MOUSE",Color LIGHT_GREY,bmp,fontr)

def loadScreen1 ( dt:float; var bmp:Bitmap8# )
    defaultSplash(dt)
    updatePalette()
    beforeDraw(bmp)
    assume lpic = Pictures[int(PictureIndex PC13_LOGO)]
    rast_fillRect(bmp,0,0,bmp.size.x,bmp.size.y,lpic.texels[0])
    drawHUDElement(320-lpic.width-20, 200-lpic.height-30,lpic.width,lpic.height,lpic,bmp)

def loadScreen2 ( dt:float; var bmp:Bitmap8# )
    defaultSplash(dt)
    updatePalette()
    beforeDraw(bmp)
    assume lpic = Pictures[int(PictureIndex TITLE_SCREEN)]
    drawHUDElement(0,0,lpic.width,lpic.height,lpic,bmp)

def loadScreen3 ( dt:float; var bmp:Bitmap8# )
    defaultSplash(dt)
    updatePalette()
    beforeDraw(bmp)
    assume lpic = Pictures[int(PictureIndex CREDITS_SCREEN)]
    drawHUDElement(0,0,lpic.width,lpic.height,lpic,bmp)

struct MenuOption
    text : string
    icon : PictureIndex

let mainMenuOptions <- [{MenuOption
    text="New Game", icon=PictureIndex NONE;
    text="Options", icon=PictureIndex NONE;
    text="Load Game", icon=PictureIndex NONE;
    text="Save Game", icon=PictureIndex NONE;
    text="Read this!", icon=PictureIndex NONE;
    text="Quit", icon=PictureIndex NONE;
}]

let episodeOptions <- [{MenuOption
    text="Escape from Wolfenstein", icon=PictureIndex EPISODE_1;
    text="Operation: Eisenfaust", icon=PictureIndex EPISODE_2;
    text="Die, Fuhrer, Die!", icon=PictureIndex EPISODE_3;
    text="A Dark Secret", icon=PictureIndex EPISODE_4;
    text="Trail of the Madman", icon=PictureIndex EPISODE_5;
    text="Confrontation", icon=PictureIndex EPISODE_6;
}]

let difficultyOptions <- [{MenuOption
    text="Can I play, Daddy?", icon = PictureIndex DIFFICULTY_1;
    text="Don't hurt me.", icon = PictureIndex DIFFICULTY_2;
    text="Bring 'em on!", icon = PictureIndex DIFFICULTY_3;
    text="I am Death incarnate!", icon = PictureIndex DIFFICULTY_4;
}]

def runMenu ( dt:float; var selection:int&; menuOptions:array<MenuOption> )
    cursorTimer = (cursorTimer + dt * frame_time) % 1.
    if dLevelFade == 0.
        if application.upButtonPressed
            selection = max(0,selection-1)
        if application.downButtonPressed
            selection = min(mainMenuOptions|>length-1,selection+1)
        if application.okButtonPressed
            play_game_sound(SoundName ATKPISTOLSND)
            dLevelFade = -LEVEL_FADE_FACTOR

def drawMenu ( menuSelection:int; menuOptions:array<MenuOption>; var font:Font; dt:float; var bmp:Bitmap8# )
    assume hpic = Pictures[int(PictureIndex MENU_HINT)]
    var dim = int2(0,15)
    for opt in menuOptions
        var odim = getFontTextDim(opt.text,font)
        if opt.icon != PictureIndex NONE
            odim.width += Pictures[int(opt.icon)].width + 5
            odim.height = max(odim.height,Pictures[int(opt.icon)].height+2)
        dim = max(dim,int2(odim.width,odim.height))
    assume cpinc = Pictures[int(cursorTimer<0.5 ? PictureIndex CURSOR_A : PictureIndex CURSOR_B)]
    dim.x += cpinc.width+5
    let minY = 200 - 20 - dim.y * menuOptions|>length
    drawHUDElement(160-hpic.width/2, 200-hpic.height-5, hpic.width,hpic.height,hpic,bmp)
    fillHUDRect(160-dim.x/2-5,minY-5,dim.x+10,190-minY,cpinc.texels[0],bmp)
    for opt,opti in menuOptions,count()
        var x = 160-dim.x/2
        var y = minY+opti*dim.y
        if opti==menuSelection
            drawHUDElement(x,y,cpinc.width,cpinc.height,cpinc,bmp)
        x += cpinc.width+5
        if opt.icon != PictureIndex NONE
            assume pic = Pictures[int(opt.icon)]
            drawHUDSubElement(x,y,pic.width,pic.height,0,0,pic.width,pic.height,pic,bmp)
            x += pic.width+5
            y += pic.height/2 - font.height/2
        drawFontText(x,y,opt.text,Color VERY_LIGHT_GREY,bmp,font)

def mainMenu ( dt:float; var bmp:Bitmap8# )
    updatePalette()
    beforeDraw(bmp)
    runMenu(dt,mainMenuSelection,mainMenuOptions)
    rast_fillRect(bmp,0,0,bmp.size.x,bmp.size.y,uint8(Color RED_BACKGROUND))
    assume opic = Pictures[int(PictureIndex OPTIONS)]
    rast_fillRect(bmp,0,0,bmp.size.x,bmp.size.y,opic.texels[0])
    drawHUDElement(160-opic.width/2, 20, opic.width,opic.height,opic,bmp)
    drawHUDSubElement(0,20,160-opic.width/2,opic.height,0,0,2,opic.height,opic,bmp)
    drawHUDSubElement(160+opic.width/2,20,(320-opic.width)/2,opic.height,0,0,2,opic.height,opic,bmp)
    drawMenu(mainMenuSelection,mainMenuOptions, Fonts[1], dt, bmp)

def episodeMenu ( dt:float; var bmp:Bitmap8# )
    updatePalette()
    beforeDraw(bmp)
    runMenu(dt,episodeMenuSelection,episodeOptions)
    rast_fillRect(bmp,0,0,bmp.size.x,bmp.size.y,uint8(Color RED_BACKGROUND))
    assume opic = Pictures[int(PictureIndex OPTIONS)]
    rast_fillRect(bmp,0,0,bmp.size.x,bmp.size.y,opic.texels[0])
    drawMenu(episodeMenuSelection,episodeOptions, Fonts[0], dt, bmp)
    let text = "Which episode to play?"
    let fdim = getFontTextDim(text,Fonts[1])
    drawFontText(160-fdim.width/2, 3, text, Color YELLOW, bmp, Fonts[1])

def difficultyMenu ( dt:float; var bmp:Bitmap8# )
    updatePalette()
    beforeDraw(bmp)
    runMenu(dt,difficultyMenuSelection,difficultyOptions)
    rast_fillRect(bmp,0,0,bmp.size.x,bmp.size.y,uint8(Color RED_BACKGROUND))
    assume opic = Pictures[int(PictureIndex OPTIONS)]
    rast_fillRect(bmp,0,0,bmp.size.x,bmp.size.y,opic.texels[0])
    drawMenu(difficultyMenuSelection,difficultyOptions, Fonts[0], dt, bmp)
    let text = "How tough are you?"
    let fdim = getFontTextDim(text,Fonts[1])
    drawFontText(160-fdim.width/2, 3, text, Color YELLOW, bmp, Fonts[1])

// ------------------------------------------------------------

def wolf3d_setGameMode ( mode:GameMode )
    gameMode = mode
    splashTimer = DEFAULT_SPLASH_TIMER

def woof3d_main ( app:Application? )
    application = app
    InitFilesFirst()
    // setupLevel(0)
    levelFade = 0.
    dLevelFade = LEVEL_FADE_FACTOR
    wolf3d_setGameMode(GameMode loadScreen0)

def woof3d_update ( dt:float; var backbuffer:Bitmap8# )
    if gameMode == GameMode loadScreen0
        loadScreen0(dt, backbuffer)
    elif gameMode == GameMode loadScreen1
        loadScreen1(dt, backbuffer)
    elif gameMode == GameMode loadScreen2
        loadScreen2(dt, backbuffer)
    elif gameMode == GameMode loadScreen3
        loadScreen3(dt, backbuffer)
    elif gameMode == GameMode mainMenu
        mainMenu(dt, backbuffer)
    elif gameMode == GameMode episodeMenu
        episodeMenu(dt, backbuffer)
    elif gameMode == GameMode difficultyMenu
        difficultyMenu(dt, backbuffer)
    elif gameMode == GameMode playing
        updateGame(dt)
        draw(level, backbuffer)
        application->set_app_sound_position(player.pos, player.dir)

