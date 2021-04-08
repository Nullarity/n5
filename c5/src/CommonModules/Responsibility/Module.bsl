Function Get ( Date, Company, Roles ) export
	
	SetPrivilegedMode ( true );
	list = Conversion.StringToArray ( Roles );
	table = getTable ( Date, Company, list );
	result = new Structure ();
	for each role in list do
		row = Table.Find ( Enums.Roles [ role ], "Role" );
		result.Insert ( role, ? ( row = undefined, undefined, row.Individual ) );
	enddo; 
	return result;
	
EndFunction 

Function getTable ( Date, Company, Roles )
	
	s = "
	|select Roles.Ref as Ref
	|into Documents
	|from Document.Roles as Roles
	|where not Roles.DeletionMark
	|and Roles.Action = value ( Enum.AssignRoles.Assign )
	|and Roles.Company = &Company
	|and Roles.Date <= &Date
	|and Roles.Role in ( &Roles )
	|;
	|select Roles.User.Employee.Individual as Individual, Roles.Role as Role
	|from Document.Roles as Roles
	|	//
	|	// Last changes
	|	//
	|	join (
	|		select Roles.Role as Role, max ( Roles.Date ) as Date
	|		from Document.Roles as Roles
	|		where Roles.Ref in ( select Ref from Documents )
	|		group by Roles.Role
	|	) as LastChanges
	|	on LastChanges.Role = Roles.Role
	|	and LastChanges.Date = Roles.Date
	|where Roles.Ref in ( select Ref from Documents )
	|";
	q = new Query ( s );
	q.SetParameter ( "Date", Date );
	q.SetParameter ( "Company", Company );
	list = new Array ();
	for each role in Roles do
		list.Add ( Enums.Roles [ role ] );
	enddo; 
	q.SetParameter ( "Roles", list );
	return q.Execute ().Unload ();
	
EndFunction 
