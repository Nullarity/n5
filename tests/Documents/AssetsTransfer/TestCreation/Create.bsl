env = Call ( "Documents.Commissioning.TestCreation.Create", _ );

id = env.ID;

// ***********************************
// Create AssetsTransfer
// ***********************************

Call ( "Common.OpenList", Meta.Documents.AssetsTransfer );
Click ( "#FormCreate" );
form = With ( "Assets Transfer (create)" );

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
	
With ( form );

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
	
With ( form );

Choose ( "#Accepted" );
employeeName = "_Accepted: " + id;
params = Call ( "Common.Select.Params" );
params.Object = Meta.Catalogs.Employees;
params.Search = employeeName;
creation = Call ( "Catalogs.Employees.Create.Params" );
creation.Description = employeeName;
params.CreationParams = creation;
Call ( "Common.Select", params );
	
With ( form );

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
	
With ( form );

Click ( "#FormPost" );

With ( form );
Click ( "#FormPost" );

return env;





