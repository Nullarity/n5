&AtServer
var Copy;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		Object.Simple = true;
		DocumentForm.Init ( Object );
		Copy = not Parameters.CopyingValue.IsEmpty ();
		if ( not Copy ) then
			loadParams ();
		endif; 
		fillNew ();
	endif; 
	setFilters ();
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	row = Object.Items.Add ();
	row.Item = Parameters.Item;
	
EndProcedure 

&AtServer
Procedure fillNew ()
	
	Object.Date = BegOfDay ( CurrentSessionDate () );
	if ( Object.Date > Object.DateTo ) then
		Object.DateTo = undefined;
	endif; 
	if ( Copy ) then
		return;
	endif;
	settings = Logins.Settings ( "Company" );
	Object.Company = settings.Company;
	Object.Items [ 0 ].Prices = findPrices ();
	setPackage ( ThisObject );
	
EndProcedure 

&AtServer
Function findPrices ()
	
	s = "
	|select top 1 Prices.Ref as Ref
	|from Catalog.Prices as Prices
	|where not Prices.DeletionMark
	|and Prices.Owner = &Company
	|and Prices.Pricing = value ( Enum.Pricing.Base )
	|and Prices.Ref not in ( select CostPrices from Catalog.Companies where Ref = &Company )
	|order by Prices.Code
	|";
	q = new Query ( s );
	q.SetParameter ( "Company", Object.Company );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
EndFunction 

&AtClientAtServerNoContext
Procedure setPackage ( Form )
	
	row = Form.Object.Items [ 0 ];
	row.Package = DF.Pick ( row.Item, "Package" );
	
EndProcedure 

&AtServer
Procedure setFilters ()
	
	row = Object.Items [ 0 ];
	a = new Array ();
	a.Add ( new ChoiceParameter ( "Filter.Owner", row.Item ) );
	Items.ItemsPackage.ChoiceParameters = new FixedArray ( a );
	Items.ItemsFeature.ChoiceParameters = new FixedArray ( a );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure ItemsItemOnChange ( Item )
	
	setPackage ( ThisObject );
	
EndProcedure
