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
		copy = not Parameters.CopyingValue.IsEmpty ();
		if ( ThisObject.Parameters.Basis = undefined ) then
			PaymentForm.FillNew ( ThisObject );
			if ( not copy ) then
				fillByVendor ();
				fillByExpenseReport ();
			endif;
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
	|Employee ExpenseReport show Object.Method = Enum.PaymentMethods.ExpenseReport;
	|Location show Object.Method <> Enum.PaymentMethods.ExpenseReport;
	|Voucher FormVoucher show filled ( Voucher ) and Object.Method = Enum.PaymentMethods.Cash;
	|NewVoucher show empty ( Voucher ) and Object.Method = Enum.PaymentMethods.Cash;
	|Reference ReferenceDate PaymentContent show Object.Method <> Enum.PaymentMethods.Cash;
	|Warning UndoPosting show Object.Posted;
	|Header GroupDocuments GroupCurrency GroupMore lock Object.Posted;
	|Update Refill enable not Object.Posted;
	|GroupIncomeTax show filled ( Object.IncomeTax )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillByVendor ()
	
	if ( not Object.Vendor.IsEmpty () ) then
		applyVendor ();
	endif;
	
EndProcedure 

&AtServer
Procedure applyVendor ()
	
	PaymentForm.SetOrganizationAccounts ( Object );
	PaymentForm.SetContract ( Object );
	applyContract ();
	
EndProcedure

&AtServer
Procedure applyContract ()
	
	PaymentForm.LoadContract ( Object );
	applyMethod ();
	PaymentForm.CalcContractAmount ( Object, 1 );
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
	resetExpenseReport ();
	Appearance.Apply ( ThisObject, "Object.Method" );
	
EndProcedure

&AtServer
Procedure applyBankAccount ()
	
	PaymentForm.SetAccount ( Object );
	PaymentForm.SetCurrency ( Object );
	applyCurrency ();
	
EndProcedure 

&AtServer
Procedure resetExpenseReport () 
	
	if ( Object.Method <> Enums.PaymentMethods.ExpenseReport ) then
		Object.ExpenseReport = undefined;
	endif;
	
EndProcedure

&AtServer
Procedure refill ()
	
	PaymentForm.Refill ( ThisObject );
	
EndProcedure 

&AtServer
Procedure fillByExpenseReport ()
	
	if ( not Object.ExpenseReport.IsEmpty () ) then
		Object.Method = Enums.PaymentMethods.ExpenseReport;
		applyExpenseReport ();
	endif;
	
EndProcedure 

&AtServer
Procedure applyExpenseReport () 
	
	data = DF.Values ( Object.ExpenseReport, "EmployeeAccount, Currency" );
	Object.Account = data.EmployeeAccount;
	Object.Currency = data.Currency;
	applyCurrency ();
	
EndProcedure

&AtServer
Procedure applyCurrency ()
	
	PaymentForm.SetRates ( Object );
	applyRate ( Object );
	Appearance.Apply ( ThisObject, "Object.Currency" );
	
EndProcedure

&AtClientAtServerNoContext
Procedure applyRate ( Object )
	
	PaymentForm.CalcContractAmount ( Object, 1 );
	PaymentForm.DistributeAmount ( Object );
	
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
	
	Notify ( Enum.MessageVendorPaymentIsSaved (), Object );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

&AtClient
Procedure VendorOnChange ( Item )
	
	applyVendor ();
	
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
	
	applyRate ( Object );
	
EndProcedure

&AtClient
Procedure FactorOnChange ( Item )
	
	applyRate ( Object );
	
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
	PaymentForm.CalcHandout ( Object );
	
EndProcedure

&AtClient
Procedure MethodOnChange ( Item )
	
	applyMethod ();
	
EndProcedure

&AtClient
Procedure ExpenseReportOnChange ( Item )
	
	applyExpenseReport ();
	
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
// *********** Group Documents

&AtClient
Procedure IncomeTaxOnChange ( Item )
	
	applyIncomeTax ();
	
EndProcedure

&AtClient
Procedure applyIncomeTax ()
	
	if ( Object.IncomeTax.IsEmpty () ) then
		Object.IncomeTaxRate = 0;
	endif;
	PaymentForm.CalcHandout ( Object );
	Appearance.Apply ( ThisObject, "Object.IncomeTax" );
	
EndProcedure

&AtClient
Procedure IncomeTaxRateOnChange ( Item )
	
	PaymentForm.CalcHandout ( Object );

EndProcedure

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
	PaymentForm.CalcPaymentAmount ( Object );
	
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
