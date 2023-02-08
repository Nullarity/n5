&AtClient
var OldTime;
&AtClient
var OldTimeTo;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	startCalendar ();
	setTitle ();
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	InitialDate = Parameters.Date;
	if ( InitialDate = Date ( 1, 1, 1 ) ) then
		InitialDate = Max ( CurrentSessionDate (), Parameters.LeftBound );
	endif;
	CurrentDate = BegOfDay ( InitialDate );
	PreviousDate = CurrentDate;
	Variant = ? ( Parameters.Finishing, 1, 0 );
	Gap = Parameters.Gap;
	if ( Gap = 0 ) then
		Gap = 3600;
	else
		step = DatePicker.Scale ();
		Gap = step * Int ( ( Gap * 60 ) / step );
	endif;
	
EndProcedure

&AtServer
Procedure startCalendar ()
	
	date = Parameters.LeftBound;
	item = Items.CurrentDate;
	if ( date <> Date ( 1, 1, 1 ) ) then
		item.BeginOfRepresentationPeriod = BegOfDay ( date );
	endif;
	if ( Parameters.Period ) then
		item.SelectionMode = DateSelectionMode.Interval;
		Items.PeriodGroup.Visible = true;
	endif;
	
EndProcedure

&AtServer
Procedure setTitle ()
	
	if ( Parameters.Period ) then
		Title = Output.DatetimePeriodTitle ();
	else
		Title = Output.DatetimeTitle ();
	endif;
	
EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	if ( Parameters.Period ) then
		initPeriod ();
		showInterval ();
		if ( Variant = 1 ) then
			activatePeriod ();
		endif;
	endif;
	updateTime ();
	
EndProcedure

&AtClient
Procedure initPeriod ()
	
	date = CurrentDate + DatePicker.GetClose ( InitialDate );
	PeriodStart = date;
	dateTo = Parameters.DateTo;
	if ( dateTo = Date ( 1, 1, 1 ) ) then
		PeriodEnd = date + Gap;
	else
		PeriodEnd = Max ( date, DatePicker.Humanize ( Parameters.DateTo ) );
	endif;
	titlePeriod ();
	
EndProcedure

&AtClient
Procedure titlePeriod ()
	
	DetachIdleHandler ( "updatePeriod" );
	AttachIdleHandler ( "updatePeriod", 0.1, true );

EndProcedure

&AtClient
Procedure updatePeriod () export
	
	#if ( WebClient ) then
		// Workaround 8.3.12.1313: PeriodStart and PeriodEnd do not update presentation on the client.
		// Server call is required.
		format = Output.DatetimeFormat ();
		updatePeriodOnServer ( format );
	#else
		format = Output.DatetimeFormat ();
		Items.PeriodStart.ChoiceList [ 0 ].Presentation = Format ( PeriodStart, format );
		Items.PeriodEnd.ChoiceList [ 0 ].Presentation = Format ( PeriodEnd, format );
	#endif
	
EndProcedure
	
&AtServer
Procedure updatePeriodOnServer ( val Format )
	
	Items.PeriodStart.ChoiceList [ 0 ].Presentation = Format ( PeriodStart, Format );
	Items.PeriodEnd.ChoiceList [ 0 ].Presentation = Format ( PeriodEnd, Format );
	
EndProcedure

&AtClient
Procedure showInterval ()
	
	selection = Items.CurrentDate.SelectedDates;
	selection.Clear();
	date = BegOfDay ( PeriodStart );
	selection.Add ( date );
	date2 = BegOfDay ( PeriodEnd );
	if ( date <> date2 ) then
		selection.Add ( date2 );
	endif;
	
EndProcedure

&AtClient
Procedure updateTime ()
	
	lastTime = currentTime ( Items.Time );
	if ( Parameters.Period ) then
		fillTime ( Time, PeriodStart );
		lastTimeTo = currentTime ( Items.TimeTo );
		fillTime ( TimeTo, PeriodEnd );
		setTimeTo ( lastTimeTo );
	else
		fillTime ( Time, CurrentDate );
	endif;
	setTime ( lastTime );
	
EndProcedure

&AtClient
Function currentTime ( Control )
	
	currentData = Control.CurrentData;
	return ? ( currentData = undefined, undefined, currentData.Value );
	
EndFunction

&AtClient
Procedure fillTime ( List, Date )
	
	step = DatePicker.Scale ();
	period = BegOfDay ( Date );
	bound = Parameters.LeftBound;
	if ( period = BegOfDay ( bound ) ) then
		counter = DatePicker.GetClose ( bound );
		period = period + counter;
	else
		counter = 0;
	endif;
	List.Clear ();
	format = Output.TimeFormat ();
	while ( counter < 86400 ) do
		List.Add ( counter, Format ( period, format ) );
		counter = counter + step;
		period = period + step;
	enddo;
	
EndProcedure

&AtClient
Procedure setTime ( Value )
	
	item = Time.FindByValue ( Value );
	if ( item = undefined ) then
		item = Time.FindByValue ( DatePicker.GetClose ( InitialDate ) );
	endif;
	if ( item <> undefined ) then
		Items.Time.CurrentRow = item.GetID ();
	endif;

EndProcedure

&AtClient
Procedure setTimeTo ( Value )
	
	item = TimeTo.FindByValue ( Value );
	if ( item = undefined ) then
		item = TimeTo.FindByValue ( DatePicker.GetClose ( PeriodEnd ) );
	endif;
	if ( item <> undefined ) then
		Items.TimeTo.CurrentRow = item.GetID ();
	endif;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	done ();
	
EndProcedure

&AtClient
Procedure done ()
	
	if ( Parameters.Period ) then
		NotifyChoice ( new Structure ( "Start, Finish", PeriodStart, PeriodEnd ) );
	else
		NotifyChoice ( CurrentDate + currentTime ( Items.Time ) );
	endif;

EndProcedure

&AtClient
Procedure PeriodOnChange ( Item )
	
	activatePeriod ();
	
EndProcedure

&AtClient
Procedure activatePeriod ()
	
	if ( Variant = 0 ) then
		CurrentDate = BegOfDay ( PeriodStart );
		Items.TimePages.CurrentPage = Items.StartTime;
	else
		CurrentDate = BegOfDay ( PeriodEnd );
		Items.TimePages.CurrentPage = Items.FinishTime;
	endif;
	PreviousDate = CurrentDate;
	
EndProcedure

// *****************************************
// *********** Calendar

&AtClient
Procedure CurrentDateOnActivateDate ( Item )
	
	applySelectedDate ();

EndProcedure

&AtClient
Procedure applySelectedDate ()
	
	if ( Parameters.Period ) then
		setPeriod ();
		showInterval ();
		titlePeriod ();
	endif;
	if ( rebuildTime () ) then
		updateTime ();
	endif;
	PreviousDate = CurrentDate;

EndProcedure

&AtClient
Procedure setPeriod ( StartChanged = undefined, EndChanged = undefined )
	
	if ( Variant = 0 ) then
		seconds = currentTime ( Items.Time );
		date = CurrentDate + ? ( seconds = undefined, 0, seconds );
		if ( date > PeriodEnd
			or ( PeriodEnd - PeriodStart ) = Gap ) then
			PeriodEnd = date + Gap;
			EndChanged = true;
		endif;
		PeriodStart = date;
	else
		seconds = currentTime ( Items.TimeTo );
		date = CurrentDate + ? ( seconds = undefined, 0, seconds );
		if ( date < PeriodStart
			or ( PeriodStart - PeriodEnd ) = Gap ) then
			PeriodStart = Max ( date - Gap, Parameters.LeftBound );
			StartChanged = true;
		endif;
		PeriodEnd = date;
	endif;
	
EndProcedure

&AtClient
Function rebuildTime ()
	
	bound = BegOfDay ( Parameters.LeftBound );
	return bound <> Date ( 1, 1, 1 )
	and PreviousDate <> CurrentDate
	and ( PreviousDate = bound
		or CurrentDate = bound );
	
EndFunction

&AtClient
Procedure CurrentDateSelection ( Item, SelectedDate )
	
	done ();
	
EndProcedure

// *****************************************
// *********** Time List

&AtClient
Procedure TimeOnActivateRow ( Item )
	
	applyTime ( Item );
	
EndProcedure

&AtClient
Procedure applyTime ( Item )
	
	if ( not Parameters.Period
		or not positionChanged ( Item ) ) then
		return;
	endif;
	startChanged = false;
	endChanged = false;
	setPeriod ( startChanged, endChanged );
	if ( Item = Items.Time
		and endChanged ) then
		setTimeTo ( PeriodEnd - BegOfDay ( PeriodEnd ) );
	elsif ( Item = Items.TimeTo
		and startChanged ) then
		setTime ( PeriodStart - BegOfDay ( PeriodStart ) );
	endif;
	titlePeriod ();
	
EndProcedure

&AtClient
Function positionChanged ( Item )
	
	row = Item.CurrentData;
	if ( row = undefined ) then
		return false;
	endif;
	value = row.Value;
	if ( Item = Items.TimeTo ) then
		if ( OldTimeTo = value ) then
			return false;
		else
			OldTimeTo = value;
		endif;
		return Variant = 1;
	elsif ( OldTime = value ) then
		return false;
	else
		OldTime = value;
		return Variant = 0;
	endif;
	
EndFunction

&AtClient
Procedure TimeSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	done ();
	
EndProcedure
