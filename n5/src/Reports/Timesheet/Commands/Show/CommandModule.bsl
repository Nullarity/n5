
&AtClient
Procedure CommandProcessing ( Employees, Params )
	
	p = ReportsSystem.GetParams ( "Timesheet" );
	OpenForm ( "Report.Common.Form", p, Params.Source, true, Params.Window );
	
EndProcedure
