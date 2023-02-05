#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Env;
var Command;
var Task;
var RoutePoint;

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )

	checkWarehouse ( CheckedAttributes );
	if ( not DeliveryRows.Check ( ThisObject, "Items" )
		or not DeliveryRows.Check ( ThisObject, "Services" ) ) then
		Cancel = true;
		return;
	endif; 
	
EndProcedure

Procedure checkWarehouse ( CheckedAttributes )
	
	if ( Items.Count () > 0 ) then
		CheckedAttributes.Add ( "Warehouse" );
	endif; 
	
EndProcedure 

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	defineCommand ();
	defineTask ();
	SetPrivilegedMode ( true );
	if ( DeletionMark ) then
		if ( not canRemove () ) then
			Cancel = true;
		endif; 
		removeRelations ();
		return;
	else
		if ( isRemoved () ) then
			Cancel = true;
			return;
		endif; 
	endif; 
	createProcess ();
	SetPrivilegedMode ( false );
	
EndProcedure

Procedure defineCommand ()
	
	if ( Action.IsEmpty () ) then
		Command = undefined;
	else
		Command = Action;
		Action = undefined;
	endif; 
	
EndProcedure 

Procedure defineTask ()
	
	if ( IsNew () ) then
		Task = undefined;
		RoutePoint = Enums.InternalOrderPoints.New;
	else
		getTask ();
		Task = ? ( Env.Tasks = undefined, undefined, Env.Tasks.Task );
		RoutePoint = ? ( Env.Statuses = undefined, Enums.InternalOrderPoints.New, Env.Statuses.Status );
	endif;
	
EndProcedure 

Procedure getTask ()
	
	s = "
	|// @Tasks
	|select top 1 Tasks.Ref as Task
	|from Task.Task.TasksByExecutive ( &Performer, BusinessProcess = &Process ) as Tasks
	|where not Tasks.Executed
	|and not Tasks.DeletionMark
	|;
	|// @Statuses
	|select Statuses.Status as Status
	|from InformationRegister.InternalOrderStatuses as Statuses
	|where Statuses.Document = &Ref
	|";
	Env = SQL.Create ( s );
	Env.Q.SetParameter ( "Performer", Performer );
	Env.Q.SetParameter ( "Process", Process );
	Env.Q.SetParameter ( "Ref", Ref );
	SQL.Perform ( Env );
	
EndProcedure

Function canRemove ()
	
	if ( IsInRole ( "Administrator" ) ) then
		return true;
	endif; 
	if ( not Process.IsEmpty () ) then
		Output.OrderCannotBeChanged ();
		return false;
	endif; 
	return true;
	
EndFunction 

Procedure removeRelations ()
	
	BP.RemoveTasks ( Process );
	BP.Remove ( Process );
	Process = undefined;
	Posting.ClearRecords ( RegisterRecords );
	removeStatus ();
	
EndProcedure 

Procedure removeStatus ()
	
	record = InformationRegisters.InternalOrderStatuses.CreateRecordManager ();
	record.Document = Ref;
	record.Delete ();
	
EndProcedure 

Function isRemoved ()
	
	if ( IsNew () or IsInRole ( "Administrator" ) ) then
		return false;
	endif; 
	removed = DF.Pick ( Ref, "DeletionMark as DeletionMark" );
	if ( removed ) then
		Output.DocumentIsRemoved ();
		return true;
	endif; 
	return false;
	
EndFunction 

Procedure createProcess ()
	
	if ( Command <> Enums.Actions.SendToApproval ) then
		return;
	endif; 
	if ( IsNew () ) then
		SetNewObjectRef ( Documents.InternalOrder.GetRef ( new UUID () ) );
		documentRef = GetNewObjectRef ();
	else
		documentRef = Ref;
	endif; 
	approval = BusinessProcesses.InternalOrder.CreateBusinessProcess ();
	approval.Date = CurrentSessionDate ();
	approval.InternalOrder = documentRef;
	approval.Write ();
	Process = approval.Ref;
	
EndProcedure 

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	SetPrivilegedMode ( true );
	if ( not performCommand () ) then
		Cancel = true;
		return;
	endif; 
	sendEmails ();
	
EndProcedure

Function performCommand ()
	
	cmd = Enums.Actions;
	if ( Command = undefined ) then
		return true;
	elsif ( Command = cmd.SendToApproval ) then
		startProcess ();
		if ( mustBePosted () ) then
			return post ();
		endif; 
	elsif ( Command = cmd.CompleteApproval ) then
		executeTask ();
		return post ();
	elsif ( Command = cmd.CompleteEdition ) then
		if ( mustBePosted () ) then
			return post ();
		endif; 
	elsif ( Command = cmd.CompleteDelivery ) then
		if ( balanceExists () ) then
			return false;
		else
			executeTask ();
		endif; 
	elsif ( Command = cmd.Reject ) then
		clearRecords ();
		executeTask ();
	else
		executeTask ();
	endif; 
	return true;
	
EndFunction 

Procedure startProcess ()
	
	obj = Process.GetObject ();
	obj.Start ();
	
EndProcedure

Procedure executeTask ()
	
	obj = Task.GetObject ();
	obj.ExecuteTask ();
	
EndProcedure 

Function post ()
	
	Env = Posting.GetParams ( Ref, RegisterRecords );
	return Documents.InternalOrder.Post ( Env );
	
EndFunction 

Function mustBePosted ()
	
	s = "
	|select top 1 1
	|from Task.Task as Tasks
	|where Tasks.BusinessProcess in ( select Process from Document.InternalOrder where Ref = &Ref )
	|and not Tasks.DeletionMark
	|and ( Tasks.RoutePoint = value ( BusinessProcess.InternalOrder.RoutePoint.Delivery )
	|	or ( Tasks.BusinessProcess.Completed
	|		and &Resolution = value ( Enum.Resolutions.Approve ) ) )
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	q.SetParameter ( "Resolution", Resolution );
	return not q.Execute ().IsEmpty ();
	
EndFunction 

Procedure clearRecords ()
	
	Posting.ClearRecords ( RegisterRecords );
	
EndProcedure 

Function balanceExists ()
	
	s = "
	|select top 1 1
	|from AccumulationRegister.InternalOrders.Balance ( , InternalOrder = &Ref ) as Balances
	|where Balances.QuantityBalance > 0
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	error = q.Execute ().Select ().Next ();
	if ( error ) then
		Output.InternalOrderClosingError ();
	endif; 
	return error;
	
EndFunction 

Procedure sendEmails ()
	
	if ( Command = undefined
		or Command = Enums.Actions.CompleteEdition ) then
		return;
	endif; 
	p = new Structure ();
	p.Insert ( "Ref", Ref );
	p.Insert ( "Sender", Performer );
	p.Insert ( "LastRoutePoint", RoutePoint );
	p.Insert ( "Process", Process );
	args = new Array ();
	args.Add ( p );
	Jobs.Run ( "InternalOrderMailing.Send", args, , , TesterCache.Testing () );
	
EndProcedure 

#endif