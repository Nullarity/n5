// Create Customer
// Create Command1
// Create Command2 and check if list with previous task appears
// Open Command1 from that list
// Close Command1
// Create Command2 again and press Create Command again in the list of existed commands

Call ( "Common.Init" );
CloseAll ();

id = Call("Common.GetID");

// Create Customer
Commando("e1cib/command/Catalog.Organizations.Create");
form = With();
Set("#Description", id);
Click("#FormWrite");

// Create Command1
Click("#FormBusinessProcessCommandNew");
With();
Set("#Description", "test");
Click("#PerformersAdd");
Choose("#PerformersPerformer");
With();
GotoRow("#TypeTree", "", "Users");
Click("#OK");
Close("Users");
With();
Put("#PerformersPerformer", "admin");
Click("#FormStartAndClose");

// Create Command2
With(form);
Click("#FormBusinessProcessCommandNew");

// List should be open and we click NewTask
With();
Click("#FormNewCommand");
With();

// Source field should be visible
CheckState("#Source", "Visible" );
