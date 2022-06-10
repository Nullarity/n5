#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
Function GetDefaults ( Organization ) export
	
	s = "
	|// @BankAccount
	|select top 1 Accounts.Ref as Ref
	|from Catalog.BankAccounts as Accounts
	|where Accounts.Owner = &Organization
	|and not Accounts.DeletionMark
	|order by Accounts.Code desc
	|;
	|// @VATAdvance
	|select Settings.Value as Value
	|from InformationRegister.Settings.SliceLast ( ,
	|	Parameter = value ( ChartOfCharacteristicTypes.Settings.VATAdvance )
	|) as Settings
	|";
	q = new Query ( s );
	q.SetParameter ( "Organization", Organization );
	data = SQL.Exec ( q );
	bank = ? ( data.BankAccount = undefined, undefined, data.BankAccount.Ref );
	advance = ? ( data.VATAdvance = undefined, undefined, data.VATAdvance.Value );
	return new Structure ( "BankAccount, VATAdvance", bank, advance );

EndFunction

#endif