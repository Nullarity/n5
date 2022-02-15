Function GetScheduled ( Key ) export
	
	SetPrivilegedMode ( true );
	result = ScheduledJobs.GetScheduledJobs ( new Structure ( "Key", Key ) );
	return ? ( result.Count () = 0, undefined, result [ 0 ] );
	
EndFunction 

Procedure Remove ( Ref ) export
	
	SetPrivilegedMode ( true );
	job = Jobs.GetScheduled ( Ref.UUID () );
	if ( job <> undefined ) then
		job.Delete ();
	endif; 
	
EndProcedure 

Function GetBackground ( Key, ActiveOnly = true ) export
	
	SetPrivilegedMode ( true );
	filter = new Structure ( "Key", Key );
	if ( ActiveOnly ) then
		filter.Insert ( "State", BackgroundJobState.Active );
	endif; 
	result = BackgroundJobs.GetBackgroundJobs ( filter );
	return ? ( result.Count () = 0, undefined, result [ 0 ] );
	
EndFunction 

Function GetByID ( ID, ActiveOnly = true ) export
	
	SetPrivilegedMode ( true );
	job = BackgroundJobs.FindByUUID ( ID );
	if ( ActiveOnly ) then
		if ( job <> undefined
			and job.State = BackgroundJobState.Active ) then
			return job;
		else
			return undefined;
		endif;
	else
		return job;
	endif; 
	
EndFunction 

Function Run ( EntryPoint, val Params = undefined, Key = undefined, Description = undefined, TestingMode = false ) export
	
	if ( Key <> undefined ) then
		cleanLog ( Key );
	endif;
	if ( TestingMode ) then
		runHere ( EntryPoint, Params, Key );
		return undefined;
	else
		if ( runningProcessor ( EntryPoint ) ) then
			augment ( Params, Key );
		endif;
		return BackgroundJobs.Execute ( EntryPoint, Params, Key, Description );
	endif;
	
EndFunction

Procedure cleanLog ( Key )
	
	r = InformationRegisters.Jobs.CreateRecordManager ();
	r.JobKey = Key;
	r.Delete ();
	
EndProcedure 

Function runningProcessor ( EntryPoint )
	
	return EntryPoint = "Jobs.ExecProcessor";
	
EndFunction

Procedure runHere ( EntryPoint, Params, Key )
	
	if ( Params = undefined ) then
		execute EntryPoint + " ();";
	else
		if ( runningProcessor ( EntryPoint ) ) then
			augment ( Params, Key );
		endif;
		parts = new Array ();
		for i = 0 to Params.UBound () do
			parts.Add ( "Params [ " + Format ( i, "NG=;NZ=" ) + " ]" );
		enddo;
		execute EntryPoint + "( " + StrConcat ( parts, ", " ) + " );";
	endif;
		
EndProcedure

Procedure augment ( Params, Key )
	
	count = Params.Count ();
	if ( count = 1 ) then
		Params.Add ( undefined );
		Params.Add ( Key );
	elsif ( count = 2 ) then
		Params.Add ( Key );
	endif;
	
EndProcedure

Procedure ExecProcessor ( DataProcessor, Params = undefined, Key = undefined ) export
	
	DataProcessors [ DataProcessor ].Exec ( Params, Key );
	
EndProcedure 
