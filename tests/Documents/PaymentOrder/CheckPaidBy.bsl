// Create a new Payment Order, click Paid checkbox and check fields

Call ( "Common.Init" );
CloseAll ();

Commando("e1cib/command/Document.PaymentOrder.Create");
CheckState ("#PaidBy", "Visible", false);
CheckState ("#Number", "ReadOnly", false);
Click("#Paid");
CheckState ("#PaidBy", "Visible");
CheckState ("#Number", "ReadOnly");