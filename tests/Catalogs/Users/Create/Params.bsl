﻿StandardProcessing = false;
p = new Structure ( "Name, Code, Language, Rights, Department, Warehouse, Organizations" );
p.Code = Right ( Call ( "Common.ScenarioID" ), 3 );
p.Language = "English";
p.Department = "Administration";
p.Warehouse = "Main";
p.Organizations = new Array ();
// Elements of strings such as:
// "Customers / Invoices, Edit"
// or "Customers / Invoices, Edit; Tools / Calendar"
p.Rights = new Array ();
return p;
