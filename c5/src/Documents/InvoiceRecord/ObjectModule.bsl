#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not checkStatus () ) then
		Cancel = true;
	endif;
	RegulatedRangesForm.Check ( ThisObject, Cancel, CheckedAttributes );
	
EndProcedure

Function checkStatus ()
	
	if ( Status = Enums.FormStatuses.Printed ) then
		if ( TypeOf ( Base ) = Type ( "DocumentRef.Invoice" )
			and not IsInRole ( Metadata.Roles.PrintUnpostedInvoices )
			and not DF.Pick ( Base, "Posted" ) )
		then
			Output.CantPrintUnpostedInvoice ( , , Base );
			return false;
		endif;
	endif;
	return true;

EndFunction

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	RegulatedRanges.Fill ( ThisObject );

EndProcedure

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	if ( RegulatedRanges.Duplication ( ThisObject ) ) then
		Cancel = true;
		return;
	endif;
	RegulatedRanges.Enroll ( ThisObject );
	
EndProcedure

#endif
