#region Sync
 
Function Sync ( List )
	
	set = StrSplit ( List, "," );
	result = new Array ();
	for each name in set do
		report = getReport ( name );
		if ( report = undefined ) then
			continue;
		endif; 
		data = new Structure ( "Name, Description, Variants" );
		data.Name = report.Name;
		data.Description = report.Description;
		data.Variants = getVariants ( report );
		result.Add ( data );
	enddo; 
	return Conversion.ToXML ( result );
	
EndFunction

Function getReport ( Name )
	
	meta = Metadata.Reports.Find ( Name );
	if ( meta = undefined ) then
		return undefined;
	endif; 
	if ( not AccessRight ( "View", meta ) ) then
		return undefined;
	endif; 
	report = new Structure ();
	report.Insert ( "Name", Name );
	report.Insert ( "Description", meta.Presentation () );
	report.Insert ( "SetupColumns", Reports [ Name ].Events ().OnGetColumns );
	report.Insert ( "Schema", Reporter.GetSchema ( Name ) );
	return report;
	
EndFunction 

Function getVariants ( Report )
	
	result = new Array ();
	variants = Report.Schema.SettingVariants;
	found = false;
	for each variant in variants do
		if ( StrStartsWith ( variant.Name, "#Mobile" ) ) then
			addVariant ( Report, result, variant );
			found = true;
		endif; 
	enddo; 
	if ( not found ) then
		addVariant ( Report, result, variants [ 0 ] );
	endif; 
	return result;
	
EndFunction 

Procedure addVariant ( Report, Result, Variant )
	
	variantName = "#" + Variant.Name;
	if ( Report.SetupColumns ) then
		columns = new Array ();
		reportColumns = new Array ();
		schema = Report.Schema;
		Reports [ Report.Name ].OnGetColumns ( variantName, reportColumns );
		for each reportColumn in reportColumns do
			path = reportColumn.Path;
			field = Reporter.FindField ( path, schema );
			if ( field = undefined ) then
				eventName = Metadata.Webservices.Reports.FullName () + ".addVariant";
				WriteLogEvent ( eventName, EventLogLevel.Error,
				Metadata.Reports [ Report.Name ], , Output.DataSetColumnNotFound ( new Structure ( "Path", path ) ) );
			else
				column = new Structure ( "Path, Title, MaximumWidth" );
				column.Path = reportColumn.Path;
				column.Title = ? ( field.Title = "", field.DataPath, field.Title );
				column.MaximumWidth = reportColumn.MaximumWidth;
				columns.Add ( column );
			endif; 
		enddo; 
	else
		columns = undefined;
	endif; 
	data = new Structure ();
	data.Insert ( "Name", variantName );
	data.Insert ( "Description", Variant.Presentation );
	data.Insert ( "Columns", columns );
	Result.Add ( data );
	
EndProcedure

#endregion

#region Get

Function Get ( Params )
	
	p = Conversion.FromXML ( Params );
	stream = new MemoryStream ();
	report = Reporter.Build ( p );
	report.Write ( stream );
	data = stream.CloseAndGetBinaryData (); 
	result = new ValueStorage ( Conversion.ToXML ( data ), new Deflation ( 9 ) );
	return result;
	
EndFunction

#endregion

#region Convert

Function Convert ( Data, Format )
	
	tabDoc = Conversion.FromXML ( Data ).Get ();
	file = GetTempFileName ();
	tabDoc.Write ( file, SpreadsheetDocumentFileType [ Format ] );
	binary = new BinaryData ( file );
	return new ValueStorage ( binary );
	
EndFunction

#endregion
