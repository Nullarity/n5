&AtClient
var TableRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	expandExplanation ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure expandExplanation ()
	
	if ( Object.Explanation <> "" ) then
		Items.GroupExplanation.Behavior = UsualGroupBehavior.Usual;
	endif;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	IsNew = Object.Ref.IsEmpty ();
	adjustMobile ();
	if ( IsNew ) then
		DocumentForm.SetCreator ( Object );
		fillNew ();
	else
		defaultButton ();
	endif;
	setOwner ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|ProcessCompleted show Object.Completed;
	|Source show filled ( Object.Source );
	|Template Description Explanation Start Performers Control Appearance Date Number Company lock ( Object.Started or not Owner );
	|Finish lock ( Object.Completed or not Owner );
	|PickTime PickTimeMobile show not Object.Started and Owner;
	|FormDelete show filled ( Object.Ref ) and Owner;
	|FormStartAndClose show Owner and not Object.Started;
	|FormSaveAndClose show
	|Owner
	|and Object.Started
	|and not Object.Completed
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure adjustMobile ()
	
	if ( Environment.MobileClient () ) then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
		Items.GroupMore.Behavior = UsualGroupBehavior.Collapsible;
	endif;
	
EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif;
	settings = Logins.Settings ( "Company" );
	Object.Company = settings.Company;
	Object.Appearance = Catalogs.CalendarAppearance.Commands;
	if ( Object.Start = Date ( 1, 1, 1 ) ) then
		start = DatePicker.Humanize ( CurrentSessionDate () );
		Object.Start = start;
		Object.Finish = start + 3600;
	endif;
	loadPerformers ();
	TaskForm.CalcDuration ( Object );
	
EndProcedure

&AtServer
Procedure loadPerformers ()
	
	performers = Parameters.Performers;
	if ( performers = undefined ) then
		return;
	endif;
	for each performer in performers do
		row = Object.Performers.Add ();
		initRow ( Object, row );
		row.Performer = performer;
	enddo;
	
EndProcedure

&AtServer
Procedure setOwner ()
	
	Owner = ( Object.Creator = SessionParameters.User );

EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	sortStages ( CurrentObject );
	
EndProcedure

&AtServer
Procedure sortStages ( CurrentObject )
	
	CurrentObject.Performers.Sort ( "Stage" );
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	notifySystem ();
	
EndProcedure

&AtClient
Procedure notifySystem ()
	
	p = new Structure ( "Start, Finish", Object.Start, Object.Finish );
	Notify ( Enum.MessageCommandSaved (), p );
	source = Object.Source;
	if ( source <> undefined ) then
		NotifyChanged ( source );
	endif;
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure TemplateOnChange ( Item )
	
	loadTemplate ();
	
EndProcedure

&AtServer
Procedure loadTemplate ()
	
	template = Object.Template;
	FillPropertyValues ( Object, template, "Description,Appearance,Control,Explanation" );
	table = template.Performers.Unload ();
	perfomers = Object.Performers;
	perfomers.Clear ();
	creator = Object.Creator;
	for each row in table do
		newRow = perfomers.Add ();
		FillPropertyValues ( newRow, row );
		if ( row.Creator ) then
			newRow.Performer = creator;
		endif;
	enddo;
	
EndProcedure

&AtClient
Procedure PeriodOnChange ( Item )
	
	TaskForm.CalcDuration ( Object );

EndProcedure

&AtClient
Procedure PeriodStartChoice ( Item, ChoiceData, StandardProcessing )
	
	#if ( MobileClient ) then
		return;
	#endif
	StandardProcessing = false;
	if ( Object.Started ) then
		DatePicker.SelectDate ( Item, Object.Finish, Object.Start );
	else
		selectPeriod ( Item );
	endif;

EndProcedure

&AtClient
Procedure selectPeriod ( Item )
	
	DatePicker.SelectPeriod ( Item, Object.Start, Object.Finish, Object.Date, Item = Items.Finish );
	
EndProcedure

&AtClient
Procedure PeriodChoiceProcessing ( Item, SelectedValue, StandardProcessing )
	
	#if ( MobileClient ) then
		return;
	#endif
	Modified = true;
	if ( Object.Started ) then
		return;
	endif;
	StandardProcessing = false;
	applyPeriod ( SelectedValue );
	
EndProcedure

&AtClient
Procedure applyPeriod ( Period )
	
	Object.Start = Period.Start;
	Object.Finish = Period.Finish;
	TaskForm.CalcDuration ( Object );
	Modified = true;
	
EndProcedure

&AtClient
Procedure PickTime ( Command )
	
	selectTime ();
	
EndProcedure

&AtClient
Procedure selectTime ()
	
	p = new Structure ( "SelectionMode, SelectionDate, Source", true, Object.Start, Object.Ref );
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
	
EndProcedure

// *****************************************
// *********** Performers

&AtClient
Procedure PerformersOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure PerformersOnStartEdit ( Item, NewRow, Clone )
	
	if ( not NewRow
		or Clone ) then
		return;
	endif;
	initRow ( Object, TableRow );
	
EndProcedure

&AtClientAtServerNoContext
Procedure initRow ( Object, Row )
	
	i = Row.LineNumber - 1;
	Row.Stage = ? ( i = 0, 1, Object.Performers [ i - 1 ].Stage + 1 );
	Row.Mandatory = true;
	
EndProcedure

&AtServer
Procedure defaultButton ()
	
	if ( Object.Started and not Object.Completed ) then
		Items.FormSaveAndClose.DefaultButton = true;
	endif;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure SaveAndClose ( Command )
	
	Write ();
	Close ();
	
EndProcedure

&AtClient
Procedure Delete ( Command )

	Output.DeleteCommand ( ThisObject );
	
EndProcedure

&AtClient
Procedure DeleteCommand ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	Object.DeletionMark = true;
	Write ();
	Close ();
	
EndProcedure
