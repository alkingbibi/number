import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

const firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyCNa06fYyioZKaGtIGq_u4WpfSOja0ubt0",
  authDomain: "yamani-app-alking.firebaseapp.com",
  projectId: "yamani-app-alking",
  storageBucket: "yamani-app-alking.appspot.com",
  messagingSenderId: "524330739259",
  appId: "1:524330739259:web:e29b6e98e01d7bac0fde1e",
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  runApp(const YamaniApp());
}

class YamaniApp extends StatelessWidget {
  const YamaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'يماني كاشف',
      theme: ThemeData(
        primaryColor: const Color(0xFFCE1126),
        scaffoldBackgroundColor: Colors.grey[50],
        fontFamily: 'Tajawal',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFCE1126),
          foregroundColor: Colors.white,
          elevation: 5,
          centerTitle: true,
          titleTextStyle: TextStyle(fontFamily: 'Tajawal', fontSize: 22, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF000000),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', '')],
      locale: const Locale('ar', ''),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    const ContributionPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.sync), label: 'المساهمة'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFFCE1126),
        unselectedItemColor: Colors.grey[600],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController phoneController = TextEditingController();
  Widget resultWidget = const SizedBox.shrink();
  bool isLoading = false;

  void searchNumber() async {
    final String number = phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (number.isEmpty) {
      setState(() {
        resultWidget = _buildInfoCard('الرجاء إدخال رقم للبحث.', isError: true);
      });
      return;
    }

    setState(() { isLoading = true; resultWidget = const SizedBox.shrink(); });

    try {
      final doc = await FirebaseFirestore.instance.collection('numbers').doc(number).get();

      if (doc.exists) {
        final data = doc.data()!;
        final List<String> names = List<String>.from(data['names'] ?? []);
        final int count = data['count'] ?? 0;
        setState(() {
          resultWidget = _buildResultCard(number, names, count);
        });
      } else {
        setState(() {
          resultWidget = _buildInfoCard('هذا الرقم غير موجود في قاعدة البيانات حالياً.', isError: true);
        });
      }
    } catch (e) {
      setState(() {
        resultWidget = _buildInfoCard('حدث خطأ في الاتصال، يرجى التحقق من الإنترنت.', isError: true);
      });
    }

    setState(() { isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('🇾🇪'),
            SizedBox(width: 8),
            Text('يماني كاشف'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'أدخل الرقم هنا',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.phone_android),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isLoading ? null : searchNumber,
              icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3.0,)) : const Icon(Icons.search),
              label: Text(isLoading ? 'جاري البحث...' : 'بـحـث'),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: resultWidget,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String number, List<String> names, int count) {
    final nameCounts = <String, int>{};
    for (var name in names) {
      nameCounts[name] = (nameCounts[name] ?? 0) + 1;
    }
    final sortedNames = nameCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final mostCommonName = sortedNames.isNotEmpty ? sortedNames.first.key : 'غير معروف';

    return Card(
      key: ValueKey('result'),
      elevation: 5,
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('الاسم الأكثر شيوعاً:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800])),
            Text(mostCommonName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Divider(),
            Text('الرقم: $number', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('تم العثور على ${names.length} اسم مختلف لهذا الرقم.'),
            Text('ساهم في تحديده $count مستخدم.'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String message, {bool isError = false}) {
    return Card(
      key: ValueKey(message),
      elevation: 5,
      color: isError ? Colors.red[50] : Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(message, style: TextStyle(color: isError ? Colors.red[800] : Colors.blue[800], fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Icon(isError ? Icons.error_outline : Icons.info_outline, color: isError ? Colors.red[800] : Colors.blue[800]),
          ],
        ),
      ),
    );
  }
}

class ContributionPage extends StatefulWidget {
  const ContributionPage({super.key});

  @override
  State<ContributionPage> createState() => _ContributionPageState();
}

class _ContributionPageState extends State<ContributionPage> {
  bool isSyncing = false;
  String syncStatus = 'ساهم/ي في بناء أكبر قاعدة بيانات يمنية.';
  Color statusColor = Colors.black;

  Future<void> syncContacts() async {
    setState(() {
      isSyncing = true;
      syncStatus = 'جاري طلب الإذن للوصول لجهات الاتصال...';
      statusColor = Colors.orange;
    });

    final permission = await Permission.contacts.request();
    if (permission.isGranted) {
      setState(() { syncStatus = 'تم الحصول على الإذن. جاري القراءة...'; });
      final List<Contact> contacts = await ContactsService.getContacts(withThumbnails: false);
      setState(() { syncStatus = 'تم قراءة ${contacts.length} اسم. جاري الرفع للسحابة...'; });

      final batch = FirebaseFirestore.instance.batch();
      
      for (final contact in contacts) {
        if (contact.phones != null && contact.phones!.isNotEmpty) {
          for (final phone in contact.phones!) {
            if (phone.value != null) {
              final cleanNumber = phone.value!.replaceAll(RegExp(r'[^0-9+]'), '');
              if (cleanNumber.length > 6) {
                final docRef = FirebaseFirestore.instance.collection('numbers').doc(cleanNumber);
                batch.set(
                  docRef,
                  {
                    'names': FieldValue.arrayUnion([contact.displayName ?? 'اسم غير معروف']),
                    'count': FieldValue.increment(1),
                  },
                  SetOptions(merge: true),
                );
              }
            }
          }
        }
      }

      await batch.commit();
      setState(() {
        syncStatus = 'اكتملت المساهمة بنجاح! شكراً لمساهمتك القيمة!';
        statusColor = Colors.green;
        isSyncing = false;
      });

    } else {
      setState(() {
        syncStatus = 'تم رفض الإذن. لا يمكن المساهمة بدون موافقتك.';
        statusColor = Colors.red;
        isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المساهمة المجتمعية')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.people_alt, size: 80, color: Color(0xFFCE1126)),
            const SizedBox(height: 16),
            const Text('كن جزءاً من الحل!', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('بمساهمتك بجهات اتصالك، أنت تساعد/ين آلاف اليمنيين على كشف الأرقام المجهولة. بياناتك آمنة وتستخدم فقط لتحسين قاعدة البيانات للجميع.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: isSyncing ? null : syncContacts,
              icon: isSyncing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3.0,)) : const Icon(Icons.cloud_upload),
              label: const Text('المساهمة بجهات الاتصال'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            ),
            const SizedBox(height: 24),
            Text(syncStatus, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
          ],
        ),
      ),
    );
  }
}


