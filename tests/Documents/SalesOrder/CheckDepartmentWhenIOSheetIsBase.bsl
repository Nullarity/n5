// Create IOSheet
// Save and Create Sales Order
// Check if Sales Order has Department field filled

Call ( "Common.Init" );
CloseAll ();

Commando("e1cib/command/Document.IOSheet.Create");
With();

Click("#JustSave");
Click("#FormDocumentSalesOrderCreateBasedOn");
With();
department = Fetch("#Department");
if(department = "") then
	Stop("The Department field should be filled");
endif;