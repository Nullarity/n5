// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	UserTasks.InitList ( List );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure OperationFilterOnChange ( Item )
	
	filterByOperation ();
	
EndProcedure

&AtServer
Procedure filterByOperation ()
	
	DC.ChangeFilter ( List, "Operation", OperationFilter, not OperationFilter.IsEmpty () );
	
EndProcedure 

// *****************************************
// *********** List

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	UserTasks.Click ( Item, SelectedRow, Field, StandardProcessing );
	
EndProcedure

