// *****************************************
// *********** Group Form

&AtClient
Procedure CarFilterOnChange ( Item )
	
	setFilterByCar ();
	
EndProcedure

&AtServer
Procedure setFilterByCar ()
	
	DC.ChangeFilter ( List, "Car", CarFilter, not CarFilter.IsEmpty () );
	
EndProcedure 

&AtClient
Procedure DriverFilterOnChange ( Item )
	
	setFilterByDriver ();
	
EndProcedure

&AtServer
Procedure setFilterByDriver ()
	
	DC.SetParameter ( List, "Driver", DriverFilter, not DriverFilter.IsEmpty () );
	
EndProcedure 
