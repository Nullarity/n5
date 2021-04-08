&AtServer
Procedure OnReadAtServer ( Form ) export
	
	Form.Advances = isAdvances ( Form.Object );
	InvoiceForm.SetLocalCurrency ( Form );
	Appearance.Apply ( Form );
	
EndProcedure

&AtServer
Function isAdvances ( Object ) 

	type = DF.Pick ( Object.Account, "Type" );
	if ( TypeOf ( Object.Ref ) = Type ( "DocumentRef.Debts" ) ) then
		return type = AccountType.Passive;
	else
		return type = AccountType.Active;
	endif;

EndFunction

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
		Form.Advances = isAdvances ( object );
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
	|DebtsTotalAmount DebtsTotalContractAmount show not Advances;
	|DebtsTotalAdvance DebtsTotalContractAdvance show Advances;
	|DebtsTotalContractAmount show ( Object.Currency <> LocalCurrency and not Advances );
	|DebtsTotalContractAdvance show ( Object.Currency <> LocalCurrency and Advances );
	|DebtsAmount DebtsContractAmount show not Advances;
	|DebtsAdvance DebtsContractAdvance show Advances;
	|DebtsContractAmount show ( Object.Currency <> LocalCurrency and not Advances );
	|DebtsContractAdvance show ( Object.Currency <> LocalCurrency and Advances )
	|" );
	Appearance.Read ( Form, rules );

EndProcedure

&AtServer
Procedure ApplyAccount ( Form ) export

	Form.Advances = isAdvances ( Form.Object );
	Appearance.Apply ( Form, "Advances" );

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
	object.Amount = object.Debts.Total ( ? ( Form.Advances, "Advance", "Amount" ) );
	
EndProcedure

&AtServer
Procedure CheckAmount ( Object, CheckedAttributes ) export

	field = ? ( isAdvances ( Object ), "Advance", "Amount" );
	CheckedAttributes.Add ( "Debts." + field );
	if ( Object.Currency <> Application.Currency () ) then
		CheckedAttributes.Add ( "Debts.Contract" + field );
	endif;

EndProcedure