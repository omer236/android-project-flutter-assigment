import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:hello_me/Auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'dart:async';

AuthRepository auth;
TextEditingController passAuthController=new TextEditingController();
TextEditingController passController=new TextEditingController();
TextEditingController emailController=new TextEditingController();
final ScrollController _scrollController = ScrollController();
SnappingSheetController snappingSheetController=new SnappingSheetController();

bool flag=true;
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

// #docregion MyApp
class App extends StatelessWidget {
  // #docregion build
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {

    return FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
            body: Center(
                child: Text(snapshot.error.toString(),
                    textDirection: TextDirection.ltr)));
      }
      if (snapshot.connectionState == ConnectionState.done) {
        Oncreate();
        return ChangeNotifierProvider<AuthRepository>(child: MyApp(),
        create: (context) => auth);
      }
      return Center(child: CircularProgressIndicator());
        },
    );
  }
}

void Oncreate() {
  if(flag) {
    auth = AuthRepository.instance();
    flag=false;
  }
}

class MyApp extends StatelessWidget {
  // #docregion build
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData(
        primaryColor: Colors.red[900],
      ),
      home: RandomWords(),
    );
  }
}


class _RandomWordsState extends State<RandomWords> {

  final _suggestions = <WordPair>[];
  final _saved = <WordPair>{};
  final _biggerFont = TextStyle(fontSize: 18.0);

  // #enddocregion RWS-var

  // #docregion _buildSuggestions
  Widget _buildSuggestions() {
    return ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemBuilder:
            (context, i) {
          if (i.isOdd) return Divider();

          final index = i ~/ 2;
          if (index >= _suggestions.length) {
            _suggestions.addAll(generateWordPairs().take(10).toList());
          }
          return _buildRow(_suggestions[index]);
        });
  }

  Future<void> fillgrid() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentSnapshot querySnapshot = await firestore.collection('users').doc(
          auth.user.uid).get();
      final allData = querySnapshot.data();
      allData.forEach((key, value) {
        if(key!='avatar') {
          var pair = WordPair(value['first'], value['second']);
          _saved.add(pair);
        }
        else
          {
            imageUrl=value['link'];
            print(value['link']);
          }
      });
    } catch (e) {}
    _pushSaved();
  }

  Future<void> getAvatarLink() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentSnapshot querySnapshot = await firestore.collection('users').doc(
          auth.user.uid).get();
      final allData = querySnapshot.data();
      allData.forEach((key, value) {
        if(key=='avatar')
          imageUrl=value['link'];
      });
    } catch (e) {}
  }
  Future<void> adduser() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();
      var found = false;
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot querySnapshot = await firestore.collection('users').get();
      final allData = querySnapshot.docs.map((doc) => doc.id).toList();
      var iter = allData.iterator;
      for (var i = 0; i < allData.length; i++) {
        iter.moveNext();
        if (iter.current == auth.user.uid) {
          found = true;
        }
      }
      if (!found) {
        firestore.collection('users').doc(auth.user.uid).set({
        });
      }
    } catch (e) {}
  }

  Future<void> additem(var id, var first, var second) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      firestore.collection('users').doc(auth.user.uid).set({
        first + second: {
          'first': first,
          'second': second
        }
      }, SetOptions(merge: true));
    } catch (e) {}
  }

  Future<void> addavatar(var link) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      firestore.collection('users').doc(auth.user.uid).set({
        'avatar': {
          'link': link,
        }
      }, SetOptions(merge: true));
    } catch (e) {}
  }

  Future<void> removeitem(var id) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      firestore.collection('users').doc(auth.user.uid).update(
          {id: FieldValue.delete()});
    } catch (e) {}
  }

  Widget _buildRow(WordPair pair) {
    final alreadySaved = _saved.contains(pair);
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),

      trailing: Icon(
        alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved ? Colors.red : null,
      ),
      onTap: () {
        setState(() {
          if (alreadySaved) {
            removeitem(pair.first + pair.second);
            _saved.remove(pair);
          } else {
            additem(pair.first + pair.second, pair.first, pair.second);
            _saved.add(pair);
          }
        });
      },
    );
  }

  Widget build(BuildContext context) {
    getAvatarLink();
    return Scaffold(
      appBar: AppBar(
        title: Text('Startup Name Generator'),
        actions: [
          IconButton(icon: Icon(Icons.favorite), onPressed: fillgrid),
          IconButton(icon: auth.status == Status.Authenticated ? Icon(
              Icons.exit_to_app) : Icon(Icons.login), onPressed: _login)
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: auth.status == Status.Authenticated ?
      InkWell(
          onTap: () {
            setState(() {
              _toggle();
            });
          },
          child: SnappingSheet(
            controller: snappingSheetController,
            lockOverflowDrag: true,
            snappingPositions: [
              SnappingPosition.factor(
                positionFactor: 0.0,
                grabbingContentOffset: GrabbingContentOffset.top,
              ),
              SnappingPosition.factor(
                snappingCurve: Curves.elasticOut,
                snappingDuration: Duration(milliseconds: 1750),
                positionFactor: 0.25,
              ),
              SnappingPosition.factor(positionFactor: 0.9),
            ],
            child: _buildSuggestions(),
            grabbingHeight: 45,
            grabbing: Container(
                padding: EdgeInsets.only(
                  left: 7,
                  right: 7,
                  top: 12,
                  bottom: 7,
                ),
                color: Colors.green,
                child:
                ListView(
                    children: [Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text('Welcome back, ' + auth.user.email,
                                  style: new TextStyle(
                                      fontSize: 16, color: Colors.white))
                            ],
                          ),
                          Column(
                            children: [Icon(
                                isToggled
                                    ? Icons.keyboard_arrow_down_outlined
                                    : Icons.keyboard_arrow_up_outlined,
                                color: Colors.white)
                            ],
                          )
                        ])
                    ])
            ),
            sheetBelow: SnappingSheetContent(
              childScrollController: _scrollController,
              draggable: true,
              child: SnappingContent(
                controller: _scrollController,
              ),
            ),
          )) : _buildSuggestions(),
    );
  }

  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Saved Suggestions'),
            ),
            body: _buildDelete(),
          );
        },
      ),
    );
  }

  Widget _buildDelete() {
    return ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemBuilder:
            (context, i) {
          if (i < _saved.length) {
            return _buildDeleteRow(_saved.elementAt(i));
          }
        });
  }

  Widget _buildDeleteRow(WordPair pair) {
    if (_saved.contains(pair)) {
      return ListTile(
        title: Text(
          pair.asPascalCase,
          style: _biggerFont,
        ),
        trailing: Icon(
          Icons.delete_outline,
          color: Colors.red[900],
        ),
        onTap: () {
          setState(() {
            removeitem(pair.first + pair.second);
            _saved.remove(pair);
            Navigator.of(context).pop();
            _pushSaved();
          });
        },
      );
    }
    return null;
  }

  void _login() {
    if (auth.status == Status.Authenticated) {
      auth.signOut();
      imageUrl=null;
      setState(() {

      });
      _saved.clear();
    }
    else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return Consumer<AuthRepository>(

                builder: (context, auth, _) {
                  if (auth.status == Status.Authenticated) {
                    Navigator.of(context).pop();
                  }

                  return Scaffold(
                      appBar: AppBar(
                        title: Text('Login'),
                        centerTitle: true,
                      ),
                      body:
                      Container(
                          padding: EdgeInsets.only(
                            left: 15,
                            right: 15,
                            top: 15,
                            bottom: 15,
                          ),
                          child: ListView(
                            children: [
                              Text(
                                'Welcome to Startup Names Generator, please log in below',
                                style: _biggerFont,
                              ),
                              Padding(padding: EdgeInsets.all(10)),
                              TextField(
                                controller: emailController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Email',
                                ),
                              ),
                              Padding(padding: EdgeInsets.all(10)),
                              TextField(
                                controller: passController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Password',
                                ),
                              ),
                              Padding(padding: EdgeInsets.all(10)),
                              TextButton(onPressed: onPressed,


                                  style: ButtonStyle(
                                      backgroundColor: MaterialStateProperty
                                          .resolveWith((states) => Colors.red),
                                      shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                              borderRadius: BorderRadius
                                                  .circular(18.0),
                                              side: BorderSide(
                                                  color: Colors.red)
                                          )
                                      )
                                  ),
                                  child: Text(
                                    'Log in',
                                    style: new TextStyle(
                                        fontSize: 12, color: Colors.white),
                                  )),
                              Padding(padding: EdgeInsets.all(10)),
                              TextButton(onPressed: onRegisterPressed,


                                  style: ButtonStyle(
                                      backgroundColor: MaterialStateProperty
                                          .resolveWith((states) =>
                                      Colors.green),
                                      shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                              borderRadius: BorderRadius
                                                  .circular(18.0),
                                              side: BorderSide(
                                                  color: Colors.green)
                                          )
                                      )
                                  ),
                                  child: Text(
                                    'New user? Click to sign up',
                                    style: new TextStyle(
                                        fontSize: 12, color: Colors.white),
                                  ))
                            ],
                          )

                      )
                  );
                }

            );
          },
        ),
      );
    }
  }

  void onPressed() async {
    if (await auth.signIn(emailController.text, passController.text)) {
      getAvatarLink();
      adduser();
      emailController.text = '';
      passController.text = '';
      var iter = _saved.iterator;
      for (var i = 0; i < _saved.length; i++) {
        iter.moveNext();
        additem(iter.current.first + iter.current.second, iter.current.first,
            iter.current.second);
      }
      setState(() {

      });
    }
    else {
      final snackBar = SnackBar(
          content: Text('There was an error logging in to the app'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }


  void onRegisterPressed() async {
    passAuthController.text = '';
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (builder) {
          return new Container(
              height: 200,
              padding: EdgeInsets.only(
                left: 15,
                right: 15,
                top: 15,
                bottom: 15,
              ),
              child: ListView(
                children: [
                  Center(
                      child: Text(
                        'Please confirm your password below:',
                        style: _biggerFont,
                      )),
                  Padding(padding: EdgeInsets.all(10)),
                  TextField(
                    controller: passAuthController,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Password',
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(10)),
                  Center(
                      child: TextButton(onPressed: onRegisterPassValidPressed,
                          style: ButtonStyle(
                              backgroundColor: MaterialStateProperty
                                  .resolveWith((states) => Colors.green),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius
                                          .zero,
                                      side: BorderSide(
                                          color: Colors.green)
                                  )
                              )
                          ),
                          child: Text(
                            'Confirm',
                            style: new TextStyle(
                                fontSize: 12, color: Colors.white),
                          )))
                ],
              )
          );
        }
    );
  }

  void onRegisterPassValidPressed() async {
    if (passController.text == passAuthController.text) {
      await auth.signUp(emailController.text, passController.text);
      adduser();
      emailController.text = '';
      passController.text = '';
      var iter = _saved.iterator;
      for (var i = 0; i < _saved.length; i++) {
        iter.moveNext();
        additem(iter.current.first + iter.current.second, iter.current.first,
            iter.current.second);
      }
      setState(() {

      });
    }
    else {
      Navigator.pop(context);
      final snackBar = SnackBar(
          content: Text('Passwords must match'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  var isToggled = false;

  void _toggle() {
    if (isToggled) {
      snappingSheetController.setSnappingSheetFactor(0.05);
      isToggled = false;
    }
    else {
      snappingSheetController.setSnappingSheetFactor(0.25);
      isToggled = true;
    }
  }

  SnappingContent({ScrollController controller}) {
    return Container(
        padding: EdgeInsets.only(
          left: 15,
          right: 15,
          top: 15,
          bottom: 15,
        ),
        color: Colors.white,
        child:
        ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Container(
                        height: 100.0,
                        width: 100.0,
                        decoration: new BoxDecoration(
                          color: const Color(0xff7c94b6),
                          borderRadius: BorderRadius.all(
                              const Radius.circular(50.0)),
                          border: Border.all(color: const Color(0xFF28324E)),
                        ),
                        child: CircleAvatar(
                            backgroundImage: NetworkImage(imageUrl!=null ? imageUrl:
                                'https://firebasestorage.googleapis.com/v0/b/hellome-4d0f3.appspot.com/o/dfault.jpg?alt=media&token=7cf95d56-c94b-4867-83d6-d1b333488efb')
                        )
                    )
                  ],
                ),
                Column(
                  children: [
                    Text(
                      auth.user.email,
                      style: _biggerFont,
                    ),
                    Padding(padding: EdgeInsets.all(10)),
                    TextButton(onPressed: onChangeAvatarPressed,
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty
                                .resolveWith((states) => Colors.green),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                    side: BorderSide(
                                        color: Colors.green)
                                )
                            )
                        ),
                        child: Text(
                          'Change avatar',
                          style: new TextStyle(
                              fontSize: 12, color: Colors.white),
                        ))
                  ],
                )
              ],
            )
          ],
        )
    );
  }
  var imageUrl;
  void onChangeAvatarPressed() async {
    final _firebaseStorage = FirebaseStorage.instance;
    final _imagePicker = ImagePicker();
    PickedFile image;
    //Select Image
    image = await _imagePicker.getImage(source: ImageSource.gallery);
    var file = File(image.path);
    if (image != null) {
      //Upload to Firebase
      var snapshot = await _firebaseStorage
          .ref()
          .child('avatars/'+auth.user.uid)
          .putFile(file);
      var downloadUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        imageUrl = downloadUrl;
        removeitem('avatar');
        addavatar(imageUrl);
      });
    }
  }
}


class RandomWords extends StatefulWidget {
  @override
  State<RandomWords> createState() => _RandomWordsState();
}


