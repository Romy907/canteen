import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class StudentInviteFriendScreen extends StatelessWidget {
  const StudentInviteFriendScreen({super.key});

  void _inviteFromContacts(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact picker not implemented yet')),
    );
  }

  void _copyReferralCode(BuildContext context) {
    const referralCode = "ABC123";
    Clipboard.setData(const ClipboardData(text: referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral code copied to clipboard')),
    );
  }

  void _shareReferralCode(BuildContext context) {
    const referralCode = "ABC123";
    Share.share("Join using my referral code: $referralCode");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
  title: const Text("Invite Friends"),
  backgroundColor: Colors.white,
  foregroundColor: Colors.black87,
  elevation: 1,
  leading: IconButton(
    icon: Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(25),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black87),
    ),
    onPressed: () => Navigator.of(context).pop(),
  ),
),
body: Padding(
  padding: const EdgeInsets.all(16.0),
  child: Column(
    children: [
      const SizedBox(height: 130),


            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 234, 192, 214),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    "Your Referral Code",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      "ABC123",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _copyReferralCode(context),
                        icon: const Icon(Icons.copy, color:  Color.fromARGB(237, 12, 1, 1)),
                        label: const Text(
                          "Copy Code",
                          style: TextStyle(color: Color.fromARGB(237, 12, 1, 1)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:  Color.fromARGB(255, 241, 237, 239),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _shareReferralCode(context),
                        icon: const Icon(Icons.share, color: Colors.white),
                        label: const Text(
                          "Share Code",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 222, 7, 115),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(25),
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
                        "Share your referral code with friends",
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
                              if (index != 2) 
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
