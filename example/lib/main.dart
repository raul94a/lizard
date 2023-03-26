
import 'package:flutter/material.dart';
import 'package:lizard/lizard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  //set encription key for store the responses
  Lizard.initializeEncryptionKey(key: 'my_encryption_key_secret');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }
  //
  void callEndpoints() {
    Future.microtask(() async {

      //See to how configure the online and offline cache
      final lizard =
          Lizard().setOfflineCache(seconds: 1500).setOnlineCache(seconds: 20);

      final response = await lizard
          .get(Uri.parse('https://rickandmortyapi.com/api/episode/?name=rick'));
      print(response.body);
      final e = await lizard
          .get(Uri.parse('https://rickandmortyapi.com/api/episode'));
      await lizard.get(Uri.parse('https://rickandmortyapi.com/api/location'));
      print(e.body);
      final a = await lizard
          .get(Uri.parse('https://rickandmortyapi.com/api/character'));
      print(e.body);
      final c = await lizard.get(
          Uri.parse('https://rickandmortyapi.com/api/character/?name=morty'));
      print(c.body);
    
    });
  }

  @override
  Widget build(BuildContext context) {
    //here the EPs will be called and their responses will be catched
    callEndpoints();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'You have pushed the button this many times:',
              ),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headline4,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  
}
