
&AtClient
Procedure CommandProcessing ( CommandParameter, ExecuteParameters )
	
	object = ExecuteParameters.Source.Object;
	p = new Structure ( "Document, Date", Object.Ref, object.Date );
	OpenForm ( "CommonForm.Date", p );
	
EndProcedure
