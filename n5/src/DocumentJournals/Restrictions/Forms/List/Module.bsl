// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadFixedFilters ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|OrganizationFilter show empty ( FixedOrganizationFilter );
	|Organization show empty ( FixedOrganizationFilter ) and empty ( OrganizationFilter );
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadFixedFilters ()
	
	filter = Parameters.Filter;
	filter.Property ( "Organization", FixedOrganizationFilter );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure OrganizationFilterOnChange ( Item )
	
	filterByOrganization ();
	
EndProcedure

&AtServer
Procedure filterByOrganization ()
	
	DC.ChangeFilter ( List, "Organization", OrganizationFilter, not OrganizationFilter.IsEmpty () );
	Appearance.Apply ( ThisObject, "OrganizationFilter" );
	
EndProcedure 
