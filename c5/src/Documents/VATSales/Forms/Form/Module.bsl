// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.Init ( Object );
		fillNew ();
	endif;
	StandardButtons.Arrange ( ThisObject );
	
EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	settings = Logins.Settings ( "Company" );
	Object.Company = settings.Company;
	Object.RecordDate = CurrentSessionDate ();
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )
	
	setRecordDate ();
	
EndProcedure

&AtClient
Procedure setRecordDate ()
	
	Object.RecordDate = Object.Date;
	
EndProcedure 

&AtClient
Procedure SeriesOnChange ( Item )
	
	setNumber ();
	
EndProcedure

&AtClient
Procedure setNumber ()
	
	Object.Number = TrimR ( Object.Series ) + Object.FormNumber;
	
EndProcedure 

&AtClient
Procedure FormNumberOnChange ( Item )
	
	setNumber ();
	
EndProcedure

&AtClient
Procedure VATUseOnChange ( Item )
	
	Computations.Total ( Object, Object.VATUse );
	
EndProcedure

&AtClient
Procedure VATCodeOnChange ( Item )
	
	Object.VATRate = DF.Pick ( Object.VATCode, "Rate" );
	Computations.Total ( Object, Object.VATUse );
	
EndProcedure

&AtClient
Procedure VATOnChange ( Item )
	
	Computations.Total ( Object, Object.VATUse, false );
	
EndProcedure

&AtClient
Procedure AmountOnChange ( Item )
	
	Computations.Total ( Object, Object.VATUse );
	
EndProcedure
