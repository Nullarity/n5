// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	UserTasks.InitList ( List );
	
EndProcedure

// *****************************************
// *********** List

&AtClient
Procedure ResponsibleFilterOnChange ( Item )
	
	filterByResponsible ();
	
EndProcedure

&AtServer
Procedure filterByResponsible ()
	
	DC.ChangeFilter ( List, "Responsible", ResponsibleFilter, not ResponsibleFilter.IsEmpty () );
	
EndProcedure

&AtClient
Procedure StatusFilterOnChange ( Item )
	
	filterByStatus ();
	
EndProcedure

&AtServer
Procedure filterByStatus ()
	
	DC.ChangeFilter ( List, "Status", StatusFilter, not StatusFilter.IsEmpty () );
	
EndProcedure

&AtClient
Procedure SourceFilterOnChange ( Item )
	
	filterBySource ();
	
EndProcedure

&AtServer
Procedure filterBySource ()
	
	DC.ChangeFilter ( List, "Source", SourceFilter, not SourceFilter.IsEmpty () );
	
EndProcedure

&AtClient
Procedure CampaignFilterOnChange ( Item )
	
	filterByCampaign ();
	
EndProcedure

&AtServer
Procedure filterByCampaign ()
	
	DC.ChangeFilter ( List, "Campaign", CampaignFilter, not CampaignFilter.IsEmpty () );
	
EndProcedure

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	UserTasks.Click ( Item, SelectedRow, Field, StandardProcessing );
	
EndProcedure
