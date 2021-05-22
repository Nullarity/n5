Function Print ( val Params, val Language ) export
	
	nextObject = false;
	objects = getObjects ( Params.Objects );
	augment ( Params, Language );
	tabDoc = Params.TabDoc;
	for each object in objects do
		if ( nextObject ) then
			tabDoc.PutHorizontalPageBreak ();
		else
			nextObject = true;
		endif; 
		error = not printObject ( Params, object, Language );
		if ( error ) then
			return undefined;
		endif; 
	enddo; 
	if ( objects.Count () > 1 ) then
		resetTabDocFixing ( tabDoc );
	endif; 
	return new Structure ( "TabDoc, Reference", tabDoc, Params.Reference );
	
EndFunction

Function getObjects ( Objects )
	
	if ( TypeOf ( Objects ) = Type ( "Array" ) ) then
		return Objects;
	else
		items = new Array ();
		items.Add ( Objects );
		return items;
	endif; 
	
EndFunction 

Procedure augment ( Params, Language )
	
	tabDoc = new SpreadsheetDocument ();
	k = Params.Key;
	tabDoc.PrintParametersKey = ? ( TypeOf ( k ) = Type ( "EnumRef.PrintForms" ), Conversion.EnumItemToName ( k ), k );
	Params.TabDoc = tabDoc;
	Params.SelectedLanguage = Language;
	
EndProcedure

Function GetFormCaption ( val Name, val Manager, val PrintingObject ) export
	
	if ( Name = undefined ) then
		return undefined;
	elsif ( Manager = undefined ) then
		template = PrintingObject.Metadata ().Templates.Find ( Name );
	else
		classAndName = getClassAndName ( Manager );
		template = Metadata [ classAndName.Class ] [ classAndName.Name ].Templates.Find ( Name );
	endif; 
	return template.Presentation ();
	
EndFunction

Function getClassAndName ( FullName )
	
	partsNames = Conversion.StringToArray ( FullName, "." );
	classAndName = new Structure ();
	classAndName.Insert ( "Class", partsNames [ 0 ] );
	classAndName.Insert ( "Name", partsNames [ 1 ] );
	return classAndName;
	
EndFunction

Function printObject ( Params, Object, Language )
	
	Params.Reference = Object;
	env = new Structure ();
	SQL.Init ( env );
	manager = getManager ( Params, Object );
	name = Params.Template;
	if ( name <> undefined ) then
		env.Insert ( "T", Manager.GetTemplate ( name + Language ) );
	endif; 
	return manager.Print ( Params, env );
	
EndFunction

Function getManager ( Params, Object )
	
	if ( Params.Manager = undefined ) then
		return getManagerByObject ( Object );
	else
		return getManagerByName ( Params.Manager );
	endif; 
	
EndFunction 

Function getManagerByObject ( Object )
	
	classAndName = getClassAndName ( Object.Metadata ().FullName () );
	if ( classAndName.Class = "Catalog" or classAndName.Class = "Справочник" ) then
		return Catalogs [ classAndName.Name ];
	elsif ( classAndName.Class = "AccountingRegister" or classAndName.Class = "РегистрБухгалтерии" ) then
		return AccountingRegisters [ classAndName.Name ];
	elsif ( classAndName.Class = "AccumulationRegister" or classAndName.Class = "РегистрНакопления" ) then
		return AccumulationRegisters [ classAndName.Name ];
	elsif ( classAndName.Class = "BusinessProcess" or classAndName.Class = "БизнесПроцесс" ) then
		return BusinessProcesses [ classAndName.Name ];
	elsif ( classAndName.Class = "CalculationRegister" or classAndName.Class = "РегистрРасчета" ) then
		return CalculationRegisters [ classAndName.Name ];
	elsif ( classAndName.Class = "ChartOfAccounts" or classAndName.Class = "ПланСчетов" ) then
		return ChartsOfAccounts [ classAndName.Name ];
	elsif ( classAndName.Class = "ChartsOfCalculationType" or classAndName.Class = "ПланВидовРасчета" ) then
		return ChartsOfCalculationTypes [ classAndName.Name ];
	elsif ( classAndName.Class = "ChartOfCharacteristicTypes" or classAndName.Class = "ПланВидовХарактеристик" ) then
		return ChartsOfCharacteristicTypes [ classAndName.Name ];
	elsif ( classAndName.Class = "DataProcessor" or classAndName.Class = "Обработка" ) then
		return DataProcessors [ classAndName.Name ];
	elsif ( classAndName.Class = "Document" or classAndName.Class = "Документ" ) then
		return Documents [ classAndName.Name ];
	elsif ( classAndName.Class = "DocumentJournal" ) or classAndName.Class = "ЖурналДокументов" then
		return DocumentJournals [ classAndName.Name ];
	elsif ( classAndName.Class = "InformationRegister" or classAndName.Class = "РегистрСведений" ) then
		return InformationRegisters [ classAndName.Name ];
	elsif ( classAndName.Class = "Report" or classAndName.Class = "Отчет" ) then
		return Reports [ classAndName.Name ];
	elsif ( classAndName.Class = "Task" or classAndName.Class = "Задача" ) then
		return Tasks [ classAndName.Name ];
	elsif ( classAndName.Class = "Enum" or classAndName.Class = "Перечисление" ) then
		return Enums [ classAndName.Name ];
	elsif ( classAndName.Class = "ExchangePlan" or classAndName.Class = "ПланОбмена" ) then
		return ExchangePlans [ classAndName.Name ];
	endif; 
	
EndFunction
 
Function getManagerByName ( Manager )
	
	classAndName = getClassAndName ( Manager );
	if ( classAndName.Class = "Catalogs" or classAndName.Class = "Справочники" ) then
		return Catalogs [ classAndName.Name ];
	elsif ( classAndName.Class = "AccountingRegisters" or classAndName.Class = "РегистрыБухгалтерии" ) then
		return AccountingRegisters [ classAndName.Name ];
	elsif ( classAndName.Class = "AccumulationRegisters" or classAndName.Class = "РегистрыНакопления" ) then
		return AccumulationRegisters [ classAndName.Name ];
	elsif ( classAndName.Class = "BusinessProcesses" or classAndName.Class = "БизнесПроцессы" ) then
		return BusinessProcesses [ classAndName.Name ];
	elsif ( classAndName.Class = "CalculationRegisters" or classAndName.Class = "РегистрыРасчета" ) then
		return CalculationRegisters [ classAndName.Name ];
	elsif ( classAndName.Class = "ChartsOfAccounts" or classAndName.Class = "ПланыСчетов" ) then
		return ChartsOfAccounts [ classAndName.Name ];
	elsif ( classAndName.Class = "ChartsOfCalculationTypes" or classAndName.Class = "ПланыВидовРасчета" ) then
		return ChartsOfCalculationTypes [ classAndName.Name ];
	elsif ( classAndName.Class = "ChartsOfCharacteristicTypes" or classAndName.Class = "ПланыВидовХарактеристик" ) then
		return ChartsOfCharacteristicTypes [ classAndName.Name ];
	elsif ( classAndName.Class = "DataProcessors" or classAndName.Class = "Обработки" ) then
		return DataProcessors [ classAndName.Name ];
	elsif ( classAndName.Class = "Documents" or classAndName.Class = "Документы" ) then
		return Documents [ classAndName.Name ];
	elsif ( classAndName.Class = "DocumentJournals" ) or classAndName.Class = "ЖурналыДокументов" then
		return DocumentJournals [ classAndName.Name ];
	elsif ( classAndName.Class = "InformationRegisters" or classAndName.Class = "РегистрыСведений" ) then
		return InformationRegisters [ classAndName.Name ];
	elsif ( classAndName.Class = "Reports" or classAndName.Class = "Отчеты" ) then
		return Reports [ classAndName.Name ];
	elsif ( classAndName.Class = "Tasks" or classAndName.Class = "Задачи" ) then
		return Tasks [ classAndName.Name ];
	elsif ( classAndName.Class = "Enums" or classAndName.Class = "Перечисления" ) then
		return Enums [ classAndName.Name ];
	elsif ( classAndName.Class = "ExchangePlans" or classAndName.Class = "ПланыОбмена" ) then
		return ExchangePlans [ classAndName.Name ];
	endif; 
	
EndFunction

Procedure resetTabDocFixing ( TabDoc )
	
	TabDoc.FixedTop = 0;
	TabDoc.FixedLeft = 0;
	
EndProcedure 

Function Language ( val Form ) export
	
	s = "
	|select Settings.Language as Language
	|from Catalog.UserSettings.Print as Settings
	|where Settings.Ref.Owner = &User
	|and Settings.Form = &Form";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Form", Enums.PrintForms [ Form ] );
	table = q.Execute ().Unload ();
	if ( table.Count () = 0 ) then
		return undefined;
	endif;
	value = table [ 0 ].Language;
	if ( value = Enums.PrintLanguages.Default ) then
		return CurrentLanguage ().LanguageCode;
	elsif ( ValueIsFilled ( value ) ) then
		return Lower ( Conversion.EnumItemToName ( value ) );
	else
		return undefined;
	endif;
	
EndFunction