&AtClient
var AdjustmentsRow export;
&AtClient
var ReceiverRow export;
&AtServer
var AccountData export;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	AdjustDebtsForm.OnReadAtServer ( ThisObject );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	AdjustDebtsForm.OnCreateAtServer ( ThisObject );
	
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
	
	AdjustDebtsForm.BeforeWriteAtServer ( CurrentObject, ThisObject );

EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject );
	
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

	AdjustDebtsForm.ApplyCustomer ( ThisObject );

EndProcedure

&AtClient
Procedure ContractOnChange ( Item )
	
	applyContract ();
	
EndProcedure

&AtServer
Procedure applyContract () 

	AdjustDebtsForm.ApplyContract ( ThisObject );

EndProcedure

&AtClient
Procedure CurrencyOnChange ( Item )
	
	applyCurrency ();
	
EndProcedure

&AtServer
Procedure applyCurrency () 

	AdjustDebtsForm.ApplyCurrency ( ThisObject );

EndProcedure

&AtClient
Procedure RateOnChange ( Item )
	
	AdjustDebtsForm.RateOnChange ( ThisObject );
	
EndProcedure

&AtClient
Procedure FactorOnChange ( Item )
	
	AdjustDebtsForm.FactorOnChange ( ThisObject );
	
EndProcedure

&AtClient
Procedure ContractRateOnChange ( Item )
	
	AdjustDebtsForm.CalcPaymentAmount ( Object );
	
EndProcedure

&AtClient
Procedure ContractFactorOnChange ( Item )
	
	AdjustDebtsForm.CalcPaymentAmount ( Object );
	
EndProcedure

&AtClient
Procedure AmountOnChange ( Item )
	
	AdjustDebtsForm.AmountOnChange ( ThisObject );
	
EndProcedure

&AtClient
Procedure AccountOnChange ( Item )
	
	applyAccount ();
	
EndProcedure

&AtServer
Procedure applyAccount () 

	AdjustDebtsForm.ApplyAccount ( ThisObject );

EndProcedure

&AtClient
Procedure OptionOnChange ( Item )
	
	applyOption ();
	
EndProcedure

&AtServer
Procedure applyOption () 

	AdjustDebtsForm.ApplyOption ( ThisObject );

EndProcedure

&AtClient
Procedure TypeOnChange ( Item )
	
	applyType ();
	
EndProcedure

&AtServer
Procedure applyType () 

	AdjustDebtsForm.ApplyType ( ThisObject );

EndProcedure

&AtClient
Procedure ReceiverOnChange ( Item )
	
	applyReceiver ();
	
EndProcedure

&AtServer
Procedure applyReceiver () 

	AdjustDebtsForm.ApplyReceiver ( ThisObject );

EndProcedure

&AtClient
Procedure ReceiverContractFactorOnChange ( Item )
	
	AdjustDebtsForm.ReceiverContractFactorOnChange ( ThisObject );
	
EndProcedure

&AtClient
Procedure ReceiverContractRateOnChange ( Item )
	
	AdjustDebtsForm.ReceiverContractRateOnChange ( ThisObject );
	
EndProcedure

&AtClient
Procedure ReceiverContractOnChange ( Item )
	
	applyReceiverContract ();
	
EndProcedure

&AtServer
Procedure applyReceiverContract () 

	AdjustDebtsForm.ApplyReceiverContract ( ThisObject );

EndProcedure

// *****************************************
// *********** Table Documents

&AtClient
Procedure FillAdjustments ( Command )
	
	Output.AdjustmentDataUpdateConfirmation ( ThisObject, true );

EndProcedure

&AtClient
Procedure AdjustmentDataUpdateConfirmation ( Answer, Refilling ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	applyAdjustmentDataUpdate ( Refilling );

EndProcedure

&AtServer
Procedure applyAdjustmentDataUpdate ( Refilling ) 

	AdjustDebtsForm.AdjustmentDataUpdateConfirmation ( ThisObject, Refilling );

EndProcedure

&AtClient
Procedure UpdateAdjustments ( Command )
	
	Output.AdjustmentDataUpdateConfirmation ( ThisObject, false );
	
EndProcedure

&AtClient
Procedure MarkAll ( Command )
	
	AdjustDebtsForm.Mark ( ThisObject, true );
	
EndProcedure

&AtClient
Procedure UnmarkAll ( Command )
	
	AdjustDebtsForm.Mark ( ThisObject, false );
	
EndProcedure

&AtClient
Procedure AdjustmentsOnActivateRow ( Item )
	
	AdjustmentsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure AdjustmentsOnEditEnd ( Item, NewRow, CancelEdit )
	
	AdjustDebtsForm.AdjustmentsOnEditEnd ( ThisObject, Item, CancelEdit );

EndProcedure

&AtClient
Procedure AdjustmentsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure AdjustmentsAfterDeleteRow ( Item )
	
	AdjustDebtsForm.CalcTotals ( ThisObject );

EndProcedure

&AtClient
Procedure AdjustmentsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	AdjustDebtsForm.AdjustmentsSelection ( Item, StandardProcessing );
	
EndProcedure

&AtClient
Procedure AdjustmentsAdjustOnChange ( Item )
	
	AdjustDebtsForm.ApplyAdjust ( ThisObject );
	
EndProcedure

&AtClient
Procedure AdjustmentsAmountOnChange ( Item )
	
	AdjustDebtsForm.AdjustmentsAmountOnChange ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Table Receiver Documents

&AtClient
Procedure FillReceiver ( Command )
	
	Output.AdjustmentDataUpdateConfirmation ( ThisObject, true, , "ReceiverDataUpdateConfirmation" );
	
EndProcedure

&AtClient
Procedure ReceiverDataUpdateConfirmation ( Answer, Refilling ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	applyReceiverDataUpdate ( Refilling );

EndProcedure

&AtServer
Procedure applyReceiverDataUpdate ( Refilling ) 

	AdjustDebtsForm.ReceiverDataUpdateConfirmation ( ThisObject, Refilling );

EndProcedure

&AtClient
Procedure UpdateReceiver ( Command )
	
	Output.AdjustmentDataUpdateConfirmation ( ThisObject, false, , "ReceiverDataUpdateConfirmation" );
	
EndProcedure

&AtClient
Procedure MarkAllReceiver ( Command )
	
	AdjustDebtsForm.MarkReceiver ( ThisObject, true );
	
EndProcedure

&AtClient
Procedure UnmarkAllReceiver ( Command )
	
	AdjustDebtsForm.MarkReceiver ( ThisObject, false );
	
EndProcedure

&AtClient
Procedure ReceiverDebtsOnActivateRow ( Item )
	
	ReceiverRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ReceiverDebtsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	AdjustDebtsForm.ReceiverDebtsSelection ( Item, StandardProcessing );
	
EndProcedure

&AtClient
Procedure ReceiverDebtsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure ReceiverDebtsOnEditEnd ( Item, NewRow, CancelEdit )
	
	AdjustDebtsForm.ReceiverDebtsOnEditEnd ( ThisObject, Item, CancelEdit );

EndProcedure

&AtClient
Procedure ReceiverDebtsAfterDeleteRow ( Item )
	
	AdjustDebtsForm.CalcTotalsReceiver ( ThisObject );
	
EndProcedure

&AtClient
Procedure ReceiverDebtsAdjustOnChange ( Item )
	
	AdjustDebtsForm.ApplyReceiverAdjust ( ThisObject );
	
EndProcedure

&AtClient
Procedure ReceiverDebtsAmountOnChange ( Item )
	
	AdjustDebtsForm.ReceiverDebtsAmountOnChange ( ThisObject );
	
EndProcedure
