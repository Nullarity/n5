#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Parameters export;
var JobKey export;
var SourceObject;
var Env;
var Company;
var BankAccount;
var Account;
var Details;
var Expenses;
var Receipts;
var Creator;
var Currency;
var Memo;
var Method;
var LineProcessing;
var Dims;

Procedure Exec() export
	
	init();
	createDocuments();
	complete();
	
EndProcedure

Procedure init()
	
	SourceObject = Parameters.Ref.GetObject ();
	SQL.Init(Env);
	Company = SourceObject.Company;
	BankAccount = SourceObject.BankAccount;
	Account = SourceObject.Account;
	Details = SourceObject.Details;
	Expenses = SourceObject.Expenses;
	Receipts = SourceObject.Receipts;
	Creator = SourceObject.Creator;
	Currency = DF.Pick ( BankAccount, "Currency" );
	Memo = OutputCont.DownloadedFromClientBank ();
	Method = Enums.PaymentMethods.Bank;
	LineProcessing = new Structure ( "Line" );
	Dims = new Structure();
	set = ChartsOfCharacteristicTypes.Dimensions;
	Dims.Insert("BankAccounts", set.BankAccounts);
	Dims.Insert("CashFlows", set.CashFlows);
	Dims.Insert("Organizations", set.Organizations);
	Dims.Insert("Contracts", set.Contracts);
	
EndProcedure

Procedure createDocuments()
	
	getData();
	createReceipts();
	createExpenses();
	
EndProcedure

Procedure getData()
	
	setFields();
	sqlReceipts();
	sqlExpenses();
	sqlInternalAccounts();
	getTables();
	
EndProcedure

Procedure setFields()
	
	Env.Insert("ReceiptsFields", StrConcat(getFields("Receipts"), ", "));
	Env.Insert("ExpensesFields", StrConcat(getFields("Expenses"), ", "));
	
EndProcedure

Function getFields(Table)
	
	fields = new Array();
	for each attribute in Metadata.Documents.LoadPayments.TabularSections[Table].Attributes do
		name = attribute.Name;
		fields.Add(Table + "." + name + " as " + name);
	enddo;
	fields.Add(Table + ".LineNumber as LineNumber");
	return fields
	
EndFunction

Procedure sqlReceipts()
	
	fields = Env.ReceiptsFields;
	s = "
	|// #Receipts
	|select " + fields + ", Receipts.Operation.Simple as Simple, 
	|	case when isnull ( Receipts.Operation.AccountDr, value ( ChartOfAccounts.General.EmptyRef ) )
	|			= value ( ChartOfAccounts.General.EmptyRef ) then Receipts.Ref.Account
	|		else Receipts.Operation.AccountDr
	|	end as AccountDr,
	|	Receipts.Account as AccountCr, Receipts.Payer as Organization, false as Currency, false as Internal
	|from Document.LoadPayments.Receipts as Receipts
	|where Receipts.Ref = &Ref
	|";
	Env.Selection.Add(s);
	
EndProcedure

Procedure sqlExpenses()
	
	fields = Env.ExpensesFields;
	s = "
	|// #Expenses
	|select " + fields + ", Expenses.Operation.Simple as Simple, 
	|	case when isnull ( Expenses.Operation.AccountCr, value ( ChartOfAccounts.General.EmptyRef ) )
	|			= value ( ChartOfAccounts.General.EmptyRef ) then Expenses.Ref.Account
	|		else Expenses.Operation.AccountCr
	|	end as AccountCr,
	|	Expenses.Account as AccountDr, Expenses.Receiver as Organization, false as Currency, false as Internal, undefined as InternalAccount
	|from Document.LoadPayments.Expenses as Expenses
	|where Expenses.Ref = &Ref
	|";
	Env.Selection.Add(s);
	
EndProcedure

Procedure sqlInternalAccounts()
	
	s = "
	|// #InternalAccounts
	|select Expenses.DetailsLine as DetailsLine, BankAccounts.Ref as BankAccount
	|from Document.LoadPayments.Expenses as Expenses
	|	//
	|	//	Details
	|	//
	|	left join Document.LoadPayments.Details as Details
	|	on Details.Ref = &Ref
	|	and Details.LineNumber = Expenses.DetailsLine
	|	//
	|	//	Bank Accounts
	|	//
	|	inner join Catalog.BankAccounts as BankAccounts
	|	on BankAccounts.Owner = Details.Ref.Company
	|	and BankAccounts.AccountNumber = Details.ReceiverAccount
	|	and not BankAccounts.DeletionMark
	|where Expenses.BankOperation = value ( Enum.BankOperations.InternalMovement )
	|and Expenses.Ref = &Ref
	|";
	Env.Selection.Add(s);
	
EndProcedure

Procedure getTables()
	
	q = Env.Q;
	q.SetParameter("Ref", SourceObject.Ref);
	q.SetParameter("Company", Company);
	SQL.Perform(Env);
	
EndProcedure

Procedure createReceipts()
	
	table = Env.Receipts;
	if (table.Count() = 0) then
		return;
	endif;
	for each row in table do
		if (not row.Download) then
			continue;
		endif;
		line = row.DetailsLine;
		rowDetail = Details.Find(line, "LineNumber");
		processingLine(line);
		if (row.BankOperation = Enums.BankOperations.Payment) then
			createPayment(row, rowDetail);
		else
			createEntry(row, rowDetail);
		endif;
	enddo;
	
EndProcedure

Procedure processingLine(Line)
	
	LineProcessing.Line = Line;
	Progress.Put(OutputCont.ProcessingLine(LineProcessing), JobKey);
	
EndProcedure

Procedure createPayment(Row, RowDetail)
	
	newDocument = false;
	document = Row.Document;
	if (ValueIsFilled(document)) then
		object = document.GetObject();
		object.Payments.Clear();
	else
		object = Documents.Payment.CreateDocument();
		object.SetNewNumber();
		newDocument = true;
	endif;
	object.Customer = Row.Payer;
	object.CustomerAccount = Row.Account;
	object.AdvanceAccount = Row.AdvanceAccount;
	object.DiscountAccount = Row.DiscountAccount;
	headerDocument(object, Row, RowDetail);
	loadContract(object, Row);
	PaymentForm.SetVATAdvance ( object );
	PaymentForm.CalcContractAmount(object, 1);
	PaymentForm.CalcAppliedAmount(object, 1);
	PaymentForm.FillTable(object);
	PaymentForm.DistributeAmount(object);
	clean(object.Payments);
	writeDocument(object, Row, newDocument);
	
EndProcedure

Procedure headerDocument(Object, Row, RowDetail)
	
	Object.Date = noon(Row.Date);
	Object.Company = Company;
	Object.Creator = Creator;
	Object.Reference = TrimAll(RowDetail.OrderNumber);
	Object.ReferenceDate = RowDetail.OrderDate;
	setContent(Object.Memo, RowDetail);
	
EndProcedure

Function noon(Date)
	
	return BegOfDay(Date) + 43200;
	
EndFunction

Procedure setContent(Content, RowDetail)
	
	Content = TrimAll(RowDetail.PaymentContent) + Memo;
	
EndProcedure

Procedure loadContract(Object, Row)
	
	Object.Contract = Row.Contract;
	Object.Account = Account;
	Object.BankAccount = BankAccount;
	Object.Currency = Currency;
	setRates(Object);
	PaymentForm.LoadContract(Object);
	Object.CashFlow = Row.CashFlow;
	Object.Method = Method;
	Object.Amount = Row.Amount;
	
EndProcedure

Procedure setRates(Object)
	
	info = CurrenciesSrv.Get(Currency, Object.Date);
	Object.Rate = info.Rate;
	Object.Factor = info.Factor;
	
EndProcedure

Procedure clean(Table)
	
	i = Table.Count();
	while (i > 0) do
		i = i - 1;
		row = Table[i];
		if (row.Amount = 0) then
			Table.Delete(i);
		endif;
	enddo;
	
EndProcedure

Procedure writeDocument(Object, Row, NewDocument)
	
	if (postDocument(Object, Row)) then
		Row.Document = Object.Ref;
		Row.Download = false;
		return;
	endif;
	try
		SetPrivilegedMode(true);
		if (NewDocument) then
			Object.Write();
		else
			if (Object.Posted) then
				Object.Write(DocumentWriteMode.UndoPosting);
			else
				Object.Write();
				if (Object.DeletionMark) then
					Object.SetDeletionMark(false);
				endif;
			endif;
		endif;
		SetPrivilegedMode(false);
		Row.Document = Object.Ref;
		Row.Download = false;
	except
		Progress.Put(OutputCont.ErrorSavingBankDocument(new Structure("Line, Error", Row.LineNumber, ErrorDescription())), JobKey, true);
	endtry;
	
EndProcedure

Function postDocument(Object, Row)
	
	try
		SetPrivilegedMode(true);
		if ( not Object.CheckFilling() ) then
			raise Output.CheckFillingError();
		endif;
		Object.Write(DocumentWriteMode.Posting);
		SetPrivilegedMode(false);
	except
		Progress.Put(OutputCont.ErrorPostingBankDocument(new Structure("Line, Error", Row.LineNumber, ErrorDescription())), JobKey, true);
		return false;
	endtry;
	return true;
	
EndFunction

Procedure createEntry(Row, RowDetail)
	
	newDocument = false;
	document = Row.Document;
	if (ValueIsFilled(document)) then
		object = document.GetObject();
		object.Records.Clear();
	else
		object = Documents.Entry.CreateDocument();
		object.SetNewNumber();
		newDocument = true;
	endif;
	headerDocument(object, Row, RowDetail);
	object.Amount = Row.Amount;
	object.Operation = Row.Operation;
	object.Simple = Row.Simple;
	rowRecord = object.Records.Add();
	rowRecord.AccountDr = Row.AccountDr;
	rowRecord.AccountCr = Row.AccountCr;
	data = EntryFormSrv.AccountsData(Row.AccountDr, Row.AccountCr);
	fillDr(rowRecord, Row, data.Dr);
	fillCr(rowRecord, Row, data.Cr);
	setAmount(object, rowRecord, Row);
	setContent(rowRecord.Content, RowDetail);
	writeDocument(object, Row, newDocument);
	
EndProcedure

Procedure fillDr(RowRecord, Row, Data)
	
	if (Row.Internal) then
		valueBankAccount = Row.InternalAccount;
	else
		valueBankAccount = BankAccount;
	endif;
	for each item in Data.Dims do
		value = getDimValue(Row, item.Dim, valueBankAccount);
		if (value = undefined) then
			continue;
		endif;
		RowRecord["DimDr" + item.LineNumber] = value;
	enddo;
	if (Data.Fields.Currency) then
		fillAccountCurrency(RowRecord, Row, "Dr");
	endif;
	
EndProcedure

Function getDimValue(Row, Dim, ValueBankAccount = undefined)
	
	if (Dim = Dims.BankAccounts) then
		return ?(ValueBankAccount = undefined, BankAccount, ValueBankAccount);
	elsif (Dim = Dims.CashFlows) then
		return Row.CashFlow;
	elsif (Dim = Dims.Organizations) then
		return Row.Organization;
	elsif (Dim = Dims.Contracts) then
		return Row.Contract;
	endif;
	return undefined;
	
EndFunction

Procedure fillAccountCurrency(RowRecord, Row, Side)
	
	amount = Row.Amount;
	RowRecord["CurrencyAmount" + Side] = amount;
	RowRecord["Currency" + Side] = Currency;
	info = CurrenciesSrv.Get(Currency, Row.Date);
	RowRecord["Rate" + Side] = info.Rate;
	RowRecord["Factor" + Side] = info.Factor;
	RowRecord.Amount = (amount * info.rate) / Max(info.Factor, 1);
	Row.Currency = true;
	
EndProcedure

Procedure fillCr(RowRecord, Row, Data)
	
	for each item in Data.Dims do
		value = getDimValue(Row, item.Dim);
		if (value = undefined) then
			continue;
		endif;
		RowRecord["DimCr" + item.LineNumber] = value;
	enddo;
	if (Data.Fields.Currency) then
		fillAccountCurrency(RowRecord, Row, "Cr");
	endif;
	
EndProcedure

Procedure setAmount(Object, RowRecord, Row)
	
	if (not Row.Currency) then
		RowRecord.Amount = Row.Amount;
	endif;
	Object.Amount = RowRecord.Amount;
	
EndProcedure

Procedure createExpenses()
	
	table = Env.Expenses;
	if (table.Count() = 0) then
		return;
	endif;
	operations = Enums.BankOperations;
	vendorPayment = operations.VendorPayment;
	internal = operations.InternalMovement;
	accounts = Env.InternalAccounts;
	for each row in table do
		if (not row.Download) then
			continue;
		endif;
		line = row.DetailsLine;
		rowDetail = Details.Find(line, "LineNumber");
		processingLine(line);
		if (row.BankOperation = vendorPayment) then
			createVendorPayment(row, rowDetail);
		else
			if (row.BankOperation = internal) then
				row.Internal = true;
				accountRow = accounts.Find(line, "DetailsLine");
				if (accountRow <> undefined) then
					row.InternalAccount = accountRow.BankAccount;
				endif;
			endif;
			createEntry(row, rowDetail);
		endif;
	enddo;
	
EndProcedure

Procedure createVendorPayment(Row, RowDetail)
	
	newDocument = false;
	document = Row.Document;
	if (ValueIsFilled(document)) then
		object = document.GetObject();
		object.Payments.Clear();
	else
		object = Documents.VendorPayment.CreateDocument();
		object.SetNewNumber();
		newDocument = true;
	endif;
	object.Vendor = Row.Receiver;
	object.VendorAccount = Row.Account;
	object.AdvanceAccount = Row.AdvanceAccount;
	object.DiscountAccount = Row.DiscountAccount;
	headerDocument(object, Row, RowDetail);
	loadContract(object, Row);
	PaymentForm.CalcContractAmount(object, 1);
	PaymentForm.FillTable(object);
	PaymentForm.DistributeAmount(object);
	PaymentForm.CalcHandout(object);
	clean(object.Payments);
	writeDocument(object, Row, newDocument);
	
EndProcedure

Procedure complete()
	
	SourceObject.Receipts.Load ( Env.Receipts );
	SourceObject.Expenses.Load ( Env.Expenses );
	try
		SourceObject.Write ( DocumentWriteMode.Posting );
	except
		Progress.Put ( Output.Error ( new Structure("Error", ErrorDescription () ) ), JobKey, true );
	endtry;
	
EndProcedure

#endif