 
&AtClient
Procedure ClearTables ( TablesArray, ProcName, Module, CallbackParams = undefined, ExtMethod = false ) export

	isArray = ( TypeOf ( TablesArray ) = Type ( "Array" ) );
	tablesPresent = "";
	if ( isArray ) then
		remove = false;
		for each tableItem in TablesArray do
			tablesPresent = tablesPresent + Chars.LF + "- " + tableItem.Presentation;
			remove = remove or ( tableItem.Table.Count () > 0 )
		enddo; 
		tablesPresent = Mid ( tablesPresent, 2 );
	else
		remove = ( TablesArray.Count () > 0 );
	endif; 
	if ( remove ) then
		p = new Structure ( "Tables", tablesPresent );
		initiator = new Structure ( "ProcName, Module, CallbackParams", ProcName, Module, CallbackParams );
		processingParams = new Structure ( "Initiator, IsArray, TablesArray", initiator, isArray, TablesArray );
		if ( isArray ) then
			if ( ExtMethod ) then
				Output.ClearTablesYesNoCancel ( ThisObject, processingParams, p, "clearTablesAnswerProcessing" );
			else
				Output.ClearTablesYesNo ( ThisObject, processingParams, p, "clearTablesAnswerProcessing" );
			endif; 
		else
			if ( ExtMethod ) then
				Output.ClearTableYesNoCancel ( ThisObject, processingParams, p, "clearTablesAnswerProcessing" );
			else
				Output.ClearTableYesNo ( ThisObject, processingParams, p, "clearTablesAnswerProcessing" );
			endif; 
		endif; 
	else
		handler = new NotifyDescription ( ProcName, Module, CallbackParams );
		ExecuteNotifyProcessing ( handler, true );
	endif;

EndProcedure

&AtClient
Procedure clearTablesAnswerProcessing ( Answer, Params ) export
	
	handler = new NotifyDescription ( Params.Initiator.ProcName, Params.Initiator.Module, Params.Initiator.CallbackParams );
	if ( Answer = DialogReturnCode.No ) then
		ExecuteNotifyProcessing ( handler, true );
	elsif ( Answer = DialogReturnCode.Cancel ) then	
		ExecuteNotifyProcessing ( handler, false );
	else
		if ( Params.IsArray ) then
			for each tableItem in Params.TablesArray do
				tableItem.Table.Clear ();
			enddo; 
		else
			Params.TablesArray.Clear ();
		endif; 
		ExecuteNotifyProcessing ( handler, true );
	endif;
	
EndProcedure 

Procedure MarkRows ( DataCollection, Check ) export
	
	for each dataitem in DataCollection do
		dataitem.Use = Check;
	enddo; 
	
EndProcedure
 
&AtClient
Procedure MoveRow ( Form, DataCollectionName, Direction ) export
	
	currentIndex = Form [ DataCollectionName ].IndexOf ( Form.Items [ DataCollectionName ].CurrentData );
	if ( currentIndex = -1 ) then
		return;
	endif; 
	if ( Direction = 1 ) then // Down
		maxIndex = Form [ DataCollectionName ].Count () - 1;
		if ( currentIndex = maxIndex ) then
			return;
		endif; 
	elsif ( currentIndex = 0 ) then // Up
		return;
	endif; 
	Form [ DataCollectionName ].Move ( currentIndex, Direction );
	
EndProcedure

&AtServer
Procedure ActivateFirstRow ( Table, Item ) export
	
	if ( Table.Count () > 0 ) then
		Item.CurrentRow = Table [ 0 ].GetID ();
	endif; 
	
EndProcedure

&AtServer
Procedure ActivatePage ( Form, Tables ) export
	
	items = Form.Items;
	for each name in StrSplit ( Tables, "," ) do
		table = items [ name ];
		value = Forms.ItemValue ( Form, table );
		if ( value.Count () > 0 ) then
			page = FormsSrv.FindPage ( table.Parent );
			pages = page.Parent;
			pages.CurrentPage = page;
			return;
		endif; 
	enddo; 
	
EndProcedure

&AtServer
Procedure ActivateEmpty ( Form, Controls ) export
	
	object = Form.Object;
	items = Form.Items;
	for each item in Conversion.StringToArray ( Controls ) do
		if ( not ValueIsFilled ( object [ item ] ) ) then
			Form.CurrentItem = items [ item ];
			break;
		endif;
	enddo;
	
EndProcedure

&AtClient
Procedure DeleteLastRow ( Table, TestColumn ) export
	
	lastIndex = Table.Count () - 1;
	if ( lastIndex = -1 ) then
		return;
	endif; 
	if ( not ValueIsFilled ( Table [ lastIndex ] [ TestColumn ] ) ) then
		Table.Delete ( lastIndex );
	endif; 
	
EndProcedure

&AtServer
Procedure ResetWindowSettings ( Form ) export
	
	Form.WindowOptionsKey = new UUID ();
	settingsArray = new Array ();
	searchStruct = new Structure ( "User", UserName () );
	selection = SystemSettingsStorage.Select ( searchStruct );
	while ( selection.Next () ) do
		if ( Find ( selection.ObjectKey, Form.FormName + "/" ) = 1 ) then
			settingsArray.Add ( selection.ObjectKey );
		endif; 
	enddo; 
	for each setting in settingsArray do
		SystemSettingsStorage.Delete ( setting, undefined, searchStruct.User );
	enddo; 
	
EndProcedure 

&AtClient
Procedure DeleteSelectedRows ( Table, Item ) export
	
	list = new ValueList ();
	for each row in Item.SelectedRows do
		list.Add ( table.IndexOf ( Item.RowData ( row ) ) );
	enddo; 
	list.SortByValue ( SortDirection.Desc );
	for each row in list do
		table.Delete ( row.Value );
	enddo; 
	
EndProcedure 

&AtServer
Function RealtimePosting ( Object ) export
	
	return Object.IsNew () and ( BegOfDay ( Object.Date ) = BegOfDay ( CurrentDate () ) );
	
EndFunction 

&AtClient
Function NewRow ( Form, Table, Clone ) export
	
	Form.Modified = true;
	object = Form.Object;
	row = object [ Table.Name ].Add ();
	if ( Clone ) then
		FillPropertyValues ( row, Table.CurrentData );
	endif; 
	Table.CurrentRow = row.GetID ();
	return row;
	
EndFunction 

Function Check ( Form, Items ) export
	
	errors = getErrors ( Form.Object, Items );
	if ( errors.Count () = 0 ) then
		return true;
	else
		showObjectErrors ( Form, errors );
		return false;
	endif; 
	
EndFunction

Function getErrors ( Object, Items )
	
	errors = new Array ();
	list = ? ( TypeOf ( Items ) = Type ( "String" ), Conversion.StringToArray ( Items ), Items );
	for each item in list do
		if ( ValueIsFilled ( Object [ item ] ) ) then
			continue;
		endif; 
		errors.Add ( item );
	enddo; 
	return errors;
	
EndFunction 

Procedure showObjectErrors ( Form, Errors )
	
	titles = FormsSrv.ItemTitles ( Form.FormName, Errors );
	j = Errors.UBound ();
	for i = 0 to j do
		name = Errors [ i ];
		title = titles [ i ];
		Output.FieldIsEmpty ( new Structure ( "Field", title ), name );
	enddo; 
	
EndProcedure 

&AtClient
Function CheckFields ( Form, Items ) export
	
	errors = getErrors ( Form, Items );
	if ( errors.Count () = 0 ) then
		return true;
	else
		showFormErrors ( Form, errors );
		return false;
	endif; 
	
EndFunction

&AtClient
Procedure showFormErrors ( Form, Errors )
	
	for each field in Errors do
		Output.FieldIsEmpty ( , field, , "" );
	enddo; 
	
EndProcedure 

&AtClient
Procedure Drag ( Form, Source, Destination, Tree, TreeObject ) export
	
	if ( recoursion ( Source, Destination, Tree ) ) then
		return;
	endif; 
	Collections.Sort ( Source );
	moveRows ( Source, Destination, TreeObject );
	removeDragged ( Source, Tree, TreeObject );
	if ( Destination <> undefined ) then
		Tree.CurrentRow = Destination;
		Tree.Expand ( Destination, true );
	endif; 
	Form.Modified = true;
	
EndProcedure 

&AtClient
Function recoursion ( Source, Destination, Tree )

	if ( Destination = undefined ) then
		return false;
	endif; 
	target = Tree.RowData ( Destination );
	while ( true ) do
		parent = target.GetParent ();
		if ( parent = undefined ) then
			break;
		endif;
		for each id in Source do
			item = Tree.RowData ( id );
			if ( parent = item ) then
				Output.NodesRecoursion ();
				return true;
			endif; 
		enddo;
		target = parent;
	enddo; 
	return false;
	
EndFunction 

&AtClient
Procedure moveRows ( Source, Destination, Tree )
	
	target = ? ( Destination = undefined, Tree.GetItems (), Tree.FindByID ( Destination ).GetItems () );
	transfers = new Map ();
	for each id in Source do
		if ( transfers [ id ] = undefined ) then
			item = Tree.FindByID ( id );
			dragRow ( item, target, transfers );
		endif; 
	enddo; 
	
EndProcedure 

&AtClient
Procedure dragRow ( Source, Destination, Transfers )
	
	if ( TypeOf ( Destination ) = Type ( "FormTable" ) ) then
		row = Destination.AddRow ();
	else
		row = Destination.Add ();
	endif; 
	FillPropertyValues ( row, Source );
	Transfers [ Source.GetID () ] = true;
	for each child in Source.GetItems () do
		dragRow ( child, row.GetItems (), Transfers )
	enddo; 
	
EndProcedure 

&AtClient
Procedure removeDragged ( Source, Tree, TreeObject )
	
	i = Source.Count ();
	while ( i > 0 ) do
		i = i - 1;
		id = Source [ i ];
		parent = Tree.RowData ( id ).GetParent ();
		rows = ? ( parent = undefined, TreeObject, parent );
		rows.GetItems ().Delete ( Tree.RowData ( id ) );
	enddo; 
	
EndProcedure 

&AtClient
Function WebWindow ( Control ) export
	
	document = Control.Document;
	if ( document = undefined ) then
		return undefined;
	else
		if ( IsMSIE () ) then
			return Control.Document.parentWindow;
		else
			return Control.Document.defaultView;
		endif;
	endif; 

EndFunction 

&AtServer
Function ItemValue ( Form, Item ) export
	
	value = Form;
	for each part in StrSplit ( Item.DataPath, "." ) do
		value = value [ part ];
	enddo; 
	return value;
	
EndFunction 

&AtServer
Function InsideMobileHomePage ( Form ) export
	
	// We will prevent opening desktop's forms inside HomePage on mobile device.
	// Mobile device will show quick actions instead.
	// This function should be called from OnCreateAtServer () event handler.
	// Only Home Page forms should exploit this trick.
	embedded = Form.Parameters.Property ( "Filter" )
	and TypeOf ( Form.Parameters.Filter ) = Type ( "Structure" )
	and Form.Parameters.Filter.Count () > 0;
	userAction = Form.Parameters.Property ( "UserAction" );
	return not embedded and not userAction and Environment.MobileClient ();
	
EndFunction

// Executed from complied functions
&AtServer
Function EvalAppearance ( Expression ) export
	
	return Eval ( Expression );
	
EndFunction
