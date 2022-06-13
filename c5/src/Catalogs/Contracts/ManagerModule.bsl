#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function GetDefaults ( Organization, ForCustomer ) export
	
	s = "
	|// @BankAccount
	|select top 1 Accounts.Ref as Ref
	|from Catalog.BankAccounts as Accounts
	|where Accounts.Owner = &Organization
	|and not Accounts.DeletionMark
	|order by Accounts.Code desc
	|";
	if ( ForCustomer ) then
		s = s + "
		|;
		|// @VATAdvance
		|select Settings.Value as Value
		|from InformationRegister.Settings.SliceLast ( ,
		|	Parameter = value ( ChartOfCharacteristicTypes.Settings.VATAdvance )
		|) as Settings
		|";
	endif;
	q = new Query ( s );
	q.SetParameter ( "Organization", Organization );
	data = SQL.Exec ( q );
	result = new Structure ( "BankAccount, VATAdvance" );
	result.BankAccount = ? ( data.BankAccount = undefined, undefined, data.BankAccount.Ref );
	if ( ForCustomer ) then
		result.VATAdvance = ? ( data.VATAdvance = undefined, undefined, data.VATAdvance.Value );
	endif;
	return result;

EndFunction

#region Printing

Function Print ( Params, Env ) export
	
	getPrintData ( Params, Env );
	if ( not templateDefined ( Params, Env ) ) then
		return false;
	endif;
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params );
	putContract ( Params, Env );
	return true;
	
EndFunction

Function templateDefined ( Params, Env )
	
	template = undefined;
	form = Env.Fields.Template;
	if ( form <> null ) then
		template = form.Get ();
	endif;
	if ( template = undefined ) then
		Output.FieldIsEmpty ( , "Template", Params.Reference );
		return false;
	endif;
	Env.Insert ( "T", template );
	return true;

EndFunction
 
Procedure setPageSettings ( Params )
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Portrait;
	tabDoc.FitToPage = true;
	
EndProcedure 

Procedure getPrintData ( Params, Env )
	
 	sqlPrintData ( Env );
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env, false );
	
EndProcedure

Procedure sqlPrintData ( Env )
	
	s = "
	|select top 1 Contacts.Name as Director
	|into Contacts
	|from Catalog.Contacts as Contacts
	|where Contacts.Owner in ( select Owner from Catalog.Contracts where Ref = &Ref )
	|and Contacts.ContactType = value ( Catalog.ContactTypes.Director )
	|;
	|// @Fields
	|select Contracts.Description as Number, Contracts.DateStart as Date, Contracts.Owner.FullDescription as Customer,
	|	Contracts.Owner.Responsible.FullName as Manager, Contacts.Director as CustomerDirector,
	|	Contracts.Owner.PaymentAddress.Presentation as CustomerAddress, Contracts.Owner.CodeFiscal as CodeFiscal,
	|	Contracts.Owner.VATCode as VATCode, Contracts.CustomerBank.Bank.Code as CustomerBankCode,
	|	Contracts.CustomerBank.Bank.Presentation as CustomerBank, Contracts.CustomerBank.AccountNumber as CustomerBankAccount,
	|	Contracts.Owner.Phone as CustomerPhone, Contracts.Owner.Fax as CustomerFax, Contracts.Owner.Email as CustomerEmail,
	|	Contracts.Template.Table as Template
	|from Catalog.Contracts as Contracts
	|	//
	|	// Contacts
	|	//
	|	left join Contacts as Contacts
	|	on true
	|where Contracts.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure putContract ( Params, Env )
	
	fields = Env.Fields;
	area = Env.T.GetArea ();
	p = area.Parameters;
	p.Fill ( fields );
	Params.TabDoc.Put ( area );
	
EndProcedure

#endregion

#endif