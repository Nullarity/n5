#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not Mailboxes.CheckAddresses ( ThisObject, "Receiver" ) ) then
		Cancel = true;
	endif; 
	if ( not Mailboxes.CheckAddresses ( ThisObject, "Cc" ) ) then
		Cancel = true;
	endif; 
	checkTableDescription ( CheckedAttributes );
	
EndProcedure

Procedure checkTableDescription ( CheckedAttributes )
	
	if ( not TableType.IsEmpty () ) then
		CheckedAttributes.Add ( TableDescription );
	endif; 
	
EndProcedure 

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( DeletionMark ) then
		detachIncomingEmail ();
	endif; 
	if ( WriteMode = DocumentWriteMode.Posting ) then
		if ( alreadyPosted () ) then
			Cancel = true;
			return;
		endif; 
	endif; 
	
EndProcedure

Procedure detachIncomingEmail ()
	
	if ( IncomingEmail.IsEmpty () ) then
		return;
	endif; 
	r = InformationRegisters.Replies.CreateRecordManager ();
	r.IncomingEmail = IncomingEmail;
	r.Delete ();
	IncomingEmail = undefined;
	
EndProcedure 

Function alreadyPosted ()
	
	if ( Posted ) then
		Output.EmailAlreadyPosted ();
		return true;
	endif; 
	return false;
	
EndFunction 

Procedure BeforeDelete ( Cancel )
	
	EmailsSrv.Clean ( MessageID, Mailbox );
	
EndProcedure

#endif