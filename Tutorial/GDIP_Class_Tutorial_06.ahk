#SingleInstance, Force
#NoEnv
#Warn
SetBatchLines, -1

#Include GDIP_Class.ahk
Tut6()
Return

*Esc::ExitApp

Tut6(){
    File1 := "Mario.png", File2 := "Link.png"                           ; Specify both of the files we are going to use
    Loop, Parse, % File1 "|" File2, % "|"                               ; Loop through both file names
        If !FileExist(A_LoopField)                                      ; If the file doesn't exist
            UrlDownloadToFile, % "https://raw.githubusercontent.com/"   ; Download it from github
                . "0xB0BAFE77/GDIP_Class/main/Tutorial/Images/" 
                . A_LoopField
            , % "Tut06_" A_LoopField
    
    pBitmap         := gdip.Gdip_CreateBitmap(600, 600)             ; Create a 500x500 pixel gdi+ bitmap (this will be the entire drawing area we have to play with)
    , G             := gdip.Gdip_GraphicsFromImage(pBitmap)         ; Get a pointer to the graphics of the bitmap, for use with drawing functions
    , pBrush        := gdip.Gdip_BrushCreateSolid(0xff00ff00)       ; Create a green brush (this will be used to fill the background with green). The brush is fully opaque (ARGB)
    , gdip.Gdip_FillRectangle(G, pBrush, 0, 0, 600, 600)            ; Fill the entire graphics of the bitmap with the green brush (this will be out background colour)
    , gdip.Gdip_DeleteBrush(pBrush)                                 ; Delete the brush created to save memory as we don't need the same brush anymore
    
    pBitmapFile1    := gdip.Gdip_CreateBitmapFromFile(File1)        ; Get the bitmap for the first file
    ;, gdip.Gdip_GetImageDimensions(pBitmapFile1, Width, Height)     ; Get width and height of the first bitmap ;;replacement method call
    , Width         := gdip.Gdip_GetImageWidth(pBitmapFile1)        ; Get width and height of the first bitmap
    , Height        := gdip.Gdip_GetImageHeight(pBitmapFile1)       ; Get height of the 1st bitmap
    ; Draw the 1st bitmap (1st image) onto our "canvas" (the graphics of the original bitmap we created) with the same height and same width
    ; at coordinates (25,30).....We will be ignoring the matrix parameter for now. This can be used to change opacity and colours when drawing
    ;Gdip_DrawImage(pGraphics, pBitmap, dx="", dy="", dw="", dh="", sx="", sy="", sw="", sh="", Matrix=1)
    , gdip.Gdip_DrawImage(G             ; Pointer to bitmap's graphics
                        , pBitmapFile1  ; Pointer to a bitmap to be drawn
                        , 25            ; Destination x-coord of upper-left corner
                        , 30            ; Destination y-coord of upper-left corner
                        , Width         ; Destination image width
                        , Height        ; Destination image height
                        , 0             ; Source x-coord of upper-left corner
                        , 0             ; Source y-coord of upper-left corner
                        , Width         ; Source image width
                        , Height)       ; Source image heigh
    MsgBox, % "G: " G "`npBitmap: " pBitmap "`npBitmapFile1: " pBitmapFile1 "`nWidth: " Width "`nHeight: " Height 
    pBitmapFile2  := gdip.Gdip_CreateBitmapFromFile(File2)
    , Width         := gdip.Gdip_GetImageWidth(pBitmapFile2)
    , Height        := gdip.Gdip_GetImageHeight(pBitmapFile2)      ; Do the same again for the 2nd file, but change the coordinates to (250,260).....
    ;, gdip.Gdip_DrawImage(G, pBitmapFile2, 250, 260, Width, Height, 0, 0, Width, Height)
    , gdip.Gdip_DrawImage(G             ; Pointer to bitmap's graphics
                        , pBitmapFile2  ; Pointer to a bitmap to be drawn
                        , 250           ; Destination x-coord of upper-left corner
                        , 260           ; Destination y-coord of upper-left corner
                        , Width         ; Destination image width
                        , Height        ; Destination image height
                        , 0             ; Source x-coord of upper-left corner
                        , 0             ; Source y-coord of upper-left corner
                        , Width         ; Source image width
                        , Height)       ; Source image heigh
    
    , gdip.Gdip_DisposeImage(pBitmapFile1)      ; Dispose of both of these bitmaps we created from the images on disk, as they are now been used...They are on
    , gdip.Gdip_DisposeImage(pBitmapFile2)      ; the graphics of the bitmap of our created "canvas"

    ; Save the bitmap to file "File.png" (extension can be .png,.bmp,.jpg,.tiff,.gif)
    ; Bear in mind transparencies may be lost with some image formats and will appear black
    , gdip.Gdip_SaveBitmapToFile(pBitmap, "FinalImage.png")

    ; The bitmap can be deleted
    , gdip.Gdip_DisposeImage(pBitmap)

    ; The graphics may now be deleted
    , gdip.Gdip_DeleteGraphics(G)
    MsgBox All done!
    Return
}