// Before running this test make sure 1c-enterprise server had been
// restarted after the latest edt update. Otherwise, ring utility will not
// be found

// Parameters
platform = "8.3.20.1789";
edt = "edt@2022.2.3:x86_64";

// Routine
p = Call("Tester.Execute.Params");
p.Platform = "/opt/1cv8/x86_64/" + platform + "/1cv8";
p.EDT = edt;
p.Application = AppName;
p.Server = "localhost";
p.ServerIBName = AppName;
p.IBName = AppName + ", local, server";
p.IBUser = "root";
p.PermissionCode = "ConfigurationUpdate";
p.Restore = "/home/dmitry/testing/" + AppName + "/init.dt";
p.TestEnvironment = "TotalTest.TestEnvironment";
p.Project = AppName;
p.Workspace = "/home/dmitry/testing/" + AppName + "/workspace";
p.GitFolder = "/home/dmitry/testing/" + AppName + "/sources";
p.GitUser = "nullarity";
p.GitPassword = Call ("Tools.GitPassword", , "System");
p.GitRepo = "github.com/nullarity/n5";
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
exceptions.Add("CommonForms.Settings.TestClosingAfterChangingLicense");

// Cost changers
exceptions.Add("Documents.AssetsTransfer.TestCreation.Start");
exceptions.Add("Documents.Commissioning.TestCreation.Start");
exceptions.Add("Documents.Disassembling.FullCreationTest.Start");
exceptions.Add("Documents.ExpenseReport.Start");
exceptions.Add("Documents.ExpenseReport.TestCurrency");
exceptions.Add("Documents.ExpenseReport.TestCurrencyCopy");
exceptions.Add("Documents.Inventory.TestCreation.Start");
exceptions.Add("DataProcessors.Cost.Commissioning" );
exceptions.Add("DataProcessors.Cost.Disassembling" );
exceptions.Add("DataProcessors.Cost.Invoice" );
exceptions.Add("DataProcessors.Cost.Retail" );
exceptions.Add("DataProcessors.Cost.Transfer" );
exceptions.Add("DataProcessors.Cost.VendorReturn" );
exceptions.Add("DataProcessors.Cost.WriteOff" );
exceptions.Add("DataProcessors.Cost.Assembling" );

// Regulatory reports
exceptions.Add("Reports.RegulatoryReports.1_Invest" );
exceptions.Add("Reports.RegulatoryReports.5_CI_2015" );
exceptions.Add("Reports.RegulatoryReports.5_CON" );
exceptions.Add("Reports.RegulatoryReports.AN5" );
exceptions.Add("Reports.RegulatoryReports.AN5J" );
exceptions.Add("Reports.RegulatoryReports.Balance" );
exceptions.Add("Reports.RegulatoryReports.BASS" );
exceptions.Add("Reports.RegulatoryReports.IALS14" );
exceptions.Add("Reports.RegulatoryReports.IALS18" );
exceptions.Add("Reports.RegulatoryReports.IPC18" );
exceptions.Add("Reports.RegulatoryReports.IRV14" );
exceptions.Add("Reports.RegulatoryReports.IVAO15" );
exceptions.Add("Reports.RegulatoryReports.MED08" );
exceptions.Add("Reports.RegulatoryReports.REV9" );
exceptions.Add("Reports.RegulatoryReports.SERV_TS_2014" );
exceptions.Add("Reports.RegulatoryReports.SERV_TS_2014_RO" );
exceptions.Add("Reports.RegulatoryReports.TVA12" );
p.Exceptions = exceptions;
params = new Structure ();
params.Insert ( "Name", String ( p.Application ) );
params.Insert ( "Folder", p.Folder );
params.Insert ( "Exceptions", p.Exceptions );
list = Call ( "Tester.Scenarios", params );

agents = 10;
batch = 1;

StoreScenarios ();
for i = 1 to agents do
	NewJob ( "tester", "TotalTest.DisconnectClients", , , "tc" + i );
enddo;

Pause (60);

// Restore & update database 
if ( not p.TestingOnly ) then
	Call ( "Tester.Infobase.Deploy", p );
endif;

if ( p.UpdateOnly ) then
	return;
endif; 

//return;

listSize = list.Count () - 1;
chunk = new Array ();
job = CurrentDelegatedJob.Job;
for i = 0 to batch - 1 do
	k = 0;
	j = i;
	while ( j <= listSize ) do
		if ( k = 0 ) then
			if ( chunk.Count () > 0 ) then
				NewJob ( "Tester", chunk, , , , , , job );
			endif;
			chunk.Clear ();
		endif;
		record = ParametersSpace ().JobRecord ();
		record.Scenario = list [ j ];
		record.PinApplication = p.Application;
		record.Disconnect = false;
		chunk.Add ( record );
		k = ? ( k = batch, 0, k + 1 );
		j = j + batch;
	enddo;
	NewJob ( "Tester", chunk, , , , , , job );
	chunk.Clear ();
enddo;

params.Insert ( "Agents", agents );
params.Insert ( "Job", job );
NewJob ( "Tester", "TotalTest.OneThread", , job, , , , job );
