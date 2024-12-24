&AtClient
var CurrentData;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadItems ();
	
EndProcedure

&AtServer
Procedure loadItems ()
	
	document = Parameters.Document;
	s = "
	|select Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	Items.Package as Package, 1 as Quantity, false as Print
	|from Document." + document.Metadata ().Name + ".Items as Items
	|where Items.Ref = &Ref
	|order by Items.LineNumber
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", document );
	Object.Items.Load ( q.Execute ().Unload () );
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( nothingSelected () ) then
		Cancel = true;
	endif;
	
EndProcedure

&AtServer
Function nothingSelected ()
	
	for each row in Object.Items do
		if ( row.Print ) then
			return false;
		endif;
	enddo;
	Output.BarcodeNothingToPrint ( , "Items[0].Print" );
	return true;
	
EndFunction

// *****************************************
// *********** Group Form

&AtClient
Procedure Print ( Command )

	if ( not CheckFilling () ) then
		return;
	endif;
	p = Print.GetParams ();
	p.Manager = "DataProcessors.PrintBarcodes";
	p.Objects = Object.Items;
	p.Key = "Barcodes";
	p.Template = "Template";
	Print.Print ( p );
	Close ();

EndProcedure

// *****************************************
// *********** Items Table

&AtClient
Procedure MarkAll ( Command )
	
	mark ( true );
	
EndProcedure

&AtClient
Procedure UnmarkAll ( Command )
	
	mark ( false );
	
EndProcedure

&AtClient
Procedure mark ( Flag )
	
	for each row in Object.Items do
		row.Print = Flag;
		adjustQuantity ( row );
	enddo; 
	
EndProcedure

&AtClient
Procedure adjustQuantity ( Row )
	
	if ( Row.Print and Row.Quantity = 0 ) then
		Row.Quantity = 1;
	endif;
	
EndProcedure

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	CurrentData = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ItemsPrintOnChange ( Item )
	
	adjustQuantity ( CurrentData );
	
EndProcedure

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	CurrentData.Print = CurrentData.Quantity <> 0;
	
EndProcedure
