&AtClient
var TableRow export;
&AtClient
var TableTaxRow export;
&AtClient
var TableTotalsRow export;
&AtClient
var AdditionsRow;
&AtClient
var RemovingEmployees;
&AtClient
var RemovingIndividuals;
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
	
	updateChangesPermission ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing)
	
	init ();
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.Init ( Object );
		fillNew ();
		updateChangesPermission ();
	endif; 
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure init ()
	
	Currency = Application.Currency ();

EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Warning UndoPosting show Object.Posted;
	|PreviousPeriod NextPeriod show Object.Period <> Enum.TimesheetPeriods.Other;
	|DateEnd lock Object.Period <> Enum.TimesheetPeriods.Other;
	|DateStart lock Object.Period <> Enum.TimesheetPeriods.Other;
	|Compensations Taxes Additions Base Advances Period Date Number Company lock Object.Posted;
	|PeriodGroup CompensationsEdit TaxesEditTax enable not Object.Posted;
	|Calculate CalculateTaxes show not Object.Dirty;
	|Calculate1 CalculateTaxes1 Ignore show Object.Dirty;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	settings = Logins.Settings ( "Company" );
	company = settings.Company;
	Object.Company = company;
	Object.Period = DF.Pick ( company, "PayrollPeriod" );
	defaultPeriod ();
	
EndProcedure 

&AtServer
Procedure defaultPeriod ()
	
	evalDateStart ();
	completePeriod ( Object );
	
EndProcedure 

&AtServer
Procedure evalDateStart ()
	
	lastDate = lastPeriod ();
	if ( lastDate = undefined ) then
		currentDate = CurrentSessionDate ();
		if ( Object.Period = PredefinedValue ( "Enum.TimesheetPeriods.Month" ) ) then
			lastDate = BegOfMonth ( currentDate );
		else
			lastDate = currentDate;
		endif; 
	else
		lastDate = lastDate + 86400;
	endif; 
	Object.DateStart = lastDate;
	
EndProcedure 

&AtServer
Function lastPeriod ()
	
	s = "
	|select allowed top 1 Payrolls.DateEnd as DateEnd
	|from Document.Payroll as Payrolls
	|where Payrolls.Company = &Company
	|and Payrolls.Period = &Period
	|and Payrolls.DateEnd < &Date
	|and not Payrolls.DeletionMark
	|order by Payrolls.DateEnd desc
	|";
	q = new Query ( s );
	q.SetParameter ( "Company", Object.Company );
	q.SetParameter ( "Period", Object.Period );
	date = Object.Date;
	q.SetParameter ( "Date", ? ( date = Date ( 1, 1, 1 ), CurrentSessionDate (), date ) );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].DateEnd );
	
EndFunction 

&AtClientAtServerNoContext
Function getDuration ( Object )
	
	period = Object.Period;
	if ( period = PredefinedValue ( "Enum.TimesheetPeriods.Week" ) ) then
		return 7 * 86400;
	elsif ( period = PredefinedValue ( "Enum.TimesheetPeriods.TwoWeeks" ) ) then
		return 14 * 86400;
	else
		return 0;
	endif; 
	
EndFunction 

&AtClientAtServerNoContext
Procedure completePeriod ( Object )
	
	defineDateEnd ( Object );
	Object.Date = Min ( Object.DateEnd, Periods.GetDocumentDate ( Object ) );

EndProcedure 

&AtClientAtServerNoContext
Procedure defineDateEnd ( Object )
	
	start = Object.DateStart;
	if ( Object.Period = PredefinedValue ( "Enum.TimesheetPeriods.Month" ) ) then
		Object.DateEnd = EndOfMonth ( start );
	else
		Object.DateEnd = start + getDuration ( Object );
	endif; 

EndProcedure 

&AtClient
Procedure ChoiceProcessing ( SelectedValue, ChoiceSource )
	
	operation = SelectedValue.Operation;
	if ( operation = Enum.ChoiceOperationsPayrollRecord () ) then
		PayrollForm.LoadRow ( ThisObject, SelectedValue );
		PayrollForm.SyncTables ( ThisObject, "Taxes, Additions" );
	elsif ( operation = Enum.ChoiceOperationsEmployeesTaxRecord () ) then
		PayrollForm.LoadTaxRow ( ThisObject, SelectedValue );
	elsif ( operation = Enum.ChoiceOperationsPayrollRecordSaveAndNew () ) then
		PayrollForm.LoadRow ( ThisObject, SelectedValue );	
		PayrollForm.SyncTables ( ThisObject, "Taxes, Additions" );
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
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	adjustPeriod ();
	updateChangesPermission ()

EndProcedure

&AtClient
Procedure adjustPeriod ()
	
	date = Object.Date;
	if ( not Object.Ref.IsEmpty ()
		or date = Date ( 1, 1, 1 ) ) then
		return;
	endif;
	period = Object.Period;
	if ( period = PredefinedValue ( "Enum.TimesheetPeriods.Week" )
		or period = PredefinedValue ( "Enum.TimesheetPeriods.TwoWeeks" ) ) then
		Object.DateStart = BegOfWeek ( date );
	else
		Object.DateStart = BegOfMonth ( date );
	endif;
	defineDateEnd ( Object );

EndProcedure

&AtClient
Procedure PreviousPeriod ( Command )
	
	if ( dataExists () ) then
		Output.DataCleaning ( ThisObject, -1 );
	else
		movePeriod ( -1 );
	endif; 
	
EndProcedure

&AtClient
Function dataExists ()
	
	return Object.Compensations.Count () > 0
	or Object.Taxes.Count () > 0;
	
EndFunction 

&AtClient
Procedure DataCleaning ( Answer, Direction ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	PayrollForm.Clean ( ThisObject );
	movePeriod ( Direction );
	
EndProcedure 

&AtClient
Procedure movePeriod ( Direction )
	
	if ( Object.Period = PredefinedValue ( "Enum.TimesheetPeriods.Month" ) ) then
		Object.DateStart = AddMonth ( Object.DateStart, Direction );
	else
		duration = getDuration ( Object );
		if ( Direction = 1 ) then
			Object.DateStart = Object.DateEnd + 86400;
		else
			Object.DateStart = Object.DateStart - duration;
		endif; 
	endif; 
	completePeriod ( Object );
	
EndProcedure 

&AtClient
Procedure NextPeriod ( Command )
	
	if ( dataExists () ) then
		Output.DataCleaning ( ThisObject, 1 );
	else
		movePeriod ( 1 );
	endif; 
	
EndProcedure

&AtClient
Procedure PeriodOnChange ( Item )
	
	applyPeriod ();
	
EndProcedure

&AtServer
Procedure applyPeriod ()
	
	defaultPeriod ();
	Object.Compensations.Clear ();
	Object.Taxes.Clear ();
	Appearance.Apply ( ThisObject, "Object.Period" );
	
EndProcedure 

&AtClient
Procedure PaymentDateOnChange ( Item )
	
	if ( Object.Totals.Count () > 0 ) then
		PayrollForm.MakeDirty ( ThisObject );
	endif;

EndProcedure

&AtClient
Procedure Fill ( Command )
	
	runCalculations ( FillDocument );
	
EndProcedure

&AtClient
Procedure runCalculations ( Variant )
	
	if ( not Forms.Check ( ThisObject, "DateStart, DateEnd, Company" ) ) then
		return;
	endif;
	CalculationVariant = Variant;
	params = fillingParams ();
	if ( CalculationVariant = FillDocument ) then
		Filler.Open ( params, ThisObject );
	else
		Filler.ProcessData ( params, ThisObject );
	endif; 
	
EndProcedure 

&AtServer
Function fillingParams ()
	
	p = Filler.GetParams ();
	p.Report = "PayrollFilling";
	p.Filters = getFilters ();
	p.Background = true;
	p.Batch = true;
	return p;
	
EndFunction

&AtServer
Function getFilters ()
	
	filters = new Array ();
	ref = Object.Ref;
	if ( CalculationVariant = CalculateAll ) then
		item = DC.CreateParameter ( "CalculatingPayroll", ref );
		filters.Add ( item );
	elsif ( CalculationVariant = CalculateTaxes ) then
		item = DC.CreateParameter ( "CalculatingTaxesPayroll", ref );
		filters.Add ( item );
	endif; 
	dateEnd = Object.DateEnd;
	item = DC.CreateParameter ( "PaymentDate", ? ( Object.Payment = Date ( 1 , 1, 1 ), dateEnd, Object.Payment ) );
	filters.Add ( item );
	item = DC.CreateParameter ( "CalculationVariant", CalculationVariant );
	filters.Add ( item );
	item = DC.CreateParameter ( "Period", new StandardPeriod ( Object.DateStart, dateEnd ) );
	filters.Add ( item );
	item = DC.CreateParameter ( "Ref", ref );
	filters.Add ( item );
	item = DC.CreateFilter ( "Company", Object.Company );
	filters.Add ( item );
	item = DC.CreateParameter ( "Additions", PutToTempStorage ( getAdditions (), UUID ) );
	filters.Add ( item );
	return filters;
	
EndFunction

&AtServer
Function getAdditions ()
	
	table = Object.Additions.Unload ();
	i = table.Count ();
	while ( i > 0 ) do
		i = i - 1;
		row = table [ i ];
		if ( row.Compensation.IsEmpty ()
			or row.Currency.IsEmpty ()
			or row.Employee.IsEmpty ()
			or row.Rate = 0 ) then
			table.Delete ( i );
		endif;
	enddo;
	return table;

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
	PayrollForm.SyncTables ( ThisObject, "Taxes, Additions" );
	
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
	
	RemovingIndividuals = new Array ();
	compensations = ( Table = Items.Compensations );
	if ( compensations ) then
		RemovingEmployees = new Array ();
	endif;
	for each id in Table.SelectedRows do
		row = Table.RowData ( id );
		RemovingIndividuals.Add ( row.Individual );
		if ( compensations ) then
			RemovingEmployees.Add ( row.Employee );
		endif;
	enddo;
	Collections.Group ( RemovingIndividuals );
	if ( compensations ) then
		Collections.Group ( RemovingEmployees );
	endif;
	
EndProcedure

&AtClient
Procedure CompensationsAfterDeleteRow ( Item )
	
	completeDeletion ( Item );
	
EndProcedure

&AtClient
Procedure completeDeletion ( Table )
	
	if ( Table = Items.Compensations ) then
		PayrollForm.DeleteTaxes ( Object, RemovingEmployees );
		deleteRecords ( Object.Base, "Employee", "Employee", RemovingEmployees );
		deleteRecords ( Object.Advances, "Employee", "Individual", RemovingIndividuals );
		RemovingEmployees.Clear ();
	endif;
	PayrollForm.CalcEmployees ( Object, RemovingIndividuals );
	RemovingIndividuals.Clear ();

EndProcedure

&AtClient
Procedure deleteRecords ( Table, Column, SyncWith, Employees )
	
	compensations = Object.Compensations;
	searchCompensations = new Structure ( SyncWith );
	searchRecords = new Structure ( Column );
	for each employee in Employees do
		searchCompensations [ SyncWith ] = employee;
		rows = compensations.FindRows ( searchCompensations );
		stillExists = rows.Count () > 0;
		if ( stillExists ) then
			continue;
		endif;
		searchRecords [ Column ] = employee;
		rows = Table.FindRows ( searchRecords );
		i = rows.Count ();
		while ( i > 0 ) do
			i = i - 1;
			Table.Delete ( rows [ i ] );
		enddo; 
	enddo;
	
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
// *********** Table Additions

&AtClient
Procedure AdditionsOnActivateRow ( Item )
	
	AdditionsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure AdditionsOnStartEdit ( Item, NewRow, Clone )
	
	if ( NewRow and not Clone ) then
		initAddition ();
	endif; 
	
EndProcedure

&AtClient
Procedure initAddition ()
	
	AdditionsRow.Currency = Currency;
	
EndProcedure 

&AtClient
Procedure AdditionsOnChange ( Item )

	PayrollForm.MakeDirty ( ThisObject );

EndProcedure

// *****************************************
// *********** Table Base

&AtClient
Procedure BaseBeforeAddRow ( Item, Cancel, Clone, Parent, IsFolder, Parameter )
	
	Cancel = true;

EndProcedure

&AtClient
Procedure BaseBeforeRowChange ( Item, Cancel )
	
	Cancel = true;

EndProcedure

// *****************************************
// *********** Table Advances

&AtClient
Procedure AdvancesBeforeAddRow ( Item, Cancel, Clone, Parent, IsFolder, Parameter )
	
	Cancel = true;

EndProcedure

// *****************************************
// *********** Variables Initialization

FillDocument = 1; 
CalculateAll = 2;
CalculateTaxes = 3;
