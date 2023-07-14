options persistent_heap

require woof3d

require daslib/raster_boost
require glfw/glfw_boost
require opengl/opengl_boost
require glsl/glsl_opengl
require daslib/defer
require daslib/safe_addr
require math
require strings
require audio/audio_boost
require audio/opl3
require rtti
require daslib/jobque_boost

var [[in, location=0]] v_position : float2
var [[in, location=2]] v_texcoord : float2
var [[inout]] f_texcoord : float2
var [[uniform]] f_tex : sampler2D
var [[uniform]] f_palette : float4[256]
var [[out]] f_FragColor : float4

[vertex_program]
def vs_main
    f_texcoord = v_texcoord
    gl_Position = float4(-v_position.yx, 0.0, 1.0)

[fragment_program]
def fs_main
    let index = int(texture(f_tex,f_texcoord).x*255.0)
    let color = f_palette[index]
    f_FragColor = color

var program : uint
var vao : uint
var vbo : uint
var ebo : uint
var texture : uint

[vertex_buffer]
struct Vertex
    xy  : float2
    rgb : float3
    uv  : float2

let vertices = [[Vertex
    xy=float2(-1.0, 1.0), uv=float2(0.0,0.0);
    xy=float2( 1.0, 1.0), uv=float2(1.0,0.0);
    xy=float2( 1.0,-1.0), uv=float2(1.0,1.0);
    xy=float2(-1.0,-1.0), uv=float2(0.0,1.0)
]]

let indices = [[int 0; 1; 2; 2; 3; 0]]

var bb_width = 0
var bb_height = 0
var surface : SurfaceData

[finalize]
def cleanup_surface
    delete surface

def get_screen_size
    return int2(bb_width,bb_height)

def update_bb ( var w, h : int )
    w = (w+3) & ~3
    h = (h+3) & ~3
    if w==bb_width && h==bb_height
        return false
    bb_width = w
    bb_height = h
    return true

def create_gl_objects(w,h : int)
    program = create_shader_program(@@vs_main,@@fs_main)
    // vao
    glGenVertexArrays(1, safe_addr(vao))
    glBindVertexArray(vao);
    // vbo
    glGenBuffers(1, safe_addr(vbo))
    glBindBuffer(GL_ARRAY_BUFFER, vbo)
    glBufferData(GL_ARRAY_BUFFER, vertices, GL_STATIC_DRAW)
    bind_vertex_buffer(null,type<Vertex>)
    // ebo
    glGenBuffers(1, safe_addr(ebo))
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo)
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices, GL_STATIC_DRAW)
    // texture
    update_bb(w,h)

var cursor_position_xy : float2
var cursor_delta_xy : float2
var mouse_buttons : int

variant MusicCommand
    stop : bool
    play : array<uint8>

def decodeIMFT ( var src : array<uint8>; hertz : int )
    return <- generator<float> [[:=src]] () <|
        var pchip = new Opl3Chip
        let llength = int(getUInt16(src, 0))
        OPL3_Reset(*pchip, hertz)
        let delay_1 = hertz / 700
        for i in range(llength/4)
            let reg = src |> getUInt8(2+i*4+0)
            let rdata = src |> getUInt8(2+i*4+1)
            let delay = int(src |> getUInt16(2+i*4+2))
            if reg != 0u8
                OPL3_WriteReg ( *pchip, uint(reg), rdata )
            if delay != 0
                let samples = delay * delay_1 * 2
                var tmp : array<uint16>
                tmp |> resize_no_init(samples)
                OPL3_GenerateStream(*pchip, tmp)
                for tb in tmp
                    yield float(int16(tb)) / 32768.0
        return false
    finally
        unsafe
            delete pchip

class OpenglApplication : woof3d::Application
    upButton, prevUpButton : bool
    downButton, prevDownButton : bool
    okButton, prevOkButton : bool
    cancelButton, prevCancelButton : bool
    music_sid : SID
    music_channel : Channel?
    def OpenglApplication
        music_sid = play_sound_from_pcm_stream(MA_SAMPLE_RATE,2)
        unsafe
            music_channel = channel_create()
        var mch = music_channel
        var cch = get_audio_command_channel()
        var msid = music_sid
        new_thread <| @
            mch |> append(1)
            unsafe
                set_audio_thread_command_channel(cch)
            var stopped = false
            var imft : iterator<float>
            while !stopped
                var commands : array<MusicCommand>
                mch |> gather <| $ ( cmd:MusicCommand# )
                    commands |> push_clone(cmd)
                for cmd in commands
                    if cmd is stop
                        stopped = true
                    elif cmd is play
                        delete imft
                        imft <- decodeIMFT(cmd as play, MA_SAMPLE_RATE)
                if stopped
                    break
                if !empty(imft)
                    var data : array<float>
                    data |> reserve(1024)
                    for i in range(1024)
                        var sample : float
                        if !next(imft, sample)
                            break
                        data |> push(sample)
                    append_to_pcm(msid, data)
            mch |> notify_and_release

    def finalize
        music_channel |> push_clone <| [[MusicCommand stop=true]]
        music_channel |> join
        unsafe(channel_remove(music_channel))
        music_channel = null
        stop(music_sid)
    def override quit : void
        glfwSetWindowShouldClose(window, GLFW_TRUE)
    def override play_app_music ( data : array<uint8> ) : void
        music_channel |> push_clone <| [[MusicCommand play <- clone_to_move(data)]]
    def override play_app_sound ( wave:array<float>; freq:int )
        play_sound_from_pcm(freq, 1, clone_to_move(wave))
    def override play_app_sound_2d ( pos:float2; radius:float; wave:array<float>; freq:int )
        play_3d_sound_from_pcm(float3(pos,0.), radius, freq, 1, clone_to_move(wave))
    def override set_app_sound_position ( xy:float2; dxy:float2 )
        set_head_position(float3(xy,0.), float3(dxy,0.))
    def update_controls
        // update cursor
        if glfwGetWindowAttrib(window, int(GLFW_FOCUSED))==GLFW_FALSE
            mouseDelta = float2(0.)
            return
        var cxy = glfwGetCursorPos(window)
        cursor_delta_xy = cxy - cursor_position_xy
        cursor_position_xy = float2(bb_width/2,bb_height/2)
        glfwSetCursorPos(window, double(cursor_position_xy.x), double(cursor_position_xy.y))
        // controls
        shootButton = (glfwGetKey(window, GLFW_KEY_LEFT_CONTROL)==GLFW_PRESS
            || glfwGetKey(window, GLFW_KEY_RIGHT_CONTROL)==GLFW_PRESS
            || glfwGetMouseButton(window,GLFW_MOUSE_BUTTON_1)==GLFW_PRESS)
        activateButton = (glfwGetKey(window, GLFW_KEY_SPACE)==GLFW_PRESS
            || glfwGetKey(window, GLFW_KEY_ENTER)==GLFW_PRESS
            || glfwGetMouseButton(window,GLFW_MOUSE_BUTTON_2)==GLFW_PRESS)
        weapon1Button = glfwGetKey(window, GLFW_KEY_1)==GLFW_PRESS
        weapon2Button = glfwGetKey(window, GLFW_KEY_2)==GLFW_PRESS
        weapon3Button = glfwGetKey(window, GLFW_KEY_3)==GLFW_PRESS
        weapon4Button = glfwGetKey(window, GLFW_KEY_4)==GLFW_PRESS
        leftButton = glfwGetKey(window, GLFW_KEY_LEFT)==GLFW_PRESS
        rightButton = glfwGetKey(window, GLFW_KEY_RIGHT)==GLFW_PRESS
        forwardButton = glfwGetKey(window, GLFW_KEY_UP)==GLFW_PRESS || glfwGetKey(window, GLFW_KEY_W)==GLFW_PRESS
        backwardButton = glfwGetKey(window, GLFW_KEY_DOWN)==GLFW_PRESS || glfwGetKey(window, GLFW_KEY_S)==GLFW_PRESS
        strafeLeftButton = glfwGetKey(window, GLFW_KEY_A)==GLFW_PRESS
        strafeRightButton = glfwGetKey(window, GLFW_KEY_D)==GLFW_PRESS
        mapButton = glfwGetKey(window, GLFW_KEY_TAB)==GLFW_PRESS
        // mouse
        mouseDelta = cursor_delta_xy
        // cheat codes
        cheatGiveEverything = glfwGetKey(window, GLFW_KEY_F1)==GLFW_PRESS
        cheat1 = glfwGetKey(window, GLFW_KEY_F8)==GLFW_PRESS
        cheat2 = glfwGetKey(window, GLFW_KEY_F9)==GLFW_PRESS
        cheat3 = glfwGetKey(window, GLFW_KEY_F2)==GLFW_PRESS
        cheatSwitchLevel = glfwGetKey(window, GLFW_KEY_F10)==GLFW_PRESS
        cheatSwitchLevelShift = glfwGetKey(window, GLFW_KEY_LEFT_SHIFT)==GLFW_PRESS || glfwGetKey(window, GLFW_KEY_RIGHT_SHIFT)==GLFW_PRESS
        // button pressed
        prevOkButton = okButton
        prevCancelButton = cancelButton
        prevUpButton = upButton
        prevDownButton = downButton
        okButton = shootButton || activateButton
        cancelButton = glfwGetKey(window, GLFW_KEY_ESCAPE)==GLFW_PRESS
        upButton = forwardButton
        downButton = backwardButton
        okButtonPressed = okButton && !prevOkButton
        cancelButtonPressed = cancelButton && !prevCancelButton
        upButtonPressed = upButton && !prevUpButton
        downButtonPressed = downButton && !prevDownButton

var window : GLFWwindow?

var dt_sec = 0.0lf

def get_delta_time_sec
    return float(dt_sec)

def fmt_msec ( msecs : float )
    let flt = build_string <| $ ( writer )
        writer |> format("%.1f",msecs)
    return "{flt}ms"

[export]
def main
    if glfwInit()==0
		panic("can't init glfw")
    defer <|
        glfwTerminate()
    with_audio_system <|
        glfwInitOpenGL(3,3)
        this_context().category |= context_category_flags opengl
        window = glfwCreateWindow(1920, 1080, "RASTER2D", null, null)
        if window==null
            panic("can't create window")
        defer <|
            glfwDestroyWindow(window)
        glfwMakeContextCurrent(window)
        var display_w, display_h : int
        glfwGetFramebufferSize(window, display_w, display_h)
        create_gl_objects(display_w, display_h)
        glfwSetInputMode(window, int(GLFW_CURSOR), int(GLFW_CURSOR_HIDDEN))
        glfwSetInputMode(window, int(GLFW_RAW_MOUSE_MOTION), int(GLFW_TRUE))
        cursor_position_xy = glfwGetCursorPos(window)
        var tframe = ref_time_ticks()
        var prev_sec = glfwGetTime()
        var msecs = 12.
        var fmsec = 16.
        var application = new OpenglApplication()
        woof3d_main(application)
        while glfwWindowShouldClose(window)==0
            var tsec = glfwGetTime()
            dt_sec = tsec - prev_sec
            prev_sec = tsec
            var dt_frame = get_time_usec(tframe)
            tframe = ref_time_ticks()
            fmsec = fmsec*0.95 + float(dt_frame/1000)*0.05
            application->update_controls()
            unsafe
                heap_collect(true,true)
            glfwPollEvents()
            glfwGetFramebufferSize(window, display_w, display_h)
            update_bb(display_w, display_h)
            // callbakck
            if bb_width!=0 && bb_height!=0
                let t0 = ref_time_ticks()
                let surfaceSize = bitmap8_size(int2(bb_width,bb_height))
                if surface.size != surfaceSize
                    delete surface
                    unsafe
                        surface <- SurfaceData(surfaceSize)
                surface |> make_bitmap8(int2(bb_width,bb_height)) <| $ ( bmp )
                    woof3d_update(fmsec, unsafe(reinterpret<Bitmap8#> bmp))
                    for p,d in bmp.palette,f_palette
                        d = unpack_byte_to_float(p) / 255.
                let dt = get_time_usec(t0)
                msecs = msecs*0.95 + float(dt/1000)*0.05
                glfwSetWindowTitle(window, "WOOF3D {bb_width}x{bb_height} frame:{fmt_msec(fmsec)} rast:{fmt_msec(msecs)} mem:{int64(heap_bytes_allocated())/1024l}kb")
            // make a texture
            glGenTextures(1, safe_addr(texture))
            glBindTexture(GL_TEXTURE_2D, texture)
            glTexImage2D(GL_TEXTURE_2D, 0, int(GL_R8), bb_height, bb_width, 0, GL_RED, GL_UNSIGNED_BYTE, surface.data)
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
            glBindTexture(GL_TEXTURE_2D, GL_INVALID_VALUE)
            // render
            glViewport(0, 0, display_w, display_h)
            glDisable(GL_DEPTH_TEST)
            glDepthMask(false)
            glUseProgram(program)
            f_tex := texture           // bind texture
            vs_main_bind_uniform(program)
            fs_main_bind_uniform(program)
            glBindVertexArray(vao)
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo)
            glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null)
            glBindTexture(GL_TEXTURE_2D, GL_INVALID_VALUE)
            // kill texture
            glDeleteTextures(1, safe_addr(texture))
            // swap buffersa
            glfwMakeContextCurrent(window)
            glfwSwapBuffers(window)
        unsafe
            delete application
