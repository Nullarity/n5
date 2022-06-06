Function Post ( Env ) export
	
	getData ( Env );
	makeAssets ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )

	setContext ( Env );
	sqlFields ( Env );
	getFields ( Env );
	sqlItems ( Env );
	sqlAssets ( Env );
	getTables ( Env );
	
EndProcedure

Procedure setContext ( Env )
	
	if ( Env.Type = Type ( "DocumentRef.AssetsBalances" ) ) then
		Env.Insert ( "FixedAssets", true );
	else
		Env.Insert ( "FixedAssets", false );
	endif; 
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select dateadd ( Documents.Date, second, - 1 ) as Date, Documents.Company as Company,
	|	Documents.Department as Department, Documents.Employee as Employee
	|from Document." +  Env.Document + " as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure sqlItems ( Env )
	
	s = "
	|select Items.InitialCost as InitialCost, Items.Depreciation as Depreciation, Items.Date as Date
	|";
	if ( Env.FixedAssets ) then
		s = s + ",
		|	Items.FixedAsset as Asset, Items.FixedAsset.Account as AssetAccount, Items.FixedAsset.DepreciationAccount as DepreciationAccount,
		|	Items.LiquidationValue as LiquidationValue, Items.Schedule as Schedule
		|";
	else
		s = s + ",
		|	Items.IntangibleAsset as Asset, Items.IntangibleAsset.Account as AssetAccount,
		|	Items.IntangibleAsset.AmortizationAccount as DepreciationAccount
		|";
	endif; 
	s = s + ",
	|	Items.Method as Method, Items.Acceleration as Acceleration, Items.Charge as Charge, Items.Expenses as Expenses,
	|	Items.Starting as Starting, Items.UsefulLife as UsefulLife,
	|	&Department as Department, &Employee as Employee
	|into Items
	|from Document." + Env.Document + ".Items as Items
	|where Items.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlAssets ( Env )
	
	s = "
	|// #Assets
	|select Items.Asset as Asset, Items.Department as Department, Items.Employee as Employee, Items.InitialCost as InitialCost,
	|	Items.Acceleration as Acceleration, Items.Charge as Charge, Items.Expenses as Expenses, Items.Depreciation as Depreciation,
	|	Items.Method as Method, Items.Starting as Starting, Items.UsefulLife as UsefulLife, Items.AssetAccount as AssetAccount,
	|	Items.DepreciationAccount as DepreciationAccount, Items.Date as Date
	|";
	if ( Env.FixedAssets ) then
		s = s + ",
		|Items.LiquidationValue as LiquidationValue, Items.Schedule as Schedule";
	endif; 
	s = s + "
	|from Items as Items
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables ( Env )
	
	fields = Env.Fields;
	q = Env.Q;
	q.SetParameter ( "Department", fields.Department );
	q.SetParameter ( "Employee", fields.Employee );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure makeAssets ( Env )
	
	makeDepreciation ( Env );
	makeLocation ( Env );
	makeBalances ( Env );
	makeCommissioning ( Env );
	
EndProcedure

Procedure makeDepreciation ( Env )
	
	tangible = Env.FixedAssets;
	if ( tangible ) then
		recordset = Env.Registers.Depreciation;
	else
		recordset = Env.Registers.Amortization;
	endif; 
	date = Env.Fields.Date;
	for each row in Env.Assets do
		movement = recordset.Add ();
		movement.Period = date;
		movement.Asset = row.Asset;
		movement.Acceleration = row.Acceleration;
		movement.Charge = row.Charge;
		movement.Expenses = row.Expenses;
		movement.Method = row.Method;
		movement.Starting = row.Starting;
		movement.UsefulLife = row.UsefulLife;
		if ( tangible ) then
			movement.LiquidationValue = row.LiquidationValue;
			movement.Schedule = row.Schedule;
		endif; 
	enddo; 
	
EndProcedure

Procedure makeLocation ( Env )
	
	if ( Env.FixedAssets ) then
		recordset = Env.Registers.FixedAssetsLocation;
	else
		recordset = Env.Registers.IntangibleAssetsLocation;
	endif;
	date = Env.Fields.Date;
	for each row in Env.Assets do
		movement = recordset.Add ();
		movement.Period = date;
		movement.Asset = row.Asset;
		movement.Department = row.Department;
		movement.Employee = row.Employee;
	enddo; 
	
EndProcedure

Procedure makeBalances ( Env )
	
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Content = Output.OpeningBalances ();
	p.Recordset = Env.Registers.General;
	p.QuantityDr = 1;
	table = Env.Assets.Copy ();
	table.GroupBy ( "Asset, AssetAccount, DepreciationAccount", "Depreciation, InitialCost" );
	for each row in table do
		p.Amount = row.InitialCost;
		p.AccountDr = row.AssetAccount;
		asset = row.Asset;
		p.DimDr1 = asset;
		p.AccountCr = ChartsOfAccounts.General._0;
		GeneralRecords.Add ( p );
		depreciation = row.Depreciation;
		if ( depreciation = 0 ) then
			continue;
		endif;
		p.Amount = depreciation;
		p.AccountDr = ChartsOfAccounts.General._0;
		p.DimDr1 = undefined;
		p.AccountCr = row.DepreciationAccount;
		p.DimCr1 = asset;
		GeneralRecords.Add ( p );
	enddo; 
	
EndProcedure

Procedure makeCommissioning ( Env )
	
	if ( Env.FixedAssets ) then
		recordset = Env.Registers.Commissioning;
	else
		recordset = Env.Registers.IntangibleAssetsCommissioning;
	endif;
	for each row in Env.Assets do
		movement = recordset.Add ();
		movement.Asset = row.Asset;
		movement.Date = row.Date;
	enddo; 
	
EndProcedure

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.General.Write = true;
	if ( Env.FixedAssets ) then
		registers.Depreciation.Write = true;
		registers.FixedAssetsLocation.Write = true;
		registers.Commissioning.Write = true;
	else
		registers.Amortization.Write = true;
		registers.IntangibleAssetsCommissioning.Write = true;
	endif; 
	
EndProcedure
