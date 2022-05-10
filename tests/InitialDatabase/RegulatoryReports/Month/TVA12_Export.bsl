env = new Structure ( "Body", new Structure () );
getData ( env, Ref );
addCompany ( env );
addPeroidnalog ( env );
addGroup3t ( env );
body = env.Body;
body.Insert ( "liberIs", 0 );
addHeader ( env );
addGroup4t ( env );
addGroup5t ( env );
data = Env.Data;
body.Insert ( "NakladPrimit", data [ "Rows1" ] );
addPurchases ( env );
body.Insert ( "NakladEliberat", data [ "Rows2" ] );
addSales ( env );
xml = new XMLWriter ();
file = GetTempFileName ( "xml" );
fillXML ( Env, xml, file );
exportFile ( file );

Procedure getData ( Env, Ref ) 

	s = "
	|select ReportFields.Field as Field, isnull ( UserFields.Value, ReportFields.Value ) as Value
	|from InformationRegister.ReportFields as ReportFields
	|	//
	|	// UserFields
	|	//
	|	left join InformationRegister.UserFields as UserFields
	|	on UserFields.Field = ReportFields.Field
	|	and UserFields.Report = ReportFields.Report
	|where ReportFields.Report = &Report
	|union
	|select UserFields.Field, UserFields.Value
	|from InformationRegister.UserFields as UserFields
	|where UserFields.Report = &Report
	|";
	q = new Query ( s );
	q.SetParameter ( "Report", Ref );
	data = new Map ();
	for each row in q.Execute ().Unload () do
		data.Insert ( row.Field, row.Value );
	enddo;
	Env.Insert ( "Data", data );

EndProcedure

Procedure addCompany ( Env )

	data = Env.Data;
	body = Env.Body;
	body.Insert ( "fiscal", data [ "CodeFiscal" ] );
	body.Insert ( "regnumber", data [ "VATCode" ] );
	body.Insert ( "name", data [ "Company" ] );
	body.Insert ( "adres", data [ "Address" ] );

EndProcedure

Procedure addPeroidnalog ( Env )

	peroidnalog = new Structure ( "datefisc", Format ( Env.Data [ "Period" ], "DF='L/MM/yyyy'" ) );
	Env.Body.Insert ( "peroidnalog", peroidnalog );

EndProcedure

Procedure addGroup3t ( Env ) 

	data = Env.Data;
	group = new Structure ();
	group.Insert ( "classDohodT", data [ "IncomeClass" ] );
	group.Insert ( "codParag", data [ "IncomeCode" ] );
	Env.Body.Insert ( "group3t", group );

EndProcedure

Procedure addHeader ( Env ) 

	data = Env.Data;
	table1 = new Structure ();
	row = new Structure ( "ndsSum2t, sum2t", data [ "A21" ], data [ "B21" ] );
	table1.Insert ( "row2t", row );
	row = new Structure ( "ndsSum3t, sum3t", data [ "A22" ], data [ "B22" ] );
	table1.Insert ( "row3t", row );
	row = new Structure ( "ndsSum4t, sum4t", data [ "A23" ], data [ "B23" ] );
	table1.Insert ( "row4t", row );
	row = new Structure ( "ndsSum5t", data [ "A24" ] );
	table1.Insert ( "row5t", row );
	row = new Structure ( "ndsSum6t", data [ "A25" ] );
	table1.Insert ( "row6t", row );
	row = new Structure ( "ndsSum7t, sum7t", data [ "A26" ], data [ "B26" ] );
	table1.Insert ( "row7t", row );
	row = new Structure ( "ndsSum71t, sum71t", data [ "A40" ], data [ "B40" ] );
	table1.Insert ( "row71t", row );
	row = new Structure ( "sum8t", data [ "B27" ] );
	table1.Insert ( "row8t", row );
	row = new Structure ( "ndsSum9t, sum9t", data [ "A28" ], data [ "B28" ] );
	table1.Insert ( "row9t", row );
	row = new Structure ( "sum10t", data [ "B29" ] );
	table1.Insert ( "row10t", row );
	row = new Structure ( "ndsSum11t, sum11t", data [ "A30" ], data [ "B30" ] );
	table1.Insert ( "row11t", row );
	row = new Structure ( "ndsSum12t, sum12t", data [ "A31" ], data [ "B31" ] );
	table1.Insert ( "row12t", row );
	row = new Structure ( "sum13t", data [ "B32" ] );
	table1.Insert ( "row13t", row );
	row = new Structure ( "sum14t", data [ "B33" ] );
	table1.Insert ( "row14t", row );
	row = new Structure ( "sum15t", data [ "B34" ] );
	table1.Insert ( "row15t", row );
	row = new Structure ( "sum16t", data [ "B35" ] );
	table1.Insert ( "row16t", row );
	row = new Structure ( "sum17t", data [ "B36" ] );
	table1.Insert ( "row17t", row );
	row = new Structure ( "sum18t", data [ "B37" ] );
	table1.Insert ( "row18t", row );
	row = new Structure ( "sum19t", data [ "B38" ] );
	table1.Insert ( "row19t", row );
	Env.Body.Insert ( "table1", table1 );

EndProcedure

Procedure addGroup4t ( Env ) 

	data = Env.Data;
	group = new Structure ();
	group.Insert ( "directorT", data [ "Director" ] );
	Env.Body.Insert ( "group4t", group );

EndProcedure

Procedure addGroup5t ( Env ) 

	data = Env.Data;
	group = new Structure ();
	group.Insert ( "contabilT", data [ "Accountant" ] );
	Env.Body.Insert ( "group5t", group );

EndProcedure

Procedure addPurchases ( Env ) 

	data = Env.Data;
	rows = new Array ();
	for i = 100 to 2000 do
		id = Format ( i, "NG=0" );
		line = data [ "A" + id ];
		if ( line = undefined ) then
			continue;
		endif;
		row = new Structure ();
		row.Insert ( "_attrs", new Structure ( "line", line ) );
		row.Insert ( "number", line );
		row.Insert ( "tinFurniz", valueOf ( data [ "B" + id ] ) );
		row.Insert ( "dataEliberarii", valueOf ( data [ "C" + id ] ) );
		row.Insert ( "seriaFact", valueOf ( data [ "D" + id ] ) );
		row.Insert ( "nrFact", valueOf ( data [ "E" + id ] ) );
		row.Insert ( "valFact", valueOf ( data [ "F" + id ] ) );
		row.Insert ( "sumTotFact", valueOf ( data [ "G" + id ] ) );
		rows.Add ( new Structure ( "row", row ) );
	enddo;
	total = new Structure ();
	total.Insert ( "totCol5", valueOf ( data [ "F2000" ] ) );
	total.Insert ( "summContr", valueOf ( data [ "G2000" ] ) );
	rows.Add ( new Structure ( "total", total ) );
	Env.Body.Insert ( "dinamicTable", rows );

EndProcedure

Procedure addSales ( Env ) 

	data = Env.Data;
	rows = new Array ();
	for i = 100 to 3000 do
		id = Format ( i, "NG=0" );
		line = data [ "AA" + id ];
		if ( line = undefined ) then
			continue;
		endif;
		row = new Structure ();
		row.Insert ( "_attrs", new Structure ( "line", line ) );
		row.Insert ( "number", line );
		row.Insert ( "tinCump", valueOf ( data [ "BA" + id ] ) );
		row.Insert ( "dataEliberarii", valueOf ( data [ "CA" + id ] ) );
		row.Insert ( "seriaFact", valueOf ( data [ "DA" + id ] ) );
		row.Insert ( "nrFact", valueOf ( data [ "EA" + id ] ) );
		row.Insert ( "valFact", valueOf ( data [ "FA" + id ] ) );
		row.Insert ( "sumTotFact", valueOf ( data [ "GA" + id ] ) );
		rows.Add ( new Structure ( "row", row ) );
	enddo;
	total = new Structure ();
	total.Insert ( "totCol5", valueOf ( data [ "FA3000" ] ) );
	total.Insert ( "summContr", valueOf ( data [ "GA3000" ] ) );
	rows.Add ( new Structure ( "total", total ) );
	Env.Body.Insert ( "dinamicTable1", rows );

EndProcedure

Function valueOf ( Value ) 

	type = TypeOf ( Value );
	if ( type = Type ( "Date" ) ) then
		result = Format ( Value, "DF=dd.MM.yyyy" );
	elsif ( type = Type ( "Number" ) ) then
		result = Format ( Value, "NFD=2; NDS=.; NG=;NZ=" );
	else
		result = ? ( ValueIsFilled ( Value ), Value, "" );
	endif;
	return result;

EndFunction

Procedure fillXML ( Env, XML, File )

	XML.OpenFile ( file, "UTF-8" );
	XML.WriteXMLDeclaration ();
	Env.Body.Insert ( "_attrs", new Structure ( "TypeName", "TVA12" ) );
	buildXML ( XML, "dec", Env.Body );	
	XML.Close ();

EndProcedure

Procedure buildXML ( XML, Name, Value )
	
	XML.WriteStartElement ( Name );
	typeValue = TypeOf ( Value );
	if ( typeValue = Type ( "Structure" ) ) then
		set = undefined;
		if ( Value.Property ( "_attrs", set ) ) then
			for each entry in set do
				XML.WriteAttribute ( entry.Key, XMLString ( entry.Value ) );
			enddo;
		endif;
		for each item in Value do
			name = item.Key;
			if ( name <> "_attrs" ) then
				buildXML ( XML, name, item.Value );
			endif;
		enddo;
	elsif ( typeValue = Type ( "Array" ) ) then
		for each item in Value do
			for each childItem in item do
				buildXML ( XML, childItem.Key, childItem.Value );
			enddo;
		enddo;
	else
		if ( typeValue = Type ( "Number" ) ) then
			text = XMLString ( Round ( Value, 2 ) );
			XML.WriteText ( text );
		else
			text = ? ( Value = undefined, "", XMLString ( TrimAll ( Value ) ) );
			XML.WriteText ( text );
		endif;
	endif;	
	XML.WriteEndElement ();	
	
EndProcedure
