import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  final List<Map<String, String>> faqs = [
    {
      'question': 'How can I place an order?',
      'answer': 'You can place an order through the canteen app by selecting items and adding them to your cart.',
    },
    {
      'question': 'What payment methods are supported?',
      'answer': 'We accept credit/debit cards, UPI, and wallet payments.',
    },
    {
      'question': 'Can I cancel my order?',
      'answer': 'Yes, you can cancel your order before it is prepared. Go to "My Orders" to manage your orders.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FAQs'),
      ),
      body: ListView.builder(
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          return ExpansionTile(
            title: Text(faqs[index]['question']!, style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(faqs[index]['answer']!),
              ),
            ],
          );
        },
      ),
    );
  }
}
