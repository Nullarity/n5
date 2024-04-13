&AtClient
var OldRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	ChatForm.Prepare ( ThisObject );
	loadFixedSettings ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Assistant show empty ( AssistantFilter );
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadFixedSettings ()
	
	DC.SetParameter ( List, "Source", Parameters.Source );
	
EndProcedure 

&AtServer
Procedure filterByAssistant ()
	
	DC.ChangeFilter ( List, "Assistant", AssistantFilter, not AssistantFilter.IsEmpty () );
	Appearance.Apply ( ThisObject, "AssistantFilter" );
	
EndProcedure

&AtClient
Procedure OnClose ( Exit )
	
	if ( not Exit ) then
		cancelSearch ( true );
	endif; 
	
EndProcedure

&AtServer
Procedure cancelSearch ( val Closing = false )
	
	job = Jobs.GetByID ( SearchJob );
	if ( job <> undefined ) then
		job.Cancel ();
	endif; 
	if ( Closing ) then
		return;
	endif; 
	DC.DeleteFilter ( List, "Ref" );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure AssistantFilterOnChange ( Item )
	
	filterByAssistant ();
	
EndProcedure

&AtClient
Procedure SearchStringEditTextChange ( Item, Text, StandardProcessing )
	
	scheduleSearch ( Item, Text );
	
EndProcedure

&AtClient
Procedure scheduleSearch ( Item, Text )
	
	detachSeach ();
	SearchItem = Item;
	SearchItem.ChoiceButton = true;
	SearchString = Text;
	SearchStarted = true;
	AttachIdleHandler ( "startSearch", 0.5, true );
	
EndProcedure 

&AtClient
Procedure detachSeach ()
	
	DetachIdleHandler ( "checkSearch" );
	DetachIdleHandler ( "startSearch" );
	
EndProcedure 

&AtClient
Procedure startSearch ()
	
	if ( IsBlankString ( SearchString )
		or StrLen ( SearchString ) < 3 ) then
		cancelSearch ();
		completeSearching ();
	else
		SearchJob = runSearch ( SearchString, UUID, SearchJob, SearchResult );
		AttachIdleHandler ( "checkSearch", 1, true );
	endif;
	
EndProcedure

&AtClient
Procedure completeSearching ()
	
	SearchStarted = false;
	Items.SearchString.ChoiceButton = false;
	
EndProcedure 

&AtClient
Procedure checkSearch () export
	
	if ( searchCompleted ( SearchJob ) ) then
		refs = GetFromTempStorage ( SearchResult );
		DC.ChangeFilter ( List, "Ref", refs, true );
		completeSearching ();
	else
		AttachIdleHandler ( "checkSearch", 1, true );
	endif; 
	
EndProcedure 

&AtServerNoContext
Function searchCompleted ( val ID )
	
	return Jobs.GetByID ( ID ) = undefined;
	
EndFunction 

&AtServerNoContext
Function runSearch ( val SearchString, val UUID, val SearchJob, SearchResult )
	
	SearchResult = PutToTempStorage ( undefined, UUID );
	params = new Array ();
	params.Add ( SearchString );
	params.Add ( Enums.Search.Chat );
	params.Add ( SearchResult );
	params.Add ( SearchJob );
	return Jobs.Run ( "FullSearch.Background", params ).UUID;
	
EndFunction 

&AtClient
Procedure SearchStringStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	
EndProcedure

&AtClient
Procedure SearchStringClearing ( Item, StandardProcessing )
	
	scheduleSearch ( Item, "" );
	
EndProcedure

// *****************************************
// *********** List

&AtClient
Procedure ListOnActivateRow ( Item )
	
	showChat ();
	
EndProcedure

&AtClient
Procedure showChat ()
	
	DetachIdleHandler ( "loadMessages" );
	AttachIdleHandler ( "loadMessages", 0.5, true );
	
EndProcedure

&AtClient
Procedure loadMessages () export
	
	row = Items.List.CurrentData;
	if ( row = undefined or
		row = OldRow ) then
		return
	endif;
	OldRow = row;
	ref = undefined;
	row.Property ( "Ref", ref );
	if ( ref = undefined ) then
		cleanMessages ();
	else
		loadChat ( ref );
	endif;
	
EndProcedure

&AtClient
Procedure cleanMessages ()
	
	Chat.Body = "";
	Files.Clear ();
	
EndProcedure

&AtServer
Procedure loadChat ( val Ref )
	
	Server = DF.Pick ( Ref.Assistant, "Server" );
	ChatForm.SetBody ( Chat, Ref );
	Files.Clear ();
	for each row in Ref.Files do
		Files.Add ( row.ID, row.Link );
	enddo;
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	NotifyChoice ( PredefinedValue ( "Document.Chat.EmptyRef" ) );
	
EndProcedure

// *****************************************
// *********** HTML

&AtClient
Procedure HTMLOnClick ( Item, EventData, StandardProcessing )
	
	StandardProcessing = false;
	ChatForm.OnClick ( Files, Server, "", Item, EventData );

EndProcedure
