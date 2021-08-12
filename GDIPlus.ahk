/*
    Log:
    20210729
        Startup and shutdown are working
        Added image class
        Image.FromFile() works
    20210730
        Image.GetType() works
        Added NativeImage to image class to store the current image
            NativeImage is used by many methods to interact with the "Native Image"
            IMOP = IMO Pointer
            Other classes operate like this, such as the graphics class
    20210731
        Created Rect, Point, and Size classes
            Added overloaded constructors
        Created gui class
        Added new_layered_window() to gui class to create fast guis
            Returns an HWND to that gui
        Created test class for testing all the things!
    20210801
        Spent almost all day learning about structs and storing them to class vars
            Apparently objects have their own built-in variable sizers and address getters.
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
        I slept most of the day. Been staying up too late!
    20210804
        Cleaned up the Size, Point, and Rect code
        Studied up on some stuff
    20210805
        Finished up last few methods in Rect class.
        Corrected some errors.
        Began writing test files
        Rect Test file is almost complete.
    20210806
        Started working on PointF, SizeF, and RectF
    20210807
        Finished all the float variants of Point, Size, and Rect
        Still need to test all 6 classes
    20210808
        Updated the Gui class and the layered window method
        Started working with the Graphics class
    20210809
        Finished Enumerations
    20210810
        Started working on graphics class and image class
    20210811
        Lots of reading the .h file of GDIPlus
    20210812
        Redid the Rect/RectF classes after finding an error.
            Improved Rect/RectF Code
*/

GDIP.Startup()

Class GDIP
{
    Static  gdip_token  := ""
            ,_version   := 1.0
    
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
    }
    
    ExitGDIP()
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
        ; A_PtrSize = size of pointer (bytes) depending on script bit type.
        this.Ptr        := (A_PtrSize = 4) ? "UPtr"     ; Set pointer type. 32-bit uses UPtrs
                        :  (A_PtrSize = 8) ? "Ptr"      ; There is no UPtr for 64-bit, only Ptr
                        :                    "UInt"     ; Default to UInt
        this.PtrA       := this.Ptr . "*"               ; Set pointer address type
        OnExit(this._method("ExitGDIP"))                ; Ensure shutdown runs at script exit
        
        ; Start up GDIPlus
        If (this.gdip_token = "")
            DllCall("GetModuleHandle", "str", "gdiplus")    ; Check if GDIPlus is loaded
                ? "" : DllCall("LoadLibrary", "str", "gdiplus")
            ,VarSetCapacity(token, A_PtrSize)
            ,VarSetCapacity(gdip_si, (A_PtrSize = 8) ? 24 : 16, 0)
            ,NumPut(1, gdip_si)
            ,estat := DllCall("gdiplus\GdiplusStartup"
                            , this.PtrA , token         ; Pointer to GDIP token
                            , this.Ptr  , &gdip_si      ; Startup Input
                            , this.Ptr  , 0)            ; Startup Output 0 = null
            ,this.gdip_token := token
        
        (estat > 0)                                     ; Error checking
            ? this.error_log(A_ThisFunc, "Startup has failed.", "Estat Error: " estat , {estat:estat, })
            : ""
        
        GDIP.TypeDef._Create()                          ; Create typedefs
        GDIP.DEFINE._Create()                           ; Create defined values
        GDIP.generate_colorName()                       ; Generate color object
        ;add other generators here
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
    }
    
    ;####################################################################################################################
    ;  Custom AHK Class Methods                                                                                            |
    ;####################################################################################################################
    ; Quick boundfuncs
    _method(method_name, params := "")
    {
        bf := ObjBindMethod(this, method_name, params*)
        Return bf
    }
    
    ; Error log expects the call where the error happened
    ; The type of value or what was expected
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
    
    ;####################################################################################################################
    ;  TYPEDEF CLASS                                                                                                    |
    ;####################################################################################################################
    ; Responsible for tracking all the different var types there are in GDIPlus
    Class TypeDef
    {
        _Create()
        {
            this.GraphicsState     := "UInt"
            this.GraphicsContainer := "UInt"
            this.REAL              := "Float"
            
            Return
        }
    }
    
    ;####################################################################################################################
    ;  DEFINED CLASS                                                                                                    |
    ;####################################################################################################################
    ; Responsible for tracking all the different var types there are in GDIPlus
    Class DEFINE
    {
        _Create()
        {
            this.GDIP_EMFPLUS_RECORD_BASE   := 0x4000
            this.GDIP_WMF_RECORD_BASE       := 0x10000
            Return
        }
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
        Static  NativeImage := ""
        
        ; ## CONSTRUCTORS ##
        
        ; ## DESTRUCTOR ##
        __Delete()
        {
            DllCall("GdipDisposeImage"
                   ,this.Ptr    , this.nativeImage)
        }
        
        ; ## METHODS ##
        ; Description       Creates a new Image object that is a duplicate of the native Image object.
        Clone(image_p="")
        {
            (image_p = "") ? image_p := this.NativeImage : ""
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
            VarSetCapacity(imoP, A_PtrSize)
            estat := DllCall("gdiplus\GdipLoadImageFromFile" . (icm ? "ICM" : "")
                            ,this.Ptr     , &filename
                            ,this.PtrA    , imoP)
            (estat)
                ? this.error_log(A_ThisFunc, "Error opening an image from file.", "Valid filename" 
                    , {filename:filename, status_enum:estat, img_obj_ptr:imoP}) : ""
            Return imoP
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
        nativeGraphics := ""
        lastResult     := ""
        
        ; ## CONSTRUCTORS ##
        ; FromHDC(HDC)          Creates a Graphics object from a device context handle
        ; FromHDC(HDC,HANDLE)   Creates a Graphics object from a device context handle and a specified device
        ; FromImage(Image)      Creates a Graphics object associated with an Image object
        ; FromHWND(HWND,BOOL)	Creates a Graphics object associated with a window
        FromImage(image)
        {
            VarSetCapacity(gp, A_PtrSize, 0)
            (image)
                ? this.lastResult = DllCall("gdiplus\GdipGetImageGraphicsContext"
                                           , this.Ptr  , (this.image.nativeImage := image)
                                           , this.PtrA , &gp)
                : this.error_log(A_ThisFunc, "A pointer to an image object was required"
                                ,"", {image_pointer:image})
            this.nativeGraphics := gp
        }
        
        FromHDC(HDC, device="")
        {
            VarSetCapacity(gp, A_PtrSize, 0)
            (device = "")
                ? this.lastResult = DllCall("gdiplus\GdipCreateFromHDC"
                                           , this.Ptr    , HDC
                                           , this.PtrA   , &gp)
                : this.lastResult = DllCall("gdiplus\GdipCreateFromHDC2"
                                           , this.Ptr    , HDC
                                           , this.Ptr    , device
                                           , this.PtrA   , &gp)
            this.nativeGraphics := gp
        }
        
        FromHWND(HWND, ICM=0)
        {
            VarSetCapacity(gp, A_PtrSize, 0)
            this.lastResult := DllCall("gdiplus\GdipCreateFromHWND" . (ICM ? "ICM" : "")
                                       ,this.Ptr     , HWND
                                       ,this.PtrA    , &gp)
            this.native_graphics := gp
            Return gp
        }
        
        ; Description       Record any non-OK status and return status
        SetStatus(status)
        {
            Return (status = "Ok")
                ? status
                : (this.lastResult = status)
        }
        
        ; ## DESTRUCTOR ##
        __Delete()
        {
            DllCall("GdipDeleteGraphics", this.Ptr, this.nativeGraphics)
        }
        
        ; ## METHODS ##
        
        ; Flush
        Flush(intention=0)
        {
            DllCall("gdiplus\GdipFlush"
                   , this.Ptr   , this.nativeGraphics
                   , "Uint"     , intention)
        }
        
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
        
        
        DrawImage()
        {
            
            Return
        }
        
        ; Description       Draws a line that connects two points.
        
        ;~ DrawLine()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        
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
        
        ;~ ; The Graphics::FromHDC method creates a Graphics object that is associated with a specified device context.
        ;~ FromHDC()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ ; The Graphics::FromHDC method creates a Graphics object that is associated with a specified device context and a specified device.
        ;~ FromHDC()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ ; The Graphics::FromHWND method creates a Graphicsobject that is associated with a specified window.
        ;~ FromHWND()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        ;~ ; The Graphics::FromImage method creates a Graphicsobject that is associated with a specified Image object.
        ;~ FromImage()
        ;~ {
            ;~ DllCall(""
                   ;~ , type      , value)
        ;~ }
        
        
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
        
        GetHDC()
        {
            VarSetCapacity(HDC, A_PtrSize, 0)
            last SetStatus(DllExports::GdipGetDC(nativeGraphics, &hdc));
            DllCall(""
                   , type      , value)
            return HDC
        }
        
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
        ; Indicates one of five brush types
        Static BrushType := {"BrushTypeSolidColor"     : 0   ; Paints a single, constant color that can be opaque or transparent.
                            ,"BrushTypeHatchFill"      : 1   ; Paints a background and paints, over that background, a pattern of lines, dots, dashes, squares, crosshatch, or some variation of these.
                            ,"BrushTypeTextureFill"    : 2   ; Paints an image.
                            ,"BrushTypePathGradient"   : 3   ; Paints a color gradient in which the color changes from a center point outward to a boundary that is defined by a closed curve or path.
                            ,"BrushTypeLinearGradient" : 4 } ; Paints a color gradient in which the color changes evenly from the starting boundary line of the linear gradient brush to the ending boundary line of the linear gradient brush.
        
        ; Specifies which GDI+ objects use color-adjustment information.
        Static ColorAdjustType := {"ColorAdjustTypeDefault" : 0   ; Applies to all categories that do not have adjustment settings of their own.
                                  ,"ColorAdjustTypeBitmap"  : 1   ; Applies to bitmapped images.
                                  ,"ColorAdjustTypeBrush"   : 2   ; Applies to brush operations in metafiles.
                                  ,"ColorAdjustTypePen"     : 3   ; Applies to pen operations in metafiles.
                                  ,"ColorAdjustTypeText"    : 4   ; Applies to text drawn in metafiles.
                                  ,"ColorAdjustTypeCount"   : 5   ; Used internally to record the number of color adjustment types.
                                  ,"ColorAdjustTypeAny"     : 6 } ; Reserved
        
        ; Specifies individual channels in the CMYK (cyan, magenta, yellow, black) color space.
        Static ColorChannelFlags := {"ColorChannelFlagsC"    : 0   ; Cyan
                                    ,"ColorChannelFlagsM"    : 1   ; Magenta
                                    ,"ColorChannelFlagsY"    : 2   ; Yellow
                                    ,"ColorChannelFlagsK"    : 3   ; Black
                                    ,"ColorChannelFlagsLast" : 4 } ; Undefined
        
        ; Specifies the types of images and colors that will be affected by the color and grayscale adjustment settings of an ImageAttributes object.
        Static ColorMatrixFlags := {"ColorMatrixFlagsDefault"   : 0   ; All color values (including grays) are adjusted by the same color-adjustment matrix.
                                   ,"ColorMatrixFlagsSkipGrays" : 1   ; Colors are adjusted but gray shades are not adjusted.
                                   ,"ColorMatrixFlagsAltGray"   : 2 } ; Colors are adjusted by one matrix and gray shades are adjusted by another matrix.
        
        ; Specifies how a new region is combined with an existing region.
        Static CombineMode := {"CombineModeReplace"    : 0   ; Replaced by the new region.
                              ,"CombineModeIntersect"  : 1   ; Replaced by the intersection of itself and the new region.
                              ,"CombineModeUnion"      : 2   ; Replaced by the union of itself and the new region.
                              ,"CombineModeXor"        : 3   ; Replaced by the result of performing an XOR on the two regions.
                              ,"CombineModeExclude"    : 4   ; Replaced by the portion of itself that is outside of the new region.
                              ,"CombineModeComplement" : 5 } ; Replaced by the portion of the new region that is outside of the existing region.
        
        ; Specifies how rendered colors are combined with background colors.
        Static CompositingMode := {"CompositingModeSourceOver" : 0   ; when a color is rendered, it is blended with the background color.
                                  ,"CompositingModeSourceCopy" : 1 } ; when a color is rendered, it overwrites the background color.
        
        ; Specifies whether gamma correction is applied when colors are blended with background colors.
        Static CompositingQuality := {"CompositingQualityInvalid"        : -1  ; Invalid
                                     ,"CompositingQualityDefault"        : 0   ; Gamma correction is not applied.
                                     ,"CompositingQualityHighSpeed"      : 1   ; Gamma correction is not applied.
                                     ,"CompositingQualityHighQuality"    : 2   ; Gamma correction is applied.
                                     ,"CompositingQualityGammaCorrected" : 3   ; Gamma correction is applied.
                                     ,"CompositingQualityAssumeLinear"   : 4 } ; Gamma correction is not applied.
        
        ; Specifies coordinate spaces.
        Static CoordinateSpace := {"CoordinateSpaceWorld"  : 0   ; Specify world space
                                  ,"CoordinateSpacePage"   : 1   ; Specify page space
                                  ,"CoordinateSpaceDevice" : 2 } ; Specify device space
        
        ; Encompasses the eight bitmap adjustments listed in the CurveAdjustments enumeration.
        Static CurveAdjustments := {"AdjustExposure"        : 0   ; Simulates increasing or decreasing the exposure of a photograph.
                                   ,"AdjustDensity"         : 1   ; Simulates increasing or decreasing the film density of a photograph.
                                   ,"AdjustContrast"        : 2   ; Increases or decreases the contrast of a bitmap.
                                   ,"AdjustHighlight"       : 3   ; Increases or decreases the value of a color channel if that channel already has a value that is above half intensity. 
                                   ,"AdjustShadow"          : 4   ; Increases or decreases the value of a color channel if that channel already has a value that is below half intensity.
                                   ,"AdjustMidtone"         : 5   ; Lightens or darkens an image.
                                   ,"AdjustWhiteSaturation" : 6   ; Set the adjustment member of a ColorCurveParams object.
                                   ,"AdjustBlackSaturation" : 7 } ; Set the adjustment member of a ColorCurveParams object.
        
        ; Specifies which color channels are affected by a ColorCurve bitmap adjustment.
        Static CurveChannel := {"CurveChannelAll"   : 0   ; Specifies that the color adjustment applies to all channels.
                               ,"CurveChannelRed"   : 1   ; Specifies that the color adjustment applies only to the red channel.
                               ,"CurveChannelGreen" : 2   ; Specifies that the color adjustment applies only to the green channel.
                               ,"CurveChannelBlue"  : 3 } ; Specifies that the color adjustment applies only to the blue channel.
        
        ; 
        Static CustomLineCapType := {"CustomLineCapTypeDefault"         : 0   ; 
                                    ,"CustomLineCapTypeAdjustableArrow" : 1 } ;
        };
        
        
        ; Specifies the type of graphic shape to use on both ends of each dash in a dashed line.
        Static DashCap := {"DashCapFlat"     : 0   ; Square cap that squares off both ends of each dash.
                          ,"DashCapRound"    : 2   ; Circular cap that rounds off both ends of each dash.
                          ,"DashCapTriangle" : 3 } ; Triangular cap that points both ends of each dash.
        
        ; Specifies the line style of a line drawn with a Windows GDI+ pen.
        Static DashStyle := {"DashStyleSolid"      : 0   ; Solid line.
                            ,"DashStyleDash"       : 1   ; Dashed line.
                            ,"DashStyleDot"        : 2   ; Dotted line.
                            ,"DashStyleDashDot"    : 3   ; Alternating dash-dot line.
                            ,"DashStyleDashDotDot" : 4   ; Alternated dash-dot-dot line.
                            ,"DashStyleCustom"     : 5 } ; User-Defined, custom dashed line.
        
        ; Identifies the available algorithms for dithering when a bitmap is converted.
        Static DitherType := {"DitherTypeNone"           : 0    ; No dithering is performed.
                             ,"DitherTypeSolid"          : 1    ; No dithering is performed.
                             ,"DitherTypeOrdered4x4"     : 2    ; perform dithering based on the colors in one of the standard fixed palettes.
                             ,"DitherTypeOrdered8x8"     : 3    ; Dithering is performed using the colors in one of the standard fixed palettes.
                             ,"DitherTypeOrdered16x16"   : 4    ; Dithering is performed using the colors in one of the standard fixed palettes.
                             ,"DitherTypeSpiral4x4"      : 5    ; Dithering is performed using the colors in one of the standard fixed palettes.
                             ,"DitherTypeSpiral8x8"      : 6    ; Dithering is performed using the colors in one of the standard fixed palettes.
                             ,"DitherTypeDualSpiral4x4"  : 7    ; Dithering is performed using the colors in one of the standard fixed palettes.
                             ,"DitherTypeDualSpiral8x8"  : 8    ; Dithering is performed using the colors in one of the standard fixed palettes.
                             ,"DitherTypeErrorDiffusion" : 9    ; Dithering is performed based on the palette specified by the palette parameter of the Bitmap::ConvertFormat method. 
                             ,"DitherTypeMax"            : 10 } ; TBD
        
        ; Specifies the spacing, orientation, and quality of the rendering for driver strings.
        Static DriverStringOptions := {"DriverStringOptionsCmapLookup"      : 1   ; String array contains Unicode character values.
                                      ,"DriverStringOptionsVertical"        : 2   ; String is displayed vertically.
                                      ,"DriverStringOptionsRealizedAdvance" : 4   ; Glyph positions are calculated from the position of the first glyph. 
                                      ,"DriverStringOptionsLimitSubpixel"   : 8 } ; Less memory should be used for cache of antialiased glyphs.
        
        ; Identifies metafile record types used in Windows Metafile Format (WMF), Enhanced Metafile (EMF), and EMF+ files. 
        Static EmfPlusRecordType := {"WmfRecordTypeSetBkColor"                  : (0x201|0x4000) ; TBD
                                    ,"WmfRecordTypeSetBkMode"                   : (0x102|0x4000) ; TBD
                                    ,"WmfRecordTypeSetMapMode"                  : (0x103|0x4000) ; TBD
                                    ,"WmfRecordTypeSetROP2"                     : (0x104|0x4000) ; TBD
                                    ,"WmfRecordTypeSetRelAbs"                   : (0x105|0x4000) ; TBD
                                    ,"WmfRecordTypeSetPolyFillMode"             : (0x106|0x4000) ; TBD
                                    ,"WmfRecordTypeSetStretchBltMode"           : (0x107|0x4000) ; TBD
                                    ,"WmfRecordTypeSetTextCharExtra"            : (0x108|0x4000) ; TBD
                                    ,"WmfRecordTypeSetTextColor"                : (0x209|0x4000) ; TBD
                                    ,"WmfRecordTypeSetTextJustification"        : (0x20A|0x4000) ; TBD
                                    ,"WmfRecordTypeSetWindowOrg"                : (0x20B|0x4000) ; TBD
                                    ,"WmfRecordTypeSetWindowExt"                : (0x20C|0x4000) ; TBD
                                    ,"WmfRecordTypeSetViewportOrg"              : (0x20D|0x4000) ; TBD
                                    ,"WmfRecordTypeSetViewportExt"              : (0x20E|0x4000) ; TBD
                                    ,"WmfRecordTypeOffsetWindowOrg"             : (0x20F|0x4000) ; TBD
                                    ,"WmfRecordTypeScaleWindowExt"              : (0x410|0x4000) ; TBD
                                    ,"WmfRecordTypeOffsetViewportOrg"           : (0x211|0x4000) ; TBD
                                    ,"WmfRecordTypeScaleViewportExt"            : (0x412|0x4000) ; TBD
                                    ,"WmfRecordTypeLineTo"                      : (0x213|0x4000) ; TBD
                                    ,"WmfRecordTypeMoveTo"                      : (0x214|0x4000) ; TBD
                                    ,"WmfRecordTypeExcludeClipRect"             : (0x415|0x4000) ; TBD
                                    ,"WmfRecordTypeIntersectClipRect"           : (0x416|0x4000) ; TBD
                                    ,"WmfRecordTypeArc"                         : (0x817|0x4000) ; TBD
                                    ,"WmfRecordTypeEllipse"                     : (0x418|0x4000) ; TBD
                                    ,"WmfRecordTypeFloodFill"                   : (0x419|0x4000) ; TBD
                                    ,"WmfRecordTypePie"                         : (0x81A|0x4000) ; TBD
                                    ,"WmfRecordTypeRectangle"                   : (0x41B|0x4000) ; TBD
                                    ,"WmfRecordTypeRoundRect"                   : (0x61C|0x4000) ; TBD
                                    ,"WmfRecordTypePatBlt"                      : (0x61D|0x4000) ; TBD
                                    ,"WmfRecordTypeSaveDC"                      : (0x01E|0x4000) ; TBD
                                    ,"WmfRecordTypeSetPixel"                    : (0x41F|0x4000) ; TBD
                                    ,"WmfRecordTypeOffsetClipRgn"               : (0x220|0x4000) ; TBD
                                    ,"WmfRecordTypeTextOut"                     : (0x521|0x4000) ; TBD
                                    ,"WmfRecordTypeBitBlt"                      : (0x922|0x4000) ; TBD
                                    ,"WmfRecordTypeStretchBlt"                  : (0xB23|0x4000) ; TBD
                                    ,"WmfRecordTypePolygon"                     : (0x324|0x4000) ; TBD
                                    ,"WmfRecordTypePolyline"                    : (0x325|0x4000) ; TBD
                                    ,"WmfRecordTypeEscape"                      : (0x626|0x4000) ; TBD
                                    ,"WmfRecordTypeRestoreDC"                   : (0x127|0x4000) ; TBD
                                    ,"WmfRecordTypeFillRegion"                  : (0x228|0x4000) ; TBD
                                    ,"WmfRecordTypeFrameRegion"                 : (0x429|0x4000) ; TBD
                                    ,"WmfRecordTypeInvertRegion"                : (0x12A|0x4000) ; TBD
                                    ,"WmfRecordTypePaintRegion"                 : (0x12B|0x4000) ; TBD
                                    ,"WmfRecordTypeSelectClipRegion"            : (0x12C|0x4000) ; TBD
                                    ,"WmfRecordTypeSelectObject"                : (0x12D|0x4000) ; TBD
                                    ,"WmfRecordTypeSetTextAlign"                : (0x12E|0x4000) ; TBD
                                    ,"WmfRecordTypeDrawText"                    : (0x62F|0x4000) ; TBD
                                    ,"WmfRecordTypeChord"                       : (0x830|0x4000) ; TBD
                                    ,"WmfRecordTypeSetMapperFlags"              : (0x231|0x4000) ; TBD
                                    ,"WmfRecordTypeExtTextOut"                  : (0xA32|0x4000) ; TBD
                                    ,"WmfRecordTypeSetDIBToDev"                 : (0xD33|0x4000) ; TBD
                                    ,"WmfRecordTypeSelectPalette"               : (0x234|0x4000) ; TBD
                                    ,"WmfRecordTypeRealizePalette"              : (0x035|0x4000) ; TBD
                                    ,"WmfRecordTypeAnimatePalette"              : (0x436|0x4000) ; TBD
                                    ,"WmfRecordTypeSetPalEntries"               : (0x037|0x4000) ; TBD
                                    ,"WmfRecordTypePolyPolygon"                 : (0x538|0x4000) ; TBD
                                    ,"WmfRecordTypeResizePalette"               : (0x139|0x4000) ; TBD
                                    ,"WmfRecordTypeDIBBitBlt"                   : (0x940|0x4000) ; TBD
                                    ,"WmfRecordTypeDIBStretchBlt"               : (0xB41|0x4000) ; TBD
                                    ,"WmfRecordTypeDIBCreatePatternBrush"       : (0x142|0x4000) ; TBD
                                    ,"WmfRecordTypeStretchDIB"                  : (0xF43|0x4000) ; TBD
                                    ,"WmfRecordTypeExtFloodFill"                : (0x548|0x4000) ; TBD
                                    ,"WmfRecordTypeSetLayout"                   : (0x149|0x4000) ; TBD
                                    ,"WmfRecordTypeResetDC"                     : (0x14C|0x4000) ; TBD
                                    ,"WmfRecordTypeStartDoc"                    : (0x14D|0x4000) ; TBD
                                    ,"WmfRecordTypeStartPage"                   : (0x04F|0x4000) ; TBD
                                    ,"WmfRecordTypeEndPage"                     : (0x050|0x4000) ; TBD
                                    ,"WmfRecordTypeAbortDoc"                    : (0x052|0x4000) ; TBD
                                    ,"WmfRecordTypeEndDoc"                      : (0x05E|0x4000) ; TBD
                                    ,"WmfRecordTypeDeleteObject"                : (0x1F0|0x4000) ; TBD
                                    ,"WmfRecordTypeCreatePalette"               : (0x0F7|0x4000) ; TBD
                                    ,"WmfRecordTypeCreateBrush"                 : (0x0F8|0x4000) ; TBD
                                    ,"WmfRecordTypeCreatePatternBrush"          : (0x1F9|0x4000) ; TBD
                                    ,"WmfRecordTypeCreatePenIndirect"           : (0x2FA|0x4000) ; TBD
                                    ,"WmfRecordTypeCreateFontIndirect"          : (0x2FB|0x4000) ; TBD
                                    ,"WmfRecordTypeCreateBrushIndirect"         : (0x2FC|0x4000) ; TBD
                                    ,"WmfRecordTypeCreateBitmapIndirect"        : (0x2FD|0x4000) ; TBD
                                    ,"WmfRecordTypeCreateBitmap"                : (0x6FE|0x4000) ; TBD
                                    ,"WmfRecordTypeCreateRegion"                : (0x6FF|0x4000) ; TBD
                                    ,"EmfRecordTypeHeader"                      : 1       ; TBD
                                    ,"EmfRecordTypePolyBezier"                  : 2       ; TBD
                                    ,"EmfRecordTypePolygon"                     : 3       ; TBD
                                    ,"EmfRecordTypePolyline"                    : 4       ; TBD
                                    ,"EmfRecordTypePolyBezierTo"                : 5       ; TBD
                                    ,"EmfRecordTypePolyLineTo"                  : 6       ; TBD
                                    ,"EmfRecordTypePolyPolyline"                : 7       ; TBD
                                    ,"EmfRecordTypePolyPolygon"                 : 8       ; TBD
                                    ,"EmfRecordTypeSetWindowExtEx"              : 9       ; TBD
                                    ,"EmfRecordTypeSetWindowOrgEx"              : 10      ; TBD
                                    ,"EmfRecordTypeSetViewportExtEx"            : 11      ; TBD
                                    ,"EmfRecordTypeSetViewportOrgEx"            : 12      ; TBD
                                    ,"EmfRecordTypeSetBrushOrgEx"               : 13      ; TBD
                                    ,"EmfRecordTypeEOF"                         : 14      ; TBD
                                    ,"EmfRecordTypeSetPixelV"                   : 15      ; TBD
                                    ,"EmfRecordTypeSetMapperFlags"              : 16      ; TBD
                                    ,"EmfRecordTypeSetMapMode"                  : 17      ; TBD
                                    ,"EmfRecordTypeSetBkMode"                   : 18      ; TBD
                                    ,"EmfRecordTypeSetPolyFillMode"             : 19      ; TBD
                                    ,"EmfRecordTypeSetROP2"                     : 20      ; TBD
                                    ,"EmfRecordTypeSetStretchBltMode"           : 21      ; TBD
                                    ,"EmfRecordTypeSetTextAlign"                : 22      ; TBD
                                    ,"EmfRecordTypeSetColorAdjustment"          : 23      ; TBD
                                    ,"EmfRecordTypeSetTextColor"                : 24      ; TBD
                                    ,"EmfRecordTypeSetBkColor"                  : 25      ; TBD
                                    ,"EmfRecordTypeOffsetClipRgn"               : 26      ; TBD
                                    ,"EmfRecordTypeMoveToEx"                    : 27      ; TBD
                                    ,"EmfRecordTypeSetMetaRgn"                  : 28      ; TBD
                                    ,"EmfRecordTypeExcludeClipRect"             : 29      ; TBD
                                    ,"EmfRecordTypeIntersectClipRect"           : 30      ; TBD
                                    ,"EmfRecordTypeScaleViewportExtEx"          : 31      ; TBD
                                    ,"EmfRecordTypeScaleWindowExtEx"            : 32      ; TBD
                                    ,"EmfRecordTypeSaveDC"                      : 33      ; TBD
                                    ,"EmfRecordTypeRestoreDC"                   : 34      ; TBD
                                    ,"EmfRecordTypeSetWorldTransform"           : 35      ; TBD
                                    ,"EmfRecordTypeModifyWorldTransform"        : 36      ; TBD
                                    ,"EmfRecordTypeSelectObject"                : 37      ; TBD
                                    ,"EmfRecordTypeCreatePen"                   : 38      ; TBD
                                    ,"EmfRecordTypeCreateBrushIndirect"         : 39      ; TBD
                                    ,"EmfRecordTypeDeleteObject"                : 40      ; TBD
                                    ,"EmfRecordTypeAngleArc"                    : 41      ; TBD
                                    ,"EmfRecordTypeEllipse"                     : 42      ; TBD
                                    ,"EmfRecordTypeRectangle"                   : 43      ; TBD
                                    ,"EmfRecordTypeRoundRect"                   : 44      ; TBD
                                    ,"EmfRecordTypeArc"                         : 45      ; TBD
                                    ,"EmfRecordTypeChord"                       : 46      ; TBD
                                    ,"EmfRecordTypePie"                         : 47      ; TBD
                                    ,"EmfRecordTypeSelectPalette"               : 48      ; TBD
                                    ,"EmfRecordTypeCreatePalette"               : 49      ; TBD
                                    ,"EmfRecordTypeSetPaletteEntries"           : 50      ; TBD
                                    ,"EmfRecordTypeResizePalette"               : 51      ; TBD
                                    ,"EmfRecordTypeRealizePalette"              : 52      ; TBD
                                    ,"EmfRecordTypeExtFloodFill"                : 53      ; TBD
                                    ,"EmfRecordTypeLineTo"                      : 54      ; TBD
                                    ,"EmfRecordTypeArcTo"                       : 55      ; TBD
                                    ,"EmfRecordTypePolyDraw"                    : 56      ; TBD
                                    ,"EmfRecordTypeSetArcDirection"             : 57      ; TBD
                                    ,"EmfRecordTypeSetMiterLimit"               : 58      ; TBD
                                    ,"EmfRecordTypeBeginPath"                   : 59      ; TBD
                                    ,"EmfRecordTypeEndPath"                     : 60      ; TBD
                                    ,"EmfRecordTypeCloseFigure"                 : 61      ; TBD
                                    ,"EmfRecordTypeFillPath"                    : 62      ; TBD
                                    ,"EmfRecordTypeStrokeAndFillPath"           : 63      ; TBD
                                    ,"EmfRecordTypeStrokePath"                  : 64      ; TBD
                                    ,"EmfRecordTypeFlattenPath"                 : 65      ; TBD
                                    ,"EmfRecordTypeWidenPath"                   : 66      ; TBD
                                    ,"EmfRecordTypeSelectClipPath"              : 67      ; TBD
                                    ,"EmfRecordTypeAbortPath"                   : 68      ; TBD
                                    ,"EmfRecordTypeReserved_069"                : 69      ; TBD
                                    ,"EmfRecordTypeGdiComment"                  : 70      ; TBD
                                    ,"EmfRecordTypeFillRgn"                     : 71      ; TBD
                                    ,"EmfRecordTypeFrameRgn"                    : 72      ; TBD
                                    ,"EmfRecordTypeInvertRgn"                   : 73      ; TBD
                                    ,"EmfRecordTypePaintRgn"                    : 74      ; TBD
                                    ,"EmfRecordTypeExtSelectClipRgn"            : 75      ; TBD
                                    ,"EmfRecordTypeBitBlt"                      : 76      ; TBD
                                    ,"EmfRecordTypeStretchBlt"                  : 77      ; TBD
                                    ,"EmfRecordTypeMaskBlt"                     : 78      ; TBD
                                    ,"EmfRecordTypePlgBlt"                      : 79      ; TBD
                                    ,"EmfRecordTypeSetDIBitsToDevice"           : 80      ; TBD
                                    ,"EmfRecordTypeStretchDIBits"               : 81      ; TBD
                                    ,"EmfRecordTypeExtCreateFontIndirect"       : 82      ; TBD
                                    ,"EmfRecordTypeExtTextOutA"                 : 83      ; TBD
                                    ,"EmfRecordTypeExtTextOutW"                 : 84      ; TBD
                                    ,"EmfRecordTypePolyBezier16"                : 85      ; TBD
                                    ,"EmfRecordTypePolygon16"                   : 86      ; TBD
                                    ,"EmfRecordTypePolyline16"                  : 87      ; TBD
                                    ,"EmfRecordTypePolyBezierTo16"              : 88      ; TBD
                                    ,"EmfRecordTypePolylineTo16"                : 89      ; TBD
                                    ,"EmfRecordTypePolyPolyline16"              : 90      ; TBD
                                    ,"EmfRecordTypePolyPolygon16"               : 91      ; TBD
                                    ,"EmfRecordTypePolyDraw16"                  : 92      ; TBD
                                    ,"EmfRecordTypeCreateMonoBrush"             : 93      ; TBD
                                    ,"EmfRecordTypeCreateDIBPatternBrushPt"     : 94      ; TBD
                                    ,"EmfRecordTypeExtCreatePen"                : 95      ; TBD
                                    ,"EmfRecordTypePolyTextOutA"                : 96      ; TBD
                                    ,"EmfRecordTypePolyTextOutW"                : 97      ; TBD
                                    ,"EmfRecordTypeSetICMMode"                  : 98      ; TBD
                                    ,"EmfRecordTypeCreateColorSpace"            : 99      ; TBD
                                    ,"EmfRecordTypeSetColorSpace"               : 100     ; TBD
                                    ,"EmfRecordTypeDeleteColorSpace"            : 101     ; TBD
                                    ,"EmfRecordTypeGLSRecord"                   : 102     ; TBD
                                    ,"EmfRecordTypeGLSBoundedRecord"            : 103     ; TBD
                                    ,"EmfRecordTypePixelFormat"                 : 104     ; TBD
                                    ,"EmfRecordTypeDrawEscape"                  : 105     ; TBD
                                    ,"EmfRecordTypeExtEscape"                   : 106     ; TBD
                                    ,"EmfRecordTypeStartDoc"                    : 107     ; TBD
                                    ,"EmfRecordTypeSmallTextOut"                : 108     ; TBD
                                    ,"EmfRecordTypeForceUFIMapping"             : 109     ; TBD
                                    ,"EmfRecordTypeNamedEscape"                 : 110     ; TBD
                                    ,"EmfRecordTypeColorCorrectPalette"         : 111     ; TBD
                                    ,"EmfRecordTypeSetICMProfileA"              : 112     ; TBD
                                    ,"EmfRecordTypeSetICMProfileW"              : 113     ; TBD
                                    ,"EmfRecordTypeAlphaBlend"                  : 114     ; TBD
                                    ,"EmfRecordTypeSetLayout"                   : 115     ; TBD
                                    ,"EmfRecordTypeTransparentBlt"              : 116     ; TBD
                                    ,"EmfRecordTypeReserved_117"                : 117     ; TBD
                                    ,"EmfRecordTypeGradientFill"                : 118     ; TBD
                                    ,"EmfRecordTypeSetLinkedUFIs"               : 119     ; TBD
                                    ,"EmfRecordTypeSetTextJustification"        : 120     ; TBD
                                    ,"EmfRecordTypeColorMatchToTargetW"         : 121     ; TBD
                                    ,"EmfRecordTypeCreateColorSpaceW"           : 122     ; TBD
                                    ,"EmfRecordTypeMax"                         : 122     ; TBD
                                    ,"EmfRecordTypeMin"                         : 1       ; TBD
                                    ,"EmfPlusRecordTypeInvalid"                 : 16384   ; TBD
                                    ,"EmfPlusRecordTypeHeader"                  : 16385   ; Identifies a record that is the EMF+ header.
                                    ,"EmfPlusRecordTypeEndOfFile"               : 16386   ; Identifies a record that marks the last EMF+ record of a metafile.
                                    ,"EmfPlusRecordTypeComment"                 : 16387   ; GDIP.Graphics.AddMetafileComment()
                                    ,"EmfPlusRecordTypeGetDC"                   : 16388   ; GDIP.Graphics.GetHDC()
                                    ,"EmfPlusRecordTypeMultiFormatStart"        : 16389   ; Identifies the start of a multiple-format block.
                                    ,"EmfPlusRecordTypeMultiFormatSection"      : 16390   ; Identifies a section in a multiple-format block.
                                    ,"EmfPlusRecordTypeMultiFormatEnd"          : 16391   ; Identifies the end of a multiple-format block.
                                    ,"EmfPlusRecordTypeObject"                  : 16392   ; TBD
                                    ,"EmfPlusRecordTypeClear"                   : 16393   ; GDIP.Graphics.Clear()
                                    ,"EmfPlusRecordTypeFillRects"               : 16394   ; FillRectangles Methods
                                    ,"EmfPlusRecordTypeDrawRects"               : 16395   ; DrawRectangles Methods
                                    ,"EmfPlusRecordTypeFillPolygon"             : 16396   ; FillPolygon Methods
                                    ,"EmfPlusRecordTypeDrawLines"               : 16397   ; DrawLines Methods
                                    ,"EmfPlusRecordTypeFillEllipse"             : 16398   ; FillEllipse Methods
                                    ,"EmfPlusRecordTypeDrawEllipse"             : 16399   ; DrawEllipse Methods
                                    ,"EmfPlusRecordTypeFillPie"                 : 16400   ; FillPie Methods
                                    ,"EmfPlusRecordTypeDrawPie"                 : 16401   ; DrawPie Methods
                                    ,"EmfPlusRecordTypeDrawArc"                 : 16402   ; DrawArc Methods
                                    ,"EmfPlusRecordTypeFillRegion"              : 16403   ; GDIP.Graphics.()
                                    ,"EmfPlusRecordTypeFillPath"                : 16404   ; GDIP.Graphics.()
                                    ,"EmfPlusRecordTypeDrawPath"                : 16405   ; GDIP.Graphics.()
                                    ,"EmfPlusRecordTypeFillClosedCurve"         : 16406   ; FillClosedCurve Methods
                                    ,"EmfPlusRecordTypeDrawClosedCurve"         : 16407   ; DrawClosedCurve Methods
                                    ,"EmfPlusRecordTypeDrawCurve"               : 16408   ; DrawCurve Methods
                                    ,"EmfPlusRecordTypeDrawBeziers"             : 16409   ; DrawBeziers Methods
                                    ,"EmfPlusRecordTypeDrawImage"               : 16410   ; DrawImage Methods
                                    ,"EmfPlusRecordTypeDrawImagePoints"         : 16411   ; DrawImage Methods (destination point arrays)
                                    ,"EmfPlusRecordTypeDrawString"              : 16412   ; DrawString Methods
                                    ,"EmfPlusRecordTypeSetRenderingOrigin"      : 16413   ; GDIP.Graphics.SetRenderingOrigin()
                                    ,"EmfPlusRecordTypeSetAntiAliasMode"        : 16414   ; GDIP.Graphics.SetSmoothingMode()
                                    ,"EmfPlusRecordTypeSetTextRenderingHint"    : 16415   ; GDIP.Graphics.SetTextRenderingHint()
                                    ,"EmfPlusRecordTypeSetTextContrast"         : 16416   ; GDIP.Graphics.SetTextContrast()
                                    ,"EmfPlusRecordTypeSetInterpolationMode"    : 16417   ; GDIP.Graphics.SetInterpolationMode()
                                    ,"EmfPlusRecordTypeSetPixelOffsetMode"      : 16418   ; GDIP.Graphics.SetPixelOffsetMode()
                                    ,"EmfPlusRecordTypeSetCompositingMode"      : 16419   ; GDIP.Graphics.SetCompositingMode()
                                    ,"EmfPlusRecordTypeSetCompositingQuality"   : 16420   ; GDIP.Graphics.SetCompositingQuality()
                                    ,"EmfPlusRecordTypeSave"                    : 16421   ; GDIP.Graphics.Save()
                                    ,"EmfPlusRecordTypeRestore"                 : 16422   ; GDIP.Graphics.Restore()
                                    ,"EmfPlusRecordTypeBeginContainer"          : 16423   ; GDIP.Graphics.BeginContainer()
                                    ,"EmfPlusRecordTypeBeginContainerNoParams"  : 16424   ; GDIP.Graphics.BeginContainer()
                                    ,"EmfPlusRecordTypeEndContainer"            : 16425   ; GDIP.Graphics.EndContainer()
                                    ,"EmfPlusRecordTypeSetWorldTransform"       : 16426   ; GDIP.Graphics.SetTransform()
                                    ,"EmfPlusRecordTypeResetWorldTransform"     : 16427   ; GDIP.Graphics.ResetTransform()
                                    ,"EmfPlusRecordTypeMultiplyWorldTransform"  : 16428   ; GDIP.Graphics.MultiplyTransform()
                                    ,"EmfPlusRecordTypeTranslateWorldTransform" : 16429   ; GDIP.Graphics.TranslateTransform()
                                    ,"EmfPlusRecordTypeScaleWorldTransform"     : 16430   ; GDIP.Graphics.ScaleTransform()
                                    ,"EmfPlusRecordTypeRotateWorldTransform"    : 16431   ; GDIP.Graphics.RotateTransform()
                                    ,"EmfPlusRecordTypeSetPageTransform"        : 16432   ; GDIP.Graphics.SetPageScale() and GDIP.Graphics.SetPageUnit()
                                    ,"EmfPlusRecordTypeResetClip"               : 16433   ; GDIP.Graphics.ResetClip()
                                    ,"EmfPlusRecordTypeSetClipRect"             : 16434   ; GDIP.Graphics.SetClip()
                                    ,"EmfPlusRecordTypeSetClipPath"             : 16435   ; GDIP.Graphics.SetClip()
                                    ,"EmfPlusRecordTypeSetClipRegion"           : 16436   ; GDIP.Graphics.SetClip()
                                    ,"EmfPlusRecordTypeOffsetClip"              : 16437   ; TranslateClip Methods
                                    ,"EmfPlusRecordTypeDrawDriverString"        : 16438   ; GDIP.Graphics.DrawDriverString()
                                    ,"EmfPlusRecordTypeStrokeFillPath"          : 16439   ; TBD
                                    ,"EmfPlusRecordTypeSerializableObject"      : 16440   ; TBD
                                    ,"EmfPlusRecordTypeSetTSGraphics"           : 16441   ; TBD
                                    ,"EmfPlusRecordTypeSetTSClip"               : 16442   ; TBD
                                    ,"EmfPlusRecordTotal"                       : 16443   ; TBD
                                    ,"EmfPlusRecordTypeMax"                     : -1      ; TBD
                                    ,"EmfPlusRecordTypeMin"                     : 16385 } ; TBD
        
        ; Specifies options for the GDIP.Metafile.EmfToWmfBits() method.
        Static EmfToWmfBitsFlags := {"EmfToWmfBitsFlagsDefault"          : 0   ; Default conversion.
                                    ,"EmfToWmfBitsFlagsEmbedEmf"         : 1   ; Source EMF metafile is embedded as a comment in the resulting WMF metafile.
                                    ,"EmfToWmfBitsFlagsIncludePlaceable" : 2   ; Resulting WMF metafile is in the placeable metafile format.
                                    ,"EmfToWmfBitsFlagsNoXORClip"        : 4 } ; Clipping region is stored in the metafile in the traditional way. 
        
        ;
        Static EmfType := {"EmfTypeEmfOnly"     : 3   ; Only EMF
                          ,"EmfTypeEmfPlusOnly" : 4   ; Only EMF+
                          ,"EmfTypeEmfPlusDual" : 5 } ; Both EMF and EMF+
        
        ; Specifies data types for image codec (encoder/decoder) parameters.
        Static EncoderParameterValueType := {"EncoderParameterValueTypeByte"          : 1   ; Is an 8-bit unsigned integer.
                                            ,"EncoderParameterValueTypeASCII"         : 2   ; Is a null-terminated character string.
                                            ,"EncoderParameterValueTypeShort"         : 3   ; Is a 16-bit unsigned integer.
                                            ,"EncoderParameterValueTypeLong"          : 4   ; Is a 32-bit unsigned integer.
                                            ,"EncoderParameterValueTypeRational"      : 5   ; Is an array of two, 32-bit unsigned integers representing a fraction.
                                            ,"EncoderParameterValueTypeLongRange"     : 6   ; Is an array of two, 32-bit unsigned integers representing a range.
                                            ,"EncoderParameterValueTypeUndefined"     : 7   ; Is an array of bytes that can hold values of any type.
                                            ,"EncoderParameterValueTypeRationalRange" : 8   ; Is an array of four, 32-bit unsigned integers representing a range of rational numbers.
                                            ,"EncoderParameterValueTypePointer"       : 9 } ; Is a pointer to a block of custom metadata.
        
        ; Specifies values that can be passed as arguments to image encoders.
        Static EncoderValue := {"EncoderValueColorTypeCMYK"            : 0    ; Not used in GDI+ version 1.0.
                               ,"EncoderValueColorTypeYCCK"            : 1    ; Not used in GDI+ version 1.0.
                               ,"EncoderValueCompressionLZW"           : 2    ; TIFF image, specifies the LZW compression method.
                               ,"EncoderValueCompressionCCITT3"        : 3    ; TIFF image, specifies the CCITT3 compression method.
                               ,"EncoderValueCompressionCCITT4"        : 4    ; TIFF image, specifies the CCITT4 compression method.
                               ,"EncoderValueCompressionRle"           : 5    ; TIFF image, specifies the RLE compression method.
                               ,"EncoderValueCompressionNone"          : 6    ; TIFF image, specifies no compression.
                               ,"EncoderValueScanMethodInterlaced"     : 7    ; Not used in GDI+ version 1.0.
                               ,"EncoderValueScanMethodNonInterlaced"  : 8    ; Not used in GDI+ version 1.0.
                               ,"EncoderValueVersionGif87"             : 9    ; Not used in GDI+ version 1.0.
                               ,"EncoderValueVersionGif89"             : 10   ; Not used in GDI+ version 1.0.
                               ,"EncoderValueRenderProgressive"        : 11   ; Not used in GDI+ version 1.0.
                               ,"EncoderValueRenderNonProgressive"     : 12   ; Not used in GDI+ version 1.0.
                               ,"EncoderValueTransformRotate90"        : 13   ; JPEG image, specifies lossless 90-degree clockwise rotation.
                               ,"EncoderValueTransformRotate180"       : 14   ; JPEG image, specifies lossless 180-degree clockwise rotation.
                               ,"EncoderValueTransformRotate270"       : 15   ; JPEG image, specifies lossless 270-degree clockwise rotation.
                               ,"EncoderValueTransformFlipHorizontal"  : 16   ; JPEG image, specifies a lossless horizontal flip.
                               ,"EncoderValueTransformFlipVertical"    : 17   ; JPEG image, specifies a lossless vertical flip.
                               ,"EncoderValueMultiFrame"               : 18   ; Specifies multiple-frame encoding.
                               ,"EncoderValueLastFrame"                : 19   ; Specifies the last frame of a multiple-frame image.
                               ,"EncoderValueFlush"                    : 20   ; Specifies that the encoder object is to be closed.
                               ,"EncoderValueFrameDimensionTime"       : 21   ; Not used in GDI+ version 1.0.
                               ,"EncoderValueFrameDimensionResolution" : 22   ; Not used in GDI+ version 1.0.
                               ,"EncoderValueFrameDimensionPage"       : 23   ; TIFF image, specifies the page frame dimension
                               ,"EncoderValueColorTypeGray"            : 24   ; Undefined
                               ,"EncoderValueColorTypeRGB"             : 25 } ; Undefined
        
        ; Specifies how to fill areas that are formed when a path or curve intersects itself.
        Static FillMode := {"FillModeAlternate" : 0   ; Areas are filled according to the even-odd parity rule.
                           ,"FillModeWinding"   : 1 } ; Areas are filled according to the nonzero winding rule.
        
        ; Specifies when to flush the queue of graphics operations.
        Static FlushIntention := {"FlushIntentionFlush" : 0   ; Pending rendering operations are executed and Flush() is not synchronized.
                                 ,"FlushIntentionSync"  : 1 } ; Pending rendering operations are executed and Flush() is synchronized.
        
        ; Specifies the style of the typeface of a font.
        Static FontStyle := {"FontStyleRegular"    : 0   ; Normal weight or thickness of the typeface.
                            ,"FontStyleBold"       : 1   ; Bold typeface. Bold is a heavier weight or thickness.
                            ,"FontStyleItalic"     : 2   ; Italic typeface, which produces a noticeable slant to the vertical stems of the characters.
                            ,"FontStyleBoldItalic" : 3   ; Typeface is both bold and italic.
                            ,"FontStyleUnderline"  : 4   ; Underline, which displays a line underneath the baseline of the characters.
                            ,"FontStyleStrikeout"  : 8 } ; Strikeout, which displays a horizontal line drawn through the middle of the characters.
        
        ; 
        Static GenericFontFamily := {"GenericFontFamilySerif"     : 0   ; 
                                    ,"GenericFontFamilySansSerif" : 1   ; 
                                    ,"GenericFontFamilyMonospace" : 2 } ; 
        
        ; 
        Static GpTestControlEnum := {"TestControlForceBilinear"  : 0
                                    ,"TestControlNoICM"          : 1
                                    ,"TestControlGetBuildNumber" : 2 }
        
        ; Specifies the hatch pattern used by a brush of type HatchBrush.
        Static HatchStyle := {"HatchStyleHorizontal"             : 0    ; Horizontal lines.
                             ,"HatchStyleVertical"               : 1    ; Vertical lines.                                                                                                                                                                                                                                         
                             ,"HatchStyleForwardDiagonal"        : 2    ; Diagonal lines that slant to the right from top points to bottom points.
                             ,"HatchStyleBackwardDiagonal"       : 3    ; Diagonal lines that slant to the left from top points to bottom points.
                             ,"HatchStyleCross"                  : 4    ; Horizontal and vertical lines that cross at 90-degree angles.
                             ,"HatchStyleDiagonalCross"          : 5    ; Forward diagonal and backward diagonal lines that cross at 90-degree angles.
                             ,"HatchStyle05Percent"              : 6    ;  5% hatch. The ratio of foreground color to background color is 5:100.
                             ,"HatchStyle10Percent"              : 7    ; 10% hatch. The ratio of foreground color to background color is 10:100.
                             ,"HatchStyle20Percent"              : 8    ; 20% hatch. The ratio of foreground color to background color is 20:100.
                             ,"HatchStyle25Percent"              : 9    ; 25% hatch. The ratio of foreground color to background color is 25:100.
                             ,"HatchStyle30Percent"              : 10   ; 30% hatch. The ratio of foreground color to background color is 30:100.
                             ,"HatchStyle40Percent"              : 11   ; 40% hatch. The ratio of foreground color to background color is 40:100.
                             ,"HatchStyle50Percent"              : 12   ; 50% hatch. The ratio of foreground color to background color is 50:100.
                             ,"HatchStyle60Percent"              : 13   ; 60% hatch. The ratio of foreground color to background color is 60:100.
                             ,"HatchStyle70Percent"              : 14   ; 70% hatch. The ratio of foreground color to background color is 70:100.
                             ,"HatchStyle75Percent"              : 15   ; 75% hatch. The ratio of foreground color to background color is 75:100.
                             ,"HatchStyle80Percent"              : 16   ; 80% hatch. The ratio of foreground color to background color is 80:100.
                             ,"HatchStyle90Percent"              : 17   ; 90% hatch. The ratio of foreground color to background color is 90:100.
                             ,"HatchStyleLightDownwardDiagonal"  : 18   ; Diagonal lines that slant to the right from top points to bottom points and are spaced 50 percent closer together than HatchStyleForwardDiagonal but are not antialiased.
                             ,"HatchStyleLightUpwardDiagonal"    : 19   ; Diagonal lines that slant to the left from top points to bottom points and are spaced 50 percent closer together than HatchStyleBackwardDiagonal but are not antialiased.
                             ,"HatchStyleDarkDownwardDiagonal"   : 20   ; Diagonal lines that slant to the right from top points to bottom points, are spaced 50 percent closer together than HatchStyleForwardDiagonal, and are twice the width of HatchStyleForwardDiagonal but are not antialiased.
                             ,"HatchStyleDarkUpwardDiagonal"     : 21   ; Diagonal lines that slant to the left from top points to bottom points, are spaced 50 percent closer together than HatchStyleBackwardDiagonal, and are twice the width of HatchStyleBackwardDiagonal but are not antialiased.
                             ,"HatchStyleWideDownwardDiagonal"   : 22   ; Diagonal lines that slant to the right from top points to bottom points, have the same spacing as HatchStyleForwardDiagonal, and are triple the width of HatchStyleForwardDiagonal but are not antialiased.
                             ,"HatchStyleWideUpwardDiagonal"     : 23   ; Diagonal lines that slant to the left from top points to bottom points, have the same spacing as HatchStyleBackwardDiagonal, and are triple the width of HatchStyleBackwardDiagonal but are not antialiased.
                             ,"HatchStyleLightVertical"          : 24   ; Vertical lines that are spaced 50 percent closer together than HatchStyleVertical.
                             ,"HatchStyleLightHorizontal"        : 25   ; Horizontal lines that are spaced 50 percent closer together than HatchStyleHorizontal.
                             ,"HatchStyleNarrowVertical"         : 26   ; Vertical lines that are spaced 75 percent closer together than HatchStyleVertical (or 25 percent closer together than HatchStyleLightVertical).
                             ,"HatchStyleNarrowHorizontal"       : 27   ; Horizontal lines that are spaced 75 percent closer together than HatchStyleHorizontal ( or 25 percent closer together than HatchStyleLightHorizontal).
                             ,"HatchStyleDarkVertical"           : 28   ; Vertical lines that are spaced 50 percent closer together than HatchStyleVerical and are twice the width of HatchStyleVertical.
                             ,"HatchStyleDarkHorizontal"         : 29   ; Horizontal lines that are spaced 50 percent closer together than HatchStyleHorizontal and are twice the width of HatchStyleHorizontal.
                             ,"HatchStyleDashedDownwardDiagonal" : 30   ; Horizontal lines that are composed of forward diagonals.
                             ,"HatchStyleDashedUpwardDiagonal"   : 31   ; Horizontal lines that are composed of backward diagonals.
                             ,"HatchStyleDashedHorizontal"       : 32   ; Horizontal dashed lines.
                             ,"HatchStyleDashedVertical"         : 33   ; Vertical dashed lines.
                             ,"HatchStyleSmallConfetti"          : 34   ; A hatch that has the appearance of confetti.
                             ,"HatchStyleLargeConfetti"          : 35   ; A hatch that has the appearance of confetti composed of larger pieces than HatchStyleSmallConfetti.
                             ,"HatchStyleZigZag"                 : 36   ; Horizontal lines of zigzags.
                             ,"HatchStyleWave"                   : 37   ; Horizontal lines of tildes.
                             ,"HatchStyleDiagonalBrick"          : 38   ; A hatch that has the appearance of a wall of bricks laid in a backward diagonal direction.
                             ,"HatchStyleHorizontalBrick"        : 39   ; A hatch that has the appearance of a wall of bricks laid horizontally.
                             ,"HatchStyleWeave"                  : 40   ; A hatch that has the appearance of a woven material.
                             ,"HatchStylePlaid"                  : 41   ; A hatch that has the appearance of a plaid material.
                             ,"HatchStyleDivot"                  : 42   ; A hatch that has the appearance of divots.
                             ,"HatchStyleDottedGrid"             : 43   ; Horizontal and vertical dotted lines that cross at 90-degree angles.
                             ,"HatchStyleDottedDiamond"          : 44   ; Forward diagonal and backward diagonal dotted lines that cross at 90-degree angles.
                             ,"HatchStyleShingle"                : 45   ; A hatch that has the appearance of shingles laid in a forward diagonal direction.
                             ,"HatchStyleTrellis"                : 46   ; A hatch that has the appearance of a trellis.
                             ,"HatchStyleSphere"                 : 47   ; A hatch that has the appearance of a checkerboard of spheres.
                             ,"HatchStyleSmallGrid"              : 48   ; Horizontal and vertical lines that cross at 90-degree angles and are spaced 50 percent closer together than HatchStyleCross.
                             ,"HatchStyleSmallCheckerBoard"      : 49   ; A hatch that has the appearance of a checkerboard.
                             ,"HatchStyleLargeCheckerBoard"      : 50   ; A hatch that has the appearance of a checkerboard with squares that are twice the size of HatchStyleSmallCheckerBoard.
                             ,"HatchStyleOutlinedDiamond"        : 51   ; Forward diagonal and backward diagonal lines that cross at 90-degree angles but are not antialiased.
                             ,"HatchStyleSolidDiamond"           : 52   ; A hatch that has the appearance of a checkerboard placed diagonally.
                             ,"HatchStyleTotal"                  : 53   ; No hatch thereby allowing the brush to be transparent.
                             ,"HatchStyleLargeGrid"              : 4    ; HatchStyleCross.
                             ,"HatchStyleMin"                    : 39   ; HatchStyleHorizonal.
                             ,"HatchStyleMax"                    : 52 } ; HatchStyleSolidDiamond.
        
        ; Specifies the number and type of histograms that represent the color channels of a bitmap.
        Static HistogramFormat := {"HistogramFormatARGB"  : 0   ; Returns four histograms: alpha, red, green, and blue channels.
                                  ,"HistogramFormatPARGB" : 1   ; Returns four histograms: one each for the alpha, red, green, and blue channels.
                                  ,"HistogramFormatRGB"   : 2   ; Returns three histograms: one each for the red, green, and blue channels. 
                                  ,"HistogramFormatGray"  : 3   ; Each pixel is converted to a grayscale value and one histogram is returned.
                                  ,"HistogramFormatB"     : 4   ; Returns a histogram for the blue channel.
                                  ,"HistogramFormatG"     : 5   ; Returns a histogram for the green channel.
                                  ,"HistogramFormatR"     : 6   ; Returns a histogram for the red channel.
                                  ,"HistogramFormatA"     : 7 } ; Returns a histogram for the alpha channel.
        
        ; Specifies how to display hot keys.
        Static HotkeyPrefix := {"HotkeyPrefixNone" : 0   ; No hot key processing occurs.
                               ,"HotkeyPrefixShow" : 1   ; Unicode text is scanned for ampersands (&), which are interpreted as hot key markers.
                               ,"HotkeyPrefixHide" : 2 } ; Unicode text is scanned for ampersands (&), which are substituted and removed.
        
        ; Indicates attributes of an image codec.
        Static ImageCodecFlags := {"ImageCodecFlagsEncoder"        : 1        ; Codec supports encoding (saving).
                                  ,"ImageCodecFlagsDecoder"        : 2        ; Codec supports decoding (reading).
                                  ,"ImageCodecFlagsSupportBitmap"  : 4        ; Codec supports raster images (bitmaps).
                                  ,"ImageCodecFlagsSupportVector"  : 8        ; Codec supports vector images (metafiles).
                                  ,"ImageCodecFlagsSeekableEncode" : 16       ; Encoder requires a seekable output stream.
                                  ,"ImageCodecFlagsBlockingDecode" : 32       ; Decoder has blocking behavior during the decoding process.
                                  ,"ImageCodecFlagsBuiltin"        : 65536    ; The codec is built in to GDI+.
                                  ,"ImageCodecFlagsSystem"         : 131072   ; Not used in GDI+ version 1.0.
                                  ,"ImageCodecFlagsUser"           : 262144 } ; Not used in GDI+ version 1.0.
        
        ; DONE THROUGH HERE
        ; Specifies the attributes of the pixel data contained in an Image object.
        Static ImageFlags := {"ImageFlagsNone"              : 0x0       ; No format information.
                             ,"ImageFlagsScalable"          : 0x1       ; Image can be scaled.
                             ,"ImageFlagsHasAlpha"          : 0x2       ; Pixel data contains alpha values.
                             ,"ImageFlagsHasTranslucent"    : 0x4       ; Pixel data has alpha values other than 0 and 255.
                             ,"ImageFlagsPartiallyScalable" : 0x8       ; Pixel data is partially scalable with some limitations.
                             ,"ImageFlagsColorSpaceRGB"     : 0x10      ; Image is stored using an RGB color space.
                             ,"ImageFlagsColorSpaceCMYK"    : 0x20      ; Image is stored using a CMYK color space.
                             ,"ImageFlagsColorSpaceGRAY"    : 0x40      ; Image is a grayscale image.
                             ,"ImageFlagsColorSpaceYCBCR"   : 0x80      ; Image is stored using a YCBCR color space.
                             ,"ImageFlagsColorSpaceYCCK"    : 0x100     ; Image is stored using a YCCK color space.
                             ,"ImageFlagsHasRealDPI"        : 0x1000    ; Dots per inch information is stored in the image.
                             ,"ImageFlagsHasRealPixelSize"  : 0x2000    ; Pixel size is stored in the image.
                             ,"ImageFlagsReadOnly"          : 0x10000   ; Pixel data is read-only.
                             ,"ImageFlagsCaching"           : 0x20000 } ; Pixel data can be cached for faster access.                                                 
        
        ; Specifies flags that are passed to the flags parameter of the GDIP.Bitmap.LockBits() method. 
        Static ImageLockMode := {"ImageLockModeRead"         : 1   ; Portion of the image is locked for reading.
                                ,"ImageLockModeWrite"        : 2   ; Portion of the image is locked for writing.
                                ,"ImageLockModeUserInputBuf" : 4 } ; Buffer used for reading or writing pixel data is allocated by the user.
        
        ; Indicates whether an image is a bitmap or a metafile.
        Static ImageType := {"ImageTypeUnknown"  : 0   ; Image type is not known.
                            ,"ImageTypeBitmap"   : 1   ; Bitmap image.
                            ,"ImageTypeMetafile" : 2 } ; Metafile image.
        
        ; Specifies the algorithm that is used when images are scaled or rotated.
        Static InterpolationMode := {"InterpolationModeInvalid"             : -1   ; Used internally.
                                    ,"InterpolationModeDefault"             :  0   ; Default interpolation mode.
                                    ,"InterpolationModeLowQuality"          :  1   ; Low-quality mode.
                                    ,"InterpolationModeHighQuality"         :  2   ; High-quality mode.
                                    ,"InterpolationModeBilinear"            :  3   ; Bilinear interpolation. Don't use to shirnk past 50% of original size.
                                    ,"InterpolationModeBicubic"             :  4   ; Bicubic interpolation. Don't use to shirnk past 25% of original size.
                                    ,"InterpolationModeNearestNeighbor"     :  5   ; nearest-neighbor interpolation.
                                    ,"InterpolationModeHighQualityBilinear" :  6   ; high-quality, bilinear interpolation.
                                    ,"InterpolationModeHighQualityBicubic"  :  7 } ; high-quality, bicubic interpolation.
        
        ; Specify the location of custom metadata in an image file.
        Static ItemDataPosition := {"ItemDataPositionAfterHeader"  : 0x0   ; Custom metadata is stored after the file header. Valid for JPEG, PNG, and GIF.
                                   ,"ItemDataPositionAfterPalette" : 0x1   ; Custom metadata is stored after the palette. Valid for PNG.
                                   ,"ItemDataPositionAfterBits"    : 0x2 } ; Custom metadata is stored after the pixel data. Valid for GIF and PNG.
        
        ; Specifies the direction in which the change of color occurs for a linear gradient brush.
        Static LinearGradientMode := {"LinearGradientModeHorizontal"       : 0   ; Color to change in a horizontal direction from the left of the display to the right of the display.
                                     ,"LinearGradientModeVertical"         : 1   ; Color to change in a vertical direction from the top of the display to the bottom of the display.
                                     ,"LinearGradientModeForwardDiagonal"  : 2   ; Color to change in a forward diagonal direction from the upper-left corner to the lower-right corner of the display.
                                     ,"LinearGradientModeBackwardDiagonal" : 3 } ; Color to change in a backward diagonal direction from the upper-right corner to the lower-left corner of the display.
        
        ; Specifies the type of graphic shape to use on the end of a line drawn with a Windows GDI+ pen.
        Static LineCap := {"LineCapFlat"          : 0x0    ; Line ends at the last point. The end is squared off.
                          ,"LineCapSquare"        : 0x1    ; Square cap. The center of the square is the last point in the line.
                          ,"LineCapRound"         : 0x2    ; Circular cap. The center of the circle is the last point in the line.
                          ,"LineCapTriangle"      : 0x3    ; Triangular cap. The base of the triangle is the last point in the line.
                          ,"LineCapNoAnchor"      : 0x10   ; Line ends are not anchored.
                          ,"LineCapSquareAnchor"  : 0x11   ; Line ends are anchored with a square.
                          ,"LineCapRoundAnchor"   : 0x12   ; Line ends are anchored with a circle.
                          ,"LineCapDiamondAnchor" : 0x13   ; Line ends are anchored with a diamond.
                          ,"LineCapArrowAnchor"   : 0x14   ; Line ends are anchored with arrowheads.
                          ,"LineCapCustom"        : 0xFF   ; Line ends are made from a CustomLineCap.
                          ,"LineCapAnchorMask"    : 0xF0 } ; Undefined.
        
        ; Specifies how to join two lines that are drawn by the same pen and whose ends meet. 
        Static LineJoin := {"LineJoinMiter"        : 0   ; Mitered join. This produces a sharp corner or a clipped corner, depending on whether the length of the miter exceeds the miter limit.
                           ,"LineJoinBevel"        : 1   ; Beveled join. This produces a diagonal corner.
                           ,"LineJoinRound"        : 2   ; Circular join. This produces a smooth, circular arc between the lines.
                           ,"LineJoinMiterClipped" : 3 } ; Mitered join. This produces a sharp corner or a beveled corner, depending on whether the length of the miter exceeds the miter limit.
        
        ; Specifies the order of multiplication when a new matrix is multiplied by an existing matrix.
        Static MatrixOrder := {"MatrixOrderPrepend" : 0   ; The new matrix is on the left and the existing matrix is on the right.
                              ,"MatrixOrderAppend"  : 1 } ; The existing matrix is on the left and the new matrix is on the right.
        
        ; Specifies the unit of measure for a metafile frame rectangle.
        Static MetafileFrameUnit := {"MetafileFrameUnitPixel"      : 2   ; Unit is 1 pixel.
                                    ,"MetafileFrameUnitPoint"      : 3   ; Unit is 1 pixel.
                                    ,"MetafileFrameUnitInch"       : 4   ; Unit is 1 pixel.
                                    ,"MetafileFrameUnitDocument"   : 5   ; Unit is 1/300 inch.
                                    ,"MetafileFrameUnitMillimeter" : 6   ; Unit is 1 pixel.
                                    ,"MetafileFrameUnitGdi"        : 7 } ; Unit is 0.01 millimeter.
        
        ; Specifies types of metafiles.
        Static MetafileType := {"MetafileTypeInvalid"      : 0   ; metafile format that is not recognized in GDI+.
                               ,"MetafileTypeWmf"          : 1   ; WMF file. Such a file contains only GDI records.
                               ,"MetafileTypeWmfPlaceable" : 2   ; WMF file that has a placeable metafile header in front of it.
                               ,"MetafileTypeEmf"          : 3   ; EMF file. Such a file contains only GDI records.
                               ,"MetafileTypeEmfPlusOnly"  : 4   ; EMF+ file. Such a file contains only GDI+ records and must be displayed by using GDI+.
                               ,"MetafileTypeEmfPlusDual"  : 5 } ; EMF+ Dual file. Such a file contains GDI+ records along with alternative GDI records and can be displayed by using either GDI or GDI+.
        
        ; Indicates the object type value of an EMF+ record.
        Static ObjectType := {"ObjectTypeInvalid"         : 0    ; Is invalid.
                             ,"ObjectTypeBrush"           : 1    ; Is a brush.
                             ,"ObjectTypePen"             : 2    ; Is a pen.
                             ,"ObjectTypePath"            : 3    ; Is a path.
                             ,"ObjectTypeRegion"          : 4    ; Is a region.
                             ,"ObjectTypeImage"           : 5    ; Is an image.
                             ,"ObjectTypeFont"            : 6    ; Is a font.
                             ,"ObjectTypeStringFormat"    : 7    ; Is a string format.
                             ,"ObjectTypeImageAttributes" : 8    ; Is an image attribute.
                             ,"ObjectTypeCustomLineCap"   : 9    ; Is a custom line cap.
                             ,"ObjectTypeGraphics"        : 10   ; Is graphics.
                             ,"ObjectTypeMax"             : 10   ; Maximum enumeration value. Currently, ObjectTypeGraphics.
                             ,"ObjectTypeMin"             : 1  } ; Minimum enumeration value. Currently, ObjectTypeBrush.
        
        ; Indicates attributes of the color data in a palette.
        Static PaletteFlags := {"PaletteFlagsHasAlpha"  : 0   ; One or more of the palette entries contains alpha (transparency) information.
                               ,"PaletteFlagsGrayScale" : 1   ; Palette contains only grayscale entries.
                               ,"PaletteFlagsHalftone"  : 2 } ; Palette is the Windows halftone palette.
        
        ; The members of the enumeration identify several standard color palette formats.
        Static PaletteType := {"PaletteTypeCustom"           : 0   ; Arbitrary custom palette provided by the caller.
                              ,"PaletteTypeOptimal"          : 1   ; Palette of colors that are optimal for a particular bitmap.
                              ,"PaletteTypeFixedBW"          : 2   ; Palette that has two colors.
                              ,"PaletteTypeFixedHalftone8"   : 3   ; Palette based on two intensities each (off or full) for the red, green, and blue channels.
                              ,"PaletteTypeFixedHalftone27"  : 4   ; Palette based on three intensities each for the red, green, and blue channels.
                              ,"PaletteTypeFixedHalftone64"  : 5   ; Palette based on four intensities each for the red, green, and blue channels.
                              ,"PaletteTypeFixedHalftone125" : 6   ; Palette based on five intensities each for the red, green, and blue channels.
                              ,"PaletteTypeFixedHalftone216" : 7   ; Palette based on six intensities each for the red, green, and blue channels.
                              ,"PaletteTypeFixedHalftone252" : 8   ; Palette based on 6 intensities of red, 7 intensities of green, and 6 intensities of blue.
                              ,"PaletteTypeFixedHalftone256" : 9 } ; Palette based on 8 intensities of red, 8 intensities of green, and 4 intensities of blue.
        
        ; Indicates point types and flags for the data points in a path.
        Static PathPointType := {"PathPointTypeStart"        : 0x00   ; The point is the start of a figure.
                                ,"PathPointTypeLine"         : 0x01   ; The point is one of the two endpoints of a line.
                                ,"PathPointTypeBezier"       : 0x03   ; The point is an endpoint or control point of a cubic Bézier spline.
                                ,"PathPointTypePathTypeMask" : 0x07   ; Masks all bits except for the three low-order bits, which indicate the point type.
                                ,"PathPointTypeDashMode"     : 0x10   ; Not used.
                                ,"PathPointTypePathMarker"   : 0x20   ; The point is a marker.
                                ,"PathPointTypeCloseSubpath" : 0x80   ; The point is the last point in a closed subpath (figure).
                                ,"PathPointTypeBezier3"      : 0x03 } ; The point is an endpoint or control point of a cubic Bézier spline.
        
        ; Specifies the alignment of a pen relative to the stroke that is being drawn.
        Static PenAlignment := {"PenAlignmentCenter" : 0   ; Pen is aligned on the center of the line that is drawn.
                               ,"PenAlignmentInset"  : 1 } ; If drawing a polygon, the pen is aligned on the inside edge of the polygon.
        
        ; Indicates the type of pattern, texture, or gradient that a pen draws.
        Static PenType := {"PenTypeSolidColor"     :  0   ; Pen draws with a solid color.
                          ,"PenTypeHatchFill"      :  1   ; Pen draws with a hatch pattern that is specified by a HatchBrush object.
                          ,"PenTypeTextureFill"    :  2   ; Pen draws with a texture that is specified by a TextureBrush object.
                          ,"PenTypePathGradient"   :  3   ; Pen draws with a color gradient that is specified by a PathGradientBrush object.
                          ,"PenTypeLinearGradient" :  4   ; Pen draws with a color gradient that is specified by a LinearGradientBrush object.
                          ,"PenTypeUnknown"        : -1 } ; Pen type is unknown.
        
        ; Specifies the pixel offset mode of a Graphics object.
        Static PixelOffsetMode := {"PixelOffsetModeInvalid"     : -1   ; Used internally.
                                  ,"PixelOffsetModeDefault"     :  0   ; Equivalent to PixelOffsetModeNone.
                                  ,"PixelOffsetModeHighSpeed"   :  1   ; Equivalent to PixelOffsetModeNone.
                                  ,"PixelOffsetModeHighQuality" :  2   ; Equivalent to PixelOffsetModeHalf.
                                  ,"PixelOffsetModeNone"        :  3   ; Indicates that pixel centers have integer coordinates.
                                  ,"PixelOffsetModeHalf"        :  4 } ; Indicates that pixel centers have coordinates that are half way between integer values.
        
        ; Specifies the direction of an image's rotation and the axis used to flip the image.
        Static RotateFlipType := {"RotateNoneFlipNone" : 0   ; No rotation and no flipping.
                                 ,"Rotate90FlipNone"   : 1   ; 90-degree rotation without flipping.
                                 ,"Rotate180FlipNone"  : 2   ; 180-degree rotation without flipping.
                                 ,"Rotate270FlipNone"  : 3   ; 270-degree rotation without flipping.
                                 ,"RotateNoneFlipX"    : 4   ; No rotation and a horizontal flip.
                                 ,"Rotate90FlipX"      : 5   ; 90-degree rotation followed by a horizontal flip.
                                 ,"Rotate180FlipX"     : 6   ; 180-degree rotation followed by a horizontal flip.
                                 ,"Rotate270FlipX"     : 7   ; 270-degree rotation followed by a horizontal flip.
                                 ,"RotateNoneFlipY"    : 6   ; No rotation and a vertical flip.
                                 ,"Rotate90FlipY"      : 7   ; 90-degree rotation followed by a vertical flip.
                                 ,"Rotate180FlipY"     : 4   ; 180-degree rotation followed by a vertical flip.
                                 ,"Rotate270FlipY"     : 5   ; 270-degree rotation followed by a vertical flip.
                                 ,"RotateNoneFlipXY"   : 2   ; No rotation, a horizontal flip, and then a vertical flip.
                                 ,"Rotate90FlipXY"     : 3   ; 90-degree rotation followed by a horizontal flip and then a vertical flip.
                                 ,"Rotate180FlipXY"    : 0   ; 180-degree rotation followed by a horizontal flip and then a vertical flip.
                                 ,"Rotate270FlipXY"    : 1 } ; 270-degree rotation followed by a horizontal flip and then a vertical flip.
        
        ; Specifies the type of smoothing (antialiasing) that is applied to lines and curves.
        Static SmoothingMode := {"SmoothingModeInvalid"      : -1   ; Reserved.
                                ,"SmoothingModeDefault"      :  0   ; Smoothing is not applied.
                                ,"SmoothingModeHighSpeed"    :  1   ; Smoothing is not applied.
                                ,"SmoothingModeHighQuality"  :  2   ; Smoothing is applied using an 8 X 4 box filter.
                                ,"SmoothingModeNone"         :  3   ; Smoothing is not applied.
                                ,"SmoothingModeAntiAlias"    :  4   ; Smoothing is applied using an 8 X 4 box filter.
                                ,"SmoothingModeAntiAlias8x4" :  4   ; Smoothing is applied using an 8 X 4 box filter.
                                ,"SmoothingModeAntiAlias8x8" :  5 } ; Smoothing is applied using an 8 X 8 box filter.
        
        ; Indicates the result of a Windows GDI+ method call.
        Static Status := {"Ok"                        : 0    ; Method call was successful.
                         ,"GenericError"              : 1    ; There was an error on the method call which is not defined elsewhere in this enumeration.
                         ,"InvalidParameter"          : 2    ; One of the arguments passed to the method was not valid.
                         ,"OutOfMemory"               : 3    ; Operating system is out of memory and could not allocate memory to process the method call. For an explanation of how constructors use the OutOfMemory status, see the Remarks section at the end of this topic.
                         ,"ObjectBusy"                : 4    ; One of the arguments specified in the API call is already in use in another thread.
                         ,"InsufficientBuffer"        : 5    ; A buffer specified as an argument in the API call is not large enough to hold the data to be received.
                         ,"NotImplemented"            : 6    ; The method is not implemented.
                         ,"Win32Error"                : 7    ; The method generated a Win32 error.
                         ,"WrongState"                : 8    ; The object is in an invalid state to satisfy the API call.
                         ,"Aborted"                   : 9    ; The method was aborted.
                         ,"FileNotFound"              : 10   ; The specified image file or metafile cannot be found.
                         ,"ValueOverflow"             : 11   ; The method performed an arithmetic operation that produced a numeric overflow.
                         ,"AccessDenied"              : 12   ; A write operation is not allowed on the specified file.
                         ,"UnknownImageFormat"        : 13   ; The specified image file format is not known.
                         ,"FontFamilyNotFound"        : 14   ; The specified font family is incorrect or the font family is not installed and cannot be found.
                         ,"FontStyleNotFound"         : 15   ; The specified style is not available for the specified font family.
                         ,"NotTrueTypeFont"           : 16   ; The font retrieved from an HDC or LOGFONT is not a TrueType font and cannot be used with GDI+.
                         ,"UnsupportedGdiplusVersion" : 17   ; The version of GDI+ that is installed on the system is incompatible with the version with which the application was compiled.
                         ,"GdiplusNotInitialized"     : 18   ; The GDI+API is not in an initialized state. (This should never happen with this AHK library as the object initialize GDIPlus for you.)
                         ,"PropertyNotFound"          : 19   ; The specified property does not exist in the image.
                         ,"PropertyNotSupported"      : 20   ; The specified property is not supported by the format of the image and, therefore, cannot be set.
                         ,"ProfileNotFound"           : 21 } ; The color profile required to save an image in CMYK format was not found.
        
        ; Specifies how a string is aligned in reference to the bounding rectangle.
        Static StringAlignment := {"StringAlignmentNear"   : 0   ; Alignment is towards the origin of the bounding rectangle.
                                  ,"StringAlignmentCenter" : 1   ; Alignment is centered between origin and extent (width) of the formatting rectangle.
                                  ,"StringAlignmentFar"    : 2 } ; Alignment is to the far extent (right side) of the formatting rectangle.
        
        ; Specifies how to substitute digits in a string according to a user's locale or language.
        Static StringDigitSubstitute := {"StringDigitSubstituteUser"        : 0   ; User-defined substitution scheme.
                                        ,"StringDigitSubstituteNone"        : 1   ; Disable substitutions.
                                        ,"StringDigitSubstituteNational"    : 2   ; Substitution digits that correspond with the official national language of the user's locale.
                                        ,"StringDigitSubstituteTraditional" : 3 } ; Substitution digits that correspond with the user's native script or language
        
        ; Specifies text layout information (such as orientation and clipping) and display manipulations
        Static StringFormatFlags := {"StringFormatFlagsDirectionRightToLeft"  : 0x1          ; Reading order is right to left.
                                    ,"StringFormatFlagsDirectionVertical"     : 0x2          ; Individual lines of text are drawn vertically on the display device.
                                    ,"StringFormatFlagsNoFitBlackBox"         : 0x4          ; Parts of characters are allowed to overhang the string's layout rectangle.
                                    ,"StringFormatFlagsDisplayFormatControl"  : 0x20         ; Unicode layout control characters are displayed with a representative character.
                                    ,"StringFormatFlagsNoFontFallback"        : 0x400        ; Alternate font is used for characters that are not supported in the requested font.
                                    ,"StringFormatFlagsMeasureTrailingSpaces" : 0x800        ; Space at the end of each line is included in a string measurement.
                                    ,"StringFormatFlagsNoWrap"                : 0x1000       ; Wrapping of text to the next line is disabled.
                                    ,"StringFormatFlagsLineLimit"             : 0x2000       ; Only entire lines are laid out in the layout rectangle.
                                    ,"StringFormatFlagsNoClip"                : 0x4000       ; Only entire lines are laid out in the layout rectangle.
                                    ,"StringFormatFlagsBypassGDI"             : 0x80000000 } ; Undefined.
        
        ; Specifies how to trim characters from a string so that the string fits into a layout rectangle.
        Static StringTrimming := {"StringTrimmingNone"              : 0   ; No trimming is done.
                                 ,"StringTrimmingCharacter"         : 1   ; String is broken at the boundary of the last character that is inside the layout rectangle.
                                 ,"StringTrimmingWord"              : 2   ; String is broken at the boundary of the last word that is inside the layout rectangle.
                                 ,"StringTrimmingEllipsisCharacter" : 3   ; String is broken at the boundary of the last character that is inside the layout rectangle and an ellipsis (...) is inserted after the character.
                                 ,"StringTrimmingEllipsisWord"      : 4   ; String is broken at the boundary of the last word that is inside the layout rectangle and an ellipsis (...) is inserted after the word.
                                 ,"StringTrimmingEllipsisPath"      : 5 } ; Center is removed from the string and replaced by an ellipsis. 
        
        ; Specifies the process used to render text. This affects text quality.
        Static TextRenderingHint := {"TextRenderingHintSystemDefault"            : 0   ; Character is drawn using the currently selected system font smoothing mode (also called a rendering hint).
                                    ,"TextRenderingHintSingleBitPerPixelGridFit" : 1   ; Character is drawn using its glyph bitmap and hinting to improve character appearance on stems and curvature.
                                    ,"TextRenderingHintSingleBitPerPixel"        : 2   ; Character is drawn using its glyph bitmap and no hinting. Better performance at cost of quality.
                                    ,"TextRenderingHintAntiAliasGridFit"         : 3   ; Character is drawn using its antialiased glyph bitmap and hinting. Better quality at cost of performance.
                                    ,"TextRenderingHintAntiAlias"                : 4   ; Character is drawn using its antialiased glyph bitmap and no hinting.
                                    ,"TextRenderingHintClearTypeGridFit"         : 5 } ; Character is drawn using its glyph ClearType bitmap and hinting.
        
        ; Specifies the unit of measure for a given data type.
        Static Unit := {"UnitWorld"      : 0   ; World coordinates, a nonphysical unit.
                       ,"UnitDisplay"    : 1   ; Display specific units.
                       ,"UnitPixel"      : 2   ; Unit is 1 pixel.
                       ,"UnitPoint"      : 3   ; Unit is 1 point or 1/72 inch.
                       ,"UnitInch"       : 4   ; Unit is 1 inch.
                       ,"UnitDocument"   : 5   ; Unit is 1/300 inch.
                       ,"UnitMillimeter" : 6   ; Unit is 1 millimeter.
                       ,"UnitAbsolute"   : 7 } ; Unit is memetic and of type easter egg.
        
        ; Specifies warp modes that can be used to transform images.
        Static WarpMode := {"WarpModePerspective" : 0   ; Perspective warp mode.
                           ,"WarpModeBilinear"    : 1 } ; Bilinear warp mode.
        
        ; Specifies how repeated copies of an image are used to tile an area.
        Static WrapMode := {"WrapModeTile"       : 0   ; Tiling without flipping.
                           ,"WrapModeTileFlipX"  : 1   ; Tiles are flipped horizontally as you move from one tile to the next in a row.
                           ,"WrapModeTileFlipY"  : 2   ; Tiles are flipped vertically as you move from one tile to the next in a column.
                           ,"WrapModeTileFlipXY" : 3   ; Tiles are flipped horizontally as you move along a row and flipped vertically as you move along a column.
                           ,"WrapModeClamp"      : 4 } ; No tiling takes place.
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
    ; A PointF object contains 2 float values representing x and y coords.                                              |
    ; Properties:                                                                                                       |
    ; .x                X coord (float)                                                                                 |
    ; .y                Y coord (float)                                                                                 |
    ; .structP          Pointer to PointF struct                                                                        |
    ;                                                                                                                   |
    ; Constructors:                                                                                                     |
    ; PointF()          Create a PointF object with x and y values of 0                                                 |
    ; PointF(f, f)      Create a PointF object with float x and float y values                                          |
    ; PointF(SizeF)     Create a PointF object with x equal to SizeF.width and y equal to SizeF.height                  |
    ; PointF(PointF)    Create a clone of the provided PointF struct                                                    |
    ;                                                                                                                   |
    ; Methods:                                                                                                          |
    ; .equals(PointF)   Returns true if native PointF values are equal to provided PointF values                        |
    ; .plus(PointF)     Returns a new PointF object containing the sum of  PointF objects > returns new PointF object   |
    ; .minus(PointF)    Subtracts the x and y PointF values from the native PointF object > returns a new PointF object |
    ;                                                                                                                   |
    ; Remarks           If working with only integers, use Point.                                                       |
    ;                   Int numbers are accepted by float methods and will be treated as float.                         |
    ;                   Point and Size are accepted but are converted to float.                                         |
    ;                   There is no way to use the + and - operators with PointFs. Use the plus() or minus() methods.   |
    ;___________________________________________________________________________________________________________________|
    ;===================================================================================================================.
    ; A Point object contains 2 integer properties representing x and y values.                                         |
    ; Properties:                                                                                                       |
    ; .x                X coord (integer)                                                                               |
    ; .y                Y coord (integer)                                                                               |
    ; .structP          Pointer to Point struct                                                                         |
    ;                                                                                                                   |
    ; Constructors:                                                                                                     |
    ; Point()           Create a Point object with x and y values of 0                                                  |
    ; Point(int1, int2) Create a Point object with int x and int y values                                               |
    ; Point(Size)       Create a Point object with x equal to size.width and y equal to size.height                     |
    ; Point(Point)      Create a clone of the provided Point struct                                                     |
    ;                                                                                                                   |
    ; Methods:                                                                                                          |
    ; .equals(Point)    Returns true if native Point values are equal to provided Point values                          |
    ; .plus(Point)      Returns a new Point object containing the sum of  Point objects > returns new Point object      |
    ; .minus(Point)     Subtracts the x and y Point values from the native Point object > returns a new Point object    |
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
        ; Point()
        ; Point(int, int)
        ; Point(SizeObj)
        ; Point(PointObj)
        __New(obj_x="U", y="U")
        {
            err := 0
            (this.is_int(obj_x) && this.is_int(y))     ? (this.x := obj_x       ,this.y := y)
                : (obj_x == "U" && y == "U")             ? (this.x := 0           ,this.y := 0)
                : (obj_x.type == "Point") && (y == "U") ? (this.x := obj_x.x     ,this.y := obj_x.y)
                : (obj_x.type == "Size") && (y == "U")  ? (this.x := obj_x.width ,this.y := obj_x.height)
                : err := 1
            
            (err)
                ? this.error_log(A_ThisFunc, "Failed to create Point struct."   ; If error, log it
                    , "No params, 2 ints, 1 size object, or 1 Point object"
                    , {obj_x:obj_x, y:y})
                : (this.SetCapacity("struct", 8)                                ; Else build Point
                    , this.structP := this.GetAddress("struct")
                    , NumPut(this.x, this.structP+0, 0, "Int")
                    , NumPut(this.y, this.structP+0, 4, "Int") )
        }
        
        ; For testing purposes > Shows contents of this object
        show(msg="")
        {
            MsgBox, % (msg = "" ? "" : msg "`n")
                . "type: " this.type    "`nstructP: " this.structP
                . "`nx: "  this.x       "`ny: "       this.y
                . "`nStructP x: " NumGet(this.structP+0, 0, "Int")
                . "`nStructP y: " NumGet(this.structP+0, 4, "Int")
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
        ;               This is a replacement for the GDIPlus +Operator (IE: Point1 + Point2)
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
        ;               Native Point is the minuend and provided point is the subtrahend
        ;               This is a replacement for the GDIPlus -Operator (IE: Point1 + Point2)
        minus(Point)
        {
            (Point.type == "Point") ? ""
                : this.error_log(A_ThisFunc, "This method requires a Point object be passed in as a parameter."
                    , "Must supply a Point object.", {providedObject: Point})
            Return new GDIP.Point(this.x - Point.x, this.y - Point.y)
        }
    }
    
    ;===================================================================================================================.
    ; A PointF object contains 2 float values representing x and y coords.                                              |
    ; Properties:                                                                                                       |
    ; .x                X coord (float)                                                                                 |
    ; .y                Y coord (float)                                                                                 |
    ; .structP          Pointer to PointF struct                                                                        |
    ;                                                                                                                   |
    ; Constructors:                                                                                                     |
    ; PointF()          Create a PointF object with x and y values of 0                                                 |
    ; PointF(f, f)      Create a PointF object with float x and float y values                                          |
    ; PointF(SizeF)     Create a PointF object with x equal to SizeF.width and y equal to SizeF.height                  |
    ; PointF(PointF)    Create a clone of the provided PointF struct                                                    |
    ;                                                                                                                   |
    ; Methods:                                                                                                          |
    ; .equals(PointF)   Returns true if native PointF values are equal to provided PointF values                        |
    ; .plus(PointF)     Returns a new PointF object containing the sum of  PointF objects > returns new PointF object   |
    ; .minus(PointF)    Subtracts the x and y PointF values from the native PointF object > returns a new PointF object |
    ;                                                                                                                   |
    ; Remarks           If working with only integers, use Point.                                                       |
    ;                   Int numbers are accepted by float methods and will be treated as float.                         |
    ;                   Point and Size are accepted but are converted to float.                                         |
    ;                   There is no way to use the + and - operators with PointFs. Use the plus() or minus() methods.   |
    ;___________________________________________________________________________________________________________________|
    Class PointF extends GDIP
    {
        type    := "PointF"
        x       := ""
        y       := ""
        struct  := ""
        structP := ""
        
        ; ## CONSTRUCTOR ##
        ; PointF()
        ; PointF(float, float)
        ; PointF(SizeFObj)
        ; PointF(PointFObj)
        __New(obj_x="U", y="U")
        {
            err := 0
            (this.is_num(obj_x) && this.is_num(y))      ? (this.x := obj_x       ,this.y := y)
                : (obj_x == "U" && y == "U")              ? (this.x := 0           ,this.y := 0)
                : (y == "U") && (obj_x.type == "PointF"
                    || obj_x.type == "Point")           ? (this.x := obj_x.x     ,this.y := obj_x.y)
                : (y == "U") && (obj_x.type == "SizeF"
                    || obj_x.type == "Size")            ? (this.x := obj_x.width ,this.y := obj_x.height)
                : err := 1
            
            (err)
                ? this.error_log(A_ThisFunc, "Failed to create PointF struct."  ; If error, log it
                    , "No params, 2 floats, SizeF object, or PointF object"
                    , {obj_x:obj_x, y:y})
                : (this.SetCapacity("struct", 8)                                ; Else build PointF
                    , this.structP := this.GetAddress("struct")
                    , NumPut(this.x, this.structP+0, 0, "Float")
                    , NumPut(this.y, this.structP+0, 4, "Float") )
        }
        
        ; For testing purposes > Shows contents of this object
        show(msg="")
        {
            MsgBox, % (msg = "" ? "" : msg "`n")
                . "type: " this.type    "`nstructP: " this.structP
                . "`nx: "  this.x       "`ny: "       this.y
                . "`nStructP x: " NumGet(this.structP+0, 0, "Float")
                . "`nStructP y: " NumGet(this.structP+0, 4, "Float")
            Return
        }
        
        ; ## METHODS ##
        
        ; Description   Determine if native and provided PointF objects have equal values
        ; PointF        PointF object to do equality check against native PointF object
        ; Return        1 = True, 0 = False
        equals(PointF)
        {
            (PointF.type == "PointF") ? ""
                : this.error_log(A_ThisFunc, "This method requires a PointF object be passed in as a parameter."
                    , "Must supply a PointF object.", {providedObject: PointF})
            Return (this.x = PointF.x) && (this.y = PointF.y) ? 1 : 0
        }
        
        ; Description   Adds the x and y values of the native and provided PointF objects
        ; PointF        PointF object to add to the native PointF object
        ; Return        New PointF object containing the added x and y values
        ; Remark        The x values and y values are added together, not x+y
        ;               This is a replacement for the PointF +Operator
        plus(PointF)
        {
            (PointF.type == "PointF") ? ""
                : this.error_log(A_ThisFunc, "This method requires a PointF object be passed in as a parameter."
                    , "Must supply a PointF object.", {providedObject: PointF})
            Return new GDIP.PointF(this.x + PointF.x, this.y + PointF.y)
        }
        
        ; Description   Subtracts the x and y PointF values from the native PointF object
        ; PointF        PointF object to subtract from the native PointF object
        ; Return        A new PointF object containing the difference of the x and y values
        ; Remark        The x values and y values are subtracted, not x-y
        ;               Native PointF is the minuend and provided PointF is the subtrahend
        ;               This replaces the PointF -Operator
        minus(PointF)
        {
            (PointF.type == "PointF") ? ""
                : this.error_log(A_ThisFunc, "This method requires a PointF object be passed in as a parameter."
                    , "Must supply a PointF object.", {providedObject: PointF})
            Return new GDIP.PointF(this.x - PointF.x, this.y - PointF.y)
        }
    }
    
    ;===================================================================================================================.
    ; A Size object contains 2 int values representing width and height.                                                |
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
    ; .empty()          Returns true if the native width or height is 0 or less                                         |
    ; .equals(Size)     Returns true if the native Size is equal to the supplied Size                                   |
    ; .plus(Size)       Returns a new Size object containing the sum of the native Size and the provided Size           |
    ; .minus(Size)      Returns a new Size object containing the difference of the native Size and the provided Size    |
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
        ; Size()
        ; Size(int, int)
        ; Size(Size)
        __New(obj_width="U", height="U")
        {
            err := 0
            (this.is_int(obj_width) && this.is_int(height))   ? (this.width  := obj_width ,this.height := height)
                : (obj_width == "U" && height == "U")           ? (this.width  := 0         ,this.height := 0)
                : (obj_width.type = "Size") && (height == "U") ? (this.width  := obj_width.width
                                                                ,this.height := obj_width.height)
                : err := 1
            
            (err)
                ? this.error_log(A_ThisFunc, "Failed to create Size struct."    ; If error, log it
                    , "No params, 2 ints, 1 Size object, or 1 point object"
                    , {obj_or_width:obj_width, height:height})
                : (this.SetCapacity("struct", 8)                                ; Else build Size struct
                    ,this.structP := this.GetAddress("struct")
                    ,NumPut(this.width , this.structP+0, 0, "Int")
                    ,NumPut(this.height, this.structP+0, 4, "Int") )
        }
        
        ; For testing purposes > Shows contents of this object
        show(msg="")
        {
            MsgBox, % (msg = "" ? "" : msg "`n")
                    . "type: "    this.type     "`nstructP: " this.structP
                    . "`nwidth: " this.width    "`nheight: "  this.height
                    . "`nStructP width: "  NumGet(this.structP+0, 0, "Int")
                    . "`nStructP height: " NumGet(this.structP+0, 4, "Int")
            Return
        }
        
        ; ## METHODS ##
        
        ; Description   Determine if Size object width and height are set to 0
        ; Return        1 = True, 0 = False
        Empty()
        {
            Return (this.width = 0 || this.height = 0) ? 1 : 0
        }
        
        ; Description   Determine if native Size and provided Size have equal width/height values
        ; Size          Size object to do equality check against native Size object
        ; Return        1 = True, 0 = False
        Equals(Size)
        {
            (size.type == "Size") ? ""
                : this.error_log(A_ThisFunc, "This method requires a Size object be passed in as a parameter."
                    , "Must supply a Size object.", {Size: Size})
            Return (this.width = Size.width && this.height = Size.height) ? 1 : 0
        }
        
        ; Description   Add width and height values of native and provided Size objects
        ; Size          Size object to add to the native Size object
        ; Return        New Size object containing the added width and height values
        ; Remark        This is a replacement for the GDIPlus +Operator (IE: Size1 + Size2)
        plus(Size)
        {
            (Size.type == "Size") ? ""
                : this.error_log(A_ThisFunc, "This method requires a Size object be passed in as a parameter."
                    , "Must supply a Size object.", {Size: Size})
            Return new GDIP.Size((this.width + Size.width), (this.height + Size.height))
        }
        
        ; Description   Subtracts the x and y Size values from the native Size object
        ; Size          Size object to subtract from the native Size object
        ; Return        A new Size object containing the difference of the width and height values
        ; Remark        The provided Size values are always subtracted from the native Size values
        ;               This is a replacement for the GDIPlus -Operator (IE: Size1 - Size2)
        minus(Size)
        {
            (Size.type == "Size") ? ""
                : this.error_log(A_ThisFunc, "This method requires a Size object be passed in as a parameter."
                    , "Must supply a Size object.", {Size: Size})
            Return new GDIP.Size((this.width - Size.width), (this.height - Size.height))
        }
    }
    
    ;===================================================================================================================.
    ; A SizeF object contains 2 float values representing width and height.                                             |
    ; Properties:                                                                                                       |
    ; .width            width (float)                                                                                   |
    ; .height           height (float)                                                                                  |
    ; .structP          Pointer to SizeF struct (width > height)                                                        |
    ;                                                                                                                   |
    ; Constructors:                                                                                                     |
    ; SizeF()           Create a SizeF object with width and height values of 0                                         |
    ; SizeF(f1, f2)     Create a SizeF object with float width and float height                                         |
    ; SizeF(SizeF)      Create a clone of the provided SizeF object                                                     |
    ;                                                                                                                   |
    ; Methods:                                                                                                          |
    ; .empty()          Returns true if the native width or height is 0 or less                                         |
    ; .equals(SizeF)    Returns true if the native SizeF is equal to the supplied SizeF                                 |
    ; .plus(SizeF)      Returns a new SizeF object containing the sum of the native SizeF and the provided SizeF        |
    ; .minus(SizeF)     Returns a new SizeF object containing the difference of the native SizeF and the provided SizeF |
    ;                                                                                                                   |
    ; Remarks           If working with only integers, use Size.                                                        |
    ;                   Int numbers are accepted by float methods and will be treated as float.                         |
    ;                   Point and Size are accepted but are converted to float.                                         |
    ;                   There is no way to use the + and - operators with SizeF. Use the plus() or minus() methods.     |
    ;___________________________________________________________________________________________________________________|
    Class SizeF extends GDIP
    {
        type    := "SizeF"
        width   := ""
        height  := ""
        struct  := ""
        structP := ""
        
        ; ## CONSTRUCTOR ##
        ; SizeF()
        ; SizeF(float, float)
        ; SizeF(SizeF)
        __New(obj_width="U", height="U")
        {
            err := 0
            (this.is_num(obj_width) && this.is_num(height))   ? (this.width  := obj_width ,this.height := height)
                : (obj_width == "U" && height == "U")           ? (this.width  := 0         ,this.height := 0)
                : (obj_width.type = "SizeF") && (height == "U") ? (this.width  := obj_width.width
                                                                ,this.height := obj_width.height)
                : err := 1
            
            (err)
                ? this.error_log(A_ThisFunc, "Failed to create SizeF struct."    ; If error, log it
                    , "No params, 2 floats, 1 SizeF object, or 1 Point object"
                    , {obj_or_width:obj_width, height:height})
                : (this.SetCapacity("struct", 8)                                ; Else build SizeF struct
                    ,this.structP := this.GetAddress("struct")
                    ,NumPut(this.width , this.structP+0, 0, "Float")
                    ,NumPut(this.height, this.structP+0, 4, "Float") )
        }
        
        ; For testing purposes > Shows contents of this object
        show(msg="")
        {
            MsgBox, % (msg = "" ? "" : msg "`n")
                    . "type: "    this.type     "`nstructP: " this.structP
                    . "`nwidth: " this.width    "`nheight: "  this.height
                    . "`nStructP width: "  NumGet(this.structP+0, 0, "Float")
                    . "`nStructP height: " NumGet(this.structP+0, 4, "Float")
            Return
        }
        
        ; ## METHODS ##
        
        ; Description   Determine if SizeF object width and height are set to 0
        ; Return        1 = True, 0 = False
        Empty()
        {
            Return (this.width = 0 || this.height = 0) ? 1 : 0
        }
        
        ; Description   Determine if native SizeF and provided SizeF have equal width/height values
        ; SizeF         SizeF object to do equality check against native SizeF object
        ; Return        1 = True, 0 = False
        Equals(SizeF)
        {
            (SizeF.type == "SizeF") ? ""
                : this.error_log(A_ThisFunc, "This method requires a SizeF object be passed in as a parameter."
                    , "Must supply a SizeF object.", {SizeF: SizeF})
            Return (this.width = SizeF.width && this.height = SizeF.height) ? 1 : 0
        }
        
        ; Description   Add width and height values of native and provided SizeF objects
        ; SizeF         SizeF object to add to the native SizeF object
        ; Return        New SizeF object containing the added width and height values
        ; Remark        This is a replacement for the GDIPlus +Operator (IE: SizeF1 + SizeF2)
        plus(SizeF)
        {
            (SizeF.type == "SizeF") ? ""
                : this.error_log(A_ThisFunc, "This method requires a SizeF object be passed in as a parameter."
                    , "Must supply a SizeF object.", {SizeF: SizeF})
            Return new GDIP.SizeF((this.width + SizeF.width), (this.height + SizeF.height))
        }
        
        ; Description   Subtracts the x and y SizeF values from the native SizeF object
        ; SizeF         SizeF object to subtract from the native SizeF object
        ; Return        A new SizeF object containing the difference of the width and height values
        ; Remark        The provided SizeF values are always subtracted from the native SizeF values
        ;               This is a replacement for the GDIPlus -Operator (IE: SizeF1 - SizeF2)
        minus(SizeF)
        {
            (SizeF.type == "SizeF") ? ""
                : this.error_log(A_ThisFunc, "This method requires a SizeF object be passed in as a parameter."
                    , "Must supply a SizeF object.", {SizeF: SizeF})
            Return new GDIP.SizeF((this.width - SizeF.width), (this.height - SizeF.height))
        }
    }
    
    ;===================================================================================================================.
    ; A RectF object contains 4 integer values representing x, y, width, and height.                                    |
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
    ; Rect(i1, i2, i3, i4) Create a Rect object with int x, y, width, and height                                        |
    ; Rect(Point, Size) Create a Rect object using a Point and Size object                                              |
    ;                                                                                                                   |
    ; Methods:                                                                                                          |
    ; Clone()           Returns a new Rect object with the same values as the native Rect object.                       |
    ; Contains(x, y)    Returns true if int x and int y fall within the native Rect                                     |
    ; Contains(Point)   Returns true if Point.x and Point.y falls within native Rect                                    |
    ; Contains(Rect)    Returns true if provided Rect falls within native Rect                                          |
    ; Equals(Rect)      Returns true if supplied and native Rect have equal x, y, width, and height values              |
    ; GetBottom()       Returns bottom y coordinate of this Rect                                                        |
    ; GetBounds(Rect)   Copies native Rect values to the provide Rect object > no return                                |
    ; GetLeft()         Returns left x coordinate of this Rect                                                          |
    ; GetLocation(Point) Copies native x and y value from Rect to the provided Point object > no return                 |
    ; GetRight()        Returns right x coordinate of this Rect                                                         |
    ; GetSize(Size)     Copies native width and height from Rect to the provided Size object > no return                |
    ; GetTop()          Returns top y coordinate of this Rect                                                           |
    ; Inflate(dx, dy)   Expands native Rect by int dx wide on both sides and int dy on top and bottom > no return       |
    ; Inflate(Point)    Expands native Rect by point.x on both sides and point.y on top and bottom > no return          |
    ; Inflate(Size)     Expands native Rect by size.width on both sides and size.height on th top and bottom > no return|
    ; Intersect(Rect)   Get values of Rect created by intersecting native with  provided rect then assign to native rect|
    ; Intersect(Rect1   Get values of Rect created by intersecting Rect1 and Rect2 then assign to native rect           |
    ;   ,Rect2, RectOut)                                                                                                |
    ; IntersectsWith(Rect) Return true if provided Rect intersects native Rect                                          |
    ; IsEmptyArea()     Return true if width or height of Rect is 0 or less                                             |
    ; Offset(Point)     Reposition Rect by moving x Point.x and y by Point.y                                            |
    ; Offset(dx, dy)    Reposition Rect by moving x by int dx and y by int dy                                           |
    ; Union(RectOut     Find Rect size to unionize Rect1 and Rect2 then assign them to RectOut                          |
    ;   , Rect1, Rect2)                                                                                                 |
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
        ; Rect()
        ; Rect(int, int, int, int)
        ; Rect(Point, Size)
        __New(obj_x="U", obj_y="U", width="U", height="U")
        {
            err := 0
            (this.is_int(obj_x) && this.is_int(obj_y) && this.is_int(width) && this.is_int(height)) ; All int
                ? (this.left  := this.x := obj_x     ,this.top    := this.y := obj_y
                  ,this.width := width               ,this.height := height
                  ,this.right := obj_x + width       ,this.bottom := obj_y + height )
            : (obj_x == "U" && obj_y == "U" && width == "U" && height == "U")                           ; All blank
                ? (this.left  := this.x := 0         ,this.top    := this.y := 0
                  ,this.width := 0                   ,this.height := 0
                  ,this.right := 0                   ,this.bottom := 0 )
            : (obj_x.type == "Point" && obj_y.type == "Size" && width == "U" && height == "U")        ; Point + Size
                ? (this.left  := this.x := obj_x.x   ,this.top    := this.y := obj_x.y 
                  ,this.width := obj_y.width         ,this.height := obj_y.height
                  ,this.right := this.x + this.width ,this.bottom := this.y + this.height )
            : err := 1                                                                              ; Error
            
            (err)
                ? this.error_log(A_ThisFunc, "Failed to create Rect struct."                        ; If error, log it
                    , "No params, 4 ints, 1 size object and 1 point object"
                    , {obj_x:obj_x, obj_y:obj_y, width:width, height:height})
                : (this.SetCapacity("struct", 16)                                                   ; Else build Rect
                    ,this.structP := this.GetAddress("struct")
                    ,this._update_struct() )
        }
        
        _update_struct()
        {
             NumPut(this.x     , this.structP+0,  0, "Int")
            ,NumPut(this.y     , this.structP+0,  4, "Int")
            ,NumPut(this.width , this.structP+0,  8, "Int")
            ,NumPut(this.height, this.structP+0, 12, "Int")
        }
        
        ; For testing purposes > Shows contents of this object
        show(msg="")
        {
            MsgBox, % (msg = "" ? "" : msg "`n")
                . "type: "             this.type                "`nstructP: "   this.structP
                . "`nx: "              this.x                   "`ny: "         this.y
                . "`nwidth: "          this.width               "`nheight: "    this.height
                . "`nleft: "           this.left                "`nright: "     this.right
                . "`ntop: "            this.top                 "`nbottom: "    this.bottom
                . "`nStructP x: "      NumGet(this.structP+0,  0, "Int")
                . "`nStructP y: "      NumGet(this.structP+0,  4, "Int")
                . "`nStructP width: "  NumGet(this.structP+0,  8, "Int")
                . "`nStructP height: " NumGet(this.structP+0, 12, "Int")
            Return
        }
        
        ; ## METHODS ##
        ; Description       Creates a new Rect object and initializes it with the contents of this Rect object.
        Clone()
        {
            Return new gdip.rect(this.x, this.y, this.width, this.height)
        }
        
        ; This is an overloaded method:
        ; Contains(x, y)    Determine if point int x and int y falls within native Rect
        ; Contains(Point)   Determine if Point falls within native Rect
        ; Contains(Rect)    Determine if provided Rect falls within native Rect
        ; Return            1 = True, 0 = False
        ; Remark            Contains include lines falling on 
        Contains(obj_x, y="U")
        {
            Return (this.is_int(obj_x) && this.is_int(y) ; check x y coords
                    && (obj_x >= this.left)     && (obj_x < this.right)
                    && (    y >= this.top)      && (    y < this.bottom)         ) ? 1
                : (obj_x.type == "Point" && y == "U"       ; check Point.x Point.y coords
                    && (obj_x.x >= this.left)   && (obj_x.x < this.right)
                    && (obj_x.y >= this.top)    && (obj_x.y < this.bottom)       ) ? 1
                : (obj_x.type == "Rect" && y == "U"        ; check if Rect is inside rect
                    && (this.x <= obj_x.x)      && (this.right  <= obj_x.right)
                    && (this.y <= obj_x.y)      && (this.bottom <= obj_x.bottom) ) ? 1
                : 0                                      ; does not contain
        }
        
        ; Description       Determine if the supplied and native have equal x, y, width, and height values
        ; Rect              Rect struct to compare
        ; Return            1 = True, 0 = False
        Equals(Rect)
        {
            Return (Rect.x     = this.x     && Rect.y      = this.y
                &&  Rect.width = this.width && Rect.height = this.height ) ? 1 : 0
        }
        
        ; Description       Retrieves coordinate for the bottom edge of this Rect
        GetBottom()
        {
            Return this.bottom
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
            Return this.left
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
            Return this.right
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
            Return this.top
        }
        
        ; Overloaded method:
        ; Inflate(dx, dy)   Expand left & right edges by int dx and top & bottom edges by int dy
        ; Inflate(Point)    Expand left & right edges by Point.x and the top & bottom edges by Point.y
        ; Inflate(Size)     Expand left & right edges by Size.width and the top & bottom edges by Size.height
        ; Return            No return value
        ; Remark            A rectangle should not be able to have a negative width or height
        Inflate(dx_obj, dy="U")
        {
            err := 0
            (this.is_int(dx_obj) && this.is_int(dy)) ; Both int
                ? (this.left  := this.x -= dx_obj       ,this.top    := this.y -= dy
                  ,this.right += dx_obj                 ,this.bottom += dy
                  ,this.width += (dx_obj*2)             ,this.height += (dy*2) )
            : (dx_obj.type == "Point" && dy == "U")   ; Point obj
                ? (this.left  := this.x -= dx_obj.x     ,this.top    := this.y -= dx_obj.y
                  ,this.right += dx_obj.x               ,this.bottom += dx_obj.y
                  ,this.width += (dx_obj.x*2)           ,this.height += (dx_obj.y*2) )
            : (dx_obj.type == "Size" && dy == "U")    ; Size obj
                ? (this.left  := this.x -= dx_obj.width ,this.top    := this.y -= dx_obj.height
                  ,this.right += dx_obj.width           ,this.bottom += dx_obj.height
                  ,this.width += (dx_obj.width*2)       ,this.height += (dx_obj.height*2) )
            : err := 1
            
            (err)
                ? this.error_log(A_ThisFunc, "This functions requires two integers, a Point object, or a Size "
                    . "object parameter.", "Point Object, Size Object, 2 Intgers", {dx_obj:dx_obj, dy:dy})
                : this._update_struct()
        }
        
        ; This is an overloaded method:
        ; Intersect(Rect)   Update current Rect values to represent the rectangle created by the intersection.
        ; Intersect(Rect1   Create new Rect using values of the rectangle created by Rect1 and Rect2 intersecting
        ;   , Rect2, RectOut) 
        ; Description       
        ; Rect              Rect object to to intersect with
        ; Return            0 = No intersection, 1 = Intersect found
        ; Remark            If there is no intersection, all values are updated to 0
        Intersect(Rect1, Rect2="U", ByRef RectOut="U")
        {
            status := "err"
            (Rect1.type == "Rect" && Rect2 == "U" && RectOut == "U")                      ; Only Rect1
                ? (this.left := this.x := (this.left   > Rect.left)   ? this.left   : Rect.left
                  ,this.top  := this.y := (this.top    > Rect.top)    ? this.top    : Rect.top
                  ,this.right          := (this.right  < Rect.right)  ? this.right  : Rect.right
                  ,this.bottom         := (this.bottom < Rect.bottom) ? this.bottom : Rect.bottom
                  ,this.width          := (this.right  - this.left)
                  ,this.height         := (this.bottom - this.top)
                  ,this._update_struct() ,status := this.IsEmptyArea() )
            : (Rect1.type == "Rect" && Rect2.type == "Rect" && RectOut.type == "Rect")  ; Rect1, Rect2, and RectOut
                ? (RectOut.left := RectOut.x := (Rect1.left     > Rect2.left)   ? Rect1.left   : Rect2.left
                  ,RectOut.top  := RectOut.y := (Rect1.top      > Rect2.top)    ? Rect1.top    : Rect2.top
                  ,RectOut.right             := (Rect1.right    < Rect2.right)  ? Rect1.right  : Rect2.right
                  ,RectOut.bottom            := (Rect1.bottom   < Rect2.bottom) ? Rect1.bottom : Rect2.bottom
                  ,RectOut.width             := (RectOut.right  - RectOut.left)
                  ,RectOut.height            := (RectOut.bottom - RectOut.top)
                  ,RectOut._update_struct() ,status := RectOut.IsEmptyArea() )
            : this.error_log(A_ThisFunc, "Bad parameter", "A single Rect or 3 Rects are required."
                , {Rect1:Rect1, Rect2:Rect2, RectOut:RectOut}) ; Error > Bad parameter passed
            Return status
        }
        
        ; Description       Determine if provided Rect and native Rect intersect
        ; Return            1 = True, 0 = False
        IntersectsWith(Rect)
        {
            Return ((this.left < Rect.right)
                &&  (this.right > Rect.left)
                &&  (this.top < Rect.bottom)
                &&  (this.bottom > Rect.top) ) ? 1 : 0
        }
        
        ; Description       Determines whether this rectangle is empty.
        ; Return            1 = Empty, 0 = Not empty
        IsEmptyArea()
        {
            Return (this.width <= 0 || this.height <= 0) ? 1 : 0
        }
        
        ; Offset(Point)     Moves the rectangle by int dx horizontally and by int dy vertically.
        ; Offset(dx, dy)    Moves this rectangle horizontally a distance of point.X and vertically a distance of point.Y.
        ; Return            No return value
        Offset(dx_obj, dy="U")
        {
            (this.is_int(dx_obj) && this.is_int(dy))
                ? (this.left := this.x += dx_obj    ,this.top := this.y += dy
                  ,this.right          += dx_obj    ,this.bottom        += dy
                  ,this._update_struct() )
            : (dx_obj == "Point" && y == "U")
                ? (this.left := this.x += dx_obj.x  ,this.top := this.y += dx_obj.y
                  ,this.right          += dx_obj.x  ,this.bottom        += dx_obj.y
                  ,this._update_struct() )
            : this.error_log(A_ThisFunc, "Bad parameter", "Point object or two integers", {dx_obj:dx_obj, dy:dy})
        }
        
        ; Description       Creates a new Rect that stores the union of two other Rect objects.
        ; Rect1, Rect2      The two Rect objects to join
        ; RectOut           The Rect output that will contain the unioned Rects.
        ; Return            1 = Empty Rect, 0 = Not Empty, Err = Error occurred
        ; Remark            A union Rect is a Rect big enough to accommodate both Rect objects.
        Union(ByRef RectOut, Rect1, Rect2)
        {
            status := 0
            (RectOut.type == "Rect" && Rect1.type == "Rect" && Rect2.type == "Rect")
                ? (RectOut.left := RectOut.x := (Rect1.left   < Rect2.left   ? Rect1.left   : Rect2.left)
                  ,RectOut.top  := RectOut.y := (Rect1.top    < Rect2.top    ? Rect1.top    : Rect2.top)
                  ,RectOut.right             := (Rect1.right  > Rect2.right  ? Rect1.right  : Rect2.right)
                  ,RectOut.bottom            := (Rect1.bottom > Rect2.bottom ? Rect1.bottom : Rect2.bottom)
                  ,RectOut.width  := (RectOut.right - RectOut.left)
                  ,RectOut.height := (RectOut.bottom - RectOut.top)
                  ,RectOut._update_struct()
                  ,status := !RectOut.IsEmptyArea() )
                : (this.error_log(A_ThisFunc, "Bad parameter", "Requires 3 Rect objects."
                    , {RectOut:RectOut, Rect1:Rect1, Rect2:Rect2})
                  ,status := "err" )
            Return status
        }
        
    }
    
    ;===================================================================================================================.
    ; A RectF object contains 4 float values representing x, y, width, and height.                                      |
    ; Properties:                                                                                                       |
    ; .x                RectF leftmost x coordinate (integer)                                                           |
    ; .y                RectF topmost y coordinate (integer)                                                            |
    ; .width            RectF width (integer)                                                                           |
    ; .height           RectF height (integer)                                                                          |
    ; .left             Left x coord (synonymous with .x)                                                               |
    ; .right            Right x coord                                                                                   |
    ; .top              Top y coord (synonymous with .y)                                                                |
    ; .bottom           Bottom y coord                                                                                  |
    ; .structP          Pointer to RectF struct (x > y > width > height)                                                |
    ;                                                                                                                   |
    ; Constructors:                                                                                                     |
    ; RectF()           Create a RectF object with width and height values of 0                                         |
    ; RectF(f1, f2, f3, f4) Create a RectF object with int x, y, width, and height                                      |
    ; RectF(PointF, SizeF) Create a RectF object using a PointF and SizeF object                                        |
    ;                                                                                                                   |
    ; Methods:                                                                                                          |
    ; Clone()           Returns a new RectF object with the same values as the native RectF object.                     |
    ; Contains(x, y)    Returns true if int x and int y fall within the native RectF                                    |
    ; Contains(PointF)  Returns true if PointF.x and PointF.y falls within native RectF                                 |
    ; Contains(RectF)   Returns true if provided RectF falls within native RectF                                        |
    ; Equals(RectF)     Returns true if supplied and native RectF have equal x, y, width, and height values             |
    ; GetBottom()       Returns bottom y coordinate of this RectF                                                       |
    ; GetBounds(RectF)  Copies native RectF values to the provide RectF object > no return                              |
    ; GetLeft()         Returns left x coordinate of this RectF                                                         |
    ; GetLocation(PointF) Copies native x and y value from RectF to the provided PointF object > no return              |
    ; GetRight()        Returns right x coordinate of this RectF                                                        |
    ; GetSizeF(SizeF)   Copies native width and height from RectF to the provided SizeF object > no return              |
    ; GetTop()          Returns top y coordinate of this RectF                                                          |
    ; Inflate(dx, dy)   Expands native RectF by int dx wide on both sides and int dy on top and bottom                  |
    ; Inflate(PointF)   Expands native RectF by PointF.x on both sides and PointF.y on top and bottom                   |
    ; Inflate(SizeF)    Expands native RectF by SizeF.width on both sides and SizeF.height on th top and bottom         |
    ; Intersect(RectF)  Returns a new RectF with values set to the rectangle intersection made by the 2 RectFs          |
    ; Intersect(RectF1  Returns a new RectF with values set to the rectangle intersection made by RectF1 and RectF2     |
    ;   ,RectF2, RectFOut)                                                                                              |
    ; IntersectsWith(RectF) Return true if provided RectF intersects native RectF                                       |
    ; IsEmptyArea()     Return true if width or height of RectF is 0 or less                                            |
    ; Offset(PointF)    Reposition RectF by moving x PointF.x and y by PointF.y                                         |
    ; Offset(dx, dy)    Reposition RectF by moving x by int dx and y by int dy                                          |
    ; Union(RectFOut    Find RectF SizeF to unionize RectF1 and RectF2 then assign them to RectFOut                     |
    ;   , RectF1, RectF2)                                                                                               |
    ;                                                                                                                   |
    ; Remarks           If working with float/decimal numbers, use RectFF.                                              |
    ;                   There is no way to use the + and - operators with RectFs. Use the plus() or minus() methods.    |
    ;___________________________________________________________________________________________________________________|
    Class RectF extends GDIP
    {
        type    := "RectF"
        x       := ""
        y       := ""
        width   := ""
        height  := ""
        bottom  := ""
        top     := ""
        struct  := ""
        structP := ""
        
        
        ; ##  Constructor ##
        ; RectF()
        ; RectF(float, float, float, float)
        ; RectF(PointF, SizeF)
        __New(obj_x="U", obj_y="U", width="U", height="U")
        {
            err := 0
            (this.is_num(obj_x) && this.is_num(obj_y) && this.is_num(width) && this.is_num(height))     ; All float
                ? (this.left  := this.x := obj_x        ,this.top    := this.y := obj_y
                  ,this.width := width                  ,this.height := height
                  ,this.right := obj_x + width          ,this.bottom := obj_y + height )
            : (obj_x == "U" && obj_y == "U" && width == "U" && height == "U")                           ; All blank
                ? (this.left  := this.x := 0            ,this.top    := this.y := 0
                  ,this.width := 0                      ,this.height := 0
                  ,this.right := 0                      ,this.bottom := 0 )
            : ((obj_x.type == "PointF" || obj_x.type == "Point")                                        ; PointF + SizeF
                && (obj_y.type == "SizeF" || obj_y.type == "Size")
                && width == "U" && height == "U")
                ? (this.left  := this.x := obj_x.x      ,this.top    := this.y := obj_x.y 
                  ,this.width := obj_y.width            ,this.height := obj_y.height
                  ,this.right := this.x + this.width    ,this.bottom := this.y + this.height )
            : err := 1                                                                                  ; Error
            
            (err)
                ? this.error_log(A_ThisFunc, "Failed to create RectF struct."                           ; If error, log it
                    , "No params, 4 floats, 1 SizeF object and 1 PointF object"
                    , {obj_x:obj_x, obj_y:obj_y, width:width, height:height})
                : (this.SetCapacity("struct", 16)                                                       ; Else build RectF
                    ,this.structP := this.GetAddress("struct")
                    ,this._update_struct() )
        }
        
        _update_struct()
        {
             NumPut(this.x     , this.structP+0,  0, "Float")
            ,NumPut(this.y     , this.structP+0,  4, "Float")
            ,NumPut(this.width , this.structP+0,  8, "Float")
            ,NumPut(this.height, this.structP+0, 12, "Float")
        }
        
        ; For testing purposes > Shows contents of this object
        show(msg="")
        {
            MsgBox, % (msg = "" ? "" : msg "`n")
                . "type: "             this.type                "`nstructP: "   this.structP
                . "`nx: "              this.x                   "`ny: "         this.y
                . "`nwidth: "          this.width               "`nheight: "    this.height
                . "`nleft: "           this.left                "`nright: "     this.right
                . "`ntop: "            this.top                 "`nbottom: "    this.bottom
                . "`nStructP x: "      NumGet(this.structP+0,  0, "Float")
                . "`nStructP y: "      NumGet(this.structP+0,  4, "Float")
                . "`nStructP width: "  NumGet(this.structP+0,  8, "Float")
                . "`nStructP height: " NumGet(this.structP+0, 12, "Float")
            Return
        }
        
        ; ## METHODS ##
        ; Description       Creates a new RectF object and initializes it with the contents of this RectF object.
        Clone()
        {
            Return new gdip.RectF(this.x, this.y, this.width, this.height)
        }
        
        ; This is an overloaded method:
        ; Contains(x, y)    Determine if float x and float y fall within native RectF
        ; Contains(PointF)  Determine if PointF falls within native RectF
        ; Contains(RectF)   Determine if provided RectF falls within native RectF
        ; Return            1 = True, 0 = False
        ; Remark            Contains include lines falling on 
        Contains(obj_x, y="U")
        {
            Return (this.is_num(obj_x) && this.is_num(y)                            ; check x y coords
                    && (obj_x >= this.left)     && (obj_x < this.right)
                    && (    y >= this.top)      && (    y < this.bottom)            ) ? 1
                : ((obj_x.type == "PointF" || obj_x.type == "Point") && y == "U"    ; check PointF xy coords
                    && (obj_x.x >= this.left)   && (obj_x.x < this.right)
                    && (obj_x.y >= this.top)    && (obj_x.y < this.bottom)          ) ? 1
                : (obj_x.type == "RectF" && y == "U"                                ; check if RectF is inside RectF
                    && (this.x <= obj_x.x)      && (this.right >= obj_x.right)
                    && (this.y <= obj_x.y)      && (this.bottom >= obj_x.bottom)    ) ? 1
                : 0                                                                 ; does not contain
        }
        
        ; Description       Determine if the supplied and native have equal x, y, width, and height values
        ; RectF             RectF struct to compare
        ; Return            1 = True, 0 = False
        Equals(RectF)
        {
            Return (RectF.x     = this.x     && RectF.y      = this.y
                &&  RectF.width = this.width && RectF.height = this.height ) ? 1 : 0
        }
        
        ; Description       Retrieves coordinate for the bottom edge of this RectF
        GetBottom()
        {
            Return this.bottom
        }
        
        ; Description       Copy the current RectF values to the provide RectF object
        GetBounds(ByRef RectF)
        {
            (RectF.type == "RectF")
                ? (RectF.x := this.x, RectF.y := this.y, RectF.width := this.width, RectF.height := this.height)
                : this.error_log(A_ThisFunc, "This functions requires a RectF object for the parameter."
                    , "RectF object", {providedRectF:RectF})
        }
        
        ; Description       Retrieves coordinate for the left edge of this RectF
        ; Remark            Left is synonymous with x of a RectF
        GetLeft()
        {
            Return this.left
        }
        
        ; Description       Get x and y value from RectF and assign them to the provided PointF object
        ; Return            No return value
        GetLocation(ByRef PointF)
        {
            PointF := new GDIP.PointF(this.x, this.y)
        }
        
        ; Description       Retrieves coordinate for the right edge of this RectF
        GetRight()
        {
            Return this.right
        }
        
        ; Description       Get width and height value from RectF and assign them to the provided SizeF object
        ; Return            No return value
        GetSizeF(ByRef SizeF)
        {
            SizeF := new GDIP.SizeF(this.width, this.height)
        }
        
        ; Description       Retrieves coordinate for the top edge of this RectF
        ; Remark            Top is synonymous with y of a RectF
        GetTop()
        {
            Return this.top
        }
        
        ; Overloaded method:
        ; Inflate(dx, dy)   Expand left & right edges by float dx and top & bottom edges by float dy
        ; Inflate(PointF)   Expand left & right edges by PointF.x and the top & bottom edges by PointF.y
        ; Inflate(SizeF)    Expand left & right edges by SizeF.width and the top & bottom edges by SizeF.height
        ; Return            No return value
        ; Remark            A RectFangle should not be able to have a negative width or height
        Inflate(dx_obj, dy="U")
        {
            err := 0
            (this.is_num(dx_obj) && this.is_num(dy))                                ; Both float
                ? (this.left  := this.x -= dx_obj       ,this.top    := this.y -= dy
                  ,this.right += dx_obj                 ,this.bottom += dy
                  ,this.width += (dx_obj*2)             ,this.height += (dy*2) )
            : ((dx_obj.type == "PointF" || dx_obj.type == "Point") && dy == "U")    ; PointF obj
                ? (this.left  := this.x -= dx_obj.x     ,this.top    := this.y -= dx_obj.y
                  ,this.right += dx_obj.x               ,this.bottom += dx_obj.y
                  ,this.width += (dx_obj.x*2)           ,this.height += (dx_obj.y*2) )
            : ((dx_obj.type == "SizeF" || dx_obj.type == "Size") && dy == "U")      ; SizeF obj
                ? (this.left  := this.x -= dx_obj.width ,this.top    := this.y -= dx_obj.height
                  ,this.right += dx_obj.width           ,this.bottom += dx_obj.height
                  ,this.width += (dx_obj.width*2)       ,this.height += (dx_obj.height*2) )
            : err := 1
            
            (err)
                ? this.error_log(A_ThisFunc, "This functions requires two Floats, a PointF object, or a SizeF "
                    . "object parameter.", "PointF Object, SizeF Object, 2 Floats", {dx_obj:dx_obj, dy:dy})
                : this._update_struct()
        }
        
        ; This is an overloaded method:
        ; Intersect(RectF)  Update current RectF values to represent the RectFangle created by the intersection.
        ; Intersect(RectF1  Create new RectF using values of the RectFangle created by RectF1 and RectF2 intersecting
        ;   ,RectF2,RectFOut) 
        ; Description       
        ; RectF             RectF object to to intersect with
        ; Return            0 = No intersection, 1 = Intersect found
        ; Remark            If there is no intersection, all values are updated to 0
        Intersect(RectF1, RectF2="U", ByRef RectFOut="U")
        {
            status := "err"
            (RectF1.type == "RectF" && RectF2 == "U" && RectFOut == "U")  ; Only RectF1
                ? (this.left := this.x := (this.left   > RectF.left)   ? this.left   : RectF.left
                  ,this.top  := this.y := (this.top    > RectF.top)    ? this.top    : RectF.top
                  ,this.right          := (this.right  < RectF.right)  ? this.right  : RectF.right
                  ,this.bottom         := (this.bottom < RectF.bottom) ? this.bottom : RectF.bottom
                  ,this.width          := (this.right  - this.left)
                  ,this.height         := (this.bottom - this.top)
                  ,this._update_struct(), status := !this.IsEmptyArea() )
            : (RectF1.type == "RectF" && RectF2.type == "RectF" && RectFOut.type == "RectF")  ; RectF1, RectF2, and RectFOut
                ? (RectFOut.left := RectFOut.x := (RectF1.left     > RectF2.left)   ? RectF1.left   : RectF2.left
                  ,RectFOut.top  := RectFOut.y := (RectF1.top      > RectF2.top)    ? RectF1.top    : RectF2.top
                  ,RectFOut.right              := (RectF1.right    < RectF2.right)  ? RectF1.right  : RectF2.right
                  ,RectFOut.bottom             := (RectF1.bottom   < RectF2.bottom) ? RectF1.bottom : RectF2.bottom
                  ,RectFOut.width              := (RectFOut.right  - RectFOut.left)
                  ,RectFOut.height             := (RectFOut.bottom - RectFOut.top)
                  ,RectFOut._update_struct(), status := !this.IsEmptyArea() )
            : this.error_log(A_ThisFunc, "Bad parameter", "A single RectF or 3 RectFs are required."
                , {RectF1:RectF1, RectF2:RectF2, RectFOut:RectFOut}) ; Error > Bad parameter passed
            Return status
        }
        
        ; Description       Determine if provided RectF and native RectF intersect
        ; Return            1 = True, 0 = False
        IntersectsWith(RectF)
        {
            Return ((this.left < RectF.right)
                &&  (this.right > RectF.left)
                &&  (this.top < RectF.bottom)
                &&  (this.bottom > RectF.top) ) ? 1 : 0
        }
        
        ; Description       Determines whether this RectFangle is empty.
        ; Return            1 = Empty, 0 = Not empty
        IsEmptyArea()
        {
            Return (this.width <= 0 || this.height <= 0) ? 1 : 0
        }
        
        ; Offset(PointF)    Moves the RectFangle by float dx horizontally and by float dy vertically.
        ; Offset(dx, dy)    Moves this RectFangle horizontally a distance of PointF.X and vertically a distance of PointF.Y.
        ; Return            No return value
        Offset(dx_obj, dy="U")
        {
            (this.is_num(dx_obj) && this.is_num(dy))
                ? (this.left := this.x += dx_obj    ,this.top := this.y += dy
                  ,this.right          += dx_obj    ,this.bottom        += dy
                  ,this._update_struct() )
            : ((dx_obj == "PointF" || dx_obj == "Point" ) && y == "U")
                ? (this.left := this.x += dx_obj.x  ,this.top := this.y += dx_obj.y
                  ,this.right          += dx_obj.x  ,this.bottom        += dx_obj.y
                  ,this._update_struct() )
            : this.error_log(A_ThisFunc, "Bad parameter", "PointF object or two Floats", {dx_obj:dx_obj, dy:dy})
        }
        
        ; Description       Creates a new RectF that stores the union of two other RectF objects.
        ; RectF1, RectF2    The two RectF objects to join
        ; RectFOut          The RectF output that will contain the unioned RectFs.
        ; Return            1 = Empty RectF, 0 = Not Empty, Err = Error occurred
        ; Remark            A union RectF is a RectF big enough to accommodate both RectF objects.
        Union(ByRef RectFOut, RectF1, RectF2)
        {
            status := "err"
            (RectFOut.type == "RectF" && RectF1.type == "RectF" && RectF2.type == "RectF")
                ? (RectFOut.left := RectFOut.x := (RectF1.left   < RectF2.left   ? RectF1.left   : RectF2.left)
                  ,RectFOut.top  := RectFOut.y := (RectF1.top    < RectF2.top    ? RectF1.top    : RectF2.top)
                  ,RectFOut.right              := (RectF1.right  > RectF2.right  ? RectF1.right  : RectF2.right)
                  ,RectFOut.bottom             := (RectF1.bottom > RectF2.bottom ? RectF1.bottom : RectF2.bottom)
                  ,RectFOut.width  := (RectFOut.right - RectFOut.left)
                  ,RectFOut.height := (RectFOut.bottom - RectFOut.top)
                  ,RectFOut._update_struct()
                  ,status := !RectFOut.IsEmptyArea() )
                : this.error_log(A_ThisFunc, "Bad parameter", "Requires 3 RectF objects."
                    , {RectFOut:RectFOut, RectF1:RectF1, RectF2:RectF2})
            Return status
        }
    }
    
    Class gui extends GDIP
    {
        gHwnd   := {}
        title   := ""
        width   := ""
        height  := ""
        
        ;___________________________________________________________________________________________________________________
        ; Call              new gdip.gui(title="OnTop:=1,TitleBar:=0,TaskBar:=0)                                            |
        ; Description       Creates a new GUI object                                                                        |
        ;                                                                                                                   |
        ; OnTop             Set window to always on top                                                                     |
        ;                                                                                                                   |
        ; Return            Handle to gui                                                                                   |
        ;___________________________________________________________________________________________________________________|
        __New(title="Main", width="", height="", OnTop=1, TitleBar=0, TaskBar=1)
        {
            this.title  := title
            this.width  := (width = "") ? A_ScreenWidth : width
            this.height := (height = "") ? A_ScreenHeight : height
            
            Gui, % title ":New", % "+E0x80000 "                ; Create a new layered window
                . (TitleBar ? "+" : "-") "Caption "             ; Remove title bar and thick window border/edge
                . (OnTop    ? "+" : "-") "AlwaysOnTop "         ; Force GUI to always be on top
                . (TaskBar  ? "+" : "-") "ToolWindow "          ; Removes the taskbar button
                . "+HWNDguiHwnd "                               ; Saves the handle of the GUI to guiHwnd
            Gui, Show, NA                                       ; Make window visible but transparent
            this.gHwnd.gui := guiHwnd
        }
        
        _update(title="Main")
        {
            DllCall("UpdateLayeredWindow"
                    , HWND          , this.gHwnd.gui[title]     ; Handle to window
                    , HDC           , hdcDst                    ; Handle to DC destination
                    , this.Ptr      , *pptDst                   ; Set new screen position using Point struct
                    , this.Ptr      , *psize                    ; Set new screen size using Size struct
                    , HDC           , hdcSrc                    ; Handle to DC source
                    , this.Ptr      , *pptSrc                   ; Set layer locaiton using Point struct
                    , COLORREF      , crKey                     ; ColorRef struct
                    , this.Ptr      , *pblend                   ; Pointer to a BlendFunction struct
                    , DWORD         , dwFlags )                 ; Add: 0x1 - ULW_COLORKEY
                                                                ;      0x2 - ULW_ALPHA
                                                                ;      0x4 - ULW_OPAQUE
                                                                ;      0x8 - ULW_EX_NORESIZE
            Return
        }
        
        show()
        {
            Gui, % this.title ":Show"
            Return
        }
        
        hide()
        {
            Gui, % this.title ":Hide"
            Return
        }
        
        default()
        {
            Gui, % this.title ":Default"
            Return
        }
    }
    
    ; ############
    ; ## Errors ##
    ; ############
    ; The value or what was actually received
    ; call      = Function or method call that failed
    ; msg       = General error message
    ; expect    = What kind of data was expected
    ; data_obj  = Object containing all pertinent info.
    ;             Key name describes vars.
    error_log(call, msg, expected, data_obj)
    {
        str := "Data Object:`n"
        ; Need to build a recursive object extractor for here
        For k, v in data_obj
            str .= k ": " v "`n"
        this.last_err := A_Now "`n" call "`n" msg "`n" expected "`n" RTrim(str, "`n") "`n`n"
        MsgBox,, GDIP Error, % this.last_err
        Return
    }
    
    ; ##################
    ; ##  Validators  ##
    ; ##################
    is_int(num)
    {
        Return (Mod(num, 1) = 0) ? 1 : 0
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
        msg(msg="Working!")
        {
            MsgBox, % msg
            Return
        }
        
        show_img(image_p)
        {
            hwnd := this.gui.new_layered_window(A_ScreenWidth, A_ScreenHeight)
            
        }
    }
    
}

; Helpful links:
; https://pdfium.googlesource.com/pdfium/+/5110c4743751145c4ae1934cd1d83bc6c55bb43f/core/src/fxge/Microsoft%20SDK/include?autodive=0/
; https://doxygen.reactos.org/d5/def/gdiplustypes_8h_source.html


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

/*
Extra code fromm work:
GDIP.Graphics.DrawImage()



; INT VARIANTS
; Draw image at specified x/y coordinate but use original img width & height
GdipDrawImage(graphicP, imoP)

GdipDrawImageI(graphicP, imoP, INT x, INT y)
GdipDrawImage(graphicP, imoP, REAL x, REAL y)

; Draw image at specified x/y coord and make image width by height.
GdipDrawImageRectI(graphicP, imoP, INT x, INT y, INT width, INT height)
GdipDrawImageRect(graphicP, imoP, REAL x, REAL y, REAL width, REAL height)

; Draws an image.
;~ * Affine or perspective blt
;~ *  destPoints.length = 3:
;~ *      rect => parallelogram
;~ *      destPoints[0] <=> top-left corner of the source rectangle
;~ *      destPoints[1] <=> top-right corner
;~ *      destPoints[2] <=> bottom-left corner
;~ *  destPoints.length = 4:
;~ *      rect => quad
;~ *      destPoints[3] <=> bottom-right corner
; Draw image
; Description       Draw image using the dest_point_arr provided.
; dest_point_arr    An array containing 3-4 Point objects
; count             Number of elements in dest_point_arr
; Remark            Count is number of elements in dp_arr and must be 3 (parallelogram) or 4 (quad).
GdipDrawImagePointsI(graphicP, imoP, dest_point_arr, INT count)
GdipDrawImagePoints(graphicP, imoP, GDIPCONST GpPointF *dstpoints, INT count)

; Capture part of an image using srcx, srcy, srcwidth, and srcheight then draw that image at the x/y coordinates.
GdipDrawImagePointRectI(graphicP, imoP, INT x, INT y, INT srcx, INT srcy, INT srcwidth, INT srcheight, GpUnit srcUnit)
GdipDrawImagePointRect(graphicP, imoP, REAL x, REAL y, REAL srcx, REAL srcy, REAL srcwidth, REAL srcheight, GpUnit srcUnit)

; Description       Capture part of an image using src_x/y/w/h and draw image at dst_x/y with src_width/height.
; src_x/y/w/h       The source WHXY that you want captured
; dst_x/y/w/h       The destination you want to draw the captured part of the image
; src_unit          A number from the Unit type enumeration
; img_attributes    
; callback          
; callback_data     
; Remark            In the flat function, the dstx, dsty, dstwidth, and dstheight parameters specify a rectangle that corresponds to the dstRect parameter in the wrapper method.

GdipDrawImageRectRectI(graphicP, imoP
                      , INT dstx, INT dsty, INT dstwidth, INT dstheight
                      , INT srcx, INT srcy, INT srcwidth, INT srcheight
                      , GpUnit srcUnit, GDIPCONST GpImageAttributes* imageAttributes, DrawImageAbort callback, VOID * callbackData)
GdipDrawImageRectRect(graphicP, imoP, REAL dstx, REAL dsty, REAL dstwidth, REAL dstheight   , REAL srcx, REAL srcy, REAL srcwidth, REAL srcheight, GpUnit srcUnit, GDIPCONST GpImageAttributes* imageAttributes, DrawImageAbort callback, VOID * callbackData)

; Draws an image.
GdipDrawImagePointsRectI(graphicP, imoP, GDIPCONST GpPoint *points, INT count, INT srcx, INT srcy, INT srcwidth, INT srcheight, GpUnit srcUnit, GDIPCONST GpImageAttributes* imageAttributes, DrawImageAbort callback, VOID * callbackData)
GdipDrawImagePointsRect(graphicP, imoP, GDIPCONST GpPointF *points, INT count, REAL srcx, REAL srcy, REAL srcwidth, REAL srcheight, GpUnit srcUnit, GDIPCONST GpImageAttributes* imageAttributes, DrawImageAbort callback, VOID * callbackData)

; OTHER
; Draws a portion of an image after applying a specified effect.
GdipDrawImageFX(graphicP, imoP, GpRectF *source, GpMatrix *xForm, CGpEffect *effect, GpImageAttributes *imageAttributes, GpUnit srcUnit)

