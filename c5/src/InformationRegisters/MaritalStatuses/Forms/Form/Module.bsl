// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Individual lock filled ( Record.Individual );
	|Select enable Record.Status = Enum.MaritalStatuses.Married;
	|Spouse enable Record.Status = Enum.MaritalStatuses.Married and Record.Select;
	|Country PIN enable Record.Status = Enum.MaritalStatuses.Married and not Record.Select
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure StatusOnChange ( Item )
	
	applyStatus ();
	
EndProcedure

&AtClient
Procedure applyStatus ()
	
	if ( Record.Status <> PredefinedValue ( "Enum.MaritalStatuses.Married" ) ) then
		Record.Select = false;
		Record.Country = undefined;
		Record.PIN = "";
		Record.Spouse = undefined;
		Appearance.Apply ( ThisObject, "Record.Select" );
	endif; 
	Appearance.Apply ( ThisObject, "Record.Status" );
	
EndProcedure 

&AtClient
Procedure SelectOnChange ( Item )
	
	resetSpouse ();
	Appearance.Apply ( ThisObject, "Record.Select" );
	
EndProcedure

&AtClient
Procedure resetSpouse ()
	
	if ( Record.Select ) then
		Record.Country = undefined;
		Record.PIN = "";
	else
		Record.Spouse = undefined;
	endif; 
	
EndProcedure 
