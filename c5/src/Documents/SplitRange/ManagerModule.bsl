#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Date" );
	Fields.Add ( "Range" );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Metadata.Documents.SplitRange.Synonym
	+ " "
	+ Data.Range
	+ ", "
	+ Format ( Data.Date, "DLF=D" );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	lock ( Env );
	if ( not make ( Env ) ) then
		return false;
	endif;
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )

	sqlFields ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Range as Range, Documents.Splitter as Splitter,
	|	Documents.Range1 as Range1, Documents.Range2 as Range2
	|from Document.SplitRange as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure lock ( Env )
	
	lock = new DataLock ();
	item = lock.Add ( "InformationRegister.Ranges" );
	item.Mode = DataLockMode.Exclusive;
	range = Env.Fields.Range;
	item.SetValue ( "Range", range );
	item = lock.Add ( "InformationRegister.RangeStatuses" );
	item.Mode = DataLockMode.Exclusive;
	item.SetValue ( "Range", range );
	item = lock.Add ( "InformationRegister.RangeLocations" );
	item.Mode = DataLockMode.Exclusive;
	item.SetValue ( "Range", range );
	lock.Lock ();
	
EndProcedure

Function make ( Env )
	
	fields = Env.Fields;
	splitter = fields.Splitter;
	data = rangeData ( Env );
	finish = data.Finish;
	last = data.Last;
	if ( ( finish - last ) < 2 ) then
		Output.RangeSplitError1 ( , "Range", Env.Ref );
		return false;
	elsif ( splitter < ( last + 1 )
		or splitter >= finish ) then
		Output.RangeSplitError2 ( , "Splitter", Env.Ref );
		return false;
	elsif ( data.Status <> Enums.RangeStatuses.Active ) then
		Output.RangeSplitError3 ( , "Range", Env.Ref );
		return false;
	endif;
	deactivate ( Env );
	activate ( Env, Data, fields.Range1 );
	activate ( Env, Data, fields.Range2 );
	return true;
	
EndFunction

Function rangeData ( Env )
	
	s = "
	|select Catalog.Finish as Finish, isnull ( Ranges.Last, Catalog.Start - 1 ) as Last,
	|	Statuses.Status as Status, Locations.Warehouse as Warehouse
	|from Catalog.Ranges as Catalog
	|	//
	|	// Ranges
	|	//
	|	left join InformationRegister.Ranges as Ranges
	|	on Ranges.Range = Catalog.Ref
	|	//
	|	// Statuses
	|	//
	|	left join InformationRegister.RangeStatuses.SliceLast ( &Date, Range = &Range ) as Statuses
	|	on true
	|	//
	|	// Locations
	|	//
	|	left join InformationRegister.RangeLocations.SliceLast ( &Date, Range = &Range ) as Locations
	|	on true
	|where Catalog.Ref = &Range
	|";
	q = new Query ( s );
	fields = Env.Fields;
	q.SetParameter ( "Range", fields.Range );
	q.SetParameter ( "Date", fields.Date - 1 );
	return q.Execute ().Unload () [ 0 ];
	
EndFunction

Procedure deactivate ( Env )
	
	fields = Env.Fields;
	movement = Env.Registers.RangeStatuses.Add ();
	movement.Period = fields.Date;
	movement.Range = fields.Range;
	movement.Status = Enums.RangeStatuses.Split;
	
EndProcedure

Procedure activate ( Env, RangeData, Range )
	
	fields = Env.Fields;
	date = fields.Date;
	movement = Env.Registers.RangeLocations.Add ();
	movement.Period = date;
	movement.Range = Range;
	movement.Warehouse = RangeData.Warehouse;
	movement = Env.Registers.RangeStatuses.Add ();
	movement.Period = date;
	movement.Range = Range;
	movement.Status = Enums.RangeStatuses.Active;
	
EndProcedure

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.RangeLocations.Write = true;
	registers.RangeStatuses.Write = true;
	
EndProcedure

#endregion

#endif