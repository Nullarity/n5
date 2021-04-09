CloseAll ();

MainWindow.ExecuteCommand ( "e1cib/list/Document.PaymentOrder" );
form = With ( "Payment Orders" );
Click ( "Create", form.GetCommandBar () );
form = With ( "Payment Order (create)*" );
commands = form.GetCommandBar ();
__.Form = form;

Run ( "FillHeader" );
With ( form );
Click ( "#FormWrite", commands );

Click ( "#FormDocumentPaymentOrderPaymentOrder", commands );
With ();
CheckTemplate ( "TabDoc" );