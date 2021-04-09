// Fill payroll taxes

date = BegOfYear ( CurrentDate () );

// ************************
// Income Tax (scale)
// ************************

p = Call ( "CalculationTypes.Taxes.Create.Params" );
p.Description = "Подоходный налог (фиксированный процент)";
p.Method = "Income Tax (fixed percent)";
p.Rate = "12";
p.RateDate = "10/2018";
p.Account = "5342";
Call ( "CalculationTypes.Taxes.Create", p );

// ************************
// Medical Insurance
// ************************

p = Call ( "CalculationTypes.Taxes.Create.Params" );
p.Description = "Медицинское страхование";
p.Method = "Medical Insurance";
p.Insert ( "Rate", 4.5 );
p.Insert ( "RateDate", date );
p.Insert ( "Account", "5332" );
Call ( "CalculationTypes.Taxes.Create", p );

// *****************************
// Medical Insurance (Employees)
// *****************************

p = Call ( "CalculationTypes.Taxes.Create.Params" );
p.Description = "Медицинское страхование (сотрудники)";
p.Method = "Medical Insurance (Employees)";
p.Insert ( "Rate", 4.5 );
p.Insert ( "RateDate", date );
p.Insert ( "Account", "5332" );
Call ( "CalculationTypes.Taxes.Create", p );

// *****************************
// Social Insurance
// *****************************

p = Call ( "CalculationTypes.Taxes.Create.Params" );
p.Description = "Социальное страхование";
p.Method = "Social Insurance";
p.Insert ( "Rate", 23 );
p.Insert ( "RateDate", date );
p.Insert ( "Account", "5331" );
Call ( "CalculationTypes.Taxes.Create", p );

// *****************************
// Social Insurance (Employees)
// *****************************

p = Call ( "CalculationTypes.Taxes.Create.Params" );
p.Description = "Социальное страхование (сотрудники)";
p.Method = "Social Insurance (Employees)";
p.Insert ( "Rate", 6 );
p.Insert ( "RateDate", date );
p.Insert ( "Account", "5331" );
Call ( "CalculationTypes.Taxes.Create", p );
