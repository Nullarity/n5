Call ( "Common.Init" );
Run ( "Env" );
__.CurrentCustomer = __.MyCompany;

types = Call ( "Catalogs.Projects.TestCreation.GetTypes" );
for each type in types do
	
	name = Call ( "Catalogs.Projects.TestCreation.GetName", type.Value );
	__.CurrentProject = name;
	__.CurrentProjectType = type.Value;
	Run ( "Create" );
	
enddo;
