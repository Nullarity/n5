return;

// Create organization and fill by code fiscal

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2BD8701C" );

Commando ( "e1cib/data/Catalog.Organizations" );
With ( "*cr*)" );

Click ( "#Vendor" );
Set ( "#CodeFiscal", "1012600013024" );
Click ( "#Fill" );

form = FindForm ( "*" );
if ( form <> undefined ) then
	Click ( "Yes", form );
endif;
Pause ( __.Performance * 5 );

Check ( "#Description", "AIS-TEHNOLOGII" );
Check ( "#FullDescription", "AIS-TEHNOLOGII S.R.L." );
Check ( "#VATUse", "1" );
Check ( "#VATCode", "0208453" );
Check ( "#ContactPerson", "Svetlana Valentin Resitco" );
Check ( "#PaymentContact", "Svetlana Valentin Resitco" );
Check ( "#ShippingContact", "Svetlana Valentin Resitco" );
Check ( "#PaymentAddress", "mun. Chişinău, sec. Centru, str. Mitropolit Varlaam, 65, ap. 420" );
Check ( "#ShippingAddress", "mun. Chişinău, sec. Centru, str. Mitropolit Varlaam, 65, ap. 420" );

Set ( "#Description", "Company " + id );
Click ( "#FormWrite" );