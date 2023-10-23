Nullarity 5 это простая и удобная программа для ведения бухгалтерского и хозяйственного учета коммерческих предприятий Молдовы с возможностью легкой адаптации под другие страны. Конфигурация разработана с использованием EDT, на английском варианте встроенного языка 1С и содержит три языка пользовательского интерфейса: Английский, Румынский и Русский.

Конфигурация не использует БСП или другие типовые подсистемы сторонних разработчиков. В основе технических решений конфигурации лежат принципы экстремального программирования, наименьшего удивления, чистоты и выразительности кода, кратких но емких идентификаторов, без шума из очевидного контекста, в код не заложена чрезмерная универсальность, квазимодульность, эмуляция наследования, псевдо ООП и другие программные эксперименты, с целью втиснуть разнообразные парадигмы в рамки языковой модели языка 1С, их не предусматривающей. В конфигурации, намеренно, практически нигде не применяется комментирование кода и не используется комментирующая типизация.

Эта конфигурация является вопиющим примером несоблюдения стандартов компании 1С по части оформления кода, что никоим образом не является предметом гордости, а лишь декларацией выбранного подхода. Также, в разработке решения нам помогает вера в то, что тестирование и документирование есть неотъемлемая часть программирования, поэтому мы плотно используем систему [Тестер](https://github.com/grumagargler/tester) и документируем разработку неразрывно с написанием кода.

Справка по программе расположена на сайте http://nullarity.com.

# Функциональность

- Типовые хозяйственные операции, стандартная бухгалтерская и регламентированная отчетность.
- Учет товаров, материалов, услуг, основных средств и нематериальных активов.
- Заработная плата по различным валютам начисления, кадровый учет, табелирование, система утверждения времени по проектам и задачам, удаленный доступ заказчиков для утверждения работ.
- Заявки покупателей, заказы поставщикам, внутренние заявки и бизнес-процессы по ним включая резервирование и размещение.
- Универсальный механизм формирования дополнительных свойств и характеристик для ТМЦ, контрагентов и других справочников.
- Гибкая настройка прав доступа, создание специальных профилей и групп пользователей, встроенный в систему почтовый клиент, умеет работать по протоколам POP3/IMAP.
- Хранение файлов и документов, календарь, графики, задачи, проекты.
- Работа в модели SAAS.
- Возможность вести в одной информационной базе неограниченное число предприятий, с гибкой настройкой прав доступа пользователей к областям данных.

# Условия использования

- Конфигурацию можно использовать бесплатно, без каких-либо ограничений по функциональности.
- За исключением авторства, конфигурацию можно дорабатывать самостоятельно без каких-либо обязательств. И мы также будем очень рады вашим pull-request-ам!
- Обращаем ваше внимание, что конфигурация зарегистрирована в агентстве авторских прав Республики Молдова, поэтому изменение авторства разработки или заимствование программного кода для тиражных коммерческих проектов допускается только с согласия её автора (nullarity@gmail.com).

# Проект

- EDT Ruby 2023.2.1
- 1C:Enterprise 8.3.23 (режим совместимости 8.3.23)
