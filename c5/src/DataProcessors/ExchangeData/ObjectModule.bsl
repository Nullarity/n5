#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var TempDirectory;
var ScheduledJob;
var FileXml;
var ReadChangesConfiguration;
var ExchangeProcessor;
var Error;
var SendReport;
var CounterFiles;
var IDProcess;
var FTP;
var NodesData;
var ExchNode;
var ThisNode;
var FileExchange;
var StartUp;
var FileMask;
var CatalogItem;

Procedure Load ( Params ) export
	
	init ( Params );
	if ( Params.Update ) then
		Output.WillBeRunRereadFileExchange ();
		ThisNode = getThisNode ( CatalogItem );
		try 
			fileUpdate = new File ( CatalogItem.FileMessage );
			FileXML = fileUpdate.FullName;
			TempDirectory = fileUpdate.Path;
			ExchNode = CatalogItem;
			FileExchange = fileUpdate.FullName;
			read ();
			Output.ExchangeReceivedFromNode ( new Structure ( "Node", ExchNode.Code ) );
		except
			Output.ErrorReceivingData ( new Structure ( "Error", ErrorDescription () ) );
			return;
		endtry;
		catObject = CatalogItem.GetObject ();
		catObject.FileMessage = "";
		catObject.NumbersOfErrors = 0;
		catObject.Write ();
		Connections.Unlock ();
		Output.UnlockBase ( new Structure ( "Date", CurrentDate () ) );
		id = Left ( Right ( TempDirectory, 37 ), 36 );
		deleteFile ( TempFilesDir () + "RereadData_" + id + ".epf" );
		deleteFile ( Mid ( TempDirectory, 1, ( StrLen ( TempDirectory ) - 1 ) ) );
		Output.FinishedRereadFileExchange ();
	else			
		ReadChangesConfiguration = false;
		nodesArray = getNodes ( CatalogItem, false );
		TempDirectory = createTempDir ();
		for each itemNode in nodesArray do
			ExchNode = NodesData [ itemNode.Ref ];
			ThisNode = itemNode.ThisNode;
			if ( ExchNode <> ThisNode ) then
				Output.ExchangeWithNode ( new Structure ( "Node", ExchNode.Code ) );
				CounterFiles = 0;
				if ( ExchNode.OperationType = Enums.ExchangeTypes.Email ) then
					loadByEmail ();
				elsif ( ExchNode.OperationType = Enums.ExchangeTypes.FTP ) then
					loadFromFTP ();
				elsif ( ExchNode.OperationType = Enums.ExchangeTypes.NetworkDisk ) then
					loadFromDisk ();
				elsif ( ExchNode.OperationType = Enums.ExchangeTypes.WebService ) then
					loadFromWebService ();
				endif;
				if ( ReadChangesConfiguration ) then
					Params.Update = true;
					break;
				endif; 
				Output.ExchangeWithNodeOver ( new Structure ( "Node", ExchNode.Code ) );
				if ( CounterFiles = 0 ) then
					handleErrors ();
				endif; 
			endif;
		enddo;
		if ( not Params.Update ) then
			deleteFile ( Mid ( TempDirectory, 1, ( StrLen ( TempDirectory ) - 1 ) ) );
		endif;
	endif;
			
EndProcedure

Procedure init ( Params )
	
	CatalogItem = Params.Node;
	StartUp = Params.StartUp;
	ID = Params.ID;	
	ScheduledJob = setScheduledJob ( CatalogItem );
	IDProcess = ? ( ID = "", getUUID (), ID );	
	Error = "";
	
EndProcedure 

Procedure Unload ( Params ) export 
	
	init ( Params );
	TempDirectory = createTempDir ();	
	map_files = createFiles ( CatalogItem );
	for each item in map_files do
		ExchNode = NodesData [ item.Key ];
		dataItem = item.Value;
		if ( dataItem.Cancel ) then
			continue;
		endif; 
		FileExchange = dataItem.File;
		ThisNode = NodesData [ dataItem.ThisNode ];
		if ( ExchNode.OperationType = Enums.ExchangeTypes.Email ) then
			unloadToEmail ();
		elsif ( ExchNode.OperationType = Enums.ExchangeTypes.FTP ) then
			unloadToFTP ();
		elsif ( ExchNode.OperationType = Enums.ExchangeTypes.NetworkDisk ) then
			unloadToDisk ();
		elsif ( ExchNode.OperationType = Enums.ExchangeTypes.WebService ) then
			unloadToWebService ();	
		endif;
		catObject = ExchNode.Ref.GetObject ();
		catObject.LastDateUnload = CurrentSessionDate ();
		catObject.Write ();
	enddo;
	deleteFile ( Mid ( TempDirectory, 1, ( StrLen ( TempDirectory ) - 1 ) ) );
	
EndProcedure

Procedure loadByEmail ()
	
	Output.LoadFromEmail ();
	profile = getEmailProfile ( ExchNode );
	email = new InternetMail;	
	try
		Output.LogonToServerMail ();
		email.Logon ( profile );
		Output.LogonSuccess ();
	except
		Output.ErrorConnectEmailProfile ( new Structure ( "Error", ErrorDescription () ) );
		return;
	endtry;
	CounterFiles = 0;
	messages = new Array;
	messages = email.Get ( true );
	if ( messages.Count () > 0 ) then 
		for each mailMessage in messages do
			attachment = mailMessage.Attachments [ 0 ];
			if not ( ( Right ( attachment.Name, 3 ) = "xml" ) or ( Right ( attachment.Name, 3 ) = "zip" ) ) then
				continue;
			endif;
			// analize name of file attachment - first analize prefix, second code is Node.Code, third code is ThisNode.Code 
			if ( Find ( attachment.Name, ExchNode.PrefixFileName ) = 0 ) then
				continue;
			endif;
			findSender = Find ( attachment.Name, ExchNode.Code );
			findReceiver = Find ( attachment.Name, NodesData [ ThisNode ].Code );
			if ( findSender = 0 ) or ( findReceiver = 0 ) or ( findSender > findReceiver ) then
				continue;
			endif;
			Output.MailReceived ();
			FileExchange = TempDirectory + attachment.Name;
			exchange_data = attachment.Data; 
			exchange_data.Write ( FileExchange );
			read ();
			if ( ReadChangesConfiguration ) then
				return;
			endif;
			CounterFiles = CounterFiles + 1;
		enddo;
	endif;
	checkCounterFiles ();
	email.Logoff ();
			
EndProcedure

Procedure loadFromFTP ()

	Output.LoadFromFTP ();
	if ( StrLen ( ExchNode.FolderFTPLoad ) > 0 ) then
		folder = ExchNode.FolderFTPLoad + "/";
	else
		folder = "";
	endif;
	FileMask = fileID ( ExchNode.Code, ThisNode.Code, ExchNode.PrefixFileName ) + "*";
	if ( ExchNode.UseStandartFTPClient ) then
		loadStandartClient ( folder );
	else
		loadFilesChilkat ( folder );		
	endif;
	arrayFiles = FindFiles ( TempDirectory, FileMask + "*" );
	CounterFiles = 0;
	if ( arrayFiles.Count () > 0 ) then
		for each file in arrayFiles do
			if ( file.Extension = ".zip" ) or ( file.Extension = ".xml" ) then
				FileExchange = file.FullName;
				read ();
				if ( ReadChangesConfiguration ) then
					return;
				endif;
				CounterFiles = CounterFiles + 1;
			endif;
		enddo;
	endif;
	checkCounterFiles ();
	
EndProcedure

Procedure loadFromDisk ()
	
	Output.LoadFromNetworkDisk ();
	path = ? ( ScheduledJob, TrimAll ( ExchNode.FolderDiskLoadScheduledJob ), TrimAll ( ExchNode.FolderDiskLoadHandle ) );
	FileMask = "*" + TrimAll ( ExchNode.Code ) + "*" + TrimAll ( ThisNode.Code ) + "*" + ( ExchNode.PrefixFileName ) + "*.";
	zipFiles = FindFiles ( path, FileMask + "zip" );	
	for each file in zipFiles do
		CopyFile ( file.FullName, TempDirectory + file.Name );
	enddo;
	xmlFiles = FindFiles ( path, FileMask + "xml" );
	for each file in xmlFiles do
		CopyFile ( file.FullName, TempDirectory + file.Name );
	enddo;
	arrayXML = FindFiles ( TempDirectory, FileMask + "*" );
	CounterFiles = 0;
	for each item in arrayXML do
		if ( item.Extension = ".zip"
			or item.Extension = ".xml" ) then
			FileExchange = item.FullName;
			read ();
			if ( ReadChangesConfiguration ) then
				CounterFiles = CounterFiles + 1;
				break;
			endif;
			CounterFiles = CounterFiles + 1;
		endif;
	enddo;
	checkCounterFiles ();
	for each file in zipFiles do
		deleteFile ( file.FullName );
	enddo;
	for each file in xmlFiles do
		deleteFile ( file.FullName );
	enddo;
		
EndProcedure

procedure loadFromWebService ()
	
	Output.LoadFromWS ();
	if ExchangePlans.MasterNode () = undefined then
		folder = TempFilesDir () + "ExchangeWebService_" + IDProcess + "\";
		files = FindFiles ( folder, "Message*.zip", false );
		if ( files.Count () = 0 ) then
			result = false;
		else
			file = files [ 0 ].FullName;
			FileExchange = TempDirectory + files [ 0 ].Name;
			CopyFile ( file, FileExchange );
			result = true;	
		endif; 
	else	
		path = TempDirectory + fileID ( ExchNode.Code, ThisNode.Code, ExchNode.PrefixFileName ) + ".zip";
		p = getWSPamas ();
		p.Path = path;
		Exchange.WSRead ( p );
		result = p.Result;
		FileExchange = path;
	endif;
	if ( result ) then
		read ();
		CounterFiles = CounterFiles + 1;
		checkCounterFiles ();
	endif; 
	
endprocedure 

Function fileID ( From, Target, Prefix )
	
	return "Message_from_" + TrimAll ( From ) + "_to_" + TrimAll ( Target ) + Prefix;
	
EndFunction 

Procedure unloadToEmail ()
	
	Output.UnLoadToEmail ();
	profile = getEmailProfile ( ExchNode );
	email = new InternetMail;
	try
		Output.LogonToServerMail ();
		email.Logon ( profile );
	except 
		Output.ErrorConnectEmailProfile ( new Structure ( "Error", ErrorDescription () ) );
		return;
	endtry;
	Output.LogonSuccess ();
	emailMessage = new InternetMailMessage;
	emailMessage.From = TrimAll ( ExchNode.EMailLoad );
	emailMessage.Subject = fileID ( ThisNode.Code, ExchNode.Code, ExchNode.PrefixFileName );
	emailMessage.Attachments.Add ( TempDirectory + FileExchange );
	emailMessage.To.Add ( TrimAll ( ExchNode.EMailUnLoad ) );
	Output.SendingMail ();
	email.Send ( emailMessage );  	
	Output.MessageSent ( new Structure ( "Node", ExchNode.Code ) );
	email.Logoff ();	
	
EndProcedure

Procedure unloadToFTP ()
	
	Output.UnLoadToFTP ();
	status_operation = 1;
	if ( ExchNode.UseStandartFTPClient ) then
		status_operation = unloadStandartClient (); 
	else
		status_operation = unloadFilesChilkat ();
	endif; 
	if ( status_operation = 0 ) then
		Output.MessageSent ( new Structure ( "Node", ExchNode.Code ) );
	else
		Output.FTPConnectionError ();	
	endif;
	
EndProcedure

Procedure unloadToDisk  ()
	
	Output.UnloadToDisk ();
	CopyFile ( TempDirectory + FileExchange, ? ( ScheduledJob, ExchNode.FolderDiskUnLoadJob, ExchNode.FolderDiskUnLoadHandle ) + "\" + FileExchange );
	Output.MessageSent ( new Structure ( "Node", ExchNode.Code ) );
		
EndProcedure

Procedure unloadToWebService ()
	
	Output.UnLoadFromWS ();
	path = TempDirectory + FileExchange;
	if ( Right ( path, 3 ) = "xml" ) then
		name = Left ( path, ( StrLen ( path ) - 3 ) ) + "zip"; 
		zip = new ZipFileWriter;
		zip.Open ( name );  
		zip.Add  ( TempDirectory + FileExchange ); 
		zip.Write ();
		deleteFile ( TempDirectory + FileExchange );
		path = zip;
	endif;
	if ( ExchangePlans.MasterNode () = undefined ) then
		folder = TempFilesDir () + "ExchangeWebService_" + IDProcess + "\" ;
		CopyFile ( path, folder + IDProcess + ".zip" );		
	else
		p = getWSPamas ();
		p.Path = path;	
		Exchange.WSWrite ( p );
	endif;
	
EndProcedure

Function getWSPamas ()
	
	p = new Structure ();
	p.Insert ( "Path", "" );
	p.Insert ( "Node", ThisNode.Code );
	p.Insert ( "Description", ThisNode.Description );
	p.Insert ( "Incoming", ExchNode.ReceivedNo );
	p.Insert ( "Outgoing", ExchNode.SentNo );
	p.Insert ( "UseClassifiers", ExchNode.UseClassifiers );
	p.Insert ( "Classifiers", ExchNode.Classifier );
	p.Insert ( "IncomingClassifiers", ExchNode.IncomingClassifiers );
	p.Insert ( "OutgoingClassifiers", ExchNode.OutgoingClassifiers );
	p.Insert ( "WebService", ExchNode.WebService );
	p.Insert ( "User", ExchNode.UserWebService );
	p.Insert ( "Password", ExchNode.PasswordWebService );
	p.Insert ( "Tenant", DF.Pick ( SessionParameters.Tenant, "Code" ) );
	p.Insert ( "Result", false );
	p.Insert ( "FileExchange", FileExchange );
	return p; 

EndFunction 

Function getThisNode ( CatalogItem )
	
	if ( CatalogItem <> Undefined ) then
		nameExchangePlan = CatalogItem.Node.Metadata ().Name;
		node = ExchangePlans [ nameExchangePlan ].ThisNode ();
		return Catalogs.Exchange.FindByCode ( node.Code );
	else
		return Catalogs.Exchange.EmptyRef (); 
	endif; 

EndFunction 

Function setScheduledJob ( CatalogItem )

	return ( ? ( ( CatalogItem = Undefined or StartUp ), true, false ) ); 
	
EndFunction

Procedure update ()
	
	if ( ScheduledJob ) then
		ReadChangesConfiguration = true;
		Connections.Lock ();
		Output.LockBase ();
	endif;
	
EndProcedure
	 
Procedure read ()
	
	if ( ( Right ( FileExchange, 3 ) = "zip" ) ) then
		zipReader = new ZipFileReader;
		zipReader.Open ( FileExchange );
		zipReader.ExtractAll ( TempDirectory );
		zipReader.Close ();
		if ( ExchNode.UseClassifiers ) then
			tenant = SessionParameters.Tenant;
			loadClassifiers ();	
			SessionParameters.Tenant = tenant;
		endif;		
		FileXml = Mid ( FileExchange, 1, StrLen ( FileExchange ) - 3 ) + "xml";
		deleteFile ( FileExchange );
	endif;
	if ( FileXml = "" ) then
		return;
	endif;
	if ( ExchNode.UseRules = Enums.ExchangeRules.Database
		or ExchNode.UseRules = Enums.ExchangeRules.File ) then
		readWithRules ( FileXml );
	else
		reader = new XMLReader;
		reader.OpenFile ( FileXml );
		messageReader = ExchangePlans.CreateMessageReader ();
		Output.ReadingChanges ();
		messageReader.BeginRead ( reader );
		try
			ExchangePlans.ReadChanges ( messageReader );
			messageReader.EndRead ();
			reader.Close ();
			#if ( Client ) then
				Output.ReceivedFromNode ( new Structure ( "Node", ExchNode.Code ) );
			#endif
		except
			reader.Close ();
			errDescription = ErrorDescription ();
			messageForUpdateEn = "Update can be performed in Designer mode.";
			messageForUpdateRu = "Обновление может быть выполнено в режиме Конфигуратор.";
			message ( errDescription );
			if ( Right ( errDescription, StrLen ( messageForUpdateEn ) ) = messageForUpdateEn
				or 
				Right ( errDescription, StrLen ( messageForUpdateRu ) ) = messageForUpdateRu ) then
				if ( ExchangePlans.MasterNode () <> Undefined ) then
					if ( ExchangePlans.MasterNode () = ExchNode.Node and ConfigurationChanged () ) then
						catObject = ExchNode.Ref.GetObject ();
						catObject.FileMessage = FileXml;
						catObject.NumbersOfErrors = 0;
						catObject.Write ();
						update ();
						Output.ReadChangesConfiguration ();
						return;
					endif;
				endif;
			endif;
			handleErrors ();
			Output.ErrorReceivingData ( new Structure ( "Error, FileXml", ErrorDescription (), FileXml ) );
			deleteFile ( FileXml );
			return;
		endtry;
	endif;
	if ( ExchangeProcessor = Undefined )
	   or
	   ( ( ExchangeProcessor <> Undefined ) and ( not ExchangeProcessor.ФлагОшибки ) ) then
		catObject = ExchNode.Ref.GetObject ();
		catObject.LastDateLoad = CurrentSessionDate ();
		catObject.FileMessage = "";
		catObject.NumbersOfErrors = 0;
		catObject.SendedEMailError = false;
		catObject.Write ();
	endif; 
	deleteFile ( FileXml );
	#if ( Client ) then
		Output.ReadingChangesComplete ( new Structure ( "Node", ExchNode.Code ) );
	#endif

EndProcedure

Procedure loadClassifiers ()
	
	file = Mid ( FileExchange, 1, StrLen ( FileExchange ) - 4 ) + "_Classifiers.xml";
	fileClassifiers = new File ( file );
	if ( not fileClassifiers.Exist () ) then
		Output.ClassifiersNotFound ();
		return;
	endif;
	if ( ExchNode.UseRulesClassifiers = Enums.ExchangeRules.Database
		or ExchNode.UseRulesClassifiers = Enums.ExchangeRules.File ) then
		readWithRules ( file );
		return;
	endif;
	reader = new XMLReader ();
	reader.OpenFile ( file );
	messageSet = ExchangePlans.CreateMessageReader ();
	try
		messageSet.BeginRead ( reader );
	except
		errorDesc = ErrorDescription (); 
		Output.ErrorReadClassifiers ( new Structure ( "Error", errorDesc ) );
		raise errorDesc;
	endtry;
	ExchangePlans.DeleteChangeRecords ( messageSet.Sender, messageSet.ReceivedNo );
	BeginTransaction ();
	while ( CanReadXML ( reader ) ) do
		try
			obj = ReadXML ( reader );	
		except
			Output.ErrorReadClassifiers ( new Structure ( "Error", ErrorDescription () ) );
			continue;
		endtry; 
		if ( obj = undefined ) then
			continue;
		endif;
		obj.DataExchange.Load = true;
		try
			obj.DataExchange.Sender = messageSet.Sender;
		except
			Output.ErrorReadClassifiers ( new Structure ( "Error", ErrorDescription () ) );
		endtry;
		try
			obj.Write ();
		except
			Output.ErrorReadClassifiers ( new Structure ( "Error", ErrorDescription () ) );
		endtry;
	enddo;
	CommitTransaction ();
	try
		messageSet.EndRead ();
	except
		Output.ErrorReadClassifiers ( new Structure ( "Error", ErrorDescription () ) );
	endtry;
	reader.Close ();
	
EndProcedure

Procedure readWithRules ( FileChanges )
	
	Output.StartReadRulesExchange ();
	processor = DataProcessors.Exchange.Create ();
	processor.ИмяФайлаОбмена = FileChanges;
	processor.РежимОбмена = "Загрузка";
	processor.Exchange = true;
	processor.ЗагружатьДанныеВРежимеОбмена = true;
	processor.ИмяФайлаПротоколаОбмена = getFileNameProtocol ();
	processor.ВыполнитьЗагрузку ();
	if ( processor.ФлагОшибки ) then
		handleErrors ( processor.ИмяФайлаПротоколаОбмена );	
	endif;
	deleteFile ( processor.ИмяФайлаПротоколаОбмена );
	
EndProcedure 

Function getFileNameProtocol ()
	
	return ( TempDirectory + "ProtocolExchangeData.txt" ); 

EndFunction 

Function createFiles ( CatalogItem )
	
	nodesArray = getNodes ( CatalogItem, true );
	mapFiles = new Map;
	for each itemNode in nodesArray do
		item = itemNode.Ref;
		if ( item <> thisNode ) then
			ExchNode = NodesData [ item ];
			ThisNode = NodesData [ itemNode.ThisNode ];
			if ( not ExchNode.UseWebService ) then
				cancel = checkFileExist ();
				if ( cancel ) then
					mapFiles.Insert ( item, new Structure ( "File, ThisNode, Cancel", "", thisNode, true ) );	
					continue;
				endif;
			endif; 
			file = fileID ( ThisNode.Code, ExchNode.Code, ExchNode.PrefixFileName );
			FileXML = TempDirectory + file + ".xml";
			if ( ExchNode.UseRules = Enums.ExchangeRules.Database
				or ExchNode.UseRules = Enums.ExchangeRules.File ) then
				makeWithRules ( false );
			else
				writeData ();
			endif;
			nameZIP = TempDirectory + file + ".zip"; 
			fileZIP = new ZipFileWriter;
			fileZIP.Open ( nameZIP );  
			fileZIP.Add ( FileXML ); 
			if ( ExchNode.UseClassifiers and ValueIsFilled ( ExchNode.ClassifierRef ) ) then
				FileXML = StrReplace ( FileXml, ".xml", "_Classifiers" ) + ".xml";
				if ( ExchNode.UseRulesClassifiers = Enums.ExchangeRules.Database
					or ExchNode.UseRulesClassifiers = Enums.ExchangeRules.File ) then
					makeWithRules ( true );
				else
					writeClassifiersData ()
				endif;
				fileZIP.Add ( FileXML );
			endif;
			fileZIP.Write ();
			mapFiles.Insert ( item, new Structure ( "File, ThisNode, Cancel", ( file + ".zip" ), itemNode.ThisNode, false ) );
			deleteFile ( FileXML );
		endif;
	enddo;
	return mapFiles;
	
EndFunction

Procedure writeData ()
	
	writerXML = new XMLWriter;
	writerXML.OpenFile ( FileXML );
	writerMessage  = ExchangePlans.CreateMessageWriter ();
	Output.WritingChanges ();
	writerMessage.BeginWrite ( writerXML, ExchNode.Node );
	ExchangePlans.WriteChanges ( writerMessage );
	writerMessage.EndWrite ();
	Output.WritingChangesComplete ();
	writerXML.Close ();
	
EndProcedure

Procedure writeClassifiersData ()
	
	writer = new XMLWriter ();
	writer.OpenFile ( FileXML, "UTF-8" );
	writer.WriteXMLDeclaration ();
	messageSet = ExchangePlans.CreateMessageWriter ();
    messageSet.BeginWrite ( writer, ExchNode.ClassifierRef );
	writer.WriteNamespaceMapping ( "xsi", "http://www.w3.org/2001/XMLSchema-instance" );
	writer.WriteNamespaceMapping ( "v8",  "http://v8.1c.ru/data" );
	changes = ExchangePlans.SelectChanges ( ExchNode.ClassifierRef, messageSet.MessageNo );
	while ( changes.Next () ) do
		try
			data = changes.Get ();
		except
			continue;
		endtry;
		WriteXML ( writer, data );
    enddo;
	messageSet.EndWrite ();
	
EndProcedure 

Procedure makeWithRules ( IsClassifier = false )
	
	ExchangeProcessor = DataProcessors.Exchange.Create ();
	newUUID = getUUID ();
	temp = true;
	if ( IsClassifier ) then
		if ( ExchNode.UseRulesClassifiers = Enums.ExchangeRules.Database ) then
			fileRulesTemporary = TempDirectory + "Rules_UUID_" + newUUID + ".xml";
			ExchNode.Ref.RulesClassifiers.Get ().Write ( fileRulesTemporary );
		else
			fileRulesTemporary = ExchNode.FileRulesClassifiers;
			temp = false;
		endif; 
	else
		if ( ExchNode.UseRules = Enums.ExchangeRules.Database ) then
			fileRulesTemporary = TempDirectory + "Rules_UUID_" + newUUID + ".xml";
			ExchNode.Ref.Rules.Get ().Write ( fileRulesTemporary );
		else
			fileRulesTemporary = ExchNode.FileRules;
			temp = false;
		endif; 
	endif; 
	ExchangeProcessor.ИмяФайлаПравилОбмена = fileRulesTemporary;
	ExchangeProcessor.ЗагрузитьПравилаОбмена ();
	node = ? ( IsClassifier, ExchNode.ClassifierRef, ExchNode.Node );
	setNodeForRules ( ExchangeProcessor.ТаблицаПравилВыгрузки.Rows, node );
	if ( temp ) then
		deleteFile ( fileRulesTemporary );
	endif; 
	ExchangeProcessor.Exchange = true;
	ExchangeProcessor.ИмяФайлаОбмена = FileXML;
	ExchangeProcessor.ВыполнитьВыгрузку ();
	
EndProcedure

Procedure setNodeForRules ( RulesTree, ItemNode )
	
	for each row in RulesTree do
		if ( row.ЭтоГруппа ) then
			setNodeForRules ( row.Rows, ItemNode );
		else
			row.СсылкаНаУзелОбмена = ItemNode;
		endif; 
	enddo; 
	
EndProcedure

Function getNodes ( CatalogItem, Unload = true )
	
	data = new Array;
	nodes = new Array ();
	if ( CatalogItem <> Undefined ) then 		
		// "hand" exchange
		thisNode = getThisNode ( CatalogItem.Ref );
		data.Add ( new Structure ( "Ref, ThisNode", CatalogItem.Ref, thisNode ) );
		nodes.Add ( CatalogItem.Ref );
		nodes.Add ( thisNode );
	else
		text = " select Ref as Ref, Node as Node, ";
		if ( Unload ) then
			text = text + "
			|case
			|	when ( Periodicity = value ( Enum.ExchangePeriodicity.Constant  ) ) then
			|		true
			|	when ( Periodicity = value ( Enum.ExchangePeriodicity.Daily ) ) and ( &Date > dateadd ( beginofperiod ( LastDateUnload, day ), day, 1 ) ) then
			|		true
			|	when ( Periodicity = value ( Enum.ExchangePeriodicity.Weekly ) ) and ( &Date > dateadd ( beginofperiod ( LastDateUnload, day ), week, 1 ) ) then
			|		true                                                                                                                                          	
			|	when ( Periodicity = value ( Enum.ExchangePeriodicity.Monthly ) ) and ( &Date > dateadd ( beginofperiod ( LastDateUnload, day ), month, 1 ) ) then
			|		true
	 		|	when ( Periodicity = value ( Enum.ExchangePeriodicity.Quarterly ) )	and ( &Date > dateadd ( beginofperiod ( LastDateUnload, day ), quarter, 1 ) ) then
			|		true
        	|	when ( Periodicity = value ( Enum.ExchangePeriodicity.Yearly ) ) and ( &Date > dateadd ( beginofperiod ( LastDateUnload, day ), year, 1 ) ) then
			|		true
			|	else 
			|		false
			|	end as Actual 
			|";
		else 
			text = text + " true AS Actual ";
		endif;
		text = text + " 
		|from Catalog.Exchange 
		|where Ref.UseAutomatic
		|	and 
		|	case
		|		when &MasterNode = undefined and OperationType = value ( Enum.ExchangeTypes.WebService ) 
		|			then false
		|		else true
		|	end
		|";
		// scheduled job ExchangePlans 
		q = new Query ( text );
		q.SetParameter ( "Date", CurrentSessionDate () );
		q.SetParameter ( "MasterNode", ExchangePlans.MasterNode () );
		result = q.Execute ().Select ();
		while result.FindNext ( new Structure ( "Actual", true ) ) do
			thisNode = getThisNode ( result.Ref );
			data.Add ( new Structure ( "Ref, ThisNode, UseRules", result.Ref, thisNode, result.UseRules ) );
			nodes.Add ( result.Ref );
			nodes.Add ( thisNode );
		enddo;			
	endif;
	fillNodesData ( nodes );
	return data;
	
EndFunction

Function createTempDir ();
	
	folder = new File ( TempFilesDir () + "ExchangeDataTemp_" + IDProcess );
	// delete directory anyway
	if ( folder.Exist () ) then
		deleteFile ( folder.FullName );
	endif;
	CreateDirectory ( folder.FullName );
	return ( folder.FullName + "\" );
	
EndFunction

Procedure deleteFile ( File )
	
	try
		DeleteFiles ( File );
	except
		Output.FileDeletionError ( new Structure ( "File, Error", File, ErrorDescription () ) );	
	endtry;
	
EndProcedure

Function getFTPStandartClient ()
	
	try
		FTP = new FTPConnection ( ExchNode.ServerFTPLoad, ExchNode.PortFTPLoad,
			ExchNode.UserFTPLoad, ExchNode.PasswordFTPLoad, , true );	
	except
		FTP = Undefined;
	endtry; 
	return FTP; 

EndFunction

Procedure handleErrors ( AttachedObjects = Undefined )
	
	catObject = ExchNode.Ref.GetObject ();
	SendReport = not catObject.SendedEMailError and ( catObject.NumbersOfErrors >= catObject.MaximumErrors );
	catObject.NumbersOfErrors = catObject.NumbersOfErrors + 1;
	if ( SendReport and catObject.SendEMailErrors ) then
		if ( ScheduledJob ) then
			// send email if scheduled job
			senErrorReport ( AttachedObjects );
			catObject.SendedEMailError = true;
		endif;
	endif; 
	catObject.Write ();
	
EndProcedure

Procedure senErrorReport ( AttachedObjects )
	
	subject = Output.SubjectErrorReport ( new Structure ( "Node, CurrentDate", ExchNode.Code, CurrentSessionDate () ) );
	if ( CounterFiles = 0 ) then
		s = Output.TextMessageEmailErrorReportNoNewExchangeFiles ( new Structure ( "Node, CurrentDate, MaximumErrors, Tenant", ExchNode.Code, CurrentSessionDate (), ExchNode.MaximumErrors, ExchNode.PrefixFileName ) );
	elsif ( ExchangeProcessor <> Undefined ) then
		s = Output.TextMessageEmailErrorReportXML ( new Structure ( "Node, CurrentDate, MaximumErrors, Tenant", ExchNode.Code, CurrentSessionDate (), ExchNode.MaximumErrors, ExchNode.PrefixFileName ) );
	else
		s = Output.TextMessageEmailErrorReport ( new Structure ( "Node, CurrentDate, Error, MaximumErrors, Tenant", ExchNode.Code, CurrentSessionDate (), Error, ExchNode.MaximumErrors, ExchNode.PrefixFileName ) );
	endif; 
	receivers = getTableReceivers ();
	if ( receivers.Count () ) then
		Exchange.SendEMailServer ( AttachedObjects, subject, s, receivers );		
	endif; 
	
EndProcedure

Function getTableReceivers ()
	
	s = "
	|select Users.User as User, Users.User.Email as EMailAddress
	|from Catalog.Exchange.Receivers as Users
	|where Users.ref = &ref
	|";
	query = new Query ( s );
	query.SetParameter ( "ref", ExchNode.Ref );		
	return ( query.Execute ().Unload () );

EndFunction

Procedure checkCounterFiles ()
	
	if ( CounterFiles = 0 ) then
		Output.NoNewExchangeFiles ();
	endif;	
	
EndProcedure

Function getEmailProfile ( Node )
	
	profile = new InternetMailProfile;
	profile.POP3ServerAddress = TrimAll ( Node.ServerPOP3 );
	profile.User = TrimAll ( Node.UserEmail );
	profile.Password = TrimAll ( Node.PasswordEmail );
	profile.POP3Port = Node.PortPOP3;
	profile.Timeout = Node.ServerTimeOut;
	profile.POP3UseSSL = Node.UseSSL;
	profile.SMTPServerAddress = TrimAll ( Node.ServerSMTP );
	profile.SMTPUser = TrimAll ( Node.UserEmail );
	profile.SMTPPassword = TrimAll ( Node.PasswordEmail );
	profile.SMTPAuthentication = SMTPAuthenticationMode.Login;
	profile.SMTPPort = Node.PortSMTP;
	profile.SMTPUseSSL = Node.UseSSL;
	return profile;

EndFunction

Function checkFileExist ()
	
	Output.CheckPreviousFileExchange ();
	FileMask = fileID ( ThisNode.Code, ExchNode.Code, ExchNode.PrefixFileName ) + "*";
	operation_type = ExchNode.OperationType;
	cancel = false;
	if ( operation_type = Enums.ExchangeTypes.Email ) then
		// code ...
	elsif ( operation_type = Enums.ExchangeTypes.FTP ) then
		cancel = checkFileExistFtp ();
	endif;
	return ( cancel ); 
	
EndFunction

Function checkFileExistFtp ()
	
	if ( StrLen ( ExchNode.FolderFTPUnLoad ) > 0 ) then
		catalogUnload = ExchNode.FolderFTPUnLoad + "/";
	else
		catalogUnload = "";
	endif;
	cancel = false;
	FileMask = fileID ( ThisNode.Code, ExchNode.Code, ExchNode.PrefixFileName );
	if ( ExchNode.UseStandartFTPClient ) then
		cancel = checkStandartClient ( catalogUnload );
	else
		cancel = checkChilkat ( catalogUnload );		
	endif;
	return cancel; 

EndFunction

Procedure loadStandartClient ( CatalogLoad )
	
	FTP = getFTPStandartClient ();
	if ( FTP = Undefined ) then
		Output.FTPConnectionError ();
		return;	
	endif; 
	FTP.SetCurrentDirectory ( CatalogLoad );
	arrayFiles = FTP.FindFiles ( FTP.GetCurrentDirectory (), FileMask );
	for each fileFromFtp  in arrayFiles do
		FTP.Get ( fileFromFtp.FullName, TempDirectory + fileFromFtp.Name );
		FTP.Delete ( fileFromFtp.FullName );
	enddo;
	
EndProcedure

Procedure loadFilesChilkat ( CatalogLoad )
	
	FTP = getFTPChilkatClient ();
	if ( FTP = Undefined ) then
		Output.FTPConnectionError ();
		return;	
	endif;
	FTP.ChangeRemoteDir ( CatalogLoad );
	arrayFiles = findFilesChilkat ();
	for each fileFromFtp  in arrayFiles do
		FTP.GetFile ( fileFromFtp, TempDirectory + fileFromFtp );
		FTP.DeleteRemoteFile ( fileFromFtp )
	enddo;
	FTP.Disconnect ();
	
EndProcedure

Function unloadStandartClient ()	
	
	StatusOperation = 1;
	if ( StrLen ( ExchNode.FolderFTPLoad ) > 0 ) then
		folder = ExchNode.FolderFTPUnLoad + "/";
	else
		folder = "";
	endif;
	FTP = getFTPStandartClient ();
	if ( FTP = Undefined ) then
		Output.FTPConnectionError ();
	else
		FTP.Put ( TempDirectory + FileExchange, folder + FileExchange );	
		StatusOperation = 0;
	endif; 
	return StatusOperation;
	
EndFunction

Function unloadFilesChilkat ()
	
	StatusOperation = 1;
	if ( StrLen ( ExchNode.FolderFTPLoad ) > 0 ) then
		folder = ExchNode.FolderFTPUnLoad;
	else
		folder = "";
	endif;
	FTP = getFTPChilkatClient ();
	if ( FTP = Undefined ) then
		Output.FTPConnectionError ();
	else
		FTP.ChangeRemoteDir ( folder );
		FTP.PutFile ( ( TempDirectory + FileExchange ), FileExchange );
		StatusOperation = 0;
	endif; 
	return ( StatusOperation ); 
	
EndFunction

Function getFTPChilkatClient ()
	
	obj = undefined;
	connection = CoreLibrary.Chilkat ( "Ftp2" );
	connection.Hostname = ExchNode.ServerFTPLoad;
	connection.Username = ExchNode.UserFTPLoad;
	connection.Password = ExchNode.PasswordFTPLoad;
	connection.Port = ExchNode.PortFTPLoad;
	// connection.Passive = 0;
	connection.PassiveUseHostAddr = 1;
	success = connection.Connect ();
	if ( success = 1 ) then
		obj = connection;	
	endif; 
	return obj; 

EndFunction

Function findFilesChilkat ()
	
	arrayFiles = new Array;
	countFilesAndDirs = FTP.NumFilesAndDirs;
	if ( countFilesAndDirs > 0 ) then
		for counter = 0 to ( countFilesAndDirs - 1 ) do
			if ( FTP.GetIsDirectory ( counter ) = 1 ) then
				continue;
			endif;
			file = FTP.GetFileName ( counter );
			if ( Find ( file, FileMask ) > 0 ) then
				arrayFiles.Add ( file ); 
			endif; 
		enddo; 
	endif;
	return arrayFiles; 
	
EndFunction 

Function checkStandartClient ( CatalogLoad )
	
	FTP = getFTPStandartClient ();
	if ( FTP = Undefined ) then
		Output.FTPConnectionError ();
		cancel = true;
	else 
		cancel = false;
	endif; 
	return cancel; 
	
EndFunction

Function checkChilkat ( CatalogUnLoad )
	
	FTP = getFTPChilkatClient ();
	if ( FTP = Undefined ) then
		Output.FTPConnectionError ();
		cancel = true;
	else 
		cancel = false;
	endif; 
	return cancel;

EndFunction

Procedure fillNodesData ( ArrayNodes )
	
	NodesData = new Map;
	s = "
	|select Settings.Ref as Ref, Settings.Code as Code, Settings.Description as Description, Settings.FolderFTPLoad as FolderFTPLoad,
	|	Settings.FolderFTPUnLoad as FolderFTPUnLoad, Settings.EMailLoad as EMailLoad, Settings.EMailUnLoad as EMailUnLoad, 
	|	Settings.InformationRules as InformationRules, Settings.LastDateLoad as LastDateLoad, Settings.Periodicity as Periodicity, 
	|	Settings.FileMessage as FileMessage, Settings.LastExchange as LastExchange, Settings.LastDateUnload as LastDateUnload, 
	|	Settings.MaximumErrors as MaximumErrors, Settings.FileRules as FileRules, Settings.Node as Node, Settings.Node.SentNo as SentNo,
	|	Settings.Node.ReceivedNo as ReceivedNo,Settings.Node.Description as NodeDescription, Settings.NumbersOfErrors as NumbersOfErrors,
	|	Settings.OperationType as OperationType, Settings.PasswordEmail as PasswordEmail, Settings.PasswordFTPLoad as PasswordFTPLoad,
	|	Settings.PasswordFTPUnLoad as PasswordFTPUnLoad, Settings.FolderFTPClient as FolderFTPClient, Settings.FolderFTPClientJob as FolderFTPClientJob, 
	|	Settings.FolderDiskLoadHandle as FolderDiskLoadHandle, Settings.FolderDiskLoadScheduledJob as FolderDiskLoadScheduledJob,
	|	Settings.FolderDiskUnLoadHandle as FolderDiskUnLoadHandle, Settings.FolderDiskUnLoadJob as FolderDiskUnLoadJob, Settings.PortFTPLoad as PortFTPLoad, 
	|	Settings.PortFTPUnLoad as PortFTPUnLoad, Settings.PortPOP3 as PortPOP3, Settings.PortSMTP as PortSMTP, Settings.PrefixFileName as PrefixFileName, 
	|	Settings.RegisterInSequenceCost as RegisterInSequenceCost, Settings.SendedEMailError as SendedEMailError, Settings.SendEMailErrors as SendEMailErrors,
	|	Settings.ServerFTPLoad as ServerFTPLoad, Settings.ServerFTPUnLoad as ServerFTPUnLoad, Settings.ServerPOP3 as ServerPOP3, 
	|	Settings.ServerSMTP as ServerSMTP, Settings.ServerTimeOut as ServerTimeOut, Settings.UpdateConfiguration as UpdateConfiguration,
	|	Settings.UseAutomatic as UseAutomatic, Settings.UserEmail as UserEmail, Settings.UserFTPLoad as UserFTPLoad,
	|	Settings.UserFTPUnLoad as UserFTPUnLoad, Settings.UserTenant as UserTenant, Settings.UseRules as UseRules, Settings.UseSSL as UseSSL, 
	|	Settings.UseStandartFTPClient as UseStandartFTPClient, Settings.Presentation as Presentation, Settings.WebService as WebService,
	|	Settings.UserWebService as UserWebService, Settings.PasswordWebService as PasswordWebService, Settings.UseClassifiers as UseClassifiers,
	|	Settings.UseRulesClassifiers as UseRulesClassifiers, Settings.Node.Classifiers as Classifier,
	|	isnull ( Classifiers.Ref, value ( ExchangePlan.Classifiers.EmptyRef ) ) as ClassifierRef,
	|	isnull ( Classifiers.ReceivedNo, 0 ) as IncomingClassifiers, isnull ( Classifiers.SentNo, 0 ) as OutgoingClassifiers,
	|	case when Settings.OperationType = value ( Enum.ExchangeTypes.WebService ) then true else false end as UseWebService,
	|	Settings.FileRulesClassifiers as FileRulesClassifiers
	|from Catalog.Exchange as Settings
	|	//
	|	//
	|	//
	|	left join ExchangePlan.Classifiers as Classifiers
	|	on Settings.Node.Classifiers = Classifiers.Code
	|where Settings.Ref in ( &ArrayNodes )
	|";
	q = new Query ( s );
	q.SetParameter ( "ArrayNodes", ArrayNodes );
	q.SetParameter ( "Tenant", SessionParameters.Tenant );
	result = q.Execute ();
	selection = result.Select ();
	while selection.Next () do
		data = new Structure ();
		for each column in result.Columns do
			data.Insert ( column.Name, selection [ column.Name ] );	
		enddo;
		NodesData.Insert ( selection.Ref, data )
	enddo;
	
EndProcedure 

Function getUUID ()
	
	return String ( new UUID () ); 
	
EndFunction

#endif