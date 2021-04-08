#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Env;

Procedure Posting ( Cancel, PostingMode )
	
	Env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not Documents.Absence.Post ( Env );
	
EndProcedure

#endif