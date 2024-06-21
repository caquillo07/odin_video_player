package main

import "core:fmt"
import "core:log"
import "core:os"

import avformat "./vendors/odin-ffmpeg-bindings/avformat"
import fftypes "./vendors/odin-ffmpeg-bindings/types"

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

main :: proc() {
    context.logger = log.create_console_logger()
    if sdlRes := sdl2.Init(sdl2.INIT_VIDEO); sdlRes < 0 {
        log.fatalf("failed to init sdl2 %v.", sdlRes)
    }

    formatCtx: ^fftypes.Format_Context
    if avformat.open_input(&formatCtx, "demo.mp4", nil, nil) < 0 {
        log.fatalf("failed to open demo.mp4")
    }

    log.info("loaded SDL Video")

    imageInitFlags := sdlimg.INIT_PNG
    imageInitRes := sdlimg.InitFlags(sdlimg.Init(imageInitFlags))
    if imageInitFlags != imageInitRes {
        log.panicf("failed to init SDL2 image: expected: %v - got: %v", imageInitFlags, imageInitRes)
    }
    log.info("loaded SDL Image")

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

    app := App {
        window   = window,
        renderer = renderer,
    }
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
