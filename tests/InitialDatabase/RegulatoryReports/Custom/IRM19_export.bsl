Env = new Structure ();
XMLWriter = new XMLWriter ();
File = GetTempFileName ( "xml" );

init ( Env, Ref );
writeXML ( Env, File, XMLWriter );
exportFile ( File );

Procedure init ( Env, Ref )
	
	setData ( Env, Ref );

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

Procedure writeXML ( Env, File, XMLWriter )
	
	XMLWriter.OpenFile ( File, "UTF-8" );
	XMLWriter.WriteXMLDeclaration ();
	
	XMLWriter.WriteStartElement ( "dec" );
	XMLWriter.WriteAttribute ( "TypeName", "IRM19" );
	
	writeFiscCode ( Env, XMLWriter );
	writeDataPrezent ( Env, XMLWriter );
	writeDinamicTable ( Env, XMLWriter );
	
	XMLWriter.WriteEndElement ();
	XMLWriter.Close();

EndProcedure 
	
Procedure writeFiscCode ( Env, XMLWriter )

	XMLWriter.WriteStartElement ( "fiscCod" );
	
	XMLWriter.WriteStartElement ( "fiscal" );
	XMLWriter.WriteText ( getStringValue ( Env, "CodeFiscal" ) );
	XMLWriter.WriteEndElement ();
	
	XMLWriter.WriteStartElement ( "name" );
	XMLWriter.WriteText ( getStringValue ( Env, "Company" ) );
	XMLWriter.WriteEndElement ();
	
	XMLWriter.WriteStartElement ( "cnas" );
	XMLWriter.WriteText ( getStringValue ( Env, "CNAS" ) );
	XMLWriter.WriteEndElement ();
	
	XMLWriter.WriteStartElement ( "fisc" );
	XMLWriter.WriteText ( getStringValue ( Env, "TaxAdministration" ) );
	XMLWriter.WriteEndElement ();
	
	XMLWriter.WriteEndElement ();	

EndProcedure

Procedure writeDataPrezent ( Env, XMLWriter )

	XMLWriter.WriteStartElement ( "dataPrezent" );
	XMLWriter.WriteText ( getDateValue ( Env, "PresentationDate" ) );
	XMLWriter.WriteEndElement ();

EndProcedure

Procedure writeDinamicTable ( Env, XMLWriter )

	XMLWriter.WriteStartElement ( "dinamicTable" );
	
	for i = 1 to 9 do
		writeDinamicRow ( Env, XMLWriter, i );		
	enddo;
	
	XMLWriter.WriteEndElement ();	

EndProcedure

Procedure writeDinamicRow ( Env, XMLWriter, RowNumber )
	
	row = Format ( RowNumber, "NLZ=" );
	number = getValue ( Env, "A" + row );
	
	if ( not ValueIsFilled ( number ) ) then
		return;
	endif;
	
	XMLWriter.WriteStartElement ( "row" );
	XMLWriter.WriteAttribute ( "line", Format ( number, "NFD=0; NG=" ) );
	
	writeStringValue ( Env, XMLWriter, "c1", "A" + row );
	writeStringValue ( Env, XMLWriter, "c2", "B" + row );
	writeStringValue ( Env, XMLWriter, "c3", "C" + row );
	writeNumericValue ( Env, XMLWriter, "c4", "D" + row );
	writeStringValue ( Env, XMLWriter, "n5", "E" + row );
	writeDateValue ( Env, XMLWriter, "c6", "F" + row );
	writeDateValue ( Env, XMLWriter, "c7", "G" + row );
	writeStringValue ( Env, XMLWriter, "c8", "H" + row );
	writeStringValue ( Env, XMLWriter, "c9", "I" + row );
	writeDateValue ( Env, XMLWriter, "c10", "J" + row );
	writeDateValue ( Env, XMLWriter, "c11", "K" + row );
	writeDateValue ( Env, XMLWriter, "c12", "L" + row );
	
	XMLWriter.WriteEndElement ();	

EndProcedure 

Procedure writeStringValue ( Env, XMLWriter, XMLName, VariableName )

	XMLWriter.WriteStartElement ( XMLName );
	XMLWriter.WriteText ( getStringValue ( Env, VariableName ) );
	XMLWriter.WriteEndElement ();	

EndProcedure 

Procedure writeNumericValue ( Env, XMLWriter, XMLName, VariableName )

	XMLWriter.WriteStartElement ( XMLName );
	XMLWriter.WriteText ( getNumericValue ( Env, VariableName ) );
	XMLWriter.WriteEndElement ();	

EndProcedure 

Procedure writeDateValue ( Env, XMLWriter, XMLName, VariableName )

	XMLWriter.WriteStartElement ( XMLName );
	XMLWriter.WriteText ( getDateValue ( Env, VariableName ) );
	XMLWriter.WriteEndElement ();	

EndProcedure 

Function getStringValue ( Env, VariableName )
	
	return XMLString ( getValue ( Env, VariableName ) );	

EndFunction

Function getNumericValue ( Env, VariableName )
	
	return Format ( getValue ( Env, VariableName ), "NFD=2; NDS=.; NG=" );	

EndFunction

Function getDateValue ( Env, VariableName )
	
	value = getValue ( Env, VariableName );
	return ? ( ValueIsFilled ( value ), XMLString ( value ), "" );	

EndFunction

Function getValue ( Env, VariableName )
		
	return Env.Data [ VariableName ];
	
EndFunction