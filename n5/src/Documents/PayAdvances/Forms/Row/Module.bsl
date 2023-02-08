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
	|PageFields unlock TableRow.Edit;
	|PageFields show TableRow.Edit or not NewRow;
	|Employee unlock TableRow.Edit or NewRow;
	|PageInfo show not TableRow.Edit and NewRow
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadParams ()
	
	Object.Company = Parameters.Company;
	NewRow = Parameters.NewRow;
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
	
EndProcedure 

&AtClient
Procedure BeforeClose ( Cancel, Exit, MessageText, StandardProcessing )
	
	if ( SelectedValue = undefined ) then
		Cancel = true;
		pickValue ( Enum.ChoiceOperationsPayAdvancesRecord (), undefined );
	endif;
	
EndProcedure

&AtClient
Procedure pickValue ( Operation, Value )
	
	SelectedValue = new Structure ();
	SelectedValue.Insert ( "Operation", Operation );
	SelectedValue.Insert ( "Value", Value );
	SelectedValue.Insert ( "NewRow", Parameters.NewRow );
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
	
	applyCommand ( Enum.ChoiceOperationsPayAdvancesRecord () );

EndProcedure

&AtClient
Procedure applyCommand ( Command )
	
	FormOwner.Modified = true;
	pickValue ( Command, TableRow );
	
EndProcedure 

&AtClient
Procedure SaveAndNew ( Command )
	
	applyCommand ( Enum.ChoiceOperationsPayAdvancesRecordSaveAndNew () );
	
EndProcedure

&AtClient
Procedure EmployeeOnChange ( Item )
	
	HiringForm.SetIndividual ( TableRow );
	
EndProcedure

&AtClient
Procedure EditOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "TableRow.Edit" );
	
EndProcedure
