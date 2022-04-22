#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Parameters export;
var JobKey export;
var SessionTenant;
var Tenants;
var Release;
var Files;
var Config;
var Remove;
//@skip-check module-unused-local-variable
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

Procedure _5_0_25_1 () export
	
	BeginTransaction ();
	for each tenant in Tenants do
		activateTenant ( tenant );
		setTaxNumbers ();
		updateAccounts ();
		loadCities ();
		updateReports ();
	enddo;
	CommitTransaction ();
	
EndProcedure

Procedure setTaxNumbers ()
	
	q = new Query ( "
	|select Forms.Document as Document, Forms.Form as Form, Forms.Status as Status,
	|	Forms.Form.Number as Number
	|from InformationRegister.Forms as Forms" );
	r = InformationRegisters.Forms.CreateRecordSet ();
	r.Load ( q.Execute ().Unload () );
	r.Write ();

EndProcedure

Procedure updateAccounts ()
	
	updateAccount ( "2265", "Дебиторская задолженность подотчетных лиц в валюте" );
	updateAccount ( "22441", "Прочие текущие авансы выданные внутри страны" );
	updateAccount ( "22442", "Прочие текущие авансы выданные из-за рубежа" );
	updateAccount ( "3111", "Уставный фонд в валюте" );
	updateAccount ( "3112", "Простые акции" );
	updateAccount ( "3113", "Простые акции в валюте" );
	updateAccount ( "3114", "Привилегированные акции" );
	updateAccount ( "3115", "Привилегированные акции в валюте" );
	updateAccount ( "3116", "Вклады" );
	updateAccount ( "3117", "Вклады в валюте" );
	updateAccount ( "3118", "Паи" );
	updateAccount ( "3119", "Паи в валюте" );
	updateAccount ( "3311", "Поправка прибыли предыдущих периодов" );
	updateAccount ( "3312", "Поправка убытков предыдущих периодов" );
	updateAccount ( "3321", "Нераспределенная прибыль прошлых лет" );
	updateAccount ( "3322", "Непокрытый убыток прошлых лет" );
	updateAccount ( "3331", "Чистая прибыль отчетного периода" );
	updateAccount ( "3332", "Чистые убытки отчетного периода" );
	updateAccount ( "5371", "Текущие целевые финансирование и поступления в стране" );
	updateAccount ( "5372", "Текущие целевые финансирование и поступления из-за рубежа" );
	updateAccount ( "7311", "Расходы по подоходному налогу" );
	updateAccount ( "7312", "Расходы по налогу на доход от операционной деятельности" );
	updateAccount ( "7313", "Прочие расходы по подоходному налогу" );
	updateAccount ( "8111", "Прямые материальные затраты" );
	updateAccount ( "8112", "Прямые затраты на оплату труда" );
	updateAccount ( "8113", "Отчисления на соц. страхование и обеспечение" );
	updateAccount ( "8114", "Косвенные производственные затраты" );
	updateAccount ( "8121", "Затраты на материалы" );
	updateAccount ( "8122", "Затраты на оплату труда" );
	updateAccount ( "8123", "Отчисл. на соц.страх. и обеспечение" );
	updateAccount ( "8124", "Косвенные производственные затраты" );
	updateAccount ( "8211", "Расходы на износ ОС" );
	updateAccount ( "8212", "Расходы на ремонт ОС" );
	updateAccount ( "8213", "Расходы на текущий ремонт ОС" );
	updateAccount ( "8214", "Амортизация НМА произв-го назначения" );
	updateAccount ( "8215", "Содержание упр. и обсл. перс. произв-х подр." );
	updateAccount ( "8216", "Охрана труда и техника безопасности" );
	updateAccount ( "8217", "Потери от простоев" );
	updateAccount ( "8218", "Содерж. охраны и затр. на обесп. ППБ пр. под." );
	updateAccount ( "8219", "Командиров. расходы произв-го персонала" );
	updateAccount ( "82110", "Прочие косвенные произв. затраты" );
	updateAccount ( "8311", "Торговая надбавка в розничной торговле" );
	updateAccount ( "8312", "Торговая надбавка в розничной торговле общими суммами" );
	
EndProcedure

Procedure updateAccount ( Account, Description )

	ref = ChartsOfAccounts.General.FindByCode ( Account );
	if ( ref.IsEmpty () ) then
		Message ( "code:" + Account + " is not found" );
		return;
	endif;
	obj = ref.GetObject ();
	obj.DescriptionRo = obj.Description;
	obj.DescriptionRu = Description;
	obj.Class = obj.Parent.Class;
	obj.Write ();

EndProcedure

Procedure loadCities ()

	country = Catalogs.Countries.FindByCode ( "498" );
	if ( country.IsEmpty () ) then
		return;
	endif;
	cities = getCities ( country );
	for each name in cities do
		obj = Catalogs.Cities.CreateItem ();
		obj.Owner = country;
		obj.Description = name;
		obj.Write ();
	enddo;

EndProcedure

Function getCities ( Country )

	s = "
	|select Cities.City as Name
	|into List
	|from &List as Cities
	|;
	|select List.Name as Name
	|from List as List
	|where List.Name not in ( select Description from Catalog.Cities where Owner = &Country )
	|";
	q = new Query ( s );
	q.SetParameter ( "Country", country );                                                       
	q.SetParameter ( "List", citiesList () );
	return q.Execute ().Unload ().UnloadColumn ( "Name" );

EndFunction

Function citiesList ()

	list = new ValueTable ();
	list.Columns.Add ( "City", Metadata.Catalogs.Cities.StandardAttributes.Description.Type );
	t = GetTemplate ( "Cities" );
	tableWidth = t.TableWidth;
	for i = 1 to t.TableHeight do
		for j = 1 to tableWidth do
			city = t.Area ( i, j, i, j ).Text;
			if ( IsBlankString ( city ) ) then
				continue;
			endif;
			row = list.Add ();
			row.City = TrimAll ( city );
		enddo;
	enddo;
	list.GroupBy ( "City" );
	return list;

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
