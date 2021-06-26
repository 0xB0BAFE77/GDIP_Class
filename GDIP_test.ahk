#Warn
GDIP.__new()

Class GDIP
{
    __New()
    {
        OnExit(this._method("Shutdown"))
        this.ptr := A_PtrSize ? 
        this.gdip_token := ""
        Return
    }
    
    ;####################################################################################################################
    ; Call          Startup()                                                                                           |
    ; Description   Initializes GDI+ and stores the token in this.token                                                 |
    ; Return        Status enumeration value. 0 = success. -1 = GDIP already started.                                   |
    ;               The Status Enumeration Table can be found at the top of this library.                               |
    ;___________________________________________________________________________________________________________________|
    Startup(){
        (this.gdip_token = "")
            ? VarSetCapacity(pStartInput, A_PtrSize = 8 ? 24 : 16, 0)
            , pStartInput := 0x1
            , status := DllCall("gdiplus\GdiplusStartup"
                                , "UInt"    , this.gdip_token,  ; Pointer to GDIP token
                                , this.ptr  , pStartInput,      ; Startup Input
                                , this.ptr  , 0)                ; Startup Output
            : ""
        Return -1
    }
    
    ;####################################################################################################################
    ; Call                                                                                                              |
    ; Description                                                                                                       |
    ; Params                                                                                                            |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    Shutdown(){
        DllCall("gdiplus\GdiplusShutdown", "UInt", this.gdip_token)
        Return
    }
    
    ; Non-GDI+ methods
    _method(method_name, params := ""){
        bf := ObjBindMethod(this, method_name, params*)
        Return bf
    }
}
