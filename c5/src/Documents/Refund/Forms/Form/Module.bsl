&AtClient
var PaymentsRow export;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	PettyCash.Read ( ThisObject );
	InvoiceForm.SetLocalCurrency ( ThisObject );
	PaymentForm.ToggleDetails ( ThisObject );
	updateChangesPermission ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

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
	|Vendor Contract Company lock filled ( Object.Base );
	|BankAccount show Object.Method <> Enum.PaymentMethods.Cash;
	|Rate Factor enable Object.Currency <> LocalCurrency;
	|ContractRate ContractFactor enable Object.ContractCurrency <> Object.Currency and Object.ContractCurrency <> LocalCurrency;
	|Voucher FormVoucher show filled ( Voucher ) and Object.Method = Enum.PaymentMethods.Cash;
	|NewVoucher show empty ( Voucher ) and Object.Method = Enum.PaymentMethods.Cash;
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
	PaymentForm.SetTitle ( ThisObject );
	refill ();
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
	PaymentForm.DistributeAmount ( object );
	
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
	
	Notify ( Enum.MessageRefundIsSaved (), Object );
	
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
	
EndProcedure

&AtClient
Procedure ContractFactorOnChange ( Item )
	
	PaymentForm.CalcPaymentAmount ( Object );
	
EndProcedure

&AtClient
Procedure AmountOnChange ( Item )
	
	PaymentForm.CalcContractAmount ( Object, 1 );
	PaymentForm.DistributeAmount ( Object );
	
EndProcedure

&AtClient
Procedure MethodOnChange ( Item )
	
	applyMethod ();
	
EndProcedure

&AtClient
Procedure NewVoucher ( Command )
	
	notifyNew = Object.Ref.IsEmpty ();
	createVoucher ();
	PettyCash.Open ( ThisObject, notifyNew );
	
EndProcedure

&AtServer
Procedure createVoucher ()
	
	PettyCash.NewReference ( ThisObject );
	Appearance.Apply ( ThisObject, "Voucher" );
	
EndProcedure 

&AtClient
Procedure VoucherClick ( Item, StandardProcessing )
	
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
		refill ();
	else
		update ();
	endif;
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
	enddo;
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
