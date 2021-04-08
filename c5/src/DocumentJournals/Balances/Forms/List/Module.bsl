&AtClient
var TableRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	prepare ();
	toggleWarning ();
	filterByCompany ();
	filterByDate ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|GroupInfo show empty ( CompanyFilter );
	|List BalanceDate show filled ( CompanyFilter )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure init ()
	
	settings = Logins.Settings ( "Company" );
	CompanyFilter = settings.Company;	
	
EndProcedure 

&AtServer
Procedure prepare ()
	
	BalanceDate = getBalanceDate ();
	OldDate = BalanceDate;

EndProcedure 

&AtServer
Function getBalanceDate ()
	
	if ( CompanyFilter.IsEmpty () ) then
		return undefined;
	endif;
	s = "
	|select top 1 Balances.Date as Date
	|from DocumentJournal.Balances as Balances
	|where Balances.Company = &Company
	|";
	q = new Query ( s );
	q.SetParameter ( "Company", CompanyFilter );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Date );

EndFunction

&AtServer
Procedure toggleWarning ()
	
	if ( BalanceDate = Date ( 1, 1, 1 ) ) then
		Items.BalanceDate.WarningOnEditRepresentation = WarningOnEditRepresentation.DontShow;
	else
		Items.BalanceDate.WarningOnEditRepresentation = WarningOnEditRepresentation.Show;
	endif; 
	
EndProcedure 

&AtServer
Procedure filterByCompany ()
	
	DC.ChangeFilter ( List, "Company", CompanyFilter, true );
	
EndProcedure 

&AtServer
Procedure filterByDate ()
	
	DC.ChangeFilter ( List, "Date", BalanceDate, BalanceDate <> Date ( 1, 1, 1 ) );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure CompanyFilterOnChange ( Item )
	
	applyCompany ();
	
EndProcedure

&AtServer
Procedure applyCompany ()
	
	prepare ();
	filterByCompany ();
	filterByDate ();
	toggleWarning ();
	Appearance.Apply ( ThisObject, "CompanyFilter" );
	
EndProcedure 

&AtClient
Procedure BalanceDateOnChange ( Item )
	
	if ( shiftStarted () ) then
		Progress.Open ( UUID, ThisObject, new NotifyDescription ( "DocumentsShifted", ThisObject ), true );
	endif;
	
EndProcedure

&AtServer
Function shiftStarted ()
	
	if ( not shiftNeeded () ) then
		filterByDate ();
		return false;
	endif;
	startShifting ();
	OldDate = BalanceDate;
	return true;
	
EndFunction

&AtServer
Function shiftNeeded ()

	return BalanceDate <> Date ( 1, 1, 1 )
	and BalanceDate <> OldDate
	and getBalanceDate () <> undefined;

EndFunction

&AtServer
Procedure startShifting ()

	p = DataProcessors.ShiftBalances.GetParams ();
	p.Date = BalanceDate;
	p.Company = CompanyFilter;
	args = new Array ();
	args.Add ( "ShiftBalances" );
	args.Add ( p );
	Jobs.Run ( "Jobs.ExecProcessor", args, UUID, , TesterCache.Testing () );
	
EndProcedure

&AtClient
Procedure DocumentsShifted ( Result, Params ) export
	
	filterByDate ();
	
EndProcedure

// *****************************************
// *********** List

&AtClient
Procedure ShowRecords ( Command )
	
	if ( TableRow = undefined ) then
		return;
	endif; 
	openRecords ();
	
EndProcedure

&AtClient
Procedure openRecords ()
	
	p = new Structure ( "Document", TableRow.Ref );
	OpenForm ( "Report.Records.Form", p );
	
EndProcedure 

&AtClient
Procedure ListOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow ( Item, Cancel, Clone, Parent, IsFolder, Parameter )
	
	if ( Clone ) then
		return;
	elsif ( not Forms.CheckFields ( ThisObject, "BalanceDate" ) ) then
		Cancel = true;
	endif;
	
EndProcedure
