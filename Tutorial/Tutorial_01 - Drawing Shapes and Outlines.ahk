; GDIP_Class Tutorial #1
; Written by 0xB0BAFE77
; An update on work originally done by Tariq Porter (tic)
; You must have GDIP_Class.ahk in the folder this tutorial is in
; You can omit the #Include if GDIP_Class.ahk is in your Lib folder

; Tutorial #1 - Drawing Shapes
; In this tutorial, you'll learn:
; - How to create a transparent gui to display an image
; - How to create a bitmap using GDIP
; - Drawing to the the bitmap you created
; - Displaying your bitmap on your transparent gui
;
; Everything will be commented out to help with learning
; I'll also be progressing the code as the tutorials go on.
; This tutorial will be coded in the global space and use subroutines.
; All tutorials after this will be done using functions and eventually classes

; Notes, URLS, and other extra information can be found at the bottom of this tutorial

#SingleInstance, Force                                      ; Allows 1 instance of this script to run at a time
SetBatchLines, -1                                           ; Speeds up the script by eliminating script sleep
;#Warn                                                      ; Detects a bunch of possible issues within the script
                                                            ; Beacuse this first tutorial is written globally (and will be the ONLY one done so)
                                                            ; #Warn is omitted to prevent the global/local variable errors that will happen

#Include GDIP_Class.ahk                                     ; Make sure to include GDIP_Class or this script won't work
ToolTip, % "Press escape to exit tutorial."                 ; Notify user how to exit tutorial
    , % A_ScreenWidth/2
    , % A_ScreenHeight/2
GoSub, Tutorial_01
Return

*Esc::ExitApp

Tutorial_01:
    ; First, we need to make the GUI that our drawing will be displayed on
    bmp_w       := A_ScreenWidth                            ; We'll use the screen's width for width
    , bmp_h     := A_ScreenHeight                           ; And we'll use the screen's height for the height
    
    ; Create a new GUI window
    Gui, 1:New, -Caption                    ; Remove title bar and the thick window border/edge
        +E0x80000                           ; Creates a layered window which the UpdateLayeredWindow() method needs
        +AlwaysOnTop                        ; Forces GUI to always be on top
        +ToolWindow                         ; Removes the taskbar button
        +HWNDguiHwnd                        ; Saves the handle of the GUI to guiHwnd
    Gui, 1: Show, NA                        ; Makes the window visible (even though it's transparent right now)
    
    ; Next, we need to create a bitmap to draw to.
    ; These steps will be used regularly in the other tutorials and will be turned into a resuable function in the the next tutorial
    ; We start by calling the CreateDIBSection() method to create a DIB (Device Independant Bitmap) Section and get the handle to it
    hbm := gdip.CreateDIBSection(bmp_w, bmp_h)              ; Supply the width and height we want our bitmap drawing area (canvas) to be
    hdc := gdip.CreateCompatibleDC()                        ; Get a handle to a compatible DC (device context)
    obm := gdip.SelectObject(hdc, hbm)                      ; Move the bitmap into the new DC and return a new bitmap object
    gp  := gdip.Gdip_GraphicsFromHDC(hdc)                   ; Get a pointer to the graphics portion of the DC
    
    ; Sets smoothing (1-7) of the image which controls the quality/antialiasing
    gdip.Gdip_SetSmoothingMode(gp, 7)                       ; 7
    
    ; Let's draw our first shape
    ; We need a tool to "draw" things with and those tools are called pens and brushes
    ; A brush fills in whatever you're drawing while a pen creates only the outline
    ; To make a pen or brush, you must supply an ARBG (Alpha, Red, Green, Blue) hex number
    ; Each ARBG value must be a 2 digit hex numbers (00 - FF)
    ; If you wanted Tomato Red (#FF6347) with half transparency, you'd use 0x80FF6347 for your ARBG
    ; 0x80 = 50% transparency, 0xFF = 100% Red, 0x63 = 39% Green, 0x47 = 28% Blue
    pBrush := gdip.Gdip_BrushCreateSolid(0xFFFF0000)        ; For a solid red brush, we set alpha and red to max (FF)
    
    ; Using the brush we just made, we're going to draw an elipse with the Gdip_FillEllipse() method
    gdip.Gdip_FillEllipse(gp                ; Pointer to our canvas
                        , pBrush            ; The brush to use
                        , 100               ; x-coordinate marking where to start
                        , 100               ; y-coordinate
                        , 100               ; width of the ellipse
                        , 200)              ; height of the ellipse
    
    ; To help cleanup the memory, we'll constantly be deleting things we no longer have a need for
    gdip.Gdip_DeleteBrush(pBrush)                           ; We don't need a solid red brush anymore
    
    ; Next, we'll draw the outline of a rectangle.
    ; P
    pPen    := gdip.Gdip_CreatePen(0xFFFFFF00, 2)          ; First, we make a pen
    pBrush := gdip.Gdip_BrushCreateSolid(0x800000ff)        ; Alpha is set to half transparency (80) and blue is set to max (FF)
    
    ; Fill the graphics of the bitmap with a rectangle using the brush created
    ; Filling from coordinates (250,80) a rectangle of 300x200
    gdip.Gdip_FillRectangle(gp              ; Pointer
                            , pBrush        ; Brush or pen
                            , 250           ; x
                            , 350           ; y
                            , 200           ; width
                            , 100)          ; height
    
    ; Cleanup
    gdip.Gdip_DeleteBrush(pBrush)
    
    ; For our thrid shape, we're going to make a solid yellow triangle outline
    pPen    := gdip.Gdip_CreatePen(0xFFFFFF00, 2)          ; First, we make a pen
    ; When drawing a polygon, you have to provide an x,y coord set for each point
    ; I've modified GDIP_Class to use either a string or an array of arrays
    ; We'll use the original string version
    points  := "500,600|600,500|700,600"                    ; This tells the program to start x500y600 and each subsequent point
    gdip.Gdip_DrawPolygon(gp, pPen, points)                 ; Draw polygon (the 3 coords provided will make a triangle)
    gdip.Gdip_DeletePen(pPen)                               ; Delete the pen as it is no longer needed and wastes memory
    
    ; Now we update the gui with the newly drawn picture and can finally see our work
    gdip.UpdateLayeredWindow(guiHwnd        ; Handle to our transparent gui
                            , hdc           ; The device context we wrote our bitmap to
                            , 0             ; x-coord to put the window
                            , 0             ; y-coord
                            , bmp_w         ; width of the window
                            , bmp_h)        ; height of the window
    
    ; Cleanup time
    ; This is another set of methods that gets ran repeatedly and will be turned into a a reusable function in the next tutorial
    gdip.SelectObject(hdc, obm)             ; First we put the bitmap object we were working with back into the DC
    gdip.DeleteObject(hbm)                  ; Get rid of the bitmap
    gdip.DeleteDC(hdc)                      ; Get rid of the DC
    gdip.Gdip_DeleteGraphics(gp)            ; Get rid of the graphics pointer
Return

; Continuing Education:
; Here are links to more information on key topics covered in this tutorial
; Layered Windows: https://docs.microsoft.com/en-us/windows/win32/winmsg/window-features#layered-windows
; DIB Sections: https://docs.microsoft.com/en-us/windows/win32/gdi/device-independent-bitmaps
; Device Contexts: https://docs.microsoft.com/en-us/windows/win32/gdi/memory-device-contexts

; Notes:
; It's important to remember that any line that starts with an operator (except -- and ++) is assumed to belong to the previous line
