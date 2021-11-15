
// *************************
// Create PaymentOptions
// *************************

byFact = "По факту";
advance = "Аванс";
variantFact = "On Delivery";
variantAdvance = "Prepayment";
p = Call ( "Catalogs.PaymentOptions.Create.Params" );
p.Description = byFact;
Call ( "Catalogs.PaymentOptions.Create", p );

p = Call ( "Catalogs.PaymentOptions.Create.Params" );
p.Description = advance;
Call ( "Catalogs.PaymentOptions.Create", p );

// *************************
// Create terms
// *************************
//Fact
p = Call ( "Catalogs.Terms.Create.Params" );
p.Description = byFact;
optionRow = Call ( "Catalogs.Terms.Create.Row" );
optionRow.Option = byFact;
optionRow.Variant = variantFact;
optionRow.Percent = 100;
p.Payments.Add ( optionRow );
Call ( "Catalogs.Terms.Create", p );

//Advance 50%
p = Call ( "Catalogs.Terms.Create.Params" );
p.Description = advance + "(50%) до отгрузки";
optionRow = Call ( "Catalogs.Terms.Create.Row" );
optionRow.Option = advance;
optionRow.Variant = variantAdvance;
optionRow.Percent = 50;
p.Payments.Add ( optionRow );
optionRow = Call ( "Catalogs.Terms.Create.Row" );
optionRow.Option = byFact;
optionRow.Variant = variantFact;
optionRow.Percent = 50;
p.Payments.Add ( optionRow );
Call ( "Catalogs.Terms.Create", p );

//Advance 100%
p = Call ( "Catalogs.Terms.Create.Params" );
p.Description = advance + "(100%) до отгрузки";
optionRow = Call ( "Catalogs.Terms.Create.Row" );
optionRow.Option = advance;
optionRow.Variant = variantAdvance;
optionRow.Percent = 100;
p.Payments.Add ( optionRow );
Call ( "Catalogs.Terms.Create", p );




