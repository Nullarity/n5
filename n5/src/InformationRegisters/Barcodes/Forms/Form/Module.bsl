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
			p = new Structure ( "Item",
				Print.FormatItem ( Fields.Item, Fields.Package, Fields.Feature, Fields.Series, Fields.Code ) );
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
	
	ScanForm.Scan ( ThisObject );
	
EndProcedure

&AtClient
Procedure NewEAN13 ( Command )
	
	Record.Barcode = Goods.NewEAN13 ();
	
EndProcedure
