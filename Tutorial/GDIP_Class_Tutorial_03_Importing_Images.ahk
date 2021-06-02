#SingleInstance, Force
#NoEnv
#Warn
SetBatchLines, -1

#Include GDIP_Class.ahk
Tut3()
Return

*Esc::ExitApp

Tut3(){
    ; gdi+ ahk tutorial 3 written by tic (Tariq Porter)
    ; Requires Gdip.ahk either in your Lib folder as standard library or using #Include
    ;
    ; Tutorial to take make a gui from an existing image on disk
    ; For the example we will use png as it can handle transparencies. The image will also be halved in size

    ; Create a layered window (+E0x80000 : must be used for UpdateLayeredWindow to work!) that is always on top (+AlwaysOnTop), has no taskbar entry or caption
    Gui, 1: -Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs +HWNDguiHwnd

    ; Show the window
    Gui, 1: Show, NA
    
    ; Get a bitmap from the image
    img_name := "Tut03_background.png"
    If !FileExist(A_ScriptDir "\" img_name)
        UrlDownloadToFile, % "https://raw.githubusercontent.com/0xB0BAFE77/GDIP_Class/main/Tutorial/Images/background.png", % img_name
    
    If !FileExist(A_ScriptDir "\" img_name)
    {
        MsgBox, Error downloading background.png.
        ExitApp
    }
    
    ; Create the bitmap
    pBitmap := gdip.Gdip_CreateBitmapFromFile(img_name)
    ; Verify than an actual bitmap was created from the file
    If !pBitmap
    {
        MsgBox, 48, File loading error!, Could not load 'background.png'
        ExitApp
    }

    ; Get the width and height of the bitmap we have just created from the file
    ; This will be the dimensions that the file is
    Width := gdip.Gdip_GetImageWidth(pBitmap)
    , Height := gdip.Gdip_GetImageHeight(pBitmap)

    ; Create a gdi bitmap with width and height of what we are going to draw into it. This is the entire drawing area for everything
    ; We are creating this "canvas" at half the size of the actual image
    ; We are halving it because we want the image to show in a gui on the screen at half its dimensions
    hbm := gdip.CreateDIBSection(Width//2, Height//2)

    ; Get a device context compatible with the screen
    hdc := gdip.CreateCompatibleDC()

    ; Select the bitmap into the device context
    obm := gdip.SelectObject(hdc, hbm)

    ; Get a pointer to the graphics of the bitmap, for use with drawing functions
    G := gdip.Gdip_GraphicsFromHDC(hdc)

    ; We do not need SmoothingMode as we did in previous examples for drawing an image
    ; Instead we must set InterpolationMode. This specifies how a file will be resized (the quality of the resize)
    ; Interpolation mode has been set to HighQualityBicubic = 7
    gdip.Gdip_SetInterpolationMode(G, 7)

    ; DrawImage will draw the bitmap we took from the file into the graphics of the bitmap we created
    ; We are wanting to draw the entire image, but at half its size
    ; Coordinates are therefore taken from (0,0) of the source bitmap and also into the destination bitmap
    ; The source height and width are specified, and also the destination width and height (half the original)
    ; Gdip_DrawImage(pGraphics, pBitmap, dx, dy, dw, dh, sx, sy, sw, sh, Matrix)
    ; d is for destination and s is for source. We will not talk about the matrix yet (this is for changing colours when drawing)
    gdip.Gdip_DrawImage(G, pBitmap, 0, 0, Width//2, Height//2, 0, 0, Width, Height)

    ; Update the specified window we have created (guiHwnd) with a handle to our bitmap (hdc), specifying the x,y,w,h we want it positioned on our screen
    ; So this will position our gui at (0,0) with the Width and Height specified earlier (half of the original image)
    gdip.UpdateLayeredWindow(guiHwnd, hdc, 0, 0, Width//2, Height//2)


    ; Select the object back into the hdc
    gdip.SelectObject(hdc, obm)

    ; Now the bitmap may be deleted
    gdip.DeleteObject(hbm)

    ; Also the device context related to the bitmap may be deleted
    gdip.DeleteDC(hdc)

    ; The graphics may now be deleted
    gdip.Gdip_DeleteGraphics(G)

    ; The bitmap we made from the image may be deleted
    gdip.Gdip_DisposeImage(pBitmap)
    
    Return
}

;#######################################################################
