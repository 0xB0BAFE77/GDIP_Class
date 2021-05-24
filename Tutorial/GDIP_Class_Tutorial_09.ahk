#SingleInstance, Force
#NoEnv
#Warn
SetBatchLines, -1

#Include GDIP_Class.ahk
Tut09()
Return

*Esc::ExitApp

; The purpose of this tutorial is to create a fully customized progress bar
; Note that AHK does already provide a progress bar feature with its GUI commands
; This progress bar is made using a rectangular picture element
; The element is filled with a rectangle and overlayed with a slightly smaller rectangle with rounded corners
Tut09() {
    ; Before we start there are some design elements we must consider.
    ; We can either make the script faster. Creating the bitmap 1st and just write the new progress bar onto it every time and updating it on the gui
    ; and dispose it all at the end/ This will use more RAM
    ; Or we can create the entire bitmap and write the information to it, display it and then delete it after every occurence
    ; This will be slower, but will use less RAM and will be modular (can all be put into a function)
    ; I will go with the 2nd option, but if more speed is a requirement then choose the 1st
    
    hwnd_arr := {}                                                                      ; Create an object to store some handles in
    Gui, T09:New, -DPIScale                                                             ; 
    Gui, T09:Default                                                                    ; 
    Gui, Add, Slider, x10 y10 w400 Range0-100 Tooltip Gon_slider_release HWNDhwnd, 50   ; 
        hwnd_arr.slider := hwnd                                                         ; 
    Gui, Add, Picture, x10 y+30 w400 h50 0xE HWNDhwnd                                   ;
        hwnd_arr.picture := hwnd                                                        ; 
    on_slider_release(,,,,hwnd_arr)                                                     ; Run function once to set the initial drawings before showing the GUI
    Gui, Show, AutoSize, Example 9 - gdi+ progress bar                                  ; Show the GUI with the custom progress bar
    Return
}

; This is the function that fires when the slider bar is released
; color_bg and color_fg are the background and foreground colors of the progress bar
; new_hwnd is used to set an array of handles to the function
; The Text, TextOptions, and Font could be moved to the parameters of the function if you wanted but I see no reason for it here
on_slider_release(CtrlHwnd:="", GuiEvent:="", EventInfo:="", ErrLevel:="", new_hwnd:=0) {
    Static hwnd         := ""
        , TextOptions   := "x0p y15p s60p Center cff000000 r4 Bold"
        , Font          := "Arial"
        , color_bg      := 0xFF0993EA
        , color_fg      := 0xFFBDE5FF
    
    If (new_hwnd != 0)                                              ; Set the new handle array if there is one.
        hwnd := new_hwnd
    
    pic_w := pic_h := 0
    GuiControlGet, pic_, Pos, % hwnd.picture                        ; Get the WHXY for the GUI picture element
    GuiControlGet, percent, , % hwnd.slider                         ; Get the current percent
    
    pBitmap         := gdip.Gdip_CreateBitmap(pic_w, pic_h)         ; Create a new bitmap that we will write to the GUI
    , gp            := gdip.Gdip_GraphicsFromImage(pBitmap)         ; Get a pointer to the graphis of the bitmap
    , pBrushFront   := gdip.Gdip_BrushCreateSolid(color_fg)         ; Create a brush for the foreground
    , pBrushBack    := gdip.Gdip_BrushCreateSolid(color_bg)         ; Create a brush for the background
    , gdip.Gdip_SetSmoothingMode(gp, 4)                             ; Setting antialiasing to 4 creates the smoothest image
    , gdip.Gdip_FillRectangle(gp, pBrushBack, 0, 0, pic_w, pic_h)   ; Create the background of the progress bar
    , gdip.Gdip_FillRoundedRectangle(gp, pBrushFront, 4, 4          ; Create the foreground (pointer, brush, x-coord, y-coord
                    , (pic_w-8)*(percent/100), pic_h-8              ; rectangle width, rectangle height
                    , (percent >= 3) ? 3 : percent)                 ; radius of rounded corners)
    , gdip.Gdip_TextToGraphics(gp                                   ; Add the text percentage to the bar (pointer,
                    , Round(percent) "`%"                           ; text to add, 
                    , TextOptions, Font                             ; text options, font,
                    , pic_w, pic_h)                                 ; pic element width, pic element height)
    , hBitmap       := gdip.Gdip_CreateHBITMAPFromBitmap(pBitmap)   ; Get a handle the bitmap we just made
    , gdip.SetImage(hwnd.picture, hBitmap)                          ; Use handle to assign new bitmap to GUI's picture element
    
    ; Cleanup/garbage collection 
    gdip.Gdip_DeleteBrush(pBrushFront)                              ; Delete foreground brush
    , gdip.Gdip_DeleteBrush(pBrushBack)                             ; Delete background brush
    , gdip.Gdip_DeleteGraphics(gp)                                  ; Delete graphics
    , gdip.Gdip_DisposeImage(pBitmap)                               ; Delete bitmap
    , gdip.DeleteObject(hBitmap)                                    ; Delete delete bitmap object
    
    Return 0
}

; Close script when GUI is closed
GuiClose() {
    ExitApp
}
