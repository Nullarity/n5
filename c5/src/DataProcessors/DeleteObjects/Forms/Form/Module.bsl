&AtClient
var TableRow;
&AtClient
var OldObject;
&AtServer
var FoundObjects;
&AtServer
var UsedObjects;
&AtServer
var Command;
&AtServer
var Limit;
&AtServer
var Cache;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	fillObjectsTable ();
	fillRemovedTypes ();
	setFillMoreRelationsTitle ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|RemovingObjectsNotFound show ObjectsCount = 0;
	|RelationsNotFound show RelationsCount = 0;
	|FillMoreRelations show LimitAchieved;
	|RelationsSetDeletionMark enable RelationsCount > 0
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure retrieveObjects ()
	
	fillObjectsTable ();
	fillRemovedTypes ();
	
EndProcedure 

&AtServer
Procedure fillObjectsTable ()
	
	Objects.Clear ();
	SetPrivilegedMode ( true );
	data = FindMarkedForDeletion ();
	SetPrivilegedMode ( false );
	Cache = new Map ();
	for each item in data do
		if ( not isSeparated ( item ) ) then
			continue;
		endif; 
		row = Objects.Add ();
		row.Object = item;
		row.ObjectPresentation = "" + item;
		row.Use = true;
	enddo; 
	ObjectsCount = Objects.Count ();
	Appearance.Apply ( ThisObject, "ObjectsCount" );
	
EndProcedure 

&AtServer
Function isSeparated ( Item )
	
	meta = Item.Metadata ();
	if ( Cache [ meta ] = undefined ) then
		Cache [ meta ] = Metadata.CommonAttributes.Tenant.Content.Find ( meta ).Use <> Metadata.ObjectProperties.CommonAttributeUse.DontUse;
	endif; 
	return Cache [ meta ];
	
EndFunction 

&AtServer
Procedure fillRemovedTypes ()
	
	types = new Array ();
	for each meta in Cache do
		if ( meta.Value = false ) then
			continue;
		endif; 
		types.Add ( Metafields.ToType ( meta.Key ) );
	enddo;
	RemovedTypes = new TypeDescription ( types );
	
EndProcedure 

&AtServer
Procedure setFillMoreRelationsTitle ()
	
	s = Commands.FillMoreRelations.Title;
	Commands.FillMoreRelations.Title = Output.FormatStr ( s, new Structure ( "Count", getRelationsTableLimit () ) );
	
EndProcedure 

&AtServer
Function getRelationsTableLimit ()
	
	return 100;
	
EndFunction 

// *****************************************
// *********** Group Form

&AtClient
Procedure Remove ( Command )
	
	Output.RemoveObjectsConfirmation ( ThisObject );
	
EndProcedure

&AtClient
Procedure RemoveObjectsConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	if ( not removeSelectedObjects () ) then
		return;
	endif; 
	refreshDynamicLists ();
	after = Objects.Count ();
	if ( after = 0 ) then
		Output.RemovingObjectsCompleted ();
		Close ();
	else
		Output.RemovingObjectsNotCompleted ();
	endif; 
	
EndProcedure 

&AtServer
Function removeSelectedObjects ()
	
	selectedObjects = getSelectedObjects ();
	if ( selectedObjects.Count () = 0 ) then
		Output.RemovingObjectsNotSelected ( , "Objects", , "" );
		return false;
	endif; 
	SetPrivilegedMode ( true );
	SetExclusiveMode ( true );
	DeleteObjects ( selectedObjects, true );
	SetExclusiveMode ( false );
	SetPrivilegedMode ( false );
	fillObjectsTable ();
	return true;
	
EndFunction

&AtServer
Function getSelectedObjects ()
	
	selectedObjects = new Array ();
	for each row in Objects do
		if ( row.Use ) then
			selectedObjects.Add ( row.Object );
		endif; 
	enddo; 
	return selectedObjects;
	
EndFunction 

&AtClient
Procedure refreshDynamicLists ()
	
	types = RemovedTypes.Types ();
	for each type in types do
		NotifyChanged ( type );
	enddo; 
	
EndProcedure 

// *****************************************
// *********** Table Objects

&AtClient
Procedure MarkAll ( Command )
	
	Forms.MarkRows ( Objects, true );
	
EndProcedure

&AtClient
Procedure UnmarkAll ( Command )
	
	Forms.MarkRows ( Objects, false );
	
EndProcedure

&AtClient
Procedure Refresh ( Command )
	
	retrieveObjects ();
	
EndProcedure

&AtClient
Procedure ObjectsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	openObject ( Item );
	
EndProcedure

&AtClient
Procedure openObject ( Item )
	
	ShowValue ( , Item.CurrentData.Object );
	
EndProcedure 

&AtClient
Procedure ObjectsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure ObjectsBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure ObjectsOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	if ( TableRow = undefined
		or TableRow.Object = OldObject ) then
		return;
	endif; 
	OldObject = TableRow.Object;
	disableRelations ();
	
EndProcedure

&AtClient
Procedure disableRelations ()
	
	Relations.Clear ();
	RelationsCount = 0;
	Items.RelationsPages.CurrentPage = Items.RelationsInformation;
	Appearance.Apply ( ThisObject, "RelationsCount" );
	
EndProcedure 

// *****************************************
// *********** Table Relations

&AtClient
Procedure FillRelations ( Command )
	
	if ( TableRow = undefined ) then
		return;
	endif; 
	fillRelationsTable ( TableRow.Object, true );
	enableRelations ();
	
EndProcedure

&AtServer
Procedure fillRelationsTable ( SelectedObject, LimitRelations )
	
	Relations.Clear ();
	Command = "FillTable";
	LimitAchieved = false;
	Limit = ? ( LimitRelations, getRelationsTableLimit (), undefined );
	startProcessRelations ( SelectedObject );
	RelationsCount = Relations.Count ();
	Appearance.Apply ( ThisObject, "RelationsCount" );
	Appearance.Apply ( ThisObject, "LimitAchieved" );
	
EndProcedure

&AtServer
Procedure startProcessRelations ( SelectedObject )
	
	FoundObjects = new Map ();
	UsedObjects = new Map ();
	processRelations ( SelectedObject );
		
EndProcedure 

&AtServer
Procedure processRelations ( SelectedObject, Counter = 0 )

	if ( FoundObjects [ SelectedObject ] = undefined ) then
		FoundObjects [ SelectedObject ] = true;
	else
		return;
	endif; 
	references = new Array ();
	references.Add ( SelectedObject );
	table = FindByRef ( references );
	for each row in table do
		if ( Limit <> undefined and Counter = getRelationsTableLimit () ) then
			LimitAchieved = true;
			return;
		endif; 
		if ( UsedObjects [ row.Data ] = undefined ) then
			UsedObjects [ row.Data ] = true;
		else
			continue;
		endif; 
		Counter = Counter + 1;
		AnyRef = row.Data;
		if ( Command = "FillTable" ) then
			addDataToRelations ( AnyRef, row );
		elsif ( Command = "SetDeletionMark" ) then
			markDeletion ( AnyRef, row );
		endif; 
		if ( AnyRef = undefined ) then
			continue;
		endif; 
		processRelations ( AnyRef, Counter );
	enddo; 
	
EndProcedure 

&AtServer
Procedure addDataToRelations ( SelectedObject, Row )
	
	if ( SelectedObject = undefined ) then
		presentation = Row.Metadata.Presentation ();
		picture = 1;
	else
		presentation = "" + SelectedObject + ", " + Row.Metadata.Presentation ();
		deletionMark = DF.Pick ( SelectedObject, "DeletionMark" );
		picture = ? ( deletionMark, 0, 1 );
	endif; 
	relationRow = Relations.Add ();
	relationRow.Object = SelectedObject;
	relationRow.ObjectPresentation = presentation;
	relationRow.Picture = picture;
	
EndProcedure 

&AtServer
Procedure markDeletion ( SelectedObject, Row )
	
	if ( SelectedObject = undefined ) then
		deletionMark = false;
	else
		deletionMark = DF.Pick ( SelectedObject, "DeletionMark" );
	endif; 
	if ( deletionMark ) then
		return;
	endif; 
	if ( Metadata.InformationRegisters.Contains ( Row.Metadata ) ) then
		r = InformationRegisters [ Row.Metadata.Name ].CreateRecordManager ();
		FillPropertyValues ( r, Row.Data );
		r.Delete ();
	elsif ( Metadata.Documents.Contains ( Row.Metadata ) ) then
		obj = Row.Data.GetObject ();
		if ( obj.Posted ) then
			obj.Write ( DocumentWriteMode.UndoPosting );
		endif; 
		obj.DeletionMark = true;
		obj.Write ();
	else
		obj = Row.Data.GetObject ();
		try
			obj.DeletionMark = true;
		except
			return;
		endtry;
		obj.Write ();
	endif; 
	
EndProcedure 

&AtClient
Procedure enableRelations ()
	
	Items.RelationsPages.CurrentPage = Items.RelationsTable;
	
EndProcedure 

&AtClient
Procedure SetDeletionMark ( Command )
	
	if ( LimitAchieved ) then
		Output.DeletionMarkConfirmation2 ( ThisObject, , new Structure ( "Count", getRelationsTableLimit () ), "deletionMarkConfirmation" );
	else
		Output.DeletionMarkConfirmation1 ( ThisObject, , , "deletionMarkConfirmation" );
	endif; 
	
EndProcedure

&AtClient
Procedure deletionMarkConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		markDeletionRelatedObjects ( TableRow.Object );
	endif; 
	
EndProcedure 

&AtServer
Procedure markDeletionRelatedObjects ( val SelectedObject )
	
	setDeletionMarkForRelatedObjects ( SelectedObject );
	retrieveObjects ();
	fillRelationsTable ( SelectedObject, true );
	
EndProcedure 

&AtServer
Procedure setDeletionMarkForRelatedObjects ( val Object )

	Command = "SetDeletionMark";
	Limit = undefined;
	startProcessRelations ( Object );
	
EndProcedure 

&AtClient
Procedure FillMoreRelations ( Command )
	
	fillRelationsTable ( TableRow.Object, false );
	
EndProcedure

&AtClient
Procedure RelationsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	openObject ( Item );
	
EndProcedure
