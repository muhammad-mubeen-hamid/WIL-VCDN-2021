import 'dart:html' as HTML;
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:easy_sidemenu/easy_sidemenu.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pwot/pages/auth/pages/auth.dart';
import 'package:pwot/pages/dashboard.dart';
import 'package:pwot/pages/feed.dart';
import 'package:pwot/utility/app_colors.dart';
import 'package:flash/flash.dart';
import 'package:firebase/firebase.dart' as FB;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData.dark().copyWith(
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)),
      home: const MyHomePage(title: 'Playwrite Occupational Therapy'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PageController page = PageController();
  var postTextController = TextEditingController();
  final FocusNode focusNodePost = FocusNode();
  bool loader = false;
  bool clear = true;
  String storagePath = "null";
  Uri? fileDownloadURL;
  HTML.File? file;
  String? fileName;

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: AppColor.bgSideMenu,
      ),
      body: SideDrawer(width, height),
      floatingActionButton: FloatingActionButton(onPressed: () {
        bool loader_2 = false;
        context.showFlashDialog(
          barrierDismissible: false,
            backgroundColor: AppColor.bgColor,
            margin: EdgeInsets.symmetric(horizontal: width * 0.2),
            persistent: true,
            title: const Text("Add a new post"),
            content: Container(
              height: height * 0.3,
              child: loader_2 == true ? Center(child: CircularProgressIndicator(color: AppColor.yellow,),): Column(
                children: [
                  Expanded(
                    flex: 3,
                      child:  Container(
                        child: Column(
                          children: [
                            Expanded(
                                child: Card(
                                  elevation: 2.0,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: <Widget>[
                                        SingleChildScrollView(
                                          padding: EdgeInsets.symmetric(horizontal: 10),
                                          child: TextField(
                                            focusNode: focusNodePost,
                                            controller: postTextController,
                                            keyboardType: TextInputType.multiline,
                                            style: TextStyle(color: AppColor.bgSideMenu),
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              icon: Icon(
                                                FontAwesomeIcons.pencilAlt,
                                                color: AppColor.bgSideMenu,
                                                size: 22.0,
                                              ),
                                              hintText: 'Enter your post here...',
                                              hintStyle: TextStyle(color: AppColor.bgSideMenu),
                                            ),
                                            onSubmitted: (_) {
                                              focusNodePost.requestFocus();
                                            },
                                            minLines: 1,
                                            maxLines: 3,
                                            maxLength: 256,
                                          ),
                                        ),
                                        Container(
                                          width: width * 0.4,
                                          height: 5.0,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.all(Radius.circular(25)),
                                            color: AppColor.yellow,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                            ),
                          ],
                        ),
                      )),
                  Expanded(
                      child: Column(
                        children: [
                          fileName == null ? Text("No Image Selected!"): FittedBox(child: Text(fileName!)),
                          Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                              color: AppColor.bgSideMenu),
                          child: MaterialButton(
                            highlightColor: Colors.transparent,
                            child: FittedBox(
                                child: loader ? const Center(child: CircularProgressIndicator()):
                                const Text('Select Image', style: TextStyle(color: Colors.white, fontSize: 12)
                                )
                            ),
                            onPressed: () {
                              HTML.FileUploadInputElement picker = HTML.FileUploadInputElement()..accept = 'image/*';
                              picker.click();

                              picker.onChange.listen((event) {
                                file = picker.files?.first;
                                setState(() {
                                  fileName = file!.name;
                                });
                                context.showSuccessBar(
                                    content: Row(
                                      children: [
                                        const Text("Image selected successfully - "),
                                        Text(file!.name, style: const TextStyle(fontWeight: FontWeight.bold),),
                                      ],
                                    ),
                                    duration: Duration(seconds: 5)
                                );
                                final reader = HTML.FileReader();
                                reader.readAsDataUrl(file!);
                                reader.onLoadEnd.listen((event) {

                                });
                              });
                            },
                          ),
                    ),
                        ],
                      )
                  )
                ],
              ),
            ),
            negativeActionBuilder: (context, controller, _) {
              return Container(
                decoration: BoxDecoration(
                    borderRadius:
                    const BorderRadius.all(Radius.circular(5.0)),
                    color: AppColor.bgSideMenu),
                child: MaterialButton(
                  highlightColor: Colors.transparent,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: height * 0.01,
                        horizontal: width * 0.03),
                    child: const Text('Post', style: TextStyle(color: Colors.white)),
                  ),
                  onPressed: () async {
                    if (FirebaseAuth.instance.currentUser == null) {
                      context.showErrorBar(content: const Text("Please log in to add new post."));
                      return;
                    }
                    if (postTextController.text == "" || postTextController.text.isEmpty){
                      context.showErrorBar(content: const Text("Post can not be empty."));
                      return;
                    }
                    if (file == null){
                      context.showErrorBar(content: const Text("Please select an image."));
                      return;
                    }
                    await uploadImage();

                  },
                ),
              );
            },
            positiveActionBuilder: (context, controller, _) {
              return Container(
                decoration: BoxDecoration(
                    borderRadius:
                    const BorderRadius.all(Radius.circular(5.0)),
                    color: Colors.red.shade900),
                child: MaterialButton(
                  highlightColor: Colors.transparent,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: height * 0.01,
                        horizontal: width * 0.03),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  onPressed: () {
                      WidgetsBinding.instance?.addPostFrameCallback((_) => setState(() {
                        loader_2 = true;
                      }));
                    //controller.dismiss();
                  },
                ),
              );
            }
        );
      }, child: Icon(Icons.add, color: AppColor.bgColor,), backgroundColor: AppColor.bgSideMenu,),
    );
  }

  void pickImage() {
    HTML.FileUploadInputElement picker = HTML.FileUploadInputElement()..accept = 'image/*';
    picker.click();

    picker.onChange.listen((event) {
      file = picker.files?.first;

      final reader = HTML.FileReader();
      reader.readAsDataUrl(file!);
      reader.onLoadEnd.listen((event) {
        setState(() {
          fileName = file!.name;
        });
      });
    });
  }

  Future<String> uploadImage() async {
    final datTime = DateTime.now().toIso8601String();
    final userID = FirebaseAuth.instance.currentUser?.uid;
    final path = '$userID/$datTime';
    String result = await upload(path, file);

    return result;
  }

  Future<String> upload(String path, var file) async {
    String status = "null";
    await FB.storage().refFromURL('gs://wilvcdn2021.appspot.com').child(path).put(file).future.then((p0) async {
      await p0.ref.getDownloadURL().then((value) {
        storagePath = path;
        clear = false;
        status = value.toString();
      });
    });
    return status;
  }

  Widget SideDrawer(double width, double height) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SideMenu(
          controller: page,
          style: SideMenuStyle(
              openSideMenuWidth: width * 0.2,
              displayMode: SideMenuDisplayMode.auto,
              hoverColor: AppColor.white.withAlpha(100),
              selectedColor: AppColor.yellow,
              selectedTitleTextStyle: TextStyle(color: AppColor.white),
              unselectedTitleTextStyle: TextStyle(color: AppColor.white),
              selectedIconColor: AppColor.white,
              unselectedIconColor: AppColor.white,
              backgroundColor: AppColor.bgSideMenu
            // openSideMenuWidth: 200
          ),
          title: Column(
            children: [
              ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: height,
                    maxWidth: width * 0.01,
                  ),
                  child: Icon(Icons.image)
              ),
              Divider(
                indent: 8.0,
                endIndent: 8.0,
              ),
            ],
          ),
          footer: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('${FirebaseAuth.instance.currentUser?.displayName}', style: TextStyle(color: AppColor.yellow)),
          ),
          items: [
            SideMenuItem(
              priority: 0,
              title: 'Feed Page',
              onTap: () {
                page.jumpToPage(0);
              },
              icon: Icons.supervisor_account,
            ),
            SideMenuItem(
              priority: 1,
              title: 'Dashboard',
              onTap: () {
                page.jumpToPage(1);
              },
              icon: Icons.home,
            ),
            SideMenuItem(
              priority: 2,
              title: 'Messages',
              onTap: () {
                page.jumpToPage(2);
              },
              icon: Icons.file_copy_rounded,
            ),
            SideMenuItem(
              priority: 3,
              title: 'Help',
              onTap: () {
                page.jumpToPage(3);
              },
              icon: Icons.file_copy_rounded,
            ),
            FirebaseAuth.instance.currentUser == null ?
            SideMenuItem(
              priority: 4,
              title: 'Sign In',
              onTap: () async {
                page.jumpToPage(4);
              },
              icon: Icons.exit_to_app,
            ): SideMenuItem(
              priority: 4,
              title: 'Sign Out',
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                setState(() {});
                page.jumpToPage(1);
              },
              icon: Icons.exit_to_app,
            ),
          ],
        ),
        Expanded(
          child: PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: page,
            children: [
              Feed(),
              Dashboard(),
              Dashboard(),
              Dashboard(),
              Auth(),
            ],
          ),
        ),
      ],
    );
  }

  //not used
  Future<bool> delete() async {
    bool status = false;
    FB.storage().refFromURL('gs://wilvcdn2021.appspot.com').child(storagePath).delete().then((value) {
      status = true;
    });

    return status;
  }
  
}

class AddPost extends StatefulWidget {
  const AddPost({Key? key}) : super(key: key);

  @override
  _AddPostState createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text("Hi"),
    );
  }
}

