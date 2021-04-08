// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadFilter ();
	init ();
	fillGallery ();
	initNavigation ();
	setTitle ();
	show ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|FormPrevious FormNext show Bound > 0;
	|Photo FormLoad Description show Bound > -1;
	|FormLoadFirst show Bound = -1;
	|EmptyGallery show Bound = -1 and not CanEdit;
	|PhotoContextMenuLoad FormLoad PhotoContextMenuDelete show CanEdit
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadFilter ()
	
	Reference = Parameters.Filter.Reference;
	
EndProcedure 

&AtServer
Procedure init ()
	
	meta = Reference.Metadata ();
	CanEdit = AccessRight ( "Edit", meta );
	if ( meta = Metadata.Catalogs.Items ) then
		RegisterName = "Gallery";
	elsif ( meta = Metadata.Documents.MobileReport ) then
		RegisterName = "MobileReports";
	endif; 
	
EndProcedure 

&AtServer
Procedure fillGallery ()
	
	Gallery.Clear ();
	table = getGallery ();
	for each row in table do
		s = ? ( row.Description = "", "", row.Description + ", " ) + row.User + ", " + Conversion.DateToString ( row.Date );
		Gallery.Add ( row.ID, s );
	enddo; 
	
EndProcedure 

&AtServer
Function getGallery ()
	
	s = "
	|select Gallery.ID as ID, Gallery.Description as Description, Gallery.User.Description as User,
	|	Gallery.Date as Date
	|from InformationRegister." + RegisterName + " as Gallery
	|where Gallery.Reference = &Product
	|order by Gallery.Date
	|";
	q = new Query ( s );
	q.SetParameter ( "Product", Reference );
	return q.Execute ().Unload ();
	
EndFunction 

&AtServer
Procedure initNavigation ( AtStart = true )
	
	Bound = Gallery.Count () - 1;
	if ( AtStart ) then
		Index = Min ( Bound, 0 );
	else
		Index = Bound;
	endif; 

EndProcedure 

&AtServer
Procedure setTitle ()
	
	s = "" + Reference;
	if ( Bound > 0 ) then
		s = s + " (" + ( Index + 1 ) + "/" + ( Bound + 1 ) + ")";
	endif; 
	Title = s;

EndProcedure 

&AtServer
Procedure show ()
	
	if ( Index < 0 ) then
		return;
	endif; 
	data = Gallery [ Index ];
	p = new Structure ( "Reference, ID", Reference, data.Value );
	binary = container ().Get ( p ).Photo.Get ();
	Photo = PutToTempStorage ( binary );
	Description = data.Presentation;
	
EndProcedure 

&AtServer
Function container ()
	
	return InformationRegisters [ RegisterName ];
	
EndFunction 

// *****************************************
// *********** Group Form

&AtClient
Procedure Load ( Command )
	
	loadPhoto ();
	
EndProcedure

&AtClient
Procedure loadPhoto ()
	
	callback = new NotifyDescription ( "NewPhoto", ThisObject );
	Images.Load ( callback, UUID );
	
EndProcedure 

&AtClient
Procedure NewPhoto ( Data, Params ) export
	
	ShowInputString ( new NotifyDescription ( "PictureDescription", ThisObject, Data.Picture ), , Output.PictureDescription () );
	
EndProcedure 

&AtClient
Procedure PictureDescription ( Description, Picture ) export
	
	complete ( Description, Picture );
	
EndProcedure 

&AtServer
Procedure complete ( val Description, val Picture )
	
	savePhoto ( Description, Picture );
	showLast ();
	
EndProcedure 

&AtServer
Procedure savePhoto ( Description, Photo )
	
	r = container ().CreateRecordManager ();
	r.Reference = Reference;
	r.ID = new UUID ();
	r.Photo = new ValueStorage ( GetFromTempStorage ( Photo ) );
	r.Description = Description;
	r.Date = CurrentSessionDate ();
	r.User = SessionParameters.User;
	r.Write ();
	
EndProcedure 

&AtServer
Procedure showLast ()
	
	fillGallery ();
	initNavigation ( false );
	setTitle ();
	show ();
	Appearance.Apply ( ThisObject );
	
EndProcedure 

&AtClient
Procedure Next ( Command )
	
	slide ( 1 );
	
EndProcedure

&AtClient
Procedure slide ( Direction )
	
	Index = Index + Direction;
	if ( Index = -1 ) then
		Index = Bound;
	elsif ( Index > Bound ) then
		Index = 0;
	endif; 
	changePhoto ();
	
EndProcedure 

&AtServer
Procedure changePhoto ()
	
	setTitle ();
	show ();
	
EndProcedure 

&AtClient
Procedure Previous ( Command )
	
	slide ( -1 );
	
EndProcedure

&AtClient
Procedure Delete ( Command )
	
	Output.DeletePictureConfirmation ( ThisObject );
	
EndProcedure

&AtClient
Procedure DeletePictureConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	deletePhoto ();
	
EndProcedure 

&AtServer
Procedure deletePhoto ()
	
	cleanData ();
	setTitle ();
	show ();
	Appearance.Apply ( ThisObject );
	
EndProcedure 

&AtServer
Procedure cleanData ()
	
	data = Gallery [ Index ];
	r = container ().CreateRecordManager ();
	r.Reference = Reference;
	r.ID = data.Value;
	r.Delete ();
	Gallery.Delete ( Index );
	Bound = Bound - 1;
	Index = Min ( Index, Bound );
	
EndProcedure 

&AtClient
Procedure PhotoClick ( Item, StandardProcessing )
	
	StandardProcessing = false;
	if ( not CanEdit ) then
		return;
	endif; 
	if ( Bound = -1 ) then
		loadPhoto ();
	elsif ( Bound > 0 ) then
		slide ( 1 );
	endif; 
	
EndProcedure
