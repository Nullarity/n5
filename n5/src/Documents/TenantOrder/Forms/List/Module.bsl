// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setListDataParameters ();
	setLicenseInformation ();
	setUsersInformation ();
	
EndProcedure

&AtServer
Procedure setListDataParameters ()
	
	List.Parameters.SetParameterValue ( "Today", BegOfDay ( CurrentSessionDate () ) );
	
EndProcedure 

&AtServer
Procedure setLicenseInformation ()
	
	info = getEndOfLicense ();
	if ( info = undefined ) then
		return;
	endif;
	p = new Structure ( "DaysRemain", Info.DaysRemain );
	if ( info.TrialPeriod ) then
		Items.LicenseProgress.Title = Output.TrialPeriodInformation ( p );
	else
		Items.LicenseProgress.Title = Output.LicensePeriodInformation ( p );
	endif; 
	Items.LicenseProgress.MaxValue = info.LicensePeriod;
	LicenseProgress = info.LicensePeriod - info.DaysRemain;
	
EndProcedure 

&AtServer
Function getEndOfLicense ()
	
	s = "
	|select allowed top 1 datediff ( &Today, Licenses.Date, day ) as DaysRemain, Licenses.TrialPeriod as TrialPeriod,
	|	Licenses.LicensePeriod as LicensePeriod
	|from (	select Tenants.EndOfTrialPeriod as Date, true as TrialPeriod, Constants.TrialPeriod as LicensePeriod
	|		from Catalog.Tenants as Tenants
	|			//
	|			// Constants
	|			//
	|			join Constants as Constants
	|			on true
	|		where Tenants.Ref = &Tenant
	|		and &Today <= Tenants.EndOfTrialPeriod
	|		union
	|		select min ( TenantOrders.DateEnd ), false, min ( datediff ( TenantOrders.Date, TenantOrders.DateEnd, day ) )
	|		from Document.TenantOrder as TenantOrders
	|			//
	|			// TenantPayments
	|			//
	|			join Document.TenantPayment as TenantPayments
	|			on TenantPayments.TenantOrder = TenantOrders.Ref
	|			and TenantPayments.Posted
	|		where &Today between TenantOrders.Date and TenantOrders.DateEnd ) as Licenses
	|where Licenses.Date is not null
	|order by Licenses.Date desc
	|";
	q = new Query ( s );
	q.SetParameter ( "Today", BegOfDay ( CurrentSessionDate () ) );
	q.SetParameter ( "Tenant", SessionParameters.Tenant );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ] );
	
EndFunction 

&AtServer
Procedure setUsersInformation ()
	
	info = CloudPayments.GetInfo ();
	UsersCount = info.UsersCount;
	PaidUsersCount = info.PaidUsersCount;
	
EndProcedure 
