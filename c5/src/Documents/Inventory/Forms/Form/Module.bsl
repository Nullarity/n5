&AtServer
var Env;
&AtClient
var ItemsRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	updateChangesPermission ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( isNew () ) then
		DocumentForm.Init ( Object );
		fillNew ();
		updateChangesPermission ();
	endif; 
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg, ItemsQuantityBalance, ItemsQuantityPkgBalance, ItemsQuantityPkgDifference, ItemsQuantityDifference" );
	setLinks ();
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Function isNew ()
	
	return Object.Ref.IsEmpty ();
	
EndFunction

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Links show ShowLinks
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	if ( Object.Warehouse.IsEmpty () ) then
		settings = Logins.Settings ( "Company, Warehouse" );
		Object.Company = settings.Company;
		Object.Warehouse = settings.Warehouse;
	else
		Object.Company = DF.Pick ( Object.Warehouse, "Owner" );
	endif;
	
EndProcedure 

&AtServer
Procedure setLinks ()
	
	SQL.Init ( Env );
	sqlLinks ();
	if ( Env.Selection.Count () = 0 ) then
		ShowLinks = false;
	else
		Env.Q.SetParameter ( "Ref", Object.Ref );
		SQL.Perform ( Env, false );
		setURLPanel ();
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	if ( isNew () ) then
		return;
	endif; 
	s = "
	|// #ReceiveItems
	|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
	|from Document.ReceiveItems as Documents
	|where Documents.Inventory = &Ref
	|and not Documents.DeletionMark
	|;
	|// #WriteOff
	|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
	|from Document.WriteOff as Documents
	|where Documents.Base = &Ref
	|and not Documents.DeletionMark
	|;
	|// #Assembling
	|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
	|from Document.Assembling as Documents
	|where Documents.Base = &Ref
	|and not Documents.DeletionMark
	|;
	|// #Disassembling
	|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
	|from Document.Disassembling as Documents
	|where Documents.Base = &Ref
	|and not Documents.DeletionMark
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	meta = Metadata.Documents;
	if ( not isNew () ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.ReceiveItems, meta.ReceiveItems ) );
		parts.Add ( URLPanel.DocumentsToURL ( Env.WriteOff, meta.WriteOff ) );
		parts.Add ( URLPanel.DocumentsToURL ( Env.Assembling, meta.Assembling ) );
		parts.Add ( URLPanel.DocumentsToURL ( Env.Disassembling, meta.Disassembling ) );
	endif; 
	s = URLPanel.Build ( parts );
	if ( s = undefined ) then
		ShowLinks = false;
	else
		ShowLinks = true;
		Links = s;
	endif; 
	
EndProcedure 

&AtClient
Procedure NewWriteProcessing ( NewObject, Source, StandardProcessing )
	
	setLinks ();
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageBarcodeScanned ()
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		addItem ( Parameter );
	elsif ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtServer
Procedure addItem ( Fields )
	
	search = new Structure ( "Item, Package, Feature" );
	FillPropertyValues ( search, Fields );
	rows = Object.Items.FindRows ( search );
	if ( rows.Count () = 0 ) then
		row = Object.Items.Add ();
		row.Item = Fields.Item;
		row.Package = Fields.Package;
		row.Feature = Fields.Feature;
		row.QuantityPkg = Fields.QuantityPkg;
		row.Capacity = Fields.Capacity;
		row.Quantity = Fields.Quantity;
		accounts = AccountsMap.Item ( row.Item, Object.Company, Object.Warehouse, "Account" );
		row.Account = accounts.Account;
	else
		row = rows [ 0 ];
		row.Quantity = row.Quantity + Fields.Quantity;
		row.QuantityPkg = row.QuantityPkg + Fields.QuantityPkg;
	endif; 
	calcDifference ( row );
	
EndProcedure 

&AtClientAtServerNoContext
Procedure calcDifference ( ItemsRow )
	
	ItemsRow.QuantityDifference = ItemsRow.Quantity - ItemsRow.QuantityBalance;
	ItemsRow.QuantityPkgDifference = ItemsRow.QuantityPkg - ItemsRow.QuantityPkgBalance;
	ItemsRow.AmountDifference = ItemsRow.Amount - ItemsRow.AmountBalance;
	
EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );
	Forms.DeleteLastRow ( Object.Items, "Item" );
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure calcTotals ( Object )
	
	Object.Amount = Object.Items.Total ( "Amount" );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Table Items

&AtClient
async Procedure OpenInventory ( Command )
	
	row = Items.ItemsTable.CurrentData;
	if ( row = undefined ) then
		return;
	endif;
	list = findInventories ( row.Item );
	if ( list = undefined ) then
		Output.ThereIsNoStockmanInventory ();
	elsif ( list.Count () = 1 ) then
		OpenValueAsync ( list [ 0 ].Value );
	else
		item = await ChooseFromListAsync ( list );
		if ( item <> undefined ) then
			OpenValueAsync ( list [ 0 ].Value );
		endif;
	endif;

EndProcedure

&AtServer
Function findInventories ( val Item )
	
	s = "
	|select distinct Items.Ref, presentation ( Items.Ref ) as Presentation
	|from Document.InventoryStockman.Items as Items
	|where Items.Ref.Warehouse = &Warehouse
	|and Items.Item = &Item
	|and Items.Ref.Posted
	|and Items.Ref.Date between dateadd ( &Date, day, - Items.Ref.Warehouse.Inventory ) and &Date";
	q = new Query ( s );
	q.SetParameter ( "Item", Item );
	q.SetParameter ( "Date", Object.Date );
	q.SetParameter ( "Warehouse", Object.Warehouse );
	result = new ValueList ();
	for each row in q.Execute ().Unload () do
		result.Add ( row.Ref, row.Presentation );
	enddo;
	return ? ( result.Count () = 0, undefined, result );

EndFunction
 
&AtClient
Procedure Scan ( Command )
	
	ScanForm.Open ( ThisObject, true );
	
EndProcedure

&AtClient
Procedure Fill ( Command )
	
	if ( Forms.Check ( ThisObject, "Warehouse" ) ) then
		askAndFill ();
	endif; 
	
EndProcedure

&AtClient
async Procedure askAndFill ()
	
	if ( Object.Items.Count () > 0 ) then
		answer = await Output.CleanTableBeforeFilling ();
		if ( answer = DialogReturnCode.Cancel ) then
			return;
		elsif ( answer = DialogReturnCode.Yes ) then
			Object.Items.Clear ();
		endif;
	endif;
	fillTable ();

EndProcedure

&AtServer
Procedure fillTable ()
	
	itemsTable = Object.Items;
	search = new Structure ( "Item, Package, Feature, Series, Account" );
	for each row in getTable () do
		FillPropertyValues ( search, row );
		foundRows = itemsTable.FindRows ( search );
		if ( foundRows.Count () = 0 ) then
			itemsRow = itemsTable.Add ();
			FillPropertyValues ( itemsRow, row );
			itemsRow.Price = row.PriceBalance;
		else
			itemsRow = foundRows [ 0 ];
			FillPropertyValues ( itemsRow, row, , "Quantity, QuantityPkg" );
			itemsRow.Price = row.PriceBalance;
			calcDifference ( itemsRow );
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Function getTable ()
	
	folder = not Object.Folder.IsEmpty ();
	s = "
	|// ItemKeys
	|select Details.ItemKey as ItemKey, Details.Item as Item, Details.Feature as Feature,
	|	Details.Package as Package, Details.Series as Series, Details.Account as Account
	|into Details
	|from InformationRegister.ItemDetails as Details
	|where Details.Warehouse = &Warehouse
	|";
	if ( folder ) then
		s = s + "and Details.Item in hierarchy ( &Folder )"
	endif;
	s = s + "
	|index by ItemKey
	|;
	|// Stockman Inventory
	|select Items.Ref as Ref, Items.Item as Item, Items.Feature as Feature, Items.Series as Series, Items.Quantity as Quantity,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package,
	|	case when Items.Item.CountPackages then Items.QuantityPkg else Items.Quantity end as QuantityPkg,
	|	case when Items.Item.CountPackages then Items.Capacity else 1 end as Capacity
	|into Inventory
	|from Document.InventoryStockman.Items as Items
	|where Items.Ref.Warehouse = &Warehouse
	|and Items.Ref.Date between dateadd ( &InventoryDate, day, - Items.Ref.Warehouse.Inventory ) and &InventoryDate
	|and Items.Ref.Posted
	|";
	if ( folder ) then
		s = s + "and Items.Item in hierarchy ( &Folder )"
	endif;
	s = s + "
	|;
	|// Cost
	|select Details.Item as Item, Details.Package as Package, Details.Feature as Feature,
	|	Details.Series as Series, Details.Account as Account,
	|	isnull ( Details.Package.Capacity, 1 ) as Capacity,
	|	Balances.QuantityBalance * isnull ( Details.Package.Capacity, 1 ) as QuantityBalance,
	|	Balances.QuantityBalance as QuantityPkgBalance, Balances.AmountBalance as AmountBalance
	|into Cost
	|from AccumulationRegister.Cost.Balance ( &Date, ItemKey in ( select ItemKey from Details ) ) as Balances
	|	//
	|	// Details
	|	//
	|	join Details as Details
	|	on Details.ItemKey = Balances.ItemKey
	|;
	|// #Items
	|select Items.Item as Item, Items.Package as Package, Items.Feature as Feature, Items.Series as Series,
	|	Items.Account as Account, Items.Capacity as Capacity, Items.Price as PriceBalance,
	|	Items.Quantity as Quantity, Items.QuantityPkg as QuantityPkg,
	|	Items.QuantityBalance as QuantityBalance, Items.QuantityPkgBalance as QuantityPkgBalance,
	|	Items.Quantity - Items.QuantityBalance as QuantityDifference,
	|	Items.QuantityPkg - Items.QuantityPkgBalance as QuantityPkgDifference,
	|	Items.AmountBalance as AmountBalance,
	|	case
	|		when Items.Quantity = Items.QuantityBalance then Items.AmountBalance
	|		else Items.Price * Items.Quantity
	|	end as Amount,
	|	case when Items.Quantity = 0 then - Items.AmountBalance
	|		when Items.Quantity = Items.QuantityBalance then 0
	|		else Items.Price * ( Items.Quantity - Items.QuantityBalance )
	|	end as AmountDifference
	|from (
	|	select Items.Item as Item, Items.Package as Package, Items.Feature as Feature, Items.Series as Series,
	|		Items.Account as Account, Items.Capacity as Capacity,
	|		cast (
	|			case when sum ( case when Items.Package is null then Items.QuantityBalance else Items.QuantityPkgBalance end ) = 0 then 0
	|				else sum ( Items.AmountBalance ) / sum ( case when Items.Package is null then Items.QuantityBalance else Items.QuantityPkgBalance end )
	|			end
	|		as Number ( 15, 2 ) ) as Price,
	|		sum ( Items.QuantityBalance ) as QuantityBalance, sum ( Items.QuantityPkgBalance ) as QuantityPkgBalance,
	|		sum ( Items.AmountBalance ) as AmountBalance, sum ( Items.Quantity ) as Quantity,
	|		sum ( Items.QuantityPkg ) as QuantityPkg
	|	from (
	|		select Cost.Item as Item, Cost.Package as Package, Cost.Feature as Feature, Cost.Series as Series,
	|			Cost.Account as Account, Cost.Capacity as Capacity, Cost.QuantityBalance as QuantityBalance,
	|			Cost.QuantityPkgBalance as QuantityPkgBalance, Cost.AmountBalance as AmountBalance,
	|			0 as Quantity, 0 as QuantityPkg
	|		from Cost as Cost
	|		union all
	|		select Inventory.Item, Inventory.Package, Inventory.Feature, Inventory.Series, Details.Account,
	|			Inventory.Capacity, 0, 0, 0, Inventory.Quantity, Inventory.QuantityPkg
	|		from Inventory as Inventory
	|			//
	|			// Details
	|			//
	|			left join Details as Details
	|			on Details.Item = Inventory.Item
	|			and Details.Feature = Inventory.Feature
	|			and Details.Series = Inventory.Series
	|			and Details.Package = Inventory.Package
	|		) as Items
	|	group by Items.Item, Items.Package, Items.Feature, Items.Series, Items.Account, Items.Capacity
	|	) as Items
	|order by Item.Description, Items.Feature.Description, Items.Series.Description, Account.Code, Capacity
	|";
	q = new Query ( s );
	q.SetParameter ( "Warehouse", Object.Warehouse );
	q.SetParameter ( "Folder", Object.Folder );
	q.SetParameter ( "Date", Periods.GetBalanceDate ( Object ) );
	q.SetParameter ( "InventoryDate", EndOfDay ( Object.Date ) );
	table = q.Execute ().Unload ();
	table.Indexes.Add ( "Item, Package, Feature, Series, Account" );
	return table;
	
EndFunction

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ItemsOnEditEnd ( Item, NewRow, CancelEdit )
	
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure ItemsAfterDeleteRow ( Item )
	
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure ItemsItemOnChange ( Item )
	
	applyItem ();
	
EndProcedure

&AtClient
Procedure applyItem ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Company", Object.Company );
	p.Insert ( "Warehouse", Object.Warehouse );
	p.Insert ( "Item", ItemsRow.Item );
	data = getItemData ( p );
	ItemsRow.Package = data.Package;
	ItemsRow.Capacity = data.Capacity;
	ItemsRow.Account = data.Account;
	Computations.Units ( ItemsRow );
	calcAmount ( ItemsRow );
	calcDifference ( ItemsRow );
	
EndProcedure 

&AtServerNoContext
Function getItemData ( val Params )
	
	data = DF.Values ( Params.Item, "Package, Package.Capacity as Capacity" );
	accounts = AccountsMap.Item ( Params.Item, Params.Company, Params.Warehouse, "Account" );
	data.Insert ( "Account", accounts.Account );
	if ( data.Capacity = 0 ) then
		data.Capacity = 1;
	endif; 
	return data;
	
EndFunction 

&AtClient
Procedure ItemsQuantityPkgOnChange ( Item )
	
	Computations.Units ( ItemsRow );
	calcAmount ( ItemsRow );
	calcDifference ( ItemsRow );
	
EndProcedure

&AtClient
Procedure calcAmount ( Row )
	
	if ( Row.Quantity = 0 ) then
		Row.Amount = 0;
	elsif ( Row.Price = Row.PriceBalance ) then
		if ( Row.Quantity = Row.QuantityBalance ) then
			Row.Amount = Row.AmountBalance;
		else
			Row.Amount = ? ( Row.QuantityBalance = 0, Row.Price, Row.AmountBalance / Row.QuantityBalance )
			* Row.Quantity;
		endif;
	else
		Row.Amount = Row.Price * Row.Quantity;
	endif;

EndProcedure

&AtClient
Procedure ItemsPackageOnChange ( Item )
	
	applyPackage ();
	
EndProcedure

&AtClient
Procedure applyPackage ()
	
	ItemsRow.Capacity = DF.Pick ( ItemsRow.Package, "Capacity", 1 );
	Computations.Units ( ItemsRow );
	calcAmount ( ItemsRow );
	calcDifference ( ItemsRow );
	
EndProcedure 

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	calcAmount ( ItemsRow );
	calcDifference ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsPriceOnChange ( Item )
	
	calcAmount ( ItemsRow );
	calcDifference ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsAmountOnChange ( Item )
	
	Computations.Price ( ItemsRow );
	calcDifference ( ItemsRow );
	
EndProcedure
