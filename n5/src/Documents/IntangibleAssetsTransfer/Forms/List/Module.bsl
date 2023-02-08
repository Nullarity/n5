// *****************************************
// *********** Group Form

&AtClient
Procedure SenderFilterOnChange(Item)

	filterBySender ();
	
EndProcedure

&AtClient
Procedure filterBySender ()
	
	DC.ChangeFilter ( List, "Sender", SenderFilter, ValueIsFilled ( SenderFilter ) );
	
EndProcedure

&AtClient
Procedure ResponsibleFilterOnChange(Item)

	filterByResponsible ();
	
EndProcedure

&AtClient
Procedure filterByResponsible ()
	
	DC.ChangeFilter ( List, "Responsible", ResponsibleFilter, ValueIsFilled ( ResponsibleFilter ) );
	
EndProcedure
