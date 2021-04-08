&AtClient
var HourStart;
&AtClient
var HourEnd;
&AtClient
var ShowPerformers;
&AtClient
var WarningColor;
&AtClient
var PastTimeColor;
&AtClient
var Holidays;
&AtClient
var Tabloid;
&AtClient
var PickedElement;
&AtClient
var EditingObjects;
&AtClient
var AccessRights;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( not SessionParameters.TenantUse ) then
		Cancel = true;
		return;
	endif;
	if ( Forms.InsideMobileHomePage ( ThisObject ) ) then
		Cancel = true;
		return;
	endif;
	initOptions ();
	initMobileMenu ();
	loadParams ();
	adjustMobile ();
	initDialogTypes ();
	readAccess ();
	filterRerformers ();
	filterCustomers ();
	filterCompleted ();
	setLayoutByDefault ();
	setWeekInfo ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure initOptions ()
	
	ProjectsAccess = AccessRight ( "View", Metadata.Catalogs.Projects );
	RoomsAccess = AccessRight ( "View", Metadata.Documents.Meeting );
	EventsAccess = AccessRight ( "View", Metadata.Documents.Event );
	MobileClient = Environment.MobileClient ();
	
EndProcedure

&AtServer
Procedure initMobileMenu ()
	
	if ( MobileClient ) then
		if ( AccessRight ( "Insert", Metadata.Tasks.UserTask ) ) then
			MobileMenu.Add ( Enum.CalendarMenuNewTask (), Output.UserTask () );
		endif;
		if ( AccessRight ( "Insert", Metadata.Documents.Event ) ) then
			MobileMenu.Add ( Enum.CalendarMenuNewEvent (), Output.Meeting () );
		endif;
		if ( AccessRight ( "Insert", Metadata.BusinessProcesses.Command ) ) then
			MobileMenu.Add ( Enum.CalendarMenuNewCommand (), Output.Command () );
		endif;
		if ( AccessRight ( "Insert", Metadata.Documents.TimeEntry ) ) then
			MobileMenu.Add ( Enum.CalendarMenuNewTimeEntry (), Output.TimeEntry () );
		endif;
		if ( AccessRight ( "Insert", Metadata.Documents.Meeting ) ) then
			MobileMenu.Add ( Enum.CalendarMenuNewMeeting (), Output.Meeting () );
		endif;
		if ( AccessRight ( "Insert", Metadata.Catalogs.Projects ) ) then
			MobileMenu.Add ( Enum.CalendarMenuNewProject (), Output.Project () );
		endif;
	endif;

EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|DetailByDay press PeriodDetail = Enum.Intervals.ByDay;
	|DetailByWeeks press PeriodDetail = Enum.Intervals.ByWeeks;
	|DetailByMonthVertical press PeriodDetail = Enum.Intervals.ByMonthsVertical;
	|DetailByMonthHorizontal DetailByMonthHorizontalMobile press PeriodDetail = Enum.Intervals.ByMonthsHorizontal;
	|ProjectFilter Projects show ProjectsAccess;
	|ShowProjects ShowProjectsMobile show ProjectsAccess and not SelectionMode;
	|ShowProjects ShowProjectsMobile press ShowProjects;
	|ShowPanel press ShowPanel and not MobileClient;
	|Calendar Settings show ( ShowPanel or MobileClient );
	|ShowPayments ShowPaymentsMobile press ShowPayments;
	|ShowVendorPayments ShowVendorPaymentsMobile press ShowVendorPayments;
	|ShowSalesOrders ShowSalesOrdersMobile press ShowSalesOrders;
	|ShowPurchaseOrders ShowPurchaseOrdersMobile press ShowPurchaseOrders;
	|ShowCompleted ShowCompleted1 ShowCompleted2 ShowCompleted3 ShowCompletedMobile press ShowCompleted;
	|PlannerCommands show not MobileClient;
	|GroupNavigationMobile show MobileClient;
	|CreateTask CreateTask1 CreateTask2 CreateEntry CreateEntry1 CreateEntry2 CreateCommand CreateCommand1 CreateCommand2 CreateProject CreateProject1 CreateProject2 NewCalendar OpenWorkLog OpenWorkLog1 OpenWorkLog2 OpenProjectAnalysis OpenProjectAnalysis1 OpenProjectAnalysis2 show not SelectionMode;
	|ShowRooms ShowRoomsMobile show RoomsAccess and not SelectionMode;
	|ShowRooms ShowRoomsMobile press ShowRooms;
	|GroupCustomers GroupPerformers GroupProjects GroupSections GroupUserTasks Customers Performers Projects Sections disable ShowRooms;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadParams ()
	
	SelectionMode = Parameters.SelectionMode;
	if ( SelectionMode ) then
		SelectionFilter = Parameters.Filter;
		SelectionSource = Parameters.Source;
		CalendarDate = Parameters.SelectionDate;
		if ( TypeOf ( SelectionFilter ) = Type ( "CatalogRef.Rooms" ) ) then
			ShowRooms = true;
		endif;
	endif;
	
EndProcedure

&AtServer
Procedure adjustMobile ()
	
	if ( MobileClient ) then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
		// Bug workaround for mobile client 8.3.14
		// The following control needs to be disabled
		// in order to prevent framework to crash
		Items.SearchTasks.Visible = false;
	endif;
	
EndProcedure

&AtServer
Procedure initDialogTypes ()
	
	types = Metadata.AccumulationRegisters.Debts.Dimensions.Document.Type.Types ();
	for each type in Metadata.AccumulationRegisters.VendorDebts.Dimensions.Document.Type.Types () do
		types.Add ( type );
	enddo;
	types.Add ( Type ( "BusinessProcessRef.Command" ) );
	EditInDialog = new TypeDescription ( types );
	
EndProcedure

&AtServer
Procedure readAccess ()
	
	ProjectsAccess = AccessRight ( "View", Metadata.Catalogs.Projects );
	RoomsAccess = AccessRight ( "View", Metadata.Documents.Meeting );
	EventsAccess = AccessRight ( "View", Metadata.Documents.Event );
	
EndProcedure

&AtServer
Procedure filterRerformers ()
	
	list = getFilter ( Performers );
	if ( list = undefined ) then
		list = new Array ();
		list.Add ( SessionParameters.User );
	endif;
	DC.ChangeFilter ( UserTasks, "Performer", list, true );
	DC.ChangeFilter ( Meetings, "Members.Member", list, true );
	DC.ChangeFilter ( Events, "Responsible", list, true );

EndProcedure

&AtServer
Procedure filterCustomers ()
	
	list = getFilter ( Customers );
	DC.ChangeFilter ( Events, "Organization", list, list <> undefined );
	
EndProcedure

&AtClientAtServerNoContext
Function getFilter ( List )
	
	result = new Array ();
	for each item in List do
		if ( item.Check ) then
			result.Add ( item.Value );
		endif;
	enddo;
	return ? ( result.Count () = 0, undefined, result );
	
EndFunction

&AtServer
Procedure filterCompleted ()
	
	hide = not ShowCompleted;
	DC.ChangeFilter ( UserTasks, "Executed", false, hide );
	DC.ChangeFilter ( Events, "Status", Enums.EventStatuses.Scheduled, hide );
	DC.ChangeFilter ( Meetings, "Completed", false, hide );
	DC.ChangeFilter ( Meetings, "Canceled", false, hide );
	
EndProcedure

&AtServer
Procedure setLayoutByDefault ()
	
	if ( SelectionMode ) then
		PeriodDetail = Enums.Intervals.ByDay;
	else
		PeriodDetail = Enums.Intervals.ByWeeks;
	endif;
	ShowWeekend = true;
	TimeScale = 15;
	TimeScaleLocation = Enums.TimeScale.Default;
	currentObject = FormAttributeToValue ( "Object" );
	colorsTemplate = currentObject.GetTemplate ( "Colors" );
	LeftSideBackColor = colorsTemplate.Areas.LeftSideBackColor.BackColor;
	HoursColor = colorsTemplate.Areas.HoursColor.BackColor;
	GridBackColor = colorsTemplate.Areas.GridBackColor.BackColor;
	HeaderBackColor = colorsTemplate.Areas.HeaderBackColor.BackColor;
	HeaderColor = colorsTemplate.Areas.HeaderColor.BackColor;
	CurrentDayColor = colorsTemplate.Areas.CurrentDayColor.BackColor;
	DaysOffColor = colorsTemplate.Areas.DaysOffColor.BackColor;
	GridBorderColor = colorsTemplate.Areas.GridBorderColor.BackColor;
	CompletedTaskColor = colorsTemplate.Areas.CompletedTasksColor.BackColor;
	ContentFont = colorsTemplate.Areas.ContentFont.Font;
	serializeColors ( ThisObject );
	Schedule = Application.Schedule ();
	CurrentUser = SessionParameters.User;
	FingerScroll = false;
	FontSize = 0;
	applyFont ( ThisObject, FontSize );
	
EndProcedure 

&AtClientAtServerNoContext
Procedure applyFont ( Form, FontSize )
	
	if ( not Form.MobileClient ) then
		return;
	endif;
	if ( FontSize = 0 ) then
		Form.Planner.Font = new Font ( , 5 );
	elsif ( FontSize = 1 ) then
		Form.Planner.Font = new Font ( , 7 );
	elsif ( FontSize = 2 ) then
		Form.Planner.Font = new Font ( , 9 );
	endif;
	
EndProcedure

&AtServer
Procedure serializeColors ( Set )
	
	Set [ "LeftSideBackColorSerialized" ] = XMLString ( new ValueStorage ( LeftSideBackColor ) );
	Set [ "CurrentDayColorSerialized" ] = XMLString ( new ValueStorage ( CurrentDayColor ) );
	Set [ "DaysOffColorSerialized" ] = XMLString ( new ValueStorage ( DaysOffColor ) );
	Set [ "CompletedTaskColorSerialized" ] = XMLString ( new ValueStorage ( CompletedTaskColor ) );
	Set [ "HeaderBackColorSerialized" ] = XMLString ( new ValueStorage ( HeaderBackColor ) );
	Set [ "HeaderColorSerialized" ] = XMLString ( new ValueStorage ( HeaderColor ) );
	Set [ "HoursColorSerialized" ] = XMLString ( new ValueStorage ( HoursColor ) );
	Set [ "GridBackColorSerialized" ] = XMLString ( new ValueStorage ( GridBackColor ) );
	Set [ "GridBorderColorSerialized" ] = XMLString ( new ValueStorage ( GridBorderColor ) );
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setWeekInfo ( Form )
	
	info = Diary.GetWeekInfo ( Form.Schedule );
	Form.WeekStart = info.WeekStart;
	Form.DayOff1 = info.DayOff1;
	Form.DayOff2 = info.DayOff2;
	start = info.Start;
	Form.TimeStart = Hour ( start );
	finish = info.Finish;
	Form.TimeEnd = Hour ( finish ) + ? ( Minute ( finish ) > 0, 1, 0 );
	Form.PreciseTimeStart = start - BegOfDay ( start );
	Form.PreciseTimeEnd = finish - BegOfDay ( finish );
	
EndProcedure 

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer ( Settings )
	
	restoreSettings ( Settings );
	if ( SelectionMode ) then
		disarmSettings ( Settings );
	endif;
	
EndProcedure

&AtServer
Procedure restoreSettings ( Settings )
	
	storedSettings = CommonSettingsStorage.Load ( Enum.SettingsCalendarSettings () );
	if ( storedSettings <> undefined ) then
		for each item in storedSettings do
			Settings [ item.Key ] = item.Value;
		enddo; 
	endif; 
	
EndProcedure

&AtServer
Procedure disarmSettings ( Settings )
	
	Settings.Delete ( "ShowPanel" );
	Settings.Delete ( "ShowPurchaseOrders" );
	Settings.Delete ( "ShowCompleted" );
	Settings.Delete ( "ShowProjects" );
	Settings.Delete ( "ShowRooms" );
	Settings.Delete ( "ShowPayments" );
	Settings.Delete ( "ShowVendorPayments" );
	Settings.Delete ( "ShowSalesOrders" );
	Settings.Delete ( "PeriodDetail" );
		
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer ( Settings )
	
	if ( SelectionMode ) then
		disarmFilters ();
		filterParameter ();
	endif;
	filterRerformers ();
	filterCustomers ();
	filterCompleted ();
	filterBySections ();
	deserializeColors ();
	setWeekInfo ( ThisObject );
	applyFont ( ThisObject, FontSize );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure disarmFilters ()
	
	Customers.FillChecks ( false );
	Sections.FillChecks ( false );
	Projects.FillChecks ( false );
	Performers.FillChecks ( false );
	Rooms.FillChecks ( false );
	
EndProcedure

&AtServer
Procedure filterParameter ()
	
	type = TypeOf ( SelectionFilter );
	if ( type = Type ( "CatalogRef.Users" ) ) then
		control = Performers;
	elsif ( type = Type ( "CatalogRef.Rooms" ) ) then
		control = Rooms;
	else
		return;
	endif;
	updateFilter ( SelectionFilter, control );
	
EndProcedure

&AtServer
Procedure filterBySections ()
	
	list = getFilter ( Sections );
	DC.ChangeFilter ( UserTasks, "Section", ? ( list = undefined, Catalogs.Sections.EmptyRef (), list ), true );
	
EndProcedure 

&AtServer
Procedure deserializeColors ()
	
	LeftSideBackColor = Colors.Deserialize ( LeftSideBackColorSerialized );
	HoursColor = Colors.Deserialize ( HoursColorSerialized );
	GridBackColor = Colors.Deserialize ( GridBackColorSerialized );
	HeaderBackColor = Colors.Deserialize ( HeaderBackColorSerialized );
	HeaderColor = Colors.Deserialize ( HeaderColorSerialized );
	CurrentDayColor = Colors.Deserialize ( CurrentDayColorSerialized );
	DaysOffColor = Colors.Deserialize ( DaysOffColorSerialized );
	CompletedTaskColor = Colors.Deserialize ( CompletedTaskColorSerialized );
	GridBorderColor = Colors.Deserialize ( GridBorderColorSerialized );
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	init ();
	adjustCalendarDate ();
	setAppearance ();
	fillCalendar ();
	AttachIdleHandler ( "showWeekendTip", 3, true );
	AttachIdleHandler ( "fillCalendar", 180, false );
	
EndProcedure

&AtClient
Procedure init ()
	
	AccessRights = new Map ();
	WarningColor = new Color ( 255, 0, 0 );
	PastTimeColor = new Color ( 220, 220, 220 );
	EditingObjects = new Array ();
	ShowProjects = ShowProjects and ProjectsAccess;
	ShowRooms = ShowRooms and RoomsAccess;
	locale = language ();
	if ( Framework.VersionLess ( "8.3.17" ) ) then
		#if ( WebClient ) then
			Planner.TimeScaleWrapHeadersFormat = locale + ";DF='ddd, dd/MM'";
		#else
			Planner.WrappedTimeScaleHeaderFormat = locale + ";DF='ddd, dd/MM'";
		#endif
	else
		Planner.WrappedTimeScaleHeaderFormat = locale + ";DF='ddd, dd/MM'";
	endif;

EndProcedure

&AtClient
Procedure adjustCalendarDate ()
	
	if ( CalendarDate = Date ( 1, 1, 1 ) ) then
		CalendarDate = SessionDate ( CurrentDate () );
	endif; 
	if ( PeriodDetail = PredefinedValue ( "Enum.Intervals.ByDay" ) ) then
		CalendarDate = BegOfDay ( CalendarDate );
	elsif ( PeriodDetail = PredefinedValue ( "Enum.Intervals.ByMonthsHorizontal" )
		or PeriodDetail = PredefinedValue ( "Enum.Intervals.ByMonthsVertical" ) ) then
		CalendarDate = BegOfMonth ( CalendarDate );
	elsif ( PeriodDetail = PredefinedValue ( "Enum.Intervals.ByWeeks" ) ) then
		CalendarDate = getBegOfWeek ();
	endif; 
	
EndProcedure 

&AtClient
Function getBegOfWeek ()
	
	weekDay = WeekDay ( CalendarDate );
	if ( weekDay > WeekStart ) then
		return dayAdd ( CalendarDate, - ( weekDay - WeekStart ) );
	elsif ( weekDay < WeekStart ) then
		return dayAdd ( CalendarDate, -7 + ( WeekStart - weekDay ) );
	else
		return CalendarDate;
	endif; 
	
EndFunction 

&AtClient
Function dayAdd ( DateFrom, Count = 1 )
	
	nextDate = DateFrom + Count * 86400;
	nextHour = Hour ( nextDate );
	if ( nextHour = Hour ( DateFrom ) ) then
		return nextDate;
	elsif ( nextHour = Hour ( DateFrom - 3600 ) ) then
		return nextDate + 3600;
	else
		return nextDate - 3600;
	endif; 
	
EndFunction 

&AtServer
Procedure setAppearance ()
	
	Planner.BackColor = GridBackColor;
	Planner.BorderColor = GridBorderColor;
	Planner.LineColor = GridBorderColor;
	Planner.TextColor = HoursColor;
	timetable = Planner.TimeScale.Items [ 0 ];
	timetable.BackColor = LeftSideBackColor;
	timetable.TextColor = HoursColor;
	timetable.LineColor = GridBorderColor;
	
EndProcedure

&AtClient
Procedure fillCalendar ()
	
	initPeriod ();
	params = getParams ();
	data = getData ( params );
	ShowPerformers = data.ShowPerformers;
	Holidays = data.Holidays;
	resetPlanner ( data );
	if ( ShowProjects ) then
		outputProjects ( data );
	elsif ( ShowRooms ) then
		outputRooms ( data );
	else
		outputTasks ( data );
		outputCommands ( data );
		outputEntries ( data );
		outputEvents ( data );
		outputMeetings ( data );
		if ( not data.FilterPerformers ) then
			newTabloid ();
			if ( ShowPayments ) then
				outputPayments ( data.Colors [ data.PaymentsColor ], data.Payments );
			endif;
			if ( ShowVendorPayments ) then
				outputPayments ( data.Colors [ data.VendorPaymentsColor ], data.VendorPayments );
			endif;
			if ( ShowSalesOrders ) then
				outputOrders ( data.Colors [ data.SalesOrdersColor ], data.SalesOrders, PictureLib.SalesOrder );
			endif;
			if ( ShowPurchaseOrders ) then
				outputOrders ( data.Colors [ data.PurchaseOrdersColor ], data.PurchaseOrders, PictureLib.Truck );
			endif;
			deleteTabloid ();
		endif;
	endif;
	drawCalendar ();
	titleCalendar ();
	
EndProcedure

&AtClient
Procedure initPeriod ()
	
	if ( PeriodDetail = PredefinedValue ( "Enum.Intervals.ByDay" ) ) then
		DateStart = CalendarDate;
		DateEnd = CalendarDate;
	elsif ( PeriodDetail = PredefinedValue ( "Enum.Intervals.ByWeeks" ) ) then
		DateStart = getBegOfWeek ();
		DateEnd = DateStart + 6 * 86400;
	elsif ( PeriodDetail = PredefinedValue ( "Enum.Intervals.ByMonthsHorizontal" ) ) then
		DateStart = CalendarDate;
		DateEnd = EndOfMonth ( CalendarDate );
	elsif ( PeriodDetail = PredefinedValue ( "Enum.Intervals.ByMonthsVertical" ) ) then
		DateStart = getBegOfWeek ();
		DateEnd = EndOfMonth ( CalendarDate );
		weekEnd = ? ( WeekStart = 1, 7, WeekStart + 6 - 7 );
		day = WeekDay ( DateEnd );
		if ( day = weekEnd ) then
			addition = 0;
		elsif ( day < weekEnd ) then
			addition = weekEnd - day;
		else
			addition = 7 - ( day - weekEnd );
		endif;
		DateEnd = DateEnd + addition * 86400;
	endif; 
	DateEnd = EndOfDay ( DateEnd );
	
EndProcedure 

&AtClient
Function getParams ()
	
	p = new Structure ();
	p.Insert ( "DateStart", DateStart );
	p.Insert ( "DateEnd", DateEnd );
	p.Insert ( "Schedule", Schedule );
	p.Insert ( "PeriodDetail", PeriodDetail );
	p.Insert ( "ShowProjects", ShowProjects );
	p.Insert ( "ShowRooms", ShowRooms );
	p.Insert ( "ShowPayments", ShowPayments );
	p.Insert ( "ShowSalesOrders", ShowSalesOrders );
	p.Insert ( "ShowPurchaseOrders", ShowPurchaseOrders );
	p.Insert ( "ShowVendorPayments", ShowVendorPayments );
	p.Insert ( "ShowCompleted", ShowCompleted );
	p.Insert ( "Customers", getFilter ( Customers ) );
	p.Insert ( "Sections", getFilter ( Sections ) );
	p.Insert ( "Performers", getFilter ( Performers ) );
	p.Insert ( "Projects", getFilter ( Projects ) );
	p.Insert ( "Rooms", getFilter ( Rooms ) );
	p.Insert ( "RoomsAccess", RoomsAccess );
	p.Insert ( "EventsAccess", EventsAccess );
	return p;
	
EndFunction 

&AtServerNoContext
Function getData ( val Params )
	
	env = initEnv ( Params );
	if ( Env.ShowPerformers ) then
		sqlPerformers ( env );
	endif;
	if ( Params.ShowProjects ) then
		sqlProjects ( env, Params );
	elsif ( Params.ShowRooms ) then
		sqlRooms ( env, Params );
	else
		sqlTasks ( env, Params );
		sqlCommands ( env );
		sqlTimeEntries ( env, Params );
		sqlMeetings ( env, Params );
		sqlEvents ( env, Params );
		if ( not env.FilterPerformers ) then
			if ( Params.ShowPayments ) then
				sqlPayments ( env, Params );
			endif;
			if ( Params.ShowVendorPayments ) then
				sqlVendorPayments ( env, Params );
			endif;
			if ( Params.ShowSalesOrders ) then
				sqlSalesOrders ( env, Params );
			endif;
			if ( Params.ShowPurchaseOrders ) then
				sqlPurchaseOrders ( env, Params );
			endif;
		endif;
	endif;
	Diary.SqlHolidays ( env );
	sqlAppearance ( env );
	SQL.Perform ( env );
	result = completeResult ( env, Params );
	return result;

EndFunction

&AtServerNoContext
Function initEnv ( Params )
	
	env = new Structure ();
	SQL.Init ( env );
	q = Env.Q;
	q.SetParameter ( "DateStart", BegOfDay ( Params.DateStart ) );
	q.SetParameter ( "DateEnd", EndOfDay ( Params.DateEnd ) );
	q.SetParameter ( "CurrentDate", CurrentSessionDate () );
	q.SetParameter ( "Schedule", Params.Schedule );
	q.SetParameter ( "Customers", Params.Customers );
	q.SetParameter ( "Projects", Params.Projects );
	q.SetParameter ( "Sections", Params.Sections );
	q.SetParameter ( "Rooms", Params.Rooms );
	me = SessionParameters.User;
	q.SetParameter ( "Me", me );
	performers = Params.Performers;
	if ( performers = undefined ) then
		performers = new Array ();
		performers.Add ( me );
		env.Insert ( "ShowPerformers", false );
		env.Insert ( "FilterPerformers", false );
	else
		count = performers.Count ();
		env.Insert ( "ShowPerformers", count > 1 );
		env.Insert ( "FilterPerformers", count > 0 );
	endif;
	q.SetParameter ( "Performers", performers );
	return env;
	
EndFunction

&AtServerNoContext
Procedure sqlPerformers ( Env )
	
	s = "
	|// #Performers
	|select Users.Ref as Ref, Users.Code as Code
	|from Catalog.Users as Users
	|where Users.Ref in ( &Performers )
	|order by Users.Code
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServerNoContext
Procedure sqlProjects ( Env, Params )
	
	performers = Params.Performers <> undefined;
	s = "
	|// #Projects
	|select allowed distinct top 100 Projects.Ref as Ref, Projects.DateStart as DateStart,
	|	endofperiod ( Projects.DateEnd, day ) as DateEnd, Projects.Appearance.Code as Appearance,
	|	Projects.Description as Description, Projects.Owner.Description as Customer,
	|	case when Projects.DateEnd < &CurrentDate then true else false end as Exceeded
	|";
	if ( performers ) then
		s = s + ", Users.Ref as Performer";
	endif;
	s = s + "
	|from Catalog.Projects as Projects
	|";
	if ( performers ) then
		s = s + "
		|//
		|// Filter by Performer
		|//
		|join Catalog.Projects.Tasks as Performers
		|on Performers.Employee in ( select Employee from Catalog.Users where Ref in ( &Performers ) )
		|and Performers.Ref = Projects.Ref
		|//
		|// Users
		|//
		|join Catalog.Users as Users
		|on Users.Employee = Performers.Employee
		|";
	endif;
	s = s + "
	|where not Projects.DeletionMark
	|and not Projects.Completed
	|and ( Projects.DateStart between &DateStart and &DateEnd
	|	or Projects.DateEnd between &DateStart and &DateEnd
	|	or ( Projects.DateStart < &DateStart and Projects.DateEnd > &DateEnd ) )
	|and Projects.DateStart <> datetime ( 1, 1, 1 )
	|and Projects.DateEnd <> datetime ( 1, 1, 1 )
	|";
	if ( Params.Customers <> undefined ) then
		s = s + "
		|and Projects.Owner in ( &Customers )
		|";
	endif;
	if ( Params.Projects <> undefined ) then
		s = s + "
		|and Projects.Ref in ( &Projects )
		|";
	endif;
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServerNoContext
Procedure sqlRooms ( Env, Params )
	
	roomsFilter = Params.Rooms <> undefined;
	s = "
	|// #Rooms
	|select Rooms.Ref as Ref, Rooms.Code as Code
	|from Catalog.Rooms as Rooms
	|where not Rooms.DeletionMark
	|";
	if ( roomsFilter ) then
		s = s + "
		|and Rooms.Ref in ( &Rooms )
		|";
	endif;
	s = s + "
	|order by Rooms.Code
	|;
	|// #Meetings
	|select allowed top 100 Meetings.Ref as Ref, Meetings.Start as DateStart, Meetings.Finish as DateEnd,
	|	Meetings.Color.Code as Appearance, Meetings.Duration as Duration, Meetings.Room as Room,
	|	Meetings.Subject as Subject, Meetings.Completed as Completed
	|from Document.Meeting as Meetings
	|where not Meetings.DeletionMark
	|and Meetings.Formed
	|";
	if ( not Params.ShowCompleted ) then
		s = s + "and not Meetings.Completed
		|and not Meetings.Canceled";
	endif;
	s = s + "
	|and ( Meetings.Start between &DateStart and &DateEnd
	|	or Meetings.Finish between &DateStart and &DateEnd
	|	or ( Meetings.Start < &DateStart and Meetings.Finish > &DateEnd ) )
	|";
	if ( roomsFilter ) then
		s = s + "
		|and Meetings.Room in ( &Rooms )
		|";
	endif;
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServerNoContext
Procedure sqlTasks ( Env, Params )
	
	s = "
	|// #Tasks
	|select allowed top 100 Tasks.Ref as Ref, Tasks.Start as DateStart, Tasks.Finish as DateEnd,
	|	Tasks.Appearance.Code as Appearance, Tasks.Duration as Duration, Tasks.Performer as Performer,
	|	case when Tasks.BusinessProcess = value ( BusinessProcess.Command.EmptyRef ) then false else true end Command,
	|	cast ( Tasks.Memo as String ( 100 ) ) as Description, Tasks.Executed as Executed,
	|	case
	|		when Tasks.Finish < &CurrentDate
	|			or isnull ( Tasks.BusinessProcess.Finish, datetime ( 3999, 12, 31 ) ) < Tasks.Finish then true
	|		else false
	|	end as Exceeded
	|from Task.UserTask as Tasks
	|where not Tasks.DeletionMark
	|and ( Tasks.Start between &DateStart and &DateEnd
	|	or Tasks.Finish between &DateStart and &DateEnd
	|	or ( Tasks.Start < &DateStart and Tasks.Finish > &DateEnd ) )
	|and Tasks.Performer in ( &Performers )
	|";
	if ( not Params.ShowCompleted ) then
		s = s + "and not Tasks.Executed";
	endif;
	sections = Params.Sections;
	if ( sections = undefined ) then
		s = s + "
		|and ( Tasks.Section = value ( Catalog.Sections.EmptyRef )
		|";
	else
		s = s + "
		|and ( Tasks.Section in ( &Sections )
		|";
	endif;
	if ( manyPerformers ( Params.Performers ) ) then
		s = s + "
		|	or Tasks.Section.Owner <> &Me
		|";
	endif;
	s = s + ")
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServerNoContext
Function manyPerformers ( Performers )
	
	return Performers <> undefined
	and ( Performers.Find ( SessionParameters.User ) = undefined
		or Performers.Count () > 1 );
	
EndFunction

&AtServerNoContext
Procedure sqlCommands ( Env )
	
	s = "
	|// #Commands
	|select allowed top 100 Commands.Ref as Ref, dateadd ( Commands.Finish, hour, -1 ) as DateStart,
	|	Commands.Finish as DateEnd, Commands.Appearance.Code as Appearance, Commands.Creator as Performer,
	|	Commands.Description as Description,
	|	case when Commands.Finish < &CurrentDate then true else false end as Exceeded
	|from BusinessProcess.Command as Commands
	|where not Commands.DeletionMark
	|and not Commands.Completed
	|and Commands.Started
	|and Commands.Finish between &DateStart and &DateEnd
	|and Commands.Creator = &Me
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServerNoContext
Procedure sqlTimeEntries ( Env, Params )
	
	s = "
	|// #TimeEntries
	|select allowed top 300 Tasks.Ref as Ref, Tasks.Description as Description,
	|	case when Tasks.TimeStart = datetime ( 1, 1, 1 ) then Tasks.Ref.Date
	|		else dateadd ( beginofperiod ( Tasks.Ref.Date, day ), minute, hour ( Tasks.TimeStart ) * 60 + minute ( Tasks.TimeStart ) ) 
	|	end as DateStart,
	|	case when Tasks.TimeEnd = datetime ( 1, 1, 1 ) then endofperiod ( Tasks.Ref.Date, day )
	|		else dateadd ( beginofperiod ( Tasks.Ref.Date, day ), minute, hour ( Tasks.TimeEnd ) * 60 + minute ( Tasks.TimeEnd ) ) 
	|	end as DateEnd,
	|	Tasks.Ref.Appearance.Code as Appearance, Tasks.Duration as Duration, Tasks.Ref.Performer as Performer,
	|	Tasks.Ref.Customer.Description as Customer, Tasks.Ref.Project.Description as Project
	|from Document.TimeEntry.Tasks as Tasks
	|where Tasks.Ref.Posted
	|and Tasks.Ref.Date between &DateStart and &DateEnd
	|";
	customersFilter = Params.Customers <> undefined;
	if ( customersFilter ) then
		s = s + "
		|and Tasks.Ref.Customer in ( &Customers )
		|";
	endif;
	performers = Params.Performers;
	if ( performers = undefined ) then
		if ( not customersFilter ) then
			s = s + "
			|and Tasks.Ref.Performer = &Me
			|";
		endif;
	else
		s = s + "
		|and Tasks.Ref.Performer in ( &Performers )
		|";
	endif;
	if ( Params.Projects <> undefined ) then
		s = s + "
		|and Tasks.Ref.Project in ( &Projects )
		|";
	endif;
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServerNoContext
Procedure sqlMeetings ( Env, Params )
	
	if ( not Params.RoomsAccess ) then
		return;
	endif;
	s = "
	|// #Meetings
	|select allowed top 100 Members.Ref as Ref, Members.Ref.Start as DateStart, Members.Ref.Finish as DateEnd,
	|	Members.Ref.Color.Code as Appearance, Members.Ref.Duration as Duration, Members.Member as Performer,
	|	Members.Ref.Subject as Subject, Members.Ref.Completed as Completed
	|from Document.Meeting.Members as Members
	|where not Members.Ref.DeletionMark
	|and Members.Ref.Formed
	|";
	if ( not Params.ShowCompleted ) then
		s = s + "and not Members.Ref.Completed"
	endif;
	s = s + "
	|and ( Members.Ref.Start between &DateStart and &DateEnd
	|	or Members.Ref.Finish between &DateStart and &DateEnd
	|	or ( Members.Ref.Start < &DateStart and Members.Ref.Finish > &DateEnd ) )
	|";
	performers = Params.Performers;
	if ( performers = undefined ) then
		s = s + "
		|and Members.Member = &Me
		|";
	else
		s = s + "
		|and Members.Member in ( &Performers )
		|";
	endif;
	if ( Params.Rooms <> undefined ) then
		s = s + "
		|and Members.Ref.Room in ( &Rooms )
		|";
	endif;
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServerNoContext
Procedure sqlEvents ( Env, Params )
	
	if ( not Params.EventsAccess ) then
		return;
	endif;
	s = "
	|// #Events
	|select allowed top 100 Events.Ref as Ref, Events.Start as DateStart, Events.Finish as DateEnd,
	|	Events.Color.Code as Appearance, Events.Duration as Duration, Events.Responsible as Performer,
	|	Events.Subject as Subject, Events.Status <> value ( Enum.EventStatuses.Scheduled ) as Completed,
	|	case Events.Severity
	|		when value ( Enum.Severity.Medium ) then 1
	|		when value ( Enum.Severity.High ) then 2
	|		else 0
	|	end as Severity
	|from Document.Event as Events
	|where not Events.DeletionMark
	|";
	if ( not Params.ShowCompleted ) then
		s = s + "and Events.Status = value ( Enum.EventStatuses.Scheduled )"
	endif;
	s = s + "
	|and ( Events.Start between &DateStart and &DateEnd
	|	or Events.Finish between &DateStart and &DateEnd
	|	or ( Events.Start < &DateStart and Events.Finish > &DateEnd ) )
	|";
	if ( Params.Customers <> undefined ) then
		s = s + "
		|and Events.Organization in ( &Customers )
		|";
	endif;
	performers = Params.Performers;
	if ( performers = undefined ) then
		s = s + "
		|and Events.Responsible = &Me
		|";
	else
		s = s + "
		|and Events.Responsible in ( &Performers )
		|";
	endif;
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServerNoContext
Procedure sqlPayments ( Env, Params )
	
	s = "
	|// @PaymentsColor
	|select Colors.Code as Code
	|from Catalog.CalendarAppearance as Colors
	|where Colors.Ref = value ( Catalog.CalendarAppearance.Payments )
	|;
	|// #Payments
	|select allowed Balances.Contract.Owner as Organization, Balances.PaymentBalance as Amount,
	|	Balances.Contract.Currency as Currency, Balances.Document as Document, Details.Date as Date
	|from AccumulationRegister.Debts.Balance ( ,";
	if ( Params.Customers <> undefined ) then
		s = s + "
		|Contract.Owner in ( &Customers )
		|";
	endif;
	s = s + " ) as Balances
	|	//
	|	// PaymentDetails
	|	//
	|	join InformationRegister.PaymentDetails as Details
	|	on Details.PaymentKey = Balances.PaymentKey
	|	//
	|	// Filter by allowed contracts
	|	//
	|	join Catalog.Contracts as Contracts
	|	on Contracts.Ref = Balances.Contract
	|";
	if ( Params.Customers <> undefined ) then
		s = s + "
		|and Contracts.Owner in ( &Customers )
		|";
	endif;
	s = s + "
	|where Balances.PaymentBalance > 0
	|and Details.Date between &DateStart and &DateEnd
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServerNoContext
Procedure sqlVendorPayments ( Env, Params )
	
	s = "
	|// @VendorPaymentsColor
	|select Colors.Code as Code
	|from Catalog.CalendarAppearance as Colors
	|where Colors.Ref = value ( Catalog.CalendarAppearance.VendorPayments )
	|;
	|// #VendorPayments
	|select allowed Balances.Contract.Owner as Organization, Balances.PaymentBalance as Amount,
	|	Balances.Contract.Currency as Currency, Balances.Document as Document, Details.Date as Date
	|from AccumulationRegister.VendorDebts.Balance as Balances
	|	//
	|	// PaymentDetails
	|	//
	|	join InformationRegister.PaymentDetails as Details
	|	on Details.PaymentKey = Balances.PaymentKey
	|	//
	|	// Filter by allowed contracts
	|	//
	|	join Catalog.Contracts as Contracts
	|	on Contracts.Ref = Balances.Contract
	|where Balances.PaymentBalance > 0
	|and Details.Date between &DateStart and &DateEnd
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServerNoContext
Procedure sqlSalesOrders ( Env, Params )
	
	s = "
	|// @SalesOrdersColor
	|select Colors.Code as Code
	|from Catalog.CalendarAppearance as Colors
	|where Colors.Ref = value ( Catalog.CalendarAppearance.SalesOrders )
	|;
	|select allowed Balances.SalesOrder as Document, Balances.RowKey as RowKey
	|into Balances
	|from AccumulationRegister.SalesOrders.Balance ( ,";
	if ( Params.Customers <> undefined ) then
		s = s + "
		|SalesOrder.Customer in ( &Customers )
		|";
	endif;
	s = s + " ) as Balances
	|	//
	|	// Filter by allowed contracts
	|	//
	|	join Catalog.Contracts as Contracts
	|	on Contracts.Ref = Balances.SalesOrder.Contract
	|";
	if ( Params.Customers <> undefined ) then
		s = s + "
		|and Contracts.Owner in ( &Customers )
		|";
	endif;
	s = s + "
	|;
	|// #SalesOrders
	|select Balances.Document as Document, Balances.Document.Customer as Organization,
	|	cast ( Balances.Document.Memo as String ( 150 ) ) as Memo,
	|	case Items.DeliveryDate when datetime ( 1, 1, 1 ) then Balances.Document.DeliveryDate else Items.DeliveryDate end as Date
	|from Balances as Balances
	|	//
	|	// Items
	|	//
	|	join Document.SalesOrder.Items as Items
	|	on Items.Ref = Balances.Document
	|	and Items.RowKey = Balances.RowKey
	|where case Items.DeliveryDate when datetime ( 1, 1, 1 ) then Balances.Document.DeliveryDate else Items.DeliveryDate end between &DateStart and &DateEnd
	|union
	|select Balances.Document, Balances.Document.Customer,
	|	cast ( Balances.Document.Memo as String ( 150 ) ),
	|	case Services.DeliveryDate when datetime ( 1, 1, 1 ) then Balances.Document.DeliveryDate else Services.DeliveryDate end
	|from Balances as Balances
	|	//
	|	// Services
	|	//
	|	join Document.SalesOrder.Services as Services
	|	on Services.Ref = Balances.Document
	|	and Services.RowKey = Balances.RowKey
	|where case Services.DeliveryDate when datetime ( 1, 1, 1 ) then Balances.Document.DeliveryDate else Services.DeliveryDate end between &DateStart and &DateEnd
	|;
	|drop Balances
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServerNoContext
Procedure sqlPurchaseOrders ( Env, Params )
	
	s = "
	|// @PurchaseOrdersColor
	|select Colors.Code as Code
	|from Catalog.CalendarAppearance as Colors
	|where Colors.Ref = value ( Catalog.CalendarAppearance.PurchaseOrders )
	|;
	|select allowed Balances.PurchaseOrder as Document, Balances.RowKey as RowKey
	|into Balances
	|from AccumulationRegister.PurchaseOrders.Balance as Balances
	|	//
	|	// Filter by allowed contracts
	|	//
	|	join Catalog.Contracts as Contracts
	|	on Contracts.Ref = Balances.PurchaseOrder.Contract
	|;
	|// #PurchaseOrders
	|select Balances.Document as Document, Balances.Document.Vendor as Organization,
	|	cast ( Balances.Document.Memo as String ( 150 ) ) as Memo,
	|	case Items.DeliveryDate when datetime ( 1, 1, 1 ) then Balances.Document.DeliveryDate else Items.DeliveryDate end as Date
	|from Balances as Balances
	|	//
	|	// Items
	|	//
	|	join Document.PurchaseOrder.Items as Items
	|	on Items.Ref = Balances.Document
	|	and Items.RowKey = Balances.RowKey
	|where case Items.DeliveryDate when datetime ( 1, 1, 1 ) then Balances.Document.DeliveryDate else Items.DeliveryDate end between &DateStart and &DateEnd
	|union
	|select Balances.Document, Balances.Document.Vendor,
	|	cast ( Balances.Document.Memo as String ( 150 ) ),
	|	case Services.DeliveryDate when datetime ( 1, 1, 1 ) then Balances.Document.DeliveryDate else Services.DeliveryDate end
	|from Balances as Balances
	|	//
	|	// Services
	|	//
	|	join Document.PurchaseOrder.Services as Services
	|	on Services.Ref = Balances.Document
	|	and Services.RowKey = Balances.RowKey
	|where case Services.DeliveryDate when datetime ( 1, 1, 1 ) then Balances.Document.DeliveryDate else Services.DeliveryDate end between &DateStart and &DateEnd
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServerNoContext
Procedure sqlAppearance ( Env ) export
	
	s = "
	|// #CalendarAppearance
	|select CalendarAppearance.Code as Code, CalendarAppearance.Color as Color, CalendarAppearance.BackColor as BackColor
	|from Catalog.CalendarAppearance as CalendarAppearance
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServerNoContext
Function completeResult ( Env, Params )

	result = new Structure ();
	if ( Params.ShowProjects ) then
		result.Insert ( "Projects", CollectionsSrv.Serialize ( Env.Projects ) );
	elsif ( Params.ShowRooms ) then
		result.Insert ( "Rooms", CollectionsSrv.Serialize ( Env.Rooms ) );
		result.Insert ( "Meetings", CollectionsSrv.Serialize ( Env.Meetings ) );
	else
		result.Insert ( "Tasks", CollectionsSrv.Serialize ( Env.Tasks ) );
		result.Insert ( "Commands", CollectionsSrv.Serialize ( Env.Commands ) );
		result.Insert ( "TimeEntries", CollectionsSrv.Serialize ( Env.TimeEntries ) );
		if ( Params.RoomsAccess ) then
			result.Insert ( "Meetings", CollectionsSrv.Serialize ( Env.Meetings ) );
		endif;
		if ( Params.EventsAccess ) then
			result.Insert ( "Events", CollectionsSrv.Serialize ( Env.Events ) );
		endif;
		if ( not Env.FilterPerformers ) then
			if ( Params.ShowPayments ) then
				result.Insert ( "Payments", CollectionsSrv.Serialize ( Env.Payments ) );
				result.Insert ( "PaymentsColor", Env.PaymentsColor.Code );
			endif;
			if ( Params.ShowVendorPayments ) then
				result.Insert ( "VendorPayments", CollectionsSrv.Serialize ( Env.VendorPayments ) );
				result.Insert ( "VendorPaymentsColor", Env.VendorPaymentsColor.Code );
			endif;
			if ( Params.ShowSalesOrders ) then
				result.Insert ( "SalesOrders", CollectionsSrv.Serialize ( Env.SalesOrders ) );
				result.Insert ( "SalesOrdersColor", Env.SalesOrdersColor.Code );
			endif;
			if ( Params.ShowPurchaseOrders ) then
				result.Insert ( "PurchaseOrders", CollectionsSrv.Serialize ( Env.PurchaseOrders ) );
				result.Insert ( "PurchaseOrdersColor", Env.PurchaseOrdersColor.Code );
			endif;
		endif;
	endif;
	showPerformers = Env.ShowPerformers;
	if ( showPerformers ) then
		result.Insert ( "Performers", CollectionsSrv.Serialize ( Env.Performers ) );
	endif;
	result.Insert ( "ShowPerformers", showPerformers );
	result.Insert ( "FilterPerformers", Env.FilterPerformers );
	result.Insert ( "Holidays", Diary.ConvertHolidaysToMap ( Env ) );
	result.Insert ( "Colors", Diary.ColorsMap ( Env ) );
	return result;
	
EndFunction

&AtClient
Procedure resetPlanner ( Data )
	
	Planner.Items.Clear ();
	Planner.Dimensions.Clear ();
	if ( ShowRooms ) then
		dim = Planner.Dimensions.Add ( "Room" );
		dim.Text = Output.Room ();
		set = dim.Items;
		for each row in Collections.DeserializeTable ( Data.Rooms ) do
			item = set.Add ( row.Ref );
			item.Text = row.Code;
		enddo;
	elsif ( ShowPerformers ) then
		dim = Planner.Dimensions.Add ( "Performer" );
		dim.Text = Output.Performer ();
		set = dim.Items;
		for each row in Collections.DeserializeTable ( Data.Performers ) do
			item = set.Add ( row.Ref );
			item.Text = row.Code;
		enddo;
	endif;
	
EndProcedure

&AtClient
Procedure outputProjects ( Data )
	
	palette = Data.Colors;
	set = Collections.DeserializeTable ( Data.Projects );
	for each record in set do
		item = Planner.Items.Add ( record.DateStart, record.DateEnd );
		item.Value = record.Ref;
		item.Text = projectDescription ( record.Customer, record.Description );
		color = palette [ record.Appearance ];
		if ( color <> undefined ) then
			item.TextColor = color.Color;
			item.BackColor = color.BackColor;
		endif;
		if ( record.Exceeded ) then
			item.BorderColor = WarningColor;
		endif;
		item.Picture = PictureLib.Projects16;
		bindPerformer ( item, record );
	enddo;
	
EndProcedure

&AtClientAtServerNoContext
Function projectDescription ( Customer, Description )
	
	return Customer + ": " + Description;

EndFunction

&AtClient
Procedure outputRooms ( Data )
	
	palette = Data.Colors;
	entries = Collections.DeserializeTable ( Data.Meetings );
	picture = PictureLib.Meeting;
	pin = PictureLib.Pin;
	for each record in entries do
		item = Planner.Items.Add ( record.DateStart, record.DateEnd );
		color = palette [ record.Appearance ];
		ref = record.Ref;
		item.Value = ref;
		if ( ref = SelectionSource ) then
			item.Picture = pin;
		else
			item.Text = record.Subject;
			item.Picture = picture;
		endif;
		item.TextColor = color.Color;
		item.BackColor = color.BackColor;
		item.Font = ContentFont;
		map = new Map ();
		map.Insert ( "Room", record.Room );
		item.DimensionValues = new FixedMap ( map );
	enddo;
	
EndProcedure

&AtClient
Procedure outputTasks ( Data )
	
	palette = Data.Colors;
	entries = Collections.DeserializeTable ( Data.Tasks );
	task = PictureLib.UserTask;
	command = PictureLib.Horn;
	pin = PictureLib.Pin;
	for each record in entries do
		item = Planner.Items.Add ( record.DateStart, record.DateEnd );
		ref = record.Ref;
		item.Value = ref;
		if ( ref = SelectionSource ) then
			item.Picture = pin;
		else
			item.Text = record.Description;
			if ( record.Command ) then
				item.Picture = command;
			else
				item.Picture = task;
			endif;
		endif;
		color = palette [ record.Appearance ];
		item.TextColor = color.Color;
		item.BackColor = ? ( record.Executed, CompletedTaskColor, color.BackColor );
		item.Font = ContentFont;
		if ( record.Exceeded ) then
			item.BorderColor = WarningColor;
		endif;
		bindPerformer ( item, record );
	enddo;
	
EndProcedure

&AtClient
Procedure bindPerformer ( Item, Record )
	
	if ( not ShowPerformers ) then
		return;
	endif;
	performer = record.Performer;
	if ( not ValueIsFilled ( performer ) ) then
		return;
	endif;
	map = new Map ();
	map.Insert ( "Performer", performer );
	item.DimensionValues = new FixedMap ( map );

EndProcedure

&AtClient
Procedure outputCommands ( Data )
	
	palette = Data.Colors;
	entries = Collections.DeserializeTable ( Data.Commands );
	picture = PictureLib.Deadline;
	for each record in entries do
		item = Planner.Items.Add ( record.DateStart, record.DateEnd );
		item.Value = record.Ref;
		item.Text = record.Description;
		color = palette [ record.Appearance ];
		item.TextColor = color.Color;
		item.BackColor = color.BackColor;
		item.Font = ContentFont;
		item.Picture = picture;
		if ( record.Exceeded ) then
			item.BorderColor = WarningColor;
		endif;
		bindPerformer ( item, record );
	enddo;
	
EndProcedure

&AtClient
Procedure outputEntries ( Data )
	
	palette = Data.Colors;
	entries = Collections.DeserializeTable ( Data.TimeEntries );
	picture = PictureLib.TimeEntries;
	for each record in entries do
		item = Planner.Items.Add ( record.DateStart, record.DateEnd );
		item.Value = record.Ref;
		item.Text = "" + record.Customer + ", " + record.Project;
		item.ToolTip = "" + record.Performer + ? ( record.Description = "", "", ": " + record.Description );
		color = palette [ record.Appearance ];
		item.TextColor = color.Color;
		item.BackColor = color.BackColor;
		item.Font = ContentFont;
		item.Picture = picture;
		bindPerformer ( item, record );
	enddo;
	
EndProcedure

&AtClient
Procedure outputMeetings ( Data )
	
	if ( not RoomsAccess ) then
		return;
	endif;
	palette = Data.Colors;
	entries = Collections.DeserializeTable ( Data.Meetings );
	picture = PictureLib.Meeting;
	for each record in entries do
		item = Planner.Items.Add ( record.DateStart, record.DateEnd );
		item.Value = record.Ref;
		item.Text = record.Subject;
		item.Picture = picture;
		color = palette [ record.Appearance ];
		item.TextColor = color.Color;
		item.BackColor = ? ( record.Completed, CompletedTaskColor, color.BackColor );
		item.Font = ContentFont;
		bindPerformer ( item, record );
	enddo;
	
EndProcedure

&AtClient
Procedure outputEvents ( Data )
	
	if ( not EventsAccess ) then
		return;
	endif;
	palette = Data.Colors;
	entries = Collections.DeserializeTable ( Data.Events );
	low = PictureLib.GreenPin;
	medium = PictureLib.BluePin;
	high = PictureLib.RedPin;
	for each record in entries do
		item = Planner.Items.Add ( record.DateStart, record.DateEnd );
		item.Value = record.Ref;
		item.Text = record.Subject;
		severity = record.Severity;
		if ( severity = 1 ) then
			picture = medium;
		elsif ( severity = 2 ) then
			picture = high;
		else
			picture = low;
		endif;
		item.Picture = picture;
		color = palette [ record.Appearance ];
		item.TextColor = color.Color;
		item.BackColor = ? ( record.Completed, CompletedTaskColor, color.BackColor );
		item.Font = ContentFont;
		bindPerformer ( item, record );
	enddo;
	
EndProcedure

&AtClient
Procedure newTabloid ()
	
	Tabloid = new Map ();

EndProcedure

&AtClient
Procedure outputPayments ( Color, Table )
	
	entries = Collections.DeserializeTable ( Table );
	picture = PictureLib.Cash;
	step = tabloidStep ();
	for each record in entries do
		date = record.Date;
		time = getTabloid ( date );
		start = date + time;
		item = Planner.Items.Add ( start, start + step );
		item.Value = record.Document;
		item.Text = "" + record.Organization + ", " + Conversion.NumberToMoney ( record.Amount, record.Currency );
		item.Picture = picture;
		item.TextColor = Color.Color;
		item.BackColor = Color.BackColor;
		nextTabloid ( date );
	enddo;
	
EndProcedure

&AtClient
Function getTabloid ( Day )
	
	time = Tabloid [ Day ];
	if ( time = undefined
		or time > ( TimeEnd * Enum.Hours1 () - tabloidStep () ) ) then
		time = TimeStart * Enum.Hours1 ();
		Tabloid [ Day ] = time;
	endif;
	return time;
		
EndFunction

&AtClient
Function tabloidStep ()
	
	return Enum.Minutes30 ();
	
EndFunction

&AtClient
Procedure nextTabloid ( Day )
	
	Tabloid [ Day ] = Tabloid [ Day ] + tabloidStep ();

EndProcedure

&AtClient
Procedure outputOrders ( Color, Table, Picture )
	
	entries = Collections.DeserializeTable ( Table );
	step = tabloidStep ();
	for each record in entries do
		date = record.Date;
		time = getTabloid ( date );
		start = date + time;
		item = Planner.Items.Add ( start, start + step );
		item.Value = record.Document;
		item.Text = Conversion.ValuesToString ( "" + record.Organization, record.Memo );
		item.Picture = Picture;
		item.TextColor = Color.Color;
		item.BackColor = Color.BackColor;
		nextTabloid ( date );
	enddo;
	
EndProcedure

&AtClient
Procedure deleteTabloid ()
	
	Tabloid = undefined;
	
EndProcedure

&AtClient
Procedure drawCalendar ()
	
	if ( PeriodDetail = PredefinedValue ( "Enum.Intervals.ByMonthsVertical" ) ) then
		drawMonth ();
	else
		drawPeriod ();
		adjustHours ();
	endif;
	fillPeriod ();
	setTimeLocation ();
	setTimeScale ();
	
EndProcedure

&AtClient
Function adjustHours ()
	
	HourStart = TimeStart;
	HourEnd = TimeEnd;
	for each item in Planner.Items do
		start = item.Begin;
		finish = item.End;
		begin = Hour ( start );
		tillNextDay = EndOfDay ( start ) + 1 = finish;
		end = ? ( tillNextDay, 24, Hour ( finish ) );
		HourStart = Min ( HourStart, begin, end );
		HourEnd = Max ( HourEnd, begin + Min ( Minute ( start ), 1 ), end + Min ( Minute ( finish ), 1 ) );
	enddo;
	HourStart = Min ( TimeStart, HourStart );
	HourEnd = Max ( TimeEnd, HourEnd );
	return HourStart <> TimeStart
	or HourEnd <> TimeEnd;

EndFunction

&AtClient
Procedure drawMonth ()
	
	if ( Framework.VersionLess ( "8.3.17" ) ) then
		#if ( WebClient ) then
			Planner.ShowWrapHeaders = false;
			Planner.ShowTimeScaleWrapHeaders = true;
		#else
			Planner.ShowWrappedHeaders = false;
			Planner.ShowWrappedTimeScaleHeaders = true;
		#endif
	else
		Planner.ShowWrappedHeaders = false;
		Planner.ShowWrappedTimeScaleHeaders = true;
	endif;
	Planner.ItemsTimeRepresentation = PlannerItemsTimeRepresentation.DontDisplay;
	Planner.ShowCurrentDate = false;
	#if ( MobileClient ) then
		// Bug workaround: Mobile Client 8.3.13.45 draws planner incorrectly for other periodic variants
		Planner.PeriodicVariantRepetition = 7;
	#else
		Planner.PeriodicVariantRepetition = ? ( ShowWeekend, 7, 7 - Min ( DayOff1, 1 ) - Min ( DayOff2, 1 ) );
	#endif
	elements = Planner.TimeScale.Items;
	item = elements [ 0 ];
	item.Unit = TimeScaleUnitType.Day;
	item.Format = language () + ";DF='d MMM, ddd'";
	if ( elements.Count () = 2 ) then
		elements.Delete ( elements [ 1 ] );
	endif;
	
EndProcedure

&AtClient
Procedure drawPeriod ()
	
	if ( Framework.VersionLess ( "8.3.17" ) ) then
		#if ( WebClient ) then
			Planner.ShowWrapHeaders = true;
			Planner.ShowTimeScaleWrapHeaders = ( PeriodDetail = PredefinedValue ( "Enum.Intervals.ByMonthsHorizontal" ) );
		#else
			Planner.ShowWrappedHeaders = true;
			Planner.ShowWrappedTimeScaleHeaders = ( PeriodDetail = PredefinedValue ( "Enum.Intervals.ByMonthsHorizontal" ) );
		#endif
	else
		Planner.ShowWrappedHeaders = true;
		Planner.ShowWrappedTimeScaleHeaders = ( PeriodDetail = PredefinedValue ( "Enum.Intervals.ByMonthsHorizontal" ) );
	endif;
	if ( ShowProjects ) then
		Planner.ItemsTimeRepresentation = PlannerItemsTimeRepresentation.DontDisplay;
	else
		Planner.ItemsTimeRepresentation = PlannerItemsTimeRepresentation.BeginAndEndTime;
	endif;
	Planner.PeriodicVariantRepetition = 1;
	Planner.ShowCurrentDate = true;
	time = Planner.TimeScale;
	elements = time.Items;
	item = elements [ 0 ];
	item.Unit = TimeScaleUnitType.Hour;
	item.Format = Output.HourFormat ();
	if ( elements.Count () = 1 ) then
		time = elements.Add ();
		time.ShowPeriodicalLabels = false;
		time.Unit = TimeScaleUnitType.Minute;
	endif;

EndProcedure

&AtClient
Procedure fillPeriod ()
	
	intervals = Planner.CurrentRepresentationPeriods;
	intervals.Clear ();
	backgrounds = Planner.BackgroundIntervals;
	backgrounds.Clear ();
	day = DateStart;
	hideWeekend = not ShowWeekend and ( PeriodDetail <> PredefinedValue ( "Enum.Intervals.ByDay" ) );
	now = CurrentDate ();
	currentDay = BegOfDay ( now );
	wholeDay = PeriodDetail = PredefinedValue ( "Enum.Intervals.ByMonthsVertical" );
	while ( day < DateEnd ) do
		weekend = dayOff ( day );
		if ( hideWeekend
			and weekend ) then
		else
			if ( wholeDay ) then
				start = day;
				finish = day + 86399;
			else
				start = day + HourStart * 3600;
				finish = day + HourEnd * 3600 - 1;
			endif;
			intervals.Add ( start, finish );
			if ( day = currentDay ) then
				background = CurrentDayColor;
			elsif ( weekend ) then
				background = DaysOffColor;
			else
				holiday = Holidays [ day ];
				background = ? ( holiday = undefined, undefined, DaysOffColor );
			endif;
			if ( background <> undefined ) then
				interval = backgrounds.Add ( start, finish );
				interval.Color = background;
			endif;
		endif;
		day = day + 86400;
	enddo;
	if ( SelectionMode
		and DateStart < now ) then
		interval = backgrounds.Add ( Min ( DateStart, now ), Min ( DateEnd, now ) );
		interval.Color = PastTimeColor;
	endif;
	
EndProcedure

&AtClient
Function dayOff ( Day )
	
	weekDay = WeekDay ( Day );
	return weekDay = DayOff1
	or weekDay = DayOff2;
	
EndFunction

&AtClient
Procedure setTimeLocation ()
	
	time = Planner.TimeScale;
	if ( TimeScaleLocation.IsEmpty ()
		or TimeScaleLocation = PredefinedValue ( "Enum.TimeScale.Default" ) ) then
		if ( PeriodDetail = PredefinedValue ( "Enum.Intervals.ByMonthsVertical" ) ) then
			//@skip-warning
			time.Location = TimeScalePosition.Top;
		else
			if ( ShowProjects ) then
				//@skip-warning
				time.Location = TimeScalePosition.Top;
			else
				//@skip-warning
				time.Location = TimeScalePosition.Left;
			endif;
		endif;
	elsif ( TimeScaleLocation = PredefinedValue ( "Enum.TimeScale.Top" ) ) then
		//@skip-warning
		time.Location = TimeScalePosition.Top;
	elsif ( TimeScaleLocation = PredefinedValue ( "Enum.TimeScale.Bottom" ) ) then
		//@skip-warning
		time.Location = TimeScalePosition.Bottom;
	elsif ( TimeScaleLocation = PredefinedValue ( "Enum.TimeScale.Left" ) ) then
		//@skip-warning
		time.Location = TimeScalePosition.Left;
	elsif ( TimeScaleLocation = PredefinedValue ( "Enum.TimeScale.Right" ) ) then
		//@skip-warning
		time.Location = TimeScalePosition.Right;
	endif;
	
EndProcedure

&AtClient
Procedure setTimeScale ()
	
	if ( PeriodDetail <> PredefinedValue ( "Enum.Intervals.ByMonthsVertical" ) ) then
		Planner.TimeScale.Items [ 1 ].Repetition = TimeScale;
	endif;
	
EndProcedure

&AtClient
Procedure showWeekendTip ()
	
	if ( ShowWeekend ) then
		return;
	endif; 
	if ( dayOff ( CurrentDate () ) ) then
		Output.ShowWeekendTip ();
	endif; 

EndProcedure 

&AtClient
Procedure titleCalendar ()
	
	lang = language ();
	parts = new Array ();
	if ( PeriodDetail = PredefinedValue ( "Enum.Intervals.ByDay" ) ) then
		parts.Add ( Format ( CalendarDate, lang + ";DF='dddd, MMM dd, yyyy'" ) );
	elsif ( PeriodDetail = PredefinedValue ( "Enum.Intervals.ByWeeks" ) ) then
		sameMonth = Month ( DateStart ) = Month ( DateEnd );
		parts.Add ( Format ( DateStart, lang + ";DF='MMM '" ) + Day ( DateStart ) + " - " + Day ( DateEnd ) + Format ( DateEnd, lang + ";" + ? ( sameMonth, "DF=', yyyy'", "DF=' MMM, yyyy'" ) ) );
	else
		parts.Add ( Format ( CalendarDate, lang + ";DF='MMMM yyyy'" ) );
	endif; 
	filter = getFilter ( Performers );
	if ( filter = undefined ) then
		parts.Add ( CurrentUser );
	else
		for each performer in filter do
			parts.Add ( performer );
		enddo;
	endif;
	Title = Title ( StrConcat ( parts, ", " ) );
	
EndProcedure

&AtClient
Function language ()
	
	return "L=" + CurrentLanguage ();
	
EndFunction

&AtServer
Procedure OnSaveDataInSettingsAtServer ( Settings )
	
	if ( SelectionMode ) then
		Settings.Clear ();
	else
		LoginsSrv.SaveSettings ( Enum.SettingsCalendarSettings (), , Settings );
	endif;
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EditingObjects.Find ( Source ) <> undefined ) then
		return;
	endif;
	if ( EventName = Enum.MessageUserTaskUpdated ()
		or EventName = Enum.MessageTimeEntryUpdated () ) then
		updateByTask ( Parameter );
	elsif ( EventName = Enum.MessageProjectChanged () ) then
		updateByProject ( Parameter );
	elsif ( EventName = Enum.MessageCommandSaved () ) then
		updateByCommand ( Parameter );
	elsif ( EventName = Enum.MessageMeetingIsSaved ()
		or EventName = Enum.MessageEventIsSaved () ) then
		updateByEvent ( Parameter );
	elsif ( EventName = Enum.MessageCalendarAppearanceChanged () ) then
		fillCalendar ();
	elsif ( EventName = Enum.MessageScheduleChanged () ) then
		updateBySchedule ( Parameter );
	elsif ( ShowPayments
		and ( EventName = Enum.MessageSalesOrderIsSaved ()
			or EventName = Enum.MessageInvoiceIsSaved ()
			or EventName = Enum.MessageBillIsSaved ()
			or EventName = Enum.MessagePaymentIsSaved () ) ) then
		fillCalendar ();
	elsif ( ShowVendorPayments
		and ( EventName = Enum.MessagePurchaseOrderIsSaved ()
		or EventName = Enum.MessageVendorInvoiceIsSaved ()
		or EventName = Enum.MessageVendorBillIsSaved ()
		or EventName = Enum.MessageVendorPaymentIsSaved () )  ) then
		fillCalendar ();
	elsif ( ShowSalesOrders
		and ( EventName = Enum.MessageSalesOrderIsSaved ()
			or EventName = Enum.MessageInvoiceIsSaved () ) ) then
		fillCalendar ();
	elsif ( ShowPurchaseOrders
		and ( EventName = Enum.MessagePurchaseOrderIsSaved ()
		or EventName = Enum.MessageVendorInvoiceIsSaved () )  ) then
		fillCalendar ();
	elsif ( ShowRooms
		and EventName = Enum.MessageRoomIsSaved () ) then
		fillCalendar ();
	endif; 
	
EndProcedure

&AtClient
Procedure updateByTask ( Params )
	
	if ( Params.OldDate >= DateStart and Params.OldDate <= DateEnd )
		or ( Params.NewDate >= DateStart and Params.NewDate <= DateEnd ) then
		fillCalendar ();
	endif; 
	
EndProcedure 

&AtClient
Procedure updateByProject ( Params )
	
	if ( Params.OldDateStart >= DateStart and Params.OldDateStart <= DateEnd )
		or ( Params.NewDateStart >= DateStart and Params.NewDateStart <= DateEnd )
		or ( Params.OldDateEnd >= DateStart and Params.OldDateEnd <= DateEnd )
		or ( Params.NewDateEnd >= DateStart and Params.NewDateEnd <= DateEnd )
	then
		fillCalendar ();
	endif; 
	
EndProcedure 

&AtClient
Procedure updateByCommand ( Params )
	
	start = Params.Start;
	finish = Params.Finish;
	if ( start >= DateStart and start <= DateEnd )
		or ( finish >= DateStart and finish <= DateEnd ) then
		fillCalendar ();
	endif; 
	
EndProcedure 

&AtClient
Procedure updateByEvent ( Params )
	
	if ( Params.OldDate >= DateStart and Params.OldDate <= DateEnd )
		or ( Params.NewDate >= DateStart and Params.NewDate <= DateEnd ) then
		fillCalendar ();
	endif; 
	
EndProcedure 

&AtClient
Procedure updateBySchedule ( SourceSchedule )
	
	if ( Schedule <> SourceSchedule ) then
		return;
	endif; 
	setWeekInfo ( ThisObject );
	fillCalendar ();
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure NewCalendar ( Command )
	
	OpenForm ( "DataProcessor.Calendar.Form", , , new UUID () );
	
EndProcedure

&AtClient
Procedure ShowProjects ( Command )
	
	applyProjects ();
	
EndProcedure

&AtClient
Procedure applyProjects ()
	
	ShowProjects = not ShowProjects;
	if ( ShowProjects and ShowRooms ) then
		ShowRooms = false;
		Appearance.Apply ( ThisObject, "ShowRooms" );
	endif;
	if ( ShowProjects ) then
		HintsPopup.Open ( Output.HintsProjectsInCalendar (), Enum.HintsProjectsInCalendar () );
	endif;
	Appearance.Apply ( ThisObject, "ShowProjects" );
	fillCalendar ();
	
EndProcedure

&AtClient
Procedure ShowRooms ( Command )
	
	applyRooms ();
	
EndProcedure

&AtClient
Procedure applyRooms ()
	
	ShowRooms = not ShowRooms;
	if ( ShowRooms and ShowProjects ) then
		ShowProjects = false;
		Appearance.Apply ( ThisObject, "ShowProjects" );
	endif;
	if ( ShowRooms ) then
		HintsPopup.Open ( Output.HintsRoomsInCalendar (), Enum.HintsRoomsInCalendar () );
	endif;
	Appearance.Apply ( ThisObject, "ShowRooms" );
	fillCalendar ();
	
EndProcedure

&AtClient
Procedure ShowPanel ( Command )
	
	ShowPanel = not ShowPanel;
	Appearance.Apply ( ThisObject, "ShowPanel" );
	
EndProcedure

&AtClient
Procedure GoToToday ( Command )
	
	setCalendarPeriod ( "Today" );
	
EndProcedure

&AtClient
Procedure setCalendarPeriod ( Parameter )
	
	if ( Parameter = "Today" ) then
		CalendarDate = undefined;
		adjustCalendarDate ();
	else
		direction = ? ( Parameter = "NextPeriod", 1, -1 );
		if ( PeriodDetail = PredefinedValue ( "Enum.Intervals.ByDay" ) ) then
			CalendarDate = dayAdd ( CalendarDate, 1 * direction );
		elsif ( PeriodDetail = PredefinedValue ( "Enum.Intervals.ByWeeks" ) ) then
			CalendarDate = dayAdd ( CalendarDate, 7 * direction );
		else
			CalendarDate = AddMonth ( CalendarDate, 1 * direction );
		endif; 
	endif; 
	fillCalendar ();
	
EndProcedure 

&AtClient
Procedure GoToPreviousPeriod ( Command )
	
	setCalendarPeriod ( "PreviousPeriod" );
	
EndProcedure

&AtClient
Procedure GoToNextPeriod ( Command )
	
	setCalendarPeriod ( "NextPeriod" );
	
EndProcedure

&AtClient
Procedure ChangePeriod ( Command )
	
	openCalendar ();
	
EndProcedure

&AtClient
Procedure openCalendar ()
	
	p = new Structure ( "Date", CalendarDate );
	OpenForm ( "DataProcessor.Calendar.Form.Calendar", p, , , , , new NotifyDescription ( "CalendarForm", ThisObject ), FormWindowOpeningMode.LockWholeInterface );
	
EndProcedure 

&AtClient
Procedure CalendarForm ( Date, Params ) export
	
	if ( Date = undefined ) then
		return;
	endif; 
	CalendarDate = Date;
	adjustCalendarDate ();
	fillCalendar ();
	
EndProcedure 

&AtClient
Procedure CreateTask ( Command )
	
	newTask ();
	
EndProcedure

&AtClient
Procedure newTask ( Start = undefined, Finish = undefined )
	
	values = new Structure ( "Start, Finish, Section", Start, Finish, getSection () );
	OpenForm ( "Task.UserTask.ObjectForm", new Structure ( "FillingValues", values ), Items.Planner );
	
EndProcedure

&AtClient
Function getSection ()
	
	filter = getFilter ( Sections );
	if ( filter = undefined ) then
		return undefined;
	else
		return filter [ 0 ];
	endif;

EndFunction

&AtClient
Procedure newEvent ( Start = undefined, Finish = undefined, Performer = undefined )
	
	values = new Structure ( "Start, Finish", Start, Finish );
	if ( Performer = undefined ) then
		filter = getFilter ( Performers );
		if ( filter <> undefined ) then
			values.Insert ( "Responsible", filter [ 0 ] );
		endif;
	else
		values.Insert ( "Responsible", Performer );
	endif;
	filter = getFilter ( Customers );
	if ( filter <> undefined ) then
		values.Insert ( "Organization", filter [ 0 ] );
	endif;
	p = new Structure ( "FillingValues", values );
	OpenForm ( "Document.Event.ObjectForm", p, Items.Planner );
	
EndProcedure 

&AtClient
Procedure CreateEntry ( Command )
	
	newEntry ();
	
EndProcedure

&AtClient
Procedure newEntry ( Start = undefined, Finish = undefined, Performer = undefined )
	
	values = new Structure ();
	if ( Performer = undefined ) then
		filter = getFilter ( Performers );
		if ( filter <> undefined ) then
			values.Insert ( "Performer", filter [ 0 ] );
		endif;
	else
		values.Insert ( "Performer", Performer );
	endif;
	filter = getFilter ( Customers );
	if ( filter <> undefined ) then
		values.Insert ( "Customer", filter [ 0 ] );
	endif;
	filter = getFilter ( Projects );
	if ( filter <> undefined ) then
		values.Insert ( "Project", filter [ 0 ] );
	endif;
	p = new Structure ( "Start, Finish, FillingValues", Start, Finish, values );
	OpenForm ( "Document.TimeEntry.ObjectForm", p, Items.Planner, true );
	
EndProcedure 

&AtClient
Procedure CreateCommand ( Command )
	
	newCommand ();
	
EndProcedure

&AtClient
Procedure newCommand ( Start = undefined, Finish = undefined, Performer = undefined )
	
	if ( Performer = undefined ) then
		employees = getFilter ( Performers );
	else
		employees = new Array ();
		employees.Add ( Performer );
	endif;
	values = new Structure ( "Start, Finish", Start, Finish );
	p = new Structure ( "Performers, FillingValues", employees, values );
	OpenForm ( "BusinessProcess.Command.ObjectForm", p, Items.Planner );
	
EndProcedure 

&AtClient
Procedure CreateProject ( Command )
	
	newProject ();
	
EndProcedure

&AtClient
Procedure newProject ( Start = undefined, Finish = undefined, Performer = undefined )
	
	if ( Performer = undefined ) then
		employees = getFilter ( Performers );
	else
		employees = new Array ();
		employees.Add ( Performer );
	endif;
	values = new Structure ( "DateStart, DateEnd", Start, Finish );
	filter = getFilter ( Customers );
	if ( filter <> undefined ) then
		values.Insert ( "Owner", filter [ 0 ] );
	endif;
	p = new Structure ( "Performers, FillingValues", employees, values );
	OpenForm ( "Catalog.Projects.ObjectForm", p, Items.Planner );
	
EndProcedure 

&AtClient
Procedure DetailByDay ( Command )
	
	applyNewPeriodDetail ( PredefinedValue ( "Enum.Intervals.ByDay" ) );
	
EndProcedure

&AtClient
Procedure applyNewPeriodDetail ( NewPeriodDetail, NewCalendarDate = undefined )
	
	if ( NewCalendarDate = undefined ) then
		resetToCurrentDay ( NewPeriodDetail );
	else
		CalendarDate = NewCalendarDate;
	endif; 
	PeriodDetail = NewPeriodDetail;
	adjustCalendarDate ();
	fillCalendar ();
	Appearance.Apply ( ThisObject, "PeriodDetail" );
	
EndProcedure 

&AtClient
Procedure resetToCurrentDay ( NewPeriodDetail )
	
	if ( NewPeriodDetail = PeriodDetail ) then
		return;
	endif; 
	now = CurrentDate ();
	if ( DateStart <= now and now <= dayAdd ( DateEnd ) ) then
		CalendarDate = undefined;
	endif; 
	
EndProcedure 

&AtClient
Procedure DetailByWeeks ( Command )
	
	applyNewPeriodDetail ( PredefinedValue ( "Enum.Intervals.ByWeeks" ) );
	
EndProcedure

&AtClient
Procedure DetailByMonthVertical ( Command )
	
	applyNewPeriodDetail ( PredefinedValue ( "Enum.Intervals.ByMonthsVertical" ) );
	
EndProcedure

&AtClient
Procedure DetailByMonthHorizontal ( Command )
	
	applyNewPeriodDetail ( PredefinedValue ( "Enum.Intervals.ByMonthsHorizontal" ) );
	
EndProcedure

&AtClient
Procedure TabloidToggled ( Command )
	
	scope = Command.Name;
	ThisObject [ scope ] = not ThisObject [ scope ];
	fillCalendar ();
	Appearance.Apply ( ThisObject, scope, true );
	
EndProcedure

&AtClient
Procedure ShowCompleted ( Command )

	applyShowCompleted ();
	fillCalendar ();
	Appearance.Apply ( ThisObject, "ShowCompleted", true );

EndProcedure

&AtClient
Procedure applyShowCompleted ()
	
	ShowCompleted = not ShowCompleted;
	filterCompleted ();
	
EndProcedure

&AtClient
Procedure RefreshCalendar ( Command )
	
	fillCalendar ();
	
EndProcedure

&AtClient
Procedure OpenProjectAnalysis ( Command )
	
	openReport ( "Projects" );
	
EndProcedure

&AtClient
Procedure openReport ( ReportName )
	
	p = ReportsSystem.GetParams ( ReportName );
	filters = new Array ();
	filter = getFilter ( Customers );
	if ( filter <> undefined ) then
		item = DC.CreateFilter ( "Customer", ? ( filter.Count () = 1, filter [ 0 ], filter ) );
		filters.Add ( item );
	endif;
	filter = getFilter ( Projects );
	if ( filter <> undefined ) then
		item = DC.CreateFilter ( "Project", ? ( filter.Count () = 1, filter [ 0 ], filter ) );
		filters.Add ( item );
	endif;
	filter = getFilter ( Performers );
	if ( filter <> undefined ) then
		employees = extractEmployees ( filter );
		item = DC.CreateFilter ( "Employee", ? ( employees.Count () = 1, employees [ 0 ], employees ) );
		filters.Add ( item );
	endif;
	if ( ReportName = "WorkLog" ) then
		p.Variant = "#Calendar";
		item = DC.CreateParameter ( "Period", new StandardPeriod ( DateStart, DateEnd ) );
		filters.Add ( item );
	endif; 
	p.GenerateOnOpen = true;
	p.Filters = filters;
	OpenForm ( "Report.Common.Form", p, ThisObject, true );
	
EndProcedure 

&AtServerNoContext
Function extractEmployees ( val Performers )
	
	s = "
	|select Users.Employee as Employee
	|from Catalog.Users as Users
	|where Users.Ref in ( &Users )
	|";
	q = new Query ( s );
	q.SetParameter ( "Users", Performers );
	return q.Execute ().Unload ().UnloadColumn ( "Employee" );
	
EndFunction

&AtClient
Procedure OpenWorkLog ( Command )
	
	openReport ( "WorkLog" );
	
EndProcedure

// *****************************************
// *********** Page Settings

&AtClient
Procedure CustomerFilterOnChange ( Item )
	
	resetFilter ( Projects );
	updateFilter ( CustomerFilter, Customers );
	fillCalendar ();

EndProcedure

&AtClient
Procedure resetFilter ( Filter )
	
	Filter.FillChecks ( false );
	
EndProcedure

&AtClientAtServerNoContext
Procedure updateFilter ( Value, List )
	
	if ( Value.IsEmpty () ) then
		return;
	endif;
	List.FillChecks ( false );
	item = List.FindByValue ( Value );
	if ( item = undefined ) then
		i = List.Count () - 1;
		while ( i > 5 ) do
			List.Delete ( i );
			i = i - 1;
		enddo;
		item = List.Insert ( 0, Value );
	endif;
	item.Check = true;
	Value = undefined;
	
EndProcedure

&AtClient
Procedure CustomersOnChange ( Item )
	
	resetFilter ( Projects );
	filterCustomers ();
	fillCalendar ();
	
EndProcedure

&AtClient
Procedure PerformerFilterOnChange ( Item )
	
	updateFilter ( PerformerFilter, Performers );
	filterByPerformers ();
	
EndProcedure

&AtClient
Procedure filterByPerformers ()
	
	filterRerformers ();
	fillCalendar ();
	
EndProcedure

&AtClient
Procedure PerformersOnChange ( Item )
	
	filterByPerformers ();
	
EndProcedure

&AtClient
Procedure FiltersBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure FiltersSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	openFilter ( Item );
	
EndProcedure

&AtClient
Procedure openFilter ( Item )
	
	value = Item.CurrentData.Value;
	type = TypeOf ( value );
	if ( type = Type ( "CatalogRef.Organizations" ) ) then
		list = Customers;
		form = "Catalog.Organizations.ObjectForm";
	elsif ( type = Type ( "CatalogRef.Users" ) ) then
		list = Performers;
		form = "Catalog.Users.ObjectForm";
	elsif ( type = Type ( "CatalogRef.Sections" ) ) then
		list = Sections;
		form = "Catalog.Sections.ObjectForm";
	elsif ( type = Type ( "CatalogRef.Projects" ) ) then
		list = Projects;
		form = "Catalog.Projects.ObjectForm";
	elsif ( type = Type ( "CatalogRef.Rooms" ) ) then
		list = Rooms;
		form = "Catalog.Rooms.ObjectForm";
	endif;
	params = new Structure ( "Value, List", value, list );
	OpenForm ( form, new Structure ( "Key", value ), , , , , new NotifyDescription ( "FilterValueClosed", ThisObject, params ) );
	
EndProcedure

&AtClient
Procedure FilterValueClosed ( Result, Params ) export
	
	value = Params.Value;
	item = Params.List.FindByValue ( value );
	if ( item <> undefined ) then
		// In order to update the item presentation, manual update should be used.
		// There was taken into consideration that the following things do not work:
		// - RefreshDataRepresentation () does not update list neither field in the list
		// - item.Description = "" + value; // It is not recommended because that Description
		//   will be restored next time as is and can be inaccurate compared to actual database value.
		item.Value = value;
	endif;
	
EndProcedure

&AtClient
Procedure ProjectFilterOnChange ( Item )
	
	resetFilter ( Customers );
	updateFilter ( ProjectFilter, Projects );
	fillCalendar ();

EndProcedure

&AtClient
Procedure ProjectsOnChange ( Item )
	
	resetFilter ( Customers );
	fillCalendar ();
	
EndProcedure

&AtClient
Procedure SectionFilterOnChange ( Item )
	
	applyFilterSections ();
	
EndProcedure

&AtClient
Procedure applyFilterSections ()
	
	updateFilter ( SectionFilter, Sections );
	filterBySections ();
	fillCalendar ();
	
EndProcedure

&AtClient
Procedure RoomFilterOnChange ( Item )
	
	updateFilter ( RoomFilter, Rooms );
	fillCalendar ();

EndProcedure

&AtClient
Procedure RoomsOnChange ( Item )
	
	fillCalendar ();
	
EndProcedure

&AtClient
Procedure SectionsOnChange ( Item )
	
	applyFilterSections ();
	
EndProcedure

&AtClient
Procedure ResetByDefault ( Command )
	
	resetCalendarByDefault ();
	fillCalendar ();
	
EndProcedure

&AtServer
Procedure resetCalendarByDefault ()
	
	setLayoutByDefault ();
	Appearance.Apply ( ThisObject );
	
EndProcedure 

&AtClient
Procedure TimeScaleOnChange ( Item )
	
	fixTimeScale ();
	fillCalendar ();
	
EndProcedure

&AtClient
Procedure fixTimeScale ()
	
	if ( TimeScale = 0 ) then
		TimeScale = 15;
	endif; 
	
EndProcedure 

&AtClient
Procedure ScheduleClearing ( Item, StandardProcessing )
	
	StandardProcessing = false;
	
EndProcedure

&AtClient
Procedure ScheduleOnChange ( Item )
	
	setWeekInfo ( ThisObject );
	fillCalendar ();
	
EndProcedure

&AtClient
Procedure ShowWeekendOnChange ( Item )
	
	fillCalendar ();
	
EndProcedure

&AtClient
Procedure ColorStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	Colors.ChooseColor ( Item, ThisObject [ Item.Name ] );
	
EndProcedure

&AtClient
Procedure ColorOnChange ( Item )
	
	fillCalendar ();
	
EndProcedure

&AtClient
Procedure ColorClearing ( Item, StandardProcessing )
	
	StandardProcessing = false;
	
EndProcedure

&AtClient
Procedure TimeScalePositionOnChange ( Item )
	
	setTimeLocation ();
	
EndProcedure

&AtClient
Procedure FontSizeOnChange ( Item )
	
	applyFont ( ThisObject, FontSize );
	
EndProcedure

// *****************************************
// *********** Planner

&AtClient
Procedure PlannerOnCurrentRepresentationPeriodChange ( Item, CurrentRepresentationPeriods, StandardProcessing )
	
	StandardProcessing = false;
	#if ( MobileClient ) then
		if ( not FingerScroll ) then
			return;
		endif;
		// 8.3.12 Bug workaround: RepresentationPeriods are incorrect and depend on calendar layout variant
		if ( PeriodDetail = PredefinedValue ( "Enum.Intervals.ByMonthsVertical" ) ) then
			if ( Planner.CurrentRepresentationPeriods [ 0 ].Begin > CurrentRepresentationPeriods [ 0 ].Begin ) then
				setCalendarPeriod ( "NextPeriod" );
			else
				setCalendarPeriod ( "PreviousPeriod" );
			endif;
		else
			if ( CurrentRepresentationPeriods [ 0 ].Begin = Planner.CurrentRepresentationPeriods [ 0 ].Begin ) then
				setCalendarPeriod ( "NextPeriod" );
			else
				setCalendarPeriod ( "PreviousPeriod" );
			endif;
		endif;
	#else
		if ( CurrentRepresentationPeriods [ 0 ].Begin > Planner.CurrentRepresentationPeriods [ 0 ].Begin ) then
			setCalendarPeriod ( "NextPeriod" );
		else
			setCalendarPeriod ( "PreviousPeriod" );
		endif;
	#endif
	
EndProcedure

&AtClient
Procedure PlannerSelection ( Item, StandardProcessing )
	
	StandardProcessing = false;
	openRecord ();
	
EndProcedure

&AtClient
Procedure openRecord ()
	
	selection = Items.Planner.SelectedItems;
	if ( selection.Count () = 0 ) then
		return;
	endif;
	value = selection [ 0 ].Value;
	ShowValue ( , value );
	
EndProcedure

&AtClient
Procedure PlannerBeforeCreate ( Item, Begin, End, Values, Text, StandardProcessing )
	
	StandardProcessing = false;
	if ( SelectionMode ) then
		pickTime ( Begin, End );
	elsif ( ShowRooms ) then
		newMeeting ( Begin, End, Values.Get ( "Room" ) );
	else
		showMenu ( Begin, End, Values );
	endif;	

EndProcedure

&AtClient
Procedure pickTime ( Begin, End )
	
	Close ( new Structure ( "Begin, End", Begin, End ) );

EndProcedure

&AtClient
Procedure newMeeting ( Start = undefined, Finish = undefined, Target = undefined )
	
	values = new Structure ( "Start, Finish", Start, Finish );
	p = new Structure ();
	if ( TypeOf ( Target ) = Type ( "CatalogRef.Rooms" ) ) then
		values.Insert ( "Room", Target );
	else
		if ( Target = undefined ) then
			members = getFilter ( Performers );
		else
			members = new Array ();
			members.Add ( Target );
		endif;
		p.Insert ( "Members", members );
	endif;
	p.Insert ( "FillingValues", values );
	OpenForm ( "Document.Meeting.ObjectForm", p, Items.Planner );
	
EndProcedure 

&AtClient
Procedure showMenu ( Begin, End, Values )
	
	adjustPeriod ( Begin, End );
	p = new Structure ( "Start, Finish, Values", Begin, End, Values );
	callback = new NotifyDescription ( "SelectedAction", ThisObject, p );
	#if ( MobileClient ) then
		MobileMenu.ShowChooseItem ( callback );
	#else
		OpenForm ( "DataProcessor.Calendar.Form.Menu", , ThisObject, , , , callback );
	#endif

EndProcedure

&AtClient
Procedure adjustPeriod ( Begin, End )
	
	if ( PeriodDetail <> PredefinedValue ( "Enum.Intervals.ByMonthsVertical" ) ) then
		return;
	endif;
	now = CurrentDate ();
	today = BegOfDay ( now );
	if ( Begin = today ) then
		Begin = BegOfMinute ( now );
	else
		Begin = BegOfDay ( Begin ) + PreciseTimeStart;
	endif;
	End = BegOfDay ( End - 1 ) + PreciseTimeEnd;
	
EndProcedure

&AtClient
Procedure SelectedAction ( Menu, Params ) export
	
	if ( Menu = undefined ) then
		return;
	endif;
	action = Menu.Value;
	if ( action = Enum.CalendarMenuNewTask () ) then
		newTask ( Params.Start, Params.Finish );
	elsif ( action = Enum.CalendarMenuNewEvent () ) then
		newEvent ( Params.Start, Params.Finish, Params.Values.Get ( "Performer" ) );
	elsif ( action = Enum.CalendarMenuNewTimeEntry () ) then
		newEntry ( Params.Start, Params.Finish, Params.Values.Get ( "Performer" ) );
	elsif ( action = Enum.CalendarMenuNewCommand () ) then
		newCommand ( Params.Start, Params.Finish, Params.Values.Get ( "Performer" ) );
	elsif ( action = Enum.CalendarMenuNewMeeting () ) then
		newMeeting ( Params.Start, Params.Finish, Params.Values.Get ( "Performer" ) );
	elsif ( action = Enum.CalendarMenuNewProject () ) then
		newProject ( Params.Start, Params.Finish, Params.Values.Get ( "Performer" ) );
	endif;
	
EndProcedure

&AtClient
Procedure PlannerBeforeStartQuickEdit ( Item, StandardProcessing )
	
	StandardProcessing = false;
	openRecord ();
	
EndProcedure

&AtClient
Procedure PlannerOnEditEnd ( Item, Copying, CancelEdit )
	
	if ( SelectionMode
		and SelectionSource = Item.SelectedItems [ 0 ].Value ) then
		CancelEdit = true;
		// Bug workaround 8.3.13.1513: we need to put off closing
		pickingWorkaround ();
		return;
	endif;
	if ( editInForm () ) then
		CancelEdit = true;
		return;
	endif;
	taskType = Type ( "TaskRef.UserTask" );
	entryType = Type ( "DocumentRef.TimeEntry" );
	projectType = Type ( "CatalogRef.Projects" );
	meetingType = Type ( "DocumentRef.Meeting" );
	eventType = Type ( "DocumentRef.Event" );
	elements = Items.Planner.SelectedItems;
	plannerItems = Planner.Items;
	EditingObjects.Clear ();
	index = elements.Count ();
	while ( index > 0 ) do
		index = index - 1;
		element = elements [ index ];
		record = serializeItem ( element );
		valueType = TypeOf ( element.Value );
		if ( valueType = taskType ) then
			record = modifyTask ( Copying, record );
		elsif ( valueType = entryType ) then
			clone = modifyEntry ( Copying, record, PeriodDetail );
			if ( Copying ) then
				plannerItems.Delete ( element );
				outputEntries ( getEntry ( getParams (), clone ) );
			endif;
		elsif ( valueType = projectType ) then
			if ( ShowPerformers ) then
				raise Output.ProjectDragAndDropError ();
			endif;
			record = modifyProject ( Copying, record, PeriodDetail );
		elsif ( valueType = meetingType ) then
			EditingObjects.Add ( element.Value );
			modifyMeeting ( Copying, record );
		elsif ( valueType = eventType ) then
			EditingObjects.Add ( element.Value );
			modifyEvent ( Copying, record );
		endif;
		if ( record <> undefined ) then
			FillPropertyValues ( element, record );
		endif;
	enddo;
	if ( PeriodDetail <> PredefinedValue ( "Enum.Intervals.ByMonthsVertical" ) ) then
		if ( adjustHours () ) then
			fillPeriod ();
		endif;
	endif;
	
EndProcedure

&AtClient
Procedure pickingWorkaround ()
	
	element = Items.Planner.SelectedItems [ 0 ];
	PickedElement = new Structure ( "Begin, End", element.Begin, element.End );
	AttachIdleHandler ( "delayedPicking", 0.01, true );
		
EndProcedure

&AtClient
Procedure delayedPicking () export
	
	pickTime ( PickedElement.Begin, PickedElement.End );
	
EndProcedure

&AtClient
Function editInForm ()
	
	for each item in Items.Planner.SelectedItems do
		value = item.Value;
		type = TypeOf ( value );
		if ( EditInDialog.ContainsType ( type ) ) then
			ShowValue ( , value );
			return true;
		endif;
	enddo;
	return false;
	
EndFunction

&AtClient
Function serializeItem ( Item )
	
	fields = new Structure ();
	fields.Insert ( "Text", Item.Text );
	fields.Insert ( "Begin", Item.Begin );
	fields.Insert ( "End", Item.End );
	fields.Insert ( "Value", Item.Value );
	dims = Item.DimensionValues;
	fields.Insert ( "Performer", dims.Get ( "Performer" ) );
	fields.Insert ( "Room", dims.Get ( "Room" ) );
	return fields;
	
EndFunction

&AtServerNoContext
Function modifyTask ( val Copying, val Item )
	
	checkProcess ( Copying, Item );
	ref = Item.Value;
	performer = Item.Performer;
	if ( Copying ) then
		obj = ref.GetObject ().Copy ();
		obj.Date = CurrentSessionDate ();
	else
		obj = ref.GetObject ();
	endif;
	obj.Start = Item.Begin;
	obj.Finish = Item.End;
	TaskForm.CalcDuration ( obj );
	if ( performer <> undefined ) then
		obj.Section = undefined;
		obj.Performer = performer;
	endif;
	if ( obj.BusinessProcess.IsEmpty () ) then
		obj.Creator = ? ( performer = undefined, SessionParameters.User, performer );
	endif;
	obj.Write ();
	if ( Copying ) then
		Item.Value = obj.Ref;
		return Item;
	endif;

EndFunction

&AtServerNoContext
Procedure checkProcess ( Copying, Item )
	
	ref = Item.Value;
	fields = DF.Values ( ref, "BusinessProcess, Point, Performer" );
	if ( not fields.BusinessProcess.IsEmpty () ) then
		if ( Copying ) then
			raise Output.TaskCopyingError ();
		elsif ( fields.Point = Enums.CommandPoints.Checking
			and Item.Performer <> undefined
			and Item.Performer <> fields.Performer ) then
			raise Output.TaskModifyingError ();
		endif;
	endif;
	
EndProcedure

&AtServerNoContext
Function modifyEntry ( val Copying, val Item, val PeriodDetail )
	
	ref = Item.Value;
	performer = Item.Performer;
	start = Item.Begin;
	finish = Item.End;
	if ( BegOfDay ( start ) <> BegOfDay ( finish ) ) then
		raise Output.TimeEntryCrossingDays ();
	endif;
	if ( Copying ) then
		obj = ref.GetObject ().Copy ();
	else
		obj = ref.GetObject ();
		records = obj.Tasks;
		if ( records.Count () > 1 ) then
			raise Output.TimeEntryChangeDurationError ();
		endif;
	endif;
	obj.Date = start;
	if ( performer <> undefined
		and performer <> obj.Performer ) then
		obj.Performer = performer;
		TimesheetForm.SetEmployee ( obj );
		TimesheetForm.SetIndividual ( obj );
	endif;
	if ( not Copying ) then
		if ( PeriodDetail <> Enums.Intervals.ByMonthsVertical ) then
			row = records [ 0 ];
			startDay = BegOfDay ( start );
			emptyDate = Date ( 1, 1, 1 );
			row.TimeStart = emptyDate + ( start - startDay );
			row.TimeEnd = emptyDate + ( finish - startDay );
			TimesheetForm.CalcMinutes ( row );
			TimesheetForm.CalcTotalMinutes ( obj );
		endif;
	endif;
	obj.Write ( DocumentWriteMode.Posting );
	if ( Copying ) then
		return obj.Ref;
	endif;

EndFunction

&AtServerNoContext
Function getEntry ( val Params, val Entry )
	
	env = new Structure ();
	SQL.Init ( env );
	q = Env.Q;
	q.SetParameter ( "Entry", Entry );
	sqlTimeEntry ( env );
	sqlAppearance ( env );
	SQL.Perform ( env );
	result = new Structure ();
	result.Insert ( "TimeEntries", CollectionsSrv.Serialize ( Env.TimeEntries ) );
	result.Insert ( "Colors", Diary.ColorsMap ( Env ) );
	return result;

EndFunction

&AtServerNoContext
Procedure sqlTimeEntry ( Env )
	
	s = "
	|// #TimeEntries
	|select allowed Tasks.Ref as Ref, Tasks.Description as Description,
	|	case when Tasks.TimeStart = datetime ( 1, 1, 1 ) then Tasks.Ref.Date
	|		else dateadd ( beginofperiod ( Tasks.Ref.Date, day ), minute, hour ( Tasks.TimeStart ) * 60 + minute ( Tasks.TimeStart ) ) 
	|	end as DateStart,
	|	case when Tasks.TimeEnd = datetime ( 1, 1, 1 ) then endofperiod ( Tasks.Ref.Date, day )
	|		else dateadd ( beginofperiod ( Tasks.Ref.Date, day ), minute, hour ( Tasks.TimeEnd ) * 60 + minute ( Tasks.TimeEnd ) ) 
	|	end as DateEnd,
	|	Tasks.Ref.Appearance.Code as Appearance, Tasks.Duration as Duration, Tasks.Ref.Performer as Performer,
	|	Tasks.Ref.Customer.Description as Customer, Tasks.Ref.Project.Description as Project
	|from Document.TimeEntry.Tasks as Tasks
	|where Tasks.Ref = &Entry
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServerNoContext
Function modifyProject ( val Copying, val Item, val PeriodDetail )
	
	ref = Item.Value;
	start = Item.Begin;
	finish = Item.End;
	BeginTransaction ();
	if ( Copying ) then
		source = ref.GetObject ();
		obj = source.Copy ();
		tables = DataProcessors.Tables.Create ();
		Catalogs.Projects.ReadJunctions ( source.Ref, tables );
		makeUnique ( obj );
	else
		obj = ref.GetObject ();
	endif;
	dateStart = obj.DateStart;
	dateEnd = EndOfDay ( obj.DateEnd );
	if ( dateStart <> start
		and dateEnd <> finish ) then
		duration = dateEnd - dateStart;
		obj.DateStart = BegOfDay ( start );
		obj.DateEnd = obj.DateStart + duration;
	else
		obj.DateStart = BegOfDay ( start );
		obj.DateEnd = finish - ? ( PeriodDetail = PredefinedValue ( "Enum.Intervals.ByMonthsVertical" ), 1, 0 );
	endif;
	obj.Write ();
	if ( Copying ) then
		Catalogs.Projects.SaveJunctions ( obj.Ref, tables );
	endif;
	CommitTransaction ();
	Item.Begin = obj.DateStart;
	Item.End = EndOfDay ( obj.DateEnd );
	if ( Copying ) then
		Item.Value = obj.Ref;
		Item.Text = projectDescription ( String ( obj.Owner ), obj.Description );
	endif;
	return Item;
	
EndFunction

&AtServerNoContext
Procedure makeUnique ( Project )
	
	locking = new Map ();
	locking [ "Owner" ] = Project.Owner;
	DF.MakeUnique ( Project, "Description", locking );
		
EndProcedure

&AtClient
Procedure modifyMeeting ( Copying, Item )
	
	p = new Structure ( "NewStart, NewFinish, NewRoom", Item.Begin, Item.End, Item.Room );
	ref = Item.Value;
	if ( Copying ) then
		p.Insert ( "CopyingValue", ref );
	else
		p.Insert ( "Key", ref );
	endif;
	callback = new NotifyDescription ( "EditingObjectClosed", ThisObject, ref );
	OpenForm ( "Document.Meeting.ObjectForm", p, Items.Planner, , , , callback );

EndProcedure

&AtClient
Procedure EditingObjectClosed ( Result, Value ) export
	
	EditingObjects.Delete ( EditingObjects.Find ( Value ) );
	fillCalendar ();
	
EndProcedure

&AtClient
Procedure modifyEvent ( Copying, Item )
	
	p = new Structure ( "NewStart, NewFinish, NewResponsible", Item.Begin, Item.End, Item.Performer );
	ref = Item.Value;
	if ( Copying ) then
		p.Insert ( "CopyingValue", ref );
	else
		p.Insert ( "Key", ref );
	endif;
	callback = new NotifyDescription ( "EditingObjectClosed", ThisObject, ref );
	OpenForm ( "Document.Event.ObjectForm", p, Items.Planner, , , , callback );

EndProcedure

&AtClient
Procedure PlannerBeforeDelete ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure
