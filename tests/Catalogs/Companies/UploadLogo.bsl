﻿// Create a new Company
// Upload log and save

Call("Common.Init");
CloseAll();

// Create a new Company
Commando("e1cib/command/Catalog.Companies.Create");
id = call("Common.GetID");
Set("#Description", "Company " + id);

CheckState("#Photo", "Visible", false);

// Upload log and save
App.SetFileDialogResult(true, __.Files + "logo.png");
Click("#Upload");
Click("#Write");
CheckState("#Photo", "Visible");

