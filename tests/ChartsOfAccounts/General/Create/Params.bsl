StandardProcessing = false;

p = new Structure ();
p.Insert ( "Code" );
p.Insert ( "Order", 9999999 );
p.Insert ( "Description" );
p.Insert ( "Type", "Active" );
p.Insert ( "Class", "Other Expenses" );
p.Insert ( "Offbalance", false );
p.Insert ( "Quantitative", false );
p.Insert ( "Currency", false );

return p;