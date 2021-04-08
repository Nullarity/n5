// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setAccess ();
	if ( Access ) then
		setCompany ();
		filterByCompany ();
	endif; 
	filterByOffline ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|CompanyFilter show Access;
	|FormShowOffline release not ShowOffline
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure setAccess ()
	
	Access = AccessRight ( "View", Metadata.AccountingRegisters.General );
	
EndProcedure 

&AtServer
Procedure setCompany ()
	
	CompanyFilter = Logins.Settings ( "Company" ).Company;
	
EndProcedure 

&AtServer
Procedure filterByCompany ()
	
	DC.ChangeFilter ( List, "Company", CompanyFilter, not CompanyFilter.IsEmpty () );
	
EndProcedure 

&AtServer
Procedure filterByOffline ()
	
	DC.ChangeFilter ( List, "Offline", ShowOffline, not ShowOffline );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure ShowOffline ( Command )
	
	toggleOffline ();
	
EndProcedure

&AtServer
Procedure toggleOffline ()
	
	ShowOffline = not ShowOffline;
	filterByOffline ();
	Appearance.Apply ( ThisObject, "ShowOffline" );
	
EndProcedure 

&AtClient
Procedure CompanyFilterOnChange ( Item )
	
	filterByCompany ();
	
EndProcedure
