
&AtClient
Procedure ClassifiersStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	p = new Structure ();
	OpenForm ( "ExchangePlan.Classifiers.ChoiceForm", p, ThisObject, , , , new NotifyDescription ( "FillCode", ThisObject, p ) );
	
EndProcedure

&AtClient
Procedure FillCode ( Result, Params ) export
	
	if ( Result <> undefined and ValueIsFilled ( Result ) ) then
		Object.Classifiers = getCode ( Result ); 
	endif; 
	
EndProcedure 

&AtServerNoContext
Function getCode ( Ref )
	
	return Ref.Code; 

EndFunction 

&AtClient
Procedure ClassifiersOpening ( Item, StandardProcessing )
	
	if ( ValueIsFilled ( Object.Classifiers ) ) then
		StandardProcessing = false;
		node = getRef ( Object.Classifiers );
		if ( ValueIsFilled ( node ) ) then
			p = new Structure ();
			p.Insert ( "Key", node ); 
			form = GetForm ( "ExchangePlan.Classifiers.ObjectForm", p );
			form.Open ();
		endif;		
	endif; 
	
EndProcedure

&AtServerNoContext
Function getRef ( Code )
	
	return ExchangePlans.Classifiers.FindByCode ( Code ); 

EndFunction 

&AtClient
Procedure CreateInitialImage ( Command )
	
	if ( Object.Ref.IsEmpty () ) then
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
	completed = createImageServer ( folderBase );
	if ( completed ) then
		ShowUserNotification ( Output.DataExchange (), , Output.InitialImageCompleted  () , PictureLib.CreateInitialImage );
		ShowMessageBox ( , Output.OperationCompleted () );
	endif;
	
EndProcedure

&AtServer
Function createImageServer ( FolderBase )
	
	return ( ExchangePlans.Full.CreateImage ( Object.Ref, FolderBase ) );
	
EndFunction

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setImageEnabled ();
		
EndProcedure

&AtServer
Procedure setImageEnabled ()
	
	if ( Object.Ref.IsEmpty () ) then
		imageEnabled = false;
	else
		imageEnabled = not Object.ThisNode; 
	endif;
	Items.CreateInitialImage.Enabled = imageEnabled;
	
EndProcedure 