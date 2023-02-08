// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	UserTasks.InitList ( List );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure RoomFilterOnChange ( Item )
	
	filterByRoom ();
	
EndProcedure

&AtServer
Procedure filterByRoom ()
	
	DC.ChangeFilter ( List, "Room", RoomFilter, not RoomFilter.IsEmpty () );
	
EndProcedure

// *****************************************
// *********** List

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	UserTasks.Click ( Item, SelectedRow, Field, StandardProcessing );
	
EndProcedure

