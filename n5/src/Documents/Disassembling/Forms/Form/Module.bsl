&AtClient
var ItemsRow;
&AtServer
var Base;
&AtServer
var Env;
&AtServer
var BaseExists;
&AtServer
var BaseMetadata;

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
		Base = Parameters.Basis;
		if ( Base = undefined ) then
			fillNew ();
		else
			baseType = TypeOf ( Base );
			if ( baseType = Type ( "DocumentRef.Assembling" ) ) then
				fillByAssembling ();
			elsif ( baseType = Type ( "DocumentRef.Inventory" ) ) then
				fillByInventory ();
			endif;
		endif;
		updateChangesPermission ();
	endif; 
	setAccuracy ();
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
Procedure fillByAssembling ()
	
	setEnv ();
	sqlAssembling ();
	SQL.Perform ( Env );
	headerByAssembling ();
	itemsByAssembling ();
	
EndProcedure

&AtServer
Procedure setEnv ()
	
	Env = new Structure ();
	SQL.Init ( Env );
	Env.Q.SetParameter ( "Base", Base );
	
EndProcedure

&AtServer
Procedure sqlAssembling ()
	
	s = "
	|// @Fields
	|select Document.Company as Company, Document.Warehouse as Warehouse, Document.Set as Set,
	|	Document.Feature as Feature, Document.Series as Series, Document.QuantityPkg as QuantityPkg,
	|	Document.Package as Package, Document.Quantity as Quantity, Document.Capacity as Capacity,
	|	Document.Account as Account
	|from Document.Assembling as Document
	|where Document.Ref = &Base
	|;
	|// #Items
	|select Items.Item as Item, Items.Feature as Feature, Items.Capacity as Capacity, Items.Series as Series,
	|	Items.Package as Package, Items.Account as Account, Items.Quantity as Quantity, 
	|	Items.QuantityPkg as QuantityPkg, Items.Warehouse as Warehouse 
	|from Document.Assembling.Items as Items
	|where Items.Ref = &Base
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure headerByAssembling ()
	
	FillPropertyValues ( Object, Env.Fields );
	
EndProcedure 

&AtServer
Procedure itemsByAssembling ()
	
	Object.Items.Load ( Env.Items );
	
EndProcedure

&AtServer
Procedure fillByInventory ()
	
	setEnv ();
	sqlInventory ();
	SQL.Perform ( Env );
	headerByInventory ();
	itemsByInventory ();
	
EndProcedure

&AtServer
Procedure sqlInventory ()
	
	s = "
	|// @Fields
	|select Document.Company as Company, Document.Warehouse as Warehouse
	|from Document.Inventory as Document
	|where Document.Ref = &Base
	|;
	|// #Items
	|select Items.Item as Item, Items.Feature as Feature, Items.Capacity as Capacity, Items.Series as Series,
	|	Items.Package as Package, Items.Account as Account, Items.QuantityDifference as Quantity, 
	|	Items.QuantityPkgDifference as QuantityPkg, Items.AmountDifference as CostRate
	|from Document.Inventory.Items as Items
	|where Items.Ref = &Base
	|and Items.QuantityDifference > 0
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure headerByInventory ()
	
	FillPropertyValues ( Object, Env.Fields );
	Object.Base = Base;
	
EndProcedure 

&AtServer
Procedure itemsByInventory ()
	
	if ( Env.Items.Count () = 0 ) then
		raise Output.FillingDataNotFoundError ();
	endif;
	Object.Items.Load ( Env.Items );
	
EndProcedure

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg, Quantity, QuantityPkg" );
	Options.SetAccuracy ( ThisObject, "ItemsTotalQuantityPkg, ItemsTotalQuantity", false );
	
EndProcedure 

&AtServer
Procedure setLinks ()
	
	SQL.Init ( Env );
	sqlLinks ();
	if ( Env.Selection.Count () = 0 ) then
		ShowLinks = false;
	else
		q = Env.Q;
		q.SetParameter ( "Ref", Object.Ref );
		q.SetParameter ( "Base", Object.Base );
		SQL.Perform ( Env );
		setURLPanel ();
	endif;

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	selection = Env.Selection;
	BaseExists = ValueIsFilled ( Object.Base );
	if ( BaseExists ) then
		BaseMetadata = Metadata.FindByType ( TypeOf ( Object.Base ) );
		s = "
		|// #Base
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document." + BaseMetadata.Name + " as Documents
		|where Documents.Ref = &Base
		|";
		selection.Add ( s );
	endif;
	
EndProcedure 

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	if ( BaseExists ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Base, BaseMetadata ) );
	endif;
	s = URLPanel.Build ( parts );
	if ( s = undefined ) then
		ShowLinks = false;
	else
		ShowLinks = true;
		Links = s;
	endif; 
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Links show ShowLinks;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtClient
Procedure ChoiceProcessing ( SelectedValue, ChoiceSource )
	
	if ( SelectedValue.Operation = Enum.ChoiceOperationsPickItems () ) then
		addSelectedItems ( SelectedValue );
	endif; 
	
EndProcedure

&AtClient
Procedure addSelectedItems ( Params )
	
	for each selectedRow in Params.Items do
		row = Object.Items.Add ();
		FillPropertyValues ( row, selectedRow );
	enddo; 
	
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
	
EndProcedure 

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

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

&AtClient
Procedure SetOnChange ( Item )

	applySet ();
	
EndProcedure

&AtClient
Procedure applySet ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Company", Object.Company );
	p.Insert ( "Warehouse", Object.Warehouse );
	p.Insert ( "Item", Object.Set );
	data = getItemData ( p );
	Object.Package = data.Package;
	Object.Capacity = data.Capacity;
	Object.Account = data.Account;
	Computations.Units ( Object );
	
EndProcedure 

&AtClient
Procedure QuantityPkgOnChange ( Item )
	
	Computations.Units ( Object );
	
EndProcedure

&AtClient
Procedure PackageOnChange ( Item )
	
	applySetPackage ();
	
EndProcedure

&AtClient
Procedure applySetPackage ()
	
	Object.Capacity = DF.Pick ( Object.Package, "Capacity", 1 );
	Computations.Units ( Object );
	
EndProcedure 

&AtClient
Procedure QuantityOnChange ( Item )
	
	Computations.Packages ( Object );
	
EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure Scan ( Command )
	
	ScanForm.Open ( ThisObject, true );
	
EndProcedure

&AtClient
Procedure SelectItems ( Command )
	
	PickItems.Open ( ThisObject, pickParams () );
	
EndProcedure

&AtServer
Function pickParams ()
	
	return PickItems.GetParams ( ThisObject );
	
EndFunction 

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	
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
	p.Insert ( "Warehouse", getWarehouse () );
	p.Insert ( "Item", ItemsRow.Item );
	data = getItemData ( p );
	ItemsRow.Package = data.Package;
	ItemsRow.Capacity = data.Capacity;
	ItemsRow.Account = data.Account;
	Computations.Units ( ItemsRow );
	
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
Function getWarehouse ()
	
	return ? ( ItemsRow.Warehouse.IsEmpty (), Object.Warehouse, ItemsRow.Warehouse );
	
EndFunction 

&AtClient
Procedure ItemsQuantityPkgOnChange ( Item )
	
	Computations.Units ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsPackageOnChange ( Item )
	
	applyPackage ();
	
EndProcedure

&AtClient
Procedure applyPackage ()
	
	ItemsRow.Capacity = DF.Pick ( ItemsRow.Package, "Capacity", 1 );
	Computations.Units ( ItemsRow );
	
EndProcedure 

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	
EndProcedure
