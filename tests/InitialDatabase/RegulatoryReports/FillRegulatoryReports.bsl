Call ( "Common.Init" );
CloseAll ();

StandardProcessing = false;
App.SetMaxActionExecutionTime ( 30 );

// *************************
// Create Master Report
// *************************

// Open reports
Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
list = With ();
Click ( "#ListShowMasters" );

data = getData ();
for each item in data.Reports do
	With ( list );                                     

	Click ( "#ListContextMenuFind" );
	With ();
	Set ( "#Pattern", Item.Description );
	Set ( "#CompareType", "Exact match" );
	Click ( "#Find" );
	With ();
	exists = Call ( "Table.Count", Get ( "#List" ) ) > 0;
	Click ( "#ListContextMenuCancelSearch" );
	if ( exists ) then
		Click ( "#ListChange" );
	else
		Click ( "#ListCreate" );
	endif;
	form = With ();
	Set ( "#Description", Item.Description );
	Set ( "#Name", Item.ID );
	Put ( "#Period", item.Period );
	Click ( "#FormWriteAndClose" );
	Pause ( 1 );

	// Design report
	With ( list );
	
	Click ( "#Design" );
	p = Call ( "RegulatoryReports.Load.Params" );
	p.Path = Item.Path;
	Call ( "RegulatoryReports.Load", p );
	Pause ( 1 );
	Next ();
	With ();
	Click ( "#Build" );
enddo;

for each item in data.Exports do
	With ( list );                                     
	GotoRow ( "#List", "Description", Item.Description );
	
	Pause ( 1 );
	
	Click ( "#Design" );
	p = Call ( "RegulatoryReports.Load.Params" );
	p.Path = Item.Path;
	Call ( "RegulatoryReports.LoadExport", p );
	Pause ( 1 );
	With ( list );
	Click ( "#Build" );
enddo;

// *************************
// Procedures
// *************************

&AtServer
Function getData ()
	
	s = "
	|select allowed Scenarios.Path as Path, Scenarios.Memo as Description, Scenarios.Description as ID, 
	|	Scenarios.Parent.Description as Period, 
	|	case when Scenarios.Description like ""%_Export"" then true else false end as Export
	|from Catalog.Scenarios as Scenarios
	|where not Scenarios.DeletionMark
	|and Scenarios.Path like ""InitialDatabase.RegulatoryReports%""
	|and Scenarios.Type = value ( Enum.Scenarios.Method )
	|and Scenarios.Application.Description = &Application
	|and Scenarios.Path not like ""Trash%""
	|and Scenarios.Path not like ""InitialDatabase.RegulatoryReports.FillRegulatoryReports""
	|and Scenarios.Path not like ""InitialDatabase.RegulatoryReports.Old.%""
	|order by case when Scenarios.Description = ""DefaultValues"" then 1 else 2 end,
	|	case when Scenarios.Description like ""%_Export"" then 2 else 1 end,
	|	Scenarios.Description
	|";
	q = new Query ( s );
	q.SetParameter ( "Application", "Cont5" );
	table = q.Execute ().Unload ();
	array = new Array ();
	arrayExport = new Array ();
	for each row in table do
		struct = new Structure ( "Path, Description, ID, Period" );
		FillPropertyValues ( struct, row );
		if ( row.Export ) then
			struct.Description = StrReplace ( struct.Description, "_Export", "" );
			arrayExport.Add ( struct );
		else
			array.Add ( struct );
		endif;	
	enddo;
	return new Structure ( "Reports, Exports", array, arrayExport );
	
EndFunction