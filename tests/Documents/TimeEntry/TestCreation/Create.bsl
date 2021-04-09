CloseAll ();

// Create User
p = Call ( "Catalogs.Employees.Create.Params" );
id = Call ( "Common.GetID" );
performer = id;
p.Description = performer;
p.CreateUser = true;
Call ( "Catalogs.Employees.Create", p );


//MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Users" );
//userForm = With ();

//id = Call ( "Common.ScenarioID", "2872088D" );
//performer = "Login " + id;
//Put ( "#Description", performer );
//Put ( "#FirstName", performer );
//Put ( "#Code", Right ( id, 3 ) );
//Put ( "#Email", "email@email.com" );
//Click ( "#FormWriteAndClose" );
//count = 0;
//while ( FindMessages ( "*unique" ).Count () > 0 ) do
//	With ( userForm );
//	if ( count > 50 ) then
//		Stop ( "Could not set unique user code" );
//		break;
//	endif;
//	id = Call ( "Common.GetID" ); 
//	Put ( "#Code", Right ( id, 3 ) );
//	Click ( "#FormWriteAndClose" );
//	count = count + 1;
//enddo;


MainWindow.ExecuteCommand ( "e1cib/list/Document.TimeEntry" );
form = With ( "Time entries" );
Click ( "Create", form.GetCommandBar () );
form = With ( "Time record (create)*" );
Put ( "#Performer", performer );
commands = form.GetCommandBar ();
__.Form = form;



Run ( "FillHeader" );
Run ( "FillTasks" );

With ( form );
Click ( "Post", commands );

CheckErrors ();
