&AtClient
var TableRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )

	init ();
	loadAccount ();
	loadPayments ();
	calcTotal ( ThisObject );

EndProcedure

&AtServer
Procedure init ()
	
	Object.Company = Logins.Settings ( "Company" ).Company;
	
EndProcedure

&AtServer
Procedure loadAccount ()

	account = Object.Account;
	if ( account.IsEmpty () ) then
		data = DF.Values ( Object.Company, "
		|BankAccount,
		|BankAccount.Bank.Application as Application,
		|BankAccount.Bank.Application.Unloading as Unloading" );
		Object.Account = data.BankAccount;
	else
		data = DF.Values ( account, "
		|Bank.Application as Application,
		|Bank.Application.Unloading as Unloading" );
	endif;
	Object.BankingApp = data.Application;
	setFiles ( data );

EndProcedure

&AtServer
Procedure setFiles ( Data )
	
	app = DF.Pick ( Object.BankingApp, "Application" );
	if ( app = PredefinedValue ( "Enum.Banks.Mobias" ) ) then
		filePayments = "Plat.dbf";
	elsif ( app = PredefinedValue ( "Enum.Banks.MAIB" ) ) then
		date = CurrentSessionDate ();
		month = Mid ( "123456789ABC", Month ( date ), 1 );
		filePayments = "IDOC" + Format ( date, "DF='dd'" ) + month + ".dbf";
		fileSalary = "PS" + Format ( date, "DF=yyMMdd" )
			+ Right ( TrimR ( DF.Pick ( Object.Account, "Bank.Code", "" ) ), 3 )
			+ DF.Pick ( Object.BankingApp, "Globus", "" )
			+ ".001";
	elsif ( app = PredefinedValue ( "Enum.Banks.FinComPay" )
	 	or app = PredefinedValue ( "Enum.Banks.Comert" ) ) then
		filePayments = "ExportPayments.xml";
	elsif ( app = PredefinedValue ( "Enum.Banks.EuroCreditBank" ) ) then
		filePayments = "ExportPayments";
	elsif ( app = PredefinedValue ( "Enum.Banks.Eximbank" ) ) then
		filePayments = "ExportPayments.txt";
		fileSalary = "salary.csv";
	else
		filePayments = "ExportPayments.txt";
	endif;
	folder = Data.Unloading + GetClientPathSeparator ();
	Object.Path = folder + filePayments;
	Object.PathSalary = folder + ? ( fileSalary = undefined, "", fileSalary );
	
EndProcedure

&AtServer
Procedure loadPayments ()
	
	table = FillerSrv.GetData ( fillingParams ( ThisObject ) );
	fillTable ( Table, true );
	
EndProcedure

&AtClientAtServerNoContext
Function fillingParams ( Form )
	
	p = Filler.GetParams ();
	p.ProposeClearing = false;
	p.Report = "PaymentOrdersFilling";
	p.Filters = getFilters ( Form );
	return p;
	
EndFunction

&AtClientAtServerNoContext
Function getFilters ( Form )
	
	filters = new Array ();
	object = Form.Object;
	filters.Add ( DC.CreateFilter ( "Company", object.Company ) );
	filters.Add ( DC.CreateFilter ( "BankAccount", object.Account ) );
	return filters;
	
EndFunction

&AtServer
Procedure fillTable ( Table, Clean )
	
	if ( Clean ) then
		Object.PaymentOrders.Load ( Table );
	else
		orders = Object.PaymentOrders;
		for each row in table do
			 FillPropertyValues ( orders.Add (), row );
		enddo;
	endif;
	
EndProcedure

&AtClientAtServerNoContext
Procedure calcTotal ( Form )
	
	amount = 0;
	rows = Form.Object.PaymentOrders.FindRows ( new Structure ( "Unload", true ) );
	for each row in rows do
		amount = amount + row.Amount;
	enddo;
	Form.Total = amount;
	
EndProcedure

&AtClient
Procedure OnOpen ( Cancel )

	LocalFiles.Prepare ();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )

	checkSalary ( CheckedAttributes );

EndProcedure

&AtServer
Procedure checkSalary ( CheckedAttributes )
	
	for each row in Object.PaymentOrders do
		if ( row.Salary ) then
			CheckedAttributes.Add ( "PathSalary" );
			break;
		endif;
	enddo;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure CompanyOnChange ( Item )
	
	applyCompany ();
	
EndProcedure

&AtServer
Procedure applyCompany ()
	
	loadAccount ();
	loadPayments ();
	calcTotal ( ThisObject );
	
EndProcedure

&AtClient
Procedure AccountOnChange ( Item )
	
	applyAccount ();
	
EndProcedure

&AtServer
Procedure applyAccount ()
	
	loadAccount ();
	loadPayments ();
	calcTotal ( ThisObject );
	
EndProcedure

&AtClient
Procedure BankingAppOnChange ( Item )
	
	resetFiles ();
	
EndProcedure

&AtClient
Procedure resetFiles ()
	
	Object.Path = "";
	Object.PathSalary = "";
	
EndProcedure

&AtClient
Procedure PathStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	BankingForm.ChooseFile ( Object.BankingApp, Item );
	
EndProcedure

&AtClient
Procedure PathSalaryStartChoice ( Item, ChoiceData, StandardProcessing )

	StandardProcessing = false;
	BankingForm.ChooseSalaryFile ( Object.BankingApp, Item );

EndProcedure

&AtClient
Procedure Unload ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif;
	if ( run () ) then
		Progress.Open ( UUID, ThisObject, new NotifyDescription ( "Uploading", ThisObject ), true );
	endif;
	
EndProcedure

&AtServer
Function run () 

	orders = getOrders ();
	if ( orders = undefined ) then
		return false;
	else
		p = new Structure ();
		p.Insert ( "Path", Object.Path );
		p.Insert ( "PathSalary", Object.PathSalary );
		p.Insert ( "Orders", orders );
		p.Insert ( "BankingApp", Object.BankingApp );
		p.Insert ( "JobKey", UUID );
		File1 = PutToTempStorage ( undefined, UUID );
		p.Insert ( "File1", File1 );
		File2 = PutToTempStorage ( undefined, UUID );
		p.Insert ( "File2", File2 );
		File3 = PutToTempStorage ( undefined, UUID );
		p.Insert ( "File3", File3 );
		FilesDescriptor = PutToTempStorage ( undefined, UUID );
		p.Insert ( "FilesDescriptor", FilesDescriptor );
		args = new Array ();
		args.Add ( p );
		Jobs.Run ( "BankingApp.Unload", args, UUID, , TesterCache.Testing () );
		return true;
	endif;

EndFunction

&AtServer
Function getOrders () 

	rows = Object.PaymentOrders.Unload ( new Structure ( "Unload", true ), "PaymentOrder" );
	if ( rows.Count () = 0 ) then
		Output.EmptyUploadList ();
		return undefined;
	else
		return rows.UnloadColumn ( "PaymentOrder" );
	endif;
	
EndFunction

&AtClient
Procedure Uploading ( Result, Params ) export
	
	if ( not Result ) then
		return;
	endif;
	Notify ( Enum.MessageBankingAppUnloaded () );
	fetchFiles ();

EndProcedure

&AtClient
Procedure fetchFiles ()
	
	list = GetFromTempStorage ( FilesDescriptor );
	folders = new Map ();
	i = 1;
	for each file in list do
		folder = FileSystem.GetFolder ( file );
		if ( folders [ folder ] = undefined ) then
			folders [ folder ] = new Array ();
		endif;
		folders [ folder ].Add ( new TransferableFileDescription ( file, ThisObject [ "File" + i ] ) );
		i = i + 1;
	enddo;
	callback = new NotifyDescription ( "FilesWritten", ThisObject, folders );
	i = folders.Count ();
	for each location in folders do
		lastFolder = ( i = 1 );
		BeginGetFilesFromServer ( ? ( lastFolder, callback, undefined ), location.Value, location.Key );
		i = i - 1;
	enddo;
	
EndProcedure

&AtClient
Procedure FilesWritten ( Files, Folders ) export 

	callback = new NotifyDescription ( "SuccessClosed", ThisObject, Folders );
	OpenForm ( "DataProcessor.UnloadPayments.Form.Success", , ThisObject, , , , callback );

EndProcedure

&AtClient
Procedure SuccessClosed ( Result, Folders ) export
	
	if ( Result = undefined
		or Result = true ) then
		for each folder in Folders do
			for each file in folder.Value do
				BeginDeletingFiles ( , file.Name );
			enddo;
		enddo;
	endif;
	
EndProcedure

// *****************************************
// *********** Table PaymentOrders

&AtClient
Procedure MarkAll ( Command )
	
	mark ( true );
	calcTotal ( ThisObject );
	
EndProcedure

&AtClient
Procedure mark ( Flag ) 

	for each row in Object.PaymentOrders do
		row.Unload = Flag;
	enddo;

EndProcedure

&AtClient
Procedure UnmarkAll ( Command )
	
	mark ( false );
	calcTotal ( ThisObject );
		
EndProcedure

&AtClient
Procedure Fill ( Command )
	
	Filler.Open ( fillingParams ( ThisObject ), ThisObject );
	
EndProcedure

&AtClient
Procedure Filling ( Result, Params ) export
	
	if ( not fillOrders ( Result ) ) then
		Output.FillingDataNotFound ();
	endif;
	
EndProcedure 

&AtServer
Function fillOrders ( val Result )
	
	table = Filler.Fetch ( Result );
	if ( table = undefined ) then
		return false;
	endif;
	filltable ( table, Result.ClearTable );
	calcTotal ( ThisObject );
	return true;
	
EndFunction

&AtClient
Procedure PaymentOrdersOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure PaymentOrdersSelection ( Item, RowSelected, Field, StandardProcessing )

	StandardProcessing = false;
	openPayment ();

EndProcedure

&AtClient
Procedure openPayment ()

	callback = new NotifyDescription ( "PaymentClosed", ThisObject );
	OpenForm ( "Document.PaymentOrder.ObjectForm", new Structure ( "Key", TableRow.PaymentOrder ),
		ThisObject, , , , callback, FormWindowOpeningMode.LockOwnerWindow );

EndProcedure

&AtClient
Procedure PaymentClosed ( Result, Params ) export
	
	updateAmount ();
	calcTotal ( ThisObject );
	
EndProcedure

&AtClient
Procedure updateAmount ()
	
	TableRow.Amount = DF.Pick ( TableRow.PaymentOrder, "Amount" );
	
EndProcedure

&AtClient
Procedure PaymentOrdersUploadOnChange ( Item )

	calcTotal ( ThisObject );

EndProcedure
