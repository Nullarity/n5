&AtClient
var TableRow;

// *****************************************
// *********** Form events

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	sortStages ();
	
EndProcedure

&AtServer
Procedure sortStages ()
	
	Object.Performers.Sort ( "Stage" );
	
EndProcedure

// *****************************************
// *********** Performers

&AtClient
Procedure PerformersOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure Edit ( Command )
	
	editRow ();
	
EndProcedure

&AtClient
Procedure editRow ()
	
	if ( ReadOnly
		or TableRow = undefined ) then
		return;
	endif;
	OpenForm ( "Catalog.Commands.Form.Row", , ThisObject, , , , new NotifyDescription ( "PerformerChanged", ThisObject ) );
	
EndProcedure 

&AtClient
Procedure PerformerChanged ( Data, Params ) export
	
	if ( Data = undefined ) then
		return;
	endif;
	FillPropertyValues ( TableRow, Data, , "LineNumber" );
	
EndProcedure

&AtClient
Procedure PerformersSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	editRow ();
	
EndProcedure

&AtClient
Procedure PerformersBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	TableRow = Forms.NewRow ( ThisObject, Item, Clone );
	if ( not Clone ) then
		initRow ();
	endif;
	editRow ();
	
EndProcedure

&AtClient
Procedure initRow ()
	
	i = TableRow.LineNumber - 1;
	TableRow.Stage = ? ( i = 0, 1, Object.Performers [ i - 1 ].Stage + 1 );
	TableRow.Mandatory = true;
	
EndProcedure
