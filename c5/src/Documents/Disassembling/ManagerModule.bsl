#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.Disassembling.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	fields = Env.Fields;
	if ( not Env.RestoreCost ) then
		makeItems ( Env );
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
		SequenceCost.Rollback ( Env.Ref, fields.Company, fields.Timestamp );
	endif;
	ItemDetails.Save ( Env );
	if ( not Env.RestoreCost ) then
		attachSequence ( Env );
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
	sqlItems ( Env );
	if ( not Env.RestoreCost ) then
		sqlSequence ( Env );
		sqlWarehouse ( Env );
	endif; 
	if ( Env.RestoreCost
		or Env.CostOnline ) then
		sqlItemsAndKeys ( Env );
	endif; 
	getTables ( Env );
	Env.Insert ( "CheckBalances", Shortage.Check ( Env.Fields.Company, Env.Realtime, Env.RestoreCost ) );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Company as Company, Documents.PointInTime as Timestamp, Lots.Ref as Lot
	|from Document.Disassembling as Documents
	|	//
	|	// Lots
	|	//
	|	left join Catalog.Lots as Lots
	|	on Lots.Document = &Ref
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	Env.Insert ( "CostOnline", Options.CostOnline ( Env.Fields.Company ) );
	
EndProcedure 

Procedure sqlItems ( Env )
	
	s = "
	|select Document.Set as Item, Document.Feature as Feature, Document.Series as Series,
	|	Document.Warehouse as Warehouse, Document.Quantity as Quantity,
	|	case when Document.Set.CountPackages then Document.Package.Capacity else 1 end as Capacity,
	|	case when Document.Set.CountPackages then Document.Package.Description else Document.Set.Unit.Code end as Unit,
	|	case when Document.Set.CountPackages then Document.QuantityPkg else Document.Quantity end as QuantityPkg,
	|	case when Document.Set.CountPackages then Document.Package else value ( Catalog.Packages.EmptyRef ) end as Package,
	|	Document.Account as Account
	|into Set
	|from Document.Disassembling as Document
	|where Document.Ref = &Ref
	|;
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	Items.Quantity as Quantity, Items.CostRate CostRate,
	|	case when Items.Item.CountPackages then Items.Capacity else 1 end as Capacity,
	|	case when Items.Item.CountPackages then Items.Package.Description else Items.Item.Unit.Code end as Unit,
	|	case when Items.Item.CountPackages then Items.QuantityPkg else Items.Quantity end as QuantityPkg,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package,
	|	case when ( Items.Warehouse = value ( Catalog.Warehouses.EmptyRef ) ) then Items.Ref.Warehouse else Items.Warehouse end as Warehouse,
	|	Items.Account as Account
	|into Items
	|from Document.Disassembling.Items as Items
	|where Items.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlSequence ( Env )
	
	s = "
	|// @SequenceCost
	|select Set.Item as Item
	|from Set
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlWarehouse ( Env )
	
	s = "
	|// ^Set
	|select Set.Warehouse, Set.Item as Item, Set.Feature as Feature, Set.Package as Package, Set.QuantityPkg as Quantity
	|from Set as Set
	|;
	|// ^Items
	|select Items.Warehouse as Warehouse, Items.Item as Item, Items.Feature as Feature,
	|	Items.Package as Package, sum ( Items.QuantityPkg ) as Quantity
	|from Items as Items
	|group by Items.Warehouse, Items.Item, Items.Feature, Items.Package
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlItemsAndKeys ( Env )
	
	s = "
	|// #SetAndKey
	|select Set.Warehouse as Warehouse, Set.Item as Item, Set.Package as Package, Set.Unit as Unit,
	|	Set.Feature as Feature, Set.Series as Series, Set.Account as Account, Set.QuantityPkg as Quantity,
	|	Set.Capacity as Capacity, Details.ItemKey as ItemKey
	|from Set as Set
	|	//
	|	// Details
	|	//
	|	left join InformationRegister.ItemDetails as Details
	|	on Details.Item = Set.Item
	|	and Details.Package = Set.Package
	|	and Details.Feature = Set.Feature
	|	and Details.Series = Set.Series
	|	and Details.Warehouse = Set.Warehouse
	|	and Details.Account = Set.Account
	|;
	|// ^ItemsAndKeys
	|select Items.LineNumber as LineNumber, Items.Warehouse as Warehouse, Items.Item as Item, Items.Item.CostMethod as CostMethod,
	|	Items.Package as Package, Items.Feature as Feature, Items.Series as Series,
	|	Items.Account as Account, Items.QuantityPkg as Quantity, Items.Capacity as Capacity, Items.CostRate as CostRate,
	|	Details.ItemKey as ItemKey
	|from Items as Items
	|	//
	|	// Details
	|	//
	|	left join InformationRegister.ItemDetails as Details
	|	on Details.Item = Items.Item
	|	and Details.Package = Items.Package
	|	and Details.Feature = Items.Feature
	|	and Details.Series = Items.Series
	|	and Details.Warehouse = Items.Warehouse
	|	and Details.Account = Items.Account
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure getTables ( Env )
	
	fields = Env.Fields;
	q = Env.Q;
	q.SetParameter ( "Timestamp", ? ( Env.Realtime, undefined, fields.Timestamp ) );
	SQL.Perform ( Env );
	
EndProcedure 

Function makeValues ( Env )

	lockCost ( Env );
	cost = undefined;
	if ( not calcCost ( Env, cost ) ) then
		return false;
	endif;
	writeOffSet ( Env, cost );
	items = receiveItems ( Env, cost );
	commitCost ( Env, items );
	setCostBound ( Env );
	return true;

EndFunction

Procedure lockCost ( Env )
	
	itemKey = Env.SetAndKey [ 0 ].ItemKey;
	if ( itemKey = null ) then
		return;
	endif; 
	lock = new DataLock ();
	item = lock.Add ( "AccumulationRegister.Cost");
	item.Mode = DataLockMode.Exclusive;
	item.SetValue ( "ItemKey", itemKey );
	lock.Lock ();
	
EndProcedure

Function calcCost ( Env, Cost )
	
	table = Env.SetAndKey.Copy ();
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

Function getCost ( Env, Items )
	
	sqlCost ( Env );
	Env.Q.SetParameter ( "SetKey", Env.SetAndKey [ 0 ].ItemKey );
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
	p.Insert ( "AddInTable1FromTable2", "Capacity, Warehouse" );
	return CollectionsSrv.Decrease ( cost, Items, p );
	
EndFunction 

Procedure sqlCost ( Env )
	
	s = "
	|select Balances.Lot as Lot, Balances.QuantityBalance as Quantity,
	|	Balances.AmountBalance as Cost, &SetKey as ItemKey, Details.Item as Item,
	|	Details.Feature as Feature, Details.Series as Series, Details.Account as Account
	|from AccumulationRegister.Cost.Balance ( &Timestamp, ItemKey = &SetKey ) as Balances
	|	//
	|	// Details
	|	//
	|	left join InformationRegister.ItemDetails as Details
	|	on Details.ItemKey = &SetKey
	|where Balances.QuantityBalance > 0
	|order by Balances.Lot.Date desc
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure completeCost ( Env, Cost, Items )
	
	field = ? ( Options.Packages (), "QuantityPkg", "Quantity" );
	msg = Posting.Msg ( Env, "Warehouse, Item, QuantityBalance, Quantity" );
	for each row in Items do
		if ( row.ItemKey = null ) then
			row.ItemKey = ItemDetails.GetKey ( Env, row.Item, row.Package, row.Feature, row.Series, row.Warehouse, row.Account );
		endif; 
		costRow = Cost.Add ();
		FillPropertyValues ( costRow, row );
		msg.Item = row.Item;
		msg.Warehouse = row.Warehouse;
		msg.QuantityBalance = Conversion.NumberToQuantity ( row.QuantityBalance, row.Package );
		msg.Quantity = Conversion.NumberToQuantity ( row.Quantity - row.QuantityBalance, row.Package );
		Output.ItemsCostBalanceError ( msg, field, Env.Ref );
	enddo;
		
EndProcedure 

Procedure writeOffSet ( Env, Cost )
	
	recordset = Env.Registers.Cost;
	fields = Env.Fields;
	date = fields.Date;
	for each row in Cost do
		movement = recordset.AddExpense ();
		movement.Period = date;
		movement.ItemKey = row.ItemKey;
		movement.Lot = row.Lot;
		movement.Quantity = row.Quantity;
		movement.Amount = row.Cost;
	enddo; 
	
EndProcedure

Function receiveItems ( Env, Cost )
	
	items = SQL.Fetch ( Env, "$ItemsAndKeys" );
	items.Columns.Add ( "Cost", Metadata.DefinedTypes.Quantity.Type );
	Collections.Distribute ( Cost.Total ( "Cost" ), items, "CostRate", "Cost" );
	fields = Env.Fields;
	lot = fields.Lot;
	date = Env.Fields.Date;
	recordset = Env.Registers.Cost;
	for each row in items do
		movement = recordset.AddReceipt ();
		movement.Period = date;
		if ( row.ItemKey = null ) then
			row.ItemKey = ItemDetails.GetKey ( Env, row.Item, row.Package, row.Feature, row.Series, row.Warehouse, row.Account );
		endif;
		if ( row.CostMethod = Enums.Cost.FIFO ) then
			if ( lot = null ) then
				lot = newLot ( Env );
			endif; 
			movement.Lot = lot;
		endif; 
		movement.ItemKey = row.ItemKey;
		movement.Quantity = row.Quantity;
		movement.Amount = row.Cost;
	enddo;
	return items;
	
EndFunction

Function newLot ( Env )
	
	obj = Catalogs.Lots.CreateItem ();
	obj.Date = Env.Fields.Date;
	obj.Document = Env.Ref;
	obj.Write ();
	return obj.Ref;
	
EndFunction

Procedure commitCost ( Env, Table )
	
	if ( Env.RestoreCost ) then
		cleanCost ( Env );
	endif; 
	fields = Env.Fields;
	data = Env.SetAndKey [ 0 ];
	set = data.Item;
	warehouse = data.Warehouse;
	account = data.Account;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;;
	p.Operation = Enums.Operations.Disassembling;
	p.DimCr1Type = "Items";
	p.DimCr2Type = "Warehouses";
	p.DimDr1Type = "Items";
	p.DimDr2Type = "Warehouses";
	p.Recordset = Env.Registers.General;
	Table.GroupBy ( "Warehouse, Item, Capacity, Account", "Quantity, Cost" );
	Table.Columns.Add ( "ProductQuantity", new TypeDescription ( "Number", , , new NumberQualifiers ( Metadata.DefinedTypes.Quantity.Type.NumberQualifiers.Digits, Constants.Accuracy.Get () ) ) );
	Collections.Distribute ( data.Quantity * data.Capacity, Table, "Quantity", "ProductQuantity" );
	for each row in Table do
		p.Amount = row.Cost;
		p.AccountDr = row.Account;
		p.QuantityDr = row.Quantity * row.Capacity;
		p.DimDr1 = row.Item;
		p.DimDr2 = row.Warehouse;
		p.AccountCr = account;
		p.DimCr1 = set;
		p.DimCr2 = warehouse;
		p.QuantityCr = row.ProductQuantity;
		GeneralRecords.Add ( p );
	enddo; 
	
EndProcedure

Procedure cleanCost ( Env )
	
	recordset = Env.Registers.General;
	recordset.Read ();
	i = recordset.Count () - 1;
	while ( i >= 0 ) do
		if ( recordset [ i ].Operation = Enums.Operations.Disassembling ) then
			recordset.Delete ( i );
		endif; 
		i = i - 1;
	enddo; 
	
EndProcedure

Procedure setCostBound ( Env )
	
	if ( Env.RestoreCost ) then
		fields = Env.Fields;
		p = new Structure ( "Company, Item", fields.Company, Env.SetAndKey [ 0 ].Item );
		Sequences.Cost.SetBound ( fields.Timestamp, p );
	endif; 
	
EndProcedure

Procedure attachSequence ( Env )

	recordset = Sequences.Cost.CreateRecordSet ();
	//@skip-warning
	recordset.Filter.Recorder.Set ( Env.Ref );
	fields = Env.Fields;
	movement = recordset.Add ();
	movement.Period = fields.Date;
	movement.Company = fields.Company;
	movement.Item = Env.SequenceCost.Item;
	recordset.Write ();
	
EndProcedure

Procedure makeItems ( Env )

	recordset = Env.Registers.Items;
	date = Env.Fields.Date;
	for each row in SQL.Fetch ( Env, "$Set" ) do
		movement = recordset.AddExpense ();
		movement.Period = date;
		movement.Item = row.Item;
		movement.Feature = row.Feature;
		movement.Warehouse = row.Warehouse;
		movement.Package = row.Package;
		movement.Quantity = row.Quantity;
	enddo;
	for each row in SQL.Fetch ( Env, "$Items" ) do
		movement = recordset.AddReceipt ();
		movement.Period = date;
		movement.Item = row.Item;
		movement.Feature = row.Feature;
		movement.Warehouse = row.Warehouse;
		movement.Package = row.Package;
		movement.Quantity = row.Quantity;
	enddo;
	
EndProcedure

Function checkBalances ( Env )
	
	if ( Env.CheckBalances ) then
		Env.Registers.Items.LockForUpdate = true;
		Env.Registers.Items.Write ();
		Shortage.SqlItems ( Env );
	else
		Env.Registers.Items.Write = true;
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
	return true;
	
EndFunction

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.Cost.Write = true;
	registers.General.Write = true;
	if ( not Env.RestoreCost ) then
		if ( not Env.CheckBalances ) then
			registers.Items.Write = true;
		endif; 
	endif;
	
EndProcedure

#endregion

#region Printing

Function Print ( Params, Env ) export
	
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params );
	getPrintData ( Params, Env );
	putHeader ( Params, Env );
	putTable ( Params, Env );
	putFooter ( Params, Env );
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
	|select Document.Number as Number, Document.Date as Date, Document.Creator as Creator,
	|	Document.Set as Set, Document.QuantityPkg as Quantity, 
	|	isnull ( Document.Package.Description, Document.Set.Unit.Code ) as Unit
	|from Document.Disassembling as Document
	|where Document.Ref = &Ref
	|;
	|// #Items
	|select Items.Item Item, sum ( Items.QuantityPkg ) as Quantity,
	|	isnull ( Items.Package.Description, Items.Item.Unit.Code ) as Unit
	|from Document.Disassembling.Items as Items
	|where Items.Ref = &Ref
	|group by Items.Item, Items.Package
	|order by min ( Items.LineNumber )
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure putHeader ( Params, Env )
	
	area = Env.T.GetArea ( "Header" );
	fields = Env.Fields;
	accuracy = Application.Accuracy ();
	p = area.Parameters;
	p.Fill ( fields );
	p.Quantity = Format ( fields.Quantity, accuracy );
	p.Date = Format ( fields.Date, "DLF=D" );
	Params.TabDoc.Put ( area );
	
EndProcedure
 
Procedure putTable ( Params, Env )
	
	t = Env.T;
	header = t.GetArea ( "Table" );
	area = t.GetArea ( "Row" );
	tabDoc = Params.TabDoc;
	tabDoc.Put ( header );
	Print.Repeat ( tabDoc );
	table = Env.Items;
	accuracy = Application.Accuracy ();
	p = area.Parameters;
	lineNumber = 0;
	for each row in table do
		p.Fill ( row );
		lineNumber = lineNumber + 1;
		p.LineNumber = lineNumber;
		p.Quantity = Format ( row.Quantity, accuracy );
		tabDoc.Put ( area );
	enddo;
	
EndProcedure

Procedure putFooter ( Params, Env )
	
	area = Env.T.GetArea ( "Footer" );
	p = area.Parameters;
	p.Fill ( Env.Fields );
	Params.TabDoc.Put ( area );        
	
EndProcedure

#endregion

#endif