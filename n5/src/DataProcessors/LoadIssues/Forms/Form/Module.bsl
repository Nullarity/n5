// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif;
	startLoading ();

	
EndProcedure

&AtClient
Procedure startLoading ()
	
	LoadingKey = "Issues Loading " + UUID;
	runReadFile();
	Progress.Open ( LoadingKey, ThisObject, new CallbackDescription ( "LoadingComplete", ThisObject ), true );	
	
EndProcedure

&AtServer
Procedure runReadFile()
	
	p = DataProcessors.LoadIssues.GetParams ();
	p.Repository = Object.Repository;
	p.Since = Object.Since;
	args = new Array ();
	args.Add ( "LoadIssues" );
	args.Add ( p );
	Jobs.Run ( "Jobs.ExecProcessor", args, LoadingKey, , TesterCache.Testing () );
	
EndProcedure

&AtClient
Procedure LoadingComplete ( Result, Params ) export
	
	if ( not Result ) then
		return;
	endif;
	NotifyChanged ( Type ( "DocumentRef.Issue" ) );
	Output.DataSuccessfullyLoaded ( ThisObject );
	
EndProcedure

&AtClient
Procedure DataSuccessfullyLoaded ( Result ) export
	
	Close ();
	
EndProcedure

&AtClient
Procedure RepositoryOnChange ( Item )
	
	if ( not Object.Repository.IsEmpty () ) then
		applyRepository ();
	endif;
	
EndProcedure

&AtServer
Procedure applyRepository ()
	
	data = InformationRegisters.GitSyncing.Get ( new Structure ( "Repository", Object.Repository ) );
	Object.Since = data.Date;
	
EndProcedure