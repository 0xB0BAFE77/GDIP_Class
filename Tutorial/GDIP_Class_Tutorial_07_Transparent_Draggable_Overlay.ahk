#SingleInstance, Force
#NoEnv
#Warn
SetBatchLines, -1

#Include GDIP_Class.ahk
Tut7()
Return

*Esc::ExitApp

Tut7(){
    ; Set the width and height we want as our drawing area, to draw everything in. This will be the dimensions of our bitmap
    Width := 300
    Height := 200

    ; Create a layered window (+E0x80000 : must be used for UpdateLayeredWindow to work!) that is always on top (+AlwaysOnTop), has no taskbar entry or caption
    Gui, 1: -Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs +HWNDguiHwnd
    ; Show the window
    Gui, 1: Show, NA

    hbm := gdip.CreateDIBSection(Width, Height)             ; Create a gdi bitmap with width and height of what we are going to draw into it. This is the entire drawing area for everything
    hdc := gdip.CreateCompatibleDC()                        ; Get a device context compatible with the screen
    obm := gdip.SelectObject(hdc, hbm)                      ; Select the bitmap into the device context
    G := gdip.Gdip_GraphicsFromHDC(hdc)                     ; Get a pointer to the graphics of the bitmap, for use with drawing functions
    gdip.Gdip_SetSmoothingMode(G, 4)                        ; Set the smoothing mode to antialias = 4 to make shapes appear smother (only used for vector drawing and filling)
    pBrush := gdip.Gdip_BrushCreateSolid(0x77000000)        ; Create a partially transparent, black brush (ARGB = Transparency, red, green, blue) to draw a rounded rectangle with

    ; Fill the graphics of the bitmap with a rounded rectangle using the brush created
    ; Filling the entire graphics - from coordinates (0, 0) the entire width and height
    ; The last parameter (20) is the radius of the circles used for the rounded corners
    gdip.Gdip_FillRoundedRectangle(G, pBrush
                                , 0
                                , 0
                                , Width
                                , Height
                                , 20)
    gdip.Gdip_DeleteBrush(pBrush)                           ; Delete the brush as it is no longer needed and wastes memory
    
    ; Update the specified window we have created (guiHwnd) with a handle to our bitmap (hdc), specifying the x,y,w,h we want it positioned on our screen
    ; With some simple maths we can place the gui in the centre of our primary monitor horizontally and vertically at the specified heigth and width
    gdip.UpdateLayeredWindow(guiHwnd, hdc, (A_ScreenWidth-Width)//2, (A_ScreenHeight-Height)//2, Width, Height)
    
    ; By placing this OnMessage here. The function WM_LBUTTONDOWN will be called every time the user left clicks on the gui
    OnMessage(0x201, "WM_LBUTTONDOWN")
    
    ; Select the object back into the hdc
    gdip.SelectObject(hdc, obm)
    
    ; Now the bitmap may be deleted
    gdip.DeleteObject(hbm)
    
    ; Also the device context related to the bitmap may be deleted
    gdip.DeleteDC(hdc)
    
    ; The graphics may now be deleted
    gdip.Gdip_DeleteGraphics(G)
    Return

    Return
}

;#######################################################################
; This function is called every time the user clicks on the gui
; The PostMessage will act on the last found window (this being the gui that launched the subroutine, hence the last parameter not being needed)
WM_LBUTTONDOWN() {
    PostMessage, 0xA1, 2
}
