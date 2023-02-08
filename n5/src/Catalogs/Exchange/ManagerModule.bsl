#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure RunProcess ( Params ) export
	
	if ( Params.Node = undefined and not ValueIsFilled ( Params.Node ) ) then
		return;
	endif;
	if ( Params.ProcessName = "UnloadHandle" ) then
		runUnloadHandle ( Params );
	elsif ( Params.ProcessName = "UnloadJob" ) then
		runUnloadJob ( Params );
	elsif ( Params.ProcessName = "LoadHandle" ) then
		runLoadHandle ( Params );		
	elsif ( Params.ProcessName = "LoadJob" ) then
		runLoadJob ( Params );
	endif; 
	
EndProcedure 

Procedure runUnloadHandle ( Params ) export
	
	p = new Structure ();
	p.Insert ( "Node", Params.Node );
	p.Insert ( "StartUp", false );
	p.Insert ( "ID", "" );
	DataProcessors.ExchangeData.Unload ( p );
	
EndProcedure

Procedure runUnloadJob ( Params ) export
	
	a = new Array ();
	a.Add ( false ); 	
	a.Add ( true  );
	a.Add ( Params.Node );
	a.Add ( false );
	a.Add ( false );
	runBackgroundJob ( a );
	
EndProcedure

Procedure runLoadHandle ( Params ) export
	
	p = new Structure ();
	p.Insert ( "Node", Params.Node );
	p.Insert ( "StartUp", false );
	p.Insert ( "Update", false );
	p.Insert ( "ID", "" );
	DataProcessors.ExchangeData.Load ( p );
	
EndProcedure

Procedure runLoadJob ( Params ) export
	
	a = new Array ();
	a.Add ( true  );
	a.Add ( false );
	a.Add ( Params.Node );
	a.Add ( false );
	a.Add ( false );
	runBackgroundJob ( a );
	
EndProcedure

Procedure runBackgroundJob ( Params )	
	
	p = new Structure ( "UserName, Date, ComputerName" );
	p.UserName = UserName ();
	p.Date = CurrentDate ();
	p.ComputerName = ComputerName ();
	description = Output.StartBackgroundJob ( p );
	backgroundJob = Jobs.Run ( "Exchange.Exchange", Params, , description );
	Output.JobStarted ( new Structure ( "DateTime", backgroundJob.Begin ) );
	jobUUID = backgroundJob.UUID;
	backgroundJob.WaitForExecutionCompletion ();
	job = BackgroundJobs.GetBackgroundJobs ( new Structure ( "UUID", jobUUID ) );
	if ( job.Count () ) then
		Output.JobEnded ( new Structure ( "DateTime", job [ 0 ].End ) );
	endif;
	
EndProcedure 

#endif