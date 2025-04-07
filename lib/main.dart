import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings.dart';
import 'database_helper.dart';
import 'package:introduction_screen/introduction_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(
      home: FutureBuilder(
        future: _initializeApp(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final isFirstLaunch = snapshot.data as bool;
            return MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (context) => Settings()),
              ],
              child: NameListApp(isFirstLaunch: isFirstLaunch),
            );
          }
          return SplashScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/app_icon.png',
              width: 150,
              height: 150,
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _initializeApp() async {
  await AppData.initialize();

  final dbHelper = DatabaseHelper();
  await dbHelper.checkAndRemoveExpiredNames();
  await dbHelper.checkAndUpdateNewlyDepartedStatus();

  // Проверяем первый запуск
  final prefs = await SharedPreferences.getInstance();
  bool isFirstLaunch = prefs.getBool('first_launch') ?? true;

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  return isFirstLaunch;
}

// Модифицируем NameListApp для обработки первого запуска
class NameListApp extends StatelessWidget {
  final bool isFirstLaunch;

  const NameListApp({Key? key, required this.isFirstLaunch}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<Settings>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Мой приход',
          theme: ThemeData(
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          darkTheme: ThemeData.dark().copyWith(
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          themeMode: settings.themeMode,
          home: isFirstLaunch ? OnboardingScreen() : NameListHome(),
        );
      },
    );
  }
}

// Добавляем новый виджет для обучения
class OnboardingScreen extends StatelessWidget {
  final _introKey = GlobalKey<IntroductionScreenState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.w700,
        color: isDarkMode ? Colors.white : Colors.grey,
      ),
      bodyTextStyle: TextStyle(
        fontSize: 19.0,
        color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
      ),
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: theme.scaffoldBackgroundColor,
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      key: _introKey,
      globalBackgroundColor: theme.scaffoldBackgroundColor,
      pages: [
        // Приветственный экран
        PageViewModel(
          title: "Помянник",
          body: "Добро пожаловать в приложение для поминовения живых и усопших. Создавайте списки, добавляйте имена и молитесь за своих близких.",
          image: Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset(
                'assets/images/app_icon.png', // Путь к иконке приложения
                width: 100,
                height: 100,
              ),
            ),
          ),
          decoration: pageDecoration.copyWith(
            bodyAlignment: Alignment.center,
          ),
        ),

        // Добавление имени
        PageViewModel(
          title: "Добавление имени",
          bodyWidget: Column(
            children: [
              Text(
                "Нажмите на эту кнопку внизу экрана, чтобы добавить новое имя в список",
                style: TextStyle(
                  fontSize: 19.0,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                margin: EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Добавить имя",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          image: Center(child: SizedBox.shrink()), // Пустой виджет для изображения
          decoration: pageDecoration.copyWith(
            contentMargin: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
          ),
        ),

        // Редактирование и удаление
        PageViewModel(
          title: "Редактирование и удаление",
          body: "Сдвиньте имя вправо для удаления или влево для редактирования",
          image: Center(
            child: Container(
              margin: EdgeInsets.only(top: 20),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 250,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        Text("Имя для поминовения"),
                        Icon(Icons.delete, color: Colors.red),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "← Редактировать    Удалить →",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          decoration: pageDecoration,
        ),

        // Добавление списка
        PageViewModel(
          title: "Добавление списка",
          body: "Нажмите на эту кнопку в правом верхнем углу, чтобы создать новый список",
          image: Center(
            child: Container(
              margin: EdgeInsets.only(top: 20),
              child: Stack(
                children: [
                  Container(
                    width: 300,
                    height: 100,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "Мой список",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: () {},
                      child: Icon(Icons.add),
                    ),
                  ),
                ],
              ),
            ),
          ),
          decoration: pageDecoration,
        ),

        // Переключение между списками
        PageViewModel(
          title: "Переключение между списками",
          body: "Сдвиньте список влево или вправо для переключения между вашими списками",
          image: Center(
            child: Container(
              margin: EdgeInsets.only(top: 20),
              child: Image.asset(
                'assets/images/onboarding.png', // Путь к вашему скриншоту
                width: MediaQuery.of(context).size.width * 0.8,
                fit: BoxFit.contain,
              ),
            ),
          ),
          decoration: pageDecoration,
        ),
      ],
      onDone: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('first_launch', false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => NameListHome()),
        );
      },
      showSkipButton: true,
      skip: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          'Пропустить',
          style: TextStyle(
            fontSize: 14, // Уменьшенный размер шрифта
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.grey : theme.primaryColor,
          ),
        ),
      ),
      next: Container(
        margin: EdgeInsets.only(left: 8),
        child: Icon(
          Icons.arrow_forward,
          color: isDarkMode ? Colors.grey : theme.primaryColor,
          size: 24, // Фиксированный размер иконки
        ),
      ),
      done: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          'Начать',
          style: TextStyle(
            fontSize: 14, // Уменьшенный размер шрифта
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.grey : theme.primaryColor,
          ),
        ),
      ),
      dotsDecorator: DotsDecorator(
        size: Size(8.0, 8.0), // Уменьшенный размер точек
        color: isDarkMode ? Colors.grey[600]! : Colors.grey,
        activeColor: isDarkMode ? Colors.white : theme.primaryColor,
        activeSize: Size(20.0, 8.0), // Уменьшенный активный размер
        spacing: EdgeInsets.symmetric(horizontal: 4), // Уменьшенное расстояние между точками
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}

// Главный экран с Drawer
class NameListHome extends StatefulWidget {
  @override
  _NameListHomeState createState() => _NameListHomeState();
}

class _NameListHomeState extends State<NameListHome> {
  final PageController _pageController = PageController(); // Контроллер для PageView
  int? _currentListId; // Текущий id списка
  List<Map<String, dynamic>> _nameLists = []; // Список всех списков

  late DatabaseHelper _dbHelper;

  @override
  void initState() {
    super.initState();
    _dbHelper = DatabaseHelper();
    _loadNameLists();
  }

  Future<void> _loadNameLists() async {
    final nameLists = await _dbHelper.loadNameLists();
    setState(() {
      _nameLists = nameLists;
      // Устанавливаем текущий список на первый, если он есть
      if (_nameLists.isNotEmpty && _currentListId == null) {
        _currentListId = _nameLists[0]['id'];
      }
    });
  }

  Future<void> _addNewList(String title, ListType type) async {
    final newListId = await _dbHelper.addNameList(title, type == ListType.health ? 0 : 1);
    await _loadNameLists(); // Перезагружаем списки
    // Переключаемся на новый список
    setState(() {
      _currentListId = newListId;
      final newListIndex = _nameLists.indexWhere((list) => list['id'] == newListId);
      if (newListIndex != -1) {
        _pageController.jumpToPage(newListIndex);
      }
    });
  }

  Future<void> _addNameToList(int nameListId, String name, int gender, int statusId, int rankId, String? endDate, String? deathDate) async {
    await _dbHelper.addName(nameListId, name, gender, statusId, rankId, endDate, deathDate);
  }

  Future<void> _editNameInList(int nameId, String newName, int gender, int status_id, int rank_id, String? endDate, String? deathDate) async {
    await _dbHelper.updateName(nameId, newName, gender, status_id, rank_id, endDate, deathDate);
  }

  Future<void> _deleteNameFromList(int nameId) async {
    await _dbHelper.deleteName(nameId);
    // Проверяем, остались ли имена в текущем списке
    final currentListId = _currentListId;
    if (currentListId != null) {
      final names = await _dbHelper.loadNames(currentListId, SortType.none);
      if (names.isEmpty) {
        // Если список пуст, удаляем его
        await _deleteList(currentListId);
      }
    }
  }

  Future<void> _editListTitle(int nameListId, String newTitle) async {
    // Получаем текущее название списка
    final currentList = _nameLists.firstWhere((list) => list['id'] == nameListId);
    final currentTitle = currentList['title'];

    // Проверяем, что новое название отличается от старого
    if (newTitle != currentTitle) {
      await _dbHelper.updateNameListTitle(nameListId, newTitle);
      await _loadNameLists(); // Перезагружаем списки
    }
  }

  Future<void> _deleteList(int nameListId) async {
    await _dbHelper.deleteNameList(nameListId);
    // Перезагружаем списки
    await _loadNameLists();
    // Если удалённый список был текущим, переключаемся на первый список
    if (_currentListId == nameListId) {
      setState(() {
        _currentListId = _nameLists.isNotEmpty ? _nameLists[0]['id'] : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Помянник'),
        actions: [
          // Иконка для переключения темы
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.wb_sunny // Иконка солнца для темной темы
                  : Icons.nightlight_round, // Иконка месяца для светлой темы
              color: Colors.grey,
            ),
            onPressed: () {
              final settings = Provider.of<Settings>(context, listen: false);
              settings.setThemeMode(
                Theme.of(context).brightness == Brightness.dark
                    ? ThemeMode.light // Переключаем на светлую тему
                    : ThemeMode.dark, // Переключаем на темную тему
              );
            },
          ),
          SizedBox(width: 8), // Отступ между иконкой и кнопкой настроек
          IconButton(
            onPressed: () {
              // Переход в страницу настроек
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
            icon: Icon(Icons.settings), // Значок настроек
          ),
          FloatingActionButton(
            onPressed: () {
              _showAddListDialog(context);
            },
            child: Icon(Icons.add),
          ),
        ],
        automaticallyImplyLeading: true, // Показывать иконку меню
      ),
      // Выпадающее меню
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Меню',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text('Помянник'),
              onTap: () {
                Navigator.pop(context); // Закрыть Drawer
                // Уже находимся на странице "Помянник", поэтому ничего не делаем
              },
            ),
            ListTile(
              leading: Icon(Icons.article),
              title: Text('Новости'),
              onTap: () {
                Navigator.pop(context); // Закрыть Drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NewsPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings), // Иконка настроек
              title: Text('Настройки'),
              onTap: () {
                Navigator.pop(context); // Закрыть Drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: _nameLists.isEmpty
          ? Center(child: Text('Нет списков. Добавьте новый список.'))
          : PageView.builder(
        controller: _pageController,
        itemCount: _nameLists.length,
        onPageChanged: (index) {
          setState(() {
            _currentListId = _nameLists[index]['id'];
          });
        },
        itemBuilder: (context, index) {
          final nameList = _nameLists[index];
          return NameListPage(
            key: ValueKey(nameList['id']), // Передаем key сюда
            nameList: nameList,
            onAddName: (name, gender, statusId, rankId, endDate, deathDate) => _addNameToList(nameList['id'], name, gender, statusId, rankId, endDate, deathDate),
            onEditName: (nameId, newName, gender, statusId, rankId, endDate, deathDate) => _editNameInList(nameId, newName, gender, statusId, rankId, endDate, deathDate),
            onDeleteName: (nameId) => _deleteNameFromList(nameId),
            onEditTitle: (newTitle) => _editListTitle(nameList['id'], newTitle),
            onDeleteList: () => _deleteList(nameList['id']),
          );
        },
      ),
    );
  }

  void _showAddListDialog(BuildContext context) {
    final titleController = TextEditingController();
    ListType selectedType = ListType.health;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Создать новый список'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(hintText: 'Без названия'),
                  ),
                  SizedBox(height: 16),
                  Text('Тип списка:'),
                  Row(
                    children: [
                      Radio(
                        value: ListType.health,
                        groupValue: selectedType,
                        onChanged: (value) {
                          setState(() {
                            selectedType = value as ListType;
                          });
                        },
                      ),
                      Text('О здравии'),
                      Radio(
                        value: ListType.repose,
                        groupValue: selectedType,
                        onChanged: (value) {
                          setState(() {
                            selectedType = value as ListType;
                          });
                        },
                      ),
                      Text('Об упокоении'),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _addNewList(titleController.text, selectedType);
                    Navigator.of(context).pop();
                  },
                  child: Text('Создать'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class NameListPage extends StatefulWidget {
  final Map<String, dynamic> nameList;
  final Function(String, int, int, int, String?, String?) onAddName;
  final Function(int, String, int, int, int, String?, String?) onEditName;
  final Function(int) onDeleteName;
  final Function(String) onEditTitle;
  final VoidCallback onDeleteList;

  // Добавляем key в конструктор
  NameListPage({
    Key? key, // Добавляем параметр key
    required this.nameList,
    required this.onAddName,
    required this.onEditName,
    required this.onDeleteName,
    required this.onEditTitle,
    required this.onDeleteList,
  }) : super(key: key); // Передаем key в super

  @override
  _NameListPageState createState() => _NameListPageState();
}

class _NameListPageState extends State<NameListPage> {
  // Текущий список статусов, который будет обновляться динамически
  List<String> _currentStatusOptions = [];
  List<String> _currentRankOptions = [];

  List<Map<String, dynamic>> _names = [];
  late DatabaseHelper _dbHelper;

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Имя не может быть пустым';
    }

    // Регулярное выражение для проверки, что строка состоит из одного слова на русском языке
    final regex = RegExp(r'^[А-Яа-яЁё]+$');
    if (!regex.hasMatch(value.trim())) {
      return 'Имя должно состоять из одного слова на русском языке. Проверьте, что имя не содержит пробелов или других символов.';
    }

    return null; // Валидация пройдена
  }

  @override
  void initState() {
    super.initState();
    _dbHelper = DatabaseHelper();
    _loadNames();
  }

  // Добавляем слушатель изменений настроек
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<Settings>(context);
    settings.addListener(_loadNames); // Перезагружаем имена при изменении настроек
  }

  @override
  void dispose() {
    final settings = Provider.of<Settings>(context, listen: false);
    settings.removeListener(_loadNames); // Важно убрать слушатель при уничтожении
    super.dispose();
  }

  Future<void> _loadNames() async {
    final settings = Provider.of<Settings>(context, listen: false);
    final names = await _dbHelper.loadNames(widget.nameList['id'], settings.sortType);
    setState(() {
      _names = List<Map<String, dynamic>>.from(names); // Создаем изменяемую копию
    });
  }

  Future<void> _addName(String name, int gender, int statusId, int rankId, String? endDate, String? deathDate) async {
    await widget.onAddName(name, gender, statusId, rankId, endDate, deathDate);
    await _loadNames();
  }

  Future<void> _editName(int nameId, String newName, int gender, int statusId, int rankId, String? endDate, String? deathDate) async {
    // Получаем текущее имя
    final name = _names.firstWhere((name) => name['id'] == nameId);
    final currentName = name['name'];
    final currentGender = name['gender'];
    final currentStatus = name['status_id'];
    final currentRank = name['rank_id'];
    final currentEndDate = name['end_date'];
    final currentDeathDate = name['death_date'];

    // Форматируем новое имя: первая буква заглавная, остальные маленькие
    String formattedName = newName.trim();
    formattedName = formattedName[0].toUpperCase() + formattedName.substring(1).toLowerCase();

    // Преобразуем оба имени в нижний регистр и сравниваем
    if (formattedName.toLowerCase() != currentName.toLowerCase()||
        gender != currentGender ||
        statusId != currentStatus ||
        rankId != currentRank ||
        currentEndDate != endDate ||
        currentDeathDate != deathDate) {
      // Если данные изменились, вызываем метод редактирования
      await widget.onEditName(nameId, formattedName, gender, statusId, rankId, endDate, deathDate);
      await _loadNames(); // Перезагружаем имена
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<Settings>(context);
    String frameImage = widget.nameList['type'] == 0
        ? 'assets/images/health_frame_title.png'
        : 'assets/images/repose_frame_title.png';

    // Получаем размеры экрана
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Устанавливаем размеры контейнера в зависимости от размера экрана
    double containerWidth = screenWidth * 0.5; // 50% от ширины экрана
    double containerHeight = screenHeight * 0.1; // 10% от высоты экрана

    Color lineColor = widget.nameList['type'] == 0 ? Colors.red : Colors.blue;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: 40.0,
              bottom: 70.0,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onLongPress: () {
                            _showEditTitleDialog(context, widget.nameList['title']);
                          },
                          child: Text(
                            widget.nameList['title'],
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          _showEditTitleDialog(context, widget.nameList['title']);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _showDeleteListDialog(context);
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  height: containerHeight,
                  width: containerWidth,
                  child: Image.asset(frameImage),
                ),
                Expanded(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: ListView.builder(
                      itemCount: _names.length,
                      itemBuilder: (context, index) {
                        final name = _names[index];
                        final status = name['status_id']; // Получаем статус, если он есть
                        final rank = name['rank_id']; // Получаем сан, если он есть
                        final endDate = name['end_date'] as String?; // Получаем дату окончания

                        // Получаем полный или сокращенный вариант в зависимости от настройки
                        final statusText = settings.useShortNames
                            ? findOptionById(status).short
                            : findOptionById(status).full;

                        final rankText = settings.useShortNames
                            ? findOptionById(rank).short
                            : findOptionById(rank).full;
                        return Dismissible(
                          key: ValueKey(name['id']), // Используем ValueKey
                          direction: DismissDirection.horizontal,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.only(left: 16.0),
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                          secondaryBackground: Container(
                            color: Colors.blue,
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 16.0),
                            child: Icon(Icons.edit, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              bool? confirm = await _showDeleteConfirmDialog(context);
                              return confirm == true;
                            } else if (direction == DismissDirection.endToStart) {
                              _showEditDialog(context, name['id'], name['name']);
                              return false;
                            }
                            return false;
                          },
                          onDismissed: (direction) {
                            setState(() {
                              _names.removeAt(index); // Удаляем элемент из изменяемого списка
                            });
                            widget.onDeleteName(name['id']); // Удаляем элемент из базы данных
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    ListTile(
                                      title: Text(
                                        [
                                          if (statusText.isNotEmpty) statusText,
                                          if (rankText.isNotEmpty)
                                            statusText.isNotEmpty
                                                ? rankText[0].toLowerCase() + rankText.substring(1) // Если статус есть, начинаем с маленькой буквы
                                                : rankText, // Если статуса нет, оставляем как есть
                                          name['name'],
                                        ].join(' '),
                                        style: TextStyle(
                                          fontSize: Provider.of<Settings>(context).fontSize,
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.grey
                                              : null,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      onLongPress: () {
                                        _showEditDialog(context, name['id'], name['name']);
                                      },
                                    ),
                                    if (endDate != null)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4.0),
                                        child: Text(
                                          'Конец поминовения: ${DateFormat('dd.MM.yyyy').format(DateTime.parse(endDate))}',
                                          style: TextStyle(
                                            fontSize: 12, // Мелкий шрифт
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? lineColor.withOpacity(0.5) // Нежно белый в темной теме
                                                : lineColor.withOpacity(0.7), // Темный с прозрачностью в светлой теме
                                            fontStyle: FontStyle.italic, // Курсив для дополнительной изящности
                                          ),
                                        ),
                                      ),
                                    Container(
                                      height: 2.0,
                                      color: lineColor,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _showAddNameDialog(context);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(8.0),
                            color: Colors.transparent,
                          ),
                          child: Text(
                            "Добавить имя",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        "Имя пишется в Родительном падеже",
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Удалить имя'),
          content: Text('Вы уверены, что хотите удалить это имя?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Удалить'),
            ),
          ],
        );
      },
    ) ??
        Future.value(false);
  }

  void _updateStatusOptions(int listType, int gender) {
    if (listType == 0) { // О здравии
      _currentStatusOptions = gender == 1
          ? _healthStatusMale.map((opt) => opt.full).toList()
          : _healthStatusFemale.map((opt) => opt.full).toList();
    } else { // Об упокоении
      _currentStatusOptions = gender == 1
          ? _reposeStatusMale.map((opt) => opt.full).toList()
          : _reposeStatusFemale.map((opt) => opt.full).toList();
    }

    // Обновляем список сана
    _currentRankOptions = gender == 1
        ? _rankOptionsMale.map((opt) => opt.full).toList()
        : _rankOptionsFemale.map((opt) => opt.full).toList();
  }

  void _showAddNameDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>(); // Ключ для управления состоянием формы
    final nameController = TextEditingController();

    bool showDeathDatePicker = false;  // Показывать ли выбор даты смерти

    int selectedGender = 1; // По умолчанию выбран мужской пол
    String? selectedStatus;
    String? selectedRank;
    DateTime? selectedDate;
    DateTime? selectedDeathDate;

    // Инициализируем список статусов в зависимости от типа списка
    _updateStatusOptions(widget.nameList['type'], selectedGender);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Добавить имя'),
              content: SingleChildScrollView(
              // Обработка прокрутки
                child: Container(
                  width: double.maxFinite, // Задаем максимальную ширину диалога
                  child: Form(
                    key: _formKey, // Подключаем ключ формы
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Позволяем колонке занимать минимальную высоту
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: 'Введите имя',
                            errorStyle: TextStyle(color: Colors.red), // Стиль текста ошибки
                            errorMaxLines: 5, // Разрешаем перенос текста ошибки на 5 строк
                          ),
                          validator: _validateName,
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: selectedGender,
                          decoration: InputDecoration(labelText: 'Пол'),
                          items: [
                            DropdownMenuItem(value: 1, child: Text('Мужской')),
                            DropdownMenuItem(value: 0, child: Text('Женский')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedGender = value!;
                              _updateStatusOptions(widget.nameList['type'], selectedGender);
                              // Сбрасываем выбранные статус и ранг при изменении пола
                              selectedStatus = null;
                              selectedRank = null;
                            });
                          },
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: InputDecoration(labelText: 'Статус'),
                          items: _currentStatusOptions.map((status) {
                            return DropdownMenuItem(
                              value: status.isEmpty ? null : status,
                              child: Text(status.isEmpty ? 'Не выбрано' : status),
                            );
                          }).toList(),
                          onChanged: (value) {
                            final statusId = findOptionByName(value).id;
                            setState(() {
                              selectedStatus = value;
                              // Показываем выбор даты смерти для новопреставленных
                              showDeathDatePicker = statusId == 13 || statusId == 16;
                              if (showDeathDatePicker && selectedDeathDate == null) {
                                selectedDeathDate = DateTime.now();  // По умолчанию текущая дата
                              }
                            });
                          },
                        ),
                        SizedBox(height: 16),
                        if (showDeathDatePicker)
                          ListTile(
                            title: Text(
                              selectedDeathDate == null
                                  ? 'Дата смерти:'
                                  : 'Дата смерти: ${DateFormat('dd.MM.yyyy').format(selectedDeathDate!)}',
                            ),
                            trailing: Icon(Icons.calendar_today),
                            onTap: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDeathDate ?? DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  selectedDeathDate = pickedDate;
                                });
                              }
                            },
                          ),
                        DropdownButtonFormField<String>(
                          value: selectedRank,
                          decoration: InputDecoration(labelText: 'Сан'),
                          items: _currentRankOptions.map((rank) {
                            return DropdownMenuItem(
                              value: rank.isEmpty ? null : rank,
                              child: Text(rank.isEmpty ? 'Не выбрано' : rank),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedRank = value;
                            });
                          },
                        ),
                        SizedBox(height: 16),
                        ListTile(
                          title: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              selectedDate == null
                                  ? 'Поминать до:'
                                  : 'Поминать до: ${DateFormat('dd.MM.yyyy').format(selectedDate!)}',
                              style: TextStyle(
                                fontSize: 16, // Начальный размер шрифта
                              ),
                              maxLines: 1, // Гарантируем одну строку
                              overflow: TextOverflow.visible, // Позволяет изменять размер шрифта
                            ),
                          ),
                          trailing: Icon(Icons.calendar_today),
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                        ),
                        if (selectedDate != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                selectedDate = null;
                              });
                            },
                            child: Text('Удалить дату'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Проверяем валидацию
                    if (_formKey.currentState!.validate()) {
                      if (nameController.text.isNotEmpty) {
                        // Форматируем имя: первая буква заглавная, остальные маленькие
                        String formattedName = nameController.text.trim();
                        formattedName = formattedName[0].toUpperCase() +
                            formattedName.substring(1).toLowerCase();
                        _addName(
                            formattedName,
                            selectedGender,
                            findOptionByName(selectedStatus).id,
                            findOptionByName(selectedRank).id,
                            selectedDate?.toIso8601String().split('T')[0], // Формат YYYY-MM-DD
                            selectedDeathDate?.toIso8601String().split('T')[0],  // Добавляем дату смерти
                        );
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  child: Text('Добавить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, int nameId, String currentName) {
    final _formKey = GlobalKey<FormState>(); // Ключ для управления состоянием формы
    final nameController = TextEditingController(text: currentName);

    // Получаем текущие данные имени
    final name = _names.firstWhere((name) => name['id'] == nameId);
    int selectedGender = name['gender'] ?? 1; // По умолчанию мужской пол
    String? selectedStatus = findOptionById(name['status_id']).full;
    String? selectedRank = findOptionById(name['rank_id']).full;
    DateTime? selectedDate = name['end_date'] == null
        ? null
        : DateTime.parse(name['end_date']);
    DateTime? selectedDeathDate = name['death_date'] == null
        ? null
        : DateTime.parse(name['death_date']);
    bool showDeathDatePicker = name['status_id'] == 13 || name['status_id'] == 16;


    // Инициализируем список статусов в зависимости от типа списка
    _updateStatusOptions(widget.nameList['type'], selectedGender);

    // Проверяем, существует ли текущий статус в новом списке
    if (!_currentStatusOptions.contains(selectedStatus)) {
      selectedStatus = null; // Сбрасываем статус, если он не существует в новом списке
    }

    // Проверяем, существует ли текущий сан в новом списке
    if(!_currentRankOptions.contains(selectedRank)) {
      selectedRank = null;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Редактировать имя'),
              content: SingleChildScrollView(
                child: Container(
                  width: double.maxFinite,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: 'Введите новое имя',
                            errorStyle: TextStyle(color: Colors.red),
                            errorMaxLines: 5,
                          ),
                          validator: _validateName,
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: selectedGender,
                          decoration: InputDecoration(labelText: 'Пол'),
                          items: [
                            DropdownMenuItem(value: 1, child: Text('Мужской')),
                            DropdownMenuItem(value: 0, child: Text('Женский')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedGender = value!;
                              // Обновляем список статусов при изменении пола
                              _updateStatusOptions(widget.nameList['type'], selectedGender);

                              // Проверяем, существует ли текущий статус в новом списке
                              if (!_currentStatusOptions.contains(selectedStatus)) {
                                selectedStatus = null; // Сбрасываем статус, если он не существует в новом списке
                              }

                              // Проверяем, существует ли текущий сан в новом списке
                              if(!_currentRankOptions.contains(selectedRank)) {
                                selectedRank = null;
                              }
                            });
                          },
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedStatus?.isEmpty ?? true ? null : selectedStatus,
                          decoration: InputDecoration(labelText: 'Статус'),
                          items: [
                            // Явно добавляем вариант "Не выбрано" с value: null
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text('Не выбрано'),
                            ),
                            // Добавляем только непустые статусы
                            ..._currentStatusOptions.where((s) => s.isNotEmpty).map((status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            final statusId = findOptionByName(value).id;
                            setState(() {
                              selectedStatus = value;
                              // Показываем выбор даты смерти для новопреставленных
                              showDeathDatePicker = statusId == 13 || statusId == 16;
                              if (showDeathDatePicker && selectedDeathDate == null) {
                                selectedDeathDate = DateTime.now();  // По умолчанию текущая дата
                              }
                            });
                          },
                        ),
                        SizedBox(height: 16),
                        if (showDeathDatePicker)
                          ListTile(
                            title: Text(
                              selectedDeathDate == null
                                  ? 'Дата смерти:'
                                  : 'Дата смерти: ${DateFormat('dd.MM.yyyy').format(selectedDeathDate!)}',
                            ),
                            trailing: Icon(Icons.calendar_today),
                            onTap: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDeathDate ?? DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  selectedDeathDate = pickedDate;
                                });
                              }
                            },
                          ),
                        DropdownButtonFormField<String>(
                          value: selectedRank?.isEmpty ?? true ? null : selectedRank,
                          decoration: InputDecoration(labelText: 'Сан'),
                          items: [
                            // Явно добавляем вариант "Не выбрано" с value: null
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text('Не выбрано'),
                            ),
                            // Добавляем только непустые статусы
                            ..._currentRankOptions.where((s) => s.isNotEmpty).map((rank) {
                              return DropdownMenuItem<String>(
                                value: rank,
                                child: Text(rank),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedRank = value;
                            });
                            },
                        ),
                        SizedBox(height: 16),
                        ListTile(
                          title: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              selectedDate == null
                                  ? 'Поминать до:'
                                  : 'Поминать до: ${DateFormat('dd.MM.yyyy').format(selectedDate!)}',
                              style: TextStyle(
                                fontSize: 16, // Начальный размер шрифта
                              ),
                              maxLines: 1, // Гарантируем одну строку
                              overflow: TextOverflow.visible, // Позволяет изменять размер шрифта
                            ),
                          ),
                          trailing: Icon(Icons.calendar_today),
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDate = pickedDate;
                              });
                            }
                            },
                        ),
                        if (selectedDate != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                selectedDate = null;
                              });
                              },
                            child: Text('Удалить дату'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Проверяем валидацию перед сохранением
                    if (_formKey.currentState!.validate()) {
                      if (nameController.text.isNotEmpty) {
                        // Форматируем имя: первая буква заглавная, остальные маленькие
                        String formattedName = nameController.text.trim();
                        formattedName = formattedName[0].toUpperCase() +
                            formattedName.substring(1).toLowerCase();

                        // Вызываем метод редактирования имени с новыми параметрами
                        _editName(
                          nameId,
                          formattedName,
                          selectedGender,
                          findOptionByName(selectedStatus).id,
                          findOptionByName(selectedRank).id,
                          selectedDate?.toIso8601String().split('T')[0], // Формат YYYY-MM-DD
                          selectedDeathDate?.toIso8601String().split('T')[0],
                        );
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  child: Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditTitleDialog(BuildContext context, String currentTitle) {
    final titleController = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Редактировать название списка'),
          content: TextField(
            controller: titleController,
            decoration: InputDecoration(hintText: 'Введите новое название'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                widget.onEditTitle(titleController.text);
                Navigator.of(context).pop();
              },
              child: Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteListDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Удалить список'),
          content: Text('Вы уверены, что хотите удалить этот список?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                widget.onDeleteList();
                Navigator.of(context).pop();
              },
              child: Text('Удалить'),
            ),
          ],
        );
      },
    );
  }
}

// Страница новостей
class NewsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Новости'),
        actions: [
          // Иконка для переключения темы
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.wb_sunny // Иконка солнца для темной темы
                  : Icons.nightlight_round, // Иконка месяца для светлой темы
              color: Colors.grey,
            ),
            onPressed: () {
              final settings = Provider.of<Settings>(context, listen: false);
              settings.setThemeMode(
                Theme.of(context).brightness == Brightness.dark
                    ? ThemeMode.light // Переключаем на светлую тему
                    : ThemeMode.dark, // Переключаем на темную тему
              );
            },
          ),
          SizedBox(width: 8), // Отступ между иконкой и кнопкой настроек
          IconButton(
            onPressed: () {
              // Переход в страницу настроек
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
            icon: Icon(Icons.settings), // Значок настроек
          ),
        ],
        automaticallyImplyLeading: true, // Показывать иконку меню
      ),
      body: Center(child: Text('Здесь будут новости приложения')),
    );
  }
}

enum ListType { health, repose }

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<Settings>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Настройки')),
      body: Column(
        children: [
          ListTile(
            title: Text('Размер текста имен'),
            subtitle: Text('Выбранный размер: ${settings.fontSize.toInt()}'),
            trailing: SizedBox(
              width: 200,
              child: Slider(
                value: settings.fontSize,
                min: 10,
                max: 40,
                divisions: 30,
                // Количество шагов (40 - 10 = 30)
                label: settings.fontSize.toInt().toString(),
                onChanged: (value) {
                  settings.setFontSize(value);
                },
              ),
            ),
          ),
          ListTile(
            title: Text('Тема приложения'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min, // Чтобы Row занимал минимальное пространство
              children: [
                // Иконка луны (темная тема) слева от ползунка
                Icon(
                  Icons.wb_sunny, // Иконка для темной темы
                  color: Colors.grey,
                ),
                Switch(
                  value: settings.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    settings.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                  },
                ),
                // Иконка солнца (светлая тема) справа от ползунка
                Icon(
                  Icons.nightlight_round, // Иконка для светлой темы
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          ListTile(
            title: Text('Использовать сокращенные имена'),
            trailing: Switch(
              value: settings.useShortNames,
              onChanged: (value) {
                settings.setUseShortNames(value);
              },
            ),
          ),
          ListTile(
            title: Text('Сортировка имен'),
            subtitle: Text(_getSortTypeDescription(settings.sortType)),
            trailing: DropdownButton<SortType>(
              value: settings.sortType,
              onChanged: (value) {
                if (value != null) {
                  settings.setSortType(value);
                }
              },
              items: [
                DropdownMenuItem(
                  value: SortType.none,
                  child: Text('Без сортировки'),
                ),
                DropdownMenuItem(
                  value: SortType.name,
                  child: Text('По имени'),
                ),
                DropdownMenuItem(
                  value: SortType.rankId,
                  child: Text('По сану'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSortTypeDescription(SortType type) {
    switch (type) {
      case SortType.none:
        return 'Текущая: Без сортировки';
      case SortType.name:
        return 'Текущая: По имени';
      case SortType.rankId:
        return 'Текущая: По сану';
      default:
        return '';
    }
  }
}

// Списки статусов для "о здравии"
final List<NameOption> _healthStatusMale = [
  NameOption.empty(),
  NameOption(full: 'Болящего', short: 'Бол.', id: 1),
  NameOption(full: 'Тяжело болящего', short: 'Т. бол.', id: 2),
  NameOption(full: 'Путешествующего', short: 'Пут.', id: 3),
  NameOption(full: 'Заключенного', short: 'Закл.', id: 4),
  NameOption(full: 'Заблудшего', short: 'Забл.', id: 5),
];

final List<NameOption> _healthStatusFemale = [
  NameOption.empty(),
  NameOption(full: 'Болящей', short: 'Бол.', id: 6),
  NameOption(full: 'Тяжело болящей', short: 'Т. бол.', id: 7),
  NameOption(full: 'Путешествующей', short: 'Пут.', id: 8),
  NameOption(full: 'Заключенной', short: 'Закл.', id: 9),
  NameOption(full: 'Заблудшей', short: 'Забл.', id: 10),
  NameOption(full: 'Непраздной', short: 'Непразд.', id: 11),
];

// Списки статусов для "об упокоении"
final List<NameOption> _reposeStatusMale = [
  NameOption.empty(),
  NameOption(full: 'Убиенного', short: 'Уб.', id: 12),
  NameOption(full: 'Новопреставленного', short: 'Н.п.', id: 13),
  NameOption(full: 'Приснопоминаемого', short: 'П.п.', id: 14),
];

final List<NameOption> _reposeStatusFemale = [
  NameOption.empty(),
  NameOption(full: 'Убиенной', short: 'Уб.', id: 15),
  NameOption(full: 'Новопреставленной', short: 'Н.п.', id: 16),
  NameOption(full: 'Приснопоминаемой', short: 'П.п..', id: 17),
];

// Список сана для мужского пола
final List<NameOption> _rankOptionsMale = [
  NameOption.empty(),
  NameOption(full: 'Отрока', short: 'Отр.', id: 46),
  NameOption(full: 'Юноши', short: 'Юн.', id: 47),
  NameOption(full: 'Младенца', short: 'Мл.', id: 48),
  NameOption(full: 'Воина', short: 'В.', id: 49),
  NameOption(full: 'Патриарха', short: 'Патр.', id: 18),
  NameOption(full: 'Схимитрополита', short: 'Схимитр.', id: 19),
  NameOption(full: 'Митрополита', short: 'Митр.', id: 20),
  NameOption(full: 'Схиархиепископа', short: 'Схиархиеп.', id: 21),
  NameOption(full: 'Архиепископа', short: 'Архиеп.', id: 22),
  NameOption(full: 'Схиепископа', short: 'Схиеп.', id: 23),
  NameOption(full: 'Епископа', short: 'Еп.', id: 24),
  NameOption(full: 'Схиархимандрита', short: 'Схиархим.', id: 25),
  NameOption(full: 'Архимандрита', short: 'Архим.', id: 26),
  NameOption(full: 'Протопресвитера', short: 'Протопр.', id: 27),
  NameOption(full: 'Схиигумена', short: 'Схиигум.', id: 28),
  NameOption(full: 'Игумена', short: 'Игум.', id: 29),
  NameOption(full: 'Протоиерея', short: 'Прот.', id: 30),
  NameOption(full: 'Иеросхимонаха', short: 'Иеросхим.', id: 31),
  NameOption(full: 'Иеромонаха', short: 'Иером.', id: 32),
  NameOption(full: 'Иерея', short: 'Иер.', id: 33),
  NameOption(full: 'Схиархидиакона', short: 'Схиархидиак.', id: 34),
  NameOption(full: 'Архидиакона', short: 'Архидиак.', id: 35),
  NameOption(full: 'Протодиакона', short: 'Протодиак.', id: 36),
  NameOption(full: 'Схииеродиакона', short: 'Схииеродиак.', id: 37),
  NameOption(full: 'Иеродиакона', short: 'Иеродиак.', id: 38),
  NameOption(full: 'Диакона', short: 'Диак.', id: 39),
  NameOption(full: 'Схимонаха', short: 'Схимон.', id: 40),
  NameOption(full: 'Монаха', short: 'Мон.', id: 41),
  NameOption(full: 'Инока', short: 'Инок.', id: 42),
  NameOption(full: 'Иподиакона', short: 'Ипод.', id: 43),
  NameOption(full: 'Послушника', short: 'Посл.', id: 44),
  NameOption(full: 'Чтеца', short: 'Чтец.', id: 45),
];

// Список сана для женского пола
final List<NameOption> _rankOptionsFemale = [
  NameOption.empty(),
  NameOption(full: 'Девицы', short: 'Дев', id: 57),
  NameOption(full: 'Отроковицы', short: 'Отр.', id: 58),
  NameOption(full: 'Младенца', short: 'Мл.', id: 59),
  NameOption(full: 'Воина', short: 'В.', id: 60),
  NameOption(full: 'Схиигуменьи', short: 'Схиигум.', id: 50),
  NameOption(full: 'Игуменьи', short: 'Игум.', id: 51),
  NameOption(full: 'Схимонахини', short: 'Схимон.', id: 52),
  NameOption(full: 'Монахини', short: 'Мон.', id: 53),
  NameOption(full: 'Инокини', short: 'Инок.', id: 54),
  NameOption(full: 'Матушки', short: 'Мат.', id: 55),
  NameOption(full: 'Послушницы', short: 'Посл.', id: 56),

];


NameOption findOptionById(int? id) {
  if (id == null) {
    return NameOption.empty();
  }
  return AppData.allOptionsList.firstWhere((opt) => opt.id == id,
      orElse: () => NameOption.empty());
}

NameOption findOptionByName(String? name) {
  if (name == null || name.isEmpty) {
    return NameOption.empty();
  }
  return AppData.allOptionsList.firstWhere((opt) => opt.full == name,
      orElse: () => NameOption.empty());
}

class NameOption {
  final String full;  // Полный вариант
  final String short; // Сокращенный вариант
  final int id;

  NameOption({required this.full, required this.short, required this.id});


  // Пустое значение
  static NameOption empty() => NameOption(full: '', short: '', id: 0);
}

class AppData {
  static late final List<NameOption> allOptionsList;

  static Future<void> initialize() async {
    allOptionsList = [
      ..._healthStatusMale,
      ..._healthStatusFemale,
      ..._reposeStatusMale,
      ..._reposeStatusFemale,
      ..._rankOptionsMale,
      ..._rankOptionsFemale
    ];
  }
}