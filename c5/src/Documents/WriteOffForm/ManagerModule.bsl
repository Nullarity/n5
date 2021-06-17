#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Base" );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Metadata.Documents.WriteOffForm.Synonym
	+ " "
	+ Data.Base;
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	fields = Env.Fields;
	if ( not Env.RestoreCost ) then
		makeItems ( Env );
		finishRange ( Env );
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
	q = Env.Q;
	q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	fields = Env.Fields;
	company = fields.Company;
	Env.Insert ( "CostOnline", Options.CostOnline ( company ) );
	Env.Insert ( "CheckBalances", Shortage.Check ( company, Env.Realtime, Env.RestoreCost ) );
	q.SetParameter ( "Timestamp", ? ( Env.Realtime, undefined, fields.Timestamp ) );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Warehouse as Warehouse, Documents.Company as Company,
	|	Documents.PointInTime as Timestamp, Documents.Item as Item, Documents.Feature as Feature,
	|	Documents.Series as Series, Documents.ExpenseAccount as ExpenseAccount,
	|	Documents.Dim1 as Dim1, Documents.Dim2 as Dim2, Documents.Dim3 as Dim3,
	|	Documents.Product as Product, Documents.ProductFeature as ProductFeature,
	|	Documents.Account as Account, Documents.Base as Base, Documents.Range as Range, Documents.Range.Finish as Finish,
	|	Documents.Base.FormNumber as RangeNumber, Details.ItemKey as ItemKey
	|from Document.WriteOffForm as Documents
	|	//
	|	// Details
	|	//
	|	left join InformationRegister.ItemDetails as Details
	|	on Details.Item = Documents.Item
	|	and Details.Package = value ( Catalog.Packages.EmptyRef )
	|	and Details.Feature = Documents.Feature
	|	and Details.Series = Documents.Series
	|	and Details.Warehouse = Documents.Warehouse
	|	and Details.Account = Documents.Account
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure makeItems ( Env )

	fields = Env.Fields;
	recordset = Env.Registers.Items;
	movement = recordset.AddExpense ();
	movement.Period = fields.Date;
	movement.Item = fields.Item;
	movement.Feature = fields.Feature;
	movement.Warehouse = fields.Warehouse;
	movement.Quantity = 1;
	
EndProcedure

Procedure finishRange ( Env )
	
	fields = Env.Fields;
	if ( fields.RangeNumber = fields.Finish ) then
		movement = Env.Registers.RangeStatuses.Add ();
		movement.Period = fields.Date;
		movement.Range = fields.Range;
		movement.Status = Enums.RangeStatuses.Finished;
	endif;
	
EndProcedure

Function makeValues ( Env )

	lockCost ( Env );
	cost = getCost ( Env );
	if ( cost = undefined ) then
		showError ( Env );
		if ( Env.RestoreCost
			or Env.CheckBalances ) then
			return false;
		endif; 
	endif; 
	makeCost ( Env, cost );
	makeExpenses ( Env, cost );
	commitCost ( Env, cost );
	setCostBound ( Env );
	return true;

EndFunction

Procedure lockCost ( Env )
	
	itemKey = Env.Fields.ItemKey;
	if ( itemKey = null ) then
		return;
	endif;
	lock = new DataLock ();
	item = lock.Add ( "AccumulationRegister.Cost");
	item.Mode = DataLockMode.Exclusive;
	item.SetValue ( "ItemKey", itemKey );
	lock.Lock ();
	
EndProcedure

Function getCost ( Env )
	
	s = "
	|select top 1 Balances.Lot as Lot, Balances.QuantityBalance as Quantity,
	|	case Balances.QuantityBalance when 1 then Balances.AmountBalance else Balances.AmountBalance / Balances.QuantityBalance end as Cost
	|from AccumulationRegister.Cost.Balance ( &Timestamp, ItemKey = &ItemKey ) as Balances
	|where Balances.QuantityBalance >= 1
	|order by Balances.Lot.Date
	|";
	q = new Query ( s );
	fields = Env.Fields;
	q.SetParameter ( "TimeStamp", fields.TimeStamp );
	q.SetParameter ( "ItemKey", fields.ItemKey );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ] );
	
EndFunction

Procedure showError ( Env )
	
	msg = Posting.Msg ( Env, "Warehouse, Item" );
	fields = Env.Fields;
	msg.Item = fields.Item;
	msg.Warehouse = fields.Warehouse;
	Output.FormCostBalanceError ( msg, "Range", fields.Base );
		
EndProcedure 

Procedure makeCost ( Env, Cost )
	
	fields = Env.Fields;
	recordset = Env.Registers.Cost;
	movement = recordset.AddExpense ();
	movement.Period = fields.Date;
	movement.Quantity = 1;
	if ( Cost = undefined ) then
		if ( fields.ItemKey = null ) then
			fields.ItemKey = ItemDetails.GetKey ( Env, fields.Item, , fields.Feature, fields.Series, fields.Warehouse, fields.Account );
		endif; 
	else
		movement.Lot = Cost.Lot;
		movement.Amount = Cost.Cost;
	endif;
	movement.ItemKey = fields.ItemKey;
	
EndProcedure

Procedure makeExpenses ( Env, Cost )
	
	fields = Env.Fields;
	recordset = Env.Registers.Expenses;
	movement = recordset.Add ();
	movement.Period = fields.Date;
	movement.Document = Env.Ref;
	movement.ItemKey = fields.ItemKey;
	movement.Account = fields.ExpenseAccount;
	movement.Expense = findDimension ( fields, Type ( "CatalogRef.Expenses" ) );
	movement.Department = findDimension ( fields, Type ( "CatalogRef.Departments" ) );
	movement.Product = fields.Product;
	movement.ProductFeature = fields.ProductFeature;
	movement.AmountDr = Cost.Cost;
	movement.QuantityDr = 1;
	
EndProcedure

Function findDimension ( Fields, Type )
	
	value = Fields.Dim1;
	if ( TypeOf ( value ) = Type ) then
		return value;
	endif;
	value = Fields.Dim2;
	if ( TypeOf ( value ) = Type ) then
		return value;
	endif;
	value = Fields.Dim2;
	if ( TypeOf ( value ) = Type ) then
		return value;
	endif;
	
EndFunction 

Procedure commitCost ( Env, Cost )
	
	if ( Env.RestoreCost ) then
		cleanCost ( Env );
	endif; 
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.AutoWritingOffForm;
	p.DimCr1Type = "Items";
	p.DimCr2Type = "Warehouses";
	p.Recordset = Env.Registers.General;
	p.Amount = Cost.Cost;
	p.AccountCr = fields.Account;
	p.QuantityCr = 1;
	p.DimCr1 = fields.Item;
	p.DimCr2 = fields.Warehouse;
	p.AccountDr = fields.ExpenseAccount;
	p.DimDr1 = fields.Dim1;
	p.DimDr2 = fields.Dim2;
	p.DimDr3 = fields.Dim3;
	GeneralRecords.Add ( p );
	
EndProcedure

Procedure cleanCost ( Env )
	
	recordset = Env.Registers.General;
	recordset.Read ();
	i = recordset.Count () - 1;
	while ( i >= 0 ) do
		if ( recordset [ i ].Operation = Enums.Operations.AutoWritingOffForm ) then
			recordset.Delete ( i );
		endif; 
		i = i - 1;
	enddo; 
	
EndProcedure

Procedure setCostBound ( Env )
	
	if ( Env.RestoreCost ) then
		fields = Env.Fields;
		Sequences.Cost.SetBound ( fields.Timestamp, new Structure ( "Company, Item", fields.Company, fields.Item ) );
	endif; 
	
EndProcedure

Procedure attachSequence ( Env )

	recordset = Sequences.Cost.CreateRecordSet ();
	//@skip-warning
	recordset.Filter.Recorder.Set ( Env.Ref );
	fields = Env.Fields;
	movement = recordset.Add ();
	movement.Period = fields.Date;;
	movement.Company = fields.Company;
	movement.Item = fields.Item;
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
	registers.Expenses.Write = true;
	if ( not Env.RestoreCost ) then
		registers.RangeStatuses.Write = true;
		if ( not Env.CheckBalances ) then
			registers.Items.Write = true;
		endif; 
	endif;
	
EndProcedure

#endregion

#endif
