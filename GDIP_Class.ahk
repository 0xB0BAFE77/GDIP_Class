;#Warn

gdip.__New()

Class gdip
{
    ; GDI+ Class library for AHK
    ; Version:  v1.48
    ; Started:  20210501
    ; Updated:  20210702
    ; 
    ; This is a rewrite of tic's original GDIP library. It has been updated to be a class with methods.
    ; All of the GDIP original tutorials have been rewritten to support the new class structure.
    ; A full set of new, advanced tutorials have also been created by me.
    ; Many of the descriptions have been updated/clarified.
    
    ; Added a __New() and __Delete() method for starting up and shutting down GDIP.
    ;   No more need to call the Startup() and Shutdown() functions
    ; Pointer info is now defined and stored as a class property at startup
    ;   This removes the need for a very large amount of if-checks that did nothing but determine x86 or x64
    ; Code is continuously being rewritten/optimized to help with performance.
    ; Implmented a 120 char max line length in this library to help with readability
    ; Added (var:="") declrations to many methods to prevent #Warn errors about variables not being declared
    ; I've broken up many of the function calls to multiple lines to add additional comments
    ;
    ; 20210601:
    ; Added Gdip_DrawPolygon() as only the Gdip_FillPolygon() existed
    ; Added new color object that contains all of CSS3's extended color table hex values and names
    ;   Usage: gdip.color.color_name
    ;   Returns: Hex value for color_name color
    ;   The official CSS3 color module info can be found here:
    ;       https://www.w3.org/TR/2018/REC-css-color-3-20180619
    ; Added a Gdip_PercentToByte(percent) method to convert a 0-100 number to byte hex
    ;   Pass a percentage and it will return byte equivalent of that percentage
    ;   This was added to help with colors and alpha values. Some people prefer using percentage values.
    ;   Example: alpha_percent(50) -> 0x80, alpha_percent(100) -> 0xFF, alpha_percent(33) -> 0x54
    ;
    ; 20210613:
    ; Overhauling the entire layout/comments. This is information and aesthetic based.
    ;   Updating all comments to be easier to understand and re-checking posted method values to ensure accuracy
    ;   Since the inception of this GDIP library, a lot of values for these methods have been updated/expanded
    ;   Giving each comment section a "folder" like aesthetic
    ; Updated color function to include grey/gray variants
    ; 
    ; 20210616:
    ;   Still rewriting/updating/creating comments, param defintiions, return values, etc.
    ;   Status Enumeration has been updated to include enum number, value, and descriptions.
    ;   Added a status object that allows you to check things/report errors. gdip.status[code] -> error
    ;
    ; 20210619:
    ;   Added get_points_from_var(ByRef var, points) function. Gets x/y coords from points and puts them in a var
    ;       This function works with both strings and objects
    ;
    ; History:
    ; Originally created by tic (Tariq Porter) 20110709
    ; Later updated by Rseding91 with fincs 64 bit compatible Gdip library 20130501
    ;   Supports: Basic, _L ANSi, _L Unicode x86 and _L Unicode x64
    ;   Updated 2/20/2014 - fixed Gdip_CreateRegion() and Gdip_GetClipRegion() on AHK Unicode x86
    ;   Updated 5/13/2013 - fixed Gdip_SetBitmapToClipboard() on AHK Unicode x64
    ;
    
    ;===================================================================================================================
    ; Want to add/ideas:
    ;   Wanting to add a handful of new methods to make using this easier.
    ;       Methods include:
    ;           bmo := NewBitmap() - Creates a new bitmap. Returns a BMO
    ;           DeleteBitmap(bmo) - Bitmap deconstructor
    ;           gob := CreateLayeredWindow() - Create layered window to draw to. Return gob? (Gui OBject?)
    ;           
    ;       The new methods would create/work with BMOs. Objects for storing all bitmap required info.
    ;           BMOs = BitmapObjects and store all info on a current bitmap
    ;           Would include things like height, width, dc handle, obm pointer, graphics pointer, etc
    ;   
    
    ;###################################################################################################################
    ; STATUS ENUMERATION
    ; Return values for functions specified to have status enumerated Return type
    ;###################################################################################################################
    ; Num  Value                       Indicates that...
    ; 0  = Ok                        = Method call was successful.
    ; 1  = GenericError              = Error on method call that is not covered by anything else in this list.
    ; 2  = InvalidParameter          = One of the method arguments passed was not valid.
    ; 3  = OutOfMemory               = Operating system is out of memory / could not allocate memory.
    ; 4  = ObjectBusy                = One of the arguments specified in the API call is already in use.
    ; 5  = InsufficientBuffer        = A buffer passed in the API call is not large enough for the data.
    ; 6  = NotImplemented            = Method is not implemented.
    ; 7  = Win32Error                = Method generated a Win32 error.
    ; 8  = WrongState                = An object state is invalid for the API call.
    ; 9  = Aborted                   = Method was aborted.
    ; 10 = FileNotFound              = Specified image file or metafile cannot be found.
    ; 11 = ValueOverflow             = An arithmetic operation produced a numeric overflow.
    ; 12 = AccessDenied              = Writing is not allowed to the specified file.
    ; 13 = UnknownImageFormat        = Specified image file format is not known.
    ; 14 = FontFamilyNotFound        = Specified font family not found. Either not installed or spelled incorrectly.
    ; 15 = FontStyleNotFound         = Specified style not available for this font family.
    ; 16 = NotTrueTypeFont           = Font retrieved from HDC or LOGFONT is not TrueType and cannot be used.
    ; 17 = UnsupportedGdiplusVersion = Installed GDI+ version not compatible with the application's compiled version.
    ; 18 = GdiplusNotInitialized     = GDI+ API not initialized. 
    ; 19 = PropertyNotFound          = Specified property does not exist in the image.
    ; 20 = PropertyNotSupported      = Specified property not supported by image format and cannot be set.
    ; 21 = ProfileNotFound           = Color profile required to save in CMYK image format was not found.
    ;###################################################################################################################
    
    ; this needs fully updated...
    ;###################################################################################################################
    ; METHODS
    ;###################################################################################################################
    ; UpdateLayeredWindow(hwnd, hdc, x="", y="", w="", h="", Alpha=255)
    ; BitBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, Raster="")
    ; StretchBlt(dDC, dx, dy, dw, dh, sDC, sx, sy, sw, sh, Raster="")
    ; SetImage(hwnd, hBitmap)
    ; Gdip_BitmapFromScreen(Screen=0, Raster="")
    ; CreateRectF(ByRef RectF, x, y, w, h)
    ; CreateSizeF(ByRef SizeF, w, h)
    ; CreateDIBSection
    
    ;####################################################################################################################
    ; Call          UpdateLayeredWindow(handle, hdc, x="", y="", width="", height="", Alpha=255)                        |
    ; Description   Updates the position, size, shape, content, and translucency of a layered window.                   |
    ;                                                                                                                   |
    ; hwnd          Handle to a layered window                                                                          |
    ; hdc           Handle to the device context of the bitmap to update                                                |
    ; LayeredX      x position to place the window                                                                      |
    ; LayeredY      y position to place the window                                                                      |
    ; LayeredW      Width of the window                                                                                 |
    ; LayeredH      Height of the window                                                                                |
    ; Alpha         The transparency of the window                                                                      |
    ;                                                                                                                   |
    ; Return        If the function succeeds, the Return value is nonzero                                               |
    ;                                                                                                                   |
    ; Notes         If x or y omitted, then layered window will use its current coordinates                             |
    ;               If w or h omitted then current width and height will be used                                        |
    ;___________________________________________________________________________________________________________________|
    UpdateLayeredWindow(hwnd, hdc, x="", y="", w="", h="", Alpha=255)
    {
        ((x != "") && (y != ""))
            ? (VarSetCapacity(pt, 8), NumPut(x, pt, 0, "UInt"), NumPut(y, pt, 4, "UInt") )
            : ""
        
        If (w = "") || (h = "")
            WinGetPos,,, w, h, ahk_id %hwnd%
        
        Return DllCall("UpdateLayeredWindow"
                        , this.Ptr  , hwnd                              ; handle to window
                        , this.Ptr  , 0                                 ; hdc of dest
                        , this.Ptr  , ((x = "") && (y = "")) ? 0 : &pt  ; Ptr to struct with dest x/y coords
                        , "int64*"  , w|h<<32                           ; Ptr to struct with dest w/h
                        , this.Ptr  , hdc                               ; hdc of source
                        , "int64*"  , 0                                 ; ptr to struct with source x/y coords
                        , "uint"    , 0                                 ; Struct to colorref color key
                        , "UInt*"   , Alpha<<16|1<<24                   ; pblend or ptr to blending struct
                        , "uint"    , 2)                                ; Flag 0x2 = ULW_ALPHA = use pblend
    }
    
    ;####################################################################################################################
    ; Call          BitBlt(dDC, dx, dy, dw, dh, sDC, sx, sy, Raster="")                                                 |
    ; Description   Performs a bit-block transfer of the color data corresponding to a rectangle                        |
    ;               of pixels from the specified source device context into a destination device context.               |
    ;                                                                                                                   |
    ; dDC           Handle to destination device context                                                                |
    ; dx            x-coord of the upper-left corner of the area being copied                                           |
    ; dy            y-coord of the upper-left corner of the area being copied                                           |
    ; dw            Width of the area being copied                                                                      |
    ; dh            Height of the area being copied                                                                     |
    ; sDC           Handle to source device context                                                                     |
    ; sx            x-coord of destination where the source should be copied to                                         |
    ; sy            y-coord of destination where the source should be copied to                                         |
    ; Raster        Raster operation code                                                                               |
    ;                                                                                                                   |
    ; Return        If the function succeeds, the Return value is nonzero                                               |
    ;                                                                                                                   |
    ; Notes         If raster operation is not specified, SRCCOPY is used.                                              |
    ;               SRCCOPY copies the source rectangle directly to the destination.                                    |
    ;                                                                                                                   |
    ; List of raster operation codes:                                                                                   |
    ; Name sorted:                                                      Number Sorted                                   |
    ; BLACKNESS         = 0x00000042                                    0x00000042 = BLACKNESS                          |
    ; CAPTUREBLT        = 0x40000000                                    0x001100A6 = NOTSRCERASE                        |
    ; DSTINVERT         = 0x00550009                                    0x00330008 = NOTSRCCOPY                         |
    ; MERGECOPY         = 0x00C000CA                                    0x00440328 = SRCERASE                           |
    ; MERGEPAINT        = 0x00BB0226                                    0x00550009 = DSTINVERT                          |
    ; NOMIRRORBITMAP    = 0x80000000                                    0x005A0049 = PATINVERT                          |
    ; NOTSRCCOPY        = 0x00330008                                    0x00660046 = SRCINVERT                          |
    ; NOTSRCERASE       = 0x001100A6                                    0x008800C6 = SRCAND                             |
    ; PATCOPY           = 0x00F00021                                    0x00BB0226 = MERGEPAINT                         |
    ; PATINVERT         = 0x005A0049                                    0x00C000CA = MERGECOPY                          |
    ; PATPAINT          = 0x00FB0A09                                    0x00CC0020 = SRCCOPY                            |
    ; SRCAND            = 0x008800C6                                    0x00EE0086 = SRCPAINT                           |
    ; SRCCOPY           = 0x00CC0020                                    0x00F00021 = PATCOPY                            |
    ; SRCERASE          = 0x00440328                                    0x00FB0A09 = PATPAINT                           |
    ; SRCINVERT         = 0x00660046                                    0x00FF0062 = WHITENESS                          |
    ; SRCPAINT          = 0x00EE0086                                    0x40000000 = CAPTUREBLT                         |
    ; WHITENESS         = 0x00FF0062                                    0x80000000 = NOMIRRORBITMAP                     |
    ;___________________________________________________________________________________________________________________|
    BitBlt(dDC, dx, dy, dw, dh, sDC, sx, sy, Raster="")
    {
        Return DllCall("gdi32\BitBlt"
                        , this.Ptr  , dDC
                        , "int"     , dx
                        , "int"     , dy
                        , "int"     , dw
                        , "int"     , dh
                        , this.Ptr  , sDC
                        , "int"     , sx
                        , "int"     , sy 
                        , "uint"    , Raster ? Raster : 0x00CC0020)
    }
    
    ;####################################################################################################################
    ; Call          StretchBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, sw, sh, Raster="")                                     |
    ; Description   Copies a bitmap from source to destination and applies any stretching or compressing the source     |
    ;               bitmap needs to fit the destination. Stretching/compressing is done using the dest stretch mode.    |
    ;                                                                                                                   |
    ; dDC           Handle to destination device context                                                                |
    ; dx            x-coord of the upper-left corner of the area being copied                                           |
    ; dy            y-coord of the upper-left corner of the area being copied                                           |
    ; dw            Width of the area being copied                                                                      |
    ; dh            Height of the area being copied                                                                     |
    ; sDC           Handle to source device context                                                                     |
    ; sx            x-coord of destination where the source should be copied to                                         |
    ; sy            y-coord of destination where the source should be copied to                                         |
    ; sw            Width of the area being copied                                                                      |
    ; sh            Height of the area being copied                                                                     |
    ; Raster        Raster operation code                                                                               |
    ;                                                                                                                   |
    ; Return        If the function succeeds, the Return value is nonzero                                               |
    ;                                                                                                                   |
    ; Notes         If raster operation is not specified, SRCCOPY is used.                                              |
    ;               SRCCOPY copies the source rectangle directly to the destination.                                    |
    ;                                                                                                                   |
    ; List of raster operation codes:                                                                                   |
    ; Name sorted:                                                      Number Sorted                                   |
    ; BLACKNESS         = 0x00000042                                    0x00000042 = BLACKNESS                          |
    ; CAPTUREBLT        = 0x40000000                                    0x001100A6 = NOTSRCERASE                        |
    ; DSTINVERT         = 0x00550009                                    0x00330008 = NOTSRCCOPY                         |
    ; MERGECOPY         = 0x00C000CA                                    0x00440328 = SRCERASE                           |
    ; MERGEPAINT        = 0x00BB0226                                    0x00550009 = DSTINVERT                          |
    ; NOMIRRORBITMAP    = 0x80000000                                    0x005A0049 = PATINVERT                          |
    ; NOTSRCCOPY        = 0x00330008                                    0x00660046 = SRCINVERT                          |
    ; NOTSRCERASE       = 0x001100A6                                    0x008800C6 = SRCAND                             |
    ; PATCOPY           = 0x00F00021                                    0x00BB0226 = MERGEPAINT                         |
    ; PATINVERT         = 0x005A0049                                    0x00C000CA = MERGECOPY                          |
    ; PATPAINT          = 0x00FB0A09                                    0x00CC0020 = SRCCOPY                            |
    ; SRCAND            = 0x008800C6                                    0x00EE0086 = SRCPAINT                           |
    ; SRCCOPY           = 0x00CC0020                                    0x00F00021 = PATCOPY                            |
    ; SRCERASE          = 0x00440328                                    0x00FB0A09 = PATPAINT                           |
    ; SRCINVERT         = 0x00660046                                    0x00FF0062 = WHITENESS                          |
    ; SRCPAINT          = 0x00EE0086                                    0x40000000 = CAPTUREBLT                         |
    ; WHITENESS         = 0x00FF0062                                    0x80000000 = NOMIRRORBITMAP                     |
    ;___________________________________________________________________________________________________________________|
    StretchBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, sw, sh, Raster="")
    {
        Return DllCall("gdi32\StretchBlt"
                        , this.Ptr  , ddc
                        , "int"     , dx
                        , "int"     , dy
                        , "int"     , dw
                        , "int"     , dh
                        , this.Ptr  , sdc
                        , "int"     , sx
                        , "int"     , sy
                        , "int"     , sw
                        , "int"     , sh
                        , "uint"    , Raster ? Raster : 0x00CC0020)
    }
    
    ;####################################################################################################################
    ; Call          SetStretchBltMode(hdc, iStretchMode=4)                                                              |
    ; Description   Sets the stretch mode for blt calls.                                                                |
    ;                                                                                                                   |
    ; hdc           Handle to the DC                                                                                    |
    ; iStretchMode  Stretching mode to use when stretching/compressing                                                  |
    ;                                                                                                                   |
    ; Return        On failure, 0 is returned. Otherwise, the stretchmode used is returned                              |
    ;                                                                                                                   |
    ; Notes         iStretchMode defines how the system combines rows or columns of a bitmap with existing pixels on a  |
    ;               display device when an application calls the StretchBlt function.                                   |
    ;               BLACKONWHITE (STRETCH_ANDSCANS) and WHITEONBLACK (STRETCH_ORSCANS) usually preserves foreground     |
    ;               pixels in monochrome bitmaps. COLORONCOLOR (STRETCH_DELETESCANS) usually preserves color in bitmaps.|
    ;               HALFTONE is slower and requires more processing than the other three modes, but produces higher     |
    ;               quality images.                                                                                     |
    ;                                                                                                                   |
    ; List of strecth modes:                                                                                            |
    ; BLACKONWHITE  0x1     Performs Boolean AND operation using the color values for the eliminated/existing pixels.   |
    ;                       If bitmap is monochrome, black pixels are preserved at the expense of white pixels.         |
    ; WHITEONBLACK  0x2     Performs Boolean OR operation using the color values for the eliminated/existing pixels.    |
    ;                       If bitmap is monochrome, white pixels are preserved at the expense of black pixels.         |
    ; COLORONCOLOR  0x3     Deletes all eliminated lines of pixels without trying to preserve their information.        |
    ; HALFTONE      0x4     Maps pixels from source rectangle into blocks of pixels in destination rectangle. The avg   |
    ;                       color over the destination block of pixels approximates the color of the source pixels.     |
    ;                       After setting HALFTONE, an application must call SetBrushOrgEx() to set the brush origin.   |
    ;                       Failure will cause brush misalignment issues.                                               |
    ; STRETCH_ANDSCANS      Synonymous with BLACKONWHITE.                                                               |
    ; STRETCH_DELETESCANS   Synonymous with COLORONCOLOR.                                                               |
    ; STRETCH_HALFTONE      Synonymous with HALFTONE.                                                                   |
    ; STRETCH_ORSCANS       Synonymous with WHITEONBLACK.                                                               |
    ;___________________________________________________________________________________________________________________|
    SetStretchBltMode(hdc, iStretchMode=4)
    {
        Return DllCall("gdi32\SetStretchBltMode"
                        , this.Ptr  , hdc
                        , "int"     , iStretchMode)
    }
    
    ;####################################################################################################################
    ; Call          SetImage(hwnd, hBitmap)                                                                             |
    ; Description   Associates a new image with a static control                                                        |
    ;                                                                                                                   |
    ; hwnd          Handle of the control to update                                                                     |
    ; hBitmap       a gdi bitmap to associate the static control with                                                   |
    ;                                                                                                                   |
    ; Return        If the function succeeds, the Return value is nonzero                                               |
    ;___________________________________________________________________________________________________________________|
    SetImage(hwnd, hBitmap)
    {
        SendMessage, 0x172, 0x0, hBitmap,, ahk_id %hwnd%
        E := ErrorLevel
        , this.DeleteObject(E)
        Return E
    }
    
    ;####################################################################################################################
    ; Call          SetSysColorToControl(hwnd, SysColor=15)                                                             |
    ; Description   Sets a solid color to a control                                                                     |
    ;                                                                                                                   |
    ; hwnd          Handle of the control to update                                                                     |
    ; SysColor      A system color to set to the control                                                                |
    ;                                                                                                                   |
    ; Return        If the function succeeds, the Return value is zero                                                  |
    ;                                                                                                                   |
    ; Notes         A control must have the 0xE style set to it so it is recognised as a bitmap                         |
    ;               By default SysColor=15 is used which is COLOR_3DFACE. This is the standard background for a control |
    ;                                                                                                                   |
    ; By Name:                                              By Number:                                                  |
    ; COLOR_3DDKSHADOW              = 21                    COLOR_SCROLLBAR               = 0                           |
    ; COLOR_3DFACE                  = 15                    COLOR_BACKGROUND              = 1                           |
    ; COLOR_3DHIGHLIGHT             = 20                    COLOR_DESKTOP                 = 1                           |
    ; COLOR_3DHILIGHT               = 20                    COLOR_ACTIVECAPTION           = 2                           |
    ; COLOR_3DLIGHT                 = 22                    COLOR_INACTIVECAPTION         = 3                           |
    ; COLOR_3DSHADOW                = 16                    COLOR_MENU                    = 4                           |
    ; COLOR_ACTIVEBORDER            = 10                    COLOR_WINDOW                  = 5                           |
    ; COLOR_ACTIVECAPTION           =  2                    COLOR_WINDOWFRAME             = 6                           |
    ; COLOR_APPWORKSPACE            = 12                    COLOR_MENUTEXT                = 7                           |
    ; COLOR_BACKGROUND              =  1                    COLOR_WINDOWTEXT              = 8                           |
    ; COLOR_BTNFACE                 = 15                    COLOR_CAPTIONTEXT             = 9                           |
    ; COLOR_BTNHIGHLIGHT            = 20                    COLOR_ACTIVEBORDER            = 10                          |
    ; COLOR_BTNHILIGHT              = 20                    COLOR_INACTIVEBORDER          = 11                          |
    ; COLOR_BTNSHADOW               = 16                    COLOR_APPWORKSPACE            = 12                          |
    ; COLOR_BTNTEXT                 = 18                    COLOR_HIGHLIGHT               = 13                          |
    ; COLOR_CAPTIONTEXT             =  9                    COLOR_HIGHLIGHTTEXT           = 14                          |
    ; COLOR_DESKTOP                 =  1                    COLOR_3DFACE                  = 15                          |
    ; COLOR_GRADIENTACTIVECAPTION   = 27                    COLOR_BTNFACE                 = 15                          |
    ; COLOR_GRADIENTINACTIVECAPTION = 28                    COLOR_3DSHADOW                = 16                          |
    ; COLOR_GRAYTEXT                = 17                    COLOR_BTNSHADOW               = 16                          |
    ; COLOR_HIGHLIGHT               = 13                    COLOR_GRAYTEXT                = 17                          |
    ; COLOR_HIGHLIGHTTEXT           = 14                    COLOR_BTNTEXT                 = 18                          |
    ; COLOR_HOTLIGHT                = 26                    COLOR_INACTIVECAPTIONTEXT     = 19                          |
    ; COLOR_INACTIVEBORDER          = 11                    COLOR_3DHIGHLIGHT             = 20                          |
    ; COLOR_INACTIVECAPTION         =  3                    COLOR_3DHILIGHT               = 20                          |
    ; COLOR_INACTIVECAPTIONTEXT     = 19                    COLOR_BTNHIGHLIGHT            = 20                          |
    ; COLOR_INFOBK                  = 24                    COLOR_BTNHILIGHT              = 20                          |
    ; COLOR_INFOTEXT                = 23                    COLOR_3DDKSHADOW              = 21                          |
    ; COLOR_MENU                    =  4                    COLOR_3DLIGHT                 = 22                          |
    ; COLOR_MENUHILIGHT             = 29                    COLOR_INFOTEXT                = 23                          |
    ; COLOR_MENUBAR                 = 30                    COLOR_INFOBK                  = 24                          |
    ; COLOR_MENUTEXT                =  7                    COLOR_HOTLIGHT                = 26                          |
    ; COLOR_SCROLLBAR               =  0                    COLOR_GRADIENTACTIVECAPTION   = 27                          |
    ; COLOR_WINDOW                  =  5                    COLOR_GRADIENTINACTIVECAPTION = 28                          |
    ; COLOR_WINDOWFRAME             =  6                    COLOR_MENUHILIGHT             = 29                          |
    ; COLOR_WINDOWTEXT              =  8                    COLOR_MENUBAR                 = 30                          |
    ;___________________________________________________________________________________________________________________|
    SetSysColorToControl(hwnd, SysColor=15)
    {
        WinGetPos,,, w, h, ahk_id %hwnd%
        bc              := DllCall("GetSysColor", "Int", SysColor, "UInt")
        , pBrushClear   := this.Gdip_BrushCreateSolid(0xFF000000 | (bc >> 16 | bc & 0xFF00 | (bc & 0xFF) << 16))
        , pBitmap       := this.Gdip_CreateBitmap(w, h)
        , gp            := this.Gdip_GraphicsFromImage(pBitmap)
        , this.Gdip_FillRectangle(gp, pBrushClear, 0, 0, w, h)
        , hBitmap       := this.Gdip_CreateHBITMAPFromBitmap(pBitmap)
        , this.SetImage(hwnd, hBitmap)
        , this.Gdip_DeleteBrush(pBrushClear)
        , this.Gdip_DeleteGraphics(gp)
        , this.Gdip_DisposeImage(pBitmap)
        , this.DeleteObject(hBitmap)
        
        Return 0
    }
    
    ;####################################################################################################################
    ; Call          Gdip_BitmapFromScreen                                                                               |
    ; Description   Gets a gdi+ bitmap from the screen                                                                  |
    ;                                                                                                                   |
    ; Screen        0 = All screens                                                                                     |
    ;               Any numerical value = That screen                                                                   |
    ;               x|y|w|h = Use a specified x, y, width, and height string delimited by pipes                         |
    ; Raster        raster operation code                                                                               |
    ;                                                                                                                   |
    ; Return        If the function succeeds, the Return value is a pointer to a gdi+ bitmap                            |
    ;               -1: One or more of x,y,w,h not passed properly                                                      |
    ;                                                                                                                   |
    ; Notes         If no raster operation is specified, then SRCCOPY is used to the Returned bitmap                    |
    ;___________________________________________________________________________________________________________________|
    Gdip_BitmapFromScreen(Screen=0, Raster="")
    {
        If (Screen = 0) ; If 0, get size and pos of virtual screen (the bounding rectangle of all monitors)
        {
            Sysget, x, 76                                       ; SM_XVIRTUALSCREEN
            Sysget, y, 77                                       ; SM_YVIRTUALSCREEN
            Sysget, w, 78                                       ; SM_CXVIRTUALSCREEN
            Sysget, h, 79                                       ; SM_CYVIRTUALSCREEN
        }
        Else If (SubStr(Screen, 1, 5) = "hwnd:")                ; Check for "hwnd:" prefix
        {
            Screen := SubStr(Screen, 6)                         ; Remove prefix
            if !WinExist("ahk_id " Screen)                      ; If handle not exist
                Return -2                                       ; Return error -2
            WinGetPos,,, w, h, ahk_id %Screen%                  ; Otherwise, get w/h of screen
            x := y := 0                                         ; Set x/y defaults
            , hhdc := this.GetDCEx(Screen, 3)                   ; Get a handle to that screen's device context
        }
        Else If (Screen&1 != "")                                ; Check if 1 (main monitor)
        {
            Sysget, M, Monitor, %Screen%                        ; Get whxy values
              x := MLeft
            , y := MTop
            , w := MRight-MLeft
            , h := MBottom-MTop
        }
        else                                                    ; Otherwise, get whxy values from provided monitor #
        {
            StringSplit, S, Screen, |
              x := S1
            , y := S2
            , w := S3
            , h := S4
        }
        
        If (x = "") || (y = "") || (w = "") || (h = "")         ; If any whxy value is empty, throw error -1
            Return -1
        
        chdc    := this.CreateCompatibleDC()                    ; Create a device context
        , hbm   := this.CreateDIBSection(w, h, chdc)            ; New bitmap
        , obm   := this.SelectObject(chdc, hbm)                 ; Select it
        , hhdc  := hhdc ? hhdc : this.GetDC()                   ; If no hhdc, get DC of entire screen
        , this.BitBlt(chdc, 0, 0, w, h, hhdc, x, y, Raster)     ; Transfer color data from screen to bitmap
        , pBitmap := this.Gdip_CreateBitmapFromHBITMAP(hbm)     ; Create bitmap and get pointer
        , this.ReleaseDC(hhdc)                                  ; Cleanup from here down
        , this.SelectObject(chdc, obm)
        , this.DeleteObject(hbm)
        , this.DeleteDC(hhdc)
        , this.DeleteDC(chdc)
        
        Return pBitmap
    }
    
    ;####################################################################################################################
    ;/ _______________________ \                                                                                        |
    ; / Gdip_BitmapFromHWND() \ \______________________________________________________________________________________ |
    ;/                         \_______________________________________________________________________________________\|
    ; Call          Gdip_BitmapFromHWND(hwnd)                                                                           |
    ; Description   Uses PrintWindow() to get a handle to the specified window and return a bitmap from it              |
    ;                                                                                                                   |
    ; hwnd          Handle to a window                                                                                  |
    ;                                                                                                                   |
    ; Return        If the function succeeds, the Return value is a pointer to a gdi+ bitmap                            |
    ;                                                                                                                   |
    ; Notes         Window must not be not minimised in order to get a handle to it's client area                       |
    ;___________________________________________________________________________________________________________________|
    Gdip_BitmapFromHWND(hwnd)
    {
        WinGetPos,,, Width, Height, ahk_id %hwnd%
        hbm         := this.CreateDIBSection(Width, Height)
        , hdc       := this.CreateCompatibleDC()
        , obm       := this.SelectObject(hdc, hbm)
        , this.PrintWindow(hwnd, hdc)
        , pBitmap   := this.Gdip_CreateBitmapFromHBITMAP(hbm)
        , this.SelectObject(hdc, obm)
        , this.DeleteObject(hbm)
        , this.DeleteDC(hdc)
        
        Return pBitmap
    }
    
    ;####################################################################################################################
    ; Call          CreateRect(ByRef Rect, x, y, w, h, float=0)                                                         |
    ; Description   Create a 16 byte rect struct containing x y w h values                                              |
    ;                                                                                                                   |
    ; Rect          Variable name                                                                                       |
    ; x             x-coordinate of rectangle's upper-left corner                                                       |
    ; y             y-coordinate of rectangle's upper-left corner                                                       |
    ; w             Width of the rectangle                                                                              |
    ; h             Height of the rectangle                                                                             |
    ; float         1 = params are float                                                                                |
    ;               0 = params are int                                                                                  |
    ;                                                                                                                   |
    ; Return        Rect is ByRef so no return needed                                                                   |
    ;___________________________________________________________________________________________________________________|
    CreateRect(ByRef Rect, x, y, w, h, float=0)
    {
        VarSetCapacity(Rect, 16)
        , NumPut(x  ,Rect   ,0  , (float ? "float" : "uint"))
        , NumPut(y  ,Rect   ,4  , (float ? "float" : "uint"))
        , NumPut(w  ,Rect   ,8  , (float ? "float" : "uint"))
        , NumPut(h  ,Rect   ,12 , (float ? "float" : "uint"))
    }
    
    ;####################################################################################################################
    ; Call          CreateSize(ByRef Size, w, h, float=0)                                                               |
    ; Description   Create an 8 byte struct containing width and height                                                 |
    ;                                                                                                                   |
    ; Size          Variable name                                                                                       |
    ; w             Width of the rectangle                                                                              |
    ; h             Height of the rectangle                                                                             |
    ; float         1 = params are float                                                                                |
    ;               0 = params are int                                                                                  |
    ;                                                                                                                   |
    ; Return        Size is ByRef so no return needed                                                                   |
    ;___________________________________________________________________________________________________________________|
    CreateSize(ByRef Size, w, h, float=0)
    {
        VarSetCapacity(Size, 8)
        , NumPut(w, Size, 0, (float ? "float" : "uint"))
        , NumPut(h, Size, 4, (float ? "float" : "uint"))     
    }
    
    ;####################################################################################################################
    ; Call          CreatePoint(ByRef Point, x, y, float=0)                                                             |
    ; Description   Create an 8 byte struct containing x/y coords                                                       |
    ;                                                                                                                   |
    ; Point         Variable name                                                                                       |
    ; x             x-coordinate of rectangle's upper-left corner                                                       |
    ; y             y-coordinate of rectangle's upper-left corner                                                       |
    ; float         1 = params are float                                                                                |
    ;               0 = params are int                                                                                  |
    ;                                                                                                                   |
    ; Return        Point is ByRef so no return needed                                                                  |
    ;___________________________________________________________________________________________________________________|
    CreatePoint(ByRef Point, x, y, float=0)
    {
        VarSetCapacity(Point, 8)
        , NumPut(x, Point, 0, (float ? "float" : "uint"))
        , NumPut(y, Point, 4, (float ? "float" : "uint"))
    }
    
    ;####################################################################################################################
    ; Call          CreateDIBSection(w, h, hdc="", bpp=32, ByRef ppvBits=0)                                             |
    ; Description   Creates a DIB (Device Independent Bitmap) that applications can directly write to                   |
    ;                                                                                                                   |
    ; w             Width to make bitmap                                                                                |
    ; h             Height to make bitmap                                                                               |
    ; hdc           Handle to a device context's palette for initializing the DIB colors                                |
    ; bpp           Bits per pixel (ARGB = 32)                                                                          |
    ; ppvBits       Pointer to a variable that receives a pointer to the location of the DIB bit values                 |
    ;                                                                                                                   |
    ; Return        Returns a handle to the new DIB                                                                     |
    ;                                                                                                                   |
    ; Notes         ppvBits will receive the location of the pixels in the DIB                                          |
    ;___________________________________________________________________________________________________________________|
    CreateDIBSection(w, h, hdc="", bpp=32, ByRef ppvBits=0)
    {
        hdc2 := hdc ? hdc : this.GetDC()
        , VarSetCapacity(pbmi, 40, 0)               ; Create BITMAPINFOHEADER (BI) struct 
        , NumPut(40 ,pbmi ,0    ,"uint")            ; BI info struct size
        , NumPut(w  ,pbmi ,4    ,"uint")            ; Width of bitmap in pixels
        , NumPut(h  ,pbmi ,8    ,"uint")            ; Height of bitmap in pixels
        , NumPut(1  ,pbmi ,12   ,"ushort")          ; BI planes (must be 1)
        , NumPut(bpp,pbmi ,14   ,"ushort")          ; BI bit count value (bits per pixel and number of colors) 
        , NumPut(0  ,pbmi ,16   ,"uInt")            ; BI compression for bottom-up bitmaps
        , hbm := DllCall("CreateDIBSection"
                        , this.Ptr  , hdc2          ; Handle to device context
                        , this.Ptr  , &pbmi         ; Pointer to bitmap info
                        , "uint"    , 0             ; Define type of data in BITMAPINFO's bmiColors
                        , this.PtrA , ppvBits       ; Pointer to a variable containing a pointer to the DIB
                        , this.Ptr  , 0             ; Handle to a file-mapping object (can be null)
                        , "uint"    , 0)            ; Used as an offset for a file-mapping object
        , (!hdc ? this.ReleaseDC(hdc2) : "")        ; If the initial hdc was bad, cleanup the hdc2 we created earlier
        
        Return hbm
    }
    
    ;####################################################################################################################
    ; Call          PrintWindow(hwnd, hdc, Flags=0)                                                                     |
    ; Description   Copies a visual window into the specified device context                                            |
    ;                                                                                                                   |
    ; hwnd          Handle of the window to be copied                                                                   |
    ; hdc           Handle to the device context                                                                        |
    ; flag          Drawing options                                                                                     |
    ;                                                                                                                   |
    ; Return        Nonzero on success                                                                                  |
    ;                                                                                                                   |
    ; Flag:         (This function has only 1 flag)                                                                     |
    ; PW_CLIENTONLY = 1     Only the client area of the window is copied                                                |
    ;___________________________________________________________________________________________________________________|
    PrintWindow(hwnd, hdc, flag=0)
    {
        Return DllCall("PrintWindow"
                        , this.Ptr  , hwnd
                        , this.Ptr  , hdc
                        , "uint"    , flag)
    }
    
    ;####################################################################################################################
    ; Call          DestroyIcon(hIcon)                                                                                  |
    ; Description   Destroys an icon and frees any memory the icon occupied                                             |
    ;                                                                                                                   |
    ; hIcon         Handle to the icon to be destroyed and it the icon must not be in use                               |
    ;                                                                                                                   |
    ; Return        Nonzero on success                                                                                  |
    ;___________________________________________________________________________________________________________________|
    DestroyIcon(hIcon)
    {
        Return DllCall("DestroyIcon", this.Ptr, hIcon)
    }
    
    ;####################################################################################################################
    ; Call          DestroyIcon(hIcon)                                                                                  |
    ; Description   Fill the clipping region in the device context with the desktop pattern or wallpaper.               |
    ;                                                                                                                   |
    ; hdc           Handle to the device context.                                                                       |
    ;                                                                                                                   |
    ; Return        Nonzero on success                                                                                  |
    ;___________________________________________________________________________________________________________________|
    PaintDesktop(hdc)
    {
        Return DllCall("PaintDesktop", this.Ptr, hdc)
    }
    
    ;####################################################################################################################
    ; Call          CreateCompatibleBitmap(hdc, w, h)                                                                   |
    ; Description   Creates a bitmap compatible with the device associated with the specified device context.           |
    ;                                                                                                                   |
    ; hdc           Handle to the device context.                                                                       |
    ; w             Bitmap width in pixels.                                                                             |
    ; h             Bitmap height in pixels.                                                                            |
    ;                                                                                                                   |
    ; Return        Handle to the compatible bitmap (DDB) otherwise NULL is returned on failure.                        |
    ;___________________________________________________________________________________________________________________|
    CreateCompatibleBitmap(hdc, w, h)
    {
        Return DllCall("gdi32\CreateCompatibleBitmap"
                        , this.Ptr  , hdc
                        , "int"     , w
                        , "int"     , h)
    }
    
    ;####################################################################################################################
    ; Call          CreateCompatibleDC(hdc=0)                                                                           |
    ; Description   Creates a memory device context (DC) compatible with the specified device                           |
    ;                                                                                                                   |
    ; hdc           Handle to an existing device context                                                                |
    ;                                                                                                                   |
    ; Return        Returns the handle to a device context or 0 on failure                                              |
    ;                                                                                                                   |
    ; Notes         If null, the function creates a compatible memory DC                                                |
    ;___________________________________________________________________________________________________________________|
    CreateCompatibleDC(hdc=0)
    {
        Return DllCall("CreateCompatibleDC", this.Ptr, hdc)
    }
    
    ;####################################################################################################################
    ; Call          SelectObject(hdc, hGdiObj)                                                                          |
    ; Description   Selects an object into the specified device context (DC)                                            |
    ;                                                                                                                   |
    ; hdc           Handle to an existing device context.                                                               |
    ; hGdiObj       Handle to the object to be selected. Object must have been created using one of the following:      |
    ;               Brush  - CreateSolidBrush()     CreateBrushIndirect()       CreateDIBPatternBrush()                 |
    ;                        CreateHatchBrush()     CreatePatternBrush()        CreateDIBPatternBrushPt()               |
    ;               Region - CombineRgn()           CreateEllipticRgn()         CreateEllipticRgnIndirect()             |
    ;                        CreateRectRgn()        CreatePolygonRgn()          CreateRectRgnIndirect()                 |
    ;               Bitmap - CreateBitmap()         CreateBitmapIndirect()      CreateCompatibleBitmap()                |
    ;                        CreateDIBitmap()       CreateDIBSection()                                                  |
    ;               Font   - CreateFont()           CreateFontIndirect()                                                |
    ;               Pen    - CreatePen()            CreatePenIndirect()                                                 |
    ;                                                                                                                   |
    ; Note          A single bitmap cannot be selected into more than one DC at the same time.                          |
    ;                                                                                                                   |
    ; Return        If selected object is a region:                                                                     |
    ;                   Success:                                                                                        |
    ;                       NULLREGION    = 1 Region is empty                                                           |
    ;                       SIMPLEREGION  = 2 Region consists of a single rectangle                                     |
    ;                       COMPLEXREGION = 3 Region consists of more than one rectangle                                |
    ;                   Failure:                                                                                        |
    ;                       HGDI_ERROR                                                                                  |
    ;               If selected object is not a region:                                                                 |
    ;                   Success: Handle to object                                                                       |
    ;                   Failure: Null                                                                                   |
    ;                   On success, value is a handle. On failure it's NULL.                                            |
    ;___________________________________________________________________________________________________________________|
    SelectObject(hdc, hGdiObj)
    {
        Return DllCall("SelectObject"
                        , this.Ptr  , hdc
                        , this.Ptr  , hGdiObj)
    }
    
    ;####################################################################################################################
    ; Call          DeleteObject(hObject)                                                                               |
    ; Description   Deletes a logical pen, brush, font, bitmap, region, or palette to free up system resources.         |
    ;                                                                                                                   |
    ; hObject       Handle to a logical pen, brush, font, bitmap, region, or palette to delete                          |
    ;                                                                                                                   |
    ; Return        Nonzero on success. 0 indicates the handles i not valid or it's currently selected into a DC        |
    ;___________________________________________________________________________________________________________________|
    DeleteObject(hObject)
    {
        Return DllCall("DeleteObject", this.Ptr, hObject)
    }
    
    ;####################################################################################################################
    ; Call          GetDC(hwnd=0)                                                                                       |
    ; Description   Retrieves a handle to a DC of the specified window or to the entire screen.                         |
    ;                                                                                                                   |
    ; hwnd          Handle used to get the device context of a specific window.                                         |
    ;               If NULL, gets device context of entire screen.                                                      |
    ;                                                                                                                   |
    ; Return        On success, a handle to the DC for the specified client area. On failure, NULL.                     |
    ;                                                                                                                   |
    ; Notes         GetDCEx() is an extension to GetDC that gives more control over how and whether clipping occurs.    |
    ;___________________________________________________________________________________________________________________|
    GetDC(hwnd=0)
    {
        Return DllCall("GetDC", this.Ptr, hwnd)
    }
    
    ;####################################################################################################################
    ; Call          GetDC(hwnd=0)                                                                                       |
    ; Description   Retrieves a handle to a DC of the specified window or to the entire screen.                         |
    ;                                                                                                                   |
    ; hwnd          Handle used to get the device context of a specific window.                                         |
    ;               If NULL, gets device context of entire screen.                                                      |
    ; hrgnClip      Clipping region that may be combined with the visible region of the DC, depending on flags          |
    ; flags         Dictates how the DC is created.                                                                     |
    ;                                                                                                                   |
    ; Return        On success, a handle to the DC for the specified client area. On failure, NULL.                     |
    ;                                                                                                                   |
    ; Notes         GetDCEx() is an extension to GetDC that gives more control over how and whether clipping occurs.    |
    ;                                                                                                                   |
    ; Flags:                                                                                                            |
    ; DCX_CACHE             = 0x2       DC from the cache, rather than the OWNDC or CLASSDC window                      |
    ; DCX_CLIPCHILDREN      = 0x8       Excludes visible regions of all child windows above the hWnd window.            |
    ; DCX_CLIPSIBLINGS      = 0x10      Excludes visible regions of all sibling windows above the hWnd window.          |
    ; DCX_EXCLUDERGN        = 0x40      Clipping region identified by hrgnClip is excluded from the visible region.     |
    ; DCX_INTERSECTRGN      = 0x80      Clipping region identified by hrgnClip is intersected from the visible region.  |
    ; DCX_INTERSECTUPDATE   = 0x200     Reserved. Do not use.                                                           |
    ; DCX_LOCKWINDOWUPDATE  = 0x400     Allows drawing even if there is a LockWindowUpdate call in effect.              |
    ; DCX_NORESETATTRS      = 0x4       This flag is ignored.                                                           |
    ; DCX_PARENTCLIP        = 0x20      Uses the visible region of the parent window                                    |
    ; DCX_VALIDATE          = 0x200000  Reserved. Do not use.                                                           |
    ; DCX_WINDOW            = 0x1       DC that corresponds to the window rectangle rather than the client rectangle    |
    ;___________________________________________________________________________________________________________________|
    GetDCEx(hwnd, flags=0, hrgnClip=0)
    {
        Return DllCall("GetDCEx"
                        , this.Ptr  , hwnd
                        , this.Ptr  , hrgnClip
                        , "int"     , flags)
    }
    
    ;___________________________________________________________________________________________________________________
    ;  /____________/\                                                                                                  |
    ; / ReleaseDC() \ \_________________________________________________________________________________________________|
    ;/               \/________________________________________________________________________________________________/|
    ; Call          ReleaseDC(hdc, hwnd=0)                                                                             \|
    ; Description   Releases a device context, freeing it for use. The effect depends on the type of device context.    |
    ;                                                                                                                   |
    ; hdc           Handle to the device context to be released                                                         |
    ; hwnd          Handle to the window whose device context is to be released                                         |
    ;                                                                                                                   |
    ; Return        1 = Released                                                                                        |
    ;               0 = Not released                                                                                    |
    ;                                                                                                                   |
    ; Notes         ReleaseDC() must be called whenever GetWindowDC() and GetDC() have retrieved a DC.                  |
    ;               Applications created by calling CreateDC() must instead use the DeleteDC function.                  |
    ;___________________________________________________________________________________________________________________|
    ReleaseDC(hdc, hwnd=0)
    {
        Return DllCall("ReleaseDC"
                        , this.Ptr  , hwnd
                        , this.Ptr  , hdc)
    }
    
    ;####################################################################################################################
    ; Call          DeleteDC(hdc)                                                                                       |
    ; Description   Deletes the specified device context (DC)                                                           |
    ;                                                                                                                   |
    ; hdc           Handle to the device context                                                                        |
    ;                                                                                                                   |
    ; Return        Nonzero on success                                                                                  |
    ;                                                                                                                   |
    ; Notes         DeleteDC() is only meant for applications created by CreateDC().                                    |
    ;               Applications created by calling GetDC() must use ReleaseDC() to free the DC.                        |
    ;___________________________________________________________________________________________________________________|
    DeleteDC(hdc)
    {
        Return DllCall("DeleteDC", this.Ptr, hdc)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_LibraryVersion                                                                                 |
    ; Description   Get the current library version                                                                     |
    ;                                                                                                                   |
    ; Return        This library's version                                                                              |
    ;                                                                                                                   |
    ; Notes         Useful for non compiled programs. Ensures an old version isn't ran when testing your scripts.       |
    ;___________________________________________________________________________________________________________________|
    Gdip_LibraryVersion()
    {
        Return 1.48
    }
    
    ;####################################################################################################################
    ; Call          Gdip_BitmapFromBRA(ByRef BRAFromMem, File, Alternate=0)                                             |
    ; Description   Gets a pointer to a gdi+ bitmap from a BRA file                                                     |
    ;                                                                                                                   |
    ; BRAFromMem    The variable for a BRA file read into memory                                                        |
    ; Fn            File name or file number depending on the Alt parameter.                                            |
    ; Alt           Changes whether the Fn parameter is file name or number                                             |
    ;                                                                                                                   |
    ; Return        If the function succeeds, the Return value is a pointer to a gdi+ bitmap                            |
    ;               -1 = The BRA variable is empty                                                                      |
    ;               -2 = The BRA has an incorrect header                                                                |
    ;               -3 = The BRA has information missing                                                                |
    ;               -4 = Could not find file inside the BRA                                                             |
    ;___________________________________________________________________________________________________________________|
    ; I HAVE NOT UPDATED THIS YET BECAUSE I'M STILL LEARNING ABOUT BINARY RESOURCE ARCHIVES
    ; I'D SAY I'M LEARNING ABOUT BRAS, BUT I HAD TAKING THOSE OFF MASTERED A LONG TIME AGO. :P
    Gdip_BitmapFromBRA(ByRef BRAFromMem, Fn, Alt=0)
    {
        Static FName = "ObjRelease"
        
        if !BRAFromMem
            Return -1
        
        Loop, Parse, BRAFromMem, `n                             ; Parse through each line of the BRA
        {
            If (A_Index = 1)                                    ; First line is header
            {
                StringSplit, Header, A_LoopField, |             ; Split header by pipe
                If (Header0 != 4 || Header2 != "BRA!")          ; Ensure 4 fields and header2 matches BRA!
                    Return -2                                   ; Otherwise throw error -2
            }
            Else If (A_Index = 2)                               ; Second line is info
            {
                StringSplit, Info, A_LoopField, |               ; Split info by pipe
                If (Info0 != 3)                                 ; Ensure 3 fields
                    Return -3                                   ; Otherwise, throw error -3
            }
            else Break                                          ; Break because no more checks need to be made
        }
        
        if !Alt                                                 ; If alt is not set
            StringReplace, Fn, Fn, \, \\, All                   ; Escape all backslashes
        
        RegExMatch(BRAFromMem, "mi`n)^"                         ; RegEx match based on Alt
            . (Alt
                ? Fn "\|.+?\|(\d+)\|(\d+)"
                : "\d+\|" Fn "\|(\d+)\|(\d+)")
            . "$", FileInfo)
        if !FileInfo
            Return -4
        
        pStream := pBitmap := ""
        , hData := DllCall("GlobalAlloc"y
                            , "uint"    , 2                     ; uFlag
                            , this.Ptr  , FileInfo2)            ; dwBytes
        , pData := DllCall("GlobalLock", this.Ptr  , hData)     ; Lock a global memory object and get a pointer to it
        , DllCall("RtlMoveMemory"                               ; Copy contents of source memory to a destination memory
                , this.Ptr  , pData                             ; Pointer to destination
                , this.Ptr  , &BRAFromMem+Info2+FileInfo1       ; Pointer to source
                , this.Ptr  , FileInfo2)                        ; Number of bytes to copy
        , DllCall("GlobalUnlock", this.Ptr, hData)              ; Unlock a global memory object
        , DllCall("ole32\CreateStreamOnHGlobal"                 ; Create a stream object using an HGLOBAL memory handle
                , this.Ptr  , hData                             ; A memory handle created by GlobalAlloc()
                , "int"     , 1                                 ; Free stream object handle on release of stream object
                , this.PtrA , pStream)                          ; IStream pointer address
        , DllCall("gdiplus\GdipCreateBitmapFromStream"          ; Create bitmap from the stream
                , this.Ptr  , pStream                           ; Pointer to stream
                , this.PtrA , pBitmap)                          ; Pointer to bitmap
        
        (A_PtrSize)
            ? %FName%(pStream)
            : DllCall(NumGet(NumGet(1*pStream)+8), "uint", pStream)
        
        Return pBitmap
    }
    
    ;####################################################################################################################
    ; Call          Gdip_DrawRectangle(gp, pPen, x, y, w, h)                                                            |
    ; Description   Use a pen to draw a rectangle outline into the graphics of a bitmap                                 |
    ;                                                                                                                   |
    ; gp            Pointer to the graphics of a bitmap                                                                 |
    ; pPen          Pointer to pen                                                                                      |
    ; x             x-coordinate of rectangle's upper-left corner                                                       |
    ; y             y-coordinate of rectangle's upper-left corner                                                       |
    ; w             Width of the rectangle                                                                              |
    ; h             Height of the rectangle                                                                             |
    ;                                                                                                                   |
    ; Return        Status enumeration value. 0 = success.                                                              |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;                                                                                                                   |
    ; Notes         Remember to include pen thickness in your height/width values.                                      |
    ;___________________________________________________________________________________________________________________|
    Gdip_DrawRectangle(gp, pPen, x, y, w, h)
    {
        Return DllCall("gdiplus\GdipDrawRectangle"
                        , this.Ptr  , gp
                        , this.Ptr  , pPen
                        , "float"   , x
                        , "float"   , y
                        , "float"   , w
                        , "float"   , h)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_DrawRoundedRectangle(gp, pPen, x, y, w, h, r)                                                  |
    ; Description   Use a pen to draw a rounded rectangle outline into the graphics of a bitmap                         |
    ;                                                                                                                   |
    ; gp            Pointer to the graphics of a bitmap                                                                 |
    ; pPen          Pointer to a pen                                                                                    |
    ; x             x-coordinate of rectangle's upper-left corner                                                       |
    ; y             y-coordinate of rectangle's upper-left corner                                                       |
    ; w             Width of the rectangle                                                                              |
    ; h             Height of the rectangle                                                                             |
    ; r             Radius to use when rounding the corners                                                             |
    ;                                                                                                                   |
    ; Return        Status enumeration value. 0 = success.                                                              |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;                                                                                                                   |
    ; Notes         Remember to include pen thickness in your height/width values.                                      |
    ;___________________________________________________________________________________________________________________|
    Gdip_DrawRoundedRectangle(gp, pPen, x, y, w, h, r)
    {
          this.Gdip_SetClipRect(gp, x-r, y-r, 2*r, 2*r, 4)
        , this.Gdip_SetClipRect(gp, x+w-r, y-r, 2*r, 2*r, 4)
        , this.Gdip_SetClipRect(gp, x-r, y+h-r, 2*r, 2*r, 4)
        , this.Gdip_SetClipRect(gp, x+w-r, y+h-r, 2*r, 2*r, 4)
        , status := this.Gdip_DrawRectangle(gp, pPen, x, y, w, h)
        , this.Gdip_ResetClip(gp)
        , this.Gdip_SetClipRect(gp, x-(2*r), y+r, w+(4*r), h-(2*r), 4)
        , this.Gdip_SetClipRect(gp, x+r, y-(2*r), w-(2*r), h+(4*r), 4)
        , this.Gdip_DrawEllipse(gp, pPen, x, y, 2*r, 2*r)
        , this.Gdip_DrawEllipse(gp, pPen, x+w-(2*r), y, 2*r, 2*r)
        , this.Gdip_DrawEllipse(gp, pPen, x, y+h-(2*r), 2*r, 2*r)
        , this.Gdip_DrawEllipse(gp, pPen, x+w-(2*r), y+h-(2*r), 2*r, 2*r)
        , this.Gdip_ResetClip(gp)
        
        Return status
    }
    
    ;####################################################################################################################
    ; Call          Gdip_DrawEllipse(gp, pPen, x, y, w, h)                                                              |
    ; Description   Use a pen to draw an ellipse outline into the graphics of a bitmap                                  |
    ;                                                                                                                   |
    ; gp            Pointer to the graphics of a bitmap                                                                 |
    ; pPen          Pointer to a pen                                                                                    |
    ; x             x-coordinate of ellipse's upper-left corner                                                         |
    ; y             y-coordinate of ellipse's upper-left corner                                                         |
    ; w             width of the ellipse                                                                                |
    ; h             height of the ellipse                                                                               |
    ; r             Radius to use when rounding the corners                                                             |
    ;                                                                                                                   |
    ; Return        Status enumeration value. 0 = success.                                                              |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;                                                                                                                   |
    ; Notes         Remember to include pen thickness in your height/width values.                                      |
    ;___________________________________________________________________________________________________________________|
    Gdip_DrawEllipse(gp, pPen, x, y, w, h)
    {
        Return DllCall("gdiplus\GdipDrawEllipse"
                        , this.Ptr  , gp
                        , this.Ptr  , pPen
                        , "float"   , x
                        , "float"   , y
                        , "float"   , w
                        , "float"   , h)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_DrawBezier(gp, pPen, x1, y1, x2, y2, x3, y3, x4, y4)                                           |
    ; Description   Use a pen to draw a bezier (weighted curve) outline into the graphics of a bitmap                   |
    ;                                                                                                                   |
    ; gp            Pointer to the graphics of a bitmap                                                                 |
    ; pPen          Pointer to a pen                                                                                    |
    ; x1            x-coordinate bezier start                                                                           |
    ; y1            y-coordinate bezier start                                                                           |
    ; x2            x-coordinate bezier first arc                                                                       |
    ; y2            y-coordinate bezier first arc                                                                       |
    ; x3            x-coordinate bezier second arc                                                                      |
    ; y3            y-coordinate bezier second arc                                                                      |
    ; x4            x-coordinate bezier end                                                                             |
    ; y4            y-coordinate bezier end                                                                             |
    ;                                                                                                                   |
    ; Return        Status enumeration value. 0 = success.                                                              |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;                                                                                                                   |
    ; Notes         Remember to include pen thickness in your height/width values.                                      |
    ;___________________________________________________________________________________________________________________|
    Gdip_DrawBezier(gp, pPen, x1, y1, x2, y2, x3, y3, x4, y4)
    {
        Return DllCall("gdiplus\GdipDrawBezier"
                        , this.Ptr  , gp
                        , this.Ptr  , pPen
                        , "float"   , x1
                        , "float"   , y1
                        , "float"   , x2
                        , "float"   , y2
                        , "float"   , x3
                        , "float"   , y3
                        , "float"   , x4
                        , "float"   , y4)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_DrawArc(gp, pPen, x, y, w, h, StartAngle, SweepAngle)                                          |
    ; Description   Use a pen to draw an arc (curved portion of an ellipse) outline into the graphics of a bitmap       |
    ;                                                                                                                   |
    ; gp            Pointer to the graphics of a bitmap                                                                 |
    ; pPen          Pointer to a pen                                                                                    |
    ; x             x-coordinate of upper-left corner of bounding rectangle for the ellipse that contains the arc       |
    ; y             y-coordinate of upper-left corner of bounding rectangle for the ellipse that contains the arc       |
    ; w             width of the ellipse that contains the arc                                                          |
    ; h             height of the ellipse that contains the arc                                                         |
    ; StartAngle    Starting angle/degree of the arc                                                                    |
    ; SweepAngle    Ending angle/degree of the arc                                                                      |
    ;                                                                                                                   |
    ; Return        Status enumeration value. 0 = success.                                                              |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;                                                                                                                   |
    ; Notes         Remember to include pen thickness in your height/width values.                                      |
    ;___________________________________________________________________________________________________________________|
    Gdip_DrawArc(gp, pPen, x, y, w, h, StartAngle, SweepAngle)
    {
        Return DllCall("gdiplus\GdipDrawArc"
                        , this.Ptr  , gp
                        , this.Ptr  , pPen
                        , "float"   , x
                        , "float"   , y
                        , "float"   , w
                        , "float"   , h
                        , "float"   , StartAngle
                        , "float"   , SweepAngle)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_DrawPie(gp, pPen, x, y, w, h, StartAngle, SweepAngle)
    ; Description   Use a pen to draw a pie outline into the graphics of a bitmap.                                      |
    ;                                                                                                                   |
    ; gp            Pointer to the graphics of a bitmap                                                                 |
    ; pPen          Pointer to a pen                                                                                    |
    ; x             x-coordinate of upper-left corner of bounding rectangle for the ellipse that will make the pie      |
    ; y             y-coordinate of upper-left corner of bounding rectangle for the ellipse that will make the pie      |
    ; w             width of the ellipse that contains the pie                                                          |
    ; h             height of the ellipse that contains the pie                                                         |
    ; StartAngle    Starting angle/degree of the pie's arc                                                              |
    ; SweepAngle    Ending angle/degree of the pie's arc                                                                |
    ;                                                                                                                   |
    ; Return        Status enumeration value. 0 = success.                                                              |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;                                                                                                                   |
    ; Notes         Remember to include pen thickness in your height/width values.                                      |
    ;___________________________________________________________________________________________________________________|
    Gdip_DrawPie(gp, pPen, x, y, w, h, StartAngle, SweepAngle)
    {
        Return DllCall("gdiplus\GdipDrawPie"
                    , this.Ptr  , gp
                    , this.Ptr  , pPen
                    , "float"   , x
                    , "float"   , y
                    , "float"   , w
                    , "float"   , h
                    , "float"   , StartAngle
                    , "float"   , SweepAngle)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_DrawLine(gp, pPen, x1, y1, x2, y2)                                                             |
    ; Description   Use pen to draw a line into the graphics of a bitmap                                                |
    ;                                                                                                                   |
    ; gp            Pointer to the graphics of a bitmap                                                                 |
    ; pPen          Pointer to a pen                                                                                    |
    ; x1            x-coordinate of the start of the line                                                               |
    ; y1            y-coordinate of the start of the line                                                               |
    ; x2            x-coordinate of the end of the line                                                                 |
    ; y2            y-coordinate of the end of the line                                                                 |
    ;                                                                                                                   |
    ; Return        Status enumeration value. 0 = success.                                                              |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;___________________________________________________________________________________________________________________|
    Gdip_DrawLine(gp, pPen, x1, y1, x2, y2)
    {
        Return DllCall("gdiplus\GdipDrawLine"
                        , this.Ptr  , gp
                        , this.Ptr  , pPen
                        , "float"   , x1
                        , "float"   , y1
                        , "float"   , x2
                        , "float"   , y2)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_DrawLines(gp, pPen, Points)                                                                    |
    ; Description   Use a pen to draw a series of joined lines into the graphics of a bitmap                            |
    ;                                                                                                                   |
    ; gp            Pointer to the graphics of a bitmap
    ; pPen          Pointer to a pen
    ; Points        List of x,y coords. String: "x1,y1|x2,y2|..." or object: [[x1,y1], [x2,y2], ...]                    |
    ;               The get_points_from_var() method covers all acceptable types Points data                            |
    ;                                                                                                                   |
    ; Return        Status enumeration value. 0 = success.                                                              |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;___________________________________________________________________________________________________________________|
    Gdip_DrawLines(gp, pPen, Points)
    {
        this.get_points_from_var(pointF, Points)
        Return DllCall("gdiplus\GdipDrawLines"
                    , this.Ptr  , gp
                    , this.Ptr  , pPen
                    , this.Ptr  , &pointF
                    , "int"     , VarSetCapacity(pointF)/8)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_FillRectangle(gp, pBrush, x, y, w, h)
    ; Description   Use a brush to draw a filled rectangle into the graphics of a bitmap
    ;                                                                                                                   |
    ; gp            Pointer to the graphics of a bitmap
    ; pBrush        Pointer to a brush
    ; x             x-coordinate for the top left of rectangle
    ; y             y-coordinate for the top left of rectangle
    ; w             width of rectanlge
    ; h             height of rectangle
    ;                                                                                                                   |
    ; Return        Status enumeration value. 0 = success.                                                              |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;___________________________________________________________________________________________________________________|
    Gdip_FillRectangle(gp, pBrush, x, y, w, h)
    {
        Return DllCall("gdiplus\GdipFillRectangle"
                        , this.Ptr  , gp
                        , this.Ptr  , pBrush
                        , "float"   , x
                        , "float"   , y
                        , "float"   , w
                        , "float"   , h)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_FillRoundedRectangle(gp, pBrush, x, y, w, h, r)
    ; Description   Use a brush to draw a filled rounded rectangle into the graphics of a bitmap
    ;                                                                                                                   |
    ; gp            Pointer to the graphics of a bitmap
    ; pBrush        Pointer to a brush
    ; x             x-coordinate for the top left of rounded rectangle
    ; y             y-coordinate for the top left of rounded rectangle
    ; w             width of rounded rectanlge
    ; h             height of rounded rectangle
    ; r             radius of rounded corners
    ;                                                                                                                   |
    ; Return        Status enumeration value. 0 = success.                                                              |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;___________________________________________________________________________________________________________________|
    Gdip_FillRoundedRectangle(gp, pBrush, x, y, w, h, r)
    {
        Region := this.Gdip_GetClipRegion(gp)
        , this.Gdip_SetClipRect(gp, x-r, y-r, 2*r, 2*r, 4)
        , this.Gdip_SetClipRect(gp, x+w-r, y-r, 2*r, 2*r, 4)
        , this.Gdip_SetClipRect(gp, x-r, y+h-r, 2*r, 2*r, 4)
        , this.Gdip_SetClipRect(gp, x+w-r, y+h-r, 2*r, 2*r, 4)
        , status := this.Gdip_FillRectangle(gp, pBrush, x, y, w, h)
        , this.Gdip_SetClipRegion(gp, Region, 0)
        , this.Gdip_SetClipRect(gp, x-(2*r), y+r, w+(4*r), h-(2*r), 4)
        , this.Gdip_SetClipRect(gp, x+r, y-(2*r), w-(2*r), h+(4*r), 4)
        , this.Gdip_FillEllipse(gp, pBrush, x, y, 2*r, 2*r)
        , this.Gdip_FillEllipse(gp, pBrush, x+w-(2*r), y, 2*r, 2*r)
        , this.Gdip_FillEllipse(gp, pBrush, x, y+h-(2*r), 2*r, 2*r)
        , this.Gdip_FillEllipse(gp, pBrush, x+w-(2*r), y+h-(2*r), 2*r, 2*r)
        , this.Gdip_SetClipRegion(gp, Region, 0)
        , this.Gdip_DeleteRegion(Region)
        
        Return status
    }
    
    ;####################################################################################################################
    ; Call          Gdip_FillPolygon(gp, pBrush, points, FillMode=0)
    ; Description   Use a brush to draw a filled polygon into the graphics of a bitmap
    ;                                                                                                                   |
    ; gp            Pointer to the graphics of a bitmap
    ; pBrush        Pointer to a brush
    ; Points        List of x,y coords. String: "x1,y1|x2,y2|..." or object: [[x1,y1], [x2,y2], ...]                    |
    ;               The get_points_from_var() method covers all acceptable types Points data                            |
    ; FillMode      Set alternate or winding for filling mode                                                           |
    ;               0 = Alternate = fill the polygon as a whole                                                         |
    ;               1 = Winding   = fill each new "segment"                                                             |
    ;                                                                                                                   |
    ; Return        Status enumeration value. 0 = success.                                                              |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;___________________________________________________________________________________________________________________|
    Gdip_FillPolygon(gp, pBrush, points, FillMode=0)
    {
        this.get_points_from_var(pointF, points)
        Return DllCall("gdiplus\GdipFillPolygon"
                        , this.Ptr  , gp
                        , this.Ptr  , pBrush
                        , this.Ptr  , &pointF
                        , "int"     , VarSetCapacity(pointF)/8
                        , "int"     , FillMode)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_DrawPolygon(gp, pPen, points)
    ; Description   Use a pen to draw a polygon outline into the graphics of a bitmap
    ;                                                                                                                   |
    ; gp            Pointer to the graphics of a bitmap
    ; pBrush        Pointer to a brush
    ; Points        List of x,y coords. String: "x1,y1|x2,y2|..." or object: [[x1,y1], [x2,y2], ...]                    |
    ;               The get_points_from_var() method covers all acceptable types Points data                            |
    ;                                                                                                                   |
    ; Return        Status enumeration value. 0 = success.                                                              |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;___________________________________________________________________________________________________________________|
    Gdip_DrawPolygon(gp, pPen, points)
    {
        this.get_points_from_var(pointF, points)
        Return DllCall("gdiplus\GdipDrawPolygon"
                        , this.Ptr  , gp
                        , this.Ptr  , pPen
                        , this.Ptr  , &pointF
                        , "int"     , VarSetCapacity(pointF)/8)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_FillPie(gp, pBrush, x, y, w, h, StartAngle, SweepAngle)
    ; Description   Use a brush to draw a filled pie into the graphics of a bitmap
    ;                                                                                                                   |
    ; gp            Pointer to the graphics of a bitmap                                                                 |
    ; pPen          Pointer to a pen                                                                                    |
    ; x             x-coordinate of upper-left corner of bounding rectangle for the ellipse that will make the pie      |
    ; y             y-coordinate of upper-left corner of bounding rectangle for the ellipse that will make the pie      |
    ; w             width of the ellipse that contains the pie                                                          |
    ; h             height of the ellipse that contains the pie                                                         |
    ; StartAngle    Starting angle/degree of the pie's arc                                                              |
    ; SweepAngle    Ending angle/degree of the pie's arc                                                                |
    ;                                                                                                                   |
    ; Return        Status enumeration value. 0 = success.                                                              |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;___________________________________________________________________________________________________________________|
    Gdip_FillPie(gp, pBrush, x, y, w, h, StartAngle, SweepAngle)
    {
        Return DllCall("gdiplus\GdipFillPie"
                        , this.Ptr  , gp
                        , this.Ptr  , pBrush
                        , "float"   , x
                        , "float"   , y
                        , "float"   , w
                        , "float"   , h
                        , "float"   , StartAngle
                        , "float"   , SweepAngle)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_FillEllipse(gp, pBrush, x, y, w, h)
    ; Description   Use a brush to draw a filled ellipse into the graphics of a bitmap
    ;                                                                                                                   |
    ; gp            Pointer to the graphics of a bitmap
    ; pBrush        Pointer to a brush
    ; x             x-coordinate for the top left of ellipse
    ; y             y-coordinate for the top left of ellipse
    ; w             width of rounded rectanlge
    ; h             height of ellipse
    ;                                                                                                                   |
    ; Return        Status enumeration value. 0 = success.                                                              |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;___________________________________________________________________________________________________________________|
    Gdip_FillEllipse(gp, pBrush, x, y, w, h)
    {
        Return DllCall("gdiplus\GdipFillEllipse"
                        , this.Ptr  , gp
                        , this.Ptr  , pBrush
                        , "float"   , x
                        , "float"   , y
                        , "float"   , w
                        , "float"   , h)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_FillRegion(gp, pBrush, Region)                                                                 |
    ; Description   Use a brush to fill a region of the graphics of a bitmap                                            |
    ;                                                                                                                   |
    ; gp            Pointer to the graphics of a bitmap                                                                 |
    ; pBrush        Pointer to a brush                                                                                  |
    ; region        Pointer to a region                                                                                 |
    ;                                                                                                                   |
    ; Return        Status enumeration value. 0 = success.                                                              |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;                                                                                                                   |
    ; Notes         Use Gdip_CreateRegion() can create a region                                                         |
    ;___________________________________________________________________________________________________________________|
    Gdip_FillRegion(gp, pBrush, region)
    {
        Return DllCall("gdiplus\GdipFillRegion"
                        , this.Ptr  , gp
                        , this.Ptr  , pBrush
                        , this.Ptr  , region)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_FillPath(gp, pBrush, Path)                                                                     |
    ; Description   Use a brush to fill a path into the graphics of a bitmap                                            |
    ;                                                                                                                   |
    ; gp            Pointer to the graphics of a bitmap                                                                 |
    ; pBrush        Pointer to a brush                                                                                  |
    ; region        Pointer to a graphics path                                                                          |
    ;                                                                                                                   |
    ; Return        Status enumeration value. 0 = success.                                                              |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;___________________________________________________________________________________________________________________|
    Gdip_FillPath(gp, pBrush, Path)
    {
        Return DllCall("gdiplus\GdipFillPath"
                        , this.Ptr  , gp
                        , this.Ptr  , pBrush
                        , this.Ptr  , Path)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_DrawImagePointsRect(gp, pBitmap, Points, sx="", sy="", sw="", sh="", Matrix=1)
    ; Description   Draws a bitmap into the graphics of another bitmap and skews it
    ;                                                                                                                   |
    ; gp            Pointer to the graphics of a bitmap
    ; pBitmap       Pointer to a bitmap to be drawn
    ; Points        List of x,y coords. String: "x1,y1|x2,y2|..." or object: [[x1,y1], [x2,y2], ...]                    |
    ;               The get_points_from_var() method covers all acceptable types Points data                            |
    ; sx            x-coordinate of source upper-left corner
    ; sy            y-coordinate of source upper-left corner
    ; sw            width of source rectangle
    ; sh            height of source rectangle
    ; Matrix        A matrix used to alter image attributes when drawing
    ;               Matrix can be a default matrix like                                                                 |
    ;                                                                                                                   |
    ; Return        Status enumeration value. 0 = success.                                                              |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;                                                                                                                   |
    ; Notes         If sx,sy,sw,sh are missed, a default value will be used
    ;               Matrix can be omitted to just draw with no alteration to ARGB
    ;               Matrix may be passed as a digit from 0 - 1 to change just transparency
    ;               Matrix can be passed as a matrix with any delimiter
    ;___________________________________________________________________________________________________________________|
    Gdip_DrawImagePointsRect(gp, pBitmap, Points, sx="", sy="", sw="", sh="", mtx=1)
    {
        this.get_points_from_var(pointF, points)
        , (mtx&1 = "")
            ? ImageAttr := this.Gdip_SetImageAttributesColorMatrix(mtx)
            : (mtx != 1)
            ? ImageAttr := this.Gdip_SetImageAttributesColorMatrix("1|0|0|0|0|"
                                                                 . "0|1|0|0|0|"
                                                                 . "0|0|1|0|0|"
                                                                 . "0|0|0|" mtx "|0|"
                                                                 . "0|0|0|0|1")
            : ""
        , (sx = "") ? sx := 0 : ""
        , (sy = "") ? sy := 0 : ""
        , (sw = "") ? sw := this.Gdip_GetImageWidth(pBitmap) : ""
        , (sh = "") ? sh := this.Gdip_GetImageHeight(pBitmap) : ""
        , status := DllCall("gdiplus\GdipDrawImagePointsRect"
                            , this.Ptr  , gp                        ; pointer to graphics
                            , this.Ptr  , pBitmap                   ; pointer to image
                            , this.Ptr  , &pointF                   ; points struct with x,y coords
                            , "int"     , VarSetCapacity(pointF)/8  ; Total x,y coords
                            , "float"   , sx                        ; upper-left x-coord of where image is to be drawn
                            , "float"   , sy                        ; upper-left y-coord of where image is to be drawn
                            , "float"   , sw                        ; width of the portion of source image to be drawn
                            , "float"   , sh                        ; height of the portion of source image to be drawn
                            , "int"     , 2                         ; Unit of measure (2=pixel). See Unit enumeration.
                            , this.Ptr  , ImageAttr                 ; Pointer to image attribute
                            , this.Ptr  , 0                         ; Callback method to cancel drawing
                            , this.Ptr  , 0)                        ; Pointer to data used by callback method
        , (ImageAttr)                                               ; If ImageAttr exists, delete it
            ? this.Gdip_DisposeImageAttributes(ImageAttr) : ""
        
        Return status
    }
    
    ;####################################################################################################################
    ; Call          Gdip_DrawImage(gp, pBitmap, dx="", dy="", dw="", dh="", sx="", sy="", sw="", sh="", Matrix=1)
    ; Description   Draws a bitmap into the graphics of another bitmap
    ;                                                                                                                   |
    ; gp            Pointer to the graphics of a bitmap
    ; pBitmap       Pointer to a bitmap to be drawn
    ; dx            x-coord of destination upper-left corner
    ; dy            y-coord of destination upper-left corner
    ; dw            width of destination image
    ; dh            height of destination image
    ; sx            x-coordinate of source upper-left corner
    ; sy            y-coordinate of source upper-left corner
    ; sw            width of source image
    ; sh            height of source image
    ; Matrix        Matrix used to alter image attributes when drawing
    ;                                                                                                                   |
    ; Return        Status enumeration value. 0 = success.                                                              |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;                                                                                                                   |
    ; Notes         If sx or sy are missing, 0 will be used
    ;               If sw or sh are missing, source bitmap width or height will be used (respectively)
    ;               The portion of the source image to be drawn is scaled to fit the rectangle
    ;               Omitting mtx will draw with no alteration to ARGB
    ;               Predefined matrices available: this.MatrixBright, this.MatrixNegative, and this.MatrixGreyScale     |
    ;                _MatrixBright__________    _MatrixNegative__    _MatrixGreyScale_______                            |
    ;               |1.5  |0    |0    |0 |0 |  |-1 |0  |0  |0 |0 |  |0.299|0.299|0.299|0 |0 |                           |
    ;               |0    |1.5  |0    |0 |0 |  |0  |-1 |0  |0 |0 |  |0.587|0.587|0.587|0 |0 |                           |
    ;               |0    |0    |1.5  |0 |0 |  |0  |0  |-1 |0 |0 |  |0.114|0.114|0.114|0 |0 |                           |
    ;               |0    |0    |0    |1 |0 |  |0  |0  |0  |1 |0 |  |0    |0    |0    |1 |0 |                           |
    ;               |0.05 |0.05 |0.05 |0 |1 |  |0  |0  |0  |0 |1 |  |0    |0    |0    |0 |1 |                           |
    ;                ------------------------  -------------------  -------------------------                           |
    ;___________________________________________________________________________________________________________________|
    Gdip_DrawImage(gp, pBitmap, dx="", dy="", dw="", dh="", sx="", sy="", sw="", sh="", mtx=1)
    {
        (mtx&1 = "")
            ? ImageAttr := this.Gdip_SetImageAttributesColorMatrix(mtx)
            : (mtx != 1)
            ? ImageAttr := this.Gdip_SetImageAttributesColorMatrix("1|0|0|0|0|"
                                                                 . "0|1|0|0|0|"
                                                                 . "0|0|1|0|0|"
                                                                 . "0|0|0|" mtx "|0|"
                                                                 . "0|0|0|0|1")
            : ""
        , (sx = "") ? sx := 0 : ""
        , (sy = "") ? sy := 0 : "" 
        , (sw = "") ? sw := this.Gdip_GetImageWidth(pBitmap) : ""
        , (sh = "") ? sh := this.Gdip_GetImageHeight(pBitmap) : ""
        , (dx = "") ? dx := sx : ""
        , (dy = "") ? dy := sy : ""
        , (dw = "") ? dw := sw : ""
        , (dh = "") ? dh := sh : ""
        , status := DllCall("gdiplus\GdipDrawImageRectRect"
                            , this.Ptr , gp    , this.Ptr , pBitmap
                            , "float"  , dx    , "float"  , dy
                            , "float"  , dw    , "float"  , dh
                            , "float"  , sx    , "float"  , sy
                            , "float"  , sw    , "float"  , sh
                            , "int"    , 2     , this.Ptr , ImageAttr
                            , this.Ptr , 0     , this.Ptr , 0)
        , (ImageAttr) ? this.Gdip_DisposeImageAttributes(ImageAttr) : ""
        
        Return status
    }
    
    ;####################################################################################################################
    ; Call          Gdip_SetImageAttributesColorMatrix(mtx)                                                             |
    ; Description   Creates and sets a color-adjustment matrix for a specified category.                                |
    ;                                                                                                                   |
    ; mtx           A 5x5 color matrix used to alter image attributes when drawing.                                     |
    ;                                                                                                                   |
    ; Return        Image attribute matrix or 0 on failure                                                              |
    ;___________________________________________________________________________________________________________________|
    Gdip_SetImageAttributesColorMatrix(mtx)
    {
        VarSetCapacity(colorMatrix, 100, 0)
        , ImageAttr := ""
        , mtx       := RegExReplace(mtx, "^[^\d-\.]+([\d\.])", "$1", "", 1)
        , mtx       := RegExReplace(mtx, "[^\d-\.]+", "|")
        , data      := StrSplit(mtx, "|")
        
        Loop, 25
        {
            (data[A_Index] = "")
                ? data[A_Index] := (Mod(A_Index-1, 6) ? 0 : 1)
                : ""
            , NumPut(data[A_Index], colorMatrix, (A_Index-1)*4, "float")
        }
        
        DllCall("gdiplus\GdipCreateImageAttributes", this.PtrA, ImageAttr)
        , DllCall("gdiplus\GdipSetImageAttributesColorMatrix"
                , this.Ptr  , ImageAttr
                , "int"     , 1
                , "int"     , 1
                , this.Ptr  , &colorMatrix
                , this.Ptr  , 0
                , "int"     , 0)
        
        Return ImageAttr
    }
    
    ;####################################################################################################################
    ; Call          Gdip_GraphicsFromImage(pBitmap)
    ; Description   Creates a graphics object that is associated with an image object.
    ;                                                                                                                   |
    ; pBitmap       Pointer to the bitmap to get graphics from
    ;                                                                                                                   |
    ; Return        Pointer to the graphics of a bitmap
    ;                                                                                                                   |
    ; Notes         A bitmap can be drawn into the graphics of another bitmap
    ;___________________________________________________________________________________________________________________|
    Gdip_GraphicsFromImage(pBitmap)
    {
        gp := "", DllCall("gdiplus\GdipGetImageGraphicsContext", this.Ptr, pBitmap, this.PtrA, gp)
        Return gp
    }
    
    ;####################################################################################################################
    ; Call          Gdip_GraphicsFromHDC(hdc)
    ; Description   Gets the graphics from the handle to a device context
    ;                                                                                                                   |
    ; hdc           Handle to the device context                                                                        |
    ;                                                                                                                   |
    ; Return        Pointer to the graphics of a bitmap
    ;                                                                                                                   |
    ; Notes         You can draw a bitmap into the graphics of another bitmap
    ;___________________________________________________________________________________________________________________|
    Gdip_GraphicsFromHDC(hdc)
    {
        gp := "", DllCall("gdiplus\GdipCreateFromHDC", this.Ptr, hdc, this.PtrA, gp)
        Return gp
    }
    
    ;####################################################################################################################
    ; Call          Gdip_GetDC(gp)
    ; Description   Get handle to the device context associated with this graphics object
    ;                                                                                                                   |
    ; hdc           Handle to the device context                                                                        |
    ;                                                                                                                   |
    ; Return        Returns the device context for the graphics of a bitmap
    ;___________________________________________________________________________________________________________________|
    Gdip_GetDC(gp)
    {
        hdc := "", DllCall("gdiplus\GdipGetDC", this.Ptr, gp, this.PtrA, hdc)
        Return hdc
    }
    
    ;####################################################################################################################
    ; Call          Gdip_ReleaseDC(gp, hdc)
    ; Description   Releases a device context from use
    ;                                                                                                                   |
    ; gp            Pointer to the graphics of a bitmap
    ; hdc           Handle to the device context                                                                        |
    ;                                                                                                                   |
    ; Return        Status enumeration value. 0 = success.                                                              |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;___________________________________________________________________________________________________________________|
    Gdip_ReleaseDC(gp, hdc)
    {
        Return DllCall("gdiplus\GdipReleaseDC", this.Ptr, gp, this.Ptr, hdc)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_GraphicsClear
    ; Description   Clears the graphics of a bitmap
    ;                                                                                                                   |
    ; gp            Pointer to the graphics of a bitmap
    ; ARGB          Default color to make the graphics of the cleared bitmap
    ;                                                                                                                   |
    ; Return        Status enumeration value. 0 = success.                                                              |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;                                                                                                                   |
    ; Notes         Default is black with full transparency
    ;               Using clipping regions you can clear a particular area on the graphics rather than clearing the entire graphics
    ;___________________________________________________________________________________________________________________|
    Gdip_GraphicsClear(gp, ARGB=0x00FFFFFF)
    {
        Return DllCall("gdiplus\GdipGraphicsClear", this.Ptr, gp, "int", ARGB)
    }
    

    
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;; COME BACK TO THIS LATER ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    
    
    
    ;####################################################################################################################
    ; Call          Gdip_SaveBitmapToFile(pBitmap, sOutput, Quality=75)
    ; Description   Saves a bitmap to a file in any supported format onto disk
    ;                                                                                                                   |
    ; pBitmap       Pointer to a bitmap
    ; savePath      The name of the file that the bitmap will be saved to.
    ;               Supported extensions are: .BMP,.DIB,.RLE,.JPG,.JPEG,.JPE,.JFIF,.GIF,.TIF,.TIFF,.PNG
    ; Quality       If saving as jpg (.JPG,.JPEG,.JPE,.JFIF) then quality can be 1-100 with default at maximum quality
    ;                                                                                                                   |
    ; Return        If the function succeeds, the Return value is zero, otherwise:
    ;               -1 = Extension provided not supported.
    ;               -2 = Unable to retrieve encoder list.
    ;               -3 = Unable to find matching encoder.
    ;               -4 = Unable to get WideChar name of output file
    ;               -5 = Unable to save file to disk
    ;                                                                                                                   |
    ; Notes         This function will use the extension supplied from the savePath parameter to determine the output format
    ;___________________________________________________________________________________________________________________|
    Gdip_SaveBitmapToFile(pBitmap, savePath, Quality=75)
    {
        SplitPath, savePath,,, Extension
        If !InStr("BMP|DIB|RLE|JPG|JPEG|JPE|JFIF|GIF|TIF|TIFF|PNG", extension)
            Return -1
        ; Should this be the list? GDI+ image file formats: "BMP|EMF|EXIF|GIF|HEIF|Icon|JPEG|PNG|TIFF|WEBP|WMF"
        
        Extension := "." Extension
        , encodeNum := encodeSize := para := ""
        , DllCall("gdiplus\GdipGetImageEncodersSize"
                , "uint*"   , encodeNum
                , "uint*"   , encodeSize)
        , VarSetCapacity(codecInfo, encodeSize)
        , DllCall("gdiplus\GdipGetImageEncoders"
                , "uint"    , encodeNum
                , "uint"    , encodeSize
                , this.Ptr  , &codecInfo)
        
        if !(encodeNum && encodeSize)
            Return -2
        
        ; get pointer to right codec
        If (A_IsUnicode)
        {
            Loop, % encodeNum
            {
                idx := (48+7*A_PtrSize)*(A_Index-1)
                sString := StrGet(NumGet(codecInfo, idx+32+3*A_PtrSize), ,"UTF-16")
                if !InStr(sString, "*" Extension)
                    continue
                
                pCodec := &codecInfo+idx
                break
            }
        }
        else
        {
            Loop, % encodeNum
            {
                Location := NumGet(codecInfo, 76*(A_Index-1)+44)
                , encodeSize := DllCall("WideCharToMultiByte"
                                    , "uint"    , 0
                                    , "uint"    , 0
                                    , "uint"    , Location
                                    , "int"     , -1
                                    , "uint"    , 0
                                    , "int"     , 0
                                    , "uint"    , 0
                                    , "uint"    , 0)
                , VarSetCapacity(sString, encodeSize)
                , DllCall("WideCharToMultiByte"
                        , "uint"    , 0
                        , "uint"    , 0
                        , "uint"    , Location
                        , "int"     , -1
                        , "str"     , sString
                        , "int"     , encodeSize
                        , "uint"    , 0
                        , "uint"    , 0)
                
                if !InStr(sString, "*" Extension)
                    Continue
                
                pCodec := &codecInfo+76*(A_Index-1)
                break
            }
        }
        
        ; If not got pcode, error -3
        if !pCodec
            Return -3
        
        
        ; Set values now so they don't have to be evaluated each loop
        offset      := (A_PtrSize ? A_PtrSize : 4) + 24
        , pad       := (A_PtrSize = 8) ? 4 : 0
        ; Check quality
        If (Quality != 75)
        {
            ; Make sure quality is in range
            (Quality < 0)           ? quality := 0
                : (Quality > 100)   ? quality := 100
                : ""
            
            ; JPEG specific check for something
            if InStr(".JPG .JPEG .JPE .JFIF", Extension)
            {
                ; Get size of encoder param list
                DllCall("gdiplus\GdipGetEncoderParameterListSize", this.Ptr, pBitmap, this.Ptr, pCodec, "uint*", encodeSize)
                ; Create a variable with that size
                VarSetCapacity(EncoderParameters, encodeSize, 0)
                ; Get param list
                DllCall("gdiplus\GdipGetEncoderParameterList", this.Ptr, pBitmap, this.Ptr, pCodec, "uint", encodeSize, this.Ptr, &EncoderParameters)
                ; Loop 
                Loop, % NumGet(EncoderParameters, "UInt")      ;%
                {
                    elem := offset * (A_Index-1) + 4 + pad
                    If (NumGet(EncoderParameters, elem+16, "UInt") = 1) && (NumGet(EncoderParameters, elem+20, "UInt") = 6)
                    {
                        para := elem+&EncoderParameters-pad-4
                        NumPut(Quality, NumGet(NumPut(4, NumPut(1, para+0)+20, "UInt")), "UInt")
                        Break
                    }
                }      
            }
        }
        
        If (!A_IsUnicode)
        {
            encodeSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, this.Ptr, &savePath, "int", -1, this.Ptr, 0, "int", 0)
            VarSetCapacity(wOutput, encodeSize*2)
            DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, this.Ptr, &savePath, "int", -1, this.Ptr, &wOutput, "int", encodeSize)
            VarSetCapacity(wOutput, -1)
            if !VarSetCapacity(wOutput)
                Return -4
            E := DllCall("gdiplus\GdipSaveImageToFile"
                        , this.Ptr, pBitmap
                        , this.Ptr, &wOutput
                        , this.Ptr, pCodec
                        , "uint", para ? para : 0)
        }
        else
            E := DllCall("gdiplus\GdipSaveImageToFile"
                        , this.Ptr, pBitmap
                        , this.Ptr, &savePath
                        , this.Ptr, pCodec
                        , "uint", para ? para : 0)
        
        Return E ? -5 : 0
    }
    
    ;####################################################################################################################
    ; Call          Gdip_GetPixel(pBitmap, x, y)
    ; Description   Get the ARGB of a specific pixel in a bitmap
    ;                                                                                                                   |
    ; pBitmap       Pointer to a bitmap
    ; x             x-coordinate of pixel
    ; y             y-coordinate of pixel
    ;                                                                                                                   |
    ; Return        ARGB value of pixel
    ;___________________________________________________________________________________________________________________|
    Gdip_GetPixel(pBitmap, x, y)
    {
        ARGB := "", DllCall("gdiplus\GdipBitmapGetPixel"
                            , this.Ptr  , pBitmap
                            , "int"     , x
                            , "int"     , y
                            , "uint*"   , ARGB)
        Return ARGB
    }
    
    ;####################################################################################################################
    ; Call          Gdip_SetPixel(pBitmap, x, y, ARGB)
    ; Description   Set the ARGB of a specific pixel in a bitmap
    ;                                                                                                                   |
    ; pBitmap       Pointer to a bitmap
    ; x             x-coordinate of pixel
    ; y             y-coordinate of pixel
    ;                                                                                                                   |
    ; Return        Status enumeration value. 0 = success.                                                              |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;___________________________________________________________________________________________________________________|
    Gdip_SetPixel(pBitmap, x, y, ARGB)
    {
        Return DllCall("gdiplus\GdipBitmapSetPixel"
                    , this.Ptr  , pBitmap
                    , "int"     , x
                    , "int"     , y
                    , "int"     , ARGB)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_GetImageWidth(pBitmap)
    ; Description   Get width of a bitmap
    ;                                                                                                                   |
    ; pBitmap       Pointer to a bitmap
    ;                                                                                                                   |
    ; Return        Width in pixels
    ;___________________________________________________________________________________________________________________|
    Gdip_GetImageWidth(pBitmap)
    {
        Width := "", DllCall("gdiplus\GdipGetImageWidth"
                            , this.Ptr  , pBitmap
                            , "uint*"   , Width)
        Return Width
    }
    
    ;####################################################################################################################
    ; Call          Gdip_GetImageHeight(pBitmap)
    ; Description   Get height of a bitmap
    ;                                                                                                                   |
    ; pBitmap       Pointer to a bitmap
    ;                                                                                                                   |
    ; Return        Height in pixels
    ;___________________________________________________________________________________________________________________|
    Gdip_GetImageHeight(pBitmap)
    {
        Height := "", DllCall("gdiplus\GdipGetImageHeight"
                            , this.Ptr  , pBitmap
                            , "uint*"   , Height)
        Return Height
    }
    
    ;####################################################################################################################
    ; Call          Gdip_GetDimensions(pBitmap, ByRef Width, ByRef Height)
    ; Description   Get width and height of a bitmap
    ;                                                                                                                   |
    ; pBitmap       Pointer to a bitmap
    ; Width         Variable to store the width in pixels
    ; Height        Variable to store the height in pixels
    ;                                                                                                                   |
    ; Return        No Return value
    ;___________________________________________________________________________________________________________________|
    Gdip_GetDimensions(pBitmap, ByRef Width, ByRef Height)
    {
        DllCall("gdiplus\GdipGetImageWidth", this.Ptr, pBitmap, "uint*", Width)
        , DllCall("gdiplus\GdipGetImageHeight", this.Ptr, pBitmap, "uint*", Height)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_GetImagePixelFormat(pBitmap)                                                                   |
    ; Description   Get the pixel format of the provided image.                                                         |
    ;                                                                                                                   |
    ; pBitmap       Pointer to a bitmap                                                                                 |
    ;                                                                                                                   |
    ; Return        An integer indicating pixel format. See Image Pixel Format Constants on MSDN for a list.            |
    ;___________________________________________________________________________________________________________________|
    Gdip_GetImagePixelFormat(pBitmap)
    {
        Format := "", DllCall("gdiplus\GdipGetImagePixelFormat", this.Ptr, pBitmap, this.PtrA, Format)
        Return Format
    }
    
    ;####################################################################################################################
    ; Call          Gdip_GetDpiX(gp)
    ; Description   Get horizontal resolution of bitmap's graphics in dots per inch.
    ;                                                                                                                   |
    ; gp            Pointer to the graphics of a bitmap
    ;                                                                                                                   |
    ; Return        DPI x value
    ;___________________________________________________________________________________________________________________|
    Gdip_GetDpiX(gp)
    {
        dpix := "", DllCall("gdiplus\GdipGetDpiX", this.Ptr, gp, "float*", dpix)
        Return Round(dpix)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_GetDpiY(gp)
    ; Description   Get vertical resolution of bitmap's graphics in dots per inch.
    ;                                                                                                                   |
    ; gp            Pointer to the graphics of a bitmap
    ;                                                                                                                   |
    ; Return        DPI y value
    ;___________________________________________________________________________________________________________________|
    Gdip_GetDpiY(gp)
    {
        dpiy := "", DllCall("gdiplus\GdipGetDpiY", this.Ptr, gp, "float*", dpiy)
        Return Round(dpiy)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_GetImageHorizontalResolution(pBitmap)                                                          |
    ; Description   Get horizontal resolution of the image in dots per inch.                                            |
    ;                                                                                                                   |
    ; pBitmap       Pointer to a bitmap
    ;                                                                                                                   |
    ; Return        DPI horizontal value                                                                                                    |
    ;___________________________________________________________________________________________________________________|
    Gdip_GetImageHorizontalResolution(pBitmap)
    {
        dpix := "", DllCall("gdiplus\GdipGetImageHorizontalResolution", this.Ptr, pBitmap, "float*", dpix)
        Return Round(dpix)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_GetImageVerticalResolution(pBitmap)                                                            |
    ; Description   Get vertical resolution of the image in dots per inch.                                              |
    ;                                                                                                                   |
    ; pBitmap       Pointer to a bitmap
    ;                                                                                                                   |
    ; Return        DPI horizontal value                                                                                                    |
    ;___________________________________________________________________________________________________________________|
    Gdip_GetImageVerticalResolution(pBitmap)
    {
        dpiy := "", DllCall("gdiplus\GdipGetImageVerticalResolution", this.Ptr, pBitmap, "float*", dpiy)
        Return Round(dpiy)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_BitmapSetResolution(pBitmap, dpix, dpiy)                                                       |
    ; Description   Sets the resolution of the bitmap object.                                                           |
    ;                                                                                                                   |
    ; pBitmap       Pointer to a bitmap                                                                                 |
    ; dpix          Horizontal resolution in dots per inch                                                              |
    ; dpiy          Vertical resolution in dots per inch                                                                |
    ;                                                                                                                   |
    ; Return        Status enumeration value. 0 = success.                                                              |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;___________________________________________________________________________________________________________________|
    Gdip_BitmapSetResolution(pBitmap, dpiX, dpiY)
    {
        Return DllCall("gdiplus\GdipBitmapSetResolution"
                    , this.Ptr  , pBitmap
                    , "float"   , dpiX
                    , "float"   , dpiY)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_CreateBitmapFromFile(sFile, IconNumber=1, IconSize="")                                         |
    ; Description   Creates a bitmap object from an image file.                                                         |
    ;                                                                                                                   |
    ; sFile         File path                                                                                           |
    ; iconNumber    The index of the icon you want. First icon is 1.                                                    |
    ; iconSize      Desired size of the icon                                                                            |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;                                                                                                                   |
    ; sFile IconNumber IconSize pBitmap
    ;___________________________________________________________________________________________________________________|
    Gdip_CreateBitmapFromFile(sFile, IconNumber=1, IconSize="")
    {
        pBitmap := ""
        ; get extension
        SplitPath, sFile,,, ext
        ; Get image from an exe or dll
        if ext in exe,dll
        {
            ; Create a buffer
            buffSize := 16 + (2*(A_PtrSize ? A_PtrSize : 4))
            ; Assign sizes if none provided
            , Sizes := IconSize ? IconSize : "256|128|64|48|32|16"
            ; Initialize vars
            , hIcon := pBitmapOld  := ""
            , VarSetCapacity(buff, BuffSize, 0)
            
            ; Check each size
            Loop, Parse, % Sizes, % "|"
            {
                ; Attempt to get the icon from file
                DllCall("PrivateExtractIcons"
                        , "str"     , sFile         ; File path
                        , "int"     , IconNumber-1  ; Icon index
                        , "int"     , A_LoopField   ; Horizontal icon desired
                        , "int"     , A_LoopField   ; Vertical icon desired
                        , this.PtrA , hIcon         ; Handle to icon
                        , this.PtrA , 0             ; Pointer to a returned resource identifier
                        , "uint"    , 1             ; Number of icons to extract
                        , "uint"    , 0)            ; Flags (LR_* LoadImage flag)
                
                ; If not successful, continue to next size
                if !hIcon
                    continue
                
                ; If no info can be gotten from the icon, try next one
                if !DllCall("GetIconInfo", this.Ptr, hIcon, this.Ptr, &buff)
                {
                    this.DestroyIcon(hIcon)
                    continue
                }
                
                ; Get handle to icon's color bitmap
                ; hbmColor := NumGet(buff, 12 + ((A_PtrSize ? A_PtrSize : 4) - 4) + (A_PtrSize ? A_PtrSize : 4))
                hbmColor := NumGet(buff, (A_PtrSize ? (A_PtrSize*2)+8 : 16))
                ; Check if hbmColor is valid and if GetObject succeeded
                if !(hbmColor && DllCall("GetObject"
                                        , this.Ptr  , hbmColor
                                        , "int"     , BuffSize
                                        , this.Ptr  , &buff) )
                {
                    ; If either failed, destroy this icon and continue to next
                    this.DestroyIcon(hIcon)
                    continue
                }
                ; If the thread gets here, break because everything was successful
                Break
            }
            
            ; If a valid handle is never found, return error -1
            if !hIcon
                Return -1
            
            ; Get width and height from buffer
            Width := NumGet(buff, 4, "int")
            , Height := NumGet(buff, 8, "int")
            ; Make new bitmap
            , hbm := this.CreateDIBSection(Width, -Height) ; <------ Why negative height? Test later.
            , hdc := this.CreateCompatibleDC()
            , obm := this.SelectObject(hdc, hbm)
            
            if !DllCall("DrawIconEx"            ; Draw icon or cursor into DC
                        , this.Ptr  , hdc       ; Handle to device context
                        , "int"     , 0         ; Logical x-coord of icon/curosr
                        , "int"     , 0         ; Logical y-coord of icon/curosr
                        , this.Ptr  , hIcon     ; Handle to icon to be drawn
                        , "uint"    , Width     ; Logical width of icon/curosr
                        , "uint"    , Height    ; Logical height of icon/curosr
                        , "uint"    , 0         ; If animated, set frame index
                        , this.Ptr  , 0         ; Pointer to flicker free brush
                        , "uint"    , 3)        ; diFlags (drawing DI_* flags)
            {
                ; If DrawIconEx fails, destroy icon and return error -2
                this.DestroyIcon(hIcon)
                Return -2
            }
            
            ; Create dib (what is 104/84? How is the size of the dib already known?)
            dibSize := (A_PtrSize = 8 ? 104 : 84)           ; sizeof(DIBSECTION) = 76+2 * (A_PtrSize=8?4:0) + 2*A_PtrSize
            , VarSetCapacity(dib, dibSize)
            ; 
            , DllCall("GetObject"                           ; Put bitmap into new dib using handle
                    , this.Ptr  , hbm
                    , "int"     , dibSize
                    , this.Ptr  , &dib)
            , DllCall("gdiplus\GdipCreateBitmapFromScan0"   ; Scan0 is the start of the bitmap data stream?
                    , "int"     , Width
                    , "int"     , Height
                    , "int"     , NumGet(dib, 12, "Int")
                    , "int"     , 0x26200A
                    , this.Ptr  , NumGet(dib, (A_PtrSize = 8 ? 24 : 20))
                    , this.PtrA , pBitmapOld)
            
            ; Create a new bitmap
            , pBitmap := this.Gdip_CreateBitmap(Width, Height)
            ; Get graphics
            , gp := this.Gdip_GraphicsFromImage(pBitmap)
            ; And write 
            , this.Gdip_DrawImage(gp, pBitmapOld, 0, 0, Width, Height, 0, 0, Width, Height)
            
            ; Cleanup
            , this.SelectObject(hdc, obm)
            , this.DeleteObject(hbm)
            , this.DeleteDC(hdc)
            , this.Gdip_DeleteGraphics(gp)
            , this.Gdip_DisposeImage(pBitmapOld)
            , this.DestroyIcon(hIcon)
        }
        ; If not a dll or exe, run this
        else
            ; If unicode
            (A_IsUnicode)
                ; Create the bitmap normally from file
                ? DllCall("gdiplus\GdipCreateBitmapFromFile"
                        , this.Ptr  , &sFile
                        , this.PtrA , pBitmap)
            ; If not unicode, convert sFile to wide char
            : ( VarSetCapacity(wFile, 1024)
                , DllCall("kernel32\MultiByteToWideChar"
                        , "uint"    , 0
                        , "uint"    , 0
                        , this.Ptr  , &sFile
                        , "int"     , -1
                        , this.Ptr  , &wFile
                        , "int"     , 512)
                ; Then create the bitmap with the converted file
                , DllCall("gdiplus\GdipCreateBitmapFromFile"
                        , this.Ptr  , &wFile
                        , this.PtrA , pBitmap) )
        
        ; Return pointer to bitmap
        Return pBitmap
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_CreateBitmapFromHBITMAP(hBitmap, Palette=0)
    {
        pBitmap := "", DllCall("gdiplus\GdipCreateBitmapFromHBITMAP"
                                , this.Ptr  , hBitmap
                                , this.Ptr  , Palette
                                , this.PtrA , pBitmap)
        Return pBitmap
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_CreateHBITMAPFromBitmap(pBitmap, Background=0xFFFFFFFF)
    {
        hbm := ""
        , DllCall("gdiplus\GdipCreateHBITMAPFromBitmap"
                , this.Ptr  , pBitmap
                , this.PtrA , hbm
                , "int"     , Background)
        Return hbm
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_CreateBitmapFromHICON(hIcon)
    {
        DllCall("gdiplus\GdipCreateBitmapFromHICON"
                , this.Ptr  , hIcon
                , this.PtrA , (pBitmap:=""))
        Return pBitmap
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_CreateHICONFromBitmap(pBitmap)
    {
        DllCall("gdiplus\GdipCreateHICONFromBitmap"
                , this.Ptr  , pBitmap
                , this.PtrA , (hIcon:=""))
        Return hIcon
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_CreateBitmap(Width, Height, Format=0x26200A)
    {
        DllCall("gdiplus\GdipCreateBitmapFromScan0"
                , "int"     , Width
                , "int"     , Height
                , "int"     , 0
                , "int"     , Format
                , this.Ptr  , 0
                , this.PtrA , (pBitmap:=""))
        Return pBitmap
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_CreateBitmapFromClipboard()
    {
        if !DllCall("OpenClipboard", this.Ptr, 0)
            Return -1
        if !DllCall("IsClipboardFormatAvailable", "uint", 8)
            Return -2
        if !hBitmap := DllCall("GetClipboardData", "uint", 2, this.Ptr)
            Return -3
        if !pBitmap := this.Gdip_CreateBitmapFromHBITMAP(hBitmap)
            Return -4
        if !DllCall("CloseClipboard")
            Return -5
        this.DeleteObject(hBitmap)
        
        Return pBitmap
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_SetBitmapToClipboard(pBitmap)
    {
        off1        := A_PtrSize = 8 ? 52 : 44
        , off2      := A_PtrSize = 8 ? 32 : 24
        , hBitmap   := this.Gdip_CreateHBITMAPFromBitmap(pBitmap)
        , DllCall("GetObject", this.Ptr, hBitmap, "int", VarSetCapacity(oi, A_PtrSize = 8 ? 104 : 84, 0), this.Ptr, &oi)
        , hdib      := DllCall("GlobalAlloc", "uint", 2, this.Ptr, 40+NumGet(oi, off1, "UInt"), this.Ptr)
        , pdib      := DllCall("GlobalLock", this.Ptr, hdib, this.Ptr)
        , DllCall("RtlMoveMemory", this.Ptr, pdib, this.Ptr, &oi+off2, this.Ptr, 40)
        , DllCall("RtlMoveMemory", this.Ptr, pdib+40, this.Ptr, NumGet(oi, off2 - (A_PtrSize ? A_PtrSize : 4), this.Ptr), this.Ptr, NumGet(oi, off1, "UInt"))
        , DllCall("GlobalUnlock", this.Ptr, hdib)
        , DllCall("DeleteObject", this.Ptr, hBitmap)
        , DllCall("OpenClipboard", this.Ptr, 0)
        , DllCall("EmptyClipboard")
        , DllCall("SetClipboardData", "uint", 8, this.Ptr, hdib)
        , DllCall("CloseClipboard")
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_CloneBitmapArea(pBitmap, x, y, w, h, Format=0x26200A)
    {
        DllCall("gdiplus\GdipCloneBitmapArea"
                        , "float"   , x
                        , "float"   , y
                        , "float"   , w
                        , "float"   , h
                        , "int"     , Format
                        , this.Ptr  , pBitmap
                        , this.PtrA , (pBitmapDest:=""))
        Return pBitmapDest
    }
    
    ;###################################################################################################################
    ; Create resources
    ;###################################################################################################################
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_CreatePen(ARGB, w)
    {
        DllCall("gdiplus\GdipCreatePen1", "UInt", ARGB, "float", w, "int", 2, this.PtrA, (pPen:=""))
        Return pPen
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_CreatePenFromBrush(pBrush, w)
    {
        DllCall("gdiplus\GdipCreatePen2", this.Ptr, pBrush, "float", w, "int", 2, this.PtrA, (pPen:=""))
        Return pPen
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_BrushCreateSolid(ARGB=0xFF000000)
    {
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", ARGB, this.PtrA, (pBrush:=""))
        Return pBrush
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ; HatchStyleHorizontal              = 0                 HatchStyleDashedDownwardDiagonal  = 30
    ; HatchStyleVertical                = 1                 HatchStyleDashedUpwardDiagonal    = 31
    ; HatchStyleForwardDiagonal         = 2                 HatchStyleDashedHorizontal        = 32
    ; HatchStyleBackwardDiagonal        = 3                 HatchStyleDashedVertical          = 33
    ; HatchStyleCross                   = 4                 HatchStyleSmallConfetti           = 34
    ; HatchStyleDiagonalCross           = 5                 HatchStyleLargeConfetti           = 35
    ; HatchStyle05Percent               = 6                 HatchStyleZigZag                  = 36
    ; HatchStyle10Percent               = 7                 HatchStyleWave                    = 37
    ; HatchStyle20Percent               = 8                 HatchStyleDiagonalBrick           = 38
    ; HatchStyle25Percent               = 9                 HatchStyleHorizontalBrick         = 39
    ;
    ; HatchStyle30Percent               = 10                HatchStyleWeave                   = 40
    ; HatchStyle40Percent               = 11                HatchStylePlaid                   = 41
    ; HatchStyle50Percent               = 12                HatchStyleDivot                   = 42
    ; HatchStyle60Percent               = 13                HatchStyleDottedGrid              = 43
    ; HatchStyle70Percent               = 14                HatchStyleDottedDiamond           = 44
    ; HatchStyle75Percent               = 15                HatchStyleShingle                 = 45
    ; HatchStyle80Percent               = 16                HatchStyleTrellis                 = 46
    ; HatchStyle90Percent               = 17                HatchStyleSphere                  = 47
    ; HatchStyleLightDownwardDiagonal   = 18                HatchStyleSmallGrid               = 48
    ; HatchStyleLightUpwardDiagonal     = 19                HatchStyleSmallCheckerBoard       = 49
    ;
    ; HatchStyleDarkDownwardDiagonal    = 20                HatchStyleLargeCheckerBoard       = 50
    ; HatchStyleDarkUpwardDiagonal      = 21                HatchStyleOutlinedDiamond         = 51
    ; HatchStyleWideDownwardDiagonal    = 22                HatchStyleSolidDiamond            = 52
    ; HatchStyleWideUpwardDiagonal      = 23                HatchStyleTotal                   = 53
    ; HatchStyleLightVertical           = 24
    ; HatchStyleLightHorizontal         = 25
    ; HatchStyleNarrowVertical          = 26
    ; HatchStyleNarrowHorizontal        = 27
    ; HatchStyleDarkVertical            = 28
    ; HatchStyleDarkHorizontal          = 29
    ;___________________________________________________________________________________________________________________|
    Gdip_BrushCreateHatch(ARGBfront, ARGBback, HatchStyle=0)
    {
        DllCall("gdiplus\GdipCreateHatchBrush", "int", HatchStyle, "UInt", ARGBfront, "UInt", ARGBback, this.PtrA, (pBrush:=""))
        Return pBrush
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_CreateTextureBrush(pBitmap, WrapMode=1, x=0, y=0, w="", h="")
    {
        pBrush := ""
        , !(w && h)
            ? DllCall("gdiplus\GdipCreateTexture", this.Ptr, pBitmap, "int", WrapMode, this.PtrA, pBrush)
            : DllCall("gdiplus\GdipCreateTexture2", this.Ptr, pBitmap, "int", WrapMode, "float", x, "float", y, "float", w, "float", h, this.PtrA, pBrush)
        Return pBrush
    }
    
    ;####################################################################################################################
    ; WrapModeTile = 0
    ; WrapModeTileFlipX = 1
    ; WrapModeTileFlipY = 2
    ; WrapModeTileFlipXY = 3
    ; WrapModeClamp = 4
    ;___________________________________________________________________________________________________________________|
    Gdip_CreateLineBrush(x1, y1, x2, y2, ARGB1, ARGB2, WrapMode=1)
    {
        pointF1 := pointF2 := LGpBrush := ""
        , this.CreatepointF(pointF1, x1, y1)
        , this.CreatepointF(pointF2, x2, y2)
        , DllCall("gdiplus\GdipCreateLineBrush", this.Ptr, &pointF1, this.Ptr, &pointF2, "Uint", ARGB1, "Uint", ARGB2, "int", WrapMode, this.PtrA, LGpBrush)
        
        Return LGpBrush
    }
    
    ;####################################################################################################################
    ; LinearGradientModeHorizontal = 0
    ; LinearGradientModeVertical = 1
    ; LinearGradientModeForwardDiagonal = 2
    ; LinearGradientModeBackwardDiagonal = 3
    ;___________________________________________________________________________________________________________________|
    Gdip_CreateLineBrushFromRect(x, y, w, h, ARGB1, ARGB2, LinearGradientMode=1, WrapMode=1)
    {
        this.CreateRectF((RectF:=""), x, y, w, h)
        , DllCall("gdiplus\GdipCreateLineBrushFromRect", this.Ptr, &RectF, "int", ARGB1, "int", ARGB2, "int", LinearGradientMode, "int", WrapMode, this.PtrA, (LGpBrush:=""))
        Return LGpBrush
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_CloneBrush(pBrush)
    {
        DllCall("gdiplus\GdipCloneBrush", this.Ptr, pBrush, this.PtrA, (pBrushClone:=""))
        Return pBrushClone
    }
    
    ;###################################################################################################################
    ; Delete resources
    ;###################################################################################################################
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_DeletePen(pPen)
    {
        Return DllCall("gdiplus\GdipDeletePen", this.Ptr, pPen)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_DeleteBrush(pBrush)
    {
        Return DllCall("gdiplus\GdipDeleteBrush", this.Ptr, pBrush)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_DisposeImage(pBitmap)
    {
        Return DllCall("gdiplus\GdipDisposeImage", this.Ptr, pBitmap)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_DeleteGraphics(gp)
    {
        Return DllCall("gdiplus\GdipDeleteGraphics", this.Ptr, gp)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_DisposeImageAttributes(ImageAttr)
    {
        Return DllCall("gdiplus\GdipDisposeImageAttributes", this.Ptr, ImageAttr)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_DeleteFont(hFont)
    {
        Return DllCall("gdiplus\GdipDeleteFont", this.Ptr, hFont)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_DeleteStringFormat(hFormat)
    {
        Return DllCall("gdiplus\GdipDeleteStringFormat", this.Ptr, hFormat)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_DeleteFontFamily(hFamily)
    {
        Return DllCall("gdiplus\GdipDeleteFontFamily", this.Ptr, hFamily)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_DeleteMatrix(Matrix)
    {
        Return DllCall("gdiplus\GdipDeleteMatrix", this.Ptr, Matrix)
    }
    
    ;###################################################################################################################
    ; Text functions
    ;###################################################################################################################
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_TextToGraphics(gp, Text, Options, Font="Arial", Width="", Height="", Measure=0)
    {
        IWidth      := Width
        , IHeight   := Height
        , PassBrush := 0
        , RegExMatch(Options, "i)X([\-\d\.]+)(p*)", xpos)
        , RegExMatch(Options, "i)Y([\-\d\.]+)(p*)", ypos)
        , RegExMatch(Options, "i)W([\-\d\.]+)(p*)", Width)
        , RegExMatch(Options, "i)H([\-\d\.]+)(p*)", Height)
        , RegExMatch(Options, "i)C(?!(entre|enter))([a-f\d]+)", color)
        , RegExMatch(Options, "i)Top|Up|Bottom|Down|vCentre|vCenter", vPos)
        , RegExMatch(Options, "i)NoWrap", NoWrap)
        , RegExMatch(Options, "i)R(\d)", Rendering)
        , RegExMatch(Options, "i)S(\d+)(p*)", Size)
        
        if !this.Gdip_DeleteBrush(this.Gdip_CloneBrush(color2))
            PassBrush   := 1
            , pBrush    := color2
        
        if !(IWidth && IHeight)
        && (xpos2 || ypos2 || Width2 || Height2 || Size2)
            Return -1
        
        Style := 0
        , Styles := "Regular|Bold|Italic|BoldItalic|Underline|Strikeout"
        Loop, Parse, Styles, |
        {
            if RegExMatch(Options, "\b" A_loopField)
            Style |= (A_LoopField != "StrikeOut") ? (A_Index-1) : 8
        }
        
        Align := 0
        , Alignments := "Near|Left|Centre|Center|Far|Right"
        Loop, Parse, Alignments, |
        {
            if RegExMatch(Options, "\b" A_loopField)
                Align |= A_Index//2.1      ; 0|0|1|1|2|2
        }
        
        xpos    := (xpos1 != "")
                    ? xpos2
                        ? IWidth*(xpos1/100)
                        : xpos1
                    : 0
        ypos    := (ypos1 != "")
                    ? ypos2
                        ? IHeight*(ypos1/100)
                        : ypos1
                    : 0
        Width   := Width1
                    ? Width2
                        ? IWidth*(Width1/100)
                        : Width1
                    : IWidth
        Height  := Height1
                    ? Height2
                        ? IHeight*(Height1/100)
                        : Height1
                    : IHeight
        
        if !PassBrush
            color := "0x" (color2 ? color2 : "FF000000")
        
        Rendering   := ((Rendering1 >= 0) && (Rendering1 <= 5)) ? Rendering1 : 4
        , Size      := (Size1 > 0) ? Size2 ? IHeight*(Size1/100) : Size1 : 12
        , hFamily   := this.Gdip_FontFamilyCreate(Font)
        , hFont     := this.Gdip_FontCreate(hFamily, Size, Style)
        , hFormat   := this.Gdip_StringFormatCreate(NoWrap ? 0x4000 | 0x1000 : 0x4000) ;FormatStyle := NoWrap ? 0x4000 | 0x1000 : 0x4000, hFormat   := this.Gdip_StringFormatCreate(FormatStyle)
        , pBrush    := PassBrush ? pBrush : this.Gdip_BrushCreateSolid(color)
        
        if !(hFamily && hFont && hFormat && pBrush && gp)
            Return  !gp  ? -2
                : !hFamily      ? -3
                : !hFont        ? -4
                : !hFormat      ? -5
                : !pBrush       ? -6
                : 0
        
        this.CreateRectF((RC:=""), xpos, ypos, Width, Height)
        , this.Gdip_SetStringFormatAlign(hFormat, Align)
        , this.Gdip_SetTextRenderingHint(gp, Rendering)
        , ReturnRC := this.Gdip_MeasureString(gp, Text, hFont, hFormat, RC)
        
        if vPos
        {
            StringSplit, ReturnRC, ReturnRC, |
            
            If (vPos = "vCentre") || (vPos = "vCenter")
                ypos += (Height-ReturnRC4)//2
            Else If (vPos = "Top") || (vPos = "Up")
                ypos := 0
            Else If (vPos = "Bottom") || (vPos = "Down")
                ypos := Height-ReturnRC4
            
            this.CreateRectF(RC, xpos, ypos, Width, ReturnRC4)
            ReturnRC := this.Gdip_MeasureString(gp, Text, hFont, hFormat, RC)
        }
        
        if !Measure
            E := this.Gdip_DrawString(gp, Text, hFont, hFormat, pBrush, RC)
        
        if !PassBrush
            this.Gdip_DeleteBrush(pBrush)
        this.Gdip_DeleteStringFormat(hFormat)   
        this.Gdip_DeleteFont(hFont)
        this.Gdip_DeleteFontFamily(hFamily)
        Return E ? E : ReturnRC
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_DrawString(gp, sString, hFont, hFormat, pBrush, ByRef RectF)
    {
        If (!A_IsUnicode)
        {
            nSize := DllCall("MultiByteToWideChar"
                            , "uint"    , 0
                            , "uint"    , 0
                            , this.Ptr  , &sString
                            , "int"     , -1
                            , this.Ptr  , 0
                            , "int"     , 0)
            , VarSetCapacity(wString, nSize*2)
            , DllCall("MultiByteToWideChar"
                    , "uint"    , 0
                    , "uint"    , 0
                    , this.Ptr  , &sString
                    , "int"     , -1
                    , this.Ptr  , &wString
                    , "int"     , nSize)
        }
        
        Return DllCall("gdiplus\GdipDrawString"
                    , this.Ptr  , gp
                    , this.Ptr  , A_IsUnicode ? &sString : &wString
                    , "int"     , -1
                    , this.Ptr  , hFont
                    , this.Ptr  , &RectF
                    , this.Ptr  , hFormat
                    , this.Ptr  , pBrush)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_MeasureString(gp, sString, hFont, hFormat, ByRef RectF)
    {
        VarSetCapacity((RC:=""), 16)
        if !A_IsUnicode
        {
            nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, this.Ptr, &sString, "int", -1, "uint", 0, "int", 0)
            , VarSetCapacity(wString, nSize*2)   
            , DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, this.Ptr, &sString, "int", -1, this.Ptr, &wString, "int", nSize)
        }
        
        DllCall("gdiplus\GdipMeasureString"
                        , this.Ptr  , gp
                        , this.Ptr  , A_IsUnicode ? &sString : &wString
                        , "int"     , -1
                        , this.Ptr  , hFont
                        , this.Ptr  , &RectF
                        , this.Ptr  , hFormat
                        , this.Ptr  , &RC
                        , "uint*"   , (Chars:="")
                        , "uint*"   , (Lines:="") )
        
        Return &RC ? NumGet(RC, 0, "float") "|" NumGet(RC, 4, "float") "|" NumGet(RC, 8, "float") "|" NumGet(RC, 12, "float") "|" Chars "|" Lines : 0
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    ; Near = 0
    ; Center = 1
    ; Far = 2
    ;___________________________________________________________________________________________________________________|
    Gdip_SetStringFormatAlign(hFormat, Align)
    {
        Return DllCall("gdiplus\GdipSetStringFormatAlign", this.Ptr, hFormat, "int", Align)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    ; StringFormatFlagsDirectionRightToLeft    = 0x00000001
    ; StringFormatFlagsDirectionVertical       = 0x00000002
    ; StringFormatFlagsNoFitBlackBox           = 0x00000004
    ; StringFormatFlagsDisplayFormatControl    = 0x00000020
    ; StringFormatFlagsNoFontFallback          = 0x00000400
    ; StringFormatFlagsMeasureTrailingSpaces   = 0x00000800
    ; StringFormatFlagsNoWrap                  = 0x00001000
    ; StringFormatFlagsLineLimit               = 0x00002000
    ; StringFormatFlagsNoClip                  = 0x00004000 
    ;___________________________________________________________________________________________________________________|
    Gdip_StringFormatCreate(Format=0, Lang=0)
    {
        DllCall("gdiplus\GdipCreateStringFormat", "int", Format, "int", Lang, this.PtrA, (hFormat:=""))
        Return hFormat
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    ; Regular = 0
    ; Bold = 1
    ; Italic = 2
    ; BoldItalic = 3
    ; Underline = 4
    ; Strikeout = 8
    ;___________________________________________________________________________________________________________________|
    Gdip_FontCreate(hFamily, Size, Style=0)
    {
        DllCall("gdiplus\GdipCreateFont", this.Ptr, hFamily, "float", Size, "int", Style, "int", 0, this.PtrA, (hFont:=""))
        Return hFont
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_FontFamilyCreate(Font)
    {
        If (!A_IsUnicode)
        {
            nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, this.Ptr, &Font, "int", -1, "uint", 0, "int", 0)
            , VarSetCapacity(wFont, nSize*2)
            , DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, this.Ptr, &Font, "int", -1, this.Ptr, &wFont, "int", nSize)
        }
        
        DllCall("gdiplus\GdipCreateFontFamilyFromName"
                        , this.Ptr  , A_IsUnicode ? &Font : &wFont
                        , "uint"    , 0
                        , this.PtrA , (hFamily:=""))
        
        Return hFamily
    }
    
    ;###################################################################################################################
    ; Matrix functions
    ;###################################################################################################################
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_CreateAffineMatrix(m11, m12, m21, m22, x, y)
    {
        DllCall("gdiplus\GdipCreateMatrix2", "float", m11, "float", m12, "float", m21, "float", m22, "float", x, "float", y, this.PtrA, (Matrix:=""))
        Return Matrix
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_CreateMatrix()
    {
        DllCall("gdiplus\GdipCreateMatrix", this.PtrA, (Matrix:=""))
        Return Matrix
    }
    
    ;####################################################################################################################
    ; Call          generate_matrix_types()                                                                             |
    ; Description   Generate and store the various matrices used with GDI+ functions requiring a color matrix.          |
    ;                                                                                                                   |
    ;                _MatrixBright__________    _MatrixNegative__    _MatrixGreyScale__________                         |
    ;               |1.5  |0    |0    |0 |0 |  |-1 |0  |0  |0 |0 |  |0.299 |0.299 |0.299 |0 |0 |                        |
    ;               |0    |1.5  |0    |0 |0 |  |0  |-1 |0  |0 |0 |  |0.587 |0.587 |0.587 |0 |0 |                        |
    ;               |0    |0    |1.5  |0 |0 |  |0  |0  |-1 |0 |0 |  |0.114 |0.114 |0.114 |0 |0 |                        |
    ;               |0    |0    |0    |1 |0 |  |0  |0  |0  |1 |0 |  |0     |0     |0     |1 |0 |                        |
    ;               |0.05 |0.05 |0.05 |0 |1 |  |0  |0  |0  |0 |1 |  |0     |0     |0     |0 |1 |                        |
    ;               |-----------------------|  |-----------------|  |--------------------------|                        |
    ;___________________________________________________________________________________________________________________|
    generate_matrix_types()
    {
        this.MatrixGrayScale   := "0.299|0.299|0.299|0|0|0.587|0.587|0.587|0|0|0.114|0.114|0.114|0|0|0|0|0|1|0|0|0|0|0|1"
        , this.MatrixGreyScale := this.MatrixGrayScale
        , this.MatrixBright    := "1.5|0|0|0|0|0|1.5|0|0|0|0|0|1.5|0|0|0|0|0|1|0|0.05|0.05|0.05|0|1"
        , this.MatrixNegative  := "-1|0|0|0|0|0|-1|0|0|0|0|0|-1|0|0|0|0|0|1|0|0|0|0|0|1"
        Return
    }

    ;###################################################################################################################
    ; GraphicsPath functions
    ;###################################################################################################################
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    ; Alternate = 0
    ; Winding = 1
    ;___________________________________________________________________________________________________________________|
    Gdip_CreatePath(BrushMode=0)
    {
        DllCall("gdiplus\GdipCreatePath", "int", BrushMode, this.PtrA, (Path:=""))
        Return Path
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_AddPathEllipse(Path, x, y, w, h)
    {
        Return DllCall("gdiplus\GdipAddPathEllipse"
                        , this.Ptr  , Path
                        , "float"   , x
                        , "float"   , y
                        , "float"   , w
                        , "float"   , h)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_AddPathPolygon(path, points)
    {
        this.get_points_from_var(pointF, points)
        Return DllCall("gdiplus\GdipAddPathPolygon"
                        , this.Ptr  , path
                        , this.Ptr  , &pointF
                        , "int"     , VarSetCapacity(pointF)/8)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_DeletePath(Path)
    {
        Return DllCall("gdiplus\GdipDeletePath", this.Ptr, Path)
    }
    
    ;###################################################################################################################
    ; Quality functions
    ;###################################################################################################################
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    ; SystemDefault             = 0
    ; SingleBitPerPixelGridFit  = 1
    ; SingleBitPerPixel         = 2
    ; AntiAliasGridFit          = 3
    ; AntiAlias                 = 4
    ;___________________________________________________________________________________________________________________|
    Gdip_SetTextRenderingHint(gp, RenderingHint)
    {
        Return DllCall("gdiplus\GdipSetTextRenderingHint", this.Ptr, gp, "int", RenderingHint)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    ; Default               = 0
    ; LowQuality            = 1
    ; HighQuality           = 2
    ; Bilinear              = 3
    ; Bicubic               = 4
    ; NearestNeighbor       = 5
    ; HighQualityBilinear   = 6
    ; HighQualityBicubic    = 7
    ;___________________________________________________________________________________________________________________|
    Gdip_SetInterpolationMode(gp, InterpolationMode)
    {
        Return DllCall("gdiplus\GdipSetInterpolationMode", this.Ptr, gp, "int", InterpolationMode)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    ; Invalid      = 0
    ; Default      = 1
    ; HighSpeed    = 2
    ; HighQuality  = 3
    ; None         = 4
    ; AntiAlias    = 5
    ; AntiAlias8x4 = 6
    ; AntiAlias8x8 = 7
    ;___________________________________________________________________________________________________________________|
    Gdip_SetSmoothingMode(gp, SmoothingMode)
    {
        Return DllCall("gdiplus\GdipSetSmoothingMode", this.Ptr, gp, "int", SmoothingMode)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    ; CompositingModeSourceOver = 0 (blended)
    ; CompositingModeSourceCopy = 1 (overwrite)
    ;___________________________________________________________________________________________________________________|
    Gdip_SetCompositingMode(gp, CompositingMode=0)
    {
        Return DllCall("gdiplus\GdipSetCompositingMode", this.Ptr, gp, "int", CompositingMode)
    }
    
    ;###################################################################################################################
    ; Extra functions
    ;###################################################################################################################
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    __New()
    {
        this.Ptr    := A_PtrSize ? "UPtr"   : "UInt"    ; Set pointer types
        this.PtrA   := A_PtrSize ? "UPtr*"  : "UInt*"
        this.pToken := this.Startup()                   ; Start up GDIP
        this.generate_colors()                          ; Generate color object
        this.generate_matrix_types()
        OnExit(this.run_method("__Delete"))             ; Set cleanup method to run at script exit
        
        Return 0
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    __Delete(pToken)
    {
        Return this.Shutdown(this.pToken)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Startup()
    {
        
        (!DllCall("GetModuleHandle", "str", "gdiplus", Ptr)) 
            ? DllCall("LoadLibrary", "str", "gdiplus") : ""
        , VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0)
        , si := Chr(1)
        , pToken := ""
        , DllCall("gdiplus\GdiplusStartup"
                , this.PtrA , pToken
                , this.Ptr  , &si
                , this.Ptr  , 0)
        
        Return pToken
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Shutdown(pToken)
    {
        DllCall("gdiplus\GdiplusShutdown", this.Ptr, pToken)
        if hModule := DllCall("GetModuleHandle", "str", "gdiplus", this.Ptr)
            DllCall("FreeLibrary", this.Ptr, hModule)
        Return 0
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    ; Prepend = 0; The new operation is applied before the old operation.
    ; Append = 1; The new operation is applied after the old operation.
    ;___________________________________________________________________________________________________________________|
    Gdip_RotateWorldTransform(gp, Angle, MatrixOrder=0)
    {
        Return DllCall("gdiplus\GdipRotateWorldTransform", this.Ptr, gp, "float", Angle, "int", MatrixOrder)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    ;___________________________________________________________________________________________________________________|
    Gdip_ScaleWorldTransform(gp, x, y, MatrixOrder=0)
    {
        Return DllCall("gdiplus\GdipScaleWorldTransform", this.Ptr, gp, "float", x, "float", y, "int", MatrixOrder)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    ;___________________________________________________________________________________________________________________|
    Gdip_TranslateWorldTransform(gp, x, y, MatrixOrder=0)
    {
        Return DllCall("gdiplus\GdipTranslateWorldTransform", this.Ptr, gp, "float", x, "float", y, "int", MatrixOrder)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    ;___________________________________________________________________________________________________________________|
    Gdip_ResetWorldTransform(gp)
    {
        Return DllCall("gdiplus\GdipResetWorldTransform", this.Ptr, gp)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    ;___________________________________________________________________________________________________________________|
    Gdip_GetRotatedTranslation(Width, Height, Angle, ByRef xTranslation, ByRef yTranslation)
    {
        TAngle  := Angle*(3.14159/180)
        , Bound := (Angle >= 0)
                ? Mod(Angle, 360)
                : 360-Mod(-Angle, -360)
        
        If ((Bound >= 0) && (Bound <= 90))
            xTranslation    := Height*Sin(TAngle)
            , yTranslation  := 0
        Else If ((Bound > 90) && (Bound <= 180))
            xTranslation    := (Height*Sin(TAngle))-(Width*Cos(TAngle))
            , yTranslation  := -Height*Cos(TAngle)
        Else If ((Bound > 180) && (Bound <= 270))
            xTranslation    := -(Width*Cos(TAngle))
            , yTranslation  := -(Height*Cos(TAngle))-(Width*Sin(TAngle))
        Else If ((Bound > 270) && (Bound <= 360))
            xTranslation    := 0
            , yTranslation  := -Width*Sin(TAngle)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_GetRotatedDimensions(width, height, angle, ByRef new_width, ByRef new_height)                  |
    ; Description   Calculates the new width and height needed to accommodate an image after it has been rotated.       |
    ;                                                                                                                   |
    ; width         Width of the image                                                                                  |
    ; height        Height of the image                                                                                 |
    ; angle         Angle (in degrees) the image is being rotated                                                       |
    ; new_width     Variable to store the image width needed after rotation                                             |
    ; new_height    Variable to store the image height needed after rotation                                            |
    ;                                                                                                                   |
    ; Return        -1 = Failure                                                                                        |
    ;                0 = Success                                                                                        |
    ;___________________________________________________________________________________________________________________|
    Gdip_GetRotatedDimensions(width, height, angle, ByRef new_width, ByRef new_height)
    {
        t_angle := angle*(3.14159/180)
        , ret := 0
        , (width = 0)
            ? (ret := -1, new_width := "Error")
            : new_width  := ceil(abs(width * cos(t_angle)) + abs(height * sin(t_angle)))
        , (height = 0)
            ? (ret := -1, new_height := "Error")
            : new_height  := ceil(abs(height * cos(t_angle)) + abs(height * sin(t_angle)))
        return ret
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    ; RotateNoneFlipNone   = 0
    ; Rotate90FlipNone     = 1
    ; Rotate180FlipNone    = 2
    ; Rotate270FlipNone    = 3
    ; RotateNoneFlipX      = 4
    ; Rotate90FlipX        = 5
    ; Rotate180FlipX       = 6
    ; Rotate270FlipX       = 7
    ; RotateNoneFlipY      = Rotate180FlipX
    ; Rotate90FlipY        = Rotate270FlipX
    ; Rotate180FlipY       = RotateNoneFlipX
    ; Rotate270FlipY       = Rotate90FlipX
    ; RotateNoneFlipXY     = Rotate180FlipNone
    ; Rotate90FlipXY       = Rotate270FlipNone
    ; Rotate180FlipXY      = RotateNoneFlipNone
    ; Rotate270FlipXY      = Rotate90FlipNone 
    ;___________________________________________________________________________________________________________________|
    Gdip_ImageRotateFlip(pBitmap, RotateFlipType=1)
    {
        Return DllCall("gdiplus\GdipImageRotateFlip", this.Ptr, pBitmap, "int", RotateFlipType)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_SetClipRect(gp, x, y, w, h, CombineMode=0)                                                     |
    ; Description   Update the clipping region of a graphics object to a combined region of itself and a rectangle.     |
    ;                                                                                                                   |
    ; gp            Pointer to graphics                                                                                 |
    ; x             x-coordinate of rectangle's upper-left corner                                                       |
    ; y             y-coordinate of rectangle's upper-left corner                                                       |
    ; w             Width of the rectangle                                                                              |
    ; h             Height of the rectangle                                                                             |
    ; CombineMode   Replace the existing region with:                                                                   |
    ;               0x0 Replace:    New region.                                                                         |
    ;               0x1 Intersect:  Intersection of existing region and new region.                                     |
    ;               0x2 Union:      Union of the existing and new regions.                                              |
    ;               0x4 XOR:        XOR of the existing and new regions.                                                |
    ;               0x5 Exclude:    The part of itself that is not in the new region.                                   |
    ;               0x6 Complement: The part of the new region that is not in the existing region.                      |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_SetClipRect(gp, x, y, w, h, CombineMode=0)
    {
        Return DllCall("gdiplus\GdipSetClipRect"
                        , this.Ptr  , gp
                        , "float"   , x
                        , "float"   , y
                        , "float"   , w
                        , "float"   , h
                        , "int"     , CombineMode)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   Gdip_SetClipPath(gp, Path, CombineMode=0)                                                           |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_SetClipPath(gp, Path, CombineMode=0)
    {
        Return DllCall("gdiplus\GdipSetClipPath"
                        , this.Ptr  , gp
                        , this.Ptr  , Path
                        , "int"     , CombineMode)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_ResetClip(gp)
    {
        Return DllCall("gdiplus\GdipResetClip", this.Ptr, gp)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_GetClipRegion(gp)
    {
        Region := this.Gdip_CreateRegion()
        , DllCall("gdiplus\GdipGetClip", this.Ptr, gp, "UInt*", Region)
        Return Region
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_SetClipRegion(gp, Region, CombineMode=0)
    {
        Return DllCall("gdiplus\GdipSetClipRegion", this.Ptr, gp, this.Ptr, Region, "int", CombineMode)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_CreateRegion()
    {
        DllCall("gdiplus\GdipCreateRegion", "UInt*", (Region:=""))
        Return Region
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_DeleteRegion(Region)
    {
        Return DllCall("gdiplus\GdipDeleteRegion", this.Ptr, Region)
    }
    
    ;###################################################################################################################
    ; BitmapLockBits
    ;###################################################################################################################
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_LockBits(pBitmap, x, y, w, h, ByRef Stride, ByRef Scan0, ByRef BitmapData, LockMode = 3, PixelFormat = 0x26200A)
    {
        this.CreateRect((Rect:=""), x, y, w, h)
        , VarSetCapacity(BitmapData, 16+2*(A_PtrSize ? A_PtrSize : 4), 0)
        , E         := DllCall("Gdiplus\GdipBitmapLockBits", this.Ptr, pBitmap, this.Ptr, &Rect, "uint", LockMode, "int", PixelFormat, this.Ptr, &BitmapData)
        , Stride    := NumGet(BitmapData, 8, "Int")
        , Scan0     := NumGet(BitmapData, 16, this.Ptr)
        Return E
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_UnlockBits(pBitmap, ByRef BitmapData)
    {
        Return DllCall("Gdiplus\GdipBitmapUnlockBits", this.Ptr, pBitmap, this.Ptr, &BitmapData)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_SetLockBitPixel(ARGB, Scan0, x, y, Stride)
    {
        Numput(ARGB, Scan0+0, (x*4)+(y*Stride), "UInt")
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_GetLockBitPixel(Scan0, x, y, Stride)
    {
        Return NumGet(Scan0+0, (x*4)+(y*Stride), "UInt")
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_PixelateBitmap(pBitmap, ByRef pBitmapOut, BlockSize)
    {
        Static PixelateBitmap := ""
        
        If (!PixelateBitmap)
        {
            MCode_PixelateBitmap := (A_PtrSize != 8) ; x86 machine code
            ?     "558BEC83EC3C8B4514538B5D1C99F7FB56578BC88955EC894DD885C90F8E830200008B451099F7FB8365DC008365E000894D"
                . "C88955F08945E833FF897DD4397DE80F8E160100008BCB0FAFCB894DCC33C08945F88945FC89451C8945143BD87E608B4508"
                . "8D50028BC82BCA8BF02BF2418945F48B45E02955F4894DC48D0CB80FAFCB03CA895DD08BD1895DE40FB64416030145140FB6"
                . "0201451C8B45C40FB604100145FC8B45F40FB604020145F883C204FF4DE475D6034D18FF4DD075C98B4DCC8B451499F7F989"
                . "45148B451C99F7F989451C8B45FC99F7F98945FC8B45F899F7F98945F885DB7E648B450C8D50028BC82BCA83C103894DC48B"
                . "C82BCA41894DF48B4DD48945E48B45E02955E48D0C880FAFCB03CA895DD08BD18BF38A45148B7DC48804178A451C8B7DF488"
                . "028A45FC8804178A45F88B7DE488043A83C2044E75DA034D18FF4DD075CE8B4DCC8B7DD447897DD43B7DE80F8CF2FEFFFF83"
                . "7DF0000F842C01000033C08945F88945FC89451C8945148945E43BD87E65837DF0007E578B4DDC034DE48B75E80FAF4D180F"
                . "AFF38B45088D500203CA8D0CB18BF08BF88945F48B45F02BF22BFA2955F48945CC0FB6440E030145140FB60101451C0FB644"
                . "0F010145FC8B45F40FB604010145F883C104FF4DCC75D8FF45E4395DE47C9B8B4DF00FAFCB85C9740B8B451499F7F9894514"
                . "EB048365140033F63BCE740B8B451C99F7F989451CEB0389751C3BCE740B8B45FC99F7F98945FCEB038975FC3BCE740B8B45"
                . "F899F7F98945F8EB038975F88975E43BDE7E5A837DF0007E4C8B4DDC034DE48B75E80FAF4D180FAFF38B450C8D500203CA8D"
                . "0CB18BF08BF82BF22BFA2BC28B55F08955CC8A551488540E038A551C88118A55FC88540F018A55F888140183C104FF4DCC75"
                . "DFFF45E4395DE47CA68B45180145E0015DDCFF4DC80F8594FDFFFF8B451099F7FB8955F08945E885C00F8E450100008B45EC"
                . "0FAFC38365DC008945D48B45E88945CC33C08945F88945FC89451C8945148945103945EC7E6085DB7E518B4DD88B45080FAF"
                . "CB034D108D50020FAF4D18034DDC8BF08BF88945F403CA2BF22BFA2955F4895DC80FB6440E030145140FB60101451C0FB644"
                . "0F010145FC8B45F40FB604080145F883C104FF4DC875D8FF45108B45103B45EC7CA08B4DD485C9740B8B451499F7F9894514"
                . "EB048365140033F63BCE740B8B451C99F7F989451CEB0389751C3BCE740B8B45FC99F7F98945FCEB038975FC3BCE740B8B45"
                . "F899F7F98945F8EB038975F88975103975EC7E5585DB7E468B4DD88B450C0FAFCB034D108D50020FAF4D18034DDC8BF08BF8"
                . "03CA2BF22BFA2BC2895DC88A551488540E038A551C88118A55FC88540F018A55F888140183C104FF4DC875DFFF45108B4510"
                . "3B45EC7CAB8BC3C1E0020145DCFF4DCC0F85CEFEFFFF8B4DEC33C08945F88945FC89451C8945148945103BC87E6C3945F07E"
                . "5C8B4DD88B75E80FAFCB034D100FAFF30FAF4D188B45088D500203CA8D0CB18BF08BF88945F48B45F02BF22BFA2955F48945"
                . "C80FB6440E030145140FB60101451C0FB6440F010145FC8B45F40FB604010145F883C104FF4DC875D833C0FF45108B4DEC39"
                . "4D107C940FAF4DF03BC874068B451499F7F933F68945143BCE740B8B451C99F7F989451CEB0389751C3BCE740B8B45FC99F7"
                . "F98945FCEB038975FC3BCE740B8B45F899F7F98945F8EB038975F88975083975EC7E63EB0233F63975F07E4F8B4DD88B75E8"
                . "0FAFCB034D080FAFF30FAF4D188B450C8D500203CA8D0CB18BF08BF82BF22BFA2BC28B55F08955108A551488540E038A551C"
                . "881118A55FC88540F018A55F888140883C104FF4D1075DFFF45088B45083B45EC7C9F5F5E33C05BC9C21800"
            :     "4489442418488954241048894C24085355565741544155415641574883EC28418BC1448B8C24980000004C8BDA99488BD941"
                . "F7F9448BD0448BFA8954240C448994248800000085C00F8E9D020000418BC04533E4458BF299448924244C8954241041F7F9"
                . "33C9898C24980000008BEA89542404448BE889442408EB054C8B5C24784585ED0F8E1A010000458BF1418BFD48897C241845"
                . "0FAFF14533D233F633ED4533E44533ED4585C97E5B4C63BC2490000000418D040A410FAFC148984C8D441802498BD9498BD0"
                . "4D8BD90FB642010FB64AFF4403E80FB60203E90FB64AFE4883C2044403E003F149FFCB75DE4D03C748FFCB75D0488B7C2418"
                . "8B8C24980000004C8B5C2478418BC59941F7FE448BE8418BC49941F7FE448BE08BC59941F7FE8BE88BC69941F7FE8BF04585"
                . "C97E4048639C24900000004103CA4D8BC1410FAFC94863C94A8D541902488BCA498BC144886901448821408869FF408871FE"
                . "4883C10448FFC875E84803D349FFC875DA8B8C2498000000488B5C24704C8B5C24784183C20448FFCF48897C24180F850AFF"
                . "FFFF8B6C2404448B2424448B6C24084C8B74241085ED0F840A01000033FF33DB4533DB4533D24533C04585C97E53488B7424"
                . "7085ED7E42438D0C04418BC50FAF8C2490000000410FAFC18D04814863C8488D5431028BCD0FB642014403D00FB6024883C2"
                . "044403D80FB642FB03D80FB642FA03F848FFC975DE41FFC0453BC17CB28BCD410FAFC985C9740A418BC299F7F98BF0EB0233"
                . "F685C9740B418BC399F7F9448BD8EB034533DB85C9740A8BC399F7F9448BD0EB034533D285C9740A8BC799F7F9448BC0EB03"
                . "4533C033D24585C97E4D4C8B74247885ED7E38418D0C14418BC50FAF8C2490000000410FAFC18D04814863C84A8D4431028B"
                . "CD40887001448818448850FF448840FE4883C00448FFC975E8FFC2413BD17CBD4C8B7424108B8C2498000000038C24900000"
                . "00488B5C24704503E149FFCE44892424898C24980000004C897424100F859EFDFFFF448B7C240C448B842480000000418BC0"
                . "9941F7F98BE8448BEA89942498000000896C240C85C00F8E3B010000448BAC2488000000418BCF448BF5410FAFC9898C2480"
                . "00000033FF33ED33F64533DB4533D24533C04585FF7E524585C97E40418BC5410FAFC14103C00FAF84249000000003C74898"
                . "488D541802498BD90FB642014403D00FB6024883C2044403D80FB642FB03F00FB642FA03E848FFCB75DE488B5C247041FFC0"
                . "453BC77CAE85C9740B418BC299F7F9448BE0EB034533E485C9740A418BC399F7F98BD8EB0233DB85C9740A8BC699F7F9448B"
                . "D8EB034533DB85C9740A8BC599F7F9448BD0EB034533D24533C04585FF7E4E488B4C24784585C97E35418BC5410FAFC14103"
                . "C00FAF84249000000003C74898488D540802498BC144886201881A44885AFF448852FE4883C20448FFC875E941FFC0453BC7"
                . "7CBE8B8C2480000000488B5C2470418BC1C1E00203F849FFCE0F85ECFEFFFF448BAC24980000008B6C240C448BA424880000"
                . "0033FF33DB4533DB4533D24533C04585FF7E5A488B7424704585ED7E48418BCC8BC5410FAFC94103C80FAF8C249000000041"
                . "0FAFC18D04814863C8488D543102418BCD0FB642014403D00FB6024883C2044403D80FB642FB03D80FB642FA03F848FFC975"
                . "DE41FFC0453BC77CAB418BCF410FAFCD85C9740A418BC299F7F98BF0EB0233F685C9740B418BC399F7F9448BD8EB034533DB"
                . "85C9740A8BC399F7F9448BD0EB034533D285C9740A8BC799F7F9448BC0EB034533C033D24585FF7E4E4585ED7E42418BCC8B"
                . "C5410FAFC903CA0FAF8C2490000000410FAFC18D04814863C8488B442478488D440102418BCD40887001448818448850FF44"
                . "8840FE4883C00448FFC975E8FFC2413BD77CB233C04883C428415F415E415D415C5F5E5D5BC3"
            
            VarSetCapacity(PixelateBitmap, StrLen(MCode_PixelateBitmap)//2)
            Loop % StrLen(MCode_PixelateBitmap)//2        ;%
                NumPut("0x" SubStr(MCode_PixelateBitmap, (2*A_Index)-1, 2), PixelateBitmap, A_Index-1, "UChar")
            DllCall("VirtualProtect", this.Ptr, &PixelateBitmap, this.Ptr, VarSetCapacity(PixelateBitmap), "uint", 0x40, this.PtrA, 0)
        }
        
        Width := Height := stride1 := stride2 := Scan01 := Scan02 := BitmapData1 := BitmapData2 := ""
        this.Gdip_GetDimensions(pBitmap, Width, Height)
        If (Width != this.Gdip_GetImageWidth(pBitmapOut) || Height != this.Gdip_GetImageHeight(pBitmapOut))
            Return -1
        If (BlockSize > Width || BlockSize > Height)
            Return -2
        
        If (this.Gdip_LockBits(pBitmap, 0, 0, Width, Height, Stride1, Scan01, BitmapData1)
            || this.Gdip_LockBits(pBitmapOut , 0, 0, Width, Height, Stride2, Scan02, BitmapData2))
            Return -3
        
        E := DllCall(&PixelateBitmap, this.Ptr  , Scan01
                                    , this.Ptr  , Scan02
                                    , "int"     , Width
                                    , "int"     , Height
                                    , "int"     , Stride1
                                    , "int"     , BlockSize)
        , this.Gdip_UnlockBits(pBitmap, BitmapData1)
        , this.Gdip_UnlockBits(pBitmapOut, BitmapData2)
        
        Return 0
    }
    
    ;####################################################################################################################
    ; Call          Gdip_PercentToByte(percent, hex=0)                                                                  |
    ; Description   Converts a percentage number to a byte value.                                                       |
    ;                                                                                                                   |
    ; percent       Percent value to convert. This number can exceed 100.                                               |
    ; hex           If set to true, value is returned as hex value                                                      |
    ;                                                                                                                   |
    ; Return        Converted percentage in dec or hex                                                                  |
    ;___________________________________________________________________________________________________________________|
    Gdip_PercentToByte(percent, hex=0)
    {
        Return (hex)
            ? this.ToHex(Round(255 * percent / 100))
            ? Round(255 * percent / 100)
    }
    
    ;####################################################################################################################
    ; Call          Gdip_ToHex(num)                                                                  |
    ; Description   Converts a number to hex                                                                            |
    ;                                                                                                                   |
    ; num           Any number                                                                                          |
    ;                                                                                                                   |
    ; Return        Hex value                                                                                           |
    ;___________________________________________________________________________________________________________________|
    Gdip_ToHex(num)
    {
        Return Format("{:#x}", num)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_ToARGB(A, R, G, B)
    {
        Return (A << 24) | (R << 16) | (G << 8) | B
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_FromARGB(ARGB, ByRef A, ByRef R, ByRef G, ByRef B)
    {
          A := (0xFF000000 & ARGB) >> 24
        , R := (0x00FF0000 & ARGB) >> 16
        , G := (0x0000FF00 & ARGB) >> 8
        , B := (0x000000FF & ARGB)
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_AFromARGB(ARGB)
    {
        Return (0xFF000000 & ARGB) >> 24
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_RFromARGB(ARGB)
    {
        Return (0x00FF0000 & ARGB) >> 16
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_GFromARGB(ARGB)
    {
        Return (0x0000FF00 & ARGB) >> 8
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Gdip_BFromARGB(ARGB)
    {
        Return 0x000000FF & ARGB
    }
    
    ;####################################################################################################################
    ; Call          StrGetB(Address, Length=-1, Encoding=0)                                                             |
    ; Description   |                                                                                                   |
    ;                                                                                                                   |
    ; hdc                                                                                                               |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    StrGetB(Address, Length=-1, Encoding=0)
    {
        ; Flexible parameter handling:
        If Length is not integer
            Encoding := Length
            , Length := -1
        
        ; Check for obvious errors.
        If (Address+0 < 1024)
            Return
        
        ; Ensure 'Encoding' contains a numeric identifier.
        (Encoding = UTF-16)                 ? Encoding := 1200
            : (Encoding = UTF-8)            ? Encoding := 65001
            : (SubStr(Encoding,1,2)="CP")   ? Encoding := SubStr(Encoding,3)
            : ""
        
        if !Encoding ; "" or 0
        {
            ; No conversion necessary, but we might not want the whole string.
            (Length == -1) ? Length := DllCall("lstrlen", "uint", Address) : ""
            , VarSetCapacity(String, Length)
            , DllCall("lstrcpyn"
                    , "str" , String
                    , "uint", Address
                    , "int" , Length + 1)
        }
        else if Encoding = 1200 ; UTF-16
        {
            char_count := DllCall("WideCharToMultiByte"
                                , "uint", 0
                                , "uint", 0x400
                                , "uint", Address
                                , "int" , Length
                                , "uint", 0
                                , "uint", 0
                                , "uint", 0
                                , "uint", 0)
            , VarSetCapacity(String, char_count)
            , DllCall("WideCharToMultiByte"
                    , "uint", 0
                    , "uint", 0x400
                    , "uint", Address
                    , "int" , Length
                    , "str" , String
                    , "int" , char_count
                    , "uint", 0
                    , "uint", 0)
        }
        else if Encoding is integer
        {
            ; Convert from target encoding to UTF-16 then to the active code page.
            char_count      := DllCall("MultiByteToWideChar"
                                        , "uint", Encoding
                                        , "uint", 0
                                        , "uint", Address
                                        , "int" , Length
                                        , "uint", 0
                                        , "int" , 0)
            , VarSetCapacity(String, char_count * 2)
            , char_count    := DllCall("MultiByteToWideChar"
                                        , "uint", Encoding
                                        , "uint", 0
                                        , "uint", Address
                                        , "int" , Length
                                        , "uint", &String
                                        , "int" , char_count * 2)
            , String        := this.StrGetB(&String, char_count, 1200)
        }
        
        Return String
    }
    
    ;####################################################################################################################
    ; Call          generate_colors()                                                                                   |
    ; Description   Generates an object containing all the hex colors from CSS3/X11.                                    |
    ;___________________________________________________________________________________________________________________|
; ########## Colors and Alpha ##########
; This needs to be updated so things like grey/gray are addressed.
; These slight variations should be accounted for
    generate_colors() {
        this.color := {}
        
        ; Pink
        this.color.MediumVioletRed      := 0xC71585
        this.color.DeepPink             := 0xFF1493
        this.color.PaleVioletRed        := 0xDB7093
        this.color.HotPink              := 0xFF69B4
        this.color.LightPink            := 0xFFB6C1
        this.color.Pink                 := 0xFFC0CB
        
        ; Red
        this.color.DarkRed              := 0x8B0000
        this.color.Red                  := 0xFF0000
        this.color.Firebrick            := 0xB22222
        this.color.Crimson              := 0xDC143C
        this.color.IndianRed            := 0xCD5C5C
        this.color.LightCoral           := 0xF08080
        this.color.Salmon               := 0xFA8072
        this.color.DarkSalmon           := 0xE9967A
        this.color.LightSalmon          := 0xFFA07A
        
        ; Orange
        this.color.OrangeRed            := 0xFF4500
        this.color.Tomato               := 0xFF6347
        this.color.DarkOrange           := 0xFF8C00
        this.color.Coral                := 0xFF7F50
        this.color.Orange               := 0xFFA500
        
        ; Yellow
        this.color.DarkKhaki            := 0xBDB76B
        this.color.Gold                 := 0xFFD700
        this.color.Khaki                := 0xF0E68C
        this.color.PeachPuff            := 0xFFDAB9
        this.color.Yellow               := 0xFFFF00
        this.color.PaleGoldenrod        := 0xEEE8AA
        this.color.Moccasin             := 0xFFE4B5
        this.color.PapayaWhip           := 0xFFEFD5
        this.color.LightGoldenrodYellow := 0xFAFAD2
        this.color.LemonChiffon         := 0xFFFACD
        this.color.LightYellow          := 0xFFFFE0
        
        ; Brown
        this.color.Maroon               := 0x800000
        this.color.Brown                := 0xA52A2A
        this.color.SaddleBrown          := 0x8B4513
        this.color.Sienna               := 0xA0522D
        this.color.Chocolate            := 0xD2691E
        this.color.DarkGoldenrod        := 0xB8860B
        this.color.Peru                 := 0xCD853F
        this.color.RosyBrown            := 0xBC8F8F
        this.color.Goldenrod            := 0xDAA520
        this.color.SandyBrown           := 0xF4A460
        this.color.Tan                  := 0xD2B48C
        this.color.Burlywood            := 0xDEB887
        this.color.Wheat                := 0xF5DEB3
        this.color.NavajoWhite          := 0xFFDEAD
        this.color.Bisque               := 0xFFE4C4
        this.color.BlanchedAlmond       := 0xFFEBCD
        this.color.Cornsilk             := 0xFFF8DC
        
        ; Green
        this.color.DarkGreen            := 0x006400
        this.color.Green                := 0x008000
        this.color.DarkOliveGreen       := 0x556B2F
        this.color.ForestGreen          := 0x228B22
        this.color.SeaGreen             := 0x2E8B57
        this.color.Olive                := 0x808000
        this.color.OliveDrab            := 0x6B8E23
        this.color.MediumSeaGreen       := 0x3CB371
        this.color.LimeGreen            := 0x32CD32
        this.color.Lime                 := 0x00FF00
        this.color.SpringGreen          := 0x00FF7F
        this.color.MediumSpringGreen    := 0x00FA9A
        this.color.DarkSeaGreen         := 0x8FBC8F
        this.color.MediumAquamarine     := 0x66CDAA
        this.color.YellowGreen          := 0x9ACD32
        this.color.LawnGreen            := 0x7CFC00
        this.color.Chartreuse           := 0x7FFF00
        this.color.LightGreen           := 0x90EE90
        this.color.GreenYellow          := 0xADFF2F
        this.color.PaleGreen            := 0x98FB98
        
        ; Cyan
        this.color.Teal                 := 0x008080
        this.color.DarkCyan             := 0x008B8B
        this.color.LightSeaGreen        := 0x20B2AA
        this.color.CadetBlue            := 0x5F9EA0
        this.color.DarkTurquoise        := 0x00CED1
        this.color.MediumTurquoise      := 0x48D1CC
        this.color.Turquoise            := 0x40E0D0
        this.color.Aqua                 := 0x00FFFF
        this.color.Cyan                 := 0x00FFFF
        this.color.Aquamarine           := 0x7FFFD4
        this.color.PaleTurquoise        := 0xAFEEEE
        this.color.LightCyan            := 0xE0FFFF
        
        ; Blue
        this.color.Navy                 := 0x000080
        this.color.DarkBlue             := 0x00008B
        this.color.MediumBlue           := 0x0000CD
        this.color.Blue                 := 0x0000FF
        this.color.MidnightBlue         := 0x191970
        this.color.RoyalBlue            := 0x4169E1
        this.color.SteelBlue            := 0x4682B4
        this.color.DodgerBlue           := 0x1E90FF
        this.color.DeepSkyBlue          := 0x00BFFF
        this.color.CornflowerBlue       := 0x6495ED
        this.color.SkyBlue              := 0x87CEEB
        this.color.LightSkyBlue         := 0x87CEFA
        this.color.LightSteelBlue       := 0xB0C4DE
        this.color.LightBlue            := 0xADD8E6
        this.color.PowderBlue           := 0xB0E0E6
        
        ; Purple, violet, and magenta
        this.color.Indigo               := 0x4B0082
        this.color.Purple               := 0x800080
        this.color.DarkMagenta          := 0x8B008B
        this.color.DarkViolet           := 0x9400D3
        this.color.DarkSlateBlue        := 0x483D8B
        this.color.BlueViolet           := 0x8A2BE2
        this.color.DarkOrchid           := 0x9932CC
        this.color.Fuchsia              := 0xFF00FF
        this.color.Magenta              := 0xFF00FF
        this.color.SlateBlue            := 0x6A5ACD
        this.color.MediumSlateBlue      := 0x7B68EE
        this.color.MediumOrchid         := 0xBA55D3
        this.color.MediumPurple         := 0x9370DB
        this.color.Orchid               := 0xDA70D6
        this.color.Violet               := 0xEE82EE
        this.color.Plum                 := 0xDDA0DD
        this.color.Thistle              := 0xD8BFD8
        this.color.Lavender             := 0xE6E6FA
        
        ; White
        this.color.MistyRose            := 0xFFE4E1
        this.color.AntiqueWhite         := 0xFAEBD7
        this.color.Linen                := 0xFAF0E6
        this.color.Beige                := 0xF5F5DC
        this.color.WhiteSmoke           := 0xF5F5F5
        this.color.LavenderBlush        := 0xFFF0F5
        this.color.OldLace              := 0xFDF5E6
        this.color.AliceBlue            := 0xF0F8FF
        this.color.Seashell             := 0xFFF5EE
        this.color.GhostWhite           := 0xF8F8FF
        this.color.Honeydew             := 0xF0FFF0
        this.color.FloralWhite          := 0xFFFAF0
        this.color.Azure                := 0xF0FFFF
        this.color.MintCream            := 0xF5FFFA
        this.color.Snow                 := 0xFFFAFA
        this.color.Ivory                := 0xFFFFF0
        this.color.White                := 0xFFFFFF
        
        ; Black and gray/grey
        this.color.Black                := 0x000000
        this.color.DarkSlateGray        := 0x2F4F4F
        this.color.DarkSlateGrey        := 0x2F4F4F
        this.color.DimGray              := 0x696969
        this.color.DimGrey              := 0x696969
        this.color.SlateGray            := 0x708090
        this.color.SlateGrey            := 0x708090
        this.color.Gray                 := 0x808080
        this.color.Grey                 := 0x808080
        this.color.LightSlateGray       := 0x778899
        this.color.LightSlateGrey       := 0x778899
        this.color.DarkGray             := 0xA9A9A9
        this.color.DarkGrey             := 0xA9A9A9
        this.color.Silver               := 0xC0C0C0
        this.color.LightGray            := 0xD3D3D3
        this.color.LightGrey            := 0xD3D3D3
        this.color.Gainsboro            := 0xDCDCDC
        
        Return
    }
    
    ; ########## Misc Methods ##########
    ;                                                                                                                   |
    ;___________________________________________________________________________________________________________________|
    run_method(method_name, params:="") {
        bf := ObjBindMethod(this, method_name, params*)
        Return bf
    }
    
    ;                                                                                                                   |
    ;___________________________________________________________________________________________________________________|
    rand(min, max) {
        Random, result, % min, % max
        Return result
    }
    
    ;####################################################################################################################
    ; Call          get_points_from_var(ByRef pointF, pts)                                                              |
    ; Description   Size and fill a variable with x/y coords from pts                                                   |
    ;                                                                                                                   |
    ; pointF        Variable to add coords to                                                                           |
    ; pts           One or more x/y coords. Can be string or object.                                                    |
    ;               String: Separate x/y by comma. Separate x/y pairs by pipe. Spaces/tabs are ignored.                 |
    ;                   "1,0|-5,-3|100.1   ,   -100.0|  10  ,   20"                                                     |
    ;               Array: Can be filled with strings using "x,y" format or with arrays with [x,y] coords               |
    ;                   ["1,0", "-5,-3", "100.1,-100.0", "10,20"]                                                       |
    ;                   [[1,0], [-5,-3], [100.1,-100.0], [10,20]]                                                       |
    ;                                                                                                                   |
    ; Return        0 = Success, 1 = Failure                                                                            |
    ;___________________________________________________________________________________________________________________|
    get_points_from_var(ByRef pointF, pts)
    {
        arr := {}                                                       ; object to store coords
        If IsObject(pts)                                                ; If pts is an object
            For index, coords in pts                                    ; Loop through pts
                IsObject(coords)                                        ; Check if first value is string or object 
                    ? arr[A_Index] := [coords.1, coords.2]              ; If already an object, save info to new array
                    : (data := StrSplit(coords, ",", " `t")             ; If string, split data by comma and add to array
                        , arr[A_Index] := [data.1, data.2] )
        Else
            Loop, Parse, % pts, % "|", % " `t"                          ; If pts is a string, parse by pipe
                data := StrSplit(A_LoopField, ",", " `t")               ; Split by comma to spearate x and y coords
                , arr[A_Index] := [data.1, data.2]                      ; Add coords to array
        
        VarSetCapacity(pointF, 8*arr.MaxIndex())                        ; Set var size based on number of coord pairs
        
        For index, coord in arr                                         ; Loop through array
        {
            If (0 * coord.1 = 0) && (0 * coord.2 = 0){                  ; Verify they're numbers and
                  NumPut(coord.1, pointF, 8*(A_Index-1)   , "float")    ; Add x coord to the point var
                , NumPut(coord.2, pointF, 8*(A_Index-1)+4 , "float")    ; Add y coord to the point var
                Continue
            }
            Else                                                        ; If coord 1 or 2 are not numbers
                arr := 1                                                ; Set arr to false
            Break                                                       ; Break loop on failure
        }
        
        Return (arr = 1 ? 1 : 0)                                        ; Return 0 = success, 1 = failure
    }
    
    ; Creates the status object for various GDI failure types
    make_status() {
        this.status := {}
        this.status.0  := "Ok"
        this.status.1  := "GenericError"
        this.status.2  := "InvalidParameter"
        this.status.3  := "OutOfMemory"
        this.status.4  := "ObjectBusy"
        this.status.5  := "InsufficientBuffer"
        this.status.6  := "NotImplemented"
        this.status.7  := "Win32Error"
        this.status.8  := "WrongState"
        this.status.9  := "Aborted"
        this.status.10 := "FileNotFound"
        this.status.11 := "ValueOverflow"
        this.status.12 := "AccessDenied"
        this.status.13 := "UnknownImageFormat"
        this.status.14 := "FontFamilyNotFound"
        this.status.15 := "FontStyleNotFound"
        this.status.16 := "NotTrueTypeFont"
        this.status.17 := "UnsupportedGdiplusVersion"
        this.status.18 := "GdiplusNotInitialized"
        this.status.19 := "PropertyNotFound"
        this.status.20 := "PropertyNotSupported"
        this.status.21 := "ProfileNotFound"
        Return
    }
}

; Resources:
; MSDN (Microsoft Development Network) GDI and GDI+ Reference
;   https://docs.microsoft.com/en-us/windows/win32/gdiplus/-gdiplus-class-gdi-reference
;   https://docs.microsoft.com/en-us/windows/win32/gdi/windows-gdi
; FunctionX GDI tutorial:
;   http://www.functionx.com/bcb/index.htm
; IT Berater's GDI+ Flat API Reference
;   http://www.jose.it-berater.org/gdiplus/iframe/index.htm
; Tariq Porter's original GDI tutorials:
;   https://github.com/tariqporter/Gdip
; AutoIt library docs. Includes GDI+ info
;   https://www.autoitscript.com/autoit3/docs/libfunctions/


; ##### THANK YOU #####
; These are people that helped me figure out something/suggested a great idea along the way.
; tic (github)
; Rseding91 (AHK forums)
; mim (discord)
; SoftCore (discord)

