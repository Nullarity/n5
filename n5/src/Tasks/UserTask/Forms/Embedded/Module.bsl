// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setFilter ();
	
EndProcedure

&AtServer
Procedure setFilter ()
	
	DC.SetParameter ( List, "Source", Parameters.Source );
	
EndProcedure

&AtClient
Procedure ListNewWriteProcessing ( NewObject, Source, StandardProcessing )
	
	type = TypeOf ( NewObject );
	if ( type = Type ( "BusinessProcessRef.Command" ) ) then
		StandardProcessing = false;
		Items.List.Refresh ();
	endif;

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure NewCommand ( Command )
	
	openCommand ();
	
EndProcedure

&AtClient
Procedure openCommand ()
	
	values = new Structure ( "Source", Parameters.Source );
	OpenForm ( "BusinessProcess.Command.ObjectForm", new Structure ( "FillingValues", values ), Items.List );
	
EndProcedure

&AtClient
Procedure NewTask ( Command )
	
	openTask ();
	
EndProcedure

&AtClient
Procedure openTask ()
	
	values = new Structure ( "Source", Parameters.Source );
	OpenForm ( "Task.UserTask.ObjectForm", new Structure ( "FillingValues", values ), Items.List );
	
EndProcedure

// *****************************************
// *********** List

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	if ( Field.Name = "BusinessProcess" ) then
		StandardProcessing = false;
		ShowValue ( , Item.CurrentData.BusinessProcess );
	endif;
	
EndProcedure
