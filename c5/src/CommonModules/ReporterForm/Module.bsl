
&AtClient
Procedure StartChoice ( Form, Setting, Item, StandardProcessing ) export
	
	object = Form.Object;
	report = object.ReportName;
	composer = object.SettingsComposer;
	if ( accountingReport ( report ) ) then
		if ( isFilter ( "Dim1", Setting, composer ) ) then
			chooseDimension ( composer, Item, 1, StandardProcessing );
		elsif ( isFilter ( "Dim2", Setting, composer ) ) then
			chooseDimension ( composer, Item, 2, StandardProcessing );
		elsif ( isFilter ( "Dim3", Setting, composer ) ) then
			chooseDimension ( composer, Item, 3, StandardProcessing );
		endif;
	endif; 
	
EndProcedure

Function accountingReport ( Report )
	
	return Report = "BalanceSheet"
		or Report = "AccountBalance"
		or Report = "AccountAnalysis"
		or Report = "Transactions"
		or Report = "Entries"
		or Report = "SubsidiaryLedger"
		or Report = "AccountTurnovers";
	
EndFunction 

&AtClient
Function isFilter ( Name, Setting, Composer )
	
	type = TypeOf ( Setting );
	if ( type = Type ( "DataCompositionSettingsParameterValue" ) ) then
		#if ( WebClient ) then
			return Name = ReporterFormSrv.Name ( Setting );
		#else
			return Name = String ( Setting.Parameter );
		#endif
	else
		filter = DC.FindFilter ( Composer, Name, false );
		if ( filter <> undefined
		 and ( filter.ComparisonType = DataCompositionComparisonType.Equal
			or filter.ComparisonType = DataCompositionComparisonType.InHierarchy ) ) then
			return filter.UserSettingID = Setting.UserSettingID;
		endif;
	endif; 
	return false;
	
EndFunction 

&AtClient
Procedure chooseDimension ( Composer, Item, Level, StandardProcessing )
	
	account = findValue ( Composer, "Account" );
	if ( not ValueIsFilled ( account ) ) then
		return;
	endif; 
	data = GeneralAccounts.GetData ( account );
	deep = data.Fields.Level;
	if ( deep = 0 ) then
		return;
	endif; 
	dims = data.Dims;
	p = Dimensions.GetParams ();
	p.Level = Level;
	if ( deep > 0 ) then
		p.Dim1 = getDimension ( Composer, 1, dims );
	endif;
	if ( deep > 1 ) then
		p.Dim2 = getDimension ( Composer, 2, dims );
	endif; 
	if ( deep > 2 ) then
		p.Dim3 = getDimension ( Composer, 3, dims );
	endif; 
	p.Company = findValue ( Composer, "Company" );
	Dimensions.Choose ( p, Item, StandardProcessing );
	
EndProcedure 

Function findValue ( Composer, Name )
	
	value = undefined;
	item = DC.FindFilter ( Composer, Name, false );
	if ( item = undefined ) then
		item = DC.FindParameter ( Composer, Name );
		if ( item <> undefined
			and item.Use ) then
			value = item.Value;
		endif; 
	else
		if ( item.Use
			and item.ComparisonType = DataCompositionComparisonType.Equal ) then
			value = item.RightValue;
		endif;
	endif;
	return value;
	
EndFunction 

&AtClient
Function getDimension ( Composer, Level, Dims )
	
	value = findValue ( Composer, "Dim" + Level );
	if ( value = undefined ) then
		value = Dims [ Level - 1 ].ValueType.AdjustValue ( undefined );
	endif; 
	return value;

EndFunction 

&AtClient
Procedure OnChange ( Form, Setting, Updated ) export
	
	object = Form.Object;
	report = object.ReportName;
	composer = object.SettingsComposer;
	ReporterForm.ApplySetting ( report, composer, Setting );
	buildFilter ( Form, Setting );
	ReporterForm.SetTitle ( Form );
	if ( simpleReport ( report ) ) then
		Form.BuildReport ( true );
		Updated = true;
	else
		Updated = false;
	endif; 
	
EndProcedure

&AtClient
Procedure buildFilter ( Form, Setting )
	
	object = Form.Object;
	report = object.ReportName;
	composer = object.SettingsComposer;
	if ( accountingReport ( report ) ) then
		if ( isFilter ( "Account", Setting, composer ) ) then
			if ( not Form.ShowSettings ) then
				Form.BuildFilter ();
			endif; 
		endif; 
	endif; 
	
EndProcedure 

&AtClient
Function simpleReport ( Report )
	
	return Report = "BalanceSheet"
	or Report = "AccountBalance"
	or Report = "AccountAnalysis"
	or Report = "IncomeStatement"
	or Report = "Debts"
	or Report = "Reconciliation"
	or Report = "VendorDebts"
	or Report = "SalesRegister"
	or Report = "Timesheet"
	or Report = "PurchasesRegister";
		
EndFunction 

&AtClient
Procedure ApplySetting ( Report, Composer, Setting ) export
	
	if ( accountingReport ( Report ) ) then
		if ( isFilter ( "Account", Setting, Composer ) ) then
			ReporterForm.ApplyAccount ( Report, composer, Setting );
		endif; 
	endif;
	
EndProcedure 

Procedure ApplyAccount ( Report, Composer, Setting ) export
	
	data = accountData ( Setting );
	setFlags ( Report, Composer, data );
	setDims ( Composer, data );
	setCurrency ( Report, Composer, data );
	setComparison ( Report, Setting, data );
	
EndProcedure 

Function accountData ( Setting )
	
	if ( TypeOf ( Setting ) = Type ( "DataCompositionSettingsParameterValue" ) ) then
		account = ? ( Setting.Use, Setting.Value, undefined );
	else
		account = ? ( Setting.Use, Setting.RightValue, undefined );
	endif;
	return ? ( ValueIsFilled ( account ), GeneralAccounts.GetData ( account ), undefined );

EndFunction 

Procedure setFlags ( Report, Composer, Data )
	
	support = ( Report = "BalanceSheet"
		and Data <> undefined )
	or Report = "AccountAnalysis"
	or Report = "AccountBalance"
	or Report = "SubsidiaryLedger"
	or Report = "AccountTurnovers";
	if ( not support ) then
		return;
	endif; 
	currency = DC.FindParameter ( Composer, "ShowCurrency" );
	quantity = DC.FindParameter ( Composer, "ShowQuantity" );
	dims = DC.FindParameter ( Composer, "ShowDimensions" );
	hierarchy = DC.FindParameter ( Composer, "AccountsHierarchy" );
	if ( Data = undefined ) then
		currency.Use = false;
		quantity.Use = false;
		dims.Use = false;
		hierarchy.Use = false;
		hierarchy.Value = false;
	else
		fields = Data.Fields;
		value = fields.Quantitative;
		quantity.Use = value;
		quantity.Value = value;
		main = fields.Main;
		hierarchy.Use = main;
		hierarchy.Value = main;
		if ( fields.Level = 0 ) then
			dims.Use = false;
			dims.Value = 1;
		else
			dims.Use = true;
			dims.Value = 1;
		endif; 
		if ( fields.Currency ) then
			currency.Use = true;
			currency.Value = true;
		else
			currency.Use = false;
			currency.Value = false;
		endif;
	endif; 
	
EndProcedure 

Procedure setDims ( Composer, Data )
	
	settings = Composer.Settings;
	if ( Data = undefined ) then
		dims = undefined;
		level = 0;
	else
		dims = Data.Dims;
		level = Data.Fields.Level;
	endif;
	for i = 1 to 3 do
		id = "Dim" + i;
		dimIndex = i - 1;
		dim = DC.FindFilter ( settings, id );
		if ( dim = undefined ) then
			continue;
		endif; 
		if ( level > dimIndex ) then
			dim.UserSettingPresentation = dims [ dimIndex ].Presentation;
			if ( dim.UserSettingID = "" ) then
				toggleSetting ( dim, id );
			endif; 
		else
			toggleSetting ( dim, "" );
		endif; 
	enddo; 
	
EndProcedure 

Procedure setCurrency ( Report, Composer, Data )
	
	currency = DC.FindFilter ( Composer.Settings, "Currency" );
	if ( currency = undefined ) then
		return;
	endif; 
	if ( Data = undefined
		and Report <> "BalanceSheet" )
		or ( Data <> undefined
		and not Data.Fields.Currency ) then
		id = "";
	else
		id = "Currency";
	endif;
	toggleSetting ( currency, id );
	
EndProcedure 

Procedure toggleSetting ( Setting, ID )
	
	if ( ID = "" ) then
		Setting.UserSettingPresentation = "";
		Setting.UserSettingID = "";
		Setting.Use = false;
		Setting.RightValue = undefined;
	else
		Setting.UserSettingID = ID;
	endif; 
	
EndProcedure 

Procedure setComparison ( Report, Setting, Data )
	
	if ( Data = undefined ) then
		return;
	endif; 
	support = ( Report = "BalanceSheet"
	or Report = "SubsidiaryLedger" );
	if ( not support ) then
		return;
	endif; 
	main = Data.Fields.Main;
	if ( main
		and Setting.ComparisonType = DataCompositionComparisonType.Equal ) then
		Setting.ComparisonType = DataCompositionComparisonType.InHierarchy;
	elsif ( not main
		and Setting.ComparisonType = DataCompositionComparisonType.InHierarchy ) then
		Setting.ComparisonType = DataCompositionComparisonType.Equal
	endif; 
	
EndProcedure 

Procedure SetTitle ( Form ) export
	
	object = Form.Object;
	report = object.ReportName;
	composer = object.SettingsComposer;
	parts = new Array ();
	parts.Add ( Form.ReportPresentation );
	if ( report = "BalanceSheet"
		or report = "SubsidiaryLedger" ) then
		addPeriod ( parts, composer );
	elsif ( report = "AccountBalance"
		or report = "AccountAnalysis"
		or report = "AccountTurnovers"
		or report = "Entries"
		or report = "Transactions" ) then
		addPart ( parts, composer, "Account" );
		addPeriod ( parts, composer );
	elsif ( report = "Timesheet"
		or report = "WorkLog"
		or report = "Payroll"
		or report = "Payslips" ) then
		addPart ( parts, composer, "Employee" );
		addPeriod ( parts, composer );
	else
		addPart ( parts, composer, "Period" );
	endif;
	Form.Title = StrConcat ( parts, ", " );

EndProcedure 

Procedure addPeriod ( Parts, Composer )
	
	#if ( not MobileClient ) then
		p = DC.FindParameter ( Composer, "Period" );
		if ( p.Use ) then
			period = p.Value;
			Parts.Add ( PeriodPresentation ( period.StartDate, period.EndDate, "FP=true" ) );
		endif; 
	#endif
	
EndProcedure 

Procedure addPart ( Parts, Composer, Fields )
	
	for each name in StrSplit ( Fields, ", " ) do
		value = findValue ( Composer, name );
		if ( ValueIsFilled ( value ) ) then
			Parts.Add ( value );
		endif; 
	enddo;
	
EndProcedure 

&AtServer
Procedure AfterLoadSettings ( Form ) export
	
	object = Form.Object;
	report = object.ReportName;
	composer = object.SettingsComposer;
	if ( accountingReport ( report ) ) then
		ReporterForm.ApplyAccount ( report, composer, findSetting ( composer, "Account" ) );
	endif; 
	filterByCompany ( report, composer );
	if ( not Form.ShowSettings ) then
		Form.BuildFilter ();
	endif; 
	
EndProcedure 

&AtServer
Function findSetting ( Composer, Name )
	
	item = DC.FindFilter ( Composer, Name, false );
	if ( item = undefined ) then
		item = DC.FindParameter ( Composer, Name );
	endif;
	return item;
	
EndFunction 

&AtServer
Procedure filterByCompany ( Report, Composer )
	
	setting = findSetting ( Composer, "Company" );
	if ( setting = undefined ) then
		return;
	endif; 
	if ( companyInstalled ( Composer ) ) then
		return;
	endif; 
	if ( oneCompany ()
		and not mandatory ( Report, setting ) ) then
		return;
	endif; 
	setValue ( setting, Logins.Settings ( "Company" ).Company );

EndProcedure 

&AtServer
Function companyInstalled ( Composer )
	
	company = findValue ( Composer, "Company" );
	return ValueIsFilled ( company );

EndFunction 

&AtServer
Function oneCompany ()
	
	s = "
	|select allowed Companies.Ref
	|from Catalog.Companies as Companies
	|where not Companies.DeletionMark
	|";
	q = new Query ( s );
	table = q.Execute ().Unload ();
	return table.Count () = 1;
	
EndFunction 

&AtServer
Function mandatory ( Report, Parameter )
	
	if ( TypeOf ( Parameter ) <> Type ( "DataCompositionSettingsParameterValue" ) ) then
		return false;
	endif;
	schema = Reporter.GetSchema ( Report );
	return schema.Parameters.Find ( Parameter.Parameter ).DenyIncompleteValues;
	
EndFunction

&AtServer
Procedure setValue ( Setting, Value )
	
	Setting.Use = true;
	if ( TypeOf ( Setting ) = Type ( "DataCompositionSettingsParameterValue" ) ) then
		Setting.Value = Value;
	else
		Setting.RightValue = Value;
	endif; 
	
EndProcedure 
