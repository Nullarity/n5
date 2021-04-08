// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Record.SourceRecordKey.IsEmpty () ) then
		IsNew = true;
	endif; 
	readAppearance ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|GroupFields InformationRegisterDeductionsCancel FormWriteAndClose enable Record.Use;
	|CanceledInfo show not Record.Use;
	|Employee lock filled ( Record.Employee );
	|InformationRegisterDeductionsCancel show not IsNew
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure
