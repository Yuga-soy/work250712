import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Generated App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF2196f3),
        canvasColor: Color(0xFFfafafa),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  String dropdownValue = "Child 1";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App Name'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.insert_emoticon),
            onPressed: iconButtonPressed,
            iconSize: 48.0,
            color: Color(0xFF000000),
          ),
          DropdownButton<String>(
            onChanged: (String? value) {
              setState(() {
                dropdownValue = value ?? "Child 1";
              });
              popupButtonSelected(value);
            },
            value: dropdownValue,
            style: TextStyle(
              fontSize: 12.0,
              color: Color(0xFF202020),
              fontWeight: FontWeight.w200,
              fontFamily: "Roboto",
            ),
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                value: "Child 1",
                child: Text("Child 1"),
              ),
              DropdownMenuItem<String>(
                value: "Child 2",
                child: Text("Child 2"),
              ),
              DropdownMenuItem<String>(
                value: "Child 3",
                child: Text("Child 3"),
              ),
            ],
          ),
          Divider(
            color: Color(0xFF5E5E5E),
          ),
          Card(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void popupButtonSelected(String? value) {}

  void iconButtonPressed() {}
}