#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure OnCopy ( CopiedObject )
	
	Catalogs.Projects.SetFolder ( ThisObject );
	Completed = false;
	CompletionDate = undefined;
	CKEditorSrv.Copy ( CopiedObject, FolderID );
	
EndProcedure

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( IsFolder ) then
		return;
	endif; 
	if ( not checkPeriods () ) then
		Cancel = true;
		return;
	endif; 
	if ( not checkApprovalDoubles () ) then
		Cancel = true;
		return;
	endif; 
	checkCompletionDate ( CheckedAttributes );
	checkApprovalList ( CheckedAttributes );
	checkTasks ( CheckedAttributes );
	
EndProcedure

Function checkPeriods ()
	
	if ( not Periods.Ok ( DateStart, DateEnd ) ) then
		Output.ProjectPeriodError1 ( , "DateEnd" );
		return false;
	endif;
	if ( not Periods.Ok ( DateStart, CompletionDate ) ) then
		Output.ProjectPeriodError2 ( , "CompletionDate" );
		return false;
	endif;
	return true;
	
EndFunction 

Function checkApprovalDoubles ()
	
	if ( not UseApprovingProcess ) then
		return true;
	endif; 
	doubles = Collections.GetDoubles ( ApprovalList, "User" );
	if ( doubles.Count () > 0 ) then
		for each row in doubles do
			Output.DoublesApprovalList ( , Output.Row ( "ApprovalList", row.LineNumber, "User" ) );
		enddo; 
		return false;
	endif; 
	return true;
	
EndFunction 

Procedure checkCompletionDate ( CheckedAttributes )
	
	if ( Completed ) then
		CheckedAttributes.Add ( "CompletionDate" );
	endif; 
	
EndProcedure 

Procedure checkApprovalList ( CheckedAttributes )
	
	if ( UseApprovingProcess ) then
		CheckedAttributes.Add ( "ApprovalList" );
	endif; 
	
EndProcedure 

Procedure checkTasks ( CheckedAttributes )
	
	if ( ObligatoryTasks ) then
		CheckedAttributes.Add ( "Tasks.Task" );
	endif; 
	
EndProcedure 

Procedure BeforeWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( not checkCurrency () ) then
		Cancel = true;
		return;
	endif;

EndProcedure

Function checkCurrency ()
	
	if ( not Parent.IsEmpty () ) then
		if ( DF.Pick ( Parent, "Currency" ) <> Currency ) then
			Output.ProjectCurrencyMismatch ( , "Currency", Ref );
			return false;
		endif; 
	endif; 
	if ( IsFolder and not IsNew () ) then
		if ( DF.Pick ( Ref, "Currency" ) <> Currency ) then
			selection = Catalogs.Projects.Select ( Ref, Owner );
			if ( selection.Next () ) then
				Output.IllegalFolderCurrency ( , "Currency", Ref );
				return false;
			endif; 
		endif; 
	endif; 
	return true;
	
EndFunction 

Procedure OnWrite ( Cancel )
	
	if ( IsFolder ) then
		return;
	endif; 
	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( not checkApprovingUsers () ) then
		Cancel = true;
		return;
	endif; 
	makeInvoicing ();
	
EndProcedure

Function checkApprovingUsers ()
	
	if ( DeletionMark ) then
		return true;
	endif; 
	if ( not UseApprovingProcess ) then
		return true;
	endif; 
	table = getNotAuthorizedUsers ();
	if ( table.Count () > 0 ) then
		for each row in table do
			Output.UserCannotApprove ( new Structure ( "Customer", Owner ), Output.Row ( "ApprovalList", row.LineNumber, "User" ) );
		enddo; 
		return false;
	endif; 
	return true;
	
EndFunction 

Function getNotAuthorizedUsers ()
	
	s = "
	|select ApprovalList.User as User, ApprovalList.LineNumber as LineNumber
	|from Catalog.Projects.ApprovalList as ApprovalList
	|	left join Catalog.Users.Organizations as Organizations
	|	on Organizations.Ref = ApprovalList.User
	|	and Organizations.Organization = &Customer
	|where ApprovalList.Ref = &Ref
	|and ApprovalList.User.OrganizationAccess = value ( Enum.Access.Allow )
	|and Organizations.Organization is null
	|union
	|select ApprovalList.User, ApprovalList.LineNumber
	|from Catalog.Projects.ApprovalList as ApprovalList
	|	left join Catalog.Users.Organizations as Organizations
	|	on Organizations.Ref = ApprovalList.User
	|	and Organizations.Organization = &Customer
	|where ApprovalList.Ref = &Ref
	|and ApprovalList.User.OrganizationAccess = value ( Enum.Access.Forbid )
	|and Organizations.Organization is not null
	|";
	q = new Query ( s );
	q.SetParameter ( "Customer", Owner );
	q.SetParameter ( "Ref", Ref );
	table = q.Execute ().Unload ();
	return table;
	
EndFunction 

Procedure makeInvoicing ()
	
	SetPrivilegedMode ( true );
	record = InformationRegisters.ProjectInvoices.CreateRecordManager ();
	record.Project = Ref;
	record.Read ();
	if ( not record.Selected () ) then
		record.Project = Ref;
		record.Write ();
	endif; 
	SetPrivilegedMode ( false );
	
EndProcedure 

#endif