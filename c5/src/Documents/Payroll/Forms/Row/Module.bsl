&AtClient
var TableRow export;
&AtClient
var SelectedValue;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	Options.Company ( ThisObject, Object.Company );
	readAppearance ();
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|GroupVacation show inlist ( Method, Enum.Calculations.ExtendedVacation, Enum.Calculations.Vacation );
	|GroupSickLeave show inlist ( Method, Enum.Calculations.SickDays, Enum.Calculations.SickDaysChild, Enum.Calculations.SickOnlySocial, Enum.Calculations.SickProduction );
	|PageFields Employee Reference enable-unlock Edit;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadParams ()
	
	Object.Company = Parameters.Company;
	NewRow = Parameters.row;
	ReadOnly = Parameters.ReadOnly;
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	loadData ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtClient
Procedure loadData ()
	
	owner = FormOwner.Object;
	Object.Date = owner.Date;
	TableRow = Object.Compensations.Add ();
	FillPropertyValues ( TableRow, FormOwner.Items.Compensations.CurrentData );
	TableRow.Edit = NewRow or TableRow.Edit;
	Edit = TableRow.Edit;
	setMethod ();
	
EndProcedure 

&AtClient
Procedure setMethod ()
	
	compensation = TableRow.Compensation;
	if ( compensation.IsEmpty () ) then
		Method = undefined;
	else
		Method = DF.Pick ( TableRow.Compensation, "Method" );
	endif;
	
EndProcedure 

&AtClient
Procedure BeforeClose ( Cancel, Exit, MessageText, StandardProcessing )
	
	if ( SelectedValue = undefined ) then
		Cancel = true;
		pickValue ( Enum.ChoiceOperationsPayrollRecord (), undefined );
	endif;
	
EndProcedure

&AtClient
Procedure pickValue ( Operation, Value )
	
	SelectedValue = new Structure ();
	SelectedValue.Insert ( "Operation", Operation );
	SelectedValue.Insert ( "Value", Value );
	SelectedValue.Insert ( "row", Parameters.NewRow );
	#if ( WebClient ) then
		// Bug workaround 8.3.14.1592. NotifyChoice () will not close the form.
		// Idle handler is required
		AttachIdleHandler ( "startChoosing", 0.01, true );
	#else
		NotifyChoice ( SelectedValue );
	#endif
	
EndProcedure

&AtClient
Procedure startChoosing ()
	
	NotifyChoice ( SelectedValue );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	applyCommand ( Enum.ChoiceOperationsPayrollRecord () );

EndProcedure

&AtClient
Procedure applyCommand ( Command )
	
	FormOwner.Modified = true;
	pickValue ( Command, TableRow );
	
EndProcedure 

&AtClient
Procedure SaveAndNew ( Command )
	
	applyCommand ( Enum.ChoiceOperationsPayrollRecordSaveAndNew () );
	
EndProcedure

&AtClient
Procedure EmployeeOnChange ( Item )
	
	HiringForm.SetIndividual ( TableRow );
	
EndProcedure

&AtClient
Procedure EditOnChange ( Item )
	
	Edit = Object.Compensations [ 0 ].Edit;
	Appearance.Apply ( ThisObject, "Edit" );
	
EndProcedure

&AtClient
Procedure CompensationOnChange ( Item )
	
	setMethod ();
	resetReference ();
	Appearance.Apply ( ThisObject, "Method" );
	
EndProcedure

&AtClient
Procedure resetReference ()
	
	if ( Method = PredefinedValue ( "Enum.Calculations.SickDays" )
		or Method = PredefinedValue ( "Enum.Calculations.ExtendedVacation" )
		or Method = PredefinedValue ( "Enum.Calculations.Vacation" ) ) then
		return;
	endif;
	TableRow.Reference = undefined;
	
EndProcedure