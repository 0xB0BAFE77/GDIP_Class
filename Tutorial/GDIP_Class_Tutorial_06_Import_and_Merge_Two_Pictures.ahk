#SingleInstance, Force
#NoEnv
#Warn
SetBatchLines, -1

#Include GDIP_Class.ahk
Tut6()
ExitApp

*Esc::ExitApp

Tut6(){
    ; Define our variables
    img1    := "Mario"                              ; img1 will be Mario
    img2    := "Link"                               ; img2 will be Link
    ext     := ".png"                               ; The extension of all our files
    bmp_w   := 600                                  ; Width we want for our new bitmap
    bmp_h   := 600                                  ; Height we want for our new bitmap
    gnd_x   := 0
    gnd_y   := bmp_h * 2/3                          ; Y start of ground
    gnd_h   := bmp_h * 1/3                          ; Height of ground
    ffn     := img1 "_Jumping_Over_" img2 ext       ; Final file name: Mario_Jumping_Over_Link.png
    
    ; Get images of Mario and Link if we don't have them already
    Loop, 2                                         ; Loop twice, once for each image
    {
        file_name := img%A_Index% . ext             ; Save name with extention
        If !FileExist(file_name)                    ; Check if file exists
        {
            ; If not found, ask user if they want to download it
            MsgBox, 0x34, % "File not found", % file_name " does not exist.`n`nDo you want to download it?"
            IfMsgBox, Yes
                UrlDownloadToFile                                   ; All tutorial images are saved to 0x0BAFE77's GitHub
                    , % "https://raw.githubusercontent.com/0xB0BAFE77"
                    . "/GDIP_Class/main/Tutorial/Images/" file_name
                    , % file_name
            IfMsgBox, No                                            ; If user doesn't want to download it, end program
                ExitApp
            If !FileExist(file_name)                                ; Check to see if download was successful
            {
                MsgBox, % "Error."
                    . "Could not download image from server."       ; If not, notify user of failure and quit
                ExitApp
            }
        }
    }
    ;MsgBox, % "gnd_y: " gnd_y "`ngnd_x: " gnd_x "`ngnd_h: " gnd_h "`nbmp_w: " bmp_w "`nbmp_h: " bmp_h "`nffn: " ffn 
    pBitmap         := gdip.Gdip_CreateBitmap(bmp_w, bmp_h)         ; Create a new bitmap that's 600x600 pixels
    , pCanvas       := gdip.Gdip_GraphicsFromImage(pBitmap)         ; Get a pointer to the graphics of the bitmap (now referred to as the canvas)
    , pBrush        := gdip.Gdip_BrushCreateSolid(0xFF8888FF)       ; Create a solid, light-blue brush with no alpha transparency
    , gdip.Gdip_FillRectangle(pCanvas, pBrush, 0, 0, bmp_w, bmp_h)  ; Create a rectangle the size of the canvas to make a sky
    , gdip.Gdip_DeleteBrush(pBrush)                                 ; We're done with this brush so delete it to save memory
    , pBrush        := gdip.Gdip_BrushCreateSolid(0xFF804020)       ; Create a solid brown brush with no alpha transparency
    , gdip.Gdip_FillRectangle(pCanvas, pBrush                       ; Create a rectangle as wide as the canvas but covering the bottom 1/3
                             , gnd_x, gnd_y, bmp_w, gnd_h)
    , gdip.Gdip_DeleteBrush(pBrush)                                 ; Delete this brush to free up memory
    
    ; Now we can put our downloaded images into our bitmap using the Gdip_DrawImage() method
    pImg1           := gdip.Gdip_CreateBitmapFromFile(img1 . ext)   ; Get the mario bitmap from disk
    , img1_w        := gdip.Gdip_GetImageWidth(pImg1)               ; Get width of Mario image
    , img1_h        := gdip.Gdip_GetImageHeight(pImg1)              ; Get height of Mario image
    , gdip.Gdip_DrawImage(pCanvas                                   ; Pointer to our canvas
                        , pImg1                                     ; Pointer to the Mario image
                        , 25                                        ; X-coord of where you want the drawn image to go on the canvas
                        , 30                                        ; Y-coord of the same^
                        , img1_w                                    ; Width to make the Mario image
                        , img1_h                                    ; Height to make the Mario image
                        , 0                                         ; Mario source image x-coord start
                        , 0                                         ; Mario source image y-coord start
                        , img1_w                                    ; Width of Mario image to include
                        , img1_h)                                   ; Height of Mario image to include
    , gdip.Gdip_DisposeImage(pImg1)                                 ; We're done with this img, so delete it from memory
    
    ; Let's do the same for link except we will put him in a different location in our bitmap
    pImg2           := gdip.Gdip_CreateBitmapFromFile(img2 . ext)
    , img2_w        := gdip.Gdip_GetImageWidth(pImg2)
    , img2_h        := gdip.Gdip_GetImageHeight(pImg2)
    , gdip.Gdip_DrawImage(pCanvas                                   ; Pointer to our canvas
                        , pImg2                                     ; Pointer to the Link image
                        , 270                                       ; New X-coord for Link
                        , (gnd_y - img2_h + 9)                      ; Put link on the ground Y-coord
                                                                    ; The +9 offsets the transparent gap between Link and the bottom of the image
                        , img2_w                                    ; Width to make Link image
                        , img2_h                                    ; Height to make Link image
                        , 0                                         ; Link source image x-coord start
                        , 0                                         ; Link source image y-coord start
                        , img2_w                                    ; Width of Link image to include
                        , img2_h)                                   ; Height of Link image to include
    , gdip.Gdip_DisposeImage(pImg2)                                 ; Like img1, we need to delete img2
    
    ; We finish by saving the file and cleaning up
    gdip.Gdip_SaveBitmapToFile(pBitmap, ffn)                        ; Use the Gdip_SaveBitmapToFile() method to save the finished bitmap to disk
    , gdip.Gdip_DeleteGraphics(pCanvas)                             ; We're done with the graphics of the image so we can delete it
    , gdip.Gdip_DisposeImage(pBitmap)                               ; Same goes for the entire bitmap
    
    MsgBox, 0x4, Finished, % "All done!"                            ; Notify the user of completion
        . "`nThe two images have been put on the new bitmap."
        . "`n`nWould you like to open up the new file?"             ; Offer to open the newly created image
    IfMsgBox, Yes                                                   ; If the user wants to see the new image, load it
        Run, % ffn
    
    Return
}
