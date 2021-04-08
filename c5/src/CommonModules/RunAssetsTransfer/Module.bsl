Function Post ( Env ) export
	
	getData ( Env );
	makeLocation ( Env );
	if ( not checkBalances ( Env ) ) then
		return false;
	endif;
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
	
	if ( Env.Type = Type ( "DocumentRef.AssetsTransfer" ) ) then
		Env.Insert ( "FixedAssets", true );
		Env.Insert ( "Register", "FixedAssetsLocation" );
	else
		Env.Insert ( "FixedAssets", false );
		Env.Insert ( "Register", "IntangibleAssetsLocation" );
	endif; 
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Company as Company, Documents.PointInTime as Timestamp,
	|	Documents.Receiver as Receiver, Documents.Accepted as Accepted,
	|	Documents.Sender as Sender, Documents.Responsible as Responsible
	|from Document." + Env.Document + " as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlItems ( Env )
	
	s = "
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Item.Account as Account
	|into Items
	|from Document." + Env.Document + ".Items as Items
	|where Items.Ref = &Ref
	|index by Items.Item
	|;
	|// #Items
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Account as Account
	|from Items as Items
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure makeLocation ( Env )

	table = Env.Items;
	recordset = Env.Registers [ Env.Register ];
	date = Env.Fields.Date;
	employee = Env.Fields.Accepted;
	department = Env.Fields.Receiver;
	for each row in table do
		record = recordset.Add ();
		record.Period = date;
		record.Asset = row.Item;
		record.Department = department;
		record.Employee = employee;
	enddo; 

EndProcedure

Function checkBalances ( Env )

	lockData ( Env );
	getErrors ( Env );
	if ( Env.Errors.Count () = 0 ) then
		return true;
	endif; 
	showErrors ( Env );
	return false;

EndFunction

Procedure lockData ( Env )
	
	table = Env.Items;
	lock = new DataLock ();
	item = lock.Add ( "AccountingRegister.General");
	item.Mode = DataLockMode.Exclusive;
	item.DataSource = table;
	item.UseFromDataSource ( "Account", "Account" );
	item.UseFromDataSource ( "ExtDimension1", "Item" );
	item = lock.Add ( "InformationRegister." + Env.Register );
	item.Mode = DataLockMode.Exclusive;
	item.DataSource = table;
	item.UseFromDataSource ( "Asset", "Item" );
	lock.Lock ();
	
EndProcedure 

Procedure getErrors ( Env )
	
	sqlErrors ( Env );
	fields = Env.Fields;
	q = Env.Q;
	if ( Env.Realtime ) then
		q.SetParameter ( "Timestamp", undefined );
		q.SetParameter ( "Period", undefined );
	else
		stamp = fields.Timestamp;
		q.SetParameter ( "Timestamp", stamp );
		q.SetParameter ( "Period", new Boundary ( stamp, BoundaryType.Excluding ) );
	endif; 
	q.SetParameter ( "Sender", fields.Sender );
	q.SetParameter ( "Responsible", fields.Responsible );
	q.SetParameter ( "Company", fields.Company );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlErrors ( Env )
	
	s = "
	|// #Errors
	|select Items.Item.Description as Item, Items.LineNumber as LineNumber,
	|	case when isnull ( Balances.QuantityBalance, 0 ) = 0 then true else false end as BalanceError,
	|	case when Locations.Department is null then true else false end as LocationError
	|from Items as Items
	|	//
	|	// Balances
	|	//
	|	left join AccountingRegister.General.Balance ( &Timestamp, Account in ( select distinct Account from Items ), , 
	|		ExtDimension1 in ( select Item from Items ) and Company = &Company ) as Balances
	|	on Items.Account = Balances.Account 
	|	and Items.Item = Balances.ExtDimension1
	|	//
	|	// Locations
	|	//
	|	left join InformationRegister." + Env.Register + ".SliceLast ( &Period,
	|		Asset in ( select Item from Items ) ) as Locations
	|	on Locations.Asset = Items.Item
	|	and Locations.Department = &Sender
	|	and Locations.Employee = &Responsible
	|where isnull ( Balances.QuantityBalance, 0 ) = 0
	|or Locations.Department is null
	|order by LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure showErrors ( Env )
	
	sender = Env.Fields.Sender;
	for each row in Env.Errors do
		if ( row.BalanceError ) then
			msg = Posting.Msg ( Env, "Item" );
			msg.Item = row.Item;
			Output.AssetBalanceError ( msg, Output.Row ( "Items", row.LineNumber, "Item" ), Env.Ref );
		elsif ( row.LocationError ) then
			msg = Posting.Msg ( Env, "Item, Department" );
			msg.Item = row.Item;
			msg.Department = sender;
			Output.AssetWrongLocation ( msg, Output.Row ( "Items", row.LineNumber, "Item" ), Env.Ref );
		endif; 
	enddo; 
	
EndProcedure 

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers [ Env.Register ].Write = true;
	
EndProcedure
