var CurrenciesTable;
var HostName;
var InternetProxy;
var HTTPConnection;
var StrDate;
var RatesTable;
var MatchingStruct;
var ColNames;
var JobKey;
var ErrorText;
var CurrencyStruct;

Procedure DownloadCurrencies ( Data ) export

	init ( Data );
	initParameters ();
	if ( hostNameEmpty () ) then
		fillErrorText ( Output.NationalBankHostNotSet () );
	else
		downloadPeriod ();
	endif;
	showMessages ();

EndProcedure

Procedure init ( Data )

	DateStart = Data.DateStart;
	DateEnd = Data.DateEnd;
	RefreshRates = Data.RefreshRates;
	initCurrenciesTable ( Data );

EndProcedure

Procedure initCurrenciesTable ( Data ) 

	CurrenciesTable = Data.CurrenciesTable;
	columns = CurrenciesTable.Columns;
	columns.Add ( "Factor" );
	columns.Add ( "Rate" );
	columns.Add ( "Unloaded", new TypeDescription ( "Boolean" ) );
	columns.Add ( "Period" );

EndProcedure

Procedure initParameters ()

	ColNames = "Currency, Period, Unloaded";
	HostName = Constants.NationalBankHost.Get ();
	JobKey = "DownloadCurrencies" + UserName ();
	ErrorText = "";
	CurrencyStruct = new Structure ( "Code, Description, FullDescription" );
	initProxy ();
	initRatesTable ();
	setMatchingStruct ();

EndProcedure

Procedure initProxy ()
	
	proxy = getProxyOptions ();
	if ( proxy.UseProxy = 0 ) then
		InternetProxy = new InternetProxy ( false );
	else
		if ( proxy.UseProxy = 1 ) then
			InternetProxy = new InternetProxy ( true );
		else
			InternetProxy = new InternetProxy ( false );
			InternetProxy.Set ( "http", proxy.Server, proxy.Port, proxy.User, proxy.Password, proxy.OSAuthentication );
		endif;
	endif;
	
EndProcedure

Function getProxyOptions () 

	s = "
	|select Constants.ProxyOSAuthentication as OSAuthentication, Constants.ProxyPassword as Password, Constants.ProxyPort as Port,
	|	Constants.ProxyServer as Server, Constants.ProxyUser as User, Constants.UseProxy as UseProxy
	|from Constants as Constants";
	q = new Query ( s );
	selection = q.Execute ().Select ();
	selection.Next ();
	return selection;

EndFunction

Procedure initRatesTable () 

	RatesTable = new ValueTable ();
	columns = RatesTable.Columns;
	typeString = new TypeDescription ( "String", , new StringQualifiers ( 3 ) );
	columns.Add ( "ID", typeString );
	columns.Add ( "NumCode", typeString );
	columns.Add ( "CharCode", typeString );
	columns.Add ( "Nominal", new TypeDescription ( "Number", new NumberQualifiers ( 8, 0 ) ) );
	columns.Add ( "Name", new TypeDescription ( "String" ) );
	columns.Add ( "Value", new TypeDescription ( "Number", new NumberQualifiers ( 15, 4 ) ) );
	indexes = RatesTable.Indexes;
	indexes.Add ( "NumCode" );
	indexes.Add ( "CharCode" );

EndProcedure

Procedure setMatchingStruct () 

	MatchingStruct = new Structure ();
	MatchingStruct.Insert ( "Code", "NumCode" );
	MatchingStruct.Insert ( "Description", "CharCode" );
	MatchingStruct.Insert ( "Factor", "Nominal" );
	MatchingStruct.Insert ( "FullDescription", "Name" );
	MatchingStruct.Insert ( "Rate", "Value" );

EndProcedure

Function hostNameEmpty ()

	return HostName = "";

EndFunction

Procedure fillErrorText ( Text ) 

	ErrorText = ErrorText + Text + Chars.LF;

EndProcedure

Procedure setHTTPConnection ()

	HTTPConnection = new HTTPConnection ( HostName , , , , InternetProxy );

EndProcedure

Procedure downloadPeriod ()

	setHTTPConnection ();
	dateStruct = new Structure ( "Date" );
	dateCounter = DateStart;
	while ( dateCounter <= DateEnd ) do
		setStrDate ( dateCounter );
		dateStruct.Date = StrDate;
		Progress.Put ( Output.LoadingRatesOnDate ( dateStruct ), JobKey );
		fillRatesTable ();
		if ( error () ) then
			break;
		endif;
		if ( RatesTable.Count () = 0 ) then
			Output.NoInformationRates ( dateStruct );
		else
			download ( dateCounter );
		endif;
		dateCounter = dateCounter + 86400;
	enddo;

EndProcedure

Procedure setStrDate ( Date ) 

	StrDate = Format ( Date, "DF=dd.MM.yyyy" );

EndProcedure

Procedure fillRatesTable ()
	
	xmlString = getXMLString ();
	if ( xmlString = "" ) then
		return;
	endif;
	XMLReader = new XMLReader;
	XMLReader.SetString ( xmlString );
	XMLReader.Read ();	
	if ( XMLReader.NodeType = XMLNodeType.StartElement ) and ( XMLReader.Name = "ValCurs" ) then		
		if ( XMLReader.GetAttribute ( "Date" ) = StrDate ) then
			RatesTable.Clear ();
			while ( XMLReader.Read () ) do		
				if ( XMLReader.NodeType = XMLNodeType.StartElement ) and ( XMLReader.Name = "Valute" ) then
					resultRow = RatesTable.Add ();
					if ( XMLReader.AttributeCount () > 0 ) then
						while ( XMLReader.ReadAttribute () ) do
							try
								resultRow [ XMLReader.Name ] = XMLReader.Value;
							except						
							endtry;						
						enddo; 					
					endif; 
					while ( XMLReader.Read () ) do
						if ( XMLReader.NodeType = XMLNodeType.StartElement ) then
							elementName = XMLReader.Name;
							XMLReader.Read ();
							if ( XMLReader.NodeType = XMLNodeType.Text ) then
								try
									if ( elementName = "Value" ) and ( Number ( "1.0" ) = 10 ) then
										resultRow [ elementName ] = Number ( StrReplace ( XMLReader.Value, ".", "," ) );	
									else
										resultRow [ elementName ] = XMLReader.Value;
									endif;
								except
								endtry;
							endif;
						elsif ( XMLReader.NodeType = XMLNodeType.EndElement ) and ( XMLReader.Name = "Valute" ) then
							break;
						endif;
					enddo;
				endif;
			enddo;
		endif; 
	else
		Output.WrongFileFormatRates ();
	endif; 
	
EndProcedure

Function getXMLString () 

	str = "";
	fileName = getFileName ();
	if ( fileName <> "" ) then
		str = TrimAll ( getTextDoc ( fileName ).GetText () );
		if ( Find ( str, "No information" ) > 0 ) then
			fillErrorText ( Output.NoInformationRates ( new Structure ( "Date", StrDate ) ) );
			str = "";
		elsif ( Find ( str, "Error" ) > 0 ) then
			fillErrorText ( Output.ErrorGettingInformationRates ( new Structure ( "Date, Error", StrDate, str ) ) );
			str = "";
		elsif ( str = "" ) then
			fillErrorText ( Output.NotFilledFileRates () );
		endif;
		DeleteFiles ( fileName );
	endif;
	return str;

EndFunction

Function getFileName () 

	command = "/ru/official_exchange_rates?get_xml=1&date=" + StrDate;	
	fileName = TempFilesDir () + "BNM" + StrDate + ".xml";
	try
		HTTPConnection.Get ( command, fileName );
	except
		errorDescription = ErrorDescription ();
		if ( IsBlankString ( errorDescription ) ) then
			fillErrorText ( Output.InternetConnectionFailed () );
		elsif ( Find ( errorDescription, "407" ) > 0 ) or ( Find ( errorDescription, "authentication" ) > 0 ) then
			fillErrorText ( Output.InternetConnectionFailedProxy () );
		else
			fillErrorText ( Output.CommonError ( new Structure ( "Error", errorDescription ) ) );
		endif;
		fileName = "";
	endtry;
	return fileName;

EndFunction

Function getTextDoc ( FileName ) 

	textDoc = new TextDocument ();
	textDoc.Read ( FileName );	
	return textDoc;

EndFunction

Procedure download ( Date )
	
	CurrenciesTable.FillValues ( Date, "Period" );
	for each row in CurrenciesTable do
		rateRow = getRateRow ( row.Currency );
		if ( rateRow <> undefined ) then
			row.Factor = rateRow [ MatchingStruct.Factor ];
			row.Rate = rateRow [ MatchingStruct.Rate ];
			addRecordRates ( row );
		endif;
	enddo;
	
EndProcedure

Function getRateRow ( Currency ) 

	CurrencyStruct.Code = TrimR ( Currency.Code );
	CurrencyStruct.Description = TrimR ( Currency.Description );
	rateRow = RatesTable.Find ( CurrencyStruct.Code, MatchingStruct.Code );
	if ( rateRow = undefined ) then
		rateRow = RatesTable.Find ( CurrencyStruct.Description, MatchingStruct.Description );
		CurrencyStruct.FullDescription = TrimR ( Currency.FullDescription );
		if ( rateRow = undefined ) then
			Output.CurrencyNotFound ( CurrencyStruct );
		else
			CurrencyStruct.Insert ( "FileCode", rateRow [ MatchingStruct.Code ] );
			Output.WrongCurrencyCode ( CurrencyStruct );
			CurrencyStruct.Delete ( "FileCode" );
		endif;
	endif;
	return rateRow;

EndFunction

Procedure addRecordRates ( Row ) 

	manager = InformationRegisters.ExchangeRates.CreateRecordManager ();
	FillPropertyValues ( manager, Row );
	manager.Read ();
	if ( needWrite ( manager, Row ) ) then
		FillPropertyValues ( manager, Row );
		try
			manager.Write ();
			Row.Unloaded = true;
		except
		    Output.Error ( new Structure ( "Error", ErrorDescription () ) );
		endtry;
	endif;

EndProcedure

Function needWrite ( Manager, Row )

	write = true;
	if ( Manager.Selected () ) then
		if ( Manager.Rate <> Row.Rate ) or ( Manager.Factor <> Row.Factor ) then				
			write = ( RefreshRates );
		endif; 
	endif;
	return write;

EndFunction

Procedure showMessages () 

	if ( error () ) then
		Progress.Put ( ErrorText, JobKey, true );
	else
		Output.EndOfExchageRatesLoad ();
	endif;

EndProcedure

Function error ()

	return ErrorText <> "";

EndFunction

Procedure DownloadCurrenciesShedule () export

	initParameters ();
	if ( hostNameEmpty () ) then
		writeLog ();
	else
		downloadByTenants ();
	endif;
	
EndProcedure

Procedure writeLog ()

	data = ValueToStringInternal ( CurrenciesTable.Copy ( , ColNames ) );
	WriteLogEvent ( "DownloadCurrencies", EventLogLevel.Error, Metadata (), data );

EndProcedure

Procedure downloadByTenants () 

	setHTTPConnection ();
	tenants = Catalogs.Tenants.Select ();
	while ( tenants.Next () ) do
		SessionParameters.Tenant = tenants.Ref;
		SessionParameters.TenantUse = true;
		init ( getData () );
		downloadDate ();
		writeLog ();
		reapeatedDownload ();
	enddo;

EndProcedure

Function getData ( Date = undefined, Table = undefined ) 

	if ( Date = undefined ) then
		Date = CurrentDate ();	
	endif;
	d = new Structure ();
	d.Insert ( "DateStart", BegOfDay ( Date ) );
	d.Insert ( "DateEnd", EndOfDay ( Date ) );
	d.Insert ( "RefreshRates", true );
	d.Insert ( "CurrenciesTable", ? ( Table = undefined, getCurrencies (), Table ) );
	return d;

EndFunction

Function getCurrencies () 

	s = "
	|select Currencies.Ref as Currency 
	|from Catalog.Currencies as Currencies 
	|where ( not Currencies.Ref.DeletionMark )
	|and Currencies.Ref <> &LocalCurrency 
	|and Currencies.Ref.Download";
	q = new Query ( s );
	q.Parameters.Insert ( "LocalCurrency", Application.Currency () );
	return q.Execute ().Unload ();

EndFunction

Procedure downloadDate ()

	setStrDate ( DateStart );
	fillRatesTable ();
	if ( RatesTable.Count () > 0 ) then
		download ( DateStart );
	endif;

EndProcedure

Procedure reapeatedDownload () 

	errorTable = getErrorTable ();
	dates = errorTable.UnloadColumn ( "Period" );
	Collections.Group ( dates );
	for each date in dates do
		table = errorTable.Copy ( new Structure ( "Period", date ), "Currency" );
		init ( getData ( date, table ) );
		downloadDate ();
		writeLog ();
	enddo;

EndProcedure

Function getErrorTable () 

	table = getLogTable ();
	unloadedData = table.Copy ( new Structure ( "Unloaded", true ) );
	unloadedData.Indexes.Add ( "Period, Currency" );
	errorData = table.Copy ( new Structure ( "Unloaded", false ) );
	table.Clear ();
	for each row in errorData do
		if ( unloadedData.FindRows ( new Structure ( "Period, Currency", row.Period, row.Currency ) ).Count () > 0 ) then
			continue;
		endif;
		FillPropertyValues ( table.Add (), row );
	enddo;
	table.Sort ( "Period" );
	return table;

EndFunction

Function getLogTable ()

	table = CurrenciesTable.CopyColumns ( ColNames );
	for each row in getLogData () do
		try
			value = ValueFromStringInternal ( row.Data );
		except
			continue;
		endtry;
		if ( TypeOf ( value ) = Type ( "ValueTable" ) ) then
			for each row in value do
				FillPropertyValues ( table.Add (), row );
			enddo;
		endif;
	enddo;
	table.GroupBy ( ColNames );
	return table;

EndFunction

Function getLogData ()

	data = new ValueTable ();
	filter = new Structure ();
	filter.Insert ( "Level", EventLogLevel.Error );
	filter.Insert ( "Event", "DownloadCurrencies" );
	filter.Insert ( "Metadata", Metadata.DataProcessors.DownloadCurrencies );
	tenantFilter = new Structure ( "Value, Use", SessionParameters.Tenant, true );
	dataSeparation = new Structure ( "Tenant", tenantFilter );
	filter.Insert ( "SessionDataSeparation", dataSeparation );
	UnloadEventLog ( data, filter, "Data" );
	return data;

EndFunction

