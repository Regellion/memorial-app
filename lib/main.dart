import 'package:flutter/material.dart';

void main() {
  runApp(NameListApp());
}

class NameListApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Name List App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: NameListHome(), // По умолчанию открывается "Помянник"
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

  final PageController _pageController = PageController(); // Контроллер для PageView
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
        _currentPageIndex = nameLists.isEmpty ? 0 : _currentPageIndex.clamp(0, nameLists.length - 1);
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
      _currentPageIndex = nameLists.isEmpty ? 0 : _currentPageIndex.clamp(0, nameLists.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Помянник'),
        actions: [
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
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Меню',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
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
          ],
        ),
      ),
      body: nameLists.isEmpty
          ? Center(
        child: Text('Нет списков. Добавьте новый список.'),
      )
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
            onEditName: (nameIndex, newName) =>
                _editNameInList(index, nameIndex, newName),
            onDeleteName: (nameIndex) => _deleteNameFromList(index, nameIndex),
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
                    decoration: InputDecoration(labelText: 'Название списка'),
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
                    if (titleController.text.isNotEmpty) {
                      _addNewList(titleController.text, selectedType);
                      Navigator.of(context).pop();
                    }
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  nameList.title,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
        Text(
          nameList.type == ListType.health ? 'О здравии' : 'Об упокоении',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: nameList.names.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(nameList.names[index]),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        _showEditDialog(context, index, nameList.names[index]);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        onDeleteName(index);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        //добавляем виджет Text
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Добавить имя', // Это строка будет отображаться постоянно
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  _showAddNameDialog(context); // Показать диалог для добавления имени
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddNameDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Добавить имя'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(hintText: 'Введите имя'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  onAddName(nameController.text);
                  Navigator.of(context).pop();
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
                if (titleController.text.isNotEmpty) {
                  onEditTitle(titleController.text);
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
      ),
      body: Center(
        child: Text('Здесь будут новости приложения'),
      ),
    );
  }
}

enum ListType { health, repose }

class NameList {
  String title;
  ListType type;
  List<String> names;

  NameList({
    required this.title,
    required this.type,
    required this.names,
  });
}