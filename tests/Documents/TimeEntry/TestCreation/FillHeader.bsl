form = __.Form;
myCompany = ( __.CurrentCustomer = __.MyCompany );

With ( form );

Choose ( "Customer" );
Call ( "Select.Organization", __.CurrentCustomer );

With ( form );

Choose ( "Project" );
projects = With ( "Projects" );
Put ( "Show", "All" ); // Show all projects

p = Call ( "Common.Find.Params" );
p.Where = "Description";
p.What = __.CurrentProject;
Call ( "Common.Find", p );

try
	found = GotoRow ( "#List", "Description", __.CurrentProject );
except
	found = false;
endtry;

if ( not found ) then
	p = Call ( "Catalogs.Projects.Create.Params" );
	p.Customer = __.CurrentCustomer;
	p.Description = __.CurrentProject;
	p.ProjectType = __.CurrentProjectType;
	Call ( "Catalogs.Projects.Create", p );
	Click ( "#FormRefresh" );
	GotoRow ( "#List", "Description", __.CurrentProject );
endif;

Click ( "#FormChoose" );

With ( form );

// ***********************************************
// If document is alreadt exists - load last ones
// ***********************************************

exists = Get ( "#LoadExistedTimeEntry" ).CurrentVisible ();
if ( exists ) then
	Click ( "#LoadExistedTimeEntry" );
	table = Get ( "#Tasks" );
	table.SelectAllRows ();
	Click ( "#TasksDelete" );
	Click ( "Yes", DialogsTitle );
endif;

Activate ( "More" );

Set ( "#Reminder", "Never" );
//Click ( "Remind" );
//Click ( "Remind" );