// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	applyParams ();
	initFlags ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
		
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|NewPrices enable Object.SetNewPrices
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure applyParams ()
	
	Object.Company = Parameters.Company;
	
EndProcedure 

&AtServer
Procedure initFlags ()
	
	Object.CalcPrices = true;
	Object.UseServicesTable = true;
	Object.UseItemsTable = true;
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure Calc ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif; 
	NotifyChoice ( getOutgoingParams () );
	
EndProcedure

&AtClient
Function getOutgoingParams ()
	
	p = new Structure ();
	p.Insert ( "Operation", "Prices" );
	p.Insert ( "CalcPrices", Object.CalcPrices );
	p.Insert ( "SetNewPrices", Object.SetNewPrices );
	p.Insert ( "NewPrices", Object.NewPrices );
	p.Insert ( "UseItemsTable", Object.UseItemsTable );
	p.Insert ( "UseServicesTable", Object.UseServicesTable );
	return p;
	
EndFunction

&AtClient
Procedure SetNewPricesOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Object.SetNewPrices" );
	
EndProcedure
