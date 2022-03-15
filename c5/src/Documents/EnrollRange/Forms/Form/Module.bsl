// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing)
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.Init ( Object );
		fillNew ();
		Constraints.ShowAccess ( ThisObject );
	endif;
	setRangeOnline ( ThisObject );
	Options.Company ( ThisObject, Object.Company );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtClientAtServerNoContext
Procedure setRangeOnline ( Form )
	
	Form.RangeOnline = DF.Pick ( Form.Object.Range, "Online" );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Warehouse hide RangeOnline
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif;
	settings = Logins.Settings ( "Company, Warehouse" );
	Object.Company = settings.Company;
	Object.Warehouse = settings.Warehouse;
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	updateBalances ();
	
EndProcedure

&AtClient
Procedure updateBalances ()
	
	NotifyChanged ( Object.Range );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure RangeStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	chooseRange ( Item );
	
EndProcedure

&AtClient
Procedure chooseRange ( Item )
	
	filter = new Structure ();
	date = Periods.GetBalanceDate ( Object );
	if ( date <> undefined
		and not Object.Ref.IsEmpty () ) then
		date = date - 1;
	endif;
	filter.Insert ( "Date", date );
	filter.Insert ( "Real", false );
	filter.Insert ( "Company", Object.Company );
	p = new Structure ( "Filter", filter );
	OpenForm ( "Catalog.Ranges.Form.New", p, Item );
	
EndProcedure

&AtClient
Procedure RangeOnChange ( Item )
	
	setRangeOnline ( ThisObject );
	
EndProcedure
