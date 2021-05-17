; gdi+ ahk tutorial 1 written by tic (Tariq Porter)
; Requires Gdip.ahk either in your Lib folder as standard library or using #Include
;
; Tutorial to draw a single ellipse and rectangle to the screen

#SingleInstance, Force
#NoEnv
#Warn
SetBatchLines, -1

#Include GDIP_Class.ahk
Tut4()
Return

*Esc::ExitApp

Tut4(){
    ; Create a layered window (+E0x80000) that is always on top (+AlwaysOnTop), has no taskbar entry or caption
    Gui, New, -Caption      ; 
        +E0x80000           ; Windows Extended Style to create a layered window
        +HWNDguiHwnd        ; Save the handle of the gui to guiHwnd
        +AlwaysOnTop        ; Makes the gui/canvas always the top window
        +ToolWindow         ; 
        +OwnDialogs         ; 
    Gui, Show, NA
    
    g_obj           := {}                                               ; Make an object to store the bitmap info
    , mon           := Get_Monitor_Dim()                                ; Get the dimensions of the primary monitor
    , g_obj.hwnd    := guiHwnd                                          ; Save GUI's handle
    , g_obj.hbm     := gdip.CreateDIBSection(mon.width, mon.height)     ; Create a gdi bitmap with width and height of the work area
    , g_obj.hdc     := gdip.CreateCompatibleDC()                        ; Get a device context compatible with the screen
    , g_obj.obm     := gdip.SelectObject(g_obj.hdc, g_obj.hbm)          ; Select the bitmap into the device context
    , g_obj.gp      := gdip.Gdip_GraphicsFromHDC(g_obj.hdc)             ; Get a pointer to the graphics of the bitmap, for use with drawing functions
    , gdip.Gdip_SetSmoothingMode(g_obj.gp, 4)                           ; Set the smoothing mode to antialias = 4 to make shapes appear smother (only used for vector drawing and filling)
    , bf            :=  Func("DrawCircle").bind(g_obj)                  ; Create a boundfunc to store your g_obj
    SetTimer, % bf, 50                                                  ; Fun your boundfunc on a timer
    Return
}

DrawCircle(g_obj){
    ; Get monitor info and generate ellipse values
    mon     := Get_Monitor_Dim()                                        ; Get primary monitor dimensions
    , r_w   := gdip.Rand(1, 200)                                        ; Pick a random width
    , r_h   := gdip.Rand(1, 200)                                        ; Pick a random height
    , r_x   := gdip.Rand(mon.left, (mon.width-r_w) )                    ; Pick a random x coord
    , r_y   := gdip.Rand(mon.top, (mon.height-r_h) )                    ; Pick a random y coord

    ; Create a very random brush
    pBrush := gdip.Gdip_BrushCreateHatch(gdip.Rand(0x0, 0xFFFFFFFF)     ; Pick random background
                                   ,gdip.Rand(0x0, 0xFFFFFFFF)          ; Pick random foreground
                                   ,gdip.Rand(0,53) )                   ; Pick random brush hatch
    
    , gdip.Gdip_FillEllipse(g_obj.gp, pBrush, r_x, r_y, r_w, r_h)       ; Create ellipse using generated vars
    , gdip.UpdateLayeredWindow(g_obj.hwnd, g_obj.hdc                    ; Update the specified window
                            , mon.left, mon.top, mon.width, mon.height)
    gdip.Gdip_DeleteBrush(pBrush)                                       ; Delete brush to free up memory
    
    ToolTip, Hit Escape to stop script.                                 ; Notify how to stop

    Return
}

; Pass a monitor number if already known otherwise primary monitor will be used
; Returns object with coords
; Object properties: .left .right .top .bottom .width .height
Get_Monitor_Dim(monitor_num:="") {
    SysGet, WA_, MonitorWorkArea, % monitor_num  ; Get work area of monitor
    arr := {}
    , arr.left      := WA_Left
    , arr.right     := WA_Right
    , arr.top       := WA_Top
    , arr.bottom    := WA_Bottom
    , arr.width     := WA_Right - WA_Left
    , arr.height    := WA_Bottom - WA_Top
    
    Return arr
}

;#######################################################################