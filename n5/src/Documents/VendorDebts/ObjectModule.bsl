#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	DebtsForm.FillCheckProcessing ( ThisObject, Cancel, CheckedAttributes );
	
EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not RunDebtsBalances.Post ( env );
	
EndProcedure

#endif