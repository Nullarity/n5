#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;
var Env;
var TabDoc;
var DateStart;
var DateEnd;
var Company;
var Organization;
var Contract;
var Currency;
var Detailed;
var Language;
var LanguageCode;
var ContractDefined;
var CurrencyDefined;
var CurrencyPresentation;
var Ready;
var Dictionary;
var DocumentsPresentation;
var EnumsPresentation;

Procedure OnCheck ( Cancel ) export
	
	readParams ();
	
EndProcedure

Procedure readParams ()
	
	settings = Params.Composer.GetSettings ();
	Company = DC.GetParameter ( settings, "Company" ).Value;
	Organization = DC.GetParameter ( settings, "Organization" ).Value;
	Contract = DC.GetParameter ( settings, "Contract" ).Value;
	Currency = DC.GetParameter ( settings, "Currency" ).Value;
	Detailed = DC.GetParameter ( settings, "Detailed" ).Value;
	Ready = not DC.GetParameter ( settings, "Draft" ).Value;
	period = DC.GetParameter ( settings, "Period" ).Value;
	DateStart = Max ( period.StartDate, Date ( 1900, 1, 1 ) );
	DateEnd = ? ( period.EndDate = Date ( 1, 1, 1 ), Date ( 3999, 1, 1 ), period.EndDate );
	Language = DC.GetParameter ( settings, "Language" ).Value;
	LanguageCode = getLanguageCode ();
	
EndProcedure 

Function getLanguageCode ()
	
	langs = Enums.Languages;
	if ( Language = langs.Ru ) then
		return "ru";	
	elsif ( Language = langs.Ro ) then
		return "ro";
	elsif ( Language = langs.En ) then
		return "en";		
	endif;
	
EndFunction

Procedure AfterOutput () export

	init ();
	print ();

EndProcedure

Procedure init () 

	ContractDefined = ValueIsFilled ( Contract );
	local = Application.Currency ();
	CurrencyDefined = ValueIsFilled ( Currency ) and Currency <> local;
	CurrencyPresentation = "" + ? ( CurrencyDefined, Currency, local );
	Env = new Structure ();
	SQL.Init ( Env );
	Env.Insert ( "T", GetTemplate ( "Reconciliation" + LanguageCode ) );	
	TabDoc = Params.Result;
	Dictionary = new Map ();
	DocumentsPresentation = GetCommonTemplate ( "Documents" );
	EnumsPresentation = GetCommonTemplate ( "Enums" );
	
EndProcedure

Function print ()
	
	TabDoc.Clear ();
	Print.SetFooter ( TabDoc );
	setPageSettings ();
	getData ();
	putHeader ();
	putTable ();
	putFooter ();
	return true;
	
EndFunction

Procedure setPageSettings ()
	
	TabDoc.PageOrientation = PageOrientation.Portrait;
	TabDoc.FitToPage = true;
	
EndProcedure

Procedure getData ()
	
	sqlFields ();
	sqlAccounts ();
	sqlRecords ();
	sqlContracts ();
	sqlBalance ();
	fetchData ();
	
EndProcedure

Procedure sqlFields ()
	
	s = "
	|// Roles
	|select Roles.Responsible as Responsible, Roles.Role as Role
	|into Roles
	|from (
	|	select top 1 Roles.Ref.User.Employee.Description as Responsible, Roles.Role as Role
	|	from Document.Roles as Roles
	|	where not Roles.DeletionMark
	|	and Roles.Action = value ( Enum.AssignRoles.Assign )
	|	and Roles.Company = &Company
	|	and Roles.Role = value ( Enum.Roles.AccountantChief )
	|	order by Roles.Date	desc
	|) as Roles
	|union all
	|select Roles.Responsible, Roles.Role
	|from (
	|	select top 1 Roles.Ref.User.Employee.Description as Responsible, Roles.Role as Role
	|	from Document.Roles as Roles
	|	where not Roles.DeletionMark
	|	and Roles.Action = value ( Enum.AssignRoles.Assign )
	|	and Roles.Company = &Company
	|	and Roles.Role = value ( Enum.Roles.GeneralManager )
	|	order by Roles.Date	desc
	|) as Roles
	|;
	|// @Fields
	|select Companies.FullDescription as Company, Companies.CodeFiscal as CodeFiscal, 
	|	RolesAccountant.Accountant as Accountant, RolesDirector.Director as Director, 
	|	Organizations.FullDescription as Organization
	|from Catalog.Companies as Companies
	|	//
	|	// Accountant
	|	//
	|	left join ( 
	|		select Roles.Responsible as Accountant
	|		from Roles as Roles
	|		where Roles.Role = value ( Enum.Roles.AccountantChief )
	|		) as RolesAccountant
	|	on true
	|	//
	|	// Director
	|	//
	|	left join ( 
	|		select Roles.Responsible as Director
	|		from Roles as Roles
	|		where Roles.Role = value ( Enum.Roles.GeneralManager )
	|		) as RolesDirector
	|	on true
	|	//
	|	// Organizations
	|	//
	|	left join Catalog.Organizations as Organizations
	|	on Organizations.Ref = &Organization
	|where Companies.Ref = &Company
	|";
 	Env.Selection.Add ( s );    
	
EndProcedure

Procedure sqlAccounts ()
	
	s = "
	|// Accounts
	|select Accounts.Ref as Account
	|into Accounts
	|from ChartOfAccounts.General as Accounts
	|where Accounts.Class in (
	|	value ( Enum.Accounts.AccountsPayable ),
	|	value ( Enum.Accounts.AccountsReceivable ),
	|	value ( Enum.Accounts.OtherCurrentLiability )
	|)
	|";
	Env.Selection.Add ( s );
		
EndProcedure

Procedure sqlRecords ()
	
	s = "
	|select Invoices.Base as Document, cast ( Invoices.Base as Document.Sale ).Method as Method,
	|	cast ( Invoices.Base as Document.Sale ).Date as Date, Invoices.Date as ReferenceDate,
	|	Invoices.Number as Number, Invoices.Number as Reference, Invoices.Amount as Dr, Invoices.Amount as Cr";
	if ( Detailed ) then
		s = s + ", cast ( Invoices.Customer as Catalog.Organizations ).CustomerContract as Contract";
	endif;
	s = s + "
	|into Invoices
	|from Document.InvoiceRecord as Invoices
	|where not Invoices.DeletionMark
	|and Invoices.Customer = &Organization
	|and Invoices.Company = &Company
	|and Invoices.Status in (
	|	value ( Enum.FormStatuses.Unloaded ),
	|	value ( Enum.FormStatuses.Printed ),
	|	value ( Enum.FormStatuses.Submitted ),
	|	value ( Enum.FormStatuses.Returned )
	|)
	|and Invoices.Base refs Document.Sale
	|and cast ( Invoices.Base as Document.Sale ).Date between &DateStart and &DateEnd";
	if ( ContractDefined ) then
		s = s + "
		|and cast ( Invoices.Customer as Catalog.Organizations ).CustomerContract in hierarchy ( &Contract )";
	endif;
	s = s + "
	|;
	|select Records.Recorder as Document, max ( Records.Period ) as Date
	|";
	if ( Detailed ) then
		s = s + ", Records.ExtDimension2 as Contract";
	endif;
	if ( CurrencyDefined ) then
		s = s + ", sum ( Records.CurrencyAmountTurnoverDr ) as Dr, sum ( Records.CurrencyAmountTurnoverCr ) as Cr";
	else
		s = s + ", sum ( Records.AmountTurnoverDr ) as Dr, sum ( Records.AmountTurnoverCr ) as Cr";
	endif;
	s = s + "
	|into Records
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, recorder,
	|	Account in ( select Account from Accounts ), &Dimensions,
	|	Company = &Company and ExtDimension1 = &Organization";
	if ( ContractDefined ) then
		s = s + " and ExtDimension2 in hierarchy ( &Contract )";
	endif;
	if ( CurrencyDefined ) then
		s = s + " and Currency = &Currency";
	endif;
	s = s + " ) as Records
	|where
	|	not ( Records.BalancedAccount in ( select Account from Accounts )
	|		and isnull ( Records.BalancedExtDimension1, value ( Catalog.Organizations.EmptyRef ) )
	|			= Records.ExtDimension1
	|";
	if ( Detailed or ContractDefined ) then
		s = s + "
		|and isnull ( Records.BalancedExtDimension2, value ( Catalog.Contracts.EmptyRef ) ) = Records.ExtDimension2";
	endif;
	s = s + " )
	|group by Records.Recorder";
	if ( Detailed ) then
		s = s + ", Records.ExtDimension2";
	endif;
	if ( CurrencyDefined ) then
		s = s + " having sum ( Records.CurrencyAmountTurnoverDr ) <> 0 or sum ( Records.CurrencyAmountTurnoverCr ) <> 0";
	else
		s = s + " having sum ( Records.AmountTurnoverDr ) <> 0 or sum ( Records.AmountTurnoverCr ) <> 0";
	endif;
	s = s + "
	|;
	|// #Records
	|select Records.Document as Document, Records.Document.Method as Method,
	|	Records.Date as Date, Records.Document.Number as Number, Records.Document.ReferenceDate as ReferenceDate,
	|	isnull ( TaxInvoices.Number, Records.Document.Reference ) as Reference, Records.Dr as Dr, Records.Cr as Cr";
	if ( Detailed ) then
		s = s + ", Records.Contract as Contract";
	endif;
	s = s + "
	|from Records as Records
	|	//
	|	// TaxInvoices
	|	//
	|	left join InformationRegister.Forms as TaxInvoices
	|	on TaxInvoices.Document = Records.Document
	|union all
	|select Invoices.Document, Invoices.Method, Invoices.Date, Invoices.Number,
	|	Invoices.ReferenceDate, Invoices.Reference, Invoices.Dr, Invoices.Cr";
	if ( Detailed ) then
		s = s + ", Invoices.Contract";
	endif;
	s = s + "
	|from Invoices as Invoices
	|order by Date
	|";
	Env.Selection.Add ( s );	
	
EndProcedure

Procedure sqlContracts ()
	
	s = "
	|// #Contracts
	|select sum ( Records.Dr ) as Dr, sum ( Records.Cr ) as Cr, sum ( Records.OpeningDr ) as OpeningDr,
	|	sum ( Records.OpeningCr ) as OpeningCr, sum ( Records.ClosingDr ) as ClosingDr,
	|	sum ( Records.ClosingCr ) as ClosingCr";
	if ( Detailed ) then
		s = s + ", Records.Contract as Contract";
	endif;
	s = s + "
	|from (
	|	select 0 as Dr, 0 as Cr";
	if ( CurrencyDefined ) then
		s = s + ", General.CurrencyAmountOpeningBalanceDr as OpeningDr, General.CurrencyAmountOpeningBalanceCr as OpeningCr,
		|General.CurrencyAmountClosingBalanceDr as ClosingDr, General.CurrencyAmountClosingBalanceCr as ClosingCr";
	else
		s = s + ", General.AmountOpeningBalanceDr as OpeningDr, General.AmountOpeningBalanceCr as OpeningCr,
		|General.AmountClosingBalanceDr as ClosingDr, General.AmountClosingBalanceCr as ClosingCr";
	endif;
	if ( Detailed ) then
		s = s + ", General.ExtDimension2 as Contract";
	endif;
	s = s + "
	|	from AccountingRegister.General.BalanceAndTurnovers ( &DateStart, &DateEnd, , , 
	|		Account in ( select Account from Accounts ), &Dimensions,
	|		Company = &Company and ExtDimension1 = &Organization";
	if ( ContractDefined ) then
		s = s + " and ExtDimension2 in hierarchy ( &Contract )";
	endif;
	if ( CurrencyDefined ) then
		s = s + " and Currency = &Currency";
	endif;
	s = s + " ) as General
	|	//
	|	// Turnovers
	|	//
	|	union all
	|	select Records.Dr, Records.Cr, 0, 0, 0, 0";
	if ( Detailed ) then
		s = s + ", Records.Contract";
	endif;
	s = s + "
	|	from Records as Records
	|	union all
	|	select Invoices.Dr, Invoices.Cr, 0, 0, 0, 0";
	if ( Detailed ) then
		s = s + ", Invoices.Contract";
	endif;
	s = s + "
	|	from Invoices as Invoices
	|) as Records
	|";
	if ( Detailed ) then
		s = s + "
		|group by Records.Contract
		|";
	endif;
	Env.Selection.Add ( s );    
	
EndProcedure

Procedure sqlBalance ()
	
	s = "
	|// @Balance
	|select Balances." + ? ( CurrencyDefined, "CurrencyAmountBalance", "AmountBalance" ) + " as Amount
	|from AccountingRegister.General.Balance ( dateadd ( &DateEnd, second, 1 ),
	|	Account in ( select Account from Accounts ), &Dimensions,
	|	Company = &Company and ExtDimension1 = &Organization";
	if ( ContractDefined ) then
		s = s + " and ExtDimension2 in hierarchy ( &Contract )";
	endif;
	if ( CurrencyDefined ) then
		s = s + " and Currency = &Currency";
	endif;
	s = s + " ) as Balances";
	Env.Selection.Add ( s );    
	
EndProcedure

Procedure fetchData ()
	
	q = Env.Q;
	q.SetParameter ( "Company", Company );
	q.SetParameter ( "Organization", Organization );
	q.SetParameter ( "DateStart", DateStart );
	q.SetParameter ( "DateEnd", DateEnd );
	q.SetParameter ( "Contract", Contract );
	q.SetParameter ( "Currency", Currency );
	dims = new Array ();
	dims.Add ( ChartsOfCharacteristicTypes.Dimensions.Organizations );
	dims.Add ( ChartsOfCharacteristicTypes.Dimensions.Contracts );
	q.SetParameter ( "Dimensions", dims );
	SQL.Perform ( Env, false );
	
EndProcedure 

Procedure putHeader ()
	
	area = Env.T.GetArea ( "Header" );
	p = area.Parameters;
	p.Fill ( Env.Fields );
	p.Period = getPeriod ();
	p.Date = Conversion.DateToString ( CurrentSessionDate () );
	p.Information = getInformation ();
	p.Currency = CurrencyPresentation;
	TabDoc.Put ( area );
	Print.Repeat ( TabDoc, 2 );
	
EndProcedure

Function getPeriod ()
	
	p = new Structure ( "DateStart, DateEnd", Conversion.DateToString ( DateStart ), Conversion.DateToString ( DateEnd ) );
	if ( not ValueIsFilled ( DateStart )
		and not ValueIsFilled ( DateEnd ) ) then
		return Output.ReconciliationPeriodAll ( p, LanguageCode );
	elsif ( not ValueIsFilled ( DateStart ) ) then
		return Output.ReconciliationPeriodTo ( p, LanguageCode );	
	elsif ( not ValueIsFilled ( DateEnd ) ) then
		return Output.ReconciliationPeriodFrom ( p, LanguageCode );	
	endif;
	return Output.ReconciliationPeriod ( p, LanguageCode );		
	
EndFunction

Function getInformation ()
	
	fields = Env.Fields;
	p = new Structure ( "Company, Organization", fields.Company, fields.Organization );
	return Output.ReconciliationInformation ( p, LanguageCode );	
	
EndFunction

Procedure putTable ()
	
	for each row in Env.Contracts do
		putBalances ( row, false );
		putDocuments ( row );
		putBalances ( row, true );	
	enddo;
	
EndProcedure

Procedure putBalances ( ContractRow, Closing )
	
	areaName = ? ( Closing, "Closing", "Opening" );
	area = Env.T.GetArea ( AreaName );
	p = area.Parameters;
	p.Fill ( ContractRow );
	if ( Detailed ) then
		p.Contract = Output.ReconciliationContract ( new Structure ( "Contract", ContractRow.Contract ), LanguageCode );
	endif;
	if ( Ready ) then
		if ( Closing ) then
			p.DrThey = ContractRow.Cr;
			p.CrThey = ContractRow.Dr;
			p.ClosingDrThey = ContractRow.ClosingCr;
			p.ClosingCrThey = ContractRow.ClosingDr;
		else
			p.OpeningDrThey = ContractRow.OpeningCr;
			p.OpeningCrThey = ContractRow.OpeningDr;
		endif;
	endif;
	TabDoc.Put ( area );
	
EndProcedure

Procedure putDocuments ( ContractRow )
	
	if ( Detailed ) then
		filter = new Structure ( "Contract", ContractRow.Contract );	
		table = Env.Records.FindRows ( filter );
	else
		table = Env.Records;
	endif;
	area = Env.T.GetArea ( "Row");
	p = area.Parameters;
	line = 1;
	description = new Array ();
	for each row in table do
		p.Fill ( row );
		p.Line = line;
		p.Number = ? ( ValueIsFilled ( row.Reference ), row.Reference, row.Number );
		p.Date = Conversion.DateToString ( row.Date );
		operation = translateDocument ( row.Document );
		description.Clear ();
		description.Add ( operation );
		referenceDate = BegOfDay ( ? ( ValueIsFilled ( row.ReferenceDate ), row.ReferenceDate, row.Date ) );
		if ( referenceDate <> BegOfDay ( row.Date ) ) then
			description.Add ( " - " + Format ( referenceDate, "DLF=D" ) );
		endif;
		method = row.Method;
		if ( method <> null ) then
			description.Add ( ", " + translateEnum ( method ) );
		endif;
		p.Operation = StrConcat ( description );
		if ( Ready ) then
			p.DrThey = row.Cr;
			p.CrThey = row.Dr;
		endif;
		TabDoc.Put ( area );
		line = line + 1;
	enddo;
	
EndProcedure

Function translateDocument ( Document )

	type = TypeOf ( Document );
	result = Dictionary [ type ];
	if ( result = undefined ) then
		name = Metadata.FindByType ( type ).Name;
		try
			result = DocumentsPresentation.Area ( name + "|" + LanguageCode ).Text;
		except
			result = String ( type );
		endtry;
		Dictionary [ type ] = result;
	endif;
	return result;

EndFunction

Function translateEnum ( Item )

	result = Dictionary [ Item ];
	if ( result = undefined ) then
		name = Metadata.FindByType ( TypeOf ( Item ) ).Name + Conversion.EnumItemToName ( Item );
		try
			result = EnumsPresentation.Area ( name + "|" + LanguageCode ).Text;
		except
			result = String ( Item );
		endtry;
		Dictionary [ Item ] = result;
	endif;
	return result;

EndFunction

Procedure putFooter ()

	area = Env.T.GetArea ( "Footer" );
	p = area.Parameters;
	p.Fill ( Env.Fields );
	p.Total = totalInfo ();
	TabDoc.Put ( area );
	
EndProcedure

Function totalInfo ()
	
	fields = Env.Fields;
	p = new Structure ( "Company, Organization, Currency, Amount" );
	p.Company = fields.Company;
	p.Organization = fields.Organization;
	amount = Env.Balance.Amount;
	if ( amount > 0 ) then
		p.Amount = Conversion.NumberToMoney ( amount, CurrencyPresentation );
		return Output.ReconciliationTotalPlus ( p, LanguageCode );
	elsif ( amount < 0 ) then
		p.Amount = Conversion.NumberToMoney ( - amount, CurrencyPresentation );
		return Output.ReconciliationTotalMinus ( p, LanguageCode );	
	else
		return Output.ReconciliationTotalZero ( p, LanguageCode );
	endif;
	
EndFunction

#endif