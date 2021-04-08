
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "WaybillTruck";
	p.Name = "WaybillTruck";
	Print.Print ( p );
	
EndProcedure
