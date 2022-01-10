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
	
	Mobile = Environment.MobileClient ();
	settings = Logins.Settings ( "Warehouse" );
	WarehouseFilter = settings.Warehouse;
	filterByWarehouse ();
	InProgress = true;
	filterByProgress ();
	
EndProcedure

&AtServer
Procedure filterByWarehouse ()
	
	DC.ChangeFilter ( List, "Warehouse", WarehouseFilter, not WarehouseFilter.IsEmpty () );
	
EndProcedure

&AtServer
Procedure filterByProgress ()
	
	DC.ChangeFilter ( List, "Invoiced", not InProgress, InProgress );
	Appearance.Apply ( ThisObject, "InProgress" );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Invoiced show not InProgress;
	|Date Memo Creator show not Mobile
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

// *****************************************
// *********** List

&AtClient
Procedure WarehouseFilterOnChange ( Item )
	
	filterByWarehouse ();
	
EndProcedure

&AtClient
Procedure InProgressOnChange ( Item )
	
	filterByProgress ();
	
EndProcedure
