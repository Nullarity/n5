// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	UserTasks.InitList ( List );
	loadFilter ();
	adjustList ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|ItemFilter show empty ( FixedItem )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadFilter ()
	
	Parameters.Filter.Property ( "Item", FixedItem );
	
EndProcedure 

&AtServer
Procedure adjustList ()
	
	embedded = not FixedItem.IsEmpty ();
	if ( embedded ) then
		Items.List.Representation = TableRepresentation.List;
	endif;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure ItemFilterOnChange ( Item )
	
	filterByItem ();
	
EndProcedure

&AtServer
Procedure filterByItem ()
	
	DC.ChangeFilter ( List, "Item", ItemFilter, not ItemFilter.IsEmpty () );
	
EndProcedure

// *****************************************
// *********** List

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	UserTasks.Click ( Item, SelectedRow, Field, StandardProcessing );
	
EndProcedure
