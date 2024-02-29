	
Function Events () export
	
	p = new Structure ();
	p.Insert ( "FullAccessRequest", false );
	p.Insert ( "OnInitDefaultParams", false );
	p.Insert ( "BeforeOpen", false );
	p.Insert ( "OnDetail", false );
	p.Insert ( "OnCheck", false );
	p.Insert ( "OnScheduling", false );
	p.Insert ( "OnCompose", false );
	p.Insert ( "OnPrepare", false );
	p.Insert ( "OnGetColumns", false );
	p.Insert ( "AfterOutput", false );
	return p;
	
EndFunction 

Function GetVariants ( User, Report ) export
	
	return getSettings ( User, Report );
	
EndFunction

Function GetUserSettings ( User, Report, ReportVariant ) export
	
	return getSettings ( User, Report, ReportVariant );
	
EndFunction

Function getSettings ( User, Report, Variant = undefined )
	
	s = "
	|select allowed Ref as Ref, Code as Code, Description as Description, LastUpdateDate as LastUpdateDate
	|from Catalog.ReportSettings
	|where not Ref.DeletionMark
	|and User = &User
	|and Report = &Report
	|";
	if ( Variant = undefined ) then
		s = s + "and not IsSettings";
	else
		s = s + "and ReportVariant = &Variant";
	endif; 
	s = s + "
	|order by Description
	|";
	q = new Query ( s );
	q.SetParameter ( "Report", Catalogs.Metadata.Ref ( "Report." + Report ) );
	q.SetParameter ( "Variant", Variant );
	q.SetParameter ( "User", User );
	return q.Execute ().Unload ();
	
EndFunction

Function GetSchema ( Report ) export
	
	return Reports [ Report ].GetTemplate ( Metadata.Reports [ Report ].MainDataCompositionSchema.Name );
	
EndFunction
 
Procedure ApplyFilters ( Composer, Params ) export
	
	filters = undefined;
	Params.Property ( "Filters", filters );
	if ( filters = undefined ) then
		return;
	endif;
	for each filter in filters do
		isParameter = filter.Property ( "Parameter" );
		if ( isParameter ) then
			name = "" + filter.Parameter;
			item = DC.GetParameter ( Composer, name );
			if ( item = undefined ) then
				raise ( "Cannot find data parameter for Name=" + name );
			endif;
			FillPropertyValues ( item, filter, , "Parameter" );
		else
			name = "" + filter.LeftValue;
			item = DC.FindFilter ( Composer, name );
			if ( item = undefined ) then
				try
					DC.SetFilter ( Composer, name, filter.RightValue, filter.ComparisonType, filter.ViewMode );
				except
					raise ( "Cannot find filter for Name=" + name );
				endtry;
				continue;
			endif;
			FillPropertyValues ( item, filter, "ComparisonType, Use, ViewMode" );
			loadRightValue ( item, filter );
		endif; 
		fixComparison ( item );
	enddo; 
	
EndProcedure

Function Prepare ( Report ) export
	
	p = getParams ( Report );
	obj = undefined;
	events = p.Events;
	if ( events.OnCheck
		or events.OnCompose
		or events.OnPrepare
		or events.AfterOutput ) then
		SetPrivilegedMode ( true );
		obj = Reports [ Report ].Create ();
		obj.Params = p;
	endif; 
	if ( obj = undefined ) then
		obj = Reports.Common.Create ();
	endif; 
	obj.Params = p;
	return obj;
	
EndFunction 

Function getParams ( Report )
	
	p = new Structure ();
	p.Insert ( "Name", Report );
	p.Insert ( "Variant" );
	p.Insert ( "Schema" );
	p.Insert ( "Result" );
	p.Insert ( "Settings" );
	p.Insert ( "Composer" );
	p.Insert ( "ExternalDataSets" );
	p.Insert ( "TempTables" );
	p.Insert ( "Details" );
	p.Insert ( "Empty", false );
	p.Insert ( "Interactive", true );
	p.Insert ( "Quickly", false );
	p.Insert ( "HiddenParams", new Array () );
	p.Insert ( "Events", Reports [ Report ].Events () );
	p.Insert ( "Columns" );
	p.Insert ( "GenerateOnOpen", false );
	p.Insert ( "CheckAccess", true );
	p.Insert ( "CompanyInHeader", true );
	p.Insert ( "StandardFooter", true );
	p.Insert ( "BatchQuery" );
	p.Insert ( "ClearTable", true );
	return p;
	
EndFunction 

Procedure setupPage ( Params )
	
	Params.Result.FitToPage = true;
	
EndProcedure

Procedure setKey ( Params )
	
	if ( TypeOf ( Params.Variant ) = Type ( "String" ) ) then
		code = StrReplace ( Params.Variant, "#", "" );
	else
		code = TrimR ( Params.Variant.Code );
	endif; 
	Params.Result.PrintParametersKey = Params.Name + code;
	
EndProcedure

Function FindField ( Path, Schema ) export
	
	i = StrFind ( Path, "." );
	if ( i = 0 ) then
		dataset = "";
		dataPath = Path;
	else
		dataset = Left ( path, i - 1 );
		dataPath = Mid ( path, i + 1 );
	endif; 
	ds = Schema.DataSets [ ? ( dataset = "", 0, dataset ) ];
	field = ds.Fields.Find ( dataPath );
	if ( field = undefined ) then
		ds = Schema.CalculatedFields;
		field = ds.Find ( dataPath );
	endif; 
	return field;
	
EndFunction 

Procedure getOutputParams ( Params )
	
	Params.Insert ( "ShowTitle", showTitle ( Params ) );
	Params.Insert ( "ShowDataVersion", showDataVersion ( Params ) );
	Params.Insert ( "ShowDataCopy", showInfo ( Params, "DatabaseCopyOutput" ) );
	Params.Insert ( "ShowFilters", showInfo ( Params, "FilterOutput" ) );
	showParams = showInfo ( Params, "DataParametersOutput" );
	Params.Insert ( "ShowParams", showParams );
	Params.Insert ( "HideParams", showParams and Params.HiddenParams.Count () > 0 );
	
EndProcedure 

Function showTitle ( Params )
	
	p = Params.Settings.OutputParameters.FindParameterValue ( new DataCompositionParameter ( "TitleOutput" ) );
	if ( p.Use ) then
		if ( p.Value = DataCompositionTextOutputType.DontOutput ) then
			return false;
		elsif ( p.Value = DataCompositionTextOutputType.Output ) then
			return true;
		endif;
	endif;
	p = Params.Settings.OutputParameters.FindParameterValue ( new DataCompositionParameter ( "Title" ) );
	return p.Use and ( p.Value <> "" );
	
EndFunction 

Function showDataVersion ( Params )
	
	p = Params.Settings.OutputParameters.FindParameterValue ( new DataCompositionParameter ( "DataRelevanceOutput" ) );
	return not p.Use or p.Value <> DataCompositionDataRelevanceOutputType.DontOutput;
	
EndFunction 

Function showInfo ( Params, Parameter )
	
	settings = Params.Settings;
	p = settings.OutputParameters.FindParameterValue ( new DataCompositionParameter ( Parameter ) );
	if ( p.Use ) then
		if ( p.Value = DataCompositionTextOutputType.DontOutput ) then
			return false;
		elsif ( p.Value = DataCompositionTextOutputType.Output ) then
			return true;
		elsif ( p.Value = DataCompositionDatabaseCopyOutputType.Output ) then
			return true;
		endif;
	endif;
	if ( Parameter = "DataParametersOutput" ) then
		items = settings.DataParameters.AvailableParameters;
		for each item in settings.DataParameters.Items do
			if ( item.Use ) then
				p = items.FindParameter ( item.Parameter );
				if ( p.Visible ) then
					return true;
				endif;
			endif; 
		enddo; 
	elsif ( Parameter = "FilterOutput" ) then
		for each item in Params.Settings.Filter.Items do
			if ( item.Use ) then
				return true;
			endif; 
		enddo; 
	endif; 
	return false;
	
EndFunction 

Procedure encodeParams ( Params )
	
	if ( not Params.HideParams ) then
		return;
	endif; 
	names = new Map ();
	for each item in Params.Schema.Parameters do
		id = "" + new UUID ();
		names [ item.Name ] = new Structure ( "ID, Title", id, item.Title );
		item.Title = id;
	enddo; 
	Params.Insert ( "ParametersMap", names );
	
EndProcedure 

Function executeComposer ( Composer, Params, Details )
	
	try
		template = buildTemplate ( Params, Composer, Details );
	except
		decodeParams ( Params );
		try
			buildTemplate ( Params, Composer, Details );
		except
			outputError ( Params, BriefErrorDescription ( ErrorInfo () ) );
			return undefined;
		endtry;
	endtry;
	if ( Params.Interactive ) then
		Params.Details = Details;
	endif; 
	return template;
	
EndFunction

Procedure outputError ( Params, Error )
	
	area = Reports.Common.GetTemplate ( "Template" ).GetArea ( "Error" );
	area.Parameters.Error = Error;
	Params.Result.Put ( area );
	
EndProcedure

Procedure getParts ( Params, DataTemplate )
	
	parts = new Array ();
	parts.Add ( "StartIndex" );
	parts.Add ( "GapAfterStartIndex" );
	if ( Params.ShowTitle ) then
		parts.Add ( "TitleIndex" );
		parts.Add ( "GapAfterTitleIndex" );
	endif;
	if ( Params.ShowDataVersion ) then
		parts.Add ( "DataVersionIndex" );
	endif;
	if ( Params.ShowDataCopy ) then
		parts.Add ( "DataCopyIndex" );
	endif;
	if ( Params.ShowParams ) then
		parts.Add ( "ParamsIndex" );
	endif;
	if ( Params.ShowFilters ) then
		parts.Add ( "FilterIndex" );
	endif;
	parts.Add ( "GapBeforeReportIndex" );
	parts.Add ( "ReportIndex" );
	all = parts.Ubound ();
	available = DataTemplate.Templates.Count () - 1;
	while ( all > available ) do
		parts.Delete ( all );
		all = all - 1;
	enddo;
	Params.Insert ( "Parts", parts );
	
EndProcedure

Procedure hideParams ( Params, DataTemplate )
	
	if ( not Params.HideParams ) then
		return;
	endif;
	template = DataTemplate.Templates [ Params.Parts.Find ( "ParamsIndex" ) ].Template;
	map = Params.ParametersMap;
	for each name in Params.HiddenParams do
		id = map [ name ].ID;
		i = template.Count () - 1;
		while ( i >= 0 ) do
			row = template [ i ];
			stop = false;
			for each cell in row.Cells do
				for each field in cell.Items do
					if ( StrStartsWith ( field.Value, id ) ) then
						//@skip-warning
						template.Delete ( i );
						stop = true;
						break;
					endif;
				enddo;
				if ( stop ) then
					break;
				endif; 
			enddo; 
			i = i - 1;
		enddo; 
	enddo; 
	
EndProcedure 

Procedure adjustHeader ( Params, DataTemplate )
	
	templates = DataTemplate.Templates;
	i = Params.Parts.Find ( "ParamsIndex" );
	if ( i <> undefined ) then
		template = templates [ i ].Template;
		for each row in template do
			//@skip-warning
			row.Cells.Delete ( 0 );
		enddo; 
	endif;
	i = Params.Parts.Find ( "FilterIndex" );
	if ( i <> undefined ) then
		for each row in templates [ i ].Template do
			for each cell in row.Cells [ 1 ].Items do
				cell.Value = StrReplace ( cell.Value, Chars.LF, " " );
			enddo; 
			//@skip-warning
			row.Cells.Delete ( 0 );
		enddo; 
	endif;
	i = Params.Parts.Find ( "GapAfterTitleIndex" );
	if ( i <> undefined ) then
		//@skip-warning
		templates [ i ].Template.Delete ( 0 );
	endif; 
	
EndProcedure 

Procedure groupHeader ( Params, DataTemplate )
	
	header = Params.Parts.Find ( "ReportIndex" );
	if ( header = undefined
		or header = 0 ) then
		return;
	endif;
	templates = DataTemplate.Templates;
	reduceMargin = true;
	chart = Type ( "DataCompositionAreaTemplateChartTemplate" );
	document = Type ( "DataCompositionAreaDocumentTemplate" );
	for i = 0 to header do
		level = ? ( i = header, 0, 1 );
		template = templates [ i ].Template;
		templateType = TypeOf ( template );
		if ( templateType = chart ) then
			reduceMargin = false;
		elsif ( templateType <> document ) then
			for each row in template do
				for each cell in row.Cells do
					set = cell.Appearance;
					set.SetParameterValue ( "VerticalLevel", level );
					if ( reduceMargin ) then
						set.SetParameterValue ( "MaximumHeight", 0.5 );
						reduceMargin = false;
					endif;
					break;
				enddo;
			enddo;
		endif;
	enddo;
	
EndProcedure

Procedure decodeParams ( Params, DataTemplate = undefined )
	
	if ( not Params.HideParams ) then
		return;
	endif; 
	ids = restoreParams ( Params );
	if ( DataTemplate <> undefined ) then
		replaceIDs ( Params, ids, DataTemplate );
	endif; 

EndProcedure 

Function restoreParams ( Params )
	
	set = Params.Schema.Parameters;
	map = new Map ();
	for each item in Params.ParametersMap do
		value = item.Value;
		set [ item.Key ].Title = value.Title;
		map [ value.ID ] = value.Title;
	enddo; 
	return map;
	
EndFunction 

Procedure replaceIDs ( Params, IDs, DataTemplate )
	
	i = Params.Parts.Find ( "ParamsIndex" );
	template = DataTemplate.Templates [ i ].Template;
	for each row in template do
		for each cell in row.Cells do
			for each field in cell.Items do
				id = Left ( field.Value, 36 );
				title = IDs [ id ];
				if ( title <> undefined ) then
					field.Value = StrReplace ( field.Value, id, title );
				endif; 
			enddo;
		enddo; 
	enddo; 
	
EndProcedure 

Function reportIsEmpty ( Params )
	
	return Params.Empty
	or Params.Result.TableHeight = 0;
	
EndFunction 

Procedure showEmpty ( Params )
	
	t = Reports.Common.GetTemplate ( "Template" );
	Params.Result.Put ( t.GetArea ( "Empty" ) );
	
EndProcedure 

Procedure headerFooter ( Params )
	
	if ( Params.CompanyInHeader ) then
		header = Params.Result.Header;		
		header.Enabled = true;
		header.RightText = Logins.Settings ( "Company" ).Company;
	endif;
	if ( Params.StandardFooter ) then
		footer = Params.Result.Footer;
		footer.Enabled = true;
		footer.RightText = Output.PageFooter ();
	endif;
	
EndProcedure

Procedure output ( Params, Processor, Builder, DataTemplate )
	
	interactive = Params.Interactive;
	if ( interactive ) then
		fixation = Params.Settings.OutputParameters.FindParameterValue ( new DataCompositionParameter ( "FixedTop" ) );
		fix = not ( fixation.Use and fixation.Value = DataCompositionFixation.DontUse );
		fixed = false;
		lastHeight = 1;
		empty = false;
	else
		fix = false;
		empty = true;
	endif; 
	Builder.BeginOutput ();
	tabDoc = Params.Result;
	while ( true ) do
		item = Processor.Next ();
		if ( item = undefined ) then
			break;
		endif;
		if ( fix
			and not fixed ) then
			if ( item.ParameterValues.Count () > 0 ) then
				fixed = true;
				if ( tabDoc.TableHeight > lastHeight ) then
					rc = "R" + Format ( lastHeight + 1, "NG=" ) + ":R" + Format ( tabDoc.TableHeight, "NG=" );
					tabDoc.RepeatOnRowPrint = tabDoc.Area ( rc );
					tabDoc.FixedTop = tabDoc.TableHeight;
				endif; 
			elsif ( item.ItemType = DataCompositionResultItemType.BeginAndEnd ) then
				lastHeight = tabDoc.TableHeight;
			endif; 
		endif; 
		if ( empty
			and not interactive ) then
			for each parameter in item.ParameterValues do
				try
					if ( ValueIsFilled ( parameter.Value ) ) then
                    	empty = false;
                    	break;
					endif;
				except
				endtry;
			enddo;
		endif; 
		Builder.OutputItem ( item );
	enddo; 
	Builder.EndOutput ();
	Params.Empty = not interactive and empty;
	
EndProcedure

Function Make ( Report, Variant, Settings ) export

	obj = prepareToMake ( Report, Variant, Settings );
	p = obj.Params;
	if ( p.Events.OnCheck ) then
		cancel = false;
		obj.OnCheck ( cancel );
		if ( cancel ) then
			return undefined;
		endif; 
	endif; 
	p.Settings = p.Composer.GetSettings ();
	Reporter.ComposeResult ( obj );
	return obj;
	
EndFunction 

Function prepareToMake ( Report, Variant, Settings )
	
	obj = Reporter.Prepare ( Report );
	p = obj.Params;
	p.Interactive = false;
	p.Variant = Variant;
	p.Result = new SpreadsheetDocument ();
	p.Schema = GetSchema ( Report );	
	p.Composer = new DataCompositionSettingsComposer ();
	p.Composer.Initialize ( new DataCompositionAvailableSettingsSource ( p.Schema ) );
	if ( TypeOf ( Variant ) = Type ( "CatalogRef.ReportSettings" ) ) then
		p.Composer.LoadSettings ( Variant.Storage.Get () );
	else
		variantName = Mid ( Variant, 2 );
		variantReport = p.Schema.SettingVariants [ variantName ].Settings;
		p.Composer.LoadSettings ( variantReport );
	endif; 
	p.Composer.LoadUserSettings ( Settings );
	return obj;
	
EndFunction 

Function Build ( Params ) export

	obj = prepareToGet ( Params );
	p = obj.Params;
	if ( p.Events.OnCheck ) then
		cancel = false;
		obj.OnCheck ( cancel );
		if ( cancel ) then
			return undefined;
		endif; 
	endif; 
	p.Settings = p.Composer.GetSettings ();
	Reporter.ComposeResult ( obj );
	return p.Result;
	
EndFunction 

Function prepareToGet ( Params )
	
	report = Params.ReportName;
	variant = Params.Variant;
	variantName = Mid ( variant, 2 );
	schema = GetSchema ( report );
	composer = new DataCompositionSettingsComposer ();
	composer.Initialize ( new DataCompositionAvailableSettingsSource ( schema ) );
	composer.LoadSettings ( schema.SettingVariants [ variantName ].Settings );
	Reporter.ApplyFilters ( composer, Params );
	obj = Reporter.Prepare ( report );
	p = obj.Params;
	p.Interactive = false;
	p.Variant = variant;
	p.Result = new SpreadsheetDocument ();
	p.Schema = schema;	
	p.Composer = composer;
	p.Columns = Params.Columns;
	return obj;
	
EndFunction 

Function FindDefinition ( Template, Name ) export
	
	result = findTemplate ( Template, Name );
	if ( result = undefined ) then
		return undefined;
	else
		return Template.Templates [ result ];
	endif; 
	
EndFunction 

Function findTemplate ( Template, Name )
	
	for each item in Template.Body do
		itemType = TypeOf ( item );
		if ( itemType = Type ( "DataCompositionTemplateTable" ) ) then
			for each row in item.Rows do
				target = targetTemplate ( row, Name );
				if ( target <> undefined ) then
					return target;
				endif; 
			enddo; 
		elsif ( itemType = Type ( "DataCompositionTemplateGroup" )
			or itemType = Type ( "DataCompositionTemplateRecords" ) ) then
			target = targetTemplate ( item, Name );
			if ( target <> undefined ) then
				return target;
			endif; 
		endif;
	enddo; 
	return undefined;
	
EndFunction 

Function targetTemplate ( Item, Name )
	
	if ( Item.Name = Name ) then
		return Item.Body [ 0 ].Template;
	else
		template = findTemplate ( Item, Name );
		if ( template <> undefined ) then
			return template;
		endif; 
	endif; 
	
EndFunction 

Procedure ReplaceExpression ( Definition, Expression, NewExpression ) export
	
	area = Type ( "DataCompositionExpressionAreaParameter" );
	for each p in Definition.Parameters do
		if ( TypeOf ( p ) = area
			and StrFind ( p.Expression, Expression ) > 0 ) then
			p.Expression = StrReplace ( p.Expression, Expression, NewExpression );
		endif; 
	enddo; 
	
EndProcedure

Procedure MakeFlat ( Template ) export
	
	for each item In Template.Templates do
        for each row in item.Template Do            
            row.TableID = "";
        enddo;
    enddo;
	
EndProcedure

#region Details

Procedure ApplyDetails ( Composer, Filters ) export
	
	localFilters = getFilters ( Composer );
	availFilters = Composer.Settings.FilterAvailableFields;
	for each filter in Filters do
		if ( not filter.StandardProcessing ) then
			continue;
		endif; 
		if ( filter.Filter ) then
			if ( TypeOf ( filter.Item ) = Type ( "DataCompositionFilterItem" ) ) then
				item = DC.FindFilter ( Composer, String ( filter.Item.LeftValue ), false );
				if ( item <> undefined ) then
					if ( not item.Use ) then
						downloadFilter ( filter.Item, item );
					endif; 
					continue;
				endif; 
			endif; 
			loadFilter ( filter.Item, availFilters, localFilters );
		else
			item = DC.FindParameter ( Composer, filter.Name );
			if ( item = undefined ) then
				item = DC.FindFilter ( Composer, filter.Name );
				if ( item = undefined ) then
					item = availFilters.FindField ( new DataCompositionField ( filter.Name ) );
				endif; 
				if ( item = undefined ) then
					continue;
				endif; 
				DC.SetFilter ( Composer, filter.Name, filter.Item.Value, filter.Comparison, DataCompositionSettingsItemViewMode.Auto );
			else
				DC.SetParameter ( Composer, filter.Name, filter.Item.Value );
			endif; 
		endif; 
	enddo; 
	
EndProcedure 

Function getFilters ( Composer )
	
	id = Composer.Settings.Filter.UserSettingID;
	if ( id = "" ) then
		return Composer.Settings.Filter.Items;
	else
		return Composer.UserSettings.Items.Find ( id ).Items;
	endif; 
	
EndFunction 

Procedure downloadFilter ( Filter, Destination )
	
	FillPropertyValues ( Destination, Filter, "Use, RightValue, ComparisonType" );
	
EndProcedure 

Procedure loadFilter ( Filter, AvailFields, Items )
	
	group = Type ( "DataCompositionFilterItemGroup" );
	if ( TypeOf ( Filter ) = group ) then
		item = Items.Add ( group );
		FillPropertyValues ( item, Filter );
		for each element in Filter.Items do
			loadFilter ( element, AvailFields, item.Items );
		enddo; 
	else
		item = AvailFields.FindField ( Filter.LeftValue );
		if ( item = undefined ) then
			return;
		endif;
		item = Items.Add ( Type ( "DataCompositionFilterItem" ) );
		FillPropertyValues ( item, Filter );
	endif; 
	
EndProcedure 

Procedure AddReport ( List, Name ) export
	
	report = Metadata.Reports [ Name ];
	if ( AccessRight ( "View", report ) ) then
		List.Add ( Name, report.Presentation () );
	endif; 
	
EndProcedure 

Procedure DateToPeriod ( Composer, Filter ) export
	
	periodItem = DC.FindParameter ( Composer, "Period" );
	periodItem.Use = true;
	period = periodItem.Value;
	period.Variant = StandardPeriodVariant.Custom;
	value = Filter.Item.Value;
	if ( TypeOf ( value ) = Type ( "CatalogRef.Calendar" ) ) then
		endDate = DF.Pick ( value, "Date" );
	else
		endDate = value;
	endif;
	period.StartDate = BegOfYear ( endDate );
	period.EndDate = EndOfDay ( endDate );
	Filter.StandardProcessing = false;
	
EndProcedure 

#endregion

Function IsFilling ( Variant ) export
	
	return StrStartsWith ( Variant, "#Fill" );

EndFunction 

Function ColumnStruct ( Path, MaximumWidth ) export
	
	return new Structure ( "Path, MaximumWidth", Path, MaximumWidth );
	
EndFunction 

Procedure loadRightValue ( Item, Filter )
	
	value = Filter.RightValue;
	if ( TypeOf ( value ) = Type ( "Array" ) ) then
		list = new ValueList ();
		list.LoadValues ( value );
		Item.RightValue = list;
	else
		Item.RightValue = value;
	endif;
	
EndProcedure

Procedure fixComparison ( Filter )
	
	parameter = TypeOf ( Filter ) = Type ( "DataCompositionSettingsParameterValue" );
	if ( parameter ) then
		candidate = DataCompositionComparisonType.InHierarchy;
		value = Filter.Value;
	else
		comparison = Filter.ComparisonType;
		if ( comparison = DataCompositionComparisonType.Equal ) then
			candidate = DataCompositionComparisonType.InHierarchy;
		elsif ( comparison = DataCompositionComparisonType.NotEqual ) then
			candidate = DataCompositionComparisonType.NotInHierarchy;
		else
			return;
		endif; 
		value = Filter.RightValue;
	endif; 
	if ( Metafields.IsFolder ( value ) ) then
		Filter.ComparisonType = candidate;
	endif; 
	
EndProcedure 

Function ComposeResult ( Report ) export
	
	p = Report.Params;
	setupPage ( p );
	setKey ( p );
	if ( p.Events.OnCompose ) then
		Report.OnCompose ();
	endif; 
	ok = putReport ( Report );
	if ( reportIsEmpty ( p ) ) then
		showEmpty ( p );
	else
		headerFooter ( p );
	endif; 
	return ok;

EndFunction

Function putReport ( Report )
	
	p = Report.Params;
	manager = Reports [ p.Name ];
	events = p.Events;
	if ( events.FullAccessRequest ) then
		SetPrivilegedMode ( manager.FullAccessRequest ( p ) );
	endif;
	if ( events.OnGetColumns
		and p.Columns = undefined ) then
		manager.OnGetColumns ( p.Variant, p.Columns );
	endif; 
	setupColumns ( p );
	getOutputParams ( p );
	encodeParams ( p );
	composer = new DataCompositionTemplateComposer ();
	details = ? ( p.Interactive, p.Details, undefined );
	template = executeComposer ( composer, p, details );
	if ( template = undefined ) then
		return false;
	endif; 
	getParts ( p, template );
	hideParams ( p, template );
	adjustHeader ( p, template );
	groupHeader ( p, template );
	decodeParams ( p, template );
	applyDirectives ( template );
	if ( events.OnPrepare ) then
		Report.OnPrepare ( template );
	endif; 
	processor = new DataCompositionProcessor ();
	processor.Initialize ( template, p.ExternalDataSets, ? ( p.Interactive, p.Details, undefined ), true, , p.TempTables );
	builder = new DataCompositionResultSpreadsheetDocumentOutputProcessor ();
	p.Result.Clear ();
	builder.SetDocument ( p.Result );
	output ( p, processor, builder, template );
	if ( events.AfterOutput ) then
		Report.AfterOutput ();
	endif;
	return true;

EndFunction

Procedure setupColumns ( Params )
	
	if ( Params.Columns = undefined ) then
		return;
	endif; 
	schema = Params.Schema;
	for each column in Params.Columns do
		path = column.Path;
		field = Reporter.FindField ( path, schema );
		if ( field = undefined ) then
			eventName = Metadata.Reports.Common.FullName () + ".setupColumns";
			WriteLogEvent ( eventName, EventLogLevel.Error,
			Metadata.Reports [ Params.Name ], , Output.DataSetColumnNotFound ( new Structure ( "Path", path ) ) );
		else
			properties = field.Appearance;
			properties.SetParameterValue ( "MaximumWidth", column.MaximumWidth );
		endif; 
	enddo; 
	
EndProcedure 

Function buildTemplate ( Params, Composer, Details )
	
	return Composer.Execute ( Params.Schema, Params.Settings, Details, , , Params.CheckAccess );
	
EndFunction 

Procedure applyDirectives ( DataTemplate )
	
	area = Type ( "DataCompositionAreaTemplate" );
	for each item in DataTemplate.Templates do
		if ( TypeOf ( item.Template ) = area ) then
			template = item.Template;
			changedRows = new Array ();
			for rowIndex = 0 to template.Count () - 1 do
				row = template [ rowIndex ];
				lastColumn = row.Cells.Count () - 1;
				skipRow = false;
				cleanup = false;
				for columnIndex = 0 to lastColumn do
					cell = row.Cells [ columnIndex ];
					for each field in cell.Items do
						value = field.Value;
						if ( StrStartsWith ( value, "#hideRow" ) ) then
							for fieldIndex = columnIndex to lastColumn do
								cleanCell ( row.Cells [ fieldIndex ] );
							enddo; 
							skipRow = true;
							cleanup = true;
							break;
						elsif ( StrStartsWith ( value, "#hideCell" ) ) then
							cleanCell ( cell );
							cleanup = true;
							break;
						endif;
					enddo;
					if ( skipRow ) then
						break;
					endif; 
				enddo; 
				if ( cleanup ) then
					changedRows.Insert ( 0, rowIndex );
				endif; 
			enddo; 
			cleanTemplate ( template, changedRows );
		endif; 
	enddo;

EndProcedure 

Procedure cleanCell ( Cells )
	
	Cells.Appearance.SetParameterValue ( "VerticalMerge", true );
	Cells.Items.Clear ();
	
EndProcedure 

Procedure cleanTemplate ( Template, Rows )
	
	for each rowIndex in Rows do
		row = Template [ rowIndex ];
		if ( rowEmpty ( row ) ) then
			Template.Delete ( rowIndex );
		endif; 
	enddo; 
	
EndProcedure 

Function rowEmpty ( Row )
	
	cells = Row.Cells;
	lastColumn = cells.Count () - 1;
	for column = 0 to lastColumn do
		cell = cells [ column ];
		for each field in cell.Items do
			if ( field.Value <> "" ) then
				return false;
			endif; 
		enddo;
	enddo; 
	return true;
	
EndFunction 

Procedure RestorePeriod ( Object ) export
	
	value = CommonSettingsStorage.Load ( periodSetting ( Object ) );
	if ( value = undefined ) then
		return;
	endif;
	parameter = getPeriod ( Object );
	if ( parameter = undefined
		or TypeOf ( parameter.Value ) <> TypeOf ( value ) ) then
		return;
	endif;
	parameter.Value = value;
	
EndProcedure

Function periodSetting ( Object )
	
	return "ReportPeriod/" + Object.ReportName;
	
EndFunction

Function getPeriod ( Object )
	
	variants = new Array ();
	variants.Add ( "Period" );
	variants.Add ( "AsOf" );
	variants.Add ( "ReportDate" );
	composer = Object.SettingsComposer;
	for each item in variants do
		parameter = DC.FindParameter ( composer, item );
		if ( parameter <> undefined
			and parameter.UserSettingID <> "" ) then
			return parameter;
		endif;
	enddo;
	return undefined;
	
EndFunction

Procedure StorePeriod ( Object ) export
	
	parameter = getPeriod ( Object );
	if ( parameter = undefined ) then
		return;
	endif;
	LoginsSrv.SaveSettings ( periodSetting ( Object ), , parameter.Value );
	
EndProcedure

Procedure DisableMenu ( Menu ) export
	
	Menu = null;
	
EndProcedure

Procedure AdjustGroupping ( Object, Name ) export
	
	group = DCsrv.GetGroup ( Object.Params.Settings, Name );
	if ( group = undefined ) then
		return;
	endif;
	groupFields = group.GroupFields.Items;
	fieldType = Type ( "DataCompositionSelectedField" );
	groupFieldType = Type ( "DataCompositionGroupField" );
	for each field in group.Selection.Items do
		if ( TypeOf ( field ) <> fieldType ) then
			continue;
		endif;
		dataField = field.Field;
		for each groupField in groupFields do
			if ( TypeOf ( groupField ) = groupFieldType
				and groupField.Field = dataField ) then
				groupField.Use = field.Use;
				break;
			endif; 
		enddo;
	enddo;
	
EndProcedure
