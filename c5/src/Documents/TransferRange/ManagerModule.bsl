#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Date" );
	Fields.Add ( "Range" );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Metadata.Documents.TransferRange.Synonym
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
	|select Documents.Date as Date, Documents.Range as Range, Documents.Sender as Sender,
	|	Documents.Receiver as Receiver, Documents.PointInTime as Timestamp
	|from Document.TransferRange as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Function make ( Env )
	
	lock ( Env );
	ref = Env.Ref;
	fields = Env.Fields;
	range = fields.Range;
	if ( wrongSender ( Env ) ) then
		OutputCont.RangeNotFound ( new Structure ( "Range, Warehouse", range, fields.Sender ), "Range", ref );
		return false;
	endif;
	movement = Env.Registers.RangeLocations.Add ();
	movement.Period = fields.Date;
	movement.Range = range;
	movement.Warehouse = fields.Receiver;
	return true;
	
EndFunction

Procedure lock ( Env )
	
	lock = new DataLock ();
	item = lock.Add ( "InformationRegister.RangeLocations" );
	item.Mode = DataLockMode.Exclusive;
	item.SetValue ( "Range", Env.Fields.Range );
	lock.Lock ();
	
EndProcedure

Function wrongSender ( Env )
	
	s = "
	|select 1
	|from InformationRegister.RangeLocations.SliceLast ( &Period, Range = &Range ) as Ranges
	|	//
	|	// Statuses
	|	//
	|	join InformationRegister.RangeStatuses.SliceLast ( &Period, Range = &Range ) as Statuses
	|	on Statuses.Status = value ( Enum.RangeStatuses.Active )
	|where Ranges.Warehouse = &Sender
	|";
	q = new Query ( s );
	fields = Env.Fields;
	period = ? ( Env.Realtime, undefined, new Boundary ( fields.Timestamp, BoundaryType.Excluding ) );
	q.SetParameter ( "Period", period );
	q.SetParameter ( "Range", fields.Range );
	q.SetParameter ( "Sender", fields.Sender );
	return q.Execute ().IsEmpty ();
	
EndFunction

Procedure flagRegisters ( Env )
	
	Env.Registers.RangeLocations.Write = true;
	
EndProcedure

#endregion

#endif
