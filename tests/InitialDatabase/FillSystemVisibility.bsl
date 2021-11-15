// ***************************************************
// Create two records: for invisibility and visibility
// ***************************************************

Commando ( "e1cib/data/InformationRegister.SystemVisibility" );
With ( "System's Visibility (cr*" );
Click ( "#FormWriteAndClose" );

Commando ( "e1cib/data/InformationRegister.SystemVisibility" );
With ( "System's Visibility (cr*" );
Click ( "#Parameter" );
Click ( "#Value" );
Click ( "#FormWriteAndClose" );

// ***************************************************
// Standard buttons
// ***************************************************

Commando("e1cib/data/InformationRegister.StandardButtons");
With();
Click("#FormWriteAndClose");

Commando("e1cib/data/InformationRegister.StandardButtons");
With();
Put ("#Button", 1);
Click("#PostAndNew");
Click("#FormWriteAndClose");

Commando("e1cib/data/InformationRegister.StandardButtons");
With();
Put ("#Button", 2);
Click("#SaveAndNew");
Click("#FormWriteAndClose");

Commando("e1cib/data/InformationRegister.StandardButtons");
With();
Put ("#Button", 3);
Click("#PostAndNew");
Click("#SaveAndNew");
Click("#FormWriteAndClose");
