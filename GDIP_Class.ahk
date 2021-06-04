;#Warn

gdip.__New()
Class gdip
{
    ; GDI+ Windows Library Class Rewrite
    ; v1.48
    ; Update by 0xB0BAFE77 20210501
    ; 
    ; Converted GDIP library to a single class
    ; Updated/corrected many descriptions
    ; Formatted code and text to be more easily readable
    ; All tutorials have been rewritten and updated
    ; Added Gdip_DrawPolygon
    ;                                                                                                                   
    ; Originally created by tic (Tariq Porter) 20110709
    ; Later updated by Rseding91 with fincs 64 bit compatible Gdip library 20130501
    ; Supports: Basic, _L ANSi, _L Unicode x86 and _L Unicode x64
    ; Updated 2/20/2014 - fixed Gdip_CreateRegion() and Gdip_GetClipRegion() on AHK Unicode x86
    ; Updated 5/13/2013 - fixed Gdip_SetBitmapToClipboard() on AHK Unicode x64
    ;                                                                                                                   
    ;##################################################################################################################
    ;##################################################################################################################
    ; STATUS ENUMERATION
    ; Return values for functions specified to have status enumerated Return type
    ;##################################################################################################################
    ;                                                                                                                   
    ; Ok =                      = 0
    ; GenericError              = 1
    ; InvalidParameter          = 2
    ; OutOfMemory               = 3
    ; ObjectBusy                = 4
    ; InsufficientBuffer        = 5
    ; NotImplemented            = 6
    ; Win32Error                = 7
    ; WrongState                = 8
    ; Aborted                   = 9
    ; FileNotFound              = 10
    ; ValueOverflow             = 11
    ; AccessDenied              = 12
    ; UnknownImageFormat        = 13
    ; FontFamilyNotFound        = 14
    ; FontStyleNotFound         = 15
    ; NotTrueTypeFont           = 16
    ; UnsupportedGdiplusVersion = 17
    ; GdiplusNotInitialized     = 18
    ; PropertyNotFound          = 19
    ; PropertyNotSupported      = 20
    ; ProfileNotFound           = 21
    ;                                                                                                                   
    ;##################################################################################################################
    ;##################################################################################################################
    ; METHODS
    ;##################################################################################################################
    ;                                                                                                                   
    ; UpdateLayeredWindow(hwnd, hdc, x="", y="", w="", h="", Alpha=255)
    ; BitBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, Raster="")
    ; StretchBlt(dDC, dx, dy, dw, dh, sDC, sx, sy, sw, sh, Raster="")
    ; SetImage(hwnd, hBitmap)
    ; Gdip_BitmapFromScreen(Screen=0, Raster="")
    ; CreateRectF(ByRef RectF, x, y, w, h)
    ; CreateSizeF(ByRef SizeF, w, h)
    ; CreateDIBSection
    ;                                                                                                                   
    ;##################################################################################################################
    ; Method          UpdateLayeredWindow
    ; Description     Updates a layered window with the handle to the DC of a gdi bitmap
    ;                                                                                                                   
    ; hwnd            Handle of the layered window to update
    ; hdc             Handle to the DC of the GDI bitmap to update the window with
    ; Layeredx        x position to place the window
    ; Layeredy        y position to place the window
    ; Layeredw        Width of the window
    ; Layeredh        Height of the window
    ; Alpha           Default = 255 : The transparency (0-255) to set the window transparency
    ;                                                                                                                   
    ; Return          If the function succeeds, the Return value is nonzero
    ;                                                                                                                   
    ; notes           If x or y omitted, then layered window will use its current coordinates
    ;                 If w or h omitted then current width and height will be used
    
    UpdateLayeredWindow(hwnd, hdc, x="", y="", w="", h="", Alpha=255)
    {
        ((x != "") && (y != ""))
            ? (VarSetCapacity(pt, 8)
                , NumPut(x, pt, 0, "UInt")
                , NumPut(y, pt, 4, "UInt") )
            : ""
        
        if (w = "") || (h = "")
            WinGetPos,,, w, h, ahk_id %hwnd%
        
        Return DllCall("UpdateLayeredWindow"
                        , this.Ptr  , hwnd
                        , this.Ptr  , 0
                        , this.Ptr  , ((x = "") && (y = "")) ? 0 : &pt
                        , "int64*"  , w|h<<32
                        , this.Ptr  , hdc
                        , "int64*"  , 0
                        , "uint"    , 0
                        , "UInt*"   , Alpha<<16|1<<24
                        , "uint"    , 2)
    }
    
    ;##################################################################################################################
    ; Method            BitBlt
    ; Description       The BitBlt function performs a bit-block transfer of the color data corresponding to a rectangle 
    ;                   of pixels from the specified source device context into a destination device context.
    ;                                                                                                                   
    ; dDC               handle to destination DC
    ; dx                x-coord of destination upper-left corner
    ; dy                y-coord of destination upper-left corner
    ; dw                width of the area to copy
    ; dh                height of the area to copy
    ; sDC               handle to source DC
    ; sx                x-coordinate of source upper-left corner
    ; sy                y-coordinate of source upper-left corner
    ; Raster            raster operation code
    ;                                                                                                                   
    ; Return            If the function succeeds, the Return value is nonzero
    ;                                                                                                                   
    ; notes             If no raster operation is specified, then SRCCOPY is used, which copies the source directly to the destination rectangle
    ;                                                                                                                   
    ; BLACKNESS         = 0x00000042
    ; NOTSRCERASE       = 0x001100A6
    ; NOTSRCCOPY        = 0x00330008
    ; SRCERASE          = 0x00440328
    ; DSTINVERT         = 0x00550009
    ; PATINVERT         = 0x005A0049
    ; SRCINVERT         = 0x00660046
    ; SRCAND            = 0x008800C6
    ; MERGEPAINT        = 0x00BB0226
    ; MERGECOPY         = 0x00C000CA
    ; SRCCOPY           = 0x00CC0020
    ; SRCPAINT          = 0x00EE0086
    ; PATCOPY           = 0x00F00021
    ; PATPAINT          = 0x00FB0A09
    ; WHITENESS         = 0x00FF0062
    ; CAPTUREBLT        = 0x40000000
    ; NOMIRRORBITMAP    = 0x80000000
    
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
    
    ;##################################################################################################################
    ; Method            StretchBlt
    ; Description       The StretchBlt function copies a bitmap from a source rectangle into a destination rectangle, 
    ;                   stretching or compressing the bitmap to fit the dimensions of the destination rectangle, if necessary.
    ;                   The system stretches or compresses the bitmap according to the stretching mode currently set in the destination device context.
    ;                                                                                                                   
    ; ddc               handle to destination DC
    ; dx                x-coord of destination upper-left corner
    ; dy                y-coord of destination upper-left corner
    ; dw                width of destination rectangle
    ; dh                height of destination rectangle
    ; sdc               handle to source DC
    ; sx                x-coordinate of source upper-left corner
    ; sy                y-coordinate of source upper-left corner
    ; sw                width of source rectangle
    ; sh                height of source rectangle
    ; Raster            raster operation code
    ;                                                                                                                   
    ; Return            If the function succeeds, the Return value is nonzero
    ;                                                                                                                   
    ; notes             If no raster operation is specified, then SRCCOPY is used. It uses the same raster operations as BitBlt        
    
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
    
    ;##################################################################################################################
    ; Method                SetStretchBltMode
    ; Description           The SetStretchBltMode function sets the bitmap stretching mode in the specified device context
    ;                                                                                                                   
    ; hdc                   handle to the DC
    ; iStretchMode          The stretching mode, describing how the target will be stretched
    ;                                                                                                                   
    ; Return                If the function succeeds, the Return value is the previous stretching mode. If it fails it will Return 0
    ;                                                                                                                   
    ; STRETCH_ANDSCANS      = 0x01
    ; STRETCH_ORSCANS       = 0x02
    ; STRETCH_DELETESCANS   = 0x03
    ; STRETCH_HALFTONE      = 0x04
    
    SetStretchBltMode(hdc, iStretchMode=4)
    {
        Return DllCall("gdi32\SetStretchBltMode"
                        , this.Ptr  , hdc
                        , "int"     , iStretchMode)
    }
    
    ;##################################################################################################################
    ; Method            SetImage
    ; Description       Associates a new image with a static control
    ;                                                                                                                   
    ; hwnd              handle of the control to update
    ; hBitmap           a gdi bitmap to associate the static control with
    ;                                                                                                                   
    ; Return            If the function succeeds, the Return value is nonzero
    
    SetImage(hwnd, hBitmap)
    {
        SendMessage, 0x172, 0x0, hBitmap,, ahk_id %hwnd%
        E := ErrorLevel
        , this.DeleteObject(E)
        Return E
    }
    
    ;##################################################################################################################
    ; Method                        SetSysColorToControl
    ; Description                   Sets a solid colour to a control
    ;                                                                                                                   
    ; hwnd                          handle of the control to update
    ; SysColor                      A system colour to set to the control
    ;                                                                                                                   
    ; Return                        If the function succeeds, the Return value is zero
    ;                                                                                                                   
    ; notes                         A control must have the 0xE style set to it so it is recognised as a bitmap
    ;                               By default SysColor=15 is used which is COLOR_3DFACE. This is the standard background for a control
    ;                                                                                                                   
    ; COLOR_3DDKSHADOW              = 21
    ; COLOR_3DFACE                  = 15
    ; COLOR_3DHIGHLIGHT             = 20
    ; COLOR_3DHILIGHT               = 20
    ; COLOR_3DLIGHT                 = 22
    ; COLOR_3DSHADOW                = 16
    ; COLOR_ACTIVEBORDER            = 10
    ; COLOR_ACTIVECAPTION           =  2
    ; COLOR_APPWORKSPACE            = 12
    ; COLOR_BACKGROUND              =  1
    ; COLOR_BTNFACE                 = 15
    ; COLOR_BTNHIGHLIGHT            = 20
    ; COLOR_BTNHILIGHT              = 20
    ; COLOR_BTNSHADOW               = 16
    ; COLOR_BTNTEXT                 = 18
    ; COLOR_CAPTIONTEXT             =  9
    ; COLOR_DESKTOP                 =  1
    ; COLOR_GRADIENTACTIVECAPTION   = 27
    ; COLOR_GRADIENTINACTIVECAPTION = 28
    ; COLOR_GRAYTEXT                = 17
    ; COLOR_HIGHLIGHT               = 13
    ; COLOR_HIGHLIGHTTEXT           = 14
    ; COLOR_HOTLIGHT                = 26
    ; COLOR_INACTIVEBORDER          = 11
    ; COLOR_INACTIVECAPTION         =  3
    ; COLOR_INACTIVECAPTIONTEXT     = 19
    ; COLOR_INFOBK                  = 24
    ; COLOR_INFOTEXT                = 23
    ; COLOR_MENU                    =  4
    ; COLOR_MENUHILIGHT             = 29
    ; COLOR_MENUBAR                 = 30
    ; COLOR_MENUTEXT                =  7
    ; COLOR_SCROLLBAR               =  0
    ; COLOR_WINDOW                  =  5
    ; COLOR_WINDOWFRAME             =  6
    ; COLOR_WINDOWTEXT              =  8
    
    SetSysColorToControl(hwnd, SysColor=15)
    {
        WinGetPos,,, w, h, ahk_id %hwnd%
        bc               := DllCall("GetSysColor", "Int", SysColor, "UInt")
        , pBrushClear    := this.Gdip_BrushCreateSolid(0xff000000 | (bc >> 16 | bc & 0xff00 | (bc & 0xff) << 16))
        , pBitmap        := this.Gdip_CreateBitmap(w, h)
        , G              := this.Gdip_GraphicsFromImage(pBitmap)
        , this.Gdip_FillRectangle(G, pBrushClear, 0, 0, w, h)
        , hBitmap        := this.Gdip_CreateHBITMAPFromBitmap(pBitmap)
        , this.SetImage(hwnd, hBitmap)
        , this.Gdip_DeleteBrush(pBrushClear)
        , this.Gdip_DeleteGraphics(G)
        , this.Gdip_DisposeImage(pBitmap)
        , this.DeleteObject(hBitmap)
        
        Return 0
    }
    
    ;##################################################################################################################
    ; Method            Gdip_BitmapFromScreen
    ; Description       Gets a gdi+ bitmap from the screen
    ;                                                                                                                   
    ; Screen            0 = All screens
    ;                   Any numerical value = Just that screen
    ;                   x|y|w|h = Take specific coordinates with a width and height
    ; Raster            raster operation code
    ;                                                                                                                   
    ; Return            If the function succeeds, the Return value is a pointer to a gdi+ bitmap
    ;                   -1: One or more of x,y,w,h not passed properly
    ;                                                                                                                   
    ; notes             If no raster operation is specified, then SRCCOPY is used to the Returned bitmap
    
    Gdip_BitmapFromScreen(Screen=0, Raster="")
    {
        if (Screen = 0)
        {
            Sysget, x, 76
            Sysget, y, 77    
            Sysget, w, 78
            Sysget, h, 79
        }
        else if (SubStr(Screen, 1, 5) = "hwnd:")
        {
            Screen := SubStr(Screen, 6)
            if !WinExist( "ahk_id " Screen)
                Return -2
            WinGetPos,,, w, h, ahk_id %Screen%
            x := y := 0
            hhdc := this.GetDCEx(Screen, 3)
        }
        else if (Screen&1 != "")
        {
            Sysget, M, Monitor, %Screen%
            x := MLeft
            , y := MTop
            , w := MRight-MLeft
            , h := MBottom-MTop
        }
        else
        {
            StringSplit, S, Screen, |
            x := S1
            , y := S2
            , w := S3
            , h := S4
        }
        
        if (x = "") || (y = "") || (w = "") || (h = "")
            Return -1
        
        chdc    := this.CreateCompatibleDC()
        , hbm   := this.CreateDIBSection(w, h, chdc)
        , obm   := this.SelectObject(chdc, hbm)
        , hhdc  := hhdc ? hhdc : this.GetDC()
        , this.BitBlt(chdc, 0, 0, w, h, hhdc, x, y, Raster)
        , this.ReleaseDC(hhdc)
        , pBitmap := this.Gdip_CreateBitmapFromHBITMAP(hbm)
        , this.SelectObject(chdc, obm)
        , this.DeleteObject(hbm)
        , this.DeleteDC(hhdc)
        , this.DeleteDC(chdc)
        Return pBitmap
    }
    
    ;##################################################################################################################
    ; Method                  Gdip_BitmapFromHWND
    ; Description            Uses PrintWindow to get a handle to the specified window and Return a bitmap from it
    ;                                                                                                                   
    ; hwnd                    handle to the window to get a bitmap from
    ;                                                                                                                   
    ; Return                If the function succeeds, the Return value is a pointer to a gdi+ bitmap
    ;                                                                                                                   
    ; notes                    Window must not be not minimised in order to get a handle to it's client area
    
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
    
    ;##################################################################################################################
    ; Method                  CreateRectF
    ; Description            Creates a RectF object, containing a the coordinates and dimensions of a rectangle
    ;                                                                                                                   
    ; RectF                   Name to call the RectF object
    ; x                        x-coordinate of the upper left corner of the rectangle
    ; y                        y-coordinate of the upper left corner of the rectangle
    ; w                        Width of the rectangle
    ; h                        Height of the rectangle
    ;                                                                                                                   
    ; Return                  No Return value
    
    CreateRectF(ByRef RectF, x, y, w, h)
    {
        VarSetCapacity(RectF, 16)
        , NumPut(x, RectF, 0, "float")
        , NumPut(y, RectF, 4, "float")
        , NumPut(w, RectF, 8, "float")
        , NumPut(h, RectF, 12, "float")
    }
    
    ;##################################################################################################################
    ; Method                  CreateRect
    ; Description            Creates a Rect object, containing a the coordinates and dimensions of a rectangle
    ;                                                                                                                   
    ; RectF                   Name to call the RectF object
    ; x                        x-coordinate of the upper left corner of the rectangle
    ; y                        y-coordinate of the upper left corner of the rectangle
    ; w                        Width of the rectangle
    ; h                        Height of the rectangle
    ;                                                                                                                   
    ; Return                  No Return value
    
    CreateRect(ByRef Rect, x, y, w, h)
    {
        VarSetCapacity(Rect, 16)
        , NumPut(x, Rect, 0, "uint")
        , NumPut(y, Rect, 4, "uint")
        , NumPut(w, Rect, 8, "uint")
        , NumPut(h, Rect, 12, "uint")
    }
    ;##################################################################################################################
    ; Method                  CreateSizeF
    ; Description            Creates a SizeF object, containing an 2 values
    ;                                                                                                                   
    ; SizeF                 Name to call the SizeF object
    ; w                        w-value for the SizeF object
    ; h                        h-value for the SizeF object
    ;                                                                                                                   
    ; Return                  No Return value
    
    CreateSizeF(ByRef SizeF, w, h)
    {
        VarSetCapacity(SizeF, 8)
        , NumPut(w, SizeF, 0, "float")
        , NumPut(h, SizeF, 4, "float")     
    }
    ;##################################################################################################################
    ; Method            CreatePointF
    ; Description       Creates a SizeF object, containing an 2 values
    ;                                                                                                                   
    ; SizeF             Name to call the SizeF object
    ; w                 w-value for the SizeF object
    ; h                 h-value for the SizeF object
    ;                                                                                                                   
    ; Return            No Return value
    
    CreatePointF(ByRef PointF, x, y)
    {
        VarSetCapacity(PointF, 8)
        , NumPut(x, PointF, 0, "float")
        , NumPut(y, PointF, 4, "float")     
    }
    ;##################################################################################################################
    ; Method            CreateDIBSection
    ; Description       The CreateDIBSection function creates a DIB (Device Independent Bitmap) that applications can write to directly
    ;                                                                                                                   
    ; w                 width of the bitmap to create
    ; h                 height of the bitmap to create
    ; hdc               a handle to the device context to use the palette from
    ; bpp               bits per pixel (32 = ARGB)
    ; ppvBits           A pointer to a variable that receives a pointer to the location of the DIB bit values
    ;                                                                                                                   
    ; Return            Returns a DIB. A gdi bitmap
    ;                                                                                                                   
    ; notes             ppvBits will receive the location of the pixels in the DIB
    
    CreateDIBSection(w, h, hdc="", bpp=32, ByRef ppvBits=0)
    {
        hdc2 := hdc ? hdc : this.GetDC()
        , VarSetCapacity(bi, 40, 0)
        , NumPut(w  ,bi ,4,  "uint")
        , NumPut(h  ,bi ,8,  "uint")
        , NumPut(40 ,bi ,0,  "uint")
        , NumPut(1  ,bi ,12, "ushort")
        , NumPut(0  ,bi ,16, "uInt")
        , NumPut(bpp,bi ,14, "ushort")
        , hbm := DllCall("CreateDIBSection"
                        , this.Ptr  , hdc2
                        , this.Ptr  , &bi
                        , "uint"    , 0
                        , this.PtrA , ppvBits
                        , this.Ptr  , 0
                        , "uint"    , 0
                        , this.Ptr)
        , (!hdc ? this.ReleaseDC(hdc2) : "")
        
        Return hbm
    }
    
    ;##################################################################################################################
    ; Method                  PrintWindow
    ; Description            The PrintWindow function copies a visual window into the specified device context (DC), typically a printer DC
    ;                                                                                                                   
    ; hwnd                    A handle to the window that will be copied
    ; hdc                    A handle to the device context
    ; Flags                    Drawing options
    ;                                                                                                                   
    ; Return                If the function succeeds, it Returns a nonzero value
    ;                                                                                                                   
    ; PW_CLIENTONLY            = 1
    
    PrintWindow(hwnd, hdc, Flags=0)
    {
        Return DllCall("PrintWindow", this.Ptr, hwnd, this.Ptr, hdc, "uint", Flags)
    }
    
    ;##################################################################################################################
    ; Method                  DestroyIcon
    ; Description            Destroys an icon and frees any memory the icon occupied
    ;                                                                                                                   
    ; hIcon                    Handle to the icon to be destroyed. The icon must not be in use
    ;                                                                                                                   
    ; Return                If the function succeeds, the Return value is nonzero
    
    DestroyIcon(hIcon)
    {
        Return DllCall("DestroyIcon", this.Ptr, hIcon)
    }
    
    ;##################################################################################################################
    PaintDesktop(hdc)
    {
        Return DllCall("PaintDesktop", this.Ptr, hdc)
    }
    
    ;##################################################################################################################
    CreateCompatibleBitmap(hdc, w, h)
    {
        Return DllCall("gdi32\CreateCompatibleBitmap", this.Ptr, hdc, "int", w, "int", h)
    }
    
    ;##################################################################################################################
    ; Method            CreateCompatibleDC
    ; Description       This function creates a memory device context (DC) compatible with the specified device
    ;                                                                                                                   
    ; hdc               Handle to an existing device context                    
    ;                                                                                                                   
    ; Return            Returns the handle to a device context or 0 on failure
    ;                                                                                                                   
    ; notes             If this handle is 0 (by default), the function creates a memory device context compatible with the application's current screen
    
    CreateCompatibleDC(hdc=0)
    {
        Return DllCall("CreateCompatibleDC", this.Ptr, hdc)
    }
    
    ;##################################################################################################################
    ; Method            SelectObject
    ; Description       The SelectObject function selects an object into the specified device context (DC). The new object replaces the previous object of the same type
    ;                                                                                                                   
    ; hdc               Handle to a DC
    ; hgdiobj           A handle to the object to be selected into the DC
    ;                                                                                                                   
    ; Return            If the selected object is not a region and the function succeeds, the Return value is a handle to the object being replaced
    ;                                                                                                                   
    ; notes             The specified object must have been created by using one of the following functions
    ;                   Bitmap - CreateBitmap, CreateBitmapIndirect, CreateCompatibleBitmap, CreateDIBitmap, CreateDIBSection (A single bitmap cannot be selected into more than one DC at the same time)
    ;                   Brush - CreateBrushIndirect, CreateDIBPatternBrush, CreateDIBPatternBrushPt, CreateHatchBrush, CreatePatternBrush, CreateSolidBrush
    ;                   Font - CreateFont, CreateFontIndirect
    ;                   Pen - CreatePen, CreatePenIndirect
    ;                   Region - CombineRgn, CreateEllipticRgn, CreateEllipticRgnIndirect, CreatePolygonRgn, CreateRectRgn, CreateRectRgnIndirect
    ;                                                                                                                   
    ; notes             If the selected object is a region and the function succeeds, the Return value is one of the following value
    ;                                                                                                                   
    ; SIMPLEREGION      = 2 Region consists of a single rectangle
    ; COMPLEXREGION     = 3 Region consists of more than one rectangle
    ; NULLREGION        = 1 Region is empty
    
    SelectObject(hdc, hgdiobj)
    {
        Return DllCall("SelectObject", this.Ptr, hdc, this.Ptr, hgdiobj)
    }
    
    ;##################################################################################################################
    ; Method                  DeleteObject
    ; Description            This function deletes a logical pen, brush, font, bitmap, region, or palette, freeing all system resources associated with the object
    ;                        After the object is deleted, the specified handle is no longer valid
    ;                                                                                                                   
    ; hObject                Handle to a logical pen, brush, font, bitmap, region, or palette to delete
    ;                                                                                                                   
    ; Return                Nonzero indicates success. Zero indicates that the specified handle is not valid or that the handle is currently selected into a device context
    
    DeleteObject(hObject)
    {
        Return DllCall("DeleteObject", this.Ptr, hObject)
    }
    
    ;##################################################################################################################
    ; Method                  GetDC
    ; Description            This function retrieves a handle to a display device context (DC) for the client area of the specified window.
    ;                        The display device context can be used in subsequent graphics display interface (GDI) functions to draw in the client area of the window. 
    ;                                                                                                                   
    ; hwnd                    Handle to the window whose device context is to be retrieved. If this value is NULL, GetDC retrieves the device context for the entire screen                    
    ;                                                                                                                   
    ; Return                The handle the device context for the specified window's client area indicates success. NULL indicates failure
    
    GetDC(hwnd=0)
    {
        Return DllCall("GetDC", this.Ptr, hwnd)
    }
    
    ;##################################################################################################################
    ; DCX_CACHE = 0x2
    ; DCX_CLIPCHILDREN = 0x8
    ; DCX_CLIPSIBLINGS = 0x10
    ; DCX_EXCLUDERGN = 0x40
    ; DCX_EXCLUDEUPDATE = 0x100
    ; DCX_INTERSECTRGN = 0x80
    ; DCX_INTERSECTUPDATE = 0x200
    ; DCX_LOCKWINDOWUPDATE = 0x400
    ; DCX_NORECOMPUTE = 0x100000
    ; DCX_NORESETATTRS = 0x4
    ; DCX_PARENTCLIP = 0x20
    ; DCX_VALIDATE = 0x200000
    ; DCX_WINDOW = 0x1
    
    GetDCEx(hwnd, flags=0, hrgnClip=0)
    {
        Return DllCall("GetDCEx", this.Ptr, hwnd, this.Ptr, hrgnClip, "int", flags)
    }
    
    ;##################################################################################################################
    ; Method                  ReleaseDC
    ; Description            This function releases a device context (DC), freeing it for use by other applications. The effect of ReleaseDC depends on the type of device context
    ;                                                                                                                   
    ; hdc                    Handle to the device context to be released
    ; hwnd                    Handle to the window whose device context is to be released
    ;                                                                                                                   
    ; Return                1 = released
    ;                        0 = not released
    ;                                                                                                                   
    ; notes                    The application must call the ReleaseDC function for each call to the GetWindowDC function and for each call to the GetDC function that retrieves a common device context
    ;                        An application cannot use the ReleaseDC function to release a device context that was created by calling the CreateDC function; instead, it must use the DeleteDC function. 
    
    ReleaseDC(hdc, hwnd=0)
    {
        Return DllCall("ReleaseDC", this.Ptr, hwnd, this.Ptr, hdc)
    }
    
    ;##################################################################################################################
    ; Method                  DeleteDC
    ; Description            The DeleteDC function deletes the specified device context (DC)
    ;                                                                                                                   
    ; hdc                    A handle to the device context
    ;                                                                                                                   
    ; Return                If the function succeeds, the Return value is nonzero
    ;                                                                                                                   
    ; notes                    An application must not delete a DC whose handle was obtained by calling the GetDC function. Instead, it must call the ReleaseDC function to free the DC
    
    DeleteDC(hdc)
    {
        Return DllCall("DeleteDC", this.Ptr, hdc)
    }
    ;##################################################################################################################
    ; Method                  Gdip_LibraryVersion
    ; Description            Get the current library version
    ;                                                                                                                   
    ; Return                the library version
    ;                                                                                                                   
    ; notes                    This is useful for non compiled programs to ensure that a person doesn't run an old version when testing your scripts
    
    Gdip_LibraryVersion()
    {
        Return 1.48
    }
    
    ;##################################################################################################################
    ; Method  :                Gdip_BitmapFromBRA
    ; Description:             Gets a pointer to a gdi+ bitmap from a BRA file
    ;                                                                                                                   
    ; BRAFromMemIn            The variable for a BRA file read to memory
    ; File                    The name of the file, or its number that you would like (This depends on alternate parameter)
    ; Alternate                Changes whether the File parameter is the file name or its number
    ;                                                                                                                   
    ; Return                  If the function succeeds, the Return value is a pointer to a gdi+ bitmap
    ;                        -1 = The BRA variable is empty
    ;                        -2 = The BRA has an incorrect header
    ;                        -3 = The BRA has information missing
    ;                        -4 = Could not find file inside the BRA
    
    Gdip_BitmapFromBRA(ByRef BRAFromMemIn, File, Alternate=0)
    {
        Static FName = "ObjRelease"
        
        if !BRAFromMemIn
            Return -1
        
        Loop, Parse, BRAFromMemIn, `n
        {
            if (A_Index = 1)
            {
                StringSplit, Header, A_LoopField, |
                if (Header0 != 4 || Header2 != "BRA!")
                    Return -2
            }
            else if (A_Index = 2)
            {
                StringSplit, Info, A_LoopField, |
                if (Info0 != 3)
                    Return -3
            }
            else
                break
        }
        
        if !Alternate
            StringReplace, File, File, \, \\, All
        
        RegExMatch(BRAFromMemIn, "mi`n)^" (Alternate ? File "\|.+?\|(\d+)\|(\d+)" : "\d+\|" File "\|(\d+)\|(\d+)") "$", FileInfo)
        if !FileInfo
            Return -4
        
        pStream := pBitmap := ""
        , hData := DllCall("GlobalAlloc", "uint", 2, this.Ptr, FileInfo2, this.Ptr)
        , pData := DllCall("GlobalLock", this.Ptr, hData, this.Ptr)
        , DllCall("RtlMoveMemory", this.Ptr, pData, this.Ptr, &BRAFromMemIn+Info2+FileInfo1, this.Ptr, FileInfo2)
        , DllCall("GlobalUnlock", this.Ptr, hData)
        , DllCall("ole32\CreateStreamOnHGlobal", this.Ptr, hData, "int", 1, this.PtrA, pStream)
        , DllCall("gdiplus\GdipCreateBitmapFromStream", this.Ptr, pStream, this.PtrA, pBitmap)
        
        If (A_PtrSize)
            %FName%(pStream)
        Else
            DllCall(NumGet(NumGet(1*pStream)+8), "uint", pStream)
        
        Return pBitmap
    }
    
    ;##################################################################################################################
    ; Method            Gdip_DrawRectangle
    ; Description       This function uses a pen to draw the outline of a rectangle into the Graphics of a bitmap
    ;                                                                                                                   
    ; pGraphics         Pointer to the Graphics of a bitmap
    ; pPen              Pointer to a pen
    ; x                 x-coordinate of the top left of the rectangle
    ; y                 y-coordinate of the top left of the rectangle
    ; w                 width of the rectanlge
    ; h                 height of the rectangle
    ;                                                                                                                   
    ; Return            status enumeration. 0 = success
    ;                                                                                                                   
    ; notes             as all coordinates are taken from the top left of each pixel, then the entire width/height should be specified as subtracting the pen width
    
    Gdip_DrawRectangle(pGraphics, pPen, x, y, w, h)
    {
        Return DllCall("gdiplus\GdipDrawRectangle", this.Ptr, pGraphics, this.Ptr, pPen, "float", x, "float", y, "float", w, "float", h)
    }
    
    ;##################################################################################################################
    ; Method                  Gdip_DrawRoundedRectangle
    ; Description            This function uses a pen to draw the outline of a rounded rectangle into the Graphics of a bitmap
    ;                                                                                                                   
    ; pGraphics                Pointer to the Graphics of a bitmap
    ; pPen                    Pointer to a pen
    ; x                        x-coordinate of the top left of the rounded rectangle
    ; y                        y-coordinate of the top left of the rounded rectangle
    ; w                        width of the rectanlge
    ; h                        height of the rectangle
    ; r                        radius of the rounded corners
    ;                                                                                                                   
    ; Return                status enumeration. 0 = success
    ;                                                                                                                   
    ; notes                    as all coordinates are taken from the top left of each pixel, then the entire width/height should be specified as subtracting the pen width
    
    Gdip_DrawRoundedRectangle(pGraphics, pPen, x, y, w, h, r)
    {
        this.Gdip_SetClipRect(pGraphics, x-r, y-r, 2*r, 2*r, 4)
        , this.Gdip_SetClipRect(pGraphics, x+w-r, y-r, 2*r, 2*r, 4)
        , this.Gdip_SetClipRect(pGraphics, x-r, y+h-r, 2*r, 2*r, 4)
        , this.Gdip_SetClipRect(pGraphics, x+w-r, y+h-r, 2*r, 2*r, 4)
        , E := this.Gdip_DrawRectangle(pGraphics, pPen, x, y, w, h)
        , this.Gdip_ResetClip(pGraphics)
        , this.Gdip_SetClipRect(pGraphics, x-(2*r), y+r, w+(4*r), h-(2*r), 4)
        , this.Gdip_SetClipRect(pGraphics, x+r, y-(2*r), w-(2*r), h+(4*r), 4)
        , this.Gdip_DrawEllipse(pGraphics, pPen, x, y, 2*r, 2*r)
        , this.Gdip_DrawEllipse(pGraphics, pPen, x+w-(2*r), y, 2*r, 2*r)
        , this.Gdip_DrawEllipse(pGraphics, pPen, x, y+h-(2*r), 2*r, 2*r)
        , this.Gdip_DrawEllipse(pGraphics, pPen, x+w-(2*r), y+h-(2*r), 2*r, 2*r)
        , this.Gdip_ResetClip(pGraphics)
        
        Return E
    }
    
    ;##################################################################################################################
    ; Method                  Gdip_DrawEllipse
    ; Description            This function uses a pen to draw the outline of an ellipse into the Graphics of a bitmap
    ;                                                                                                                   
    ; pGraphics                Pointer to the Graphics of a bitmap
    ; pPen                    Pointer to a pen
    ; x                        x-coordinate of the top left of the rectangle the ellipse will be drawn into
    ; y                        y-coordinate of the top left of the rectangle the ellipse will be drawn into
    ; w                        width of the ellipse
    ; h                        height of the ellipse
    ;                                                                                                                   
    ; Return                status enumeration. 0 = success
    ;                                                                                                                   
    ; notes                    as all coordinates are taken from the top left of each pixel, then the entire width/height should be specified as subtracting the pen width
    
    Gdip_DrawEllipse(pGraphics, pPen, x, y, w, h)
    {
        Return DllCall("gdiplus\GdipDrawEllipse", this.Ptr, pGraphics, this.Ptr, pPen, "float", x, "float", y, "float", w, "float", h)
    }
    
    ;##################################################################################################################
    ; Method                  Gdip_DrawBezier
    ; Description            This function uses a pen to draw the outline of a bezier (a weighted curve) into the Graphics of a bitmap
    ;                                                                                                                   
    ; pGraphics                Pointer to the Graphics of a bitmap
    ; pPen                    Pointer to a pen
    ; x1                    x-coordinate of the start of the bezier
    ; y1                    y-coordinate of the start of the bezier
    ; x2                    x-coordinate of the first arc of the bezier
    ; y2                    y-coordinate of the first arc of the bezier
    ; x3                    x-coordinate of the second arc of the bezier
    ; y3                    y-coordinate of the second arc of the bezier
    ; x4                    x-coordinate of the end of the bezier
    ; y4                    y-coordinate of the end of the bezier
    ;                                                                                                                   
    ; Return                status enumeration. 0 = success
    ;                                                                                                                   
    ; notes                    as all coordinates are taken from the top left of each pixel, then the entire width/height should be specified as subtracting the pen width
    
    Gdip_DrawBezier(pGraphics, pPen, x1, y1, x2, y2, x3, y3, x4, y4)
    {
        Return DllCall("gdiplus\GdipDrawBezier"
                        , this.Ptr  , pgraphics
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
    
    ;##################################################################################################################
    ; Method            Gdip_DrawArc
    ; Description       This function uses a pen to draw the outline of an arc into the Graphics of a bitmap
    ;                                                                                                                   
    ; pGraphics         Pointer to the Graphics of a bitmap
    ; pPen              Pointer to a pen
    ; x                 x-coordinate of the start of the arc
    ; y                 y-coordinate of the start of the arc
    ; w                 width of the arc
    ; h                 height of the arc
    ; StartAngle        specifies the angle between the x-axis and the starting point of the arc
    ; SweepAngle        specifies the angle between the starting and ending points of the arc
    ;                                                                                                                   
    ; Return            status enumeration. 0 = success
    ;                                                                                                                   
    ; notes             as all coordinates are taken from the top left of each pixel, then the entire width/height should be specified as subtracting the pen width
    
    Gdip_DrawArc(pGraphics, pPen, x, y, w, h, StartAngle, SweepAngle)
    {
        Return DllCall("gdiplus\GdipDrawArc"
                        , this.Ptr  , pGraphics
                        , this.Ptr  , pPen
                        , "float"   , x
                        , "float"   , y
                        , "float"   , w
                        , "float"   , h
                        , "float"   , StartAngle
                        , "float"   , SweepAngle)
    }
    
    ;##################################################################################################################
    ; Method                  Gdip_DrawPie
    ; Description            This function uses a pen to draw the outline of a pie into the Graphics of a bitmap
    ;                                                                                                                   
    ; pGraphics                Pointer to the Graphics of a bitmap
    ; pPen                    Pointer to a pen
    ; x                        x-coordinate of the start of the pie
    ; y                        y-coordinate of the start of the pie
    ; w                        width of the pie
    ; h                        height of the pie
    ; StartAngle            specifies the angle between the x-axis and the starting point of the pie
    ; SweepAngle            specifies the angle between the starting and ending points of the pie
    ;                                                                                                                   
    ; Return                status enumeration. 0 = success
    ;                                                                                                                   
    ; notes                    as all coordinates are taken from the top left of each pixel, then the entire width/height should be specified as subtracting the pen width
    
    Gdip_DrawPie(pGraphics, pPen, x, y, w, h, StartAngle, SweepAngle)
    {
        Return DllCall("gdiplus\GdipDrawPie", this.Ptr, pGraphics, this.Ptr, pPen, "float", x, "float", y, "float", w, "float", h, "float", StartAngle, "float", SweepAngle)
    }
    
    ;##################################################################################################################
    ; Method                  Gdip_DrawLine
    ; Description            This function uses a pen to draw a line into the Graphics of a bitmap
    ;                                                                                                                   
    ; pGraphics                Pointer to the Graphics of a bitmap
    ; pPen                    Pointer to a pen
    ; x1                    x-coordinate of the start of the line
    ; y1                    y-coordinate of the start of the line
    ; x2                    x-coordinate of the end of the line
    ; y2                    y-coordinate of the end of the line
    ;                                                                                                                   
    ; Return                status enumeration. 0 = success        
    
    Gdip_DrawLine(pGraphics, pPen, x1, y1, x2, y2)
    {
        Return DllCall("gdiplus\GdipDrawLine"
                        , this.Ptr  , pGraphics
                        , this.Ptr  , pPen
                        , "float"   , x1
                        , "float"   , y1
                        , "float"   , x2
                        , "float"   , y2)
    }
    
    ;##################################################################################################################
    ; Method                  Gdip_DrawLines
    ; Description            This function uses a pen to draw a series of joined lines into the Graphics of a bitmap
    ;                                                                                                                   
    ; pGraphics                Pointer to the Graphics of a bitmap
    ; pPen                    Pointer to a pen
    ; Points                the coordinates of all the points passed as x1,y1|x2,y2|x3,y3.....
    ;                                                                                                                   
    ; Return                status enumeration. 0 = success                
    
    Gdip_DrawLines(pGraphics, pPen, Points)
    {
        StringSplit, Points, Points, |
        VarSetCapacity(PointF, 8*Points0)   
        Loop, %Points0%
        {
            StringSplit, Coord, Points%A_Index%, `,
            NumPut(Coord1, PointF, 8*(A_Index-1), "float")
            , NumPut(Coord2, PointF, (8*(A_Index-1))+4, "float")
        }
        Return DllCall("gdiplus\GdipDrawLines", this.Ptr, pGraphics, this.Ptr, pPen, this.Ptr, &PointF, "int", Points0)
    }
    
    ;##################################################################################################################
    ; Method                  Gdip_FillRectangle
    ; Description            This function uses a brush to fill a rectangle in the Graphics of a bitmap
    ;                                                                                                                   
    ; pGraphics                Pointer to the Graphics of a bitmap
    ; pBrush                Pointer to a brush
    ; x                        x-coordinate of the top left of the rectangle
    ; y                        y-coordinate of the top left of the rectangle
    ; w                        width of the rectanlge
    ; h                        height of the rectangle
    ;                                                                                                                   
    ; Return                status enumeration. 0 = success
    
    Gdip_FillRectangle(pGraphics, pBrush, x, y, w, h)
    {
        Return DllCall("gdiplus\GdipFillRectangle"
                        , this.Ptr  , pGraphics
                        , this.Ptr  , pBrush
                        , "float"   , x
                        , "float"   , y
                        , "float"   , w
                        , "float"   , h)
    }
    
    ;##################################################################################################################
    ; Method            Gdip_FillRoundedRectangle
    ; Description       This function uses a brush to fill a rounded rectangle in the Graphics of a bitmap
    ;                                                                                                                   
    ; pGraphics         Pointer to the Graphics of a bitmap
    ; pBrush            Pointer to a brush
    ; x                 x-coordinate of the top left of the rounded rectangle
    ; y                 y-coordinate of the top left of the rounded rectangle
    ; w                 width of the rectanlge
    ; h                 height of the rectangle
    ; r                 radius of the rounded corners
    ;                                                                                                                   
    ; Return            status enumeration. 0 = success
    
    Gdip_FillRoundedRectangle(pGraphics, pBrush, x, y, w, h, r)
    {
        Region := this.Gdip_GetClipRegion(pGraphics)
        , this.Gdip_SetClipRect(pGraphics, x-r, y-r, 2*r, 2*r, 4)
        , this.Gdip_SetClipRect(pGraphics, x+w-r, y-r, 2*r, 2*r, 4)
        , this.Gdip_SetClipRect(pGraphics, x-r, y+h-r, 2*r, 2*r, 4)
        , this.Gdip_SetClipRect(pGraphics, x+w-r, y+h-r, 2*r, 2*r, 4)
        , E := this.Gdip_FillRectangle(pGraphics, pBrush, x, y, w, h)
        , this.Gdip_SetClipRegion(pGraphics, Region, 0)
        , this.Gdip_SetClipRect(pGraphics, x-(2*r), y+r, w+(4*r), h-(2*r), 4)
        , this.Gdip_SetClipRect(pGraphics, x+r, y-(2*r), w-(2*r), h+(4*r), 4)
        , this.Gdip_FillEllipse(pGraphics, pBrush, x, y, 2*r, 2*r)
        , this.Gdip_FillEllipse(pGraphics, pBrush, x+w-(2*r), y, 2*r, 2*r)
        , this.Gdip_FillEllipse(pGraphics, pBrush, x, y+h-(2*r), 2*r, 2*r)
        , this.Gdip_FillEllipse(pGraphics, pBrush, x+w-(2*r), y+h-(2*r), 2*r, 2*r)
        , this.Gdip_SetClipRegion(pGraphics, Region, 0)
        , this.Gdip_DeleteRegion(Region)
        
        Return E
    }
    
    ;##################################################################################################################
    ; Method            Gdip_FillPolygon
    ; Description       This function uses a brush to fill a polygon in the Graphics of a bitmap
    ;                                                                                                                   
    ; pGraphics         Pointer to the Graphics of a bitmap
    ; pBrush            Pointer to a brush
    ; Points            the coordinates of all the points passed as x1,y1|x2,y2|x3,y3.....
    ;                                                                                                                   
    ; Return            status enumeration. 0 = success
    ;                                                                                                                   
    ; notes             Alternate will fill the polygon as a whole, wheras winding will fill each new "segment"
    ; Alternate         = 0
    ; Winding           = 1
    
    Gdip_FillPolygon(pGraphics, pBrush, points, FillMode=0)
    {
        points_arr := IsObject(points) ? points : StrSplit(points, "|")
        VarSetCapacity(pointF, 8*points_arr.MaxIndex())
        For index, coords in points_arr
            IsObject(coords)
                ? ""
                : coords := StrSplit(coords, ",", " ")
            , NumPut(coords[1], pointF, 8*(A_Index-1), "float")
            , NumPut(coords[2], pointF, (8*(A_Index-1))+4, "float")
        
        Return DllCall("gdiplus\GdipFillPolygon"
                        , this.Ptr  , pGraphics
                        , this.Ptr  , pBrush
                        , this.Ptr  , &pointF
                        , "int"     , points_arr.MaxIndex()
                        , "int"     , FillMode)
    }
    
    ;###############################################################################################################################################
    ; Method            Gdip_DrawPolygon
    ; Description       This function uses a pen to draw a polygon in the Graphics of a bitmap
    ;                                                                                                                   
    ; pGraphics         Pointer to the Graphics of a bitmap
    ; pBrush            Pointer to a brush
    ; Points            List of coordinates can be passed by 2D array or by string
    ;                   Coord sets must be pairs of numbers separated by commas (string spaces are omitted and can be used freely)
    ;                   Examples of acceptable point sets:
    ;                       array1  = [[30,53], [-30,53], [-30,0], [30,0]]
    ;                       array2  = ["30,53", "-30,53", "-30,0", "30,0"]
    ;                       string  = 30, 53|-30,53|   -30,   0|30 , 0
    ;                                                                                                                   
    ; Return            status enumeration. 0 = success
    
    Gdip_DrawPolygon(gp, pPen, points)
    {
        points_arr := IsObject(points) ? points : StrSplit(points, "|")
        VarSetCapacity(pointF, 8*points_arr.MaxIndex())
        For index, coords in points_arr
            IsObject(coords)
                ? ""
                : coords := StrSplit(coords, ",", " ")
            , NumPut(coords[1], pointF, 8*(A_Index-1)       , "float")
            , NumPut(coords[2], pointF, (8*(A_Index-1))+4   , "float")
        
        Return DllCall("gdiplus\GdipDrawPolygon"
                        , this.Ptr  , gp
                        , this.Ptr  , pPen
                        , this.Ptr  , &PointF
                        , "int"     , points_arr.MaxIndex())
    }
    
    ;##################################################################################################################
    ; Method                  Gdip_FillPie
    ; Description            This function uses a brush to fill a pie in the Graphics of a bitmap
    ;                                                                                                                   
    ; pGraphics                Pointer to the Graphics of a bitmap
    ; pBrush                Pointer to a brush
    ; x                        x-coordinate of the top left of the pie
    ; y                        y-coordinate of the top left of the pie
    ; w                        width of the pie
    ; h                        height of the pie
    ; StartAngle            specifies the angle between the x-axis and the starting point of the pie
    ; SweepAngle            specifies the angle between the starting and ending points of the pie
    ;                                                                                                                   
    ; Return                status enumeration. 0 = success
    
    Gdip_FillPie(pGraphics, pBrush, x, y, w, h, StartAngle, SweepAngle)
    {
        Return DllCall("gdiplus\GdipFillPie"
                        , this.Ptr  , pGraphics
                        , this.Ptr  , pBrush
                        , "float"   , x
                        , "float"   , y
                        , "float"   , w
                        , "float"   , h
                        , "float"   , StartAngle
                        , "float"   , SweepAngle)
    }
    
    ;##################################################################################################################
    ; Method                  Gdip_FillEllipse
    ; Description            This function uses a brush to fill an ellipse in the Graphics of a bitmap
    ;                                                                                                                   
    ; pGraphics                Pointer to the Graphics of a bitmap
    ; pBrush                Pointer to a brush
    ; x                        x-coordinate of the top left of the ellipse
    ; y                        y-coordinate of the top left of the ellipse
    ; w                        width of the ellipse
    ; h                        height of the ellipse
    ;                                                                                                                   
    ; Return                status enumeration. 0 = success
    
    Gdip_FillEllipse(pGraphics, pBrush, x, y, w, h)
    {
        Return DllCall("gdiplus\GdipFillEllipse", this.Ptr, pGraphics, this.Ptr, pBrush, "float", x, "float", y, "float", w, "float", h)
    }
    
    ;##################################################################################################################
    ; Method                  Gdip_FillRegion
    ; Description            This function uses a brush to fill a region in the Graphics of a bitmap
    ;                                                                                                                   
    ; pGraphics                Pointer to the Graphics of a bitmap
    ; pBrush                Pointer to a brush
    ; Region                Pointer to a Region
    ;                                                                                                                   
    ; Return                status enumeration. 0 = success
    ;                                                                                                                   
    ; notes                    You can create a region Gdip_CreateRegion() and then add to this
    
    Gdip_FillRegion(pGraphics, pBrush, Region)
    {
        Return DllCall("gdiplus\GdipFillRegion", this.Ptr, pGraphics, this.Ptr, pBrush, this.Ptr, Region)
    }
    
    ;##################################################################################################################
    ; Method                  Gdip_FillPath
    ; Description            This function uses a brush to fill a path in the Graphics of a bitmap
    ;                                                                                                                   
    ; pGraphics                Pointer to the Graphics of a bitmap
    ; pBrush                Pointer to a brush
    ; Region                Pointer to a Path
    ;                                                                                                                   
    ; Return                status enumeration. 0 = success
    
    Gdip_FillPath(pGraphics, pBrush, Path)
    {
        Return DllCall("gdiplus\GdipFillPath", this.Ptr, pGraphics, this.Ptr, pBrush, this.Ptr, Path)
    }
    
    ;##################################################################################################################
    ; Method            Gdip_DrawImagePointsRect
    ; Description       This function draws a bitmap into the Graphics of another bitmap and skews it
    ;                                                                                                                   
    ; pGraphics         Pointer to the Graphics of a bitmap
    ; pBitmap           Pointer to a bitmap to be drawn
    ; Points            Points passed as x1,y1|x2,y2|x3,y3 (3 points: top left, top right, bottom left) describing the drawing of the bitmap
    ; sx                x-coordinate of source upper-left corner
    ; sy                y-coordinate of source upper-left corner
    ; sw                width of source rectangle
    ; sh                height of source rectangle
    ; Matrix            a matrix used to alter image attributes when drawing
    ;                                                                                                                   
    ; Return            status enumeration. 0 = success
    ;                                                                                                                   
    ; notes             if sx,sy,sw,sh are missed then the entire source bitmap will be used
    ;                   Matrix can be omitted to just draw with no alteration to ARGB
    ;                   Matrix may be passed as a digit from 0 - 1 to change just transparency
    ;                   Matrix can be passed as a matrix with any delimiter
    
    Gdip_DrawImagePointsRect(pGraphics, pBitmap, Points, sx="", sy="", sw="", sh="", Matrix=1)
    {
        StringSplit, Points, Points, |
        VarSetCapacity(PointF, 8*Points0)   
        Loop, %Points0%
        {
            StringSplit, Coord, Points%A_Index%, `,
            NumPut(Coord1, PointF, 8*(A_Index-1), "float"), NumPut(Coord2, PointF, (8*(A_Index-1))+4, "float")
        }
        
        if (Matrix&1 = "")
            ImageAttr := this.Gdip_SetImageAttributesColorMatrix(Matrix)
        else if (Matrix != 1)
            ImageAttr := this.Gdip_SetImageAttributesColorMatrix("1|0|0|0|0|0|1|0|0|0|0|0|1|0|0|0|0|0|" Matrix "|0|0|0|0|0|1")
        
        if (sx = "" && sy = "" && sw = "" && sh = "")
        {
            sx := 0, sy := 0
            sw := this.Gdip_GetImageWidth(pBitmap)
            sh := this.Gdip_GetImageHeight(pBitmap)
        }
        
        E := DllCall("gdiplus\GdipDrawImagePointsRect"
                    , this.Ptr  , pGraphics
                    , this.Ptr  , pBitmap
                    , this.Ptr  , &PointF
                    , "int"     , Points0
                    , "float"   , sx
                    , "float"   , sy
                    , "float"   , sw
                    , "float"   , sh
                    , "int"     , 2
                    , this.Ptr  , ImageAttr
                    , this.Ptr  , 0
                    , this.Ptr  , 0)
        
        if ImageAttr
            this.Gdip_DisposeImageAttributes(ImageAttr)
        
        Return E
    }
    
    ;##################################################################################################################
    ; Method            Gdip_DrawImage
    ; Description       This function draws a bitmap into the Graphics of another bitmap
    ;                                                                                                                   
    ; pGraphics         Pointer to the Graphics of a bitmap
    ; pBitmap           Pointer to a bitmap to be drawn
    ; dx                x-coord of destination upper-left corner
    ; dy                y-coord of destination upper-left corner
    ; dw                width of destination image
    ; dh                height of destination image
    ; sx                x-coordinate of source upper-left corner
    ; sy                y-coordinate of source upper-left corner
    ; sw                width of source image
    ; sh                height of source image
    ; Matrix            a matrix used to alter image attributes when drawing
    ;                                                                                                                   
    ; Return            status enumeration. 0 = success
    ;                                                                                                                   
    ; notes             if sx,sy,sw,sh are missed then the entire source bitmap will be used
    ;                   Gdip_DrawImage performs faster
    ;                   Matrix can be omitted to just draw with no alteration to ARGB
    ;                   Matrix may be passed as a digit from 0 - 1 to change just transparency
    ;                   Matrix can be passed as a matrix with any delimiter. For example:
    ;                   MatrixBright=
    ;                   (
    ;                      1.5    |0      |0      |0      |0
    ;                      0      |1.5    |0      |0      |0
    ;                      0      |0      |1.5    |0      |0
    ;                      0      |0      |0      |1      |0
    ;                      0.05   |0.05   |0.05   |0      |1
    ;                   )
    ;                                                                                                                   
    ; notes             MatrixBright = 1.5|0|0|0|0|0|1.5|0|0|0|0|0|1.5|0|0|0|0|0|1|0|0.05|0.05|0.05|0|1
    ;                   MatrixGreyScale = 0.299|0.299|0.299|0|0|0.587|0.587|0.587|0|0|0.114|0.114|0.114|0|0|0|0|0|1|0|0|0|0|0|1
    ;                   MatrixNegative = -1|0|0|0|0|0|-1|0|0|0|0|0|-1|0|0|0|0|0|1|0|0|0|0|0|1
    
    Gdip_DrawImage(pGraphics, pBitmap, dx="", dy="", dw="", dh="", sx="", sy="", sw="", sh="", Matrix=1)
    {
        ImageAttr := (Matrix&1 = "") ? this.Gdip_SetImageAttributesColorMatrix(Matrix)
                : (Matrix != 1) ? this.Gdip_SetImageAttributesColorMatrix("1|0|0|0|0|0|1|0|0|0|0|0|1|0|0|0|0|0|" Matrix "|0|0|0|0|0|1")
                : ""
        
        if (sx = "" && sy = "" && sw = "" && sh = "")
        {
            if (dx = "" && dy = "" && dw = "" && dh = "")
            {
                sx := dx := 0, sy := dy := 0
                sw := dw := this.Gdip_GetImageWidth(pBitmap)
                sh := dh := this.Gdip_GetImageHeight(pBitmap)
            }
            else
            {
                sx := sy := 0
                sw := this.Gdip_GetImageWidth(pBitmap)
                sh := this.Gdip_GetImageHeight(pBitmap)
            }
        }
        
        E := DllCall("gdiplus\GdipDrawImageRectRect"
                    , this.Ptr  , pGraphics
                    , this.Ptr  , pBitmap
                    , "float"   , dx
                    , "float"   , dy
                    , "float"   , dw
                    , "float"   , dh
                    , "float"   , sx
                    , "float"   , sy
                    , "float"   , sw
                    , "float"   , sh
                    , "int"     , 2
                    , this.Ptr  , ImageAttr
                    , this.Ptr  , 0
                    , this.Ptr  , 0)
        
        if ImageAttr
            this.Gdip_DisposeImageAttributes(ImageAttr)
        
        Return E
    }
    
    ;##################################################################################################################
    ; Method                  Gdip_SetImageAttributesColorMatrix
    ; Description            This function creates an image matrix ready for drawing
    ;                                                                                                                   
    ; Matrix                a matrix used to alter image attributes when drawing
    ;                        passed with any delimeter
    ;                                                                                                                   
    ; Return                Returns an image matrix on sucess or 0 if it fails
    ;                                                                                                                   
    ; notes                    MatrixBright = 1.5|0|0|0|0|0|1.5|0|0|0|0|0|1.5|0|0|0|0|0|1|0|0.05|0.05|0.05|0|1
    ;                        MatrixGreyScale = 0.299|0.299|0.299|0|0|0.587|0.587|0.587|0|0|0.114|0.114|0.114|0|0|0|0|0|1|0|0|0|0|0|1
    ;                        MatrixNegative = -1|0|0|0|0|0|-1|0|0|0|0|0|-1|0|0|0|0|0|1|0|0|0|0|0|1
    
    Gdip_SetImageAttributesColorMatrix(Matrix)
    {
        VarSetCapacity(ColourMatrix, 100, 0)
        ImageAttr   := ""
        Matrix      := RegExReplace(RegExReplace(Matrix, "^[^\d-\.]+([\d\.])", "$1", "", 1), "[^\d-\.]+", "|")
        StringSplit, Matrix, Matrix, |
        Loop, 25
        {
            Matrix := (Matrix%A_Index% != "")
                ? Matrix%A_Index%
                : Mod(A_Index-1, 6) ? 0 : 1
            , NumPut(Matrix, ColourMatrix, (A_Index-1)*4, "float")
        }
        
        DllCall("gdiplus\GdipCreateImageAttributes", this.PtrA, ImageAttr)
        , DllCall("gdiplus\GdipSetImageAttributesColorMatrix", this.Ptr, ImageAttr, "int", 1, "int", 1, this.Ptr, &ColourMatrix, this.Ptr, 0, "int", 0)
        Return ImageAttr
    }
    
    ;##################################################################################################################
    ; Method                  Gdip_GraphicsFromImage
    ; Description            This function gets the graphics for a bitmap used for drawing functions
    ;                                                                                                                   
    ; pBitmap                Pointer to a bitmap to get the pointer to its graphics
    ;                                                                                                                   
    ; Return                Returns a pointer to the graphics of a bitmap
    ;                                                                                                                   
    ; notes                    a bitmap can be drawn into the graphics of another bitmap
    
    Gdip_GraphicsFromImage(pBitmap)
    {
        DllCall("gdiplus\GdipGetImageGraphicsContext", this.Ptr, pBitmap, this.PtrA, (pGraphics:=""))
        Return pGraphics
    }
    
    ;##################################################################################################################
    ; Method                  Gdip_GraphicsFromHDC
    ; Description            This function gets the graphics from the handle to a device context
    ;                                                                                                                   
    ; hdc                    This is the handle to the device context
    ;                                                                                                                   
    ; Return                Returns a pointer to the graphics of a bitmap
    ;                                                                                                                   
    ; notes                    You can draw a bitmap into the graphics of another bitmap
    
    Gdip_GraphicsFromHDC(hdc)
    {
        DllCall("gdiplus\GdipCreateFromHDC", this.Ptr, hdc, this.PtrA, (pGraphics:=""))
        Return pGraphics
    }
    
    ;##################################################################################################################
    ; Method                  Gdip_GetDC
    ; Description            This function gets the device context of the passed Graphics
    ;                                                                                                                   
    ; hdc                    This is the handle to the device context
    ;                                                                                                                   
    ; Return                Returns the device context for the graphics of a bitmap
    
    Gdip_GetDC(pGraphics)
    {
        DllCall("gdiplus\GdipGetDC", this.Ptr, pGraphics, this.PtrA, (hdc:=""))
        Return hdc
    }
    
    ;##################################################################################################################
    ; Method                  Gdip_ReleaseDC
    ; Description            This function releases a device context from use for further use
    ;                                                                                                                   
    ; pGraphics                Pointer to the graphics of a bitmap
    ; hdc                    This is the handle to the device context
    ;                                                                                                                   
    ; Return                status enumeration. 0 = success
    
    Gdip_ReleaseDC(pGraphics, hdc)
    {
        Return DllCall("gdiplus\GdipReleaseDC", this.Ptr, pGraphics, this.Ptr, hdc)
    }
    
    ;##################################################################################################################
    ; Method                  Gdip_GraphicsClear
    ; Description            Clears the graphics of a bitmap ready for further drawing
    ;                                                                                                                   
    ; pGraphics                Pointer to the graphics of a bitmap
    ; ARGB                    The colour to clear the graphics to
    ;                                                                                                                   
    ; Return                status enumeration. 0 = success
    ;                                                                                                                   
    ; notes                    By default this will make the background invisible
    ;                        Using clipping regions you can clear a particular area on the graphics rather than clearing the entire graphics
    
    Gdip_GraphicsClear(pGraphics, ARGB=0x00ffffff)
    {
        Return DllCall("gdiplus\GdipGraphicsClear", this.Ptr, pGraphics, "int", ARGB)
    }
    
    ;##################################################################################################################
    ; Method                  Gdip_BlurBitmap
    ; Description            Gives a pointer to a blurred bitmap from a pointer to a bitmap
    ;                                                                                                                   
    ; pBitmap                Pointer to a bitmap to be blurred
    ; Blur                    The Amount to blur a bitmap by from 1 (least blur) to 100 (most blur)
    ;                                                                                                                   
    ; Return                If the function succeeds, the Return value is a pointer to the new blurred bitmap
    ;                        -1 = The blur parameter is outside the range 1-100
    ;                                                                                                                   
    ; notes                    This function will not dispose of the original bitmap
    
    Gdip_BlurBitmap(pBitmap, Blur)
    {
        if (Blur > 100) || (Blur < 1)
            Return -1    
        
        sWidth      := this.Gdip_GetImageWidth(pBitmap)
        , sHeight   := this.Gdip_GetImageHeight(pBitmap)
        , dWidth    := sWidth//Blur
        , dHeight   := sHeight//Blur
        , pBitmap1  := this.Gdip_CreateBitmap(dWidth, dHeight)
        , G1        := this.Gdip_GraphicsFromImage(pBitmap1)
        , this.Gdip_SetInterpolationMode(G1, 7)
        , this.Gdip_DrawImage(G1, pBitmap, 0, 0, dWidth, dHeight, 0, 0, sWidth, sHeight)
        , this.Gdip_DeleteGraphics(G1)
        , pBitmap2  := this.Gdip_CreateBitmap(sWidth, sHeight)
        , G2        := this.Gdip_GraphicsFromImage(pBitmap2)
        , this.Gdip_SetInterpolationMode(G2, 7)
        , this.Gdip_DrawImage(G2, pBitmap1, 0, 0, sWidth, sHeight, 0, 0, dWidth, dHeight)
        , this.Gdip_DeleteGraphics(G2)
        , this.Gdip_DisposeImage(pBitmap1)
        
        Return pBitmap2
    }
    
    ;##################################################################################################################
    ; Method            Gdip_SaveBitmapToFile
    ; Description       Saves a bitmap to a file in any supported format onto disk
    ;                                                                                                                   
    ; pBitmap           Pointer to a bitmap
    ; sOutput           The name of the file that the bitmap will be saved to. Supported extensions are: .BMP,.DIB,.RLE,.JPG,.JPEG,.JPE,.JFIF,.GIF,.TIF,.TIFF,.PNG
    ; Quality           If saving as jpg (.JPG,.JPEG,.JPE,.JFIF) then quality can be 1-100 with default at maximum quality
    ;                                                                                                                   
    ; Return            If the function succeeds, the Return value is zero, otherwise:
    ;                   -1 = Extension supplied is not a supported file format
    ;                   -2 = Could not get a list of encoders on system
    ;                   -3 = Could not find matching encoder for specified file format
    ;                   -4 = Could not get WideChar name of output file
    ;                   -5 = Could not save file to disk
    ;                                                                                                                   
    ; notes             This function will use the extension supplied from the sOutput parameter to determine the output format
    
    Gdip_SaveBitmapToFile(pBitmap, sOutput, Quality=75)
    {
        SplitPath, sOutput,,, Extension
        if Extension not in BMP,DIB,RLE,JPG,JPEG,JPE,JFIF,GIF,TIF,TIFF,PNG
            Return -1
        
        Extension   := "." Extension
        , nCount    := nSize := p := ""
        , DllCall("gdiplus\GdipGetImageEncodersSize", "uint*", nCount, "uint*", nSize)
        , VarSetCapacity(ci, nSize)
        , DllCall("gdiplus\GdipGetImageEncoders", "uint", nCount, "uint", nSize, this.Ptr, &ci)
        
        if !(nCount && nSize)
            Return -2
        
        If (A_IsUnicode)
        {
            StrGet_Name := "StrGet"
            Loop, %nCount%
            {
                sString := %StrGet_Name%(NumGet(ci, (idx := (48+7*A_PtrSize)*(A_Index-1))+32+3*A_PtrSize), "UTF-16")
                if !InStr(sString, "*" Extension)
                    continue
                
                pCodec := &ci+idx
                break
            }
        }
        else
        {
            Loop, %nCount%
            {
                Location := NumGet(ci, 76*(A_Index-1)+44)
                nSize := DllCall("WideCharToMultiByte", "uint", 0, "uint", 0, "uint", Location, "int", -1, "uint", 0, "int",  0, "uint", 0, "uint", 0)
                VarSetCapacity(sString, nSize)
                DllCall("WideCharToMultiByte", "uint", 0, "uint", 0, "uint", Location, "int", -1, "str", sString, "int", nSize, "uint", 0, "uint", 0)
                if !InStr(sString, "*" Extension)
                    Continue
                
                pCodec := &ci+76*(A_Index-1)
                break
            }
        }
        
        if !pCodec
            Return -3
        
        if (Quality != 75)
        {
            Quality := (Quality < 0)
                ? 0 
                : (Quality > 100)
                    ? 100
                    : Quality
            
            if Extension in .JPG,.JPEG,.JPE,.JFIF
            {
                DllCall("gdiplus\GdipGetEncoderParameterListSize", this.Ptr, pBitmap, this.Ptr, pCodec, "uint*", nSize)
                VarSetCapacity(EncoderParameters, nSize, 0)
                DllCall("gdiplus\GdipGetEncoderParameterList", this.Ptr, pBitmap, this.Ptr, pCodec, "uint", nSize, this.Ptr, &EncoderParameters)
                Loop, % NumGet(EncoderParameters, "UInt")      ;%
                {
                    elem := (24+(A_PtrSize ? A_PtrSize : 4))*(A_Index-1) + 4 + (pad := A_PtrSize = 8 ? 4 : 0)
                    if (NumGet(EncoderParameters, elem+16, "UInt") = 1) && (NumGet(EncoderParameters, elem+20, "UInt") = 6)
                    {
                        p := elem+&EncoderParameters-pad-4
                        NumPut(Quality, NumGet(NumPut(4, NumPut(1, p+0)+20, "UInt")), "UInt")
                        Break
                    }
                }      
            }
        }
        
        if (!A_IsUnicode)
        {
            nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, this.Ptr, &sOutput, "int", -1, this.Ptr, 0, "int", 0)
            VarSetCapacity(wOutput, nSize*2)
            DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, this.Ptr, &sOutput, "int", -1, this.Ptr, &wOutput, "int", nSize)
            VarSetCapacity(wOutput, -1)
            if !VarSetCapacity(wOutput)
                Return -4
            E := DllCall("gdiplus\GdipSaveImageToFile", this.Ptr, pBitmap, this.Ptr, &wOutput, this.Ptr, pCodec, "uint", p ? p : 0)
        }
        else
            E := DllCall("gdiplus\GdipSaveImageToFile", this.Ptr, pBitmap, this.Ptr, &sOutput, this.Ptr, pCodec, "uint", p ? p : 0)
        
        Return E ? -5 : 0
    }
    
    ;##################################################################################################################
    ; Method                  Gdip_GetPixel
    ; Description            Gets the ARGB of a pixel in a bitmap
    ;                                                                                                                   
    ; pBitmap                Pointer to a bitmap
    ; x                        x-coordinate of the pixel
    ; y                        y-coordinate of the pixel
    ;                                                                                                                   
    ; Return                Returns the ARGB value of the pixel
    
    Gdip_GetPixel(pBitmap, x, y)
    {
        DllCall("gdiplus\GdipBitmapGetPixel", this.Ptr, pBitmap, "int", x, "int", y, "uint*", (ARGB:=""))
        Return ARGB
    }
    
    ;##################################################################################################################
    ; Method                  Gdip_SetPixel
    ; Description            Sets the ARGB of a pixel in a bitmap
    ;                                                                                                                   
    ; pBitmap                Pointer to a bitmap
    ; x                        x-coordinate of the pixel
    ; y                        y-coordinate of the pixel
    ;                                                                                                                   
    ; Return                status enumeration. 0 = success
    
    Gdip_SetPixel(pBitmap, x, y, ARGB)
    {
        Return DllCall("gdiplus\GdipBitmapSetPixel", this.Ptr, pBitmap, "int", x, "int", y, "int", ARGB)
    }
    
    ;##################################################################################################################
    ; Method                  Gdip_GetImageWidth
    ; Description            Gives the width of a bitmap
    ;                                                                                                                   
    ; pBitmap                Pointer to a bitmap
    ;                                                                                                                   
    ; Return                Returns the width in pixels of the supplied bitmap
    
    Gdip_GetImageWidth(pBitmap)
    {
        DllCall("gdiplus\GdipGetImageWidth", this.Ptr, pBitmap, "uint*", (Width:=""))
        Return Width
    }
    
    ;##################################################################################################################
    ; Method                  Gdip_GetImageHeight
    ; Description            Gives the height of a bitmap
    ;                                                                                                                   
    ; pBitmap                Pointer to a bitmap
    ;                                                                                                                   
    ; Return                Returns the height in pixels of the supplied bitmap
    
    Gdip_GetImageHeight(pBitmap)
    {
        DllCall("gdiplus\GdipGetImageHeight", this.Ptr, pBitmap, "uint*", (Height:=""))
        Return Height
    }
    
    ;##################################################################################################################
    ; Method                Gdip_GetDimensions
    ; Description            Gives the width and height of a bitmap
    ;                                                                                                                   
    ; pBitmap                Pointer to a bitmap
    ; Width                    ByRef variable. This variable will be set to the width of the bitmap
    ; Height                ByRef variable. This variable will be set to the height of the bitmap
    ;                                                                                                                   
    ; Return                No Return value
    ;                        Gdip_GetDimensions(pBitmap, ThisWidth, ThisHeight) will set ThisWidth to the width and ThisHeight to the height
    
    Gdip_GetImageDimensions(pBitmap, ByRef Width, ByRef Height)
    {
        DllCall("gdiplus\GdipGetImageWidth", this.Ptr, pBitmap, "uint*", Width)
        ,DllCall("gdiplus\GdipGetImageHeight", this.Ptr, pBitmap, "uint*", Height)
    }
    
    ;##################################################################################################################
    Gdip_GetDimensions(pBitmap, ByRef Width, ByRef Height)
    {
        this.Gdip_GetImageDimensions(pBitmap, Width, Height)
    }
    
    ;##################################################################################################################
    Gdip_GetImagePixelFormat(pBitmap)
    {
        DllCall("gdiplus\GdipGetImagePixelFormat", this.Ptr, pBitmap, this.PtrA, (Format:=""))
        Return Format
    }
    
    ;##################################################################################################################
    ; Method            Gdip_GetDpiX
    ; Description       Gives the horizontal dots per inch of the graphics of a bitmap
    ;                                                                                                                   
    ; pBitmap           Pointer to a bitmap
    ; Width             ByRef variable. This variable will be set to the width of the bitmap
    ; Height            ByRef variable. This variable will be set to the height of the bitmap
    ;                                                                                                                   
    ; Return            No Return value
    ;                   Gdip_GetDimensions(pBitmap, ThisWidth, ThisHeight) will set ThisWidth to the width and ThisHeight to the height
    
    Gdip_GetDpiX(pGraphics)
    {
        DllCall("gdiplus\GdipGetDpiX", this.Ptr, pGraphics, "float*", (dpix:=""))
        Return Round(dpix)
    }
    
    ;##################################################################################################################
    Gdip_GetDpiY(pGraphics)
    {
        DllCall("gdiplus\GdipGetDpiY", this.Ptr, pGraphics, "float*", (dpiy:=""))
        Return Round(dpiy)
    }
    
    ;##################################################################################################################
    Gdip_GetImageHorizontalResolution(pBitmap)
    {
        DllCall("gdiplus\GdipGetImageHorizontalResolution", this.Ptr, pBitmap, "float*", (dpix:=""))
        Return Round(dpix)
    }
    
    ;##################################################################################################################
    Gdip_GetImageVerticalResolution(pBitmap)
    {
        DllCall("gdiplus\GdipGetImageVerticalResolution", this.Ptr, pBitmap, "float*", (dpiy:=""))
        Return Round(dpiy)
    }
    
    ;##################################################################################################################
    Gdip_BitmapSetResolution(pBitmap, dpix, dpiy)
    {
        Return DllCall("gdiplus\GdipBitmapSetResolution", this.Ptr, pBitmap, "float", dpix, "float", dpiy)
    }
    
    ;##################################################################################################################
    ; sFile IconNumber IconSize pBitmap
    
    Gdip_CreateBitmapFromFile(sFile, IconNumber=1, IconSize="")
    {
        pBitmap := ""
        
        SplitPath, sFile,,, ext
        if ext in exe,dll
        {
            BufSize := 16 + (2*(A_PtrSize ? A_PtrSize : 4))
            , Sizes := IconSize ? IconSize : 256 "|" 128 "|" 64 "|" 48 "|" 32 "|" 16
            , hIcon := pBitmapOld  := ""
            , VarSetCapacity(buf, BufSize, 0)
            
            Loop, Parse, Sizes, |
            {
                DllCall("PrivateExtractIcons", "str", sFile, "int", IconNumber-1, "int", A_LoopField, "int", A_LoopField, this.PtrA, hIcon, this.PtrA, 0, "uint", 1, "uint", 0)
                
                if !hIcon
                    continue
                
                if !DllCall("GetIconInfo", this.Ptr, hIcon, this.Ptr, &buf)
                {
                    this.DestroyIcon(hIcon)
                    continue
                }
                
                hbmMask  := NumGet(buf, 12 + ((A_PtrSize ? A_PtrSize : 4) - 4)) ; What is this used for...? It's never referenced.
                hbmColor := NumGet(buf, 12 + ((A_PtrSize ? A_PtrSize : 4) - 4) + (A_PtrSize ? A_PtrSize : 4))
                if !(hbmColor && DllCall("GetObject", this.Ptr, hbmColor, "int", BufSize, this.Ptr, &buf))
                {
                    this.DestroyIcon(hIcon)
                    continue
                }
                break
            }
            
            if !hIcon
                Return -1
            
            Width := NumGet(buf, 4, "int")
            , Height := NumGet(buf, 8, "int")
            
            hbm := this.CreateDIBSection(Width, -Height)
            , hdc := this.CreateCompatibleDC()
            , obm := this.SelectObject(hdc, hbm)
            
            if !DllCall("DrawIconEx", this.Ptr, hdc, "int", 0, "int", 0, this.Ptr, hIcon, "uint", Width, "uint", Height, "uint", 0, this.Ptr, 0, "uint", 3)
            {
                this.DestroyIcon(hIcon)
                Return -2
            }
            
            VarSetCapacity(dib, 104)
            , DllCall("GetObject", this.Ptr, hbm, "int", A_PtrSize = 8 ? 104 : 84, this.Ptr, &dib) ; sizeof(DIBSECTION) = 76+2*(A_PtrSize=8?4:0)+2*A_PtrSize
            , Stride := NumGet(dib, 12, "Int")
            , Bits := NumGet(dib, 20 + (A_PtrSize = 8 ? 4 : 0)) ; padding
            , DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", Width, "int", Height, "int", Stride, "int", 0x26200A, this.Ptr, Bits, this.PtrA, pBitmapOld)
            , pBitmap := this.Gdip_CreateBitmap(Width, Height)
            , G := this.Gdip_GraphicsFromImage(pBitmap)
            , this.Gdip_DrawImage(G, pBitmapOld, 0, 0, Width, Height, 0, 0, Width, Height)
            , this.SelectObject(hdc, obm)
            , this.DeleteObject(hbm)
            , this.DeleteDC(hdc)
            , this.Gdip_DeleteGraphics(G)
            , this.Gdip_DisposeImage(pBitmapOld)
            
            this.DestroyIcon(hIcon)
        }
        else
        {
            if (!A_IsUnicode)
            {
                VarSetCapacity(wFile, 1024)
                DllCall("kernel32\MultiByteToWideChar", "uint", 0, "uint", 0, this.Ptr, &sFile, "int", -1, this.Ptr, &wFile, "int", 512)
                DllCall("gdiplus\GdipCreateBitmapFromFile", this.Ptr, &wFile, this.PtrA, pBitmap)
            }
            else
                DllCall("gdiplus\GdipCreateBitmapFromFile", this.Ptr, &sFile, this.PtrA, pBitmap)
        }
        
        Return pBitmap
    }
    
    ;##################################################################################################################
    Gdip_CreateBitmapFromHBITMAP(hBitmap, Palette=0)
    {
        DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", this.Ptr, hBitmap, this.Ptr, Palette, this.PtrA, (pBitmap:=""))
        Return pBitmap
    }
    
    ;##################################################################################################################
    Gdip_CreateHBITMAPFromBitmap(pBitmap, Background=0xffffffff)
    {
        DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", this.Ptr, pBitmap, this.PtrA, (hbm:=""), "int", Background)
        Return hbm
    }
    
    ;##################################################################################################################
    Gdip_CreateBitmapFromHICON(hIcon)
    {
        DllCall("gdiplus\GdipCreateBitmapFromHICON", this.Ptr, hIcon, this.PtrA, (pBitmap:=""))
        Return pBitmap
    }
    
    ;##################################################################################################################
    Gdip_CreateHICONFromBitmap(pBitmap)
    {
        DllCall("gdiplus\GdipCreateHICONFromBitmap", this.Ptr, pBitmap, this.PtrA, (hIcon:=""))
        Return hIcon
    }
    
    ;##################################################################################################################
    Gdip_CreateBitmap(Width, Height, Format=0x26200A)
    {
        DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", Width, "int", Height, "int", 0, "int", Format, this.Ptr, 0, this.PtrA, (pBitmap:=""))
        Return pBitmap
    }
    
    ;##################################################################################################################
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
    
    ;##################################################################################################################
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
    
    ;##################################################################################################################
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
    
    ;##################################################################################################################
    ; Create resources
    ;##################################################################################################################
    Gdip_CreatePen(ARGB, w)
    {
        DllCall("gdiplus\GdipCreatePen1", "UInt", ARGB, "float", w, "int", 2, this.PtrA, (pPen:=""))
        Return pPen
    }
    
    ;##################################################################################################################
    Gdip_CreatePenFromBrush(pBrush, w)
    {
        DllCall("gdiplus\GdipCreatePen2", this.Ptr, pBrush, "float", w, "int", 2, this.PtrA, (pPen:=""))
        Return pPen
    }
    
    ;##################################################################################################################
    Gdip_BrushCreateSolid(ARGB=0xff000000)
    {
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", ARGB, this.PtrA, (pBrush:=""))
        Return pBrush
    }
    
    ;##################################################################################################################
    ; HatchStyleHorizontal              = 0
    ; HatchStyleVertical                = 1
    ; HatchStyleForwardDiagonal         = 2
    ; HatchStyleBackwardDiagonal        = 3
    ; HatchStyleCross                   = 4
    ; HatchStyleDiagonalCross           = 5
    ; HatchStyle05Percent               = 6
    ; HatchStyle10Percent               = 7
    ; HatchStyle20Percent               = 8
    ; HatchStyle25Percent               = 9
    
    ; HatchStyle30Percent               = 10
    ; HatchStyle40Percent               = 11
    ; HatchStyle50Percent               = 12
    ; HatchStyle60Percent               = 13
    ; HatchStyle70Percent               = 14
    ; HatchStyle75Percent               = 15
    ; HatchStyle80Percent               = 16
    ; HatchStyle90Percent               = 17
    ; HatchStyleLightDownwardDiagonal   = 18
    ; HatchStyleLightUpwardDiagonal     = 19
    
    ; HatchStyleDarkDownwardDiagonal    = 20
    ; HatchStyleDarkUpwardDiagonal      = 21
    ; HatchStyleWideDownwardDiagonal    = 22
    ; HatchStyleWideUpwardDiagonal      = 23
    ; HatchStyleLightVertical           = 24
    ; HatchStyleLightHorizontal         = 25
    ; HatchStyleNarrowVertical          = 26
    ; HatchStyleNarrowHorizontal        = 27
    ; HatchStyleDarkVertical            = 28
    ; HatchStyleDarkHorizontal          = 29
    
    ; HatchStyleDashedDownwardDiagonal  = 30
    ; HatchStyleDashedUpwardDiagonal    = 31
    ; HatchStyleDashedHorizontal        = 32
    ; HatchStyleDashedVertical          = 33
    ; HatchStyleSmallConfetti           = 34
    ; HatchStyleLargeConfetti           = 35
    ; HatchStyleZigZag                  = 36
    ; HatchStyleWave                    = 37
    ; HatchStyleDiagonalBrick           = 38
    ; HatchStyleHorizontalBrick         = 39
    
    ; HatchStyleWeave                   = 40
    ; HatchStylePlaid                   = 41
    ; HatchStyleDivot                   = 42
    ; HatchStyleDottedGrid              = 43
    ; HatchStyleDottedDiamond           = 44
    ; HatchStyleShingle                 = 45
    ; HatchStyleTrellis                 = 46
    ; HatchStyleSphere                  = 47
    ; HatchStyleSmallGrid               = 48
    ; HatchStyleSmallCheckerBoard       = 49
    
    ; HatchStyleLargeCheckerBoard       = 50
    ; HatchStyleOutlinedDiamond         = 51
    ; HatchStyleSolidDiamond            = 52
    ; HatchStyleTotal                   = 53
    
    Gdip_BrushCreateHatch(ARGBfront, ARGBback, HatchStyle=0)
    {
        DllCall("gdiplus\GdipCreateHatchBrush", "int", HatchStyle, "UInt", ARGBfront, "UInt", ARGBback, this.PtrA, (pBrush:=""))
        Return pBrush
    }
    
    ;##################################################################################################################
    Gdip_CreateTextureBrush(pBitmap, WrapMode=1, x=0, y=0, w="", h="")
    {
        pBrush := ""
        , !(w && h)
            ? DllCall("gdiplus\GdipCreateTexture", this.Ptr, pBitmap, "int", WrapMode, this.PtrA, pBrush)
            : DllCall("gdiplus\GdipCreateTexture2", this.Ptr, pBitmap, "int", WrapMode, "float", x, "float", y, "float", w, "float", h, this.PtrA, pBrush)
        Return pBrush
    }
    
    ;##################################################################################################################
    ; WrapModeTile = 0
    ; WrapModeTileFlipX = 1
    ; WrapModeTileFlipY = 2
    ; WrapModeTileFlipXY = 3
    ; WrapModeClamp = 4
    Gdip_CreateLineBrush(x1, y1, x2, y2, ARGB1, ARGB2, WrapMode=1)
    {
        PointF1 := PointF2 := LGpBrush := ""
        , this.CreatePointF(PointF1, x1, y1)
        , this.CreatePointF(PointF2, x2, y2)
        , DllCall("gdiplus\GdipCreateLineBrush", this.Ptr, &PointF1, this.Ptr, &PointF2, "Uint", ARGB1, "Uint", ARGB2, "int", WrapMode, this.PtrA, LGpBrush)
        
        Return LGpBrush
    }
    
    ;##################################################################################################################
    ; LinearGradientModeHorizontal = 0
    ; LinearGradientModeVertical = 1
    ; LinearGradientModeForwardDiagonal = 2
    ; LinearGradientModeBackwardDiagonal = 3
    Gdip_CreateLineBrushFromRect(x, y, w, h, ARGB1, ARGB2, LinearGradientMode=1, WrapMode=1)
    {
        this.CreateRectF((RectF:=""), x, y, w, h)
        , DllCall("gdiplus\GdipCreateLineBrushFromRect", this.Ptr, &RectF, "int", ARGB1, "int", ARGB2, "int", LinearGradientMode, "int", WrapMode, this.PtrA, (LGpBrush:=""))
        Return LGpBrush
    }
    
    ;##################################################################################################################
    Gdip_CloneBrush(pBrush)
    {
        DllCall("gdiplus\GdipCloneBrush", this.Ptr, pBrush, this.PtrA, (pBrushClone:=""))
        Return pBrushClone
    }
    
    ;##################################################################################################################
    ; Delete resources
    ;##################################################################################################################
    Gdip_DeletePen(pPen)
    {
        Return DllCall("gdiplus\GdipDeletePen", this.Ptr, pPen)
    }
    
    ;##################################################################################################################
    Gdip_DeleteBrush(pBrush)
    {
        Return DllCall("gdiplus\GdipDeleteBrush", this.Ptr, pBrush)
    }
    
    ;##################################################################################################################
    Gdip_DisposeImage(pBitmap)
    {
        Return DllCall("gdiplus\GdipDisposeImage", this.Ptr, pBitmap)
    }
    
    ;##################################################################################################################
    Gdip_DeleteGraphics(pGraphics)
    {
        Return DllCall("gdiplus\GdipDeleteGraphics", this.Ptr, pGraphics)
    }
    
    ;##################################################################################################################
    Gdip_DisposeImageAttributes(ImageAttr)
    {
        Return DllCall("gdiplus\GdipDisposeImageAttributes", this.Ptr, ImageAttr)
    }
    
    ;##################################################################################################################
    Gdip_DeleteFont(hFont)
    {
        Return DllCall("gdiplus\GdipDeleteFont", this.Ptr, hFont)
    }
    
    ;##################################################################################################################
    Gdip_DeleteStringFormat(hFormat)
    {
        Return DllCall("gdiplus\GdipDeleteStringFormat", this.Ptr, hFormat)
    }
    
    ;##################################################################################################################
    Gdip_DeleteFontFamily(hFamily)
    {
        Return DllCall("gdiplus\GdipDeleteFontFamily", this.Ptr, hFamily)
    }
    
    ;##################################################################################################################
    Gdip_DeleteMatrix(Matrix)
    {
        Return DllCall("gdiplus\GdipDeleteMatrix", this.Ptr, Matrix)
    }
    
    ;##################################################################################################################
    ; Text functions
    ;##################################################################################################################
    Gdip_TextToGraphics(pGraphics, Text, Options, Font="Arial", Width="", Height="", Measure=0)
    {
        IWidth      := Width
        , IHeight   := Height
        , PassBrush := 0
        , RegExMatch(Options, "i)X([\-\d\.]+)(p*)", xpos)
        , RegExMatch(Options, "i)Y([\-\d\.]+)(p*)", ypos)
        , RegExMatch(Options, "i)W([\-\d\.]+)(p*)", Width)
        , RegExMatch(Options, "i)H([\-\d\.]+)(p*)", Height)
        , RegExMatch(Options, "i)C(?!(entre|enter))([a-f\d]+)", Colour)
        , RegExMatch(Options, "i)Top|Up|Bottom|Down|vCentre|vCenter", vPos)
        , RegExMatch(Options, "i)NoWrap", NoWrap)
        , RegExMatch(Options, "i)R(\d)", Rendering)
        , RegExMatch(Options, "i)S(\d+)(p*)", Size)
        
        if !this.Gdip_DeleteBrush(this.Gdip_CloneBrush(Colour2))
            PassBrush   := 1
            , pBrush    := Colour2
        
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
            Colour := "0x" (Colour2 ? Colour2 : "ff000000")
        
        Rendering   := ((Rendering1 >= 0) && (Rendering1 <= 5)) ? Rendering1 : 4
        , Size      := (Size1 > 0) ? Size2 ? IHeight*(Size1/100) : Size1 : 12
        , hFamily   := this.Gdip_FontFamilyCreate(Font)
        , hFont     := this.Gdip_FontCreate(hFamily, Size, Style)
        , hFormat   := this.Gdip_StringFormatCreate(NoWrap ? 0x4000 | 0x1000 : 0x4000) ;FormatStyle := NoWrap ? 0x4000 | 0x1000 : 0x4000, hFormat   := this.Gdip_StringFormatCreate(FormatStyle)
        , pBrush    := PassBrush ? pBrush : this.Gdip_BrushCreateSolid(Colour)
        
        if !(hFamily && hFont && hFormat && pBrush && pGraphics)
            Return  !pGraphics  ? -2
                : !hFamily      ? -3
                : !hFont        ? -4
                : !hFormat      ? -5
                : !pBrush       ? -6
                : 0
        
        this.CreateRectF((RC:=""), xpos, ypos, Width, Height)
        , this.Gdip_SetStringFormatAlign(hFormat, Align)
        , this.Gdip_SetTextRenderingHint(pGraphics, Rendering)
        , ReturnRC := this.Gdip_MeasureString(pGraphics, Text, hFont, hFormat, RC)
        
        if vPos
        {
            StringSplit, ReturnRC, ReturnRC, |
            
            if (vPos = "vCentre") || (vPos = "vCenter")
                ypos += (Height-ReturnRC4)//2
            else if (vPos = "Top") || (vPos = "Up")
                ypos := 0
            else if (vPos = "Bottom") || (vPos = "Down")
                ypos := Height-ReturnRC4
            
            this.CreateRectF(RC, xpos, ypos, Width, ReturnRC4)
            ReturnRC := this.Gdip_MeasureString(pGraphics, Text, hFont, hFormat, RC)
        }
        
        if !Measure
            E := this.Gdip_DrawString(pGraphics, Text, hFont, hFormat, pBrush, RC)
        
        if !PassBrush
            this.Gdip_DeleteBrush(pBrush)
        this.Gdip_DeleteStringFormat(hFormat)   
        this.Gdip_DeleteFont(hFont)
        this.Gdip_DeleteFontFamily(hFamily)
        Return E ? E : ReturnRC
    }
    
    ;##################################################################################################################
    Gdip_DrawString(pGraphics, sString, hFont, hFormat, pBrush, ByRef RectF)
    {
        if (!A_IsUnicode)
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
                    , this.Ptr  , pGraphics
                    , this.Ptr  , A_IsUnicode ? &sString : &wString
                    , "int"     , -1
                    , this.Ptr  , hFont
                    , this.Ptr  , &RectF
                    , this.Ptr  , hFormat
                    , this.Ptr  , pBrush)
    }
    
    ;##################################################################################################################
    Gdip_MeasureString(pGraphics, sString, hFont, hFormat, ByRef RectF)
    {
        VarSetCapacity((RC:=""), 16)
        if !A_IsUnicode
        {
            nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, this.Ptr, &sString, "int", -1, "uint", 0, "int", 0)
            , VarSetCapacity(wString, nSize*2)   
            , DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, this.Ptr, &sString, "int", -1, this.Ptr, &wString, "int", nSize)
        }
        
        DllCall("gdiplus\GdipMeasureString"
                        , this.Ptr  , pGraphics
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
    
    ; Near = 0
    ; Center = 1
    ; Far = 2
    Gdip_SetStringFormatAlign(hFormat, Align)
    {
        Return DllCall("gdiplus\GdipSetStringFormatAlign", this.Ptr, hFormat, "int", Align)
    }
    
    ; StringFormatFlagsDirectionRightToLeft    = 0x00000001
    ; StringFormatFlagsDirectionVertical       = 0x00000002
    ; StringFormatFlagsNoFitBlackBox           = 0x00000004
    ; StringFormatFlagsDisplayFormatControl    = 0x00000020
    ; StringFormatFlagsNoFontFallback          = 0x00000400
    ; StringFormatFlagsMeasureTrailingSpaces   = 0x00000800
    ; StringFormatFlagsNoWrap                  = 0x00001000
    ; StringFormatFlagsLineLimit               = 0x00002000
    ; StringFormatFlagsNoClip                  = 0x00004000 
    Gdip_StringFormatCreate(Format=0, Lang=0)
    {
        DllCall("gdiplus\GdipCreateStringFormat", "int", Format, "int", Lang, this.PtrA, (hFormat:=""))
        Return hFormat
    }
    
    ; Regular = 0
    ; Bold = 1
    ; Italic = 2
    ; BoldItalic = 3
    ; Underline = 4
    ; Strikeout = 8
    Gdip_FontCreate(hFamily, Size, Style=0)
    {
        DllCall("gdiplus\GdipCreateFont", this.Ptr, hFamily, "float", Size, "int", Style, "int", 0, this.PtrA, (hFont:=""))
        Return hFont
    }
    
    Gdip_FontFamilyCreate(Font)
    {
        if (!A_IsUnicode)
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
    
    ;##################################################################################################################
    ; Matrix functions
    ;##################################################################################################################
    Gdip_CreateAffineMatrix(m11, m12, m21, m22, x, y)
    {
        DllCall("gdiplus\GdipCreateMatrix2", "float", m11, "float", m12, "float", m21, "float", m22, "float", x, "float", y, this.PtrA, (Matrix:=""))
        Return Matrix
    }
    
    Gdip_CreateMatrix()
    {
        DllCall("gdiplus\GdipCreateMatrix", this.PtrA, (Matrix:=""))
        Return Matrix
    }
    
    ;##################################################################################################################
    ; GraphicsPath functions
    ;##################################################################################################################
    ; Alternate = 0
    ; Winding = 1
    Gdip_CreatePath(BrushMode=0)
    {
        DllCall("gdiplus\GdipCreatePath", "int", BrushMode, this.PtrA, (Path:=""))
        Return Path
    }
    
    Gdip_AddPathEllipse(Path, x, y, w, h)
    {
        Return DllCall("gdiplus\GdipAddPathEllipse", this.Ptr, Path, "float", x, "float", y, "float", w, "float", h)
    }
    
    Gdip_AddPathPolygon(Path, Points)
    {
        StringSplit, Points, Points, |
        VarSetCapacity(PointF, 8*Points0)   
        Loop, %Points0%
        {
            StringSplit, Coord, Points%A_Index%, `,
            NumPut(Coord1, PointF, 8*(A_Index-1), "float")
            , NumPut(Coord2, PointF, (8*(A_Index-1))+4, "float")
        }   
    
        Return DllCall("gdiplus\GdipAddPathPolygon", this.Ptr, Path, this.Ptr, &PointF, "int", Points0)
    }
    
    Gdip_DeletePath(Path)
    {
        Return DllCall("gdiplus\GdipDeletePath", this.Ptr, Path)
    }
    
    ;##################################################################################################################
    ; Quality functions
    ;##################################################################################################################
    ; SystemDefault             = 0
    ; SingleBitPerPixelGridFit  = 1
    ; SingleBitPerPixel         = 2
    ; AntiAliasGridFit          = 3
    ; AntiAlias                 = 4
    Gdip_SetTextRenderingHint(pGraphics, RenderingHint)
    {
        Return DllCall("gdiplus\GdipSetTextRenderingHint", this.Ptr, pGraphics, "int", RenderingHint)
    }
    
    ; Default               = 0
    ; LowQuality            = 1
    ; HighQuality           = 2
    ; Bilinear              = 3
    ; Bicubic               = 4
    ; NearestNeighbor       = 5
    ; HighQualityBilinear   = 6
    ; HighQualityBicubic    = 7
    Gdip_SetInterpolationMode(pGraphics, InterpolationMode)
    {
        Return DllCall("gdiplus\GdipSetInterpolationMode", this.Ptr, pGraphics, "int", InterpolationMode)
    }
    
    ; Invalid      = 0
    ; Default      = 1
    ; HighSpeed    = 2
    ; HighQuality  = 3
    ; None         = 4
    ; AntiAlias    = 5
    ; AntiAlias8x4 = 6
    ; AntiAlias8x8 = 7
    Gdip_SetSmoothingMode(pGraphics, SmoothingMode)
    {
        Return DllCall("gdiplus\GdipSetSmoothingMode", this.Ptr, pGraphics, "int", SmoothingMode)
    }
    
    ; CompositingModeSourceOver = 0 (blended)
    ; CompositingModeSourceCopy = 1 (overwrite)
    Gdip_SetCompositingMode(pGraphics, CompositingMode=0)
    {
        Return DllCall("gdiplus\GdipSetCompositingMode", this.Ptr, pGraphics, "int", CompositingMode)
    }
    
    ;##################################################################################################################
    ; Extra functions
    ;##################################################################################################################
    __New()
    {
        this.Ptr    := A_PtrSize ? "UPtr"   : "UInt"
        this.PtrA   := A_PtrSize ? "UPtr*"  : "UInt*"
        
        this.pToken := this.Startup()
        OnExit(this.run_method("__Delete"))
        ;MsgBox, % "GDIP Started up successfully.`n`nthis.Ptr: " this.Ptr "`nthis.PtrA: " this.PtrA "`nthis.pToken: " this.pToken 
        Return 0
    }
    
    __Delete(pToken)
    {
        Return this.Shutdown(this.pToken)
    }
    
    Startup()
    {
        
        (!DllCall("GetModuleHandle", "str", "gdiplus", Ptr)) ? DllCall("LoadLibrary", "str", "gdiplus") : ""
        , VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0)
        , si := Chr(1)
        , DllCall("gdiplus\GdiplusStartup", this.PtrA, (pToken:=""), this.Ptr, &si, this.Ptr, 0)
        
        Return pToken
    }
    
    Shutdown(pToken)
    {
        DllCall("gdiplus\GdiplusShutdown", this.Ptr, pToken)
        if hModule := DllCall("GetModuleHandle", "str", "gdiplus", this.Ptr)
            DllCall("FreeLibrary", this.Ptr, hModule)
        Return 0
    }

    
    
    ; Prepend = 0; The new operation is applied before the old operation.
    ; Append = 1; The new operation is applied after the old operation.
    Gdip_RotateWorldTransform(pGraphics, Angle, MatrixOrder=0)
    {
        Return DllCall("gdiplus\GdipRotateWorldTransform", this.Ptr, pGraphics, "float", Angle, "int", MatrixOrder)
    }
    
    Gdip_ScaleWorldTransform(pGraphics, x, y, MatrixOrder=0)
    {
        Return DllCall("gdiplus\GdipScaleWorldTransform", this.Ptr, pGraphics, "float", x, "float", y, "int", MatrixOrder)
    }
    
    Gdip_TranslateWorldTransform(pGraphics, x, y, MatrixOrder=0)
    {
        Return DllCall("gdiplus\GdipTranslateWorldTransform", this.Ptr, pGraphics, "float", x, "float", y, "int", MatrixOrder)
    }
    
    Gdip_ResetWorldTransform(pGraphics)
    {
        Return DllCall("gdiplus\GdipResetWorldTransform", this.Ptr, pGraphics)
    }
    
    Gdip_GetRotatedTranslation(Width, Height, Angle, ByRef xTranslation, ByRef yTranslation)
    {
        TAngle  := Angle*(3.14159/180)
        , Bound := (Angle >= 0)
                ? Mod(Angle, 360)
                : 360-Mod(-Angle, -360)
        
        if ((Bound >= 0) && (Bound <= 90))
            xTranslation    := Height*Sin(TAngle)
            , yTranslation  := 0
        else if ((Bound > 90) && (Bound <= 180))
            xTranslation    := (Height*Sin(TAngle))-(Width*Cos(TAngle))
            , yTranslation  := -Height*Cos(TAngle)
        else if ((Bound > 180) && (Bound <= 270))
            xTranslation    := -(Width*Cos(TAngle))
            , yTranslation  := -(Height*Cos(TAngle))-(Width*Sin(TAngle))
        else if ((Bound > 270) && (Bound <= 360))
            xTranslation    := 0
            , yTranslation  := -Width*Sin(TAngle)
    }
    
    Gdip_GetRotatedDimensions(Width, Height, Angle, ByRef RWidth, ByRef RHeight)
    {
        TAngle := Angle*(3.14159/180)
        if !(Width && Height)
            Return -1
        RWidth  := Ceil(Abs(Width * Cos(TAngle)) + Abs(Height * Sin(TAngle)))
        RHeight := Ceil(Abs(Width * Sin(TAngle)) + Abs(Height * Cos(Tangle)))
    }
    
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
    
    Gdip_ImageRotateFlip(pBitmap, RotateFlipType=1)
    {
        Return DllCall("gdiplus\GdipImageRotateFlip", this.Ptr, pBitmap, "int", RotateFlipType)
    }
    
    ; Replace    = 0
    ; Intersect  = 1
    ; Union      = 2
    ; Xor        = 3
    ; Exclude    = 4
    ; Complement = 5
    Gdip_SetClipRect(pGraphics, x, y, w, h, CombineMode=0)
    {
        Return DllCall("gdiplus\GdipSetClipRect", this.Ptr, pGraphics, "float", x, "float", y, "float", w, "float", h, "int", CombineMode)
    }
    
    Gdip_SetClipPath(pGraphics, Path, CombineMode=0)
    {
        Return DllCall("gdiplus\GdipSetClipPath", this.Ptr, pGraphics, this.Ptr, Path, "int", CombineMode)
    }
    
    Gdip_ResetClip(pGraphics)
    {
        Return DllCall("gdiplus\GdipResetClip", this.Ptr, pGraphics)
    }
    
    Gdip_GetClipRegion(pGraphics)
    {
        Region := this.Gdip_CreateRegion()
        , DllCall("gdiplus\GdipGetClip", this.Ptr, pGraphics, "UInt*", Region)
        Return Region
    }
    
    Gdip_SetClipRegion(pGraphics, Region, CombineMode=0)
    {
        Return DllCall("gdiplus\GdipSetClipRegion", this.Ptr, pGraphics, this.Ptr, Region, "int", CombineMode)
    }
    
    Gdip_CreateRegion()
    {
        DllCall("gdiplus\GdipCreateRegion", "UInt*", (Region:=""))
        Return Region
    }
    
    Gdip_DeleteRegion(Region)
    {
        Return DllCall("gdiplus\GdipDeleteRegion", this.Ptr, Region)
    }
    
    ;##################################################################################################################
    ; BitmapLockBits
    ;##################################################################################################################
    Gdip_LockBits(pBitmap, x, y, w, h, ByRef Stride, ByRef Scan0, ByRef BitmapData, LockMode = 3, PixelFormat = 0x26200a)
    {
        this.CreateRect((Rect:=""), x, y, w, h)
        , VarSetCapacity(BitmapData, 16+2*(A_PtrSize ? A_PtrSize : 4), 0)
        , E         := DllCall("Gdiplus\GdipBitmapLockBits", this.Ptr, pBitmap, this.Ptr, &Rect, "uint", LockMode, "int", PixelFormat, this.Ptr, &BitmapData)
        , Stride    := NumGet(BitmapData, 8, "Int")
        , Scan0     := NumGet(BitmapData, 16, this.Ptr)
        Return E
    }
    
    ;##################################################################################################################
    Gdip_UnlockBits(pBitmap, ByRef BitmapData)
    {
        Return DllCall("Gdiplus\GdipBitmapUnlockBits", this.Ptr, pBitmap, this.Ptr, &BitmapData)
    }
    
    ;##################################################################################################################
    Gdip_SetLockBitPixel(ARGB, Scan0, x, y, Stride)
    {
        Numput(ARGB, Scan0+0, (x*4)+(y*Stride), "UInt")
    }
    
    ;##################################################################################################################
    Gdip_GetLockBitPixel(Scan0, x, y, Stride)
    {
        Return NumGet(Scan0+0, (x*4)+(y*Stride), "UInt")
    }
    
    ;##################################################################################################################
    Gdip_PixelateBitmap(pBitmap, ByRef pBitmapOut, BlockSize)
    {
        Static PixelateBitmap := ""
        
        if (!PixelateBitmap)
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
        this.Gdip_GetImageDimensions(pBitmap, Width, Height)
        if (Width != this.Gdip_GetImageWidth(pBitmapOut) || Height != this.Gdip_GetImageHeight(pBitmapOut))
            Return -1
        if (BlockSize > Width || BlockSize > Height)
            Return -2
        
        if (this.Gdip_LockBits(pBitmap, 0, 0, Width, Height, Stride1, Scan01, BitmapData1)
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
    
    ;##################################################################################################################
    Gdip_ToARGB(A, R, G, B)
    {
        Return (A << 24) | (R << 16) | (G << 8) | B
    }
    
    ;##################################################################################################################
    Gdip_FromARGB(ARGB, ByRef A, ByRef R, ByRef G, ByRef B)
    {
          A := (0xff000000 & ARGB) >> 24
        , R := (0x00ff0000 & ARGB) >> 16
        , G := (0x0000ff00 & ARGB) >> 8
        , B := (0x000000ff & ARGB)
    }
    
    ;##################################################################################################################
    Gdip_AFromARGB(ARGB)
    {
        Return (0xff000000 & ARGB) >> 24
    }
    
    ;##################################################################################################################
    Gdip_RFromARGB(ARGB)
    {
        Return (0x00ff0000 & ARGB) >> 16
    }
    
    ;##################################################################################################################
    Gdip_GFromARGB(ARGB)
    {
        Return (0x0000ff00 & ARGB) >> 8
    }
    
    ;##################################################################################################################    
    Gdip_BFromARGB(ARGB)
    {
        Return 0x000000ff & ARGB
    }
    
    ;##################################################################################################################    
    StrGetB(Address, Length=-1, Encoding=0)
    {
        ; Flexible parameter handling:
        if Length is not integer
            Encoding := Length
            , Length := -1
        
        ; Check for obvious errors.
        if (Address+0 < 1024)
            Return
        
        ; Ensure 'Encoding' contains a numeric identifier.
        if Encoding = UTF-16
            Encoding = 1200
        else if Encoding = UTF-8
            Encoding = 65001
        else if SubStr(Encoding,1,2)="CP"
            Encoding := SubStr(Encoding,3)
        
        if !Encoding ; "" or 0
        {
            ; No conversion necessary, but we might not want the whole string.
            if (Length == -1)
                Length := DllCall("lstrlen", "uint", Address)
            VarSetCapacity(String, Length)
            DllCall("lstrcpyn", "str", String, "uint", Address, "int", Length + 1)
        }
        else if Encoding = 1200 ; UTF-16
        {
            char_count := DllCall("WideCharToMultiByte", "uint", 0, "uint", 0x400, "uint", Address, "int", Length, "uint", 0, "uint", 0, "uint", 0, "uint", 0)
            VarSetCapacity(String, char_count)
            DllCall("WideCharToMultiByte", "uint", 0, "uint", 0x400, "uint", Address, "int", Length, "str", String, "int", char_count, "uint", 0, "uint", 0)
        }
        else if Encoding is integer
        {
            ; Convert from target encoding to UTF-16 then to the active code page.
            char_count      := DllCall("MultiByteToWideChar", "uint", Encoding, "uint", 0, "uint", Address, "int", Length, "uint", 0, "int", 0)
            , VarSetCapacity(String, char_count * 2)
            , char_count    := DllCall("MultiByteToWideChar", "uint", Encoding, "uint", 0, "uint", Address, "int", Length, "uint", &String, "int", char_count * 2)
            , String        := this.StrGetB(&String, char_count, 1200)
        }
        
        Return String
    }
    
    ; ########## Misc Methods ##########
    run_method(method_name, params:="") {
        bf := ObjBindMethod(this, method_name, params*)
        Return bf
    }
    
    rand(min, max) {
        Random, result, % min, % max
        Return result
    }
}
