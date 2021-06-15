&AtClient
var ReceiptsRow export;
&AtClient
var ExpensesRow export;
&AtClient
var WritingStarted;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	Appearance.Apply(ThisObject);
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	if (Object.Ref.IsEmpty()) then
		if (isCopy()) then
			Cancel = true;
			return;
		endif;
		DocumentForm.Init(Object);
		fillNew();
	endif;
	readAppearance();
	Appearance.Apply(ThisObject);
	
EndProcedure

&AtServer
Procedure readAppearance()
	
	rules = new Array();
	rules.Add("
	|UndoPosting show Object.Posted;
	|GroupImportantFields lock Object.Posted;
	|FormWrite Read hide Object.Posted;
	|GroupFileInfo show Object.Status = 1;
	|GroupError show Object.Status = 2;
	|#c ExpensesBankOperation unlock ExpensesRow <> undefined and empty ( ExpensesRow.Document );
	|#c ExpensesReceiver ExpensesContract ExpensesAdvanceAccount unlock ExpensesRow <> undefined
	|	and inlist ( ExpensesRow.BankOperation, Enum.BankOperations.VendorPayment, Enum.BankOperations.ReturnToCustomer );
	|#c ExpensesOperation unlock ExpensesRow <> undefined
	|	and inlist ( ExpensesRow.BankOperation, Enum.BankOperations.InternalMovement, Enum.BankOperations.OtherExpense );
	|#c ReceiptsBankOperation unlock ReceiptsRow <> undefined and empty ( ReceiptsRow.Document );
	|#c ReceiptsReceiver ReceiptsContract ReceiptsAdvanceAccount unlock ReceiptsRow <> undefined
	|	and inlist ( ReceiptsRow.BankOperation, Enum.BankOperations.Payment, Enum.BankOperations.ReturnFromVendor );
	|#c ReceiptsOperation unlock ReceiptsRow <> undefined and ReceiptsRow.BankOperation = Enum.BankOperations.OtherReceipt;
	|");
	Appearance.Read(ThisObject, rules);
	
EndProcedure

&AtServer
Function isCopy()
	
	if (not Parameters.CopyingValue.IsEmpty()) then
		OutputCont.CannotCopyBankingApp();
		return true;
	endif;
	return false;
	
EndFunction

&AtServer
Procedure fillNew()
	
	Object.Company = Logins.Settings("Company").Company;
	applyCompany();
	initOperations();
	
EndProcedure

&AtServer
Procedure applyCompany()
	
	data = DF.Values(Object.Company, "BankAccount, BankAccount.Loading");
	Object.BankAccount = data.BankAccount;
	Object.Path = data.BankAccountLoading;
	applyBankAccount(Object);
	
EndProcedure

&AtClientAtServerNoContext
Procedure applyBankAccount(val Object)
	
	data = DF.Values(Object.BankAccount, "Account, Application");
	Object.Account = data.Account;
	Object.Application = data.Application;
	
EndProcedure

&AtServer
Procedure initOperations()
	
	s = "
		|select top 1 Documents.InternalMovement as InternalMovement, Documents.OtherExpense as OtherExpense,
		|	Documents.OtherReceipt as OtherReceipt
		|from Document.LoadPayments as Documents
		|where not Documents.DeletionMark
		|and Documents.Company = &Company
		|order by Documents.Date desc
		|";
	q = new Query(s);
	q.SetParameter("Company", Object.Company);
	table = q.Execute().Unload();
	if (table.Count() = 0) then
		return;
	endif;
	FillPropertyValues(Object, table[0]);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	LocalFiles.Prepare();
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	if (WritingStarted) then
		return;
	endif;
	if (WriteParameters.WriteMode = DocumentWriteMode.Posting) then
		Cancel = true;
		post();
	endif;
	
EndProcedure

&AtClient
Procedure post()
	
	if (not CheckFilling()) then
		return;
	endif;
	WritingStarted = true;
	ok = Write();
	WritingStarted = false;
	if (ok) then
		runPosting();
		Progress.Open(UUID, ThisObject, new NotifyDescription("Posted", ThisObject), true);
	endif;
	
EndProcedure

&AtServer
Procedure runPosting()
	
	p = DataProcessors.LoadPayments2.GetParams();
	p.Ref = Object.Ref;
	args = new Array();
	args.Add("LoadPayments2");
	args.Add(p);
	Jobs.Run("Jobs.ExecProcessor", args, UUID, , TesterCache.Testing());
	
EndProcedure

&AtClient
Procedure Posted(Result, Params) export
	
	if (Result = undefined) then
		return;
	endif;
	reload();
	notifySystem ();
	
EndProcedure

&AtServer
Procedure reload()
	
	obj = Object.Ref.GetObject();
	ValueToFormAttribute(obj, "Object");
	Appearance.Apply(ThisObject, "Object.Posted");
	
EndProcedure

&AtClient
Procedure notifySystem ()
	
	Notify ( Enum.MessageBankingAppLoaded () );
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	Appearance.Apply ( ThisObject, "Object.Posted" );
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )

	if (WriteParameters.WriteMode = DocumentWriteMode.UndoPosting) then
		notifySystem ();
	endif;

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure ReadFile(Command)
	
	startReading();
	
EndProcedure

&AtClient
Procedure startReading()
	
	if (not check(Object)) then
		return;
	endif;
	files = new Array();
	files.Add(new TransferableFileDescription(Object.Path));
	BeginPuttingFiles(new NotifyDescription("Reading", ThisObject), files, , false, UUID);
	
EndProcedure

&AtServerNoContext
Function check(val Object)
	
	fields = mandatoryFields();
	if (not checkFields(Object, fields)) then
		return false;
	endif;
	return true;
	
EndFunction

&AtServerNoContext
Function mandatoryFields()
	
	fields = new Array();
	attributes = Metadata.Documents.LoadPayments.Attributes;
	fields.Add(attributes.Path);
	fields.Add(attributes.BankAccount);
	fields.Add(attributes.Application);
	fields.Add(attributes.Company);
	fields.Add(attributes.Account);
	return fields;
	
EndFunction

&AtServerNoContext
Function checkFields(Object, Fields)
	
	errors = findErrors(Object, Fields);
	if (errors.Count() = 0) then
		return true;
	endif;
	for each error in errors do
		Output.FieldIsEmpty(new Structure("Field", error.Presentation()), error.Name);
	enddo;
	return false;
	
EndFunction

&AtServerNoContext
Function findErrors(Object, Fields)
	
	errors = new Array();
	for each field in Fields do
		if (not ValueIsFilled(Object[field.Name])) then
			errors.Add(field);
		endif;
	enddo;
	return errors;
	
EndFunction

&AtClient
Procedure Reading(Result, Params) export
	
	ReadKey = "Bank Client Read " + UUID;
	Location = Result[0].Location;
	runReadFile();
	Progress.Open(ReadKey, ThisObject, new NotifyDescription("ReadingComplete", ThisObject), true);
	
EndProcedure

&AtServer
Procedure runReadFile()
	
	p = DataProcessors.LoadPayments1.GetParams();
	p.File = GetFromTempStorage(Location);
	p.Application = Object.Application;
	p.Company = Object.Company;
	p.BankAccount = Object.BankAccount;
	ResultAddress = PutToTempStorage(undefined, UUID);
	p.Address = ResultAddress;
	p.Account = Object.Account;
	p.InternalMovement = Object.InternalMovement;
	p.OtherExpense = Object.OtherExpense;
	p.OtherReceipt = Object.OtherReceipt;
	args = new Array();
	args.Add("LoadPayments1");
	args.Add(p);
	Jobs.Run("Jobs.ExecProcessor", args, ReadKey, , TesterCache.Testing ());
	
EndProcedure

&AtClient
Procedure ReadingComplete(Result, Params) export
	
	if (Result = undefined) then
		return;
	endif;
	applyFilling();
	
EndProcedure

&AtServer
Procedure applyFilling()
	
	result = GetFromTempStorage(ResultAddress);
	if (result = undefined) then
		Object.Status = 2;
	else
		Object.Details.Load(result.Details);
		Object.Receipts.Load(result.Receipts);
		Object.Expenses.Load(result.Expenses);
		ok = (Object.Receipts.Count() > 0 or Object.Expenses.Count() > 0);
		Object.Status = ?(ok, 1, 2);
	endif;
	Appearance.Apply(ThisObject, "Object.Status");
	
EndProcedure

&AtClient
Procedure CompanyOnChange(Item)
	
	applyCompany();
	makeDirty();
	
EndProcedure

&AtClient
Procedure makeDirty()
	
	Object.Status = 0;
	Object.Details.Clear();
	Object.Expenses.Clear();
	Object.Receipts.Clear();
	Appearance.Apply(ThisObject, "Object.Status");
	
EndProcedure

&AtClient
Procedure BankAccountOnChange(Item)
	
	applyBankAccount(Object);
	makeDirty();
	
EndProcedure

&AtClient
Procedure PathStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = false;
	BankingForm.ChooseLoading(Object.Application, Item);
	
EndProcedure

&AtClient
Procedure PathOnChange(Item)
	
	makeDirty();
	if (not IsBlankString(Object.Path)) then
		OutputCont.LoadPaymentsConfirmation(ThisObject);
	endif;
	
EndProcedure

&AtClient
Procedure LoadPaymentsConfirmation(Answer, Params) export
	
	if (Answer = DialogReturnCode.No) then
		return;
	endif;
	startReading();
	
EndProcedure

&AtClient
Procedure ApplicationOnChange(Item)
	
	Object.Path = "";
	makeDirty();
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	if (CurrentPage = Items.GroupReceipts) then
		syncDetails(ReceiptsRow);
	elsif (CurrentPage = Items.GroupExpenses) then
		syncDetails(ExpensesRow);
	endif;
	
EndProcedure

&AtClient
Procedure syncDetails(Row)
	
	if (Row = undefined) then
		return;
	endif;
	filter = new Structure("LineNumber", Row.DetailsLine);
	rows = Object.Details.FindRows(filter);
	if (rows.Count() = 0) then
		return;
	endif;
	Items.Details.CurrentRow = rows[0].GetID();
	
EndProcedure

// *****************************************
// *********** Table Receipt

&AtClient
Procedure MarkAllReceipts(Command)
	
	mark(Object.Receipts, true);
	
EndProcedure

&AtClient
Procedure mark(Table, Flag)
	
	for each row in Table do
		row.Download = Flag;
	enddo;
	
EndProcedure

&AtClient
Procedure UnmarkAllReceipts(Command)
	
	mark(Object.Receipts, false);
	
EndProcedure

&AtClient
Procedure ReceiptsOnActivateRow(Item)
	
	ReceiptsRow = Item.CurrentData;
	Appearance.Apply(ThisObject, "ReceiptsRow");
	syncDetails(ReceiptsRow);
	
EndProcedure

&AtClient
Procedure ReceiptsSelection(Item, SelectedRow, Field, StandardProcessing)
	
	if (Field = Items.ReceiptsDocument) then
		openDocument(ReceiptsRow.Document);
	endif;
	
EndProcedure

&AtClient
Procedure openDocument(Ref)
	
	if (ValueIsFilled(Ref)) then
		ShowValue( , Ref);
	endif;
	
EndProcedure

&AtClient
Procedure ReceiptsOnEditEnd(Item, NewRow, CancelEdit)
	
	if (not CancelEdit) then
		enableDownload(Item);
	endif;
	
EndProcedure

&AtClient
Procedure enableDownload(Item)
	
	column = Item.CurrentItem.Name;
	if (column = "ExpensesDownload"
			or column = "ReceiptsDownload") then
		return;
	else
		Item.CurrentData.Download = true;
	endif;
	
EndProcedure

&AtClient
Procedure ReceiptsBankOperationOnChange(Item)
	
	applyBankOperation(ReceiptsRow);
	
EndProcedure

&AtClient
Procedure applyBankOperation(Row)
	
	operation = row.BankOperation;
	if (operation = PredefinedValue("Enum.BankOperations.InternalMovement")) then
		row.Receiver = undefined;
		row.Contract = undefined;
		row.AdvanceAccount = undefined;
		row.CashFlow = Object.InternalMovement;
		Appearance.Apply(ThisObject, "ExpensesRow.BankOperation");
	elsif (operation = PredefinedValue("Enum.BankOperations.OtherExpense")) then
		row.Receiver = undefined;
		row.Contract = undefined;
		row.AdvanceAccount = undefined;
		row.CashFlow = Object.OtherExpense;
		Appearance.Apply(ThisObject, "ExpensesRow.BankOperation");
	elsif (operation = PredefinedValue("Enum.BankOperations.OtherReceipt")) then
		row.Payer = undefined;
		row.Contract = undefined;
		row.AdvanceAccount = undefined;
		row.CashFlow = Object.OtherReceipt;
		Appearance.Apply(ThisObject, "ReceiptsRow.BankOperation");
	elsif (operation = PredefinedValue("Enum.BankOperations.Payment")
			or operation = PredefinedValue("Enum.BankOperations.ReturnFromVendor")) then
		row.Operation = undefined;
		Appearance.Apply(ThisObject, "ReceiptsRow.BankOperation");
	elsif (operation = PredefinedValue("Enum.BankOperations.ReturnToCustomer")
			or operation = PredefinedValue("Enum.BankOperations.VendorPayment")) then
		row.Operation = undefined;
		Appearance.Apply(ThisObject, "ExpensesRow.BankOperation");
	endif;
	
EndProcedure

&AtClient
Procedure ReceiptsOperationOnChange(Item)
	
	setAccountCr();
	
EndProcedure

&AtClient
Procedure setAccountCr()
	
	ReceiptsRow.Account = DF.Pick(ReceiptsRow.Operation, "AccountCr");
	
EndProcedure

&AtClient
Procedure ReceiptsPayerOnChange(Item)
	
	applyPayer();
	
EndProcedure

&AtClient
Procedure applyPayer()
	
	data = payerData(ReceiptsRow.Payer, ReceiptsRow.BankOperation, Object.Company);
	FillPropertyValues(ReceiptsRow, data);
	
EndProcedure

&AtServerNoContext
Function payerData(val Payer, val Operation, val Company)
	
	data = new Structure("Account, AdvanceAccount, Contract, CashFlow");
	if (Operation = Enums.BankOperations.Payment) then
		accounts = AccountsMap.Organization(Payer, Company, "CustomerAccount, AdvanceTaken");
		data.Account = accounts.CustomerAccount;
		data.AdvanceAccount = accounts.AdvanceTaken;
		contract = DF.Values(Payer, "CustomerContract, CustomerContract.Company as Company");
		if (contract.Company = Company) then
			data.Contract = contract.CustomerContract;
		endif;
	elsif (Operation = Enums.BankOperations.ReturnFromVendor) then
		accounts = AccountsMap.Organization(Payer, Company, "VendorAccount, AdvanceTaken");
		data.Account = accounts.VendorAccount;
		data.AdvanceAccount = accounts.AdvanceTaken;
		contract = DF.Values(Payer, "VendorContract, VendorContract.Company as Company");
		if (contract.Company = Company) then
			data.Contract = contract.VendorContract;
		endif;
	endif;
	data.CashFlow = contractCashFlow(Operation, data.Contract);
	return data;
	
EndFunction

&AtClientAtServerNoContext
Function contractCashFlow(Operation, Contract)
	
	if (not ValueIsFilled(Contract)) then
		return undefined;
	endif;
	if (Operation = PredefinedValue("Enum.BankOperations.Payment")
			or Operation = PredefinedValue("Enum.BankOperations.ReturnToCustomer")) then
		return DF.Pick(Contract, "CustomerCashFlow");
	elsif (Operation = PredefinedValue("Enum.BankOperations.ReturnFromVendor")
			or Operation = PredefinedValue("Enum.BankOperations.VendorPayment")) then
		return DF.Pick(Contract, "VendorCashFlow");
	endif;
	
EndFunction

&AtClient
Procedure ReceiptsContractOnChange(Item)
	
	applyContract(ReceiptsRow);
	
EndProcedure

&AtClient
Procedure applyContract(Row)
	
	Row.CashFlow = contractCashFlow(Row.BankOperation, Row.Contract);
	
EndProcedure

// *****************************************
// *********** Table Expenses

&AtClient
Procedure MarkAllExpenses(Command)
	
	mark(Object.Expenses, true);
	
EndProcedure

&AtClient
Procedure UnmarkAllExpenses(Command)
	
	mark(Object.Expenses, false);
	
EndProcedure

&AtClient
Procedure ExpensesOnActivateRow(Item)
	
	ExpensesRow = Item.CurrentData;
	syncDetails(ExpensesRow);
	Appearance.Apply(ThisObject, "ExpensesRow");
	
EndProcedure

&AtClient
Procedure ExpensesOnEditEnd(Item, NewRow, CancelEdit)
	
	if (not CancelEdit) then
		enableDownload(Item);
	endif;
	
EndProcedure

&AtClient
Procedure ExpensesSelection(Item, SelectedRow, Field, StandardProcessing)
	
	if (Field = Items.ExpensesDocument) then
		openDocument(ExpensesRow.Document);
	endif;
	
EndProcedure

&AtClient
Procedure ExpensesOperationOnChange(Item)
	
	setAccountDr();
	
EndProcedure

&AtClient
Procedure setAccountDr()
	
	ExpensesRow.Account = DF.Pick(ExpensesRow.Operation, "AccountDr");
	
EndProcedure

&AtClient
Procedure ExpensesBankOperationOnChange(Item)
	
	applyBankOperation(ExpensesRow);
	
EndProcedure

&AtClient
Procedure ExpensesReceiverOnChange(Item)
	
	applyReceiver();
	
EndProcedure

&AtClient
Procedure applyReceiver()
	
	data = receiverData(ExpensesRow.Receiver, ExpensesRow.BankOperation, Object.Company);
	FillPropertyValues(ExpensesRow, data);
	
EndProcedure

&AtServerNoContext
Function receiverData(val Receiver, val Operation, val Company)
	
	data = new Structure("Account, AdvanceAccount, Contract, CashFlow");
	if (Operation = Enums.BankOperations.VendorPayment) then
		accounts = AccountsMap.Organization(Receiver, Company, "VendorAccount, AdvanceGiven");
		data.Account = accounts.VendorAccount;
		data.AdvanceAccount = accounts.AdvanceGiven;
		contract = DF.Values(Receiver, "VendorContract, VendorContract.Company as Company");
		if (contract.Company = Company) then
			data.Contract = contract.VendorContract;
		endif;
	elsif (Operation = Enums.BankOperations.ReturnToCustomer) then
		accounts = AccountsMap.Organization(Receiver, Company, "CustomerAccount, AdvanceGiven");
		data.Account = accounts.CustomerAccount;
		data.AdvanceAccount = accounts.AdvanceGiven;
		contract = DF.Values(Receiver, "CustomerContract, CustomerContract.Company as Company");
		if (contract.Company = Company) then
			data.Contract = contract.CustomerContract;
		endif;
	endif;
	data.CashFlow = contractCashFlow(Operation, data.Contract);
	return data;
	
EndFunction

&AtClient
Procedure ExpensesContractOnChange(Item)
	
	applyContract(ExpensesRow);
	
EndProcedure

// *****************************************
// *********** Table Details

&AtClient
Procedure DetailsSelection(Item, SelectedRow, Field, StandardProcessing)
	
	filter = new Structure("DetailsLine", Items.Details.CurrentData.LineNumber);
	rows = Object.Receipts.FindRows(filter);
	if (rows.Count() = 0) then
		rows = Object.Expenses.FindRows(filter);
		if (rows.Count() = 0) then
			return;
		endif;
	endif;
	openDocument(rows[0].Document);
	
EndProcedure

// *****************************************
// *********** Variables Initialization

WritingStarted = false;
