// Create a new document and publish it
// Then, open it again, start editing and check context

Call ( "Common.Init" );
CloseAll ();

content = "Hello World";

#region newDocument
document = "document " + Call ( "Common.GetID" );
Commando("e1cib/command/Document.Document.Create");
Set("#Subject", document);
Set("#TextEditor", content);
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

#region editDocument
DocumentsList = Get ( "#DocumentsList" );
DocumentsList.Choose ();
With ();
Click ( "#FormEdit" );
Click ( "#Button0", DialogsTitle );
Check("#TextEditor", content);
#endregion