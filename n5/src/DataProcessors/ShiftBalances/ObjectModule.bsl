#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Parameters export;
var JobKey export;
var Meta;
var Metaname;

Procedure Exec () export
	
	init ();
	table = getDocuments ();
	date = Parameters.Date;
	for each row in table do
		obj = row.Ref.GetObject ();
		obj.Date = date;
		try
			obj.Write ( ? ( row.Posted, DocumentWriteMode.Posting, DocumentWriteMode.Write ) );
		except
			logError ( ErrorDescription () );
		endtry;
	enddo; 

EndProcedure

Procedure init ()
	
	Meta = Metadata ();
	Metaname = Meta.FullName ();
	
EndProcedure 

Function getDocuments ()
	
	s = "
	|select Balances.Ref as Ref, Balances.Posted as Posted
	|from DocumentJournal.Balances as Balances
	|where Balances.Company = &Company
	|";
	q = new Query ( s );
	q.SetParameter ( "Company", Parameters.Company );
	return q.Execute ().Unload ();
	
EndFunction 

Procedure logError ( Error )
	
	Progress.Put ( Error, JobKey, true );
	WriteLogEvent ( Metaname, EventLogLevel.Error, Meta, , Error );
	
EndProcedure 

#endif