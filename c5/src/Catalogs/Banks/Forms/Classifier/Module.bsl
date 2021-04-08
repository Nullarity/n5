&AtClient
var TableRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	activateRow ();
	
EndProcedure

&AtServer
Procedure activateRow ()
	
	description = undefined;
	Parameters.Property ( "FillingText", description );
	if ( description = undefined ) then
		return;
	endif;
	Items.List.CurrentRow = Catalogs.BanksClassifier.FindByDescription ( description );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure Select ( Command )
	
	if ( TableRow = undefined ) then
		return;
	endif; 
	choose ();
	
EndProcedure

&AtClient
Procedure choose ()
	
	p = Collections.GetFields ( TableRow, "Code, Description" );
	bank = getBank ( p );
	NotifyWritingNew ( bank );
	NotifyChoice ( bank );
	
EndProcedure 

&AtServerNoContext
Function getBank ( val Params )
	
	code = Params.Code;
	ref = Catalogs.Banks.FindByCode ( code );	
	if ( ref.IsEmpty () ) then
		obj = Catalogs.Banks.CreateItem ();
		obj.Code = code;
		obj.Description = Params.Description;
		obj.Write ();
		return obj.Ref;
	else
		return ref;
	endif; 
	
EndFunction 

// *****************************************
// *********** Table List

&AtClient
Procedure ListOnActivateRow ( Item )
	
	TableRow = Items.List.CurrentData;
	
EndProcedure

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	choose ();
	
EndProcedure
