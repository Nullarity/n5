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
	Object.VATUse = owner.VATUse;
	TableRow = Object.FixedAssets.Add ();
	FillPropertyValues ( TableRow, FormOwner.Items.FixedAssets.CurrentData );
	if ( TableRow.Method.IsEmpty () ) then
		TableRow.Method = PredefinedValue ( "Enum.Amortization.Linear" );
	endif; 
	
EndProcedure 

&AtClient
Procedure BeforeClose ( Cancel, Exit, MessageText, StandardProcessing )
	
	if ( SelectedValue = undefined ) then
		Cancel = true;
		pickValue ( Enum.ChoiceOperationsFixedAsset (), undefined );
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
	
	applyCommand ( Enum.ChoiceOperationsFixedAsset () );
	
EndProcedure

&AtClient
Procedure applyCommand ( Command )
	
	FormOwner.Modified = true;
	pickValue ( Command, TableRow );
	
EndProcedure 

&AtClient
Procedure SaveAndNew ( Command )
	
	applyCommand ( Enum.ChoiceOperationsFixedAssetSaveAndNew () );
	
EndProcedure

&AtClient
Procedure MethodOnChange ( Item )
	
	CommissioningForm.MethodOnChage ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemOnChange ( Item )
	
	applyItem ();
	
EndProcedure

&AtClient
Procedure applyItem ()
	
	item = TableRow.Item;
	data = DF.Values ( item, "VAT, VAT.Rate as Rate" );
	TableRow.VATCode = data.VAT;
	TableRow.VATRate = data.Rate;
	TableRow.VATAccount = AccountsMap.FixedAsset ( item, Object.Company, "VAT" ).VAT;
	
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

&AtClient
Procedure VATCodeOnChange ( Item )
	
	TableRow.VATRate = DF.Pick ( TableRow.VATCode, "Rate" );
	Computations.Total ( TableRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure VATOnChange ( Item )
	
	Computations.Total ( TableRow, Object.VATUse, false );
	
EndProcedure

&AtClient
Procedure AmountOnChange ( Item )
	
	Computations.Total ( TableRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure TypeOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "TableRow.Type" );
	
EndProcedure
