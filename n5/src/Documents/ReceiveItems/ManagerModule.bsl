#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.ReceiveItems.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	if ( not checkRows ( Env ) ) then
		return false;
	endif;
	makeValues ( Env );
	makeItems ( Env );
	makeFixedAssets ( Env );
	makeIntangibleAssets ( Env );
	makeProducerPrices ( Env );
	SequenceCost.Rollback ( Env.Ref, Env.Fields.Company, Env.Fields.Timestamp );
	flagRegisters ( Env );
	return true;
	
EndFunction
 
Procedure getData ( Env )
	
	sqlFields ( Env );
	getFields ( Env );
	defineAmount ( Env );
	sqlItems ( Env );
	if ( Options.Series () ) then
		sqlEmptySeries ( Env );
	endif;
	sqlCost ( Env );
	sqlWarehouse ( Env );
	sqlFixedAssets ( Env );
	sqlIntangibleAssets ( Env );
	sqlProducerPrices ( Env );
	getTables ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select top 1 Documents.Date as Date, Documents.Warehouse as Warehouse, Documents.Company as Company, 
	|	Documents.Currency as Currency, Documents.PointInTime as Timestamp, Documents.Rate as Rate, 
	|	Documents.Factor as Factor, Documents.Account as Account,
	|	Documents.Dim1 as Dim1, Documents.Dim2 as Dim2, Documents.Dim3 as Dim3,  
	|	Constants.Currency as LocalCurrency, Lots.Ref as Lot
	|from Document.ReceiveItems as Documents
	|	//
	|	// Lots
	|	//
	|	left join Catalog.Lots as Lots
	|	on Lots.Document = &Ref
	|	//
	|	// Constants
	|	//
	|	join Constants as Constants
	|	on true
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure defineAmount ( Env )
	
	list = new Structure ();
	Env.Insert ( "AmountFields", list );
	amount = "( Total - VAT )";
	currencyAmount = amount;
	fields = Env.Fields;
	if ( fields.Currency <> fields.LocalCurrency ) then
		rate = " * &Rate / &Factor";
		amount = amount + rate;
	endif;
	list.Insert ( "Amount", "cast ( " + amount + " as Number ( 15, 2 ) )" );
	list.Insert ( "CurrencyAmount", currencyAmount );
	
EndProcedure 

Procedure sqlItems ( Env )
	
	amount = Env.AmountFields;
	s = "
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	Items.Quantity as Quantity, Items.Account as Account, 
	|	case when Items.Item.CountPackages then Items.QuantityPkg else Items.Quantity end as QuantityPkg,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package,
	|	case when ( Items.Warehouse = value ( Catalog.Warehouses.EmptyRef ) ) then &Warehouse else Items.Warehouse end as Warehouse,
	|	Items.Social as Social, Items.Price as Price, Items.ProducerPrice as ProducerPrice,
	|	" + amount.Amount + " as Amount, " + amount.CurrencyAmount + " as CurrencyAmount
	|into Items
	|from Document.ReceiveItems.Items as Items
	|where Items.Ref = &Ref
	|index by Items.Item, Items.Feature, Items.Series
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

Procedure sqlCost ( Env )
	
	s = "
	|// #Cost
	|select Items.Item as Item, Items.Item.CostMethod as CostMethod, Items.Package as Package,
	|	Items.Feature as Feature, Items.Series as Series, Items.Warehouse as Warehouse, Items.Account as Account,
	|	Details.ItemKey as Itemkey, Items.QuantityPkg as Quantity, Items.Quantity as Units, Items.Amount as Amount,
	|	Items.CurrencyAmount as CurrencyAmount
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
	|select Items.Item as Item, Items.Warehouse as Warehouse, Items.Account as Account,
	|	sum ( Items.Quantity ) as Units, sum ( Items.Amount ) as Amount, sum ( Items.CurrencyAmount ) as CurrencyAmount
	|from Items as Items
	|group by Items.Item, Items.Warehouse, Items.Account
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlWarehouse ( Env )
	
	s = "
	|// #Items
	|select Goods.Item as Item, Goods.Feature as Feature, Goods.Warehouse as Warehouse, Goods.Package as Package,
	|	Goods.Series as Series, sum ( Goods.QuantityPkg ) as Quantity
	|from Items as Goods
	|group by Goods.Item, Goods.Feature, Goods.Series, Goods.Warehouse, Goods.Package
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlFixedAssets ( Env )
	
	amount = Env.AmountFields;
	s = "
	|// #FixedAssets
	|select Items.Acceleration as Acceleration, Items.Charge as Charge, Items.Department as Department,
	|	Items.Employee as Employee, Items.Expenses as Expenses, Items.Item as Item,
	|	Items.LiquidationValue as LiquidationValue, Items.Method as Method, 
	|	Items.Item.Account as Account, Items.Starting as Starting, Items.Schedule as Schedule, Items.UsefulLife as UsefulLife,
	|	" + amount.Amount + " as Amount, " + amount.CurrencyAmount + " as CurrencyAmount
	|from Document.ReceiveItems.FixedAssets as Items
	|where Items.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlIntangibleAssets ( Env )
	
	amount = Env.AmountFields;
	s = "
	|// #IntangibleAssets
	|select Items.Acceleration as Acceleration, Items.Charge as Charge, Items.Department as Department,
	|	Items.Employee as Employee, Items.Expenses as Expenses, Items.Item as Item, Items.Method as Method,
	|	Items.Item.Account as Account, Items.Starting as Starting, Items.UsefulLife as UsefulLife,
	|	" + amount.Amount + " as Amount, " + amount.CurrencyAmount + " as CurrencyAmount
	|from Document.ReceiveItems.IntangibleAssets as Items
	|where Items.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables ( Env )
	
	fields = Env.Fields;
	Env.Q.SetParameter ( "Warehouse", fields.Warehouse );
	Env.Q.SetParameter ( "Rate", fields.Rate );
	Env.Q.SetParameter ( "Factor", fields.Factor );
	SQL.Prepare ( Env );
	Env.Insert ( "Data", Env.Q.ExecuteBatch () );
	SQL.Unload ( Env, Env.Data );
	
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

Procedure makeValues ( Env )

	ItemDetails.Init ( Env );
	makeCost ( Env );
	commitCost ( Env );
	ItemDetails.Save ( Env );
	
EndProcedure

Procedure makeCost ( Env )
	
	recordset = Env.Registers.Cost;
	fields = Env.Fields;
	lot = fields.Lot;
	date = fields.Date;
	for each row in Env.Cost do
		movement = recordset.AddReceipt ();
		movement.Period = date;
		if ( row.ItemKey = null ) then
			row.ItemKey = ItemDetails.GetKey ( Env, row.Item, row.Package, row.Feature, row.Series, row.Warehouse, row.Account );
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

Function newLot ( Env )
	
	obj = Catalogs.Lots.CreateItem ();
	obj.Date = Env.Fields.Date;
	obj.Document = Env.Ref;
	obj.Write ();
	return obj.Ref;
	
EndFunction

Procedure commitCost ( Env )
	
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	p.Recordset = Env.Registers.General;
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.OtherReceipt;
	p.AccountCr = fields.Account;
	p.DimCr1 = fields.Dim1;
	p.DimCr2 = fields.Dim2;
	p.DimCr3 = fields.Dim3;
	p.CurrencyCr = fields.Currency;
	for each row in Env.AccountingCost do
		p.AccountDr = row.Account;
		p.Amount = row.Amount;
		p.QuantityDr = row.Units;
		p.DimDr1 = row.Item;
		p.DimDr2 = row.Warehouse;
		p.CurrencyAmountCr = row.CurrencyAmount;
		GeneralRecords.Add ( p );
	enddo;

EndProcedure

Procedure makeItems ( Env )

	recordset = Env.Registers.Items;
	date = Env.Fields.Date;
	for each row in Env.Items do
		movement = recordset.AddReceipt ();
		movement.Period = date;
		movement.Item = row.Item;
		movement.Feature = row.Feature;
		movement.Series = row.Series;
		movement.Warehouse = row.Warehouse;
		movement.Package = row.Package;
		movement.Quantity = row.Quantity;
	enddo; 
	
EndProcedure

Procedure makeFixedAssets ( Env )

	table = Env.FixedAssets;
	if ( table.Count () = 0 ) then
		return;
	endif; 
	registers = Env.Registers;
	depreciation = registers.Depreciation;
	location = registers.FixedAssetsLocation;
	fields = Env.Fields;
	date = fields.Date;
	account = fields.Account;
	currency = fields.Currency;
	dim1 = fields.Dim1;
	dim2 = fields.Dim2;
	dim3 = fields.Dim3;
	p = GeneralRecords.GetParams ();
	p.Date = date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.FixedAssetsReceipt;
	p.Recordset = Env.Registers.General;
	for each row in table do
		item = row.Item;
		movement = depreciation.Add ();
		movement.Period = date;
		movement.Asset = item;
		movement.Acceleration = row.Acceleration;
		movement.Charge = row.Charge;
		movement.Expenses = row.Expenses;
		movement.LiquidationValue = row.LiquidationValue;
		movement.Method = row.Method;
		movement.Starting = row.Starting;
		movement.Schedule = row.Schedule;
		movement.UsefulLife = row.UsefulLife;
		movement = location.Add ();
		movement.Period = date;
		movement.Asset = item;
		movement.Employee = row.Employee;
		movement.Department = row.Department;
		p.AccountDr = row.Account;
		p.QuantityDr = 1;
		p.Amount = row.Amount;
		p.DimDr1 = item;
		p.AccountCr = account;
		p.DimCr1 = dim1;
		p.DimCr2 = dim2;
		p.DimCr3 = dim3;
		p.CurrencyCr = currency;
		p.CurrencyAmountCr = row.CurrencyAmount;
		GeneralRecords.Add ( p );
	enddo; 
	
EndProcedure

Procedure makeIntangibleAssets ( Env )

	table = Env.IntangibleAssets;
	if ( table.Count () = 0 ) then
		return;
	endif; 
	registers = Env.Registers;
	amortization = registers.Amortization;
	location = registers.IntangibleAssetsLocation;
	fields = Env.Fields;
	date = fields.Date;
	account = fields.Account;
	currency = fields.Currency;
	dim1 = fields.Dim1;
	dim2 = fields.Dim2;
	dim3 = fields.Dim3;
	p = GeneralRecords.GetParams ();
	p.Date = date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.IntangibleAssetsReceipt;
	p.Recordset = Env.Registers.General;
	for each row in table do
		asset = row.Item;
		record = amortization.Add ();
		record.Period = date;
		record.Asset = asset;
		record.Acceleration = row.Acceleration;
		record.Charge = row.Charge;
		record.Expenses = row.Expenses;
		record.Method = row.Method;
		record.Starting = row.Starting;
		record.UsefulLife = row.UsefulLife;
		record = location.Add ();
		record.Period = date;
		record.Asset = asset;
		record.Employee = row.Employee;
		record.Department = row.Department;
		p.AccountDr = row.Account;
		p.Amount = row.Amount;
		p.DimDr1 = asset;
		p.QuantityDr = 1;
		p.AccountCr = account;
		p.DimCr1 = dim1;
		p.DimCr2 = dim2;
		p.DimCr3 = dim3;
		p.CurrencyCr = currency;
		p.CurrencyAmountCr = row.CurrencyAmount;
		GeneralRecords.Add ( p );
	enddo; 
	
EndProcedure

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.General.Write = true;
	registers.Items.Write = true;
	registers.FixedAssetsLocation.Write = true;
	registers.IntangibleAssetsLocation.Write = true;
	registers.Amortization.Write = true;
	registers.Depreciation.Write = true;
	registers.Cost.Write = true;
	registers.ProducerPrices.Write = true;
	
EndProcedure

Procedure sqlProducerPrices ( Env )
	
	s = "
	|// #ProducerPrices
	|select Items.Item as Item, Items.ProducerPrice as Price, Items.Package as Package, Items.Feature as Feature
	|from Items as Items
	|where Items.Social
	|and Items.Price <> 0
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure makeProducerPrices ( Env ) 

	table = Env.ProducerPrices;
	if ( table.Count () = 0 ) then
		return;
	endif;
	recordset = Env.Registers.ProducerPrices;
	date = Env.Fields.Date;
	for each row in table do
		movement = recordset.Add ();
		movement.Period = date;
		movement.Item = row.Item;
		movement.Package = row.Package;
		movement.Feature = row.Feature;
		movement.Price = row.Price;
	enddo;

EndProcedure

#endregion

#endif