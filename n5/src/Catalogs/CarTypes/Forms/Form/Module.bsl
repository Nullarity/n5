// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|OdometerSummerCity OdometerWinterCity show inlist ( Object.Type, Enum.CarTypes.PassengerCar, Enum.CarTypes.Rent )
	|;
	|PageTrailers show Object.Type = Enum.CarTypes.Truck
	|;
	|GroupOdometer show inlist ( Object.Type, Enum.CarTypes.Bus, Enum.CarTypes.Heavy, Enum.CarTypes.PassengerCar, Enum.CarTypes.Rent, Enum.CarTypes.Special, Enum.CarTypes.Truck )
	|;
	|GroupEngineHours show inlist ( Object.Type, Enum.CarTypes.Heavy, Enum.CarTypes.Special )
	|;
	|GroupEquipment show inlist ( Object.Type, Enum.CarTypes.Heavy, Enum.CarTypes.Special, Enum.CarTypes.Truck )
	|;
	|GroupOther show inlist ( Object.Type, Enum.CarTypes.Bus, Enum.CarTypes.Heavy, Enum.CarTypes.PassengerCar, Enum.CarTypes.Rent, Enum.CarTypes.Special, Enum.CarTypes.Truck )
	|;
	|GroupAdditionalEquipments show inlist ( Object.Type, Enum.CarTypes.Bus, Enum.CarTypes.Heavy, Enum.CarTypes.PassengerCar, Enum.CarTypes.Rent, Enum.CarTypes.Special, Enum.CarTypes.Truck )
	|;
	|GroupTrailer show Object.Type = Enum.CarTypes.Truck
	|;
	|GroupTransportWork GroupTransportMovements show inlist ( Object.Type, Enum.CarTypes.Truck )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure CarTypeOnChange ( Item )
	
	applyCarType ();
	
EndProcedure

&AtServer
Procedure applyCarType ()
	
	type = Object.Type;
	carTypes = Enums.CarTypes;
	if ( type <> carTypes.PassengerCar
		and type <> carTypes.Rent ) then
		Object.OdometerSummerCity = 0;
		Object.OdometerWinterCity = 0;
	endif; 
	Appearance.Apply ( ThisObject, "Object.Type" );
	
EndProcedure 