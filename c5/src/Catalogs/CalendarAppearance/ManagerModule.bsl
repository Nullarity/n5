#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure ChoiceDataGetProcessing ( ChoiceData, Parameters, StandardProcessing )
	
	StandardProcessing = false;
	items = getItems ();
	fillChoiceData ( ChoiceData, items );
	
EndProcedure

Function getItems ()
	
	s = "
	|select Items.Description as Description, Items.Ref as Ref, Items.BackColor as BackColor, Items.Color as TextColor
	|from Catalog.CalendarAppearance as Items
	|where not Items.DeletionMark
	|";
	q = new Query ( s );
	return q.Execute ().Unload ();
	
EndFunction 

Procedure fillChoiceData ( ChoiceData, Items )
	
	ChoiceData = new ValueList ();
	for each item in Items do
		presentation = new FormattedString ( item.Description, , Colors.Deserialize ( item.TextColor ), Colors.Deserialize ( item.BackColor ) );
		ChoiceData.Add ( item.Ref, presentation );
	enddo; 
	
EndProcedure 

#endif