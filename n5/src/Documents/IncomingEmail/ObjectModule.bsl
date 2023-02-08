#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var IsNew;

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	IsNew = IsNew ();
	
EndProcedure

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( DeletionMark ) then
		Documents.IncomingEmail.MarkAsRead ( Ref );
	else
		MailboxesSrv.AttachLabels ( Ref, IsNew, getLabel (), Mailbox );
		if ( IsNew ) then
			Documents.IncomingEmail.MarkAsNew ( Ref );
		endif; 
	endif; 
	
EndProcedure

Function getLabel ()
	
	if ( IsNew ) then
		return Catalogs.MailLabels.EmptyRef ();
	else
		return MailboxesSrv.GetLabel ( Ref );
	endif; 
	
EndFunction 

Procedure BeforeDelete ( Cancel )
	
	EmailsSrv.Clean ( MessageID, Mailbox );
	
EndProcedure

#endif