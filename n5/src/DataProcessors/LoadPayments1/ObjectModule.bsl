#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Parameters export;
var JobKey export;
var App;
var Company;
var BankAccount;
var BankAccountCurrency;
var LocalCurrency;
var CurrencyRate;
var Account;
var OtherExpense;
var OtherReceipt;
var OtherExpenseData;
var OtherReceiptData;
var Details;
var Expenses;
var Receipts;
var Env;
var Fields;
var PaymentOrdersFilter;
var LineProcessing;
var DetailsTable;
var AccountInternal;
var Path;
var OnExpense;
var OnReceipt;
var ExecuteOnExpense;
var ExecuteOnReceipt;

Procedure Exec() export
	
	init();
	initTables();
	initAccounts();
	prepareFile();
	if (not readFile()) then
		return;
	endif;
	if (not processData()) then
		return;
	endif;
	putToStorage();
	
EndProcedure

Procedure init()
	
	SQL.Init(Env);
	program = Parameters.Application;
	data = DF.Values ( program, "Application, OnExpense, OnReceipt" );
	App = data.Application;
	OnExpense = data.OnExpense;
	OnReceipt = data.OnReceipt;
	ExecuteOnExpense = ValueIsFilled ( OnExpense );
	ExecuteOnReceipt = ValueIsFilled ( OnReceipt );
	Company = Parameters.Company;
	BankAccount = Parameters.BankAccount;
	BankAccountCurrency = Parameters.BankAccountCurrency;
	LocalCurrency = Application.Currency ();
	Account = Parameters.Account;
	OtherExpense = Parameters.OtherExpense;
	OtherReceipt = Parameters.OtherReceipt;
	LineProcessing = new Structure("Line");
	if ( LocalCurrency <> BankAccountCurrency ) then
		CurrencyRate = CurrenciesSrv.Get ( BankAccountCurrency, Parameters.Date );
	endif
	
EndProcedure

Procedure initTables()
	
	obj = Documents.LoadPayments.CreateDocument();
	Receipts = obj.Receipts.Unload ();
	Expenses = obj.Expenses.Unload ();
	Details = obj.Details.Unload ();
	DetailsTable = Details.Copy();
	columns = DetailsTable.Columns;
	boolean = new TypeDescription("Boolean");
	columns.Add("Expense", boolean);
	columns.Add("UseExpense", boolean);
	
EndProcedure

Procedure initAccounts()
	
	OtherExpenseData = DF.Values(OtherExpense, "
	|AccountDr as Account, DimDr1 as Dim1, DimDr2 as Dim2, DimDr3 as Dim3");
	OtherReceiptData = DF.Values(OtherReceipt, "
	|AccountCr as Account, DimCr1 as Dim1, DimCr2 as Dim2, DimCr3 as Dim3");
	
EndProcedure

Procedure prepareFile()
	
	tempPath = GetTempFileName();
	Parameters.File.Write(tempPath);
	tempFile = new File(tempPath);
	Path = tempFile.Path + Left(tempFile.BaseName, 8) + tempFile.Extension;
	MoveFile(tempPath, Path);
	
EndProcedure

Function readFile()
	
	if (App = Enums.Banks.VictoriaBank
			or App = Enums.Banks.Energbank
			or App = Enums.Banks.ProCreditBank) then
		return readVictoriaBank();
	elsif (App = Enums.Banks.Mobias) then
		return readMobias();
	elsif (App = Enums.Banks.MAIB) then
		return readMaib();
	elsif (App = Enums.Banks.Eximbank) then
		return readEximbank();
	elsif (App = Enums.Banks.FinComPay) then
		return readFinComPay();
	elsif (App = Enums.Banks.EuroCreditBank) then
		return readEuroCreditBank();
	elsif (App = Enums.Banks.Comert ) then
		return readComert();
	endif;
	
EndFunction

Function readVictoriaBank()
	
	textReader = new TextReader(Path);
	lineCounter = 0;
	docStart = false;
	initFields();
	lineNumber = 1;
	while (true) do
		line = textReader.ReadLine();
		if (line = undefined) then
			break;
		endif;
		lineCounter = lineCounter + 1;
		if (not checkTxtFormat(lineCounter, line)) then
			return false;
		endif;
		processingLine(lineCounter);
		equal = Find(line, "=");
		operator = TrimAll(Left(line, ?(equal = 0, StrLen(line), equal - 1)));
		value = ?(equal = 0, undefined, TrimAll(Mid(line, equal + 1)));
		if (operator = "DocStart") then
			rowDetails = getDetailsRow(lineNumber);
			docStart = true;
			continue;
		elsif (operator = "DocEnd") then
			docStart = false;
			continue;
		endif;
		if (docStart) then
			fillRowDetails(rowDetails, operator, value);
		endif;
	enddo;
	return true;
	
EndFunction

Procedure initFields()
	
	Fields = new Structure();
	Fields.Insert("DOCUMENTNUMBER", "OrderNumber");
	Fields.Insert("PAYERACCOUNT", "PayerAccount");
	Fields.Insert("PAYERACCOUNT", "PayerAccount");
	Fields.Insert("PAYERFCODE", "PayerFiscalCode");
	Fields.Insert("PAYERBANKBIC", "PayerBankCode");
	Fields.Insert("PAYER", "Payer");
	Fields.Insert("PAYERBANK", "PayerBank");
	Fields.Insert("RECEIVER", "Receiver");
	Fields.Insert("RECEIVERFCODE", "ReceiverFiscalCode");
	Fields.Insert("RECEIVERACCOUNT", "ReceiverAccount");
	Fields.Insert("RECEIVERBANKBIC", "ReceiverBankCode");
	Fields.Insert("RECEIVERBANK", "ReceiverBank");
	Fields.Insert("AMOUNT", "Amount");
	Fields.Insert("GROUND", "PaymentContent");
	Fields.Insert("OPERTYPE", "Type");
	Fields.Insert("TRANSACTIONCODE", "TransactionCode");
	Fields.Insert("TRANSFERTYPE", "TransferType");
	Fields.Insert("DEBETSUBACCOUNT", "PayerSubaccount");
	Fields.Insert("CREDITSUBACCOUNT", "ReceiverSubaccount");
	
EndProcedure

Function checkTxtFormat(Line, String)
	
	if (Line = 1
			and String <> "1CClientBankExchange(V:M.1)") then
		Progress.Put(Output.WrongFileFormat(), JobKey, true);
		return false;
	endif;
	return true;
	
EndFunction

Procedure processingLine(Line)
	
	LineProcessing.Line = Line;
	Progress.Put(Output.ProcessingLine(LineProcessing), JobKey);
	
EndProcedure

Function getDetailsRow(Line, IncreaseLine = true)
	
	row = DetailsTable.Add();
	row.LineNumber = Line;
	if (IncreaseLine) then
		Line = Line + 1;
	endif;
	return row;
	
EndFunction

Procedure fillRowDetails(Row, Operator, Value)
	
	if (Operator = "DOCUMENTDATE") then
		Row.OrderDate = dateFromString(Value);
	elsif (Operator = "DATEWRITTEN") then
		Row.Date = dateFromString(Value);
	else
		if (Fields.Property(Operator)) then
			Row[Fields[Operator]] = Value;
		endif;
	endif;
	
EndProcedure

Function dateFromString(String)
	
	s = TrimAll(String);
	if (s = "") then
		return Date(1, 1, 1);
	else
		return Date(Mid(s, 7, 4) + Mid(s, 4, 2) + Mid(s, 1, 2));
	endif;
	
EndFunction

Function readMobias()
	
	xBase = getXBaseMobias();
	if (xBase = undefined) then
		return false;
	endif;
	xBase.First();
	for line = 1 to xBase.RecCount() do
		xBase.GoTo(line);
		processingLine(line);
		row = getDetailsRow(line, false);
		row.UseExpense = true;
		row.Type = 1;
		id = TrimAll(xBase.ID);
		if (ValueIsFilled(id)) then
			row.OrderNumber = id;
			row.OrderDate = dateFromString(xBase.DATAINTROD);
			row.Date = dateFromString(xBase.DATA);
			row.Amount = xBase.SUMA;
			row.PaymentContent = xBase.DESTINATIA;
			row.Payer = xBase.KLIENT;
			row.PayerBankCode = xBase.MFO;
			row.PayerBank = xBase.Bank;
			row.PayerFiscalCode = xBase.FKOD;
			payerAccount = xBase.NOMERSCETA;
			row.PayerAccount = payerAccount;
			row.PayerIBAN = payerAccount;
			receiverAccount = xBase.SCETMY;
			row.ReceiverAccount = receiverAccount;
			row.ReceiverIBAN = receiverAccount;
		else
			row.Expense = true;
			row.OrderNumber = TrimAll ( xBase.ID_D );
			date = dateFromString(xBase.DATA_D);
			row.OrderDate = date;
			row.Date = date;
			row.Amount = xBase.SUMA_D;
			row.PaymentContent = xBase.DESTIN_D;
			row.Receiver = xBase.KLIENT_D;
			row.ReceiverBankCode = xBase.MFO_D;
			row.ReceiverBank = xBase.BANK_D;
			row.ReceiverFiscalCode = xBase.FKOD_D;
			payerAccount = xBase.SCETMY_D;
			row.PayerAccount = payerAccount;
			row.PayerIBAN = payerAccount;
			receiverAccount = xBase.SCET_D;
			row.ReceiverAccount = receiverAccount;
			row.ReceiverIBAN = receiverAccount;
		endif;
	enddo;
	if (not closeXBase(xBase)) then
		return false;
	endif;
	return true;
	
EndFunction

Function getXBaseMobias()
	
	xBase = getXBase(XBaseEncoding.ANSI);
	if (xBase = undefined) then
		return undefined;
	endif;
	if (not checkStructureMobias(xBase)) then
		return undefined;
	endif;
	return xBase;
	
EndFunction

Function getXBase(Encoding)
	
	xBase = new XBase(Encoding);
	xBase.Encoding = Encoding;
	try
		xBase.OpenFile(Path, , true);
	except
		Progress.Put(Output.UnableToOpenFile(new Structure("Error", ErrorDescription())), JobKey, true);
		return undefined;
	endtry;
	if (not xBase.IsOpen()) then
		Progress.Put(Output.DBFFileNotOpened(), JobKey, true);
		return undefined;
	endif;
	return xBase;
	
EndFunction

Function checkStructureMobias(Xbase)
	
	fields = Xbase.Fields;
	if (fields.Find("ID") = undefined)
		or (fields.Find("KLIENT") = undefined)
		or (fields.Find("SUMA") = undefined)
		or (fields.Find("MFO") = undefined)
		or (fields.Find("Bank") = undefined)
		or (fields.Find("DATAINTROD") = undefined)
		or (fields.Find("DATA") = undefined)
		or (fields.Find("DESTINATIA") = undefined)
		or (fields.Find("FKOD") = undefined)
		or (fields.Find("NOMERSCETA") = undefined)
		or (fields.Find("SCETMY") = undefined)
		or (fields.Find("ID_D") = undefined)
		or (fields.Find("KLIENT_D") = undefined)
		or (fields.Find("SUMA_D") = undefined)
		or (fields.Find("MFO_D") = undefined)
		or (fields.Find("BANK_D") = undefined)
		or (fields.Find("DATA_D") = undefined)
		or (fields.Find("DESTIN_D") = undefined)
		or (fields.Find("FKOD_D") = undefined)
		or (fields.Find("SCET_D") = undefined)
		or (fields.Find("SCETMY_D") = undefined) then
		Progress.Put(Output.DBFInvalidStructure(), JobKey, true);
		closeXBase(Xbase);
		return false;
	endif;
	return true;
	
EndFunction

Function closeXBase(Xbase)
	
	try
		Xbase.CloseFile();
	except
		Progress.Put(Output.CommonError(new Structure("Error", ErrorDescription())), JobKey, true);
		return false;
	endtry;
	return true;
	
EndFunction

Function readMaib()
	
	xBase = getXBaseMaib();
	if (xBase = undefined) then
		return false;
	endif;
	for line = 2 to xBase.RecCount() do
		xBase.GoTo(line);
		processingLine(line);
		row = getDetailsRow(line - 1, false);
		row.OrderNumber = TrimAll ( xBase.NDOC );
		date = xBase.DATA;
		row.OrderDate = date;
		row.Date = date;
		row.Amount = xBase.SUML;
		row.CurrencyAmount = xBase.SUMN;
		row.PaymentContent = xBase.DE1 + xBase.DE2 + xBase.DE3 + xBase.DE4;
		row.PayerFiscalCode = xBase.CFC;
		row.ReceiverFiscalCode = xBase.CFCCOR;
		row.TransferType = xBase.URGENT;
		row.TransactionCode = xBase.COD_TRANZ;
		row.Type = xBase.TD;
		row.ReceiverSubaccount = TrimAll(xBase.CCORT);
		if (xBase.DC = "1") then
			row.UseExpense = true;
			row.Payer = xBase.DENC;
			row.PayerBankCode = xBase.BIC;
			payerAccount = TrimAll(xBase.CCOR);
			row.PayerAccount = payerAccount;
			row.PayerIBAN = payerAccount;
			receiverAccount = getAccount(xBase.CCL);
			row.ReceiverAccount = receiverAccount;
			row.ReceiverIBAN = receiverAccount;
		elsif (xBase.DC = "0") then
			row.UseExpense = true;
			row.Expense = true;
			row.Receiver = xBase.DENC;
			row.ReceiverBankCode = xBase.BIC;
			iban = TrimAll(xBase.CCOR);
			row.ReceiverIBAN = iban;
			row.ReceiverAccount = iban;
			payerAccount = getAccount(xBase.CCL);
			row.PayerAccount = payerAccount;
			row.PayerIBAN = payerAccount;
		endif;
	enddo;
	if (not closeXBase(xBase)) then
		return false;
	endif;
	return true;
	
EndFunction

Function getXBaseMaib()
	
	xBase = getXBase(XBaseEncoding.OEM);
	if (xBase = undefined) then
		return undefined;
	endif;
	if (not checkStructureMaib(xBase)) then
		return undefined;
	endif;
	return xBase;
	
EndFunction

Function checkStructureMaib(XBase)
	
	fields = XBase.fields;
	if (fields.Find("DATA") = undefined
			or fields.Find("NDOC") = undefined
			or fields.Find("DC") = undefined
			or fields.Find("ST") = undefined
			or fields.Find("CCL") = undefined
			or fields.Find("CCOR") = undefined
			or fields.Find("CCORT") = undefined
			or fields.Find("CFC") = undefined
			or fields.Find("CFCCOR") = undefined
			or fields.Find("CBC") = undefined
			or fields.Find("DENC") = undefined
			or fields.Find("SUMN") = undefined
			or fields.Find("SUML") = undefined
			or fields.Find("TD") = undefined
			or fields.Find("DE1") = undefined
			or fields.Find("DE2") = undefined
			or fields.Find("DE3") = undefined
			or fields.Find("DE4") = undefined
			or fields.Find("PRI") = undefined
			or fields.Find("DAT_AC") = undefined
			or fields.Find("BIC") = undefined
			or fields.Find("COD_TRANZ") = undefined
			or fields.Find("URGENT") = undefined) then
		Progress.Put(Output.DBFInvalidStructure(), JobKey, true);
		closeXBase(Xbase);
		return false;
	endif;
	return true;
	
EndFunction

Function getAccount(String)
	
	return ?(StrLen(String) = 24, parse(String), String);
	
EndFunction

Function parse(String)
	
	s = Right(String, 24);
	onlyDigits(s);
	removeZeros(s);
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

Function readEximbank()
	
	xBase = getXBaseEximbank();
	if (xBase = undefined) then
		return false;
	endif;
	currency = DF.Pick(BankAccountCurrency, "Description as Currency");
	for line = 2 to xBase.RecCount() do
		xBase.GoTo(line);
		if (not checkCurrency(xBase, currency)) then
			return false;
		endif;
		processingLine(line);
		row = getDetailsRow(line - 1, false);
		row.OrderNumber = TrimAll ( xBase.DOCUMENT );
		date = xBase.DATA;
		row.OrderDate = date;
		row.Date = date;
		row.Amount = xBase.SUML;
		row.CurrencyAmount = xBase.SUMN;
		row.PaymentContent = xBase.DE1 + xBase.DE2 + xBase.DE3 + xBase.DE4;
		row.TransferType = xBase.URGENT;
		row.TransactionCode = TrimAll(xBase.COD_TRANZ);
		row.Type = xBase.TD;
		row.ReceiverSubaccount = TrimAll(xBase.CCORT);
		if (xBase.DC = "C") then
			row.Payer = xBase.DENC + xBase.DENCT;
			row.PayerBankCode = TrimAll(xBase.BIC);
			row.PayerFiscalCode = TrimAll(xBase.CFCCOR);
			payerAccount = TrimAll(xBase.CCOR);
			row.PayerAccount = payerAccount;
			row.PayerIBAN = payerAccount;
			receiverAccount = TrimAll(xBase.CCL);
			row.ReceiverAccount = receiverAccount;
			row.ReceiverIBAN = receiverAccount;
			row.ReceiverFiscalCode = TrimAll(xBase.CFC);
		elsif (xBase.DC = "D") then
			row.Receiver = xBase.DENC + xBase.DENCT;
			row.ReceiverBankCode = TrimAll(xBase.BIC);
			row.ReceiverFiscalCode = TrimAll(xBase.CFCCOR);
			receiverAccount = TrimAll(xBase.CCOR);
			row.ReceiverIBAN = receiverAccount;
			row.ReceiverAccount = receiverAccount;
			payerAccount = TrimAll(xBase.CCL);
			row.PayerAccount = payerAccount;
			row.PayerIBAN = payerAccount;
			row.PayerFiscalCode = TrimAll(xBase.CFC);
		endif;
	enddo;
	if (not closeXBase(xBase)) then
		return false;
	endif;
	return true;
	
EndFunction

Function getXBaseEximbank()
	
	xBase = getXBase(XBaseEncoding.OEM);
	if (xBase = undefined) then
		return undefined;
	endif;
	if (not checkStructureExim(xBase)) then
		return undefined;
	endif;
	return xBase;
	
EndFunction

Function checkStructureExim(Xbase)
	
	fields = Xbase.fields;
	if (fields.Find("DATA") = undefined
			or fields.Find("NDOC") = undefined
			or fields.Find("DC") = undefined
			or fields.Find("ST") = undefined
			or fields.Find("CCL") = undefined
			or fields.Find("CCOR") = undefined
			or fields.Find("CCORT") = undefined
			or fields.Find("CFC") = undefined
			or fields.Find("CFCCOR") = undefined
			or fields.Find("CBC") = undefined
			or fields.Find("DENC") = undefined
			or fields.Find("DENCT") = undefined
			or fields.Find("TV") = undefined
			or fields.Find("SUMN") = undefined
			or fields.Find("SUML") = undefined
			or fields.Find("TD") = undefined
			or fields.Find("DE1") = undefined
			or fields.Find("DE2") = undefined
			or fields.Find("DE3") = undefined
			or fields.Find("DE4") = undefined
			or fields.Find("PRI") = undefined
			or fields.Find("DAT_TR") = undefined
			or fields.Find("DAT_AC") = undefined
			or fields.Find("BIC") = undefined
			or fields.Find("COD_TRANZ") = undefined
			or fields.Find("URGENT") = undefined
			or fields.Find("DOCUMENT") = undefined
			or fields.Find("CONT_CORES") = undefined) then
		Progress.Put(Output.DBFInvalidStructure(), JobKey, true);
		closeXBase(Xbase);
		return false;
	endif;
	return true;
	
EndFunction

Function checkCurrency(Xbase, Currency)
	
	if (Xbase.TV <> Currency) then
		Progress.Put(Output.AccountCurrencyError(), JobKey, true);
		closeXBase(Xbase);
		return false;
	endif;
	return true;
	
EndFunction

Function readFinComPay()
	
	table = finComTable();
	extractFinCom(table);
	if (table.Count() = 0) then
		return false;
	endif;
	line = 1;
	for each rowFile in table do
		expense = getExpense(rowFile);
		if (expense = undefined) then
			continue;
		endif;
		processingLine(line);
		row = getDetailsRow(line);
		row.Amount = Conversion.StringToNumber ( rowFile.AMOUNT ) / 100;
		row.UseExpense = true;
		row.OrderNumber = TrimAll ( rowFile.DOCUMENTNO );
		row.OrderDate = finComDate ( rowFile.DOCUMENTDATE );
		row.Date = finComDate ( rowFile.POSTINGDATE );
		row.PaymentContent = rowFile.DETAILSOFPAYMENT;
		row.Type = 1;
		row.TransactionCode = rowFile.TRANSACTIONCODE;
		if (expense) then
			row.Expense = true;
			row.Receiver = rowFile.CORRSNAME;
			row.ReceiverBankCode = rowFile.BIC_B;
			row.ReceiverIBAN = rowFile.IBAN_B;
			row.ReceiverFiscalCode = rowFile.CORRFISCALCODE;
			row.PayerAccount = accountFromString(rowFile.ACCOUNTNO);
			row.Payer = rowFile.SNAME;
			row.PayerBankCode = rowFile.BIC_A;
			row.PayerIBAN = rowFile.IBAN_A;
			row.PayerFiscalCode = rowFile.FISCALCODE;
			row.ReceiverAccount = rowFile.CORRACCOUNTNO;
		else
			row.Payer = rowFile.CORRSNAME;
			row.PayerBankCode = rowFile.BIC_B;
			row.PayerIBAN = rowFile.IBAN_B;
			row.PayerFiscalCode = rowFile.CORRFISCALCODE;
			row.PayerAccount = rowFile.CORRACCOUNTNO;
			row.ReceiverAccount = accountFromString(rowFile.ACCOUNTNO);
			row.Receiver = rowFile.SNAME;
			row.ReceiverBankCode = rowFile.BIC_A;
			row.ReceiverIBAN = rowFile.IBAN_A;
			row.ReceiverFiscalCode = rowFile.FISCALCODE;
		endif;
	enddo;
	return true;
	
EndFunction

Function finComTable()
	
	table = new ValueTable();
	columns = table.Columns;
	columns.Add("SUMMAEQ");
	columns.Add("DOCUMENTID");
	columns.Add("PRIORITY");
	columns.Add("CORRSUBDIVISIONCODE");
	columns.Add("SUBDIVISIONCODE");
	columns.Add("TREZACCOUNTNO");
	columns.Add("FISCALCODE");
	columns.Add("SNAME");
	columns.Add("DETAILSOFPAYMENT");
	columns.Add("CORRSNAME");
	columns.Add("CORRFISCALCODE");
	columns.Add("POSTINGDATE");
	columns.Add("AMOUNT");
	columns.Add("DOCUMENTDATE");
	columns.Add("OPERATIONTYPE");
	columns.Add("CURRENCYID");
	columns.Add("DOCUMENTNO");
	columns.Add("TRANSACTIONCODE");
	columns.Add("CORRTREZACCOUNTNO");
	columns.Add("CORRACCOUNTNO");
	columns.Add("BIC_B");
	columns.Add("ACCOUNTNO");
	columns.Add("BIC_A");
	columns.Add("IBAN_A");
	columns.Add("IBAN_B");
	return table;
	
EndFunction

Procedure extractFinCom(Table)
	
	reader = getXMLReader();
	if (reader = undefined) then
		return;
	endif;
	builder = new DOMBuilder();
	xml = builder.Read(reader);
	structure = new Structure();
	for each node in xml.ChildNodes do
		structure.Insert(node.NodeName, node.ChildNodes);
		addChildNodes(structure, node);
	enddo;
	for each row in structure.ROWDATA do
		rowTable = Table.Add();
		for each attribute in row.Attributes do
			try
				rowTable[attribute.LocalName] = attribute.NodeValue;
			except
				Progress.Put(Output.UnableToReadFile(new Structure("Error", ErrorDescription())), JobKey, true);
			endtry;
		enddo;
	enddo;
	reader.Close();
	
EndProcedure

Function getXMLReader()
	
	xmlReader = new XMLReader();
	try
		xmlReader.OpenFile(Path);
	except
		Progress.Put(Output.UnableToOpenFile(new Structure("Error", ErrorDescription())), JobKey, true);
		return undefined;
	endtry;
	return xmlReader;
	
EndFunction

Procedure addChildNodes(Structure, XML)
	
	for each node in XML.ChildNodes do
		if (node.Attributes <> undefined) then
			Structure.Insert(node.NodeName, node.ChildNodes);
			addChildNodes(Structure, node);
		endif;
	enddo;
	
EndProcedure

Function getExpense(Row)
	
	type = Row.OPERATIONTYPE;
	if (String(type) = "0") then
		return true;
	elsif (String(type) = "1") then
		return false;
	endif;
	return undefined
	
EndFunction

Function accountFromString(String)
	
	newAccount = Find(String, "/") - 1;
	if (newAccount <> 0) then
		String = Left(String, newAccount);
	endif;
	return String;
	
EndFunction

Function finComDate ( String )
	
	String = TrimAll( String );
	if ( String = "" ) then
		return Date ( 1, 1, 1 );
	endif;
	return Date ( "20" + Mid ( String, 1, 2 ) + Mid ( String, 3, 2 ) + Mid ( String, 5, 2 ) );
	
EndFunction

Function readComert()
	
	table = comertTable();
	extractComert(table);
	if (table.Count() = 0) then
		return false;
	endif;
	line = 1;
	for each row in table do
		processingLine(line);
		newRow = getDetailsRow(line);
		newRow.OrderNumber = TrimAll ( row.ndoc );
		date = comertDate ( row.ddoc );
		newRow.OrderDate = date;
		newRow.Date = date;
		newRow.Amount = Conversion.StringToNumber ( StrReplace ( row.summ, ",", "." ) );
		newRow.PaymentContent = row.dest;	
		newRow.Payer = row.pay_client;
		newRow.PayerBankCode = row.pay_bic;
		newRow.PayerFiscalCode = row.pay_fiscal;	
		newRow.PayerAccount = row.pay_account;
		newRow.ReceiverAccount = row.rec_account;     
		newRow.Receiver = row.rec_client;
		newRow.ReceiverBankCode = row.rec_bic;
		newRow.ReceiverFiscalCode = row.rec_fiscal;
		newRow.TransactionCode = row.trancode;
	enddo;
	return true;
	
EndFunction

Function comertTable ()
	
	table = new ValueTable ();
	columns = table.Columns;
	columns.Add ( "ID" );
	columns.Add ( "ndoc" );
	columns.Add ( "ddoc" );
	columns.Add ( "td" );
	columns.Add ( "pay_account" );
	columns.Add ( "pay_account_tr" );
	columns.Add ( "currency_d" );
	columns.Add ( "pay_bic" );
	columns.Add ( "pay_client" );
	columns.Add ( "pay_client_tr" );
	columns.Add ( "pay_fiscal" );
	columns.Add ( "pay_division" );
	columns.Add ( "rec_account" );
	columns.Add ( "rec_account_tr" );
	columns.Add ( "currency_c" );
	columns.Add ( "rec_bic" );
	columns.Add ( "rec_client" );
	columns.Add ( "rec_client_tr" );
	columns.Add ( "rec_fiscal" );
	columns.Add ( "rec_division" );
	columns.Add ( "dest" );
	columns.Add ( "summ" );
	columns.Add ( "transcourse" );
	columns.Add ( "trancode" );
	columns.Add ( "tt" );
	return table;

EndFunction

Procedure extractComert ( Table )
	
	reader = getXMLReader ();
	builder = new DOMBuilder ();
	document = builder.Read ( reader );
	root = document.FirstChild;
	for each node in root.ChildNodes do
		row = Table.Add ();
		for each child in node.ChildNodes do
			try
				row [ child.NodeName ] = child.TextContent;
			except
				Progress.Put(Output.UnableToReadFile(new Structure("Error", ErrorDescription())), JobKey, true);
			endtry;
		enddo;				
	enddo;
	reader.Close ();

EndProcedure 

Function comertDate ( S )
	
	parts = StrSplit ( S, "." );
	return Date ( parts [ 2 ], parts [ 1 ], parts [ 0 ] );
	
EndFunction

Function readEuroCreditBank()
	
	textReader = new TextReader(Path);
	lineCounter = 1;
	while (true) do
		line = textReader.ReadLine();
		if (line = undefined) then
			break;
		endif;
		comand = Mid(line, 2, 2);
		if (comand <> "61") then
			continue;
		endif;
		processingLine(lineCounter);
		row = getDetailsRow(lineCounter);
		row.Type = 1;
		values = StrSplit(line, "*");
		if (values.Count() < 34) then
			Progress.Put(Output.WrongFileFormat(), JobKey, true);
			return false;
		endif;
		row.OrderNumber = TrimAll ( values[12] );
		try
			date = Date(values[14]);
		except
			date = Date(1, 1, 1);
		endtry;
		row.OrderDate = date;
		row.Date = date;
		row.Amount = values[17];
		row.Payer = values[21];
		row.PayerFiscalCode = values[22];
		row.PayerAccount = values[23];
		row.PayerBankCode = values[26];
		row.Receiver = values[27];
		row.ReceiverFiscalCode = values[28];
		row.ReceiverAccount = values[29];
		row.ReceiverBankCode = values[32];
		row.PaymentContent = values[33];
	enddo;
	return true;
	
EndFunction

Function processData()
	
	if (DetailsTable.Count() = 0) then
		Progress.Put(Output.DataNotFound(), JobKey, true);
		return false;
	endif;
	getData();
	isMaib = (App = Enums.Banks.MAIB);
	for each rowDetail in Env.Details do
		type = rowDetail.Type;
		if (error(rowDetail)
			or repeat(rowDetail)
			or type = "DE"
			or type = "CR") then
			continue;
		endif;
		expense = rowDetail.Expense;
		if (expense) then
			row = Expenses.Add();
			fillExpense(row, rowDetail);
		else
			row = Receipts.Add();
			fillReceipt(row, rowDetail);
		endif;
		findOperations(row, rowDetail, isMaib);
		row.Download = true;
		row.DetailsLine = rowDetail.LineNumber;
		row.Amount = rowDetail.Amount;
		row.Date = rowDetail.Date;
	enddo;
	return true;
	
EndFunction

Procedure getData()
	
	setDetailsFields();
	sqlFields();
	getFields();
	sqlDetails();
	sqlRepeats();
	sqlOrganizations();
	sqlPaymentOrders();
	sqlCashFlows();
	getTables();
	adjustFields();
	setCashFlows();
	PaymentOrdersFilter = new Structure("OrderDate, OrderNumber, ReceiverAccount, ReceiverSubaccount");
	
EndProcedure

Procedure setDetailsFields()
	
	fieldsJoin = new Array();
	fieldsAlias = new Array();
	for each attribute in Metadata.Documents.LoadPayments.TabularSections.Details.Attributes do
		name = attribute.Name;
		field = "Details." + name;
		fieldsJoin.Add("DetailsRef." + name + " = " + field);
		fieldsAlias.Add(field + " as " + name);
	enddo;
	fieldsAlias.Add("Details.LineNumber as LineNumber");
	Env.Insert("DetailsFieldsJoin", StrConcat(fieldsJoin, " and "));
	Env.Insert("DetailsFieldsAlias", StrConcat(fieldsAlias, ", "));
	
EndProcedure

Procedure sqlFields()
	
	s = "
		|// @Fields
		|select Company.CodeFiscal as CodeFiscal
		|from Catalog.Companies as Company
		|where Company.Ref = &Company
		|";
	Env.Selection.Add(s);
	
EndProcedure

Procedure getFields()
	
	Env.Q.SetParameter("Company", Company);
	SQL.Perform(Env);
	
EndProcedure

Procedure sqlDetails()
	
	detailFields = Env.DetailsFieldsAlias;
	s = "
	|// RawDetails
	|select " + detailFields + ",
	|	Details.UseExpense as UseExpense, Details.Expense as Expense
	|into RawDetails
	|from &Details as Details
	|;
	|// Details
	|select " + detailFields + ",
	|	BankAccounts.Currency as Currency,
	|	case when Details.UseExpense or Details.PayerFiscalCode = &CodeFiscal or Details.ReceiverFiscalCode = &CodeFiscal then false else true end as Error,
	|	case when Details.UseExpense then Details.Expense
	|		else Details.PayerFiscalCode = &CodeFiscal and Details.PayerAccount = BankAccounts.AccountNumber
	|	end as Expense,
	|	case when Details.UseExpense
	|		then ( Details.Expense and Details.ReceiverFiscalCode = &CodeFiscal ) or ( not Details.Expense and Details.PayerFiscalCode = &CodeFiscal )
	|		else Details.PayerFiscalCode = &CodeFiscal and Details.ReceiverFiscalCode = &CodeFiscal
	|	end as Internal
	|into Details
	|from RawDetails as Details
	|	//
	|	// BankAccounts
	|	//
	|	left join Catalog.BankAccounts as BankAccounts
	|	on BankAccounts.Ref = &BankAccount
	|;
	|// #Details
	|select " + detailFields + ", Details.Error or Details.Amount = 0 or Details.Date = datetime ( 1, 1, 1 ) as Error,
	|	Details.Expense as Expense, Details.Internal as Internal,
	|	InternalReceivers.Ref as InternalReceiverAccount, InternalSenders.Ref as InternalSenderAccount
	|from Details as Details
	|	//
	|	// InternalReceivers
	|	//
	|	left join Catalog.BankAccounts as InternalReceivers
	|	on InternalReceivers.Owner = &Company
	|	and InternalReceivers.AccountNumber = Details.ReceiverAccount
	|	and InternalReceivers.Currency = Details.Currency
	|	and not InternalReceivers.DeletionMark
	|	and Details.Internal
	|	and Details.Expense
	|	//
	|	// InternalSenders
	|	//
	|	left join Catalog.BankAccounts as InternalSenders
	|	on InternalSenders.Owner = &Company
	|	and InternalSenders.AccountNumber = Details.PayerAccount
	|	and InternalSenders.Currency = Details.Currency
	|	and not InternalSenders.DeletionMark
	|	and Details.Internal
	|	and not Details.Expense
	|";
	Env.Selection.Add(s);
	
EndProcedure

Procedure sqlRepeats()
	
	s = "
	|// Repeats
	|select DetailsRef.Ref as Ref, DetailsRef.LineNumber as DetailsLine, Details.LineNumber as LineNumber, Details.Expense as Expense
	|into Repeats
	|from Details as Details
	|	//
	|	//	Details
	|	//
	|	inner join Document.LoadPayments.Details as DetailsRef
	|	on " + Env.DetailsFieldsJoin + "
	|where not Details.Error
	|and not DetailsRef.Ref.DeletionMark
	|;
	|// #Repeats
	|select Repeats.LineNumber as LineNumber, Table.Document as Document, true as Expense, Table.Account as Account,
	|	Table.AdvanceAccount as AdvanceAccount, Table.BankOperation as BankOperation, Table.Operation as Operation,
	|	Table.CashFlow as CashFlow, Table.Dim1 as Dim1, Table.Dim2 as Dim2, Table.Dim3 as Dim3,
	|	Table.Currency as Currency, Table.Rate as Rate, Table.Factor as Factor, Table.CurrencyAmount as CurrencyAmount,
	|	Table.Date as Date, Table.Amount as Amount, Table.PaymentContent as PaymentContent
	|from Document.LoadPayments.Expenses as Table
	|	//
	|	// Repeats
	|	//
	|	inner join Repeats as Repeats
	|	on Repeats.Ref = Table.Ref
	|	and Repeats.DetailsLine = Table.DetailsLine
	|	and Repeats.Expense
	|where not Table.Document.DeletionMark
	|union all
	|select Repeats.LineNumber, Table.Document, false, Table.Account, Table.AdvanceAccount, Table.BankOperation,
	|	Table.Operation, Table.CashFlow, Table.Dim1, Table.Dim2, Table.Dim3, Table.Currency, Table.Rate, Table.Factor,
	|	Table.CurrencyAmount, Table.Date, Table.Amount, Table.PaymentContent
	|from Document.LoadPayments.Receipts as Table
	|	//
	|	// Repeats
	|	//
	|	inner join Repeats as Repeats
	|	on Repeats.Ref = Table.Ref
	|	and Repeats.DetailsLine = Table.DetailsLine
	|	and not Repeats.Expense
	|where not Table.Document.DeletionMark
	|";
	Env.Selection.Add(s);
	
EndProcedure

Procedure sqlOrganizations()
	
	s = "
	|// #Organizations
	|select Details.LineNumber as LineNumber, Organizations.Ref as Organization, Organizations.Ref.Customer as Customer, 
	|	Organizations.Ref.CustomerContract as CustomerContract, Organizations.Ref.Vendor as Vendor,
	|	Organizations.Ref.VendorContract as VendorContract, Organizations.Ref.CustomerContract.CustomerCashFlow as CustomerCashFlow,
	|	Organizations.Ref.VendorContract.VendorCashFlow as VendorCashFlow
	|from Details as Details
	|	//
	|	// Organizations
	|	//
	|	join (
	|		select Details.LineNumber as LineNumber, Organizations.Ref as Ref
	|		from Details as Details
	|			//
	|			//	Organizations
	|			//
	|			join Catalog.Organizations as Organizations
	|			on not Organizations.DeletionMark
	|			and Organizations.CodeFiscal = case when Details.Expense then Details.ReceiverFiscalCode else Details.PayerFiscalCode end
	|		where not Details.Error
	|		and Organizations.CodeFiscal <> """"
	|		union
	|		select Details.LineNumber, BankAccounts.Owner
	|		from Details as Details
	|			//
	|			//	BankAccounts
	|			//
	|			join Catalog.BankAccounts as BankAccounts
	|			on not BankAccounts.DeletionMark
	|			and BankAccounts.AccountNumber = Details.ReceiverAccount
	|			and BankAccounts.Owner refs Catalog.Organizations
	|		where not Details.Error
	|		and Details.Expense
	|		and Details.ReceiverFiscalCode = """"
	|		and Details.ReceiverAccount <> """"
	|		union
	|		select Details.LineNumber, BankAccounts.Owner
	|		from Details as Details
	|			//
	|			//	BankAccounts
	|			//
	|			join Catalog.BankAccounts as BankAccounts
	|			on not BankAccounts.DeletionMark
	|			and BankAccounts.AccountNumber = Details.PayerAccount
	|			and BankAccounts.Owner refs Catalog.Organizations
	|		where not Details.Error
	|		and not Details.Expense
	|		and Details.PayerFiscalCode = """"
	|		and Details.PayerAccount <> """"
	|	) as Organizations
	|	on Organizations.LineNumber = Details.LineNumber
	|";
	Env.Selection.Add(s);
	
EndProcedure

Procedure sqlPaymentOrders()
	
	s = "
	|// #PaymentOrders
	|select Documents.Date as OrderDate, Documents.CashFlow as CashFlow, Documents.ToCompany as ToCompany, Documents.Recipient as Receiver,
	|	Documents.RecipientBankAccount.AccountNumber as ReceiverAccount, Documents.RecipientBankAccount.TreasuryCode as ReceiverSubaccount, 
	|	Documents.Recipient.CodeFiscal as ReceiverFiscalCode, Documents.ID as OrderNumber,
	|	Documents.Contract as Contract, Documents.Contract.Customer as Customer, Documents.Taxes as Taxes,
	|	Documents.Account as Account, Documents.Dim1 as Dim1, Documents.Dim2 as Dim2, Documents.Dim3 as Dim3,
	|	Documents.RecipientBankAccount as RecipientBankAccount, Documents.Ref as Ref, Documents.Amount as Amount
	|from Document.PaymentOrder as Documents
	|where not Documents.DeletionMark
	|and Documents.BankAccount = &BankAccount
	|and Documents.ID in ( select distinct OrderNumber from Details )
	|";
	Env.Selection.Add(s);
	
EndProcedure

Procedure sqlCashFlows()
	
	s = "
	|// #CashFlows
	|select Items.Ref as Ref, Items.FlowType as Type
	|from Catalog.CashFlows as Items
	|where not Items.DeletionMark
	|and Items.FlowType in (
	|	value ( Enum.CashFlow.Type_010 ),
	|	value ( Enum.CashFlow.Type_020 ),
	|	value ( Enum.CashFlow.Type_060 ),
	|	value ( Enum.CashFlow.Type_070 ),
	|	value ( Enum.CashFlow.Type_251 )
	|)
	|order by Items.Code";
	Env.Selection.Add(s);
	
EndProcedure

Procedure getTables()
	
	q = Env.Q;
	q.SetParameter("CodeFiscal", Env.Fields.CodeFiscal);
	q.SetParameter("BankAccount", BankAccount);
	q.SetParameter ( "Details", DetailsTable );
	dates = DetailsTable.Copy( , "OrderDate");
	dates.Sort("OrderDate");
	q.SetParameter("DateStart", BegOfDay(dates[0].OrderDate));
	q.SetParameter("DateEnd", EndOfDay(dates[dates.Count() - 1].OrderDate));
	SQL.Perform(Env);
	
EndProcedure

Procedure adjustFields()
	
	for each row in Env.PaymentOrders do
		row.ReceiverAccount = TrimAll(row.ReceiverAccount);
		row.ReceiverSubaccount = TrimAll(row.ReceiverSubaccount);
		row.ReceiverFiscalCode = TrimAll(row.ReceiverFiscalCode);
	enddo;
	
EndProcedure

Procedure setCashFlows()
	
	flowReceipt = undefined;
	flowExpense = undefined;
	flowOtherReceipt = undefined;
	flowOtherExpense = undefined;
	flowInternal = undefined;
	flows = Enums.CashFlow;
	typeReceipt = flows.Type_010;
	typeExpense = flows.Type_020;
	typeOtherReceipt = flows.Type_060;
	typeOtherExpense = flows.Type_070;
	for each row in Env.CashFlows do
		type = row.Type;
		if (type = typeReceipt) then
			if ( flowReceipt = undefined ) then
				flowReceipt = row.Ref;
			endif;
		elsif (type = typeExpense) then
			if ( flowExpense = undefined ) then
				flowExpense = row.Ref;
			endif;
		elsif (type = typeOtherReceipt) then
			if ( flowOtherReceipt = undefined ) then
				flowOtherReceipt = row.Ref;
			endif;
		elsif (type = typeOtherExpense) then
			if ( flowOtherExpense = undefined ) then
				flowOtherExpense = row.Ref;
			endif;
		else
			if ( flowInternal = undefined ) then
				flowInternal = row.Ref;
			endif;
		endif;
	enddo;
	Env.Insert("FlowReceipt", flowReceipt);
	Env.Insert("FlowExpense", flowExpense);
	Env.Insert("FlowOtherReceipt", flowOtherReceipt);
	Env.Insert("FlowOtherExpense", flowOtherExpense);
	Env.Insert("FlowInternal", flowInternal);
	
EndProcedure

Function error(Row)
	
	if (Row.Error) then
		Output.RowContainsError(new Structure("Line", Row.LineNumber));
		return true;
	endif;
	return false;
	
EndFunction

Function repeat(RowDetail)
	
	line = RowDetail.LineNumber;
	rowRepeat = Env.Repeats.Find(line, "LineNumber");
	if (rowRepeat <> undefined) then
		if (rowRepeat.Expense) then
			row = Expenses.Add();
		else
			row = Receipts.Add();
		endif;
		FillPropertyValues(row, rowRepeat);
		row.DetailsLine = line;
		return true;
	endif;
	return false;
	
EndFunction

Procedure fillExpense(Row, RowDetail)
	
	paymentOrder = Env.PaymentOrders.Find ( RowDetail.OrderNumber, "OrderNumber" );
	if ( paymentOrder <> undefined ) then
		Row.PaymentOrder = paymentOrder.Ref;
	endif;
	commission = ( paymentOrder = undefined and findContent ( RowDetail, "comision plata, deservirea" ) )
	or ( paymentOrder <> undefined and paymentOrder.Amount > RowDetail.Amount );
	if ( commission ) then
		Row.BankOperation = Enums.BankOperations.OtherExpense;
		Row.CashFlow = Env.FlowOtherExpense;
		Row.Operation = OtherExpense;
		setOperation ( Row, OtherExpenseData );
	else
		if ( paymentOrder = undefined ) then
			if (RowDetail.Internal) then
				Row.BankOperation = Enums.BankOperations.OtherExpense;
				cashFlow = Env.FlowInternal;
				Row.CashFlow = cashFlow;
				Row.Account = Account;
				Row.Dim1 = RowDetail.InternalReceiverAccount;
				Row.Dim2 = cashFlow;
				Row.Operation = OtherExpense;
			else
				rowReceiver = Env.Organizations.Find(RowDetail.LineNumber, "LineNumber");
				if (rowReceiver = undefined) then
					Row.BankOperation = Enums.BankOperations.VendorPayment;
					Row.CashFlow = Env.FlowExpense;
				else
					receiver = rowReceiver.Organization;
					Row.Dim1 = receiver;
					if (rowReceiver.Vendor) then
						Row.Dim2 = rowReceiver.VendorContract;
						Row.BankOperation = Enums.BankOperations.VendorPayment;
						setCashFlow(Row, rowReceiver.VendorCashFlow, Env.FlowExpense);
						accounts = AccountsMap.Organization(receiver, Company, "VendorAccount, AdvanceGiven");
						Row.Account = accounts.VendorAccount;
						Row.AdvanceAccount = accounts.AdvanceGiven;
					else
						Row.Dim2 = rowReceiver.CustomerContract;
						Row.BankOperation = Enums.BankOperations.ReturnToCustomer;
						setCashFlow(Row, rowReceiver.CustomerCashFlow, Env.FlowOtherExpense);
						accounts = AccountsMap.Organization(receiver, Company, "CustomerAccount, AdvanceGiven");
						Row.Account = accounts.CustomerAccount;
						Row.AdvanceAccount = accounts.AdvanceGiven;
					endif;
				endif;
			endif;
		else
			Row.CashFlow = paymentOrder.CashFlow;
			if (paymentOrder.ToCompany) then
				Row.BankOperation = Enums.BankOperations.OtherExpense;
				Row.Account = AccountInternal;
				Row.Dim1 = paymentOrder.RecipientBankAccount;
				Row.Operation = OtherExpense;
			elsif ( paymentOrder.Taxes ) then
				Row.BankOperation = Enums.BankOperations.OtherExpense;
				Row.Account = paymentOrder.Account;
				Row.Dim1 = paymentOrder.Dim1;
				Row.Dim2 = paymentOrder.Dim2;
				Row.Dim2 = paymentOrder.Dim3;
				Row.Operation = OtherExpense;
			else
				receiver = paymentOrder.Receiver;
				Row.Dim1 = receiver;
				Row.Dim2 = paymentOrder.Contract;
				if (paymentOrder.Customer) then
					Row.BankOperation = Enums.BankOperations.ReturnToCustomer;
					accounts = AccountsMap.Organization(receiver, Company, "CustomerAccount, AdvanceTaken");
					Row.Account = accounts.CustomerAccount;
					Row.AdvanceAccount = accounts.AdvanceTaken;
				else
					Row.BankOperation = Enums.BankOperations.VendorPayment;
					accounts = AccountsMap.Organization(receiver, Company, "VendorAccount, AdvanceGiven");
					Row.Account = accounts.VendorAccount;
					Row.AdvanceAccount = accounts.AdvanceGiven;
				endif;
			endif;
		endif;
	endif;
	Row.PaymentContent = RowDetail.PaymentContent;
	if ( BankAccountCurrency <> LocalCurrency ) then
		Row.CurrencyAmount = RowDetail.CurrencyAmount;
		Row.Currency = BankAccountCurrency;
		Row.Rate = CurrencyRate.Rate;
		Row.Factor = CurrencyRate.Factor;
	endif;
	if ( ExecuteOnExpense ) then
		SetSafeMode ( true );
		Execute ( OnExpense );
	endif;
	
EndProcedure

Procedure setOperation ( Row, Data )
	
	Row.Account = Data.Account;
	Row.Dim1 = Data.Dim1;
	Row.Dim2 = Data.Dim2;
	Row.Dim3 = Data.Dim3;

EndProcedure

Procedure setCashFlow(Row, CashFlowContract, EnvCashFlow)
	
	if (ValueIsFilled(CashFlowContract)) then
		Row.CashFlow = CashFlowContract;
	else
		Row.CashFlow = EnvCashFlow;
	endif;
	
EndProcedure

Function findContent ( RowDetail, Strings )
	
	content = Lower ( RowDetail.PaymentContent );
	for each part in Conversion.StringToArray ( Strings, "," ) do
		if ( Find ( content, part ) ) then
			return true;
		endif;
	enddo;
	return false;
	
EndFunction

Procedure fillReceipt(Row, RowDetail)
	
	if (RowDetail.Internal) then
		Row.BankOperation = Enums.BankOperations.OtherReceipt;
		cashFlow = Env.FlowInternal;
		Row.CashFlow = cashFlow;
		Row.Account = Account;
		Row.Dim1 = RowDetail.InternalSenderAccount;
		Row.Dim2 = cashFlow;
		Row.Operation = OtherReceipt;
	else
		rowPayer = Env.Organizations.Find(RowDetail.LineNumber, "LineNumber");
		if (rowPayer = undefined) then
			Row.BankOperation = Enums.BankOperations.OtherReceipt;
			Row.CashFlow = Env.FlowOtherReceipt;
			Row.Operation = OtherReceipt;
			setOperation ( Row, OtherReceiptData );
		else
			payer = rowPayer.Organization;
			Row.Dim1 = payer;
			if (rowPayer.Customer) then
				Row.Dim2 = rowPayer.CustomerContract;
				Row.BankOperation = Enums.BankOperations.Payment;
				setCashFlow(Row, rowPayer.CustomerCashFlow, Env.FlowReceipt);
				accounts = AccountsMap.Organization(payer, Company, "CustomerAccount, AdvanceTaken");
				Row.Account = accounts.CustomerAccount;
				Row.AdvanceAccount = accounts.AdvanceTaken;
			else
				Row.Dim2 = rowPayer.VendorContract;
				Row.BankOperation = Enums.BankOperations.ReturnFromVendor;
				setCashFlow(Row, rowPayer.VendorCashFlow, Env.FlowOtherReceipt);
				accounts = AccountsMap.Organization(payer, Company, "VendorAccount, AdvanceTaken");
				Row.Account = accounts.VendorAccount;
				Row.AdvanceAccount = accounts.AdvanceTaken;
			endif;
		endif;
	endif;
	Row.PaymentContent = RowDetail.PaymentContent;
	if ( BankAccountCurrency <> LocalCurrency ) then
		Row.CurrencyAmount = RowDetail.CurrencyAmount;
		Row.Currency = BankAccountCurrency;
		Row.Rate = CurrencyRate.Rate;
		Row.Factor = CurrencyRate.Factor;
	endif;
	if ( ExecuteOnReceipt ) then
		SetSafeMode ( true );
		Execute ( OnReceipt );
	endif;
	
EndProcedure

Procedure findOperations(Row, RowDetail, IsMaib)
	
	code = RowDetail.TransactionCode;
	expense = RowDetail.Expense;
	if (code = "001")
		or (code = "101"
			and IsMaib) then
		if (expense) then
			operation = Enums.BankOperations.VendorPayment;
			if (Row.BankOperation = operation) then
				return;
			endif;
			Row.BankOperation = operation;
			Row.CashFlow = Env.FlowExpense;
		else
			operation = Enums.BankOperations.Payment;
			if (Row.BankOperation = operation) then
				return;
			endif;
			Row.BankOperation = operation;
			Row.CashFlow = Env.FlowReceipt;
		endif;
		Row.Operation = undefined;
		Row.Account = undefined;
	elsif (IsBlankString(code))
		and (IsMaib) then
		if (expense) then
			operation = Enums.BankOperations.OtherExpense;
			if (Row.BankOperation = operation) then
				return;
			endif;
			Row.BankOperation = operation;
			Row.CashFlow = Env.FlowOtherExpense;
			Row.Operation = OtherExpense;
			setOperation ( Row, OtherExpenseData );
		else
			operation = Enums.BankOperations.OtherReceipt;
			if (Row.BankOperation = operation) then
				return;
			endif;
			Row.BankOperation = operation;
			Row.CashFlow = Env.FlowOtherReceipt;
			Row.Operation = OtherReceipt;
			setOperation ( Row, OtherReceiptData );
		endif;
	endif;
	
EndProcedure

Procedure putToStorage()
	
	result = new Structure("Details, Receipts, Expenses", DetailsTable, Receipts, Expenses);
	PutToTempStorage(result, Parameters.Address);
	
EndProcedure

#endif