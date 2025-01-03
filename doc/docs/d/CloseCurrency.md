﻿Закрытие валютных остатков по резидентам страны. Это документ специфической функциональности, выполняющий следующие  действия:

- Анализирует валютные остатки покупателей-резидентов по привязанным к валюте договорам. Сюда входят как долги, так и авансы;
- Производит перенос всех валютных остатков на текущий леевый договор с покупателем. Леевая сумма рассчитывается по курсу на момент закрытия валют (т.е. на конец прошлого года, от даты ввода документа закрытия валют);
- Закрываются образовавшиеся леевые остатки по валютным договорам на текущий леевый договор с покупателем.

В процессе работы, программа формирует наборы [корректировок долгов покупателей](/d/AdjustDebts). Для каждой операции, создается отдельная корректировка. Результатом работы документа, является образование всей задолженности покупателя на одном леевом договоре.

Документ вводится и заполняется текущей датой. Для заполнения документа, на командной панели предусмотрена кнопка `Заполнить`. В дальнейшем, при необходимости, однажды заполненный документ, может быть перезаполнен или перерасчитан.

Перерасчёт документа следует проводить, если требуется актуализация данных по уже существующим в документе записям. В свою очередь, перезаполнение, позволяет полностью очистить документ от предыдущих записей, и ввести новые данные, актуализируя информацию о валютных остатках и договорах с покупателями.

Также, допускается частичное заполнение по группе, или выбранным клиентам. Например, таким образом можно заполнить документ по всем клиентам, и в случае обнаружения особых ситуаций требующих отдельного внимания, исключить их из списка, путём пометки на удаление нужных корректировок. Впоследствии, для таких заказчиков, можно будет создать отдельные закрытия валют.

Стоит обратить внимание на следующие нюансы работы документа:

- Получение данных и формирование корректировок производится на конец прошлого от даты документа, года. Это означает, что если закрытие валют выполняется в феврале/марте, то после закрытия валют, может потребоваться переформирование/перепроведение оплат и/или расходных накладных (и других связанных документов) текущего года. Это касается тех покупателей, по которым на момент формирования закрытия валют, уже были проведены какие-то операции в текущем периоде.
- В процессе генерации корректировок, могут происходить исключительные ситуации, связанные с некорректным состоянием входных данных. Те корректировки, которые не удалось успешно провести, сохраняются в базе, с пометкой на удаление. Чтобы отобразить такие документы в основном списке корректировок, можно воспользоваться кнопкой `Показать удаленные` (`Скрыть удаленные`), расположенной на командной панели списка.
- В процессе переноса задолженности, программа пытается автоматически закрыть её на возможно уже существующие документы леевого договора (договора приёмника). Остаток не покрытой документами-приёмниками задолженности, фиксируется за самой корректировкой. `Вариант оплаты` и `Дата оплаты` такой задолженности указываются в одноименных реквизитах шапки документа.
- С каждой сформированной корректировкой, можно работать в обычном режиме. То есть при необходимости, их можно снимать с проведения, перепроводить и так далее. Однако, следует учитывать, что при повторном заполнении или перерасчёте документа закрытия валют, корректировки будут переоформлены, а изменения - утеряны.

---

См. также:

- [Корректировка долга покупателя](/d/AdjustDebts)
- [Акт сверки](/r/Reconciliation)
- [Дебиторы](/r/Debts)

