&AtClient
var TagRow;
&AtClient
var OldTag;
&AtClient
var OldDateStart;
&AtClient
var OldDateEnd;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	setCloud ();
	Catalogs.Projects.ReadJunctions ( Object.Ref, Tables, false );
	setFlags ( ThisObject );
	setAccessRightsFlags ();
	setCanChangeApprovalList ();
	if ( Clouds ) then
		initEditor ( CurrentObject );
	endif;
	Appearance.Apply ( ThisObject );
		
EndProcedure

&AtServer
Procedure setCloud ()
	
	Clouds = Cloud.Cloud ();
	
EndProcedure

&AtClientAtServerNoContext
Procedure setFlags ( Form )
	
	object = Form.Object;
	Form.AmountAllowed = false;
	Form.HourlyRateAllowed = false;
	Form.HoursAllowed = false;
	Form.TasksAmountAllowed = false;
	Form.TasksHourlyRateAllowed = false;
	Form.TasksHoursAllowed = false;
	Form.TasksAmountVisible = false;
	if ( object.Pricing = PredefinedValue ( "Enum.ProjectsPricing.Amount" ) ) then
		Form.AmountAllowed = true;
		Form.HourlyRateAllowed = true;
		Form.HoursAllowed = true;
	elsif ( object.Pricing = PredefinedValue ( "Enum.ProjectsPricing.HourlyRate" ) ) then
		Form.HourlyRateAllowed = true;
		Form.TasksHoursAllowed = true;
		Form.TasksAmountVisible = true;
	elsif ( object.Pricing = PredefinedValue ( "Enum.ProjectsPricing.Tasks" )
		or object.Pricing = PredefinedValue ( "Enum.ProjectsPricing.Employees" ) ) then
		Form.TasksAmountAllowed = true;
		Form.TasksHourlyRateAllowed = true;
		Form.TasksHoursAllowed = true;
		Form.TasksAmountVisible = true;
	endif; 
	
EndProcedure 

&AtServer
Procedure setAccessRightsFlags ()
	
	admin = Logins.Admin ();
	HourlyCostEdit = admin or IsInRole ( "HourlyCostEdit" );
	HourlyRatesEdit = admin or IsInRole ( "HourlyRatesEdit" );
	
EndProcedure 

&AtServer
Procedure setCanChangeApprovalList ()
	
	if ( Object.Ref.IsEmpty () ) then
		CanChangeApprovalList = true;
	elsif ( not Object.UseApprovingProcess ) then
		CanChangeApprovalList = true;
	else
		CanChangeApprovalList = not existActiveTimesheetApproval ();
	endif; 
	
EndProcedure 

&AtServer
Function existActiveTimesheetApproval ()
	
	s = "
	|select top 1 1
	|from BusinessProcess.TimesheetApproval as TimesheetApproval
	|where TimesheetApproval.Project = &Project
	|and TimesheetApproval.Started
	|and not TimesheetApproval.Completed
	|and not TimesheetApproval.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "Project", Object.Ref );
	return q.Execute ().Select ().Next ();
	
EndFunction 

&AtServer
Procedure initEditor ( CurrentObject )

	TextEditor.SetHTML ( CurrentObject.Data.Get (), new Structure () );
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	Forms.RedefineOpeningModeForLinux ( ThisObject );
	if ( Object.Ref.IsEmpty () ) then
		setCloud ();
		setAccessRightsFlags ();
		setFlags ( ThisObject );
		copyingValue = Parameters.CopyingValue;
		if ( copyingValue.IsEmpty () ) then
			fillNew ();
		else
			Catalogs.Projects.ReadJunctions ( copyingValue, Tables );
		endif; 
		setCanChangeApprovalList ();
		if ( Parameters.Email <> undefined ) then
			fillByEmail ();
		endif;
	endif; 
	setCanChange ();
	setEmailVisible ();
	setProjectsList ();
	setPricingList ();
	setOurCompany ();
	setCurrentItem ();
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|HourlyRate enable HourlyRateAllowed;
	|Duration enable HoursAllowed;
	|Amount lock not AmountAllowed;
	|CompletionDate lock not Object.Completed;
	|ApprovalList enable Object.UseApprovingProcess and CanChangeApprovalList;
	|ApprovalListGroup enable Object.UseApprovingProcess;
	|ApprovalListWarning show not CanChangeApprovalList;
	|UseApprovingProcess enable CanChangeApprovalList;
	|Email show EmailVisible;
	|TextEditor Attachments Tags enable CanChange;
	|ObligatoryTasks enable Object.ProjectType = Enum.ProjectTypes.Regular;
	|ProjectType enable Object.Owner = OurCompany;
	|TasksHourlyRate show TasksHourlyRateAllowed;
	|TasksDuration show TasksHoursAllowed;
	|TasksAmount TasksTimeType show TasksAmountVisible;
	|TasksAmount lock not TasksAmountAllowed;
	|TasksTask TasksTimeType show Object.ProjectType = Enum.ProjectTypes.Regular;
	|EditorPage show Clouds;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	Catalogs.Projects.SetFolder ( Object );
	settings = Logins.Settings ( "Company" );
	Object.Company = settings.Company;
	Object.Manager = DF.Pick ( SessionParameters.User, "Employee" );
	Object.Appearance = Catalogs.CalendarAppearance.Projects;
	Object.DateStart = CurrentSessionDate ();
	if ( not Object.Owner.IsEmpty () ) then
		setCurrency ();
	endif; 
	if ( Object.Currency.IsEmpty () ) then
		Object.Currency = Application.Currency ();
	endif; 
	loadPerformers ();
	
EndProcedure 

&AtServer
Procedure loadPerformers ()
	
	performers = Parameters.Performers;
	if ( performers = undefined ) then
		return;
	endif;
	for each performer in performers do
		row = Object.Tasks.Add ();
		defaultTimeType ( Object, row );
		row.Employee = DF.Pick ( performer, "Employee" );
		applyEmployee ( ThisObject, row );
	enddo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure defaultTimeType ( Object, Row )
	
	Row.TimeType = getTimeType ( Object );
	
EndProcedure 

&AtClientAtServerNoContext
Procedure applyEmployee ( Form, Row )
	
	if ( not ( Form.HourlyCostEdit and Form.HourlyRatesEdit ) ) then
		return;
	endif; 
	if ( Form.Object.Pricing = PredefinedValue ( "Enum.ProjectsPricing.Amount" ) ) then
		return;
	endif; 
	fillRowByEmployee ( Form, Row );
	calcAmountByTask ( Form, Row );
	
EndProcedure

&AtClientAtServerNoContext
Procedure fillRowByEmployee ( Form, Row )
	
	p = new Structure ();
	p.Insert ( "TimeType", Row.TimeType );
	p.Insert ( "Employee", Row.Employee );
	object = Form.Object;
	p.Insert ( "Currency", object.Currency );
	p.Insert ( "Pricing", object.Pricing );
	p.Insert ( "DateStart", object.DateStart );
	p.Insert ( "HourlyRatesEdit", Form.HourlyRatesEdit );
	p.Insert ( "HourlyCostEdit", Form.HourlyCostEdit );
	fields = getFieldsByEmployee ( p );
	FillPropertyValues ( Row, fields );
	
EndProcedure 

&AtServerNoContext
Function getFieldsByEmployee ( val Params )
	
	fields = new Structure ();
	fieldsData = "Currency";
	if ( Params.HourlyRatesEdit ) then
		fields.Insert ( "HourlyRate" );
		fieldsData = fieldsData + ", HourlyRate";
	endif; 
	if ( Params.HourlyCostEdit ) then
		fields.Insert ( "HourlyCost" );
		fieldsData = fieldsData + ", HourlyCost";
	endif; 
	data = DF.Values ( Params.Employee, fieldsData );
	if ( Params.HourlyRatesEdit ) then
		setHourlyRate ( fields, Params, data );
	endif;
	if ( Params.HourlyCostEdit ) then
		setHourlyCost ( fields, Params, data );
	endif;
	return fields;
	
EndFunction 

&AtServerNoContext
Procedure setHourlyRate ( Fields, Params, Data )
	
	if ( Params.TimeType = Enums.Time.Billable ) then
		if ( Params.Pricing = Enums.ProjectsPricing.Employees ) then
			Fields.HourlyRate = Currencies.Convert ( Data.HourlyRate, Data.Currency, Params.Currency, Params.DateStart );
		endif; 
	else
		Fields.HourlyRate = 0;
	endif; 

EndProcedure 

&AtServerNoContext
Procedure setHourlyCost ( Fields, Params, Data )
	
	Fields.HourlyCost = Currencies.Convert ( Data.HourlyCost, Data.Currency, Params.Currency, Params.DateStart );

EndProcedure 

&AtServer
Procedure fillByEmail ()
	
	data = DF.Values ( Parameters.Email, "Subject" );
	Object.Email = Parameters.Email;
	Object.Description = data.Subject;
	
EndProcedure 

&AtServer
Procedure setCanChange ()
	
	CanChange = AccessRight ( "Edit", Object.Ref.Metadata () );
	
EndProcedure

&AtServer
Procedure setEmailVisible ()
	
	SetPrivilegedMode ( true );
	EmailVisible = Object.Email <> undefined and DF.Pick ( Object.Email, "Creator" ) = SessionParameters.User;
	SetPrivilegedMode ( false );
	
EndProcedure 

&AtServer
Procedure setProjectsList ()
	
	list = Items.ProjectType.ChoiceList;
	list.Clear ();
	list.Add ( Enums.ProjectTypes.Regular );
	if ( Object.Owner = DF.Pick ( Object.Company, "Organization" ) ) then
		list.Add ( Enums.ProjectTypes.Vacations );
		list.Add ( Enums.ProjectTypes.SickDays );
		list.Add ( Enums.ProjectTypes.Holidays );
	endif; 
	
EndProcedure 

&AtServer
Procedure setPricingList ()
	
	allowed = AccessRight ( "View", Metadata.Catalogs.Projects.Attributes.Pricing );
	if ( not allowed ) then
		return;
	endif; 
	pricing = Enums.ProjectsPricing;
	list = Items.Pricing.ChoiceList;
	list.Clear ();
	list.Add ( pricing.Amount );
	list.Add ( pricing.HourlyRate );
	list.Add ( pricing.Employees );
	if ( Object.ProjectType = Enums.ProjectTypes.Regular ) then
		list.Add ( pricing.Tasks );
	endif; 
	
EndProcedure 

&AtServer
Procedure setOurCompany ()
	
	OurCompany = DF.Pick ( Object.Company, "Organization" );
	
EndProcedure 

&AtServer
Procedure setCurrentItem ()
	
	if ( Object.Owner.IsEmpty () ) then
		CurrentItem = Items.Owner;
	else
		CurrentItem = Items.Description;
	endif;
	
EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	savePeriod ();

EndProcedure

&AtClient
Procedure savePeriod ()
	
	OldDateStart = Object.DateStart;
	OldDateEnd = Object.DateEnd;
	
EndProcedure 

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	calcProjectTotals ( CurrentObject );
	storeContent ( CurrentObject );
	
EndProcedure

&AtServer
Procedure calcProjectTotals ( CurrentObject )
	
	cost = 0;
	paidMinutes = 0;
	for each row in CurrentObject.Tasks do
		if ( Object.Pricing = Enums.ProjectsPricing.Amount ) then
			cost = cost + Object.Minutes * row.HourlyCost / 60;
		else
			cost = cost + row.Minutes * row.HourlyCost / 60;
		endif; 
		if ( row.TimeType = Enums.Time.Billable ) then
			paidMinutes = paidMinutes + row.Minutes;
		endif; 
	enddo; 
	if ( CurrentObject.Pricing = Enums.ProjectsPricing.Amount ) then
		paidMinutes = CurrentObject.Minutes;
	endif; 
	CurrentObject.Cost = cost;
	CurrentObject.PaidMinutes = paidMinutes;
	
EndProcedure 

&AtServer
Procedure storeContent ( CurrentObject )
	
	CurrentObject.Content = new ValueStorage ( TextEditor.GetText () );
	CurrentObject.Data = new ValueStorage ( FD.GetHTML ( TextEditor ) );
	
EndProcedure 

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( not checkTaskDoubles ( CurrentObject ) ) then
		Cancel = true;
		return;
	endif; 
	if ( Object.Ref.IsEmpty () ) then
		Catalogs.Projects.SaveJunctions ( CurrentObject.Ref, Tables );
	endif; 
	
EndProcedure

&AtServer
Function checkTaskDoubles ( CurrentObject )
	
	doubles = getTasksDoubles ( CurrentObject );
	if ( doubles.Count () > 0 ) then
		for each row in doubles do
			Output.DoublesEmployeesAndTasks ( , Output.Row ( "Tasks", row.LineNumber, "Employee" ) );
		enddo; 
		return false;
	endif; 
	return true;
	
EndFunction 

&AtServer
Function getTasksDoubles ( CurrentObject )
	
	s = "
	|select max ( Tasks.LineNumber ) as LineNumber
	|from Catalog.Projects.Tasks as Tasks
	|	left join Catalog.Projects.Tasks as Doubles
	|	on Doubles.Ref = &Ref
	|	and Doubles.Employee = Tasks.Employee
	|	and Doubles.Task = Tasks.Task
	|where Tasks.Ref = &Ref
	|and ( Doubles.HourlyRate <> Tasks.HourlyRate
	|or Doubles.HourlyCost <> Tasks.HourlyCost )
	|having max ( Tasks.LineNumber ) is not null
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", CurrentObject.Ref );
	SetPrivilegedMode ( true );
	table = q.Execute ().Unload ();
	SetPrivilegedMode ( false );
	return table;
	
EndFunction 

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	if ( Parameters.Email <> undefined ) then
		attachEmail ( CurrentObject );
	endif; 
	
EndProcedure

&AtServer
Procedure attachEmail ( CurrentObject )
	
	r = InformationRegisters.ProjectsAndEmails.CreateRecordManager ();
	r.Project = CurrentObject.Ref;
	r.Email = Parameters.Email;
	r.Write ();
	
EndProcedure 

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	notifySystem ();
	
EndProcedure

&AtClient
Procedure notifySystem ()
	
	p = new Structure ( "OldDateStart, NewDateStart, OldDateEnd, NewDateEnd", OldDateStart, Object.DateStart, OldDateEnd, Object.DateEnd );
	Notify ( Enum.MessageProjectChanged (), p );
	savePeriod ();
	if ( Parameters.Email <> undefined ) then
		NotifyChanged ( Type ( "InformationRegisterRecordKey.ProjectsAndEmails" ) );
	endif; 
	
EndProcedure 

&AtClient
Procedure OnClose ( Exit )
	
	if ( Exit ) then
		return;
	endif; 
	if ( Object.Ref.IsEmpty () ) then
		CKEditorSrv.Clean ( Object.FolderID );
	endif; 
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure OwnerOnChange ( Item )
	
	applyCustomer ();
	
EndProcedure

&AtServer
Procedure applyCustomer ()
	
	setProjectType ();
	applyProjectType ();
	setCurrency ();
	Appearance.Apply ( ThisObject, "Object.Owner" );
	
EndProcedure 

&AtServer
Procedure setProjectType ()
	
	setProjectsList ();
	Object.ProjectType = Enums.ProjectTypes.Regular;
	
EndProcedure 

&AtServer
Procedure applyProjectType ()
	
	setPricingList ();
	adjustPricing ();
	adjustTasks ();
	Appearance.Apply ( ThisObject, "Object.ProjectType" );
	
EndProcedure 

&AtServer
Procedure adjustPricing ()
	
	if ( Object.Pricing = Enums.ProjectsPricing.Tasks
		and Object.ProjectType <> Enums.ProjectTypes.Regular ) then
		Object.Pricing = Enums.ProjectsPricing.HourlyRate;
	endif; 
	
EndProcedure 

&AtServer
Procedure adjustTasks ()
	
	projectType = Object.ProjectType;
	time = getTimeType ( Object );
	for each row in Object.Tasks do
		row.TimeType = time;
	enddo; 
	if ( projectType <> Enums.ProjectTypes.Regular ) then
		Object.ObligatoryTasks = false;
		for each row in Object.Tasks do
			row.Task = undefined;
		enddo; 
	endif; 
	
EndProcedure 

&AtClientAtServerNoContext
Function getTimeType ( Object )
	
	projectType = Object.ProjectType;
	if ( projectType = PredefinedValue ( "Enum.ProjectTypes.Holidays" ) ) then
		return PredefinedValue ( "Enum.Time.Holiday" );
	elsif ( projectType = PredefinedValue ( "Enum.ProjectTypes.SickDays" ) ) then
		return PredefinedValue ( "Enum.Time.Sickness" );
	elsif ( projectType = PredefinedValue ( "Enum.ProjectTypes.Vacations" ) ) then
		return PredefinedValue ( "Enum.Time.Vacation" );
	else
		return PredefinedValue ( "Enum.Time.Billable" );
	endif; 
	 
EndFunction 

&AtServer
Procedure setCurrency ()
	
	if ( not ( HourlyCostEdit and HourlyRatesEdit ) ) then
		return;
	endif; 
	currency = DF.Pick ( Object.Owner, "CustomerContract.Currency" );
	if ( not currency.IsEmpty () ) then
		Object.Currency = currency;
	endif;
	
EndProcedure 

&AtClient
Procedure ProjectTypeOnChange ( Item )
	
	applyProjectType ();
	
EndProcedure

&AtClient
Procedure PricingOnChange ( Item )
	
	setFlags ( ThisObject );
	resetFields ();
	recalcProjectAmount ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtClient
Procedure resetFields ()
	
	if ( Object.Pricing = PredefinedValue ( "Enum.ProjectsPricing.Amount" ) ) then
		resetTasksColumn ( "HourlyRate, Minutes, Duration, Amount" );
	elsif ( Object.Pricing = PredefinedValue ( "Enum.ProjectsPricing.HourlyRate" ) ) then
		resetTasksColumn ( "HourlyRate" );
	else
		Object.HourlyRate = 0;
	endif; 
	
EndProcedure 

&AtClient
Procedure resetTasksColumn ( Columns )
	
	columnsArray = Conversion.StringToArray ( Columns );
	for each row in Object.Tasks do
		for each column in columnsArray do
			row [ column ] = 0;
		enddo; 
	enddo; 
	
EndProcedure 

&AtClient
Procedure recalcProjectAmount ()
	
	if ( AmountAllowed ) then
		calcAmount ();
	else
		recalcAmountAndHourlyRate ();
		calcTotalAmountByTasks ();
	endif; 
	
EndProcedure 

&AtClient
Procedure calcAmount ()
	
	Object.Amount = Object.HourlyRate * Object.Minutes / 60;
	
EndProcedure 

&AtServer
Procedure recalcAmountAndHourlyRate ()
	
	for each row in Object.Tasks do
		recalcHourlyRateByTask ( ThisObject, row );
		calcAmountByTask ( ThisObject, row );
	enddo; 
	
EndProcedure 

&AtClientAtServerNoContext
Procedure recalcHourlyRateByTask ( Form, Row )
	
	object = Form.Object;
	if ( Row.TimeType = PredefinedValue ( "Enum.Time.Billable" ) ) then
		if ( object.Pricing = PredefinedValue ( "Enum.ProjectsPricing.Employees" ) ) then
			Row.HourlyRate = getHourlyRate ( Row.Employee, object.Currency, object.DateStart );
		elsif ( object.Pricing = PredefinedValue ( "Enum.ProjectsPricing.Tasks" ) ) then
			Row.HourlyRate = getHourlyRate ( Row.Task, object.Currency, object.DateStart );
		endif; 
	else
		Row.HourlyRate = 0;
	endif; 
	
EndProcedure 

&AtServerNoContext
Function getHourlyRate ( val EmployeeOrTask, val Currency, val DateStart )
	
	tariffStruct = DF.Values ( EmployeeOrTask, "Currency, HourlyRate" );
	return Currencies.Convert ( tariffStruct.HourlyRate, tariffStruct.Currency, Currency, DateStart );
	
EndFunction 

&AtClient
Procedure CurrencyOnChange ( Item )
	
	recalcProjectAmount ();
	
EndProcedure

&AtClient
Procedure HourlyRateOnChange ( Item )
	
	recalcProjectAmount ();
	
EndProcedure

&AtClientAtServerNoContext
Procedure calcAmountByTask ( Form, Row )
	
	object = Form.Object;
	if ( Row.TimeType = PredefinedValue ( "Enum.Time.Billable" ) ) then
		if ( Form.TasksHourlyRateAllowed ) then
			Row.Amount = Row.HourlyRate * Row.Minutes / 60;
		else
			Row.Amount = object.HourlyRate * Row.Minutes / 60;
		endif;
	else
		Row.Amount = 0;
	endif; 
	
EndProcedure 

&AtClient
Procedure calcTotalAmountByTasks ()
	
	if ( not HourlyRatesEdit ) then
		return;
	endif; 
	Object.Amount = Object.Tasks.Total ( "Amount" );
	
EndProcedure 

&AtClient
Procedure DurationOnChange ( Item )
	
	Conversion.AdjustTime ( Object.Duration );
	calcMinutes ( Object );
	calcAmount ();
	
EndProcedure

&AtClient
Procedure calcMinutes ( Data )
	
	Data.Minutes = Conversion.DurationToMinutes ( Data.Duration );
	
EndProcedure 

&AtClient
Procedure AmountOnChange ( Item )
	
	calcHourlyRate ( Object );
	
EndProcedure

&AtClient
Procedure calcHourlyRate ( Data )
	
	Data.HourlyRate = Data.Amount / ? ( Data.Minutes = 0, 1, Data.Minutes / 60 );
	
EndProcedure 

&AtClient
Procedure CompletedOnChange ( Item )
	
	setCompletionDate ();
	Appearance.Apply ( ThisObject, "Object.Completed" );
	
EndProcedure

&AtClient
Procedure setCompletionDate ()
	
	if ( Object.Completed ) then
		Object.CompletionDate = SessionDate ();
	else
		Object.CompletionDate = undefined;
	endif; 
	
EndProcedure 

&AtClient
Procedure TextEditorDocumentComplete ( Item )
	
	EditorBegun = true;
	
EndProcedure

// *****************************************
// *********** Group Tasks

&AtClient
Procedure TasksOnStartEdit ( Item, NewRow, Clone )
	
	if ( Clone or not NewRow ) then
		return;
	endif; 
	defaultTimeType ( Object, Item.CurrentData )
	
EndProcedure

&AtClient
Procedure TasksOnEditEnd ( Item, NewRow, CancelEdit )
	
	calcTotals ();
	
EndProcedure

&AtClient
Procedure calcTotals ()
	
	if ( TasksAmountVisible ) then
		calcTotalAmountByTasks ();
	endif;
	if ( TasksHoursAllowed ) then
		calcTotalMinutesByTasks ();
	endif;
	
EndProcedure 

&AtClient
Procedure calcTotalMinutesByTasks ()
	
	Object.Minutes = Object.Tasks.Total ( "Minutes" );
	Object.Duration = Conversion.MinutesToDuration ( Object.Minutes );
	
EndProcedure 

&AtClient
Procedure TasksAfterDeleteRow ( Item )
	
	calcTotals ();
	
EndProcedure

&AtClient
Procedure TasksEmployeeOnChange ( Item )
	
	applyEmployee ( ThisObject, Items.Tasks.CurrentData );
	
EndProcedure

&AtClient
Procedure TasksTaskOnChange ( Item )
	
	if ( not HourlyRatesEdit ) then
		return;
	endif; 
	currentData = Items.Tasks.CurrentData;
	if ( Object.Pricing = PredefinedValue ( "Enum.ProjectsPricing.Tasks" ) ) then
		fillRowByTask ( currentData );
	else
		setTimeType ( currentData );
	endif;  
	calcAmountByTask ( ThisObject, currentData );
	
EndProcedure

&AtClient
Procedure fillRowByTask ( Row )
	
	p = new Structure ();
	p.Insert ( "Task", Row.Task );
	p.Insert ( "Currency", Object.Currency );
	p.Insert ( "DateStart", Object.DateStart );
	fields = getFieldsByTask ( p );
	FillPropertyValues ( Row, fields );
	
EndProcedure 

&AtServerNoContext
Function getFieldsByTask ( val Params )
	
	fields = new Structure ( "TimeType, HourlyRate" );
	data = DF.Values ( Params.Task, "Currency, HourlyRate, Billable" );
	fields.TimeType = ? ( data.Billable, Enums.Time.Billable, Enums.Time.NonBillable );
	if ( data.Billable ) then
		fields.HourlyRate = Currencies.Convert ( data.HourlyRate, data.Currency, Params.Currency, Params.DateStart );
	endif; 
	return fields;
	
EndFunction

&AtClient
Procedure setTimeType ( Row )
	
	billable = DF.Pick ( Row.Task, "Billable" );
	Row.TimeType = ? ( billable, PredefinedValue ( "Enum.Time.Billable" ), PredefinedValue ( "Enum.Time.NonBillable" ) );
	
EndProcedure 

&AtClient
Procedure TasksHourlyRateOnChange ( Item )
	
	calcAmountByTask ( ThisObject, Items.Tasks.CurrentData );
	
EndProcedure

&AtClient
Procedure TasksDurationOnChange ( Item )
	
	currentData = Items.Tasks.CurrentData;
	Conversion.AdjustTime ( currentData.Duration );
	calcMinutes ( currentData );
	if ( not HourlyRatesEdit ) then
		return;
	endif; 
	calcAmountByTask ( ThisObject, currentData );
	
EndProcedure

&AtClient
Procedure TasksAmountOnChange ( Item )
	
	calcHourlyRate ( Items.Tasks.CurrentData );
	
EndProcedure

&AtClient
Procedure TasksDescriptionOpening ( Item, StandardProcessing )
	
	StandardProcessing = false;
	currentData = Items.Tasks.CurrentData;
	ShowInputString ( new NotifyDescription ( "SetTaskDescription", ThisObject, currentData ), currentData.Description, , , true );
	
EndProcedure

&AtClient
Procedure SetTaskDescription ( Text, Row ) export
	
	if ( Text = undefined ) then
		return;
	endif; 
	Row.Description = Text;
	Modified = true;
	
EndProcedure 

&AtClient
Procedure TasksTimeTypeOnChange ( Item )
	
	if ( not HourlyRatesEdit ) then
		return;
	endif; 
	currentData = Items.Tasks.CurrentData;
	if ( TasksHourlyRateAllowed ) then
		recalcHourlyRateByTask ( ThisObject, currentData );
	endif; 
	calcAmountByTask ( ThisObject, currentData );
	
EndProcedure

// *****************************************
// *********** Table Attachments

&AtClient
Procedure AttachmentsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	Attachments.Command ( attachmentParams ( Enum.AttachmentsCommandsShow () ) );
	
EndProcedure

&AtClient
Function attachmentParams ( Command )
	
	p = Attachments.GetParams ();
	p.Command = Command;
	p.Control = Items.Attachments;
	p.Table = Tables.Attachments;
	p.FolderID = Object.FolderID;
	p.Ref = Object.Ref;
	p.Form = ThisObject;
	return p;
	
EndFunction 

&AtClient
Procedure Upload ( Command )
	
	Attachments.Command ( attachmentParams ( Enum.AttachmentsCommandsUpload () ) );
	
EndProcedure

&AtClient
Procedure Remove ( Command )
	
	Attachments.Remove ( attachmentParams ( Enum.AttachmentsCommandsRemove () ) );
	
EndProcedure

&AtClient
Procedure DownloadFile ( Command )

	Attachments.Command ( attachmentParams ( Enum.AttachmentsCommandsDownload () ) );

EndProcedure

&AtClient
Procedure DownloadAllFiles ( Command )
	
	Attachments.Command ( attachmentParams ( Enum.AttachmentsCommandsDownloadAll () ) );
	
EndProcedure

// *****************************************
// *********** Table Tags

&AtClient
Procedure TagsOnActivateRow ( Item )
	
	TagRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure TagsOnStartEdit ( Item, NewRow, Clone )
	
	OldTag = TagRow.Tag;
	
EndProcedure

&AtClient
Procedure TagsOnEditEnd ( Item, NewRow, CancelEdit )
	
	if ( CancelEdit ) then
		return;
	endif;
	Tags.Attach ( Object.Ref, TagRow, OldTag );
	
EndProcedure

&AtClient
Procedure TagsBeforeDeleteRow ( Item, Cancel )
	
	Tags.Delete ( Object.Ref, Items.Tags, Tables.Tags  );
	
EndProcedure

// *****************************************
// *********** Page ApprovalListPage

&AtClient
Procedure UseApprovingProcessOnChange ( Item )
	
	resetApprovalList ();
	fillApprovalList ();
	Appearance.Apply ( ThisObject, "Object.UseApprovingProcess" );
	
EndProcedure

&AtClient
Procedure resetApprovalList ()
	
	if ( not Object.UseApprovingProcess ) then
		Object.ApprovalList.Clear ();
	endif; 
	
EndProcedure 

&AtClient
Procedure fillApprovalList ()
	
	if ( not Object.UseApprovingProcess ) then
		return;
	endif;
	fillByTemplate ();
	if ( Object.ApprovalList.Count () = 0
		and not Object.Manager.IsEmpty () ) then
		addToApprovalList ();
	endif; 
	
EndProcedure 

&AtServer
Procedure fillByTemplate ()
	
	table = getApprovalList ();
	Object.ApprovalList.Load ( table );
	
EndProcedure 

&AtServer
Function getApprovalList ()
	
	s = "
	|select List.User as User, List.Priority as Priority
	|from Catalog.Organizations.ApprovalList as List
	|where List.Ref = &Customer
	|order by Priority
	|";
	q = new Query ( s );
	q.SetParameter ( "Customer", Object.Owner );
	return q.Execute ().Unload ();
	
EndFunction 

&AtClient
Procedure addToApprovalList ()
	
	usersByManager = getUsersByManager ( Object.Manager );
	priority = undefined;
	for each user in usersByManager do
		row = Object.ApprovalList.Add ();
		row.User = user;
		if ( priority = undefined ) then
			priority = row.LineNumber;
		endif; 
		row.Priority = priority;
	enddo; 
	
EndProcedure 

&AtServerNoContext
Function getUsersByManager ( val Manager )
	
	s = "
	|select Users.Ref as Ref
	|from Catalog.Users as Users
	|where Users.Employee = &Manager
	|and not Users.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "Manager", Manager );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
EndFunction 

&AtClient
Procedure ApprovalListOnStartEdit ( Item, NewRow, Clone )
	
	if ( not NewRow ) then
		return;
	endif; 
	setPriority ( Item.CurrentData );
	
EndProcedure

&AtClient
Procedure setPriority ( Row )
	
	Row.Priority = Row.LineNumber;
	
EndProcedure 

// *****************************************
// *********** Page More

&AtClient
Procedure CompanyOnChange ( Item )
	
	applyCompany ();
	
EndProcedure

&AtServer
Procedure applyCompany ()
	
	setOurCompany ();
	Appearance.Apply ( ThisObject, "OurCompany" );
	
EndProcedure
