&AtClient
var TableRow;
&AtClient
var OldTableRow;
&AtClient
var CurrentFolder;
&AtClient
var PreviousArea;
&AtClient
var TotalsEnv;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setCompany ();
	showUserRepors ();
	activateReportCommands ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|CompanyFilter enable not Designer;
	|ProgramCodePage ExporterCodePage TabDoc OpenGenerator show Designer;
	|TotalInfo CalcTotals hide Designer;
	|ReportField show not Designer;
	|ListShowList show MasterMode;
	|ListShowMasters show not MasterMode;
	|FinancialPeriodField show RowPeriod <> Enum.Periods.None;
	|ShowReports ShowReports1 press ShowReports;
	|GroupReports show ShowReports;
	|Export show HasExport
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure setCompany ()
	
	settings = Logins.Settings ( "Company" );
	CompanyFilter = settings.Company;

EndProcedure 

&AtServer
Procedure showUserRepors ()
	
	ShowReports = true;
	MasterMode = false;
	DC.ChangeFilter ( List, "Master", false, true );
	filterByCompany ();
	Items.List.Representation = TableRepresentation.HierarchicalList;
	Appearance.Apply ( ThisObject, "MasterMode" );
	
EndProcedure 

&AtServer
Procedure filterByCompany ()
	
	if ( CompanyFilter.IsEmpty () ) then
		DC.DeleteFilter ( List, "Company" );
	else
		set = new Array ();
		set.Add ( Catalogs.Companies.EmptyRef () );
		set.Add ( CompanyFilter );
		DC.ChangeFilter ( List, "Company", set, true );
	endif;
	
EndProcedure 

&AtServer
Procedure activateReportCommands ()
	
	Items.Commands.CurrentPage = Items.ReportCommands;

EndProcedure 

&AtClient
Procedure BeforeClose ( Cancel , StandardProcessing )
	
	if ( Modified ) then
		Cancel = true;
		Output.SaveModifiedTemplate ( ThisObject, true );
	endif; 
	
EndProcedure

&AtClient
Procedure SaveModifiedTemplate ( Answer, Close ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		saveTemplate ();
	endif; 
	Modified = false;
	if ( Close ) then
		Close ();
	else
		setCurrentReport ();
		loadTemplate ();
	endif; 
	
EndProcedure 

&AtServer
Procedure saveTemplate ()

	if ( CurrentReport.IsEmpty () ) then
		return;
	endif; 
	writeDetails ();
	obj = CurrentReport.GetObject ();
	obj.Template = new ValueStorage ( TabDoc );
	obj.Program = new ValueStorage ( ProgramCode );
	obj.Exporter = new ValueStorage ( ExporterCode );
	obj.HasExport = not IsBlankString ( ExporterCode );
	RegulatoryReports.WriteDependencies ( obj, ProgramCode );
	obj.Write ();
	Modified = false;

EndProcedure 

&AtServer
Procedure writeDetails ()
	
	top = TabDoc.TableHeight;
	right = TabDoc.TableWidth;
	for i = 1 to top do
		for j = 1 to right do
			area = TabDoc.Area ( i, j, i, j );
			if ( area.FillType = SpreadsheetDocumentAreaFillType.Parameter ) then
				area.DetailsParameter = "_Detail_" + area.Parameter;
			else
				area.DetailsParameter = "";
			endif;
		enddo; 
	enddo; 
	
EndProcedure 

&AtClient
Procedure setCurrentReport ()
	
	CurrentReport = TableRow.Ref;
	RowPeriod = TableRow.Period;
	Appearance.Apply ( ThisObject, "RowPeriod" );

EndProcedure 

&AtServer
Procedure loadTemplate ()
	
	TabDoc.Clear ();
	data = DF.Values ( CurrentReport, "Template, Program, Exporter" );
	t = data.Template.Get ();
	if ( TypeOf ( t ) = Type ( "SpreadsheetDocument" ) ) then
		TabDoc = t;
	endif; 
	ProgramCode = data.Program.Get ();
	ExporterCode = data.Exporter.Get ();
	setTitle ( ThisObject );
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setTitle ( Form )
	
	Form.Title = "" + Form.CurrentReport;
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure LoadForm ( Command )
	
	startUploading ( "Template" );
	
EndProcedure

&AtClient
Procedure startUploading ( Type )
	
	#if ( WebClient ) then
		Output.WebclientIsNotSupported ();
		return;
	#endif
	ShowInputString ( new NotifyDescription ( "EnterFileName", ThisObject, Type ), , Output.EnterFileName () );
	
EndProcedure

&AtClient
Procedure EnterFileName ( File, Type ) export
	
	if ( not ValueIsFilled ( File ) ) then
		return;
	endif; 
	files = new Array ();
	files.Add ( new TransferableFileDescription ( File ) );
	BeginPuttingFiles ( new NotifyDescription ( "PuttingFiles", ThisObject, Type ), files, , false, UUID );
	
EndProcedure 

&AtClient
Procedure PuttingFiles ( Files, Type ) export
	
	if ( Files.Count () = 0 ) then
		return;
	endif; 
	loadFile ( Files, Type );
	
EndProcedure 

&AtServer
Procedure loadFile ( val Files, val Type )
	
	data = GetFromTempStorage ( Files [ 0 ].Location );
	if ( Type = "Template" ) then
		file = GetTempFileName ( "mxl" );
		data.Write ( file );
		TabDoc.Read ( file );
	else
		file = GetTempFileName ( "bsl" );
		data.Write ( file );
		reader = new TextReader ( file );
		if ( Type = "Module" ) then
			ProgramCode = reader.Read ();
		else
			ExporterCode = reader.Read ();
		endif;
		reader.Close ();
	endif; 
	setModified ( ThisObject );
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setModified ( Form )
	
	Form.Modified = true;
	
EndProcedure 

&AtClient
Procedure LoadScript ( Command )
	
	startUploading ( "Module" );
	
EndProcedure

&AtClient
Procedure LoadExporter ( Command )
	
	startUploading ( "Exporter" );
	
EndProcedure

&AtClient
Procedure FinancialPeriodFieldOpening ( Item, StandardProcessing )
	
	StandardProcessing = false;
	openPeriod ();
	
EndProcedure

&AtClient
Procedure openPeriod ()
	
	period = DF.Values ( CurrentReport, "DateStart, DateEnd" );
	dialog = new StandardPeriodEditDialog ();
	dialog.Period = new StandardPeriod ( period.DateStart, period.DateEnd );
	dialog.Show ( new NotifyDescription ( "PeriodChanged", ThisObject ) );
	
EndProcedure 

&AtClient
Procedure PeriodChanged ( NewPeriod, Params ) export
	
	if ( NewPeriod = undefined ) then
		return;
	endif; 
	loadReport ( ThisObject, NewPeriod );
	NotifyChanged ( CurrentReport );
	
EndProcedure 

&AtClientAtServerNoContext
Procedure loadReport ( Form, NewPeriod = undefined, val Rebuild = false )
	
	data = getReport ( Form.CurrentReport, NewPeriod, Rebuild );
	Form.ReportField = data.Report;
	Form.Areas = data.Areas;
	Form.HasExport = data.HasExport;
	Form.FinancialPeriodField = data.FinancialPeriod;
	Appearance.Apply ( Form, "HasExport" );
	setTitle ( Form );

EndProcedure

&AtServerNoContext
Function getReport ( val CurrentReport, val NewPeriod, val Rebuild )
	
	obj = CurrentReport.GetObject ();
	if ( NewPeriod <> undefined ) then
		financialPeriod ( obj, NewPeriod );
		RegulatoryReports.WriteDependencies ( obj, obj.Program.Get () );
	endif; 
	wasCalculated = obj.Calculated;
	if ( Rebuild
		or NewPeriod <> undefined ) then
		obj.Calculated = false;
	endif;
	tabDoc = new SpreadsheetDocument ();
	areas = obj.Build ( tabDoc );
	if ( NewPeriod <> undefined
		or not wasCalculated ) then
		obj.Calculated = true;
		obj.Write ();
	endif; 
	return new Structure ( "Report, Areas, HasExport, FinancialPeriod",
		tabDoc, areas, obj.HasExport, obj.FinancialPeriod );
	
EndFunction

&AtServerNoContext
Procedure financialPeriod ( Report, Period = undefined )
	
	term = ? ( Report.Master, Report.Period, DF.Pick ( Report.MasterReport, "Period" ) );
	newPeriod = adjustPeriod ( term, Period );
	if ( newPeriod = undefined ) then
		startDate = undefined;
		endDate = undefined;
		presentation = "";
	else
		startDate = newPeriod.StartDate;
		endDate = newPeriod.EndDate;
		presentation = Periods.Presentation ( startDate, endDate );
	endif; 
	Report.DateStart = startDate;
	Report.DateEnd = endDate;
	Report.FinancialPeriod = presentation;

EndProcedure 

&AtServerNoContext
Function adjustPeriod ( Term, val Period )
	
	if ( Term = PredefinedValue ( "Enum.Periods.None" ) ) then
		return undefined;
	endif;
	if ( Period = undefined ) then
		Period = new StandardPeriod ( StandardPeriodVariant.Month );
	endif; 
	startDate = Period.StartDate;
	if ( Term = PredefinedValue ( "Enum.Periods.HalfYear" ) ) then
		year = Year ( startDate );
		if ( Month ( startDate ) > 6 ) then
			Period.StartDate = Date ( year, 7, 1 );
			Period.EndDate = Date ( year, 12, 31, 23, 59, 59 );
		else
			Period.StartDate = Date ( year, 1, 1 );
			Period.EndDate = Date ( year, 6, 30, 23, 59, 59 );
		endif; 
	elsif ( Term = PredefinedValue ( "Enum.Periods.Month" ) ) then
		Period.StartDate = BegOfMonth ( startDate );
		Period.EndDate = EndOfMonth ( startDate );
	elsif ( Term = PredefinedValue ( "Enum.Periods.Quarter" ) ) then
		Period.StartDate = BegOfQuarter ( startDate );
		Period.EndDate = EndOfQuarter ( startDate );
	elsif ( Term = PredefinedValue ( "Enum.Periods.Year" ) ) then
		Period.StartDate = BegOfYear ( startDate );
		Period.EndDate = EndOfYear ( startDate );
	endif; 
	return Period;
	
EndFunction

&AtClient
Procedure CompanyFilterOnChange ( Item )
	
	filterByCompany ();
	
EndProcedure

// *****************************************
// *********** Group ReportField

&AtClient
Procedure ReportFieldOnChange ( Item )
	
	writeUserValue ();
	PreviousArea = undefined;
	
EndProcedure

&AtClient
Procedure writeUserValue ()
	
	try
		if ( ReportField.CurrentArea.Details = undefined ) then
			return;
		endif; 
	except
		return;
	endtry;
	currentArea = ReportField.CurrentArea;
	applyUserValue ( ? ( currentArea.ContainsValue, currentArea.Value, currentArea.Text ), currentArea.Details, currentArea.ContainsValue );
	
EndProcedure 

&AtServer
Procedure applyUserValue ( val Value, val Field, val ContainsValue )
	
	RegulatoryReports.SaveUserValue ( CurrentReport, Value, Field, ContainsValue );
	refreshCopies ( Value, Field );
	changes = calcDependencies ( Field );
	putChanges ( changes );
	
EndProcedure 

&AtServer
Procedure refreshCopies ( Value, Field )
	
	set = Areas [ Field ];
	if ( set.Count () = 1 ) then
		return;
	endif; 
	for each area in set do
		fieldArea = ReportField.Area ( area );
		if ( fieldArea.ContainsValue ) then
			fieldArea.Value = Value;
		else
			fieldArea.Text = Value;
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Function calcDependencies ( Field )
	
	objects = new Map ();
	recalculatedFields = new Array ();
	RegulatoryReports.FixCalculation ( recalculatedFields, CurrentReport, Field );
	table = RegulatoryReports.GetDependants ( CurrentReport, Field );
	for each row in table do
		report = row.DependentReport;
		if ( objects [ report ] = undefined ) then
			objects [ report ] = report.GetObject ();
		endif; 
		obj = objects [ report ];
		dependentField = row.DependentField;
		if ( Lower ( dependentField ) = "make" ) then
			refreshDependant ( obj );
		else
			obj.CalcField ( dependentField, recalculatedFields );
		endif; 
	enddo; 
	return recalculatedFields;
	
EndFunction

&AtServer
Procedure refreshDependant ( Obj )
	
	wasCalculated = Obj.Calculated;
	Obj.Calculated = false;
	if ( Obj.Ref = CurrentReport ) then
		Areas = Obj.Build ( ReportField, CurrentReport );
	else
		Obj.Build ( obj.Template.Get (), CurrentReport );
	endif;
	if ( not wasCalculated ) then
		Obj.Calculated = true;
		Obj.Write ();
	endif; 
	
EndProcedure 

&AtServer
Procedure putChanges ( Changes )
	
	values = readValues ();
	for each item in Changes do
		if ( item.Report <> CurrentReport ) then
			continue;
		endif; 
		field = values.Find ( item.Field, "Field" );
		if ( field = undefined ) then
			continue;
		endif; 
		value = field.Value;
		for each area in Areas [ item.Field ] do
			fieldArea = ReportField.Area ( area );
			if ( fieldArea.ContainsValue ) then
				fieldArea.Value = value;
			else
				fieldArea.Text = value;
			endif; 
		enddo; 
	enddo; 
	
EndProcedure 

&AtServer
Function readValues ()
	
	str = "
	|select ReportFields.Field as Field, isnull ( UserFields.Value, ReportFields.Value ) as Value
	|from InformationRegister.ReportFields as ReportFields
	|	//
	|	// UserFields
	|	//
	|	left join InformationRegister.UserFields as UserFields
	|	on UserFields.Field = ReportFields.Field
	|	and UserFields.Report = ReportFields.Report
	|where ReportFields.Report = &Report
	|";
	q = new Query ( str );
	q.SetParameter ( "Report", CurrentReport );
	return q.Execute ().Unload ();
	
EndFunction 

// *****************************************
// *********** Group TabDoc

&AtClient
Procedure RefreshReport ( Command )
	
	if ( TableRow = undefined ) then
		return;
	endif; 
	updateReport ();
	
EndProcedure

&AtServer
Procedure updateReport ()
	
	clearSystemData ();
	userInput = fetchUserInput ();
	clearUserData ();
	loadReport ( ThisObject, , true );
	if ( userInput.Count () > 0 ) then
		userInput.Write ();
		loadReport ( ThisObject );
	endif;
	
EndProcedure

&AtServer
Function fetchUserInput ()
	
	r = InformationRegisters.UserFields.CreateRecordSet ();
	r.Filter.Report.Set ( CurrentReport );
	r.Read ();
	return r;
	
EndFunction

&AtServer
Procedure clearSystemData ()
	
	recordset = InformationRegisters.ReportFields.CreateRecordSet ();
	recordset.Filter.Report.Set ( CurrentReport );
	recordset.Write ();

EndProcedure

&AtClient
Procedure Design ( Command )
	
	if ( TableRow = undefined ) then
		return;
	endif; 
	if ( Designer ) then
		return;
	endif; 
	enableDesigner ();
	
EndProcedure

&AtServer
Procedure enableDesigner ()
	
	loadTemplate ();
	Items.Commands.CurrentPage = Items.DesignerCommands;
	CurrentItem = Items.ProgramCode;
	Designer = true;
	Appearance.Apply ( ThisObject, "Designer" );
	
EndProcedure 

&AtClient
Procedure Reload ( Command )
	
	if ( Modified ) then
		Output.ReloadTemplateConfirmation ( ThisObject );
	else
		loadTemplate ();
	endif; 
		
EndProcedure 

&AtClient
Procedure ReloadTemplateConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	loadTemplate ();
	
EndProcedure 

&AtClient
Procedure CancelDesign ( Command )
	
	if ( Modified ) then
		Output.CancelDesignConfirmation ( ThisObject );
	else
		disableDesigner ();
	endif; 

EndProcedure

&AtClient
Procedure CancelDesignConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	disableDesigner ();
	
EndProcedure 

&AtClient
Procedure OpenGenerator ( Command )

	OpenForm ( "Catalog.Reports.Form.Generator", , ThisObject, , , ,
		new NotifyDescription ( "GenerateFields", ThisObject ) );

EndProcedure

&AtClient
Procedure GenerateFields ( Params, Nothing ) export
	
	if ( Params = undefined ) then
		return;
	endif;
	templateMode ();
	enumerate ( Params );
	
EndProcedure

&AtServer
Procedure templateMode ()
	
	TabDoc.Template = true;
	setModified ( ThisObject );	
	
EndProcedure

&AtClient
Procedure enumerate ( Params )
	
	areaID = 0;
	set = TabDoc.SelectedAreas;
	k = TabDoc.SelectedAreas.Count ();
	while ( k > 0 ) do
		k = k - 1;
		selection = set [ k ];
		column = selection.Left;
		i = selection.Top;
		bottom = selection.Bottom;
		while ( true ) do
			area = TabDoc.Area ( i, column );
			if ( area.Top <> area.Bottom ) then
				areaBottom = area.Bottom;
				area = TabDoc.Area ( i, column, i, column );
				i = areaBottom;
			endif;
			setProperties ( area, areaID, Params );
			if ( i = bottom ) then
				break;
			endif;
			areaID = areaID + 1;
			i = i + 1;
		enddo;
	enddo;

EndProcedure

&AtClient
Procedure setProperties ( Area, ID, Params )
	
	Area.FillType = SpreadsheetDocumentAreaFillType.Parameter;
	Area.Parameter = Params.Prefix + Format ( Params.StartFrom + ID, "NG=;NZ=" );
	containsValue = Params.ContainsValue;
	Area.ContainsValue = containsValue;
	if ( containsValue ) then
		Area.ValueType = Params.ValueType;
	endif;
	
EndProcedure

&AtClient
Procedure TabDocOnChange ( Item )
	
	setModified ( ThisObject );
	
EndProcedure

&AtClient
Procedure Save ( Command )
	
	saveTemplate ();
	
EndProcedure

&AtClient
Procedure Rebuild ( Command )
	
	if ( TableRow = undefined ) then
		return;
	endif; 
	Output.UserDataWillBeCleared ( ThisObject );
	
EndProcedure

&AtClient
Procedure UserDataWillBeCleared ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	rebuildReport ();
	
EndProcedure 

&AtServer
Procedure rebuildReport ()
	
	clearUserData ();
	clearSystemData ();
	loadReport ( ThisObject, , true );
	
EndProcedure 

&AtServer
Procedure clearUserData ()
	
	recordset = InformationRegisters.UserFields.CreateRecordSet ();
	recordset.Filter.Report.Set ( CurrentReport );
	recordset.Write ();
	
EndProcedure 

&AtClient
Procedure Build ( Command )
	
	if ( not Designer ) then
		return;
	endif;
	setCurrentReport ();
	saveAndBuild ();
	
EndProcedure

&AtServer
Procedure saveAndBuild ()
	
	saveTemplate ();
	disableDesigner ();
	rebuildReport ();
	
EndProcedure 

&AtServer
Procedure disableDesigner ()
	
	Items.Commands.CurrentPage = Items.ReportCommands;
	CurrentItem = Items.ReportField;
	Designer = false;
	Modified = false;
	Appearance.Apply ( ThisObject, "Designer" );
	
EndProcedure 

&AtClient
Procedure ProgramCodeOnChange ( Item )
	
	setModified ( ThisObject );	
	
EndProcedure 

// *****************************************
// *********** Group List

&AtClient
Procedure ShowMasters ( Command )
	
	showMasterRepors ();
	
EndProcedure

&AtServer
Procedure showMasterRepors ()
	
	MasterMode = true;
	DC.ChangeFilter ( List, "Master", true, true );
	Items.List.Representation = TableRepresentation.List;
	Appearance.Apply ( ThisObject, "MasterMode" );
	
EndProcedure 

&AtClient
Procedure ShowList ( Command )
	
	showUserRepors ();
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	if ( Clone or Folder ) then
		return;
	endif;
	Cancel = true;
	if ( not Forms.CheckFields ( ThisObject, "CompanyFilter" ) ) then
		return;
	endif;
	if ( MasterMode ) then
		createMaster ( Item, Parent );
	else
		chooseMaster ( Item, Parent );
	endif; 
	
EndProcedure

&AtClient
Procedure createMaster ( Item, Parent )
	
	p = new Structure ( "Master", true );
	OpenForm ( "Catalog.Reports.Form.Master", new Structure ( "FillingValues", p ), Item );
	
EndProcedure 

&AtClient
Procedure chooseMaster ( Item, Parent )
	
	CurrentFolder = Parent;
	OpenForm ( "Catalog.Reports.Form.Choice", , Item );
	
EndProcedure 

&AtClient
Procedure ListChoiceProcessing ( Item, SelectedValue, StandardProcessing )
	
	ref = createReport ( SelectedValue, CurrentFolder, CompanyFilter );
	NotifyChanged ( ref );
	Items.List.CurrentRow = ref;
		
EndProcedure

&AtServerNoContext
Function createReport ( val Master, val Folder, val Company )
	
	obj = newReport ( Master, Folder, Company );
	RegulatoryReports.WriteDependencies ( obj, obj.Program.Get () );
	return obj.Ref;
	
EndFunction 

&AtServerNoContext
Function newReport ( Master, Folder, Company )
	
	obj = Catalogs.Reports.CreateItem ();
	obj.Parent = Folder;
	obj.Company = Company;
	obj.Creator = SessionParameters.User;
	obj.Date = CurrentSessionDate ();
	obj.MasterReport = Master;
	data = DF.Values ( Master, "Description, Program, Template, Exporter, HasExport" );
	obj.Description = data.Description;
	obj.HasExport = data.HasExport;
	Catalogs.Reports.CopyInternals ( data, obj );
	financialPeriod ( obj );
	obj.Write ();
	return obj;
	
EndFunction 

&AtClient
Procedure ListOnActivateRow ( Item )
	
	DetachIdleHandler ( "openReport" );
	TableRow = Items.List.CurrentData;
	if ( oldRow () ) then
		return;
	endif;
	OldTableRow = TableRow;
	activatePanel ();
	if ( Modified ) then
		Output.SaveModifiedTemplate ( ThisObject, false );
	else
		AttachIdleHandler ( "openReport", 0.3, true );
	endif; 
	
EndProcedure

&AtClient
Function oldRow ()
	
	return TableRow = undefined
	or ( OldTableRow <> undefined
	and TableRow.Ref = OldTableRow.Ref );
		
EndFunction 
	
&AtClient
Procedure activatePanel ()
	
	if ( TableRow.IsFolder ) then
		Items.Pages.CurrentPage = Items.Nothing;
	else
		Items.Pages.CurrentPage = Items.WorkPlace;
	endif; 
	
EndProcedure 

&AtClient
Procedure openReport () export
	
	setCurrentReport ();
	if ( TableRow.IsFolder ) then
		return;
	else
		if ( Designer ) then
			loadTemplate ();
		else
			loadReport ( ThisObject );
		endif; 
	endif; 
	
EndProcedure 

&AtClient
Procedure ShowReports ( Command )
	
	toggleReports ();
	
EndProcedure

&AtServer
Procedure toggleReports ()
	
	ShowReports = not ShowReports;
	Appearance.Apply ( ThisObject, "ShowReports" );
	
EndProcedure 

// *****************************************
// *********** Page Exporter

&AtClient
Procedure CheckSyntax ( Command )
	
	checkCode ();
	activateEditor ();
	
EndProcedure

&AtClient
Procedure checkCode ()
	
	error = findError ();
	if ( error = undefined ) then
		OpenForm ( "CommonForm.SyntaxPassed" );
	else
		ShowValue ( , error );
	endif;
	
EndProcedure 

&AtServer
Function findError ()
	
	code = DataProcessors.Compiler.Syntax ( ExporterCode );
	tester = Catalogs.Reports.CreateItem ();
	try
		tester.RunScript ( code );
	except
		return BriefErrorDescription ( ErrorInfo () );
	endtry;
	return undefined;
	
EndFunction

&AtClient
Procedure activateEditor () export
	
	CurrentItem = Items.ExporterCode;
	
EndProcedure 

&AtClient
Procedure ExportReport ( Command )
	
	callback = new NotifyDescription ( "StartExport", ThisObject );
	LocalFiles.Prepare ( callback );
	
EndProcedure

&AtClient
Procedure StartExport ( Result, Params ) export
	
	data = exportData ();
	if ( TypeOf ( data ) = Type ( "TransferableFileDescription" ) ) then
		links = new Array ();
		links.Add ( data );
	else
		links = data;
	endif;
	BeginGettingFiles ( new NotifyDescription ( "GettingFiles", ThisObject, links ), links );
	
EndProcedure 

&AtServer
Function exportData ()
	
	obj = CurrentReport.GetObject ();
	obj.FormUUID = UUID;
	code = DataProcessors.Compiler.Compile ( obj.Exporter.Get () );
	obj.RunScript ( code );
	data = obj.ExporterData;
	if ( data = undefined ) then
		raise Output.ExportDataUndefined ();
	else
		return data;
	endif;
	
EndFunction

&AtClient
Procedure GettingFiles ( Files, Links ) export
	
	for each item in Links do
		DeleteFromTempStorage ( item.Location );
	enddo;
	if ( Files = undefined ) then
		return;
	endif; 
	Output.ExportDataCompleted ();
	
EndProcedure

&AtClient
Procedure ReportFieldOnActivateArea ( Item )

	if ( drawing ()
		or sameArea () ) then
		return;
	endif;
	startCalculation ();
	
EndProcedure

&AtClient
Function drawing ()
	
	return TypeOf ( ReportField.CurrentArea ) <> Type ( "SpreadsheetDocumentRange" );
	
EndFunction 

&AtClient
Function sameArea ()
	
	currentName = ReportField.CurrentArea.Name;
	if ( PreviousArea = currentName ) then
		return true;
	else
		PreviousArea = currentName;
		return false;
	endif; 
	
EndFunction

&AtClient
Procedure startCalculation ()
	
	DetachIdleHandler ( "startUpdating" );
	AttachIdleHandler ( "startUpdating", 0.2, true );
	
EndProcedure 

&AtClient
Procedure startUpdating ()
	
	updateTotals ( true );
	
EndProcedure

&AtClient
Procedure updateTotals ( CheckSquare )
	
	if ( TotalsEnv = undefined ) then
		SpreadsheetTotals.Init ( TotalsEnv );	
	endif;
	TotalsEnv.Spreadsheet = ReportField;
	TotalsEnv.CheckSquare = CheckSquare;
	SpreadsheetTotals.Update ( TotalsEnv );
	Items.CalcTotals.Visible = CheckSquare and TotalsEnv.HugeSquare;
	TotalInfo = TotalsEnv.Result; 
	
EndProcedure

&AtClient
Procedure CalcTotals ( Command )
	
	updateTotals ( false );
	
EndProcedure 
