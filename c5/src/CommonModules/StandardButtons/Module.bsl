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
	set.Add ( "JustSave" );
	panel = ? ( CommandBar = undefined, Form.CommandBar, CommandBar );
	buttonts = getButtons ( panel.ChildItems, set );
	if ( not Env.Save ) then
		hide ( buttonts, "FormWrite" );
		hide ( buttonts, "FormWriteAndClose" );
	elsif ( Env.Post ) then
		hide ( buttonts, "FormWrite" );
		shortcut ( buttonts, "FormPost" );
	else
		shortcut ( buttonts, "FormWrite" );
	endif;
	move ( buttonts, "JustSave" );
	
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
Procedure hide ( Buttonts, Name )
	
	for each item in Buttonts do
		if ( isButton ( item, Name ) ) then
			item.Visible = false;
		endif;
	enddo;
	
EndProcedure

&AtServer
Procedure shortcut ( Buttonts, Name )
	
	for each item in Buttonts do
		if ( isButton ( item, Name, true ) ) then
			item.Shortcut = new Shortcut ( Key.S, , true );
			return;
		endif;
	enddo;
	
EndProcedure

&AtServer
Procedure move ( Buttonts, Name )
	
	for each item in Buttonts do
		if ( isButton ( item, Name ) ) then
			if ( Framework.VersionLess ( "8.3.15" ) ) then
				item.OnlyInAllActions = true;
			else
				// We use Eval to avoid syntax error in versions less than 8.3.15
				item.LocationInCommandBar = Eval ( "ButtonLocationInCommandBar.InAdditionalSubmenu" );
			endif;
		endif;
	enddo;
	
EndProcedure

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
	
	write ( Form, true );
	
EndProcedure 

&AtClient
Procedure write ( Form, Post ) export
	
	owner = Form.FormOwner;
	if ( not save ( Form, Post ) ) then
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
Function save ( Form, Post )
	
	if ( form.ReadOnly ) then
		return true;
	else
		alreadyPosted = false;
		Form.Object.Property ( "Posted", alreadyPosted );
		if ( Post or alreadyPosted ) then
			action = new Structure ( "WriteMode", DocumentWriteMode.Posting );
		else
			action = new Structure ( "JustSave", true );
		endif;
		return form.Write ( action );
	endif;
	
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
	
	write ( Form, false );
	
EndProcedure 

&AtClient
Procedure Create ( Type, Owner = undefined, List = undefined ) export
	
	params = StandardButtonsSrv.GetParams ( Type, ? ( List = undefined, undefined, List.SettingsComposer ) );
	OpenForm ( params.Form, new Structure ( "FillingValues", params.FillingValues ), Owner );
	
EndProcedure 

&AtClient
Procedure SaveDraft ( Form ) export
	
	save ( Form, false );
	
EndProcedure 

&AtClient
Procedure AdjustSaving ( Form, WriteParameters ) export
	
	if ( WriteParameters.Property ( "JustSave" ) ) then
		WriteParameters.WriteMode = DocumentWriteMode.Write;
	elsif ( WriteParameters.WriteMode = DocumentWriteMode.Write ) then
		WriteParameters.WriteMode = DocumentWriteMode.Posting;
	endif;
	
EndProcedure