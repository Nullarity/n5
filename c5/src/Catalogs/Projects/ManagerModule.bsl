#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure SetFolder ( Object ) export
	
	Object.FolderID = new UUID ();
	Object.Folder = Object.FolderID;
	
EndProcedure

Procedure ReadJunctions ( Source, Tables, MakeDirty = true ) export
	
	Attachments.Read ( Source, Tables.Attachments, MakeDirty );
	Tags.Read ( Source, Tables.Tags );
			
EndProcedure

Procedure SaveJunctions ( Ref, Tables ) export
	
	AttachmentsSrv.Save ( Ref, Tables.Attachments );
	Tags.Save  ( Ref, Tables.Tags );
	
EndProcedure

#region Printing
	
Function Print ( Params, Env ) export
	
	setDataParams ( Params, Env );
	Print.OutputSchema ( Env.T, Params.TabDoc );
	Print.SetFooter ( Params.TabDoc );
	Params.TabDoc.FitToPage = true;
	return true;
	
EndFunction

Procedure setDataParams ( Params, Env )
	
	Env.T.Parameters.Ref.Value = Params.Reference;
	
EndProcedure 

#endregion

#endif