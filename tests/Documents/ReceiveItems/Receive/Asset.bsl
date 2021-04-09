StandardProcessing = false;

p = new Structure ();
p.Insert ( "Asset" );
p.Insert ( "Amount" );
p.Insert ( "Department" );
p.Insert ( "Responsible" );
p.Insert ( "Method", "Linear" );
p.Insert ( "UsefulLife", "5" );
p.Insert ( "Charge", true );
p.Insert ( "Starting" ); // Can be empty

return p;
