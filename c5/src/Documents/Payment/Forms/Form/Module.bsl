&AtClient
var PaymentsRow export;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	PettyCash.Read ( ThisObject );
	InvoiceForm.SetLocalCurrency ( ThisObject );
	PaymentForm.ToggleDetails ( ThisObject );
	updateInfo ( ThisObject );
	Constraints.ShowAccess ( ThisObject );
	Appearance.Apply ( ThisObject );

EndProcedure

&AtClientAtServerNoContext
Procedure updateInfo ( Form )
	
	object = Form.Object;
	difference = object.Amount - object.Applied;
	if ( difference = 0 ) then
		Form.Info = "";
	else
		Form.Info = Output.CustomerPaymentDifference ( new Structure ( "Amount", Conversion.NumberToMoney ( difference, object.Currency ) ) );
	endif;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		InvoiceForm.SetLocalCurrency ( ThisObject );
		DocumentForm.Init ( Object );
		if ( ThisObject.Parameters.Basis = undefined ) then
			PaymentForm.FillNew ( ThisObject );
			fillByCustomer ();
		else
			PaymentForm.Fill ( ThisObject );
		endif; 
		defineCopy ();
		updateInfo ( ThisObject );
		Constraints.ShowAccess ( ThisObject );
	endif; 
	PaymentForm.FilterAccount ( ThisObject );
	PaymentForm.SetTitle ( ThisObject );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Base show filled ( Object.Base );
	|Customer Contract Company lock filled ( Object.Base );
	|BankAccount show Object.Method <> Enum.PaymentMethods.Cash;
	|Rate Factor enable Object.Currency <> LocalCurrency and Object.Currency <> Object.ContractCurrency;
	|ContractRate ContractFactor enable Object.ContractCurrency <> LocalCurrency;
	|NewReceipt show empty ( Receipt ) and Object.Method = Enum.PaymentMethods.Cash
	|	and not field ( Object.Location, ""Register"" );
	|Receipt FormReceipt show filled ( Receipt ) and Object.Method = Enum.PaymentMethods.Cash;
	|Reference ReferenceDate PaymentContent show Object.Method <> Enum.PaymentMethods.Cash;
	|Warning UndoPosting show Object.Posted;
	|Header GroupDocuments GroupCurrency GroupMore lock Object.Posted;
	|GroupFill MarkAll1 UnmarkAll1 enable not Object.Posted
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillByCustomer ()
	
	apply = Parameters.FillingValues.Property ( "Customer" )
	and Parameters.CopyingValue.IsEmpty () 
	and not Object.Customer.IsEmpty ();
	if ( apply ) then
		applyCustomer ();
	endif;
	
EndProcedure 

&AtServer
Procedure applyCustomer ()
	
	PaymentForm.SetOrganizationAccounts ( Object );
	PaymentForm.SetContract ( Object );
	applyContract ();
	
EndProcedure

&AtServer
Procedure applyContract ()
	
	PaymentForm.LoadContract ( Object );
	applyMethod ();
	PaymentForm.CalcContractAmount ( Object, 1 );
	PaymentForm.CalcAppliedAmount ( Object, 1 );
	PaymentForm.SetTitle ( ThisObject );
	refill ();
	updateInfo ( ThisObject );
	Appearance.Apply ( ThisObject, "Object.ContractCurrency" );
	Appearance.Apply ( ThisObject, "Object.Method" );
	
EndProcedure

&AtServer
Procedure applyMethod ()
	
	PaymentForm.SetBankAccount ( Object );
	applyBankAccount ();
	PaymentForm.FilterAccount ( ThisObject );
	Appearance.Apply ( ThisObject, "Object.Method" );
	
EndProcedure

&AtServer
Procedure applyBankAccount ()
	
	PaymentForm.SetAccount ( Object );
	PaymentForm.SetCurrency ( Object );
	applyCurrency ();
	
EndProcedure 

&AtServer
Procedure applyCurrency ()
	
	PaymentForm.SetRates ( Object );
	applyRate ( ThisObject );
	Appearance.Apply ( ThisObject, "Object.Currency" );
	
EndProcedure 

&AtClientAtServerNoContext
Procedure applyRate ( Form )
	
	object = Form.Object;
	PaymentForm.CalcContractAmount ( object, 1 );
	PaymentForm.CalcAppliedAmount ( object, 1 );
	PaymentForm.DistributeAmount ( object );
	updateInfo ( Form );
	
EndProcedure 

&AtServer
Procedure refill ()
	
	PaymentForm.Refill ( ThisObject );
	
EndProcedure 

&AtServer
Procedure defineCopy ()
	
	CopyOf = Parameters.CopyingValue;

EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	passCopy ( CurrentObject );
	PaymentForm.Clean ( CurrentObject.Payments );	

EndProcedure

&AtServer
Procedure passCopy ( CurrentObject )
	
	if ( CurrentObject.IsNew () ) then
		CurrentObject.AdditionalProperties.Insert ( Enum.AdditionalPropertiesCopyOf (), CopyOf ); 
	endif;

EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	PettyCash.Read ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	Notify ( Enum.MessagePaymentIsSaved (), Object );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure CustomerOnChange ( Item )
	
	applyCustomer ();
	
EndProcedure

&AtClient
Procedure ContractOnChange ( Item )
	
	applyContract ();
	
EndProcedure

&AtClient
Procedure BankAccountOnChange ( Item )
	
	applyBankAccount ();
	
EndProcedure

&AtClient
Procedure LocationOnChange ( Item )
	
	applyLocation ();
	
EndProcedure

&AtServer
Procedure applyLocation ()
	
	PaymentForm.SetAccount ( Object );
	PaymentForm.FilterAccount ( ThisObject );
	Appearance.Apply ( ThisObject, "Object.Location" );
	
EndProcedure 

&AtClient
Procedure CurrencyOnChange ( Item )
	
	applyCurrency ();
	
EndProcedure

&AtClient
Procedure RateOnChange ( Item )
	
	applyRate ( ThisObject );
	
EndProcedure

&AtClient
Procedure FactorOnChange ( Item )
	
	applyRate ( ThisObject );
	
EndProcedure

&AtClient
Procedure ContractRateOnChange ( Item )
	
	PaymentForm.CalcPaymentAmount ( Object );
	updateInfo ( ThisObject );
	
EndProcedure

&AtClient
Procedure ContractFactorOnChange ( Item )
	
	PaymentForm.CalcPaymentAmount ( Object );
	updateInfo ( ThisObject );
	
EndProcedure

&AtClient
Procedure AmountOnChange ( Item )
	
	PaymentForm.CalcContractAmount ( Object, 1 );
	PaymentForm.CalcAppliedAmount ( Object, 1 );
	PaymentForm.DistributeAmount ( Object );
	updateInfo ( ThisObject );
	
EndProcedure

&AtClient
Procedure MethodOnChange ( Item )
	
	applyMethod ();
	
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
	if ( Refilling ) then
		PaymentForm.CalcContractAmount ( Object, 1 );
		PaymentForm.CalcAppliedAmount ( Object, 1 );
		refill ();
	else
		update ();
	endif;
	updateInfo ( ThisObject );
	CurrentItem = Items.Payments;

EndProcedure

&AtServer
Procedure update ()
	
	PaymentForm.Update ( ThisObject );
	
EndProcedure

&AtClient
Procedure UpdatePayments ( Command )
	
	Output.PaymentDataUpdateConfirmation ( ThisObject, false );
	
EndProcedure

&AtClient
Procedure MarkAll ( Command )
	
	mark ( true );
	
EndProcedure

&AtClient
Procedure mark ( Flag ) 

	tempRow = PaymentsRow;
	for each row in Object.Payments do
		if ( row.Pay = Flag ) then
			continue;
		endif;
		row.Pay = Flag;
		PaymentsRow = row;
		PaymentForm.ApplyPay ( ThisObject );
		PaymentForm.CalcContractAmount ( Object, 2 );
		PaymentForm.CalcAppliedAmount ( Object, 2 );
	enddo;
	updateInfo ( ThisObject );
	PaymentsRow = tempRow;

EndProcedure

&AtClient
Procedure UnmarkAll ( Command )
	
	mark ( false );
	
EndProcedure

&AtClient
Procedure PaymentsOnActivateRow ( Item )
	
	PaymentsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure PaymentsOnEditEnd ( Item, NewRow, CancelEdit )
	
	if ( not CancelEdit ) then
		PaymentForm.TogglePay ( Item.CurrentData );
	endif;
	calcTotals ();

EndProcedure

&AtClient
Procedure calcTotals ()
	
	PaymentForm.CalcContractAmount ( Object, 2 );
	PaymentForm.CalcAppliedAmount ( Object, 2 );
	updateInfo ( ThisObject );
	
EndProcedure 

&AtClient
Procedure PaymentsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure PaymentsAfterDeleteRow ( Item )
	
	calcTotals ();

EndProcedure

&AtClient
Procedure PaymentsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = not Item.CurrentItem.ReadOnly;
	PaymentForm.Show ( Item );
	
EndProcedure

&AtClient
Procedure PaymentsPayOnChange ( Item )
	
	PaymentForm.ApplyPay ( ThisObject );
	
EndProcedure

&AtClient
Procedure PaymentsDiscountRateOnChange ( Item )
	
	PaymentForm.CalcDiscount ( PaymentsRow );
	PaymentForm.CalcAmount ( PaymentsRow );
	PaymentForm.CalcOverpayment ( PaymentsRow );
	
EndProcedure

&AtClient
Procedure PaymentsDiscountOnChange ( Item )
	
	PaymentForm.CalcDiscountRate ( PaymentsRow );
	PaymentForm.CalcAmount ( PaymentsRow );
	PaymentForm.CalcOverpayment ( PaymentsRow );
	
EndProcedure

&AtClient
Procedure PaymentsAmountOnChange ( Item )
	
	PaymentForm.CalcOverpayment ( PaymentsRow );
	
EndProcedure
