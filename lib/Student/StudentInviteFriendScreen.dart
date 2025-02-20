import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class StudentInviteFriendScreen extends StatelessWidget {
  const StudentInviteFriendScreen({super.key});

  void _inviteFromContacts(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact picker not implemented yet')),
    );
  }

  void _inviteViaReferralLink(BuildContext context) {
    const referralLink = "https://example.com/referral?code=ABC123";
    Share.share("Join using my referral link: $referralLink");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Invite Friends")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 130),

            // Invite via Referral Link button
            ElevatedButton.icon(
              onPressed: () => _inviteViaReferralLink(context),
              icon: const Icon(Icons.link, color: Color.fromARGB(255, 222, 7, 115)),
              label: const Text(
                "Invite via Referral Link",
                style: TextStyle(color: Color.fromARGB(255, 222, 7, 115), fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 234, 192, 214),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // How Referral Works?
                        Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    spreadRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "How referral works?",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: List.generate(3, (index) {
                      List<String> steps = [
                        "Share referral code or link with friends",
                        "When they place their first order, you both earn rewards",
                        "Redeem your coupons at checkout to claim your rewards"
                      ];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.grey.shade300,
                                child: Text(
                                  "${index + 1}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (index != 2) // Add dotted line for steps except last one
                                Container(
                                  height: 30,
                                  width: 2,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: Colors.grey,
                                        width: 1,
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                steps[index],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),

            const Spacer(),


            // Invite from Contacts button at the bottom
            ElevatedButton.icon(
              onPressed: () => _inviteFromContacts(context),
              icon: const Icon(Icons.contacts, color: Colors.white),
              label: const Text(
                "Invite from Contacts",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 222, 7, 115),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
