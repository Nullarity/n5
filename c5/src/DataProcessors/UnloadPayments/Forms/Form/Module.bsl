&AtClient
var TableRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )

	init ();
	setAccount ();
	setApplication ();
	loadPayments ();
	calcTotal ( ThisObject );

EndProcedure

&AtServer
Procedure init ()
	
	Object.Company = Logins.Settings ( "Company" ).Company;
	
EndProcedure

&AtServer
Procedure setAccount ()

	data = DF.Values ( Object.Company, "BankAccount, BankAccount.Unloading" );
	Object.Account = data.BankAccount;
	Object.Path = data.BankAccountUnloading;

EndProcedure

&AtServer
Procedure setApplication ()
	
	Object.Application = DF.Pick ( Object.Account, "Application" );
	
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

// *****************************************
// *********** Group Form

&AtClient
Procedure CompanyOnChange ( Item )
	
	applyCompany ();
	
EndProcedure

&AtServer
Procedure applyCompany ()
	
	setAccount ();
	setApplication ();
	loadPayments ();
	calcTotal ( ThisObject );
	
EndProcedure

&AtClient
Procedure AccountOnChange ( Item )
	
	applyAccount ();
	
EndProcedure

&AtServer
Procedure applyAccount ()
	
	setApplication ();
	loadPayments ();
	calcTotal ( ThisObject );
	
EndProcedure

&AtClient
Procedure ApplicationOnChange ( Item )
	
	Object.Path = "";
	
EndProcedure

&AtClient
Procedure PathStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	BankingForm.ChooseUnloading ( Object.Application, Item );
	
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
		p.Insert ( "Orders", orders );
		p.Insert ( "Application", Object.Application );
		p.Insert ( "JobKey", UUID );
		File1 = PutToTempStorage ( undefined, UUID );
		p.Insert ( "File1", File1 );
		File2 = PutToTempStorage ( undefined, UUID );
		p.Insert ( "File2", File2 );
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
		OutputCont.EmptyUploadList ();
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
	files = GetFromTempStorage ( FilesDescriptor );
	BeginGettingFiles ( new NotifyDescription ( "FilesWritten", ThisObject ), files, , false );

EndProcedure

&AtClient
Procedure FilesWritten ( Files, Params ) export 

	callback = new NotifyDescription ( "SuccessClosed", ThisObject, Files );
	OpenForm ( "DataProcessor.UnloadPayments.Form.Success", , ThisObject, , , , callback );

EndProcedure

&AtClient
Procedure SuccessClosed ( Result, Files ) export
	
	if ( Result = undefined
		or Result = true ) then
		for each file in Files do
			BeginDeletingFiles ( , file.FullName );
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
