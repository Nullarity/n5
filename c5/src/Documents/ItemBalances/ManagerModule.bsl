#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.ItemBalances.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	fields = Env.Fields;
	if ( fields.Forms
		and not RunRanges.Check ( Env ) ) then
		return false;
	endif;
	makeValues ( Env );
	makeItems ( Env );
	SequenceCost.Rollback ( Env.Ref, Env.Fields.Company, Env.Fields.Timestamp );
	if ( fields.Forms
		and not RunRanges.MakeReceipt ( Env ) ) then
		return false;
	endif;
	flagRegisters ( Env );
	return true;
	
EndFunction
 
Procedure getData ( Env )
	
	sqlFields ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	fields = Env.Fields;
	fields.Insert ( "Timestamp", new PointInTime ( fields.Date, Env.Ref ) );
	sqlItems ( Env );
	sqlCost ( Env );
	sqlWarehouse ( Env );
	if ( fields.Forms ) then
		RunRanges.SqlData ( Env );
	endif;
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select top 1 dateadd ( Documents.Date, second, - 1 ) as Date, Documents.Warehouse as Warehouse,
	|	Documents.Company as Company, Documents.Account as Account,
	|	Lots.Ref as Lot, isnull ( Forms.Exists, false ) as Forms
	|from Document.ItemBalances as Documents
	|	//
	|	// Lots
	|	//
	|	left join Catalog.Lots as Lots
	|	on Lots.Document = &Ref
	|	//
	|	// Forms
	|	//
	|	left join (
	|		select top 1 true as Exists
	|		from Document.ItemBalances.Items as Items
	|		where Items.Item.Form
	|		and Items.Ref = &Ref ) as Forms
	|	on true
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlItems ( Env )
	
	s = "
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	Items.Quantity as Quantity, Items.Amount as Amount, Items.Ref.Account as Account,
	|	case when Items.Item.CountPackages then Items.QuantityPkg else Items.Quantity end as QuantityPkg,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package,
	|	case Items.Warehouse when value ( Catalog.Warehouses.EmptyRef ) then Items.Ref.Warehouse else Items.Warehouse end as Warehouse,
	|	Items.Range as Range
	|into Items
	|from Document.ItemBalances.Items as Items
	|where Items.Ref = &Ref
	|index by Items.Item, Items.Feature, Items.Series
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlCost ( Env )
	
	s = "
	|// #Cost
	|select Items.Item as Item, Items.Item.CostMethod as CostMethod, Items.Package as Package,
	|	Items.Feature as Feature, Items.Series as Series, Items.Warehouse as Warehouse,
	|	Details.ItemKey as Itemkey, Items.QuantityPkg as Quantity, Items.Amount as Amount
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
	|;
	|// #AccountingCost
	|select Items.Item as Item, Items.Warehouse as Warehouse, sum ( Items.Quantity ) as Units, sum ( Items.Amount ) as Amount
	|from Items as Items
	|group by Items.Item, Items.Warehouse
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlWarehouse ( Env )
	
	s = "
	|// #Items
	|select Goods.Item as Item, Goods.Feature as Feature, Goods.Warehouse as Warehouse, Goods.Package as Package,
	|	sum ( Goods.QuantityPkg ) as Quantity
	|from Items as Goods
	|group by Goods.Item, Goods.Feature, Goods.Warehouse, Goods.Package
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure makeValues ( Env )

	ItemDetails.Init ( Env );
	makeCost ( Env );
	commitCost ( Env );
	ItemDetails.Save ( Env );
	
EndProcedure

Procedure makeCost ( Env )
	
	fields = Env.Fields;
	lot = fields.Lot;
	date = fields.Date;
	account = fields.Account;
	recordset = Env.Registers.Cost;
	for each row in Env.Cost do
		movement = recordset.AddReceipt ();
		movement.Period = date;
		if ( row.ItemKey = null ) then
			row.ItemKey = ItemDetails.GetKey ( Env, row.Item, row.Package, row.Feature, row.Series, row.Warehouse, account );
		endif; 
		movement.ItemKey = row.ItemKey;
		if ( row.CostMethod = Enums.Cost.FIFO ) then
			if ( lot = null ) then
				lot = newLot ( Env );
			endif; 
			movement.Lot = lot;
		endif; 
		movement.Quantity = row.Quantity;
		movement.Amount = row.Amount;
	enddo; 
	
EndProcedure

Procedure commitCost ( Env )
	
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.AccountDr = fields.Account;
	p.Operation = Enums.Operations.Other;
	p.Content = Output.OpeningBalances ();
	p.AccountCr = ChartsOfAccounts.General._0;
	p.Recordset = Env.Registers.General;
	for each row in Env.AccountingCost do
		p.Amount = row.Amount;
		p.QuantityDr = row.Units;
		p.DimDr1 = row.Item;
		p.DimDr2 = row.Warehouse;
		GeneralRecords.Add ( p );
	enddo; 
	
EndProcedure

Function newLot ( Env )
	
	obj = Catalogs.Lots.CreateItem ();
	obj.Date = Env.Fields.Date;
	obj.Document = Env.Ref;
	obj.Write ();
	return obj.Ref;
	
EndFunction

Procedure makeItems ( Env )

	recordset = Env.Registers.Items;
	date = Env.Fields.Date;
	for each row in Env.Items do
		movement = recordset.AddReceipt ();
		movement.Period = date;
		movement.Item = row.Item;
		movement.Feature = row.Feature;
		movement.Warehouse = row.Warehouse;
		movement.Package = row.Package;
		movement.Quantity = row.Quantity;
	enddo; 
	
EndProcedure

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.General.Write = true;
	registers.Items.Write = true;
	registers.Cost.Write = true;
	registers.RangeStatuses.Write = true;
	registers.RangeLocations.Write = true;
	
EndProcedure

#endregion

#endif