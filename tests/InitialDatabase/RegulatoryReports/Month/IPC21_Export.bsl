
Env = new Structure ();

init ( Env, Ref );

xml = new XMLWriter ();
file = GetTempFileName ( "xml" );
fillXML ( Env, xml, file );
exportFile ( file );

Procedure init ( Env, Ref ) 

	setData ( Env, Ref );
	setColumns ( Env );
	setColumnsTable1 ( Env );
	setColumnsTable2 ( Env );
	setStructure ( Env );
	
EndProcedure

Procedure setData ( Env, Ref ) 

	s = "
	|select Fields.Field as Field, Fields.Value as Value
	|from InformationRegister.ReportFields as Fields
	|where Fields.Report = &Report
	|";
	q = new Query ( s );
	q.SetParameter ( "Report", Ref );
	data = new Map ();
	for each row in q.Execute ().Unload () do
		data.Insert ( row.Field, row.Value );
	enddo;
	Env.Insert ( "Data", data );

EndProcedure

Procedure setColumns ( Env )

	columns = new Array ();
	columns.Add ( "A" );
	columns.Add ( "B" );
	columns.Add ( "C" );
	columns.Add ( "D" );
	columns.Add ( "E" );
	columns.Add ( "F" );
	columns.Add ( "G" );
	columns.Add ( "H" );
	columns.Add ( "I" );
	columns.Add ( "J" );
	columns.Add ( "K" );
	columns.Add ( "L" );
	columns.Add ( "M" );
	Env.Insert ( "Columns", columns );

EndProcedure

Procedure setColumnsTable1 ( Env )

	columns = new Array ();
	columns.Add ( "A" );
	columns.Add ( "B" );
	columns.Add ( "D" );
	columns.Add ( "E" );
	columns.Add ( "F" );
	Env.Insert ( "ColumnsTable1", columns );

EndProcedure

Procedure setColumnsTable2 ( Env )

	columns = new Array ();
	columns.Add ( "A" );
	columns.Add ( "B" );
	columns.Add ( "C" );
	columns.Add ( "D" );
	columns.Add ( "E" );
	columns.Add ( "F" );
	columns.Add ( "G" );
	columns.Add ( "M" );
	columns.Add ( "H" );
	columns.Add ( "I" );
	columns.Add ( "J" );
	columns.Add ( "K" );
	Env.Insert ( "ColumnsTable2", columns );

EndProcedure

Procedure setStructure ( Env )
	
	iPC21 = new Structure ();
	Env.Insert ( "IPC21", iPC21 );
	addFiscCode ( Env );
	addPeroidnalog ( Env );
	addDirector ( Env );
	addTable1 ( Env );
	iPC21.Insert ( "summContr", formatValue ( Env.Data [ "CheckAmount" ] ) );
	addDinamicTable ( Env );
	addDinamicTable2 ( Env );
	addTable3 ( Env );
	
EndProcedure

Procedure addFiscCode ( Env )

	fiscCod = new Structure ();
	data = Env.Data;
	fiscCod.Insert ( "fiscal", data [ "CodeFiscal" ] );
	fiscCod.Insert ( "name", data [ "Company" ] );
	fiscCod.Insert ( "cuatm", data [ "CUATM" ] );
	fiscCod.Insert ( "fisc", data [ "TaxAdministration" ] );
	fiscCod.Insert ( "caem", data [ "CAEM" ] );
	fiscCod.Insert ( "cnas", data [ "CNAS" ] );
	Env.IPC21.Insert ( "fiscCod", fiscCod );

EndProcedure

Procedure addPeroidnalog ( Env )

	peroidnalog = new Structure ( "datefisc", Format ( Env.Data [ "Period" ], "DF='L/MM/yyyy'" ) );
	Env.IPC21.Insert ( "peroidnalog", peroidnalog );

EndProcedure

Procedure addDirector ( Env ) 

	director = new Structure ();
	data = Env.Data;
	director.Insert ( "director", data [ "Director" ] );
	director.Insert ( "contabil", data [ "Accountant" ] );
	Env.IPC21.Insert ( "director", director );

EndProcedure

Procedure addTable1 ( Env ) 

	ds = new Structure ();
	ds.Insert ( "flag", "" );
	data = Env.Data;
	ds.Insert ( "flag1", ? ( data [ "Primary" ] = true, "x", "" ) );
	ds.Insert ( "flag2", ? ( data [ "Correct" ] = true, "x", "" ) );
	it = new Structure ();
	it.Insert ( "flag", "" );
	it.Insert ( "flag1", ? ( data [ "ITParcResident" ] = true, "x", "" ) );
	cf = new Structure ();
	cf.Insert ( "flag", "" );
	cf.Insert ( "flag1", ? ( data [ "FiscalControl" ] = true, "x", "" ) );
	table1 = new Structure ();
	table1.Insert ( "ds", ds );
	table1.Insert ( "it", it );
	table1.Insert ( "cf", cf );
	table1.Insert ( "row", getTable1Rows ( Env ) );
	Env.IPC21.Insert ( "table1", table1 );

EndProcedure

Function getTable1Rows ( Env )
	
	rows = new Structure ();
	data = Env.Data;
	rows.Insert ( "r11c4", data [ "A32" ] );
	rows.Insert ( "r11c5", data [ "B32" ] );
	rows.Insert ( "r11c6", data [ "C32" ] );
	rows.Insert ( "r12c4", data [ "A33" ] );
	rows.Insert ( "r12c5", data [ "B33" ] );
	rows.Insert ( "r12c6", data [ "C33" ] );
	rows.Insert ( "r21c4", data [ "A34" ] );
	rows.Insert ( "r21c5", data [ "B34" ] );
	rows.Insert ( "r31c4", data [ "A35" ] );
	rows.Insert ( "r31c5", data [ "B35" ] );
	rows.Insert ( "r32c4", data [ "A36" ] );
	rows.Insert ( "r41c4", data [ "A37" ] );
	rows.Insert ( "r41c5", data [ "B37" ] );
	rows.Insert ( "r42c4", data [ "A38" ] );
	rows.Insert ( "r42c5", data [ "B38" ] );
	rows.Insert ( "r43c4", data [ "A39" ] );
	rows.Insert ( "r43c5", data [ "B39" ] );
	rows.Insert ( "r44c4", data [ "A40" ] );
	rows.Insert ( "r44c5", data [ "B40" ] );
	rows.Insert ( "r45c4", data [ "A41" ] );
	rows.Insert ( "r45c5", data [ "B41" ] );
	rows.Insert ( "r46c4", data [ "A42" ] );
	rows.Insert ( "r46c5", data [ "B42" ] );
	rows.Insert ( "r47c4", data [ "A43" ] );
	rows.Insert ( "r47c5", data [ "B43" ] );
	rows.Insert ( "r48c4", data [ "A44" ] );
	rows.Insert ( "r48c5", data [ "B44" ] );
	rows.Insert ( "r49c4", data [ "A52" ] );
	rows.Insert ( "r49c5", data [ "B52" ] );
	rows.Insert ( "r491c4", data [ "A53" ] );
	rows.Insert ( "r491c5", data [ "B53" ] );
	rows.Insert ( "r51c4", data [ "A45" ] );
	rows.Insert ( "r51c5", data [ "B45" ] );
	rows.Insert ( "r52c4", data [ "A46" ] );
	rows.Insert ( "r52c5", data [ "B46" ] );
	rows.Insert ( "r53c4", data [ "A47" ] );
	rows.Insert ( "r53c5", data [ "B47" ] );
	rows.Insert ( "r54c4", data [ "A48" ] );
	rows.Insert ( "r54c5", data [ "B48" ] );
	rows.Insert ( "r55c4", data [ "A49" ] );
	rows.Insert ( "r55c5", data [ "B49" ] );
	rows.Insert ( "r56c4", data [ "A50" ] );
	rows.Insert ( "r56c5", data [ "B50" ] );
	rows.Insert ( "r61c4", data [ "A51" ] );
	rows.Insert ( "r61c5", data [ "B51" ] );
	rows.Insert ( "r61c6", data [ "C51" ] );
	return rows;
	
EndFunction

Procedure addDinamicTable ( Env ) 

	dinamicTable = new Structure;
	dinamicTable.Insert ( "rows", getDinamicRows ( Env, 87, 124, 5, Env.ColumnsTable1 ) );
	dinamicTable.Insert ( "total", getDinamicTotals ( Env ) );
	Env.IPC21.Insert ( "dinamicTable", dinamicTable );

EndProcedure

Function getDinamicRows ( Env, FirstRow, LastRow, MaxColumns, Columns = undefined )
	
	result = new Array ();
	line = 1;
	data = Env.Data;
	if ( Columns = undefined ) then
		Columns = Env.Columns;
	endif;
	for i = FirstRow to LastRow do
		valueColumn1 = data [ "A" + i ];
		if ( valueColumn1 = undefined ) then
			break;
		endif;
		row = new Structure ();
		row.Insert ( "line", line );
		row.Insert ( "c1", valueColumn1 );
		for column = 2 to MaxColumns do
			value = data [ Columns [ column - 1 ] + i ];
			if ( column = 8 ) then
				id = "71";
				value = ? ( value = undefined, undefined, "" + value + "%" );
			elsif ( column > 8 ) then
				id = "" + ( column - 1 );
			else
				id = "" + column;
			endif;
			row.Insert ( "c" + id, formatValue ( value ) );
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
	totals.Insert ( "tot1c3", data [ "D125" ] );
	totals.Insert ( "tot1c4", data [ "E125" ] );
	totals.Insert ( "tot1c5", data [ "F125" ] );
	return totals;
	
EndFunction

Procedure addDinamicTable2 ( Env ) 

	dinamicTable2 = new Structure ();
	dinamicTable2.Insert ( "rows", getDinamicRows ( Env, 191, 338, 12, Env.ColumnsTable2 ) );
	dinamicTable2.Insert ( "total", getDinamicTotals2 ( Env ) );
	Env.IPC21.Insert ( "dinamicTable2", dinamicTable2 );

EndProcedure

Function getDinamicTotals2 ( Env )
	
	totals = new Structure ();
	data = Env.Data;
	totals.Insert ( "tot2c9", data [ "I339" ] );
	totals.Insert ( "tot2c10", data [ "J339" ] );
	totals.Insert ( "tot2c11", data [ "K339" ] );
	return totals;	
	
EndFunction

Procedure addTable3 ( Env ) 

	table = new Structure ();
	table.Insert ( "row", getTable2Row ( Env ) );
	Env.IPC21.Insert ( "table2", table );

EndProcedure

Function getTable2Row ( Env )
	
	row = new Structure ();
	data = Env.Data;
	row.Insert ( "r11bc9", formatValue ( data [ "I341" ] ) );
	row.Insert ( "r11bc11", formatValue ( data [ "K341" ] ) );
	return row;	
	
EndFunction

Procedure fillXML ( Env, XML, File )

	XML.OpenFile ( file, "UTF-8" );
	XML.WriteXMLDeclaration ();
	XML.WriteStartElement ( "dec" );
	XML.WriteAttribute ( "TypeName", "IPC21" );
	for each item in Env.IPC21 do
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
