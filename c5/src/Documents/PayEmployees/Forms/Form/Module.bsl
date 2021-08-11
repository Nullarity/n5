&AtClient
var TableRow export;
&AtClient
var TableTaxRow export;
&AtClient
var TableTotalsRow export;
&AtClient
var RemovingEmployee;
&AtClient
var FillDocument; 
&AtClient
var CalculateAll; 
&AtClient
var CalculateTaxes; 

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	PettyCash.Read ( ThisObject );
	InvoiceForm.SetLocalCurrency ( ThisObject );
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing)
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.Init ( Object );
		fillNew ();
	endif; 
	InvoiceForm.SetLocalCurrency ( ThisObject );
	PaymentForm.FilterAccount ( ThisObject );
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Warning UndoPosting show Object.Posted;
	|Compensations Taxes Date Number Company DepositLiabilities PaymentGroup lock Object.Posted;
	|GroupCommands CompensationsEdit TaxesEditTax enable not Object.Posted;
	|Calculate CalculateTaxes show not Object.Dirty;
	|Calculate1 CalculateTaxes1 Ignore show Object.Dirty;
	|BankAccount show filled ( Object.Method ) and Object.Method <> Enum.PaymentMethods.Cash;
	|Voucher FormVoucher show filled ( Voucher ) and Object.Method = Enum.PaymentMethods.Cash;
	|NewVoucher show empty ( Voucher ) and Object.Method = Enum.PaymentMethods.Cash;
	|Reference ReferenceDate show filled ( Object.Method ) and Object.Method <> Enum.PaymentMethods.Cash;
	|Account CashFlow show filled ( Object.Method )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	settings = Logins.Settings ( "Company, PaymentLocation" );
	Object.Location = settings.PaymentLocation;
	Object.Company = settings.Company;
	initMethod ();
	initAccounts ();
	PaymentForm.SetBankAccount ( Object );
	PaymentForm.SetAccount ( Object );
	
EndProcedure 

&AtServer
Procedure initMethod ()
	
	method = lastMethod ();
	if ( method = undefined ) then
		Object.Method = Enums.PaymentMethods.Bank;
	else
		Object.Method = method;
	endif; 
	
EndProcedure 

&AtServer
Function lastMethod ()
	
	s = "
	|select allowed top 1 Documents.Method as Method
	|from Document.PayEmployees as Documents
	|where Documents.Posted
	|and Documents.Company = &Company
	|order by Documents.Date desc
	|";
	q = new Query ( s );
	q.SetParameter ( "Company", Object.Company );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Method );

EndFunction 

&AtServer
Procedure initAccounts ()
	
	Object.DepositLiabilities = InformationRegisters.Settings.GetLast ( ,
		new Structure ( "Parameter", ChartsOfCharacteristicTypes.Settings.DepositLiabilities ) ).Value;
	
EndProcedure 

&AtClient
Procedure ChoiceProcessing ( SelectedValue, ChoiceSource )
	
	operation = SelectedValue.Operation;
	if ( operation = Enum.ChoiceOperationsPayEmployeesRecord () ) then
		PayrollForm.LoadRow ( ThisObject, SelectedValue );
	elsif ( operation = Enum.ChoiceOperationsEmployeesTaxRecord () ) then
		PayrollForm.LoadTaxRow ( ThisObject, SelectedValue );
	elsif ( operation = Enum.ChoiceOperationsPayEmployeesRecordSaveAndNew () ) then
		PayrollForm.LoadRow ( ThisObject, SelectedValue );	
		PayrollForm.NewRow ( ThisObject, false );
	elsif ( operation = Enum.ChoiceOperationsEmployeesTaxRecordSaveAndNew () ) then	
		PayrollForm.LoadTaxRow ( ThisObject, SelectedValue );
		PayrollForm.NewTaxRow ( ThisObject, false );
	endif; 
	
EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	PayrollForm.BeforeWrite ( CurrentObject, WriteParameters );
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	PettyCash.Read ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure Fill ( Command )
	
	runCalculations ( FillDocument );
	
EndProcedure

&AtClient
Procedure runCalculations ( Variant )
	
	CalculationVariant = Variant;
	if ( Forms.Check ( ThisObject, "Company" ) ) then
		params = fillingParams ();
		if ( CalculationVariant = FillDocument ) then
			Filler.Open ( params, ThisObject );
		else
			Filler.ProcessData ( params, ThisObject );
		endif; 
	endif; 
	
EndProcedure 

&AtServer
Function fillingParams ()
	
	p = Filler.GetParams ();
	p.Report = "PayEmployeesFilling";
	p.Filters = getFilters ();
	p.Background = true;
	p.Batch = true;
	return p;
	
EndFunction

&AtServer
Function getFilters ()
	
	filters = new Array ();
	ref = Object.Ref;
	if ( CalculationVariant = 2 ) then
		item = DC.CreateParameter ( "CalculatingDocument", ref );
		filters.Add ( item );
	elsif ( CalculationVariant = 3 ) then
		item = DC.CreateParameter ( "CalculatingTaxesDocument", ref );
		filters.Add ( item );
	endif; 
	item = DC.CreateParameter ( "CalculationVariant", CalculationVariant );
	filters.Add ( item );
	item = DC.CreateParameter ( "Date", Catalogs.Calendar.GetDate ( Periods.GetDocumentDate ( Object ) ) );
	filters.Add ( item );
	item = DC.CreateParameter ( "Ref", ref );
	filters.Add ( item );
	item = DC.CreateFilter ( "Company", Object.Company );
	filters.Add ( item );
	account = InformationRegisters.Settings.GetLast ( , new Structure ( "Parameter", ChartsOfCharacteristicTypes.Settings.PayrollAccount ) ).Value;
	item = DC.CreateParameter ( "Account", account );
	filters.Add ( item );
	return filters;
	
EndFunction

&AtClient
Procedure Filling ( Result, Params ) export
	
	if ( not fillTables ( Result ) ) then
		Output.FillingDataNotFound ();
	endif;
	
EndProcedure 

&AtServer
Function fillTables ( val Result )
	
	return PayrollForm.FillTables ( ThisObject, Result );

EndFunction

&AtClient
Procedure Calculate ( Command )
	
	if ( Modified ) then
		Output.SaveModifiedObject ( ThisObject, CalculateAll );
	else
		runCalculations ( CalculateAll );
	endif; 
	
EndProcedure

&AtClient
Procedure SaveModifiedObject ( Answer, Variant ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	if ( save () ) then
		runCalculations ( Variant );
	endif; 
	
EndProcedure

&AtClient
Function save ()
	
	return Write ( new Structure ( "JustSave", true ) );
	
EndFunction

&AtClient
Procedure CalculateTaxes ( Command )
	
	if ( Modified ) then
		Output.SaveModifiedObject ( ThisObject, CalculateTaxes );
	else
		runCalculations ( CalculateTaxes );
	endif; 
	
EndProcedure

&AtClient
Procedure Ignore ( Command )
	
	PayrollForm.MakeClean ( ThisObject );
	
EndProcedure

&AtClient
Procedure MethodOnChange ( Item )
	
	applyMethod ();
	
EndProcedure

&AtServer
Procedure applyMethod ()
	
	PaymentForm.SetBankAccount ( Object );
	PaymentForm.SetAccount ( Object );
	PaymentForm.FilterAccount ( ThisObject );
	if ( Object.Method.IsEmpty () ) then
		Object.CashFlow = undefined;
	endif; 
	Appearance.Apply ( ThisObject, "Object.Method" );
	
EndProcedure

&AtClient
Procedure NewVoucher ( Command )
	
	notifyNew = Object.Ref.IsEmpty ();
	createVoucher ();
	PettyCash.Open ( ThisObject, notifyNew );
	
EndProcedure

&AtServer
Procedure createVoucher ()
	
	PettyCash.NewReference ( ThisObject );
	Appearance.Apply ( ThisObject, "Voucher" );
	
EndProcedure 

&AtClient
Procedure VoucherClick ( Item, StandardProcessing )
	
	PettyCash.ClickProcessing ( ThisObject, StandardProcessing );

EndProcedure

&AtClient
Procedure BankAccountOnChange ( Item )
	
	applyBankAccount ();
	
EndProcedure

&AtServer
Procedure applyBankAccount ()
	
	PaymentForm.SetAccount ( Object );
	
EndProcedure 

&AtClient
Procedure LocationOnChange ( Item )
	
	applyLocation ();
	
EndProcedure

&AtServer
Procedure applyLocation ()
	
	PaymentForm.SetAccount ( Object );
	PaymentForm.FilterAccount ( ThisObject );
	
EndProcedure 

&AtClient
Procedure CompanyOnChange ( Item )
	
	applyCompany ();
	
EndProcedure

&AtServer
Procedure applyCompany ()
	
	PaymentForm.SetBankAccount ( Object );
	applyBankAccount ();
	
EndProcedure 

// *****************************************
// *********** Table Totals

&AtClient
Procedure TotalsOnActivateRow ( Item )
	
	TableTotalsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure TotalsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	PayrollForm.OpenCalculations ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Table Compensation

&AtClient
Procedure Edit ( Command )
	
	PayrollForm.EditRow ( ThisObject );
	
EndProcedure

&AtClient
Procedure CompensationsOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	PayrollForm.SyncTaxes ( ThisObject );
	
EndProcedure

&AtClient
Procedure CompensationsBeforeRowChange ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure CompensationsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	PayrollForm.EditRow ( ThisObject );

EndProcedure

&AtClient
Procedure CompensationsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	PayrollForm.NewRow ( ThisObject, Clone );
	
EndProcedure

&AtClient
Procedure CompensationsBeforeDeleteRow ( Item, Cancel )
	
	RemovingEmployee = TableRow.Employee;
	
EndProcedure

&AtClient
Procedure CompensationsAfterDeleteRow ( Item )
	
	PayrollForm.DeleteTaxes ( Object, RemovingEmployee );
	PayrollForm.CalcEmployee ( Object, RemovingEmployee );
	
EndProcedure

&AtClient
Procedure CompensationsOnChange ( Item )
	
	PayrollForm.MakeDirty ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Table Taxes

&AtClient
Procedure EditTax ( Command )
	
	PayrollForm.EditTaxRow ( ThisObject );
	
EndProcedure

&AtClient
Procedure TaxesOnActivateRow ( Item )
	
	TableTaxRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure TaxesBeforeRowChange ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure TaxesSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	PayrollForm.EditTaxRow ( ThisObject );

EndProcedure

&AtClient
Procedure TaxesBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	PayrollForm.NewTaxRow ( ThisObject, Clone );
	
EndProcedure

&AtClient
Procedure TaxesBeforeDeleteRow ( Item, Cancel )
	
	RemovingEmployee = TableTaxRow.Employee;
	
EndProcedure

&AtClient
Procedure TaxesAfterDeleteRow ( Item )
	
	PayrollForm.CalcEmployee ( Object, RemovingEmployee );
	
EndProcedure

// *****************************************
// *********** Variables Initialization

FillDocument = 1; 
CalculateAll = 2;
CalculateTaxes = 3;
