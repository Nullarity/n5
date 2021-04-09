// Create a new Customer
// Generate a new Task
// Change progress
// Check if task has 10%
// Set 100% competion
// Check if there is completed task
// Open again and delete
// Check if there is no tasks anymore

Call ( "Common.Init" );
CloseAll ();

id = Call("Common.GetID");
customer = "Customer " + id;

// Create a new Customer
Commando("e1cib/command/Catalog.Organizations.Create");
With();

Click("#Customer");
Set("#Description", customer);
Click("#Write");

// Generate a new Task
Click("#FormTaskUserTaskNew");
With();
Set("#Memo", id);
Put("#Progress", "10%");
Click("#FormOK");

// Change progress
Commando("e1cib/command/Catalog.Organizations.Command.Customers");
With();
GotoRow("#List", "Name", customer);

// Check if task has 10%
list = Get("#List");
//task = Fetch("#GroupTaskStatus", list);
task = Fetch("#Progress", list);
//Progress

if ( Find ( task, "10%" ) = 0 ) then
	Stop ( "Task not found" );
endif;
list.Choose ();
With();

// Set 100% competion
Put("#Progress", "100%");
Click("#FormComplete");
With();
Click("Yes");

// Check if there is completed task
With();
task = Fetch("#Progress", list);
if ( Find ( task, "100%" ) = 0 ) then
	Stop ( "Task not found" );
endif;

// Open again and delete
list.Choose ();
With();
Click("#FormDelete");
With();
Click("Yes");

// Check if there is no tasks anymore
With();
task = Fetch("#Progress", list);
if ( Find ( task, id ) <> 0 ) then
	Stop ( "Task should gone because of its deletion" );
endif;

Disconnect ();
