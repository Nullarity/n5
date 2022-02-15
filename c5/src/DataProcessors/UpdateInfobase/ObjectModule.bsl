#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Parameters export;
var JobKey export;
var SessionTenant;
var Tenants;
var Release;
var Files;
var Config;
var Remove;
//@skip-warning
var Update;
var ReportsList;
var Template;
var Program;
var Exporter;
var Company;
var User;

Procedure Exec () export
	
	rememberSession ();
	Tenants = getTenants ();
	releases = DataProcessors.UpdateInfobase.GetReleases ();
	error = undefined;
	for i = lastUpdate ( releases ) to releases.Ubound () do
		Release = releases [ i ];
		try
			run ();
		except
			error = ErrorDescription ();
			break;
		endtry;
		commit ();
	enddo;
	if ( error = undefined ) then
		restoreSession ();
	else
		processError ( error );
	endif;
	stopUpdating ();
	
EndProcedure

Procedure rememberSession ()
	
	SessionTenant = SessionParameters.Tenant;
	
EndProcedure

Function getTenants ()
	
	s = "
	|select Tenants.Ref as Ref
	|from Catalog.Tenants as Tenants
	|where not Tenants.DeletionMark
	|and not Tenants.Deactivated
	|";
	q = new Query ( s );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
EndFunction

Function lastUpdate ( Releases )
	
	myVersion = DataProcessors.UpdateInfobase.MyVersion ();
	i = releases.Count ();
	while ( i > 0 ) do
		i = i - 1;
		Release = Releases [ i ];
		if ( Release.Version <= myVersion ) then
			return i + 1;
		elsif ( Release.Intermediate ) then
			return i;
		endif;
	enddo;
	return 0;
	
EndFunction

Procedure run ()
	
	call = "_" + StrReplace ( Release.Release, ".", "_" ) + "();";
	execute ( call );
	
EndProcedure

Procedure restoreSession ()
	
	activateTenant ( SessionTenant );
	
EndProcedure

Procedure processError ( Error )
	
	while ( TransactionActive () ) do
		RollbackTransaction ();
	enddo;
	restoreSession ();
	Progress.Put ( Output.UpdateError () + ":" + Chars.LF + Error, JobKey, true );
	
EndProcedure

Procedure commit ()
	
	Constants.Release.Set ( Release.Release );
	
EndProcedure

Procedure activateTenant ( Tenant )
	
	SessionParameters.Tenant = Tenant;
	SessionParameters.TenantUse = true;
	
EndProcedure

Procedure stopUpdating ()
	
	Constants.Updating.Set ( false );
	
EndProcedure

#region Releases

Procedure _1_0_0_1 () export
	
	// Consider the following code as template of update procedure
	BeginTransaction ();
	for each tenant in Tenants do
		activateTenant ( tenant );
		// Do your update...
		// Update reports if required
		updateReports ();
	enddo;
	CommitTransaction ();
	
EndProcedure

Procedure _5_0_23_1 () export
	
	BeginTransaction ();
	for each tenant in Tenants do
		activateTenant ( tenant );
		updateCustomsDeclarations ();
		setTaxNumbers ();
	enddo;
	CommitTransaction ();
	
EndProcedure

Procedure updateCustomsDeclarations ()
	
	selection = Documents.CustomsDeclaration.Select ();
	while ( selection.Next () ) do
		obj = selection.GetObject ();
		id = 1;
		for each groupsRow in obj.CustomsGroups do
			groupsRow.ID = id;
			value = groupsRow.CustomsGroup;
			search = new Structure ( "CustomsGroup", value );
			for each row in obj.Items.FindRows ( search ) do
				row.ID = id;
			enddo;
			for each row in obj.Charges.FindRows ( search ) do
				row.ID = id;
			enddo;
			id = id + 1;
		enddo;
		obj.DataExchange.Load = true;
		obj.Write ();
	enddo;

EndProcedure

Procedure setTaxNumbers ()
	
	q = new Query ( "select distinct Base from Document.InvoiceRecord where not DeletionMark and Base <> undefined" );
	selection = q.Execute ().Select ();
	while ( selection.Next () ) do
		document = selection.Base;
		r = InformationRegisters.TaxInvoices.CreateRecordManager ();
		r.Document = document;
		numbers = getNumbers ( document );
		if ( numbers = "" ) then
			r.Delete ();
		else
			r.Number = numbers;
			r.Write ();
		endif;
	enddo;

EndProcedure

Function getNumbers ( Document )
	
	s = "
	|select Invoices.Number as Number
	|from Document.InvoiceRecord as Invoices
	|where not Invoices.DeletionMark
	|and Invoices.Base = &Base
	|order by Invoices.Date
	|";
	q = new Query ( s );
	q.SetParameter ( "Base", Document );
	list = q.Execute ().Unload ().UnloadColumn ( "Number" );
	Collections.Group ( list );
	return StrConcat ( list, ", " );

EndFunction

#endregion

Procedure updateReports ()

	readData ();
	getReportsList ();
	runUpdateReports ();
	
EndProcedure

Procedure readData () 

	folder = TempFilesDir ();
	fileName = folder + new UUID + ".zip";
	t = GetTemplate ( "Reports_" + StrReplace ( Release.Release, ".", "_" ) );
	t.Write ( fileName );
    zip = new ZipFileReader ();
	zip.Open ( fileName );
	for each item in zip.Items do
		zip.Extract ( item, folder );
		extension = item.Extension;
		fileName = folder + item.FullName;
		if ( extension = "json" ) then
			Config = Conversion.FromJSON ( getText ( fileName ) );
			continue;
		endif;	
		if ( extension = "mxl" ) then
			data = new SpreadsheetDocument ();
			data.Read ( fileName );	
			id = item.BaseName;
			type = Template;
		else
			data = getText ( fileName );
			baseName = item.BaseName;
			if ( StrFind ( baseName, ".module" ) > 0 ) then
				id = StrReplace ( baseName, ".module", "" );
				type = Program;
			else
				id = StrReplace ( baseName, ".export", "" );
				type = Exporter;
			endif;
		endif;
		row = Files.Add ();
		row.ID = id;
		row.Type = type;
		row.Data = data;
	enddo;
	zip.Close ();

EndProcedure

Function getText ( FileName ) 

	text = new TextDocument ();
	text.Read ( FileName );	
	return text.GetText ();

EndFunction

Procedure getReportsList () 

	s = "
	|select Reports.Ref as Ref, Reports.Name as ID
	|from Catalog.Reports as Reports
	|where not Reports.DeletionMark
	|and Reports.Master
	|and Reports.Name in ( &IDs )
	|";
	q = new Query ( s );
	ids = new Array ();
	for each row in Config do
		ids.Add ( row.ID );	
	enddo;
	q.SetParameter ( "IDs", ids );
	ReportsList = q.Execute ().Unload ();
	ReportsList.Indexes.Add ( "ID" );

EndProcedure

Procedure runUpdateReports () 

	reportsManager = Catalogs.Reports;
	filter = new Structure ( "ID" );
	for each row in Config do
		id = row.ID;
		rowList = ReportsList.Find ( id, "ID" );
		if ( rowList = undefined ) then
			ref = undefined;
		else
			ref = rowList.Ref;
		endif;
		if ( row.Action = Remove ) then
			if ( ref = undefined ) then
				continue;
			endif;
			object = ref.GetObject ();
			object.Delete ();
		else
			if ( ref = undefined ) then
				object = reportsManager.CreateItem ();
			else
				object = ref.GetObject ();	
			endif;
			filter.ID = id;
			updateReport ( row, object, Files.FindRows ( filter ) );
		endif;
	enddo;

EndProcedure

Procedure updateReport ( RowConfig, Object, FilesRows ) 

	for each file in FilesRows do
		type = file.Type;
		data = file.Data;
		if ( type = Template ) then
			Object.Template = new ValueStorage ( data );
		elsif (type = Program ) then
			Object.Program = new ValueStorage ( data );
		else
			if ( data = "" ) then
				Object.HasExport = false;
				Object.Exporter = undefined;
			else
				Object.HasExport = true;
				Object.Exporter = new ValueStorage ( data );
			endif;
		endif;
	enddo;
	Object.Period = Enums.Periods [ RowConfig.Period ];
	Object.Description = RowConfig.Description;
	Object.Name = RowConfig.ID;
	if ( Object.IsNew () ) then
		Object.Master = true;
		Object.Company = Company;
		Object.Creator = User;	
		Object.Date = CurrentSessionDate ();
	endif;
	Object.Write ();	

EndProcedure

// *****************************************
// *********** Variables Initialization

Files = new ValueTable ();
columns = Files.Columns;
columns.Add ( "ID" );
columns.Add ( "Type" );
columns.Add ( "Data" );
Files.Indexes.Add ( "ID" );
Remove = "Remove";
Update = "Update";
Template = "Template";
Exporter = "Exporter";
Program = "Program";
Company = Logins.Settings ( "Company" ).Company;
User = SessionParameters.User;

#endif
