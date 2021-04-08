Procedure SetPosition ( Employee, Position, Date ) export
	
	if ( TypeOf ( Employee ) = Type ( "CatalogRef.Employees" )
		and not Employee.IsEmpty () ) then
		Position = MembersFormSrv.GetPosition ( Employee, Date );
	endif; 

EndProcedure 

Procedure FillPosition ( TableRow, Date ) export
	
	MembersForm.SetPosition ( TableRow.Member, TableRow.Position, Date );
	
EndProcedure 
