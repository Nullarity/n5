&AtClient
var PaymentsRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	PaymentForm.OnReadAtServer ( ThisObject );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	PaymentForm.OnCreateAtServer ( ThisObject );
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	PaymentForm.BeforeWriteAtServer ( CurrentObject, ThisObject );

EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	PaymentForm.AfterWriteAtServer ( ThisObject );
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	PaymentForm.AfterWrite ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

&AtClient
Procedure CustomerOnChange ( Item )
	
	applyCustomer ();
	
EndProcedure

&AtServer
Procedure applyCustomer ()
	
	PaymentForm.ApplyOrganization ( ThisObject );

EndProcedure

&AtClient
Procedure ContractOnChange ( Item )
	
	applyContract ();
	
EndProcedure

&AtServer
Procedure applyContract ()
	
	PaymentForm.ApplyContract ( ThisObject );

EndProcedure

&AtClient
Procedure BankAccountOnChange ( Item )
	
	applyBankAccount ();
	
EndProcedure

&AtServer
Procedure applyBankAccount ()
	
	PaymentForm.ApplyBankAccount ( ThisObject );

EndProcedure

&AtClient
Procedure LocationOnChange ( Item )
	
	applyLocation ();
	
EndProcedure

&AtServer
Procedure applyLocation ()
	
	PaymentForm.ApplyLocation ( ThisObject );
	
EndProcedure 

&AtClient
Procedure CurrencyOnChange ( Item )
	
	applyCurrency ();
	
EndProcedure

&AtServer
Procedure applyCurrency () 

	PaymentForm.ApplyCurrency ( ThisObject );

EndProcedure

&AtClient
Procedure RateOnChange ( Item )
	
	PaymentForm.RateOnChange ( ThisObject );
	
EndProcedure

&AtClient
Procedure FactorOnChange ( Item )
	
	PaymentForm.RateOnChange ( ThisObject );
	
EndProcedure

&AtClient
Procedure ContractRateOnChange ( Item )
	
	PaymentForm.ApplyContractRate ( ThisObject );
	
EndProcedure

&AtClient
Procedure ContractFactorOnChange ( Item )
	
	PaymentForm.ApplyContractRate ( ThisObject );
	
EndProcedure

&AtClient
Procedure AmountOnChange ( Item )
	
	PaymentForm.AmountOnChange ( ThisObject );
	
EndProcedure

&AtClient
Procedure MethodOnChange ( Item )
	
	applyMethod ();
	
EndProcedure

&AtServer
Procedure applyMethod ()
	
	PaymentForm.ApplyMethod ( ThisObject );

EndProcedure

&AtClient
Procedure NewReceipt ( Command )
	
	notifyNew = Object.Ref.IsEmpty ();
	createReceipt ();
	PettyCash.Open ( ThisObject, notifyNew );
	
EndProcedure

&AtServer
Procedure createReceipt ()
	
	PettyCash.NewReference ( ThisObject );
	Appearance.Apply ( ThisObject, "Receipt" );
	
EndProcedure 

&AtClient
Procedure ReceiptClick ( Item, StandardProcessing )
	
	PettyCash.ClickProcessing ( ThisObject, StandardProcessing );

EndProcedure

// *****************************************
// *********** Table Documents

&AtClient
Procedure FillPayments ( Command )
	
	Output.PaymentDataUpdateConfirmation ( ThisObject, true );

EndProcedure

&AtClient
Procedure PaymentDataUpdateConfirmation ( Answer, Refilling ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	applyDataUpdate ( Refilling );

EndProcedure

&AtServer
Procedure applyDataUpdate ( val Refilling )
	
	PaymentForm.ApplyDataUpdate ( ThisObject, Refilling );

EndProcedure

&AtClient
Procedure UpdatePayments ( Command )
	
	Output.PaymentDataUpdateConfirmation ( ThisObject, false );
	
EndProcedure

&AtClient
Procedure MarkAll ( Command )
	
	PaymentForm.Mark ( ThisObject, true );
	
EndProcedure

&AtClient
Procedure UnmarkAll ( Command )
	
	PaymentForm.Mark ( ThisObject, false );
	
EndProcedure

&AtClient
Procedure PaymentsOnActivateRow ( Item )
	
	PaymentsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure PaymentsOnEditEnd ( Item, NewRow, CancelEdit )
	
	PaymentForm.PaymentsOnEditEnd ( ThisObject, Item, CancelEdit );

EndProcedure

&AtClient
Procedure PaymentsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure PaymentsAfterDeleteRow ( Item )
	
	PaymentForm.PaymentsAfterDeleteRow ( ThisObject );

EndProcedure

&AtClient
Procedure PaymentsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = not Item.CurrentItem.ReadOnly;
	PaymentForm.Show ( Item );
	
EndProcedure

&AtClient
Procedure PaymentsPayOnChange ( Item )
	
	PaymentForm.ApplyPay ( Object, PaymentsRow );
	
EndProcedure

&AtClient
Procedure PaymentsDiscountRateOnChange ( Item )
	
	PaymentForm.PaymentsDiscountRateOnChange ( PaymentsRow );
	
EndProcedure

&AtClient
Procedure PaymentsDiscountOnChange ( Item )
	
	PaymentForm.PaymentsDiscountOnChange ( PaymentsRow );
	
EndProcedure
