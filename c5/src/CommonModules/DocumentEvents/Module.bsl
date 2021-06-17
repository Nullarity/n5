
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
	if ( exception ( Source ) ) then
		return;
	endif; 
	Prefix = Prefix + Source.Company.Prefix;
	
EndProcedure

Function exception ( Source )
	
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
		or Source.DataExchange.Load
		or Logins.Admin () ) then
		return;
	endif; 
	Cancel = not writingAllowed ( Source );

EndProcedure

Function writingAllowed ( Source )
	
	rights = getRights ( Source );
	access = getAccess ( Source, rights );
	if ( not access.Allowed ) then
		if ( access.Action = undefined ) then
			Output.DocumentRightsUndefined ( new Structure ( "User", SessionParameters.User ) );
		else
			Output.DocumentModificationIsNotAllowed ( new Structure ( "User, Action", SessionParameters.User, access.Action ) );
		endif; 
	endif; 
	return access.Allowed;
	
EndFunction

Function getRights ( Source )
	
	rightsMap = new Map ();
	table = getRightsTable ( Source );
	for each row in table do
		if ( rightsMap [ row.Action ] = undefined ) then
			rightsMap [ row.Action ] = row.Access;
		endif; 
	enddo; 
	return rightsMap;
	
EndFunction 

Function getRightsTable ( Source )
	
	s = "
	|select undefined as User
	|into UserAndGroups
	|union
	|select &User
	|union
	|select Users.Membership
	|from InformationRegister.Membership as Users
	|where Users.User = &User
	|and not Users.Membership.DeletionMark
	|;
	|select Rights.Access as Access, Rights.Action as Action,
	|	case when Rights.Target = undefined then 0
	|			+ case when Rights.Document <> value ( Catalog.Metadata.EmptyRef ) then 5 else 0 end
	|			+ case when Rights.Access = value ( Enum.AllowDeny.Deny ) then 1000 else 0 end
	|		when Rights.Target refs Catalog.Membership then 10
	|			+ case when Rights.Document <> value ( Catalog.Metadata.EmptyRef ) then 5 else 0 end
	|			+ case when Rights.Access = value ( Enum.AllowDeny.Deny ) then 1000 else 0 end
	|		else 100
	|			+ case when Rights.Document <> value ( Catalog.Metadata.EmptyRef ) then 5 else 0 end
	|			+ case when Rights.Access = value ( Enum.AllowDeny.Deny ) then 1000 else 0 end
	|	end as Weight
	|from InformationRegister.Rights as Rights
	|where Rights.Target in ( select User from UserAndGroups )
	|and Rights.Document in ( value ( Catalog.Metadata.EmptyRef ), Document = &Document )
	|and ( ( Rights.Method = value ( Enum.RestrictionMethods.Period )
	|	and &DocumentDate > Rights.DateStart
	|	and ( &DocumentDate < Rights.DateEnd or Rights.DateEnd = datetime ( 1, 1, 1 ) ) )
	|	or ( Rights.Method = value ( Enum.RestrictionMethods.Duration )
	|	and Rights.Access = value ( Enum.AllowDeny.Deny )
	|	and datediff ( &DocumentDate, &OperationalTime, day ) >= Rights.Duration )
	|	or ( Rights.Method = value ( Enum.RestrictionMethods.Duration )
	|	and Rights.Access = value ( Enum.AllowDeny.Allow )
	|	and datediff ( &DocumentDate, &OperationalTime, day ) <= Rights.Duration )
	|	or Rights.Method = value ( Enum.RestrictionMethods.EmptyRef ) )
	|and ( &OperationalTime < Rights.Expiration or Rights.Expiration = datetime ( 1, 1, 1 ) )
	|order by Weight desc
	|";
	q = new Query ( s );
	q.TempTablesManager = new TempTablesManager ();
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Document", MetadataRef.Get ( Source.Metadata ().FullName () ) );
	q.SetParameter ( "DocumentDate", Source.Date );
	q.SetParameter ( "OperationalTime",	Max ( GetRealTimeTimestamp (), CurrentDate () ) );
	return q.Execute ().Unload ();
	
EndFunction 

Function getAccess ( Source, Rights )
	
	result = new Structure ( "Allowed, Action", false, undefined );
	if ( Source.IsNew () ) then
		if ( Rights [ Enums.AccessRights.Create ] = Enums.AllowDeny.Deny ) then
			result.Action = Enums.AccessRights.Create;
		elsif ( Rights [ Enums.AccessRights.Any ] = Enums.AllowDeny.Deny ) then
			result.Action = Enums.AccessRights.Any;
		elsif ( Rights [ Enums.AccessRights.Create ] = Enums.AllowDeny.Allow
			or Rights [ Enums.AccessRights.Any ] = Enums.AllowDeny.Allow ) then
			result.Allowed = true;
		endif;
	elsif ( Rights [ Enums.AccessRights.Edit ] = Enums.AllowDeny.Deny ) then
		result.Action = Enums.AccessRights.Edit;
	elsif ( Rights [ Enums.AccessRights.UndoPosting ] = Enums.AllowDeny.Deny ) then
		result.Action = Enums.AccessRights.UndoPosting;
	elsif ( Rights [ Enums.AccessRights.Any ] = Enums.AllowDeny.Deny ) then
		result.Action = Enums.AccessRights.Any;
	elsif ( Rights [ Enums.AccessRights.Edit ] = Enums.AllowDeny.Allow
		or Rights [ Enums.AccessRights.UndoPosting ] = Enums.AllowDeny.Allow
		or Rights [ Enums.AccessRights.Any ] = Enums.AllowDeny.Allow ) then
		result.Allowed = true;
	endif; 
	return result;
	
EndFunction

Procedure CheckInvoice ( Source, Cancel, WriteMode, PostingMode ) export
	
	if ( Source.IsNew ()
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
		return changesAllowed ( DF.Pick ( invoice, "Status" ) );
	endif;

EndFunction

Function changesAllowed ( Status )
	
	return Status.IsEmpty ()
	or Status = Enums.FormStatuses.Saved
	or Status = Enums.FormStatuses.Canceled;
	
EndFunction
