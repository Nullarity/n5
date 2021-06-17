#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Date" );
	Fields.Add ( "Range" );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Metadata.Documents.EnrollRange.Synonym
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
	|select Documents.Date as Date, Documents.Range as Range, Documents.Warehouse as Warehouse,
	|	Documents.PointInTime as Timestamp, Documents.Range.Online as RangeOnline
	|from Document.EnrollRange as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Function make ( Env )
	
	lock ( Env );
	ref = Env.Ref;
	if ( rangeInUse ( Env ) ) then
		Output.RangeAlreadyEnrolled ( , "Range", ref );
		return false;
	endif;
	fields = Env.Fields;
	date = fields.Date;
	range = fields.Range;
	if ( not fields.RangeOnline ) then
		locations = Env.Registers.RangeLocations;
		movement = locations.Add ();
		movement.Period = date;
		movement.Range = range;
		movement.Warehouse = fields.Warehouse;
	endif;
	statuses = Env.Registers.RangeStatuses;
	movement = statuses.Add ();
	movement.Period = date;
	movement.Range = range;
	movement.Status = Enums.RangeStatuses.Active;
	return true;
	
EndFunction

Procedure lock ( Env )
	
	lock = new DataLock ();
	item = lock.Add ( "InformationRegister.RangeStatuses" );
	item.Mode = DataLockMode.Exclusive;
	item.SetValue ( "Range", Env.Fields.Range );
	lock.Lock ();
	
EndProcedure

Function rangeInUse ( Env )
	
	s = "
	|select 1
	|from InformationRegister.RangeStatuses.SliceLast ( &Period, Range = &Range )
	|";
	q = new Query ( s );
	period = ? ( Env.Realtime, undefined, new Boundary ( Env.Fields.Timestamp, BoundaryType.Excluding ) );
	q.SetParameter ( "Period", period );
	q.SetParameter ( "Range", Env.Fields.Range );
	return not q.Execute ().IsEmpty ();
	
EndFunction

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.RangeLocations.Write = true;
	registers.RangeStatuses.Write = true;
	
EndProcedure

#endregion

#endif
