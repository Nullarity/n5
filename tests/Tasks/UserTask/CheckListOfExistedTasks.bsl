// Create Customer
// Create Task1
// Create Task2 and check if list with previous task appears
// Open Task1 from that list
// Close Task1
// Create Task2 again and press Create Task again in the list of existed tasks

Call ( "Common.Init" );
CloseAll ();

id = Call("Common.GetID");

// Create Customer
Commando("e1cib/command/Catalog.Organizations.Create");
form = With();
Set("#Description", id);
Click("#FormWrite");

// Create Task1
Click("#FormTaskUserTaskNew");
With();
Set("#Memo", "test");
Click("#FormOK");

// Create Task2
With(form);
Click("#FormTaskUserTaskNew");

// List should be open and we click NewTask
With();
Click("#FormNewTask");
With();

// Source field should be visible
CheckState("#Source", "Visible" );

Set("#Memo", "test");
Click("#FormOK");
