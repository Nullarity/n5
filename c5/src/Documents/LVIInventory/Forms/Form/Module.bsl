&AtServer
var Env;
&AtServer
var ViewReceiveItems;
&AtServer
var ViewLVIWriteOff;
&AtClient
var ItemsRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Constraints.ShowAccess ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( isNew () ) then
		DocumentForm.Init ( Object );
		fillNew ();
		Constraints.ShowAccess ( ThisObject );
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
	if ( Object.Department.IsEmpty () ) then
		settings = Logins.Settings ( "Company, Department" );
		Object.Company = settings.Company;
		Object.Department = settings.Department;
	else
		Object.Company = DF.Pick ( Object.Department, "Owner" );
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

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	if ( isNew () ) then
		return;
	endif; 
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
		Env.Selection.Add ( s );
	endif; 
	ViewLVIWriteOff = AccessRight ( "View", meta.LVIWriteOff );
	if ( ViewLVIWriteOff ) then
		s = "
		|// #LVIWriteOff
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.LVIWriteOff as Documents
		|where Documents.LVIInventory = &Ref
		|and not Documents.DeletionMark
		|";
		Env.Selection.Add ( s );
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
		if ( ViewLVIWriteOff ) then
			parts.Add ( URLPanel.DocumentsToURL ( Env.LVIWriteOff, meta.LVIWriteOff ) );
		endif; 
	endif; 
	s = URLPanel.Build ( parts );
	if ( s = undefined ) then
		ShowLinks = false;
	else
		ShowLinks = true;
		Links = s;
	endif; 
	Appearance.Apply ( ThisObject, "ShowLinks" )
	
EndProcedure 

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	Forms.DeleteLastRow ( Object.Items, "Item" );
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure calcTotals ( Object )
	
	Object.Amount = Object.Items.Total ( "Amount" );
	
EndProcedure 

&AtClient
Procedure NewWriteProcessing ( NewObject, Source, StandardProcessing )
	
	readNew ( NewObject );
	
EndProcedure

&AtServer
Procedure readNew ( NewObject ) 

	type = TypeOf ( NewObject );
	if ( type = Type ( "DocumentRef.ReceiveItems" )
		or type = Type ( "DocumentRef.LVIWriteOff" ) ) then
		setLinks ();
		Appearance.Apply ( ThisObject, "ShowLinks" );
	else
		return;
	endif;
	
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
Procedure Fill ( Command )
	
	if ( Forms.Check ( ThisObject, "Department" ) ) then
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
	|select Balances.QuantityBalanceDr as QuantityPkg,
	|	Balances.ExtDimension1 as Item, Balances.AmountBalanceDr as Amount,
	|	Balances.Account as Account, Balances.ExtDimension1.Package as Package,
	|	isnull ( Balances.ExtDimension1.Package.Capacity, 1 ) as Capacity,
	|	Balances.QuantityBalanceDr * isnull ( Balances.ExtDimension1.Package.Capacity, 1 ) as Quantity,
	|	cast ( case when Balances.QuantityBalanceDr = 0 then 0 else Balances.AmountBalanceDr / Balances.QuantityBalanceDr end as Number ( 15, 2 ) ) as Price
	|from AccountingRegister.General.Balance ( &Date, Account = &Account, , ExtDimension2 = &Department ) as Balances
	|";
	q = new Query ( s );
	q.SetParameter ( "Department", Object.Department );
	q.SetParameter ( "Account", Object.Account );
	q.SetParameter ( "Date", Periods.GetBalanceDate ( Object ) );
	table = q.Execute ().Unload ();
	table.Indexes.Add ( "Item, Package, Account, Price" );
	return table;
	
EndFunction 

&AtClientAtServerNoContext
Procedure calcDifference ( ItemsRow )
	
	ItemsRow.QuantityDifference = ItemsRow.Quantity - ItemsRow.QuantityBalance;
	ItemsRow.QuantityPkgDifference = ItemsRow.QuantityPkg - ItemsRow.QuantityPkgBalance;
	ItemsRow.AmountDifference = ItemsRow.Amount - ItemsRow.AmountBalance;
	
EndProcedure

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
	accounts = AccountsMap.Item ( Params.Item, Params.Company, , "Account" );
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
