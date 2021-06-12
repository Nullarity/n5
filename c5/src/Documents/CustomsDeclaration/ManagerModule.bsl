#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Date" );
	Fields.Add ( "Number" );
	
EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Metadata.Documents.CustomsDeclaration.Synonym + " #" + Data.Number + " " + Format ( Data.Date, "DLF=D" );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	if ( not getData ( Env ) ) then
		return false;
	endif; 
	if ( invalidRows ( Env ) ) then
		return false;
	endif;
	if ( not Env.RestoreCost ) then
		makeValues ( Env );
		if ( not distributeExpenses ( Env ) ) then
			return false;
		endif; 
		if ( not RunDebts.FromInvoice ( Env ) ) then
			return false;
		endif;
	endif;
	if ( not Env.RestoreCost
		and not Env.Realtime ) then
		fields = Env.Fields;
		SequenceCost.Rollback ( Env.Ref, fields.Company, fields.Timestamp );
	endif;
	if ( not Env.RestoreCost ) then
		writeDistribution ( Env );
		attachSequence ( Env );
	endif;
	flagRegisters ( Env );
	return true;
	
EndFunction
 
Function getData ( Env )
	
	sqlFields ( Env );
	if ( Env.Reposted ) then
		selection = Env.Selection;
		selection.Add ( Dependencies.SqlDependencies () );
		selection.Add ( Dependencies.SqlDependants () );
	endif; 
	getFields ( Env );
	if ( not removeDependency ( Env ) ) then
		return false;
	endif;
	sqlItems ( Env );
	sqlInvalidRows ( Env );
	if ( not Env.RestoreCost ) then
		sqlCharges ( Env );
		sqlExpenses ( Env );
		sqlSequence ( Env );
		if ( Env.Fields.DistributionExists ) then
			sqlDistributingExpenses ( Env );
		endif; 
	endif;
	getTables ( Env );
	Env.Insert ( "DistributionRecordsets" );
	return true;
	
EndFunction

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select top 1 Document.Date as Date, Document.Customs as Customs, Document.Distribution as Distribution, Document.Amount as ContractAmount,
	|	Document.Company as Company, Document.Contract as Contract, Constants.Currency as Currency, Constants.AdvancesMonthly as AdvancesMonthly,
	|	Document.PointInTime as Timestamp, Document.CustomsAccount as CustomsAccount, Document.VAT as VAT,
	|	isnull ( DistributionTable.Exist, false ) as DistributionExists,
	|	case when Document.PaymentDate = datetime ( 1, 1, 1 ) then datetime ( 3999, 12, 31 ) else Document.PaymentDate end as PaymentDate,
	|	Document.PaymentOption as PaymentOption, PaymentDetails.PaymentKey as PaymentKey, Document.VATAccount as VATAccount, Document.Amount as Amount,
	|	Document.Contract.VendorAdvances as CloseAdvances
	|from Document.CustomsDeclaration as Document
	|	//
	|	// Constants
	|	//
	|	join Constants as Constants
	|	on true
	|	//
	|	// PaymentDetails
	|	//
	|	left join InformationRegister.PaymentDetails as PaymentDetails
	|	on PaymentDetails.Option = Document.PaymentOption
	|	and PaymentDetails.Date = case when Document.PaymentDate = datetime ( 1, 1, 1 ) then datetime ( 3999, 12, 31 ) else Document.PaymentDate end
	|	//
	|	// Distribution
	|	//
	|	left join ( select top 1 true as Exist
	|			from Document.CustomsDeclaration.Charges
	|			where Ref = &Ref
	|			and Cost 
	|			and not VAT ) as DistributionTable
	|	on true
	|where Document.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure 

Function removeDependency ( Env )
	
	if ( Env.Reposted ) then
		if ( dependenciesExist ( Env ) ) then
			return false;
		endif;
		Dependencies.Clear ( Env.Ref, SQL.Fetch ( Env, "$Dependants" ) );
	endif; 
	return true;
	
EndFunction 

Function dependenciesExist ( Env )
	
	table = SQL.Fetch ( Env, "$Dependencies" );
	Dependencies.Show ( table );
	return table.Count () > 0;
	
EndFunction

Procedure sqlItems ( Env )
	
	s = "
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Invoice as Invoice, Items.CustomsGroup as CustomsGroup
	|into Items
	|from Document.CustomsDeclaration.Items as Items
	|where Items.Ref = &Ref
	|index by Items.Item
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlInvalidRows ( Env )
	
	s = "
	|// ^InvalidRows
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Invoice as Document
	|from Items as Items
	|	//
	|	// Goods
	|	//
	|	left join Document.VendorInvoice.Items as Goods
	|	on Goods.Ref = Items.Invoice
	|	and Goods.Item = Items.Item
	|where Goods.Item is null
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlCharges ( Env )
	
	s = "
	|select Charges.LineNumber as LineNumber, Charges.Charge as Charge, Charges.CustomsGroup as CustomsGroup, Charges.Amount as Amount, Charges.VAT as VAT,
	|	Charges.ExpenseAccount as ExpenseAccount, Charges.Dim1 as Dim1,	Charges.Dim2 as Dim2, Charges.Dim3 as Dim3,	Charges.Product as Product, 
	|	Charges.Cost as Cost, Charges.ProductFeature as ProductFeature
	|into Charges
	|from Document.CustomsDeclaration.Charges as Charges
	|where Charges.Ref = &Ref
	|index by Charges.CustomsGroup
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlExpenses ( Env )
	
	s = "
	|// ^Expenses
	|select Charges.ExpenseAccount as ExpenseAccount, Charges.Dim1 as Dim1, Charges.Dim2 as Dim2, Charges.Dim3 as Dim3, Charges.Product as Product,
	|	Charges.ProductFeature as ProductFeature, Charges.Amount as Amount
	|from Charges as Charges
	|where not Charges.Cost
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

Procedure sqlDistributingExpenses ( Env )
	
	s = "
	|// ^DistributingExpenses
	|select Charges.LineNumber as ChargesLineNumber, Charges.Amount as Amount, Charges.CustomsGroup as CustomsGroup, 
	|	case when &Distribution = value ( Enum.Distribution.Quantity ) then ""Quantity""
	|		when &Distribution = value ( Enum.Distribution.Amount ) then ""Amount""
	|		when &Distribution = value ( Enum.Distribution.Weight ) then ""Weight""
	|	end as DistributeColumn, presentation ( Charges.Charge ) as ChargePresentation, Charges.Charge as Charge
	|from Charges as Charges
	|where Charges.Cost
	|and not Charges.VAT
	|;
	|// Accepters
	|select distinct Items.Invoice as Document, isnull ( ExchangeRates.Rate, 1 ) as Rate, isnull ( ExchangeRates.Factor, 1 ) as Factor, Items.Item as Item,
	|	Items.CustomsGroup as CustomsGroup
	|into Accepters
	|from Items as Items
	|	//
	|	// ExchangeRates
	|	//
	|	left join InformationRegister.ExchangeRates.SliceLast ( &Timestamp ) as ExchangeRates
	|	on ExchangeRates.Currency = Items.Invoice.Currency
	|index by Items.Invoice, Items.Item
	|;
	|// ^DistributionBase
	|select Goods.LineNumber as LineNumber, Goods.Ref as Document, Goods.Ref.Date as Date,
	|	Goods.Quantity as Quantity, Goods.Quantity * Goods.Item.Weight as Weight, Goods.Amount * Accepters.Rate / Accepters.Factor as Amount,
	|	Goods.Item as Item, Goods.Account as Account,
	|	Goods.Package as Package, Goods.Feature as Feature, Goods.Series as Series,
	|	case when Goods.Warehouse = value ( Catalog.Warehouses.EmptyRef ) then Goods.Ref.Warehouse else Goods.Warehouse end as Warehouse,
	|	case when Goods.Item.CostMethod = value ( Enum.Cost.Avg ) then value ( Catalog.Lots.EmptyRef ) else Lots.Ref end as Lot,
	|	Details.ItemKey as ItemKey, Accepters.CustomsGroup as CustomsGroup
	|from Document.VendorInvoice.Items as Goods
	|	//
	|	// Details
	|	//
	|	left join InformationRegister.ItemDetails as Details
	|	on Details.Item = Goods.Item
	|	and Details.Package = case when Goods.Item.CountPackages then Goods.Package else value ( Catalog.Packages.EmptyRef ) end
	|	and Details.Feature = Goods.Feature
	|	and Details.Warehouse = ( case when Goods.Warehouse = value ( Catalog.Warehouses.EmptyRef ) then Goods.Ref.Warehouse else Goods.Warehouse end )
	|	and Details.Series = Goods.Series
	|	and Details.Account = Goods.Account
	|	//
	|	// Accepters
	|	//
	|	join Accepters as Accepters
	|	on Accepters.Document = Goods.Ref
	|	and Accepters.Item = Goods.Item
	|	//
	|	// Lots
	|	//
	|	left join Catalog.Lots as Lots
	|	on Lots.Document = Goods.Ref
	|where Goods.Ref.Posted
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure getTables ( Env )
	
	fields = Env.Fields;
	q = Env.Q;
	q.SetParameter ( "Timestamp", fields.Timestamp );
	q.SetParameter ( "Distribution", fields.Distribution );
	SQL.Prepare ( Env );
	Env.Insert ( "Data", q.ExecuteBatch () );
	SQL.Unload ( Env, Env.Data );
	
EndProcedure 

Function invalidRows ( Env )
	
	table = SQL.Fetch ( Env, "$InvalidRows" );
	for each row in table do
		Output.DocumentOrderItemsNotValid ( new Structure ( "DocumentOrder", row.Document ), Output.Row ( "Items", row.LineNumber, "Item" ), Env.Ref );
	enddo; 
	return table.Count () > 0;
	
EndFunction

Procedure makeValues ( Env )

	table = SQL.Fetch ( Env, "$Expenses" );
	makeExpenses ( Env, table );
	commitExpenses ( Env, table );
	commitVAT ( Env );
	
EndProcedure

Procedure makeExpenses ( Env, Table )
	
	recordset = Env.Registers.Expenses;
	expenses = Table.Copy ( , "ExpenseAccount, Dim1, Dim2, Dim3, Product, ProductFeature, Amount" );
	expenses.GroupBy ( "ExpenseAccount, Dim1, Dim2, Dim3, Product, ProductFeature", "Amount" );
	ref = Env.Ref;
	expensesType = Type ( "CatalogRef.Expenses" );
	departmentsType = Type ( "CatalogRef.Departments" );
	date = Env.Fields.Date;
	for each row in expenses do
		movement = recordset.Add ();
		movement.Document = ref;
		movement.Period = date;
		movement.Account = row.ExpenseAccount;
		movement.Expense = findDimension ( row, expensesType );
		movement.Department = findDimension ( row, departmentsType );
		movement.Product = row.Product;
		movement.ProductFeature = row.ProductFeature;
		movement.AmountDr = row.Amount;
	enddo;
	
EndProcedure

Function findDimension ( Row, Type )
	
	value = Row.Dim1;
	if ( TypeOf ( value ) = Type ) then
		return value;
	endif;
	value = Row.Dim2;
	if ( TypeOf ( value ) = Type ) then
		return value;
	endif;
	value = Row.Dim2;
	if ( TypeOf ( value ) = Type ) then
		return value;
	endif;
	
EndFunction 

Procedure commitExpenses ( Env, Table )
	
	fields = Env.Fields;
	customsAccount = fields.CustomsAccount;
	customs = fields.Customs;
	contract = fields.Contract;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.WriteoffCharges;
	p.DimCr1Type = "Organizations";
	p.DimCr2Type = "Contracts";
	p.Recordset = Env.Registers.General;
	Table.GroupBy ( "Dim1, Dim2, Dim3, ExpenseAccount", "Amount" );
	for each row in Table do
		p.Amount = row.Amount;
		p.AccountCr = customsAccount;
		p.DimCr1 = customs;
		p.DimCr2 = contract;
		p.AccountDr = row.ExpenseAccount;
		p.DimDr1 = row.Dim1;
		p.DimDr2 = row.Dim2;
		p.DimDr3 = row.Dim3;
		GeneralRecords.Add ( p );
	enddo; 

EndProcedure

Procedure commitVAT ( Env ) 

	if ( Env.Fields.VAT = 0 ) then
		return;
	endif;
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.OffsetVATImport;
	p.DimCr1Type = "Organizations";
	p.DimCr2Type = "Contracts";
	p.Recordset = Env.Registers.General;
	p.Amount = fields.VAT;
	p.AccountCr = fields.CustomsAccount;
	p.DimCr1 = fields.Customs;
	p.DimCr2 = fields.Contract;
	p.AccountDr = fields.VATAccount;
	GeneralRecords.Add ( p );
	
EndProcedure

Function distributeExpenses ( Env )
	
	if ( not Env.Fields.DistributionExists ) then
		return true;
	endif;
	table = getDistribution ( Env );
	if ( table = undefined ) then
		return false;
	endif; 
	saveDistribution ( Env, table );
	makeCustomsCharges ( Env, table );
	return true;

EndFunction

Function getDistribution ( Env )
	
	result = new ValueTable ();
	tables = getDistributingTables ( Env );
	if ( tables.Base.Count () = 0 ) then
		Output.BaseNotFound ( , , Env.Ref );
		return undefined;
	endif; 
	p = getDistributingParams ( Env );
	for each expensesRow in tables.Expenses do
		tables.ExpensesByRow.Clear ();
		row = tables.ExpensesByRow.Add ();
		FillPropertyValues ( row, expensesRow );
		tables.BaseByRow.Clear ();
		for each baseRow in tables.Base do
			row = tables.BaseByRow.Add ();
			FillPropertyValues ( row, baseRow );
		enddo; 
		p.Insert ( "KeyColumn", expensesRow.DistributeColumn );
		CollectionsSrv.Join ( result, CollectionsSrv.Combine ( tables.ExpensesByRow, tables.BaseByRow, p ) );
		if ( tables.ExpensesByRow.Count () > 0 ) then
			// Error....
			return undefined;
		endif; 
	enddo; 
	return result;
	
EndFunction 

Function getDistributingTables ( Env )
	
	tables = new Structure ();
	tables.Insert ( "Expenses", SQL.Fetch ( Env, "$DistributingExpenses" ) );
	tables.Insert ( "ExpensesByRow", tables.Expenses.CopyColumns () );
	amountType = Metadata.AccountingRegisters.General.Resources.Amount.Type;
	CollectionsSrv.Adjust ( tables.ExpensesByRow, "Amount", amountType );
	base = SQL.Fetch ( Env, "$DistributionBase" );
	tables.Insert ( "Base", base );
	tables.Insert ( "BaseByRow", base.CopyColumns () );
	return tables;
	
EndFunction 

Function getDistributingParams ( Env )
	
	p = new Structure ();
	p.Insert ( "FilterColumns", "CustomsGroup" );
	p.Insert ( "DistribColumnsTable1", "Amount" );
	p.Insert ( "DistributeTables" );
	p.Insert ( "AssignСоlumnsTаble1", "Charge, ChargePresentation, ChargesLineNumber" );
	p.Insert ( "AssignColumnsTable2", "Document, Item, Warehouse, Account, ItemKey, Lot, Date, LineNumber" );
	return p;
	
EndFunction 

Procedure saveDistribution ( Env, DistributedExpenses )
	
	fields = Env.Fields;
	Env.DistributionRecordsets = new Map ();
	entry = GeneralRecords.GetParams ();
	entry.Date = fields.Date;
	entry.Company = fields.Company;
	entry.Operation = Enums.Operations.AdditionalExpenses;
	for each row in DistributedExpenses do
		makeAdditionalCost ( Env, row );
		commitAdditionalCost ( Env, row, entry );
		makeItemExpenses ( Env, row );
	enddo; 

EndProcedure 

Procedure makeAdditionalCost ( Env, Row )
	
	recordset = distributionRecordset ( Env, row.Document );
	movement = recordset.Add ();
	movement.Period = Row.Date;
	movement.ItemKey = Row.ItemKey;
	movement.Lot = Row.Lot;
	movement.Amount = Row.Amount;
	ref = Env.Ref;
	if ( ref <> Row.Document ) then
		movement.Dependency = ref;
	endif; 
	
EndProcedure 

Function distributionRecordset ( Env, Document )
	
	recordsets = Env.DistributionRecordsets;
	recordset = recordsets [ Document ];
	if ( recordset = undefined ) then
		recordset = AccumulationRegisters.Cost.CreateRecordSet ();
		recordset.Filter.Recorder.Set ( Document );
		recordsets [ Document ] = recordset;
		return recordset;
	else
		return recordset;
	endif; 
	
EndFunction 

Procedure commitAdditionalCost ( Env, Row, Entry )
	
	fields = Env.Fields;
	Entry.DimDr1 = Row.Item;
	Entry.DimDr1Type = "Items";
	Entry.DimDr2 = Row.Warehouse;
	Entry.DimDr2Type = "Warehouses";
	document = Row.Document;
	if ( document <> Env.Ref ) then
		Entry.Dependency = document;
	endif; 
	Entry.AccountDr = Row.Account;
	Entry.AccountCr = fields.CustomsAccount;
	Entry.DimCr1 = fields.Customs;
	Entry.DimCr2 = fields.Contract;
	Entry.Amount = Row.Amount;
	Entry.Recordset = Env.Registers.General;
	Entry.Content = getContent ( Entry, Row );
	GeneralRecords.Add ( Entry );
	
EndProcedure 

Function getContent ( Entry, Row )
	
	return "" + Entry.Operation + ": " + row.ChargePresentation;
	
EndFunction 

Procedure makeItemExpenses ( Env, Row )
	
	movement = Env.Registers.ItemExpenses.Add ();
	movement.Date = Row.Date;
	movement.Document = Row.Document;
	tables = Enums.Tables;
	movement.DocumentTable = tables.Items;
	movement.DocumentRow = Row.LineNumber;
	movement.Source = Env.Ref;
	movement.Table = tables.Charges;
	movement.TableRow = Row.ChargesLineNumber;
	movement.Amount = row.Amount;
	
EndProcedure 

Procedure makeCustomsCharges ( Env, Table )
	
	Table.GroupBy ( "Item, Document, Charge", "Amount" );
	recordset = Env.Registers.CustomsCharges;
	date = Env.Fields.Date;
	for each row in Table do
		movement = recordset.Add ();
		FillPropertyValues ( movement, row );
		movement.Period = date;
	enddo;
	
EndProcedure 

Procedure writeDistribution ( Env )
	
	if ( Env.Fields.DistributionExists ) then
		for each recordset in Env.DistributionRecordsets do
			recordset.Value.Write ( false );
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
		movement.Company = company;
		movement.Item = row.Item;
	enddo;
	recordset.Write ();
	
EndProcedure

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.General.Write = true;
	registers.Expenses.Write = true;
	registers.VendorDebts.Write = true;
	registers.CustomsCharges.Write = true;
	registers.ItemExpenses.Write = true;
	
EndProcedure

#endregion

#endif