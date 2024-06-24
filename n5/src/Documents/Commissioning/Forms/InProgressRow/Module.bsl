
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
	CommissioningForm.FixedAssetAppearance ( ThisObject );

EndProcedure

&AtServer
Procedure loadParams ()
	
	Object.Company = Parameters.Company;
	
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
	TableRow = Object.InProgress.Add ();
	data = FormOwner.Items.InProgress.CurrentData;
	Inventory = data.Item;
	FillPropertyValues ( TableRow, data );
	if ( TableRow.Method.IsEmpty () ) then
		TableRow.Method = PredefinedValue ( "Enum.Amortization.Linear" );
	endif; 

EndProcedure

&AtClient
Procedure BeforeClose ( Cancel, Exit, MessageText, StandardProcessing )
	
	if ( SelectedValue = undefined ) then
		Cancel = true;
		pickValue ( Enum.ChoiceOperationsFixedAssetInProgress (), undefined );
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
	
	applyCommand ( Enum.ChoiceOperationsFixedAssetInProgress () );
	
EndProcedure

&AtClient
Procedure applyCommand ( Command )
	
	FormOwner.Modified = true;
	pickValue ( Command, TableRow );
	
EndProcedure 

&AtClient
Procedure SaveAndNew ( Command )
	
	applyCommand ( Enum.ChoiceOperationsFixedAssetInProgressSaveAndNew () );
	
EndProcedure

&AtClient
Procedure MethodOnChange ( Item )
	
	CommissioningForm.MethodOnChage ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemOnChange ( Item )
	
	CommissioningForm.SetAmount ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemAccountOnChange ( Item )
	
	CommissioningForm.SetAmount ( ThisObject );
	
EndProcedure

&AtClient
Procedure FixedAssetCreating ( Item, StandardProcessing )
	
	StandardProcessing = false;
	newAsset ( Item );
	
EndProcedure

&AtClient
Procedure newAsset ( Item )
	
	p = new Structure ();
	p.Insert ( "ChoiceMode", true );
	p.Insert ( "FillingText", ? ( Item.EditText = "", String ( Inventory ), Item.EditText ) );
	OpenForm ( "Catalog.FixedAssets.ObjectForm", p, Item, , , , , FormWindowOpeningMode.LockOwnerWindow );
		
EndProcedure 

&AtClient
Procedure ChargeOnChange ( Item )
	
	resetDate ();
	Appearance.Apply ( ThisObject, "TableRow.Charge" );
	
EndProcedure

&AtClient
Procedure resetDate ()
	
	if ( TableRow.Charge ) then
		TableRow.Starting = BegOfMonth ( AddMonth ( Object.Date, 1 ) );
	else
		TableRow.Starting = undefined;
	endif; 
	
EndProcedure 

&AtClient
Procedure StartingOnChange ( Item )
	
	TableRow.Starting = BegOfMonth ( TableRow.Starting );
	
EndProcedure
