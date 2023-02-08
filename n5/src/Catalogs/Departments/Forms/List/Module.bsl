// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadFixedSettings ();
	initList ();
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
Procedure loadFixedSettings ()
	
	Parameters.Filter.Property ( "Owner", FixedCompanyFilter );
	
EndProcedure 

&AtServer
Procedure initList ()
	
	if ( FixedCompanyFilter.IsEmpty () ) then
		settings = Logins.Settings ( "Company" );
		CompanyFilter = settings.Company;
		filterByCompany ();
	endif;

EndProcedure

&AtServer
Procedure filterByCompany ()
	
	DC.ChangeFilter ( List, "Owner", CompanyFilter, not CompanyFilter.IsEmpty () );
	
EndProcedure 

// *****************************************
// *********** Table List

&AtClient
Procedure CompanyFilterOnChange ( Item )
	
	filterByCompany ();
	
EndProcedure
