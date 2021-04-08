&AtClient
var TableRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.Init ( Object );
		fillNew ();
	endif; 
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	
EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	settings = Logins.Settings ( "Company" );
	Object.Company = settings.Company;
	
EndProcedure 

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

EndProcedure

// *****************************************
// *********** Table Employees

&AtClient
Procedure EmployeesOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure EmployeesDurationOnChange ( Item )
	
	Conversion.AdjustTime ( TableRow.Duration );
	calcMinutes ();
	
EndProcedure

&AtClient
Procedure calcMinutes ()
	
	TableRow.Minutes = Conversion.DurationToMinutes ( TableRow.Duration );
	
EndProcedure 

&AtClient
Procedure EmployeesEmployeeOnChange ( Item )
	
	HiringForm.SetIndividual ( TableRow );
	
EndProcedure
