#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	// Bug workaround: Tabular section checking process should be done manually.
	// Otherwise, platform 8.3.10.2052 will explicitly add a new row into Compensation
	// tabular section that confuses users.
	CheckedAttributes.Add ( "Compensations" );
	
EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not Documents.Payroll.Post ( env );
	
EndProcedure

#endif