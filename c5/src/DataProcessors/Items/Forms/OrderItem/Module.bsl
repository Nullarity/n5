&AtServer
var Env;
&AtClient
var ReservationRow;
&AtClient
var AllocationRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	fillTables ();
	markAllocation ( getDeliveryDate ( ThisObject ), Object.Provision );
	setCurrentItem ();
	setAccuracy ();
	Options.Company ( ThisObject, Source.Company );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Discount DiscountRate enable DiscountApplicable;
	|VATCode VAT Total show VATUse > 0
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadParams ()
	
	CountPackages = Parameters.CountPackages;
	Source = Parameters.Source;
	TableRow = Parameters.TableRow;
	FillPropertyValues ( ThisObject, Source );
	FillPropertyValues ( ThisObject, TableRow );
	DiscountApplicable = Source.Type.SalesOrder;
	VATUse = Source.VATUse;
	VATCode = TableRow.VATCode;
	VATRate = TableRow.VATRate;
	VAT = TableRow.VAT;
	Total = TableRow.Total;
	
EndProcedure

&AtServer
Procedure fillTables ( val Allocation = true )
	
	getData ( Allocation );
	Object.Reservation.Load ( Env.Reservation );
	if ( Allocation ) then
		Object.Provision.Load ( Env.Provision );
	endif; 
	
EndProcedure

&AtServer
Procedure getData ( Allocation )
	
	SQL.Init ( Env );
	sqlReservation ();
	if ( Allocation ) then
		sqlAllocation ();
	endif; 
	q = Env.Q;
	q.SetParameter ( "Period", ? ( Source.Date = Date ( 1, 1, 1 ), undefined, Source.Date ) );
	q.SetParameter ( "Item", Item );
	q.SetParameter ( "Feature", Feature );
	q.SetParameter ( "Warehouse", Source.Warehouse );
	q.SetParameter ( "Package", ? ( CountPackages, Package, Catalogs.Packages.EmptyRef () ) );
	SQL.Perform ( Env );
	
EndProcedure

&AtServer
Procedure sqlReservation ()
	
	s = "
	|// #Reservation
	|select true as Use, ItemWarehousesBalance.Warehouse as Warehouse, ItemWarehousesBalance.QuantityBalance as Quantity";
	if ( CountPackages ) then
		s = s + ", presentation ( ItemWarehousesBalance.Package )";
	else
		s = s + ", presentation ( ItemWarehousesBalance.Item.Unit )";
	endif; 
	s = s + " as Package
	|from AccumulationRegister.Items.Balance ( &Period, Item = &Item and Feature = &Feature and Package = &Package ) as ItemWarehousesBalance
	|order by case when ItemWarehousesBalance.Warehouse = &Warehouse then 1 else 0 end desc, ItemWarehousesBalance.QuantityBalance desc
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure sqlAllocation ()
	
	s = "
	|select AllocationBalance.DocumentOrder as DocumentOrder, AllocationBalance.RowKey as RowKey, AllocationBalance.QuantityBalance as QuantityBalance
	|into AllocationBalance
	|from AccumulationRegister.Provision.Balance ( &Period ) as AllocationBalance
	|index by DocumentOrder, RowKey
	|;
	|// #Provision
	|select PurchaseOrders.Ref as DocumentOrder, PurchaseOrders.RowKey as RowKey, AllocationBalance.QuantityBalance as Quantity,
	|	PurchaseOrders.DeliveryDate as DeliveryDate, PurchaseOrders.Ref.Warehouse as Warehouse,
	|	PurchaseOrders.Ref.Vendor.Description as Presentation
	|from AllocationBalance as AllocationBalance
	|	//
	|	// PurchaseOrders
	|	//
	|	join Document.PurchaseOrder.Items as PurchaseOrders
	|	on PurchaseOrders.Ref = AllocationBalance.DocumentOrder
	|	and PurchaseOrders.RowKey = AllocationBalance.RowKey
	|	and PurchaseOrders.Item = &Item
	|	and PurchaseOrders.Feature = &Feature
	|union all
	|select ProductionOrders.Ref, ProductionOrders.RowKey, AllocationBalance.QuantityBalance,
	|	ProductionOrders.DeliveryDate, ProductionOrders.Ref.Warehouse, ProductionOrders.Ref.Department.Description
	|from AllocationBalance as AllocationBalance
	|	//
	|	// ProductionOrders
	|	//
	|	join Document.ProductionOrder.Items as ProductionOrders
	|	on ProductionOrders.Ref = AllocationBalance.DocumentOrder
	|	and ProductionOrders.RowKey = AllocationBalance.RowKey
	|	and ProductionOrders.Item = &Item
	|	and ProductionOrders.Feature = &Feature
	|order by DeliveryDate, Quantity
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtClientAtServerNoContext
Function getDeliveryDate ( Form )
	
	return ? ( Form.DeliveryDate = Date ( 1, 1, 1 ), Form.Source.DeliveryDate, Form.DeliveryDate );
	
EndFunction 

&AtClientAtServerNoContext
Procedure markAllocation ( DeliveryDate, Provision )
	
	for each row in Provision do
		row.Use = DeliveryDate <> undefined and ( row.DeliveryDate <= DeliveryDate );
	enddo; 

EndProcedure

&AtServer
Procedure setCurrentItem ()
	
	if ( Options.Packages () ) then
		CurrentItem = Items.QuantityPkg;
	endif; 
	
EndProcedure 

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "Quantity, QuantityPkg, WarehousesReservationQuantityReserved, ProvisionQuantity, ProvisionAllocated" );
	Options.SetAccuracy ( ThisObject, "WarehousesReservationQuantity", , false );
	
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
	
	reserved = Object.Reservation.Total ( "Reserved" );
	if ( CountPackages ) then
		reserved = reserved * Capacity;
	endif;
	allocated = Object.Provision.Total ( "Allocated" );
	if ( ( reserved + allocated ) > Quantity ) then
		Output.QuantityLessReservationAndAllocation ();
		return false;
	endif;
	return true;
	
EndFunction

&AtClient
Procedure performChoice ()
	
	result = getResult ();
	if ( Parameters.Command = Enum.PickItemsCommandsReserve () ) then
		NotifyChoice ( new Structure ( "Operation, Result", Enum.ChoiceOperationsReserveItems (), result ) );
	else
		NotifyChoice ( result );
	endif;
	
EndProcedure 

&AtClient
Function getResult ()
	
	FillPropertyValues ( TableRow, ThisObject );
	result = new Array ();
	addReserves ( result );
	addAllocations ( result );
	addRest ( result );
	return result;
	
EndFunction

&AtClient
Procedure addReserves ( Result )
	
	warehouseReservation = PredefinedValue ( "Enum.Reservation.Warehouse" );
	for each reserveRow in Object.Reservation do
		if ( not reserveRow.Use or reserveRow.Reserved = 0 ) then
			continue;
		endif; 
		Result.Add ( Collections.CopyStructure ( TableRow ) );
		row = Result [ Result.UBound () ];
		row.Reservation = warehouseReservation;
		row.Stock = reserveRow.Warehouse;
		if ( CountPackages ) then
			row.QuantityPkg = reserveRow.Reserved;
			row.Quantity = reserveRow.Reserved * Capacity;
		else
			row.Quantity = reserveRow.Reserved;
			row.QuantityPkg = row.Quantity / Capacity;
		endif; 
		if ( DiscountApplicable ) then
			Computations.Discount ( row );
			TableRow.Discount = TableRow.Discount - row.Discount;
		endif; 
		Computations.Amount ( row );
		Computations.Total ( row, VATUse );
		TableRow.Quantity = TableRow.Quantity - row.Quantity;
		TableRow.QuantityPkg = TableRow.QuantityPkg - row.QuantityPkg;
		TableRow.Amount = TableRow.Amount - row.Amount;
		TableRow.VAT = TableRow.VAT - row.VAT;
		TableRow.Total = TableRow.Total - row.Total;
	enddo; 
	
EndProcedure 

&AtClient
Procedure addAllocations ( Result )
	
	poReservation = PredefinedValue ( "Enum.Reservation.PurchaseOrder" );
	for each allocatedRow in Object.Provision do
		if ( not allocatedRow.Use or allocatedRow.Allocated = 0 ) then
			continue;
		endif; 
		Result.Add ( Collections.CopyStructure ( TableRow ) );
		row = Result [ Result.UBound () ];
		row.Reservation = poReservation;
		row.DocumentOrder = allocatedRow.DocumentOrder;
		row.DocumentOrderRowKey = allocatedRow.RowKey;
		row.Quantity = allocatedRow.Allocated;
		row.QuantityPkg = row.Quantity / Capacity;
		TableRow.Quantity = TableRow.Quantity - row.Quantity;
		TableRow.QuantityPkg = TableRow.QuantityPkg - row.QuantityPkg;
		Computations.Amount ( row );
		Computations.Total ( row, VATUse );
	enddo; 
	
EndProcedure

&AtClient
Procedure addRest ( Result )
	
	if ( TableRow.Quantity > 0 ) then
		Result.Add ( TableRow );
		row = Result [ Result.UBound () ];
		Computations.Amount ( row );
	endif; 
	
EndProcedure 

&AtClient
Procedure PackageOnChange ( Item )
	
	applyPackage ();
	
EndProcedure

&AtServer
Procedure applyPackage ()
	
	Capacity = DF.Pick ( Package, "Capacity", 1 );
	Price = Goods.Price ( , Source.Date, Prices, Item, Package, Feature, Source.Customer, Source.Contract, , Source.Warehouse, Source.Currency );
	Computations.Units ( ThisObject );
	Computations.Amount ( ThisObject );
	if ( CountPackages ) then
		fillTables ( false );
	endif; 
	
EndProcedure 

&AtClient
Procedure QuantityPkgOnChange ( Item )
	
	Computations.Units ( ThisObject );
	Computations.Amount ( ThisObject );
	Computations.Total ( ThisObject, VATUse );
	
EndProcedure

&AtClient
Procedure QuantityOnChange ( Item )
	
	Computations.Packages ( ThisObject );
	Computations.Amount ( ThisObject );
	Computations.Total ( ThisObject, VATUse );
	
EndProcedure

&AtClient
Procedure PricesOnChange ( Item )
	
	priceItem ();
	Computations.Amount ( ThisObject );
	Computations.Total ( ThisObject, VATUse );
	
EndProcedure

&AtClient
Procedure priceItem ()
	
	Price = Goods.Price ( , Source.Date, Prices, Item, Package, Feature, Source.Customer, Source.Contract, , Source.Warehouse, Source.Currency );
	
EndProcedure 

&AtClient
Procedure PriceOnChange ( Item )
	
	Computations.Discount ( ThisObject );
	Computations.Amount ( ThisObject );
	Computations.Total ( ThisObject, VATUse );
	
EndProcedure

&AtClient
Procedure DiscountRateOnChange ( Item )
	
	Computations.Discount ( ThisObject );
	Computations.Amount ( ThisObject );
	Computations.Total ( ThisObject, VATUse );
	
EndProcedure

&AtClient
Procedure DiscountOnChange ( Item )
	
	Computations.DiscountRate ( ThisObject );
	Computations.Amount ( ThisObject );
	Computations.Total ( ThisObject, VATUse );
	
EndProcedure

&AtClient
Procedure AmountOnChange ( Item )
	
	Computations.Price ( ThisObject );
	Computations.Discount ( ThisObject );
	Computations.Total ( ThisObject, VATUse );
	
EndProcedure

&AtClient
Procedure DeliveryDateOnChange ( Item )
	
	markAllocation ( getDeliveryDate ( ThisObject ), Object.Provision );
	
EndProcedure

// *****************************************
// *********** Table WarehousesReservation

&AtClient
Procedure ReserveQuantity ( Command )
	
	distributeReserve ();
	
EndProcedure

&AtClient
Procedure distributeReserve ()
	
	filter = new Structure ( "Use", true );
	value = ? ( CountPackages, QuantityPkg, Quantity );
	Collections.Slice ( value, Object.Reservation, "Quantity", "Reserved", filter );
	
EndProcedure

&AtClient
Procedure ClearReservedQuantity ( Command )
	
	cleanReservation ();
	
EndProcedure

&AtClient
Procedure cleanReservation ()
	
	Collections.FillDataCollection ( Object.Reservation, "Reserved", 0 );
	
EndProcedure

&AtClient
Procedure CheckReserves ( Command )
	
	Forms.MarkRows ( Object.Reservation, true );

EndProcedure

&AtClient
Procedure UncheckReserves ( Command )
	
	Forms.MarkRows ( Object.Reservation, false );
	cleanReservation ();
	
EndProcedure

&AtClient
Procedure WarehousesReservationOnActivateRow ( Item )
	
	ReservationRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure WarehousesReservationBeforeAddRow ( Item, Cancel, Clone, Parent, Folder )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure WarehousesReservationBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure WarehousesReservationBeforeEditEnd ( Item, NewRow, CancelEdit, Cancel )
	
	if ( CancelEdit ) then
		return;
	endif; 
	if ( not reservationCorrect () ) then
		Cancel = true;
		Output.QuantityReservedGreatWarehouseQuantity ();
		adjustReserve ();
	endif; 
	
EndProcedure

&AtClient
Function reservationCorrect ()
	
	error = ReservationRow.Use and ( ReservationRow.Reserved > ReservationRow.Quantity );
	return not error;
	
EndFunction

&AtClient
Procedure adjustReserve ()
	
	ReservationRow.Reserved = ReservationRow.Quantity;
	
EndProcedure

&AtClient
Procedure WarehousesReservationUseOnChange ( Item )
	
	if ( not ReservationRow.Use ) then
		ReservationRow.Reserved = 0;
	endif;
	
EndProcedure
 
&AtClient
Procedure WarehousesReservationQuantityReservedOnChange ( Item )
	
	ReservationRow.Use = true;
	
EndProcedure

// *****************************************
// *********** Table Provision

&AtClient
Procedure AllocateQuantity ( Command )
	
	distributeAllocation ();
	
EndProcedure

&AtClient
Procedure distributeAllocation ()
	
	filter = new Structure ( "Use", true );
	Collections.Slice ( Quantity, Object.Provision, "Quantity", "Allocated", filter );
	
EndProcedure

&AtClient
Procedure ProvisionBeforeAddRow ( Item, Cancel, Clone, Parent, Folder )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure ProvisionBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure ClearAllocatedQuantity ( Command )
	
	cleanAllocation ();
	
EndProcedure

&AtClient
Procedure cleanAllocation ()
	
	Collections.FillDataCollection ( Object.Provision, "Allocated", 0 );
	
EndProcedure

&AtClient
Procedure CheckAllocation ( Command )
	
	Forms.MarkRows ( Object.Provision, true );

EndProcedure

&AtClient
Procedure UncheckAllocation ( Command )
	
	Forms.MarkRows ( Object.Provision, false );
	cleanAllocation ();

EndProcedure

&AtClient
Procedure ProvisionOnActivateRow ( Item )
	
	AllocationRow = Item.CurrentData;

EndProcedure

&AtClient
Procedure ProvisionBeforeEditEnd ( Item, NewRow, CancelEdit, Cancel )
	
	if ( CancelEdit ) then
		return;
	endif; 
	if ( not allocationCorrect () ) then
		Cancel = true;
		Output.QuantityAllocatedGreatOrderQuantity ();
		adjustAllocation ();
		return;
	endif; 
	
EndProcedure

&AtClient
Function allocationCorrect ()
	
	error = AllocationRow.Use and ( AllocationRow.Allocated > AllocationRow.Quantity );
	return not error;
	
EndFunction

&AtClient
Procedure adjustAllocation ()
	
	AllocationRow.Allocated = AllocationRow.Quantity;
	
EndProcedure

&AtClient
Procedure ProvisionUseOnChange ( Item )
	
	resetAllocation ();
	
EndProcedure
 
&AtClient
Procedure resetAllocation ()
	
	if ( not AllocationRow.Use ) then
		AllocationRow.Allocated = 0;
	endif;
	
EndProcedure

&AtClient
Procedure ProvisionAllocatedOnChange ( Item )
	
	AllocationRow.Use = true;
	
EndProcedure

&AtClient
Procedure VATCodeOnChange ( Item )
	
	VATRate = DF.Pick ( VATCode, "Rate" );
	Computations.Total ( ThisObject, VATUse );
	
EndProcedure

&AtClient
Procedure VATOnChange ( Item )
	
	Computations.Total ( ThisObject, VATUse, false );
	
EndProcedure
