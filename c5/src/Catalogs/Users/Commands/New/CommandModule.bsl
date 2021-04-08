
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	if ( not Commands.CheckParameter ( CommandParameter, true, false ) ) then
		return;
	endif; 
	if ( TypeOf ( CommandParameter ) = Type ( "CatalogRef.Employees" ) ) then
		if ( userFound ( CommandParameter ) ) then
			Output.UserAlreadyExists ( ThisObject, CommandParameter );
		else
			openNewUserForm ( CommandParameter );
		endif;
	else
		openNewUserForm ( CommandParameter );
	endif; 
	
EndProcedure

&AtClient
Procedure UserAlreadyExists ( Asnwer, Employee ) export
	
	if ( Asnwer = DialogReturnCode.Yes ) then
		openNewUserForm ( Employee )
	endif; 
	
EndProcedure

&AtServer
Function userFound ( Employee )
	
	s = "
	|select allowed top 1 null
	|from Catalog.Users as Users
	|where Users.Employee = &Employee
	|and not Users.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "Employee", Employee );
	return q.Execute ().Select ().Next ();

EndFunction 

&AtClient
Procedure openNewUserForm ( Base )
	
	p = new Structure ( "Basis", Base );
	OpenForm ( "Catalog.Users.ObjectForm", p );
	
EndProcedure 
