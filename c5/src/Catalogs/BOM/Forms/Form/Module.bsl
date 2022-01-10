&AtClient
var ItemsRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
	endif; 
	setAccuracy ();
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	
EndProcedure

&AtServer
Procedure fillNew ()
	
	Object.Creator = SessionParameters.User;
	Object.Created = CurrentSessionDate ();
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	settings = Logins.Settings ( "Company" );
	Object.Company = settings.Company;
	Object.Prices = DF.Pick ( Object.Company, "CostPrices" );
	Object.Calculated = CurrentSessionDate ();
	Object.Technologist = DF.Pick ( Object.Creator, "Employee.Individual" );
	if ( not Object.Item.IsEmpty () ) then
		applyProduct ( Object );
	endif;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure applyProduct ( Object )
	
	data = DF.Values ( Object.Item, "Package, Package.Capacity as Capacity, FullDescription" );
	if ( data.Capacity = 0 ) then
		data.Capacity = 1;
	endif; 
	Object.Package = data.Package;
	Object.Capacity = data.Capacity;
	Object.Description = data.FullDescription;
	Computations.Units ( Object );
	
EndProcedure

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "Quantity, QuantityPkg" );
	
EndProcedure 

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageBarcodeScanned ()
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		addItem ( Parameter );
	endif; 
	
EndProcedure

&AtServer
Procedure addItem ( Fields )
	
	search = new Structure ( "Item, Package, Feature" );
	FillPropertyValues ( search, Fields );
	table = Object.Items;
	rows = table.FindRows ( search );
	if ( rows.Count () = 0 ) then
		row = table.Add ();
		item = Fields.Item;
		row.Item = item;
		package = Fields.Package;
		row.Package = package;
		feature = Fields.Feature;
		row.Feature = feature;
		row.QuantityPkg = Fields.QuantityPkg;
		row.Capacity = Fields.Capacity;
		row.Quantity = Fields.Quantity;
		row.Price = Goods.Price ( , Object.Calculated, Object.Prices, item, package, feature );
	else
		row = rows [ 0 ];
		row.Quantity = row.Quantity + Fields.Quantity;
		row.QuantityPkg = row.QuantityPkg + Fields.QuantityPkg;
	endif; 
	calcCost ( row );
	calcTotals ( Object );
	
EndProcedure 

&AtClientAtServerNoContext
Procedure calcCost ( TableRow )
	
	TableRow.Cost = TableRow.Price * TableRow.QuantityPkg;
	
EndProcedure

&AtClientAtServerNoContext
Procedure calcTotals ( Object )
	
	Object.Cost = Object.Items.Total ( "Cost" );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure Scan ( Command )
	
	ScanForm.Open ( ThisObject, true );
	
EndProcedure

&AtClient
Procedure Recalculate ( Command )
	
	recalc ();
	
EndProcedure

&AtServer
Procedure recalc ()
	
	for each row in Object.Items do
		priceItem ( Object, row );
		calcCost ( row );
	enddo;
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure PricesOnChange ( Item )
	
	recalc ();
	
EndProcedure

&AtClient
Procedure ItemOnChange ( Item )
	
	applyProduct ( Object );
	
EndProcedure

&AtClient
Procedure QuantityPkgOnChange ( Item )
	
	Computations.Units ( Object );
	
EndProcedure

&AtClient
Procedure PackageOnChange ( Item )
	
	applyProductPackage ();
	
EndProcedure

&AtClient
Procedure applyProductPackage ()
	
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
	p.Insert ( "Date", Object.Calculated );
	p.Insert ( "Company", Object.Company );
	p.Insert ( "Item", ItemsRow.Item );
	p.Insert ( "Prices", Object.Prices );
	data = getItemData ( p );
	ItemsRow.Package = data.Package;
	ItemsRow.Capacity = data.Capacity;
	ItemsRow.Price = data.Price;
	Computations.Units ( ItemsRow );
	calcCost ( ItemsRow );
	
EndProcedure

&AtServerNoContext
Function getItemData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "Package, Package.Capacity as Capacity" );
	price = Goods.Price ( , Params.Date, Params.Prices, item, data.Package );
	data.Insert ( "Price", price );
	if ( data.Capacity = 0 ) then
		data.Capacity = 1;
	endif; 
	return data;
	
EndFunction 

&AtClient
Procedure ItemsFeatureOnChange ( Item )
	
	priceItem ( Object, ItemsRow );
	calcCost ( ItemsRow );
	
EndProcedure

&AtClientAtServerNoContext
Procedure priceItem ( Object, TableRow )
	
	TableRow.Price = Goods.Price ( , Object.Calculated, Object.Prices, TableRow.Item, TableRow.Package, TableRow.Feature );
	
EndProcedure 

&AtClient
Procedure ItemsPackageOnChange ( Item )
	
	applyPackage ();
	
EndProcedure

&AtClient
Procedure applyPackage ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Calculated );
	p.Insert ( "Item", ItemsRow.Item );
	p.Insert ( "Feature", ItemsRow.Feature );
	p.Insert ( "Package", ItemsRow.Package );
	p.Insert ( "Prices", Object.Prices );
	data = getPackageData ( p );
	ItemsRow.Capacity = data.Capacity;
	ItemsRow.Price = data.Price;
	Computations.Units ( ItemsRow );
	calcCost ( ItemsRow );
	
EndProcedure 

&AtServerNoContext
Function getPackageData ( val Params )
	
	package = Params.Package;
	capacity = DF.Pick ( package, "Capacity", 1 );
	price = Goods.Price ( , Params.Date, Params.Prices, Params.Item, package, Params.Feature );
	data = new Structure ();
	data.Insert ( "Capacity", capacity );
	data.Insert ( "Price", price );
	return data;
	
EndFunction 

&AtClient
Procedure ItemsQuantityPkgOnChange ( Item )
	
	Computations.Units ( ItemsRow );
	calcCost ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	calcCost ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsPriceOnChange ( Item )

	calcCost ( ItemsRow );

EndProcedure

&AtClient
Procedure ItemsCostOnChange ( Item )
	
	calcPrice ();
	
EndProcedure

&AtClient
Procedure calcPrice ()
	
	quantity = ItemsRow.QuantityPkg;
	ItemsRow.Price = ItemsRow.Cost / ? ( quantity = 0, 1, quantity );
	
EndProcedure
