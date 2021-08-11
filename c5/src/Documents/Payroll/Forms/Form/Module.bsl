&AtClient
var TableRow export;
&AtClient
var TableTaxRow export;
&AtClient
var TableTotalsRow export;
&AtClient
var RemovingEmployee;
&AtClient
var RemovingIndividual;
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
	
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing)
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.Init ( Object );
		fillNew ();
	endif; 
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
	|PreviousPeriod NextPeriod show Object.Period <> Enum.TimesheetPeriods.Other;
	|DateEnd lock Object.Period <> Enum.TimesheetPeriods.Other;
	|DateStart lock Object.Period <> Enum.TimesheetPeriods.Other;
	|Compensations Taxes Period Date Number Company lock Object.Posted;
	|PeriodGroup CompensationsEdit TaxesEditTax enable not Object.Posted;
	|Calculate CalculateTaxes show not Object.Dirty;
	|Calculate1 CalculateTaxes1 Ignore show Object.Dirty
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
	
	if ( Object.Period = PredefinedValue ( "Enum.TimesheetPeriods.Month" ) ) then
		Object.DateEnd = EndOfMonth ( Object.DateStart );
	else
		Object.DateEnd = Object.DateStart + getDuration ( Object );
	endif; 
	Object.Date = Object.DateEnd;

EndProcedure 

&AtClient
Procedure ChoiceProcessing ( SelectedValue, ChoiceSource )
	
	operation = SelectedValue.Operation;
	if ( operation = Enum.ChoiceOperationsPayrollRecord () ) then
		PayrollForm.LoadRow ( ThisObject, SelectedValue );
	elsif ( operation = Enum.ChoiceOperationsEmployeesTaxRecord () ) then
		PayrollForm.LoadTaxRow ( ThisObject, SelectedValue );
	elsif ( operation = Enum.ChoiceOperationsPayrollRecordSaveAndNew () ) then
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
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Form

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
Procedure Fill ( Command )
	
	runCalculations ( FillDocument );
	
EndProcedure

&AtClient
Procedure runCalculations ( Variant )
	
	CalculationVariant = Variant;
	if ( Forms.Check ( ThisObject, "DateStart, DateEnd, Company" ) ) then
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
	if ( CalculationVariant = 2 ) then
		item = DC.CreateParameter ( "CalculatingPayroll", ref );
		filters.Add ( item );
	elsif ( CalculationVariant = 3 ) then
		item = DC.CreateParameter ( "CalculatingTaxesPayroll", ref );
		filters.Add ( item );
	endif; 
	item = DC.CreateParameter ( "CalculationVariant", CalculationVariant );
	filters.Add ( item );
	item = DC.CreateParameter ( "Period", new StandardPeriod ( Object.DateStart, Object.DateEnd ) );
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
	
	trackDeletion ();
	
EndProcedure

&AtClient
Procedure trackDeletion ()
	
	RemovingEmployee = TableRow.Employee;
	RemovingIndividual = TableRow.Individual;
	
EndProcedure

&AtClient
Procedure CompensationsAfterDeleteRow ( Item )
	
	PayrollForm.DeleteTaxes ( Object, RemovingEmployee );
	PayrollForm.CalcEmployee ( Object, RemovingIndividual );
	
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
	
	trackDeletion ();
	
EndProcedure

&AtClient
Procedure TaxesAfterDeleteRow ( Item )
	
	PayrollForm.CalcEmployee ( Object, RemovingIndividual );
	
EndProcedure

// *****************************************
// *********** Variables Initialization

FillDocument = 1; 
CalculateAll = 2;
CalculateTaxes = 3;
