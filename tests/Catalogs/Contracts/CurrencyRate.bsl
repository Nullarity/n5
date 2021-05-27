// Create Contract, change currency and check currency fields visibility

Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/command/Catalog.Contracts.Create" );
Click("#Customer");
Click("#Vendor");
CheckState("#CustomerRateType, #CustomerRate, #CustomerFactor, #VendorRateType, #VendorRate, #VendorFactor", "Visible", false);
Put ("#Currency", "USD");
CheckState("#CustomerRateType, #CustomerRate, #CustomerFactor, #VendorRateType, #VendorRate, #VendorFactor", "Visible");