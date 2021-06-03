#SingleInstance, Force
#NoEnv
#Warn
SetBatchLines, -1

; Playing with pixelate
; This tutorial will load a picture into the middle of the screen
; It checks where your mouse is relative to the center of the image
; The further the mouse is from the center of the image, the more it pixelates

#Include GDIP_Class.ahk
Tut12.Start()
Return

*Esc::ExitApp

Class Tut12
{
    Static  hwnd        := {}
    Static  max_pixel   := 15
    
    Start()
    {
        ; Method to run when script exits to delete images
        bf := ObjBindMethod(this, "delete_img")
        OnExit(bf)
        
        url     := "https://digitalblasphemy.com/graphics/640x480/fluorescencereddit1640.jpg"
        f_name  := "shroom.jpg"
        If !FileExist(f_name)                                                           ; If the image we want to work with does not exist on disk, then download it...
        {
            UrlDownloadToFile, % url, % f_name
            If (ErrorLevel){
                MsgBox, 48, Download Error
                    , There was an error downloading the file.`nURL: %url%
                ExitApp
            }
        }
        
        pBitmap := gdip.Gdip_CreateBitmapFromFile(f_name)                               ; Get a bitmap from the image
        ;pBitmap := gdip.Gdip_BitmapFromScreen()                                        ; You can also use this to just take a screenshot and pixelate that
        If !pBitmap
        {
            MsgBox, 48, File Load Error, There was an error loading the file.`nSource: %A_ScriptDir%\%f_name%
            ExitApp
        }
        
        ; Get the width and height of the bitmap we have just created from the file
        width   := gdip.Gdip_GetImageWidth(pBitmap)
        height  := gdip.Gdip_GetImageHeight(pBitmap)
        x       := (A_ScreenWidth-width)//2
        y       := (A_ScreenHeight-height)//2
        
        ; We also need to create
        pBitmapOut := gdip.Gdip_CreateBitmapFromFile(f_name)
        ;pBitmapOut := gdip.Gdip_CreateBitmap(width, height)
        
        ; As normal create a gdi bitmap and get the graphics for it to draw into
        hbm     := gdip.CreateDIBSection(width, height)
        hdc     := gdip.CreateCompatibleDC()
        obm     := gdip.SelectObject(hdc, hbm)
        gp      := gdip.Gdip_GraphicsFromHDC(hdc)
        
        ; Create a layered window that is always on top as usual and get a handle to the window
        Gui, 1:New, -Caption +E0x80000 +OwnDialogs +Owner +AlwaysOnTop +HWNDgui_hwnd
        ;Gui, 1:Add, Picture, x0 y0 w%width% h%height% HWNDpic_hwnd
        Gui, 1:Show, NA
        
        ; Update the window with the hdc so that it has a position and dimension for future calls to not
        ; have to explicitly pass them
        gdip.UpdateLayeredWindow(gui_hwnd
                                , hdc
                                , x ;(A_ScreenWidth-width)//2
                                , y ;(A_ScreenHeight-height)//2
                                , width, height)
        
        ; Save variables to class for use with other methods
        Loop, Parse, % "gui_hwnd pBitmap pBitmapOut Width Height hbm hdc obm gp", % " "
            this[A_LoopField] := %A_LoopField%
        
        ; Fires on left mouse down and allows click+drag moving of image
        bf  := ObjBindMethod(this, "WM_LBUTTONDOWN")
        OnMessage(0x201, bf)
        
        bf  := ObjBindMethod(this, "pixelate_roate")
        SetTimer, % bf, 100
        
        Return
    }

;#######################################################################

    pixelate_roate() {
        Static v    := 1
        Static dir  := 1
        
        ; Make sure our pixelation numbers stay within our bounds
        ; Also sets if v should be increased or decreased
        if (v <= 1)
            dir := 1
        else if (v >= this.max_pixel)
            dir := 0
        dir ? v++ : v--
        tooltip, % "v: " v "`ndir: " dir "`nthis.max_pixel: " this.max_pixel "`nthis.gp: " this.gp 
        ; Call Gdip_PixelateBitmap with the bitmap we retrieved earlier and the block size of the pixels
        ; The function returns the pixelated bitmap, and doesn't dispose of the original bitmap
        gdip.Gdip_PixelateBitmap(this.pBitmap
                                , this.pBitmapOut
                                , v)
        
        ; We can optionally clear the graphics we will be drawing to, but if we know there will be no transparencies then
        ; it doesn't matter
        ;Gdip_GraphicsClear(G)
        
        ; We then draw our pixelated bitmap into our graphics and dispose of the pixelated bitmap
        gdip.Gdip_DrawImage(this.gp
                            , this.pBitmapOut
                            , 0, 0
                            , this.width, this.height
                            , 0, 0
                            , this.width, this.height)
        
        ; We can now update our window, and don't need to provide a position or dimensions as we don't want them to change
        gdip.UpdateLayeredWindow(this.gui_hwnd, this.hdc)
        return
    }

    ;#######################################################################
    
    pixelate_image(block_size:=1){
        ; Call Gdip_PixelateBitmap with the bitmap we retrieved earlier and the block size of the pixels
        ; The function returns the pixelated bitmap, and doesn't dispose of the original bitmap
        gdip.Gdip_PixelateBitmap(this.pBitmap
                                , this.pBitmapOut
                                , block_size)
        gdip.Gdip_DrawImage(this.gp
                            , this.pBitmapOut
                            , 0, 0
                            , this.width, this.height
                            , 0, 0
                            , this.width, this.height)
        ; We can now update our window, and don't need to provide a position or dimensions as we don't want them to change
        gdip.UpdateLayeredWindow(this.gui_hwnd, this.hdc)
        ToolTip, % "Current block size: " block_size
        Return
    }
    
    ;#######################################################################
    
    ; This is called on left click
    WM_LBUTTONDOWN()
    {
        ; Tells the window the user is dragging the title bar around
        PostMessage, 0xA1, 2
    }

    ;#######################################################################

    ; On exit, dispose of everything created
    delete_img(){
        gdip.Gdip_DisposeImage(this.pBitmapOut)
        gdip.Gdip_DisposeImage(this.pBitmap)
        gdip.SelectObject(this.hdc, this.obm)
        gdip.DeleteObject(this.hbm)
        gdip.DeleteDC(this.hdc)
        gdip.Gdip_DeleteGraphics(this.gp)
        ExitApp
    }
}
