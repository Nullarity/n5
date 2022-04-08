#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.Transfer.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	if ( not Env.RestoreCost ) then
		if ( Env.Fields.Forms
			and not RunRanges.Check ( Env ) ) then
			return false;
		endif;
		if ( not checkRows ( Env ) ) then
			return false;
		endif;
		makeItems ( Env );
		if ( Env.DocumentOrderExists
			and not makeReserves ( Env ) ) then
			return false;
		endif;
	endif;
	ItemDetails.Init ( Env );
	if ( Env.RestoreCost
		or Env.CostOnline ) then
		if ( not makeValues ( Env ) ) then
			return false;
		endif;
	endif;
	if ( not Env.RestoreCost
		and not Env.Realtime ) then
		SequenceCost.Rollback ( Env.Ref, Env.Fields.Company, Env.Fields.Timestamp );
	endif;
	ItemDetails.Save ( Env );
	if ( not Env.RestoreCost ) then
		attachSequence ( Env );
		if ( Env.Fields.Forms ) then
			if ( not makeRanges ( Env ) ) then
				return false;
			endif;
		endif;
		if ( not checkBalances ( Env ) ) then
			return false;
		endif; 
	endif;
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )

	sqlFields ( Env );
	getFields ( Env );
	setContext ( Env );
	sqlItems ( Env );
	fields = Env.Fields;
	if ( fields.Forms ) then
		RunRanges.SqlData ( Env );
	endif;
	if ( not Env.RestoreCost ) then
		if ( Options.Series () ) then
			sqlEmptySeries ( Env );
		endif;
		sqlSequence ( Env );
		if ( Env.DocumentOrderExists ) then
			sqlReserves ( Env );
		endif;
		sqlQuantity ( Env );
	endif; 
	if ( Env.RestoreCost
		or Env.CostOnline ) then
		sqlItemKeys ( Env );
		sqlItemsAndKeys ( Env );
	endif; 
	getTables ( Env );
	Env.Insert ( "CheckBalances", Shortage.Check ( fields.Company, Env.Realtime, Env.RestoreCost ) );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Sender as Sender, Documents.Receiver as Receiver,
	|	Documents.Company as Company, Documents.PointInTime as Timestamp,
	|	isnull ( Forms.Exists, false ) as Forms
	|from Document.Transfer as Documents
	|	//
	|	// Forms
	|	//
	|	left join (
	|		select top 1 true as Exists
	|		from Document.Transfer.Items as Items
	|		where Items.Item.Form
	|		and Items.Ref = &Ref ) as Forms
	|	on true
	|where Documents.Ref = &Ref
	|;
	|// @DocumentOrderExists
	|select top 1 true as Exist
	|from Document.Transfer.Items as Items
	|where Items.DocumentOrder <> undefined
	|and Items.Ref = &Ref
	|union
	|select top 1 true
	|from Document.Transfer as Documents
	|where Documents.DocumentOrder <> undefined
	|and Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	Env.Insert ( "CostOnline", Options.CostOnline ( Env.Fields.Company ) );
	
EndProcedure 

Procedure setContext ( Env )
	
	Env.Insert ( "DocumentOrderExists", Env.DocumentOrderExists <> undefined and Env.DocumentOrderExists.Exist );

EndProcedure

Procedure sqlItems ( Env )
	
	s = "
	|select ""Items"" as Table, Items.LineNumber as LineNumber, Items.Item as Item, Items.Feature as Feature,
	|	Items.Series as Series, Items.Quantity as Quantity, Items.Account as Account,
	|	Items.AccountReceiver as AccountReceiver, Items.RowKey as RowKey, Items.Range as Range,
	|	case when Items.Item.CountPackages then Items.Capacity else 1 end as Capacity,
	|	case when Items.Item.CountPackages then Items.Package.Description else Items.Item.Unit.Code end as Unit,
	|	case when Items.Item.CountPackages then Items.QuantityPkg else Items.Quantity end as QuantityPkg,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package,
	|	case when ( Items.Sender = value ( Catalog.Warehouses.EmptyRef ) ) then &Sender else Items.Sender end as Sender,
	|	case when ( Items.Receiver = value ( Catalog.Warehouses.EmptyRef ) ) then &Receiver else Items.Receiver end as Receiver,
	|	case when Items.DocumentOrder = undefined then Items.Ref.DocumentOrder else Items.DocumentOrder end as DocumentOrder
	|into Items
	|from Document.Transfer.Items as Items
	|where Items.Ref = &Ref
	|index by Items.Item, Items.Feature
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlEmptySeries ( Env )
	
	s = "
	|// #EmptySeries
	|select Items.LineNumber as LineNumber
	|from Items as Items
	|where Items.Item.Series
	|and Items.Series = value ( Catalog.Series.EmptyRef )
	|";
	Env.Selection.Add ( s );

EndProcedure

Procedure sqlSequence ( Env )
	
	s = "
	|// ^SequenceCost
	|select distinct Items.Item as Item
	|from Items
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlReserves ( Env )
	
	s = "
	|select Items.RowKey as RowKey, Items.Sender as Sender, Items.Receiver as Receiver, Items.Item as Item,
	|	Items.Feature as Feature, Items.LineNumber as LineNumber, Items.Quantity as Quantity,
	|	Items.DocumentOrder as DocumentOrder, case when SalesOrders.Item is null then true else false end as Invalid
	|into Reserves
	|from Items as Items
	|	//
	|	// SalesOrders
	|	//
	|	left join Document.SalesOrder.Items as SalesOrders
	|	on SalesOrders.Ref = Items.DocumentOrder
	|	and SalesOrders.RowKey = Items.RowKey
	|	and SalesOrders.Item = Items.Item
	|	and SalesOrders.Feature = Items.Feature
	|	and SalesOrders.Reservation <> value ( Enum.Reservation.None )
	|where Items.DocumentOrder refs Document.SalesOrder
	|union all
	|select Items.RowKey, Items.Sender, Items.Receiver, Items.Item, Items.Feature, Items.LineNumber,
	|	Items.Quantity, Items.DocumentOrder, case when InternalOrders.Item is null then true else false end
	|from Items as Items
	|	//
	|	// InternalOrders
	|	//
	|	left join Document.InternalOrder.Items as InternalOrders
	|	on InternalOrders.Ref = Items.DocumentOrder
	|	and InternalOrders.RowKey = Items.RowKey
	|	and InternalOrders.Feature = Items.Feature
	|	and InternalOrders.Reservation <> value ( Enum.Reservation.None )
	|where Items.DocumentOrder refs Document.InternalOrder
	|index by Items.RowKey
	|;
	|// ^Reserves
	|select Reserves.Sender as Sender, Reserves.Receiver as Receiver, Reserves.RowKey as RowKey,
	|	Reserves.Quantity as Quantity, Reserves.DocumentOrder as DocumentOrder,
	|	Reserves.LineNumber as LineNumber, Reserves.Invalid as Invalid
	|from Reserves as Reserves
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlQuantity ( Env )
	
	s = "
	|// ^Items
	|select Items.Sender as Sender, Items.Receiver as Receiver, Items.Item as Item, Items.Feature as Feature,
	|	Items.Series as Series, Items.Package as Package, sum ( Items.QuantityPkg ) as Quantity
	|from Items as Items
	|";
	if ( Env.DocumentOrderExists ) then
		s = s + "
		|where Items.RowKey not in ( select RowKey from Reserves )";
	endif;
	s = s + "
	|group by Items.Sender, Items.Receiver, Items.Item, Items.Feature, Items.Package, Items.Series
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlItemKeys ( Env )
	
	s = "
	|select distinct Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	Items.Capacity as Capacity, Items.Account as Account, CostDetails.ItemKey as ItemKey
	|into ItemKeys
	|from Items as Items
	|	//
	|	// CostDetails
	|	//
	|	join InformationRegister.ItemDetails as CostDetails
	|	on CostDetails.Item = Items.Item
	|	and CostDetails.Package = Items.Package
	|	and CostDetails.Feature = Items.Feature
	|	and CostDetails.Series = Items.Series
	|	and CostDetails.Warehouse = Items.Sender
	|	and CostDetails.Account = Items.Account
	|index by CostDetails.ItemKey
	|;
	|// ^ItemKeys
	|select ItemKeys.ItemKey as ItemKey
	|from ItemKeys as ItemKeys
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlItemsAndKeys ( Env )
	
	s = "
	|// ^ItemsAndKeys
	|select Items.LineNumber as LineNumber, Items.Sender as Sender, Items.Receiver as Receiver, Items.Item as Item,
	|	Items.Package as Package, Items.Item.Unit as Unit, Items.Feature as Feature, Items.Series as Series,
	|	Items.Account as Account, Items.AccountReceiver as AccountReceiver, Items.QuantityPkg as Quantity,
	|	SenderDetails.ItemKey as ItemKey, ReceiverDetails.ItemKey as ItemKeyReceiver,
	|	Items.DocumentOrder as DocumentOrder, Items.Capacity as Capacity
	|from Items as Items
	|	//
	|	// SenderDetails
	|	//
	|	left join InformationRegister.ItemDetails as SenderDetails
	|	on SenderDetails.Item = Items.Item
	|	and SenderDetails.Package = Items.Package
	|	and SenderDetails.Feature = Items.Feature
	|	and SenderDetails.Series = Items.Series
	|	and SenderDetails.Warehouse = Items.Sender
	|	and SenderDetails.Account = Items.Account
	|	//
	|	// ReceiverDetails
	|	//
	|	left join InformationRegister.ItemDetails as ReceiverDetails
	|	on ReceiverDetails.Item = Items.Item
	|	and ReceiverDetails.Package = Items.Package
	|	and ReceiverDetails.Feature = Items.Feature
	|	and ReceiverDetails.Series = Items.Series
	|	and ReceiverDetails.Warehouse = Items.Receiver
	|	and ReceiverDetails.Account = Items.AccountReceiver
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables ( Env )
	
	fields = Env.Fields;
	Env.Q.SetParameter ( "Timestamp", ? ( Env.Realtime, undefined, fields.Timestamp ) );
	Env.Q.SetParameter ( "Sender", fields.Sender );
	Env.Q.SetParameter ( "Receiver", fields.Receiver );
	SQL.Perform ( Env );
	
EndProcedure 

Function checkRows ( Env )
	
	ok = true;
	if ( Options.Series () ) then
		for each row in Env.EmptySeries do
			Output.UndefinedSeries ( , Output.Row ( "Items", row.LineNumber, "Series" ), Env.Ref );
			ok = false;
		enddo; 
	endif;
	return ok;
	
EndFunction

Procedure makeItems ( Env )

	table = SQL.Fetch ( Env, "$Items" );
	recordset = Env.Registers.Items;
	for each row in table do
		movement = recordset.AddExpense ();
		movement.Period = Env.Fields.Date;
		movement.Item = row.Item;
		movement.Feature = row.Feature;
		movement.Series = row.Series;
		movement.Warehouse = row.Sender;
		movement.Package = row.Package;
		movement.Quantity = row.Quantity;
		movement2 = recordset.AddReceipt ();
		movement2.Warehouse = row.Receiver;
		FillPropertyValues ( movement2, movement, , "RecordType, Warehouse" );
	enddo; 
	
EndProcedure

Function makeValues ( Env )

	lockCost ( Env );
	cost = undefined;
	if ( not calcCost ( Env, cost ) ) then
		return false;
	endif;
	makeCost ( Env, cost );
	commitCost ( Env, cost );
	setCostBound ( Env );
	return true;

EndFunction

Procedure lockCost ( Env )
	
	table = SQL.Fetch ( Env, "$ItemKeys" );
	if ( table.Count () > 0 ) then
		lock = new DataLock ();
		item = lock.Add ( "AccumulationRegister.Cost");
		item.Mode = DataLockMode.Exclusive;
		item.DataSource = table;
		item.UseFromDataSource ( "ItemKey", "ItemKey" );
		lock.Lock ();
	endif;
	
EndProcedure

Function calcCost ( Env, Cost )
	
	table = SQL.Fetch ( Env, "$ItemsAndKeys" );
	setReceiverKeys ( Env, table );
	Cost = getCost ( Env, table );
	error = ( table.Count () > 0 );
	if ( error ) then
		completeCost ( Env, Cost, table );
		if ( Env.RestoreCost
			or Env.CheckBalances ) then
			return false;
		endif; 
	endif; 
	return true;
	
EndFunction

Procedure setReceiverKeys ( Env, Table )
	
	rows = Table.FindRows ( new Structure ( "ItemKeyReceiver", null ) );
	for each row in rows do
		row.ItemKeyReceiver = ItemDetails.GetKey ( Env, row.Item, row.Package, row.Feature, row.Series, row.Receiver, row.AccountReceiver );
	enddo;
	
EndProcedure 

Function getCost ( Env, Items )
	
	sqlCost ( Env );
	SQL.Prepare ( Env );
	cost = Env.Q.Execute ().Unload ();
	p = new Structure ();
	p.Insert ( "FilterColumns", "ItemKey" );
	if ( Options.Features () ) then
		p.FilterColumns = p.FilterColumns + ", Feature";
	endif; 
	if ( Options.Series () ) then
		p.FilterColumns = p.FilterColumns + ", Series";
	endif; 
	p.Insert ( "KeyColumn", "Quantity" );
	p.Insert ( "KeyColumnAvailable", "QuantityBalance" );
	p.Insert ( "DecreasingColumns", "Cost" );
	p.Insert ( "AddInTable1FromTable2", "Capacity, Sender, Receiver, DocumentOrder, AccountReceiver, ItemKeyReceiver" );
	return CollectionsSrv.Decrease ( cost, Items, p );
	
EndFunction 

Procedure sqlCost ( Env )
	
	s = "
	|select Balances.Lot as Lot, Balances.QuantityBalance as Quantity,
	|	Balances.AmountBalance as Cost, ItemKeys.ItemKey as ItemKey, ItemKeys.Item as Item,
	|	ItemKeys.Feature as Feature, ItemKeys.Series as Series, ItemKeys.Account as Account
	|from AccumulationRegister.Cost.Balance ( &Timestamp, ItemKey in ( select ItemKey from ItemKeys ) ) as Balances
	|	//
	|	// ItemKeys
	|	//
	|	left join ItemKeys as ItemKeys
	|	on ItemKeys.ItemKey = Balances.ItemKey
	|	and Balances.QuantityBalance > 0
	|order by Balances.Lot.Date desc
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure completeCost ( Env, Cost, Items )
	
	column = ? ( Options.Packages (), "QuantityPkg", "Quantity" );
	msg = Posting.Msg ( Env, "Warehouse, Item, QuantityBalance, Quantity" );
	for each row in Items do
		if ( row.ItemKey = null ) then
			row.ItemKey = ItemDetails.GetKey ( Env, row.Item, row.Package, row.Feature, row.Series, row.Sender, row.Account );
		endif; 
		costRow = Cost.Add ();
		FillPropertyValues ( costRow, row );
		balance = row.QuantityBalance;
		outstanding = row.Quantity - balance;
		costRow.Quantity = outstanding;
		msg.Item = row.Item;
		msg.Warehouse = row.Sender;
		msg.QuantityBalance = Conversion.NumberToQuantity ( balance, row.Unit );
		msg.Quantity = Conversion.NumberToQuantity ( outstanding, row.Unit );
		Output.ItemsCostBalanceError ( msg, Output.Row ( "Items", row.LineNumber, column ), Env.Ref );
	enddo; 
		
EndProcedure 

Procedure makeCost ( Env, Table )
	
	recordset = Env.Registers.Cost;
	for each row in Table do
		movement = recordset.AddExpense ();
		movement.Period = Env.Fields.Date;
		movement.ItemKey = row.ItemKey;
		movement.Lot = row.Lot;
		movement.Quantity = row.Quantity;
		movement.Amount = row.Cost;
		movement2 = recordset.AddReceipt ();
		movement2.ItemKey = row.ItemKeyReceiver;
		FillPropertyValues ( movement2, movement, , "RecordType, ItemKey" );
	enddo; 
	
EndProcedure

Procedure commitCost ( Env, Table )
	
	if ( Env.RestoreCost ) then
		cleanCost ( Env );
	endif; 
	items = Table.Copy ( , "Sender, Receiver, Item, Account, AccountReceiver, Capacity, Quantity, Cost" );
	items.GroupBy ( "Sender, Receiver, Item, Account, AccountReceiver, Capacity", "Quantity, Cost" );
	p = GeneralRecords.GetParams ();
	p.Date = Env.Fields.Date;
	p.Company = Env.Fields.Company;
	p.Operation = Enums.Operations.ItemsRetirement;
	p.DimDr1Type = "Items";
	p.DimDr2Type = "Warehouses";
	p.DimCr1Type = "Items";
	p.DimCr2Type = "Warehouses";
	p.Recordset = Env.Registers.General;
	for each row in items do
		quantity = row.Quantity * row.Capacity;
		item = row.Item;
		p.AccountDr = row.AccountReceiver;
		p.AccountCr = row.Account;
		p.Amount = row.Cost;
		p.QuantityDr = quantity;
		p.QuantityCr = quantity;
		p.DimDr1 = item;
		p.DimDr2 = row.Receiver;
		p.DimCr1 = item;
		p.DimCr2 = row.Sender;
		GeneralRecords.Add ( p );
	enddo; 
	
EndProcedure

Procedure cleanCost ( Env )
	
	recordset = Env.Registers.General;
	recordset.Read ();
	i = recordset.Count () - 1;
	while ( i >= 0 ) do
		if ( recordset [ i ].Operation = Enums.Operations.Transfer ) then
			recordset.Delete ( i );
		endif; 
		i = i - 1;
	enddo; 
	
EndProcedure

Procedure setCostBound ( Env )
	
	if ( Env.RestoreCost ) then
		table = SQL.Fetch ( Env, "$ItemsAndKeys" );
		for each row in table do
			Sequences.Cost.SetBound ( Env.Fields.Timestamp, new Structure ( "Company, Item", Env.Fields.Company, row.Item ) );
		enddo; 
	endif; 
	
EndProcedure

Procedure attachSequence ( Env )

	recordset = Sequences.Cost.CreateRecordSet ();
	//@skip-warning
	recordset.Filter.Recorder.Set ( Env.Ref );
	table = SQL.Fetch ( Env, "$SequenceCost" );
	for each row in table do
		movement = recordset.Add ();
		movement.Period = Env.Fields.Date;
		movement.Company= Env.Fields.Company;
		movement.Item = row.Item;
	enddo;
	recordset.Write ();
	
EndProcedure

Function checkBalances ( Env )
	
	if ( Env.CheckBalances ) then
		Env.Registers.Items.LockForUpdate = true;
		Env.Registers.Items.Write ();
		Shortage.SqlItems ( Env );
	else
		Env.Registers.Items.Write = true;
	endif; 
	if ( Env.DocumentOrderExists ) then
		if ( Env.CheckBalances ) then
			if ( Env.ReservesExist ) then
				Env.Registers.Reserves.LockForUpdate = true;
				Env.Registers.Reserves.Write ();
				Shortage.SqlReserves ( Env );
			else
				Env.Registers.Reserves.Write = true;
			endif;
		endif; 
	else
		Env.Registers.Reserves.Write = true;
	endif; 
	if ( Env.Selection.Count () = 0 ) then
		return true;
	endif;
	SQL.Perform ( Env );
	if ( not Env.CheckBalances ) then
		return true;
	endif; 
	table = SQL.Fetch ( Env, "$ShortageItems" );
	if ( table.Count () > 0 ) then
		Shortage.Items ( Env, table );
		return false;
	endif; 
	if ( Env.DocumentOrderExists ) then
		if ( Env.ReservesExist ) then
			table = SQL.Fetch ( Env, "$ShortageReserves" );
			if ( table.Count () > 0 ) then
				Shortage.Reserves ( Env, table );
				return false;
			endif; 
		endif; 
	endif; 
	return true;
	
EndFunction

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.Cost.Write = true;
	registers.General.Write = true;
	if ( not Env.RestoreCost ) then
		registers.RangeLocations.Write = true;
		if ( not Env.CheckBalances ) then
			registers.Items.Write = true;
			registers.Reserves.Write = true;
		endif; 
	endif;
	
EndProcedure

Function makeReserves ( Env )

	table = SQL.Fetch ( Env, "$Reserves" );
	Env.Insert ( "ReservesExist", table.Count () > 0 );
	recordset = Env.Registers.Reserves;
	date = Env.Fields.Date;
	error = false;
	for each row in table do
		if ( row.Invalid ) then
			error = true;
			Output.DocumentOrderItemsNotValid ( new Structure ( "DocumentOrder", row.DocumentOrder ), Output.Row ( "Items", row.LineNumber, "Item" ), Env.Ref );
			continue;
		endif; 
		movement = recordset.AddExpense ();
		movement.Period = date;
		movement.DocumentOrder = row.DocumentOrder;
		movement.RowKey = row.RowKey;
		movement.Warehouse = row.Sender;
		movement.Quantity = row.Quantity;
		movement2 = recordset.AddReceipt ();
		movement2.Warehouse = row.Receiver;
		FillPropertyValues ( movement2, movement, , "RecordType, Warehouse" );
	enddo; 
	return not error;
	
EndFunction

Function makeRanges ( Env )
	
	RunRanges.Lock ( Env );
	table = getRanges ( Env );
	recordset = Env.Registers.RangeLocations;
	date = Env.Fields.Date;
	ref = Env.Ref;
	error = false;
	field = ? ( Options.Packages (), "QuantityPkg", "Quantity" );
	for each row in table do
		if ( row.NotFound ) then
			error = true;
			p = new Structure ( "Range, Warehouse", row.Range, row.Sender );
			Output.RangeNotFound ( p, Output.Row ( "Items", row.LineNumber, "Item" ), ref );
		elsif ( row.Broken ) then
			error = true;
			p = new Structure ( "Range, Quantity, Balance, Warehouse", row.Range, row.Quantity, row.Balance, row.Sender );
			Output.RangeIsBroken ( p, Output.Row ( "Items", row.LineNumber, field ), ref );
		else
			movement = recordset.Add ();
			movement.Period = date;
			movement.Range = row.Range;
			movement.Warehouse = row.Receiver;
		endif;
	enddo;
	return not error;
	
EndFunction

Function getRanges ( Env )
	
	s = "
	|// #Ranges
	|select Items.LineNumber as LineNumber, Items.Range as Range, Items.Sender as Sender, Items.Receiver as Receiver,
	|	case when Locations.Range is null
	|			or Statuses.Range is null then true
	|		else false
	|	end as NotFound,
	|	case when Items.Quantity = ( Items.Range.Finish - isnull ( Ranges.Last, Items.Range.Start - 1 ) ) then false else true end Broken,
	|	Items.Quantity as Quantity, Items.Range.Finish - isnull ( Ranges.Last, Items.Range.Start - 1 ) as Balance
	|from (
	|	select Items.Range as Range, Items.Sender as Sender, Items.Receiver as Receiver,
	|		sum ( Items.Quantity ) as Quantity, min ( Items.LineNumber ) as LineNumber
	|	from Items as Items
	|	where Items.Range <> value ( Catalog.Ranges.EmptyRef )
	|	group by Items.Range, Items.Sender, Items.Receiver
	|) as Items
	|	//
	|	// Ranges
	|	//
	|	left join InformationRegister.Ranges as Ranges
	|	on Ranges.Range = Items.Range
	|	//
	|	// Locations
	|	//
	|	left join InformationRegister.RangeLocations.SliceLast ( &Period,
	|		Range in ( select Range from Ranges ) ) as Locations
	|	on Locations.Range = Items.Range
	|	and Locations.Warehouse = Items.Sender
	|	//
	|	// Statuses
	|	//
	|	left join InformationRegister.RangeStatuses.SliceLast ( &Period,
	|		Range in ( select Range from Ranges ) ) as Statuses
	|	on Statuses.Range = Items.Range
	|	and Statuses.Status = value ( Enum.RangeStatuses.Active )
	|";
	Env.Selection.Add ( s );
	SQL.Prepare ( Env );
	period = ? ( Env.Realtime, undefined, new Boundary ( Env.Fields.Timestamp, BoundaryType.Excluding ) );
	q = Env.Q;
	q.SetParameter ( "Period", period );
	return q.Execute ().Unload ();
	
EndFunction

#endregion

#region Printing

Function Print ( Params, Env ) export
	
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params );
	getPrintData ( Params, Env );
	putHeader ( Params, Env );
	putTable ( Params, Env );
	putFooter ( Params, Env );
	putMemo ( Params, Env );
	return true;
	
EndFunction
 
Procedure setPageSettings ( Params )
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Portrait;
	tabDoc.FitToPage = true;
	
EndProcedure 

Procedure getPrintData ( Params, Env )
	
	SetPrivilegedMode ( true );
 	sqlPrintData ( Env );
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );
	SetPrivilegedMode ( false );
	
EndProcedure

Procedure sqlPrintData ( Env )
	
	s = "
	|// @Fields
	|select Document.Number as DocumentNumber, Document.Date as DocumentDate, Document.Sender.Description as Sender,
	|	Document.Sender.Address.Presentation as SenderAddress, Document.Receiver.Description as Receiver,
	|	Document.Receiver.Address.Presentation as ReceiverAddress, Document.Currency.Description as Currency,
	|	Document.Tax as Tax, Document.Amount - Document.Tax as Subtotal, Document.ShowPrices as ShowPrices,
	|	Document.Taxable as Taxable, Document.Amount as Amount, Document.Company.FullDescription as Company
	|from Document.Transfer as Document
	|where Document.Ref = &Ref
	|;
	|// #Items
	|select Items.Item.Description as Item, Items.Item.Code as Code, Items.Feature.Description as Feature, Items.QuantityPkg as Quantity,
	|	presentation ( case when Items.Package = value ( Catalog.Packages.EmptyRef ) then Items.Item.Unit else Items.Package end ) as Package,
	|	Items.Price as Price, Items.Amount as Amount
	|from Document.Transfer.Items as Items
	|where Items.Ref = &Ref
	|order by Items.LineNumber
	|;
	|// #Taxes
	|select Taxes.Tax.Print as Tax, Taxes.Percent as Percent, Taxes.Amount as Amount
	|from Document.Transfer.Taxes as Taxes
	|where Taxes.Ref = &Ref
	|order by Taxes.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure putHeader ( Params, Env )
	
	fields = Env.Fields;
	area = Env.T.GetArea ( "Header" );
	p = area.Parameters;
	p.Fill ( fields );
	p.DocumentNumber = Print.ShortNumber ( fields.DocumentNumber );
	p.Sender = fields.Sender + ? ( ValueIsFilled ( fields.SenderAddress ), ", " + fields.SenderAddress, "" );
	p.Receiver = fields.Receiver + ? ( ValueIsFilled ( fields.ReceiverAddress ), ", " + fields.ReceiverAddress, "" );
	Params.TabDoc.Put ( area );
	
EndProcedure
 
Procedure putTable ( Params, Env )
	
	t = Env.T;
	fields = Env.Fields;
	showPrices = fields.ShowPrices;
	if ( showPrices ) then
		header = t.GetArea ( "Table" );
		area = t.GetArea ( "Row" );
	else
		header = t.GetArea ( "TableNoPrices" );
		area = t.GetArea ( "RowNoPrices" );
	endif; 
	header.Parameters.Fill ( fields );
	tabDoc = Params.TabDoc;
	tabDoc.Put ( header );
	Print.Repeat ( tabDoc );
	table = Env.Items;
	accuracy = Application.Accuracy ();
	p = area.Parameters;
	lineNumber = 0;
	for each row in table do
		lineNumber = lineNumber + 1;
		p.LineNumber = lineNumber;
		p.Code = row.Code;
		p.Item = Print.FormatItem ( row.Item, row.Package, row.Feature );
		p.Package = row.Package;
		p.Quantity = Format ( row.Quantity, accuracy );
		if ( showPrices ) then
			p.Price = row.Price;
			p.Amount = row.Amount;
		endif; 
		tabDoc.Put ( area );
	enddo;
	
EndProcedure

Procedure putFooter ( Params, Env )
	
	t = Env.T;
	fields = Env.Fields;
	tabDoc = Params.TabDoc;
	area = t.GetArea ( "Footer" );
	tabDoc.Put ( area );
	area = t.GetArea ( "Quantity" );
	accuracy = Application.Accuracy ();
	area.Parameters.Quantity = Format ( Env.Items.Total ( "Quantity" ), accuracy );
	tabDoc.Put ( area );
	if ( not fields.ShowPrices ) then
		return;
	endif; 
	if ( fields.Taxable ) then
		area = t.GetArea ( "Subtotal" );
		area.Parameters.SubTotal = fields.SubTotal;
		tabDoc.Put ( area );
		area = t.GetArea ( "Tax" );
		p = area.Parameters;
		for each row in Env.Taxes do
			p.Tax = row.Tax;
			p.Rate = Format ( row.Percent, "NZ=" );
			p.Amount = row.Amount;
			tabDoc.Put ( area );
		enddo; 
	endif; 
	area = t.GetArea ( "Total" );
	p = area.Parameters;
	p.Amount = fields.Amount;
	p.Currency = fields.Currency;
	tabDoc.Put ( area );
	
EndProcedure

Procedure putMemo ( Params, Env )
	
	area = Env.T.GetArea ( "Memo" );
	area.Parameters.Fill ( Env.Fields );
	Params.TabDoc.Put ( area );
	
EndProcedure

#endregion

#endif