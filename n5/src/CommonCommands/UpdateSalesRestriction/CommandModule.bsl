
&AtClient
Procedure CommandProcessing ( Command, ExecuteParameters )

	params = ExecuteParameters.Parameters;
	Notify ( Enum.MessageUpdateSalesPermission (), params.Form );

EndProcedure
