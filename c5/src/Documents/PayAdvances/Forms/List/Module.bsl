// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	UserTasks.InitList ( List );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure EmployeeFilterOnChange ( Item )
	
	filterByEmployee ();
	
EndProcedure

&AtServer
Procedure filterByEmployee ()
	
	DC.ChangeFilter ( List, "Totals.Employee", EmployeeFilter, not EmployeeFilter.IsEmpty () );
	
EndProcedure 

// *****************************************
// *********** List

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	UserTasks.Click ( Item, SelectedRow, Field, StandardProcessing );
	
EndProcedure
