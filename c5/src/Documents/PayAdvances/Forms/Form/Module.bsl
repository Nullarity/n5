&AtServer
var Env;
&AtClient
var TableRow export;
&AtClient
var TableTaxRow export;
&AtClient
var TableTotalsRow export;
&AtClient
var RemovingEmployees;
&AtClient
var FillDocument; 
&AtClient
var CalculateAll; 
&AtClient
var CalculateTaxes; 
&AtServer
var FillDocument; 
&AtServer
var CalculateAll; 
&AtServer
var CalculateTaxes; 

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	PettyCash.Read ( ThisObject );
	InvoiceForm.SetLocalCurrency ( ThisObject );
	findPaymentOrder ();
	setLinks ();
	Constraints.ShowAccess ( ThisObject );
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure findPaymentOrder ()
	
	s = "select top 1 1 from Document.PaymentOrder where Base = &Ref and not DeletionMark";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	PaymentOrderExists = not q.Execute ().IsEmpty ();
	
EndProcedure

&AtServer
Procedure setLinks ()
	
	SQL.Init ( Env );
	sqlLinks ();
	if ( Env.Selection.Count () = 0 ) then
		ShowLinks = false;
	else
		q = Env.Q;
		q.SetParameter ( "Ref", Object.Ref );
		SQL.Perform ( Env, false );
		setURLPanel ();
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	if ( isNew () ) then
		return;
	endif; 
	s = "
	|// #PaymentOrders
	|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
	|from Document.PaymentOrder as Documents
	|where Documents.Base = &Ref
	|and not Documents.DeletionMark
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	meta = Metadata.Documents;
	if ( not isNew () ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.PaymentOrders, meta.PaymentOrder ) );
	endif; 
	s = URLPanel.Build ( parts );
	if ( s = undefined ) then
		ShowLinks = false;
	else
		ShowLinks = true;
		Links = s;
	endif; 
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing)
	
	if ( isNew () ) then
		DocumentForm.Init ( Object );
		fillNew ();
		setLinks ();
		defineCopy ();
		Constraints.ShowAccess ( ThisObject );
	endif; 
	InvoiceForm.SetLocalCurrency ( ThisObject );
	PaymentForm.FilterAccount ( ThisObject );
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Function isNew ()
	
	return Object.Ref.IsEmpty ();
	
EndFunction

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Links show ShowLinks;
	|ThisObject lock PaymentOrderExists;
	|PaymentOrder hide PaymentOrderExists;
	|WarningPaid show PaymentOrderExists;
	|Warning UndoPosting show Object.Posted and not PaymentOrderExists;
	|Compensations Taxes Date Number Company DepositLiabilities PaymentGroup lock Object.Posted;
	|GroupCommands CompensationsEdit TaxesEditTax enable not Object.Posted;
	|Calculate CalculateTaxes show not Object.Dirty;
	|Calculate1 CalculateTaxes1 Ignore show Object.Dirty;
	|BankAccount show filled ( Object.Method ) and Object.Method <> Enum.PaymentMethods.Cash;
	|Voucher FormVoucher show filled ( Voucher ) and Object.Method = Enum.PaymentMethods.Cash;
	|NewVoucher show empty ( Voucher ) and Object.Method = Enum.PaymentMethods.Cash;
	|Reference ReferenceDate show filled ( Object.Method ) and Object.Method <> Enum.PaymentMethods.Cash;
	|Account CashFlow show filled ( Object.Method );
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
	|from Document.PayAdvances as Documents
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

&AtServer
Procedure defineCopy ()
	
	CopyOf = Parameters.CopyingValue;

EndProcedure

&AtClient
Procedure NewWriteProcessing ( NewObject, Source, StandardProcessing )
	
	if ( TypeOf ( NewObject ) = Type ( "DocumentRef.PaymentOrder" ) ) then
		lock ();
	endif;
	
EndProcedure

&AtServer
Procedure lock ()
	
	setLinks ();
	PaymentOrderExists = true;
	Appearance.Apply ( ThisObject, "PaymentOrderExists" );

EndProcedure

&AtClient
Procedure ChoiceProcessing ( SelectedValue, ChoiceSource )
	
	operation = SelectedValue.Operation;
	if ( operation = Enum.ChoiceOperationsPayAdvancesRecord () ) then
		PayrollForm.LoadRow ( ThisObject, SelectedValue );
		PayrollForm.SyncTables ( ThisObject, "Taxes" );
	elsif ( operation = Enum.ChoiceOperationsEmployeesTaxRecord () ) then
		PayrollForm.LoadTaxRow ( ThisObject, SelectedValue );
	elsif ( operation = Enum.ChoiceOperationsPayAdvancesRecordSaveAndNew () ) then
		PayrollForm.LoadRow ( ThisObject, SelectedValue );	
		PayrollForm.SyncTables ( ThisObject, "Taxes" );
		PayrollForm.NewRow ( ThisObject, false );
	elsif ( operation = Enum.ChoiceOperationsEmployeesTaxRecordSaveAndNew () ) then	
		PayrollForm.LoadTaxRow ( ThisObject, SelectedValue );
		PayrollForm.NewTaxRow ( ThisObject, false );
	endif; 
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	PayrollForm.BeforeWrite ( CurrentObject, WriteParameters, CopyOf );
	
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
	p.Report = "PayAdvancesFilling";
	p.Filters = getFilters ();
	p.Background = true;
	p.Batch = true;
	return p;
	
EndFunction

&AtServer
Function getFilters ()
	
	filters = new Array ();
	ref = Object.Ref;
	if ( CalculationVariant <> FillDocument ) then
		item = DC.CreateParameter ( "CalculatingDocument", ref );
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
	
	return Write ( new Structure ( Enum.WriteParametersJustSave (), true ) );
	
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
	PayrollForm.SyncTables ( ThisObject, "Taxes" );
	
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
	
	trackDeletion ( Item );
	
EndProcedure

&AtClient
Procedure trackDeletion ( Table )
	
	RemovingEmployees = new Array ();
	column = ? ( Table = Items.Compensations, "Individual", "Employee" );
	for each id in Table.SelectedRows do
		row = Table.RowData ( id );
		RemovingEmployees.Add ( row [ column ] );
	enddo;
	Collections.Group ( RemovingEmployees );
	
EndProcedure

&AtClient
Procedure CompensationsAfterDeleteRow ( Item )
	
	completeDeletion ( Item );
	
EndProcedure

&AtClient
Procedure completeDeletion ( Table )
	
	deleteTax = ( Table = Items.Compensations );
	if ( deleteTax ) then
		PayrollForm.DeleteTaxes ( Object, RemovingEmployees );
	endif;
	PayrollForm.CalcEmployees ( Object, RemovingEmployees );
	RemovingEmployees.Clear ();

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
	
	trackDeletion ( Item );
	
EndProcedure

&AtClient
Procedure TaxesAfterDeleteRow ( Item )
	
	completeDeletion ( Item );
	
EndProcedure

// *****************************************
// *********** Variables Initialization

FillDocument = 1; 
CalculateAll = 2;
CalculateTaxes = 3;
