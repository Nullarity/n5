&AtClient
var TableRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	filterByPeriod ();
	setTitle ();
	filterByAccount ();
	fillAllowedDocuments ();
	
EndProcedure

&AtServer
Procedure init ()
	
	LogAvailable = AccessRight ( "View", Metadata.Documents.LoadPayments );
	value = CommonSettingsStorage.Load ( Enum.SettingsBankPeriod () );
	if ( value = undefined ) then
		Period.Variant = StandardPeriodVariant.Month;
	else
		Period = value;
		extendPeriod ( value );
	endif; 
	
EndProcedure 

&AtServer
Procedure extendPeriod ( NewPeriod )
	
	set = Items.Period.ChoiceList;
	item = set.FindByValue ( NewPeriod );
	if ( item = undefined ) then
		set.Add ( NewPeriod, PeriodPresentation ( NewPeriod.StartDate, NewPeriod.EndDate, "FP=true" ) );
	endif; 

EndProcedure 

&AtServer
Procedure readAppearance ()
	
	rules = new Array ();
	rules.Add ( "
	|DimensionFilter show HasDimensions;
	|" );
	Appearance.Read ( ThisObject, rules );
	
EndProcedure

&AtServer
Procedure filterByPeriod ()
	
	startDate = Period.StartDate;
	endDate = Period.EndDate;
	DC.SetParameter ( List, "DateStart", startDate, true );
	DC.SetParameter ( List, "DateEnd", endDate, true );
	DC.SetParameter ( Balances, "DateStart", startDate, true );
	balance = Min ( endDate, EndOfDay ( CurrentSessionDate () ) );
	DC.SetParameter ( Balances, "DateEnd", balance, true );
	if ( LogAvailable ) then
		Items.Log.Period = new StandardPeriod ( startDate, endDate );
	endif;
	
EndProcedure 

&AtServer
Procedure setTitle ()
	
	Title = Metadata.InformationRegisters.Bank.Synonym + ", " + Format ( Period.StartDate, "DLF=D" )
	+ " - "
	+ Format ( Period.EndDate, "DLF=D" );
	
EndProcedure

&AtServer
Procedure filterByAccount ()
	
	clearCurrencyFilter ();
	set = not AccountFilter.IsEmpty ();
	DC.ChangeFilter ( List, "AccountCode", AccountFilter, set);
	DC.ChangeFilter ( Balances, "Account", AccountFilter, set );
	DC.ChangeFilter ( Balances, "Account.Class", Enums.Accounts.Bank, not set );
	if ( LogAvailable ) then
		DC.ChangeFilter ( Log, "BankAccount", AccountFilter, set );
	endif;
	
EndProcedure

&AtServer
Procedure fillAllowedDocuments ()
	
	types = Metadata.DefinedTypes.Bank.Type.Types ();
	addDocuments ( types );
	addOperations ();
	
EndProcedure 

&AtServer
Procedure addDocuments ( Types )
	
	entry = Type ( "DocumentRef.Entry" );
	for each type in Types do
		if ( type = entry ) then
			continue;
		endif; 
		meta = Metadata.FindByType ( type );
		if ( AccessRight ( "Insert", meta ) ) then
			AllowedDocuments.Add ( meta.Name, meta.Presentation () );
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Procedure addOperations ()
	
	if ( not AccessRight ( "Insert", Metadata.Documents.Entry ) ) then
		return;
	endif; 
	for each operation in getOperations () do
		AllowedDocuments.Add ( operation.Ref, operation.Description );
	enddo; 

EndProcedure

&AtServer
Function getOperations ()
	
	s = "
	|select top 15 Operations.Ref as Ref, Operations.Description as Description
	|from Catalog.Operations as Operations
	|where not Operations.DeletionMark
	|and Operations.Operation in ( value ( Enum.Operations.BankExpense ), value ( Enum.Operations.BankReceipt ) )
	|order by Operations.Description
	|";
	q = new Query ( s );
	return q.Execute ().Unload ();
	
EndFunction 

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )

	if ( EventName = Enum.MessageBankingAppLoaded () ) then
		update ();
	endif;

EndProcedure

&AtServer
Procedure update ()
	
	Items.List.Refresh ();
	Items.Balances.Refresh ();
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure PeriodOnChange ( Item )
	
	if ( customPeriod () ) then
		choosePeriod ();
	else
		applyPeriod ();
	endif; 
	
EndProcedure

&AtClient
Function customPeriod ()
	
	return Period.Variant = StandardPeriodVariant.Custom
	and Period.StartDate = Period.EndDate
	and Period.StartDate = Date ( 1, 1, 1 );
	
EndFunction 

&AtClient
Procedure choosePeriod ()
	
	dialog = new StandardPeriodEditDialog ();
	dialog.Period = new StandardPeriod ( Period.StartDate, Period.EndDate );
	dialog.Show ( new NotifyDescription ( "PeriodChanged", ThisObject ) );
	
EndProcedure 

&AtClient
Procedure PeriodChanged ( NewPeriod, Params ) export
	
	if ( NewPeriod = undefined ) then
		return;
	endif; 
	Period = NewPeriod;
	applyPeriod ();
	
EndProcedure 

&AtServer
Procedure applyPeriod ()
	
	extendPeriod ( Period );
	filterByPeriod ();
	setTitle ();
	LoginsSrv.SaveSettings ( Enum.SettingsBankPeriod (), , Period );
	
EndProcedure 

&AtClient
Procedure AccountFilterOnChange ( Item )
	
	applyAccountFilter ();
	
EndProcedure

&AtServer
Procedure applyAccountFilter ()
	
	getDimensions ();
	if ( not HasDimensions ) then
		DimensionFilter = undefined;
		filterByDimension ();
	endif;
	filterByAccount ();
	Appearance.Apply ( ThisObject, "HasDimensions" );
	
EndProcedure

&AtServer
Procedure getDimensions ()
	
	if ( AccountFilter.IsEmpty () ) then
		HasDimensions = false;
	else
		s = "
		|select allowed top 1 1
		|from ChartOfAccounts.General.ExtDimensionTypes as Dimensions
		|where Dimensions.Ref = &Account";
		q = new Query ( s );
		q.SetParameter ( "Account", AccountFilter );
		HasDimensions = not q.Execute ().IsEmpty ();
	endif;
	
EndProcedure

&AtServer
Procedure clearCurrencyFilter () 

	CurrencyFilter = undefined;
	DC.ChangeFilter ( List, "Currency", undefined, false );
	DC.ChangeFilter ( Balances, "Dim1", undefined, false );
	if ( LogAvailable ) then
		DC.ChangeFilter ( Log, "BankAccount.Currency", undefined, false );
	endif;

EndProcedure

&AtClient
Procedure DimensionFilterOnChange ( Item )
	
	filterByDimension ();

EndProcedure

&AtServer
Procedure filterByDimension ()
	
	clearCurrencyFilter ();
	setup = not DimensionFilter.IsEmpty ();
	DC.ChangeFilter ( List, "Account", DimensionFilter, setup );
	DC.ChangeFilter ( Balances, "ExtDimension1", DimensionFilter, setup );
	
EndProcedure

&AtClient
Procedure CurrencyFilterOnChange ( Item )
	
	filterByCurrency ();
	
EndProcedure

&AtServer
Procedure filterByCurrency ()
	
	clearAccountFilter ();
	setup = not CurrencyFilter.IsEmpty ();
	DC.ChangeFilter ( List, "Currency", CurrencyFilter, setup );
	if ( setup ) then
		DC.ChangeFilter ( Balances, "Dim1", getAccounts (), true );
	else
		DC.ChangeFilter ( Balances, "Dim1", undefined, false );
	endif;
	if ( LogAvailable ) then
		DC.ChangeFilter ( Log, "BankAccount.Currency", CurrencyFilter, setup );
	endif;
	
EndProcedure

&AtServer
Procedure clearAccountFilter () 

	AccountFilter = undefined;
	DC.ChangeFilter ( List, "Account", undefined, false );
	if ( LogAvailable ) then
		DC.ChangeFilter ( Log, "BankAccount", undefined, false );
	endif;

EndProcedure

&AtServer
Function getAccounts () 

	s = "
	|select Accounts.Ref as Ref
	|from Catalog.BankAccounts as Accounts
	|where not Accounts.DeletionMark
	|and Accounts.Currency = &Currency
	|";
	q = new Query ( s );
	q.SetParameter ( "Currency", CurrencyFilter );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );

EndFunction

// *****************************************
// *********** List

&AtClient
Procedure Post ( Command )
	
	processDocuments ( Enum.DocumentActionsPost (), Items.List.SelectedRows );
	
EndProcedure

&AtClient
Procedure processDocuments ( Action, Keys )
	
	for each item in Keys do
		try
			writeDocument ( item, Action );
		except
			ShowErrorInfo ( ErrorInfo () );
			continue;
		endtry;
		NotifyChanged ( item );
	enddo; 
	
EndProcedure

&AtServerNoContext
Procedure writeDocument ( val Key, val Action )
	
	obj = Key.Document.GetObject ();
	if ( Action = Enum.DocumentActionsPost () ) then
		if ( not obj.CheckFilling () ) then
			raise Output.OperationError ();
		endif;
		obj.Write ( DocumentWriteMode.Posting );
	elsif ( Action = Enum.DocumentActionsUnpost () ) then
		obj.Write ( DocumentWriteMode.UndoPosting );
	elsif ( Action = Enum.DocumentActionsDelete () ) then
		obj.SetDeletionMark ( true );
	else
		obj.SetDeletionMark ( false );
	endif; 
	
EndProcedure 

&AtClient
Procedure Unpost ( Command )
	
	processDocuments ( Enum.DocumentActionsUnpost (), Items.List.SelectedRows );
	
EndProcedure

&AtClient
Procedure CreateDocument ( Command )
	
	showMenu ( Items.ListCommandBar );
	
EndProcedure

&AtClient
Procedure showMenu ( Control )

	if ( AllowedDocuments.Count () = 0 ) then
		Output.ListIsReadonly ();
	else
		ShowChooseFromMenu ( new NotifyDescription ( "MenuSelected", ThisObject ), AllowedDocuments, Control );
	endif; 
	
EndProcedure 

&AtClient
Procedure MenuSelected ( Item, Params ) export
	
	if ( Item = undefined ) then
		return;
	endif; 
	value = Item.Value;
	if ( TypeOf ( value ) = Type ( "CatalogRef.Operations" ) ) then
		p = new Structure ( "FillingValues", new Structure ( "Operation", value ) );
		OpenForm ( "Document.Entry.ObjectForm", p, Items.List );
	else
		OpenForm ( "Document." + value + ".ObjectForm", , Items.List );
	endif; 
	
EndProcedure 

&AtClient
Procedure DocumentClosed ( Result, Ref ) export
	
	#if ( WebClient ) then
		Items.List.Refresh ();
	#else
		for each k in getKeys ( Ref ) do
			NotifyChanged ( k );
		enddo;
	#endif
	
EndProcedure 

&AtServerNoContext
Function getKeys ( val Document )
	
	s = "select Record from InformationRegister.Bank where Document = &Ref";
	q = new Query ( s );
	q.SetParameter ( "Ref", Document );
	keys = q.Execute ().Unload ().UnloadColumn ( "Record" );
	set = new Array ();
	for each id in keys do
		k = new ( "InformationRegisterRecordKey.Bank", new Structure ( "Document, Record", Document, id ) );
		set.Add ( k );
	enddo;
	return set;
	
EndFunction

&AtClient
Procedure ShowRecords ( Command )
	
	if ( TableRow = undefined ) then
		return;
	endif; 
	openRecords ();
	
EndProcedure

&AtClient
Procedure openRecords ()
	
	p = new Structure ( "Document", TableRow.Document );
	OpenForm ( "Report.Records.Form", p );
	
EndProcedure 

&AtClient
Procedure ListNewWriteProcessing ( NewObject, Source, StandardProcessing )
	
	activateDocument ( NewObject );
	
EndProcedure

&AtClient
Procedure activateDocument ( Document )
	
	set = getKeys ( Document );
	if ( set.Count () = 0 ) then
		return;
	endif;
	#if ( WebClient ) then
		Items.List.Refresh ();
	#else
		for each k in set do
			NotifyChanged ( k );
		enddo;
	#endif
	Items.List.CurrentRow = set [ 0 ];
	
EndProcedure 

&AtClient
Procedure ListOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	if ( Clone ) then
		openDocument ( TableRow.Document, true );
	else
		showMenu ( Item );
	endif; 
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange ( Item, Cancel )
	
	Cancel = true;
	editDocument ();

EndProcedure

&AtClient
Procedure editDocument ()
	
	if ( TableRow = undefined ) then
		return;
	endif; 
	openDocument ( TableRow.Document, false );
	
EndProcedure 

&AtClient
Procedure openDocument ( Ref, Copying )
	
	type = TypeOf ( Ref );
	if ( type = Type ( "DocumentRef.Payment" ) ) then
		name = "Payment";
	elsif ( type = Type ( "DocumentRef.VendorPayment" ) ) then
		name = "VendorPayment";
	elsif ( type = Type ( "DocumentRef.PayEmployees" ) ) then
		name = "PayEmployees";
	else
		name = "Entry";
	endif; 
	form = "Document." + name + ".ObjectForm";
	if ( Copying ) then
		OpenForm ( form, new Structure ( "CopyingValue", Ref ), Items.List );
	else
		callback = new NotifyDescription ( "DocumentClosed", ThisObject, Ref );
		OpenForm ( form, new Structure ( "Key", Ref ), Items.List, , , , callback );
	endif; 
	
EndProcedure 

&AtClient
Procedure ListBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	confirm ();
	
EndProcedure

&AtClient
Procedure confirm ()
	
	info = deletionInfo ();
	msg = new Structure ( "Object", info.Object );
	if ( info.Restoration ) then
		Output.Undelete ( ThisObject, info, msg, "ObjectsDeletion" );
	else
		Output.MarkForDeletion ( ThisObject, info, msg, "ObjectsDeletion" );
	endif; 
	
EndProcedure 

&AtClient
Function deletionInfo ()
	
	delete = new Array ();
	restore = new Array ();
	listControl = Items.List;
	for each row in Items.List.SelectedRows do
		data = listControl.RowData ( row );
		if ( data.Status = 2 ) then
			restore.Add ( row );
		else
			delete.Add ( row );
		endif; 
	enddo; 
	if ( restore.Count () > 0 ) then
		keys = restore;
		restoration = true;
	else
		keys = delete;
		restoration = false;
	endif; 
	info = new Structure ();
	info.Insert ( "Restoration", restoration );
	info.Insert ( "Keys", keys );
	info.Insert ( "Object", listControl.RowData ( keys [ 0 ] ).Document );
	return info;
	
EndFunction

&AtClient
Procedure ObjectsDeletion ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	if ( Params.Restoration ) then
		processDocuments ( Enum.DocumentActionsUndelete (), Params.Keys );
	else
		processDocuments ( Enum.DocumentActionsDelete (), Params.Keys );
	endif; 
	
EndProcedure 
