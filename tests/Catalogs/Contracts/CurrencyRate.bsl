// Create Contract, change currency and check currency fields visibility

Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/command/Catalog.Contracts.Create" );
Click("#Customer");
Click("#Vendor");
CheckState("#CustomerRateType, #CustomerRate, #CustomerFactor, #VendorRateType, #VendorRate, #VendorFactor", "Visible", false);
Put ("#Currency", "USD");
Check ("#CustomerRateType", "Operation Date");
Check ("#VendorRateType", "Operation Date");
Put ("#CustomerRateType", "Fixed");
Put ("#VendorRateType", "Fixed");
CheckState("#CustomerRateType, #CustomerRate, #CustomerFactor, #VendorRateType, #VendorRate, #VendorFactor", "Visible");