Function GetInfo () export
	
	q = new Query ();
	q.Text = getUsersSql () + ";"
	+ getPaidUsersSql () + ";"
	+ getEndOfTrialPeriodSql ();
	q.SetParameter ( "Tenant", SessionParameters.Tenant );
	today = BegOfDay ( CurrentSessionDate () );
	q.SetParameter ( "Today", today );
	SetPrivilegedMode ( true );
	data = q.ExecuteBatch ();
	usersRow = data [ 0 ].Unload () [ 0 ];
	paidUsersTable = data [ 1 ].Unload ();
	endOfTrialPeriodRow = data [ 2 ].Unload () [ 0 ];
	SetPrivilegedMode ( false );
	result = new Structure ();
	result.Insert ( "UsersCount", usersRow.Count );
	paidUsersCount = paidUsersTable [ 0 ];
	result.Insert ( "PaidUsersCount", ? ( paidUsersCount.Count = null, 0, paidUsersCount.Count ) );
	result.Insert ( "EndOfTrialPeriod", endOfTrialPeriodRow.EndOfTrialPeriod );
	result.Insert ( "Today", today );
	result.Insert ( "Info", Cloud.Info () );
	result.Insert ( "System", Connections.IsDemo () or Logins.Sysadmin () );
	return result;
	
EndFunction 

Function getUsersSql ()
	
	s = "
	|select count ( Ref ) as Count
	|from Catalog.Users as Users
	|where not Users.IsFolder
	|and not Users.DeletionMark
	|and not Users.AccessDenied
	|";
	return s;
	
EndFunction 

Function getPaidUsersSql ()
	
	s = "
	|select sum ( TenantOrders.UsersCount ) as Count
	|from Document.TenantOrder as TenantOrders
	|	//
	|	// TenantPayments
	|	//
	|	join Document.TenantPayment as TenantPayments
	|	on TenantPayments.TenantOrder = TenantOrders.Ref
	|	and TenantPayments.Posted
	|where endofperiod ( &Today, day ) between TenantOrders.Date and TenantOrders.DateEnd
	|and TenantOrders.Tenant = &Tenant
	|and not TenantOrders.DeletionMark
	|";
	return s;
	
EndFunction 

Function getEndOfTrialPeriodSql ()
	
	s = "
	|select Tenants.EndOfTrialPeriod as EndOfTrialPeriod
	|from Catalog.Tenants as Tenants
	|where Ref = &Tenant
	|";
	return s;
	
EndFunction 

Function UserCanPay () export
	
	return IsInRole ( "Administrator" );
	
EndFunction 
