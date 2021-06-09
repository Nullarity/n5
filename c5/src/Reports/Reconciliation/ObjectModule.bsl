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
	DateStart = period.StartDate;
	DateEnd = period.EndDate;
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
	fillDictionary ();
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
	
EndProcedure

Procedure fillDictionary ()
	
	Dictionary = new Map ();
	t = GetCommonTemplate ( "Documents" );
	suffix = "|" + LanguageCode;
	for each area in t.Areas do
		if ( area.AreaType = SpreadsheetDocumentCellAreaType.Columns ) then
			continue;
		endif;
		name = area.Name;
		type = Type ( "DocumentRef." + name );
		Dictionary [ type ] = t.Area ( name + suffix ).Text;
	enddo;
	
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
	
	s = "// Roles
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
	|where Accounts.Class in ( value ( Enum.Accounts.AccountsPayable ), value ( Enum.Accounts.AccountsReceivable ) )
	|";
	Env.Selection.Add ( s );
		
EndProcedure

Procedure sqlRecords ()
	
	s = "
	|select Records.Recorder as Document, valuetype ( Records.Recorder ) as Operation, max ( Records.Period ) as Date,
	|	Records.Recorder.ReferenceDate as ReferenceDate, Records.Recorder.Number as Number,
	|	Records.Recorder.Reference as Reference
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
		s = s + " and ExtDimension2 = &Contract";
	endif;
	if ( CurrencyDefined ) then
		s = s + " and Currency = &Currency";
	endif;
	s = s + " ) as Records
	|where not ( Records.BalancedAccount in ( select Account from Accounts )
	|	and Records.BalancedExtDimension1 = Records.ExtDimension1";
	if ( ContractDefined ) then
		s = s + "
		|and Records.BalancedExtDimension2 = Records.ExtDimension2";
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
	|select Records.Document as Document, Records.Operation as Operation, Records.Date as Date,
	|	Records.ReferenceDate as ReferenceDate, Records.Number as Number, Records.Reference as Reference,
	|	Records.Dr as Dr, Records.Cr as Cr";
	if ( Detailed ) then
		s = s + ", Records.Contract as Contract";
	endif;
	s = s + "
	|from Records as Records
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
		s = s + " and ExtDimension2 = &Contract";
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
		s = s + " and ExtDimension2 = &Contract";
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
		return OutputCont.ReconciliationPeriodAll ( p, LanguageCode );
	elsif ( not ValueIsFilled ( DateStart ) ) then
		return OutputCont.ReconciliationPeriodTo ( p, LanguageCode );	
	elsif ( not ValueIsFilled ( DateEnd ) ) then
		return OutputCont.ReconciliationPeriodFrom ( p, LanguageCode );	
	endif;
	return OutputCont.ReconciliationPeriod ( p, LanguageCode );		
	
EndFunction

Function getInformation ()
	
	fields = Env.Fields;
	p = new Structure ( "Company, Organization", fields.Company, fields.Organization );
	return OutputCont.ReconciliationInformation ( p, LanguageCode );	
	
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
		p.Contract = OutputCont.ReconciliationContract ( new Structure ( "Contract", ContractRow.Contract ), LanguageCode );
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
	for each row in table do
		p.Fill ( row );
		p.Line = line;
		p.Number = ? ( ValueIsFilled ( row.Reference ), row.Reference, row.Number );
		p.Date = Conversion.DateToString ( row.Date );
		operationType = row.Operation;
		operation = Dictionary [ operationType ];
		if ( operation = undefined ) then
			operation = String ( operationType );
		endif;
		referenceDate = row.ReferenceDate;
		if ( ValueIsFilled ( referenceDate )
			and referenceDate <> BegOfDay ( row.Date ) ) then
			p.Operation = operation + " - " + Format ( referenceDate, "DLF=D" );
		else
			p.Operation = operation;
		endif;
		if ( Ready ) then
			p.DrThey = row.Cr;
			p.CrThey = row.Dr;
		endif;
		TabDoc.Put ( area );
		line = line + 1;
	enddo;
	
EndProcedure

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
		return OutputCont.ReconciliationTotalPlus ( p, LanguageCode );
	elsif ( amount < 0 ) then
		p.Amount = Conversion.NumberToMoney ( - amount, CurrencyPresentation );
		return OutputCont.ReconciliationTotalMinus ( p, LanguageCode );	
	else
		return OutputCont.ReconciliationTotalZero ( p, LanguageCode );
	endif;
	
EndFunction

#endif