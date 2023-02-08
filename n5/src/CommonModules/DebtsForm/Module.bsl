&AtServer
Procedure OnReadAtServer ( Form ) export
	
	InvoiceForm.SetLocalCurrency ( Form );
	Appearance.Apply ( Form );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Form ) export

	object = Form.Object;
	if ( object.Ref.IsEmpty () ) then
		copy = not Form.Parameters.CopyingValue.IsEmpty ();
		if ( copy ) then
			BalancesForm.FixDate ( Form );
		else
			BalancesForm.CheckParameters ( Form );
		endif;
		InvoiceForm.SetLocalCurrency ( Form );
		DocumentForm.SetCreator ( object );
		if ( not copy ) then
			object.Currency = Form.LocalCurrency;
		endif;
	endif; 
	Options.Company ( Form, object.Company );
	StandardButtons.Arrange ( Form );
	readAppearance ( Form );
	Appearance.Apply ( Form );
	
EndProcedure

&AtServer
Procedure readAppearance ( Form )

	rules = new Array ();
	rules.Add ( "
	|DebtsTotalAmount DebtsTotalContractAmount show not Object.Advances;
	|DebtsTotalAdvance DebtsTotalContractAdvance show Object.Advances;
	|DebtsTotalContractAmount show ( Object.Currency <> LocalCurrency and not Object.Advances );
	|DebtsTotalContractAdvance show ( Object.Currency <> LocalCurrency and Object.Advances );
	|DebtsAmount DebtsContractAmount show not Object.Advances;
	|DebtsAdvance DebtsContractAdvance show Object.Advances;
	|DebtsContractAmount show ( Object.Currency <> LocalCurrency and not Object.Advances );
	|DebtsContractAdvance show ( Object.Currency <> LocalCurrency and Object.Advances );
	|AdvanceAccount hide Object.Advances;" );
	if ( TypeOf ( Form.Object.Ref ) = Type ( "DocumentRef.Debts" ) ) then
		rules.Add ( "
		|CustomerAccount VATAccount ReceivablesVATAccount VATAdvance show Object.Advances;
		|" );
	else
		rules.Add ( "
		|VendorAccount show Object.Advances;
		|" );
	endif;
	Appearance.Read ( Form, rules );

EndProcedure

&AtServer
Procedure ApplyAccount ( Form ) export

	object = Form.Object;
	account = object.Account;
	type = DF.Pick ( account, "Type" );
	if ( TypeOf ( object.Ref ) = Type ( "DocumentRef.VendorDebts" ) ) then
		data = AccountsMap.Organization ( Catalogs.Organizations.EmptyRef (), object.Company,
			"VendorAccount, AdvanceGiven" );
		advances = ( type = AccountType.Active );
		object.Advances = advances;
		if ( advances ) then
			object.AdvanceAccount = account;
			object.VendorAccount = data.VendorAccount;
		else
			object.VendorAccount = account;
			object.AdvanceAccount = data.AdvanceGiven;
		endif;
	else
		data = AccountsMap.Organization ( Catalogs.Organizations.EmptyRef (), object.Company,
			"CustomerAccount, AdvanceTaken" );
		advances = ( type = AccountType.Passive );
		object.Advances = advances;
		if ( advances ) then
			PaymentForm.SetVATAdvance ( object );
			object.VATAdvance = Constants.ItemsVAT.Get ();
			object.AdvanceAccount = account;
			object.CustomerAccount = data.CustomerAccount;
		else
			object.VATAccount = undefined;
			object.ReceivablesVATAccount = undefined;
			object.VATAdvance = undefined;
			object.CustomerAccount = account;
			object.AdvanceAccount = data.AdvanceTaken;
		endif;
	endif;
	Appearance.Apply ( Form, "Object.Advances" );

EndProcedure

&AtClient
Procedure DebtsAmountOnChange ( Form ) export
	
	if ( isLocalCurrency ( Form ) ) then
		return;
	endif;
	debtsRow = Form.DebtsRow;
	debtsRow.ContractAmount = debtsRow.Amount;
	
EndProcedure

&AtClient
Function isLocalCurrency ( Form )

	return Form.Object.Currency = Form.LocalCurrency;

EndFunction

&AtClient
Procedure DebtsAdvanceOnChange ( Form ) export
	
	if ( isLocalCurrency ( Form ) ) then
		return;
	endif;
	debtsRow = Form.DebtsRow;
	debtsRow.ContractAdvance = debtsRow.Advance;
	
EndProcedure

&AtClient
Procedure CalcTotals ( Form ) export
	
	object = Form.Object;
	object.Amount = object.Debts.Total ( ? ( object.Advances, "Advance", "Amount" ) );
	
EndProcedure

&AtServer
Procedure FillCheckProcessing ( Object, Cancel, CheckedAttributes ) export
	
	checkAccounts ( Object, CheckedAttributes );
	checkAmount ( Object, CheckedAttributes );
	
EndProcedure

&AtServer
Procedure checkAccounts ( Object, CheckedAttributes )
	
	if ( Object.Advances ) then
		CheckedAttributes.Add (
			? ( TypeOf ( Object.Ref ) = Type ( "DocumentRef.Debts" ), "CustomerAccount", "VendorAccount" ) );
	else
		CheckedAttributes.Add ( "AdvanceAccount" );
	endif;

EndProcedure

&AtServer
Procedure checkAmount ( Object, CheckedAttributes )

	field = ? ( object.Advances, "Advance", "Amount" );
	CheckedAttributes.Add ( "Debts." + field );
	if ( Object.Currency <> Application.Currency () ) then
		CheckedAttributes.Add ( "Debts.Contract" + field );
	endif;

EndProcedure