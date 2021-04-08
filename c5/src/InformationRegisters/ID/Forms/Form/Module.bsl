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
	|Individual lock filled ( Record.Individual )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure 

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not checkPeriod () ) then
		Cancel = true;
	endif; 
	
EndProcedure

Function checkPeriod ()
	
	if ( not Periods.Ok ( Record.Period, Record.ValidTo ) ) then
		Output.PeriodError ( , "Period" );
		return false;
	endif;
	return true;
	
EndFunction 

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( Record.Main ) then
		resetPrevious ();
	endif; 
	
EndProcedure

&AtServer
Procedure resetPrevious ()
	
	data = mainID ();
	if ( data = undefined ) then
		return;
	endif; 
	r = InformationRegisters.ID.CreateRecordManager ();
	FillPropertyValues ( r, data );
	r.Main = false;
	r.Write ();
	
EndProcedure 

&AtServer
Function mainID ()
	
	s = "
	|select *
	|from InformationRegister.ID as IDs
	|where IDs.Individual = &Individual
	|and IDs.Main
	|";
	q = new Query ( s );
	q.SetParameter ( "Individual", Record.Individual );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ] );
	
EndFunction 