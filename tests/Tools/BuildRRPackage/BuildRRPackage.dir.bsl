// zip must contain:
// index.v1.json
// .module.txt
// .export.txt
// .mxl

StandardProcessing = false;

env = _;

list = new Array ();
for each item in Env.Update do
	scenario = Test.FindScenario ( item ).Scenario;
	try
		scenarioExport = Test.FindScenario ( item + "_Export" ).Scenario;
	except
		scenarioExport = undefined;
	endtry;	
	list.Add ( new Structure ( "Scenario, ScenarioExport", scenario, scenarioExport ) );
enddo;
Env.Update = list;

path = env.Path + "\";
zip = new ZipFileWriter ( path + "Reports_" + env.Release + ".zip" );

data = getData ( env );
text = new TextDocument ();
text.SetText ( data.Json );

fileName = path + "index.v1.json";
text.Write ( fileName );
zip.Add ( fileName );
for each row in data.Files do
	fileName = path + row.FileName;
	if ( row.IsText ) then
		text = new TextDocument ();
		text.SetText ( row.Data );	
		text.Write ( fileName )
	else
		tabDoc = row.Data;
		tabDoc.Write ( fileName ); 
	endif;
	zip.Add ( fileName );
enddo;
zip.Write ();

&AtServer
Function getData ( Env )

	jsonList = new Array ();
	files = new Array ();
	for each row in Env.Update do
		data = DF.Values ( row.Scenario, "Template, Script, Description as ID, Memo as Description, Parent.Description as Period" );
		id = data.ID;
		jsonList.Add ( new Structure ( "Action, ID, Description, Period", "Update", id, data.Description, data.Period ) );
		files.Add ( new Structure ( "IsText, FileName, Data", false, id + ".mxl", data.Template.Get () ) );
		files.Add ( new Structure ( "IsText, FileName, Data", true, id + ".module.txt", data.Script ) );
		scenarioExport = row.ScenarioExport;
		if ( scenarioExport = undefined ) then
			script = "";
		else
			script = DF.Pick ( scenarioExport, "Script" );
		endif;
		files.Add ( new Structure ( "IsText, FileName, Data", true, id + ".export.txt", script ) );
	enddo;
	for each item in Env.Remove do
		jsonList.Add ( new Structure ( "Action, ID", "Remove", item ) );
	enddo;
	return new Structure ( "Json, Files", Conversion.ToJSON ( jsonList ), files );

EndFunction