import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'settings.dart';
import 'database_helper.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => Settings()),
      ],
      child: NameListApp(),
    ),
  );
}

class NameListApp extends StatelessWidget {
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
          themeMode: settings.themeMode, // Используем выбранную тему
          home: NameListHome(), // По умолчанию открывается "Помянник"
        );
      },
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

  Future<void> _addNameToList(int nameListId, String name, int gender, String? status, String? rank) async {
    await _dbHelper.addName(nameListId, name, gender, status, rank);
  }

  Future<void> _editNameInList(int nameId, String newName, int gender, String? status, String? rank) async {
    await _dbHelper.updateName(nameId, newName, gender, status, rank);
  }

  Future<void> _deleteNameFromList(int nameId) async {
    await _dbHelper.deleteName(nameId);
    // Проверяем, остались ли имена в текущем списке
    final currentListId = _currentListId;
    if (currentListId != null) {
      final names = await _dbHelper.loadNames(currentListId);
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
            onAddName: (name, gender, status, rank) => _addNameToList(nameList['id'], name, gender, status, rank),
            onEditName: (nameId, newName, gender, status, rank) => _editNameInList(nameId, newName, gender, status, rank),
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
  final Function(String, int, String?, String?) onAddName;
  final Function(int, String, int, String?, String?) onEditName;
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
  List<Map<String, dynamic>> _names = [];
  late DatabaseHelper _dbHelper;

  @override
  void initState() {
    super.initState();
    _dbHelper = DatabaseHelper();
    _loadNames();
  }

  Future<void> _loadNames() async {
    final names = await _dbHelper.loadNames(widget.nameList['id']);
    setState(() {
      _names = List<Map<String, dynamic>>.from(names); // Создаем изменяемую копию
    });
  }

  Future<void> _addName(String name, int gender, String? status, String? rank) async {
    await widget.onAddName(name, gender, status, rank);
    await _loadNames();
  }

  Future<void> _editName(int nameId, String newName, int gender, String? status, String? rank) async {
    // Получаем текущее имя
    final name = _names.firstWhere((name) => name['id'] == nameId);
    final currentName = name['name'];
    final currentGender = name['gender'];
    final currentStatus = name['status'];
    final currentRank = name['rank'];

    // Форматируем новое имя: первая буква заглавная, остальные маленькие
    String formattedName = newName.trim();
    formattedName = formattedName[0].toUpperCase() + formattedName.substring(1).toLowerCase();

    // Преобразуем оба имени в нижний регистр и сравниваем
    if (formattedName.toLowerCase() != currentName.toLowerCase()||
        gender != currentGender ||
        status != currentStatus ||
        rank != currentRank) {
      // Если данные изменились, вызываем метод редактирования
      await widget.onEditName(nameId, formattedName, gender, status, rank);
      await _loadNames(); // Перезагружаем имена
    }
  }

  Future<void> _deleteName(int nameId) async {
    await widget.onDeleteName(nameId);
    await _loadNames();
  }

  @override
  Widget build(BuildContext context) {
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
                        final status = name['status']?.toString() ?? ''; // Получаем статус, если он есть
                        final rank = name['rank']?.toString() ?? ''; // Получаем сан, если он есть

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
                                          if (status.isNotEmpty) status,
                                          if (rank.isNotEmpty) rank,
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

  void _showAddNameDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>(); // Ключ для управления состоянием формы
    final nameController = TextEditingController();

    int selectedGender = 1; // По умолчанию выбран мужской пол
    String? selectedStatus;
    String? selectedRank;

    // Списки для выбора статуса и сана
    //todo
    final List<String> statusOptions = ['болящий', 'воин', 'новопреставленный'];
    final List<String> rankOptions = ['мирянин', 'монах', 'священник', 'епископ'];

    showDialog(
      context: context,
      builder: (context) {
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Имя не может быть пустым';
                        }

                        // Регулярное выражение для проверки, что строка состоит из одного слова на русском языке
                        final regex = RegExp(r'^[А-Яа-яЁё]+$');
                        if (!regex.hasMatch(value.trim())) {
                          return 'Имя должно состоять из одного слова на русском языке. Проверьте, что имя не содержит пробелов или других символов.';
                        }

                        return null; // Валидация пройдена
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedGender,
                      //todo
                      decoration: InputDecoration(labelText: 'Пол'),
                      items: [
                        DropdownMenuItem(value: 1, child: Text('Мужской')),
                        DropdownMenuItem(value: 0, child: Text('Женский')),
                      ],
                      onChanged: (value) {
                        selectedGender = value!;
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(labelText: 'Статус'),
                      items: statusOptions.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedStatus = value;
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRank,
                      decoration: InputDecoration(labelText: 'Сан'),
                      items: rankOptions.map((rank) {
                        return DropdownMenuItem(
                          value: rank,
                          child: Text(rank),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedRank = value;
                      },
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
                    _addName(formattedName, selectedGender, selectedStatus, selectedRank);
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
  }

  void _showEditDialog(BuildContext context, int nameId, String currentName) {
    final nameController = TextEditingController(text: currentName);

    // Получаем текущие данные имени
    final name = _names.firstWhere((name) => name['id'] == nameId);
    int selectedGender = name['gender'] ?? 1; // По умолчанию мужской пол
    String? selectedStatus = name['status']?.toString();
    String? selectedRank = name['rank']?.toString();
    //todo
    // Списки для выбора статуса и сана
    final List<String> statusOptions = ['болящий', 'воин', 'новопреставленный'];
    final List<String> rankOptions = ['мирянин', 'монах', 'священник', 'епископ'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Редактировать имя'),
          content: SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(hintText: 'Введите новое имя'),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedGender,
                    //todo
                    decoration: InputDecoration(labelText: 'Пол'),
                    items: [
                      DropdownMenuItem(value: 1, child: Text('Мужской')),
                      DropdownMenuItem(value: 0, child: Text('Женский')),
                    ],
                    onChanged: (value) {
                      selectedGender = value!;
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(labelText: 'Статус'),
                    items: statusOptions.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedStatus = value;
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRank,
                    decoration: InputDecoration(labelText: 'Сан'),
                    items: rankOptions.map((rank) {
                      return DropdownMenuItem(
                        value: rank,
                        child: Text(rank),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedRank = value;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  // Форматируем имя: первая буква заглавная, остальные маленькие
                  String formattedName = nameController.text.trim();
                  formattedName = formattedName[0].toUpperCase() +
                      formattedName.substring(1).toLowerCase();

                  // Вызываем метод редактирования имени с новыми параметрами
                  _editName(nameId, formattedName, selectedGender, selectedStatus, selectedRank);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Сохранить'),
            ),
          ],
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
        ],
      ),
    );
  }
}