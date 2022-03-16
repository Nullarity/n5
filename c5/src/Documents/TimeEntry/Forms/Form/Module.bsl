&AtServer
var Copy;
&AtServer
var Env;
&AtServer
var Base;
&AtClient
var OldDate;
&AtClient
var TimeOffset;
&AtClient
var TasksRow;
&AtClient
var ItemsRow;
&AtServer
var TimesheetExists;
&AtServer
var SalesOrderExists;
&AtServer
var InternalOrderExists;
&AtServer
var EventExists;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	setTitle ( ThisObject );
	setTimesheet ();
	setProjects ();
	setTasks ();
	fillTimeTypes ();
	readSignature ();
	updateChangesPermission ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtClientAtServerNoContext
Procedure setTitle ( Form )
	
	object = Form.Object;
	if ( object.Ref.IsEmpty () ) then
		s = Output.NewTimeEntry ();
	else
		s = "" + object.Ref;
	endif; 
	performer = object.Performer;
	if ( not performer.IsEmpty () ) then
		s = s + ", " + performer;
	endif; 
	Form.Title = s;
	
EndProcedure 

&AtServer
Procedure setTimesheet ()
	
	Timesheet = Documents.TimeEntry.GetTimesheetByEmployee ( Object.Date, Object.Employee );
	
EndProcedure 

&AtServer
Procedure setProjects ()
	
	list = Items.Project.ChoiceList;
	list.Clear ();
	projects = getProjects ();
	for each project in projects do
		Items.Project.ChoiceList.Add ( project.Project, project.Description );
	enddo; 
	
EndProcedure 

&AtServer
Function getProjects ()
	
	s = "
	|select allowed Projects.Project as Project, Projects.Description as Description
	|from (
	|	select top 10 Projects.Ref as Project, Projects.Description as Description
	|	from Catalog.Projects as Projects
	|		//
	|		// Constants
	|		//
	|		left join Constants as Constants
	|		on true
	|	where Projects.Owner = &Customer
	|	and not Projects.Completed
	|	and not Projects.IsFolder
	|	and Projects.ProjectType not in (
	|			value ( Enum.ProjectTypes.SickDays ),
	|			value ( Enum.ProjectTypes.Vacations ),
	|			value ( Enum.ProjectTypes.Holidays ) )
	|	union
	|	select Projects.Ref, Projects.Description
	|	from Catalog.Projects as Projects
	|	where Projects.Ref = &Project ) as Projects
	|order by Projects.Description
	|
	|";
	q = new Query ( s );
	q.SetParameter ( "Customer", Object.Customer );
	q.SetParameter ( "Project", Object.Project );
	return q.Execute ().Unload ();
	
EndFunction 

&AtServer
Procedure setTasks ()
	
	data = getProjectTasks ();
	list = Items.TasksTask.ChoiceList;
	list.Clear ();
	for each row in data.Tasks do
		list.Add ( row.Task, row.Description );
	enddo; 
	ProjectTime.Clear ();
	for each row in data.Time do
		newRow = ProjectTime.Add ();
		FillPropertyValues ( newRow, row );
	enddo; 
	
EndProcedure 

&AtServer
Function getProjectTasks ()
	
	s = "
	|// #Tasks
	|select allowed distinct Tasks.Task as Task,
	|	case when Tasks.Employee = value ( Catalog.Employees.EmptyRef )
	|			or Tasks.Employee = &Employee then Tasks.Task.Description
	|		else Tasks.Task.Description + "" ("" + Tasks.Employee.Description + "")""
	|	end as Description
	|from Catalog.Projects.Tasks as Tasks
	|where Tasks.Ref = &Ref
	|and Tasks.Task <> value ( Catalog.Tasks.EmptyRef )
	|;
	|// #Time
	|select allowed distinct Tasks.Task as Task, Tasks.TimeType as Time
	|from Catalog.Projects.Tasks as Tasks
	|where Tasks.Ref = &Ref
	|and Tasks.Employee = &Employee
	|";
	env = SQL.Create ( s );
	q = env.Q;
	q.SetParameter ( "Ref", Object.Project );
	q.SetParameter ( "Employee", Object.Employee );
	sql.Perform ( env );
	return env;
	
EndFunction 

&AtServer
Procedure setTimeTypes ()
	
	fillTimeTypes ();
	adjustTimeTypes ();
	
EndProcedure 

&AtServer
Procedure fillTimeTypes ()
	
	list = Items.TasksTimeType.ChoiceList;
	list.Clear ();
	ProjectType = DF.Pick ( Object.Project, "ProjectType" );
	if ( ProjectType = Enums.ProjectTypes.Holidays ) then
		list.Add ( Enums.Time.Holiday );
	elsif ( ProjectType = Enums.ProjectTypes.SickDays ) then
		list.Add ( Enums.Time.Sickness );
	elsif ( ProjectType = Enums.ProjectTypes.Vacations ) then
		list.Add ( Enums.Time.Vacation );
		list.Add ( Enums.Time.ExtendedVacation );
	else
		list.Add ( Enums.Time.Billable );
		list.Add ( Enums.Time.NonBillable );
		list.Add ( Enums.Time.Banked );
		list.Add ( Enums.Time.BankedUse );
		list.Add ( Enums.Time.Overtime );
		list.Add ( Enums.Time.Evening );
		list.Add ( Enums.Time.Night );
		list.Add ( Enums.Time.DayOff );
	endif; 
	
EndProcedure 

&AtServer
Procedure adjustTimeTypes ()
	
	list = Items.TasksTimeType.ChoiceList;
	for each row in Object.Tasks do
		if ( list.FindByValue ( row.TimeType ) = undefined ) then
			row.TimeType = undefined;
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Procedure readSignature ()
	
	data = DF.Pick ( Object.Ref, "Signature" ).Get ();
	if ( data = undefined ) then
		Signature = undefined;
	else
		Signature = PutToTempStorage ( data, UUID );
	endif; 
	NewSignature = false;
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	loadParams ();
	setOpeningMode ();
	setTopCommandBarVisibility ();
	if ( Object.Ref.IsEmpty () ) then
		Copy = not Parameters.CopyingValue.IsEmpty ();
		setAppearance ();
		TimesheetForm.SetCreator ( ThisObject );
		baseType = TypeOf ( Parameters.Basis );
		if ( baseType = Type ( "CatalogRef.Projects" ) ) then
			fillByProject ();
		elsif ( baseType = Type ( "TaskRef.UserTask" ) ) then
			fillByTask ();
		elsif ( baseType = Type ( "DocumentRef.Event" ) ) then
			fillByEvent ();
		else
			fillNew ();
		endif; 
		setDate ();
		setTitle ( ThisObject );
		if ( not Object.Customer.IsEmpty () ) then
			setProjects ();
		endif; 
		if ( not Object.Project.IsEmpty () ) then
			fillTimeTypes ();
			setTasks ();
		endif; 
		if ( TimesheetBase
			or Copy ) then
			setExistedTimeEntry ();
		endif;
		Constraints.ShowAccess ( ThisObject );
	endif;
	setLinks ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Links show ShowLinks;
	|TasksTask show ProjectType = Enum.ProjectTypes.Regular;
	|Timesheet show filled ( Timesheet );
	|LoadExistedTimeEntry show filled ( ExistedTimeEntry );
	|Start Duration Description TasksStopTimer TasksCancelTimer enable TimerStarted;
	|TasksStartTimer enable not TimerStarted;
	|Date Performer Project Customer lock TimesheetBase;
	|DeleteTimeEntry show TimesheetBase and filled ( Object.Ref );
	|FormDeleteTimeEntry show filled ( Object.Ref ) and not TimesheetBase;
	|TakeSignature show empty ( Signature ) and filled ( Object.Signer );
	|ShowSignature show filled ( Signature ) and filled ( Object.Signer );
	|FormLoadSignature enable filled ( Object.Ref );
	|Write show empty ( Object.Ref ) and Mobile;
	|Signer lock filled ( Object.Ref ) and filled ( Signature );
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure init ()
	
	AdministratorSystem = IsInRole ( Metadata.Roles.AdministratorSystem );
	Mobile = Environment.MobileClient () or TesterCache.Testing ();
	
EndProcedure 

&AtServer
Procedure loadParams ()
	
	TimesheetBase = Parameters.TimesheetBase;
	TimesheetTime = Parameters.TimesheetTime;
	if ( Parameters.Start <> Date ( 1, 1, 1 ) ) then
		loadTime ();
	endif;
		
EndProcedure 

&AtServer
Procedure loadTime ()
	
	start = Parameters.Start;
	Object.Date = start;
	row = Object.Tasks.Add ();
	row.TimeStart = CoreLibrary.DateToTime ( start );
	row.TimeEnd = CoreLibrary.DateToTime ( Parameters.Finish );
	row.TimeType = Enums.Time.Billable;
	TimesheetForm.CalcMinutes ( row );
	TimesheetForm.CalcTotalMinutes ( Object );
	
EndProcedure

&AtServer
Procedure setOpeningMode ()
	
	if ( TimesheetBase ) then
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
	endif;
	
EndProcedure 

&AtServer
Procedure setTopCommandBarVisibility ()
	
	standard = not TimesheetBase;
	panel = Items.StandardTopCommandBar;
	panel.Visible = standard;
	if ( standard ) then
		StandardButtons.Arrange ( ThisObject, panel );
	endif;
	Items.TimesheetTopCommandBar.Visible = TimesheetBase;
	Items.UpdateTimesheet.DefaultButton = TimesheetBase;
	
EndProcedure

&AtServer
Procedure setAppearance ()
	
	Object.Appearance = Catalogs.CalendarAppearance.Default;
	
EndProcedure 

#region Filling

&AtServer
Procedure fillByProject ()
	
	getProjectData ();
	fillHeaderByProject ();
	
EndProcedure 

&AtServer
Procedure getProjectData ()
	
	initBase ();
	sqlProject ();
	SQL.Perform ( Base );
	
EndProcedure

&AtServer
Procedure initBase ()
	
	Base = new Structure ();
	SQL.Init ( Base );
	Base.Q.SetParameter ( "Base", Parameters.Basis );
	
EndProcedure 

&AtServer
Procedure sqlProject ()
	
	s = "
	|// @Fields
	|select Projects.Ref as Project, Projects.Owner as Customer
	|from Catalog.Projects as Projects
	|where Projects.Ref = &Base
	|";
	Base.Selection.Add ( s );
	
EndProcedure 

&AtServer
Procedure fillHeaderByProject ()
	
	Object.Project = Base.Fields.Project;
	Object.Customer = Base.Fields.Customer;
	
EndProcedure 

&AtServer
Procedure fillByTask ()
	
	getTaskData ();
	fillDocumentByTask ();
	
EndProcedure 

&AtServer
Procedure getTaskData ()
	
	initBase ();
	sqlTask ();
	SQL.Perform ( Base );
	
EndProcedure

&AtServer
Procedure sqlTask ()
	
	s = "
	|// @Fields
	|select Tasks.Memo as Memo, Tasks.Start as Start, Tasks.Finish as Finish, Tasks.Duration as Duration, Tasks.Minutes as Minutes,
	|	case when Tasks.Task then Tasks.Start else Tasks.Date end as Date
	|from Task.UserTask as Tasks
	|where Tasks.Ref = &Base
	|";
	Base.Selection.Add ( s );
	
EndProcedure 

&AtServer
Procedure fillDocumentByTask ()
	
	Object.Date = Base.Fields.Date;
	row = Object.Tasks.Add ();
	row.Description = Base.Fields.Memo;
	row.Duration = Base.Fields.Duration;
	row.Minutes = Base.Fields.Minutes;
	row.TimeEnd = CoreLibrary.DateToTime ( Base.Fields.Finish );
	row.TimeStart = CoreLibrary.DateToTime ( Base.Fields.Start );
	row.TimeType = Enums.Time.Billable;
	TimesheetForm.CalcTotalMinutes ( Object );
	
EndProcedure 

&AtServer
Procedure fillByEvent ()
	
	getEventData ();
	fillDocumentByEvent ();
	
EndProcedure

&AtServer
Procedure getEventData ()
	
	initBase ();
	sqlEvent ();
	SQL.Perform ( Base );
	
EndProcedure

&AtServer
Procedure sqlEvent ()
	
	s = "
	|// @Fields
	|select Events.Subject as Subject, Events.Content as Content, Events.Start as Start, Events.Finish as Finish,
	|	Events.Responsible as Responsible, Events.Organization as Customer, Events.Company as Company
	|from Document.Event as Events
	|where Events.Ref = &Base
	|";
	Base.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure fillDocumentByEvent ()
	
	Object.Event = Parameters.Basis;
	fields = Base.Fields;
	Object.Company = fields.Company;
	Object.Customer = fields.Customer;
	Object.Date = fields.Start;
	Object.Performer = fields.Responsible;
	TimesheetForm.SetEmployee ( Object );
	TimesheetForm.SetIndividual ( Object );
	row = Object.Tasks.Add ();
	parts = new Array ();
	parts.Add ( fields.Subject );
	content = fields.Content;
	if ( not IsBlankString ( content ) ) then
		parts.Add ( content );
	endif;
	row.Description = StrConcat ( parts, "; " );
	row.TimeStart = CoreLibrary.DateToTime ( fields.Start );
	row.TimeEnd = CoreLibrary.DateToTime ( fields.Finish );
	TimesheetForm.CalcMinutes ( row );
	row.TimeType = Enums.Time.Billable;
	TimesheetForm.CalcTotalMinutes ( Object );
	
EndProcedure

#endregion

&AtServer
Procedure fillNew ()
	
	if ( Copy ) then
		return;
	endif; 
	settings = Logins.Settings ( "Company, Warehouse" );
	Object.Company = settings.Company;
	Object.Warehouse = settings.Warehouse;
	if ( Object.Customer.IsEmpty ()
		and not Object.Project.IsEmpty () ) then
		Object.Customer = DF.Pick ( Object.Project, "Owner" );
	endif; 

EndProcedure

&AtServer
Procedure setDate ()
	
	if ( Object.Date = Date ( 1, 1, 1 ) ) then
		Object.Date = BegOfMinute ( CurrentSessionDate () );
	endif; 
	
EndProcedure 

&AtServer
Procedure setExistedTimeEntry ()
	
	if ( Object.Customer.IsEmpty ()
		or Object.Project.IsEmpty ()
		or Object.Employee.IsEmpty ()
		or Object.Date = Date ( 1, 1, 1 ) ) then
		return;
	endif; 
	ExistedTimeEntry = getExistedTimeEntry ();

EndProcedure 

&AtServer
Function getExistedTimeEntry ()
	
	s = "
	|select TimeEntries.Ref as Ref
	|from Document.TimeEntry as TimeEntries
	|where TimeEntries.Date between &DateStart and &DateEnd
	|and TimeEntries.Project = &Project
	|and TimeEntries.Employee = &Employee
	|and TimeEntries.Ref <> &CurrentTimeEntry
	|and not TimeEntries.DeletionMark
	|";
	q = new Query ( s );
	dateStart = BegOfDay ( ? ( Object.Date = Date ( 1, 1, 1 ), CurrentDate (), Object.Date ) );
	q.SetParameter ( "DateStart", dateStart );
	q.SetParameter ( "DateEnd", EndOfDay ( dateStart ) );
	q.SetParameter ( "Project", Object.Project );
	q.SetParameter ( "Employee", Object.Employee );
	q.SetParameter ( "CurrentTimeEntry", Object.Ref );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
EndFunction

&AtServer
Procedure setLinks ()
	
	SQL.Init ( Env );
	sqlLinks ();
	if ( Env.Selection.Count () = 0 ) then
		ShowLinks = false;
	else
		q = Env.Q;
		q.SetParameter ( "Ref", Object.Ref );
		q.SetParameter ( "DocumentOrder", Object.DocumentOrder );
		q.SetParameter ( "Timesheet", Timesheet );
		q.SetParameter ( "Event", Object.Event );
		SQL.Perform ( Env, false );
		setURLPanel ();
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	selection = Env.Selection;
	TimesheetExists = not Timesheet.IsEmpty ();
	orderType = TypeOf ( Object.DocumentOrder );
	SalesOrderExists = orderType = Type ( "DocumentRef.SalesOrder" );
	InternalOrderExists = orderType = Type ( "DocumentRef.InternalOrder" );
	EventExists = not Object.Event.IsEmpty ();
	if ( InternalOrderExists ) then
		s = "
		|// #InternalOrders
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.InternalOrder as Documents
		|where Documents.Ref = &DocumentOrder
		|";
		selection.Add ( s );
	elsif ( SalesOrderExists ) then
		s = "
		|// #SalesOrders
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.SalesOrder as Documents
		|where Documents.Ref = &DocumentOrder
		|";
		selection.Add ( s );
	endif;
	if ( TimesheetExists ) then
		s = "
		|// #Timesheet
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.Timesheet as Documents
		|where Documents.Ref = &Timesheet
		|";
		selection.Add ( s );
	endif;
	if ( EventExists ) then
		s = "
		|// #Event
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.Event as Documents
		|where Documents.Ref = &Event
		|";
		selection.Add ( s );
	endif;
	if ( isNew () ) then
		return;
	endif; 
	s = "
	|// #Invoices
	|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
	|from Document.Invoice as Documents
	|where Documents.TimeEntry = &Ref
	|";
	selection.Add ( s );
	
EndProcedure 

&AtServer
Function isNew ()
	
	return Object.Ref.IsEmpty ();
	
EndFunction

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	meta = Metadata.Documents;
	if ( TimesheetExists ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Timesheet, meta.Timesheet ) );
	endif; 
	if ( InternalOrderExists ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.InternalOrder, meta.InternalOrder ) );
	elsif ( SalesOrderExists ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.SalesOrder, meta.SalesOrder ) );
	endif; 
	if ( EventExists ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Event, meta.Event ) );
	endif; 
	if ( not isNew () ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Invoices, meta.Invoice ) );
	endif; 
	s = URLPanel.Build ( parts );
	if ( s = undefined ) then
		ShowLinks = false;
	else
		ShowLinks = true;
		Links = s;
	endif; 
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	saveOldDate ();

EndProcedure

&AtClient
Procedure saveOldDate ()
	
	OldDate = Object.Date;
	
EndProcedure 

&AtClient
Procedure ChoiceProcessing ( SelectedValue, ChoiceSource )
	
	if ( SelectedValue.Operation = Enum.ChoiceOperationsPickItems () ) then
		addSelectedItems ( SelectedValue );
	endif; 
	
EndProcedure

&AtClient
Procedure addSelectedItems ( Params )
	
	for each selectedRow in Params.Items do
		row = Object.Items.Add ();
		FillPropertyValues ( row, selectedRow );
	enddo; 
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageBarcodeScanned ()
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		addItem ( Parameter );
	elsif ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtServer
Procedure addItem ( Fields )
	
	search = new Structure ( "Item, Package, Feature" );
	FillPropertyValues ( search, Fields );
	rows = Object.Items.FindRows ( search );
	if ( rows.Count () = 0 ) then
		row = Object.Items.Add ();
		row.Item = Fields.Item;
		row.Package = Fields.Package;
		feature = Fields.Feature;
		row.Feature = feature;
		row.QuantityPkg = Fields.QuantityPkg;
		row.Capacity = Fields.Capacity;
		row.Quantity = Fields.Quantity;
	else
		row = rows [ 0 ];
		row.Quantity = row.Quantity + Fields.Quantity;
		row.QuantityPkg = row.QuantityPkg + Fields.QuantityPkg;
	endif; 
	
EndProcedure 

&AtClient
Procedure NewWriteProcessing ( NewObject, Source, StandardProcessing )
	
	readNewInvoices ( NewObject );
	
EndProcedure

&AtServer
Procedure readNewInvoices ( val NewObject ) 

	type = TypeOf ( NewObject );
	if ( type = Type ( "DocumentRef.Invoice" ) ) then
		setLinks ();
	endif;

EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( not checkExistedTimeEntry () ) then
		Cancel = true;
		Appearance.Apply ( ThisObject, "ExistedTimeEntry" );
		return;
	endif;
	Documents.TimeEntry.SetKeys ( CurrentObject );
	if ( NewSignature ) then
		saveSignature ( CurrentObject );
	endif;
	TimesheetForm.CalcBillableMinutes ( CurrentObject );
	setProperties ( CurrentObject, WriteParameters );
	
EndProcedure

&AtServer
Function checkExistedTimeEntry ()
	
	setExistedTimeEntry ();
	error = not ExistedTimeEntry.IsEmpty ();
	if ( error ) then
		Output.TimeEntryAlreadyExists ( new Structure ( "Date, Customer", Format ( Object.Date, "DLF=D" ), Object.Customer ), "Date" );
	endif; 
	return not error;
	
EndFunction 

&AtServer
Procedure saveSignature ( CurrentObject )
	
	CurrentObject.Signature = new ValueStorage ( GetFromTempStorage ( Signature ) );
	NewSignature = false;
	
EndProcedure 

&AtServer
Procedure setProperties ( CurrentObject, WriteParameters )
	
	if ( WriteParameters.Property ( "ChangedFromTimesheet" ) ) then
		CurrentObject.AdditionalProperties.Insert ( "ChangedFromTimesheet" );
	endif; 
	
EndProcedure 

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject, "Object.Ref" );
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	notifySystem ();
	
EndProcedure

&AtClient
Procedure notifySystem ()
	
	p = new Structure ( "Project, OldDate, NewDate, Event", Object.Project, OldDate, Object.Date, Object.Event );
	Notify ( Enum.MessageTimeEntryUpdated (), p );
	saveOldDate ();
	
EndProcedure 

&AtClient
Procedure OnClose ( Exit )
	
	#if ( MobileClient ) then
		notifySystem ();
	#endif
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DeleteTimeEntry ( Command )
	
	Output.RemoveTimeEntryConfirmation ( ThisObject );

EndProcedure

&AtClient
Procedure RemoveTimeEntryConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	if ( removeTimeEntry () ) then
		if ( TimesheetBase ) then
			notifyTimesheetAboutDeletion ();
			Modified = false;
			p = new Structure ();
			p.Insert ( "Command", "Delete" );
			p.Insert ( "Project", Object.Project );
			NotifyChoice ( p );
		else
			Close ();
		endif; 
	endif; 
	
EndProcedure 

&AtClient
Function removeTimeEntry ()
	
	Object.DeletionMark = true;
	writeParams = new Structure ( "WriteMode", DocumentWriteMode.UndoPosting );
	if ( TimesheetBase ) then
		writeParams.Insert ( "ChangedFromTimesheet" );
	endif; 
	if ( not Write ( writeParams ) ) then
		return false;
	endif; 
	removeDocument ( Object.Ref );
	return true;

EndFunction

&AtServerNoContext
Procedure removeDocument ( Ref )
	
	SetPrivilegedMode ( true );
	Ref.GetObject ().Delete ();
	SetPrivilegedMode ( false );
	
EndProcedure 

&AtClient
Procedure notifyTimesheetAboutDeletion ()
	
	Modified = false;
	p = new Structure ();
	p.Insert ( "Command", "Delete" );
	p.Insert ( "Project", Object.Project );
	NotifyChoice ( p );
	
EndProcedure

&AtClient
Procedure UpdateTimesheet ( Command )
	
	timeList = undefined;
	if ( not postDocument ( timeList ) ) then
		return;
	endif; 
	updateTimesheetTimeEntry ( timeList );
	
EndProcedure

&AtClient
Function postDocument ( TimeList )
	
	result = Write ( new Structure ( "WriteMode, ChangedFromTimesheet", DocumentWriteMode.Posting ) );
	if ( result ) then
		TimeList = getTimeList ();
	endif; 
	return result;
	
EndFunction 

&AtServer
Function getTimeList ()
	
	table = Object.Tasks.Unload ( , "TimeType, Minutes" );
	table.GroupBy ( "TimeType", "Minutes" );
	list = new Array ();
	for each row in table do
		list.Add ( new Structure ( "Time, Minutes", row.TimeType, row.Minutes ) );
	enddo; 
	return list;
	
EndFunction 

&AtClient
Procedure updateTimesheetTimeEntry ( TimeList )
	
	p = new Structure ();
	p.Insert ( "Command", "Update" );
	p.Insert ( "TimeEntry", Object.Ref );
	p.Insert ( "Project", Object.Project );
	p.Insert ( "Customer", Object.Customer );
	p.Insert ( "Time", TimeList );
	NotifyChoice ( p );
	
EndProcedure 

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

&AtClient
Procedure DateOnChange ( Item )

	applyDate ();	
	
EndProcedure

&AtServer
Procedure applyDate ()
	
	showExistedTimeEntry ();
	updateChangesPermission ()

EndProcedure

&AtServer
Procedure showExistedTimeEntry ()
	
	setExistedTimeEntry ();
	Appearance.Apply ( ThisObject, "ExistedTimeEntry" );
	
EndProcedure 

&AtClient
Procedure CustomerOnChange ( Item )
	
	applyCustomer ();
	
EndProcedure

&AtServer
Procedure applyCustomer ()
	
	setProjects ();
	setDefaultProject ();
	showExistedTimeEntry ();
	
EndProcedure 

&AtServer
Procedure setDefaultProject ()
	
	list = Items.Project.ChoiceList;
	if ( list.Count () = 1 ) then
		Object.Project = list [ 0 ].Value;
		applyProject ();
	endif; 
	
EndProcedure 

&AtServer
Procedure applyProject ()
	
	setTasks ();
	setTimeTypes ();
	showExistedTimeEntry ();
	Appearance.Apply ( ThisObject, "ProjectType" );
	
EndProcedure 

&AtClient
Procedure ProjectOnChange ( Item )
	
	applyProject ();
	
EndProcedure

&AtClient
Procedure PerformerOnChange ( Item )
	
	setTitle ( ThisObject );
	applyPerformer ();
	
EndProcedure

&AtServer
Procedure applyPerformer ()
	
	TimesheetForm.SetEmployee ( Object );
	TimesheetForm.SetIndividual ( Object );
	showExistedTimeEntry ();
	
EndProcedure 

&AtClient
Procedure LoadExistedTimeEntry ( Command )
	
	loadExistedTimeEntryDocument ();
	
EndProcedure

&AtServer
Procedure loadExistedTimeEntryDocument ()
	
	ValueToFormAttribute ( ExistedTimeEntry.GetObject (), "Object" );
	setTitle ( ThisObject );
	setTimesheet ();
	fillTimeTypes ();
	ExistedTimeEntry = undefined;
	Modified = false;
	Appearance.Apply ( ThisObject );
	
EndProcedure 

&AtClient
Procedure LoadSignature ( Command )
	
	uploadSignature ();
	
EndProcedure

&AtClient
Procedure uploadSignature ()
	
	callback = new NotifyDescription ( "StartUploading", ThisObject );
	LocalFiles.Prepare ( callback );
	
EndProcedure 

&AtClient
Procedure StartUploading ( Result, Params ) export
	
	BeginPutFile ( new NotifyDescription ( "CompleteUpload", ThisObject ), , , true, UUID );
	
EndProcedure 

&AtClient
Procedure CompleteUpload ( Result, Address, FileName, Params ) export
	
	if ( not Result ) then
		return;
	endif; 
	if ( not FileSystem.Picture ( FileName ) ) then
		return;
	endif; 
	Signature = Address;
	Modified = true;
	NewSignature = true;
	Appearance.Apply ( ThisObject, "Signature" );

EndProcedure 

// *****************************************
// *********** Group Tasks

&AtClient
Procedure LoadTasks ( Command )
	
	if ( not Forms.Check ( ThisObject, "Project, Performer" ) ) then
		return;
	endif; 
	fillTasks ();
	TimesheetForm.CalcTotalMinutes ( Object );
	
EndProcedure

&AtServer
Procedure fillTasks ()
	
	table = getTasks ();
	if ( table.Count () = 0 ) then
		Output.TasksNotFound ( , "Performer" );
		return;
	endif; 
	for each row in table do
		taskRow = Object.Tasks.Add ();
		FillPropertyValues ( taskRow, row );
		taskRow.TimeStart = getTimeStart ( ThisObject, taskRow );
		taskRow.TimeEnd = taskRow.TimeStart + taskRow.Minutes * 60;
	enddo; 
	
EndProcedure 

&AtServer
Function getTasks ()
	
	s = "
	|select Tasks.Task as Task, Tasks.Description as Description, Tasks.Duration as Duration, Tasks.Minutes as Minutes, Tasks.TimeType as TimeType
	|from Catalog.Projects.Tasks as Tasks
	|where Tasks.Ref = &Project
	|and Tasks.Employee = &Employee
	|order by Tasks.LineNumber
	|";
	q = new Query ( s );
	q.SetParameter ( "Project", Object.Project );
	q.SetParameter ( "Employee", Object.Employee );
	return q.Execute ().Unload ();
	
EndFunction

&AtClientAtServerNoContext
Function getTimeStart ( Form, Row )
	
	object = Form.Object;
	i = object.Tasks.IndexOf ( Row );
	if ( i = 0 ) then
		return roundTime ( object.Date );
	else
		previousRow = object.Tasks.Get ( i - 1 );
		if ( previousRow.TimeEnd <> Date ( 1, 1, 1 ) ) then
			return previousRow.TimeEnd;
		endif; 
	endif; 
	
EndFunction

&AtClientAtServerNoContext
Function roundTime ( TimeValue )
	
	seconds = Second ( TimeValue );
	return Date ( 1, 1, 1 ) + Hour ( TimeValue ) * 3600 + Minute ( TimeValue ) * 60 + ? ( seconds < 30, 0, 60 );
	
EndFunction

&AtClient
Procedure StartTimer ( Command )
	
	startTimeCounter ();
	setCurrentItem ( Items.Description );
	
EndProcedure

&AtClient
Procedure startTimeCounter ()
	
	TimerStarted = true;
	dateStart = SessionDate ();
	TimeOffset = dateStart - CurrentDate ();
	Start = dateStart;
	Duration = Date ( 1, 1, 1 );
	Appearance.Apply ( ThisObject, "TimerStarted" );
	AttachIdleHandler ( "tick", 1 );
	
EndProcedure 

&AtClient
Procedure setCurrentItem ( Item )
	
	CurrentItem = Item;

EndProcedure 

&AtClient
Procedure tick ()
	
	Duration = Date ( 1, 1, 1 ) + ( ( CurrentDate () - Start ) + TimeOffset );
	
EndProcedure 

&AtClient
Procedure StopTimer ( Command )
	
	detachTimer ();
	addTimeline ();
	updateTimerButtonsStronglyAfterActivatingRow ();
	
EndProcedure

&AtClient
Procedure detachTimer ()
	
	TimerStarted = false;
	DetachIdleHandler ( "tick" );
	
EndProcedure 

&AtClient
Procedure addTimeline ()
	
	row = Object.Tasks.Add ();
	row.TimeStart = roundTime ( Start );
	row.TimeEnd = roundTime ( SessionDate () );
	row.Description = Items.Description.EditText;
	setTimeType ( row );
	TimesheetForm.CalcMinutes ( row );
	Items.Tasks.CurrentRow = row.GetID ();
	setCurrentItem ( Items.Tasks );
	Items.Tasks.CurrentItem = Items.TasksDescription;
	Items.Tasks.ChangeRow ();

EndProcedure 

&AtClient
Procedure setTaskByDefault ( Row )
	
	list = Items.TasksTask.ChoiceList;
	if ( list.Count () > 0 ) then
		Row.Task = list [ 0 ].Value;
	endif; 
	
EndProcedure 

&AtClient
Procedure updateTimerButtonsStronglyAfterActivatingRow ();
	
	Appearance.Apply ( ThisObject, "TimerStarted" );

EndProcedure

&AtClient
Procedure CancelTimer ( Command )
	
	detachTimer ();
	
EndProcedure

&AtClient
Procedure TasksOnStartEdit ( Item, NewRow, Clone )
	
	if ( Clone ) then
		TasksRow.RowKey = undefined;
	elsif ( NewRow ) then
		setTaskByDefault ( TasksRow );
		setTimeType ( TasksRow );
		TasksRow.TimeStart = getTimeStart ( ThisObject, TasksRow );
	endif; 
	
EndProcedure

&AtClient
Procedure TasksOnEditEnd ( Item, NewRow, CancelEdit )
	
	TimesheetForm.CalcTotalMinutes ( Object );
	
EndProcedure

&AtClient
Procedure TasksBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	Output.RecordRemovingConfirmation ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure RecordRemovingConfirmation ( Answer, Item ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		Modified = true;
		Forms.DeleteSelectedRows ( Object.Tasks, Item );
		TimesheetForm.CalcTotalMinutes ( Object );
	endif; 
	
EndProcedure 

&AtClient
Procedure TasksTimeStartOnChange ( Item )
	
	adjustTimeEnd ();
	TimesheetForm.CalcMinutes ( TasksRow );
	
EndProcedure

&AtClient
Procedure adjustTimeEnd ()
	
	if ( TasksRow.TimeStart >= TasksRow.TimeEnd ) then
		TasksRow.TimeEnd = undefined;
	endif;
	
EndProcedure

&AtClient
Procedure TasksTimeEndOnChange ( Item )
	
	adjustTimeStart ();
	TimesheetForm.CalcMinutes ( TasksRow );
	
EndProcedure

&AtClient
Procedure adjustTimeStart ()
	
	if ( TasksRow.TimeEnd <= TasksRow.TimeStart ) then
		TasksRow.TimeStart = undefined;
	endif;
	
EndProcedure

&AtClient
Procedure TasksDurationOnChange ( Item )
	
	Conversion.AdjustTime ( TasksRow.Duration );
	calcMinutesByDuration ( TasksRow );
	
EndProcedure

&AtClient
Procedure calcMinutesByDuration ( Row )
	
	Row.Minutes = Conversion.DurationToMinutes ( Row.Duration );
	
EndProcedure 

&AtClient
Procedure TasksOnActivateRow ( Item )
	
	TasksRow = Items.Tasks.CurrentData;
	
EndProcedure

&AtClient
Procedure TasksTaskOnChange ( Item )
	
	setTimeType ( TasksRow );
	
EndProcedure

&AtClient
Procedure setTimeType ( Row )
	
	if ( timeFromTimesheet () ) then
		Row.TimeType = TimesheetTime;
	else
		task = Row.Task;
		rows = ProjectTime.FindRows ( new Structure ( "Task", task ) );
		if ( rows.Count () = 0 ) then
			if ( task.IsEmpty () ) then
				Row.TimeType = Items.TasksTimeType.ChoiceList [ 0 ].Value;
			else
				taskBillabe = DF.Pick ( task, "Billable" );
				if ( taskBillabe ) then
					Row.TimeType = PredefinedValue ( "Enum.Time.Billable" );
				else
					Row.TimeType = PredefinedValue ( "Enum.Time.NonBillable" );
				endif; 
			endif; 
		else
			Row.TimeType = rows [ 0 ].Time;
		endif; 
	endif; 
	
EndProcedure 

&AtClient
Function timeFromTimesheet ()
	
	return TimesheetBase
	and not TimesheetTime.IsEmpty ();
	
EndFunction 

&AtClient
Procedure TasksDescriptionOpening ( Item, StandardProcessing )
	
	StandardProcessing = false;
	ShowInputString ( new NotifyDescription ( "SetTaskDescription", ThisObject, TasksRow ), TasksRow.Description, , , true );
	
EndProcedure

&AtClient
Procedure SetTaskDescription ( Text, Row ) export
	
	if ( Text = undefined ) then
		return;
	endif; 
	Row.Description = Text;
	Modified = true;
	
EndProcedure 

// *****************************************
// *********** Table Items

&AtClient
Procedure Scan ( Command )
	
	ScanForm.Open ( ThisObject, true );
	
EndProcedure

&AtClient
Procedure SelectItems ( Command )
	
	PickItems.Open ( ThisObject, pickParams () );
	
EndProcedure

&AtServer
Function pickParams ()
	
	return PickItems.GetParams ( ThisObject );
	
EndFunction 

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ItemsItemOnChange ( Item )
	
	applyItem ();
	
EndProcedure

&AtClient
Procedure applyItem ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Company", Object.Company );
	p.Insert ( "Warehouse", Object.Warehouse );
	p.Insert ( "Item", ItemsRow.Item );
	data = getItemData ( p );
	ItemsRow.Package = data.Package;
	ItemsRow.Capacity = data.Capacity;
	Computations.Units ( ItemsRow );
	
EndProcedure 

&AtServerNoContext
Function getItemData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "Package, Package.Capacity as Capacity" );
	if ( data.Capacity = 0 ) then
		data.Capacity = 1;
	endif; 
	return data;
	
EndFunction 

&AtClient
Procedure ItemsPackageOnChange ( Item )
	
	applyPackage ();
	
EndProcedure

&AtClient
Procedure applyPackage ()
	
	ItemsRow.Capacity = DF.Pick ( ItemsRow.Package, "Capacity", 1 );
	Computations.Units ( ItemsRow );
	
EndProcedure 

&AtClient
Procedure ItemsQuantityPkgOnChange ( Item )
	
	Computations.Units ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	
EndProcedure

// *****************************************
// *********** Group Signature

&AtClient
Procedure TakeSignature ( Command )
	
	signatureForm ();
	
EndProcedure

&AtClient
Procedure signatureForm ()
	
	callback = new NotifyDescription ( "SignatureTaken", ThisObject );
	OpenForm ( "DataProcessor.Signature.Form", , ThisObject, , , , callback );
	
EndProcedure 

&AtClient
Procedure SignatureTaken ( Data, Params ) export
	
	if ( Data = undefined ) then
		return;
	endif; 
	Signature = PutToTempStorage ( Data, UUID );
	NewSignature = true;
	Appearance.Apply ( ThisObject, "Signature" );
	
EndProcedure 

&AtClient
Procedure ShowSignature ( Command )
	
	OpenForm ( "CommonForm.Signature", new Structure ( "Signature, Title", Signature, Object.Signer ) );
	
EndProcedure

&AtClient
Procedure SignerOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Signature" );
	
EndProcedure
