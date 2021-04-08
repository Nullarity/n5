// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadFixedSettings ();
	setTitle ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|OwnerFilter show empty ( FixedOwnerFilter )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadFixedSettings ()
	
	Parameters.Filter.Property ( "Owner", FixedOwnerFilter );
	
EndProcedure 

&AtServer
Procedure setTitle ()
	
	if ( FixedOwnerFilter.IsEmpty () ) then
		Title = Metadata.Catalogs.PropertyValues.Presentation ();
	else
		Title = "" + FixedOwnerFilter;
	endif; 
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure OwnerFilterOnChange ( Item )
	
	filterByOwner ();
	
EndProcedure

&AtServer
Procedure filterByOwner ()
	
	DC.ChangeFilter ( List, "Owner", OwnerFilter, not OwnerFilter.IsEmpty () );
	
EndProcedure 