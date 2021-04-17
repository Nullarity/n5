Procedure Make ()

	if ( Calculated ) then
		goto ~draw;
	endif;

	str = "
	|// @Fields
	|select Companies.FullDescription as Company, Companies.CodeFiscal as CodeFiscal
	|from Catalog.Companies as Companies
	|where Companies.Ref = &Company
	|;
	|// Hiring
	|select Employees.Individual.LastName + "" "" + Employees.Individual.FirstName as Name, Employees.Individual.PIN as PIN, 
	|	Employees.Individual.SIN as SIN, ""01"" as Status, Employees.DateStart as Date
	|into Hiring
	|from Document.Hiring.Employees as Employees
	|where Employees.Ref.Posted
	|and Employees.DateStart between &DateStart and &DateEnd
	|and Employees.Ref.Company = &Company
	|;
	|// Firing
	|select Employees.Individual.LastName + "" "" + Employees.Individual.FirstName as Name, Employees.Individual.PIN as PIN, 
	|	Employees.Individual.SIN as SIN, ""02"" as Status, Employees.Date as Date, Employees.Reason as Reason
	|into Firing
	|from Document.Termination.Employees as Employees
	|where Employees.Ref.Posted
	|and Employees.Date between &DateStart and &DateEnd
	|and Employees.Ref.Company = &Company
	|;
	|// Vacations
	|select Employees.Individual.LastName + "" "" + Employees.Individual.FirstName as Name, Employees.Individual.PIN as PIN, 
	|	Employees.Individual.SIN as SIN, Employees.DateStart as DateStart, Employees.DateEnd as DateEnd,
	|	case 
	|		when Employees.Compensation.Method = value ( Enum.Calculations.PaternityVacation ) then ""165""
	|		when Employees.Compensation.Method = value ( Enum.Calculations.ChildCare ) then ""157""
	|		when Employees.Compensation.Method = value ( Enum.Calculations.ExtraChildCare ) then ""158""
	|	end as InsuranceCode,
	|	case when Employees.Compensation.Method = value ( Enum.Calculations.ExtraChildCare ) 
	|		then ""03""
	|		else """"
	|	end as Status,
	|	case when Employees.Compensation.Method = value ( Enum.Calculations.ExtraChildCare ) 
	|		then Employees.DateStart
	|		else null
	|	end as Date  
	|into Vacations
	|from Document.Vacation.Employees as Employees 
	|where Employees.Ref.Posted
	|and Employees.DateStart between &DateStart and &DateEnd
	|and Employees.Ref.Company = &Company
	|and Employees.Compensation.Method in ( value ( Enum.Calculations.PaternityVacation ), value ( Enum.Calculations.ChildCare ), value ( Enum.Calculations.ExtraChildCare ) )  
	|;
	|// #Table
	|select Hiring.Name as Name, Hiring.PIN as PIN, Hiring.SIN as SIN, null as InsuranceCode, 
	|	null as DateStart, null as DateEnd, Hiring.Status as Status,
	|	null as Reason, Hiring.Date as Date
	|from Hiring as Hiring
	|union all
	|select Firing.Name, Firing.PIN, Firing.SIN, null, 
	|	null, null, Firing.Status, Firing.Reason, Firing.Date
	|from Firing as Firing
	|union all
	|select Vacations.Name, Vacations.PIN, Vacations.SIN, Vacations.InsuranceCode, 
	|	Vacations.DateStart, Vacations.DateEnd, Vacations.Status, null, Vacations.Date
	|from Vacations as Vacations";
	Env.Selection.Add ( str );	
	getData ();

	// Fields
	envFields = Env.Fields;
	if ( envFields <> undefined ) then 
		for each item in envFields do
		 	FieldsValues [ item.Key ] = item.Value;
		enddo;
	endif;
	
	// Default values
	FieldsValues [ "TaxAdministration" ] = get ( "TaxAdministration", "DefaultValues" );
	FieldsValues [ "CNAS" ] = get ( "CNAS", "DefaultValues" );
	
	// Period
	FieldsValues [ "Period" ] = DateStart;
	
	// *********
	// Table
	// *********
	
	line = 1;
	for each row in Env.Table do
		FieldsValues [ "A" + line ] = line;
		FieldsValues [ "B" + line ] = TrimAll ( Upper ( row.Name ) );
		FieldsValues [ "C" + line ] = row.PIN;
		FieldsValues [ "D" + line ] = row.SIN;
		FieldsValues [ "E" + line ] = row.InsuranceCode;
		FieldsValues [ "F" + line ] = row.DateStart;
		FieldsValues [ "G" + line ] = row.DateEnd;
		FieldsValues [ "H" + line ] = row.Status;
		FieldsValues [ "I" + line ] = row.Reason;
		FieldsValues [ "J" + line ] = row.Date;
		line = line + 1;
	enddo;
	
	~draw:
	
	area = getArea ();
	
	TabDoc.PageOrientation = PageOrientation.Landscape;	
	draw ();

EndProcedure
