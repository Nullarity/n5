StandardProcessing = false;

p = new Structure ();
p.Insert ( "Item" );
p.Insert ( "Amount" );
p.Insert ( "Department" );
p.Insert ( "Employee" );
p.Insert ( "Method", "Linear" );
p.Insert ( "Rate", "5" );
p.Insert ( "UsefulLife", "5" );
p.Insert ( "Charge", true );
p.Insert ( "Starting" ); // Can be empty
p.Insert ( "Expenses" );
p.Insert ( "Shedule" );
p.Insert ( "LiquidationValue", 0 );

return p;
