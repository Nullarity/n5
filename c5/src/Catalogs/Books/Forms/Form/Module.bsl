// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	readAccess ( Object.Ref );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAccess ( Document )
	
	s = "
	|select Access.UserGroup as UserGroup, Access.Read as Read, Access.Write as Write
	|from InformationRegister.GroupsAccess as Access
	|where Access.Document = &Document
	|order by Access.UserGroup.Description
	|;
	|select allowed Users.Ref as Ref, Users.Description as Name
	|into Users
	|from Catalog.Users as Users
	|index by Ref
	|;
	|select Access.User as User, Access.Read as Read, Access.Write as Write
	|from InformationRegister.UsersAccess as Access
	|	//
	|	// Users
	|	//
	|	left join Users as Users
	|	on Users.Ref = Access.User
	|where Access.Document = &Document
	|order by isnull ( Users.Name, """" )
	|";
	q = new Query ( s );
	q.SetParameter ( "Document", Document );
	data = q.ExecuteBatch ();
	Tables.UsersGroupsRights.Load ( data [ 0 ].Unload () );
	Tables.UsersRights.Load ( data [ 2 ].Unload () );
	
EndProcedure 
	
&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		setSorting ();
		setCreator ();
		if ( not Parameters.CopyingValue.IsEmpty () ) then
			CopiedBook = Parameters.CopyingValue;
			resetCreationDate ();
			copyAccess ();
		endif; 
	endif; 
	setCanChange ();
	setCanChangeAccess ();
	showEffectiveRights ( Object.Parent );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|FormChangeCreator show filled ( Object.Ссылка );
	|Description Parent Sorting Link ManualSorting Dictionary enable CanChange;
	|FormWriteAndClose FormWrite show CanChange;
	|SpecialAccess enable CanChangeAccess;
	|Groups Users enable Object.SpecialAccess and CanChangeAccess
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure setSorting ()
	
	Object.Sorting = Catalogs.Books.GetSorting ();
	
EndProcedure 

&AtServer
Procedure setCreator ()
	
	Object.Creator = SessionParameters.User;
	
EndProcedure 

&AtServer
Procedure resetCreationDate ()
	
	Object.CreationDate = undefined;
	
EndProcedure 

&AtServer
Procedure copyAccess ()
	
	if ( Parameters.CopyingValue.SpecialAccess ) then
		readAccess ( Parameters.CopyingValue );
	endif; 
	
EndProcedure 

&AtServer
Procedure setCanChange ()

	CanChange = Object.Ref.IsEmpty () or Catalogs.Books.CanChange ( Object.Ref );
	
EndProcedure

&AtServer
Procedure setCanChangeAccess ()
	
	CanChangeAccess = Logins.Admin ()
	or ( SessionParameters.User = Object.Creator
		and CanChange );
	
EndProcedure 

&AtServer
Procedure showEffectiveRights ( Folder )
	
	if ( Object.SpecialAccess ) then
		return;
	elsif ( Object.Parent.IsEmpty () ) then
		Tables.UsersGroupsRights.Clear ();
		Tables.UsersRights.Clear ();
	else
		book = InformationRegisters.EffectiveRights.Get ( new Structure ( "Book", Folder ) ).AccessBook;
		readAccess ( book );
	endif; 
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	if ( ThisObject.FormOwner = undefined
		and not Object.Ref.IsEmpty () ) then
		Cancel = true;
		findInList ();
	endif; 
	
EndProcedure

&AtClient
Procedure findInList ()
	
	DocumentsFindBook = Object.Ref;
	OpenForm ( "Document.Document.ListForm" );
	
EndProcedure 

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not checkAccess () ) then
		Cancel = true;
	endif; 
	
EndProcedure

&AtServer
Function checkAccess ()
	
	if ( not Object.SpecialAccess
		or accessExists () ) then
		return true;
	endif;
	Output.BookAccessNotSelected ( , "Groups" );
	return false;

EndFunction 

&AtServer
Function accessExists ()
	
	for each row in Tables.UsersGroupsRights do
		if ( not row.UserGroup.IsEmpty ()
			and row.Read ) then
			return true;
		endif; 
	enddo; 
	for each row in Tables.UsersRights do
		if ( not row.User.IsEmpty ()
			and row.Read ) then
			return true;
		endif; 
	enddo; 
	return false;
	
EndFunction 

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	setCreationDate ( CurrentObject );	
	if ( WriteParameters.Property ( "CopiedBook" ) ) then
		CurrentObject.AdditionalProperties.Insert ( "CopiedBook", WriteParameters.CopiedBook );	
	endif; 	
	
EndProcedure

&AtServer
Procedure setCreationDate ( CurrentObject )
	
	if ( CurrentObject.CreationDate = Date ( 1, 1, 1 ) ) then
		CurrentObject.CreationDate = CurrentSessionDate ();
	endif; 
	
EndProcedure 

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	cleanAccess ( CurrentObject );
	if ( Object.SpecialAccess ) then
		saveAccess ( CurrentObject );
	endif; 

EndProcedure

&AtServer
Procedure cleanAccess ( CurrentObject )
	
	if ( Object.Ref.IsEmpty () ) then
		return;
	endif; 
	SetPrivilegedMode ( true );
	recordset = InformationRegisters.UsersAccessBooks.CreateRecordSet ();
	recordset.Filter.Book.Set ( CurrentObject.Ref );
	recordset.Read ();
	table = recordset.Unload ( , "User" );
	for each row in table do
		r = InformationRegisters.UsersAccessBooks.CreateRecordManager ();
		r.Book = CurrentObject.Ref;
		r.User = row.User;
		r.Delete ();
	enddo; 
	recordset = InformationRegisters.GroupsAccessBooks.CreateRecordSet ();
	recordset.Filter.Book.Set ( CurrentObject.Ref );
	recordset.Read ();
	table = recordset.Unload ( , "UserGroup" );
	for each row in table do
		r = InformationRegisters.GroupsAccessBooks.CreateRecordManager ();
		r.Book = CurrentObject.Ref;
		r.UserGroup = row.UserGroup;
		r.Delete ();
	enddo; 
	SetPrivilegedMode ( false );
	
EndProcedure 

&AtServer
Procedure saveAccess ( CurrentObject )
	
	SetPrivilegedMode ( true );
	book = CurrentObject.Ref;
	recordset = InformationRegisters.GroupsAccessBooks.CreateRecordSet ();
	doubles = new Map ();
	for each row in Tables.UsersGroupsRights do
		if ( row.UserGroup.IsEmpty ()
			or doubles [ row.UserGroup ] <> undefined
			or ( row.Read = false and row.Write = false ) ) then
			continue;
		endif; 
		record = recordset.Add ();
		record.Book = book;
		record.UserGroup = row.UserGroup;
		record.Read = row.Read;
		record.Write = row.Write;
		doubles [ row.UserGroup ] = true;
	enddo; 
	recordset.Write ( false );
	recordset = InformationRegisters.UsersAccessBooks.CreateRecordSet ();
	doubles = new Map ();
	for each row in Tables.UsersRights do
		if ( row.User.IsEmpty ()
			or doubles [ row.User ] <> undefined
			or ( row.Read = false and row.Write = false ) ) then
			continue;
		endif; 
		record = recordset.Add ();
		record.Book = book;
		record.User = row.User;
		record.Read = row.Read;
		record.Write = row.Write;
		doubles [ row.User ] = true;
	enddo; 
	recordset.Write ( false );
	SetPrivilegedMode ( false );
	
EndProcedure 

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure ParentOnChange ( Item )
	
	if ( Object.Parent.IsEmpty () ) then
		enableSpecialAccess ();
	else
		showEffectiveRights ( Object.Parent );
	endif; 
	
EndProcedure

&AtServer
Procedure enableSpecialAccess ()
	
	Object.SpecialAccess = true;
	applySpecialAccess ();
	
EndProcedure 

&AtServer
Procedure applySpecialAccess ()
	
	if ( Object.SpecialAccess ) then
		addMe ();
	endif; 
	showEffectiveRights ( Object.Parent );
	Appearance.Apply ( ThisObject, "Object.SpecialAccess" );

EndProcedure 

&AtServer
Procedure addMe ()
	
	if ( Tables.UsersRights.Count () > 0 ) then
		return;
	endif; 
	row = Tables.UsersRights.Add ();
	row.User = SessionParameters.User;
	row.Read = true;
	row.Write = true;

EndProcedure 

// *****************************************
// *********** Group Access

&AtClient
Procedure SpecialAccessOnChange ( Item )
	
	applySpecialAccess ();
	
EndProcedure

// *****************************************
// *********** Table Groups

&AtClient
Procedure GroupsOnStartEdit ( Item, NewRow, Clone )
	
	if ( not Clone and NewRow ) then
		setReadAccess ( Item );
	endif; 
	
EndProcedure

&AtClient
Procedure setReadAccess ( Item )
	
	Item.CurrentData.Read = true;
	
EndProcedure 

&AtClient
Procedure GroupsOnEditEnd ( Item, NewRow, CancelEdit )
	
	if ( CancelEdit ) then
		return;
	endif; 
	fixRights ( Item );
	
EndProcedure

&AtClient
Procedure fixRights ( Item )
	
	currentData = Item.CurrentData;
	column = Item.CurrentItem.Name;
	if ( Find ( column, "Read" ) > 0
		and currentData.Read = false
		and currentData.Write = true ) then
		currentData.Write = false;
	elsif ( Find ( column, "Write" ) > 0
		and currentData.Read = false
		and currentData.Write = true ) then
		currentData.Read = true;
	endif;
	
EndProcedure 

&AtClient
Procedure GroupsBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	Output.AccessRemovingConfirmation ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure AccessRemovingConfirmation ( Answer, Item ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	if ( Item = Items.Groups ) then
		table = Tables.UsersGroupsRights;
	else
		table = Tables.UsersRights;
	endif; 
	Forms.DeleteSelectedRows ( table, Item );
	
EndProcedure 

// *****************************************
// *********** Table Users

&AtClient
Procedure UsersOnEditEnd ( Item, NewRow, CancelEdit )
	
	if ( CancelEdit ) then
		return;
	endif; 
	fixRights ( Item );
	
EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	if ( not CopiedBook.IsEmpty () ) then
		WriteParameters.Insert ( "CopiedBook", CopiedBook );	
	endif;
	
EndProcedure
