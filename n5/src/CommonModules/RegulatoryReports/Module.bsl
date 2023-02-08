Procedure WriteDependencies ( Object, ProgramCode ) export
	
	BeginTransaction ();
	removeDependencies ( Object );
	RegulatoryReports.DisassembleProgramCode ( Object, ProgramCode );
	CommitTransaction ();
	
EndProcedure 

Procedure removeDependencies ( Object )
	
	ref = Object.Ref;
	table = getDependencies ( ref );
	for each row in table do
		rm = InformationRegisters.FieldsDependency.CreateRecordManager ();
		FillPropertyValues ( rm, row );
		rm.DependentReport = ref;
		rm.Delete ();
	enddo; 
	
EndProcedure 

Function getDependencies ( Reference )
	
	str = "
	|select Dependencies.Report as Report, Dependencies.Field as Field, Dependencies.DependentField as DependentField
	|from InformationRegister.FieldsDependency as Dependencies
	|where Dependencies.DependentReport = &Report
	|";
	q = new Query ( str );
	q.SetParameter ( "Report", Reference );
	return q.Execute ().Unload ();
	
EndFunction 

Procedure DisassembleProgramCode ( Object, ProgramCode, Building = false ) export
	
	if ( Building ) then
		Object.Procedures = new Map ();
		Object.ExecutedProcedures = new Map ();
	endif;
	// Lunux bug https://gcc.gnu.org/bugzilla/show_bug.cgi?id=86164 workaround
	procedures = Regexp.Split ( ProgramCode, "EndProcedure" );
	for each chunk in procedures do
		if ( IsBlankString ( chunk ) ) then
			continue;
		endif;
		i = StrFind ( chunk, "Procedure" );
		if ( i > 0 ) then
			j = StrFind ( chunk, "(", , i );
			name = TrimAll ( Mid ( chunk, i + 9, j - i - 9 ) );
			j = StrFind ( chunk, Chars.LF, , j );
			body = Mid ( chunk, j );
		endif;
		if ( Building ) then
			addProcedure ( body, Object, name );
		else
			addDependency ( body, Object, name );
		endif;
	enddo; 

EndProcedure 

Procedure addProcedure ( Body, Object, ProcedureName )
	
	s = Body;
	if ( Object.FieldProcedures [ ProcedureName ] <> undefined ) then
		s = s + "
		|	put ( """ + ProcedureName + """, result );";
	endif; 
	Object.Procedures [ ProcedureName ] = s;

EndProcedure 

Procedure addDependency ( Body, Object, ProcedureName )
	
	pattern = "\b(get|getLast|sum|sumLast)[\ \(\""]+([a-zA-Zа-яА-Я0-9_:, ]+)\""([\ \""\)\;]+|[\,\ \""]+([a-zA-Zа-яА-Я0-9_\(\) ]+)[\""\ \)\;]+)";
	matches = Regexp.Select ( Body, pattern );
	ref = Object.Ref;
	for each match in matches do
		method = Lower ( match.Groups [ 0 ] );
		report = match.Groups [ 3 ];
		last = Find ( method, "last" ) > 0;
		if ( last ) then
			reportName = ? ( report = "", ? ( Object.Master, Object.Name, DF.Pick ( Object.MasterReport, "Name" ) ), report );
			mainReport = RegulatoryReports.Search ( Object, reportName, true );
		else
			if ( report = "" ) then
				mainReport = ref;
			else
				mainReport = RegulatoryReports.Search ( Object, report, false );
			endif; 
		endif; 
		if ( mainReport = undefined ) then
			if ( not last ) then
				Output.ReportIsNotFound ( new Structure ( "Report", report ) );
			endif;
			continue;
		endif; 
		parameter = match.Groups [ 1 ];
		if ( method = "sum"
			or method = "sumlast" ) then
			fields = RegulatoryReports.ExtractFields ( parameter );
			for each field in fields do
				writeDependency ( field, mainReport, ref, ProcedureName );
			enddo;
		else
			writeDependency ( parameter, mainReport, ref, ProcedureName );
		endif; 
	enddo;

EndProcedure 

Procedure writeDependency ( Field, Report, Reference, ProcedureName )
	
	rm = InformationRegisters.FieldsDependency.CreateRecordManager ();
	rm.Report = Report;
	rm.Field = Field;
	rm.DependentReport = Reference;
	rm.DependentField = ProcedureName;
	rm.Write ();
	
EndProcedure 

Function ExtractFields ( Body ) export
	
	return CoreLibrary.ExtractFields ( Body );
	
EndFunction 

Function GetDependants ( Report, Field ) export
	
	str = "
	|select Dependencies.DependentReport as DependentReport, Dependencies.DependentField as DependentField
	|from InformationRegister.FieldsDependency as Dependencies
	|where Dependencies.Report = &Report
	|and Dependencies.Field = &Field
	|";
	q = new Query ( str );
	q.SetParameter ( "Report", Report );
	q.SetParameter ( "Field", Field );
	return q.Execute ().Unload ();
	
EndFunction 

Procedure SaveUserValue ( Report, Value, Field, ContainsValue ) export
	
	r = InformationRegisters.UserFields.CreateRecordManager ();
	r.Report = Report;
	r.Field = Field;
	if ( ContainsValue ) then
		actualValue = Value;
	else
		if ( Value = "" ) then
			actualValue = 0;
		else
			try
				actualValue = Number ( Value );
			except
				actualValue = Value;
			endtry;
		endif; 
	endif; 
	r.Value = actualValue;
	r.Write ();
	
EndProcedure 

Function FieldCalculated ( Field, RecalculatedFields ) export
	
	i = RecalculatedFields.UBound ();
	while ( i >= 0 ) do
		if ( RecalculatedFields [ i ].Field = Field ) then
			return true;
		endif;
		i = i - 1;
	enddo; 
	return false;
	
EndFunction 

Procedure FixCalculation ( RecalculatedFields, Report, Field ) export
	
	RecalculatedFields.Add ( new Structure ( "Report, Field", Report, Field ) );
	
EndProcedure 

Function Search ( Object, Report, Last ) export
	
	s = "
	|select top 1 Reports.Ref as Ref
	|from Catalog.Reports as Reports
	|where not Reports.DeletionMark
	|";
	if ( Object.Master ) then
		s = s + "
		|and Reports.Name = &Report
		|";
	else
		s = s + "
		|and Reports.MasterReport.Name = &Report
		|and Reports.Company = &Company
		|";
	endif; 
	if ( Last ) then
		s = s + "
		|and Reports.DateEnd < &DateStart
		|and Reports.Ref <> &Ref
		|order by Reports.DateEnd desc, Reports.Date desc
		|";
	else
		s = s + "
		|order by Reports.Date desc
		|";
	endif; 
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	q.SetParameter ( "Report", Report );
	q.SetParameter ( "DateStart", Object.DateStart );
	q.SetParameter ( "Company", Object.Company );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
EndFunction 

Function GetStoredField ( ExternalFields, Parameter, Report ) export
	
	s = "
	|select 0 as Priority, UserFields.Value as Value
	|from InformationRegister.UserFields as UserFields
	|where UserFields.Report = &Report
	|and UserFields.Field = &Field
	|union
	|select 1, ReportFields.Value
	|from InformationRegister.ReportFields as ReportFields
	|where ReportFields.Report = &Report
	|and ReportFields.Field = &Field
	|order by Priority
	|";
	q = new Query ( s );
	q.SetParameter ( "Report", Report );
	q.SetParameter ( "Field", Parameter );
	table = q.Execute ().Unload ();
	if ( table.Count () = 0 ) then
		value = 0;
	else
		value = table [ 0 ].Value;
	endif; 
	row = ExternalFields.Add ();
	row.Report = Report;
	row.Parameter = Parameter;
	row.Value = value;
	return value;
	
EndFunction 

Function Retrieve ( Object, Field ) export
	
	wasCalculated = true;
	result = Object.Fields [ Field ];
	if ( result = undefined ) then
		row = Object.DataMapping.Find ( Field, "Field" );
		if ( row = undefined ) then
			result = Object.FieldsValues [ Field ];
			if ( result = undefined ) then
				wasCalculated = false;
				result = 0;
			endif; 
		else
			table = Object.Env [ row.Dataset ];
			if ( table.Count () = 1 and table.Columns.Count () = 1 ) then
				result = table [ 0 ] [ 0 ];
			else
				keys = Conversion.StringToArray ( row.Key );
				if ( keys.Count () = 1 ) then
					row = table.Find ( keys [ 0 ], "Key" );
					result = ? ( row = undefined, 0, row.Value );
				else
					result = 0;
					for each k in keys do
						row = table.Find ( k, "Key" );
						if ( row = undefined ) then
							continue;
						endif;
						if ( row.Value = undefined
							or row.Value = null ) then
							continue;
						endif; 
						result = result + row.Value;
					enddo; 
				endif; 
			endif; 
			if ( result = undefined
				or result = null ) then
				wasCalculated = false;
				result = 0;
			endif; 
		endif; 
		if ( wasCalculated ) then
			RegulatoryReports.WriteParameter ( Object, Field, result );
		endif; 
		Object.Fields [ Field ] = result;
	endif; 
	return result;
	
EndFunction 

Procedure WriteParameter ( Object, Parameter, Value ) export
	
	Record = InformationRegisters.ReportFields.CreateRecordManager ();
	Record.Report = Object.Ref;
	Record.Field = Parameter;
	Record.Value = Value;
	Record.Write ();
	Object.Fields [ Parameter ] = Value;
	
EndProcedure 
