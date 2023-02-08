#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.InternalOrder.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

Function DeliveryComplete ( InternalOrder ) export
	
	s = "
	|select top 1 1
	|from AccumulationRegister.InternalOrders.Balance ( , InternalOrder = &InternalOrder ) as Balances
	|where Balances.QuantityBalance > 0
	|";
	q = new Query ( s );
	q.SetParameter ( "InternalOrder", InternalOrder );
	return q.Execute ().IsEmpty ();
	
EndFunction 

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	makeInternalOrders ( Env );
	makeAllocations ( Env );
	makeReserves ( Env );
	if ( not makeProvision ( Env ) ) then
		return false;
	endif; 
	if ( not checkBalances ( Env ) ) then
		return false;
	endif; 
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )
	
	sqlFields ( Env );
	sqlItems ( Env );
	sqlOrders ( Env );
	sqlAllocation ( Env );
	sqlItemReserves ( Env );
	getTables ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date
	|from Document.InternalOrder as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlItems ( Env )
	
	s = "
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Feature as Feature, Items.Stock as Stock,
	|	Items.Series as Series, Items.DocumentOrder as DocumentOrder, Items.DocumentOrderRowKey as DocumentOrderRowKey,
	|	Items.RowKey as RowKey, Items.Reservation as Reservation, Items.Quantity as Quantity,
	|	case when Items.Item.CountPackages then Items.QuantityPkg else Items.Quantity end as QuantityPkg,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package
	|into Items
	|from Document.InternalOrder.Items as Items
	|where Items.Ref = &Ref
	|index by Reservation
	|;
	|select Services.LineNumber as LineNumber, Services.RowKey as RowKey, Services.Quantity as Quantity, Services.Performer as Performer
	|into Services
	|from Document.InternalOrder.Services as Services
	|where Services.Ref = &Ref
	|index by Performer
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlOrders ( Env )
	
	s = "
	|// ^Order
	|select Items.LineNumber as LineNumber, Items.Quantity as Quantity, Items.RowKey as RowKey
	|from Items as Items
	|union all
	|select Services.LineNumber, Services.Quantity, Services.RowKey
	|from Services as Services
	|order by LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlAllocation ( Env )
	
	s = "
	|// ^Allocation
	|select Items.RowKey as RowKey, Quantity as Quantity
	|from Items as Items
	|where Items.Reservation = value ( Enum.Reservation.Invoice )
	|union all
	|select Services.RowKey as RowKey, Services.Quantity as Quantity
	|from Services as Services
	|where Services.Performer = value ( Enum.Performers.Vendor )
	|;
	|// ^Provision
	|select Items.LineNumber as LineNumber, Items.Quantity as Quantity, Items.DocumentOrder as DocumentOrder, Items.DocumentOrderRowKey as DocumentOrderRowKey,
	|	case when PurchaseOrders.Item is null and ProductionOrders.Item is null then true else false end as InvalidRow
	|from Items as Items
	|	//
	|	// PurchaseOrders
	|	//
	|	left join Document.PurchaseOrder.Items as PurchaseOrders
	|	on PurchaseOrders.Ref = Items.DocumentOrder
	|	and PurchaseOrders.RowKey = Items.DocumentOrderRowKey
	|	and PurchaseOrders.Item = Items.Item
	|	and PurchaseOrders.Feature = Items.Feature
	|	//
	|	// ProductionOrders
	|	//
	|	left join Document.ProductionOrder.Items as ProductionOrders
	|	on ProductionOrders.Ref = Items.DocumentOrder
	|	and ProductionOrders.RowKey = Items.DocumentOrderRowKey
	|	and ProductionOrders.Item = Items.Item
	|	and ProductionOrders.Feature = Items.Feature
	|where Items.DocumentOrder <> undefined
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlItemReserves ( Env )
	
	s = "
	|// ^Reserves
	|select Items.Item as Item, Items.Package as Package, Items.Feature as Feature, Items.Series as Series,
	|	Items.Stock as Stock, Items.RowKey as RowKey, Items.Quantity as Quantity, Items.QuantityPkg as QuantityPkg
	|from Items as Items
	|where Items.Reservation = value ( Enum.Reservation.Warehouse )
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure makeInternalOrders ( Env )

	table = SQL.Fetch ( Env, "$Order" );
	recordset = Env.Registers.InternalOrders;
	for each row in table do
		movement = recordset.AddReceipt ();
		movement.Period = Env.Fields.Date;
		movement.InternalOrder = Env.Ref;
		movement.RowKey = row.RowKey;
		movement.Quantity = row.Quantity;
	enddo; 
	
EndProcedure

Procedure makeAllocations ( Env )
	
	table = SQL.Fetch ( Env, "$Allocation" );
	recordset = Env.Registers.Allocation;
	for each row in table do
		movement = recordset.AddReceipt ();
		movement.Period = Env.Fields.Date;
		movement.DocumentOrder = Env.Ref;
		movement.RowKey = row.RowKey;
		movement.Quantity = row.Quantity;
	enddo; 
	
EndProcedure

Function makeProvision ( Env )
	
	error = false;
	table = SQL.Fetch ( Env, "$Provision" );
	Env.Insert ( "ProvisionExists", table.Count () > 0 );
	recordset = Env.Registers.Provision;
	for each row in table do
		if ( row.InvalidRow ) then
			error = true;
			Output.DocumentOrderItemsNotValid ( new Structure ( "DocumentOrder", row.DocumentOrder ), Output.Row ( "Items", row.LineNumber, "Item" ), Env.Ref );
			continue;
		endif; 
		movement = recordset.AddExpense ();
		movement.DocumentOrder = row.DocumentOrder;
		movement.Period = Env.Fields.Date;
		movement.RowKey = row.DocumentOrderRowKey;
		movement.Quantity = row.Quantity;
	enddo; 
	return not error;
	
EndFunction

Procedure makeReserves ( Env )
	
	table = SQL.Fetch ( Env, "$Reserves" );
	Env.Insert ( "ReserversExist", table.Count () > 0 );
	for each row in table do
		minusItems ( Env, row );
		plusReserves ( Env, row );
	enddo; 
	
EndProcedure

Procedure minusItems ( Env, Row )
	
	movement = Env.Registers.Items.AddExpense ();
	movement.Period = Env.Fields.Date;
	movement.Warehouse = Row.Stock;
	movement.Item = Row.Item;
	movement.Feature = Row.Feature;
	movement.Series = Row.Series;
	movement.Package = Row.Package;
	movement.Quantity = Row.QuantityPkg;
	
EndProcedure

Procedure plusReserves ( Env, Row )
	
	movement = Env.Registers.Reserves.AddReceipt ();
	movement.Period = Env.Fields.Date;
	movement.DocumentOrder = Env.Ref;
	movement.Warehouse = Row.Stock;
	movement.RowKey = Row.RowKey;
	movement.Quantity = Row.Quantity;
	
EndProcedure

Function checkBalances ( Env )
	
	if ( Env.ReserversExist ) then
		Env.Registers.Items.LockForUpdate = true;
		Env.Registers.Items.Write ();
		Shortage.SqlItems ( Env );
	else
		Env.Registers.Items.Write = true;
	endif;
	if ( Env.ProvisionExists ) then
		Env.Registers.Provision.LockForUpdate = true;
		Env.Registers.Provision.Write ();
		Shortage.SqlProvision ( Env );
	else
		Env.Registers.Provision.Write = true;
	endif;
	if ( Env.Selection.Count () = 0 ) then
		return true;
	endif;
	SQL.Prepare ( Env );
	SQL.Unload ( Env );
	if ( Env.ReserversExist ) then
		table = SQL.Fetch ( Env, "$ShortageItems" );
		if ( table.Count () > 0 ) then
			Shortage.Items ( Env, table );
			return false;
		endif; 
	endif; 
	if ( Env.ProvisionExists ) then
		table = SQL.Fetch ( Env, "$ShortageProvision" );
		if ( table.Count () > 0 ) then
			Shortage.Provision ( Env, table );
			return false;
		endif; 
	endif; 
	return true;
	
EndFunction

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.InternalOrders.Write = true;
	registers.Allocation.Write = true;
	registers.Reserves.Write = true;
	
EndProcedure

#endregion

#endif