&AtClient
var Result;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	// 8.3.6.x Bug workaround. Just PurposeUseKey does not work
	// Window size should dependend on PurposeUseKey
	setWindowSize ();
	loadParams ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Autoclose AskQuantity show not JustScan
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
Procedure OnClose ( Exit )
	
	if ( Result <> undefined ) then
		provideFields ( Result );
	endif; 
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure BarcodeAutoComplete ( Item, Text, ChoiceData, DataGetParameters, Wait, StandardProcessing )
	
	if ( IsBlankString ( Text ) ) then
		return;
	endif; 
	applyBarcode ( Text );
	
EndProcedure

&AtClient
Procedure startClosing ( Data )
	
	Result = Data;
	AttachIdleHandler ( "closeForm", 0.1, true ); // 8.3.6.x Bug workaround. Just close () will crash thin client
	
EndProcedure 

&AtClient
Procedure closeForm ()
	
	Close ();
	
EndProcedure 

&AtClient
Procedure applyBarcode ( Code )

	data = barcodeData ( Code );
	if ( JustScan ) then
		if ( data.Item <> undefined ) then
			startClosing ( data );
			return;
		endif; 
	else
		if ( data.Item = undefined ) then
			Output.BarcodeNotFound ();
		else
			if ( AskQuantity ) then
				OpenForm ( "CommonForm.Quantity", data, ThisObject, , , , new NotifyDescription ( "QuantitySelected", ThisObject ) );
			else
				if ( Autoclose ) then
					startClosing ( data );
					return;
				else
					provideFields ( data );
				endif; 
			endif; 
		endif; 
	endif; 
	Barcode = "";
	CurrentItem = Items.Barcode;
	
EndProcedure 

&AtServerNoContext
Function barcodeData ( val Code )
	
	Code = StrReplace ( Code, Char ( 10 ), "" );
	Code = StrReplace ( Code, Char ( 13 ), "" );
	s = "
	|select Barcodes.Item as Item, Barcodes.Package as Package, Barcodes.Feature as Feature,
	|	Barcodes.Item.Code as Code, isnull ( Barcodes.Package.Capacity, 1 ) as Capacity
	|from InformationRegister.Barcodes as Barcodes
	|where Barcodes.Barcode = &Barcode
	|";
	q = new Query ( s );
	q.SetParameter ( "Barcode", Code );
	table = q.Execute ().Unload ();
	fields = new Structure ( "Barcode, Code, Item, Package, Feature, Capacity, Quantity, QuantityPkg" );
	fields.Barcode = Code;
	if ( table.Count () = 0 ) then
		fields.Capacity = 1;
	else
		FillPropertyValues ( fields, table [ 0 ] );
	endif;
	fields.QuantityPkg = 1;
	Computations.Units ( fields );
	return fields;

EndFunction 

&AtClient
Procedure provideFields ( Fields )
	
	Notify ( Enum.MessageBarcodeScanned (), Fields, ThisObject );
		
EndProcedure 

&AtClient
Procedure QuantitySelected ( Fields, Params ) export
	
	if ( Fields = undefined ) then
		return;
	endif; 
	if ( Autoclose ) then
		startClosing ( Fields );
	else
		provideFields ( Fields );
	endif; 
	
EndProcedure 
