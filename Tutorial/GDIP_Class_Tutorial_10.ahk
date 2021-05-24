#SingleInstance, Force
#NoEnv
#Warn
SetBatchLines, -1

#Include GDIP_Class.ahk
; We're going to be using a class for this tutorial
; A class helps us group together variables and functions (called methods) into one "package"
; Big thanks to MiM on the AHK Discord Server for helping me with a silly problem I was having with the slider!
tutorial10.start()6
Return

*Esc::ExitApp

; Our main tutorial class
Class tutorial10
{
    Static hwnd := {}       ; An object to store all handles in
    Static path := ""       ; Stores the path to the image being worked with
    
    ; This starts the tutorial by creating a GUI with controls that allow us to rotate and flip an image
    start(){
        def_h   := 25                                                                   ; The default height for most elements
        pad     := 10                                                                   ; Padding to space everything
        w_full  := 300                                                                  ; Width we want the large gui elements
        w_half  := (w_full-pad)/2                                                       ; Width to evently put 2 elements on 1 row
        sld_opt := "Line1 Page10 TickInterval30 ToolTip Range0-360"                     ; Majority of slider options we'll be using
        this.hwnd.main := {}                                                            ; Add a new main object to the class HWND object for storing element handles
        
        ; Create "main" GUI
        Gui, Main:New, +ToolWindow +AlwaysOnTop +HWNDgHwnd                              ; Creates a new gui
            this.hwnd.main.gui := gHwnd
        Gui, Main:Default                                                               ; Set "Main" GUI to default
        Gui, Margin, % pad, % pad                                                       ; Set a default margin width
        ; Add select/load buttons
        Gui, Add, Button, xm ym w%w_half% h%def_h% Default HWNDgHwnd, Select &File      ; Add a button to select an img file
            this.Add_Method(gHwnd, "file_select")
        Gui, Add, Button, x+%pad% ym w%w_half% h%def_h% HWNDgHwnd, &Load                ; Button to load selected file
            this.Add_Method(gHwnd, "file_load")
        ; Add edit box for path
        Gui, Add, Edit, xm y+%pad% w%w_full% r1 HWNDgHwnd , % ""                        ; Add an edit field for the image's path
            this.hwnd.main.edit := gHwnd
        ; Add slider for rotation and checkboxes for flipping
        Gui, Add, CheckBox, xm y+%pad% w%w_half% h%def_h% HWNDgHwnd, Flip Horizontally  ; Checkbox to flip image on horizontal axis
            this.hwnd.main.cb_h := gHwnd
            this.Add_Method(gHwnd, "flip_image")
        Gui, Add, CheckBox, x+%pad% yp w%w_half% h%def_h% HWNDgHwnd, Flip Vertically    ; Checkbox to flip image on vertical axis
            this.hwnd.main.cb_v := gHwnd
            this.Add_Method(gHwnd, "flip_image")
        Gui, Add, Slider, xm y+%pad% w%w_full% %sld_opt% +HWNDgHwnd AltSubmit, 0        ; Slider to rotate image
            this.hwnd.main.slider := gHwnd
            this.Add_Method(gHwnd, "rotate_image")
        ; Show it
        Gui, Show, y0 AutoSize xCenter                                                  ; Autosize the gui to fit controls and show on mid-top of screen
        
        ; Create "img" GUI to display the image we're manipulating
        Gui, img:New, +E0x80000 +AlwaysOnTop +ToolWindow +OwnDialogs +HWNDgHwnd         ; Create a gui to display images on
            this.hwnd.img.gui := gHwnd                                                  ; Save handle
        Gui, img:Show, NA
        
        bf := ObjBindMethod(this, "WM_LBUTTONDOWN")                                     ; This allows us to click and drag the image around the screen
        OnMessage(0x201, bf)
        
        Return
    }
    
    file_select() {
        FileSelectFile, path, 3, % A_ScriptDir, % "Select an image."                    ; Let user select a path to an image
            , % "image (*.bmp; *.gif; *.jpg; *.jpeg; *.png; *.tiff)"
        this.path := path                                                               ; Save path to the class
        
        If FileExist(path)                                                              ; If file exists
        {
            GuiControl,, % this.hwnd.main.edit, % path                                  ; Load path into edit box
            MsgBox, 0x4, Load image?, Do you want to load this image now?               ; And offer to load image
            IfMsgBox, Yes
                this.file_load()
        }
        Else                                                                            ; If file not found
            MsgBox, A valid file was not provided                                       ; Notify user
        
        Return
    }
    
    file_load() {
        If !(pBitmap := gdip.Gdip_CreateBitmapFromFile(this.path))          ; If not a valid path/no image found, return nothing
        {
            MsgBox, , Error, Unable to load file.
            Return
        }
        
        ; We should get the width and height of the image, in case it is too big for the screen then we can resize it to fit nicely
        GuiControlGet, angle, , % this.hwnd.main.slider                     ; Current set angle
        i_width     := gdip.Gdip_GetImageWidth(pBitmap)                     ; Initial width of bitmap
        , i_height  := gdip.Gdip_GetImageHeight(pBitmap)                    ; Initial height of bitmap
        , Ratio     := i_width/i_height                                     ; Height:width ratio
        , r_width   := r_height := ""                                       ; Post rotation width/height
        , x_shift   := y_shift := ""                                        ; Coordinate shift
        ; 
        If (i_width >= A_ScreenWidth//2)
            If (i_width >= i_height)
                width := A_ScreenWidth//2, height := Width*(1/Ratio)    
            Else
                width := Height*Ratio, height := A_ScreenHeight//2
        Else
            width := i_width, height := i_height                            ; If image width is less than 1/2 screen, use initial values
        
        ; Width and Height now contain the new dimensions the image on screen will be
        ; When rotating a square image, then the bitmap or canvas will need to be bigger as you can imagine that once rotated then a triangle will be wider than a square
        ; We need to know the new dimensions of the image
        ; With Gdip_GetRotatedDimensions we can plug in the width and height of the image, and the angle it is to be rotated by
        ; The last 2 parameters are the variables in which to store the new width and height of the rotated image
        ; RWidth and RHeight now contain the dimensions of the rotated image
        gdip.Gdip_GetRotatedDimensions(width, height, angle, r_width, r_height)
        
        ; We rotate an image about the top left corner of the image, however this will result in the image moving off the canvas
        ; We can use Gdip_GetRotatedTranslation to find how much the image should be 'shifted' by in the x and y coordinates in order for it to be back on the canvas
        ; As with the above function, we plug in the width, height and angle to rotate by
        ; The function will then make the last 2 parameters the x and y translation (this is the distance in pixels the image must be shifted by)
        ; xTranslation and yTranslation now contain the distance to shift the image by
        gdip.Gdip_GetRotatedTranslation(width, height, angle, x_shift, y_shift)
        ; We will now create a gdi bitmap to display the rotated image on the screen (as mentioned previously we must use a gdi bitmap to display things on the screen)
        hbm := gdip.CreateDIBSection(r_width, r_height)
        ; Get a device context compatible with the screen
        hdc := gdip.CreateCompatibleDC()
        ; Select the bitmap into the device context
        obm := gdip.SelectObject(hdc, hbm)
        ; Get a pointer to the graphics of the bitmap, for use with drawing functions,
        ; and set the InterpolationMode to HighQualityBicubic = 7 so that when resizing the image still looks good
        gp := gdip.Gdip_GraphicsFromHDC(hdc)
        gdip.Gdip_SetInterpolationMode(gp, 7)
        ; We can now shift our graphics or 'canvas' using the values found with Gdip_GetRotatedTranslation so that the image will be drawn on the canvas
        gdip.Gdip_TranslateWorldTransform(gp, x_shift, y_shift)
        
        ; If we wish to flip the image horizontally, then we supply Gdip_ScaleWorldTransform(G, x, y) with a negative x transform
        ; We multiply the image by the x and y transform. So multiplying a direction by -1 will flip it in that direction and 1 will do nothing
        ; We must then shift the graphics again to ensure the image will be within the 'canvas'
        ; You can see that if we wish to flip vertically we supply a negative y transform
        If Horizontal
            Gdip_ScaleWorldTransform(G, -1, 1), Gdip_TranslateWorldTransform(G, -Width, 0)
        If Vertical
            Gdip_ScaleWorldTransform(G, 1, -1), Gdip_TranslateWorldTransform(G, 0, -Height)
        ; As you will already know....we must draw the image onto the graphics. We want to draw from the top left coordinates of the image (0, 0) to the top left of the graphics (0, 0)
        ; We are drawing from the orginal image size to the new size (this may not be different if the image was not larger than half the screen)
        Gdip_DrawImage(G, pBitmap, 0, 0, Width, Height, 0, 0, i_width, i_height)
        
        ; Even though this is not necessary in this scenario, you should always reset the transforms set on the graphics. This will remove any of the rotations
        Gdip_ResetWorldTransform(G)
        
        ; We will update the hwnd  with the hdc of our gdi bitmap. We are drawing it at the new width and height and in the centre of the screen
        UpdateLayeredWindow(hwnd2, hdc, (A_ScreenWidth-r_width)//2, (A_ScreenHeight-r_height)//2, r_width, r_height)
        
        ; As always we will dispose of everything we created
        ; So we select the object back into the hdc, the delete the bitmap and hdc
        SelectObject(hdc, obm), DeleteObject(hbm), DeleteDC(hdc)
        ; We will then dispose of the graphics and bitmap we created
        Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmap)

        
        MsgBox, % "i_width: " i_width "`ni_height: " i_height "`nRatio: " Ratio "`nr_width: " r_width "`nr_height: " r_height "`nx_shift: " x_shift "`ny_shift: " y_shift "`nangle: " angle
        MsgBox, % "hbm: " hbm "`nhdc: " hdc "`nobm: " obm "`ngp: " gp 
        Return
    }
    
    flip_image() {
        MsgBox, % A_ThisFunc
        Return
    }
    
    rotate_image() {
        Gui, Submit, NoHide
        GuiControlGet, pos,, % this.hwnd.main.slider
        ToolTip, % pos
        Return
    }
    
    WM_LBUTTONDOWN() {
        ; This function fires whenever left mouse is pressed down
        If (A_Gui = "img")              ; First, we make sure the "img" gui was the gui clicked
            PostMessage, 0xA1, 2        ; If yes, tell the system you're actually clicking on the title bar of the window
                                        ; The 2 in the wParam slot tells the system that your cursor is in the title bar
                                        ; This is what allows you to drag the window around
        Return
    }
    
    ; This function let's us add a method to a GUI element
    Add_Method(hwnd, method_name) {
        bf := ObjBindMethod(this, method_name)      ; Creates a boundfunc object
        GuiControl, +g, % hwnd, % bf                ; And then associates that boundfunc with a handle
        Return
    }
}
/*
    ; Updates image whenever a change is made
    Update() {
        Gui, Main:Submit, NoHide                                ; Save values
        If !(pBitmap := Gdip_CreateBitmapFromFile(this.path))   ; If not a valid path/no image found, return nothing
            Return ""
        
        ; We should get the width and height of the image, in case it is too big for the screen then we can resize it to fit nicely
        GuiControlGet, angle, , this.hwnd.main.slider                       ; Current set angle
        i_width     := Gdip_GetImageWidth(pBitmap)                          ; Initial width of bitmap
        , i_height  := Gdip_GetImageHeight(pBitmap)                         ; Initial height of bitmap
        , Ratio     := i_width/i_height                                     ; Height:width ratio
        , r_width   := r_height := ""                                       ; Post rotation width/height
        , x_shift   := y_shift := ""                                        ; Coordinate shift
        If (i_width >= A_ScreenWidth//2)                                    ; If image width is larger than 1/2 the screen
            If (i_width >= i_height)                                        ;   And if width is larger than height
                width := A_ScreenWidth//2   , height := Width*(1/Ratio)     ;   Set width to 1/2 screen and adjust height using ratio
            Else
                width := Height*Ratio       , height := A_ScreenHeight//2   ;   If image height is larger
        Else
            width := i_width                , height := i_height            ; If image width is less than 1/2 screen, use initial values
        
        ; Width and Height now contain the new dimensions the image on screen will be
        ; When rotating a square image, then the bitmap or canvas will need to be bigger as you can imagine that once rotated then a triangle will be wider than a square
        ; We need to know the new dimensions of the image
        ; With Gdip_GetRotatedDimensions we can plug in the width and height of the image, and the angle it is to be rotated by
        ; The last 2 parameters are the variables in which to store the new width and height of the rotated image
        ; RWidth and RHeight now contain the dimensions of the rotated image
        Gdip_GetRotatedDimensions(width, height, angle, r_width, r_height)
        
        
        
        
        ;;;;;;;;;;;;;;;;;;;;;;;;;; ^^^^HEY SLEEPY HEAD, YOU STOPPED HERE^^^^ ;;;;;;;;;;;;;;;;;;;;;;;;;;
        
        
        
        
        ; We rotate an image about the top left corner of the image, however this will result in the image moving off the canvas
        ; We can use Gdip_GetRotatedTranslation to find how much the image should be 'shifted' by in the x and y coordinates in order for it to be back on the canvas
        ; As with the above function, we plug in the width, height and angle to rotate by
        ; The function will then make the last 2 parameters the x and y translation (this is the distance in pixels the image must be shifted by)
        ; xTranslation and yTranslation now contain the distance to shift the image by
        Gdip_GetRotatedTranslation(width, height, angle, x_shift, y_shift)
        ; We will now create a gdi bitmap to display the rotated image on the screen (as mentioned previously we must use a gdi bitmap to display things on the screen)
        hbm := CreateDIBSection(r_width, r_height)
        ; Get a device context compatible with the screen
        hdc := CreateCompatibleDC()
        ; Select the bitmap into the device context
        obm := SelectObject(hdc, hbm)
        ; Get a pointer to the graphics of the bitmap, for use with drawing functions,
        ; and set the InterpolationMode to HighQualityBicubic = 7 so that when resizing the image still looks good
        G := Gdip_GraphicsFromHDC(hdc), Gdip_SetInterpolationMode(G, 7)
        ; We can now shift our graphics or 'canvas' using the values found with Gdip_GetRotatedTranslation so that the image will be drawn on the canvas
        Gdip_TranslateWorldTransform(G, x_shift, y_shift)
        ; We can also rotate the graphics by the angle we desire
        Gdip_RotateWorldTransform(G, Angle)
        ; If we wish to flip the image horizontally, then we supply Gdip_ScaleWorldTransform(G, x, y) with a negative x transform
        ; We multiply the image by the x and y transform. So multiplying a direction by -1 will flip it in that direction and 1 will do nothing
        ; We must then shift the graphics again to ensure the image will be within the 'canvas'
        ; You can see that if we wish to flip vertically we supply a negative y transform
        If Horizontal
            Gdip_ScaleWorldTransform(G, -1, 1), Gdip_TranslateWorldTransform(G, -Width, 0)
        If Vertical
            Gdip_ScaleWorldTransform(G, 1, -1), Gdip_TranslateWorldTransform(G, 0, -Height)
        ; As you will already know....we must draw the image onto the graphics. We want to draw from the top left coordinates of the image (0, 0) to the top left of the graphics (0, 0)
        ; We are drawing from the orginal image size to the new size (this may not be different if the image was not larger than half the screen)
        Gdip_DrawImage(G, pBitmap, 0, 0, Width, Height, 0, 0, i_width, i_height)
        
        ; Even though this is not necessary in this scenario, you should always reset the transforms set on the graphics. This will remove any of the rotations
        Gdip_ResetWorldTransform(G)
        
        ; We will update the hwnd  with the hdc of our gdi bitmap. We are drawing it at the new width and height and in the centre of the screen
        UpdateLayeredWindow(hwnd2, hdc, (A_ScreenWidth-r_width)//2, (A_ScreenHeight-r_height)//2, r_width, r_height)
        
        ; As always we will dispose of everything we created
        ; So we select the object back into the hdc, the delete the bitmap and hdc
        SelectObject(hdc, obm), DeleteObject(hbm), DeleteDC(hdc)
        ; We will then dispose of the graphics and bitmap we created
        Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmap)
        Return
    }

    ; This function allows the user to click and drag the loaded image around
    WM_LBUTTONDOWN()
    {
        ; This function fires whenever left mouse is pressed down
        If (A_Gui = "img")              ; First, we make sure the "img" gui was the gui clicked
            PostMessage, 0xA1, 2        ; If yes, tell the system you're actually clicking on the title bar of the window
                                        ; The 2 in the wParam slot tells the system that your cursor is in the title bar
                                        ; This is what allows you to drag the window aroundj
    }

    file_load() {
        
        Return
    }

    file_select() {
        FileSelectFile, path, 3, % A_ScriptDir, % "Select an image.", image file (*.bmp; *.gif; *.jpg; *.jpeg; *.png, *.tiff)
        If path
            this.path := path
            , file_load()
        Else
            MsgBox, No valid path captured
        Return
    }
}
;#####################################################################

Go() {
    ; If the file in the edit field is not a valid image then return
    If !pBitmap := Gdip_CreateBitmapFromFile(this.path)
        Return
    
    ; We should get the width and height of the image, in case it is too big for the screen then we can resize it to fit nicely
    OriginalWidth := Gdip_GetImageWidth(pBitmap), OriginalHeight := Gdip_GetImageHeight(pBitmap)
    Ratio := OriginalWidth/OriginalHeight

    ; If the image has a width larger than 1/2 of the width of the screen or height larger than 1/2 the screen, then we will resize it to be half of the screen
    If (OriginalWidth >= A_ScreenWidth//2) || (OriginalHeight >= A_ScreenHeight//2)
    {
        If (OriginalWidth >= OriginalHeight)
        Width := A_ScreenWidth//2, Height := Width*(1/Ratio)
        Else
        Height := A_ScreenHeight//2, Width := Height*Ratio
    }
    Else
    Width := OriginalWidth, Height := OriginalHeight

    ; Width and Height now contain the new dimensions the image on screen will be

    ; When rotating a square image, then the bitmap or canvas will need to be bigger as you can imagine that once rotated then a triangle will be wider than a square
    ; We need to know the new dimensions of the image
    ; With Gdip_GetRotatedDimensions we can plug in the width and height of the image, and the angle it is to be rotated by
    ; The last 2 parameters are the variables in which tio store the new width and height of the rotated image
    ; RWidth and RHeight now contain the dimensions of the rotated image
    Gdip_GetRotatedDimensions(Width, Height, Angle, RWidth, RHeight)

    ; We rotate an image about the top left corner of the image, however this will result in the image moving off the canvas
    ; We can use Gdip_GetRotatedTranslation to find how much the image should be 'shifted' by in the x and y coordinates in order for it to be back on the canvas
    ; As with the above function, we plug in the width, height and angle to rotate by
    ; The function will then make the last 2 parameters the x and y translation (this is the distance in pixels the image must be shifted by)
    ; xTranslation and yTranslation now contain the distance to shift the image by
    Gdip_GetRotatedTranslation(Width, Height, Angle, xTranslation, yTranslation)

    ; We will now create a gdi bitmap to display the rotated image on the screen (as mentioned previously we must use a gdi bitmap to display things on the screen)
    hbm := CreateDIBSection(RWidth, RHeight)

    ; Get a device context compatible with the screen
    hdc := CreateCompatibleDC()

    ; Select the bitmap into the device context
    obm := SelectObject(hdc, hbm)

    ; Get a pointer to the graphics of the bitmap, for use with drawing functions,
    ; and set the InterpolationMode to HighQualityBicubic = 7 so that when resizing the image still looks good
    G := Gdip_GraphicsFromHDC(hdc), Gdip_SetInterpolationMode(G, 7)

    ; We can now shift our graphics or 'canvas' using the values found with Gdip_GetRotatedTranslation so that the image will be drawn on the canvas
    Gdip_TranslateWorldTransform(G, xTranslation, yTranslation)

    ; We can also rotate the graphics by the angle we desire
    Gdip_RotateWorldTransform(G, Angle)

    ; If we wish to flip the image horizontally, then we supply Gdip_ScaleWorldTransform(G, x, y) with a negative x transform
    ; We multiply the image by the x and y transform. So multiplying a direction by -1 will flip it in that direction and 1 will do nothing
    ; We must then shift the graphics again to ensure the image will be within the 'canvas'
    ; You can see that if we wish to flip vertically we supply a negative y transform
    If Horizontal
        Gdip_ScaleWorldTransform(G, -1, 1), Gdip_TranslateWorldTransform(G, -Width, 0)
    If Vertical
        Gdip_ScaleWorldTransform(G, 1, -1), Gdip_TranslateWorldTransform(G, 0, -Height)


    ; As you will already know....we must draw the image onto the graphics. We want to draw from the top left coordinates of the image (0, 0) to the top left of the graphics (0, 0)
    ; We are drawing from the orginal image size to the new size (this may not be different if the image was not larger than half the screen)
    Gdip_DrawImage(G, pBitmap, 0, 0, Width, Height, 0, 0, OriginalWidth, OriginalHeight)
    
    ; Even though this is not necessary in this scenario, you should always reset the transforms set on the graphics. This will remove any of the rotations
    Gdip_ResetWorldTransform(G)
    
    ; We will update the hwnd  with the hdc of our gdi bitmap. We are drawing it at the new width and height and in the centre of the screen
    UpdateLayeredWindow(hwnd2, hdc, (A_ScreenWidth-RWidth)//2, (A_ScreenHeight-RHeight)//2, RWidth, RHeight)
    
    ; As always we will dispose of everything we created
    ; So we select the object back into the hdc, the delete the bitmap and hdc
    SelectObject(hdc, obm), DeleteObject(hbm), DeleteDC(hdc)
    ; We will then dispose of the graphics and bitmap we created
    Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmap)
    Return
}
