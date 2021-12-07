&AtClient
var ReceiptsRow export;
&AtClient
var ExpensesRow export;
&AtClient
var WritingStarted;
&AtClient
var AccountData;

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
	|Receipts Expenses lock Object.Posted;
	|#c ExpensesBankOperation unlock ExpensesRow <> undefined and empty ( ExpensesRow.Document );
	|#c ExpensesAdvanceAccount unlock ExpensesRow <> undefined
	|	and inlist ( ExpensesRow.BankOperation, Enum.BankOperations.VendorPayment, Enum.BankOperations.ReturnToCustomer );
	|#c ExpensesOperation unlock ExpensesRow <> undefined
	|	and inlist ( ExpensesRow.BankOperation, Enum.BankOperations.OtherExpense );
	|#c ReceiptsBankOperation unlock ReceiptsRow <> undefined and empty ( ReceiptsRow.Document );
	|#c ReceiptsAdvanceAccount unlock ReceiptsRow <> undefined
	|	and inlist ( ReceiptsRow.BankOperation, Enum.BankOperations.Payment, Enum.BankOperations.ReturnFromVendor );
	|#c ReceiptsOperation unlock ReceiptsRow <> undefined and ReceiptsRow.BankOperation = Enum.BankOperations.OtherReceipt;
	|");
	Appearance.Read(ThisObject, rules);
	
EndProcedure

&AtServer
Function isCopy()
	
	if (not Parameters.CopyingValue.IsEmpty()) then
		Output.CannotCopyBankingApp();
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
	
	data = DF.Values(Object.Company, "BankAccount, BankAccount.Bank.Application.Loading as Path");
	Object.BankAccount = data.BankAccount;
	Object.Path = data.Path;
	applyBankAccount(Object);
	
EndProcedure

&AtClientAtServerNoContext
Procedure applyBankAccount(val Object)
	
	data = DF.Values(Object.BankAccount, "Account, Bank.Application as Application, Bank.Application.Loading as Path");
	Object.Account = data.Account;
	Object.Application = data.Application;
	Object.Path = data.Path;
	
EndProcedure

&AtServer
Procedure initOperations()
	
	s = "
	|select top 1 Documents.OtherExpense as OtherExpense, Documents.OtherReceipt as OtherReceipt
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
	Object.Received = Object.Receipts.Total ( "Amount" );
	Object.Expense = Object.Expenses.Total ( "Amount" );
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
	BankingForm.ChooseLoadingFile(Object.Application, Item);
	
EndProcedure

&AtClient
Procedure PathOnChange(Item)
	
	makeDirty();
	if (not IsBlankString(Object.Path)) then
		Output.LoadPaymentsConfirmation(ThisObject);
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
	
	setPath ();
	makeDirty();
	
EndProcedure

&AtClient
Procedure setPath ()
	
	Object.Path = DF.Pick ( Object.Application, "Loading", "" );

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
// *********** Table Details

&AtClient
Procedure DetailsSelection(Item, SelectedRow, Field, StandardProcessing)
	
	activateRecord ();
	
EndProcedure

&AtClient
Procedure activateRecord ()
	
	filter = new Structure("DetailsLine", Items.Details.CurrentData.LineNumber);
	rows = Object.Receipts.FindRows(filter);
	if (rows.Count() = 0) then
		rows = Object.Expenses.FindRows(filter);
		if (rows.Count() = 0) then
			return;
		endif;
		Items.Pages.CurrentPage = Items.GroupExpenses;
		Items.Expenses.CurrentRow = rows [ 0 ].GetID ();
	else
		Items.Pages.CurrentPage = Items.GroupReceipts;
		Items.Receipts.CurrentRow = rows [ 0 ].GetID ();
	endif;

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
	
	resetDims ( Item );
	if (not CancelEdit) then
		enableDownload(Item);
	endif;
	
EndProcedure

&AtClient
Procedure resetDims ( Item )
	
	name = Item.Name;
	Items [ name + "Currency" ].ReadOnly = false;
	Items [ name + "CurrencyAmount" ].ReadOnly = false;
	Items [ name + "Rate" ].ReadOnly = false;
	Items [ name + "Factor" ].ReadOnly = false;
	Items [ name + "Dim1" ].ReadOnly = false;
	Items [ name + "Dim2" ].ReadOnly = false;
	Items [ name + "Dim3" ].ReadOnly = false;
	
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
Procedure ReceiptsBeforeRowChange(Item, Cancel)

	readAccount ( Item );
	enableDims ( Item );

EndProcedure

&AtClient
Procedure readAccount ( Item )
	
	AccountData = GeneralAccounts.GetData ( Item.CurrentData.Account );
	
EndProcedure 

&AtClient
Procedure enableDims ( Item )
	
	fields = AccountData.Fields;
	local = not fields.Currency;
	name = Item.Name;
	Items [ name + "Currency" ].ReadOnly = local;
	Items [ name + "CurrencyAmount" ].ReadOnly = local;
	Items [ name + "Rate" ].ReadOnly = local;
	Items [ name + "Factor" ].ReadOnly = local;
	level = fields.Level;
	dim = name + "Dim";
	for i = 1 to 3 do
		disable = ( level < i );
		Items [ dim + i ].ReadOnly = disable;
	enddo; 
	
EndProcedure 

&AtClient
Procedure ReceiptsBankOperationOnChange(Item)
	
	applyBankOperation(Items.Receipts);
	
EndProcedure

&AtClient
Procedure applyBankOperation(Item)
	
	row = Item.CurrentData;
	operation = row.BankOperation;
	if (operation = PredefinedValue("Enum.BankOperations.OtherExpense")) then
		row.AdvanceAccount = undefined;
		row.Operation = Object.OtherExpense;
	elsif (operation = PredefinedValue("Enum.BankOperations.OtherReceipt")) then
		row.AdvanceAccount = undefined;
		row.Operation = Object.OtherReceipt;
	else
		row.Operation = undefined;
	endif;
	field = ? ( Item = Items.Receipts, "ReceiptsRow.BankOperation", "ExpensesRow.BankOperation" );
	Appearance.Apply(ThisObject, field);
	
EndProcedure

&AtClient
Procedure ReceiptsOperationOnChange(Item)
	
	setAccount(Items.Receipts);
	
EndProcedure

&AtClient
Procedure setAccount(Item)
	
	row = Item.CurrentData;
	side = ? ( Item = Items.Receipts, "AccountCr", "AccountDr" );
	account = DF.Pick(row.Operation, side );
	if ( ValueIsFilled ( account ) ) then
		ReceiptsRow.Account = account;
	endif;
	
EndProcedure

&AtClient
Procedure ReceiptsAccountOnChange(Item)

	control = Items.Receipts;
	readAccount ( control );
	adjustDims ( control );
	enableDims ( control );

EndProcedure

&AtClient
Procedure adjustDims ( Item )
	
	fields = AccountData.Fields;
	dims = AccountData.Dims;
	row = Item.CurrentData;
	if ( not fields.Currency ) then
		row.Currency = undefined;
		row.CurrencyAmount = 0;
		row.Rate = 0;
		row.Factor = 0;
	endif; 
	level = fields.Level;
	if ( level = 0 ) then
		row.Dim1 = undefined;
		row.Dim2 = undefined;
		row.Dim3 = undefined;
	elsif ( level = 1 ) then
		row.Dim1 = dims [ 0 ].ValueType.AdjustValue ( row.Dim1 );
		row.Dim2 = undefined;
		row.Dim3 = undefined;
	elsif ( level = 2 ) then
		row.Dim1 = dims [ 0 ].ValueType.AdjustValue ( row.Dim1 );
		row.Dim2 = dims [ 1 ].ValueType.AdjustValue ( row.Dim2 );
		row.Dim3 = undefined;
	else
		row.Dim1 = dims [ 0 ].ValueType.AdjustValue ( row.Dim1 );
		row.Dim2 = dims [ 1 ].ValueType.AdjustValue ( row.Dim2 );
		row.Dim3 = dims [ 2 ].ValueType.AdjustValue ( row.Dim3 );
	endif; 

EndProcedure

&AtClient
Procedure ReceiptsDim1StartChoice(Item, ChoiceData, StandardProcessing)
	
	chooseDimension ( Items.Receipts, 1, StandardProcessing );
	
EndProcedure

&AtClient
Procedure chooseDimension ( Item, Level, StandardProcessing )
	
	p = Dimensions.GetParams ();
	p.Company = Object.Company;
	p.Level = Level;
	row = Item.CurrentData;
	p.Dim1 = row.Dim1;
	p.Dim2 = row.Dim2;
	p.Dim3 = row.Dim3;
	Dimensions.Choose ( p, Item.CurrentItem, StandardProcessing );
	
EndProcedure

&AtClient
Procedure ReceiptsDim1OnChange ( Item )

	applyDim1 (ReceiptsRow);

EndProcedure

&AtClient
Procedure applyDim1(Row)
	
	organization = Row.Dim1;
	if ( TypeOf ( organization ) <> Type ( "CatalogRef.Organizations" ) ) then
		return;
	endif;
	data = organizationData(organization, Row.BankOperation, Object.Company);
	value = data.Contract;
	if ( ValueIsFilled ( value ) ) then
		Row.Dim2 = value;
	endif;
	value = data.CashFlow;
	if ( ValueIsFilled ( value ) ) then
		Row.CashFlow = value;
	endif;
	
EndProcedure

&AtServerNoContext
Function organizationData(val Organization, val Operation, val Company)
	
	data = new Structure("Contract, CashFlow");
	if (Operation = Enums.BankOperations.Payment) then
		contract = DF.Values(Organization, "CustomerContract, CustomerContract.Company as Company");
		if (contract.Company = Company) then
			data.Contract = contract.CustomerContract;
		endif;
	elsif (Operation = Enums.BankOperations.ReturnFromVendor) then
		contract = DF.Values(Organization, "VendorContract, VendorContract.Company as Company");
		if (contract.Company = Company) then
			data.Contract = contract.VendorContract;
		endif;
	elsif (Operation = Enums.BankOperations.VendorPayment) then
		contract = DF.Values(Organization, "VendorContract, VendorContract.Company as Company");
		if (contract.Company = Company) then
			data.Contract = contract.VendorContract;
		endif;
	elsif (Operation = Enums.BankOperations.ReturnToCustomer) then
		contract = DF.Values(Organization, "CustomerContract, CustomerContract.Company as Company");
		if (contract.Company = Company) then
			data.Contract = contract.CustomerContract;
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
Procedure ReceiptsDim2StartChoice(Item, ChoiceData, StandardProcessing)
	
	chooseDimension ( Items.Receipts, 2, StandardProcessing );
	
EndProcedure

&AtClient
Procedure ReceiptsDim2OnChange(Item)

	applyContract(ReceiptsRow);

EndProcedure

&AtClient
Procedure applyContract(Row)
	
	contract = Row.Dim2;
	if ( TypeOf ( contract ) = Type ( "CatalogRef.Contracts" ) ) then
		Row.CashFlow = contractCashFlow(Row.BankOperation, contract);
	endif;
	
EndProcedure

&AtClient
Procedure ReceiptsDim3StartChoice(Item, ChoiceData, StandardProcessing)
	
	chooseDimension ( Items.Receipts, 3, StandardProcessing );
	
EndProcedure

&AtClient
Procedure ReceiptsCurrencyOnChange(Item)
	
	setCurrency ( ReceiptsRow );
	
EndProcedure

&AtClient
Procedure setCurrency ( Row )
	
	info = CurrenciesSrv.Get ( Row.Currency, Object.Date );
	Row.Rate = info.Rate;
	Row.Factor = info.Factor;
	
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
	
	resetDims ( Item );
	if (not CancelEdit) then
		enableDownload(Item);
	endif;
	
EndProcedure

&AtClient
Procedure ExpensesBeforeRowChange ( Item, Cancel )

	readAccount ( Item );
	enableDims ( Item );

EndProcedure

&AtClient
Procedure ExpensesSelection(Item, SelectedRow, Field, StandardProcessing)
	
	if (Field = Items.ExpensesDocument) then
		openDocument(ExpensesRow.Document);
	endif;
	
EndProcedure

&AtClient
Procedure ExpensesOperationOnChange(Item)
	
	setAccount(Items.Expenses);
	
EndProcedure

&AtClient
Procedure ExpensesBankOperationOnChange(Item)
	
	applyBankOperation(ExpensesRow);
	
EndProcedure

&AtClient
Procedure ExpensesAccountOnChange ( Item )
	
	control = Items.Expenses;
	readAccount ( control );
	adjustDims ( control );
	enableDims ( control );

EndProcedure

&AtClient
Procedure ExpensesDim1StartChoice(Item, ChoiceData, StandardProcessing)

	chooseDimension ( Items.Expenses, 1, StandardProcessing );

EndProcedure

&AtClient
Procedure ExpensesDim1OnChange(Item)
	
	applyDim1(ExpensesRow);
	
EndProcedure

&AtClient
Procedure ExpensesDim2StartChoice(Item, ChoiceData, StandardProcessing)
	
	chooseDimension ( Items.Expenses, 2, StandardProcessing );
	
EndProcedure

&AtClient
Procedure ExpensesDim2OnChange(Item)

	applyContract(ExpensesRow);

EndProcedure

&AtClient
Procedure ExpensesDim3StartChoice(Item, ChoiceData, StandardProcessing)
	
	chooseDimension ( Items.Expenses, 3, StandardProcessing );
	
EndProcedure

&AtClient
Procedure ExpensesCurrencyOnChange(Item)

	setCurrency ( ExpensesRow );

EndProcedure

// *****************************************
// *********** Variables Initialization

WritingStarted = false;
