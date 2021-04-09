Call ( "Common.Init" );
types = Call ( "Catalogs.Projects.TestCreation.GetTypes" );
p = Call ( "Common.Find.Params" );
for each type in types do
	CloseAll ();
	Run ( "TestList.Open" );
	form = With ( "Projects" );

	Pick ( "Show", "All" );
	Pick ( "Status", "All" );

	name = Call ( "Catalogs.Projects.TestCreation.GetName", type.Value );
		
	p.Where = "Description";
	p.What = name;
	Call ( "Common.Find", p );

	With ( form );
	Click ( "#FormCopy" );
	CheckErrors ();

	With ( "Projects (create)" );
enddo;