// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	DocumentForm.SetCreator ( Object );
	
EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure TenantOrderOnChange ( Item )
	
	applyTenantOrder ();
	setAmount ();
	
EndProcedure

&AtServer
Procedure applyTenantOrder ()
	
	setAmount ();
	setTenant ();
	
EndProcedure 

&AtServer
Procedure setAmount ()
	
	s = "
	|select Tenants.AmountBalance as Amount, Tenants.BonusBalance as Bonus
	|from AccumulationRegister.Tenants.Balance ( , TenantOrder = &TenantOrder ) as Tenants
	|";
	q = new Query ( s );
	q.SetParameter ( "TenantOrder", Object.TenantOrder );
	table = q.Execute ().Unload ();
	if ( table.Count () = 0 ) then
		Object.Amount = 0;
		Object.Bonus = 0;
	else
		row = table [ 0 ];
		Object.Amount = row.Amount;
		Object.Bonus = row.Bonus;
	endif; 
	
EndProcedure 

&AtServer
Procedure setTenant ()
	
	Object.Tenant = DF.Pick ( Object.TenantOrder, "Tenant" );
	
EndProcedure 
