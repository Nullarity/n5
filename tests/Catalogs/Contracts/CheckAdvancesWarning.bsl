// Create contract and check warning about advances visibility.
// Warnings should be visible when:
// Customer is resident
// && Currency isn't local
// && there is no Export
// && Monthly Advances unchecked
// (the same for Vendor)

Call ( "Common.Init" );
CloseAll ();

Commando("e1cib/command/Catalog.Contracts.Create");
CheckState("#CustomerAdvancesWarning", "Visible", false);
CheckState("#VendorAdvancesWarning", "Visible", false);
Click("#Customer");
Click("#Vendor");
Put("#Currency", "USD");
CheckState("#CustomerAdvancesWarning", "Visible");
Click("#CustomerAdvancesMonthly");
Click("#VendorAdvancesMonthly");
CheckState("#CustomerAdvancesWarning", "Visible", false);
CheckState("#VendorAdvancesWarning", "Visible", false);
Click("#CustomerAdvancesMonthly");
CheckState("#CustomerAdvancesWarning", "Visible");
CheckState("#VendorAdvancesWarning", "Visible", false);
Click("#VendorAdvancesMonthly");
CheckState("#VendorAdvancesWarning", "Visible");
Click("#Export");
CheckState("#CustomerAdvancesWarning", "Visible", false);
Click("#Import");
CheckState("#VendorAdvancesWarning", "Visible", false);
