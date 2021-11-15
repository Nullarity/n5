CloseAll ();

Call ( "Catalogs.Projects.TestList.Open" );
form = With ( "Projects" );
Click ( "Create", form.GetCommandBar () );
form = With ( "Projects (create)" );
__.Form = form;

Run ( "FillHeader" );
Run ( "FillTasks" );
Run ( "Approval" );

With ( form );
//Activate ( "Calculation" );
Click ( "#Completed" );
Click ( "#FormWrite" );
CheckErrors ();
__.Insert ( "Code", Fetch ( "#Code" ) );

Click ( "#FormDocumentTimeEntryCreateBasedOn" );
With ( "Time record (create)*" );