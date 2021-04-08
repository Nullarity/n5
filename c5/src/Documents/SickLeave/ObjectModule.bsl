#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not checkPeriod () ) then
		Cancel = true;
		return;
	endif; 
	
EndProcedure

Function checkPeriod ()
	
	if ( not Periods.Ok ( DateStart, DateEnd ) ) then
		Output.PeriodError ( , "DateEnd" );
		return false;
	endif;
	return true;
	
EndFunction

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	if ( not DeletionMark ) 
		and ( alreadySick () ) then
		Cancel = true;	
	endif;	
	
EndProcedure

Function alreadySick ()
	
	s = "
	|select top 1 SickLeaves.Ref as Ref
	|from Document.SickLeave as SickLeaves
	|where SickLeaves.Employee = &Employee
	|and ( SickLeaves.DateStart between &DateStart and &DateEnd
	|	or SickLeaves.DateEnd between &DateStart and &DateEnd )
	|and SickLeaves.Ref <> &Ref
	|and not SickLeaves.DeletionMark
	|order by SickLeaves.Date
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	q.SetParameter ( "Employee", Employee );
	q.SetParameter ( "DateStart", DateStart );
	q.SetParameter ( "DateEnd", DateEnd );
	table = q.Execute ().Unload ();
	if ( table.Count () = 0 ) then
		return false;
	endif;
	document = table [ 0 ].Ref;
	OutputCont.EmployeeAlreadySick ( new Structure ( "Ref", document ), , document );
	return true;
	
EndFunction

#endif