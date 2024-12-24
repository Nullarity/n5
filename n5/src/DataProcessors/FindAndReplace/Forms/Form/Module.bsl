&AtServer
var Pictures, FindValue, Replacement, FindType,
		ObjectsStructure, RegistersStructure;
&AtServer
var UnknownType, ConstantType, CatalogType, DocumentType, InformationRegisterType,
		BusinessProcessType, TaskType, ChartOfCharacteristicTypesType,
		ChartOfCalculationTypesType, ChartOfAccountsType, ExchangePlanType,
		ExternalDataSourceTableType, ExternalDataSourceCubeType;

// *****************************************
// *********** Form events

&AtServer
Procedure OnLoadDataFromSettingsAtServer ( Settings )
	
	Object.Find = Settings [ "Object.Find" ];
	Object.Replace = Settings [ "Object.Replace" ];
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )

	defineTypes ();
	readAppearance ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure defineTypes ()
	
	types = new Array;
	addType ( types, Catalogs.AllRefsType () );
	addType ( types, Documents.AllRefsType () );
	addType ( types, Enums.AllRefsType () );
	addType ( types, ChartsOfCharacteristicTypes.AllRefsType () );
	addType ( types, ChartsOfAccounts.AllRefsType () );
	addType ( types, ChartsOfCalculationTypes.AllRefsType () );
	addType ( types, BusinessProcesses.AllRefsType () );
	addType ( types, Tasks.AllRefsType () );
	addType ( types, ExchangePlans.AllRefsType () );
	for each source in ExternalDataSources do
		addType ( types, source.Tables.AllRefsType () );
	enddo;
	Items.Find.TypeRestriction = new TypeDescription ( types );
	
EndProcedure

&AtServerNoContext
Procedure addType ( List, Types )
	
	try
		array = Types.Types ();
		for each type in array Do
			List.Add ( type );
		enddo;
	except
	endtry;
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Warning show filled ( Object.Find ) and empty ( Object.Replace );
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	if ( ValueIsFilled ( Object.Find ) ) then
		beginFetchingLinks ( true );
	endif;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure FindLinks ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif;
	beginFetchingLinks ( true );
	
EndProcedure

&AtClient
Procedure beginFetchingLinks ( ShowProgress = false, Params = undefined ) export
	
	if ( ShowProgress = undefined ) then
		fetchLinks ();
		WaitForm.Close ();
	else
		WaitForm.Open ( "beginFetchingLinks", , ThisObject );
	endif;
	
EndProcedure

&AtServer
Procedure fetchLinks ()
	
	prepareMetadata ();
	references = getReferences (); 
  Links.Clear ();
  classes = new Map ();
	for each reference in references Do
		meta = reference.Metadata;
		link = reference.Data;
		type = metaType ( meta );
		row = Links.Add ();
		row.Apply = true;
		row.Type = type;
		row.Name = meta.Name;
		row.Presentation = dataPresentation ( type, meta, link )
			+ " (" + meta.Presentation () + ")";
		row.Link = link;
		row.Picture = Pictures [ type ];
		if ( type <> ConstantType
			and type <> InformationRegisterType
			and type <> ExternalDataSourceTableType
			and type <> ExternalDataSourceCubeType ) then
			if ( classes [ meta ] = undefined ) then
				classes [ meta ] = new Array ();
			endif;
			classes [ meta ].Add ( link );
		endif;
	enddo;
	markDeleted ( classes );
	
EndProcedure

&AtServer
Procedure markDeleted ( Classes )
	
	q = new Query ();
	parts = new Array ();
	set = 1;
	template = "select Ref as Ref from %Name where DeletionMark and Ref in ( &%Filter )";
	for each class in Classes do
		filter = "_" + Format ( set, "NG=0" );
		parts.Add ( Output.FormatStr ( template,
			new Structure ( "Name, Filter", class.Key.FullName (), filter ) ) );
		q.SetParameter ( filter, class.Value );
		set = set + 1;
	enddo;
	if ( parts.Count () = 0 ) then
		return;
	endif;
	q.Text = StrConcat ( parts, " union all " );
	marked = q.Execute ().Unload ().UnloadColumn ( "Ref" );
	for each row in Links do
		row.Marked = marked.Find ( row.Link ) <> undefined;
	enddo;
	
EndProcedure

&AtServer
Procedure prepareMetadata ()

	Pictures = new Array ( 13 );
	Pictures [ UnknownType ] = new Picture ();
	Pictures [ ConstantType ] = PictureLib.Constant;
	Pictures [ CatalogType ] = PictureLib.CatalogObject;
	Pictures [ DocumentType ] = PictureLib.DocumentObject;
	Pictures [ InformationRegisterType ] = PictureLib.InformationRegister;
	Pictures [ BusinessProcessType ] = PictureLib.BusinessProcessObject;
	Pictures [ TaskType ] = PictureLib.TaskObject;
	Pictures [ ChartOfCharacteristicTypesType ] = PictureLib.ChartOfCharacteristicTypesObject;
	Pictures [ ChartOfCalculationTypesType ] = PictureLib.ChartOfCalculationTypesObject;
	Pictures [ ChartOfAccountsType ] = PictureLib.ChartOfAccountsObject;
	Pictures [ ExchangePlanType ] = PictureLib.ExchangePlanObject;
	Pictures [ ExternalDataSourceTableType ] = PictureLib.ExternalDataSourceTable;
	Pictures [ ExternalDataSourceCubeType ] = PictureLib.ExternalDataSourceTable;

EndProcedure

&AtServer
Function getReferences ()
	
	what = new Array ();
	what.Add ( Object.Find );
	return FindByRef ( what );
	
EndFunction

&AtServer
Function metaType ( MetaObject )
	
	if ( Metadata.Constants.Contains ( MetaObject ) ) then
		return ConstantType;
	endif;
	if ( Metadata.Catalogs.Contains ( MetaObject ) ) then
	    return CatalogType;
	endif;
	if ( Metadata.Documents.Contains ( MetaObject ) ) then
	    return DocumentType;
	endif;
	if ( Metadata.InformationRegisters.Contains ( MetaObject ) ) then
	    return InformationRegisterType;
	endif;
	if ( Metadata.BusinessProcesses.Contains ( MetaObject ) ) then
	    return BusinessProcessType;
	endif;
	if ( Metadata.Tasks.Contains ( MetaObject ) ) then
	    return TaskType;
	endif;
	if ( Metadata.ChartsOfCharacteristicTypes.Contains ( MetaObject ) ) then
	    return ChartOfCharacteristicTypesType;
	endif;
	if ( Metadata.ChartsOfCalculationTypes.Contains ( MetaObject ) ) then
	    return ChartOfCalculationTypesType;
	endif;
	if ( Metadata.ChartsOfAccounts.Contains ( MetaObject ) ) then
	    return ChartOfAccountsType;
	endif;
	if ( Metadata.ExchangePlans.Contains ( MetaObject ) ) then
	    return ExchangePlanType;
	endif;
	objectData = Metadata.ObjectProperties.ExternalDataSourceTableDataType.ObjectData;
	for each source in Metadata.ExternalDataSources do
	    if ( source.Tables.Contains ( MetaObject ) ) then
	        if ( MetaObject.TableDataType = objectData ) then
	            return ExternalDataSourceTableType;
	        else
	            return ExternalDataSourceCubeType;
	        endif;
	    endif;
	enddo;
	return UnknownType;
	
EndFunction

&AtServer
Function dataPresentation ( MetaType, MetaObject, Data )
	
	presentation = "";
	if ( MetaType = UnknownType  or MetaType = ConstantType or MetaType = CatalogType
		or MetaType = DocumentType or MetaType = ExchangePlanType
		or MetaType = BusinessProcessType or MetaType = TaskType
		or MetaType = ChartOfCharacteristicTypesType or MetaType = ChartOfCalculationTypesType
		or MetaType = ChartOfAccountsType or MetaType = ExternalDataSourceTableType ) then
		presentation = String ( Data );
	elsif ( MetaType = InformationRegisterType ) then
		if ( MetaObject.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical ) then
			presentation = String ( Data.Period );
		endif;
		if ( MetaObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate ) then
			presentation = ? ( presentation = "", "", presentation  + "; ") + String ( Data.Recorder );
		endif;
		for each dim in MetaObject.Dimensions do
			presentation = ? ( presentation = "", "", presentation + "; ") + String ( Data [ dim.Name ] );
		enddo;
	elsif ( MetaType = ExternalDataSourceCubeType ) then
		for each dim in MetaObject.KeyFields do
			Presentation = ? ( presentation = "", "", presentation + "; ") + String ( Data [ dim.Name ] );
		enddo;
	endif;
	return presentation;
	
EndFunction

&AtClient
Procedure FindOnChange ( Item )
	
	applyFind ();
	
EndProcedure

&AtClient
Procedure applyFind ()
	
	if ( Object.Find = undefined ) then
		Object.Replace = undefined;
		Links.Clear ();
	else
		types = new Array ();
		types.Add ( TypeOf ( Object.Find ) );
		descriptor = new TypeDescription ( types );
		Object.Replace = descriptor.AdjustValue ( Object.Replace );
		if ( ValueIsFilled ( Object.Find ) ) then
			beginFetchingLinks ( true );
		endif;
	endif;
	Appearance.Apply ( ThisObject, "Object.Find" );
	
EndProcedure

&AtClient
Procedure ReplaceOnChange ( Item )

	Appearance.Apply ( ThisObject, "Object.Replace" );

EndProcedure

// *****************************************
// *********** Table Links

&AtClient
Procedure MarkAll ( Command )
	
	mark ( true );
	
EndProcedure

&AtClient
Procedure mark ( Flag ) 

	for each row in Links do
		row.Apply = Flag;
	enddo;

EndProcedure

&AtClient
Procedure UnmarkAll ( Command )

	mark ( false );
		
EndProcedure

&AtClient
Procedure LinksSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	openLink ();
	
EndProcedure

&AtClient
Procedure openLink ()
	
	ShowValue ( , Items.Links.CurrentData.Link );

EndProcedure

&AtClient
async Procedure ReplaceLinks ( Command )
	
	if ( not replacingPossible () ) then
		return;
	endif;
	answer = await Output.ReplaceValuesConfirmation ();
	if ( answer = DialogReturnCode.Yes ) then
		WaitForm.Open ( "beginReplacing", , ThisObject );
	endif;
	
EndProcedure

&AtServer
Function replacingPossible ()
	
	if ( not CheckFilling () ) then
		return false;
	endif;
	if ( Object.Find = Object.Replace ) then
		Output.WrongReplaceValue ( , "Replace" );
		return false;
	endif;
	return true;
	
EndFunction

&AtClient
Procedure beginReplacing ( Result, Params ) export
	
	replace ();
	WaitForm.Close ();
	
EndProcedure

&AtServer
Procedure replace ()
	
	init ();
	startReplacing ();
	fetchLinks ();
	
EndProcedure

&AtServer
Procedure init ()
	
	FindValue = Object.Find;
	FindType = TypeOf ( FindValue );
	Replacement = Object.Replace;
	RegistersStructure = new Map ();
	ObjectsStructure = new Map ();
	
EndProcedure

&AtServer
Procedure startReplacing ()
	
	for each link in Links do
		if ( not link.Apply ) then
			continue;
		endif;
		type = link.Type;
		if ( type = ConstantType ) then
			Constants [ link.Name ].Set ( Object.Replace );
		elsif ( type = InformationRegisterType ) then
			replaceInRecordkeys ( link );
		else
			replaceInObject ( link );
		endif;
	enddo;
	
EndProcedure

&AtServer
Procedure replaceInObject ( Link )
	
	obj = Link.Link.GetObject ();
	meta = objectMeta ( Link );
	for each attribute in meta.Attributes do
		replaceValue ( obj [ attribute ] );
	enddo;
	for each table in meta.Tables do
		for each row in obj [ table.Key ] do
			for each column in table.Value do
				replaceValue ( row [ column ] );
			enddo;
		enddo;
	enddo;
	obj.DataExchange.Load = true;
	obj.Write ();
	if ( Link.Type = DocumentType ) then
		replaceInRecords ( obj.RegisterRecords );
	endif;

EndProcedure

&AtServer
Function objectMeta ( Link )
	
	manager = typeToMeta ( Link.Type );
	meta = manager [ Link.Name ];
	if ( ObjectsStructure [ meta ] <> undefined ) then
		return ObjectsStructure [ meta ];
	endif;
	attributes = new Array ();
	for each attribute in meta.Attributes do
		attributes.Add ( attribute.Name );
	enddo; 
	if ( manager = Metadata.Catalogs ) then
		attributes.Add ( "Owner" );
		attributes.Add ( "Parent" );
	endif;
	tables = new Map ();
	for each table in meta.TabularSections do
		columns = new Array ();
		for each column in table.Attributes do
			columns.Add ( column.Name );
		enddo;
		tables [ table.Name ] = columns;
	enddo;
	entry = new Structure ( "Attributes, Tables", attributes, tables );
	ObjectsStructure [ meta ] = entry;
	return entry;
	
EndFunction


&AtServer
Procedure replaceValue ( Value )
	
	if ( TypeOf ( Value ) = FindType
		and Value = FindValue ) then
		Value = Replacement; 
	endif;
	
EndProcedure

&AtServer
Function typeToMeta ( Type )
	
	if ( Type = CatalogType ) then
			return Metadata.Catalogs;
	elsif ( Type = DocumentType ) then
		return Metadata.Documents;
	elsif ( Type = InformationRegisterType ) then
		return Metadata.InformationRegisters;
	elsif ( Type = BusinessProcessType ) then
		return Metadata.BusinessProcesses;
	elsif ( Type = TaskType ) then
		return Metadata.Tasks;
	elsif ( Type = ChartOfCharacteristicTypesType ) then
		return Metadata.ChartsOfCharacteristicTypes;
	elsif ( Type = ChartOfCalculationTypesType ) then
		return Metadata.ChartsOfCalculationTypes;
	elsif ( Type = ChartOfAccountsType ) then
		return Metadata.ChartsOfAccounts;
	endif;

EndFunction

&AtServer
Procedure replaceInRecords ( Records )
	
	for each recordset in Records do
		recordset.Read ();
		meta = registerMeta ( recordset.Metadata () );
		accounting = meta.Accounting;
		attributes = meta.Attributes;
		for each record in recordset do
			for each attribute in attributes do
				replaceValue ( record [ attribute ] );
			enddo;
			if ( accounting ) then
				dims = new Array ();
				dims.Add ( record.ExtDimensionsDr );
				dims.Add ( record.ExtDimensionsCr );
				for each set in dims do
					values = new Array ();
					for each dimension in set do
						value = dimension.Value;
						replaceValue ( value );
						values.Add ( new Structure ( "Key, Value", dimension.Key, value ) );
					enddo;
					set.Clear ();
					for each value in values do
						set.Insert ( value.Key, value.Value );
					enddo;
				enddo;
			endif;
		enddo;
		recordset.DataExchange.Load = true;
		recordset.Write ();
	enddo;
	
EndProcedure

&AtServer
Function registerMeta ( Register )
	
	if ( RegistersStructure [ Register ] <> undefined ) then
		return RegistersStructure [ Register ];
	endif;
	attributes = new Array ();
	for each attribute in Register.Attributes do
		attributes.Add ( attribute.Name );
	enddo;
	accounting = Metadata.AccountingRegisters.Contains ( Register );
	list = new Array ();
	list.Add ( Register.Dimensions );
	list.Add ( Register.Resources );
	for each set in list do
		for each attribute in set do
			name = attribute.Name;
			if ( accounting ) then
				if ( attribute.Balance ) then
					attributes.Add ( name );
				else
					attributes.Add ( name + "Dr" );
					attributes.Add ( name + "Cr" );
				endif;
			else
				attributes.Add ( name );
			endif;
		enddo;
	enddo;
	entry = new Structure ( "Attributes, Accounting", attributes, accounting );
	RegistersStructure [ Register ] = entry;
	return entry;
	
EndFunction

&AtServer
Procedure replaceInRecordkeys ( Link )
	
	name = Link.Name;
	manager = InformationRegisters [ name ];
	oldRecord = manager.CreateRecordManager ();
	newRecord = manager.CreateRecordManager ();
	FillPropertyValues ( oldRecord, Link.Link );
	FillPropertyValues ( newRecord, oldRecord );
	meta = registerMeta ( Metadata.InformationRegisters [ name ] );
	for each attribute in meta.Attributes do
		replaceValue ( newRecord [ attribute ] );
	enddo;
	newRecord.Write ();
	oldRecord.Delete ();
	
EndProcedure

// *****************************************
// *********** Module initialization

UnknownType = 0;
ConstantType = 1;
CatalogType = 2;
DocumentType = 3;
InformationRegisterType = 4;
BusinessProcessType = 5;
TaskType = 6;
ChartOfCharacteristicTypesType = 7;
ChartOfCalculationTypesType = 8;
ChartOfAccountsType = 9;
ExchangePlanType = 10;
ExternalDataSourceTableType = 11;
ExternalDataSourceCubeType = 12;
