﻿StandardProcessing = false;

p = new Structure ();
p.Insert ( "Description" );
p.Insert ( "Currency" );
p.Insert ( "Organization" );
p.Insert ( "Delivery" );
p.Insert ( "CloseAdvances", true );
p.Insert ( "Items", new Array () ); // Array of Core.Catalogs.Organizations.CreateVendor.ContractItem
p.Insert ( "Services", new Array () ); // Array of Core.Catalogs.Organizations.CreateVendor.ContractService
p.Insert ( "ClearTerms", false );
p.Insert ( "Terms" );
return p;
