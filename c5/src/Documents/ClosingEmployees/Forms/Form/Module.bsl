
// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Constraints.ShowAccess ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.Init ( Object );
		fillNew ();
		Constraints.ShowAccess ( ThisObject );
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
	|Debts Date Company DebtAccount lock Object.Posted;
	|Fill enable not Object.Posted
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	settings = Logins.Settings ( "Company" );
	Object.Company = settings.Company;
	setDebtAccount ();
	CalculationsForm.SetDate ( Object );
	
EndProcedure 

&AtServer
Procedure setDebtAccount ()
	
	Object.DebtAccount = getAccount ();
	
EndProcedure 

&AtServer
Function getAccount ()
	
	s = "
	|select Settings.Value as Value
	|from InformationRegister.Settings.SliceLast ( , Parameter = value ( ChartOfCharacteristicTypes.Settings.ExpenseReportDebt ) ) as Settings
	|";
	q = new Query ( s );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Value );
	
EndFunction 

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

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure Fill ( Command )
	
	runFilling ();
	
EndProcedure

&AtClient
Procedure runFilling ()
	
	if ( Forms.Check ( ThisObject, "DebtAccount, Company" ) ) then
		params = fillingParams ();
		Filler.Open ( params, ThisObject );
	endif; 
	
EndProcedure 

&AtServer
Function fillingParams ()
	
	p = Filler.GetParams ();
	p.Report = "ClosingEmployeesFilling";
	p.Filters = getFilters ();
	p.Background = true;
	return p;
	
EndFunction

&AtServer
Function getFilters ()
	
	filters = new Array ();
	item = DC.CreateParameter ( "Date", Object.Date );
	filters.Add ( item );
	item = DC.CreateParameter ( "Company", Object.Company );
	filters.Add ( item );
	item = DC.CreateParameter ( "DebtAccount", Object.DebtAccount );
	filters.Add ( item );
	item = DC.CreateParameter ( "EmployeeAccount", getEmployeeAccount () );
	filters.Add ( item );
	return filters;
	
EndFunction

&AtServer
Function getEmployeeAccount () 

	info = InformationRegisters.Settings.GetLast ( , new Structure ( "Parameter", ChartsOfCharacteristicTypes.Settings.ExpenseReportAccount ) );
	return info.Value;

EndFunction

&AtClient
Procedure Filling ( Result, Params ) export
	
	if ( not fillTable ( Result ) ) then
		Output.FillingDataNotFound ();
	endif;
	
EndProcedure 

&AtServer
Function fillTable ( val Result )
	
	data = Filler.Fetch ( Result );
	if ( data = undefined ) then
		return false;
	endif;
	debts = Object.Debts;
	if ( Result.ClearTable ) then
		debts.Clear ();
	endif; 
	for each rowData in data do
		row = debts.Add ();
		FillPropertyValues ( row, rowData );
	enddo; 
	return true;

EndFunction

&AtClient
Procedure DateChoiceProcessing ( Item, SelectedValue, StandardProcessing )
	
	SelectedValue = EndOfDay ( SelectedValue );
	
EndProcedure
