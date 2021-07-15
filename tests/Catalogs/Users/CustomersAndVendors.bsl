// Open User rights and assign Customers and Vendors rights

Call("Common.Init");
CloseAll();

Commando("e1cib/list/Catalog.Users");
List = Get("#List");
search = new Map();
search["Name"] = "admin";
List.GotoRow(search);
List.Choose();

With();
Activate("#Group7"); // Rights
UserGroups = Get("#Membership");
Click("#RightsEditRights");

With();
Rights = Get("#Rights");
search = new Map();
search["Right"] = "Customers";
search["Use"] = "No";
Rights.GotoRow(search);
Get("#RightsUse").SetCheck();
Click("#RightsApplyRights");

Click("#RightsUnmarkAllRights");
search = new Map();
search["Right"] = "Purchases";
search["Use"] = "No";
Rights.GotoRow(search);
Get("#RightsUse").SetCheck();
Click("#RightsApplyRights");

