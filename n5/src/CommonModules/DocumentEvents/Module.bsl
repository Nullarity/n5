
Procedure CheckDate ( Source, Cancel, CheckedAttributes ) export
	
	if ( Source.Date = Date ( 1, 1, 1 ) ) then
		return;
	endif;
	if ( Source.Date < Date ( "20000101" ) ) then
		Output.DocumentDateError1 ( , "Date" );
	elsif ( Source.Date > Date ( "21000101" ) ) then
		Output.DocumentDateError2 ( , "Date" );
	endif; 
	
EndProcedure

Procedure Prefix ( Source, StandardProcessing, Prefix ) export
	
	px = Application.Prefix ();
	if ( px <> "" ) then
		Prefix = px;
	endif;
	if ( dontPrefix ( Source ) ) then
		return;
	endif; 
	Prefix = Prefix + Source.Company.Prefix;
	
EndProcedure

Function dontPrefix ( Source )
	
	type = TypeOf ( Source );
	return
		type = Type ( "DocumentObject.AgentPayment" )
		or type = Type ( "DocumentObject.Document" )
		or type = Type ( "DocumentObject.DocumentVersion" )
		or type = Type ( "DocumentObject.IncomingEmail" )
		or type = Type ( "DocumentObject.OutgoingEmail" )
		or type = Type ( "DocumentObject.ProjectsInvoice" )
		or type = Type ( "DocumentObject.ProjectsPayment" )
		or type = Type ( "DocumentObject.TenantOrder" )
		or type = Type ( "DocumentObject.TenantPayment" )
		or type = Type ( "DocumentObject.TimeEntry" )
		or type = Type ( "DocumentObject.Timesheet" )
		or type = Type ( "DocumentObject.Entry" )
		or type = Type ( "DocumentObject.InvoiceRecord" );
	
EndFunction 
	
Procedure BankEnrollment ( Source ) export
	
	InformationRegisters.Bank.Enroll ( Source );
	
EndProcedure

Procedure CheckAccess ( Source, Cancel, WriteMode, PostingMode ) export
	
	if ( Cancel
		or Source.DataExchange.Load ) then
		return;
	endif; 
	if ( not Constraints.CheckAccess ( Source ) ) then
		Cancel = true;
	endif; 

EndProcedure
 
Procedure CheckInvoice ( Source, Cancel, WriteMode, PostingMode ) export
	
	if ( Source.IsNew ()
		or Source.DataExchange.Load = true
		or canChange ( Source ) ) then
		return;
	endif;
	Cancel = true;
	Output.InvoicePrinted ();
	
EndProcedure

Function canChange ( Source ) 

	invoice = InvoiceRecordsSrv.Search ( Source.Ref );
	if ( invoice = undefined ) then
		return true;
	else
		return changesAllowed ( DF.Values ( invoice, "Status, DeletionMark" ) );
	endif;

EndFunction

Function changesAllowed ( Info )
	
	status = Info.Status;
	return Info.DeletionMark
	or Status.IsEmpty ()
	or Status = Enums.FormStatuses.Saved
	or Status = Enums.FormStatuses.Canceled
	or IsInRole ( Metadata.Roles.ModifyIssuedInvoices );
	
EndFunction
