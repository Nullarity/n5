// Create a new document and attach file
// Then, download that file and compare with original

Call ( "Common.Init" );
CloseAll ();

content = "Test";

#region upload
document = "document " + Call ( "Common.GetID" );
Commando("e1cib/command/Document.Document.Create");
Set("#Subject", document);
file = GetTempFileName("txt");
doc = new TextDocument();
doc.SetText ( content );
doc.Write(file);
App.SetFileDialogResult ( true, file );
Activate("#Attachments");
Click("#AttachmentsUpload");
Pause(1);
#endregion

#region donwload
folder = GetTempFileName ();
CreateDirectory(folder);
Click("#AttachmentsDownload");
#endregion

#region check
Pause ( 1 );
Click ( "#Button1", DialogsTitle ); // Button No
newFile = folder + "/" + file;
reader = new TextReader (file);
Assert ( reader.Read () ).Equal (content);
reader.Close();
#endregion

DeleteFiles(file);
DeleteFiles(newFile);
DeleteFiles(folder);