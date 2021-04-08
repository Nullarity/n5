Procedure Send () export
	
	SetPrivilegedMode ( true );
	profile = MailboxesSrv.SystemProfile ();
	message = new InternetMailMessage ();
	table = getTenants ();
	payers = getPayers ();
	for each row in table do
		if ( payers [ row.Tenant ] = undefined ) then
			continue;
		endif; 
		setSenderAndReceiver ( row, message );
		setSubjectAndBody ( row, message );
		try
			MailboxesSrv.Post ( profile, message );
		except
			WriteLogEvent ( "MailboxesSrv.Post", EventLogLevel.Error, Metadata.ScheduledJobs.PaymentNotifications, , ErrorDescription () );
		endtry
	enddo; 
	SetPrivilegedMode ( false );
	
EndProcedure

Function getTenants ()
	
	s = "
	|select Tenants.Ref as Tenant, Tenants.Code as Code, Tenants.Description as Email, true as TrialPeriod, null as UsersCount, null as OrderNumber
	|from Catalog.Tenants as Tenants
	|	//
	|	// TenantPayments
	|	//
	|	left join Document.TenantPayment as TenantPayments
	|	on TenantPayments.TenantOrder.Tenant = Tenants.Ref
	|	and TenantPayments.Posted
	|where dateadd ( Tenants.EndOfTrialPeriod, day, -" + remindBefore () + " ) = &Today
	|and not Tenants.Deactivated
	|and not Tenants.DeletionMark
	|and TenantPayments.TenantOrder is null
	|union all
	|select TenantOrders.Tenant, TenantOrders.Tenant.Code, TenantOrders.Tenant.Description, false, TenantOrders.UsersCount, TenantOrders.Number
	|from Document.TenantOrder as TenantOrders
	|	//
	|	// TenantPayments
	|	//
	|	left join Document.TenantPayment as TenantPayments
	|	on TenantPayments.TenantOrder = TenantOrders.Ref
	|	and TenantPayments.Posted
	|where dateadd ( TenantOrders.DateEnd, day, -" + remindBefore () + " ) = &Today
	|";
	q = new Query ( s );
	q.SetParameter ( "Today", BegOfDay ( CurrentSessionDate () ) );
	return q.Execute ().Unload ();
	
EndFunction 

Function remindBefore ()
	
	return 5;
	
EndFunction 

Function getPayers ()
	
	result = new Map ();
	q = payersQuery ();
	tenants = Catalogs.Tenants.Select ();
	while ( tenants.Next () ) do
		tenant = tenants.Ref;
		toggleTenant ( tenant );
		if ( q.Execute ().IsEmpty () ) then
			continue;
		endif; 
		result [ tenant ] = true;
	enddo; 
	toggleTenant ( Catalogs.Tenants.EmptyRef () );
	return result;

EndFunction 

Function payersQuery ()
	
	return new Query ( "
	|select 1
	|from Catalog.Users as Users
	|where not Users.IsFolder
	|and not Users.DeletionMark
	|and not Users.AccessDenied
	|and not Users.AccessRevoked
	|having count ( Users.Ref ) > 1
	|" );
	
EndFunction 

Procedure toggleTenant ( Tenant )
	
	SessionParameters.Tenant = Tenant;
	SessionParameters.TenantUse = Tenant <> undefined;
	
EndProcedure 

Procedure setSenderAndReceiver ( Row, Message )
	
	Message.From = Cloud.Info ();
	Message.To.Add ( Row.Email );
	
EndProcedure

Procedure setSubjectAndBody ( Row, Message )
	
	p = new Structure ();
	p.Insert ( "CountOfDays", remindBefore () );
	p.Insert ( "Info", Cloud.Info () );
	p.Insert ( "Website", Cloud.Website () );
	if ( Row.TrialPeriod ) then
		p.Insert ( "TenantOrder", Cloud.GetTenantURL ( Row.Code ) + "/#e1cib/data/Document.TenantOrder" );
		p.Insert ( "DeactivateProfile", Cloud.GetTenantURL ( Row.Code ) + "/#e1cib/command/InformationRegister.DeactivationReasons.Command.Deactivate" );
		Message.Subject = Output.EndOfTrialPeriodSubject ( p );
		Message.Texts.Add ( Output.EndOfTrialPeriodBody ( p ) );
	else
		p.Insert ( "TenantOrder", Cloud.GetTenantURL ( Row.Code ) + "?C=" + EncodeString ( "c1=" + Row.OrderNumber, StringEncodingMethod.URLInURLEncoding ) );
		p.Insert ( "TenantOrderList", Cloud.GetTenantURL ( Row.Code ) + "/#e1cib/list/Document.TenantOrder" );
		p.Insert ( "UsersCount", Row.UsersCount );
		p.Insert ( "OrderNumber", Row.OrderNumber );
		Message.Subject = Output.EndOfLicensePeriodSubject ( p );
		Message.Texts.Add ( Output.EndOfLicensePeriodBody ( p ) );
	endif; 
	
EndProcedure
