
// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Record.SourceRecordKey.IsEmpty () ) then
		fillNew ();
	else
		if ( not InformationRegisters.Rights.Allowed ( Record.Target ) ) then
			Cancel = true;
			return;
		endif; 
	endif;
	initTarget ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure initTarget ()
	
	if ( not ValueIsFilled ( Record.Target ) ) then
		Record.Target = Catalogs.Users.EmptyRef ();
		Modified = false;
	endif;
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|DateStart DateEnd enable Record.Method = Enum.RestrictionMethods.Period;
	|Duration enable Record.Method = Enum.RestrictionMethods.Duration;
	|DurationSpan enable Record.Method = Enum.RestrictionMethods.Span;
	|AccessGroup Expiration disable Record.Disabled;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	Record.Creator = SessionParameters.User;
	
EndProcedure 

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	adjustTarget ( CurrentObject );
	if ( not InformationRegisters.Rights.Allowed ( Record.Target ) ) then
		Cancel = true;
	endif; 
	
EndProcedure

&AtServer
Procedure adjustTarget ( CurrentObject )
	
	if ( not ValueIsFilled ( CurrentObject.Target ) ) then
		CurrentObject.Target = undefined;
	endif; 
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure DisabledOnChange ( Item )

	Appearance.Apply ( ThisObject, "Record.Disabled" );

EndProcedure

&AtClient
Procedure MethodOnChange ( Item )
	
	reset ();
	Appearance.Apply ( ThisObject, "Record.Method" );
	
EndProcedure

&AtClient
Procedure reset ()
	
	if ( Record.Method = PredefinedValue ( "Enum.RestrictionMethods.Period" ) ) then
		Record.Duration = 0;
	else
		Record.DateStart = undefined;
		Record.DateEnd = undefined;
	endif; 
	
EndProcedure 
