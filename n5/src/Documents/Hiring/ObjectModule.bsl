#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not HiringForm.CheckDoubles ( ThisObject ) ) then
		Cancel = true;
		return;
	endif; 
	
EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not Documents.Hiring.Post ( env );
	
EndProcedure

#endif