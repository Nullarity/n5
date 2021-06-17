#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Date" );
	Fields.Add ( "Number" );
	
EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Metadata.Documents.LVITransfer.Synonym + " #" + Data.Number + " " + Format ( Data.Date, "DLF=D" );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	if ( not makeValues ( Env ) ) then
		return false;
	endif;
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )

	sqlFields ( Env );
	getFields ( Env );
	sqlItems ( Env );
	getItems ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Document.Date as Date, Document.Company as Company, Document.PointInTime as Timestamp
	|from Document.LVITransfer as Document
	|where Document.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure sqlItems ( Env )
	
	s = "
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Employee.Individual as Employee, Items.EmployeeReceiver.Individual as EmployeeReceiver,
	|	Items.Quantity as Quantity, Items.Account as Account, Items.Department as Department, Items.DepartmentReceiver as DepartmentReceiver,
	|	case when Items.Item.CountPackages then Items.Capacity else 1 end as Capacity,
	|	case when Items.Item.CountPackages then Items.Package.Description else Items.Item.Unit.Code end as Unit,
	|	case when Items.Item.CountPackages then Items.QuantityPkg else Items.Quantity end as QuantityPkg,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package
	|into Items
	|from Document.LVITransfer.Items as Items
	|where Items.Ref = &Ref
	|index by Items.Item
	|;
	|select Items.Item as Item, Sum ( Items.Quantity ) as Quantity, Items.Account as Account, Items.Department as Department,
	|	Items.DepartmentReceiver as DepartmentReceiver, Items.Employee as Employee, Items.EmployeeReceiver as EmployeeReceiver
	|into ItemsGrouped
	|from Items as Items
	|group by Items.Item, Items.Account, Items.Department, Items.DepartmentReceiver, Items.Employee, Items.EmployeeReceiver
	|;
	|// ^Items
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Employee as Employee, Items.EmployeeReceiver as EmployeeReceiver,
	|	Items.Quantity as Quantity, Items.Account as Account, Items.Department as Department, Items.DepartmentReceiver as DepartmentReceiver,
	|	Items.Capacity as Capacity, Items.Unit as Unit,Items.QuantityPkg as QuantityPkg,Items.Package as Package
	|from Items as Items
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure getItems ( Env )
	
	SQL.Perform ( Env );
	
EndProcedure 

Function makeValues ( Env )

	lockCost ( Env );
	cost = undefined;
	if ( not calcCost ( Env, cost ) ) then
		return false;
	endif;
	commitCost ( Env, cost );
	return true;

EndFunction

Procedure lockCost ( Env )
	
	table = SQL.Fetch ( Env, "$Items" );
	if ( table.Count () > 0 ) then
		lock = new DataLock ();
		item = lock.Add ( "AccountingRegister.General");
		item.Mode = DataLockMode.Exclusive;
		item.DataSource = table;
		item.UseFromDataSource ( "Account", "Account" );
		dims = ChartsOfCharacteristicTypes.Dimensions;
		item.UseFromDataSource ( dims.Items, "Item" );
		item.UseFromDataSource ( dims.Departments, "Department" );
		item.UseFromDataSource ( dims.Employees, "Employee" );
		lock.Lock ();
	endif;
	
EndProcedure

Function calcCost ( Env, Cost )
	
	table = SQL.Fetch ( Env, "$Items" );
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
	q = Env.Q;
	q.SetParameter ( "Timestamp", ? ( Env.Realtime, undefined, Env.Fields.Timestamp ) );
	cost = q.Execute ().Unload ();
	p = new Structure ();
	p.Insert ( "FilterColumns", "Item, Department, Account, Employee" );
	p.Insert ( "KeyColumn", "Quantity" );
	p.Insert ( "KeyColumnAvailable", "QuantityBalance" );
	p.Insert ( "AddInTable1FromTable2", "DepartmentReceiver, Capacity, EmployeeReceiver" );
	return CollectionsSrv.Decrease ( cost, Items, p );
	
EndFunction 

Procedure sqlCost ( Env )
	
	s = "
	|select Balances.QuantityBalance as Quantity,
	|	Items.Item as Item, Items.Department as Department, Balances.AmountBalance as Amount,
	|	Items.Account as Account, Items.Employee
	|from AccountingRegister.General.Balance(&Timestamp, Account in ( select Account from ItemsGrouped ), , 
	|	(ExtDimension1, ExtDimension2, ExtDimension3) in ( select Item, Department, Employee from ItemsGrouped ) ) as Balances
	|	//
	|	// Items
	|	//
	|	left join ItemsGrouped as Items
	|	on Items.Item = Balances.ExtDimension1
	|	and Items.Department = Balances.ExtDimension2
	|	and Items.Employee = Balances.ExtDimension3
	|	and Balances.QuantityBalance > 0
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure completeCost ( Env, Cost, Items )
	
	column = ? ( Options.Packages (), "QuantityPkg", "Quantity" );
	msg = Posting.Msg ( Env, "Item, QuantityBalance, Quantity, Department, Employee" );
	ref = Env.Ref;
	for each row in Items do
		costRow = Cost.Add ();
		FillPropertyValues ( costRow, row );
		msg.Item = row.Item;
		msg.Department = row.Department;
		msg.Employee = row.Employee;
		quantityBalance = row.QuantityBalance;
		unit = row.Unit;
		msg.QuantityBalance = Conversion.NumberToQuantity ( quantityBalance, unit );
		msg.Quantity = Conversion.NumberToQuantity ( row.Quantity - quantityBalance, unit );
		Output.LVIBalanceError ( msg, Output.Row ( "Items", row.LineNumber, column ), ref );
	enddo; 
		
EndProcedure 

Procedure commitCost ( Env, Table )
	
	if ( Env.RestoreCost ) then
		cleanCost ( Env );
	endif;
	groupColumns = "Item, Account, Department, DepartmentReceiver, Employee, EmployeeReceiver, Capacity";
	sumColumns = "Quantity, Amount";
	items = Table.Copy ( , groupColumns + ", " + sumColumns );
	items.GroupBy ( groupColumns, sumColumns );
	p = GeneralRecords.GetParams ();
	p.Date = Env.Fields.Date;
	p.Company = Env.Fields.Company;
	p.Operation = Enums.Operations.LVITransfer;
	p.DimDr1Type = "Items";
	p.DimDr2Type = "Departments";
	p.DimDr3Type = "Employees";
	p.Recordset = Env.Registers.General;
	for each row in items do
		quantity = row.Quantity * row.Capacity;
		item = row.Item;
		p.AccountDr = row.Account;
		p.AccountCr = row.Account;
		p.QuantityDr = quantity;
		p.QuantityCr = quantity;
		p.Amount =  row.Amount;
		p.DimDr1 = item;
		p.DimDr2 = row.DepartmentReceiver;
		p.DimDr3 = row.EmployeeReceiver;
		p.DimCr1 = item;
		p.DimCr2 = row.Department;
		p.DimCr3 = row.Employee;
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

Procedure flagRegisters ( Env )
	
	Env.Registers.General.Write = true;
	
EndProcedure

#endregion

#endif