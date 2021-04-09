MainWindow.ExecuteCommand ( "e1cib/list/Document.Entry" );
With ( "Accounting Entries" );
Put ( "#OperationFilter", _.OperationExpense );
Click ( "#FormChange" );

With ( "Entry*" );
Click ( "#FormVoucher" );
With ( "Voucher: Print" );
Call ( "Common.CheckLogic", "#TabDoc" );