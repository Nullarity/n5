// "Downgrade" application to version 1.0.0.0
// Restart app with "-mode skipupdate" key and check if update has been skipped

Call ( "Common.Init" );
CloseAll ();

// "Downgrade" application to version 1.0.0.0
Commando("e1cib/data/CommonForm.System");
With();
Set("#Release", "1.0.0.0");
Click("#FormWriteAndClose");
Disconnect(true);

// Restart app and check if system skips update
p = Call ("Tester.Run.Params");
p.User = "admin";
if ( __.TestServer ) then
	p.IBase = "Core, develop";
else
	p.IBase = "Core, sources";
endif;
p.Port = AppData.Port;
p.Parameters = "/Z FFD0B42561 /C ""-mode skipupdate""";
Call("Tester.Run", p);

// if settings form is opened then update has been skipped
// and release should be 1.0.0.1
Connect();
Commando("e1cib/data/CommonForm.System");
With();
Check("#Release", "1.0.0.0");

// Restore release for preventing further updates
Set("#Release", "1.0.0.1");
Click("#FormWriteAndClose");
