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

/*
GDI+ Class and Method List
                                                                                                                                                                               
AdjustableArrowCap                      Builds a line cap that looks like an arrow. This is a subclass of CustomLineCap.
    ::Inherit::                         
    ::Methods::                         
    AdjustableArrowCap()                Creates an adjustable arrow line cap with specified height and width. Can be filled or unfilled. Middle inset defaults to zero.
    GetHeight()                         Gets height of arrow cap. The height is the distance from the base of the arrow to its vertex.
    GetMiddleInset()                    Gets value of inset. The middle inset is the number of units that the midpoint of the base shifts towards the vertex.
    GetWidth()                          Gets width of arrow cap. The width is the distance between the endpoints of the base of the arrow.
    IsFilled()                          Determines whether the arrow cap is filled.
    SetFillState()                      Sets fill state of the arrow cap. If the arrow cap is not filled, only the outline is drawn.
    SetHeight()                         Sets height of the arrow cap. This is the distance from the base of the arrow to its vertex.
    SetMiddleInset()                    Sets number of units that the midpoint of the base shifts towards the vertex.
    SetWidth()                          Sets width of the arrow cap. The width is the distance between the endpoints of the base of the arrow.
                                                                                                                                                                                       
Bitmap                                  Inherits from the Image class. The Image class provides saving and loading methods for vector images (metafiles) and raster images (bitmaps).
    ::Inherit::                         
    ::Methods::                         
    ApplyEffectThe()                    Bitmap::ApplyEffect method creates a new Bitmap object by applying a specified effect to an existing Bitmap object.
    ApplyEffectThe()                    Bitmap::ApplyEffect method alters this Bitmap object by applying a specified effect.
    Bitmap()                            Creates a Bitmap object based on a BITMAPINFO structure and an array of pixel data.
    Bitmap()                            Creates a Bitmap object based on an image file.
    Bitmap()                            Creates a Bitmap object based on a handle to a Windows Windows Graphics Device Interface (GDI) bitmap and a handle to a GDI palette.
    Bitmap()                            Creates a Bitmap object based on an icon.
    Bitmap()                            Creates a Bitmap object based on an application or DLL instance handle and the name of a bitmap resource.
    Bitmap()                            Creates a Bitmap object based on a DirectDraw surface. The Bitmap::Bitmap object maintains a reference to the DirectDraw surface until the Bitmap::Bitmap object is deleted or goes out of scope.
    Bitmap()                            Creates a Bitmap object based on a Graphics object, a width, and a height.
    Bitmap()                            Creates a Bitmap object based on an array of bytes along with size and format information.
    Bitmap()                            Creates a Bitmap object of a specified size and pixel format. The pixel data must be provided after the Bitmap::Bitmap object is constructed.
    Bitmap()                            Creates a Bitmap object based on an IStream COM interface.
    CloneThe()                          Creates a new Bitmap object by copying a portion of this bitmap.
    CloneThe()                          Creates a new Bitmap object by copying a portion of this bitmap.
    CloneThe()                          Creates a new Bitmapobject by copying a portion of this bitmap.
    CloneThe()                          Creates a new Bitmapobject by copying a portion of this bitmap.
    ConvertFormatThe()                  Converts a bitmap to a specified pixel format. The original pixel data in the bitmap is replaced by the new pixel data.
    FromBITMAPINFOThe()                 Creates a Bitmap object based on a BITMAPINFO structure and an array of pixel data.
    FromDirectDrawSurface()             Creates a Bitmap object based on a DirectDraw surface. The Bitmap object maintains a reference to the DirectDraw surface until the Bitmap object is deleted.
    FromFileThe()                       Creates a Bitmap object based on an image file.
    FromHBITMAPThe()                    Creates a Bitmap object based on a handle to a Windows Graphics Device Interface (GDI) bitmap and a handle to a GDI palette.
    FromHICONThe()                      Creates a Bitmap object based on a handle to an icon.
    FromResourceThe()                   Creates a Bitmap object based on an application or DLL instance handle and the name of a bitmap resource.
    FromStreamThe()                     Creates a Bitmap object based on a stream.
    GetHBITMAPThe()                     Creates a Windows Graphics Device Interface (GDI) bitmap from this Bitmap object.
    GetHICONThe()                       Creates an icon from this Bitmap object.
    GetHistogramThe()                   Returns one or more histograms for specified color channels of this Bitmap object.
    GetHistogramSizeThe()               The number of elements (in an array of UINTs) that you must allocate before you call the Bitmap::GetHistogram method of a Bitmap object.
    GetPixelThe()                       Gets the color of a specified pixel in this bitmap.
    InitializePaletteThe()              Initializes a standard, optimal, or custom color palette.
    LockBitsThe()                       Locks a rectangular portion of this bitmap and provides a temporary buffer that you can use to read or write pixel data in a specified format.
    SetPixelThe()                       Sets the color of a specified pixel in this bitmap.
    SetResolutionThe()                  Sets the resolution of this Bitmap object.
    UnlockBitsThe()                     Unlocks a portion of this bitmap that was previously locked by a call to Bitmap::LockBits.
                                                                                                                                                                                       
BitmapData                              Used by the Bitmap::LockBits and Bitmap::UnlockBits methods of the Bitmap class. A BitmapData object stores attributes of a bitmap.
    ::Inherit::                         
    ::Methods::                         
                                                                                                                                                                                       
Blur                                    Enables you to apply a Gaussian blur effect to a bitmap and specify the nature of the blur.
    ::Inherit::                         
    ::Methods::                         
    BlurCreates()                       Blur object.
    GetParameters()                     Gets current values of Blur object parameters.
    SetParameters()                     Sets value for Blur object.
                                                                                                                                                                                   
BrightnessContrast                      Enables you to change the brightness and contrast of a bitmap. 
    ::Inherit::                         
    ::Methods::                         
    BrightnessContrast()                Creates a new BrightnessContrast object.
    GetParameters()                     Gets current values of the parameters of this BrightnessContrast object.
    SetParameters()                     Sets parameters of this BrightnessContrast object.    
                                                                                                                                                                                   
Brush                                   An abstract base class that defines a Brush object. A Brush object is used to paint the interior of graphics shapes, such as rectangles, ellipses, pies, polygons, and paths.
    ::Inherit::                         
    ::Methods::                         
    Clone()                             Creates a copy of a Brush object.
    GetLastStatus()                     Returns a value indicating this Brush object's most recent method failure.
    GetType()                           Gets the type of this brush.
                                                                                                                                                                                       
CachedBitmap                            Stores a bitmap in a format that is optimized for display on a particular device.
    ::Inherit::                         
    ::Methods::                         
    CachedBitmap()                      Create a CachedBitmap object based on a Bitmap object and Graphics object.
    CachedBitmap()                      Copy constructor for CachedBitmap.
    GetLastStatus()                     Returns a value indicating if CachedBitmap object was constructed successfully.
                                                                                                                                                                                       
CharacterRange                          Specifies a range of character positions within a string
    ::Inherit::                         
    ::Constructors::                    
    CharacterRange()                    Creates a CharacterRange object with data members set to zero.
    CharacterRange(INT,INT)             Creates a CharacterRange object and initializes data members to the values specified.    
    ::Methods::                         
    operator=()                         The operator= method sets a CharacterRange object equal to the specified CharacterRange object.
                                                                                                                                                                                       
Color                                   An object that stores a 32-bit value representing a color. The value contains four 8-bit components: alpha, red, green, and blue (respectively)
    ::Inherit::                         
    ::Constructors::                    
    Color()                             Creates Color object and initializes it to opaque black. This is the default constructor.
    Color(ARGB)                         Creates Color object using an ARGB value.
    Color(BYTE,BYTE,BYTE)               Creates Color object using specified values for the red, green, and blue components. This constructor sets the alpha component to 255 (opaque).
    Color(BYTE,BYTE,BYTE,BYTE)          Creates Color object using specified values for the alpha, red, green, and blue components.     
    ::Methods::                         
    GetA()                              Gets alpha component of Color object.
    GetAlpha()                          Gets alpha component of Color object.
    GetB()                              Gets blue component of Color object.
    GetBlue()                           Gets blue component of Color object.
    GetG()                              Gets green component of Color object.
    GetGreen()                          Gets green component of Color object.
    GetR()                              Gets red component of Color object.
    GetRed()                            Gets red component of Color object.
    GetValue()                          Gets ARGB value of this Color object.
    MakeARGB()                          Creates a 32-bit value using the specified alpha, red, green, and blue components.
    SetFromCOLORREF()                   Uses a GDICOLORREF value to set the ARGB value of this Color object.
    SetValue()                          Sets the color of this Color object.
    ToCOLORREF()                        Converts this Color object's ARGB value to a GDICOLORREF value.
                                                                                                                                                                                   
ColorBalance                            The ColorBalance class enables you to change the color balance (relative amounts of red, green, and blue) of a bitmap.
    ::Inherit::                         
    ::Methods::                         
    ColorBalance()                      Create new ColorBalance object.
    GetParameters()                     Gets the current values of the parameters of this ColorBalance object.
    SetParameters()                     Sets the parameters of this ColorBalance object.
                                                                                                                                                                                       
ColorCurve                              Eight different image adjustments: Exposure, density, contrast, highlight, shadow, midtone, white saturation, black saturation
    ::Inherit::                         
    ::Methods::                         
    ColorCurve()                        Creates a ColorCurve object.
    GetParameters()                     Gets the current values of the parameters of this ColorCurve object.
    SetParameters()                     Sets the parameters of this ColorCurve object.
                                                                                                                                                                                       
ColorLUT                                Use lookup tables to make custom color adjustments to bitmaps. A ColorLUTParams structure has four members, each being a lookup table for : alpha, red, green, or blue.
    ::Inherit::                         
    ::Methods::                         
    ColorLUT()                          Creates a new ColorLUT object.
    GetParameters()                     Gets the current values of the parameters of this ColorLUT object.
    SetParameters()                     Sets the parameters of this ColorLUT object.
                                                                                                                                                                                       
ColorMatrixEffect                       Enables you to apply an affine transformation to a bitmap.
    ::Inherit::                         
    ::Methods::                         
    ColorMatrixEffect()                 Creates a ColorMatrixEffect object.
    GetParameters()                     Gets the elements of the current 5x5 color matrix of this ColorMatrixEffect object.
    SetParameters()                     Sets the 5x5 color matrix of this ColorMatrixEffect object.
                                                                                                                                                                                   
CustomLineCap                           Encapsulates a custom line cap. A line cap defines the style of graphic used to draw the ends of a line. It can be various shapes, such as a square, circle, or diamond. A custom line cap is defined by the path that draws it.
    ::Inherit::                         
    ::Methods::                         
    Clone()                             Copies the contents of the existing object into a new CustomLineCap object.
    CustomLineCap()                     Copy constructor for CustomLineCap.
    CustomLineCap()                     Creates a CustomLineCap object.
    CustomLineCap()                     Creates a CustomLineCap object.
    GetBaseCap()                        Gets the style of the base cap. The base cap is a LineCap object used as a cap at the end of a line along with this CustomLineCap object.
    GetBaseInset()                      Gets the distance between the base cap to the start of the line.
    GetLastStatus()                     Returns a value that indicates the nature of this CustomLineCap object's most recent method failure.
    GetStrokeCaps()                     Gets the end cap styles for both the start line cap and the end line cap. Line caps are LineCap objects that end the individual lines within a path.
    GetStrokeJoin()                     Returns the style of LineJoin used to join multiple lines in the same GraphicsPath object.
    GetWidthScale()                     Gets the value of the scale width. This is the amount to scale the custom line cap relative to the width of the Pen object used to draw a line. The default value of 1.0 does not scale the line cap.
    SetBaseCap()                        Sets the LineCap that appears as part of this CustomLineCap at the end of a line.
    SetBaseInset()                      Sets the base inset value of this custom line cap. This is the distance between the end of a line and the base cap.
    SetStrokeCap()                      Sets the LineCap object used to start and end lines within the GraphicsPath object that defines this CustomLineCap object.
    SetStrokeCaps()                     Sets the LineCap objects used to start and end lines within the GraphicsPath object that defines this CustomLineCap object.
    SetStrokeJoin()                     Sets the style of line join for the stroke. The line join specifies how two lines that intersect within the GraphicsPath object that makes up the custom line cap are joined.
    SetWidthScale()                     Sets the value of the scale width. This is the amount to scale the custom line cap relative to the width of the Pen used to draw lines. The default value of 1.0 does not scale the line cap.
                                                                                                                                                                                   
Effect                                  Serves as a base class for eleven classes that you can use to apply effects and adjustments to bitmaps. 
    ::Inherit::                         
    ::Constructors::                    
    Effect()                            Creates an Effect object
    ::Methods::                         
    GetAuxData()                        Gets a pointer to a set of lookup tables created by a previous call to the Bitmap::ApplyEffect method.
    GetAuxDataSize()                    Gets the size, in bytes, of the auxiliary data created by a previous call to the Bitmap::ApplyEffect method.
    GetParameterSize()                  Gets the total size, in bytes, of the parameters currently set for this Effect. The Effect::GetParameterSize method is usually called on an object that is an instance of a descendant of the Effect class.
    UseAuxData()                        Sets or clears a flag that specifies whether the Bitmap::ApplyEffect method should return a pointer to the auxiliary data that it creates.
                                                                                                                                                                                       
EncoderParameter                        Holds a parameter that can be passed to an image encoder.
    ::Inherit::                         
    ::Methods::                         
                                                                                                                                                                                       
EncoderParameters                       An array of EncoderParameter objects along with a data member that specifies the number of EncoderParameter objects in the array.
    ::Inherit::                         
    ::Methods::                         
                                                                                                                                                                                       
Font                                    Encapsulates the characteristics, such as family, height, size, and style (or combination of styles), of a specific font. A Font object is used when drawing strings.
    ::Inherit::                         
    ::Methods::                         
    Clone()                             Creates a new Font object based on this Font object.
    Font()                              Lists the constructors of the Font class. For a complete class listing, see Font Class.
    Font()                              Creates a Font object based on a FontFamily object, a size, a font style, and a unit of measurement.
    Font()                              Creates a Font object based on a font family, a size, a font style, a unit of measurement, and a FontCollection object.
    Font()                              This topic lists the constructors of the Font class. For a complete class listing, see Font Class.
    Font()                              Creates a Font object based on the Windows Graphics Device Interface (GDI) font object that is currently selected into a specified device context. This constructor is provided for compatibility with GDI.
    Font()                              Creates a Font object indirectly from a Windows Graphics Device Interface (GDI) logical font by using a handle to a GDILOGFONT structure.
    Font()                              Creates a Font object directly from a Windows Graphics Device Interface (GDI) logical font.
    Font()                              Creates a Font object directly from a Windows Graphics Device Interface (GDI) logical font.
    GetFamily()                         Gets the font family on which this font is based.
    GetHeight()                         Gets the line spacing of this font in the current unit of a specified Graphics object.
    GetHeight()                         Gets the line spacing, in pixels, of this font.
    GetLastStatus()                     Returns a value that indicates the nature of this Font object's most recent method failure.
    GetLogFontA()                       Uses a LOGFONTA structure to get the attributes of this Font object.
    GetLogFontW()                       Uses a LOGFONTW structure to get the attributes of this Font object.
    GetSize()                           Returns the font size (commonly called the em size) of this Font object. The size is in the units of this Font object.
    GetStyle()                          Gets the style of this font's typeface.
    GetUnit()                           Returns the unit of measure of this Font object.
    IsAvailable()                       Determines whether this Font object was created successfully.
                                                                                                                                                                                       
FontCollection                          
    ::Inherit::                         
    ::Methods::                         
    FontCollection()                    Creates an empty FontCollection object.
    FontCollection()                    Creates an empty FontCollection object.
    GetFamilies()                       Gets the font families contained in this font collection.
    GetFamilyCount()                    Gets the number of font families contained in this font collection.
    GetLastStatus()                     Returns a value that indicates the result of this FontCollection object's previous method call.
                                                                                                                                                                                       
FontFamily                              Encapsulates a set of fonts that make up a font family. A font family is a group of fonts that have the same typeface but different styles.
    ::Inherit::                         
    ::Methods::                         
    Clone()                             Creates a new FontFamily object based on this FontFamily object.
    FontFamily()                        Creates an empty FontFamily object.
    FontFamily()                        Lists the constructors of the FontFamily class. For a complete class listing, see FontFamilyClass.
    FontFamily()                        Creates a FontFamily object based on a specified font family.
    FontFamily()                        Lists the constructors of the FontFamily class. For a complete class listing, see FontFamilyClass.
    GenericMonospace()                  Gets a FontFamily object that specifies a generic monospace typeface.
    GenericSansSerif()                  Gets a FontFamily object that specifies a generic sans serif typeface.
    GenericSerif()                      Gets a FontFamily object that represents a generic serif typeface.
    GetCellAscent()                     Gets the cell ascent, in design units, of this font family for the specified style or style combination.
    GetCellDescent()                    Gets the cell descent, in design units, of this font family for the specified style or style combination.
    GetEmHeight()                       Gets the size (commonly called em size or em height), in design units, of this font family.
    GetFamilyName()                     Gets the name of this font family.
    GetLastStatus()                     Returns a value that indicates the nature of this FontFamily object's most recent method failure.
    GetLineSpacing()                    Gets the line spacing, in design units, of this font family for the specified style or style combination. The line spacing is the vertical distance between the base lines of two consecutive lines of text.
    IsAvailable()                       Determines whether this FontFamily object was created successfully.
    IsStyleAvailable()                  Determines whether the specified style is available for this font family.
                                                                                                                                                                                           
GdiplusBase                                                                                                             
    ::Inherit::                         
    ::Methods::                         
    operator delete                     The operator delete method deallocates memory for one GDI+ object.
    operator delete[]                   The operator delete[] method allocates memory for an array of GDI+ objects.
    operator new                        The operator new method allocates memory for one GDI+ object.
    operator new[]                      The operator new[] method allocates memory for an array of GDI+ objects.
                                                                                                        
Graphics
    ::Inherit::                         
    ::Methods::                         
    AddMetafileComment()                Adds a text comment to an existing metafile.
    BeginContainer()                    Begins a new graphics container.
    BeginContainer()                    Begins a new graphics container.
    BeginContainer()                    Begins a new graphics container.              
    Clear()                             Clears a Graphicsobject to a specified color.
    DrawArc()                           Draws an arc. The arc is part of an ellipse.
    DrawArc()                           Draws an arc. The arc is part of an ellipse.
    DrawArc()                           Draws an arc. The arc is part of an ellipse.
    DrawArc()                           Draws an arc.
    DrawBezier()                        Draws a Bezier spline.
    DrawBezier()                        Draws a Bezier spline.
    DrawBezier()                        Draws a Bezier spline.
    DrawBezier()                        Draws a Bezier spline.
    DrawBeziers()                       Draws a sequence of connected B�zier splines.
    DrawBeziers()                       Draws a sequence of connected Bezier splines.
    DrawCachedBitmap()                  Draws the image stored in a CachedBitmap object.
    DrawClosedCurve()                   Draws a closed cardinal spline.
    DrawClosedCurve()                   Draws a closed cardinal spline.
    DrawClosedCurve()                   Draws a closed cardinal spline.
    DrawClosedCurve()                   Draws a closed cardinal spline.
    DrawCurve()                         Draws a cardinal spline.
    DrawCurve()                         Draws a cardinal spline.
    DrawCurve()                         Draws a cardinal spline.
    DrawCurve()                         Draws a cardinal spline.
    DrawCurve()                         Draws a cardinal spline.
    DrawCurve()                         Draws a cardinal spline.
    DrawDriverString()                  Draws characters at the specified positions. The method gives the client complete control over the appearance of text. The method assumes that the client has already set up the format and layout to be applied.
    DrawEllipse()                       Draws an ellipse.
    DrawEllipse()                       Draws an ellipse.
    DrawEllipse()                       Draws an ellipse.
    DrawEllipse()                       Draws an ellipse.
    DrawImage()                         Draws an image.
    DrawImage()                         Draws an image.
    DrawImage()                         Draws an image.
    DrawImage()                         Draws an image.
    DrawImage()                         Draws an image.
    DrawImage()                         Draws an image.
    DrawImage()                         Draws an image.
    DrawImage()                         Draws an image.
    DrawImage()                         Draws an image.
    DrawImage()                         Draws a specified portion of an image at a specified location.
    DrawImage()                         Draws an image.
    DrawImage()                         Draws an image at a specified location.
    DrawImage()                         Draws an image.
    DrawImage()                         Draws an image.
    DrawImage()                         Draws an image at a specified location.
    DrawImage()                         Draws an image.
    DrawImage()                         Draws an image.
    DrawImage()                         Draws a portion of an image after applying a specified effect.
    DrawLine()                          Draws a line that connects two points.
    DrawLine()                          Draws a line that connects two points.
    DrawLine()                          Draws a line that connects two points.
    DrawLine()                          Draws a line that connects two points.
    DrawLines()                         Draws a sequence of connected lines.
    DrawLines()                         Draws a sequence of connected lines.
    DrawPath()                          Draws a sequence of lines and curves defined by a GraphicsPath object.
    DrawPie()                           Draws a pie.
    DrawPie()                           Draws a pie.
    DrawPie()                           Draws a pie.
    DrawPie()                           Draws a pie.
    DrawPolygon()                       Draws a polygon.
    DrawPolygon()                       Draws a polygon.
    DrawRectangle()                     Draws a rectangle.
    DrawRectangle()                     Draws a rectangle.
    DrawRectangle()                     Draws a rectangle.
    DrawRectangle()                     Draws a rectangle.
    DrawRectangles()                    Draws a sequence of rectangles.
    DrawRectangles()                    Draws a sequence of rectangles.
    DrawString()                        Draws a string based on a font and an origin for the string.
    DrawString()                        Draws a string based on a font, a string origin, and a format.
    DrawString()                        Draws a string based on a font, a layout rectangle, and a format.
    EndContainer()                      Closes a graphics container that was previously opened by the Graphics::BeginContainer method.
    EnumerateMetafile()                 Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    EnumerateMetafile()                 Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    EnumerateMetafile()                 Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    EnumerateMetafile()                 Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    EnumerateMetafile()                 Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    EnumerateMetafile()                 Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    EnumerateMetafile()                 Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    EnumerateMetafile()                 Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    EnumerateMetafile()                 Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    EnumerateMetafile()                 Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    EnumerateMetafile()                 Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    EnumerateMetafile()                 Calls an application-defined callback function for each record in a specified metafile. You can use this method to display a metafile by calling PlayRecord in the callback function.
    ExcludeClip()                       Updates the clipping region to the portion of itself that does not intersect the specified rectangle.
    ExcludeClip()                       Updates the clipping region to the portion of itself that does not intersect the specified rectangle.
    ExcludeClip()                       Updates the clipping region with the portion of itself that does not overlap the specified region.
    FillClosedCurve()                   Creates a closed cardinal spline from an array of points and uses a brush to fill the interior of the spline.
    FillClosedCurve()                   Creates a closed cardinal spline from an array of points and uses a brush to fill, according to a specified mode, the interior of the spline.
    FillClosedCurve()                   Creates a closed cardinal spline from an array of points and uses a brush to fill the interior of the spline.
    FillClosedCurve()                   Creates a closed cardinal spline from an array of points and uses a brush to fill, according to a specified mode, the interior of the spline.
    FillEllipse()                       Uses a brush to fill the interior of an ellipse that is specified by a rectangle.
    FillEllipse()                       Uses a brush to fill the interior of an ellipse that is specified by a rectangle.
    FillEllipse()                       Uses a brush to fill the interior of an ellipse that is specified by coordinates and dimensions.
    FillEllipse()                       Uses a brush to fill the interior of an ellipse that is specified by coordinates and dimensions.
    FillPath()                          Uses a brush to fill the interior of a path. If a figure in the path is not closed, this method treats the nonclosed figure as if it were closed by a straight line that connects the figure's starting and ending points.
    FillPie()                           Uses a brush to fill the interior of a pie.
    FillPie()                           Uses a brush to fill the interior of a pie.
    FillPie()                           Uses a brush to fill the interior of a pie.
    FillPie()                           Uses a brush to fill the interior of a pie.
    FillPolygon()                       Uses a brush to fill the interior of a polygon.
    FillPolygon()                       Uses a brush to fill the interior of a polygon.
    FillPolygon()                       Uses a brush to fill the interior of a polygon.
    FillPolygon()                       Uses a brush to fill the interior of a polygon.
    FillRectangle()                     Uses a brush to fill the interior of a rectangle.
    FillRectangle()                     Uses a brush to fill the interior of a rectangle.
    FillRectangle()                     Uses a brush to fill the interior of a rectangle.
    FillRectangle()                     Uses a brush to fill the interior of a rectangle.
    FillRectangles()                    Uses a brush to fill the interior of a sequence of rectangles.
    FillRectangles()                    Uses a brush to fill the interior of a sequence of rectangles.
    FillRegion()                        Uses a brush to fill a specified region.
    Flush()                             Flushes all pending graphics operations.
    FromHDC()                           Creates a Graphics object that is associated with a specified device context.
    FromHDC()                           Creates a Graphics object that is associated with a specified device context and a specified device.
    FromHWND()                          Creates a Graphicsobject that is associated with a specified window.
    FromImage()                         Creates a Graphicsobject that is associated with a specified Image object.
    GetClip()                           Gets the clipping region of this Graphics object.
    GetClipBounds()                     Gets a rectangle that encloses the clipping region of this Graphics object.
    GetClipBounds()                     Gets a rectangle that encloses the clipping region of this Graphics object.
    GetCompositingMode()                Gets the compositing mode currently set for this Graphics object.
    GetCompositingQuality()             Gets the compositing quality currently set for this Graphics object.
    GetDpiX()                           Gets the horizontal resolution, in dots per inch, of the display device associated with this Graphics object.
    GetDpiY()                           Gets the vertical resolution, in dots per inch, of the display device associated with this Graphics object.
    GetHalftonePalette()                Gets a Windows halftone palette.
    GetHDC()                            Gets a handle to the device context associated with this Graphics object.
    GetInterpolationMode()              Gets the interpolation mode currently set for this Graphics object. The interpolation mode determines the algorithm that is used when images are scaled or rotated.
    GetLastStatus()                     Returns a value that indicates the nature of this Graphics object's most recent method failure.
    GetNearestColor()                   Gets the nearest color to the color that is passed in. This method works on 8-bits per pixel or lower display devices for which there is an 8-bit color palette.
    GetPageScale()                      Gets the scaling factor currently set for the page transformation of this Graphics object. The page transformation converts page coordinates to device coordinates.
    GetPageUnit()                       Gets the unit of measure currently set for this Graphics object.
    GetPixelOffsetMode()                Gets the pixel offset mode currently set for this Graphics object.
    GetRenderingOrigin()                Gets the rendering origin currently set for this Graphics object.
    GetSmoothingMode()                  Determines whether smoothing (antialiasing) is applied to the Graphics object.
    GetTextContrast()                   Gets the contrast value currently set for this Graphics object. The contrast value is used for antialiasing text.
    GetTextRenderingHint()              Returns the text rendering mode currently set for this Graphics object.
    GetTransform()                      Gets the world transformation matrix of this Graphics object.
    GetVisibleClipBounds()              Gets a rectangle that encloses the visible clipping region of this Graphics object.
    GetVisibleClipBounds()              Gets a rectangle that encloses the visible clipping region of this Graphics object.
    Graphics()                          Lists the constructors of the Graphics class. For a complete class listing, see Graphics Class.
    Graphics()                          Lists the constructors of the Graphics class. For a complete class listing, see Graphics Class.
    Graphics()                          Creates a Graphics object that is associated with a specified device context.
    Graphics()                          Creates a Graphics object that is associated with a specified device context and a specified device.
    Graphics()                          Creates a Graphics object that is associated with a specified window.
    Graphics()                          Creates a Graphics object that is associated with an Image object.
    IntersectClip()                     Updates the clipping region of this Graphics object to the portion of the specified rectangle that intersects with the current clipping region of this Graphics object.
    IntersectClip()                     Updates the clipping region of this Graphics object.
    IntersectClip()                     Updates the clipping region of this Graphics object to the portion of the specified region that intersects with the current clipping region of this Graphics object.
    IsClipEmpty()                       Determines whether the clipping region of this Graphics object is empty.
    IsVisible()                         Determines whether the specified point is inside the visible clipping region of this Graphics object.
    IsVisible()                         Determines whether the specified point is inside the visible clipping region of this Graphics object.
    IsVisible()                         Determines whether the specified rectangle intersects the visible clipping region of this Graphics object.
    IsVisible()                         Determines whether the specified rectangle intersects the visible clipping region of this Graphics object.
    IsVisible()                         Determines whether the specified point is inside the visible clipping region of this Graphics object.
    IsVisible()                         Determines whether the specified rectangle intersects the visible clipping region of this Graphics object.
    IsVisible()                         Determines whether the specified point is inside the visible clipping region of this Graphics object.
    IsVisible()                         Determines whether the specified rectangle intersects the visible clipping region of this Graphics object.
    IsVisibleClipEmpty()                Determines whether the visible clipping region of this Graphics object is empty. The visible clipping region is the intersection of the clipping region of this Graphics object and the clipping region of the window.
    MeasureCharacterRanges()            Gets a set of regions each of which bounds a range of character positions within a string.
    MeasureDriverString()               Measures the bounding box for the specified characters and their corresponding positions.
    MeasureString()                     Measures the extent of the string in the specified font, format, and layout rectangle.
    MeasureString()                     Measures the extent of the string in the specified font and layout rectangle.
    MeasureString()                     Measures the extent of the string in the specified font, format, and layout rectangle.
    MeasureString()                     Measures the extent of the string in the specified font and layout rectangle.
    MeasureString()                     Measures the extent of the string in the specified font, format, and layout rectangle.
    MultiplyTransform()                 Updates this Graphics object's world transformation matrix with the product of itself and another matrix.
    ReleaseHDC()                        Releases a device context handle obtained by a previous call to the Graphics::GetHDC method of this Graphics object.
    ResetClip()                         Sets the clipping region of this Graphics object to an infinite region.
    ResetTransform()                    Sets the world transformation matrix of this Graphics object to the identity matrix.
    Restore()                           Sets the state of this Graphics object to the state stored by a previous call to the Graphics::Save method of this Graphics object.
    RotateTransform()                   Updates the world transformation matrix of this Graphics object with the product of itself and a rotation matrix.
    Save()                              Saves the current state (transformations, clipping region, and quality settings) of this Graphics object. You can restore the state later by calling the Graphics::Restore method.
    ScaleTransform()                    Updates this Graphics object's world transformation matrix with the product of itself and a scaling matrix.
    SetAbort()                          Not used in Windows GDI+ versions 1.0 and 1.1.
    SetClip()                           Updates the clipping region of this Graphics object.
    SetClip()                           Updates the clipping region of this Graphics object to a region that is the combination of itself and the region specified by a graphics path.
    SetClip()                           Updates the clipping region of this Graphics object to a region that is the combination of itself and a rectangle.
    SetClip()                           Updates the clipping region of this Graphics object to a region that is the combination of itself and a rectangle.
    SetClip()                           Updates the clipping region of this Graphics object to a region that is the combination of itself and the region specified by a Region object.
    SetClip()                           Updates the clipping region of this Graphics object to a region that is the combination of itself and a Windows Graphics Device Interface (GDI) region.
    SetCompositingMode()                Sets the compositing mode of this Graphics object.
    SetCompositingQuality()             Sets the compositing quality of this Graphics object.
    SetInterpolationMode()              Sets the interpolation mode of this Graphics object. The interpolation mode determines the algorithm that is used when images are scaled or rotated.
    SetPageScale()                      Sets the scaling factor for the page transformation of this Graphics object. The page transformation converts page coordinates to device coordinates.
    SetPageUnit()                       Sets the unit of measure for this Graphics object. The page unit belongs to the page transformation, which converts page coordinates to device coordinates.
    SetPixelOffsetMode()                Sets the pixel offset mode of this Graphics object.
    SetRenderingOrigin()                Sets the rendering origin of this Graphics object. The rendering origin is used to set the dither origin for 8-bits-per-pixel and 16-bits-per-pixel dithering and is also used to set the origin for hatch brushes.
    SetSmoothingMode()                  Sets the rendering quality of the Graphics object.
    SetTextContrast()                   Sets the contrast value of this Graphics object. The contrast value is used for antialiasing text.
    SetTextRenderingHint()              Sets the text rendering mode of this Graphics object.
    SetTransform()                      Sets the world transformation of this Graphics object.
    TransformPoints()                   Converts an array of points from one coordinate space to another. The conversion is based on the current world and page transformations of this Graphics object.
    TransformPoints()                   Converts an array of points from one coordinate space to another. The conversion is based on the current world and page transformations of this Graphics object.
    TranslateClip()                     Translates the clipping region of this Graphics object.
    TranslateClip()                     Translates the clipping region of this Graphics object.
    TranslateTransform()                Updates this Graphics object's world transformation matrix with the product of itself and a translation matrix.
                                                                                                                                                                                       
GraphicsPath                            Stores a sequence of lines, curves, and shapes. You can also place markers in the sequence, so that you can draw selected portions of the path.
    ::Inherit::                         
    ::Methods::                         
    AddArc()                            Adds an elliptical arc to the current figure of this path.
    AddArc()                            Adds an elliptical arc to the current figure of this path.
    AddArc()                            Adds an elliptical arc to the current figure of this path.
    AddArc()                            Adds an elliptical arc to the current figure of this path.
    AddBezier()                         Adds a Bezier spline to the current figure of this path.
    AddBezier()                         Adds a Bezier spline to the current figure of this path.
    AddBezier()                         Adds a Bezier spline to the current figure of this path.
    AddBezier()                         Adds a Bezier spline to the current figure of this path.
    AddBeziers()                        Adds a sequence of connected Bezier splines to the current figure of this path.
    AddBeziers()                        Adds a sequence of connected Bezier splines to the current figure of this path.
    AddClosedCurve()                    Adds a closed cardinal spline to this path.
    AddClosedCurve()                    Adds a closed cardinal spline to this path.
    AddClosedCurve()                    Adds a closed cardinal spline to this path.
    AddClosedCurve()                    Adds a closed cardinal spline to this path.
    AddCurve()                          Adds a cardinal spline to the current figure of this path.
    AddCurve()                          Adds a cardinal spline to the current figure of this path.
    AddCurve()                          Adds a cardinal spline to the current figure of this path.
    AddCurve()                          Adds a cardinal spline to the current figure of this path.
    AddCurve()                          Adds a cardinal spline to the current figure of this path.
    AddCurve()                          Adds a cardinal spline to the current figure of this path.
    AddEllipse()                        Adds an ellipse to this path.
    AddEllipse()                        Adds an ellipse to this path.
    AddEllipse()                        Adds an ellipse to this path.
    AddEllipse()                        Adds an ellipse to this path.
    AddLine()                           Adds a line to the current figure of this path.
    AddLine()                           Adds a line to the current figure of this path.
    AddLine()                           Adds a line to the current figure of this path.
    AddLine()                           Adds a line to the current figure of this path.
    AddLines()                          Adds a sequence of connected lines to the current figure of this path.
    AddLines()                          Adds a sequence of connected lines to the current figure of this path.
    AddPath()                           Adds a path to this path.
    AddPie()                            Adds a pie to this path.
    AddPie()                            Adds a pie to this path.
    AddPie()                            Adds a pie to this path.
    AddPie()                            Adds a pie to this path.
    AddPolygon()                        Adds a polygon to this path.
    AddPolygon()                        Adds a polygon to this path.
    AddRectangle()                      Adds a rectangle to this path.
    AddRectangle()                      Adds a rectangle to this path.
    AddRectangles()                     Adds a sequence of rectangles to this path
    AddRectangles()                     Adds a sequence of rectangles to this path.
    AddString()                         Adds the outlines of a string to this path.
    AddString()                         Adds the outline of a string to this path.
    AddString()                         Adds the outline of a string to this path.
    AddString()                         Adds the outline of a string to this path.
    ClearMarkers()                      Clears the markers from this path.
    Clone()                             Creates a new GraphicsPath object, and initializes it with the contents of this GraphicsPath object.
    CloseAllFigures()                   Closes all open figures in this path.
    CloseFigure()                       Closes the current figure of this path.
    Flatten()                           Applies a transformation to this path and converts each curve in the path to a sequence of connected lines.
    GetBounds()                         Gets a bounding rectangle for this path.
    GetBounds()                         Gets a bounding rectangle for this path.
    GetFillMode()                       Gets the fill mode of this path.
    GetLastPoint()                      Gets the ending point of the last figure in this path.
    GetLastStatus()                     Returns a value that indicates the nature of this GraphicsPath object's most recent method failure.
    GetPathData()                       Gets an array of points and an array of point types from this path. Together, these two arrays define the lines, curves, figures, and markers of this path.
    GetPathPoints()                     Gets this path's array of points. The array contains the endpoints and control points of the lines and Bezier splines that are used to draw the path.
    GetPathPoints()                     Gets this path's array of points.
    GetPathTypes()                      Gets this path's array of point types.
    GetPointCount()                     Gets the number of points in this path's array of data points. This is the same as the number of types in the path's array of point types.
    GraphicsPath()                      Lists the constructors of the GraphicsPath class. For a complete class listing, see GraphicsPath Class.
    GraphicsPath()                      Creates a GraphicsPath object based on an array of points, an array of types, and a fill mode.
    GraphicsPath()                      Creates a GraphicsPath object based on an array of points, an array of types, and a fill mode.
    GraphicsPath()                      Creates a GraphicsPath object and initializes the fill mode. This is the default constructor.
    GraphicsPath()                      Lists the constructors of the GraphicsPath class. For a complete class listing, see GraphicsPath Class.
    IsOutlineVisible()                  Determines whether a specified point touches the outline of this path when the path is drawn by a specified Graphicsobject and a specified pen.
    IsOutlineVisible()                  Determines whether a specified point touches the outline of a path.
    IsOutlineVisible()                  Determines whether a specified point touches the outline of this path when the path is drawn by a specified Graphics object and a specified pen.
    IsOutlineVisible()                  Determines whether a specified point touches the outline of this path when the path is drawn by a specified Graphics object and a specified pen.
    IsVisible()                         Determines whether a specified point lies in the area that is filled when this path is filled by a specified Graphics object.
    IsVisible()                         Determines whether a specified point lies in an area.
    IsVisible()                         Determines whether a specified point lies in the area that is filled when this path is filled by a specified Graphicsobject.
    IsVisible()                         Determines whether a specified point lies in the area that is filled when this path is filled by a specified Graphics object.
    Outline()                           Transforms and flattens this path, and then converts this path's data points so that they represent only the outline of the path.
    Reset()                             Empties the path and sets the fill mode to FillModeAlternate.
    Reverse()                           Reverses the order of the points that define this path's lines and curves.
    SetFillMode()                       Sets the fill mode of this path.
    SetMarker()                         Designates the last point in this path as a marker point.
    StartFigure()                       Starts a new figure without closing the current figure. Subsequent points added to this path are added to the new figure.
    Transform()                         Multiplies each of this path's data points by a specified matrix.
    Warp()                              Applies a warp transformation to this path. The GraphicsPath::Warp method also flattens (converts to a sequence of straight lines) the path.
    Widen()                             Replaces this path with curves that enclose the area that is filled when this path is drawn by a specified pen. The GraphicsPath::Widen method also flattens the path.
                                                                                                                                                                                       
GraphicsPathIterator                    Provides methods for isolating selected subsets of the path stored in a GraphicsPath object.
    ::Inherit::                         
    ::Methods::                         
    CopyData()                          Copies a subset of the path's data points to a PointF array and copies a subset of the path's point types to a BYTE array.
    Enumerate()                         Copies the path's data points to a PointF array and copies the path's point types to a BYTE array.
    GetCount()                          Returns the number of data points in the path.
    GetLastStatus()                     Returns a value that indicates the nature of this GraphicsPathIterator object's most recent method failure.
    GetSubpathCount()                   Returns the number of subpaths (also called figures) in the path.
    GraphicsPathIterator()              Creates a new GraphicsPathIterator object and associates it with a GraphicsPath object.
    GraphicsPathIterator()              Copy constructor for GraphicsPathIterator.
    HasCurve()                          Determines whether the path has any curves.
    NextMarker()                        Gets the next marker-delimited section of this iterator's associated path.
    NextMarker()                        Gets the starting index and the ending index of a section.
    NextPathType()                      Gets the starting index and the ending index of the next group of data points that all have the same type.
    NextSubpath()                       Gets the next figure (subpath) from this iterator's associated path.
    NextSubpath()                       Gets the starting index and the ending index of the next subpath.
    Rewind()                            Rewinds this iterator to the beginning of its associated path.
                                                                                                                                                                                       
HatchBrush                              Defines a rectangular brush with a hatch style, a foreground color, and a background color. There are six hatch styles.
    ::Inherit::                         The HatchBrush class implements Brush.
    ::Methods::                         
    GetBackgroundColor()                Gets the background color of this hatch brush.
    GetForegroundColor()                Gets the foreground color of this hatch brush.
    GetHatchStyle()                     Gets the hatch style of this hatch brush.
    HatchBrush()                        Copy constructor for HatchBrush.
    HatchBrush()                        Creates a HatchBrush object based on a hatch style, foreground color, and background color.
                                                                                                                                                                                       
HueSaturationLightness                  Enables you to change the hue, saturation, and lightness of a bitmap.
    ::Constructors::                    
    ::Inherit::                         The HueSaturationLightness class implements Effect.
    ::Methods::                         
    GetParameters()                     Gets the current values of the parameters of this HueSaturationLightness object.
    HueSaturationLightness()            Creates a HueSaturationLightness object.
    SetParameters()                     Sets the parameters of this HueSaturationLightness object.
                                                                                                                                                                                       
Image                                   Provides methods for loading and saving raster images (bitmaps) and vector images (metafiles).
    ::Inherit::                         The Image class implements GdiplusBase.
    ::Methods::                         
    Clone()                             Creates a new Image object and initializes it with the contents of this Image object.
    FindFirstItem()                     Retrieves the description and the data size of the first metadata item in this Image object.
    FindNextItem()                      Used along with the Image::FindFirstItem method to enumerate the metadata items stored in this Image object.
    FromFile()                          Creates an Image object based on a file.
    FromStream()                        Creates a new Image object based on a stream.
    GetAllPropertyItems()               Gets all the property items (metadata) stored in this Image object.
    GetBounds()                         Gets the bounding rectangle for this image.
    GetEncoderParameterList()           Gets a list of the parameters supported by a specified image encoder.
    GetEncoderParameterListSize()       Gets the size, in bytes, of the parameter list for a specified image encoder.
    GetFlags()                          Gets a set of flags that indicate certain attributes of this Image object.
    GetFrameCount()                     Gets the number of frames in a specified dimension of this Image object.
    GetFrameDimensionsCount()           Gets the number of frame dimensions in this Image object.
    GetFrameDimensionsList()            Gets the identifiers for the frame dimensions of this Image object.
    GetHeight()                         Gets the image height, in pixels, of this image.
    GetHorizontalResolution()           Gets the horizontal resolution, in dots per inch, of this image.
    GetItemData()                       Gets one piece of metadata from this Image object.
    GetLastStatus()                     Returns a value that indicates the nature of this Image object's most recent method failure.
    GetPalette()                        Gets the ColorPalette of this Image object.
    GetPaletteSize()                    Gets the size, in bytes, of the color palette of this Image object.
    GetPhysicalDimension()              Gets the width and height of this image.
    GetPixelFormat()                    Gets the pixel format of this Image object.
    GetPropertyCount()                  Gets the number of properties (pieces of metadata) stored in this Image object.
    GetPropertyIdList()                 Gets a list of the property identifiers used in the metadata of this Image object.
    GetPropertyItem()                   Gets a specified property item (piece of metadata) from this Image object.
    GetPropertyItemSize()               Gets the size, in bytes, of a specified property item of this Image object.
    GetPropertySize()                   Gets the total size, in bytes, of all the property items stored in this Image object. The Image::GetPropertySize method also gets the number of property items stored in this Image object.
    GetRawFormat()                      Gets a globally unique identifier ( GUID) that identifies the format of this Image object. GUIDs that identify various file formats are defined in Gdiplusimaging.h.
    GetThumbnailImage()                 Gets a thumbnail image from this Image object.
    GetType()                           Gets the type (bitmap or metafile) of this Image object.
    GetVerticalResolution()             Gets the vertical resolution, in dots per inch, of this image.
    GetWidth()                          Gets the width, in pixels, of this image.
    Image()                             Lists the constructors of the Image class. For a complete class listing, see Image Class.
    Image()                             Creates an Image object based on a file.
    Image()                             Lists the constructors of the Image class. For a complete class listing, see Image Class.
    Image()                             Creates an Image object based on a stream.
    Image()                             Lists the constructors of the Image class. For a complete class listing, see Image Class.
    RemovePropertyItem()                Removes a property item (piece of metadata) from this Image object.
    RotateFlip()                        Rotates and flips this image.
    Save()                              Saves this image to a file.
    Save()                              Saves this image to a stream.
    SaveAdd()                           Adds a frame to a file or stream specified in a previous call to the Save method.
    SaveAdd()                           Adds a frame to a file or stream specified in a previous call to the Save method.
    SelectActiveFrame()                 Selects the frame in this Image object specified by a dimension and an index.
    SetAbort()                          Sets the object whose Abort method is called periodically during time-consuming rendering operation.
    SetPalette()                        Sets the color palette of this Image object.
    SetPropertyItem()                   Sets a property item (piece of metadata) for this Image object. If the item already exists, then its contents are updated; otherwise, a new item is added.
                                                                                                                                                                                   
ImageAttributes                         Contains information about how bitmap and metafile colors are manipulated during rendering.                                                                    
    ::Inherit::                         The ImageAttributes class implements GdiplusBase.
    ::Methods::                         
    ClearBrushRemapTable()              Clears the brush color-remap table of this ImageAttributes object.
    ClearColorKey()                     Clears the color key (transparency range) for a specified category.
    ClearColorMatrices()                Clears the color-adjustment matrix and the grayscale-adjustment matrix for a specified category.
    ClearColorMatrix()                  Clears the color-adjustment matrix for a specified category.
    ClearGamma()                        Disables gamma correction for a specified category.
    ClearNoOp()                         Clears the NoOp setting for a specified category.
    ClearOutputChannel()                Clears the cyan-magenta-yellow-black (CMYK) output channel setting for a specified category.
    ClearOutputChannelColorProfile()    Clears the output channel color profile setting for a specified category.
    ClearRemapTable()                   Clears the color-remap table for a specified category.
    ClearThreshold()                    Clears the threshold value for a specified category.
    Clone()                             Makes a copy of this ImageAttributes object.
    GetAdjustedPalette()                Adjusts the colors in a palette according to the adjustment settings of a specified category.
    GetLastStatus()                     Returns a value that indicates the nature of this ImageAttributes object's most recent method failure.
    ImageAttributes()                   Creates an ImageAttributes object. This is the default constructor.
    ImageAttributes()                   Creates an ImageAttributes object. This is the default constructor.
    ImageAttributes()                   Creates an ImageAttributes object. This is the default constructor.
    Reset()                             Clears all color- and grayscale-adjustment settings for a specified category.
    SetBrushRemapTable()                Sets the color remap table for the brush category.
    SetColorKey()                       Sets the color key (transparency range) for a specified category.
    SetColorMatrices()                  Sets the color-adjustment matrix and the grayscale-adjustment matrix for a specified category.
    SetColorMatrix()                    Sets the color-adjustment matrix for a specified category.
    SetGamma()                          Sets the gamma value for a specified category.
    SetNoOp()                           Turns off color adjustment for a specified category. You can call ImageAttributes::ClearNoOp to reinstate the color-adjustment settings that were in place before the call to ImageAttributes::SetNoOp.
    SetOutputChannel()                  Sets the CMYK output channel for a specified category.
    SetOutputChannelColorProfile()      Sets the output channel color-profile file for a specified category.
    SetRemapTable()                     Sets the color-remap table for a specified category.
    SetThreshold()                      Sets the threshold (transparency range) for a specified category.
    SetToIdentity()                     Sets the color-adjustment matrix of a specified category to identity matrix.
    SetWrapMode()                       Sets the wrap mode of this ImageAttributes object.
                                                                                                                                                                               
ImageCodecInfo                          Stores information about an image codec (encoder/decoder). GDI+ provides several built-in image codecs.                                                               
    ::Methods::                         
                                                                                                                                                                               
ImageItemData                           Used to store and retrieve custom image metadata. Windows GDI+ supports custom metadata for JPEG, PNG, and GIF image files.                                                              
    ::Methods::                         
                                                                                                                                                                               
InstalledFontCollection                                                                                         
    ::Inherit::                         The InstalledFontCollection class implements FontCollection.                                                                                                                                                      
    ::Methods::                         
    InstalledFontCollection()           Creates an InstalledFontCollection object.
    InstalledFontCollection()           Creates an InstalledFontCollection object.
                                                                                                                                                                               
Levels                                  Encompasses three bitmap adjustments: highlight, midtone, and shadow.                                                       
    ::Inherit::                         The Levels class implements Effect.                                                                                                                                                      
    ::Methods::                         
    GetParameters()                     Gets the current values of the parameters of this Levels object.
    Levels()                            Creates a Levels object.
    SetParameters()                     Sets the parameters of this Levels object.

LinearGradientBrush                     Defines a brush that paints a color gradient in which the color changes evenly from the starting boundary line of the linear gradient brush to the ending boundary line of the linear gradient brush.                                                                    
    ::Inherit::                         The LinearGradientBrush class implements Brush.
    ::Methods::                         
    GetBlend()                          Gets the blend factors and their corresponding blend positions from a LinearGradientBrush object.
    GetBlendCount()                     Gets the number of blend factors currently set for this LinearGradientBrush object.
    GetGammaCorrection()                Determines whether gamma correction is enabled for this LinearGradientBrush object.
    GetInterpolationColorCount()        Gets the number of colors currently set to be interpolated for this linear gradient brush.
    GetInterpolationColors()            Gets the colors currently set to be interpolated for this linear gradient brush and their corresponding blend positions.
    GetLinearColors()                   Gets the starting color and ending color of this linear gradient brush.
    GetRectangle()                      Gets the rectangle that defines the boundaries of the gradient.
    GetRectangle()                      Lists the GetRectangle methods of the LinearGradientBrush class. For a complete list of methods for the LinearGradientBrush class, see LinearGradientBrush Methods.
    GetTransform()                      Gets the transformation matrix of this linear gradient brush.
    GetWrapMode()                       Gets the wrap mode for this brush. The wrap mode determines how an area is tiled when it is painted with a brush.
    LinearGradientBrush()               Lists the constructors of the LinearGradientBrush class. For a complete class listing, see LinearGradientBrush Class.
    LinearGradientBrush()               Lists the constructors of the LinearGradientBrush class. For a complete class listing, see LinearGradientBrush Class.
    LinearGradientBrush()               Creates a LinearGradientBrush object from a set of boundary points and boundary colors.
    LinearGradientBrush()               Creates a LinearGradientBrush object based on a rectangle and mode of direction.
    LinearGradientBrush()               Creates a LinearGradientBrush object from a rectangle and angle of direction.
    LinearGradientBrush()               Creates a LinearGradientBrush object based on a rectangle and mode of direction.
    LinearGradientBrush()               Creates a LinearGradientBrush object from a rectangle and angle of direction.
    LinearGradientBrush()               Lists the constructors of the LinearGradientBrush class. For a complete class listing, see LinearGradientBrush Class.
    MultiplyTransform()                 Updates this brush's transformation matrix with the product of itself and another matrix.
    ResetTransform()                    Resets the transformation matrix of this linear gradient brush to the identity matrix. This means that no transformation takes place.
    RotateTransform()                   Updates this brush's current transformation matrix with the product of itself and a rotation matrix.
    ScaleTransform()                    Updates this brush's current transformation matrix with the product of itself and a scaling matrix.
    SetBlend()                          Sets the blend factors and the blend positions of this linear gradient brush to create a custom blend.
    SetBlendBellShape()                 Sets the blend shape of this linear gradient brush to create a custom blend based on a bell-shaped curve.
    SetBlendTriangularShape()           Sets the blend shape of this linear gradient brush to create a custom blend based on a triangular shape.
    SetGammaCorrection()                Specifies whether gamma correction is enabled for this linear gradient brush.
    SetInterpolationColors()            Sets the colors to be interpolated for this linear gradient brush and their corresponding blend positions.
    SetLinearColors()                   Sets the starting color and ending color of this linear gradient brush.
    SetTransform()                      Sets the transformation matrix of this linear gradient brush.
    SetWrapMode()                       Sets the wrap mode of this linear gradient brush.
    TranslateTransform()                Updates this brush's current transformation matrix with the product of itself and a translation matrix.

Matrix                                  Represents a 3 ×3 matrix that, in turn, represents an affine transformation.
    ::Inherit::                         The Matrix class implements GdiplusBase.
    ::Methods::                         
    Clone()                             Creates a new Matrix object that is a copy of this Matrix object.
    Equals()                            Determines whether the elements of this matrix are equal to the elements of another matrix.
    GetElements()                       Gets the elements of this matrix. The elements are placed in an array in the order m11, m12, m21, m22, m31, m32, where mij denotes the element in row i, column j.
    GetLastStatus()                     Returns a value that indicates the nature of this Matrix object's most recent method failure.
    Invert()                            Replaces the elements of this matrix with the elements of its inverse, if this matrix is invertible.
    IsIdentity()                        Determines whether this matrix is the identity matrix.
    IsInvertible()                      Determines whether this matrix is invertible.
    Matrix()                            Creates and initializes a Matrix object that represents the identity matrix.
    Matrix()                            Creates and initializes a Matrix object that represents the identity matrix.
    Matrix()                            Creates a Matrix object based on a rectangle and a point.
    Matrix()                            Creates a Matrix object based on a rectangle and a point.
    Matrix()                            Creates and initializes a Matrix object that represents the identity matrix.
    Matrix()                            Creates and initializes a Matrix object based on six numbers that define an affine transformation.
    Multiply()                          Updates this matrix with the product of itself and another matrix.
    OffsetX()                           Gets the horizontal translation value of this matrix, which is the element in row 3, column 1.
    OffsetY()                           Gets the vertical translation value of this matrix, which is the element in row 3, column 2.
    Reset()                             Updates this matrix with the elements of the identity matrix.
    Rotate()                            Updates this matrix with the product of itself and a rotation matrix.
    RotateAt()                          Updates this matrix with the product of itself and a matrix that represents rotation about a specified point.
    Scale()                             Updates this matrix with the product of itself and a scaling matrix.
    SetElements()                       Sets the elements of this matrix.
    Shear()                             Updates this matrix with the product of itself and a shearing matrix.
    TransformPoints()                   Multiplies each point in an array by this matrix. Each point is treated as a row matrix. The multiplication is performed with the row matrix on the left and this matrix on the right.
    TransformPoints()                   Lists the TransformPoints methods of the Matrix class. For a complete list of methods for the Matrix class, see Matrix Methods.
    TransformVectors()                  Multiplies each vector in an array by this matrix.
    TransformVectors()                  Lists the TransformVectors methods of the Matrix class. For a complete list of methods for the Matrix class, see Matrix Methods.
    Translate()                         Updates this matrix with the product of itself and a translation matrix.
                                                                                                                                                                               
Metafile                                Defines a graphic metafile.
    ::Inherit::                         The Metafile class implements Image.
    ::Methods::                         
    ConvertToEmfPlus()                  Converts this Metafile object to the EMF+ format.
    ConvertToEmfPlus()                  Converts this Metafile object to the EMF+ format.
    ConvertToEmfPlus()                  Converts this Metafile object to the EMF+ format.
    EmfToWmfBits()                      Converts an enhanced-format metafile to a Windows Metafile Format (WMF) metafile and stores the converted records in a specified buffer.
    GetDownLevelRasterizationLimit()    Gets the rasterization limit currently set for this metafile.
    GetHENHMETAFILE()                   Gets a Windows handle to an Enhanced Metafile (EMF) file.
    GetMetafileHeader()                 Gets the header.
    GetMetafileHeader()                 Gets the header.
    GetMetafileHeader()                 Gets the metafile header of this metafile.
    GetMetafileHeader()                 Gets the header.
    GetMetafileHeader()                 Gets the header.
    Metafile()                          Lists the constructors of the Metafile class. For a complete class listing, see Metafile Class.
    Metafile()                          Creates a Metafile object for playback.
    Metafile()                          Lists the constructors of the Metafile class. For a complete class listing, see Metafile Class.
    Metafile()                          Creates a Metafile object for recording.
    Metafile()                          Creates a Metafile object for recording.
    Metafile()                          Creates a Metafile object for recording.
    Metafile()                          Creates a Metafile object for recording.
    Metafile()                          Creates a Metafile object for recording.
    Metafile()                          Creates a Metafile object for recording.
    Metafile()                          Creates a Windows GDI+ Metafile object for playback based on a Windows Graphics Device Interface (GDI) Enhanced Metafile (EMF) file.
    Metafile()                          Creates a Windows GDI+Metafile object for recording. The format will be placeable metafile.
    Metafile()                          Creates a Metafile object from an IStream interface for playback.
    Metafile()                          Creates a Metafile object for recording to an IStream interface.
    Metafile()                          Creates a Metafile object for recording to an IStream interface.
    Metafile()                          Creates a Metafile object for recording to an IStream interface.
    Metafile()                          Lists the constructors of the Metafile class. For a complete class listing, see Metafile Class.
    PlayRecord()                        The PlayRecord method plays a metafile record.
    SetDownLevelRasterizationLimit()    Sets the resolution for certain brush bitmaps that are stored in this metafile.
                                                                                                                                                                               
MetafileHeader                          Stores properties of an associated metafile.
    ::Methods::                         
    GetBounds()                         Gets the bounding rectangle for the associated metafile.
    GetDpiX()                           Gets the horizontal dots per inch of the associated metafile.
    GetDpiY()                           Gets the vertical dots per inch of the associated metafile.
    GetEmfHeader()                      Gets an ENHMETAHEADER3 structure that contains properties of the associated metafile.
    GetEmfPlusFlags()                   Gets a flag that indicates whether the associated metafile was recorded against a video display device context.
    GetMetafileSize()                   Gets the size, in bytes, of the metafile.
    GetType()                           Gets the type of the associated metafile.
    GetVersion()                        Gets the version of the metafile.
    GetWmfHeader()                      Gets a METAHEADER structure that contains properties of the associated metafile.
    IsDisplay()                         Determines whether the associated metafile was recorded against a video display device context.
    IsEmf()                             Determines whether the associated metafile is in the EMF format.
    IsEmfOrEmfPlus()                    Determines whether the associated metafile is in either the EMF or EMF+ format.
    IsEmfPlus()                         Determines whether the associated metafile is in the EMF+ format.
    IsEmfPlusDual()                     Determines whether the associated metafile is in the EMF+ Dual format.
    IsEmfPlusOnly()                     Determines whether the associated metafile is in the EMF+ Only format.
    IsWmf()                             Determines whether the associated metafile is in the WMF format.
    IsWmfPlaceable()                    Determines whether the associated metafile is a placeable metafile.

PathData                                Get or set the data points (and their types) of a path. Helper class for the GraphicsPath and GraphicsPathIterator classes.
    ::Methods::                         
    ~PathData()                         Destructor for the PathData class.
    PathData()                          Creates a PathData object. The Count data member is initialized to 0. Points and Types data members are initialized to NULL.
                                                                                                                                                                               
PathGradientBrush                       Stores the attributes of a color gradient that you can use to fill the interior of a path with a gradually changing color.
    ::Inherit::                         The PathGradientBrush class implements Brush.
    ::Methods::                         
    GetBlend()                          Gets the blend factors and the corresponding blend positions currently set for this path gradient brush.
    GetBlendCount()                     Gets the number of blend factors currently set for this path gradient brush.
    GetCenterColor()                    Gets the color of the center point of this path gradient brush.
    GetCenterPoint()                    Gets the center point of this path gradient brush.
    GetCenterPoint()                    Gets the center point of this path gradient brush.
    GetFocusScales()                    Gets the focus scales of this path gradient brush.
    GetGammaCorrection()                Determines whether gamma correction is enabled for this path gradient brush.
    GetGraphicsPath()                   Is not implemented in Windows GDI+ version 1.0.
    GetInterpolationColorCount()        Gets the number of preset colors currently specified for this path gradient brush.
    GetInterpolationColors()            Gets the preset colors and blend positions currently specified for this path gradient brush.
    GetPointCount()                     Gets the number of points in the array of points that defines this brush's boundary path.
    GetRectangle()                      Gets the smallest rectangle that encloses the boundary path of this path gradient brush.
    GetRectangle()                      Gets the smallest rectangle that encloses the boundary path of this path gradient brush.
    GetSurroundColorCount()             Gets the number of colors that have been specified for the boundary path of this path gradient brush.
    GetSurroundColors()                 Gets the surround colors currently specified for this path gradient brush.
    GetTransform()                      Gets transformation matrix of this path gradient brush.
    GetWrapMode()                       Gets the wrap mode currently set for this path gradient brush.
    MultiplyTransform()                 Updates the brush's transformation matrix with the product of itself and another matrix.
    PathGradientBrush()                 Creates a PathGradientBrush object based on a GraphicsPath object.
    PathGradientBrush()                 Lists the constructors of the PathGradientBrush class. For a complete class listing, see PathGradientBrushXX Class.
    PathGradientBrush()                 Creates a PathGradientBrush object based on an array of points. Initializes the wrap mode of the path gradient brush.
    PathGradientBrush()                 Creates a PathGradientBrush object based on an array of points. Initializes the wrap mode of the path gradient brush.
    PathGradientBrush()                 Lists the constructors of the PathGradientBrush class. For a complete class listing, see PathGradientBrushXX Class.
    ResetTransform()                    Resets the transformation matrix of this path gradient brush to the identity matrix. This means that no transformation will take place.
    RotateTransform()                   Updates this brush's current transformation matrix with the product of itself and a rotation matrix.
    ScaleTransform()                    Updates this brush's current transformation matrix with the product of itself and a scaling matrix.
    SetBlend()                          Sets the blend factors and the blend positions of this path gradient brush.
    SetBlendBellShape()                 Sets the blend shape of this path gradient brush.
    SetBlendTriangularShape()           Sets the blend shape of this path gradient brush.
    SetCenterColor()                    Sets the center color of this path gradient brush. The center color is the color that appears at the brush's center point.
    SetCenterPoint()                    Sets the center point of this path gradient brush. By default, the center point is at the centroid of the brush's boundary path, but you can set the center point to any location inside or outside the path.
    SetCenterPoint()                    Sets the center point of this path gradient brush.
    SetFocusScales()                    Sets the focus scales of this path gradient brush.
    SetGammaCorrection()                Specifies whether gamma correction is enabled for this path gradient brush.
    SetGraphicsPath()                   Is not implemented in Windows GDI+ version 1.0.
    SetInterpolationColors()            Sets the preset colors and the blend positions of this path gradient brush.
    SetSurroundColors()                 Sets the surround colors of this path gradient brush. The surround colors are colors specified for discrete points on the brush's boundary path.
    SetTransform()                      Sets the transformation matrix of this path gradient brush.
    SetWrapMode()                       Sets the wrap mode of this path gradient brush.
    TranslateTransform()                Updates this brush's current transformation matrix with the product of itself and a translation matrix.
                                        
Pen                                     A Windows GDI+ object used to draw lines and curves
    ::Inherit::                         The Pen class implements GdiplusBase.
    ::Methods::                         
    Clone()                             Copies a Pen object.
    GetAlignment()                      Gets the alignment currently set for this Pen object.
    GetBrush()                          Gets the Brush object that is currently set for this Pen object.
    GetColor()                          Gets the color currently set for this Pen object.
    GetCompoundArray()                  Gets the compound array currently set for this Pen object.
    GetCompoundArrayCount()             Gets the number of elements in a compound array.
    GetCustomEndCap()                   Gets the custom end cap currently set for this Pen object.
    GetCustomStartCap()                 Gets the custom start cap currently set for this Pen object.
    GetDashCap()                        Gets the dash cap style currently set for this Pen object.
    GetDashOffset()                     Gets the distance from the start of the line to the start of the first space in a dashed line.
    GetDashPattern()                    Gets an array of custom dashes and spaces currently set for this Pen object.
    GetDashPatternCount()               Gets the number of elements in a dash pattern array.
    GetDashStyle()                      Gets the dash style currently set for this Pen object.
    GetEndCap()                         Gets the end cap currently set for this Pen object.
    GetLastStatus()                     Returns a value that indicates the nature of this Pen object's most recent method failure.
    GetLineJoin()                       Gets the line join style currently set for this Pen object.
    GetMiterLimit()                     Gets the miter length currently set for this Pen object.
    GetPenType()                        Gets the type currently set for this Pen object.
    GetStartCap()                       Gets the start cap currently set for this Pen object.
    GetTransform()                      Gets the world transformation matrix currently set for this Pen object.
    GetWidth()                          Gets the width currently set for this Pen object.
    MultiplyTransform()                 Updates the world transformation matrix of this Pen object with the product of itself and another matrix.
    Pen()                               Creates a Pen object that uses the attributes of a brush and a real number to set the width of this Pen object.
    Pen()                               Creates a Pen object that uses a specified color and width.
    Pen()                               Lists the constructors of the Pen class. For a complete class listing, see Pen Class.
    Pen()                               Lists the constructors of the Pen class. For a complete class listing, see Pen Class.
    ResetTransform()                    Sets the world transformation matrix of this Pen object to the identity matrix.
    RotateTransform()                   Updates the world transformation matrix of this Pen object with the product of itself and a rotation matrix.
    ScaleTransform()                    Sets the Pen object's world transformation matrix equal to the product of itself and a scaling matrix.
    SetAlignment()                      Sets the alignment for this Pen object relative to the line.
    SetBrush()                          Sets the Brush object that a pen uses to fill a line.
    SetColor()                          Sets the color for this Pen object.
    SetCompoundArray()                  Sets the compound array for this Pen object.
    SetCustomEndCap()                   Sets the custom end cap for this Pen object.
    SetCustomStartCap()                 Sets the custom start cap for this Pen object.
    SetDashCap()                        Sets the dash cap style for this Pen object.
    SetDashOffset()                     Sets the distance from the start of the line to the start of the first dash in a dashed line.
    SetDashPattern()                    Sets an array of custom dashes and spaces for this Pen object.
    SetDashStyle()                      Sets the dash style for this Pen object.
    SetEndCap()                         Sets the end cap for this Pen object.
    SetLineCap()                        Sets the cap styles for the start, end, and dashes in a line drawn with this pen.
    SetLineJoin()                       Sets the line join for this Pen object.
    SetMiterLimit()                     Sets the miter limit of this Pen object.
    SetStartCap()                       Sets the start cap for this Pen object.
    SetTransform()                      Sets the world transformation of this Pen object.
    SetWidth()                          Sets the width for this Pen object.
                                        
Point                                   Encapsulates a point in a 2-D coordinate system.
    ::Constructors::                    
    Point()                             Creates a Point object. Initializes X and Y data to zero. This is the default constructor.
    Point(INT,INT)                      Creates a Point object. Initialize the X and Y data members using passed values.
    Point(Point&)                       Creates a new Point object by copying the data members from another Point object.
    Point(Size&)                        Creates a Point object using a Size object to initialize the X and Y data members.
    ::Methods::                         
    Equals                              The Point::Equals method determines whether two Point objects are equal. Two points are considered equal if they have the same X and Y data members.
    operator-(Point&)                   The Point::operator- method subtracts the X and Y data members of two Point objects.
    operator+(Point&)                   The Point::operator+ method adds the X and Y data members of two Point objects.
                                        
PointF                                  
    ::Constructors::                    
    PointF()                            Creates a PointF object and initializes the X and Y data members to zero. This is the default constructor.
    PointF(PointF&)                     Creates a new PointF object and copies the data from another PointF object.
    PointF(REAL,REAL)                   Creates a PointF object using two real numbers to specify the X and Y data members.
    PointF(SizeF&)                      Creates a PointF object using a SizeF object to specify the X and Y data members.
    ::Methods::                         
    Equals                              Determines whether two PointF objects are equal. Two points are considered equal if they have the same X and Y data members.
    operator-(PointF&)                  Subtracts the X and Y data members of two PointF objects.
    operator+(PointF&)                  Adds the X and Y data members of two PointF objects.
                                        
PrivateFontCollection                   Keeps a collection of fonts specifically for an application.
    ::Inherit::                         The PrivateFontCollection class implements FontCollection.
    ::Methods::                         
    AddFontFile()                       Adds a font file to this private font collection.
    AddMemoryFont()                     Adds a font that is contained in system memory to a Windows GDI+ font collection.
    PrivateFontCollection()             Creates an empty PrivateFontCollection object.
    PrivateFontCollection()             Creates an empty PrivateFontCollection object.

PropertyItem                            A PropertyItem object holds one piece of image metadata and is a helper class for the Image and Bitmap classes.
    ::Inherit::                         
    ::Constructors::                    
    ::Methods::                         
                                        
Rect                                    
    ::Inherit::                         
    ::Constructors::                    
    ::Methods::                         
                                        
RectF                                   
    ::Inherit::                         
    ::Constructors::                    
    ::Methods::                         
                                        
RedEyeCorrection                        
    ::Inherit::                         
    ::Constructors::                    
    ::Methods::                         
                                                                                                                                                                               
Region                                                                                         
    ::Constructors::                    
    ::Inherit::                         
    ::Methods::                         
                                                                                                                                                                               
Sharpen                                                                                         
    ::Constructors::                    
    ::Inherit::                         
    ::Methods::                         
                                                                                                                                                                               
Size                                                                                         
    ::Constructors::                    
    ::Inherit::                         
    ::Methods::                         
                                                                                                                                                                               
SizeF                                                                                         
    ::Constructors::                    
    ::Inherit::                         
    ::Methods::                         
                                                                                                                                                                               
SolidBrush                                                                                         
    ::Constructors::                    
    ::Inherit::                         
    ::Methods::                         
                                                                                                                                                                               
StringFormat                                                                                         
    ::Constructors::                    
    ::Inherit::                         
    ::Methods::                         
                                                                                                                                                                               
TextureBrush                                                                                         
    ::Constructors::                    
    ::Inherit::                         
    ::Methods::                         
                                                                                                                                                                               
Tint                                                                                         
    ::Constructors::                    
    ::Inherit::                         
    ::Methods::                         
                 
*/
