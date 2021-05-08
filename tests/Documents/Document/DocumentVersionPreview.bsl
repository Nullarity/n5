// Create a new document, attach a file and publish
// Then, open document version and preview the file

Call ( "Common.Init" );
CloseAll ();

content = "Test";
documentContent = "Hello World";

#region upload
document = "document " + Call ( "Common.GetID" );
Commando("e1cib/command/Document.Document.Create");
Set("#Subject", document);
Set("#TextEditor", documentContent);
file = GetTempFileName("txt");
doc = new TextDocument();
doc.SetText ( content );
doc.Write(file);
App.SetFileDialogResult ( true, file );
Activate("#Attachments");
Click("#AttachmentsUpload");
Pause(2);
DeleteFiles(file);
#endregion

#region publish
Click("#FormPublish");
Click("#Button0", DialogsTitle); // Yes, publish
Click("#Button0", DialogsTitle); // Yes, without access
#endregion

#region openList
Commando("e1cib/list/Document.Document");
p = Call("Common.Find.Params");
p.Button = "#DocumentsListContextMenuFind";
p.Where = "Subject";
p.What = document;
p = Call("Common.Find", p);
#endregion

#region openVersion
Get("#DocumentsList").Choose();
With();
Activate ( "#ChangesPage" ); // Changes
Changes = Get ( "#Changes" );
Activate ( "#ChangesVersion" );
Changes.Choose ();
#endregion

#region checkVersion
With();
Assert(Fetch("#Preview")).Contains(documentContent);
Get ( "#Attachments" ).Choose ();
#endregion