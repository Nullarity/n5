// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	readMethod ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readMethod ()
	
	Method = DF.Pick ( Record.Tax, "Method" );
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Record.SourceRecordKey.IsEmpty () ) then
		IsNew = true;
		readMethod ();
	endif; 
	readAppearance ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|CanceledInfo show not Record.Use;
	|GroupFields FormWriteAndClose InformationRegisterPayrollTaxesCancel enable Record.Use;
	|Tax lock filled ( Record.Tax );
	|InformationRegisterPayrollTaxesCancel show not IsNew and Record.Use
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure TaxOnChange ( Item )
	
	applyTax ();
	
EndProcedure

&AtServer
Procedure applyTax ()
	
	readMethod ();
	Appearance.Apply ( ThisObject, "Method" );
	
EndProcedure
