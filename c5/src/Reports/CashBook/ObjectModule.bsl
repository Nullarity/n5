#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;
var Env;
var TabDoc;
var DateStart;
var DateEnd;
var Company;
var Currency;
var ByCurrency;
var LocalCurrency;
var PutCover;
var Cash;
var AreasRows;
var AreasHeader;
var AreasFooter;
var Page;
var TabDocPages;
var Records;
var Day;
var Receipt;
var Expense;
var Areas;
var PagesMonth;
var PagesDay;
var AddPagesMonth;
var AddPagesYear;
var Balances;

Procedure OnCheck ( Cancel ) export
	
	readParams ();
	if ( not checkCompany () ) then
		Cancel = true;
	endif;
	if ( not checkPeriod () ) then
		Cancel = true;
	endif; 
	
EndProcedure 

Procedure readParams ()
	
	settings = Params.Composer.GetSettings ();
	Company = DC.GetParameter ( settings, "Company" ).Value;
	Currency = DC.GetParameter ( settings, "Currency" ).Value;
	value = DC.GetParameter ( settings, "PutCover" ).Value;
	PutCover = ? ( ValueIsFilled ( value ), value, false );
	value = DC.GetParameter ( settings, "Period" ).value;
	if ( ValueIsFilled ( value ) ) then
		DateStart = value.StartDate;
		DateEnd = value.EndDate;
	endif;
	
EndProcedure 

Function checkCompany () 

	if ( ValueIsFilled ( Company ) ) then
		return true;
	endif;
	Output.CompanyEmpty ();
	return false;

EndFunction

Function checkPeriod ()
	
	if ( DateStart <> undefined )
		and ( Year ( DateStart ) = Year ( DateEnd ) ) then
		return true;
	endif;
	Output.PeriodYearError ();
	return false;

EndFunction 

Procedure AfterOutput () export

	init ();
	print ();

EndProcedure

Procedure init () 

	applicationCurrency = Application.Currency ();
	LocalCurrency = String ( applicationCurrency );
	ByCurrency = ValueIsFilled ( Currency ) and Currency <> applicationCurrency;
	initEnv ();
	initTabDocs ();
	initAreas ();
	
EndProcedure

Procedure initEnv () 

	Env = new Structure ();
	SQL.Init ( Env );
	Env.Insert ( "T", GetTemplate ( "CashBook" ) );

EndProcedure

Procedure initTabDocs () 

	TabDoc = Params.Result;
	TabDocPages = new SpreadsheetDocument ();

EndProcedure

Procedure initAreas () 

	AreasRows = new ValueTable ();
	columns = AreasRows.Columns;
	columns.Add ( "Area" );
	columns.Add ( "Receipt" );
	columns.Add ( "Expense" );
	AreasHeader = new Array ();
	AreasFooter = new Array ();

EndProcedure

#Region Print

Function print ()
	
	Print.SetFooter ( TabDoc );
	setPageSettings ();
	getData ();
	if ( PutCover ) then
		putFirstPage ();
	endif;
	putPages ();
	if ( PutCover ) then
		putLastPage ();
	endif;
	return true;
	
EndFunction
 
Procedure setPageSettings ()
	
	TabDoc.PageOrientation = PageOrientation.Landscape;
	TabDoc.FitToPage = true;
	FillPropertyValues ( TabDocPages, TabDoc );
	
EndProcedure 

Procedure getData ()
	
	sqlFields ();
	sqlCash ();
	sqlAccounts ();
	sqlBalances ();
	getTables ()
	
EndProcedure

Procedure sqlFields ()
	
	s = "
	|// Documents
	|select Roles.Ref as Ref, Roles.Role as Role
	|into Documents
	|from Document.Roles as Roles
	|where not Roles.DeletionMark
	|and Roles.Action = value ( Enum.AssignRoles.Assign )
	|and Roles.Company = &Company
	|and Roles.Role in ( value ( Enum.Roles.AccountantChief ), value ( Enum.Roles.GeneralManager ) )
	|;
	|// Roles
	|select Roles.User.Employee.Individual as Individual, Roles.Role as Role
	|into Roles
	|from Document.Roles as Roles
	|	//
	|	// Last changes
	|	//
	|	join (
	|		select Roles.Role as Role, max ( Roles.Date ) as Date
	|		from Document.Roles as Roles
	|		where Roles.Ref in ( select Ref from Documents )
	|		group by Roles.Role
	|	) as LastChanges
	|	on LastChanges.Role = Roles.Role
	|	and LastChanges.Date = Roles.Date
	|where Roles.Ref in ( select Ref from Documents )
	|;
	|// @Fields
	|select allowed Companies.FullDescription as Company, Companies.CodeFiscal as CodeFiscal, RolesAccountant.Accountant as Accountant, 
	|	RolesDirector.Director as Director, isnull ( Pages.Page, 0 ) as Page,
	|	isnull ( Pages.PagesMonth, 0 ) as PagesMonth
	|from Catalog.Companies as Companies
	|	//
	|	// Accountant
	|	//
	|	left join ( 
	|		select Roles.Individual.Description as Accountant
	|		from Roles as Roles
	|		where Roles.Role = value ( Enum.Roles.AccountantChief )
	|		) as RolesAccountant
	|	on true
	|	//
	|	// Director
	|	//
	|	left join ( 
	|		select Roles.Individual.Description as Director
	|		from Roles as Roles
	|		where Roles.Role = value ( Enum.Roles.GeneralManager )
	|		) as RolesDirector
	|	on true
	| 	//
	| 	// Pages
	| 	//
	|	left join (
	|		select sum ( Pages.Page ) as Page, 
	|			sum ( case when beginofperiod ( Pages.Period, month ) = beginofperiod ( &DateStart, month ) then Pages.Page else 0 end ) as PagesMonth
	|		from InformationRegister.CashBookPages as Pages
	|		where Pages.Company = &Company
	|		and Pages.Period < &DateStart
	|		and beginofperiod ( Pages.Period, year ) = beginofperiod ( &DateStart, year )
	|		) as Pages
	|	on true
	|where Companies.Ref = &Company
	|";
 	Env.Selection.Add ( s );    
	
EndProcedure

Procedure sqlCash ()
	
	s = "
	|// Cash
	|select allowed Receipt.Giver as GiverReceiver, Receipt.Base as Base, Receipt.Number as Number, true as Receipt,
	|	Receipt.Amount as Amount
	|into Cash
	|from Document.CashReceipt as Receipt
	|where Receipt.Posted
	|and Receipt.Date between &DateStart and &DateEnd
	|and Receipt.Company = &Company
	|union all
	|select Voucher.Receiver, Voucher.Base, Voucher.Number, false, Voucher.Amount
	|from Document.CashVoucher as Voucher
	|where Voucher.Posted
	|and Voucher.Date between &DateStart and &DateEnd
	|and Voucher.Company = &Company
	|;
	|// #Cash
	|select allowed General.DayPeriod as Day, isnull ( Cash.Base.Date, General.Recorder.Date ) as Date,
	|	isnull ( Cash.Base, General.Recorder ) as Base,
	|	case valuetype ( General.Recorder )
	|		when type ( Document.RetailSales ) then Cash.Amount
	|		else General.AmountTurnoverDr
	|	end as Receipt,
	|	General.AmountTurnoverCr as Expense, General.MonthPeriod as Month,
	|	isnull ( Cash.Number, General.Recorder.Number ) as Number, General.CurrencyAmountTurnoverDr as ReceiptCurrency, 
	|	General.CurrencyAmountTurnoverCr as ExpenseCurrency, Cash.GiverReceiver as GiverReceiver,
	|	isnull ( Cash.Receipt, General.AmountTurnoverDr > 0 ) as IsReceipt,
	|	isnull ( General.Currency.Description, Constants.Currency.Description ) as Currency,
	|	isnull ( General.Currency.FullDescription, Constants.Currency.FullDescription ) as FullCurrency
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, auto,
	|	Account.Class = value ( Enum.Accounts.Cash ) and Account.Currency = &ByCurrency, , 
	|	ExtDimension1 in (
	|		select Ref from Catalog.PaymentLocations where not Remote and Owner = &Company
	|		union all select value ( Catalog.PaymentLocations.EmptyRef )
	|	)
	|	and Company = &Company
	|";
	if ( ByCurrency ) then
		s = s + "and Currency = &Currency";
	endif;
	s =  s + " 
	|	) as General
	|	//
	|	// Cash
	|	//
	|	join Cash as Cash
	|	on Cash.Base = General.Recorder
	|	//
	|	// Constants
	|	//
	|	left join Constants as Constants
	|	on true
	|order by General.SecondPeriod, isnull ( Cash.Number, Recorder.Number )
	|";
	Env.Selection.Add ( s );    
	
EndProcedure

Procedure sqlAccounts ()
	
	s = "
	|// #Accounts
	|select distinct case when Cash.Receipt then Entry.AccountCr.Code else Entry.AccountDr.Code end as Account, Cash.Base as Base
	|from Document.Entry.Records as Entry
	| 	//
	| 	//	Cash
	| 	//
	| 	join Cash as Cash
	| 	on Cash.Base = Entry.Ref
	|union all
	|select distinct Payment.CustomerAccount, Payment.Ref
	|from Document.Payment as Payment
	|where Payment.Ref in ( select Base from Cash )
	|union all
	|select distinct Payment.VendorAccount, Payment.Ref
	|from Document.VendorPayment as Payment
	|where Payment.Ref in ( select Base from Cash )
	|order by case when Cash.Receipt then Entry.AccountCr.Code else Entry.AccountDr.Code end
	|";
	Env.Selection.Add ( s );    
	
EndProcedure

Procedure sqlBalances ()
	
	s = "
	|// #Balances
	|select allowed sum ( General.BalanceBegin ) as BalanceBegin, sum ( General.BalanceBeginCurrency ) as BalanceBeginCurrency, 0 as BalanceEnd,
	|	0 as BalanceEndCurrency, 0 as Receipt, 0 as Expense, 0 as ReceiptCurrency, 0 as ExpenseCurrency,
	|	General.Currency.FullDescription as FullCurrency, General.Currency.Description as Currency
	|from (
	|	select General.AmountBalanceDr as BalanceBegin, General.CurrencyAmountBalanceDr as BalanceBeginCurrency,	
	|		isnull ( General.Currency, Constants.Currency ) as Currency
	|	from AccountingRegister.General.Balance ( &DateStart,
	|		Account.Class = value ( Enum.Accounts.Cash ) and Account.Currency = &ByCurrency, ,
	|		ExtDimension1 in (
	|			select Ref from Catalog.PaymentLocations where not Remote and Owner = &Company
	|			union all select value ( Catalog.PaymentLocations.EmptyRef )
	|		)
	|		and Company = &Company
	|";
	if ( ByCurrency ) then
		s = s + "and Currency = &Currency";
	endif;
	s = s + "
	|	) as General
	|		//
	|		// Constants
	|		//
	|		left join Constants as Constants
	|		on true ) as General
	|group by General.Currency
	|";
	Env.Selection.Add ( s );    
	
EndProcedure

Procedure getTables ()
	
	q = Env.Q;
	q.SetParameter ( "Company", Company );
	q.SetParameter ( "Currency", Currency );
	q.SetParameter ( "ByCurrency", ByCurrency );
	q.SetParameter ( "DateStart", DateStart );
	q.SetParameter ( "DateEnd", DateEnd );
	SQL.Prepare ( Env );
	Env.Insert ( "Data", q.ExecuteBatch () );
	SQL.Unload ( Env, Env.Data );
	
EndProcedure 

Procedure putFirstPage ()
	
	area = Env.T.GetArea ( "FirstPage" );
	p = area.Parameters;
	p.Fill ( Env.Fields );
	p.Year = Format ( Year ( DateStart ), "NG=" );
	area.Areas.FirstPage.CreateFormatOfRows ();
	TabDoc.Put ( area );
	TabDoc.PutHorizontalPageBreak ();
	
EndProcedure

Procedure putPages () 
	
	initPagesData ();
	if ( Cash.Count () = 0 ) then
		return;
	endif;
	filter = new Structure ( "Month" );
	lastDay = Cash [ Cash.Count () - 1 ].Day;
	for each month in getMonths () do
		filter.Month = month;
		days = getDays ( filter );
		i = 1;
		count = days.Count ();
		for each Day in days do
			clearAreas ();
			initDayData ();
			setBalanceEnd ();
			putDay ();
			setBalanceBegin ();
			initFooterMonth ( i, count );
			initFooterYear ( lastDay );
			putAreas ();
			i = i + 1;
		enddo;
		PagesMonth = 0;
	enddo;
	TabDocPages.Area ( 1, 1, TabDocPages.TableHeight, TabDocPages.TableWidth ).CreateFormatOfRows ();
	TabDoc.Put ( TabDocPages );

EndProcedure

Procedure initPagesData () 

	fields = Env.Fields;
	Page = fields.Page;
	PagesMonth = fields.PagesMonth;
	Cash = Env.Cash;
	Balances = Env.Balances;

EndProcedure

Function getMonths () 

	months = Cash.UnloadColumn ( "Month" );
	Collections.Group ( months );
	return months;

EndFunction

Function getDays ( Filter ) 

	days = Cash.Copy ( Filter ).UnloadColumn ( "Day" );
	Collections.Group ( days );
	return days;

EndFunction

Procedure clearAreas () 

	AreasRows.Clear ();
	AreasHeader.Clear ();
	AreasFooter.Clear ();

EndProcedure

Procedure initDayData () 

	Page = Page + 1;
	Records = Cash.Copy ( new Structure ( "Day", Day ) );

EndProcedure

Procedure setBalanceEnd () 

	for each row in Records do
		rowBalance = Balances.Add ();
		FillPropertyValues ( rowBalance, row );
	enddo;
	Balances.GroupBy ( "Currency, FullCurrency", "BalanceBegin, BalanceEnd, BalanceBeginCurrency, BalanceEndCurrency,
	|Receipt, Expense, ReceiptCurrency, ExpenseCurrency" );
	for each row in Balances do
		row.BalanceEnd = row.BalanceBegin + row.Receipt - row.Expense;
		row.BalanceEndCurrency = row.BalanceBeginCurrency + row.ReceiptCurrency - row.ExpenseCurrency;
	enddo;

EndProcedure

Procedure putDay () 

	putHeaderDay ();
	putBalanceBegin ();
	if ( ByCurrency ) then
		putCurrencyBegin ();
	endif;
	putHeader ();
	putRecords ();
	putTurnover ();
	if ( ByCurrency ) then
		putTurnoverCurrency ();
	endif;
	putBalanceEnd ();
	if ( ByCurrency ) then
		putCurrencyEnd ();
	endif;
	putFooter ();

EndProcedure

Procedure putHeaderDay () 

	t = Env.T;
	area = t.GetArea ( "HeaderDay | Report" );
	p = area.Parameters;
	p.Day = Format ( Day, "DF='dd.MM.yyyy'" );
	p.Page = Page;
	areaCopy = t.GetArea ( "HeaderDayCopy | Report" );
	areaCopy.Parameters.Fill ( p );
	AreasHeader.Add ( spreadsheet ( area, t.GetArea ( "HeaderDay | Splitter" ), areaCopy ) );

EndProcedure

Function spreadsheet ( Area1, Splitter, Area2 = undefined ) 

	if ( Area2 = undefined ) then
		Area2 = Area1;
	endif;
	spreadsheet = new SpreadsheetDocument ();
	spreadsheet.Put ( Area1 );
	spreadsheet.Join ( Splitter );
	spreadsheet.Join ( Area2 );
	return spreadsheet;

EndFunction

Procedure putBalanceBegin () 

	t = Env.T;
	area = t.GetArea ( "BalanceBegin | Report" );
	area.Parameters.BalanceBegin = formatAmount ( Balances.Total ( "BalanceBegin" ) );
	AreasHeader.Add ( spreadsheet ( area, t.GetArea ( "BalanceBegin | Splitter" ) ) );

EndProcedure

Function formatAmount ( Amount, CurrencyFormat = undefined ) 

	if ( CurrencyFormat = undefined ) then
		CurrencyFormat = LocalCurrency;
	endif;
	return Format ( Amount, "NFD=2; NDS==; NN=0; NZ=0=00" ) + " " + CurrencyFormat;

EndFunction

Procedure putCurrencyBegin () 

	if ( Balances.Total ( "BalanceBegin" ) = 0 ) then
		return;
	endif;
	putIncluding ( AreasHeader );
	t = Env.T;
	splitter = t.GetArea ( "CurrencyBalance | Splitter" );
	for each row in Balances do
		if ( row.BalanceBegin = 0 ) then
			continue;
		endif;
		area = t.GetArea ( "CurrencyBalance | Report" );
		p = area.Parameters;
		p.Currency = row.FullCurrency;
		p.Balance = formatAmount ( row.BalanceBegin );
		p.CurrencyBalance = formatAmount ( row.BalanceBeginCurrency, row.Currency );
		AreasHeader.Add ( spreadsheet ( area, splitter ) );
	enddo;

EndProcedure

Procedure putIncluding ( Table ) 

	t = Env.T;
	Table.Add ( spreadsheet ( t.GetArea ( "Including | Report" ), t.GetArea ( "Including | Splitter" ) ) );

EndProcedure

Procedure putHeader () 

	t = Env.T;
	AreasHeader.Add ( spreadsheet ( t.GetArea ( "Header | Report" ), t.GetArea ( "Header | Splitter" ) ) );

EndProcedure

Procedure putRecords () 

	line = 1;
	for each row in Records do
		if ( ByCurrency ) then
			putRowCurrency ( row, line );
		else
			putRow ( row, line );
		endif;
		line = line + 1;
	enddo;

EndProcedure

Procedure putRow ( Row, Line ) 

	t = Env.T;
	area = t.GetArea ( "Row | Report" );
	p = area.Parameters;
	p.Fill ( Row );
	p.Line = line;
	receipt = Row.Receipt;
	expense = Row.Expense;;
	if ( Row.IsReceipt ) then
		p.Receipt = formatAmount ( receipt );
	else
		p.Expense = formatAmount ( expense );
	endif;
	p.Account = getAccounts ( Row );
	addAreaRow ( spreadsheet ( area, t.GetArea ( "Row | Splitter" ) ), receipt, expense );

EndProcedure

Function getAccounts ( Row ) 

	accounts = Env.Accounts.Copy ( new Structure ( "Base", Row.Base ) ).UnloadColumn ( "Account" );
	Collections.Group ( accounts );
	return StrConcat ( accounts, ", " );

EndFunction

Procedure addAreaRow ( Area, Receipt, Expense ) 

	row = AreasRows.Add ();
	row.Area = Area;
	row.Receipt = Receipt;
	row.Expense = Expense;

EndProcedure

Procedure putRowCurrency ( Row, Line ) 

	t = Env.T;
	area = t.GetArea ( "RowCurrency | Report" );
	p = area.Parameters;
	p.Fill ( Row );
	p.Line = line;
	formatCurrency = Row.Currency;
	receipt = Row.Receipt;
	expense = Row.Expense;;
	if ( Row.IsReceipt ) then
		p.Receipt = formatAmount ( receipt );
		p.ReceiptCurrency = formatAmount ( Row.ReceiptCurrency, formatCurrency );
	else
		p.Expense = formatAmount ( expense );
		p.ExpenseCurrency = formatAmount ( Row.ExpenseCurrency, formatCurrency );
	endif;
	p.Account = getAccounts ( Row );
	addAreaRow ( spreadsheet ( area, t.GetArea ( "RowCurrency | Splitter" ) ), receipt, expense );

EndProcedure

Procedure putTurnover () 

	t = Env.T;
	area = t.GetArea ( "Turnover | Report" );
	p = area.Parameters;
	p.Receipt = formatAmount ( Records.Total ( "Receipt" ) );
	p.Expense = formatAmount ( Records.Total ( "Expense" ) );
	AreasFooter.Add ( spreadsheet ( area, t.GetArea ( "Turnover | Splitter" ) ) );

EndProcedure

Procedure putTurnoverCurrency () 

	table = Records.Copy ( , "FullCurrency, Currency, Receipt, Expense, ReceiptCurrency, ExpenseCurrency" );
	table.GroupBy ( "FullCurrency, Currency", "Receipt, Expense, ReceiptCurrency, ExpenseCurrency" );
	t = Env.T;
	splitter = t.GetArea ( "TurnoverCurrency | Splitter" );
	for each row in table do
		rowCurrency = row.Currency;
		area = t.GetArea ( "TurnoverCurrency | Report" );
		p = area.Parameters;
		p.Currency = row.FullCurrency;
		p.Receipt = formatAmount ( row.Receipt );
		p.Expense = formatAmount ( row.Expense );
		amount = row.ReceiptCurrency;
		if ( amount > 0 ) then
			p.ReceiptCurrency = formatAmount ( amount, rowCurrency );
		endif;
		amount = row.ExpenseCurrency;
		if ( amount > 0 ) then
			p.ExpenseCurrency = formatAmount ( amount, rowCurrency );
		endif;
		AreasFooter.Add ( spreadsheet ( area, splitter ) );
	enddo;

EndProcedure

Procedure putBalanceEnd ()

	t = Env.T;
	area = t.GetArea ( "BalanceEnd | Report" );
	area.Parameters.BalanceEnd = formatAmount ( Balances.Total ( "BalanceEnd" ) );
	AreasFooter.Add ( spreadsheet ( area, t.GetArea ( "BalanceEnd | Splitter" ) ) );

EndProcedure

Procedure putCurrencyEnd () 

	if ( Balances.Total ( "BalanceEnd" ) = 0 ) then
		return;
	endif;
	putIncluding ( AreasFooter );
	t = Env.T;
	splitter = t.GetArea ( "CurrencyBalance | Splitter" );
	for each row in Balances do
		if ( row.BalanceEnd = 0 ) then
			continue;
		endif;
		area = t.GetArea ( "CurrencyBalance | Report" );
		p = area.Parameters;
		p.Currency = row.FullCurrency;
		p.Balance = formatAmount ( row.BalanceEnd );
		p.CurrencyBalance = formatAmount ( row.BalanceEndCurrency, row.Currency );
		AreasFooter.Add ( spreadsheet ( area, splitter ) );
	enddo;

EndProcedure

Procedure putFooter () 

	t = Env.T;
	area = t.GetArea ( "Footer | Report" );
	p = area.Parameters;
	p.Count = Records.Count ();
	format = "L=ro_RO; FN=false";
	option = " , , , , , , 0";
	p.CountWords = NumberInWords ( p.Count, format, option );
	filter = new Structure ( "IsReceipt", true );
	p.Receipt = Records.FindRows ( filter ).Count ();
	p.ReceiptWords = NumberInWords ( p.Receipt, format, option );
	filter.IsReceipt = false;
	p.Expense = Records.FindRows ( filter ).Count ();
	p.ExpenseWords = NumberInWords ( p.Expense, format, option );
	AreasFooter.Add ( spreadsheet ( area, t.GetArea ( "Footer | Splitter" ) ) );

EndProcedure

Procedure setBalanceBegin () 

	for each row in Balances do
		row.BalanceBegin = row.BalanceEnd;
		row.BalanceBeginCurrency = row.BalanceEndCurrency;
		row.Receipt = 0;
		row.Expense = 0;
		row.ReceiptCurrency = 0;
		row.ExpenseCurrency = 0;
		row.BalanceEnd = 0;
		row.BalanceEndCurrency = 0;
	enddo;

EndProcedure

Procedure initFooterMonth ( DayCount, MaxDayCount ) 

	if ( DayCount = MaxDayCount ) then
		AddPagesMonth = true;
		PagesMonth = PagesMonth + 1;
	else
		AddPagesMonth = false;
	endif;

EndProcedure

Procedure initFooterYear ( LastDay )

	if ( Day = LastDay
		and DateEnd = EndOfYear ( DateEnd ) ) then
		AddPagesYear = true;
	else
		AddPagesYear = false;
	endif;

EndProcedure

Procedure putAreas () 

	initAreasData ();
	putAreasHeader ();
	putAreasFooter ();
	if ( TabDocPages.CheckPut ( Areas ) ) then
		put ();
	else
		Areas = new Array ();
		row = AreasRows [ 0 ];
		Areas.Add ( row.Area );
		t = Env.T;
		subtotal = t.GetArea ( "Subtotal | Report" );
		splitter = t.GetArea ( "Subtotal | Splitter" );
		p = subtotal.Parameters;
		initSubtotals ( row );
		addSubtotal ( subtotal, splitter );
		count = AreasRows.Count () - 1;
		for i = 1 to count do
			row = AreasRows [ i ];
			Areas.Insert ( Areas.UBound (), row.Area );
			increaseSubtotals ( row );
			if ( not TabDocPages.CheckPut ( Areas ) ) then
				Areas.Delete ( Areas.UBound () - 1 );
				setSubtotals ( p, Row );
				deleteLastArea ();
				addSubtotal ( subtotal, splitter );
				put ();
				Areas = new Array ();
				putHeaderTransfer ();
				Areas.Add ( row.Area );
				initSubtotals ( row );
				addSubtotal ( subtotal, splitter );
			endif;
		enddo;
		deleteLastArea ();
		putAreasFooter ();
		if ( TabDocPages.CheckPut ( Areas )  ) then
			put ();
		else
			deleteFooter ();
			deleteLastArea ();
			setSubtotals ( p, Row );
			addSubtotal ( subtotal, splitter );
			put ();
			Areas = new Array ();
			putHeaderTransfer ();
			Areas.Add ( AreasRows [ count ].Area );
			putAreasFooter ();
			put ();
		endif;
	endif;

EndProcedure

Procedure initAreasData () 

	PagesDay = 0;
	Areas = AreasRows.UnloadColumn ( "Area" );

EndProcedure

Procedure putAreasHeader () 

	for each area in AreasHeader do
		TabDocPages.Put ( area );
	enddo;

EndProcedure

Procedure putAreasFooter () 

	for each area in AreasFooter do
		Areas.Add ( area );
	enddo;
	if ( AddPagesMonth ) then
		putPagesMonth ();
	endif;
	if ( AddPagesYear ) then
		putPagesYear ();
	endif;

EndProcedure

Procedure putPagesMonth () 

	t = Env.T;
	area = t.GetArea ( "PagesMonth | Report" );
	p = area.Parameters;
	p.Month = Format ( Day, "L=ro_RO;DF='MMMM'" );
	p.MonthRu = Lower ( Format ( Day, "L=ru_RU;DF='MMMM'" ) );
	p.PagesMonth = PagesMonth;
	Areas.Add ( spreadsheet ( area, t.GetArea ( "PagesMonth | Splitter" ) ) );

EndProcedure

Procedure putPagesYear () 

	t = Env.T;
	area = t.GetArea ( "PagesYear | Report" );
	p = area.Parameters;
	p.Year = Format ( Day, "DF='yyyy'" );
	p.Page = Page;
	Areas.Add ( spreadsheet ( area, t.GetArea ( "PagesYear | Splitter" ) ) );

EndProcedure

Procedure put () 

	for each area in Areas do
		TabDocPages.Put ( area );
	enddo;
	TabDocPages.PutHorizontalPageBreak ();
	writePages ();

EndProcedure

Procedure writePages () 

	PagesMonth = PagesMonth + 1;
	PagesDay = PagesDay + 1;
	manager = InformationRegisters.CashBookPages.CreateRecordManager ();
	manager.Company = Company;
	manager.Period = Day;
	manager.Page = PagesDay;
	manager.Write ( true );

EndProcedure

Procedure initSubtotals ( Row ) 

	Receipt = Row.Receipt;
	Expense = Row.Expense;

EndProcedure

Procedure addSubtotal ( Area, Splitter ) 

	Areas.Add ( spreadsheet ( Area, Splitter ) );

EndProcedure

Procedure increaseSubtotals ( Row ) 

	Receipt = Receipt + Row.Receipt;
	Expense = Expense + Row.Expense;

EndProcedure

Procedure setSubtotals ( TransferParams, Row ) 

	TransferParams.Receipt = formatAmount ( Receipt - Row.Receipt );
	TransferParams.Expense = formatAmount ( Expense - Row.Expense );

EndProcedure

Procedure putHeaderTransfer () 
	
	Page = Page + 1;
	t = Env.T;
	area = t.GetArea ( "HeaderDay | Report" );
	p = area.Parameters;
	p.Day = Format ( Day, "DF='dd.MM.yyyy'" );
	p.Page = Page;
	areaCopy = t.GetArea ( "HeaderDayCopy | Report" );
	areaCopy.Parameters.Fill ( p );
	Areas.Add ( spreadsheet ( area, t.GetArea ( "HeaderDay | Splitter" ), areaCopy ) );
	Areas.Add ( spreadsheet ( t.GetArea ( "Header | Report" ), t.GetArea ( "Header | Splitter" ) ) );

EndProcedure

Procedure deleteFooter () 

	count = AreasFooter.Count ();
	for i = 1 to count do
		Areas.Delete ( Areas.UBound () );
	enddo;

EndProcedure

Procedure deleteLastArea () 

	Areas.Delete ( Areas.UBound () );

EndProcedure

Procedure putLastPage ()
	
	area = Env.T.GetArea ( "LastPage" );
	p = area.Parameters;
	p.Fill ( Env.Fields );
	p.Page = Page;
	area.Areas.LastPage.CreateFormatOfRows ();
	TabDoc.Put ( area );
	
EndProcedure

#EndRegion

#endif