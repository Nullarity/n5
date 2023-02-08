// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure init ()
	
	settings = Logins.Settings ( "Warehouse" );
	WarehouseFilter = settings.Warehouse;
	filterByWarehouse ();
	
EndProcedure

&AtServer
Procedure filterByWarehouse ()
	
	DC.ChangeFilter ( List, "Warehouse", WarehouseFilter, not WarehouseFilter.IsEmpty () );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Warehouse show empty ( WarehouseFilter )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

// *****************************************
// *********** List

&AtClient
Procedure WarehouseFilterOnChange ( Item )
	
	applyWarehouse ();
	
EndProcedure

&AtServer
Procedure applyWarehouse ()
	
	filterByWarehouse ();
	Appearance.Apply ( ThisObject, "WarehouseFilter" );
	
EndProcedure