#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	// Bug workaround: Tabular section checking process should be done manually.
	// Otherwise, platform 8.3.10.2052 will explicitly add a new row into Compensation
	// tabular section that confuses users.
	CheckedAttributes.Add ( "Compensations" );
	
EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	if ( wrongAdditions () ) then
		Cancel = true;
		return;
	endif;
	env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not Documents.Payroll.Post ( env );
	
EndProcedure

Function wrongAdditions ()
	
	errors = missedEmployees ();
	if ( errors.Count () = 0 ) then
		return false;
	endif;
	for each row in errors do
		Output.AdditionalCompensationBroken ( , Output.Row ( "Additions", row.row, "Compensation" ), Ref );
	enddo;
	return true;

EndFunction

Function missedEmployees ()
	
	s = "
	|select Additions.LineNumber as Row
	|from Document.Payroll.Additions as Additions
	|	//
	|	// Compensations
	|	//
	|	left join Document.Payroll.Compensations as Compensations
	|	on Compensations.Ref = &Ref
	|	and Compensations.Employee = Additions.Employee
	|	and Compensations.Compensation = Additions.Compensation
	|where Additions.Ref = &Ref
	|and Compensations.Ref is null
	|order by Additions.LineNumber
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	return q.Execute ().Unload ();

EndFunction

#endif