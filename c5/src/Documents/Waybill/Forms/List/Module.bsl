// *****************************************
// *********** Form events

&AtServer
Procedure OnLoadDataFromSettingsAtServer ( Settings )
	
	setFilterByCar ();
	setFilterByDriver ();
	
EndProcedure

&AtServer
Procedure setFilterByCar ()
	
	DC.ChangeFilter ( List, "Car", CarFilter, not CarFilter.IsEmpty () );
	
EndProcedure 

&AtServer
Procedure setFilterByDriver ()
	
	DC.SetParameter ( List, "Driver", DriverFilter, not DriverFilter.IsEmpty () );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure CarFilterOnChange ( Item )
	
	setFilterByCar ();
	
EndProcedure

&AtClient
Procedure DriverFilterOnChange ( Item )
	
	setFilterByDriver ();
	
EndProcedure
