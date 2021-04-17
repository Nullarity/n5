MainWindow.ExecuteCommand ( "e1cib/list/Document.Entry" );
With ( "Accounting Entries" );
Put ( "#OperationFilter", _.OperationReceipt );
Click ( "#FormChange" );

With ( "Entry*" );
Click ( "#FormReceipt" );
With ( "Receipt: Print" );
Call ( "Common.CheckLogic", "#TabDoc" );