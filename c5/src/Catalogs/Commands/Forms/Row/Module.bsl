&AtClient
var TableRow export;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	readAppearance ();
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|User enable Switcher = 2;
	|Role enable Switcher = 3
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	loadData ();
	initSwitcher ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtClient
Procedure loadData ()
	
	TableRow = Object.Performers.Add ();
	data = FormOwner.Items.Performers.CurrentData;
	FillPropertyValues ( TableRow, data );

EndProcedure

&AtClient
Procedure initSwitcher ()
	
	performerType = TypeOf ( TableRow.Performer );
	if ( performerType = Type ( "CatalogRef.Users" ) ) then
		Switcher = 2;
		User = TableRow.Performer;
	elsif ( performerType = Type ( "EnumRef.Roles" ) ) then
		Switcher = 3;
		Role = TableRow.Performer;
	else
		Switcher = 1;
	endif;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	if ( not checkFields () ) then
		return;
	endif;
	FormOwner.Modified = true;
	applySwitcher ();
	Close ( TableRow );
	
EndProcedure

&AtClient
Function checkFields ()
	
	if ( Switcher = 2 ) then
		field = "User";
	elsif ( Switcher = 3 ) then
		field = "Role";
	else
		return true;
	endif;
	return Forms.CheckFields ( ThisObject, field );
	
EndFunction

&AtClient
Procedure applySwitcher ()
	
	if ( Switcher = 2 ) then
		TableRow.Performer = User;
		TableRow.Creator = false;
	elsif ( Switcher = 3 ) then
		TableRow.Performer = Role;
		TableRow.Creator = false;
	else
		TableRow.Performer = undefined;
		TableRow.Creator = true;
	endif;
	
EndProcedure

&AtClient
Procedure SwitcherOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Switcher" );
	
EndProcedure
