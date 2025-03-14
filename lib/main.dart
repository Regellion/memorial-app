import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'settings.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => Settings(),
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
  List<NameList> nameLists = [
    NameList(title: 'Семья', type: ListType.health, names: ['Анна', 'Иван']),
    NameList(title: 'Друзья', type: ListType.repose, names: ['Олег']),
  ];

  final PageController _pageController =
      PageController(); // Контроллер для PageView
  int _currentPageIndex = 0; // Текущий индекс списка

  void _addNewList(String title, ListType type) {
    setState(() {
      nameLists.add(NameList(title: title, type: type, names: []));
      _currentPageIndex = nameLists.length - 1; // Переключиться на новый список
      if (nameLists.length > 1) {
        // Переключаемся на новую страницу только если PageView активен
        _pageController.jumpToPage(_currentPageIndex);
      }
    });
  }

  void _addNameToList(int listIndex, String name) {
    setState(() {
      nameLists[listIndex].names.add(name);
    });
  }

  void _editNameInList(int listIndex, int nameIndex, String newName) {
    setState(() {
      nameLists[listIndex].names[nameIndex] = newName;
    });
  }

  void _deleteNameFromList(int listIndex, int nameIndex) {
    setState(() {
      nameLists[listIndex].names.removeAt(nameIndex);
      // Автоматическое удаление списка, если он пуст
      if (nameLists[listIndex].names.isEmpty) {
        nameLists.removeAt(listIndex);
        _currentPageIndex =
            nameLists.isEmpty
                ? 0
                : _currentPageIndex.clamp(0, nameLists.length - 1);
      }
    });
  }

  void _editListTitle(int listIndex, String newTitle) {
    setState(() {
      nameLists[listIndex].title = newTitle;
    });
  }

  void _deleteList(int listIndex) {
    setState(() {
      nameLists.removeAt(listIndex);
      _currentPageIndex =
          nameLists.isEmpty
              ? 0
              : _currentPageIndex.clamp(0, nameLists.length - 1);
    });
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
      body:
          nameLists.isEmpty
              ? Center(child: Text('Нет списков. Добавьте новый список.'))
              : PageView.builder(
                controller: _pageController, // Используем PageController
                itemCount: nameLists.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPageIndex = index; // Обновляем текущий индекс
                  });
                },
                itemBuilder: (context, index) {
                  return NameListPage(
                    nameList: nameLists[index],
                    onAddName: (name) => _addNameToList(index, name),
                    onEditName:
                        (nameIndex, newName) =>
                            _editNameInList(index, nameIndex, newName),
                    onDeleteName:
                        (nameIndex) => _deleteNameFromList(index, nameIndex),
                    onEditTitle: (newTitle) => _editListTitle(index, newTitle),
                    onDeleteList: () => _deleteList(index),
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

class NameListPage extends StatelessWidget {
  final NameList nameList;
  final Function(String) onAddName;
  final Function(int, String) onEditName;
  final Function(int) onDeleteName;
  final Function(String) onEditTitle;
  final VoidCallback onDeleteList;

  NameListPage({
    required this.nameList,
    required this.onAddName,
    required this.onEditName,
    required this.onDeleteName,
    required this.onEditTitle,
    required this.onDeleteList,
  });

  @override
  Widget build(BuildContext context) {
    String frameImage =
    nameList.type == ListType.health ?
    'assets/images/health_frame_title.png':
    'assets/images/repose_frame_title.png';

    // Получаем размеры экрана
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Устанавливаем размеры контейнера в зависимости от размера экрана
    // Например, ширина 30% от ширины экрана, а высота 20% от высоты экрана
    double containerWidth = screenWidth * 0.5; // 50% от ширины экрана
    double containerHeight = screenHeight * 0.1; // 10% от высоты экрана

    // Определение цвета линии в зависимости от типа списка
    Color lineColor = nameList.type == ListType.health ? Colors.red : Colors.blue;

    return Stack(
      children: [
        // Основной контейнер, где будет содержимое списка
        Container(
          padding: EdgeInsets.only(
            top: 40.0,
            bottom: 70.0,
            left: 16,
            right: 16,
          ), // Отступы
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor, // Используем цвет фона из темы
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 2), // Тень незначительная
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
                          _showEditTitleDialog(context, nameList.title); // Редактирование при долгом нажатии
                        },
                        child: Text(
                          nameList.title,
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        _showEditTitleDialog(context, nameList.title);
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
              // Заменяем текст картинкой
              Container(
                height: containerHeight,
                width: containerWidth,
                // margin: EdgeInsets.symmetric(vertical: 8.0),
                child: Image.asset(frameImage), // Отображаем картинку вместо текста
              ),
              Expanded(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.75, // 75% от ширины экрана
                  child: ListView.builder(
                    itemCount: nameList.names.length,
                    itemBuilder: (context, index) {
                      return Dismissible(
                        key: Key(nameList.names[index]),
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
                            // Показываем диалог подтверждения удаления
                            bool? confirm = await _showDeleteConfirmDialog(context);
                            return confirm == true;
                          } else if (direction == DismissDirection.endToStart) {
                            _showEditDialog(context, index, nameList.names[index]);
                            return false; // Не удаляем элемент, просто открываем диалог
                          }
                          return false;
                        },
                        onDismissed: (direction) {
                          // Удаляем имя из списка при выполнении жеста
                          onDeleteName(index); // Удаляем элемент из списка
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center, // Центрируем все содержимое в строке
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  ListTile(
                                    title: Text(
                                      nameList.names[index],
                                      style: TextStyle(
                                        fontSize: Provider.of<Settings>(context).fontSize,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.grey // Серый цвет для темной темы
                                            : null, // Цвет по умолчанию для светлой темы
                                      ),
                                      textAlign: TextAlign.center, // Центрируем текст имени
                                    ),
                                    onLongPress: () {
                                      _showEditDialog(
                                        context,
                                        index,
                                        nameList.names[index],
                                      ); // Редактирование при долгом нажатии
                                    },
                                  ),
                                  // Добавляем линию (разделитель) под именем
                                  Container(
                                    height: 2.0, // Высота линии
                                    color: lineColor, // Цвет линии в зависимости от типа списка
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
                        _showAddNameDialog(context); // Показать диалог для добавления имени
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

                    onAddName(formattedName);
                    Navigator.of(context).pop(formattedName);
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

  void _showEditDialog(BuildContext context, int index, String currentName) {
    final nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Редактировать имя'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(hintText: 'Введите новое имя'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  onEditName(index, nameController.text);
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
                onEditTitle(titleController.text);
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
                onDeleteList();
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

class NameList {
  String title;
  ListType type;
  List<String> names;

  NameList({required this.title, required this.type, required this.names});
}

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