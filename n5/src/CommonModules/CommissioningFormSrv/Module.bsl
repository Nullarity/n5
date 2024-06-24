
Function GetAmount ( val Params ) export
	
	s = "
	|select Balances.AmountBalance as Amount
	|from AccountingRegister.General.Balance ( &Date, Account = &Account, ,
	|	ExtDimension1 = &Item and Company = &Company ) as Balances
	|";
	q = new Query ( s );
	q.SetParameter ( "Date", Params.Date );
	q.SetParameter ( "Item", Params.Item );
	q.SetParameter ( "Company", Params.Company );
	q.SetParameter ( "Account", Params.Account );
	return q.Execute ().Unload () [ 0 ].Amount;
	
EndFunction
