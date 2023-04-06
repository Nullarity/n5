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
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.Init ( Object );
		fillNew ();
		updateChangesPermission ();
	endif; 
	LocalCurrency = Application.Currency ();
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
	|Warning UndoPosting show Object.Posted;
	|Date Number Company FinancialResult ProfitLoss lock Object.Posted;
	|Fill show not Object.Posted
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
	setAccounts ();
	
EndProcedure

&AtServer
Procedure setAccounts ()
	
	table = getSettings ();
	settings = ChartsOfCharacteristicTypes.Settings;
	profitLoss = settings.ProfitLoss;
	financialResult = settings.FinancialResult;
	for each row in table do
		parameter = row.Parameter;
		value = row.Value;
		if ( parameter = profitLoss ) then
			Object.ProfitLoss = value;
		elsif ( parameter = financialResult ) then 
			Object.FinancialResult = value;
		endif; 
	enddo; 
	
EndProcedure

&AtServer
Function getSettings ()
	
	accounts = new Array ();
	accounts.Add ( "value ( ChartOfCharacteristicTypes.Settings.ProfitLoss )" );
	accounts.Add ( "value ( ChartOfCharacteristicTypes.Settings.FinancialResult )" );
	s = "
	|select Settings.Parameter as Parameter, Settings.Value as Value
	|from InformationRegister.Settings.SliceLast ( , Parameter in ( " + StrConcat ( accounts, "," ) + ") ) as Settings
	|";
	q = new Query ( s );
	return q.Execute ().Unload ();
	
EndFunction 

&AtClient
Procedure OnOpen ( Cancel )
	
	if ( Object.Ref.IsEmpty () ) then
		fillDocument ( true );
	endif;
	
EndProcedure

&AtClient
Procedure fillDocument ( Silently )
	
	if ( Forms.Check ( ThisObject, "Date, Company, ProfitLoss, FinancialResult", Silently ) ) then
		params = fillingParams ();
		Filler.ProcessData ( params, ThisObject );
	endif
	
EndProcedure

&AtServer
Function fillingParams ()
	
	p = Filler.GetParams ();
	p.Report = "YearCloseFilling";
	p.Filters = getFilters ();
	p.Background = true;
	p.Batch = true;
	return p;
	
EndFunction

&AtServer
Function getFilters ()
	
	filters = new Array ();
	item = DC.CreateParameter ( "Date", BegOfYear ( Object.Date ) );
	filters.Add ( item );
	item = DC.CreateParameter ( "Company", Object.Company );
	filters.Add ( item );
	return filters;
	
EndFunction

&AtClient
Procedure Filling ( Result, Params ) export
	
	fillRecords ( Result );
	
EndProcedure 

&AtServer
Procedure fillRecords ( val Result )

	records = Object.Records;
	records.Clear ();
	table = GetFromTempStorage ( Result.Address ) [ 0 ].Unload ();
	financialResult = Object.FinancialResult;
	for each row in table do
		record = records.Add ();
		if ( row.Class = Enums.Accounts.Income
			or row.Class = Enums.Accounts.OtherIncome ) then
			side = "Dr";
			correspondence = "Cr";
		else
			side = "Cr";
			correspondence = "Dr";
		endif;
		record [ "Account" + side ] = row.Account;
		record [ "Dim" + side + "1" ] = row.Dim1;
		record [ "Dim" + side + "2" ] = row.Dim2;
		record [ "Dim" + side + "3" ] = row.Dim3;
		record [ "CurrencyAmount" + side ] = row.CurrencyAmount;
		record [ "Currency" + side ] = row.Currency;
		record [ "Quantity" + side ] = row.Quantity;
		record [ "Account" + correspondence ] = financialResult;
		amount = row [ "Amount" + correspondence ];
		record.AmountDr = amount;
		record.AmountCr = amount;
		record.Amount = amount;
	enddo;
	
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
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

&AtClient
Procedure Fill ( Command )

	fillDocument ( false );

EndProcedure
