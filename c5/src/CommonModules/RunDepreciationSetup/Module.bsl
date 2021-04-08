Function Post ( Env ) export
	
	getData ( Env );
	makeDepreciation ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )

	setContext ( Env );
	sqlFields ( Env );
	sqlItems ( Env );
	getFields ( Env );
	
EndProcedure

Procedure setContext ( Env )
	
	if ( Env.Type = Type ( "DocumentRef.DepreciationSetup" ) ) then
		Env.Insert ( "FixedAssets", true );
		Env.Insert ( "Register", "Depreciation" );
	else
		Env.Insert ( "FixedAssets", false );
		Env.Insert ( "Register", "Amortization" );
	endif; 
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.PointInTime as Timestamp
	|from Document." + Env.Document + " as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlItems ( Env )
	
	s = "
	|// #Items
	|select Items.Item as Item
	|from Document." + Env.Document + ".Items as Items
	|where Items.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure makeDepreciation ( Env )

	lockDepreciation ( Env );
	getDepreciation ( Env );
	saveDepreciation ( Env );

EndProcedure

Procedure lockDepreciation ( Env )
	
	lock = new DataLock ();
	item = lock.Add ( "InformationRegister." + Env.Register );
	item.Mode = DataLockMode.Exclusive;
	item.DataSource = Env.Items;
	item.UseFromDataSource ( "Asset", "Item" );
	lock.Lock ();
	
EndProcedure 

Procedure getDepreciation ( Env )
	
	sqlDeprecation ( Env );
	q = Env.Q;
	if ( Env.Realtime ) then
		q.SetParameter ( "Period", undefined );
	else
		q.SetParameter ( "Period", new Boundary ( Env.Fields.Timestamp, BoundaryType.Excluding ) );
	endif; 
	SQL.Perform ( Env );
	
EndProcedure 

Procedure sqlDeprecation ( Env )
	
	name = Env.Document;
	s = "
	|// #Deprecation
	|select Items.Item as Item,
	|	case when Items.Ref.ExpensesChange then Items.Ref.Expenses else Depreciation.Expenses end as Expenses,
	|	case when Items.Ref.UsefulLifeChange then Items.Ref.UsefulLife else Depreciation.UsefulLife end as UsefulLife,
	|	case when Items.Ref.MethodChange then Items.Ref.Acceleration else Depreciation.Acceleration end as Acceleration,
	|	case when Items.Ref.MethodChange then Items.Ref.Method else Depreciation.Method end as Method,
	|	Depreciation.Starting as Starting";
	if ( Env.FixedAssets ) then
		s = s + ",
		|	case when Items.Ref.MethodChange then Items.Ref.Schedule else Depreciation.Schedule end as Schedule,
		|	case when Items.Ref.MethodChange then Items.Ref.LiquidationValue else Depreciation.LiquidationValue end as LiquidationValue
		|";
	endif; 
	s = s + ",
	|	case Items.Ref.Charge
	|		when 0 then Depreciation.Charge
	|		when 1 then true
	|		else false
	|	end as Charge
	|from Document." + name + ".Items as Items
	|	//
	|	// Details
	|	//
	|	left join InformationRegister." + Env.Register + ".SliceLast ( &Period, 
	|		Asset in ( select Item from Document." + name + ".Items where Ref = &Ref ) ) as Depreciation
	|	on Depreciation.Asset = Items.Item
	|where Items.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure saveDepreciation ( Env )

	tangible = Env.FixedAssets;
	recordset = Env.Registers [ Env.Register ];
	date = Env.Fields.Date;
	for each row in Env.Deprecation do
		movement = recordset.Add ();
		movement.Period = date;
		movement.Asset = row.Item;
		movement.Acceleration = row.Acceleration;
		movement.Charge = row.Charge;
		movement.Expenses = row.Expenses;
		movement.Method = row.Method;
		movement.Starting = row.Starting;
		movement.UsefulLife = row.UsefulLife;
		if ( tangible ) then
			movement.Schedule = row.Schedule;
			movement.LiquidationValue = row.LiquidationValue;
		endif; 
	enddo; 

EndProcedure

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers [ Env.Register ].Write = true;
	
EndProcedure
