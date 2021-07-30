#Warn
GDIP.__New()

; testing
FileSelectFile, img_path
img_p := GDIP.image.FromFile(img_path, 1)

ExitApp

*Escape::ExitApp

Class GDIP
{
    Static  gdip_token  := ""
            , version   := 1.0
            , imo_ptr   := ""
    
    ;####################################################################################################################
    ; STATUS ENUMERATION - This defines all possible status enumeration return types you might encounter                |
    ;                      Any function with a 'status' named return variable will reference this.                      |
    ;___________________________________________________________________________________________________________________|
    ; Num | Value                     | Indicates that...                                                               |
    ;  0  | Ok                        | Method call was successful.                                                     |
    ;  1  | GenericError              | Error on method call that is not covered by anything else in this list.         |
    ;  2  | InvalidParameter          | One of the method arguments passed was not valid.                               |
    ;  3  | OutOfMemory               | Operating system is out of memory / could not allocate memory.                  |
    ;  4  | ObjectBusy                | One of the arguments specified in the API call is already in use.               |
    ;  5  | InsufficientBuffer        | A buffer passed in the API call is not large enough for the data.               |
    ;  6  | NotImplemented            | Method is not implemented.                                                      |
    ;  7  | Win32Error                | Method generated a Win32 error.                                                 |
    ;  8  | WrongState                | An object state is invalid for the API call.                                    |
    ;  9  | Aborted                   | Method was aborted.                                                             |
    ; 10  | FileNotFound              | Specified image file or metafile cannot be found.                               |
    ; 11  | ValueOverflow             | An arithmetic operation produced a numeric overflow.                            |
    ; 12  | AccessDenied              | Writing is not allowed to the specified file.                                   |
    ; 13  | UnknownImageFormat        | Specified image file format is not known.                                       |
    ; 14  | FontFamilyNotFound        | Specified font family not found. Either not installed or spelled incorrectly.   |
    ; 15  | FontStyleNotFound         | Specified style not available for this font family.                             |
    ; 16  | NotTrueTypeFont           | Font retrieved from HDC or LOGFONT is not TrueType and cannot be used.          |
    ; 17  | UnsupportedGdiplusVersion | Installed GDI+ version not compatible with the application's compiled version.  |
    ; 18  | GdiplusNotInitialized     | GDI+ API not initialized.                                                       |
    ; 19  | PropertyNotFound          | Specified property does not exist in the image.                                 |
    ; 20  | PropertyNotSupported      | Specified property not supported by image format and cannot be set.             |
    ; 21  | ProfileNotFound           | Color profile required to save in CMYK image format was not found.              |
    ;_____|___________________________|_________________________________________________________________________________|
    
    ;####################################################################################################################
    ;  Initialize/Terminate GDI+                                                                                        |
    ;####################################################################################################################
    
    ;___________________________________________________________________________________________________________________|
    ; Call                                                                                                              |
    ; Description                                                                                                       |
    ; Params                                                                                                            |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    __New()
    {
        ; A_PtrSize = size of pointer (bytes) depending on script bit type.
        this.Ptr        := (A_PtrSize = 4) ? "UPtr"     ; Set pointer type. 32-bit uses UPtrs
                        :  (A_PtrSize = 8) ? "Ptr"      ; There is no UPtr for 64-bit, only Ptr
                        :                    "UInt"     ; Default to UInt
        this.PtrA       := this.Ptr . "*"               ; Set pointer address type
        OnExit(this._method("__Delete"))                ; Ensure shutdown runs at script exit
        estat           := this.Startup()               ; Run GDIP startup and get token
        ;this.generate_colorName()                      ; Generate color object
        ;ad generator here
        Return estat
    }
    
    __Delete()
    {
        this.Shutdown()
        , this.gdip_token := ""
        Return
    }
    
    ;___________________________________________________________________________________________________________________|
    ; Call          Startup()                                                                                           |
    ; Description   Initializes GDI+ and stores token in the main GDIP class under GDIP.token                           |
    ; Return        Status enumeration. 0 = success. -1 = GDIP already started.                                         |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;___________________________________________________________________________________________________________________|
    Startup()
    {
        If (this.gdip_token != "")
            Return -1
        
        DllCall("GetModuleHandle", "str", "gdiplus")
            ? "" : DllCall("LoadLibrary", "str", "gdiplus")
        
        VarSetCapacity(token, A_PtrSize)
        ,VarSetCapacity(gdip_si, (A_PtrSize = 8) ? 24 : 16, 0)
        ,NumPut(1, gdip_si)
        ,estat := DllCall("gdiplus\GdiplusStartup"
                         ,this.PtrA , token         ; Pointer to GDIP token
                         ,this.Ptr  , &gdip_si      ; Startup Input
                         ,this.Ptr  , 0)            ; Startup Output 0 = null
        ,this.gdip_token := token
        
        Return estat
    }
    
    ;___________________________________________________________________________________________________________________|
    ; Call              Shutdown()                                                                                      |
    ; Description       Cleans up resources used by Windows GDI+ and clears GDIP token.                                 |
    ;                                                                                                                   |
    ; Return            None                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Shutdown()
    {
        DllCall("gdiplus\GdiplusShutdown", "UInt", this.gdip_token)
        Return
    }
    
    ;___________________________________________________________________________________________________________________|
    ; Call              new_window(OnTop:=1,TitleBar:=0,TaskBar:=0)                                                     |
    ; Description       Cleans up resources used by Windows GDI+ and clears GDIP token.                                 |
    ;                                                                                                                   |
    ; OnTop             Set window to always on top                                                                     |
    ;                                                                                                                   |
    ; Return            Handle to gui                                                                                            |
    ;___________________________________________________________________________________________________________________|
    new_window(OnTop=1, TitleBar=0, TaskBar=0)
    {
        Gui, New, % "+E0x80000 "                        ; Create a new layered window
            . (TitleBar ? " -Caption"     : "")         ; Remove title bar and thick window border/edge
            . (OnTop    ? " +AlwaysOnTop" : "")         ; Force GUI to always be on top
            . (TaskBar  ? " +ToolWindow"  : "")         ; Removes the taskbar button
            . "+HWNDguiHwnd "                           ; Saves the handle of the GUI to guiHwnd
        Gui, Show, NA                                   ; Make window visible but transparent
        Return guiHwnd
    }
    
    ;####################################################################################################################
    ;  Class Methods                                                                                                    |
    ;####################################################################################################################
    ; Quick boundfuncs
    _method(method_name, params := "")
    {
        bf := ObjBindMethod(this, method_name, params*)
        Return bf
    }
    
    log_error(call, type, value)
    {
        this.last_err := A_Now "`n" call "`n" type "`n" value "`n`n"
        Return
    }
    
    ; Stores byte size of different data_type
    data_type_size(type)
    {
        Static dt  := ""
        If (dt = "")
        {
            p := A_PtrSize
            h := (A_PtrSize = 8) ? 4 : 2
            u := A_IsUnicode     ? 2 : 1
            dt.__int8     := 1    ,dt.int                 := 4    ,dt["unsigned __int16"]    := 2
            dt.__int16    := 2    ,dt.long                := 4    ,dt["unsigned __int32"]    := 4
            dt.__int32    := 4    ,dt.short               := 2    ,dt["unsigned __int64"]    := 8
            dt.__int64    := 8    ,dt.wchar_t             := 2    ,dt["unsigned char"]       := 1
            dt.__wchar_t  := 2    ,dt["long double"]      := 8    ,dt["unsigned short"]      := 2
            dt.bool       := 1    ,dt["long long"]        := 8    ,dt["unsigned long"]       := 4
            dt.char       := 1    ,dt["unsigned int"]     := 4    ,dt["unsigned long long"]  := 8
            dt.double     := 8    ,dt["unsigned __int8"]  := 1    ,dt["signed char"]         := 1
            dt.float      := 4
            
            dt.ATOM          := 2    ,dt.INT_PTR           := p    ,dt.PSHORT                 := p
            dt.BOOL          := 4    ,dt.LANGID            := 2    ,dt.PSIZE_T                := p
            dt.BOOLEAN       := 1    ,dt.LCID              := 4    ,dt.PSSIZE_T               := p
            dt.BYTE          := 1    ,dt.LCTYPE            := 4    ,dt.PSTR                   := p
            dt.CCHAR         := 1    ,dt.LGRPID            := 4    ,dt.PTBYTE                 := p
            dt.CHAR          := 1    ,dt.LONG              := 4    ,dt.PTCHAR                 := p
            dt.COLORREF      := 4    ,dt.LONG32            := 4    ,dt.PTSTR                  := p
            dt.DWORD         := 4    ,dt.LONG64            := 8    ,dt.PUCHAR                 := p
            dt.DWORD32       := 4    ,dt.LONG_PTR          := p    ,dt.PUHALF_PTR             := p
            dt.DWORD64       := 8    ,dt.LONGLONG          := 8    ,dt.PUINT                  := p
            dt.DWORD_PTR     := p    ,dt.LPARAM            := p    ,dt.PUINT16                := p
            dt.DWORDLONG     := 8    ,dt.LPBOOL            := p    ,dt.PUINT32                := p
            dt.HACCEL        := p    ,dt.LPBYTE            := p    ,dt.PUINT64                := p
            dt.HALF_PTR      := h    ,dt.LPCOLORREF        := p    ,dt.PUINT8                 := p
            dt.HANDLE        := p    ,dt.LPCSTR            := p    ,dt.PUINT_PTR              := p
            dt.HBITMAP       := p    ,dt.LPCTSTR           := p    ,dt.PULONG                 := p
            dt.HBRUSH        := p    ,dt.LPCVOID           := 0    ,dt.PULONG32               := p
            dt.HCOLORSPACE   := p    ,dt.LPDWORD           := 4    ,dt.PULONG64               := p
            dt.HCONV         := p    ,dt.LPHANDLE          := p    ,dt.PULONG_PTR             := p
            dt.HCONVLIST     := p    ,dt.LPINT             := 4    ,dt.PULONGLONG             := p
            dt.HCURSOR       := p    ,dt.LPLONG            := 4    ,dt.PUSHORT                := p
            dt.HDC           := p    ,dt.LPVOID            := p    ,dt.PVOID                  := p
            dt.HDDEDATA      := p    ,dt.LPWORD            := 2    ,dt.PWCHAR                 := p
            dt.HDESK         := p    ,dt.LRESULT           := p    ,dt.PWORD                  := p
            dt.HDROP         := p    ,dt.PBOOL             := p    ,dt.PWSTR                  := p
            dt.HDWP          := p    ,dt.PBOOLEAN          := p    ,dt.QWORD                  := 8
            dt.HENHMETAFILE  := p    ,dt.PBYTE             := p    ,dt.SC_HANDLE              := p
            dt.HFILE         := 4    ,dt.PCHAR             := p    ,dt.SC_LOCK                := p
            dt.HFONT         := p    ,dt.PDWORD            := p    ,dt.SERVICE_STATUS_HANDLE  := p
            dt.HGDIOBJ       := p    ,dt.PDWORD32          := p    ,dt.SIZE_T                 := p
            dt.HGLOBAL       := p    ,dt.PDWORD64          := p    ,dt.SSIZE_T                := p
            dt.HHOOK         := p    ,dt.PDWORD_PTR        := p    ,dt.TBYTE                  := u
            dt.HICON         := p    ,dt.PDWORDLONG        := p    ,dt.TCHAR                  := u
            dt.HINSTANCE     := p    ,dt.PFLOAT            := p    ,dt.UCHAR                  := 1
            dt.HKEY          := p    ,dt.PHALF_PTR         := p    ,dt.UHALF_PTR              := h
            dt.HKL           := p    ,dt.PHANDLE           := p    ,dt.UINT                   := 4
            dt.HLOCAL        := p    ,dt.PHKEY             := p    ,dt.UINT16                 := 2
            dt.HMENU         := p    ,dt.PINT              := p    ,dt.UINT32                 := 4
            dt.HMETAFILE     := p    ,dt.PINT16            := p    ,dt.UINT64                 := 8
            dt.HMODULE       := p    ,dt.PINT32            := p    ,dt.UINT8                  := 1
            dt.HMONITOR      := p    ,dt.PINT64            := p    ,dt.UINT_PTR               := p
            dt.HPALETTE      := p    ,dt.PINT8             := p    ,dt.ULONG                  := 4
            dt.HPEN          := p    ,dt.PINT_PTR          := p    ,dt.ULONG32                := 4
            dt.HRESULT       := 4    ,dt.PLCID             := p    ,dt.ULONG64                := 8
            dt.HRGN          := p    ,dt.PLONG             := p    ,dt.ULONG_PTR              := p
            dt.HRSRC         := p    ,dt.PLONG32           := p    ,dt.ULONGLONG              := 8
            dt.HSZ           := p    ,dt.PLONG64           := p    ,dt.USHORT                 := 2
            dt.HWINSTA       := p    ,dt.PLONG_PTR         := p    ,dt.USN                    := 8
            dt.HWND          := p    ,dt.PLONGLONG         := p    ,dt.VOID                   := 0
            dt.INT16         := 2    ,dt.POINTER_32        := p    ,dt.WCHAR                  := 2
            dt.INT32         := 4    ,dt.POINTER_64        := p    ,dt.WORD                   := 2
            dt.INT64         := 8    ,dt.POINTER_SIGNED    := p    ,dt.WPARAM                 := p
            dt.INT8          := 1    ,dt.POINTER_UNSIGNED  := p
        }
        bytes := dt[type]
        Return (bytes * 0 = 0) ? bytes                  ; Bytes
             : "error"                                  ; Not found
    }
    
    is_supported_file_type(type)
    {
        Static  file_types:= {"BMP"   : 1
                             ,"ICON"  : 1
                             ,"GIF"   : 1
                             ,"JPEG"  : 1
                             ,"Exif"  : 1
                             ,"PNG"   : 1
                             ,"TIFF"  : 1
                             ,"WMF"   : 1
                             ,"EMF"   : 1 }
        Return (file_types[type] ? 1 : 0)
    }
    
    ;####################################################################################################################
    ;  Image Class                                                                                                      |
    ;####################################################################################################################
    ; The Image class provides methods for loading and saving raster images (bitmaps) and vector images (metafiles).
    ; An Image object encapsulates a bitmap or a metafile and stores attributes that you can retrieve by calling 
    ; various Get methods.
    ; You can construct Image objects from a variety of file types including:
    ; BMP, ICON, GIF, JPEG, Exif, PNG, TIFF, WMF, EMF
    
    Class Image Extends GDIP
    {
        ; The Clone method creates a new Image object and initializes it with the contents of this Image object.
        Clone(image_p)
        {
            VarSetCapacity(clone_p, A_PtrSize)
            estat := DllCall("gdip\GdipCloneImage"
                            ,this.Ptr   , image_p
                            ,this.Ptr   , clone_p)
            estat ? this.log_error(A_ThisFunc, "Enum Status", estat) : ""
            MsgBox, % "image_p: " image_p "`nclone_p: " clone_p "`nestat: " estat 
            Return clone_p
        }
        
        ; The FindFirstItem method retrieves the description and the data size of the first metadata item in this Image object.
        ;FindFirstItem()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The FindNextItem method is used along with the FindFirstItem method to enumerate the metadata items stored in this Image object.
        ;FindNextItem()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; Description   The FromFile method creates an Image object based on a file.
        ; filename      String containing filename/full path to file.
        ; icm           Bool that specifies if Image Color Management (color correction) should be used
        ; 
        ; Returns       Pointer to new Image object
        FromFile(filename, icm=0)
        {
            VarSetCapacity(image_p, A_PtrSize)
            estat := DllCall("gdiplus\GdipLoadImageFromFile" . (icm ? "ICM" : "")
                            ,this.Ptr     , &filename
                            ,this.PtrA    , image_p)
            estat ? this.log_error(A_ThisFunc, "Enum Status", estat) : ""
            Return image_p
        }
        
        ; The FromStream method creates a new Image object based on a stream.
        ;FromStream()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetAllPropertyItems method gets all the property items (metadata) stored in this Image object.
        ;GetAllPropertyItems()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetBounds method gets the bounding rectangle for this image.
        ;GetBounds()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetEncoderParameterList method gets a list of the parameters supported by a specified image encoder.
        ;GetEncoderParameterList()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetEncoderParameterListSize method gets the size, in bytes, of the parameter list for a specified image encoder.
        ;GetEncoderParameterListSize()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetFlags method gets a set of flags that indicate certain attributes of this Image object.
        ;GetFlags()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetFrameCount method gets the number of frames in a specified dimension of this Image object.
        ;GetFrameCount()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetFrameDimensionsCount method gets the number of frame dimensions in this Image object.
        ;GetFrameDimensionsCount()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetFrameDimensionsList method gets the identifiers for the frame dimensions of this Image object.
        ;GetFrameDimensionsList()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetHeight method gets the image height, in pixels, of this image.
        ;GetHeight()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetHorizontalResolution method gets the horizontal resolution, in dots per inch, of this image.
        ;GetHorizontalResolution()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetItemData method gets one piece of metadata from this Image object.
        ;GetItemData()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetLastStatus method returns a value that indicates the nature of this Image object's most recent method failure.
        ;GetLastStatus()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetPalette method gets the ColorPalette of this Image object.
        ;GetPalette()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetPaletteSize method gets the size, in bytes, of the color palette of this Image object.
        ;GetPaletteSize()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetPhysicalDimension method gets the width and height of this image.
        ;GetPhysicalDimension()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetPixelFormat method gets the pixel format of this Image object.
        ;GetPixelFormat()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetPropertyCount method gets the number of properties (pieces of metadata) stored in this Image object.
        ;GetPropertyCount()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetPropertyIdList method gets a list of the property identifiers used in the metadata of this Image object.
        ;GetPropertyIdList()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetPropertyItem method gets a specified property item (piece of metadata) from this Image object.
        ;GetPropertyItem()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetPropertyItemSize method gets the size, in bytes, of a specified property item of this Image object.
        ;GetPropertyItemSize()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetPropertySize method gets the total size, in bytes, of all the property items stored in this Image object. The GetPropertySize method also gets the number of property items stored in this Image object.
        ;GetPropertySize()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetRawFormat method gets a globally unique identifier ( GUID) that identifies the format of this Image object. GUIDs that identify various file formats are defined in Gdiplusimaging.h.
        ;GetRawFormat()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetThumbnailImage method gets a thumbnail image from this Image object.
        ;GetThumbnailImage()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetType method gets the type (bitmap or metafile) of this Image object.
        GetType(image_p)
        {
            VarSetCapacity(type, this.data_size.int)
            DllCall("gdip\GdipGetImageType"
                   ,this.Ptr    , image_p
                   ,"Int"       , type)
            Return this.enum[type]
        }
        
        ; The GetVerticalResolution method gets the vertical resolution, in dots per inch, of this image.
        ;GetVerticalResolution()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The GetWidth method gets the width, in pixels, of this image.
        ;GetWidth()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; This topic lists the constructors of the Image class. For a complete class listing, see Image Class.
        ;Image()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; Creates an Image object based on a file.
        ;Image()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; This topic lists the constructors of the Image class. For a complete class listing, see Image Class.
        ;Image()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; Creates an Image object based on a stream.
        ;Image()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; This topic lists the constructors of the Image class. For a complete class listing, see Image Class.
        ;Image()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The RemovePropertyItem method removes a property item (piece of metadata) from this Image object.
        ;RemovePropertyItem()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The RotateFlip method rotates and flips this image.
        ;RotateFlip()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The Save method saves this image to a file.
        ;Save()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The Save method saves this image to a stream.
        ;Save()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The SaveAdd method adds a frame to a file or stream specified in a previous call to the Save method.
        ;SaveAdd()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The SaveAdd method adds a frame to a file or stream specified in a previous call to the Save method.
        ;SaveAdd()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The SelectActiveFrame method selects the frame in this Image object specified by a dimension and an index.
        ;SelectActiveFrame()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The SetAbort method sets the object whose Abort method is called periodically during time-consuming rendering operation.
        ;SetAbort()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The SetPalette method sets the color palette of this Image object.
        ;SetPalette()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
        
        ; The SetPropertyItem method sets a property item (piece of metadata) for this Image object. If the item already exists, then its contents are updated; otherwise, a new item is added.
        ;SetPropertyItem()
        ;{
            ;DllCall("gdip\"
            ;, type , value)
        ;}
    }
    
    ;####################################################################################################################
    ;  Graphics Class                                                                                                   |
    ;####################################################################################################################
    Class grahics extends GDIP
    {
        ; Adds a text comment to an existing metafile
        ; text      The text to add
        ; gp        Pointer to graphics
        ; Return    Estat
        AddMetafileComment(text, gp)
        {
            stat := DllCall("gdiplus\GdipComment"
                           ,this.Ptr    , gp                    ; Graphics pointer
                           ,"UINT"      , VarSetCapacity(text)  ; Size of text
                           ,this.Ptr    , text)                 ; Text
            Return stat
        }
        
        ; Begins a new graphics container
        ; Used to make nested graphics containers
        ; dstrect   Destination rectangle
        ; srcrect   Source rectangle
        ; unit      Unit of measure (See unit enum)
        ; Return    
        ; Remark    If no params are passe
        ;BeginContainer(dstrect=0, srcrect=0, unit=0) ;IN const RectF &dstrect, IN const RectF &srcrect, IN Unit unit
        ;{
        ;    DllCall("gdiplus\GdipBeginContainer"
        ;           , GpGraphics *graphics
        ;           , GDIPCONST GpRectF  , *dstrect
        ;           , GDIPCONST GpRectF  , *srcrect
        ;           , GpUnit             , unit
        ;           , "UInt"             , *state)
        ;}
        
        ;~ Clear()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::Clear method clears a Graphicsobject to a specified color.
        
        ;~ DrawArc()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawArc method draws an arc. The arc is part of an ellipse.
        
        ;~ DrawArc()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawArc method draws an arc. The arc is part of an ellipse.
        
        ;~ DrawArc()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawArc method draws an arc. The arc is part of an ellipse.
        
        ;~ DrawArc()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawArc method draws an arc.
        
        ;~ DrawBezier()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawBezier method draws a B?zier spline.
        
        ;~ DrawBezier()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawBezier method draws a B?zier spline.
        
        ;~ DrawBezier()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawBezier method draws a B?zier spline.
        
        ;~ DrawBezier()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawBezier method draws a Bezier spline.
        
        ;~ DrawBeziers()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawBeziers method draws a sequence of connected B?zier splines.
        
        ;~ DrawBeziers()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawBeziers method draws a sequence of connected Bezier splines.
        
        ;~ DrawCachedBitmap()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawCachedBitmap method draws the image stored in a CachedBitmap object.
        
        ;~ DrawClosedCurve()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawClosedCurve method draws a closed cardinal spline.
        
        ;~ DrawClosedCurve()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawClosedCurve method draws a closed cardinal spline.
        
        ;~ DrawClosedCurve()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawClosedCurve method draws a closed cardinal spline.
        
        ;~ DrawClosedCurve()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawClosedCurve method draws a closed cardinal spline.
        
        ;~ DrawCurve()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawCurve method draws a cardinal spline.
        
        ;~ DrawCurve()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawCurve method draws a cardinal spline.
        
        ;~ DrawCurve()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawCurve method draws a cardinal spline.
        
        ;~ DrawCurve()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawCurve method draws a cardinal spline.
        
        ;~ DrawCurve()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawCurve method draws a cardinal spline.
        
        ;~ DrawCurve()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawCurve method draws a cardinal spline.
        
        ;~ DrawDriverString()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawDriverString method draws characters at the specified positions. The method gives the client complete control over the appearance of text. The method assumes that the client has already set up the format and layout to be applied.
        
        ;~ DrawEllipse()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawEllipse method draws an ellipse.
        
        ;~ DrawEllipse()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawEllipse method draws an ellipse.
        
        ;~ DrawEllipse()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawEllipse method draws an ellipse.
        
        ;~ DrawEllipse()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawEllipse method draws an ellipse.
        
        ;~ DrawImage()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawImage method draws an image.
        
        ;~ DrawImage()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawImage method draws an image.
        
        ;~ DrawImage()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawImage method draws an image.
        
        ;~ DrawImage()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawImage method draws an image.
        
        ;~ DrawImage()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawImage method draws an image.
        
        ;~ DrawImage()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawImage method draws an image.
        
        ;~ DrawImage()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawImage method draws an image.
        
        ;~ DrawImage()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawImage method draws an image.
        
        ;~ DrawImage()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawImage method draws an image.
        
        ;~ DrawImage()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawImage method draws a specified portion of an image at a specified location.
        
        ;~ DrawImage()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawImage method draws an image.
        
        ;~ DrawImage()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawImage method draws an image at a specified location.
        
        ;~ DrawImage()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawImage method draws an image.
        
        ;~ DrawImage()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawImage method draws an image.
        
        ;~ DrawImage()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawImage method draws an image at a specified location.
        
        ;~ DrawImage()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawImage method draws an image.
        
        ;~ DrawImage()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawImage method draws an image.
        
        ;~ DrawImage()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The method draws a portion of an image after applying a specified effect.
        
        ;~ DrawLine()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawLine method draws a line that connects two points.
        
        ;~ DrawLine()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawLine method draws a line that connects two points.
        
        ;~ DrawLine()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawLine method draws a line that connects two points.
        
        ;~ DrawLine()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawLine method draws a line that connects two points.
        
        ;~ DrawLines()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawLines method draws a sequence of connected lines.
        
        ;~ DrawLines()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawLines method draws a sequence of connected lines.
        
        ;~ DrawPath()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawPath method draws a sequence of lines and curves defined by a GraphicsPath object.
        
        ;~ DrawPie()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawPie method draws a pie.
        
        ;~ DrawPie()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawPie method draws a pie.
        
        ;~ DrawPie()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawPie method draws a pie.
        
        ;~ DrawPie()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawPie method draws a pie.
        
        ;~ DrawPolygon()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawPolygon method draws a polygon.
        
        ;~ DrawPolygon()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawPolygon method draws a polygon.
        
        ;~ DrawRectangle()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawRectangle method draws a rectangle.
        
        ;~ DrawRectangle()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawRectangle method draws a rectangle.
        
        ;~ DrawRectangle()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawRectangle method draws a rectangle.
        
        ;~ DrawRectangle()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawRectangle method draws a rectangle.
        
        ;~ DrawRectangles()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawRectangles method draws a sequence of rectangles.
        
        ;~ DrawRectangles()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawRectangles method draws a sequence of rectangles.
        
        ;~ DrawString()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawString method draws a string based on a font and an origin for the string.
        
        ;~ DrawString()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawString method draws a string based on a font, a string origin, and a format.
        
        ;~ DrawString()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::DrawString method draws a string based on a font, a layout rectangle, and a format.
        
        ;~ EndContainer()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::EndContainer method closes a graphics container that was previously opened by the Graphics::BeginContainer method.
        
        ;~ EnumerateMetafile()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::EnumerateMetafile method calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        
        ;~ EnumerateMetafile()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::EnumerateMetafile method calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        
        ;~ EnumerateMetafile()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::EnumerateMetafile method calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        
        ;~ EnumerateMetafile()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::EnumerateMetafile method calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        
        ;~ EnumerateMetafile()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::EnumerateMetafile method calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        
        ;~ EnumerateMetafile()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::EnumerateMetafile method calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        
        ;~ EnumerateMetafile()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::EnumerateMetafile method calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        
        ;~ EnumerateMetafile()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::EnumerateMetafile method calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        
        ;~ EnumerateMetafile()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::EnumerateMetafile method calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        
        ;~ EnumerateMetafile()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::EnumerateMetafile method calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        
        ;~ EnumerateMetafile()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::EnumerateMetafile method calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        
        ;~ EnumerateMetafile()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::EnumerateMetafile method calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        
        ;~ ExcludeClip()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::ExcludeClip method updates the clipping region to the portion of itself that does not intersect the specified rectangle.
        
        ;~ ExcludeClip()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::ExcludeClip method updates the clipping region to the portion of itself that does not intersect the specified rectangle.
        
        ;~ ExcludeClip()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::ExcludeClip method updates the clipping region with the portion of itself that does not overlap the specified region.
        
        ;~ FillClosedCurve()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillClosedCurve method creates a closed cardinal spline from an array of points and uses a brush to fill the interior of the spline.
        
        ;~ FillClosedCurve()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillClosedCurve method creates a closed cardinal spline from an array of points and uses a brush to fill, according to a specified mode, the interior of the spline.
        
        ;~ FillClosedCurve()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillClosedCurve method creates a closed cardinal spline from an array of points and uses a brush to fill the interior of the spline.
        
        ;~ FillClosedCurve()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillClosedCurve method creates a closed cardinal spline from an array of points and uses a brush to fill, according to a specified mode, the interior of the spline.
        
        ;~ FillEllipse()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillEllipse method uses a brush to fill the interior of an ellipse that is specified by a rectangle.
        
        ;~ FillEllipse()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillEllipse method uses a brush to fill the interior of an ellipse that is specified by a rectangle.
        
        ;~ FillEllipse()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillEllipse method uses a brush to fill the interior of an ellipse that is specified by coordinates and dimensions.
        
        ;~ FillEllipse()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillEllipse method uses a brush to fill the interior of an ellipse that is specified by coordinates and dimensions.
        
        ;~ FillPath()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillPath method uses a brush to fill the interior of a path. If a figure in the path is not closed, this method treats the nonclosed figure as if it were closed by a straight line that connects the figure's starting and ending points.
        
        ;~ FillPie()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillPie method uses a brush to fill the interior of a pie.
        
        ;~ FillPie()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillPie method uses a brush to fill the interior of a pie.
        
        ;~ FillPie()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillPie method uses a brush to fill the interior of a pie.
        
        ;~ FillPie()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillPie method uses a brush to fill the interior of a pie.
        
        ;~ FillPolygon()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillPolygon method uses a brush to fill the interior of a polygon.
        
        ;~ FillPolygon()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillPolygon method uses a brush to fill the interior of a polygon.
        
        ;~ FillPolygon()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillPolygon method uses a brush to fill the interior of a polygon.
        
        ;~ FillPolygon()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillPolygon method uses a brush to fill the interior of a polygon.
        
        ;~ FillRectangle()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillRectangle method uses a brush to fill the interior of a rectangle.
        
        ;~ FillRectangle()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillRectangle method uses a brush to fill the interior of a rectangle.
        
        ;~ FillRectangle()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillRectangle method uses a brush to fill the interior of a rectangle.
        
        ;~ FillRectangle()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillRectangle method uses a brush to fill the interior of a rectangle.
        
        ;~ FillRectangles()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillRectangles method uses a brush to fill the interior of a sequence of rectangles.
        
        ;~ FillRectangles()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillRectangles method uses a brush to fill the interior of a sequence of rectangles.
        
        ;~ FillRegion()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FillRegion method uses a brush to fill a specified region.
        
        ;~ Flush()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::Flush method flushes all pending graphics operations.
        
        ;~ FromHDC()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FromHDC method creates a Graphics object that is associated with a specified device context.
        
        ;~ FromHDC()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FromHDC method creates a Graphics object that is associated with a specified device context and a specified device.
        
        ;~ FromHWND()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FromHWND method creates a Graphicsobject that is associated with a specified window.
        
        ;~ FromImage()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::FromImage method creates a Graphicsobject that is associated with a specified Image object.
        
        ;~ GetClip()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::GetClip method gets the clipping region of this Graphics object.
        
        ;~ GetClipBounds()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::GetClipBounds method gets a rectangle that encloses the clipping region of this Graphics object.
        
        ;~ GetClipBounds()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::GetClipBounds method gets a rectangle that encloses the clipping region of this Graphics object.
        
        ;~ GetCompositingMode()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::GetCompositingMode method gets the compositing mode currently set for this Graphics object.
        
        ;~ GetCompositingQuality()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::GetCompositingQuality method gets the compositing quality currently set for this Graphics object.
        
        ;~ GetDpiX()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::GetDpiX method gets the horizontal resolution, in dots per inch, of the display device associated with this Graphics object.
        
        ;~ GetDpiY()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::GetDpiY method gets the vertical resolution, in dots per inch, of the display device associated with this Graphics object.
        
        ;~ GetHalftonePalette()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::GetHalftonePalette method gets a Windows halftone palette.
        
        ;~ GetHDC()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::GetHDC method gets a handle to the device context associated with this Graphics object.
        
        ;~ GetInterpolationMode()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::GetInterpolationMode method gets the interpolation mode currently set for this Graphics object. The interpolation mode determines the algorithm that is used when images are scaled or rotated.
        
        ;~ GetLastStatus()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::GetLastStatus method returns a value that indicates the nature of this Graphics object's most recent method failure.
        
        ;~ GetNearestColor()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::GetNearestColor method gets the nearest color to the color that is passed in. This method works on 8-bits per pixel or lower display devices for which there is an 8-bit color palette.
        
        ;~ GetPageScale()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::GetPageScale method gets the scaling factor currently set for the page transformation of this Graphics object. The page transformation converts page coordinates to device coordinates.
        
        ;~ GetPageUnit()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::GetPageUnit method gets the unit of measure currently set for this Graphics object.
        
        ;~ GetPixelOffsetMode()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::GetPixelOffsetMode method gets the pixel offset mode currently set for this Graphics object.
        
        ;~ GetRenderingOrigin()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::GetRenderingOrigin method gets the rendering origin currently set for this Graphics object.
        
        ;~ GetSmoothingMode()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::GetSmoothingMode method determines whether smoothing (antialiasing) is applied to the Graphics object.
        
        ;~ GetTextContrast()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::GetTextContrast method gets the contrast value currently set for this Graphics object. The contrast value is used for antialiasing text.
        
        ;~ GetTextRenderingHint()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::GetTextRenderingHint method returns the text rendering mode currently set for this Graphics object.
        
        ;~ GetTransform()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::GetTransform method gets the world transformation matrix of this Graphics object.
        
        ;~ GetVisibleClipBounds()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::GetVisibleClipBounds method gets a rectangle that encloses the visible clipping region of this Graphics object.
        
        ;~ GetVisibleClipBounds()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::GetVisibleClipBounds method gets a rectangle that encloses the visible clipping region of this Graphics object.
        
        ;~ Graphics()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ This topic lists the constructors of the Graphics class. For a complete class listing, see Graphics Class.
        
        ;~ Graphics()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ This topic lists the constructors of the Graphics class. For a complete class listing, see Graphics Class.
        
        ;~ Graphics()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ Creates a Graphics::Graphics object that is associated with a specified device context.
        
        ;~ Graphics()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ Creates a Graphics::Graphics object that is associated with a specified device context and a specified device.
        
        ;~ Graphics()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ Creates a Graphics::Graphics object that is associated with a specified window.
        
        ;~ Graphics()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ Creates a Graphics::Graphics object that is associated with an Image object.
        
        ;~ IntersectClip()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::IntersectClip method updates the clipping region of this Graphics object to the portion of the specified rectangle that intersects with the current clipping region of this Graphics object.
        
        ;~ IntersectClip()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::IntersectClip method updates the clipping region of this Graphics object.
        
        ;~ IntersectClip()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::IntersectClip method updates the clipping region of this Graphics object to the portion of the specified region that intersects with the current clipping region of this Graphics object.
        
        ;~ IsClipEmpty()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::IsClipEmpty method determines whether the clipping region of this Graphics object is empty.
        
        ;~ IsVisible()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::IsVisible method determines whether the specified point is inside the visible clipping region of this Graphics object.
        
        ;~ IsVisible()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::IsVisible method determines whether the specified point is inside the visible clipping region of this Graphics object.
        
        ;~ IsVisible()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::IsVisible method determines whether the specified rectangle intersects the visible clipping region of this Graphics object.
        
        ;~ IsVisible()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::IsVisible method determines whether the specified rectangle intersects the visible clipping region of this Graphics object.
        
        ;~ IsVisible()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::IsVisible method determines whether the specified point is inside the visible clipping region of this Graphics object.
        
        ;~ IsVisible()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::IsVisible method determines whether the specified rectangle intersects the visible clipping region of this Graphics object.
        
        ;~ IsVisible()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::IsVisible method determines whether the specified point is inside the visible clipping region of this Graphics object.
        
        ;~ IsVisible()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::IsVisible method determines whether the specified rectangle intersects the visible clipping region of this Graphics object.
        
        ;~ IsVisibleClipEmpty()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::IsVisibleClipEmpty method determines whether the visible clipping region of this Graphics object is empty. The visible clipping region is the intersection of the clipping region of this Graphics object and the clipping region of the window.
        
        ;~ MeasureCharacterRanges()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::MeasureCharacterRanges method gets a set of regions each of which bounds a range of character positions within a string.
        
        ;~ MeasureDriverString()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::MeasureDriverString method measures the bounding box for the specified characters and their corresponding positions.
        
        ;~ MeasureString()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::MeasureString method measures the extent of the string in the specified font, format, and layout rectangle.
        
        ;~ MeasureString()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::MeasureString method measures the extent of the string in the specified font and layout rectangle.
        
        ;~ MeasureString()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::MeasureString method measures the extent of the string in the specified font, format, and layout rectangle.
        
        ;~ MeasureString()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::MeasureString method measures the extent of the string in the specified font and layout rectangle.
        
        ;~ MeasureString()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::MeasureString method measures the extent of the string in the specified font, format, and layout rectangle.
        
        ;~ MultiplyTransform()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::MultiplyTransform method updates this Graphics object's world transformation matrix with the product of itself and another matrix.
        
        ;~ ReleaseHDC()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::ReleaseHDC method releases a device context handle obtained by a previous call to the Graphics::GetHDC method of this Graphics object.
        
        ;~ ResetClip()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::ResetClip method sets the clipping region of this Graphics object to an infinite region.
        
        ;~ ResetTransform()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::ResetTransform method sets the world transformation matrix of this Graphics object to the identity matrix.
        
        ;~ Restore()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::Restore method sets the state of this Graphics object to the state stored by a previous call to the Graphics::Save method of this Graphics object.
        
        ;~ RotateTransform()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::RotateTransform method updates the world transformation matrix of this Graphics object with the product of itself and a rotation matrix.
        
        ;~ Save()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::Save method saves the current state (transformations, clipping region, and quality settings) of this Graphics object. You can restore the state later by calling the Graphics::Restore method.
        
        ;~ ScaleTransform()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::ScaleTransform method updates this Graphics object's world transformation matrix with the product of itself and a scaling matrix.
        
        ;~ SetAbort()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ Not used in Windows GDI+ versions 1.0 and 1.1.
        
        ;~ SetClip()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::SetClip method updates the clipping region of this Graphics object.
        
        ;~ SetClip()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::SetClip method updates the clipping region of this Graphics object to a region that is the combination of itself and the region specified by a graphics path.
        
        ;~ SetClip()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::SetClip method updates the clipping region of this Graphics object to a region that is the combination of itself and a rectangle.
        
        ;~ SetClip()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::SetClip method updates the clipping region of this Graphics object to a region that is the combination of itself and a rectangle.
        
        ;~ SetClip()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::SetClip method updates the clipping region of this Graphics object to a region that is the combination of itself and the region specified by a Region object.
        
        ;~ SetClip()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::SetClip method updates the clipping region of this Graphics object to a region that is the combination of itself and a Windows Graphics Device Interface (GDI) region.
        
        ;~ SetCompositingMode()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::SetCompositingMode method sets the compositing mode of this Graphics object.
        
        ;~ SetCompositingQuality()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::SetCompositingQuality method sets the compositing quality of this Graphics object.
        
        ;~ SetInterpolationMode()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::SetInterpolationMode method sets the interpolation mode of this Graphics object. The interpolation mode determines the algorithm that is used when images are scaled or rotated.
        
        ;~ SetPageScale()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::SetPageScale method sets the scaling factor for the page transformation of this Graphics object. The page transformation converts page coordinates to device coordinates.
        
        ;~ SetPageUnit()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::SetPageUnit method sets the unit of measure for this Graphics object. The page unit belongs to the page transformation, which converts page coordinates to device coordinates.
        
        ;~ SetPixelOffsetMode()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::SetPixelOffsetMode method sets the pixel offset mode of this Graphics object.
        
        ;~ SetRenderingOrigin()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::SetRenderingOrigin method sets the rendering origin of this Graphics object. The rendering origin is used to set the dither origin for 8-bits-per-pixel and 16-bits-per-pixel dithering and is also used to set the origin for hatch brushes.
        
        ;~ SetSmoothingMode()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::SetSmoothingMode method sets the rendering quality of the Graphics object.
        
        ;~ SetTextContrast()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::SetTextContrast method sets the contrast value of this Graphics object. The contrast value is used for antialiasing text.
        
        ;~ SetTextRenderingHint()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::SetTextRenderingHint method sets the text rendering mode of this Graphics object.
        
        ;~ SetTransform()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::SetTransform method sets the world transformation of this Graphics object.
        
        ;~ TransformPoints()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::TransformPoints method converts an array of points from one coordinate space to another. The conversion is based on the current world and page transformations of this Graphics object.
        
        ;~ TransformPoints()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::TransformPoints method converts an array of points from one coordinate space to another. The conversion is based on the current world and page transformations of this Graphics object.
        
        ;~ TranslateClip()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::TranslateClip method translates the clipping region of this Graphics object.
        
        ;~ TranslateClip()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::TranslateClip method translates the clipping region of this Graphics object.
        
        ;~ TranslateTransform()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ The Graphics::TranslateTransform method updates this Graphics object's world transformation matrix with the product of itself and a translation matrix.
    }

    ;####################################################################################################################
    ;  Enumerations (Enum)                                                                                              |
    ;####################################################################################################################
    Class enum
    {
        Static  ImageType := {0:"ImageTypeUnknown"
                             ,1:"ImageTypeBitmap"
                             ,2:"ImageTypeMetafile"}
        
    }
    
}

/*
    Log:
    20210729
        Startup and shutdown are working
        Added image class
        Image.FromFile() working
    
*/

















/*
    Class AdjustableArrowCap
    {
        ;####################################
        ; Call          AdjustableArrowCap(REAL height, REAL width, BOOL isFilled, GpAdjustableArrowCap **cap)
        ; Description   Creates an adjustable arrow line cap with the specified height and width. The arrow line cap can be filled or nonfilled. The middle inset defaults to zero.
        ;          
        ; Params        REAL height, REAL width, BOOL isFilled, GpAdjustableArrowCap **cap
        ;          
        ; Return        Status
        ;______________________________________
        AdjustableArrowCap(REAL height, REAL width, BOOL isFilled, GpAdjustableArrowCap **cap)
        {
            status := GdipCreateAdjustableArrowCap(REAL height, REAL width, BOOL isFilled, GpAdjustableArrowCap **cap)
            Return status
        }
        
        ;####################################
        ; Call          SetHeight(GpAdjustableArrowCap* cap, REAL height)
        ; Description   The AdjustableArrowCap::SetHeight method sets the height of the arrow cap. This is the distance from the base of the arrow to its vertex.
        ;          
        ; Params        GpAdjustableArrowCap* cap, REAL height
        ;          
        ; Return        Status
        ;______________________________________
        SetHeight(GpAdjustableArrowCap* cap, REAL height)
        {
            status := GdipSetAdjustableArrowCapHeight(GpAdjustableArrowCap* cap, REAL height)
            Return status
        }
        
        ;####################################
        ; Call          GetHeight(GpAdjustableArrowCap* cap, REAL* height)
        ; Description   The AdjustableArrowCap::GetHeight method gets the height of the arrow cap. The height is the distance from the base of the arrow to its vertex.
        ;          
        ; Params        GpAdjustableArrowCap* cap, REAL* height
        ;          
        ; Return        Status
        ;______________________________________
        GetHeight(GpAdjustableArrowCap* cap, REAL* height)
        {
            status := GdipGetAdjustableArrowCapHeight(GpAdjustableArrowCap* cap, REAL* height)
            Return status
        }
        
        ;####################################
        ; Call          SetWidth(GpAdjustableArrowCap* cap, REAL width)
        ; Description   The AdjustableArrowCap::SetWidth method sets the width of the arrow cap. The width is the distance between the endpoints of the base of the arrow.
        ;          
        ; Params        GpAdjustableArrowCap* cap, REAL width
        ;          
        ; Return        Status
        ;______________________________________
        SetWidth(GpAdjustableArrowCap* cap, REAL width)
        {
            status := GdipSetAdjustableArrowCapWidth(GpAdjustableArrowCap* cap, REAL width)
            Return status
        }
        
        ;####################################
        ; Call          GetWidth(GpAdjustableArrowCap* cap, REAL* width)
        ; Description   The AdjustableArrowCap::GetWidth method gets the width of the arrow cap. The width is the distance between the endpoints of the base of the arrow.
        ;          
        ; Params        GpAdjustableArrowCap* cap, REAL* width
        ;          
        ; Return        Status
        ;______________________________________
        GetWidth(GpAdjustableArrowCap* cap, REAL* width)
        {
            status := GdipGetAdjustableArrowCapWidth(GpAdjustableArrowCap* cap, REAL* width)
            Return status
        }
        
        ;####################################
        ; Call          SetMiddleInset(GpAdjustableArrowCap* cap, REAL middleInset)
        ; Description   The AdjustableArrowCap::SetMiddleInset method sets the number of units that the midpoint of the base shifts towards the vertex.
        ;          
        ; Params        GpAdjustableArrowCap* cap, REAL middleInset
        ;          
        ; Return        Status
        ;______________________________________
        SetMiddleInset(GpAdjustableArrowCap* cap, REAL middleInset)
        {
            status := GdipSetAdjustableArrowCapMiddleInset(GpAdjustableArrowCap* cap, REAL middleInset)
            Return status
        }
        
        ;####################################
        ; Call          GetMiddleInset(GpAdjustableArrowCap* cap, REAL* middleInset)
        ; Description   The AdjustableArrowCap::GetMiddleInset method gets the value of the inset. The middle inset is the number of units that the midpoint of the base shifts towards the vertex.
        ;          
        ; Params        GpAdjustableArrowCap* cap, REAL* middleInset
        ;          
        ; Return        Status
        ;______________________________________
        GetMiddleInset(GpAdjustableArrowCap* cap, REAL* middleInset)
        {
            status := GdipGetAdjustableArrowCapMiddleInset(GpAdjustableArrowCap* cap, REAL* middleInset)
            Return status
        }
        
        ;####################################
        ; Call          SetFillState(GpAdjustableArrowCap* cap, BOOL fillState)
        ; Description   The AdjustableArrowCap::SetFillState method sets the fill state of the arrow cap. If the arrow cap is not filled, only the outline is drawn.
        ;          
        ; Params        GpAdjustableArrowCap* cap, BOOL fillState
        ;          
        ; Return        Status
        ;______________________________________
        SetFillState(GpAdjustableArrowCap* cap, BOOL fillState)
        {
            status := GdipSetAdjustableArrowCapFillState(GpAdjustableArrowCap* cap, BOOL fillState)
            Return status
        }
        
        ;####################################
        ; Call          IsFilled(GpAdjustableArrowCap* cap, BOOL* fillState)
        ; Description   The AdjustableArrowCap::IsFilled method determines whether the arrow cap is filled.
        ;          
        ; Params        GpAdjustableArrowCap* cap, BOOL* fillState
        ;          
        ; Return        Status
        ;______________________________________
        IsFilled(GpAdjustableArrowCap* cap, BOOL* fillState)
        {
            status := GdipGetAdjustableArrowCapFillState(GpAdjustableArrowCap* cap, BOOL* fillState)
            Return status
        }
    }
    
    
    Class Bitmap
    {
        ;####################################
        ; Call          Bitmap(IStream* stream, GpBitmap **bitmap)
        ; Description   Creates a Bitmap::Bitmap object based on a stream. This function does not use Image Color Management (ICM). It is called when the useEmbeddedColorManagement parameter of the Bitmap::Bitmap constructor is set to FALSE.
        ;          
        ; Params        IStream* stream, GpBitmap **bitmap
        ;          
        ; Return        Status
        ;______________________________________
        Bitmap(IStream* stream, GpBitmap **bitmap)
        {
            status := GdipCreateBitmapFromStream(IStream* stream, GpBitmap **bitmap)
            Return status
        }
        
        ;####################################
        ; Call          Bitmap(GDIPCONST WCHAR* filename, GpBitmap **bitmap)
        ; Description   Creates a Bitmap::Bitmap object based on an image file. This function does not use ICM. It is called when the useEmbeddedColorManagement parameter of the Bitmap::Bitmap constructor is set to FALSE.
        ;          
        ; Params        GDIPCONST WCHAR* filename, GpBitmap **bitmap
        ;          
        ; Return        Status
        ;______________________________________
        Bitmap(GDIPCONST WCHAR* filename, GpBitmap **bitmap)
        {
            status := GdipCreateBitmapFromFile(GDIPCONST WCHAR* filename, GpBitmap **bitmap)
            Return status
        }
        
        ;####################################
        ; Call          Bitmap(IStream* stream, GpBitmap **bitmap)
        ; Description   Creates a Bitmap::Bitmap object based on a stream. This function uses ICM. It is called when the useEmbeddedColorManagement parameter of the Bitmap::Bitmap constructor is set to TRUE.
        ;          
        ; Params        IStream* stream, GpBitmap **bitmap
        ;          
        ; Return        Status
        ;______________________________________
        Bitmap(IStream* stream, GpBitmap **bitmap)
        {
            status := GdipCreateBitmapFromStreamICM(IStream* stream, GpBitmap **bitmap)
            Return status
        }
        
        ;####################################
        ; Call          Bitmap(GDIPCONST WCHAR* filename, GpBitmap **bitmap)
        ; Description   Creates a Bitmap::Bitmap object based on an image file. This function uses ICM. It is called when the useEmbeddedColorManagement parameter of the Bitmap::Bitmap constructor is set to TRUE.
        ;          
        ; Params        GDIPCONST WCHAR* filename, GpBitmap **bitmap
        ;          
        ; Return        Status
        ;______________________________________
        Bitmap(GDIPCONST WCHAR* filename, GpBitmap **bitmap)
        {
            status := GdipCreateBitmapFromFileICM(GDIPCONST WCHAR* filename, GpBitmap **bitmap)
            Return status
        }
        
        ;####################################
        ; Call          Bitmap(INT width, INT height, INT stride, PixelFormat format, BYTE* scan0, GpBitmap** bitmap)
        ; Description   Creates a Bitmap::Bitmap object based on an array of bytes along with size and format information.
        ;          
        ; Params        INT width, INT height, INT stride, PixelFormat format, BYTE* scan0, GpBitmap** bitmap
        ;          
        ; Return        Status
        ;______________________________________
        Bitmap(INT width, INT height, INT stride, PixelFormat format, BYTE* scan0, GpBitmap** bitmap)
        {
            status := GdipCreateBitmapFromScan0(INT width, INT height, INT stride, PixelFormat format, BYTE* scan0, GpBitmap** bitmap)
            Return status
        }
        
        ;####################################
        ; Call          Bitmap(INT width, INT height, GpGraphics* target, GpBitmap** bitmap)
        ; Description   Creates a Bitmap::Bitmap object based on a Graphics object, a width, and a height.
        ;          
        ; Params        INT width, INT height, GpGraphics* target, GpBitmap** bitmap
        ;          
        ; Return        Status
        ;______________________________________
        Bitmap(INT width, INT height, GpGraphics* target, GpBitmap** bitmap)
        {
            status := GdipCreateBitmapFromGraphics(INT width, INT height, GpGraphics* target, GpBitmap** bitmap)
            Return status
        }
        
        ;####################################
        ; Call          Bitmap(IDirectDrawSurface7* surface, GpBitmap** bitmap)
        ; Description   Creates a Bitmap::Bitmap object based on a DirectDraw surface. The Bitmap::Bitmap object maintains a reference to the DirectDraw surface until the Bitmap::Bitmap object is deleted or goes out of scope.
        ;          
        ; Params        IDirectDrawSurface7* surface, GpBitmap** bitmap
        ;          
        ; Return        Status
        ;______________________________________
        Bitmap(IDirectDrawSurface7* surface, GpBitmap** bitmap)
        {
            status := GdipCreateBitmapFromDirectDrawSurface(IDirectDrawSurface7* surface, GpBitmap** bitmap)
            Return status
        }
        
        ;####################################
        ; Call          Bitmap(GDIPCONST BITMAPINFO* gdiBitmapInfo, VOID* gdiBitmapData, GpBitmap** bitmap)
        ; Description   Creates a Bitmap::Bitmap object based on a BITMAPINFO structure and an array of pixel data.
        ;          
        ; Params        GDIPCONST BITMAPINFO* gdiBitmapInfo, VOID* gdiBitmapData, GpBitmap** bitmap
        ;          
        ; Return        Status
        ;______________________________________
        Bitmap(GDIPCONST BITMAPINFO* gdiBitmapInfo, VOID* gdiBitmapData, GpBitmap** bitmap)
        {
            status := GdipCreateBitmapFromGdiDib(GDIPCONST BITMAPINFO* gdiBitmapInfo, VOID* gdiBitmapData, GpBitmap** bitmap)
            Return status
        }
        
        ;####################################
        ; Call          Bitmap(HBITMAP hbm, HPALETTE hpal, GpBitmap** bitmap)
        ; Description   Creates a Bitmap::Bitmap object based on a handle to a Windows Windows Graphics Device Interface (GDI) bitmap and a handle to a GDI palette.
        ;          
        ; Params        HBITMAP hbm, HPALETTE hpal, GpBitmap** bitmap
        ;          
        ; Return        Status
        ;______________________________________
        Bitmap(HBITMAP hbm, HPALETTE hpal, GpBitmap** bitmap)
        {
            status := GdipCreateBitmapFromHBITMAP(HBITMAP hbm, HPALETTE hpal, GpBitmap** bitmap)
            Return status
        }
        
        ;####################################
        ; Call          GetHBITMAP(GpBitmap* bitmap, HBITMAP* hbmReturn, ARGB background)
        ; Description   The Bitmap::GetHBITMAP method creates a GDI bitmap from this Bitmap object.
        ;          
        ; Params        GpBitmap* bitmap, HBITMAP* hbmReturn, ARGB background
        ;          
        ; Return        Status
        ;______________________________________
        GetHBITMAP(GpBitmap* bitmap, HBITMAP* hbmReturn, ARGB background)
        {
            status := GdipCreateHBITMAPFromBitmap(GpBitmap* bitmap, HBITMAP* hbmReturn, ARGB background)
            Return status
        }
        
        ;####################################
        ; Call          Bitmap(HICON hicon, GpBitmap** bitmap)
        ; Description   Creates a Bitmap object based on an icon.
        ;          
        ; Params        HICON hicon, GpBitmap** bitmap
        ;          
        ; Return        Status
        ;______________________________________
        Bitmap(HICON hicon, GpBitmap** bitmap)
        {
            status := GdipCreateBitmapFromHICON(HICON hicon, GpBitmap** bitmap)
            Return status
        }
        
        ;####################################
        ; Call          GetHICON(GpBitmap* bitmap, HICON* hbmReturn)
        ; Description   The Bitmap::GetHICON method creates an icon from this Bitmap object.
        ;          
        ; Params        GpBitmap* bitmap, HICON* hbmReturn
        ;          
        ; Return        Status
        ;______________________________________
        GetHICON(GpBitmap* bitmap, HICON* hbmReturn)
        {
            status := GdipCreateHICONFromBitmap(GpBitmap* bitmap, HICON* hbmReturn)
            Return status
        }
        
        ;####################################
        ; Call          Bitmap(HINSTANCE hInstance, GDIPCONST WCHAR* lpBitmapName, GpBitmap** bitmap)
        ; Description   Creates a Bitmap::Bitmap object based on an application or DLL instance handle and the name of a bitmap resource.
        ;          
        ; Params        HINSTANCE hInstance, GDIPCONST WCHAR* lpBitmapName, GpBitmap** bitmap
        ;          
        ; Return        Status
        ;______________________________________
        Bitmap(HINSTANCE hInstance, GDIPCONST WCHAR* lpBitmapName, GpBitmap** bitmap)
        {
            status := GdipCreateBitmapFromResource(HINSTANCE hInstance, GDIPCONST WCHAR* lpBitmapName, GpBitmap** bitmap)
            Return status
        }
        
        ;####################################
        ; Call          Clone(REAL x, REAL y, REAL width, REAL height, PixelFormat format, GpBitmap *srcBitmap, GpBitmap **dstBitmap)
        ; Description   The Bitmap::Clone method creates a new Bitmap object by copying a portion of this bitmap.
        ;          
        ; Params        REAL x, REAL y, REAL width, REAL height, PixelFormat format, GpBitmap *srcBitmap, GpBitmap **dstBitmap
        ;          
        ; Return        Status
        ;______________________________________
        Clone(REAL x, REAL y, REAL width, REAL height, PixelFormat format, GpBitmap *srcBitmap, GpBitmap **dstBitmap)
        {
            status := GdipCloneBitmapArea(REAL x, REAL y, REAL width, REAL height, PixelFormat format, GpBitmap *srcBitmap, GpBitmap **dstBitmap)
            Return status
        }
        
        ;####################################
        ; Call          Clone(INT x, INT y, INT width, INT height, PixelFormat format, GpBitmap *srcBitmap, GpBitmap **dstBitmap)
        ; Description   The Bitmap::Clone method creates a new Bitmap object by copying a portion of this bitmap.
        ;          
        ; Params        INT x, INT y, INT width, INT height, PixelFormat format, GpBitmap *srcBitmap, GpBitmap **dstBitmap
        ;          
        ; Return        Status
        ;______________________________________
        Clone(INT x, INT y, INT width, INT height, PixelFormat format, GpBitmap *srcBitmap, GpBitmap **dstBitmap)
        {
            status := GdipCloneBitmapAreaI(INT x, INT y, INT width, INT height, PixelFormat format, GpBitmap *srcBitmap, GpBitmap **dstBitmap)
            Return status
        }
        
        ;####################################
        ; Call          LockBits(GpBitmap* bitmap, GDIPCONST GpRect* rect, UINT flags, PixelFormat format, BitmapData* lockedBitmapData)
        ; Description   The Bitmap::LockBits method locks a rectangular portion of this bitmap and provides a temporary buffer that you can use to read or write pixel data in a specified format. Any pixel data that you write to the buffer is copied to the Bitmap object when you call Bitmap::UnlockBits.
        ;          
        ; Params        GpBitmap* bitmap, GDIPCONST GpRect* rect, UINT flags, PixelFormat format, BitmapData* lockedBitmapData
        ;          
        ; Return        Status
        ;______________________________________
        LockBits(GpBitmap* bitmap, GDIPCONST GpRect* rect, UINT flags, PixelFormat format, BitmapData* lockedBitmapData)
        {
            status := GdipBitmapLockBits(GpBitmap* bitmap, GDIPCONST GpRect* rect, UINT flags, PixelFormat format, BitmapData* lockedBitmapData)
            Return status
        }
        
        ;####################################
        ; Call          UnlockBits(GpBitmap* bitmap, BitmapData* lockedBitmapData)
        ; Description   The Bitmap::UnlockBits method unlocks a portion of this bitmap that was previously locked by a call to Bitmap::LockBits.
        ;          
        ; Params        GpBitmap* bitmap, BitmapData* lockedBitmapData
        ;          
        ; Return        Status
        ;______________________________________
        UnlockBits(GpBitmap* bitmap, BitmapData* lockedBitmapData)
        {
            status := GdipBitmapUnlockBits(GpBitmap* bitmap, BitmapData* lockedBitmapData)
            Return status
        }
        
        ;####################################
        ; Call          GetPixel(GpBitmap* bitmap, INT x, INT y, ARGB *color)
        ; Description   The Bitmap::GetPixel method gets the color of a specified pixel in this bitmap.
        ;          
        ; Params        GpBitmap* bitmap, INT x, INT y, ARGB *color
        ;          
        ; Return        Status
        ;______________________________________
        GetPixel(GpBitmap* bitmap, INT x, INT y, ARGB *color)
        {
            status := GdipBitmapGetPixel(GpBitmap* bitmap, INT x, INT y, ARGB *color)
            Return status
        }
        
        ;####################################
        ; Call          SetPixel(GpBitmap* bitmap, INT x, INT y, ARGB color)
        ; Description   The Bitmap::SetPixel method sets the color of a specified pixel in this bitmap.
        ;          
        ; Params        GpBitmap* bitmap, INT x, INT y, ARGB color
        ;          
        ; Return        Status
        ;______________________________________
        SetPixel(GpBitmap* bitmap, INT x, INT y, ARGB color)
        {
            status := GdipBitmapSetPixel(GpBitmap* bitmap, INT x, INT y, ARGB color)
            Return status
        }
        
        ;####################################
        ; Call          SetResolution(GpBitmap* bitmap, REAL xdpi, REAL ydpi)
        ; Description   The Bitmap::SetResolution method sets the resolution of this Bitmap object.
        ;          
        ; Params        GpBitmap* bitmap, REAL xdpi, REAL ydpi
        ;          
        ; Return        Status
        ;______________________________________
        SetResolution(GpBitmap* bitmap, REAL xdpi, REAL ydpi)
        {
            status := GdipBitmapSetResolution(GpBitmap* bitmap, REAL xdpi, REAL ydpi)
            Return status
        }
        
        ;####################################
        ; Call          ConvertFormat(IN GpBitmap *pInputBitmap, PixelFormat format, DitherType dithertype, PaletteType palettetype, ColorPalette *palette, REAL alphaThresholdPercent)
        ; Description   The Bitmap::ConvertFormat method converts a bitmap to a specified pixel format. The original pixel data in the bitmap is replaced by the new pixel data.
        ;          
        ; Params        IN GpBitmap *pInputBitmap, PixelFormat format, DitherType dithertype, PaletteType palettetype, ColorPalette *palette, REAL alphaThresholdPercent
        ;          
        ; Return        Status
        ;______________________________________
        ConvertFormat(IN GpBitmap *pInputBitmap, PixelFormat format, DitherType dithertype, PaletteType palettetype, ColorPalette *palette, REAL alphaThresholdPercent)
        {
            status := GdipBitmapConvertFormat(IN GpBitmap *pInputBitmap, PixelFormat format, DitherType dithertype, PaletteType palettetype, ColorPalette *palette, REAL alphaThresholdPercent)
            Return status
        }
        
        ;####################################
        ; Call          InitializePalette(OUT ColorPalette *palette, PaletteType palettetype, INT optimalColors, BOOL useTransparentColor, GpBitmap *bitmap)
        ; Description   The Bitmap::InitializePalette method initializes a standard, optimal, or custom color palette.
        ;          
        ; Params        OUT ColorPalette *palette, PaletteType palettetype, INT optimalColors, BOOL useTransparentColor, GpBitmap *bitmap
        ;          
        ; Return        Status
        ;______________________________________
        InitializePalette(OUT ColorPalette *palette, PaletteType palettetype, INT optimalColors, BOOL useTransparentColor, GpBitmap *bitmap)
        {
            status := GdipInitializePalette(OUT ColorPalette *palette, PaletteType palettetype, INT optimalColors, BOOL useTransparentColor, GpBitmap *bitmap)
            Return status
        }
        
        ;####################################
        ; Call          ApplyEffect(GpBitmap* bitmap, CGpEffect *effect, RECT *roi, BOOL useAuxData, VOID **auxData, INT *auxDataSize)
        ; Description   The Bitmap::ApplyEffect method alters this Bitmap object by applying a specified effect.
        ;          
        ; Params        GpBitmap* bitmap, CGpEffect *effect, RECT *roi, BOOL useAuxData, VOID **auxData, INT *auxDataSize
        ;          
        ; Return        Status
        ;______________________________________
        ApplyEffect(GpBitmap* bitmap, CGpEffect *effect, RECT *roi, BOOL useAuxData, VOID **auxData, INT *auxDataSize)
        {
            status := GdipBitmapApplyEffect(GpBitmap* bitmap, CGpEffect *effect, RECT *roi, BOOL useAuxData, VOID **auxData, INT *auxDataSize)
            Return status
        }
        
        ;####################################
        ; Call          ApplyEffect(GpBitmap **inputBitmaps, INT numInputs, CGpEffect *effect, RECT *roi, RECT *outputRect, GpBitmap **outputBitmap, BOOL useAuxData, VOID **auxData, INT *auxDataSize)
        ; Description   The Bitmap::ApplyEffect method creates a new Bitmap object by applying a specified effect to an existing Bitmap object.
        ;          
        ; Params        GpBitmap **inputBitmaps, INT numInputs, CGpEffect *effect, RECT *roi, RECT *outputRect, GpBitmap **outputBitmap, BOOL useAuxData, VOID **auxData, INT *auxDataSize
        ;          
        ; Return        Status
        ;______________________________________
        ApplyEffect(GpBitmap **inputBitmaps, INT numInputs, CGpEffect *effect, RECT *roi, RECT *outputRect, GpBitmap **outputBitmap, BOOL useAuxData, VOID **auxData, INT *auxDataSize)
        {
            status := GdipBitmapCreateApplyEffect(GpBitmap **inputBitmaps, INT numInputs, CGpEffect *effect, RECT *roi, RECT *outputRect, GpBitmap **outputBitmap, BOOL useAuxData, VOID **auxData, INT *auxDataSize)
            Return status
        }
        
        ;####################################
        ; Call          GetHistogram(GpBitmap* bitmap, IN HistogramFormat format, IN UINT NumberOfEntries, OUT UINT *channel0, OUT UINT *channel1, OUT UINT *channel2, OUT UINT *channel3)
        ; Description   The Bitmap::GetHistogram method returns one or more histograms for specified color channels of this Bitmap object.
        ;          
        ; Params        GpBitmap* bitmap, IN HistogramFormat format, IN UINT NumberOfEntries, OUT UINT *channel0, OUT UINT *channel1, OUT UINT *channel2, OUT UINT *channel3
        ;          
        ; Return        Status
        ;______________________________________
        GetHistogram(GpBitmap* bitmap, IN HistogramFormat format, IN UINT NumberOfEntries, OUT UINT *channel0, OUT UINT *channel1, OUT UINT *channel2, OUT UINT *channel3)
        {
            status := GdipBitmapGetHistogram(GpBitmap* bitmap, IN HistogramFormat format, IN UINT NumberOfEntries, OUT UINT *channel0, OUT UINT *channel1, OUT UINT *channel2, OUT UINT *channel3)
            Return status
        }
        
        ;####################################
        ; Call          GetHistogramSize(IN HistogramFormat format, OUT UINT *NumberOfEntries)
        ; Description   The Bitmap::GetHistogramSize returns the number of elements (in an array of UINTs) that you must allocate before you call the Bitmap::GetHistogram method of a Bitmap object.
        ;          
        ; Params        IN HistogramFormat format, OUT UINT *NumberOfEntries
        ;          
        ; Return        Status
        ;______________________________________
        GetHistogramSize(IN HistogramFormat format, OUT UINT *NumberOfEntries)
        {
            status := GdipBitmapGetHistogramSize(IN HistogramFormat format, OUT UINT *NumberOfEntries)
            Return status
        }
        
        ;####################################
        ; Call          Effect(const GUID guid, CGpEffect **effect)
        ; Description   The constructors of all descendants of the Effect class call GdipCreateEffect. For example, the Blur constructor makes the following call: GdipCreateEffect(BlurEffectGuid, &nativeEffect); BlurEffectGuid is a constant defined in Gdipluseffects.h.
        ;          
        ; Params        CGpEffect *effect, UINT *size
        ;          
        ; Return        Status
        ;______________________________________
        Effect(CGpEffect *effect, UINT *size)
        {
            status := GdipCreateEffect(CGpEffect *effect, UINT *size)
            Return status
        }
        
        ;####################################
        ; Call          ~Effect(CGpEffect *effect)
        ; Description   Cleans up resources used by a Bitmap object.
        ;          
        ; Params        CGpEffect *effect
        ;          
        ; Return        Status
        ;______________________________________
        ~Effect(CGpEffect *effect, UINT *size)
        {
            status := GdipCreateEffect(CGpEffect *effect, UINT *size)
            Return status
        }
        
        ;####################################
        ; Call          GetParameterSize(CGpEffect *effect, UINT *size)
        ; Description   The Effect::GetParameterSize method gets the total size, in bytes, of the parameters currently set for this Effect. The Effect::GetParameterSize method is usually called on an object that is an instance of a descendant of the Effect class.
        ;          
        ; Params        CGpEffect *effect, UINT *size
        ;          
        ; Return        Status
        ;______________________________________
        GetParameterSize(CGpEffect *effect, UINT *size)
        {
            status := GdipGetEffectParameterSize(CGpEffect *effect, UINT *size)
            Return status
        }
        
        ;####################################
        ; Call          Effect(CGpEffect *effect, const VOID *params, const UINT size)
        ; Description   Each descendant of the Effect class has a SetParameters method that calls the protected method Effect::SetParameters, which in turn calls GdipSetEffectParameters. For example, the Blur::SetParameters method makes the following call: Effect::SetParameters(parameters, size).
        ;          
        ; Params        CGpEffect *effect, const VOID *params, const UINT size
        ;          
        ; Return        Status
        ;______________________________________
        Effect(CGpEffect *effect, const VOID *params, const UINT size)
        {
            status := GdipSetEffectParameters(CGpEffect *effect, const VOID *params, const UINT size)
            Return status
        }
        
        ;####################################
        ; Call          Effect(CGpEffect *effect, UINT *size, VOID *params)
        ; Description   Each descendant of the Effect class has a SetParameters method that calls the protected method Effect::SetParameters, which in turn calls GdipSetEffectParameters. For example, the Blur::SetParameters method makes the following call: Effect::SetParameters(parameters, size).
        ;          
        ; Params        CGpEffect *effect, UINT *size, VOID *params
        ;          
        ; Return        Status
        ;______________________________________
        Effect(CGpEffect *effect, const VOID *params, const UINT size)
        {
            status := GdipGetEffectParameters(CGpEffect *effect, UINT *size, VOID *params)
            Return status
        }
        
        ;####################################
        ; Call          Effect(GpTestControlEnum control, void * param)
        ; Description   Each descendant of the Effect class has a SetParameters method that calls the protected method Effect::SetParameters, which in turn calls GdipSetEffectParameters. For example, the Blur::SetParameters method makes the following call: Effect::SetParameters(parameters, size).
        ;          
        ; Params        GpTestControlEnum control, void * param
        ;          
        ; Return        Status
        ;______________________________________
        Effect(GpTestControlEnum control, void * param)
        {
            status := GdipTestControl(GpTestControlEnum control, void * param)
            Return status
        }
    }
    
    Class Brush
    {
        ;####################################
        ; Call          Clone(GpBrush *brush, GpBrush **cloneBrush)
        ; Description   The Brush::Clone method creates a new Brush object based on this brush.
        ;          
        ; Params        GpBrush *brush, GpBrush **cloneBrush
        ;          
        ; Return        Status
        ;______________________________________
        Clone(GpBrush *brush, GpBrush **cloneBrush)
        {
            status := GdipCloneBrush(GpBrush *brush, GpBrush **cloneBrush)
            Return status
        }
        
        ;####################################
        ; Call          ~Brush(GpBrush *brush)
        ; Description   Cleans up resources used by a Brush object.
        ;          
        ; Params        GpBrush *brush
        ;          
        ; Return        Status
        ;______________________________________
        ~Brush(GpBrush *brush)
        {
            status := GdipCloneBrush(GpBrush *brush)
            Return status
        }
        
        ;####################################
        ; Call          GetType(GpBrush *brush, GpBrushType *type)
        ; Description   The Brush::GetType method gets the type of this brush.
        ;          
        ; Params        GpBrush *brush, GpBrushType *type
        ;          
        ; Return        Status
        ;______________________________________
        GetType(GpBrush *brush, GpBrushType *type)
        {
            status := GdipGetBrushType(GpBrush *brush, GpBrushType *type)
            Return status
        }
        
    }
    
    
    Class  CachedBitmap
    {
        ;####################################
        ; Call          CachedBitmap( GpBitmap *bitmap, GpGraphics *graphics, GpCachedBitmap **cachedBitmap )
        ; Description   Creates a CachedBitmap::CachedBitmap object based on a Bitmap object and a Graphics object. The cached bitmap takes the pixel data from the Bitmap object and stores it in a format that is optimized for the display device associated with the Graphics object.
        ;          
        ; Params         GpBitmap *bitmap, GpGraphics *graphics, GpCachedBitmap **cachedBitmap 
        ;          
        ; Return        Status
        ;______________________________________
        CachedBitmap( GpBitmap *bitmap, GpGraphics *graphics, GpCachedBitmap **cachedBitmap )
        {
            status := GdipCreateCachedBitmap( GpBitmap *bitmap, GpGraphics *graphics, GpCachedBitmap **cachedBitmap )
            Return status
        }
        
        ;####################################
        ; Call          ~CachedBitmap( GpCachedBitmap *cachedBitmap )
        ; Description   Creates a CachedBitmap::CachedBitmap object based on a Bitmap object and a Graphics object. The cached bitmap takes the pixel data from the Bitmap object and stores it in a format that is optimized for the display device associated with the Graphics object.
        ;          
        ; Params        GpCachedBitmap *cachedBitmap
        ;          
        ; Return        Status
        ;______________________________________
        ~CachedBitmap(GpCachedBitmap *cachedBitmap)
        {
            status := GdipDeleteCachedBitmap(GpCachedBitmap *cachedBitmap)
            Return status
        }
        
        ;####################################
        ; Call          DrawCachedBitmap( GpGraphics *graphics, GpCachedBitmap *cachedBitmap, INT x, INT y )
        ; Description   The Graphics::DrawCachedBitmap method draws the image stored in a CachedBitmap object.
        ;          
        ; Params         GpGraphics *graphics, GpCachedBitmap *cachedBitmap, INT x, INT y 
        ;          
        ; Return        Status
        ;______________________________________
        DrawCachedBitmap( GpGraphics *graphics, GpCachedBitmap *cachedBitmap, INT x, INT y )
        {
            status := GdipDrawCachedBitmap( GpGraphics *graphics, GpCachedBitmap *cachedBitmap, INT x, INT y )
            Return status
        }
        
        ;####################################
        ; Call          EmfToWmfBits( HENHMETAFILE hemf, UINT cbData16, LPBYTE pData16, INT iMapMode, INT eFlags )
        ; Description   Converts an enhanced-format metafile to a Windows Metafile Format (WMF) metafile and stores the converted records in a specified buffer.
        ;          
        ; Params         HENHMETAFILE hemf, UINT cbData16, LPBYTE pData16, INT iMapMode, INT eFlags 
        ;          
        ; Return        Status
        ;______________________________________
        EmfToWmfBits( HENHMETAFILE hemf, UINT cbData16, LPBYTE pData16, INT iMapMode, INT eFlags )
        {
            status := GdipEmfToWmfBits( HENHMETAFILE hemf, UINT cbData16, LPBYTE pData16, INT iMapMode, INT eFlags )
            Return status
        }
    }
    
    
    Class CustomLineCap
    {
        ;####################################
        ; Call          CustomLineCap(GpPath* fillPath, GpPath* strokePath, GpLineCap baseCap, REAL baseInset, GpCustomLineCap **customCap)
        ; Description   Creates a CustomLineCap::CustomLineCap object.
        ;          
        ; Params        GpPath* fillPath, GpPath* strokePath, GpLineCap baseCap, REAL baseInset, GpCustomLineCap **customCap
        ;          
        ; Return        Status
        ;______________________________________
        CustomLineCap(GpPath* fillPath, GpPath* strokePath, GpLineCap baseCap, REAL baseInset, GpCustomLineCap **customCap)
        {
            status := GdipCreateCustomLineCap(GpPath* fillPath, GpPath* strokePath, GpLineCap baseCap, REAL baseInset, GpCustomLineCap **customCap)
            Return status
        }
        
        ;####################################
        ; Call          ~CustomLineCap(GpCustomLineCap* customCap)
        ; Description   Cleans up resources used by a CustomLineCap::CustomLineCap object.
        ;          
        ; Params        GpPath* fillPath, GpPath* strokePath, GpLineCap baseCap, REAL baseInset, GpCustomLineCap **customCap
        ;          
        ; Return        Status
        ;______________________________________
        ~CustomLineCap(GpCustomLineCap* customCap)
        {
            status := GdipDeleteCustomLineCap(GpCustomLineCap* customCap)
            Return status
        }
        
        ;####################################
        ; Call          Clone(GpCustomLineCap* customCap, GpCustomLineCap** clonedCap)
        ; Description   The CustomLineCap::Clone method copies the contents of the existing object into a new CustomLineCap object.
        ;          
        ; Params        GpCustomLineCap* customCap, GpCustomLineCap** clonedCap
        ;          
        ; Return        Status
        ;______________________________________
        Clone(GpCustomLineCap* customCap, GpCustomLineCap** clonedCap)
        {
            status := GdipCloneCustomLineCap(GpCustomLineCap* customCap, GpCustomLineCap** clonedCap)
            Return status
        }
        
        ;####################################
        ; Call          GdipGetCustomLineCapType(GpCustomLineCap* customCap, CustomLineCapType* capType)
        ; Description   When this function is called, the capType parameter receives the type of the CustomLineCap specified by customCap.\nThe CustomLineCapType enumeration (defined in GdiplusEnums.h) has two elements: CustomLineCapTypeDefault = 0 and CustomLineCapTypeAdjustableArrow = 1.
        ;          
        ; Params        GpCustomLineCap* customCap, CustomLineCapType* capType
        ;          
        ; Return        Status
        ;______________________________________
        GdipGetCustomLineCapType(GpCustomLineCap* customCap, CustomLineCapType* capType)
        {
            status := GdipGetCustomLineCapType(GpCustomLineCap* customCap, CustomLineCapType* capType)
            Return status
        }
        
        ;####################################
        ; Call          SetStrokeCap(GpCustomLineCap* customCap, GpLineCap startCap, GpLineCap endCap)
        ; Description   The CustomLineCap::SetStrokeCap method sets the LineCap object used to start and end lines within the GraphicsPath object that defines this CustomLineCap object.
        ;          
        ; Params        GpCustomLineCap* customCap, GpLineCap startCap, GpLineCap endCap
        ;          
        ; Return        Status
        ;______________________________________
        SetStrokeCap(GpCustomLineCap* customCap, GpLineCap startCap, GpLineCap endCap)
        {
            status := GdipSetCustomLineCapStrokeCaps(GpCustomLineCap* customCap, GpLineCap startCap, GpLineCap endCap)
            Return status
        }
        
        ;####################################
        ; Call          GetStrokeCaps(GpCustomLineCap* customCap, GpLineCap* startCap, GpLineCap* endCap)
        ; Description   The CustomLineCap::GetStrokeCaps method gets the end cap styles for both the start line cap and the end line cap. Line caps are LineCap objects that end the individual lines within a path.
        ;          
        ; Params        GpCustomLineCap* customCap, GpLineCap* startCap, GpLineCap* endCap
        ;          
        ; Return        Status
        ;______________________________________
        GetStrokeCaps(GpCustomLineCap* customCap, GpLineCap* startCap, GpLineCap* endCap)
        {
            status := GdipGetCustomLineCapStrokeCaps(GpCustomLineCap* customCap, GpLineCap* startCap, GpLineCap* endCap)
            Return status
        }
        
        ;####################################
        ; Call          SetStrokeJoin(GpCustomLineCap* customCap, GpLineJoin lineJoin)
        ; Description   The CustomLineCap::SetStrokeJoin method sets the style of line join for the stroke. The line join specifies how two lines that intersect within the GraphicsPath object that makes up the custom line cap are joined.
        ;          
        ; Params        GpCustomLineCap* customCap, GpLineJoin lineJoin
        ;          
        ; Return        Status
        ;______________________________________
        SetStrokeJoin(GpCustomLineCap* customCap, GpLineJoin lineJoin)
        {
            status := GdipSetCustomLineCapStrokeJoin(GpCustomLineCap* customCap, GpLineJoin lineJoin)
            Return status
        }
        
        ;####################################
        ; Call          GetStrokeJoin(GpCustomLineCap* customCap, GpLineJoin* lineJoin)
        ; Description   The CustomLineCap::GetStrokeJoin method returns the style of LineJoin used to join multiple lines in the same GraphicsPath object.
        ;          
        ; Params        GpCustomLineCap* customCap, GpLineJoin* lineJoin
        ;          
        ; Return        Status
        ;______________________________________
        GetStrokeJoin(GpCustomLineCap* customCap, GpLineJoin* lineJoin)
        {
            status := GdipGetCustomLineCapStrokeJoin(GpCustomLineCap* customCap, GpLineJoin* lineJoin)
            Return status
        }
        
        ;####################################
        ; Call          SetBaseCap(GpCustomLineCap* customCap, GpLineCap baseCap)
        ; Description   The CustomLineCap::SetBaseCap method sets the LineCap that appears as part of this CustomLineCap at the end of a line.
        ;          
        ; Params        GpCustomLineCap* customCap, GpLineCap baseCap
        ;          
        ; Return        Status
        ;______________________________________
        SetBaseCap(GpCustomLineCap* customCap, GpLineCap baseCap)
        {
            status := GdipSetCustomLineCapBaseCap(GpCustomLineCap* customCap, GpLineCap baseCap)
            Return status
        }
        
        ;####################################
        ; Call          GetBaseCap(GpCustomLineCap* customCap, GpLineCap* baseCap)
        ; Description   The CustomLineCap::GetBaseCap method gets the style of the base cap. The base cap is a LineCap object used as a cap at the end of a line along with this CustomLineCap object.
        ;          
        ; Params        GpCustomLineCap* customCap, GpLineCap* baseCap
        ;          
        ; Return        Status
        ;______________________________________
        GetBaseCap(GpCustomLineCap* customCap, GpLineCap* baseCap)
        {
            status := GdipGetCustomLineCapBaseCap(GpCustomLineCap* customCap, GpLineCap* baseCap)
            Return status
        }
        
        ;####################################
        ; Call          SetBaseInset(GpCustomLineCap* customCap, REAL inset)
        ; Description   The CustomLineCap::SetBaseInset method sets the base inset value of this custom line cap. This is the distance between the end of a line and the base cap.
        ;          
        ; Params        GpCustomLineCap* customCap, REAL inset
        ;          
        ; Return        Status
        ;______________________________________
        SetBaseInset(GpCustomLineCap* customCap, REAL inset)
        {
            status := GdipSetCustomLineCapBaseInset(GpCustomLineCap* customCap, REAL inset)
            Return status
        }
        
        ;####################################
        ; Call          GetBaseInset(GpCustomLineCap* customCap, REAL* inset)
        ; Description   The CustomLineCap::GetBaseInset method gets the distance between the base cap to the start of the line.
        ;          
        ; Params        GpCustomLineCap* customCap, REAL* inset
        ;          
        ; Return        Status
        ;______________________________________
        GetBaseInset(GpCustomLineCap* customCap, REAL* inset)
        {
            status := GdipGetCustomLineCapBaseInset(GpCustomLineCap* customCap, REAL* inset)
            Return status
        }
        
        ;####################################
        ; Call          SetWidthScale(GpCustomLineCap* customCap, REAL widthScale)
        ; Description   The CustomLineCap::SetWidthScale method sets the value of the scale width. This is the amount to scale the custom line cap relative to the width of the Pen used to draw lines. The default value of 1.0 does not scale the line cap.
        ;          
        ; Params        GpCustomLineCap* customCap, REAL widthScale
        ;          
        ; Return        Status
        ;______________________________________
        SetWidthScale(GpCustomLineCap* customCap, REAL widthScale)
        {
            status := GdipSetCustomLineCapWidthScale(GpCustomLineCap* customCap, REAL widthScale)
            Return status
        }
        
        ;####################################
        ; Call          GetWidthScale(GpCustomLineCap* customCap, REAL* widthScale)
        ; Description   The CustomLineCap::GetWidthScale method gets the value of the scale width. This is the amount to scale the custom line cap relative to the width of the Pen object used to draw a line. The default value of 1.0 does not scale the line cap.
        ;          
        ; Params        GpCustomLineCap* customCap, REAL* widthScale
        ;          
        ; Return        Status
        ;______________________________________
        GetWidthScale(GpCustomLineCap* customCap, REAL* widthScale)
        {
            status := GdipGetCustomLineCapWidthScale(GpCustomLineCap* customCap, REAL* widthScale)
            Return status
        }
        
    }
    
    
    Class Font
    {
        ;####################################
        ; Call          Font(HDC hdc, GpFont **font)
        ; Description   Creates a Font object based on the GDI font object that is currently selected into a specified device context. This constructor is provided for compatibility with GDI.
        ;          
        ; Params        HDC hdc, GpFont **font 
        ;          
        ; Return        Status
        ;______________________________________
        Font(HDC hdc, GpFont **font)
        {
            status := GdipCreateFontFromDC(HDC hdc, GpFont **font)
            Return status
        }
        
        ;####################################
        ; Call          Font(HDC hdc, GDIPCONST LOGFONTA *logfont, GpFont **font)
        ; Description   Creates a Font object directly from a GDI logical font. The GDI logical font is a LOGFONTA structure, which is the one-byte character version of a logical font. This constructor is provided for compatibility with GDI.
        ;          
        ; Params        HDC hdc, GDIPCONST LOGFONTA *logfont, GpFont **font 
        ;          
        ; Return        Status
        ;______________________________________
        Font(HDC hdc, GDIPCONST LOGFONTA *logfont, GpFont **font)
        {
            status := GdipCreateFontFromLogfontA(HDC hdc, GDIPCONST LOGFONTA *logfont, GpFont **font)
            Return status
        }
        
        ;####################################
        ; Call          Font(HDC hdc, GDIPCONST LOGFONTW *logfont, GpFont **font)
        ; Description   Creates a Font object directly from a GDI logical font. The GDI logical font is a LOGFONTW structure, which is the one-byte character version of a logical font. This constructor is provided for compatibility with GDI.
        ;          
        ; Params        HDC hdc, GDIPCONST LOGFONTW *logfont, GpFont **font 
        ;          
        ; Return        Status
        ;______________________________________
        Font(HDC hdc, GDIPCONST LOGFONTW *logfont, GpFont **font)
        {
            status := GdipCreateFontFromLogfontW(HDC hdc, GDIPCONST LOGFONTW *logfont, GpFont **font)
            Return status
        }
        
        ;####################################
        ; Call          Font(GDIPCONST GpFontFamily *fontFamily, REAL emSize, INT style, Unit unit, GpFont **font)
        ; Description   Creates a Font object based on a font family, a size, a font style, a unit of measurement, and a FontCollection object.
        ;          
        ; Params        GDIPCONST GpFontFamily *fontFamily, REAL emSize, INT style, Unit unit, GpFont **font 
        ;          
        ; Return        Status
        ;______________________________________
        Font(GDIPCONST GpFontFamily *fontFamily, REAL emSize, INT style, Unit unit, GpFont **font)
        {
            status := GdipCreateFont(GDIPCONST GpFontFamily *fontFamily, REAL emSize, INT style, Unit unit, GpFont **font)
            Return status
        }
        
        ;####################################
        ; Call          Font* Clone(GpFont* font, GpFont** cloneFont)
        ; Description   Creates a new Font object based on this Font object.
        ;          
        ; Params        GpFont* font, GpFont** cloneFont
        ;          
        ; Return        Status
        ;______________________________________
        Font* Clone(GpFont* font, GpFont** cloneFont)
        {
            status := GdipCloneFont(GpFont* font, GpFont** cloneFont)
            Return status
        }

        ;####################################
        ; Call          GetFamily(GpFont *font, GpFontFamily **family)
        ; Description   Gets the font family on which this font is based.
        ;          
        ; Params        GpFont *font, GpFontFamily **family
        ;          
        ; Return        Status
        ;______________________________________
        GetFamily(GpFont *font, GpFontFamily **family)
        {
            status := GdipGetFamily(GpFont *font, GpFontFamily **family)
            Return status
        }
        
        ;####################################
        ; Call          GetStyle(GpFont *font, INT *style)
        ; Description   Gets the style of this font's typeface
        ;          
        ; Params        GpFont *font, INT *style
        ;          
        ; Return        Status
        ;______________________________________
        GetStyle(GpFont *font, INT *style)
        {
            status := GdipGetFontStyle(GpFont *font, INT *style)
            Return status
        }
        
        ;####################################
        ; Call          GetSize(GpFont *font, REAL *size)
        ; Description   Returns the font size (commonly called the em size) of this Font object. The size is in the units of this Font object.
        ;          
        ; Params        GpFont *font, REAL *size
        ;          
        ; Return        Status
        ;______________________________________
        GetSize(GpFont *font, REAL *size)
        {
            status := GdipGetFontSize(GpFont *font, REAL *size)
            Return status
        }
        
        ;####################################
        ; Call          GetUnit(GpFont *font, Unit *unit)
        ; Description   Returns the unit of measure of this Font object.
        ;          
        ; Params        GpFont *font, Unit *unit
        ;          
        ; Return        Status
        ;______________________________________
        GetUnit(GpFont *font, Unit *unit)
        {
            status := GdipGetFontUnit(GpFont *font, Unit *unit)
            Return status
        }
        
        ;####################################
        ; Call          GetHeight(GDIPCONST GpFont *font, GDIPCONST GpGraphics *graphics, REAL *height)
        ; Description   Gets the line spacing of this font in the current unit of a specified Graphics object. The line spacing is the vertical distance between the base lines of two consecutive lines of text. Thus, the line spacing includes the blank space between lines along with the height of the character itself.
        ;          
        ; Params        GDIPCONST GpFont *font, GDIPCONST GpGraphics *graphics, REAL *height
        ;          
        ; Return        Status
        ;______________________________________
        GetHeight(GDIPCONST GpFont *font, GDIPCONST GpGraphics *graphics, REAL *height)
        {
            status := GdipGetFontHeight(GDIPCONST GpFont *font, GDIPCONST GpGraphics *graphics, REAL *height)
            Return status
        }
        
        ;####################################
        ; Call          GetHeight(GDIPCONST GpFont *font, REAL dpi, REAL *height)
        ; Description   Gets the line spacing, in pixels, of this font. The line spacing is the vertical distance between the base lines of two consecutive lines of text. Thus, the line spacing includes the blank space between lines along with the height of the character itself.
        ;          
        ; Params        GDIPCONST GpFont *font, REAL dpi, REAL *height
        ;          
        ; Return        Status
        ;______________________________________
        GetHeight(GDIPCONST GpFont *font, REAL dpi, REAL *height)
        {
            status := GdipGetFontHeightGivenDPI(GDIPCONST GpFont *font, REAL dpi, REAL *height)
            Return status
        }
        
        ;####################################
        ; Call          GetLogFontA(GpFont * font, GpGraphics *graphics, LOGFONTA * logfontA)
        ; Description   Uses a LOGFONTA structure to get the attributes of this Font object.
        ;          
        ; Params        GpFont * font, GpGraphics *graphics, LOGFONTA * logfontA
        ;          
        ; Return        Status
        ;______________________________________
        GetLogFontA(GpFont * font, GpGraphics *graphics, LOGFONTA * logfontA)
        {
            status := GdipGetLogFontA(GpFont * font, GpGraphics *graphics, LOGFONTA * logfontA)
            Return status
        }
        
        ;####################################
        ; Call          GetLogFontW(GpFont * font, GpGraphics *graphics, LOGFONTW * logfontW)
        ; Description   Uses a LOGFONTW structure to get the attributes of this Font object.
        ;          
        ; Params        GpFont * font, GpGraphics *graphics, LOGFONTW * logfontW
        ;          
        ; Return        Status
        ;______________________________________
        GetLogFontW(GpFont * font, GpGraphics *graphics, LOGFONTW * logfontW)
        {
            status := GdipGetLogFontW(GpFont * font, GpGraphics *graphics, LOGFONTW * logfontW)
            Return status
        }
    }
    
    
    Class FontFamily
    {
        ;####################################
        ; Call          FontFamily(GDIPCONST WCHAR *name, GpFontCollection *fontCollection, GpFontFamily **FontFamily)
        ; Description   Creates a FontFamily::FontFamily object based on a specified font family.
        ;          
        ; Params        GDIPCONST WCHAR *name, GpFontCollection *fontCollection, GpFontFamily **FontFamily
        ;          
        ; Return        Status
        ;______________________________________
        FontFamily(GDIPCONST WCHAR *name, GpFontCollection *fontCollection, GpFontFamily **FontFamily)
        {
            status := GdipCreateFontFamilyFromName(GDIPCONST WCHAR *name, GpFontCollection *fontCollection, GpFontFamily **FontFamily)
            Return status
        }
        
        ;####################################
        ; Call          Clone(GpFontFamily *FontFamily, GpFontFamily **clonedFontFamily)
        ; Description   Creates a new FontFamily::FontFamily object based on this FontFamily::FontFamily object.
        ;          
        ; Params        GpFontFamily *FontFamily, GpFontFamily **clonedFontFamily
        ;          
        ; Return        Status
        ;______________________________________
        Clone(GpFontFamily *FontFamily, GpFontFamily **clonedFontFamily)
        {
            status := GdipCloneFontFamily(GpFontFamily *FontFamily, GpFontFamily **clonedFontFamily)
            Return status
        }
        
        ;####################################
        ; Call          GenericSansSerif(GpFontFamily **nativeFamily)
        ; Description   Gets a FontFamily::FontFamily object that specifies a generic sans serif typeface.
        ;          
        ; Params        GpFontFamily **nativeFamily
        ;          
        ; Return        Status
        ;______________________________________
        GenericSansSerif(GpFontFamily **nativeFamily)
        {
            status := GdipGetGenericFontFamilySansSerif(GpFontFamily **nativeFamily)
            Return status
        }
        
        ;####################################
        ; Call          GenericSerif(GpFontFamily **nativeFamily)
        ; Description   Gets a FontFamily::FontFamily object that specifies a generic serif typeface.
        ;          
        ; Params        GpFontFamily **nativeFamily
        ;          
        ; Return        Status
        ;______________________________________
        GenericSerif(GpFontFamily **nativeFamily)
        {
            status := GdipGetGenericFontFamilySerif(GpFontFamily **nativeFamily)
            Return status
        }
        
        ;####################################
        ; Call          GenericMonospace(GpFontFamily **nativeFamily)
        ; Description   Gets a FontFamily::FontFamily object that specifies a generic monospace typeface.
        ;          
        ; Params        GpFontFamily **nativeFamily
        ;          
        ; Return        Status
        ;______________________________________
        GenericMonospace(GpFontFamily **nativeFamily)
        {
            status := GdipGetGenericFontFamilyMonospace(GpFontFamily **nativeFamily)
            Return status
        }
        
        ;####################################
        ; Call          GetFamilyName(GDIPCONST GpFontFamily *family, WCHAR name[LF_FACESIZE], LANGID language)
        ; Description   Gets the name of this font family.
        ;          
        ; Params        GDIPCONST GpFontFamily *family, WCHAR name[LF_FACESIZE], LANGID language 
        ;          
        ; Return        Status
        ;______________________________________
        GetFamilyName(GDIPCONST GpFontFamily *family, WCHAR name[LF_FACESIZE], LANGID language)
        {
            status := GdipGetFamilyName( GDIPCONST GpFontFamily *family, WCHAR name[LF_FACESIZE], LANGID language )
            Return status
        }
        
        ;####################################
        ; Call          IsStyleAvailable(GDIPCONST GpFontFamily *family, INT style, BOOL * IsStyleAvailable)
        ; Description   Determines whether the specified style is available for this font family.
        ;          
        ; Params        GDIPCONST GpFontFamily *family, INT style, BOOL * IsStyleAvailable
        ;          
        ; Return        Status
        ;______________________________________
        IsStyleAvailable(GDIPCONST GpFontFamily *family, INT style, BOOL * IsStyleAvailable)
        {
            status := GdipIsStyleAvailable(GDIPCONST GpFontFamily *family, INT style, BOOL * IsStyleAvailable)
            Return status
        }
        
        ;####################################
        ; Call          GetEmHeight(GDIPCONST GpFontFamily *family, INT style, UINT16 * EmHeight)
        ; Description   Gets the size (commonly called em size or em height), in design units, of this font family.
        ;          
        ; Params        GDIPCONST GpFontFamily *family, INT style, UINT16 * EmHeight
        ;          
        ; Return        Status
        ;______________________________________
        GetEmHeight(GDIPCONST GpFontFamily *family, INT style, UINT16 * EmHeight)
        {
            status := GdipGetEmHeight(GDIPCONST GpFontFamily *family, INT style, UINT16 * EmHeight)
            Return status
        }
        
        ;####################################
        ; Call          GetCellAscent(GDIPCONST GpFontFamily *family, INT style, UINT16 * CellAscent)
        ; Description   Gets the cell ascent, in design units, of this font family for the specified style or style combination.
        ;          
        ; Params        GDIPCONST GpFontFamily *family, INT style, UINT16 * CellAscent
        ;          
        ; Return        Status
        ;______________________________________
        GetCellAscent(GDIPCONST GpFontFamily *family, INT style, UINT16 * CellAscent)
        {
            status := GdipGetCellAscent(GDIPCONST GpFontFamily *family, INT style, UINT16 * CellAscent)
            Return status
        }
        
        ;####################################
        ; Call          GetCellDescent(GDIPCONST GpFontFamily *family, INT style, UINT16 * CellDescent)
        ; Description   Gets the cell descent, in design units, of this font family for the specified style or style combination.
        ;          
        ; Params        GDIPCONST GpFontFamily *family, INT style, UINT16 * CellDescent
        ;          
        ; Return        Status
        ;______________________________________
        GetCellDescent(GDIPCONST GpFontFamily *family, INT style, UINT16 * CellDescent)
        {
            status := GdipGetCellDescent(GDIPCONST GpFontFamily *family, INT style, UINT16 * CellDescent)
            Return status
        }
        
        ;####################################
        ; Call          GetLineSpacing(GDIPCONST GpFontFamily *family, INT style, UINT16 * LineSpacing)
        ; Description   Gets the line spacing, in design units, of this font family for the specified style or style combination. The line spacing is the vertical distance between the base lines of two consecutive lines of text.
        ;          
        ; Params        GDIPCONST GpFontFamily *family, INT style, UINT16 * LineSpacing
        ;          
        ; Return        Status
        ;______________________________________
        GetLineSpacing(GDIPCONST GpFontFamily *family, INT style, UINT16 * LineSpacing)
        {
            status := GdipGetLineSpacing(GDIPCONST GpFontFamily *family, INT style, UINT16 * LineSpacing)
            Return status
        }
        
    }
    
    
    Class Graphics
    {
        ;####################################
        ; Call          Flush(GpGraphics *graphics, GpFlushIntention intention)
        ; Description   Flushes all pending graphics operations.
        ;          
        ; Params        GpGraphics *graphics, GpFlushIntention intention
        ;          
        ; Return        Status
        ;______________________________________
        Flush(GpGraphics *graphics, GpFlushIntention intention)
        {
            status := GdipFlush(GpGraphics *graphics, GpFlushIntention intention)
            Return status
        }
        
        ;####################################
        ; Call          Graphics(HDC hdc, GpGraphics **graphics)
        ; Description   Creates a Graphics object that is associated with a specified device context.
        ;          
        ; Params        HDC hdc, GpGraphics **graphics
        ;          
        ; Return        Status
        ;______________________________________
        Graphics(HDC hdc, GpGraphics **graphics)
        {
            status := GdipCreateFromHDC(HDC hdc, GpGraphics **graphics)
            Return status
        }
        
        ;####################################
        ; Call          Graphics(HDC hdc, HANDLE hDevice, GpGraphics **graphics)
        ; Description   Creates a Graphics object that is associated with a specified device context and a specified device.
        ;          
        ; Params        HDC hdc, HANDLE hDevice, GpGraphics **graphics
        ;          
        ; Return        Status
        ;______________________________________
        Graphics(HDC hdc, HANDLE hDevice, GpGraphics **graphics)
        {
            status := GdipCreateFromHDC2(HDC hdc, HANDLE hDevice, GpGraphics **graphics)
            Return status
        }
        
        ;####################################
        ; Call          Graphics(HWND hwnd, GpGraphics **graphics)
        ; Description   Creates a Graphics object that is associated with a specified window.
        ;          
        ; Params        HWND hwnd, GpGraphics **graphics
        ;          
        ; Return        Status
        ;______________________________________
        Graphics(HWND hwnd, GpGraphics **graphics)
        {
            status := GdipCreateFromHWND(HWND hwnd, GpGraphics **graphics)
            Return status
        }
        
        ;####################################
        ; Call          Graphics(HWND hwnd, GpGraphics **graphics)
        ; Description   This function uses Image Color Management (ICM). It is called when the icm parameter of the Graphics::Graphics constructor is set to TRUE.
        ;          
        ; Params        HWND hwnd, GpGraphics **graphics
        ;          
        ; Return        Status
        ;______________________________________
        Graphics(HWND hwnd, GpGraphics **graphics)
        {
            status := GdipCreateFromHWNDICM(HWND hwnd, GpGraphics **graphics)
            Return status
        }
        
        ;####################################
        ; Call          GetHDC(GpGraphics* graphics, HDC * hdc)
        ; Description   Gets a handle to the device context associated with this Graphics object.
        ;          
        ; Params        GpGraphics* graphics, HDC * hdc
        ;          
        ; Return        Status
        ;______________________________________
        GetHDC(GpGraphics* graphics, HDC * hdc)
        {
            status := GdipGetDC(GpGraphics* graphics, HDC * hdc)
            Return status
        }
        
        ;####################################
        ; Call          ReleaseHDC(GpGraphics* graphics, HDC hdc)
        ; Description   Releases a device context handle obtained by a previous call to the Graphics::GetHDC method of this Graphics object.
        ;          
        ; Params        GpGraphics* graphics, HDC hdc
        ;          
        ; Return        Status
        ;______________________________________
        ReleaseHDC(GpGraphics* graphics, HDC hdc)
        {
            status := GdipReleaseDC(GpGraphics* graphics, HDC hdc)
            Return status
        }
        
        ;####################################
        ; Call          SetCompositingMode(GpGraphics *graphics, CompositingMode compositingMode)
        ; Description   Sets the compositing mode of this Graphics object.
        ;          
        ; Params        GpGraphics *graphics, CompositingMode compositingMode
        ;          
        ; Return        Status
        ;______________________________________
        SetCompositingMode(GpGraphics *graphics, CompositingMode compositingMode)
        {
            status := GdipSetCompositingMode(GpGraphics *graphics, CompositingMode compositingMode)
            Return status
        }
        
        ;####################################
        ; Call          GetCompositingMode(GpGraphics *graphics, CompositingMode *compositingMode)
        ; Description   Gets the compositing mode currently set for this Graphics object.
        ;          
        ; Params        GpGraphics *graphics, CompositingMode *compositingMode
        ;          
        ; Return        Status
        ;______________________________________
        GetCompositingMode(GpGraphics *graphics, CompositingMode *compositingMode)
        {
            status := GdipGetCompositingMode(GpGraphics *graphics, CompositingMode *compositingMode)
            Return status
        }
        
        ;####################################
        ; Call          SetRenderingOrigin(GpGraphics *graphics, INT x, INT y)
        ; Description   Sets the rendering origin of this Graphics object. The rendering origin is used to set the dither origin for 8-bits-per-pixel and 16-bits-per-pixel dithering and is also used to set the origin for hatch brushes. Syntax
        ;          
        ; Params        GpGraphics *graphics, INT x, INT y
        ;          
        ; Return        Status
        ;______________________________________
        SetRenderingOrigin(GpGraphics *graphics, INT x, INT y)
        {
            status := GdipSetRenderingOrigin(GpGraphics *graphics, INT x, INT y)
            Return status
        }
        
        ;####################################
        ; Call          GetRenderingOrigin(GpGraphics *graphics, INT *x, INT *y)
        ; Description   Gets the rendering origin currently set for this Graphics object. The rendering origin is used to set the dither origin for 8-bits per pixel and 16-bits per pixel dithering and is also used to set the origin for hatch brushes.
        ;          
        ; Params        GpGraphics *graphics, INT *x, INT *y
        ;          
        ; Return        Status
        ;______________________________________
        GetRenderingOrigin(GpGraphics *graphics, INT *x, INT *y)
        {
            status := GdipGetRenderingOrigin(GpGraphics *graphics, INT *x, INT *y)
            Return status
        }
        
        ;####################################
        ; Call          SetCompositingQuality(GpGraphics *graphics, CompositingQuality compositingQuality)
        ; Description   Sets the compositing quality of this Graphics object.
        ;          
        ; Params        GpGraphics *graphics, CompositingQuality compositingQuality
        ;          
        ; Return        Status
        ;______________________________________
        SetCompositingQuality(GpGraphics *graphics, CompositingQuality compositingQuality)
        {
            status := GdipSetCompositingQuality(GpGraphics *graphics, CompositingQuality compositingQuality)
            Return status
        }
        
        ;####################################
        ; Call          GetCompositingQuality(GpGraphics *graphics, CompositingQuality *compositingQuality)
        ; Description   Gets the compositing quality currently set for this Graphics object.
        ;          
        ; Params        GpGraphics *graphics, CompositingQuality *compositingQuality
        ;          
        ; Return        Status
        ;______________________________________
        GetCompositingQuality(GpGraphics *graphics, CompositingQuality *compositingQuality)
        {
            status := GdipGetCompositingQuality(GpGraphics *graphics, CompositingQuality *compositingQuality)
            Return status
        }
        
        ;####################################
        ; Call          SetSmoothingMode(GpGraphics *graphics, SmoothingMode smoothingMode)
        ; Description   Sets the rendering quality of the Graphics object.
        ;          
        ; Params        GpGraphics *graphics, SmoothingMode smoothingMode
        ;          
        ; Return        Status
        ;______________________________________
        SetSmoothingMode(GpGraphics *graphics, SmoothingMode smoothingMode)
        {
            status := GdipSetSmoothingMode(GpGraphics *graphics, SmoothingMode smoothingMode)
            Return status
        }
        
        ;####################################
        ; Call          GetSmoothingMode(GpGraphics *graphics, SmoothingMode *smoothingMode)
        ; Description   Determines whether smoothing (antialiasing) is applied to the Graphics object.
        ;          
        ; Params        GpGraphics *graphics, SmoothingMode *smoothingMode
        ;          
        ; Return        Status
        ;______________________________________
        GetSmoothingMode(GpGraphics *graphics, SmoothingMode *smoothingMode)
        {
            status := GdipGetSmoothingMode(GpGraphics *graphics, SmoothingMode *smoothingMode)
            Return status
        }
        
        ;####################################
        ; Call          SetPixelOffsetMode(GpGraphics* graphics, PixelOffsetMode pixelOffsetMode)
        ; Description   Sets the pixel offset mode of this Graphics object.
        ;          
        ; Params        GpGraphics* graphics, PixelOffsetMode pixelOffsetMode
        ;          
        ; Return        Status
        ;______________________________________
        SetPixelOffsetMode(GpGraphics* graphics, PixelOffsetMode pixelOffsetMode)
        {
            status := GdipSetPixelOffsetMode(GpGraphics* graphics, PixelOffsetMode pixelOffsetMode)
            Return status
        }
        
        ;####################################
        ; Call          GetPixelOffsetMode(GpGraphics *graphics, PixelOffsetMode *pixelOffsetMode)
        ; Description   Gets the pixel offset mode currently set for this Graphics object.
        ;          
        ; Params        GpGraphics *graphics, PixelOffsetMode *pixelOffsetMode
        ;          
        ; Return        Status
        ;______________________________________
        GetPixelOffsetMode(GpGraphics *graphics, PixelOffsetMode *pixelOffsetMode)
        {
            status := GdipGetPixelOffsetMode(GpGraphics *graphics, PixelOffsetMode *pixelOffsetMode)
            Return status
        }
        
        ;####################################
        ; Call          SetTextRenderingHint(GpGraphics *graphics, TextRenderingHint mode)
        ; Description   Sets the text rendering mode of this Graphics object.
        ;          
        ; Params        GpGraphics *graphics, TextRenderingHint mode
        ;          
        ; Return        Status
        ;______________________________________
        SetTextRenderingHint(GpGraphics *graphics, TextRenderingHint mode)
        {
            status := GdipSetTextRenderingHint(GpGraphics *graphics, TextRenderingHint mode)
            Return status
        }
        
        ;####################################
        ; Call          GetTextRenderingHint(GpGraphics *graphics, TextRenderingHint *mode)
        ; Description   Gets the text rendering mode currently set for this Graphics object.
        ;          
        ; Params        GpGraphics *graphics, TextRenderingHint *mode
        ;          
        ; Return        Status
        ;______________________________________
        GetTextRenderingHint(GpGraphics *graphics, TextRenderingHint *mode)
        {
            status := GdipGetTextRenderingHint(GpGraphics *graphics, TextRenderingHint *mode)
            Return status
        }
        
        ;####################################
        ; Call          SetTextContrast(GpGraphics *graphics, UINT contrast)
        ; Description   Sets the contrast value of this Graphics object. The contrast value is used for antialiasing text.
        ;          
        ; Params        GpGraphics *graphics, UINT contrast
        ;          
        ; Return        Status
        ;______________________________________
        SetTextContrast(GpGraphics *graphics, UINT contrast)
        {
            status := GdipSetTextContrast(GpGraphics *graphics, UINT contrast)
            Return status
        }
        
        ;####################################
        ; Call          GetTextContrast(GpGraphics *graphics, UINT * contrast)
        ; Description   Gets the contrast value currently set for this Graphics object. The contrast value is used for antialiasing text.
        ;          
        ; Params        GpGraphics *graphics, UINT * contrast
        ;          
        ; Return        Status
        ;______________________________________
        GetTextContrast(GpGraphics *graphics, UINT * contrast)
        {
            status := GdipGetTextContrast(GpGraphics *graphics, UINT * contrast)
            Return status
        }
        
        ;####################################
        ; Call          SetInterpolationMode(GpGraphics *graphics, InterpolationMode interpolationMode)
        ; Description   Sets the interpolation mode of this Graphics object. The interpolation mode determines the algorithm that is used when images are scaled or rotated.
        ;          
        ; Params        GpGraphics *graphics, InterpolationMode interpolationMode
        ;          
        ; Return        Status
        ;______________________________________
        SetInterpolationMode(GpGraphics *graphics, InterpolationMode interpolationMode)
        {
            status := GdipSetInterpolationMode(GpGraphics *graphics, InterpolationMode interpolationMode)
            Return status
        }
        
        ;####################################
        ; Call          GetInterpolationMode(GpGraphics *graphics, InterpolationMode *interpolationMode)
        ; Description   Gets the interpolation mode currently set for this Graphics object. The interpolation mode determines the algorithm that is used when images are scaled or rotated.
        ;          
        ; Params        GpGraphics *graphics, InterpolationMode *interpolationMode
        ;          
        ; Return        Status
        ;______________________________________
        GetInterpolationMode(GpGraphics *graphics, InterpolationMode *interpolationMode)
        {
            status := GdipGetInterpolationMode(GpGraphics *graphics, InterpolationMode *interpolationMode)
            Return status
        }
        
        ;####################################
        ; Call          SetTransform(GpGraphics *graphics, GpMatrix *matrix)
        ; Description   Sets the world transformation of this Graphics object.
        ;          
        ; Params        GpGraphics *graphics, GpMatrix *matrix
        ;          
        ; Return        Status
        ;______________________________________
        SetTransform(GpGraphics *graphics, GpMatrix *matrix)
        {
            status := GdipSetWorldTransform(GpGraphics *graphics, GpMatrix *matrix)
            Return status
        }
        
        ;####################################
        ; Call          ResetTransform(GpGraphics *graphics)
        ; Description   Sets the world transformation matrix of this Graphics object to the identity matrix.
        ;          
        ; Params        GpGraphics *graphics
        ;          
        ; Return        Status
        ;______________________________________
        ResetTransform(GpGraphics *graphics)
        {
            status := GdipResetWorldTransform(GpGraphics *graphics)
            Return status
        }
        
        ;####################################
        ; Call          MultiplyTransform(GpGraphics *graphics, GDIPCONST GpMatrix *matrix, GpMatrixOrder order)
        ; Description   Updates this Graphics object's world transformation matrix with the product of itself and another matrix.
        ;          
        ; Params        GpGraphics *graphics, GDIPCONST GpMatrix *matrix, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        MultiplyTransform(GpGraphics *graphics, GDIPCONST GpMatrix *matrix, GpMatrixOrder order)
        {
            status := GdipMultiplyWorldTransform(GpGraphics *graphics, GDIPCONST GpMatrix *matrix, GpMatrixOrder order)
            Return status
        }
        
        ;####################################
        ; Call          TranslateTransform(GpGraphics *graphics, REAL dx, REAL dy, GpMatrixOrder order)
        ; Description   Updates this Graphics object's world transformation matrix with the product of itself and a translation matrix.
        ;          
        ; Params        GpGraphics *graphics, REAL dx, REAL dy, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        TranslateTransform(GpGraphics *graphics, REAL dx, REAL dy, GpMatrixOrder order)
        {
            status := GdipTranslateWorldTransform(GpGraphics *graphics, REAL dx, REAL dy, GpMatrixOrder order)
            Return status
        }
        
        ;####################################
        ; Call          ScaleTransform(GpGraphics *graphics, REAL sx, REAL sy, GpMatrixOrder order)
        ; Description   Updates this Graphics object's world transformation matrix with the product of itself and a scaling matrix.
        ;          
        ; Params        GpGraphics *graphics, REAL sx, REAL sy, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        ScaleTransform(GpGraphics *graphics, REAL sx, REAL sy, GpMatrixOrder order)
        {
            status := GdipScaleWorldTransform(GpGraphics *graphics, REAL sx, REAL sy, GpMatrixOrder order)
            Return status
        }
        
        ;####################################
        ; Call          RotateTransform(GpGraphics *graphics, REAL angle, GpMatrixOrder order)
        ; Description   Updates the world transformation matrix of this Graphics object with the product of itself and a rotation matrix.
        ;          
        ; Params        GpGraphics *graphics, REAL angle, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        RotateTransform(GpGraphics *graphics, REAL angle, GpMatrixOrder order)
        {
            status := GdipRotateWorldTransform(GpGraphics *graphics, REAL angle, GpMatrixOrder order)
            Return status
        }
        
        ;####################################
        ; Call          GetTransform(GpGraphics *graphics, GpMatrix *matrix)
        ; Description   Gets the world transformation matrix of this Graphics object.
        ;          
        ; Params        GpGraphics *graphics, GpMatrix *matrix
        ;          
        ; Return        Status
        ;______________________________________
        GetTransform(GpGraphics *graphics, GpMatrix *matrix)
        {
            status := GdipGetWorldTransform(GpGraphics *graphics, GpMatrix *matrix)
            Return status
        }
        
        ;####################################
        ; Call          GdipResetPageTransform(GpGraphics *graphics)
        ; Description   This function resets the page transform matrix to identity.
        ;          
        ; Params        GpGraphics *graphics
        ;          
        ; Return        Status
        ;______________________________________
        GdipResetPageTransform(GpGraphics *graphics)
        {
            status := GdipResetPageTransform(GpGraphics *graphics)
            Return status
        }

        ;####################################
        ; Call          GetPageUnit(GpGraphics *graphics, GpUnit *unit)
        ; Description   Gets the unit of measure currently set for this Graphics object.
        ;          
        ; Params        GpGraphics *graphics, GpUnit *unit
        ;          
        ; Return        Status
        ;______________________________________
        GetPageUnit(GpGraphics *graphics, GpUnit *unit)
        {
            status := GdipGetPageUnit(GpGraphics *graphics, GpUnit *unit)
            Return status
        }
        
        ;####################################
        ; Call          GetPageScale(GpGraphics *graphics, REAL *scale)
        ; Description   Gets the scaling factor currently set for the page transformation of this Graphics object. The page transformation converts page coordinates to device coordinates.
        ;          
        ; Params        GpGraphics *graphics, REAL *scale
        ;          
        ; Return        Status
        ;______________________________________
        GetPageScale(GpGraphics *graphics, REAL *scale)
        {
            status := GdipGetPageScale(GpGraphics *graphics, REAL *scale)
            Return status
        }
        
        ;####################################
        ; Call          SetPageUnit(GpGraphics *graphics, GpUnit unit)
        ; Description   Sets the unit of measure for this Graphics object. The page unit belongs to the page transformation, which converts page coordinates to device coordinates.
        ;          
        ; Params        GpGraphics *graphics, GpUnit unit
        ;          
        ; Return        Status
        ;______________________________________
        SetPageUnit(GpGraphics *graphics, GpUnit unit)
        {
            status := GdipSetPageUnit(GpGraphics *graphics, GpUnit unit)
            Return status
        }
        
        ;####################################
        ; Call          SetPageScale(GpGraphics *graphics, REAL scale)
        ; Description   Sets the scaling factor for the page transformation of this Graphics object. The page transformation converts page coordinates to device coordinates.
        ;          
        ; Params        GpGraphics *graphics, REAL scale
        ;          
        ; Return        Status
        ;______________________________________
        SetPageScale(GpGraphics *graphics, REAL scale)
        {
            status := GdipSetPageScale(GpGraphics *graphics, REAL scale)
            Return status
        }
        
        ;####################################
        ; Call          GetDpiX(GpGraphics *graphics, REAL* dpi)
        ; Description   Gets the horizontal resolution, in dots per inch, of the display device associated with this Graphics object.
        ;          
        ; Params        GpGraphics *graphics, REAL* dpi
        ;          
        ; Return        Status
        ;______________________________________
        GetDpiX(GpGraphics *graphics, REAL* dpi)
        {
            status := GdipGetDpiX(GpGraphics *graphics, REAL* dpi)
            Return status
        }
        
        ;####################################
        ; Call          GetDpiY(GpGraphics *graphics, REAL* dpi)
        ; Description   Gets the vertical resolution, in dots per inch, of the display device associated with this Graphics object.
        ;          
        ; Params        GpGraphics *graphics, REAL* dpi
        ;          
        ; Return        Status
        ;______________________________________
        GetDpiY(GpGraphics *graphics, REAL* dpi)
        {
            status := GdipGetDpiY(GpGraphics *graphics, REAL* dpi)
            Return status
        }
        
        ;####################################
        ; Call          TransformPoints(GpGraphics *graphics, GpCoordinateSpace destSpace, GpCoordinateSpace srcSpace, GpPoint *points, INT count)
        ; Description   Converts an array of points from one coordinate space to another. The conversion is based on the current world and page transformations of this Graphics object.
        ;          
        ; Params        GpGraphics *graphics, GpCoordinateSpace destSpace, GpCoordinateSpace srcSpace, GpPoint *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        TransformPoints(GpGraphics *graphics, GpCoordinateSpace destSpace, GpCoordinateSpace srcSpace, GpPoint *points, INT count)
        {
            status := GdipTransformPointsI(GpGraphics *graphics, GpCoordinateSpace destSpace, GpCoordinateSpace srcSpace, GpPoint *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          GetNearestColor(GpGraphics *graphics, ARGB* argb)
        ; Description   Gets the nearest color to the color that is passed in. This method works on 8-bits per pixel or lower display devices for which there is an 8-bit color palette.
        ;          
        ; Params        GpGraphics *graphics, ARGB* argb
        ;          
        ; Return        Status
        ;______________________________________
        GetNearestColor(GpGraphics *graphics, ARGB* argb)
        {
            status := GdipGetNearestColor(GpGraphics *graphics, ARGB* argb)
            Return status
        }
        
        ;####################################
        ; Call          GetHalftonePalette()
        ; Description   Gets a Windows halftone palette.
        ;          
        ; Params        
        ;          
        ; Return        Status
        ;______________________________________
        GetHalftonePalette()
        {
            status := GdipCreateHalftonePalette()
            Return status
        }
        
        ;####################################
        ; Call          DrawLine(GpGraphics *graphics, GpPen *pen, REAL x1, REAL y1, REAL x2, REAL y2)
        ; Description   Draws a line that connects two points.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, REAL x1, REAL y1, REAL x2, REAL y2
        ;          
        ; Return        Status
        ;______________________________________
        DrawLine(GpGraphics *graphics, GpPen *pen, REAL x1, REAL y1, REAL x2, REAL y2)
        {
            status := GdipDrawLine(GpGraphics *graphics, GpPen *pen, REAL x1, REAL y1, REAL x2, REAL y2)
            Return status
        }
        
        ;####################################
        ; Call          DrawLine(GpGraphics *graphics, GpPen *pen, INT x1, INT y1, INT x2, INT y2)
        ; Description   Draws a line that connects two points.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, INT x1, INT y1, INT x2, INT y2
        ;          
        ; Return        Status
        ;______________________________________
        DrawLine(GpGraphics *graphics, GpPen *pen, INT x1, INT y1, INT x2, INT y2)
        {
            status := GdipDrawLineI(GpGraphics *graphics, GpPen *pen, INT x1, INT y1, INT x2, INT y2)
            Return status
        }
        
        ;####################################
        ; Call          DrawLines(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count)
        ; Description   Draws a sequence of connected lines.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        DrawLines(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count)
        {
            status := GdipDrawLines(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          DrawLines(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count)
        ; Description   Draws a sequence of connected lines.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        DrawLines(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count)
        {
            status := GdipDrawLinesI(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          DrawArc(GpGraphics *graphics, GpPen *pen, REAL x, REAL y, REAL width, REAL height, REAL startAngle, REAL sweepAngle)
        ; Description   Draws an arc. The arc is part of an ellipse.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, REAL x, REAL y, REAL width, REAL height, REAL startAngle, REAL sweepAngle
        ;          
        ; Return        Status
        ;______________________________________
        DrawArc(GpGraphics *graphics, GpPen *pen, REAL x, REAL y, REAL width, REAL height, REAL startAngle, REAL sweepAngle)
        {
            status := GdipDrawArc(GpGraphics *graphics, GpPen *pen, REAL x, REAL y, REAL width, REAL height, REAL startAngle, REAL sweepAngle)
            Return status
        }
        
        ;####################################
        ; Call          DrawArc(GpGraphics *graphics, GpPen *pen, INT x, INT y, INT width, INT height, REAL startAngle, REAL sweepAngle)
        ; Description   Draws an arc. The arc is part of an ellipse.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, INT x, INT y, INT width, INT height, REAL startAngle, REAL sweepAngle
        ;          
        ; Return        Status
        ;______________________________________
        DrawArc(GpGraphics *graphics, GpPen *pen, INT x, INT y, INT width, INT height, REAL startAngle, REAL sweepAngle)
        {
            status := GdipDrawArcI(GpGraphics *graphics, GpPen *pen, INT x, INT y, INT width, INT height, REAL startAngle, REAL sweepAngle)
            Return status
        }
        
        ;####################################
        ; Call          DrawBezier(GpGraphics *graphics, GpPen *pen, REAL x1, REAL y1, REAL x2, REAL y2, REAL x3, REAL y3, REAL x4, REAL y4)
        ; Description   Draws a Bézier spline.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, REAL x1, REAL y1, REAL x2, REAL y2, REAL x3, REAL y3, REAL x4, REAL y4
        ;          
        ; Return        Status
        ;______________________________________
        DrawBezier(GpGraphics *graphics, GpPen *pen, REAL x1, REAL y1, REAL x2, REAL y2, REAL x3, REAL y3, REAL x4, REAL y4)
        {
            status := GdipDrawBezier(GpGraphics *graphics, GpPen *pen, REAL x1, REAL y1, REAL x2, REAL y2, REAL x3, REAL y3, REAL x4, REAL y4)
            Return status
        }
        
        ;####################################
        ; Call          DrawBezier(GpGraphics *graphics, GpPen *pen, INT x1, INT y1, INT x2, INT y2, INT x3, INT y3, INT x4, INT y4)
        ; Description   Draws a Bézier spline.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, INT x1, INT y1, INT x2, INT y2, INT x3, INT y3, INT x4, INT y4
        ;          
        ; Return        Status
        ;______________________________________
        DrawBezier(GpGraphics *graphics, GpPen *pen, INT x1, INT y1, INT x2, INT y2, INT x3, INT y3, INT x4, INT y4)
        {
            status := GdipDrawBezierI(GpGraphics *graphics, GpPen *pen, INT x1, INT y1, INT x2, INT y2, INT x3, INT y3, INT x4, INT y4)
            Return status
        }
        
        ;####################################
        ; Call          DrawBeziers(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count)
        ; Description   Draws a sequence of connected Bézier splines.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        DrawBeziers(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count)
        {
            status := GdipDrawBeziers(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          DrawBeziers(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count)
        ; Description   Draws a sequence of connected Bézier splines.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        DrawBeziers(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count)
        {
            status := GdipDrawBeziersI(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          DrawRectangle(GpGraphics *graphics, GpPen *pen, REAL x, REAL y, REAL width, REAL height)
        ; Description   Draws a rectangle.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, REAL x, REAL y, REAL width, REAL height
        ;          
        ; Return        Status
        ;______________________________________
        DrawRectangle(GpGraphics *graphics, GpPen *pen, REAL x, REAL y, REAL width, REAL height)
        {
            status := (GpGraphics *graphics, GpPen *pen, REAL x, REAL y, REAL width, REAL height)
            Return status
        }
        
        ;####################################
        ; Call          DrawRectangle(GpGraphics *graphics, GpPen *pen, INT x, INT y, INT width, INT height)
        ; Description   Draws a rectangle.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, INT x, INT y, INT width, INT height
        ;          
        ; Return        Status
        ;______________________________________
        DrawRectangle(GpGraphics *graphics, GpPen *pen, INT x, INT y, INT width, INT height)
        {
            status := GdipDrawRectangleI(GpGraphics *graphics, GpPen *pen, INT x, INT y, INT width, INT height)
            Return status
        }
        
        ;####################################
        ; Call          DrawRectangles(GpGraphics *graphics, GpPen *pen, GDIPCONST GpRectF *rects, INT count)
        ; Description   Draws a sequence of rectangles.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, GDIPCONST GpRectF *rects, INT count
        ;          
        ; Return        Status
        ;______________________________________
        DrawRectangles(GpGraphics *graphics, GpPen *pen, GDIPCONST GpRectF *rects, INT count)
        {
            status := GdipDrawRectangles(GpGraphics *graphics, GpPen *pen, GDIPCONST GpRectF *rects, INT count)
            Return status
        }
        
        ;####################################
        ; Call          DrawRectangles(GpGraphics *graphics, GpPen *pen, GDIPCONST GpRect *rects, INT count)
        ; Description   Draws a sequence of rectangles.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, GDIPCONST GpRect *rects, INT count
        ;          
        ; Return        Status
        ;______________________________________
        DrawRectangles(GpGraphics *graphics, GpPen *pen, GDIPCONST GpRect *rects, INT count)
        {
            status := GdipDrawRectanglesI(GpGraphics *graphics, GpPen *pen, GDIPCONST GpRect *rects, INT count)
            Return status
        }
        
        ;####################################
        ; Call          DrawEllipse(GpGraphics *graphics, GpPen *pen, REAL x, REAL y, REAL width, REAL height)
        ; Description   Draws an ellipse.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, REAL x, REAL y, REAL width, REAL height
        ;          
        ; Return        Status
        ;______________________________________
        DrawEllipse(GpGraphics *graphics, GpPen *pen, REAL x, REAL y, REAL width, REAL height)
        {
            status := GdipDrawEllipse(GpGraphics *graphics, GpPen *pen, REAL x, REAL y, REAL width, REAL height)
            Return status
        }
        
        ;####################################
        ; Call          DrawEllipse(GpGraphics *graphics, GpPen *pen, INT x, INT y, INT width, INT height)
        ; Description   Draws an ellipse.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, INT x, INT y, INT width, INT height
        ;          
        ; Return        Status
        ;______________________________________
        DrawEllipse(GpGraphics *graphics, GpPen *pen, INT x, INT y, INT width, INT height)
        {
            status := GdipDrawEllipseI(GpGraphics *graphics, GpPen *pen, INT x, INT y, INT width, INT height)
            Return status
        }
        
        ;####################################
        ; Call          DrawPie(GpGraphics *graphics, GpPen *pen, REAL x, REAL y, REAL width, REAL height, REAL startAngle, REAL sweepAngle)
        ; Description   Draws a pie.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, REAL x, REAL y, REAL width, REAL height, REAL startAngle, REAL sweepAngle
        ;          
        ; Return        Status
        ;______________________________________
        DrawPie(GpGraphics *graphics, GpPen *pen, REAL x, REAL y, REAL width, REAL height, REAL startAngle, REAL sweepAngle)
        {
            status := GdipDrawPie(GpGraphics *graphics, GpPen *pen, REAL x, REAL y, REAL width, REAL height, REAL startAngle, REAL sweepAngle)
            Return status
        }
        
        ;####################################
        ; Call          DrawPie(GpGraphics *graphics, GpPen *pen, INT x, INT y, INT width, INT height, REAL startAngle, REAL sweepAngle)
        ; Description   Draws a pie.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, INT x, INT y, INT width, INT height, REAL startAngle, REAL sweepAngle
        ;          
        ; Return        Status
        ;______________________________________
        DrawPie(GpGraphics *graphics, GpPen *pen, INT x, INT y, INT width, INT height, REAL startAngle, REAL sweepAngle)
        {
            status := GdipDrawPieI(GpGraphics *graphics, GpPen *pen, INT x, INT y, INT width, INT height, REAL startAngle, REAL sweepAngle)
            Return status
        }
        
        ;####################################
        ; Call          DrawPolygon(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count)
        ; Description   Draws a polygon.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        DrawPolygon(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count)
        {
            status := GdipDrawPolygon(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          DrawPolygon(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count)
        ; Description   Draws a polygon.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        DrawPolygon(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count)
        {
            status := GdipDrawPolygonI(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          DrawPath(GpGraphics *graphics, GpPen *pen, GpPath *path)
        ; Description   Draws a sequence of lines and curves defined by a GraphicsPath object.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, GpPath *path
        ;          
        ; Return        Status
        ;______________________________________
        DrawPath(GpGraphics *graphics, GpPen *pen, GpPath *path)
        {
            status := GdipDrawPath(GpGraphics *graphics, GpPen *pen, GpPath *path)
            Return status
        }
        
        ;####################################
        ; Call          DrawCurve(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count)
        ; Description   Draws a closed cardinal spline.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        DrawCurve(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count)
        {
            status := GdipDrawCurve(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          DrawCurve(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count)
        ; Description   Draws a closed cardinal spline.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        DrawCurve(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count)
        {
            status := GdipDrawCurveI(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          DrawCurve(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count, REAL tension)
        ; Description   Draws a closed cardinal spline.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count, REAL tension
        ;          
        ; Return        Status
        ;______________________________________
        DrawCurve(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count, REAL tension)
        {
            status := GdipDrawCurve2(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count, REAL tension)
            Return status
        }
        
        ;####################################
        ; Call          DrawCurve(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count, REAL tension)
        ; Description   Draws a closed cardinal spline.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count, REAL tension
        ;          
        ; Return        Status
        ;______________________________________
        DrawCurve(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count, REAL tension)
        {
            status := GdipDrawCurve2I(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count, REAL tension)
            Return status
        }
        
        ;####################################
        ; Call          DrawClosedCurve(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count)
        ; Description   Draws a closed cardinal spline.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        DrawClosedCurve(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count)
        {
            status := GdipDrawClosedCurve(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          DrawClosedCurve(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count)
        ; Description   Draws a closed cardinal spline.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        DrawClosedCurve(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count)
        {
            status := GdipDrawClosedCurveI(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          DrawClosedCurve(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count, REAL tension)
        ; Description   Draws a closed cardinal spline.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count, REAL tension
        ;          
        ; Return        Status
        ;______________________________________
        DrawClosedCurve(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count, REAL tension)
        {
            status := GdipDrawClosedCurve2(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPointF *points, INT count, REAL tension)
            Return status
        }
        
        ;####################################
        ; Call          DrawClosedCurve(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count, REAL tension)
        ; Description   Draws a closed cardinal spline.
        ;          
        ; Params        GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count, REAL tension
        ;          
        ; Return        Status
        ;______________________________________
        DrawClosedCurve(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count, REAL tension)
        {
            status := GdipDrawClosedCurve2I(GpGraphics *graphics, GpPen *pen, GDIPCONST GpPoint *points, INT count, REAL tension)
            Return status
        }
        
        ;####################################
        ; Call          Clear(GpGraphics *graphics, ARGB color)
        ; Description   Clears a Graphics object to a specified color.
        ;          
        ; Params        GpGraphics *graphics, ARGB color
        ;          
        ; Return        Status
        ;______________________________________
        Clear(GpGraphics *graphics, ARGB color)
        {
            status := GdipGraphicsClear(GpGraphics *graphics, ARGB color)
            Return status
        }
        
        ;####################################
        ; Call          FillRectangle(GpGraphics *graphics, GpBrush *brush, REAL x, REAL y, REAL width, REAL height)
        ; Description   Uses a brush to fill the interior of a rectangle.
        ;          
        ; Params        GpGraphics *graphics, GpBrush *brush, REAL x, REAL y, REAL width, REAL height
        ;          
        ; Return        Status
        ;______________________________________
        FillRectangle(GpGraphics *graphics, GpBrush *brush, REAL x, REAL y, REAL width, REAL height)
        {
            status := GdipFillRectangle(GpGraphics *graphics, GpBrush *brush, REAL x, REAL y, REAL width, REAL height)
            Return status
        }
        
        ;####################################
        ; Call          FillRectangle(GpGraphics *graphics, GpBrush *brush, INT x, INT y, INT width, INT height)
        ; Description   Uses a brush to fill the interior of a rectangle.
        ;          
        ; Params        GpGraphics *graphics, GpBrush *brush, INT x, INT y, INT width, INT height
        ;          
        ; Return        Status
        ;______________________________________
        FillRectangle(GpGraphics *graphics, GpBrush *brush, INT x, INT y, INT width, INT height)
        {
            status := GdipFillRectangleI(GpGraphics *graphics, GpBrush *brush, INT x, INT y, INT width, INT height)
            Return status
        }
        
        ;####################################
        ; Call          FillPolygon(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPointF *points, INT count, GpFillMode fillMode)
        ; Description   Uses a brush to fill the interior of a polygon.
        ;          
        ; Params        GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPointF *points, INT count, GpFillMode fillMode
        ;          
        ; Return        Status
        ;______________________________________
        FillPolygon(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPointF *points, INT count, GpFillMode fillMode)
        {
            status := GdipFillPolygon(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPointF *points, INT count, GpFillMode fillMode)
            Return status
        }
        
        ;####################################
        ; Call          FillPolygon(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPoint *points, INT count, GpFillMode fillMode)
        ; Description   Uses a brush to fill the interior of a polygon.
        ;          
        ; Params        GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPoint *points, INT count, GpFillMode fillMode
        ;          
        ; Return        Status
        ;______________________________________
        FillPolygon(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPoint *points, INT count, GpFillMode fillMode)
        {
            status := GdipFillPolygonI(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPoint *points, INT count, GpFillMode fillMode)
            Return status
        }
        
        ;####################################
        ; Call          GdipFillPolygon2(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPointF *points, INT count)
        ; Description   This function fills a polygon with a brush. The points parameter specifies the vertices of the polygon. The count parameter specifies the number of vertices. The brush parameter specifies the brush object used to fill the polygon. The fill mode is FillModeAlternate.
        ;          
        ; Params        GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPointF *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        GdipFillPolygon2(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPointF *points, INT count)
        {
            status := GdipFillPolygon2(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPointF *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          GdipFillPolygon2I(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPoint *points, INT count)
        ; Description   This function fills a polygon with a brush. The points parameter specifies the vertices of the polygon. The count parameter specifies the number of vertices. The brush parameter specifies the brush object used to fill the polygon. The fill mode is FillModeAlternate.
        ;          
        ; Params        GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPoint *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        GdipFillPolygon2I(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPoint *points, INT count)
        {
            status := GdipFillPolygon2I(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPoint *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          FillEllipse(GpGraphics *graphics, GpBrush *brush, REAL x, REAL y, REAL width, REAL height)
        ; Description   Uses a brush to fill the interior of an ellipse that is specified by coordinates and dimensions.
        ;          
        ; Params        GpGraphics *graphics, GpBrush *brush, REAL x, REAL y, REAL width, REAL height
        ;          
        ; Return        Status
        ;______________________________________
        FillEllipse(GpGraphics *graphics, GpBrush *brush, REAL x, REAL y, REAL width, REAL height)
        {
            status := GdipFillEllipse(GpGraphics *graphics, GpBrush *brush, REAL x, REAL y, REAL width, REAL height)
            Return status
        }
        
        ;####################################
        ; Call          FillEllipse(GpGraphics *graphics, GpBrush *brush, INT x, INT y, INT width, INT height)
        ; Description   Uses a brush to fill the interior of an ellipse that is specified by coordinates and dimensions.
        ;          
        ; Params        GpGraphics *graphics, GpBrush *brush, INT x, INT y, INT width, INT height
        ;          
        ; Return        Status
        ;______________________________________
        FillEllipse(GpGraphics *graphics, GpBrush *brush, INT x, INT y, INT width, INT height)
        {
            status := GdipFillEllipseI(GpGraphics *graphics, GpBrush *brush, INT x, INT y, INT width, INT height)
            Return status
        }
        
        ;####################################
        ; Call          FillPie(GpGraphics *graphics, GpBrush *brush, REAL x, REAL y, REAL width, REAL height, REAL startAngle, REAL sweepAngle)
        ; Description   Uses a brush to fill the interior of a pie.
        ;          
        ; Params        GpGraphics *graphics, GpBrush *brush, REAL x, REAL y, REAL width, REAL height, REAL startAngle, REAL sweepAngle
        ;          
        ; Return        Status
        ;______________________________________
        FillPie(GpGraphics *graphics, GpBrush *brush, REAL x, REAL y, REAL width, REAL height, REAL startAngle, REAL sweepAngle)
        {
            status := GdipFillPie(GpGraphics *graphics, GpBrush *brush, REAL x, REAL y, REAL width, REAL height, REAL startAngle, REAL sweepAngle)
            Return status
        }
        
        ;####################################
        ; Call           FillPie(GpGraphics *graphics, GpBrush *brush, INT x, INT y, INT width, INT height, REAL startAngle, REAL sweepAngle)
        ; Description   Uses a brush to fill the interior of a pie.
        ;          
        ; Params        GpGraphics *graphics, GpBrush *brush, INT x, INT y, INT width, INT height, REAL startAngle, REAL sweepAngle
        ;          
        ; Return        Status
        ;______________________________________
         FillPie(GpGraphics *graphics, GpBrush *brush, INT x, INT y, INT width, INT height, REAL startAngle, REAL sweepAngle)
        {
            status := GdipFillPieI(GpGraphics *graphics, GpBrush *brush, INT x, INT y, INT width, INT height, REAL startAngle, REAL sweepAngle)
            Return status
        }
        
        ;####################################
        ; Call          FillPath(GpGraphics *graphics, GpBrush *brush, GpPath *path)
        ; Description   Uses a brush to fill the interior of a path. If a figure in the path is not closed, this method treats the nonclosed figure as if it were closed by a straight line that connects the figure's starting and ending points.
        ;          
        ; Params        GpGraphics *graphics, GpBrush *brush, GpPath *path
        ;          
        ; Return        Status
        ;______________________________________
        FillPath(GpGraphics *graphics, GpBrush *brush, GpPath *path)
        {
            status := GdipFillPath(GpGraphics *graphics, GpBrush *brush, GpPath *path)
            Return status
        }
        
        ;####################################
        ; Call          FillClosedCurve(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPointF *points, INT count)
        ; Description   Creates a closed cardinal spline from an array of points and uses a brush to fill the interior of the spline.
        ;          
        ; Params        GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPointF *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        FillClosedCurve(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPointF *points, INT count)
        {
            status := GdipFillClosedCurve(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPointF *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          FillClosedCurve(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPoint *points, INT count)
        ; Description   Creates a closed cardinal spline from an array of points and uses a brush to fill the interior of the spline.
        ;          
        ; Params        GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPoint *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        FillClosedCurve(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPoint *points, INT count)
        {
            status := GdipFillClosedCurveI(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPoint *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          FillClosedCurve(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPointF *points, INT count, REAL tension, GpFillMode fillMode)
        ; Description   Creates a closed cardinal spline from an array of points and uses a brush to fill, according to a specified mode, the interior of the spline.
        ;          
        ; Params        GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPointF *points, INT count, REAL tension, GpFillMode fillMode
        ;          
        ; Return        Status
        ;______________________________________
        FillClosedCurve(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPointF *points, INT count, REAL tension, GpFillMode fillMode)
        {
            status := GdipFillClosedCurve2(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPointF *points, INT count, REAL tension, GpFillMode fillMode)
            Return status
        }
        
        ;####################################
        ; Call          FillClosedCurve(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPoint *points, INT count, REAL tension, GpFillMode fillMode)
        ; Description   Creates a closed cardinal spline from an array of points and uses a brush to fill, according to a specified mode, the interior of the spline.
        ;          
        ; Params        GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPoint *points, INT count, REAL tension, GpFillMode fillMode
        ;          
        ; Return        Status
        ;______________________________________
        FillClosedCurve(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPoint *points, INT count, REAL tension, GpFillMode fillMode)
        {
            status := GdipFillClosedCurve2I(GpGraphics *graphics, GpBrush *brush, GDIPCONST GpPoint *points, INT count, REAL tension, GpFillMode fillMode)
            Return status
        }
        
        ;####################################
        ; Call          FillRegion(GpGraphics *graphics, GpBrush *brush, GpRegion *region)
        ; Description   Uses a brush to fill a specified region.
        ;          
        ; Params        GpGraphics *graphics, GpBrush *brush, GpRegion *region
        ;          
        ; Return        Status
        ;______________________________________
        FillRegion(GpGraphics *graphics, GpBrush *brush, GpRegion *region)
        {
            status := GdipFillRegion(GpGraphics *graphics, GpBrush *brush, GpRegion *region)
            Return status
        }
        
        ;####################################
        ; Call          DrawImage(GpGraphics *graphics, GpImage *image, REAL x, REAL y)
        ; Description   Draws an image at a specified location.
        ;          
        ; Params        GpGraphics *graphics, GpImage *image, REAL x, REAL y
        ;          
        ; Return        Status
        ;______________________________________
        DrawImage(GpGraphics *graphics, GpImage *image, REAL x, REAL y)
        {
            status := GdipDrawImage(GpGraphics *graphics, GpImage *image, REAL x, REAL y)
            Return status
        }
        
        ;####################################
        ; Call          DrawImage(GpGraphics *graphics, GpImage *image, INT x, INT y)
        ; Description   Draws an image at a specified location.
        ;          
        ; Params        GpGraphics *graphics, GpImage *image, INT x, INT y
        ;          
        ; Return        Status
        ;______________________________________
        DrawImage(GpGraphics *graphics, GpImage *image, INT x, INT y)
        {
            status := GdipDrawImageI(GpGraphics *graphics, GpImage *image, INT x, INT y)
            Return status
        }
        
        ;####################################
        ; Call          DrawImage(GpGraphics *graphics, GpImage *image, REAL x, REAL y, REAL width, REAL height)
        ; Description   Draws an image.
        ;          
        ; Params        GpGraphics *graphics, GpImage *image, REAL x, REAL y, REAL width, REAL height
        ;          
        ; Return        Status
        ;______________________________________
        DrawImage(GpGraphics *graphics, GpImage *image, REAL x, REAL y, REAL width, REAL height)
        {
            status := GdipDrawImageRect(GpGraphics *graphics, GpImage *image, REAL x, REAL y, REAL width, REAL height)
            Return status
        }
        
        ;####################################
        ; Call          DrawImage(GpGraphics *graphics, GpImage *image, INT x, INT y, INT width, INT height)
        ; Description   Draws an image.
        ;          
        ; Params        GpGraphics *graphics, GpImage *image, INT x, INT y, INT width, INT height
        ;          
        ; Return        Status
        ;______________________________________
        DrawImage(GpGraphics *graphics, GpImage *image, INT x, INT y, INT width, INT height)
        {
            status := GdipDrawImageRectI(GpGraphics *graphics, GpImage *image, INT x, INT y, INT width, INT height)
            Return status
        }
        
        ;####################################
        ; Call          DrawImage(GpGraphics *graphics, GpImage *image, GDIPCONST GpPointF *dstpoints, INT count)
        ; Description   Draws an image.
        ;          
        ; Params        GpGraphics *graphics, GpImage *image, GDIPCONST GpPointF *dstpoints, INT count
        ;          
        ; Return        Status
        ;______________________________________
        DrawImage(GpGraphics *graphics, GpImage *image, GDIPCONST GpPointF *dstpoints, INT count)
        {
            status := GdipDrawImagePoints(GpGraphics *graphics, GpImage *image, GDIPCONST GpPointF *dstpoints, INT count)
            Return status
        }
        
        ;####################################
        ; Call          DrawImage(GpGraphics *graphics, GpImage *image, GDIPCONST GpPoint *dstpoints, INT count)
        ; Description   Draws an image.
        ;          
        ; Params        GpGraphics *graphics, GpImage *image, GDIPCONST GpPoint *dstpoints, INT count
        ;          
        ; Return        Status
        ;______________________________________
        DrawImage(GpGraphics *graphics, GpImage *image, GDIPCONST GpPoint *dstpoints, INT count)
        {
            status := GdipDrawImagePointsI(GpGraphics *graphics, GpImage *image, GDIPCONST GpPoint *dstpoints, INT count)
            Return status
        }
        
        ;####################################
        ; Call          DrawImage(GpGraphics *graphics, GpImage *image, REAL x, REAL y, REAL srcx, REAL srcy, REAL srcwidth, REAL srcheight, GpUnit srcUnit)
        ; Description   Draws an image.
        ;          
        ; Params        GpGraphics *graphics, GpImage *image, REAL x, REAL y, REAL srcx, REAL srcy, REAL srcwidth, REAL srcheight, GpUnit srcUnit
        ;          
        ; Return        Status
        ;______________________________________
        DrawImage(GpGraphics *graphics, GpImage *image, REAL x, REAL y, REAL srcx, REAL srcy, REAL srcwidth, REAL srcheight, GpUnit srcUnit)
        {
            status := GdipDrawImagePointRect(GpGraphics *graphics, GpImage *image, REAL x, REAL y, REAL srcx, REAL srcy, REAL srcwidth, REAL srcheight, GpUnit srcUnit)
            Return status
        }
        
        ;####################################
        ; Call          DrawImage(GpGraphics *graphics, GpImage *image, INT x, INT y, INT srcx, INT srcy, INT srcwidth, INT srcheight, GpUnit srcUnit)
        ; Description   Draws an image.
        ;          
        ; Params        GpGraphics *graphics, GpImage *image, INT x, INT y, INT srcx, INT srcy, INT srcwidth, INT srcheight, GpUnit srcUnit
        ;          
        ; Return        Status
        ;______________________________________
        DrawImage(GpGraphics *graphics, GpImage *image, INT x, INT y, INT srcx, INT srcy, INT srcwidth, INT srcheight, GpUnit srcUnit)
        {
            status := GdipDrawImagePointRectI(GpGraphics *graphics, GpImage *image, INT x, INT y, INT srcx, INT srcy, INT srcwidth, INT srcheight, GpUnit srcUnit)
            Return status
        }
        
        ;####################################
        ; Call          DrawImage(GpGraphics *graphics, GpImage *image, REAL dstx, REAL dsty, REAL dstwidth, REAL dstheight, REAL srcx, REAL srcy, REAL srcwidth, REAL srcheight, GpUnit srcUnit, GDIPCONST GpImageAttributes* imageAttributes, DrawImageAbort callback, VOID * callbackData)
        ; Description   Draws an image.\nIn the flat function, the dstx, dsty, dstwidth, and dstheight parameters specify a rectangle that corresponds to the dstRect parameter in the wrapper method.
        ;          
        ; Params        GpGraphics *graphics, GpImage *image, REAL dstx, REAL dsty, REAL dstwidth, REAL dstheight, REAL srcx, REAL srcy, REAL srcwidth, REAL srcheight, GpUnit srcUnit, GDIPCONST GpImageAttributes* imageAttributes, DrawImageAbort callback, VOID * callbackData
        ;          
        ; Return        Status
        ;______________________________________
        DrawImage(GpGraphics *graphics, GpImage *image, REAL dstx, REAL dsty, REAL dstwidth, REAL dstheight, REAL srcx, REAL srcy, REAL srcwidth, REAL srcheight, GpUnit srcUnit, GDIPCONST GpImageAttributes* imageAttributes, DrawImageAbort callback, VOID * callbackData)
        {
            status := GdipDrawImageRectRect(GpGraphics *graphics, GpImage *image, REAL dstx, REAL dsty, REAL dstwidth, REAL dstheight, REAL srcx, REAL srcy, REAL srcwidth, REAL srcheight, GpUnit srcUnit, GDIPCONST GpImageAttributes* imageAttributes, DrawImageAbort callback, VOID * callbackData)
            Return status
        }
        
        ;####################################
        ; Call          DrawImage(GpGraphics *graphics, GpImage *image, INT dstx, INT dsty, INT dstwidth, INT dstheight, INT srcx, INT srcy, INT srcwidth, INT srcheight, GpUnit srcUnit, GDIPCONST GpImageAttributes* imageAttributes, DrawImageAbort callback, VOID * callbackData)
        ; Description   Draws an image.\nIn the flat function, the dstx, dsty, dstwidth, and dstheight parameters specify a rectangle that corresponds to the dstRect parameter in the wrapper method.
        ;          
        ; Params        GpGraphics *graphics, GpImage *image, INT dstx, INT dsty, INT dstwidth, INT dstheight, INT srcx, INT srcy, INT srcwidth, INT srcheight, GpUnit srcUnit, GDIPCONST GpImageAttributes* imageAttributes, DrawImageAbort callback, VOID * callbackData
        ;          
        ; Return        Status
        ;______________________________________
        DrawImage(GpGraphics *graphics, GpImage *image, INT dstx, INT dsty, INT dstwidth, INT dstheight, INT srcx, INT srcy, INT srcwidth, INT srcheight, GpUnit srcUnit, GDIPCONST GpImageAttributes* imageAttributes, DrawImageAbort callback, VOID * callbackData)
        {
            status := GdipDrawImageRectRectI(GpGraphics *graphics, GpImage *image, INT dstx, INT dsty, INT dstwidth, INT dstheight, INT srcx, INT srcy, INT srcwidth, INT srcheight, GpUnit srcUnit, GDIPCONST GpImageAttributes* imageAttributes, DrawImageAbort callback, VOID * callbackData)
            Return status
        }
        
        ;####################################
        ; Call          DrawImage(GpGraphics *graphics, GpImage *image, GDIPCONST GpPointF *points, INT count, REAL srcx, REAL srcy, REAL srcwidth, REAL srcheight, GpUnit srcUnit, GDIPCONST GpImageAttributes* imageAttributes, DrawImageAbort callback, VOID * callbackData)
        ; Description   Draws an image.
        ;          
        ; Params        GpGraphics *graphics, GpImage *image, GDIPCONST GpPointF *points, INT count, REAL srcx, REAL srcy, REAL srcwidth, REAL srcheight, GpUnit srcUnit, GDIPCONST GpImageAttributes* imageAttributes, DrawImageAbort callback, VOID * callbackData
        ;          
        ; Return        Status
        ;______________________________________
        DrawImage(GpGraphics *graphics, GpImage *image, GDIPCONST GpPointF *points, INT count, REAL srcx, REAL srcy, REAL srcwidth, REAL srcheight, GpUnit srcUnit, GDIPCONST GpImageAttributes* imageAttributes, DrawImageAbort callback, VOID * callbackData)
        {
            status := GdipDrawImagePointsRect(GpGraphics *graphics, GpImage *image, GDIPCONST GpPointF *points, INT count, REAL srcx, REAL srcy, REAL srcwidth, REAL srcheight, GpUnit srcUnit, GDIPCONST GpImageAttributes* imageAttributes, DrawImageAbort callback, VOID * callbackData)
            Return status
        }
        
        ;####################################
        ; Call          DrawImage(GpGraphics *graphics, GpImage *image, GDIPCONST GpPoint *points, INT count, INT srcx, INT srcy, INT srcwidth, INT srcheight, GpUnit srcUnit, GDIPCONST GpImageAttributes* imageAttributes, DrawImageAbort callback, VOID * callbackData)
        ; Description   Draws an image.
        ;          
        ; Params        GpGraphics *graphics, GpImage *image, GDIPCONST GpPoint *points, INT count, INT srcx, INT srcy, INT srcwidth, INT srcheight, GpUnit srcUnit, GDIPCONST GpImageAttributes* imageAttributes, DrawImageAbort callback, VOID * callbackData
        ;          
        ; Return        Status
        ;______________________________________
        DrawImage(GpGraphics *graphics, GpImage *image, GDIPCONST GpPoint *points, INT count, INT srcx, INT srcy, INT srcwidth, INT srcheight, GpUnit srcUnit, GDIPCONST GpImageAttributes* imageAttributes, DrawImageAbort callback, VOID * callbackData)
        {
            status := GdipDrawImagePointsRectI(GpGraphics *graphics, GpImage *image, GDIPCONST GpPoint *points, INT count, INT srcx, INT srcy, INT srcwidth, INT srcheight, GpUnit srcUnit, GDIPCONST GpImageAttributes* imageAttributes, DrawImageAbort callback, VOID * callbackData)
            Return status
        }
        
        ;####################################
        ; Call          DrawImage(GpGraphics *graphics, GpImage *image, GpRectF *source, GpMatrix *xForm, CGpEffect *effect, GpImageAttributes *imageAttributes, GpUnit srcUnit)
        ; Description   Draws a portion of an image after applying a specified effect.
        ;          
        ; Params        GpGraphics *graphics, GpImage *image, GpRectF *source, GpMatrix *xForm, CGpEffect *effect, GpImageAttributes *imageAttributes, GpUnit srcUnit
        ;          
        ; Return        Status
        ;______________________________________
        DrawImage(GpGraphics *graphics, GpImage *image, GpRectF *source, GpMatrix *xForm, CGpEffect *effect, GpImageAttributes *imageAttributes, GpUnit srcUnit)
        {
            status := GdipDrawImageFX(GpGraphics *graphics, GpImage *image, GpRectF *source, GpMatrix *xForm, CGpEffect *effect, GpImageAttributes *imageAttributes, GpUnit srcUnit)
            Return status
        }
        
        ;####################################
        ; Call          EnumerateMetafile( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST PointF & destPoint, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
        ; Description   Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        ;          
        ; Params        GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST PointF & destPoint, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes 
        ;          
        ; Return        Status
        ;______________________________________
        EnumerateMetafile( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST PointF & destPoint, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
        {
            status := GdipEnumerateMetafileDestPoint( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST PointF & destPoint, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
            Return status
        }
        
        ;####################################
        ; Call          EnumerateMetafile( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Point & destPoint, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
        ; Description   Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        ;          
        ; Params        GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Point & destPoint, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes 
        ;          
        ; Return        Status
        ;______________________________________
        EnumerateMetafile( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Point & destPoint, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
        {
            status := GdipEnumerateMetafileDestPointI( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Point & destPoint, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
            Return status
        }
        
        ;####################################
        ; Call          EnumerateMetafile( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST RectF & destRect, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
        ; Description   Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        ;          
        ; Params        GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST RectF & destRect, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes 
        ;          
        ; Return        Status
        ;______________________________________
        EnumerateMetafile( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST RectF & destRect, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
        {
            status := GdipEnumerateMetafileDestRect( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST RectF & destRect, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
            Return status
        }
        
        ;####################################
        ; Call          EnumerateMetafile( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Rect & destRect, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
        ; Description   Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        ;          
        ; Params        GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Rect & destRect, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes 
        ;          
        ; Return        Status
        ;______________________________________
        EnumerateMetafile( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Rect & destRect, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
        {
            status := GdipEnumerateMetafileDestRectI( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Rect & destRect, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
            Return status
        }
        
        ;####################################
        ; Call          EnumerateMetafile( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Point * destPoints, INT count, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
        ; Description   Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        ;          
        ; Params        GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Point * destPoints, INT count, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes 
        ;          
        ; Return        Status
        ;______________________________________
        EnumerateMetafile( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Point * destPoints, INT count, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
        {
            status := GdipEnumerateMetafileDestPointsI( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Point * destPoints, INT count, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
            Return status
        }
        
        ;####################################
        ; Call          EnumerateMetafile( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Point & destPoint, GDIPCONST Rect & srcRect, Unit srcUnit, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
        ; Description   Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        ;          
        ; Params        GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Point & destPoint, GDIPCONST Rect & srcRect, Unit srcUnit, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes 
        ;          
        ; Return        Status
        ;______________________________________
        EnumerateMetafile( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Point & destPoint, GDIPCONST Rect & srcRect, Unit srcUnit, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
        {
            status := GdipEnumerateMetafileSrcRectDestPointI( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Point & destPoint, GDIPCONST Rect & srcRect, Unit srcUnit, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
            Return status
        }
        
        ;####################################
        ; Call          EnumerateMetafile( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST RectF & destRect, GDIPCONST RectF & srcRect, Unit srcUnit, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
        ; Description   Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        ;          
        ; Params        GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST RectF & destRect, GDIPCONST RectF & srcRect, Unit srcUnit, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes 
        ;          
        ; Return        Status
        ;______________________________________
        EnumerateMetafile( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST RectF & destRect, GDIPCONST RectF & srcRect, Unit srcUnit, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
        {
            status := GdipEnumerateMetafileSrcRectDestRect( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST RectF & destRect, GDIPCONST RectF & srcRect, Unit srcUnit, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
            Return status
        }
        
        ;####################################
        ; Call          EnumerateMetafile( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Rect & destRect, GDIPCONST Rect & srcRect, Unit srcUnit, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
        ; Description   Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        ;          
        ; Params        GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Rect & destRect, GDIPCONST Rect & srcRect, Unit srcUnit, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes 
        ;          
        ; Return        Status
        ;______________________________________
        EnumerateMetafile( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Rect & destRect, GDIPCONST Rect & srcRect, Unit srcUnit, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
        {
            status := GdipEnumerateMetafileSrcRectDestRectI( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Rect & destRect, GDIPCONST Rect & srcRect, Unit srcUnit, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
            Return status
        }
        
        ;####################################
        ; Call          EnumerateMetafile( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST PointF * destPoints, INT count, GDIPCONST RectF & srcRect, Unit srcUnit, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
        ; Description   Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        ;          
        ; Params        GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST PointF * destPoints, INT count, GDIPCONST RectF & srcRect, Unit srcUnit, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes 
        ;          
        ; Return        Status
        ;______________________________________
        EnumerateMetafile( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST PointF * destPoints, INT count, GDIPCONST RectF & srcRect, Unit srcUnit, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
        {
            status := GdipEnumerateMetafileSrcRectDestPoints( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST PointF * destPoints, INT count, GDIPCONST RectF & srcRect, Unit srcUnit, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
            Return status
        }
        
        ;####################################
        ; Call          EnumerateMetafile( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Point * destPoints, INT count, GDIPCONST Rect & srcRect, Unit srcUnit, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
        ; Description   Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        ;          
        ; Params        GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Point * destPoints, INT count, GDIPCONST Rect & srcRect, Unit srcUnit, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes 
        ;          
        ; Return        Status
        ;______________________________________
        EnumerateMetafile( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Point * destPoints, INT count, GDIPCONST Rect & srcRect, Unit srcUnit, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
        {
            status := GdipEnumerateMetafileSrcRectDestPointsI( GpGraphics * graphics, GDIPCONST GpMetafile * metafile, GDIPCONST Point * destPoints, INT count, GDIPCONST Rect & srcRect, Unit srcUnit, EnumerateMetafileProc callback, VOID * callbackData, GDIPCONST GpImageAttributes * imageAttributes )
            Return status
        }
        
        ;####################################
        ; Call          PlayRecord( GDIPCONST GpMetafile * metafile, EmfPlusRecordType recordType, UINT flags, UINT dataSize, GDIPCONST BYTE * data )
        ; Description   Plays a metafile record.
        ;          
        ; Params        GDIPCONST GpMetafile * metafile, EmfPlusRecordType recordType, UINT flags, UINT dataSize, GDIPCONST BYTE * data 
        ;          
        ; Return        Status
        ;______________________________________
        PlayRecord( GDIPCONST GpMetafile * metafile, EmfPlusRecordType recordType, UINT flags, UINT dataSize, GDIPCONST BYTE * data )
        {
            status := GdipPlayMetafileRecord( GDIPCONST GpMetafile * metafile, EmfPlusRecordType recordType, UINT flags, UINT dataSize, GDIPCONST BYTE * data )
            Return status
        }
        
        ;####################################
        ; Call          SetClip(GpGraphics *graphics, GpGraphics *srcgraphics, CombineMode combineMode)
        ; Description   Updates the clipping region of this Graphics object to a region that is the combination of itself and the clipping region of another Graphics object.\nThe g parameter in the wrapper method corresponds to the srcgraphics parameter in the flat function.
        ;          
        ; Params        GpGraphics *graphics, GpGraphics *srcgraphics, CombineMode combineMode
        ;          
        ; Return        Status
        ;______________________________________
        SetClip(GpGraphics *graphics, GpGraphics *srcgraphics, CombineMode combineMode)
        {
            status := GdipSetClipGraphics(GpGraphics *graphics, GpGraphics *srcgraphics, CombineMode combineMode)
            Return status
        }
        
        ;####################################
        ; Call          SetClip(GpGraphics *graphics, REAL x, REAL y, REAL width, REAL height, CombineMode combineMode)
        ; Description   Updates the clipping region of this Graphics object to a region that is the combination of itself and a rectangle.\nThe x, y, width, and height parameters in the flat function specify a rectangle that corresponds to the rect parameter in the wrapper method.
        ;          
        ; Params        GpGraphics *graphics, REAL x, REAL y, REAL width, REAL height, CombineMode combineMode
        ;          
        ; Return        Status
        ;______________________________________
        SetClip(GpGraphics *graphics, REAL x, REAL y, REAL width, REAL height, CombineMode combineMode)
        {
            status := GdipSetClipRect(GpGraphics *graphics, REAL x, REAL y, REAL width, REAL height, CombineMode combineMode)
            Return status
        }
        
        ;####################################
        ; Call          SetClip(GpGraphics *graphics, INT x, INT y, INT width, INT height, CombineMode combineMode)
        ; Description   Updates the clipping region of this Graphics object to a region that is the combination of itself and a rectangle.\nThe x, y, width, and height parameters in the flat function specify a rectangle that corresponds to the rect parameter in the wrapper method.
        ;          
        ; Params        GpGraphics *graphics, INT x, INT y, INT width, INT height, CombineMode combineMode
        ;          
        ; Return        Status
        ;______________________________________
        SetClip(GpGraphics *graphics, INT x, INT y, INT width, INT height, CombineMode combineMode)
        {
            status := GdipSetClipRectI(GpGraphics *graphics, INT x, INT y, INT width, INT height, CombineMode combineMode)
            Return status
        }
        
        ;####################################
        ; Call          SetClip(GpGraphics *graphics, GpPath *path, CombineMode combineMode)
        ; Description   Updates the clipping region of this Graphics object to a region that is the combination of itself and the region specified by a graphics path. If a figure in the path is not closed, this method treats the nonclosed figure as if it were closed by a straight line that connects the figure's starting and ending points.
        ;          
        ; Params        GpGraphics *graphics, GpPath *path, CombineMode combineMode
        ;          
        ; Return        Status
        ;______________________________________
        SetClip(GpGraphics *graphics, GpPath *path, CombineMode combineMode)
        {
            status := GdipSetClipPath(GpGraphics *graphics, GpPath *path, CombineMode combineMode)
            Return status
        }
        
        ;####################################
        ; Call          SetClip(GpGraphics *graphics, GpRegion *region, CombineMode combineMode)
        ; Description   Updates the clipping region of this Graphics object to a region that is the combination of itself and the region specified by a Region object.
        ;          
        ; Params        GpGraphics *graphics, GpRegion *region, CombineMode combineMode
        ;          
        ; Return        Status
        ;______________________________________
        SetClip(GpGraphics *graphics, GpRegion *region, CombineMode combineMode)
        {
            status := GdipSetClipRegion(GpGraphics *graphics, GpRegion *region, CombineMode combineMode)
            Return status
        }
        
        ;####################################
        ; Call          SetClip(GpGraphics *graphics, HRGN hRgn, CombineMode combineMode)
        ; Description   Updates the clipping region of this Graphics object to a region that is the combination of itself and a Windows Graphics Device Interface (GDI) region
        ;          
        ; Params        GpGraphics *graphics, HRGN hRgn, CombineMode combineMode
        ;          
        ; Return        Status
        ;______________________________________
        SetClip(GpGraphics *graphics, HRGN hRgn, CombineMode combineMode)
        {
            status := GdipSetClipHrgn(GpGraphics *graphics, HRGN hRgn, CombineMode combineMode)
            Return status
        }
        
        ;####################################
        ; Call          ResetClip(GpGraphics *graphics)
        ; Description   Sets the clipping region of this Graphics object to an infinite region.
        ;          
        ; Params        GpGraphics *graphics
        ;          
        ; Return        Status
        ;______________________________________
        ResetClip(GpGraphics *graphics)
        {
            status := GdipResetClip(GpGraphics *graphics)
            Return status
        }
        
        ;####################################
        ; Call          TranslateClip(GpGraphics *graphics, REAL dx, REAL dy)
        ; Description   Translates the clipping region of this Graphics object.
        ;          
        ; Params        GpGraphics *graphics, REAL dx, REAL dy
        ;          
        ; Return        Status
        ;______________________________________
        TranslateClip(GpGraphics *graphics, REAL dx, REAL dy)
        {
            status := GdipTranslateClip(GpGraphics *graphics, REAL dx, REAL dy)
            Return status
        }
        
        ;####################################
        ; Call          TranslateClip(GpGraphics *graphics, INT dx, INT dy)
        ; Description   Translates the clipping region of this Graphics object.
        ;          
        ; Params        GpGraphics *graphics, INT dx, INT dy
        ;          
        ; Return        Status
        ;______________________________________
        TranslateClip(GpGraphics *graphics, INT dx, INT dy)
        {
            status := GdipTranslateClipI(GpGraphics *graphics, INT dx, INT dy)
            Return status
        }
        
        ;####################################
        ; Call          GetClip(GpGraphics *graphics, GpRegion *region)
        ; Description   Gets the clipping region of this Graphics object.
        ;          
        ; Params        GpGraphics *graphics, GpRegion *region
        ;          
        ; Return        Status
        ;______________________________________
        GetClip(GpGraphics *graphics, GpRegion *region)
        {
            status := GdipGetClip(GpGraphics *graphics, GpRegion *region)
            Return status
        }
        
        ;####################################
        ; Call          GetClipBounds(GpGraphics *graphics, GpRectF *rect)
        ; Description   Gets a rectangle that encloses the clipping region of this Graphics object.
        ;          
        ; Params        GpGraphics *graphics, GpRectF *rect
        ;          
        ; Return        Status
        ;______________________________________
        GetClipBounds(GpGraphics *graphics, GpRectF *rect)
        {
            status := GdipGetClipBounds(GpGraphics *graphics, GpRectF *rect)
            Return status
        }
        
        ;####################################
        ; Call          GetClipBounds(GpGraphics *graphics, GpRect *rect)
        ; Description   Gets a rectangle that encloses the clipping region of this Graphics object.
        ;          
        ; Params        GpGraphics *graphics, GpRect *rect
        ;          
        ; Return        Status
        ;______________________________________
        GetClipBounds(GpGraphics *graphics, GpRect *rect)
        {
            status := GdipGetClipBoundsI(GpGraphics *graphics, GpRect *rect)
            Return status
        }
        
        ;####################################
        ; Call          IsClipEmpty(GpGraphics *graphics, BOOL *result)
        ; Description   Determines whether the clipping region of this Graphics object is empty.
        ;          
        ; Params        GpGraphics *graphics, BOOL *result
        ;          
        ; Return        Status
        ;______________________________________
        IsClipEmpty(GpGraphics *graphics, BOOL *result)
        {
            status := GdipIsClipEmpty(GpGraphics *graphics, BOOL *result)
            Return status
        }
        
        ;####################################
        ; Call          GetVisibleClipBounds(GpGraphics *graphics, GpRectF *rect)
        ; Description   Gets a rectangle that encloses the visible clipping region of this Graphics object. The visible clipping region is the intersection of the clipping region of this Graphics object and the clipping region of the window.
        ;          
        ; Params        GpGraphics *graphics, GpRectF *rect
        ;          
        ; Return        Status
        ;______________________________________
        GetVisibleClipBounds(GpGraphics *graphics, GpRectF *rect)
        {
            status := GdipGetVisibleClipBounds(GpGraphics *graphics, GpRectF *rect)
            Return status
        }
        
        ;####################################
        ; Call          GetVisibleClipBounds(GpGraphics *graphics, GpRect *rect)
        ; Description   Gets a rectangle that encloses the visible clipping region of this Graphics object. The visible clipping region is the intersection of the clipping region of this Graphics object and the clipping region of the window.
        ;          
        ; Params        GpGraphics *graphics, GpRect *rect
        ;          
        ; Return        Status
        ;______________________________________
        GetVisibleClipBounds(GpGraphics *graphics, GpRect *rect)
        {
            status := GdipGetVisibleClipBoundsI(GpGraphics *graphics, GpRect *rect)
            Return status
        }
        
        ;####################################
        ; Call          IsVisibleClipEmpty(GpGraphics *graphics, BOOL *result)
        ; Description   Determines whether the visible clipping region of this Graphics object is empty. The visible clipping region is the intersection of the clipping region of this Graphics object and the clipping region of the window.
        ;          
        ; Params        GpGraphics *graphics, BOOL *result
        ;          
        ; Return        Status
        ;______________________________________
        IsVisibleClipEmpty(GpGraphics *graphics, BOOL *result)
        {
            status := GdipIsVisibleClipEmpty(GpGraphics *graphics, BOOL *result)
            Return status
        }
        
        ;####################################
        ; Call          IsVisible(GpGraphics *graphics, REAL x, REAL y, BOOL *result)
        ; Description   Determines whether the specified point is inside the visible clipping region of this Graphics object. The visible clipping region is the intersection of the clipping region of this Graphics object and the clipping region of the window.\nThe x and y parameters in the flat function represent the x and y coordinates of a point that corresponds to the point parameter in the wrapper method.
        ;          
        ; Params        GpGraphics *graphics, REAL x, REAL y, BOOL *result
        ;          
        ; Return        Status
        ;______________________________________
        IsVisible(GpGraphics *graphics, REAL x, REAL y, BOOL *result)
        {
            status := GdipIsVisiblePoint(GpGraphics *graphics, REAL x, REAL y, BOOL *result)
            Return status
        }
        
        ;####################################
        ; Call          IsVisible(GpGraphics *graphics, INT x, INT y, BOOL *result)
        ; Description   Determines whether the specified point is inside the visible clipping region of this Graphics object. The visible clipping region is the intersection of the clipping region of this Graphics object and the clipping region of the window.\nThe x and y parameters in the flat function represent the x and y coordinates of a point that corresponds to the point parameter in the wrapper method.
        ;          
        ; Params        GpGraphics *graphics, INT x, INT y, BOOL *result
        ;          
        ; Return        Status
        ;______________________________________
        IsVisible(GpGraphics *graphics, INT x, INT y, BOOL *result)
        {
            status := GdipIsVisiblePointI(GpGraphics *graphics, INT x, INT y, BOOL *result)
            Return status
        }
        
        ;####################################
        ; Call          IsVisible(GpGraphics *graphics, REAL x, REAL y, REAL width, REAL height, BOOL *result)
        ; Description   Determines whether the specified rectangle intersects the visible clipping region of this Graphics object. The visible clipping region is the intersection of the clipping region of this Graphics object and the clipping region of the window.\nThe x, y, width, and height parameters in the flat function specify a rectangle that corresponds to the rect parameter in the wrapper method.
        ;          
        ; Params        GpGraphics *graphics, REAL x, REAL y, REAL width, REAL height, BOOL *result
        ;          
        ; Return        Status
        ;______________________________________
        IsVisible(GpGraphics *graphics, REAL x, REAL y, REAL width, REAL height, BOOL *result)
        {
            status := GdipIsVisibleRect(GpGraphics *graphics, REAL x, REAL y, REAL width, REAL height, BOOL *result)
            Return status
        }
        
        ;####################################
        ; Call          IsVisible(GpGraphics *graphics, INT x, INT y, INT width, INT height, BOOL *result)
        ; Description   Determines whether the specified rectangle intersects the visible clipping region of this Graphics object. The visible clipping region is the intersection of the clipping region of this Graphics object and the clipping region of the window.\nThe x, y, width, and height parameters in the flat function specify a rectangle that corresponds to the rect parameter in the wrapper method.
        ;          
        ; Params        GpGraphics *graphics, INT x, INT y, INT width, INT height, BOOL *result
        ;          
        ; Return        Status
        ;______________________________________
        IsVisible(GpGraphics *graphics, INT x, INT y, INT width, INT height, BOOL *result)
        {
            status := GdipIsVisibleRectI(GpGraphics *graphics, INT x, INT y, INT width, INT height, BOOL *result)
            Return status
        }
        
        ;####################################
        ; Call          Save(GpGraphics *graphics, GraphicsState *state)
        ; Description   Saves the current state (transformations, clipping region, and quality settings) of this Graphics object. You can restore the state later by calling the Graphics::Restore method.
        ;          
        ; Params        GpGraphics *graphics, GraphicsState *state
        ;          
        ; Return        Status
        ;______________________________________
        Save(GpGraphics *graphics, GraphicsState *state)
        {
            status := GdipSaveGraphics(GpGraphics *graphics, GraphicsState *state)
            Return status
        }
        
        ;####################################
        ; Call          Restore(GpGraphics *graphics, GraphicsState state)
        ; Description   Sets the state of this Graphics object to the state stored by a previous call to the Graphics::Save method of this Graphics object.
        ;          
        ; Params        GpGraphics *graphics, GraphicsState state
        ;          
        ; Return        Status
        ;______________________________________
        Restore(GpGraphics *graphics, GraphicsState state)
        {
            status := GdipRestoreGraphics(GpGraphics *graphics, GraphicsState state)
            Return status
        }
        
        ;####################################
        ; Call          GraphicsContainer BeginContainer(GpGraphics *graphics, GDIPCONST GpRectF* dstrect, GDIPCONST GpRectF *srcrect, GpUnit unit, GraphicsContainer *state)
        ; Description   Begins a new graphics container.
        ;          
        ; Params        GpGraphics *graphics, GDIPCONST GpRectF* dstrect, GDIPCONST GpRectF *srcrect, GpUnit unit, GraphicsContainer *state
        ;          
        ; Return        Status
        ;______________________________________
        GraphicsContainer BeginContainer(GpGraphics *graphics, GDIPCONST GpRectF* dstrect, GDIPCONST GpRectF *srcrect, GpUnit unit, GraphicsContainer *state)
        {
            status := GdipBeginContainer(GpGraphics *graphics, GDIPCONST GpRectF* dstrect, GDIPCONST GpRectF *srcrect, GpUnit unit, GraphicsContainer *state)
            Return status
        }
        
        ;####################################
        ; Call          GraphicsContainer BeginContainer(GpGraphics *graphics, GDIPCONST GpRect* dstrect, GDIPCONST GpRect *srcrect, GpUnit unit, GraphicsContainer *state)
        ; Description   Begins a new graphics container.
        ;          
        ; Params        GpGraphics *graphics, GDIPCONST GpRect* dstrect, GDIPCONST GpRect *srcrect, GpUnit unit, GraphicsContainer *state
        ;          
        ; Return        Status
        ;______________________________________
        GraphicsContainer BeginContainer(GpGraphics *graphics, GDIPCONST GpRect* dstrect, GDIPCONST GpRect *srcrect, GpUnit unit, GraphicsContainer *state)
        {
            status := GdipBeginContainerI(GpGraphics *graphics, GDIPCONST GpRect* dstrect, GDIPCONST GpRect *srcrect, GpUnit unit, GraphicsContainer *state)
            Return status
        }
        
        ;####################################
        ; Call          GraphicsContainer BeginContainer(GpGraphics *graphics, GraphicsContainer* state)
        ; Description   Begins a new graphics container.
        ;          
        ; Params        GpGraphics *graphics, GraphicsContainer* state
        ;          
        ; Return        Status
        ;______________________________________
        GraphicsContainer BeginContainer(GpGraphics *graphics, GraphicsContainer* state)
        {
            status := GdipBeginContainer2(GpGraphics *graphics, GraphicsContainer* state)
            Return status
        }
        
        ;####################################
        ; Call          EndContainer(GpGraphics *graphics, GraphicsContainer state)
        ; Description   Closes a graphics container that was previously opened by the Graphics::BeginContainer method.
        ;          
        ; Params        GpGraphics *graphics, GraphicsContainer state
        ;          
        ; Return        Status
        ;______________________________________
        EndContainer(GpGraphics *graphics, GraphicsContainer state)
        {
            status := GdipEndContainer(GpGraphics *graphics, GraphicsContainer state)
            Return status
        }
        
        ;####################################
        ; Call          GetMetafileHeader( HENHMETAFILE hEmf, MetafileHeader * header )
        ; Description   Gets the header.
        ;          
        ; Params        HENHMETAFILE hEmf, MetafileHeader * header 
        ;          
        ; Return        Status
        ;______________________________________
        GetMetafileHeader( HENHMETAFILE hEmf, MetafileHeader * header )
        {
            status := GdipGetMetafileHeaderFromEmf( HENHMETAFILE hEmf, MetafileHeader * header )
            Return status
        }
        
        ;####################################
        ; Call          GetMetafileHeader( GDIPCONST WCHAR* filename, MetafileHeader * header )
        ; Description   Gets the header.
        ;          
        ; Params        GDIPCONST WCHAR* filename, MetafileHeader * header 
        ;          
        ; Return        Status
        ;______________________________________
        GetMetafileHeader( GDIPCONST WCHAR* filename, MetafileHeader * header )
        {
            status := GdipGetMetafileHeaderFromFile( GDIPCONST WCHAR* filename, MetafileHeader * header )
            Return status
        }
        
        ;####################################
        ; Call          GetMetafileHeader( IStream * stream, MetafileHeader * header )
        ; Description   Gets the header.
        ;          
        ; Params        IStream * stream, MetafileHeader * header 
        ;          
        ; Return        Status
        ;______________________________________
        GetMetafileHeader( IStream * stream, MetafileHeader * header )
        {
            status := GdipGetMetafileHeaderFromStream( IStream * stream, MetafileHeader * header )
            Return status
        }
        
        ;####################################
        ; Call          GetMetafileHeader( GpMetafile * metafile, MetafileHeader * header )
        ; Description   Gets the header.
        ;          
        ; Params        GpMetafile * metafile, MetafileHeader * header 
        ;          
        ; Return        Status
        ;______________________________________
        GetMetafileHeader( GpMetafile * metafile, MetafileHeader * header )
        {
            status := GdipGetMetafileHeaderFromMetafile( GpMetafile * metafile, MetafileHeader * header )
            Return status
        }
        
        ;####################################
        ; Call          GetHENHMETAFILE( GpMetafile * metafile, HENHMETAFILE * hEmf )
        ; Description   Gets a Windows handle to an Enhanced Metafile (EMF) file.
        ;          
        ; Params        GpMetafile * metafile, HENHMETAFILE * hEmf 
        ;          
        ; Return        Status
        ;______________________________________
        GetHENHMETAFILE( GpMetafile * metafile, HENHMETAFILE * hEmf )
        {
            status := GdipGetHemfFromMetafile( GpMetafile * metafile, HENHMETAFILE * hEmf )
            Return status
        }
        
        ;####################################
        ; Call          GdipCreateStreamOnFile(GDIPCONST WCHAR * filename, UINT access, IStream **stream)
        ; Description   Returns a pointer to an IStream interface based on a file. The filename parameter specifies the file. The access parameter is a set of flags that must include GENERIC_READ or GENERIC_WRITE. The stream parameter receives a pointer to the IStream interface.
        ;          
        ; Params        GDIPCONST WCHAR * filename, UINT access, IStream **stream
        ;          
        ; Return        Status
        ;______________________________________
        GdipCreateStreamOnFile(GDIPCONST WCHAR * filename, UINT access, IStream **stream)
        {
            status := GdipCreateStreamOnFile(GDIPCONST WCHAR * filename, UINT access, IStream **stream)
            Return status
        }
        
        ;####################################
        ; Call          Metafile(HMETAFILE hWmf, BOOL deleteWmf, GDIPCONST WmfPlaceableFileHeader * wmfPlaceableFileHeader, GpMetafile **metafile)
        ; Description   Creates a Windows GDI+ Metafile::Metafile object for recording. The format will be placeable metafile.
        ;          
        ; Params        HMETAFILE hWmf, BOOL deleteWmf, GDIPCONST WmfPlaceableFileHeader * wmfPlaceableFileHeader, GpMetafile **metafile
        ;          
        ; Return        Status
        ;______________________________________
        Metafile(HMETAFILE hWmf, BOOL deleteWmf, GDIPCONST WmfPlaceableFileHeader * wmfPlaceableFileHeader, GpMetafile **metafile)
        {
            status := GdipCreateMetafileFromWmf(HMETAFILE hWmf, BOOL deleteWmf, GDIPCONST WmfPlaceableFileHeader * wmfPlaceableFileHeader, GpMetafile **metafile)
            Return status
        }
        
        ;####################################
        ; Call          Metafile(HENHMETAFILE hEmf, BOOL deleteEmf, GpMetafile **metafile)
        ; Description   Creates a Windows GDI+ Metafile::Metafile object for playback based on a Windows Graphics Device Interface (EMF) file.
        ;          
        ; Params        HENHMETAFILE hEmf, BOOL deleteEmf, GpMetafile **metafile
        ;          
        ; Return        Status
        ;______________________________________
        Metafile(HENHMETAFILE hEmf, BOOL deleteEmf, GpMetafile **metafile)
        {
            status := GdipCreateMetafileFromEmf(HENHMETAFILE hEmf, BOOL deleteEmf, GpMetafile **metafile)
            Return status
        }
        
        ;####################################
        ; Call          Metafile(GDIPCONST WCHAR* file, GpMetafile **metafile)
        ; Description   Creates a Metafile::Metafile object for playback.
        ;          
        ; Params        GDIPCONST WCHAR* file, GpMetafile **metafile
        ;          
        ; Return        Status
        ;______________________________________
        Metafile(GDIPCONST WCHAR* file, GpMetafile **metafile)
        {
            status := GdipCreateMetafileFromFile(GDIPCONST WCHAR* file, GpMetafile **metafile)
            Return status
        }
        
        ;####################################
        ; Call          Metafile(IStream * stream, GpMetafile **metafile)
        ; Description   Creates a Metafile::Metafile object from an IStream interface for playback.
        ;          
        ; Params        IStream * stream, GpMetafile **metafile
        ;          
        ; Return        Status
        ;______________________________________
        Metafile(IStream * stream, GpMetafile **metafile)
        {
            status := GdipCreateMetafileFromStream(IStream * stream, GpMetafile **metafile)
            Return status
        }
        
        ;####################################
        ; Call          Metafile( HDC referenceHdc, EmfType type, GDIPCONST GpRectF * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile )
        ; Description   Creates a Metafile::Metafile object for recording.
        ;          
        ; Params        HDC referenceHdc, EmfType type, GDIPCONST GpRectF * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile 
        ;          
        ; Return        Status
        ;______________________________________
        Metafile( HDC referenceHdc, EmfType type, GDIPCONST GpRectF * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile )
        {
            status := GdipRecordMetafile( HDC referenceHdc, EmfType type, GDIPCONST GpRectF * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile )
            Return status
        }
        
        ;####################################
        ; Call          Metafile( HDC referenceHdc, EmfType type, GDIPCONST GpRect * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile )
        ; Description   Creates a Metafile::Metafile object for recording.
        ;          
        ; Params        HDC referenceHdc, EmfType type, GDIPCONST GpRect * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile 
        ;          
        ; Return        Status
        ;______________________________________
        Metafile( HDC referenceHdc, EmfType type, GDIPCONST GpRect * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile )
        {
            status := GdipRecordMetafileI( HDC referenceHdc, EmfType type, GDIPCONST GpRect * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile )
            Return status
        }
        
        ;####################################
        ; Call          Metafile( GDIPCONST WCHAR* fileName, HDC referenceHdc, EmfType type, GDIPCONST GpRectF * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile )
        ; Description   Creates a Metafile::Metafile object for recording.
        ;          
        ; Params        GDIPCONST WCHAR* fileName, HDC referenceHdc, EmfType type, GDIPCONST GpRectF * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile 
        ;          
        ; Return        Status
        ;______________________________________
        Metafile( GDIPCONST WCHAR* fileName, HDC referenceHdc, EmfType type, GDIPCONST GpRectF * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile )
        {
            status := GdipRecordMetafileFileName( GDIPCONST WCHAR* fileName, HDC referenceHdc, EmfType type, GDIPCONST GpRectF * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile )
            Return status
        }
        
        ;####################################
        ; Call          Metafile( GDIPCONST WCHAR* fileName, HDC referenceHdc, EmfType type, GDIPCONST GpRect * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile )
        ; Description   Creates a Metafile::Metafile object for recording.
        ;          
        ; Params        GDIPCONST WCHAR* fileName, HDC referenceHdc, EmfType type, GDIPCONST GpRect * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile 
        ;          
        ; Return        Status
        ;______________________________________
        Metafile( GDIPCONST WCHAR* fileName, HDC referenceHdc, EmfType type, GDIPCONST GpRect * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile )
        {
            status := GdipRecordMetafileFileNameI( GDIPCONST WCHAR* fileName, HDC referenceHdc, EmfType type, GDIPCONST GpRect * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile )
            Return status
        }
        
        ;####################################
        ; Call          Metafile( IStream * stream, HDC referenceHdc, EmfType type, GDIPCONST GpRectF * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile )
        ; Description   Creates a Metafile::Metafile object for recording to an IStream interface.
        ;          
        ; Params        IStream * stream, HDC referenceHdc, EmfType type, GDIPCONST GpRectF * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile 
        ;          
        ; Return        Status
        ;______________________________________
        Metafile( IStream * stream, HDC referenceHdc, EmfType type, GDIPCONST GpRectF * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile )
        {
            status := GdipRecordMetafileStream( IStream * stream, HDC referenceHdc, EmfType type, GDIPCONST GpRectF * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile )
            Return status
        }
        
        ;####################################
        ; Call          Metafile( IStream * stream, HDC referenceHdc, EmfType type, GDIPCONST GpRect * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile )
        ; Description   Creates a Metafile::Metafile object for recording to an IStream interface.
        ;          
        ; Params        IStream * stream, HDC referenceHdc, EmfType type, GDIPCONST GpRect * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile 
        ;          
        ; Return        Status
        ;______________________________________
        Metafile( IStream * stream, HDC referenceHdc, EmfType type, GDIPCONST GpRect * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile )
        {
            status := GdipRecordMetafileStreamI( IStream * stream, HDC referenceHdc, EmfType type, GDIPCONST GpRect * frameRect, MetafileFrameUnit frameUnit, GDIPCONST WCHAR * description, GpMetafile ** metafile )
            Return status
        }
        
        ;####################################
        ; Call          SetDownLevelRasterizationLimit( GpMetafile * metafile, UINT metafileRasterizationLimitDpi )
        ; Description   Sets the resolution for certain brush bitmaps that are stored in this metafile.
        ;          
        ; Params        GpMetafile * metafile, UINT metafileRasterizationLimitDpi 
        ;          
        ; Return        Status
        ;______________________________________
        SetDownLevelRasterizationLimit( GpMetafile * metafile, UINT metafileRasterizationLimitDpi )
        {
            status := GdipSetMetafileDownLevelRasterizationLimit( GpMetafile * metafile, UINT metafileRasterizationLimitDpi )
            Return status
        }
        
        ;####################################
        ; Call          GetDownLevelRasterizationLimit( GDIPCONST GpMetafile * metafile, UINT * metafileRasterizationLimitDpi )
        ; Description   Gets the rasterization limit currently set for this metafile. The rasterization limit is the resolution used for certain brush bitmaps that are stored in the metafile. For a detailed explanation of the rasterization limit, see Metafile::SetDownLevelRasterizationLimit.
        ;          
        ; Params        GDIPCONST GpMetafile * metafile, UINT * metafileRasterizationLimitDpi 
        ;          
        ; Return        Status
        ;______________________________________
        GetDownLevelRasterizationLimit( GDIPCONST GpMetafile * metafile, UINT * metafileRasterizationLimitDpi )
        {
            status := GdipGetMetafileDownLevelRasterizationLimit( GDIPCONST GpMetafile * metafile, UINT * metafileRasterizationLimitDpi )
            Return status
        }
        
        ;####################################
        ; Call          GetImageDecodersSize(UINT *numDecoders, UINT *size)
        ; Description   Gets the number of available image decoders and the total size of the array of ImageCodecInfo objects that is returned by the GetImageDecoders function.
        ;          
        ; Params        UINT *numDecoders, UINT *size 
        ;          
        ; Return        Status
        ;______________________________________
        GetImageDecodersSize(UINT *numDecoders, UINT *size)
        {
            status := GdipGetImageDecodersSize(UINT *numDecoders, UINT *size)
            Return status
        }
        
        ;####################################
        ; Call          GetImageDecoders(UINT *numDecoders, UINT *size)
        ; Description   Gets an array of ImageCodecInfo objects that contain information about the available image decoders.
        ;          
        ; Params        UINT numDecoders, UINT size, ImageCodecInfo *decoders 
        ;          
        ; Return        Status
        ;______________________________________
        GetImageDecoders(UINT numDecoders, UINT size, ImageCodecInfo *decoders)
        {
            status := GdipGetImageDecoders(UINT numDecoders, UINT size, ImageCodecInfo *decoders)
            Return status
        }
        
        ;####################################
        ; Call          GetImageEncodersSize(UINT *numEncoders, UINT *size)
        ; Description   Gets the number of available image encoders and the total size of the array of ImageCodecInfo objects that is returned by the GetImageEncoders function.
        ;          
        ; Params        UINT *numEncoders, UINT *size
        ;          
        ; Return        Status
        ;______________________________________
        GetImageEncodersSize(UINT *numEncoders, UINT *size)
        {
            status := GdipGetImageEncodersSize(UINT *numEncoders, UINT *size)
            Return status
        }
        
        ;####################################
        ; Call          GetImageEncoders(UINT *numDecoders, UINT *size)
        ; Description   Gets an array of ImageCodecInfo objects that contain information about the available image encoders.
        ;          
        ; Params        UINT *numDecoders, UINT *size 
        ;          
        ; Return        Status
        ;______________________________________
        GetImageEncoders(UINT *numDecoders, UINT *size)
        {
            status := GdipGetImageEncoders(UINT numEncoders, UINT size, ImageCodecInfo *encoders)
            Return status
        }
        
        ;####################################
        ; Call          AddMetafileComment(GpGraphics* graphics, UINT sizeData, GDIPCONST BYTE * data)
        ; Description   Adds a text comment to an existing metafile.
        ;          
        ; Params        GpGraphics* graphics, UINT sizeData, GDIPCONST BYTE * data
        ;          
        ; Return        Status
        ;______________________________________
        AddMetafileComment(GpGraphics* graphics, UINT sizeData, GDIPCONST BYTE * data)
        {
            status := GdipComment(GpGraphics* graphics, UINT sizeData, GDIPCONST BYTE * data)
            Return status
        }
    }
    
    Class GraphicsPath
    {
        ;####################################
        ; Call          GraphicsPath(GpFillMode brushMode, GpPath **path)
        ; Description   Creates a GraphicsPath object and initializes the fill mode. This is the default constructor.
        ;          
        ; Params        GpFillMode brushMode, GpPath **path
        ;          
        ; Return        Status
        ;______________________________________
        GraphicsPath(GpFillMode brushMode, GpPath **path)
        {
            status := GdipCreatePath(GpFillMode brushMode, GpPath **path)
            Return status
        }
        
        ;####################################
        ; Call          GraphicsPath(GDIPCONST GpPointF* points, GDIPCONST BYTE* types, INT count, GpFillMode fillMode, GpPath **path)
        ; Description   Creates a GraphicsPath object based on an array of points, an array of types, and a fill mode.
        ;          
        ; Params        GDIPCONST GpPointF* points, GDIPCONST BYTE* types, INT count, GpFillMode fillMode, GpPath **path
        ;          
        ; Return        Status
        ;______________________________________
        GraphicsPath(GDIPCONST GpPointF* points, GDIPCONST BYTE* types, INT count, GpFillMode fillMode, GpPath **path)
        {
            status := GdipCreatePath2(GDIPCONST GpPointF* points, GDIPCONST BYTE* types, INT count, GpFillMode fillMode, GpPath **path)
            Return status
        }
        
        ;####################################
        ; Call          GraphicsPath(GDIPCONST GpPoint* points, GDIPCONST BYTE* types, INT count, GpFillMode fillMode, GpPath **path)
        ; Description   Creates a GraphicsPath object based on an array of points, an array of types, and a fill mode.
        ;          
        ; Params        GDIPCONST GpPoint* points, GDIPCONST BYTE* types, INT count, GpFillMode fillMode, GpPath **path
        ;          
        ; Return        Status
        ;______________________________________
        GraphicsPath(GDIPCONST GpPoint* points, GDIPCONST BYTE* types, INT count, GpFillMode fillMode, GpPath **path)
        {
            status := GdipCreatePath2I(GDIPCONST GpPoint* points, GDIPCONST BYTE* types, INT count, GpFillMode fillMode, GpPath **path)
            Return status
        }
        
        ;####################################
        ; Call          GraphicsPath* Clone(GpPath* path, GpPath **clonePath)
        ; Description   Creates a new GraphicsPath object, and initializes it with the contents of this GraphicsPath object.
        ;          
        ; Params        GpPath* path, GpPath **clonePath
        ;          
        ; Return        Status
        ;______________________________________
        GraphicsPath* Clone(GpPath* path, GpPath **clonePath)
        {
            status := GdipClonePath(GpPath* path, GpPath **clonePath)
            Return status
        }
        
        ;####################################
        ; Call          ~GraphicsPath(GpPath* path)
        ; Description   Releases resources used by the GraphicsPath object.
        ;          
        ; Params        GpPath* path
        ;          
        ; Return        Status
        ;______________________________________
        ~GraphicsPath(GpPath* path)
        {
            status := GdipDeletePath(GpPath* path)
            Return status
        }
        
        ;####################################
        ; Call          Reset(GpPath* path)
        ; Description   Empties the path and sets the fill mode to FillModeAlternate.
        ;          
        ; Params        GpPath* path
        ;          
        ; Return        Status
        ;______________________________________
        Reset(GpPath* path)
        {
            status := GdipResetPath(GpPath* path)
            Return status
        }
        
        ;####################################
        ; Call          GetPointCount(GpPath* path, INT* count)
        ; Description   Gets the number of points in this path's array of data points. This is the same as the number of types in the path's array of point types.
        ;          
        ; Params        GpPath* path, INT* count
        ;          
        ; Return        Status
        ;______________________________________
        GetPointCount(GpPath* path, INT* count)
        {
            status := GdipGetPointCount(GpPath* path, INT* count)
            Return status
        }
        
        ;####################################
        ; Call          GetPathTypes(GpPath* path, BYTE* types, INT count)
        ; Description   Gets this path's array of point types.
        ;          
        ; Params        GpPath* path, BYTE* types, INT count
        ;          
        ; Return        Status
        ;______________________________________
        GetPathTypes(GpPath* path, BYTE* types, INT count)
        {
            status := GdipGetPathTypes(GpPath* path, BYTE* types, INT count)
            Return status
        }
        
        ;####################################
        ; Call          GetPathPoints(GpPath*, GpPointF* points, INT count)
        ; Description   Gets this path's array of points. The array contains the endpoints and control points of the lines and Bézier splines that are used to draw the path.
        ;          
        ; Params        GpPath*, GpPointF* points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        GetPathPoints(GpPath*, GpPointF* points, INT count)
        {
            status := GdipGetPathPoints(GpPath*, GpPointF* points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          GetPathPoints(GpPath*, GpPoint* points, INT count)
        ; Description   Gets this path's array of points. The array contains the endpoints and control points of the lines and Bézier splines that are used to draw the path.
        ;          
        ; Params        GpPath*, GpPoint* points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        GetPathPoints(GpPath*, GpPoint* points, INT count)
        {
            status := GdipGetPathPointsI(GpPath*, GpPoint* points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          GetFillMode(GpPath *path, GpFillMode *fillmode)
        ; Description   Gets the fill mode of this path.
        ;          
        ; Params        GpPath *path, GpFillMode *fillmode
        ;          
        ; Return        Status
        ;______________________________________
        GetFillMode(GpPath *path, GpFillMode *fillmode)
        {
            status := GdipGetPathFillMode(GpPath *path, GpFillMode *fillmode)
            Return status
        }
        
        ;####################################
        ; Call          SetFillMode(GpPath *path, GpFillMode fillmode)
        ; Description   Sets the fill mode of this path.
        ;          
        ; Params        GpPath *path, GpFillMode fillmode
        ;          
        ; Return        Status
        ;______________________________________
        SetFillMode(GpPath *path, GpFillMode fillmode)
        {
            status := GdipSetPathFillMode(GpPath *path, GpFillMode fillmode)
            Return status
        }
        
        ;####################################
        ; Call          GetPathData(GpPath *path, GpPathData* pathData)
        ; Description   Gets an array of points and an array of point types from this path. Together, these two arrays define the lines, curves, figures, and markers of this path.
        ;          
        ; Params        GpPath *path, GpPathData* pathData
        ;          
        ; Return        Status
        ;______________________________________
        GetPathData(GpPath *path, GpPathData* pathData)
        {
            status := GdipGetPathData(GpPath *path, GpPathData* pathData)
            Return status
        }
        
        ;####################################
        ; Call          StartFigure(GpPath *path)
        ; Description   Starts a new figure without closing the current figure. Subsequent points added to this path are added to the new figure.
        ;          
        ; Params        GpPath *path
        ;          
        ; Return        Status
        ;______________________________________
        StartFigure(GpPath *path)
        {
            status := GdipStartPathFigure(GpPath *path)
            Return status
        }
        
        ;####################################
        ; Call          CloseFigure(GpPath *path)
        ; Description   Closes the current figure of this path.
        ;          
        ; Params        GpPath *path
        ;          
        ; Return        Status
        ;______________________________________
        CloseFigure(GpPath *path)
        {
            status := GdipClosePathFigure(GpPath *path)
            Return status
        }
        
        ;####################################
        ; Call          CloseAllFigures(GpPath *path)
        ; Description   Closes all open figures in this path.
        ;          
        ; Params        GpPath *path
        ;          
        ; Return        Status
        ;______________________________________
        CloseAllFigures(GpPath *path)
        {
            status := GdipClosePathFigures(GpPath *path)
            Return status
        }
        
        ;####################################
        ; Call          SetMarker(GpPath* path)
        ; Description   Designates the last point in this path as a marker point.
        ;          
        ; Params        GpPath* path
        ;          
        ; Return        Status
        ;______________________________________
        SetMarker(GpPath* path)
        {
            status := GdipSetPathMarker(GpPath* path)
            Return status
        }
        
        ;####################################
        ; Call          ClearMarkers(GpPath* path)
        ; Description   Clears the markers from this path.
        ;          
        ; Params        GpPath* path
        ;          
        ; Return        Status
        ;______________________________________
        ClearMarkers(GpPath* path)
        {
            status := GdipClearPathMarkers(GpPath* path)
            Return status
        }
        
        ;####################################
        ; Call          Reverse(GpPath* path)
        ; Description   Reverses the order of the points that define this path's lines and curves.
        ;          
        ; Params        GpPath* path
        ;          
        ; Return        Status
        ;______________________________________
        Reverse(GpPath* path)
        {
            status := GdipReversePath(GpPath* path)
            Return status
        }
        
        ;####################################
        ; Call          GetLastPoint(GpPath* path, GpPointF* lastPoint)
        ; Description   Gets the ending point of the last figure in this path.
        ;          
        ; Params        GpPath* path, GpPointF* lastPoint
        ;          
        ; Return        Status
        ;______________________________________
        GetLastPoint(GpPath* path, GpPointF* lastPoint)
        {
            status := GdipGetPathLastPoint(GpPath* path, GpPointF* lastPoint)
            Return status
        }
        
        ;####################################
        ; Call          AddLine(GpPath *path, REAL x1, REAL y1, REAL x2, REAL y2)
        ; Description   Adds a line to the current figure of this path.
        ;          
        ; Params        GpPath *path, REAL x1, REAL y1, REAL x2, REAL y2
        ;          
        ; Return        Status
        ;______________________________________
        AddLine(GpPath *path, REAL x1, REAL y1, REAL x2, REAL y2)
        {
            status := GdipAddPathLine(GpPath *path, REAL x1, REAL y1, REAL x2, REAL y2)
            Return status
        }
        
        ;####################################
        ; Call          AddLines(GpPath *path, GDIPCONST GpPointF *points, INT count)
        ; Description   Adds a sequence of connected lines to the current figure of this path.
        ;          
        ; Params        GpPath *path, GDIPCONST GpPointF *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        AddLines(GpPath *path, GDIPCONST GpPointF *points, INT count)
        {
            status := GdipAddPathLine2(GpPath *path, GDIPCONST GpPointF *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          AddArc(GpPath *path, REAL x, REAL y, REAL width, REAL height, REAL startAngle, REAL sweepAngle)
        ; Description   Adds an elliptical arc to the current figure of this path.
        ;          
        ; Params        GpPath *path, REAL x, REAL y, REAL width, REAL height, REAL startAngle, REAL sweepAngle
        ;          
        ; Return        Status
        ;______________________________________
        AddArc(GpPath *path, REAL x, REAL y, REAL width, REAL height, REAL startAngle, REAL sweepAngle)
        {
            status := GdipAddPathArc(GpPath *path, REAL x, REAL y, REAL width, REAL height, REAL startAngle, REAL sweepAngle)
            Return status
        }
        
        ;####################################
        ; Call          AddBezier(GpPath *path, REAL x1, REAL y1, REAL x2, REAL y2, REAL x3, REAL y3, REAL x4, REAL y4)
        ; Description   Adds a Bézier spline to the current figure of this path.
        ;          
        ; Params        GpPath *path, REAL x1, REAL y1, REAL x2, REAL y2, REAL x3, REAL y3, REAL x4, REAL y4
        ;          
        ; Return        Status
        ;______________________________________
        AddBezier(GpPath *path, REAL x1, REAL y1, REAL x2, REAL y2, REAL x3, REAL y3, REAL x4, REAL y4)
        {
            status := GdipAddPathBezier(GpPath *path, REAL x1, REAL y1, REAL x2, REAL y2, REAL x3, REAL y3, REAL x4, REAL y4)
            Return status
        }
        
        ;####################################
        ; Call          AddBeziers(GpPath *path, GDIPCONST GpPointF *points, INT count)
        ; Description   Adds a sequence of connected Bézier splines to the current figure of this path.
        ;          
        ; Params        GpPath *path, GDIPCONST GpPointF *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        AddBeziers(GpPath *path, GDIPCONST GpPointF *points, INT count)
        {
            status := GdipAddPathBeziers(GpPath *path, GDIPCONST GpPointF *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          AddCurve(GpPath *path, GDIPCONST GpPointF *points, INT count)
        ; Description   Adds a cardinal spline to the current figure of this path.
        ;          
        ; Params        GpPath *path, GDIPCONST GpPointF *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        AddCurve(GpPath *path, GDIPCONST GpPointF *points, INT count)
        {
            status := GdipAddPathCurve(GpPath *path, GDIPCONST GpPointF *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          AddCurve(GpPath *path, GDIPCONST GpPointF *points, INT count, REAL tension)
        ; Description   Adds a cardinal spline to the current figure of this path.
        ;          
        ; Params        GpPath *path, GDIPCONST GpPointF *points, INT count, REAL tension
        ;          
        ; Return        Status
        ;______________________________________
        AddCurve(GpPath *path, GDIPCONST GpPointF *points, INT count, REAL tension)
        {
            status := GdipAddPathCurve2(GpPath *path, GDIPCONST GpPointF *points, INT count, REAL tension)
            Return status
        }
        
        ;####################################
        ; Call          AddCurve(GpPath *path, GDIPCONST GpPointF *points, INT count, INT offset, INT numberOfSegments, REAL tension)
        ; Description   Adds a cardinal spline to the current figure of this path.
        ;          
        ; Params        GpPath *path, GDIPCONST GpPointF *points, INT count, INT offset, INT numberOfSegments, REAL tension
        ;          
        ; Return        Status
        ;______________________________________
        AddCurve(GpPath *path, GDIPCONST GpPointF *points, INT count, INT offset, INT numberOfSegments, REAL tension)
        {
            status := GdipAddPathCurve3(GpPath *path, GDIPCONST GpPointF *points, INT count, INT offset, INT numberOfSegments, REAL tension)
            Return status
        }
        
        ;####################################
        ; Call          AddClosedCurve(GpPath *path, GDIPCONST GpPointF *points, INT count)
        ; Description   Adds a closed cardinal spline to this path.
        ;          
        ; Params        GpPath *path, GDIPCONST GpPointF *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        AddClosedCurve(GpPath *path, GDIPCONST GpPointF *points, INT count)
        {
            status := GdipAddPathClosedCurve(GpPath *path, GDIPCONST GpPointF *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          AddClosedCurve(GpPath *path, GDIPCONST GpPointF *points, INT count, REAL tension)
        ; Description   Adds a closed cardinal spline to this path.
        ;          
        ; Params        GpPath *path, GDIPCONST GpPointF *points, INT count, REAL tension
        ;          
        ; Return        Status
        ;______________________________________
        AddClosedCurve(GpPath *path, GDIPCONST GpPointF *points, INT count, REAL tension)
        {
            status := GdipAddPathClosedCurve2(GpPath *path, GDIPCONST GpPointF *points, INT count, REAL tension)
            Return status
        }
        
        ;####################################
        ; Call          AddRectangle(GpPath *path, REAL x, REAL y, REAL width, REAL height)
        ; Description   Adds a rectangle to this path.\nThe x, y, width, and height parameters in the flat function specify a rectangle that corresponds to the rect parameter in the wrapper method.
        ;          
        ; Params        GpPath *path, REAL x, REAL y, REAL width, REAL height
        ;          
        ; Return        Status
        ;______________________________________
        AddRectangle(GpPath *path, REAL x, REAL y, REAL width, REAL height)
        {
            status := GdipAddPathRectangle(GpPath *path, REAL x, REAL y, REAL width, REAL height)
            Return status
        }
        
        ;####################################
        ; Call          AddRectangles(GpPath *path, GDIPCONST GpRectF *rects, INT count)
        ; Description   Adds a sequence of rectangles to this path.
        ;          
        ; Params        GpPath *path, GDIPCONST GpRectF *rects, INT count
        ;          
        ; Return        Status
        ;______________________________________
        AddRectangles(GpPath *path, GDIPCONST GpRectF *rects, INT count)
        {
            status := GdipAddPathRectangles(GpPath *path, GDIPCONST GpRectF *rects, INT count)
            Return status
        }
        
        ;####################################
        ; Call          AddEllipse(GpPath *path, REAL x, REAL y, REAL width, REAL height)
        ; Description   Adds an ellipse to this path.
        ;          
        ; Params        GpPath *path, REAL x, REAL y, REAL width, REAL height
        ;          
        ; Return        Status
        ;______________________________________
        AddEllipse(GpPath *path, REAL x, REAL y, REAL width, REAL height)
        {
            status := GdipAddPathEllipse(GpPath *path, REAL x, REAL y, REAL width, REAL height)
            Return status
        }
        
        ;####################################
        ; Call          AddPie(GpPath *path, REAL x, REAL y, REAL width, REAL height, REAL startAngle, REAL sweepAngle)
        ; Description   Adds a pie to this path. An arc is a portion of an ellipse, and a pie is a portion of the area enclosed by an ellipse. A pie is bounded by an arc and two lines (edges) that go from the center of the ellipse to the endpoints of the arc.
        ;          
        ; Params        GpPath *path, REAL x, REAL y, REAL width, REAL height, REAL startAngle, REAL sweepAngle
        ;          
        ; Return        Status
        ;______________________________________
        AddPie(GpPath *path, REAL x, REAL y, REAL width, REAL height, REAL startAngle, REAL sweepAngle)
        {
            status := GdipAddPathPie(GpPath *path, REAL x, REAL y, REAL width, REAL height, REAL startAngle, REAL sweepAngle)
            Return status
        }
        
        ;####################################
        ; Call          AddPolygon(GpPath *path, GDIPCONST GpPointF *points, INT count)
        ; Description   Adds a polygon to this path.
        ;          
        ; Params        GpPath *path, GDIPCONST GpPointF *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        AddPolygon(GpPath *path, GDIPCONST GpPointF *points, INT count)
        {
            status := GdipAddPathPolygon(GpPath *path, GDIPCONST GpPointF *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          AddPath(GpPath *path, GDIPCONST GpPath* addingPath, BOOL connect)
        ; Description   Adds a path to this path.
        ;          
        ; Params        GpPath *path, GDIPCONST GpPath* addingPath, BOOL connect
        ;          
        ; Return        Status
        ;______________________________________
        AddPath(GpPath *path, GDIPCONST GpPath* addingPath, BOOL connect)
        {
            status := GdipAddPathPath(GpPath *path, GDIPCONST GpPath* addingPath, BOOL connect)
            Return status
        }
        
        ;####################################
        ; Call          AddString(GpPath *path, GDIPCONST WCHAR *string, INT length, GDIPCONST GpFontFamily *family, INT style, REAL emSize, GDIPCONST RectF *layoutRect, GDIPCONST GpStringFormat *format)
        ; Description   Adds the outline of a string to this path.
        ;          
        ; Params        GpPath *path, GDIPCONST WCHAR *string, INT length, GDIPCONST GpFontFamily *family, INT style, REAL emSize, GDIPCONST RectF *layoutRect, GDIPCONST GpStringFormat *format
        ;          
        ; Return        Status
        ;______________________________________
        AddString(GpPath *path, GDIPCONST WCHAR *string, INT length, GDIPCONST GpFontFamily *family, INT style, REAL emSize, GDIPCONST RectF *layoutRect, GDIPCONST GpStringFormat *format)
        {
            status := GdipAddPathString(GpPath *path, GDIPCONST WCHAR *string, INT length, GDIPCONST GpFontFamily *family, INT style, REAL emSize, GDIPCONST RectF *layoutRect, GDIPCONST GpStringFormat *format)
            Return status
        }
        
        ;####################################
        ; Call          AddString(GpPath *path, GDIPCONST WCHAR *string, INT length, GDIPCONST GpFontFamily *family, INT style, REAL emSize, GDIPCONST Rect *layoutRect, GDIPCONST GpStringFormat *format)
        ; Description   Adds the outline of a string to this path.
        ;          
        ; Params        GpPath *path, GDIPCONST WCHAR *string, INT length, GDIPCONST GpFontFamily *family, INT style, REAL emSize, GDIPCONST Rect *layoutRect, GDIPCONST GpStringFormat *format
        ;          
        ; Return        Status
        ;______________________________________
        AddString(GpPath *path, GDIPCONST WCHAR *string, INT length, GDIPCONST GpFontFamily *family, INT style, REAL emSize, GDIPCONST Rect *layoutRect, GDIPCONST GpStringFormat *format)
        {
            status := GdipAddPathStringI(GpPath *path, GDIPCONST WCHAR *string, INT length, GDIPCONST GpFontFamily *family, INT style, REAL emSize, GDIPCONST Rect *layoutRect, GDIPCONST GpStringFormat *format)
            Return status
        }
        
        ;####################################
        ; Call          AddLine(GpPath *path, INT x1, INT y1, INT x2, INT y2)
        ; Description   Adds a line to the current figure of this path.
        ;          
        ; Params        GpPath *path, INT x1, INT y1, INT x2, INT y2
        ;          
        ; Return        Status
        ;______________________________________
        AddLine(GpPath *path, INT x1, INT y1, INT x2, INT y2)
        {
            status := GdipAddPathLineI(GpPath *path, INT x1, INT y1, INT x2, INT y2)
            Return status
        }
        
        ;####################################
        ; Call          AddLines(GpPath *path, GDIPCONST GpPoint *points, INT count)
        ; Description   Adds a sequence of connected lines to the current figure of this path.
        ;          
        ; Params        GpPath *path, GDIPCONST GpPoint *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        AddLines(GpPath *path, GDIPCONST GpPoint *points, INT count)
        {
            status := GdipAddPathLine2I(GpPath *path, GDIPCONST GpPoint *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          AddArc(GpPath *path, INT x, INT y, INT width, INT height, REAL startAngle, REAL sweepAngle)
        ; Description   Adds an elliptical arc to the current figure of this path.
        ;          
        ; Params        GpPath *path, INT x, INT y, INT width, INT height, REAL startAngle, REAL sweepAngle
        ;          
        ; Return        Status
        ;______________________________________
        AddArc(GpPath *path, INT x, INT y, INT width, INT height, REAL startAngle, REAL sweepAngle)
        {
            status := GdipAddPathArcI(GpPath *path, INT x, INT y, INT width, INT height, REAL startAngle, REAL sweepAngle)
            Return status
        }
        
        ;####################################
        ; Call          AddBezier(GpPath *path, INT x1, INT y1, INT x2, INT y2, INT x3, INT y3, INT x4, INT y4)
        ; Description   Adds a Bézier spline to the current figure of this path.
        ;          
        ; Params        GpPath *path, INT x1, INT y1, INT x2, INT y2, INT x3, INT y3, INT x4, INT y4
        ;          
        ; Return        Status
        ;______________________________________
        AddBezier(GpPath *path, INT x1, INT y1, INT x2, INT y2, INT x3, INT y3, INT x4, INT y4)
        {
            status := GdipAddPathBezierI(GpPath *path, INT x1, INT y1, INT x2, INT y2, INT x3, INT y3, INT x4, INT y4)
            Return status
        }
        
        ;####################################
        ; Call          AddBeziers(GpPath *path, GDIPCONST GpPoint *points, INT count)
        ; Description   Adds a Bézier spline to the current figure of this path.
        ;          
        ; Params        GpPath *path, GDIPCONST GpPoint *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        AddBeziers(GpPath *path, GDIPCONST GpPoint *points, INT count)
        {
            status := GdipAddPathBeziersI(GpPath *path, GDIPCONST GpPoint *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          AddCurve(GpPath *path, GDIPCONST GpPoint *points, INT count)
        ; Description   Adds a cardinal spline to the current figure of this path.
        ;          
        ; Params        GpPath *path, GDIPCONST GpPoint *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        AddCurve(GpPath *path, GDIPCONST GpPoint *points, INT count)
        {
            status := GdipAddPathCurveI(GpPath *path, GDIPCONST GpPoint *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          AddCurve(GpPath *path, GDIPCONST GpPoint *points, INT count, REAL tension)
        ; Description   Adds a cardinal spline to the current figure of this path.
        ;          
        ; Params        GpPath *path, GDIPCONST GpPoint *points, INT count, REAL tension
        ;          
        ; Return        Status
        ;______________________________________
        AddCurve(GpPath *path, GDIPCONST GpPoint *points, INT count, REAL tension)
        {
            status := GdipAddPathCurve2I(GpPath *path, GDIPCONST GpPoint *points, INT count, REAL tension)
            Return status
        }
        
        ;####################################
        ; Call          AddCurve(GpPath *path, GDIPCONST GpPoint *points, INT count, INT offset, INT numberOfSegments, REAL tension)
        ; Description   Adds a cardinal spline to the current figure of this path.
        ;          
        ; Params        GpPath *path, GDIPCONST GpPoint *points, INT count, INT offset, INT numberOfSegments, REAL tension
        ;          
        ; Return        Status
        ;______________________________________
        AddCurve(GpPath *path, GDIPCONST GpPoint *points, INT count, INT offset, INT numberOfSegments, REAL tension)
        {
            status := GdipAddPathCurve3I(GpPath *path, GDIPCONST GpPoint *points, INT count, INT offset, INT numberOfSegments, REAL tension)
            Return status
        }
        
        ;####################################
        ; Call          AddClosedCurve(GpPath *path, GDIPCONST GpPoint *points, INT count)
        ; Description   Adds a closed cardinal spline to this path.
        ;          
        ; Params        GpPath *path, GDIPCONST GpPoint *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        AddClosedCurve(GpPath *path, GDIPCONST GpPoint *points, INT count)
        {
            status := GdipAddPathClosedCurveI(GpPath *path, GDIPCONST GpPoint *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          AddClosedCurve(GpPath *path, GDIPCONST GpPoint *points, INT count, REAL tension)
        ; Description   Adds a closed cardinal spline to this path.
        ;          
        ; Params        GpPath *path, GDIPCONST GpPoint *points, INT count, REAL tension
        ;          
        ; Return        Status
        ;______________________________________
        AddClosedCurve(GpPath *path, GDIPCONST GpPoint *points, INT count, REAL tension)
        {
            status := GdipAddPathClosedCurve2I(GpPath *path, GDIPCONST GpPoint *points, INT count, REAL tension)
            Return status
        }
        
        ;####################################
        ; Call          AddRectangle(GpPath *path, INT x, INT y, INT width, INT height)
        ; Description   Adds a rectangle to this path.\nThe x, y, width, and height parameters in the flat function specify a rectangle that corresponds to the rect parameter in the wrapper method.
        ;          
        ; Params        GpPath *path, INT x, INT y, INT width, INT height
        ;          
        ; Return        Status
        ;______________________________________
        AddRectangle(GpPath *path, INT x, INT y, INT width, INT height)
        {
            status := GdipAddPathRectangleI(GpPath *path, INT x, INT y, INT width, INT height)
            Return status
        }
        
        ;####################################
        ; Call          AddRectangles(GpPath *path, GDIPCONST GpRect *rects, INT count)
        ; Description   Adds a sequence of rectangles to this path
        ;          
        ; Params        GpPath *path, GDIPCONST GpRect *rects, INT count
        ;          
        ; Return        Status
        ;______________________________________
        AddRectangles(GpPath *path, GDIPCONST GpRect *rects, INT count)
        {
            status := GdipAddPathRectanglesI(GpPath *path, GDIPCONST GpRect *rects, INT count)
            Return status
        }
        
        ;####################################
        ; Call          AddEllipse(GpPath *path, INT x, INT y, INT width, INT height)
        ; Description   Adds an ellipse to this path.
        ;          
        ; Params        GpPath *path, INT x, INT y, INT width, INT height
        ;          
        ; Return        Status
        ;______________________________________
        AddEllipse(GpPath *path, INT x, INT y, INT width, INT height)
        {
            status := GdipAddPathEllipseI(GpPath *path, INT x, INT y, INT width, INT height)
            Return status
        }
        
        ;####################################
        ; Call          AddPie(GpPath *path, INT x, INT y, INT width, INT height, REAL startAngle, REAL sweepAngle)
        ; Description   Adds a pie to this path. An arc is a portion of an ellipse, and a pie is a portion of the area enclosed by an ellipse. A pie is bounded by an arc and two lines (edges) that go from the center of the ellipse to the endpoints of the arc.
        ;          
        ; Params        GpPath *path, INT x, INT y, INT width, INT height, REAL startAngle, REAL sweepAngle
        ;          
        ; Return        Status
        ;______________________________________
        AddPie(GpPath *path, INT x, INT y, INT width, INT height, REAL startAngle, REAL sweepAngle)
        {
            status := GdipAddPathPieI(GpPath *path, INT x, INT y, INT width, INT height, REAL startAngle, REAL sweepAngle)
            Return status
        }
        
        ;####################################
        ; Call          AddPolygon(GpPath *path, GDIPCONST GpPoint *points, INT count)
        ; Description   Adds a polygon to this path.
        ;          
        ; Params        GpPath *path, GDIPCONST GpPoint *points, INT count
        ;          
        ; Return        Status
        ;______________________________________
        AddPolygon(GpPath *path, GDIPCONST GpPoint *points, INT count)
        {
            status := GdipAddPathPolygonI(GpPath *path, GDIPCONST GpPoint *points, INT count)
            Return status
        }
        
        ;####################################
        ; Call          Flatten(GpPath *path, GpMatrix* matrix, REAL flatness)
        ; Description   Applies a transformation to this path and converts each curve in the path to a sequence of connected lines.
        ;          
        ; Params        GpPath *path, GpMatrix* matrix, REAL flatness
        ;          
        ; Return        Status
        ;______________________________________
        Flatten(GpPath *path, GpMatrix* matrix, REAL flatness)
        {
            status := GdipFlattenPath(GpPath *path, GpMatrix* matrix, REAL flatness)
            Return status
        }
        
        ;####################################
        ; Call          Outline( GpPath *path, GpMatrix *matrix, REAL flatness )
        ; Description   Transforms and flattens this path, and then converts this path's data points so that they represent only the outline of the path.
        ;          
        ; Params        GpPath *path, GpMatrix *matrix, REAL flatness 
        ;          
        ; Return        Status
        ;______________________________________
        Outline( GpPath *path, GpMatrix *matrix, REAL flatness )
        {
            status := GdipWindingModeOutline( GpPath *path, GpMatrix *matrix, REAL flatness )
            Return status
        }
        
        ;####################################
        ; Call          Widen( GpPath *nativePath, GpPen *pen, GpMatrix *matrix, REAL flatness )
        ; Description   Replaces this path with curves that enclose the area that is filled when this path is drawn by a specified pen. This method also flattens the path.
        ;          
        ; Params        GpPath *nativePath, GpPen *pen, GpMatrix *matrix, REAL flatness 
        ;          
        ; Return        Status
        ;______________________________________
        Widen( GpPath *nativePath, GpPen *pen, GpMatrix *matrix, REAL flatness )
        {
            status := GdipWidenPath( GpPath *nativePath, GpPen *pen, GpMatrix *matrix, REAL flatness )
            Return status
        }
        
        ;####################################
        ; Call          Warp(GpPath *path, GpMatrix* matrix, GDIPCONST GpPointF *points, INT count, REAL srcx, REAL srcy, REAL srcwidth, REAL srcheight, WarpMode warpMode, REAL flatness)
        ; Description   Applies a warp transformation to this path. This method also flattens (converts to a sequence of straight lines) the path.\nThe srcx, srcy, srcwidth, and srcheight parameters in the flat function specify a rectangle that corresponds to the srcRect parameter in the wrapper method.
        ;          
        ; Params        GpPath *path, GpMatrix* matrix, GDIPCONST GpPointF *points, INT count, REAL srcx, REAL srcy, REAL srcwidth, REAL srcheight, WarpMode warpMode, REAL flatness
        ;          
        ; Return        Status
        ;______________________________________
        Warp(GpPath *path, GpMatrix* matrix, GDIPCONST GpPointF *points, INT count, REAL srcx, REAL srcy, REAL srcwidth, REAL srcheight, WarpMode warpMode, REAL flatness)
        {
            status := GdipWarpPath(GpPath *path, GpMatrix* matrix, GDIPCONST GpPointF *points, INT count, REAL srcx, REAL srcy, REAL srcwidth, REAL srcheight, WarpMode warpMode, REAL flatness)
            Return status
        }
        
        ;####################################
        ; Call          Transform(GpPath* path, GpMatrix* matrix)
        ; Description   Multiplies each of this path's data points by a specified matrix.
        ;          
        ; Params        GpPath* path, GpMatrix* matrix
        ;          
        ; Return        Status
        ;______________________________________
        Transform(GpPath* path, GpMatrix* matrix)
        {
            status := GdipTransformPath(GpPath* path, GpMatrix* matrix)
            Return status
        }
        
        ;####################################
        ; Call          GetBounds(GpPath* path, GpRectF* bounds, GDIPCONST GpMatrix *matrix, GDIPCONST GpPen *pen)
        ; Description   Gets a bounding rectangle for this path.
        ;          
        ; Params        GpPath* path, GpRectF* bounds, GDIPCONST GpMatrix *matrix, GDIPCONST GpPen *pen
        ;          
        ; Return        Status
        ;______________________________________
        GetBounds(GpPath* path, GpRectF* bounds, GDIPCONST GpMatrix *matrix, GDIPCONST GpPen *pen)
        {
            status := GdipGetPathWorldBounds(GpPath* path, GpRectF* bounds, GDIPCONST GpMatrix *matrix, GDIPCONST GpPen *pen)
            Return status
        }
        
        ;####################################
        ; Call          GetBounds(GpPath* path, GpRect* bounds, GDIPCONST GpMatrix *matrix, GDIPCONST GpPen *pen)
        ; Description   Gets a bounding rectangle for this path.
        ;          
        ; Params        GpPath* path, GpRect* bounds, GDIPCONST GpMatrix *matrix, GDIPCONST GpPen *pen
        ;          
        ; Return        Status
        ;______________________________________
        GetBounds(GpPath* path, GpRect* bounds, GDIPCONST GpMatrix *matrix, GDIPCONST GpPen *pen)
        {
            status := GdipGetPathWorldBoundsI(GpPath* path, GpRect* bounds, GDIPCONST GpMatrix *matrix, GDIPCONST GpPen *pen)
            Return status
        }
        
        ;####################################
        ; Call          IsVisible(GpPath* path, REAL x, REAL y, GpGraphics *graphics, BOOL *result)
        ; Description   Determines whether a specified point lies in the area that is filled when this path is filled by a specified Graphics object.
        ;          
        ; Params        GpPath* path, REAL x, REAL y, GpGraphics *graphics, BOOL *result
        ;          
        ; Return        Status
        ;______________________________________
        IsVisible(GpPath* path, REAL x, REAL y, GpGraphics *graphics, BOOL *result)
        {
            status := GdipIsVisiblePathPoint(GpPath* path, REAL x, REAL y, GpGraphics *graphics, BOOL *result)
            Return status
        }
        
        ;####################################
        ; Call          IsVisible(GpPath* path, INT x, INT y, GpGraphics *graphics, BOOL *result)
        ; Description   Determines whether a specified point lies in the area that is filled when this path is filled by a specified Graphics object.
        ;          
        ; Params        GpPath* path, INT x, INT y, GpGraphics *graphics, BOOL *result
        ;          
        ; Return        Status
        ;______________________________________
        IsVisible(GpPath* path, INT x, INT y, GpGraphics *graphics, BOOL *result)
        {
            status := GdipIsVisiblePathPointI(GpPath* path, INT x, INT y, GpGraphics *graphics, BOOL *result)
            Return status
        }
        
        ;####################################
        ; Call          IsOutlineVisible(GpPath* path, REAL x, REAL y, GpPen *pen, GpGraphics *graphics, BOOL *result)
        ; Description   Determines whether a specified point touches the outline of this path when the path is drawn by a specified Graphics object and a specified pen.
        ;          
        ; Params        GpPath* path, REAL x, REAL y, GpPen *pen, GpGraphics *graphics, BOOL *result
        ;          
        ; Return        Status
        ;______________________________________
        IsOutlineVisible(GpPath* path, REAL x, REAL y, GpPen *pen, GpGraphics *graphics, BOOL *result)
        {
            status := GdipIsOutlineVisiblePathPoint(GpPath* path, REAL x, REAL y, GpPen *pen, GpGraphics *graphics, BOOL *result)
            Return status
        }
        
        ;####################################
        ; Call          IsOutlineVisible(GpPath* path, INT x, INT y, GpPen *pen, GpGraphics *graphics, BOOL *result)
        ; Description   Determines whether a specified point touches the outline of this path when the path is drawn by a specified Graphics object and a specified pen.
        ;          
        ; Params        GpPath* path, INT x, INT y, GpPen *pen, GpGraphics *graphics, BOOL *result
        ;          
        ; Return        Status
        ;______________________________________
        IsOutlineVisible(GpPath* path, INT x, INT y, GpPen *pen, GpGraphics *graphics, BOOL *result)
        {
            status := GdipIsOutlineVisiblePathPointI(GpPath* path, INT x, INT y, GpPen *pen, GpGraphics *graphics, BOOL *result)
            Return status
        }
    }
    
    Class HatchBrush
    {
        ;####################################
        ; Call          HatchBrush(GpHatchStyle hatchstyle, ARGB forecol, ARGB backcol, GpHatch **brush)
        ; Description   Creates a HatchBrush object based on a hatch style, a foreground color, and a background color.
        ;          
        ; Params        GpHatchStyle hatchstyle, ARGB forecol, ARGB backcol, GpHatch **brush
        ;          
        ; Return        Status
        ;______________________________________
        HatchBrush(GpHatchStyle hatchstyle, ARGB forecol, ARGB backcol, GpHatch **brush)
        {
            status := GdipCreateHatchBrush(GpHatchStyle hatchstyle, ARGB forecol, ARGB backcol, GpHatch **brush)
            Return status
        }
        
        ;####################################
        ; Call          GetHatchStyle(GpHatch *brush, GpHatchStyle *hatchstyle)
        ; Description   Gets the hatch style of this hatch brush.
        ;          
        ; Params        GpHatch *brush, GpHatchStyle *hatchstyle
        ;          
        ; Return        Status
        ;______________________________________
        GetHatchStyle(GpHatch *brush, GpHatchStyle *hatchstyle)
        {
            status := GdipGetHatchStyle(GpHatch *brush, GpHatchStyle *hatchstyle)
            Return status
        }
        
        ;####################################
        ; Call          GetForegroundColor(GpHatch *brush, ARGB* forecol)
        ; Description   Gets the foreground color of this hatch brush.
        ;          
        ; Params        GpHatch *brush, ARGB* forecol
        ;          
        ; Return        Status
        ;______________________________________
        GetForegroundColor(GpHatch *brush, ARGB* forecol)
        {
            status := GdipGetHatchForegroundColor(GpHatch *brush, ARGB* forecol)
            Return status
        }
        
        ;####################################
        ; Call          GetBackgroundColor(GpHatch *brush, ARGB* backcol)
        ; Description   Gets the background color of this hatch brush.
        ;          
        ; Params        GpHatch *brush, ARGB* backcol
        ;          
        ; Return        Status
        ;______________________________________
        GetBackgroundColor(GpHatch *brush, ARGB* backcol)
        {
            status := GdipGetHatchBackgroundColor(GpHatch *brush, ARGB* backcol)
            Return status
        }
        
    }
    
Class Image
    {
        ;####################################
        ; Call          Image(IStream* stream, GpImage **image)
        ; Description   Creates an Image object based on a stream.\nThis flat function does not use Image Color Management (ICM).
        ;          
        ; Params        IStream* stream, GpImage **image
        ;          
        ; Return        Status
        ;______________________________________
        Image(IStream* stream, GpImage **image)
        {
            status := GdipLoadImageFromStream(IStream* stream, GpImage **image)
            Return status
        }
        
        ;####################################
        ; Call          Image(GDIPCONST WCHAR* filename, GpImage **image)
        ; Description   Creates an Image object based on a file.\nThis flat function does not use ICM.
        ;          
        ; Params        GDIPCONST WCHAR* filename, GpImage **image
        ;          
        ; Return        Status
        ;______________________________________
        Image(GDIPCONST WCHAR* filename, GpImage **image)
        {
            status := GdipLoadImageFromFile(GDIPCONST WCHAR* filename, GpImage **image)
            Return status
        }
        
        ;####################################
        ; Call          Image(IStream* stream, GpImage **image)
        ; Description   Creates an Image object based on a stream.\nThis flat function does not use ICM.
        ;          
        ; Params        IStream* stream, GpImage **image
        ;          
        ; Return        Status
        ;______________________________________
        Image(IStream* stream, GpImage **image)
        {
            status := GdipLoadImageFromStreamICM(IStream* stream, GpImage **image)
            Return status
        }
        
        ;####################################
        ; Call          Image(GDIPCONST WCHAR* filename, GpImage **image)
        ; Description   Creates an Image object based on a file.\nThis flat function does not use ICM.
        ;          
        ; Params        GDIPCONST WCHAR* filename, GpImage **image
        ;          
        ; Return        Status
        ;______________________________________
        Image(GDIPCONST WCHAR* filename, GpImage **image)
        {
            status := GdipLoadImageFromFileICM(GDIPCONST WCHAR* filename, GpImage **image)
            Return status
        }
        
        ;####################################
        ; Call          Clone(GpImage *image, GpImage **cloneImage)
        ; Description   Creates a new Image object and initializes it with the contents of this Image object.
        ;          
        ; Params        GpImage *image, GpImage **cloneImage
        ;          
        ; Return        Status
        ;______________________________________
        Clone(GpImage *image, GpImage **cloneImage)
        {
            status := GdipCloneImage(GpImage *image, GpImage **cloneImage)
            Return status
        }
        
        ;####################################
        ; Call          ~Image(GpImage *image)
        ; Description   Releases resources used by the Image object.
        ;          
        ; Params        GpImage *image
        ;          
        ; Return        Status
        ;______________________________________
        ~Image(GpImage *image)
        {
            status := GdipDisposeImage(GpImage *image)
            Return status
        }
        
        ;####################################
        ; Call          Save(GpImage *image, GDIPCONST WCHAR* filename, GDIPCONST CLSID* clsidEncoder, GDIPCONST EncoderParameters* encoderParams)
        ; Description   Saves this image to a file.
        ;          
        ; Params        GpImage *image, GDIPCONST WCHAR* filename, GDIPCONST CLSID* clsidEncoder, GDIPCONST EncoderParameters* encoderParams
        ;          
        ; Return        Status
        ;______________________________________
        Save(GpImage *image, GDIPCONST WCHAR* filename, GDIPCONST CLSID* clsidEncoder, GDIPCONST EncoderParameters* encoderParams)
        {
            status := GdipSaveImageToFile(GpImage *image, GDIPCONST WCHAR* filename, GDIPCONST CLSID* clsidEncoder, GDIPCONST EncoderParameters* encoderParams)
            Return status
        }
        
        ;####################################
        ; Call          Save(GpImage *image, IStream* stream, GDIPCONST CLSID* clsidEncoder, GDIPCONST EncoderParameters* encoderParams)
        ; Description   Saves this image to a stream.
        ;          
        ; Params        GpImage *image, IStream* stream, GDIPCONST CLSID* clsidEncoder, GDIPCONST EncoderParameters* encoderParams
        ;          
        ; Return        Status
        ;______________________________________
        Save(GpImage *image, IStream* stream, GDIPCONST CLSID* clsidEncoder, GDIPCONST EncoderParameters* encoderParams)
        {
            status := GdipSaveImageToStream(GpImage *image, IStream* stream, GDIPCONST CLSID* clsidEncoder, GDIPCONST EncoderParameters* encoderParams)
            Return status
        }
        
        ;####################################
        ; Call          SaveAdd(GpImage *image, GDIPCONST EncoderParameters* encoderParams)
        ; Description   Adds a frame to a file or stream specified in a previous call to the Save method. Use this method to save selected frames from a multiple-frame image to another multiple-frame image.
        ;          
        ; Params        GpImage *image, GDIPCONST EncoderParameters* encoderParams
        ;          
        ; Return        Status
        ;______________________________________
        SaveAdd(GpImage *image, GDIPCONST EncoderParameters* encoderParams)
        {
            status := GdipSaveAdd(GpImage *image, GDIPCONST EncoderParameters* encoderParams)
            Return status
        }
        
        ;####################################
        ; Call          SaveAdd(GpImage *image, GpImage* newImage, GDIPCONST EncoderParameters* encoderParams)
        ; Description   Adds a frame to a file or stream specified in a previous call to the Save method.
        ;          
        ; Params        GpImage *image, GpImage* newImage, GDIPCONST EncoderParameters* encoderParams
        ;          
        ; Return        Status
        ;______________________________________
        SaveAdd(GpImage *image, GpImage* newImage, GDIPCONST EncoderParameters* encoderParams)
        {
            status := GdipSaveAddImage(GpImage *image, GpImage* newImage, GDIPCONST EncoderParameters* encoderParams)
            Return status
        }
        
        ;####################################
        ; Call          Graphics(GpImage *image, GpGraphics **graphics)
        ; Description   Creates a Graphics object that is associated with an Image object.
        ;          
        ; Params        GpImage *image, GpGraphics **graphics
        ;          
        ; Return        Status
        ;______________________________________
        Graphics(GpImage *image, GpGraphics **graphics)
        {
            status := GdipGetImageGraphicsContext(GpImage *image, GpGraphics **graphics)
            Return status
        }
        
        ;####################################
        ; Call          GetBounds(GpImage *image, GpRectF *srcRect, GpUnit *srcUnit)
        ; Description   Gets the bounding rectangle for this image.
        ;          
        ; Params        GpImage *image, GpRectF *srcRect, GpUnit *srcUnit
        ;          
        ; Return        Status
        ;______________________________________
        GetBounds(GpImage *image, GpRectF *srcRect, GpUnit *srcUnit)
        {
            status := GdipGetImageBounds(GpImage *image, GpRectF *srcRect, GpUnit *srcUnit)
            Return status
        }
        
        ;####################################
        ; Call          GetPhysicalDimension(GpImage *image, REAL *width, REAL *height)
        ; Description   Gets the width and height of this image.\nIn the flat function, the width and height parameters together correspond to the size parameter in the wrapper method.
        ;          
        ; Params        GpImage *image, REAL *width, REAL *height
        ;          
        ; Return        Status
        ;______________________________________
        GetPhysicalDimension(GpImage *image, REAL *width, REAL *height)
        {
            status := GdipGetImageDimension(GpImage *image, REAL *width, REAL *height)
            Return status
        }
        
        ;####################################
        ; Call          GetType(GpImage *image, ImageType *type)
        ; Description   Gets the type (bitmap or metafile) of this Image object.
        ;          
        ; Params        GpImage *image, ImageType *type
        ;          
        ; Return        Status
        ;______________________________________
        GetType(GpImage *image, ImageType *type)
        {
            status := GdipGetImageType(GpImage *image, ImageType *type)
            Return status
        }
        
        ;####################################
        ; Call          GetWidth(GpImage *image, UINT *width)
        ; Description   Gets the width, in pixels, of this image.
        ;          
        ; Params        GpImage *image, UINT *width
        ;          
        ; Return        Status
        ;______________________________________
        GetWidth(GpImage *image, UINT *width)
        {
            status := GdipGetImageWidth(GpImage *image, UINT *width)
            Return status
        }
        
        ;####################################
        ; Call          GetHeight(GpImage *image, UINT *height)
        ; Description   Gets the image height, in pixels, of this image.
        ;          
        ; Params        GpImage *image, UINT *height
        ;          
        ; Return        Status
        ;______________________________________
        GetHeight(GpImage *image, UINT *height)
        {
            status := GdipGetImageHeight(GpImage *image, UINT *height)
            Return status
        }
        
        ;####################################
        ; Call          GetHorizontalResolution(GpImage *image, REAL *resolution)
        ; Description   Gets the horizontal resolution, in dots per inch, of this image.
        ;          
        ; Params        GpImage *image, REAL *resolution
        ;          
        ; Return        Status
        ;______________________________________
        GetHorizontalResolution(GpImage *image, REAL *resolution)
        {
            status := GdipGetImageHorizontalResolution(GpImage *image, REAL *resolution)
            Return status
        }
        
        ;####################################
        ; Call          GetVerticalResolution(GpImage *image, REAL *resolution)
        ; Description   Gets the vertical resolution, in dots per inch, of this image.
        ;          
        ; Params        GpImage *image, REAL *resolution
        ;          
        ; Return        Status
        ;______________________________________
        GetVerticalResolution(GpImage *image, REAL *resolution)
        {
            status := GdipGetImageVerticalResolution(GpImage *image, REAL *resolution)
            Return status
        }
        
        ;####################################
        ; Call          GetFlags(GpImage *image, UINT *flags)
        ; Description   Gets a set of flags that indicate certain attributes of this Image object.
        ;          
        ; Params        GpImage *image, UINT *flags
        ;          
        ; Return        Status
        ;______________________________________
        GetFlags(GpImage *image, UINT *flags)
        {
            status := GdipGetImageFlags(GpImage *image, UINT *flags)
            Return status
        }
        
        ;####################################
        ; Call          GetRawFormat(GpImage *image, GUID *format)
        ; Description   Gets a globally unique identifier ( GUID) that identifies the format of this Image object. GUIDs that identify various file formats are defined in Gdiplusimaging.h.
        ;          
        ; Params        GpImage *image, GUID *format
        ;          
        ; Return        Status
        ;______________________________________
        GetRawFormat(GpImage *image, GUID *format)
        {
            status := GdipGetImageRawFormat(GpImage *image, GUID *format)
            Return status
        }
        
        ;####################################
        ; Call          GetPixelFormat(GpImage *image, PixelFormat *format)
        ; Description   Gets the pixel format of this Image object.
        ;          
        ; Params        GpImage *image, PixelFormat *format
        ;          
        ; Return        Status
        ;______________________________________
        GetPixelFormat(GpImage *image, PixelFormat *format)
        {
            status := GdipGetImagePixelFormat(GpImage *image, PixelFormat *format)
            Return status
        }
        
        ;####################################
        ; Call          GetThumbnailImage(GpImage *image, UINT thumbWidth, UINT thumbHeight, GpImage **thumbImage, GetThumbnailImageAbort callback, VOID * callbackData)
        ; Description   Gets a thumbnail image from this Image object.
        ;          
        ; Params        GpImage *image, UINT thumbWidth, UINT thumbHeight, GpImage **thumbImage, GetThumbnailImageAbort callback, VOID * callbackData
        ;          
        ; Return        Status
        ;______________________________________
        GetThumbnailImage(GpImage *image, UINT thumbWidth, UINT thumbHeight, GpImage **thumbImage, GetThumbnailImageAbort callback, VOID * callbackData)
        {
            status := GdipGetImageThumbnail(GpImage *image, UINT thumbWidth, UINT thumbHeight, GpImage **thumbImage, GetThumbnailImageAbort callback, VOID * callbackData)
            Return status
        }
        
        ;####################################
        ; Call          GetEncoderParameterListSize(GpImage *image, GDIPCONST CLSID* clsidEncoder, UINT* size)
        ; Description   Gets the size, in bytes, of the parameter list for a specified image encoder.
        ;          
        ; Params        GpImage *image, GDIPCONST CLSID* clsidEncoder, UINT* size
        ;          
        ; Return        Status
        ;______________________________________
        GetEncoderParameterListSize(GpImage *image, GDIPCONST CLSID* clsidEncoder, UINT* size)
        {
            status := GdipGetEncoderParameterListSize(GpImage *image, GDIPCONST CLSID* clsidEncoder, UINT* size)
            Return status
        }
        
        ;####################################
        ; Call          GetEncoderParameterList(GpImage *image, GDIPCONST CLSID* clsidEncoder, UINT size, EncoderParameters* buffer)
        ; Description   Gets a list of the parameters supported by a specified image encoder.
        ;          
        ; Params        GpImage *image, GDIPCONST CLSID* clsidEncoder, UINT size, EncoderParameters* buffer
        ;          
        ; Return        Status
        ;______________________________________
        GetEncoderParameterList(GpImage *image, GDIPCONST CLSID* clsidEncoder, UINT size, EncoderParameters* buffer)
        {
            status := GdipGetEncoderParameterList(GpImage *image, GDIPCONST CLSID* clsidEncoder, UINT size, EncoderParameters* buffer)
            Return status
        }
        
        ;####################################
        ; Call          GetFrameDimensionsCount(GpImage* image, UINT* count)
        ; Description   Gets the number of frame dimensions in this Image object.
        ;          
        ; Params        GpImage* image, UINT* count
        ;          
        ; Return        Status
        ;______________________________________
        GetFrameDimensionsCount(GpImage* image, UINT* count)
        {
            status := GdipImageGetFrameDimensionsCount(GpImage* image, UINT* count)
            Return status
        }
        
        ;####################################
        ; Call          GetFrameDimensionsList(GpImage* image, GUID* dimensionIDs, UINT count)
        ; Description   Gets the identifiers for the frame dimensions of this Image object.
        ;          
        ; Params        GpImage* image, GUID* dimensionIDs, UINT count
        ;          
        ; Return        Status
        ;______________________________________
        GetFrameDimensionsList(GpImage* image, GUID* dimensionIDs, UINT count)
        {
            status := GdipImageGetFrameDimensionsList(GpImage* image, GUID* dimensionIDs, UINT count)
            Return status
        }
        
        ;####################################
        ; Call          GetFrameCount(GpImage *image, GDIPCONST GUID* dimensionID, UINT* count)
        ; Description   Gets the number of frames in a specified dimension of this Image object.
        ;          
        ; Params        GpImage *image, GDIPCONST GUID* dimensionID, UINT* count
        ;          
        ; Return        Status
        ;______________________________________
        GetFrameCount(GpImage *image, GDIPCONST GUID* dimensionID, UINT* count)
        {
            status := GdipImageGetFrameCount(GpImage *image, GDIPCONST GUID* dimensionID, UINT* count)
            Return status
        }
        
        ;####################################
        ; Call          SelectActiveFrame(GpImage *image, GDIPCONST GUID* dimensionID, UINT frameIndex)
        ; Description   Selects the frame in this Image object specified by a dimension and an index.
        ;          
        ; Params        GpImage *image, GDIPCONST GUID* dimensionID, UINT frameIndex
        ;          
        ; Return        Status
        ;______________________________________
        SelectActiveFrame(GpImage *image, GDIPCONST GUID* dimensionID, UINT frameIndex)
        {
            status := GdipImageSelectActiveFrame(GpImage *image, GDIPCONST GUID* dimensionID, UINT frameIndex)
            Return status
        }
        
        ;####################################
        ; Call          RotateFlip(GpImage *image, RotateFlipType rfType)
        ; Description   Rotates and flips this image.
        ;          
        ; Params        GpImage *image, RotateFlipType rfType
        ;          
        ; Return        Status
        ;______________________________________
        RotateFlip(GpImage *image, RotateFlipType rfType)
        {
            status := GdipImageRotateFlip(GpImage *image, RotateFlipType rfType)
            Return status
        }
        
        ;####################################
        ; Call          GetPalette(GpImage *image, ColorPalette *palette, INT size)
        ; Description   Gets the ColorPalette of this Image object.
        ;          
        ; Params        GpImage *image, ColorPalette *palette, INT size
        ;          
        ; Return        Status
        ;______________________________________
        GetPalette(GpImage *image, ColorPalette *palette, INT size)
        {
            status := GdipGetImagePalette(GpImage *image, ColorPalette *palette, INT size)
            Return status
        }
        
        ;####################################
        ; Call          SetPalette(GpImage *image, GDIPCONST ColorPalette *palette)
        ; Description   Sets the color palette of this Image object.
        ;          
        ; Params        GpImage *image, GDIPCONST ColorPalette *palette
        ;          
        ; Return        Status
        ;______________________________________
        SetPalette(GpImage *image, GDIPCONST ColorPalette *palette)
        {
            status := GdipSetImagePalette(GpImage *image, GDIPCONST ColorPalette *palette)
            Return status
        }
        
        ;####################################
        ; Call          GetPaletteSize(GpImage *image, INT *size)
        ; Description   Gets the size, in bytes, of the color palette of this Image object.
        ;          
        ; Params        GpImage *image, INT *size
        ;          
        ; Return        Status
        ;______________________________________
        GetPaletteSize(GpImage *image, INT *size)
        {
            status := GdipGetImagePaletteSize(GpImage *image, INT *size)
            Return status
        }
        
        ;####################################
        ; Call          GetPropertyCount(GpImage *image, UINT* numOfProperty)
        ; Description   Gets the pixel format of this Image object.
        ;          
        ; Params        GpImage *image, UINT* numOfProperty
        ;          
        ; Return        Status
        ;______________________________________
        GetPropertyCount(GpImage *image, UINT* numOfProperty)
        {
            status := GdipGetPropertyCount(GpImage *image, UINT* numOfProperty)
            Return status
        }
        
        ;####################################
        ; Call          GetPropertyIdList(GpImage *image, UINT numOfProperty, PROPID* list)
        ; Description   Gets a list of the property identifiers used in the metadata of this Image object.
        ;          
        ; Params        GpImage *image, UINT numOfProperty, PROPID* list
        ;          
        ; Return        Status
        ;______________________________________
        GetPropertyIdList(GpImage *image, UINT numOfProperty, PROPID* list)
        {
            status := GdipGetPropertyIdList(GpImage *image, UINT numOfProperty, PROPID* list)
            Return status
        }
        
        ;####################################
        ; Call          GetPropertyItemSize(GpImage *image, PROPID propId, UINT* size)
        ; Description   Gets the size, in bytes, of a specified property item of this Image object.
        ;          
        ; Params        GpImage *image, PROPID propId, UINT* size
        ;          
        ; Return        Status
        ;______________________________________
        GetPropertyItemSize(GpImage *image, PROPID propId, UINT* size)
        {
            status := GdipGetPropertyItemSize(GpImage *image, PROPID propId, UINT* size)
            Return status
        }
        
        ;####################################
        ; Call          GetPropertyItem(GpImage *image, PROPID propId,UINT propSize, PropertyItem* buffer)
        ; Description   Gets a specified property item (piece of metadata) from this Image object.
        ;          
        ; Params        GpImage *image, PROPID propId,UINT propSize, PropertyItem* buffer
        ;          
        ; Return        Status
        ;______________________________________
        GetPropertyItem(GpImage *image, PROPID propId,UINT propSize, PropertyItem* buffer)
        {
            status := GdipGetPropertyItem(GpImage *image, PROPID propId,UINT propSize, PropertyItem* buffer)
            Return status
        }
        
        ;####################################
        ; Call          GetPropertySize(GpImage *image, UINT* totalBufferSize, UINT* numProperties)
        ; Description   Gets the total size, in bytes, of all the property items stored in this Image object. This method also gets the number of property items stored in this Image object.
        ;          
        ; Params        GpImage *image, UINT* totalBufferSize, UINT* numProperties
        ;          
        ; Return        Status
        ;______________________________________
        GetPropertySize(GpImage *image, UINT* totalBufferSize, UINT* numProperties)
        {
            status := GdipGetPropertySize(GpImage *image, UINT* totalBufferSize, UINT* numProperties)
            Return status
        }
        
        ;####################################
        ; Call          GetAllPropertyItems(GpImage *image, UINT totalBufferSize, UINT numProperties, PropertyItem* allItems)
        ; Description   Gets all the property items (metadata) stored in this Image object.
        ;          
        ; Params        GpImage *image, UINT totalBufferSize, UINT numProperties, PropertyItem* allItems
        ;          
        ; Return        Status
        ;______________________________________
        GetAllPropertyItems(GpImage *image, UINT totalBufferSize, UINT numProperties, PropertyItem* allItems)
        {
            status := GdipGetAllPropertyItems(GpImage *image, UINT totalBufferSize, UINT numProperties, PropertyItem* allItems)
            Return status
        }
        
        ;####################################
        ; Call          RemovePropertyItem(GpImage *image, PROPID propId)
        ; Description   Removes a property item (piece of metadata) from this Image object.
        ;          
        ; Params        GpImage *image, PROPID propId
        ;          
        ; Return        Status
        ;______________________________________
        RemovePropertyItem(GpImage *image, PROPID propId)
        {
            status := GdipRemovePropertyItem(GpImage *image, PROPID propId)
            Return status
        }
        
        ;####################################
        ; Call          SetPropertyItem(GpImage *image, GDIPCONST PropertyItem* item)
        ; Description   Sets a property item (piece of metadata) for this Image object. If the item already exists, then its contents are updated; otherwise, a new item is added.
        ;          
        ; Params        GpImage *image, GDIPCONST PropertyItem* item
        ;          
        ; Return        Status
        ;______________________________________
        SetPropertyItem(GpImage *image, GDIPCONST PropertyItem* item)
        {
            status := GdipSetPropertyItem(GpImage *image, GDIPCONST PropertyItem* item)
            Return status
        }
        
        ;####################################
        ; Call          FindFirstItem(GpImage *image, ImageItemData* item)
        ; Description   Retrieves the description and the data size of the first metadata item in this Image object.
        ;          
        ; Params        GpImage *image, ImageItemData* item
        ;          
        ; Return        Status
        ;______________________________________
        FindFirstItem(GpImage *image, ImageItemData* item)
        {
            status := GdipFindFirstImageItem(GpImage *image, ImageItemData* item)
            Return status
        }
        
        ;####################################
        ; Call          FindNextItem(GpImage *image, ImageItemData* item)
        ; Description   Retrieves the description and the data size of the next metadata item in this Image object. This method is used along with the Image::FindFirstItem method to enumerate the metadata items stored in this ImImageage object.
        ;          
        ; Params        GpImage *image, ImageItemData* item
        ;          
        ; Return        Status
        ;______________________________________
        FindNextItem(GpImage *image, ImageItemData* item)
        {
            status := GdipFindNextImageItem(GpImage *image, ImageItemData* item)
            Return status
        }
        
        ;####################################
        ; Call          GetItemData(GpImage *image, ImageItemData* item)
        ; Description   Gets one piece of metadata from this Image object.
        ;          
        ; Params        GpImage *image, ImageItemData* item
        ;          
        ; Return        Status
        ;______________________________________
        GetItemData(GpImage *image, ImageItemData* item)
        {
            status := GdipGetImageItemData(GpImage *image, ImageItemData* item)
            Return status
        }
        
        ;####################################
        ; Call          SetAbort(GpImage *pImage, GdiplusAbort *pIAbort)
        ; Description   Sets the object whose Abort method is called periodically during time-consuming rendering operation.
        ;          
        ; Params        GpImage *pImage, GdiplusAbort *pIAbort
        ;          
        ; Return        Status
        ;______________________________________
        SetAbort(GpImage *pImage, GdiplusAbort *pIAbort)
        {
            status := GdipImageSetAbort(GpImage *pImage, GdiplusAbort *pIAbort)
            Return status
        }
        
        ;####################################
        ; Call          ConvertToEmfPlus(const GpGraphics* refGraphics, GpMetafile* metafile, BOOL* conversionSuccess, EmfType emfType, const WCHAR* description, GpMetafile** out_metafile)
        ; Description   Converts this Metafile object to the EMF+ format.
        ;          
        ; Params        const GpGraphics* refGraphics, GpMetafile* metafile, BOOL* conversionSuccess, EmfType emfType, const WCHAR* description, GpMetafile** out_metafile
        ;          
        ; Return        Status
        ;______________________________________
        ConvertToEmfPlus(const GpGraphics* refGraphics, GpMetafile* metafile, BOOL* conversionSuccess, EmfType emfType, const WCHAR* description, GpMetafile** out_metafile)
        {
            status := GdipConvertToEmfPlus(const GpGraphics* refGraphics, GpMetafile* metafile, BOOL* conversionSuccess, EmfType emfType, const WCHAR* description, GpMetafile** out_metafile)
            Return status
        }
        
        ;####################################
        ; Call          ConvertToEmfPlus(const GpGraphics* refGraphics, GpMetafile* metafile, BOOL* conversionSuccess, const WCHAR* filename, EmfType emfType, const WCHAR* description, GpMetafile** out_metafile)
        ; Description   Converts this Metafile object to the EMF+ format.
        ;          
        ; Params        const GpGraphics* refGraphics, GpMetafile* metafile, BOOL* conversionSuccess, const WCHAR* filename, EmfType emfType, const WCHAR* description, GpMetafile** out_metafile
        ;          
        ; Return        Status
        ;______________________________________
        ConvertToEmfPlus(const GpGraphics* refGraphics, GpMetafile* metafile, BOOL* conversionSuccess, const WCHAR* filename, EmfType emfType, const WCHAR* description, GpMetafile** out_metafile)
        {
            status := GdipConvertToEmfPlusToFile(const GpGraphics* refGraphics, GpMetafile* metafile, BOOL* conversionSuccess, const WCHAR* filename, EmfType emfType, const WCHAR* description, GpMetafile** out_metafile)
            Return status
        }
        
        ;####################################
        ; Call          ConvertToEmfPlus(const GpGraphics* refGraphics, GpMetafile* metafile, BOOL* conversionSuccess, IStream* stream, EmfType emfType, const WCHAR* description, GpMetafile** out_metafile)
        ; Description   Converts this Metafile object to the EMF+ format.
        ;          
        ; Params        const GpGraphics* refGraphics, GpMetafile* metafile, BOOL* conversionSuccess, IStream* stream, EmfType emfType, const WCHAR* description, GpMetafile** out_metafile
        ;          
        ; Return        Status
        ;______________________________________
        ConvertToEmfPlus(const GpGraphics* refGraphics, GpMetafile* metafile, BOOL* conversionSuccess, IStream* stream, EmfType emfType, const WCHAR* description, GpMetafile** out_metafile)
        {
            status := GdipConvertToEmfPlusToStream(const GpGraphics* refGraphics, GpMetafile* metafile, BOOL* conversionSuccess, IStream* stream, EmfType emfType, const WCHAR* description, GpMetafile** out_metafile)
            Return status
        }
        
        ;####################################
        ; Call          GdipImageForceValidation(GpImage *image)
        ; Description   This function forces validation of the image.
        ;          
        ; Params        const GpGraphics* refGraphics, GpMetafile* metafile, BOOL* conversionSuccess, IStream* stream, EmfType emfType, const WCHAR* description, GpMetafile** out_metafile
        ;          
        ; Return        Status
        ;______________________________________
        GdipImageForceValidation(GpImage *image)
        {
            status := GdipImageForceValidation(GpImage *image)
            Return status
        }
    }
    
    Class ImageAttributes
    {
        ;####################################
        ; Call          ImageAttributes(GpImageAttributes **imageattr)
        ; Description   Creates an ImageAttributes object.
        ;          
        ; Params        GpImageAttributes **imageattr
        ;          
        ; Return        Status
        ;______________________________________
        ImageAttributes(GpImageAttributes **imageattr)
        {
            status := GdipCreateImageAttributes(GpImageAttributes **imageattr)
            Return status
        }
        
        ;####################################
        ; Call          Clone(GDIPCONST GpImageAttributes *imageattr, GpImageAttributes **cloneImageattr)
        ; Description   Makes a copy of this ImageAttributes object.
        ;          
        ; Params        GDIPCONST GpImageAttributes *imageattr, GpImageAttributes **cloneImageattr
        ;          
        ; Return        Status
        ;______________________________________
        Clone(GDIPCONST GpImageAttributes *imageattr, GpImageAttributes **cloneImageattr)
        {
            status := GdipCloneImageAttributes(GDIPCONST GpImageAttributes *imageattr, GpImageAttributes **cloneImageattr)
            Return status
        }
        
        ;####################################
        ; Call          ~ImageAttributes(GpImageAttributes *imageattr)
        ; Description   Releases resources used by the ImageAttributes object.
        ;          
        ; Params        GpImageAttributes *imageattr
        ;          
        ; Return        Status
        ;______________________________________
        ~ImageAttributes(GpImageAttributes *imageattr)
        {
            status := GdipDisposeImageAttributes(GpImageAttributes *imageattr)
            Return status
        }
        
        ;####################################
        ; Call          SetToIdentity(GpImageAttributes *imageattr, ColorAdjustType type)
        ; Description   Sets the color-adjustment matrix of a specified category to identity matrix.
        ;          
        ; Params        GpImageAttributes *imageattr, ColorAdjustType type
        ;          
        ; Return        Status
        ;______________________________________
        SetToIdentity(GpImageAttributes *imageattr, ColorAdjustType type)
        {
            status := GdipSetImageAttributesToIdentity(GpImageAttributes *imageattr, ColorAdjustType type)
            Return status
        }
        
        ;####################################
        ; Call          Reset(GpImageAttributes *imageattr, ColorAdjustType type)
        ; Description   Sets the color-adjustment matrix of a specified category to identity matrix.
        ;          
        ; Params        GpImageAttributes *imageattr, ColorAdjustType type
        ;          
        ; Return        Status
        ;______________________________________
        Reset(GpImageAttributes *imageattr, ColorAdjustType type)
        {
            status := GdipResetImageAttributes(GpImageAttributes *imageattr, ColorAdjustType type)
            Return status
        }
        
        ;####################################
        ; Call          SetColorMatrix(IN ColorAdjustType type = ColorAdjustTypeDefault)(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, GDIPCONST ColorMatrix* colorMatrix, GDIPCONST ColorMatrix* grayMatrix, ColorMatrixFlags flags)
        ; Description   Sets the color-adjustment matrix for a specified category. The enableFlag parameter in the flat function is a Boolean value that specifies whether a separate color adjustment is enabled for the category specified by the type parameter. ImageAttributes::SetColorMatrix sets enableFlag to TRUE, and ImageAttributes::ClearColorMatrix sets enableFlag to FALSE.\nClears the color-adjustment matrix for a specified category. The grayMatrix parameter specifies a matrix to be used for adjusting gray shades when the value of the flags parameter is ColorMatrixFlagsAltGray.
        ;          
        ; Params        GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, GDIPCONST ColorMatrix* colorMatrix, GDIPCONST ColorMatrix* grayMatrix, ColorMatrixFlags flags
        ;          
        ; Return        Status
        ;______________________________________
        SetColorMatrix(IN ColorAdjustType type = ColorAdjustTypeDefault)(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, GDIPCONST ColorMatrix* colorMatrix, GDIPCONST ColorMatrix* grayMatrix, ColorMatrixFlags flags)
        {
            status := GdipSetImageAttributesColorMatrix(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, GDIPCONST ColorMatrix* colorMatrix, GDIPCONST ColorMatrix* grayMatrix, ColorMatrixFlags flags)
            Return status
        }
        
        ;####################################
        ; Call          SetThreshold(IN ColorAdjustType type = ColorAdjustTypeDefault)(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, REAL threshold)
        ; Description   Sets the threshold (transparency range) for a specified category.\nThe enableFlag parameter in the flat function is a Boolean value that specifies whether a separate threshold is enabled for the category specified by the type parameter. ImageAttributes::SetThreshold sets enableFlag to TRUE, and ImageAttributes::ClearThreshold sets enableFlag to FALSE.Clears the threshold value for a specified category.
        ;          
        ; Params        GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, REAL threshold
        ;          
        ; Return        Status
        ;______________________________________
        SetThreshold(IN ColorAdjustType type = ColorAdjustTypeDefault)(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, REAL threshold)
        {
            status := GdipSetImageAttributesThreshold(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, REAL threshold)
            Return status
        }
        
        ;####################################
        ; Call          SetGamma(IN ColorAdjustType type = ColorAdjustTypeDefault)(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, REAL gamma)
        ; Description   Sets the gamma value for a specified category. The enableFlag parameter in the flat function is a Boolean value that specifies whether a separate gamma is enabled for the category specified by the type parameter. ImageAttributes::SetGamma sets enableFlag to TRUE, and ImageAttributes::ClearGamma sets enableFlag to FALSE.\nDisables gamma correction for a specified category.
        ;          
        ; Params        GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, REAL gamma
        ;          
        ; Return        Status
        ;______________________________________
        SetGamma(IN ColorAdjustType type = ColorAdjustTypeDefault)(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, REAL gamma)
        {
            status := GdipSetImageAttributesGamma(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, REAL gamma)
            Return status
        }
        
        ;####################################
        ; Call          SetNoOp(IN ColorAdjustType type = ColorAdjustTypeDefault)(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag)
        ; Description   Turns off color adjustment for a specified category. You can call the ImageAttributes::ClearNoOp method to reinstate the color-adjustment settings that were in place before the call to ImageAttributes::SetNoOp method . The enableFlag parameter in the flat function is a Boolean value that specifies whether a color adjustment is enabled for the category specified by the type parameter. ImageAttributes::SetNoOp sets enableFlag to TRUE, and ImageAttributes::ClearNoOp sets enableFlag to FALSE.\nClears the NoOp setting for a specified category.
        ;          
        ; Params        GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag
        ;          
        ; Return        Status
        ;______________________________________
        SetNoOp(IN ColorAdjustType type = ColorAdjustTypeDefault)(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag)
        {
            status := GdipSetImageAttributesNoOp(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag)
            Return status
        }
        
        ;####################################
        ; Call          SetColorKey(IN ColorAdjustType type = ColorAdjustTypeDefault)(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, ARGB colorLow, ARGB colorHigh)
        ; Description   Sets the color key (transparency range) for a specified category.
        ;          
        ; Params        GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, ARGB colorLow, ARGB colorHigh
        ;          
        ; Return        Status
        ;______________________________________
        SetColorKey(IN ColorAdjustType type = ColorAdjustTypeDefault)(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, ARGB colorLow, ARGB colorHigh)
        {
            status := GdipSetImageAttributesColorKeys(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, ARGB colorLow, ARGB colorHigh)
            Return status
        }
        
        ;####################################
        ; Call          SetOutputChannel(IN ColorAdjustType type = ColorAdjustTypeDefault)(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, ColorChannelFlags channelFlags)
        ; Description   Sets the cyan-magenta-yellow-black (CMYK) output channel setting for a specified category.
        ;          
        ; Params        GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, ColorChannelFlags channelFlags
        ;          
        ; Return        Status
        ;______________________________________
        SetOutputChannel(IN ColorAdjustType type = ColorAdjustTypeDefault)(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, ColorChannelFlags channelFlags)
        {
            status := GdipSetImageAttributesOutputChannel(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, ColorChannelFlags channelFlags)
            Return status
        }
        
        ;####################################
        ; Call          SetOutputChannelColorProfile(IN ColorAdjustType type = ColorAdjustTypeDefault)(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, GDIPCONST WCHAR *colorProfileFilename)
        ; Description   Sets the output channel color-profile file for a specified category. The enableFlag parameter in the flat function is a Boolean value that specifies whether a separate output channel color profile is enabled for the category specified by the type parameter. ImageAttributes::SetOutputChannelColorProfile sets enableFlag to TRUE, and ImageAttributes::ClearOutputChannelColorProfile sets enableFlag to FALSE.\nClears the output channel color profile setting for a specified category.
        ;          
        ; Params        GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, GDIPCONST WCHAR *colorProfileFilename
        ;          
        ; Return        Status
        ;______________________________________
        SetOutputChannelColorProfile(IN ColorAdjustType type = ColorAdjustTypeDefault)(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, GDIPCONST WCHAR *colorProfileFilename)
        {
            status := GdipSetImageAttributesOutputChannelColorProfile(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, GDIPCONST WCHAR *colorProfileFilename)
            Return status
        }
        
        ;####################################
        ; Call          SetRemapTable(IN ColorAdjustType type = ColorAdjustTypeDefault)(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, UINT mapSize, GDIPCONST ColorMap *map)
        ; Description   Sets the color-remap table for a specified category. The enableFlag parameter in the flat function is a Boolean value that specifies whether a separate color remap table is enabled for the category specified by the type parameter. ImageAttributes::SetRemapTable sets enableFlag to TRUE, and ImageAttributes::ClearRemapTable sets enableFlag to FALSE.\nClears the color-remap table for a specified category.
        ;          
        ; Params        GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, UINT mapSize, GDIPCONST ColorMap *map
        ;          
        ; Return        Status
        ;______________________________________
        SetRemapTable(IN ColorAdjustType type = ColorAdjustTypeDefault)(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, UINT mapSize, GDIPCONST ColorMap *map)
        {
            status := GdipSetImageAttributesRemapTable(GpImageAttributes *imageattr, ColorAdjustType type, BOOL enableFlag, UINT mapSize, GDIPCONST ColorMap *map)
            Return status
        }
        
        ;####################################
        ; Call          SetWrapMode(GpImageAttributes *imageAttr, WrapMode wrap, ARGB argb, BOOL clamp )
        ; Description   Sets the wrap mode of this ImageAttributes object
        ;          
        ; Params        GpImageAttributes *imageAttr, WrapMode wrap, ARGB argb, BOOL clamp 
        ;          
        ; Return        Status
        ;______________________________________
        SetWrapMode(GpImageAttributes *imageAttr, WrapMode wrap, ARGB argb, BOOL clamp )
        {
            status := GdipSetImageAttributesWrapMode(GpImageAttributes *imageAttr, WrapMode wrap, ARGB argb, BOOL clamp )
            Return status
        }
        
        ;####################################
        ; Call          GdipSetImageAttributesICMMode(GpImageAttributes *imageAttr, BOOL on)
        ; Description   This function sets an internal state variable to the value specified by the on parameter. If this value is TRUE, Image Color Management (ICM) is used for all color adjustment. If the value is FALSE, ICM is not used.
        ;          
        ; Params        GpImageAttributes *imageAttr, BOOL on
        ;          
        ; Return        Status
        ;______________________________________
        GdipSetImageAttributesICMMode(GpImageAttributes *imageAttr, BOOL on)
        {
            status := GdipSetImageAttributesICMMode(GpImageAttributes *imageAttr, BOOL on)
            Return status
        }
        
        ;####################################
        ; Call          GetAdjustedPalette(GpImageAttributes *imageAttr, ColorPalette * colorPalette, ColorAdjustType colorAdjustType )
        ; Description   Adjusts the colors in a palette according to the adjustment settings of a specified category.
        ;          
        ; Params        GpImageAttributes *imageAttr, ColorPalette * colorPalette, ColorAdjustType colorAdjustType 
        ;          
        ; Return        Status
        ;______________________________________
        GetAdjustedPalette(GpImageAttributes *imageAttr, ColorPalette * colorPalette, ColorAdjustType colorAdjustType )
        {
            status := GdipGetImageAttributesAdjustedPalette(GpImageAttributes *imageAttr, ColorPalette * colorPalette, ColorAdjustType colorAdjustType )
            Return status
        }
        
        ;####################################
        ; Call          GdipSetImageAttributesCachedBackground(GpImageAttributes *imageattr, BOOL enableFlag)
        ; Description   Sets or clears the CachedBackground member of a specified GpImageAttributes object. GDI+ does not use the CachedBackground member, so calling this function has no effect. The imageattr parameter specifies the GpImageAttributes object. The enableFlag parameter specifies whether the CachedBackground member is set (TRUE) or cleared (FALSE).
        ;          
        ; Params        GpImageAttributes *imageattr, BOOL enableFlag 
        ;          
        ; Return        Status
        ;______________________________________
        GdipSetImageAttributesCachedBackground(GpImageAttributes *imageattr, BOOL enableFlag)
        {
            status := GdipSetImageAttributesCachedBackground(GpImageAttributes *imageattr, BOOL enableFlag)
            Return status
        }
    }
    
    Class LinearGradientBrush
    {
        ;####################################
        ; Call          LinearGradientBrush(GDIPCONST GpPointF* point1, GDIPCONST GpPointF* point2, ARGB color1, ARGB color2, GpWrapMode wrapMode, GpLineGradient **lineGradient)
        ; Description   Creates a LinearGradientBrush object from a set of boundary points and boundary colors.\nLinearGradientBrush(IN const PointF& point1, IN const PointF& point2, IN const Color& color1, IN const Color& color2) The wrapMode parameter in the flat function is a member of the WrapMode enumeration that specifies how areas filled with the brush are tiled.
        ;          
        ; Params        GDIPCONST GpPointF* point1, GDIPCONST GpPointF* point2, ARGB color1, ARGB color2, GpWrapMode wrapMode, GpLineGradient **lineGradient
        ;          
        ; Return        Status
        ;______________________________________
        LinearGradientBrush(GDIPCONST GpPointF* point1, GDIPCONST GpPointF* point2, ARGB color1, ARGB color2, GpWrapMode wrapMode, GpLineGradient **lineGradient)
        {
            status := GdipCreateLineBrush(GDIPCONST GpPointF* point1, GDIPCONST GpPointF* point2, ARGB color1, ARGB color2, GpWrapMode wrapMode, GpLineGradient **lineGradient)
            Return status
        }
        
        ;####################################
        ; Call          LinearGradientBrush(GDIPCONST GpPoint* point1, GDIPCONST GpPoint* point2, ARGB color1, ARGB color2, GpWrapMode wrapMode, GpLineGradient **lineGradient)
        ; Description   Creates a LinearGradientBrush object from a set of boundary points and boundary colors.\nThe wrapMode parameter in the flat function is a member of the WrapMode enumeration that specifies how areas filled with the brush are tiled.
        ;          
        ; Params        GDIPCONST GpPoint* point1, GDIPCONST GpPoint* point2, ARGB color1, ARGB color2, GpWrapMode wrapMode, GpLineGradient **lineGradient
        ;          
        ; Return        Status
        ;______________________________________
        LinearGradientBrush(GDIPCONST GpPoint* point1, GDIPCONST GpPoint* point2, ARGB color1, ARGB color2, GpWrapMode wrapMode, GpLineGradient **lineGradient)
        {
            status := GdipCreateLineBrushI(GDIPCONST GpPoint* point1, GDIPCONST GpPoint* point2, ARGB color1, ARGB color2, GpWrapMode wrapMode, GpLineGradient **lineGradient)
            Return status
        }
        
        ;####################################
        ; Call          LinearGradientBrush(GDIPCONST GpRectF* rect, ARGB color1, ARGB color2, LinearGradientMode mode, GpWrapMode wrapMode, GpLineGradient **lineGradient)
        ; Description   Creates a LinearGradientBrush object based on a rectangle and mode of direction.\nThe wrapMode parameter in the flat function is a member of the WrapMode enumeration that specifies how areas filled with the brush are tiled.
        ;          
        ; Params        GDIPCONST GpRectF* rect, ARGB color1, ARGB color2, LinearGradientMode mode, GpWrapMode wrapMode, GpLineGradient **lineGradient
        ;          
        ; Return        Status
        ;______________________________________
        LinearGradientBrush(GDIPCONST GpRectF* rect, ARGB color1, ARGB color2, LinearGradientMode mode, GpWrapMode wrapMode, GpLineGradient **lineGradient)
        {
            status := GdipCreateLineBrushFromRect(GDIPCONST GpRectF* rect, ARGB color1, ARGB color2, LinearGradientMode mode, GpWrapMode wrapMode, GpLineGradient **lineGradient)
            Return status
        }
        
        ;####################################
        ; Call          LinearGradientBrush(GDIPCONST GpRect* rect, ARGB color1, ARGB color2, LinearGradientMode mode, GpWrapMode wrapMode, GpLineGradient **lineGradient)
        ; Description   Creates a LinearGradientBrush object based on a rectangle and mode of direction.\nThe wrapMode parameter in the flat function is a member of the WrapMode enumeration that specifies how areas filled with the brush are tiled.
        ;          
        ; Params        GDIPCONST GpRect* rect, ARGB color1, ARGB color2, LinearGradientMode mode, GpWrapMode wrapMode, GpLineGradient **lineGradient
        ;          
        ; Return        Status
        ;______________________________________
        LinearGradientBrush(GDIPCONST GpRect* rect, ARGB color1, ARGB color2, LinearGradientMode mode, GpWrapMode wrapMode, GpLineGradient **lineGradient)
        {
            status := GdipCreateLineBrushFromRectI(GDIPCONST GpRect* rect, ARGB color1, ARGB color2, LinearGradientMode mode, GpWrapMode wrapMode, GpLineGradient **lineGradient)
            Return status
        }
        
        ;####################################
        ; Call          LinearGradientBrush(GDIPCONST GpRectF* rect, ARGB color1, ARGB color2, REAL angle, BOOL isAngleScalable, GpWrapMode wrapMode, GpLineGradient **lineGradient)
        ; Description   Creates a LinearGradientBrush object from a rectangle and angle of direction.\nThe wrapMode parameter in the flat function is a member of the WrapMode enumeration that specifies how areas filled with the brush are tiled.
        ;          
        ; Params        GDIPCONST GpRectF* rect, ARGB color1, ARGB color2, REAL angle, BOOL isAngleScalable, GpWrapMode wrapMode, GpLineGradient **lineGradient
        ;          
        ; Return        Status
        ;______________________________________
        LinearGradientBrush(GDIPCONST GpRectF* rect, ARGB color1, ARGB color2, REAL angle, BOOL isAngleScalable, GpWrapMode wrapMode, GpLineGradient **lineGradient)
        {
            status := GdipCreateLineBrushFromRectWithAngle(GDIPCONST GpRectF* rect, ARGB color1, ARGB color2, REAL angle, BOOL isAngleScalable, GpWrapMode wrapMode, GpLineGradient **lineGradient)
            Return status
        }
        
        ;####################################
        ; Call          LinearGradientBrush(GDIPCONST GpRect* rect, ARGB color1, ARGB color2, REAL angle, BOOL isAngleScalable, GpWrapMode wrapMode, GpLineGradient **lineGradient)
        ; Description   Creates a LinearGradientBrush object from a rectangle and angle of direction.\nThe wrapMode parameter in the flat function is a member of the WrapMode enumeration that specifies how areas filled with the brush are tiled.
        ;          
        ; Params        GDIPCONST GpRect* rect, ARGB color1, ARGB color2, REAL angle, BOOL isAngleScalable, GpWrapMode wrapMode, GpLineGradient **lineGradient
        ;          
        ; Return        Status
        ;______________________________________
        LinearGradientBrush(GDIPCONST GpRect* rect, ARGB color1, ARGB color2, REAL angle, BOOL isAngleScalable, GpWrapMode wrapMode, GpLineGradient **lineGradient)
        {
            status := GdipCreateLineBrushFromRectWithAngleI(GDIPCONST GpRect* rect, ARGB color1, ARGB color2, REAL angle, BOOL isAngleScalable, GpWrapMode wrapMode, GpLineGradient **lineGradient)
            Return status
        }
        
        ;####################################
        ; Call          SetLinearColors(GpLineGradient *brush, ARGB color1, ARGB color2)
        ; Description   Sets the starting color and ending color of this linear gradient brush.
        ;          
        ; Params        GpLineGradient *brush, ARGB color1, ARGB color2
        ;          
        ; Return        Status
        ;______________________________________
        SetLinearColors(GpLineGradient *brush, ARGB color1, ARGB color2)
        {
            status := GdipSetLineColors(GpLineGradient *brush, ARGB color1, ARGB color2)
            Return status
        }
        
        ;####################################
        ; Call          GetLinearColors(GpLineGradient *brush, ARGB* colors)
        ; Description   Gets the starting color and ending color of this linear gradient brush.
        ;          
        ; Params        GpLineGradient *brush, ARGB* colors
        ;          
        ; Return        Status
        ;______________________________________
        GetLinearColors(GpLineGradient *brush, ARGB* colors)
        {
            status := GdipGetLineColors(GpLineGradient *brush, ARGB* colors)
            Return status
        }
        
        ;####################################
        ; Call          GetRectangle(GpLineGradient *brush, GpRectF *rect)
        ; Description   Gets the rectangle that defines the boundaries of the gradient.
        ;          
        ; Params        GpLineGradient *brush, GpRectF *rect
        ;          
        ; Return        Status
        ;______________________________________
        GetRectangle(GpLineGradient *brush, GpRectF *rect)
        {
            status := GdipGetLineRect(GpLineGradient *brush, GpRectF *rect)
            Return status
        }
        
        ;####################################
        ; Call          GetRectangle(GpLineGradient *brush, GpRect *rect)
        ; Description   Gets the rectangle that defines the boundaries of the gradient.
        ;          
        ; Params        GpLineGradient *brush, GpRect *rect
        ;          
        ; Return        Status
        ;______________________________________
        GetRectangle(GpLineGradient *brush, GpRect *rect)
        {
            status := GdipGetLineRectI(GpLineGradient *brush, GpRect *rect)
            Return status
        }
        
        ;####################################
        ; Call          SetGammaCorrection(GpLineGradient *brush, BOOL useGammaCorrection)
        ; Description   Specifies whether gamma correction is enabled for this linear gradient brush.
        ;          
        ; Params        GpLineGradient *brush, BOOL useGammaCorrection
        ;          
        ; Return        Status
        ;______________________________________
        SetGammaCorrection(GpLineGradient *brush, BOOL useGammaCorrection)
        {
            status := GdipSetLineGammaCorrection(GpLineGradient *brush, BOOL useGammaCorrection)
            Return status
        }
        
        ;####################################
        ; Call          GetGammaCorrection(GpLineGradient *brush, BOOL *useGammaCorrection)
        ; Description   Determines whether gamma correction is enabled.
        ;          
        ; Params        GpLineGradient *brush, BOOL *useGammaCorrection
        ;          
        ; Return        Status
        ;______________________________________
        GetGammaCorrection(GpLineGradient *brush, BOOL *useGammaCorrection)
        {
            status := GdipGetLineGammaCorrection(GpLineGradient *brush, BOOL *useGammaCorrection)
            Return status
        }
        
        ;####################################
        ; Call          GetBlendCount(GpLineGradient *brush, INT *count)
        ; Description   Gets the number of blend factors currently set .
        ;          
        ; Params        GpLineGradient *brush, INT *count
        ;          
        ; Return        Status
        ;______________________________________
        GetBlendCount(GpLineGradient *brush, INT *count)
        {
            status := GdipGetLineBlendCount(GpLineGradient *brush, INT *count)
            Return status
        }
        
        ;####################################
        ; Call          GetBlend(GpLineGradient *brush, REAL *blend, REAL* positions, INT count)
        ; Description   Gets the blend factors and their corresponding blend positions from a LinearGradientBrush object.
        ;          
        ; Params        GpLineGradient *brush, REAL *blend, REAL* positions, INT count
        ;          
        ; Return        Status
        ;______________________________________
        GetBlend(GpLineGradient *brush, REAL *blend, REAL* positions, INT count)
        {
            status := GdipGetLineBlend(GpLineGradient *brush, REAL *blend, REAL* positions, INT count)
            Return status
        }
        
        ;####################################
        ; Call          SetBlend(GpLineGradient *brush, GDIPCONST REAL *blend, GDIPCONST REAL* positions, INT count)
        ; Description   Sets the blend factors and the blend positions of this linear gradient brush to create a custom blend.
        ;          
        ; Params        GpLineGradient *brush, GDIPCONST REAL *blend, GDIPCONST REAL* positions, INT count
        ;          
        ; Return        Status
        ;______________________________________
        SetBlend(GpLineGradient *brush, GDIPCONST REAL *blend, GDIPCONST REAL* positions, INT count)
        {
            status := GdipSetLineBlend(GpLineGradient *brush, GDIPCONST REAL *blend, GDIPCONST REAL* positions, INT count)
            Return status
        }
        
        ;####################################
        ; Call          GetInterpolationColorCount(GpLineGradient *brush, INT *count)
        ; Description   Gets the number of colors currently set to be interpolated for this linear gradient brush.
        ;          
        ; Params        GpLineGradient *brush, INT *count
        ;          
        ; Return        Status
        ;______________________________________
        GetInterpolationColorCount(GpLineGradient *brush, INT *count)
        {
            status := GdipGetLinePresetBlendCount(GpLineGradient *brush, INT *count)
            Return status
        }
        
        ;####################################
        ; Call          GetInterpolationColors(GpLineGradient *brush, ARGB *blend, REAL* positions, INT count)
        ; Description   Gets the colors currently set to be interpolated for this linear gradient brush and their corresponding blend positions.
        ;          
        ; Params        GpLineGradient *brush, ARGB *blend, REAL* positions, INT count
        ;          
        ; Return        Status
        ;______________________________________
        GetInterpolationColors(GpLineGradient *brush, ARGB *blend, REAL* positions, INT count)
        {
            status := GdipGetLinePresetBlend(GpLineGradient *brush, ARGB *blend, REAL* positions, INT count)
            Return status
        }
        
        ;####################################
        ; Call          SetInterpolationColors(GpLineGradient *brush, GDIPCONST ARGB *blend, GDIPCONST REAL* positions, INT count)
        ; Description   Sets the colors to be interpolated for this linear gradient brush and their corresponding blend positions.
        ;          
        ; Params        GpLineGradient *brush, GDIPCONST ARGB *blend, GDIPCONST REAL* positions, INT count
        ;          
        ; Return        Status
        ;______________________________________
        SetInterpolationColors(GpLineGradient *brush, GDIPCONST ARGB *blend, GDIPCONST REAL* positions, INT count)
        {
            status := GdipSetLinePresetBlend(GpLineGradient *brush, GDIPCONST ARGB *blend, GDIPCONST REAL* positions, INT count)
            Return status
        }
        
        ;####################################
        ; Call          SetBlendBellShape(GpLineGradient *brush, REAL focus, REAL scale)
        ; Description   Sets the blend shape of this linear gradient brush to create a custom blend based on a bell-shaped curve.
        ;          
        ; Params        GpLineGradient *brush, REAL focus, REAL scale
        ;          
        ; Return        Status
        ;______________________________________
        SetBlendBellShape(GpLineGradient *brush, REAL focus, REAL scale)
        {
            status := GdipSetLineSigmaBlend(GpLineGradient *brush, REAL focus, REAL scale)
            Return status
        }
        
        ;####################################
        ; Call          SetBlendTriangularShape(GpLineGradient *brush, REAL focus, REAL scale)
        ; Description   Sets the blend shape of this linear gradient brush to create a custom blend based on a triangular shape.
        ;          
        ; Params        GpLineGradient *brush, REAL focus, REAL scale
        ;          
        ; Return        Status
        ;______________________________________
        SetBlendTriangularShape(GpLineGradient *brush, REAL focus, REAL scale)
        {
            status := GdipSetLineLinearBlend(GpLineGradient *brush, REAL focus, REAL scale)
            Return status
        }
        
        ;####################################
        ; Call          SetWrapMode(GpLineGradient *brush, GpWrapMode wrapmode)
        ; Description   Sets the wrap mode of this linear gradient brush.
        ;          
        ; Params        GpLineGradient *brush, GpWrapMode wrapmode
        ;          
        ; Return        Status
        ;______________________________________
        SetWrapMode(GpLineGradient *brush, GpWrapMode wrapmode)
        {
            status := GdipSetLineWrapMode(GpLineGradient *brush, GpWrapMode wrapmode)
            Return status
        }
        
        ;####################################
        ; Call          GetWrapMode(GpLineGradient *brush, GpWrapMode *wrapmode)
        ; Description   Gets the wrap mode for this brush. The wrap mode determines how an area is tiled when it is painted with a brush.
        ;          
        ; Params        GpLineGradient *brush, GpWrapMode *wrapmode
        ;          
        ; Return        Status
        ;______________________________________
        GetWrapMode(GpLineGradient *brush, GpWrapMode *wrapmode)
        {
            status := GdipGetLineWrapMode(GpLineGradient *brush, GpWrapMode *wrapmode)
            Return status
        }
        
        ;####################################
        ; Call          GetTransform(GpLineGradient *brush, GpMatrix *matrix)
        ; Description   Gets the transformation matrix of this linear gradient brush.
        ;          
        ; Params        GpLineGradient *brush, GpMatrix *matrix
        ;          
        ; Return        Status
        ;______________________________________
        GetTransform(GpLineGradient *brush, GpMatrix *matrix)
        {
            status := GdipGetLineTransform(GpLineGradient *brush, GpMatrix *matrix)
            Return status
        }
        
        ;####################################
        ; Call          SetTransform(GpLineGradient *brush, GDIPCONST GpMatrix *matrix)
        ; Description   Sets the transformation matrix of this linear gradient brush.
        ;          
        ; Params        GpLineGradient *brush, GDIPCONST GpMatrix *matrix
        ;          
        ; Return        Status
        ;______________________________________
        SetTransform(GpLineGradient *brush, GDIPCONST GpMatrix *matrix)
        {
            status := GdipSetLineTransform(GpLineGradient *brush, GDIPCONST GpMatrix *matrix)
            Return status
        }
        
        ;####################################
        ; Call          ResetTransform(GpLineGradient* brush)
        ; Description   Resets the transformation matrix of this linear gradient brush to the identity matrix. This means that no transformation takes place.
        ;          
        ; Params        GpLineGradient* brush
        ;          
        ; Return        Status
        ;______________________________________
        ResetTransform(GpLineGradient* brush)
        {
            status := GdipResetLineTransform(GpLineGradient* brush)
            Return status
        }
        
        ;####################################
        ; Call          MultiplyTransform(GpLineGradient* brush, GDIPCONST GpMatrix *matrix, GpMatrixOrder order)
        ; Description   Updates this brush's transformation matrix with the product of itself and another matrix.
        ;          
        ; Params        GpLineGradient* brush, GDIPCONST GpMatrix *matrix, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        MultiplyTransform(GpLineGradient* brush, GDIPCONST GpMatrix *matrix, GpMatrixOrder order)
        {
            status := GdipMultiplyLineTransform(GpLineGradient* brush, GDIPCONST GpMatrix *matrix, GpMatrixOrder order)
            Return status
        }
        
        ;####################################
        ; Call          TranslateTransform(GpLineGradient* brush, REAL dx, REAL dy, GpMatrixOrder order)
        ; Description   Updates this brush's current transformation matrix with the product of itself and a translation matrix.
        ;          
        ; Params        GpLineGradient* brush, REAL dx, REAL dy, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        TranslateTransform(GpLineGradient* brush, REAL dx, REAL dy, GpMatrixOrder order)
        {
            status := GdipTranslateLineTransform(GpLineGradient* brush, REAL dx, REAL dy, GpMatrixOrder order)
            Return status
        }
        
        ;####################################
        ; Call          ScaleTransform(GpLineGradient* brush, REAL sx, REAL sy, GpMatrixOrder order)
        ; Description   Updates this brush's current transformation matrix with the product of itself and a scaling matrix.
        ;          
        ; Params        GpLineGradient* brush, REAL sx, REAL sy, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        ScaleTransform(GpLineGradient* brush, REAL sx, REAL sy, GpMatrixOrder order)
        {
            status := GdipScaleLineTransform(GpLineGradient* brush, REAL sx, REAL sy, GpMatrixOrder order)
            Return status
        }
        
        ;####################################
        ; Call          RotateTransform(GpLineGradient* brush, REAL angle, GpMatrixOrder order)
        ; Description   Updates this brush's current transformation matrix with the product of itself and a rotation matrix.
        ;          
        ; Params        GpLineGradient* brush, REAL angle, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        RotateTransform(GpLineGradient* brush, REAL angle, GpMatrixOrder order)
        {
            status := GdipRotateLineTransform(GpLineGradient* brush, REAL angle, GpMatrixOrder order)
            Return status
        }
        
    }
    
    Class Matrix
    {
        ;####################################
        ; Call          Matrix(GpMatrix **matrix)
        ; Description   Creates and initializes a Matrix::Matrix object that represents the identity matrix.
        ;          
        ; Params        GpMatrix **matrix
        ;          
        ; Return        Status
        ;______________________________________
        Matrix(GpMatrix **matrix)
        {
            status := GdipCreateMatrix(GpMatrix **matrix)
            Return status
        }
        
        ;####################################
        ; Call          Matrix(REAL m11, REAL m12, REAL m21, REAL m22, REAL dx, REAL dy, GpMatrix **matrix)
        ; Description   Creates and initializes a Matrix::Matrix object based on six numbers that define an affine transformation.
        ;          
        ; Params        REAL m11, REAL m12, REAL m21, REAL m22, REAL dx, REAL dy, GpMatrix **matrix
        ;          
        ; Return        Status
        ;______________________________________
        Matrix(REAL m11, REAL m12, REAL m21, REAL m22, REAL dx, REAL dy, GpMatrix **matrix)
        {
            status := GdipCreateMatrix2(REAL m11, REAL m12, REAL m21, REAL m22, REAL dx, REAL dy, GpMatrix **matrix)
            Return status
        }
        
        ;####################################
        ; Call          Matrix(GDIPCONST GpRectF *rect, GDIPCONST GpPointF *dstplg, GpMatrix **matrix)
        ; Description   Creates a Matrix::Matrix object based on a rectangle and a point.
        ;          
        ; Params        GDIPCONST GpRectF *rect, GDIPCONST GpPointF *dstplg, GpMatrix **matrix
        ;          
        ; Return        Status
        ;______________________________________
        Matrix(GDIPCONST GpRectF *rect, GDIPCONST GpPointF *dstplg, GpMatrix **matrix)
        {
            status := GdipCreateMatrix3(GDIPCONST GpRectF *rect, GDIPCONST GpPointF *dstplg, GpMatrix **matrix)
            Return status
        }
        
        ;####################################
        ; Call          Matrix(GDIPCONST GpRect *rect, GDIPCONST GpPoint *dstplg, GpMatrix **matrix)
        ; Description   Creates a Matrix::Matrix object based on a rectangle and a point.
        ;          
        ; Params        GDIPCONST GpRect *rect, GDIPCONST GpPoint *dstplg, GpMatrix **matrix
        ;          
        ; Return        Status
        ;______________________________________
        Matrix(GDIPCONST GpRect *rect, GDIPCONST GpPoint *dstplg, GpMatrix **matrix)
        {
            status := GdipCreateMatrix3I(GDIPCONST GpRect *rect, GDIPCONST GpPoint *dstplg, GpMatrix **matrix)
            Return status
        }
        
        ;####################################
        ; Call          Clone(GpMatrix *matrix, GpMatrix **cloneMatrix)
        ; Description   The Matrix::Clone method creates a new Matrix object that is a copy of this Matrix object.
        ;          
        ; Params        GpMatrix *matrix, GpMatrix **cloneMatrix
        ;          
        ; Return        Status
        ;______________________________________
        Clone(GpMatrix *matrix, GpMatrix **cloneMatrix)
        {
            status := GdipCloneMatrix(GpMatrix *matrix, GpMatrix **cloneMatrix)
            Return status
        }
        
        ;####################################
        ; Call          ~Matrix(GpMatrix *matrix)
        ; Description   Cleans up resources used by a Matrix::Matrix object.
        ;          
        ; Params        GpMatrix *matrix
        ;          
        ; Return        Status
        ;______________________________________
        ~Matrix(GpMatrix *matrix)
        {
            status := GdipDeleteMatrix(GpMatrix *matrix)
            Return status
        }
        
        ;####################################
        ; Call          SetElements(GpMatrix *matrix, REAL m11, REAL m12, REAL m21, REAL m22, REAL dx, REAL dy)
        ; Description   The Matrix::SetElements method sets the elements of this matrix.
        ;          
        ; Params        GpMatrix *matrix, REAL m11, REAL m12, REAL m21, REAL m22, REAL dx, REAL dy
        ;          
        ; Return        Status
        ;______________________________________
        SetElements(GpMatrix *matrix, REAL m11, REAL m12, REAL m21, REAL m22, REAL dx, REAL dy)
        {
            status := GdipSetMatrixElements(GpMatrix *matrix, REAL m11, REAL m12, REAL m21, REAL m22, REAL dx, REAL dy)
            Return status
        }
        
        ;####################################
        ; Call          Multiply(GpMatrix *matrix, GpMatrix* matrix2, GpMatrixOrder order)
        ; Description   The Matrix::Multiply method updates this matrix with the product of itself and another matrix.
        ;          
        ; Params        GpMatrix *matrix, GpMatrix* matrix2, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        Multiply(GpMatrix *matrix, GpMatrix* matrix2, GpMatrixOrder order)
        {
            status := GdipMultiplyMatrix(GpMatrix *matrix, GpMatrix* matrix2, GpMatrixOrder order)
            Return status
        }
        
        ;####################################
        ; Call          Translate(GpMatrix *matrix, REAL offsetX, REAL offsetY, GpMatrixOrder order)
        ; Description   The Matrix::Translate method updates this matrix with the product of itself and a translation matrix.
        ;          
        ; Params        GpMatrix *matrix, REAL offsetX, REAL offsetY, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        Translate(GpMatrix *matrix, REAL offsetX, REAL offsetY, GpMatrixOrder order)
        {
            status := GdipTranslateMatrix(GpMatrix *matrix, REAL offsetX, REAL offsetY, GpMatrixOrder order)
            Return status
        }
        
        ;####################################
        ; Call          Scale(GpMatrix *matrix, REAL scaleX, REAL scaleY, GpMatrixOrder order)
        ; Description   The Matrix::Scale method updates this matrix with the product of itself and a scaling matrix.
        ;          
        ; Params        GpMatrix *matrix, REAL scaleX, REAL scaleY, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        Scale(GpMatrix *matrix, REAL scaleX, REAL scaleY, GpMatrixOrder order)
        {
            status := GdipScaleMatrix(GpMatrix *matrix, REAL scaleX, REAL scaleY, GpMatrixOrder order)
            Return status
        }
        
        ;####################################
        ; Call          Rotate(GpMatrix *matrix, REAL angle, GpMatrixOrder order)
        ; Description   The Matrix::Rotate method updates this matrix with the product of itself and a rotation matrix.
        ;          
        ; Params        GpMatrix *matrix, REAL angle, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        Rotate(GpMatrix *matrix, REAL angle, GpMatrixOrder order)
        {
            status := GdipRotateMatrix(GpMatrix *matrix, REAL angle, GpMatrixOrder order)
            Return status
        }
        
        ;####################################
        ; Call          Shear(GpMatrix *matrix, REAL shearX, REAL shearY, GpMatrixOrder order)
        ; Description   The Matrix::Shear method updates this matrix with the product of itself and a shearing matrix.
        ;          
        ; Params        GpMatrix *matrix, REAL shearX, REAL shearY, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        Shear(GpMatrix *matrix, REAL shearX, REAL shearY, GpMatrixOrder order)
        {
            status := GdipShearMatrix(GpMatrix *matrix, REAL shearX, REAL shearY, GpMatrixOrder order)
            Return status
        }
        
        ;####################################
        ; Call          Invert(GpMatrix *matrix)
        ; Description   If this matrix is invertible, the Matrix::Invert method replaces the elements of this matrix with the elements of its inverse.
        ;          
        ; Params        GpMatrix *matrix
        ;          
        ; Return        Status
        ;______________________________________
        Invert(GpMatrix *matrix)
        {
            status := GdipInvertMatrix(GpMatrix *matrix)
            Return status
        }
        
        ;####################################
        ; Call          TransformPoints(GpMatrix *matrix, GpPointF *pts, INT count)
        ; Description   The Matrix::TransformPoints method multiplies each point in an array by this matrix. Each point is treated as a row matrix. The multiplication is performed with the row matrix on the left and this matrix on the right.
        ;          
        ; Params        GpMatrix *matrix, GpPointF *pts, INT count
        ;          
        ; Return        Status
        ;______________________________________
        TransformPoints(GpMatrix *matrix, GpPointF *pts, INT count)
        {
            status := GdipTransformMatrixPoints(GpMatrix *matrix, GpPointF *pts, INT count)
            Return status
        }
        
        ;####################################
        ; Call          TransformPoints(GpMatrix *matrix, GpPoint *pts, INT count)
        ; Description   The Matrix::TransformPoints method multiplies each point in an array by this matrix. Each point is treated as a row matrix. The multiplication is performed with the row matrix on the left and this matrix on the right.
        ;          
        ; Params        GpMatrix *matrix, GpPoint *pts, INT count
        ;          
        ; Return        Status
        ;______________________________________
        TransformPoints(GpMatrix *matrix, GpPoint *pts, INT count)
        {
            status := GdipTransformMatrixPointsI(GpMatrix *matrix, GpPoint *pts, INT count)
            Return status
        }
        
        ;####################################
        ; Call          TransformVectors(GpMatrix *matrix, GpPointF *pts, INT count)
        ; Description   The Matrix::TransformVectors method multiplies each vector in an array by this matrix. The translation elements of this matrix (third row) are ignored. Each vector is treated as a row matrix. The multiplication is performed with the row matrix on the left and this matrix on the right.
        ;          
        ; Params        GpMatrix *matrix, GpPointF *pts, INT count
        ;          
        ; Return        Status
        ;______________________________________
        TransformVectors(GpMatrix *matrix, GpPointF *pts, INT count)
        {
            status := GdipVectorTransformMatrixPoints(GpMatrix *matrix, GpPointF *pts, INT count)
            Return status
        }
        
        ;####################################
        ; Call          TransformVectors(GpMatrix *matrix, GpPoint *pts, INT count)
        ; Description   The Matrix::TransformVectors method multiplies each vector in an array by this matrix. The translation elements of this matrix (third row) are ignored. Each vector is treated as a row matrix. The multiplication is performed with the row matrix on the left and this matrix on the right.
        ;          
        ; Params        GpMatrix *matrix, GpPoint *pts, INT count
        ;          
        ; Return        Status
        ;______________________________________
        TransformVectors(GpMatrix *matrix, GpPoint *pts, INT count)
        {
            status := GdipVectorTransformMatrixPointsI(GpMatrix *matrix, GpPoint *pts, INT count)
            Return status
        }
        
        ;####################################
        ; Call          GetElements(GDIPCONST GpMatrix *matrix, REAL *matrixOut)
        ; Description   The Matrix::GetElements method gets the elements of this matrix. The elements are placed in an array in the order m11, m12, m21, m22, m31, m32, where mij denotes the element in row i, column j.
        ;          
        ; Params        GDIPCONST GpMatrix *matrix, REAL *matrixOut
        ;          
        ; Return        Status
        ;______________________________________
        GetElements(GDIPCONST GpMatrix *matrix, REAL *matrixOut)
        {
            status := GdipGetMatrixElements(GDIPCONST GpMatrix *matrix, REAL *matrixOut)
            Return status
        }
        
        ;####################################
        ; Call          IsInvertible(GDIPCONST GpMatrix *matrix, BOOL *result)
        ; Description   The Matrix::IsInvertible method determines whether this matrix is invertible.
        ;          
        ; Params        GDIPCONST GpMatrix *matrix, BOOL *result
        ;          
        ; Return        Status
        ;______________________________________
        IsInvertible(GDIPCONST GpMatrix *matrix, BOOL *result)
        {
            status := GdipIsMatrixInvertible(GDIPCONST GpMatrix *matrix, BOOL *result)
            Return status
        }
        
        ;####################################
        ; Call          IsIdentity(GDIPCONST GpMatrix *matrix, BOOL *result)
        ; Description   The Matrix::IsIdentity method determines whether this matrix is the identity matrix.
        ;          
        ; Params        GDIPCONST GpMatrix *matrix, BOOL *result
        ;          
        ; Return        Status
        ;______________________________________
        IsIdentity(GDIPCONST GpMatrix *matrix, BOOL *result)
        {
            status := GdipIsMatrixIdentity(GDIPCONST GpMatrix *matrix, BOOL *result)
            Return status
        }
        
        ;####################################
        ; Call          Equals(GDIPCONST GpMatrix *matrix, GDIPCONST GpMatrix *matrix2, BOOL *result)
        ; Description   The Matrix::Equals method determines whether the elements of this matrix are equal to the elements of another matrix.
        ;          
        ; Params        GDIPCONST GpMatrix *matrix, GDIPCONST GpMatrix *matrix2, BOOL *result
        ;          
        ; Return        Status
        ;______________________________________
        Equals(GDIPCONST GpMatrix *matrix, GDIPCONST GpMatrix *matrix2, BOOL *result)
        {
            status := GdipIsMatrixEqual(GDIPCONST GpMatrix *matrix, GDIPCONST GpMatrix *matrix2, BOOL *result)
            Return status
        }
    }
    
    Class Memory
    {
        ;####################################
        ; Call          new(size_t size)
        ; Description   Allocates memory for one Windows GDI+ object.\nGdipAlloc is declared in GdiplusMem.h.
        ;          
        ; Params        size_t size
        ;          
        ; Return        Status
        ;______________________________________
        new(size_t size)
        {
            status := GdipAlloc(size_t size)
            Return status
        }
        
        ;####################################
        ; Call          delete(void* ptr)
        ; Description   Deallocates memory for one Windows GDI+ object.\nGdipFree is declared in GdiplusMem.h.
        ;          
        ; Params        void* ptr
        ;          
        ; Return        Status
        ;______________________________________
        delete(void* ptr)
        {
            status := GdipFree(void* ptr)
            Return status
        }
    }
    
    Class Notification
    {
        ;####################################
        ; Call          GdiplusNotificationHook(OUT ULONG_PTR *token)
        ; Description   The GdiplusStartup function returns (in its output parameter) a pointer to a GdiplusStartupOutput structure. One of the members of the structure is a pointer to a notification hook function that has the same signature as GdiplusNotificationHook.\nThere are two ways you can call the notification hook function; you can use the pointer returned by GdiplusStartup or you can call GdiplusNotificationHook. In fact, GdiplusNotificationHook simply verifies that you have suppressed the background thread and then calls the notification hook function that is returned by GdiplusStartup.\nThe token parameter receives an identifier that you should later pass in a corresponding call to the notification unhook function.
        ;          
        ; Params        OUT ULONG_PTR *token
        ;          
        ; Return        Status
        ;______________________________________
        GdiplusNotificationHook(OUT ULONG_PTR *token)
        {
            status := GdiplusNotificationHook(OUT ULONG_PTR *token)
            Return status
        }
        
        ;####################################
        ; Call          GdiplusNotificationUnhook(ULONG_PTR token)
        ; Description   The GdiplusStartup function returns (in its output parameter) a pointer to a GdiplusStartupOutput structure. One of the members of the structure is a pointer to a notification unhook function that has the same signature as GdiplusNotificationUnhook.\nThere are two ways you can call the notification unhook function; you can use the pointer returned by GdiplusStartup or you can call GdiplusNotificationUnhook. In fact, GdiplusNotificationUnhook simply verifies that you have suppressed the background thread and then calls the notification unhook function that is returned by GdiplusStartup.\nWhen you call the notification unhook function, pass the token that you previously received from a corresponding call to the notification hook function. If you do not do this, there will be resource leaks that won't be cleaned up until the process exits.
        ;          
        ; Params        ULONG_PTR token
        ;          
        ; Return        Status
        ;______________________________________
        GdiplusNotificationUnhook(ULONG_PTR token)
        {
            status := GdiplusNotificationUnhook(ULONG_PTR token)
            Return status
        }
    }
    
    Class PathGradientBrush
    {
        ;####################################
        ; Call          PathGradientBrush(GDIPCONST GpPointF* points, INT count, GpWrapMode wrapMode, GpPathGradient **polyGradient)
        ; Description   Creates a PathGradientBrush object based on an array of points. Initializes the wrap mode of the path gradient brush.
        ;          
        ; Params        GDIPCONST GpPointF* points, INT count, GpWrapMode wrapMode, GpPathGradient **polyGradient
        ;          
        ; Return        Status
        ;______________________________________
        PathGradientBrush(GDIPCONST GpPointF* points, INT count, GpWrapMode wrapMode, GpPathGradient **polyGradient)
        {
            status := GdipCreatePathGradient(GDIPCONST GpPointF* points, INT count, GpWrapMode wrapMode, GpPathGradient **polyGradient)
            Return status
        }
        
        ;####################################
        ; Call          PathGradientBrush(GDIPCONST GpPoint* points, INT count, GpWrapMode wrapMode, GpPathGradient **polyGradient)
        ; Description   Creates a PathGradientBrush object based on an array of points. Initializes the wrap mode of the path gradient brush.
        ;          
        ; Params        GDIPCONST GpPoint* points, INT count, GpWrapMode wrapMode, GpPathGradient **polyGradient
        ;          
        ; Return        Status
        ;______________________________________
        PathGradientBrush(GDIPCONST GpPoint* points, INT count, GpWrapMode wrapMode, GpPathGradient **polyGradient)
        {
            status := GdipCreatePathGradientI(GDIPCONST GpPoint* points, INT count, GpWrapMode wrapMode, GpPathGradient **polyGradient)
            Return status
        }
        
        ;####################################
        ; Call          PathGradientBrush(GDIPCONST GpPath* path, GpPathGradient **polyGradient)
        ; Description   Creates a PathGradientBrush object based on a GraphicsPath object.
        ;          
        ; Params        GDIPCONST GpPath* path, GpPathGradient **polyGradient
        ;          
        ; Return        Status
        ;______________________________________
        PathGradientBrush(GDIPCONST GpPath* path, GpPathGradient **polyGradient)
        {
            status := GdipCreatePathGradientFromPath(GDIPCONST GpPath* path, GpPathGradient **polyGradient)
            Return status
        }
        
        ;####################################
        ; Call          GetCenterColor( GpPathGradient *brush, ARGB* colors)
        ; Description   Gets the color of the center point of this path gradient brush.
        ;          
        ; Params        GpPathGradient *brush, ARGB* colors
        ;          
        ; Return        Status
        ;______________________________________
        GetCenterColor( GpPathGradient *brush, ARGB* colors)
        {
            status := GdipGetPathGradientCenterColor( GpPathGradient *brush, ARGB* colors)
            Return status
        }
        
        ;####################################
        ; Call          SetCenterColor( GpPathGradient *brush, ARGB colors)
        ; Description   Sets the center color of this path gradient brush. The center color is the color that appears at the brush's center point.
        ;          
        ; Params        GpPathGradient *brush, ARGB colors
        ;          
        ; Return        Status
        ;______________________________________
        SetCenterColor( GpPathGradient *brush, ARGB colors)
        {
            status := GdipSetPathGradientCenterColor( GpPathGradient *brush, ARGB colors)
            Return status
        }
        
        ;####################################
        ; Call          GetSurroundColors( GpPathGradient *brush, ARGB* color, INT* count)
        ; Description   Gets the surround colors currently specified for this path gradient brush.
        ;          
        ; Params        GpPathGradient *brush, ARGB* color, INT* count
        ;          
        ; Return        Status
        ;______________________________________
        GetSurroundColors( GpPathGradient *brush, ARGB* color, INT* count)
        {
            status := GdipGetPathGradientSurroundColorsWithCount( GpPathGradient *brush, ARGB* color, INT* count)
            Return status
        }
        
        ;####################################
        ; Call          SetSurroundColors( GpPathGradient *brush, GDIPCONST ARGB* color, INT* count)
        ; Description   Sets the surround colors of this path gradient brush. The surround colors are colors specified for discrete points on the brush's boundary path.
        ;          
        ; Params        GpPathGradient *brush, GDIPCONST ARGB* color, INT* count
        ;          
        ; Return        Status
        ;______________________________________
        SetSurroundColors( GpPathGradient *brush, GDIPCONST ARGB* color, INT* count)
        {
            status := GdipSetPathGradientSurroundColorsWithCount( GpPathGradient *brush, GDIPCONST ARGB* color, INT* count)
            Return status
        }
        
        ;####################################
        ; Call          GetGraphicsPath(GpPathGradient *brush, GpPath *path)
        ; Description   Is not implemented in GDI+ version 1.0.
        ;          
        ; Params        GpPathGradient *brush, GpPath *path
        ;          
        ; Return        Status
        ;______________________________________
        GetGraphicsPath(GpPathGradient *brush, GpPath *path)
        {
            status := GdipGetPathGradientPath(GpPathGradient *brush, GpPath *path)
            Return status
        }
        
        ;####################################
        ; Call          SetGraphicsPath(GpPathGradient *brush, GDIPCONST GpPath *path)
        ; Description   Is not implemented in GDI+ version 1.0.
        ;          
        ; Params        GpPathGradient *brush, GDIPCONST GpPath *path
        ;          
        ; Return        Status
        ;______________________________________
        SetGraphicsPath(GpPathGradient *brush, GDIPCONST GpPath *path)
        {
            status := GdipSetPathGradientPath(GpPathGradient *brush, GDIPCONST GpPath *path)
            Return status
        }
        
        ;####################################
        ; Call          GetCenterPoint( GpPathGradient *brush, GpPointF* points)
        ; Description   Gets the center point of this path gradient brush.
        ;          
        ; Params        GpPathGradient *brush, GpPointF* points
        ;          
        ; Return        Status
        ;______________________________________
        GetCenterPoint( GpPathGradient *brush, GpPointF* points)
        {
            status := GdipGetPathGradientCenterPoint( GpPathGradient *brush, GpPointF* points)
            Return status
        }
        
        ;####################################
        ; Call          GetCenterPoint( GpPathGradient *brush, GpPoint* points)
        ; Description   Gets the center point of this path gradient brush.
        ;          
        ; Params        GpPathGradient *brush, GpPoint* points
        ;          
        ; Return        Status
        ;______________________________________
        GetCenterPoint( GpPathGradient *brush, GpPoint* points)
        {
            status := GdipGetPathGradientCenterPointI( GpPathGradient *brush, GpPoint* points)
            Return status
        }
        
        ;####################################
        ; Call          SetCenterPoint( GpPathGradient *brush, GDIPCONST GpPointF* points)
        ; Description   Sets the center point of this path gradient brush. By default, the center point is at the centroid of the brush's boundary path, but you can set the center point to any location inside or outside the path.
        ;          
        ; Params        GpPathGradient *brush, GDIPCONST GpPointF* points
        ;          
        ; Return        Status
        ;______________________________________
        SetCenterPoint( GpPathGradient *brush, GDIPCONST GpPointF* points)
        {
            status := GdipSetPathGradientCenterPoint( GpPathGradient *brush, GDIPCONST GpPointF* points)
            Return status
        }
        
        ;####################################
        ; Call          SetCenterPoint( GpPathGradient *brush, GDIPCONST GpPoint* points)
        ; Description   Sets the center point of this path gradient brush. By default, the center point is at the centroid of the brush's boundary path, but you can set the center point to any location inside or outside the path.
        ;          
        ; Params        GpPathGradient *brush, GDIPCONST GpPoint* points
        ;          
        ; Return        Status
        ;______________________________________
        SetCenterPoint( GpPathGradient *brush, GDIPCONST GpPoint* points)
        {
            status := GdipSetPathGradientCenterPointI( GpPathGradient *brush, GDIPCONST GpPoint* points)
            Return status
        }
        
        ;####################################
        ; Call          GetRectangle(GpPathGradient *brush, GpRectF *rect)
        ; Description   Gets the smallest rectangle that encloses the boundary path of this path gradient brush.
        ;          
        ; Params        GpPathGradient *brush, GpRectF *rect
        ;          
        ; Return        Status
        ;______________________________________
        GetRectangle(GpPathGradient *brush, GpRectF *rect)
        {
            status := GdipGetPathGradientRect(GpPathGradient *brush, GpRectF *rect)
            Return status
        }
        
        ;####################################
        ; Call          GetRectangle(GpPathGradient *brush, GpRect *rect)
        ; Description   Gets the smallest rectangle that encloses the boundary path of this path gradient brush.
        ;          
        ; Params        GpPathGradient *brush, GpRect *rect
        ;          
        ; Return        Status
        ;______________________________________
        GetRectangle(GpPathGradient *brush, GpRect *rect)
        {
            status := GdipGetPathGradientRectI(GpPathGradient *brush, GpRect *rect)
            Return status
        }
        
        ;####################################
        ; Call          GetPointCount(GpPathGradient *brush, INT* count)
        ; Description   Gets the number of points in the array of points that defines this brush's boundary path.
        ;          
        ; Params        GpPathGradient *brush, INT* count
        ;          
        ; Return        Status
        ;______________________________________
        GetPointCount(GpPathGradient *brush, INT* count)
        {
            status := GdipGetPathGradientPointCount(GpPathGradient *brush, INT* count)
            Return status
        }
        
        ;####################################
        ; Call          GetSurroundColorCount(GpPathGradient *brush, INT* count)
        ; Description   Gets the number of colors that have been specified for the boundary path of this path gradient brush.
        ;          
        ; Params        GpPathGradient *brush, INT* count
        ;          
        ; Return        Status
        ;______________________________________
        GetSurroundColorCount(GpPathGradient *brush, INT* count)
        {
            status := GdipGetPathGradientSurroundColorCount(GpPathGradient *brush, INT* count)
            Return status
        }
        
        ;####################################
        ; Call          SetGammaCorrection(GpPathGradient *brush, BOOL useGammaCorrection)
        ; Description   Specifies whether gamma correction is enabled for this path gradient brush.
        ;          
        ; Params        GpPathGradient *brush, BOOL useGammaCorrection
        ;          
        ; Return        Status
        ;______________________________________
        SetGammaCorrection(GpPathGradient *brush, BOOL useGammaCorrection)
        {
            status := GdipSetPathGradientGammaCorrection(GpPathGradient *brush, BOOL useGammaCorrection)
            Return status
        }
        
        ;####################################
        ; Call          GetGammaCorrection(GpPathGradient *brush, BOOL *useGammaCorrection)
        ; Description   Determines whether gamma correction is enabled for this path gradient brush.
        ;          
        ; Params        GpPathGradient *brush, BOOL *useGammaCorrection
        ;          
        ; Return        Status
        ;______________________________________
        GetGammaCorrection(GpPathGradient *brush, BOOL *useGammaCorrection)
        {
            status := GdipGetPathGradientGammaCorrection(GpPathGradient *brush, BOOL *useGammaCorrection)
            Return status
        }
        
        ;####################################
        ; Call          GetBlendCount(GpPathGradient *brush, INT *count)
        ; Description   Gets the number of blend factors currently set for this path gradient brush.
        ;          
        ; Params        GpPathGradient *brush, INT *count
        ;          
        ; Return        Status
        ;______________________________________
        GetBlendCount(GpPathGradient *brush, INT *count)
        {
            status := GdipGetPathGradientBlendCount(GpPathGradient *brush, INT *count)
            Return status
        }
        
        ;####################################
        ; Call          GetBlend(GpPathGradient *brush, REAL *blend, REAL *positions, INT count)
        ; Description   Gets the blend factors and the corresponding blend positions currently set for this path gradient brush.
        ;          
        ; Params        GpPathGradient *brush, REAL *blend, REAL *positions, INT count
        ;          
        ; Return        Status
        ;______________________________________
        GetBlend(GpPathGradient *brush, REAL *blend, REAL *positions, INT count)
        {
            status := GdipGetPathGradientBlend(GpPathGradient *brush, REAL *blend, REAL *positions, INT count)
            Return status
        }
        
        ;####################################
        ; Call          SetBlend(GpPathGradient *brush, GDIPCONST REAL *blend, GDIPCONST REAL *positions, INT count)
        ; Description   Sets the blend factors and the blend positions of this path gradient brush.
        ;          
        ; Params        GpPathGradient *brush, GDIPCONST REAL *blend, GDIPCONST REAL *positions, INT count
        ;          
        ; Return        Status
        ;______________________________________
        SetBlend(GpPathGradient *brush, GDIPCONST REAL *blend, GDIPCONST REAL *positions, INT count)
        {
            status := GdipSetPathGradientBlend(GpPathGradient *brush, GDIPCONST REAL *blend, GDIPCONST REAL *positions, INT count)
            Return status
        }
        
        ;####################################
        ; Call          GetInterpolationColorCount(GpPathGradient *brush, INT *count)
        ; Description   Gets the number of preset colors currently specified for this path gradient brush.
        ;          
        ; Params        GpPathGradient *brush, INT *count
        ;          
        ; Return        Status
        ;______________________________________
        GetInterpolationColorCount(GpPathGradient *brush, INT *count)
        {
            status := GdipGetPathGradientPresetBlendCount(GpPathGradient *brush, INT *count)
            Return status
        }
        
        ;####################################
        ; Call          GetInterpolationColors(GpPathGradient *brush, ARGB *blend, REAL* positions, INT count)
        ; Description   Gets the preset colors and blend positions currently specified for this path gradient brush.
        ;          
        ; Params        GpPathGradient *brush, ARGB *blend, REAL* positions, INT count
        ;          
        ; Return        Status
        ;______________________________________
        GetInterpolationColors(GpPathGradient *brush, ARGB *blend, REAL* positions, INT count)
        {
            status := GdipGetPathGradientPresetBlend(GpPathGradient *brush, ARGB *blend, REAL* positions, INT count)
            Return status
        }
        
        ;####################################
        ; Call          SetInterpolationColors(GpPathGradient *brush, GDIPCONST ARGB *blend, GDIPCONST REAL* positions, INT count)
        ; Description   Sets the preset colors and the blend positions of this path gradient brush.
        ;          
        ; Params        GpPathGradient *brush, GDIPCONST ARGB *blend, GDIPCONST REAL* positions, INT count
        ;          
        ; Return        Status
        ;______________________________________
        SetInterpolationColors(GpPathGradient *brush, GDIPCONST ARGB *blend, GDIPCONST REAL* positions, INT count)
        {
            status := GdipSetPathGradientPresetBlend(GpPathGradient *brush, GDIPCONST ARGB *blend, GDIPCONST REAL* positions, INT count)
            Return status
        }
        
        ;####################################
        ; Call          SetBlendBellShape(GpPathGradient *brush, REAL focus, REAL scale)
        ; Description   Sets the blend shape of this path gradient brush.
        ;          
        ; Params        GpPathGradient *brush, REAL focus, REAL scale
        ;          
        ; Return        Status
        ;______________________________________
        SetBlendBellShape(GpPathGradient *brush, REAL focus, REAL scale)
        {
            status := GdipSetPathGradientSigmaBlend(GpPathGradient *brush, REAL focus, REAL scale)
            Return status
        }
        
        ;####################################
        ; Call          SetBlendTriangularShape(GpPathGradient *brush, REAL focus, REAL scale)
        ; Description   Sets the blend shape of this path gradient brush.
        ;          
        ; Params        GpPathGradient *brush, REAL focus, REAL scale
        ;          
        ; Return        Status
        ;______________________________________
        SetBlendTriangularShape(GpPathGradient *brush, REAL focus, REAL scale)
        {
            status := GdipSetPathGradientLinearBlend(GpPathGradient *brush, REAL focus, REAL scale)
            Return status
        }
        
        ;####################################
        ; Call          GetWrapMode(GpPathGradient *brush, GpWrapMode *wrapmode)
        ; Description   Gets the wrap mode currently set for this path gradient brush.
        ;          
        ; Params        GpPathGradient *brush, GpWrapMode *wrapmode
        ;          
        ; Return        Status
        ;______________________________________
        GetWrapMode(GpPathGradient *brush, GpWrapMode *wrapmode)
        {
            status := GdipGetPathGradientWrapMode(GpPathGradient *brush, GpWrapMode *wrapmode)
            Return status
        }
        
        ;####################################
        ; Call          SetWrapMode(GpPathGradient *brush, GpWrapMode wrapmode)
        ; Description   Sets the wrap mode of this path gradient brush.
        ;          
        ; Params        GpPathGradient *brush, GpWrapMode wrapmode
        ;          
        ; Return        Status
        ;______________________________________
        SetWrapMode(GpPathGradient *brush, GpWrapMode wrapmode)
        {
            status := GdipSetPathGradientWrapMode(GpPathGradient *brush, GpWrapMode wrapmode)
            Return status
        }
        
        ;####################################
        ; Call          GetTransform(GpPathGradient *brush, GpMatrix *matrix)
        ; Description   Gets transformation matrix of this path gradient brush.
        ;          
        ; Params        GpPathGradient *brush, GpMatrix *matrix
        ;          
        ; Return        Status
        ;______________________________________
        GetTransform(GpPathGradient *brush, GpMatrix *matrix)
        {
            status := GdipGetPathGradientTransform(GpPathGradient *brush, GpMatrix *matrix)
            Return status
        }
        
        ;####################################
        ; Call          SetTransform(GpPathGradient *brush, GpMatrix *matrix)
        ; Description   Sets the transformation matrix of this path gradient brush.
        ;          
        ; Params        GpPathGradient *brush, GpMatrix *matrix
        ;          
        ; Return        Status
        ;______________________________________
        SetTransform(GpPathGradient *brush, GpMatrix *matrix)
        {
            status := GdipSetPathGradientTransform(GpPathGradient *brush, GpMatrix *matrix)
            Return status
        }
        
        ;####################################
        ; Call          ResetTransform(GpPathGradient* brush)
        ; Description   Resets the transformation matrix of this path gradient brush to the identity matrix. This means that no transformation will take place.
        ;          
        ; Params        GpPathGradient* brush
        ;          
        ; Return        Status
        ;______________________________________
        ResetTransform(GpPathGradient* brush)
        {
            status := GdipResetPathGradientTransform(GpPathGradient* brush)
            Return status
        }
        
        ;####################################
        ; Call          MultiplyTransform(GpPathGradient* brush, GDIPCONST GpMatrix *matrix, GpMatrixOrder order)
        ; Description   Updates the brush's transformation matrix with the product of itself and another matrix.
        ;          
        ; Params        GpPathGradient* brush, GDIPCONST GpMatrix *matrix, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        MultiplyTransform(GpPathGradient* brush, GDIPCONST GpMatrix *matrix, GpMatrixOrder order)
        {
            status := GdipMultiplyPathGradientTransform(GpPathGradient* brush, GDIPCONST GpMatrix *matrix, GpMatrixOrder order)
            Return status
        }
        
        ;####################################
        ; Call          TranslateTransform(GpPathGradient* brush, REAL dx, REAL dy, GpMatrixOrder order)
        ; Description   Updates this brush's current transformation matrix with the product of itself and a translation matrix.
        ;          
        ; Params        GpPathGradient* brush, REAL dx, REAL dy, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        TranslateTransform(GpPathGradient* brush, REAL dx, REAL dy, GpMatrixOrder order)
        {
            status := GdipTranslatePathGradientTransform(GpPathGradient* brush, REAL dx, REAL dy, GpMatrixOrder order)
            Return status
        }
        
        ;####################################
        ; Call          ScaleTransform(GpPathGradient* brush, REAL sx, REAL sy, GpMatrixOrder order)
        ; Description   Updates this brush's current transformation matrix with the product of itself and a scaling matrix.
        ;          
        ; Params        GpPathGradient* brush, REAL sx, REAL sy, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        ScaleTransform(GpPathGradient* brush, REAL sx, REAL sy, GpMatrixOrder order)
        {
            status := GdipScalePathGradientTransform(GpPathGradient* brush, REAL sx, REAL sy, GpMatrixOrder order)
            Return status
        }
        
        ;####################################
        ; Call          RotateTransform(GpPathGradient* brush, REAL angle, GpMatrixOrder order)
        ; Description   Updates this brush's current transformation matrix with the product of itself and a rotation matrix.
        ;          
        ; Params        GpPathGradient* brush, REAL angle, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        RotateTransform(GpPathGradient* brush, REAL angle, GpMatrixOrder order)
        {
            status := GdipRotatePathGradientTransform(GpPathGradient* brush, REAL angle, GpMatrixOrder order)
            Return status
        }
        
        ;####################################
        ; Call          GetFocusScales(GpPathGradient *brush, REAL* xScale, REAL* yScale)
        ; Description   Gets the focus scales of this path gradient brush.
        ;          
        ; Params        GpPathGradient *brush, REAL* xScale, REAL* yScale
        ;          
        ; Return        Status
        ;______________________________________
        GetFocusScales(GpPathGradient *brush, REAL* xScale, REAL* yScale)
        {
            status := GdipGetPathGradientFocusScales(GpPathGradient *brush, REAL* xScale, REAL* yScale)
            Return status
        }
        
        ;####################################
        ; Call          SetFocusScales(GpPathGradient *brush, REAL xScale, REAL yScale)
        ; Description   Sets the focus scales of this path gradient brush
        ;          
        ; Params        GpPathGradient *brush, REAL xScale, REAL yScale
        ;          
        ; Return        Status
        ;______________________________________
        SetFocusScales(GpPathGradient *brush, REAL xScale, REAL yScale)
        {
            status := GdipSetPathGradientFocusScales(GpPathGradient *brush, REAL xScale, REAL yScale)
            Return status
        }
    }
    
    Class PathIterator
    {
        ;####################################
        ; Call          GraphicsPathIterator(GpPathIterator **iterator, GpPath* path)
        ; Description   Creates a new GraphicsPathIterator object and associates it with a GraphicsPath object.
        ;          
        ; Params        GpPathIterator **iterator, GpPath* path
        ;          
        ; Return        Status
        ;______________________________________
        GraphicsPathIterator(GpPathIterator **iterator, GpPath* path)
        {
            status := GdipCreatePathIter(GpPathIterator **iterator, GpPath* path)
            Return status
        }
        
        ;####################################
        ; Call          ~GraphicsPathIterator(GpPathIterator *iterator)
        ; Description   Releases resources used by the GraphicsPathIterator object.
        ;          
        ; Params        GpPathIterator *iterator
        ;          
        ; Return        Status
        ;______________________________________
        ~GraphicsPathIterator(GpPathIterator *iterator)
        {
            status := GdipDeletePathIter(GpPathIterator *iterator)
            Return status
        }
        
        ;####################################
        ; Call          NextSubpath(GpPathIterator* iterator, INT *resultCount, INT* startIndex, INT* endIndex, BOOL* isClosed)
        ; Description   Gets the starting index and the ending index of the next subpath (figure) in this iterator's associated path.
        ;          
        ; Params        GpPathIterator* iterator, INT *resultCount, INT* startIndex, INT* endIndex, BOOL* isClosed
        ;          
        ; Return        Status
        ;______________________________________
        NextSubpath(GpPathIterator* iterator, INT *resultCount, INT* startIndex, INT* endIndex, BOOL* isClosed)
        {
            status := GdipPathIterNextSubpath(GpPathIterator* iterator, INT *resultCount, INT* startIndex, INT* endIndex, BOOL* isClosed)
            Return status
        }
        
        ;####################################
        ; Call          NextSubpath(GpPathIterator* iterator, INT* resultCount, GpPath* path, BOOL* isClosed)
        ; Description   Getsthe next figure (subpath) from this iterator's associated path.
        ;          
        ; Params        GpPathIterator* iterator, INT* resultCount, GpPath* path, BOOL* isClosed
        ;          
        ; Return        Status
        ;______________________________________
        NextSubpath(GpPathIterator* iterator, INT* resultCount, GpPath* path, BOOL* isClosed)
        {
            status := GdipPathIterNextSubpathPath(GpPathIterator* iterator, INT* resultCount, GpPath* path, BOOL* isClosed)
            Return status
        }
        
        ;####################################
        ; Call          NextPathType(GpPathIterator* iterator, INT* resultCount, BYTE* pathType, INT* startIndex, INT* endIndex)
        ; Description   Gets the starting index and the ending index of the next group of data points that all have the same type.
        ;          
        ; Params        GpPathIterator* iterator, INT* resultCount, BYTE* pathType, INT* startIndex, INT* endIndex
        ;          
        ; Return        Status
        ;______________________________________
        NextPathType(GpPathIterator* iterator, INT* resultCount, BYTE* pathType, INT* startIndex, INT* endIndex)
        {
            status := GdipPathIterNextPathType(GpPathIterator* iterator, INT* resultCount, BYTE* pathType, INT* startIndex, INT* endIndex)
            Return status
        }
        
        ;####################################
        ; Call          NextMarker(GpPathIterator* iterator, INT *resultCount, INT* startIndex, INT* endIndex)
        ; Description   Gets the starting index and the ending index of the next marker-delimited section in this iterator's associated path.
        ;          
        ; Params        GpPathIterator* iterator, INT *resultCount, INT* startIndex, INT* endIndex
        ;          
        ; Return        Status
        ;______________________________________
        NextMarker(GpPathIterator* iterator, INT *resultCount, INT* startIndex, INT* endIndex)
        {
            status := GdipPathIterNextMarker(GpPathIterator* iterator, INT *resultCount, INT* startIndex, INT* endIndex)
            Return status
        }
        
        ;####################################
        ; Call          NextMarker(GpPathIterator* iterator, INT* resultCount, GpPath* path)
        ; Description   Gets the next marker-delimited section of this iterator's associated path.
        ;          
        ; Params        GpPathIterator* iterator, INT* resultCount, GpPath* path
        ;          
        ; Return        Status
        ;______________________________________
        NextMarker(GpPathIterator* iterator, INT* resultCount, GpPath* path)
        {
            status := GdipPathIterNextMarkerPath(GpPathIterator* iterator, INT* resultCount, GpPath* path)
            Return status
        }
        
        ;####################################
        ; Call          GetCount(GpPathIterator* iterator, INT* count)
        ; Description   Returns the number of data points in the path.
        ;          
        ; Params        GpPathIterator* iterator, INT* count
        ;          
        ; Return        Status
        ;______________________________________
        GetCount(GpPathIterator* iterator, INT* count)
        {
            status := GdipPathIterGetCount(GpPathIterator* iterator, INT* count)
            Return status
        }
        
        ;####################################
        ; Call          GetSubpathCount(GpPathIterator* iterator, INT* count)
        ; Description   Returns the number of subpaths (also called figures) in the path.
        ;          
        ; Params        GpPathIterator* iterator, INT* count
        ;          
        ; Return        Status
        ;______________________________________
        GetSubpathCount(GpPathIterator* iterator, INT* count)
        {
            status := GdipPathIterGetSubpathCount(GpPathIterator* iterator, INT* count)
            Return status
        }
        
        ;####################################
        ; Call          GdipPathIterIsValid(GpPathIterator* iterator, BOOL* valid)
        ; Description   This function passes a Boolean value that indicates whether the path iterator specified by the iterator parameter is valid. The output parameter valid receives the result.
        ;          
        ; Params        GpPathIterator* iterator, BOOL* valid
        ;          
        ; Return        Status
        ;______________________________________
        GdipPathIterIsValid(GpPathIterator* iterator, BOOL* valid)
        {
            status := GdipPathIterIsValid(GpPathIterator* iterator, BOOL* valid)
            Return status
        }
        
        ;####################################
        ; Call          HasCurve(GpPathIterator* iterator, BOOL* hasCurve)
        ; Description   Determines whether the path has any curves.
        ;          
        ; Params        GpPathIterator* iterator, BOOL* hasCurve
        ;          
        ; Return        Status
        ;______________________________________
        HasCurve(GpPathIterator* iterator, BOOL* hasCurve)
        {
            status := GdipPathIterHasCurve(GpPathIterator* iterator, BOOL* hasCurve)
            Return status
        }
        
        ;####################################
        ; Call          Rewind(GpPathIterator* iterator)
        ; Description   Rewinds this iterator to the beginning of its associated path.
        ;          
        ; Params        GpPathIterator* iterator
        ;          
        ; Return        Status
        ;______________________________________
        Rewind(GpPathIterator* iterator)
        {
            status := GdipPathIterRewind(GpPathIterator* iterator)
            Return status
        }
        
        ;####################################
        ; Call          Enumerate(GpPathIterator* iterator, INT* resultCount, GpPointF *points, BYTE *types, INT count)
        ; Description   Copies the path's data points to a PointF array and copies the path's point types to a BYTE array.
        ;          
        ; Params        GpPathIterator* iterator, INT* resultCount, GpPointF *points, BYTE *types, INT count
        ;          
        ; Return        Status
        ;______________________________________
        Enumerate(GpPathIterator* iterator, INT* resultCount, GpPointF *points, BYTE *types, INT count)
        {
            status := GdipPathIterEnumerate(GpPathIterator* iterator, INT* resultCount, GpPointF *points, BYTE *types, INT count)
            Return status
        }
        
        ;####################################
        ; Call          CopyData(GpPathIterator* iterator, INT* resultCount, GpPointF* points, BYTE* types, INT startIndex, INT endIndex)
        ; Description   Copies a subset of the path's data points to a PointF array and copies a subset of the path's point types to a BYTE array.
        ;          
        ; Params        GpPathIterator* iterator, INT* resultCount, GpPointF* points, BYTE* types, INT startIndex, INT endIndex
        ;          
        ; Return        Status
        ;______________________________________
        CopyData(GpPathIterator* iterator, INT* resultCount, GpPointF* points, BYTE* types, INT startIndex, INT endIndex)
        {
            status := GdipPathIterCopyData(GpPathIterator* iterator, INT* resultCount, GpPointF* points, BYTE* types, INT startIndex, INT endIndex)
            Return status
        }
    }
    
    Class Pen
    {
        ;####################################
        ; Call          Pen(ARGB color, REAL width, GpUnit unit, GpPen **pen)
        ; Description   Creates a Pen object that uses a specified color and width.\nThe unit parameter of the flat function is a member of the Unit enumeration that specifies the unit of measure for the width of the pen.
        ;          
        ; Params        ARGB color, REAL width, GpUnit unit, GpPen **pen
        ;          
        ; Return        Status
        ;______________________________________
        Pen(ARGB color, REAL width, GpUnit unit, GpPen **pen)
        {
            status := GdipCreatePen1(ARGB color, REAL width, GpUnit unit, GpPen **pen)
            Return status
        }
        
        ;####################################
        ; Call          Pen(GpBrush *brush, REAL width, GpUnit unit, GpPen **pen)
        ; Description   Creates a Pen object that uses the attributes of a brush and a real number to set the width of this Pen object.\nThe unit parameter of the flat function is a member of the Unit enumeration that specifies the unit of measure for the width of the pen.
        ;          
        ; Params        GpBrush *brush, REAL width, GpUnit unit, GpPen **pen
        ;          
        ; Return        Status
        ;______________________________________
        Pen(GpBrush *brush, REAL width, GpUnit unit, GpPen **pen)
        {
            status := GdipCreatePen2(GpBrush *brush, REAL width, GpUnit unit, GpPen **pen)
            Return status
        }
        
        ;####################################
        ; Call          Clone(GpPen *pen, GpPen **clonepen)
        ; Description   Copies a Pen object.
        ;          
        ; Params        GpPen *pen, GpPen **clonepen
        ;          
        ; Return        Status
        ;______________________________________
        Clone(GpPen *pen, GpPen **clonepen)
        {
            status := GdipClonePen(GpPen *pen, GpPen **clonepen)
            Return status
        }
        
        ;####################################
        ; Call          ~Pen(GpPen *pen)
        ; Description   Releases resources used by the Pen object.
        ;          
        ; Params        GpPen *pen
        ;          
        ; Return        Status
        ;______________________________________
        ~Pen(GpPen *pen)
        {
            status := GdipDeletePen(GpPen *pen)
            Return status
        }
        
        ;####################################
        ; Call          SetWidth(GpPen *pen, REAL width)
        ; Description   Sets the width for this Pen object.
        ;          
        ; Params        GpPen *pen, REAL width
        ;          
        ; Return        Status
        ;______________________________________
        SetWidth(GpPen *pen, REAL width)
        {
            status := GdipSetPenWidth(GpPen *pen, REAL width)
            Return status
        }
        
        ;####################################
        ; Call          GetWidth(GpPen *pen, REAL *width)
        ; Description   Gets the width currently set for this Pen object.
        ;          
        ; Params        GpPen *pen, REAL *width
        ;          
        ; Return        Status
        ;______________________________________
        GetWidth(GpPen *pen, REAL *width)
        {
            status := GdipGetPenWidth(GpPen *pen, REAL *width)
            Return status
        }
        
        ;####################################
        ; Call          GdipSetPenUnit(GpPen *pen, GpUnit unit)
        ; Description   This function sets the unit of measure for the pen specified by the pen parameter to the value specified by the unit parameter. The unit parameter is a member of the Unit enumeration that specifies the unit of measure for the width of the pen.
        ;          
        ; Params        GpPen *pen, GpUnit unit
        ;          
        ; Return        Status
        ;______________________________________
        GdipSetPenUnit(GpPen *pen, GpUnit unit)
        {
            status := GdipSetPenUnit(GpPen *pen, GpUnit unit)
            Return status
        }
        
        ;####################################
        ; Call          GdipGetPenUnit(GpPen *pen, GpUnit *unit)
        ; Description   This function gets the unit of measure for the pen specified by the pen parameter. The unit parameter receives a member of the Unit enumeration that indicates the unit of measure for the width of the pen.
        ;          
        ; Params        GpPen *pen, GpUnit *unit
        ;          
        ; Return        Status
        ;______________________________________
        GdipGetPenUnit(GpPen *pen, GpUnit *unit)
        {
            status := GdipGetPenUnit(GpPen *pen, GpUnit *unit)
            Return status
        }
        
        ;####################################
        ; Call          SetLineCap(GpPen *pen, GpLineCap startCap, GpLineCap endCap, GpDashCap dashCap)
        ; Description   Sets the cap styles for the start, end, and dashes in a line drawn with this pen.
        ;          
        ; Params        GpPen *pen, GpLineCap startCap, GpLineCap endCap, GpDashCap dashCap
        ;          
        ; Return        Status
        ;______________________________________
        SetLineCap(GpPen *pen, GpLineCap startCap, GpLineCap endCap, GpDashCap dashCap)
        {
            status := GdipSetPenLineCap197819(GpPen *pen, GpLineCap startCap, GpLineCap endCap, GpDashCap dashCap)
            Return status
        }
        
        ;####################################
        ; Call          SetStartCap(GpPen *pen, GpLineCap startCap)
        ; Description   Sets the start cap for this Pen object.
        ;          
        ; Params        GpPen *pen, GpLineCap startCap
        ;          
        ; Return        Status
        ;______________________________________
        SetStartCap(GpPen *pen, GpLineCap startCap)
        {
            status := GdipSetPenStartCap(GpPen *pen, GpLineCap startCap)
            Return status
        }
        
        ;####################################
        ; Call          SetEndCap(GpPen *pen, GpLineCap endCap)
        ; Description   Sets the end cap for this Pen object.
        ;          
        ; Params        GpPen *pen, GpLineCap endCap
        ;          
        ; Return        Status
        ;______________________________________
        SetEndCap(GpPen *pen, GpLineCap endCap)
        {
            status := GdipSetPenEndCap(GpPen *pen, GpLineCap endCap)
            Return status
        }
        
        ;####################################
        ; Call          SetDashCap(GpPen *pen, GpDashCap dashCap)
        ; Description   Sets the dash cap style for this Pen object.
        ;          
        ; Params        GpPen *pen, GpDashCap dashCap
        ;          
        ; Return        Status
        ;______________________________________
        SetDashCap(GpPen *pen, GpDashCap dashCap)
        {
            status := GdipSetPenDashCap197819(GpPen *pen, GpDashCap dashCap)
            Return status
        }
        
        ;####################################
        ; Call          GetStartCap(GpPen *pen, GpLineCap *startCap)
        ; Description   Gets the start cap currently set for this Pen object.
        ;          
        ; Params        GpPen *pen, GpLineCap *startCap
        ;          
        ; Return        Status
        ;______________________________________
        GetStartCap(GpPen *pen, GpLineCap *startCap)
        {
            status := GdipGetPenStartCap(GpPen *pen, GpLineCap *startCap)
            Return status
        }
        
        ;####################################
        ; Call          GetEndCap(GpPen *pen, GpLineCap *endCap)
        ; Description   Gets the end cap currently set for this Pen object.
        ;          
        ; Params        GpPen *pen, GpLineCap *endCap
        ;          
        ; Return        Status
        ;______________________________________
        GetEndCap(GpPen *pen, GpLineCap *endCap)
        {
            status := GdipGetPenEndCap(GpPen *pen, GpLineCap *endCap)
            Return status
        }
        
        ;####################################
        ; Call          GetDashCap(GpPen *pen, GpDashCap *dashCap)
        ; Description   Gets the dash cap style currently set for this Pen object.
        ;          
        ; Params        GpPen *pen, GpDashCap *dashCap
        ;          
        ; Return        Status
        ;______________________________________
        GetDashCap(GpPen *pen, GpDashCap *dashCap)
        {
            status := GdipGetPenDashCap197819(GpPen *pen, GpDashCap *dashCap)
            Return status
        }
        
        ;####################################
        ; Call          SetLineJoin(GpPen *pen, GpLineJoin lineJoin)
        ; Description   Sets the line join for this Pen object.
        ;          
        ; Params        GpPen *pen, GpLineJoin lineJoin
        ;          
        ; Return        Status
        ;______________________________________
        SetLineJoin(GpPen *pen, GpLineJoin lineJoin)
        {
            status := GdipSetPenLineJoin(GpPen *pen, GpLineJoin lineJoin)
            Return status
        }
        
        ;####################################
        ; Call          GetLineJoin(GpPen *pen, GpLineJoin *lineJoin)
        ; Description   Gets the line join for this Pen object.
        ;          
        ; Params        GpPen *pen, GpLineJoin *lineJoin
        ;          
        ; Return        Status
        ;______________________________________
        GetLineJoin(GpPen *pen, GpLineJoin *lineJoin)
        {
            status := GdipGetPenLineJoin(GpPen *pen, GpLineJoin *lineJoin)
            Return status
        }
        
        ;####################################
        ; Call          SetCustomStartCap(GpPen *pen, GpCustomLineCap* customCap)
        ; Description   Sets the custom start cap for this Pen object.
        ;          
        ; Params        GpPen *pen, GpCustomLineCap* customCap
        ;          
        ; Return        Status
        ;______________________________________
        SetCustomStartCap(GpPen *pen, GpCustomLineCap* customCap)
        {
            status := GdipSetPenCustomStartCap(GpPen *pen, GpCustomLineCap* customCap)
            Return status
        }
        
        ;####################################
        ; Call          GetCustomStartCap(GpPen *pen, GpCustomLineCap** customCap)
        ; Description   Gets the custom start cap for this Pen object.
        ;          
        ; Params        GpPen *pen, GpCustomLineCap** customCap
        ;          
        ; Return        Status
        ;______________________________________
        GetCustomStartCap(GpPen *pen, GpCustomLineCap** customCap)
        {
            status := GdipGetPenCustomStartCap(GpPen *pen, GpCustomLineCap** customCap)
            Return status
        }
        
        ;####################################
        ; Call          SetCustomEndCap(GpPen *pen, GpCustomLineCap* customCap)
        ; Description   Sets the custom end cap currently set for this Pen object
        ;          
        ; Params        GpPen *pen, GpCustomLineCap* customCap
        ;          
        ; Return        Status
        ;______________________________________
        SetCustomEndCap(GpPen *pen, GpCustomLineCap* customCap)
        {
            status := GdipSetPenCustomEndCap(GpPen *pen, GpCustomLineCap* customCap)
            Return status
        }
        
        ;####################################
        ; Call          GetCustomEndCap(GpPen *pen, GpCustomLineCap** customCap)
        ; Description   Gets the custom end cap currently set for this Pen object
        ;          
        ; Params        GpPen *pen, GpCustomLineCap** customCap
        ;          
        ; Return        Status
        ;______________________________________
        GetCustomEndCap(GpPen *pen, GpCustomLineCap** customCap)
        {
            status := GdipGetPenCustomEndCap(GpPen *pen, GpCustomLineCap** customCap)
            Return status
        }
        
        ;####################################
        ; Call          SetMiterLimit(GpPen *pen, REAL miterLimit)
        ; Description   Sets the miter length currently set for this Pen object.
        ;          
        ; Params        GpPen *pen, REAL miterLimit
        ;          
        ; Return        Status
        ;______________________________________
        SetMiterLimit(GpPen *pen, REAL miterLimit)
        {
            status := GdipSetPenMiterLimit(GpPen *pen, REAL miterLimit)
            Return status
        }
        
        ;####################################
        ; Call          GetMiterLimit(GpPen *pen, REAL *miterLimit)
        ; Description   Gets the miter length currently set for this Pen object.
        ;          
        ; Params        GpPen *pen, REAL *miterLimit
        ;          
        ; Return        Status
        ;______________________________________
        GetMiterLimit(GpPen *pen, REAL *miterLimit)
        {
            status := GdipGetPenMiterLimit(GpPen *pen, REAL *miterLimit)
            Return status
        }
        
        ;####################################
        ; Call          SetAlignment(GpPen *pen, GpPenAlignment penMode)
        ; Description   Sets the alignment currently set for this Pen object.
        ;          
        ; Params        GpPen *pen, GpPenAlignment penMode
        ;          
        ; Return        Status
        ;______________________________________
        SetAlignment(GpPen *pen, GpPenAlignment penMode)
        {
            status := GdipSetPenMode(GpPen *pen, GpPenAlignment penMode)
            Return status
        }
        
        ;####################################
        ; Call          GetAlignment(GpPen *pen, GpPenAlignment *penMode)
        ; Description   Sets the alignment currently set for this Pen object.
        ;          
        ; Params        GpPen *pen, GpPenAlignment *penMode
        ;          
        ; Return        Status
        ;______________________________________
        GetAlignment(GpPen *pen, GpPenAlignment *penMode)
        {
            status := GdipGetPenMode(GpPen *pen, GpPenAlignment *penMode)
            Return status
        }
        
        ;####################################
        ; Call          SetTransform(GpPen *pen, GpMatrix *matrix)
        ; Description   Sets the world transformation matrix currently set for this Pen object.
        ;          
        ; Params        GpPen *pen, GpMatrix *matrix
        ;          
        ; Return        Status
        ;______________________________________
        SetTransform(GpPen *pen, GpMatrix *matrix)
        {
            status := GdipSetPenTransform(GpPen *pen, GpMatrix *matrix)
            Return status
        }
        
        ;####################################
        ; Call          GetTransform(GpPen *pen, GpMatrix *matrix)
        ; Description   Gets the world transformation matrix currently set for this Pen object.
        ;          
        ; Params        GpPen *pen, GpMatrix *matrix
        ;          
        ; Return        Status
        ;______________________________________
        GetTransform(GpPen *pen, GpMatrix *matrix)
        {
            status := GdipGetPenTransform(GpPen *pen, GpMatrix *matrix)
            Return status
        }
        
        ;####################################
        ; Call          ResetTransform(GpPen *pen)
        ; Description   Sets the world transformation matrix of this Pen object to the identity matrix.
        ;          
        ; Params        GpPen *pen
        ;          
        ; Return        Status
        ;______________________________________
        ResetTransform(GpPen *pen)
        {
            status := GdipResetPenTransform(GpPen *pen)
            Return status
        }
        
        ;####################################
        ; Call          GdipTranslatePenTransform(GpPen *pen, REAL dx, REAL dy, GpMatrixOrder order)
        ; Description   No description given.
        ;          
        ; Params        GpPen *pen, REAL dx, REAL dy, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        GdipTranslatePenTransform(GpPen *pen, REAL dx, REAL dy, GpMatrixOrder order)
        {
            status := GdipTranslatePenTransform(GpPen *pen, REAL dx, REAL dy, GpMatrixOrder order)
            Return status
        }
        
        ;####################################
        ; Call          ScaleTransform(GpPen *pen, REAL sx, REAL sy, GpMatrixOrder order)
        ; Description   Sets the Pen object's world transformation matrix equal to the product of itself and a scaling matrix.
        ;          
        ; Params        GpPen *pen, REAL sx, REAL sy, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        ScaleTransform(GpPen *pen, REAL sx, REAL sy, GpMatrixOrder order)
        {
            status := GdipScalePenTransform(GpPen *pen, REAL sx, REAL sy, GpMatrixOrder order)
            Return status
        }
        
        ;####################################
        ; Call          RotateTransform(GpPen *pen, REAL angle, GpMatrixOrder order)
        ; Description   Updates the world transformation matrix of this Pen object with the product of itself and a rotation matrix.
        ;          
        ; Params        GpPen *pen, REAL angle, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        RotateTransform(GpPen *pen, REAL angle, GpMatrixOrder order)
        {
            status := GdipRotatePenTransform(GpPen *pen, REAL angle, GpMatrixOrder order)
            Return status
        }
        
        ;####################################
        ; Call          SetColor(GpPen *pen, ARGB argb)
        ; Description   Sets the color for this Pen object.
        ;          
        ; Params        GpPen *pen, ARGB argb
        ;          
        ; Return        Status
        ;______________________________________
        SetColor(GpPen *pen, ARGB argb)
        {
            status := GdipSetPenColor(GpPen *pen, ARGB argb)
            Return status
        }
        
        ;####################################
        ; Call          GetColor(GpPen *pen, ARGB *argb)
        ; Description   Gets the color for this Pen object.
        ;          
        ; Params        GpPen *pen, ARGB *argb
        ;          
        ; Return        Status
        ;______________________________________
        GetColor(GpPen *pen, ARGB *argb)
        {
            status := GdipGetPenColor(GpPen *pen, ARGB *argb)
            Return status
        }
        
        ;####################################
        ; Call          SetBrush(GpPen *pen, GpBrush *brush)
        ; Description   Sets the Brush object that a pen uses to fill a line.
        ;          
        ; Params        GpPen *pen, GpBrush *brush
        ;          
        ; Return        Status
        ;______________________________________
        SetBrush(GpPen *pen, GpBrush *brush)
        {
            status := GdipSetPenBrushFill(GpPen *pen, GpBrush *brush)
            Return status
        }
        
        ;####################################
        ; Call          GetBrush(GpPen *pen, GpBrush **brush)
        ; Description   Gets the Brush object that a pen uses to fill a line.
        ;          
        ; Params        GpPen *pen, GpBrush **brush
        ;          
        ; Return        Status
        ;______________________________________
        GetBrush(GpPen *pen, GpBrush **brush)
        {
            status := GdipGetPenBrushFill(GpPen *pen, GpBrush **brush)
            Return status
        }
        
        ;####################################
        ; Call          GetPenType(GpPen *pen, GpPenType* type)
        ; Description   Gets the type currently set for this Pen object.
        ;          
        ; Params        GpPen *pen, GpPenType* type
        ;          
        ; Return        Status
        ;______________________________________
        GetPenType(GpPen *pen, GpPenType* type)
        {
            status := GdipGetPenFillType(GpPen *pen, GpPenType* type)
            Return status
        }
        
        ;####################################
        ; Call          GetDashStyle(GpPen *pen, GpDashStyle *dashstyle)
        ; Description   Gets the dash style currently set for this Pen object.
        ;          
        ; Params        GpPen *pen, GpDashStyle *dashstyle
        ;          
        ; Return        Status
        ;______________________________________
        GetDashStyle(GpPen *pen, GpDashStyle *dashstyle)
        {
            status := GdipGetPenDashStyle(GpPen *pen, GpDashStyle *dashstyle)
            Return status
        }
        
        ;####################################
        ; Call          SetDashStyle(GpPen *pen, GpDashStyle dashstyle)
        ; Description   Sets the dash style currently set for this Pen object.
        ;          
        ; Params        GpPen *pen, GpDashStyle dashstyle
        ;          
        ; Return        Status
        ;______________________________________
        SetDashStyle(GpPen *pen, GpDashStyle dashstyle)
        {
            status := GdipSetPenDashStyle(GpPen *pen, GpDashStyle dashstyle)
            Return status
        }
        
        ;####################################
        ; Call          GetDashOffset(GpPen *pen, REAL *offset)
        ; Description   Gets the distance from the start of the line to the start of the first space in a dashed line.
        ;          
        ; Params        GpPen *pen, REAL *offset
        ;          
        ; Return        Status
        ;______________________________________
        GetDashOffset(GpPen *pen, REAL *offset)
        {
            status := GdipGetPenDashOffset(GpPen *pen, REAL *offset)
            Return status
        }
        
        ;####################################
        ; Call          SetDashOffset(GpPen *pen, REAL offset)
        ; Description   Sets the distance from the start of the line to the start of the first space in a dashed line.
        ;          
        ; Params        GpPen *pen, REAL offset
        ;          
        ; Return        Status
        ;______________________________________
        SetDashOffset(GpPen *pen, REAL offset)
        {
            status := GdipSetPenDashOffset(GpPen *pen, REAL offset)
            Return status
        }
        
        ;####################################
        ; Call          GetDashPatternCount(GpPen *pen, INT *count)
        ; Description   Gets the number of elements in a dash pattern array.
        ;          
        ; Params        GpPen *pen, INT *count
        ;          
        ; Return        Status
        ;______________________________________
        GetDashPatternCount(GpPen *pen, INT *count)
        {
            status := GdipGetPenDashCount(GpPen *pen, INT *count)
            Return status
        }
        
        ;####################################
        ; Call          SetDashPattern(GpPen *pen, GDIPCONST REAL *dash, INT count)
        ; Description   Sets an array of custom dashes and spaces currently set for this Pen object.
        ;          
        ; Params        GpPen *pen, GDIPCONST REAL *dash, INT count
        ;          
        ; Return        Status
        ;______________________________________
        SetDashPattern(GpPen *pen, GDIPCONST REAL *dash, INT count)
        {
            status := GdipSetPenDashArray(GpPen *pen, GDIPCONST REAL *dash, INT count)
            Return status
        }
        
        ;####################################
        ; Call          GetDashPattern(GpPen *pen, REAL *dash, INT count)
        ; Description   Gets an array of custom dashes and spaces currently set for this Pen object.
        ;          
        ; Params        GpPen *pen, REAL *dash, INT count
        ;          
        ; Return        Status
        ;______________________________________
        GetDashPattern(GpPen *pen, REAL *dash, INT count)
        {
            status := GdipGetPenDashArray(GpPen *pen, REAL *dash, INT count)
            Return status
        }
        
        ;####################################
        ; Call          GetCompoundArrayCount(GpPen *pen, INT *count)
        ; Description   Gets the number of elements in a compound array.
        ;          
        ; Params        GpPen *pen, INT *count
        ;          
        ; Return        Status
        ;______________________________________
        GetCompoundArrayCount(GpPen *pen, INT *count)
        {
            status := GdipGetPenCompoundCount(GpPen *pen, INT *count)
            Return status
        }
        
        ;####################################
        ; Call          SetCompoundArray(GpPen *pen, GDIPCONST REAL *dash, INT count)
        ; Description   Sets the compound array currently set for this Pen object.
        ;          
        ; Params        GpPen *pen, GDIPCONST REAL *dash, INT count
        ;          
        ; Return        Status
        ;______________________________________
        SetCompoundArray(GpPen *pen, GDIPCONST REAL *dash, INT count)
        {
            status := GdipSetPenCompoundArray(GpPen *pen, GDIPCONST REAL *dash, INT count)
            Return status
        }
        
        ;####################################
        ; Call          GetCompoundArray(GpPen *pen, REAL *dash, INT count)
        ; Description   Gets the compound array currently set for this Pen object.
        ;          
        ; Params        GpPen *pen, REAL *dash, INT count
        ;          
        ; Return        Status
        ;______________________________________
        GetCompoundArray(GpPen *pen, REAL *dash, INT count)
        {
            status := GdipGetPenCompoundArray(GpPen *pen, REAL *dash, INT count)
            Return status
        }
    }
    
    Class  Region
    {
        ;####################################
        ; Call          Region(GpRegion **region)
        ; Description   Creates a region that is infinite. This is the default constructor.
        ;          
        ; Params        GpRegion **region
        ;          
        ; Return        Status
        ;______________________________________
        Region(GpRegion **region)
        {
            status := GdipCreateRegion(GpRegion **region)
            Return status
        }
        
        ;####################################
        ; Call          Region(GDIPCONST GpRectF *rect, GpRegion **region)
        ; Description   Creates a region that is defined by a rectangle.
        ;          
        ; Params        GDIPCONST GpRectF *rect, GpRegion **region
        ;          
        ; Return        Status
        ;______________________________________
        Region(GDIPCONST GpRectF *rect, GpRegion **region)
        {
            status := GdipCreateRegionRect(GDIPCONST GpRectF *rect, GpRegion **region)
            Return status
        }
        
        ;####################################
        ; Call          Region(GDIPCONST GpRect *rect, GpRegion **region)
        ; Description   Creates a region that is defined by a rectangle.
        ;          
        ; Params        GDIPCONST GpRect *rect, GpRegion **region
        ;          
        ; Return        Status
        ;______________________________________
        Region(GDIPCONST GpRect *rect, GpRegion **region)
        {
            status := GdipCreateRegionRectI(GDIPCONST GpRect *rect, GpRegion **region)
            Return status
        }
        
        ;####################################
        ; Call          Region(GpPath *path, GpRegion **region)
        ; Description   Creates a region that is defined by a GraphicsPath object and has a fill mode that is contained in the GraphicsPath object.
        ;          
        ; Params        GpPath *path, GpRegion **region
        ;          
        ; Return        Status
        ;______________________________________
        Region(GpPath *path, GpRegion **region)
        {
            status := GdipCreateRegionPath(GpPath *path, GpRegion **region)
            Return status
        }
        
        ;####################################
        ; Call          Region(GDIPCONST BYTE *regionData, INT size, GpRegion **region)
        ; Description   Creates a region that is defined by data obtained from another region.
        ;          
        ; Params        GDIPCONST BYTE *regionData, INT size, GpRegion **region
        ;          
        ; Return        Status
        ;______________________________________
        Region(GDIPCONST BYTE *regionData, INT size, GpRegion **region)
        {
            status := GdipCreateRegionRgnData(GDIPCONST BYTE *regionData, INT size, GpRegion **region)
            Return status
        }
        
        ;####################################
        ; Call          Region(HRGN hRgn, GpRegion **region)
        ; Description   Creates a region that is identical to the region that is specified by a handle to a GDI region.
        ;          
        ; Params        HRGN hRgn, GpRegion **region
        ;          
        ; Return        Status
        ;______________________________________
        Region(HRGN hRgn, GpRegion **region)
        {
            status := GdipCreateRegionHrgn(HRGN hRgn, GpRegion **region)
            Return status
        }
        
        ;####################################
        ; Call          Clone(GpRegion *region, GpRegion **cloneRegion)
        ; Description   Makes a copy of this Region object and returns the address of the new Region object.
        ;          
        ; Params        GpRegion *region, GpRegion **cloneRegion
        ;          
        ; Return        Status
        ;______________________________________
        Clone(GpRegion *region, GpRegion **cloneRegion)
        {
            status := GdipCloneRegion(GpRegion *region, GpRegion **cloneRegion)
            Return status
        }
        
        ;####################################
        ; Call          ~Region(GpRegion *region)
        ; Description   Releases resources used by the Region object.
        ;          
        ; Params        GpRegion *region
        ;          
        ; Return        Status
        ;______________________________________
        ~Region(GpRegion *region)
        {
            status := GdipDeleteRegion(GpRegion *region)
            Return status
        }
        
        ;####################################
        ; Call          MakeInfinite(GpRegion *region)
        ; Description   Updates this region to an infinite region.
        ;          
        ; Params        GpRegion *region
        ;          
        ; Return        Status
        ;______________________________________
        MakeInfinite(GpRegion *region)
        {
            status := GdipSetInfinite(GpRegion *region)
            Return status
        }
        
        ;####################################
        ; Call          MakeEmpty(GpRegion *region)
        ; Description   Updates this region to an empty region. In other words, the region occupies no space on the display device.
        ;          
        ; Params        GpRegion *region
        ;          
        ; Return        Status
        ;______________________________________
        MakeEmpty(GpRegion *region)
        {
            status := GdipSetEmpty(GpRegion *region)
            Return status
        }
        
        ;####################################
        ; Call          Intersect(GpRegion *region, GDIPCONST GpRectF *rect, CombineMode combineMode)
        ; Description   Updates this region to the portion of itself that intersects the specified rectangle's interior.\nThe combineMode parameter in the flat function is a member of the CombineMode enumeration that specifies how the region and rectangle are combined.
        ;          
        ; Params        GpRegion *region, GDIPCONST GpRectF *rect, CombineMode combineMode
        ;          
        ; Return        Status
        ;______________________________________
        Intersect(GpRegion *region, GDIPCONST GpRectF *rect, CombineMode combineMode)
        {
            status := GdipCombineRegionRect(GpRegion *region, GDIPCONST GpRectF *rect, CombineMode combineMode)
            Return status
        }
        
        ;####################################
        ; Call          Intersect(GpRegion *region, GDIPCONST GpRect *rect, CombineMode combineMode)
        ; Description   Updates this region to the portion of itself that intersects the specified rectangle's interior.\nThe combineMode parameter in the flat function is a member of the CombineMode enumeration that specifies how the region and rectangle are combined.
        ;          
        ; Params        GpRegion *region, GDIPCONST GpRect *rect, CombineMode combineMode
        ;          
        ; Return        Status
        ;______________________________________
        Intersect(GpRegion *region, GDIPCONST GpRect *rect, CombineMode combineMode)
        {
            status := GdipCombineRegionRectI(GpRegion *region, GDIPCONST GpRect *rect, CombineMode combineMode)
            Return status
        }
        
        ;####################################
        ; Call          Intersect(GpRegion *region, GpPath *path, CombineMode combineMode)
        ; Description   Updates this region to the portion of itself that intersects the specified path's interior.\nThe combineMode parameter in the flat function is a member of the CombineMode enumeration that specifies how the region and path are combined.
        ;          
        ; Params        GpRegion *region, GpPath *path, CombineMode combineMode
        ;          
        ; Return        Status
        ;______________________________________
        Intersect(GpRegion *region, GpPath *path, CombineMode combineMode)
        {
            status := GdipCombineRegionPath(GpRegion *region, GpPath *path, CombineMode combineMode)
            Return status
        }
        
        ;####################################
        ; Call          Intersect(GpRegion *region, GpRegion *region2, CombineMode combineMode)
        ; Description   Updates this region to the portion of itself that intersects another region.\nThe combineMode parameter in the flat function is a member of the CombineMode enumeration that specifies how the regions are combined.
        ;          
        ; Params        GpRegion *region, GpRegion *region2, CombineMode combineMode
        ;          
        ; Return        Status
        ;______________________________________
        Intersect(GpRegion *region, GpRegion *region2, CombineMode combineMode)
        {
            status := GdipCombineRegionRegion(GpRegion *region, GpRegion *region2, CombineMode combineMode)
            Return status
        }
        
        ;####################################
        ; Call          Translate(GpRegion *region, REAL dx, REAL dy)
        ; Description   Offsets this region by specified amounts in the horizontal and vertical directions.
        ;          
        ; Params        GpRegion *region, REAL dx, REAL dy
        ;          
        ; Return        Status
        ;______________________________________
        Translate(GpRegion *region, REAL dx, REAL dy)
        {
            status := GdipTranslateRegion(GpRegion *region, REAL dx, REAL dy)
            Return status
        }
        
        ;####################################
        ; Call          Translate(GpRegion *region, INT dx, INT dy)
        ; Description   Offsets this region by specified amounts in the horizontal and vertical directions.
        ;          
        ; Params        GpRegion *region, INT dx, INT dy
        ;          
        ; Return        Status
        ;______________________________________
        Translate(GpRegion *region, INT dx, INT dy)
        {
            status := GdipTranslateRegionI(GpRegion *region, INT dx, INT dy)
            Return status
        }
        
        ;####################################
        ; Call          Transform(GpRegion *region, GpMatrix *matrix)
        ; Description   Transforms this region by multiplying each of its data points by a specified matrix.
        ;          
        ; Params        GpRegion *region, GpMatrix *matrix
        ;          
        ; Return        Status
        ;______________________________________
        Transform(GpRegion *region, GpMatrix *matrix)
        {
            status := GdipTransformRegion(GpRegion *region, GpMatrix *matrix)
            Return status
        }
        
        ;####################################
        ; Call          GetBounds(GpRegion *region, GpGraphics *graphics, GpRectF *rect)
        ; Description   Gets a rectangle that encloses this region.
        ;          
        ; Params        GpRegion *region, GpGraphics *graphics, GpRectF *rect
        ;          
        ; Return        Status
        ;______________________________________
        GetBounds(GpRegion *region, GpGraphics *graphics, GpRectF *rect)
        {
            status := GdipGetRegionBounds(GpRegion *region, GpGraphics *graphics, GpRectF *rect)
            Return status
        }
        
        ;####################################
        ; Call          GetBounds(GpRegion *region, GpGraphics *graphics, GpRect *rect)
        ; Description   Gets a rectangle that encloses this region.
        ;          
        ; Params        GpRegion *region, GpGraphics *graphics, GpRect *rect
        ;          
        ; Return        Status
        ;______________________________________
        GetBounds(GpRegion *region, GpGraphics *graphics, GpRect *rect)
        {
            status := GdipGetRegionBoundsI(GpRegion *region, GpGraphics *graphics, GpRect *rect)
            Return status
        }
        
        ;####################################
        ; Call          GetHRGN(GpRegion *region, GpGraphics *graphics, HRGN *hRgn)
        ; Description   Creates a GDI region from this region.
        ;          
        ; Params        GpRegion *region, GpGraphics *graphics, HRGN *hRgn
        ;          
        ; Return        Status
        ;______________________________________
        GetHRGN(GpRegion *region, GpGraphics *graphics, HRGN *hRgn)
        {
            status := GdipGetRegionHRgn(GpRegion *region, GpGraphics *graphics, HRGN *hRgn)
            Return status
        }
        
        ;####################################
        ; Call          IsEmpty(GpRegion *region, GpGraphics *graphics, BOOL *result)
        ; Description   Determines whether this region is empty.
        ;          
        ; Params        GpRegion *region, GpGraphics *graphics, BOOL *result
        ;          
        ; Return        Status
        ;______________________________________
        IsEmpty(GpRegion *region, GpGraphics *graphics, BOOL *result)
        {
            status := GdipIsEmptyRegion(GpRegion *region, GpGraphics *graphics, BOOL *result)
            Return status
        }
        
        ;####################################
        ; Call          IsInfinite(GpRegion *region, GpGraphics *graphics, BOOL *result)
        ; Description   Determines whether this region is infinite.
        ;          
        ; Params        GpRegion *region, GpGraphics *graphics, BOOL *result
        ;          
        ; Return        Status
        ;______________________________________
        IsInfinite(GpRegion *region, GpGraphics *graphics, BOOL *result)
        {
            status := GdipIsInfiniteRegion(GpRegion *region, GpGraphics *graphics, BOOL *result)
            Return status
        }
        
        ;####################################
        ; Call          Equals(GpRegion *region, GpRegion *region2, GpGraphics *graphics, BOOL *result)
        ; Description   Determines whether this region is equal to a specified region.
        ;          
        ; Params        GpRegion *region, GpRegion *region2, GpGraphics *graphics, BOOL *result
        ;          
        ; Return        Status
        ;______________________________________
        Equals(GpRegion *region, GpRegion *region2, GpGraphics *graphics, BOOL *result)
        {
            status := GdipIsEqualRegion(GpRegion *region, GpRegion *region2, GpGraphics *graphics, BOOL *result)
            Return status
        }
        
        ;####################################
        ; Call          GetDataSize(GpRegion *region, UINT * bufferSize)
        ; Description   Gets the number of bytes of data that describes this region.
        ;          
        ; Params        GpRegion *region, UINT * bufferSize
        ;          
        ; Return        Status
        ;______________________________________
        GetDataSize(GpRegion *region, UINT * bufferSize)
        {
            status := GdipGetRegionDataSize(GpRegion *region, UINT * bufferSize)
            Return status
        }
        
        ;####################################
        ; Call          GetData(GpRegion *region, BYTE * buffer, UINT bufferSize, UINT * sizeFilled)
        ; Description   Gets data that describes this region.
        ;          
        ; Params        GpRegion *region, BYTE * buffer, UINT bufferSize, UINT * sizeFilled
        ;          
        ; Return        Status
        ;______________________________________
        GetData(GpRegion *region, BYTE * buffer, UINT bufferSize, UINT * sizeFilled)
        {
            status := GdipGetRegionData(GpRegion *region, BYTE * buffer, UINT bufferSize, UINT * sizeFilled)
            Return status
        }
        
        ;####################################
        ; Call          IsVisible(GpRegion *region, REAL x, REAL y, GpGraphics *graphics, BOOL *result)
        ; Description   Determines whether a point is inside this region.\nThe x and y parameters in the flat function specify the x and y coordinates of a point that corresponds to the point parameter in the wrapper method.
        ;          
        ; Params        GpRegion *region, REAL x, REAL y, GpGraphics *graphics, BOOL *result
        ;          
        ; Return        Status
        ;______________________________________
        IsVisible(GpRegion *region, REAL x, REAL y, GpGraphics *graphics, BOOL *result)
        {
            status := GdipIsVisibleRegionPoint(GpRegion *region, REAL x, REAL y, GpGraphics *graphics, BOOL *result)
            Return status
        }
        
        ;####################################
        ; Call          IsVisible(GpRegion *region, INT x, INT y, GpGraphics *graphics, BOOL *result)
        ; Description   Determines whether a point is inside this region.\nThe x and y parameters in the flat function specify the x and y coordinates of a point that corresponds to the point parameter in the wrapper method.
        ;          
        ; Params        GpRegion *region, INT x, INT y, GpGraphics *graphics, BOOL *result
        ;          
        ; Return        Status
        ;______________________________________
        IsVisible(GpRegion *region, INT x, INT y, GpGraphics *graphics, BOOL *result)
        {
            status := GdipIsVisibleRegionPointI(GpRegion *region, INT x, INT y, GpGraphics *graphics, BOOL *result)
            Return status
        }
        
        ;####################################
        ; Call          IsVisible(GpRegion *region, REAL x, REAL y, REAL width, REAL height, GpGraphics *graphics, BOOL *result)
        ; Description   Determines whether a rectangle intersects this region.\nThe x, y, width, and height parameters in the flat function specify a rectangle that corresponds to the rect parameter in the wrapper method.
        ;          
        ; Params        GpRegion *region, REAL x, REAL y, REAL width, REAL height, GpGraphics *graphics, BOOL *result
        ;          
        ; Return        Status
        ;______________________________________
        IsVisible(GpRegion *region, REAL x, REAL y, REAL width, REAL height, GpGraphics *graphics, BOOL *result)
        {
            status := GdipIsVisibleRegionRect(GpRegion *region, REAL x, REAL y, REAL width, REAL height, GpGraphics *graphics, BOOL *result)
            Return status
        }
        
        ;####################################
        ; Call          IsVisible(GpRegion *region, INT x, INT y, INT width, INT height, GpGraphics *graphics, BOOL *result)
        ; Description   Determines whether a rectangle intersects this region.\nThe x, y, width, and height parameters in the flat function specify a rectangle that corresponds to the rect parameter in the wrapper method.
        ;          
        ; Params        GpRegion *region, INT x, INT y, INT width, INT height, GpGraphics *graphics, BOOL *result
        ;          
        ; Return        Status
        ;______________________________________
        IsVisible(GpRegion *region, INT x, INT y, INT width, INT height, GpGraphics *graphics, BOOL *result)
        {
            status := GdipIsVisibleRegionRectI(GpRegion *region, INT x, INT y, INT width, INT height, GpGraphics *graphics, BOOL *result)
            Return status
        }
        
        ;####################################
        ; Call          GetRegionScansCount(GpRegion *region, UINT* count, GpMatrix* matrix)
        ; Description   Gets the number of rectangles that approximate this region. The region is transformed by a specified matrix before the rectangles are calculated.
        ;          
        ; Params        GpRegion *region, UINT* count, GpMatrix* matrix
        ;          
        ; Return        Status
        ;______________________________________
        GetRegionScansCount(GpRegion *region, UINT* count, GpMatrix* matrix)
        {
            status := GdipGetRegionScansCount(GpRegion *region, UINT* count, GpMatrix* matrix)
            Return status
        }
        
        ;####################################
        ; Call          GetRegionScans(GpRegion *region, GpRectF* rects, INT* count, GpMatrix* matrix)
        ; Description   Gets an array of rectangles that approximate this region. The region is transformed by a specified matrix before the rectangles are calculated.
        ;          
        ; Params        GpRegion *region, GpRectF* rects, INT* count, GpMatrix* matrix
        ;          
        ; Return        Status
        ;______________________________________
        GetRegionScans(GpRegion *region, GpRectF* rects, INT* count, GpMatrix* matrix)
        {
            status := GdipGetRegionScans(GpRegion *region, GpRectF* rects, INT* count, GpMatrix* matrix)
            Return status
        }
        
        ;####################################
        ; Call          GetRegionScans(GpRegion *region, GpRect* rects, INT* count, GpMatrix* matrix)
        ; Description   Gets an array of rectangles that approximate this region. The region is transformed by a specified matrix before the rectangles are calculated.
        ;          
        ; Params        GpRegion *region, GpRect* rects, INT* count, GpMatrix* matrix
        ;          
        ; Return        Status
        ;______________________________________
        GetRegionScans(GpRegion *region, GpRect* rects, INT* count, GpMatrix* matrix)
        {
            status := GdipGetRegionScansI(GpRegion *region, GpRect* rects, INT* count, GpMatrix* matrix)
            Return status
        }
    }
    
    Class SolidBrush
    {
        ;####################################
        ; Call          SolidBrush(ARGB color, GpSolidFill **brush)
        ; Description   Creates a SolidBrush object based on a color
        ;          
        ; Params        ARGB color, GpSolidFill **brush
        ;          
        ; Return        Status
        ;______________________________________
        SolidBrush(ARGB color, GpSolidFill **brush)
        {
            status := GdipCreateSolidFill(ARGB color, GpSolidFill **brush)
            Return status
        }
        
        ;####################################
        ; Call          SetColor(GpSolidFill *brush, ARGB color)
        ; Description   Sets the color of this solid brush
        ;          
        ; Params        GpSolidFill *brush, ARGB color
        ;          
        ; Return        Status
        ;______________________________________
        SetColor(GpSolidFill *brush, ARGB color)
        {
            status := GdipSetSolidFillColor(GpSolidFill *brush, ARGB color)
            Return status
        }
        
        ;####################################
        ; Call          GetColor(GpSolidFill *brush, ARGB *color)
        ; Description   Gets the color of this solid brush
        ;          
        ; Params        GpSolidFill *brush, ARGB *color
        ;          
        ; Return        Status
        ;______________________________________
        GetColor(GpSolidFill *brush, ARGB *color)
        {
            status := GdipGetSolidFillColor(GpSolidFill *brush, ARGB *color)
            Return status
        }
        
    }
    
    Class StringFormat
    {
        ;####################################
        ; Call          StringFormat( INT formatAttributes, LANGID language, GpStringFormat **format )
        ; Description   Creates a StringFormat object based on string format flags and a language.
        ;          
        ; Params        INT formatAttributes, LANGID language, GpStringFormat **format 
        ;          
        ; Return        Status
        ;______________________________________
        StringFormat( INT formatAttributes, LANGID language, GpStringFormat **format )
        {
            status := GdipCreateStringFormat( INT formatAttributes, LANGID language, GpStringFormat **format )
            Return status
        }
        
        ;####################################
        ; Call          GenericDefault(GpStringFormat **format)
        ; Description   Creates a generic, default StringFormat object.
        ;          
        ; Params        GpStringFormat **format
        ;          
        ; Return        Status
        ;______________________________________
        GenericDefault(GpStringFormat **format)
        {
            status := GdipStringFormatGetGenericDefault(GpStringFormat **format)
            Return status
        }
        
        ;####################################
        ; Call          GenericTypographic(GpStringFormat **format)
        ; Description   Creates a generic, typographic StringFormat object.
        ;          
        ; Params        GpStringFormat **format
        ;          
        ; Return        Status
        ;______________________________________
        GenericTypographic(GpStringFormat **format)
        {
            status := GdipStringFormatGetGenericTypographic(GpStringFormat **format)
            Return status
        }
        
        ;####################################
        ; Call          ~StringFormat(GpStringFormat *format)
        ; Description   Releases resources used by the StringFormat object.
        ;          
        ; Params        GpStringFormat *format
        ;          
        ; Return        Status
        ;______________________________________
        ~StringFormat(GpStringFormat *format)
        {
            status := GdipDeleteStringFormat(GpStringFormat *format)
            Return status
        }
        
        ;####################################
        ; Call          StringFormat(GDIPCONST GpStringFormat *format, GpStringFormat **newFormat)
        ; Description   Creates a StringFormat object from another StringFormat object.
        ;          
        ; Params        GDIPCONST GpStringFormat *format, GpStringFormat **newFormat
        ;          
        ; Return        Status
        ;______________________________________
        StringFormat(GDIPCONST GpStringFormat *format, GpStringFormat **newFormat)
        {
            status := GdipCloneStringFormat(GDIPCONST GpStringFormat *format, GpStringFormat **newFormat)
            Return status
        }
        
        ;####################################
        ; Call          SetFormatFlags(GpStringFormat *format, INT flags)
        ; Description   Sets the format flags for this StringFormat object. The format flags determine most of the characteristics of a StringFormat object.
        ;          
        ; Params        GpStringFormat *format, INT flags
        ;          
        ; Return        Status
        ;______________________________________
        SetFormatFlags(GpStringFormat *format, INT flags)
        {
            status := GdipSetStringFormatFlags(GpStringFormat *format, INT flags)
            Return status
        }
        
        ;####################################
        ; Call          GetFormatFlags(GDIPCONST GpStringFormat *format, INT *flags)
        ; Description   Gets the string format flags for this StringFormat object.
        ;          
        ; Params        GDIPCONST GpStringFormat *format, INT *flags
        ;          
        ; Return        Status
        ;______________________________________
        GetFormatFlags(GDIPCONST GpStringFormat *format, INT *flags)
        {
            status := GdipGetStringFormatFlags(GDIPCONST GpStringFormat *format, INT *flags)
            Return status
        }
        
        ;####################################
        ; Call          SetAlignment(GpStringFormat *format, StringAlignment align)
        ; Description   Sets the line alignment of this StringFormat object in relation to the origin of the layout rectangle. The line alignment setting specifies how to align the string vertically in the layout rectangle. The layout rectangle is used to position the displayed string.
        ;          
        ; Params        GpStringFormat *format, StringAlignment align
        ;          
        ; Return        Status
        ;______________________________________
        SetAlignment(GpStringFormat *format, StringAlignment align)
        {
            status := GdipSetStringFormatAlign(GpStringFormat *format, StringAlignment align)
            Return status
        }
        
        ;####################################
        ; Call          GetAlignment(GDIPCONST GpStringFormat *format, StringAlignment *align)
        ; Description   Gets an element of the StringAlignment enumeration that indicates the character alignment of this StringFormat object in relation to the origin of the layout rectangle. A layout rectangle is used to position the displayed string.
        ;          
        ; Params        GDIPCONST GpStringFormat *format, StringAlignment *align
        ;          
        ; Return        Status
        ;______________________________________
        GetAlignment(GDIPCONST GpStringFormat *format, StringAlignment *align)
        {
            status := GdipGetStringFormatAlign(GDIPCONST GpStringFormat *format, StringAlignment *align)
            Return status
        }
        
        ;####################################
        ; Call          SetLineAlignment(GpStringFormat *format, StringAlignment align)
        ; Description   Sets the line alignment of this StringFormat object in relation to the origin of the layout rectangle. The line alignment setting specifies how to align the string vertically in the layout rectangle. The layout rectangle is used to position the displayed string.
        ;          
        ; Params        GpStringFormat *format, StringAlignment align
        ;          
        ; Return        Status
        ;______________________________________
        SetLineAlignment(GpStringFormat *format, StringAlignment align)
        {
            status := GdipSetStringFormatLineAlign(GpStringFormat *format, StringAlignment align)
            Return status
        }
        
        ;####################################
        ; Call          GetLineAlignment(GDIPCONST GpStringFormat *format, StringAlignment *align)
        ; Description   Gets an element of the StringAlignment enumeration that indicates the line alignment of this StringFormat object in relation to the origin of the layout rectangle. The line alignment setting specifies how to align the string vertically in the layout rectangle. The layout rectangle is used to position the displayed string.
        ;          
        ; Params        GDIPCONST GpStringFormat *format, StringAlignment *align
        ;          
        ; Return        Status
        ;______________________________________
        GetLineAlignment(GDIPCONST GpStringFormat *format, StringAlignment *align)
        {
            status := GdipGetStringFormatLineAlign(GDIPCONST GpStringFormat *format, StringAlignment *align)
            Return status
        }
        
        ;####################################
        ; Call          SetTrimming( GpStringFormat *format, StringTrimming trimming )
        ; Description   Sets the trimming style for this StringFormat object. The trimming style determines how to trim a string so that it fits into the layout rectangle.
        ;          
        ; Params        GpStringFormat *format, StringTrimming trimming 
        ;          
        ; Return        Status
        ;______________________________________
        SetTrimming( GpStringFormat *format, StringTrimming trimming )
        {
            status := GdipSetStringFormatTrimming( GpStringFormat *format, StringTrimming trimming )
            Return status
        }
        
        ;####################################
        ; Call          GetTrimming( GDIPCONST GpStringFormat *format, StringTrimming *trimming )
        ; Description   Gets an element of the StringTrimming enumeration that indicates the trimming style of this StringFormat object. The trimming style determines how to trim characters from a string that is too large to fit in the layout rectangle.
        ;          
        ; Params        GDIPCONST GpStringFormat *format, StringTrimming *trimming 
        ;          
        ; Return        Status
        ;______________________________________
        GetTrimming( GDIPCONST GpStringFormat *format, StringTrimming *trimming )
        {
            status := GdipGetStringFormatTrimming( GDIPCONST GpStringFormat *format, StringTrimming *trimming )
            Return status
        }
        
        ;####################################
        ; Call          SetHotkeyPrefix(GpStringFormat *format, INT hotkeyPrefix)
        ; Description   Sets the type of processing that is performed on a string when the hot key prefix, an ampersand (&), is encountered. The ampersand is called the hot key prefix and can be used to designate certain keys as hot keys.
        ;          
        ; Params        GpStringFormat *format, INT hotkeyPrefix
        ;          
        ; Return        Status
        ;______________________________________
        SetHotkeyPrefix(GpStringFormat *format, INT hotkeyPrefix)
        {
            status := GdipSetStringFormatHotkeyPrefix(GpStringFormat *format, INT hotkeyPrefix)
            Return status
        }
        
        ;####################################
        ; Call          GetHotkeyPrefix(GDIPCONST GpStringFormat *format, INT *hotkeyPrefix)
        ; Description   Gets an element of the HotkeyPrefix enumeration that indicates the type of processing that is performed on a string when a hot key prefix, an ampersand (&), is encountered.
        ;          
        ; Params        GDIPCONST GpStringFormat *format, INT *hotkeyPrefix
        ;          
        ; Return        Status
        ;______________________________________
        GetHotkeyPrefix(GDIPCONST GpStringFormat *format, INT *hotkeyPrefix)
        {
            status := GdipGetStringFormatHotkeyPrefix(GDIPCONST GpStringFormat *format, INT *hotkeyPrefix)
            Return status
        }
        
        ;####################################
        ; Call          SetTabStops(GpStringFormat *format, REAL firstTabOffset, INT count, GDIPCONST REAL *tabStops)
        ; Description   Sets the offsets for tab stops in this StringFormat object.
        ;          
        ; Params        GpStringFormat *format, REAL firstTabOffset, INT count, GDIPCONST REAL *tabStops
        ;          
        ; Return        Status
        ;______________________________________
        SetTabStops(GpStringFormat *format, REAL firstTabOffset, INT count, GDIPCONST REAL *tabStops)
        {
            status := GdipSetStringFormatTabStops(GpStringFormat *format, REAL firstTabOffset, INT count, GDIPCONST REAL *tabStops)
            Return status
        }
        
        ;####################################
        ; Call          GetTabStops(GDIPCONST GpStringFormat *format, INT count, REAL *firstTabOffset, REAL *tabStops)
        ; Description   Gets the offsets of the tab stops in this StringFormat object.
        ;          
        ; Params        GDIPCONST GpStringFormat *format, INT count, REAL *firstTabOffset, REAL *tabStops
        ;          
        ; Return        Status
        ;______________________________________
        GetTabStops(GDIPCONST GpStringFormat *format, INT count, REAL *firstTabOffset, REAL *tabStops)
        {
            status := GdipGetStringFormatTabStops(GDIPCONST GpStringFormat *format, INT count, REAL *firstTabOffset, REAL *tabStops)
            Return status
        }
        
        ;####################################
        ; Call          GetTabStopCount(GDIPCONST GpStringFormat *format, INT * count)
        ; Description   Gets the number of tab-stop offsets in this StringFormat object.
        ;          
        ; Params        GDIPCONST GpStringFormat *format, INT * count
        ;          
        ; Return        Status
        ;______________________________________
        GetTabStopCount(GDIPCONST GpStringFormat *format, INT * count)
        {
            status := GdipGetStringFormatTabStopCount(GDIPCONST GpStringFormat *format, INT * count)
            Return status
        }
        
        ;####################################
        ; Call          SetDigitSubstitution(GpStringFormat *format, LANGID language, StringDigitSubstitute substitute)
        ; Description   Sets the digit substitution method and the language that corresponds to the digit substitutes.
        ;          
        ; Params        GpStringFormat *format, LANGID language, StringDigitSubstitute substitute
        ;          
        ; Return        Status
        ;______________________________________
        SetDigitSubstitution(GpStringFormat *format, LANGID language, StringDigitSubstitute substitute)
        {
            status := GdipSetStringFormatDigitSubstitution(GpStringFormat *format, LANGID language, StringDigitSubstitute substitute)
            Return status
        }
        
        ;####################################
        ; Call          GetDigitSubstitutionMethod(GDIPCONST GpStringFormat *format, LANGID *language, StringDigitSubstitute *substitute)
        ; Description   gets an element of the StringDigitSubstitute enumeration that indicates the digit substitution method that is used by this StringFormat object.\nThe language parameter in the flat function is a 16-bit value that specifies the language to use.
        ;          
        ; Params        GDIPCONST GpStringFormat *format, LANGID *language, StringDigitSubstitute *substitute
        ;          
        ; Return        Status
        ;______________________________________
        GetDigitSubstitutionMethod(GDIPCONST GpStringFormat *format, LANGID *language, StringDigitSubstitute *substitute)
        {
            status := GdipGetStringFormatDigitSubstitution(GDIPCONST GpStringFormat *format, LANGID *language, StringDigitSubstitute *substitute)
            Return status
        }
        
        ;####################################
        ; Call          GetMeasurableCharacterRangeCount( GDIPCONST GpStringFormat *format, INT *count )
        ; Description   gets the number of measurable character ranges that are currently set. The character ranges that are set can be measured in a string by using the Graphics::MeasureCharacterRanges method.
        ;          
        ; Params        GDIPCONST GpStringFormat *format, INT *count 
        ;          
        ; Return        Status
        ;______________________________________
        GetMeasurableCharacterRangeCount( GDIPCONST GpStringFormat *format, INT *count )
        {
            status := GdipGetStringFormatMeasurableCharacterRangeCount( GDIPCONST GpStringFormat *format, INT *count )
            Return status
        }
        
        ;####################################
        ; Call          SetMeasurableCharacterRanges( GpStringFormat *format, INT rangeCount, GDIPCONST CharacterRange *ranges )
        ; Description   Sets a series of character ranges for this StringFormat object that, when in a string, can be measured by the Graphics::MeasureCharacterRanges method.
        ;          
        ; Params        GpStringFormat *format, INT rangeCount, GDIPCONST CharacterRange *ranges 
        ;          
        ; Return        Status
        ;______________________________________
        SetMeasurableCharacterRanges( GpStringFormat *format, INT rangeCount, GDIPCONST CharacterRange *ranges )
        {
            status := GdipSetStringFormatMeasurableCharacterRanges( GpStringFormat *format, INT rangeCount, GDIPCONST CharacterRange *ranges )
            Return status
        }
        
    }
    
    Class Text
    {
        ;####################################
        ; Call          DrawString( GpGraphics *graphics, GDIPCONST WCHAR *string, INT length, GDIPCONST GpFont *font, GDIPCONST RectF *layoutRect, GDIPCONST GpStringFormat *stringFormat, GDIPCONST GpBrush *brush )
        ; Description   Draws a string based on a font, a layout rectangle, and a format.
        ;          
        ; Params        GpGraphics *graphics, GDIPCONST WCHAR *string, INT length, GDIPCONST GpFont *font, GDIPCONST RectF *layoutRect, GDIPCONST GpStringFormat *stringFormat, GDIPCONST GpBrush *brush 
        ;          
        ; Return        Status
        ;______________________________________
        DrawString( GpGraphics *graphics, GDIPCONST WCHAR *string, INT length, GDIPCONST GpFont *font, GDIPCONST RectF *layoutRect, GDIPCONST GpStringFormat *stringFormat, GDIPCONST GpBrush *brush )
        {
            status := GdipDrawString( GpGraphics *graphics, GDIPCONST WCHAR *string, INT length, GDIPCONST GpFont *font, GDIPCONST RectF *layoutRect, GDIPCONST GpStringFormat *stringFormat, GDIPCONST GpBrush *brush )
            Return status
        }
        
        ;####################################
        ; Call          MeasureString( GpGraphics *graphics, GDIPCONST WCHAR *string, INT length, GDIPCONST GpFont *font, GDIPCONST RectF *layoutRect, GDIPCONST GpStringFormat *stringFormat, RectF *boundingBox, INT *codepointsFitted, INT *linesFilled )
        ; Description   Measures the extent of the string in the specified font, format, and layout rectangle.
        ;          
        ; Params        GpGraphics *graphics, GDIPCONST WCHAR *string, INT length, GDIPCONST GpFont *font, GDIPCONST RectF *layoutRect, GDIPCONST GpStringFormat *stringFormat, RectF *boundingBox, INT *codepointsFitted, INT *linesFilled 
        ;          
        ; Return        Status
        ;______________________________________
        MeasureString( GpGraphics *graphics, GDIPCONST WCHAR *string, INT length, GDIPCONST GpFont *font, GDIPCONST RectF *layoutRect, GDIPCONST GpStringFormat *stringFormat, RectF *boundingBox, INT *codepointsFitted, INT *linesFilled )
        {
            status := GdipMeasureString( GpGraphics *graphics, GDIPCONST WCHAR *string, INT length, GDIPCONST GpFont *font, GDIPCONST RectF *layoutRect, GDIPCONST GpStringFormat *stringFormat, RectF *boundingBox, INT *codepointsFitted, INT *linesFilled )
            Return status
        }
        
        ;####################################
        ; Call          MeasureCharacterRanges( GpGraphics *graphics, GDIPCONST WCHAR *string, INT length, GDIPCONST GpFont *font, GDIPCONST RectF &layoutRect, GDIPCONST GpStringFormat *stringFormat, INT regionCount, GpRegion **regions )
        ; Description   Gets a set of regions each of which bounds a range of character positions within a string.
        ;          
        ; Params        GpGraphics *graphics, GDIPCONST WCHAR *string, INT length, GDIPCONST GpFont *font, GDIPCONST RectF &layoutRect, GDIPCONST GpStringFormat *stringFormat, INT regionCount, GpRegion **regions 
        ;          
        ; Return        Status
        ;______________________________________
        MeasureCharacterRanges( GpGraphics *graphics, GDIPCONST WCHAR *string, INT length, GDIPCONST GpFont *font, GDIPCONST RectF &layoutRect, GDIPCONST GpStringFormat *stringFormat, INT regionCount, GpRegion **regions )
        {
            status := GdipMeasureCharacterRanges( GpGraphics *graphics, GDIPCONST WCHAR *string, INT length, GDIPCONST GpFont *font, GDIPCONST RectF &layoutRect, GDIPCONST GpStringFormat *stringFormat, INT regionCount, GpRegion **regions )
            Return status
        }
        
        ;####################################
        ; Call          DrawDriverString( GpGraphics *graphics, GDIPCONST UINT16 *text, INT length, GDIPCONST GpFont *font, GDIPCONST GpBrush *brush, GDIPCONST PointF *positions, INT flags, GDIPCONST GpMatrix *matrix )
        ; Description   Draws characters at the specified positions. The method gives the client complete control over the appearance of text. The method assumes that the client has already set up the format and layout to be applied.
        ;          
        ; Params        GpGraphics *graphics, GDIPCONST UINT16 *text, INT length, GDIPCONST GpFont *font, GDIPCONST GpBrush *brush, GDIPCONST PointF *positions, INT flags, GDIPCONST GpMatrix *matrix 
        ;          
        ; Return        Status
        ;______________________________________
        DrawDriverString( GpGraphics *graphics, GDIPCONST UINT16 *text, INT length, GDIPCONST GpFont *font, GDIPCONST GpBrush *brush, GDIPCONST PointF *positions, INT flags, GDIPCONST GpMatrix *matrix )
        {
            status := GdipDrawDriverString( GpGraphics *graphics, GDIPCONST UINT16 *text, INT length, GDIPCONST GpFont *font, GDIPCONST GpBrush *brush, GDIPCONST PointF *positions, INT flags, GDIPCONST GpMatrix *matrix )
            Return status
        }
        
        ;####################################
        ; Call          MeasureDriverString( GpGraphics *graphics, GDIPCONST UINT16 *text, INT length, GDIPCONST GpFont *font, GDIPCONST PointF *positions, INT flags, GDIPCONST GpMatrix *matrix, RectF *boundingBox )
        ; Description   Measures the bounding box for the specified characters and their corresponding positions.
        ;          
        ; Params        GpGraphics *graphics, GDIPCONST UINT16 *text, INT length, GDIPCONST GpFont *font, GDIPCONST PointF *positions, INT flags, GDIPCONST GpMatrix *matrix, RectF *boundingBox 
        ;          
        ; Return        Status
        ;______________________________________
        MeasureDriverString( GpGraphics *graphics, GDIPCONST UINT16 *text, INT length, GDIPCONST GpFont *font, GDIPCONST PointF *positions, INT flags, GDIPCONST GpMatrix *matrix, RectF *boundingBox )
        {
            status := GdipMeasureDriverString( GpGraphics *graphics, GDIPCONST UINT16 *text, INT length, GDIPCONST GpFont *font, GDIPCONST PointF *positions, INT flags, GDIPCONST GpMatrix *matrix, RectF *boundingBox )
            Return status
        }
    }
    
    Class TextureBrush
    {
        ;####################################
        ; Call          TextureBrush(GpImage *image, GpWrapMode wrapmode, GpTexture **texture)
        ; Description   Creates a TextureBrush object based on an image and a wrap mode. The size of the brush defaults to the size of the image, so the entire image is used by the brush.
        ;          
        ; Params        GpImage *image, GpWrapMode wrapmode, GpTexture **texture
        ;          
        ; Return        Status
        ;______________________________________
        TextureBrush(GpImage *image, GpWrapMode wrapmode, GpTexture **texture)
        {
            status := GdipCreateTexture(GpImage *image, GpWrapMode wrapmode, GpTexture **texture)
            Return status
        }
        
        ;####################################
        ; Call          TextureBrush(GpImage *image, GpWrapMode wrapmode, REAL x, REAL y, REAL width, REAL height, GpTexture **texture)
        ; Description   Creates a TextureBrush object based on an image, a wrap mode, and a defining set of coordinates.
        ;          
        ; Params        GpImage *image, GpWrapMode wrapmode, REAL x, REAL y, REAL width, REAL height, GpTexture **texture
        ;          
        ; Return        Status
        ;______________________________________
        TextureBrush(GpImage *image, GpWrapMode wrapmode, REAL x, REAL y, REAL width, REAL height, GpTexture **texture)
        {
            status := GdipCreateTexture2(GpImage *image, GpWrapMode wrapmode, REAL x, REAL y, REAL width, REAL height, GpTexture **texture)
            Return status
        }
        
        ;####################################
        ; Call          TextureBrush(GpImage *image, GDIPCONST GpImageAttributes *imageAttributes, REAL x, REAL y, REAL width, REAL height, GpTexture **texture)
        ; Description   Creates a TextureBrush object based on an image, a defining rectangle, and a set of image properties.\nThe x, y, width, and height parameters of the flat function define a rectangle that corresponds to the dstRect parameter of the wrapper method.
        ;          
        ; Params        GpImage *image, GDIPCONST GpImageAttributes *imageAttributes, REAL x, REAL y, REAL width, REAL height, GpTexture **texture
        ;          
        ; Return        Status
        ;______________________________________
        TextureBrush(GpImage *image, GDIPCONST GpImageAttributes *imageAttributes, REAL x, REAL y, REAL width, REAL height, GpTexture **texture)
        {
            status := GdipCreateTextureIA(GpImage *image, GDIPCONST GpImageAttributes *imageAttributes, REAL x, REAL y, REAL width, REAL height, GpTexture **texture)
            Return status
        }
        
        ;####################################
        ; Call          TextureBrush(GpImage *image, GpWrapMode wrapmode, INT x, INT y, INT width, INT height, GpTexture **texture)
        ; Description   Creates a TextureBrush object based on an image, a wrap mode, and a defining set of coordinates.
        ;          
        ; Params        GpImage *image, GpWrapMode wrapmode, INT x, INT y, INT width, INT height, GpTexture **texture
        ;          
        ; Return        Status
        ;______________________________________
        TextureBrush(GpImage *image, GpWrapMode wrapmode, INT x, INT y, INT width, INT height, GpTexture **texture)
        {
            status := GdipCreateTexture2I(GpImage *image, GpWrapMode wrapmode, INT x, INT y, INT width, INT height, GpTexture **texture)
            Return status
        }
        
        ;####################################
        ; Call          TextureBrush(GpImage *image, GDIPCONST GpImageAttributes *imageAttributes, INT x, INT y, INT width, INT height, GpTexture **texture)
        ; Description   Creates a TextureBrush object based on an image, a defining rectangle, and a set of image properties.\nThe x, y, width, and height parameters of the flat function define a rectangle that corresponds to the dstRect parameter of the wrapper method.
        ;          
        ; Params        GpImage *image, GDIPCONST GpImageAttributes *imageAttributes, INT x, INT y, INT width, INT height, GpTexture **texture
        ;          
        ; Return        Status
        ;______________________________________
        TextureBrush(GpImage *image, GDIPCONST GpImageAttributes *imageAttributes, INT x, INT y, INT width, INT height, GpTexture **texture)
        {
            status := GdipCreateTextureIAI(GpImage *image, GDIPCONST GpImageAttributes *imageAttributes, INT x, INT y, INT width, INT height, GpTexture **texture)
            Return status
        }
        
        ;####################################
        ; Call          GetTransform(GpTexture *brush, GpMatrix *matrix)
        ; Description   Gets the transformation matrix of this texture brush.
        ;          
        ; Params        GpTexture *brush, GpMatrix *matrix
        ;          
        ; Return        Status
        ;______________________________________
        GetTransform(GpTexture *brush, GpMatrix *matrix)
        {
            status := GdipGetTextureTransform(GpTexture *brush, GpMatrix *matrix)
            Return status
        }
        
        ;####################################
        ; Call          SetTransform(GpTexture *brush, GDIPCONST GpMatrix *matrix)
        ; Description   Sets the transformation matrix of this texture brush.
        ;          
        ; Params        GpTexture *brush, GDIPCONST GpMatrix *matrix
        ;          
        ; Return        Status
        ;______________________________________
        SetTransform(GpTexture *brush, GDIPCONST GpMatrix *matrix)
        {
            status := GdipSetTextureTransform(GpTexture *brush, GDIPCONST GpMatrix *matrix)
            Return status
        }
        
        ;####################################
        ; Call          ResetTransform(GpTexture* brush)
        ; Description   Resets the transformation matrix of this texture brush to the identity matrix. This means that no transformation takes place.
        ;          
        ; Params        GpTexture* brush
        ;          
        ; Return        Status
        ;______________________________________
        ResetTransform(GpTexture* brush)
        {
            status := GdipResetTextureTransform(GpTexture* brush)
            Return status
        }
        
        ;####################################
        ; Call          MultiplyTransform(GpTexture* brush, GDIPCONST GpMatrix *matrix, GpMatrixOrder order)
        ; Description   Updates this brush's transformation matrix with the product of itself and another matrix.
        ;          
        ; Params        GpTexture* brush, GDIPCONST GpMatrix *matrix, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        MultiplyTransform(GpTexture* brush, GDIPCONST GpMatrix *matrix, GpMatrixOrder order)
        {
            status := GdipMultiplyTextureTransform(GpTexture* brush, GDIPCONST GpMatrix *matrix, GpMatrixOrder order)
            Return status
        }
        
        ;####################################
        ; Call          TranslateTransform(GpTexture* brush, REAL dx, REAL dy, GpMatrixOrder order)
        ; Description   Updates this brush's current transformation matrix with the product of itself and a translation matrix.
        ;          
        ; Params        GpTexture* brush, REAL dx, REAL dy, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        TranslateTransform(GpTexture* brush, REAL dx, REAL dy, GpMatrixOrder order)
        {
            status := GdipTranslateTextureTransform(GpTexture* brush, REAL dx, REAL dy, GpMatrixOrder order)
            Return status
        }
        
        ;####################################
        ; Call          ScaleTransform(GpTexture* brush, REAL sx, REAL sy, GpMatrixOrder order)
        ; Description   Updates this texture brush's current transformation matrix with the product of itself and a scaling matrix.
        ;          
        ; Params        GpTexture* brush, REAL sx, REAL sy, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        ScaleTransform(GpTexture* brush, REAL sx, REAL sy, GpMatrixOrder order)
        {
            status := GdipScaleTextureTransform(GpTexture* brush, REAL sx, REAL sy, GpMatrixOrder order)
            Return status
        }
        
        ;####################################
        ; Call          RotateTransform(GpTexture* brush, REAL angle, GpMatrixOrder order)
        ; Description   Updates this texture brush's current transformation matrix with the product of itself and a rotation matrix.
        ;          
        ; Params        GpTexture* brush, REAL angle, GpMatrixOrder order
        ;          
        ; Return        Status
        ;______________________________________
        RotateTransform(GpTexture* brush, REAL angle, GpMatrixOrder order)
        {
            status := GdipRotateTextureTransform(GpTexture* brush, REAL angle, GpMatrixOrder order)
            Return status
        }
        
        ;####################################
        ; Call          SetWrapMode(GpTexture *brush, GpWrapMode wrapmode)
        ; Description   Sets the wrap mode of this texture brush.
        ;          
        ; Params        GpTexture *brush, GpWrapMode wrapmode
        ;          
        ; Return        Status
        ;______________________________________
        SetWrapMode(GpTexture *brush, GpWrapMode wrapmode)
        {
            status := GdipSetTextureWrapMode(GpTexture *brush, GpWrapMode wrapmode)
            Return status
        }
        
        ;####################################
        ; Call          GetWrapMode(GpTexture *brush, GpWrapMode *wrapmode)
        ; Description   Gets the wrap mode currently set for this texture brush.
        ;          
        ; Params        GpTexture *brush, GpWrapMode *wrapmode
        ;          
        ; Return        Status
        ;______________________________________
        GetWrapMode(GpTexture *brush, GpWrapMode *wrapmode)
        {
            status := GdipGetTextureWrapMode(GpTexture *brush, GpWrapMode *wrapmode)
            Return status
        }
        
        ;####################################
        ; Call          GetImage(GpTexture *brush, GpImage **image)
        ; Description   Gets a pointer to the Image object that is defined by this texture brush.
        ;          
        ; Params        GpTexture *brush, GpImage **image
        ;          
        ; Return        Status
        ;______________________________________
        GetImage(GpTexture *brush, GpImage **image)
        {
            status := GdipGetTextureImage(GpTexture *brush, GpImage **image)
            Return status
        }
        
    }
    
    
    
    ;## GENERATORS ##
    
    ;####################################################################################################################
    ; Call          generate_colors()                                                                                   |
    ; Description   Generates an object containing all the hex colors from CSS3/X11.                                    |
    ;___________________________________________________________________________________________________________________|
    generate_colorName() {
        this.color := {}
        
        ; Black and gray/grey                                   ; White                                             
        ,this.colorName.Black                := 0x000000        ,this.colorName.MistyRose            := 0xFFE4E1         
        ,this.colorName.DarkSlateGray        := 0x2F4F4F        ,this.colorName.AntiqueWhite         := 0xFAEBD7         
        ,this.colorName.DarkSlateGrey        := 0x2F4F4F        ,this.colorName.Linen                := 0xFAF0E6         
        ,this.colorName.DimGray              := 0x696969        ,this.colorName.Beige                := 0xF5F5DC         
        ,this.colorName.DimGrey              := 0x696969        ,this.colorName.WhiteSmoke           := 0xF5F5F5         
        ,this.colorName.SlateGray            := 0x708090        ,this.colorName.LavenderBlush        := 0xFFF0F5         
        ,this.colorName.SlateGrey            := 0x708090        ,this.colorName.OldLace              := 0xFDF5E6         
        ,this.colorName.Gray                 := 0x808080        ,this.colorName.AliceBlue            := 0xF0F8FF         
        ,this.colorName.Grey                 := 0x808080        ,this.colorName.Seashell             := 0xFFF5EE         
        ,this.colorName.LightSlateGray       := 0x778899        ,this.colorName.GhostWhite           := 0xF8F8FF         
        ,this.colorName.LightSlateGrey       := 0x778899        ,this.colorName.Honeydew             := 0xF0FFF0         
        ,this.colorName.DarkGray             := 0xA9A9A9        ,this.colorName.FloralWhite          := 0xFFFAF0         
        ,this.colorName.DarkGrey             := 0xA9A9A9        ,this.colorName.Azure                := 0xF0FFFF         
        ,this.colorName.Silver               := 0xC0C0C0        ,this.colorName.MintCream            := 0xF5FFFA         
        ,this.colorName.LightGray            := 0xD3D3D3        ,this.colorName.Snow                 := 0xFFFAFA         
        ,this.colorName.LightGrey            := 0xD3D3D3        ,this.colorName.Ivory                := 0xFFFFF0         
        ,this.colorName.Gainsboro            := 0xDCDCDC        ,this.colorName.White                := 0xFFFFFF         
                                                                                                                           
        ; Red                                                   ; Pink
        ,this.colorName.DarkRed              := 0x8B0000        ,this.colorName.MediumVioletRed      := 0xC71585
        ,this.colorName.Red                  := 0xFF0000        ,this.colorName.DeepPink             := 0xFF1493
        ,this.colorName.Firebrick            := 0xB22222        ,this.colorName.PaleVioletRed        := 0xDB7093
        ,this.colorName.Crimson              := 0xDC143C        ,this.colorName.HotPink              := 0xFF69B4
        ,this.colorName.IndianRed            := 0xCD5C5C        ,this.colorName.LightPink            := 0xFFB6C1
        ,this.colorName.LightCoral           := 0xF08080        ,this.colorName.Pink                 := 0xFFC0CB
        ,this.colorName.Salmon               := 0xFA8072        
        ,this.colorName.DarkSalmon           := 0xE9967A        
        ,this.colorName.LightSalmon          := 0xFFA07A        
                                                                                                                           
        ; Blue                                                  ; Purple, violet, and magenta                           
        ,this.colorName.Navy                 := 0x000080        ,this.colorName.Indigo               := 0x4B0082             
        ,this.colorName.DarkBlue             := 0x00008B        ,this.colorName.Purple               := 0x800080             
        ,this.colorName.MediumBlue           := 0x0000CD        ,this.colorName.DarkMagenta          := 0x8B008B             
        ,this.colorName.Blue                 := 0x0000FF        ,this.colorName.DarkViolet           := 0x9400D3             
        ,this.colorName.MidnightBlue         := 0x191970        ,this.colorName.DarkSlateBlue        := 0x483D8B             
        ,this.colorName.RoyalBlue            := 0x4169E1        ,this.colorName.BlueViolet           := 0x8A2BE2             
        ,this.colorName.SteelBlue            := 0x4682B4        ,this.colorName.DarkOrchid           := 0x9932CC             
        ,this.colorName.DodgerBlue           := 0x1E90FF        ,this.colorName.Fuchsia              := 0xFF00FF             
        ,this.colorName.DeepSkyBlue          := 0x00BFFF        ,this.colorName.Magenta              := 0xFF00FF             
        ,this.colorName.CornflowerBlue       := 0x6495ED        ,this.colorName.SlateBlue            := 0x6A5ACD             
        ,this.colorName.SkyBlue              := 0x87CEEB        ,this.colorName.MediumSlateBlue      := 0x7B68EE             
        ,this.colorName.LightSkyBlue         := 0x87CEFA        ,this.colorName.MediumOrchid         := 0xBA55D3             
        ,this.colorName.LightSteelBlue       := 0xB0C4DE        ,this.colorName.MediumPurple         := 0x9370DB             
        ,this.colorName.LightBlue            := 0xADD8E6        ,this.colorName.Orchid               := 0xDA70D6             
        ,this.colorName.PowderBlue           := 0xB0E0E6        ,this.colorName.Violet               := 0xEE82EE             
                                                                ,this.colorName.Plum                 := 0xDDA0DD            
                                                                ,this.colorName.Thistle              := 0xD8BFD8            
                                                                ,this.colorName.Lavender             := 0xE6E6FA            
                                                                                                                           
        ; Green                                                 ; Cyan                                                       
        ,this.colorName.DarkGreen            := 0x006400        ,this.colorName.Teal                 := 0x008080             
        ,this.colorName.Green                := 0x008000        ,this.colorName.DarkCyan             := 0x008B8B             
        ,this.colorName.DarkOliveGreen       := 0x556B2F        ,this.colorName.LightSeaGreen        := 0x20B2AA             
        ,this.colorName.ForestGreen          := 0x228B22        ,this.colorName.CadetBlue            := 0x5F9EA0             
        ,this.colorName.SeaGreen             := 0x2E8B57        ,this.colorName.DarkTurquoise        := 0x00CED1             
        ,this.colorName.Olive                := 0x808000        ,this.colorName.MediumTurquoise      := 0x48D1CC             
        ,this.colorName.OliveDrab            := 0x6B8E23        ,this.colorName.Turquoise            := 0x40E0D0             
        ,this.colorName.MediumSeaGreen       := 0x3CB371        ,this.colorName.Aqua                 := 0x00FFFF             
        ,this.colorName.LimeGreen            := 0x32CD32        ,this.colorName.Cyan                 := 0x00FFFF             
        ,this.colorName.Lime                 := 0x00FF00        ,this.colorName.Aquamarine           := 0x7FFFD4             
        ,this.colorName.SpringGreen          := 0x00FF7F        ,this.colorName.PaleTurquoise        := 0xAFEEEE             
        ,this.colorName.MediumSpringGreen    := 0x00FA9A        ,this.colorName.LightCyan            := 0xE0FFFF             
        ,this.colorName.DarkSeaGreen         := 0x8FBC8F                                                                     
        ,this.colorName.MediumAquamarine     := 0x66CDAA        ; Orange                                                     
        ,this.colorName.YellowGreen          := 0x9ACD32        ,this.colorName.OrangeRed            := 0xFF4500             
        ,this.colorName.LawnGreen            := 0x7CFC00        ,this.colorName.Tomato               := 0xFF6347             
        ,this.colorName.Chartreuse           := 0x7FFF00        ,this.colorName.DarkOrange           := 0xFF8C00             
        ,this.colorName.LightGreen           := 0x90EE90        ,this.colorName.Coral                := 0xFF7F50             
        ,this.colorName.GreenYellow          := 0xADFF2F        ,this.colorName.Orange               := 0xFFA500             
        ,this.colorName.PaleGreen            := 0x98FB98        
                                                                                                                           
        ; Brown                                                 ; Yellow                                                   
        ,this.colorName.Maroon               := 0x800000        ,this.colorName.DarkKhaki            := 0xBDB76B            
        ,this.colorName.Brown                := 0xA52A2A        ,this.colorName.Gold                 := 0xFFD700            
        ,this.colorName.SaddleBrown          := 0x8B4513        ,this.colorName.Khaki                := 0xF0E68C            
        ,this.colorName.Sienna               := 0xA0522D        ,this.colorName.PeachPuff            := 0xFFDAB9            
        ,this.colorName.Chocolate            := 0xD2691E        ,this.colorName.Yellow               := 0xFFFF00            
        ,this.colorName.DarkGoldenrod        := 0xB8860B        ,this.colorName.PaleGoldenrod        := 0xEEE8AA            
        ,this.colorName.Peru                 := 0xCD853F        ,this.colorName.Moccasin             := 0xFFE4B5            
        ,this.colorName.RosyBrown            := 0xBC8F8F        ,this.colorName.PapayaWhip           := 0xFFEFD5            
        ,this.colorName.Goldenrod            := 0xDAA520        ,this.colorName.LightGoldenrodYellow := 0xFAFAD2            
        ,this.colorName.SandyBrown           := 0xF4A460        ,this.colorName.LemonChiffon         := 0xFFFACD            
        ,this.colorName.Tan                  := 0xD2B48C        ,this.colorName.LightYellow          := 0xFFFFE0            
        ,this.colorName.Burlywood            := 0xDEB887                                                                     
        ,this.colorName.Wheat                := 0xF5DEB3                                                                     
        ,this.colorName.NavajoWhite          := 0xFFDEAD                                                                     
        ,this.colorName.Bisque               := 0xFFE4C4                                                                     
        ,this.colorName.BlanchedAlmond       := 0xFFEBCD                                                                     
        ,this.colorName.Cornsilk             := 0xFFF8DC                                                                     
        Return
    }
}

/*
### IDEAS ###
Add a "cup" class as a container to hold pens and brushes
    Add a method to "empty" the cup of all brushes and pens
    Add a method to list all stored brushes and pens
    
*/

    ;___________________________________________________________________________________________________________________|
    ; Call                                                                                                              |
    ; Description                                                                                                       |
    ; Params                                                                                                            |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|



/*
    ;###################################################################################################################|
    ; Call                                                                                                              |
    ; Description                                                                                                       |
    ;                                                                                                                   |
    ; Param                                                                                                             |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    
Class GDIP
{
    ; ## Functions ##
    ;###################################################################################################################|
    ; Call              |                                                                                               |
    ; Description       Cleans up resources used by Windows GDI+                                                        |
    ;                                                                                                                   |
    ; Param                                                                                                             |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    GdiplusShutdown(token)
    {
        ;void GdiplusShutdown(
        ;    ULONG_PTR token
        ;)
        Return
    }
        
    ;###################################################################################################################|
    ; Call                                                                                                              |
    ; Description                                                                                                       |
    ;                                                                                                                   |
    ; Param                                                                                                             |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
     GdiplusStartup()
    {
        ; Status GdiplusStartup(
        ;   ULONG_PTR                 *token,
        ;   const GdiplusStartupInput *input,
        ;   GdiplusStartupOutput      *output
        ; );
        Return
    }
        
    ; 
    ; Builds a line cap that looks like an arrow. This is a subclass of CustomLineCap.
    Class AdjustableArrowCap
    {
        ; ## Methods ##
        ; Creates an adjustable arrow line cap with specified height and width. Can be filled or unfilled. Middle inset defaults to zero.
        AdjustableArrowCap()
        {
            Return
        }
        
        ; Gets height of arrow cap. The height is the distance from the base of the arrow to its vertex.
        GetHeight()
        {
            Return
        }
        
        ; Gets value of inset. The middle inset is the number of units that the midpoint of the base shifts towards the vertex.
        GetMiddleInset()
        {
            Return
        }
        
        ; Gets width of arrow cap. The width is the distance between the endpoints of the base of the arrow.
        GetWidth()
        {
            Return
        }
        
        ; Determines whether the arrow cap is filled.
        IsFilled()
        {
            Return
        }
        
        ; Sets fill state of the arrow cap. If the arrow cap is not filled, only the outline is drawn.
        SetFillState()
        {
            Return
        }
        
        ; Sets height of the arrow cap. This is the distance from the base of the arrow to its vertex.
        SetHeight()
        {
            Return
        }
        
        ; Sets number of units that the midpoint of the base shifts towards the vertex.
        SetMiddleInset()
        {
            Return
        }
        
        ; Sets width of the arrow cap. The width is the distance between the endpoints of the base of the arrow.
        SetWidth()
        {
            Return
        }
        
    }
        
    ; Inherits from the Image class. The Image class provides saving and loading methods for vector images (metafiles)                                 ; and raster images (bitmaps).
    Class Bitmap
    {
        ; ## Methods ##
        ; Creates a new Bitmap object by applying a specified effect to an existing Bitmap object.
        ApplyEffectThe()
        {
            Return
        }
        
        ; Alters this Bitmap object by applying a specified effect.
        ApplyEffectThe()
        {
            Return
        }
        
        ; Creates a Bitmap object based on a BITMAPINFO structure and an array of pixel data.
        Bitmap()
        {
            Return
        }
        
        ; Creates a Bitmap object based on an image file.
        Bitmap()
        {
            Return
        }
        
        ; Creates a Bitmap object based on a handle to a Windows Windows Graphics Device Interface (GDI)                                 ; bitmap and a handle to a GDI palette.
        Bitmap()
        {
            Return
        }
        
        ; Creates a Bitmap object based on an icon.
        Bitmap()
        {
            Return
        }
        
        ; Creates a Bitmap object based on an application or DLL instance handle and the name of a bitmap resource.
        Bitmap()
        {
            Return
        }
        
        ; Creates a Bitmap object based on a DirectDraw surface. The Bitmap object maintains a reference to DirectDraw surface until Bitmap object is deleted or goes out of scope.
        Bitmap()
        {
            Return
        }
        
        ; Creates a Bitmap object based on a Graphics object, a width, and a height.
        Bitmap()
        {
            Return
        }
        
        ; Creates a Bitmap object based on an array of bytes along with size and format information.
        Bitmap()
        {
            Return
        }
        
        ; Creates a Bitmap object of a specified size and pixel format. The pixel data must be provided after the Bitmap::Bitmap object is constructed.
        Bitmap()
        {
            Return
        }
        
        ; Creates a Bitmap object based on an IStream COM interface.
        Bitmap()
        {
            Return
        }
        
        ; Creates a new Bitmap object by copying a portion of this bitmap.
        CloneThe()
        {
            Return
        }
        
        ; Creates a new Bitmap object by copying a portion of this bitmap.
        CloneThe()
        {
            Return
        }
        
        ; Creates a new Bitmapobject by copying a portion of this bitmap.
        CloneThe()
        {
            Return
        }
        
        ; Creates a new Bitmapobject by copying a portion of this bitmap.
        CloneThe()
        {
            Return
        }
        
        ; Converts a bitmap to a specified pixel format. The original pixel data in the bitmap is replaced by the new pixel data.
        ConvertFormatThe()
        {
            Return
        }
        
        ; Creates a Bitmap object based on a BITMAPINFO structure and an array of pixel data.
        FromBITMAPINFOThe()
        {
            Return
        }
        
        ; Creates a Bitmap object based on a DirectDraw surface. The Bitmap object maintains a reference to the DirectDraw surface until the Bitmap object is deleted.
        FromDirectDrawSurface()
        {
            Return
        }
        
        ; Creates a Bitmap object based on an image file.
        FromFileThe()
        {
            Return
        }
        
        ; Creates a Bitmap object based on a handle to a Windows Graphics Device Interface (GDI)                                 ; bitmap and a handle to a GDI palette.
        FromHBITMAPThe()
        {
            Return
        }
        
        ; Creates a Bitmap object based on a handle to an icon.
        FromHICONThe()
        {
            Return
        }
        
        ; Creates a Bitmap object based on an application or DLL instance handle and the name of a bitmap resource.
        FromResourceThe()
        {
            Return
        }
        
        ; Creates a Bitmap object based on a stream.
        FromStreamThe()
        {
            Return
        }
        
        ; Creates a Windows Graphics Device Interface (GDI)                                 ; bitmap from this Bitmap object.
        GetHBITMAPThe()
        {
            Return
        }
        
        ; Creates an icon from this Bitmap object.
        GetHICONThe()
        {
            Return
        }
        
        ; Returns one or more histograms for specified color channels of this Bitmap object.
        GetHistogramThe()
        {
            Return
        }
        
        ; The number of elements (in an array of UINTs)                                 ; that you must allocate before you call the Bitmap::GetHistogram method of a Bitmap object.
        GetHistogramSizeThe()
        {
            Return
        }
        
        ; Gets the color of a specified pixel in this bitmap.
        GetPixelThe()
        {
            Return
        }
        
        ; Initializes a standard, optimal, or custom color palette.
        InitializePaletteThe()
        {
            Return
        }
        
        ; Locks a rectangular portion of this bitmap and provides a temporary buffer that you can use to read or write pixel data in a specified format.
        LockBitsThe()
        {
            Return
        }
        
        ; Sets the color of a specified pixel in this bitmap.
        SetPixelThe()
        {
            Return
        }
        
        ; Sets the resolution of this Bitmap object.
        SetResolutionThe()
        {
            Return
        }
        
        ; Unlocks a portion of this bitmap that was previously locked by a call to Bitmap::LockBits.
        UnlockBitsThe()
        {
            Return
        }
        
    }
        
    ; Used by the Bitmap::LockBits and Bitmap::UnlockBits methods of the Bitmap class. A BitmapData object stores attributes of a bitmap.
    Class BitmapData
    {
        ; ## Methods ##
    }
        
    ; Enables you to apply a Gaussian blur effect to a bitmap and specify the nature of the blur.
    Class Blur
    {
        ; ## Methods ##
        ; Blur object.
        BlurCreates()
        {
            Return
        }
        
        ; Gets current values of Blur object parameters.
        GetParameters()
        {
            Return
        }
        
        ; Sets value for Blur object.
        SetParameters()
        {
            Return
        }
        
    }
        
    ; Enables you to change the brightness and contrast of a bitmap. 
    Class BrightnessContrast
    {
        ; ## Methods ##
        ; Creates a new BrightnessContrast object.
        BrightnessContrast()
        {
            Return
        }
        
        ; Gets current values of the parameters of this BrightnessContrast object.
        GetParameters()
        {
            Return
        }
        
        ; Sets parameters of this BrightnessContrast object.    
        SetParameters()
        {
            Return
        }
        
    }
        
    ; An abstract base class that defines a Brush object. A Brush object is used to paint the interior of graphics shapes, such as rectangles, ellipses, pies, polygons, and paths.
    Class Brush
    {
        ; ## Methods ##
        ; Creates a copy of a Brush object.
        Clone()
        {
            Return
        }
        
        ; Returns a value indicating this Brush object's most recent method failure.
        GetLastStatus()
        {
            Return
        }
        
        ; Gets the type of this brush.
        GetType()
        {
            Return
        }
        
    }
        
    ; Stores a bitmap in a format that is optimized for display on a particular device.
    Class CachedBitmap
    {
        ; ## Methods ##
        ; Create a CachedBitmap object based on a Bitmap object and Graphics object.
        CachedBitmap()
        {
            Return
        }
        
        ; Copy constructor for CachedBitmap.
        CachedBitmap()
        {
            Return
        }
        
        ; Returns a value indicating if CachedBitmap object was constructed successfully.
        GetLastStatus()
        {
            Return
        }
        
    }
        
    ; Specifies a range of character positions within a string
    Class CharacterRange
    {
        ; ## Constructors ##
        ; Creates a CharacterRange object with data members set to zero.
        CharacterRange()
        {
            Return
        }
        
        ; Creates a CharacterRange object and initializes data members to the values specified.    
        CharacterRange(INT,INT)
        {
            Return
        }
        
        
        ; ## Methods ##
        operator=()                                                         ; The operator= method sets a CharacterRange object equal to the specified CharacterRange object.
    }
        
    ; An object that stores a 32-bit value representing a color. The value contains four 8-bit components: alpha, red, green, and blue (respectively)
    Class Color
    {
        ; ## Constructors ##
        ; Creates Color object and initializes it to opaque black. This is the default constructor.
        Color()
        {
            Return
        }
        
        ; Creates Color object using an ARGB value.
        Color(ARGB)
        {
            Return
        }
        
        ; Creates Color object using specified values for the red, green, and blue components. This constructor sets the alpha component to 255 (opaque).
        Color(BYTE,BYTE,BYTE)
        {
            Return
        }
        
        ; Creates Color object using specified values for the alpha, red, green, and blue components.     
        Color(BYTE,BYTE,BYTE,BYTE)
        {
            Return
        }
        
        
        ; ## Methods ##
        ; Gets alpha component of Color object.
        GetA()
        {
            Return
        }
        
        ; Gets alpha component of Color object.
        GetAlpha()
        {
            Return
        }
        
        ; Gets blue component of Color object.
        GetB()
        {
            Return
        }
        
        ; Gets blue component of Color object.
        GetBlue()
        {
            Return
        }
        
        ; Gets green component of Color object.
        GetG()
        {
            Return
        }
        
        ; Gets green component of Color object.
        GetGreen()
        {
            Return
        }
        
        ; Gets red component of Color object.
        GetR()
        {
            Return
        }
        
        ; Gets red component of Color object.
        GetRed()
        {
            Return
        }
        
        ; Gets ARGB value of this Color object.
        GetValue()
        {
            Return
        }
        
        ; Creates a 32-bit value using the specified alpha, red, green, and blue components.
        MakeARGB()
        {
            Return
        }
        
        ; Uses a GDICOLORREF value to set the ARGB value of this Color object.
        SetFromCOLORREF()
        {
            Return
        }
        
        ; Sets the color of this Color object.
        SetValue()
        {
            Return
        }
        
        ; Converts this Color object's ARGB value to a GDICOLORREF value.
        ToCOLORREF()
        {
            Return
        }
        
    }
        
    ; The ColorBalance class enables you to change the color balance (relative amounts of red, green, and blue)                                 ; of a bitmap.
    Class ColorBalance
    {
        ; ## Methods ##
        ; Create new ColorBalance object.
        ColorBalance()
        {
            Return
        }
        
        ; Gets the current values of the parameters of this ColorBalance object.
        GetParameters()
        {
            Return
        }
        
        ; Sets the parameters of this ColorBalance object.
        SetParameters()
        {
            Return
        }
        
    }
        
    ; Eight different image adjustments: Exposure, density, contrast, highlight, shadow, midtone, white saturation, black saturation
    Class ColorCurve
    {
        ; ## Methods ##
        ; Creates a ColorCurve object.
        ColorCurve()
        {
            Return
        }
        
        ; Gets the current values of the parameters of this ColorCurve object.
        GetParameters()
        {
            Return
        }
        
        ; Sets the parameters of this ColorCurve object.
        SetParameters()
        {
            Return
        }
        
    }
        
    ; Use lookup tables to make custom color adjustments to bitmaps. A ColorLUTParams structure has four members, each being a lookup table for : alpha, red, green, or blue.
    Class ColorLUT
    {
        ; ## Methods ##
        ; Creates a new ColorLUT object.
        ColorLUT()
        {
            Return
        }
        
        ; Gets the current values of the parameters of this ColorLUT object.
        GetParameters()
        {
            Return
        }
        
        ; Sets the parameters of this ColorLUT object.
        SetParameters()
        {
            Return
        }
        
    }
        
    ; Enables you to apply an affine transformation to a bitmap.
    Class ColorMatrixEffect
    {
        ; ## Methods ##
        ; Creates a ColorMatrixEffect object.
        ColorMatrixEffect()
        {
            Return
        }
        
        ; Gets the elements of the current 5x5 color matrix of this ColorMatrixEffect object.
        GetParameters()
        {
            Return
        }
        
        ; Sets the 5x5 color matrix of this ColorMatrixEffect object.
        SetParameters()
        {
            Return
        }
        
    }
        
    ; Encapsulates a custom line cap. A line cap defines the style of graphic used to draw the ends of a line. It can be various shapes, such as a square, circle, or diamond. A custom line cap is defined by the path that draws it.
    Class CustomLineCap
    {
        ; ## Methods ##
        ; Copies the contents of the existing object into a new CustomLineCap object.
        Clone()
        {
            Return
        }
        
        ; Copy constructor for CustomLineCap.
        CustomLineCap()
        {
            Return
        }
        
        ; Creates a CustomLineCap object.
        CustomLineCap()
        {
            Return
        }
        
        ; Creates a CustomLineCap object.
        CustomLineCap()
        {
            Return
        }
        
        ; Gets the style of the base cap. The base cap is a LineCap object used as a cap at the end of a line along with this CustomLineCap object.
        GetBaseCap()
        {
            Return
        }
        
        ; Gets the distance between the base cap to the start of the line.
        GetBaseInset()
        {
            Return
        }
        
        ; Returns a value that indicates the nature of this CustomLineCap object's most recent method failure.
        GetLastStatus()
        {
            Return
        }
        
        ; Gets the end cap styles for both the start line cap and the end line cap. Line caps are LineCap objects that end the individual lines within a path.
        GetStrokeCaps()
        {
            Return
        }
        
        ; Returns the style of LineJoin used to join multiple lines in the same GraphicsPath object.
        GetStrokeJoin()
        {
            Return
        }
        
        ; Gets the value of the scale width. This is the amount to scale the custom line cap relative to the width of the Pen object used to draw a line. The default value of 1.0 does not scale the line cap.
        GetWidthScale()
        {
            Return
        }
        
        ; Sets the LineCap that appears as part of this CustomLineCap at the end of a line.
        SetBaseCap()
        {
            Return
        }
        
        ; Sets the base inset value of this custom line cap. This is the distance between the end of a line and the base cap.
        SetBaseInset()
        {
            Return
        }
        
        ; Sets the LineCap object used to start and end lines within the GraphicsPath object that defines this CustomLineCap object.
        SetStrokeCap()
        {
            Return
        }
        
        ; Sets the LineCap objects used to start and end lines within the GraphicsPath object that defines this CustomLineCap object.
        SetStrokeCaps()
        {
            Return
        }
        
        ; Sets the style of line join for the stroke. The line join specifies how two lines that intersect within the GraphicsPath object that makes up the custom line cap are joined.
        SetStrokeJoin()
        {
            Return
        }
        
        ; Sets the value of the scale width. This is the amount to scale the custom line cap relative to the width of the Pen used to draw lines. The default value of 1.0 does not scale the line cap.
        SetWidthScale()
        {
            Return
        }
        
    }
        
    ; Serves as a base class for eleven classes that you can use to apply effects and adjustments to bitmaps. 
    Class Effect
    {
        ; ## Constructors ##
        ; Creates an Effect object
        Effect()
        {
            Return
        }
        
        
        ; ## Methods ##
        ; Gets a pointer to a set of lookup tables created by a previous call to the Bitmap::ApplyEffect method.
        GetAuxData()
        {
            Return
        }
        
        ; Gets the size, in bytes, of the auxiliary data created by a previous call to the Bitmap::ApplyEffect method.
        GetAuxDataSize()
        {
            Return
        }
        
        ; Gets the total size, in bytes, of the parameters currently set for this Effect. The Effect::GetParameterSize method is usually called on an object that is an instance of a descendant of the Effect class.
        GetParameterSize()
        {
            Return
        }
        
        ; Sets or clears a flag that specifies whether the Bitmap::ApplyEffect method should return a pointer to the auxiliary data that it creates.
        UseAuxData()
        {
            Return
        }
        
    }
        
    ; Holds a parameter that can be passed to an image encoder.
    Class EncoderParameter
    {
        ; ## Methods ##
    }
        
    ; An array of EncoderParameter objects along with a data member that specifies the number of EncoderParameter objects in the array.
    Class EncoderParameters
    {
        ; ## Methods ##
    }
        
    ; Encapsulates the characteristics, such as family, height, size, and style (or combination of styles), of a specific font. A Font object is used when drawing strings.
    Class Font
    {
        ; ## Methods ##
        ; Creates a new Font object based on this Font object.
        Clone()
        {
            Return
        }
        
        ; Lists the constructors of the Font class. For a complete class listing, see Font Class.
        Font()
        {
            Return
        }
        
        ; Creates a Font object based on a FontFamily object, a size, a font style, and a unit of measurement.
        Font()
        {
            Return
        }
        
        ; Creates a Font object based on a font family, a size, a font style, a unit of measurement, and a FontCollection object.
        Font()
        {
            Return
        }
        
        ; This topic lists the constructors of the Font class. For a complete class listing, see Font Class.
        Font()
        {
            Return
        }
        
        ; Creates a Font object based on the Windows Graphics Device Interface (GDI)                                 ; font object that is currently selected into a specified device context. This constructor is provided for compatibility with GDI.
        Font()
        {
            Return
        }
        
        ; Creates a Font object indirectly from a Windows Graphics Device Interface (GDI)                                 ; logical font by using a handle to a GDILOGFONT structure.
        Font()
        {
            Return
        }
        
        ; Creates a Font object directly from a Windows Graphics Device Interface (GDI)                                 ; logical font.
        Font()
        {
            Return
        }
        
        ; Creates a Font object directly from a Windows Graphics Device Interface (GDI)                                 ; logical font.
        Font()
        {
            Return
        }
        
        ; Gets the font family on which this font is based.
        GetFamily()
        {
            Return
        }
        
        ; Gets the line spacing of this font in the current unit of a specified Graphics object.
        GetHeight()
        {
            Return
        }
        
        ; Gets the line spacing, in pixels, of this font.
        GetHeight()
        {
            Return
        }
        
        ; Returns a value that indicates the nature of this Font object's most recent method failure.
        GetLastStatus()
        {
            Return
        }
        
        ; Uses a LOGFONTA structure to get the attributes of this Font object.
        GetLogFontA()
        {
            Return
        }
        
        ; Uses a LOGFONTW structure to get the attributes of this Font object.
        GetLogFontW()
        {
            Return
        }
        
        ; Returns the font size (commonly called the em size)                                 ; of this Font object. The size is in the units of this Font object.
        GetSize()
        {
            Return
        }
        
        ; Gets the style of this font's typeface.
        GetStyle()
        {
            Return
        }
        
        ; Returns the unit of measure of this Font object.
        GetUnit()
        {
            Return
        }
        
        ; Determines whether this Font object was created successfully.
        IsAvailable()
        {
            Return
        }
        
                                                                                                                                                                                           
    FontCollection                          
        
        ; ## Methods ##
        ; Creates an empty FontCollection object.
        FontCollection()
        {
            Return
        }
        
        ; Creates an empty FontCollection object.
        FontCollection()
        {
            Return
        }
        
        ; Gets the font families contained in this font collection.
        GetFamilies()
        {
            Return
        }
        
        ; Gets the number of font families contained in this font collection.
        GetFamilyCount()
        {
            Return
        }
        
        ; Returns a value that indicates the result of this FontCollection object's previous method call.
        GetLastStatus()
        {
            Return
        }
        
    }
        
    ; Encapsulates a set of fonts that make up a font family. A font family is a group of fonts that have the same typeface but different styles.
    Class FontFamily
    {
        ; ## Methods ##
        ; Creates a new FontFamily object based on this FontFamily object.
        Clone()
        {
            Return
        }
        
        ; Creates an empty FontFamily object.
        FontFamily()
        {
            Return
        }
        
        ; Lists the constructors of the FontFamily class. For a complete class listing, see FontFamilyClass.
        FontFamily()
        {
            Return
        }
        
        ; Creates a FontFamily object based on a specified font family.
        FontFamily()
        {
            Return
        }
        
        ; Lists the constructors of the FontFamily class. For a complete class listing, see FontFamilyClass.
        FontFamily()
        {
            Return
        }
        
        ; Gets a FontFamily object that specifies a generic monospace typeface.
        GenericMonospace()
        {
            Return
        }
        
        ; Gets a FontFamily object that specifies a generic sans serif typeface.
        GenericSansSerif()
        {
            Return
        }
        
        ; Gets a FontFamily object that represents a generic serif typeface.
        GenericSerif()
        {
            Return
        }
        
        ; Gets the cell ascent, in design units, of this font family for the specified style or style combination.
        GetCellAscent()
        {
            Return
        }
        
        ; Gets the cell descent, in design units, of this font family for the specified style or style combination.
        GetCellDescent()
        {
            Return
        }
        
        ; Gets the size (commonly called em size or em height), in design units, of this font family.
        GetEmHeight()
        {
            Return
        }
        
        ; Gets the name of this font family.
        GetFamilyName()
        {
            Return
        }
        
        ; Returns a value that indicates the nature of this FontFamily object's most recent method failure.
        GetLastStatus()
        {
            Return
        }
        
        ; Gets the line spacing, in design units, of this font family for the specified style or style combination. The line spacing is the vertical distance between the base lines of two consecutive lines of text.
        GetLineSpacing()
        {
            Return
        }
        
        ; Determines whether this FontFamily object was created successfully.
        IsAvailable()
        {
            Return
        }
        
        ; Determines whether the specified style is available for this font family.
        IsStyleAvailable()
        {
            Return
        }
        
                                                                                                                                                                                               
    GdiplusBase                                                                                                             
        
        ; ## Methods ##
        operator delete()                                                   ; The operator delete method deallocates memory for one GDI+ object.
        operator delete[]()                                                 ; The operator delete[] method allocates memory for an array of GDI+ objects.
        operator new()                                                      ; The operator new method allocates memory for one GDI+ object.
        operator new[]()                                                    ; The operator new[] method allocates memory for an array of GDI+ objects.
                                                                                                            
    Graphics
        
        ; ## Methods ##
        ; Adds a text comment to an existing metafile.
        AddMetafileComment()
        {
            Return
        }
        
        ; Begins a new graphics container.
        BeginContainer()
        {
            Return
        }
        
        ; Begins a new graphics container.
        BeginContainer()
        {
            Return
        }
        
        ; Begins a new graphics container.              
        BeginContainer()
        {
            Return
        }
        
        ; Clears a Graphicsobject to a specified color.
        Clear()
        {
            Return
        }
        
        ; Draws an arc. The arc is part of an ellipse.
        DrawArc()
        {
            Return
        }
        
        ; Draws an arc. The arc is part of an ellipse.
        DrawArc()
        {
            Return
        }
        
        ; Draws an arc. The arc is part of an ellipse.
        DrawArc()
        {
            Return
        }
        
        ; Draws an arc.
        DrawArc()
        {
            Return
        }
        
        ; Draws a Bezier spline.
        DrawBezier()
        {
            Return
        }
        
        ; Draws a Bezier spline.
        DrawBezier()
        {
            Return
        }
        
        ; Draws a Bezier spline.
        DrawBezier()
        {
            Return
        }
        
        ; Draws a Bezier spline.
        DrawBezier()
        {
            Return
        }
        
        ; Draws a sequence of connected B?zier splines.
        DrawBeziers()
        {
            Return
        }
        
        ; Draws a sequence of connected Bezier splines.
        DrawBeziers()
        {
            Return
        }
        
        ; Draws the image stored in a CachedBitmap object.
        DrawCachedBitmap()
        {
            Return
        }
        
        ; Draws a closed cardinal spline.
        DrawClosedCurve()
        {
            Return
        }
        
        ; Draws a closed cardinal spline.
        DrawClosedCurve()
        {
            Return
        }
        
        ; Draws a closed cardinal spline.
        DrawClosedCurve()
        {
            Return
        }
        
        ; Draws a closed cardinal spline.
        DrawClosedCurve()
        {
            Return
        }
        
        ; Draws a cardinal spline.
        DrawCurve()
        {
            Return
        }
        
        ; Draws a cardinal spline.
        DrawCurve()
        {
            Return
        }
        
        ; Draws a cardinal spline.
        DrawCurve()
        {
            Return
        }
        
        ; Draws a cardinal spline.
        DrawCurve()
        {
            Return
        }
        
        ; Draws a cardinal spline.
        DrawCurve()
        {
            Return
        }
        
        ; Draws a cardinal spline.
        DrawCurve()
        {
            Return
        }
        
        ; Draws characters at the specified positions. The method gives the client complete control over the appearance of text. The method assumes that the client has already set up the format and layout to be applied.
        DrawDriverString()
        {
            Return
        }
        
        ; Draws an ellipse.
        DrawEllipse()
        {
            Return
        }
        
        ; Draws an ellipse.
        DrawEllipse()
        {
            Return
        }
        
        ; Draws an ellipse.
        DrawEllipse()
        {
            Return
        }
        
        ; Draws an ellipse.
        DrawEllipse()
        {
            Return
        }
        
        ; Draws an image.
        DrawImage()
        {
            Return
        }
        
        ; Draws an image.
        DrawImage()
        {
            Return
        }
        
        ; Draws an image.
        DrawImage()
        {
            Return
        }
        
        ; Draws an image.
        DrawImage()
        {
            Return
        }
        
        ; Draws an image.
        DrawImage()
        {
            Return
        }
        
        ; Draws an image.
        DrawImage()
        {
            Return
        }
        
        ; Draws an image.
        DrawImage()
        {
            Return
        }
        
        ; Draws an image.
        DrawImage()
        {
            Return
        }
        
        ; Draws an image.
        DrawImage()
        {
            Return
        }
        
        ; Draws a specified portion of an image at a specified location.
        DrawImage()
        {
            Return
        }
        
        ; Draws an image.
        DrawImage()
        {
            Return
        }
        
        ; Draws an image at a specified location.
        DrawImage()
        {
            Return
        }
        
        ; Draws an image.
        DrawImage()
        {
            Return
        }
        
        ; Draws an image.
        DrawImage()
        {
            Return
        }
        
        ; Draws an image at a specified location.
        DrawImage()
        {
            Return
        }
        
        ; Draws an image.
        DrawImage()
        {
            Return
        }
        
        ; Draws an image.
        DrawImage()
        {
            Return
        }
        
        ; Draws a portion of an image after applying a specified effect.
        DrawImage()
        {
            Return
        }
        
        ; Draws a line that connects two points.
        DrawLine()
        {
            Return
        }
        
        ; Draws a line that connects two points.
        DrawLine()
        {
            Return
        }
        
        ; Draws a line that connects two points.
        DrawLine()
        {
            Return
        }
        
        ; Draws a line that connects two points.
        DrawLine()
        {
            Return
        }
        
        ; Draws a sequence of connected lines.
        DrawLines()
        {
            Return
        }
        
        ; Draws a sequence of connected lines.
        DrawLines()
        {
            Return
        }
        
        ; Draws a sequence of lines and curves defined by a GraphicsPath object.
        DrawPath()
        {
            Return
        }
        
        ; Draws a pie.
        DrawPie()
        {
            Return
        }
        
        ; Draws a pie.
        DrawPie()
        {
            Return
        }
        
        ; Draws a pie.
        DrawPie()
        {
            Return
        }
        
        ; Draws a pie.
        DrawPie()
        {
            Return
        }
        
        ; Draws a polygon.
        DrawPolygon()
        {
            Return
        }
        
        ; Draws a polygon.
        DrawPolygon()
        {
            Return
        }
        
        ; Draws a rectangle.
        DrawRectangle()
        {
            Return
        }
        
        ; Draws a rectangle.
        DrawRectangle()
        {
            Return
        }
        
        ; Draws a rectangle.
        DrawRectangle()
        {
            Return
        }
        
        ; Draws a rectangle.
        DrawRectangle()
        {
            Return
        }
        
        ; Draws a sequence of rectangles.
        DrawRectangles()
        {
            Return
        }
        
        ; Draws a sequence of rectangles.
        DrawRectangles()
        {
            Return
        }
        
        ; Draws a string based on a font and an origin for the string.
        DrawString()
        {
            Return
        }
        
        ; Draws a string based on a font, a string origin, and a format.
        DrawString()
        {
            Return
        }
        
        ; Draws a string based on a font, a layout rectangle, and a format.
        DrawString()
        {
            Return
        }
        
        ; Closes a graphics container that was previously opened by the Graphics::BeginContainer method.
        EndContainer()
        {
            Return
        }
        
        ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        EnumerateMetafile()
        {
            Return
        }
        
        ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        EnumerateMetafile()
        {
            Return
        }
        
        ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        EnumerateMetafile()
        {
            Return
        }
        
        ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        EnumerateMetafile()
        {
            Return
        }
        
        ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        EnumerateMetafile()
        {
            Return
        }
        
        ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        EnumerateMetafile()
        {
            Return
        }
        
        ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        EnumerateMetafile()
        {
            Return
        }
        
        ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        EnumerateMetafile()
        {
            Return
        }
        
        ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        EnumerateMetafile()
        {
            Return
        }
        
        ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        EnumerateMetafile()
        {
            Return
        }
        
        ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        EnumerateMetafile()
        {
            Return
        }
        
        ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
        EnumerateMetafile()
        {
            Return
        }
        
        ; Updates the clipping region to the portion of itself that does not intersect the specified rectangle.
        ExcludeClip()
        {
            Return
        }
        
        ; Updates the clipping region to the portion of itself that does not intersect the specified rectangle.
        ExcludeClip()
        {
            Return
        }
        
        ; Updates the clipping region with the portion of itself that does not overlap the specified region.
        ExcludeClip()
        {
            Return
        }
        
        ; Creates a closed cardinal spline from an array of points and uses a brush to fill the interior of the spline.
        FillClosedCurve()
        {
            Return
        }
        
        ; Creates a closed cardinal spline from an array of points and uses a brush to fill, according to a specified mode, the interior of the spline.
        FillClosedCurve()
        {
            Return
        }
        
        ; Creates a closed cardinal spline from an array of points and uses a brush to fill the interior of the spline.
        FillClosedCurve()
        {
            Return
        }
        
        ; Creates a closed cardinal spline from an array of points and uses a brush to fill, according to a specified mode, the interior of the spline.
        FillClosedCurve()
        {
            Return
        }
        
        ; Uses a brush to fill the interior of an ellipse that is specified by a rectangle.
        FillEllipse()
        {
            Return
        }
        
        ; Uses a brush to fill the interior of an ellipse that is specified by a rectangle.
        FillEllipse()
        {
            Return
        }
        
        ; Uses a brush to fill the interior of an ellipse that is specified by coordinates and dimensions.
        FillEllipse()
        {
            Return
        }
        
        ; Uses a brush to fill the interior of an ellipse that is specified by coordinates and dimensions.
        FillEllipse()
        {
            Return
        }
        
        ; Uses a brush to fill the interior of a path. If a figure in the path is not closed, this method treats the nonclosed figure as if it were closed by a straight line that connects the figure's starting and ending points.
        FillPath()
        {
            Return
        }
        
        ; Uses a brush to fill the interior of a pie.
        FillPie()
        {
            Return
        }
        
        ; Uses a brush to fill the interior of a pie.
        FillPie()
        {
            Return
        }
        
        ; Uses a brush to fill the interior of a pie.
        FillPie()
        {
            Return
        }
        
        ; Uses a brush to fill the interior of a pie.
        FillPie()
        {
            Return
        }
        
        ; Uses a brush to fill the interior of a polygon.
        FillPolygon()
        {
            Return
        }
        
        ; Uses a brush to fill the interior of a polygon.
        FillPolygon()
        {
            Return
        }
        
        ; Uses a brush to fill the interior of a polygon.
        FillPolygon()
        {
            Return
        }
        
        ; Uses a brush to fill the interior of a polygon.
        FillPolygon()
        {
            Return
        }
        
        ; Uses a brush to fill the interior of a rectangle.
        FillRectangle()
        {
            Return
        }
        
        ; Uses a brush to fill the interior of a rectangle.
        FillRectangle()
        {
            Return
        }
        
        ; Uses a brush to fill the interior of a rectangle.
        FillRectangle()
        {
            Return
        }
        
        ; Uses a brush to fill the interior of a rectangle.
        FillRectangle()
        {
            Return
        }
        
        ; Uses a brush to fill the interior of a sequence of rectangles.
        FillRectangles()
        {
            Return
        }
        
        ; Uses a brush to fill the interior of a sequence of rectangles.
        FillRectangles()
        {
            Return
        }
        
        ; Uses a brush to fill a specified region.
        FillRegion()
        {
            Return
        }
        
        ; Flushes all pending graphics operations.
        Flush()
        {
            Return
        }
        
        ; Creates a Graphics object that is associated with a specified device context.
        FromHDC()
        {
            Return
        }
        
        ; Creates a Graphics object that is associated with a specified device context and a specified device.
        FromHDC()
        {
            Return
        }
        
        ; Creates a Graphicsobject that is associated with a specified window.
        FromHWND()
        {
            Return
        }
        
        ; Creates a Graphicsobject that is associated with a specified Image object.
        FromImage()
        {
            Return
        }
        
        ; Gets the clipping region of this Graphics object.
        GetClip()
        {
            Return
        }
        
        ; Gets a rectangle that encloses the clipping region of this Graphics object.
        GetClipBounds()
        {
            Return
        }
        
        ; Gets a rectangle that encloses the clipping region of this Graphics object.
        GetClipBounds()
        {
            Return
        }
        
        ; Gets the compositing mode currently set for this Graphics object.
        GetCompositingMode()
        {
            Return
        }
        
        ; Gets the compositing quality currently set for this Graphics object.
        GetCompositingQuality()
        {
            Return
        }
        
        ; Gets the horizontal resolution, in dots per inch, of the display device associated with this Graphics object.
        GetDpiX()
        {
            Return
        }
        
        ; Gets the vertical resolution, in dots per inch, of the display device associated with this Graphics object.
        GetDpiY()
        {
            Return
        }
        
        ; Gets a Windows halftone palette.
        GetHalftonePalette()
        {
            Return
        }
        
        ; Gets a handle to the device context associated with this Graphics object.
        GetHDC()
        {
            Return
        }
        
        ; Gets the interpolation mode currently set for this Graphics object. The interpolation mode determines the algorithm that is used when images are scaled or rotated.
        GetInterpolationMode()
        {
            Return
        }
        
        ; Returns a value that indicates the nature of this Graphics object's most recent method failure.
        GetLastStatus()
        {
            Return
        }
        
        ; Gets the nearest color to the color that is passed in. This method works on 8-bits per pixel or lower display devices for which there is an 8-bit color palette.
        GetNearestColor()
        {
            Return
        }
        
        ; Gets the scaling factor currently set for the page transformation of this Graphics object. The page transformation converts page coordinates to device coordinates.
        GetPageScale()
        {
            Return
        }
        
        ; Gets the unit of measure currently set for this Graphics object.
        GetPageUnit()
        {
            Return
        }
        
        ; Gets the pixel offset mode currently set for this Graphics object.
        GetPixelOffsetMode()
        {
            Return
        }
        
        ; Gets the rendering origin currently set for this Graphics object.
        GetRenderingOrigin()
        {
            Return
        }
        
        ; Determines whether smoothing (antialiasing)                                 ; is applied to the Graphics object.
        GetSmoothingMode()
        {
            Return
        }
        
        ; Gets the contrast value currently set for this Graphics object. The contrast value is used for antialiasing text.
        GetTextContrast()
        {
            Return
        }
        
        ; Returns the text rendering mode currently set for this Graphics object.
        GetTextRenderingHint()
        {
            Return
        }
        
        ; Gets the world transformation matrix of this Graphics object.
        GetTransform()
        {
            Return
        }
        
        ; Gets a rectangle that encloses the visible clipping region of this Graphics object.
        GetVisibleClipBounds()
        {
            Return
        }
        
        ; Gets a rectangle that encloses the visible clipping region of this Graphics object.
        GetVisibleClipBounds()
        {
            Return
        }
        
        ; Lists the constructors of the Graphics class. For a complete class listing, see Graphics Class.
        Graphics()
        {
            Return
        }
        
        ; Lists the constructors of the Graphics class. For a complete class listing, see Graphics Class.
        Graphics()
        {
            Return
        }
        
        ; Creates a Graphics object that is associated with a specified device context.
        Graphics()
        {
            Return
        }
        
        ; Creates a Graphics object that is associated with a specified device context and a specified device.
        Graphics()
        {
            Return
        }
        
        ; Creates a Graphics object that is associated with a specified window.
        Graphics()
        {
            Return
        }
        
        ; Creates a Graphics object that is associated with an Image object.
        Graphics()
        {
            Return
        }
        
        ; Updates the clipping region of this Graphics object to the portion of the specified rectangle that intersects with the current clipping region of this Graphics object.
        IntersectClip()
        {
            Return
        }
        
        ; Updates the clipping region of this Graphics object.
        IntersectClip()
        {
            Return
        }
        
        ; Updates the clipping region of this Graphics object to the portion of the specified region that intersects with the current clipping region of this Graphics object.
        IntersectClip()
        {
            Return
        }
        
        ; Determines whether the clipping region of this Graphics object is empty.
        IsClipEmpty()
        {
            Return
        }
        
        ; Determines whether the specified point is inside the visible clipping region of this Graphics object.
        IsVisible()
        {
            Return
        }
        
        ; Determines whether the specified point is inside the visible clipping region of this Graphics object.
        IsVisible()
        {
            Return
        }
        
        ; Determines whether the specified rectangle intersects the visible clipping region of this Graphics object.
        IsVisible()
        {
            Return
        }
        
        ; Determines whether the specified rectangle intersects the visible clipping region of this Graphics object.
        IsVisible()
        {
            Return
        }
        
        ; Determines whether the specified point is inside the visible clipping region of this Graphics object.
        IsVisible()
        {
            Return
        }
        
        ; Determines whether the specified rectangle intersects the visible clipping region of this Graphics object.
        IsVisible()
        {
            Return
        }
        
        ; Determines whether the specified point is inside the visible clipping region of this Graphics object.
        IsVisible()
        {
            Return
        }
        
        ; Determines whether the specified rectangle intersects the visible clipping region of this Graphics object.
        IsVisible()
        {
            Return
        }
        
        ; Determines whether the visible clipping region of this Graphics object is empty. The visible clipping region is the intersection of the clipping region of this Graphics object and the clipping region of the window.
        IsVisibleClipEmpty()
        {
            Return
        }
        
        ; Gets a set of regions each of which bounds a range of character positions within a string.
        MeasureCharacterRanges()
        {
            Return
        }
        
        ; Measures the bounding box for the specified characters and their corresponding positions.
        MeasureDriverString()
        {
            Return
        }
        
        ; Measures the extent of the string in the specified font, format, and layout rectangle.
        MeasureString()
        {
            Return
        }
        
        ; Measures the extent of the string in the specified font and layout rectangle.
        MeasureString()
        {
            Return
        }
        
        ; Measures the extent of the string in the specified font, format, and layout rectangle.
        MeasureString()
        {
            Return
        }
        
        ; Measures the extent of the string in the specified font and layout rectangle.
        MeasureString()
        {
            Return
        }
        
        ; Measures the extent of the string in the specified font, format, and layout rectangle.
        MeasureString()
        {
            Return
        }
        
        ; Updates this Graphics object's world transformation matrix with the product of itself and another matrix.
        MultiplyTransform()
        {
            Return
        }
        
        ; Releases a device context handle obtained by a previous call to the Graphics::GetHDC method of this Graphics object.
        ReleaseHDC()
        {
            Return
        }
        
        ; Sets the clipping region of this Graphics object to an infinite region.
        ResetClip()
        {
            Return
        }
        
        ; Sets the world transformation matrix of this Graphics object to the identity matrix.
        ResetTransform()
        {
            Return
        }
        
        ; Sets the state of this Graphics object to the state stored by a previous call to the Graphics::Save method of this Graphics object.
        Restore()
        {
            Return
        }
        
        ; Updates the world transformation matrix of this Graphics object with the product of itself and a rotation matrix.
        RotateTransform()
        {
            Return
        }
        
        ; Saves the current state (transformations, clipping region, and quality settings)                                 ; of this Graphics object. You can restore the state later by calling the Graphics::Restore method.
        Save()
        {
            Return
        }
        
        ; Updates this Graphics object's world transformation matrix with the product of itself and a scaling matrix.
        ScaleTransform()
        {
            Return
        }
        
        ; Not used in Windows GDI+ versions 1.0 and 1.1.
        SetAbort()
        {
            Return
        }
        
        ; Updates the clipping region of this Graphics object.
        SetClip()
        {
            Return
        }
        
        ; Updates the clipping region of this Graphics object to a region that is the combination of itself and the region specified by a graphics path.
        SetClip()
        {
            Return
        }
        
        ; Updates the clipping region of this Graphics object to a region that is the combination of itself and a rectangle.
        SetClip()
        {
            Return
        }
        
        ; Updates the clipping region of this Graphics object to a region that is the combination of itself and a rectangle.
        SetClip()
        {
            Return
        }
        
        ; Updates the clipping region of this Graphics object to a region that is the combination of itself and the region specified by a Region object.
        SetClip()
        {
            Return
        }
        
        ; Updates the clipping region of this Graphics object to a region that is the combination of itself and a Windows Graphics Device Interface (GDI)                                 ; region.
        SetClip()
        {
            Return
        }
        
        ; Sets the compositing mode of this Graphics object.
        SetCompositingMode()
        {
            Return
        }
        
        ; Sets the compositing quality of this Graphics object.
        SetCompositingQuality()
        {
            Return
        }
        
        ; Sets the interpolation mode of this Graphics object. The interpolation mode determines the algorithm that is used when images are scaled or rotated.
        SetInterpolationMode()
        {
            Return
        }
        
        ; Sets the scaling factor for the page transformation of this Graphics object. The page transformation converts page coordinates to device coordinates.
        SetPageScale()
        {
            Return
        }
        
        ; Sets the unit of measure for this Graphics object. The page unit belongs to the page transformation, which converts page coordinates to device coordinates.
        SetPageUnit()
        {
            Return
        }
        
        ; Sets the pixel offset mode of this Graphics object.
        SetPixelOffsetMode()
        {
            Return
        }
        
        ; Sets the rendering origin of this Graphics object. The rendering origin is used to set the dither origin for 8-bits-per-pixel and 16-bits-per-pixel dithering and is also used to set the origin for hatch brushes.
        SetRenderingOrigin()
        {
            Return
        }
        
        ; Sets the rendering quality of the Graphics object.
        SetSmoothingMode()
        {
            Return
        }
        
        ; Sets the contrast value of this Graphics object. The contrast value is used for antialiasing text.
        SetTextContrast()
        {
            Return
        }
        
        ; Sets the text rendering mode of this Graphics object.
        SetTextRenderingHint()
        {
            Return
        }
        
        ; Sets the world transformation of this Graphics object.
        SetTransform()
        {
            Return
        }
        
        ; Converts an array of points from one coordinate space to another. The conversion is based on the current world and page transformations of this Graphics object.
        TransformPoints()
        {
            Return
        }
        
        ; Converts an array of points from one coordinate space to another. The conversion is based on the current world and page transformations of this Graphics object.
        TransformPoints()
        {
            Return
        }
        
        ; Translates the clipping region of this Graphics object.
        TranslateClip()
        {
            Return
        }
        
        ; Translates the clipping region of this Graphics object.
        TranslateClip()
        {
            Return
        }
        
        ; Updates this Graphics object's world transformation matrix with the product of itself and a translation matrix.
        TranslateTransform()
        {
            Return
        }
        
    }
        
    ; Stores a sequence of lines, curves, and shapes. You can also place markers in the sequence, so that you can draw selected portions of the path.
    Class GraphicsPath
    {
        ; ## Methods ##
        ; Adds an elliptical arc to the current figure of this path.
        AddArc()
        {
            Return
        }
        
        ; Adds an elliptical arc to the current figure of this path.
        AddArc()
        {
            Return
        }
        
        ; Adds an elliptical arc to the current figure of this path.
        AddArc()
        {
            Return
        }
        
        ; Adds an elliptical arc to the current figure of this path.
        AddArc()
        {
            Return
        }
        
        ; Adds a Bezier spline to the current figure of this path.
        AddBezier()
        {
            Return
        }
        
        ; Adds a Bezier spline to the current figure of this path.
        AddBezier()
        {
            Return
        }
        
        ; Adds a Bezier spline to the current figure of this path.
        AddBezier()
        {
            Return
        }
        
        ; Adds a Bezier spline to the current figure of this path.
        AddBezier()
        {
            Return
        }
        
        ; Adds a sequence of connected Bezier splines to the current figure of this path.
        AddBeziers()
        {
            Return
        }
        
        ; Adds a sequence of connected Bezier splines to the current figure of this path.
        AddBeziers()
        {
            Return
        }
        
        ; Adds a closed cardinal spline to this path.
        AddClosedCurve()
        {
            Return
        }
        
        ; Adds a closed cardinal spline to this path.
        AddClosedCurve()
        {
            Return
        }
        
        ; Adds a closed cardinal spline to this path.
        AddClosedCurve()
        {
            Return
        }
        
        ; Adds a closed cardinal spline to this path.
        AddClosedCurve()
        {
            Return
        }
        
        ; Adds a cardinal spline to the current figure of this path.
        AddCurve()
        {
            Return
        }
        
        ; Adds a cardinal spline to the current figure of this path.
        AddCurve()
        {
            Return
        }
        
        ; Adds a cardinal spline to the current figure of this path.
        AddCurve()
        {
            Return
        }
        
        ; Adds a cardinal spline to the current figure of this path.
        AddCurve()
        {
            Return
        }
        
        ; Adds a cardinal spline to the current figure of this path.
        AddCurve()
        {
            Return
        }
        
        ; Adds a cardinal spline to the current figure of this path.
        AddCurve()
        {
            Return
        }
        
        ; Adds an ellipse to this path.
        AddEllipse()
        {
            Return
        }
        
        ; Adds an ellipse to this path.
        AddEllipse()
        {
            Return
        }
        
        ; Adds an ellipse to this path.
        AddEllipse()
        {
            Return
        }
        
        ; Adds an ellipse to this path.
        AddEllipse()
        {
            Return
        }
        
        ; Adds a line to the current figure of this path.
        AddLine()
        {
            Return
        }
        
        ; Adds a line to the current figure of this path.
        AddLine()
        {
            Return
        }
        
        ; Adds a line to the current figure of this path.
        AddLine()
        {
            Return
        }
        
        ; Adds a line to the current figure of this path.
        AddLine()
        {
            Return
        }
        
        ; Adds a sequence of connected lines to the current figure of this path.
        AddLines()
        {
            Return
        }
        
        ; Adds a sequence of connected lines to the current figure of this path.
        AddLines()
        {
            Return
        }
        
        ; Adds a path to this path.
        AddPath()
        {
            Return
        }
        
        ; Adds a pie to this path.
        AddPie()
        {
            Return
        }
        
        ; Adds a pie to this path.
        AddPie()
        {
            Return
        }
        
        ; Adds a pie to this path.
        AddPie()
        {
            Return
        }
        
        ; Adds a pie to this path.
        AddPie()
        {
            Return
        }
        
        ; Adds a polygon to this path.
        AddPolygon()
        {
            Return
        }
        
        ; Adds a polygon to this path.
        AddPolygon()
        {
            Return
        }
        
        ; Adds a rectangle to this path.
        AddRectangle()
        {
            Return
        }
        
        ; Adds a rectangle to this path.
        AddRectangle()
        {
            Return
        }
        
        ; Adds a sequence of rectangles to this path
        AddRectangles()
        {
            Return
        }
        
        ; Adds a sequence of rectangles to this path.
        AddRectangles()
        {
            Return
        }
        
        ; Adds the outlines of a string to this path.
        AddString()
        {
            Return
        }
        
        ; Adds the outline of a string to this path.
        AddString()
        {
            Return
        }
        
        ; Adds the outline of a string to this path.
        AddString()
        {
            Return
        }
        
        ; Adds the outline of a string to this path.
        AddString()
        {
            Return
        }
        
        ; Clears the markers from this path.
        ClearMarkers()
        {
            Return
        }
        
        ; Creates a new GraphicsPath object, and initializes it with the contents of this GraphicsPath object.
        Clone()
        {
            Return
        }
        
        ; Closes all open figures in this path.
        CloseAllFigures()
        {
            Return
        }
        
        ; Closes the current figure of this path.
        CloseFigure()
        {
            Return
        }
        
        ; Applies a transformation to this path and converts each curve in the path to a sequence of connected lines.
        Flatten()
        {
            Return
        }
        
        ; Gets a bounding rectangle for this path.
        GetBounds()
        {
            Return
        }
        
        ; Gets a bounding rectangle for this path.
        GetBounds()
        {
            Return
        }
        
        ; Gets the fill mode of this path.
        GetFillMode()
        {
            Return
        }
        
        ; Gets the ending point of the last figure in this path.
        GetLastPoint()
        {
            Return
        }
        
        ; Returns a value that indicates the nature of this GraphicsPath object's most recent method failure.
        GetLastStatus()
        {
            Return
        }
        
        ; Gets an array of points and an array of point types from this path. Together, these two arrays define the lines, curves, figures, and markers of this path.
        GetPathData()
        {
            Return
        }
        
        ; Gets this path's array of points. The array contains the endpoints and control points of the lines and Bezier splines that are used to draw the path.
        GetPathPoints()
        {
            Return
        }
        
        ; Gets this path's array of points.
        GetPathPoints()
        {
            Return
        }
        
        ; Gets this path's array of point types.
        GetPathTypes()
        {
            Return
        }
        
        ; Gets the number of points in this path's array of data points. This is the same as the number of types in the path's array of point types.
        GetPointCount()
        {
            Return
        }
        
        ; Lists the constructors of the GraphicsPath class. For a complete class listing, see GraphicsPath Class.
        GraphicsPath()
        {
            Return
        }
        
        ; Creates a GraphicsPath object based on an array of points, an array of types, and a fill mode.
        GraphicsPath()
        {
            Return
        }
        
        ; Creates a GraphicsPath object based on an array of points, an array of types, and a fill mode.
        GraphicsPath()
        {
            Return
        }
        
        ; Creates a GraphicsPath object and initializes the fill mode. This is the default constructor.
        GraphicsPath()
        {
            Return
        }
        
        ; Lists the constructors of the GraphicsPath class. For a complete class listing, see GraphicsPath Class.
        GraphicsPath()
        {
            Return
        }
        
        ; Determines whether a specified point touches the outline of this path when the path is drawn by a specified Graphicsobject and a specified pen.
        IsOutlineVisible()
        {
            Return
        }
        
        ; Determines whether a specified point touches the outline of a path.
        IsOutlineVisible()
        {
            Return
        }
        
        ; Determines whether a specified point touches the outline of this path when the path is drawn by a specified Graphics object and a specified pen.
        IsOutlineVisible()
        {
            Return
        }
        
        ; Determines whether a specified point touches the outline of this path when the path is drawn by a specified Graphics object and a specified pen.
        IsOutlineVisible()
        {
            Return
        }
        
        ; Determines whether a specified point lies in the area that is filled when this path is filled by a specified Graphics object.
        IsVisible()
        {
            Return
        }
        
        ; Determines whether a specified point lies in an area.
        IsVisible()
        {
            Return
        }
        
        ; Determines whether a specified point lies in the area that is filled when this path is filled by a specified Graphicsobject.
        IsVisible()
        {
            Return
        }
        
        ; Determines whether a specified point lies in the area that is filled when this path is filled by a specified Graphics object.
        IsVisible()
        {
            Return
        }
        
        ; Transforms and flattens this path, and then converts this path's data points so that they represent only the outline of the path.
        Outline()
        {
            Return
        }
        
        ; Empties the path and sets the fill mode to FillModeAlternate.
        Reset()
        {
            Return
        }
        
        ; Reverses the order of the points that define this path's lines and curves.
        Reverse()
        {
            Return
        }
        
        ; Sets the fill mode of this path.
        SetFillMode()
        {
            Return
        }
        
        ; Designates the last point in this path as a marker point.
        SetMarker()
        {
            Return
        }
        
        ; Starts a new figure without closing the current figure. Subsequent points added to this path are added to the new figure.
        StartFigure()
        {
            Return
        }
        
        ; Multiplies each of this path's data points by a specified matrix.
        Transform()
        {
            Return
        }
        
        ; Applies a warp transformation to this path. The GraphicsPath::Warp method also flattens (converts to a sequence of straight lines)                                 ; the path.
        Warp()
        {
            Return
        }
        
        ; Replaces this path with curves that enclose the area that is filled when this path is drawn by a specified pen. The GraphicsPath::Widen method also flattens the path.
        Widen()
        {
            Return
        }
        
    }
        
    ; Provides methods for isolating selected subsets of the path stored in a GraphicsPath object.
    Class GraphicsPathIterator
    {
        ; ## Methods ##
        ; Copies a subset of the path's data points to a PointF array and copies a subset of the path's point types to a BYTE array.
        CopyData()
        {
            Return
        }
        
        ; Copies the path's data points to a PointF array and copies the path's point types to a BYTE array.
        Enumerate()
        {
            Return
        }
        
        ; Returns the number of data points in the path.
        GetCount()
        {
            Return
        }
        
        ; Returns a value that indicates the nature of this GraphicsPathIterator object's most recent method failure.
        GetLastStatus()
        {
            Return
        }
        
        ; Returns the number of subpaths (also called figures)                                 ; in the path.
        GetSubpathCount()
        {
            Return
        }
        
        ; Creates a new GraphicsPathIterator object and associates it with a GraphicsPath object.
        GraphicsPathIterator()
        {
            Return
        }
        
        ; Copy constructor for GraphicsPathIterator.
        GraphicsPathIterator()
        {
            Return
        }
        
        ; Determines whether the path has any curves.
        HasCurve()
        {
            Return
        }
        
        ; Gets the next marker-delimited section of this iterator's associated path.
        NextMarker()
        {
            Return
        }
        
        ; Gets the starting index and the ending index of a section.
        NextMarker()
        {
            Return
        }
        
        ; Gets the starting index and the ending index of the next group of data points that all have the same type.
        NextPathType()
        {
            Return
        }
        
        ; Gets the next figure (subpath)                                 ; from this iterator's associated path.
        NextSubpath()
        {
            Return
        }
        
        ; Gets the starting index and the ending index of the next subpath.
        NextSubpath()
        {
            Return
        }
        
        ; Rewinds this iterator to the beginning of its associated path.
        Rewind()
        {
            Return
        }
        
    }
        
    ; Defines a rectangular brush with a hatch style, a foreground color, and a background color. There are six hatch styles.
    Class HatchBrush
    {
        ; ## Inherit ##   The HatchBrush class implements Brush.
        
        ; ## Methods ##
        ; Gets the background color of this hatch brush.
        GetBackgroundColor()
        {
            Return
        }
        
        ; Gets the foreground color of this hatch brush.
        GetForegroundColor()
        {
            Return
        }
        
        ; Gets the hatch style of this hatch brush.
        GetHatchStyle()
        {
            Return
        }
        
        ; Copy constructor for HatchBrush.
        HatchBrush()
        {
            Return
        }
        
        ; Creates a HatchBrush object based on a hatch style, foreground color, and background color.
        HatchBrush()
        {
            Return
        }
        
    }
        
    ; Enables you to change the hue, saturation, and lightness of a bitmap.
    Class HueSaturationLightness
    {
        ; ## Constructors ##
        ; ## Inherit ##   The HueSaturationLightness class implements Effect.
        
        ; ## Methods ##
        ; Gets the current values of the parameters of this HueSaturationLightness object.
        GetParameters()
        {
            Return
        }
        
        ; Creates a HueSaturationLightness object.
        HueSaturationLightness()
        {
            Return
        }
        
        ; Sets the parameters of this HueSaturationLightness object.
        SetParameters()
        {
            Return
        }
        
    }
        
    ; Provides methods for loading and saving raster images (bitmaps)                                 ; and vector images (metafiles).
    Class Image
    {
        ; ## Inherit ##   The Image class implements GdiplusBase.
        
        ; ## Methods ##
        ; Creates a new Image object and initializes it with the contents of this Image object.
        Clone()
        {
            Return
        }
        
        ; Retrieves the description and the data size of the first metadata item in this Image object.
        FindFirstItem()
        {
            Return
        }
        
        ; Used along with the Image::FindFirstItem method to enumerate the metadata items stored in this Image object.
        FindNextItem()
        {
            Return
        }
        
        ; Creates an Image object based on a file.
        FromFile()
        {
            Return
        }
        
        ; Creates a new Image object based on a stream.
        FromStream()
        {
            Return
        }
        
        ; Gets all the property items (metadata)                                 ; stored in this Image object.
        GetAllPropertyItems()
        {
            Return
        }
        
        ; Gets the bounding rectangle for this image.
        GetBounds()
        {
            Return
        }
        
        ; Gets a list of the parameters supported by a specified image encoder.
        GetEncoderParameterList()
        {
            Return
        }
        
        ; Gets the size, in bytes, of the parameter list for a specified image encoder.
        GetEncoderParameterListSize()
        {
            Return
        }
        
        ; Gets a set of flags that indicate certain attributes of this Image object.
        GetFlags()
        {
            Return
        }
        
        ; Gets the number of frames in a specified dimension of this Image object.
        GetFrameCount()
        {
            Return
        }
        
        ; Gets the number of frame dimensions in this Image object.
        GetFrameDimensionsCount()
        {
            Return
        }
        
        ; Gets the identifiers for the frame dimensions of this Image object.
        GetFrameDimensionsList()
        {
            Return
        }
        
        ; Gets the image height, in pixels, of this image.
        GetHeight()
        {
            Return
        }
        
        ; Gets the horizontal resolution, in dots per inch, of this image.
        GetHorizontalResolution()
        {
            Return
        }
        
        ; Gets one piece of metadata from this Image object.
        GetItemData()
        {
            Return
        }
        
        ; Returns a value that indicates the nature of this Image object's most recent method failure.
        GetLastStatus()
        {
            Return
        }
        
        ; Gets the ColorPalette of this Image object.
        GetPalette()
        {
            Return
        }
        
        ; Gets the size, in bytes, of the color palette of this Image object.
        GetPaletteSize()
        {
            Return
        }
        
        ; Gets the width and height of this image.
        GetPhysicalDimension()
        {
            Return
        }
        
        ; Gets the pixel format of this Image object.
        GetPixelFormat()
        {
            Return
        }
        
        ; Gets the number of properties (pieces of metadata)                                 ; stored in this Image object.
        GetPropertyCount()
        {
            Return
        }
        
        ; Gets a list of the property identifiers used in the metadata of this Image object.
        GetPropertyIdList()
        {
            Return
        }
        
        ; Gets a specified property item (piece of metadata)                                 ; from this Image object.
        GetPropertyItem()
        {
            Return
        }
        
        ; Gets the size, in bytes, of a specified property item of this Image object.
        GetPropertyItemSize()
        {
            Return
        }
        
        ; Gets the total size, in bytes, of all the property items stored in this Image object. The Image::GetPropertySize method also gets the number of property items stored in this Image object.
        GetPropertySize()
        {
            Return
        }
        
        ; Gets a globally unique identifier ( GUID)                                 ; that identifies the format of this Image object. GUIDs that identify various file formats are defined in Gdiplusimaging.h.
        GetRawFormat()
        {
            Return
        }
        
        ; Gets a thumbnail image from this Image object.
        GetThumbnailImage()
        {
            Return
        }
        
        ; Gets the type (bitmap or metafile)                                 ; of this Image object.
        GetType()
        {
            Return
        }
        
        ; Gets the vertical resolution, in dots per inch, of this image.
        GetVerticalResolution()
        {
            Return
        }
        
        ; Gets the width, in pixels, of this image.
        GetWidth()
        {
            Return
        }
        
        ; Lists the constructors of the Image class. For a complete class listing, see Image Class.
        Image()
        {
            Return
        }
        
        ; Creates an Image object based on a file.
        Image()
        {
            Return
        }
        
        ; Lists the constructors of the Image class. For a complete class listing, see Image Class.
        Image()
        {
            Return
        }
        
        ; Creates an Image object based on a stream.
        Image()
        {
            Return
        }
        
        ; Lists the constructors of the Image class. For a complete class listing, see Image Class.
        Image()
        {
            Return
        }
        
        ; Removes a property item (piece of metadata)                                 ; from this Image object.
        RemovePropertyItem()
        {
            Return
        }
        
        ; Rotates and flips this image.
        RotateFlip()
        {
            Return
        }
        
        ; Saves this image to a file.
        Save()
        {
            Return
        }
        
        ; Saves this image to a stream.
        Save()
        {
            Return
        }
        
        ; Adds a frame to a file or stream specified in a previous call to the Save method.
        SaveAdd()
        {
            Return
        }
        
        ; Adds a frame to a file or stream specified in a previous call to the Save method.
        SaveAdd()
        {
            Return
        }
        
        ; Selects the frame in this Image object specified by a dimension and an index.
        SelectActiveFrame()
        {
            Return
        }
        
        ; Sets the object whose Abort method is called periodically during time-consuming rendering operation.
        SetAbort()
        {
            Return
        }
        
        ; Sets the color palette of this Image object.
        SetPalette()
        {
            Return
        }
        
        ; Sets a property item (piece of metadata)                                 ; for this Image object. If the item already exists, then its contents are updated; otherwise, a new item is added.
        SetPropertyItem()
        {
            Return
        }
        
    }
        
    ; Contains information about how bitmap and metafile colors are manipulated during rendering.                                                                    
    Class ImageAttributes
    {
        ; ## Inherit ##   The ImageAttributes class implements GdiplusBase.
        
        ; ## Methods ##
        ; Clears the brush color-remap table of this ImageAttributes object.
        ClearBrushRemapTable()
        {
            Return
        }
        
        ; Clears the color key (transparency range)                                 ; for a specified category.
        ClearColorKey()
        {
            Return
        }
        
        ; Clears the color-adjustment matrix and the grayscale-adjustment matrix for a specified category.
        ClearColorMatrices()
        {
            Return
        }
        
        ; Clears the color-adjustment matrix for a specified category.
        ClearColorMatrix()
        {
            Return
        }
        
        ; Disables gamma correction for a specified category.
        ClearGamma()
        {
            Return
        }
        
        ; Clears the NoOp setting for a specified category.
        ClearNoOp()
        {
            Return
        }
        
        ; Clears the cyan-magenta-yellow-black (CMYK)                                 ; output channel setting for a specified category.
        ClearOutputChannel()
        {
            Return
        }
        
        ; Clears the output channel color profile setting for a specified category.
        ClearOutputChannelColorProfile()
        {
            Return
        }
        
        ; Clears the color-remap table for a specified category.
        ClearRemapTable()
        {
            Return
        }
        
        ; Clears the threshold value for a specified category.
        ClearThreshold()
        {
            Return
        }
        
        ; Makes a copy of this ImageAttributes object.
        Clone()
        {
            Return
        }
        
        ; Adjusts the colors in a palette according to the adjustment settings of a specified category.
        GetAdjustedPalette()
        {
            Return
        }
        
        ; Returns a value that indicates the nature of this ImageAttributes object's most recent method failure.
        GetLastStatus()
        {
            Return
        }
        
        ; Creates an ImageAttributes object. This is the default constructor.
        ImageAttributes()
        {
            Return
        }
        
        ; Creates an ImageAttributes object. This is the default constructor.
        ImageAttributes()
        {
            Return
        }
        
        ; Creates an ImageAttributes object. This is the default constructor.
        ImageAttributes()
        {
            Return
        }
        
        ; Clears all color- and grayscale-adjustment settings for a specified category.
        Reset()
        {
            Return
        }
        
        ; Sets the color remap table for the brush category.
        SetBrushRemapTable()
        {
            Return
        }
        
        ; Sets the color key (transparency range)                                 ; for a specified category.
        SetColorKey()
        {
            Return
        }
        
        ; Sets the color-adjustment matrix and the grayscale-adjustment matrix for a specified category.
        SetColorMatrices()
        {
            Return
        }
        
        ; Sets the color-adjustment matrix for a specified category.
        SetColorMatrix()
        {
            Return
        }
        
        ; Sets the gamma value for a specified category.
        SetGamma()
        {
            Return
        }
        
        ; Turns off color adjustment for a specified category. You can call ImageAttributes::ClearNoOp to reinstate the color-adjustment settings that were in place before the call to ImageAttributes::SetNoOp.
        SetNoOp()
        {
            Return
        }
        
        ; Sets the CMYK output channel for a specified category.
        SetOutputChannel()
        {
            Return
        }
        
        ; Sets the output channel color-profile file for a specified category.
        SetOutputChannelColorProfile()
        {
            Return
        }
        
        ; Sets the color-remap table for a specified category.
        SetRemapTable()
        {
            Return
        }
        
        ; Sets the threshold (transparency range)                                 ; for a specified category.
        SetThreshold()
        {
            Return
        }
        
        ; Sets the color-adjustment matrix of a specified category to identity matrix.
        SetToIdentity()
        {
            Return
        }
        
        ; Sets the wrap mode of this ImageAttributes object.
        SetWrapMode()
        {
            Return
        }
        
    }
        
    ; Stores information about an image codec (encoder/decoder). GDI+ provides several built-in image codecs.                                                               
    Class ImageCodecInfo
    {
        ; ## Methods ##
    }
        
    ; Used to store and retrieve custom image metadata. Windows GDI+ supports custom metadata for JPEG, PNG, and GIF image files.                                                              
    Class ImageItemData
    {
        ; ## Methods ##
                                                                                                                                                                                   
    InstalledFontCollection                                                                                         
        ; ## Inherit ##   The InstalledFontCollection class implements FontCollection.                                                                                                                                                      
        
        ; ## Methods ##
        ; Creates an InstalledFontCollection object.
        InstalledFontCollection()
        {
            Return
        }
        
        ; Creates an InstalledFontCollection object.
        InstalledFontCollection()
        {
            Return
        }
        
    }
        
    ; Encompasses three bitmap adjustments: highlight, midtone, and shadow.                                                       
    Class Levels
    {
        ; ## Inherit ##   The Levels class implements Effect.                                                                                                                                                      
        
        ; ## Methods ##
        ; Gets the current values of the parameters of this Levels object.
        GetParameters()
        {
            Return
        }
        
        ; Creates a Levels object.
        Levels()
        {
            Return
        }
        
        ; Sets the parameters of this Levels object.
        SetParameters()
        {
            Return
        }
        
    }
        
    ; Defines a brush that paints a color gradient in which the color changes evenly from the starting boundary line of the linear gradient brush to the ending boundary line of the linear gradient brush.                                                                    
    Class LinearGradientBrush
    {
        ; ## Inherit ##   The LinearGradientBrush class implements Brush.
        
        ; ## Methods ##
        ; Gets the blend factors and their corresponding blend positions from a LinearGradientBrush object.
        GetBlend()
        {
            Return
        }
        
        ; Gets the number of blend factors currently set for this LinearGradientBrush object.
        GetBlendCount()
        {
            Return
        }
        
        ; Determines whether gamma correction is enabled for this LinearGradientBrush object.
        GetGammaCorrection()
        {
            Return
        }
        
        ; Gets the number of colors currently set to be interpolated for this linear gradient brush.
        GetInterpolationColorCount()
        {
            Return
        }
        
        ; Gets the colors currently set to be interpolated for this linear gradient brush and their corresponding blend positions.
        GetInterpolationColors()
        {
            Return
        }
        
        ; Gets the starting color and ending color of this linear gradient brush.
        GetLinearColors()
        {
            Return
        }
        
        ; Gets the rectangle that defines the boundaries of the gradient.
        GetRectangle()
        {
            Return
        }
        
        ; Lists the GetRectangle methods of the LinearGradientBrush class. For a complete list of methods for the LinearGradientBrush class, see LinearGradientBrush Methods.
        GetRectangle()
        {
            Return
        }
        
        ; Gets the transformation matrix of this linear gradient brush.
        GetTransform()
        {
            Return
        }
        
        ; Gets the wrap mode for this brush. The wrap mode determines how an area is tiled when it is painted with a brush.
        GetWrapMode()
        {
            Return
        }
        
        ; Lists the constructors of the LinearGradientBrush class. For a complete class listing, see LinearGradientBrush Class.
        LinearGradientBrush()
        {
            Return
        }
        
        ; Lists the constructors of the LinearGradientBrush class. For a complete class listing, see LinearGradientBrush Class.
        LinearGradientBrush()
        {
            Return
        }
        
        ; Creates a LinearGradientBrush object from a set of boundary points and boundary colors.
        LinearGradientBrush()
        {
            Return
        }
        
        ; Creates a LinearGradientBrush object based on a rectangle and mode of direction.
        LinearGradientBrush()
        {
            Return
        }
        
        ; Creates a LinearGradientBrush object from a rectangle and angle of direction.
        LinearGradientBrush()
        {
            Return
        }
        
        ; Creates a LinearGradientBrush object based on a rectangle and mode of direction.
        LinearGradientBrush()
        {
            Return
        }
        
        ; Creates a LinearGradientBrush object from a rectangle and angle of direction.
        LinearGradientBrush()
        {
            Return
        }
        
        ; Lists the constructors of the LinearGradientBrush class. For a complete class listing, see LinearGradientBrush Class.
        LinearGradientBrush()
        {
            Return
        }
        
        ; Updates this brush's transformation matrix with the product of itself and another matrix.
        MultiplyTransform()
        {
            Return
        }
        
        ; Resets the transformation matrix of this linear gradient brush to the identity matrix. This means that no transformation takes place.
        ResetTransform()
        {
            Return
        }
        
        ; Updates this brush's current transformation matrix with the product of itself and a rotation matrix.
        RotateTransform()
        {
            Return
        }
        
        ; Updates this brush's current transformation matrix with the product of itself and a scaling matrix.
        ScaleTransform()
        {
            Return
        }
        
        ; Sets the blend factors and the blend positions of this linear gradient brush to create a custom blend.
        SetBlend()
        {
            Return
        }
        
        ; Sets the blend shape of this linear gradient brush to create a custom blend based on a bell-shaped curve.
        SetBlendBellShape()
        {
            Return
        }
        
        ; Sets the blend shape of this linear gradient brush to create a custom blend based on a triangular shape.
        SetBlendTriangularShape()
        {
            Return
        }
        
        ; Specifies whether gamma correction is enabled for this linear gradient brush.
        SetGammaCorrection()
        {
            Return
        }
        
        ; Sets the colors to be interpolated for this linear gradient brush and their corresponding blend positions.
        SetInterpolationColors()
        {
            Return
        }
        
        ; Sets the starting color and ending color of this linear gradient brush.
        SetLinearColors()
        {
            Return
        }
        
        ; Sets the transformation matrix of this linear gradient brush.
        SetTransform()
        {
            Return
        }
        
        ; Sets the wrap mode of this linear gradient brush.
        SetWrapMode()
        {
            Return
        }
        
        ; Updates this brush's current transformation matrix with the product of itself and a translation matrix.
        TranslateTransform()
        {
            Return
        }
        
    }
        
    ; Represents a 3 ×3 matrix that, in turn, represents an affine transformation.
    Class Matrix
    {
        ; ## Inherit ##   The Matrix class implements GdiplusBase.
        
        ; ## Methods ##
        ; Creates a new Matrix object that is a copy of this Matrix object.
        Clone()
        {
            Return
        }
        
        ; Determines whether the elements of this matrix are equal to the elements of another matrix.
        Equals()
        {
            Return
        }
        
        ; Gets the elements of this matrix. The elements are placed in an array in the order m11, m12, m21, m22, m31, m32, where mij denotes the element in row i, column j.
        GetElements()
        {
            Return
        }
        
        ; Returns a value that indicates the nature of this Matrix object's most recent method failure.
        GetLastStatus()
        {
            Return
        }
        
        ; Replaces the elements of this matrix with the elements of its inverse, if this matrix is invertible.
        Invert()
        {
            Return
        }
        
        ; Determines whether this matrix is the identity matrix.
        IsIdentity()
        {
            Return
        }
        
        ; Determines whether this matrix is invertible.
        IsInvertible()
        {
            Return
        }
        
        ; Creates and initializes a Matrix object that represents the identity matrix.
        Matrix()
        {
            Return
        }
        
        ; Creates and initializes a Matrix object that represents the identity matrix.
        Matrix()
        {
            Return
        }
        
        ; Creates a Matrix object based on a rectangle and a point.
        Matrix()
        {
            Return
        }
        
        ; Creates a Matrix object based on a rectangle and a point.
        Matrix()
        {
            Return
        }
        
        ; Creates and initializes a Matrix object that represents the identity matrix.
        Matrix()
        {
            Return
        }
        
        ; Creates and initializes a Matrix object based on six numbers that define an affine transformation.
        Matrix()
        {
            Return
        }
        
        ; Updates this matrix with the product of itself and another matrix.
        Multiply()
        {
            Return
        }
        
        ; Gets the horizontal translation value of this matrix, which is the element in row 3, column 1.
        OffsetX()
        {
            Return
        }
        
        ; Gets the vertical translation value of this matrix, which is the element in row 3, column 2.
        OffsetY()
        {
            Return
        }
        
        ; Updates this matrix with the elements of the identity matrix.
        Reset()
        {
            Return
        }
        
        ; Updates this matrix with the product of itself and a rotation matrix.
        Rotate()
        {
            Return
        }
        
        ; Updates this matrix with the product of itself and a matrix that represents rotation about a specified point.
        RotateAt()
        {
            Return
        }
        
        ; Updates this matrix with the product of itself and a scaling matrix.
        Scale()
        {
            Return
        }
        
        ; Sets the elements of this matrix.
        SetElements()
        {
            Return
        }
        
        ; Updates this matrix with the product of itself and a shearing matrix.
        Shear()
        {
            Return
        }
        
        ; Multiplies each point in an array by this matrix. Each point is treated as a row matrix. The multiplication is performed with the row matrix on the left and this matrix on the right.
        TransformPoints()
        {
            Return
        }
        
        ; Lists the TransformPoints methods of the Matrix class. For a complete list of methods for the Matrix class, see Matrix Methods.
        TransformPoints()
        {
            Return
        }
        
        ; Multiplies each vector in an array by this matrix.
        TransformVectors()
        {
            Return
        }
        
        ; Lists the TransformVectors methods of the Matrix class. For a complete list of methods for the Matrix class, see Matrix Methods.
        TransformVectors()
        {
            Return
        }
        
        ; Updates this matrix with the product of itself and a translation matrix.
        Translate()
        {
            Return
        }
        
    }
        
    ; Defines a graphic metafile.
    Class Metafile
    {
        ; ## Inherit ##   The Metafile class implements Image.
        
        ; ## Methods ##
        ; Converts this Metafile object to the EMF+ format.
        ConvertToEmfPlus()
        {
            Return
        }
        
        ; Converts this Metafile object to the EMF+ format.
        ConvertToEmfPlus()
        {
            Return
        }
        
        ; Converts this Metafile object to the EMF+ format.
        ConvertToEmfPlus()
        {
            Return
        }
        
        ; Converts an enhanced-format metafile to a Windows Metafile Format (WMF)                                 ; metafile and stores the converted records in a specified buffer.
        EmfToWmfBits()
        {
            Return
        }
        
        ; Gets the rasterization limit currently set for this metafile.
        GetDownLevelRasterizationLimit()
        {
            Return
        }
        
        ; Gets a Windows handle to an Enhanced Metafile (EMF)                                 ; file.
        GetHENHMETAFILE()
        {
            Return
        }
        
        ; Gets the header.
        GetMetafileHeader()
        {
            Return
        }
        
        ; Gets the header.
        GetMetafileHeader()
        {
            Return
        }
        
        ; Gets the metafile header of this metafile.
        GetMetafileHeader()
        {
            Return
        }
        
        ; Gets the header.
        GetMetafileHeader()
        {
            Return
        }
        
        ; Gets the header.
        GetMetafileHeader()
        {
            Return
        }
        
        ; Lists the constructors of the Metafile class. For a complete class listing, see Metafile Class.
        Metafile()
        {
            Return
        }
        
        ; Creates a Metafile object for playback.
        Metafile()
        {
            Return
        }
        
        ; Lists the constructors of the Metafile class. For a complete class listing, see Metafile Class.
        Metafile()
        {
            Return
        }
        
        ; Creates a Metafile object for recording.
        Metafile()
        {
            Return
        }
        
        ; Creates a Metafile object for recording.
        Metafile()
        {
            Return
        }
        
        ; Creates a Metafile object for recording.
        Metafile()
        {
            Return
        }
        
        ; Creates a Metafile object for recording.
        Metafile()
        {
            Return
        }
        
        ; Creates a Metafile object for recording.
        Metafile()
        {
            Return
        }
        
        ; Creates a Metafile object for recording.
        Metafile()
        {
            Return
        }
        
        ; Creates a Windows GDI+ Metafile object for playback based on a Windows Graphics Device Interface (GDI)                                 ; Enhanced Metafile (EMF)                                 ; file.
        Metafile()
        {
            Return
        }
        
        ; Creates a Windows GDI+Metafile object for recording. The format will be placeable metafile.
        Metafile()
        {
            Return
        }
        
        ; Creates a Metafile object from an IStream interface for playback.
        Metafile()
        {
            Return
        }
        
        ; Creates a Metafile object for recording to an IStream interface.
        Metafile()
        {
            Return
        }
        
        ; Creates a Metafile object for recording to an IStream interface.
        Metafile()
        {
            Return
        }
        
        ; Creates a Metafile object for recording to an IStream interface.
        Metafile()
        {
            Return
        }
        
        ; Lists the constructors of the Metafile class. For a complete class listing, see Metafile Class.
        Metafile()
        {
            Return
        }
        
        ; The PlayRecord method plays a metafile record.
        PlayRecord()
        {
            Return
        }
        
        ; Sets the resolution for certain brush bitmaps that are stored in this metafile.
        SetDownLevelRasterizationLimit()
        {
            Return
        }
        
    }
        
    ; Stores properties of an associated metafile.
    Class MetafileHeader
    {
        ; ## Methods ##
        ; Gets the bounding rectangle for the associated metafile.
        GetBounds()
        {
            Return
        }
        
        ; Gets the horizontal dots per inch of the associated metafile.
        GetDpiX()
        {
            Return
        }
        
        ; Gets the vertical dots per inch of the associated metafile.
        GetDpiY()
        {
            Return
        }
        
        ; Gets an ENHMETAHEADER3 structure that contains properties of the associated metafile.
        GetEmfHeader()
        {
            Return
        }
        
        ; Gets a flag that indicates whether the associated metafile was recorded against a video display device context.
        GetEmfPlusFlags()
        {
            Return
        }
        
        ; Gets the size, in bytes, of the metafile.
        GetMetafileSize()
        {
            Return
        }
        
        ; Gets the type of the associated metafile.
        GetType()
        {
            Return
        }
        
        ; Gets the version of the metafile.
        GetVersion()
        {
            Return
        }
        
        ; Gets a METAHEADER structure that contains properties of the associated metafile.
        GetWmfHeader()
        {
            Return
        }
        
        ; Determines whether the associated metafile was recorded against a video display device context.
        IsDisplay()
        {
            Return
        }
        
        ; Determines whether the associated metafile is in the EMF format.
        IsEmf()
        {
            Return
        }
        
        ; Determines whether the associated metafile is in either the EMF or EMF+ format.
        IsEmfOrEmfPlus()
        {
            Return
        }
        
        ; Determines whether the associated metafile is in the EMF+ format.
        IsEmfPlus()
        {
            Return
        }
        
        ; Determines whether the associated metafile is in the EMF+ Dual format.
        IsEmfPlusDual()
        {
            Return
        }
        
        ; Determines whether the associated metafile is in the EMF+ Only format.
        IsEmfPlusOnly()
        {
            Return
        }
        
        ; Determines whether the associated metafile is in the WMF format.
        IsWmf()
        {
            Return
        }
        
        ; Determines whether the associated metafile is a placeable metafile.
        IsWmfPlaceable()
        {
            Return
        }
        
    }
        
    ; Get or set the data points (and their types)                                 ; of a path. Helper class for the GraphicsPath and GraphicsPathIterator classes.
    Class PathData
    {
        ; ## Methods ##
        ~PathData()                                                         ; Destructor for the PathData class.
        ; Creates a PathData object. The Count data member is initialized to 0. Points and Types data members are initialized to NULL.
        PathData()
        {
            Return
        }
        
    }
        
    ; Stores the attributes of a color gradient that you can use to fill the interior of a path with a gradually changing color.
    Class PathGradientBrush
    {
        ; ## Inherit ##   The PathGradientBrush class implements Brush.
        
        ; ## Methods ##
        ; Gets the blend factors and the corresponding blend positions currently set for this path gradient brush.
        GetBlend()
        {
            Return
        }
        
        ; Gets the number of blend factors currently set for this path gradient brush.
        GetBlendCount()
        {
            Return
        }
        
        ; Gets the color of the center point of this path gradient brush.
        GetCenterColor()
        {
            Return
        }
        
        ; Gets the center point of this path gradient brush.
        GetCenterPoint()
        {
            Return
        }
        
        ; Gets the center point of this path gradient brush.
        GetCenterPoint()
        {
            Return
        }
        
        ; Gets the focus scales of this path gradient brush.
        GetFocusScales()
        {
            Return
        }
        
        ; Determines whether gamma correction is enabled for this path gradient brush.
        GetGammaCorrection()
        {
            Return
        }
        
        ; Is not implemented in Windows GDI+ version 1.0.
        GetGraphicsPath()
        {
            Return
        }
        
        ; Gets the number of preset colors currently specified for this path gradient brush.
        GetInterpolationColorCount()
        {
            Return
        }
        
        ; Gets the preset colors and blend positions currently specified for this path gradient brush.
        GetInterpolationColors()
        {
            Return
        }
        
        ; Gets the number of points in the array of points that defines this brush's boundary path.
        GetPointCount()
        {
            Return
        }
        
        ; Gets the smallest rectangle that encloses the boundary path of this path gradient brush.
        GetRectangle()
        {
            Return
        }
        
        ; Gets the smallest rectangle that encloses the boundary path of this path gradient brush.
        GetRectangle()
        {
            Return
        }
        
        ; Gets the number of colors that have been specified for the boundary path of this path gradient brush.
        GetSurroundColorCount()
        {
            Return
        }
        
        ; Gets the surround colors currently specified for this path gradient brush.
        GetSurroundColors()
        {
            Return
        }
        
        ; Gets transformation matrix of this path gradient brush.
        GetTransform()
        {
            Return
        }
        
        ; Gets the wrap mode currently set for this path gradient brush.
        GetWrapMode()
        {
            Return
        }
        
        ; Updates the brush's transformation matrix with the product of itself and another matrix.
        MultiplyTransform()
        {
            Return
        }
        
        ; Creates a PathGradientBrush object based on a GraphicsPath object.
        PathGradientBrush()
        {
            Return
        }
        
        ; Lists the constructors of the PathGradientBrush class. For a complete class listing, see PathGradientBrushXX Class.
        PathGradientBrush()
        {
            Return
        }
        
        ; Creates a PathGradientBrush object based on an array of points. Initializes the wrap mode of the path gradient brush.
        PathGradientBrush()
        {
            Return
        }
        
        ; Creates a PathGradientBrush object based on an array of points. Initializes the wrap mode of the path gradient brush.
        PathGradientBrush()
        {
            Return
        }
        
        ; Lists the constructors of the PathGradientBrush class. For a complete class listing, see PathGradientBrushXX Class.
        PathGradientBrush()
        {
            Return
        }
        
        ; Resets the transformation matrix of this path gradient brush to the identity matrix. This means that no transformation will take place.
        ResetTransform()
        {
            Return
        }
        
        ; Updates this brush's current transformation matrix with the product of itself and a rotation matrix.
        RotateTransform()
        {
            Return
        }
        
        ; Updates this brush's current transformation matrix with the product of itself and a scaling matrix.
        ScaleTransform()
        {
            Return
        }
        
        ; Sets the blend factors and the blend positions of this path gradient brush.
        SetBlend()
        {
            Return
        }
        
        ; Sets the blend shape of this path gradient brush.
        SetBlendBellShape()
        {
            Return
        }
        
        ; Sets the blend shape of this path gradient brush.
        SetBlendTriangularShape()
        {
            Return
        }
        
        ; Sets the center color of this path gradient brush. The center color is the color that appears at the brush's center point.
        SetCenterColor()
        {
            Return
        }
        
        ; Sets the center point of this path gradient brush. By default, the center point is at the centroid of the brush's boundary path, but you can set the center point to any location inside or outside the path.
        SetCenterPoint()
        {
            Return
        }
        
        ; Sets the center point of this path gradient brush.
        SetCenterPoint()
        {
            Return
        }
        
        ; Sets the focus scales of this path gradient brush.
        SetFocusScales()
        {
            Return
        }
        
        ; Specifies whether gamma correction is enabled for this path gradient brush.
        SetGammaCorrection()
        {
            Return
        }
        
        ; Is not implemented in Windows GDI+ version 1.0.
        SetGraphicsPath()
        {
            Return
        }
        
        ; Sets the preset colors and the blend positions of this path gradient brush.
        SetInterpolationColors()
        {
            Return
        }
        
        ; Sets the surround colors of this path gradient brush. The surround colors are colors specified for discrete points on the brush's boundary path.
        SetSurroundColors()
        {
            Return
        }
        
        ; Sets the transformation matrix of this path gradient brush.
        SetTransform()
        {
            Return
        }
        
        ; Sets the wrap mode of this path gradient brush.
        SetWrapMode()
        {
            Return
        }
        
        ; Updates this brush's current transformation matrix with the product of itself and a translation matrix.
        TranslateTransform()
        {
            Return
        }
        
    }
        
    ; A Windows GDI+ object used to draw lines and curves
    Class Pen
    {
        ; ## Inherit ##   The Pen class implements GdiplusBase.
        
        ; ## Methods ##
        ; Copies a Pen object.
        Clone()
        {
            Return
        }
        
        ; Gets the alignment currently set for this Pen object.
        GetAlignment()
        {
            Return
        }
        
        ; Gets the Brush object that is currently set for this Pen object.
        GetBrush()
        {
            Return
        }
        
        ; Gets the color currently set for this Pen object.
        GetColor()
        {
            Return
        }
        
        ; Gets the compound array currently set for this Pen object.
        GetCompoundArray()
        {
            Return
        }
        
        ; Gets the number of elements in a compound array.
        GetCompoundArrayCount()
        {
            Return
        }
        
        ; Gets the custom end cap currently set for this Pen object.
        GetCustomEndCap()
        {
            Return
        }
        
        ; Gets the custom start cap currently set for this Pen object.
        GetCustomStartCap()
        {
            Return
        }
        
        ; Gets the dash cap style currently set for this Pen object.
        GetDashCap()
        {
            Return
        }
        
        ; Gets the distance from the start of the line to the start of the first space in a dashed line.
        GetDashOffset()
        {
            Return
        }
        
        ; Gets an array of custom dashes and spaces currently set for this Pen object.
        GetDashPattern()
        {
            Return
        }
        
        ; Gets the number of elements in a dash pattern array.
        GetDashPatternCount()
        {
            Return
        }
        
        ; Gets the dash style currently set for this Pen object.
        GetDashStyle()
        {
            Return
        }
        
        ; Gets the end cap currently set for this Pen object.
        GetEndCap()
        {
            Return
        }
        
        ; Returns a value that indicates the nature of this Pen object's most recent method failure.
        GetLastStatus()
        {
            Return
        }
        
        ; Gets the line join style currently set for this Pen object.
        GetLineJoin()
        {
            Return
        }
        
        ; Gets the miter length currently set for this Pen object.
        GetMiterLimit()
        {
            Return
        }
        
        ; Gets the type currently set for this Pen object.
        GetPenType()
        {
            Return
        }
        
        ; Gets the start cap currently set for this Pen object.
        GetStartCap()
        {
            Return
        }
        
        ; Gets the world transformation matrix currently set for this Pen object.
        GetTransform()
        {
            Return
        }
        
        ; Gets the width currently set for this Pen object.
        GetWidth()
        {
            Return
        }
        
        ; Updates the world transformation matrix of this Pen object with the product of itself and another matrix.
        MultiplyTransform()
        {
            Return
        }
        
        ; Creates a Pen object that uses the attributes of a brush and a real number to set the width of this Pen object.
        Pen()
        {
            Return
        }
        
        ; Creates a Pen object that uses a specified color and width.
        Pen()
        {
            Return
        }
        
        ; Lists the constructors of the Pen class. For a complete class listing, see Pen Class.
        Pen()
        {
            Return
        }
        
        ; Lists the constructors of the Pen class. For a complete class listing, see Pen Class.
        Pen()
        {
            Return
        }
        
        ; Sets the world transformation matrix of this Pen object to the identity matrix.
        ResetTransform()
        {
            Return
        }
        
        ; Updates the world transformation matrix of this Pen object with the product of itself and a rotation matrix.
        RotateTransform()
        {
            Return
        }
        
        ; Sets the Pen object's world transformation matrix equal to the product of itself and a scaling matrix.
        ScaleTransform()
        {
            Return
        }
        
        ; Sets the alignment for this Pen object relative to the line.
        SetAlignment()
        {
            Return
        }
        
        ; Sets the Brush object that a pen uses to fill a line.
        SetBrush()
        {
            Return
        }
        
        ; Sets the color for this Pen object.
        SetColor()
        {
            Return
        }
        
        ; Sets the compound array for this Pen object.
        SetCompoundArray()
        {
            Return
        }
        
        ; Sets the custom end cap for this Pen object.
        SetCustomEndCap()
        {
            Return
        }
        
        ; Sets the custom start cap for this Pen object.
        SetCustomStartCap()
        {
            Return
        }
        
        ; Sets the dash cap style for this Pen object.
        SetDashCap()
        {
            Return
        }
        
        ; Sets the distance from the start of the line to the start of the first dash in a dashed line.
        SetDashOffset()
        {
            Return
        }
        
        ; Sets an array of custom dashes and spaces for this Pen object.
        SetDashPattern()
        {
            Return
        }
        
        ; Sets the dash style for this Pen object.
        SetDashStyle()
        {
            Return
        }
        
        ; Sets the end cap for this Pen object.
        SetEndCap()
        {
            Return
        }
        
        ; Sets the cap styles for the start, end, and dashes in a line drawn with this pen.
        SetLineCap()
        {
            Return
        }
        
        ; Sets the line join for this Pen object.
        SetLineJoin()
        {
            Return
        }
        
        ; Sets the miter limit of this Pen object.
        SetMiterLimit()
        {
            Return
        }
        
        ; Sets the start cap for this Pen object.
        SetStartCap()
        {
            Return
        }
        
        ; Sets the world transformation of this Pen object.
        SetTransform()
        {
            Return
        }
        
        ; Sets the width for this Pen object.
        SetWidth()
        {
            Return
        }
        
    }
        
    ; Encapsulates a point in a 2-D coordinate system.
    Class Point
    {
        ; ## Constructors ##
        ; Creates a Point object. Initializes X and Y data to zero. This is the default constructor.
        Point()
        {
            Return
        }
        
        ; Creates a Point object. Initialize the X and Y data members using passed values.
        Point(INT,INT)
        {
            Return
        }
        
        ; Creates a new Point object by copying the data members from another Point object.
        Point(Point&)
        {
            Return
        }
        
        ; Creates a Point object using a Size object to initialize the X and Y data members.
        Point(Size&)
        {
            Return
        }
        
        
        ; ## Methods ##
        ; Determines whether two Point objects are equal. Two points are considered equal if they have the same X and Y data members.
        Equals()
        {
            Return
        }
        
        operator-(Point&)()                                                 ; Subtracts the X and Y data members of two Point objects.
        operator+(Point&)()                                                 ; Adds the X and Y data members of two Point objects.
                                            
    PointF                                  
        ; ## Constructors ##
        ; Creates a PointF object and initializes the X and Y data members to zero. This is the default constructor.
        PointF()
        {
            Return
        }
        
        ; Creates a new PointF object and copies the data from another PointF object.
        PointF(PointF&)
        {
            Return
        }
        
        ; Creates a PointF object using two real numbers to specify the X and Y data members.
        PointF(REAL,REAL)
        {
            Return
        }
        
        ; Creates a PointF object using a SizeF object to specify the X and Y data members.
        PointF(SizeF&)
        {
            Return
        }
        
        
        ; ## Methods ##
        Equals                              ; Determines whether two PointF objects are equal. Two points are considered equal if they have the same X and Y data members.
        operator-(PointF&)                                                  ; Subtracts the X and Y data members of two PointF objects.
        operator+(PointF&)                                                  ; Adds the X and Y data members of two PointF objects.
    }
        
    ; Keeps a collection of fonts specifically for an application.
    Class PrivateFontCollection
    {
        ; ## Inherit ##   The PrivateFontCollection class implements FontCollection.
        
        ; ## Methods ##
        ; Adds a font file to this private font collection.
        AddFontFile()
        {
            Return
        }
        
        ; Adds a font that is contained in system memory to a Windows GDI+ font collection.
        AddMemoryFont()
        {
            Return
        }
        
        ; Creates an empty PrivateFontCollection object.
        PrivateFontCollection()
        {
            Return
        }
        
        ; Creates an empty PrivateFontCollection object.
        PrivateFontCollection()
        {
            Return
        }
        
    }
        
    ; A PropertyItem object holds one piece of image metadata and is a helper class for the Image and Bitmap classes.
    Class PropertyItem
    {
    }
        
    ; Stores the upper-left corner's x and y, width, and height of a rectangle.
    Class Rect
    {
        ; ## Constructors ##
        ; Creates a Rect object whose x-coordinate, y-coordinate, width, and height are all zero. This is the default constructor.
        Rect()
        {
            Return
        }
        
        ; Creates a Rect object by using four integers to initialize the X, Y, Width, and Height data members.
        Rect(INT,INT,INT,INT)
        {
            Return
        }
        
        ; Creates a Rect object by using a Point object to initialize the X and Y data members and a Size object to initialize the Width and Height data members.
        Rect(Point&,Size&)
        {
            Return
        }
        
        
        ; ## Methods ##
        ; Creates a new Rect object and initializes it with the contents of this Rect object.
        Clone()
        {
            Return
        }
        
        ; Determines whether the point ( x, y)                                 ; is inside this rectangle.
        Contains(INT,INT)
        {
            Return
        }
        
        ; Determines whether a point is inside this rectangle.
        Contains(Point&)
        {
            Return
        }
        
        ; Determines whether another rectangle is inside this rectangle.
        Contains(Rect&)
        {
            Return
        }
        
        ; Determines whether two rectangles are the same.
        Equals()
        {
            Return
        }
        
        ; Gets the y-coordinate of the bottom edge of the rectangle.
        GetBottom()
        {
            Return
        }
        
        ; Makes a copy of this rectangle.
        GetBounds()
        {
            Return
        }
        
        ; Gets the x-coordinate of the left edge of the rectangle.
        GetLeft()
        {
            Return
        }
        
        ; Gets the coordinates of the upper-left corner of the rectangle.
        GetLocation()
        {
            Return
        }
        
        ; Gets the x-coordinate of the right edge of the rectangle.
        GetRight()
        {
            Return
        }
        
        ; Gets the width and height of the rectangle.
        GetSize()
        {
            Return
        }
        
        ; Gets the y-coordinate of the top edge of the rectangle.
        GetTop()
        {
            Return
        }
        
        ; Expands the rectangle by dx on the left and right edges, and by dy on the top and bottom edges.
        Inflate(INT,INT)
        {
            Return
        }
        
        ; Expands the rectangle by the value of point.X on the left and right edges, and by the value of point.Y on the top and bottom edges.
        Inflate(Point&)
        {
            Return
        }
        
        ; Replaces this rectangle with the intersection of itself and another rectangle.
        Intersect(Rect&)
        {
            Return
        }
        
        ; Determines the intersection of two rectangles and stores the result in a Rect object.
        Intersect(Rect&,Rect&,Rect&)
        {
            Return
        }
        
        ; Determines whether this rectangle intersects another rectangle.
        IntersectsWith()
        {
            Return
        }
        
        ; Determines whether this rectangle is empty.
        IsEmptyArea()
        {
            Return
        }
        
        ; Moves the rectangle by dx horizontally and by dy vertically.
        Offset(INT,INT)
        {
            Return
        }
        
        ; Moves this rectangle horizontally a distance of point.X and vertically a distance of point.Y.
        Offset(Point&)
        {
            Return
        }
        
        ; Determines the union of two rectangles and stores the result in a Rect object.
        Union()
        {
            Return
        }
        
    }
        
    ; Stores the upper-left corner's x and y, width, and height of a rectangle. The RectF class uses floating point numbers.
    Class RectF
    {
        ; ## Constructors ##
        ; Creates a RectF object and initializes the X and Y data members to zero. This is the default constructor.
        RectF()
        {
            Return
        }
        
        ; Creates a RectF object by using a PointF object to initialize the X and Y data members and uses a SizeF object to initialize the Width and Height data members of this rectangle.
        RectF(PointF&,SizeF&)
        {
            Return
        }
        
        ; Creates a RectF object by using four integers to initialize the X, Y, Width, and Height data members.
        RectF(REAL,REAL,REAL,REAL)
        {
            Return
        }
        
        
        ; ## Methods ##
        ; Creates a new RectF object and initializes it with the contents of this RectF object.
        Clone()
        {
            Return
        }
        
        ; Determines whether a point is inside this rectangle.
        Contains(PointF&)
        {
            Return
        }
        
        ; Determines whether the point (x, y)                                 ; is inside this rectangle.
        Contains(REAL,REAL)
        {
            Return
        }
        
        ; Determines whether another rectangle is inside this rectangle.
        Contains(RectF&)
        {
            Return
        }
        
        ; Determines whether two rectangles are the same.
        Equals()
        {
            Return
        }
        
        ; Gets the y-coordinate of the bottom edge of the rectangle.
        GetBottom()
        {
            Return
        }
        
        ; Makes a copy of this rectangle.
        GetBounds()
        {
            Return
        }
        
        ; Gets the x-coordinate of the left edge of the rectangle.
        GetLeft()
        {
            Return
        }
        
        ; Gets the coordinates of the upper-left corner of this rectangle.
        GetLocation()
        {
            Return
        }
        
        ; Gets the x-coordinate of the right edge of the rectangle.
        GetRight()
        {
            Return
        }
        
        ; Gets the width and height of this rectangle.
        GetSize()
        {
            Return
        }
        
        ; Gets the y-coordinate of the top edge of the rectangle.
        GetTop()
        {
            Return
        }
        
        ; Expands the rectangle by the value of point.X on the left and right edges, and by the value of point.Y on the top and bottom edges.
        Inflate(PointF&)
        {
            Return
        }
        
        ; Expands the rectangle by dx on the left and right edges, and by dy on the top and bottom edges.
        Inflate(REAL,REAL)
        {
            Return
        }
        
        ; Replaces this rectangle with the intersection of itself and another rectangle.
        Intersect(RectF&)
        {
            Return
        }
        
        ; Determines the intersection of two rectangles and stores the result in a RectF object.
        Intersect(RectF&,RectF&,RectF&)
        {
            Return
        }
        
        ; Determines whether this rectangle intersects another rectangle.
        IntersectsWith()
        {
            Return
        }
        
        ; Determines whether this rectangle is empty.
        IsEmptyArea()
        {
            Return
        }
        
        ; Moves this rectangle horizontally a distance of point.X and vertically a distance of point.Y.
        Offset(PointF&)
        {
            Return
        }
        
        ; Moves the rectangle by dx horizontally and by dx vertically.
        Offset(REAL,REAL)
        {
            Return
        }
        
        ; Determines the union of two rectangles and stores the result in a RectF object.
        Union()
        {
            Return
        }
        
    }
        
    ; Enables you to correct the red eyes that sometimes occur in flash photographs.
    Class RedEyeCorrection
    {
        ; ## Inherit ##   The RedEyeCorrection class implements Effect.
        
        ; ## Methods ##
        ; Gets the current values of the parameters of this RedEyeCorrection object.
        GetParameters()
        {
            Return
        }
        
        ; Creates a RedEyeCorrection object.
        RedEyeCorrection()
        {
            Return
        }
        
        ; Sets the parameters of this RedEyeCorrection object.
        SetParameters()
        {
            Return
        }
        
    }
        
    ; Describes an area of the display surface. The area can be any shape.
    Class Region
    {
        ; ## Inherit ##   The Region class implements GdiplusBase.
        
        ; ## Methods ##
        ; Makes a copy of this Regionobject and returns the address of the new Regionobject.
        Clone()
        {
            Return
        }
        
        ; Updates this region to the portion of the specified path's interior that does not intersect this region.
        Complement()
        {
            Return
        }
        
        ; Updates a region that does not intersect this region.
        Complement()
        {
            Return
        }
        
        ; Updates this region to the portion of the specified rectangle's interior that does not intersect this region.
        Complement()
        {
            Return
        }
        
        ; Updates this region to the portion of another region that does not intersect this region.
        Complement()
        {
            Return
        }
        
        ; Determines whether this region is equal to a specified region.
        Equals()
        {
            Return
        }
        
        ; Updates this region to the portion of itself that does not intersect the specified path's interior.
        Exclude()
        {
            Return
        }
        
        ; Updates a region that does not intersect the specified rectangle's interior.
        Exclude()
        {
            Return
        }
        
        ; Updates this region to the portion of itself that does not intersect the specified rectangle's interior.
        Exclude()
        {
            Return
        }
        
        ; Updates this region to the portion of itself that does not intersect another region.
        Exclude()
        {
            Return
        }
        
        ; Creates a Windows GDI+Region object from a Windows Graphics Device Interface (GDI)                                  ; region.
        FromHRGN()
        {
            Return
        }
        
        ; Gets a rectangle that encloses this region.
        GetBounds()
        {
            Return
        }
        
        ; Gets a rectangle that encloses this region.
        GetBounds()
        {
            Return
        }
        
        ; Gets data that describes this region.
        GetData()
        {
            Return
        }
        
        ; Gets the number of bytes of data that describes this region.
        GetDataSize()
        {
            Return
        }
        
        ; Creates a Windows Graphics Device Interface (GDI)                                 ; region from this region.
        GetHRGN()
        {
            Return
        }
        
        ; Returns a value that indicates the nature of this Regionobject's most recent method failure.
        GetLastStatus()
        {
            Return
        }
        
        ; Gets an array of rectangles that approximate this region. The region is transformed by a specified matrix before the rectangles are calculated.
        GetRegionScans()
        {
            Return
        }
        
        ; Gets an array of rectangles that approximate this region.
        GetRegionScans()
        {
            Return
        }
        
        ; Gets the number of rectangles that approximate this region. The region is transformed by a specified matrix before the rectangles are calculated.
        GetRegionScansCount()
        {
            Return
        }
        
        ; Updates this region to the portion of itself that intersects the specified path's interior.
        Intersect()
        {
            Return
        }
        
        ; Updates a region intersects the specified rectangle's interior.
        Intersect()
        {
            Return
        }
        
        ; Updates this region to the portion of itself that intersects the specified rectangle's interior.
        Intersect()
        {
            Return
        }
        
        ; Updates this region to the portion of itself that intersects another region.
        Intersect()
        {
            Return
        }
        
        ; Determines whether this region is empty.
        IsEmpty()
        {
            Return
        }
        
        ; Determines whether this region is infinite.
        IsInfinite()
        {
            Return
        }
        
        ; Determines whether a point is inside this region.
        IsVisible()
        {
            Return
        }
        
        ; Determines whether a point is inside this region.
        IsVisible()
        {
            Return
        }
        
        ; Determines whether a rectangle intersects this region.
        IsVisible()
        {
            Return
        }
        
        ; Determines whether a rectangle intersects this region.
        IsVisible()
        {
            Return
        }
        
        ; Determines whether a point is inside this region.
        IsVisible()
        {
            Return
        }
        
        ; Determines whether a rectangle intersects this region.
        IsVisible()
        {
            Return
        }
        
        ; Determines whether a point is inside this region.
        IsVisible()
        {
            Return
        }
        
        ; Determines whether a rectangle intersects this region.
        IsVisible()
        {
            Return
        }
        
        ; Updates this region to an empty region. In other words, the region occupies no space on the display device.
        MakeEmpty()
        {
            Return
        }
        
        ; Updates this region to an infinite region.
        MakeInfinite()
        {
            Return
        }
        
        ; Creates a region that is infinite. This is the default constructor.
        Region()
        {
            Return
        }
        
        ; Creates a region that is defined by data obtained from another region.
        Region()
        {
            Return
        }
        
        ; Creates a region that is defined by a path (a GraphicsPath object)                                 ; and has a fill mode that is contained in the GraphicsPath object.
        Region()
        {
            Return
        }
        
        ; Creates a region that is defined by a rectangle.
        Region()
        {
            Return
        }
        
        ; Creates a region that is defined by a rectangle.
        Region()
        {
            Return
        }
        
        ; Creates a region that is infinite. This is the default constructor.
        Region()
        {
            Return
        }
        
        ; Creates a region that is infinite. This is the default constructor.
        Region()
        {
            Return
        }
        
        ; Creates a region that is identical to the region that is specified by a handle to a Windows Graphics Device Interface (GDI)                                 ; region.
        Region()
        {
            Return
        }
        
        ; Transforms this region by multiplying each of its data points by a specified matrix.
        Transform()
        {
            Return
        }
        
        ; Offsets this region by specified amounts in the horizontal and vertical directions.
        Translate()
        {
            Return
        }
        
        ; Offsets this region by specified amounts in the horizontal and vertical directions.
        Translate()
        {
            Return
        }
        
        ; Updates this region to all portions (intersecting and nonintersecting)                                 ; of itself and all portions of the specified path's interior.
        Union()
        {
            Return
        }
        
        ; Updates this region.
        Union()
        {
            Return
        }
        
        ; Updates this region to all portions (intersecting and nonintersecting)                                 ; of itself and all portions of the specified rectangle's interior.
        Union()
        {
            Return
        }
        
        ; Updates this region to all portions (intersecting and nonintersecting)                                 ; of itself and all portions of another region.
        Union()
        {
            Return
        }
        
        ; Updates this region to the nonintersecting portions of itself and the specified path's interior.
        Xor()
        {
            Return
        }
        
        ; Updates a region to the nonintersecting portions with a rectangle's interior.
        Xor()
        {
            Return
        }
        
        ; Updates this region to the nonintersecting portions of itself and the specified rectangle's interior.
        Xor()
        {
            Return
        }
        
        ; Updates this region to the nonintersecting portions of itself and another region.
        Xor()
        {
            Return
        }
        
    }
        
    ; Enables you to adjust the sharpness of a bitmap.
    Class Sharpen
    {
        ; ## Inherit ##   The Sharpen class implements Effect.
        
        ; ## Methods ##
        ; Gets the current values of the parameters of this Sharpen object.
        GetParameters()
        {
            Return
        }
        
        ; Sets the parameters of this Sharpen object.
        SetParameters()
        {
            Return
        }
        
        ; Creates a Sharpen object.
        Sharpen()
        {
            Return
        }
        
    }
        
    ; Encapsulates a Width and Height dimension in a 2-D coordinate system.
    Class Size
    {
        ; ## Constructors ##
        ; Creates a new Size object and initializes the members to zero. This is the default constructor.
        Size()
        {
            Return
        }
        
        ; Creates a Size object and initializes its Width and Height data members.
        Size(INT,INT)
        {
            Return
        }
        
        ; Creates a Size object and initializes its members by copying the members of another Size object.
        Size(Size&)
        {
            Return
        }
        
        
        ; ## Methods ##
        ; Determines whether a Size object is empty.
        Empty()
        {
            Return
        }
        
        ; Determines whether two Size objects are equal.
        Equals()
        {
            Return
        }
        
        operator-(Size&)                                                    ; Subtracts the Width and Height data members of two Size objects.
        operator+(Size&)                                                    ; Adds the Width and Height data members of two Size objects.
    }
        
    ; Encapsulates a Width and Height dimension in a 2-D coordinate system. The SizeF class uses floating point numbers.
    Class SizeF
    {
        ; ## Constructors ##
        ; Creates a SizeF object and initializes the members to zero. This is the default constructor.
        SizeF()
        {
            Return
        }
        
        ; Creates a SizeF object and initializes its Width and Height data members.
        SizeF(REAL,REAL)
        {
            Return
        }
        
        ; Creates a SizeF object and initializes its members by copying the members of another SizeF object.
        SizeF(SizeF&)
        {
            Return
        }
        
        
        ; ## Methods ##
        ; The Empty method determines whether a SizeF object is empty.
        Empty()
        {
            Return
        }
        
        ; The Equals method determines whether two SizeF objects are equal.
        Equals()
        {
            Return
        }
        
        operator-(SizeF&)                                                   ; The operator- method subtracts the Width and Height data members of two SizeF objects.
        operator+(SizeF&)                                                   ; The operator+ method adds the Width and Height data members of two SizeF objects.
    }
        
    ; A Brush object is used to fill in shapes similar to the way a paint brush can paint the inside of a shape.
    Class SolidBrush
    {
        ; ## Inherit ##   The SolidBrush class implements Brush.
        
        ; ## Methods ##
        ; Gets the color of this solid brush.
        GetColor()
        {
            Return
        }
        
        ; Sets the color of this solid brush.
        SetColor()
        {
            Return
        }
        
        ; Creates a SolidBrush object based on a color.
        SolidBrush()
        {
            Return
        }
        
        ; Copy constructor for SolidBrush.
        SolidBrush()
        {
            Return
        }
        
        ; Creates a SolidBrush object based on a color.
        SolidBrush()
        {
            Return
        }
        
    }
        
    ; Encapsulates text layout information and display manipulations.
    Class StringFormat
    {
        ; ## Inherit ##   The StringFormat class implements GdiplusBase.
        
        ; ## Methods ##
        ; Creates a new StringFormat object and initializes it with the contents of this StringFormat object.
        Clone()
        {
            Return
        }
        
        ; Creates a generic, default StringFormat object.
        GenericDefault()
        {
            Return
        }
        
        ; Creates a generic, typographic StringFormat object.
        GenericTypographic()
        {
            Return
        }
        
        ; Gets an element of the StringAlignment enumeration that indicates the character alignment of this StringFormat object in relation to the origin of the layout rectangle.
        GetAlignment()
        {
            Return
        }
        
        ; Gets the language that corresponds with the digits that are to be substituted for Western European digits.
        GetDigitSubstitutionLanguage()
        {
            Return
        }
        
        ; Gets an element of the StringDigitSubstitute enumeration that indicates the digit substitution method that is used by this StringFormat object.
        GetDigitSubstitutionMethod()
        {
            Return
        }
        
        ; Gets the string format flags for this StringFormat object.
        GetFormatFlags()
        {
            Return
        }
        
        ; Gets an element of the HotkeyPrefix enumeration that indicates the type of processing that is performed on a string when a hot key prefix, an ampersand (&), is encountered.
        GetHotkeyPrefix()
        {
            Return
        }
        
        ; Returns a value that indicates the nature of this StringFormat object's most recent method failure.
        GetLastStatus()
        {
            Return
        }
        
        ; Gets an element of the StringAlignment enumeration that indicates the line alignment of this StringFormat object in relation to the origin of the layout rectangle.
        GetLineAlignment()
        {
            Return
        }
        
        ; Gets the number of measurable character ranges that are currently set. The character ranges that are set can be measured in a string by using the MeasureCharacterRanges method.
        GetMeasurableCharacterRangeCount()
        {
            Return
        }
        
        ; Gets the number of tab-stop offsets in this StringFormat object.
        GetTabStopCount()
        {
            Return
        }
        
        ; Gets the offsets of the tab stops in this StringFormat object.
        GetTabStops()
        {
            Return
        }
        
        ; Gets an element of the StringTrimming enumeration that indicates the trimming style of this StringFormat object.
        GetTrimming()
        {
            Return
        }
        
        ; Sets the character alignment of this StringFormat object in relation to the origin of the layout rectangle. A layout rectangle is used to position the displayed string.
        SetAlignment()
        {
            Return
        }
        
        ; Sets the digit substitution method and the language that corresponds to the digit substitutes.
        SetDigitSubstitution()
        {
            Return
        }
        
        ; Sets the format flags for this StringFormat object. The format flags determine most of the characteristics of a StringFormat object.
        SetFormatFlags()
        {
            Return
        }
        
        ; Sets the type of processing that is performed on a string when the hot key prefix, an ampersand (&), is encountered.
        SetHotkeyPrefix()
        {
            Return
        }
        
        ; Sets the line alignment of this StringFormat object in relation to the origin of the layout rectangle.
        SetLineAlignment()
        {
            Return
        }
        
        ; Sets a series of character ranges for this StringFormat object that, when in a string, can be measured by the MeasureCharacterRanges method.
        SetMeasurableCharacterRanges()
        {
            Return
        }
        
        ; Sets the offsets for tab stops in this StringFormat object.
        SetTabStops()
        {
            Return
        }
        
        ; Sets the trimming style for this StringFormat object. The trimming style determines how to trim a string so that it fits into the layout rectangle.
        SetTrimming()
        {
            Return
        }
        
        ; Creates a StringFormat object from another StringFormat object.
        StringFormat()
        {
            Return
        }
        
        ; Lists the constructors of the StringFormat class. For a complete class listing, see StringFormat Class.
        StringFormat()
        {
            Return
        }
        
        ; Lists the constructors of the StringFormat class. For a complete class listing, see StringFormat Class.
        StringFormat()
        {
            Return
        }
        
        ; Creates a StringFormat object based on string format flags and a language.
        StringFormat()
        {
            Return
        }
        
    }
        
    ; Defines a Brush object that contains an Image object that is used for the fill.
    Class TextureBrush
    {
        ; ## Inherit ##   The TextureBrush class implements Brush.
        
        ; ## Methods ##
        ; Gets a pointer to the Image object that is defined by this texture brush.
        GetImage()
        {
            Return
        }
        
        ; Gets the transformation matrix of this texture brush.
        GetTransform()
        {
            Return
        }
        
        ; Gets the wrap mode currently set for this texture brush.
        GetWrapMode()
        {
            Return
        }
        
        ; Updates this brush's transformation matrix with the product of itself and another matrix.
        MultiplyTransform()
        {
            Return
        }
        
        ; Resets the transformation matrix of this texture brush to the identity matrix. This means that no transformation takes place.
        ResetTransform()
        {
            Return
        }
        
        ; Updates this texture brush's current transformation matrix with the product of itself and a rotation matrix.
        RotateTransform()
        {
            Return
        }
        
        ; Updates this texture brush's current transformation matrix with the product of itself and a scaling matrix.
        ScaleTransform()
        {
            Return
        }
        
        ; Sets the transformation matrix of this texture brush.
        SetTransform()
        {
            Return
        }
        
        ; Sets the wrap mode of this texture brush.
        SetWrapMode()
        {
            Return
        }
        
        ; Lists the constructors of the TextureBrush class. For a complete class listing, see TextureBrush Class.
        TextureBrush()
        {
            Return
        }
        
        ; Creates a TextureBrush object based on an image, a defining rectangle, and a set of image properties.
        TextureBrush()
        {
            Return
        }
        
        ; Creates a TextureBrush object based on an image, a defining rectangle, and a set of image properties.
        TextureBrush()
        {
            Return
        }
        
        ; Creates a TextureBrush object based on an image and a wrap mode. The size of the brush defaults to the size of the image, so the entire image is used by the brush.
        TextureBrush()
        {
            Return
        }
        
        ; Creates a TextureBrush object based on an image, a wrap mode, and a defining rectangle.
        TextureBrush()
        {
            Return
        }
        
        ; Creates a TextureBrush object based on an image, a wrap mode, and a defining rectangle.
        TextureBrush()
        {
            Return
        }
        
        ; Creates a TextureBrush object based on an image, a wrap mode, and a defining set of coordinates.
        TextureBrush()
        {
            Return
        }
        
        ; Creates a TextureBrush object based on an image, a wrap mode, and a defining set of coordinates.
        TextureBrush()
        {
            Return
        }
        
        ; Lists the constructors of the TextureBrush class. For a complete class listing, see TextureBrush Class.
        TextureBrush()
        {
            Return
        }
        
        ; Updates this brush's current transformation matrix with the product of itself and a translation matrix.
        TranslateTransform()
        {
            Return
        }
        
    }
        
    ; Enables you to apply a tint to a bitmap.
    Class Tint
    {
        ; ## Inherit ##   The Tint class implements Effect.
        
        ; ## Methods ##
        ; Gets the current values of the parameters of this Tint object.
        GetParameters()
        {
            Return
        }
        
        ; Sets the parameters of this Tint object.
        SetParameters()
        {
            Return
        }
        
        ; Creates a Tint object.
        Tint()
        {
            Return
        }
        
    }
}
*/

































/*
GDI+ Class and Method List
                                                                                                                                                                               
AdjustableArrowCap                      ; Builds a line cap that looks like an arrow. This is a subclass of CustomLineCap.
    ::Inherit::                         
    ::Methods::                         
    AdjustableArrowCap()                ; Creates an adjustable arrow line cap with specified height and width. Can be filled or unfilled. Middle inset defaults to zero.
    GetHeight()                         ; Gets height of arrow cap. The height is the distance from the base of the arrow to its vertex.
    GetMiddleInset()                    ; Gets value of inset. The middle inset is the number of units that the midpoint of the base shifts towards the vertex.
    GetWidth()                          ; Gets width of arrow cap. The width is the distance between the endpoints of the base of the arrow.
    IsFilled()                          ; Determines whether the arrow cap is filled.
    SetFillState()                      ; Sets fill state of the arrow cap. If the arrow cap is not filled, only the outline is drawn.
    SetHeight()                         ; Sets height of the arrow cap. This is the distance from the base of the arrow to its vertex.
    SetMiddleInset()                    ; Sets number of units that the midpoint of the base shifts towards the vertex.
    SetWidth()                          ; Sets width of the arrow cap. The width is the distance between the endpoints of the base of the arrow.
                                                                                                                                                                                       
Bitmap                                  ; Inherits from the Image class. The Image class provides saving and loading methods for vector images (metafiles) ; and raster images (bitmaps).
    ::Inherit::                         
    ::Methods::                         
    ApplyEffectThe()                    ; Bitmap::ApplyEffect method creates a new Bitmap object by applying a specified effect to an existing Bitmap object.
    ApplyEffectThe()                    ; Bitmap::ApplyEffect method alters this Bitmap object by applying a specified effect.
    Bitmap()                            ; Creates a Bitmap object based on a BITMAPINFO structure and an array of pixel data.
    Bitmap()                            ; Creates a Bitmap object based on an image file.
    Bitmap()                            ; Creates a Bitmap object based on a handle to a Windows Windows Graphics Device Interface (GDI) ; bitmap and a handle to a GDI palette.
    Bitmap()                            ; Creates a Bitmap object based on an icon.
    Bitmap()                            ; Creates a Bitmap object based on an application or DLL instance handle and the name of a bitmap resource.
    Bitmap()                            ; Creates a Bitmap object based on a DirectDraw surface. The Bitmap::Bitmap object maintains a reference to the DirectDraw surface until the Bitmap::Bitmap object is deleted or goes out of scope.
    Bitmap()                            ; Creates a Bitmap object based on a Graphics object, a width, and a height.
    Bitmap()                            ; Creates a Bitmap object based on an array of bytes along with size and format information.
    Bitmap()                            ; Creates a Bitmap object of a specified size and pixel format. The pixel data must be provided after the Bitmap::Bitmap object is constructed.
    Bitmap()                            ; Creates a Bitmap object based on an IStream COM interface.
    CloneThe()                          ; Creates a new Bitmap object by copying a portion of this bitmap.
    CloneThe()                          ; Creates a new Bitmap object by copying a portion of this bitmap.
    CloneThe()                          ; Creates a new Bitmapobject by copying a portion of this bitmap.
    CloneThe()                          ; Creates a new Bitmapobject by copying a portion of this bitmap.
    ConvertFormatThe()                  ; Converts a bitmap to a specified pixel format. The original pixel data in the bitmap is replaced by the new pixel data.
    FromBITMAPINFOThe()                 ; Creates a Bitmap object based on a BITMAPINFO structure and an array of pixel data.
    FromDirectDrawSurface()             ; Creates a Bitmap object based on a DirectDraw surface. The Bitmap object maintains a reference to the DirectDraw surface until the Bitmap object is deleted.
    FromFileThe()                       ; Creates a Bitmap object based on an image file.
    FromHBITMAPThe()                    ; Creates a Bitmap object based on a handle to a Windows Graphics Device Interface (GDI) ; bitmap and a handle to a GDI palette.
    FromHICONThe()                      ; Creates a Bitmap object based on a handle to an icon.
    FromResourceThe()                   ; Creates a Bitmap object based on an application or DLL instance handle and the name of a bitmap resource.
    FromStreamThe()                     ; Creates a Bitmap object based on a stream.
    GetHBITMAPThe()                     ; Creates a Windows Graphics Device Interface (GDI) ; bitmap from this Bitmap object.
    GetHICONThe()                       ; Creates an icon from this Bitmap object.
    GetHistogramThe()                   ; Returns one or more histograms for specified color channels of this Bitmap object.
    GetHistogramSizeThe()               ; The number of elements (in an array of UINTs) ; that you must allocate before you call the Bitmap::GetHistogram method of a Bitmap object.
    GetPixelThe()                       ; Gets the color of a specified pixel in this bitmap.
    InitializePaletteThe()              ; Initializes a standard, optimal, or custom color palette.
    LockBitsThe()                       ; Locks a rectangular portion of this bitmap and provides a temporary buffer that you can use to read or write pixel data in a specified format.
    SetPixelThe()                       ; Sets the color of a specified pixel in this bitmap.
    SetResolutionThe()                  ; Sets the resolution of this Bitmap object.
    UnlockBitsThe()                     ; Unlocks a portion of this bitmap that was previously locked by a call to Bitmap::LockBits.
                                                                                                                                                                                       
BitmapData                              ; Used by the Bitmap::LockBits and Bitmap::UnlockBits methods of the Bitmap class. A BitmapData object stores attributes of a bitmap.
    ::Inherit::                         
    ::Methods::                         
                                                                                                                                                                                       
Blur                                    ; Enables you to apply a Gaussian blur effect to a bitmap and specify the nature of the blur.
    ::Inherit::                         
    ::Methods::                         
    BlurCreates()                       ; Blur object.
    GetParameters()                     ; Gets current values of Blur object parameters.
    SetParameters()                     ; Sets value for Blur object.
                                                                                                                                                                                   
BrightnessContrast                      ; Enables you to change the brightness and contrast of a bitmap. 
    ::Inherit::                         
    ::Methods::                         
    BrightnessContrast()                ; Creates a new BrightnessContrast object.
    GetParameters()                     ; Gets current values of the parameters of this BrightnessContrast object.
    SetParameters()                     ; Sets parameters of this BrightnessContrast object.    
                                                                                                                                                                                   
Brush                                   ; An abstract base class that defines a Brush object. A Brush object is used to paint the interior of graphics shapes, such as rectangles, ellipses, pies, polygons, and paths.
    ::Inherit::                         
    ::Methods::                         
    Clone()                             ; Creates a copy of a Brush object.
    GetLastStatus()                     ; Returns a value indicating this Brush object's most recent method failure.
    GetType()                           ; Gets the type of this brush.
                                                                                                                                                                                       
CachedBitmap                            ; Stores a bitmap in a format that is optimized for display on a particular device.
    ::Inherit::                         
    ::Methods::                         
    CachedBitmap()                      ; Create a CachedBitmap object based on a Bitmap object and Graphics object.
    CachedBitmap()                      ; Copy constructor for CachedBitmap.
    GetLastStatus()                     ; Returns a value indicating if CachedBitmap object was constructed successfully.
                                                                                                                                                                                       
CharacterRange                          ; Specifies a range of character positions within a string
    ::Inherit::                         
    ::Constructors::                    
    CharacterRange()                    ; Creates a CharacterRange object with data members set to zero.
    CharacterRange(INT,INT)             ; Creates a CharacterRange object and initializes data members to the values specified.    
    ::Methods::                         
    operator=()                         ; The operator= method sets a CharacterRange object equal to the specified CharacterRange object.
                                                                                                                                                                                       
Color                                   ; An object that stores a 32-bit value representing a color. The value contains four 8-bit components: alpha, red, green, and blue (respectively)
    ::Inherit::                         
    ::Constructors::                    
    Color()                             ; Creates Color object and initializes it to opaque black. This is the default constructor.
    Color(ARGB)                         ; Creates Color object using an ARGB value.
    Color(BYTE,BYTE,BYTE)               ; Creates Color object using specified values for the red, green, and blue components. This constructor sets the alpha component to 255 (opaque).
    Color(BYTE,BYTE,BYTE,BYTE)          ; Creates Color object using specified values for the alpha, red, green, and blue components.     
    ::Methods::                         
    GetA()                              ; Gets alpha component of Color object.
    GetAlpha()                          ; Gets alpha component of Color object.
    GetB()                              ; Gets blue component of Color object.
    GetBlue()                           ; Gets blue component of Color object.
    GetG()                              ; Gets green component of Color object.
    GetGreen()                          ; Gets green component of Color object.
    GetR()                              ; Gets red component of Color object.
    GetRed()                            ; Gets red component of Color object.
    GetValue()                          ; Gets ARGB value of this Color object.
    MakeARGB()                          ; Creates a 32-bit value using the specified alpha, red, green, and blue components.
    SetFromCOLORREF()                   ; Uses a GDICOLORREF value to set the ARGB value of this Color object.
    SetValue()                          ; Sets the color of this Color object.
    ToCOLORREF()                        ; Converts this Color object's ARGB value to a GDICOLORREF value.
                                                                                                                                                                                   
ColorBalance                            ; The ColorBalance class enables you to change the color balance (relative amounts of red, green, and blue) ; of a bitmap.
    ::Inherit::                         
    ::Methods::                         
    ColorBalance()                      ; Create new ColorBalance object.
    GetParameters()                     ; Gets the current values of the parameters of this ColorBalance object.
    SetParameters()                     ; Sets the parameters of this ColorBalance object.
                                                                                                                                                                                       
ColorCurve                              ; Eight different image adjustments: Exposure, density, contrast, highlight, shadow, midtone, white saturation, black saturation
    ::Inherit::                         
    ::Methods::                         
    ColorCurve()                        ; Creates a ColorCurve object.
    GetParameters()                     ; Gets the current values of the parameters of this ColorCurve object.
    SetParameters()                     ; Sets the parameters of this ColorCurve object.
                                                                                                                                                                                       
ColorLUT                                ; Use lookup tables to make custom color adjustments to bitmaps. A ColorLUTParams structure has four members, each being a lookup table for : alpha, red, green, or blue.
    ::Inherit::                         
    ::Methods::                         
    ColorLUT()                          ; Creates a new ColorLUT object.
    GetParameters()                     ; Gets the current values of the parameters of this ColorLUT object.
    SetParameters()                     ; Sets the parameters of this ColorLUT object.
                                                                                                                                                                                       
ColorMatrixEffect                       ; Enables you to apply an affine transformation to a bitmap.
    ::Inherit::                         
    ::Methods::                         
    ColorMatrixEffect()                 ; Creates a ColorMatrixEffect object.
    GetParameters()                     ; Gets the elements of the current 5x5 color matrix of this ColorMatrixEffect object.
    SetParameters()                     ; Sets the 5x5 color matrix of this ColorMatrixEffect object.
                                                                                                                                                                                   
CustomLineCap                           ; Encapsulates a custom line cap. A line cap defines the style of graphic used to draw the ends of a line. It can be various shapes, such as a square, circle, or diamond. A custom line cap is defined by the path that draws it.
    ::Inherit::                         
    ::Methods::                         
    Clone()                             ; Copies the contents of the existing object into a new CustomLineCap object.
    CustomLineCap()                     ; Copy constructor for CustomLineCap.
    CustomLineCap()                     ; Creates a CustomLineCap object.
    CustomLineCap()                     ; Creates a CustomLineCap object.
    GetBaseCap()                        ; Gets the style of the base cap. The base cap is a LineCap object used as a cap at the end of a line along with this CustomLineCap object.
    GetBaseInset()                      ; Gets the distance between the base cap to the start of the line.
    GetLastStatus()                     ; Returns a value that indicates the nature of this CustomLineCap object's most recent method failure.
    GetStrokeCaps()                     ; Gets the end cap styles for both the start line cap and the end line cap. Line caps are LineCap objects that end the individual lines within a path.
    GetStrokeJoin()                     ; Returns the style of LineJoin used to join multiple lines in the same GraphicsPath object.
    GetWidthScale()                     ; Gets the value of the scale width. This is the amount to scale the custom line cap relative to the width of the Pen object used to draw a line. The default value of 1.0 does not scale the line cap.
    SetBaseCap()                        ; Sets the LineCap that appears as part of this CustomLineCap at the end of a line.
    SetBaseInset()                      ; Sets the base inset value of this custom line cap. This is the distance between the end of a line and the base cap.
    SetStrokeCap()                      ; Sets the LineCap object used to start and end lines within the GraphicsPath object that defines this CustomLineCap object.
    SetStrokeCaps()                     ; Sets the LineCap objects used to start and end lines within the GraphicsPath object that defines this CustomLineCap object.
    SetStrokeJoin()                     ; Sets the style of line join for the stroke. The line join specifies how two lines that intersect within the GraphicsPath object that makes up the custom line cap are joined.
    SetWidthScale()                     ; Sets the value of the scale width. This is the amount to scale the custom line cap relative to the width of the Pen used to draw lines. The default value of 1.0 does not scale the line cap.
                                                                                                                                                                                   
Effect                                  ; Serves as a base class for eleven classes that you can use to apply effects and adjustments to bitmaps. 
    ::Inherit::                         
    ::Constructors::                    
    Effect()                            ; Creates an Effect object
    ::Methods::                         
    GetAuxData()                        ; Gets a pointer to a set of lookup tables created by a previous call to the Bitmap::ApplyEffect method.
    GetAuxDataSize()                    ; Gets the size, in bytes, of the auxiliary data created by a previous call to the Bitmap::ApplyEffect method.
    GetParameterSize()                  ; Gets the total size, in bytes, of the parameters currently set for this Effect. The Effect::GetParameterSize method is usually called on an object that is an instance of a descendant of the Effect class.
    UseAuxData()                        ; Sets or clears a flag that specifies whether the Bitmap::ApplyEffect method should return a pointer to the auxiliary data that it creates.
                                                                                                                                                                                       
EncoderParameter                        ; Holds a parameter that can be passed to an image encoder.
    ::Inherit::                         
    ::Methods::                         
                                                                                                                                                                                       
EncoderParameters                       ; An array of EncoderParameter objects along with a data member that specifies the number of EncoderParameter objects in the array.
    ::Inherit::                         
    ::Methods::                         
                                                                                                                                                                                       
Font                                    ; Encapsulates the characteristics, such as family, height, size, and style (or combination of styles), of a specific font. A Font object is used when drawing strings.
    ::Inherit::                         
    ::Methods::                         
    Clone()                             ; Creates a new Font object based on this Font object.
    Font()                              ; Lists the constructors of the Font class. For a complete class listing, see Font Class.
    Font()                              ; Creates a Font object based on a FontFamily object, a size, a font style, and a unit of measurement.
    Font()                              ; Creates a Font object based on a font family, a size, a font style, a unit of measurement, and a FontCollection object.
    Font()                              ; This topic lists the constructors of the Font class. For a complete class listing, see Font Class.
    Font()                              ; Creates a Font object based on the Windows Graphics Device Interface (GDI) ; font object that is currently selected into a specified device context. This constructor is provided for compatibility with GDI.
    Font()                              ; Creates a Font object indirectly from a Windows Graphics Device Interface (GDI) ; logical font by using a handle to a GDILOGFONT structure.
    Font()                              ; Creates a Font object directly from a Windows Graphics Device Interface (GDI) ; logical font.
    Font()                              ; Creates a Font object directly from a Windows Graphics Device Interface (GDI) ; logical font.
    GetFamily()                         ; Gets the font family on which this font is based.
    GetHeight()                         ; Gets the line spacing of this font in the current unit of a specified Graphics object.
    GetHeight()                         ; Gets the line spacing, in pixels, of this font.
    GetLastStatus()                     ; Returns a value that indicates the nature of this Font object's most recent method failure.
    GetLogFontA()                       ; Uses a LOGFONTA structure to get the attributes of this Font object.
    GetLogFontW()                       ; Uses a LOGFONTW structure to get the attributes of this Font object.
    GetSize()                           ; Returns the font size (commonly called the em size) ; of this Font object. The size is in the units of this Font object.
    GetStyle()                          ; Gets the style of this font's typeface.
    GetUnit()                           ; Returns the unit of measure of this Font object.
    IsAvailable()                       ; Determines whether this Font object was created successfully.
                                                                                                                                                                                       
FontCollection                          
    ::Inherit::                         
    ::Methods::                         
    FontCollection()                    ; Creates an empty FontCollection object.
    FontCollection()                    ; Creates an empty FontCollection object.
    GetFamilies()                       ; Gets the font families contained in this font collection.
    GetFamilyCount()                    ; Gets the number of font families contained in this font collection.
    GetLastStatus()                     ; Returns a value that indicates the result of this FontCollection object's previous method call.
                                                                                                                                                                                       
FontFamily                              ; Encapsulates a set of fonts that make up a font family. A font family is a group of fonts that have the same typeface but different styles.
    ::Inherit::                         
    ::Methods::                         
    Clone()                             ; Creates a new FontFamily object based on this FontFamily object.
    FontFamily()                        ; Creates an empty FontFamily object.
    FontFamily()                        ; Lists the constructors of the FontFamily class. For a complete class listing, see FontFamilyClass.
    FontFamily()                        ; Creates a FontFamily object based on a specified font family.
    FontFamily()                        ; Lists the constructors of the FontFamily class. For a complete class listing, see FontFamilyClass.
    GenericMonospace()                  ; Gets a FontFamily object that specifies a generic monospace typeface.
    GenericSansSerif()                  ; Gets a FontFamily object that specifies a generic sans serif typeface.
    GenericSerif()                      ; Gets a FontFamily object that represents a generic serif typeface.
    GetCellAscent()                     ; Gets the cell ascent, in design units, of this font family for the specified style or style combination.
    GetCellDescent()                    ; Gets the cell descent, in design units, of this font family for the specified style or style combination.
    GetEmHeight()                       ; Gets the size (commonly called em size or em height), in design units, of this font family.
    GetFamilyName()                     ; Gets the name of this font family.
    GetLastStatus()                     ; Returns a value that indicates the nature of this FontFamily object's most recent method failure.
    GetLineSpacing()                    ; Gets the line spacing, in design units, of this font family for the specified style or style combination. The line spacing is the vertical distance between the base lines of two consecutive lines of text.
    IsAvailable()                       ; Determines whether this FontFamily object was created successfully.
    IsStyleAvailable()                  ; Determines whether the specified style is available for this font family.
                                                                                                                                                                                           
GdiplusBase                                                                                                             
    ::Inherit::                         
    ::Methods::                         
    operator delete()                   ; The operator delete method deallocates memory for one GDI+ object.
    operator delete[]()                 ; The operator delete[] method allocates memory for an array of GDI+ objects.
    operator new()                      ; The operator new method allocates memory for one GDI+ object.
    operator new[]()                    ; The operator new[] method allocates memory for an array of GDI+ objects.
                                                                                                        
Graphics
    ::Inherit::                         
    ::Methods::                         
    AddMetafileComment()                ; Adds a text comment to an existing metafile.
    BeginContainer()                    ; Begins a new graphics container.
    BeginContainer()                    ; Begins a new graphics container.
    BeginContainer()                    ; Begins a new graphics container.              
    Clear()                             ; Clears a Graphicsobject to a specified color.
    DrawArc()                           ; Draws an arc. The arc is part of an ellipse.
    DrawArc()                           ; Draws an arc. The arc is part of an ellipse.
    DrawArc()                           ; Draws an arc. The arc is part of an ellipse.
    DrawArc()                           ; Draws an arc.
    DrawBezier()                        ; Draws a Bezier spline.
    DrawBezier()                        ; Draws a Bezier spline.
    DrawBezier()                        ; Draws a Bezier spline.
    DrawBezier()                        ; Draws a Bezier spline.
    DrawBeziers()                       ; Draws a sequence of connected B?zier splines.
    DrawBeziers()                       ; Draws a sequence of connected Bezier splines.
    DrawCachedBitmap()                  ; Draws the image stored in a CachedBitmap object.
    DrawClosedCurve()                   ; Draws a closed cardinal spline.
    DrawClosedCurve()                   ; Draws a closed cardinal spline.
    DrawClosedCurve()                   ; Draws a closed cardinal spline.
    DrawClosedCurve()                   ; Draws a closed cardinal spline.
    DrawCurve()                         ; Draws a cardinal spline.
    DrawCurve()                         ; Draws a cardinal spline.
    DrawCurve()                         ; Draws a cardinal spline.
    DrawCurve()                         ; Draws a cardinal spline.
    DrawCurve()                         ; Draws a cardinal spline.
    DrawCurve()                         ; Draws a cardinal spline.
    DrawDriverString()                  ; Draws characters at the specified positions. The method gives the client complete control over the appearance of text. The method assumes that the client has already set up the format and layout to be applied.
    DrawEllipse()                       ; Draws an ellipse.
    DrawEllipse()                       ; Draws an ellipse.
    DrawEllipse()                       ; Draws an ellipse.
    DrawEllipse()                       ; Draws an ellipse.
    DrawImage()                         ; Draws an image.
    DrawImage()                         ; Draws an image.
    DrawImage()                         ; Draws an image.
    DrawImage()                         ; Draws an image.
    DrawImage()                         ; Draws an image.
    DrawImage()                         ; Draws an image.
    DrawImage()                         ; Draws an image.
    DrawImage()                         ; Draws an image.
    DrawImage()                         ; Draws an image.
    DrawImage()                         ; Draws a specified portion of an image at a specified location.
    DrawImage()                         ; Draws an image.
    DrawImage()                         ; Draws an image at a specified location.
    DrawImage()                         ; Draws an image.
    DrawImage()                         ; Draws an image.
    DrawImage()                         ; Draws an image at a specified location.
    DrawImage()                         ; Draws an image.
    DrawImage()                         ; Draws an image.
    DrawImage()                         ; Draws a portion of an image after applying a specified effect.
    DrawLine()                          ; Draws a line that connects two points.
    DrawLine()                          ; Draws a line that connects two points.
    DrawLine()                          ; Draws a line that connects two points.
    DrawLine()                          ; Draws a line that connects two points.
    DrawLines()                         ; Draws a sequence of connected lines.
    DrawLines()                         ; Draws a sequence of connected lines.
    DrawPath()                          ; Draws a sequence of lines and curves defined by a GraphicsPath object.
    DrawPie()                           ; Draws a pie.
    DrawPie()                           ; Draws a pie.
    DrawPie()                           ; Draws a pie.
    DrawPie()                           ; Draws a pie.
    DrawPolygon()                       ; Draws a polygon.
    DrawPolygon()                       ; Draws a polygon.
    DrawRectangle()                     ; Draws a rectangle.
    DrawRectangle()                     ; Draws a rectangle.
    DrawRectangle()                     ; Draws a rectangle.
    DrawRectangle()                     ; Draws a rectangle.
    DrawRectangles()                    ; Draws a sequence of rectangles.
    DrawRectangles()                    ; Draws a sequence of rectangles.
    DrawString()                        ; Draws a string based on a font and an origin for the string.
    DrawString()                        ; Draws a string based on a font, a string origin, and a format.
    DrawString()                        ; Draws a string based on a font, a layout rectangle, and a format.
    EndContainer()                      ; Closes a graphics container that was previously opened by the Graphics::BeginContainer method.
    EnumerateMetafile()                 ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    EnumerateMetafile()                 ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    EnumerateMetafile()                 ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    EnumerateMetafile()                 ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    EnumerateMetafile()                 ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    EnumerateMetafile()                 ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    EnumerateMetafile()                 ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    EnumerateMetafile()                 ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    EnumerateMetafile()                 ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    EnumerateMetafile()                 ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    EnumerateMetafile()                 ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    EnumerateMetafile()                 ; Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    ExcludeClip()                       ; Updates the clipping region to the portion of itself that does not intersect the specified rectangle.
    ExcludeClip()                       ; Updates the clipping region to the portion of itself that does not intersect the specified rectangle.
    ExcludeClip()                       ; Updates the clipping region with the portion of itself that does not overlap the specified region.
    FillClosedCurve()                   ; Creates a closed cardinal spline from an array of points and uses a brush to fill the interior of the spline.
    FillClosedCurve()                   ; Creates a closed cardinal spline from an array of points and uses a brush to fill, according to a specified mode, the interior of the spline.
    FillClosedCurve()                   ; Creates a closed cardinal spline from an array of points and uses a brush to fill the interior of the spline.
    FillClosedCurve()                   ; Creates a closed cardinal spline from an array of points and uses a brush to fill, according to a specified mode, the interior of the spline.
    FillEllipse()                       ; Uses a brush to fill the interior of an ellipse that is specified by a rectangle.
    FillEllipse()                       ; Uses a brush to fill the interior of an ellipse that is specified by a rectangle.
    FillEllipse()                       ; Uses a brush to fill the interior of an ellipse that is specified by coordinates and dimensions.
    FillEllipse()                       ; Uses a brush to fill the interior of an ellipse that is specified by coordinates and dimensions.
    FillPath()                          ; Uses a brush to fill the interior of a path. If a figure in the path is not closed, this method treats the nonclosed figure as if it were closed by a straight line that connects the figure's starting and ending points.
    FillPie()                           ; Uses a brush to fill the interior of a pie.
    FillPie()                           ; Uses a brush to fill the interior of a pie.
    FillPie()                           ; Uses a brush to fill the interior of a pie.
    FillPie()                           ; Uses a brush to fill the interior of a pie.
    FillPolygon()                       ; Uses a brush to fill the interior of a polygon.
    FillPolygon()                       ; Uses a brush to fill the interior of a polygon.
    FillPolygon()                       ; Uses a brush to fill the interior of a polygon.
    FillPolygon()                       ; Uses a brush to fill the interior of a polygon.
    FillRectangle()                     ; Uses a brush to fill the interior of a rectangle.
    FillRectangle()                     ; Uses a brush to fill the interior of a rectangle.
    FillRectangle()                     ; Uses a brush to fill the interior of a rectangle.
    FillRectangle()                     ; Uses a brush to fill the interior of a rectangle.
    FillRectangles()                    ; Uses a brush to fill the interior of a sequence of rectangles.
    FillRectangles()                    ; Uses a brush to fill the interior of a sequence of rectangles.
    FillRegion()                        ; Uses a brush to fill a specified region.
    Flush()                             ; Flushes all pending graphics operations.
    FromHDC()                           ; Creates a Graphics object that is associated with a specified device context.
    FromHDC()                           ; Creates a Graphics object that is associated with a specified device context and a specified device.
    FromHWND()                          ; Creates a Graphicsobject that is associated with a specified window.
    FromImage()                         ; Creates a Graphicsobject that is associated with a specified Image object.
    GetClip()                           ; Gets the clipping region of this Graphics object.
    GetClipBounds()                     ; Gets a rectangle that encloses the clipping region of this Graphics object.
    GetClipBounds()                     ; Gets a rectangle that encloses the clipping region of this Graphics object.
    GetCompositingMode()                ; Gets the compositing mode currently set for this Graphics object.
    GetCompositingQuality()             ; Gets the compositing quality currently set for this Graphics object.
    GetDpiX()                           ; Gets the horizontal resolution, in dots per inch, of the display device associated with this Graphics object.
    GetDpiY()                           ; Gets the vertical resolution, in dots per inch, of the display device associated with this Graphics object.
    GetHalftonePalette()                ; Gets a Windows halftone palette.
    GetHDC()                            ; Gets a handle to the device context associated with this Graphics object.
    GetInterpolationMode()              ; Gets the interpolation mode currently set for this Graphics object. The interpolation mode determines the algorithm that is used when images are scaled or rotated.
    GetLastStatus()                     ; Returns a value that indicates the nature of this Graphics object's most recent method failure.
    GetNearestColor()                   ; Gets the nearest color to the color that is passed in. This method works on 8-bits per pixel or lower display devices for which there is an 8-bit color palette.
    GetPageScale()                      ; Gets the scaling factor currently set for the page transformation of this Graphics object. The page transformation converts page coordinates to device coordinates.
    GetPageUnit()                       ; Gets the unit of measure currently set for this Graphics object.
    GetPixelOffsetMode()                ; Gets the pixel offset mode currently set for this Graphics object.
    GetRenderingOrigin()                ; Gets the rendering origin currently set for this Graphics object.
    GetSmoothingMode()                  ; Determines whether smoothing (antialiasing) ; is applied to the Graphics object.
    GetTextContrast()                   ; Gets the contrast value currently set for this Graphics object. The contrast value is used for antialiasing text.
    GetTextRenderingHint()              ; Returns the text rendering mode currently set for this Graphics object.
    GetTransform()                      ; Gets the world transformation matrix of this Graphics object.
    GetVisibleClipBounds()              ; Gets a rectangle that encloses the visible clipping region of this Graphics object.
    GetVisibleClipBounds()              ; Gets a rectangle that encloses the visible clipping region of this Graphics object.
    Graphics()                          ; Lists the constructors of the Graphics class. For a complete class listing, see Graphics Class.
    Graphics()                          ; Lists the constructors of the Graphics class. For a complete class listing, see Graphics Class.
    Graphics()                          ; Creates a Graphics object that is associated with a specified device context.
    Graphics()                          ; Creates a Graphics object that is associated with a specified device context and a specified device.
    Graphics()                          ; Creates a Graphics object that is associated with a specified window.
    Graphics()                          ; Creates a Graphics object that is associated with an Image object.
    IntersectClip()                     ; Updates the clipping region of this Graphics object to the portion of the specified rectangle that intersects with the current clipping region of this Graphics object.
    IntersectClip()                     ; Updates the clipping region of this Graphics object.
    IntersectClip()                     ; Updates the clipping region of this Graphics object to the portion of the specified region that intersects with the current clipping region of this Graphics object.
    IsClipEmpty()                       ; Determines whether the clipping region of this Graphics object is empty.
    IsVisible()                         ; Determines whether the specified point is inside the visible clipping region of this Graphics object.
    IsVisible()                         ; Determines whether the specified point is inside the visible clipping region of this Graphics object.
    IsVisible()                         ; Determines whether the specified rectangle intersects the visible clipping region of this Graphics object.
    IsVisible()                         ; Determines whether the specified rectangle intersects the visible clipping region of this Graphics object.
    IsVisible()                         ; Determines whether the specified point is inside the visible clipping region of this Graphics object.
    IsVisible()                         ; Determines whether the specified rectangle intersects the visible clipping region of this Graphics object.
    IsVisible()                         ; Determines whether the specified point is inside the visible clipping region of this Graphics object.
    IsVisible()                         ; Determines whether the specified rectangle intersects the visible clipping region of this Graphics object.
    IsVisibleClipEmpty()                ; Determines whether the visible clipping region of this Graphics object is empty. The visible clipping region is the intersection of the clipping region of this Graphics object and the clipping region of the window.
    MeasureCharacterRanges()            ; Gets a set of regions each of which bounds a range of character positions within a string.
    MeasureDriverString()               ; Measures the bounding box for the specified characters and their corresponding positions.
    MeasureString()                     ; Measures the extent of the string in the specified font, format, and layout rectangle.
    MeasureString()                     ; Measures the extent of the string in the specified font and layout rectangle.
    MeasureString()                     ; Measures the extent of the string in the specified font, format, and layout rectangle.
    MeasureString()                     ; Measures the extent of the string in the specified font and layout rectangle.
    MeasureString()                     ; Measures the extent of the string in the specified font, format, and layout rectangle.
    MultiplyTransform()                 ; Updates this Graphics object's world transformation matrix with the product of itself and another matrix.
    ReleaseHDC()                        ; Releases a device context handle obtained by a previous call to the Graphics::GetHDC method of this Graphics object.
    ResetClip()                         ; Sets the clipping region of this Graphics object to an infinite region.
    ResetTransform()                    ; Sets the world transformation matrix of this Graphics object to the identity matrix.
    Restore()                           ; Sets the state of this Graphics object to the state stored by a previous call to the Graphics::Save method of this Graphics object.
    RotateTransform()                   ; Updates the world transformation matrix of this Graphics object with the product of itself and a rotation matrix.
    Save()                              ; Saves the current state (transformations, clipping region, and quality settings) ; of this Graphics object. You can restore the state later by calling the Graphics::Restore method.
    ScaleTransform()                    ; Updates this Graphics object's world transformation matrix with the product of itself and a scaling matrix.
    SetAbort()                          ; Not used in Windows GDI+ versions 1.0 and 1.1.
    SetClip()                           ; Updates the clipping region of this Graphics object.
    SetClip()                           ; Updates the clipping region of this Graphics object to a region that is the combination of itself and the region specified by a graphics path.
    SetClip()                           ; Updates the clipping region of this Graphics object to a region that is the combination of itself and a rectangle.
    SetClip()                           ; Updates the clipping region of this Graphics object to a region that is the combination of itself and a rectangle.
    SetClip()                           ; Updates the clipping region of this Graphics object to a region that is the combination of itself and the region specified by a Region object.
    SetClip()                           ; Updates the clipping region of this Graphics object to a region that is the combination of itself and a Windows Graphics Device Interface (GDI) ; region.
    SetCompositingMode()                ; Sets the compositing mode of this Graphics object.
    SetCompositingQuality()             ; Sets the compositing quality of this Graphics object.
    SetInterpolationMode()              ; Sets the interpolation mode of this Graphics object. The interpolation mode determines the algorithm that is used when images are scaled or rotated.
    SetPageScale()                      ; Sets the scaling factor for the page transformation of this Graphics object. The page transformation converts page coordinates to device coordinates.
    SetPageUnit()                       ; Sets the unit of measure for this Graphics object. The page unit belongs to the page transformation, which converts page coordinates to device coordinates.
    SetPixelOffsetMode()                ; Sets the pixel offset mode of this Graphics object.
    SetRenderingOrigin()                ; Sets the rendering origin of this Graphics object. The rendering origin is used to set the dither origin for 8-bits-per-pixel and 16-bits-per-pixel dithering and is also used to set the origin for hatch brushes.
    SetSmoothingMode()                  ; Sets the rendering quality of the Graphics object.
    SetTextContrast()                   ; Sets the contrast value of this Graphics object. The contrast value is used for antialiasing text.
    SetTextRenderingHint()              ; Sets the text rendering mode of this Graphics object.
    SetTransform()                      ; Sets the world transformation of this Graphics object.
    TransformPoints()                   ; Converts an array of points from one coordinate space to another. The conversion is based on the current world and page transformations of this Graphics object.
    TransformPoints()                   ; Converts an array of points from one coordinate space to another. The conversion is based on the current world and page transformations of this Graphics object.
    TranslateClip()                     ; Translates the clipping region of this Graphics object.
    TranslateClip()                     ; Translates the clipping region of this Graphics object.
    TranslateTransform()                ; Updates this Graphics object's world transformation matrix with the product of itself and a translation matrix.
                                                                                                                                                                                       
GraphicsPath                            ; Stores a sequence of lines, curves, and shapes. You can also place markers in the sequence, so that you can draw selected portions of the path.
    ::Inherit::                         
    ::Methods::                         
    AddArc()                            ; Adds an elliptical arc to the current figure of this path.
    AddArc()                            ; Adds an elliptical arc to the current figure of this path.
    AddArc()                            ; Adds an elliptical arc to the current figure of this path.
    AddArc()                            ; Adds an elliptical arc to the current figure of this path.
    AddBezier()                         ; Adds a Bezier spline to the current figure of this path.
    AddBezier()                         ; Adds a Bezier spline to the current figure of this path.
    AddBezier()                         ; Adds a Bezier spline to the current figure of this path.
    AddBezier()                         ; Adds a Bezier spline to the current figure of this path.
    AddBeziers()                        ; Adds a sequence of connected Bezier splines to the current figure of this path.
    AddBeziers()                        ; Adds a sequence of connected Bezier splines to the current figure of this path.
    AddClosedCurve()                    ; Adds a closed cardinal spline to this path.
    AddClosedCurve()                    ; Adds a closed cardinal spline to this path.
    AddClosedCurve()                    ; Adds a closed cardinal spline to this path.
    AddClosedCurve()                    ; Adds a closed cardinal spline to this path.
    AddCurve()                          ; Adds a cardinal spline to the current figure of this path.
    AddCurve()                          ; Adds a cardinal spline to the current figure of this path.
    AddCurve()                          ; Adds a cardinal spline to the current figure of this path.
    AddCurve()                          ; Adds a cardinal spline to the current figure of this path.
    AddCurve()                          ; Adds a cardinal spline to the current figure of this path.
    AddCurve()                          ; Adds a cardinal spline to the current figure of this path.
    AddEllipse()                        ; Adds an ellipse to this path.
    AddEllipse()                        ; Adds an ellipse to this path.
    AddEllipse()                        ; Adds an ellipse to this path.
    AddEllipse()                        ; Adds an ellipse to this path.
    AddLine()                           ; Adds a line to the current figure of this path.
    AddLine()                           ; Adds a line to the current figure of this path.
    AddLine()                           ; Adds a line to the current figure of this path.
    AddLine()                           ; Adds a line to the current figure of this path.
    AddLines()                          ; Adds a sequence of connected lines to the current figure of this path.
    AddLines()                          ; Adds a sequence of connected lines to the current figure of this path.
    AddPath()                           ; Adds a path to this path.
    AddPie()                            ; Adds a pie to this path.
    AddPie()                            ; Adds a pie to this path.
    AddPie()                            ; Adds a pie to this path.
    AddPie()                            ; Adds a pie to this path.
    AddPolygon()                        ; Adds a polygon to this path.
    AddPolygon()                        ; Adds a polygon to this path.
    AddRectangle()                      ; Adds a rectangle to this path.
    AddRectangle()                      ; Adds a rectangle to this path.
    AddRectangles()                     ; Adds a sequence of rectangles to this path
    AddRectangles()                     ; Adds a sequence of rectangles to this path.
    AddString()                         ; Adds the outlines of a string to this path.
    AddString()                         ; Adds the outline of a string to this path.
    AddString()                         ; Adds the outline of a string to this path.
    AddString()                         ; Adds the outline of a string to this path.
    ClearMarkers()                      ; Clears the markers from this path.
    Clone()                             ; Creates a new GraphicsPath object, and initializes it with the contents of this GraphicsPath object.
    CloseAllFigures()                   ; Closes all open figures in this path.
    CloseFigure()                       ; Closes the current figure of this path.
    Flatten()                           ; Applies a transformation to this path and converts each curve in the path to a sequence of connected lines.
    GetBounds()                         ; Gets a bounding rectangle for this path.
    GetBounds()                         ; Gets a bounding rectangle for this path.
    GetFillMode()                       ; Gets the fill mode of this path.
    GetLastPoint()                      ; Gets the ending point of the last figure in this path.
    GetLastStatus()                     ; Returns a value that indicates the nature of this GraphicsPath object's most recent method failure.
    GetPathData()                       ; Gets an array of points and an array of point types from this path. Together, these two arrays define the lines, curves, figures, and markers of this path.
    GetPathPoints()                     ; Gets this path's array of points. The array contains the endpoints and control points of the lines and Bezier splines that are used to draw the path.
    GetPathPoints()                     ; Gets this path's array of points.
    GetPathTypes()                      ; Gets this path's array of point types.
    GetPointCount()                     ; Gets the number of points in this path's array of data points. This is the same as the number of types in the path's array of point types.
    GraphicsPath()                      ; Lists the constructors of the GraphicsPath class. For a complete class listing, see GraphicsPath Class.
    GraphicsPath()                      ; Creates a GraphicsPath object based on an array of points, an array of types, and a fill mode.
    GraphicsPath()                      ; Creates a GraphicsPath object based on an array of points, an array of types, and a fill mode.
    GraphicsPath()                      ; Creates a GraphicsPath object and initializes the fill mode. This is the default constructor.
    GraphicsPath()                      ; Lists the constructors of the GraphicsPath class. For a complete class listing, see GraphicsPath Class.
    IsOutlineVisible()                  ; Determines whether a specified point touches the outline of this path when the path is drawn by a specified Graphicsobject and a specified pen.
    IsOutlineVisible()                  ; Determines whether a specified point touches the outline of a path.
    IsOutlineVisible()                  ; Determines whether a specified point touches the outline of this path when the path is drawn by a specified Graphics object and a specified pen.
    IsOutlineVisible()                  ; Determines whether a specified point touches the outline of this path when the path is drawn by a specified Graphics object and a specified pen.
    IsVisible()                         ; Determines whether a specified point lies in the area that is filled when this path is filled by a specified Graphics object.
    IsVisible()                         ; Determines whether a specified point lies in an area.
    IsVisible()                         ; Determines whether a specified point lies in the area that is filled when this path is filled by a specified Graphicsobject.
    IsVisible()                         ; Determines whether a specified point lies in the area that is filled when this path is filled by a specified Graphics object.
    Outline()                           ; Transforms and flattens this path, and then converts this path's data points so that they represent only the outline of the path.
    Reset()                             ; Empties the path and sets the fill mode to FillModeAlternate.
    Reverse()                           ; Reverses the order of the points that define this path's lines and curves.
    SetFillMode()                       ; Sets the fill mode of this path.
    SetMarker()                         ; Designates the last point in this path as a marker point.
    StartFigure()                       ; Starts a new figure without closing the current figure. Subsequent points added to this path are added to the new figure.
    Transform()                         ; Multiplies each of this path's data points by a specified matrix.
    Warp()                              ; Applies a warp transformation to this path. The GraphicsPath::Warp method also flattens (converts to a sequence of straight lines) ; the path.
    Widen()                             ; Replaces this path with curves that enclose the area that is filled when this path is drawn by a specified pen. The GraphicsPath::Widen method also flattens the path.
                                                                                                                                                                                       
GraphicsPathIterator                    ; Provides methods for isolating selected subsets of the path stored in a GraphicsPath object.
    ::Inherit::                         
    ::Methods::                         
    CopyData()                          ; Copies a subset of the path's data points to a PointF array and copies a subset of the path's point types to a BYTE array.
    Enumerate()                         ; Copies the path's data points to a PointF array and copies the path's point types to a BYTE array.
    GetCount()                          ; Returns the number of data points in the path.
    GetLastStatus()                     ; Returns a value that indicates the nature of this GraphicsPathIterator object's most recent method failure.
    GetSubpathCount()                   ; Returns the number of subpaths (also called figures) ; in the path.
    GraphicsPathIterator()              ; Creates a new GraphicsPathIterator object and associates it with a GraphicsPath object.
    GraphicsPathIterator()              ; Copy constructor for GraphicsPathIterator.
    HasCurve()                          ; Determines whether the path has any curves.
    NextMarker()                        ; Gets the next marker-delimited section of this iterator's associated path.
    NextMarker()                        ; Gets the starting index and the ending index of a section.
    NextPathType()                      ; Gets the starting index and the ending index of the next group of data points that all have the same type.
    NextSubpath()                       ; Gets the next figure (subpath) ; from this iterator's associated path.
    NextSubpath()                       ; Gets the starting index and the ending index of the next subpath.
    Rewind()                            ; Rewinds this iterator to the beginning of its associated path.
                                                                                                                                                                                       
HatchBrush                              ; Defines a rectangular brush with a hatch style, a foreground color, and a background color. There are six hatch styles.
    ::Inherit::                         ; The HatchBrush class implements Brush.
    ::Methods::                         
    GetBackgroundColor()                ; Gets the background color of this hatch brush.
    GetForegroundColor()                ; Gets the foreground color of this hatch brush.
    GetHatchStyle()                     ; Gets the hatch style of this hatch brush.
    HatchBrush()                        ; Copy constructor for HatchBrush.
    HatchBrush()                        ; Creates a HatchBrush object based on a hatch style, foreground color, and background color.
                                                                                                                                                                                       
HueSaturationLightness                  ; Enables you to change the hue, saturation, and lightness of a bitmap.
    ::Constructors::                    
    ::Inherit::                         ; The HueSaturationLightness class implements Effect.
    ::Methods::                         
    GetParameters()                     ; Gets the current values of the parameters of this HueSaturationLightness object.
    HueSaturationLightness()            ; Creates a HueSaturationLightness object.
    SetParameters()                     ; Sets the parameters of this HueSaturationLightness object.
                                                                                                                                                                                       
Image                                   ; Provides methods for loading and saving raster images (bitmaps) ; and vector images (metafiles).
    ::Inherit::                         ; The Image class implements GdiplusBase.
    ::Methods::                         
    Clone()                             ; Creates a new Image object and initializes it with the contents of this Image object.
    FindFirstItem()                     ; Retrieves the description and the data size of the first metadata item in this Image object.
    FindNextItem()                      ; Used along with the Image::FindFirstItem method to enumerate the metadata items stored in this Image object.
    FromFile()                          ; Creates an Image object based on a file.
    FromStream()                        ; Creates a new Image object based on a stream.
    GetAllPropertyItems()               ; Gets all the property items (metadata) ; stored in this Image object.
    GetBounds()                         ; Gets the bounding rectangle for this image.
    GetEncoderParameterList()           ; Gets a list of the parameters supported by a specified image encoder.
    GetEncoderParameterListSize()       ; Gets the size, in bytes, of the parameter list for a specified image encoder.
    GetFlags()                          ; Gets a set of flags that indicate certain attributes of this Image object.
    GetFrameCount()                     ; Gets the number of frames in a specified dimension of this Image object.
    GetFrameDimensionsCount()           ; Gets the number of frame dimensions in this Image object.
    GetFrameDimensionsList()            ; Gets the identifiers for the frame dimensions of this Image object.
    GetHeight()                         ; Gets the image height, in pixels, of this image.
    GetHorizontalResolution()           ; Gets the horizontal resolution, in dots per inch, of this image.
    GetItemData()                       ; Gets one piece of metadata from this Image object.
    GetLastStatus()                     ; Returns a value that indicates the nature of this Image object's most recent method failure.
    GetPalette()                        ; Gets the ColorPalette of this Image object.
    GetPaletteSize()                    ; Gets the size, in bytes, of the color palette of this Image object.
    GetPhysicalDimension()              ; Gets the width and height of this image.
    GetPixelFormat()                    ; Gets the pixel format of this Image object.
    GetPropertyCount()                  ; Gets the number of properties (pieces of metadata) ; stored in this Image object.
    GetPropertyIdList()                 ; Gets a list of the property identifiers used in the metadata of this Image object.
    GetPropertyItem()                   ; Gets a specified property item (piece of metadata) ; from this Image object.
    GetPropertyItemSize()               ; Gets the size, in bytes, of a specified property item of this Image object.
    GetPropertySize()                   ; Gets the total size, in bytes, of all the property items stored in this Image object. The Image::GetPropertySize method also gets the number of property items stored in this Image object.
    GetRawFormat()                      ; Gets a globally unique identifier ( GUID) ; that identifies the format of this Image object. GUIDs that identify various file formats are defined in Gdiplusimaging.h.
    GetThumbnailImage()                 ; Gets a thumbnail image from this Image object.
    GetType()                           ; Gets the type (bitmap or metafile) ; of this Image object.
    GetVerticalResolution()             ; Gets the vertical resolution, in dots per inch, of this image.
    GetWidth()                          ; Gets the width, in pixels, of this image.
    Image()                             ; Lists the constructors of the Image class. For a complete class listing, see Image Class.
    Image()                             ; Creates an Image object based on a file.
    Image()                             ; Lists the constructors of the Image class. For a complete class listing, see Image Class.
    Image()                             ; Creates an Image object based on a stream.
    Image()                             ; Lists the constructors of the Image class. For a complete class listing, see Image Class.
    RemovePropertyItem()                ; Removes a property item (piece of metadata) ; from this Image object.
    RotateFlip()                        ; Rotates and flips this image.
    Save()                              ; Saves this image to a file.
    Save()                              ; Saves this image to a stream.
    SaveAdd()                           ; Adds a frame to a file or stream specified in a previous call to the Save method.
    SaveAdd()                           ; Adds a frame to a file or stream specified in a previous call to the Save method.
    SelectActiveFrame()                 ; Selects the frame in this Image object specified by a dimension and an index.
    SetAbort()                          ; Sets the object whose Abort method is called periodically during time-consuming rendering operation.
    SetPalette()                        ; Sets the color palette of this Image object.
    SetPropertyItem()                   ; Sets a property item (piece of metadata) ; for this Image object. If the item already exists, then its contents are updated; otherwise, a new item is added.
                                                                                                                                                                                   
ImageAttributes                         ; Contains information about how bitmap and metafile colors are manipulated during rendering.                                                                    
    ::Inherit::                         ; The ImageAttributes class implements GdiplusBase.
    ::Methods::                         
    ClearBrushRemapTable()              ; Clears the brush color-remap table of this ImageAttributes object.
    ClearColorKey()                     ; Clears the color key (transparency range) ; for a specified category.
    ClearColorMatrices()                ; Clears the color-adjustment matrix and the grayscale-adjustment matrix for a specified category.
    ClearColorMatrix()                  ; Clears the color-adjustment matrix for a specified category.
    ClearGamma()                        ; Disables gamma correction for a specified category.
    ClearNoOp()                         ; Clears the NoOp setting for a specified category.
    ClearOutputChannel()                ; Clears the cyan-magenta-yellow-black (CMYK) ; output channel setting for a specified category.
    ClearOutputChannelColorProfile()    ; Clears the output channel color profile setting for a specified category.
    ClearRemapTable()                   ; Clears the color-remap table for a specified category.
    ClearThreshold()                    ; Clears the threshold value for a specified category.
    Clone()                             ; Makes a copy of this ImageAttributes object.
    GetAdjustedPalette()                ; Adjusts the colors in a palette according to the adjustment settings of a specified category.
    GetLastStatus()                     ; Returns a value that indicates the nature of this ImageAttributes object's most recent method failure.
    ImageAttributes()                   ; Creates an ImageAttributes object. This is the default constructor.
    ImageAttributes()                   ; Creates an ImageAttributes object. This is the default constructor.
    ImageAttributes()                   ; Creates an ImageAttributes object. This is the default constructor.
    Reset()                             ; Clears all color- and grayscale-adjustment settings for a specified category.
    SetBrushRemapTable()                ; Sets the color remap table for the brush category.
    SetColorKey()                       ; Sets the color key (transparency range) ; for a specified category.
    SetColorMatrices()                  ; Sets the color-adjustment matrix and the grayscale-adjustment matrix for a specified category.
    SetColorMatrix()                    ; Sets the color-adjustment matrix for a specified category.
    SetGamma()                          ; Sets the gamma value for a specified category.
    SetNoOp()                           ; Turns off color adjustment for a specified category. You can call ImageAttributes::ClearNoOp to reinstate the color-adjustment settings that were in place before the call to ImageAttributes::SetNoOp.
    SetOutputChannel()                  ; Sets the CMYK output channel for a specified category.
    SetOutputChannelColorProfile()      ; Sets the output channel color-profile file for a specified category.
    SetRemapTable()                     ; Sets the color-remap table for a specified category.
    SetThreshold()                      ; Sets the threshold (transparency range) ; for a specified category.
    SetToIdentity()                     ; Sets the color-adjustment matrix of a specified category to identity matrix.
    SetWrapMode()                       ; Sets the wrap mode of this ImageAttributes object.
                                                                                                                                                                               
ImageCodecInfo                          ; Stores information about an image codec (encoder/decoder). GDI+ provides several built-in image codecs.                                                               
    ::Methods::                         
                                                                                                                                                                               
ImageItemData                           ; Used to store and retrieve custom image metadata. Windows GDI+ supports custom metadata for JPEG, PNG, and GIF image files.                                                              
    ::Methods::                         
                                                                                                                                                                               
InstalledFontCollection                                                                                         
    ::Inherit::                         ; The InstalledFontCollection class implements FontCollection.                                                                                                                                                      
    ::Methods::                         
    InstalledFontCollection()           ; Creates an InstalledFontCollection object.
    InstalledFontCollection()           ; Creates an InstalledFontCollection object.
                                                                                                                                                                               
Levels                                  ; Encompasses three bitmap adjustments: highlight, midtone, and shadow.                                                       
    ::Inherit::                         ; The Levels class implements Effect.                                                                                                                                                      
    ::Methods::                         
    GetParameters()                     ; Gets the current values of the parameters of this Levels object.
    Levels()                            ; Creates a Levels object.
    SetParameters()                     ; Sets the parameters of this Levels object.

LinearGradientBrush                     ; Defines a brush that paints a color gradient in which the color changes evenly from the starting boundary line of the linear gradient brush to the ending boundary line of the linear gradient brush.                                                                    
    ::Inherit::                         ; The LinearGradientBrush class implements Brush.
    ::Methods::                         
    GetBlend()                          ; Gets the blend factors and their corresponding blend positions from a LinearGradientBrush object.
    GetBlendCount()                     ; Gets the number of blend factors currently set for this LinearGradientBrush object.
    GetGammaCorrection()                ; Determines whether gamma correction is enabled for this LinearGradientBrush object.
    GetInterpolationColorCount()        ; Gets the number of colors currently set to be interpolated for this linear gradient brush.
    GetInterpolationColors()            ; Gets the colors currently set to be interpolated for this linear gradient brush and their corresponding blend positions.
    GetLinearColors()                   ; Gets the starting color and ending color of this linear gradient brush.
    GetRectangle()                      ; Gets the rectangle that defines the boundaries of the gradient.
    GetRectangle()                      ; Lists the GetRectangle methods of the LinearGradientBrush class. For a complete list of methods for the LinearGradientBrush class, see LinearGradientBrush Methods.
    GetTransform()                      ; Gets the transformation matrix of this linear gradient brush.
    GetWrapMode()                       ; Gets the wrap mode for this brush. The wrap mode determines how an area is tiled when it is painted with a brush.
    LinearGradientBrush()               ; Lists the constructors of the LinearGradientBrush class. For a complete class listing, see LinearGradientBrush Class.
    LinearGradientBrush()               ; Lists the constructors of the LinearGradientBrush class. For a complete class listing, see LinearGradientBrush Class.
    LinearGradientBrush()               ; Creates a LinearGradientBrush object from a set of boundary points and boundary colors.
    LinearGradientBrush()               ; Creates a LinearGradientBrush object based on a rectangle and mode of direction.
    LinearGradientBrush()               ; Creates a LinearGradientBrush object from a rectangle and angle of direction.
    LinearGradientBrush()               ; Creates a LinearGradientBrush object based on a rectangle and mode of direction.
    LinearGradientBrush()               ; Creates a LinearGradientBrush object from a rectangle and angle of direction.
    LinearGradientBrush()               ; Lists the constructors of the LinearGradientBrush class. For a complete class listing, see LinearGradientBrush Class.
    MultiplyTransform()                 ; Updates this brush's transformation matrix with the product of itself and another matrix.
    ResetTransform()                    ; Resets the transformation matrix of this linear gradient brush to the identity matrix. This means that no transformation takes place.
    RotateTransform()                   ; Updates this brush's current transformation matrix with the product of itself and a rotation matrix.
    ScaleTransform()                    ; Updates this brush's current transformation matrix with the product of itself and a scaling matrix.
    SetBlend()                          ; Sets the blend factors and the blend positions of this linear gradient brush to create a custom blend.
    SetBlendBellShape()                 ; Sets the blend shape of this linear gradient brush to create a custom blend based on a bell-shaped curve.
    SetBlendTriangularShape()           ; Sets the blend shape of this linear gradient brush to create a custom blend based on a triangular shape.
    SetGammaCorrection()                ; Specifies whether gamma correction is enabled for this linear gradient brush.
    SetInterpolationColors()            ; Sets the colors to be interpolated for this linear gradient brush and their corresponding blend positions.
    SetLinearColors()                   ; Sets the starting color and ending color of this linear gradient brush.
    SetTransform()                      ; Sets the transformation matrix of this linear gradient brush.
    SetWrapMode()                       ; Sets the wrap mode of this linear gradient brush.
    TranslateTransform()                ; Updates this brush's current transformation matrix with the product of itself and a translation matrix.

Matrix                                  ; Represents a 3 ×3 matrix that, in turn, represents an affine transformation.
    ::Inherit::                         ; The Matrix class implements GdiplusBase.
    ::Methods::                         
    Clone()                             ; Creates a new Matrix object that is a copy of this Matrix object.
    Equals()                            ; Determines whether the elements of this matrix are equal to the elements of another matrix.
    GetElements()                       ; Gets the elements of this matrix. The elements are placed in an array in the order m11, m12, m21, m22, m31, m32, where mij denotes the element in row i, column j.
    GetLastStatus()                     ; Returns a value that indicates the nature of this Matrix object's most recent method failure.
    Invert()                            ; Replaces the elements of this matrix with the elements of its inverse, if this matrix is invertible.
    IsIdentity()                        ; Determines whether this matrix is the identity matrix.
    IsInvertible()                      ; Determines whether this matrix is invertible.
    Matrix()                            ; Creates and initializes a Matrix object that represents the identity matrix.
    Matrix()                            ; Creates and initializes a Matrix object that represents the identity matrix.
    Matrix()                            ; Creates a Matrix object based on a rectangle and a point.
    Matrix()                            ; Creates a Matrix object based on a rectangle and a point.
    Matrix()                            ; Creates and initializes a Matrix object that represents the identity matrix.
    Matrix()                            ; Creates and initializes a Matrix object based on six numbers that define an affine transformation.
    Multiply()                          ; Updates this matrix with the product of itself and another matrix.
    OffsetX()                           ; Gets the horizontal translation value of this matrix, which is the element in row 3, column 1.
    OffsetY()                           ; Gets the vertical translation value of this matrix, which is the element in row 3, column 2.
    Reset()                             ; Updates this matrix with the elements of the identity matrix.
    Rotate()                            ; Updates this matrix with the product of itself and a rotation matrix.
    RotateAt()                          ; Updates this matrix with the product of itself and a matrix that represents rotation about a specified point.
    Scale()                             ; Updates this matrix with the product of itself and a scaling matrix.
    SetElements()                       ; Sets the elements of this matrix.
    Shear()                             ; Updates this matrix with the product of itself and a shearing matrix.
    TransformPoints()                   ; Multiplies each point in an array by this matrix. Each point is treated as a row matrix. The multiplication is performed with the row matrix on the left and this matrix on the right.
    TransformPoints()                   ; Lists the TransformPoints methods of the Matrix class. For a complete list of methods for the Matrix class, see Matrix Methods.
    TransformVectors()                  ; Multiplies each vector in an array by this matrix.
    TransformVectors()                  ; Lists the TransformVectors methods of the Matrix class. For a complete list of methods for the Matrix class, see Matrix Methods.
    Translate()                         ; Updates this matrix with the product of itself and a translation matrix.
                                                                                                                                                                               
Metafile                                ; Defines a graphic metafile.
    ::Inherit::                         ; The Metafile class implements Image.
    ::Methods::                         
    ConvertToEmfPlus()                  ; Converts this Metafile object to the EMF+ format.
    ConvertToEmfPlus()                  ; Converts this Metafile object to the EMF+ format.
    ConvertToEmfPlus()                  ; Converts this Metafile object to the EMF+ format.
    EmfToWmfBits()                      ; Converts an enhanced-format metafile to a Windows Metafile Format (WMF) ; metafile and stores the converted records in a specified buffer.
    GetDownLevelRasterizationLimit()    ; Gets the rasterization limit currently set for this metafile.
    GetHENHMETAFILE()                   ; Gets a Windows handle to an Enhanced Metafile (EMF) ; file.
    GetMetafileHeader()                 ; Gets the header.
    GetMetafileHeader()                 ; Gets the header.
    GetMetafileHeader()                 ; Gets the metafile header of this metafile.
    GetMetafileHeader()                 ; Gets the header.
    GetMetafileHeader()                 ; Gets the header.
    Metafile()                          ; Lists the constructors of the Metafile class. For a complete class listing, see Metafile Class.
    Metafile()                          ; Creates a Metafile object for playback.
    Metafile()                          ; Lists the constructors of the Metafile class. For a complete class listing, see Metafile Class.
    Metafile()                          ; Creates a Metafile object for recording.
    Metafile()                          ; Creates a Metafile object for recording.
    Metafile()                          ; Creates a Metafile object for recording.
    Metafile()                          ; Creates a Metafile object for recording.
    Metafile()                          ; Creates a Metafile object for recording.
    Metafile()                          ; Creates a Metafile object for recording.
    Metafile()                          ; Creates a Windows GDI+ Metafile object for playback based on a Windows Graphics Device Interface (GDI) ; Enhanced Metafile (EMF) ; file.
    Metafile()                          ; Creates a Windows GDI+Metafile object for recording. The format will be placeable metafile.
    Metafile()                          ; Creates a Metafile object from an IStream interface for playback.
    Metafile()                          ; Creates a Metafile object for recording to an IStream interface.
    Metafile()                          ; Creates a Metafile object for recording to an IStream interface.
    Metafile()                          ; Creates a Metafile object for recording to an IStream interface.
    Metafile()                          ; Lists the constructors of the Metafile class. For a complete class listing, see Metafile Class.
    PlayRecord()                        ; The PlayRecord method plays a metafile record.
    SetDownLevelRasterizationLimit()    ; Sets the resolution for certain brush bitmaps that are stored in this metafile.
                                                                                                                                                                               
MetafileHeader                          ; Stores properties of an associated metafile.
    ::Methods::                         
    GetBounds()                         ; Gets the bounding rectangle for the associated metafile.
    GetDpiX()                           ; Gets the horizontal dots per inch of the associated metafile.
    GetDpiY()                           ; Gets the vertical dots per inch of the associated metafile.
    GetEmfHeader()                      ; Gets an ENHMETAHEADER3 structure that contains properties of the associated metafile.
    GetEmfPlusFlags()                   ; Gets a flag that indicates whether the associated metafile was recorded against a video display device context.
    GetMetafileSize()                   ; Gets the size, in bytes, of the metafile.
    GetType()                           ; Gets the type of the associated metafile.
    GetVersion()                        ; Gets the version of the metafile.
    GetWmfHeader()                      ; Gets a METAHEADER structure that contains properties of the associated metafile.
    IsDisplay()                         ; Determines whether the associated metafile was recorded against a video display device context.
    IsEmf()                             ; Determines whether the associated metafile is in the EMF format.
    IsEmfOrEmfPlus()                    ; Determines whether the associated metafile is in either the EMF or EMF+ format.
    IsEmfPlus()                         ; Determines whether the associated metafile is in the EMF+ format.
    IsEmfPlusDual()                     ; Determines whether the associated metafile is in the EMF+ Dual format.
    IsEmfPlusOnly()                     ; Determines whether the associated metafile is in the EMF+ Only format.
    IsWmf()                             ; Determines whether the associated metafile is in the WMF format.
    IsWmfPlaceable()                    ; Determines whether the associated metafile is a placeable metafile.

PathData                                ; Get or set the data points (and their types) ; of a path. Helper class for the GraphicsPath and GraphicsPathIterator classes.
    ::Methods::                         
    ~PathData()                         ; Destructor for the PathData class.
    PathData()                          ; Creates a PathData object. The Count data member is initialized to 0. Points and Types data members are initialized to NULL.
                                                                                                                                                                               
PathGradientBrush                       ; Stores the attributes of a color gradient that you can use to fill the interior of a path with a gradually changing color.
    ::Inherit::                         ; The PathGradientBrush class implements Brush.
    ::Methods::                         
    GetBlend()                          ; Gets the blend factors and the corresponding blend positions currently set for this path gradient brush.
    GetBlendCount()                     ; Gets the number of blend factors currently set for this path gradient brush.
    GetCenterColor()                    ; Gets the color of the center point of this path gradient brush.
    GetCenterPoint()                    ; Gets the center point of this path gradient brush.
    GetCenterPoint()                    ; Gets the center point of this path gradient brush.
    GetFocusScales()                    ; Gets the focus scales of this path gradient brush.
    GetGammaCorrection()                ; Determines whether gamma correction is enabled for this path gradient brush.
    GetGraphicsPath()                   ; Is not implemented in Windows GDI+ version 1.0.
    GetInterpolationColorCount()        ; Gets the number of preset colors currently specified for this path gradient brush.
    GetInterpolationColors()            ; Gets the preset colors and blend positions currently specified for this path gradient brush.
    GetPointCount()                     ; Gets the number of points in the array of points that defines this brush's boundary path.
    GetRectangle()                      ; Gets the smallest rectangle that encloses the boundary path of this path gradient brush.
    GetRectangle()                      ; Gets the smallest rectangle that encloses the boundary path of this path gradient brush.
    GetSurroundColorCount()             ; Gets the number of colors that have been specified for the boundary path of this path gradient brush.
    GetSurroundColors()                 ; Gets the surround colors currently specified for this path gradient brush.
    GetTransform()                      ; Gets transformation matrix of this path gradient brush.
    GetWrapMode()                       ; Gets the wrap mode currently set for this path gradient brush.
    MultiplyTransform()                 ; Updates the brush's transformation matrix with the product of itself and another matrix.
    PathGradientBrush()                 ; Creates a PathGradientBrush object based on a GraphicsPath object.
    PathGradientBrush()                 ; Lists the constructors of the PathGradientBrush class. For a complete class listing, see PathGradientBrushXX Class.
    PathGradientBrush()                 ; Creates a PathGradientBrush object based on an array of points. Initializes the wrap mode of the path gradient brush.
    PathGradientBrush()                 ; Creates a PathGradientBrush object based on an array of points. Initializes the wrap mode of the path gradient brush.
    PathGradientBrush()                 ; Lists the constructors of the PathGradientBrush class. For a complete class listing, see PathGradientBrushXX Class.
    ResetTransform()                    ; Resets the transformation matrix of this path gradient brush to the identity matrix. This means that no transformation will take place.
    RotateTransform()                   ; Updates this brush's current transformation matrix with the product of itself and a rotation matrix.
    ScaleTransform()                    ; Updates this brush's current transformation matrix with the product of itself and a scaling matrix.
    SetBlend()                          ; Sets the blend factors and the blend positions of this path gradient brush.
    SetBlendBellShape()                 ; Sets the blend shape of this path gradient brush.
    SetBlendTriangularShape()           ; Sets the blend shape of this path gradient brush.
    SetCenterColor()                    ; Sets the center color of this path gradient brush. The center color is the color that appears at the brush's center point.
    SetCenterPoint()                    ; Sets the center point of this path gradient brush. By default, the center point is at the centroid of the brush's boundary path, but you can set the center point to any location inside or outside the path.
    SetCenterPoint()                    ; Sets the center point of this path gradient brush.
    SetFocusScales()                    ; Sets the focus scales of this path gradient brush.
    SetGammaCorrection()                ; Specifies whether gamma correction is enabled for this path gradient brush.
    SetGraphicsPath()                   ; Is not implemented in Windows GDI+ version 1.0.
    SetInterpolationColors()            ; Sets the preset colors and the blend positions of this path gradient brush.
    SetSurroundColors()                 ; Sets the surround colors of this path gradient brush. The surround colors are colors specified for discrete points on the brush's boundary path.
    SetTransform()                      ; Sets the transformation matrix of this path gradient brush.
    SetWrapMode()                       ; Sets the wrap mode of this path gradient brush.
    TranslateTransform()                ; Updates this brush's current transformation matrix with the product of itself and a translation matrix.
                                        
Pen                                     ; A Windows GDI+ object used to draw lines and curves
    ::Inherit::                         ; The Pen class implements GdiplusBase.
    ::Methods::                         
    Clone()                             ; Copies a Pen object.
    GetAlignment()                      ; Gets the alignment currently set for this Pen object.
    GetBrush()                          ; Gets the Brush object that is currently set for this Pen object.
    GetColor()                          ; Gets the color currently set for this Pen object.
    GetCompoundArray()                  ; Gets the compound array currently set for this Pen object.
    GetCompoundArrayCount()             ; Gets the number of elements in a compound array.
    GetCustomEndCap()                   ; Gets the custom end cap currently set for this Pen object.
    GetCustomStartCap()                 ; Gets the custom start cap currently set for this Pen object.
    GetDashCap()                        ; Gets the dash cap style currently set for this Pen object.
    GetDashOffset()                     ; Gets the distance from the start of the line to the start of the first space in a dashed line.
    GetDashPattern()                    ; Gets an array of custom dashes and spaces currently set for this Pen object.
    GetDashPatternCount()               ; Gets the number of elements in a dash pattern array.
    GetDashStyle()                      ; Gets the dash style currently set for this Pen object.
    GetEndCap()                         ; Gets the end cap currently set for this Pen object.
    GetLastStatus()                     ; Returns a value that indicates the nature of this Pen object's most recent method failure.
    GetLineJoin()                       ; Gets the line join style currently set for this Pen object.
    GetMiterLimit()                     ; Gets the miter length currently set for this Pen object.
    GetPenType()                        ; Gets the type currently set for this Pen object.
    GetStartCap()                       ; Gets the start cap currently set for this Pen object.
    GetTransform()                      ; Gets the world transformation matrix currently set for this Pen object.
    GetWidth()                          ; Gets the width currently set for this Pen object.
    MultiplyTransform()                 ; Updates the world transformation matrix of this Pen object with the product of itself and another matrix.
    Pen()                               ; Creates a Pen object that uses the attributes of a brush and a real number to set the width of this Pen object.
    Pen()                               ; Creates a Pen object that uses a specified color and width.
    Pen()                               ; Lists the constructors of the Pen class. For a complete class listing, see Pen Class.
    Pen()                               ; Lists the constructors of the Pen class. For a complete class listing, see Pen Class.
    ResetTransform()                    ; Sets the world transformation matrix of this Pen object to the identity matrix.
    RotateTransform()                   ; Updates the world transformation matrix of this Pen object with the product of itself and a rotation matrix.
    ScaleTransform()                    ; Sets the Pen object's world transformation matrix equal to the product of itself and a scaling matrix.
    SetAlignment()                      ; Sets the alignment for this Pen object relative to the line.
    SetBrush()                          ; Sets the Brush object that a pen uses to fill a line.
    SetColor()                          ; Sets the color for this Pen object.
    SetCompoundArray()                  ; Sets the compound array for this Pen object.
    SetCustomEndCap()                   ; Sets the custom end cap for this Pen object.
    SetCustomStartCap()                 ; Sets the custom start cap for this Pen object.
    SetDashCap()                        ; Sets the dash cap style for this Pen object.
    SetDashOffset()                     ; Sets the distance from the start of the line to the start of the first dash in a dashed line.
    SetDashPattern()                    ; Sets an array of custom dashes and spaces for this Pen object.
    SetDashStyle()                      ; Sets the dash style for this Pen object.
    SetEndCap()                         ; Sets the end cap for this Pen object.
    SetLineCap()                        ; Sets the cap styles for the start, end, and dashes in a line drawn with this pen.
    SetLineJoin()                       ; Sets the line join for this Pen object.
    SetMiterLimit()                     ; Sets the miter limit of this Pen object.
    SetStartCap()                       ; Sets the start cap for this Pen object.
    SetTransform()                      ; Sets the world transformation of this Pen object.
    SetWidth()                          ; Sets the width for this Pen object.
                                        
Point                                   ; Encapsulates a point in a 2-D coordinate system.
    ::Constructors::                    
    Point()                             ; Creates a Point object. Initializes X and Y data to zero. This is the default constructor.
    Point(INT,INT)                      ; Creates a Point object. Initialize the X and Y data members using passed values.
    Point(Point&)                       ; Creates a new Point object by copying the data members from another Point object.
    Point(Size&)                        ; Creates a Point object using a Size object to initialize the X and Y data members.
    ::Methods::                         
    Equals                              ; The Point::Equals method determines whether two Point objects are equal. Two points are considered equal if they have the same X and Y data members.
    operator-(Point&)                   ; The Point::operator- method subtracts the X and Y data members of two Point objects.
    operator+(Point&)                   ; The Point::operator+ method adds the X and Y data members of two Point objects.
                                        
PointF                                  
    ::Constructors::                    
    PointF()                            ; Creates a PointF object and initializes the X and Y data members to zero. This is the default constructor.
    PointF(PointF&)                     ; Creates a new PointF object and copies the data from another PointF object.
    PointF(REAL,REAL)                   ; Creates a PointF object using two real numbers to specify the X and Y data members.
    PointF(SizeF&)                      ; Creates a PointF object using a SizeF object to specify the X and Y data members.
    ::Methods::                         
    Equals                              ; Determines whether two PointF objects are equal. Two points are considered equal if they have the same X and Y data members.
    operator-(PointF&)                  ; Subtracts the X and Y data members of two PointF objects.
    operator+(PointF&)                  ; Adds the X and Y data members of two PointF objects.
                                        
PrivateFontCollection                   ; Keeps a collection of fonts specifically for an application.
    ::Inherit::                         ; The PrivateFontCollection class implements FontCollection.
    ::Methods::                         
    AddFontFile()                       ; Adds a font file to this private font collection.
    AddMemoryFont()                     ; Adds a font that is contained in system memory to a Windows GDI+ font collection.
    PrivateFontCollection()             ; Creates an empty PrivateFontCollection object.
    PrivateFontCollection()             ; Creates an empty PrivateFontCollection object.

PropertyItem                            ; A PropertyItem object holds one piece of image metadata and is a helper class for the Image and Bitmap classes.
                                        
Rect                                    ; Stores the upper-left corner's x and y, width, and height of a rectangle.
    ::Constructors::                    
    Rect()                              ; Creates a Rect object whose x-coordinate, y-coordinate, width, and height are all zero. This is the default constructor.
    Rect(INT,INT,INT,INT)               ; Creates a Rect object by using four integers to initialize the X, Y, Width, and Height data members.
    Rect(Point&,Size&)                  ; Creates a Rect object by using a Point object to initialize the X and Y data members and a Size object to initialize the Width and Height data members.
    ::Methods::                             
    Clone()                             ; Creates a new Rect object and initializes it with the contents of this Rect object.
    Contains(INT,INT)                   ; Determines whether the point ( x, y) ; is inside this rectangle.
    Contains(Point&)                    ; Determines whether a point is inside this rectangle.
    Contains(Rect&)                     ; Determines whether another rectangle is inside this rectangle.
    Equals()                            ; Determines whether two rectangles are the same.
    GetBottom()                         ; Gets the y-coordinate of the bottom edge of the rectangle.
    GetBounds()                         ; Makes a copy of this rectangle.
    GetLeft()                           ; Gets the x-coordinate of the left edge of the rectangle.
    GetLocation()                       ; Gets the coordinates of the upper-left corner of the rectangle.
    GetRight()                          ; Gets the x-coordinate of the right edge of the rectangle.
    GetSize()                           ; Gets the width and height of the rectangle.
    GetTop()                            ; Gets the y-coordinate of the top edge of the rectangle.
    Inflate(INT,INT)                    ; Expands the rectangle by dx on the left and right edges, and by dy on the top and bottom edges.
    Inflate(Point&)                     ; Expands the rectangle by the value of point.X on the left and right edges, and by the value of point.Y on the top and bottom edges.
    Intersect(Rect&)                    ; Replaces this rectangle with the intersection of itself and another rectangle.
    Intersect(Rect&,Rect&,Rect&)        ; Determines the intersection of two rectangles and stores the result in a Rect object.
    IntersectsWith()                    ; Determines whether this rectangle intersects another rectangle.
    IsEmptyArea()                       ; Determines whether this rectangle is empty.
    Offset(INT,INT)                     ; Moves the rectangle by dx horizontally and by dy vertically.
    Offset(Point&)                      ; Moves this rectangle horizontally a distance of point.X and vertically a distance of point.Y.
    Union()                             ; Determines the union of two rectangles and stores the result in a Rect object.
                                        
RectF                                   ; Stores the upper-left corner's x and y, width, and height of a rectangle. The RectF class uses floating point numbers.
    ::Constructors::                    
    RectF()                             ; Creates a RectF object and initializes the X and Y data members to zero. This is the default constructor.
    RectF(PointF&,SizeF&)               ; Creates a RectF object by using a PointF object to initialize the X and Y data members and uses a SizeF object to initialize the Width and Height data members of this rectangle.
    RectF(REAL,REAL,REAL,REAL)          ; Creates a RectF object by using four integers to initialize the X, Y, Width, and Height data members.
    ::Methods::                         
    Clone()                             ; Creates a new RectF object and initializes it with the contents of this RectF object.
    Contains(PointF&)                   ; Determines whether a point is inside this rectangle.
    Contains(REAL,REAL)                 ; Determines whether the point (x, y) ; is inside this rectangle.
    Contains(RectF&)                    ; Determines whether another rectangle is inside this rectangle.
    Equals()                            ; Determines whether two rectangles are the same.
    GetBottom()                         ; Gets the y-coordinate of the bottom edge of the rectangle.
    GetBounds()                         ; Makes a copy of this rectangle.
    GetLeft()                           ; Gets the x-coordinate of the left edge of the rectangle.
    GetLocation()                       ; Gets the coordinates of the upper-left corner of this rectangle.
    GetRight()                          ; Gets the x-coordinate of the right edge of the rectangle.
    GetSize()                           ; Gets the width and height of this rectangle.
    GetTop()                            ; Gets the y-coordinate of the top edge of the rectangle.
    Inflate(PointF&)                    ; Expands the rectangle by the value of point.X on the left and right edges, and by the value of point.Y on the top and bottom edges.
    Inflate(REAL,REAL)                  ; Expands the rectangle by dx on the left and right edges, and by dy on the top and bottom edges.
    Intersect(RectF&)                   ; Replaces this rectangle with the intersection of itself and another rectangle.
    Intersect(RectF&,RectF&,RectF&)     ; Determines the intersection of two rectangles and stores the result in a RectF object.
    IntersectsWith()                    ; Determines whether this rectangle intersects another rectangle.
    IsEmptyArea()                       ; Determines whether this rectangle is empty.
    Offset(PointF&)                     ; Moves this rectangle horizontally a distance of point.X and vertically a distance of point.Y.
    Offset(REAL,REAL)                   ; Moves the rectangle by dx horizontally and by dx vertically.
    Union()                             ; Determines the union of two rectangles and stores the result in a RectF object.
                                        
RedEyeCorrection                        ; Enables you to correct the red eyes that sometimes occur in flash photographs.
    ::Inherit::                         ; The RedEyeCorrection class implements Effect.
    ::Constructors::                    
    ::Methods::                         
    GetParameters()                     ; Gets the current values of the parameters of this RedEyeCorrection object.
    RedEyeCorrection()                  ; Creates a RedEyeCorrection object.
    SetParameters()                     ; Sets the parameters of this RedEyeCorrection object.
                                                                                                                                                                               
Region                                  ; Describes an area of the display surface. The area can be any shape.
    ::Inherit::                         ; The Region class implements GdiplusBase.
    ::Methods::                         
    Clone()                             ; Makes a copy of this Regionobject and returns the address of the new Regionobject.
    Complement()                        ; Updates this region to the portion of the specified path's interior that does not intersect this region.
    Complement()                        ; Updates a region that does not intersect this region.
    Complement()                        ; Updates this region to the portion of the specified rectangle's interior that does not intersect this region.
    Complement()                        ; Updates this region to the portion of another region that does not intersect this region.
    Equals()                            ; Determines whether this region is equal to a specified region.
    Exclude()                           ; Updates this region to the portion of itself that does not intersect the specified path's interior.
    Exclude()                           ; Updates a region that does not intersect the specified rectangle's interior.
    Exclude()                           ; Updates this region to the portion of itself that does not intersect the specified rectangle's interior.
    Exclude()                           ; Updates this region to the portion of itself that does not intersect another region.
    FromHRGN()                          ; Creates a Windows GDI+Region object from a Windows Graphics Device Interface (GDI)  ; region.
    GetBounds()                         ; Gets a rectangle that encloses this region.
    GetBounds()                         ; Gets a rectangle that encloses this region.
    GetData()                           ; Gets data that describes this region.
    GetDataSize()                       ; Gets the number of bytes of data that describes this region.
    GetHRGN()                           ; Creates a Windows Graphics Device Interface (GDI) ; region from this region.
    GetLastStatus()                     ; Returns a value that indicates the nature of this Regionobject's most recent method failure.
    GetRegionScans()                    ; Gets an array of rectangles that approximate this region. The region is transformed by a specified matrix before the rectangles are calculated.
    GetRegionScans()                    ; Gets an array of rectangles that approximate this region.
    GetRegionScansCount()               ; Gets the number of rectangles that approximate this region. The region is transformed by a specified matrix before the rectangles are calculated.
    Intersect()                         ; Updates this region to the portion of itself that intersects the specified path's interior.
    Intersect()                         ; Updates a region intersects the specified rectangle's interior.
    Intersect()                         ; Updates this region to the portion of itself that intersects the specified rectangle's interior.
    Intersect()                         ; Updates this region to the portion of itself that intersects another region.
    IsEmpty()                           ; Determines whether this region is empty.
    IsInfinite()                        ; Determines whether this region is infinite.
    IsVisible()                         ; Determines whether a point is inside this region.
    IsVisible()                         ; Determines whether a point is inside this region.
    IsVisible()                         ; Determines whether a rectangle intersects this region.
    IsVisible()                         ; Determines whether a rectangle intersects this region.
    IsVisible()                         ; Determines whether a point is inside this region.
    IsVisible()                         ; Determines whether a rectangle intersects this region.
    IsVisible()                         ; Determines whether a point is inside this region.
    IsVisible()                         ; Determines whether a rectangle intersects this region.
    MakeEmpty()                         ; Updates this region to an empty region. In other words, the region occupies no space on the display device.
    MakeInfinite()                      ; Updates this region to an infinite region.
    Region()                            ; Creates a region that is infinite. This is the default constructor.
    Region()                            ; Creates a region that is defined by data obtained from another region.
    Region()                            ; Creates a region that is defined by a path (a GraphicsPath object) ; and has a fill mode that is contained in the GraphicsPath object.
    Region()                            ; Creates a region that is defined by a rectangle.
    Region()                            ; Creates a region that is defined by a rectangle.
    Region()                            ; Creates a region that is infinite. This is the default constructor.
    Region()                            ; Creates a region that is infinite. This is the default constructor.
    Region()                            ; Creates a region that is identical to the region that is specified by a handle to a Windows Graphics Device Interface (GDI) ; region.
    Transform()                         ; Transforms this region by multiplying each of its data points by a specified matrix.
    Translate()                         ; Offsets this region by specified amounts in the horizontal and vertical directions.
    Translate()                         ; Offsets this region by specified amounts in the horizontal and vertical directions.
    Union()                             ; Updates this region to all portions (intersecting and nonintersecting) ; of itself and all portions of the specified path's interior.
    Union()                             ; Updates this region.
    Union()                             ; Updates this region to all portions (intersecting and nonintersecting) ; of itself and all portions of the specified rectangle's interior.
    Union()                             ; Updates this region to all portions (intersecting and nonintersecting) ; of itself and all portions of another region.
    Xor()                               ; Updates this region to the nonintersecting portions of itself and the specified path's interior.
    Xor()                               ; Updates a region to the nonintersecting portions with a rectangle's interior.
    Xor()                               ; Updates this region to the nonintersecting portions of itself and the specified rectangle's interior.
    Xor()                               ; Updates this region to the nonintersecting portions of itself and another region.
                                                                                                                                                                               
Sharpen                                 ; Enables you to adjust the sharpness of a bitmap.
    ::Inherit::                         ; The Sharpen class implements Effect.
    ::Methods::                         
    GetParameters()                     ; Gets the current values of the parameters of this Sharpen object.
    SetParameters()                     ; Sets the parameters of this Sharpen object.
    Sharpen()                           ; Creates a Sharpen object.
                                                                                                                                                                               
Size                                    ; Encapsulates a Width and Height dimension in a 2-D coordinate system.
    ::Constructors::                    
    Size()                              ; Creates a new Size object and initializes the members to zero. This is the default constructor.
    Size(INT,INT)                       ; Creates a Size object and initializes its Width and Height data members.
    Size(Size&)                         ; Creates a Size object and initializes its members by copying the members of another Size object.
    ::Methods::                         
    Empty                               ; Determines whether a Size object is empty.
    Equals                              ; Determines whether two Size objects are equal.
    operator-(Size&)                    ; Subtracts the Width and Height data members of two Size objects.
    operator+(Size&)                    ; Adds the Width and Height data members of two Size objects.
                                                                                                                                                                               
SizeF                                   ; Encapsulates a Width and Height dimension in a 2-D coordinate system. The SizeF class uses floating point numbers.
    ::Constructors::                    
    SizeF()                             ; Creates a SizeF object and initializes the members to zero. This is the default constructor.
    SizeF(REAL,REAL)                    ; Creates a SizeF object and initializes its Width and Height data members.
    SizeF(SizeF&)                       ; Creates a SizeF object and initializes its members by copying the members of another SizeF object.
    ::Methods::                         
    Empty                               ; The Empty method determines whether a SizeF object is empty.
    Equals                              ; The Equals method determines whether two SizeF objects are equal.
    operator-(SizeF&)                   ; The operator- method subtracts the Width and Height data members of two SizeF objects.
    operator+(SizeF&)                   ; The operator+ method adds the Width and Height data members of two SizeF objects.
                                                                                                                                                                               
SolidBrush                              ; A Brush object is used to fill in shapes similar to the way a paint brush can paint the inside of a shape.
    ::Inherit::                         ; The SolidBrush class implements Brush.
    ::Methods::                         
    GetColor()                          ; Gets the color of this solid brush.
    SetColor()                          ; Sets the color of this solid brush.
    SolidBrush()                        ; Creates a SolidBrush object based on a color.
    SolidBrush()                        ; Copy constructor for SolidBrush.
    SolidBrush()                        ; Creates a SolidBrush object based on a color.
                                                                                                                                                                               
StringFormat                            ; Encapsulates text layout information and display manipulations.
    ::Inherit::                         ; The StringFormat class implements GdiplusBase.
    ::Methods::                         
    Clone()                             ; Creates a new StringFormat object and initializes it with the contents of this StringFormat object.
    GenericDefault()                    ; Creates a generic, default StringFormat object.
    GenericTypographic()                ; Creates a generic, typographic StringFormat object.
    GetAlignment()                      ; Gets an element of the StringAlignment enumeration that indicates the character alignment of this StringFormat object in relation to the origin of the layout rectangle.
    GetDigitSubstitutionLanguage()      ; Gets the language that corresponds with the digits that are to be substituted for Western European digits.
    GetDigitSubstitutionMethod()        ; Gets an element of the StringDigitSubstitute enumeration that indicates the digit substitution method that is used by this StringFormat object.
    GetFormatFlags()                    ; Gets the string format flags for this StringFormat object.
    GetHotkeyPrefix()                   ; Gets an element of the HotkeyPrefix enumeration that indicates the type of processing that is performed on a string when a hot key prefix, an ampersand (&), is encountered.
    GetLastStatus()                     ; Returns a value that indicates the nature of this StringFormat object's most recent method failure.
    GetLineAlignment()                  ; Gets an element of the StringAlignment enumeration that indicates the line alignment of this StringFormat object in relation to the origin of the layout rectangle.
    GetMeasurableCharacterRangeCount()  ; Gets the number of measurable character ranges that are currently set. The character ranges that are set can be measured in a string by using the MeasureCharacterRanges method.
    GetTabStopCount()                   ; Gets the number of tab-stop offsets in this StringFormat object.
    GetTabStops()                       ; Gets the offsets of the tab stops in this StringFormat object.
    GetTrimming()                       ; Gets an element of the StringTrimming enumeration that indicates the trimming style of this StringFormat object.
    SetAlignment()                      ; Sets the character alignment of this StringFormat object in relation to the origin of the layout rectangle. A layout rectangle is used to position the displayed string.
    SetDigitSubstitution()              ; Sets the digit substitution method and the language that corresponds to the digit substitutes.
    SetFormatFlags()                    ; Sets the format flags for this StringFormat object. The format flags determine most of the characteristics of a StringFormat object.
    SetHotkeyPrefix()                   ; Sets the type of processing that is performed on a string when the hot key prefix, an ampersand (&), is encountered.
    SetLineAlignment()                  ; Sets the line alignment of this StringFormat object in relation to the origin of the layout rectangle.
    SetMeasurableCharacterRanges()      ; Sets a series of character ranges for this StringFormat object that, when in a string, can be measured by the MeasureCharacterRanges method.
    SetTabStops()                       ; Sets the offsets for tab stops in this StringFormat object.
    SetTrimming()                       ; Sets the trimming style for this StringFormat object. The trimming style determines how to trim a string so that it fits into the layout rectangle.
    StringFormat()                      ; Creates a StringFormat object from another StringFormat object.
    StringFormat()                      ; Lists the constructors of the StringFormat class. For a complete class listing, see StringFormat Class.
    StringFormat()                      ; Lists the constructors of the StringFormat class. For a complete class listing, see StringFormat Class.
    StringFormat()                      ; Creates a StringFormat object based on string format flags and a language.
                                                                                                                                                                               
TextureBrush                            ; Defines a Brush object that contains an Image object that is used for the fill.
    ::Inherit::                         ; The TextureBrush class implements Brush.
    ::Methods::                         
    GetImage()                          ; Gets a pointer to the Image object that is defined by this texture brush.
    GetTransform()                      ; Gets the transformation matrix of this texture brush.
    GetWrapMode()                       ; Gets the wrap mode currently set for this texture brush.
    MultiplyTransform()                 ; Updates this brush's transformation matrix with the product of itself and another matrix.
    ResetTransform()                    ; Resets the transformation matrix of this texture brush to the identity matrix. This means that no transformation takes place.
    RotateTransform()                   ; Updates this texture brush's current transformation matrix with the product of itself and a rotation matrix.
    ScaleTransform()                    ; Updates this texture brush's current transformation matrix with the product of itself and a scaling matrix.
    SetTransform()                      ; Sets the transformation matrix of this texture brush.
    SetWrapMode()                       ; Sets the wrap mode of this texture brush.
    TextureBrush()                      ; Lists the constructors of the TextureBrush class. For a complete class listing, see TextureBrush Class.
    TextureBrush()                      ; Creates a TextureBrush object based on an image, a defining rectangle, and a set of image properties.
    TextureBrush()                      ; Creates a TextureBrush object based on an image, a defining rectangle, and a set of image properties.
    TextureBrush()                      ; Creates a TextureBrush object based on an image and a wrap mode. The size of the brush defaults to the size of the image, so the entire image is used by the brush.
    TextureBrush()                      ; Creates a TextureBrush object based on an image, a wrap mode, and a defining rectangle.
    TextureBrush()                      ; Creates a TextureBrush object based on an image, a wrap mode, and a defining rectangle.
    TextureBrush()                      ; Creates a TextureBrush object based on an image, a wrap mode, and a defining set of coordinates.
    TextureBrush()                      ; Creates a TextureBrush object based on an image, a wrap mode, and a defining set of coordinates.
    TextureBrush()                      ; Lists the constructors of the TextureBrush class. For a complete class listing, see TextureBrush Class.
    TranslateTransform()                ; Updates this brush's current transformation matrix with the product of itself and a translation matrix.
                                                                                                                                                                               
Tint                                    ; Enables you to apply a tint to a bitmap.
    ::Inherit::                         ; The Tint class implements Effect.
    ::Methods::                         
    GetParameters()                     ; Gets the current values of the parameters of this Tint object.
    SetParameters()                     ; Sets the parameters of this Tint object.
    Tint()                              ; Creates a Tint object.
*/
