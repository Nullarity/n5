// *****************************************
// *********** Group Form

&AtClient
Procedure TenantFilterOnChange ( Item )
	
	filterByTenant ();
	
EndProcedure

&AtServer
Procedure filterByTenant ()
	
	DC.ChangeFilter ( List, "TenantOrder.Tenant", TenantFilter, not TenantFilter.IsEmpty () );
	
EndProcedure 