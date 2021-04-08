// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	Object.RefreshRates = true;
	fill ();
	initPeriod ();
	
EndProcedure

&AtServer
Procedure fill () 
	
	table = getRates ();
	marks = Object.List.Unload ( , "Download, Currency" );
	for each row in table do
		found = marks.Find ( row.Currency, "Currency" );
		if ( found <> undefined ) then
			row.Download = found.Download;
		endif; 
	enddo; 
	Object.List.Load ( table );
	
EndProcedure

&AtServer
Function getRates ()
	
	s = "
	|select Currencies.Ref as Currency, true as Download, Rates.Rate as Rate,
	|	Rates.Factor as Factor, Rates.Period as Period 
	|from Catalog.Currencies as Currencies
	|	//
	|	// Rates
	|	//
	|	left join InformationRegister.ExchangeRates.SliceLast as Rates
	|	on Rates.Currency = Currencies.Ref
	|where not Currencies.DeletionMark
	|and Currencies.Ref <> &LocalCurrency
	|order by Currencies.Ref.Description";
	q = new Query ( s );
	q.SetParameter ( "LocalCurrency", Application.Currency () );
	return q.Execute ().Unload ();
	
EndFunction 

&AtServer
Procedure initPeriod ()
	
	dateEnd = CurrentDate ();
	dateStart = Date ( 1980, 1, 1 );
	for each row in Object.List do
		if ( row.Period <= dateEnd
			and row.Period > dateStart ) then
			dateStart = row.Period;
		endif; 
	enddo;
	Object.DateStart = dateStart;
	Object.DateEnd = dateEnd;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not checkList () ) then
		Cancel = true;
	endif; 
	
EndProcedure

&AtServer
Function checkList ()
	
	error = Object.List.FindRows ( new Structure ( "Download", true ) ).Count () = 0;
	if ( error ) then
		OutputCont.CheckCurrency ( , "List [ 0 ].Download" );
	endif;
	return not error;
	
EndFunction 

// *****************************************
// *********** Group Form

&AtClient
Procedure Download ( Command )
	
	
	if ( CheckFilling () ) and ( dateEndValid () ) then
		jobKey = "DownloadCurrencies" + UserName ();
		run ( jobKey );
		Progress.Open ( jobKey, ThisObject, new NotifyDescription ( "Complete", ThisObject ), true );
	endif; 
	
EndProcedure

&AtClient
Function dateEndValid () 

	valid = true;
	if ( BegOfDay ( Object.DateEnd ) > BegOfDay ( CurrentDate () ) ) then
		OutputCont.InvalidDateEnd ( , "DateEnd" );
		valid = false;
	endif;
	return valid;

EndFunction

&AtServer
Procedure run ( JobKey ) 

	BackgroundJobs.Execute ( "DownloadCurrencies.Download", getParameters (), JobKey );
	fill ();

EndProcedure

&AtServer
Function getParameters () 

	s = new Structure ();
	s.Insert ( "DateStart", Object.DateStart );
	s.Insert ( "DateEnd", Object.DateEnd );
	s.Insert ( "RefreshRates", Object.RefreshRates );
	s.Insert ( "CurrenciesTable", Object.List.Unload ( new Structure ( "Download", true ), "Currency" ) );
	p = new Array ();
	p.Add ( s );
	return p;

EndFunction

&AtClient
Procedure Complete ( Result, Params ) export
	
	for each message in messages () do
		message.Message ();
	enddo;
	
EndProcedure

&AtServerNoContext
Function messages ()

	return BackgroundJobs.GetBackgroundJobs (
		new Structure ( "Key", "DownloadCurrencies" + UserName () ) )
			[ 0 ].GetUserMessages ();

EndFunction

// *****************************************
// *********** Table List

&AtClient
Procedure MarkAll ( Command )
	
	mark ( true );
	
EndProcedure

&AtClient
Procedure mark ( Flag ) 

	for each row in Object.List do
		row.Download = Flag;
	enddo;

EndProcedure

&AtClient
Procedure UnMarkAll ( Command )
	
	mark ( false );
	
EndProcedure

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	if ( Field <> Items.ListDownload ) then
		f = new Structure ( "Currency", Item.CurrentData.Currency );
		OpenForm ( "InformationRegister.ExchangeRates.ListForm", new Structure ( "Filter", f ) );
	endif;
	
EndProcedure
