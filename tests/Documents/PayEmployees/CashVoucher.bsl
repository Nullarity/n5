// - Create a new PayEmployees
// - Set Method = Cash
// - Write document
// - Try to print Cash Voucher

Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/command/Document.PayEmployees.Create" );
With ( "Pay Employees (cr*" );

Set ( "#Method", "Cash" );
Click ( "#FormWrite" );
Click ( "#FormVoucher" );