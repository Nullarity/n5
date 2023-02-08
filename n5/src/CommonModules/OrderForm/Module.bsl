&AtServer
Procedure LoadProcess ( Form ) export
	
	env = initEnv ( Form );
	getProcess ( env );
	setRoutePoint ( env );
	setResolutionMemo ( env );
	setCanChangeFlag ( env );
	
EndProcedure 

&AtServer
Function initEnv ( Form )
	
	object = Form.Object;
	env = new Structure ();
	env.Insert ( "Form", Form );
	env.Insert ( "Object", object );
	env.Insert ( "SalesOrder", TypeOf ( object.Ref ) = Type ( "DocumentRef.SalesOrder" ) );
	SQL.Init ( env );
	return env;
	
EndFunction 

&AtServer
Procedure getProcess ( Env )
	
	object = Env.Object;
	sqlProcess ( Env );
	sqlLastMemo ( Env );
	Env.Q.SetParameter ( "Ref", object.Ref );
	Env.Q.SetParameter ( "Performer", SessionParameters.User );
	Env.Q.SetParameter ( "Process", object.Process );
	SQL.Perform ( Env );

EndProcedure 

&AtServer
Procedure sqlProcess ( Env )
	
	if ( Env.SalesOrder ) then
		process = "SalesOrder";
		statuses = "SalesOrderStatuses";
	else
		process = "InternalOrder";
		statuses = "InternalOrderStatuses";
	endif; 
	s = "
	|// @Flags
	|select BP.Completed as Completed, BP.Started as Started
	|from BusinessProcess." + process + " as BP
	|where BP.Ref = &Process
	|;
	|// @Process
	|select top 1 case when MyTasks.Ref is null then false else true end as MyTask,
	|	Statuses.Status as RoutePoint
	|from Task.Task as Tasks
	|	//
	|	// MyTasks
	|	//
	|	left join Task.Task.TasksByExecutive ( &Performer, not Executed and BusinessProcess = &Process ) as MyTasks
	|	on MyTasks.Ref = Tasks.Ref
	|	//
	|	// Statuses
	|	//
	|	left join InformationRegister." + statuses + " as Statuses
	|	on Statuses.Document = &Ref
	|where not Tasks.Executed
	|and not Tasks.DeletionMark
	|and Tasks.BusinessProcess = &Process
	|order by case when MyTasks.Ref is null then false else true end desc
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure sqlLastMemo ( Env )
	
	if ( Env.SalesOrder ) then
		register = "SalesOrderResolutions";
	else
		register = "InternalOrderResolutions";
	endif; 
	s = "
	|select max ( Memos.Date ) as Date
	|into LastMemos
	|from InformationRegister." + register + " as Memos
	|where Memos.Document = &Ref
	|;
	|// @LastMemo
	|select Memos.User.Description + "": "" + Memos.Memo as Memo
	|from InformationRegister." + register + " as Memos
	|	//
	|	// LastMemos
	|	//
	|	join LastMemos as LastMemos
	|	on LastMemos.Date = Memos.Date
	|where Memos.Document = &Ref
	|and Memos.Memo <> """"
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure setRoutePoint ( Env )
	
	form = Env.Form;
	flags = Env.Flags;
	salesOrder = Env.SalesOrder;
	object = Env.Object;
	if ( flags = undefined ) then
		completed = false;
		form.Started = false;
	else
		completed = flags.Completed;
		form.Started = flags.Started;
	endif; 
	if ( completed ) then
		if ( salesOrder ) then
			form.RoutePoint = Enums.SalesOrderPoints.Finish;
		else
			form.RoutePoint = Enums.InternalOrderPoints.Finish;
		endif; 
		form.MyTask = false;
	else
		if ( Env.Process = undefined ) then
			if ( salesOrder ) then
				form.RoutePoint = Enums.SalesOrderPoints.New;
			else
				form.RoutePoint = Enums.InternalOrderPoints.New;
			endif;
			form.MyTask = ( object.Creator = SessionParameters.User );
		else
			form.RoutePoint = Env.Process.RoutePoint;
			form.MyTask = Env.Process.MyTask;
		endif; 
	endif; 
	
EndProcedure 

&AtServer
Procedure setResolutionMemo ( Env )
	
	form = Env.Form;
	lastMemo = Env.LastMemo;
	if ( lastMemo = undefined ) then
		form.ResolutionMemo = "";
	else
		form.ResolutionMemo = lastMemo.Memo;
	endif; 
	
EndProcedure 

&AtServer
Procedure setCanChangeFlag ( Env )
	
	type = TypeOf ( Env.Object.Ref );
	if ( type = Type ( "DocumentRef.SalesOrder" ) ) then
		right = "ChangeSalesOrders";
	else
		right = "ChangeInternalOrders";
	endif; 
	Env.Form.CanChange = DF.Pick ( SessionParameters.User, right );

EndProcedure 

&AtServer
Procedure InitRoutePoint ( Form ) export
	
	Form.MyTask = true;
	type = TypeOf ( Form.Object.Ref );
	if ( type = Type ( "DocumentRef.SalesOrder" ) ) then
		Form.RoutePoint = Enums.SalesOrderPoints.New;
	else
		Form.RoutePoint = Enums.InternalOrderPoints.New;
	endif; 
		
EndProcedure 

&AtServer
Procedure ResetCopiedFields ( Object ) export
	
	Object.Action = undefined;
	Object.Resolution = undefined;
	Object.Process = undefined;
	Object.Changes.Clear ();
	
EndProcedure 

&AtClient
Procedure ActivateItem ( Form ) export
	
	object = Form.Object;
	items = Form.Items;
	parameters = Form.Parameters;
	if ( parameters.ActivateItem.IsEmpty () ) then
		return;
	endif; 
	item = parameters.ActivateItem;
	rows = object.Items.FindRows ( new Structure ( "Item", item ) );
	if ( rows.Count () > 0 ) then
		Form.ItemsRow = rows [ 0 ];
		items.ItemsTable.CurrentRow = Form.ItemsRow.GetID ();
	else
		rows = object.Services.FindRows ( new Structure ( "Item", item ) );
		if ( rows.Count () > 0 ) then
			Form.ServicesRow = rows [ 0 ];
			items.Services.CurrentRow = Form.ServicesRow.GetID ();
		endif;
	endif; 
	
EndProcedure

&AtClient
Procedure ReserveItem ( Form, Params ) export
	
	object = Form.Object;
	itemsRow = Form.ItemsRow;
	result = Params.Result;
	FillPropertyValues ( itemsRow, result [ 0 ] );
	table = object.Items;
	last = table.IndexOf ( itemsRow ) + 1;
	index = result.Ubound ();
	while ( index > 0 ) do
		row = table.Insert ( last );
		FillPropertyValues ( row, result [ index ] );
		Computations.Total ( row, Object.VATUse );
		index = index - 1;
	enddo; 
	
EndProcedure 

&AtServer
Function CheckAccessibility ( Form ) export
	
	if ( Form.MyTask
		or Form.CanChange ) then
		return true;
	else
		Output.OrderCannotBeChanged ();
		return false;
	endif; 
	
EndFunction 

&AtClient
Procedure Modify ( Form ) export
	
	object = Form.Object;
	OpenForm ( "CommonForm.Changes", OrderFormSrv.ChangeReasons ( object.Ref ), ThisObject, , , , new NotifyDescription ( "Edit", ThisObject, Form ) );
	
EndProcedure

&AtClient
Procedure Edit ( Data, Form ) export
	
	if ( Data = undefined ) then
		return;
	endif; 
	addChanges ( Form, Data );
	Form.Editing = true;
	Appearance.Apply ( Form, "Editing" );
	Output.ModificationTooltip ();
	
EndProcedure 

&AtClient
Procedure addChanges ( Form, Data )
	
	object = Form.Object;
	row = object.Changes.Add ();
	row.Date = SessionDate ();
	row.Information = Data.Information;
	row.Reason = Data.Reason;
	row.User = Form.CurrentUser;
	
EndProcedure 

&AtClient
Procedure OpenPerformers ( Form ) export
	
	object = Form.Object;
	if ( not Form.Started ) then
		ShowValue ( , "" + object.Creator );
	else
		performers = OrderFormSrv.GetPerformers ( Object.Process );
		if ( performers = undefined ) then
			Output.PerformersNotFound ();
		else
			ShowValue ( , performers );
		endif; 
	endif; 
	
EndProcedure 

&AtServer
Function ReservationParams ( Form, RowIndex ) export
	
	object = Form.Object;
	p = new Structure ();
	p.Insert ( "Source", PickItems.GetParams ( Form ) );
	p.Insert ( "Command", Enum.PickItemsCommandsReserve () );
	tableRow = rowStructure ( object, RowIndex );
	p.Insert ( "TableRow", tableRow );
	p.Insert ( "CountPackages", DF.Pick ( tableRow.Item, "CountPackages" ) );
	return p;
	
EndFunction

&AtServer
Function rowStructure ( Object, RowIndex )
	
	row = new Structure ();
	for each item in Object.Ref.Metadata ().TabularSections.Items.Attributes do
		row.Insert ( item.Name );
	enddo; 
	FillPropertyValues ( row, Object.Items [ RowIndex ] );
	return row;
	
EndFunction 

&AtServer
Function SetRowKeys ( CurrentObject ) export
	
	error = not Catalogs.RowKeys.Set ( CurrentObject.Items, 1 );
	error = error or not Catalogs.RowKeys.Set ( CurrentObject.Services, 2 );
	return not error;
	
EndFunction
