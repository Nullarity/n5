// *****************************************
// *********** Group Form

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	openRecord ( Item, SelectedRow );
	
EndProcedure

&AtClient
Procedure openRecord ( Item, RecordKey )
	
	OpenForm ( "InformationRegister.ScheduledReports.RecordForm", new Structure ( "Key", RecordKey ), Item );
	
EndProcedure 
