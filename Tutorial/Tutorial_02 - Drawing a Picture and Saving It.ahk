; GDIP_Class Tutorial #2
; Written by 0xB0BAFE77
; A continuation on work originally done by Tariq Porter (tic)
; You must have GDIP_Class.ahk in the same folder as this tutorial

; Tutorial #2 - Drawing a Picture and Saving It
; In this tutorial, we will:
; - No longer be working in the global space but instead will start using functions (as it shold be)
; - Make new functions to create/destroy bitmaps, draw images, and more. These will be reused throughout the tutorials
; - Explore the new color() and alpha_perc() methods added to the library
; - Draw a picture using the shape commands from Tutorial 01
; - Save our finished bitmap to disk
;
; If no comments are present by something, it was covered in a previous tutorial
; Extra notes, URLS, and other information can be found at the bottom of this tutorial

#SingleInstance, Force                                      ; Allows 1 instance of this script to run at a time
SetBatchLines, -1                                           ; Speeds up the script by eliminating script sleep
;#Warn                                                      ; Detects a bunch of possible issues within the script
;                                                           ; Beacuse this first tutorial is written globally (and will be the ONLY one done so)
;                                                           ; #Warn is omitted to prevent the global/local variable errors that will happen

; If GDIP_Class.ahk is in your Lib folder you can 
#Include GDIP_Class.ahk                                     ; Make sure to include GDIP_Class or this script won't work
ToolTip, % "Press escape to exit tutorial."                 ; Notify user how to exit tutorial
    , % A_ScreenWidth/2
    , % A_ScreenHeight/2
Tutorial_2()                                                ; Run the tutorial
Return

*Esc::ExitApp

Tutorial_02() {
    ; Let's use our new function to create a new bitmap
    ; This function will return a bmo (Bitmap Object). It's an object that contains all
    ; the info about the new bitmap we created. BMO will be used with all of our new functions.
    ; We must provide this function with a width and height for out bitmap
    bmo     := bitmap_new(600, 400)
    gdip.Gdip_SetSmoothingMode(bmo.gp, 7)
    
    ; To make things easy, let's make an object called color
    ; Add all the colors we're going to be using
    color   :=  {"sky"      : gdip.color.DeepSkyBlue
                ,"grass"    : gdip.color.Green
                ,"house"    : gdip.color.Wheat
                ,"door"     : gdip.color.Sienna
                ,"window"   : gdip.color.Gold
                ,"roof"     : gdip.color.DarkGray
                ,"sun"      : gdip.color.Yellow
                ,"cloud"    : gdip.color.GhostWhite
                ,"leaves"   : gdip.color.DarkGreen
                ,"trunk"    : gdip.color.SaddleBrown }
    
    ; We're going to draw a basic house with a sun in the sky.
    ; We've made 3 new functions to draw stuff: draw_ellipse(), draw_rectangle(), draw_polygon()
    ; Each function has usage instructions by it
    ; To draw this image, we the furthest thing first and the closest thing last
    ; Let's make the sky
    draw_rectangle(bmo, 0xFF, color.sky, x, y, width, height, pen_size:=0)
    ;draw_rectangle(bmo, arbg, x, y, width, height, pen_size:=0)
    ;draw_polygon(bmo, arbg, points, pen_size:=0)
    
    ; Next, we'll draw the outline of a rectangle.
    ; P
    pPen    := gdip.Gdip_CreatePen(0xFFFFFF00, 2)          ; First, we make a pen
    pBrush  := gdip.Gdip_BrushCreateSolid(0x800000ff)        ; Alpha is set to half transparency (80) and blue is set to max (FF)
    
    ; Cleanup
    gdip.Gdip_DeleteBrush(pBrush)
    
    ; For our thrid shape, we're going to make a solid yellow triangle outline
    pPen    := gdip.Gdip_CreatePen(0xFFFFFF00, 2)          ; First, we make a pen
    gdip.Gdip_DeletePen(pPen)                               ; Delete the pen as it is no longer needed and wastes memory
    
    ; Now we update the gui with the newly drawn picture and can finally see our work
    gdip.UpdateLayeredWindow(guiHwnd        ; Handle to our transparent gui
                            , hdc           ; The device context we wrote our bitmap to
                            , 0             ; x-coord to put the window
                            , 0             ; y-coord
                            , bmp_w         ; width of the window
                            , bmp_h)        ; height of the window
    
    Return
}

; Creates a new bitmap through GDI+
; Requires a width and height
; Optionall requires a handle to GUI with the layered window style
; This function returns an object with the following properties:
;   obj.gui_hwnd  = Handle to the layered window being drawn to
;   obj.width     = Width of the bitmap
;   obj.height    = Height of the bitmap
;   obj.hbm       = Handle to the bitmap
;   obj.hdc       = Handle to the device context
;   obj.obm       = Handle to the new bitmap object
;   obj.gp        = Pointer to the bitmap's graphics
bitmap_new(bmp_w, bmp_h, gui_hwnd:="") {
    obj := {}
    
    ; If no gui handle is passed, create a new one and assign it to the object
    obj.gui_hwnd := (gui_hwnd = "")
        ? new_layered_window()
        : gui_hwnd
    
    ; Next, we need to create a bitmap to draw to.
    ; These steps will be used regularly in the other tutorials and will be turned into a resuable function in the the next tutorial
    ; We start by calling the CreateDIBSection() method to create a DIB (Device Independant Bitmap) Section and get the handle to it
    obj.hbm := gdip.CreateDIBSection(bmp_w, bmp_h)              ; Supply the width and height we want our bitmap drawing area (canvas) to be
    obj.hdc := gdip.CreateCompatibleDC()                        ; Get a handle to a compatible DC (device context)
    obj.obm := gdip.SelectObject(hdc, hbm)                      ; Move the bitmap into the new DC and return a new bitmap object
    obj.gp  := gdip.Gdip_GraphicsFromHDC(hdc)                   ; Get a pointer to the graphics portion of the DC
    Return obj
}

new_layered_window(gui_name:="") {
    Gui, % (gui_name = "" ? "" : gui_name ":") "New"
        ,-Caption +E0x80000 +AlwaysOnTop +ToolWindow +HWNDgui_hwnd
    Gui, 1: Show, NA
    Return gui_hwnd
}

; Delete a bitmap no longer in use
bitmap_delete(bmo) {
    gdip.SelectObject(bmo.hdc, bmo.obm)
    , gdip.DeleteObject(bmo.hbm)
    , gdip.DeleteDC(bmo.hdc)
    , gdip.Gdip_DeleteGraphics(bmo.gp)
    Return
}

; Draws an ellipse
; Requires a bmo, percent alpha, a hex color 6 digits long,
;   x and y coord of the ellipse, and the width and height
; If the last parameter is 0 or is omitted, the ellipse is filled in
; Otherwise, that number is treated as pen thickness and an outline will be drawn instead
draw_ellipse(bmo, alpha, color, x, y, width, height, pen_size:=0) {
    arbg := gdip.Gdip_ToARGB(alpha
                            ,
                            ,
                            ,)
    If (pen_size= 0)
    {
        brush := gdip.Gdip_BrushCreateSolid()
        gdip.Gdip_FillEllipse(bmo.gp, brush, x, y, width, height)
        Gdip_DeleteBrush(brush)
    }
    Else
    {
        pen := gdip.Gdip_CreatePen(arbg, pen_size)
        gdip.Gdip_DrawEllipse(bmo.gp, pen, x, y, width, height)
        gdip.Gdip_DeletePen(pen)
    }
    Return
}

; Draws an rectangle
; Requires a bmo, an ARBG, x and y coord of the draw, and width and height of the rectangle
; If the last parameter is 0 or is omitted, the ellipse is filled in
; Otherwise, that number is treated as pen thickness and an outline will be drawn instead
draw_rectangle(bmo, arbg, x, y, width, height, pen_size:=0) {
    If (pen_size= 0)
    {
        brush := gdip.Gdip_BrushCreateSolid(arbg)
        gdip.Gdip_FillRectangle(bmo.gp, brush, x, y, width, height)
        Gdip_DeleteBrush(brush)
    }
    Else
    {
        pen := gdip.Gdip_CreatePen(arbg, pen_size)
        gdip.Gdip_DrawRectangle(bmo.gp, pen, x, y, width, height)
        gdip.Gdip_DeletePen(pen)
    }
    Return
}

; Draws a polygon
; Requires a bmo, an ARBG, and a list of points. The list of points can be:
;   a string = "0,0|5,10|0,10"
;   an array of strings = ["0,0", "5,10", "0,10"]
;   an array of arrays = [[0,0], [5,10], [0,10]]
; If the last parameter is 0 or is omitted, the ellipse is filled in
; Otherwise, that number is treated as pen thickness and an outline will be drawn instead
draw_polygon(bmo, arbg, points, pen_size:=0) {
    If (pen_size > 0)
    {
        pen := gdip.Gdip_CreatePen(arbg, pen_size)
        gdip.Gdip_DrawPolygon(bmo.gp, pen, points)
        gdip.Gdip_DeletePen(pen)
    }
    Else
    {
        brush := gdip.Gdip_BrushCreateSolid(arbg)
        gdip.Gdip_FillPolygon(bmo.gp, brush, points)
        Gdip_DeleteBrush(brush)
    }
    Return
}





; Continuing Education:
; Here are links to more information on key topics covered in this tutorial
; Layered Windows: https://docs.microsoft.com/en-us/windows/win32/winmsg/window-features#layered-windows
; DIB Sections: https://docs.microsoft.com/en-us/windows/win32/gdi/device-independent-bitmaps
; Device Contexts: https://docs.microsoft.com/en-us/windows/win32/gdi/memory-device-contexts

; Notes:
; It's important to remember that any line that starts with an operator (except -- and ++) is assumed to belong to the previous line
