// Create a range without registration
// Create an Invoice Record and set number manually
// Check if system raises an error about range activity

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6AB994" );

env = getEnv ( id );
createEnv ( env );

// Create an Invoice Record and set number manually
Commando("e1cib/command/Document.InvoiceRecord.Create");
Choose ( "#Range" );
With ();
GotoRow("#List", "Range", env.Range + " 1 - 50");
Click ( "#FormChoose" );
With();
Set("#Series", env.FormPrefix);
Click("Yes", "1?:*");
Set("#FormNumber", 1);
Click("Yes", "1?:*");
Set("#DeliveryDate", "01/01/2020");
Next ();
IgnoreErrors = true;

// Check if system raises an error about range activity
Click("#FormWrite");
try
	CheckErrors();
	Stop("We should get a message: The range <...> is not yet active");
except
endtry;
IgnoreErrors = false;
Disconnect();

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	prexix = Right(ID, 5);
	p.Insert ( "FormPrefix", prexix );
	p.Insert ( "Range", "Invoice Records " + prexix );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *********************
	// Create Range
	// *********************
	
	Commando("e1cib/command/Catalog.Ranges.Create");
	Set("#Type","Invoice Records");
	Set("#Prefix", env.FormPrefix);
	Set("#Start", 1);
	Set("#Finish", 50);
	Set("#Length", 3);
	Click("#WriteAndClose");
	
	RegisterEnvironment ( id );
	
EndProcedure
