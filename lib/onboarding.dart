// Добавляем новый виджет для обучения
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart' show NameListHome;

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
        // 1. Приветственный экран
        PageViewModel(
          title: "Помянник",
          body: "Добро пожаловать в Помянник - современное приложение для поминовения живых "
              "и усопших. Здесь вы можете создавать списки имён, подобно церковным запискам, "
              "и молиться за своих близких.",
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

        // 2. Списки
        PageViewModel(
          title: "Списки",
          body: "Списки - это аналог церковных записок. Они бывают двух видов:\n\n• О здравии - "
              "для поминовения живых\n• О упокоении - для поминовения усопших\n\n"
              "Вы можете создавать несколько списков для разных нужд (например, для разных храмов).",
          image: Center(
            child: Container(
              margin: EdgeInsets.only(top: 20),
              child: Image.asset(
                'assets/images/list.png', // Путь к вашему скриншоту
                width: MediaQuery.of(context).size.width * 0.8,
                fit: BoxFit.contain,
              ),
            ),
          ),
          decoration: pageDecoration,
        ),

        // 3. Добавление списка
        PageViewModel(
          title: "Добавление списка",
          body: "Нажмите на эту кнопку в правом верхнем углу, чтобы создать новый список."
              " Вы сможете выбрать его тип (о здравии или упокоении) и дать ему понятное для Вас название.",
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

        // 4. Переключение между списками
        PageViewModel(
          title: "Переключение между списками",
          body: "Сдвиньте список влево или вправо для переключения между вашими списками",
          image: Center(
            child: Container(
              margin: EdgeInsets.only(top: 20),
              child: Image.asset(
                'assets/images/onboarding-swipe-right-left.png',
                width: MediaQuery.of(context).size.width * 0.8,
                fit: BoxFit.contain,
              ),
            ),
          ),
          decoration: pageDecoration,
        ),

        // 5. Быстрый выбор списков
        PageViewModel(
          title: "Быстрый выбор списков",
          body: "Для удобного переключения между списками сдвиньте экран вверх от кнопки "
              "\"Добавить имя\". В появившемся меню вы сможете быстро выбрать нужный список "
              "без перелистывания.",
          image: Center(
            child: Container(
              margin: EdgeInsets.only(top: 20),
              child: Image.asset(
                'assets/images/onboarding-swipe-up.png',
                width: MediaQuery.of(context).size.width * 0.8,
                fit: BoxFit.contain,
              ),
            ),
          ),
          decoration: pageDecoration,
        ),

        // 6. Добавление имени
        PageViewModel(
          title: "Добавление имени",
          bodyWidget: Column(
            children: [
              Text(
                "Чтобы добавить имя в текущий список, нажмите на кнопку 'Добавить имя' внизу экрана."
                    "В появившемся меню Вам будет доступна настройка дополнительной информации, "
                    "такой как сан, статус, время поминовения, пол.",
                style: TextStyle(
                  fontSize: 18.0,
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
            contentMargin: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
          ),
        ),

        // 7. Редактирование и удаление
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
        size: Size(6.0, 6.0), // Уменьшенный размер точек
        color: isDarkMode ? Colors.grey[600]! : Colors.grey,
        activeColor: isDarkMode ? Colors.white : theme.primaryColor,
        activeSize: Size(15.0, 6.0), // Уменьшенный активный размер
        spacing: EdgeInsets.symmetric(horizontal: 3), // Уменьшенное расстояние между точками
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}