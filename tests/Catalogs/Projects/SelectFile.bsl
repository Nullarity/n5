// Create a new project and attach file
// Then, select this file (dblclk on that file)

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

#region click
Pause(1);
Get ( "#Attachments" ).Choose ();
#endregion
