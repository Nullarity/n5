// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setTitle ();
	loadFixedSettings ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|CompanyFilter show empty ( FixedCompanyFilter )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure setTitle ()
	
	filter = Parameters.Filter;
	if ( filter.Property ( "Production" )
		and filter.Production ) then
		AutoTitle = false;
		Title = Output.WorkshopsList ();
	endif;
	
EndProcedure

&AtServer
Procedure loadFixedSettings ()
	
	Parameters.Filter.Property ( "Owner", FixedCompanyFilter );
	
EndProcedure 

// *****************************************
// *********** Table List

&AtClient
Procedure CompanyFilterOnChange ( Item )
	
	filterByCompany ();
	
EndProcedure

&AtServer
Procedure filterByCompany ()
	
	DC.ChangeFilter ( List, "Owner", CompanyFilter, not CompanyFilter.IsEmpty () );
	
EndProcedure 
