// Create a new project and attach file
// Then, download that file and compare with original

Call ( "Common.Init" );
CloseAll ();

content = "Test";

#region upload
project = "Project " + Call ( "Common.ScenarioID", "2D0D1063" );
Commando("e1cib/command/Catalog.Projects.Create");
Put("#Owner", "ABC Distributions");
Set("#Description", project);
file = GetTempFileName("txt");
doc = new TextDocument();
doc.SetText ( content );
doc.Write(file);
App.SetFileDialogResult ( true, file );
Activate("#Attachments");
Click("#AttachmentsUpload");
DeleteFiles(file);
#endregion

#region donwload
folder = GetTempFileName ();
CreateDirectory(folder);
App.SetFileDialogResult ( true, folder );
Click("#AttachmentsDownload");
#endregion

#region check
Pause ( 1 );
Click ( "#Button1", DialogsTitle ); // Button No
newFile = folder + "/" + FileSystem.GetFileName ( file );
reader = new TextReader (file);
Assert ( reader.Read () ).Equal (content);
#endregion