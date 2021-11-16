#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not checkAmount () ) then
		Cancel = true;
		return;
	endif;
	PaymentForm.Check ( ThisObject, Cancel, CheckedAttributes );
	
EndProcedure

Function checkAmount ()
	
	if ( Amount = Applied ) then
		return true;
	endif;
	Output.CustomerPaymentError ( , "Amount" );
	return false;
	
EndFunction

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	resetAction ();
	
EndProcedure

Procedure resetAction ()
	
	if ( not Action.IsEmpty () ) then
		Action = undefined;
	endif; 
	
EndProcedure 

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	PettyCash.Sync ( ThisObject );
	
EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not RunPayments.Post ( env );
	
EndProcedure

#endif