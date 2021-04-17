// Create Customer
// Navigate to the Tasks List
// Create Task

Call ( "Common.Init" );
CloseAll ();

id = Call("Common.GetID");

// Create Customer
Commando("e1cib/command/Catalog.Organizations.Create");
form = With();
Set("#Description", id);
Click("#FormWrite");

// Navigate to the Tasks List
Click("Tasks", GetLinks());
With();
Click("#FormNewTask");
With();
CheckState("#Source", "Visible" );
