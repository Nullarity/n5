&AtClient
var TableRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )

	updateChangesPermission ();

EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing)
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.Init ( Object );
		fillNew ();
		updateChangesPermission ();
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
	company = settings.Company;
	Object.Company = company;
	
EndProcedure 

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

// *****************************************
// *********** Table Employees

&AtClient
Procedure EmployeesOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure EmployeesEmployeeOnChange ( Item )
	
	HiringForm.SetIndividual ( TableRow );	
	
EndProcedure

&AtClient
Procedure EmployeesOnStartEdit ( Item, NewRow, Clone )
	
	if ( not NewRow
		or Clone ) then
		return;
	endif; 
	TableRow.Date = Object.Date;
	adjustDate ();

EndProcedure

&AtClient
Procedure adjustDate ()
	
	date = TableRow.Date;
	if ( date = Date ( 1, 1, 1 ) ) then
		return;
	endif; 
	TableRow.Date = EndOfDay ( date );
	
EndProcedure 

&AtClient
Procedure EmployeesOnEditEnd ( Item, NewRow, CancelEdit )
	
	if ( CancelEdit
		and NewRow ) then
		return;
	endif; 
	adjustDate ();
	
EndProcedure
