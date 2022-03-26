&AtServer
Procedure Arrange ( Form, CommandBar = undefined ) export

	if ( choiceMode ( Form ) ) then
		return;
	endif; 
	env = formEnvironment ( Form );
	adjustCommands ( Form, CommandBar, env );
	extendCommands ( Form, env );
	
EndProcedure 

&AtServer
Function choiceMode ( Form )
	
	return Form.Parameters.ChoiceMode;
	
EndFunction 

&AtServer
Function formEnvironment ( Form )
	
	p = new Structure ();
	p.Insert ( "Save", canBeChanged ( Form ) );
	p.Insert ( "Post", canBePosted ( Form ) );
	return p;

EndFunction

&AtServer
Function canBeChanged ( Form )
	
	return AccessRight ( "Edit", Metadata.FindByType ( TypeOf ( Form.Object.Ref ) ) );
	
EndFunction 

&AtServer
Function canBePosted ( Form )
	
	document = Metadata.FindByType( TypeOf ( Form.Object.Ref ) );
	return document <> undefined
	and Metadata.Documents.Contains ( document )
	and document.Posting = Metadata.ObjectProperties.Posting.Allow
	and AccessRight ( "Posting", document );
	
EndFunction 

&AtServer
Procedure adjustCommands ( Form, CommandBar, Env )
	
	set = new Array ();
	set.Add ( "FormWrite" );
	set.Add ( "FormWriteAndClose" );
	set.Add ( "FormPost" );
	set.Add ( "FormPostAndClose" );
	set.Add ( "JustSave" );
	panel = ? ( CommandBar = undefined, Form.CommandBar, CommandBar );
	Buttons = getButtons ( panel.ChildItems, set );
	if ( not Env.Save ) then
		hide ( Buttons, "FormWrite" );
		hide ( Buttons, "FormWriteAndClose" );
	elsif ( Env.Post ) then
		hide ( Buttons, "FormWrite" );
		shortcut ( Buttons, "FormPost" );
		adjustPostAndClose ( Form, panel, Buttons );
	else
		shortcut ( Buttons, "FormWrite" );
	endif;
	
EndProcedure

&AtServer
Function getButtons ( Items, Set, Result = undefined )
	
	if ( Result = undefined ) then
		Result = new Array ();
	endif;
	group = Type ( "FormGroup" );
	button = Type ( "FormButton" );
	for each item in Items do
		type = TypeOf ( item );
		if ( type = group ) then
			getButtons ( item.ChildItems, Set, Result );
		elsif ( type = button
			and item.CommandName = "" ) then
			for each candidate in Set do
				if ( isButton ( item, candidate ) ) then
					Result.Add ( item );
				endif;
			enddo;
		endif;
	enddo;
	return Result;
	
EndFunction

&AtServer
Function isButton ( Button, Name, Original = false )
	
	buttonName = Button.Name;
	if ( Original ) then
		return buttonName = Name;
	else
		if ( not StrStartsWith ( buttonName, Name ) ) then
			return false;
		endif;
		suffix = Mid ( buttonName, StrLen ( Name ) + 1, 1 );
		return suffix = "" or StrFind ( "1234567890", suffix ) > 0;
	endif;
	
EndFunction

&AtServer
Procedure hide ( Buttons, Name )
	
	for each item in Buttons do
		if ( isButton ( item, Name ) ) then
			item.Visible = false;
		endif;
	enddo;
	
EndProcedure

&AtServer
Procedure shortcut ( Buttons, Name )
	
	for each item in Buttons do
		if ( isButton ( item, Name, true ) ) then
			item.Shortcut = new Shortcut ( Key.S, , true );
			return;
		endif;
	enddo;
	
EndProcedure

&AtServer
Procedure adjustPostAndClose ( Form, CommandBar, Buttons )
	
	standard = findButton ( Buttons, "FormPostAndClose1" );
	standardWasReplaced = standard <> undefined;
	if ( standardWasReplaced ) then
		standard.Visible = false;
		custom = findButton ( Buttons, "FormPostAndClose" );
		custom.Enabled = not Form.ReadOnly;
		Form.Items.Move ( custom, CommandBar, CommandBar );
	endif;
	
EndProcedure

&AtServer
Function findButton ( Buttons, Name )
	
	for each item in Buttons do
		if ( isButton ( item, Name, true ) ) then
			return item;
		endif;
	enddo;
	return undefined;

EndFunction

&AtServer
Procedure extendCommands ( Form, Env )
	
	if ( Env.Save and Env.Post ) then
		buttons = 3;
	elsif ( Env.Save ) then
		buttons = 2;
	elsif ( Env.Post ) then
		buttons = 1;
	else
		buttons = 0;
	endif; 
	Form.Parameters.FunctionalOptionsParameters.Insert ( "Button", buttons );
	
EndProcedure

&AtClient
Procedure PostAndNew ( Form ) export
	
	write ( Form, true, Enum.DocumentActionsPostAndNew () );
	
EndProcedure 

&AtClient
Procedure write ( Form, Post, Action ) export
	
	owner = Form.FormOwner;
	if ( not save ( Form, Post, Action ) ) then
		return;
	endif; 
	ref = Form.Object.Ref;
	Form.Close ();
	list = findParent ( owner );
	if ( list = undefined ) then
		StandardButtons.Create ( TypeOf ( ref ), undefined, undefined );
	elsif ( list.Parameters.Property ( "CustomStandardButtonsHandler" ) ) then
		notifyParent ( ref, list );
	else
		StandardButtons.Create ( TypeOf ( ref ), owner, list [ owner.Name ] );
	endif; 
	
EndProcedure 

&AtClient
Function save ( Form, Post, UserAction )
	
	if ( form.ReadOnly ) then
		return true;
	endif;
	params = new Structure ();
	if ( UserAction <> undefined ) then
		params.Insert ( Enum.AdditionalPropertiesUserAction (), UserAction );
	endif;
	alreadyPosted = false;
	Form.Object.Property ( "Posted", alreadyPosted );
	if ( Post or alreadyPosted ) then
		params.Insert ( "WriteMode", DocumentWriteMode.Posting );
	else
		params.Insert ( Enum.WriteParametersJustSave (), true );
	endif;
	return form.Write ( params );
	
EndFunction 

&AtClient
Function findParent ( Control )
	
	if ( Control = undefined ) then
		return undefined;
	else
		type = TypeOf ( Control );
		if ( type = Type ( Enum.FrameworkManagedForm () ) ) then
			return Control;
		// Specifying certain control type, because WebClient can provide FormTemplate by some reason	
		elsif ( type = Type ( "FormTable" ) ) then
			return findParent ( Control.Parent );
		endif; 
	endif; 
	
EndFunction 

&AtClient
Procedure notifyParent ( Reference, Parent )
	
	newObject = TypeOf ( Reference );
	Notify ( Enum.DocumentActionsPostAndNew (), newObject, Parent );

EndProcedure 

&AtClient
Procedure SaveAndNew ( Form ) export
	
	write ( Form, false, Enum.DocumentActionsSaveAndNew () );
	
EndProcedure 

&AtClient
Procedure Create ( Type, Owner = undefined, List = undefined ) export
	
	params = StandardButtonsSrv.GetParams ( Type, ? ( List = undefined, undefined, List.SettingsComposer ) );
	OpenForm ( params.Form, new Structure ( "FillingValues", params.FillingValues ), Owner );
	
EndProcedure 

&AtClient
Procedure SaveDraft ( Form ) export
	
	save ( Form, false, undefined );
	
EndProcedure 

&AtClient
Procedure AdjustSaving ( Form, WriteParameters ) export
	
	if ( WriteParameters.Property ( Enum.WriteParametersJustSave () ) ) then
		WriteParameters.WriteMode = DocumentWriteMode.Write;
	elsif ( WriteParameters.WriteMode = DocumentWriteMode.Write ) then
		WriteParameters.WriteMode = DocumentWriteMode.Posting;
	endif;
	
EndProcedure

&AtClient
Procedure PostAndClose ( Form ) export
	
	if ( not save ( Form, true, Enum.DocumentActionsPostAndClose () ) ) then
		return;
	endif; 
	Form.Close ();
	
EndProcedure 
