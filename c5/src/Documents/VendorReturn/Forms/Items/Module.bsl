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
	
	VendorInvoice = Parameters.VendorInvoice;
	VendorReturn = Parameters.VendorReturn;
	Object.VATUse = VendorInvoice.VATUse;
	
EndProcedure

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg, AccountsQuantity" );
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	loadData ();
	fillTables ();
	if ( emptyTables () ) then
		Output.NoItemsToReturn ( new Structure ( "Document", VendorInvoice ), , VendorInvoice );
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
	table = Object.FixedAssets;
	for each row in owner.FixedAssets do
		newRow = table.Add ();
		FillPropertyValues ( newRow, row ); 
	enddo;
	table = Object.IntangibleAssets;
	for each row in owner.IntangibleAssets do
		newRow = table.Add ();
		FillPropertyValues ( newRow, row ); 
	enddo;
	table = Object.Accounts;
	for each row in owner.Accounts do
		newRow = table.Add ();
		FillPropertyValues ( newRow, row ); 
	enddo;
	
EndProcedure

&AtServer
Procedure fillTables ()

	setEnv ();
	getData ();
	fillItems ();
	fillFixedAssets ();
	fillIntangibleAssets ();
	fillAccounts ();
	Forms.ActivatePage ( ThisObject, "ItemsTable,FixedAssets,IntangibleAssets,Accounts" );

EndProcedure

&AtServer
Procedure setEnv ()

	Env = new Structure ();
	SQL.Init ( Env );

EndProcedure

&AtServer
Procedure getData ()
	
	sqlItems ();
	sqlFixedAssets ();
	sqlIntangibleAssets ();
	sqlAccounts ();
	getTables ();
	
EndProcedure

&AtServer
Procedure sqlItems ()
	
	purchaseOrder = "case when Items.PurchaseOrder = value ( Document.PurchaseOrder.EmptyRef ) then Items.Ref.PurchaseOrder else Items.PurchaseOrder end";
	s = "
	|// ExistedItems
	|select Items.VendorInvoice as VendorInvoice, Items.Item as Item, Items.Feature as Feature, 
	|	Items.Series as Series, Items.PurchaseOrder as PurchaseOrder, Items.RowKey as RowKey,
	|	Items.DocumentOrder as DocumentOrder, Items.DocumentOrderRowKey as DocumentOrderRowKey, 
	|	Items.Quantity as Quantity
	|into ExistedItems
	|from &Items as Items
	|where Items.VendorInvoice = &VendorInvoice
	|;
	|// ReturnedItems
	|select Items.VendorInvoice as VendorInvoice, Items.Item as Item, Items.Feature as Feature, 
	|	Items.Series as Series, Items.PurchaseOrder as PurchaseOrder, Items.RowKey as RowKey,
	|	Items.DocumentOrder as DocumentOrder, Items.DocumentOrderRowKey as DocumentOrderRowKey, 
	|	Items.Quantity as Quantity
	|into ReturnedItems
	|from Document.VendorReturn.Items as Items
	|where Items.VendorInvoice = &VendorInvoice
	|and Items.Ref.Posted
	|and Items.Ref <> &VendorReturn
	|;
	|// #Items
	|select true as Select, Items.Ref as VendorInvoice, Items.Account as Account, Items.Amount as Amount, Items.Capacity as Capacity,
	|	Items.Discount as Discount, Items.DiscountRate as DiscountRate, Items.DocumentOrder as DocumentOrder,
	|	Items.DocumentOrderRowKey as DocumentOrderRowKey, Items.Feature as Feature, Items.Item as Item,
	|	Items.Price as Price, Items.Package as Package, Items.Prices as Prices, Items.ProducerPrice as ProducerPrice,
	|	" + purchaseOrder + " as PurchaseOrder, Items.Quantity - isnull ( Existed.Quantity, 0 ) - isnull ( Returned.Quantity, 0 ) as Quantity, 
	|	Items.QuantityPkg as QuantityPkg, Items.RowKey as RowKey, Items.Series as Series, Items.Social as Social, Items.Total as Total,
	|	Items.VAT as VAT, Items.VATAccount as VATAccount, Items.VATCode as VATCode,
	|	Items.VATRate as VATRate, Items.Warehouse as Warehouse
	|from Document.VendorInvoice.Items as Items
	|	//
	|	// Existed
	|	//
	|	left join ExistedItems as Existed
	|	on Existed.VendorInvoice = Items.Ref
	|	and Existed.Item = Items.Item
	|	and Existed.Feature = Items.Feature
	|	and Existed.Series = Items.Series
	|	and Existed.PurchaseOrder = " + purchaseOrder + "
	|	and Existed.RowKey = Items.RowKey
	|	and Existed.DocumentOrder = Items.DocumentOrder
	|	and Existed.DocumentOrderRowKey = Items.DocumentOrderRowKey
	|	//
	|	// Returned
	|	//
	|	left join ReturnedItems as Returned
	|	on Returned.VendorInvoice = Items.Ref
	|	and Returned.Item = Items.Item
	|	and Returned.Feature = Items.Feature
	|	and Returned.Series = Items.Series
	|	and Returned.PurchaseOrder = " + purchaseOrder + "
	|	and Returned.RowKey = Items.RowKey
	|	and Returned.DocumentOrder = Items.DocumentOrder
	|	and Returned.DocumentOrderRowKey = Items.DocumentOrderRowKey
	|where Items.Ref = &VendorInvoice
	|and Items.Quantity - isnull ( Existed.Quantity, 0 ) - isnull ( Returned.Quantity, 0 ) > 0
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure sqlFixedAssets ()
	
	s = "
	|// ExistedFixedAssets
	|select FixedAssets.VendorInvoice as VendorInvoice, FixedAssets.Item as Item	
	|into ExistedFixedAssets
	|from &FixedAssets as FixedAssets
	|where FixedAssets.VendorInvoice = &VendorInvoice
	|;
	|// ReturnedFixedAssets
	|select FixedAssets.VendorInvoice as VendorInvoice, FixedAssets.Item as Item	
	|into ReturnedFixedAssets
	|from Document.VendorReturn.FixedAssets as FixedAssets
	|where FixedAssets.VendorInvoice = &VendorInvoice
	|and FixedAssets.Ref.Posted
	|and FixedAssets.Ref <> &VendorReturn
	|;
	|// #FixedAssets
	|select true as Select, FixedAssets.Ref as VendorInvoice, FixedAssets.Amount as Amount, FixedAssets.Item as Item, 
	|	FixedAssets.Total as Total, FixedAssets.VAT as VAT, FixedAssets.VATAccount as VATAccount,
	|	FixedAssets.VATCode as VATCode, FixedAssets.VATRate as VATRate
	|from Document.VendorInvoice.FixedAssets as FixedAssets
	|	//
	|	// Existed
	|	//
	|	left join ExistedFixedAssets as Existed
	|	on Existed.VendorInvoice = FixedAssets.Ref
	|	and Existed.Item = FixedAssets.Item
	|	//
	|	// Returned
	|	//
	|	left join ReturnedFixedAssets as Returned
	|	on Returned.VendorInvoice = FixedAssets.Ref
	|	and Returned.Item = FixedAssets.Item
	|where FixedAssets.Ref = &VendorInvoice
	|and Existed.Item is null
	|and Returned.Item is null
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure sqlIntangibleAssets ()
	
	s = "
	|// ExistedIntangibleAssets
	|select IntangibleAssets.VendorInvoice as VendorInvoice, IntangibleAssets.Item as Item	
	|into ExistedIntangibleAssets
	|from &IntangibleAssets as IntangibleAssets
	|where IntangibleAssets.VendorInvoice = &VendorInvoice
	|;
	|// ReturnedIntangibleAssets
	|select IntangibleAssets.VendorInvoice as VendorInvoice, IntangibleAssets.Item as Item	
	|into ReturnedIntangibleAssets
	|from Document.VendorReturn.IntangibleAssets as IntangibleAssets
	|where IntangibleAssets.VendorInvoice = &VendorInvoice
	|and IntangibleAssets.Ref.Posted
	|and IntangibleAssets.Ref <> &VendorReturn
	|;
	|// #IntangibleAssets
	|select true as Select, IntangibleAssets.Ref as VendorInvoice, IntangibleAssets.Amount as Amount, IntangibleAssets.Item as Item, 
	|	IntangibleAssets.Total as Total, IntangibleAssets.VAT as VAT, IntangibleAssets.VATAccount as VATAccount, 
	|	IntangibleAssets.VATCode as VATCode, IntangibleAssets.VATRate as VATRate
	|from Document.VendorInvoice.IntangibleAssets as IntangibleAssets
	|	//
	|	// Existed
	|	//
	|	left join ExistedIntangibleAssets as Existed
	|	on Existed.VendorInvoice = IntangibleAssets.Ref
	|	and Existed.Item = IntangibleAssets.Item
	|	//
	|	// Returned
	|	//
	|	left join ReturnedIntangibleAssets as Returned
	|	on Returned.VendorInvoice = IntangibleAssets.Ref
	|	and Returned.Item = IntangibleAssets.Item
	|where IntangibleAssets.Ref = &VendorInvoice
	|and Existed.Item is null
	|and Returned.Item is null
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure sqlAccounts ()
	
	s = "
	|// ExistedAccounts
	|select Accounts.VendorInvoice as VendorInvoice, Accounts.Account as Account, Accounts.Dim1 as Dim1,
	|	Accounts.Dim2 as Dim2, Accounts.Dim3 as Dim3, Accounts.Quantity as Quantity
	|into ExistedAccounts
	|from &Accounts as Accounts
	|where Accounts.VendorInvoice = &VendorInvoice
	|;
	|// ReturnedAccounts
	|select Accounts.VendorInvoice as VendorInvoice, Accounts.Account as Account, Accounts.Dim1 as Dim1,
	|	Accounts.Dim2 as Dim2, Accounts.Dim3 as Dim3, Accounts.Quantity as Quantity
	|into ReturnedAccounts
	|from Document.VendorReturn.Accounts as Accounts
	|where Accounts.VendorInvoice = &VendorInvoice
	|and Accounts.Ref.Posted
	|and Accounts.Ref <> &VendorReturn
	|;
	|// #Accounts
	|select true as Select, Accounts.Ref as VendorInvoice, Accounts.Account as Account, Accounts.Amount as Amount, 
	|	Accounts.Content as Content, Accounts.Currency as Currency, Accounts.CurrencyAmount as CurrencyAmount, Accounts.Dim1 as Dim1,
	|	Accounts.Dim2 as Dim2, Accounts.Dim3 as Dim3, Accounts.Factor as Factor, 
	|	Accounts.Quantity - isnull ( Existed.Quantity, 0 ) - isnull ( Returned.Quantity, 0 ) as Quantity,
	|	Accounts.Rate as Rate, Accounts.Total as Total, Accounts.VAT as VAT, Accounts.VATAccount as VATAccount,
	|	Accounts.VATCode as VATCode, Accounts.VATRate as VATRate
	|from Document.VendorInvoice.Accounts as Accounts
	|	//
	|	// Existed
	|	//
	|	left join ExistedAccounts as Existed
	|	on Existed.VendorInvoice = Accounts.Ref
	|	and Existed.Account = Accounts.Account
	|	and Existed.Dim1 = Accounts.Dim1
	|	and Existed.Dim2 = Accounts.Dim2
	|	and Existed.Dim3 = Accounts.Dim3
	|	//
	|	// Returned
	|	//
	|	left join ReturnedAccounts as Returned
	|	on Returned.VendorInvoice = Accounts.Ref
	|	and Returned.Account = Accounts.Account
	|	and Returned.Dim1 = Accounts.Dim1
	|	and Returned.Dim2 = Accounts.Dim2
	|	and Returned.Dim3 = Accounts.Dim3
	|where Accounts.Ref = &VendorInvoice
	|and Accounts.Quantity - isnull ( Existed.Quantity, 0 ) - isnull ( Returned.Quantity, 0 ) > 0
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure getTables ()

	q = Env.Q;
	q.SetParameter ( "VendorInvoice", VendorInvoice );
	q.SetParameter ( "VendorReturn", VendorReturn );
	q.SetParameter ( "Items", Object.Items.Unload () );
	q.SetParameter ( "FixedAssets", Object.FixedAssets.Unload () );
	q.SetParameter ( "IntangibleAssets", Object.IntangibleAssets.Unload () );
	q.SetParameter ( "Accounts", Object.Accounts.Unload () );
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

&AtServer
Procedure fillFixedAssets ()
	
	source = Env.FixedAssets;
	receiver = Object.FixedAssets;
	receiver.Clear ();
	for each row in source do
		newRow = receiver.Add ();
		FillPropertyValues ( newRow, row );
	enddo;
	
EndProcedure

&AtServer
Procedure fillIntangibleAssets ()
	
	source = Env.IntangibleAssets;
	receiver = Object.IntangibleAssets;
	receiver.Clear ();
	for each row in source do
		newRow = receiver.Add ();
		FillPropertyValues ( newRow, row );
	enddo;
	
EndProcedure

&AtServer
Procedure fillAccounts ()
	
	source = Env.Accounts;
	receiver = Object.Accounts;
	receiver.Clear ();
	for each row in source do
		newRow = receiver.Add ();
		FillPropertyValues ( newRow, row );
	enddo;
	
EndProcedure

&AtClient
Function emptyTables ()
	
	return Object.Items.Count () = 0
	and Object.FixedAssets.Count () = 0
	and Object.IntangibleAssets.Count () = 0
	and Object.Accounts.Count () = 0;
	
EndFunction

// *****************************************
// *********** Table Items

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

// *****************************************
// *********** Group Form

&AtClient
Procedure Select ( Command )
	
	p = new Structure ( "Items, FixedAssets, IntangibleAssets, Accounts" );
	p.Items = Object.Items.FindRows ( new Structure ( "Select", true ) );
	p.FixedAssets = Object.FixedAssets.FindRows ( new Structure ( "Select", true ) );
	p.IntangibleAssets = Object.IntangibleAssets.FindRows ( new Structure ( "Select", true ) );
	p.Accounts = Object.Accounts.FindRows ( new Structure ( "Select", true ) );
	NotifyChoice ( p );
	
EndProcedure

&AtClient
Procedure MarkAll ( Command )
	
	tableName = StrReplace ( Command.Name, "MarkAll", "" );
	table = Object [ tableName ];
	mark ( table, true );
	
EndProcedure

&AtClient
Procedure mark ( Table, Flag )
	
	for each row in Table do
		row.Select = Flag;
	enddo;

EndProcedure

&AtClient
Procedure UnmarkAll ( Command )
	
	tableName = StrReplace ( Command.Name, "UnmarkAll", "" );
	table = Object [ tableName ];
	mark ( table, false );
	
EndProcedure

