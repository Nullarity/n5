&AtClient
var TableRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	fill ();
	activateRow ();
	
EndProcedure

&AtServer
Procedure fill ()
	
	t = Catalogs.Currencies.GetTemplate ( "Classifier" );
	height = t.TableHeight;
	for i = 2 to height do
		row = List.Add ();
		row.Currency = TrimAll ( t.Area ( i, 1, i, 1 ).Text );
		row.Code = TrimAll ( t.Area ( i, 2, i, 2 ).Text );
		row.ID = TrimAll ( t.Area ( i, 3, i, 3 ).Text );
	enddo; 
	
EndProcedure 

&AtServer
Procedure activateRow ()
	
	code = undefined;
	Parameters.Property ( "FillingText", code );
	if ( code = undefined ) then
		return;
	endif; 
	for each row in List do
		if ( StrStartsWith ( row.Code, Upper ( code ) ) ) then
			Items.List.CurrentRow = row.GetID ();
			break;
		endif; 
	enddo; 
	
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
	
	p = Collections.GetFields ( TableRow, "Code, Currency, ID" );
	currency = getCurrency ( p );
	NotifyWritingNew ( currency );
	NotifyChoice ( currency );
	
EndProcedure 

&AtServerNoContext
Function getCurrency ( val Params )
	
	id = Params.ID;
	ref = Catalogs.Currencies.FindByCode ( id );	
	if ( ref.IsEmpty () ) then
		obj = Catalogs.Currencies.CreateItem ();
		obj.Code = id;
		obj.Description = Params.Code;
		obj.FullDescription = Params.Currency;
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
Procedure ListValueChoice ( Item, Value, StandardProcessing )
	
	choose ();
	
EndProcedure
