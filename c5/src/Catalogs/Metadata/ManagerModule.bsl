#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

#if ( Server ) then

Function Ref ( Path, Renew = false ) export

	SetPrivilegedMode ( true );
	item = FindByAttribute ( "Path", Path );
	if ( item.IsEmpty () or Renew ) then
		if ( item.IsEmpty () ) then
			obj = CreateItem ();
			isNew = true;
		else
			obj = item.GetObject ();
			isNew = false;
		endif; 
		init ( Path, obj, isNew );
		obj.Write ();
		item = obj.Ref;
	endif; 
	return item;
	
EndFunction

Procedure init ( Path, Object, IsNew )
	
	item = Metadata.FindByFullName ( Path );
	lang = CurrentLanguage ();
	languages = Metadata.Languages;
	isEnglish = ( lang = languages.Find ( "English" ) );
	isRomanian = ( lang = languages.Find ( "Romanian" ) );
	if ( IsNew or isEnglish ) then
		Object.Description = item.Presentation ();
	endif; 
	Object.Parent = getParent ( Path );
	Object.Path = Path;
	if ( isEnglish ) then
		Object.ExplanationEN = item.Explanation;
		Object.SynonymEN = item.Synonym;
	elsif ( isRomanian ) then
		Object.ExplanationRO = item.Explanation;
		Object.SynonymRO = item.Synonym;
	else
		Object.ExplanationRU = item.Explanation;
		Object.SynonymRU = item.Synonym;
	endif; 
	Object.NotFound = false;
	
EndProcedure

Function getParent ( Path )
	
	class = Left ( Path, Find ( Path, "." ) - 1 );
	if ( class = "Catalog" ) then
		parent = Catalogs;
	elsif ( class = "AccountingRegister" ) then
		parent = AccountingRegisters;
	elsif ( class = "AccumulationRegister" ) then
		parent = AccumulationRegisters;
	elsif ( class = "BusinessProcess" ) then
		parent = BusinessProcesses;
	elsif ( class = "CalculationRegister" ) then
		parent = CalculationRegisters;
	elsif ( class = "ChartOfAccounts" ) then
		parent = ChartsOfAccounts;
	elsif ( class = "ChartsOfCalculationType" ) then
		parent = ChartsOfCalculationTypes;
	elsif ( class = "ChartOfCharacteristicTypes" ) then
		parent = ChartsOfCharacteristicTypes;
	elsif ( class = "DataProcessor" ) then
		parent = DataProcessors;
	elsif ( class = "Document" ) then
		parent = Documents;
	elsif ( class = "DocumentJournal" ) then
		parent = DocumentJournals;
	elsif ( class = "InformationRegister" ) then
		parent = InformationRegisters;
	elsif ( class = "Report" ) then
		parent = Reports;
	elsif ( class = "Task" ) then
		parent = Tasks;
	elsif ( class = "Enum" ) then
		parent = Enums;
	elsif ( class = "Subsystem" ) then
		parent = Subsystems;
	elsif ( class = "ExchangePlan" ) then
		parent = ExchangePlans;
	else
		parent = EmptyRef ();
	endif; 
	return parent;

EndFunction

#endif

#endif