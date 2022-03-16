&AtServer
var Env;
&AtServer
var ViewReceiveItems;
&AtServer
var ViewWriteOff;
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
		SQL.Perform ( Env );
		setURLPanel ();
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	if ( isNew () ) then
		return;
	endif; 
	selection = Env.Selection;
	meta = Metadata.Documents;
	ViewReceiveItems = AccessRight ( "View", meta.ReceiveItems );
	if ( ViewReceiveItems ) then
		s = "
		|// #ReceiveItems
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.ReceiveItems as Documents
		|where Documents.Inventory = &Ref
		|and not Documents.DeletionMark
		|";
		selection.Add ( s );
	endif; 
	ViewWriteOff = AccessRight ( "View", meta.WriteOff );
	if ( ViewWriteOff ) then
		s = "
		|// #WriteOff
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.WriteOff as Documents
		|where Documents.Base = &Ref
		|and not Documents.DeletionMark
		|";
		selection.Add ( s );
	endif; 
	
EndProcedure 

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	meta = Metadata.Documents;
	if ( not isNew () ) then
		if ( ViewReceiveItems ) then
			parts.Add ( URLPanel.DocumentsToURL ( Env.ReceiveItems, meta.ReceiveItems ) );
		endif; 
		if ( ViewWriteOff ) then
			parts.Add ( URLPanel.DocumentsToURL ( Env.WriteOff, meta.WriteOff ) );
		endif; 
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
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );
	Forms.DeleteLastRow ( Object.Items, "Item" );
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure calcTotals ( Object )
	
	Object.Amount = Object.Items.Total ( "Amount" );
	
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
Procedure Scan ( Command )
	
	ScanForm.Open ( ThisObject, true );
	
EndProcedure

&AtClient
Procedure Fill ( Command )
	
	if ( Forms.Check ( ThisObject, "Warehouse" ) ) then
		Output.UpdateInventory ( ThisObject );
	endif; 
	
EndProcedure

&AtClient
Procedure UpdateInventory ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	fillTable ();
	
EndProcedure 

&AtServer
Procedure fillTable ()
	
	table = getTable ();
	itemsTable = Object.Items;
	search = new Structure ( "Item, Package, Feature, Series, Account" );
	for each row in table do
		FillPropertyValues ( search, row );
		foundRows = itemsTable.FindRows ( search );
		found = foundRows.Count () > 0;
		if ( found ) then
			itemsRow = foundRows [ 0 ];
		else
			itemsRow = itemsTable.Add ();
			FillPropertyValues ( itemsRow, row );
		endif; 
		itemsRow.QuantityBalance = row.Quantity;
		itemsRow.QuantityPkgBalance = row.QuantityPkg;
		itemsRow.PriceBalance = row.Price;
		itemsRow.AmountBalance = row.Amount;
		if ( found ) then
			calcDifference ( itemsRow );
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Function getTable ()
	
	s = "
	|// ItemKeys
	|select Details.ItemKey as ItemKey, Details.Item as Item, Details.Feature as Feature,
	|	Details.Package as Package, Details.Series as Series, Details.Account as Account
	|into Details
	|from InformationRegister.ItemDetails as Details
	|where Details.Warehouse = &Warehouse
	|index by ItemKey
	|;
	|select Details.Item as Item, Details.Package as Package, Details.Feature as Feature,
	|	Details.Series as Series, Details.Account as Account,
	|	isnull ( Details.Package.Capacity, 1 ) as Capacity,
	|	cast ( Balances.AmountBalance / Balances.QuantityBalance as Number ( 15, 2 ) ) as Price,
	|	Balances.QuantityBalance * isnull ( Details.Package.Capacity, 1 ) as Quantity,
	|	Balances.QuantityBalance as QuantityPkg, Balances.AmountBalance as Amount
	|from AccumulationRegister.Cost.Balance ( &Date, ItemKey in ( select ItemKey from Details ) ) as Balances
	|	//
	|	// Details
	|	//
	|	join Details as Details
	|	on Details.ItemKey = Balances.ItemKey
	|order by Item.Description, Account.Code, Capacity
	|";
	q = new Query ( s );
	q.SetParameter ( "Warehouse", Object.Warehouse );
	q.SetParameter ( "Date", Periods.GetBalanceDate ( Object ) );
	table = q.Execute ().Unload ();
	table.Indexes.Add ( "Item, Package, Feature, Series, Account, Price" );
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
	Computations.Amount ( ItemsRow );
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
	Computations.Amount ( ItemsRow );
	calcDifference ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsPackageOnChange ( Item )
	
	applyPackage ();
	
EndProcedure

&AtClient
Procedure applyPackage ()
	
	ItemsRow.Capacity = DF.Pick ( ItemsRow.Package, "Capacity", 1 );
	Computations.Units ( ItemsRow );
	Computations.Amount ( ItemsRow );
	calcDifference ( ItemsRow );
	
EndProcedure 

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	Computations.Amount ( ItemsRow );
	calcDifference ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsPriceOnChange ( Item )
	
	Computations.Amount ( ItemsRow );
	calcDifference ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsAmountOnChange ( Item )
	
	Computations.Price ( ItemsRow );
	calcDifference ( ItemsRow );
	
EndProcedure
