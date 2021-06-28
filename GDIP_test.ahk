#Warn
GDIP.__new()

Class GDIP
{
    ;###################################################################################################################
    ; STATUS ENUMERATION - Defines all possible status enumeration return types you might encounter                     |
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
        this.ptr        := A_PtrSize ? "UInt" : ""
        this.gdip_token := ""
        OnExit(this.run_method("Shutdown"))
        
        this.Startup()
        Return
    }
    
    ;___________________________________________________________________________________________________________________|
    ; Call          Startup()                                                                                           |
    ; Description   Initializes GDI+ and stores the token in this.token                                                 |
    ; Return        Status enumeration value. 0 = success. -1 = GDIP already started.                                   |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;___________________________________________________________________________________________________________________|
    Startup()
    {
        (this.gdip_token = "")
            ? (VarSetCapacity(pStartInput, A_PtrSize = 8 ? 24 : 16, 0)
            , pStartInput := 0x1
            , status := DllCall("gdiplus\GdiplusStartup"
                                , "UInt"    , this.gdip_token,  ; Pointer to GDIP token
                                , this.ptr  , pStartInput,      ; Startup Input
                                , this.ptr  , 0) )              ; Startup Output
            : status := -1
        Return status
    }
    
    ;___________________________________________________________________________________________________________________|
    ; Call                                                                                                              |
    ; Description                                                                                                       |
    ; Params                                                                                                            |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Shutdown()
    {
        DllCall("gdiplus\GdiplusShutdown", "UInt", this.gdip_token)
        Return
    }
    
    ; Class related methods
    run_method(method_name, params := "")
    {
        bf := ObjBindMethod(this, method_name, params*)
        Return bf
    }

}

    ;___________________________________________________________________________________________________________________|
    ; Call                                                                                                              |
    ; Description                                                                                                       |
    ; Params                                                                                                            |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
