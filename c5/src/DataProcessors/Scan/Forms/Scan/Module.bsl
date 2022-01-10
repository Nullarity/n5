&AtClient
var CameraActive;
&AtClient
var CameraWasActive;
&AtClient
var ScanResult;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	// 8.3.6.x Bug workaround. Just PurposeUseKey does not work
	// Window size should dependend on PurposeUseKey
	setWindowSize ();
	loadParams ();
	readAppearance ();
	
EndProcedure

&AtServer
Procedure init ()
	
	AllowCreation = Parameters.AllowCreation and AccessRight ( "Edit", Metadata.Catalogs.Items );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Autoclose AskQuantity show not JustScan;
	|Scan CodeType CameraOnly FormScan show ScannerSupported;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure setWindowSize ()
	
	if ( Parameters.JustScan ) then
		WindowOptionsKey = "Scan";
	else
		WindowOptionsKey = "Select";
	endif; 
	
EndProcedure 

&AtServer
Procedure loadParams ()
	
	JustScan = Parameters.JustScan;
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	initFields ();
	resetScanResult ();
	defineScan ();
	Appearance.Apply ( ThisObject );
	if ( CameraOnly
		and ScannerSupported  ) then
		openCamera ();
	else
		continueScanning ();
	endif;
	
EndProcedure

&AtClient
Procedure initFields ()
	
	CameraActive = false;
	CameraWasActive = false;
	
EndProcedure

&AtClient
Procedure resetScanResult ()
	
	ScanResult = new Structure ();
	ScanResult.Insert ( "Barcode" );
	ScanResult.Insert ( "Code" );
	ScanResult.Insert ( "Item" );
	ScanResult.Insert ( "Package" );
	ScanResult.Insert ( "Series" );
	ScanResult.Insert ( "Feature" );
	ScanResult.Insert ( "Quantity", 1 );
	ScanResult.Insert ( "QuantityPkg", 1 );
	ScanResult.Insert ( "Capacity", 1 );
	ScanResult.Insert ( "SeriesControl", false );
	ScanResult.Insert ( "BarcodeFound", false );
	
EndProcedure

&AtClient
Procedure defineScan ()
	
	#if ( MobileClient ) then
		ScannerSupported = MultimediaTools.BarcodeScanningSupported ();
	#else
		ScannerSupported = false;
	#endif
	
EndProcedure 

&AtClient
Procedure openCamera ()
	
	#if ( MobileClient ) then
		if ( CameraActive ) then
			return;
		endif;
		CameraActive = true;
		if ( CodeType = 1 ) then
			type = BarcodeType.Linear;
		elsif ( CodeType = 2 ) then
			type = BarcodeType.Matrix;
		else
			type = BarcodeType.All;
		endif; 
		scanning = new NotifyDescription ( "Scanning", ThisObject );
		closing = new NotifyDescription ( "ClosingScanner", ThisObject );
	    MultimediaTools.ShowBarcodeScanning ( Output.FocusCamera (), scanning, closing, type );
	#endif
	
EndProcedure 

&AtClient
Procedure Scanning ( Code, Result, Error, Params ) export
	
	if ( Result ) then
		applyBarcode ( Code );
	else
        raise Error;
    endif;

EndProcedure 

&AtClient
Procedure applyBarcode ( Code )

	data = barcodeData ( Code );
	dataFound = data <> undefined;
	if ( dataFound ) then
		FillPropertyValues ( ScanResult, data );
	endif;
	ScanResult.Barcode = Code;
	if ( JustScan ) then
		if ( dataFound ) then
			provideFields ();
		endif; 
	else
		if ( not dataFound ) then
			askUser ();
		elsif ( ScanResult.SeriesControl
			and ScanResult.Series.IsEmpty () ) then
			askUser ( true );
		else
			applyItem ();
		endif; 
	endif; 
	
EndProcedure 

&AtServerNoContext
Function barcodeData ( Code )
	
	barcode = StrReplace ( Code, Char ( 10 ), "" );
	barcode = StrReplace ( barcode, Char ( 13 ), "" );
	s = "
	|select Barcodes.Item as Item, Barcodes.Package as Package, Barcodes.Series as Series,
	|	Barcodes.Item.Code as Code, Barcodes.Item.Series as SeriesControl, Barcodes.Feature as Feature,
	|	Barcodes.Item.Series and Barcodes.Series <> value ( Catalog.Series.EmptyRef ) as BarcodeFound,
	|	isnull ( Barcodes.Package.Capacity, 1 ) as Capacity
	|from InformationRegister.Barcodes as Barcodes
	|where Barcodes.Barcode = &Barcode
	|";
	q = new Query ( s );
	q.SetParameter ( "Barcode", barcode );
	table = q.Execute ().Unload ();
	if ( table.Count () = 0 ) then
		return undefined;
	endif;
	result = new Structure ( "Barcode, Capacity, QuantityPkg, Code, Item, Package, Feature, Series, SeriesControl, Quantity",
		barcode, 1, 1 );
	FillPropertyValues ( result, table [ 0 ] );
	Computations.Units ( result );
	return result;

EndFunction 

&AtClient
Procedure BarcodeNotfound ( Params ) export
	
	continueScanning ();
	
EndProcedure

&AtClient
Procedure askUser ( JustSeries = false )
	
	closeCamera ();
	callback = new NotifyDescription ( "AugmentedData", ThisObject );
	params = new Structure ( "ScanResult", ScanResult );
	if ( JustSeries ) then
		form = "DataProcessor.Scan.Form.SelectSeries";
	else
		if ( AllowCreation ) then
			form = "DataProcessor.Scan.Form.AssignBarcode";
		else
			Output.BarcodeNotFound ( ThisObject );
			return;
		endif;
	endif;
	OpenForm ( form, params, ThisObject, , , , callback );
	
EndProcedure

&AtClient
Procedure AugmentedData ( Data, Nothing ) export
	
	if ( Data = undefined ) then
		continueScanning ();
	else
		FillPropertyValues ( ScanResult, Data );
		applyItem ();
	endif;
	
EndProcedure

&AtClient
Procedure applyItem ()
	
	if ( AskQuantity ) then
		closeCamera ();
		callback = new NotifyDescription ( "QuantitySelected", ThisObject );
		OpenForm ( "DataProcessor.Scan.Form.Quantity", new Structure ( "ScanResult", ScanResult ), ThisObject, , , , callback );
	else
		provideFields ();
	endif; 
	
EndProcedure

&AtClient
Procedure closeCamera ()
	
	#if ( MobileClient ) then
		if ( CameraActive ) then
			MultimediaTools.CloseBarcodeScanning ();
			CameraActive = false;
			CameraWasActive = true;
		endif; 
	#endif
	
EndProcedure 

&AtClient
Procedure provideFields ()
	
	Notify ( Enum.MessageBarcodeScanned (), ScanResult, ThisObject );
	if ( Autoclose
		or JustScan ) then
		closeCamera ();
		startClosing ();
	else
		if ( CameraWasActive ) then
			openCamera ();
		else
			continueScanning ();
		endif; 
	endif; 
		
EndProcedure 

&AtClient
Procedure ClosingScanner ( Params ) export
	
	CameraActive = false;
	CameraWasActive = true;
	
EndProcedure

&AtClient
Procedure continueScanning ()
	
	Activate ();
	Barcode = "";
	resetScanResult ();
	CurrentItem = Items.Barcode;
	#if ( MobileClient ) then
    	BeginEditingItem ();
	#endif
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	proceed ( Barcode );
	
EndProcedure

&AtClient
Procedure proceed ( Text )
	
	if ( IsBlankString ( Text ) ) then
		return;
	endif; 
	applyBarcode ( Text );

EndProcedure

&AtClient
Procedure Scan ( Command )
	
	openCamera ();
	
EndProcedure

&AtClient
Procedure BarcodeAutoComplete ( Item, Text, ChoiceData, DataGetParameters, Wait, StandardProcessing )
	
	proceed ( Text );

EndProcedure

&AtClient
Procedure startClosing ()
	
	AttachIdleHandler ( "closeForm", 0.1, true ); // 8.3.6.x Bug workaround. Just close () will crash thin client
	
EndProcedure 

&AtClient
Procedure closeForm ()
	
	Close ();
	
EndProcedure 

&AtClient
Procedure QuantitySelected ( Fields, Params ) export
	
	if ( Fields = undefined ) then
		continueScanning ();
	else
		FillPropertyValues ( ScanResult, Fields );
		provideFields ();
	endif;
	
EndProcedure 
