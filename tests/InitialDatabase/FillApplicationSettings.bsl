CloseAll ();

OpenMenu ( "Settings / Application" );
form = With ( "Application Settings" );

// **************************
// General
// **************************

Put ( "#Company", "Наша Компания" );
Put ( "#Currency", "MDL" );
Set ( "#Schedule", "Пятидневка" );

// **************************
// Features
// **************************

Click ( "#Packages" );

// **************************
// Customers & Vendors
// **************************

term = "По факту";
Put ( "#Terms", term );
Put ( "#VendorTerms", term );
method = "Bank Transfer";
Put ( "#PaymentMethod", method );
Put ( "#VendorPaymentMethod", method );

// **************************
// Items
// **************************

Put ( "#Unit", "шт" );

// **************************
// Accounting
// **************************

Set ( "#AccountsPresentation", "Show Account Code" );
setValue ( _, "Deposit Liabilities", "5312" );
setValue ( _, "Employees Other Debt", "2264" );
setValue ( _, "Employer Other Debt", "5412" );
setValue ( _, "Expense Report Account", "22611" );
setValue ( _, "Payroll Account", "5311" );

setValue ( _, "LVI Limit", "1000" );
setValue ( _, "LVI Amortization Account", "2141" );
setValue ( _, "LVI Exploitation Account", "2132" );

setValue ( _, "Child Care", "157" );
setValue ( _, "Extended Vacation", "155" );
setValue ( _, "Extra Child Care", "158" );
setValue ( _, "Paternity Vacation", "165" );
setValue ( _, "Regular Sick Leave", "15311" );
setValue ( _, "Sick Days, Social", "15312" );
setValue ( _, "Regular Vacation", "160" );
setValue ( _, "Vacation Without Pay", "159" );
setValue ( _, "Sick Days, Production", "15321" );
setValue ( _, "Sick Days, Production Social", "15322" );
setValue ( _, "Sick Days, Child", "15332" );
setValue ( _, "Sick Days, Only Social", "15342" );

setValue ( _, "Receivables from VAT Account", "2252" );
setValue ( _, "VAT from Advance", "20%" );
setValue ( _, "VAT on Export", "0%" );
setValue ( _, "Expense Report Debt", "5321" );

With ( form );
Click ( "#FormWriteAndClose" );
Click ( "OK", DialogsTitle );

Procedure setValue ( Map, Name, Value )

	param = Map [ Name ];
	
	With ( "Application Settings*" );
	date = Format ( BegOfYear ( CurrentDate () ), "DLF=D" );
	Put ( "#SetupDate", date );
	table = Activate ( "#Settings" );

	GotoRow ( table, "Parameter", param );
	table.Choose ();
	With ( param + ": Setup" );
	Put ( "#Value", Value );
	Put ( "#SetupDate", date );
	Click ( "#FormOK" );

EndProcedure
