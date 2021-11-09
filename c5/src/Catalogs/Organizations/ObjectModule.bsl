#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( IsFolder ) then
		return;
	endif; 
	if ( not checkApprovalDoubles () ) then
		Cancel = true;
	endif; 
	if ( not checkEmail () ) then
		Cancel = true;
	endif; 
	if ( not PhoneTemplates.Check ( ThisObject, "Phone, Fax" ) ) then
		Cancel = true;
	endif; 
	checkCustomer ( CheckedAttributes );
	
EndProcedure

Function checkApprovalDoubles ()
	
	doubles = Collections.GetDoubles ( ApprovalList, "User" );
	if ( doubles.Count () > 0 ) then
		for each row in doubles do
			Output.DoublesApprovalList ( , Output.Row ( "ApprovalList", row.LineNumber, "User" ) );
		enddo; 
		return false;
	endif; 
	return true;
	
EndFunction 

Function checkEmail ()
	
	if ( IsBlankString ( Email ) ) then
		return true;
	endif; 
	result = Mailboxes.TestAddress ( Email );
	if ( not result ) then
		Output.InvalidEmail ( , "Email" );
	endif; 
	return result;
	
EndFunction 

Procedure checkCustomer ( CheckedAttributes )
	
	if ( not Customer ) then
		return;
	endif;
	CheckedAttributes.Add ( "CustomerType" );
	if ( CustomerType = Enums.CustomerTypes.Branch ) then
		CheckedAttributes.Add ( "Wholesaler" );
	endif;
	if ( CustomerType = Enums.CustomerTypes.ChainRetailer ) then
		CheckedAttributes.Add ( "Chain" );
	endif; 
	
EndProcedure 

Procedure BeforeWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		recheckEmail ();
		return;
	endif; 
	defaultName ();

EndProcedure

Procedure recheckEmail ()
	
	if ( IsFolder or Email = "" ) then
		return;
	endif; 
	result = Mailboxes.TestAddress ( Email );
	if ( not result ) then
		Email = "";
	endif; 
	
EndProcedure

Procedure defaultName ()
	
	if ( Description = "" ) then
		Description = Output.WorkingDescription ();
	endif; 
	
EndProcedure 

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( not checkApprovingUsers () ) then
		Cancel = true;
	endif; 
	
EndProcedure

Function checkApprovingUsers ()
	
	if ( DeletionMark ) then
		return true;
	endif; 
	table = getNotAuthorizedUsers ();
	if ( table.Count () > 0 ) then
		for each row in table do
			Output.UserCannotApprove ( new Structure ( "Customer", Description ), Output.Row ( "ApprovalList", row.LineNumber, "User" ) );
		enddo; 
		return false;
	endif; 
	return true;
	
EndFunction 

Function getNotAuthorizedUsers ()
	
	s = "
	|select ApprovalList.User as User, ApprovalList.LineNumber as LineNumber
	|from Catalog.Organizations.ApprovalList as ApprovalList
	|	//
	|	// Organizations
	|	//
	|	left join Catalog.Users.Organizations as Organizations
	|	on Organizations.Ref = ApprovalList.User
	|	and Organizations.Organization = &Ref
	|where ApprovalList.Ref = &Ref
	|and ApprovalList.User.OrganizationAccess = value ( Enum.Access.Allow )
	|and Organizations.Organization is null
	|union
	|select ApprovalList.User, ApprovalList.LineNumber
	|from Catalog.Organizations.ApprovalList as ApprovalList
	|	//
	|	// Organizations
	|	//
	|	left join Catalog.Users.Organizations as Organizations
	|	on Organizations.Ref = ApprovalList.User
	|	and Organizations.Organization = &Ref
	|where ApprovalList.Ref = &Ref
	|and ApprovalList.User.OrganizationAccess = value ( Enum.Access.Forbid )
	|and Organizations.Organization is not null
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	table = q.Execute ().Unload ();
	return table;
	
EndFunction 

#endif