#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;
var Row;
var OperationDate;
var LocalCurrency;
var Company;
var VATAccount;
var ReceivablesVATAccount;
var Base;
var PaymentDate;
var PaymentOption;

Procedure OnCompose () export	
	
	init ();
	unpost ();
	
EndProcedure

Procedure init ()

	OperationDate = DC.GetParameter ( Params.Settings, "Date" ).Value;
	Company = DC.GetParameter ( Params.Settings, "Company" ).Value;
	Base = DC.GetParameter ( Params.Settings, "Base" ).Value;
	PaymentDate = DC.GetParameter ( Params.Settings, "PaymentOption" ).Value;
	PaymentOption = DC.GetParameter ( Params.Settings, "PaymentDate" ).Value;
	LocalCurrency = Application.Currency ();
	accounts = AccountsMap.Item ( Catalogs.Items.EmptyRef (), Company, Catalogs.Warehouses.EmptyRef (), "VAT" );
	VATAccount = accounts.VAT;
	ReceivablesVATAccount = receivablesVAT ();

EndProcedure

Procedure unpost ()

	BeginTransaction ();
	for each ref in getAdjustments ( true ) do
		obj = ref.GetObject ();
		obj.Write ( DocumentWriteMode.UndoPosting );
	enddo;
	CommitTransaction ();

EndProcedure

Function getAdjustments ( Posted )
	
	s = "
	|select Documents.Ref as Ref
	|from Document.AdjustDebts as Documents
	|where not Documents.DeletionMark
	|and Documents.Posted = &Posted
	|and Documents.Base = &Base
	|";
	q = new Query ( s );
	q.SetParameter ( "Posted", Posted );
	q.SetParameter ( "Base", Base );
	table = q.Execute ().Unload ();
	return table.UnloadColumn ( "Ref" );
	
EndFunction

Procedure AfterOutput () export

	table = Params.Result [ Params.Result.Ubound () ].Unload ();
	for each Row in table do
		makeAdjustment ();
	enddo;
	if ( Params.ClearTable ) then
		delete ();
	endif;
	Params.Result = undefined;
	
EndProcedure

Function receivablesVAT ()

	s = "
	|select Settings.Value as Value
	|from InformationRegister.Settings.SliceLast ( ,
	|	Parameter = value ( ChartOfCharacteristicTypes.Settings.ReceivablesVATAccount )
	|) as Settings
	|";
	q = new Query ( s );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Value );
	
EndFunction

Procedure makeAdjustment ()
	
	obj = getObject ();
	obj.Date = OperationDate;
	obj.Company = Company;
	obj.Option = Enums.AdjustmentOptions.Customer;
	customer = Row.Customer;
	contractCurrency = Row.Currency;
	rate = Row.Rate;
	factor = Row.Factor;
	amount = Row.Amount;
	advance = Row.Advance;
	obj.Customer = customer;
	obj.Contract = Row.Contract;
	obj.Receiver = customer;
	obj.ReceiverContract = Row.ContractLocal;
	obj.ContractCurrency = contractCurrency;
	obj.ContractRate = rate;
	obj.ContractFactor = factor;
	obj.ReceiverContractCurrency = LocalCurrency;
	obj.ReceiverContractRate = 1;
	obj.ReceiverContractFactor = 1;
	movingDebt = ( Row.Operation = 0 );
	if ( movingDebt ) then
		if ( amount <> 0 ) then
			obj.Amount = amount;
			obj.Type = Enums.TypesAdjustDebts.Debt;
		else
			obj.Amount = advance;
			obj.Type = Enums.TypesAdjustDebts.Advance;
		endif;
		obj.Currency = contractCurrency;
		obj.Rate = rate;
		obj.Factor = factor;
	else
		if ( amount > 0 ) then
			obj.Amount = amount;
			obj.Type = Enums.TypesAdjustDebts.Debt;
		elsif ( amount < 0 ) then
			obj.Amount = amount;
			obj.Type = Enums.TypesAdjustDebts.Advance;
		elsif ( advance > 0 ) then
			obj.Amount = advance;
			obj.Type = Enums.TypesAdjustDebts.Advance;
		else
			obj.Amount = advance;
			obj.Type = Enums.TypesAdjustDebts.Debt;
		endif;
		obj.Currency = LocalCurrency;
		obj.Rate = 1;
		obj.Factor = 1;
		obj.AmountDifference = true;
	endif;
	setAccounts ( obj );
	obj.Adjustments.Load ( AdjustDebtsForm.GetPayments ( obj ) );
	obj.ReceiverDebts.Load ( AdjustDebtsForm.GetPaymentsReceiver ( obj ) );
	AdjustDebtsForm.CalcContract ( obj );
	AdjustDebtsForm.DistributeAmount ( obj );
	AdjustDebtsForm.CalcApplied ( obj );
	AdjustDebtsForm.CalcReceiverContract ( obj );
	AdjustDebtsForm.DistributeReceiverAmount ( obj );
	AdjustDebtsForm.CalcAppliedReceiver ( obj );
	rest = AdjustDebtsForm.ReceiverDifference ( obj );
	if ( rest <> 0 ) then
		correction = obj.AccountingReceiver.Add ();
		correction.Amount = ? ( movingDebt, rest * rate / factor, rest );
		correction.PaymentDate = PaymentDate;
		correction.PaymentOption = PaymentOption;
		AdjustDebtsForm.CalcAppliedReceiver ( obj );
	endif;
	AdjustDebtsForm.BeforeWriteAtServer ( obj, true );
	if ( Jobs.CheckFilling ( obj ) ) then
		obj.Write ( DocumentWriteMode.Posting );
	endif;
	
EndProcedure

Function getObject ()

	newObject = Documents.AdjustDebts.CreateDocument ();
	Metafields.Constructor ( newObject );
	if ( Row.Adjustment = null ) then
		newObject.Creator = SessionParameters.User;
		newObject.Base = Base;
		return newObject;
	endif;
	obj = Row.Adjustment.GetObject ();
	if ( obj.DeletionMark ) then
		obj.SetDeletionMark ( false );
	endif;
	FillPropertyValues ( obj, newObject, , "Creator, Ref, Number, Posted, DeletionMark, Base" );
	for each table in Metadata.Documents.AdjustDebts.TabularSections do
		obj [ table.Name ].Clear ();
	enddo;
	return obj;

EndFunction

Procedure setAccounts ( Object )
	
	accounts = AccountsMap.Organization ( Object.Customer, Company, "CustomerAccount, AdvanceTaken" );
	customerAccount = accounts.CustomerAccount;
	Object.CustomerAccount = customerAccount;
	Object.AdvanceAccount = accounts.AdvanceTaken;	
	Object.VATAccount = VATAccount;
	Object.VATAdvance = Row.VATAdvance;
	Object.ReceivablesVATAccount = ReceivablesVATAccount;
	object.ReceiverAccount = customerAccount;
	
EndProcedure

Procedure delete ()
	
	BeginTransaction ();
	for each ref in getAdjustments ( false ) do
		obj = ref.GetObject ();
		obj.SetDeletionMark ( true );
	enddo;
	CommitTransaction ();
	
EndProcedure

#endif