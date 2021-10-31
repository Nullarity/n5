&AtClient
Procedure Open ( Form, NotifyNew ) export
	
	if ( PettyCash.Voucher ( Form.Object.Ref ) ) then
		name = "CashVoucher";
		ref = Form.Voucher;
	else
		name = "CashReceipt";
		ref = Form.Receipt;
	endif; 
	params = new Structure ( "Form, NotifyNew, Reference", Form, NotifyNew, ref );
	callback = new NotifyDescription ( "PettyCashClosed", ThisObject, params );
	OpenForm ( "Document." + name + ".ObjectForm", new Structure ( "Key", ref ), Form, , , , callback );
	
EndProcedure 

Function Voucher ( Reference ) export
	
	type = TypeOf ( Reference );
	if ( type = Type ( "DocumentRef.CashVoucher" ) ) then
		return true;
	elsif ( type = Type ( "DocumentRef.CashReceipt" ) ) then
		return false;
	else
		return PettyCashSrv.Voucher ( Reference );
	endif;
	
EndFunction 

&AtClient
Procedure PettyCashClosed ( Result, Params ) export
	
	if ( Params.NotifyNew ) then
		Params.Form.NotifyWritingNew ( Params.Reference );
	endif; 
	
EndProcedure 

&AtServer
Procedure Read ( Form ) export
	
	reference = PettyCashSrv.Search ( Form.Object.Ref );
	if ( PettyCash.Voucher ( reference ) ) then
		Form.Voucher = reference;
	else
		Form.Receipt = reference;
	endif; 
	
EndProcedure 

&AtServer
Procedure NewReference ( Form ) export
	
	object = Form.Object;
	if ( object.Ref.IsEmpty () ) then
		Form.Write ();
	endif;
	field = ? ( PettyCash.Voucher ( object.Ref ), "Voucher", "Receipt" );
	if ( Form [ field ].IsEmpty () ) then
		update ( object, Form [ field ] );
	endif; 
	
EndProcedure 

&AtServer
Procedure update ( Object, Reference )
	
	isVoucher = PettyCash.Voucher ( Reference );
	if ( Reference.IsEmpty () ) then
		if ( isVoucher ) then
			obj = Documents.CashVoucher.CreateDocument ();
		else
			obj = Documents.CashReceipt.CreateDocument ();
		endif; 
		isNew = true;
	else
		obj = Reference.GetObject ();
		isNew = false;
	endif;
	obj.Date = Object.Date;
	obj.Company = Object.Company;
	obj.Memo = Object.Memo;
	obj.Posted = Object.Posted;
	obj.DeletionMark = false;
	type = TypeOf ( Object.Ref );
	if ( type = Type ( "DocumentRef.Entry" ) ) then
		entry = entryData ( Object );
		obj.Currency = entry.Currency;
		obj.Amount = entry.Amount;
		obj.Location = entry.Location;
	elsif ( type = Type ( "DocumentRef.PayEmployees" )
		or type = Type ( "DocumentRef.PayAdvances" ) ) then
		obj.Currency = Application.Currency ();
		obj.Amount = Object.Amount;
		obj.Location = Object.Location;
	elsif ( type = Type ( "DocumentRef.Refund" ) ) then
		obj.Currency = Object.Currency;
		obj.Location = Object.Location;
		obj.Amount = Object.Amount;
	else
		obj.Currency = Object.Currency;
		obj.Location = Object.Location;
		obj.Amount = ? ( isVoucher, Object.Total, Object.Amount );
	endif; 
	if ( isNew ) then
		creator = Object.Creator;
		obj.Creator = creator;
		obj.Base = Object.Ref;
		obj.Responsible = DF.Pick ( creator, "Employee.Individual" );
		data = Responsibility.Get ( Object.Date, Object.Company, "AccountantChief, GeneralManager" );
		obj.Accountant = data.AccountantChief;
		obj.Director = data.GeneralManager;
		if ( type = Type ( "DocumentRef.Payment" ) ) then
			obj.Giver = presentation ( Object.Customer );
		elsif ( type = Type ( "DocumentRef.VendorPayment" ) ) then
			obj.Receiver = presentation ( Object.Vendor );
		elsif ( type = Type ( "DocumentRef.PayEmployees" )
			or type = Type ( "DocumentRef.PayAdvances" ) ) then
			obj.Receiver = Object.Ref;
		elsif ( type = Type ( "DocumentRef.Entry" ) ) then
			subject = entry.Subject;
			name = presentation ( subject );
			if ( isVoucher ) then
				obj.Receiver = name;
				obj.ID = subjectID ( subject );
			else
				obj.Giver = name;
			endif;
		elsif ( type = Type ( "DocumentRef.VendorRefund" ) ) then
			obj.Giver = presentation ( Object.Vendor );	
		elsif ( type = Type ( "DocumentRef.Refund" ) ) then
			obj.Receiver = presentation ( Object.Customer );	
		endif; 
	endif; 
	markSyncing ( obj );
	obj.Write ();
	if ( isNew ) then
		Reference = obj.Ref;
	endif; 
	
EndProcedure

&AtServer
Function entryData ( Object )
	
	s = "
	|select
	|	case
	|		when Records.Ref.Operation.Operation = value ( Enum.Operations.CashExpense )
	|			and Records.AccountCr.Currency then
	|			Records.CurrencyCr
	|		when Records.Ref.Operation.Operation = value ( Enum.Operations.CashReceipt )
	|			and Records.AccountDr.Currency then
	|			Records.CurrencyDr
	|		else
	|			Constants.Currency
	|	end as Currency,
	|	case
	|		when Records.Ref.Operation.Operation = value ( Enum.Operations.CashExpense ) then
	|			Records.DimCr1
	|		else
	|			Records.DimDr1
	|	end as Location,
	|	case
	|		when Records.Ref.Operation.Operation = value ( Enum.Operations.CashExpense ) then
	|			Records.DimDr1
	|		else
	|			Records.DimCr1
	|	end as Subject,
	|	case
	|		when Records.Ref.Operation.Operation = value ( Enum.Operations.CashExpense ) then
	|			case when Records.AccountCr.Currency then Total.CurrencyAmount else Total.Amount end
	|		else
	|			case when Records.AccountDr.Currency then Total.CurrencyAmount else Total.Amount end
	|	end as Amount
	|from Document.Entry.Records as Records
	|	//
	|	// Totals
	|	//
	|	left join (
	|		select
	|			sum ( Records.Amount ) as Amount,
	|			sum ( isnull (
	|				case when Records.Ref.Operation.Operation = value ( Enum.Operations.CashExpense ) then
	|					 	Records.CurrencyAmountCr
	|					else Records.CurrencyAmountDr
	|				end, 0 )
	|			) as CurrencyAmount
	|		from Document.Entry.Records as Records
	|		where Records.Ref = &Ref
	|	) as Total
	|	on true
	|	//
	|	// Constants
	|	//
	|	left join Constants
	|	on true
	|where Records.Ref = &Ref
	|and Records.LineNumber = 1
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	return Conversion.RowToStructure ( q.Execute ().Unload () );

EndFunction 

&AtServer
Function presentation ( Value )
	
	type = TypeOf ( Value );
	if ( type = Type ( "CatalogRef.Organizations" ) ) then
		data = DF.Values ( Value, "Individual, Description, FullDescription" );
		return ? ( data.Individual, data.Description, data.FullDescription );
	else
		return String ( Value );
	endif; 
	
EndFunction 

&AtServer
Function subjectID ( Subject )
	
	if ( TypeOf ( Subject ) <> Type ( "CatalogRef.Individuals" ) ) then
		return  "";
	endif; 
	data = identificationData ( Subject );
	if ( data = undefined ) then
		return "";
	endif; 
	parts = new Array ();
	value = data.Series;
	if ( value <> "" ) then
		parts.Add ( Output.IDSeries () + " " + value );
	endif; 
	value = data.Number;
	if ( value <> "" ) then
		parts.Add ( Output.IDNumber () + value );
	endif; 
	value = data.IssuedBy;
	if ( value <> "" ) then
		parts.Add ( Output.IDIssuedBy () + " " + value );
	endif; 
	value = data.Issued;
	if ( value <> Date ( 1, 1, 1 ) ) then
		parts.Add ( Output.IDIssued () + " " + Format ( value, "DLF=D" ) );
	endif; 
	s = StrConcat ( parts, ", " );
	value = data.Type;
	if ( value <> "" ) then
		s = "" + value + ": " + s;
	endif; 
	return Title ( s );
	
EndFunction 

&AtServer
Function identificationData ( Subject )
	
	s = "
	|select IDs.Type as Type, IDs.Series as Series, IDs.Number as Number,
	|	IDs.IssuedBy as IssuedBy, IDs.Issued as Issued
	|from InformationRegister.ID as IDs
	|where IDs.Individual = &Individual
	|and IDs.Main
	|";
	q = new Query ( s );
	q.SetParameter ( "Individual", Subject );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ] );
	
EndFunction 

&AtServer
Procedure Sync ( Object ) export
	
	if ( syncing ( Object ) ) then
		return;
	endif; 
	reference = PettyCashSrv.Search ( Object.Ref );
	if ( relationMustDie ( Object ) ) then
		if ( not reference.IsEmpty () ) then
			remove ( reference );
		endif; 
	else
		update ( Object, reference );
	endif; 
	
EndProcedure 

&AtServer
Function syncing ( Object )
	
	sync = undefined;
	Object.AdditionalProperties.Property ( "Syncing", sync );
	return sync <> undefined
	and sync;
	
EndFunction 

&AtServer
Function relationMustDie ( Object )
	
	type = TypeOf ( Object.Ref );
	if ( ( type = Type ( "DocumentRef.Payment" )
		or type = Type ( "DocumentRef.VendorPayment" )
		or type = Type ( "DocumentRef.PayEmployees" )
		or type = Type ( "DocumentRef.PayAdvances" ) )
		and Object.Method = Enums.PaymentMethods.Cash ) then
		return false;
	elsif ( type = Type ( "DocumentRef.Entry" ) ) then
		operation = DF.Pick ( Object.Operation, "Operation" );
		return operation <> Enums.Operations.CashExpense
		and operation <> Enums.Operations.CashReceipt;
	endif;
	return true;
	
EndFunction 

&AtServer
Procedure remove ( Ref )
	
	obj = Ref.GetObject ();
	markSyncing ( obj );
	obj.SetDeletionMark ( true );
	
EndProcedure 

&AtServer
Procedure markSyncing ( Object )
	
	Object.AdditionalProperties.Insert ( "Syncing", true );
	
EndProcedure 

&AtServer
Procedure Delete ( Object ) export
	
	if ( syncing ( Object ) ) then
		return;
	endif; 
	reference = PettyCashSrv.Search ( Object.Ref );
	if ( not reference.IsEmpty () ) then
		remove ( reference );
	endif; 

EndProcedure 

&AtServer
Procedure SyncBase ( Object ) export
	
	if ( syncing ( Object ) ) then
		return;
	endif; 
	updateBase ( Object );
	
EndProcedure 

&AtServer
Procedure updateBase ( Object )
	
	base = Object.Base;
	parent = DF.Values ( base, "Posted, DeletionMark" );
	posted = Object.Posted;
	marked = Object.DeletionMark;
	postingChanged = parent.Posted <> posted;
	markChanged = parent.DeletionMark <> marked;
	if ( postingChanged ) then
		obj = base.GetObject ();
		markSyncing ( obj );
		if ( posted ) then
			if ( obj.CheckFilling () ) then
				obj.Write ( DocumentWriteMode.Posting );
			else
				raise Output.OperationError ();
			endif;
		else
			obj.Write ( DocumentWriteMode.UndoPosting );
		endif; 
	endif;
	if ( markChanged ) then
		obj = base.GetObject ();
		markSyncing ( obj );
		obj.SetDeletionMark ( marked );
	endif;
	
EndProcedure 

&AtServer
Procedure DeleteBase ( Object ) export
	
	if ( syncing ( Object ) ) then
		return;
	endif; 
	remove ( Object.Base );

EndProcedure 

&AtClient
Procedure Print ( Params ) export
	
	if ( shortcutPressedInMainWindow ( Params ) ) then
		return;
	endif; 
	form = Params.Source;
	if ( form.Modified ) then
		form.Write ();
	endif; 
	formName = form.FormName;
	if ( formName = "CommonForm.CashReceipt"
		or formName = "CommonForm.CashVoucher" ) then
		document = form.Parameters.Key;
	else
		document = PettyCashSrv.Search ( form.Object.Ref );
	endif; 
	PettyCash.Output ( document );
	
EndProcedure 

&AtClient
Function shortcutPressedInMainWindow ( Params )
	
	return TypeOf ( Params.Source ) = Type ( "ClientApplicationWindow" );
	
EndFunction 

&AtClient
Procedure Output ( Scope ) export
	
	document = ? ( TypeOf ( Scope ) = Type ( "Array" ), Scope [ 0 ], Scope );
	name = ? ( PettyCash.Voucher ( document ), "Voucher", "Receipt" );
	p = Print.GetParams ();
	p.Objects = Scope;
	p.Key = name;
	p.Template = name;
	Print.Print ( p );
	
EndProcedure 

&AtClient
Procedure ClickProcessing ( Form, StandardProcessing ) export
	
	if ( Form.Modified ) then
		StandardProcessing = Form.Write ();
	endif; 
	
EndProcedure 
