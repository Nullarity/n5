Call ( "Common.Init" );
CloseAll ();

Call ( "Common.OpenList", Meta.Catalogs.Users );
Click ( "#FormCreate" );

With ( "Users (crea*" );
Activate ( "Location" );

Check ( "#TrackLocation", "Never" );
CheckState ( "#TrackingPeriodicity, #TrackingTime, #TrackingDistance, #TrackingProvider", "Visible", false );

Set ( "#TrackLocation", "Periodically" );
Check ( "#TrackingPeriodicity", "30 Min" );
CheckState ( "#TrackingPeriodicity, #TrackingProvider", "Visible" );
CheckState ( "#TrackingTime, #TrackingDistance", "Visible", false );

Set ( "#TrackLocation", "Always" );
Check ( "#TrackingTime", "30 Min" );
Check ( "#TrackingDistance", "300" );
CheckState ( "#TrackingPeriodicity", "Visible", false );
CheckState ( "#TrackingTime, #TrackingDistance, #TrackingProvider", "Visible" );
