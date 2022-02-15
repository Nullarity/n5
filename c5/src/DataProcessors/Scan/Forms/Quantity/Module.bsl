// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	setAccuracy ();
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	FillPropertyValues ( ThisObject, Parameters.ScanResult );
	Capacity = DF.Pick ( Package, "Capacity", 1 );
	
EndProcedure

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "Quantity, QuantityPkg" );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	p = getParams ();
	Close ( p );
	
EndProcedure

&AtClient
Function getParams ()
	
	p = new Structure ();
	p.Insert ( "Item", Item );
	p.Insert ( "Series", Series );
	p.Insert ( "Package", Package );
	p.Insert ( "Quantity", Quantity );
	p.Insert ( "Capacity", Capacity );
	p.Insert ( "QuantityPkg", QuantityPkg );
	p.Insert ( "Code", Code );
	p.Insert ( "Barcode", Barcode );
	return p;
	
EndFunction 

&AtClient
Procedure QuantityPkgOnChange ( Item )

	Computations.Units ( ThisObject );

EndProcedure

&AtClient
Procedure QuantityOnChange ( Item )

	Computations.Packages ( ThisObject );

EndProcedure
