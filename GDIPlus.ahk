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
        Redid entire Rect/Point/Size classes
            Removed float variants and added .Struct(type) method
                type can be whatever type you need. Int, Float, Etc.
        Finished Color Class (ARGB)
        Collected MetaHeader 
        Started on gdiplusimaging
    20210816
        Added colormatrix.h info
        Addded imaging.h info
            Incomplete
        Started GUID class
        Started on effects class
            This is what spawned the need for a GUID Class
    20210817
        Finished GUID class
    20210818
        Worked heavily on effect class and the 11 related effect classes
    20210819
        Did more work on graphics class
    20210820
        Graphics Class is now Grafixed and working!!
    20210821
        Started work on the Pen class.
        Updated the Color class and added some methods.
    20210821
        Reformatted and organized all the color constants
            Colors are broken up by general color and alphabetized
    20210822
        Colors class finished and tested
        Pen class progress

*/

#Warn
GDIP.Startup()

MsgBox, % GDIP.Color.Black
ExitApp

Class GDIP
{
    Static  gdip_token  := ""
            ,_version   := 1.0
    
    ;####################################################################################################################
    ; STATUS ENUMERATION - This defines all possible status enumeration return types you might encounter                |
    ;                      Any function with a status return type references this. 0 is OK. Anything > 0 is an error.   |
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
        this.GdiplusStartup()
        GDIP.TypeDef._Create()                          ; Create typedefs
        GDIP.generate_colorName()                       ; Generate color object
        GDIP.Effect._generate_guids()                   ; Creates GUIDs needed for effect objects
        ;add other generators here
    }
    
    ExitGDIP()
    {
         this.GdiplusShutdown()
        ,this.gdip_token := ""
        Return
    }
    
    GdiplusStartup()
    {
        If (this.gdip_token = "")
            ; Check if GDIPlus been loaded into Window's library
            DllCall("GetModuleHandle", "str", "gdiplus") ? "" : DllCall("LoadLibrary", "str", "gdiplus")
            ,VarSetCapacity(token, A_PtrSize)
            ,VarSetCapacity(gdip_si, (A_PtrSize = 8) ? 24 : 16, 0)
            ,NumPut(1, gdip_si)
            ,estat := DllCall("gdiplus\GdiplusStartup"
                             ,this.PtrA , token      ; Variable to receive pointer to token
                             ,this.Ptr  , &gdip_si   ; Startup Input
                             ,this.Ptr  , 0)         ; Startup Output 0 = null
            ,this.gdip_token := token
        
        (estat > 0)   ; Error checking
            ? GDIP.error_log(A_ThisFunc, "Startup has failed.", "Estat Error: " estat , {estat:estat})
            : ""
    }
    
    GdiplusShutdown()
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
    
    Enum(name, ID)
    {
        Return GDIP.Enumerations[name][ID]
    }
    
    ;####################################################################################################################
    ;  TYPEDEF CLASS                                                                                                    |
    ;####################################################################################################################
    ; Responsible for tracking all the different var types there are in GDIPlus
    Class TypeDef
    {
        Static GraphicsState     := "UInt"
             , GraphicsContainer := "UInt"
             , REAL              := "Float"
    }
    
    ;####################################################################################################################
    ;  DEFINED CLASS                                                                                                    |
    ;####################################################################################################################
    ; Responsible for tracking all the different var types there are in GDIPlus
    Class DEFINE
    {
        Static GDIP_EMFPLUS_RECORD_BASE  := 0x4000
        Static GDIP_WMF_RECORD_BASE      := 0x10000
        Static GDIP_EMFPLUSFLAGS_DISPLAY := 0x1
        
        ;---------------------------------------------------------------------------
        ; Image property types 
        ;---------------------------------------------------------------------------
        Static PropertyTagTypeByte      := 1
             , PropertyTagTypeASCII     := 2
             , PropertyTagTypeShort     := 3
             , PropertyTagTypeLong      := 4
             , PropertyTagTypeRational  := 5
             , PropertyTagTypeUndefined := 7
             , PropertyTagTypeSLONG     := 9
             , PropertyTagTypeSRational := 10
        
        ;---------------------------------------------------------------------------
        ; Image property ID tags
        ;---------------------------------------------------------------------------
        
        Static PropertyTagExifIFD               := 0x8769
             , PropertyTagGpsIFD                := 0x8825
             , PropertyTagNewSubfileType        := 0x00FE
             , PropertyTagSubfileType           := 0x00FF
             , PropertyTagImageWidth            := 0x0100
             , PropertyTagImageHeight           := 0x0101
             , PropertyTagBitsPerSample         := 0x0102
             , PropertyTagCompression           := 0x0103
             , PropertyTagPhotometricInterp     := 0x0106
             , PropertyTagThreshHolding         := 0x0107
             , PropertyTagCellWidth             := 0x0108
             , PropertyTagCellHeight            := 0x0109
             , PropertyTagFillOrder             := 0x010A
             , PropertyTagDocumentName          := 0x010D
             , PropertyTagImageDescription      := 0x010E
             , PropertyTagEquipMake             := 0x010F
             , PropertyTagEquipModel            := 0x0110
             , PropertyTagStripOffsets          := 0x0111
             , PropertyTagOrientation           := 0x0112
             , PropertyTagSamplesPerPixel       := 0x0115
             , PropertyTagRowsPerStrip          := 0x0116
             , PropertyTagStripBytesCount       := 0x0117
             , PropertyTagMinSampleValue        := 0x0118
             , PropertyTagMaxSampleValue        := 0x0119
             , PropertyTagXResolution           := 0x011A   ; Image resolution in width direction
             , PropertyTagYResolution           := 0x011B   ; Image resolution in height direction
             , PropertyTagPlanarConfig          := 0x011C   ; Image data arrangement
             , PropertyTagPageName              := 0x011D
             , PropertyTagXPosition             := 0x011E
             , PropertyTagYPosition             := 0x011F
             , PropertyTagFreeOffset            := 0x0120
             , PropertyTagFreeByteCounts        := 0x0121
             , PropertyTagGrayResponseUnit      := 0x0122
             , PropertyTagGrayResponseCurve     := 0x0123
             , PropertyTagT4Option              := 0x0124
             , PropertyTagT6Option              := 0x0125
             , PropertyTagResolutionUnit        := 0x0128   ; Unit of X and Y resolution
             , PropertyTagPageNumber            := 0x0129
             , PropertyTagTransferFuncition     := 0x012D
             , PropertyTagSoftwareUsed          := 0x0131
             , PropertyTagDateTime              := 0x0132
             , PropertyTagArtist                := 0x013B
             , PropertyTagHostComputer          := 0x013C
             , PropertyTagPredictor             := 0x013D
             , PropertyTagWhitePoint            := 0x013E
             , PropertyTagPrimaryChromaticities := 0x013F
             , PropertyTagColorMap              := 0x0140
             , PropertyTagHalftoneHints         := 0x0141
             , PropertyTagTileWidth             := 0x0142
             , PropertyTagTileLength            := 0x0143
        Static PropertyTagTileOffset            := 0x0144
             , PropertyTagTileByteCounts        := 0x0145
             , PropertyTagInkSet                := 0x014C
             , PropertyTagInkNames              := 0x014D
             , PropertyTagNumberOfInks          := 0x014E
             , PropertyTagDotRange              := 0x0150
             , PropertyTagTargetPrinter         := 0x0151
             , PropertyTagExtraSamples          := 0x0152
             , PropertyTagSampleFormat          := 0x0153
             , PropertyTagSMinSampleValue       := 0x0154
             , PropertyTagSMaxSampleValue       := 0x0155
             , PropertyTagTransferRange         := 0x0156
        
        Static PropertyTagJPEGProc               := 0x200
             , PropertyTagJPEGInterFormat        := 0x201
             , PropertyTagJPEGInterLength        := 0x202
             , PropertyTagJPEGRestartInterval    := 0x203
             , PropertyTagJPEGLosslessPredictors := 0x205
             , PropertyTagJPEGPointTransforms    := 0x206
             , PropertyTagJPEGQTables            := 0x207
             , PropertyTagJPEGDCTables           := 0x208
             , PropertyTagJPEGACTables           := 0x209
        
        Static PropertyTagYCbCrCoefficients    := 0x0211
             , PropertyTagYCbCrSubsampling     := 0x0212
             , PropertyTagYCbCrPositioning     := 0x0213
             , PropertyTagREFBlackWhite        := 0x0214
             , PropertyTagICCProfile           := 0x8773   ; This TAG is defined by ICC for embedded ICC in TIFF
             , PropertyTagGamma                := 0x0301
             , PropertyTagICCProfileDescriptor := 0x0302
             , PropertyTagSRGBRenderingIntent  := 0x0303
             , PropertyTagImageTitle           := 0x0320
             , PropertyTagCopyright            := 0x8298
        
        ; Extra TAGs (Like Adobe Image Information tags etc.)
        Static PropertyTagResolutionXUnit           := 0x5001
             , PropertyTagResolutionYUnit           := 0x5002
             , PropertyTagResolutionXLengthUnit     := 0x5003
             , PropertyTagResolutionYLengthUnit     := 0x5004
             , PropertyTagPrintFlags                := 0x5005
             , PropertyTagPrintFlagsVersion         := 0x5006
             , PropertyTagPrintFlagsCrop            := 0x5007
             , PropertyTagPrintFlagsBleedWidth      := 0x5008
             , PropertyTagPrintFlagsBleedWidthScale := 0x5009
             , PropertyTagHalftoneLPI               := 0x500A
             , PropertyTagHalftoneLPIUnit           := 0x500B
             , PropertyTagHalftoneDegree            := 0x500C
             , PropertyTagHalftoneShape             := 0x500D
             , PropertyTagHalftoneMisc              := 0x500E
             , PropertyTagHalftoneScreen            := 0x500F
             , PropertyTagJPEGQuality               := 0x5010
             , PropertyTagGridSize                  := 0x5011
             , PropertyTagThumbnailFormat           := 0x5012   ; 1 = JPEG, 0 = RAW RGB
             , PropertyTagThumbnailWidth            := 0x5013
             , PropertyTagThumbnailHeight           := 0x5014
             , PropertyTagThumbnailColorDepth       := 0x5015
             , PropertyTagThumbnailPlanes           := 0x5016
             , PropertyTagThumbnailRawBytes         := 0x5017
             , PropertyTagThumbnailSize             := 0x5018
             , PropertyTagThumbnailCompressedSize   := 0x5019
             , PropertyTagColorTransferFunction     := 0x501A
             , PropertyTagThumbnailData             := 0x501B   ; RAW thumbnail bits in JPEG/RGB depends on PropertyTagThumbnailFormat
        
        ; Thumbnail related TAGs
        Static PropertyTagThumbnailImageWidth            := 0x5020   ; Thumbnail width
             , PropertyTagThumbnailImageHeight           := 0x5021   ; Thumbnail height
             , PropertyTagThumbnailBitsPerSample         := 0x5022   ; Number of bits per component
             , PropertyTagThumbnailCompression           := 0x5023   ; Compression Scheme
             , PropertyTagThumbnailPhotometricInterp     := 0x5024   ; Pixel composition
             , PropertyTagThumbnailImageDescription      := 0x5025   ; Image Tile
             , PropertyTagThumbnailEquipMake             := 0x5026   ; Manufacturer of Image Input equipment
             , PropertyTagThumbnailEquipModel            := 0x5027   ; Model of Image input equipment
             , PropertyTagThumbnailStripOffsets          := 0x5028   ; Image data location
             , PropertyTagThumbnailOrientation           := 0x5029   ; Orientation of image
             , PropertyTagThumbnailSamplesPerPixel       := 0x502A   ; Number of components
             , PropertyTagThumbnailRowsPerStrip          := 0x502B   ; Number of rows per strip
             , PropertyTagThumbnailStripBytesCount       := 0x502C   ; Bytes per compressed strip
             , PropertyTagThumbnailResolutionX           := 0x502D   ; Resolution in width direction
             , PropertyTagThumbnailResolutionY           := 0x502E   ; Resolution in height direction
             , PropertyTagThumbnailPlanarConfig          := 0x502F   ; Image data arrangement
             , PropertyTagThumbnailResolutionUnit        := 0x5030   ; Unit of X and Y Resolution
             , PropertyTagThumbnailTransferFunction      := 0x5031   ; Transfer function
             , PropertyTagThumbnailSoftwareUsed          := 0x5032   ; Software used
             , PropertyTagThumbnailDateTime              := 0x5033   ; File change date and time
             , PropertyTagThumbnailArtist                := 0x5034   ; Person who created the image
             , PropertyTagThumbnailWhitePoint            := 0x5035   ; White point chromaticity
             , PropertyTagThumbnailPrimaryChromaticities := 0x5036   ; Chromaticities of primaries
             , PropertyTagThumbnailYCbCrCoefficients     := 0x5037   ; Color space transformation coefficients
             , PropertyTagThumbnailYCbCrSubsampling      := 0x5038   ; Subsampling ratio of Y to C
             , PropertyTagThumbnailYCbCrPositioning      := 0x5039   ; Y and C position
             , PropertyTagThumbnailRefBlackWhite         := 0x503A   ; Pair of black and white reference values
             , PropertyTagThumbnailCopyRight             := 0x503B   ; CopyRight holder
             , PropertyTagLuminanceTable                 := 0x5090
             , PropertyTagChrominanceTable               := 0x5091
             , PropertyTagFrameDelay                     := 0x5100
             , PropertyTagLoopCount                      := 0x5101
             , PropertyTagGlobalPalette                  := 0x5102
             , PropertyTagIndexBackground                := 0x5103
             , PropertyTagIndexTransparent               := 0x5104
             , PropertyTagPixelUnit                      := 0x5110   ; Unit specifier for pixel/unit
             , PropertyTagPixelPerUnitX                  := 0x5111   ; Pixels per unit in X
             , PropertyTagPixelPerUnitY                  := 0x5112   ; Pixels per unit in Y
             , PropertyTagPaletteHistogram               := 0x5113   ; Palette histogram
        
        ; EXIF specific tag
        Static PropertyTagExifExposureTime  := 0x829A
             , PropertyTagExifFNumber       := 0x829D
             , PropertyTagExifExposureProg  := 0x8822
             , PropertyTagExifSpectralSense := 0x8824
             , PropertyTagExifISOSpeed      := 0x8827
             , PropertyTagExifOECF          := 0x8828
             , PropertyTagExifVer           := 0x9000
             , PropertyTagExifDTOrig        := 0x9003   ; Date & time of original
             , PropertyTagExifDTDigitized   := 0x9004   ; Date & time of digital data generation
             , PropertyTagExifCompConfig    := 0x9101
             , PropertyTagExifCompBPP       := 0x9102
             , PropertyTagExifShutterSpeed  := 0x9201
             , PropertyTagExifAperture      := 0x9202
             , PropertyTagExifBrightness    := 0x9203
             , PropertyTagExifExposureBias  := 0x9204
             , PropertyTagExifMaxAperture   := 0x9205
             , PropertyTagExifSubjectDist   := 0x9206
             , PropertyTagExifMeteringMode  := 0x9207
             , PropertyTagExifLightSource   := 0x9208
             , PropertyTagExifFlash         := 0x9209
             , PropertyTagExifFocalLength   := 0x920A
             , PropertyTagExifSubjectArea   := 0x9214   ; exif 2.2 Subject Area
             , PropertyTagExifMakerNote     := 0x927C
             , PropertyTagExifUserComment   := 0x9286
             , PropertyTagExifDTSubsec      := 0x9290   ; Date & Time subseconds
             , PropertyTagExifDTOrigSS      := 0x9291   ; Date & Time original subseconds
             , PropertyTagExifDTDigSS       := 0x9292   ; Date & TIme digitized subseconds
             , PropertyTagExifFPXVer        := 0xA000
             , PropertyTagExifColorSpace    := 0xA001
             , PropertyTagExifPixXDim       := 0xA002
             , PropertyTagExifPixYDim       := 0xA003
             , PropertyTagExifRelatedWav    := 0xA004   ; related sound file
             , PropertyTagExifInterop       := 0xA005
             , PropertyTagExifFlashEnergy   := 0xA20B
             , PropertyTagExifSpatialFR     := 0xA20C   ; Spatial Frequency Response
             , PropertyTagExifFocalXRes     := 0xA20E   ; Focal Plane X Resolution
             , PropertyTagExifFocalYRes     := 0xA20F   ; Focal Plane Y Resolution
             , PropertyTagExifFocalResUnit  := 0xA210   ; Focal Plane Resolution Unit
             , PropertyTagExifSubjectLoc    := 0xA214
             , PropertyTagExifExposureIndex := 0xA215
             , PropertyTagExifSensingMethod := 0xA217
             , PropertyTagExifFileSource    := 0xA300
             , PropertyTagExifSceneType     := 0xA301
             , PropertyTagExifCfaPattern    := 0xA302
        
        ; New EXIF 2.2 properties
        Static PropertyTagExifCustomRendered        := 0xA401
             , PropertyTagExifExposureMode          := 0xA402
             , PropertyTagExifWhiteBalance          := 0xA403
             , PropertyTagExifDigitalZoomRatio      := 0xA404
             , PropertyTagExifFocalLengthIn35mmFilm := 0xA405
             , PropertyTagExifSceneCaptureType      := 0xA406
             , PropertyTagExifGainControl           := 0xA407
             , PropertyTagExifContrast              := 0xA408
             , PropertyTagExifSaturation            := 0xA409
             , PropertyTagExifSharpness             := 0xA40A
             , PropertyTagExifDeviceSettingDesc     := 0xA40B
             , PropertyTagExifSubjectDistanceRange  := 0xA40C
             , PropertyTagExifUniqueImageID         := 0xA420
             , PropertyTagGpsVer                    := 0x0000
             , PropertyTagGpsLatitudeRef            := 0x0001
             , PropertyTagGpsLatitude               := 0x0002
             , PropertyTagGpsLongitudeRef           := 0x0003
             , PropertyTagGpsLongitude              := 0x0004
             , PropertyTagGpsAltitudeRef            := 0x0005
             , PropertyTagGpsAltitude               := 0x0006
             , PropertyTagGpsGpsTime                := 0x0007
             , PropertyTagGpsGpsSatellites          := 0x0008
             , PropertyTagGpsGpsStatus              := 0x0009
             , PropertyTagGpsGpsMeasureMode         := 0x00A
             , PropertyTagGpsGpsDop                 := 0x000B   ; Measurement precision
             , PropertyTagGpsSpeedRef               := 0x000C
             , PropertyTagGpsSpeed                  := 0x000D
             , PropertyTagGpsTrackRef               := 0x000E
             , PropertyTagGpsTrack                  := 0x000F
             , PropertyTagGpsImgDirRef              := 0x0010
             , PropertyTagGpsImgDir                 := 0x0011
             , PropertyTagGpsMapDatum               := 0x0012
             , PropertyTagGpsDestLatRef             := 0x0013
             , PropertyTagGpsDestLat                := 0x0014
             , PropertyTagGpsDestLongRef            := 0x0015
             , PropertyTagGpsDestLong               := 0x0016
             , PropertyTagGpsDestBearRef            := 0x0017
             , PropertyTagGpsDestBear               := 0x0018
             , PropertyTagGpsDestDistRef            := 0x0019
             , PropertyTagGpsDestDist               := 0x001A
             , PropertyTagGpsProcessingMethod       := 0x001B
             , PropertyTagGpsAreaInformation        := 0x001C
             , PropertyTagGpsDate                   := 0x001D
             , PropertyTagGpsDifferential           := 0x001E
    }
    
    
    ;####################################################################################################################
    ;  Image Class                                                                                                      |
    ;####################################################################################################################
    ; The Image class provides methods for loading and saving raster images (bitmaps) and vector images (metafiles).
    ; An Image object encapsulates a bitmap or a metafile and stores attributes that you can retrieve by calling 
    ; various Get methods.
    ; Image objects can be constructe from the following types: BMP, ICON, GIF, JPEG, Exif, PNG, TIFF, WMF, EMF
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
            estat := DllCall("gdiplus\GdipCloneImage"
                            ,this.Ptr   , &image_p
                            ,this.PtrA  , clone_p)
            estat ? GDIP.error_log(A_ThisFunc, "Enum Status", estat) : ""
            MsgBox, % "imop: " imop "`nclone_p: " clone_p "`nestat: " estat 
            Return clone_p
        }
        
        ; The FindFirstItem method retrieves the description and the data size of the first metadata item in this Image object.
        ;FindFirstItem()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The FindNextItem method is used along with the FindFirstItem method to enumerate the metadata items stored in this Image object.
        ;FindNextItem()
        ;{
            ;DllCall("gdiplus\"
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
                ? GDIP.error_log(A_ThisFunc, "Error opening an image from file.", "Valid filename" 
                    , {filename:filename, status_enum:estat, img_obj_ptr:imoP}) : ""
            Return imoP
        }
        
        ; The FromStream method creates a new Image object based on a stream.
        ;FromStream()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetAllPropertyItems method gets all the property items (metadata) stored in this Image object.
        ;GetAllPropertyItems()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetBounds method gets the bounding rectangle for this image.
        ;GetBounds()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetEncoderParameterList method gets a list of the parameters supported by a specified image encoder.
        ;GetEncoderParameterList()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetEncoderParameterListSize method gets the size, in bytes, of the parameter list for a specified image encoder.
        ;GetEncoderParameterListSize()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetFlags method gets a set of flags that indicate certain attributes of this Image object.
        ;GetFlags()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetFrameCount method gets the number of frames in a specified dimension of this Image object.
        ;GetFrameCount()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetFrameDimensionsCount method gets the number of frame dimensions in this Image object.
        ;GetFrameDimensionsCount()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetFrameDimensionsList method gets the identifiers for the frame dimensions of this Image object.
        ;GetFrameDimensionsList()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetHeight method gets the image height, in pixels, of this image.
        ;GetHeight()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetHorizontalResolution method gets the horizontal resolution, in dots per inch, of this image.
        ;GetHorizontalResolution()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetItemData method gets one piece of metadata from this Image object.
        ;GetItemData()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetLastStatus method returns a value that indicates the nature of this Image object's most recent method failure.
        ;GetLastStatus()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetPalette method gets the ColorPalette of this Image object.
        ;GetPalette()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetPaletteSize method gets the size, in bytes, of the color palette of this Image object.
        ;GetPaletteSize()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetPhysicalDimension method gets the width and height of this image.
        ;GetPhysicalDimension()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetPixelFormat method gets the pixel format of this Image object.
        ;GetPixelFormat()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetPropertyCount method gets the number of properties (pieces of metadata) stored in this Image object.
        ;GetPropertyCount()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetPropertyIdList method gets a list of the property identifiers used in the metadata of this Image object.
        ;GetPropertyIdList()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetPropertyItem method gets a specified property item (piece of metadata) from this Image object.
        ;GetPropertyItem()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetPropertyItemSize method gets the size, in bytes, of a specified property item of this Image object.
        ;GetPropertyItemSize()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetPropertySize method gets the total size, in bytes, of all the property items stored in this Image object. The GetPropertySize method also gets the number of property items stored in this Image object.
        ;GetPropertySize()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetRawFormat method gets a globally unique identifier ( GUID) that identifies the format of this Image object. GUIDs that identify various file formats are defined in Gdiplusimaging.h.
        ;GetRawFormat()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetThumbnailImage method gets a thumbnail image from this Image object.
        ;GetThumbnailImage()
        ;{
            ;DllCall("gdiplus\"
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
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The GetWidth method gets the width, in pixels, of this image.
        ;GetWidth()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; This topic lists the constructors of the Image class. For a complete class listing, see Image Class.
        ;Image()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; Creates an Image object based on a file.
        ;Image()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; This topic lists the constructors of the Image class. For a complete class listing, see Image Class.
        ;Image()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; Creates an Image object based on a stream.
        ;Image()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; This topic lists the constructors of the Image class. For a complete class listing, see Image Class.
        ;Image()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The RemovePropertyItem method removes a property item (piece of metadata) from this Image object.
        ;RemovePropertyItem()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The RotateFlip method rotates and flips this image.
        ;RotateFlip()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The Save method saves this image to a file.
        ;Save()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The Save method saves this image to a stream.
        ;Save()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The SaveAdd method adds a frame to a file or stream specified in a previous call to the Save method.
        ;SaveAdd()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The SaveAdd method adds a frame to a file or stream specified in a previous call to the Save method.
        ;SaveAdd()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The SelectActiveFrame method selects the frame in this Image object specified by a dimension and an index.
        ;SelectActiveFrame()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The SetAbort method sets the object whose Abort method is called periodically during time-consuming rendering operation.
        ;SetAbort()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The SetPalette method sets the color palette of this Image object.
        ;SetPalette()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
        
        ; The SetPropertyItem method sets a property item (piece of metadata) for this Image object. If the item already exists, then its contents are updated; otherwise, a new item is added.
        ;SetPropertyItem()
        ;{
            ;DllCall("gdiplus\"
            ;, type , value)
        ;}
    }
    
    ;####################################################################################################################
    ;  Graphics Class                                                                                                   |
    ;####################################################################################################################
    Class Graphics Extends GDIP
    {
        _type          := "graphics"
        nativeGraphics := ""
        lastResult     := ""
        
        ; ##################
        ; ## CONSTRUCTORS ##
        ; ##################
        ; Grahpics(hwnd, icm)   Handle to a window. ICM = I
        ; Graphics(hdc)         
        ; Graphics(hdc, device) 
        ; Graphics(imageObject) 
        __New(gIn="", dev_icm="")
        {
            VarSetCapacity(gp, A_PtrSize, 0)
            (dev_icm)   ; If dev_icm is true
                ? !(estat := DllCall("gdiplus\GdipCreateFromHWNDICM", this.Ptr, gIn, this.PtrA, gp))    ? ""             ; From HWND with ICM
                : !(estat := DllCall("gdiplus\GdipCreateFromHDC2", this.Ptr, gIn, this.Ptr, dev_icm, this.PtrA, gp))     ; From HDC and device
            ; If dev_icm is false
            :     !(estat := DllCall("gdiplus\GdipCreateFromHWND", this.Ptr, gIn, this.PtrA, gp))       ? ""             ; From HWND without ICM
                : !(estat := DllCall("gdiplus\GdipCreateFromHDC", this.Ptr, gIn, this.PtrA, gp))        ? ""             ; From HDC
                : estat := DllCall("gdiplus\GdipGetImageGraphicsContext", this.Ptr, gIn.nativeImage, this.PtrA, gp)      ; From Image Object
            
            (estat)   ; An estat that's not 0 is an error and should be logged
                ? this.log_error(A_ThisFunc, "Error creating Graphics object"
                                ,"HDC`nHWND`nImage Object", {param1:gIn, param2:dev_icm, estat:estat})
                : (this.nativeGraphics := gp   ; Otherwise, save graphics and last result
                  ,this.lastResult := estat)
        }
        
        ; Description       Record any non-OK status and return status
        SetStatus(status)
        {
            Return (status = 0)
                ? status
                : (this.lastResult := status)
        }
        
        ; ## DESTRUCTOR ##
        __Delete()
        {
            DllCall("GdipDeleteGraphics", this.Ptr, this.nativeGraphics+0)
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
            ;VarSetCapacity(HDC, A_PtrSize, 0)
            ;last SetStatus(DllExports::GdipGetDC(nativeGraphics, &hdc));
            ;DllCall(""
            ;       , type      , value)
            ;return HDC
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
    Class Enumerations
    {
        Class ColorAdjustType {                 ; Specifies which GDI+ objects the color adjustment information is for
            Static ColorAdjustTypeDefault = 0   ; Default GDI+ object color adjustment for all 
                 , ColorAdjustTypeBitmap  = 1   ; Color adjustment for Bitmap objects
                 , ColorAdjustTypeBrush   = 2   ; Color adjustment for Brush objects
                 , ColorAdjustTypePen     = 3   ; Color adjustment for Pen objects
                 , ColorAdjustTypeText    = 4   ; Color adjustment for Text objects
                 , ColorAdjustTypeCount   = 5   ; Number of types specified
                 , ColorAdjustTypeAny     = 6   ; Reserved
        }
        
        Class ColorChannelFlags {              ; Specifies individual channels in the CMYK (cyan, magenta, yellow, black) color space.
            Static ColorChannelFlagsC    = 0   ; Cyan
                 , ColorChannelFlagsM    = 1   ; Magenta
                 , ColorChannelFlagsY    = 2   ; Yellow
                 , ColorChannelFlagsK    = 3   ; Black
                 , ColorChannelFlagsLast = 4   ; Undefined
        }
        
        Class ColorMode {                ; Specifies two modes for color component values
            Static ColorModeARGB32 = 0   ; Integer values supplied are 32-bit
                 , ColorModeARGB64 = 1   ; Integer values supplied are 64-bit
        }
        
        Class ColorMatrixFlags {                   ; Specifies the types of images and colors that will be affected by the color and grayscale adjustment settings of an ImageAttributes object.
            Static ColorMatrixFlagsDefault   = 0   ; All color values (including grays) are adjusted by the same color-adjustment matrix.
                 , ColorMatrixFlagsSkipGrays = 1   ; Colors are adjusted but gray shades are not adjusted.
                 , ColorMatrixFlagsAltGray   = 2   ; Colors are adjusted by one matrix and gray shades are adjusted by another matrix.
        }
        
        Class CombineMode {                    ; Specifies how a new region is combined with an existing region.
            Static CombineModeReplace    = 0   ; Replaced by the new region.
                 , CombineModeIntersect  = 1   ; Replaced by the intersection of itself and the new region.
                 , CombineModeUnion      = 2   ; Replaced by the union of itself and the new region.
                 , CombineModeXor        = 3   ; Replaced by the result of performing an XOR on the two regions.
                 , CombineModeExclude    = 4   ; Replaced by the portion of itself that is outside of the new region.
                 , CombineModeComplement = 5   ; Replaced by the portion of the new region that is outside of the existing region.
        }
        
        Class CompositingMode {                    ; Specifies how rendered colors are combined with background colors.
            Static CompositingModeSourceOver = 0   ; when a color is rendered, it is blended with the background color.
                 , CompositingModeSourceCopy = 1   ; when a color is rendered, it overwrites the background color.
        }
        
        Class CompositingQuality {                        ; Specifies whether gamma correction is applied when colors are blended with background colors.
            Static CompositingQualityInvalid        = -1  ; Invalid
                 , CompositingQualityDefault        = 0   ; Gamma correction is not applied.
                 , CompositingQualityHighSpeed      = 1   ; Gamma correction is not applied.
                 , CompositingQualityHighQuality    = 2   ; Gamma correction is applied.
                 , CompositingQualityGammaCorrected = 3   ; Gamma correction is applied.
                 , CompositingQualityAssumeLinear   = 4   ; Gamma correction is not applied.
        }
        
        Class CoordinateSpace {                ; Specifies coordinate spaces.
            Static CoordinateSpaceWorld  = 0   ; Specify world space
                 , CoordinateSpacePage   = 1   ; Specify page space
                 , CoordinateSpaceDevice = 2   ; Specify device space
        }
        
        Class CurveAdjustments {               ; Encompasses the eight bitmap adjustments listed in the CurveAdjustments enumeration.
            Static AdjustExposure        = 0   ; Simulates increasing or decreasing the exposure of a photograph.
                 , AdjustDensity         = 1   ; Simulates increasing or decreasing the film density of a photograph.
                 , AdjustContrast        = 2   ; Increases or decreases the contrast of a bitmap.
                 , AdjustHighlight       = 3   ; Increases or decreases the value of a color channel if that channel already has a value that is above half intensity. 
                 , AdjustShadow          = 4   ; Increases or decreases the value of a color channel if that channel already has a value that is below half intensity.
                 , AdjustMidtone         = 5   ; Lightens or darkens an image.
                 , AdjustWhiteSaturation = 6   ; Set the adjustment member of a ColorCurveParams object.
                 , AdjustBlackSaturation = 7   ; Set the adjustment member of a ColorCurveParams object.
        }
        
        Class CurveChannel {               ; Specifies which color channels are affected by a ColorCurve bitmap adjustment.
            Static CurveChannelAll   = 0   ; Specifies that the color adjustment applies to all channels.
                 , CurveChannelRed   = 1   ; Specifies that the color adjustment applies only to the red channel.
                 , CurveChannelGreen = 2   ; Specifies that the color adjustment applies only to the green channel.
                 , CurveChannelBlue  = 3   ; Specifies that the color adjustment applies only to the blue channel.
        }
        
        Class CustomLineCapType {                         ;
            Static CustomLineCapTypeDefault         = 0   ; 
                 , CustomLineCapTypeAdjustableArrow = 1   ;
        }
        
        Class DashCap {                  ; Specifies the type of graphic shape to use on both ends of each dash in a dashed line.
            Static DashCapFlat     = 0   ; Square cap that squares off both ends of each dash.
                 , DashCapRound    = 2   ; Circular cap that rounds off both ends of each dash.
                 , DashCapTriangle = 3   ; Triangular cap that points both ends of each dash.
        }
        
        Class DashStyle {                    ; Specifies the line style of a line drawn with a Windows GDI+ pen.
            Static DashStyleSolid      = 0   ; Solid line.
                 , DashStyleDash       = 1   ; Dashed line.
                 , DashStyleDot        = 2   ; Dotted line.
                 , DashStyleDashDot    = 3   ; Alternating dash-dot line.
                 , DashStyleDashDotDot = 4   ; Alternated dash-dot-dot line.
                 , DashStyleCustom     = 5   ; User-Defined, custom dashed line.
        }
        
        Class DitherType {                         ; Identifies the available algorithms for dithering when a bitmap is converted.
            Static DitherTypeNone           = 0    ; No dithering is performed.
                 , DitherTypeSolid          = 1    ; No dithering is performed.
                 , DitherTypeOrdered4x4     = 2    ; perform dithering based on the colors in one of the standard fixed palettes.
                 , DitherTypeOrdered8x8     = 3    ; Dithering is performed using the colors in one of the standard fixed palettes.
                 , DitherTypeOrdered16x16   = 4    ; Dithering is performed using the colors in one of the standard fixed palettes.
                 , DitherTypeSpiral4x4      = 5    ; Dithering is performed using the colors in one of the standard fixed palettes.
                 , DitherTypeSpiral8x8      = 6    ; Dithering is performed using the colors in one of the standard fixed palettes.
                 , DitherTypeDualSpiral4x4  = 7    ; Dithering is performed using the colors in one of the standard fixed palettes.
                 , DitherTypeDualSpiral8x8  = 8    ; Dithering is performed using the colors in one of the standard fixed palettes.
                 , DitherTypeErrorDiffusion = 9    ; Dithering is performed based on the palette specified by the palette parameter of the this.Bitmap.ConvertFormat() method. 
                 , DitherTypeMax            = 10   ; TBD
        }
        
        Class DriverStringOptions {                         ; Specifies the spacing, orientation, and quality of the rendering for driver strings.
            Static DriverStringOptionsCmapLookup      = 1   ; String array contains Unicode character values.
                 , DriverStringOptionsVertical        = 2   ; String is displayed vertically.
                 , DriverStringOptionsRealizedAdvance = 4   ; Glyph positions are calculated from the position of the first glyph. 
                 , DriverStringOptionsLimitSubpixel   = 8   ; Less memory should be used for cache of antialiased glyphs.
        }
        
        Class EmfPlusRecordType {                                     ; Identifies metafile record types used in Windows Metafile Format (WMF), Enhanced Metafile (EMF), and EMF+ files. 
            Static EmfPlusRecordTypeMax                     = -1      ; TBD 
                 , EmfRecordTypeMin                         = 1       ; TBD 
                 , EmfRecordTypeHeader                      = 1       ; TBD 
                 , EmfRecordTypePolyBezier                  = 2       ; TBD 
                 , EmfRecordTypePolygon                     = 3       ; TBD 
                 , EmfRecordTypePolyline                    = 4       ; TBD 
                 , EmfRecordTypePolyBezierTo                = 5       ; TBD 
                 , EmfRecordTypePolyLineTo                  = 6       ; TBD 
                 , EmfRecordTypePolyPolyline                = 7       ; TBD 
                 , EmfRecordTypePolyPolygon                 = 8       ; TBD 
                 , EmfRecordTypeSetWindowExtEx              = 9       ; TBD 
                 , EmfRecordTypeSetWindowOrgEx              = 10      ; TBD           
                 , EmfRecordTypeSetViewportExtEx            = 11      ; TBD           
                 , EmfRecordTypeSetViewportOrgEx            = 12      ; TBD           
                 , EmfRecordTypeSetBrushOrgEx               = 13      ; TBD 
                 , EmfRecordTypeEOF                         = 14      ; TBD 
                 , EmfRecordTypeSetPixelV                   = 15      ; TBD 
                 , EmfRecordTypeSetMapperFlags              = 16      ; TBD           
                 , EmfRecordTypeSetMapMode                  = 17      ; TBD 
                 , EmfRecordTypeSetBkMode                   = 18      ; TBD 
                 , EmfRecordTypeSetPolyFillMode             = 19      ; TBD           
                 , EmfRecordTypeSetROP2                     = 20      ; TBD 
                 , EmfRecordTypeSetStretchBltMode           = 21      ; TBD           
                 , EmfRecordTypeSetTextAlign                = 22      ; TBD 
                 , EmfRecordTypeSetColorAdjustment          = 23      ; TBD           
                 , EmfRecordTypeSetTextColor                = 24      ; TBD 
                 , EmfRecordTypeSetBkColor                  = 25      ; TBD 
                 , EmfRecordTypeOffsetClipRgn               = 26      ; TBD 
                 , EmfRecordTypeMoveToEx                    = 27      ; TBD 
                 , EmfRecordTypeSetMetaRgn                  = 28      ; TBD 
                 , EmfRecordTypeExcludeClipRect             = 29      ; TBD           
                 , EmfRecordTypeIntersectClipRect           = 30      ; TBD           
                 , EmfRecordTypeScaleViewportExtEx          = 31      ; TBD           
                 , EmfRecordTypeScaleWindowExtEx            = 32      ; TBD           
                 , EmfRecordTypeSaveDC                      = 33      ; TBD 
                 , EmfRecordTypeRestoreDC                   = 34      ; TBD 
                 , EmfRecordTypeSetWorldTransform           = 35      ; TBD           
                 , EmfRecordTypeModifyWorldTransform        = 36      ; TBD           
                 , EmfRecordTypeSelectObject                = 37      ; TBD 
                 , EmfRecordTypeCreatePen                   = 38      ; TBD 
                 , EmfRecordTypeCreateBrushIndirect         = 39      ; TBD           
                 , EmfRecordTypeDeleteObject                = 40      ; TBD 
                 , EmfRecordTypeAngleArc                    = 41      ; TBD 
                 , EmfRecordTypeEllipse                     = 42      ; TBD 
                 , EmfRecordTypeRectangle                   = 43      ; TBD 
                 , EmfRecordTypeRoundRect                   = 44      ; TBD 
                 , EmfRecordTypeArc                         = 45      ; TBD 
                 , EmfRecordTypeChord                       = 46      ; TBD 
                 , EmfRecordTypePie                         = 47      ; TBD 
                 , EmfRecordTypeSelectPalette               = 48      ; TBD 
            Static EmfRecordTypeCreatePalette               = 49      ; TBD 
                 , EmfRecordTypeSetPaletteEntries           = 50      ; TBD           
                 , EmfRecordTypeResizePalette               = 51      ; TBD 
                 , EmfRecordTypeRealizePalette              = 52      ; TBD           
                 , EmfRecordTypeExtFloodFill                = 53      ; TBD 
                 , EmfRecordTypeLineTo                      = 54      ; TBD 
                 , EmfRecordTypeArcTo                       = 55      ; TBD 
                 , EmfRecordTypePolyDraw                    = 56      ; TBD 
                 , EmfRecordTypeSetArcDirection             = 57      ; TBD           
                 , EmfRecordTypeSetMiterLimit               = 58      ; TBD 
                 , EmfRecordTypeBeginPath                   = 59      ; TBD 
                 , EmfRecordTypeEndPath                     = 60      ; TBD 
                 , EmfRecordTypeCloseFigure                 = 61      ; TBD 
                 , EmfRecordTypeFillPath                    = 62      ; TBD 
                 , EmfRecordTypeStrokeAndFillPath           = 63      ; TBD           
                 , EmfRecordTypeStrokePath                  = 64      ; TBD 
                 , EmfRecordTypeFlattenPath                 = 65      ; TBD 
                 , EmfRecordTypeWidenPath                   = 66      ; TBD 
                 , EmfRecordTypeSelectClipPath              = 67      ; TBD           
                 , EmfRecordTypeAbortPath                   = 68      ; TBD 
                 , EmfRecordTypeReserved_069                = 69      ; TBD 
                 , EmfRecordTypeGdiComment                  = 70      ; TBD 
                 , EmfRecordTypeFillRgn                     = 71      ; TBD 
                 , EmfRecordTypeFrameRgn                    = 72      ; TBD 
                 , EmfRecordTypeInvertRgn                   = 73      ; TBD 
                 , EmfRecordTypePaintRgn                    = 74      ; TBD 
                 , EmfRecordTypeExtSelectClipRgn            = 75      ; TBD           
                 , EmfRecordTypeBitBlt                      = 76      ; TBD 
                 , EmfRecordTypeStretchBlt                  = 77      ; TBD 
                 , EmfRecordTypeMaskBlt                     = 78      ; TBD 
                 , EmfRecordTypePlgBlt                      = 79      ; TBD 
                 , EmfRecordTypeSetDIBitsToDevice           = 80      ; TBD           
                 , EmfRecordTypeStretchDIBits               = 81      ; TBD 
                 , EmfRecordTypeExtCreateFontIndirect       = 82      ; TBD           
                 , EmfRecordTypeExtTextOutA                 = 83      ; TBD 
                 , EmfRecordTypeExtTextOutW                 = 84      ; TBD 
                 , EmfRecordTypePolyBezier16                = 85      ; TBD 
                 , EmfRecordTypePolygon16                   = 86      ; TBD 
                 , EmfRecordTypePolyline16                  = 87      ; TBD 
                 , EmfRecordTypePolyBezierTo16              = 88      ; TBD           
                 , EmfRecordTypePolylineTo16                = 89      ; TBD 
                 , EmfRecordTypePolyPolyline16              = 90      ; TBD           
                 , EmfRecordTypePolyPolygon16               = 91      ; TBD 
                 , EmfRecordTypePolyDraw16                  = 92      ; TBD 
                 , EmfRecordTypeCreateMonoBrush             = 93      ; TBD           
                 , EmfRecordTypeCreateDIBPatternBrushPt     = 94      ; TBD           
                 , EmfRecordTypeExtCreatePen                = 95      ; TBD 
                 , EmfRecordTypePolyTextOutA                = 96      ; TBD 
                 , EmfRecordTypePolyTextOutW                = 97      ; TBD 
                 , EmfRecordTypeSetICMMode                  = 98      ; TBD 
            Static EmfRecordTypeCreateColorSpace            = 99      ; TBD           
                 , EmfRecordTypeSetColorSpace               = 100     ; TBD           
                 , EmfRecordTypeDeleteColorSpace            = 101     ; TBD           
                 , EmfRecordTypeGLSRecord                   = 102     ; TBD 
                 , EmfRecordTypeGLSBoundedRecord            = 103     ; TBD           
                 , EmfRecordTypePixelFormat                 = 104     ; TBD 
                 , EmfRecordTypeDrawEscape                  = 105     ; TBD 
                 , EmfRecordTypeExtEscape                   = 106     ; TBD 
                 , EmfRecordTypeStartDoc                    = 107     ; TBD 
                 , EmfRecordTypeSmallTextOut                = 108     ; TBD 
                 , EmfRecordTypeForceUFIMapping             = 109     ; TBD           
                 , EmfRecordTypeNamedEscape                 = 110     ; TBD 
                 , EmfRecordTypeColorCorrectPalette         = 111     ; TBD           
                 , EmfRecordTypeSetICMProfileA              = 112     ; TBD           
                 , EmfRecordTypeSetICMProfileW              = 113     ; TBD           
                 , EmfRecordTypeAlphaBlend                  = 114     ; TBD 
                 , EmfRecordTypeSetLayout                   = 115     ; TBD 
                 , EmfRecordTypeTransparentBlt              = 116     ; TBD           
                 , EmfRecordTypeReserved_117                = 117     ; TBD 
                 , EmfRecordTypeGradientFill                = 118     ; TBD 
                 , EmfRecordTypeSetLinkedUFIs               = 119     ; TBD           
                 , EmfRecordTypeSetTextJustification        = 120     ; TBD           
                 , EmfRecordTypeColorMatchToTargetW         = 121     ; TBD           
                 , EmfRecordTypeCreateColorSpaceW           = 122     ; TBD           
                 , EmfRecordTypeMax                         = 122     ; TBD 
                 , EmfPlusRecordTypeInvalid                 = 16384   ; TBD           
                 , EmfPlusRecordTypeHeader                  = 16385   ; Identifies a record that is the EMF+ header.    
                 , EmfPlusRecordTypeMin                     = 16385   ; TBD 
                 , EmfPlusRecordTypeEndOfFile               = 16386   ; Identifies a record that marks the last EMF+ record of a metafile.
                 , EmfPlusRecordTypeComment                 = 16387   ; this.Graphics.AddMetafileComment()           
                 , EmfPlusRecordTypeGetDC                   = 16388   ; this.Graphics.GetHDC()           
                 , EmfPlusRecordTypeMultiFormatStart        = 16389   ; Identifies the start of a multiple-format block.     
                 , EmfPlusRecordTypeMultiFormatSection      = 16390   ; Identifies a section in a multiple-format block.     
                 , EmfPlusRecordTypeMultiFormatEnd          = 16391   ; Identifies the end of a multiple-format block.     
                 , EmfPlusRecordTypeObject                  = 16392   ; TBD 
                 , EmfPlusRecordTypeClear                   = 16393   ; this.Graphics.Clear()           
                 , EmfPlusRecordTypeFillRects               = 16394   ; FillRectangles Methods          
                 , EmfPlusRecordTypeDrawRects               = 16395   ; DrawRectangles Methods          
                 , EmfPlusRecordTypeFillPolygon             = 16396   ; FillPolygon Methods          
                 , EmfPlusRecordTypeDrawLines               = 16397   ; DrawLines Methods          
                 , EmfPlusRecordTypeFillEllipse             = 16398   ; FillEllipse Methods          
                 , EmfPlusRecordTypeDrawEllipse             = 16399   ; DrawEllipse Methods          
                 , EmfPlusRecordTypeFillPie                 = 16400   ; FillPie Methods          
                 , EmfPlusRecordTypeDrawPie                 = 16401   ; DrawPie Methods          
                 , EmfPlusRecordTypeDrawArc                 = 16402   ; DrawArc Methods          
                 , EmfPlusRecordTypeFillRegion              = 16403   ; this.Graphics.()           
                 , EmfPlusRecordTypeFillPath                = 16404   ; this.Graphics.()           
                 , EmfPlusRecordTypeDrawPath                = 16405   ; this.Graphics.()           
                 , EmfPlusRecordTypeFillClosedCurve         = 16406   ; FillClosedCurve Methods          
                 , EmfPlusRecordTypeDrawClosedCurve         = 16407   ; DrawClosedCurve Methods          
            Static EmfPlusRecordTypeDrawCurve               = 16408   ; DrawCurve Methods          
                 , EmfPlusRecordTypeDrawBeziers             = 16409   ; DrawBeziers Methods          
                 , EmfPlusRecordTypeDrawImage               = 16410   ; DrawImage Methods          
                 , EmfPlusRecordTypeDrawImagePoints         = 16411   ; DrawImage Methods (destination point arrays)       
                 , EmfPlusRecordTypeDrawString              = 16412   ; DrawString Methods          
                 , EmfPlusRecordTypeSetRenderingOrigin      = 16413   ; this.Graphics.SetRenderingOrigin()           
                 , EmfPlusRecordTypeSetAntiAliasMode        = 16414   ; this.Graphics.SetSmoothingMode()           
                 , WmfRecordTypeSaveDC                      = 16414   ; TBD 
                 , EmfPlusRecordTypeSetTextRenderingHint    = 16415   ; this.Graphics.SetTextRenderingHint()           
                 , EmfPlusRecordTypeSetTextContrast         = 16416   ; this.Graphics.SetTextContrast()           
                 , EmfPlusRecordTypeSetInterpolationMode    = 16417   ; this.Graphics.SetInterpolationMode()           
                 , EmfPlusRecordTypeSetPixelOffsetMode      = 16418   ; this.Graphics.SetPixelOffsetMode()           
                 , EmfPlusRecordTypeSetCompositingMode      = 16419   ; this.Graphics.SetCompositingMode()           
                 , EmfPlusRecordTypeSetCompositingQuality   = 16420   ; this.Graphics.SetCompositingQuality()           
                 , EmfPlusRecordTypeSave                    = 16421   ; this.Graphics.Save()           
                 , EmfPlusRecordTypeRestore                 = 16422   ; this.Graphics.Restore()           
                 , EmfPlusRecordTypeBeginContainer          = 16423   ; this.Graphics.BeginContainer()           
                 , EmfPlusRecordTypeBeginContainerNoParams  = 16424   ; this.Graphics.BeginContainer()           
                 , EmfPlusRecordTypeEndContainer            = 16425   ; this.Graphics.EndContainer()           
                 , EmfPlusRecordTypeSetWorldTransform       = 16426   ; this.Graphics.SetTransform()           
                 , EmfPlusRecordTypeResetWorldTransform     = 16427   ; this.Graphics.ResetTransform()           
                 , EmfPlusRecordTypeMultiplyWorldTransform  = 16428   ; this.Graphics.MultiplyTransform()           
                 , EmfPlusRecordTypeTranslateWorldTransform = 16429   ; this.Graphics.TranslateTransform()           
                 , EmfPlusRecordTypeScaleWorldTransform     = 16430   ; this.Graphics.ScaleTransform()           
                 , EmfPlusRecordTypeRotateWorldTransform    = 16431   ; this.Graphics.RotateTransform()           
                 , EmfPlusRecordTypeSetPageTransform        = 16432   ; this.Graphics.SetPageScale() and this.Graphics.SetPageUnit()         
                 , EmfPlusRecordTypeResetClip               = 16433   ; this.Graphics.ResetClip()           
                 , EmfPlusRecordTypeSetClipRect             = 16434   ; this.Graphics.SetClip()           
                 , EmfPlusRecordTypeSetClipPath             = 16435   ; this.Graphics.SetClip()           
                 , EmfPlusRecordTypeSetClipRegion           = 16436   ; this.Graphics.SetClip()           
                 , EmfPlusRecordTypeOffsetClip              = 16437   ; TranslateClip Methods          
                 , WmfRecordTypeRealizePalette              = 16437   ; TBD           
                 , EmfPlusRecordTypeDrawDriverString        = 16438   ; this.Graphics.DrawDriverString()           
                 , EmfPlusRecordTypeStrokeFillPath          = 16439   ; TBD           
                 , WmfRecordTypeSetPalEntries               = 16439   ; TBD           
                 , EmfPlusRecordTypeSerializableObject      = 16440   ; TBD           
                 , EmfPlusRecordTypeSetTSGraphics           = 16441   ; TBD           
                 , EmfPlusRecordTypeSetTSClip               = 16442   ; TBD           
                 , EmfPlusRecordTotal                       = 16443   ; TBD 
                 , WmfRecordTypeStartPage                   = 16463   ; TBD 
                 , WmfRecordTypeEndPage                     = 16464   ; TBD 
                 , WmfRecordTypeAbortDoc                    = 16466   ; TBD 
                 , WmfRecordTypeEndDoc                      = 16478   ; TBD 
                 , WmfRecordTypeCreatePalette               = 16631   ; TBD           
                 , WmfRecordTypeCreateBrush                 = 16632   ; TBD           
                 , WmfRecordTypeSetBkMode                   = 16642   ; TBD 
                 , WmfRecordTypeSetMapMode                  = 16643   ; TBD 
                 , WmfRecordTypeSetROP2                     = 16644   ; TBD 
                 , WmfRecordTypeSetRelAbs                   = 16645   ; TBD 
                 , WmfRecordTypeSetPolyFillMode             = 16646   ; TBD           
            Static WmfRecordTypeSetStretchBltMode           = 16647   ; TBD           
                 , WmfRecordTypeSetTextCharExtra            = 16648   ; TBD           
                 , WmfRecordTypeRestoreDC                   = 16679   ; TBD 
                 , WmfRecordTypeInvertRegion                = 16682   ; TBD           
                 , WmfRecordTypePaintRegion                 = 16683   ; TBD           
                 , WmfRecordTypeSelectClipRegion            = 16684   ; TBD           
                 , WmfRecordTypeSelectObject                = 16685   ; TBD           
                 , WmfRecordTypeSetTextAlign                = 16686   ; TBD           
                 , WmfRecordTypeResizePalette               = 16697   ; TBD           
                 , WmfRecordTypeDIBCreatePatternBrush       = 16706   ; TBD           
                 , WmfRecordTypeSetLayout                   = 16713   ; TBD 
                 , WmfRecordTypeResetDC                     = 16716   ; TBD 
                 , WmfRecordTypeStartDoc                    = 16717   ; TBD 
                 , WmfRecordTypeDeleteObject                = 16880   ; TBD           
                 , WmfRecordTypeCreatePatternBrush          = 16889   ; TBD           
                 , WmfRecordTypeSetBkColor                  = 16897   ; TBD 
                 , WmfRecordTypeSetTextColor                = 16905   ; TBD           
                 , WmfRecordTypeSetTextJustification        = 16906   ; TBD           
                 , WmfRecordTypeSetWindowOrg                = 16907   ; TBD           
                 , WmfRecordTypeSetWindowExt                = 16908   ; TBD           
                 , WmfRecordTypeSetViewportOrg              = 16909   ; TBD           
                 , WmfRecordTypeSetViewportExt              = 16910   ; TBD           
                 , WmfRecordTypeOffsetWindowOrg             = 16911   ; TBD           
                 , WmfRecordTypeOffsetViewportOrg           = 16913   ; TBD           
                 , WmfRecordTypeLineTo                      = 16915   ; TBD 
                 , WmfRecordTypeMoveTo                      = 16916   ; TBD 
                 , WmfRecordTypeOffsetClipRgn               = 16928   ; TBD           
                 , WmfRecordTypeFillRegion                  = 16936   ; TBD 
                 , WmfRecordTypeSetMapperFlags              = 16945   ; TBD           
                 , WmfRecordTypeSelectPalette               = 16948   ; TBD           
                 , WmfRecordTypeCreatePenIndirect           = 17146   ; TBD           
                 , WmfRecordTypeCreateFontIndirect          = 17147   ; TBD           
                 , WmfRecordTypeCreateBrushIndirect         = 17148   ; TBD           
                 , WmfRecordTypeCreateBitmapIndirect        = 17149   ; TBD           
                 , WmfRecordTypePolygon                     = 17188   ; TBD 
                 , WmfRecordTypePolyline                    = 17189   ; TBD 
                 , WmfRecordTypeScaleWindowExt              = 17424   ; TBD           
                 , WmfRecordTypeScaleViewportExt            = 17426   ; TBD           
                 , WmfRecordTypeExcludeClipRect             = 17429   ; TBD           
                 , WmfRecordTypeIntersectClipRect           = 17430   ; TBD           
                 , WmfRecordTypeEllipse                     = 17432   ; TBD 
                 , WmfRecordTypeFloodFill                   = 17433   ; TBD 
                 , WmfRecordTypeRectangle                   = 17435   ; TBD 
                 , WmfRecordTypeSetPixel                    = 17439   ; TBD 
                 , WmfRecordTypeFrameRegion                 = 17449   ; TBD           
                 , WmfRecordTypeAnimatePalette              = 17462   ; TBD           
                 , WmfRecordTypeTextOut                     = 17697   ; TBD 
                 , WmfRecordTypePolyPolygon                 = 17720   ; TBD           
                 , WmfRecordTypeExtFloodFill                = 17736   ; TBD           
                 , WmfRecordTypeRoundRect                   = 17948   ; TBD 
            Static WmfRecordTypePatBlt                      = 17949   ; TBD 
                 , WmfRecordTypeEscape                      = 17958   ; TBD 
                 , WmfRecordTypeDrawText                    = 17967   ; TBD 
                 , WmfRecordTypeCreateBitmap                = 18174   ; TBD           
                 , WmfRecordTypeCreateRegion                = 18175   ; TBD           
                 , WmfRecordTypeArc                         = 18455   ; TBD 
                 , WmfRecordTypePie                         = 18458   ; TBD 
                 , WmfRecordTypeChord                       = 18480   ; TBD 
                 , WmfRecordTypeBitBlt                      = 18722   ; TBD 
                 , WmfRecordTypeDIBBitBlt                   = 18752   ; TBD 
                 , WmfRecordTypeExtTextOut                  = 18994   ; TBD 
                 , WmfRecordTypeStretchBlt                  = 19235   ; TBD 
                 , WmfRecordTypeDIBStretchBlt               = 19265   ; TBD           
                 , WmfRecordTypeSetDIBToDev                 = 19763   ; TBD           
                 , WmfRecordTypeStretchDIB                  = 20291   ; TBD 
        }
        
        Class EmfToWmfBitsFlags {                          ; Specifies options for the this.Metafile.EmfToWmfBits() method.
            Static EmfToWmfBitsFlagsDefault          = 0   ; Default conversion.
                 , EmfToWmfBitsFlagsEmbedEmf         = 1   ; Source EMF metafile is embedded as a comment in the resulting WMF metafile.
                 , EmfToWmfBitsFlagsIncludePlaceable = 2   ; Resulting WMF metafile is in the placeable metafile format.
                 , EmfToWmfBitsFlagsNoXORClip        = 4   ; Clipping region is stored in the metafile in the traditional way. 
        }
        
        Class EmfType {                     ; Specifies if EMF, EMF+, or dual
            Static EmfTypeEmfOnly     = 3   ; Only EMF
                 , EmfTypeEmfPlusOnly = 4   ; Only EMF+
                 , EmfTypeEmfPlusDual = 5   ; Both EMF and EMF+
        }
        
        Class EncoderParameterValueType {                       ; Specifies data types for image codec (encoder/decoder) parameters.
            Static EncoderParameterValueTypeByte          = 1   ; Is an 8-bit unsigned integer.
                 , EncoderParameterValueTypeASCII         = 2   ; Is a null-terminated character string.
                 , EncoderParameterValueTypeShort         = 3   ; Is a 16-bit unsigned integer.
                 , EncoderParameterValueTypeLong          = 4   ; Is a 32-bit unsigned integer.
                 , EncoderParameterValueTypeRational      = 5   ; Is an array of two, 32-bit unsigned integers representing a fraction.
                 , EncoderParameterValueTypeLongRange     = 6   ; Is an array of two, 32-bit unsigned integers representing a range.
                 , EncoderParameterValueTypeUndefined     = 7   ; Is an array of bytes that can hold values of any type.
                 , EncoderParameterValueTypeRationalRange = 8   ; Is an array of four, 32-bit unsigned integers representing a range of rational numbers.
                 , EncoderParameterValueTypePointer       = 9   ; Is a pointer to a block of custom metadata.
        }
        
        Class EncoderValue {                                   ; Specifies values that can be passed as arguments to image encoders.
            Static EncoderValueColorTypeCMYK            = 0    ; Not used in GDI+ version 1.0.
                 , EncoderValueColorTypeYCCK            = 1    ; Not used in GDI+ version 1.0.
                 , EncoderValueCompressionLZW           = 2    ; TIFF image, specifies the LZW compression method.
                 , EncoderValueCompressionCCITT3        = 3    ; TIFF image, specifies the CCITT3 compression method.
                 , EncoderValueCompressionCCITT4        = 4    ; TIFF image, specifies the CCITT4 compression method.
                 , EncoderValueCompressionRle           = 5    ; TIFF image, specifies the RLE compression method.
                 , EncoderValueCompressionNone          = 6    ; TIFF image, specifies no compression.
                 , EncoderValueScanMethodInterlaced     = 7    ; Not used in GDI+ version 1.0.
                 , EncoderValueScanMethodNonInterlaced  = 8    ; Not used in GDI+ version 1.0.
                 , EncoderValueVersionGif87             = 9    ; Not used in GDI+ version 1.0.
                 , EncoderValueVersionGif89             = 10   ; Not used in GDI+ version 1.0.
                 , EncoderValueRenderProgressive        = 11   ; Not used in GDI+ version 1.0.
                 , EncoderValueRenderNonProgressive     = 12   ; Not used in GDI+ version 1.0.
                 , EncoderValueTransformRotate90        = 13   ; JPEG image, specifies lossless 90-degree clockwise rotation.
                 , EncoderValueTransformRotate180       = 14   ; JPEG image, specifies lossless 180-degree clockwise rotation.
                 , EncoderValueTransformRotate270       = 15   ; JPEG image, specifies lossless 270-degree clockwise rotation.
                 , EncoderValueTransformFlipHorizontal  = 16   ; JPEG image, specifies a lossless horizontal flip.
                 , EncoderValueTransformFlipVertical    = 17   ; JPEG image, specifies a lossless vertical flip.
                 , EncoderValueMultiFrame               = 18   ; Specifies multiple-frame encoding.
                 , EncoderValueLastFrame                = 19   ; Specifies the last frame of a multiple-frame image.
                 , EncoderValueFlush                    = 20   ; Specifies that the encoder object is to be closed.
                 , EncoderValueFrameDimensionTime       = 21   ; Not used in GDI+ version 1.0.
                 , EncoderValueFrameDimensionResolution = 22   ; Not used in GDI+ version 1.0.
                 , EncoderValueFrameDimensionPage       = 23   ; TIFF image, specifies the page frame dimension
                 , EncoderValueColorTypeGray            = 24   ; Undefined
                 , EncoderValueColorTypeRGB             = 25   ; Undefined
        }
        
        Class FillMode {                   ; Specifies how to fill areas that are formed when a path or curve intersects itself.
            Static FillModeAlternate = 0   ; Areas are filled according to the even-odd parity rule.
                 , FillModeWinding   = 1   ; Areas are filled according to the nonzero winding rule.
        }
        
        Class FlushIntention {               ; Specifies when to flush the queue of graphics operations.
            Static FlushIntentionFlush = 0   ; Pending rendering operations are executed and Flush() is not synchronized.
                 , FlushIntentionSync  = 1   ; Pending rendering operations are executed and Flush() is synchronized.
        }
        
        Class FontStyle {                    ; Specifies the style of the typeface of a font.
            Static FontStyleRegular    = 0   ; Normal weight or thickness of the typeface.
                 , FontStyleBold       = 1   ; Bold typeface. Bold is a heavier weight or thickness.
                 , FontStyleItalic     = 2   ; Italic typeface, which produces a noticeable slant to the vertical stems of the characters.
                 , FontStyleBoldItalic = 3   ; Typeface is both bold and italic.
                 , FontStyleUnderline  = 4   ; Underline, which displays a line underneath the baseline of the characters.
                 , FontStyleStrikeout  = 8   ; Strikeout, which displays a horizontal line drawn through the middle of the characters.
        }
        
        Class GenericFontFamily {                   ;
            Static GenericFontFamilySerif     = 0   ; 
                 , GenericFontFamilySansSerif = 1   ; 
                 , GenericFontFamilyMonospace = 2   ; 
        }
        
        Class GpTestControlEnum {                  ;
            Static TestControlForceBilinear  = 0   ;
                 , TestControlNoICM          = 1   ;
                 , TestControlGetBuildNumber = 2   ;
        }
        
        Class HatchStyle {                                 ; Specifies the hatch pattern used by a brush of type HatchBrush.
            Static HatchStyleHorizontal             = 0    ; Horizontal lines.
                 , HatchStyleVertical               = 1    ; Vertical lines.                                                                                                                                                                                                                                         
                 , HatchStyleForwardDiagonal        = 2    ; Diagonal lines that slant to the right from top points to bottom points.
                 , HatchStyleBackwardDiagonal       = 3    ; Diagonal lines that slant to the left from top points to bottom points.
                 , HatchStyleCross                  = 4    ; Horizontal and vertical lines that cross at 90-degree angles.
                 , HatchStyleDiagonalCross          = 5    ; Forward diagonal and backward diagonal lines that cross at 90-degree angles.
                 , HatchStyle05Percent              = 6    ;  5% hatch. The ratio of foreground color to background color is 5:100.
                 , HatchStyle10Percent              = 7    ; 10% hatch. The ratio of foreground color to background color is 10:100.
                 , HatchStyle20Percent              = 8    ; 20% hatch. The ratio of foreground color to background color is 20:100.
                 , HatchStyle25Percent              = 9    ; 25% hatch. The ratio of foreground color to background color is 25:100.
                 , HatchStyle30Percent              = 10   ; 30% hatch. The ratio of foreground color to background color is 30:100.
                 , HatchStyle40Percent              = 11   ; 40% hatch. The ratio of foreground color to background color is 40:100.
                 , HatchStyle50Percent              = 12   ; 50% hatch. The ratio of foreground color to background color is 50:100.
                 , HatchStyle60Percent              = 13   ; 60% hatch. The ratio of foreground color to background color is 60:100.
                 , HatchStyle70Percent              = 14   ; 70% hatch. The ratio of foreground color to background color is 70:100.
                 , HatchStyle75Percent              = 15   ; 75% hatch. The ratio of foreground color to background color is 75:100.
                 , HatchStyle80Percent              = 16   ; 80% hatch. The ratio of foreground color to background color is 80:100.
                 , HatchStyle90Percent              = 17   ; 90% hatch. The ratio of foreground color to background color is 90:100.
                 , HatchStyleLightDownwardDiagonal  = 18   ; Diagonal lines that slant to the right from top points to bottom points and are spaced 50 percent closer together than HatchStyleForwardDiagonal but are not antialiased.
                 , HatchStyleLightUpwardDiagonal    = 19   ; Diagonal lines that slant to the left from top points to bottom points and are spaced 50 percent closer together than HatchStyleBackwardDiagonal but are not antialiased.
                 , HatchStyleDarkDownwardDiagonal   = 20   ; Diagonal lines that slant to the right from top points to bottom points, are spaced 50 percent closer together than HatchStyleForwardDiagonal, and are twice the width of HatchStyleForwardDiagonal but are not antialiased.
                 , HatchStyleDarkUpwardDiagonal     = 21   ; Diagonal lines that slant to the left from top points to bottom points, are spaced 50 percent closer together than HatchStyleBackwardDiagonal, and are twice the width of HatchStyleBackwardDiagonal but are not antialiased.
                 , HatchStyleWideDownwardDiagonal   = 22   ; Diagonal lines that slant to the right from top points to bottom points, have the same spacing as HatchStyleForwardDiagonal, and are triple the width of HatchStyleForwardDiagonal but are not antialiased.
                 , HatchStyleWideUpwardDiagonal     = 23   ; Diagonal lines that slant to the left from top points to bottom points, have the same spacing as HatchStyleBackwardDiagonal, and are triple the width of HatchStyleBackwardDiagonal but are not antialiased.
            Static HatchStyleLightVertical          = 24   ; Vertical lines that are spaced 50 percent closer together than HatchStyleVertical.
                 , HatchStyleLightHorizontal        = 25   ; Horizontal lines that are spaced 50 percent closer together than HatchStyleHorizontal.
                 , HatchStyleNarrowVertical         = 26   ; Vertical lines that are spaced 75 percent closer together than HatchStyleVertical (or 25 percent closer together than HatchStyleLightVertical).
                 , HatchStyleNarrowHorizontal       = 27   ; Horizontal lines that are spaced 75 percent closer together than HatchStyleHorizontal ( or 25 percent closer together than HatchStyleLightHorizontal).
                 , HatchStyleDarkVertical           = 28   ; Vertical lines that are spaced 50 percent closer together than HatchStyleVerical and are twice the width of HatchStyleVertical.
                 , HatchStyleDarkHorizontal         = 29   ; Horizontal lines that are spaced 50 percent closer together than HatchStyleHorizontal and are twice the width of HatchStyleHorizontal.
                 , HatchStyleDashedDownwardDiagonal = 30   ; Horizontal lines that are composed of forward diagonals.
                 , HatchStyleDashedUpwardDiagonal   = 31   ; Horizontal lines that are composed of backward diagonals.
                 , HatchStyleDashedHorizontal       = 32   ; Horizontal dashed lines.
                 , HatchStyleDashedVertical         = 33   ; Vertical dashed lines.
                 , HatchStyleSmallConfetti          = 34   ; A hatch that has the appearance of confetti.
                 , HatchStyleLargeConfetti          = 35   ; A hatch that has the appearance of confetti composed of larger pieces than HatchStyleSmallConfetti.
                 , HatchStyleZigZag                 = 36   ; Horizontal lines of zigzags.
                 , HatchStyleWave                   = 37   ; Horizontal lines of tildes.
                 , HatchStyleDiagonalBrick          = 38   ; A hatch that has the appearance of a wall of bricks laid in a backward diagonal direction.
                 , HatchStyleHorizontalBrick        = 39   ; A hatch that has the appearance of a wall of bricks laid horizontally.
                 , HatchStyleWeave                  = 40   ; A hatch that has the appearance of a woven material.
                 , HatchStylePlaid                  = 41   ; A hatch that has the appearance of a plaid material.
                 , HatchStyleDivot                  = 42   ; A hatch that has the appearance of divots.
                 , HatchStyleDottedGrid             = 43   ; Horizontal and vertical dotted lines that cross at 90-degree angles.
                 , HatchStyleDottedDiamond          = 44   ; Forward diagonal and backward diagonal dotted lines that cross at 90-degree angles.
                 , HatchStyleShingle                = 45   ; A hatch that has the appearance of shingles laid in a forward diagonal direction.
                 , HatchStyleTrellis                = 46   ; A hatch that has the appearance of a trellis.
                 , HatchStyleSphere                 = 47   ; A hatch that has the appearance of a checkerboard of spheres.
                 , HatchStyleSmallGrid              = 48   ; Horizontal and vertical lines that cross at 90-degree angles and are spaced 50 percent closer together than HatchStyleCross.
                 , HatchStyleSmallCheckerBoard      = 49   ; A hatch that has the appearance of a checkerboard.
                 , HatchStyleLargeCheckerBoard      = 50   ; A hatch that has the appearance of a checkerboard with squares that are twice the size of HatchStyleSmallCheckerBoard.
                 , HatchStyleOutlinedDiamond        = 51   ; Forward diagonal and backward diagonal lines that cross at 90-degree angles but are not antialiased.
                 , HatchStyleSolidDiamond           = 52   ; A hatch that has the appearance of a checkerboard placed diagonally.
                 , HatchStyleTotal                  = 53   ; No hatch thereby allowing the brush to be transparent.
                 , HatchStyleLargeGrid              = 4    ; HatchStyleCross.
                 , HatchStyleMin                    = 39   ; HatchStyleHorizonal.
                 , HatchStyleMax                    = 52   ; HatchStyleSolidDiamond.
        }
        
        Class HistogramFormat {               ; Specifies the number and type of histograms that represent the color channels of a bitmap.
            Static HistogramFormatARGB  = 0   ; Returns four histograms: alpha, red, green, and blue channels.
                 , HistogramFormatPARGB = 1   ; Returns four histograms: one each for the alpha, red, green, and blue channels.
                 , HistogramFormatRGB   = 2   ; Returns three histograms: one each for the red, green, and blue channels. 
                 , HistogramFormatGray  = 3   ; Each pixel is converted to a grayscale value and one histogram is returned.
                 , HistogramFormatB     = 4   ; Returns a histogram for the blue channel.
                 , HistogramFormatG     = 5   ; Returns a histogram for the green channel.
                 , HistogramFormatR     = 6   ; Returns a histogram for the red channel.
                 , HistogramFormatA     = 7   ; Returns a histogram for the alpha channel.
        }
        
        Class HotkeyPrefix {              ; Specifies how to display hot keys.
            Static HotkeyPrefixNone = 0   ; No hot key processing occurs.
                 , HotkeyPrefixShow = 1   ; Unicode text is scanned for ampersands (&), which are interpreted as hot key markers.
                 , HotkeyPrefixHide = 2   ; Unicode text is scanned for ampersands (&), which are substituted and removed.
        }
        
        Class ImageCodecFlags {                             ; Indicates attributes of an image codec.                       
            Static ImageCodecFlagsEncoder        = 0x00001  ; Codec supports encoding (saving).
                 , ImageCodecFlagsDecoder        = 0x00002  ; Codec supports decoding (reading).
                 , ImageCodecFlagsSupportBitmap  = 0x00004  ; Codec supports raster images (bitmaps).
                 , ImageCodecFlagsSupportVector  = 0x00008  ; Codec supports vector images (metafiles).
                 , ImageCodecFlagsSeekableEncode = 0x00010  ; Encoder requires a seekable output stream.
                 , ImageCodecFlagsBlockingDecode = 0x00020  ; Decoder has blocking behavior during the decoding process.
                 , ImageCodecFlagsBuiltin        = 0x10000  ; The codec is built in to GDI+.
                 , ImageCodecFlagsSystem         = 0x20000  ; Not used in GDI+ version 1.0.
                 , ImageCodecFlagsUser           = 0x40000  ; Not used in GDI+ version 1.0.
        }        
        
        Class ImageFlags {                                 ; Specifies the attributes of the pixel data contained in an Image object.
            Static ImageFlagsNone              = 0x0       ; No format information.
                 , ImageFlagsScalable          = 0x1       ; Image can be scaled.
                 , ImageFlagsHasAlpha          = 0x2       ; Pixel data contains alpha values.
                 , ImageFlagsHasTranslucent    = 0x4       ; Pixel data has alpha values other than 0 and 255.
                 , ImageFlagsPartiallyScalable = 0x8       ; Pixel data is partially scalable with some limitations.
                 , ImageFlagsColorSpaceRGB     = 0x10      ; Image is stored using an RGB color space.
                 , ImageFlagsColorSpaceCMYK    = 0x20      ; Image is stored using a CMYK color space.
                 , ImageFlagsColorSpaceGRAY    = 0x40      ; Image is a grayscale image.
                 , ImageFlagsColorSpaceYCBCR   = 0x80      ; Image is stored using a YCBCR color space.
                 , ImageFlagsColorSpaceYCCK    = 0x100     ; Image is stored using a YCCK color space.
                 , ImageFlagsHasRealDPI        = 0x1000    ; Dots per inch information is stored in the image.
                 , ImageFlagsHasRealPixelSize  = 0x2000    ; Pixel size is stored in the image.
                 , ImageFlagsReadOnly          = 0x10000   ; Pixel data is read-only.
                 , ImageFlagsCaching           = 0x20000   ; Pixel data can be cached for faster access.                                                 
        }
        
        Class ImageLockMode {                      ; Specifies flags that are passed to the flags parameter of the this.Bitmap.LockBits() method. 
            Static ImageLockModeRead         = 1   ; Portion of the image is locked for reading.
                 , ImageLockModeWrite        = 2   ; Portion of the image is locked for writing.
                 , ImageLockModeUserInputBuf = 4   ; Buffer used for reading or writing pixel data is allocated by the user.
        }
        
        Class ImageType {                  ; Indicates whether an image is a bitmap or a metafile.
            Static ImageTypeUnknown  = 0   ; Image type is not known.
                 , ImageTypeBitmap   = 1   ; Bitmap image.
                 , ImageTypeMetafile = 2   ; Metafile image.
        }
        
        Class InterpolationMode {   ; Specifies the algorithm that is used when images are scaled or rotated.
            Static InterpolationModeInvalid             = -1   ; Used internally.
                 , InterpolationModeDefault             =  0   ; Default interpolation mode.
                 , InterpolationModeLowQuality          =  1   ; Low-quality mode.
                 , InterpolationModeHighQuality         =  2   ; High-quality mode.
                 , InterpolationModeBilinear            =  3   ; Bilinear interpolation. Don't use to shirnk past 50% of original size.
                 , InterpolationModeBicubic             =  4   ; Bicubic interpolation. Don't use to shirnk past 25% of original size.
                 , InterpolationModeNearestNeighbor     =  5   ; nearest-neighbor interpolation.
                 , InterpolationModeHighQualityBilinear =  6   ; high-quality, bilinear interpolation.
                 , InterpolationModeHighQualityBicubic  =  7   ; high-quality, bicubic interpolation.
        }
        
        Class ItemDataPosition {                        ; Specify the location of custom metadata in an image file.
            Static ItemDataPositionAfterHeader  = 0x0   ; Custom metadata is stored after the file header. Valid for JPEG, PNG, and GIF.
                 , ItemDataPositionAfterPalette = 0x1   ; Custom metadata is stored after the palette. Valid for PNG.
                 , ItemDataPositionAfterBits    = 0x2   ; Custom metadata is stored after the pixel data. Valid for GIF and PNG.
        }
        
        Class LinearGradientMode {                          ; Specifies the direction in which the change of color occurs for a linear gradient brush.
            Static LinearGradientModeHorizontal       = 0   ; Color to change in a horizontal direction from the left of the display to the right of the display.
                 , LinearGradientModeVertical         = 1   ; Color to change in a vertical direction from the top of the display to the bottom of the display.
                 , LinearGradientModeForwardDiagonal  = 2   ; Color to change in a forward diagonal direction from the upper-left corner to the lower-right corner of the display.
                 , LinearGradientModeBackwardDiagonal = 3   ; Color to change in a backward diagonal direction from the upper-right corner to the lower-left corner of the display.
        }
        
        Class LineCap {                          ; Specifies the type of graphic shape to use on the end of a line drawn with a Windows GDI+ pen.
            Static LineCapFlat          = 0x0    ; Line ends at the last point. The end is squared off.
                 , LineCapSquare        = 0x1    ; Square cap. The center of the square is the last point in the line.
                 , LineCapRound         = 0x2    ; Circular cap. The center of the circle is the last point in the line.
                 , LineCapTriangle      = 0x3    ; Triangular cap. The base of the triangle is the last point in the line.
                 , LineCapNoAnchor      = 0x10   ; Line ends are not anchored.
                 , LineCapSquareAnchor  = 0x11   ; Line ends are anchored with a square.
                 , LineCapRoundAnchor   = 0x12   ; Line ends are anchored with a circle.
                 , LineCapDiamondAnchor = 0x13   ; Line ends are anchored with a diamond.
                 , LineCapArrowAnchor   = 0x14   ; Line ends are anchored with arrowheads.
                 , LineCapCustom        = 0xFF   ; Line ends are made from a CustomLineCap.
                 , LineCapAnchorMask    = 0xF0   ; Undefined.
        }
        
        Class LineJoin {                      ; Specifies how to join two lines that are drawn by the same pen and whose ends meet. 
            Static LineJoinMiter        = 0   ; Mitered join. This produces a sharp corner or a clipped corner, depending on whether the length of the miter exceeds the miter limit.
                 , LineJoinBevel        = 1   ; Beveled join. This produces a diagonal corner.
                 , LineJoinRound        = 2   ; Circular join. This produces a smooth, circular arc between the lines.
                 , LineJoinMiterClipped = 3   ; Mitered join. This produces a sharp corner or a beveled corner, depending on whether the length of the miter exceeds the miter limit.
        }
        
        Class MatrixOrder {                 ; Specifies the order of multiplication when a new matrix is multiplied by an existing matrix.
            Static MatrixOrderPrepend = 0   ; The new matrix is on the left and the existing matrix is on the right.
                 , MatrixOrderAppend  = 1   ; The existing matrix is on the left and the new matrix is on the right.
        }
        
        Class MetafileFrameUnit {                    ; Specifies the unit of measure for a metafile frame rectangle.
            Static MetafileFrameUnitPixel      = 2   ; Unit is 1 pixel.
                 , MetafileFrameUnitPoint      = 3   ; Unit is 1 pixel.
                 , MetafileFrameUnitInch       = 4   ; Unit is 1 pixel.
                 , MetafileFrameUnitDocument   = 5   ; Unit is 1/300 inch.
                 , MetafileFrameUnitMillimeter = 6   ; Unit is 1 pixel.
                 , MetafileFrameUnitGdi        = 7   ; Unit is 0.01 millimeter.
        }
        
        Class MetafileType {                      ; Specifies types of metafiles.
            Static MetafileTypeInvalid      = 0   ; metafile format that is not recognized in GDI+.
                 , MetafileTypeWmf          = 1   ; WMF file. Such a file contains only GDI records.
                 , MetafileTypeWmfPlaceable = 2   ; WMF file that has a placeable metafile header in front of it.
                 , MetafileTypeEmf          = 3   ; EMF file. Such a file contains only GDI records.
                 , MetafileTypeEmfPlusOnly  = 4   ; EMF+ file. Such a file contains only GDI+ records and must be displayed by using GDI+.
                 , MetafileTypeEmfPlusDual  = 5   ; EMF+ Dual file. Such a file contains GDI+ records along with alternative GDI records and can be displayed by using either GDI or GDI+.
        }
        
        Class ObjectType {                          ; Indicates the object type value of an EMF+ record.
            Static ObjectTypeInvalid         = 0    ; Is invalid.
                 , ObjectTypeBrush           = 1    ; Is a brush.
                 , ObjectTypePen             = 2    ; Is a pen.
                 , ObjectTypePath            = 3    ; Is a path.
                 , ObjectTypeRegion          = 4    ; Is a region.
                 , ObjectTypeImage           = 5    ; Is an image.
                 , ObjectTypeFont            = 6    ; Is a font.
                 , ObjectTypeStringFormat    = 7    ; Is a string format.
                 , ObjectTypeImageAttributes = 8    ; Is an image attribute.
                 , ObjectTypeCustomLineCap   = 9    ; Is a custom line cap.
                 , ObjectTypeGraphics        = 10   ; Is graphics.
                 , ObjectTypeMax             = 10   ; Maximum enumeration value. Currently, ObjectTypeGraphics.
                 , ObjectTypeMin             = 1    ; Minimum enumeration value. Currently, ObjectTypeBrush.
        }
        
        Class PaletteFlags {                   ; Indicates attributes of the color data in a palette.
            Static PaletteFlagsHasAlpha  = 0   ; One or more of the palette entries contains alpha (transparency) information.
                 , PaletteFlagsGrayScale = 1   ; Palette contains only grayscale entries.
                 , PaletteFlagsHalftone  = 2   ; Palette is the Windows halftone palette.
        }
        
        Class PaletteType {                          ; The members of the enumeration identify several standard color palette formats.
            Static PaletteTypeCustom           = 0   ; Arbitrary custom palette provided by the caller.
                 , PaletteTypeOptimal          = 1   ; Palette of colors that are optimal for a particular bitmap.
                 , PaletteTypeFixedBW          = 2   ; Palette that has two colors.
                 , PaletteTypeFixedHalftone8   = 3   ; Palette based on two intensities each (off or full) for the red, green, and blue channels.
                 , PaletteTypeFixedHalftone27  = 4   ; Palette based on three intensities each for the red, green, and blue channels.
                 , PaletteTypeFixedHalftone64  = 5   ; Palette based on four intensities each for the red, green, and blue channels.
                 , PaletteTypeFixedHalftone125 = 6   ; Palette based on five intensities each for the red, green, and blue channels.
                 , PaletteTypeFixedHalftone216 = 7   ; Palette based on six intensities each for the red, green, and blue channels.
                 , PaletteTypeFixedHalftone252 = 8   ; Palette based on 6 intensities of red, 7 intensities of green, and 6 intensities of blue.
                 , PaletteTypeFixedHalftone256 = 9   ; Palette based on 8 intensities of red, 8 intensities of green, and 4 intensities of blue.
        }
        
        Class PathPointType {                         ; Indicates point types and flags for the data points in a path.
            Static PathPointTypeStart        = 0x00   ; The point is the start of a figure.
                 , PathPointTypeLine         = 0x01   ; The point is one of the two endpoints of a line.
                 , PathPointTypeBezier       = 0x03   ; The point is an endpoint or control point of a cubic Bézier spline.
                 , PathPointTypePathTypeMask = 0x07   ; Masks all bits except for the three low-order bits, which indicate the point type.
                 , PathPointTypeDashMode     = 0x10   ; Not used.
                 , PathPointTypePathMarker   = 0x20   ; The point is a marker.
                 , PathPointTypeCloseSubpath = 0x80   ; The point is the last point in a closed subpath (figure).
                 , PathPointTypeBezier3      = 0x03   ; The point is an endpoint or control point of a cubic Bézier spline.
        }
        
        Class PenAlignment {                ; Specifies the alignment of a pen relative to the stroke that is being drawn.
            Static PenAlignmentCenter = 0   ; Pen is aligned on the center of the line that is drawn.
                 , PenAlignmentInset  = 1   ; If drawing a polygon, the pen is aligned on the inside edge of the polygon.
        }
        
        Class PenType {                         ; Indicates the type of pattern, texture, or gradient that a pen draws.
            Static PenTypeSolidColor     =  0   ; Pen draws with a solid color.
                 , PenTypeHatchFill      =  1   ; Pen draws with a hatch pattern that is specified by a HatchBrush object.
                 , PenTypeTextureFill    =  2   ; Pen draws with a texture that is specified by a TextureBrush object.
                 , PenTypePathGradient   =  3   ; Pen draws with a color gradient that is specified by a PathGradientBrush object.
                 , PenTypeLinearGradient =  4   ; Pen draws with a color gradient that is specified by a LinearGradientBrush object.
                 , PenTypeUnknown        = -1   ; Pen type is unknown.
        }
        
        Class PixelOffsetMode {                      ; Specifies the pixel offset mode of a Graphics object.
            Static PixelOffsetModeInvalid     = -1   ; Used internally.
                 , PixelOffsetModeDefault     =  0   ; Equivalent to PixelOffsetModeNone.
                 , PixelOffsetModeHighSpeed   =  1   ; Equivalent to PixelOffsetModeNone.
                 , PixelOffsetModeHighQuality =  2   ; Equivalent to PixelOffsetModeHalf.
                 , PixelOffsetModeNone        =  3   ; Indicates that pixel centers have integer coordinates.
                 , PixelOffsetModeHalf        =  4   ; Indicates that pixel centers have coordinates that are half way between integer values.
        }
        
        Class RotateFlipType {              ; Specifies the direction of an image's rotation and the axis used to flip the image.
            Static RotateNoneFlipNone = 0   ; No rotation and no flipping.
                 , Rotate90FlipNone   = 1   ; 90-degree rotation without flipping.
                 , Rotate180FlipNone  = 2   ; 180-degree rotation without flipping.
                 , Rotate270FlipNone  = 3   ; 270-degree rotation without flipping.
                 , RotateNoneFlipX    = 4   ; No rotation and a horizontal flip.
                 , Rotate90FlipX      = 5   ; 90-degree rotation followed by a horizontal flip.
                 , Rotate180FlipX     = 6   ; 180-degree rotation followed by a horizontal flip.
                 , Rotate270FlipX     = 7   ; 270-degree rotation followed by a horizontal flip.
                 , RotateNoneFlipY    = 6   ; No rotation and a vertical flip.
                 , Rotate90FlipY      = 7   ; 90-degree rotation followed by a vertical flip.
                 , Rotate180FlipY     = 4   ; 180-degree rotation followed by a vertical flip.
                 , Rotate270FlipY     = 5   ; 270-degree rotation followed by a vertical flip.
                 , RotateNoneFlipXY   = 2   ; No rotation, a horizontal flip, and then a vertical flip.
                 , Rotate90FlipXY     = 3   ; 90-degree rotation followed by a horizontal flip and then a vertical flip.
                 , Rotate180FlipXY    = 0   ; 180-degree rotation followed by a horizontal flip and then a vertical flip.
                 , Rotate270FlipXY    = 1   ; 270-degree rotation followed by a horizontal flip and then a vertical flip.
        }
        
        Class SmoothingMode {                       ; Specifies the type of smoothing (antialiasing) that is applied to lines and curves.
            Static SmoothingModeInvalid      = -1   ; Reserved.
                 , SmoothingModeDefault      =  0   ; Smoothing is not applied.
                 , SmoothingModeHighSpeed    =  1   ; Smoothing is not applied.
                 , SmoothingModeHighQuality  =  2   ; Smoothing is applied using an 8 X 4 box filter.
                 , SmoothingModeNone         =  3   ; Smoothing is not applied.
                 , SmoothingModeAntiAlias    =  4   ; Smoothing is applied using an 8 X 4 box filter.
                 , SmoothingModeAntiAlias8x4 =  4   ; Smoothing is applied using an 8 X 4 box filter.
                 , SmoothingModeAntiAlias8x8 =  5   ; Smoothing is applied using an 8 X 8 box filter.
        }
        
        Class Status {                              ; Indicates the result of a Windows GDI+ method call.
            Static Ok                        = 0    ; Method call was successful.
                 , GenericError              = 1    ; There was an error on the method call which is not defined elsewhere in this enumeration.
                 , InvalidParameter          = 2    ; One of the arguments passed to the method was not valid.
                 , OutOfMemory               = 3    ; Operating system is out of memory and could not allocate memory to process the method call. For an explanation of how constructors use the OutOfMemory status, see the Remarks section at the end of this topic.
                 , ObjectBusy                = 4    ; One of the arguments specified in the API call is already in use in another thread.
                 , InsufficientBuffer        = 5    ; A buffer specified as an argument in the API call is not large enough to hold the data to be received.
                 , NotImplemented            = 6    ; The method is not implemented.
                 , Win32Error                = 7    ; The method generated a Win32 error.
                 , WrongState                = 8    ; The object is in an invalid state to satisfy the API call.
                 , Aborted                   = 9    ; The method was aborted.
                 , FileNotFound              = 10   ; The specified image file or metafile cannot be found.
                 , ValueOverflow             = 11   ; The method performed an arithmetic operation that produced a numeric overflow.
                 , AccessDenied              = 12   ; A write operation is not allowed on the specified file.
                 , UnknownImageFormat        = 13   ; The specified image file format is not known.
                 , FontFamilyNotFound        = 14   ; The specified font family is incorrect or the font family is not installed and cannot be found.
                 , FontStyleNotFound         = 15   ; The specified style is not available for the specified font family.
                 , NotTrueTypeFont           = 16   ; The font retrieved from an HDC or LOGFONT is not a TrueType font and cannot be used with GDI+.
                 , UnsupportedGdiplusVersion = 17   ; The version of GDI+ that is installed on the system is incompatible with the version with which the application was compiled.
                 , GdiplusNotInitialized     = 18   ; The GDI+API is not in an initialized state. (This should never happen with this AHK library as the object initialize GDIPlus for you.)
                 , PropertyNotFound          = 19   ; The specified property does not exist in the image.
                 , PropertyNotSupported      = 20   ; The specified property is not supported by the format of the image and, therefore, cannot be set.
                 , ProfileNotFound           = 21   ; The color profile required to save an image in CMYK format was not found.
        }
        
        Class StringAlignment {                ; Specifies how a string is aligned in reference to the bounding rectangle.
            Static StringAlignmentNear   = 0   ; Alignment is towards the origin of the bounding rectangle.
                 , StringAlignmentCenter = 1   ; Alignment is centered between origin and extent (width) of the formatting rectangle.
                 , StringAlignmentFar    = 2   ; Alignment is to the far extent (right side) of the formatting rectangle.
        }
        
        Class StringDigitSubstitute {                     ; Specifies how to substitute digits in a string according to a user's locale or language.
            Static StringDigitSubstituteUser        = 0   ; User-defined substitution scheme.
                 , StringDigitSubstituteNone        = 1   ; Disable substitutions.
                 , StringDigitSubstituteNational    = 2   ; Substitution digits that correspond with the official national language of the user's locale.
                 , StringDigitSubstituteTraditional = 3   ; Substitution digits that correspond with the user's native script or language
        }
        
        Class StringFormatFlags {                                        ; Specifies text layout information (such as orientation and clipping) and display manipulations
            Static StringFormatFlagsDirectionRightToLeft  = 0x1          ; Reading order is right to left.
                 , StringFormatFlagsDirectionVertical     = 0x2          ; Individual lines of text are drawn vertically on the display device.
                 , StringFormatFlagsNoFitBlackBox         = 0x4          ; Parts of characters are allowed to overhang the string's layout rectangle.
                 , StringFormatFlagsDisplayFormatControl  = 0x20         ; Unicode layout control characters are displayed with a representative character.
                 , StringFormatFlagsNoFontFallback        = 0x400        ; Alternate font is used for characters that are not supported in the requested font.
                 , StringFormatFlagsMeasureTrailingSpaces = 0x800        ; Space at the end of each line is included in a string measurement.
                 , StringFormatFlagsNoWrap                = 0x1000       ; Wrapping of text to the next line is disabled.
                 , StringFormatFlagsLineLimit             = 0x2000       ; Only entire lines are laid out in the layout rectangle.
                 , StringFormatFlagsNoClip                = 0x4000       ; Only entire lines are laid out in the layout rectangle.
                 , StringFormatFlagsBypassGDI             = 0x80000000   ; Undefined.
        }
        
        Class StringTrimming {                           ; Specifies how to trim characters from a string so that the string fits into a layout rectangle.
            Static StringTrimmingNone              = 0   ; No trimming is done.
                 , StringTrimmingCharacter         = 1   ; String is broken at the boundary of the last character that is inside the layout rectangle.
                 , StringTrimmingWord              = 2   ; String is broken at the boundary of the last word that is inside the layout rectangle.
                 , StringTrimmingEllipsisCharacter = 3   ; String is broken at the boundary of the last character that is inside the layout rectangle and an ellipsis (...) is inserted after the character.
                 , StringTrimmingEllipsisWord      = 4   ; String is broken at the boundary of the last word that is inside the layout rectangle and an ellipsis (...) is inserted after the word.
                 , StringTrimmingEllipsisPath      = 5   ; Center is removed from the string and replaced by an ellipsis. 
        }
        
        Class TextRenderingHint {                                  ; Specifies the process used to render text. This affects text quality.
            Static TextRenderingHintSystemDefault            = 0   ; Character is drawn using the currently selected system font smoothing mode (also called a rendering hint).
                 , TextRenderingHintSingleBitPerPixelGridFit = 1   ; Character is drawn using its glyph bitmap and hinting to improve character appearance on stems and curvature.
                 , TextRenderingHintSingleBitPerPixel        = 2   ; Character is drawn using its glyph bitmap and no hinting. Better performance at cost of quality.
                 , TextRenderingHintAntiAliasGridFit         = 3   ; Character is drawn using its antialiased glyph bitmap and hinting. Better quality at cost of performance.
                 , TextRenderingHintAntiAlias                = 4   ; Character is drawn using its antialiased glyph bitmap and no hinting.
                 , TextRenderingHintClearTypeGridFit         = 5   ; Character is drawn using its glyph ClearType bitmap and hinting.
        }
        
        Class Unit {                    ; Specifies the unit of measure for a given data type.
            Static UnitWorld      = 0   ; World coordinates, a nonphysical unit.
                 , UnitDisplay    = 1   ; Display specific units.
                 , UnitPixel      = 2   ; Unit is 1 pixel.
                 , UnitPoint      = 3   ; Unit is 1 point or 1/72 inch.
                 , UnitInch       = 4   ; Unit is 1 inch.
                 , UnitDocument   = 5   ; Unit is 1/300 inch.
                 , UnitMillimeter = 6   ; Unit is 1 millimeter.
                 , UnitAbsolute   = 7   ; Unit is memetic for max and is of type easter egg.
        }
        
        Class WarpMode {                     ; Specifies warp modes that can be used to transform images.
            Static WarpModePerspective = 0   ; Perspective warp mode.
                 , WarpModeBilinear    = 1   ; Bilinear warp mode.
        }
        
        Class WrapMode {                    ; Specifies how repeated copies of an image are used to tile an area.
            Static WrapModeTile       = 0   ; Tiling without flipping.
                 , WrapModeTileFlipX  = 1   ; Tiles are flipped horizontally as you move from one tile to the next in a row.
                 , WrapModeTileFlipY  = 2   ; Tiles are flipped vertically as you move from one tile to the next in a column.
                 , WrapModeTileFlipXY = 3   ; Tiles are flipped horizontally as you move along a row and flipped vertically as you move along a column.
                 , WrapModeClamp      = 4   ; No tiling takes place.
        }
    }
    
    ;----------------------------------------------------------------------------
    ; Color matrix
    Class ColorMatrix
    {
        _type   := "ColorMatrix"
        _dt     := "Float"
        __New()
        {
            this.matrix := {0:{0:0, 1:0, 2:0, 3:0, 4:0}
                           ,1:{0:0, 1:0, 2:0, 3:0, 4:0}
                           ,2:{0:0, 1:0, 2:0, 3:0, 4:0}
                           ,3:{0:0, 1:0, 2:0, 3:0, 4:0}
                           ,4:{0:0, 1:0, 2:0, 3:0, 4:0}}
            Return
        }
    }
    
    
    
    ;-------------------------------------------------------------------------------------------------------------------.
    ; GdiplusColor.h                                                                                                    |
    ;___________________________________________________________________________________________________________________|
    
    ;-------------------------------------------------------------------------------------------------------------------.
    ; Color Class - Stores a 32 bit value tha represents Alpha, Red, Blue, and Green values.                            |
    ;-------------------------------------------------------------------------------------------------------------------|
    ; A Color object has Alpha (transparency), Red, Green, and Blue values. Type is ARGB                                |
    ; Properties:                                                                                                       |
    ; .A                Transparency. 0-255                                                                             |
    ; .R                Red value. 0-255                                                                                |
    ; .G                Green value. 0-255                                                                              |
    ; .B                Blue value. 0-255                                                                               |
    ;                                                                                                                   |
    ; Constructors:                                                                                                     |
    ; Color()           Create solid black color object                                                                 |
    ; Color(ColorObj)   Create a color object using the values from the provided color object                           |
    ; Color(ARGB)       Create a color object using an ARGB (a 0xAARRGGBB value)                                        |
    ; Color(r, g, b)    Create a solid color object using the provided red, green and blue values                       |
    ; Color(a, r, g, b) Create a color object using the provided alpha, red, green and blue values                      |
    ;                                                                                                                   |
    ; Methods:                                                                                                          |
    ; .Struct()         Builds ARBG structure and returns pointer.                                                      |
    ; .GetAlpha(hex)    Returns Alpha value.                                                                            |
    ; .GetRed(hex)      Returns Red value.                                                                              |
    ; .GetGreen(hex)    Returns Green value.                                                                            |
    ; .GetBlue(hex)     Returns Blue value.                                                                             |
    ; .GetValue()       Returns an ARBG value.                                                                          |
    ; .SetValue(argb)   Sets color's ARGB values using an ARGB.                                                         |
    ; .MakeARGB(a ,r    Creates an ARGB value using an alpha, red, green, and blue value.                               |
    ;          ,g ,b)                                                                                                   |
    ;                                                                                                                   |
    ; Remarks           An ARGB is a hex number containing 4 values. Alpha, Red, Green, and Blue: 0xAARRGGBB            |
    ;                   Alpha, Red, Green, and Blue values less than 0 are set to 0 & greater than 255 are set to 255.  |
    ;                   Gray and grey are both supported for colors. Ex: DarkGray and DarkGrey both return 0xFFA9A9A9   |
    ;___________________________________________________________________________________________________________________|
    Class Color
    {
        _type := "Color"
        ,A    := ""
        ,R    := ""
        ,G    := ""
        ,B    := ""
        
        ; ############################
        ; ## COMMON COLOR CONSTANTS ##
        ; ############################
            ; Special
        Static Transparent      = 0x00FFFFFF
        
            ; Black and gray/grey               ; White
        Static Black            = 0xFF000000    , AliceBlue            = 0xFFF0F8FF
            , DarkGray          = 0xFFA9A9A9    , AntiqueWhite         = 0xFFFAEBD7
            , DarkGrey          = 0xFFA9A9A9    , Azure                = 0xFFF0FFFF
            , DarkSlateGray     = 0xFF2F4F4F    , Beige                = 0xFFF5F5DC
            , DarkSlateGrey     = 0xFF2F4F4F    , FloralWhite          = 0xFFFFFAF0
            , DimGray           = 0xFF696969    , GhostWhite           = 0xFFF8F8FF
            , DimGrey           = 0xFF696969    , Honeydew             = 0xFFF0FFF0
            , Gainsboro         = 0xFFDCDCDC    , Ivory                = 0xFFFFFFF0
            , Gray              = 0xFF808080    , LavenderBlush        = 0xFFFFF0F5
            , Grey              = 0xFF808080    , Linen                = 0xFFFAF0E6
            , LightGray         = 0xFFD3D3D3    , MintCream            = 0xFFF5FFFA
            , LightGrey         = 0xFFD3D3D3    , MistyRose            = 0xFFFFE4E1
            , LightSlateGray    = 0xFF778899    , OldLace              = 0xFFFDF5E6
            , LightSlateGrey    = 0xFF778899    , Seashell             = 0xFFFFF5EE
            , Silver            = 0xFFC0C0C0    , Snow                 = 0xFFFFFAFA
            , SlateGray         = 0xFF708090    , White                = 0xFFFFFFFF
            , SlateGrey         = 0xFF708090    , WhiteSmoke           = 0xFFF5F5F5
            
            ; Red                               ; Pink
        Static Crimson          = 0xFFDC143C    , DeepPink             = 0xFFFF1493
            , DarkRed           = 0xFF8B0000    , HotPink              = 0xFFFF69B4
            , DarkSalmon        = 0xFFE9967A    , LightPink            = 0xFFFFB6C1
            , Firebrick         = 0xFFB22222    , MediumVioletRed      = 0xFFC71585
            , IndianRed         = 0xFFCD5C5C    , PaleVioletRed        = 0xFFDB7093
            , LightCoral        = 0xFFF08080    , Pink                 = 0xFFFFC0CB
            , LightSalmon       = 0xFFFFA07A    
            , Red               = 0xFFFF0000    
            , Salmon            = 0xFFFA8072    
            
            ; Green                             ; Yellow
        Static Chartreuse       = 0xFF7FFF00    , Bisque               = 0xFFFFE4C4
            , DarkGreen         = 0xFF006400    , BlanchedAlmond       = 0xFFFFEBCD
            , DarkOliveGreen    = 0xFF556B2F    , Burlywood            = 0xFFDEB887
            , ForestGreen       = 0xFF228B22    , Cornsilk             = 0xFFFFF8DC
            , Green             = 0xFF008000    , DarkKhaki            = 0xFFBDB76B
            , GreenYellow       = 0xFFADFF2F    , Gold                 = 0xFFFFD700
            , LawnGreen         = 0xFF7CFC00    , Khaki                = 0xFFF0E68C
            , LightGreen        = 0xFF90EE90    , LemonChiffon         = 0xFFFFFACD
            , Lime              = 0xFF00FF00    , LightGoldenrodYellow = 0xFFFAFAD2
            , LimeGreen         = 0xFF32CD32    , LightYellow          = 0xFFFFFFE0
            , MediumAquamarine  = 0xFF66CDAA    , Moccasin             = 0xFFFFE4B5
            , MediumSeaGreen    = 0xFF3CB371    , NavajoWhite          = 0xFFFFDEAD
            , MediumSpringGreen = 0xFF00FA9A    , PaleGoldenrod        = 0xFFEEE8AA
            , Olive             = 0xFF808000    , PapayaWhip           = 0xFFFFEFD5
            , OliveDrab         = 0xFF6B8E23    , PeachPuff            = 0xFFFFDAB9
            , PaleGreen         = 0xFF98FB98    , Wheat                = 0xFFF5DEB3
            , SeaGreen          = 0xFF2E8B57    , Yellow               = 0xFFFFFF00
            , SpringGreen       = 0xFF00FF7F    
            , YellowGreen       = 0xFF9ACD32    
            
            ; Blue                              ; Cyan
        Static Blue             = 0xFF0000FF    , Aqua                 = 0xFF00FFFF
            , CornflowerBlue    = 0xFF6495ED    , Aquamarine           = 0xFF7FFFD4
            , DarkBlue          = 0xFF00008B    , CadetBlue            = 0xFF5F9EA0
            , DeepSkyBlue       = 0xFF00BFFF    , Cyan                 = 0xFF00FFFF
            , DodgerBlue        = 0xFF1E90FF    , DarkCyan             = 0xFF008B8B
            , LightBlue         = 0xFFADD8E6    , DarkTurquoise        = 0xFF00CED1
            , LightSkyBlue      = 0xFF87CEFA    , LightCyan            = 0xFFE0FFFF
            , LightSteelBlue    = 0xFFB0C4DE    , LightSeaGreen        = 0xFF20B2AA
            , MediumBlue        = 0xFF0000CD    , MediumTurquoise      = 0xFF48D1CC
            , MidnightBlue      = 0xFF191970    , PaleTurquoise        = 0xFFAFEEEE
            , Navy              = 0xFF000080    , Teal                 = 0xFF008080
            , PowderBlue        = 0xFFB0E0E6    , Turquoise            = 0xFF40E0D0
            , RoyalBlue         = 0xFF4169E1    
            , SkyBlue           = 0xFF87CEEB    
            , SteelBlue         = 0xFF4682B4    
            
            ; Purple/magenta                    ; Orange
        Static BlueViolet       = 0xFF8A2BE2    , Coral                = 0xFFFF7F50
            , DarkMagenta       = 0xFF8B008B    , DarkOrange           = 0xFFFF8C00
            , DarkOrchid        = 0xFF9932CC    , Orange               = 0xFFFFA500
            , DarkSlateBlue     = 0xFF483D8B    , OrangeRed            = 0xFFFF4500
            , DarkViolet        = 0xFF9400D3    , Tomato               = 0xFFFF6347
            , Fuchsia           = 0xFFFF00FF    
            , Indigo            = 0xFF4B0082    ; Brown
            , Lavender          = 0xFFE6E6FA    , Brown                = 0xFFA52A2A
            , Magenta           = 0xFFFF00FF    , Chocolate            = 0xFFD2691E
            , MediumOrchid      = 0xFFBA55D3    , DarkGoldenrod        = 0xFFB8860B
            , MediumPurple      = 0xFF9370DB    , Goldenrod            = 0xFFDAA520
            , MediumSlateBlue   = 0xFF7B68EE    , Maroon               = 0xFF800000
            , Orchid            = 0xFFDA70D6    , Peru                 = 0xFFCD853F
            , Plum              = 0xFFDDA0DD    , RosyBrown            = 0xFFBC8F8F
            , Purple            = 0xFF800080    , SaddleBrown          = 0xFF8B4513
            , SlateBlue         = 0xFF6A5ACD    , SandyBrown           = 0xFFF4A460
            , Thistle           = 0xFFD8BFD8    , Sienna               = 0xFFA0522D
            , Violet            = 0xFFEE82EE    , Tan                  = 0xFFD2B48C
        
        ; Color()
        ; Color(ColorObject)
        ; Color(ARGB)
        ; Color(red, blue, green)
        ; Color(alpha, red, blue, green)
        __New(a="", r="", g="", b="")
        {
            this.SetCapacity("_struct", 4)
            ,this.structP := this.GetAddress("_struct")
            ,(a._type == "Color" && r = "" && g = "" && b = "")     ; Color object
                ? this._set_color(a.A, a.R, a.G, a.B)
            : ((a >= 0 && a <= 0xFFFFFFFF) && r="" && g="" && b="") ; ARGB (0xAARRGGBB)
                ? this.SetValue(a)
            : (a="" && r="" && g="" && b="")                        ; All Empty
                ? this._set_color(255, 0, 0, 0)
            : (b = "")                                              ; R G B values
                ? this._set_color(255, a, r, g)
                : this._set_color(a, r, g, b)                       ; A R G B values 
        }
        
        ; Remark: Values fallling out of the 0-255 range will be rounded
        _set_color(a, r, g, b)
        {
             this.A := (a < 0) ? 0 : (a > 255) ? 255 : a
            ,this.R := (r < 0) ? 0 : (r > 255) ? 255 : r
            ,this.G := (g < 0) ? 0 : (g > 255) ? 255 : g
            ,this.B := (b < 0) ? 0 : (b > 255) ? 255 : b
        }
        
        show()
        {
            ptr   := this.Struct()
            ,a    := NumGet(ptr+0, 3, "UChar")
            ,r    := NumGet(ptr+0, 2, "UChar")
            ,g    := NumGet(ptr+0, 1, "UChar")
            ,b    := NumGet(ptr+0, 0, "UChar")
            ,argb := this.GetValue()
            MsgBox, % this._type " object:"
                . "`nstructP: "   this.structP
                . "`nA: "         GDIP.to_hex(this.A) " | " this.A
                . "`nR: "         GDIP.to_hex(this.R) " | " this.R
                . "`nB: "         GDIP.to_hex(this.B) " | " this.B
                . "`nG: "         GDIP.to_hex(this.G) " | " this.G
                . "`nNumGet A: "  GDIP.to_hex(a) " | " a
                . "`nNumGet R: "  GDIP.to_hex(r) " | " r
                . "`nNumGet G: "  GDIP.to_hex(g) " | " g
                . "`nNumGet B: "  GDIP.to_hex(b) " | " b
                . "`nARBG: "      GDIP.to_hex(argb) " | " argb
        }
        
        Struct()
        {
             NumPut(this.B, this.structP+0, 0, "UChar")
            ,NumPut(this.G, this.structP+0, 1, "UChar")
            ,NumPut(this.R, this.structP+0, 2, "UChar")
            ,NumPut(this.A, this.structP+0, 3, "UChar")
            Return this.structP+0
        }
        
        GetAlpha(hex=0) {
            Return (hex ? GDIP.to_hex(this.A) : this.A)
        }
        
        GetRed(hex=0) {
            Return (hex ? GDIP.to_hex(this.R) : this.R)
        }
        
        GetGreen(hex=0) {
            Return (hex ? GDIP.to_hex(this.G) : this.G)
        }
        
        GetBlue(hex=0) {
            Return (hex ? GDIP.to_hex(this.B) : this.B)
        }
        
        GetValue(hex=0) {
            argb := (this.A << this.A_Shift)
                 +  (this.R << this.R_Shift)
                 +  (this.G << this.G_Shift)
                 +   this.B
            Return (hex ? GDIP.to_hex(argb) : argb)
        }
        
        SetValue(argb) {
             this.A := (argb & this.A_Mask) >> this.A_Shift
            ,this.R := (argb & this.R_Mask) >> this.R_Shift
            ,this.G := (argb & this.G_Mask) >> this.G_Shift
            ,this.B := (argb & this.B_Mask)
        }
        
        ; Takes four 8-bit values (0-255) and returns a 32-bit combined
        MakeARGB(a, r, g, b)
        {
            Return ( (a << this.A_Shift)
                   + (r << this.R_Shift)
                   + (g << this.G_Shift)
                   +  b )
        }        
        
        ; ; I don't think these two will be needed, so they're staying commented out for now
        ; ; Set ARGB value using a COLORREF
        ; SetFromCOLORREF()
        ; {
        ;     Return
        ; }
        ; 
        ; ; Converts ARGB value to a COLORREF
        ; ToCOLORREF(ARGB)
        ; {
        ;     Return
        ; }
        
        ; ARGB masks and bitshifts
        Static A_Mask  := 0xFF000000
             , R_Mask  := 0x00FF0000
             , G_Mask  := 0x0000FF00
             , B_Mask  := 0x000000FF
             , A_Shift := 24
             , R_Shift := 16
             , G_Shift := 8
             , B_Shift := 0
    }
    
    
    ;-------------------------------------------------------------------------------------------------------------------.
    ; GdiplusTypes.h                                                                                                    |
    ;___________________________________________________________________________________________________________________|
    
    ;-------------------------------------------------------------------------------------------------------------------.
    ; Point Class - Represents a location in a 2D coordinate system                                                     |
    ;-------------------------------------------------------------------------------------------------------------------|
    ; A Point object contains x and y coordinate values.                                                                |
    ; Properties:                                                                                                       |
    ; .X                X coord                                                                                         |
    ; .Y                Y coord                                                                                         |
    ; ._float           Set to 1 if Point is of Float type. Default is 0 which is Int.                                  |
    ;                                                                                                                   |
    ; Constructors:                                                                                                     |
    ; Point()           Set X and Y to 0                                                                                |
    ; Point(x, y)       Set X and Y to number                                                                           |
    ; Point(Point)      Set X to Point.X and Y to Point.Y                                                               |
    ; Point(Size)       Set X to Size.width and Y to Size.height                                                        |
    ;                                                                                                                   |
    ; Methods:                                                                                                          |
    ; .Struct()         Create struct and return pointer to it.                                                         |
    ; .Plus(Point)      Return a new Point object with Point and NativePoint values summed                              |
    ; .Minus(Point)     Return a new Point object with Point and NativePoint values differenced                         |
    ; .Equals(Point)    Return True if Point and NativePoint have equal values                                          |
    ;                                                                                                                   |
    ; Remarks           You cannot use + and - operators on Points like in C++. Use: p1.plus(p2) or p1.minus(p2)        |
    ;___________________________________________________________________________________________________________________|
    Class Point
    {
        _type  := "Point"
        _float := 0
        Width  := ""
        Height := ""
        
        ; ## Constructor ##
        ; Point()
        ; Point(x, y)
        ; Point(Point)
        ; Point(Size)
        __New(x="", y="")
        {
             this.SetCapacity("_struct", 8)
            ,this.structP := this.GetAddress("_struct")
            
            ,(x = "" && y = "")                     ; empty
                ? this._set_xy(0, 0)
            : (GDIP.is_num(x) && GDIP.is_num(y))    ; numbers
                ? this._set_xy(x, y)
            : (x._type == "Point" && y = "")        ; Point
                ? this._set_xy(x.X, x.Y)
            : (x._type == "Size" && y = "")         ; Size
                ? this._set_xy(x.Width, x.Height)
            : GDIP.error_log(A_ThisFunc, "Point constructor error."
                , "Empty: Point()`nFrom two numbers: Point(x, y)"
                . "`nFrom another Point: Point(Point)`nFrom a Size: Point(Size)"
                , {p1:w, p2:h})
        }
        
        Show()
        {
            ptr := this.Struct()
            ,type := (this._float) ? "Float" : "Int"
            MsgBox, % this._type " Object:"
                . "`nthis.X: "       this.X
                . "`nthis.Y: "       this.Y
                . "`nthis.structP: " this.structP
                . "`nSturct x: "     NumGet(ptr, 0, type)
                . "`nSturct y: "     NumGet(ptr, 4, type)
            Return
        }
        
        _set_xy(x, y)
        {
             this.X := x
            ,this.Y := y
        }
        
        ; Return    Pointer to struct
        Struct()
        {
             type := (this._float) ? "Float" : "Int"
            ,NumPut(this.X, this.structP+0, 0, type)
            ,NumPut(this.Y, this.structP+0, 4, type)
            Return structP+0
        }
        
        Plus(Point)
        {
            Return new GDIP.Point(this.X + Point.X, this.Y + Point.Y)
        }
        
        Minus(Point)
        {
            Return new GDIP.Point(this.X - Point.X, this.Y - Point.Y )
        }
        
        Equals(Point)
        {
            Return (this.X = Point.X && this.Y = Point.Y) ? 1 : 0
        }
    }
    
    ;-------------------------------------------------------------------------------------------------------------------.
    ; Size Class - Represents a dimension in a 2D coordinate system                                                     |
    ;-------------------------------------------------------------------------------------------------------------------|
    ; A Size object contains width and height values.                                                                   |
    ; Properties:                                                                                                       |
    ; .Width            Size Width                                                                                      |
    ; .Height           Size Height                                                                                     |
    ; ._float           Set to 1 if Size is of Float type. Default is 0 which is Int.                                   |
    ;                                                                                                                   |
    ; Constructors:                                                                                                     |
    ; Size()            Set Width and Height to 0                                                                       |
    ; Size(num1, num2)  Set Width to num1 and Height to num2                                                            |
    ; Size(Size)        Set Width to Size.Width and Height to Size.Height                                               |
    ;                                                                                                                   |
    ; Methods:                                                                                                          |
    ; .Struct(type)     Create struct a struct and return pointer to it.                                                |
    ; .Plus(Size)       Return a new Size object with sum of Size and NativeSize values                                 |
    ; .Minus(Size)      Return a new Size object with difference of NativeSize and Size values                          |
    ; .Equals(Size)     Return True if Size and NativeSize have equal values                                            |
    ; .Empty()          Return true if width or height <= 0                                                             |
    ;                                                                                                                   |
    ; Remarks           You cannot use + and - operators on Sizes like in C++. Use: s1.plus(s2) or s1.minus(s2)         |
    ;___________________________________________________________________________________________________________________|
    Class Size
    {
        _type  := "Size"
        _float := 0
        Width  := ""
        Height := ""
        
        ; ## Constructor ##
        ; Size()
        ; Size(width, height)
        ; Size(Size)
        __New(w="", h="")
        {
             this.SetCapacity("_struct", 8)
            ,this.structP := this.GetAddress("_struct")
            
            ,(w = "" && h = "")
                ? this._set_wh(0, 0)
            : (GDIP.is_num(w) && GDIP.is_num(h))
                ? this._set_wh(w, h)
            : (w._type == "Size" && h = "")
                ? this._set_wh(w.Width, w.Height)
            : GDIP.error_log(A_ThisFunc, "Size constructor error."
                  , "Empty: Size()`nFrom two numbers: Size(width, height)"
                  . "`nFrom another Size: Size(Size)", {p1:w, p2:h})
        }
        
        Show(type="")
        {
            ptr := this.Struct()
            ,type := (this._float) ? "Float" : "Int"
            MsgBox, % "Size Object:"
                . "`nthis.Width: "    this.Width
                . "`nthis.Height: "   this.Height
                . "`nthis.structP: "  this.structP
                . "`nSturct width: "  NumGet(ptr, 0, type)
                . "`nSturct height: " NumGet(ptr, 4, type)
            Return
        }
        
        _set_wh(w, h)
        {
             this.Width  := w
            ,this.Height := h
        }
        
        ; type      Pass expected structure type
        Struct(type="")
        {
             type := (this._float) ? "Float" : "Int"
            ,NumPut(this.Width,  this.structP+0, 0, type)
            ,NumPut(this.Height, this.structP+0, 4, type)
            Return structP+0
        }
        
        Plus(Size)
        {
            Return new GDIP.Size(this.Width + Size.Width, this.Height + Size.Height)
        }
        
        Minus(Size)
        {
            Return new GDIP.Size(this.Width - Size.Width, this.Height - Size.Height)
        }
        
        Equals(Size)
        {
            Return (this.Width = Size.Width && this.Height = Size.Height) ? 1 : 0
        }
        
        Empty()
        {
            Return (this.Width <= 0 || this.Height <= 0) ? 1 : 0
        }
    }
    
    ;-------------------------------------------------------------------------------------------------------------------.
    ; Rect Class - Represents a rectangle in a 2D coordinate system                                                     |
    ;-------------------------------------------------------------------------------------------------------------------|
    ; A Rect object contains X, Y, Width, and Height values as well as left, right, top, and bottom edge coords.        |
    ; Properties:                                                                                                       |
    ; .X                X location                                                                                      |
    ; .Y                Y location                                                                                      |
    ; .Width            Rect Width including border                                                                     |
    ; .Height           Rect Height including border                                                                    |
    ; .Left             X coordinate of Left edge                                                                       |
    ; .Top              Y coordinate of Top edge                                                                        |
    ; .Right            X coordinate of Right edge                                                                      |
    ; .Bottom           Y coordinate of Bottom edge                                                                     |
    ; ._float           Set to 1 if Rect is of Float type. Default is 0 which is Int.                                   |
    ;                                                                                                                   |
    ; Constructors:                                                                                                     |
    ; Rect()            X, Y, Width, and Height = 0                                                                     |
    ; Rect(x, y, w, h)  X=x, Y=y, Width=w Height=h                                                                      |
    ; Rect(Point, Size) X=Point.X, Y=Point.Y, Width=Size.Width, Height=Size.Height                                      |
    ;                                                                                                                   |
    ; Methods:                                                                                                          |
    ; .Struct(type)     Create struct with current values and return pointer to it. type can be any 4 byte data type.   |
    ; .Clone()          Return new Rect object with copy of NativeRect's values.                                        |
    ; .GetLocation(Point) Store X and Y values of NativeRect into Point object.                                         |
    ; .GetSize(Size)    Store Width and Height values of Rect into Size object.                                         |
    ; .GetBounds(Rect)  Update Rect values with NativeRect's values.                                                    |
    ; .GetLeft()        Use the .Left   property.                                                                       |
    ; .GetTop()         Use the .Top    property.                                                                       |
    ; .GetRight()       Use the .Right  property.                                                                       |
    ; .GetBottom()      Use the .Bottom property.                                                                       |
    ; .IsEmptyArea()    Return True if width or height <= 0.                                                            |
    ; .Equals(Rect)     Return True if NativeRect and Rect have equal values.                                           |
    ; .Contains(x, y)   Return True if the (x,y) coordinate provided falls inside NativeRect.                           |
    ; .Contains(Point)  Return True if the Point provided falls inside NativeRect.                                      |
    ; .Inflate(dx, dy)  Increase width of NativeRect by dx and height by dy. Sizes decreases if negative.               |
    ; .Inflate(Point)   Increases width by Point.X and Height by Point.Y. Sizes decreases if negative.                  |
    ; .Intersect(Rect)  Update NativeRect values to the intersect values of NativeRect and Rect.                        |
    ; .Intersect(R1, R2 Update ROut values to the intersect values of R1 and R2.                                        |
    ;           , ROut)                                                                                                 |
    ; .IntersectsWith(Rect) Return true if Rect intersects with NativeRect                                              |
    ; .Union(Rect1)     Update NativeRect to the values needed to unionize Rect1 and NativeRect.                        |
    ; .Union(R1, R2     Update RectOut to the values needed to unionize R1 and R2.                                      |
    ;       ,RectOut)                                                                                                   |
    ; .Offset(dx, dy)   Update NativeRect x,y with dx,dy                                                                |
    ; .Offset(Point)    Update NativeRect x,y with Point.X,Point.Y                                                      |
    ;                                                                                                                   |
    ; Remarks           A return value of "" means there was a parameter error.                                         |
    ;                   Struct type is updated to the requested type at .Struct() call.                                 |
    ;___________________________________________________________________________________________________________________|
    Class Rect
    {
         _type  := "Rect"
        ,_float := 0
        ,X      := Left   := ""
        ,Y      := Top    := ""
        ,Width  := Right  := ""
        ,Height := Bottom := ""
        
        ; ## Constructor ##
        ; Rect()
        ; Rect(x, y, width, height)
        ; Rect(Point, Size)
        __New(x="", y="", w="", h="")
        {
            this.SetCapacity("_struct", 16)
            ,this.structP := this.GetAddress("_struct")
            
            ,(x = "" && y = "" && w = "" && h = "")
                ? this._set_xywh(0, 0, 0, 0)
            : (GDIP.is_num(x) && GDIP.is_num(y) && GDIP.is_num(w) && GDIP.is_num(h))
                ? this._set_xywh(x, y, w, h)
            : (x._type == "Point" && y._type == "Size" && w = "" && h = "")
                ? this._set_xywh(x.X, x.Y, y.Width, y.Height)
            : GDIP.error_log(A_ThisFunc, "Invalid Parameter", "Empty: Rect()"
                . "`nNumbers: Rect(n1, n2, n3, n4)`nPoint and Size Object: Rect(Point, Size)"
                , {p1:x, p2:y, p3:w, p4:h})
        }
        
        _set_xywh(x, y, w, h)
        {
             this.Left   := this.X       := x
            ,this.Top    := this.Y       := y
            ,this.Right  := x + w
            ,this.Bottom := y + h
            ,this.Width  := w
            ,this.Height := h
        }
        
        _set_edge(l, t, r, b)
        {
             this.X      := this.Left    := l
            ,this.Y      := this.Top     := t
            ,this.Width  := (this.Right  := r) - l
            ,this.Height := (this.Bottom := b) - t
        }
        
        ; type      Pass expected structure type
        ; Return    Pointer to struct
        Struct(type="")
        {
             type := (this._float) ? "Float" : "Int"
            ,NumPut(this.X,      this.structP+0,  0, type)
            ,NumPut(this.Y,      this.structP+0,  4, type)
            ,NumPut(this.Width,  this.structP+0,  8, type)
            ,NumPut(this.Height, this.structP+0, 12, type)
            Return structP+0
        }
        
        Show(type="") ; Used for testing purposes
        {
            ptr := this.Struct()
            ,type := (this._float) ? "Float" : "Int"
            MsgBox, % this._type " object:"
                . "`nthis.structP: "  this.structP
                . "`nthis.X: "        this.X
                . "`nthis.Y: "        this.Y
                . "`nthis.Width: "    this.Width
                . "`nthis.Height: "   this.Height
                . "`nLeft: "          this.Left
                . "`nTop: "           this.Top
                . "`nRight: "         this.Right
                . "`nBottom: "        this.Bottom
                . "`nStruct X: "      (x := NumGet(ptr,  0, type))
                . "`nStruct Y: "      (y := NumGet(ptr,  4, type))
                . "`nStruct Width: "  (w := NumGet(ptr,  8, type))
                . "`nStruct Height: " (h := NumGet(ptr, 12, type))
                . "`nStruct Left: "   x
                . "`nStruct Top: "    y
                . "`nStruct Right: "  x+w
                . "`nStruct Bottom: " y+h
            Return
        }
        
        ; ## METHODS ##
        Clone()
        {
            Return new GDIP.Rect(this.X, this.Y, this.Width, this.Height)
        }
        
        GetLocation(Point)
        {
            Point._set_xy(this.X, this.Y)
        }
        
        GetSize(Size)
        {
            Size._set_wh(this.Width, this.Height)
        }
        
        GetBounds(Rect)
        {
            Rect._set_xywh(this.X, this.Y, this.Width, this.Height)
        }
        
        IsEmptyArea()
        {
            Return (this.Width <= 0 || this.Height <= 0) ? 1 : 0
        }
        
        Equals(Rect)
        {
            Return (this.X = Rect.X && this.Y = Rect.Y && this.Width = Rect.Width && this.Height = Rect.Height) ? 1 : 0
        }
        
        ; Contains(x, y)
        ; Contains(Point)
        ; Contains(Rect)
        ; Return: 1 = True, 0 = False, "" = Error
        Contains(x, y="")
        {
            Return (x._type == "Point" && y = "") ; Point object
                    ? (x.X >= this.X && x.Y >= this.Y && x.X < this.Right && x.Y < this.Bottom)
                        ? 1 : 0
                : (x._type == "Rect" && y = "") ; Rect object
                    ? (Rect.X >= this.X && Rect.Y >= this.Y && Rect.X < this.Right && Rect.Y < this.Bottom)
                        ? 1 : 0
                : (x >= this.X && y >= this.Y && x < this.Right && y < this.Bottom) ; x,y coords
                        ? 1 : 0
        }
        
        ; Inflate(dx, dy)
        ; Inflate(Point)
        Inflate(dx, dy="")
        {
            (dx._type == "Point" && dy = "")
                ? this._set_xywh(this.Width + (dx.X*2) ; Point object
                                ,this.Height + (dx.Y*2)
                                ,this.X - dx.X
                                ,this.Y - dx.Y )
                : this._set_xywh(this.Width + (dx*2) ; dx,dy
                                ,this.Height + (dy*2)
                                ,this.X - dx
                                ,this.Y - dy )
        }
        
        ; Intersect(Rect)
        ; Intersect(Rect1, Rect2, RectOut)
        ; Return        0 = Empty, 1 = Not Empty, "" = Error
        Intersect(Rect1, Rect2="", ByRef RectOut="")
        {
            (Rect1._type == "Rect" && Rect2 = "" && RectOut = "") ; Rect object
                ? (this._set_edge(GDIP.get_max(this.Left  , Rect1.Left  )
                                 ,GDIP.get_max(this.Top   , Rect1.Top   )
                                 ,GDIP.get_min(this.Right , Rect1.Right )
                                 ,GDIP.get_min(this.Bottom, Rect1.Bottom) )
                  ,status := !this.IsEmptyArea() )
                : (RectOut._set_edge(GDIP.get_max(Rect1.Left  , Rect2.Left  )
                                    ,GDIP.get_max(Rect1.Top   , Rect2.Top   )
                                    ,GDIP.get_min(Rect1.Right , Rect2.Right )
                                    ,GDIP.get_min(Rect1.Bottom, Rect2.Bottom) )
                  ,status := !RectOut.IsEmptyArea() )
            
            Return status
        }
        
        IntersectsWith(Rect)
        {
            Return ((this.Left   < Rect.Right )
                &&  (this.Top    > Rect.Bottom)
                &&  (this.Right  > Rect.Left  )
                &&  (this.Bottom < Rect.Top   ) ) ? 1 : 0
        }
        
        ; Return        0 = Empty, 1 = Not Empty, "" = Error
        Union(Rect1, Rect2="", ByRef RectOut="")
        {
            (Rect1._type == "Rect" && Rect2 = "" && RectOut = "") ; Rect object
                ? (this._set_edge(GDIP.get_min(this.Left  , Rect1.Left  )
                                 ,GDIP.get_min(this.Top   , Rect1.Top   )
                                 ,GDIP.get_max(this.Right , Rect1.Right )
                                 ,GDIP.get_max(this.Bottom, Rect1.Bottom) )
                  ,status := !this.IsEmptyArea() )
                : (RectOut._set_edge(GDIP.get_min(Rect1.Left  , Rect2.Left  )
                                    ,GDIP.get_min(Rect1.Top   , Rect2.Top   )
                                    ,GDIP.get_max(Rect1.Right , Rect2.Right )
                                    ,GDIP.get_max(Rect1.Bottom, Rect2.Bottom) )
                  ,status := !this.IsEmptyArea() )
            
            Return status
        }
        
        ; Offset(x, y)
        ; Offset(Point)
        Offset(dx, dy="")
        {
            (dx._type = "Point" && y = "")
                ? this._set_xywh(this.X + dx.X, this.Y + dx.Y, this.width, this.height)
                : this._set_xywh(this.X + dx  , this.Y + dy  , this.width, this.height)
        }
    }
    
    
    
    ;-------------------------------------------------------------------------------------------------------------------.
    ; GUID (Globally Unique Identifier) Class - Used to create and get information about a GUID.                        |
    ;-------------------------------------------------------------------------------------------------------------------|
    ; A GUID object stores a native GUID, a pointer to that GUID, and the string version of it.                         |
    ; Properties:                                                                                                       |
    ; .pointer          Pointer to the native GUID                                                                      |
    ; .string           String of the native GUID                                                                       |
    ; .ptr              Same as .pointer                                                                                |
    ; .str              Same as .string                                                                                 |
    ;                                                                                                                   |
    ; Constructors:                                                                                                     |
    ; GUID()            Create a new and unique GUID object                                                             |
    ; GUID(guidStr)     Create a new GUID object based on the provided string                                           |
    ; GUID(guidPtr)     Create a new GUID object using the provided GUID pointer                                        |
    ;                                                                                                                   |
    ; Methods:                                                                                                          |
    ; get_string(ptr)   Returns GUID string if success or a blank string if fail                                        |
    ; get_pointer(str)  Returns GUID pointer if success or a blank string if fail                                       |
    ;                                                                                                                   |
    ; Remark            Opening/closing brackets {} and hyphens - are optional.                                         |
    ;                   GUID strings must be 32 hex digits long.                                                        |
    ;                   Expected GUID string format: {D3A1DBE1-8EC4-4C17-9F4C-EA97AD1C343D}                             |
    ;___________________________________________________________________________________________________________________|
    Class GUID
    {
        Static _rgx_guid := "\{?([\d|A-F|a-f]{8})-?([[\d|A-F|a-f]{4})-?([\d|A-F|a-f]{4})-?([\d|A-F|a-f]{4})-?([\d|A-F|a-f]{12})\}?"
            , _rgx_hex  := "[\d|A-F|a-f]+"
        
        _type   := "GUID"
        ,_str   := ""
        ,_ptr   := ""
        
        __New(guid="")
        {
            m := ""
            ,(guid = "")
                ? this.new_guid()
            : RegExMatch(guid, this._rgx_guid, m)
                ? (this._str := "{" m1 "-" m2 "-" m3 "-" m4 "-" m5 "}"
                  ,this._ptr := this.get_pointer(this._str) )
            : RegExMatch(guid, this._rgx_hex)
                ? (this._ptr := guid+0
                  ,this._str := this.get_string(this._ptr) )
            : this.error_log(A_ThisFunc, "Error creating GUID"
                            ,"GUID String `nPointer to GUID" ,{guid:guid})
        }
        
        ; Return        GUID string if success or a blank string if fail
        get_string(ptr)
        {
            strP := ""
            ,err := DllCall("ole32\StringFromCLSID"
                           ,GDIP.Ptr     ,ptr+0
                           ,GDIP.PtrA    ,strP )
            ,(err)
                ? this.error_log(A_ThisFunc, "Error setting GUID string from provided pointer."
                    , "Pointer to GUID", {ptr:ptr, err:err, stringPointer:strP})
                : ""
            Return (err) ? "" : StrGet(strP, , "UTF-16")
        }
        
        ; Description   Creates a GUID using a GUID string
        ; Return        Pointer to GUID if success or a blank string if fail
        get_pointer(str)
        {
            VarSetCapacity(_ptr, 16)
            ,err := DllCall("ole32\CLSIDFromString"
                        ,"WStr"     , str
                        ,GDIP.Ptr   , &_ptr)
            ,(err)
                ? this.error_log(A_ThisFunc, "Error setting GUID from provided string."
                    , "GUID String", {str:str, err:err})
                : ""
            Return (err) ? "" : &_ptr
        }
        
        new_guid()
        {
             this._str := ComObjCreate("Scriptlet.TypeLib").GUID
            ,this._ptr := this.get_pointer(this._str)
            
        }
        
        string
        {
            get {
                Return this._str
            }
        }
        
        str
        {
            get {
                Return this._str
            }
        }
        
        pointer
        {
            get {
                Return this._ptr+0
            }
        }
        
        ptr
        {
            get {
                Return this._ptr+0
            }
        }
    }
    
    
    

    
    
    
    
    
    ; gdiplusmetaheader.h
    
    ; Placeable WMFs
    
    ; Placeable Metafiles were created as a non-standard way of specifying how 
    ; a metafile is mapped and scaled on an output device.
    ; Placeable metafiles are quite wide-spread, but not directly supported by
    ; the Windows API. To playback a placeable metafile using the Windows API,
    ; you will first need to strip the placeable metafile header from the file.
    ; This is typically performed by copying the metafile to a temporary file
    ; starting at file offset 22 (0x16). The contents of the temporary file may
    ; then be used as input to the Windows GetMetaFile(), PlayMetaFile(),
    ; CopyMetaFile(), etc. GDI functions.
    
    ; Each placeable metafile begins with a 22-byte header,
    ;  followed by a standard metafile:
    
    ;~ Class ENHMETAHEADER3
    ;~ {
        ;~ iType          := 4    ; Record type EMR_HEADER
        ;~ nSize          := 4    ; Record size in bytes.  This may be greater than the sizeof(ENHMETAHEADER).
        ;~ rclBounds      := 16   ; Inclusive-inclusive bounds in device units
        ;~ rclFrame       := 16   ; Inclusive-inclusive Picture Frame .01mm unit
        ;~ dSignature     := 4    ; Signature.  Must be ENHMETA_SIGNATURE.
        ;~ nVersion       := 4    ; Version number
        ;~ nBytes         := 4    ; Size of the metafile in bytes
        ;~ nRecords       := 4    ; Number of records in the metafile
        ;~ nHandles       := 2    ; Number of handles in the handle table Handle index zero is reserved.
        ;~ sReserved      := 2    ; Reserved.  Must be zero.
        ;~ nDescription   := 4    ; Number of chars in the unicode desc string This is 0 if there is no description string
        ;~ offDescription := 4    ; Offset to the metafile description record. This is 0 if there is no description string
        ;~ nPalEntries    := 4    ; Number of entries in the metafile palette.
        ;~ szlDevice      := 8    ; Size of the reference device in pels
        ;~ szlMillimeters := 8    ; Size of the reference device in millimeters
    ;~ }
    
    ;~ Class PWMFRect16
    ;~ {
        ;~ Static Left   := 2
        ;~ Static Top    := 2
        ;~ Static Right  := 2
        ;~ Static Bottom := 2
    ;~ }
    
    ;~ Class WmfPlaceableFileHeader
    ;~ {
        ;~ UINT32          Key         := 4   ; GDIP_WMF_PLACEABLEKEY
        ;~ INT16           Hmf         := 2   ; Metafile HANDLE number (always 0)
        ;~ PWMFRect16      BoundingBox := 8   ; Coordinates in metafile units
        ;~ INT16           Inch        := 2   ; Number of metafile units per inch
        ;~ UINT32          Reserved    := 4   ; Reserved (always 0)
        ;~ INT16           Checksum    := 2   ; Checksum value for previous 10 WORDs
    ;~ } 
    
    ; Key contains a special identification value that indicates the presence of a placeable metafile header.
    ; It is always 0x9AC6CDD7.
    ; Handle is used to stored the handle of the metafile in memory. When written to disk, this field is not used
    ; and will always contains the value 0.
    
    ; Left, Top, Right, and Bottom contain the coordinates of the upper-left and lower-right corners of the image
    ; on the output device. These are measured in twips.
    
    ; A twip (meaning "twentieth of a point") is the logical unit of measurement used in Windows Metafiles.
    ; A twip is equal to 1/1440 of an inch. Thus 720 twips equal 1/2 inch, while 32,768 twips is 22.75 inches.
    
    ; Inch contains the number of twips per inch used to represent the image. Normally, there are 1440 twips per inch;
    ; however, this number may be changed to scale the image. A value of 720 indicates that the image is double its normal
    ; size, or scaled to a factor of 2:1. A value of 360 indicates a scale of 4:1, while a value of 2880 indicates that 
    ; the image is scaled down in size by a factor of two. A value of 1440 indicates a 1:1 scale ratio.
    
    ; Reserved is unused and always set to 0.
    
    ; Checksum contains a checksum value for the previous 10 WORDs in the header. This value can be used in an attempt
    ; to detect if the metafile has become corrupted. The checksum is calculated by XORing each WORD value to an initial
    ; value of 0.
    
    ; If the metafile was recorded with a reference Hdc that was a display.
        
    class MetafileHeader
    {
         ;~ _type              := "MetafileHeader"
        ;~ ,Type               := ""                     ; MetafileType
        ;~ ,Size               := ""                     ; UINT               ; Size of the metafile (in bytes)
        ;~ ,Version            := ""                     ; UINT       ; EMF+, EMF, or WMF version
        ;~ ,EmfPlusFlags       := ""                     ; UINT 
        ;~ ,DpiX               := ""                     ; REAL 
        ;~ ,DpiY               := ""                     ; REAL 
        ;~ ,X                  := ""                     ; INT         ; Bounds in device units
        ;~ ,Y                  := ""                     ; INT  
        ;~ ,Width              := ""                     ; INT  
        ;~ ,Height             := ""                     ; INT  
        ;~ ,union              := {METAHEADER     : 0
                               ;~ ,ENHMETAHEADER3 : 0}
        ;~ ,EmfPlusHeaderSize  :=                        ; INT size of the EMF+ header in file
        ;~ ,LogicalDpiX        :=                        ; INT Logical Dpi of reference Hdc
        ;~ ,LogicalDpiY        :=                        ; INT usually valid only for EMF+
        
        ;~ MetafileType GetType() const { return Type; }
        
        ;~ UINT GetMetafileSize() const { return Size; }
        
        ;~ ; If IsEmfPlus, this is the EMF+ version; else it is the WMF or EMF ver
        
        ;~ UINT GetVersion() const { return Version; }
        
        ;~ ; Get the EMF+ flags associated with the metafile
        
        ;~ UINT GetEmfPlusFlags() const { return EmfPlusFlags; }
        
        ;~ REAL GetDpiX() const { return DpiX; }
        
        ;~ REAL GetDpiY() const { return DpiY; }
        
        ;~ VOID GetBounds (OUT Rect *rect) const
        ;~ {
            ;~ rect->X = X;
            ;~ rect->Y = Y;
            ;~ rect->Width = Width;
            ;~ rect->Height = Height;
        ;~ }
        
        ;~ ; Is it any type of WMF (standard or Placeable Metafile)?
        
        ;~ BOOL IsWmf() const
        ;~ {
           ;~ return ((Type == MetafileTypeWmf) || (Type == MetafileTypeWmfPlaceable));
        ;~ }
        
        ;~ ; Is this an Placeable Metafile?
        
        ;~ BOOL IsWmfPlaceable() const { return (Type == MetafileTypeWmfPlaceable); }
        
        ;~ ; Is this an EMF (not an EMF+)?
        
        ;~ BOOL IsEmf() const { return (Type == MetafileTypeEmf); }
        
        ;~ ; Is this an EMF or EMF+ file?
        
        ;~ BOOL IsEmfOrEmfPlus() const { return (Type >= MetafileTypeEmf); }
        
        ;~ ; Is this an EMF+ file?
        
        ;~ BOOL IsEmfPlus() const { return (Type >= MetafileTypeEmfPlusOnly); }
        
        ;~ ; Is this an EMF+ dual (has dual, down-level records) file?
        
        ;~ BOOL IsEmfPlusDual() const { return (Type == MetafileTypeEmfPlusDual); }
        
        ;~ ; Is this an EMF+ only (no dual records) file?
        
        ;~ BOOL IsEmfPlusOnly() const { return (Type == MetafileTypeEmfPlusOnly); }
        
        ;~ ; If it's an EMF+ file, was it recorded against a display Hdc?
        
        ;~ BOOL IsDisplay() const
        ;~ {
            ;~ return (IsEmfPlus() &&
                    ;~ ((EmfPlusFlags & GDIP_EMFPLUSFLAGS_DISPLAY) != 0));
        ;~ }
        
        ;~ ; Get the WMF header of the metafile (if it is a WMF)
        
        ;~ const METAHEADER * GetWmfHeader() const
        ;~ {
            ;~ if (IsWmf())
            ;~ {
                ;~ return &WmfHeader;
            ;~ }
            ;~ return NULL;
        ;~ }
        
        ;~ ; Get the EMF header of the metafile (if it is an EMF)
        
        ;~ const ENHMETAHEADER3 * GetEmfHeader() const
        ;~ {
            ;~ if (IsEmfOrEmfPlus())
            ;~ {
                ;~ return &EmfHeader;
            ;~ }
            ;~ return NULL;
        ;~ }
    }
    
    
    
    ; Imaging.h
    

    
    Class GUI Extends GDIP
    {
        hwnd    := {}
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
             this.title    := title
            ,this.width    := (width = "") ? A_ScreenWidth : width
            ,this.height   := (height = "") ? A_ScreenHeight : height
            ,this.OnTop    := OnTop
            ,this.TitleBar := TitleBar
            ,this.TaskBar  := TaskBar
            
            Gui, % title ":New", % "+E0x80000 "             ; Create a new layered window
                . (TitleBar ? "+" : "-") "Caption "         ; Remove title bar and thick window border/edge
                . (OnTop    ? "+" : "-") "AlwaysOnTop "     ; Force GUI to always be on top
                . (TaskBar  ? "+" : "-") "ToolWindow "      ; Removes the taskbar button
                . "+HWNDguiHwnd "                           ; Saves the handle of the GUI to guiHwnd
            
            this.hwnd.gui := guiHwnd
        }
        
        _update(title="Main")
        {
            ;~ DllCall("UpdateLayeredWindow"
                    ;~ , HWND          , this.hwnd.gui[title]      ; Handle to window
                    ;~ , HDC           , hdcDst                    ; Handle to DC destination
                    ;~ , this.Ptr      , *pptDst                   ; Set new screen position using Point struct
                    ;~ , this.Ptr      , *psize                    ; Set new screen size using Size struct
                    ;~ , HDC           , hdcSrc                    ; Handle to DC source
                    ;~ , this.Ptr      , *pptSrc                   ; Set layer locaiton using Point struct
                    ;~ , COLORREF      , crKey                     ; ColorRef struct
                    ;~ , this.Ptr      , *pblend                   ; Pointer to a BlendFunction struct
                    ;~ , DWORD         , dwFlags )                 ; Add: 0x1 - ULW_COLORKEY
                                                                ;~ ;      0x2 - ULW_ALPHA
                                                                ;~ ;      0x4 - ULW_OPAQUE
                                                                ;~ ;      0x8 - ULW_EX_NORESIZE
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
    
    ; #####################
    ; ## Errors Handling ##
    ; #####################
    
    ; The value or what was actually received
    ; call      = Function or method call that failed
    ; msg       = General error message
    ; expected  = What kind of data was expected
    ; data_obj  = Object containing all pertinent info. Need to import my object extractor into this. 
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
    ; ##  Misc Funcs  ##
    ; ##################
    is_int(num) {
        Return (Mod(num, 1) = 0) ? 1 : 0
    }
    
    is_num(num) {
        Return (0 * num = 0) ? 1 : 0
    }
    
    get_min(n1, n2) {
        Return (n1 < n2) ? n1 : n2
    }
    
    get_max(n1, n2) {
        Return (n1 > n2) ? n1 : n2
    }
    
    to_hex(num) {
        Return Format("{1:#x}", num)
    }
    
    ; Kudos to jNizM and Coco for their posts on GUIDs
    str_to_guid(guidStr, ByRef guidP)
    {
        VarSetCapacity(guidP, 16, 0)
        DllCall("ole32\CLSIDFromString"
            , "WStr"    , guidStr
            , this.PtrA , guidP)
        Return
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
    }
}


; Used for performance testing. Also, SKAN is a pretty awesome dude.
; qpx(1) starts it and qpx() stops timer and returns time
qpx(N=0) ; QueryPerformanceCounter() wrapper originally by SKAN  | Created: 06Dec2009
{        ; My version | Modified: 15Jan2020
    Local   
    Static F:="", A:="", Q:="", P:="", X:=""
    If (N && !P)
        Return DllCall("QueryPerformanceFrequency",Int64P,F) + (X:=A:=0)
             + DllCall("QueryPerformanceCounter",Int64P,P)
    DllCall("QueryPerformanceCounter",Int64P,Q), A:=A+Q-P, P:=Q, X:=X+1
    Return (N && X=N) ? (X:=X-1)<<64 : (N=0 && (R:=A/X/F)) ? (R + (A:=P:=X:=0)) : 1
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
        
        dt.ATOM         := 2   ,dt.INT_PTR          := p   ,dt.PSHORT                := p
        dt.BOOL         := 4   ,dt.LANGID           := 2   ,dt.PSIZE_T               := p
        dt.BOOLEAN      := 1   ,dt.LCID             := 4   ,dt.PSSIZE_T              := p
        dt.BYTE         := 1   ,dt.LCTYPE           := 4   ,dt.PSTR                  := p
        dt.CCHAR        := 1   ,dt.LGRPID           := 4   ,dt.PTBYTE                := p
        dt.CHAR         := 1   ,dt.LONG             := 4   ,dt.PTCHAR                := p
        dt.COLORREF     := 4   ,dt.LONG32           := 4   ,dt.PTSTR                 := p
        dt.DWORD        := 4   ,dt.LONG64           := 8   ,dt.PUCHAR                := p
        dt.DWORD32      := 4   ,dt.LONG_PTR         := p   ,dt.PUHALF_PTR            := p
        dt.DWORD64      := 8   ,dt.LONGLONG         := 8   ,dt.PUINT                 := p
        dt.DWORD_PTR    := p   ,dt.LPARAM           := p   ,dt.PUINT16               := p
        dt.DWORDLONG    := 8   ,dt.LPBOOL           := p   ,dt.PUINT32               := p
        dt.HACCEL       := p   ,dt.LPBYTE           := p   ,dt.PUINT64               := p
        dt.HALF_PTR     := h   ,dt.LPCOLORREF       := p   ,dt.PUINT8                := p
        dt.HANDLE       := p   ,dt.LPCSTR           := p   ,dt.PUINT_PTR             := p
        dt.HBITMAP      := p   ,dt.LPCTSTR          := p   ,dt.PULONG                := p
        dt.HBRUSH       := p   ,dt.LPCVOID          := 0   ,dt.PULONG32              := p
        dt.HCOLORSPACE  := p   ,dt.LPDWORD          := 4   ,dt.PULONG64              := p
        dt.HCONV        := p   ,dt.LPHANDLE         := p   ,dt.PULONG_PTR            := p
        dt.HCONVLIST    := p   ,dt.LPINT            := 4   ,dt.PULONGLONG            := p
        dt.HCURSOR      := p   ,dt.LPLONG           := 4   ,dt.PUSHORT               := p
        dt.HDC          := p   ,dt.LPVOID           := p   ,dt.PVOID                 := p
        dt.HDDEDATA     := p   ,dt.LPWORD           := 2   ,dt.PWCHAR                := p
        dt.HDESK        := p   ,dt.LRESULT          := p   ,dt.PWORD                 := p
        dt.HDROP        := p   ,dt.PBOOL            := p   ,dt.PWSTR                 := p
        dt.HDWP         := p   ,dt.PBOOLEAN         := p   ,dt.QWORD                 := 8
        dt.HENHMETAFILE := p   ,dt.PBYTE            := p   ,dt.REAL                  := 4
        dt.HFILE        := 4   ,dt.PCHAR            := p   ,dt.SC_HANDLE             := p
        dt.HFONT        := p   ,dt.PDWORD           := p   ,dt.SC_LOCK               := p
        dt.HGDIOBJ      := p   ,dt.PDWORD32         := p   ,dt.SERVICE_STATUS_HANDLE := p
        dt.HGLOBAL      := p   ,dt.PDWORD64         := p   ,dt.SIZE_T                := p
        dt.HHOOK        := p   ,dt.PDWORD_PTR       := p   ,dt.SSIZE_T               := p
        dt.HICON        := p   ,dt.PDWORDLONG       := p   ,dt.TBYTE                 := u
        dt.HINSTANCE    := p   ,dt.PFLOAT           := p   ,dt.TCHAR                 := u
        dt.HKEY         := p   ,dt.PHALF_PTR        := p   ,dt.UCHAR                 := 1
        dt.HKL          := p   ,dt.PHANDLE          := p   ,dt.UHALF_PTR             := h
        dt.HLOCAL       := p   ,dt.PHKEY            := p   ,dt.UINT                  := 4
        dt.HMENU        := p   ,dt.PINT             := p   ,dt.UINT16                := 2
        dt.HMETAFILE    := p   ,dt.PINT16           := p   ,dt.UINT32                := 4
        dt.HMODULE      := p   ,dt.PINT32           := p   ,dt.UINT64                := 8
        dt.HMONITOR     := p   ,dt.PINT64           := p   ,dt.UINT8                 := 1
        dt.HPALETTE     := p   ,dt.PINT8            := p   ,dt.UINT_PTR              := p
        dt.HPEN         := p   ,dt.PINT_PTR         := p   ,dt.ULONG                 := 4
        dt.HRESULT      := 4   ,dt.PLCID            := p   ,dt.ULONG32               := 4
        dt.HRGN         := p   ,dt.PLONG            := p   ,dt.ULONG64               := 8
        dt.HRSRC        := p   ,dt.PLONG32          := p   ,dt.ULONG_PTR             := p
        dt.HSZ          := p   ,dt.PLONG64          := p   ,dt.ULONGLONG             := 8
        dt.HWINSTA      := p   ,dt.PLONG_PTR        := p   ,dt.USHORT                := 2
        dt.HWND         := p   ,dt.PLONGLONG        := p   ,dt.USN                   := 8
        dt.INT16        := 2   ,dt.POINTER_32       := p   ,dt.VOID                  := 0
        dt.INT32        := 4   ,dt.POINTER_64       := p   ,dt.WCHAR                 := 2
        dt.INT64        := 8   ,dt.POINTER_SIGNED   := p   ,dt.WORD                  := 2
        dt.INT8         := 1   ,dt.POINTER_UNSIGNED := p   ,dt.WPARAM                := p                               
    }
    bytes := dt[type]
    If (bytes != "")
        Return bytes
    GDIP.error_log(A_ThisFunc, "No valid datatype found.", type, "See 'data_type_size' function for list of data types.")
    Return "err"
}


; Helpful links:
; https://pdfium.googlesource.com/pdfium/+/5110c4743751145c4ae1934cd1d83bc6c55bb43f/core/src/fxge/Microsoft%20SDK/include?autodive=0/
; https://doxygen.reactos.org/d5/def/gdiplustypes_8h_source.html



; ### IDEAS ###
; Add a "cup" class as a container to hold pens and brushes
;     Add a method to "empty" the cup of all brushes and pens
;     Add a method to list all stored brushes and pens





















    ;___________________________________________________________________________________________________________________|
    ; Call                                                                                                              |
    ; Description                                                                                                       |
    ; Params                                                                                                            |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    
    ;###################################################################################################################|
    ; Call                                                                                                              |
    ; Description                                                                                                       |
    ;                                                                                                                   |
    ; Param                                                                                                             |
    ;                                                                                                                   |
    ; Return                                                                                                            |
    ;___________________________________________________________________________________________________________________|
    





























































/* Current code
;   GdiplusImaging.h
;---------------------------------------------------------------------------
; Image file format identifiers
;---------------------------------------------------------------------------

DEFINE_GUID(ImageFormatUndefined, 0xb96b3ca9,0x0728,0x11d3,0x9d,0x7b,0x00,0x00,0xf8,0x1e,0xf3,0x2e);
DEFINE_GUID(ImageFormatMemoryBMP, 0xb96b3caa,0x0728,0x11d3,0x9d,0x7b,0x00,0x00,0xf8,0x1e,0xf3,0x2e);
DEFINE_GUID(ImageFormatBMP, 0xb96b3cab,0x0728,0x11d3,0x9d,0x7b,0x00,0x00,0xf8,0x1e,0xf3,0x2e);
DEFINE_GUID(ImageFormatEMF, 0xb96b3cac,0x0728,0x11d3,0x9d,0x7b,0x00,0x00,0xf8,0x1e,0xf3,0x2e);
DEFINE_GUID(ImageFormatWMF, 0xb96b3cad,0x0728,0x11d3,0x9d,0x7b,0x00,0x00,0xf8,0x1e,0xf3,0x2e);
DEFINE_GUID(ImageFormatJPEG, 0xb96b3cae,0x0728,0x11d3,0x9d,0x7b,0x00,0x00,0xf8,0x1e,0xf3,0x2e);
DEFINE_GUID(ImageFormatPNG, 0xb96b3caf,0x0728,0x11d3,0x9d,0x7b,0x00,0x00,0xf8,0x1e,0xf3,0x2e);
DEFINE_GUID(ImageFormatGIF, 0xb96b3cb0,0x0728,0x11d3,0x9d,0x7b,0x00,0x00,0xf8,0x1e,0xf3,0x2e);
DEFINE_GUID(ImageFormatTIFF, 0xb96b3cb1,0x0728,0x11d3,0x9d,0x7b,0x00,0x00,0xf8,0x1e,0xf3,0x2e);
DEFINE_GUID(ImageFormatEXIF, 0xb96b3cb2,0x0728,0x11d3,0x9d,0x7b,0x00,0x00,0xf8,0x1e,0xf3,0x2e);
DEFINE_GUID(ImageFormatIcon, 0xb96b3cb5,0x0728,0x11d3,0x9d,0x7b,0x00,0x00,0xf8,0x1e,0xf3,0x2e);

;---------------------------------------------------------------------------
; Predefined multi-frame dimension IDs
;---------------------------------------------------------------------------

DEFINE_GUID(FrameDimensionTime, 0x6aedbd6d,0x3fb5,0x418a,0x83,0xa6,0x7f,0x45,0x22,0x9d,0xc8,0x72);
DEFINE_GUID(FrameDimensionResolution, 0x84236f7b,0x3bd3,0x428f,0x8d,0xab,0x4e,0xa1,0x43,0x9c,0xa3,0x15);
DEFINE_GUID(FrameDimensionPage, 0x7462dc86,0x6180,0x4c7e,0x8e,0x3f,0xee,0x73,0x33,0xa7,0xa4,0x83);

;---------------------------------------------------------------------------
; Property sets
;---------------------------------------------------------------------------

DEFINE_GUID(FormatIDImageInformation, 0xe5836cbe,0x5eef,0x4f1d,0xac,0xde,0xae,0x4c,0x43,0xb6,0x08,0xce);
DEFINE_GUID(FormatIDJpegAppHeaders, 0x1c4afdcd,0x6177,0x43cf,0xab,0xc7,0x5f,0x51,0xaf,0x39,0xee,0x85);

;---------------------------------------------------------------------------
; Encoder parameter sets
;---------------------------------------------------------------------------

DEFINE_GUID(EncoderCompression, 0xe09d739d,0xccd4,0x44ee,0x8e,0xba,0x3f,0xbf,0x8b,0xe4,0xfc,0x58);
DEFINE_GUID(EncoderColorDepth, 0x66087055,0xad66,0x4c7c,0x9a,0x18,0x38,0xa2,0x31,0x0b,0x83,0x37);
DEFINE_GUID(EncoderScanMethod, 0x3a4e2661,0x3109,0x4e56,0x85,0x36,0x42,0xc1,0x56,0xe7,0xdc,0xfa);
DEFINE_GUID(EncoderVersion, 0x24d18c76,0x814a,0x41a4,0xbf,0x53,0x1c,0x21,0x9c,0xcc,0xf7,0x97);
DEFINE_GUID(EncoderRenderMethod, 0x6d42c53a,0x229a,0x4825,0x8b,0xb7,0x5c,0x99,0xe2,0xb9,0xa8,0xb8);
DEFINE_GUID(EncoderQuality, 0x1d5be4b5,0xfa4a,0x452d,0x9c,0xdd,0x5d,0xb3,0x51,0x05,0xe7,0xeb);
DEFINE_GUID(EncoderTransformation,0x8d0eb2d1,0xa58e,0x4ea8,0xaa,0x14,0x10,0x80,0x74,0xb7,0xb6,0xf9);
DEFINE_GUID(EncoderLuminanceTable,0xedb33bce,0x0266,0x4a77,0xb9,0x04,0x27,0x21,0x60,0x99,0xe7,0x17);
DEFINE_GUID(EncoderChrominanceTable,0xf2e455dc,0x09b3,0x4316,0x82,0x60,0x67,0x6a,0xda,0x32,0x48,0x1c);
DEFINE_GUID(EncoderSaveFlag,0x292266fc,0xac40,0x47bf,0x8c, 0xfc, 0xa8, 0x5b, 0x89, 0xa6, 0x55, 0xde);

#if (GDIPVER >= 0x0110)
DEFINE_GUID(EncoderColorSpace,0xae7a62a0,0xee2c,0x49d8,0x9d,0x7,0x1b,0xa8,0xa9,0x27,0x59,0x6e);
DEFINE_GUID(EncoderImageItems,0x63875e13,0x1f1d,0x45ab,0x91, 0x95, 0xa2, 0x9b, 0x60, 0x66, 0xa6, 0x50);
DEFINE_GUID(EncoderSaveAsCMYK,0xa219bbc9, 0xa9d, 0x4005, 0xa3, 0xee, 0x3a, 0x42, 0x1b, 0x8b, 0xb0, 0x6c);
#endif ;(GDIPVER >= 0x0110)

DEFINE_GUID(CodecIImageBytes,0x025d1823,0x6c7d,0x447b,0xbb, 0xdb, 0xa3, 0xcb, 0xc3, 0xdf, 0xa2, 0xfc);

MIDL_INTERFACE("025D1823-6C7D-447B-BBDB-A3CBC3DFA2FC")
IImageBytes : public IUnknown
{
public:
    ; Return total number of bytes in the IStream

    STDMETHOD(CountBytes)(
        OUT UINT *pcb
        ) = 0;
    
    ; Locks "cb" bytes, starting from "ulOffset" in the stream, and returns the
    ; pointer to the beginning of the locked memory chunk in "ppvBytes"

    STDMETHOD(LockBytes)(
        IN UINT cb,
        IN ULONG ulOffset,
        OUT const VOID ** ppvBytes
        ) = 0;

    ; Unlocks "cb" bytes, pointed by "pvBytes", starting from "ulOffset" in the
    ; stream

    STDMETHOD(UnlockBytes)(
        IN const VOID *pvBytes,
        IN UINT cb,
        IN ULONG ulOffset
        ) = 0;
};

;--------------------------------------------------------------------------
; ImageCodecInfo structure
;--------------------------------------------------------------------------
Class ImageCodecInfo
{
     Clsid             := ""   ; CLSID
    ,FormatID          := ""   ; GUID 
    ,CodecName         := ""   ; const WCHAR* 
    ,DllName           := ""   ; const WCHAR* 
    ,FormatDescription := ""   ; const WCHAR* 
    ,FilenameExtension := ""   ; const WCHAR* 
    ,MimeType          := ""   ; const WCHAR* 
    ,Flags             := ""   ; DWORD
    ,Version           := ""   ; DWORD
    ,SigCount          := ""   ; DWORD
    ,SigSize           := ""   ; DWORD
    ,SigPattern        := ""   ; BYTE* const
    ,SigMask           := ""   ; BYTE* const
}

;---------------------------------------------------------------------------
; Information about image pixel data
;---------------------------------------------------------------------------
Class BitmapData
{
    Width       := ""   ; UINT        
    Height      := ""   ; UINT        
    Stride      := ""   ; INT         
    PixelFormat := ""   ; PixelFormat 
    Scan0       := ""   ; VOID*       
    Reserved    := ""   ; UINT_PTR    
}

;---------------------------------------------------------------------------
; Encoder Parameter structure
;---------------------------------------------------------------------------
class EncoderParameter
{
    Guid           ; GUID     ; GUID of the parameter
    NumberOfValues ; ULONG    ; Number of the parameter values
    Type           ; ULONG    ; Value type, like ValueTypeLONG  etc.
    Value          ; VOID*    ; A pointer to the parameter values
}

;---------------------------------------------------------------------------
; Encoder Parameters structure
;---------------------------------------------------------------------------
class EncoderParameters
{
public:
    UINT Count;                      ; Number of parameters in this structure
    EncoderParameter Parameter[1];   ; Parameter values
}

enum ItemDataPosition
{
    ItemDataPositionAfterHeader    = 0x0,
    ItemDataPositionAfterPalette   = 0x1,
    ItemDataPositionAfterBits      = 0x2,
}

;---------------------------------------------------------------------------
; External Data Item
;---------------------------------------------------------------------------
class ImageItemData
{
public:
    UINT  Size;           ; size of the structure 
    UINT  Position;       ; flags describing how the data is to be used.
    VOID *Desc;           ; description on how the data is to be saved.
                          ; it is different for every codec type.
    UINT  DescSize;       ; size memory pointed by Desc
    VOID *Data;           ; pointer to the data that is to be saved in the
                          ; file, could be anything saved directly.
    UINT  DataSize;       ; size memory pointed by Data
    UINT  Cookie;         ; opaque for the apps data member used during
                          ; enumeration of image data items.
};
#endif ;(GDIPVER >= 0x0110)

;---------------------------------------------------------------------------
; Property Item
;---------------------------------------------------------------------------
class PropertyItem
{
public:
    PROPID  id;                 ; ID of this property
    ULONG   length;             ; Length of the property value, in bytes
    WORD    type;               ; Type of the value, as one of TAG_TYPE_XXX
                                ; defined above
    VOID*   value;              ; property value
};



















/* Effect and subclasses WIP
; Effect Class - Current WIP

#SingleInstance Force
#Warn
test()
ExitApp

test()
{
    myguid := new gdip.guid()
    Return
}

*Escape::ExitApp

;   Gdiplus effect objects.

;-----------------------------------------------------------------------------
; GDI+ effect GUIDs
;-----------------------------------------------------------------------------
Class Effect
{
    ;~ GDIP.Blur.BlurEffectGuid                                     := new GDIP.GUID("{633C80A4-1843-482b-9EF2-BE2834C5FDD4}")
    ;~ GDIP.BrightnessContrast.BrightnessContrastEffectGuid         := new GDIP.GUID("{D3A1DBE1-8EC4-4C17-9F4C-EA97AD1C343D}")
    ;~ GDIP.ColorBalance.ColorBalanceEffectGuid                     := new GDIP.GUID("{537E597D-251E-48DA-9664-29CA496B70F8}")
    ;~ GDIP.ColorCurve.ColorCurveEffectGuid                         := new GDIP.GUID("{DD6A0022-58E4-4A67-9D9B-D48EB881A53D}")
    ;~ GDIP.ColorLookupTable.ColorLookupTableEffectGuid             := new GDIP.GUID("{A7CE72A9-0F7F-40D7-B3CC-D0C02D5C3212}")
    ;~ GDIP.ColorMatrix.ColorMatrixEffectGuid                       := new GDIP.GUID("{718F2615-7933-40E3-A511-5F68FE14DD74}")
    ;~ GDIP.HueSaturationLightness.HueSaturationLightnessEffectGuid := new GDIP.GUID("{8B2DD6C3-EB07-4D87-A5F0-7108E26A9C5F}")
    ;~ GDIP.Levels.LevelsEffectGuid                                 := new GDIP.GUID("{99C354EC-2A31-4F3A-8C34-17A803B33A25}")
    ;~ GDIP.RedEyeCorrection.RedEyeCorrectionEffectGuid             := new GDIP.GUID("{74D29D05-69A4-4266-9549-3CC52836B632}")
    ;~ GDIP.Sharpen.SharpenEffectGuid                               := new GDIP.GUID("{63CBF3EE-C526-402C-8F71-62C540BF5142}")
    ;~ GDIP.Tint.TintEffectGuid                                     := new GDIP.GUID("{1077AF00-2848-4441-9489-44AD4C2D7A2C}")
    _generate_guids()
    {
        GDIP.Blur.BlurEffectGuid       := new GDIP.GUID("{633C80A4-1843-482b-9EF2-BE2834C5FDD4}")
        GDIP.BrightnessContrast        := new GDIP.GUID("{D3A1DBE1-8EC4-4C17-9F4C-EA97AD1C343D}")
        GDIP.ColorBalance              := new GDIP.GUID("{537E597D-251E-48DA-9664-29CA496B70F8}")
        GDIP.ColorCurve                := new GDIP.GUID("{DD6A0022-58E4-4A67-9D9B-D48EB881A53D}")
        GDIP.ColorLookupTable          := new GDIP.GUID("{A7CE72A9-0F7F-40D7-B3CC-D0C02D5C3212}")
        GDIP.ColorMatrix               := new GDIP.GUID("{718F2615-7933-40E3-A511-5F68FE14DD74}")
        GDIP.HueSaturationLightness    := new GDIP.GUID("{8B2DD6C3-EB07-4D87-A5F0-7108E26A9C5F}")
        GDIP.Levels                    := new GDIP.GUID("{99C354EC-2A31-4F3A-8C34-17A803B33A25}")
        GDIP.RedEyeCorrection          := new GDIP.GUID("{74D29D05-69A4-4266-9549-3CC52836B632}")
        GDIP.Sharpen.SharpenEffectGuid := new GDIP.GUID("{63CBF3EE-C526-402C-8F71-62C540BF5142}")
        GDIP.Tint.TintEffectGuid       := new GDIP.GUID("{1077AF00-2848-4441-9489-44AD4C2D7A2C}")
    }
    
    ; ## CONSTRUCTOR ##
    ; effect()
    __New()
    {
        ; ?
        Return
    }
    
    ; ## METHODS ##
    SetParameters(const void *params, const UINT size)
    {
        return GdipSetEffectParameters(nativeEffect, params, size);
    }

    GetParameters(UINT *size, void *params)
    {
        return GdipGetEffectParameters(nativeEffect, size, params);
    }

    ; protected data members.
    
    CGpEffect   *nativeEffect;
    INT         auxDataSize;
    VOID        *auxData;
    BOOL        useAuxData;
    
public:

    Effect()
    {
        auxDataSize  = 0;
        auxData      = NULL;
        nativeEffect = NULL;
        useAuxData   = FALSE;
    }
    
    ; virtual ~Effect()
    __Delete()
    {
        DllExports::GdipFree(auxData)   ; pvData is allocated by ApplyEffect. Return the pointer so that it can be freed by the appropriate memory manager.
        GdipDeleteEffect(nativeEffect)  ; Release the native Effect.
    }
    
    UseAuxData(const BOOL useAuxDataFlag)
    {
        useAuxData = useAuxDataFlag;
    }

    GetParameterSize(UINT *size)
    {
        return GdipGetEffectParameterSize(nativeEffect, size);
    }
}



; Blur class
; Radius        The radius of the blur. Must be 0-255. Greater radius = more blur.
; expandEdge    If true, expands bitmap by an emount equal to the blur radius to accommodate soft edges.
Class Blur Extends Effect
{
    _type      := "Blur"
    radius     := 0
    expandEdge := 0
    ;~ struct BlurParams
    ;~ {
        ;~ float radius;
        ;~ BOOL expandEdge;
    ;~ }

    
    ; ## CONSTRUCTOR ##
    __New(radius, expandEdge)
    { 
        this.SetCapacity("_struct", 8)
        this._ptr := this.GetAddress("_struct")
        (radius <= 255 && radius >= 0) && (expandEdge = 0 || expandEdge = 1)
            ? (this._radius := radius, this._expandEdge := expandEdge)
            : this.error_log(A_ThisFunc, "", "", {radius:radius, expandEdge:expandEdge})
        GdipCreateEffect(BlurEffectGuid, &nativeEffect)
    }
    
    ; type      Pass expected structure type
    ; Return    Pointer to struct
    Struct()
    {
         NumPut(, this._ptr+0, 0, "Float")
        ,NumPut(, this._ptr+0, 4, "Bool" )
        Return structP+0
    }
    
    ; ## METHODS ##
    Status SetParameters(const BlurParams *parameters)
    {
        UINT size = sizeof(BlurParams);
        return Effect::SetParameters(parameters, size);
    }

    Status GetParameters(UINT *size, BlurParams *parameters)
    {
        return Effect::GetParameters(size, (VOID*)parameters);
    }
}

; Sharpen

Class Sharpen Extends Effect
{
    ;~ struct SharpenParams
    ;~ {
        ;~ float radius;
        ;~ float amount;
    ;~ }
public:
    
    Sharpen()
    { 
        GdipCreateEffect(SharpenEffectGuid, &nativeEffect);
    }

    Status SetParameters(const SharpenParams *parameters)
    {
        UINT size = sizeof(SharpenParams);
        return Effect::SetParameters(parameters, size);
    }

    Status GetParameters(UINT *size, SharpenParams *parameters)
    {
        return Effect::GetParameters(size, (VOID*)parameters);
    }
}

; RedEye Correction

Class RedEyeCorrection Extends Effect
{
    ;~ struct RedEyeCorrectionParams
    ;~ {
        ;~ UINT numberOfAreas;
        ;~ RECT *areas;
    ;~ }

public:
    
    ; constructors cannot return an error code.
    
    RedEyeCorrection()
    { 
        GdipCreateEffect(RedEyeCorrectionEffectGuid, &nativeEffect);
    }
    
    Status SetParameters(const RedEyeCorrectionParams *parameters)
    {
        Status status = InvalidParameter;

        if (parameters)
        {
            RedEyeCorrectionParams *inputParam =
                (RedEyeCorrectionParams*)parameters;

            UINT size = sizeof(RedEyeCorrectionParams) +
                inputParam->numberOfAreas * sizeof(RECT);

            status = Effect::SetParameters(parameters, size);
        }

        return status;
    }    
    
    Status GetParameters(UINT *size, RedEyeCorrectionParams *parameters)
    {
        return Effect::GetParameters(size,(VOID*)parameters);
    }
}

; Brightness/Contrast
Class BrightnessContrast Extends Effect
{
    ;~ struct BrightnessContrastParams
    ;~ {
        ;~ INT brightnessLevel;
        ;~ INT contrastLevel;
    ;~ }
public:
    BrightnessContrast()
    {
        GdipCreateEffect(BrightnessContrastEffectGuid, &nativeEffect);
    }

    Status SetParameters(const BrightnessContrastParams *parameters)
    {
        UINT size = sizeof(BrightnessContrastParams);
        return Effect::SetParameters((VOID*)parameters, size);
    }
    
    Status GetParameters(UINT *size, BrightnessContrastParams *parameters)
    {
        return Effect::GetParameters(size, (VOID*)parameters);
    }
}

; Hue/Saturation/Lightness

Class HueSaturationLightness Extends Effect
{
    ;~ struct HueSaturationLightnessParams
    ;~ {
        ;~ INT hueLevel;
        ;~ INT saturationLevel;
        ;~ INT lightnessLevel;
    ;~ }
public:
    HueSaturationLightness()
    {
        GdipCreateEffect(HueSaturationLightnessEffectGuid, &nativeEffect);
    }

    Status SetParameters(const HueSaturationLightnessParams *parameters)
    {
        UINT size = sizeof(HueSaturationLightnessParams);
        return Effect::SetParameters((VOID*)parameters, size);
    }

    Status GetParameters(UINT *size, HueSaturationLightnessParams *parameters)
    {
        return Effect::GetParameters(size, (VOID*)parameters);
    }
}

; Highlight/Midtone/Shadow curves

Class Levels Extends Effect
{
    ;~ struct LevelsParams
    ;~ {
        ;~ INT highlight;
        ;~ INT midtone;
        ;~ INT shadow;
    ;~ }
public:
    Levels()
    {
        GdipCreateEffect(LevelsEffectGuid, &nativeEffect);
    }
    
    Status SetParameters(const LevelsParams *parameters)
    {
        UINT size = sizeof(LevelsParams);
        return Effect::SetParameters((VOID*)parameters, size);
    }

    Status GetParameters(UINT *size, LevelsParams *parameters)
    {
        return Effect::GetParameters(size, (VOID*)parameters);
    }
}

; Tint

Class Tint Extends Effect
{
    ;~ struct TintParams
    ;~ {
        ;~ INT hue;
        ;~ INT amount;
    ;~ }

public:
    Tint()
    {
        GdipCreateEffect(TintEffectGuid, &nativeEffect);
    }
    
    Status SetParameters(const TintParams *parameters)
    {
        UINT size = sizeof(TintParams);
        return Effect::SetParameters((VOID*)parameters, size);
    }

    Status GetParameters(UINT *size, TintParams *parameters)
    {
        return Effect::GetParameters(size, (VOID*)parameters);
    }
}

; ColorBalance

Class ColorBalance Extends Effect
{
    ;~ struct ColorBalanceParams
    ;~ {
        ;~ INT cyanRed;
        ;~ INT magentaGreen;
        ;~ INT yellowBlue;
    ;~ }
public:
    ColorBalance()
    {
        GdipCreateEffect(ColorBalanceEffectGuid, &nativeEffect);
    }
    
    Status SetParameters(const ColorBalanceParams *parameters)
    {
        UINT size = sizeof(ColorBalanceParams);
        return Effect::SetParameters((VOID*)parameters, size);
    }

    Status GetParameters(UINT *size, ColorBalanceParams *parameters)
    {
        return Effect::GetParameters(size, (VOID*)parameters);
    }
}

; ColorMatrix

Class ColorMatrixEffect Extends Effect
{
public:
    
    ; constructors cannot return an error code.
    
    ColorMatrixEffect()
    { 
        GdipCreateEffect(ColorMatrixEffectGuid, &nativeEffect);
    }
    
    Status SetParameters(const ColorMatrix *matrix)
    {
        UINT size = sizeof(ColorMatrix);
        return Effect::SetParameters(matrix, size);
    }

    Status GetParameters(UINT *size, ColorMatrix *matrix)
    {
        return Effect::GetParameters(size, (VOID*)matrix);
    }
}


; ColorLUT

Class ColorLUT Extends Effect
{
    ;~ struct ColorLUTParams
    ;~ {
        ;~ ; look up tables for each color channel.
        
        ;~ ColorChannelLUT lutB;
        ;~ ColorChannelLUT lutG;
        ;~ ColorChannelLUT lutR;
        ;~ ColorChannelLUT lutA;
    ;~ }
    public:
    
    ; constructors cannot return an error code.
    
    ColorLUT()
    { 
        GdipCreateEffect(ColorLUTEffectGuid, &nativeEffect);
    }

    Status SetParameters(const ColorLUTParams *lut)
    {
        UINT size = sizeof(ColorLUTParams);
        return Effect::SetParameters(lut, size);
    }

    Status GetParameters(UINT *size, ColorLUTParams *lut)
    {
        return Effect::GetParameters(size, (VOID*)lut);
    }
}

; Color Curve

Class ColorCurve Extends Effect
{
    ;~ struct ColorCurveParams
    ;~ {
        ;~ CurveAdjustments adjustment;
        ;~ CurveChannel channel;
        ;~ INT adjustValue;
    ;~ }
public:
    ColorCurve()
    {
        GdipCreateEffect(ColorCurveEffectGuid, &nativeEffect);
    }

    Status SetParameters(const ColorCurveParams *parameters)
    {
        UINT size = sizeof(ColorCurveParams);
        return Effect::SetParameters((VOID*)parameters, size);
    }

    Status GetParameters(UINT *size, ColorCurveParams *parameters)
    {
        return Effect::GetParameters(size, (VOID*)parameters);
    }
}

























/*
;   GdiplusGraphics.h

class Graphics : public GdiplusBase
{


    ;~Graphics()
    __Delete()
    {
        DllCall("GdipDeleteGraphics", this.Ptr, this.nativeGraphics)
    }

    Flush(intention = FlushIntentionFlush)
    {
        DllCall("gdiplus\GdipFlush", this.Ptr, this.nativeGraphics, intention);
    }

    ;------------------------------------------------------------------------
    ; GDI Interop methods
    ;------------------------------------------------------------------------

    ; Locks the graphics until ReleaseDC is called

    GetHDC()
    {
        VarSetCapacity(hdc, A_PtrSize, 0)
        ,estat := DllCall("gdiplus\GdipGetDC"
                         ,this.Ptr   ,nativeGraphics
                         ,this.PtrA  ,hdc)
        ,(estat) ? (this.lastResult := estat) : estat
        Return (estat) ? 0 : hdc
    }

    ReleaseHDC(hdc)
    {
        estat := DllCall("gdiplus\GdipReleaseDC"
                        ,this.Ptr   ,nativeGraphics
                        ,this.Ptr   ,hdc)
        ,(estat) ? (this.lastResult := estat) : estat
    }

    ;------------------------------------------------------------------------
    ; Rendering modes
    ;------------------------------------------------------------------------

    SetRenderingOrigin(x, y)
    {
        estat := DllCall("gdiplus\GdipSetRenderingOrigin"
                        ,this.Ptr ,this.nativeGraphics
                        ,"Int"    ,x
                        ,"Int"    ,y)
        Return (estat) ? (this.lastResult := estat) : estat
    }

    GetRenderingOrigin(ByRef x, ByRef y)
    {
         VarSetCapacity(x, 4)
        ,VarSetCapacity(y, 4)
        ,estat := DllCall("gdiplus\GdipGetRenderingOrigin"
                        ,this.Ptr ,this.nativeGraphics
                        ,"Int"    ,&x
                        ,"Int"    ,&y)
        Return (estat) ? (this.lastResult := estat) : estat
    }
    
    ; Expects a number from the CompositingMode enum
    SetCompositingMode(compositingMode)
    {
        estat := DllCall("gdiplus\GdipSetCompositingMode"
                        ,this.Ptr   ,this.nativeGraphics
                        ,"UInt"      ,&compositingMode)
        Return (estat) ? (this.lastResult := estat) : estat
    }

    GetCompositingMode()
    {
        VarSetCapacity(mode, "Int")
        DllCall("gdiplus\GdipGetCompositingMode"
                ,this.Ptr   ,this.nativeGraphics
                ,"UInt"     ,&mode)
        return mode
    }

    Status SetCompositingQuality(IN CompositingQuality compositingQuality)
    {
        return SetStatus(DllCall("gdiplus\GdipSetCompositingQuality(
            nativeGraphics,
            compositingQuality));
    }

    CompositingQuality GetCompositingQuality() const
    {
        CompositingQuality quality;

        SetStatus(DllCall("gdiplus\GdipGetCompositingQuality(
            nativeGraphics,
            &quality));

        return quality;
    }

    Status SetTextRenderingHint(IN TextRenderingHint newMode)
    {
        return SetStatus(DllCall("gdiplus\GdipSetTextRenderingHint(nativeGraphics,
                                                          newMode));
    }

    TextRenderingHint GetTextRenderingHint() const
    {
        TextRenderingHint hint;

        SetStatus(DllCall("gdiplus\GdipGetTextRenderingHint(nativeGraphics,
                                                   &hint));

        return hint;
    }

    Status SetTextContrast(IN UINT contrast)
    {
        return SetStatus(DllCall("gdiplus\GdipSetTextContrast(nativeGraphics,
                                                          contrast));
    }

    UINT GetTextContrast() const
    {
        UINT contrast;

        SetStatus(DllCall("gdiplus\GdipGetTextContrast(nativeGraphics,
                                                    &contrast));

        return contrast;
    }

    InterpolationMode GetInterpolationMode() const
    {
        InterpolationMode mode = InterpolationModeInvalid;

        SetStatus(DllCall("gdiplus\GdipGetInterpolationMode(nativeGraphics,
                                                           &mode));

        return mode;
    }

    Status SetInterpolationMode(IN InterpolationMode interpolationMode)
    {
        return SetStatus(DllCall("gdiplus\GdipSetInterpolationMode(nativeGraphics,
                                                           interpolationMode));
    }

#if (GDIPVER >= 0x0110)
    Status SetAbort(GdiplusAbort *pIAbort)
    {
        return SetStatus(DllCall("gdiplus\GdipGraphicsSetAbort(
            nativeGraphics,
            pIAbort
        ));
    }
#endif ;(GDIPVER >= 0x0110)

    SmoothingMode GetSmoothingMode() const
    {
        SmoothingMode smoothingMode = SmoothingModeInvalid;

        SetStatus(DllCall("gdiplus\GdipGetSmoothingMode(nativeGraphics,
                                                   &smoothingMode));

        return smoothingMode;
    }

    Status SetSmoothingMode(IN SmoothingMode smoothingMode)
    {
        return SetStatus(DllCall("gdiplus\GdipSetSmoothingMode(nativeGraphics,
                                                          smoothingMode));
    }

    PixelOffsetMode GetPixelOffsetMode() const
    {
        PixelOffsetMode pixelOffsetMode = PixelOffsetModeInvalid;

        SetStatus(DllCall("gdiplus\GdipGetPixelOffsetMode(nativeGraphics,
                                                     &pixelOffsetMode));

        return pixelOffsetMode;
    }

    Status SetPixelOffsetMode(IN PixelOffsetMode pixelOffsetMode)
    {
        return SetStatus(DllCall("gdiplus\GdipSetPixelOffsetMode(nativeGraphics,
                                                            pixelOffsetMode));
    }

    ;------------------------------------------------------------------------
    ; Manipulate current world transform
    ;------------------------------------------------------------------------

    Status SetTransform(IN const Matrix* matrix)
    {
        return SetStatus(DllCall("gdiplus\GdipSetWorldTransform(nativeGraphics,
                                                        matrix->nativeMatrix));
    }
    Status ResetTransform()
    {
        return SetStatus(DllCall("gdiplus\GdipResetWorldTransform(nativeGraphics));
    }

    Status MultiplyTransform(IN const Matrix* matrix,
                             IN MatrixOrder order = MatrixOrderPrepend)
    {
        return SetStatus(DllCall("gdiplus\GdipMultiplyWorldTransform(nativeGraphics,
                                                                matrix->nativeMatrix,
                                                                order));
    }

    Status TranslateTransform(IN REAL dx,
                              IN REAL dy,
                              IN MatrixOrder order = MatrixOrderPrepend)
    {
        return SetStatus(DllCall("gdiplus\GdipTranslateWorldTransform(nativeGraphics,
                                                               dx, dy, order));
    }

    Status ScaleTransform(IN REAL sx,
                          IN REAL sy,
                          IN MatrixOrder order = MatrixOrderPrepend)
    {
        return SetStatus(DllCall("gdiplus\GdipScaleWorldTransform(nativeGraphics,
                                                             sx, sy, order));
    }

    Status RotateTransform(IN REAL angle,
                           IN MatrixOrder order = MatrixOrderPrepend)
    {
        return SetStatus(DllCall("gdiplus\GdipRotateWorldTransform(nativeGraphics,
                                                              angle, order));
    }

    Status GetTransform(OUT Matrix* matrix) const
    {
        return SetStatus(DllCall("gdiplus\GdipGetWorldTransform(nativeGraphics,
                                                           matrix->nativeMatrix));
    }

    Status SetPageUnit(IN Unit unit)
    {
        return SetStatus(DllCall("gdiplus\GdipSetPageUnit(nativeGraphics,
                                                     unit));
    }

    Status SetPageScale(IN REAL scale)
    {
        return SetStatus(DllCall("gdiplus\GdipSetPageScale(nativeGraphics,
                                                      scale));
    }

    Unit GetPageUnit() const
    {
        Unit unit;

        SetStatus(DllCall("gdiplus\GdipGetPageUnit(nativeGraphics, &unit));

        return unit;
    }

    REAL GetPageScale() const
    {
        REAL scale;

        SetStatus(DllCall("gdiplus\GdipGetPageScale(nativeGraphics, &scale));

        return scale;
    }

    REAL GetDpiX() const
    {
        REAL dpi;

        SetStatus(DllCall("gdiplus\GdipGetDpiX(nativeGraphics, &dpi));

        return dpi;
    }

    REAL GetDpiY() const
    {
        REAL dpi;

        SetStatus(DllCall("gdiplus\GdipGetDpiY(nativeGraphics, &dpi));

        return dpi;
    }

    Status TransformPoints(IN CoordinateSpace destSpace,
                           IN CoordinateSpace srcSpace,
                           IN OUT PointF* pts,
                           IN INT count) const
    {
        return SetStatus(DllCall("gdiplus\GdipTransformPoints(nativeGraphics,
                                                         destSpace,
                                                         srcSpace,
                                                         pts,
                                                         count));
    }

    Status TransformPoints(IN CoordinateSpace destSpace,
                           IN CoordinateSpace srcSpace,
                           IN OUT Point* pts,
                           IN INT count) const
    {

        return SetStatus(DllCall("gdiplus\GdipTransformPointsI(nativeGraphics,
                                                          destSpace,
                                                          srcSpace,
                                                          pts,
                                                          count));
    }

    ;------------------------------------------------------------------------
    ; GetNearestColor (for <= 8bpp surfaces).  Note: Alpha is ignored.
    ;------------------------------------------------------------------------
    
    Status GetNearestColor(IN OUT Color* color) const
    {
        if (color == NULL)
        {
            return SetStatus(InvalidParameter);
        }

        ARGB argb = color->GetValue();

        Status status = SetStatus(DllCall("gdiplus\GdipGetNearestColor(nativeGraphics, &argb));

        color->SetValue(argb);

        return status;
    }

    Status DrawLine(IN const Pen* pen,
                    IN REAL x1,
                    IN REAL y1,
                    IN REAL x2,
                    IN REAL y2)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawLine(nativeGraphics,
                                                  pen->nativePen, x1, y1, x2,
                                                  y2));
    }

    Status DrawLine(IN const Pen* pen,
                    IN const PointF& pt1,
                    IN const PointF& pt2)
    {
        return DrawLine(pen, pt1.X, pt1.Y, pt2.X, pt2.Y);
    }

    Status DrawLines(IN const Pen* pen,
                     IN const PointF* points,
                     IN INT count)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawLines(nativeGraphics,
                                                   pen->nativePen,
                                                   points, count));
    }

    Status DrawLine(IN const Pen* pen,
                    IN INT x1,
                    IN INT y1,
                    IN INT x2,
                    IN INT y2)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawLineI(nativeGraphics,
                                                   pen->nativePen,
                                                   x1,
                                                   y1,
                                                   x2,
                                                   y2));
    }

    Status DrawLine(IN const Pen* pen,
                    IN const Point& pt1,
                    IN const Point& pt2)
    {
        return DrawLine(pen,
                        pt1.X,
                        pt1.Y,
                        pt2.X,
                        pt2.Y);
    }

    Status DrawLines(IN const Pen* pen,
                     IN const Point* points,
                     IN INT count)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawLinesI(nativeGraphics,
                                                    pen->nativePen,
                                                    points,
                                                    count));
    }

    Status DrawArc(IN const Pen* pen,
                   IN REAL x,
                   IN REAL y,
                   IN REAL width,
                   IN REAL height,
                   IN REAL startAngle,
                   IN REAL sweepAngle)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawArc(nativeGraphics,
                                                 pen->nativePen,
                                                 x,
                                                 y,
                                                 width,
                                                 height,
                                                 startAngle,
                                                 sweepAngle));
    }

    Status DrawArc(IN const Pen* pen,
                   IN const RectF& rect,
                   IN REAL startAngle,
                   IN REAL sweepAngle)
    {
        return DrawArc(pen, rect.X, rect.Y, rect.Width, rect.Height,
                       startAngle, sweepAngle);
    }

    Status DrawArc(IN const Pen* pen,
                   IN INT x,
                   IN INT y,
                   IN INT width,
                   IN INT height,
                   IN REAL startAngle,
                   IN REAL sweepAngle)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawArcI(nativeGraphics,
                                                  pen->nativePen,
                                                  x,
                                                  y,
                                                  width,
                                                  height,
                                                  startAngle,
                                                  sweepAngle));
    }


    Status DrawArc(IN const Pen* pen,
                   IN const Rect& rect,
                   IN REAL startAngle,
                   IN REAL sweepAngle)
    {
        return DrawArc(pen,
                       rect.X,
                       rect.Y,
                       rect.Width,
                       rect.Height,
                       startAngle,
                       sweepAngle);
    }

    Status DrawBezier(IN const Pen* pen,
                      IN REAL x1,
                      IN REAL y1,
                      IN REAL x2,
                      IN REAL y2,
                      IN REAL x3,
                      IN REAL y3,
                      IN REAL x4,
                      IN REAL y4)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawBezier(nativeGraphics,
                                                    pen->nativePen, x1, y1,
                                                    x2, y2, x3, y3, x4, y4));
    }

    Status DrawBezier(IN const Pen* pen,
                      IN const PointF& pt1,
                      IN const PointF& pt2,
                      IN const PointF& pt3,
                      IN const PointF& pt4)
    {
        return DrawBezier(pen,
                          pt1.X,
                          pt1.Y,
                          pt2.X,
                          pt2.Y,
                          pt3.X,
                          pt3.Y,
                          pt4.X,
                          pt4.Y);
    }

    Status DrawBeziers(IN const Pen* pen,
                       IN const PointF* points,
                       IN INT count)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawBeziers(nativeGraphics,
                                                     pen->nativePen,
                                                     points,
                                                     count));
    }

    Status DrawBezier(IN const Pen* pen,
                      IN INT x1,
                      IN INT y1,
                      IN INT x2,
                      IN INT y2,
                      IN INT x3,
                      IN INT y3,
                      IN INT x4,
                      IN INT y4)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawBezierI(nativeGraphics,
                                                     pen->nativePen,
                                                     x1,
                                                     y1,
                                                     x2,
                                                     y2,
                                                     x3,
                                                     y3,
                                                     x4,
                                                     y4));
    }

    Status DrawBezier(IN const Pen* pen,
                      IN const Point& pt1,
                      IN const Point& pt2,
                      IN const Point& pt3,
                      IN const Point& pt4)
    {
        return DrawBezier(pen,
                          pt1.X,
                          pt1.Y,
                          pt2.X,
                          pt2.Y,
                          pt3.X,
                          pt3.Y,
                          pt4.X,
                          pt4.Y);
    }

    Status DrawBeziers(IN const Pen* pen,
                       IN const Point* points,
                       IN INT count)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawBeziersI(nativeGraphics,
                                                      pen->nativePen,
                                                      points,
                                                      count));
    }

    Status DrawRectangle(IN const Pen* pen,
                         IN const RectF& rect)
    {
        return DrawRectangle(pen, rect.X, rect.Y, rect.Width, rect.Height);
    }

    Status DrawRectangle(IN const Pen* pen,
                         IN REAL x,
                         IN REAL y,
                         IN REAL width,
                         IN REAL height)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawRectangle(nativeGraphics,
                                                       pen->nativePen, x, y,
                                                       width, height));
    }

    Status DrawRectangles(IN const Pen* pen,
                          IN const RectF* rects,
                          IN INT count)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawRectangles(nativeGraphics,
                                                        pen->nativePen,
                                                        rects, count));
    }

    Status DrawRectangle(IN const Pen* pen,
                         IN const Rect& rect)
    {
        return DrawRectangle(pen,
                             rect.X,
                             rect.Y,
                             rect.Width,
                             rect.Height);
    }

    Status DrawRectangle(IN const Pen* pen,
                         IN INT x,
                         IN INT y,
                         IN INT width,
                         IN INT height)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawRectangleI(nativeGraphics,
                                                        pen->nativePen,
                                                        x,
                                                        y,
                                                        width,
                                                        height));
    }

    Status DrawRectangles(IN const Pen* pen,
                          IN const Rect* rects,
                          IN INT count)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawRectanglesI(nativeGraphics,
                                                         pen->nativePen,
                                                         rects,
                                                         count));
    }

    Status DrawEllipse(IN const Pen* pen,
                       IN const RectF& rect)
    {
        return DrawEllipse(pen, rect.X, rect.Y, rect.Width, rect.Height);
    }

    Status DrawEllipse(IN const Pen* pen,
                       IN REAL x,
                       IN REAL y,
                       IN REAL width,
                       IN REAL height)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawEllipse(nativeGraphics,
                                                     pen->nativePen,
                                                     x,
                                                     y,
                                                     width,
                                                     height));
    }

    Status DrawEllipse(IN const Pen* pen,
                       IN const Rect& rect)
    {
        return DrawEllipse(pen,
                           rect.X,
                           rect.Y,
                           rect.Width,
                           rect.Height);
    }

    Status DrawEllipse(IN const Pen* pen,
                       IN INT x,
                       IN INT y,
                       IN INT width,
                       IN INT height)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawEllipseI(nativeGraphics,
                                                      pen->nativePen,
                                                      x,
                                                      y,
                                                      width,
                                                      height));
    }

    Status DrawPie(IN const Pen* pen,
                   IN const RectF& rect,
                   IN REAL startAngle,
                   IN REAL sweepAngle)
    {
        return DrawPie(pen,
                       rect.X,
                       rect.Y,
                       rect.Width,
                       rect.Height,
                       startAngle,
                       sweepAngle);
    }

    Status DrawPie(IN const Pen* pen,
                   IN REAL x,
                   IN REAL y,
                   IN REAL width,
                   IN REAL height,
                   IN REAL startAngle,
                   IN REAL sweepAngle)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawPie(nativeGraphics,
                                                 pen->nativePen,
                                                 x,
                                                 y,
                                                 width,
                                                 height,
                                                 startAngle,
                                                 sweepAngle));
    }

    Status DrawPie(IN const Pen* pen,
                   IN const Rect& rect,
                   IN REAL startAngle,
                   IN REAL sweepAngle)
    {
        return DrawPie(pen,
                       rect.X,
                       rect.Y,
                       rect.Width,
                       rect.Height,
                       startAngle,
                       sweepAngle);
    }

    Status DrawPie(IN const Pen* pen,
                   IN INT x,
                   IN INT y,
                   IN INT width,
                   IN INT height,
                   IN REAL startAngle,
                   IN REAL sweepAngle)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawPieI(nativeGraphics,
                                                  pen->nativePen,
                                                  x,
                                                  y,
                                                  width,
                                                  height,
                                                  startAngle,
                                                  sweepAngle));
    }

    Status DrawPolygon(IN const Pen* pen,
                       IN const PointF* points,
                       IN INT count)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawPolygon(nativeGraphics,
                                                     pen->nativePen,
                                                     points,
                                                     count));
    }

    Status DrawPolygon(IN const Pen* pen,
                       IN const Point* points,
                       IN INT count)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawPolygonI(nativeGraphics,
                                                      pen->nativePen,
                                                      points,
                                                      count));
    }

    Status DrawPath(IN const Pen* pen,
                    IN const GraphicsPath* path)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawPath(nativeGraphics,
                                                  pen ? pen->nativePen : NULL,
                                                  path ? path->nativePath : NULL));
    }

    Status DrawCurve(IN const Pen* pen,
                     IN const PointF* points,
                     IN INT count)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawCurve(nativeGraphics,
                                                   pen->nativePen, points,
                                                   count));
    }

    Status DrawCurve(IN const Pen* pen,
                     IN const PointF* points,
                     IN INT count,
                     IN REAL tension)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawCurve2(nativeGraphics,
                                                    pen->nativePen, points,
                                                    count, tension));
    }

    Status DrawCurve(IN const Pen* pen,
                     IN const PointF* points,
                     IN INT count,
                     IN INT offset,
                     IN INT numberOfSegments,
                     IN REAL tension = 0.5f)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawCurve3(nativeGraphics,
                                                    pen->nativePen, points,
                                                    count, offset,
                                                    numberOfSegments, tension));
    }

    Status DrawCurve(IN const Pen* pen,
                     IN const Point* points,
                     IN INT count)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawCurveI(nativeGraphics,
                                                    pen->nativePen,
                                                    points,
                                                    count));
    }

    Status DrawCurve(IN const Pen* pen,
                     IN const Point* points,
                     IN INT count,
                     IN REAL tension)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawCurve2I(nativeGraphics,
                                                     pen->nativePen,
                                                     points,
                                                     count,
                                                     tension));
    }

    Status DrawCurve(IN const Pen* pen,
                     IN const Point* points,
                     IN INT count,
                     IN INT offset,
                     IN INT numberOfSegments,
                     IN REAL tension = 0.5f)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawCurve3I(nativeGraphics,
                                                     pen->nativePen,
                                                     points,
                                                     count,
                                                     offset,
                                                     numberOfSegments,
                                                     tension));
    }

    Status DrawClosedCurve(IN const Pen* pen,
                           IN const PointF* points,
                           IN INT count)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawClosedCurve(nativeGraphics,
                                                         pen->nativePen,
                                                         points, count));
    }

    Status DrawClosedCurve(IN const Pen *pen,
                           IN const PointF* points,
                           IN INT count,
                           IN REAL tension)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawClosedCurve2(nativeGraphics,
                                                          pen->nativePen,
                                                          points, count,
                                                          tension));
    }

    Status DrawClosedCurve(IN const Pen* pen,
                           IN const Point* points,
                           IN INT count)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawClosedCurveI(nativeGraphics,
                                                          pen->nativePen,
                                                          points,
                                                          count));
    }

    Status DrawClosedCurve(IN const Pen *pen,
                           IN const Point* points,
                           IN INT count,
                           IN REAL tension)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawClosedCurve2I(nativeGraphics,
                                                           pen->nativePen,
                                                           points,
                                                           count,
                                                           tension));
    }

    Status Clear(IN const Color &color)
    {
        return SetStatus(DllCall("gdiplus\GdipGraphicsClear(
            nativeGraphics,
            color.GetValue()));
    }

    Status FillRectangle(IN const Brush* brush,
                         IN const RectF& rect)
    {
        return FillRectangle(brush, rect.X, rect.Y, rect.Width, rect.Height);
    }

    Status FillRectangle(IN const Brush* brush,
                         IN REAL x,
                         IN REAL y,
                         IN REAL width,
                         IN REAL height)
    {
        return SetStatus(DllCall("gdiplus\GdipFillRectangle(nativeGraphics,
                                                       brush->nativeBrush, x, y,
                                                       width, height));
    }

    Status FillRectangles(IN const Brush* brush,
                          IN const RectF* rects,
                          IN INT count)
    {
        return SetStatus(DllCall("gdiplus\GdipFillRectangles(nativeGraphics,
                                                        brush->nativeBrush,
                                                        rects, count));
    }

    Status FillRectangle(IN const Brush* brush,
                         IN const Rect& rect)
    {
        return FillRectangle(brush,
                             rect.X,
                             rect.Y,
                             rect.Width,
                             rect.Height);
    }

    Status FillRectangle(IN const Brush* brush,
                         IN INT x,
                         IN INT y,
                         IN INT width,
                         IN INT height)
    {
        return SetStatus(DllCall("gdiplus\GdipFillRectangleI(nativeGraphics,
                                                        brush->nativeBrush,
                                                        x,
                                                        y,
                                                        width,
                                                        height));
    }

    Status FillRectangles(IN const Brush* brush,
                          IN const Rect* rects,
                          IN INT count)
    {
        return SetStatus(DllCall("gdiplus\GdipFillRectanglesI(nativeGraphics,
                                                         brush->nativeBrush,
                                                         rects,
                                                         count));
    }

    Status FillPolygon(IN const Brush* brush,
                       IN const PointF* points,
                       IN INT count)
    {
        return FillPolygon(brush, points, count, FillModeAlternate);
    }

    Status FillPolygon(IN const Brush* brush,
                       IN const PointF* points,
                       IN INT count,
                       IN FillMode fillMode)
    {
        return SetStatus(DllCall("gdiplus\GdipFillPolygon(nativeGraphics,
                                                     brush->nativeBrush,
                                                     points, count, fillMode));
    }

    Status FillPolygon(IN const Brush* brush,
                       IN const Point* points,
                       IN INT count)
    {
        return FillPolygon(brush, points, count, FillModeAlternate);
    }

    Status FillPolygon(IN const Brush* brush,
                       IN const Point* points,
                       IN INT count,
                       IN FillMode fillMode)
    {
        return SetStatus(DllCall("gdiplus\GdipFillPolygonI(nativeGraphics,
                                                      brush->nativeBrush,
                                                      points, count,
                                                      fillMode));
    }

    Status FillEllipse(IN const Brush* brush,
                       IN const RectF& rect)
    {
        return FillEllipse(brush, rect.X, rect.Y, rect.Width, rect.Height);
    }

    Status FillEllipse(IN const Brush* brush,
                       IN REAL x,
                       IN REAL y,
                       IN REAL width,
                       IN REAL height)
    {
        return SetStatus(DllCall("gdiplus\GdipFillEllipse(nativeGraphics,
                                                     brush->nativeBrush, x, y,
                                                     width, height));
    }

    Status FillEllipse(IN const Brush* brush,
                       IN const Rect& rect)
    {
        return FillEllipse(brush, rect.X, rect.Y, rect.Width, rect.Height);
    }

    Status FillEllipse(IN const Brush* brush,
                       IN INT x,
                       IN INT y,
                       IN INT width,
                       IN INT height)
    {
        return SetStatus(DllCall("gdiplus\GdipFillEllipseI(nativeGraphics,
                                                      brush->nativeBrush,
                                                      x,
                                                      y,
                                                      width,
                                                      height));
    }

    Status FillPie(IN const Brush* brush,
                   IN const RectF& rect,
                   IN REAL startAngle,
                   IN REAL sweepAngle)
    {
        return FillPie(brush, rect.X, rect.Y, rect.Width, rect.Height,
                       startAngle, sweepAngle);
    }

    Status FillPie(IN const Brush* brush,
                   IN REAL x,
                   IN REAL y,
                   IN REAL width,
                   IN REAL height,
                   IN REAL startAngle,
                   IN REAL sweepAngle)
    {
        return SetStatus(DllCall("gdiplus\GdipFillPie(nativeGraphics,
                                                 brush->nativeBrush, x, y,
                                                 width, height, startAngle,
                                                 sweepAngle));
    }

    Status FillPie(IN const Brush* brush,
                   IN const Rect& rect,
                   IN REAL startAngle,
                   IN REAL sweepAngle)
    {
        return FillPie(brush, rect.X, rect.Y, rect.Width, rect.Height,
                       startAngle, sweepAngle);
    }

    Status FillPie(IN const Brush* brush,
                   IN INT x,
                   IN INT y,
                   IN INT width,
                   IN INT height,
                   IN REAL startAngle,
                   IN REAL sweepAngle)
    {
        return SetStatus(DllCall("gdiplus\GdipFillPieI(nativeGraphics,
                                                  brush->nativeBrush,
                                                  x,
                                                  y,
                                                  width,
                                                  height,
                                                  startAngle,
                                                  sweepAngle));
    }

    Status FillPath(IN const Brush* brush,
                    IN const GraphicsPath* path)
    {
        return SetStatus(DllCall("gdiplus\GdipFillPath(nativeGraphics,
                                                  brush->nativeBrush,
                                                  path->nativePath));
    }

    Status FillClosedCurve(IN const Brush* brush,
                           IN const PointF* points,
                           IN INT count)
    {
        return SetStatus(DllCall("gdiplus\GdipFillClosedCurve(nativeGraphics,
                                                         brush->nativeBrush,
                                                         points, count));

    }

    Status FillClosedCurve(IN const Brush* brush,
                           IN const PointF* points,
                           IN INT count,
                           IN FillMode fillMode,
                           IN REAL tension = 0.5f)
    {
        return SetStatus(DllCall("gdiplus\GdipFillClosedCurve2(nativeGraphics,
                                                          brush->nativeBrush,
                                                          points, count,
                                                          tension, fillMode));
    }

    Status FillClosedCurve(IN const Brush* brush,
                           IN const Point* points,
                           IN INT count)
    {
        return SetStatus(DllCall("gdiplus\GdipFillClosedCurveI(nativeGraphics,
                                                          brush->nativeBrush,
                                                          points,
                                                          count));
    }

    Status FillClosedCurve(IN const Brush* brush,
                           IN const Point* points,
                           IN INT count,
                           IN FillMode fillMode,
                           IN REAL tension = 0.5f)
    {
        return SetStatus(DllCall("gdiplus\GdipFillClosedCurve2I(nativeGraphics,
                                                           brush->nativeBrush,
                                                           points, count,
                                                           tension, fillMode));
    }

    Status FillRegion(IN const Brush* brush,
                      IN const Region* region)
    {
        return SetStatus(DllCall("gdiplus\GdipFillRegion(nativeGraphics,
                                                    brush->nativeBrush,
                                                    region->nativeRegion));
    }

    Status
    DrawString(
        IN const WCHAR        *string,
        IN INT                 length,
        IN const Font         *font,
        IN const RectF        &layoutRect,
        IN const StringFormat *stringFormat,
        IN const Brush        *brush
    )
    {
        return SetStatus(DllCall("gdiplus\GdipDrawString(
            nativeGraphics,
            string,
            length,
            font ? font->nativeFont : NULL,
            &layoutRect,
            stringFormat ? stringFormat->nativeFormat : NULL,
            brush ? brush->nativeBrush : NULL
        ));
    }

    Status
    DrawString(
        const WCHAR        *string,
        INT                 length,
        const Font         *font,
        const PointF       &origin,
        const Brush        *brush
    )
    {
        RectF rect(origin.X, origin.Y, 0.0f, 0.0f);

        return SetStatus(DllCall("gdiplus\GdipDrawString(
            nativeGraphics,
            string,
            length,
            font ? font->nativeFont : NULL,
            &rect,
            NULL,
            brush ? brush->nativeBrush : NULL
        ));
    }

    Status
    DrawString(
        const WCHAR        *string,
        INT                 length,
        const Font         *font,
        const PointF       &origin,
        const StringFormat *stringFormat,
        const Brush        *brush
    )
    {
        RectF rect(origin.X, origin.Y, 0.0f, 0.0f);

        return SetStatus(DllCall("gdiplus\GdipDrawString(
            nativeGraphics,
            string,
            length,
            font ? font->nativeFont : NULL,
            &rect,
            stringFormat ? stringFormat->nativeFormat : NULL,
            brush ? brush->nativeBrush : NULL
        ));
    }

    Status
    MeasureString(
        IN const WCHAR        *string,
        IN INT                 length,
        IN const Font         *font,
        IN const RectF        &layoutRect,
        IN const StringFormat *stringFormat,
        OUT RectF             *boundingBox,
        OUT INT               *codepointsFitted = 0,
        OUT INT               *linesFilled      = 0
    ) const
    {
        return SetStatus(DllCall("gdiplus\GdipMeasureString(
            nativeGraphics,
            string,
            length,
            font ? font->nativeFont : NULL,
            &layoutRect,
            stringFormat ? stringFormat->nativeFormat : NULL,
            boundingBox,
            codepointsFitted,
            linesFilled
        ));
    }

    Status
    MeasureString(
        IN const WCHAR        *string,
        IN INT                 length,
        IN const Font         *font,
        IN const SizeF        &layoutRectSize,
        IN const StringFormat *stringFormat,
        OUT SizeF             *size,
        OUT INT               *codepointsFitted = 0,
        OUT INT               *linesFilled      = 0
    ) const
    {
        RectF   layoutRect(0, 0, layoutRectSize.Width, layoutRectSize.Height);
        RectF   boundingBox;
        Status  status;

        if (size == NULL)
        {
            return SetStatus(InvalidParameter);
        }

        status = SetStatus(DllCall("gdiplus\GdipMeasureString(
            nativeGraphics,
            string,
            length,
            font ? font->nativeFont : NULL,
            &layoutRect,
            stringFormat ? stringFormat->nativeFormat : NULL,
            size ? &boundingBox : NULL,
            codepointsFitted,
            linesFilled
        ));

        if (size && status == Ok)
        {
            size->Width  = boundingBox.Width;
            size->Height = boundingBox.Height;
        }

        return status;
    }

    Status
    MeasureString(
        IN const WCHAR        *string,
        IN INT                 length,
        IN const Font         *font,
        IN const PointF       &origin,
        IN const StringFormat *stringFormat,
        OUT RectF             *boundingBox
    ) const
    {
        RectF rect(origin.X, origin.Y, 0.0f, 0.0f);

        return SetStatus(DllCall("gdiplus\GdipMeasureString(
            nativeGraphics,
            string,
            length,
            font ? font->nativeFont : NULL,
            &rect,
            stringFormat ? stringFormat->nativeFormat : NULL,
            boundingBox,
            NULL,
            NULL
        ));
    }

    Status
    MeasureString(
        IN const WCHAR  *string,
        IN INT           length,
        IN const Font   *font,
        IN const RectF  &layoutRect,
        OUT RectF       *boundingBox
    ) const
    {
        return SetStatus(DllCall("gdiplus\GdipMeasureString(
            nativeGraphics,
            string,
            length,
            font ? font->nativeFont : NULL,
            &layoutRect,
            NULL,
            boundingBox,
            NULL,
            NULL
        ));
    }

    Status
    MeasureString(
        IN const WCHAR  *string,
        IN INT           length,
        IN const Font   *font,
        IN const PointF &origin,
        OUT RectF       *boundingBox
    ) const
    {
        RectF rect(origin.X, origin.Y, 0.0f, 0.0f);

        return SetStatus(DllCall("gdiplus\GdipMeasureString(
            nativeGraphics,
            string,
            length,
            font ? font->nativeFont : NULL,
            &rect,
            NULL,
            boundingBox,
            NULL,
            NULL
        ));
    }


    Status
    MeasureCharacterRanges(
        IN const WCHAR        *string,
        IN INT                 length,
        IN const Font         *font,
        IN const RectF        &layoutRect,
        IN const StringFormat *stringFormat,
        IN INT                 regionCount,
        OUT Region            *regions
    ) const
    {
        if (!regions || regionCount <= 0)
        {
            return InvalidParameter;
        }

        GpRegion **nativeRegions = new GpRegion* [regionCount];

        if (!nativeRegions)
        {
            return OutOfMemory;
        }

        for (INT i = 0; i < regionCount; i++)
        {
            nativeRegions[i] = regions[i].nativeRegion;
        }

        Status status = SetStatus(DllCall("gdiplus\GdipMeasureCharacterRanges(
            nativeGraphics,
            string,
            length,
            font ? font->nativeFont : NULL,
            layoutRect,
            stringFormat ? stringFormat->nativeFormat : NULL,
            regionCount,
            nativeRegions
        ));

        delete [] nativeRegions;

        return status;
    }

    Status DrawDriverString(
        IN const UINT16  *text,
        IN INT            length,
        IN const Font    *font,
        IN const Brush   *brush,
        IN const PointF  *positions,
        IN INT            flags,
        IN const Matrix        *matrix
    )
    {
        return SetStatus(DllCall("gdiplus\GdipDrawDriverString(
            nativeGraphics,
            text,
            length,
            font ? font->nativeFont : NULL,
            brush ? brush->nativeBrush : NULL,
            positions,
            flags,
            matrix ? matrix->nativeMatrix : NULL
        ));
    }

    Status MeasureDriverString(
        IN const UINT16  *text,
        IN INT            length,
        IN const Font    *font,
        IN const PointF  *positions,
        IN INT            flags,
        IN const Matrix        *matrix,
        OUT RectF        *boundingBox
    ) const
    {
        return SetStatus(DllCall("gdiplus\GdipMeasureDriverString(
            nativeGraphics,
            text,
            length,
            font ? font->nativeFont : NULL,
            positions,
            flags,
            matrix ? matrix->nativeMatrix : NULL,
            boundingBox
        ));
    }

    ; Draw a cached bitmap on this graphics destination offset by
    ; x, y. Note this will fail with WrongState if the CachedBitmap
    ; native format differs from this Graphics.

    Status DrawCachedBitmap(IN CachedBitmap *cb,
                            IN INT x,
                            IN INT y)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawCachedBitmap(
            nativeGraphics,
            cb->nativeCachedBitmap,
            x, y
        ));
    }

    Status DrawImage(IN Image* image,
                     IN const PointF& point)
    {
        return DrawImage(image, point.X, point.Y);
    }

    Status DrawImage(IN Image* image,
                     IN REAL x,
                     IN REAL y)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawImage(nativeGraphics,
                                                   image ? image->nativeImage
                                                         : NULL,
                                                   x,
                                                   y));
    }

    Status DrawImage(IN Image* image, 
                     IN const RectF& rect)
    {
        return DrawImage(image, rect.X, rect.Y, rect.Width, rect.Height);
    }

    Status DrawImage(IN Image* image,
                     IN REAL x,
                     IN REAL y,
                     IN REAL width,
                     IN REAL height)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawImageRect(nativeGraphics,
                                                       image ? image->nativeImage
                                                             : NULL,
                                                       x,
                                                       y,
                                                       width,
                                                       height));
    }

    Status DrawImage(IN Image* image,
                     IN const Point& point)
    {
        return DrawImage(image, point.X, point.Y);
    }

    Status DrawImage(IN Image* image,
                     IN INT x,
                     IN INT y)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawImageI(nativeGraphics,
                                                    image ? image->nativeImage
                                                          : NULL,
                                                    x,
                                                    y));
    }

    Status DrawImage(IN Image* image,
                     IN const Rect& rect)
    {
        return DrawImage(image,
                         rect.X,
                         rect.Y,
                         rect.Width,
                         rect.Height);
    }

    Status DrawImage(IN Image* image,
                     IN INT x,
                     IN INT y,
                     IN INT width,
                     IN INT height) {
        return SetStatus(DllCall("gdiplus\GdipDrawImageRectI(nativeGraphics,
                                                        image ? image->nativeImage
                                                              : NULL,
                                                        x,
                                                        y,
                                                        width,
                                                        height));
    }

    
    Status DrawImage(IN Image* image,
                     IN const PointF* destPoints,
                     IN INT count)
    {
        if (count != 3 && count != 4)
            return SetStatus(InvalidParameter);

        return SetStatus(DllCall("gdiplus\GdipDrawImagePoints(nativeGraphics,
                                                         image ? image->nativeImage
                                                               : NULL,
                                                         destPoints, count));
    }

    Status DrawImage(IN Image* image,
                     IN const Point* destPoints,
                     IN INT count)
    {
        if (count != 3 && count != 4)
            return SetStatus(InvalidParameter);

        return SetStatus(DllCall("gdiplus\GdipDrawImagePointsI(nativeGraphics,
                                                          image ? image->nativeImage
                                                                : NULL,
                                                          destPoints,
                                                          count));
    }

    Status DrawImage(IN Image* image,
                     IN REAL x,
                     IN REAL y,
                     IN REAL srcx,
                     IN REAL srcy,
                     IN REAL srcwidth,
                     IN REAL srcheight,
                     IN Unit srcUnit)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawImagePointRect(nativeGraphics,
                                                            image ? image->nativeImage
                                                                  : NULL,
                                                            x, y,
                                                            srcx, srcy,
                                                            srcwidth, srcheight, srcUnit));
    }

    Status DrawImage(IN Image* image,
                     IN const RectF& destRect,
                     IN REAL srcx,
                     IN REAL srcy,
                     IN REAL srcwidth,
                     IN REAL srcheight,
                     IN Unit srcUnit,
                     IN const ImageAttributes* imageAttributes = NULL,
                     IN DrawImageAbort callback = NULL,
                     IN VOID* callbackData = NULL)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawImageRectRect(nativeGraphics,
                                                           image ? image->nativeImage
                                                                 : NULL,
                                                           destRect.X,
                                                           destRect.Y,
                                                           destRect.Width,
                                                           destRect.Height,
                                                           srcx, srcy,
                                                           srcwidth, srcheight,
                                                           srcUnit,
                                                           imageAttributes
                                                            ? imageAttributes->nativeImageAttr
                                                            : NULL,
                                                           callback,
                                                           callbackData));
    }

    Status DrawImage(IN Image* image,
                     IN const PointF* destPoints,
                     IN INT count,
                     IN REAL srcx,
                     IN REAL srcy,
                     IN REAL srcwidth,
                     IN REAL srcheight,
                     IN Unit srcUnit,
                     IN const ImageAttributes* imageAttributes = NULL,
                     IN DrawImageAbort callback = NULL,
                     IN VOID* callbackData = NULL)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawImagePointsRect(nativeGraphics,
                                                             image ? image->nativeImage
                                                                   : NULL,
                                                             destPoints, count,
                                                             srcx, srcy,
                                                             srcwidth,
                                                             srcheight,
                                                             srcUnit,
                                                             imageAttributes
                                                              ? imageAttributes->nativeImageAttr
                                                              : NULL,
                                                             callback,
                                                             callbackData));
    }

    Status DrawImage(IN Image* image,
                     IN INT x,
                     IN INT y,
                     IN INT srcx,
                     IN INT srcy,
                     IN INT srcwidth,
                     IN INT srcheight,
                     IN Unit srcUnit)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawImagePointRectI(nativeGraphics,
                                                             image ? image->nativeImage
                                                                   : NULL,
                                                             x,
                                                             y,
                                                             srcx,
                                                             srcy,
                                                             srcwidth,
                                                             srcheight,
                                                             srcUnit));
    }

    Status DrawImage(IN Image* image,
                     IN const Rect& destRect,
                     IN INT srcx,
                     IN INT srcy,
                     IN INT srcwidth,
                     IN INT srcheight,
                     IN Unit srcUnit,
                     IN const ImageAttributes* imageAttributes = NULL,
                     IN DrawImageAbort callback = NULL,
                     IN VOID* callbackData = NULL)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawImageRectRectI(nativeGraphics,
                                                            image ? image->nativeImage
                                                                  : NULL,
                                                            destRect.X,
                                                            destRect.Y,
                                                            destRect.Width,
                                                            destRect.Height,
                                                            srcx,
                                                            srcy,
                                                            srcwidth,
                                                            srcheight,
                                                            srcUnit,
                                                            imageAttributes
                                                            ? imageAttributes->nativeImageAttr
                                                            : NULL,
                                                            callback,
                                                            callbackData));
    }

    Status DrawImage(IN Image* image,
                     IN const Point* destPoints,
                     IN INT count,
                     IN INT srcx,
                     IN INT srcy,
                     IN INT srcwidth,
                     IN INT srcheight,
                     IN Unit srcUnit,
                     IN const ImageAttributes* imageAttributes = NULL,
                     IN DrawImageAbort callback = NULL,
                     IN VOID* callbackData = NULL)
    {
        return SetStatus(DllCall("gdiplus\GdipDrawImagePointsRectI(nativeGraphics,
                                                              image ? image->nativeImage
                                                                    : NULL,
                                                              destPoints,
                                                              count,
                                                              srcx,
                                                              srcy,
                                                              srcwidth,
                                                              srcheight,
                                                              srcUnit,
                                                              imageAttributes
                                                               ? imageAttributes->nativeImageAttr
                                                               : NULL,
                                                              callback,
                                                              callbackData));
    }
    
#if (GDIPVER >= 0x0110)
    Status DrawImage(
        IN Image *image,
        IN const RectF &destRect,
        IN const RectF &sourceRect,
        IN Unit srcUnit,
        IN const ImageAttributes *imageAttributes = NULL
    )
    {
        return SetStatus(DllCall("gdiplus\GdipDrawImageRectRect(
            nativeGraphics,
            image->nativeImage,
            destRect.X,
            destRect.Y,
            destRect.Width,
            destRect.Height,
            sourceRect.X,
            sourceRect.Y,
            sourceRect.Width,
            sourceRect.Height,
            srcUnit,
            imageAttributes ? imageAttributes->nativeImageAttr : NULL,
            NULL,
            NULL
        ));
    }

    Status DrawImage(
        IN Image *image,
        IN RectF *sourceRect,
        IN Matrix *xForm,
        IN Effect *effect,
        IN ImageAttributes *imageAttributes,
        IN Unit srcUnit
    )
    {
        return SetStatus(DllCall("gdiplus\GdipDrawImageFX(
            nativeGraphics,
            image->nativeImage,
            sourceRect,
            xForm ? xForm->nativeMatrix : NULL,
            effect ? effect->nativeEffect : NULL,
            imageAttributes ? imageAttributes->nativeImageAttr : NULL,
            srcUnit
        ));
    }
#endif ;(GDIPVER >= 0x0110)

    ; The following methods are for playing an EMF+ to a graphics
    ; via the enumeration interface.  Each record of the EMF+ is
    ; sent to the callback (along with the callbackData).  Then
    ; the callback can invoke the Metafile::PlayRecord method
    ; to play the particular record.

    Status
    EnumerateMetafile(
        IN const Metafile *        metafile,
        IN const PointF &          destPoint,
        IN EnumerateMetafileProc   callback,
        IN VOID *                  callbackData    = NULL,
        IN const ImageAttributes *       imageAttributes = NULL
        )
    {
        return SetStatus(DllCall("gdiplus\GdipEnumerateMetafileDestPoint(
                    nativeGraphics,
                    (const GpMetafile *)(metafile ? metafile->nativeImage:NULL),
                    destPoint,
                    callback,
                    callbackData,
                    imageAttributes ? imageAttributes->nativeImageAttr : NULL));
    }

    Status
    EnumerateMetafile(
        IN const Metafile *        metafile,
        IN const Point &           destPoint,
        IN EnumerateMetafileProc   callback,
        IN VOID *                  callbackData    = NULL,
        IN const ImageAttributes *       imageAttributes = NULL
        )
    {
        return SetStatus(DllCall("gdiplus\GdipEnumerateMetafileDestPointI(
                    nativeGraphics,
                    (const GpMetafile *)(metafile ? metafile->nativeImage:NULL),
                    destPoint,
                    callback,
                    callbackData,
                    imageAttributes ? imageAttributes->nativeImageAttr : NULL));
    }

    Status
    EnumerateMetafile(
        IN const Metafile *        metafile,
        IN const RectF &           destRect,
        IN EnumerateMetafileProc   callback,
        IN VOID *                  callbackData    = NULL,
        IN const ImageAttributes *       imageAttributes = NULL
        )
    {
        return SetStatus(DllCall("gdiplus\GdipEnumerateMetafileDestRect(
                    nativeGraphics,
                    (const GpMetafile *)(metafile ? metafile->nativeImage:NULL),
                    destRect,
                    callback,
                    callbackData,
                    imageAttributes ? imageAttributes->nativeImageAttr : NULL));
    }

    Status
    EnumerateMetafile(
        IN const Metafile *        metafile,
        IN const Rect &            destRect,
        IN EnumerateMetafileProc   callback,
        IN VOID *                  callbackData    = NULL,
        IN const ImageAttributes *       imageAttributes = NULL
        )
    {
        return SetStatus(DllCall("gdiplus\GdipEnumerateMetafileDestRectI(
                    nativeGraphics,
                    (const GpMetafile *)(metafile ? metafile->nativeImage:NULL),
                    destRect,
                    callback,
                    callbackData,
                    imageAttributes ? imageAttributes->nativeImageAttr : NULL));
    }

    Status
    EnumerateMetafile(
        IN const Metafile *        metafile,
        IN const PointF *          destPoints,
        IN INT                     count,
        IN EnumerateMetafileProc   callback,
        IN VOID *                  callbackData    = NULL,
        IN const ImageAttributes *       imageAttributes = NULL
        )
    {
        return SetStatus(DllCall("gdiplus\GdipEnumerateMetafileDestPoints(
                    nativeGraphics,
                    (const GpMetafile *)(metafile ? metafile->nativeImage:NULL),
                    destPoints,
                    count,
                    callback,
                    callbackData,
                    imageAttributes ? imageAttributes->nativeImageAttr : NULL));
    }

    Status
    EnumerateMetafile(
        IN const Metafile *        metafile,
        IN const Point *           destPoints,
        IN INT                     count,
        IN EnumerateMetafileProc   callback,
        IN VOID *                  callbackData    = NULL,
        IN const ImageAttributes *       imageAttributes = NULL
        )
    {
        return SetStatus(DllCall("gdiplus\GdipEnumerateMetafileDestPointsI(
                    nativeGraphics,
                    (const GpMetafile *)(metafile ? metafile->nativeImage:NULL),
                    destPoints,
                    count,
                    callback,
                    callbackData,
                    imageAttributes ? imageAttributes->nativeImageAttr : NULL));
    }

    Status
    EnumerateMetafile(
        IN const Metafile *        metafile,
        IN const PointF &          destPoint,
        IN const RectF &           srcRect,
        IN Unit                    srcUnit,
        IN EnumerateMetafileProc   callback,
        IN VOID *                  callbackData    = NULL,
        IN const ImageAttributes *       imageAttributes = NULL
        )
    {
        return SetStatus(DllCall("gdiplus\GdipEnumerateMetafileSrcRectDestPoint(
                    nativeGraphics,
                    (const GpMetafile *)(metafile ? metafile->nativeImage:NULL),
                    destPoint,
                    srcRect,
                    srcUnit,
                    callback,
                    callbackData,
                    imageAttributes ? imageAttributes->nativeImageAttr : NULL));
    }

    Status
    EnumerateMetafile(
        IN const Metafile *        metafile,
        IN const Point &           destPoint,
        IN const Rect &            srcRect,
        IN Unit                    srcUnit,
        IN EnumerateMetafileProc   callback,
        IN VOID *                  callbackData    = NULL,
        IN const ImageAttributes *       imageAttributes = NULL
        )
    {
        return SetStatus(DllCall("gdiplus\GdipEnumerateMetafileSrcRectDestPointI(
                    nativeGraphics,
                    (const GpMetafile *)(metafile ? metafile->nativeImage:NULL),
                    destPoint,
                    srcRect,
                    srcUnit,
                    callback,
                    callbackData,
                    imageAttributes ? imageAttributes->nativeImageAttr : NULL));
    }

    Status
    EnumerateMetafile(
        IN const Metafile *        metafile,
        IN const RectF &           destRect,
        IN const RectF &           srcRect,
        IN Unit                    srcUnit,
        IN EnumerateMetafileProc   callback,
        IN VOID *                  callbackData    = NULL,
        IN const ImageAttributes *       imageAttributes = NULL
        )
    {
        return SetStatus(DllCall("gdiplus\GdipEnumerateMetafileSrcRectDestRect(
                    nativeGraphics,
                    (const GpMetafile *)(metafile ? metafile->nativeImage:NULL),
                    destRect,
                    srcRect,
                    srcUnit,
                    callback,
                    callbackData,
                    imageAttributes ? imageAttributes->nativeImageAttr : NULL));
    }

    Status
    EnumerateMetafile(
        IN const Metafile *        metafile,
        IN const Rect &            destRect,
        IN const Rect &            srcRect,
        IN Unit                    srcUnit,
        IN EnumerateMetafileProc   callback,
        IN VOID *                  callbackData    = NULL,
        IN const ImageAttributes *       imageAttributes = NULL
        )
    {
        return SetStatus(DllCall("gdiplus\GdipEnumerateMetafileSrcRectDestRectI(
                    nativeGraphics,
                    (const GpMetafile *)(metafile ? metafile->nativeImage:NULL),
                    destRect,
                    srcRect,
                    srcUnit,
                    callback,
                    callbackData,
                    imageAttributes ? imageAttributes->nativeImageAttr : NULL));
    }

    Status
    EnumerateMetafile(
        IN const Metafile *        metafile,
        IN const PointF *          destPoints,
        IN INT                     count,
        IN const RectF &           srcRect,
        IN Unit                    srcUnit,
        IN EnumerateMetafileProc   callback,
        IN VOID *                  callbackData    = NULL,
        IN const ImageAttributes *       imageAttributes = NULL
        )
    {
        return SetStatus(DllCall("gdiplus\GdipEnumerateMetafileSrcRectDestPoints(
                    nativeGraphics,
                    (const GpMetafile *)(metafile ? metafile->nativeImage:NULL),
                    destPoints,
                    count,
                    srcRect,
                    srcUnit,
                    callback,
                    callbackData,
                    imageAttributes ? imageAttributes->nativeImageAttr : NULL));
    }

    Status
    EnumerateMetafile(
        IN const Metafile *        metafile,
        IN const Point *           destPoints,
        IN INT                     count,
        IN const Rect &            srcRect,
        IN Unit                    srcUnit,
        IN EnumerateMetafileProc   callback,
        IN VOID *                  callbackData    = NULL,
        IN const ImageAttributes *       imageAttributes = NULL
        )
    {
        return SetStatus(DllCall("gdiplus\GdipEnumerateMetafileSrcRectDestPointsI(
                    nativeGraphics,
                    (const GpMetafile *)(metafile ? metafile->nativeImage:NULL),
                    destPoints,
                    count,
                    srcRect,
                    srcUnit,
                    callback,
                    callbackData,
                    imageAttributes ? imageAttributes->nativeImageAttr : NULL));
    }
    
    Status SetClip(IN const Graphics* g,
                   IN CombineMode combineMode = CombineModeReplace)
    {
        return SetStatus(DllCall("gdiplus\GdipSetClipGraphics(nativeGraphics,
                                                         g->nativeGraphics,
                                                         combineMode));
    }

    Status SetClip(IN const RectF& rect,
                   IN CombineMode combineMode = CombineModeReplace)
    {
        return SetStatus(DllCall("gdiplus\GdipSetClipRect(nativeGraphics,
                                                     rect.X, rect.Y,
                                                     rect.Width, rect.Height,
                                                     combineMode));
    }

    Status SetClip(IN const Rect& rect,
                   IN CombineMode combineMode = CombineModeReplace)
    {
        return SetStatus(DllCall("gdiplus\GdipSetClipRectI(nativeGraphics,
                                                      rect.X, rect.Y,
                                                      rect.Width, rect.Height,
                                                      combineMode));
    }

    Status SetClip(IN const GraphicsPath* path,
                   IN CombineMode combineMode = CombineModeReplace)
    {
        return SetStatus(DllCall("gdiplus\GdipSetClipPath(nativeGraphics,
                                                     path->nativePath,
                                                     combineMode));
    }

    Status SetClip(IN const Region* region,
                   IN CombineMode combineMode = CombineModeReplace)
    {
        return SetStatus(DllCall("gdiplus\GdipSetClipRegion(nativeGraphics,
                                                       region->nativeRegion,
                                                       combineMode));
    }

    ; This is different than the other SetClip methods because it assumes
    ; that the HRGN is already in device units, so it doesn't transform
    ; the coordinates in the HRGN.
    
    Status SetClip(IN HRGN hRgn,
                   IN CombineMode combineMode = CombineModeReplace)
    {
        return SetStatus(DllCall("gdiplus\GdipSetClipHrgn(nativeGraphics, hRgn,
                                                     combineMode));
    }

    Status IntersectClip(IN const RectF& rect)
    {
        return SetStatus(DllCall("gdiplus\GdipSetClipRect(nativeGraphics,
                                                     rect.X, rect.Y,
                                                     rect.Width, rect.Height,
                                                     CombineModeIntersect));
    }

    Status IntersectClip(IN const Rect& rect)
    {
        return SetStatus(DllCall("gdiplus\GdipSetClipRectI(nativeGraphics,
                                                      rect.X, rect.Y,
                                                      rect.Width, rect.Height,
                                                      CombineModeIntersect));
    }

    Status IntersectClip(IN const Region* region)
    {
        return SetStatus(DllCall("gdiplus\GdipSetClipRegion(nativeGraphics,
                                                       region->nativeRegion,
                                                       CombineModeIntersect));
    }

    Status ExcludeClip(IN const RectF& rect)
    {
        return SetStatus(DllCall("gdiplus\GdipSetClipRect(nativeGraphics,
                                                     rect.X, rect.Y,
                                                     rect.Width, rect.Height,
                                                     CombineModeExclude));
    }

    Status ExcludeClip(IN const Rect& rect)
    {
        return SetStatus(DllCall("gdiplus\GdipSetClipRectI(nativeGraphics,
                                                      rect.X, rect.Y,
                                                      rect.Width, rect.Height,
                                                      CombineModeExclude));
    }

    Status ExcludeClip(IN const Region* region)
    {
        return SetStatus(DllCall("gdiplus\GdipSetClipRegion(nativeGraphics,
                                                       region->nativeRegion,
                                                       CombineModeExclude));
    }

    Status ResetClip()
    {
        return SetStatus(DllCall("gdiplus\GdipResetClip(nativeGraphics));
    }

    Status TranslateClip(IN REAL dx,
                         IN REAL dy)
    {
        return SetStatus(DllCall("gdiplus\GdipTranslateClip(nativeGraphics, dx, dy));
    }

    Status TranslateClip(IN INT dx,
                         IN INT dy)
    {
        return SetStatus(DllCall("gdiplus\GdipTranslateClipI(nativeGraphics,
                                                        dx, dy));
    }

    Status GetClip(OUT Region* region) const
    {
        return SetStatus(DllCall("gdiplus\GdipGetClip(nativeGraphics,
                                                 region->nativeRegion));
    }

    Status GetClipBounds(OUT RectF* rect) const
    {
        return SetStatus(DllCall("gdiplus\GdipGetClipBounds(nativeGraphics, rect));
    }

    Status GetClipBounds(OUT Rect* rect) const
    {
        return SetStatus(DllCall("gdiplus\GdipGetClipBoundsI(nativeGraphics, rect));
    }

    BOOL IsClipEmpty() const
    {
        BOOL booln = FALSE;

        SetStatus(DllCall("gdiplus\GdipIsClipEmpty(nativeGraphics, &booln));

        return booln;
    }

    Status GetVisibleClipBounds(OUT RectF *rect) const
    {

        return SetStatus(DllCall("gdiplus\GdipGetVisibleClipBounds(nativeGraphics,
                                                              rect));
    }

    Status GetVisibleClipBounds(OUT Rect *rect) const
    {
       return SetStatus(DllCall("gdiplus\GdipGetVisibleClipBoundsI(nativeGraphics,
                                                              rect));
    }

    BOOL IsVisibleClipEmpty() const
    {
        BOOL booln = FALSE;

        SetStatus(DllCall("gdiplus\GdipIsVisibleClipEmpty(nativeGraphics, &booln));

        return booln;
    }

    BOOL IsVisible(IN INT x,
                   IN INT y) const
    {
        return IsVisible(Point(x,y));
    }

    BOOL IsVisible(IN const Point& point) const
    {
        BOOL booln = FALSE;

        SetStatus(DllCall("gdiplus\GdipIsVisiblePointI(nativeGraphics,
                                                  point.X,
                                                  point.Y,
                                                  &booln));

        return booln;
    }

    BOOL IsVisible(IN INT x,
                   IN INT y,
                   IN INT width,
                   IN INT height) const
    {
        return IsVisible(Rect(x, y, width, height));
    }

    BOOL IsVisible(IN const Rect& rect) const
    {

        BOOL booln = TRUE;

        SetStatus(DllCall("gdiplus\GdipIsVisibleRectI(nativeGraphics,
                                                 rect.X,
                                                 rect.Y,
                                                 rect.Width,
                                                 rect.Height,
                                                 &booln));
        return booln;
    }

    BOOL IsVisible(IN REAL x,
                   IN REAL y) const
    {
        return IsVisible(PointF(x, y));
    }

    BOOL IsVisible(IN const PointF& point) const
    {
        BOOL booln = FALSE;

        SetStatus(DllCall("gdiplus\GdipIsVisiblePoint(nativeGraphics,
                                                 point.X,
                                                 point.Y,
                                                 &booln));

        return booln;
    }

    BOOL IsVisible(IN REAL x,
                   IN REAL y,
                   IN REAL width,
                   IN REAL height) const
    {
        return IsVisible(RectF(x, y, width, height));
    }

    BOOL IsVisible(IN const RectF& rect) const
    {
        BOOL booln = TRUE;

        SetStatus(DllCall("gdiplus\GdipIsVisibleRect(nativeGraphics,
                                                rect.X,
                                                rect.Y,
                                                rect.Width,
                                                rect.Height,
                                                &booln));
        return booln;
    }

    GraphicsState Save() const
    {
        GraphicsState gstate;

        SetStatus(DllCall("gdiplus\GdipSaveGraphics(nativeGraphics, &gstate));

        return gstate;
    }

    Status Restore(IN GraphicsState gstate)
    {
        return SetStatus(DllCall("gdiplus\GdipRestoreGraphics(nativeGraphics,
                                                         gstate));
    }

    GraphicsContainer BeginContainer(IN const RectF &dstrect,
                                     IN const RectF &srcrect,
                                     IN Unit         unit)
    {
        GraphicsContainer state;

        SetStatus(DllCall("gdiplus\GdipBeginContainer(nativeGraphics, &dstrect,
                                                 &srcrect, unit, &state));

        return state;
    }

    GraphicsContainer BeginContainer(IN const Rect    &dstrect,
                                     IN const Rect    &srcrect,
                                     IN Unit           unit)
    {
        GraphicsContainer state;

        SetStatus(DllCall("gdiplus\GdipBeginContainerI(nativeGraphics, &dstrect,
                                                  &srcrect, unit, &state));

        return state;
    }

    GraphicsContainer BeginContainer()
    {
        GraphicsContainer state;

        SetStatus(DllCall("gdiplus\GdipBeginContainer2(nativeGraphics, &state));

        return state;
    }

    Status EndContainer(IN GraphicsContainer state)
    {
        return SetStatus(DllCall("gdiplus\GdipEndContainer(nativeGraphics, state));
    }

    ; Only valid when recording metafiles.

    Status AddMetafileComment(IN const BYTE * data,
                              IN UINT sizeData)
    {
        return SetStatus(DllCall("gdiplus\GdipComment(nativeGraphics, sizeData, data));
    }

    static HPALETTE GetHalftonePalette()
    {
        return DllCall("gdiplus\GdipCreateHalftonePalette();
    }

    Status GetLastStatus() const
    {
        Status lastStatus = lastResult;
        lastResult = Ok;

        return lastStatus;
    }

private:
    Graphics(const Graphics &);
    Graphics& operator=(const Graphics &);

protected:
    Graphics(GpGraphics* graphics)
    {
        lastResult = Ok;
        SetNativeGraphics(graphics);
    }

    VOID SetNativeGraphics(GpGraphics *graphics)
    {
        this->nativeGraphics = graphics;
    }

    Status SetStatus(Status status) const
    {
        if (status != Ok)
            return (lastResult = status);
        else
            return status;
    }

    GpGraphics* GetNativeGraphics() const
    {
        return this->nativeGraphics;
    }

    GpPen* GetNativePen(const Pen* pen)
    {
        return pen->nativePen;
    }

protected:
    GpGraphics* nativeGraphics;
    mutable Status lastResult;

};

;----------------------------------------------------------------------------
; Implementation of GraphicsPath methods that use Graphics
;----------------------------------------------------------------------------

; The GetBounds rectangle may not be the tightest bounds.

inline Status
GraphicsPath::GetBounds(
    OUT RectF* bounds,
    IN const Matrix* matrix,
    IN const Pen* pen) const
{
    GpMatrix* nativeMatrix = NULL;
    GpPen* nativePen = NULL;

    if (matrix)
        nativeMatrix = matrix->nativeMatrix;

    if (pen)
        nativePen = pen->nativePen;

    return SetStatus(DllCall("gdiplus\GdipGetPathWorldBounds(nativePath, bounds,
                                                   nativeMatrix, nativePen));
}

inline Status
GraphicsPath::GetBounds(
    OUT Rect* bounds,
    IN const Matrix* matrix,
    IN const Pen* pen
) const
{
    GpMatrix* nativeMatrix = NULL;
    GpPen* nativePen = NULL;

    if (matrix)
        nativeMatrix = matrix->nativeMatrix;

    if (pen)
        nativePen = pen->nativePen;

    return SetStatus(DllCall("gdiplus\GdipGetPathWorldBoundsI(nativePath, bounds,
                                                    nativeMatrix, nativePen));
}

inline BOOL
GraphicsPath::IsVisible(
    IN REAL x,
    IN REAL y,
    IN const Graphics* g) const
{
   BOOL booln = FALSE;

   GpGraphics* nativeGraphics = NULL;

   if (g)
       nativeGraphics = g->nativeGraphics;

   SetStatus(DllCall("gdiplus\GdipIsVisiblePathPoint(nativePath,
                                                x, y, nativeGraphics,
                                                &booln));
   return booln;
}

inline BOOL
GraphicsPath::IsVisible(
    IN INT x,
    IN INT y,
    IN const Graphics* g) const
{
   BOOL booln = FALSE;

   GpGraphics* nativeGraphics = NULL;

   if (g)
       nativeGraphics = g->nativeGraphics;

   SetStatus(DllCall("gdiplus\GdipIsVisiblePathPointI(nativePath,
                                                 x, y, nativeGraphics,
                                                 &booln));
   return booln;
}

inline BOOL
GraphicsPath::IsOutlineVisible(
    IN REAL x,
    IN REAL y,
    IN const Pen* pen,
    IN const Graphics* g) const
{
    BOOL booln = FALSE;

    GpGraphics* nativeGraphics = NULL;
    GpPen* nativePen = NULL;

    if(g)
        nativeGraphics = g->nativeGraphics;
    if(pen)
        nativePen = pen->nativePen;

    SetStatus(DllCall("gdiplus\GdipIsOutlineVisiblePathPoint(nativePath,
                                                        x, y, nativePen, nativeGraphics,
                                                        &booln));
    return booln;
}

inline BOOL
GraphicsPath::IsOutlineVisible(
    IN INT x,
    IN INT y,
    IN const Pen* pen,
    IN const Graphics* g) const
{
    BOOL booln = FALSE;

    GpGraphics* nativeGraphics = NULL;
    GpPen* nativePen = NULL;

    if(g)
        nativeGraphics = g->nativeGraphics;
    if(pen)
        nativePen = pen->nativePen;

    SetStatus(DllCall("gdiplus\GdipIsOutlineVisiblePathPointI(nativePath,
                                                         x, y, nativePen, nativeGraphics,
                                                         &booln));
    return booln;
}

#if _MSC_VER >= 1200
#pragma warning(pop)
#endif

#endif /* WINAPI_FAMILY_PARTITION(WINAPI_PARTITION_DESKTOP) */
#pragma endregion

#endif





































/*
; Graphics Class - Current WIP

#SingleInstance Force
#Warn
test()
ExitApp

test()
{
    MsgBox, % GDIP.to_hex(GDIP.Color.LightSeaGreen)
    myCol := new GDIP.Color(GDIP.Color.LightSeaGreen)
    MsgBox, % "myCol.a: " myCol.a "`nmyCol.r: " myCol.r "`nmyCol.g: " myCol.g "`nmyCol.b: " myCol.b 
    MsgBox, % gdip.to_hex(myCol.MakeARGB(0xDE, 0xAD, 0xBE, 0xEF))
    Return
}

*Escape::ExitApp


Class GDIP
{
    ;-------------------------------------------------------------------------------------------------------------------.
    ; GdiplusColor.h                                                                                                    |
    ;___________________________________________________________________________________________________________________|
    
    ;-------------------------------------------------------------------------------------------------------------------.
    ; Color Class - Stores a 32 bit value tha represents Alpha, Red, Blue, and Green values.                            |
    ;-------------------------------------------------------------------------------------------------------------------|
    ; A Color object has Alpha (transparency), Red, Green, and Blue values. Type is ARGB                                |
    ; Properties:                                                                                                       |
    ; .Alpha            Transparency. 0-255                                                                             |
    ; .Red              Red value. 0-255                                                                                |
    ; .Green            Green value. 0-255                                                                              |
    ; .Blue             Blue value. 0-255                                                                               |
    ;                                                                                                                   |
    ; Constructors:                                                                                                     |
    ; Color()           Create solid black color object                                                                 |
    ; Color(ColorObj)   Create a color object using the values from the provided color object                           |
    ; Color(ARGB)       Create a color object using an ARGB (a 0xAARRGGBB value)                                        |
    ; Color(r, g, b)    Create a solid color object using the provided red, green and blue values                       |
    ; Color(a, r, g, b) Create a color object using the provided alpha, red, green and blue values                      |
    ;                                                                                                                   |
    ; Methods:                                                                                                          |
    ; .struct()         Builds struct and returns struct pointer.                                                       |
    ;                                                                                                                   |
    ; Remarks           Alpha, Red, Green, and Blue values less than 0 are set to 0 & greater than 255 are set to 255.  |
    ;                                                                                                                   |
    ; Enum: Names       List of 139 pre-defined colors. Use: this.name.Colorname                                        |
    ;___________________________________________________________________________________________________________________|
    Class Color
    {
        _type := "Color"
        ,A    := 0
        ,R    := 0
        ,G    := 0
        ,B    := 0
        
        ; Common color constants
        Static AliceBlue            = 0xFFF0F8FF             , LightSeaGreen        = 0xFF20B2AA
             , AntiqueWhite         = 0xFFFAEBD7             , LightSkyBlue         = 0xFF87CEFA
             , Aqua                 = 0xFF00FFFF             , LightSlateGray       = 0xFF778899
             , Aquamarine           = 0xFF7FFFD4             , LightSteelBlue       = 0xFFB0C4DE
             , Azure                = 0xFFF0FFFF             , LightYellow          = 0xFFFFFFE0
             , Beige                = 0xFFF5F5DC             , Lime                 = 0xFF00FF00
             , Bisque               = 0xFFFFE4C4             , LimeGreen            = 0xFF32CD32
             , Black                = 0xFF000000             , Linen                = 0xFFFAF0E6
             , BlanchedAlmond       = 0xFFFFEBCD             , Magenta              = 0xFFFF00FF
             , Blue                 = 0xFF0000FF             , Maroon               = 0xFF800000
             , BlueViolet           = 0xFF8A2BE2             , MediumAquamarine     = 0xFF66CDAA
             , Brown                = 0xFFA52A2A             , MediumBlue           = 0xFF0000CD
             , BurlyWood            = 0xFFDEB887             , MediumOrchid         = 0xFFBA55D3
             , CadetBlue            = 0xFF5F9EA0             , MediumPurple         = 0xFF9370DB
             , Chartreuse           = 0xFF7FFF00             , MediumSeaGreen       = 0xFF3CB371
             , Chocolate            = 0xFFD2691E             , MediumSlateBlue      = 0xFF7B68EE
             , Coral                = 0xFFFF7F50             , MediumSpringGreen    = 0xFF00FA9A
             , CornflowerBlue       = 0xFF6495ED             , MediumTurquoise      = 0xFF48D1CC
             , Cornsilk             = 0xFFFFF8DC             , MediumVioletRed      = 0xFFC71585
             , Crimson              = 0xFFDC143C             , MidnightBlue         = 0xFF191970
             , Cyan                 = 0xFF00FFFF             , MintCream            = 0xFFF5FFFA
             , DarkBlue             = 0xFF00008B             , MistyRose            = 0xFFFFE4E1
             , DarkCyan             = 0xFF008B8B             , Moccasin             = 0xFFFFE4B5
             , DarkGoldenrod        = 0xFFB8860B             , NavajoWhite          = 0xFFFFDEAD
             , DarkGray             = 0xFFA9A9A9             , Navy                 = 0xFF000080
        Static DarkGreen            = 0xFF006400             , OldLace              = 0xFFFDF5E6
             , DarkKhaki            = 0xFFBDB76B             , Olive                = 0xFF808000
             , DarkMagenta          = 0xFF8B008B             , OliveDrab            = 0xFF6B8E23
             , DarkOliveGreen       = 0xFF556B2F             , Orange               = 0xFFFFA500
             , DarkOrange           = 0xFFFF8C00             , OrangeRed            = 0xFFFF4500
             , DarkOrchid           = 0xFF9932CC             , Orchid               = 0xFFDA70D6
             , DarkRed              = 0xFF8B0000             , PaleGoldenrod        = 0xFFEEE8AA
             , DarkSalmon           = 0xFFE9967A             , PaleGreen            = 0xFF98FB98
             , DarkSeaGreen         = 0xFF8FBC8B             , PaleTurquoise        = 0xFFAFEEEE
             , DarkSlateBlue        = 0xFF483D8B             , PaleVioletRed        = 0xFFDB7093
             , DarkSlateGray        = 0xFF2F4F4F             , PapayaWhip           = 0xFFFFEFD5
             , DarkTurquoise        = 0xFF00CED1             , PeachPuff            = 0xFFFFDAB9
             , DarkViolet           = 0xFF9400D3             , Peru                 = 0xFFCD853F
             , DeepPink             = 0xFFFF1493             , Pink                 = 0xFFFFC0CB
             , DeepSkyBlue          = 0xFF00BFFF             , Plum                 = 0xFFDDA0DD
             , DimGray              = 0xFF696969             , PowderBlue           = 0xFFB0E0E6
             , DodgerBlue           = 0xFF1E90FF             , Purple               = 0xFF800080
             , Firebrick            = 0xFFB22222             , Red                  = 0xFFFF0000
             , FloralWhite          = 0xFFFFFAF0             , RosyBrown            = 0xFFBC8F8F
             , ForestGreen          = 0xFF228B22             , RoyalBlue            = 0xFF4169E1
             , Fuchsia              = 0xFFFF00FF             , SaddleBrown          = 0xFF8B4513
             , Gainsboro            = 0xFFDCDCDC             , Salmon               = 0xFFFA8072
             , GhostWhite           = 0xFFF8F8FF             , SandyBrown           = 0xFFF4A460
             , Gold                 = 0xFFFFD700             , SeaGreen             = 0xFF2E8B57
             , Goldenrod            = 0xFFDAA520             , SeaShell             = 0xFFFFF5EE
        Static Gray                 = 0xFF808080             , Sienna               = 0xFFA0522D
             , Green                = 0xFF008000             , Silver               = 0xFFC0C0C0
             , GreenYellow          = 0xFFADFF2F             , SkyBlue              = 0xFF87CEEB
             , Honeydew             = 0xFFF0FFF0             , SlateBlue            = 0xFF6A5ACD
             , HotPink              = 0xFFFF69B4             , SlateGray            = 0xFF708090
             , IndianRed            = 0xFFCD5C5C             , Snow                 = 0xFFFFFAFA
             , Indigo               = 0xFF4B0082             , SpringGreen          = 0xFF00FF7F
             , Ivory                = 0xFFFFFFF0             , SteelBlue            = 0xFF4682B4
             , Khaki                = 0xFFF0E68C             , Tan                  = 0xFFD2B48C
             , Lavender             = 0xFFE6E6FA             , Teal                 = 0xFF008080
             , LavenderBlush        = 0xFFFFF0F5             , Thistle              = 0xFFD8BFD8
             , LawnGreen            = 0xFF7CFC00             , Tomato               = 0xFFFF6347
             , LemonChiffon         = 0xFFFFFACD             , Transparent          = 0x00FFFFFF
             , LightBlue            = 0xFFADD8E6             , Turquoise            = 0xFF40E0D0
             , LightCoral           = 0xFFF08080             , Violet               = 0xFFEE82EE
             , LightCyan            = 0xFFE0FFFF             , Wheat                = 0xFFF5DEB3
             , LightGoldenrodYellow = 0xFFFAFAD2             , White                = 0xFFFFFFFF
             , LightGray            = 0xFFD3D3D3             , WhiteSmoke           = 0xFFF5F5F5
             , LightGreen           = 0xFF90EE90             , Yellow               = 0xFFFFFF00
             , LightPink            = 0xFFFFB6C1             , YellowGreen          = 0xFF9ACD32
             , LightSalmon          = 0xFFFFA07A
        
        ; Color()
        ; Color(ColorObject)
        ; Color(ARGB)
        ; Color(red, blue, green)
        ; Color(alpha, red, blue, green)
        __New(a="", r="", g="", b="")
        {
            this.SetCapacity("_ARGB", 4)
            ,this.structP := this.GetAddress("_ARGB")
            ,(a._type == "Color" && r = "" && g = "" && b = "") ; Color object
                ? this._set_color(a.a, a.r, a.g, a.b)
            : (this.is_num(a) && r="" && g="" && b="")          ; ARGB (0xAARRGGBB)
                ? this._set_color(255, 0, 0, 0)
            : (a="" && r="" && g="" && b="")                    ; Empty
                ? this._set_color(255, 0, 0, 0)
            : (g = "")                                          ; RBG values
                ? this._set_color(255, a, r, g)
                : this._set_color(a, r, g, b)                   ; Default to ARGB
        }
        
        ; Remark: Values below 0 are set to 0 and values above 255 are set to 255
        _set_color(a, r, g, b)
        {
             this.A := (a < 0) ? 0 : (a > 255) ? 255 : a
            ,this.R := (r < 0) ? 0 : (r > 255) ? 255 : r
            ,this.G := (g < 0) ? 0 : (g > 255) ? 255 : g
            ,this.B := (b < 0) ? 0 : (b > 255) ? 255 : b
        }
        
        show()
        {
            ptr := this.Struct()
            MsgBox, % this._type " object:"
                . "`nthis.A: "       this.A
                . "`nthis.R: "       this.R
                . "`nthis.B: "       this.B
                . "`nthis.G: "       this.G
                . "`nthis.structP: " this.structP
                . "`nNumGet A: "     NumGet(ptr, 3, "UChar")
                . "`nNumGet R: "     NumGet(ptr, 2, "UChar")
                . "`nNumGet G: "     NumGet(ptr, 1, "UChar")
                . "`nNumGet B: "     NumGet(ptr, 0, "UChar")
        }
        
        Struct()
        {
             NumPut(this.GetValue(), this.structP+0, 0, "Int")
            Return this.structP+0
        }
        
        GetAlpha() {
            Return this.A
        }
        
        GetRed() {
            Return this.R
        }
        
        GetGreen() {
            Return this.G
        }
        
        GetBlue() {
            Return this.B
        }
        
        GetValue() {
            Return ( (this.A << this.A_Shift)
                   + (this.R << this.R_Shift)
                   + (this.G << this.G_Shift)
                   +  this.B )
        }
        
        SetValue(argb) {
             this.A := (argb & this.A_Mask) >> this.A_Shift
            ,this.R := (argb & this.R_Mask) >> this.R_Shift
            ,this.G := (argb & this.G_Mask) >> this.G_Shift
            ,this.B := (argb & this.B_Mask)
        }
        
        ; Converts four 8-bit values (0-255) into a 32-bit hex value
        MakeARGB(a, r, g, b)
        {
            Return ( (a << this.A_Shift)
                   + (r << this.R_Shift)
                   + (g << this.G_Shift)
                   +  b )
        }        
        
        
        ; ; I don't think these two will be needed, so they're staying commented out for now
        ; ; Set ARGB value using a COLORREF
        ; SetFromCOLORREF()
        ; {
        ;     Return
        ; }
        ; 
        ; ; Converts ARGB value to a COLORREF
        ; ToCOLORREF(ARGB)
        ; {
        ;     Return
        ; }
        
        ; ARGB masks and bitshifts
        Static A_Mask  := 0xFF000000
             , R_Mask  := 0x00FF0000
             , G_Mask  := 0x0000FF00
             , B_Mask  := 0x000000FF
             , A_Shift := 24
             , R_Shift := 16
             , G_Shift := 8
             , B_Shift := 0
        
    }
    
    get_min(n1, n2) {
        Return (n1 < n2) ? n1 : n2
    }
    
    get_max(n1, n2) {
        Return (n1 > n2) ? n1 : n2
    }
    
    to_hex(num) {
        Return Format("{:#x}", num)
    }
}
    
/*

    ;   GdiplusPen.h

    ;-------------------------------------------------------------------------------------------------------------------.
    ; Pen Class -                                                                                                       |
    ;-------------------------------------------------------------------------------------------------------------------|
    ; A Color object has Alpha (transparency), Red, Green, and Blue values. Type is ARGB                                |
    ; Properties:                                                                                                       |
    ; .Alpha            Transparency. 0-255                                                                             |
    ; .Red              Red value. 0-255                                                                                |
    ; .Blue             Blue value. 0-255                                                                               |
    ; .Green            Green value. 0-255                                                                              |
    ;                                                                                                                   |
    ; Constructors:                                                                                                     |
    ; Color()           Defaults to solid black. A=255, R=0, B=0, G=0                                                   |
    ; Color(ARGB)       Copy ARGB object values. A=ARGB.A, R=ARGB.R, B=ARGB.B, G=ARGB.G                                 |
    ; Color(r, b, g)    Red, blue, green values. Alpha is assumed opaque. A=255, R=r, B=b, G=g                          |
    ; Color(a, r, b, g) Set values A=a, R=r, B=b, G=g                                                                   |
    ;                                                                                                                   |
    ; Methods:                                                                                                          |
    ; .struct()         Builds struct and returns struct pointer.                                                       |
    ;                                                                                                                   |
    ; Enum: Names       List of 139 pre-defined colors. Use: this.name.Colorname                                        |
    ;___________________________________________________________________________________________________________________|
    class Pen : public GdiplusBase
    {
        _type      := "Pen"
        nativePen  := ""
        lastResult := ""
        
        ; Pen(IN const Brush* brush, IN REAL width = 1.0f)      ; From brush
        ; Pen(IN const Color& color, IN REAL width = 1.0f)      ; From color/argb
        __New(colIn, width)
        {
            unit := GDIP.enum("Unit", "UnitWorld")
            this.SetCapacity("nativePen", A_PtrSize)
            (colIn.type == "Brush")
                ? estat := DllCall("gdiplus\GdipCreatePen1"
                                        ,   ,color.GetValue()
                                        ,   ,width
                                        ,   ,unit
                                        ,   ,&nativePen)
            : (colIn.type == "Color")
            
            this.lastResult := estat
        }
        
        Pen(IN const Color& color, 
            IN REAL width = 1.0f)
        {
            Unit unit = UnitWorld;
            nativePen = NULL;
            lastResult = DllCall("gdiplus\GdipCreatePen1(color.GetValue(),
                                        width, unit, &nativePen);
        }

        Pen(IN const Brush* brush, 
            IN REAL width = 1.0f)
        {
            Unit unit = UnitWorld;
            nativePen = NULL;
            lastResult = DllCall("gdiplus\GdipCreatePen2(brush->nativeBrush,
                                        width, unit, &nativePen);
        }

        ;~Pen()
        __Delete()
        {
            DllCall("gdiplus\GdipDeletePen(nativePen);
        }

        Pen* Clone() const
        {
            GpPen *clonePen = NULL;

            lastResult = DllCall("gdiplus\GdipClonePen(nativePen, &clonePen);
       
            return new Pen(clonePen, lastResult);
        }

        Status SetWidth(IN REAL width)
        {
            return SetStatus(DllCall("gdiplus\GdipSetPenWidth(nativePen, width));
        }

        REAL GetWidth() const
        {
            REAL width;

            SetStatus(DllCall("gdiplus\GdipGetPenWidth(nativePen, &width));
            
            return width;
        }
        
        ; Set/get line caps: start, end, and dash

        ; Line cap and join APIs by using LineCap and LineJoin enums.

        Status SetLineCap(IN LineCap startCap, 
                          IN LineCap endCap, 
                          IN DashCap dashCap)
        {
            return SetStatus(DllCall("gdiplus\GdipSetPenLineCap197819(nativePen, 
                                       startCap, endCap, dashCap));
        }

        Status SetStartCap(IN LineCap startCap)
        {
            return SetStatus(DllCall("gdiplus\GdipSetPenStartCap(nativePen, startCap));
        }

        Status SetEndCap(IN LineCap endCap)
        {
            return SetStatus(DllCall("gdiplus\GdipSetPenEndCap(nativePen, endCap));
        }

        Status SetDashCap(IN DashCap dashCap)
        {
            return SetStatus(DllCall("gdiplus\GdipSetPenDashCap197819(nativePen,
                                       dashCap));
        }

        LineCap GetStartCap() const
        {
            LineCap startCap;

            SetStatus(DllCall("gdiplus\GdipGetPenStartCap(nativePen, &startCap));
            
            return startCap;
        }

        LineCap GetEndCap() const
        {
            LineCap endCap;

            SetStatus(DllCall("gdiplus\GdipGetPenEndCap(nativePen, &endCap));

            return endCap;
        }

        DashCap GetDashCap() const
        {
            DashCap dashCap;

            SetStatus(DllCall("gdiplus\GdipGetPenDashCap197819(nativePen,
                                &dashCap));

            return dashCap;
        }

        Status SetLineJoin(IN LineJoin lineJoin)
        {
            return SetStatus(DllCall("gdiplus\GdipSetPenLineJoin(nativePen, lineJoin));
        }

        LineJoin GetLineJoin() const
        {
            LineJoin lineJoin;
            
            SetStatus(DllCall("gdiplus\GdipGetPenLineJoin(nativePen, &lineJoin));
            
            return lineJoin;
        }

        Status SetCustomStartCap(IN const CustomLineCap* customCap)
        {
            GpCustomLineCap* nativeCap = NULL;
            if(customCap)
                nativeCap = customCap->nativeCap;

            return SetStatus(DllCall("gdiplus\GdipSetPenCustomStartCap(nativePen, 
                                                                  nativeCap));
        }

        Status GetCustomStartCap(OUT CustomLineCap* customCap) const
        {
            if(!customCap)
                return SetStatus(InvalidParameter);

            return SetStatus(DllCall("gdiplus\GdipGetPenCustomStartCap(nativePen, 
                                                        &(customCap->nativeCap)));
        }

        Status SetCustomEndCap(IN const CustomLineCap* customCap)
        {
            GpCustomLineCap* nativeCap = NULL;
            if(customCap)
                nativeCap = customCap->nativeCap;

            return SetStatus(DllCall("gdiplus\GdipSetPenCustomEndCap(nativePen, 
                                                                nativeCap));
        }

        Status GetCustomEndCap(OUT CustomLineCap* customCap) const
        {
            if(!customCap)
                return SetStatus(InvalidParameter);

            return SetStatus(DllCall("gdiplus\GdipGetPenCustomEndCap(nativePen, 
                                                        &(customCap->nativeCap)));
        }

        Status SetMiterLimit(IN REAL miterLimit)
        {
            return SetStatus(DllCall("gdiplus\GdipSetPenMiterLimit(nativePen, 
                                                        miterLimit));
        }

        REAL GetMiterLimit() const
        {
            REAL miterLimit;

            SetStatus(DllCall("gdiplus\GdipGetPenMiterLimit(nativePen, &miterLimit));

            return miterLimit;
        }

        Status SetAlignment(IN PenAlignment penAlignment)
        {
            return SetStatus(DllCall("gdiplus\GdipSetPenMode(nativePen, penAlignment));
        }

        PenAlignment GetAlignment() const
        {
            PenAlignment penAlignment;
            
            SetStatus(DllCall("gdiplus\GdipGetPenMode(nativePen, &penAlignment));
            
            return penAlignment;
        }
        
        Status SetTransform(IN const Matrix* matrix)
        {
            return SetStatus(DllCall("gdiplus\GdipSetPenTransform(nativePen, 
                                                           matrix->nativeMatrix));
        }

        Status GetTransform(OUT Matrix* matrix) const
        {
            return SetStatus(DllCall("gdiplus\GdipGetPenTransform(nativePen, 
                                                             matrix->nativeMatrix));
        }

        Status ResetTransform()
        {
            return SetStatus(DllCall("gdiplus\GdipResetPenTransform(nativePen));
        }

        Status MultiplyTransform(IN const Matrix* matrix,
                                 IN MatrixOrder order = MatrixOrderPrepend)
        {
            return SetStatus(DllCall("gdiplus\GdipMultiplyPenTransform(nativePen,
                                                             matrix->nativeMatrix,
                                                             order));
        }

        Status TranslateTransform(IN REAL dx, 
                                  IN REAL dy,
                                  IN MatrixOrder order = MatrixOrderPrepend)
        {
            return SetStatus(DllCall("gdiplus\GdipTranslatePenTransform(nativePen,
                                                                   dx, 
                                                                   dy, 
                                                                   order));
        }

        Status ScaleTransform(IN REAL sx, 
                              IN REAL sy,
                              IN MatrixOrder order = MatrixOrderPrepend)
        {
            return SetStatus(DllCall("gdiplus\GdipScalePenTransform(nativePen,
                                                               sx, 
                                                               sy, 
                                                               order));
        }

        Status RotateTransform(IN REAL angle, 
                               IN MatrixOrder order = MatrixOrderPrepend)
        {
            return SetStatus(DllCall("gdiplus\GdipRotatePenTransform(nativePen,
                                                                angle, 
                                                                order));
        }

        PenType GetPenType() const
        {
           PenType type;
           SetStatus(DllCall("gdiplus\GdipGetPenFillType(nativePen, &type));

           return type;
        }

        Status SetColor(IN const Color& color)
        {
            return SetStatus(DllCall("gdiplus\GdipSetPenColor(nativePen,
                                                         color.GetValue()));
        }

        Status SetBrush(IN const Brush* brush)
        {
            return SetStatus(DllCall("gdiplus\GdipSetPenBrushFill(nativePen, 
                                           brush->nativeBrush));
        }

        Status GetColor(OUT Color* color) const
        {
            if (color == NULL) 
            {
                return SetStatus(InvalidParameter);
            }
            
            PenType type = GetPenType();

            if (type != PenTypeSolidColor) 
            {
                return WrongState;
            }
            
            ARGB argb;
            
            SetStatus(DllCall("gdiplus\GdipGetPenColor(nativePen,
                                                  &argb));
            if (lastResult == Ok)
            {
                color->SetValue(argb);
            }
            
            return lastResult;
        }

        Brush* GetBrush() const
        {
           PenType type = GetPenType();

           Brush* brush = NULL;

           switch(type)
           {
           case PenTypeSolidColor:
               brush = new SolidBrush();
               break;

           case PenTypeHatchFill:
               brush = new HatchBrush();
               break;

           case PenTypeTextureFill:
               brush = new TextureBrush();
               break;

           case PenTypePathGradient:
               brush = new Brush();
               break;

           case PenTypeLinearGradient:
               brush = new LinearGradientBrush();
               break;

           default:
               break;
           }

           if(brush)
           {
               GpBrush* nativeBrush;

               SetStatus(DllCall("gdiplus\GdipGetPenBrushFill(nativePen, 
                                                         &nativeBrush));
               brush->SetNativeBrush(nativeBrush);
           }

           return brush;
        }

        DashStyle GetDashStyle() const
        {
            DashStyle dashStyle;

            SetStatus(DllCall("gdiplus\GdipGetPenDashStyle(nativePen, &dashStyle));

            return dashStyle;
        }

        Status SetDashStyle(IN DashStyle dashStyle)
        {
            return SetStatus(DllCall("gdiplus\GdipSetPenDashStyle(nativePen, 
                                                             dashStyle));
        }

        REAL GetDashOffset() const
        {
            REAL dashOffset;

            SetStatus(DllCall("gdiplus\GdipGetPenDashOffset(nativePen, &dashOffset));

            return dashOffset;
        }

        Status SetDashOffset(IN REAL dashOffset)
        {
            return SetStatus(DllCall("gdiplus\GdipSetPenDashOffset(nativePen, 
                                                              dashOffset));
        }
        
        Status SetDashPattern(IN const REAL* dashArray, IN INT count)
        {
            return SetStatus(DllCall("gdiplus\GdipSetPenDashArray(nativePen,
                                                             dashArray, 
                                                             count));
        }
        
        INT GetDashPatternCount() const
        {
            INT count = 0;
            
            SetStatus(DllCall("gdiplus\GdipGetPenDashCount(nativePen, &count));
            
            return count;
        }

        Status GetDashPattern(OUT REAL* dashArray, 
                              IN INT count) const
        {
            if (dashArray == NULL || count <= 0)
                return SetStatus(InvalidParameter); 
            
            return SetStatus(DllCall("gdiplus\GdipGetPenDashArray(nativePen, 
                                                             dashArray, 
                                                             count));
        }

        Status SetCompoundArray(IN const REAL* compoundArray,
                                IN INT count)
        {
            return SetStatus(DllCall("gdiplus\GdipSetPenCompoundArray(nativePen, 
                                                                 compoundArray,
                                                                 count));
        }

        INT GetCompoundArrayCount() const
        {
            INT count = 0;
            
            SetStatus(DllCall("gdiplus\GdipGetPenCompoundCount(nativePen, &count));
            
            return count;
        }

        Status GetCompoundArray(OUT REAL* compoundArray, 
                                IN INT count) const
        {
            if (compoundArray == NULL || count <= 0)
                return SetStatus(InvalidParameter); 
            
            return SetStatus(DllCall("gdiplus\GdipGetPenCompoundArray(nativePen, 
                                                                 compoundArray, 
                                                                 count));
        }

        Status GetLastStatus() const
        {
            Status lastStatus = lastResult;
            lastResult = Ok;

            return lastStatus;
        }

    private:
        Pen(const Pen &);
        Pen& operator=(const Pen &);

    protected:
        Pen(GpPen* nativePen, Status status)
        {
            lastResult = status;
            SetNativePen(nativePen);
        }

        VOID SetNativePen(GpPen* nativePen)
        {
            this->nativePen = nativePen;
        }
        
        Status SetStatus(Status status) const
        {
            if (status != Ok)
                return (lastResult = status);
            else 
                return status;
        }

    };


}






































; Effects Class - Current WIP


;   Gdiplus effect objects.

;-----------------------------------------------------------------------------
; GDI+ effect GUIDs
;-----------------------------------------------------------------------------
Class Effect
{
    ;~ GDIP.Blur.BlurEffectGuid                                     := new GDIP.GUID("{633C80A4-1843-482b-9EF2-BE2834C5FDD4}")
    ;~ GDIP.BrightnessContrast.BrightnessContrastEffectGuid         := new GDIP.GUID("{D3A1DBE1-8EC4-4C17-9F4C-EA97AD1C343D}")
    ;~ GDIP.ColorBalance.ColorBalanceEffectGuid                     := new GDIP.GUID("{537E597D-251E-48DA-9664-29CA496B70F8}")
    ;~ GDIP.ColorCurve.ColorCurveEffectGuid                         := new GDIP.GUID("{DD6A0022-58E4-4A67-9D9B-D48EB881A53D}")
    ;~ GDIP.ColorLookupTable.ColorLookupTableEffectGuid             := new GDIP.GUID("{A7CE72A9-0F7F-40D7-B3CC-D0C02D5C3212}")
    ;~ GDIP.ColorMatrix.ColorMatrixEffectGuid                       := new GDIP.GUID("{718F2615-7933-40E3-A511-5F68FE14DD74}")
    ;~ GDIP.HueSaturationLightness.HueSaturationLightnessEffectGuid := new GDIP.GUID("{8B2DD6C3-EB07-4D87-A5F0-7108E26A9C5F}")
    ;~ GDIP.Levels.LevelsEffectGuid                                 := new GDIP.GUID("{99C354EC-2A31-4F3A-8C34-17A803B33A25}")
    ;~ GDIP.RedEyeCorrection.RedEyeCorrectionEffectGuid             := new GDIP.GUID("{74D29D05-69A4-4266-9549-3CC52836B632}")
    ;~ GDIP.Sharpen.SharpenEffectGuid                               := new GDIP.GUID("{63CBF3EE-C526-402C-8F71-62C540BF5142}")
    ;~ GDIP.Tint.TintEffectGuid                                     := new GDIP.GUID("{1077AF00-2848-4441-9489-44AD4C2D7A2C}")
    _generate_guids()
    {
        GDIP.Blur.BlurEffectGuid       := new GDIP.GUID("{633C80A4-1843-482b-9EF2-BE2834C5FDD4}")
        GDIP.BrightnessContrast        := new GDIP.GUID("{D3A1DBE1-8EC4-4C17-9F4C-EA97AD1C343D}")
        GDIP.ColorBalance              := new GDIP.GUID("{537E597D-251E-48DA-9664-29CA496B70F8}")
        GDIP.ColorCurve                := new GDIP.GUID("{DD6A0022-58E4-4A67-9D9B-D48EB881A53D}")
        GDIP.ColorLookupTable          := new GDIP.GUID("{A7CE72A9-0F7F-40D7-B3CC-D0C02D5C3212}")
        GDIP.ColorMatrix               := new GDIP.GUID("{718F2615-7933-40E3-A511-5F68FE14DD74}")
        GDIP.HueSaturationLightness    := new GDIP.GUID("{8B2DD6C3-EB07-4D87-A5F0-7108E26A9C5F}")
        GDIP.Levels                    := new GDIP.GUID("{99C354EC-2A31-4F3A-8C34-17A803B33A25}")
        GDIP.RedEyeCorrection          := new GDIP.GUID("{74D29D05-69A4-4266-9549-3CC52836B632}")
        GDIP.Sharpen.SharpenEffectGuid := new GDIP.GUID("{63CBF3EE-C526-402C-8F71-62C540BF5142}")
        GDIP.Tint.TintEffectGuid       := new GDIP.GUID("{1077AF00-2848-4441-9489-44AD4C2D7A2C}")
    }
    
    ; ## CONSTRUCTOR ##
    ; effect()
    __New()
    {
        ; ?
        Return
    }
    
    ; ## METHODS ##
    SetParameters(const void *params, const UINT size)
    {
        return GdipSetEffectParameters(nativeEffect, params, size);
    }

    GetParameters(UINT *size, void *params)
    {
        return GdipGetEffectParameters(nativeEffect, size, params);
    }

    ; protected data members.
    
    CGpEffect   *nativeEffect;
    INT         auxDataSize;
    VOID        *auxData;
    BOOL        useAuxData;
    
public:

    Effect()
    {
        auxDataSize  = 0;
        auxData      = NULL;
        nativeEffect = NULL;
        useAuxData   = FALSE;
    }
    
    ; virtual ~Effect()
    __Delete()
    {
        DllExports::GdipFree(auxData)   ; pvData is allocated by ApplyEffect. Return the pointer so that it can be freed by the appropriate memory manager.
        GdipDeleteEffect(nativeEffect)  ; Release the native Effect.
    }
    
    UseAuxData(const BOOL useAuxDataFlag)
    {
        useAuxData = useAuxDataFlag;
    }

    GetParameterSize(UINT *size)
    {
        return GdipGetEffectParameterSize(nativeEffect, size);
    }
}



; Blur class
; Radius        The radius of the blur. Must be 0-255. Greater radius = more blur.
; expandEdge    If true, expands bitmap by an emount equal to the blur radius to accommodate soft edges.
Class Blur Extends Effect
{
    _type      := "Blur"
    radius     := 0
    expandEdge := 0
    ;~ struct BlurParams
    ;~ {
        ;~ float radius;
        ;~ BOOL expandEdge;
    ;~ }

    
    ; ## CONSTRUCTOR ##
    __New(radius, expandEdge)
    { 
        this.SetCapacity("_struct", 8)
        this._ptr := this.GetAddress("_struct")
        (radius <= 255 && radius >= 0) && (expandEdge = 0 || expandEdge = 1)
            ? (this._radius := radius, this._expandEdge := expandEdge)
            : this.error_log(A_ThisFunc, "", "", {radius:radius, expandEdge:expandEdge})
        GdipCreateEffect(BlurEffectGuid, &nativeEffect)
    }
    
    ; type      Pass expected structure type
    ; Return    Pointer to struct
    Struct()
    {
         NumPut(, this._ptr+0, 0, "Float")
        ,NumPut(, this._ptr+0, 4, "Bool" )
        Return structP+0
    }
    
    ; ## METHODS ##
    Status SetParameters(const BlurParams *parameters)
    {
        UINT size = sizeof(BlurParams);
        return Effect::SetParameters(parameters, size);
    }

    Status GetParameters(UINT *size, BlurParams *parameters)
    {
        return Effect::GetParameters(size, (VOID*)parameters);
    }
}

; Sharpen

Class Sharpen Extends Effect
{
    ;~ struct SharpenParams
    ;~ {
        ;~ float radius;
        ;~ float amount;
    ;~ }
public:
    
    Sharpen()
    { 
        GdipCreateEffect(SharpenEffectGuid, &nativeEffect);
    }

    Status SetParameters(const SharpenParams *parameters)
    {
        UINT size = sizeof(SharpenParams);
        return Effect::SetParameters(parameters, size);
    }

    Status GetParameters(UINT *size, SharpenParams *parameters)
    {
        return Effect::GetParameters(size, (VOID*)parameters);
    }
}

; RedEye Correction

Class RedEyeCorrection Extends Effect
{
    ;~ struct RedEyeCorrectionParams
    ;~ {
        ;~ UINT numberOfAreas;
        ;~ RECT *areas;
    ;~ }

public:
    
    ; constructors cannot return an error code.
    
    RedEyeCorrection()
    { 
        GdipCreateEffect(RedEyeCorrectionEffectGuid, &nativeEffect);
    }
    
    Status SetParameters(const RedEyeCorrectionParams *parameters)
    {
        Status status = InvalidParameter;

        if (parameters)
        {
            RedEyeCorrectionParams *inputParam =
                (RedEyeCorrectionParams*)parameters;

            UINT size = sizeof(RedEyeCorrectionParams) +
                inputParam->numberOfAreas * sizeof(RECT);

            status = Effect::SetParameters(parameters, size);
        }

        return status;
    }    
    
    Status GetParameters(UINT *size, RedEyeCorrectionParams *parameters)
    {
        return Effect::GetParameters(size,(VOID*)parameters);
    }
}

; Brightness/Contrast
Class BrightnessContrast Extends Effect
{
    ;~ struct BrightnessContrastParams
    ;~ {
        ;~ INT brightnessLevel;
        ;~ INT contrastLevel;
    ;~ }
public:
    BrightnessContrast()
    {
        GdipCreateEffect(BrightnessContrastEffectGuid, &nativeEffect);
    }

    Status SetParameters(const BrightnessContrastParams *parameters)
    {
        UINT size = sizeof(BrightnessContrastParams);
        return Effect::SetParameters((VOID*)parameters, size);
    }
    
    Status GetParameters(UINT *size, BrightnessContrastParams *parameters)
    {
        return Effect::GetParameters(size, (VOID*)parameters);
    }
}

; Hue/Saturation/Lightness

Class HueSaturationLightness Extends Effect
{
    ;~ struct HueSaturationLightnessParams
    ;~ {
        ;~ INT hueLevel;
        ;~ INT saturationLevel;
        ;~ INT lightnessLevel;
    ;~ }
public:
    HueSaturationLightness()
    {
        GdipCreateEffect(HueSaturationLightnessEffectGuid, &nativeEffect);
    }

    Status SetParameters(const HueSaturationLightnessParams *parameters)
    {
        UINT size = sizeof(HueSaturationLightnessParams);
        return Effect::SetParameters((VOID*)parameters, size);
    }

    Status GetParameters(UINT *size, HueSaturationLightnessParams *parameters)
    {
        return Effect::GetParameters(size, (VOID*)parameters);
    }
}

; Highlight/Midtone/Shadow curves

Class Levels Extends Effect
{
    ;~ struct LevelsParams
    ;~ {
        ;~ INT highlight;
        ;~ INT midtone;
        ;~ INT shadow;
    ;~ }
public:
    Levels()
    {
        GdipCreateEffect(LevelsEffectGuid, &nativeEffect);
    }
    
    Status SetParameters(const LevelsParams *parameters)
    {
        UINT size = sizeof(LevelsParams);
        return Effect::SetParameters((VOID*)parameters, size);
    }

    Status GetParameters(UINT *size, LevelsParams *parameters)
    {
        return Effect::GetParameters(size, (VOID*)parameters);
    }
}

; Tint

Class Tint Extends Effect
{
    ;~ struct TintParams
    ;~ {
        ;~ INT hue;
        ;~ INT amount;
    ;~ }

public:
    Tint()
    {
        GdipCreateEffect(TintEffectGuid, &nativeEffect);
    }
    
    Status SetParameters(const TintParams *parameters)
    {
        UINT size = sizeof(TintParams);
        return Effect::SetParameters((VOID*)parameters, size);
    }

    Status GetParameters(UINT *size, TintParams *parameters)
    {
        return Effect::GetParameters(size, (VOID*)parameters);
    }
}

; ColorBalance

Class ColorBalance Extends Effect
{
    ;~ struct ColorBalanceParams
    ;~ {
        ;~ INT cyanRed;
        ;~ INT magentaGreen;
        ;~ INT yellowBlue;
    ;~ }
public:
    ColorBalance()
    {
        GdipCreateEffect(ColorBalanceEffectGuid, &nativeEffect);
    }
    
    Status SetParameters(const ColorBalanceParams *parameters)
    {
        UINT size = sizeof(ColorBalanceParams);
        return Effect::SetParameters((VOID*)parameters, size);
    }

    Status GetParameters(UINT *size, ColorBalanceParams *parameters)
    {
        return Effect::GetParameters(size, (VOID*)parameters);
    }
}

; ColorMatrix

Class ColorMatrixEffect Extends Effect
{
public:
    
    ; constructors cannot return an error code.
    
    ColorMatrixEffect()
    { 
        GdipCreateEffect(ColorMatrixEffectGuid, &nativeEffect);
    }
    
    Status SetParameters(const ColorMatrix *matrix)
    {
        UINT size = sizeof(ColorMatrix);
        return Effect::SetParameters(matrix, size);
    }

    Status GetParameters(UINT *size, ColorMatrix *matrix)
    {
        return Effect::GetParameters(size, (VOID*)matrix);
    }
}


; ColorLUT

Class ColorLUT Extends Effect
{
    ;~ struct ColorLUTParams
    ;~ {
        ;~ ; look up tables for each color channel.
        
        ;~ ColorChannelLUT lutB;
        ;~ ColorChannelLUT lutG;
        ;~ ColorChannelLUT lutR;
        ;~ ColorChannelLUT lutA;
    ;~ }
    public:
    
    ; constructors cannot return an error code.
    
    ColorLUT()
    { 
        GdipCreateEffect(ColorLUTEffectGuid, &nativeEffect);
    }

    Status SetParameters(const ColorLUTParams *lut)
    {
        UINT size = sizeof(ColorLUTParams);
        return Effect::SetParameters(lut, size);
    }

    Status GetParameters(UINT *size, ColorLUTParams *lut)
    {
        return Effect::GetParameters(size, (VOID*)lut);
    }
}

; Color Curve

Class ColorCurve Extends Effect
{
    ;~ struct ColorCurveParams
    ;~ {
        ;~ CurveAdjustments adjustment;
        ;~ CurveChannel channel;
        ;~ INT adjustValue;
    ;~ }
public:
    ColorCurve()
    {
        GdipCreateEffect(ColorCurveEffectGuid, &nativeEffect);
    }

    Status SetParameters(const ColorCurveParams *parameters)
    {
        UINT size = sizeof(ColorCurveParams);
        return Effect::SetParameters((VOID*)parameters, size);
    }

    Status GetParameters(UINT *size, ColorCurveParams *parameters)
    {
        return Effect::GetParameters(size, (VOID*)parameters);
    }
}











































; Temporary workspace for constructing and testing GDIPlus classes
; DON'T FORGET TO IMPORT BACK INTO MAIN FILE, YOU SPED!!!
#SingleInstance Force
#Warn
test()
ExitApp

test()
{
    
    Return
}

*Escape::ExitApp

Class GDIP
{
    ;-------------------------------------------------------------------------------------------------------------------.
    ; GdiplusColor.h                                                                                                    |
    ;___________________________________________________________________________________________________________________|
    
    ;-------------------------------------------------------------------------------------------------------------------.
    ; Color Class - Stores a 32 bit value tha represents Alpha, Red, Blue, and Green values.                            |
    ;-------------------------------------------------------------------------------------------------------------------|
    ; A Color object has Alpha (transparency), Red, Green, and Blue values. Type is ARGB                                |
    ; Properties:                                                                                                       |
    ; .A                Transparency. 0-255                                                                             |
    ; .R                Red value. 0-255                                                                                |
    ; .G                Green value. 0-255                                                                              |
    ; .B                Blue value. 0-255                                                                               |
    ; .Struct           Stores the pointer for the struct                                                               |
    ;                                                                                                                   |
    ; Constructors:                                                                                                     |
    ; Color()           Create solid black color object                                                                 |
    ; Color(ColorObj)   Create a color object using the values from the provided color object                           |
    ; Color(ARGB)       Create a color object using an ARGB (a 0xAARRGGBB value)                                        |
    ; Color(r, g, b)    Create a solid color object using the provided red, green and blue values                       |
    ; Color(a, r, g, b) Create a color object using the provided alpha, red, green and blue values                      |
    ;                                                                                                                   |
    ; Methods:                                                                                                          |
    ; .GetAlpha(hex)    Returns Alpha value.                                                                            |
    ; .GetRed(hex)      Returns Red value.                                                                              |
    ; .GetGreen(hex)    Returns Green value.                                                                            |
    ; .GetBlue(hex)     Returns Blue value.                                                                             |
    ; .GetValue()       Returns an ARBG value.                                                                          |
    ; .SetValue(argb)   Sets color's ARGB values using an ARGB.                                                         |
    ; .MakeARGB(a ,r    Creates an ARGB value using an alpha, red, green, and blue value.                               |
    ;          ,g ,b)                                                                                                   |
    ;                                                                                                                   |
    ; Remarks           An ARGB is a hex number containing 4 values. Alpha, Red, Green, and Blue: 0xAARRGGBB            |
    ;                   Alpha, Red, Green, and Blue values less than 0 are set to 0 & greater than 255 are set to 255.  |
    ;                   Gray and grey are both supported for colors. Ex: DarkGray and DarkGrey both return 0xFFA9A9A9   |
    ;___________________________________________________________________________________________________________________|
    Class Color
    {
        _type := "Color"
        ,A    := ""
        ,R    := ""
        ,G    := ""
        ,B    := ""
        _ptr[]
        {
            Get{
                Return value+0
            }
        }
        struct[]
        {
            Get {
                 NumPut(this.B, this._ptr, 0, "UChar")
                ,NumPut(this.G, this._ptr, 1, "UChar")
                ,NumPut(this.R, this._ptr, 2, "UChar")
                ,NumPut(this.A, this._ptr, 3, "UChar")
                Return this._ptr
            }
            
            Set {
                Return
            }
        }
        
        ; ############################
        ; ## COMMON COLOR CONSTANTS ##
        ; ############################
            ; Special
        Static Transparent      = 0x00FFFFFF
        
            ; Black and gray/grey               ; White
        Static Black            = 0xFF000000    , AliceBlue            = 0xFFF0F8FF
            , DarkGray          = 0xFFA9A9A9    , AntiqueWhite         = 0xFFFAEBD7
            , DarkGrey          = 0xFFA9A9A9    , Azure                = 0xFFF0FFFF
            , DarkSlateGray     = 0xFF2F4F4F    , Beige                = 0xFFF5F5DC
            , DarkSlateGrey     = 0xFF2F4F4F    , FloralWhite          = 0xFFFFFAF0
            , DimGray           = 0xFF696969    , GhostWhite           = 0xFFF8F8FF
            , DimGrey           = 0xFF696969    , Honeydew             = 0xFFF0FFF0
            , Gainsboro         = 0xFFDCDCDC    , Ivory                = 0xFFFFFFF0
            , Gray              = 0xFF808080    , LavenderBlush        = 0xFFFFF0F5
            , Grey              = 0xFF808080    , Linen                = 0xFFFAF0E6
            , LightGray         = 0xFFD3D3D3    , MintCream            = 0xFFF5FFFA
            , LightGrey         = 0xFFD3D3D3    , MistyRose            = 0xFFFFE4E1
            , LightSlateGray    = 0xFF778899    , OldLace              = 0xFFFDF5E6
            , LightSlateGrey    = 0xFF778899    , Seashell             = 0xFFFFF5EE
            , Silver            = 0xFFC0C0C0    , Snow                 = 0xFFFFFAFA
            , SlateGray         = 0xFF708090    , White                = 0xFFFFFFFF
            , SlateGrey         = 0xFF708090    , WhiteSmoke           = 0xFFF5F5F5
            
            ; Red                               ; Pink
        Static Crimson          = 0xFFDC143C    , DeepPink             = 0xFFFF1493
            , DarkRed           = 0xFF8B0000    , HotPink              = 0xFFFF69B4
            , DarkSalmon        = 0xFFE9967A    , LightPink            = 0xFFFFB6C1
            , Firebrick         = 0xFFB22222    , MediumVioletRed      = 0xFFC71585
            , IndianRed         = 0xFFCD5C5C    , PaleVioletRed        = 0xFFDB7093
            , LightCoral        = 0xFFF08080    , Pink                 = 0xFFFFC0CB
            , LightSalmon       = 0xFFFFA07A    
            , Red               = 0xFFFF0000    
            , Salmon            = 0xFFFA8072    
            
            ; Green                             ; Yellow
        Static Chartreuse       = 0xFF7FFF00    , Bisque               = 0xFFFFE4C4
            , DarkGreen         = 0xFF006400    , BlanchedAlmond       = 0xFFFFEBCD
            , DarkOliveGreen    = 0xFF556B2F    , Burlywood            = 0xFFDEB887
            , ForestGreen       = 0xFF228B22    , Cornsilk             = 0xFFFFF8DC
            , Green             = 0xFF008000    , DarkKhaki            = 0xFFBDB76B
            , GreenYellow       = 0xFFADFF2F    , Gold                 = 0xFFFFD700
            , LawnGreen         = 0xFF7CFC00    , Khaki                = 0xFFF0E68C
            , LightGreen        = 0xFF90EE90    , LemonChiffon         = 0xFFFFFACD
            , Lime              = 0xFF00FF00    , LightGoldenrodYellow = 0xFFFAFAD2
            , LimeGreen         = 0xFF32CD32    , LightYellow          = 0xFFFFFFE0
            , MediumAquamarine  = 0xFF66CDAA    , Moccasin             = 0xFFFFE4B5
            , MediumSeaGreen    = 0xFF3CB371    , NavajoWhite          = 0xFFFFDEAD
            , MediumSpringGreen = 0xFF00FA9A    , PaleGoldenrod        = 0xFFEEE8AA
            , Olive             = 0xFF808000    , PapayaWhip           = 0xFFFFEFD5
            , OliveDrab         = 0xFF6B8E23    , PeachPuff            = 0xFFFFDAB9
            , PaleGreen         = 0xFF98FB98    , Wheat                = 0xFFF5DEB3
            , SeaGreen          = 0xFF2E8B57    , Yellow               = 0xFFFFFF00
            , SpringGreen       = 0xFF00FF7F    
            , YellowGreen       = 0xFF9ACD32    
            
            ; Blue                              ; Cyan
        Static Blue             = 0xFF0000FF    , Aqua                 = 0xFF00FFFF
            , CornflowerBlue    = 0xFF6495ED    , Aquamarine           = 0xFF7FFFD4
            , DarkBlue          = 0xFF00008B    , CadetBlue            = 0xFF5F9EA0
            , DeepSkyBlue       = 0xFF00BFFF    , Cyan                 = 0xFF00FFFF
            , DodgerBlue        = 0xFF1E90FF    , DarkCyan             = 0xFF008B8B
            , LightBlue         = 0xFFADD8E6    , DarkTurquoise        = 0xFF00CED1
            , LightSkyBlue      = 0xFF87CEFA    , LightCyan            = 0xFFE0FFFF
            , LightSteelBlue    = 0xFFB0C4DE    , LightSeaGreen        = 0xFF20B2AA
            , MediumBlue        = 0xFF0000CD    , MediumTurquoise      = 0xFF48D1CC
            , MidnightBlue      = 0xFF191970    , PaleTurquoise        = 0xFFAFEEEE
            , Navy              = 0xFF000080    , Teal                 = 0xFF008080
            , PowderBlue        = 0xFFB0E0E6    , Turquoise            = 0xFF40E0D0
            , RoyalBlue         = 0xFF4169E1    
            , SkyBlue           = 0xFF87CEEB    
            , SteelBlue         = 0xFF4682B4    
            
            ; Purple/magenta                    ; Orange
        Static BlueViolet       = 0xFF8A2BE2    , Coral                = 0xFFFF7F50
            , DarkMagenta       = 0xFF8B008B    , DarkOrange           = 0xFFFF8C00
            , DarkOrchid        = 0xFF9932CC    , Orange               = 0xFFFFA500
            , DarkSlateBlue     = 0xFF483D8B    , OrangeRed            = 0xFFFF4500
            , DarkViolet        = 0xFF9400D3    , Tomato               = 0xFFFF6347
            , Fuchsia           = 0xFFFF00FF    
            , Indigo            = 0xFF4B0082    ; Brown
            , Lavender          = 0xFFE6E6FA    , Brown                = 0xFFA52A2A
            , Magenta           = 0xFFFF00FF    , Chocolate            = 0xFFD2691E
            , MediumOrchid      = 0xFFBA55D3    , DarkGoldenrod        = 0xFFB8860B
            , MediumPurple      = 0xFF9370DB    , Goldenrod            = 0xFFDAA520
            , MediumSlateBlue   = 0xFF7B68EE    , Maroon               = 0xFF800000
            , Orchid            = 0xFFDA70D6    , Peru                 = 0xFFCD853F
            , Plum              = 0xFFDDA0DD    , RosyBrown            = 0xFFBC8F8F
            , Purple            = 0xFF800080    , SaddleBrown          = 0xFF8B4513
            , SlateBlue         = 0xFF6A5ACD    , SandyBrown           = 0xFFF4A460
            , Thistle           = 0xFFD8BFD8    , Sienna               = 0xFFA0522D
            , Violet            = 0xFFEE82EE    , Tan                  = 0xFFD2B48C
        
        ; Color()
        ; Color(ColorObject)
        ; Color(ARGB)
        ; Color(red, blue, green)
        ; Color(alpha, red, blue, green)
        __New(a="", r="", g="", b="")
        {
            this.SetCapacity("_struct", 4)
            ,this._ptr := this.GetAddress("_struct")
            ,(a._type == "Color" && r = "" && g = "" && b = "")     ; Color object
                ? this._set_color(a.A, a.R, a.G, a.B)
            : ((a >= 0 && a <= 0xFFFFFFFF) && r="" && g="" && b="") ; ARGB (0xAARRGGBB)
                ? this.SetValue(a)
            : (a="" && r="" && g="" && b="")                        ; All Empty
                ? this._set_color(255, 0, 0, 0)
            : (b = "")                                              ; R G B values
                ? this._set_color(255, a, r, g)
                : this._set_color(a, r, g, b)                       ; A R G B values 
        }
        
        ; Remark: Values fallling out of the 0-255 range will be rounded
        _set_color(a, r, g, b)
        {
             this.A := (a < 0) ? 0 : (a > 255) ? 255 : a
            ,this.R := (r < 0) ? 0 : (r > 255) ? 255 : r
            ,this.G := (g < 0) ? 0 : (g > 255) ? 255 : g
            ,this.B := (b < 0) ? 0 : (b > 255) ? 255 : b
        }
        
        Show()
        {
            ptr   := this.Struct()
            ,a    := NumGet(ptr+0, 3, "UChar")
            ,r    := NumGet(ptr+0, 2, "UChar")
            ,g    := NumGet(ptr+0, 1, "UChar")
            ,b    := NumGet(ptr+0, 0, "UChar")
            ,argb := this.GetValue()
            MsgBox, % this._type " object:"
                . "`n_ptr: "   this._ptr
                . "`nA: "         GDIP.to_hex(this.A) " | " this.A
                . "`nR: "         GDIP.to_hex(this.R) " | " this.R
                . "`nB: "         GDIP.to_hex(this.B) " | " this.B
                . "`nG: "         GDIP.to_hex(this.G) " | " this.G
                . "`nNumGet A: "  GDIP.to_hex(a) " | " a
                . "`nNumGet R: "  GDIP.to_hex(r) " | " r
                . "`nNumGet G: "  GDIP.to_hex(g) " | " g
                . "`nNumGet B: "  GDIP.to_hex(b) " | " b
                . "`nARBG: "      GDIP.to_hex(argb) " | " argb
        }
        
        GetAlpha(hex=0) {
            Return (hex ? GDIP.to_hex(this.A) : this.A)
        }
        
        GetRed(hex=0) {
            Return (hex ? GDIP.to_hex(this.R) : this.R)
        }
        
        GetGreen(hex=0) {
            Return (hex ? GDIP.to_hex(this.G) : this.G)
        }
        
        GetBlue(hex=0) {
            Return (hex ? GDIP.to_hex(this.B) : this.B)
        }
        
        GetValue(hex=0) {
            argb := (this.A << this.A_Shift)
                 +  (this.R << this.R_Shift)
                 +  (this.G << this.G_Shift)
                 +   this.B
            Return (hex ? GDIP.to_hex(argb) : argb)
        }
        
        SetValue(argb) {
             this.A := (argb & this.A_Mask) >> this.A_Shift
            ,this.R := (argb & this.R_Mask) >> this.R_Shift
            ,this.G := (argb & this.G_Mask) >> this.G_Shift
            ,this.B := (argb & this.B_Mask)
        }
        
        ; Takes four 8-bit values (0-255) and returns a 32-bit combined
        MakeARGB(a, r, g, b)
        {
            Return ( (a << this.A_Shift)
                   + (r << this.R_Shift)
                   + (g << this.G_Shift)
                   +  b )
        }        
        
        ; ; I don't think these two will be needed, so they're staying commented out for now
        ; ; Set ARGB value using a COLORREF
        ; SetFromCOLORREF()
        ; {
        ;     Return
        ; }
        ; 
        ; ; Converts ARGB value to a COLORREF
        ; ToCOLORREF(ARGB)
        ; {
        ;     Return
        ; }
        
        ; ARGB masks and bitshifts
        Static A_Mask  := 0xFF000000
             , R_Mask  := 0x00FF0000
             , G_Mask  := 0x0000FF00
             , B_Mask  := 0x000000FF
             , A_Shift := 24
             , R_Shift := 16
             , G_Shift := 8
             , B_Shift := 0
        
    }
    
    get_min(n1, n2) {
        Return (n1 < n2) ? n1 : n2
    }
    
    get_max(n1, n2) {
        Return (n1 > n2) ? n1 : n2
    }
    
    to_hex(num) {
        Return Format("0x{:X}", num)
    }
    
    
    
    ;-------------------------------------------------------------------------------------------------------------------.
    ; GdiplusPen.h                                                                                                      |
    ;___________________________________________________________________________________________________________________|
    ;-------------------------------------------------------------------------------------------------------------------.
    ; Pen Class - Creates an object to draw lines with.                                                                 |
    ;-------------------------------------------------------------------------------------------------------------------|
    ; Properties:                                                                                                       |
    ; None              The pen object only has methods.                                                                |
    ;                                                                                                                   |
    ; Constructors:                                                                                                     |
    ; Color()           Defaults to solid black. A=255, R=0, B=0, G=0                                                   |
    ; Color(ARGB)       Copy ARGB object values. A=ARGB.A, R=ARGB.R, B=ARGB.B, G=ARGB.G                                 |
    ; Color(r, b, g)    Red, blue, green values. Alpha is assumed opaque. A=255, R=r, B=b, G=g                          |
    ; Color(a, r, b, g) Set values A=a, R=r, B=b, G=g                                                                   |
    ;                                                                                                                   |
    ; Methods:                                                                                                          |
    ; .struct()         Builds struct and returns struct pointer.                                                       |
    ;                                                                                                                   |
    ; Enum: Names       List of 139 pre-defined colors. Use: this.name.Colorname                                        |
    ;___________________________________________________________________________________________________________________|
    Class Pen
    {
        _type      := "Pen"
        lastResult := ""
        nativePen[]
        {
            Get {
                Return this._ptr+0
            }
            Set {
                this._ptr := value
            }
        }
        
        ; Pen()                  ; Create default black pen with width 1
        ; Pen(ColorObj, width)   ; Create pen using color ARGB and a pen width
        ; Pen(BrushObj, width)   ; 
        __New(p1="", width=1, lastRes="")
        {
            this.SetCapacity(nativePen, A_PtrSize)
            , (p1 = "")
                ? this.lastResult := DllCall("gdiplus\GdipCreatePen1"           ; Default black pen
                                            ,"Int"        ,GDIP.Color.Black
                                            ,"Float"      ,1
                                            ,"Int"        ,0
                                            ,this.PtrA    ,this.nativePen)
            : (p1._type == "Color")
                ? this.lastResult := DllCall("gdiplus\GdipCreatePen1"           ; Pen from ColorObj
                                            ,"Int"        ,p1.GetValue()
                                            ,"Float"      ,width
                                            ,"Int"        ,0
                                            ,this.PtrA    ,this.nativePen)
            : (p1._type == "Brush")
                ? this.lastResult := DllCall("gdiplus\GdipCreatePen2"           ; Pen from BrushObj
                                            ,this.Ptr     ,p1.nativeBrush
                                            ,"Float"      ,width
                                            ,"Int"        ,0
                                            ,this.PtrA    ,this.nativePen)
            : (p1 == "ClonePen")                                                ; Internal call for Pen clones
                ? (this.nativePen  := width
                  ,this.lastResult := lastRes )
            : (this.lastResult := 2
              ,this.error_log(A_ThisFunc, "Bad parameter"                       ; Otherwise, error
                             ,"Pen()`nPen(ColorObj, Width)`nPen(BrushObj, Width)"
                             ,{p1:p1, p2:width, p3:lastRes} )
        }
        
        __Delete()
        {
            DllCall("gdiplus\GdipDeletePen", this.Ptr, this.nativePen)
        }
        
        Clone()
        {
            VarSetCapacity(clonePen, A_PtrSize)
            this.lastResult := DllCall("gdiplus\GdipClonePen"
                                      ,this.Ptr     ,this.nativePen
                                      ,this.PtrA    ,clonePen)
            Return new GDIP.Pen("ClonePen", clonePen, lastResult)
        }
        
        SetWidth(width) ; Float
        {
            return SetStatus(DllCall("gdiplus\GdipSetPenWidth(nativePen, width));
        }
        
        ;~ REAL GetWidth() const
        ;~ {
            ;~ REAL width;
        
            ;~ SetStatus(DllCall("gdiplus\GdipGetPenWidth(nativePen, &width));
            
            ;~ return width;
        ;~ }
        
        ;~ ; Set/get line caps: start, end, and dash
        
        ;~ ; Line cap and join APIs by using LineCap and LineJoin enums.
        
        ;~ Status SetLineCap(IN LineCap startCap, 
                          ;~ IN LineCap endCap, 
                          ;~ IN DashCap dashCap)
        ;~ {
            ;~ return SetStatus(DllCall("gdiplus\GdipSetPenLineCap197819(nativePen, 
                                       ;~ startCap, endCap, dashCap));
        ;~ }
        
        ;~ Status SetStartCap(IN LineCap startCap)
        ;~ {
            ;~ return SetStatus(DllCall("gdiplus\GdipSetPenStartCap(nativePen, startCap));
        ;~ }
        
        ;~ Status SetEndCap(IN LineCap endCap)
        ;~ {
            ;~ return SetStatus(DllCall("gdiplus\GdipSetPenEndCap(nativePen, endCap));
        ;~ }
        
        ;~ Status SetDashCap(IN DashCap dashCap)
        ;~ {
            ;~ return SetStatus(DllCall("gdiplus\GdipSetPenDashCap197819(nativePen,
                                       ;~ dashCap));
        ;~ }
        
        ;~ LineCap GetStartCap() const
        ;~ {
            ;~ LineCap startCap;
        
            ;~ SetStatus(DllCall("gdiplus\GdipGetPenStartCap(nativePen, &startCap));
            
            ;~ return startCap;
        ;~ }
        
        ;~ LineCap GetEndCap() const
        ;~ {
            ;~ LineCap endCap;
        
            ;~ SetStatus(DllCall("gdiplus\GdipGetPenEndCap(nativePen, &endCap));
        
            ;~ return endCap;
        ;~ }
        
        ;~ DashCap GetDashCap() const
        ;~ {
            ;~ DashCap dashCap;
        
            ;~ SetStatus(DllCall("gdiplus\GdipGetPenDashCap197819(nativePen,
                                ;~ &dashCap));
        
            ;~ return dashCap;
        ;~ }
        
        ;~ Status SetLineJoin(IN LineJoin lineJoin)
        ;~ {
            ;~ return SetStatus(DllCall("gdiplus\GdipSetPenLineJoin(nativePen, lineJoin));
        ;~ }
        
        ;~ LineJoin GetLineJoin() const
        ;~ {
            ;~ LineJoin lineJoin;
            
            ;~ SetStatus(DllCall("gdiplus\GdipGetPenLineJoin(nativePen, &lineJoin));
            
            ;~ return lineJoin;
        ;~ }
        
        ;~ Status SetCustomStartCap(IN const CustomLineCap* customCap)
        ;~ {
            ;~ GpCustomLineCap* nativeCap = NULL;
            ;~ if(customCap)
                ;~ nativeCap = customCap->nativeCap;
        
            ;~ return SetStatus(DllCall("gdiplus\GdipSetPenCustomStartCap(nativePen, 
                                                                  ;~ nativeCap));
        ;~ }
        
        ;~ Status GetCustomStartCap(OUT CustomLineCap* customCap) const
        ;~ {
            ;~ if(!customCap)
                ;~ return SetStatus(InvalidParameter);
        
            ;~ return SetStatus(DllCall("gdiplus\GdipGetPenCustomStartCap(nativePen, 
                                                        ;~ &(customCap->nativeCap)));
        ;~ }
        
        ;~ Status SetCustomEndCap(IN const CustomLineCap* customCap)
        ;~ {
            ;~ GpCustomLineCap* nativeCap = NULL;
            ;~ if(customCap)
                ;~ nativeCap = customCap->nativeCap;
        
            ;~ return SetStatus(DllCall("gdiplus\GdipSetPenCustomEndCap(nativePen, 
                                                                ;~ nativeCap));
        ;~ }
        
        ;~ Status GetCustomEndCap(OUT CustomLineCap* customCap) const
        ;~ {
            ;~ if(!customCap)
                ;~ return SetStatus(InvalidParameter);
        
            ;~ return SetStatus(DllCall("gdiplus\GdipGetPenCustomEndCap(nativePen, 
                                                        ;~ &(customCap->nativeCap)));
        ;~ }
        
        ;~ Status SetMiterLimit(IN REAL miterLimit)
        ;~ {
            ;~ return SetStatus(DllCall("gdiplus\GdipSetPenMiterLimit(nativePen, 
                                                        ;~ miterLimit));
        ;~ }
        
        ;~ REAL GetMiterLimit() const
        ;~ {
            ;~ REAL miterLimit;
        
            ;~ SetStatus(DllCall("gdiplus\GdipGetPenMiterLimit(nativePen, &miterLimit));
        
            ;~ return miterLimit;
        ;~ }
        
        ;~ Status SetAlignment(IN PenAlignment penAlignment)
        ;~ {
            ;~ return SetStatus(DllCall("gdiplus\GdipSetPenMode(nativePen, penAlignment));
        ;~ }
        
        ;~ PenAlignment GetAlignment() const
        ;~ {
            ;~ PenAlignment penAlignment;
            
            ;~ SetStatus(DllCall("gdiplus\GdipGetPenMode(nativePen, &penAlignment));
            
            ;~ return penAlignment;
        ;~ }
        
        ;~ Status SetTransform(IN const Matrix* matrix)
        ;~ {
            ;~ return SetStatus(DllCall("gdiplus\GdipSetPenTransform(nativePen, 
                                                           ;~ matrix->nativeMatrix));
        ;~ }
        
        ;~ Status GetTransform(OUT Matrix* matrix) const
        ;~ {
            ;~ return SetStatus(DllCall("gdiplus\GdipGetPenTransform(nativePen, 
                                                             ;~ matrix->nativeMatrix));
        ;~ }
        
        ;~ Status ResetTransform()
        ;~ {
            ;~ return SetStatus(DllCall("gdiplus\GdipResetPenTransform(nativePen));
        ;~ }
        
        ;~ Status MultiplyTransform(IN const Matrix* matrix,
                                 ;~ IN MatrixOrder order = MatrixOrderPrepend)
        ;~ {
            ;~ return SetStatus(DllCall("gdiplus\GdipMultiplyPenTransform(nativePen,
                                                             ;~ matrix->nativeMatrix,
                                                             ;~ order));
        ;~ }
        
        ;~ Status TranslateTransform(IN REAL dx, 
                                  ;~ IN REAL dy,
                                  ;~ IN MatrixOrder order = MatrixOrderPrepend)
        ;~ {
            ;~ return SetStatus(DllCall("gdiplus\GdipTranslatePenTransform(nativePen,
                                                                   ;~ dx, 
                                                                   ;~ dy, 
                                                                   ;~ order));
        ;~ }
        
        ;~ Status ScaleTransform(IN REAL sx, 
                              ;~ IN REAL sy,
                              ;~ IN MatrixOrder order = MatrixOrderPrepend)
        ;~ {
            ;~ return SetStatus(DllCall("gdiplus\GdipScalePenTransform(nativePen,
                                                               ;~ sx, 
                                                               ;~ sy, 
                                                               ;~ order));
        ;~ }
        
        ;~ Status RotateTransform(IN REAL angle, 
                               ;~ IN MatrixOrder order = MatrixOrderPrepend)
        ;~ {
            ;~ return SetStatus(DllCall("gdiplus\GdipRotatePenTransform(nativePen,
                                                                ;~ angle, 
                                                                ;~ order));
        ;~ }
        
        ;~ PenType GetPenType() const
        ;~ {
           ;~ PenType type;
           ;~ SetStatus(DllCall("gdiplus\GdipGetPenFillType(nativePen, &type));
        
           ;~ return type;
        ;~ }
        
        ;~ Status SetColor(IN const Color& color)
        ;~ {
            ;~ return SetStatus(DllCall("gdiplus\GdipSetPenColor(nativePen,
                                                         ;~ color.GetValue()));
        ;~ }
        
        ;~ Status SetBrush(IN const Brush* brush)
        ;~ {
            ;~ return SetStatus(DllCall("gdiplus\GdipSetPenBrushFill(nativePen, 
                                           ;~ brush->nativeBrush));
        ;~ }
        
        ;~ Status GetColor(OUT Color* color) const
        ;~ {
            ;~ if (color == NULL) 
            ;~ {
                ;~ return SetStatus(InvalidParameter);
            ;~ }
            
            ;~ PenType type = GetPenType();
        
            ;~ if (type != PenTypeSolidColor) 
            ;~ {
                ;~ return WrongState;
            ;~ }
            
            ;~ ARGB argb;
            
            ;~ SetStatus(DllCall("gdiplus\GdipGetPenColor(nativePen,
                                                  ;~ &argb));
            ;~ if (lastResult == Ok)
            ;~ {
                ;~ color->SetValue(argb);
            ;~ }
            
            ;~ return lastResult;
        ;~ }
        
        ;~ Brush* GetBrush() const
        ;~ {
           ;~ PenType type = GetPenType();
        
           ;~ Brush* brush = NULL;
        
           ;~ switch(type)
           ;~ {
           ;~ case PenTypeSolidColor:
               ;~ brush = new SolidBrush();
               ;~ break;
        
           ;~ case PenTypeHatchFill:
               ;~ brush = new HatchBrush();
               ;~ break;
        
           ;~ case PenTypeTextureFill:
               ;~ brush = new TextureBrush();
               ;~ break;
        
           ;~ case PenTypePathGradient:
               ;~ brush = new Brush();
               ;~ break;
        
           ;~ case PenTypeLinearGradient:
               ;~ brush = new LinearGradientBrush();
               ;~ break;
        
           ;~ default:
               ;~ break;
           ;~ }
        
           ;~ if(brush)
           ;~ {
               ;~ GpBrush* nativeBrush;
        
               ;~ SetStatus(DllCall("gdiplus\GdipGetPenBrushFill(nativePen, 
                                                         ;~ &nativeBrush));
               ;~ brush->SetNativeBrush(nativeBrush);
           ;~ }
        
           ;~ return brush;
        ;~ }
        
        ;~ DashStyle GetDashStyle() const
        ;~ {
            ;~ DashStyle dashStyle;
        
            ;~ SetStatus(DllCall("gdiplus\GdipGetPenDashStyle(nativePen, &dashStyle));
        
            ;~ return dashStyle;
        ;~ }
        
        ;~ Status SetDashStyle(IN DashStyle dashStyle)
        ;~ {
            ;~ return SetStatus(DllCall("gdiplus\GdipSetPenDashStyle(nativePen, 
                                                             ;~ dashStyle));
        ;~ }
        
        ;~ REAL GetDashOffset() const
        ;~ {
            ;~ REAL dashOffset;
        
            ;~ SetStatus(DllCall("gdiplus\GdipGetPenDashOffset(nativePen, &dashOffset));
        
            ;~ return dashOffset;
        ;~ }
        
        ;~ Status SetDashOffset(IN REAL dashOffset)
        ;~ {
            ;~ return SetStatus(DllCall("gdiplus\GdipSetPenDashOffset(nativePen, 
                                                              ;~ dashOffset));
        ;~ }
        
        ;~ Status SetDashPattern(IN const REAL* dashArray, IN INT count)
        ;~ {
            ;~ return SetStatus(DllCall("gdiplus\GdipSetPenDashArray(nativePen,
                                                             ;~ dashArray, 
                                                             ;~ count));
        ;~ }
        
        ;~ INT GetDashPatternCount() const
        ;~ {
            ;~ INT count = 0;
            
            ;~ SetStatus(DllCall("gdiplus\GdipGetPenDashCount(nativePen, &count));
            
            ;~ return count;
        ;~ }
        
        ;~ Status GetDashPattern(OUT REAL* dashArray, 
                              ;~ IN INT count) const
        ;~ {
            ;~ if (dashArray == NULL || count <= 0)
                ;~ return SetStatus(InvalidParameter); 
            
            ;~ return SetStatus(DllCall("gdiplus\GdipGetPenDashArray(nativePen, 
                                                             ;~ dashArray, 
                                                             ;~ count));
        ;~ }
        
        ;~ Status SetCompoundArray(IN const REAL* compoundArray,
                                ;~ IN INT count)
        ;~ {
            ;~ return SetStatus(DllCall("gdiplus\GdipSetPenCompoundArray(nativePen, 
                                                                 ;~ compoundArray,
                                                                 ;~ count));
        ;~ }
        
        ;~ INT GetCompoundArrayCount() const
        ;~ {
            ;~ INT count = 0;
            
            ;~ SetStatus(DllCall("gdiplus\GdipGetPenCompoundCount(nativePen, &count));
            
            ;~ return count;
        ;~ }
        
        ;~ Status GetCompoundArray(OUT REAL* compoundArray, 
                                ;~ IN INT count) const
        ;~ {
            ;~ if (compoundArray == NULL || count <= 0)
                ;~ return SetStatus(InvalidParameter); 
            
            ;~ return SetStatus(DllCall("gdiplus\GdipGetPenCompoundArray(nativePen, 
                                                                 ;~ compoundArray, 
                                                                 ;~ count));
        ;~ }
        
        ;~ Status GetLastStatus() const
        ;~ {
            ;~ Status lastStatus = lastResult;
            ;~ lastResult = Ok;
        
            ;~ return lastStatus;
        ;~ }
    
    ;~ protected:
        ;~ Pen(GpPen* nativePen, Status status)
        ;~ {
            ;~ lastResult = status;
            ;~ SetNativePen(nativePen);
        ;~ }
        
        ;~ VOID SetNativePen(GpPen* nativePen)
        ;~ {
            ;~ this->nativePen = nativePen;
        ;~ }
        
        ;~ Status SetStatus(Status status) const
        ;~ {
            ;~ if (status != Ok)
                ;~ return (lastResult = status);
            ;~ else 
                ;~ return status;
        ;~ }
    }
}
