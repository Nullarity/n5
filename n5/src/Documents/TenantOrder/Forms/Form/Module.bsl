// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Paid = getPaidFlag ( Object.Ref );
	Appearance.Apply ( ThisObject );
	if ( Object.Posted ) then
		ReadOnly = true;
	endif; 
	
EndProcedure

&AtServerNoContext
Function getPaidFlag ( val TenantOrder )
	
	return Documents.TenantOrder.Paid ( TenantOrder );
	
EndFunction

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Cloud.SaaS ()
		and Connections.IsDemo () ) then
		Output.DemoMode ();
		Cancel = true;
		return;
	endif; 
	if ( Object.Ref.IsEmpty () ) then
		setTenant ();
		setDate ();
		setPrice ();
		setPromoCodeData ();
		calcDateEnd ( ThisObject );
		calcAmount ( ThisObject );
		calcBonus ( ThisObject );
		setPaymentMethod ();
	endif; 
	applyInfoEmail ();
	initStep ();
	setDefaultButton ( ThisObject );
	initTitle ( ThisObject );
	setDiscounts ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|FormClose show
	|( Object.Posted
	|	or Object.DeletionMark
	|	or Step = 4 );
	|FormGoToPaymentMethod show
	|Step = 1
	|and not Object.Posted
	|and not Object.DeletionMark;
	|FormBackToOrder show ( Step = 2 or Step = 3 );
	|FormCancel show
	|not Object.Posted
	|and ( Step = 1
	|	or Step = 2
	|	or Step = 3 );
	|OrderDeleted show Object.DeletionMark;
	|UsersCount MonthsCount Date lock ( Object.Posted or Object.DeletionMark );
	|OrderPaid CompleteMessage OpenTenantOrdersList show Paid;
	|OrderPage show Step = 1;
	|PaymentMethodPage FormGoToPayment show Step = 2;
	|PaymentPage show Step = 3;
	|PaymentComplete show Step = 4;
	|PaymentInfo show Object.Posted
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure setTenant ()
	
	Object.Tenant = SessionParameters.Tenant;
	SetPrivilegedMode ( true );
	Object.AgentTenant = DF.Pick ( SessionParameters.Tenant, "PromoCode.Agent.Tenant" );
	SetPrivilegedMode ( false );
	
EndProcedure 

&AtServer
Procedure setDate ()
	
	if ( Object.Date = Date ( 1, 1, 1 ) ) then
		Object.Date = BegOfDay ( CurrentSessionDate () );
	endif; 
	
EndProcedure 

&AtServer
Procedure setPrice ()
	
	Object.AccessPrice = Constants.AccessPrice.Get ();
	Object.Currency = Constants.CloudCurrency.Get ();
	
EndProcedure 

&AtServer
Procedure setPromoCodeData ()
	
	SetPrivilegedMode ( true );
	fields = DF.Values ( SessionParameters.Tenant, "PromoCode.Discount, PromoCode.Bonus, PromoCode.Finish" );
	SetPrivilegedMode ( false );
	if ( fields.PromoCodeFinish < CurrentSessionDate () ) then
		Object.PromoCodeDiscount = 0;
		Object.BonusPercent = 0;
	else
		Object.PromoCodeDiscount = fields.PromoCodeDiscount;
		Object.BonusPercent = fields.PromoCodeBonus;
	endif; 
	
EndProcedure 

&AtClientAtServerNoContext
Procedure calcDateEnd ( Form )
	
	object = Form.Object;
	object.DateEnd = AddMonth ( object.Date, object.MonthsCount );
	
EndProcedure 

&AtClientAtServerNoContext
Procedure calcAmount ( Form )
	
	calcDiscountRate ( Form );
	object = Form.Object;
	object.GrossAmount = object.AccessPrice * object.UsersCount * object.MonthsCount;
	object.Discount = object.GrossAmount / 100 * ( object.DiscountRate + object.PromoCodeDiscount );
	object.Amount = object.GrossAmount - object.Discount;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure calcDiscountRate ( Form )
	
	object = Form.Object;
	if ( object.UsersCount < 5 ) then
		usersDiscount = 0;
	elsif ( object.UsersCount < 10 ) then
		usersDiscount = 10;
	elsif ( object.UsersCount < 20 ) then
		usersDiscount = 15;
	elsif ( object.UsersCount < 50 ) then
		usersDiscount = 20;
	elsif ( object.UsersCount < 100 ) then
		usersDiscount = 25;
	elsif ( object.UsersCount < 500 ) then
		usersDiscount = 30;
	else
		usersDiscount = 35;
	endif; 
	if ( object.MonthsCount < 3 ) then
		monthsDiscount = 0;
	elsif ( object.MonthsCount < 6 ) then
		monthsDiscount = 3;
	elsif ( object.MonthsCount < 12 ) then
		monthsDiscount = 6;
	elsif ( object.MonthsCount < 24 ) then
		monthsDiscount = 12;
	else
		monthsDiscount = 15;
	endif;
	object.DiscountRate = Min ( 100, usersDiscount + monthsDiscount );
	
EndProcedure 

&AtClientAtServerNoContext
Procedure calcBonus ( Form )
	
	object = Form.Object;
	object.Bonus = object.Amount / 100 * object.BonusPercent;
	
EndProcedure 

&AtServer
Procedure setPaymentMethod ()
	
	if ( Parameters.CopyingValue.IsEmpty () ) then
		Object.Method = Constants.CloudPaymentMethod.Get ();
	endif; 
		
EndProcedure 

&AtServer
Procedure applyInfoEmail ()
	
	s = Items.PayPalInformation.Title;
	Items.PayPalInformation.Title = Output.FormatStr ( s, new Structure ( "Info", Cloud.Info () ) );
	
EndProcedure 

&AtServer
Procedure initStep ()
	
	Step = 1;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setDefaultButton ( Form )
	
	items = Form.Items;
	items.FormGoToPaymentMethod.DefaultButton = ( Form.Step = 1 );
	items.FormGoToPayment.DefaultButton = ( Form.Step = 2 );
	
EndProcedure 

&AtClientAtServerNoContext
Procedure initTitle ( Form )
	
	object = Form.Object;
	if ( Form.Paid or object.DeletionMark ) then
		Form.AutoTitle = true;
	else
		Form.AutoTitle = false;
		Form.Title = Output.PaymentStep1 ();
	endif; 
	
EndProcedure 

&AtServer
Procedure setDiscounts ()
	
	Discounts.Put ( Documents.TenantOrder.GetTemplate ( "Discounts" ) );
	
EndProcedure 

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	protectFromStuffing ();
	
EndProcedure

&AtServer
Procedure protectFromStuffing ()
	
	setTenant ();
	calcDateEnd ( ThisObject );
	calcAmount ( ThisObject );
	calcBonus ( ThisObject );
	
EndProcedure 

// *****************************************
// *********** Page Order

&AtClient
Procedure GoToPaymentMethod ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif; 
	gotoPaymentMethodPage ();
	
EndProcedure

&AtClient
Procedure gotoPaymentMethodPage ()
	
	Step = 2;
	setDefaultButton ( ThisObject );
	Title = Output.PaymentStep2 ();
	Appearance.Apply ( ThisObject, "Step" );
	
EndProcedure 

&AtClient
Procedure GoToPayment ( Command )
	
	Output.BuyNowConfirmation ( ThisObject );
	
EndProcedure

&AtClient
Procedure BuyNowConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	if ( Object.Method = PredefinedValue ( "Enum.PaymentMethods.PayPal" ) ) then
		GotoURL ( getPaymentAddress () );
		gotoPaymentPage ();
	else
		postOrder ();
		gotoInvoicePage ();
	endif; 
	
EndProcedure 

&AtServer
Function getPaymentAddress ()
	
	p = new Structure ();
	p.Insert ( "Amount", Format ( Object.Amount, "NFD=2;NDS=.;NZ=" ) );
	p.Insert ( "Custom", Object.Number );
	itemName = Output.ApplicationItemName ( new Structure ( "UsersCount, MonthsCount", Object.UsersCount, Object.MonthsCount ) );
	p.Insert ( "ItemName", itemName );
	paymentParams = "Amount=%Amount&ItemName=%ItemName&Custom=%Custom";
	url = Cloud.PaymentsURL () + "/test.aspx?" + EncodeString ( Output.FormatStr ( paymentParams, p ), StringEncodingMethod.URLInURLEncoding );
	return url;
	
EndFunction

&AtClient
Procedure gotoPaymentPage ()
	
	Step = 3;
	Title = Output.PaymentStep3 ();
	Appearance.Apply ( ThisObject, "Step" );
	attachPaymentChecking ();
	
EndProcedure 

&AtClient
Procedure attachPaymentChecking ()
	
	AttachIdleHandler ( "paymentCheckingHandler", 3 );
	
EndProcedure 

&AtClient
Procedure paymentCheckingHandler ()
	
	Paid = getPaidFlag ( Object.Ref );
	if ( Paid ) then
		detachPaymentChecking ();
		postOrder ();
		gotoPaymentCompletePage ();
	endif; 
	
EndProcedure 

&AtClient
Procedure detachPaymentChecking ()
	
	DetachIdleHandler ( "paymentCheckingHandler" );
	
EndProcedure 

&AtServer
Procedure postOrder ()
	
	Write ( new Structure ( "WriteMode", DocumentWriteMode.Posting ) );
	
EndProcedure 

&AtClient
Procedure gotoPaymentCompletePage ()
	
	Step = 4;
	Title = Output.PaymentStep4PayPal ();
	Appearance.Apply ( ThisObject, "Paid" );
	Appearance.Apply ( ThisObject, "Step" );
	
EndProcedure 

&AtServer
Procedure gotoInvoicePage ()
	
	Step = 4;
	Title = Output.PaymentStep4Bank ();
	setInvoiceMessage ();
	Appearance.Apply ( ThisObject, "Step" );
	
EndProcedure 

&AtServer
Procedure setInvoiceMessage ()
	
	p = new Structure ( "Email", "" + Object.Tenant );
	Items.InvoiceMessage.Title = Output.InvoiceInformation ( p );
	
EndProcedure 

&AtClient
Procedure Cancel ( Command )
	
	Output.CancelTenantOrder ( ThisObject );
	
EndProcedure

&AtClient
Procedure CancelTenantOrder ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		Modified = false;
		Close ();
	endif; 
	
EndProcedure 

&AtClient
Procedure UsersCountOnChange ( Item )
	
	calcAmount ( ThisObject );
	calcBonus ( ThisObject );
	
EndProcedure

&AtClient
Procedure MonthsCountOnChange ( Item )
	
	calcDateEnd ( ThisObject );
	calcAmount ( ThisObject );
	calcBonus ( ThisObject );
	
EndProcedure

&AtClient
Procedure DateOnChange ( Item )
	
	calcDateEnd ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Page Payment

&AtClient
Procedure BackToOrder ( Command )
	
	if ( Step = 3 ) then
		Output.BreakPaymentChecking ( ThisObject );
	else
		gotoOrderPage ();
	endif; 
	
EndProcedure

&AtClient
Procedure BreakPaymentChecking ( Answer, Params ) export
	
	if ( answer = DialogReturnCode.Yes ) then
		detachPaymentChecking ();
		gotoOrderPage ();
	endif; 
	
EndProcedure

&AtClient
Procedure gotoOrderPage ()
	
	Paid = getPaidFlag ( Object.Ref );
	Step = 1;
	setDefaultButton ( ThisObject );
	initTitle ( ThisObject );
	Appearance.Apply ( ThisObject, "Paid" );
	Appearance.Apply ( ThisObject, "Step" );
	
EndProcedure 

// *****************************************
// *********** Page PaymentComplete

&AtClient
Procedure OpenTenantOrdersList ( Command )
	
	OpenForm ( "Document.TenantOrder.ListForm" );
	Close ();
	
EndProcedure
