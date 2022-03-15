&AtClient
var TableRow export;
&AtClient
var DrData export;
&AtClient
var CrData export;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	PettyCash.Read ( ThisObject );
	readOperation ();
	rememberOperation ();
	enableWarning ( ThisObject );
	Constraints.ShowAccess ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readOperation ()
	
	value = Object.Operation;
	obj = ? ( value.IsEmpty (), Catalogs.Operations.CreateItem (), value.GetObject () );
	ValueToFormAttribute ( obj, "Operation" );
	
EndProcedure 

&AtServer
Procedure rememberOperation ()
	
	OldOperation = Object.Method;

EndProcedure

&AtClientAtServerNoContext
Procedure enableWarning ( Form )
	
	if ( Form.Object.Operation.IsEmpty () ) then
		Form.Items.Operation.WarningOnEditRepresentation = WarningOnEditRepresentation.DontShow;
	else
		Form.Items.Operation.WarningOnEditRepresentation = WarningOnEditRepresentation.Show;
	endif; 

EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.Init ( Object );
		fillNew ();
		enableWarning ( ThisObject );
		defineCopy ();
		Constraints.ShowAccess ( ThisObject );
	endif; 
	InvoiceForm.SetLocalCurrency ( ThisObject );
	Options.SetAccuracy ( ThisObject, "RecordsQuantityDr, RecordsQuantityCr" );
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|OneRecordPage show Object.Simple;
	|RecordsPage show not Object.Simple;
	|AccountDr lock Object.Simple and filled ( Operation.AccountDr );
	|AccountCr lock Object.Simple and filled ( Operation.AccountCr );
	|NewReceipt show empty ( Receipt ) and Object.Method = Enum.Operations.CashReceipt;
	|NewVoucher show empty ( Voucher ) and Object.Method = Enum.Operations.CashExpense;
	|Receipt FormReceipt show filled ( Receipt ) and Object.Method = Enum.Operations.CashReceipt;
	|Voucher FormVoucher show filled ( Voucher ) and Object.Method = Enum.Operations.CashExpense;
	|Reference ReferenceDate PaymentContent show
	|	inlist ( Object.Method, Enum.Operations.BankExpense, Enum.Operations.BankReceipt );
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Object.Operation.IsEmpty () ) then
		uploadOperation ();
	endif; 
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	settings = Logins.Settings ( "Company" );
	Object.Company = settings.Company;
	
EndProcedure 

&AtServer
Procedure uploadOperation ()
	
	readOperation ();
	Object.Simple = Operation.Simple;
	Object.Method = Operation.Operation;
	
EndProcedure

&AtServer
Procedure defineCopy ()
	
	CopyOf = Parameters.CopyingValue;

EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	if ( Object.Simple ) then
		initTableRow ();
		if ( Object.Ref.IsEmpty () ) then
			EntryForm.FixAccounts ( ThisObject );
		endif; 
		initRecord ();
	endif; 
	
EndProcedure

&AtClient
Procedure initTableRow ()
	
	records = Object.Records;
	if ( records.Count () = 0 ) then
		records.Add ();
	endif; 
	TableRow = records [ 0 ];

EndProcedure 

&AtClient
Procedure initRecord ()
	
	EntryForm.InitAccounts ( ThisObject );
	EntryForm.EnableAnalytics ( ThisObject );
	EntryForm.DisableCurrency ( ThisObject, "Dr" );
	EntryForm.DisableCurrency ( ThisObject, "Cr" );
	
EndProcedure 

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	checkAccounts ( CheckedAttributes );
	
EndProcedure

&AtServer
Procedure checkAccounts ( CheckedAttributes )
	
	if ( Object.Simple ) then
		CheckedAttributes.Add ( "AccountDr" );
		CheckedAttributes.Add ( "AccountCr" );
	endif; 
	
EndProcedure 

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	PettyCash.Read ( ThisObject );
	rememberOperation ();
	Appearance.Apply ( ThisObject, "Voucher" );
	Appearance.Apply ( ThisObject, "Receipt" );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

&AtClient
Procedure OperationOnChange ( Item )
	
	applyOperation ();
	
EndProcedure

&AtClient
Procedure applyOperation ()
	
	applyOperationType ();
	enableWarning ( ThisObject );
	if ( Object.Operation.IsEmpty () ) then
		return;
	endif;
	applySimple ();
	
EndProcedure 

&AtServer
Procedure applyOperationType ()
	
	uploadOperation ();
	resetReference ();
	Appearance.Apply ( ThisObject, "Object.Method" );
	if ( Object.Operation.IsEmpty () ) then
		Appearance.Apply ( ThisObject, "Operation.AccountDr" );
		Appearance.Apply ( ThisObject, "Operation.AccountCr" );
	endif;
	
EndProcedure 

&AtServer
Procedure resetReference ()
	
	type = Object.Method;
	if ( type = Enums.Operations.BankExpense
		or type = Enums.Operations.BankReceipt ) then
		return;
	endif; 
	Object.Reference = undefined;
	Object.ReferenceDate = undefined;
	
EndProcedure 

&AtClient
Procedure applySimple ()
	
	if ( Object.Simple
		and Object.Records.Count () > 1 ) then
		Output.ApplySimplicityConfirmation ( ThisObject );
	else
		commitSimplicity ();
	endif; 
	
EndProcedure

&AtClient
Procedure ApplySimplicityConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		leave1row ();
		calcTotals ();
	else
		Object.Simple = false;
	endif; 
	commitSimplicity ();
	
EndProcedure 

&AtClient
Procedure commitSimplicity ()
	
	if ( Object.Simple ) then
		initTableRow ();
		EntryForm.FixAccounts ( ThisObject );
		initRecord ();
	endif; 
	Appearance.Apply ( ThisObject, "Object.Simple" );
	
EndProcedure 

&AtClient
Procedure leave1row ()
	
	records = Object.Records;
	i = records.Count () - 1;
	while ( i > 0 ) do
		records.Delete ( i );
		i = i - 1;
	enddo; 
	
EndProcedure 

&AtClient
Procedure NewVoucher ( Command )
	
	notifyNew = Object.Ref.IsEmpty ();
	createVoucher ();
	PettyCash.Open ( ThisObject, notifyNew );
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	passCopy ( CurrentObject );

EndProcedure

&AtServer
Procedure passCopy ( CurrentObject )
	
	if ( CurrentObject.IsNew () ) then
		CurrentObject.AdditionalProperties.Insert ( Enum.AdditionalPropertiesCopyOf (), CopyOf ); 
	endif;

EndProcedure

&AtServer
Procedure createVoucher ()
	
	PettyCash.NewReference ( ThisObject );
	Appearance.Apply ( ThisObject, "Voucher" );
	
EndProcedure 

&AtClient
Procedure NewReceipt ( Command )
	
	notifyNew = Object.Ref.IsEmpty ();
	createReceipt ();
	PettyCash.Open ( ThisObject, notifyNew );
	
EndProcedure

&AtServer
Procedure createReceipt ()
	
	PettyCash.NewReference ( ThisObject );
	Appearance.Apply ( ThisObject, "Receipt" );
	
EndProcedure 

&AtClient
Procedure CashDocumentClick ( Item, StandardProcessing )
	
	PettyCash.ClickProcessing ( ThisObject, StandardProcessing );
	
EndProcedure

&AtClient
Procedure SimpleOnChange ( Item )
	
	applySimple ();
	
EndProcedure

// *****************************************
// *********** Group Record

&AtClient
Procedure AccountDrOnChange ( Item )
	
	EntryForm.AccountDrOnChange ( ThisObject );
	
EndProcedure

&AtClient
Procedure DimDr1StartChoice ( Item, ChoiceData, StandardProcessing )
	
	EntryForm.DimDr1StartChoice ( ThisObject, Item, ChoiceData, StandardProcessing );
	
EndProcedure

&AtClient
Procedure DimDr1OnChange ( Item )
	
	EntryForm.DimDr1OnChange ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure DimDr2StartChoice ( Item, ChoiceData, StandardProcessing )
	
	EntryForm.DimDr2StartChoice ( ThisObject, Item, ChoiceData, StandardProcessing );
	
EndProcedure

&AtClient
Procedure DimDr2OnChange ( Item )
	
	EntryForm.DimDr2OnChange ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure DimDr3StartChoice ( Item, ChoiceData, StandardProcessing )
	
	EntryForm.DimDr3StartChoice ( ThisObject, Item, ChoiceData, StandardProcessing );
	
EndProcedure

&AtClient
Procedure CurrencyDrOnChange ( Item )
	
	EntryForm.CurrencyDrOnChange ( ThisObject, Item );

EndProcedure

&AtClient
Procedure RateDrOnChange ( Item )
	
	EntryForm.RateDrOnChange ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure FactorDrOnChange ( Item )
	
	EntryForm.FactorDrOnChange ( ThisObject, Item );

EndProcedure

&AtClient
Procedure CurrencyAmountDrOnChange ( Item )
	
	EntryForm.CurrencyAmountDrOnChange ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure AccountCrOnChange ( Item )
	
	EntryForm.AccountCrOnChange ( ThisObject );
	
EndProcedure

&AtClient
Procedure DimCr1StartChoice ( Item, ChoiceData, StandardProcessing )
	
	EntryForm.DimCr1StartChoice ( ThisObject, Item, ChoiceData, StandardProcessing );
	
EndProcedure

&AtClient
Procedure DimCr1OnChange ( Item )
	
	EntryForm.DimCr1OnChange ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure DimCr2StartChoice ( Item, ChoiceData, StandardProcessing )

	EntryForm.DimCr2StartChoice ( ThisObject, Item, ChoiceData, StandardProcessing );
	
EndProcedure

&AtClient
Procedure DimCr2OnChange ( Item )
	
	EntryForm.DimCr2OnChange ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure DimCr3StartChoice ( Item, ChoiceData, StandardProcessing )
	
	EntryForm.DimCr3StartChoice ( ThisObject, Item, ChoiceData, StandardProcessing );
	
EndProcedure

&AtClient
Procedure CurrencyCrOnChange ( Item )
	
	EntryForm.CurrencyCrOnChange ( ThisObject, Item );

EndProcedure

&AtClient
Procedure RateCrOnChange ( Item )
	
	EntryForm.RateCrOnChange ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure FactorCrOnChange ( Item )
	
	EntryForm.FactorCrOnChange ( ThisObject, Item );

EndProcedure

&AtClient
Procedure CurrencyAmountCrOnChange ( Item )
	
	EntryForm.CurrencyAmountCrOnChange ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure AmountOnChange ( Item )
	
	EntryForm.AmountOnChange ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure ContentOnChange ( Item )
	
	setMemo ( false );
	
EndProcedure

&AtClient
Procedure setMemo ( CheckEmpty )
	
	if ( CheckEmpty
		and TableRow.Content = "" ) then
		return;
	endif;
	Object.Memo = TableRow.Content;
	
EndProcedure 

// *****************************************
// *********** Group Records

&AtClient
Procedure Edit ( Command )
	
	editRow ();
	
EndProcedure

&AtClient
Procedure editRow ( NewRow = false )
	
	if ( TableRow = undefined ) then
		return;
	endif; 
	p = new Structure ();
	p.Insert ( "Company", Object.Company );
	p.Insert ( "DisableDr", not Operation.AccountDr.IsEmpty () );
	p.Insert ( "DisableCr", not Operation.AccountCr.IsEmpty () );
	p.Insert ( "NewRow", NewRow );
	OpenForm ( "Document.Entry.Form.Record", p, ThisObject, , , , new NotifyDescription ( "RecordClosed", ThisObject, NewRow ) );
	
EndProcedure 

&AtClient
Procedure RecordClosed ( Result, NewRow ) export
	
	if ( TypeOf ( Result ) = Type ( "Structure" ) ) then
		command = Result.Operation;
		if ( command = Enum.ChoiceOperationsEntryRecord () ) then
			loadRow ( Result );
		elsif ( command = Enum.ChoiceOperationsEntrySaveAndNew () ) then
			loadRow ( Result );
			newRow ( Items.Records, false );
		endif; 
	elsif ( NewRow ) then
		Object.Records.Delete ( TableRow );
		calcTotals ();
	endif; 

EndProcedure 

&AtClient
Procedure loadRow ( Params )
	
	FillPropertyValues ( TableRow, Params.Value );
	if ( Object.Records.Count () = 1 ) then
		setMemo ( true );
	endif;
	calcTotals ();
	
EndProcedure

&AtClient
Procedure calcTotals ()
	
	Object.Amount = Object.Records.Total ( "Amount" );
	
EndProcedure 

&AtClient
Procedure newRow ( Item, Clone )
	
	Forms.NewRow ( ThisObject, Item, Clone );
	if ( not Clone ) then
		TableRow.Content = Object.Memo;
	endif; 
	editRow ( true );
	
EndProcedure 

&AtClient
Procedure RecordsOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure RecordsAfterDeleteRow ( Item )
	
	calcTotals ();
	
EndProcedure

&AtClient
Procedure RecordsBeforeRowChange ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure RecordsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	editRow ();

EndProcedure

&AtClient
Procedure RecordsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	newRow ( Item, Clone );
	
EndProcedure
