Procedure SqlData ( Env ) export
	
	s = "
	|select Goods.LineNumber as LineNumber, Goods.Range as Range
	|into Ranges
	|from Items as Goods
	|where Goods.Range <> value ( Catalog.Ranges.EmptyRef )
	|index by Range
	|;
	|// #RangeErrors
	|select 1 as Error, Items.LineNumber as LineNumber
	|from Items as Items
	|where Items.Range = value ( Catalog.Ranges.EmptyRef )
	|and Items.Item.Form
	|union all
	|select 2, min ( Items.LineNumber )
	|from Items as Items
	|	//
	|	// Doubles
	|	//
	|	join Items as Doubles
	|	on Doubles.Range = Items.Range
	|	and Doubles.LineNumber <> Items.LineNumber
	|where Items.Range <> value ( Catalog.Ranges.EmptyRef )
	|group by Items.Range
	|";
	type = TypeOf ( Env.Ref );
	if ( type = Type ( "DocumentRef.VendorInvoice" )
		or type = Type ( "DocumentRef.ItemBalances" ) ) then
		s = s + "
		|union all
		|select 3, Items.LineNumber
		|from Items as Items
		|where Items.Range <> value ( Catalog.Ranges.EmptyRef )
		|and Items.Quantity <> ( 1 + Items.Range.Finish - Items.Range.Start )
		|";
	endif;
	s = s + "
	|;
	|// #RangeList
	|select Ranges.Range as Range
	|from Ranges as Ranges
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Function Check ( Env ) export
	
	table = Env.RangeErrors;
	if ( table.Count () = 0 ) then
		return true;
	endif;
	ref = Env.Ref;
	qty = ? ( Options.Packages (), "QuantityPkg", "Quantity" );
	for each row in table do
		if ( row.Error = 1 ) then
			field = Output.Row ( "Items", row.LineNumber, "Item" );
			Output.RangeIsEmpty ( , field, ref );
		elsif ( row.Error = 2 ) then
			field = Output.Row ( "Items", row.LineNumber, "Item" );
			Output.RangeDoubled ( , field, ref );
		elsif ( row.Error = 3 ) then
			field = Output.Row ( "Items", row.LineNumber, qty );
			Output.RangeIncomplete ( , field, ref );
		endif;
	enddo;
	return false;
	
EndFunction

Function MakeReceipt ( Env ) export

	RunRanges.Lock ( Env );
	table = getRanges ( Env );
	locations = Env.Registers.RangeLocations;
	statuses = Env.Registers.RangeStatuses;
	ref = Env.Ref;
	date = Env.Fields.Date;
	error = false;
	for each row in table do
		if ( row.AlreadyInUse ) then
			error = true;
			p = new Structure ( "Range", row.Range );
			field = Output.Row ( "Items", row.LineNumber, "Item" );
			Output.RangeAlreadyInUse ( p, field, ref );
		else
			range = row.Range;
			movement = locations.Add ();
			movement.Period = date;
			movement.Range = range;
			movement.Warehouse = row.Warehouse;
			movement = statuses.Add ();
			movement.Period = date;
			movement.Range = range;
			movement.Status = Enums.RangeStatuses.Active;
		endif;
	enddo; 
	return not error;
	
EndFunction

Procedure Lock ( Env ) export
	
	table = Env.RangeList;
	lock = new DataLock ();
	item = lock.Add ( "InformationRegister.RangeStatuses" );
	item.Mode = DataLockMode.Exclusive;
	item.DataSource = table;
	item.UseFromDataSource ( "Range", "Range" );
	type = TypeOf ( Env.Ref );
	if ( type = Type ( "DocumentRef.WriteOff" )
		or type = Type ( "DocumentRef.Transfer" ) ) then
		item = lock.Add ( "InformationRegister.Ranges" );
		item.Mode = DataLockMode.Exclusive;
		item.DataSource = table;
		item.UseFromDataSource ( "Range", "Range" );
		item = lock.Add ( "InformationRegister.RangeLocations" );
		item.Mode = DataLockMode.Exclusive;
		item.DataSource = table;
		item.UseFromDataSource ( "Range", "Range" );
	endif;
	lock.Lock ();
	
EndProcedure

Function getRanges ( Env )
	
	s = "
	|// #Ranges
	|select Ranges.LineNumber as LineNumber, Ranges.Range as Range, Ranges.Warehouse,
	|	case when Statuses.Status is null then false else true end as AlreadyInUse
	|from Items as Ranges
	|	//
	|	// Statuses
	|	//
	|	left join InformationRegister.RangeStatuses.SliceLast ( &Period,
	|		Range in ( select Range from Ranges ) ) as Statuses
	|	on Statuses.Range = Ranges.Range
	|where Ranges.Range <> value ( Catalog.Ranges.EmptyRef )
	|";
	Env.Selection.Add ( s );
	SQL.Prepare ( Env );
	period = ? ( Env.Realtime, undefined, new Boundary ( Env.Fields.Timestamp, BoundaryType.Excluding ) );
	q = Env.Q;
	q.SetParameter ( "Period", period );
	return q.Execute ().Unload ();
	
EndFunction
