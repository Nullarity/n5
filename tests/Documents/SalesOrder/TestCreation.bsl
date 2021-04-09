
Call ( "Common.Init" );

p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
customer = Call ( "Catalogs.Organizations.CreateCustomer", p );

CloseAll ();
Call ( "Common.OpenList", Meta.Documents.SalesOrder );
form = With ( "Sales Orders" );
Click ( "Create", form.GetCommandBar () );

form = With ( "Sales order (create)" );
Set ( "Customer", customer.Code );
form.GotoNextItem ();
