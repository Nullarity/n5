&AtServer
var SchedulesTable;
&AtServer
var WeekHours;
&AtServer
var WeekHoursEvening;
&AtServer
var WeekHoursNight;
&AtClient
var CurrentYearsRow;
&AtClient
var yearsRow;
&AtClient
var SchedulesRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	Forms.RedefineOpeningModeForLinux ( ThisObject );
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
	endif;
	filterBySchedule ();
	setCurrentYear ();
	initFormFields ();
	filterByYear ();
	fillMonths ();
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|TimesheetDays enable Object.TimesheetPeriod = Enum.TimesheetPeriods.Other;
	|Schedules lock not ManualChanges;
	|ManualChanges press ManualChanges;
	|OvertimeCoef1 OvertimeCoef2 OvertimeLimit enable Object.UseOvertime;
	|Calendar Schedules enable filled ( Object.Ref );
	|Write show empty ( Object.Ref )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	weekStarts = WeekDay ( BegOfWeek ( CurrentDate () ) );
	if ( weekStarts = 1 ) then
		Object.WeekStart = Enums.Week.Monday;
	elsif ( weekStarts = 7 ) then
		Object.WeekStart = Enums.Week.Sunday;
	elsif ( weekStarts = 2 ) then
		Object.WeekStart = Enums.Week.Tuesday;
	elsif ( weekStarts = 3 ) then
		Object.WeekStart = Enums.Week.Wednesday;
	elsif ( weekStarts = 4 ) then
		Object.WeekStart = Enums.Week.Thursday;
	elsif ( weekStarts = 5 ) then
		Object.WeekStart = Enums.Week.Friday;
	else
		Object.WeekStart = Enums.Week.Saturday;
	endif;
	
EndProcedure

&AtServer
Procedure filterBySchedule ()
	
	Schedules.Parameters.SetParameterValue ( "Schedule", Object.Ref );
	
EndProcedure 

&AtServer
Procedure setCurrentYear ()
	
	CurrentYear = Year ( CurrentDate () );
	
EndProcedure 

&AtServer
Procedure initFormFields ()
	
	Year = 1;
	ManualChanges = false;
	
EndProcedure 

&AtServer
Procedure filterByYear ()
	
	Schedules.Parameters.SetParameterValue ( "Year", Year );
	Items.Calendar.BeginOfRepresentationPeriod = Date ( Year, 1, 1 );
	Items.Calendar.EndOfRepresentationPeriod = Date ( Year, 12, 31 );
	
EndProcedure 

&AtServer
Procedure fillMonths ()
	
	table = getMonths ();
	loadMonths ( table );
	
EndProcedure 

&AtServer
Function getMonths ()
	
	s = "
	|select Schedules.Year as Year, beginofperiod ( Schedules.Day, month ) as Month,
	|	sum ( case when Holidays.Day is null then Schedules.Minutes else 0 end / 60 ) as Hours,
	|	sum ( case when Holidays.Day is null then Schedules.MinutesEvening else 0 end / 60 ) as EveningHours,
	|	sum ( case when Holidays.Day is null then Schedules.MinutesNight else 0 end / 60 ) as NightHours,
	|	sum ( case when Holidays.Day is null then case when Schedules.Minutes > 0 then 1 else 0 end else 0 end ) as Days,
	|	sum ( case when Holidays.Day is null then 0 else 1 end ) as Holidays
	|from InformationRegister.Schedules as Schedules
	|	//
	|	// Holidays
	|	//
	|	left join InformationRegister.Holidays as Holidays
	|	on Holidays.Reference = &Holidays
	|	and Holidays.Day = Schedules.Day
	|where Schedules.Schedule = &Schedule
	|group by Schedules.Year, beginofperiod ( Schedules.Day, month )
	|order by Year desc, Month
	|totals by Year
	|";
	q = new Query ( s );
	q.SetParameter ( "Holidays", Object.Holidays );
	q.SetParameter ( "Schedule", Object.Ref );
	return q.Execute ().Unload ( QueryResultIteration.ByGroups );
	
EndFunction 

&AtServer
Procedure loadMonths ( Table )
	
	currentMonth = BegOfMonth ( CurrentSessionDate () );
	rows = Months.GetItems ();
	rows.Clear ();
	for each yearsRow in Table.Rows do
		newRow = rows.Add ();
		FillPropertyValues ( newRow, yearsRow );
		newRow.Current = ( CurrentYear = yearsRow.Year );
		newRow.Presentation = Format ( yearsRow.Year, "NG=" );
		childRows = newRow.GetItems ();
		for each monthsRow in yearsRow.Rows do
			newRow = childRows.Add ();
			FillPropertyValues ( newRow, monthsRow );
			newRow.Presentation = Format ( monthsRow.Month, "DF='MMMM, yyyy'" );
			newRow.Current = ( currentMonth = monthsRow.Month );
		enddo; 
	enddo; 
	
EndProcedure 

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not checkHours () ) then
		Cancel = true;
	endif; 
	
EndProcedure

&AtServer
Function checkHours ()
	
	error = false;
	ref = Object.Ref;
	for each yearsRow in Object.Years do
		if ( ( yearsRow.Monday - yearsRow.MondayEvening - yearsRow.MondayNight ) < 0 ) then
			column = "Monday";
		elsif ( ( yearsRow.Tuesday - yearsRow.TuesdayEvening - yearsRow.TuesdayNight ) < 0 ) then
			column = "Tuesday";
		elsif ( ( yearsRow.Wednesday - yearsRow.WednesdayEvening - yearsRow.WednesdayNight ) < 0 ) then
			column = "Wednesday";
		elsif ( ( yearsRow.Thursday - yearsRow.ThursdayEvening - yearsRow.ThursdayNight ) < 0 ) then
			column = "Thursday";
		elsif ( ( yearsRow.Friday - yearsRow.FridayEvening - yearsRow.FridayNight ) < 0 ) then
			column = "Friday";
		elsif ( ( yearsRow.Saturday - yearsRow.SaturdayEvening - yearsRow.SaturdayNight ) < 0 ) then
			column = "Saturday";
		elsif ( ( yearsRow.Sunday - yearsRow.SundayEvening - yearsRow.SundayNight ) < 0 ) then
			column = "Sunday";
		else
			continue;
		endif; 
		error = true;
		Output.WrongTotalHours ( , Output.Row ( "Years", yearsRow.LineNumber, column ), ref );
	enddo; 
	return not error;
	
EndFunction 

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	prepareSchedulesTable ();
	
EndProcedure

&AtServer
Procedure prepareSchedulesTable ()
	
	getOldSchedulesTable ();
	getScheduleChanges ();
	
EndProcedure 

&AtServer
Procedure getOldSchedulesTable ()
	
	s = "
	|select Years.Year as Year, Years.Monday as Monday, Years.Tuesday as Tuesday, Years.Wednesday as Wednesday, Years.Thursday as Thursday,
	|	Years.Friday as Friday, Years.Saturday as Saturday, Years.Sunday as Sunday,
	|	Years.ManualChanges as ManualChanges, ""Remove"" as Action,
	|	Years.MondayEvening as MondayEvening, Years.TuesdayEvening as TuesdayEvening, Years.WednesdayEvening as WednesdayEvening,
	|	Years.ThursdayEvening as ThursdayEvening, Years.FridayEvening as FridayEvening, Years.SaturdayEvening as SaturdayEvening,
	|	Years.SundayEvening as SundayEvening,
	|	Years.MondayNight as MondayNight, Years.TuesdayNight as TuesdayNight, Years.WednesdayNight as WednesdayNight,
	|	Years.ThursdayNight as ThursdayNight, Years.FridayNight as FridayNight, Years.SaturdayNight as SaturdayNight,
	|	Years.SundayNight as SundayNight
	|from Catalog.Schedules.Years as Years
	|where Years.Ref = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	SchedulesTable = q.Execute ().Unload ();
	
EndProcedure 

&AtServer
Procedure getScheduleChanges ()
	
	for each yearsRow in Object.Years do
		foundYear = SchedulesTable.Find ( yearsRow.Year, "Year" );
		if ( foundYear = undefined ) then
			schedulesRow = SchedulesTable.Add ();
			FillPropertyValues ( schedulesRow, yearsRow );
			schedulesRow.Action = ? ( yearsRow.ManualChanges, "Skip", "Add" );
		else
			if ( yearsRow.Monday <> foundYear.Monday
				or yearsRow.Tuesday <> foundYear.Tuesday
				or yearsRow.Wednesday <> foundYear.Wednesday
				or yearsRow.Thursday <> foundYear.Thursday
				or yearsRow.Friday <> foundYear.Friday
				or yearsRow.Saturday <> foundYear.Saturday
				or yearsRow.Sunday <> foundYear.Sunday
				or yearsRow.MondayEvening <> foundYear.MondayEvening
				or yearsRow.TuesdayEvening <> foundYear.TuesdayEvening
				or yearsRow.WednesdayEvening <> foundYear.WednesdayEvening
				or yearsRow.ThursdayEvening <> foundYear.ThursdayEvening
				or yearsRow.FridayEvening <> foundYear.FridayEvening
				or yearsRow.SaturdayEvening <> foundYear.SaturdayEvening
				or yearsRow.SundayEvening <> foundYear.SundayEvening
				or yearsRow.MondayNight <> foundYear.MondayNight
				or yearsRow.TuesdayNight <> foundYear.TuesdayNight
				or yearsRow.WednesdayNight <> foundYear.WednesdayNight
				or yearsRow.ThursdayNight <> foundYear.ThursdayNight
				or yearsRow.FridayNight <> foundYear.FridayNight
				or yearsRow.SaturdayNight <> foundYear.SaturdayNight
				or yearsRow.SundayNight <> foundYear.SundayNight
				or yearsRow.ManualChanges <> foundYear.ManualChanges ) then
				if ( yearsRow.ManualChanges ) then
					foundYear.Action = "Skip";
				else
					FillPropertyValues ( foundYear, yearsRow );
					foundYear.Action = "Change";
				endif;
			else
				foundYear.Action = "Skip";
			endif; 
		endif; 
	enddo; 
	
EndProcedure

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	writeSchedules ( CurrentObject.Ref );
	
EndProcedure

&AtServer
Procedure writeSchedules ( Ref )
	
	for each scheduleRow in SchedulesTable do
		if ( scheduleRow.Action = "Add" or scheduleRow.Action = "Change" ) then
			writeScheduleRow ( scheduleRow, Ref );
		elsif ( scheduleRow.Action = "Skip" ) then
		elsif ( scheduleRow.Action = "Remove" ) then
			removeSchedule ( scheduleRow, Ref );
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Procedure writeScheduleRow ( ScheduleRow, Ref )
	
	getWeekHours ( ScheduleRow );
	makeSchedule ( ScheduleRow, Ref );
	
EndProcedure 

&AtServer
Procedure getWeekHours ( ScheduleRow )
	
	WeekHours = new Array ();
	WeekHours.Add ( 0 );
	WeekHours.Add ( ScheduleRow.Monday );
	WeekHours.Add ( ScheduleRow.Tuesday );
	WeekHours.Add ( ScheduleRow.Wednesday );
	WeekHours.Add ( ScheduleRow.Thursday );
	WeekHours.Add ( ScheduleRow.Friday );
	WeekHours.Add ( ScheduleRow.Saturday );
	WeekHours.Add ( ScheduleRow.Sunday );
	WeekHoursEvening = new Array ();
	WeekHoursEvening.Add ( 0 );
	WeekHoursEvening.Add ( ScheduleRow.MondayEvening );
	WeekHoursEvening.Add ( ScheduleRow.TuesdayEvening );
	WeekHoursEvening.Add ( ScheduleRow.WednesdayEvening );
	WeekHoursEvening.Add ( ScheduleRow.ThursdayEvening );
	WeekHoursEvening.Add ( ScheduleRow.FridayEvening );
	WeekHoursEvening.Add ( ScheduleRow.SaturdayEvening );
	WeekHoursEvening.Add ( ScheduleRow.SundayEvening );
	WeekHoursNight = new Array ();
	WeekHoursNight.Add ( 0 );
	WeekHoursNight.Add ( ScheduleRow.MondayNight );
	WeekHoursNight.Add ( ScheduleRow.TuesdayNight );
	WeekHoursNight.Add ( ScheduleRow.WednesdayNight );
	WeekHoursNight.Add ( ScheduleRow.ThursdayNight );
	WeekHoursNight.Add ( ScheduleRow.FridayNight );
	WeekHoursNight.Add ( ScheduleRow.SaturdayNight );
	WeekHoursNight.Add ( ScheduleRow.SundayNight );
	
EndProcedure 

&AtServer
Procedure makeSchedule ( ScheduleRow, Ref )
	
	recordset = InformationRegisters.Schedules.CreateRecordSet ();
	recordset.Filter.Schedule.Set ( Ref );
	recordset.Filter.Year.Set ( ScheduleRow.Year );
	day = Date ( ScheduleRow.Year, 1, 1 );
	weekDay = WeekDay ( day );
	dateEnd = Date ( ScheduleRow.Year, 12, 31 );
	while ( day <= dateEnd ) do
		record = recordset.Add ();
		record.Schedule = Ref;
		record.Year = ScheduleRow.Year;
		record.Day = day;
		value = WeekHours [ weekDay ];
		record.Duration = value;
		record.Minutes = Conversion.DurationToMinutes ( value );
		value = WeekHoursEvening [ weekDay ];
		record.DurationEvening = value;
		record.MinutesEvening = Conversion.DurationToMinutes ( value );
		value = WeekHoursNight [ weekDay ];
		record.DurationNight = value;
		record.MinutesNight = Conversion.DurationToMinutes ( value );
		day = day + 86400;
		weekDay = ? ( weekDay = 7, 1, weekDay + 1 );
	enddo; 
	recordset.Write ();
	
EndProcedure 

&AtServer
Procedure removeSchedule ( ScheduleRow, Ref )
	
	recordset = InformationRegisters.Schedules.CreateRecordSet ();
	recordset.Filter.Schedule.Set ( Ref );
	recordset.Filter.Year.Set ( ScheduleRow.Year );
	recordset.Write ();
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	filterBySchedule ();
	fillMonths ();
	Appearance.Apply ( ThisObject, "Object.Ref" );
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	Notify ( Enum.MessageScheduleChanged (), Object.Ref );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure TimesheetPeriodOnChange ( Item )
	
	setTimesheetFields ();
	Appearance.Apply ( ThisObject, "Object.TimesheetPeriod" );
	
EndProcedure

&AtClient
Procedure setTimesheetFields ()
	
	if ( Object.TimesheetPeriod = PredefinedValue ( "Enum.TimesheetPeriods.Other" ) ) then
		if ( Object.TimesheetDays = 0 ) then
			Object.TimesheetDays = 15;
		endif;
	else
		Object.TimesheetDays = 0;
	endif; 
	
EndProcedure 

&AtClient
Procedure UseOvertimeOnChange ( Item )
	
	setOvertimeFields ();
	Appearance.Apply ( ThisObject, "Object.UseOvertime" );
	
EndProcedure

&AtClient
Procedure setOvertimeFields ()
	
	if ( Object.UseOvertime ) then
		if ( Object.OvertimeCoef1 = 0 ) then
			Object.OvertimeCoef1 = 1.5;
			Object.OvertimeCoef2 = 2;
			Object.OvertimeLimit = 4;
		endif; 
	else
		Object.OvertimeCoef1 = 0;
		Object.OvertimeCoef2 = 0;
		Object.OvertimeLimit = 0;
	endif; 
	
EndProcedure 

&AtClient
Procedure PagesOnCurrentPageChange ( Item, CurrentPage )
	
	if ( CurrentPage = Items.GroupCalendar ) then
		CurrentYearsRow = Items.Years.CurrentRow; // Workaround: platform is reseting current row after server call
		extractYearFields ();
		activateYearsRow ();
	else
		Items.Years.CurrentRow = CurrentYearsRow;
	endif; 
	
EndProcedure

&AtClient
Procedure extractYearFields ()
	
	if ( yearsRow = undefined ) then
		Year = 1;
		ManualChanges = false;
	else
		Year = Max ( 1, yearsRow.Year );
		ManualChanges = yearsRow.ManualChanges;
	endif; 
	
EndProcedure 

&AtServer
Procedure activateYearsRow ()
	
	filterByYear ();
	Appearance.Apply ( ThisObject, "ManualChanges" );
	
EndProcedure 

// *****************************************
// *********** Group Years

&AtClient
Procedure YearsOnActivateRow ( Item )
	
	yearsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure YearsOnStartEdit ( Item, NewRow, Clone )
	
	if ( Clone or not NewRow ) then
		return;
	endif; 
	fillYearRowByDefault ();
	
EndProcedure

&AtClient
Procedure fillYearRowByDefault ()
	
	yearsRow.Year = getNextYear ();
	yearsRow.Monday = getWorkingHours ( PredefinedValue ( "Enum.Week.Monday" ) );
	yearsRow.Tuesday = getWorkingHours ( PredefinedValue ( "Enum.Week.Tuesday" ) );
	yearsRow.Wednesday = getWorkingHours ( PredefinedValue ( "Enum.Week.Wednesday" ) );
	yearsRow.Thursday = getWorkingHours ( PredefinedValue ( "Enum.Week.Thursday" ) );
	yearsRow.Friday = getWorkingHours ( PredefinedValue ( "Enum.Week.Friday" ) );
	yearsRow.Saturday = getWorkingHours ( PredefinedValue ( "Enum.Week.Saturday" ) );
	yearsRow.Sunday = getWorkingHours ( PredefinedValue ( "Enum.Week.Sunday" ) );
	
EndProcedure 

&AtClient
Function getWorkingHours ( Weekday )
	
	if ( Weekday = Object.DayOff1
		or Weekday = Object.DayOff2 ) then
		return 0;
	else
		return 8;
	endif; 
	
EndFunction 

&AtClient
Function getNextYear ()
	
	year = 0;
	for each yearsRow in Object.Years do
		year = Max ( year, yearsRow.Year );
	enddo; 
	return ? ( year = 0, CurrentYear, year + 1 );
	
EndFunction 

&AtClient
Procedure YearsBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	Output.RemoveScheduleYear ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure RemoveScheduleYear ( Answer, Item ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	Forms.DeleteSelectedRows ( Object.Years, Item );
	Modified = true;
	
EndProcedure 

&AtClient
Procedure YearsMondayOnChange ( Item )
	
	adjustTime ( Item );
	
EndProcedure

&AtClient
Procedure adjustTime ( Item )
	
	column = Mid ( Item.Name, 6 );
	Conversion.AdjustTime ( yearsRow [ column ] );
	
EndProcedure 

// *****************************************
// *********** Group Calendar

&AtClient
Procedure CalendarSelection ( Item, SelectedDate )
	
	openSelectedDate ();
	
EndProcedure

&AtClient
Procedure openSelectedDate ()
	
	CurrentScheduleRecordKey = getAndActivateScheduleRow ();
	if ( CurrentScheduleRecordKey = undefined ) then
		if ( not ManualChanges ) then
			Output.ScheduleDayNotFound ();
			return;
		endif; 
		hours = getHoursByDate ( Calendar );
		fillingValues = new Structure ( "Schedule, Year, Day, Hours", Object.Ref, Year, Calendar, hours );
		p = new Structure ( "FillingValues", fillingValues );
	else
		p = new Structure ( "Key, ReadOnly", CurrentScheduleRecordKey, not ManualChanges );
	endif; 
	OpenForm ( "InformationRegister.Schedules.RecordForm", p, Items.Schedules );
	
EndProcedure 

&AtServer
Function getAndActivateScheduleRow ()
	
	p = new Structure ( "Schedule, Year, Day", Object.Ref, Year, Calendar );
	r = InformationRegisters.Schedules.CreateRecordManager ();
	FillPropertyValues ( r, p );
	r.Read ();
	if ( r.Selected () ) then
		recordKey = InformationRegisters.Schedules.CreateRecordKey ( p );
		Items.Schedules.CurrentRow = recordKey;
		return recordKey;
	endif;
	return undefined;
	
EndFunction

&AtClient
Function getHoursByDate ( Day )
	
	weekDay = WeekDay ( Day );
	if ( weekDay = 1 ) then
		return yearsRow.Monday;
	elsif ( weekDay = 2 ) then
		return yearsRow.Tuesday;
	elsif ( weekDay = 3 ) then
		return yearsRow.Wednesday;
	elsif ( weekDay = 4 ) then
		return yearsRow.Thursday;
	elsif ( weekDay = 5 ) then
		return yearsRow.Friday;
	elsif ( weekDay = 6 ) then
		return yearsRow.Saturday;
	else
		return yearsRow.Sunday;
	endif; 
	
EndFunction 

&AtClient
Procedure ManualChanges ( Command )
	
	if ( ManualChanges ) then
		Output.UncheckManualChanges ( ThisObject );
	else
		resetManualChanges ();
	endif; 
	
EndProcedure

&AtClient
Procedure UncheckManualChanges ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		resetManualChanges ();
	endif; 
	
EndProcedure 

&AtClient
Procedure resetManualChanges ()
	
	fillScheduleYear ();
	setManualChanges ( not ManualChanges );
	Appearance.Apply ( ThisObject, "ManualChanges" );
		
EndProcedure 

&AtServer
Procedure fillScheduleYear ()
	
	writeScheduleRow ( Object.Years.FindRows ( new Structure ( "Year", Year ) ) [ 0 ], Object.Ref );
	
EndProcedure 

&AtClient
Procedure setManualChanges ( Value )
	
	ManualChanges = Value;
	yearsRow.ManualChanges = Value;
	
EndProcedure 

&AtClient
Procedure SchedulesOnActivateRow ( Item )
	
	SchedulesRow = Item.CurrentData;
	setCurrentCalendarDate ();
	
EndProcedure

&AtClient
Procedure setCurrentCalendarDate ()
	
	if ( SchedulesRow = undefined ) then
		return;
	endif; 
	Calendar = SchedulesRow.Day;
	
EndProcedure 

&AtClient
Procedure SchedulesBeforeAddRow ( Item, Cancel, Clone, Parent, Folder )
	
	if ( Clone ) then
		return;
	endif; 
	Cancel = true;
	openNewScheduleRecord ();
	
EndProcedure

&AtClient
Procedure openNewScheduleRecord ()
	
	fillingValues = new Structure ( "Schedule, Year, Day", Object.Ref, Year, Date ( Year, 1, 1 ) );
	p = new Structure ( "FillingValues", fillingValues );
	OpenForm ( "InformationRegister.Schedules.RecordForm", p, Items.Schedules );
	
EndProcedure 
