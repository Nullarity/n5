
Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	checkExpiration ( CheckedAttributes );

EndProcedure

Procedure checkExpiration ( CheckedAttributes )
	
	if ( Resolution = Enums.AllowDeny.Allow ) then
		CheckedAttributes.Add ( "Expired" );
	endif;

EndProcedure

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	if ( not checkAccess () ) then
		Cancel = true;
		return;
	endif;
	if ( DeletionMark ) then
		reset ();
	endif;

EndProcedure

Function checkAccess ()
	
	ok = Resolution.IsEmpty ()
	or IsInRole ( Metadata.Roles.RightsEdit )
	or Logins.Admin ()
	or Logins.Agent ();
	if ( ok ) then
		return true;
	endif;
	Output.ResolutionAlreadyIssued ();
	return false;

EndFunction

Procedure reset ()
	
	Organization = undefined;
	Document = undefined;
	Responsible = undefined;
	Resolution = undefined;

EndProcedure
