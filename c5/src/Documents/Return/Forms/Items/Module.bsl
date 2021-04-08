&AtServer
var Env;
&AtClient
var ItemsRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	setAccuracy ();
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	Document = Parameters.Return; 
	Invoice = Parameters.Invoice;
	Object.VATUse = Invoice.VATUse;
	
EndProcedure

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg" );
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	loadData ();
	fill ();
	if ( Object.Items.Count () = 0 ) then
		OutputCont.NoItemsToReturn ( new Structure ( "Document", Invoice ), , Invoice );
		Close ();			
	endif;
	
EndProcedure

&AtClient
Procedure loadData ()
	
	owner = FormOwner.Object;
	table = Object.Items;
	for each row in owner.Items do
		newRow = table.Add ();
		FillPropertyValues ( newRow, row ); 
	enddo;
	
EndProcedure

&AtServer
Procedure fill ()

	setEnv ();
	getData ();
	fillItems ();

EndProcedure

&AtServer
Procedure setEnv ()

	Env = new Structure ();
	SQL.Init ( Env );

EndProcedure

&AtServer
Procedure getData ()
	
	sqlItems ();
	getTables ();
	
EndProcedure

&AtServer
Procedure sqlItems ()
	
	salesOrder = "case when Items.SalesOrder = value ( Document.SalesOrder.EmptyRef ) then Items.Ref.SalesOrder else Items.SalesOrder end";
	s = "
	|// Existed
	|select Items.Invoice as Invoice, Items.Item as Item, Items.Feature as Feature, 
	|	Items.Series as Series, Items.SalesOrder as SalesOrder, Items.RowKey as RowKey,
	|	Items.Quantity as Quantity
	|into Existed
	|from &Items as Items
	|where Items.Invoice = &Invoice
	|;
	|// Returned
	|select Items.Invoice as Invoice, Items.Item as Item, Items.Feature as Feature, 
	|	Items.Series as Series, Items.SalesOrder as SalesOrder, Items.RowKey as RowKey,
	|	Items.Quantity as Quantity
	|into Returned
	|from Document.Return.Items as Items
	|where Items.Ref.Posted
	|and Items.Ref <> &Return
	|and Items.Invoice = &Invoice
	|;
	|// #Items
	|select true as Select, Items.Ref as Invoice, Items.Account as Account, Items.Amount as Amount, Items.Capacity as Capacity,
	|	Items.Discount as Discount, Items.DiscountRate as DiscountRate, Items.ExtraCharge as ExtraCharge, Items.Feature as Feature, 
	|	Items.Income as Income, Items.Item as Item, Items.Package as Package, Items.Price as Price, Items.Prices as Prices, Items.ProducerPrice as ProducerPrice,
	|	Items.Quantity - isnull ( Existed.Quantity, 0 ) - isnull ( Returned.Quantity, 0 ) as Quantity, Items.QuantityPkg as QuantityPkg, 
	|	Items.RowKey as RowKey, Items.SalesCost as SalesCost, " + salesOrder + " as SalesOrder, Items.Series as Series, Items.Social as Social, 
	|	Items.Total as Total, Items.VAT as VAT, Items.VATAccount as VATAccount, Items.VATCode as VATCode, Items.VATRate as VATRate, Items.Warehouse as Warehouse
	|from Document.Invoice.Items as Items
	|	//
	|	// Existed
	|	//
	|	left join Existed as Existed
	|	on Existed.Invoice = Items.Ref
	|	and Existed.Item = Items.Item
	|	and Existed.Feature = Items.Feature
	|	and Existed.Series = Items.Series
	|	and Existed.SalesOrder = " + salesOrder + "
	|	and Existed.RowKey = Items.RowKey
	|	//
	|	// Returned
	|	//
	|	left join Returned as Returned
	|	on Returned.Invoice = Items.Ref
	|	and Returned.Item = Items.Item
	|	and Returned.Feature = Items.Feature
	|	and Returned.Series = Items.Series
	|	and Returned.SalesOrder = " + salesOrder + "
	|	and Returned.RowKey = Items.RowKey
	|where Items.Ref = &Invoice
	|and Items.Quantity - isnull ( Existed.Quantity, 0 ) - isnull ( Returned.Quantity, 0 ) > 0
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure getTables ()

	q = Env.Q;
	q.SetParameter ( "Invoice", Invoice );
	q.SetParameter ( "Return", Document );
	q.SetParameter ( "Items", Object.Items.Unload () );
	SQL.Perform ( Env );

EndProcedure

&AtServer
Procedure fillItems ()
	
	source = Env.Items;
	receiver = Object.Items;
	receiver.Clear ();
	vatUse = Object.VATUse; 
	for each row in source do
		newRow = receiver.Add ();
		FillPropertyValues ( newRow, row );
		Computations.Packages ( newRow );
		Computations.Amount ( newRow );
		Computations.Total ( newRow, vatUse );
	enddo;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure Select ( Command )
	
	p = new Structure ( "Items" );
	p.Items = Object.Items.FindRows ( new Structure ( "Select", true ) );
	NotifyChoice ( p );
	
EndProcedure

// *****************************************
// *********** Table Items

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

&AtClient
Procedure ItemsTableOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ItemsQuantityPkgOnChange ( Item )
	
	Computations.Units ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure
