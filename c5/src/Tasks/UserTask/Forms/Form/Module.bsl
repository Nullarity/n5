&AtClient
var OldDate;
&AtClient
var OldTask;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
	endif; 
	init ();
	adjustMobile ();
	defaultButton ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	disableDeleted ();
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Source show filled ( Object.Source );
	|Email show filled ( Object.Email );
	|BusinessProcess Creator Performer Point show filled ( Object.BusinessProcess );
	|FormOK show
	|( ( not Object.Executed and MyTask )
	|	or ( filled ( Object.BusinessProcess )
	|		and ProcessOwner
	|		and Object.Point = Enum.CommandPoints.Task ) );
	|Progress Status enable
	|( ( not Object.Executed and MyTask )
	|	or ( filled ( Object.BusinessProcess )
	|		and ProcessOwner
	|		and Object.Point = Enum.CommandPoints.Task ) );
	|FormComplete show
	|filled ( Object.Ref )
	|and not Object.Executed
	|and MyTask;
	|FormGiveBack show
	|Object.Point = Enum.CommandPoints.Task
	|and not Object.Executed
	|and MyTask;
	|FormRepeat FormDelegate FormTerminate show
	|Object.Point = Enum.CommandPoints.Checking
	|and not Object.Executed
	|and MyTask;
	|FormDelete show
	|filled ( Object.Ref )
	|and empty ( Object.BusinessProcess )
	|and MyTask;
	|Start Finish Reminder PickTime PickTimeMobile enable
	|not Object.Executed
	|and ( MyTask or ProcessOwner );
	|Memo Section Appearance Display lock ( Object.Executed or not MyTask );
	|Section show MyTask;
	|Performer lock
	|( empty ( Object.BusinessProcess )
	|	or not ProcessOwner
	|	or Object.Point <> Enum.CommandPoints.Task );
	|DeletionInfo show Object.DeletionMark;
	|DisplayGroup show not MobileClient
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		Object.Executed = false;
	endif;
	me = SessionParameters.User;
	Object.Creator = me;
	Object.Performer = me;
	TaskForm.InitStart ( Object );
	TaskForm.AdjustFinish ( Object );
	TaskForm.CalcDuration ( Object );
		
EndProcedure

&AtServer
Procedure init ()
	
	me = SessionParameters.User;
	MyTask = ( me = Object.Performer );
	ProcessOwner = not Object.BusinessProcess.IsEmpty () and ( me = DF.Pick ( Object.BusinessProcess, "Creator" ) );
	
EndProcedure

&AtServer
Procedure adjustMobile ()
	
	MobileClient = Environment.MobileClient ();
	if ( MobileClient ) then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
	endif;
	
EndProcedure

&AtServer
Procedure defaultButton ()
	
	if ( Object.Ref.IsEmpty () ) then
		Items.FormOK.DefaultButton = true;
	else
		Items.FormComplete.DefaultButton = true;
	endif;
	
EndProcedure

&AtServer
Procedure disableDeleted ()
	
	if ( Object.DeletionMark ) then
		ReadOnly = true;
	endif;
	
EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	saveCalendarInfo ();
	
EndProcedure

&AtClient
Procedure saveCalendarInfo ()
	
	OldDate = Object.Start;
	
EndProcedure 

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject );

EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	notifySystem ();
	
EndProcedure

&AtClient
Procedure notifySystem ()
	
	p = new Structure ( "OldDate, NewDate", OldDate, Object.Start );
	Notify ( Enum.MessageUserTaskUpdated (), p );
	source = Object.Source;
	if ( source <> undefined ) then
		NotifyChanged ( source );
	endif;
	saveCalendarInfo ();
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure SaveAndClose ( Command )
	
	if ( Write () ) then
		Close ();
	endif; 
	
EndProcedure

&AtClient
Procedure Complete ( Command )
	
	if ( notesRequired () ) then
		OpenForm ( "Task.UserTask.Form.Notes", new Structure ( "Status", Object.Status ), ThisObject, , , , new NotifyDescription ( "TaskNotes", ThisObject, PredefinedValue ( "Enum.Actions.Complete" ) ) );
	else
		Output.CompleteTask ( ThisObject );
	endif;
	
EndProcedure

&AtClient
Function notesRequired ()
	
	return Object.Creator <> Object.Performer
	and Object.Point <> PredefinedValue ( "Enum.CommandPoints.Checking" );

EndFunction

&AtClient
Procedure TaskNotes ( Result, Action ) export
	
	if ( Result = undefined ) then
		return;
	endif; 
	completeMemo ( Result.Notes );
	Object.Status = Result.Status;
	run ( Action );

EndProcedure

&AtClient
Procedure completeMemo ( Notes )
	
	if ( Notes = "" ) then
		return;
	endif;
	Object.Display = firstLine ( Notes );
	parts = new Array ();
	data = new Structure ( "Date, Notes, User", CurrentDate (), Notes, Object.Performer );
	parts.Add ( Output.TaskNotes ( data ) );
	parts.Add ( Chars.LF );
	parts.Add ( "---" );
	parts.Add ( Chars.LF );
	parts.Add ( Object.Memo );
	Object.Memo = StrConcat ( parts );
	
EndProcedure

&AtClient
Function firstLine ( Str )
	
	for i = 0 to StrLineCount ( Str ) do
		s = StrGetLine ( Str, i );
		if ( not IsBlankString ( s ) ) then
			return s;
		endif;
	enddo;
	return "<...>";
	
EndFunction

&AtClient
Procedure CompleteTask ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	run ( PredefinedValue ( "Enum.Actions.Complete" ) );

EndProcedure

&AtClient
Procedure run ( Action )
	
	Object.Action = Action;
	Write ( new Structure ( "ВыполнитьЗадачу", true ) );
	Close ();
	
EndProcedure

&AtClient
Procedure GiveBack ( Command )
	
	OpenForm ( "Task.UserTask.Form.Return", new Structure ( "Status", Object.Status ), ThisObject, , , , new NotifyDescription ( "TaskNotes", ThisObject, PredefinedValue ( "Enum.Actions.Resolve" ) ) );
	
EndProcedure

&AtClient
Procedure Repeat ( Command )
	
	OpenForm ( "Task.UserTask.Form.Notes", new Structure ( "Status", Object.Status ), ThisObject, , , , new NotifyDescription ( "TaskNotes", ThisObject, PredefinedValue ( "Enum.Actions.Rework" ) ) );
	
EndProcedure

&AtClient
Procedure Delegate ( Command )
	
	OpenForm ( "Task.UserTask.Form.Delegate", , ThisObject, , , , new NotifyDescription ( "DelegationData", ThisObject, PredefinedValue ( "Enum.Actions.Rework" ) ) );
	
EndProcedure

&AtClient
Procedure DelegationData ( Data, Action ) export
	
	if ( Data = undefined ) then
		return;
	endif; 
	completeMemo ( Data.Notes );
	Object.Delegated = Data.Performer;
	run ( Action );

EndProcedure

&AtClient
Procedure TerminateCommand ( Command )
	
	Output.TerminateProcess ( ThisObject );
	
EndProcedure

&AtClient
Procedure TerminateProcess ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	run ( PredefinedValue ( "Enum.Actions.Reject" ) );

EndProcedure

&AtClient
Procedure Delete ( Command )
	
	Output.RemoveTaskConfirmation ( ThisObject )
	
EndProcedure

&AtClient
Procedure RemoveTaskConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	Modified = false;
	deleteTask ( Object.Ref );
	notifySystem ();
	NotifyChanged ( Object.Ref );
	Close ();
	
EndProcedure 

&AtServerNoContext
Procedure deleteTask ( val Task )
	
	obj = Task.GetObject ();
	obj.SetDeletionMark ( true );
	
EndProcedure 

&AtClient
Procedure PickTime ( Command )
	
	selectTime ();
	
EndProcedure

&AtClient
Procedure selectTime ()
	
	p = new Structure ( "SelectionMode, SelectionDate, Filter, Source", true, Object.Start, Object.Performer, Object.Ref );
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
// *********** Group Task

&AtClient
Procedure MemoOnChange ( Item )
	
	setDisplay ();
	
EndProcedure

&AtClient
Procedure setDisplay ()
	
	Object.Display = firstLine ( Object.Memo );
	
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
	
EndProcedure
