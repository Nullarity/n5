#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
var UseReceiver;

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	setUseReceiver ();
	if ( not checkAmount () ) then
		Cancel = true;
		return;
	endif;
	checkAttributes ( CheckedAttributes );
	
EndProcedure

Procedure setUseReceiver () 

	adjustmentOptions = Enums.AdjustmentOptions;
	UseReceiver = ( Option = adjustmentOptions.Customer
	or Option = adjustmentOptions.Vendor );

EndProcedure

Function checkAmount ()
	
	if ( Amount = Applied ) then
		return true;
	endif;
	Output.AdjustDebtsError ( , "Amount" );
	return false;
	
EndFunction

Procedure checkAttributes ( CheckedAttributes ) 

	if ( UseReceiver ) then
		CheckedAttributes.Add ( "Receiver" );
		CheckedAttributes.Add ( "ReceiverContract" );
		CheckedAttributes.Add ( "ReceiverContractFactor" );
		CheckedAttributes.Add ( "ReceiverContractRate" );
		CheckedAttributes.Add ( "ReceiverAccount" );
	else
		CheckedAttributes.Add ( "Account" );
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

	if ( not DeletionMark ) then
		InvoiceRecords.Sync ( ThisObject );
	endif; 

EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not RunAdjustDebts.Post ( env );
	
EndProcedure

#endif
