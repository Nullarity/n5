Call ( "Common.Init" );
CloseAll ();

warehouseName = "Main";
departmentName = "_Just Department#";

form = Call ( "Common.OpenList", Meta.Documents.Commissioning );

Choose ( "#WarehouseFilter" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Warehouses;
p.Search = "Main";
Call ( "Common.Select", p );

// ***********************************
// Create & Select Department
// ***********************************

params = Call ( "Catalogs.Departments.Create.Params" );
params.Description = departmentName;

p = Call ( "Common.CreateIfNew.Params" );
p.Object = Meta.Catalogs.Departments;
p.Description = params.Description;
p.CreationParams = params;
Call ( "Common.CreateIfNew", p );

Choose ( "#DepartmentFilter" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Departments;
p.Search = departmentName;
Call ( "Common.Select", p );

// ***********************************
// Check
// ***********************************

warehouse = Fetch ( "#WarehouseFilter" );
department = Fetch ( "#DepartmentFilter" );
Click ( "#FormCreate" );

With ( "Commissioning (create)" );
Check ( "#Department", Department );
Check ( "#Warehouse", warehouse );
