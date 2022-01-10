#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.Assembling.Synonym, Data, Presentation, StandardProcessing );
	
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
		sqlQuantity ( Env );
	endif; 
	if ( Env.RestoreCost
		or Env.CostOnline ) then
		sqlItemKeys ( Env );
		sqlItemsAndKeys ( Env );
	endif; 
	getTables ( Env );
	Env.Insert ( "CheckBalances", Shortage.Check ( Env.Fields.Company, Env.Realtime, Env.RestoreCost ) );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Warehouse as Warehouse, Documents.Company as Company,
	|	Documents.PointInTime as Timestamp, Documents.Set as Set, Documents.Feature as Feature, Documents.Series as Series,
	|	case when Documents.Set.CountPackages then Documents.Capacity else 1 end as Capacity,
	|	case when Documents.Set.CountPackages then Documents.Package.Description else Documents.Set.Unit.Code end as Unit,
	|	case when Documents.Set.CountPackages then Documents.QuantityPkg else Documents.Quantity end as QuantityPkg,
	|	case when Documents.Set.CountPackages then Documents.Package else value ( Catalog.Packages.EmptyRef ) end as Package,
	|	Documents.Account as Account, Details.ItemKey as ItemKey, Lots.Ref as Lot, Documents.Set.CostMethod as CostMethod
	|from Document.Assembling as Documents
	|	//
	|	// Lots
	|	//
	|	left join Catalog.Lots as Lots
	|	on Lots.Document = &Ref
	|	//
	|	// Details
	|	//
	|	left join InformationRegister.ItemDetails as Details
	|	on Details.Item = Documents.Set
	|	and Details.Package = case when Documents.Set.CountPackages then Documents.Package else value ( Catalog.Packages.EmptyRef ) end
	|	and Details.Feature = Documents.Feature
	|	and Details.Series = Documents.Series
	|	and Details.Warehouse = Documents.Warehouse
	|	and Details.Account = Documents.Account
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
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	Items.Quantity as Quantity,
	|	case when Items.Item.CountPackages then Items.Capacity else 1 end as Capacity,
	|	case when Items.Item.CountPackages then Items.Package.Description else Items.Item.Unit.Code end as Unit,
	|	case when Items.Item.CountPackages then Items.QuantityPkg else Items.Quantity end as QuantityPkg,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package,
	|	case when ( Items.Warehouse = value ( Catalog.Warehouses.EmptyRef ) ) then &Warehouse else Items.Warehouse end as Warehouse,
	|	Items.Account as Account, &Warehouse as SetWarehouse, &Account as SetAccount, &Set as Set
	|into Items
	|from Document.Assembling.Items as Items
	|where Items.Ref = &Ref
	|index by Items.Item, Items.Feature
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

Procedure sqlQuantity ( Env )
	
	s = "
	|// ^Items
	|select Items.Warehouse as Warehouse, Items.Item as Item, Items.Feature as Feature,
	|	Items.Package as Package, Items.Series as Series, sum ( Items.QuantityPkg ) as Quantity
	|from Items as Items
	|group by Items.Warehouse, Items.Item, Items.Feature, Items.Package, Items.Series
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlItemKeys ( Env )
	
	s = "
	|select Items.Item as Item, Items.Feature as Feature, Items.Series as Series, Items.Account as Account,
	|	Details.ItemKey as ItemKey
	|into ItemKeys
	|from Items as Items
	|	//
	|	// Details
	|	//
	|	join InformationRegister.ItemDetails as Details
	|	on Details.Item = Items.Item
	|	and Details.Package = Items.Package
	|	and Details.Feature = Items.Feature
	|	and Details.Series = Items.Series
	|	and Details.Warehouse = Items.Warehouse
	|	and Details.Account = Items.Account
	|union
	|select Details.Item, Details.Feature, Details.Series, Details.Account, Details.ItemKey
	|from InformationRegister.ItemDetails as Details
	|where Details.Item = &Set and Details.Package = &Package and Details.Feature = &Feature
	|	and Details.Series = &Series and Details.Warehouse = &Warehouse and Details.Account = &Account
	|index by Details.ItemKey
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
	|select Items.LineNumber as LineNumber, Items.Warehouse as Warehouse, Items.Item as Item,
	|	Items.Package as Package, Items.Unit as Unit, Items.Feature as Feature, Items.Series as Series,
	|	Items.Account as Account, Items.QuantityPkg as Quantity, Items.Capacity as Capacity, Details.ItemKey as ItemKey,
	|	Items.SetWarehouse as SetWarehouse, Items.Set as Set, Items.SetAccount as SetAccount
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
	q.SetParameter ( "Warehouse", fields.Warehouse );
	q.SetParameter ( "Set", fields.Set );
	q.SetParameter ( "Package", fields.Package );
	q.SetParameter ( "Feature", fields.Feature );
	q.SetParameter ( "Series", fields.Series );
	q.SetParameter ( "Account", fields.Account );
	SQL.Perform ( Env );
	
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
	p.Insert ( "AddInTable1FromTable2", "Capacity, Warehouse, Set, SetWarehouse, SetAccount" );
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
			row.ItemKey = ItemDetails.GetKey ( Env, row.Item, row.Package, row.Feature, row.Series, row.Warehouse, row.Account );
		endif; 
		costRow = Cost.Add ();
		FillPropertyValues ( costRow, row );
		msg.Item = row.Item;
		msg.Warehouse = row.Warehouse;
		msg.QuantityBalance = Conversion.NumberToQuantity ( row.QuantityBalance, row.Package );
		msg.Quantity = Conversion.NumberToQuantity ( row.Quantity - row.QuantityBalance, row.Package );
		Output.ItemsCostBalanceError ( msg, Output.Row ( "Items", row.LineNumber, column ), Env.Ref );
	enddo;
		
EndProcedure

Procedure makeCost ( Env, Table )
	
	recordset = Env.Registers.Cost;
	fields = Env.Fields;
	date = fields.Date;
	for each row in Table do
		movement = recordset.AddExpense ();
		movement.Period = date;
		movement.ItemKey = row.ItemKey;
		movement.Lot = row.Lot;
		movement.Quantity = row.Quantity;
		movement.Amount = row.Cost;
	enddo; 
	movement = recordset.AddReceipt ();
	movement.Period = date;
	if ( fields.ItemKey = null ) then
		fields.ItemKey = ItemDetails.GetKey ( Env, fields.Set, fields.Package, fields.Feature, fields.Series, fields.Warehouse, fields.Account );
	endif; 
	movement.ItemKey = fields.ItemKey;
	lot = fields.Lot;
	if ( fields.CostMethod = Enums.Cost.FIFO ) then
		if ( lot = null ) then
			lot = newLot ( Env );
		endif; 
		movement.Lot = lot;
	endif; 
	movement.Quantity = fields.QuantityPkg;
	movement.Amount = Table.Total ( "Cost" );
	
EndProcedure

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
	date = fields.Date;
	company = fields.Company;
	setQuantity = fields.QuantityPkg * fields.Capacity;
	p = GeneralRecords.GetParams ();
	p.Date = date;
	p.Company = company;
	p.Operation = Enums.Operations.Assembling;
	p.DimCr1Type = "Items";
	p.DimCr2Type = "Warehouses";
	p.DimDr1Type = "Items";
	p.DimDr2Type = "Warehouses";
	p.Recordset = Env.Registers.General;
	Table.GroupBy ( "Warehouse, Item, Capacity, Account, Set, SetWarehouse, SetAccount", "Quantity, Cost" );
	fullQuantity = Table.Total ( "Quantity" );
	writtenQuantity = 0;
	rowNumber = 0;
	tableCount = Table.Count ();
	accuracy = Constants.Accuracy.Get ();
	for each row in Table do
		rowNumber = rowNumber + 1;
		p.Amount = row.Cost;
		p.AccountCr = row.Account;
		p.QuantityCr = row.Quantity * row.Capacity;
		p.DimCr1 = row.Item;
		p.DimCr2 = row.Warehouse;
		p.AccountDr = row.SetAccount;
		p.DimDr1 = row.Set;
		p.DimDr2 = row.SetWarehouse;
		quantityPart = Round ( setQuantity * row.Quantity / fullQuantity, accuracy );
		p.QuantityDr = quantityPart;
		writtenQuantity = writtenQuantity + quantityPart;
		if ( rowNumber = tableCount and writtenQuantity <> setQuantity ) then
			p.QuantityDr = p.QuantityDr - writtenQuantity + setQuantity;
		endif;
		GeneralRecords.Add ( p );
	enddo; 
	
EndProcedure

Procedure cleanCost ( Env )
	
	recordset = Env.Registers.General;
	recordset.Read ();
	i = recordset.Count () - 1;
	while ( i >= 0 ) do
		if ( recordset [ i ].Operation = Enums.Operations.Assembling ) then
			recordset.Delete ( i );
		endif; 
		i = i - 1;
	enddo; 
	
EndProcedure

Procedure setCostBound ( Env )
	
	if ( Env.RestoreCost ) then
		table = SQL.Fetch ( Env, "$ItemsAndKeys" );
		fields = Env.Fields;
		time = fields.Timestamp;
		company = fields.Company;
		for each row in table do
			Sequences.Cost.SetBound ( time, new Structure ( "Company, Item", company, row.Item ) );
		enddo; 
	endif; 
	
EndProcedure

Procedure attachSequence ( Env )

	recordset = Sequences.Cost.CreateRecordSet ();
	//@skip-warning
	recordset.Filter.Recorder.Set ( Env.Ref );
	table = SQL.Fetch ( Env, "$SequenceCost" );
	fields = Env.Fields;
	date = fields.Date;
	company = fields.Company;
	for each row in table do
		movement = recordset.Add ();
		movement.Period = date;
		movement.Company= company;
		movement.Item = row.Item;
	enddo;
	recordset.Write ();
	
EndProcedure

Procedure makeItems ( Env )

	table = SQL.Fetch ( Env, "$Items" );
	recordset = Env.Registers.Items;
	fields = Env.Fields;
	date = fields.Date;
	for each row in table do
		movement = recordset.AddExpense ();
		movement.Period = date;
		movement.Item = row.Item;
		movement.Feature = row.Feature;
		movement.Series = row.Series;
		movement.Warehouse = row.Warehouse;
		movement.Package = row.Package;
		movement.Quantity = row.Quantity;
	enddo;
	movement = recordset.AddReceipt ();
	movement.Period = date;
	movement.Item = fields.Set;
	movement.Feature = fields.Feature;
	movement.Series = fields.Series;
	movement.Warehouse = fields.Warehouse;
	movement.Package = fields.Package;
	movement.Quantity = fields.QuantityPkg;
	
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
	|	presentation ( case when Document.Package = value ( Catalog.Packages.EmptyRef ) then Document.Set.Unit else Document.Package end ) as Package
	|from Document.Assembling as Document
	|where Document.Ref = &Ref
	|;
	|// #Items
	|select Items.Item Item, Items.QuantityPkg as Quantity,
	|	presentation ( case when Items.Package = value ( Catalog.Packages.EmptyRef ) then Items.Item.Unit else Items.Package end ) as Package
	|from Document.Assembling.Items as Items
	|where Items.Ref = &Ref
	|order by Items.LineNumber
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