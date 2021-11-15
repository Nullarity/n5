// Description:
// 1. Does standard selection process.
// 2. Opens Details form and chane Qty, Pkg, Units
// 3. Use Prices parameter if you want to check amount calculation

form = With ( "Items Selection" );

flag = ? ( _.ShowPrices, "Yes", "No" );
if ( flag <> Fetch ( "#ShowPrices" ) ) then
	Click ( "#ShowPrices" );
endif;

details = _.AskDetails;
flag = ? ( details, "Yes", "No" );
if ( flag <> Fetch ( "#AskDetails" ) ) then
	Click ( "#AskDetails" );
endif;

if ( _.AvailableOnly ) then
	Pick ( "#Filter", "Available Only" );
else
	Pick ( "#Filter", "None" );
endif;

showItems = _.ShowItems;
flag = ? ( showItems, "Yes", "No" );
if ( flag <> Fetch ( "#ShowItems" ) ) then
	Click ( "#ShowItems" );
endif;

p = Call ( "Common.Find.Params" );
p.Where = "Item";
p.What = _.Item;
p.Button = "#ItemsListContextMenuFind";
Call ( "Common.Find", p );

list = Get ( "#ItemsList" );
list.Choose ();

// ***********************************
// Details Form
// ***********************************

if ( details ) then
	With ( "Details" );
	Set ( "#QuantityPkg", 5 );
	Activate ( "#Quantity" );
	Check ( "#Quantity", 25 );

	Set ( "#Quantity", 50 );
	Activate ( "#QuantityPkg" );
	Check ( "#QuantityPkg", 10 );

	Clear ( "#Package" );
	Check ( "#Quantity", 10 );

	Put ( "#Package", "PK" );
	Check ( "#Quantity", 50 );

	if ( _.Prices ) then
		Set ( "#QuantityPkg", 5 );
		Set ( "#Price", 10 );
		Activate ( "#Amount" );
		Check ( "#Amount", 50 );

		Set ( "#Amount", 100 );
		Activate ( "#Price" );
		Check ( "#Price", 20 );
		
		Set ( "#Amount", 0 );
	endif;

	Click ( "#FormOK" );
	
	// *********************************************************
	// Select Item again and again and check selected rows count
	// *********************************************************

	if ( showItems ) then
		list.Choose ();
		With ( "Details" );
		
		Click ( "#FormOK" );
		With ( form );
		
		t = Get ( "#SelectedItems" );
		t.GotoLastRow ();
		count = Fetch ( "#SelectedItemsLineNumber", t );
		if ( count <> "1" ) then
			Stop ( "The total count of Selected Items should be 1 because two rows are equal. Actual value is " + count );
		endif;
		
		if ( _.Prices ) then
			list.Choose ();
			With ( "Details" );
			
			Set ( "#Price", 10 );
	
			Click ( "#FormOK" );
			With ( form );
			
			t = Get ( "#SelectedItems" );
			t.GotoLastRow ();
			count = Fetch ( "#SelectedItemsLineNumber", t );
			if ( count <> "2" ) then
				Stop ( "The total count of Selected Items should be 2 because prices are different. Actual value is " + count );
			endif;
		endif;
	endif;
endif;

Click ( "#FormOK" );
