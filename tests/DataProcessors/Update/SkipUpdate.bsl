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
p.Infobase = AppName;
p.Port = AppData.Port;
p.Parameters = "/Z 0C931F556B /C ""-mode skipupdate""";
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
