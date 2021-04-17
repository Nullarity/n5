// Create employee and then user. Check if employee automatically pops up

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "2C016526" ) );
id = this.ID;
login = "user " + id;

// Create employee
Commando ( "e1cib/command/Catalog.Employees.Create" );
Set ( "#FirstName", login );
Set ( "#Code", id );
Click ( "#Button0", "1?:*" );
Set ( "#EmployeeCode", id );
Click ( "#FormWrite" );
employeeCode = Fetch ( "#Code" );
Close();

// Create user
Commando ( "e1cib/command/Catalog.Users.Create" );
Set ( "#Description", login );
code = Mid ( id, 5, 3 );
Set ( "#Code", code );
Set ( "#Email", code + "@wsxcderfv.xxx" );
Click ( "#MembershipMarkAllGroups" );
Click("#FormWrite");
Pause (1);
Activate ( "#Group3" ).Expand (); // More
Get ( "#Employee" ).Open ();
With ();
Assert ( Fetch ( "#Code" ), "Created earlier employee should be selected" ).Equal ( employeeCode );
Close ();

// Clear employee and create manually
With ();
Clear ( "#Employee" );
Click ( "#FormWrite" );
Pause (1);
Click ( "#CreateEmployee" );
With ( "Individ*" );
Check ( "#FirstName", login );
Disconnect ();