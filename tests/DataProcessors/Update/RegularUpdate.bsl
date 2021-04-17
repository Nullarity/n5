// "Downgrade" application to version 1.0.0.0
// Restart app and perform update
// Check if update has been completed

Call ( "Common.Init" );
CloseAll ();

// "Downgrade" application to version 1.0.0.0
Commando("e1cib/data/CommonForm.System");
With();
Set("#Release", "1.0.0.0");
Click("#FormWriteAndClose");
Disconnect(true);

// Restart app and check if system updates
p = Call ("Tester.Run.Params");
p.User = "admin";
p.Infobase = AppName;
p.Port = AppData.Port;
p.Parameters = "/Z FFD0B42561";
Call("Tester.Run", p);

// Connect and check message
Connect();
With("");
Click("#FormGo");
Waiting("_Update_is_Happening_", 5);
With();
Close();
Commando("e1cib/data/CommonForm.System");
With();
Check("#Release", "1.0.0.1");
