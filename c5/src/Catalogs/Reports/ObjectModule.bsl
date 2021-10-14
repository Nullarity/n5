#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var T;
var TabDoc;
var Procedures export;
var ExecutedProcedures export;
var Areas;
var Exp;
var ProcedureName;
var Script;
var Area;
var Fields export;
var UserFields;
var ExternalFields;
var ReportObjects;
var MakeComplete;
var TemplateParameters;
var FieldProcedures export;
var InternalProcessing;
var ObjectIsInitialized;
var Env export;
var DataMapping export;
var FieldsValues export;
var Parameters;
var Stack export;
var CalledBy;
var ExporterData export;
var FormUUID export;

Procedure RunScript ( Code ) export
	
	//@skip-warning
	_procedures = new Map ();
	Execute ( Code );

EndProcedure

Function Build ( Spreadsheet = undefined, RequestedBy = undefined ) export
	
	CalledBy = RequestedBy;
	if ( not ObjectIsInitialized ) then
		initEnv ( Spreadsheet );
		initStack ();
		if ( T = undefined ) then
			return undefined;
		endif; 
		initExternalFields ();
		readUserFields ();
		readTemplateParameters ();
		RegulatoryReports.DisassembleProgramCode ( ThisObject, Program.Get (), true );
		ObjectIsInitialized = true;
	endif; 
	BeginTransaction ();
	make ();
	makeAll ();
	CommitTransaction ();
	return ? ( InternalProcessing, undefined, Areas );
	
EndFunction

Procedure initEnv ( Spreadsheet )
	
	MakeComplete = false;
	Fields = new Map ();
	SQL.Init ( Env );
	InternalProcessing = ( Spreadsheet = undefined );
	T = Template.Get ();
	if ( not InternalProcessing ) then
		TabDoc = Spreadsheet;
		TabDoc.Clear ();
	endif; 
	
EndProcedure 

Procedure initStack ()
	
	alreadyCreated = ( Stack <> undefined );
	if ( alreadyCreated ) then
		return;
	endif; 
	Stack = new Array ();
	
EndProcedure 

Procedure initExternalFields ()
	
	ExternalFields = new ValueTable ();
	ExternalFields.Columns.Add ( "Report" );
	ExternalFields.Columns.Add ( "Parameter", new TypeDescription ( "String" ) );
	ExternalFields.Columns.Add ( "Value" );
	ExternalFields.Indexes.Add ( "Report, Parameter" );
	
EndProcedure 

Procedure readUserFields ()
	
	UserFields = new Map ();
	table = getUserFields ();
	for each row in table do
		UserFields [ row.Field ] = row.Value;
	enddo; 

EndProcedure 

Function getUserFields ()
	
	s = "
	|select UserFields.Field as Field, UserFields.Value as Value
	|from InformationRegister.UserFields as UserFields
	|where UserFields.Report = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	return q.Execute ().Unload ();

EndFunction

Procedure readTemplateParameters ()
	
	TemplateParameters = new Structure ();
	FieldProcedures = new Map ();
	top = T.TableHeight;
	right = T.TableWidth;
	for i = 1 to top do
		for j = 1 to right do
			area = T.Area ( i, j, i, j );
			if ( area.DetailsParameter = "" ) then
				continue;
			endif;
			TemplateParameters.Insert ( area.DetailsParameter, area.Parameter );
			FieldProcedures [ area.Parameter ] = true;
		enddo; 
	enddo; 
	
EndProcedure 

Procedure make ()
	
	script = Procedures [ "Make" ];
	if ( script <> undefined ) then
		if ( ExecutedProcedures [ "Make" ] = undefined ) then
			execute ( script );
			ExecutedProcedures [ "Make" ] = true;
		endif; 
	endif; 
	readLocations ();

EndProcedure 

Procedure readLocations ()
	
	if ( InternalProcessing ) then
		return;
	endif; 
	Areas = new Structure ();
	top = TabDoc.TableHeight;
	right = TabDoc.TableWidth;
	for i = 1 to top do
		for j = 1 to right do
			area = TabDoc.Area ( i, j, i, j );
			if ( area.Details = undefined ) then
				continue;
			endif;
			if ( not Areas.Property ( area.Details ) ) then
				Areas.Insert ( area.Details, new Array () );
			endif; 
			parameterAreas = Areas [ area.Details ];
			parameterAreas.Add ( TabDoc.Area ( i, j ).Name );
		enddo; 
	enddo; 
	
EndProcedure 

Procedure makeAll ()
	
	MakeComplete = true;
	for each proc in FieldProcedures do
		k = proc.Key;
		if ( Procedures [ k ] = undefined ) then
			drawValue ( k, get ( k ) );
		else
			if ( ExecutedProcedures [ k ] = undefined ) then
				execute ( Procedures [ k ] );
				ExecutedProcedures [ k ] = true;
			endif; 
		endif; 
	enddo; 
	
EndProcedure 

Procedure drawValue ( Parameter, Value )
	
	if ( MakeComplete ) then
		for each areaName in Areas [ Parameter ] do
			Area = TabDoc.Area ( areaName );
			if ( Area.ContainsValue ) then
				Area.Value = Value;
			else
				Area.Text = Value;
			endif; 
		enddo; 
	else
		Area.Parameters [ Parameter ] = Value;
	endif; 
	
EndProcedure 

Procedure CalcField ( Field, RecalculatedFields ) export
	
	if ( RegulatoryReports.FieldCalculated ( Field, RecalculatedFields ) ) then
		return;
	endif; 
	if ( not Calculated ) then
		raise Output.ReportNotCalculated ( new Structure ( "Report", Description ) );
	endif; 
	if ( not ObjectIsInitialized ) then
		InternalProcessing = true;
		initEnv ( undefined );
		initStack ();
		initExternalFields ();
		readUserFields ();
		readTemplateParameters ();
		RegulatoryReports.DisassembleProgramCode ( ThisObject, Program.Get (), true );
		ObjectIsInitialized = true;
	endif; 
	execute Procedures [ Field ];
	RegulatoryReports.FixCalculation ( RecalculatedFields, Ref, Field );
	calcDependentFields ( Field, RecalculatedFields );
	
EndProcedure 

Procedure calcDependentFields ( Field, RecalculatedFields )
	
	objects = new Map ();
	table = RegulatoryReports.GetDependants ( Ref, Field );
	for each row in table do
		if ( row.DependentReport = Ref ) then
			CalcField ( row.DependentField, RecalculatedFields );
		else
			if ( objects [ row.DependentReport ] = undefined ) then
				objects [ row.DependentReport ] = row.DependentReport.GetObject ();
			endif; 
			obj = objects [ row.DependentReport ];
			obj.CalcField ( row.DependentField, recalculatedFields );
		endif; 
	enddo; 
	
EndProcedure 

#region ReportFunctions

Procedure mapField ( Field, KeyField, ParamsList = undefined, Dataset = "Table" ) export
	
	row = DataMapping.Add ();
	row.Key = KeyField;
	row.Field = Field;
	row.Dataset = Dataset;
	keys = Conversion.StringToArray ( KeyField );
	if ( keys.Count () > 1 and ParamsList = undefined ) then
		raise Output.MapFieldError ();
	endif; 
	if ( ParamsList = undefined ) then
		Parameters [ Field ] = KeyField;
	else
		if ( Parameters [ ParamsList ] = undefined ) then
			Parameters [ ParamsList ] = new Array ();
		endif; 
		list = Parameters [ ParamsList ];
		for each item in keys do
			if ( list.Find ( item ) = undefined ) then
				list.Add ( item );
			endif; 
		enddo; 
	endif; 
	
EndProcedure 

Procedure assignField ( Field, KeyField = undefined, Dataset = "Table" ) export
	
	row = DataMapping.Add ();
	row.Key = ? ( KeyField = undefined, Field, KeyField );
	row.Field = Field;
	row.Dataset = Dataset;
	
EndProcedure 

Procedure assignTable ( Dataset = "Table" ) export
	
	table = Env [ Dataset ];
	for each row in table do
		FieldsValues [ row.Key ] = row.Value;
	enddo; 
	
EndProcedure 

Function getArea ( AreaName = undefined ) export
	
	return ? ( InternalProcessing, undefined, T.GetArea ( AreaName ) );
	
EndFunction

Procedure put ( Parameter, Value ) export
	
	userValue = UserFields [ Parameter ];
	actualValue = ? ( userValue = undefined, Value, userValue );
	RegulatoryReports.WriteParameter ( ThisObject, Parameter, actualValue );
	if ( InternalProcessing ) then
		return;
	endif; 
	drawValue ( Parameter, actualValue );

EndProcedure 

Function get ( Parameter, Report = undefined ) export
	
	reference = ? ( Report = undefined, Ref, RegulatoryReports.Search ( ThisObject, Report, false ) );
	return getParameterValue ( Parameter, reference );
	
EndFunction 

Function getLast ( Parameter, Report = undefined )
	
	reportName = ? ( Master, Name, DF.Pick ( MasterReport, "Name" ) );
	reference = RegulatoryReports.Search ( ThisObject, ? ( Report = undefined, reportName, Report ), true );
	if ( reference = undefined ) then
		return 0;
	else
		return getParameterValue ( Parameter, reference );
	endif; 

EndFunction 

Procedure getData () export
	
	for each item in Parameters do
		Env.Q.SetParameter ( item.Key, item.Value );
	enddo; 
	SQL.Prepare ( Env );
	Env.Q.SetParameter ( "DateStart", DateStart );
	Env.Q.SetParameter ( "DateEnd", DateEnd );
	Env.Q.SetParameter ( "Company", Company );
	Env.Q.SetParameter ( "LastYearDateStart", AddMonth ( DateStart, -12 ) );
	Env.Q.SetParameter ( "LastYearDateEnd", AddMonth ( DateEnd, -12 ) );
	data = Env.Q.ExecuteBatch ();
	SQL.Unload ( Env, data );
	
EndProcedure 

Procedure draw () export
	
	if ( InternalProcessing ) then
		return;
	endif; 
	Area.Parameters.Fill ( TemplateParameters );
	TabDoc.Put ( Area );
	
EndProcedure 

Function sum ( Parameter, Report = undefined ) export
	
	return sumFields ( Parameter, Report, false );
	
EndFunction 

Function sumLast ( Parameter, Report = undefined ) export
	
	return sumFields ( Parameter, Report, true );
	
EndFunction 

Procedure exportFile ( File ) export
	
	if ( MasterReport.IsEmpty () ) then
		masterName = Name;
	else
		masterName = DF.Pick ( MasterReport, "Name" );
	endif;
	fileName = masterName + "-" + Format ( CurrentSessionDate (), "DF=yyyy-MM-dd" ) + ".xml";
	ExporterData = new TransferableFileDescription ( fileName, PutToTempStorage ( new BinaryData ( File ), FormUUID ) );
	DeleteFiles ( File );
	
EndProcedure

#endregion

Function getParameterValue ( Parameter, Reference )
	
	if ( resursion ( Parameter, Reference ) ) then
		value = RegulatoryReports.Retrieve ( ThisObject, Parameter );
	else
		push ( Parameter, Reference );
		if ( Reference = Ref ) then
			value = getHere ( Parameter );
		else
			value = getThere ( Parameter, Reference );
		endif; 
		pop ();
	endif; 
	return value;
	
EndFunction 

Function resursion ( Parameter, Report )
	
	i = Stack.UBound ();
	while ( i >= 0 ) do
		call = Stack [ i ];
		if ( call.Parameter = Parameter
			and call.Report = Report ) then
			return true;
		endif; 
		i = i - 1;
	enddo; 
	return false;
	
EndFunction 

Procedure push ( Parameter, Report )
	
	Stack.Add ( new Structure ( "Parameter, Report", Parameter, Report ) );
	
EndProcedure 

Function getHere ( Parameter )
	
	value = UserFields [ Parameter ];
	if ( value = undefined ) then
		value = Fields [ Parameter ];
	endif; 
	if ( value = undefined ) then
		if ( Calculated ) then
			value = RegulatoryReports.GetStoredField ( ExternalFields, Parameter, Ref );
			if ( value = undefined ) then
				value = 0;
			endif; 
			Fields [ Parameter ] = value;
		else
			script = Procedures [ Parameter ];
			if ( script = undefined ) then
				value = RegulatoryReports.Retrieve ( ThisObject, Parameter );
			else
				execute ( script );
				value = Fields [ Parameter ];
			endif; 
		endif; 
	endif; 
	return value;
	
EndFunction 

Function getThere ( Parameter, Report )
	
	result = ExternalFields.FindRows ( new Structure ( "Report, Parameter", Report, Parameter ) );
	if ( result.Count () = 0 ) then
		value = RegulatoryReports.GetStoredField ( ExternalFields, Parameter, Report );
	else
		value = result [ 0 ].Value;
	endif; 
	if ( value = undefined ) then
		obj = getReport ( Report );
		value = obj.get ( Parameter );
	endif; 
	return value;
	
EndFunction 

Procedure pop ()
	
	Stack.Delete ( Stack.UBound () );
	
EndProcedure 

Function getReport ( Report )
	
	if ( ReportObjects = undefined ) then
		ReportObjects = new Map ();
	endif; 
	if ( ReportObjects [ Report ] = undefined ) then
		obj = Report.GetObject ();
		obj.Stack = Stack;
		obj.Build ();
		ReportObjects [ Report ] = obj;
	endif; 
	return ReportObjects [ Report ];
	
EndFunction 

Function sumFields ( Parameter, Report, Last ) export
	
	result = 0;
	cells = RegulatoryReports.ExtractFields ( Parameter );
	for each cell in cells do
		result = result + ? ( Last, getLast ( cell, Report ), get ( cell, Report ) );
	enddo; 
	return result;
	
EndFunction 

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( IsFolder ) then
		return;
	endif; 
	if ( Master ) then
		checkMaster ( CheckedAttributes );
	else
		checkReport ( CheckedAttributes );
	endif; 
	
EndProcedure

Procedure checkMaster ( CheckedAttributes )
	
	CheckedAttributes.Add ( "Name" );
	CheckedAttributes.Add ( "Period" );
	
EndProcedure 

Procedure checkReport ( CheckedAttributes )
	
	CheckedAttributes.Add ( "Company" );
	CheckedAttributes.Add ( "MasterReport" );
	
EndProcedure 

Procedure BeforeWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	if ( not checkName () ) then
		Cancel = true;
	endif; 
	
EndProcedure

Function checkName ()
	
	if ( Name = "" ) then
		return true;
	endif; 
	s = "
	|select top 1 1
	|from Catalog.Reports as Reports
	|where Reports.Name = &Name
	|and Reports.Ref <> &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Name", Name );
	q.SetParameter ( "Ref", Ref );
	error = q.Execute ().Select ().Next ();
	if ( error ) then
		Output.ReportAlreadyExists ( new Structure ( "Name", Name ), "Name" );
	endif; 
	return not error;
	
EndFunction 

// *****************************************
// *********** Variables Initialization

ObjectIsInitialized = false;
Parameters = new Map ();
FieldsValues = new Map ();

DataMapping = new ValueTable ();
DataMapping.Columns.Add ( "Key" );
DataMapping.Columns.Add ( "Field" );
DataMapping.Columns.Add ( "Dataset" );

#endif