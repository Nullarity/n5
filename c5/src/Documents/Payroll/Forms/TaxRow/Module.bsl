&AtClient
var TableRow export;
&AtClient
var SelectedValue;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	PayrollTaxForm.OnCreate ( ThisObject );
	
EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	PayrollTaxForm.OnOpen ( ThisObject );

EndProcedure

&AtClient
Procedure BeforeClose ( Cancel, Exit, MessageText, StandardProcessing )
	
	if ( SelectedValue = undefined ) then
		Cancel = true;
		pickValue ( Enum.ChoiceOperationsEmployeesTaxRecord (), undefined );
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
	
	Modified = true;
	pickValue ( Enum.ChoiceOperationsEmployeesTaxRecord (), TableRow );
	
EndProcedure

&AtClient
Procedure SaveAndNew ( Command )
	
	pickValue ( Enum.ChoiceOperationsEmployeesTaxRecordSaveAndNew (), TableRow );
	
EndProcedure

&AtClient
Procedure EmployeeOnChange ( Item )
	
	HiringForm.SetIndividual ( TableRow );
	
EndProcedure

&AtClient
Procedure EditOnChange ( Item )
	
	PayrollTaxForm.EditOnChange ( ThisObject );
	
EndProcedure

&AtClient
Procedure TaxOnChange ( Item )
	
	PayrollTaxForm.TaxOnChange ( ThisObject );
	
EndProcedure
