#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not Mailboxes.CheckAddresses ( ThisObject, "Email" ) ) then
		Cancel = true;
	endif; 
	if ( not Mailboxes.CheckName ( ThisObject, "Box" ) ) then
		Cancel = true;
	endif; 
	checkLogin ( CheckedAttributes );
	
EndProcedure

Procedure checkLogin ( CheckedAttributes )
	
	if ( Protocol = Enums.Protocols.IMAP ) then
		CheckedAttributes.Add ( "IMAPUser" );
		CheckedAttributes.Add ( "IMAPPassword" );
		CheckedAttributes.Add ( "IMAPServerAddress" );
	elsif ( Protocol = Enums.Protocols.POP3 ) then
		CheckedAttributes.Add ( "POP3User" );
		CheckedAttributes.Add ( "POP3Password" );
		CheckedAttributes.Add ( "POP3ServerAddress" );
	endif; 
	
EndProcedure 

#endif