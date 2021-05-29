#SingleInstance, Force
#NoEnv
#Warn
SetBatchLines, -1

; Making a new bitmap, importing 2 other images onto it, then saving it to file
#Include GDIP_Class.ahk
Tut5()
Return

*Esc::ExitApp

Tut5() {
    pBitmap         := gdip.Gdip_CreateBitmap(400, 400)                         ; Create a 400x400 pixel gdi+ bitmap
    , G             := gdip.Gdip_GraphicsFromImage(pBitmap)                     ; Get a pointer to the graphics of the bitmap, for use with drawing functions
    , gdip.Gdip_SetSmoothingMode(G, 4)                                          ; Set the smoothing mode to antialias = 4 to make shapes appear smoother (only used for vector drawing and filling)
    , pBrush        := gdip.Gdip_BrushCreateHatch(0xff553323, 0xffc09e8e, 31)   ; Create a hatched brush with background and foreground colours specified (HatchStyleBackwardDiagonal = 3)
    , gdip.Gdip_FillRectangle(G, pBrush, (400-200)//2, (400-250)//2, 200, 250)  ; Draw into the graphics of the bitmap from coordinates (100,80) a filled rectangle with 200 width and 250 height using the brush created
    , gdip.Gdip_DeleteBrush(pBrush)                                             ; Delete the brush created to save memory as we don't need the same brush anymore
    , pBrush        := gdip.Gdip_BrushCreateHatch(0xff000000, 0xff4d3538, 31)   ; Create a hatched brush with background and foreground colours specified (HatchStyleBackwardDiagonal = 3)
    , gdip.Gdip_FillPie(G, pBrush, (400-80)//2, (400-80)//2, 80, 80, 250, 40)   ; Draw an ellipse into the graphics with the brush we just created. 40 degree sweep angle starting at 250 degrees (0 degrees from right horizontal)
    , gdip.Gdip_DeleteBrush(pBrush)                                             ; Delete the brush created to save memory as we don't need the same brush anymore
    , pBrushWhite   := gdip.Gdip_BrushCreateSolid(0xffffffff)                   ; Create a white brush
    , pBrushBlack   := gdip.Gdip_BrushCreateSolid(0xff000000)                   ; Create a black brush
    
    ; Loop to draw 2 ellipses filling them with white then black in the centre of each
    Loop, 2
    {
          x := (A_Index = 1) ? 120 : 220
        , y := 100
        , gdip.Gdip_FillEllipse(G, pBrushWhite, x, y, 60, 60)
        , gdip.Gdip_FillEllipse(G, pBrushBlack, (x+15), (y+15), 30, 30)
    }
    
    gdip.Gdip_DeleteBrush(pBrushWhite), gdip.Gdip_DeleteBrush(pBrushBlack)  ; Delete both brushes
    , pBrush    := gdip.Gdip_BrushCreateHatch(0xfff22231, 0xffa10f19, 10)   ; Create a hatched brush with background and foreground colours specified (HatchStyle30Percent = 10)
    , gdip.Gdip_FillPie(G, pBrush, 150, 200, 100, 80, 0, 180)               ; Again draw another ellipse into the graphics with the specified brush
    , gdip.Gdip_DeleteBrush(pBrush)                                         ; Delete the brush
    , pPen      := gdip.Gdip_CreatePen(0xbb000000, 3)                       ; Create a 3 pixel wide slightly transparent black pen
    
    ; Create some coordinates for the lines in format x1,y1,x2,y2 then loop and draw all the lines
    Lines = 180,200,130,220|180,190,130,195|220,200,270,220|220,190,270,195
    Loop, Parse, Lines, |
    {
        StringSplit, Pos, A_LoopField, `,
        gdip.Gdip_DrawLine(G, pPen, Pos1, Pos2, Pos3, Pos4)
    }
    ; Delete the pen
    gdip.Gdip_DeletePen(pPen)

    ; Save the bitmap to file "File.png" (extension can be .png,.bmp,.jpg,.tiff,.gif)
    ; Bear in mind transparencies may be lost with some image formats and will appear black
    FileSelectFile, path, S18, % A_ScriptDir, Save your new file. (Saves as a .png)
    gdip.Gdip_SaveBitmapToFile(pBitmap, path ".png")

    ; The bitmap can be deleted
    gdip.Gdip_DisposeImage(pBitmap)

    ; The graphics may now be deleted
    gdip.Gdip_DeleteGraphics(G)

    ; ...and gdi+ may now be shutdown
    gdip.Gdip_Shutdown(pToken)
    Return
}
