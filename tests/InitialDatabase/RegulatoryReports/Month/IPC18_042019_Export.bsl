
Env = new Structure ();

init ( Env, Ref );

xml = new XMLWriter ();
file = GetTempFileName ( "xml" );
fillXML ( Env, xml, file );
exportFile ( file );

Procedure init ( Env, Ref ) 

	setData ( Env, Ref );
	setColumns ( Env );
	setColumnsTable3 ( Env );
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

Procedure setColumnsTable3 ( Env )

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
	columns.Add ( "L" );
	Env.Insert ( "ColumnsTable3", columns );

EndProcedure

Procedure setStructure ( Env )
	
	iPC18 = new Structure ();
	Env.Insert ( "IPC18", iPC18 );
	addFiscCode ( Env );
	addPeroidnalog ( Env );
	addDirector ( Env );
	addTable1 ( Env );
	iPC18.Insert ( "summContr", Env.Data [ "CheckAmount" ] );
	addDinamicTable ( Env );
	addDinamicTable3 ( Env );
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
	Env.IPC18.Insert ( "fiscCod", fiscCod );

EndProcedure

Procedure addPeroidnalog ( Env )

	peroidnalog = new Structure ( "datefisc", Env.Data [ "Period" ] );
	Env.IPC18.Insert ( "peroidnalog", peroidnalog );

EndProcedure

Procedure addDirector ( Env ) 

	director = new Structure ();
	data = Env.Data;
	director.Insert ( "director", data [ "Director" ] );
	director.Insert ( "contabil", data [ "Accountant" ] );
	Env.IPC18.Insert ( "director", director );

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
	Env.IPC18.Insert ( "table1", table1 );

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
	dinamicTable.Insert ( "rows", getDinamicRows ( Env, 87, 124, 6 ) );
	dinamicTable.Insert ( "total", getDinamicTotals ( Env ) );
	Env.IPC18.Insert ( "dinamicTable", dinamicTable );

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
			row.Insert ( "c" + column, value );	
		enddo;
		result.Add ( row );
		line = line + 1;
	enddo;
	return result;
	
EndFunction

Function getDinamicTotals ( Env )
	
	totals = new Structure ();
	data = Env.Data;
	totals.Insert ( "tot1c4", data [ "D125" ] );
	totals.Insert ( "tot1c5", data [ "E125" ] );
	totals.Insert ( "tot1c6", data [ "F125" ] );
	return totals;
	
EndFunction

Procedure addDinamicTable3 ( Env ) 

	dinamicTable3 = new Structure ();
	dinamicTable3.Insert ( "rows", getDinamicRows ( Env, 191, 338, 13, Env.ColumnsTable3 ) );
	dinamicTable3.Insert ( "total", getDinamicTotals3 ( Env ) );
	Env.IPC18.Insert ( "dinamicTable3", dinamicTable3 );

EndProcedure

Function getDinamicTotals3 ( Env )
	
	totals = new Structure ();
	data = Env.Data;
	totals.Insert ( "tot2c9", data [ "I339" ] );
	totals.Insert ( "tot2c10", data [ "J339" ] );
	totals.Insert ( "tot2c11", data [ "K339" ] );
	totals.Insert ( "tot2c12", data [ "L339" ] );
	return totals;	
	
EndFunction

Procedure addTable3 ( Env ) 

	table3 = new Structure ();
	table3.Insert ( "row", getTable3Row ( Env ) );
	Env.IPC18.Insert ( "table3", table3 );

EndProcedure

Function getTable3Row ( Env )
	
	row = new Structure;
	data = Env.Data;
	row.Insert ( "r11c9", formatValue ( data [ "I339" ] ) );
	row.Insert ( "r111c9", formatValue ( data [ "I340" ] ) );
	row.Insert ( "r11c12", formatValue ( data [ "L339" ] ) );
	row.Insert ( "r111c12", formatValue ( data [ "L340" ] ) );	
	row.Insert ( "r12c9", formatValue ( data [ "I342" ] ) );
	row.Insert ( "r121c9", formatValue ( data [ "I3421" ] ) );	
	row.Insert ( "r12c12", formatValue ( data [ "L342" ] ) );
	row.Insert ( "r121c12", formatValue ( data [ "L3421" ] ) );	
	row.Insert ( "r13c9", data [ "I343" ] );
	row.Insert ( "r13c12", data [ "L343" ] );
	row.Insert ( "r14c9", data [ "I344" ] );
	row.Insert ( "r14c12", data [ "L344" ] );
	row.Insert ( "r15c12", data [ "L345" ] );
	row.Insert ( "r16c11", data [ "K338" ] );
	row.Insert ( "r2c9", data [ "I339" ] );
	row.Insert ( "r2c11", data [ "K339" ] );
	row.Insert ( "r3c10", data [ "J350" ] );
	row.Insert ( "r31c10", data [ "J351" ] );
	row.Insert ( "r32c10", data [ "J352" ] );
	row.Insert ( "r33c10", data [ "J353" ] );
	row.Insert ( "r34c10", data [ "J354" ] );
	row.Insert ( "r4c10", data [ "J355" ] );
	row.Insert ( "r41c10", data [ "J356" ] );
	row.Insert ( "r42c10", data [ "J357" ] );
	row.Insert ( "r43c10", data [ "J358" ] );
	row.Insert ( "r44c10", data [ "J359" ] );
	return row;	
	
EndFunction

Function formatValue ( Value ) 

	return ? ( value = 0, "", value );

EndFunction

Procedure fillXML ( Env, XML, File )

	XML.OpenFile ( file, "UTF-8" );
	XML.WriteXMLDeclaration ();
	XML.WriteStartElement ( "dec" );
	XML.WriteAttribute ( "TypeName", "IPC18" );
	for each item in Env.IPC18 do
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
