// *****************************************
// *********** Group Form

&AtClient
Procedure TenantFilterOnChange ( Item )
	
	filterByTenant ();
	
EndProcedure

&AtServer
Procedure filterByTenant ()
	
	DC.ChangeFilter ( List, "Agent", TenantFilter, not TenantFilter.IsEmpty () );
	
EndProcedure 