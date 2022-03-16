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
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		copy = not Parameters.CopyingValue.IsEmpty ();
		if ( copy ) then
			BalancesForm.FixDate ( ThisObject );
		else
			BalancesForm.CheckParameters ( ThisObject );
		endif;
		DocumentForm.SetCreator ( Object );
		Constraints.ShowAccess ( ThisObject );
	endif;
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	
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
Procedure EmployeesCompensationOnChange ( Item )
	
	setAccount ();
	
EndProcedure

&AtClient
Procedure setAccount ()
	
	TableRow.Account = DF.Pick ( TableRow.Compensation, "Account" );
	
EndProcedure 
