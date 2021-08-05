#Warn
GDIP.__New()

test()
ExitApp


test()
{
    FileSelectFile, img_path
    img_p := GDIP.image.FromFile(img_path, 1)
    result := GDIP.image.GetType(img_p)
    MsgBox, % "img_p: " img_p "`nresult: " result
}

*Escape::ExitApp

/*
    Log:
    20210729
        Startup and shutdown are working
        Added image class
        Image.FromFile() works
    20210730
        Image.GetType() works
        Added NativeImage to base.image to store the current image
            NativeImage is used by many methods to interact with the "Native Image"
            IMOP = IMO Pointer
    20210731
        Created rect class
            Added overloaded constructor
        Created point class
            Added overloaded constructor
        Created size class
            Added overloaded constructor
        Created gui class
        Added new_layered_window() to gui class to create fast guis
            Returns an HWND to that gui
        Created test class for testing all the things!
    20210801
        Spent almost all day learning about structs and storing them to class vars
    20210802
        Finished up Point class
        Finished up Size class
        Worked heavily on Rect class
    20210802
        More work done on Rect.
            Rode the struggle bus on intersect :(
        Updated error logging.
        Updated various descriptions.
    20210803
        OMG I slept most of the day. Been staying up too late!
    20210804
        
*/


Class GDIP
{
    Static  gdip_token  := ""
            , version   := 1.0
    
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
        VarSetCapacity(imo, A_PtrSize)                  ; Create a variable to store the native image pointer
        this.image.imo  := imo                          ; This pointer resides in base.image
        estat           := this.Startup()               ; Run GDIP startup and get token
        ;this.generate_colorName()                      ; Generate color object
        ;add other generators here
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
        
        (estat > 0)
            ? this.error_log(A_ThisFunc, "Startup has failed.", "Enum Status: " this.enum.status[estat])
            : ""
        
        this.gdip_token := token
        
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

    
    
    ;####################################################################################################################
    ;  Regular Class Methods                                                                                            |
    ;####################################################################################################################
    ; Quick boundfuncs
    _method(method_name, params := "")
    {
        bf := ObjBindMethod(this, method_name, params*)
        Return bf
    }
    
    ; Error log expects the call where the error happened
    ; The type of value or what was expected
    ; The value or what was actually received
    error_log(call, msg, expected, found)
    {
        this.last_err := A_Now "`n" call "`n" type "`n" value "`n`n"
        Return
    }
    
    ; Stores byte size of different data_type
    data_type_size(type)
    {
        Static dt  := ""
        If !IsObject(dt)
        {
            p  := A_PtrSize
            h  := (A_PtrSize = 8) ? 4 : 2
            u  := A_IsUnicode     ? 2 : 1
            dt := {}
            
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
            dt.HENHMETAFILE  := p    ,dt.PBYTE             := p    ,dt.REAL                   := 4
            dt.HFILE         := 4    ,dt.PCHAR             := p    ,dt.SC_HANDLE              := p
            dt.HFONT         := p    ,dt.PDWORD            := p    ,dt.SC_LOCK                := p
            dt.HGDIOBJ       := p    ,dt.PDWORD32          := p    ,dt.SERVICE_STATUS_HANDLE  := p
            dt.HGLOBAL       := p    ,dt.PDWORD64          := p    ,dt.SIZE_T                 := p
            dt.HHOOK         := p    ,dt.PDWORD_PTR        := p    ,dt.SSIZE_T                := p
            dt.HICON         := p    ,dt.PDWORDLONG        := p    ,dt.TBYTE                  := u
            dt.HINSTANCE     := p    ,dt.PFLOAT            := p    ,dt.TCHAR                  := u
            dt.HKEY          := p    ,dt.PHALF_PTR         := p    ,dt.UCHAR                  := 1
            dt.HKL           := p    ,dt.PHANDLE           := p    ,dt.UHALF_PTR              := h
            dt.HLOCAL        := p    ,dt.PHKEY             := p    ,dt.UINT                   := 4
            dt.HMENU         := p    ,dt.PINT              := p    ,dt.UINT16                 := 2
            dt.HMETAFILE     := p    ,dt.PINT16            := p    ,dt.UINT32                 := 4
            dt.HMODULE       := p    ,dt.PINT32            := p    ,dt.UINT64                 := 8
            dt.HMONITOR      := p    ,dt.PINT64            := p    ,dt.UINT8                  := 1
            dt.HPALETTE      := p    ,dt.PINT8             := p    ,dt.UINT_PTR               := p
            dt.HPEN          := p    ,dt.PINT_PTR          := p    ,dt.ULONG                  := 4
            dt.HRESULT       := 4    ,dt.PLCID             := p    ,dt.ULONG32                := 4
            dt.HRGN          := p    ,dt.PLONG             := p    ,dt.ULONG64                := 8
            dt.HRSRC         := p    ,dt.PLONG32           := p    ,dt.ULONG_PTR              := p
            dt.HSZ           := p    ,dt.PLONG64           := p    ,dt.ULONGLONG              := 8
            dt.HWINSTA       := p    ,dt.PLONG_PTR         := p    ,dt.USHORT                 := 2
            dt.HWND          := p    ,dt.PLONGLONG         := p    ,dt.USN                    := 8
            dt.INT16         := 2    ,dt.POINTER_32        := p    ,dt.VOID                   := 0
            dt.INT32         := 4    ,dt.POINTER_64        := p    ,dt.WCHAR                  := 2
            dt.INT64         := 8    ,dt.POINTER_SIGNED    := p    ,dt.WORD                   := 2
            dt.INT8          := 1    ,dt.POINTER_UNSIGNED  := p    ,dt.WPARAM                 := p                               
        }
        bytes := dt[type]
        If (bytes != "")
            Return bytes
        this.error_log(A_ThisFunc, "No valid datatype found.", type, "See 'data_type_size' function for list of data types.")
        Return "err"
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
        Static  native_image_p := ""
        ; The Clone method creates a new Image object and initializes it with the contents of this Image object.
        Clone(image_p="")
        {
            (image_p = "") ? image_p := this.native_image_p : ""
            VarSetCapacity(clone_p, A_PtrSize)
            estat := DllCall("gdip\GdipCloneImage"
                            ,this.Ptr   , &image_p
                            ,this.PtrA  , clone_p)
            estat ? this.error_log(A_ThisFunc, "Enum Status", estat) : ""
            MsgBox, % "imop: " imop "`nclone_p: " clone_p "`nestat: " estat 
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
            VarSetCapacity(imop, A_PtrSize)
            estat := DllCall("gdiplus\GdipLoadImageFromFile" . (icm ? "ICM" : "")
                            ,this.Ptr     , &filename
                            ,this.PtrA    , imop)
            estat ? this.error_log(A_ThisFunc, "Enum Status", estat) : ""
            Return imop
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
        
        ; Description   Gets the type (bitmap or metafile) of this Image object.
        ; imop       Pointer to image object
        ; 
        GetType(imop)
        {
            type  := ""
            estat := DllCall("gdiplus\GdipGetImageType"
                            ,this.Ptr    , imop       ; (GpImage *image, ImageType *type)
                            ,this.PtrA   , type)
            Return type
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
    Class graphics extends GDIP
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
        ; Identify's an image's main type
        Static  ImageType   := {0   :"ImageTypeUnknown"
                               ,1   :"ImageTypeBitmap"
                               ,2   :"ImageTypeMetafile" }
        
        ; GDIP status error codes
        Static  Status      := {0   : "Ok"                          ; Method call was successful.                                                     |
                               ,1   : "GenericError"                ; Error on method call that is not covered by anything else in this list.         |
                               ,2   : "InvalidParameter"            ; One of the method arguments passed was not valid.                               |
                               ,3   : "OutOfMemory"                 ; Operating system is out of memory / could not allocate memory.                  |
                               ,4   : "ObjectBusy"                  ; One of the arguments specified in the API call is already in use.               |
                               ,5   : "InsufficientBuffer"          ; A buffer passed in the API call is not large enough for the data.               |
                               ,6   : "NotImplemented"              ; Method is not implemented.                                                      |
                               ,7   : "Win32Error"                  ; Method generated a Win32 error.                                                 |
                               ,8   : "WrongState"                  ; An object state is invalid for the API call.                                    |
                               ,9   : "Aborted"                     ; Method was aborted.                                                             |
                               ,10  : "FileNotFound"                ; Specified image file or metafile cannot be found.                               |
                               ,11  : "ValueOverflow"               ; An arithmetic operation produced a numeric overflow.                            |
                               ,12  : "AccessDenied"                ; Writing is not allowed to the specified file.                                   |
                               ,13  : "UnknownImageFormat"          ; Specified image file format is not known.                                       |
                               ,14  : "FontFamilyNotFound"          ; Specified font family not found. Either not installed or spelled incorrectly.   |
                               ,15  : "FontStyleNotFound"           ; Specified style not available for this font family.                             |
                               ,16  : "NotTrueTypeFont"             ; Font retrieved from HDC or LOGFONT is not TrueType and cannot be used.          |
                               ,17  : "UnsupportedGdiplusVersion"   ; Installed GDI+ version not compatible with the application's compiled version.  |
                               ,18  : "GdiplusNotInitialized"       ; GDI+ API not initialized.                                                       |
                               ,19  : "PropertyNotFound"            ; Specified property does not exist in the image.                                 |
                               ,20  : "PropertyNotSupported"        ; Specified property not supported by image format and cannot be set.             |
                               ,21  : "ProfileNotFound" }           ; Color profile required to save in CMYK image format was not found.              |
        
    }
    
    ;####################################################################################################################
    ;  Generators                                                                                                       |
    ;####################################################################################################################
    ;####################################################################################################################
    ; Description   Generates an object containing all the named colors from CSS3/X11 and their hex codes.              |
    ;               These colors can be accessed by calling this.ColorHex.ColorsName                                    |
    ;___________________________________________________________________________________________________________________|
    generate_colorName()
    {
        color := {}
        
        ; Black and gray/grey                          ; White                                             
         color.Black                := 0x000000        ,color.MistyRose            := 0xFFE4E1         
        ,color.DarkSlateGray        := 0x2F4F4F        ,color.AntiqueWhite         := 0xFAEBD7         
        ,color.DarkSlateGrey        := 0x2F4F4F        ,color.Linen                := 0xFAF0E6         
        ,color.DimGray              := 0x696969        ,color.Beige                := 0xF5F5DC         
        ,color.DimGrey              := 0x696969        ,color.WhiteSmoke           := 0xF5F5F5         
        ,color.SlateGray            := 0x708090        ,color.LavenderBlush        := 0xFFF0F5         
        ,color.SlateGrey            := 0x708090        ,color.OldLace              := 0xFDF5E6         
        ,color.Gray                 := 0x808080        ,color.AliceBlue            := 0xF0F8FF         
        ,color.Grey                 := 0x808080        ,color.Seashell             := 0xFFF5EE         
        ,color.LightSlateGray       := 0x778899        ,color.GhostWhite           := 0xF8F8FF         
        ,color.LightSlateGrey       := 0x778899        ,color.Honeydew             := 0xF0FFF0         
        ,color.DarkGray             := 0xA9A9A9        ,color.FloralWhite          := 0xFFFAF0         
        ,color.DarkGrey             := 0xA9A9A9        ,color.Azure                := 0xF0FFFF         
        ,color.Silver               := 0xC0C0C0        ,color.MintCream            := 0xF5FFFA         
        ,color.LightGray            := 0xD3D3D3        ,color.Snow                 := 0xFFFAFA         
        ,color.LightGrey            := 0xD3D3D3        ,color.Ivory                := 0xFFFFF0         
        ,color.Gainsboro            := 0xDCDCDC        ,color.White                := 0xFFFFFF         
                                                                                                                           
        ; Red                                          ; Pink
         color.DarkRed              := 0x8B0000        ,color.MediumVioletRed      := 0xC71585
        ,color.Red                  := 0xFF0000        ,color.DeepPink             := 0xFF1493
        ,color.Firebrick            := 0xB22222        ,color.PaleVioletRed        := 0xDB7093
        ,color.Crimson              := 0xDC143C        ,color.HotPink              := 0xFF69B4
        ,color.IndianRed            := 0xCD5C5C        ,color.LightPink            := 0xFFB6C1
        ,color.LightCoral           := 0xF08080        ,color.Pink                 := 0xFFC0CB
        ,color.Salmon               := 0xFA8072        
        ,color.DarkSalmon           := 0xE9967A        
        ,color.LightSalmon          := 0xFFA07A        
                                                                                                                           
        ; Blue                                         ; Purple, violet, and magenta                           
         color.Navy                 := 0x000080        ,color.Indigo               := 0x4B0082             
        ,color.DarkBlue             := 0x00008B        ,color.Purple               := 0x800080             
        ,color.MediumBlue           := 0x0000CD        ,color.DarkMagenta          := 0x8B008B             
        ,color.Blue                 := 0x0000FF        ,color.DarkViolet           := 0x9400D3             
        ,color.MidnightBlue         := 0x191970        ,color.DarkSlateBlue        := 0x483D8B             
        ,color.RoyalBlue            := 0x4169E1        ,color.BlueViolet           := 0x8A2BE2             
        ,color.SteelBlue            := 0x4682B4        ,color.DarkOrchid           := 0x9932CC             
        ,color.DodgerBlue           := 0x1E90FF        ,color.Fuchsia              := 0xFF00FF             
        ,color.DeepSkyBlue          := 0x00BFFF        ,color.Magenta              := 0xFF00FF             
        ,color.CornflowerBlue       := 0x6495ED        ,color.SlateBlue            := 0x6A5ACD             
        ,color.SkyBlue              := 0x87CEEB        ,color.MediumSlateBlue      := 0x7B68EE             
        ,color.LightSkyBlue         := 0x87CEFA        ,color.MediumOrchid         := 0xBA55D3             
        ,color.LightSteelBlue       := 0xB0C4DE        ,color.MediumPurple         := 0x9370DB             
        ,color.LightBlue            := 0xADD8E6        ,color.Orchid               := 0xDA70D6             
        ,color.PowderBlue           := 0xB0E0E6        ,color.Violet               := 0xEE82EE             
                                                       ,color.Plum                 := 0xDDA0DD            
                                                       ,color.Thistle              := 0xD8BFD8            
                                                       ,color.Lavender             := 0xE6E6FA            
                                                                                                                           
        ; Green                                        ; Cyan                                                       
         color.DarkGreen            := 0x006400        ,color.Teal                 := 0x008080             
        ,color.Green                := 0x008000        ,color.DarkCyan             := 0x008B8B             
        ,color.DarkOliveGreen       := 0x556B2F        ,color.LightSeaGreen        := 0x20B2AA             
        ,color.ForestGreen          := 0x228B22        ,color.CadetBlue            := 0x5F9EA0             
        ,color.SeaGreen             := 0x2E8B57        ,color.DarkTurquoise        := 0x00CED1             
        ,color.Olive                := 0x808000        ,color.MediumTurquoise      := 0x48D1CC             
        ,color.OliveDrab            := 0x6B8E23        ,color.Turquoise            := 0x40E0D0             
        ,color.MediumSeaGreen       := 0x3CB371        ,color.Aqua                 := 0x00FFFF             
        ,color.LimeGreen            := 0x32CD32        ,color.Cyan                 := 0x00FFFF             
        ,color.Lime                 := 0x00FF00        ,color.Aquamarine           := 0x7FFFD4             
        ,color.SpringGreen          := 0x00FF7F        ,color.PaleTurquoise        := 0xAFEEEE             
        ,color.MediumSpringGreen    := 0x00FA9A        ,color.LightCyan            := 0xE0FFFF             
        ,color.DarkSeaGreen         := 0x8FBC8F                                                                     
        ,color.MediumAquamarine     := 0x66CDAA        ; Orange                                                     
        ,color.YellowGreen          := 0x9ACD32        ,color.OrangeRed            := 0xFF4500             
        ,color.LawnGreen            := 0x7CFC00        ,color.Tomato               := 0xFF6347             
        ,color.Chartreuse           := 0x7FFF00        ,color.DarkOrange           := 0xFF8C00             
        ,color.LightGreen           := 0x90EE90        ,color.Coral                := 0xFF7F50             
        ,color.GreenYellow          := 0xADFF2F        ,color.Orange               := 0xFFA500             
        ,color.PaleGreen            := 0x98FB98        
                                                                                                                           
        ; Brown                                                 ; Yellow                                                   
         color.Maroon               := 0x800000        ,color.DarkKhaki            := 0xBDB76B            
        ,color.Brown                := 0xA52A2A        ,color.Gold                 := 0xFFD700            
        ,color.SaddleBrown          := 0x8B4513        ,color.Khaki                := 0xF0E68C            
        ,color.Sienna               := 0xA0522D        ,color.PeachPuff            := 0xFFDAB9            
        ,color.Chocolate            := 0xD2691E        ,color.Yellow               := 0xFFFF00            
        ,color.DarkGoldenrod        := 0xB8860B        ,color.PaleGoldenrod        := 0xEEE8AA            
        ,color.Peru                 := 0xCD853F        ,color.Moccasin             := 0xFFE4B5            
        ,color.RosyBrown            := 0xBC8F8F        ,color.PapayaWhip           := 0xFFEFD5            
        ,color.Goldenrod            := 0xDAA520        ,color.LightGoldenrodYellow := 0xFAFAD2            
        ,color.SandyBrown           := 0xF4A460        ,color.LemonChiffon         := 0xFFFACD            
        ,color.Tan                  := 0xD2B48C        ,color.LightYellow          := 0xFFFFE0            
        ,color.Burlywood            := 0xDEB887                                                                     
        ,color.Wheat                := 0xF5DEB3                                                                     
        ,color.NavajoWhite          := 0xFFDEAD                                                                     
        ,color.Bisque               := 0xFFE4C4                                                                     
        ,color.BlanchedAlmond       := 0xFFEBCD                                                                     
        ,color.Cornsilk             := 0xFFF8DC                                                                     
        
        this.colorhex := Color
        
        Return
    }
    
    ;===================================================================================================================.
    ; A Point object contains 2 integer properties representing x and y values. The object also stores a struct.        |
    ; Properties:                                                                                                       |
    ; .x                X coord (integer)                                                                               |
    ; .y                Y coord (integer)                                                                               |
    ; .structP          Pointer to Point struct (x > y)                                                                 |
    ;                                                                                                                   |
    ; Constructors:                                                                                                     |
    ; Point()           Create a Point object with x and y values of 0                                                  |
    ; Point(int1, int2) Create a Point object with int x and int y values                                               |
    ; Point(Size)       Create a Point object with x equal to size.width and y equal to size.height                     |
    ; Point(Point)      Create a clone of the provided Point struct                                                     |
    ;                                                                                                                   |
    ; Methods:                                                                                                          |
    ; .equals(Point)    Determine if native and provided Point objects have equal values then returns true or false     |
    ; .plus(Point)      Adds the x and y values of the native and provided Point objects then returns new Point object  |
    ; .minus(Point)     Subtracts the x and y Point values from the native Point object then returns a new Point object |
    ;                                                                                                                   |
    ; Remarks           If working with float/decimal numbers, use PointF.                                              |
    ;                   There is no way to use the + and - operators with Points. Use the plus() or minus() methods.    |
    ;___________________________________________________________________________________________________________________|
    Class Point extends GDIP
    {
        type    := "Point"
        x       := ""
        y       := ""
        struct  := ""
        structP := ""
        
        ; ## CONSTRUCTOR ##
        
        __New(obj_x="", y="")
        {
            err := 0
            (this.is_int(obj_x) && this.is_int(y))      ? (this.x := obj_x      , this.y := y)
                : (obj_x = "" && y = "")                ? (this.x := 0          , this.y := 0)
                : (obj_x.type = "Point") && (y = "")    ? (this.x := obj_x.x    , this.y := obj_x.y)
                : (obj_x.type = "Size") && (y = "")     ? (this.x := obj_x.width, this.y := obj_x.height)
                :                                         err := 1
            
            (err) ? this.error_log(A_ThisFunc, "Failed to create Point struct." ; If error, log it
                        , "No params, 2 ints, 1 size object, or 1 Point object"
                        , {obj_x:obj_x, y:y})
                : (this.SetCapacity("struct", 8)                                ; Else build Point
                    , ptr := this.GetAddress("struct")
                    , NumPut(this.x, ptr+0, 0, "Int")
                    , NumPut(this.y, ptr+0, 4, "Int")
                    , this.structP := ptr )
        }
        
        ; For testing purposes
        show()
        {
            MsgBox, % ".x: "        this.x
                . "`n.y: "          this.y
                . "`n.structP: "    this.structP
                . "`nStructP x: "   NumGet(this.structP+0, 0, "Int")
                . "`nStructP y: "   NumGet(this.structP+0, 4, "Int")
            Return
        }
        
        ; ## METHODS ##
        
        ; Description   Determine if native and provided Point objects have equal values
        ; Point         Point object to do equality check against native Point object
        ; Return        1 = True, 0 = False
        equals(Point)
        {
            (Point.type == "Point") ? ""
                : this.error_log(A_ThisFunc, "This method requires a Point object be passed in as a parameter."
                    , "Must supply a Point object.", {providedObject: Point})
            Return (this.x = Point.x) && (this.y = Point.y) ? 1 : 0
        }
        
        ; Description   Adds the x and y values of the native and provided Point objects
        ; Point         Point object to add to the native Point object
        ; Return        New Point object containing the added x and y values
        ; Remark        The x values and y values are added together, not x+y
        plus(Point)
        {
            (Point.type == "Point") ? ""
                : this.error_log(A_ThisFunc, "This method requires a Point object be passed in as a parameter."
                    , "Must supply a Point object.", {providedObject: Point})
            Return new GDIP.Point(this.x + Point.x, this.y + Point.y)
        }
        
        ; Description   Subtracts the x and y Point values from the native Point object
        ; Point         Point object to subtract from the native Point object
        ; Return        A new Point object containing the difference of the x and y values
        ; Remark        The x values and y values are subtracted, not x-y
        ;               The provided Point values are always subtracted from the native Point values
        minus(Point)
        {
            (Point.type == "Point") ? ""
                : this.error_log(A_ThisFunc, "This method requires a Point object be passed in as a parameter."
                    , "Must supply a Point object.", {providedObject: Point})
            Return new GDIP.Point(this.x - Point.x, this.y - Point.y)
        }
    }
    
    ;===================================================================================================================.
    ; A Size object contains 2 integer properties representing width and height. The object also stores a struct.       |
    ; Properties:                                                                                                       |
    ; .width            width (integer)                                                                                 |
    ; .height           height (integer)                                                                                |
    ; .structP          Pointer to Size struct (width > height)                                                         |
    ;                                                                                                                   |
    ; Constructors:                                                                                                     |
    ; Size()            Create a Size object with width and height values of 0                                          |
    ; Size(int1, int2)  Create a Size object with int width and int height                                              |
    ; Size(Size)        Create a clone of the provided Size object                                                      |
    ;                                                                                                                   |
    ; Methods:                                                                                                          |
    ; .empty()          Determine if native Size object width and height are both set to 0 then returns true or false   |
    ; .equals(Size)     Determine if native and provided Size objects have equal values then returns true or false      |
    ; .plus(Size)       Add width and height values of native and provided Size objects then return new Size object     |
    ; .minus(Size)      Subtract width and height values of provided and native Size objects then return new Size object|
    ;                                                                                                                   |
    ; Remarks           If working with float/decimal numbers, use SizeF.                                               |
    ;                   There is no way to use the + and - operators with Sizes. Use the plus() or minus() methods.     |
    ;___________________________________________________________________________________________________________________|
    Class Size extends GDIP
    {
        type    := "Size"
        width   := ""
        height  := ""
        struct  := ""
        structP := ""
        
        ; ## CONSTRUCTOR ##
        
        __New(obj_width="", height="")
        {
            err := 0
            (this.is_int(obj_width) && this.is_int(height))                     ; All int
                ? (this.width := obj_width , this.height := height)
                : (obj_width = "" && height = "")                               ; All blank
                ? (this.width := 0 , this.height := 0)
                : (obj_width.type = "Size") && (height = "")                    ; Size obj
                ? (this.width := obj_width.width, this.height := obj_width.height)
                : err := 1                                                      ; Error
            
            (err) ? this.error_log(A_ThisFunc, "Failed to create Size struct."  ; If error, log it
                        , "No params, 2 ints, 1 Size object, or 1 point object"
                        , {obj_width:obj_width, height:height})
                : (this.SetCapacity("struct", 8)                                ; Else build Size
                    , ptr := this.GetAddress("struct")
                    , NumPut(this.width , ptr+0, 0, "Int")
                    , NumPut(this.height, ptr+0, 4, "Int")
                    , this.structP := ptr )
        }
        
        ; For testing purposes
        show()
        {
            MsgBox, % ".width: "            this.width
                    . "`n.height: "         this.height
                    . "`n.structP: "        this.structP
                    . "`nStructP width: "   NumGet(this.structP+0, 0, "Int")
                    . "`nStructP height: "  NumGet(this.structP+0, 4, "Int")
            Return
        }
        
        ; ## METHODS ##
        
        ; Description   Determine if Size object width and height are set to 0
        ; Return        1 = True, 0 = False
        Empty()
        {
            Return (this.width = 0 && this.height = 0) ? 1 : 0
        }
        
        ; Description   Determine if native Size and provided Size have equal width/height values
        ; Size          Size object to do equality check against native Size object
        ; Return        1 = True, 0 = False
        Equals(Size)
        {
            (size.type == "Size") ? ""
                : this.error_log(A_ThisFunc, "This method requires a Size object be passed in as a parameter."
                    , "Must supply a Size object.", {providedObject: Size})
            Return (this.width = Size.width) && (this.height = Size.height) ? 1 : 0
        }
        
        ; Description   Add width and height values of native and provided Size objects
        ; Size          Size object to add to the native Size object
        ; Return        New Size object containing the added width and height values
        plus(Size)
        {
            (Size.type == "Size") ? ""
                : this.error_log(A_ThisFunc, "This method requires a Size object be passed in as a parameter."
                    , "Must supply a Size object.", {providedObject: Size})
            Return new GDIP.Size(this.width + Size.width, this.height + Size.height)
        }
        
        ; Description   Subtracts the x and y Size values from the native Size object
        ; Size          Size object to subtract from the native Size object
        ; Return        A new Size object containing the difference of the width and height values
        ; Remark        The provided Size values are always subtracted from the native Size values
        minus(Size)
        {
            (Size.type == "Size") ? ""
                : this.error_log(A_ThisFunc, "This method requires a Size object be passed in as a parameter."
                    , "Must supply a Size object.", {providedObject: Size})
            Return new GDIP.Size(this.width - Size.width, this.height - Size.height)
        }
    }
    
    ;===================================================================================================================.
    ; A Rect object contains 4 integer properties representing x, y, width, and height. The object also stores a struct.|
    ; Properties:                                                                                                       |
    ; .x                Rect leftmost x coordinate (integer)                                                            |
    ; .y                Rect topmost y coordinate (integer)                                                             |
    ; .width            Rect width (integer)                                                                            |
    ; .height           Rect height (integer)                                                                           |
    ; .left             Left x coord (synonymous with .x)                                                               |
    ; .right            Right x coord                                                                                   |
    ; .top              Top y coord (synonymous with .y)                                                                |
    ; .bottom           Bottom y coord                                                                                  |
    ; .structP          Pointer to Rect struct (x > y > width > height)                                                 |
    ;                                                                                                                   |
    ; Constructors:                                                                                                     |
    ; Rect()            Create a Rect object with width and height values of 0                                          |
    ; Rect(i1,i2,i3,i4) Create a Rect object with int width and int height                                              |
    ; Rect(Point, Size) Create a Rect object using a Point and Size object                                              |
    ;                                                                                                                   |
    ; Methods:                                                                                                          |
    ; .clone()                                                                                                          |
    ; .empty()          Determine if native Rect object width and height are both set to 0 then returns true or false   |
    ; .equals(Rect)     Determine if native and provided Rect objects have equal values then returns true or false      |
    ; .plus(Rect)       Add width and height values of native and provided Rect objects then return new Rect object     |
    ; .minus(Rect)      Subtract width and height values of provided and native Rect objects then return new Rect object|
    ;                                                                                                                   |
    ; Remarks           If working with float/decimal numbers, use RectF.                                               |
    ;                   There is no way to use the + and - operators with Rects. Use the plus() or minus() methods.     |
    ;___________________________________________________________________________________________________________________|
    Class Rect extends GDIP
    {
        type    := "Rect"
        x       := ""
        y       := ""
        width   := ""
        height  := ""
        bottom  := ""
        top     := ""
        struct  := ""
        structP := ""
        
        ; ##  Constructor ##
        __New(x_obj="", y_obj="", width="", height="")
        {
            err := 0
            (this.is_int(x_obj) && this.is_int(y_obj) && this.is_int(width) && this.is_int(height)) ; All int
                ? (this.left  := this.x := x_obj    ,this.top    := this.y := y_obj
                  ,this.width := width              ,this.height := height
                  ,this.right := x_obj + width      ,this.bottom := y_obj + height )
                : (x_obj = "" && y_obj = "" && width = "" && height = "")                           ; All blank
                ? (this.left  := this.x := 0        ,this.top    := this.y := 0
                  ,this.width := 0                  ,this.height := 0
                  ,this.right := 0                  ,this.bottom := 0 )
                : (x_obj.type == "Point" && y_obj.type == "Size" && width = "" && height = "")      ; Point + Size
                ? (this.left  := this.x := x_obj.x  ,this.top    := this.y := x_obj.y 
                  ,this.width := y_obj.width        ,this.height := y_obj.height
                  ,this.right := height             ,this.bottom := y_obj + height )
                : err := 1                                                                          ; Error
            
            (err) ? this.error_log(A_ThisFunc, "Failed to create Rect struct."                      ; If error, log it
                        , "No params, 4 ints, 1 size object and 1 point object"
                        , {x_obj:x_obj, y_obj:y_obj, width:width, height:height})
                :   (this.SetCapacity("struct", 16)                                                 ; Else build Rect
                    , ptr := this.GetAddress("struct")
                    , NumPut(this.x     , ptr+0,  0, "Int")
                    , NumPut(this.y     , ptr+0,  4, "Int")
                    , NumPut(this.width , ptr+0,  8, "Int")
                    , NumPut(this.height, ptr+0, 12, "Int")
                    , this.structP := ptr )
        }
        
        ; For testing purposes
        show()
        {
            MsgBox, % ".x: "            this.x
                . "`n.y: "              this.y
                . "`n.width: "          this.width
                . "`n.height: "         this.height
                . "`n.structP: "        this.structP
                . "`nStructP x: "       NumGet(this.structP+0,  0, "Int")
                . "`nStructP y: "       NumGet(this.structP+0,  4, "Int")
                . "`nStructP width: "   NumGet(this.structP+0,  8, "Int")
                . "`nStructP height: "  NumGet(this.structP+0, 12, "Int")
            Return
        }
        
        ; ## METHOD ##
        
        ; Description       Creates a duplicate copy of a Rect object
        Clone()
        {
            Return new gdip.rect(this.x, this.y, this.width, this.height)
        }
        
        ; This is an overloaded method:
        ; Contains(x, y)    Determine if integer points x,y falls within this Rect
        ; Contains(Point)   Determine if Point falls within this Rect
        ; Contains(Rect)    Determine if all of passed Rect falls inside native Rect
        ; Return            1 = True, 0 = False
        Contains(obj_x, y)
        {
            Return (this.is_int(obj_x) && this.is_int(y)                        ; x y integers
                    &&   obj_x >= this.x &&   obj_x <= (this.x + this.width)
                    &&       y <= this.y &&       y >= (this.y + this.height) ) ? 1
                :  (obj_x.type == "Point" && y = ""
                    && obj_x.x >= this.x && obj_x.x <= (this.x + this.width)
                    && obj_x.y <= this.y && obj_x.y >= (this.y + this.height) ) ? 1
                :  (obj_x.type == "Rect" && y = ""
                    && obj_x.x >= this.x && obj_x.y <= (this.x + this.width)
                    && (obj_x.x >= this.x) && (obj_x.y <= this.y)
                    && (obj_x.x + obj_x.width) <= (this.x + this.width) 
                    && (obj_x.y + obj_x.height) >= (this.y + this.height) ) ? 1
                : 0
        }
        
        ; Description       Determine if the supplied and native have equal x, y, width, and height values
        ; Rect              Rect struct to compare
        ; Return            1 = True, 0 = False
        Equals(Rect)
        {
            Return (Rect.x = this.x && Rect.width  = this.width
                &&  Rect.y = this.y && Rect.height = this.height) ? 1 : 0
        }
        
        ; Description       Retrieves coordinate for the bottom edge of this Rect
        GetBottom()
        {
            Return (this.y + this.height)
        }
        
        ; Description       Copy the current rect values to the provide Rect object
        GetBounds(ByRef Rect)
        {
            (Rect.type == "Rect")
                ? (Rect.x := this.x, Rect.y := this.y, Rect.width := this.width, Rect.height := this.height)
                : this.error_log(A_ThisFunc, "This functions requires a Rect object for the parameter."
                    , "Rect object", {providedRect:Rect})
        }
        
        ; Description       Retrieves coordinate for the left edge of this Rect
        ; Remark            Left is synonymous with x of a Rect
        GetLeft()
        {
            Return this.x
        }
        
        ; Description       Get x and y value from Rect and assign them to the provided Point object
        ; Return            No return value
        GetLocation(ByRef Point)
        {
            Point := new GDIP.Point(this.x, this.y)
        }
        
        ; Description       Retrieves coordinate for the right edge of this Rect
        GetRight()
        {
            Return (this.x + this.width)
        }
        
        ; Description       Get width and height value from Rect and assign them to the provided Size object
        ; Return            No return value
        GetSize(ByRef Size)
        {
            Size := new GDIP.Size(this.width, this.height)
        }
        
        ; Description       Retrieves coordinate for the top edge of this Rect
        ; Remark            Top is synonymous with y of a Rect
        GetTop()
        {
            Return this.y
        }
        
        ; This is an overloaded method:
        ; Inflate(dx, dy)   Expand left & right edges by int dx and top & bottom edges by int dy
        ; Inflate(Point)    Expand left & right edges by Point.x and the top & bottom edges by Point.y
        ; Inflate(Size)     Expand left & right edges by Size.width and the top & bottom edges by Size.height
        ; Return            No return value
        Inflate(dx_obj, dy="")
        {
            (this.is_int(dx_obj) && this.is_int(dy))
                ? (this.x -= dx_obj, this.y -= dy, this.width += (dx_obj*2), this.height += (dy*2) )
            : (dx_obj.type == "Point" && dy = "")
                ? (this.x -= dx_obj.x, this.y -= dx_obj.y, this.width += (dx_obj.x*2), this.height += (dx_obj.y*2) )
            : (dx_obj.type == "Size" && dy = "")
                ? (this.x -= dx_obj.width, this.y -= dx_obj.height 
                    ,this.width += (dx_obj.width*2), this.height += (dx_obj.height*2) )
            : this.error_log(A_ThisFunc, "This functions requires two integers, a Point object, :"
                . "or a Size object parameter.", "Point Object, Size Object, 2 Intgers", {dx_obj:dx_obj, dy:dy})
        }
        
        ; This is an overloaded method:
        ; Intersect(Rect)   Update current Rect values to represent the rectangle created by the intersection.
        ; Intersect(Rect1   Create new Rect using values of the rectangle created by Rect1 and Rect2 intersecting
        ;   ,Rect1,RectOut) 
        ; Description       
        ; Rect              Rect object to to intersect with
        ; Return            0 = No intersection, 1 = Intersect found
        ; Remark            If there is no intersection, all values are updated to 0
        Intersect(Rect1, Rect2="", ByRef RectOut="")
        {
            (Rect1.type == "Rect" && Rect2 = "" && RectOut = "")    ; Only Rect1
                ? this.IntersectsWith(Rect)
                    ? (this.left := this.x := (this.left   > Rect.left)   ? this.left   : Rect.left
                      ,this.top  := this.y := (this.top    > Rect.top)    ? this.top    : Rect.top
                      ,this.right          := (this.right  < Rect.right)  ? this.right  : Rect.right
                      ,this.bottom         := (this.bottom < Rect.bottom) ? this.bottom : Rect.bottom
                      ,this.width          := (this.right  - this.left)
                      ,this.height         := (this.bottom - this.top)
                      ,status              := 1 )
                :     (this.left := this.x := 0 ,this.top  := this.y := 0
                      ,this.right          := 0 ,this.bottom         := 0
                      ,this.width          := 0 ,this.height         := 0
                      ,status              := 0 )
            : (Rect1.type == "Rect" && Rect2.type == "Rect")        ; Rect1, Rect2, and RectOut
                ? this.IntersectsWith(Rect)
                    ? (this.left := this.x := (this.left   > Rect.left)   ? this.left   : Rect.left
                      ,this.top  := this.y := (this.top    > Rect.top)    ? this.top    : Rect.top
                      ,this.right          := (this.right  < Rect.right)  ? this.right  : Rect.right
                      ,this.bottom         := (this.bottom < Rect.bottom) ? this.bottom : Rect.bottom
                      ,this.width          := (this.right  - this.left)
                      ,this.height         := (this.bottom - this.top)
                      ,status              := 1 )
                :     (this.left := this.x := 0 ,this.top  := this.y := 0
                      ,this.right          := 0 ,this.bottom         := 0
                      ,this.width          := 0 ,this.height         := 0
                      ,status              := 0 )
            :  status                      := 1                         ; Failed parameter check
            
            Return status
        }
        
        ; Description       Creates a new
        Intersect(ByRef RectOut, Rect1, Rect2)
        {
            status := 1
            RectOut := new GDIP.Rect()
            
            Rect1.IntersectsWith(Rect2)
                ? 
                : (RectOut.left     := RectOut.x := 0
                  ,RectOut.top      := RectOut.y := 0
                  ,RectOut.right    := 0
                  ,RectOut.bottom   := 0
                  ,RectOut.width    := 0
                  ,RectOut.height   := 0
                  ,status := 0 )
            
            RectOut.x       := (Rect1.x > Rect2.x) ? Rect1.x : Rect2.x
            ,RectOut.y      := (Rect1.y > Rect2.y) ? Rect1.y : Rect2.y
            ,RectOut.width  := 0
            ,RectOut.height := 0
            Return status
        }
        
        ; Description       Determine if provided Rect and native Rect intersect
        ; Return            1 = True, 0 = False
        IntersectsWith(Rect)
        {
            Return ((this.right < Rect.left) || (this.left > Rect.right)
                &&  (this.top > Rect.bottom) || (this.bottom < Rect.top) ) ? 1 : 0
        }
        
        ; IsEmptyArea method determines whether this rectangle is empty.
        IsEmptyArea()
        {
            Return
        }
        
        ; Offset method moves the rectangle by dx horizontally and by dy vertically.
        Offset(dx, dy)
        {
            Return
        }
        
        ; Offset method moves this rectangle horizontally a distance of point.X and vertically a distance of point.Y.
        Offset(Point)
        {
            Return
        }
        
        ; Union method determines the union of two rectangles and stores the result in a Rect object.
        Union()
        {
            Return
        }
        
    }
    
    ; ##################
    ; ##  Validators  ##
    ; ##################
    is_int(num)
    {
        Return (Mod(number, 1) = 0) ? 1 : 0
    }
    
    is_float(num)
    {
        Return (Mod(number, 1) = 0) ? 0 : 1
    }
    
    is_num(num)
    {
        Return (0*num = 0) ? 1 : 0
    }
    
    ; ########################################
    ; ##  Testing and Troubleshooting Code  ##
    ; ########################################
    Class test
    {
        show_img(image_p)
        {
            hwnd := this.gui.new_layered_window(A_ScreenWidth, A_ScreenHeight)
            
        }
    }
    
}

Class gui
{
    ;___________________________________________________________________________________________________________________|
    ; Call              new_layered_window(OnTop:=1,TitleBar:=0,TaskBar:=0)                                             |
    ; Description       Cleans up resources used by Windows GDI+ and clears GDIP token.                                 |
    ;                                                                                                                   |
    ; OnTop             Set window to always on top                                                                     |
    ;                                                                                                                   |
    ; Return            Handle to gui                                                                                   |
    ;___________________________________________________________________________________________________________________|
    new_layered_window(width, height, OnTop=1, TitleBar=0, TaskBar=0)
    {
        Gui, New, % "+E0x80000 "                        ; Create a new layered window
            . (TitleBar ? " -Caption"     : "")         ; Remove title bar and thick window border/edge
            . (OnTop    ? " +AlwaysOnTop" : "")         ; Force GUI to always be on top
            . (TaskBar  ? " +ToolWindow"  : "")         ; Removes the taskbar button
            . "+HWNDguiHwnd "                           ; Saves the handle of the GUI to guiHwnd
        Gui, Show, NA                                   ; Make window visible but transparent
        Return guiHwnd
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
    


/* Test file
#SingleInstance, Force
#Warn
#NoEnv
SetBatchLines, -1
if !A_IsAdmin || !(DllCall("GetCommandLine","Str")~=" /restart(?!\S)")
    Try Run % "*RunAs """ (A_IsCompiled?A_ScriptFullPath """ /restart":A_AhkPath """ /restart """ A_ScriptFullPath """")
    Finally ExitApp

test()
ExitApp

*Esc::ExitApp

test()
{
    p1  := new gdip.point()
    p2  := new gdip.point(10, 20)
    p3  := new gdip.point(p2)
    show(p1)
    show(p2)
    show(p3)
    Return
}

show(point)
{
    MsgBox, % "point.structP: " point.structP 
    MsgBox, % "point.width: "   point.width
        . "`npoint.height: "    point.height 
        . "`nStruct width: "    NumGet(point.struct,    0, "Int")
        . "`nStruct height: "   NumGet(point.struct,    0, "Int")
        . "`nStructP width: "   NumGet(point.structP+0, 0, "Int")
        . "`nStructP height: "  NumGet(point.structP+0, 0, "Int")
    Return
}

Class GDIP
{
    ;===================================================================================================================.
    ; A point objects/structures contain 2 integers representing x and y coordinates.                                   |
    ; Properties:                                                                                                       |
    ; .x                X coord (integer)                                                                               |
    ; .y                Y coord (integer)                                                                               |
    ; .struct           Actual 8 byte struct                                                                            |
    ; .structP          Pointer to Point struct                                                                         |
    ;                                                                                                                   |
    ; Methods:                                                                                                          |
    ; equals(point2)    Determines if 2 Points have equal values. Returns true/false                                    |
    ; sum(point2)       Adds Point2 to the current Point. Returns a new Point object.                                   |
    ; diff(point2)      Subtracts Point2 from the current Point. Returns a new Point object.                            |
    ;___________________________________________________________________________________________________________________|
    Class point extends GDIP
    {
        type    := "Point"
        x       := 0
        y       := 0
        struct  := 0
        structP := 0
        
        ; The new creation method is overloaded, giving multiple ways to create a point object
        ; Point()           Creates a point struct containing all zeroes
        ; Point(x, y)       Creates a point using an int for x and one for y
        ; Point(Size)       Creates a point using the 2 values stored in a size struct
        ; Point(Point)      Clones a point struct
        __New(obj_x="", y="")0
        {
            err := 0
            (this.is_int(obj_x) && this.is_int(y))  ? (this.width := obj_x, this.height := y)
                : (obj_x = "" && y = "")            ? (this.width := 0, this.height := 0)
                : (obj_x.type = "Size")             ? (this.width := obj_x.x, this.height := obj_x.y)
                : (obj_x.type = "Point")            ? (this.width := obj_x.w, this.height := obj_x.h)
                :                                     err := 1
            
            If (err)
                this.error_log(A_ThisFunc, "Failed to create point struct.", "Expected", {obj_x:obj_x, y:y})
            Else 
            {
                MsgBox, % "this.structP: " this.structP 
                this.SetCapacity("struct", 8)           ; Set struct to 8 bytes
                MsgBox, % "Capacity: " this.GetCapacity("struct")
                ptr := this.GetAddress("struct")        ; Get struct pointer
                NumPut(this.width,  ptr+0, 0, "Int")    ; Set first 4 bytes to width
                NumPut(this.height, ptr+0, 4, "Int")    ; Set last 4 bytes to height
                this.structP := ptr                     ; Save pointer
                MsgBox, % "this.structP: " this.structP "`nptr: " ptr
            }
        }
        
        ;~ ; METHODS
        ;~ ; Description       Determines whether two PointF objects are equal
        ;~ Equals(point1, point2)
        ;~ {
            ;~ Return (NumGet(point1, 0, "Int64") = NumGet(point1, 0, "Int64")) ? 1 : 0
        ;~ }
        
        ;~ ; The PointF::operator+ method adds the X and Y data members of two PointF objects.
        ;~ sum(point1, point2)
        ;~ {
            ;~ sx := NumGet(point1, 0, "Int") + NumGet(point2, 0, "Int")
            ;~ sy := NumGet(point1, 4, "Int") + NumGet(point2, 4, "Int")
            ;~ Return this.Point(sy, sx)
        ;~ }
        
        ;~ ; The PointF::operator- method subtracts the X and Y data members of two PointF objects.
        ;~ diff(point1, point2)
        ;~ {
            ;~ Return
        ;~ }
        
    }
    
    Class size extends GDIP
    {
        method()
        {
            Return
        }
    }
    
    is_int(num)
    {
        Return (Mod(num, 1) = 0) ? 1 : 0
    }
    
    is_float(num)
    {
        Return (Mod(num, 1) = 0) ? 0 : 1
    }
    
    is_num(num)
    {
        Return (0*num = 0) ? 1 : 0
    }
}








class testingclass
{
}

Rounding_Mindfuck()
{
    percent := 50
    x := 255 * percent / 100
    y := 255 / 100 * percent
    MsgBox, % "Percent = " percent
            . "`nvar`tRounded`tFormula"
            . "`nx`t" Round(x) "`t255 * percent / 100"
            . "`ny`t" Round(y) "`t255 / 100 * percent"
            
    ;MsgBox, % "x: " x "`nRounded`nx: " Round(x) "`ny: " y "`ny: "Round(y)
    Return
}

to_hex(num){
    Return Format("{1:#x}", num)
}

; qpx(1) starts it and qpx() stops timer and returns time
qpx(N=0) {  ; Wrapper for QueryPerformanceCounter() by SKAN  | CD: 06/Dec/2009
    Local   ; www.autohotkey.com/forum/viewtopic.php?t=52083 | LM: 10/Dec/2009
    Static F:="", A:="", Q:="", P:="", X:=""
    If (N && !P)
        Return DllCall("QueryPerformanceFrequency",Int64P,F) + (X:=A:=0)
             + DllCall("QueryPerformanceCounter",Int64P,P)
    DllCall("QueryPerformanceCounter",Int64P,Q), A:=A+Q-P, P:=Q, X:=X+1
    Return (N && X=N) ? (X:=X-1)<<64 : (N=0 && (R:=A/X/F)) ? (R + (A:=P:=X:=0)) : 1
}
