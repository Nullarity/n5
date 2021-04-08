// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing)
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.Init ( Object );
		fillNew ();
	endif; 
	Options.Company ( ThisObject, Object.Company );
	
EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif;
	settings = Logins.Settings ( "Company, Warehouse" );
	Object.Company = settings.Company;
	Object.Sender = settings.Warehouse;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure RangeStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	choose ( Item );
	
EndProcedure

&AtClient
Procedure choose ( Item )
	
	filter = new Structure ();
	filter.Insert ( "Warehouse", Object.Sender );
	date = Periods.GetBalanceDate ( Object );
	if ( date <> undefined
		and not Object.Ref.IsEmpty () ) then
		date = date - 1;
	endif;
	filter.Insert ( "Date", date );
	filter.Insert ( "Real", false );
	OpenForm ( "Catalog.Ranges.Form.Balances", new Structure ( "Filter", filter ), Item );
	
EndProcedure
