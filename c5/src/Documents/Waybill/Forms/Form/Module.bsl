&AtServer
var Env;
&AtClient
var At7h;
&AtClient
var At19h;
&AtServer
var ViewWriteOff;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	markVersoErrors ( ThisObject );
	setCarType ();
	setNormative ();
	setTotalsByHours ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtClientAtServerNoContext
Procedure markVersoErrors ( Form )
	
	object = Form.Object;
	items = Form.Items;
	verso = object.Verso;
	red = WebColors.Red;
	black = WebColors.Black;
	items.VersoMileage.FooterTextColor = ? ( verso.Total ( "Mileage" ) > object.TotalMileage, red, black );
	engineHours = object.EngineHoursMax + object.EngineHoursAvg + object.EngineHoursMin + object.EquipmentWorkTime;
	items.VersoEngineHours.FooterTextColor = ? ( verso.Total ( "EngineHours" ) > engineHours, red, black );
	
EndProcedure 

&AtServer
Procedure setCarType ()
	
	CarType = DF.Pick ( Object.Car, "CarType.Type" );
	
EndProcedure

&AtServer
Procedure setNormative ()
	
	if ( Object.Car.IsEmpty () ) then
		return;
	endif; 
	data = getNorms ();
	FillPropertyValues ( ThisObject, data );

EndProcedure 

&AtServer
Function getNorms ()
	
	s = "
	|select
	|	case when &Method = value ( Enum.FuelExpenseMethods.Summer ) then Cars.CarType.EquipmentSummer else Cars.CarType.EquipmentWinter end as NormEquipment,
	|	case when &Method = value ( Enum.FuelExpenseMethods.Summer ) then Cars.CarType.EngineSummerAvg else Cars.CarType.EngineWinterAvg end as NormEngineAvg,
	|	case when &Method = value ( Enum.FuelExpenseMethods.Summer ) then Cars.CarType.EngineSummerMax else Cars.CarType.EngineWinterMax end as NormEngineMax,
	|	case when &Method = value ( Enum.FuelExpenseMethods.Summer ) then Cars.CarType.EngineSummerMin else Cars.CarType.EngineWinterMin end as NormEngineMin,
	|	case when &Method = value ( Enum.FuelExpenseMethods.Summer ) then Cars.CarType.OdometerSummer else Cars.CarType.OdometerWinter end as NormOdometer,
	|	case when &Method = value ( Enum.FuelExpenseMethods.Summer ) then Cars.CarType.OdometerSummerCity else Cars.CarType.OdometerWinterCity end as NormOdometerCity,
	|	case when &Method = value ( Enum.FuelExpenseMethods.Summer ) then Cars.CarType.AdditionalEquipmentSummer else Cars.CarType.AdditionalEquipmentSummer end as NormAdditionalEquipment,
	|	case when &Method = value ( Enum.FuelExpenseMethods.Summer ) then Cars.CarType.TrailerSummer else Cars.CarType.TrailerWinter end as NormTrailer,
	|	case when &Method = value ( Enum.FuelExpenseMethods.Summer ) then Cars.CarType.TransportWorkSummer else Cars.CarType.TransportWorkWinter end as NormTransportWork,
	|	case when &Method = value ( Enum.FuelExpenseMethods.Summer ) then Cars.CarType.MovementsSummer else Cars.CarType.MovementsWinter end as NormMovements,
	|	Cars.CarType.Carrying as Carrying, Cars.CarType.Weight as CarWeight 
	|from Catalog.Cars as Cars
	|where Cars.Ref = &Car
	|";
	q = new Query ( s );
	q.SetParameter ( "Car", Object.Car );
	q.SetParameter ( "Method", Object.FuelExpenseMethod );
	return q.Execute ().Unload () [ 0 ];

EndFunction 

&AtClientAtServerNoContext
Procedure setTotalsByHours ( Form )
	
	object = Form.Object;
	Form.ExpenseEngineHours = object.ExpenseEngineMax + object.ExpenseEngineAvg + object.ExpenseEngineMin;
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.Init ( Object );
		fillNew ();
		setFuelExpenseMethod ();
		if ( not Object.Car.IsEmpty () ) then
			setCar ();
		endif; 
	endif;
	setLinks ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|FuelBalances enable Object.FuelInventory;
	|MileageTrailerI MileageTrailerII MileageTrailerWithoutI MileageTrailerWithoutII CoefficientTrailerI CoefficientTrailerII enable filled ( Object.Trailer );
	|EquipmentWorkTime enable
	|CarType <> Enum.CarTypes.Truck
	|and ( NormAdditionalEquipment <> 0 or NormEquipment <> 0 );
	|EngineHours enable
	|( NormEngineAvg <> 0
	|	or NormEngineMax <> 0
	|	or NormEngineMin <> 0 );
	|EngineHoursAvg enable NormEngineAvg <> 0;
	|EngineHoursMin enable NormEngineMin <> 0;
	|EngineHoursMax enable NormEngineMax <> 0;
	|MileageCity enable inlist ( CarType, Enum.CarTypes.PassengerCar, Enum.CarTypes.Rent );
	|AdditionalEquipmentsWork AdditionalEquipments enable
	|CarType <> Enum.CarTypes.Truck
	|and ( NormAdditionalEquipment <> 0 or NormEquipment <> 0 );
	|CoefficientCar enable CarType = Enum.CarTypes.Truck;
	|QuantityTrips enable CarType = Enum.CarTypes.Truck and Object.CoefficientCar <= 0.5;
	|CoefficientConsumption enable CarType <> Enum.CarTypes.Truck;
	|PageTrips show CarType = Enum.CarTypes.Truck and Object.CoefficientCar > 0.5;
	|LoadFactors enable ( filled ( Object.Trailer ) or CarType = Enum.CarTypes.Truck );
	|Links show ShowLinks
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew () 

	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	settings = Logins.Settings ( "Company" );
	Object.Company = settings.Company;

EndProcedure

&AtServer
Procedure setFuelExpenseMethod ()
	
	fuelSettings = getFuelSettings ();
	if ( fuelSettings = undefined ) then
		return;
	endif;
	Object.FuelExpenseMethod = getFuelMethod ( fuelSettings.Summer, fuelSettings.Winter );
	
EndProcedure

&AtServer
Function getFuelSettings () 

	s = "
	|select Settings.Value as Value, Settings.Parameter as Parameter
	|from InformationRegister.Settings.SliceLast ( &Date, Parameter in ( value ( ChartOfCharacteristicTypes.Settings.FuelSummerPeriod ),
	|		 value ( ChartOfCharacteristicTypes.Settings.FuelWinterPeriod ) ) ) as Settings
	|";
	q = new Query ( s );
	q.SetParameter ( "Date", Periods.GetBalanceDate ( Object ) );
	table = q.Execute ().Unload ();
	if ( table.Count () < 1 ) then
		return undefined;
	endif;
	summerPeriodSetting = ChartsOfCharacteristicTypes.Settings.FuelSummerPeriod;
	for each row in table do
		if ( row.Parameter = summerPeriodSetting ) then
			summer = makeDate ( row.Value );
		else
			winter = makeDate ( row.Value );
		endif;	
	enddo;
	return new Structure ( "Summer, Winter", summer, winter );

EndFunction

&AtServer
Function makeDate ( Date ) 

	return Date ( 1, Month ( Date ), Day ( Date ) );

EndFunction

&AtServer
Function getFuelMethod ( SummerBegin, WinterBegin ) 

	date = makeDate ( Object.Date );
	methods = Enums.FuelExpenseMethods;
	summer = methods.Summer;
	winter = methods.Winter;
	if ( WinterBegin > SummerBegin ) then
		if ( date >= SummerBegin
			and date < WinterBegin ) then
			return summer;
		else
			return winter;
		endif;
	else
		if ( date >= WinterBegin
			and date < SummerBegin ) then
			return winter;
		else
			return summer;
		endif;
	endif;

EndFunction

&AtServer
Procedure setCar ()
	
	getCarData ();
	fillByLastWaybill ();
	setCarType ();
	setFuel ();
	setTrailer ();
	setNormative ();
	calcTotalMileage ( Object );
	calcNorms ( ThisObject );
	calcMotoNorms ( ThisObject, Maximum );
	calcMotoNorms ( ThisObject, Average );
	calcMotoNorms ( ThisObject, Minimum );
	calcEquipmentNorms ( ThisObject );
		
EndProcedure 

&AtServer
Procedure getCarData ()
	
	SQL.Init ( Env );
	sqlLastWaybill ();
	sqlTrailer ();
	sqlFuel ();
	q = Env.Q;
	q.SetParameter ( "Car", Object.Car );
	q.SetParameter ( "Ref", Object.Ref );
	q.SetParameter ( "Date", EndOfDay ( Object.Date ) );
	q.SetParameter ( "Method", Object.FuelExpenseMethod );
	SQL.Perform ( Env );
	
EndProcedure 

&AtServer
Procedure sqlLastWaybill ()
	
	Env.Selection.Add ( getLastWaybill () );
	
EndProcedure

&AtServer
Function getLastWaybill () 

	s = "
	|// @LastWaybill
	|select top 1 Driver1 as Driver1, Waybill.OdometerEnd as OdometerStart, Waybill.WaybillType as WaybillType
	|from Document.Waybill as Waybill
	|where Waybill.Car = &Car
	|and Waybill.Date < &Date
	|and Waybill.Posted
	|";
	if ( not Object.Ref.IsEmpty () ) then
		s = s + "
		|	and Waybill.Ref <> &Ref
		|";
	endif; 
	s = s + "
	|order by Waybill.Date desc
	|";
	return s;

EndFunction

&AtServer
Procedure sqlTrailer ()
	
	s = "
	|// @Trailer
	|select Trailers.Trailer as Trailer
	|from Catalog.CarTypes.Trailers as Trailers
	|where Trailers.Ref in ( select CarType from Catalog.Cars where Ref = &Car )
	|and Trailers.LineNumber = 1
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServer
Procedure sqlFuel ()
	
	s = "
	|// @Fuel
	|select Cars.CarType.FuelMain as FuelMain, Cars.CarType.FuelHours as FuelHours, Cars.CarType.FuelEquipment as FuelEquipment,
	|	Cars.CarType.FuelOther as FuelOther
	|from Catalog.Cars as Cars
	|where Cars.Ref = &Car
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServer
Procedure fillByLastWaybill ()
	
	if ( Env.LastWayBill = undefined ) then
		return;
	endif; 
	FillPropertyValues ( Object, Env.LastWayBill );	
	
EndProcedure 

&AtServer
Procedure setFuel ()
	
	FillPropertyValues ( Object, Env.Fuel );
	
EndProcedure  

&AtServer
Procedure setTrailer ()
	
	if ( Env.Trailer = undefined ) then
		Object.Trailer = undefined;
	else
		Object.Trailer = Env.Trailer.Trailer;
	endif; 
	
EndProcedure 

&AtClientAtServerNoContext
Procedure calcTotalMileage ( Object )
	
	Object.TotalMileage = Object.OdometerEnd - Object.OdometerStart + Object.MileageWithoutOdometer;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure calcNorms ( Form )
	
	object = Form.Object;
	if ( object.TotalMileage < 0 ) then
		object.ExpenseOdometer = 0;
		return;
	endif;
	if ( Form.CarType = PredefinedValue ( "Enum.CarTypes.Bus" ) ) then
		calcNormsBus ( Form );
	elsif ( Form.CarType = PredefinedValue ( "Enum.CarTypes.TipTruck" ) ) then
		calcNormsTipTruck ( Form );
	else
		calcNormsOther ( Form );
	endif; 
	
EndProcedure

&AtClientAtServerNoContext
Procedure calcNormsBus ( Form )
	
	expenseOdometer = calcExpenseOdometer ( Form );
	coeffConsumption = calcCoefficientConsumption ( Form );
	expenseAdditionalEquipment = calcExpenseAdditionalEquipment ( Form );
	Form.Object.ExpenseOdometer = expenseOdometer * coeffConsumption + expenseAdditionalEquipment; 
	
EndProcedure

&AtClientAtServerNoContext
Function calcExpenseOdometer ( Form )
	
	return Form.NormOdometer * Form.Object.TotalMileage / 100;
	
EndFunction

&AtClientAtServerNoContext
Function calcCoefficientConsumption ( Form )
	
	return ( 1 + Form.Object.CoefficientConsumption / 100 ); 
	
EndFunction

&AtClientAtServerNoContext
Function calcExpenseAdditionalEquipment ( Form )
	
	return Form.NormAdditionalEquipment * Form.Object.AdditionalEquipmentsWork;
	
EndFunction 

&AtClientAtServerNoContext
Procedure calcNormsTipTruck ( Form )
	
	object = Form.Object;
	if ( object.CoefficientCar < 0.5 ) then
		object.ExpenseOdometer = 0.01 * ( Form.NormOdometer + Form.NormTransportWork * ( Form.TrailerWeight + 0.5 * Form.TrailerCarrying ) )
		* object.TotalMileage * ( 1 + object.CoefficientConsumption * 0.01 ) + object.QuantityTrips * Form.NormMovements;
	else
		object.ExpenseOdometer = 0;		
	endif; 
	
EndProcedure 

&AtClientAtServerNoContext
Procedure calcNormsOther ( Form )
	
	object = Form.Object;
	if ( object.TotalMileage < 0 ) then
		object.ExpenseOdometer = 0;
		return;
	endif; 
	factor = Form.NormOdometer;
	if ( object.MileageTrailerI = 0 ) 
		and ( object.MileageTrailerWithoutI = 0 ) then
		factorI = 0;	
		mileageTrailerI = 0;
	else
		factorTrailerI = getTrailerNorm ( object.Car, object.Trailer, PredefinedValue ( "Enum.FuelConsumptionCategory.I" ), object.FuelExpenseMethod );
		factorI = factorTrailerI * object.CoefficientTrailerI;
		mileageTrailerI = object.MileageTrailerI + object.MileageTrailerWithoutI; 
	endif;
	if ( object.MileageTrailerII = 0 ) 
		and ( object.MileageTrailerWithoutII = 0 ) then
		factorII = 0;
		mileageTrailerII = 0;
	else
		factorTrailerII = getTrailerNorm ( object.Car, object.Trailer, PredefinedValue ( "Enum.FuelConsumptionCategory.II" ), object.FuelExpenseMethod );
	    factorII = factorTrailerII * object.CoefficientTrailerII;
		mileageTrailerII = object.MileageTrailerII + object.MileageTrailerWithoutII; 
	endif;
	mileageTrailer = mileageTrailerI + mileageTrailerII;
	mileageCity = object.MileageCity;
	object.ExpenseOdometer = ( ( object.TotalMileage - mileageTrailer - mileageCity ) / 100 ) * factor
	+ ( ( mileageTrailerI ) / 100 ) * factorI + ( ( mileageTrailerII ) / 100 ) * factorII
	+ ( mileageCity / 100 ) * Form.NormOdometerCity;
	
EndProcedure

&AtServerNoContext
Function getTrailerNorm ( val Car, val Trailer, val Category, val Method )
	
	s = "
	|select case when &Method = value ( Enum.FuelExpenseMethods.Summer ) then Trailers.Summer else Trailers.Winter end as Norm
	|from Catalog.CarTypes.Trailers as Trailers
	|where Trailers.Ref in ( select CarType from Catalog.Cars where Ref = &Car )
	|and Trailers.Category = &Category
	|and Trailers.Trailer = &Trailer
	|";
	q = new Query ( s );
	q.SetParameter ( "Car", Car );
	q.SetParameter ( "Method", Method );
	q.SetParameter ( "Category", Category );
	q.SetParameter ( "Trailer", Trailer );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, 0, table [ 0 ].Norm );
	
EndFunction

&AtClientAtServerNoContext
Procedure calcMotoNorms ( Form, Factor )
	
	object = Form.Object;
	if ( Factor = Form.Maximum ) then
		object.ExpenseEngineMax = object.EngineHoursMax * Form.NormEngineMax;
	elsif ( Factor = Form.Average ) then
		object.ExpenseEngineAvg = object.EngineHoursAvg * Form.NormEngineAvg;
	elsif ( Factor = Form.Minimum ) then
		object.ExpenseEngineMin = object.EngineHoursMin * Form.NormEngineMin;
	endif; 
	setTotalsByHours ( Form );
	
EndProcedure 

&AtClientAtServerNoContext
Procedure calcEquipmentNorms ( Form )
	
	object = Form.Object;
	object.ExpenseEquipment = object.EquipmentWorkTime * Form.NormEquipment;
	
EndProcedure 

&AtServer
Procedure setLinks ()
	
	SQL.Init ( Env );
	sqlLinks ();
	if ( Env.Selection.Count () = 0 ) then
		ShowLinks = false;
	else
		Env.Q.SetParameter ( "Ref", Object.Ref );
		SQL.Perform ( Env );
		setURLPanel ();
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	if ( Object.Ref.IsEmpty () ) then
		return;
	endif; 
	ViewWriteOff = AccessRight ( "View", Metadata.Documents.WriteOff );
	if ( ViewWriteOff ) then
		s = "
		|// #WriteOff
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.WriteOff as Documents
		|where Documents.Base = &Ref
		|and Documents.Posted
		|and not Documents.DeletionMark
		|";
		Env.Selection.Add ( s );
	endif; 
	
EndProcedure 

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	if ( not Object.Ref.IsEmpty () ) then
		if ( ViewWriteOff ) then
			parts.Add ( URLPanel.DocumentsToURL ( Env.WriteOff, Metadata.Documents.WriteOff ) );
		endif; 
	endif; 
	s = URLPanel.Build ( parts );
	if ( s = undefined ) then
		ShowLinks = false;
	else
		ShowLinks = true;
		Links = s;
	endif; 
	
EndProcedure 

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	Object.Verso.Sort ( "DateStart" );
	calcWorkTime ();

EndProcedure

&AtClient
Procedure calcWorkTime ()

	Object.WorkTime = 0;
	lunchStart = 12 * 60 * 60 + 30 * 60;
	lunchEnd = 13 * 60 * 60 + 30 * 60;
	absenteeism = PredefinedValue ( "Enum.CarWorkTypes.Absenteeism" );
	for each row in Object.Verso do
		dateStart = BegOfMinute ( row.DateStart );
		row.DateStart = dateStart;
		dateEnd = BegOfMinute ( row.DateEnd );
		row.DateEnd = dateEnd;
		row.WorkTime = Int ( ( dateEnd - dateStart ) / 60 );
		timeStart = Hour ( dateStart ) * 60 * 60 + ( 60 * Minute ( dateStart ) );
		timeEnd = Hour ( dateEnd ) * 60 * 60 + ( 60 * Minute ( dateEnd ) );
		workLunchStart = Max ( lunchStart, timeStart );
		workLunchEnd = Min ( lunchEnd, timeEnd );
		if ( not ( workLunchStart > lunchEnd 
			or workLunchEnd < lunchStart ) ) then
			row.WorkTime = row.WorkTime - Int ( ( workLunchEnd - workLunchStart ) / 60 );
		endif; 
		if ( row.Work <> absenteeism ) then
			Object.WorkTime = Object.WorkTime + row.WorkTime;
		endif; 
	enddo; 
	
EndProcedure 

// *****************************************
// *********** Form

&AtClient
Procedure DateOpeningOnChange ( Item )
	
	if ( Object.Car.IsEmpty () ) then
		return;
	endif; 
	setLastWaybill ();
	
EndProcedure

&AtServer
Procedure setLastWaybill ()
	
	q = new Query ();
	q.Text = getLastWaybill ();
	q.SetParameter ( "Car", Object.Car );
	q.SetParameter ( "Ref", Object.Ref );
	q.SetParameter ( "Date", EndOfDay ( Object.Date ) );
	table = q.Execute ().Unload ();
	if ( table.Count () = 0 ) then
		return;
	endif; 
	FillPropertyValues ( Object, table [ 0 ] );
	
EndProcedure 

&AtClient
Procedure DateOnChange ( Item )
	
	setFuelExpenseMethod ();
	
EndProcedure

&AtClient
Procedure CarOnChange ( Item )
	
	applyCar ();
	
EndProcedure

&AtServer
Procedure applyCar ()
	
	setCar ();
	Appearance.Apply ( ThisObject, "Object.Trailer" );
	Appearance.Apply ( ThisObject, "CarType" );
	Appearance.Apply ( ThisObject, "NormEquipment" );
	Appearance.Apply ( ThisObject, "NormEngineAvg" );
	Appearance.Apply ( ThisObject, "NormEngineMin" );
	Appearance.Apply ( ThisObject, "NormEngineMax" );

EndProcedure 

&AtClient
Procedure TrailerOnChange ( Item )
	
	applyTrailer ();
	
EndProcedure

&AtServer
Procedure applyTrailer ()
	
	fillDataTrailer ();
	calcNorms ( ThisObject );
	Appearance.Apply ( ThisObject, "Object.Trailer" );
	
EndProcedure

&AtServer
Procedure fillDataTrailer ()
	
	if ( ValueIsFilled ( Object.Trailer ) ) then
		s = "
		|select CarTypes.Carrying as TrailerCarrying,
		|	CarTypes.Weight as TrailerWeight
		|from Catalog.CarTypes as CarTypes
		|where CarTypes.Ref = &CarType
		|";
		q = new Query ( s );
		q.SetParameter ( "CarType", Object.Trailer );
		result = q.Execute ();
		selection = result.Select ();
		selection.Next ();
		TrailerWeight = selection.TrailerWeight;
		TrailerCarrying = selection.TrailerCarrying;
	else
		TrailerWeight = 0;
		TrailerCarrying = 0;		 
	endif; 
	
EndProcedure 

&AtClient
Procedure OdometerStartOnChange ( Item )
	
	calcTotalMileage ( Object );
	calcNorms ( ThisObject );
	markVersoErrors ( ThisObject );
	
EndProcedure

&AtClient
Procedure CoefficientCarOnChange ( Item )
	
	calcNorms ( ThisObject );
	markVersoErrors ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtClient
Procedure EngineHoursMaxOnChange ( Item )
	
	calcMotoNorms ( ThisForm, Maximum );
	markVersoErrors ( ThisObject );
	
EndProcedure

&AtClient
Procedure EngineHoursAvgOnChange ( Item )
	
	calcMotoNorms ( ThisForm, Average );
	markVersoErrors ( ThisObject );
	
EndProcedure

&AtClient
Procedure EngineHoursMinOnChange ( Item )
	
	calcMotoNorms ( ThisForm, Minimum );
	markVersoErrors ( ThisObject );
	
EndProcedure

&AtClient
Procedure EquipmentWorkTimeOnChange ( Item )
	
	calcEquipmentNorms ( ThisForm );
	markVersoErrors ( ThisObject );
		
EndProcedure

&AtClient
Procedure MileageCityOnChange ( Item )
	
	calcNorms ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Table FuelBalances

&AtClient
Procedure FuelInventoryOnChange ( Item )
	
	fillFuelBalances ();
	
EndProcedure

&AtServer
Procedure fillFuelBalances ()
	
	if ( Object.FuelInventory ) then
		row = Object.FuelBalances.Add ();
		capacity = DF.Values ( Object.Car, "CarType.TankCapacity, CarType.TankCapacityAdditional" );
		row.Quantity = capacity.CarTypeTankCapacity;
		if ( not Object.FuelMain.IsEmpty () ) then
			row.Fuel = Object.FuelMain;
		elsif ( not Object.FuelHours.IsEmpty () ) then
			row.Fuel = Object.FuelHours;
		endif;
		if ( not Object.FuelEquipment.IsEmpty () ) then
			if ( Object.FuelEquipment <> row.Fuel ) then
				row = Object.FuelBalances.Add ();
				row.Fuel = Object.FuelEquipment;
			endif; 
			row.Quantity = row.Quantity + capacity.CarTypeTankCapacityAdditional;
		endif; 
	else
		Object.FuelBalances.Clear ();
	endif; 
	Appearance.Apply ( ThisObject, "Object.FuelInventory" );
	
EndProcedure 

&AtClient
Procedure FuelBalancesBeforeAddRow ( Item, Cancel, Clone, Parent, Folder )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure FuelBalancesBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

// *****************************************
// *********** Table Verso

&AtClient
Procedure VersoDateStartOnChange ( Item )
	
	currentData = Items.Verso.CurrentData;
	setPeriod ( currentData );
	
EndProcedure

&AtClient
Procedure setPeriod ( TableRow )
	
	dateStart = BegOfDay ( TableRow.DateStart );
	dateEnd = BegOfDay ( TableRow.DateEnd );
	if ( dateStart <> dateEnd ) then
		TableRow.DateStart = dateStart + At7h;
		TableRow.DateEnd = dateStart + ( TableRow.DateEnd - dateEnd );
	endif; 
	
EndProcedure 

&AtClient
Procedure VersoCustomerOnChange ( Item )
	
	applyCustomer ()
	
EndProcedure

&AtClient
Procedure applyCustomer ()
	
	currentData = Items.Verso.CurrentData;
	if ( currentData = undefined ) then
		return;
	endif; 
	Items.VersoCustomerDivision.ReadOnly = TypeOf ( currentData.Customer ) <> Type ( "CatalogRef.Organizations" );
	
EndProcedure 

&AtClient
Procedure VersoOdometerStartOnChange ( Item )
	
	applyVersoOdometerStart ();
	markVersoErrors ( ThisObject );
	
EndProcedure

&AtClient
Procedure applyVersoOdometerStart ()
	
	row = Items.Verso.CurrentData;
	mileage = row.Mileage;
	odometerStart = row.OdometerStart;
	odometerEnd = row.OdometerEnd;
	if ( odometerStart >= 0 ) and ( odometerEnd > 0 ) then
		mileage = ? ( ( odometerEnd - odometerStart ) < 0, 0, ( odometerEnd - odometerStart ) );
	elsif ( odometerStart >= 0 ) and ( mileage > 0 ) then 
		odometerEnd = odometerStart + mileage; 
	endif;
	row.Mileage = mileage;
	row.OdometerStart = odometerStart;
	row.OdometerEnd = odometerEnd;
		
EndProcedure

&AtClient
Procedure VersoOdometerEndOnChange ( Item )
	
	applyVersoOdometerEnd ();
	markVersoErrors ( ThisObject );
	
EndProcedure

&AtClient
Procedure applyVersoOdometerEnd ()
	
	row = Items.Verso.CurrentData;
	mileage = row.Mileage;
	odometerStart = row.OdometerStart;
	odometerEnd = row.OdometerEnd;
	if ( odometerEnd > 0 ) and ( odometerStart >= 0 ) then
		mileage = ? ( ( odometerEnd - odometerStart ) < 0, 0, ( odometerEnd - odometerStart ) );
	elsif ( odometerEnd > 0 ) and ( mileage > 0 ) then 
		odometerStart = odometerEnd - mileage; 
	endif;
	row.Mileage = mileage;
	row.OdometerStart = odometerStart;
	row.OdometerEnd = odometerEnd;
		
EndProcedure

&AtClient
Procedure VersoMileageOnChange ( Item )
	
	applyVersoMileage ();
	markVersoErrors ( ThisObject );
	
EndProcedure

&AtClient
Procedure applyVersoMileage ()
	
	row = Items.Verso.CurrentData;
	mileage = row.Mileage;
	odometerStart = row.OdometerStart;
	odometerEnd = row.OdometerEnd;
	if ( mileage > 0 ) then
		if ( odometerStart > 0 ) then
			odometerEnd = odometerStart + mileage;
		elsif ( odometerStart = 0 ) and ( odometerEnd > 0 ) then
			odometerStart = odometerEnd - mileage;
		endif;
	endif;
	row.Mileage = mileage;
	row.OdometerStart = odometerStart;
	row.OdometerEnd = odometerEnd;
		
EndProcedure

&AtClient
Procedure VersoEngineHoursOnChange ( Item )
	
	markVersoErrors ( ThisObject );
	
EndProcedure

&AtClient
Procedure VersoOnActivateRow ( Item )
	
	applyCustomer ();
	
EndProcedure

&AtClient
Procedure VersoOnStartEdit ( Item, NewRow, Clone )
	
	if ( NewRow ) then
		currentData = Items.Verso.CurrentData;
		setPeriodDefault ( currentData );
	endif; 

EndProcedure

&AtClient
Procedure setPeriodDefault ( TableRow )
	
	verso = Object.Verso;
	index = verso.IndexOf ( TableRow );
	if ( index = 0 ) then
		day = BegOfDay ( Object.DateOpening );
		TableRow.DateStart = day + At7h;
		TableRow.DateEnd = day + At19h;
		TableRow.OdometerStart = Object.OdometerStart;
	else
		topRow = verso [ index - 1 ];
		dateStart = topRow.DateEnd;
		TableRow.DateStart = dateStart;
		dateEnd = BegOfDay ( dateStart ) + At19h;
		if ( dateStart <= dateEnd ) then
			TableRow.DateEnd = dateEnd;			
		endif;
		if ( topRow.OdometerEnd > 0 ) then
			TableRow.OdometerStart = topRow.OdometerEnd;
		endif;
	endif; 
	
EndProcedure 

&AtClient
Procedure VersoOnEditEnd ( Item, NewRow, CancelEdit )
	
	markVersoErrors ( ThisObject );
	
EndProcedure

&AtClient
Procedure VersoAfterDeleteRow ( Item )
	
	markVersoErrors ( ThisObject );
	
EndProcedure

&AtClient
Procedure VersoBeforeEditEnd ( Item, NewRow, CancelEdit, Cancel )
	
	if ( CancelEdit ) then
		return;
	endif; 
	currentData = Items.Verso.CurrentData;
	splitPeriod ( currentData );
	
EndProcedure

&AtClient
Procedure splitPeriod ( TableRow )
	
	if ( TableRow.DateEnd > TableRow.DateStart ) then
		return;
	endif;
	Output.WorkTimeOnTwoDays ( ThisObject, TableRow );
	
EndProcedure 

&AtClient
Procedure WorkTimeOnTwoDays ( Answer, TableRow ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	verso = Object.Verso;
	index = verso.IndexOf ( TableRow );
	nextRow = verso.Insert ( index + 1 );
	FillPropertyValues ( nextRow, TableRow );
	dateStart = TableRow.DateStart;
	nextRow.DateStart = BegOfDay ( dateStart + 86400 );
	nextRow.DateEnd = TableRow.DateEnd + 86400;
	TableRow.DateEnd = EndOfDay ( dateStart );
	
EndProcedure 

// *****************************************
// *********** Page More

&AtClient
Procedure FuelExpenseMethodOnChange ( Item )
	
	applyNewMethod ();
	
EndProcedure

&AtServer
Procedure applyNewMethod ()
	
	if ( Object.Car.IsEmpty ()
		or Object.FuelExpenseMethod.IsEmpty () ) then
		return;
	endif; 
	setNormative ();
	calcNorms ( ThisObject );
	calcMotoNorms ( ThisObject, Maximum );
	calcMotoNorms ( ThisObject, Average );
	calcMotoNorms ( ThisObject, Minimum );
	calcEquipmentNorms ( ThisObject );
	Appearance.Apply ( ThisObject, "NormEquipment" );
	Appearance.Apply ( ThisObject, "NormEngineAvg" );
	Appearance.Apply ( ThisObject, "NormEngineMin" );
	Appearance.Apply ( ThisObject, "NormEngineMax" );
	
EndProcedure 

&AtClient
Procedure AdditionalEquipmentsWorkOnChange ( Item )
	
	calcNorms ( ThisObject );
	
EndProcedure

&AtClient
Procedure CoefficientConsumptionOnChange ( Item )
	
	calcNorms ( ThisObject );
	
EndProcedure

&AtClient
Procedure TripsTrailerOnChange ( Item )
	
	data = Items.Trips.CurrentData;
	if ( ValueIsFilled ( data.Trailer ) ) then
		data.TrailerWeight = DF.Pick ( data.Trailer, "Weight" );
		calcRow ();
	endif; 
	
EndProcedure

&AtClient
Procedure TripsOdometerStartOnChange ( Item )
	
	calcTripMileage ();
	calcTotalTripMileage ();
	calcRow ();	
	
EndProcedure

&AtClient
Procedure calcTripMileage ()
	
	row = Items.Trips.CurrentData;
	row.Mileage = row.OdometerEnd - row.OdometerStart;
	if ( row.MileageCargo = 0 ) then
		row.MileageCargo = row.Mileage;
	endif; 
	
EndProcedure

&AtClient
Procedure calcTotalTripMileage ()
	
	Object.TotalMileage = Object.Trips.Total ( "Mileage" );
	
EndProcedure 

&AtClient
Procedure TripsSpeedometerEndOnChange ( Item )
	
	calcTripMileage ();
	calcTotalTripMileage ();
	calcRow ();
	
EndProcedure

&AtClient 
Procedure TripsMileageOnChange ( Item )
	
	calcTotalTripMileage ();
	calcRow ();
	
EndProcedure

&AtClient
Procedure calcRow ()
	
	calcNormTrip ();
	
EndProcedure

&AtClient
Procedure calcNormTrip ()
	
	row = Items.Trips.CurrentData;
	weightForCalc = 0;
	if ( CarType = PredefinedValue ( "Enum.CarTypes.TipTruck" ) and Object.CoefficientCar > 0.5 ) then
		weightForCalc = row.TrailerWeight + CarWeight;
	elsif ( CarType = PredefinedValue ( "Enum.CarTypes.Truck" ) ) then
		weightForCalc = row.TrailerWeight;
	else
		return;
	endif;
	row.ExpenseOdometer = 0.01 * ( ( NormOdometer + NormTrailer * weightForCalc ) * row.Mileage + NormTransportWork * row.Weight * row.MileageCargo ) 
		* ( 1 + 0.01 * row.CoefficientConsumption ) + NormEquipment * row.EquipmentWorkTime + NormAdditionalEquipment * row.AdditionalEquipmentsWork;
	Object.ExpenseOdometer = Object.Trips.Total ( "ExpenseOdometer" );
	
EndProcedure 

&AtClient
Procedure TripsMileageCargoOnChange ( Item )
	
	calcRow ();	
	
EndProcedure

&AtClient
Procedure TripsWeightOnChange ( Item )
	
	calcRow ();
	
EndProcedure

&AtClient
Procedure TripsCoefficientConsumptionOnChange ( Item )
	
	calcRow ();
	
EndProcedure

&AtClient
Procedure TripsEquipmentWorkTimeOnChange ( Item )
	
	calcRow ();
	
EndProcedure

&AtClient
Procedure TripsAdditionalEquipmentsWorkOnChange ( Item )
	
	calcRow ();	
	
EndProcedure

&AtClient
Procedure TripsOnStartEdit ( Item, NewRow, Clone )
	
	if ( NewRow ) then
		data = Items.Trips.CurrentData;
		countRows = Object.Trips.Count ();
		if ( countRows = 1 ) then
			odometerStart = Object.OdometerStart;
		else
			odometerStart = Object.Trips [ ( countRows - 2 ) ].OdometerEnd;	
		endif;
		data.OdometerStart = odometerStart;
		if ( ValueIsFilled ( Object.Trailer ) ) then
			data.Trailer = Object.Trailer;
			data.TrailerWeight = DF.Pick ( data.Trailer, "Weight" );
		endif; 
		if ( Clone ) then
			data.OdometerEnd = 0;
			data.Mileage = 0;
			data.MileageCargo = 0;
			data.ExpenseOdometer = 0;
		endif; 
	endif; 
	
EndProcedure

&AtClient
Procedure QuantityTripsOnChange ( Item )
	
	calcNorms ( ThisObject );
	markVersoErrors ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Variables Initialization

At7h = 25200;
At19h = 68400;
Maximum = "Max";
Minimum = "Min";
Average = "Avg";