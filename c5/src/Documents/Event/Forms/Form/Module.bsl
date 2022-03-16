&AtClient
var OldDate;
&AtServer
var Env;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	updateChangesPermission ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	if ( isNew () ) then
		DocumentForm.Init ( Object );
		fillNew ();
		Constraints.ShowAccess ( ThisObject );
	endif;
	applyParams ();
	updateReminder ( ThisObject );
	defaultControl ();
	setLinks ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure init ()
	
	MobileClient = Environment.MobileClient ();
	
EndProcedure 

&AtServer
Function isNew ()
	
	return Object.Ref.IsEmpty ();
	
EndFunction

&AtServer
Procedure fillNew ()
	
	if ( Parameters.CopyingValue.IsEmpty () ) then
		Object.Company  = Logins.Settings ( "Company" ).Company;
		if ( Object.Responsible.IsEmpty () ) then
			Object.Responsible = SessionParameters.User;
		endif;
		if ( not Object.Organization.IsEmpty () ) then
			applyOrganization ();
		endif;
		start = Object.Start;
		if ( start = Date ( 1, 1, 1 ) ) then
			TaskForm.InitStart ( Object );
		else
			if ( start < PeriodsSrv.CurrentUserDate ( Object.Responsible ) ) then
				Object.Status = Enums.EventStatuses.Completed;
			endif;
		endif;
		Object.Color = Catalogs.CalendarAppearance.Default; 
	endif; 
	TaskForm.AdjustFinish ( Object );
	TaskForm.CalcDuration ( Object );
	
EndProcedure

&AtServer
Procedure applyOrganization ()
	
	data = DF.Values ( Object.Organization, "Contact, Customer, Vendor, CustomerContract, VendorContract" );
	Object.Contact = data.Contact;
	Object.Contract = ? ( data.Customer, data.CustomerContract, data.VendorContract );
	
EndProcedure

&AtClientAtServerNoContext
Procedure updateReminder ( Form )
	
	object = Form.Object;
	responsible = object.Responsible;
	#if ( Client ) then
		if ( object.Creator = responsible ) then
			now = SessionDate ();
		else
			now = PeriodsSrv.CurrentUserDate ( responsible );
		endif;
	#else
		now = PeriodsSrv.CurrentUserDate ( responsible );
	#endif
	Form.Now = now;
	Appearance.Apply ( Form, "Now" );
	
EndProcedure

&AtServer
Procedure applyParams ()
	
	newStart = Parameters.NewStart;
	if ( newStart = Date ( 1, 1, 1 ) ) then
		return;
	endif;
	Modified = true;
	Object.Start = newStart;
	Object.Finish = Parameters.NewFinish;
	newResponsible = Parameters.NewResponsible;
	if ( not newResponsible.IsEmpty ()
		and newResponsible <> Object.Responsible ) then
		Object.Responsible = newResponsible;
	endif;
	TaskForm.AdjustFinish ( Object );
	TaskForm.CalcDuration ( Object );
	
EndProcedure

&AtServer
Procedure defaultControl ()
	
	CurrentItem = ? ( isNew (), Items.Start, Items.Status );

EndProcedure

&AtServer
Procedure setLinks ()
	
	SQL.Init ( Env );
	sqlLinks ();
	if ( Env.Selection.Count () = 0 ) then
		ShowLinks = false;
	else
		q = Env.Q;
		q.SetParameter ( "Ref", Object.Ref );
		SQL.Perform ( Env, false );
		setURLPanel ();
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	selection = Env.Selection;
	if ( isNew () ) then
		return;
	endif; 
	s = "
	|// #TimeEntries
	|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
	|from Document.TimeEntry as Documents
	|where Documents.Event = &Ref
	|and not Documents.DeletionMark
	|";
	selection.Add ( s );
	
EndProcedure

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	meta = Metadata.Documents;
	if ( not isNew () ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.TimeEntries, meta.TimeEntry ) );
	endif; 
	s = URLPanel.Build ( parts );
	if ( s = undefined ) then
		ShowLinks = false;
	else
		ShowLinks = true;
		Links = s;
	endif; 
	
EndProcedure 

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Links show ShowLinks;
	|Reminder hide Object.Start < Now or Object.Status <> Enum.EventStatuses.Scheduled;
	|Warning show ( Object.Start < Now and Object.Status = Enum.EventStatuses.Scheduled )
	|	or ( Object.Start > Now and Object.Status = Enum.EventStatuses.Completed )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	saveCalendarInfo ()
	
EndProcedure

&AtClient
Procedure saveCalendarInfo ()
	
	OldDate = Object.Start;
	
EndProcedure 

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	notifySystem ();
	
EndProcedure

&AtClient
Procedure notifySystem ()
	
	p = new Structure ( "OldDate, NewDate", OldDate, Object.Start );
	Notify ( Enum.MessageEventIsSaved (), p, Object.Ref );
	saveCalendarInfo ();
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )

	if ( EventName = Enum.MessageTimeEntryUpdated ()
		and Parameter.Event = Object.Ref ) then
		setLinks ();
	elsif ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

&AtClient
Procedure PickTime ( Command )
	
	selectTime ();
	
EndProcedure

&AtClient
Procedure selectTime ()
	
	p = new Structure ( "SelectionMode, SelectionDate, Filter, Source", true, Object.Start, Object.Responsible, Object.Ref );
	callback = new NotifyDescription ( "TimePicked", ThisObject );
	OpenForm ( "DataProcessor.Calendar.Form", p, ThisObject, , , , callback, FormWindowOpeningMode.LockWholeInterface );
	
EndProcedure

&AtClient
Procedure TimePicked ( Time, Params ) export
	
	if ( Time = undefined ) then
		return;
	endif;
	Object.Start = Time.Begin;
	Object.Finish = Time.End;
	TaskForm.CalcDuration ( Object );
	updateReminder ( ThisObject );
	
EndProcedure

&AtClient
Procedure PeriodStartChoice ( Item, ChoiceData, StandardProcessing )
	
	#if ( MobileClient ) then
		return;
	#endif
	StandardProcessing = false;
	DatePicker.SelectPeriod ( Item, Object.Start, Object.Finish, , Item = Items.Finish );
	
EndProcedure

&AtClient
Procedure PeriodOnChange ( Item )
	
	TaskForm.AdjustFinish ( Object );
	TaskForm.CalcDuration ( Object );
	updateReminder ( ThisObject );
	
EndProcedure

&AtClient
Procedure PeriodChoiceProcessing ( Item, SelectedValue, StandardProcessing )
	
	#if ( MobileClient ) then
		return;
	#endif
	StandardProcessing = false;
	Modified = true;
	applyPeriod ( SelectedValue );
	
EndProcedure

&AtClient
Procedure applyPeriod ( Period )
	
	Object.Start = Period.Start;
	Object.Finish = Period.Finish;
	TaskForm.AdjustFinish ( Object );
	TaskForm.CalcDuration ( Object );
	updateReminder ( ThisObject );
	
EndProcedure

&AtClient
Procedure StatusOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Object.Status" );
	
EndProcedure

&AtClient
Procedure OrganizationOnChange ( Item )
	
	applyOrganization ();
	
EndProcedure
