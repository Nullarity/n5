&AtServer
var Env;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	fillItems ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|ItemsQuantity show Distribution = Enum.Distribution.Quantity;
	|ItemsWeight show Distribution = Enum.Distribution.Weight
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadParams () 

	Distribution = Parameters.Distribution;

EndProcedure

&AtServer
Procedure fillItems () 

	setEnv ();
	sqlItems ();
	getItems ();
	itemsByInvoice ();

EndProcedure

&AtServer
Procedure setEnv () 

	Env = new Structure ();
	SQL.Init ( Env );

EndProcedure

&AtServer
Procedure sqlItems ()
	
	s = "
	|// Items
	|select Items.CustomsGroup as CustomsGroup, Items.Invoice as Invoice, Items.Item as Item, sum ( Items.Quantity ) as Quantity, 
	|	sum ( Items.Amount ) as Amount,	sum ( Items.Weight ) as Weight
	|into Items
	|from ( 
	|	select 
	|		case when Details.Item.CustomsGroup = value ( Catalog.CustomsGroups.EmptyRef ) then &CustomsGroup
	|			else Details.Item.CustomsGroup
	|		end as CustomsGroup, Cost.Recorder as Invoice, Details.Item as Item, Cost.Quantity as Quantity, Cost.Amount as Amount, 
	|		Details.Item.Weight * Cost.Quantity as Weight
	|	from AccumulationRegister.Cost as Cost
	|		//
	|		// Details
	|		//
	|		join InformationRegister.ItemDetails as Details
	|		on Details.ItemKey = Cost.ItemKey
	|	where Cost.Recorder = &Invoice
	|	and Details.Item.CustomsGroup in ( &CustomsGroup, value ( Catalog.CustomsGroups.EmptyRef ) )
	|	and Cost.Dependency <> &Ref
	|	) as Items
	|group by Items.CustomsGroup, Items.Invoice, Items.Item
	|;
	|// #Items
	|select Items.CustomsGroup as CustomsGroup, Items.Invoice as Invoice, Items.Item as Item, Items.Quantity as Quantity, Items.Amount as Amount,
	|	Items.Weight as Weight, true as Select
	|from Items as Items
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure getItems () 

	q = Env.Q;
	q.SetParameter ( "Invoice", Parameters.VendorInvoice );
	q.SetParameter ( "CustomsGroup", Parameters.CustomsGroup );
	q.SetParameter ( "Ref", Parameters.CustomsDeclaration );
	SQL.Perform ( Env );

EndProcedure

&AtServer
Procedure itemsByInvoice ()
	
	table = Env.Items;
	if ( table.Count () = 0 ) then
		raise OutputCont.ItemsNotFoundByCustomsGroup ( new Structure ( "CustomsGroup, Invoice", Parameters.CustomsGroup, Parameters.VendorInvoice ) );
	endif;
	tableItems = Object.Items;
	for each row in table do
		newRow = tableItems.Add ();
		FillPropertyValues ( newRow, row );
	enddo;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure Select ( Command )
	
	table = Object.Items.FindRows ( new Structure ( "Select", true ) );
	p = new Structure ( "Items, Clear", table, Clear );
	NotifyChoice ( p );
	
EndProcedure

&AtClient
Procedure MarkAll ( Command )
	
	mark ( true );
	
EndProcedure

&AtClient
Procedure mark ( Flag ) 

	for each row in Object.Items do
		row.Select = Flag;
	enddo;

EndProcedure

&AtClient
Procedure UnmarkAll ( Command )
	
	mark ( false );
	
EndProcedure
