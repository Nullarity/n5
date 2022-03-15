&AtServer
var Copy;
&AtServer
var Env;
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
	
	if ( Object.Ref.IsEmpty () ) then
		Copy = not Parameters.CopyingValue.IsEmpty ();
		DocumentForm.Init ( Object );
		fillNew ();
		fillByCustomer ();
		Constraints.ShowAccess ( ThisObject );
	endif; 
	setAccuracy ();
	setLinks ();
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Links show ShowLinks;
	|IOSheet1 show filled ( Object.IOSheet1 );
	|IOSheet2 show filled ( Object.IOSheet2 );
	|IOSheet3 show filled ( Object.IOSheet3 )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( Copy
		or Parameters.Basis <> undefined ) then
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
Procedure fillByCustomer ()
	
	apply = Parameters.FillingValues.Property ( "Customer" )
	and not Copy
	and not Object.Customer.IsEmpty ();
	if ( apply ) then
		fillDocument ();
		Appearance.Apply ( ThisObject );
	endif;

EndProcedure 

&AtServer
Procedure fillDocument ()
	
	SQL.Init ( Env );
	sqlSheets ();
	Env.Q.SetParameter ( "Date", ? ( Object.Date = Date ( 1, 1, 1 ), CurrentSessionDate (), Object.Date ) );
	Env.Q.SetParameter ( "Ref", Object.Ref );
	Env.Q.SetParameter ( "Customer", Object.Customer );
	Env.Q.SetParameter ( "Warehouse", Object.Warehouse );
	SQL.Perform ( Env );
	sqlHistory ();
	sqlItems ();
	SQL.Perform ( Env );
	loadData ();
	
EndProcedure

&AtServer
Procedure sqlSheets ()
	
	s = "
	|// #Sheets
	|select allowed top 3 Sheets.Ref as Ref, Sheets.Date as Date
	|from Document.IOSheet as Sheets
	|where Sheets.Posted
	|and Sheets.Customer = &Customer
	|and Sheets.Warehouse = &Warehouse
	|and Sheets.Ref <> &Ref
	|and Sheets.Date <= &Date
	|order by Sheets.Date desc
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServer
Procedure sqlHistory ()
	
	fields = new Array ();
	joins = new Array ();
	Env.Insert ( "History", Env.Sheets.Count () );
	for i = 1 to Env.History do
		field = "" + i;
		alias = "History" + field;
		fields.Add ( alias + ".Package as Package" + field );
		fields.Add ( alias + ".Quantity as Quantity" + field );
		fields.Add ( alias + ".QuantityPkg as QuantityPkg" + field );
		s = "
		|	left join Document.IOSheet.Items as " + alias + "
		|	on " + alias + ".Ref = &" + alias + "
		|	and " + alias + ".Item = Items.Ref
		|	and " + alias + ".Package = isnull ( Packages.Ref, value ( Catalog.Packages.EmptyRef ) )
		|	and " + alias + ".Feature = isnull ( Features.Ref, value ( Catalog.Features.EmptyRef ) )
		|";
		joins.Add ( s );
		Env.Q.SetParameter ( alias, Env.Sheets [ i - 1 ].Ref );
	enddo; 
	Env.Insert ( "Fields", StrConcat ( fields, "," ) );
	Env.Insert ( "Joins", StrConcat ( joins, " " ) );
	
EndProcedure 

&AtServer
Procedure sqlItems ()
	
	s = "
	|select Balances.Item as Item, Balances.Feature as Feature, Balances.Package as Package,
	|	Balances.QuantityBalance as Balance
	|into Balances
	|from AccumulationRegister.Items.Balance ( , Warehouse = &Warehouse ) as Balances
	|index by Item, Feature, Package
	|;
	|// #Items
	|select Items.Ref as Item, Packages.Ref as Package, isnull ( Packages.Capacity, 1 ) as Capacity,
	|	Features.Ref as Feature, isnull ( BalancesPackages.Balance, Balances.Balance ) as Balance";
	if ( Env.History > 0 ) then
		s = s + ", " + Env.Fields;
	endif;
	s = s + "
	|from Catalog.Items as Items
	|	//
	|	// Packages
	|	//
	|	left join Catalog.Packages as Packages
	|	on Packages.Owner = Items.Ref
	|	and not Packages.DeletionMark
	|	//
	|	// Features
	|	//
	|	left join Catalog.Features as Features
	|	on Features.Owner = Items.Ref
	|	and not Features.DeletionMark
	|	//
	|	// BalancesPackages
	|	//
	|	left join Balances as BalancesPackages
	|	on Items.CountPackages
	|	and BalancesPackages.Item = Items.Ref
	|	and BalancesPackages.Feature = isnull ( Features.Ref, value ( Catalog.Features.EmptyRef ) )
	|	and BalancesPackages.Package = Packages.Ref
	|	//
	|	// Balances
	|	//
	|	left join Balances as Balances
	|	on not Items.CountPackages
	|	and Balances.Item = Items.Ref
	|	and Balances.Feature = isnull ( Features.Ref, value ( Catalog.Features.EmptyRef ) )
	|";
	if ( Env.History > 0 ) then
		s = s + Env.Joins;
	endif;
	s = s + "
	|where not Items.DeletionMark
	|and not Items.Service
	|and not Items.IsFolder
	|order by Items.Description, Packages.Capacity
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServer
Procedure loadData ()
	
	Object.Items.Load ( Env.Items );
	table = Env.Sheets;
	for i = 1 to 3 do
		iosheet = "IOSheet" + i;
		if ( i > Env.History ) then
			Object [ iosheet ] = undefined;
		else
			Object [ iosheet ] = table [ i - 1 ].Ref;
		endif; 
		#if ( not WebClient ) then
			// 8.3.6.2100 Bug workaround
			column = Items [ "ItemsIO" + i ];
			if ( Object.Ref.IsEmpty () ) then
				column.Title = " "; // It enforces to refresh columns title
			endif; 
		#endif
	enddo; 
	
EndProcedure 

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsBalance, ItemsQuantity1, ItemsQuantityPkg1, ItemsQuantity2, ItemsQuantityPkg2, ItemsQuantity3, ItemsQuantityPkg3", , false );
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg" );
	Options.SetAccuracy ( ThisObject, "ItemsTotalQuantityPkg, ItemsTotalQuantity", false );
	
EndProcedure 

&AtServer
Procedure setLinks ()
	
	if ( Object.Ref.IsEmpty () ) then
		ShowLinks = false;
		return;
	endif; 
	SQL.Init ( Env );
	sqlLinks ();
	Env.Q.SetParameter ( "Ref", Object.Ref );
	SQL.Perform ( Env );
	setURLPanel ();
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	s = "
	|// #SalesOrders
	|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
	|from Document.SalesOrder as Documents
	|where Documents.IOSheet = &Ref
	|and not Documents.DeletionMark
	|order by Date
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	meta = Metadata.Documents;
	parts.Add ( URLPanel.DocumentsToURL ( Env.SalesOrders, meta.SalesOrder ) );
	s = URLPanel.Build ( parts );
	if ( s = undefined ) then
		ShowLinks = false;
	else
		ShowLinks = true;
		Links = s;
	endif; 
	
EndProcedure 

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageBarcodeScanned ()
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		activateItem ( Parameter );
	elsif ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtClient
Procedure activateItem ( Fields )
	
	search = new Structure ( "Item, Package, Feature" );
	FillPropertyValues ( search, Fields );
	rows = Object.Items.FindRows ( search );
	if ( rows.Count () = 0 ) then
		Output.ItemNotFound ();
	else
		ItemsRow = rows [ 0 ];
		Items.Items.CurrentRow = ItemsRow.GetID ();
	endif; 
	
EndProcedure 

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtClient
Procedure NewWriteProcessing ( NewObject, Source, StandardProcessing )
	
	setLinks ();
	
EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

&AtClient
Procedure CustomerOnChange ( Item )
	
	refill ();
	
EndProcedure

&AtServer
Procedure refill ()
	
	fillDocument ();
	Appearance.Apply ( ThisObject );
	
EndProcedure 

&AtClient
Procedure WarehouseOnChange ( Item )
	
	refill ();
	
EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure Scan ( Command )
	
	ScanForm.Scan ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure ItemsBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ItemsQuantityPkgOnChange ( Item )
	
	Computations.Units ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	
EndProcedure
