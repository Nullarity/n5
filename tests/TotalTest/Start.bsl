// Before running this test make sure 1c-enterprise server had been
// restarted after the latest edt update. Otherwise, ring utility will not
// be found

// Parameters
platform = "8.3.18.1363";
edt = "edt@2021.1.1:x86_64";

// Routine
p = Call("Tester.Execute.Params");
p.Platform = "/opt/1cv8/x86_64/" + platform + "/1cv8";
p.EDT = edt;
p.Application = AppName;
p.Server = "localhost";
p.ServerIBName = AppName;
p.IBName = AppName;
p.IBUser = "root";
p.Restore = "/home/dmitry/testing/" + AppName + "/init.dt";
p.TestEnvironment = "TotalTest.TestEnvironment";
p.Project = AppName;
p.Workspace = "/home/dmitry/" + AppName;
p.GitFolder = "/home/dmitry/git/" + AppName;
p.GitUser = "nullarity";
p.GitPassword = "d0st0primechatelnost";
p.GitRepo = "github.com/contabilizare/c5";
p.TestingOnly = _ <> undefined and _ = "TestingOnly";
exceptions = new Array();
exceptions.Add("Documents.Document.ChangeBook");
exceptions.Add("Documents.Document.CopyDocumentWithFiles");
exceptions.Add("Documents.Document.CopyDocumentWithSpreadsheetOnly");
exceptions.Add("Documents.Document.ExportPrintFormToDocument");
exceptions.Add("Documents.Document.PrintFromForm");
exceptions.Add("Documents.Document.PrintFromList");
exceptions.Add("Documents.Document.PublishChangedFiles");
exceptions.Add("Documents.Document.RenameFile");
exceptions.Add("Documents.Document.TheSameSubject");
exceptions.Add("DataProcessors.Update.RegularUpdate");
exceptions.Add("DataProcessors.Update.SkipUpdate");

p.Exceptions = exceptions;

// Restore & update database 
if ( not p.TestingOnly ) then
	Call ( "Tester.Infobase.Deploy", p );
endif;
if ( p.UpdateOnly ) then
	return;
endif;

StoreScenarios ();

params = new Structure ();
params.Insert ( "Name", String ( p.Application ) );
params.Insert ( "Folder", p.Folder );
params.Insert ( "Exceptions", p.Exceptions );
list = Call ( "Tester.Scenarios", params );
batch = 5;
currentBatch = 0;
tests = list.Count ();
chunk = new Array ();
for each scenario in list do
	record = ParametersSpace ().JobRecord ();
	record.Scenario = scenario;
	record.PinApplication = p.Application;
	record.Disconnect = false;
	chunk.Add ( record );
	currentBatch = currentBatch + 1;
	if ( currentBatch = batch ) then
		NewJob ( "Tester", chunk );
		currentBatch = 0;
		chunk = new Array ();
	endif;
enddo;
