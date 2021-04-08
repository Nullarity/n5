&AtServer
var Env;
&AtClient
var ReservationRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	fillTables ();
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
	|Price Amount Prices show ShowPrice;
	|ChangeReservation show ShowReservation;
	|VATCode VAT Total show ( ShowPrice and VATUse > 0 )
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
	ShowPrice = Source.ShowPrice;
	VATUse = Source.VATUse;
	VATCode = TableRow.VATCode;
	VATRate = TableRow.VATRate;
	VAT = TableRow.VAT;
	Total = TableRow.Total;
	
EndProcedure

&AtServer
Procedure fillTables ()
	
	getData ();
	reservation = Env.Reservation;
	if ( reservation.Count () = 0 ) then
		ShowReservation = false;
	else
		ShowReservation = true;
		Object.ChangeReservation.Load ( reservation );
	endif;
	
EndProcedure

&AtServer
Procedure getData ()
	
	SQL.Init ( Env );
	sqlOrders ();
	sqlReservation ();
	q = Env.Q;
	q.SetParameter ( "Period", ? ( Source.Date = Date ( 1, 1, 1 ), undefined, Source.Date ) );
	q.SetParameter ( "Item", Item );
	q.SetParameter ( "Feature", Feature );
	q.SetParameter ( "Warehouse", Source.Warehouse );
	q.SetParameter ( "Package", ? ( CountPackages, Package, Catalogs.Packages.EmptyRef () ) );
	SQL.Perform ( Env );
	
EndProcedure

&AtServer
Procedure sqlOrders () 

	s = "
	|// Orders
	|select Reserves.DocumentOrder as DocumentOrder, Reserves.DocumentOrder.Date as Date, Reserves.RowKey.Code as Code,
	|	Reserves.RowKey as RowKey, Reserves.QuantityBalance as Reserved 
	|into Orders
	|from AccumulationRegister.Reserves.Balance ( &Period, Warehouse = &Warehouse ) as Reserves
	|where Reserves.QuantityBalance > 0
	|index by Reserves.DocumentOrder, Reserves.RowKey
	|";
	Env.Selection.Add ( s );

EndProcedure

&AtServer
Procedure sqlReservation ()
	
	s = "
	|// #Reservation
	|select true as Use, Orders.DocumentOrder as DocumentOrder, Orders.Reserved as Reserved, Orders.RowKey as RowKey, 1 as Table, Orders.Date as Date, 
	|	Orders.Code as Code, case when Items.Item.CountPackages then Orders.Reserved / Items.Capacity else Orders.Reserved end as ReservedPkg
	|from Orders as Orders
	|	//
	|	// SalesOrderItems
	|	//
	|	join Document.SalesOrder.Items as Items
	|	on Items.RowKey = Orders.RowKey
	|	and Items.Ref = Orders.DocumentOrder
	|where Items.Item = &Item
	|and Items.Feature = &Feature
	|";
	if ( CountPackages ) then
		s = s + "and Items.Package = &Package";
	endif;
	s = s + "
	|union all
	|select true, Orders.DocumentOrder, Orders.Reserved, Orders.RowKey, 2, Orders.Date, Orders.Code,
	|	case when Items.Item.CountPackages then Orders.Reserved / Items.Capacity else Orders.Reserved end
	|from Orders as Orders
	|	//
	|	// InternalOrderItems
	|	//
	|	join Document.InternalOrder.Items as Items
	|	on Items.RowKey = Orders.RowKey
	|	and Items.Ref = Orders.DocumentOrder
	|where Items.Item = &Item 
	|and Items.Feature = &Feature 
	|";
	if ( CountPackages ) then
		s = s + "and Items.Package = &Package";
	endif;
	s = s + "
	|order by Table, Orders.Date, Orders.Code
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure setCurrentItem ()
	
	if ( Options.Packages () ) then
		CurrentItem = Items.QuantityPkg;
	endif; 
	
EndProcedure 

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "Quantity, QuantityPkg, ChangeReservationQuantity" );
	Options.SetAccuracy ( ThisObject, "ChangeReservationReserved, ChangeReservationReservedPkg", , false );
	
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
	
	reserved = getReserved ();
	if ( reserved > 0
		and Quantity > reserved  ) then
		Output.QuantitySelectedGreatReservedQuantity ();
		return false;
	endif;
	return true;
	
EndFunction

&AtClient
Function getReserved () 

	reserved = 0;
	rows = Object.ChangeReservation.FindRows ( new Structure ( "Use", true ) );
	for each row in rows do
		reserved = reserved + row.Reserved;
	enddo;
	return reserved;

EndFunction

&AtClient
Procedure performChoice ()
	
	NotifyChoice ( getResult () );
	
EndProcedure 

&AtClient
Function getResult ()
	
	FillPropertyValues ( TableRow, ThisObject );
	result = new Array ();
	addReserves ( result );
	addRest ( result );
	return result;
	
EndFunction

&AtClient
Procedure addReserves ( Result )
	
	for each reserveRow in Object.ChangeReservation do
		if ( not reserveRow.Use or reserveRow.Quantity = 0 ) then
			continue;
		endif; 
		Result.Add ( Collections.CopyStructure ( TableRow ) );
		row = Result [ Result.UBound () ];
		row.DocumentOrder = reserveRow.DocumentOrder;
		row.RowKey = reserveRow.RowKey;
		row.Quantity = reserveRow.Quantity;
		row.QuantityPkg = row.Quantity / Capacity;
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
	Computations.Total ( ThisObject, VATUse );
	if ( CountPackages ) then
		fillTables ();
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
	
	Computations.Amount ( ThisObject );
	Computations.Total ( ThisObject, VATUse );
	
EndProcedure

&AtClient
Procedure AmountOnChange ( Item )
	
	Computations.Price ( ThisObject );
	Computations.Total ( ThisObject, VATUse );
	
EndProcedure

// *****************************************
// *********** Table ChangeReservation

&AtClient
Procedure ReserveQuantity ( Command )
	
	distributeReserve ();
	
EndProcedure

&AtClient
Procedure distributeReserve ()
	
	filter = new Structure ( "Use", true );
	Collections.Slice ( Quantity, Object.ChangeReservation, "Reserved", "Quantity", filter );
	
EndProcedure

&AtClient
Procedure ClearSelectedQuantity ( Command )
	
	cleanSelection ();
	
EndProcedure

&AtClient
Procedure cleanSelection ()
	
	Collections.FillDataCollection ( Object.ChangeReservation, "Quantity", 0 );
	
EndProcedure

&AtClient
Procedure CheckReserves ( Command )
	
	Forms.MarkRows ( Object.ChangeReservation, true );

EndProcedure

&AtClient
Procedure UncheckReserves ( Command )
	
	Forms.MarkRows ( Object.ChangeReservation, false );
	cleanSelection ();
	
EndProcedure

&AtClient
Procedure ChangeReservationOnActivateRow ( Item )
	
	ReservationRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ChangeReservationBeforeAddRow ( Item, Cancel, Clone, Parent, Folder )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure ChangeReservationBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure ChangeReservationBeforeEditEnd ( Item, NewRow, CancelEdit, Cancel )
	
	if ( CancelEdit ) then
		return;
	endif; 
	if ( not reservationCorrect () ) then
		Cancel = true;
		Output.QuantitySelectedGreatReservedQuantity ();
		adjustReserve ();
	endif; 
	
EndProcedure

&AtClient
Function reservationCorrect ()
	
	error = ReservationRow.Use and ( ReservationRow.Quantity > ReservationRow.Reserved  );
	return not error;
	
EndFunction

&AtClient
Procedure adjustReserve ()
	
	ReservationRow.Quantity = ReservationRow.Reserved;
	
EndProcedure

&AtClient
Procedure ChangeReservationUseOnChange ( Item )
	
	if ( not ReservationRow.Use ) then
		ReservationRow.Quantity = 0;
	endif;
	
EndProcedure
 
&AtClient
Procedure ChangeReservationQuantityOnChange ( Item )
	
	ReservationRow.Use = true;
	
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
