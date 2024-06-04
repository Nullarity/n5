// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )

	initFilter ();
	readAppearance ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|UnitFilter show empty ( FixedOwnerFilter );
	|Owner show empty ( UnitFilter );
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure initFilter ()
	
	if ( Parameters.Filter.Property ( "Owner", FixedOwnerFilter ) ) then
		UnitFilter = FixedOwnerFilter;
	else
		UnitFilter = Logins.Settings ( "Company" ).Company;
		filterByUnit ();
	endif;
	
EndProcedure

&AtServer
Procedure filterByUnit ()
	
	DC.ChangeFilter ( List, "Owner", UnitFilter, ValueIsFilled ( UnitFilter ) );
	Appearance.Apply ( ThisObject, "UnitFilter" );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure UnitFilterOnChange ( Item )

	filterByUnit ();

EndProcedure
