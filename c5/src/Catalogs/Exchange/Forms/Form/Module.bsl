
&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
	else
		dataNode = getDataNode ( Object.Node, new Structure ( "Code, ExchangePlanNode, ReceivedNo, SentNo" ) );
		if ( dataNode = undefined ) then
			CodeNode = "";
			ExchangePlanNode = "";
			ReceivedNo = 0;
			SentNo = 0;
		else
			CodeNode = dataNode.Code;
			ExchangePlanNode = dataNode.ExchangePlanNode;
			ReceivedNo = dataNode.ReceivedNo;
			SentNo = dataNode.SentNo;
		endif;
	endif;
	MasterNode = false; // ( ExchangePlans.MasterNode () = undefined );
	TypeExchange = ? ( Object.UseAutomatic, 1, 2 );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|PageEmail show Object.OperationType = Enum.ExchangeTypes.Email;
	|PageFTP show Object.OperationType = Enum.ExchangeTypes.FTP;
	|PageNetworkDisk show Object.OperationType = Enum.ExchangeTypes.NetworkDisk;
	|PageWebService show Object.OperationType = Enum.ExchangeTypes.WebService;
	|FileRules LoadRules UnloadRules InformationRules enable inlist ( Object.UseRules, Enum.ExchangeRules.File, Enum.ExchangeRules.Database );
	|FileRulesClassifiers LoadRulesClassifiers UnloadRulesClassifiers InformationRulesClassifiers enable inlist ( Object.UseRulesClassifiers, Enum.ExchangeRules.File, Enum.ExchangeRules.Database )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure fillNew ()	
	
	Object.OperationType = Enums.ExchangeTypes.NetworkDisk; 
	Object.UseAutomatic = true;
	Object.UseClassifiers = true;
	Object.Periodicity = Enums.ExchangePeriodicity.Constant;
	Object.UpdateConfiguration = false;
	Object.NumbersOfErrors = 3;
	tenant = SessionParameters.Tenant;
	Object.PrefixFileName = ? ( ValueIsFilled ( tenant ), tenant.Code, "" );
	
EndProcedure

&AtServerNoContext
Function getDataNode ( Node, Attributes = undefined )
	
	if ( not ValueIsFilled ( Node ) ) then
		return undefined;
	endif;
	s = "
	|select Plan.Ref as Ref, Plan.Code as Code, Plan.Description as Description, Plan.SentNo as SentNo, Plan.ReceivedNo as ReceivedNo
	|from ExchangePlan." + Node.Metadata ().Name + " AS Plan
	|where Plan.Ref = &Node
	|";
	q = new Query ( s );
	q.SetParameter ( "Node", Node );		
	result = Conversion.RowToStructure ( q.Execute ().Unload () );
	if ( Attributes = undefined ) then
		return result;
	elsif ( TypeOf ( Attributes ) = Type ( "Structure" ) ) then
		data = new Structure;
		for each item in Attributes do
			if ( item.Key = "ExchangePlanNode" ) then
				data.Insert ( item.Key, Node.Metadata ().Synonym );			
			else
				data.Insert ( item.Key, result [ item.Key ] );				
			endif; 
		enddo; 
	endif;
	return data; 
	
EndFunction 

&AtClient
Procedure OnOpen ( Cancel )
	
	setEnableRules ();
	setEnableRules ( "Classifiers" );
	setEnablePeriodicity ();
	fillNode ();
	
EndProcedure

&AtClient  
Procedure setEnableRules ( Postfix = "" )
	
	field = "UseRules" + Postfix;
	info = "InformationRules" + Postfix;
	control = Items [ info ];
	if ( Object [ field ] = PredefinedValue ( "Enum.ExchangeRules.None" ) ) then
		control.Title = "";
	else
		control.Title = Object [ info ];
	endif; 
	Appearance.Apply ( ThisObject, "Object." + field );
	
EndProcedure

&AtClient
Procedure setEnablePeriodicity ()
	
	Items.Periodicity.Enabled = Object.UseAutomatic; 
	
EndProcedure

&AtClient
Procedure LoadRules ( Command )
	
	loadFileRules ();
	
EndProcedure

&AtClient
Procedure UnloadRules ( Command )
	
	unloadFileRules ();
	
EndProcedure

&AtClient
Procedure ChooseFiles ( Result, Params ) export
	
	if ( Params.Property ( "FileDialogMode" ) ) then
		mode = Params.FileDialogMode;
	else
		mode = FileDialogMode.Open;
	endif; 
	dialog = new FileDialog ( mode );
	dialog.Multiselect = false;
	dialog.Filter = "XML (*.xml)|*.xml";
	dialog.Show ( new NotifyDescription ( "SelectFiles", ThisObject, Params ) );
	
EndProcedure

&AtClient
Procedure SelectFiles ( Files, Params ) export
	
	if ( Files = undefined ) then
		return;
	endif;
	if ( Params.Command = "Load" ) then
		loadFile ( Files [ 0 ], Params );
	elsif ( Params.Command = "Unload" ) then
		saveFile ( Files [ 0 ], Params );		
	endif;
	
EndProcedure

&AtClient
Procedure loadFile ( File, Params )
	
	files = new Array ();
	files.Add ( new TransferableFileDescription ( File ) );
	BeginPuttingFiles ( new NotifyDescription ( "Loading", ThisObject, Params ), files, , false );
	
EndProcedure

&AtClient
Procedure Loading ( Result, Params ) export
	
	dataFile = Result [ 0 ];
	newFile = new File ( dataFile.Name );
	postfix = Params.Postfix;
	Object [ "FileRules" + postfix ] = dataFile.Name;
	info = "";
	setRules ( newFile.Name, dataFile.Location, info, postfix );
	Items [ "InformationRules" + postfix ].Title = info;
	Object [ "InformationRules" + postfix ] = info; 
	
EndProcedure

&AtServer 
Procedure setRules ( File, Location, Info, Postfix )
	
	currentObject = FormAttributeToValue ( "Object" );
	binData = GetFromTempStorage ( Location );
	currentObject [ "Rules" + Postfix ] = new ValueStorage ( binData, new Deflation ( 9 ) );
	currentObject.Write ();
	ValueToFormAttribute ( currentObject, "Object" );
	Info = Output.InformationAboutFileRules ( new Structure ( "File, Size, SaveTime", File, binData.Size (), CurrentDate () ) );
	DeleteFromTempStorage ( Location );			
	
EndProcedure 

&AtClient  
Procedure saveFile ( File, Params )	
	
	address = getRules ( Params.Postfix );
	data = GetFromTempStorage ( address );
	data.Write ( File );
	
EndProcedure

&AtServer
Function getRules ( Postfix )
	
	currentObject = FormAttributeToValue ( "Object" );
	data = currentObject [ "Rules" + Postfix ].Get ();
	return  PutToTempStorage ( data );

EndFunction 

&AtClient
Procedure PathNetworkStartChoice ( Item, ChoiceData, StandardProcessing )
	
	selectDirectory ( Item.Name );
	
EndProcedure

&AtClient
Procedure selectDirectory ( Name )
	
	p = new Structure ( "Attribute", Name );
	LocalFiles.Prepare ( new NotifyDescription ( "OpenDialog", ThisObject, p ) );	
	
EndProcedure 

&AtClient
Procedure OpenDialog ( Result, Params ) export
	
	dialog = new FileDialog ( FileDialogMode.ChooseDirectory );
	dialog.Directory = getDirectory ( Params.Attribute );
	dialog.Show ( new NotifyDescription ( "SetAttribute", ThisObject, Params ) );
	
EndProcedure 

&AtClient
Procedure SetAttribute ( Result, Params ) export
	
	if ( Result = undefined ) then
		return;
	endif; 
	Object [ Params.Attribute ] = Result [ 0 ];
	Modified = true;
	
EndProcedure

&AtClient
Function getDirectory ( Attribute )
	
	path = Object [ Attribute ];
	directory = "";
	if ( path = "" ) then
		return directory;
	endif; 
	c = StrLen ( path );
	while c > 0 do
		if ( Mid ( path, c, 1 ) = "\" ) then
			directory = Mid ( path, 1, ( c - 1 ) );
			break;
		endif; 
		c = c - 1;		
	enddo;
	return directory; 

EndFunction 

&AtClient
Procedure UseRulesOnChange ( Item )
	
	setEnableRules ();
	
EndProcedure

&AtClient
Procedure TypeExchangeOnChange ( Item )
	
	Object.UseAutomatic = ? ( TypeExchange = 1, true, false );
	setEnablePeriodicity ();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( ValueIsFilled ( CurrentObject.Node ) and CurrentObject.Ref.IsEmpty () ) then
		Cancel = checkNode ( CurrentObject.Node );
	endif;
	if ( not Cancel ) then
		writeNumber ( CurrentObject.Node );
	endif; 
	
EndProcedure

&AtServer
Function checkNode ( Node )
	
	q = new Query ( "select Catalog.Ref as Ref from Catalog.Exchange as Catalog where Catalog.Node = &Node" );
	q.SetParameter ( "Node", Node );		
	result = q.Execute ();
	if ( result.IsEmpty () ) then
		error = false
	else
		error = true;
		Output.ExchangeDataItemAlreadyExist ( new Structure ( "Code", Node.Code ) );
	endif;
	return error; 
		
EndFunction 

&AtServer 
Procedure writeNumber ( Node )
	
	object_node = Node.GetObject ();
	writeNode = false;
	if ( object_node.ReceivedNo <> ReceivedNo ) then
		object_node.ReceivedNo = ReceivedNo;
		writeNode = true;
	endif;
	if ( object_node.SentNo <> SentNo ) then
		object_node.SentNo = SentNo;
		writeNode = true;
	endif;
	if ( writeNode ) then
		object_node.Write ();	
	endif; 
	
EndProcedure 

&AtClient
Procedure NodeOnChange ( Item )
	
	fillNode ();
	
EndProcedure

&AtClient
Procedure fillNode ()
	
	if ( ValueIsFilled ( Object.Node ) ) then
		dataNode = getDataNode ( Object.Node, new Structure ( "Code, ExchangePlanNode, ReceivedNo, SentNo" ) );
		if ( dataNode = undefined ) then
			clearNode ();
		else
			Object.Code = dataNode.Code;
			CodeNode = dataNode.Code;
			ExchangePlanNode = dataNode.ExchangePlanNode;
			ReceivedNo = dataNode.ReceivedNo;
			SentNo = dataNode.SentNo;
		endif;		
	else
		clearNode ();
	endif; 
	
EndProcedure 

&AtClient
Procedure clearNode ()
	
	CodeNode = "";
	ExchangePlanNode = "";
	ReceivedNo = 0;
	SentNo = 0;
	Object.Code = "";
	
EndProcedure 

&AtClient
Procedure NodeClearing ( Item, StandardProcessing )
	
	clearNode ();
	
EndProcedure

&AtClient
Procedure PrefixFileNameOnChange ( Item )
	
	Output.ChangePrefixFileName ();
	
EndProcedure

&AtClient
Procedure runProcess ( Command )
	
	if ( not Object.Ref.IsEmpty () and ValueIsFilled ( Object.Node ) ) then
		if ( isThisNode ( Object.Node  ) ) then
			Output.ThisNode ();
			return;
		elsif ( Object.OperationType = PredefinedValue ( "Enum.ExchangeTypes.WebService" ) and MasterNode ) then
			Output.MasterNode ();
			return;
		endif;	
		p = new Structure ( "ProcessName, Node", Command.Name, Object.Ref ); 
		runProcessServer ( p );	
	endif; 
	
EndProcedure

&AtServerNoContext
Function isThisNode ( Node )
	
	result = true;
	if ( ValueIsFilled ( Node ) ) then
		result = ( ExchangePlans [ Node.Metadata ().Name ].ThisNode () = Node );
	endif;
	return result; 	 
	
EndFunction 

&AtServerNoContext 
Procedure runProcessServer ( Params )
	
	Catalogs.Exchange.RunProcess ( Params );	
	
EndProcedure

&AtClient
Procedure EditSettings ( Command )
	
	OpenForm ( "Catalog.Exchange.Form.EditSettings" );
	
EndProcedure

&AtClient
Procedure OperationType1OnChange ( Item )
	
	Appearance.Apply ( ThisObject );	
	
EndProcedure

&AtClient
Procedure UseRulesClassifiersOnChange ( Item )
	
	setEnableRules ( "Classifiers" );
	
EndProcedure

&AtClient
Procedure LoadRulesClassifiers ( Command )
	
	loadFileRules ( "Classifiers" );
	
EndProcedure

&AtClient
Procedure loadFileRules ( Postfix = "" )
	
	p = new Structure;
	p.Insert ( "Command", "Load" );
	p.Insert ( "FileDialogMode", FileDialogMode.Open );
	p.Insert ( "Postfix", Postfix );
	LocalFiles.Prepare ( new NotifyDescription ( "ChooseFiles", ThisObject, p ) );
	
EndProcedure 

&AtClient
Procedure UnloadRulesClassifiers ( Command )
	
	unloadFileRules ( "Classifiers" );	
	
EndProcedure

&AtClient
Procedure unloadFileRules ( Postfix = "" )
	
	p = new Structure;
	p.Insert ( "Command", "Unload" );
	p.Insert ( "FileDialogMode", FileDialogMode.Save );
	p.Insert ( "Postfix", Postfix );
	LocalFiles.Prepare ( new NotifyDescription ( "ChooseFiles", ThisObject, p ) );
	
EndProcedure 