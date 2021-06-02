#SingleInstance, Force
#NoEnv
#Warn
SetBatchLines, -1

#Include GDIP_Class.ahk
; We're going to be using a class for this tutorial
; A class helps us group together variables and functions (called methods) into one "package"
; Big thanks to MiM on the AHK Discord Server for helping me with a silly problem I was having with the slider!
tutorial10.start()
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
        this.hwnd.main  := {}                                                           ; Add a new main object to the class HWND object for storing element handles
        this.hwnd.img   := {}                                                           ; And one for img
        
        ; Create "main" GUI
        Gui, Main:New, +ToolWindow +AlwaysOnTop +HWNDgHwnd                              ; Creates a new gui
            this.hwnd.main.gui := gHwnd
        Gui, Main:Default                                                               ; Set "Main" GUI to default
        Gui, Margin, % pad, % pad                                                       ; Set a default margin width
        ; Add select/load buttons
        Gui, Add, Button, xm ym w%w_half% h%def_h% Default HWNDgHwnd, Select &File      ; Add a button to select an img file
            this.Add_Method(gHwnd, "file_select")
        Gui, Add, Button, x+%pad% ym w%w_half% h%def_h% HWNDgHwnd, &Load                ; Button to load selected file
            this.Add_Method(gHwnd, "update")
        ; Add edit box for path
        Gui, Add, Edit, xm y+%pad% w%w_full% r1 HWNDgHwnd , % ""                        ; Add an edit field for the image's path
            this.hwnd.main.edit := gHwnd
        ; Add slider for rotation and checkboxes for flipping
        Gui, Add, CheckBox, xm y+%pad% w%w_half% h%def_h% HWNDgHwnd, Flip Horizontally  ; Checkbox to flip image on horizontal axis
            this.hwnd.main.cb_h := gHwnd
            this.Add_Method(gHwnd, "update")
        Gui, Add, CheckBox, x+%pad% yp w%w_half% h%def_h% HWNDgHwnd, Flip Vertically    ; Checkbox to flip image on vertical axis
            this.hwnd.main.cb_v := gHwnd
            this.Add_Method(gHwnd, "update")
        Gui, Add, Slider, xm y+%pad% w%w_full% %sld_opt% +HWNDgHwnd AltSubmit, 0        ; Slider to rotate image
            this.hwnd.main.slider := gHwnd
            this.Add_Method(gHwnd, "update")
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
    
    ; This method is used to get the path of an image file
    file_select() {
        FileSelectFile, path, 3, % A_ScriptDir, % "Select an image."                    ; Let user select a path to an image
            , % "image (*.bmp; *.gif; *.jpg; *.jpeg; *.png; *.tiff)"
        this.path := path                                                               ; Save path to the class
        
        If FileExist(path)                                                              ; If file exists
            GuiControl,, % this.hwnd.main.edit, % path                                  ; Load path into edit box
        Else                                                                            ; If file not found
            MsgBox, A valid file was not provided                                       ; Notify user
        this.update()
        Return
    }
    
    update() {
        If !(pBitmap := gdip.Gdip_CreateBitmapFromFile(this.path))          ; If not a valid path/no image found, return nothing
        {
            MsgBox, , Error, Unable to load file.
            Return
        }
        
        ; Vars
        GuiControlGet, angle,, % this.hwnd.main.slider                      ; Current user angle
        GuiControlGet, horz,, % this.hwnd.main.cb_h
        GuiControlGet, vert,, % this.hwnd.main.cb_v
        i_width     := gdip.Gdip_GetImageWidth(pBitmap)                     ; Initial width of bitmap
        , i_height  := gdip.Gdip_GetImageHeight(pBitmap)                    ; Initial height of bitmap
        , ratio     := i_width/i_height                                     ; Height:width ratio
        , r_width   := r_height := x_shift := y_shift := ""                 ; Variables for later
        
        ; Resize image so it's not larger than 1/2 the screen 
        If (i_width >= A_ScreenWidth//2)
            If (i_width >= i_height)
                width := A_ScreenWidth//2, height := width*(1/ratio)    
            Else
                width := Height*ratio, height := A_ScreenHeight//2
        Else
            width := i_width, height := i_height
        
        ; Mention that when manipulating an image, scaling, rotating, and translating order is important?
        ; This function uses RST: Rotate > Scale > Translate
        gdip.Gdip_GetRotatedDimensions(width, height, angle, r_width, r_height)     ; Get width/height needed to fit rotated image
        gdip.Gdip_GetRotatedTranslation(width, height, angle, x_shift, y_shift)     ; Get upper-left x/y coordinate of rotated image
        hbm := gdip.CreateDIBSection(r_width, r_height)                             ; Create a new DIB Section using new height/width
        hdc := gdip.CreateCompatibleDC()                                            ; Create device context
        obm := gdip.SelectObject(hdc, hbm)                                          ; Move bitmap to device context
        gp  := gdip.Gdip_GraphicsFromHDC(hdc)                                       ; Get pointer to bitmap's graphics
        gdip.Gdip_SetInterpolationMode(gp, 7)                                       ; Set quality of image manipulation to highest
        gdip.Gdip_TranslateWorldTransform(gp, x_shift, y_shift)                     ; Use shift values to move graphics to their correct place on the canvas
        gdip.Gdip_RotateWorldTransform(gp, angle)                                   ; Rotates the image by the provided angle
        
        If horz                                                                     ; Check for horizontal mirroring
            gdip.Gdip_ScaleWorldTransform(gp, -1, 1)
            , gdip.Gdip_TranslateWorldTransform(gp, -width, 0)
        If vert                                                                     ; Check for vertical mirroring
            gdip.Gdip_ScaleWorldTransform(gp, 1, -1)
            , gdip.Gdip_TranslateWorldTransform(gp, 0, -height)
        
        gdip.Gdip_DrawImage(gp, pBitmap                                             ; Draw image to canvas
                            , 0, 0, width, height
                            , 0, 0, i_width, i_height)
        
        gdip.Gdip_ResetWorldTransform(gp)                                           ; Always reset the world transformation matrix
        
        ;UpdateLayeredWindow(hwnd, hdc, x="", y="", w="", h="", Alpha=255)
        gdip.UpdateLayeredWindow(this.hwnd.img.gui, hdc                             ; Apply the changes we made to the GUI
                                , (A_ScreenWidth-r_width) // 2                      ; x
                                , (A_ScreenHeight-r_height) // 2                    ; y
                                , r_width                                           ; w
                                , r_height)                                         ; y
        
        ; Clean up stuff no longer needed
        gdip.SelectObject(hdc, obm)                                                 ; Select the bitmap object back into the device context
        gdip.DeleteObject(hbm)                                                      ; Delete the object the bitmap handle is associated with
        gdip.DeleteDC(hdc)                                                          ; Delete the device context we were using
        gdip.Gdip_DeleteGraphics(gp)                                                ; Delete the pointer we were using
        gdip.Gdip_DisposeImage(pBitmap)                                             ; Delete imported image
        
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
