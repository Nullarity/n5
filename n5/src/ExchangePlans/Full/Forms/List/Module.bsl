
&AtServer 
var BaseNode;

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setMasterNode ();
	
EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	setEnableCreateInitialImage ();
	
EndProcedure

&AtServer
Procedure setMasterNode ()
	
	MasterNode = ( ExchangePlans.MasterNode () = Undefined );	
	
EndProcedure 

&AtClient
Procedure CreateInitialImage ( Command )
	
	if ( not ValueIsFilled ( Items.List.CurrentRow ) ) then
		return;
	endif;
	selectFolderBase ();
	
EndProcedure

&AtClient 
Procedure selectFolderBase ()
	
	LocalFiles.Prepare ( new NotifyDescription ( "OpenDialog", ThisObject ) );
	
EndProcedure

&AtClient
Procedure OpenDialog ( Result, Params ) export
	
	dialog = new FileDialog ( FileDialogMode.ChooseDirectory );
	dialog.Title = Output.ChooseFolderImage ();
	dialog.Show ( new NotifyDescription ( "SelectFolder", ThisObject ) );
	
EndProcedure

&AtClient
Procedure SelectFolder ( Result, Params ) export
	
	if ( Result = undefined ) then
		return;
	endif; 
	folderBase = Result [ 0 ];
	ShowUserNotification ( Output.DataExchange (), , Output.CreateInitialImage () , PictureLib.CreateInitialImage );	
	completed = createImageServer ( Items.List.CurrentRow, folderBase );
	if ( completed ) then
		ShowUserNotification ( Output.DataExchange (), , Output.InitialImageCompleted  () , PictureLib.CreateInitialImage );
		ShowMessageBox ( , Output.OperationCompleted () );
	endif; 
	
EndProcedure

&AtServer
Function createImageServer ( Node, FolderBase )
	
	return ( ExchangePlans.Full.CreateImage ( Node, FolderBase ) );
	
EndFunction

&AtClient
Procedure ListOnActivateRow ( Item )
	
	setEnableCreateInitialImage ();
	
EndProcedure

&AtClient
Procedure setEnableCreateInitialImage ()
	
	if ( Items.List.CurrentData = undefined ) then
		value = false;
	else
		value = not Items.List.CurrentData.ThisNode;
	endif;
	Items.CreateInitialImage.Enabled = value;
	
EndProcedure