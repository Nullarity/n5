#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not Documents.YearClose.Post ( env );
	
EndProcedure

#endif