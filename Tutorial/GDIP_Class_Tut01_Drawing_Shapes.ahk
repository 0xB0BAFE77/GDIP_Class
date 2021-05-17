; gdi+ ahk tutorial 1 written by tic (Tariq Porter)
; Requires Gdip.ahk either in your Lib folder as standard library or using #Include
;
; Tutorial to draw a single ellipse and rectangle to the screen

#SingleInstance, Force
#NoEnv
#Warn
SetBatchLines, -1

#Include GDIP_Class.ahk
Tut1()
Return

*Esc::ExitApp

Tut1(){
    ; Set the width and height we want as our drawing area, to draw everything in. This will be the dimensions of our bitmap
    Width :=1400, Height := 1050
    
    ; Create a layered window (+E0x80000 : must be used for UpdateLayeredWindow to work!) that is always on top (+AlwaysOnTop), has no taskbar entry or caption
    Gui, 1: -Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs +HWNDguiHwnd
    
    ; Show the window
    Gui, 1: Show, NA
    
    ; Create a gdi bitmap with width and height of what we are going to draw into it. This is the entire drawing area for everything
    hbm := gdip.CreateDIBSection(Width, Height)
    
    ; Get a device context compatible with the screen
    hdc := gdip.CreateCompatibleDC()
    
    ; Select the bitmap into the device context
    obm := gdip.SelectObject(hdc, hbm)
    
    ; Get a pointer to the graphics of the bitmap, for use with drawing functions
    G := gdip.Gdip_GraphicsFromHDC(hdc)
    
    ; Set the smoothing mode to antialias = 4 to make shapes appear smother (only used for vector drawing and filling)
    gdip.Gdip_SetSmoothingMode(G, 4)
    
    ; Create a fully opaque red brush (ARGB = Transparency, red, green, blue) to draw a circle
    pBrush := gdip.Gdip_BrushCreateSolid(0xffff0000)
    
    ; Fill the graphics of the bitmap with an ellipse using the brush created
    ; Filling from coordinates (100,50) an ellipse of 200x300
    gdip.Gdip_FillEllipse(G, pBrush, 100, 500, 200, 300)
    
    ;working on
    ; Delete the brush as it is no longer needed and wastes memory
    gdip.Gdip_DeleteBrush(pBrush)
    
    ; Create a slightly transparent (66) blue brush (ARGB = Transparency, red, green, blue) to draw a rectangle
    pBrush := gdip.Gdip_BrushCreateSolid(0x660000ff)
    
    ; Fill the graphics of the bitmap with a rectangle using the brush created
    ; Filling from coordinates (250,80) a rectangle of 300x200
    gdip.Gdip_FillRectangle(G, pBrush, 250, 80, 300, 200)
    
    ; Delete the brush as it is no longer needed and wastes memory
    gdip.Gdip_DeleteBrush(pBrush)
    
    ; Update the specified window we have created (guiHwnd) with a handle to our bitmap (hdc), specifying the x,y,w,h we want it positioned on our screen
    ; So this will position our gui at (0,0) with the Width and Height specified earlier
    gdip.UpdateLayeredWindow(guiHwnd, hdc, 0, 0, Width, Height)
    
    ; Select the object back into the hdc
    gdip.SelectObject(hdc, obm)
    
    ; Now the bitmap may be deleted
    gdip.DeleteObject(hbm)
    
    ; Also the device context related to the bitmap may be deleted
    gdip.DeleteDC(hdc)
    
    ; The graphics may now be deleted
    gdip.Gdip_DeleteGraphics(G)
    Return
}

;#######################################################################
