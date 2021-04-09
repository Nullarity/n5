Call ( "Common.Init" );
CloseAll ();

license = "00" + Call ("Common.GetID");
Commando("e1cib/data/CommonForm.Settings");
With();
Set("#License", license);
Next();
Click("#FormWriteAndClose");
Click("No", DialogsTitle);
strillOpened = Waiting("Application Settings");
if ( strillOpened ) then
	Stop("The Application Settings window should be closed!");
endif;