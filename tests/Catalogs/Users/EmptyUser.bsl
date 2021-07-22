// Create User Group and try to assign rights for empty user

Call("Common.Init");
CloseAll();

Commando("e1cib/command/Catalog.Membership.Create");
Set("#Description", "test " + CurrentDate());
Users = Get("#Users");
Click("#UsersAdd");
Put("#UsersUser", "Accountant", Users);
Click("#UsersAdd");
Click("#UsersAdd");
Rights = Get("#Rights");
search = new Map();
search["Right"] = "General";
Rights.Expand(search);
search = new Map();
search["Right"] = "Save Settings";
search["Use"] = "No";
Rights.GotoRow(search);
Get("#RightsUse").SetCheck();
Click("#FormWrite");
Disconnect();