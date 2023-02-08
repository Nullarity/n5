
Function ChangeReasons ( val Ref ) export
	
	list = new Array ();
	list.Add ( Enums.ChangeReasons.Item );
	list.Add ( Enums.ChangeReasons.Price );
	list.Add ( Enums.ChangeReasons.Quantity );
	list.Add ( Enums.ChangeReasons.DeliveryDate );
	list.Add ( Enums.ChangeReasons.ReceiptOther );
	type = TypeOf ( Ref );
	if ( type = Type ( "DocumentRef.SalesOrder" ) ) then
		list.Add ( Enums.ChangeReasons.SoldLess );
		list.Add ( Enums.ChangeReasons.SoldMore );
	endif; 
	list.Add ( Enums.ChangeReasons.Other );
	return new Structure ( "Reasons", list );
	                     	
EndFunction 

Function GetPerformers ( val Process ) export
	
	mebmers = getUsers ();
	if ( mebmers.Count () = 0 ) then
		return undefined;
	endif; 
	performers = getTasks ( mebmers, Process );
	if ( performers.Count () = 0 ) then
		return undefined;
	else
		return Output.ProcessPerformers ( new Structure ( "Performers", StrConcat ( performers, Chars.LF ) ) );
	endif; 

EndFunction

Function getUsers ()
	
	s = "
	|select distinct BPRouter.User as User
	|from InformationRegister.BPRouter as BPRouter
	|";
	q = new Query ( s );
	return q.Execute ().Unload ();
	
EndFunction 

Function getTasks ( Mebmers, Process )
	
	q = new Query ();
	q.SetParameter ( "Process", Process );
	i = 1;
	s = "
	|select presentation ( Tasks.User ) as Performer, Tasks.Ref as Task
	|from Task.Task as Tasks
	|where not Tasks.Executed
	|and Tasks.BusinessProcess = &Process
	|and Tasks.User <> value ( Catalog.Users.EmptyRef )
	|";
	for each member in Mebmers do
		param = "Performer" + Format ( i, "NG=" );
		s = s + "
		|union
		|select presentation ( &" + param + " ), Tasks.Ref
		|from Task.Task.TasksByExecutive ( &" + param + ", not Executed and BusinessProcess = &Process ) as Tasks
		|";
		i = i + 1;
		q.SetParameter ( param, member.User );
	enddo; 
	q.Text = s;
	return q.Execute ().Unload ().UnloadColumn ( "Performer" );
	
EndFunction 
