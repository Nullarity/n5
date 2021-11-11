// Check how Goverment falg works

Call ( "Common.Init" );
CloseAll ();

Commando("e1cib/command/Catalog.Organizations.Create");
#region governmentFlag
Click("#Government");
CheckState("#Individual", "Visible", false);
Click("#Government");
CheckState("#Individual", "Visible");
#endregion

#region individualFlag
Click("#Individual");
CheckState("#Government", "Visible", false);
Click("#Individual");
CheckState("#Government", "Visible");
#endregion
