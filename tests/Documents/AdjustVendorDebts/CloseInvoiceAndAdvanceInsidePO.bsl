// 1. Create Purchase Order
// 2. Create Vendor Payment
// 3. Create Vendor Invoice without closing advances
// 4. Create Adjust vendor debt for closing advances and invoice manually
// 5. Check movemnts
// There is an important step to restore payment amount in the adjusting debts
// algorithm.

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0Y7" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Create Adjust Vendor Debts
// *************************

Commando ( "e1cib/list/Document.AdjustVendorDebts" );
list = With ();
Put ( "#VendorFilter", env.Vendor );
try
	Click ( "#FormChange" );
	form = With ();
	try
		Click ( "#FormUndoPosting" );
	except
	endtry;	
except
	Click ( "#FormCreate" );
	form = With ();
	Put ( "#Option", "Vendor" );
	Put ( "#Receiver", env.Vendor );
	Click ( "#Reversal" ); // Uncheck reversal flag
	Click ( "#ApplyVAT" ); // Uncheck reversal flag
	Put ( "#Amount", 400 );
endtry;

Click ( "#FormPost" );

Click ( "#FormReportRecordsShow" );
records = With ();
CheckTemplate ( "#TabDoc" );

#region generateReport
p = Call ( "Common.Report.Params" );
p.Path = "e1cib/app/Report.VendorDebtDetails";
p.Title = "Vendor Debt Detail*";
filters = new Array ();

item = Call ( "Common.Report.Filter" );
item.Period = true;
item.Name = "Period";
item.ValueFrom = BegOfYear ( CurrentDate () );
item.ValueTo = EndOfYear ( CurrentDate () );;
filters.Add ( item );

item = Call ( "Common.Report.Filter" );
item.Name = "Vendor";
item.Value = env.Vendor;
filters.Add ( item );

p.Filters = filters;

With ( Call ( "Common.Report", p ) );
Click ( "#GenerateReport" );
Check ( "#Result [ R10C13 ]", 400 ); // For payment / At the end / 400.00

#endregion

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	p.Insert ( "Contract2", "General2" );
	p.Insert ( "Service", "Service " + ID );
	p.Insert ( "Expense", "Expense " + ID );
	p.Insert ( "Department", "Administration " + ID );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Vendor
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = Env.Vendor;
	p.Terms = "Due on receipt";
	p.CloseAdvances = false;
	Call ( "Catalogs.Organizations.CreateVendor", p );
		
	// *************************
	// Create Service
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	
	// *************************
	// Create Expense
	// *************************
	
	Call ( "Catalogs.Expenses.Create", Env.Expense );
	
	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );
	
	// *************************
	// Create PurchaseOrder
	// *************************
	
	Commando ( "e1cib/data/Document.PurchaseOrder" );
	purchaseOrder = With ();
	Put ( "#Vendor", Env.Vendor );
	Put ( "#Memo", id );

	// Services
	table = Get ( "#Services" );
	Click ( "#ServicesAdd" );
	Put ( "#ServicesItem", Env.Service );
	Next ();
	Put ( "#ServicesAmount", "1000", table );
	Put ( "#Department", Env.Department );
	Click ( "#FormPost" );
	
	// *************************
	// Create Vendor Payment
	// *************************
	
	Commando ( "e1cib/command/Document.VendorPayment.Create" );
	With ();
	
	Put ( "#Vendor",  Env.Vendor );
	Pick ( "#Method", "Cash" );
	Put ( "#Amount", 600 );
	Click ( "#FormPostAndClose" );
	
	// *************************
	// Create Invoice
	// *************************
	
	With ( purchaseOrder );
	Click ( "#FormVendorInvoice" );
	With ();
	table = Get ( "#Services" );
	Set ( "#ServicesPrice [ 1 ]", 400, table ); 
	Set ( "#ServicesExpense [ 1 ]", Env.Expense, table ); 
	Set ( "#ServicesAccount [ 1 ]", "8111", table ); 
	Click ( "#FormPostAndClose" );
	
	Close ( purchaseOrder );
	
	RegisterEnvironment ( id );
	
EndProcedure