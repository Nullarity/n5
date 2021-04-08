
Function IsReady ( WebWindow ) export
	
	try
		return not ( WebWindow = undefined
			or WebWindow.EditorIsReady = undefined
			or not webWindow.EditorIsReady );
	except
		return false;
	endtry;
	
EndFunction 
	
Function GetWindow ( Item ) export
	
	try
		document = Item.Document;
	except
		return undefined;
	endtry;
	if ( document = undefined ) then
		return undefined;
	endif; 
	return ? ( IsMSIE (), document.parentWindow, document.defaultView );
	
EndFunction 

Procedure CheckModified ( Form, Item ) export
	
	webWindow = CKEditor.GetWindow ( Item );
	if ( CKEditor.IsReady ( webWindow ) ) then
		webWindow.CheckDirty ();
		if ( webWindow.IsDirty ) then
			Form.Modified = true;
		endif;
	endif; 
	
EndProcedure

Procedure SaveHTML ( WriteParameters, Item ) export
	
	webWindow = CKEditor.GetWindow ( Item );
	if ( CKEditor.IsReady ( webWindow ) ) then
		webWindow.GetContent ();
		WriteParameters.Insert ( Item.Name, webWindow.Content );
	else
		WriteParameters.Insert ( Item.Name, undefined );
	endif; 
	
EndProcedure

Procedure ResetDirty ( Item ) export
	
	webWindow = CKEditor.GetWindow ( Item );
	if ( CKEditor.IsReady ( webWindow ) ) then
		webWindow.ResetDirty ();
	endif; 
	
EndProcedure 

Function Action ( Href, ActionID ) export
	
	return StrFind ( Href, ActionID, SearchDirection.FromEnd ) > 0;
	
EndFunction 