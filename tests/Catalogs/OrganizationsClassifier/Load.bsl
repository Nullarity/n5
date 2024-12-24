// Load Organizations Classifier from XLSX file

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A1B1" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

Commando ( "e1cib/list/Catalog.OrganizationsClassifier" );
App.SetFileDialogResult ( true, this.File );
Click ( "#FormLoad" );

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "File", TempFilesDir () + "/organizationsClassifier.xlsx" );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;

	stack  = Debug.Stack [ Debug.Level ];
	template = RuntimeSrv.GetSpreadsheet ( stack.Module, stack.IsVersion ).Template;
	template.Write ( this.File, SpreadsheetDocumentFileType.XLSX );

	RegisterEnvironment ( id );

EndProcedure
