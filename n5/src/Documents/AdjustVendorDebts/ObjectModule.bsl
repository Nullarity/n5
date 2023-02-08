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
		if ( UseReceiver ) then
			if ( Amount = AppliedReceiver ) then
				return true;
			endif;
		else
			return true;
		endif;
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
		if ( Option = Enums.AdjustmentOptions.Customer ) then
			CheckedAttributes.Add ( "VATAccount" );
			CheckedAttributes.Add ( "ReceivablesVATAccount" );
			CheckedAttributes.Add ( "VATAdvance" );
		endif;
	else
		CheckedAttributes.Add ( "Account" );
	endif;
	if ( not ( Option = Enums.AdjustmentOptions.AccountingDr
			or Option = Enums.AdjustmentOptions.AccountingCr ) ) then
		CheckedAttributes.Add ( "Amount" );
	endif;

EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not RunAdjustDebts.Post ( env );
	
EndProcedure

#endif