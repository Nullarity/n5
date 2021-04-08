#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Date" );
	Fields.Add ( "Number" );
	
EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Metadata.Documents.LVIWriteOff.Synonym + " #" + Data.Number + " " + Format ( Data.Date, "DLF=D" );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	ItemDetails.Init ( Env );
	if ( not makeValues ( Env ) ) then
		return false;
	endif;
	ItemDetails.Save ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )

	sqlFields ( Env );
	getFields ( Env );
	defineAmount ( Env );
	sqlItems ( Env );
	sqlItemKeys ( Env );
	sqlItemsAndKeys ( Env );
	getTables ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Document.Date as Date, Document.Company as Company, Constants.Currency as LocalCurrency,
	|	Document.PointInTime as Timestamp, Document.AmortizationAccount as AmortizationAccount,
	|	Document.Rate as Rate, Document.Factor as Factor, Document.Currency as Currency, Document.ExpenseAccount as ExpenseAccount,
	|	Document.Dim1 as Dim1, Document.Dim2 as Dim2, Document.Dim3 as Dim3, Document.Department, 
	|	Document.Product as Product, Document.ProductFeature as ProductFeature
	|from Document.LVIWriteOff as Document
	|	//
	|	// Constants
	|	//
	|	join Constants as Constants
	|	on true
	|where Document.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	Env.Insert ( "CostOnline", Options.CostOnline ( Env.Fields.Company ) );
	
EndProcedure 

Procedure defineAmount ( Env )
	
	list = new Structure ();
	fields = Env.Fields;
	amount = "Amount";
	if ( fields.Currency <> fields.LocalCurrency ) then
		amount = amount + " * &Rate / &Factor";
	endif;
	list.Insert ( "Amount", "cast ( " + amount + " as Number ( 15, 2 ) )" );
	Env.Insert ( "AmountFields", list );

EndProcedure 

Procedure sqlItems ( Env )
	
	s = "
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	Items.Quantity as Quantity,
	|	case when Items.Item.CountPackages then Items.Capacity else 1 end as Capacity,
	|	case when Items.Item.CountPackages then Items.Package.Description else Items.Item.Unit.Code end as Unit,
	|	case when Items.Item.CountPackages then Items.QuantityPkg else Items.Quantity end as QuantityPkg,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package,
	|	" + Env.AmountFields.Amount + " as ResidualValue,
	|	case when ( Items.ExpenseAccount = value ( ChartOfAccounts.General.EmptyRef ) ) then &ExpenseAccount else Items.ExpenseAccount end as ExpenseAccount,
	|	case when ( Items.ExpenseAccount = value ( ChartOfAccounts.General.EmptyRef ) ) then &Dim1 else Items.Dim1 end as Dim1,
	|	case when ( Items.ExpenseAccount = value ( ChartOfAccounts.General.EmptyRef ) ) then &Dim2 else Items.Dim2 end as Dim2,
	|	case when ( Items.ExpenseAccount = value ( ChartOfAccounts.General.EmptyRef ) ) then &Dim3 else Items.Dim3 end as Dim3,
	|	case when ( Items.Product = value ( Catalog.Items.EmptyRef ) ) then &Product else Items.Product end as Product,
	|	case when ( Items.ProductFeature = value ( Catalog.Features.EmptyRef ) ) then &ProductFeature else Items.ProductFeature end as ProductFeature,
	|	Items.Account as Account, &Department as Department, Items.Employee.Individual as Employee
	|into Items
	|from Document.LVIWriteOff.Items as Items
	|where Items.Ref = &Ref
	|index by Items.Item, Items.Feature
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlItemKeys ( Env )
	
	s = "
	|select distinct Items.Item as Item, Items.Feature as Feature, Items.Series as Series, Items.Account as Account,
	|	Details.ItemKey as ItemKey, Items.Department, Items.Employee
	|into ItemKeys
	|from Items as Items
	|	//
	|	// Details
	|	//
	|	left join InformationRegister.ItemDetails as Details
	|	on Details.Item = Items.Item
	|	and Details.Package = Items.Package
	|	and Details.Feature = Items.Feature
	|	and Details.Series = Items.Series
	|	and Details.Account = Items.Account
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
	|select Items.LineNumber as LineNumber, Items.Item as Item,
	|	Items.Package as Package, Items.Unit as Unit, Items.Feature as Feature, Items.Series as Series,
	|	Items.Account as Account, Items.ExpenseAccount as ExpenseAccount,
	|	Items.Dim1 as Dim1, Items.Dim2 as Dim2, Items.Dim3 as Dim3,
	|	Items.Product as Product, Items.ProductFeature as ProductFeature, Items.Employee as Employee,
	|	Items.QuantityPkg as Quantity, Items.Capacity as Capacity, Details.ItemKey as ItemKey, 
	|	Items.ResidualValue as ResidualValue, Items.Department as Department
	|from Items as Items
	|	//
	|	// Details
	|	//
	|	left join InformationRegister.ItemDetails as Details
	|	on Details.Item = Items.Item
	|	and Details.Package = Items.Package
	|	and Details.Feature = Items.Feature
	|	and Details.Series = Items.Series
	|	and Details.Account = Items.Account
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables ( Env )
	
	fields = Env.Fields;
	q = Env.Q;
	q.SetParameter ( "Timestamp", ? ( Env.Realtime, undefined, fields.Timestamp ) );
	q.SetParameter ( "Rate", fields.Rate );
	q.SetParameter ( "Factor", fields.Factor );
	q.SetParameter ( "ExpenseAccount", fields.ExpenseAccount );
	q.SetParameter ( "Dim1", fields.Dim1 );
	q.SetParameter ( "Dim2", fields.Dim2 );
	q.SetParameter ( "Dim3", fields.Dim3 );
	q.SetParameter ( "Department", fields.Department );
	q.SetParameter ( "Product", fields.Product );
	q.SetParameter ( "ProductFeature", fields.ProductFeature );
	SQL.Perform ( Env );
	
EndProcedure 

Function makeValues ( Env )

	cost = undefined;
	if ( not calcCost ( Env, cost ) ) then
		return false;
	endif;
	makeExpenses ( Env, cost );
	commitCost ( Env, cost );
	return true;

EndFunction

Function calcCost ( Env, Cost )
	
	table = SQL.Fetch ( Env, "$ItemsAndKeys" );
	Cost = getCost ( Env, table );
	error = ( table.Count () > 0 );
	if ( error ) then
		completeCost ( Env, Cost, table );
		return false;
	endif; 
	return true;
	
EndFunction

Function getCost ( Env, Items )
	
	sqlCost ( Env );
	SQL.Prepare ( Env );
	cost = Env.Q.Execute ().Unload ();
	p = new Structure ();
	p.Insert ( "FilterColumns", "Item" );
	if ( Options.Features () ) then
		p.FilterColumns = p.FilterColumns + ", Feature";
	endif; 
	if ( Options.Series () ) then
		p.FilterColumns = p.FilterColumns + ", Series";
	endif; 
	p.Insert ( "KeyColumn", "Quantity" );
	p.Insert ( "KeyColumnAvailable", "QuantityBalance" );
	p.Insert ( "DecreasingColumns", "Cost" );
	p.Insert ( "AddInTable1FromTable2", "Capacity, Product, ProductFeature, ExpenseAccount, ResidualValue, Department, Employee, Dim1, Dim2, Dim3" );
	return CollectionsSrv.Decrease ( cost, Items, p );
	
EndFunction 

Procedure sqlCost ( Env )
	
	s = "
	|select Balances.QuantityBalanceDr as Quantity,
	|	Items.Item as Item, Items.Department as Department, Balances.AmountBalanceDr as Cost,
	|	Items.Account as Account, Items.Employee, Items.ItemKey as ItemKey, Items.Feature as Feature, Items.Series as Series
	|from AccountingRegister.General.Balance(&Timestamp, Account in ( select distinct Account from ItemKeys ), , 
	|	(ExtDimension1, ExtDimension2, ExtDimension3) in ( select distinct Item, Department, Employee from ItemKeys ) ) as Balances
	|	//
	|	// Items
	|	//
	|	left join ItemKeys as Items
	|	on Items.Item = Balances.ExtDimension1
	|	and Items.Department = Balances.ExtDimension2
	|	and Items.Employee = Balances.ExtDimension3
	|	and Balances.QuantityBalanceDr > 0
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure completeCost ( Env, Cost, Items )
	
	column = ? ( Options.Packages (), "QuantityPkg", "Quantity" );
	msg = Posting.Msg ( Env, "Item, QuantityBalance, Quantity, Department, Employee" );
	ref = Env.Ref;
	for each row in Items do
		item = row.Item;
		package = row.Package;
		if ( row.ItemKey = null ) then
			row.ItemKey = ItemDetails.GetKey ( Env, item, package, row.Feature, row.Series, , row.Account );
		endif; 
		costRow = Cost.Add ();
		FillPropertyValues ( costRow, row );
		msg.Item = item;
		msg.Department = row.Department;
		msg.Employee = row.Employee;
		quantityBalance = row.QuantityBalance;
		msg.QuantityBalance = Conversion.NumberToQuantity ( quantityBalance, package );
		msg.Quantity = Conversion.NumberToQuantity ( row.Quantity - quantityBalance, package );
		OutputCont.LVIBalanceError ( msg, Output.Row ( "Items", row.LineNumber, column ), ref );
	enddo; 
		
EndProcedure 

Procedure makeExpenses ( Env, Table )
	
	recordset = Env.Registers.Expenses;
	expenses = Table.Copy ( , "ItemKey, ExpenseAccount, Product, ProductFeature, Quantity, Cost, ResidualValue, Dim1, Dim2, Dim3" );
	expenses.GroupBy ( "ItemKey, ExpenseAccount, Product, ProductFeature, Dim1, Dim2, Dim3", "Quantity, Cost, ResidualValue" );
	date = Env.Fields.Date;
	expensesType = Type ( "CatalogRef.Expenses" );
	departmentsType = Type ( "CatalogRef.Departments" );
	for each row in expenses do
		movement = recordset.Add ();
		movement.Period = date;
		movement.Document = Env.Ref;
		movement.ItemKey = row.ItemKey;
		movement.Account = row.ExpenseAccount;
		movement.Product = row.Product;
		movement.ProductFeature = row.ProductFeature;
		movement.Expense = findDimension ( row, expensesType );
		movement.Department = findDimension ( row, departmentsType );
		movement.AmountDr = row.ResidualValue + ( row.Cost - row.ResidualValue ) / 2;
		movement.QuantityDr = row.Quantity;
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

Procedure commitCost ( Env, Table )
	
	fields = Env.Fields;
	amoritzation = fields.AmortizationAccount;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.LVIWriteOff;
	p.Recordset = Env.Registers.General;
	Table.GroupBy ( "Department, Employee, Item, Capacity, Account, Dim1, Dim2, Dim3, ExpenseAccount", "Quantity, Cost, ResidualValue" );
	for each row in Table do
		residual = row.ResidualValue;
		onlyCost = row.Cost - residual;
		p.DimCr1Type = "Items";
		p.DimCr2Type = "Departments";
		p.Amount = onlyCost / 2;
		p.AccountCr = amoritzation;
		p.QuantityCr = row.Quantity * row.Capacity;
		p.DimCr1 = row.Item;
		p.DimCr2 = row.Department;
		p.AccountDr = row.ExpenseAccount;
		p.DimDr1 = row.Dim1;
		p.DimDr2 = row.Dim2;
		p.DimDr3 = row.Dim3;
		GeneralRecords.Add ( p );
		p.DimCr3Type = "Employees";
		p.DimCr3 = row.Employee;
		p.AccountCr = row.Account;
		if ( residual <> 0 ) then
			p.Amount = residual;
			GeneralRecords.Add ( p );
		endif;
		p.DimDr1Type = "Items";
		p.DimDr2Type = "Departments";
		p.DimDr3Type = "";
		p.Amount = onlyCost;
		p.AccountDr = amoritzation;
		p.DimDr1 = row.Item;
		p.DimDr2 = row.Department;
		GeneralRecords.Add ( p );
	enddo; 
	
EndProcedure

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.General.Write = true;
	registers.Expenses.Write = true;
	
EndProcedure

#endregion

#endif