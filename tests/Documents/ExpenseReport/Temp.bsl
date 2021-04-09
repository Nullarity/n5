// CAD Rate = 10
Call ( "Common.Init" );
CloseAll ();

MainWindow.ExecuteCommand ( "e1cib/data/Document.ExpenseReport?ref=bc4f00155d01fa0311e70aeb8d829b8e" );
MainWindow.ExecuteCommand ( "e1cib/data/Document.VendorPayment?ref=bc4f00155d01fa0311e70aeb8d829b8f" );

