Function Print ( Params ) export
	
	nextObject = false;
	objects = getObjects ( Params.Objects );
	prepareParams ( Params );
	setFormCaption ( Params, objects );
	for each object in objects do
		if ( nextObject ) then
			Params.TabDoc.PutHorizontalPageBreak ();
		else
			nextObject = true;
		endif; 
		error = not printObject ( Params, object );
		if ( error ) then
			return false;
		endif; 
	enddo; 
	if ( objects.Count () > 1 ) then
		resetTabDocFixing ( Params.TabDoc );
	endif; 
	return true;
	
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

Procedure prepareParams ( Params )
	
	if ( Params.TabDoc = undefined ) then
		Params.TabDoc = new SpreadsheetDocument ();
	endif; 
	Params.TabDoc.PrintParametersKey = Params.Key;
	
EndProcedure

Procedure setFormCaption ( Params, PrintingObjects )
	
	if ( Params.Name = undefined
		or Params.Caption <> undefined ) then
		return;
	endif;
	if ( Params.Manager = undefined ) then
		template = PrintingObjects [ 0 ].Metadata ().Templates.Find ( Params.Name );
	else
		classAndName = getClassAndName ( Params.Manager );
		template = Metadata [ classAndName.Class ] [ classAndName.Name ].Templates.Find ( Params.Name );
	endif; 
	Params.Caption = template.Presentation ();
	
EndProcedure 

Function getClassAndName ( FullName )
	
	partsNames = Conversion.StringToArray ( FullName, "." );
	classAndName = new Structure ();
	classAndName.Insert ( "Class", partsNames [ 0 ] );
	classAndName.Insert ( "Name", partsNames [ 1 ] );
	return classAndName;
	
EndFunction

Function printObject ( Params, Object )
	
	Params.Reference = Object;
	env = new Structure ();
	SQL.Init ( env );
	manager = getManager ( Params, Object );
	if ( Params.Name <> undefined ) then
		env.Insert ( "T", Manager.GetTemplate ( Params.Name ) );
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
