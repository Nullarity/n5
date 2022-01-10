&AtServer
var Env;
&AtClient
var TableRow;
&AtServer
var TableRow;
&AtClient
var AllocationRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	fillTables ();
	markAllocation ( getDeliveryDate ( ThisObject ), Object.Allocation );
	setCurrentItem ();
	Options.SetAccuracy ( ThisObject, "AllocationQuantity, AllocationQuantityAllocated" );
	if ( not Service ) then
		filterPackage ();
	endif; 
	Options.Company ( ThisObject, document ( ThisObject ).Company );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|PurchaseOrderGroup show Source.Type.PurchaseOrder;
	|ProductionOrderGroup show Source.Type.ProductionOrder;
	|ServiceGroup show Source.Type.PurchaseOrder and Service;
	|ItemGroup show Source.Type.PurchaseOrder and not Service;
	|ServiceGroupProduction show Source.Type.ProductionOrder and Service;
	|ItemGroupProduction show Source.Type.ProductionOrder and not Service;
	|VATCode VAT ServicesVATCode ServicesVAT show
	|	Source.Type.PurchaseOrder and PurchaseOrder.VATUse > 0;
	|Total ServicesTotal show PurchaseOrder.VATUse = 2;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadParams ()
	
	Source = Parameters.Source;
	Service = Parameters.Service;
	document = document ( ThisObject );
	if ( Service ) then
		TableRow = document.Services.Add ();
	else
		TableRow = document.Items.Add ();
	endif; 
	FillPropertyValues ( document, Source );
	FillPropertyValues ( TableRow, Parameters.TableRow );
	Warehouse = document.Warehouse;
	
EndProcedure

&AtClientAtServerNoContext
Function document ( Form )
	
	type = Form.Source.Type;
	if ( type.PurchaseOrder ) then
		return Form.PurchaseOrder;
	elsif ( type.ProductionOrder ) then
		return Form.ProductionOrder;
	endif;
	
EndFunction

&AtServer
Procedure fillTables ()
	
	getData ();
	Object.Allocation.Load ( Env.Allocation );
	
EndProcedure

&AtServer
Procedure getData ()
	
	SQL.Init ( Env );
	sqlAllocation ();
	q = Env.Q;
	document = document ( ThisObject );
	q.SetParameter ( "Period", ? ( document.Date = Date ( 1, 1, 1 ), undefined, document.Date ) );
	q.SetParameter ( "Item", TableRow.Item );
	q.SetParameter ( "Feature", TableRow.Feature );
	SQL.Perform ( Env );
	
EndProcedure

&AtServer
Procedure sqlAllocation ()
	
	s = "
	|select AllocationBalance.DocumentOrder as DocumentOrder, AllocationBalance.RowKey as RowKey, AllocationBalance.QuantityBalance as QuantityBalance
	|into AllocationBalance
	|from AccumulationRegister.Allocation.Balance ( &Period ) as AllocationBalance
	|index by DocumentOrder, RowKey
	|;
	|// #Allocation
	|select SalesOrder.Ref as DocumentOrder, SalesOrder.RowKey as RowKey, AllocationBalance.QuantityBalance as Quantity,
	|	SalesOrder.DeliveryDate as DeliveryDate, SalesOrder.Ref.Warehouse as Warehouse,
	|	SalesOrder.Ref.Customer.Description as Presentation
	|from AllocationBalance as AllocationBalance
	|	//
	|	// SalesOrder
	|	//
	|	join Document.SalesOrder.Items as SalesOrder
	|	on SalesOrder.Ref = AllocationBalance.DocumentOrder
	|	and SalesOrder.RowKey = AllocationBalance.RowKey
	|	and SalesOrder.Item = &Item
	|	and SalesOrder.Feature = &Feature
	|union all
	|select SalesOrder.Ref, SalesOrder.RowKey, AllocationBalance.QuantityBalance, SalesOrder.DeliveryDate, SalesOrder.Ref.Warehouse,
	|	SalesOrder.Ref.Customer.Description
	|from AllocationBalance as AllocationBalance
	|	//
	|	// SalesOrder
	|	//
	|	join Document.SalesOrder.Services as SalesOrder
	|	on SalesOrder.Ref = AllocationBalance.DocumentOrder
	|	and SalesOrder.RowKey = AllocationBalance.RowKey
	|	and SalesOrder.Item = &Item
	|	and SalesOrder.Feature = &Feature
	|union all
	|select InternalOrder.Ref, InternalOrder.RowKey, AllocationBalance.QuantityBalance, InternalOrder.DeliveryDate, InternalOrder.Ref.Warehouse,
	|	InternalOrder.Ref.Department.Description
	|from AllocationBalance as AllocationBalance
	|	//
	|	// InternalOrder
	|	//
	|	join Document.InternalOrder.Items as InternalOrder
	|	on InternalOrder.Ref = AllocationBalance.DocumentOrder
	|	and InternalOrder.RowKey = AllocationBalance.RowKey
	|	and InternalOrder.Item = &Item
	|	and InternalOrder.Feature = &Feature
	|union all
	|select InternalOrder.Ref, InternalOrder.RowKey, AllocationBalance.QuantityBalance, InternalOrder.DeliveryDate, InternalOrder.Ref.Warehouse,
	|	InternalOrder.Ref.Department.Description
	|from AllocationBalance as AllocationBalance
	|	//
	|	// InternalOrder
	|	//
	|	join Document.InternalOrder.Services as InternalOrder
	|	on InternalOrder.Ref = AllocationBalance.DocumentOrder
	|	and InternalOrder.RowKey = AllocationBalance.RowKey
	|	and InternalOrder.Item = &Item
	|	and InternalOrder.Feature = &Feature
	|order by DeliveryDate, Quantity
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtClientAtServerNoContext
Procedure markAllocation ( DeliveryDate, Allocation )
	
	for each row in Allocation do
		row.Use = row.DeliveryDate <= DeliveryDate;
	enddo; 

EndProcedure

&AtClientAtServerNoContext
Function getDeliveryDate ( Form )
	
	row = tableRow ( Form );
	return ? ( row.DeliveryDate = Date ( 1, 1, 1 ), document ( Form ).DeliveryDate, row.DeliveryDate );
	
EndFunction 

&AtClientAtServerNoContext
Function tableRow ( Form )
	
	document = document ( Form );
	return ? ( Form.Service, document.Services [ 0 ], document.Items [ 0 ] );
	
EndFunction 

&AtServer
Procedure setCurrentItem ()
	
	if ( Service ) then
		CurrentItem = Items.ServicesPrice;
	else
		if ( Options.Packages () ) then
			CurrentItem = Items.QuantityPkg;
		endif; 
	endif; 
	
EndProcedure 

&AtServer
Procedure filterPackage ()
	
	a = new Array ();
	a.Add ( new ChoiceParameter ( "Filter.Owner", TableRow.Item ) );
	Items.Package.ChoiceParameters = new FixedArray ( a );
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	TableRow = tableRow ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	if ( not checkQuantity () ) then
		return;
	endif; 
	performChoice ();
	
EndProcedure

&AtClient
Function checkQuantity ()
	
	allocated = Object.Allocation.Total ( "Allocated" );
	if ( allocated > TableRow.Quantity ) then
		Output.QuantityLessReservation ();
		return false;
	endif;
	return true;
	
EndFunction

&AtClient
Procedure performChoice ()
	
	result = getResult ();
	if ( Parameters.Command = Enum.PickItemsCommandsAllocate () ) then
		operation = ? ( Service, Enum.ChoiceOperationsAllocateServices (), Enum.ChoiceOperationsAllocateItems () );
		NotifyChoice ( new Structure ( "Operation, Result", operation, result ) );
	else
		NotifyChoice ( result );
	endif;
	
EndProcedure 

&AtClient
Function getResult ()
	
	result = new Array ();
	addAllocations ( result );
	addRest ( result );
	return result;

EndFunction

&AtClient
Procedure addAllocations ( Result )
	
	directProvision = PredefinedValue ( "Enum.Provision.Directly" );
	pricing = Source.Type.PurchaseOrder;
	vatUse = ? ( pricing, PurchaseOrder.VATUse, false );
	for each allocatedRow in Object.Allocation do
		if ( not allocatedRow.Use or allocatedRow.Allocated = 0 ) then
			continue;
		endif; 
		Result.Add ( document ( ThisObject ).Items.Add () );
		row = Result [ Result.UBound () ];
		FillPropertyValues ( row, TableRow );
		row.DocumentOrder = allocatedRow.DocumentOrder;
		row.DocumentOrderRowKey = allocatedRow.RowKey;
		row.Quantity = allocatedRow.Allocated;
		if ( not Service ) then
			row.Provision = directProvision;
			row.QuantityPkg = row.Quantity / TableRow.Capacity;
		endif; 
		TableRow.Quantity = TableRow.Quantity - row.Quantity;
		if ( not Service ) then
			TableRow.QuantityPkg = TableRow.QuantityPkg - row.QuantityPkg;
		endif; 
		if ( pricing ) then
			Computations.Discount ( row );
			Computations.Amount ( row );
			Computations.Total ( row, vatUse );
			TableRow.Amount = TableRow.Amount - row.Amount;
			TableRow.Discount = TableRow.Discount - row.Discount;
			TableRow.VAT = TableRow.VAT - row.VAT;
			TableRow.Total = TableRow.Total - row.Total;
		endif;
	enddo; 
	
EndProcedure

&AtClient
Procedure addRest ( Result )
	
	if ( TableRow.Quantity > 0 ) then
		Result.Add ( TableRow );
		row = Result [ Result.UBound () ];
		if ( Source.Type.PurchaseOrder ) then
			Computations.Amount ( row );
		endif;
	endif; 
	
EndProcedure 

&AtClient
Procedure PackageOnChange ( Item )
	
	applyPackage ();
	
EndProcedure

&AtServer
Procedure applyPackage ()
	
	TableRow = tableRow ( ThisObject );
	package = TableRow.Package;
	TableRow.Capacity = DF.Pick ( package, "Capacity", 1 );
	Computations.Units ( TableRow );
	if ( Source.Type.PurchaseOrder ) then
		priceItem ( PurchaseOrder, TableRow );
		Computations.Amount ( TableRow );
		Computations.Total ( TableRow, PurchaseOrder.VATUse );
	endif;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure priceItem ( PurchaseOrder, TableRow )
	
	TableRow.Price = Goods.Price ( , PurchaseOrder.Date, TableRow.Prices, TableRow.Item, TableRow.Package, TableRow.Feature, PurchaseOrder.Vendor, PurchaseOrder.Contract, true, PurchaseOrder.Warehouse, PurchaseOrder.Currency );
	
EndProcedure 

&AtClient
Procedure QuantityPkgOnChange ( Item )
	
	Computations.Units ( TableRow );
	if ( Source.Type.PurchaseOrder ) then
		Computations.Amount ( TableRow );
		Computations.Total ( TableRow, PurchaseOrder.VATUse );
	endif;
	
EndProcedure

&AtClient
Procedure QuantityOnChange ( Item )
	
	if ( not Service ) then
		Computations.Packages ( TableRow );
	endif; 
	if ( Source.Type.PurchaseOrder ) then
		Computations.Amount ( TableRow );
		Computations.Total ( TableRow, PurchaseOrder.VATUse );
	endif;
	
EndProcedure

&AtClient
Procedure PricesOnChange ( Item )
	
	priceItem ( PurchaseOrder, TableRow );
	Computations.Amount ( TableRow );
	Computations.Total ( TableRow, PurchaseOrder.VATUse );
	
EndProcedure

&AtClient
Procedure PriceOnChange ( Item )
	
	Computations.Discount ( TableRow );
	Computations.Amount ( TableRow );
	Computations.Total ( TableRow, PurchaseOrder.VATUse );
	
EndProcedure

&AtClient
Procedure DiscountRateOnChange ( Item )
	
	Computations.Discount ( TableRow );
	Computations.Amount ( TableRow );
	Computations.Total ( TableRow, PurchaseOrder.VATUse );
	
EndProcedure

&AtClient
Procedure DiscountOnChange ( Item )
	
	Computations.DiscountRate ( TableRow );
	Computations.Amount ( TableRow );
	Computations.Total ( TableRow, PurchaseOrder.VATUse );
	
EndProcedure

&AtClient
Procedure AmountOnChange ( Item )
	
	Computations.Price ( TableRow );
	Computations.Discount ( TableRow );
	Computations.Total ( TableRow, PurchaseOrder.VATUse );
	
EndProcedure

&AtClient
Procedure DeliveryDateOnChange ( Item )
	
	markAllocation ( getDeliveryDate ( ThisObject ), Object.Allocation );
	
EndProcedure

// *****************************************
// *********** Table Allocation

&AtClient
Procedure AllocateQuantity ( Command )
	
	allocateQuantityByOrders ();
	
EndProcedure

&AtClient
Procedure allocateQuantityByOrders ()
	
	filter = new Structure ( "Use", true );
	Collections.Slice ( TableRow.Quantity, Object.Allocation, "Quantity", "Allocated", filter );
	
EndProcedure

&AtClient
Procedure AllocationOnActivateRow ( Item )
	
	AllocationRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure AllocationBeforeAddRow ( Item, Cancel, Clone, Parent, Folder )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure AllocationBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure ClearAllocatedQuantity ( Command )
	
	clearAllocationQuantity ();
	
EndProcedure

&AtClient
Procedure clearAllocationQuantity ()
	
	Collections.FillDataCollection ( Object.Allocation, "Allocated", 0 );
	
EndProcedure

&AtClient
Procedure CheckAllocation ( Command )
	
	Forms.MarkRows ( Object.Allocation, true );

EndProcedure

&AtClient
Procedure UncheckAllocation ( Command )
	
	Forms.MarkRows ( Object.Allocation, false );
	clearAllocationQuantity ();

EndProcedure

&AtClient
Procedure AllocationBeforeEditEnd ( Item, NewRow, CancelEdit, Cancel )
	
	if ( CancelEdit ) then
		return;
	endif; 
	if ( not allocationCorrect () ) then
		Cancel = true;
		Output.QuantityAllocatedGreatOrderQuantity ();
		adjustAllocation ();
	endif; 
	
EndProcedure

&AtClient
Function allocationCorrect ()
	
	error = AllocationRow.Use and ( AllocationRow.Allocated > TableRow.Quantity );
	return not error;
	
EndFunction

&AtClient
Procedure adjustAllocation ()
	
	AllocationRow.Allocated = TableRow.Quantity;
	
EndProcedure

&AtClient
Procedure AllocationUseOnChange ( Item )
	
	resetAllocation ();
	
EndProcedure
 
&AtClient
Procedure resetAllocation ()
	
	if ( not AllocationRow.Use ) then
		AllocationRow.Allocated = 0;
	endif;
	
EndProcedure

&AtClient
Procedure AllocationQuantityAllocatedOnChange ( Item )
	
	AllocationRow.Use = true;
	
EndProcedure

&AtClient
Procedure VATCodeOnChange ( Item )
	
	TableRow.VATRate = DF.Pick ( TableRow.VATCode, "Rate" );
	Computations.Total ( TableRow, PurchaseOrder.VATUse );
	
EndProcedure

&AtClient
Procedure VATOnChange ( Item )
	
	Computations.Total ( TableRow, PurchaseOrder.VATUse, false );
	
EndProcedure
