// Before running this test make sure 1c-enterprise server had been
// restarted after the latest edt update. Otherwise, ring utility will not
// be found

// Parameters
platform = "8.3.18.1334";
edt = "edt@2021.1.0:x86_64";

// Routine
p = Call("Tester.Execute.Params");
p.Platform = "C:\Program Files\1cv8\" + platform + "\bin\1cv8.exe";
p.EDT = edt;
p.Application = "Cont5";
p.Server = "localhost:1841";
p.ServerIBName = "Cont5";
p.IBName = "Cont5";
p.IBUser = "root";
p.Restore = "C:\Users\Administrator\Desktop\TestCont5\init.dt";
p.TestEnvironment = "TotalTest.TestEnvironment";
p.Folder = "Core";
p.Project = "Cont5";
p.Workspace = "c:\users\administrator\Cont5";
p.GitFolder = "c:\users\administrator\git\Cont5";
p.GitUser = "grumegargler";
p.GitPassword = "e1egance";
p.GitRepo = "gitlab.com/Grumegargler/Cont5";
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
