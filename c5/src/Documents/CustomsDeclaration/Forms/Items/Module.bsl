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
	Object.Items.Load ( Env.Items );

EndProcedure

&AtServer
Procedure setEnv () 

	Env = new Structure ();
	SQL.Init ( Env );

EndProcedure

&AtServer
Procedure sqlItems ()
	
	s = "
	|// #Items
	|select Cost.Recorder as Invoice, Details.Item as Item, Cost.Quantity as Quantity, Cost.Amount as Amount, 
	|	Details.Item.Weight * Cost.Quantity as Weight, AlreadySelected.Ref is null as Select,
	|	AlreadySelected.Ref is not null as Added
	|from AccumulationRegister.Cost as Cost
	|	//
	|	// Details
	|	//
	|	join InformationRegister.ItemDetails as Details
	|	on Details.ItemKey = Cost.ItemKey
	|	//
	|	// Already Selected
	|	//
	|	left join Catalog.Items as AlreadySelected
	|	on AlreadySelected.Ref in ( &AlreadySelected )
	|	and AlreadySelected.Ref = Details.Item
	|where Cost.Recorder = &Invoice
	|and Cost.Dependency <> &Ref
	|order by Select desc, Details.Item.Description
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure getItems () 

	q = Env.Q;
	q.SetParameter ( "Invoice", Parameters.VendorInvoice );
	q.SetParameter ( "CustomsGroup", Parameters.CustomsGroup );
	q.SetParameter ( "Ref", Parameters.CustomsDeclaration );
	q.SetParameter ( "AlreadySelected", Parameters.AlreadySelected );
	SQL.Perform ( Env );

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
