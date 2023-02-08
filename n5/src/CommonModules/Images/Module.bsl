Procedure Load ( Callback, FormID ) export
	
	p = new Structure ( "Callback, FormID", Callback, FormID );
	bridge = new NotifyDescription ( "SelectPhoto", ThisObject, p );
	LocalFiles.Prepare ( bridge );
	
EndProcedure 

Procedure SelectPhoto ( Result, Params ) export
	
	BeginPutFile ( new NotifyDescription ( "CompleteUpload", ThisObject, Params.Callback ), , , true, Params.FormID );
	
EndProcedure 

Procedure CompleteUpload ( Result, Address, File, Callback ) export
	
	if ( not Result ) then
		return;
	endif; 
	if ( not FileSystem.Picture ( File ) ) then
		Output.SelectPicture ();
		return;
	endif; 
	p = new Structure ( "Picture, File" );
	p.Picture = Address;
	p.File = File;
	ExecuteNotifyProcessing ( Callback, p );

EndProcedure 
