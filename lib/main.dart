import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
          title: 'Мой приход. Помянник',
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
  Map<int, List<Map<String, dynamic>>> _namesCache = {}; // Кеш имен всех списков

  late DatabaseHelper _dbHelper;
  // Новые переменные для управления каруселью
  final ScrollController _carouselController = ScrollController();
  double _carouselOpacity = 0.0;
  bool _carouselVisible = false;

  final maxVisibleNames = 4; // Максимальное количество отображаемых имен
  double get containerHeight => MediaQuery.of(context).size.height * 0.1; // 10% высоты экрана
  double get itemHeight => MediaQuery.of(context).size.height * 0.05; // 5% высоты экрана

  @override
  void initState() {
    super.initState();
    _dbHelper = DatabaseHelper();
    _loadNameLists();
    // Инициализируем контроллер карусели
    _carouselController.addListener(() {
      // Можно добавить дополнительную логику при прокрутке
    });
  }


  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
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

  void _hideCarousel() {
    setState(() {
      _carouselOpacity = 0.0;
      _namesCache = {}; // Очищаем кеш!
    });
    Future.delayed(Duration(milliseconds: 300), () {
      setState(() {
        _carouselVisible = false;
      });
    });
  }

  void _showCarousel() {
    setState(() {
      _carouselVisible = true;
      if (_namesCache.isEmpty) {
        _preloadNames();
      }
      _carouselOpacity = 1.0;
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
  // Добавьте метод в _NameListHomeState:
  void _showDeveloperInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('О программе'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Приложение "Помянник"'),
            SizedBox(height: 8),
            Text('Версия: ${_dbHelper.appVersion}'),
            SizedBox(height: 8),
            Text('Разработчик: Диакон Артема'),
            SizedBox(height: 8),
            InkWell(
              onTap: () => _launchEmail(),
              child: Row(
                children: [
                  Text(
                    'Контакты: ',
                  ),
                  Text(
                    'moy.prikhod@internet.ru',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              )
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Закрыть'),
          ),
        ],
      ),
    );
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
        child: Column(
            children: [
              Expanded(
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
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _showDeveloperInfo(context);
                },
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Блок с информацией о разработчике
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'О программе',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1)))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    SizedBox(height: 8),
                    Text(
                      '© ${DateTime.now().year} Все права защищены',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ]
        ),
      ),
      body: Stack(
        children: [
          // Основной контент
          NotificationListener<ScrollNotification>(
            onNotification: (scrollNotification) {
              return false;
            },
            child: _buildMainContent(),
          ),

          // Полноэкранная карусель списков
          if (_carouselVisible)
            GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! > 5) {
                  _hideCarousel();
                }
              },
              onTap: _hideCarousel,
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 300),
                opacity: _carouselOpacity,
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + 20),
                      Text(
                        'Ваши списки',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: containerHeight + (maxVisibleNames + 1) * itemHeight,
                        child: PageView.builder(
                          controller: PageController(
                            viewportFraction: 0.4,
                            initialPage: _nameLists.length > 2 ? _getCurrentListIndex() + _nameLists.length * 1000 : _getCurrentListIndex(),
                          ),
                          physics: BouncingScrollPhysics(), // Добавляем эффект инерции и "отскока"
                          itemCount: _nameLists.length > 2 ? _nameLists.length * 2000 : _nameLists.length,
                          onPageChanged: (index) {
                            if (_nameLists.length > 2) {
                              index = index % _nameLists.length;
                            }
                            setState(() {
                              _currentListId = _nameLists[index]['id'];
                            });
                          },
                          itemBuilder: (context, index) {
                            if (_nameLists.length > 2) {
                              index = index % _nameLists.length;
                            }
                            final list = _nameLists[index];
                            final isCurrent = list['id'] == _currentListId;
                            final color = list['type'] == 0 ? Colors.red : Colors.blue;

                            return GestureDetector(
                              onTap: () {
                                _pageController.jumpToPage(index);
                                _hideCarousel();
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCurrent ? color : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: _buildListCard(list, color),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                      FloatingActionButton(
                        onPressed: _hideCarousel,
                        child: Icon(Icons.close),
                        backgroundColor: Colors.red,
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _preloadNames() async {
    final settings = Provider.of<Settings>(context, listen: false);
    Map<int, List<Map<String, dynamic>>> tempCache = {};

    for (var list in _nameLists) {
      tempCache[list['id']] =
      await _dbHelper.loadNames(list['id'], settings.sortType);
    }

    setState(() {
      _namesCache = tempCache;
    });
  }

  Widget _buildListCard(Map<String, dynamic> list, Color color) {
    final names = _namesCache[list['id']] ?? [];
    final remainingNames = max(names.length - maxVisibleNames, 0);

    final frameImage = list['type'] == 0
        ? 'assets/images/health_frame_title.png'
        : 'assets/images/repose_frame_title.png';
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min, // Важно для ограничения высоты
        children: [
          // Шапка с изображением и названием
          Container(
            height: MediaQuery.of(context).size.height * 0.07,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  frameImage,
                  height: 33, // Фиксированная высота изображения
                  fit: BoxFit.contain,
                ),
                Text(
                  list['title'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(height: 1, color: color),

          // Список имен с фиксированной высотой
          SizedBox(
            height: (maxVisibleNames + 1) * itemHeight,
            child: Column(
              children: [
                // Видимая часть списка
                Expanded(
                  child: ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: min(names.length, maxVisibleNames),
                    itemBuilder: (context, index) {
                      final name = names[index];
                      return Container(
                        height: itemHeight,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: color.withOpacity(0.7),
                            ),
                          ),
                        ),
                        child: Text(
                          [_getStatusText(name), name['name']].join(' '),
                          style: TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),

                // Счетчик оставшихся имен
                if (remainingNames > 0)
                  Container(
                    height: itemHeight,
                    alignment: Alignment.center,
                    child: Text(
                      'и ещё $remainingNames ${_getNounForm(remainingNames)}',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getCurrentListIndex() {
    if (_currentListId == null) return 0;
    return _nameLists.indexWhere((list) => list['id'] == _currentListId);
  }

  // Вспомогательная функция для склонения слова "имя"
  String _getNounForm(int number) {
    if (number % 100 >= 11 && number % 100 <= 14) {
      return 'имён';
    }

    switch (number % 10) {
      case 1: return 'имя';
      case 2:
      case 3:
      case 4: return 'имени';
      default: return 'имён';
    }
  }

  Widget _buildMainContent() {
    return _nameLists.isEmpty
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
          onShowCarousel: _showCarousel,  // Передаем методы
          onHideCarousel: _hideCarousel,
        );
      },
    );
  }

  String _getStatusText(Map<String, dynamic> name) {
    final statusId = name['status_id'];
    final rankId = name['rank_id'];

    // Получаем текстовые представления
    final statusText = statusId != null
        ? findOptionById(statusId).short
        : '';

    final rankText = rankId != null
        ? findOptionById(rankId).short
        : '';

    // Комбинируем результат
    final result = [statusText, rankText].where((s) => s.isNotEmpty).join(' ');

    return result.isNotEmpty ? result : '';
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

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'moy.prikhod@internet.ru',
      queryParameters: {
        'subject': 'Помянник:_обратная_связь',
        'body': 'Здравствуйте!', // Предзаполненный текст
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      // Если нет почтового клиента, показываем сообщение
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть почтовый клиент')),
      );
    }
  }
}

class NameListPage extends StatefulWidget {
  final Map<String, dynamic> nameList;
  final Function(String, int, int, int, String?, String?) onAddName;
  final Function(int, String, int, int, int, String?, String?) onEditName;
  final Function(int) onDeleteName;
  final Function(String) onEditTitle;
  final VoidCallback onDeleteList;
  final VoidCallback onShowCarousel;  // Новый колбэк
  final VoidCallback onHideCarousel;  // Новый колбэк

  // Добавляем key в конструктор
  NameListPage({
    Key? key, // Добавляем параметр key
    required this.nameList,
    required this.onAddName,
    required this.onEditName,
    required this.onDeleteName,
    required this.onEditTitle,
    required this.onDeleteList,
    required this.onShowCarousel,
    required this.onHideCarousel,
  }) : super(key: key); // Передаем key в super

  @override
  _NameListPageState createState() => _NameListPageState();
}

class _NameListPageState extends State<NameListPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Сохранять состояние
  bool _isButtonPressed = false;

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
    try {
      final settings = Provider.of<Settings>(context, listen: false);
      settings.removeListener(
          _loadNames); // Важно убрать слушатель при уничтожении
    } catch (_) {
      // Игнорируем ошибку, если контекст уже недействителен
    }
    super.dispose();
  }

  Future<void> _loadNames() async {
    if (!mounted) return; // Проверка, что виджет все еще в дереве

    final settings = Provider.of<Settings>(context, listen: false);
    final names = await _dbHelper.loadNames(widget.nameList['id'], settings.sortType);
    if (mounted) { // Дополнительная проверка перед setState
      setState(() {
        _names = List<Map<String, dynamic>>.from(names);
      });
    }
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
    super.build(context);
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
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) {
                          setState(() {
                            _isButtonPressed = true;
                          });
                        },
                        onTapUp: (_) {
                          setState(() {
                            _isButtonPressed = false;
                          });
                          _showAddNameDialog(context);
                        },
                        onTapCancel: () {
                          setState(() {
                            _isButtonPressed = false;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _isButtonPressed ? Colors.grey : Colors.blue,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                            color: _isButtonPressed ? Colors.blue : Colors.transparent,
                          ),
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              if (details.delta.dy < 0) {
                                widget.onShowCarousel();
                              } else if (details.delta.dy > 0) {
                                widget.onHideCarousel();
                              }
                            },
                            child: Text(
                              "Добавить имя",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _isButtonPressed ? Colors.grey : Colors.blue,
                              ),
                              textAlign: TextAlign.center,
                            ),
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
    final TextEditingController _typeAheadController = TextEditingController();

    bool showDeathDatePicker = false;  // Показывать ли выбор даты смерти

    int selectedGender = 1; // По умолчанию выбран мужской пол
    String? selectedStatus;
    String? selectedRank;
    DateTime? selectedDate;
    DateTime? selectedDeathDate;

    Timer? _genderSelectionTimer;
    bool showGenderSelection = false;
    String? _lastSelectedSuggestion;

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
                        TypeAheadField<MenologyName>(
                          controller: _typeAheadController,
                          suggestionsCallback: (pattern) {
                            if (pattern.isEmpty) {
                              return [];
                            }
                            return _menologyNames.where((name) =>
                                name.name.toLowerCase().contains(pattern.toLowerCase())
                            ).toList();
                          },
                          builder: (context, controller, focusNode) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Введите имя',
                                errorStyle: TextStyle(color: Colors.red), // Стиль текста ошибки
                                errorMaxLines: 5, // Разрешаем перенос текста ошибки на 5 строк
                              ),
                              validator: _validateName,
                              onChanged: (value) {
                                // Отменяем предыдущий таймер, если он был
                                _genderSelectionTimer?.cancel();

                                // Если поле пустое, скрываем выбор пола
                                if (value.isEmpty) {
                                  setState(() {
                                    showGenderSelection = false;
                                    _lastSelectedSuggestion = null;
                                  });
                                  return;
                                }

                                // Если текущий текст не совпадает с последним выбранным из подсказок
                                if (_lastSelectedSuggestion != null &&
                                    value != _lastSelectedSuggestion) {
                                  setState(() {
                                    _lastSelectedSuggestion = null;
                                  });
                                }

                                _genderSelectionTimer = Timer(Duration(milliseconds: 500), () {
                                  final exactMatch = _menologyNames.any((name) =>
                                  name.name.toLowerCase() == value.toLowerCase());

                                  setState(() {
                                    showGenderSelection = !exactMatch && _lastSelectedSuggestion == null;
                                  });
                                });
                              },
                            );
                          },
                          itemBuilder: (context, MenologyName suggestion) {
                            return ListTile(
                              title: Text(suggestion.name),
                              subtitle: Text(suggestion.gender == 1 ? 'Мужское имя' : 'Женское имя'),
                            );
                          },
                          onSelected: (MenologyName selected) {
                            _typeAheadController.text = selected.name;
                            setState(() {
                              selectedGender = selected.gender;
                              // Обновляем список статусов при изменении пола
                              _updateStatusOptions(widget.nameList['type'], selectedGender);
                              showGenderSelection = false; // Скрываем выбор пола после выбора из подсказки
                              _lastSelectedSuggestion = selected.name; // Присавиваем значения выбранного из подсказки имени

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
                          // Ничего не отображает, если список пуст
                          emptyBuilder: (context) => SizedBox.shrink(),
                        ),
                        SizedBox(height: 16),
                        if (showGenderSelection) ...[
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
                                selectedStatus = null;
                                selectedRank = null;
                              });
                            },
                          ),
                          SizedBox(height: 16),
                        ],
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
                      final name = _typeAheadController.text.trim();
                      if (name.isNotEmpty) {
                        // Форматируем имя: первая буква заглавная, остальные маленькие
                        String formattedName = name[0].toUpperCase() +
                            name.substring(1).toLowerCase();
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
    final TextEditingController _typeAheadController = TextEditingController(text: currentName);

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
                        TypeAheadField<MenologyName>(
                          controller: _typeAheadController,
                          suggestionsCallback: (pattern) {
                            if (pattern.isEmpty) {
                              return [];
                            }
                            return _menologyNames.where((name) =>
                                name.name.toLowerCase().contains(pattern.toLowerCase())
                            ).toList();
                          },
                          builder: (context, controller, focusNode) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Введите новое имя',
                                errorStyle: TextStyle(color: Colors.red), // Стиль текста ошибки
                                errorMaxLines: 5, // Разрешаем перенос текста ошибки на 5 строк
                              ),
                              validator: _validateName,
                            );
                          },
                          itemBuilder: (context, MenologyName suggestion) {
                            return ListTile(
                              title: Text(suggestion.name),
                              subtitle: Text(suggestion.gender == 1 ? 'Мужское имя' : 'Женское имя'),
                            );
                          },
                          onSelected: (MenologyName selected) {
                            _typeAheadController.text = selected.name;
                            setState(() {
                              selectedGender = selected.gender;
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
                          emptyBuilder: (context) {
                            // Ничего не отображает, если список пуст
                            return SizedBox.shrink();
                          },
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
                      final name = _typeAheadController.text.trim();
                      if (name.isNotEmpty) {
                        // Форматируем имя: первая буква заглавная, остальные маленькие
                        String formattedName = name[0].toUpperCase() +
                            name.substring(1).toLowerCase();

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

class MenologyName {
  late String name;
  late int gender;

  MenologyName(this.name, this.gender);
  bool matches(String query) {
    return name.toLowerCase().contains(query.toLowerCase());
  }
}

final List<MenologyName> _menologyNames = [
  MenologyName("Аарона", 1),
  MenologyName("Або", 1),
  MenologyName("Аввакира", 1),
  MenologyName("Аввакума", 1),
  MenologyName("Августина", 1),
  MenologyName("Авда", 1),
  MenologyName("Авделая", 1),
  MenologyName("Авдиеса", 1),
  MenologyName("Авдиисуса", 1),
  MenologyName("Авдия", 1),
  MenologyName("Авдикия", 1),
  MenologyName("Авдифакса", 1),
  MenologyName("Авдона", 1),
  MenologyName("Авеля", 1),
  MenologyName("Авенира", 1),
  MenologyName("Аверкия", 1),
  MenologyName("Авива", 1),
  MenologyName("Авима", 1),
  MenologyName("Авксентия", 1),
  MenologyName("Авксивия", 1),
  MenologyName("Авкта", 1),
  MenologyName("Авраама", 1),
  MenologyName("Аврамия", 1),
  MenologyName("Аврикия", 1),
  MenologyName("Автонома", 1),
  MenologyName("Авудима", 1),
  MenologyName("Авундия", 1),
  MenologyName("Агава", 1),
  MenologyName("Агавва", 1),
  MenologyName("Агапия", 1),
  MenologyName("Агапиона", 1),
  MenologyName("Агапита", 1),
  MenologyName("Агафангела", 1),
  MenologyName("Агафодора", 1),
  MenologyName("Агафона", 1),
  MenologyName("Агафоника", 1),
  MenologyName("Агафопода", 1),
  MenologyName("Агафопуса", 1),
  MenologyName("Аггея", 1),
  MenologyName("Аглаия", 1),
  MenologyName("Агна", 1),
  MenologyName("Агриппа", 1),
  MenologyName("Адама", 1),
  MenologyName("Адарнасе", 1),
  MenologyName("Адриана", 1),
  MenologyName("Аетия", 1),
  MenologyName("Аза", 1),
  MenologyName("Азадана", 1),
  MenologyName("Азария", 1),
  MenologyName("Азата", 1),
  MenologyName("Аифала", 1),
  MenologyName("Акакия", 1),
  MenologyName("Акепсия", 1),
  MenologyName("Акепсима", 1),
  MenologyName("Акила", 1),
  MenologyName("Акиндина", 1),
  MenologyName("Аксия", 1),
  MenologyName("Акутиона", 1),
  MenologyName("Албана", 1),
  MenologyName("Александра", 1),
  MenologyName("Алексия", 1),
  MenologyName("Алима", 1),
  MenologyName("Алипия", 1),
  MenologyName("Алония", 1),
  MenologyName("Алфея", 1),
  MenologyName("Алфия", 1),
  MenologyName("Альвиана", 1),
  MenologyName("Амандина", 1),
  MenologyName("Амвросия", 1),
  MenologyName("Аммона", 1),
  MenologyName("Аммонафа", 1),
  MenologyName("Аммония", 1),
  MenologyName("Аммуна", 1),
  MenologyName("Амона", 1),
  MenologyName("Амонита", 1),
  MenologyName("Амоса", 1),
  MenologyName("Амплия", 1),
  MenologyName("Амфиана", 1),
  MenologyName("Амфилохия", 1),
  MenologyName("Анаклета", 1),
  MenologyName("Анания", 1),
  MenologyName("Анастасия", 1),
  MenologyName("Анатолия", 1),
  MenologyName("Ангелия", 1),
  MenologyName("Ангеляра", 1),
  MenologyName("Ангия", 1),
  MenologyName("Андрея", 1),
  MenologyName("Андроника", 1),
  MenologyName("Анекта", 1),
  MenologyName("Анемподиста", 1),
  MenologyName("Аниана", 1),
  MenologyName("Аникиты", 1),
  MenologyName("Анина", 1),
  MenologyName("Антилина", 1),
  MenologyName("Антиоха", 1),
  MenologyName("Антипы", 1),
  MenologyName("Антипатра", 1),
  MenologyName("Антония", 1),
  MenologyName("Антонина", 1),
  MenologyName("Анувия", 1),
  MenologyName("Анфа", 1),
  MenologyName("Анфима", 1),
  MenologyName("Анфира", 1),
  MenologyName("Анфона", 1),
  MenologyName("Апеллия", 1),
  MenologyName("Аполлинария", 1),
  MenologyName("Аполлона", 1),
  MenologyName("Аполлония", 1),
  MenologyName("Аполлоса", 1),
  MenologyName("Апостола", 1),
  MenologyName("Апрониана", 1),
  MenologyName("Аргира", 1),
  MenologyName("Ардалиона", 1),
  MenologyName("Арефы", 1),
  MenologyName("Ариана", 1),
  MenologyName("Ария", 1),
  MenologyName("Ариса", 1),
  MenologyName("Аристарха", 1),
  MenologyName("Аристида", 1),
  MenologyName("Аристиона", 1),
  MenologyName("Аристовула", 1),
  MenologyName("Аристоклия", 1),
  MenologyName("Аркадия", 1),
  MenologyName("Ароноса", 1),
  MenologyName("Арпилы", 1),
  MenologyName("Арсакия", 1),
  MenologyName("Арсения", 1),
  MenologyName("Артемы", 1),
  MenologyName("Артемия", 1),
  MenologyName("Артемона", 1),
  MenologyName("Архелая", 1),
  MenologyName("Архилия", 1),
  MenologyName("Архиппа", 1),
  MenologyName("Арчила", 1),
  MenologyName("Асинкрита", 1),
  MenologyName("Асира", 1),
  MenologyName("Аскалона", 1),
  MenologyName("Асклипиада", 1),
  MenologyName("Асклипия", 1),
  MenologyName("Асклипиодота", 1),
  MenologyName("Астерия", 1),
  MenologyName("Астия", 1),
  MenologyName("Астиона", 1),
  MenologyName("Аттала", 1),
  MenologyName("Аттия", 1),
  MenologyName("Аттика", 1),
  MenologyName("Афанасия", 1),
  MenologyName("Афиногена", 1),
  MenologyName("Афинодора", 1),
  MenologyName("Афра", 1),
  MenologyName("Афраата", 1),
  MenologyName("Африкана", 1),
  MenologyName("Афродисия", 1),
  MenologyName("Аффония", 1),
  MenologyName("Ахаза", 1),
  MenologyName("Ахаика", 1),
  MenologyName("Ахилы", 1),
  MenologyName("Ахиллы", 1),
  MenologyName("Ахиллеса", 1),
  MenologyName("Ахиллия", 1),
  MenologyName("Ахия", 1),
  MenologyName("Ахмета", 1),
  MenologyName("Ацискла", 1),
  MenologyName("Августы", 0),
  MenologyName("Агапию", 0),
  MenologyName("Агафию", 0),
  MenologyName("Агафоклию", 0),
  MenologyName("Агафонику", 0),
  MenologyName("Аглаиду", 0),
  MenologyName("Агнию", 0),
  MenologyName("Агриппину", 0),
  MenologyName("Акилину", 0),
  MenologyName("Алевтину", 0),
  MenologyName("Александру", 0),
  MenologyName("Аллу", 0),
  MenologyName("Аммонарию", 0),
  MenologyName("Анастасию", 0),
  MenologyName("Анатолию", 0),
  MenologyName("Ангелину", 0),
  MenologyName("Андропелагию", 0),
  MenologyName("Анимаису", 0),
  MenologyName("Анисию", 0),
  MenologyName("Анну", 0),
  MenologyName("Антонину", 0),
  MenologyName("Антонию", 0),
  MenologyName("Анфису", 0),
  MenologyName("Анфию", 0),
  MenologyName("Анфусу", 0),
  MenologyName("Аполлинарию", 0),
  MenologyName("Апфию", 0),
  MenologyName("Аргиру", 0),
  MenologyName("Ариадну", 0),
  MenologyName("Арсению", 0),
  MenologyName("Артемию", 0),
  MenologyName("Архелаю", 0),
  MenologyName("Аскитрею", 0),
  MenologyName("Асклиаду", 0),
  MenologyName("Асклипиаду", 0),
  MenologyName("Асклипиодоту", 0),
  MenologyName("Асфею", 0),
  MenologyName("Афанасию", 0),
  MenologyName("Бидзина", 1),
  MenologyName("Боголепа", 1),
  MenologyName("Бона", 1),
  MenologyName("Бориса", 1),
  MenologyName("Бояна", 1),
  MenologyName("Бранко", 1),
  MenologyName("Библиаду", 0),
  MenologyName("Бландину", 0),
  MenologyName("Вавила", 1),
  MenologyName("Вадима", 1),
  MenologyName("Вакха", 1),
  MenologyName("Валента", 1),
  MenologyName("Валентина", 1),
  MenologyName("Валериана", 1),
  MenologyName("Валерия", 1),
  MenologyName("Ваптоса", 1),
  MenologyName("Варадата", 1),
  MenologyName("Варака", 1),
  MenologyName("Варахиила", 1),
  MenologyName("Варахия", 1),
  MenologyName("Варахисия", 1),
  MenologyName("Варвара", 1),
  MenologyName("Варипсава", 1),
  MenologyName("Варлаама", 1),
  MenologyName("Варнаву", 1),
  MenologyName("Варсаву", 1),
  MenologyName("Варсиса", 1),
  MenologyName("Варсонофия", 1),
  MenologyName("Варула", 1),
  MenologyName("Варуха", 1),
  MenologyName("Варфоломея", 1),
  MenologyName("Василида", 1),
  MenologyName("Василия", 1),
  MenologyName("Василиска", 1),
  MenologyName("Васоя", 1),
  MenologyName("Васса", 1),
  MenologyName("Вассиана", 1),
  MenologyName("Вата", 1),
  MenologyName("Вафусия", 1),
  MenologyName("Вахтисия", 1),
  MenologyName("Вендимиана", 1),
  MenologyName("Венедикта", 1),
  MenologyName("Венедима", 1),
  MenologyName("Венерия", 1),
  MenologyName("Вениамина", 1),
  MenologyName("Верка", 1),
  MenologyName("Ветрана", 1),
  MenologyName("Вианора", 1),
  MenologyName("Вивиана", 1),
  MenologyName("Викентия", 1),
  MenologyName("Виктора", 1),
  MenologyName("Викторина", 1),
  MenologyName("Вила", 1),
  MenologyName("Вирилада", 1),
  MenologyName("Виса", 1),
  MenologyName("Виссариона", 1),
  MenologyName("Вита", 1),
  MenologyName("Виталия", 1),
  MenologyName("Витимия", 1),
  MenologyName("Вифония", 1),
  MenologyName("Владимира", 1),
  MenologyName("Владислава", 1),
  MenologyName("Власия", 1),
  MenologyName("Воифа", 1),
  MenologyName("Вонифатия", 1),
  MenologyName("Восва", 1),
  MenologyName("Всеволода", 1),
  MenologyName("Вукашина", 1),
  MenologyName("Вукола", 1),
  MenologyName("Вячеслава", 1),
  MenologyName("Валентину", 0),
  MenologyName("Валерию", 0),
  MenologyName("Варвару", 0),
  MenologyName("Варсиму", 0),
  MenologyName("Варсонофию", 0),
  MenologyName("Василиссу", 0),
  MenologyName("Вассу", 0),
  MenologyName("Вауфу", 0),
  MenologyName("Вевею", 0),
  MenologyName("Веру", 0),
  MenologyName("Веронику", 0),
  MenologyName("Викторину", 0),
  MenologyName("Викторию", 0),
  MenologyName("Виринею", 0),
  MenologyName("Вриену", 0),
  MenologyName("Гаведда", 1),
  MenologyName("Гавиния", 1),
  MenologyName("Гавриила", 1),
  MenologyName("Гада", 1),
  MenologyName("Гаия", 1),
  MenologyName("Гая", 1),
  MenologyName("Галактиона", 1),
  MenologyName("Галика", 1),
  MenologyName("Галла", 1),
  MenologyName("Галликана", 1),
  MenologyName("Гамалиила", 1),
  MenologyName("Гедеона", 1),
  MenologyName("Геласия", 1),
  MenologyName("Гемелла", 1),
  MenologyName("Генефлия", 1),
  MenologyName("Геннадия", 1),
  MenologyName("Георгия", 1),
  MenologyName("Герасима", 1),
  MenologyName("Гервасия", 1),
  MenologyName("Геркулина", 1),
  MenologyName("Германа", 1),
  MenologyName("Гермогена", 1),
  MenologyName("Геронтия", 1),
  MenologyName("Гигантия", 1),
  MenologyName("Гимнасия", 1),
  MenologyName("Глеба", 1),
  MenologyName("Гликерия", 1),
  MenologyName("Гоброна", 1),
  MenologyName("Гонората", 1),
  MenologyName("Горазда", 1),
  MenologyName("Горгия", 1),
  MenologyName("Горгония", 1),
  MenologyName("Гордиана", 1),
  MenologyName("Гордия", 1),
  MenologyName("Григория", 1),
  MenologyName("Гурия", 1),
  MenologyName("Гаафу", 0),
  MenologyName("Гаиану", 0),
  MenologyName("Гаианию", 0),
  MenologyName("Галию", 0),
  MenologyName("Галину", 0),
  MenologyName("Гермогену", 0),
  MenologyName("Глафиру", 0),
  MenologyName("Гликерию", 0),
  MenologyName("Голиндуху", 0),
  MenologyName("Горгонию", 0),
  MenologyName("Гуделию", 0),
  MenologyName("Давида", 1),
  MenologyName("Давикта", 1),
  MenologyName("Дада", 1),
  MenologyName("Далмата", 1),
  MenologyName("Далматоя", 1),
  MenologyName("Дамаскина", 1),
  MenologyName("Дамиана", 1),
  MenologyName("Дана", 1),
  MenologyName("Данакта", 1),
  MenologyName("Даниила", 1),
  MenologyName("Дасия", 1),
  MenologyName("Диадоха", 1),
  MenologyName("Дидима", 1),
  MenologyName("Дия", 1),
  MenologyName("Дима", 1),
  MenologyName("Димитриана", 1),
  MenologyName("Димитрия", 1),
  MenologyName("Диодора", 1),
  MenologyName("Диодота", 1),
  MenologyName("Диомида", 1),
  MenologyName("Диона", 1),
  MenologyName("Дионисия", 1),
  MenologyName("Диоскора", 1),
  MenologyName("Дисана", 1),
  MenologyName("Дисидерия", 1),
  MenologyName("Дифила", 1),
  MenologyName("Довмонта", 1),
  MenologyName("Додо", 1),
  MenologyName("Доментиана", 1),
  MenologyName("Дометиана", 1),
  MenologyName("Дометия", 1),
  MenologyName("Домна", 1),
  MenologyName("Домнина", 1),
  MenologyName("Доната", 1),
  MenologyName("Доримедонта", 1),
  MenologyName("Дорофея", 1),
  MenologyName("Доса", 1),
  MenologyName("Досифея", 1),
  MenologyName("Драгутина", 1),
  MenologyName("Дракона", 1),
  MenologyName("Дукития", 1),
  MenologyName("Дула", 1),
  MenologyName("Дамару", 0),
  MenologyName("Дарию", 0),
  MenologyName("Девору", 0),
  MenologyName("Денахису", 0),
  MenologyName("Дикторину", 0),
  MenologyName("Динару", 0),
  MenologyName("Домну", 0),
  MenologyName("Домнику", 0),
  MenologyName("Домнину", 0),
  MenologyName("Дорофею", 0),
  MenologyName("Досифею", 0),
  MenologyName("Дросиду", 0),
  MenologyName("Дуклиду", 0),
  MenologyName("Евагрия", 1),
  MenologyName("Евангела", 1),
  MenologyName("Евареста", 1),
  MenologyName("Еввула", 1),
  MenologyName("Евгения", 1),
  MenologyName("Евграфа", 1),
  MenologyName("Евдемона", 1),
  MenologyName("Евдокима", 1),
  MenologyName("Евдоксия", 1),
  MenologyName("Евелписта", 1),
  MenologyName("Евиласия", 1),
  MenologyName("Евкарпия", 1),
  MenologyName("Евклея", 1),
  MenologyName("Евлалия", 1),
  MenologyName("Евлампия", 1),
  MenologyName("Евлогия", 1),
  MenologyName("Евмения", 1),
  MenologyName("Евникиана", 1),
  MenologyName("Евноика", 1),
  MenologyName("Евода", 1),
  MenologyName("Евпла", 1),
  MenologyName("Евпора", 1),
  MenologyName("Евпсихия", 1),
  MenologyName("Евсевия", 1),
  MenologyName("Евсевона", 1),
  MenologyName("Евсигния", 1),
  MenologyName("Евстафия", 1),
  MenologyName("Евстохия", 1),
  MenologyName("Евстратия", 1),
  MenologyName("Евсхимона", 1),
  MenologyName("Евтихиана", 1),
  MenologyName("Евтихия", 1),
  MenologyName("Евтропия", 1),
  MenologyName("Евфимия", 1),
  MenologyName("Евфрасия", 1),
  MenologyName("Евфросина", 1),
  MenologyName("Едесия", 1),
  MenologyName("Езекия", 1),
  MenologyName("Екдикия", 1),
  MenologyName("Екзуперанция", 1),
  MenologyName("Ексакустодиана", 1),
  MenologyName("Елеазара", 1),
  MenologyName("Елевсиппа", 1),
  MenologyName("Елевферия", 1),
  MenologyName("Елезвоя", 1),
  MenologyName("Елима", 1),
  MenologyName("Елисея", 1),
  MenologyName("Елладия", 1),
  MenologyName("Еллия", 1),
  MenologyName("Елпидия", 1),
  MenologyName("Елпидифора", 1),
  MenologyName("Емилиана", 1),
  MenologyName("Еноса", 1),
  MenologyName("Еноха", 1),
  MenologyName("Епагафа", 1),
  MenologyName("Епафраса", 1),
  MenologyName("Епафродита", 1),
  MenologyName("Епенета", 1),
  MenologyName("Епиктета", 1),
  MenologyName("Епимаха", 1),
  MenologyName("Епиподия", 1),
  MenologyName("Епифания", 1),
  MenologyName("Епполония", 1),
  MenologyName("Еразма", 1),
  MenologyName("Ераста", 1),
  MenologyName("Ерма", 1),
  MenologyName("Ермея", 1),
  MenologyName("Ермия", 1),
  MenologyName("Ермила", 1),
  MenologyName("Ерминингельда", 1),
  MenologyName("Ермиппа", 1),
  MenologyName("Ермогена", 1),
  MenologyName("Ермократа", 1),
  MenologyName("Ермолая", 1),
  MenologyName("Ероса", 1),
  MenologyName("Еспера", 1),
  MenologyName("Еферия", 1),
  MenologyName("Ефива", 1),
  MenologyName("Ефрема", 1),
  MenologyName("Еву", 0),
  MenologyName("Еванфию", 0),
  MenologyName("Еввулу", 0),
  MenologyName("Евгению", 0),
  MenologyName("Евдокию", 0),
  MenologyName("Евдоксию", 0),
  MenologyName("Евлалию", 0),
  MenologyName("Евлампию", 0),
  MenologyName("Евникию", 0),
  MenologyName("Евпраксию", 0),
  MenologyName("Евстолию", 0),
  MenologyName("Евтихию", 0),
  MenologyName("Евтропию", 0),
  MenologyName("Евфалию", 0),
  MenologyName("Евфимию", 0),
  MenologyName("Евфрасию", 0),
  MenologyName("Евфросинию", 0),
  MenologyName("Екатерину", 0),
  MenologyName("Екзуперию", 0),
  MenologyName("Елену", 0),
  MenologyName("Елесу", 0),
  MenologyName("Еликониду", 0),
  MenologyName("Елисавету", 0),
  MenologyName("Емилию", 0),
  MenologyName("Еннафу", 0),
  MenologyName("Епистимию", 0),
  MenologyName("Епихарию", 0),
  MenologyName("Ермионию", 0),
  MenologyName("Еротииду", 0),
  MenologyName("Есию", 0),
  MenologyName("Есфирь", 0),
  MenologyName("Завулона", 1),
  MenologyName("Закхея", 1),
  MenologyName("Занифа", 1),
  MenologyName("Захарию", 1),
  MenologyName("Зевина", 1),
  MenologyName("Зенона", 1),
  MenologyName("Зина", 1),
  MenologyName("Зиновия", 1),
  MenologyName("Зинона", 1),
  MenologyName("Зоила", 1),
  MenologyName("Зоровавеля", 1),
  MenologyName("Зосима", 1),
  MenologyName("Зотика", 1),
  MenologyName("Женевьеву", 0),
  MenologyName("Зинаиду", 0),
  MenologyName("Зиновию", 0),
  MenologyName("Злату", 0),
  MenologyName("Зою", 0),
  MenologyName("Иадора", 1),
  MenologyName("Иакинфа", 1),
  MenologyName("Иакисхола", 1),
  MenologyName("Иакова", 1),
  MenologyName("Иамвлиха", 1),
  MenologyName("Ианикиту", 1),
  MenologyName("Ианнуария", 1),
  MenologyName("Иасона", 1),
  MenologyName("Иафета", 1),
  MenologyName("Ивистиона", 1),
  MenologyName("Ивхириона", 1),
  MenologyName("Игафракса", 1),
  MenologyName("Игнатия", 1),
  MenologyName("Игоря", 1),
  MenologyName("Иегудиила", 1),
  MenologyName("Иезекииля", 1),
  MenologyName("Иеракса", 1),
  MenologyName("Иеремиила", 1),
  MenologyName("Иеремия", 1),
  MenologyName("Иеремии", 1),
  MenologyName("Иерона", 1),
  MenologyName("Иеронима", 1),
  MenologyName("Иерофея", 1),
  MenologyName("Иессея", 1),
  MenologyName("Иеффая", 1),
  MenologyName("Изяслава", 1),
  MenologyName("Иисуса", 1),
  MenologyName("Илария", 1),
  MenologyName("Илариона", 1),
  MenologyName("Илиана", 1),
  MenologyName("Илия", 1),
  MenologyName("Илиодора", 1),
  MenologyName("Илию", 1),
  MenologyName("Иллирика", 1),
  MenologyName("Индиса", 1),
  MenologyName("Инна", 1),
  MenologyName("Иннокентия", 1),
  MenologyName("Иоада", 1),
  MenologyName("Иоакима", 1),
  MenologyName("Иоанна", 1),
  MenologyName("Иоанникия", 1),
  MenologyName("Иоасафа", 1),
  MenologyName("Иова", 1),
  MenologyName("Иоиля", 1),
  MenologyName("Иону", 1),
  MenologyName("Иордана", 1),
  MenologyName("Иосифа", 1),
  MenologyName("Иосию", 1),
  MenologyName("Иотама", 1),
  MenologyName("Ипатия", 1),
  MenologyName("Иперехия", 1),
  MenologyName("Иперихия", 1),
  MenologyName("Ипполита", 1),
  MenologyName("Ираклемона", 1),
  MenologyName("Ираклида", 1),
  MenologyName("Ираклия", 1),
  MenologyName("Иринарха", 1),
  MenologyName("Иринея", 1),
  MenologyName("Ириния", 1),
  MenologyName("Иродиона", 1),
  MenologyName("Ирона", 1),
  MenologyName("Исаака", 1),
  MenologyName("Исаакия", 1),
  MenologyName("Исавра", 1),
  MenologyName("Исаию", 1),
  MenologyName("Исе", 1),
  MenologyName("Исидора", 1),
  MenologyName("Исихия", 1),
  MenologyName("Искоя", 1),
  MenologyName("Исмаила", 1),
  MenologyName("Иссахара", 1),
  MenologyName("Истукария", 1),
  MenologyName("Исхириона", 1),
  MenologyName("Иувеналия", 1),
  MenologyName("Иувентина", 1),
  MenologyName("Иуду", 1),
  MenologyName("Иулиана", 1),
  MenologyName("Иулия", 1),
  MenologyName("Иуста", 1),
  MenologyName("Иустина", 1),
  MenologyName("Иустиниана", 1),
  MenologyName("Иаиль", 0),
  MenologyName("Иарою", 0),
  MenologyName("Иерию", 0),
  MenologyName("Иерусалиму", 0),
  MenologyName("Иларию", 0),
  MenologyName("Индику", 0),
  MenologyName("Иоанну", 0),
  MenologyName("Иоанникию", 0),
  MenologyName("Иовиллу", 0),
  MenologyName("Ипомону", 0),
  MenologyName("Ираиду", 0),
  MenologyName("Ирину", 0),
  MenologyName("Исидору", 0),
  MenologyName("Иудифь", 0),
  MenologyName("Иулианию", 0),
  MenologyName("Иулитту", 0),
  MenologyName("Иулию", 0),
  MenologyName("Иунию", 0),
  MenologyName("Иусту", 0),
  MenologyName("Иустину", 0),
  MenologyName("Кайхосро", 1),
  MenologyName("Каллимаха", 1),
  MenologyName("Каллиника", 1),
  MenologyName("Каллиопия", 1),
  MenologyName("Каллиста", 1),
  MenologyName("Каллистрата", 1),
  MenologyName("Калуфа", 1),
  MenologyName("Калюмниоза", 1),
  MenologyName("Кандида", 1),
  MenologyName("Канида", 1),
  MenologyName("Кантидиана", 1),
  MenologyName("Кантидия", 1),
  MenologyName("Капика", 1),
  MenologyName("Капитона", 1),
  MenologyName("Кариона", 1),
  MenologyName("Карпа", 1),
  MenologyName("Картерия", 1),
  MenologyName("Кассиана", 1),
  MenologyName("Кастела", 1),
  MenologyName("Кастина", 1),
  MenologyName("Кастора", 1),
  MenologyName("Кастория", 1),
  MenologyName("Кастрикия", 1),
  MenologyName("Кастула", 1),
  MenologyName("Катерия", 1),
  MenologyName("Катуна", 1),
  MenologyName("Квинтилиана", 1),
  MenologyName("Келестина", 1),
  MenologyName("Келсия", 1),
  MenologyName("Кенсорина", 1),
  MenologyName("Керкана", 1),
  MenologyName("Кесария", 1),
  MenologyName("Кесаря", 1),
  MenologyName("Киндея", 1),
  MenologyName("Кинтиона", 1),
  MenologyName("Киона", 1),
  MenologyName("Кипра", 1),
  MenologyName("Киприана", 1),
  MenologyName("Кира", 1),
  MenologyName("Кириака", 1),
  MenologyName("Кирика", 1),
  MenologyName("Кирилла", 1),
  MenologyName("Кирина", 1),
  MenologyName("Кириона", 1),
  MenologyName("Кирмидола", 1),
  MenologyName("Кифу", 1),
  MenologyName("Клавдиана", 1),
  MenologyName("Клавдия", 1),
  MenologyName("Клеоника", 1),
  MenologyName("Клеопу", 1),
  MenologyName("Климента", 1),
  MenologyName("Кодрата", 1),
  MenologyName("Коинта", 1),
  MenologyName("Колумбана", 1),
  MenologyName("Комасия", 1),
  MenologyName("Коммода", 1),
  MenologyName("Кондрата", 1),
  MenologyName("Конкордия", 1),
  MenologyName("Конона", 1),
  MenologyName("Констанса", 1),
  MenologyName("Константина", 1),
  MenologyName("Констанция", 1),
  MenologyName("Коприя", 1),
  MenologyName("Корива", 1),
  MenologyName("Корнилия", 1),
  MenologyName("Корнута", 1),
  MenologyName("Короната", 1),
  MenologyName("Косму", 1),
  MenologyName("Крискента", 1),
  MenologyName("Крискентиана", 1),
  MenologyName("Криспа", 1),
  MenologyName("Кронида", 1),
  MenologyName("Кронина", 1),
  MenologyName("Крониона", 1),
  MenologyName("Ксанфа", 1),
  MenologyName("Ксанфия", 1),
  MenologyName("Ксенофонта", 1),
  MenologyName("Куарта", 1),
  MenologyName("Кукшу", 1),
  MenologyName("Кутония", 1),
  MenologyName("Куфия", 1),
  MenologyName("Каздою", 0),
  MenologyName("Калису", 0),
  MenologyName("Каллинику", 0),
  MenologyName("Каллиопию", 0),
  MenologyName("Каллисту", 0),
  MenologyName("Каллисфению", 0),
  MenologyName("Калодоту", 0),
  MenologyName("Капитолину", 0),
  MenologyName("Касинию", 0),
  MenologyName("Кассию", 0),
  MenologyName("Керкиру", 0),
  MenologyName("Кетевань", 0),
  MenologyName("Кикилию", 0),
  MenologyName("Киприану", 0),
  MenologyName("Киприну", 0),
  MenologyName("Киранну", 0),
  MenologyName("Киру", 0),
  MenologyName("Кириакию", 0),
  MenologyName("Кириену", 0),
  MenologyName("Кириллу", 0),
  MenologyName("Клавдию", 0),
  MenologyName("Клеопатру", 0),
  MenologyName("Конкордию", 0),
  MenologyName("Крискентию", 0),
  MenologyName("Ксанфиппу", 0),
  MenologyName("Ксению", 0),
  MenologyName("Лавра", 1),
  MenologyName("Лаврентия", 1),
  MenologyName("Лазаря", 1),
  MenologyName("Лампада", 1),
  MenologyName("Лаодикия", 1),
  MenologyName("Ларгия", 1),
  MenologyName("Льва", 1),
  MenologyName("Левия", 1),
  MenologyName("Левкия", 1),
  MenologyName("Леонида", 1),
  MenologyName("Леонта", 1),
  MenologyName("Леонтия", 1),
  MenologyName("Ливерия", 1),
  MenologyName("Ликариона", 1),
  MenologyName("Лимния", 1),
  MenologyName("Лина", 1),
  MenologyName("Лисимаха", 1),
  MenologyName("Лоллия", 1),
  MenologyName("Лоллиона", 1),
  MenologyName("Лонгина", 1),
  MenologyName("Лота", 1),
  MenologyName("Луарсаба", 1),
  MenologyName("Луку", 1),
  MenologyName("Лукиана", 1),
  MenologyName("Лукия", 1),
  MenologyName("Лукиллиаан", 1),
  MenologyName("Лупа", 1),
  MenologyName("Луппу", 1),
  MenologyName("Ларису", 0),
  MenologyName("Леониду", 0),
  MenologyName("Леониллу", 0),
  MenologyName("Лептину", 0),
  MenologyName("Ливию", 0),
  MenologyName("Лидию", 0),
  MenologyName("Лию", 0),
  MenologyName("Лукину", 0),
  MenologyName("Лукию", 0),
  MenologyName("Любовь", 0),
  MenologyName("Людину", 0),
  MenologyName("Людмилу", 0),
  MenologyName("Люциллу", 0),
  MenologyName("Мавра", 1),
  MenologyName("Маврикия", 1),
  MenologyName("Мавсима", 1),
  MenologyName("Мага", 1),
  MenologyName("Магна", 1),
  MenologyName("Маиора", 1),
  MenologyName("Маира", 1),
  MenologyName("Макария", 1),
  MenologyName("Македона", 1),
  MenologyName("Македония", 1),
  MenologyName("Макровия", 1),
  MenologyName("Максиана", 1),
  MenologyName("Максима", 1),
  MenologyName("Максимиана", 1),
  MenologyName("Максимилиана", 1),
  MenologyName("Мала", 1),
  MenologyName("Малахию", 1),
  MenologyName("Малха", 1),
  MenologyName("Маманта", 1),
  MenologyName("Маммия", 1),
  MenologyName("Мануила", 1),
  MenologyName("Мара", 1),
  MenologyName("Мардария", 1),
  MenologyName("Мардония", 1),
  MenologyName("Мариава", 1),
  MenologyName("Мариана", 1),
  MenologyName("Марина", 1),
  MenologyName("Марка", 1),
  MenologyName("Маркелла", 1),
  MenologyName("Маркеллина", 1),
  MenologyName("Маркиана", 1),
  MenologyName("Марона", 1),
  MenologyName("Марсалия", 1),
  MenologyName("Мартина", 1),
  MenologyName("Мартиниана", 1),
  MenologyName("Мартирия", 1),
  MenologyName("Маруфа", 1),
  MenologyName("Марциала", 1),
  MenologyName("Матоя", 1),
  MenologyName("Матура", 1),
  MenologyName("Матфея", 1),
  MenologyName("Матфия", 1),
  MenologyName("Мегефия", 1),
  MenologyName("Медимна", 1),
  MenologyName("Меладия", 1),
  MenologyName("Меласиппа", 1),
  MenologyName("Мелевсиппа", 1),
  MenologyName("Мелетия", 1),
  MenologyName("Мелиссена", 1),
  MenologyName("Мелитона", 1),
  MenologyName("Мелхиседека", 1),
  MenologyName("Мемнона", 1),
  MenologyName("Меналапа", 1),
  MenologyName("Менандра", 1),
  MenologyName("Менея", 1),
  MenologyName("Менигна", 1),
  MenologyName("Меркурия", 1),
  MenologyName("Мертия", 1),
  MenologyName("Месира", 1),
  MenologyName("Места", 1),
  MenologyName("Метрия", 1),
  MenologyName("Мефодия", 1),
  MenologyName("Миана", 1),
  MenologyName("Мигдония", 1),
  MenologyName("Мила", 1),
  MenologyName("Милия", 1),
  MenologyName("Милла", 1),
  MenologyName("Мимненоса", 1),
  MenologyName("Мину", 1),
  MenologyName("Минеона", 1),
  MenologyName("Минсифея", 1),
  MenologyName("Миракса", 1),
  MenologyName("Мириана", 1),
  MenologyName("Мирона", 1),
  MenologyName("Мисаила", 1),
  MenologyName("Митридата", 1),
  MenologyName("Митрофана", 1),
  MenologyName("Михаила", 1),
  MenologyName("Михея", 1),
  MenologyName("Мнасена", 1),
  MenologyName("Модеста", 1),
  MenologyName("Моисея", 1),
  MenologyName("Мокия", 1),
  MenologyName("Молия", 1),
  MenologyName("Монагрея", 1),
  MenologyName("Мосхиана", 1),
  MenologyName("Мстислава", 1),
  MenologyName("Муко", 1),
  MenologyName("Мурина", 1),
  MenologyName("Мавру", 0),
  MenologyName("Магдалину", 0),
  MenologyName("Макарию", 0),
  MenologyName("Македонию", 0),
  MenologyName("Макрину", 0),
  MenologyName("Малфефу", 0),
  MenologyName("Мамелхву", 0),
  MenologyName("Мамику", 0),
  MenologyName("Мамфусу", 0),
  MenologyName("Манефу", 0),
  MenologyName("Маргариту", 0),
  MenologyName("Мариам", 0),
  MenologyName("Мариамну", 0),
  MenologyName("Марину", 0),
  MenologyName("Мариониллу", 0),
  MenologyName("Марию", 0),
  MenologyName("Маркеллу", 0),
  MenologyName("Маркеллину", 0),
  MenologyName("Маркиану", 0),
  MenologyName("Марфу", 0),
  MenologyName("Мастридию", 0),
  MenologyName("Матрону", 0),
  MenologyName("Мелану", 0),
  MenologyName("Меланию", 0),
  MenologyName("Мелитину", 0),
  MenologyName("Милицу", 0),
  MenologyName("Минодору", 0),
  MenologyName("Миропию", 0),
  MenologyName("Митродору", 0),
  MenologyName("Михаилу", 0),
  MenologyName("Моико", 0),
  MenologyName("Мстиславу", 0),
  MenologyName("Музу", 0),
  MenologyName("Навкратия", 1),
  MenologyName("Назария", 1),
  MenologyName("Наркисса", 1),
  MenologyName("Нарса", 1),
  MenologyName("Наталия", 1),
  MenologyName("Наума", 1),
  MenologyName("Нафана", 1),
  MenologyName("Нафанаила", 1),
  MenologyName("Неадия", 1),
  MenologyName("Неаниска", 1),
  MenologyName("Неарха", 1),
  MenologyName("Неемию", 1),
  MenologyName("Нектария", 1),
  MenologyName("Немезия", 1),
  MenologyName("Неона", 1),
  MenologyName("Неофита", 1),
  MenologyName("Нерангиоса", 1),
  MenologyName("Нердона", 1),
  MenologyName("Нестава", 1),
  MenologyName("Нестора", 1),
  MenologyName("Неффалима", 1),
  MenologyName("Никандра", 1),
  MenologyName("Никанора", 1),
  MenologyName("Никиту", 1),
  MenologyName("Никифора", 1),
  MenologyName("Никодима", 1),
  MenologyName("Николу", 1),
  MenologyName("Николая", 1),
  MenologyName("Никона", 1),
  MenologyName("Никострата", 1),
  MenologyName("Никтополиона", 1),
  MenologyName("Нила", 1),
  MenologyName("Нимфана", 1),
  MenologyName("Нирея", 1),
  MenologyName("Нирсу", 1),
  MenologyName("Нисфероя", 1),
  MenologyName("Нита", 1),
  MenologyName("Нифонта", 1),
  MenologyName("Ноя", 1),
  MenologyName("Нона", 1),
  MenologyName("Нягу", 1),
  MenologyName("Надежду", 0),
  MenologyName("Нану", 0),
  MenologyName("Наталию", 0),
  MenologyName("Неониллу", 0),
  MenologyName("Неофиту", 0),
  MenologyName("Нику", 0),
  MenologyName("Нимфодору", 0),
  MenologyName("Нину", 0),
  MenologyName("Нонну", 0),
  MenologyName("Нунехию", 0),
  MenologyName("Олафа", 1),
  MenologyName("Олега", 1),
  MenologyName("Олимпа", 1),
  MenologyName("Олимпия", 1),
  MenologyName("Онисия", 1),
  MenologyName("Онисима", 1),
  MenologyName("Онисифора", 1),
  MenologyName("Онуфрия", 1),
  MenologyName("Оптата", 1),
  MenologyName("Ора", 1),
  MenologyName("Орентия", 1),
  MenologyName("Ореста", 1),
  MenologyName("Ориона", 1),
  MenologyName("Оропса", 1),
  MenologyName("Ортисия", 1),
  MenologyName("Осию", 1),
  MenologyName("Острихия", 1),
  MenologyName("Олду", 0),
  MenologyName("Олимпиаду", 0),
  MenologyName("Ольгу", 0),
  MenologyName("Ореозилу", 0),
  MenologyName("Павла", 1),
  MenologyName("Павлина", 1),
  MenologyName("Павсикакия", 1),
  MenologyName("Павсилипа", 1),
  MenologyName("Павсирия", 1),
  MenologyName("Паисия", 1),
  MenologyName("Пактовия", 1),
  MenologyName("Паламона", 1),
  MenologyName("Палладия", 1),
  MenologyName("Палмата", 1),
  MenologyName("Памву", 1),
  MenologyName("Памвона", 1),
  MenologyName("Памфалона", 1),
  MenologyName("Памфамира", 1),
  MenologyName("Памфила", 1),
  MenologyName("Панагиота", 1),
  MenologyName("Панкратия", 1),
  MenologyName("Пансофия", 1),
  MenologyName("Пансфена", 1),
  MenologyName("Пантелеимона", 1),
  MenologyName("Пантолеона", 1),
  MenologyName("Панфирия", 1),
  MenologyName("Панхария", 1),
  MenologyName("Папу", 1),
  MenologyName("Папия", 1),
  MenologyName("Папилу", 1),
  MenologyName("Папилина", 1),
  MenologyName("Паппа", 1),
  MenologyName("Паппия", 1),
  MenologyName("Парамона", 1),
  MenologyName("Парда", 1),
  MenologyName("Паригория", 1),
  MenologyName("Пармена", 1),
  MenologyName("Пармения", 1),
  MenologyName("Парода", 1),
  MenologyName("Парсмана", 1),
  MenologyName("Парфения", 1),
  MenologyName("Пасикрата", 1),
  MenologyName("Пассариона", 1),
  MenologyName("Патапия", 1),
  MenologyName("Патермуфия", 1),
  MenologyName("Патрикия", 1),
  MenologyName("Патрова", 1),
  MenologyName("Патрокла", 1),
  MenologyName("Пафнутия", 1),
  MenologyName("Пахомия", 1),
  MenologyName("Пелия", 1),
  MenologyName("Пеона", 1),
  MenologyName("Пергия", 1),
  MenologyName("Перегрина", 1),
  MenologyName("Петра", 1),
  MenologyName("Петрония", 1),
  MenologyName("Пигасия", 1),
  MenologyName("Пиерия", 1),
  MenologyName("Пимена", 1),
  MenologyName("Пинну", 1),
  MenologyName("Пиннуфрия", 1),
  MenologyName("Пиония", 1),
  MenologyName("Пиора", 1),
  MenologyName("Пирра", 1),
  MenologyName("Писта", 1),
  MenologyName("Питирима", 1),
  MenologyName("Питируна", 1),
  MenologyName("Платона", 1),
  MenologyName("Плотина", 1),
  MenologyName("Полидора", 1),
  MenologyName("Полиевкта", 1),
  MenologyName("Полиена", 1),
  MenologyName("Поликарпа", 1),
  MenologyName("Полихрония", 1),
  MenologyName("Полувия", 1),
  MenologyName("Помпея", 1),
  MenologyName("Помпиана", 1),
  MenologyName("Помпия", 1),
  MenologyName("Понтия", 1),
  MenologyName("Понтика", 1),
  MenologyName("Поплия", 1),
  MenologyName("Поплиона", 1),
  MenologyName("Порфирия", 1),
  MenologyName("Потита", 1),
  MenologyName("Пофина", 1),
  MenologyName("Прилидиана", 1),
  MenologyName("Примитива", 1),
  MenologyName("Приска", 1),
  MenologyName("Прова", 1),
  MenologyName("Провия", 1),
  MenologyName("Прокесса", 1),
  MenologyName("Прокла", 1),
  MenologyName("Прокопия", 1),
  MenologyName("Прокула", 1),
  MenologyName("Прота", 1),
  MenologyName("Протасия", 1),
  MenologyName("Протерия", 1),
  MenologyName("Протиона", 1),
  MenologyName("Протогена", 1),
  MenologyName("Протолеона", 1),
  MenologyName("Прохора", 1),
  MenologyName("Псоя", 1),
  MenologyName("Пуда", 1),
  MenologyName("Пуллия", 1),
  MenologyName("Пуплия", 1),
  MenologyName("Павлу", 0),
  MenologyName("Параскеву", 0),
  MenologyName("Парфагапу", 0),
  MenologyName("Патрикию", 0),
  MenologyName("Пелагию", 0),
  MenologyName("Перпетую", 0),
  MenologyName("Петрониллу", 0),
  MenologyName("Петронию", 0),
  MenologyName("Пиаму", 0),
  MenologyName("Плакиллу", 0),
  MenologyName("Платониду", 0),
  MenologyName("Полактию", 0),
  MenologyName("Поликсению", 0),
  MenologyName("Поплию", 0),
  MenologyName("Потамию", 0),
  MenologyName("Потенциану", 0),
  MenologyName("Препедигну", 0),
  MenologyName("Прискиллу", 0),
  MenologyName("Проклу", 0),
  MenologyName("Проскудию", 0),
  MenologyName("Пульхерию", 0),
  MenologyName("Равулу", 1),
  MenologyName("Раждена", 1),
  MenologyName("Разумника", 1),
  MenologyName("Рамаза", 1),
  MenologyName("Рафаила", 1),
  MenologyName("Реаса", 1),
  MenologyName("Ревоката", 1),
  MenologyName("Ригина", 1),
  MenologyName("Рикса", 1),
  MenologyName("Римма", 1),
  MenologyName("Рина", 1),
  MenologyName("Родиана", 1),
  MenologyName("Родиона", 1),
  MenologyName("Родопиана", 1),
  MenologyName("Романа", 1),
  MenologyName("Ромила", 1),
  MenologyName("Ростислава", 1),
  MenologyName("Рувима", 1),
  MenologyName("Рустика", 1),
  MenologyName("Руфа", 1),
  MenologyName("Руфина", 1),
  MenologyName("Раав", 0),
  MenologyName("Раису", 0),
  MenologyName("Рафаилу", 0),
  MenologyName("Рахиль", 0),
  MenologyName("Ревекку", 0),
  MenologyName("Ридору", 0),
  MenologyName("Рипсимию", 0),
  MenologyName("Руфину", 0),
  MenologyName("Руфь", 0),
  MenologyName("Савву", 1),
  MenologyName("Савватия", 1),
  MenologyName("Савела", 1),
  MenologyName("Саверия", 1),
  MenologyName("Савина", 1),
  MenologyName("Савиниана", 1),
  MenologyName("Садока", 1),
  MenologyName("Саиса", 1),
  MenologyName("Сакердона", 1),
  MenologyName("Саламана", 1),
  MenologyName("Салона", 1),
  MenologyName("Самея", 1),
  MenologyName("Самона", 1),
  MenologyName("Сампсона", 1),
  MenologyName("Самуила", 1),
  MenologyName("Санкта", 1),
  MenologyName("Сарапавона", 1),
  MenologyName("Сарвила", 1),
  MenologyName("Сармата", 1),
  MenologyName("Сармеана", 1),
  MenologyName("Сасония", 1),
  MenologyName("Сатира", 1),
  MenologyName("Саторина", 1),
  MenologyName("Саторния", 1),
  MenologyName("Саторнила", 1),
  MenologyName("Саторнина", 1),
  MenologyName("Сатура", 1),
  MenologyName("Сатурнина", 1),
  MenologyName("Святослава", 1),
  MenologyName("Севастиана", 1),
  MenologyName("Севериана", 1),
  MenologyName("Северина", 1),
  MenologyName("Севира", 1),
  MenologyName("Севоя", 1),
  MenologyName("Секунда", 1),
  MenologyName("Селафиила", 1),
  MenologyName("Селевка", 1),
  MenologyName("Селевкия", 1),
  MenologyName("Селиния", 1),
  MenologyName("Сенниса", 1),
  MenologyName("Сеннуфия", 1),
  MenologyName("Септемина", 1),
  MenologyName("Серапиона", 1),
  MenologyName("Серафима", 1),
  MenologyName("Серафиона", 1),
  MenologyName("Сергия", 1),
  MenologyName("Серида", 1),
  MenologyName("Сивеифа", 1),
  MenologyName("Сивела", 1),
  MenologyName("Сигица", 1),
  MenologyName("Сикста", 1),
  MenologyName("Силу", 1),
  MenologyName("Силана", 1),
  MenologyName("Силуана", 1),
  MenologyName("Сильвана", 1),
  MenologyName("Сильвестра", 1),
  MenologyName("Сима", 1),
  MenologyName("Симеона", 1),
  MenologyName("Симона", 1),
  MenologyName("Симфориана", 1),
  MenologyName("Симфрония", 1),
  MenologyName("Синесия", 1),
  MenologyName("Сиония", 1),
  MenologyName("Сисиния", 1),
  MenologyName("Сисоя", 1),
  MenologyName("Сифа", 1),
  MenologyName("Смарагда", 1),
  MenologyName("Созона", 1),
  MenologyName("Созонта", 1),
  MenologyName("Сократа", 1),
  MenologyName("Соломона", 1),
  MenologyName("Солохона", 1),
  MenologyName("Сонирила", 1),
  MenologyName("Сосипатра", 1),
  MenologyName("Соссия", 1),
  MenologyName("Сосфена", 1),
  MenologyName("Софония", 1),
  MenologyName("Софрония", 1),
  MenologyName("Спевсиппа", 1),
  MenologyName("Спиридона", 1),
  MenologyName("Стаматия", 1),
  MenologyName("Стахия", 1),
  MenologyName("Стефана", 1),
  MenologyName("Стилиана", 1),
  MenologyName("Стиракия", 1),
  MenologyName("Стиракина", 1),
  MenologyName("Стратона", 1),
  MenologyName("Стратоника", 1),
  MenologyName("Стратора", 1),
  MenologyName("Судислава", 1),
  MenologyName("Суимвла", 1),
  MenologyName("Сухия", 1),
  MenologyName("Шалву", 1),
  MenologyName("Шио", 1),
  MenologyName("Савину", 0),
  MenologyName("Саломию", 0),
  MenologyName("Сарру", 0),
  MenologyName("Севастиану", 0),
  MenologyName("Сеию", 0),
  MenologyName("Серафиму", 0),
  MenologyName("Сидонию", 0),
  MenologyName("Симферусу", 0),
  MenologyName("Синклитикию", 0),
  MenologyName("Сиру", 0),
  MenologyName("Снандулию", 0),
  MenologyName("Соломонию", 0),
  MenologyName("Сосанну", 0),
  MenologyName("Сосипатру", 0),
  MenologyName("Софию", 0),
  MenologyName("Стефаниду", 0),
  MenologyName("Стратию", 0),
  MenologyName("Стратонику", 0),
  MenologyName("Сусанну", 0),
  MenologyName("Шушанику", 0),
  MenologyName("Тавриона", 1),
  MenologyName("Талалея", 1),
  MenologyName("Тарасия", 1),
  MenologyName("Тараха", 1),
  MenologyName("Татиана", 1),
  MenologyName("Татиона", 1),
  MenologyName("Телесфора", 1),
  MenologyName("Телетия", 1),
  MenologyName("Теодола", 1),
  MenologyName("Терентия", 1),
  MenologyName("Тертия", 1),
  MenologyName("Тертуллина", 1),
  MenologyName("Тивуртия", 1),
  MenologyName("Тигрия", 1),
  MenologyName("Тимолая", 1),
  MenologyName("Тимона", 1),
  MenologyName("Тимофея", 1),
  MenologyName("Тиранна", 1),
  MenologyName("Тиричана", 1),
  MenologyName("Тита", 1),
  MenologyName("Тифоя", 1),
  MenologyName("Тихика", 1),
  MenologyName("Тихона", 1),
  MenologyName("Транквиллина", 1),
  MenologyName("Триандафила", 1),
  MenologyName("Тривимия", 1),
  MenologyName("Трифиллия", 1),
  MenologyName("Трифона", 1),
  MenologyName("Троадия", 1),
  MenologyName("Трофима", 1),
  MenologyName("Турвона", 1),
  MenologyName("Тавифу", 0),
  MenologyName("Таисию", 0),
  MenologyName("Тамару", 0),
  MenologyName("Татиану", 0),
  MenologyName("Татту", 0),
  MenologyName("Текусу", 0),
  MenologyName("Трифену", 0),
  MenologyName("Уара", 1),
  MenologyName("Урвана", 1),
  MenologyName("Уриила", 1),
  MenologyName("Урпасиана", 1),
  MenologyName("Урсикия", 1),
  MenologyName("Уирку", 0),
  MenologyName("Фавия", 1),
  MenologyName("Фавмасия", 1),
  MenologyName("Фавста", 1),
  MenologyName("Фавстиана", 1),
  MenologyName("Фаддея", 1),
  MenologyName("Фала", 1),
  MenologyName("Фалалея", 1),
  MenologyName("Фалассия", 1),
  MenologyName("Фантина", 1),
  MenologyName("Фанурия", 1),
  MenologyName("Фармуфия", 1),
  MenologyName("Фарнакия", 1),
  MenologyName("Фафуила", 1),
  MenologyName("Феагена", 1),
  MenologyName("Федима", 1),
  MenologyName("Федра", 1),
  MenologyName("Феиона", 1),
  MenologyName("Феликиссима", 1),
  MenologyName("Феликса", 1),
  MenologyName("Фемелия", 1),
  MenologyName("Фемистоклея", 1),
  MenologyName("Феогена", 1),
  MenologyName("Феогнида", 1),
  MenologyName("Феогния", 1),
  MenologyName("Феогноста", 1),
  MenologyName("Феодора", 1),
  MenologyName("Феодорита", 1),
  MenologyName("Феодосия", 1),
  MenologyName("Феодота", 1),
  MenologyName("Феодотиона", 1),
  MenologyName("Феодоха", 1),
  MenologyName("Феодула", 1),
  MenologyName("Феоида", 1),
  MenologyName("Феоктириста", 1),
  MenologyName("Феоктиста", 1),
  MenologyName("Феолипта", 1),
  MenologyName("Феону", 1),
  MenologyName("Феопемпта", 1),
  MenologyName("Феописта", 1),
  MenologyName("Феопрепия", 1),
  MenologyName("Феосевия", 1),
  MenologyName("Феостирикта", 1),
  MenologyName("Феостиха", 1),
  MenologyName("Феотекна", 1),
  MenologyName("Феотима", 1),
  MenologyName("Феотиха", 1),
  MenologyName("Феофана", 1),
  MenologyName("Феофила", 1),
  MenologyName("Феофилакта", 1),
  MenologyName("Ферапонта", 1),
  MenologyName("Ферина", 1),
  MenologyName("Ферма", 1),
  MenologyName("Феспесия", 1),
  MenologyName("Филагрия", 1),
  MenologyName("Филадельфа", 1),
  MenologyName("Филарета", 1),
  MenologyName("Филеорта", 1),
  MenologyName("Филетера", 1),
  MenologyName("Филия", 1),
  MenologyName("Филика", 1),
  MenologyName("Филикла", 1),
  MenologyName("Филикса", 1),
  MenologyName("Филимона", 1),
  MenologyName("Филиппа", 1),
  MenologyName("Филиппика", 1),
  MenologyName("Филита", 1),
  MenologyName("Филла", 1),
  MenologyName("Филогония", 1),
  MenologyName("Филоктимона", 1),
  MenologyName("Филолога", 1),
  MenologyName("Филона", 1),
  MenologyName("Филонида", 1),
  MenologyName("Философа", 1),
  MenologyName("Филофея", 1),
  MenologyName("Филумена", 1),
  MenologyName("Финееса", 1),
  MenologyName("Фирма", 1),
  MenologyName("Фирмина", 1),
  MenologyName("Фирмоса", 1),
  MenologyName("Фирса", 1),
  MenologyName("Фифаила", 1),
  MenologyName("Флавиана", 1),
  MenologyName("Флавия", 1),
  MenologyName("Флегонта", 1),
  MenologyName("Флора", 1),
  MenologyName("Флорентия", 1),
  MenologyName("Фоку", 1),
  MenologyName("Фому", 1),
  MenologyName("Форвина", 1),
  MenologyName("Фортуната", 1),
  MenologyName("Фостирия", 1),
  MenologyName("Фота", 1),
  MenologyName("Фотия", 1),
  MenologyName("Фотина", 1),
  MenologyName("Фридолина", 1),
  MenologyName("Фронтасия", 1),
  MenologyName("Фрументия", 1),
  MenologyName("Фулвиана", 1),
  MenologyName("Фусика", 1),
  MenologyName("Фавсту", 0),
  MenologyName("Фаину", 0),
  MenologyName("Фамарь", 0),
  MenologyName("Февронию", 0),
  MenologyName("Феклу", 0),
  MenologyName("Феодору", 0),
  MenologyName("Феодосию", 0),
  MenologyName("Феодоту", 0),
  MenologyName("Феодотию", 0),
  MenologyName("Феодулу", 0),
  MenologyName("Феодулию", 0),
  MenologyName("Феоклиту", 0),
  MenologyName("Феоктисту", 0),
  MenologyName("Феониллу", 0),
  MenologyName("Феопистию", 0),
  MenologyName("Феосевию", 0),
  MenologyName("Феотиму", 0),
  MenologyName("Феофанию", 0),
  MenologyName("Феофилу", 0),
  MenologyName("Фервуфу", 0),
  MenologyName("Фессалоникию", 0),
  MenologyName("Фею", 0),
  MenologyName("Фиву", 0),
  MenologyName("Фивею", 0),
  MenologyName("Филиппию", 0),
  MenologyName("Филицату", 0),
  MenologyName("Филицитату", 0),
  MenologyName("Филониллу", 0),
  MenologyName("Филофею", 0),
  MenologyName("Фомаиду", 0),
  MenologyName("Фотиду", 0),
  MenologyName("Фотину", 0),
  MenologyName("Фотинию", 0),
  MenologyName("Фоту", 0),
  MenologyName("Фронтину", 0),
  MenologyName("Халева", 1),
  MenologyName("Харалампия", 1),
  MenologyName("Харисима", 1),
  MenologyName("Харитона", 1),
  MenologyName("Херимона", 1),
  MenologyName("Хрисанфа", 1),
  MenologyName("Хрисогона", 1),
  MenologyName("Хрисотель", 1),
  MenologyName("Христодула", 1),
  MenologyName("Христоса", 1),
  MenologyName("Христофора", 1),
  MenologyName("Худиона", 1),
  MenologyName("Хусдазата", 1),
  MenologyName("Хариессу", 0),
  MenologyName("Харису", 0),
  MenologyName("Хариту", 0),
  MenologyName("Харитину", 0),
  MenologyName("Хионию", 0),
  MenologyName("Хрисию", 0),
  MenologyName("Христину", 0),
  MenologyName("Христодулу", 0),
  MenologyName("Элизбара", 1),
  MenologyName("Ювеналия", 1),
  MenologyName("Юлиана", 1),
  MenologyName("Юлия", 1),
  MenologyName("Юлию", 0),
  MenologyName("Юнию", 0),
  MenologyName("Ярополка", 1),
  MenologyName("Ярослава", 1),
  MenologyName("Яздундокту", 0),
  MenologyName("Уалента", 1),
  MenologyName("Уалентина", 1),
  MenologyName("Уалериана", 1),
  MenologyName("Уалерия", 1),
];