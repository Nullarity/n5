﻿Справочник договоров, сделок, соглашений. Ключевой справочник в подсистеме учета взаиморасчетов. Используется для детализации и задания правил расчетов с контрагентами. В программе Nullarity 5, учет взаиморасчетов с контрагентами организован на базе регистров оперативного учета, отражение операций по которым, симметрично и автоматически выполняется в бухгалтерском учете. Такая организация данных, позволяет получать информацию о задолженности контрагентов в разрезах, не предусмотренных бухгалтерским учетом. В частности, речь идет о детализации долгов по валютам (или условным единицам) для компаний-резидентов Молдовы, по заказам покупателей / поставщикам и расчетным документам на их основе. В свою очередь, применяемая методика накладывает ограничение рекомендательного характера, на использование документа [Операция](/d/Entry) при работе со счетами кредиторской или дебиторской задолженности. Для того, чтобы случайно не внести расхождение в систему учета взаиморасчетов, используйте документы [Корректировка долга покупателя](/d/AdjustDebts) и [Корректировка долга поставщика](/d/AdjustVendorDebts), для оформления встречных взаимозачетов, списаний, переуступок и других задач, требующих особенных бухгалтерских корреспонденций счетов.

# Статус

Справочная информация для произвольной классификации статусов договоров. В качестве примера могут выступать следующие значения: На ознакомлении, Отправлен, Ожидание подписи, Подшит и так далее. Статус выводится в форму списка договоров и может использоваться для отбора или сортировки данных. См. также [Статусы договоров](/c/ContractStatuses).

# Подписан

Признак подписания договора. Свойство связано с функциональной опцией системы [Контроль договоров](/cf/Settings#ContractsControl) и предназначено для контроля возможности реализации товаров покупателям в зависимости от наличия задолженности и подписанного договора.

!!!note "Примечание"
	Для редактирования полей `Статус` или `Подписан`, пользователю необходимо обладать правом `Подписание договоров`.

# Валюта

Валюта договора, ключевой реквизит, задающий валюту ведения расчетов с контрагентом. Если валюта договора отлична от лея, документы введенные по данному договору можно будет ввести в одной из двух валют: леи или указанная в договоре валюта.

!!!tip "Подсказка"
	Несмотря на то, что валюту документа можно менять, во избежании проблем округления задолженности контрагента, рекомендуется вводить документы в той валюте, в которой ведется учет по договору.

Логика определения курса валюты задается в полях `Курс валюты` на вкладке `Покупатель` и/или `Поставщик` соответственно.

# Курс валюты

Поле доступно для договоров в иностранной валюте и может принимать следующие значения:

## Фиксированный

В этом случае вы можете указать фиксированный курс валюты договора в поле `Курс`. При вводе заказов и накладных по данному договору, система будет использовать заданный в справочнике валют, курс. Если в поле `Курс` не указать значение курса, курс валюты будет определяться на момент ввода документа.

Например, если вы укажете валюту USD, и фиксированный курс 17 лей, то при вводе документа Заказ покупателя, курс валюты документа будет установлен в 17 лей. При вводе документа Реализация товаров на основании данного заказа, курс валюты будет взят из заказа, и также будет установлен в 17 лей.

В свою очередь, если фиксированный курс задан не будет, то в примере выше, при вводе заказа, курс валюты заказа будет установлен в значение текущего курса (согласно текущих курсов валют). Последующий ввод реализации, будет использовать курс валюты, указанный в заказе.

Данный метод расчета курса имеет смысл указывать при работе с резидентами страны, с привязкой к курсу иностранной валюты.

## На дату операции

При данном варианте, значение курса будет определяться при вводе первичных документов. Таким образом, курс валюты заказа и накладной могут отличаться, в случае если курс валюты различался на даты этих операций.

Использовать этот метод определения курса имеет смысл при работе с нерезидентами, когда взаиморасчеты полностью ведутся в иностранной валюте по валютным счетам бухгалтерского учета.

!!!tip "Подсказка"
	В обоих вариантах определения курса валюты, само значение курса, при необходимости, может быть отредактировано на уровне ввода исходных документов. Также, нужно отметить, что данный механизм задает курс для документов по реализации, оплаты же, всегда вводятся по национальному курсу на дату ввода документа.

# Основной договор

В системе возможен учет не только по основному договору, а так же в разрезе его дополнительных приложений. Для ведения аналитики в разрезе приложений, необходимо заполнить значение данного поля.

# Цены

Поле служит для заполнения по умолчанию. Укажите необходимый «тип Цен» для текущего Договора и в документах, после ввода договора, цены заполнятся автоматически.

Существует возможность задания цен на ТМЦ непосредственно в договоре. Такие цены будут иметь приоритет над ценами, задаваемыми в документе [Установка цен](/d/SetupPrices).

Данная возможность будет полезна в случаях, когда не ведется учет по заказам покупателям/поставщикам, и не требуется специальный контроль количества ТМЦ.

# Дней доставки

Предполагаемое количество календарных дней для расчета поля «Нужно» в документах.  Определяет заполнение по умолчанию ожидаемой даты получения. Целесообразно использовать в случае, когда договором предусмотрен фиксированный срок доставки для всех заказов.

!!!warning ""
	Не рекомендуется заполнять реквизит, в случае установки индивидуальных или уточненных сроков доставки заказа. В этом случае целесообразно использовать реквизит документа.

# Закрывать предоплату

Флаг работает как значение по умолчанию при вводе документов [Расходная накладная](/d/Invoice) и [Поступление товаров](/d/VendorInvoice). Флаг влияет на алгоритм определения авансовых платежей в оперативном учете, и может быть включен/выключен на уровне каждого документа. См. также [Почему я не вижу проводки по авансам контрагентов?](/faqaccounting#WhereIsAdvance)

# Отображать авансы в конце месяца <a name=CloseAdvances></a>

Флаг влияет на момент времени зачета авансов в финансовом учете по данному договору. Если флаг включен, проведение первичных документов в течении периода, не будет сопровождаться определением и формированием проводок по авансам. Эти операции могут быть выполнены в конце месяца отдельной парой документов [Закрытие полученных авансов](/d/ClosingAdvances) и [Закрытие выданных авансов](/d/ClosingAdvancesGiven). При создании договоров, начальное значение данного флага устанавливается согласно настройке приложения [Закрывать авансы в конце месяца](/cf/Settings#CloseAdvances).

!!!note "Примечание"
	Флаг не влияет на механизмы определения авансовых платежей в оперативном учете. Такие отчеты как [Дебиторы](/r/Debts) и [Кредиторы](/r/VendorDebts) будут показывать актуальное состояние по взаиморасчетам, вне зависимости от состояния данного флага.

!!!warning "Внимание!"
	В связи с курсовой разницей, рекомендуется устанавливать данный флаг для договоров в валюте, во избежание неочевидных расчетов программы по закрытию авансов в течении периода.

# Печать

В программе предусмотрены базовые возможности по печати договоров. Печатные формы договоров (шаблоны) создаются пользователями в подсистеме Документы (см. меню `Быстрые функции > Документы`). Создаваемые шаблоны, связываются с конкретным договорами через поле `Шаблон` справочника договоров.

Разработка печатной формы договора производится в табличном поле, расположенном на вкладке `Таблица`, создаваемого документа. При создании шаблона договора, доступны следующие поля:

|Поле|Описание|
|---|---|
|Number| Номер договора
|Date| Дата начала действия договора
|Customer| Официальное название покупателя
|Manager| Ответственное за покупателя лицо (поле `Ответственный`, в группе `Покупатель` справочника Контрагенты)|
|CustomerDirector| Руководитель организации покупателя|
|CustomerAddress| Юридический адрес покупателя|
|CodeFiscal| Фискальный код покупателя|
|VATCode| Код НДС покупателя|
|CustomerBankCode| Код банка покупателя (банковские реквизиты покупателя задаются в поле `Банковский счет`, в карточке договора)|
|CustomerBank| Название банка покупателя|
|CustomerBankAccount| Номер счета покупателя|
|CustomerPhone| Рабочий телефон покупателя|
|CustomerFax| Факс покупателя|
|CustomerEmail| Электронная почта покупателя|

Для того, чтобы эти поля были автоматически заполнены, у редактируемого табличного документа, должно быть установлено свойство Макет:

![](../img/20230116203807.png)

Предполагается, что реквизиты нашей организации, будут заполнены непосредственно в самом шаблоне. На картинке ниже, представлен пример части макета договора с реквизитами сторон:

![](../img/20230117082531.png)  