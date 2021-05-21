#SingleInstance, Force
#NoEnv
#Warn
SetBatchLines, -1

#Include GDIP_Class.ahk
Tut9()
Return

*Esc::ExitApp

Tut9(){
    ; Before we start there are some design elements we must consider.
    ; We can either make the script faster. Creating the bitmap 1st and just write the new progress bar onto it every time and updating it on the gui
    ; and dispose it all at the end/ This will use more RAM
    ; Or we can create the entire bitmap and write the information to it, display it and then delete it after every occurence
    ; This will be slower, but will use less RAM and will be modular (can all be put into a function)
    ; I will go with the 2nd option, but if more speed is a requirement then choose the 1st
    hwnd := {}
    Gui, 1: -DPIScale
    
    ; I am first creating a slider, just as a way to change the percentage on the progress bar
    Gui, 1: Add, Slider, x10 y10 w400 Range0-100 Tooltip gSlider HWNDsliderHwnd, 50 ;vSlider
    MsgBox, % "sliderHwnd: " sliderHwnd 
    ; The progress bar needs to be added as a picture, as all we are doing is creating a gdi+ bitmap and setting it to this control
    ; Note we have set the 0xE style for it to accept an hBitmap later and also set a variable in order to reference it (could also use hwnd)
    Gui, 1: Add, Picture, x10 y+30 w400 h50 0xE ;vProgressBar
    
    ; We will set the initial image on the control before showing the gui
    ;Slider(sliderHwnd)
    
    Gui, 1: Show, AutoSize, Example 9 - gdi+ progress bar
    Return
}

; This subroutine is activated every time we move the slider as I used gSlider in the options of the slider
Slider(CtrlHwnd, GuiEvent, EventInfo, ErrLevel:="") {
    MsgBox, % "CtrlHwnd: " CtrlHwnd "`nGuiEvent: " GuiEvent "`nEventInfo: " EventInfo "`nErrLevel: " ErrLevel
    Gui, 1: Default
    Gui, 1: Submit, NoHide
    Gdip_SetProgress(ProgressBar, Percentage, 0xff0993ea, 0xffbde5ff, Percentage "`%")
    Return
}

Gdip_SetProgress(ByRef Variable, Percentage, Foreground, Background=0x00000000, Text="", TextOptions="x0p y15p s60p Center cff000000 r4 Bold", Font="Arial") {
    ; We first want the hwnd (handle to the picture control) so that we know where to put the bitmap we create
    ; We also want to width and height (posw and Posh)
    GuiControlGet, Pos, Pos, Variable
    GuiControlGet, hwnd, hwnd, Variable
    
    ; Create 2 brushes, one for the background and one for the foreground. Remember this is in ARGB
    pBrushFront := gdip.Gdip_BrushCreateSolid(Foreground)
    , pBrushBack := gdip.Gdip_BrushCreateSolid(Background)
    
    ; Create a gdi+ bitmap the width and height that we found the picture control to be
    ; We will then get a reference to the graphics of this bitmap
    ; We will also set the smoothing mode of the graphics to 4 (Antialias) to make the shapes we use smooth
    pBitmap := gdip.Gdip_CreateBitmap(Posw, Posh)
    , G := gdip.Gdip_GraphicsFromImage(pBitmap)
    , gdip.Gdip_SetSmoothingMode(G, 4)
    
    ; We will fill the background colour with out background brush
    ; x = 0, y = 0, w = Posw, h = Posh
    gdip.Gdip_FillRectangle(G, pBrushBack, 0, 0, Posw, Posh)
    
    ; We will then fill a rounded rectangle with our other brush, starting at x = 4 and y = 4
    ; The total width is now Posw-8 as we have slightly indented the actual progress bar
    ; The last parameter which is the amount the corners will be rounded by in pixels has been made to be 3 pixels...
    ; ...however I have made it so that they are smaller if the percentage is too small as it cannot be rounded by that much
    gdip.Gdip_FillRoundedRectangle(G, pBrushFront, 4, 4, (Posw-8)*(Percentage/100), Posh-8, (Percentage >= 3) ? 3 : Percentage)
    
    ; As mentioned in previous examples, we will provide Gdip_TextToGraphics with the width and height of the graphics
    ; We will then write the percentage centred onto the graphics (Look at previous examples to understand all options)
    ; I added an optional text parameter at the top of this function, to make it so you could write an indication onto the progress bar
    ; such as "Finished!" or whatever, otherwise it will write the percentage to it
    gdip.Gdip_TextToGraphics(G, (Text != "") ? Text : Round(Percentage) "`%", TextOptions, Font, Posw, Posh)
    
    ; We then get a gdi bitmap from the gdi+ one we've been working with...
    hBitmap := gdip.Gdip_CreateHBITMAPFromBitmap(pBitmap)
    ; ... and set it to the hwnd we found for the picture control
    gdip.SetImage(hwnd, hBitmap)
    
    ; We then must delete everything we created
    ; So the 2 brushes must be deleted
    ; Then we can delete the graphics, our gdi+ bitmap and the gdi bitmap
    gdip.Gdip_DeleteBrush(pBrushFront)
    , gdip.Gdip_DeleteBrush(pBrushBack)
    , gdip.Gdip_DeleteGraphics(G)
    , gdip.Gdip_DisposeImage(pBitmap)
    , gdip.DeleteObject(hBitmap)
    
    Return, 0
}

GuiClose() {
    ExitApp
}