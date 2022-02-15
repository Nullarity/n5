#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Print ( Params, Env ) export
	
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params );
	getData ( Params, Env );
	putHeader ( Params, Env );
	putHeaderTable ( Params, Env );
	putTable ( Params, Env );
	return true;
	
EndFunction
 
Procedure setPageSettings ( Params )
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Portrait;
	tabDoc.FitToPage = true;
	
EndProcedure 

Procedure getData ( Params, Env )
	
	SetPrivilegedMode ( true );
	sqlFields ( Env );
	getFields ( Params, Env );
	defineAmount ( Env );
	sqlBalance ( Env );
	sqlItems ( Env );
	getTables ( Env );
	SetPrivilegedMode ( false );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Number as Number, Documents.Date as Date, Documents.Company.FullDescription as Company, Documents.Currency as CurrencyRef,
	|	Documents.Employee.Description as Employee, Documents.Currency.Description as Currency, Contacts.Name as Accountant,
	|	Documents.Employee as EmployeeRef, isnull ( LastReport.Date, undefined ) as LastDate, 
	|	Documents.EmployeeAccount as EmployeeAccount, Documents.Rate as Rate, Documents.Factor as Factor, Constants.Currency as LocalCurrency,
	|	Documents.Company as CompanyRef, Documents.Description as Purpose
	|from Document.ExpenseReport as Documents
	|	//
	|	// Contacts
	|	//
	|	left join Catalog.Contacts as Contacts
	|	on Contacts.ContactType = value ( Catalog.ContactTypes.Accountant )
	|	and Contacts.Owner = Documents.Company
	|	//
	|	// Constants
	|	//
	|	join Constants as Constants
	|	on true
	|	// 
	|	// Last Expense Report
	|	//
	|	left join 
	|		( 
	|		select top 1 dateadd ( Documents.Date, second, 1 ) as Date, Documents.Ref as Ref
	|		from Document.ExpenseReport as Documents
	|			// 
	|			// Expense Report
	|			//
	|			join Document.ExpenseReport as Report
	|			on Report.Ref = &Ref
	|			and Report.Employee = Documents.Employee
	|			and Report.Currency = Documents.Currency
	|			and Report.Date > Documents.Date
	|		where Documents.Posted
	|		order by Documents.Date desc
	|		) as LastReport
	|	on true
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Params, Env )
	
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure defineAmount ( Env )
	
	fields = Env.Fields;
	amount = "Total";
	vat = "VAT";
	if ( fields.Currency <> fields.LocalCurrency ) then
		rate = " * &Rate / &Factor";
		amount = amount + rate;
		vat = vat + rate;
	endif;
	Env.Insert ( "AmountField", "cast ( " + amount + " as Number ( 15, 2 ) )" );
	Env.Insert ( "VATField", "cast ( " + vat + " as Number ( 15, 2 ) )" );

EndProcedure 

Procedure sqlBalance ( Env )
	
	s = "
	|// #Balances
	|select General.AmountOpeningBalance as InitBalance, General.AmountTurnoverDr as Income, General.Recorder.Date as Date, CashVoucher.Number as Number
	|from AccountingRegister.General.BalanceAndTurnovers ( &LastDate, dateadd ( &Date, second, -1 ), recorder, , Account = &Account, 
	|														value ( ChartOfCharacteristicTypes.Dimensions.Employees ),
	|														Company = &Company
	|														and case when &Currency = &LocalCurrency then Currency is null else Currency = &Currency end
	|														and ExtDimension1 = &Employee ) as General
	|	//
	|	//	CashVoucher
	|	//
	|	left join Document.CashVoucher as CashVoucher
	|	on CashVoucher.Base = General.Recorder
	|where General.Recorder <> undefined
	|order by General.Period desc
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlItems ( Env )
	
	amount = Env.AmountField;
	vat = Env.VATField;
	s = "
	|// Items
	|select Items.Item as Item, " + amount + " as Amount, Items.Account as Account, Items.Date as Date, 
	|	Items.DocumentSeries + Items.Number as Number,	Items.Amount as CurrencyAmount, " + vat + " as VAT
	|into Items
	|from Document.ExpenseReport.Items as Items
	|where Items.Ref = &Ref
	|union all
	|select Items.Item, " + amount + ", Items.Account, Items.Date, Items.DocumentSeries + Items.Number, Items.Amount, " + vat + "
	|from Document.ExpenseReport.Services as Items
	|where Items.Ref = &Ref
	|union all
	|select Items.Item, " + amount + ", Items.Item.Account, Items.Date, Items.DocumentSeries + Items.Number, Items.Amount, " + vat + " 
	|from Document.ExpenseReport.FixedAssets as Items
	|where Items.Ref = &Ref
	|union all
	|select Items.Item, " + amount + ", Items.Item.Account, Items.Date, Items.DocumentSeries + Items.Number, Items.Amount, " + vat + " 
	|from Document.ExpenseReport.IntangibleAssets as Items
	|where Items.Ref = &Ref
	|union all
	|select Items.Dim1, " + amount + ", Items.Account, Items.Date, Items.DocumentSeries + Items.Number, Items.Amount, " + vat + " 
	|from Document.ExpenseReport.Accounts as Items
	|where Items.Ref = &Ref
	|;
	|// Payments
	|select Documents.Vendor.FullDescription + case Documents.PaymentContent when """" then """" else "", "" + Documents.PaymentContent end as Item,
	|	Documents.VendorAccount.Code as Account,
	|	case when Documents.Reference = """" then Documents.Number else Documents.Reference end as Number,
	|	case when Documents.ReferenceDate = datetime ( 1, 1, 1 ) then Documents.Date else Documents.ReferenceDate end as Date,
	|	case when Documents.Currency = &LocalCurrency then Documents.Total else Documents.Total * Documents.Rate / Documents.Factor end as Amount,
	|	case when Documents.Currency = &Currency then 
	|			Documents.Total
	|		 else case when Documents.Currency = &LocalCurrency then 
	|				   		Documents.Total 
	|				   else Documents.Total * Documents.Rate / Documents.Factor 
	|			  end / &Rate * &Factor
	|	end as CurrencyAmount
	|into Payments
	|from Document.VendorPayment as Documents
	|where Documents.Posted
	|and Documents.ExpenseReport = &Ref
	|;
	|// #Items
	|select Items.Item.Description as Item, Items.Amount as Amount, Items.Account.Code as Account, Items.Date as Date, 
	|	Items.Number as Number, case when &Currency = &LocalCurrency then 0 else Items.CurrencyAmount end as CurrencyAmount,
	|	Items.VAT as VAT
	|from Items as Items
	|union all
	|select Items.Item, Items.Amount, Items.Account, Items.Date, Items.Number,
	|	case when &Currency = &LocalCurrency then 0 else Items.CurrencyAmount end, 0
	|from Payments as Items
	|order by Account, Date, Number, Item
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables ( Env )
	
	fields = Env.Fields;
	q = Env.Q;
	q.SetParameter ( "Currency", fields.CurrencyRef );
	q.SetParameter ( "LocalCurrency", fields.LocalCurrency );
	q.SetParameter ( "Employee", fields.EmployeeRef );
	q.SetParameter ( "Company", fields.CompanyRef );
	q.SetParameter ( "Account", fields.EmployeeAccount );
	q.SetParameter ( "Rate", fields.Rate );
	q.SetParameter ( "Date", fields.Date );
	q.SetParameter ( "LastDate", fields.LastDate );
	q.SetParameter ( "Factor", fields.Factor );
	SQL.Prepare ( Env );
	Env.Insert ( "Data", q.ExecuteBatch () );
	SQL.Unload ( Env, Env.Data );
	
EndProcedure 

Procedure putHeader ( Params, Env )
	
	area = Env.T.GetArea ( "Header" );
	fields = Env.Fields;
	p = area.Parameters;
	p.Fill ( fields );
	date = fields.Date;
	p.Date = Format ( date, "DLF=D" );
	p.Year = Format ( date, "DF=yyyy" );
	fillIncome ( Env.Balances, p );
	items = Env.Items;
	fillAccounts ( items, p );
	amount = items.Total ( "Amount" );
	p.Amount = amount;
	p.AmountInWords = Conversion.AmountToWords ( amount );
	intAmount = Int ( amount );
	p.AmountLei = Format ( intAmount, "NG=" );
	p.AmountBani = Format ( ( amount - intAmount ) * 100, "NZ=00" );
	p.DocumentsCount = getDocumentsCount ( items );
	difference = p.InitBalance + p.Income - amount;
	if ( difference > 0 ) then
		p.Balance = difference;
	else
		p.Overspending = -difference;
	endif;
	tabDoc = Params.TabDoc;
	tabDoc.Put ( area );
	Env.Insert ( "Amount", amount );
	
EndProcedure

Procedure fillIncome ( Balances, AreaParams ) 

	count = Balances.Count ();
	initBalance = 0;
	for i = 1 to count do
		row = Balances [ i - 1 ];
		if ( i <= 3 ) then
			AreaParams [ "Number" + i ] = row.Number;
			AreaParams [ "Date" + i ] = row.Date;
			AreaParams [ "Income" + i ] = row.Income;
		endif;
		if ( i = count ) then
			initBalance = row.InitBalance;
		endif;
	enddo;
	AreaParams.InitBalance = initBalance;
	AreaParams.Income = Balances.Total ( "Income" );

EndProcedure

Procedure fillAccounts ( Table, AreaParams ) 

	accounts = Table.Copy ();
	accounts.GroupBy ( "Account", "Amount" );
	count = accounts.Count ();
	for i = 1 to count do
		row = accounts [ i - 1 ];
		AreaParams [ "Account" + i ] = row.Account;
		AreaParams [ "Amount" + i ] = row.Amount;
	enddo;

EndProcedure

Function getDocumentsCount ( Table ) 

	documentsTable = Table.Copy ();
	documentsTable.GroupBy ( "Date, Number" );
	return documentsTable.Count ();

EndFunction

Procedure putHeaderTable ( Params, Env ) 

	fields = Env.Fields;
	t = Env.T;
	area = t.GetArea ( "Table" );
	if ( fields.CurrencyRef <> fields.LocalCurrency ) then
		area.Parameters.Currency = fields.Currency;
	endif;
	tabDoc = Params.TabDoc;
	tabDoc.Put ( area );
	Print.Repeat ( tabDoc, 4 );
	
EndProcedure

Procedure putTable ( Params, Env ) 

	t = Env.T;
	area = t.GetArea ( "Row" );
	p = area.Parameters;
	tabdoc = Params.TabDoc;
	table = Env.Items;
	for each row in table do
		p.Fill ( row );
		tabdoc.Put ( area );
	enddo;
	area = t.GetArea ( "Footer" );
	p = area.Parameters;
	p.Amount = Env.Amount;
	p.CurrencyAmount = table.Total ( "CurrencyAmount" );
	tabdoc.Put ( area );
	
EndProcedure

#endif