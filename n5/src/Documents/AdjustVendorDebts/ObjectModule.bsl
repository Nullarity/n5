#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	AdjustDebtsForm.FillCheckProcessing ( ThisObject, Cancel, CheckedAttributes );
	
EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not RunAdjustDebts.Post ( env );
	
EndProcedure

#endif