#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function CreateImage ( Node, Folder ) export
	
	SetPrivilegedMode ( true );
	data = getData ( Node );
	if ( not ValueIsFilled ( data.Classifiers ) ) then
		Output.ClassifiersNotSelected ( new Structure ( "Node", Node ) );
		return false; 
	endif;
	temp = makeTempDir ();
	connection = getConnection ( temp );
	ExchangePlans.CreateInitialImage ( data.Ref, connection );
	MoveFile ( temp + "\1Cv8.1CD", Folder + "\1Cv8.1CD" );
	ExchangePlans.DeleteChangeRecords ( data.Ref );
	DeleteFiles ( temp );
	recordClassifiers ( data );
	unloadClassifiers ( data, Folder );
	unloadData ( data, Folder );
	runScript ( Folder );
	SetPrivilegedMode ( false );
	return true; 
	
EndFunction

Function getData ( Node )
	
	s = "
	|select PlanFull.Ref as Ref, PlanFull.ThisNode as ThisNode, PlanFull.Code as Code, PlanFull.Description as Description,
	|	PlanFull.SentNo as SentNo, PlanFull.ReceivedNo as ReceivedNo, PlanFull.Classifiers as Classifiers, 
	|	PlanFull.Presentation as Presentation, isnull ( PlanClassifiers.Ref, value ( ExchangePlan.Classifiers.EmptyRef ) ) as ClassifiersRef  
	|from ExchangePlan.Full as PlanFull
	|	left join ExchangePlan.Classifiers as PlanClassifiers
	|	on PlanFull.Classifiers = PlanClassifiers.Code
	|		and PlanClassifiers.Tenant = &Tenant 
	|where PlanFull.Ref = &Node
	|";
	q = new Query ( s );
	q.SetParameter ( "Node", Node );
	q.SetParameter ( "Tenant", SessionParameters.Tenant );
	return q.Execute ().Unload () [ 0 ]; 

EndFunction

Function makeTempDir ();
	
	tempDir = new File ( TempFilesDir () + "InitialImage_" + String ( new UUID () ) );
	if ( tempDir.Exist () ) then
		DeleteFiles ( tempDir.FullName );
	endif;
	CreateDirectory ( tempDir.FullName );
	return ( tempDir.FullName );
	
EndFunction

Function getConnection ( Folder )

	return ( "File=""" + Folder + """;Locale=""" + InfoBaseLocaleCode () + """;" );
	
EndFunction 

Procedure recordClassifiers ( Data )
	
	if ( not ValueIsFilled ( Data.ClassifiersRef ) ) then
		a = new Structure ();
		a.Insert ( "Code", Data.Code );
		a.Insert ( "Description", Data.Description );
		a.Insert ( "SentNo", Data.SentNo );
		a.Insert ( "ReceivedNo", Data.ReceivedNo );
		objectNode = Data.Ref.GetObject ();
		Data.Classifiers = Data.Code;
		Data.ClassifiersRef = createClassifiers ( a );
		objectNode.Classifiers = Data.Code;
		objectNode.Write ();		
	endif;
	enrollNode ( Data.ClassifiersRef, Metadata.ExchangePlans.Classifiers );
	
EndProcedure

Function createClassifiers ( Data )
	                                                                 
	classifiers = ExchangePlans.Classifiers.CreateNode ();
	FillPropertyValues ( classifiers, Data );
	classifiers.Write ();
	return classifiers.Ref; 

EndFunction 

Procedure enrollNode ( Node, Plan )
	
	for each item in Plan.Content do
		ExchangePlans.RecordChanges ( Node, item.Metadata );
	enddo;
	
EndProcedure

Procedure unloadClassifiers ( Data, Folder ) export 
	
	fileName = Folder + "\ClassifiersData.xml";
	writeClassifiers ( Data, fileName );
	
EndProcedure

Procedure writeClassifiers ( DataNode, File )	
	
	writer = new XMLWriter ();
	writer.OpenFile ( File, "UTF-8" );
	writer.WriteXMLDeclaration ();
	messageSet = ExchangePlans.CreateMessageWriter ();
    messageSet.BeginWrite ( writer, DataNode.ClassifiersRef );
	writer.WriteNamespaceMapping ( "xsi", "http://www.w3.org/2001/XMLSchema-instance" );
	writer.WriteNamespaceMapping ( "v8",  "http://v8.1c.ru/data" );
	changes = ExchangePlans.SelectChanges ( DataNode.ClassifiersRef, messageSet.MessageNo );
	while ( changes.Next () ) do
		try
			data = changes.Get ();
		except
			continue;
		endtry;
		WriteXML ( writer, data );
    enddo;
	messageSet.EndWrite ();
	obj = DataNode.ClassifiersRef.GetObject ();
	obj.SentNo = 0;
	obj.ReceivedNo = 0;
	obj.Write ();
	ExchangePlans.DeleteChangeRecords ( DataNode.ClassifiersRef );
	
EndProcedure

Procedure unloadData ( Data, Folder )
	
	dataMap = new Map;
	fillNodesClassifiers ( Data.ClassifiersRef, dataMap );
	writeFileData ( dataMap, Folder );	
	
EndProcedure

Procedure fillNodesClassifiers ( Classifier, DataMap )
	
	s = "
	|select
	|// future slave node 
	|	PlanClassifiers.Code as Code, PlanClassifiers.Description as Description
	|from ExchangePlan.Classifiers as PlanClassifiers
	|where PlanClassifiers.ThisNode and PlanClassifiers.Tenant = &Tenant
	|;
	|// future this node
	|select
	|	PlanClassifiers.Code as Code, PlanClassifiers.Description as Description, 
	|	PlanClassifiers.SentNo as SentNo, PlanClassifiers.ReceivedNo as ReceivedNo
	|from ExchangePlan.Classifiers as PlanClassifiers
	|where PlanClassifiers.Ref = &Ref and PlanClassifiers.Tenant = &Tenant
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Classifier );
	q.SetParameter ( "Tenant", SessionParameters.Tenant );
	result = q.ExecuteBatch ();
	selection0 = result [ 0 ].Select ();
	selection0.Next ();
	selection1 = result [ 1 ].Select ();
	selection1.Next ();
	data0 = new Structure ( "Code, Description, SentNo, ReceivedNo" );
	data0.Code = selection0.Code;
	data0.Description = selection0.Description;
	data0.SentNo = selection1.SentNo;
	data0.ReceivedNo = selection1.ReceivedNo;
	DataMap.Insert ( "Slave", data0 );
	data1 = new Structure ( "Code, Description, SentNo, ReceivedNo" );
	data1.Code = selection1.Code;
	data1.Description = selection1.Description;
	data1.SentNo = 0;
	data1.ReceivedNo = 0;
	DataMap.Insert ( "Main", data1 );
	
EndProcedure 

Procedure writeFileData ( DataMap, Folder )
	
	serializer = new XDTOSerializer ( XDTOFactory );
	writer = new XMLWriter ();
	writer.OpenFile ( Folder + "\FillingData.xml" );
	serializer.WriteXML ( writer, DataMap );
	
EndProcedure 

Procedure runScript ( Folder)
	
	pathScript = Folder  + "\script.vbs";
	script = new TextWriter ( pathScript, TextEncoding.ANSI );
	textScript = getTextScript ( Folder );
	script.Write ( textScript ); 
	script.Close ();
	RunApp ( pathScript );
	
EndProcedure 

Function getTextScript ( Folder )
	
	script = GetTemplate ( "Script" ).GetText ();
	pathProgram = BinDir () + "1cv8c.exe"; // !!!!! 1cv8c - thin client
	script = StrReplace ( script, "%FileProgram%", pathProgram );
	script = StrReplace ( script, "%StringDataBase%", getStringDataBase ( Folder ) );
	return script; 	
	
EndFunction 

Procedure ReadData () export
	
	DataMap = readMap ();
	if ( DataMap = undefined ) then
		return;
	endif; 
	//@skip-warning
	fillClassifier ( DataMap [ "Main" ] );
	//@skip-warning
	data = DataMap [ "Slave" ];
	a = new Structure ();
	a.Insert ( "Code", data.Code );
	a.Insert ( "Description", data.Description );
	a.Insert ( "SentNo", data.SentNo );
	a.Insert ( "ReceivedNo", data.ReceivedNo );
	createClassifiers ( a );
	
EndProcedure

Function readMap ()
	
	result = undefined;
	stringConnection = getStringConnection ();
	fileName = stringConnection + "\FillingData.xml";
	if ( checkFile ( fileName ) ) then
		serializer = new XDTOSerializer ( XDTOFactory );
		reader = new XMLReader ();
		reader.OpenFile ( fileName );
		result = serializer.ReadXML ( reader, Type ( "Map" ) );
		reader.Close ();
	endif;
	if ( result <> undefined ) then
		deleteFile ( fileName );
	endif; 
	return result; 
	
EndFunction 

Procedure fillClassifier ( Data )
	
	s = "
	|select top 1
	|	PlanClassifiers.Ref as Classifiers
	|from ExchangePlan.Classifiers as PlanClassifiers
	|where PlanClassifiers.ThisNode
	|"; 
	q = new Query ( s );
	result = q.Execute ();
	selection = result.Select ();
	selection.Next ();
	objectNode = selection.Classifiers.GetObject ();
	objectNode.Code = Data.Code;
	objectNode.Description = Data.Description;
	objectNode.Write ();
	
EndProcedure

Procedure ReadChanges () export 
	
	stringConnection = getStringConnection ();
	fileName = stringConnection + "\ClassifiersData.xml";
	if ( checkFile ( fileName ) ) then
		reader = new XMLReader ();
		reader.OpenFile ( fileName );
		messageSet = ExchangePlans.CreateMessageReader ();
		try
			messageSet.BeginRead ( reader );
		except
			Output.ErrorReadClassifiers ( new Structure ( "Error", ErrorDescription () ) );
			raise;
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
	endif;
	setClassifiers ();
	deleteFile ( fileName );
	                                                
EndProcedure

Procedure setClassifiers ()
	
	q = new Query ( "select top 1 Plan.Ref as Ref from ExchangePlan.Classifiers as Plan where not Plan.ThisNode" );
	result = q.Execute ();
	selection = result.Select ();
	while selection.Next () do
		obj = selection.Ref.GetObject ();
		obj.SentNo = 0;
		obj.ReceivedNo = 0;
		obj.Write ();
	enddo;
	
EndProcedure 

Function getStringConnection () export 
	
	return ( NStr ( InfoBaseConnectionString (), "File" ) );
	
EndFunction

Function getStringDataBase ( Folder )
	
	return ( " /F " + """""" + Folder + """""" );	

EndFunction

Function checkFile ( Name )
	
	file = new File ( Name );
	return ( file.Exist () ); 

EndFunction

Procedure deleteFile ( File )
	
	try
		DeleteFiles ( File );
	except
		Output.FileDeletionError ( new Structure ( "File, Error", File, ErrorDescription () ) );	
	endtry;
	
EndProcedure

Procedure FillTenant () export
	
	s = "
	|select top 1 Ref from Catalog.Tenants
	|;
	|select Ref from ExchangePlan.Classifiers where Tenant = value ( Catalog.Tenants.EmptyRef )
	|";
	q = new Query ( s );
	result = q.ExecuteBatch ();
	if ( not result [ 0 ].IsEmpty () ) then
		selection = result [ 0 ].Select ();
		selection.Next ();
		tenant = selection.Ref;
		classifiers = result [ 1 ].Select ();
		while ( classifiers.Next () ) do
			obj = classifiers.Ref.GetObject ();
			obj.Tenant = tenant;
			obj.Write ();			
		enddo;
	endif; 
	
EndProcedure

#endif