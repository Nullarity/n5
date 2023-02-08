// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	Options.SetAccuracy ( ThisObject, "Quantity, QuantityPkg", false );
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	Item = Parameters.Item;
	Feature = Parameters.Feature;
	Package = Parameters.Package;
	Quantity = Parameters.Quantity;
	QuantityPkg = Parameters.QuantityPkg;
	Capacity = Parameters.Capacity;
	Code = Parameters.Code;
	Barcode = Parameters.Barcode;
	
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
	p.Insert ( "Feature", Feature );
	p.Insert ( "Package", Package );
	p.Insert ( "Quantity", Quantity );
	p.Insert ( "QuantityPkg", QuantityPkg );
	p.Insert ( "Capacity", Capacity );
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
