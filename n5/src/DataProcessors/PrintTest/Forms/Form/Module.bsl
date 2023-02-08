
&AtClient
Procedure PrintForm ( Command )
	
	p = Print.GetParams ();
	p.Objects = Objects;
	p.Manager = "PrintTest";
	Print.Print ( p );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	Objects = Parameters.Objects;
	
EndProcedure
