// Create User

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "2B6FD79E" ) );

Commando ( "e1cib/command/Catalog.Users.Create" );

// Fill profile
id = this.ID;
login = "user " + id;
Set ( "#Description", login );
code = Mid ( id, 5, 3 );
Set ( "#Code", code );
Set ( "#Email", code + "@wsxcderfv.xxx" );
Click ( "#MembershipMarkAllGroups" );


// Commit changes twice
Click("#FormWrite");
CheckErrors ();
Pause (1);
Click("#FormWrite");
CheckErrors ();

// Check if employee is filled
Pause (1);
Activate ( "#Group3" ).Expand (); // More
Get ( "#Employee" ).Open ();
With ();
Assert ( Fetch ( "#FirstName" ) ).Equal ( login );
Assert ( Fetch ( "#EmployeeType" ) ).Filled ();
Assert ( Fetch ( "#EmployeeCompany" ) ).Filled ();
Close();

// Change name and check changes in Employees and Individual list
With ();
lastName = "Ivanov";
Set ( "#LastName", lastName );
login = login + " " + lastName;
Click ( "#FormWrite" );
Pause (1);
Commando ( "e1cib/list/Catalog.Employees" );
Assert ( GotoRow ( "#List", "Description", login ) ).IsTrue ();
Close ();
Commando ( "e1cib/list/Catalog.Individuals" );
Assert ( GotoRow ( "#List", "Description", login ) ).IsTrue ();
