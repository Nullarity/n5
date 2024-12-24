// *****************************************
// *********** Form events

&AtClient
async Procedure Load ( Command )
	
	params = new PutFilesDialogParameters ( , false, "XLSX (*.xlsx)|*.xlsx" );
	file = await PutFileToServerAsync ( , , , params, UUID );
	if ( file = undefined
		or file.PutFileCanceled ) then
		return;
	endif;
	loadFile ( file.Address );
	Progress.Open ( UUID, ThisObject, new CallbackDescription ( "Loading", ThisObject ), true );
	
EndProcedure

&AtServer
Procedure loadFile ( val Location )

	p = DataProcessors.LoadInvoices.GetParams ();
	p.File = GetFromTempStorage ( Location );
	args = new Array ();
	args.Add ( "LoadOrganizations" );
	args.Add ( p );
	Jobs.Run ( "Jobs.ExecProcessor", args, UUID, , TesterCache.Testing () );
	
EndProcedure

&AtClient
Procedure Loading ( Result, Params ) export
	
	if ( Result = undefined ) then
		return;
	endif;
	Items.List.Refresh ();

EndProcedure
