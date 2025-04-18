import 'package:flutter/material.dart';
import 'package:parkingapp/widgets/TopBar.dart' show TopBar;

class SupportScreen extends StatefulWidget {
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> topics = ['General', 'Account', 'Payment', 'Security'];
  int selectedTopicIndex = 0;

  final List<Map<String, String>> faqList = [
    {
      'question': 'How do I manage my notifications?',
      'answer':
          'To manage notifications, go to "Settings", select "Notification Settings", and customize your preferences.'
    },
    {
      'question': 'How do I start a guided meditation session?',
      'answer': 'Tap "Start Session" on the home screen.'
    },
    {
      'question': 'How do I join a support group?',
      'answer': 'Navigate to the "Community" tab and select a group.'
    },
    {
      'question': 'Is my data safe and private?',
      'answer': 'Yes, we follow industry-standard security protocols.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              greeting: 'Help Center',
              showBackButton: true,
              onBackPressed: () => Navigator.pop(context),
            ),
            TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              indicatorColor: Colors.black,
              tabs: const [
                Tab(text: "FAQ"),
                Tab(text: "Contact Us"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  buildFAQTab(),
                  Center(child: Text("Contact Form Coming Soon...")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFAQTab() {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: List.generate(topics.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ChoiceChip(
                  label: Text(topics[index]),
                  selected: selectedTopicIndex == index,
                  onSelected: (val) {
                    setState(() => selectedTopicIndex = index);
                  },
                  selectedColor: Colors.black,
                  labelStyle: TextStyle(
                    color: selectedTopicIndex == index
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              );
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: "Search for help",
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: faqList.length,
            itemBuilder: (context, index) {
              final item = faqList[index];
              return ExpansionTile(
                title: Text(item['question']!),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(item['answer'] ?? "Answer coming soon..."),
                  )
                ],
              );
            },
          ),
        )
      ],
    );
  }
}
