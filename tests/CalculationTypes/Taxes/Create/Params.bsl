StandardProcessing = false;

p = new Structure ();
p.Insert ( "Description", "_Tax: " + CurrentDate () );
p.Insert ( "Method" );
p.Insert ( "Base", new Array () ); // Array of compensations ID
p.Insert ( "Scale", new Array () ); // Optional. Array of CalculationTypes.Taxes.Create.Scale
p.Insert ( "Rate" ); // Optional. Either Scale or RateDate & Rate should be provided
p.Insert ( "RateDate" );
p.Insert ( "Account" );
return p;