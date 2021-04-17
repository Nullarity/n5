Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/Data/Document.MobileReport" );
With ( "ER, Mobile (cr*" );

// Create Individual
name = "_Individual: " + Call ( "Common.GetID" );
p = Call ( "Catalogs.Individuals.Create.Params" );
p.Description = name;
Call ( "Catalogs.Individuals.Create", p );

// Fill header
Set ( "#Company", __.Company );
Set ( "#Employee", name );
Set ( "#Amount", "500" );
Set ( "#Currency", "USD" );
Set ( "#Factor", "1" );
Set ( "#Rate", "1" );
Click ( "#FormWrite" );

// Check Photos
Click ( "Photos", GetLinks () );
