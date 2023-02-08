
&AtClient
Procedure CommandProcessing ( CommandParameter, ExecuteParameters )
	
	object = ExecuteParameters.Source.Object;
	p = new Structure ( "Document, Date", object.Ref, object.Date );
	OpenForm ( "CommonForm.Date", p );
	
EndProcedure
