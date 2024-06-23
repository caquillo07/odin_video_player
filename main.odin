package main

import "core:fmt"
import "core:log"
import "core:os"

import avcodec "./vendors/odin-ffmpeg/avcodec"
import avformat "./vendors/odin-ffmpeg/avformat"
import fftypes "./vendors/odin-ffmpeg/types"

import sdl2 "vendor:sdl2"
import sdlimg "vendor:sdl2/image"

WindowWidth :: 1280
WindowHeight :: 720

App :: struct {
    window:      ^sdl2.Window,
    renderer:    ^sdl2.Renderer,
    shouldClose: bool,
    //    app_start:     f64,

    //    frame_start:   f64,
    //    frame_end:     f64,
    //    frame_elapsed: f64,
}

closeApp :: proc(app: App) {
    sdl2.DestroyRenderer(app.renderer)
    sdl2.DestroyWindow(app.window)
    sdl2.Quit()
}

app: App

main :: proc() {
    context.logger = log.create_console_logger()
    if sdlRes := sdl2.Init(sdl2.INIT_VIDEO); sdlRes < 0 {
        log.fatalf("failed to init sdl2 %v.", sdlRes)
    }
    log.info("loaded SDL Video")

    formatCtx: ^fftypes.AVFormatContext
    if avformat.open_input(&formatCtx, "demo.mp4", nil, nil) < 0 {
        log.fatalf("failed to open demo.mp4")
    }


    //    imageInitFlags := sdlimg.INIT_PNG
    //    imageInitRes := sdlimg.InitFlags(sdlimg.Init(imageInitFlags))
    //    if imageInitFlags != imageInitRes {
    //        log.panicf("failed to init SDL2 image: expected: %v - got: %v", imageInitFlags, imageInitRes)
    //    }
    //    log.info("loaded SDL Image")
    if avformat.find_stream_info(formatCtx, nil) < 0 {
        log.fatalf("failed to find stream info")
    }

    avformat.dump_format(formatCtx, 0, "demo.mp4", 0)

    videoStream: i32 = -1
    log.infof("formatCtx: %v", formatCtx)
    for i := u32(0); i < formatCtx.nb_streams; i += 1 {
        if formatCtx.streams[i].codecpar.codec_type == .Video {
            videoStream = i32(i)
            break
        }
    }
    assert(videoStream != -1)
    fmt.printf("%d\n", videoStream)

    codec := avcodec.find_decoder(formatCtx.streams[videoStream].codecpar.codec_id)
    assert(codec != nil)
    fmt.printf("%#v\n", codec)

    codecContextOrig := avcodec.alloc_context3(codec)
    if avcodec.parameters_to_context(codecContextOrig, formatCtx.streams[videoStream].codecpar) != 0 {
        log.fatalf("failed parameters_to_context on codecContextOrig")
    }
    /**
     * Note that we must not use the AVCodecContext from the video stream
     * directly! So we have to use avcodec_copy_context() to copy the
     * context to a new location (after allocating memory for it, of
     * course).
     */
    codecContext := avcodec.alloc_context3(codec)
    if avcodec.parameters_to_context(codecContext, formatCtx.streams[videoStream].codecpar) != 0 {
        log.fatalf("failed parameters_to_context on codecContext")
    }

    if avcodec.open2(codecContext, codec, nil) < 0 {
        log.fatalf("could not open codec")
    }

    fmt.printf("%#v\n", codecContext)

    window := sdl2.CreateWindow(
        "Odin Video PLayer",
        sdl2.WINDOWPOS_UNDEFINED,
        sdl2.WINDOWPOS_UNDEFINED,
        WindowWidth,
        WindowHeight,
        {},
    )
    assert(window != nil)

    renderer := sdl2.CreateRenderer(
        window,
        -1,
        sdl2.RENDERER_ACCELERATED | sdl2.RENDERER_PRESENTVSYNC | sdl2.RENDERER_TARGETTEXTURE,
    )
    assert(renderer != nil)

    app.window = window
    app.renderer = renderer

    defer closeApp(app)

    for !app.shouldClose {
        process_input(&app)
        update(&app)
        draw(&app)
    }
}

process_input :: proc(app: ^App) {
    e: sdl2.Event
    for sdl2.PollEvent(&e) {
        if e.type == sdl2.EventType.QUIT {
            app.shouldClose = true
            return
        }
        #partial switch (e.type) {
        case .QUIT:
        case .KEYDOWN:
            #partial switch (e.key.keysym.sym) {
            case .ESCAPE:
                app.shouldClose = true
                return
            }
        }
    }
}

update :: proc(app: ^App) {

}

draw :: proc(app: ^App) {
    sdl2.SetRenderDrawColor(app.renderer, 175, 175, 175, 255)
    sdl2.RenderClear(app.renderer)

    sdl2.RenderPresent(app.renderer)
}
