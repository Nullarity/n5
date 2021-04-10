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
p.Exceptions = exceptions;
Call("Tester.Execute", p);
