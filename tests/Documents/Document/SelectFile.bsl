// Create a new document and attach a file
// Then, select this file (dblclk on that file)

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

#region previewAttachment
Get("#DocumentsList").Choose();
With();
Get ( "#Attachments" ).Choose ();
#endregion