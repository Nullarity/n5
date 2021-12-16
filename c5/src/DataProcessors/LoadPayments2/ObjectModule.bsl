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
var LocalCurrency;

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
	LocalCurrency = Application.Currency ();
	Memo = Output.DownloadedFromClientBank ();
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
	
	s = "
	|// #Receipts
	|select 
	|	case when isnull ( Receipts.Operation.AccountDr, value ( ChartOfAccounts.General.EmptyRef ) )
	|			= value ( ChartOfAccounts.General.EmptyRef ) then Receipts.Ref.Account
	|		else Receipts.Operation.AccountDr
	|	end as AccountDr,
	|	case when Receipts.BankOperation = value ( Enum.BankOperations.OtherReceipt ) then
	|		case when isnull ( Receipts.Operation.AccountDr, value ( ChartOfAccounts.General.EmptyRef ) )
	|			= value ( ChartOfAccounts.General.EmptyRef )
	|			then Receipts.Ref.Account.Class
	|			else Receipts.Operation.AccountDr.Class
	|		end
	|	end as DrClass,
	|	case Receipts.BankOperation
	|		when value ( Enum.BankOperations.OtherReceipt ) then Receipts.Account.Class
	|	end as CrClass,
	|	Receipts.Account as AccountCr, Receipts.Operation.Operation as Method,
	|	isnull ( Receipts.Operation.Simple, true ) as Simple,
	|" + Env.ReceiptsFields + "
	|from Document.LoadPayments.Receipts as Receipts
	|where Receipts.Ref = &Ref
	|";
	Env.Selection.Add(s);
	
EndProcedure

Procedure sqlExpenses()
	
	s = "
	|// #Expenses
	|select
	|	case when isnull ( Expenses.Operation.AccountCr, value ( ChartOfAccounts.General.EmptyRef ) )
	|			= value ( ChartOfAccounts.General.EmptyRef ) then Expenses.Ref.Account
	|		else Expenses.Operation.AccountCr
	|	end as AccountCr,
	|	case when Expenses.BankOperation = value ( Enum.BankOperations.OtherExpense ) then
	|		case when isnull ( Expenses.Operation.AccountCr, value ( ChartOfAccounts.General.EmptyRef ) )
	|			= value ( ChartOfAccounts.General.EmptyRef )
	|			then Expenses.Ref.Account.Class
	|			else Expenses.Operation.AccountCr.Class
	|		end
	|	end as CrClass,
	|	case Expenses.BankOperation
	|		when value ( Enum.BankOperations.OtherExpense ) then Expenses.Account.Class
	|	end as DrClass,
	|	Expenses.Account as AccountDr, Expenses.Operation.Operation as Method,
	|	isnull ( Expenses.Operation.Simple, true ) as Simple,
	|" + Env.ExpensesFields + "
	|from Document.LoadPayments.Expenses as Expenses
	|where Expenses.Ref = &Ref
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
		operation = row.BankOperation;
		if (operation = Enums.BankOperations.Payment) then
			createPayment(row, rowDetail);
		elsif (operation = Enums.BankOperations.ReturnFromVendor) then
			createVendorRefund(row, rowDetail);
		else
			createEntry(row, rowDetail, true);
		endif;
	enddo;
	
EndProcedure

Procedure processingLine(Line)
	
	LineProcessing.Line = Line;
	Progress.Put(Output.ProcessingLine(LineProcessing), JobKey);
	
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
	object.Customer = Row.Dim1;
	object.CustomerAccount = Row.Account;
	object.AdvanceAccount = Row.AdvanceAccount;
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
	Object.PaymentContent = RowDetail.PaymentContent;
	
EndProcedure

Function noon(Date)
	
	return BegOfDay(Date) + 43200;
	
EndFunction

Procedure loadContract(Object, Row)
	
	Object.Contract = Row.Dim2;
	Object.Account = Account;
	Object.BankAccount = BankAccount;
	if ( ValueIsFilled ( Row.Currency ) ) then
		Object.Currency = Row.Currency;
		Object.Rate = Row.Rate;
		Object.Factor = Row.Factor;
		Object.Amount = Row.CurrencyAmount;
		Object.ContractAmount = Row.Amount;
	else
		Object.Currency = Currency;
		info = CurrenciesSrv.Get(Currency, Object.Date);
		Object.Rate = info.Rate;
		Object.Factor = info.Factor;
		Object.Amount = Row.Amount;
	endif;
	PaymentForm.LoadContract(Object);
	Object.CashFlow = Row.CashFlow;
	Object.Method = Method;
	
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
		Progress.Put(Output.ErrorSavingBankDocument(new Structure("Line, Error", Row.LineNumber, ErrorDescription())), JobKey, true);
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
		Progress.Put(Output.ErrorPostingBankDocument(new Structure("Line, Error", Row.LineNumber, ErrorDescription())), JobKey, true);
		return false;
	endtry;
	return true;
	
EndFunction

Procedure createVendorRefund(Row, RowDetail)
	
	newDocument = false;
	document = Row.Document;
	if (ValueIsFilled(document)) then
		object = document.GetObject();
		object.Payments.Clear();
	else
		object = Documents.VendorRefund.CreateDocument();
		object.SetNewNumber();
		newDocument = true;
	endif;
	object.Vendor = Row.Dim1;
	object.VendorAccount = Row.Account;
	object.AdvanceAccount = Row.AdvanceAccount;
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

Procedure createEntry(Row, RowDetail, Debit)
	
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
	amount = Row.Amount;
	object.Amount = amount;
	object.Operation = Row.Operation;
	object.Method = Row.Method;
	object.Simple = Row.Simple;
	rowRecord = object.Records.Add();
	rowRecord.AccountDr = Row.AccountDr;
	rowRecord.DrClass = Row.DrClass;
	rowRecord.AccountCr = Row.AccountCr;
	rowRecord.CrClass = Row.CrClass;
	if ( Debit ) then
		bankSide = "Dr";
		side = "Cr";
	else
		bankSide = "Cr";
		side = "Dr";
	endif;
	dim = "Dim" + side;
	rowRecord [ dim + "1" ] = Row.Dim1;
	rowRecord [ dim + "2" ] = Row.Dim2;
	rowRecord [ dim + "3" ] = Row.Dim3;
	rowRecord [ "Currency" + side ] = Row.Currency;
	rowRecord [ "CurrencyAmount" + side ] = Row.CurrencyAmount;
	rowRecord [ "Rate" + side ] = Row.Rate;
	rowRecord [ "Factor" + side ] = Row.Factor;
	dim = "Dim" + bankSide;
	rowRecord [ dim + "1" ] = BankAccount;
	rowRecord [ dim + "2" ] = Row.CashFlow;
	rowRecord.Amount = amount;
	writeDocument(object, Row, newDocument);
	
EndProcedure

Procedure createExpenses()
	
	table = Env.Expenses;
	if (table.Count() = 0) then
		return;
	endif;
	operations = Enums.BankOperations;
	vendorPayment = operations.VendorPayment;
	for each row in table do
		if (not row.Download) then
			continue;
		endif;
		line = row.DetailsLine;
		rowDetail = Details.Find(line, "LineNumber");
		processingLine(line);
		operation = row.BankOperation;
		if (operation = vendorPayment) then
			createVendorPayment(row, rowDetail);
		elsif ( operation = Enums.BankOperations.ReturnToCustomer ) then
			createRefund (row, rowDetail);
		else
			createEntry(row, rowDetail, false);
		endif;
		payPaymentOrder ( row );
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
	object.Vendor = Row.Dim1;
	object.VendorAccount = Row.Account;
	object.AdvanceAccount = Row.AdvanceAccount;
	headerDocument(object, Row, RowDetail);
	loadContract(object, Row);
	PaymentForm.CalcContractAmount(object, 1);
	PaymentForm.FillTable(object);
	PaymentForm.DistributeAmount(object);
	PaymentForm.CalcHandout(object);
	clean(object.Payments);
	writeDocument(object, Row, newDocument);
	
EndProcedure

Procedure createRefund(Row, RowDetail)
	
	newDocument = false;
	document = Row.Document;
	if (ValueIsFilled(document)) then
		object = document.GetObject();
		object.Payments.Clear();
	else
		object = Documents.Refund.CreateDocument();
		object.SetNewNumber();
		newDocument = true;
	endif;
	object.Customer = Row.Dim1;
	object.CustomerAccount = Row.Account;
	object.AdvanceAccount = Row.AdvanceAccount;
	headerDocument(object, Row, RowDetail);
	loadContract(object, Row);
	PaymentForm.CalcContractAmount(object, 1);
	PaymentForm.FillTable(object);
	PaymentForm.DistributeAmount(object);
	clean(object.Payments);
	writeDocument(object, Row, newDocument);
	
EndProcedure

Procedure payPaymentOrder ( Row )
	
	if ( Row.Document = undefined
		or Row.PaymentOrder.IsEmpty () ) then
		return;
	endif;
	obj = Row.PaymentOrder.GetObject ();
	if ( obj.DeletionMark
		or obj.Paid ) then
		return;
	endif;
	obj.Paid = true;
	obj.PaidBy = Row.Document;
	SetPrivilegedMode(true);
	try
		obj.Write();
	except
		Progress.Put(Output.ErrorSavingBankDocument(new Structure("Line, Error", Row.LineNumber, ErrorDescription())), JobKey, true);
	endtry;
	SetPrivilegedMode(false);

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