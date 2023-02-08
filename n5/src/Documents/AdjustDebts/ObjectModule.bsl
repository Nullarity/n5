#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not checkAmount () ) then
		Cancel = true;
		return;
	endif;
	checkAttributes ( CheckedAttributes );
	
EndProcedure

Function checkAmount ()
	
	if ( Amount = Applied ) then
		return true;
	endif;
	Output.AdjustDebtsError ( , "Amount" );
	return false;
	
EndFunction

Procedure checkAttributes ( CheckedAttributes ) 

	if ( Option = Enums.AdjustmentOptions.Customer
		or Option = Enums.AdjustmentOptions.Vendor ) then
		CheckedAttributes.Add ( "Receiver" );
		CheckedAttributes.Add ( "ReceiverContract" );
		CheckedAttributes.Add ( "ReceiverContractFactor" );
		CheckedAttributes.Add ( "ReceiverContractRate" );
		CheckedAttributes.Add ( "ReceiverAccount" );
	else
		CheckedAttributes.Add ( "Account" );
	endif;
	if ( not AmountDifference ) then
		CheckedAttributes.Add ( "Amount" );
	endif;

EndProcedure

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )

	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( DeletionMark ) then
		InvoiceRecords.Delete ( ThisObject );
	endif;

EndProcedure

Procedure OnWrite ( Cancel )

	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( not DeletionMark ) then
		InvoiceRecords.Sync ( ThisObject );
	endif; 

EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not RunAdjustDebts.Post ( env );
	
EndProcedure

#endif
