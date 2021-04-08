#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	checkFolder ( CheckedAttributes );
	
EndProcedure

Procedure checkFolder ( CheckedAttributes )
	
	if ( not System and ( LabelType <> Enums.LabelTypes.IMAP ) ) then
		CheckedAttributes.Add ( "Parent" );
	endif; 
	
EndProcedure 

Procedure BeforeWrite ( Cancel )
	
	if ( DeletionMark ) then
		if ( not deletionAllowed () ) then
			Cancel = true;
			return;
		endif; 
	endif; 
	if ( not folderIsCorrect () ) then
		Cancel = true;
		return;
	endif; 
	if ( not checkTrash () ) then
		Cancel = true;
		return;
	endif; 
	
EndProcedure

Function deletionAllowed ()
	
	if ( System ) then
		mailboxMark = DF.Pick ( Owner, "DeletionMark" );
		if ( not mailboxMark ) then
			Output.MailLabelDeletionError ();
			return false;
		endif; 
	endif; 
	return true;
	
EndFunction 

Function folderIsCorrect ()
	
	if ( not Parent.IsEmpty () ) then
		parentLabelType = DF.Pick ( Parent, "LabelType" );
		if ( parentLabelType <> LabelType ) then
			p = new Structure ( "ParentType, LabelType", parentLabelType, LabelType );
			Output.LabelIsIncorrect ( p, "Parent", Ref );
			return false;
		endif; 
	endif; 
	return true;
	
EndFunction 

Function checkTrash ()
	
	parentLabelType = DF.Pick ( Parent, "LabelType" );
	if ( parentLabelType = Enums.LabelTypes.Trash ) then
		Output.TrashFolderError ();
		return false;
	endif; 
	return true;
	
EndFunction 

#endif