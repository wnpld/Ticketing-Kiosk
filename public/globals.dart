library globals;
import 'dart:html';

String serverurl = "";

//Adjust the following paths as necessary
String validatescript = "/cgi-bin/bcval.pl";
String orderscript = "/cgi-bin/ticketorder.pl";

Element? scanblock = document.querySelector('#scan');
Element? manualblock = document.querySelector('#manual');
Element? seblock = document.querySelector('#selectevent');
Element? stblock = document.querySelector('#selecttickets');
Element? finishblock = document.querySelector('#finish');
Element? printblock = document.querySelector('#print');
Element? errorblock = document.querySelector('#error');
Element? barcodespan = document.querySelector('#enteredbarcode');
Element? errorheader = document.querySelector('#errorheader');
Element? errorinfo = document.querySelector('#errorinfo');
Element? footertext = document.querySelector('#footer');

bool oneprogramperday = true;

int adultTicketSum = 1;
int youthTicketSum = 1;

int registrationdelay = 5;

String language = "english";
var scanBarcode = {
    'english': 'Please scan your library card to get started.',
    'spanish': 'Escanee su tarjeta de la biblioteca para comenzar.',
    'polish': 'Aby rozpocząć, zeskanuj swoją kartę biblioteczną.',
    'russian': 'Пожалуйста, отсканируйте свой читательский билет, чтобы начать.',
    'chinese': '请扫描您的借书证以开始。',
    'tradchinese': '請掃描您的借書卡以開始使用。'
};
var manualEntry = {
    'english': 'Manually Enter Card/Phone Number',
    'spanish': 'Ingresar manualmente el número de tarjeta/teléfono',
    'polish': 'Wprowadź ręcznie numer karty/telefonu',
    'russian': 'Введите номер карты/телефона вручную',
    'chinese': '手动输入卡号/电话号码',
    'tradchinese': '手動輸入卡片/電話號碼'
};
var closedHeader = {
    'english': 'The Ticket Kiosk is Closed',
    'spanish': 'El quiosco de venta de billetes está cerrado',
    'polish': 'Kiosk biletowy jest zamknięty',
    'russian': 'Билетный киоск закрыт',
    'chinese': '售票亭已关闭',
    'tradchinese': '售票亭已關閉'
};
var closedText = {
    'english': 'There are no ticketed events scheduled in Youth Services for the rest of the day.',
    'spanish': 'No hay eventos con entradas programados en los Servicios para Jóvenes para el resto del día.',
    'polish': 'Na resztę dnia w Centrum Usług Młodzieżowych nie zaplanowano żadnych wydarzeń biletowanych.',
    'russian': 'На оставшуюся часть дня в Молодежном отделе не запланировано никаких мероприятий с оплатой билетов.',
    'chinese': '当天剩余时间青年服务中没有安排售票活动。',
    'tradchinese': '當天剩餘的時間裡，青少年服務處沒有安排任何售票活動。'
};

var manualText = {
    'english': 'Enter your libary barcode or phone number.',
    'spanish': 'Introduzca su código de barras o el número de teléfono.',
    'polish': 'Wprowadź kod kreskowy biblioteki lub numer telefonu.',
    'russian': 'Введите штрих-код вашей библиотеки или номер телефона.',
    'chinese': '输入您的图书馆条形码或电话号码。',
    'tradchinese': '輸入您的圖書館條碼或電話號碼。'
};

var manualDescription = {
    'english': 'Out-of-district cards and phone numbers can only be used to get event tickets starting ### minutes before the event starts.',
    'spanish': 'Las tarjetas y números de teléfono de fuera del distrito solo se pueden usar para obtener entradas para eventos a partir de ### minutos antes de que comience el evento.',
    'polish': 'Karty i numery telefonów spoza rejonu można wykorzystać wyłącznie do zakupu biletów na wydarzenie, które rozpoczyna się ### minut przed jego rozpoczęciem.',
    'russian': 'Карты и номера телефонов для иногородних можно использовать для получения билетов на мероприятия только за ### минут до начала мероприятия.',
    'chinese': '区外卡及电话号码仅可在活动开始前###分钟起领取活动门票。',
    'tradchinese': '區外卡和電話號碼只能在活動開始前 ### 分鐘開始取得活動門票。'
};

var manualSubmit = {
    'english': 'Submit Card/Phone Number',
    'spanish': 'Ingresar su número de tarjeta/número de teléfono',
    'polish': 'Prześlij kartę/numer telefonu',
    'russian': 'Отправить номер карты/телефона',
    'chinese': '提交卡号/电话号码',
    'tradchinese': '提交卡片/電話號碼'
};

var manualCancel = {
    'english': 'Cancel',
    'spanish': 'Cancelar',
    'polish': 'Anulować',
    'russian': 'Отмена',
    'chinese': '取消',
    'tradchinese': '取消'
};

var eventCancel = {
    'english': 'Cancel',
    'spanish': 'Cancelar',
    'polish': 'Anulować',
    'russian': 'Отмена',
    'chinese': '取消',
    'tradchinese': '取消'
};

var seCancel = {
    'english': 'Cancel',
    'spanish': 'Cancelar',
    'polish': 'Anulować',
    'russian': 'Отмена',
    'chinese': '取消',
    'tradchinese': '取消'
};

var ticketsCancel = {
    'english': 'Cancel',
    'spanish': 'Cancelar',
    'polish': 'Anulować',
    'russian': 'Отмена',
    'chinese': '取消',
    'tradchinese': '取消'
};

var phoneErrorheader = {
    'english': 'Phone Number Entered',
    'spanish': 'Número de teléfono ingresado',
    'polish': 'Wprowadzono numer telefonu',
    'russian': 'Введенный номер телефона',
    'chinese': '输入的电话号码',
    'tradchinese': '輸入的電話號碼'
};

var phoneErrorinfo = {
    'english': 'Only tickets for in-district patrons are currently available and phone numbers cannot be validated as from within the library district.  Please check back ### minutes before the start of the program for general availability tickets.',
    'spanish': 'Actualmente, solo hay entradas disponibles para usuarios del distrito y no se pueden validar números de teléfono si se trata de personas que pertenecen al distrito de la biblioteca. Vuelva a consultar ### minutos antes del inicio del programa para ver las entradas disponibles para todos.',
    'polish': 'Obecnie dostępne są tylko bilety dla użytkowników z okręgu, a numery telefonów nie mogą być weryfikowane jako pochodzące z okręgu bibliotecznego. Sprawdź ponownie ### minut przed rozpoczęciem programu, aby uzyskać bilety o ogólnej dostępności.',
    'russian': 'В настоящее время доступны только билеты для посетителей из района, а номера телефонов не могут быть проверены из библиотечного района. Пожалуйста, проверьте наличие билетов для общего пользования за ### минут до начала программы.',
    'chinese': '目前仅提供区域内顾客的门票，无法验证电话号码是否来自图书馆区域内。请在节目开始前 ### 分钟回来查看是否有普通门票。',
    'tradchinese': '目前僅提供區內讀者的門票，且無法驗證圖書館區內的電話號碼。 請在節目開始前 ### 分鐘回來查看常規門票。'
};

var cardOODheader = {
    'english': 'Out of District Library Card',
    'spanish': 'Tarjeta de biblioteca fuera del distrito',
    'polish': 'Karta biblioteczna spoza okręgu',
    'russian': 'Библиотечная карточка для читателей из других районов',
    'chinese': '区外借书卡',
    'tradchinese': '區外圖書館卡'
};

var cardOODinfo = {
    'english': 'No tickets are currently available for out-of-district users.  Check back ### minutes before the program starts.',
    'spanish': 'Actualmente no hay entradas disponibles para usuarios de fuera del distrito. Vuelva a consultar ### minutos antes de que comience el programa.',
    'polish': 'Obecnie nie ma dostępnych biletów dla użytkowników spoza okręgu. Sprawdź ponownie ### minut przed rozpoczęciem programu.',
    'russian': 'Билеты для пользователей из других районов в настоящее время недоступны. Проверьте за ### минут до начала программы.',
    'chinese': '目前没有可供区外用户购买的门票。请在节目开始前 ### 分钟回来查看。',
    'tradchinese': '目前，外地用戶暫不提供門票。 在節目開始前 ### 分鐘回來查看。'
};

var barcodeErrorheader = {
    'english': 'The scanned card was not recognized as a valid library card.  It may have have just scanned incorrectly.  Check your card and try again.',
    'spanish': 'La tarjeta escaneada no fue reconocida como una tarjeta de biblioteca válida. Es posible que se haya escaneado incorrectamente. Verifique su tarjeta e intente nuevamente.',
    'polish': 'Zeskanowana karta nie została rozpoznana jako ważna karta biblioteczna. Mogła zostać po prostu nieprawidłowo zeskanowana. Sprawdź swoją kartę i spróbuj ponownie.',
    'russian': 'Отсканированная карта не распознана как действительная библиотечная карта. Возможно, она просто была отсканирована неправильно. Проверьте карту и попробуйте еще раз.',
    'chinese': '扫描的借书卡未被识别为有效的借书卡。可能扫描不正确。请检查您的借书卡并重试。',
    'tradchinese': '掃描的卡片未被識別為有效的借書卡。 它可能只是掃描不正確。 檢查您的卡並重試。'
};

var barcodeErrorinfo = {
    'english': 'Double-check the card that you scanned or entered to make sure that it was your current library card.  If you entered a phone number, make sure to enter the entire ten-digit phone number.',
    'spanish': 'Vuelva a verificar la tarjeta que escaneó o ingresó para asegurarse de que sea su tarjeta de biblioteca actual. Si ingresó un número de teléfono, asegúrese de ingresar el número de teléfono completo de diez dígitos.',
    'polish': 'Sprawdź dwukrotnie kartę, którą zeskanowałeś lub wprowadziłeś, aby upewnić się, że jest to Twoja aktualna karta biblioteczna. Jeśli wprowadziłeś numer telefonu, upewnij się, że wprowadziłeś cały dziesięciocyfrowy numer telefonu.',
    'russian': 'Дважды проверьте карту, которую вы отсканировали или ввели, чтобы убедиться, что это ваша текущая библиотечная карта. Если вы ввели номер телефона, убедитесь, что вы ввели весь десятизначный номер телефона.',
    'chinese': '仔细检查您扫描或输入的卡片，确保这是您当前的借书证。如果您输入的是电话号码，请确保输入完整的十位数电话号码。',
    'tradchinese': '仔細檢查您掃描或輸入的卡片，以確保它是您目前的借書卡。 如果您輸入了電話號碼，請確保輸入完整的十位數電話號碼。'
};

var selectEvent = {
    'english': 'For which event do you want tickets (tap to choose)?',
    'spanish': '¿Para qué evento quieres entradas (toca para elegir)?',
    'polish': 'Na które wydarzenie chcesz bilety (dotknij, aby wybrać)?',
    'russian': 'На какое мероприятие вам нужны билеты (нажмите, чтобы выбрать)?',
    'chinese': '您想要哪场活动的门票 (点击选择)？',
    'tradchinese': '您想要哪個活動的門票 (點選選擇)？'
};

var selectTickets = {
    'english': 'Select Tickets',
    'spanish': 'Seleccionar entradas',
    'polish': 'Wybierz bilety',
    'russian': 'Выбрать билеты',
    'chinese': '选择门票',
    'tradchinese': '選擇門票'
};

var alreadyTicketedheader = {
    'english': 'Tickets Already Issued',
    'spanish': 'Entradas ya emitidos',
    'polish': 'Bilety już wystawione',
    'russian': 'Билеты уже выпущены',
    'chinese': '门票已发出',
    'tradchinese': '門票已發出'
};

var alreadyTicketedinfo = {
    'english': 'Tickets have already been aquired for this library card today and there is a limit of one event per card.',
    'spanish': 'Ya se han adquirido las entradas para esta tarjeta de biblioteca hoy y hay un límite de un evento por tarjeta.',
    'polish': 'Bilety na tę kartę biblioteczną zostały już dziś zakupione. Na jedną kartę przypada maksymalnie jedno wydarzenie.',
    'russian': 'Билеты по этой библиотечной карте уже приобретены сегодня, и на одну карту действует ограничение — одно мероприятие.',
    'chinese': '今天已经为这张借书证购买了门票，每张卡限参加一场活动。',
    'tradchinese': '這張借書卡的門票已於今日獲取，每張借書卡僅限參加一次活動。'
};

var noTickets = {
    'english': 'There are no tickets remaining for this event.',
    'spanish': 'No quedan entradas disponibles para este evento.',
    'polish': 'Na to wydarzenie nie ma już biletów.',
    'russian': 'Билетов на это мероприятие не осталось.',
    'chinese': '此活动已无剩余门票。',
    'tradchinese': '此活動已無剩餘門票。'
};

var noTicketsNowheader = {
    'english': 'Tickets Not Currently Available',
    'spanish': 'Entradas no disponibles actualmente',
    'polish': 'Bilety obecnie niedostępne',
    'russian': 'Билеты в настоящее время недоступны',
    'chinese': '目前无票出售',
    'tradchinese': '目前不提供門票'
};

var noTicketsNowinfo = {
    'english': 'No tickets are available for this card at this time since district library cards are given priority.  You may try again ### minutes before the event starts.',
    'spanish': 'No hay entradas disponibles para esta tarjeta en este momento, ya que las tarjetas de la biblioteca del distrito tienen prioridad. Puede volver a intentarlo ### minutos antes de que comience el evento.',
    'polish': 'W tej chwili nie ma dostępnych biletów na tę kartę, ponieważ karty biblioteczne okręgowe mają pierwszeństwo. Możesz spróbować ponownie ### minut przed rozpoczęciem wydarzenia.',
    'russian': 'Билеты на эту карту в настоящее время недоступны, так как приоритет отдается картам районной библиотеки. Вы можете попробовать еще раз за ### минут до начала мероприятия.',
    'chinese': '由于地区图书馆卡优先，因此目前此卡没有可用门票。您可以在活动开始前###分钟再试一次。',
    'tradchinese': '由於地區圖書館卡優先，因此該卡目前不提供門票。 您可以在活動開始前 ### 分鐘重試。'
};

var noTicketsNowButton = {
    'english': 'Only District Cardholder Tickets Remain - Check Back ### Minutes Before Event Start',
    'spanish': 'Solo quedan boletos para titulares de tarjetas del distrito. Vuelva a consultar ### Minutos antes del inicio del evento',
    'polish': 'Pozostały tylko bilety posiadaczy karty okręgowej — sprawdź ponownie ### minut przed rozpoczęciem wydarzenia',
    'russian': 'Остались только билеты для владельцев районных карт — проверьте за ### минут до начала мероприятия',
    'chinese': '仅剩地区持卡人门票 - 活动开始前 ### 分钟再次查看',
    'tradchinese': '僅剩地區持卡人門票 - 請在活動開始前 ### 分鐘回來查看' 
};

var limitReached = {
    'english': 'Daily Ticket Limit Reached',
    'spanish': 'Se alcanzó el límite diario de boletos',
    'polish': 'Osiągnięto dzienny limit biletów',
    'russian': 'Достигнут дневной лимит билетов',
    'chinese': '每日票数已达上限',
    'tradchinese': '每日門票已達上限'
};

var ticketsOut = {
    'english': 'No Tickets Remaining',
    'spanish': 'No quedan entradas',
    'polish': 'Brak pozostałych biletów',
    'russian': 'Билетов не осталось',
    'chinese': '已无剩余门票',
    'tradchinese': '沒有剩餘門票'
};

var monthsTerm = {
    'english': ' months',
    'spanish': ' meses',
    'polish': ' miesięcy',
    'russian': ' месяцев',
    'chinese': '个月',
    'tradchinese': '個月'
};

var yearsTerm = {
    'english': ' years',
    'spanish': ' años',
    'polish': ' lat',
    'russian': ' лет',
    'chinese': '年',
    'tradchinese': '年'
};

var childTicketsHeader = {
    'english': 'Child Tickets',
    'spanish': 'Entradas para niños',
    'polish': 'Bilety dla dzieci',
    'russian': 'Детские билеты',
    'chinese': '儿童票',
    'tradchinese': '兒童票'
};

var adultTicketsHeader = {
    'english': 'Adult Tickets',
    'spanish': 'Entradas para adultos',
    'polish': 'Bilety dla dorosłych',
    'russian': 'Билеты для взрослых',
    'chinese': '成人票',
    'tradchinese': '成人票'
};

var adultTicketsNote = {
    'english': 'Adult tickets are currently limited to one because this event is almost full.',
    'spanish': 'Las entradas para adultos actualmente están limitadas a una porque este evento está casi lleno.',
    'polish': 'Obecnie dostępna jest tylko jedna cena biletu dla dorosłych, ponieważ wydarzenie jest prawie pełne.',
    'russian': 'В настоящее время количество билетов для взрослых ограничено одним, поскольку на мероприятие почти нет мест.',
    'chinese': '由于本次活动已基本满员，目前成人票仅限一张。',
    'tradchinese': '成人票目前僅限一張，因為活動幾乎已滿。'
};

var childNoteI = {
    'english': 'Note: all children for this event must between ',
    'spanish': 'Nota: todos los niños para este evento deben tener entre ',
    'polish': 'Uwaga: w tym wydarzeniu mogą wziąć udział wyłącznie dzieci w wieku od ',
    'russian': 'Примечание: в этом мероприятии могут принять участие дети в возрасте от ',
    'chinese': '注意：参加本次活动的所有儿童年龄必须在',
    'tradchinese': '註：所有參與本次活動的兒童年齡必須在。'
};

var childNoteII = {
    'english': ' old.',
    'spanish': '.',
    'polish': '.',
    'russian': '.',
    'chinese': '之间。',
    'tradchinese': '之間。'
};

var requestTickets = {
    'english': 'Request Tickets',
    'spanish': 'Solicitar entradas',
    'polish': 'Poproś o bilety',
    'russian': 'Запросить билеты',
    'chinese': '索取门票',
    'tradchinese': '索取門票'
};

var remainingEvents = {
    'english': 'Today\'s Remaining Ticketed Events',
    'spanish': 'Eventos restantes con entradas disponibles para hoy',
    'polish': 'Dzisiejsze pozostałe wydarzenia biletowane',
    'russian': 'Оставшиеся билеты на сегодняшние мероприятия',
    'chinese': '今天剩余的售票活动',
    'tradchinese': '今天剩餘的門票活動'
};

var ticketsAvailable = {
    'english': 'Tickets Available',
    'spanish': 'Entradas disponibles',
    'polish': 'Dostępne bilety',
    'russian': 'Билеты доступны',
    'chinese': '有票出售',
    'tradchinese': '可用門票'
};

var kioskOffline = {
    'english': 'The ticket kiosk is temporarily offline',
    'spanish': 'El quiosco de venta de entredas está temporalmente fuera de línea',
    'polish': 'Kiosk biletowy jest tymczasowo niedostępny',
    'russian': 'Билетный киоск временно не работает',
    'chinese': '售票亭暂时下线',
    'tradchinese': '售票亭暫時離線'
};

var finishHeader = {
    'english': 'Collect Tickets',
    'spanish': 'Recoger entradas',
    'polish': 'Zbieraj bilety',
    'russian': 'Собирайте билеты',
    'chinese': '领取门票',
    'tradchinese': '領取門票'
};

var finishText = {
    'english': 'Your tickets are being printed.  Please collect them from the ticket dispenser.',
    'spanish': 'Sus entradas se están imprimiendo. Recójalas en el expendedor de entradas.',
    'polish': 'Twoje bilety są drukowane. Odbierz je z dystrybutora biletów.',
    'russian': 'Ваши билеты печатаются. Пожалуйста, заберите их в автомате по выдаче билетов.',
    'chinese': '正在打印您的票。请从售票机领取。',
    'tradchinese': '您的門票正在列印。 請從售票機領取。'
};

var oodNotice = {
    'english': 'If you do not see the event you want tickets for, it may be because you have an out of district card and spaces are reserved for in-district patrons.  You can try again a few minutes before the program starts.',
    'spanish': 'Si no ves el evento para el que quieres entradas, puede ser porque tienes una tarjeta de fuera del distrito y hay plazas reservadas para los asistentes del distrito. Puedes volver a intentarlo unos minutos antes de que empiece el programa.',
    'polish': 'Jeśli nie widzisz wydarzenia, na które chcesz kupić bilety, może to być spowodowane tym, że masz kartę spoza okręgu, a miejsca są zarezerwowane dla patronów z okręgu. Możesz spróbować ponownie kilka minut przed rozpoczęciem programu.',
    'russian': 'Если вы не видите мероприятие, на которое хотите купить билеты, это может быть связано с тем, что у вас карта из другого района, а места зарезервированы для посетителей из этого района. Вы можете повторить попытку за несколько минут до начала программы.',
    'chinese': '如果您没有看到想要购买门票的活动，可能是因为您持有的是区外卡，而座位是为区内观众预留的。您可以在活动开始前几分钟再试一次。',
    'tradchinese': '如果您沒有看到想要門票的活動，可能是因為您持有區外卡，而空間是為區內顧客預留的。 您可以在程序開始前幾分鐘重試。'
};