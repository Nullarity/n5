Commando("e1cib/command/Catalog.Organizations.Create");
Set("Name", _.Name);
if ( AppName = "c5" ) then
	Set("#CodeFiscal", "1234567890123");
endif;
if ( Fetch ( "#Customer" ) = "No" ) then
	Click ( "#Customer" );
endif;
if ( _.BankAccount <> undefined ) then
	Click("#FormWrite");
	CheckErrors();
	Click("#CustomerPage");
	Get("#CustomerContract").Open ();
	With();
	Activate("#CustomerBank").Create ();
	With();
	Set("#AccountNumber", _.BankAccount);
	Next();
	Click("#FormWriteAndClose");
	CheckErrors();
	With();
	Click("#FormWriteAndClose");
	CheckErrors();
	With();
endif;
if ( _.PaymentAddress <> undefined ) then
	Click ( "#FormWrite" );
	CheckErrors();
	field = Activate("#PaymentAddress");
	field.OpenDropList ();
	field.Create ();
	With();
	Click("#Manual");
	Set("#Address", _.PaymentAddress);
	Click("#FormWriteAndClose");
	CheckErrors();
	With();
endif;
Click ( "#FormWriteAndClose" );
