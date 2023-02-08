&AtClient
var TableRow export;

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
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
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
	Object.Company = settings.Company;
	
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
Procedure Edit ( Command )
	
	HiringForm.EditRow ( ThisObject );
	
EndProcedure

&AtClient
Procedure EmployeesOnActivateRow ( Item )
	
	HiringForm.OnActivateRow ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure EmployeesBeforeRowChange ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure EmployeesSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	HiringForm.EditRow ( ThisObject );

EndProcedure

&AtClient
Procedure EmployeesBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	Forms.NewRow ( ThisObject, Item, Clone );
	HiringForm.EditRow ( ThisObject, not Clone );
	
EndProcedure

&AtClient
Procedure EmployeesBeforeDeleteRow ( Item, Cancel )
	
	HiringForm.CleanAdditions ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Table Additions

&AtClient
Procedure AdditionsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	HiringForm.EditRow ( ThisObject );
	
EndProcedure
