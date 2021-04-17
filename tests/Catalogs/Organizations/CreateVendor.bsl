// Description:
// Creates a new Vendor
//
// Returns:
// Structure ( "Code, Description" )

MainWindow.ExecuteCommand("e1cib/data/Catalog.Organizations");

form = With("Organizations (create)");
useParams = (TypeOf(_) = Type("Structure"));
name = ?(_ = undefined, "_Vendor: " + CurrentDate(), ?(useParams, _.Description, _));

Set("Name", name);

if (Fetch("#Vendor") = "No") then
	Click("#Vendor");
endif;
Set("#VATUse", "Included in Price");
Click("#FormWrite");
code = Fetch("#Code");

Run("CreateVendor.CreateContractVendor", ?(useParams, _, undefined));
With("*(Organizations)");
Close();

return new Structure("Code, Description", code, name);

