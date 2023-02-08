Function GetByIndividual ( Individual, Company = undefined ) export
	
	s = "
	|select top 1 List.Ref as Employee
	|from Catalog.Employees as List
	|	//
	|	// Employees
	|	//
	|	left join InformationRegister.Employees.SliceLast ( , Employee.Individual = &Individual";
	if ( Company <> undefined ) then
		s = s + " and Employee.Company = &Company";
	endif;
	s = s + "
	|) as Employees
	|	on Employees.Employee = List.Ref
	|	and Employees.Hired
	|	//
	|	// Employment
	|	//
	|	left join InformationRegister.Employment.SliceLast ( , Employee.Individual = &Individual ) as CurrentEmployment
	|	on CurrentEmployment.Employee = List.Ref
	|where List.Individual = &Individual
	|order by
	|	case when isnull ( Employees.Hired, false ) then 0 else 1 end desc,
	|	case CurrentEmployment.Employment
	|		when value ( Enum.Employment.Main ) then 0
	|		when value ( Enum.Employment.SecondJob ) then 1
	|		when value ( Enum.Employment.PartTime ) then 2
	|	end desc
	|";
	q = new Query ( s );
	q.SetParameter ( "Individual", Individual );
	q.SetParameter ( "Company", Company );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Employee );
	
EndFunction 
