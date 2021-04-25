Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "2CFEE56B" ) );
id = this.ID;
env = Call ( "Documents.Commissioning.TestCreation.Create", id );

// Create AssetsTransfer
Commando("e1cib/command/Document.AssetsTransfer.Create");
Put ( "#Memo", id );
Choose ( "#Responsible" );
employeeName = env.employee;
params = Call ( "Common.Select.Params" );
params.Object = Meta.Catalogs.Employees;
params.Search = employeeName;
creation = Call ( "Catalogs.Employees.Create.Params" );
creation.Description = employeeName;
params.CreationParams = creation;
Call ( "Common.Select", params );
	
With ();

Choose ( "#Sender" );
departmentName = env.department;
params = Call ( "Common.Select.Params" );
params.Object = Meta.Catalogs.Departments;
params.Search = departmentName;
creation = Call ( "Catalogs.Departments.Create.Params" );
creation.Description = departmentName;
userSettings = Call ( "Catalogs.UserSettings.Get" );
company = userSettings.Company;
creation.Company = company;
params.CreationParams = creation;
params.App = AppName;
Call ( "Common.Select", params );
	
With ();

Choose ( "#Accepted" );
employeeName = "_Accepted: " + id;
params = Call ( "Common.Select.Params" );
params.Object = Meta.Catalogs.Employees;
params.Search = employeeName;
creation = Call ( "Catalogs.Employees.Create.Params" );
creation.Description = employeeName;
params.CreationParams = creation;
Call ( "Common.Select", params );

With ();

Choose ( "#Receiver" );
departmentName = "_Receiver: " + id;
params = Call ( "Common.Select.Params" );
params.Object = Meta.Catalogs.Departments;
params.Search = departmentName;
creation = Call ( "Catalogs.Departments.Create.Params" );
creation.Description = departmentName;
userSettings = Call ( "Catalogs.UserSettings.Get" );
company = userSettings.Company;
creation.Company = company;
params.CreationParams = creation;
Call ( "Common.Select", params );
	
fillStakeholders ( env.Employees );

With ();

table = Activate ( "#ItemsTable" );
Call ( "Table.AddEscape", table );
Set ( "#ItemsItem", env.Items [ 2 ].Item, table );
Next();

// Disable cost & post
Call ( "Catalogs.UserSettings.CostOnline", false );
With();
Click ( "#FormPost" );
error = "* was not found in balance";
Call ( "Common.CheckPostingError", error );

// CostOnline
Call ( "Catalogs.UserSettings.CostOnline", true );

With ();
Set ( "#ItemsTable / #ItemsItem [ 1 ]", env.Items [ 0 ].Item );
Click ( "#FormPost" );

Run ( "Logic" );
With ();
Run ( "PrintForm" );
Run ( "TestMF1" );

Procedure fillStakeholders ( Employees )
	
	Activate ( "Stakeholders" );
	
    approved = Employees [ 0 ];
	head = Employees [ 1 ];

	setValue ( "#Approved", approved.Employee );
	Activate ( "#ApprovedPosition" );
	Check ( "#ApprovedPosition", approved.Position );

	setValue ( "#Head", head.Employee );
	Activate ( "#HeadPosition" );
	Check ( "#HeadPosition", head.Position );
	
	// *********************
	// Fill members
	// *********************
	
	table = Activate ( "#Members" );
	Call ( "Table.Clear", table );
	for i = 2 to 3 do
		member = Employees [ i ];

		Click ( "#MembersAdd" );
		setValue ( "#MembersMember", member.Employee );
		table.EndEditRow ();
		
		Check ( "#MembersPosition", member.Position, table );
	enddo;
	
EndProcedure

Procedure setValue ( Field, Value )

	Choose ( Field );
	With ( "Select data type" );
	GotoRow ( "#TypeTree", "", "Employees" );
	Click ( "#OK" );
	With ( "Employees" );
	GotoRow ( "#List", "Description", Value );
	Click ( "#FormChoose" );
	With ();
	
EndProcedure
