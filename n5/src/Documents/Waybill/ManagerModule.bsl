#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.Waybill.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	makeFuelToExpense ( Env );
	makeWaybillWorksByWorkTypes ( Env );
	makeWaybillWorks ( Env );
	if ( Env.Fields.FuelInventory ) then
		makeFuelInventory ( Env );
	endif; 
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )

	sqlFields ( Env );
	getFields ( Env );
	sqlFuelToExpense ( Env );
	sqlVerso ( Env );
	sqlFuelBalances ( Env );
	sqlFuelInventory ( Env );
	getTables ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Document.Date as Date, Document.DateOpening as DateOpening, Document.Car as Car, Document.FuelInventory as FuelInventory,
	|	Document.PointInTime as Timestamp, Document.Driver1 as Driver1, Document.WaybillType as WaybillType, Document.Car.Warehouse as Warehouse
	|from Document.Waybill as Document
	|where Document.Ref = &Ref
	|";
	Env.Selection.Add ( s );	
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlFuelToExpense ( Env )
	
	s = "
	|select FuelData.Fuel as Fuel, sum ( FuelData.Quantity ) as Quantity
	|into FuelToExpense
	|from (
	|	select Document.FuelMain as Fuel, Document.ExpenseOdometer as Quantity
	|	from Document.Waybill as Document
	|	where Document.Ref = &Ref
	|	union all
	|	select Document.FuelEquipment, Document.ExpenseEquipment
	|	from Document.Waybill as Document
	|	where Document.Ref = &Ref
	|	union all
	|	select Document.FuelOther, Document.OtherFuelExpense
	|	from Document.Waybill as Document
	|	where Document.Ref = &Ref
	|	union all
	|	select Document.FuelHours, ( Document.ExpenseEngineMax + Document.ExpenseEngineAvg + Document.ExpenseEngineMin )
	|	from Document.Waybill as Document
	|	where Document.Ref = &Ref ) as FuelData
	|group by FuelData.Fuel
	|having sum ( FuelData.Quantity ) > 0
	|;
	|// #FuelToExpense
	|select FuelToExpense.Fuel as Fuel, FuelToExpense.Quantity as Quantity
	|from FuelToExpense as FuelToExpense
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlVerso ( Env )
	
	s = "
	|select Verso.Customer as Customer, Verso.CustomerDivision as CustomerDivision, Verso.Work as Work, beginofperiod ( Verso.DateStart, day ) as DateStart,
	|	sum ( Verso.EngineHours ) as EngineHours, sum ( Verso.WorkTime ) as WorkTime, sum ( Verso.Mileage ) as Mileage
	|into Verso
	|from Document.Waybill.Verso as Verso
	|where Verso.Ref = &Ref
	|group by Verso.Customer, Verso.CustomerDivision, Verso.Work, beginofperiod ( Verso.DateStart, day )
	|;
	|// #Verso
	|select Verso.Customer as Customer, Verso.CustomerDivision as CustomerDivision, Verso.DateStart as DateStart, Verso.Work as Work,
	|	Verso.EngineHours as EngineHours, Verso.WorkTime as WorkTime, Verso.Mileage as Mileage
	|from Verso as Verso
	|;
	|// #WorkTime
	|select Verso.DateStart as DateStart, sum ( Verso.WorkTime ) as WorkTime
	|from Verso as Verso
	|where Verso.Work <> value ( Enum.CarWorkTypes.Absenteeism )
	|group by Verso.DateStart
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlFuelBalances ( Env )
	
	s = "
	|// #FuelBalances
	|select FuelBalances.Fuel as Fuel, FuelBalances.Quantity as Quantity
	|from Document.Waybill.FuelBalances as FuelBalances
	|where FuelBalances.Ref = &Ref
	|";
	Env.Selection.Add ( s );	
	
EndProcedure

Procedure sqlFuelInventory ( Env )
	
	s = "
	|select FuelBalances.Fuel as Fuel, &Warehouse as Warehouse
	|into FuelBalances
	|from Document.Waybill.FuelBalances as FuelBalances
	|where FuelBalances.Ref = &Ref
	|index by Fuel, Warehouse
	|;
	|// #FuelInventory
	|select Items.Fuel as Fuel, sum ( Items.Quantity ) as QuantityExtraExpense, sum ( Items.QuantityToExpenseBalance ) as QuantityToExpenseBalance
	|from ( select GoodsBalances.Item as Fuel, sum ( GoodsBalances.QuantityBalance ) as Quantity, 0 as QuantityToExpenseBalance
	|		from AccumulationRegister.Items.Balance ( &Timestamp, ( Warehouse, Item ) in ( select Warehouse, Fuel from FuelBalances ) ) as GoodsBalances
	|		group by GoodsBalances.Item
	|		union all
	|		select FuelToExpense.Fuel, - FuelToExpense.QuantityBalance, - FuelToExpense.QuantityBalance
	|		from AccumulationRegister.FuelToExpense.Balance ( &Timestamp, Car = &Car ) as FuelToExpense
	|		union all
	|		select FuelToExpense.Fuel, - FuelToExpense.Quantity, - FuelToExpense.Quantity
	|		from FuelToExpense as FuelToExpense
	|		union all
	|		select FuelBalances.Fuel, - FuelBalances.Quantity, 0
	|		from Document.Waybill.FuelBalances as FuelBalances
	|		where FuelBalances.Ref = &Ref ) as Items
	|group by Items.Fuel
	|having sum ( Items.Quantity ) <> 0
	|";
	Env.Selection.Add ( s );	
	
EndProcedure

Procedure getTables ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	Env.Q.SetParameter ( "Car", Env.Fields.Car );
	Env.Q.SetParameter ( "Warehouse", Env.Fields.Warehouse );
	Env.Q.SetParameter ( "Timestamp", Env.Fields.Timestamp );
	SQL.Perform ( Env );
	
EndProcedure

Procedure makeFuelToExpense ( Env )

	table = Env.FuelToExpense;
	recordset = Env.Registers.FuelToExpense;
	for each row in table do
		movement = recordset.AddReceipt ();
		movement.Period = Env.Fields.Date;
		movement.Fuel = row.Fuel;
		movement.Car = Env.Fields.Car;
		movement.Quantity = row.Quantity;
	enddo; 
	
EndProcedure

Procedure makeWaybillWorksByWorkTypes ( Env )

	recordset = Env.Registers.WaybillWorksByWorkTypes;
	table = Env.Verso;
	for each row in table do
		movement = recordset.Add ();
		movement.Period = Env.Fields.Date;
		movement.WorkDay = row.DateStart;
		movement.Car = Env.Fields.Car;
		movement.Customer = row.Customer;
		movement.CustomerDivision = row.CustomerDivision;
		movement.Work = row.Work;
		movement.WorkTime = row.WorkTime;
		movement.Mileage = row.Mileage;
		movement.MotorHours = row.EngineHours;
	enddo; 

EndProcedure 

Procedure makeWaybillWorks ( Env )

	table = Env.WorkTime;
	lastIndex = table.Count () - 1;
	if ( lastIndex = -1 ) then
		return;
	endif; 
	recordset = Env.Registers.WaybillWorks;
	start = BegOfDay ( Env.Fields.DateOpening );
	end = table [ lastIndex ].DateStart;
	while ( start <= end ) do
		row = table.Find ( start, "DateStart" );
		if ( row = Undefined ) then
			row = new Structure ( "DateStart, WorkTime", start, 0 );
		endif;
		movement = recordset.Add ();
		movement.Period = Env.Fields.Date;
		movement.WorkDay = row.DateStart;
		movement.Car = Env.Fields.Car;
		movement.Fact = row.WorkTime;
		if ( Env.Fields.WaybillType = Enums.WaybillTypes._11 ) then
			movement.Norm = 11 * 60;
		elsif ( Env.Fields.WaybillType = Enums.WaybillTypes._22 ) then
			movement.Norm = 22 * 60;
		endif; 
		start = start + 86400;
	enddo; 

EndProcedure 

Procedure makeFuelInventory ( Env )
	
	recordsetFuelToExpense = Env.Registers.FuelToExpense;
	recordsetFuelExcess = Env.Registers.FuelExcess;
	recordsetFuelExcessTurnovers = Env.Registers.FuelExcessTurnovers;
	recordsetFuelExcess.Clear ();
	recordsetFuelExcessTurnovers.Clear ();
	table = Env.FuelInventory;
	for each row in table do
		if ( row.QuantityExtraExpense > 0 ) then
			movement = recordsetFuelExcess.Add ();
			movement.Period = Env.Fields.Date;
			movement.Fuel = row.Fuel;
			movement.Driver = Env.Fields.Driver1;
			movement.Car = Env.Fields.Car;
			movement.Quantity = row.QuantityExtraExpense;
			movement = recordsetFuelExcessTurnovers.Add ();
			movement.Period = Env.Fields.Date;
			movement.Fuel = row.Fuel;
			movement.Driver = Env.Fields.Driver1;
			movement.Car = Env.Fields.Car;
			movement.Excess = row.QuantityExtraExpense;
		else
			movement = recordsetFuelToExpense.AddReceipt ();
			movement.Period = Env.Fields.Date;
			movement.Fuel = row.Fuel;
			movement.Car = Env.Fields.Car;
			movement.Quantity = row.QuantityExtraExpense;
			movement = recordsetFuelExcessTurnovers.Add ();
			movement.Period = Env.Fields.Date;
			movement.Fuel = row.Fuel;
			movement.Driver = Env.Fields.Driver1;
			movement.Car = Env.Fields.Car;
			movement.Economy = - row.QuantityExtraExpense;
		endif; 
	enddo; 
	
EndProcedure 

Procedure flagRegisters ( Env )
	
	registers = Env.Registers; 
	registers.FuelToExpense.Write = true;
	registers.FuelExcess.Write = true;
	registers.FuelExcessTurnovers.Write = true;
	registers.WaybillWorks.Write = true;
	registers.WaybillWorksByWorkTypes.Write = true;
	
EndProcedure

#endregion

#region Printing

Function Print ( Params, Env ) export
	
	setPageSettings ( Params );	
	getPrintData ( Params, Env );
	put ( Params, Env );
	return true;
	
EndFunction

Procedure setPageSettings ( Params )
	
	Params.TabDoc.FitToPage = true;
	Params.TabDoc.PageOrientation = ? ( Params.Template = "WaybillCar", PageOrientation.Portrait, PageOrientation.Landscape );
	
EndProcedure

Procedure getPrintData ( Params, Env )
	
 	sqlPrintData ( Env );
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure sqlPrintData ( Env )
	
	s = "
	|// @Fields
	|select Waybill.Car.CarType as CarType, Waybill.Car.CarNumber as CarNumber, Waybill.Car.GarageNumber as GarageNumber,
	|	Waybill.Driver1.LastName + "" "" + Waybill.Driver1.FirstName as Driver1Name, Waybill.Driver1.Code as Driver1Code, Waybill.DateOpening as DateOpening,
	|	presentation ( Waybill.Company ) as Company, Waybill.Company.CodeFiscal as CodeFiscal, Waybill.Date as Date, Waybill.WaybillNumber as WaybillNumber, 
	|	Waybill.WaybillSeries as WaybillSeries
	|from Document.Waybill as Waybill
	|where Waybill.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure put ( Params, Env )
	
	area = Env.T.GetArea ();
	area.Parameters.Fill ( Env.Fields );
	Params.TabDoc.Put ( area );
	
EndProcedure 

#endregion

#endif