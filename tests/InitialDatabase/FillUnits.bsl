// - Create general units list

CloseAll ();

list = new Array ();
list.Add ( new Structure ( "Code, Name", "м", "Метр" ) );
list.Add ( new Structure ( "Code, Name", "га", "Гектар" ) );
list.Add ( new Structure ( "Code, Name", "л", "Литр" ) );
list.Add ( new Structure ( "Code, Name", "м3", "Кубический метр" ) );
list.Add ( new Structure ( "Code, Name", "мг", "Миллиграмм" ) );
list.Add ( new Structure ( "Code, Name", "г", "Грамм" ) );
list.Add ( new Structure ( "Code, Name", "кг", "Килограмм" ) );
list.Add ( new Structure ( "Code, Name", "т", "Тонна" ) );
list.Add ( new Structure ( "Code, Name", "Вт", "Ватт" ) );
list.Add ( new Structure ( "Code, Name", "кВт", "Киловатт" ) );
list.Add ( new Structure ( "Code, Name", "ч", "Час" ) );
list.Add ( new Structure ( "Code, Name", "л.", "Лист" ) );
list.Add ( new Structure ( "Code, Name", "набор", "Набор" ) );
list.Add ( new Structure ( "Code, Name", "пар", "Пара" ) );
list.Add ( new Structure ( "Code, Name", "упак", "Упаковка" ) );
list.Add ( new Structure ( "Code, Name", "шт", "Штука" ) );
list.Add ( new Structure ( "Code, Name", "пог. м", "Погонный метр" ) );
list.Add ( new Structure ( "Code, Name", "ед", "Единица" ) );
list.Add ( new Structure ( "Code, Name", "мест", "Место" ) );
list.Add ( new Structure ( "Code, Name", "яч", "Ячейка" ) );
list.Add ( new Structure ( "Code, Name", "ящ", "Ящик" ) );
list.Add ( new Structure ( "Code, Name", "компл", "Комплект" ) );
list.Add ( new Structure ( "Code, Name", "бут", "Бутылка" ) );
list.Add ( new Structure ( "Code, Name", "флак", "Флакон" ) );
list.Add ( new Structure ( "Code, Name", "ампул", "Ампула" ) );

Commando ( "e1cib/list/Catalog.Units" );
for each item in list do

	With ( "Units" );
	Click ( "#FormCreate" );
	With ( "Units (cr*" );
	Set ( "#Code", item.Code );
	Set ( "#Description", item.Name );
	Click ( "#FormWriteAndClose" );

enddo;

