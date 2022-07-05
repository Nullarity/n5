#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	checkVATAccount ( CheckedAttributes );
	DebtsForm.CheckAmount ( ThisObject, CheckedAttributes );
	
EndProcedure

Procedure checkVATAccount ( CheckedAttributes )
	
	if ( Advances ) then
		CheckedAttributes.Add ( "VATAccount" );
		CheckedAttributes.Add ( "ReceivablesVATAccount" );
		CheckedAttributes.Add ( "VATAdvance" );
	endif;

EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not RunDebtsBalances.Post ( env );
	
EndProcedure

#endif