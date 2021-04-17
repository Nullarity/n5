// Description:
// Set filters in Assets Transfer list form and create a new Assets Inventory.
// Checks the automatic header filling process
//
// Conditions:
// Command interface shoud be visible.

Call ( "Common.Init" );
CloseAll ();
form = Call ( "Common.OpenList", Meta.Documents.AssetsTransfer );

Choose ( "#SenderFilter" );
departmentName = "_Assets Transfer Department";
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

With ( form );

Choose ( "#ResponsibleFilter" );
employeeName = "_Assets Transfer Employee";
params = Call ( "Common.Select.Params" );
params.Object = Meta.Catalogs.Employees;
params.Search = employeeName;
creation = Call ( "Catalogs.Employees.Create.Params" );
creation.Description = employeeName;
params.CreationParams = creation;
Call ( "Common.Select", params );

With ( form );
department = Fetch ( "#SenderFilter" );
employee = Fetch ( "#ResponsibleFilter" );
Click ( "#FormCreate" );

With ( "Assets Transfer (create)" );
Check ( "#Sender", department );
Check ( "#Responsible", employee );
