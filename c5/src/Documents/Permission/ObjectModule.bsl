
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
	if ( DeletionMark ) then
		reset ();
	endif;

EndProcedure

Procedure reset ()
	
	Customer = undefined;
	Document = undefined;
	Responsible = undefined;
	Resolution = undefined;
	Restrictions.Clear ();

EndProcedure
