Env = new Structure ();

init ( Env, Ref );

xml = new XMLWriter ();
file = GetTempFileName ( "xml" );
fillXML ( Env, xml, file );
exportFile ( file );

Procedure init ( Env, Ref ) 

	setData ( Env, Ref );
	setColumnsTable1 ( Env );
	setColumnsTable2 ( Env );
	setStructure ( Env );
	
EndProcedure

Procedure setData ( Env, Ref ) 

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
	|";
	q = new Query ( s );
	q.SetParameter ( "Report", Ref );
	data = new Map ();
	for each row in q.Execute ().Unload () do
		data.Insert ( row.Field, row.Value );
	enddo;
	Env.Insert ( "Data", data );

EndProcedure

Procedure setColumnsTable1 ( Env )

	columns = new Array ();
	columns.Add ( new Structure ( "Name, Key", "A", "number" ) );
	columns.Add ( new Structure ( "Name, Key", "B", "tinsalcds" ) );
	columns.Add ( new Structure ( "Name, Key", "C", "namettl" ) );
	columns.Add ( new Structure ( "Name, Key", "D", "tinsotcds" ) );
	columns.Add ( new Structure ( "Name, Key", "E", "codsurcdc" ) );
	columns.Add ( new Structure ( "Name, Key", "F", "sumvencur" ) );
	columns.Add ( new Structure ( "Name, Key", "G", "alpha3cod" ) );
	columns.Add ( new Structure ( "Name, Key", "I", "sumscpcur" ) );
	columns.Add ( new Structure ( "Name, Key", "J", "sumscmcur" ) );
	columns.Add ( new Structure ( "Name, Key", "L", "sumscsmcur" ) );
	columns.Add ( new Structure ( "Name, Key", "M", "sumscncur" ) );
	columns.Add ( new Structure ( "Name, Key", "N", "sumschcur" ) );
	columns.Add ( new Structure ( "Name, Key", "O", "sumsctotcur" ) );
	columns.Add ( new Structure ( "Name, Key", "P", "summedcur" ) );
	columns.Add ( new Structure ( "Name, Key", "Q", "sumded2cur" ) );
	columns.Add ( new Structure ( "Name, Key", "R", "sumimpcur" ) );
	Env.Insert ( "ColumnsTable1", columns );

EndProcedure

Procedure setColumnsTable2 ( Env )

	columns = new Array ();
	columns.Add ( new Structure ( "Name, Key", "A", "number" ) );
	columns.Add ( new Structure ( "Name, Key", "B", "tinang" ) );
	columns.Add ( new Structure ( "Name, Key", "C", "tinpin" ) );
	columns.Add ( new Structure ( "Name, Key", "D", "tinpih" ) );
	Env.Insert ( "ColumnsTable2", columns );

EndProcedure

Procedure setStructure ( Env )
	
	ials21 = new Structure ();
	Env.Insert ( "IALS21", ials21 );
	addFiscCode ( Env );
	ials21.Insert ( "nrinscr", Format ( Env.Data [ "RecordsNumber" ], "NG=0" ) );
	addDinamicTable ( Env );
	ials21.Insert ( "GroupsummContr", new Structure ( "summContr", formatValue ( Env.Data [ "R141" ] ) ) );
	addDirector ( Env );
	addDinamicTable2 ( Env );
	
EndProcedure

Procedure addFiscCode ( Env )

	fiscCod = new Structure ();
	data = Env.Data;
	fiscCod.Insert ( "fiscal", data [ "CodeFiscal" ] );
	fiscCod.Insert ( "name", data [ "Company" ] );
	fiscCod.Insert ( "datefisc", Format ( data [ "Period" ], "DF='L/MM/yyyy'" ) );
	fiscCod.Insert ( "cuatm", data [ "CUATM" ] );
	fiscCod.Insert ( "fisc", data [ "TaxAdministration" ] );
	fiscCod.Insert ( "caem", data [ "CAEM" ] );
	Env.IALS21.Insert ( "fiscCod", fiscCod );

EndProcedure

Procedure addDirector ( Env ) 

	director = new Structure ();
	data = Env.Data;
	director.Insert ( "director", data [ "Director" ] );
	director.Insert ( "contabil", data [ "Accountant" ] );
	Env.IALS21.Insert ( "director", director );

EndProcedure

Procedure addDinamicTable ( Env ) 

	dinamicTable = new Structure;
	dinamicTable.Insert ( "rows", getDinamicRows ( Env, 51, 140, 16, Env.ColumnsTable1 ) );
	dinamicTable.Insert ( "totalRow", getDinamicTotals ( Env ) );
	Env.IALS21.Insert ( "dinamicTable", dinamicTable );

EndProcedure

Function getDinamicRows ( Env, FirstRow, LastRow, MaxColumns, Columns )
	
	result = new Array ();
	line = 1;
	data = Env.Data;
	for i = FirstRow to LastRow do
		valueColumn1 = data [ "A" + i ];
		if ( valueColumn1 = undefined ) then
			break;
		endif;
		row = new Structure ();
		row.Insert ( "line", line );
		row.Insert ( "number", valueColumn1 );
		for column = 2 to MaxColumns do
			item = Columns [ column - 1 ];
			value = data [ item.Name + i ];
			row.Insert ( item.Key, formatValue ( value ) );
		enddo;
		result.Add ( row );
		line = line + 1;
	enddo;
	return result;
	
EndFunction

Function formatValue ( Value ) 

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

Function getDinamicTotals ( Env )
	
	totals = new Structure ();
	data = Env.Data;
	totals.Insert ( "ventotcur", data [ "F141" ] );
	totals.Insert ( "scpcur", data [ "I141" ] );
	totals.Insert ( "scmcur", data [ "J141" ] );
	totals.Insert ( "scsmcur", data [ "L141" ] );
	totals.Insert ( "scncur", data [ "M141" ] );
	totals.Insert ( "schcur", data [ "N141" ] );
	totals.Insert ( "sctotcur", data [ "O141" ] );
	totals.Insert ( "medcur", data [ "P141" ] );
	totals.Insert ( "ded2cur", data [ "Q141" ] );
	totals.Insert ( "impreticur", data [ "R141" ] );
	return totals;

EndFunction

Procedure addDinamicTable2 ( Env ) 

	dinamicTable2 = new Structure ();
	dinamicTable2.Insert ( "rows", getDinamicRows ( Env, 200, 229, 4, Env.ColumnsTable2 ) );
	Env.IALS21.Insert ( "dinamicTable2", dinamicTable2 );

EndProcedure

Procedure fillXML ( Env, XML, File )

	XML.OpenFile ( file, "UTF-8" );
	XML.WriteXMLDeclaration ();
	XML.WriteStartElement ( "dec" );
	XML.WriteAttribute ( "TypeName", "IALS21" );
	for each item in Env.IALS21 do
		buildXML ( XML, item.Key, item.Value );	
	enddo;
	XML.WriteEndElement ();
	XML.Close ();

EndProcedure

Procedure buildXML ( XML, Name, Value )
	
	typeValue = TypeOf ( Value );
	if ( typeValue = Type ( "Structure" ) ) then
		XML.WriteStartElement ( Name );
		for each item in Value do
			buildXML ( XML, item.Key, item.Value );
		enddo;
		XML.WriteEndElement ();
	elsif ( typeValue = Type ( "Array" ) ) then
		for each item in Value do
			XML.WriteStartElement ( "row" );
			for each childItem in item do
				if ( childItem.Key = "line" ) then
					text = XMLString ( Round ( item.line ) );
					XML.WriteAttribute ( "line", text );
					continue;	
				endif;
				buildXML ( XML, childItem.Key, childItem.Value );
			enddo;
			XML.WriteEndElement ();
		enddo;
	else
		XML.WriteStartElement ( Name );
		if ( typeValue = Type ( "Number" ) ) then
			text = XMLString ( Round ( Value, 2 ) );
			XML.WriteText ( text );
		else
			text = ? ( Value = undefined, "", XMLString ( TrimAll ( Value ) ) );
			XML.WriteText ( text );
		endif;
		XML.WriteEndElement ();	
	endif;	
	
EndProcedure