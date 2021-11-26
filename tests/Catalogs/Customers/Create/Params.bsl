StandardProcessing = false;
p = new Structure ();
p.Insert ( "Name" );
p.Insert ( "PaymentAddress" ); // String means arbitrary address
p.Insert ( "BankAccount" );
p.Insert ( "Government", false );
return p;