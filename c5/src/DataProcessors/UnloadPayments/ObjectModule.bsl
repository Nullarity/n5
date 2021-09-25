#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Env;
var PaymentOrder;
var JobKey;
var ProcessingError;
var TempFile;
var Files;
var FilesDescriptor;
var FileAddresses;
var PaymentsFile;
var SalaryFile;

Procedure Run(Params) export
	
	init(Params);
	getRows(Params.Orders);
	if (BankingApp = Enums.Banks.VictoriaBank) then
		runVictoriaBank();
	elsif (BankingApp = Enums.Banks.Energbank) then
		runEnergBank();
	elsif (BankingApp = Enums.Banks.ProCreditBank) then
		runProcreditBank();
	elsif (BankingApp = Enums.Banks.Eximbank) then
		runEximbank();
	elsif (BankingApp = Enums.Banks.Mobias) then
		runMobias();
	elsif (BankingApp = Enums.Banks.MAIB) then
		runMaib();
	elsif (BankingApp = Enums.Banks.FinComPay) then
		runFinComPay();
	elsif (BankingApp = Enums.Banks.Comert) then
		runComert();
	elsif (BankingApp = Enums.Banks.EuroCreditBank) then
		runEuroCreditBank();
	endif;
	if (ProcessingError) then
		return;
	endif;
	PutToTempStorage(Files, FilesDescriptor);
	clean();
	commitUnloading();
	
EndProcedure

Procedure init(Params)
	
	ProcessingError = false;
	Files = new Array();
	SQL.Init(Env);
	PaymentOrder = Documents.PaymentOrder;
	BankingApp = Params.BankingApp;
	JobKey = Params.JobKey;
	FileAddresses = new Array();
	FileAddresses.Add(Params.File1);
	FileAddresses.Add(Params.File2);
	FileAddresses.Add(Params.File3);
	FilesDescriptor = Params.FilesDescriptor;
	PaymentsFile = Params.Path;
	SalaryFile = Params.PathSalary;
	if (BankingApp = PredefinedValue("Enum.Banks.Mobias")
		or BankingApp = PredefinedValue("Enum.Banks.MAIB")) then
		TempFile = TempFilesDir() + FileSystem.DBFTempFile();
	else
		TempFile = GetTempFileName();
	endif;
	
EndProcedure

Procedure getRows(Orders)
	
	SQL.Init(Env);
	Env.Q.SetParameter("Orders", Orders);
	sqlRows();
	SQL.Perform(Env);
	
EndProcedure

Procedure sqlRows()
	
	s = "
	|// #Rows
	|select Documents.Number as Number, Documents.Company.Prefix as Prefix, Documents.Date as Date, Documents.Company.CodeFiscal as CodeFiscal,
	|	case when Documents.Division = value ( Catalog.Divisions.EmptyRef ) then false else true end as HasDivision, Documents.Division.Code as DivisionCode,
	|	Documents.BankAccount.AccountNumber as AccountNumber, Documents.BankAccount.Bank.Code as BankCode, Documents.RecipientPresentation as RecipientPresentation,
	|	Documents.Recipient.CodeFiscal as RecipientCodeFiscal, Documents.RecipientBankAccount.AccountNumber as RecipientAccountNumber,
	|	Documents.RecipientBankAccount.Bank.Code as RecipientBankCode, Documents.Amount - Documents.IncomeTax as AmountWithoutTax, Documents.VATRate.Rate as VATRate,
	|	case when Documents.VATRate = value ( Catalog.VAT.EmptyRef ) then false else true end as VATFilled, Documents.VAT as VAT, Documents.Amount as Amount,
	|	Documents.IncomeTax as IncomeTax, Documents.IncomeTaxRate as IncomeTaxRate, Documents.ExcludeTaxes as ExcludeTaxes,
	|	case when Documents.IncomeTaxRate = 0 then false else true end as TaxRateFilled, Documents.PaymentContent as PaymentContent,
	|	case when Documents.Urgent then ""U"" else ""N"" end as TransferType, case when Documents.Trezorerial then ""101"" else ""001"" end as TransactionCode, 
	|	Documents.Trezorerial as Trezorerial, Documents.Ref as PaymentOrder, Documents.BankAccount.TreasuryCode as TreasuryCode,
	|	Documents.Company.FullDescription as CompanyName, Documents.BankAccount.Bank.Description as BankDescription,
	|	Documents.RecipientBankAccount.Bank.Description as RecipientBankDescription, Documents.RecipientBankAccount.Bank.MFO as RecipientBankMFO,
	|	Documents.BankAccount.Currency.Code as CurrencyCode, Documents.BankAccount.Currency.Description as CurrencyName,
	|	case when Documents.Recipient.Alien then ""N"" else ""R"" end as RecipientResidency,
	|	case when Documents.Company.Alien then ""N"" else ""R"" end as Residency, Documents.Company.Description as CompanyDescription,
	|	Documents.Salary as Salary
	|from Document.PaymentOrder as Documents
	|where Documents.Ref in ( &Orders )
	|;
	|// #Salary
	|select Totals.Net as Amount, Totals.Employee.FirstName as FirstName, Totals.Employee.LastName as LastName,
	|	Totals.Employee.Patronymic as Patronymic, Totals.Employee.Code as Code
	|from Document.PayEmployees.Totals as Totals
	|where Totals.Ref in (
	|	select distinct Base
	|	from Document.PaymentOrder
	|	where Ref in ( &Orders )
	|)
	|and Totals.Net > 0
	|";
	Env.Selection.Add(s);
	
EndProcedure

Procedure runVictoriaBank()
	
	text = getTextDocument();
	for each row in Env.Rows do
		startText(text);
		text.AddLine(getDOCUMENTNUMBER(row));
		text.AddLine(getDOCUMENTDATE(row));
		text.AddLine(getPAYERFCODE(row));
		text.AddLine(getPAYERACCOUNT(row));
		text.AddLine(getPAYERBANKBIC(row));
		text.AddLine(getRECEIVER(row));
		text.AddLine(getRECEIVERFCODE(row));
		text.AddLine("RECEIVERACCOUNT=" + TrimAll(row.RecipientAccountNumber));
		text.AddLine("RECEIVERBANKBIC=" + TrimAll(row.RecipientBankCode));
		text.AddLine(getAMOUNT(row));
		text.AddLine(getGROUND(row));
		text.AddLine(getCREDITSUBACCOUNT(row));
		text.AddLine(getTRANSFERTYPE(row));
		text.AddLine(getTRANSACTIONCODE(row));
		endText(text, row);
	enddo;
	saveText(text, PaymentsFile, true);
	
EndProcedure

Function getTextDocument()
	
	text = new TextDocument();
	text.AddLine("1CClientBankExchange(V:M.1)");
	return text;
	
EndFunction

Procedure startText(Text)
	
	Text.AddLine("DocStart");
	Text.AddLine("DOCID=1");
	
EndProcedure

Function getDOCUMENTNUMBER(Row)
	
	return "DOCUMENTNUMBER=" + PaymentOrder.NumberWithoutPrefix(Row.Number, Row.Prefix);
	
EndFunction

Function getDOCUMENTDATE(Row)
	
	return "DOCUMENTDATE=" + Format(Row.Date, "DF='dd.MM.yyyy'");
	
EndFunction

Function getPAYERFCODE(Row)
	
	return "PAYERFCODE=" + TrimAll(Row.CodeFiscal) + ?(Row.HasDivision, "/" + Format(Row.DivisionCode, "NG="), "");
	
EndFunction

Function getPAYERACCOUNT(Row)
	
	return "PAYERACCOUNT=" + TrimAll(Row.AccountNumber);
	
EndFunction

Function getPAYERBANKBIC(Row)
	
	return "PAYERBANKBIC=" + TrimAll(Row.BankCode);
	
EndFunction

Function getRECEIVER(Row)
	
	return "RECEIVER=" + PaymentOrder.RemoveInadmissibleSymbols(TrimAll(Row.RecipientPresentation));
	
EndFunction

Function getRECEIVERFCODE(Row)
	
	return "RECEIVERFCODE=" + TrimAll(Row.RecipientCodeFiscal);
	
EndFunction

Function getAMOUNT(Row)
	
	return "AMOUNT=" + Format(Row.AmountWithoutTax, "NFD=2; NDS=.; NG=");
	
EndFunction

Function getGROUND(Row)
	
	return "GROUND=" + Mid(getContent(Row), 1, 210);
	
EndFunction

Function getContent(Row)
	
	return StrReplace(Documents.PaymentOrder.RemoveInadmissibleSymbols(Row.PaymentContent), Chars.LF, " ") + " " + getTax(Row);
	
EndFunction

Function getTax(Row)
	
	vatFilled = Row.VATFilled;
	taxRateFilled = Row.TaxRateFilled;
	tax = "";
	if (not Row.ExcludeTaxes) then
		if (vatFilled)
			and (taxRateFilled) then
			tax = "Impozit " + String(Row.IncomeTaxRate) + " prc. " + Format(Row.IncomeTax, "ND='15';NFD='2';NDS='-';NG=0")
				+ " lei, inclusiv TVA " + Format(Row.VATRate, "NZ=") + " prc. " + Format(Row.VAT, "ND='15'; NFD='2'; NDS='-'; NG=0") + " lei.";
			
		elsif (vatFilled)
			and (not taxRateFilled) then
			tax = "Inclusiv TVA " + Format(Row.VATRate, "NZ=") + " prc. " + Format(Row.VAT, "ND='15';NFD='2';NDS='-';NG=0") + " lei.";
		elsif (not vatFilled) and (taxRateFilled) then
			tax = "Impozit " + String(Row.IncomeTaxRate) + " prc. " + Format(Row.IncomeTax, "ND='15';NFD='2';NDS='-';NG=0") + " lei.";
		endif;
	endif;
	return tax;
	
EndFunction

Function getCREDITSUBACCOUNT(Row)
	
	trasuryCode = Row.TreasuryCode;
	s = "CREDITSUBACCOUNT=";
	if (IsBlankString(trasuryCode)) then
		return s;
	else
		return s + TrimAll(trasuryCode);
	endif;
	
EndFunction

Function getTRANSFERTYPE(Row)
	
	return "TRANSFERTYPE=" + Row.TransferType;
	
EndFunction

Function getTRANSACTIONCODE(Row)
	
	return "TRANSACTIONCODE=" + Row.TransactionCode;
	
EndFunction

Procedure endText(Text, Row)
	
	Text.AddLine("DocEnd");
	
EndProcedure

Procedure saveText(Text, File, BOM)
	
	try
		stream = new MemoryStream();
		Text.Write(stream);
		data = stream.CloseAndGetBinaryData ();
		if ( BOM ) then
			string64 = Base64String(data);
			string64 = Right(string64, StrLen(string64) - 4);
			data = Base64Value(string64);
		endif;
		putToStorage(data, File);
	except
		ProcessingError = true;
		Progress.Put(Output.UnableToSaveData(new Structure("Error", ErrorDescription())), JobKey, true);
	endtry;
	
EndProcedure

Procedure putToStorage(Data, File)
	
	Files.Add(File);
	index = Files.Ubound();
	PutToTempStorage(Data, FileAddresses[index]);
	
EndProcedure

Procedure runEnergBank()
	
	text = getTextDocument();
	for each row in Env.Rows do
		startText(text);
		text.AddLine(getDOCUMENTNUMBER(row));
		text.AddLine(getDOCUMENTDATE(row));
		text.AddLine(getPAYERFCODE(row));
		accountNumber = TrimAll(row.AccountNumber);
		text.AddLine("PAYERACCOUNT=" + parse(accountNumber));
		text.AddLine("PAYERIBAN=" + accountNumber);
		text.AddLine(getPAYERBANKBIC(row));
		text.AddLine(getRECEIVER(row));
		text.AddLine(getRECEIVERFCODE(row));
		accountNumber = TrimAll(row.RecipientAccountNumber);
		if (StrLen(accountNumber) = 24)
			and (Left(accountNumber, 2) = "MD") then
			text.AddLine("RECEIVERACCOUNT=");
		else
			text.AddLine("RECEIVERACCOUNT=" + parse(accountNumber, false));
		endif;
		text.AddLine("RECEIVERIBAN=" + accountNumber);
		text.AddLine("RECEIVERBANKBIC=" + Mid(TrimAll(row.RecipientBankCode), 1, 8));
		text.AddLine(getAMOUNT(row));
		text.AddLine(getGROUND(row));
		text.AddLine(getTRANSFERTYPE(row));
		text.AddLine(getTRANSACTIONCODE(row));
		text.AddLine("DocEnd");
	enddo;
	saveText(text, PaymentsFile, true);
	
EndProcedure

Function parse(String, RemoveZeros = true)
	
	s = Right(String, 24);
	onlyDigits(s);
	if (RemoveZeros) then
		removeZeros(s);
	endif;
	s = mid(s, 1, StrLen(s) - 3);
	return (s);
	
EndFunction

Procedure onlyDigits(String)
	
	String = Mid(String, 4);
	i = 1;
	while (i <= StrLen(String)) do
		code = CharCode(Mid(String, i, 1));
		if (code < 47
				or code > 57) then
			String = Mid(String, i + 1);
			i = 1;
		else
			i = i + 1;
		endif;
	enddo;
	
EndProcedure

Procedure removeZeros(String)
	
	while (Left(String, 1) = "0") do
		String = Right(String, StrLen(String) - 1);
	enddo;
	
EndProcedure

Procedure runProcreditBank()
	
	text = getTextDocument();
	for each row in Env.Rows do
		startText(text);
		text.AddLine(getDOCUMENTNUMBER(row));
		text.AddLine(getDOCUMENTDATE(row));
		text.AddLine(getPAYERFCODE(row));
		text.AddLine(getPAYERACCOUNT(row));
		text.AddLine(getPAYERBANKBIC(row));
		text.AddLine(getRECEIVER(row));
		text.AddLine(getRECEIVERFCODE(row));
		text.AddLine("RECEIVERACCOUNT=" + TrimAll(row.RecipientAccountNumber));
		recipientBankCode = TrimAll(row.RecipientBankCode);
		if (StrLen(recipientBankCode) <= 8) then
			recipientBankCode = recipientBankCode + "XXX";
		endif;
		text.AddLine("RECEIVERBANKBIC=" + recipientBankCode);
		text.AddLine(getAMOUNT(row));
		text.AddLine(getGROUND(row));
		text.AddLine(getCREDITSUBACCOUNT(row));
		text.AddLine(getTRANSFERTYPE(row));
		text.AddLine("DocEnd");
	enddo;
	saveText(text, PaymentsFile, true);
	
EndProcedure

Procedure runEximbank()
	
	line = getEximLine();
	text = new TextDocument();
	rows = Env.Rows;
	text.AddLine(Format(rows.Total("Amount"), "NG=0; NDS=""."""));
	for each row in rows do
		line.DATA = Format(row.Date, "DF='yyyyMMdd'");
		line.NDOC = Left(PaymentOrder.NumberWithoutPrefix(row.Number, row.Prefix), 10);
		line.CCL = TrimAll(row.AccountNumber);
		line.CCOR = TrimAll(row.RecipientAccountNumber);
		line.CFC = TrimAll(row.CodeFiscal);
		line.CFCCOR = TrimAll(row.RecipientCodeFiscal);
		setDenc(line, row);
		line.SUMN = Format(row.Amount, "NG=0; NDS="".""");
		setContent(line, row);
		line.BIC = TrimAll(row.RecipientBankCode);
		line.URGENT = row.TransferType;
		addLine(text, line);
	enddo;
	saveText(text, PaymentsFile, false);
	if ( salaryExists () ) then
		unloadEximSalary ();
	endif;
	
EndProcedure

Function getEximLine()
	
	line = new Structure();
	line.Insert("DATA");
	line.Insert("NDOC");
	line.Insert("CCL");
	line.Insert("CCOR");
	line.Insert("CCORT", "");
	line.Insert("CFC");
	line.Insert("CFCCOR");
	line.Insert("CBC", "");
	line.Insert("DENC");
	line.Insert("DENCT");
	line.Insert("SUMN");
	line.Insert("TD", "");
	line.Insert("DE1");
	line.Insert("DE2");
	line.Insert("DE3");
	line.Insert("DE4", "");
	line.Insert("BIC");
	line.Insert("URGENT");
	line.Insert("DOCUMENT", "");
	line.Insert("DOCUMENTDATE", "");
	return line;
	
EndFunction

Procedure setDenc(Line, Row)
	
	denc = TrimAll(Row.RecipientPresentation);
	denct = "";
	denc = StrReplace(denc, "(R) ", "(R)");
	denc = StrReplace(denc, "(N) ", "(N)");
	if (StrLen(denc) > 55) then
		denc = Left(denc, 55);
		denct = Mid(denc, 55, 50);
	endif;
	Line.DENC = denc;
	Line.DENCT = denct;
	
EndProcedure

Procedure setContent(Line, Row)
	
	content1 = TrimAll(Row.PaymentContent);
	content2 = "";
	content3 = "";
	if (StrLen(content1) > 57) then
		content1 = Left(content1, 57);
		content2 = Mid(content1, 57, 57);
	endif;
	if (StrLen(content2) > 57) then
		content2 = Left(content2, 57);
		content3 = Mid(content2, 57, 96);
	endif;
	Line.DE1 = content1;
	Line.DE2 = content2;
	Line.DE3 = content3;
	
EndProcedure

Procedure addLine(Text, Line)
	
	s = "";
	for each item in Line do
		s = s + item.Value + "^";
	enddo;
	s = Left(s, StrLen(s) - 1);
	Text.AddLine(s);
	
EndProcedure

Function salaryExists ()
	
	return Env.Salary.Count () > 0;
	
EndFunction

Procedure unloadEximSalary ()

	currency = DF.Pick ( Application.Currency (), "Code" );
	text = new TextDocument();
	text.AddLine ( "TAB_NO,NAME_EM,TR_AMOUNT,KV" );
	total = 0;
	list = new Array ();
	for each row in Env.Salary do
		list.Add ( CoreLibrary.EscapeCSV ( Print.ShortNumber ( row.Code ) ) );
		name = "";
		value = row.LastName;
		if ( value <> "" ) then
			name = name + value + "/";
		endif;
		name = name + row.FirstName + "/";
		value = row.Patronymic;
		if ( value <> "" ) then
			name = name + value;
		endif;
		list.Add ( CoreLibrary.EscapeCSV ( name ) );
		list.Add ( Format ( row.Amount, "NFD=2; NDS=.; NGS=''; NZ=0; NG=0;" ) );
		list.Add ( currency );
		text.AddLine ( StrConcat ( list, "," ) );
		list.Clear ();
		total = total + row.Amount;
	enddo;
	text.AddLine ( "99999,," + Format ( total, "NFD=2; NDS=.; NGS=''; NZ=0; NG=0;" ) + "," + currency );
	saveText(text, SalaryFile, false);
	
EndProcedure

Procedure saveStream ( Stream, File )
	
	try
		data = Stream.CloseAndGetBinaryData ();
		putToStorage(data, File);
	except
		Progress.Put(Output.UnableToSaveData(new Structure("Error", ErrorDescription())), JobKey, true);
	endtry;
	
EndProcedure

Procedure runMobias()
	
	dbf = getMobiasDbf();
	for each row in Env.Rows do
		dbf.Add();
		dbf.DATE = row.Date;
		dbf.N_DOC = PaymentOrder.NumberWithoutPrefix(row.Number, row.Prefix);
		if (row.Trezorerial) then
			dbf.FIS_K_MY = TrimAll(row.CodeFiscal) + "/" + TrimAll(row.DivisionCode);
		else
			dbf.FIS_K_MY = TrimAll(row.CodeFiscal);
		endif;
		dbf.MFO_MY = TrimAll(row.BankCode);
		dbf.NAZNACH1 = Left(getContent(row), 210);
		dbf.SCET_MY = TrimAll(row.AccountNumber);
		dbf.NAME_MY = PaymentOrder.RemoveInadmissibleSymbols(deleteRomanianChars(row.CompanyName));
		dbf.BANK_MY = PaymentOrder.RemoveInadmissibleSymbols(deleteRomanianChars(row.BankDescription));
		dbf.FIS_K_HIS = TrimAll(row.RecipientCodeFiscal);
		dbf.MFO_HIS = TrimAll(row.RecipientBankCode);
		dbf.SCET_HIS = TrimAll(row.RecipientAccountNumber);
		dbf.NAME_HIS = PaymentOrder.RemoveInadmissibleSymbols(deleteRomanianChars(TrimAll(row.RecipientPresentation)));
		dbf.BANK_HIS = PaymentOrder.RemoveInadmissibleSymbols(deleteRomanianChars(row.RecipientBankDescription));
		dbf.CONTRBEN = TrimAll(row.TreasuryCode);
		dbf.SUM = Format(row.AmountWithoutTax, "NFD=2; NDS=-; NG=");
	enddo;
	closeXBase(dbf);
	
EndProcedure

Function getMobiasDbf()
	
	xBase = new XBase();
	fields = xBase.Fields;
	fields.Add("N_DOC", "S", 10);
	fields.Add("DATE", "D", 8);
	fields.Add("SUM", "S", 16);
	fields.Add("NAZNACH1", "S", 210);
	fields.Add("FIS_K_MY", "S", 18);
	fields.Add("MFO_MY", "S", 11);
	fields.Add("SCET_MY", "S", 24);
	fields.Add("NAME_MY", "S", 105);
	fields.Add("BANK_MY", "S", 50);
	fields.Add("FIS_K_HIS", "S", 18);
	fields.Add("MFO_HIS", "S", 11);
	fields.Add("SCET_HIS", "S", 29);
	fields.Add("NAME_HIS", "S", 105);
	fields.Add("BANK_HIS", "S", 50);
	fields.Add("CONTRBEN", "S", 29);
	try	
		xBase.CreateFile(TempFile);
	except
		Progress.Put(Output.DBFErrorCreate(new Structure("Error", ErrorDescription())), JobKey, true);
		return undefined;
	endtry;
	xBase.Encoding = XBaseEncoding.ANSI;
	xBase.AutoSave = true;
	return xBase;
	
EndFunction

Function deleteRomanianChars(String)
	
	s = StrReplace(String, "Ă", "A");
	s = StrReplace(s, "ă", "a");
	s = StrReplace(s, "Â", "A");
	s = StrReplace(s, "â", "a");
	s = StrReplace(s, "Î", "I");
	s = StrReplace(s, "î", "i");
	s = StrReplace(s, "Ş", "S");
	s = StrReplace(s, "ş", "s");
	s = StrReplace(s, "Ţ", "T");
	s = StrReplace(s, "ţ", "t");
	return s;
	
EndFunction

Procedure closeXBase(XBase)
	
	try
		XBase.CloseFile();
		putToStorage(new BinaryData(TempFile), PaymentsFile);
	except
		Progress.Put(Output.UnableToSaveData(new Structure("Error", ErrorDescription())), JobKey, true);
	endtry;
	
EndProcedure

Procedure runMaib()
	
	dbf = getMaibDbf();
	if (ProcessingError) then
		return;
	endif;
	dbf.Add();
	rows = Env.Rows;
	dbf.SUMN = rows.Total("AmountWithoutTax");
	for each row in rows do
		content = getContentMaib(row);
		contentCount = content.Count();
		dbf.Add();
		dbf.DATA = Format(row.Date, "DF='yyyyMMdd'");
		dbf.NDOC = PaymentOrder.NumberWithoutPrefix(row.Number, row.Prefix);
		dbf.CCL = TrimAll(row.AccountNumber);
		recipientAccountNumber = TrimAll(row.RecipientAccountNumber);
		dbf.CCOR = recipientAccountNumber;
		dbf.CFC = getCFC(row);
		dbf.CFCCOR = TrimAll(row.RecipientCodeFiscal);
		mfo = TrimAll(row.RecipientBankMFO);
		if (StrLen(mfo) > 2) then
			dbf.CBC = Number(Right(mfo, 3));
		endif;
		dbf.DENC = deleteRomanianChars(TrimAll(row.RecipientPresentation));
		dbf.SUMN = row.AmountWithoutTax;
		dbf.DE1 = ?(contentCount > 0, content[0], "");
		dbf.DE2 = ?(contentCount > 1, content[1], "");
		dbf.DE3 = ?(contentCount > 2, content[2], "");
		dbf.DE4 = ?(contentCount > 3, content[3], "");
		dbf.URGENT = row.TransferType;
		dbf.BIC = getBIC(recipientAccountNumber, row.RecipientBankCode);
		dbf.CCORT = "";
		dbf.TD = 1;
	enddo;
	closeXBase(dbf);
	
EndProcedure

Function getMaibDbf()
	
	xBase = new XBase();
	fields = xBase.fields;
	fields.Add("DATA", "D", 8);
	fields.Add("NDOC", "S", 10);
	fields.Add("CCL", "S", 24);
	fields.Add("CCOR", "S", 29);
	fields.Add("CCORT", "S", 15);
	fields.Add("CFC", "S", 18);
	fields.Add("CFCCOR", "S", 18);
	fields.Add("CBC", "N", 3);
	fields.Add("DENC", "S", 55);
	fields.Add("DENCT", "S", 50);
	fields.Add("SUMN", "N", 15, 2);
	fields.Add("TD", "N", 2);
	fields.Add("DE1", "S", 57);
	fields.Add("DE2", "S", 57);
	fields.Add("DE3", "S", 114);
	fields.Add("DE4", "S", 114);
	fields.Add("BIC", "S", 11);
	fields.Add("URGENT", "S", 1);
	try
		xBase.CreateFile(TempFile);
	except
		ProcessingError = true;
		Progress.Put(Output.DBFErrorCreate(new Structure("Error", ErrorDescription())), JobKey, true);
		return undefined;
	endtry;
	xBase.Encoding = XBaseEncoding.ANSI;
	xBase.AutoSave = true;
	return xBase;
	
EndFunction

Function getContentMaib(Row)
	
	separator = " ";
	words = StrSplit(getContent(Row), separator, false);
	content = new Array();
	s = "";
	for i = 0 to words.Count() - 1 do
		word = words[i];
		len = ?(content.Count() <= 1, 57, 114);
		if (StrLen(s + word) > len) then
			content.Add(TrimAll(s));
			s = word;
		else
			s = s + separator + word;
		endif;
	enddo;
	content.Add(TrimAll(s));
	return content;
	
EndFunction

Function getCFC(Row)
	
	if (Row.Trezorerial) then
		code = TrimAll(Row.DivisionCode);
		if (code <> "") then
			code = "/" + code;
		endif;
	else
		code = "";
	endif;
	return TrimAll(Row.CodeFiscal) + code;
	
EndFunction

Function getBIC(AccountNumber, BankCode)
	
	bic = TrimAll(BankCode);
	if (Find(AccountNumber, "MD") <> 0) then
		bicLen = StrLen(bic);
		if (bicLen > 8) then
			bic = Left(bic, bicLen - (bicLen - 8));
		endif;
	endif;
	return bic
	
EndFunction

Procedure runComert()
	
	xmlWriter = new XMLWriter();
	stream = new MemoryStream ();
	xmlWriter.OpenStream(stream, "windows-1251");
	xmlWriter.WriteXMLDeclaration();
	xmlWriter.WriteStartElement("docs");
	for each row in Env.Rows do
		xmlWriter.WriteStartElement("doc");
		writeXMLElement("ID", "", xmlWriter);
		docNumber = PaymentOrder.NumberWithoutPrefix(row.Number, row.Prefix);
		writeXMLElement("ndoc", docNumber, xmlWriter);
		writeXMLElement("ddoc", Format(row.Date, "DF=dd.MM.yyyy") + " 0:00:00", xmlWriter);
		writeXMLElement("td", 1, xmlWriter);
		writeXMLElement("pay_account", row.AccountNumber, xmlWriter);
		writeXMLElement("pay_account_tr", "", xmlWriter);
		writeXMLElement("currency_d", row.CurrencyName, xmlWriter);
		writeXMLElement("pay_bic", TrimAll(row.BankCode), xmlWriter);
		payer = "(" + row.Residency + ") " + PaymentOrder.RemoveInadmissibleSymbols(deleteRomanianChars(TrimAll(row.CompanyName)));
		writeXMLElement("pay_client", payer, xmlWriter);
		writeXMLElement("pay_client_tr", "", xmlWriter);
		writeXMLElement("pay_fiscal", row.CodeFiscal, xmlWriter);
		writeXMLElement("pay_division", "", xmlWriter);
		writeXMLElement("rec_account", row.RecipientAccountNumber, xmlWriter);
		writeXMLElement("rec_account_tr", "", xmlWriter);
		writeXMLElement("currency_c", row.CurrencyCode, xmlWriter);
		writeXMLElement("rec_bic", TrimAll(row.RecipientBankCode), xmlWriter);
		client = PaymentOrder.RemoveInadmissibleSymbols(deleteRomanianChars(TrimAll(row.RecipientPresentation)));
		writeXMLElement("rec_client", client, xmlWriter);
		writeXMLElement("rec_client_tr", "", xmlWriter);
		writeXMLElement("rec_fiscal", row.RecipientCodeFiscal, xmlWriter);
		writeXMLElement("rec_division", "", xmlWriter);
		writeXMLElement("dest", getContent(row), xmlWriter);
		writeXMLElement("summ", Format(row.AmountWithoutTax, "NFD=2; NDS=,; NG="), xmlWriter);
		writeXMLElement("transcourse", "0", xmlWriter);
		writeXMLElement("trancode", ?(row.Trezorerial, "101", "1"), xmlWriter);
		writeXMLElement("tt", row.TransferType, xmlWriter);
		xmlWriter.WriteEndElement();
	enddo;
	xmlWriter.WriteEndElement();
	xmlWriter.Close();
	saveStream ( stream, PaymentsFile );
	
EndProcedure

Procedure writeXMLElement(Name, Value, XMLWriter)
	
	XMLWriter.WriteStartElement(Name);
	XMLWriter.WriteText(XMLString(Value));
	XMLWriter.WriteEndElement();
	
EndProcedure

Procedure runFinComPay()
	
	if ( Framework.IsLinux () ) then
		raise Output.LinuxNotSupported ();
	endif;
	xml = new COMObject("Microsoft.XMLDOM");
	xml.async = 0;
	xml.validateOnParse = 0;
	xml.resolveExternals = 0;
	xml.appendChild(xml.createProcessingInstruction("xml", "version='1.0' encoding='UTF-8' standalone='yes'"));
	root = xml.createElement("ROWDATA");
	xml.appendChild(root);
	for each row in Env.Rows do
		xmlRow = xml.createElement("ROW");
		xmlRow.setAttribute("BIC_A", TrimAll(row.BankCode));
		accountNumber = TrimAll(row.AccountNumber);
		xmlRow.setAttribute("ACCOUNTNO", parseFincompay(TrimAll(Mid(accountNumber, 1, StrLen(accountNumber) - 3) + "/" + String(row.CurrencyCode))));
		xmlRow.setAttribute("IBAN_A", accountNumber);
		xmlRow.setAttribute("BIC_B", TrimAll(row.RecipientBankCode));
		recipientAccount = TrimAll(row.RecipientAccountNumber);
		xmlRow.setAttribute("CORRACCOUNTNO", parseFincompay(recipientAccount, false));
		xmlRow.setAttribute("IBAN_B", recipientAccount);
		xmlRow.setAttribute("CORRTREZACCOUNTNO", TrimAll(row.TreasuryCode));
		xmlRow.setAttribute("TRANSACTIONCODE", row.TransactionCode);
		xmlRow.setAttribute("DOCUMENTNO", PaymentOrder.NumberWithoutPrefix(row.Number, row.Prefix));
		xmlRow.setAttribute("DOCUMENTDATE", Format(row.Date, "DF=yyMMdd"));
		xmlRow.setAttribute("AMOUNT", (row.AmountWithoutTax) * 100);
		xmlRow.setAttribute("CORRFISCALCODE", TrimAll(row.RecipientCodeFiscal));
		xmlRow.setAttribute("FISCALCODE", row.CodeFiscal);
		xmlRow.setAttribute("CORRSNAME", PaymentOrder.RemoveInadmissibleSymbols(deleteRomanianChars(TrimAll(row.RecipientPresentation))));
		xmlRow.setAttribute("DETAILSOFPAYMENT", Left(getContent(row), 210));
		xmlRow.setAttribute("CORRRESIDENCY", row.RecipientResidency);
		xmlRow.setAttribute("PRIORITY", row.TransferType);
		xmlRow.setAttribute("SUBDIVISIONCODE", String(fillLeft(Left(TrimAll(row.DivisionCode), 4), 4, " ")));
		xmlRow.setAttribute("STATENAME", "");
		xmlRow.setAttribute("CONTRAGENTSNAME", TrimAll(row.RecipientBankDescription));
		xmlRow.setAttribute("RESIDENCY", row.Residency);
		root.appendChild(xmlRow);
	enddo;
	saveXml(xml);
	
EndProcedure

Function parseFincompay(String, RemoveZeros = true)
	
	s = Right(String, 24);
	if (RemoveZeros) then
		onlyDigits(s);
	else
		s = Mid(s, 7);
	endif;
	if (RemoveZeros) then
		removeZeros(s);
	endif;
	return (s);
	
EndFunction

Function fillLeft(String, Length, Char = " ")
	
	count = Length - StrLen(String);
	s = "";
	while count > 0 do
		s = s + Char;
		count = count - 1;
	enddo;
	return s + String;
	
EndFunction

Procedure saveXml(XML)
	
	try
		XML.Save(TempFile);
		putToStorage(new BinaryData(TempFile), PaymentsFile);
	except
		Progress.Put(Output.UnableToSaveData(new Structure("Error", ErrorDescription())), JobKey, true);
	endtry;
	
EndProcedure

Procedure runEuroCreditBank()
	
	rows = Env.Rows;
	filter = new Structure("Trezorerial", true);
	runTrezorerialRows(rows.Copy(filter), "108", "TREZORIAL.108");
	filter.Trezorerial = false;
	runTrezorerialRows(rows.Copy(filter), "107", ".107");
	
EndProcedure

Procedure runTrezorerialRows(Rows, Code, Suffix)
	
	if (Rows.Count() = 0) then
		return;
	endif;
	text = new TextDocument();
	for each row in Rows do
		text.AddLine(lineEuroCreditBank(row, Code));
	enddo;
	saveText(text, PaymentsFile + Suffix, true);
	
EndProcedure

Function lineEuroCreditBank(Row, Code)
	
	content = Mid(getContent(Row), 1, 210);
	separator = "*";
	line = Code + separator +
		PaymentOrder.NumberWithoutPrefix(Row.Number, Row.Prefix) + separator +
		Format(Row.Date, "DF='yyyyMMdd'") + "*MDL*" +
		Format(Row.AmountWithoutTax, "NFD=2; NDS=.; NG=") + separator +
		TrimAll(Row.AccountNumber) + separator +
		TrimAll(Row.CodeFiscal) + separator +
		PaymentOrder.RemoveInadmissibleSymbols(TrimAll(Row.CompanyDescription)) + separator +
		TrimAll(Row.BankCode) + separator +
		TrimAll(Row.BankDescription) + separator +
		TrimAll(Row.RecipientBankCode) + separator +
		TrimAll(Row.RecipientBankDescription) + separator +
		TrimAll(Row.RecipientAccountNumber) + separator +
		TrimAll(Row.RecipientCodeFiscal) + separator +
		TrimAll(Row.RecipientPresentation) + separator +
		Left(content, 40) + separator +
		Mid(content, 40, 40) + separator +
		Mid(content, 80, 40) + separator +
		Mid(content, 120, 40) + separator +
		Mid(content, 160, 40) + separator +
		Mid(content, 200, 10) + separator +
		Row.TransferType;
	return line;
	
EndFunction

Procedure clean()
	
	DeleteFiles(TempFile);
	
EndProcedure

Procedure commitUnloading()
	
	SetPrivilegedMode(true);
	BeginTransaction();
	for each row in Env.Rows do
		obj = row.PaymentOrder.GetObject();
		obj.Unload = false;
		try
			obj.Write();
		except
			RollbackTransaction();
			ProcessingError = true;
			Progress.Put(Output.CommonError(new Structure("Error", ErrorDescription())), JobKey, true);
			return;
		endtry;
	enddo;
	CommitTransaction();
	
EndProcedure

#endif