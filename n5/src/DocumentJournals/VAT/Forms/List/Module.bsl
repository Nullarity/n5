// *****************************************
// *********** Group Form

&AtClient
Procedure OrganizationFilterOnChange ( Item )
	
	filterByOrganization ();
	
EndProcedure

&AtServer
Procedure filterByOrganization ()
	
	DC.ChangeFilter ( List, "Organization", OrganizationFilter, not OrganizationFilter.IsEmpty () );
	
EndProcedure 