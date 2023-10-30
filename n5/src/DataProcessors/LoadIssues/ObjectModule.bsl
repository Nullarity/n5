#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Parameters export;
var JobKey export;
var RepositoryInfo;
var Finder;
var Issue;
var Object;
var LastError;
var LastSynching;

Procedure Exec () export
	
	repositoryInfo ();
	if ( not supported () ) then
		return;
	endif;
	init ();
	load ();
	commit ();
	
EndProcedure

Procedure repositoryInfo ()
	
	s = "
	|select Repositories.URL as URL, isnull ( Tokens.Token, """" ) as Token
	|from Catalog.Repositories as Repositories
	|	//
	|	// Tokens
	|	//
	|	left join InformationRegister.Tokens as Tokens
	|	on Tokens.Target = Repositories.Ref
	|where Repositories.Ref = &Ref";
	q = new Query ( s );
	q.SetParameter ( "Ref", Parameters.Repository );
	RepositoryInfo = q.Execute ().Unload () [ 0 ];
	
EndProcedure

Function supported ()
	
	supported = StrFind ( Lower ( RepositoryInfo.URL ), "github.com" ) > 0;
	if ( not supported ) then
		Progress.Put ( Output.RepositoryNotSupported (), JobKey, true );
	endif;
	return supported;
	
EndFunction

Procedure init ()

	LastSynching = CurrentSessionDate ();
	initFinder ();

EndProcedure

Procedure initFinder ()

	s = "
	|select Issues.ID as ID, Issues.Ref as Ref
	|from Document.Issue as Issues
	|where Issues.Repository = &Repo
	|and ID = &ID";
	Finder = new Query ( s );
	Finder.SetParameter ( "Repo", Parameters.Repository );

EndProcedure

Procedure load ()
	
	list = fetch ();
	if ( list = undefined ) then
		return;
	endif;
	for each Issue in list do
		BeginTransaction ();
		getIssue ();
		fill ();
		if ( write () ) then
			CommitTransaction ();
		else
			while ( TransactionActive () ) do
				RollbackTransaction ();
			enddo;
			Progress.Put ( Output.ErrorSavingIssue (
				new Structure ( "Issue, Error", Issue [ "number" ], LastError ) ),
				JobKey, true );
			raise Output.OperationError ();
		endif;
	enddo;
	
EndProcedure

Function fetch ()
	
	dateFrom = Parameters.Since;
	if ( dateFrom = Date ( 1, 1, 1 ) ) then
		dateFrom = "";
	else
		dateFrom = WriteJSONDate ( dateFrom, JSONDateFormat.ISO, JSONDateWritingVariant.UniversalDate );
	endif;
	json = CoreLibrary.GetIssues ( RepositoryInfo.URL, RepositoryInfo.Token, dateFrom, "" );
	reader = new JSONReader ();
	reader.SetString ( json );
	dates = new Array ();
	dates.Add ( "created_at" );
	dates.Add ( "updated_at" );
	dates.Add ( "closed_at" );
	return ReadJSON ( reader, true, dates, JSONDateFormat.ISO );
	
EndFunction

Procedure getIssue ()
	
	lock ();
	ref = findIssue ();
	if ( ref = undefined ) then
		Object = Documents.Issue.CreateDocument ();
	else
		Object = ref.GetObject ();
	endif;
	
EndProcedure

Procedure lock ()
	
	lock = new DataLock ();
	item = lock.Add ( "Document.Issue");
	item.Mode = DataLockMode.Exclusive;
	item.SetValue ( "Repository", Parameters.Repository );
	item.SetValue ( "ID", Issue [ "id" ] );
	lock.Lock ();
	
EndProcedure

Function findIssue ()
	
	Finder.SetParameter ( "ID", Issue [ "id" ] );
	table = Finder.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
EndFunction

Procedure fill ()
	
	Object.Date = Issue [ "created_at" ];
	Object.Closed = Issue [ "closed_at" ];
	Object.Creator = SessionParameters.User;
	Object.Details = Issue [ "body" ];
	Object.ID = Issue [ "id" ];
	Object.IssueNumber = Issue [ "number" ];
	Object.Repository = Parameters.Repository;
	Object.Status = Issue [ "state" ];
	Object.Title = Issue [ "title" ];
	Object.Updated = Issue [ "updated_at" ];
	Object.URL = Issue [ "html_url" ];
	user = Issue [ "user" ];
	Object.User = user [ "login" ];
	Object.Profile = user [ "html_url" ];
	labels = Object.Labels;
	labels.Clear ();
	for each label in Issue [ "labels" ] do
		row = labels.Add ();
		row.Name = label [ "name" ];
	enddo;
	
EndProcedure

Function write ()
	
	try
		SetPrivilegedMode ( true );
		if ( Object.IsNew () ) then
			Object.Write();
		else
			Object.Write ();
			if ( Object.DeletionMark ) then
				Object.SetDeletionMark ( false );
			endif;
		endif;
		return true;
	except
		LastError = ErrorDescription ();
		return false;
	endtry;
	
EndFunction

Procedure commit ()
	
	r = InformationRegisters.GitSyncing.CreateRecordManager ();
	r.Repository = Parameters.Repository;
	r.Date = LastSynching;
	r.Write ();
	
EndProcedure

#endif