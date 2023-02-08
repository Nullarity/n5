// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadPicture ();
	
EndProcedure

&AtServer
Procedure loadPicture ()
	
	HTML = ImagesSrv.Image ( Parameters.ID );
	data = getData ();
	Title = data.Reference + ", " + data.Date + ", " + data.User + ? ( data.Description = "", "", ", " + data.Description );
	
EndProcedure 

&AtServer
Function getData ()
	
	s = "
	|select Gallery.Reference.Description as Reference, Gallery.Date as Date, Gallery.Description as Description,
	|	Gallery.User.Description as User
	|from InformationRegister.Gallery as Gallery
	|where Gallery.ID = &ID
	|";
	q = new Query ( s );
	q.SetParameter ( "ID", Parameters.ID );
	return q.Execute ().Unload () [ 0 ];
	
EndFunction 