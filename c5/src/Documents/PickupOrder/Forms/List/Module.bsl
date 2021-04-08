// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	filterByStatus ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
		
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Status show ( empty ( StatusFilter ) or StatusFilter = Enum.ShipmentPoints.All )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure init ()
	
	settings = Logins.Settings ( "Warehouse, Department" );
	WarehouseFilter = settings.Warehouse;
	
EndProcedure 

&AtServer
Procedure filterByStatus ()
	
	if ( StatusFilter.IsEmpty () ) then
		a = new Array ();
		a.Add ( Enums.ShipmentPoints.New );
		a.Add ( Enums.ShipmentPoints.Picking );
		DC.ChangeFilter ( List, "Status", a, true );
	else
		DC.ChangeFilter ( List, "Status", StatusFilter, StatusFilter <> Enums.ShipmentPoints.All );
	endif; 
	Appearance.Apply ( ThisObject, "StatusFilter" );
	
EndProcedure 

&AtServer
Procedure filterByWarehouse ()
	
	DC.ChangeFilter ( List, "Warehouse", WarehouseFilter, not WarehouseFilter.IsEmpty () );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure Create ( Command )
	
	newPickupOrder ();
	
EndProcedure

&AtClient
Procedure newPickupOrder ()
	
	p = new Structure ( "Warehouse", WarehouseFilter );
	OpenForm ( "DataProcessor.PickupOrder.Form", p, ThisObject );
	
EndProcedure 

&AtClient
Procedure StatusFilterOnChange ( Item )
	
	filterByStatus ();
	
EndProcedure

&AtClient
Procedure WarehouseFilterOnChange ( Item )
	
	filterByWarehouse ();
	
EndProcedure
