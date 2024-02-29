// Check document amount after picking an item

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A198" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region purchaseOrder
Commando ( "e1cib/command/Document.PurchaseOrder.Create" );
Click ( "#ItemsSelectItems" );
With ( "Items Selection" );
if ( Fetch ( "#AskDetails" ) = "No" ) then
	Click ( "#AskDetails" );
endif;
Put ( "#Addition1", this.Service );
Pause ( 2 * __.Performance );
ItemsList = Get ( "#ItemsList" );
ItemsList.Choose ();
Activate ( "#GroupFeatures" ); // GroupFeatures
FeaturesList = Get ( "#FeaturesList" );
FeaturesList.Choose ();
With ( "Details" );
Set ( "#ServicesQuantity", 568 );
amount = this.Amount;
Set ( "#ServicesAmount", amount );
Click ( "#FormOK" );
With ( "Items Selection" );
Click ( "#FormOK" );
With ( "Purchase Order (create) *" );
Activate ( "#GroupServices" ); // Services
Services = Get ( "#Services" );
Check ( "#Services / #ServicesAmount [ 1 ]", amount );
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Service", "Service " + id );
	this.Insert ( "Amount", 120.3 );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createService
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
