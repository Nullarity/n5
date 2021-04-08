// *****************************************
// *********** Form events

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageBarcodeScanned ()
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		install ( Parameter );
	endif; 
	
EndProcedure

&AtClient
Procedure install ( Fields )
	
	if ( Fields.Item = undefined ) then
		assign ( Fields.Barcode );
	else
		if ( Fields.Item = undefined ) then
			assign ( Fields.Barcode );
		else
			p = new Structure ( "Item", Print.FormatItem ( Fields.Item, Fields.Package, Fields.Feature, , Fields.Code ) );
			Output.ReplaceBarcode ( ThisObject, Fields.Barcode, p );
		endif; 
	endif; 
	
EndProcedure 

&AtClient
Procedure assign ( Barcode )
	
	Record.Barcode = Barcode;
	
EndProcedure 

&AtClient
Procedure ReplaceBarcode ( Answer, Barcode ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	detach ( Barcode );
	assign ( Barcode );
	
EndProcedure 

&AtServerNoContext
Procedure detach ( val Barcode )
	
	r = InformationRegisters.Barcodes.CreateRecordManager ();
	r.Barcode = Barcode;
	r.Delete ();
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure Scan ( Command )
	
	OpenForm ( "CommonForm.Scan", new Structure ( "JustScan", true ), ThisObject );
	
EndProcedure

&AtClient
Procedure NewEAN13 ( Command )
	
	Record.Barcode = getEAN13 ();
	
EndProcedure

&AtServerNoContext
Function getEAN13 ()
	
	next = Min ( getMax () + 1, 99999999 );
	return convertToCode ( next );

EndFunction

&AtServerNoContext
Function getMax ( UnitPrefix = "0", InternalPrefix = "00" )

	s = "
	|select max ( substring ( Barcodes.Barcode, 5, 8 ) ) as Code
	|from InformationRegister.Barcodes as Barcodes
	|where Barcodes.Barcode like ""2" + UnitPrefix + InternalPrefix + "_________""
	|";
	q = new Query ( s );
	selection = q.Execute ().Select ();
	selection.Next ();
	numberType = new TypeDescription ( "Number" );
	result = numberType.AdjustValue ( selection.Code );
	return result;

EndFunction

&AtServerNoContext
Function convertToCode ( Next, UnitPrefix = "0", InternalPrefix = "00" )

	barcode = "2" + UnitPrefix + InternalPrefix + Format ( Next, "ND=8; NLZ=; NG=");
	barcode = barcode + symbol ( barcode, 13 );
	return barcode;

EndFunction

&AtServerNoContext
Function symbol ( Barcode, Class )

	even = 0;
	odd = 0;
	count = ? ( Class = 13, 6, 4);
	for i = 1 to count do
		if ( Class <> 8
			or i <> count) then
			even = even + Number ( Mid ( Barcode, 2 * i, 1 ) );
		endif;
		odd = odd + Number ( Mid ( Barcode, 2 * i - 1, 1 ) );
	enddo;
	if ( Class = 13 ) then
		even = even * 3;
	else
		odd = odd * 3;
	endif;
	control = 10 - ( even + odd ) % 10;
	return ? ( control = 10, "0", String ( control ) );

EndFunction
