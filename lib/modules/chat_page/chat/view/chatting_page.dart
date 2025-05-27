import 'dart:async';
import 'dart:math';
import 'package:animated_icon/animated_icon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:privatily_app/modules/chat_page/chat/view/widgets/guestStatus.dart';
import 'package:privatily_app/modules/chat_page/chat/view/widgets/msgAnim_Icon.dart';
import 'package:privatily_app/modules/chat_page/chat/view/widgets/typing_indicator.dart';
import 'package:privatily_app/modules/chat_page/chat/view/widgets/variables/globalVariables.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../firebase_utils.dart';
import '../../logic.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_input_field.dart';
import 'widgets/common_questions.dart';
import 'widgets/date_label.dart';

class ChattingPage extends StatefulWidget {
  final String chatRoomId;
  final String receiverId;
  final String receiverName;

  const ChattingPage({
    Key? key,
    required this.chatRoomId,
    required this.receiverId,
    required this.receiverName,
  }) : super(key: key);

  @override
  State<ChattingPage> createState() => _ChattingPageState();
}

class _ChattingPageState extends State<ChattingPage> with WidgetsBindingObserver {
  final ChattingPageLogic logic = Get.put(ChattingPageLogic());
  final TextEditingController _messageController = TextEditingController();
  final RxBool showCommonQuestions = true.obs;

  Timer? _typingTimer;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    globalChatRoomId = widget.chatRoomId;
    WidgetsBinding.instance.addObserver(this);
    setUserOnline(globalChatRoomId);
  }

  @override
  void dispose() {
    logic.setUserOffline();
    WidgetsBinding.instance.removeObserver(this);
    _typingTimer?.cancel();
    Get.delete<ChattingPageLogic>();
    super.dispose();
  }

  Future<void> sendWithNameCheck(String message) async {
    // Name prompt removed – directly sending the message
    await logic.sendMessage(widget.chatRoomId, widget.receiverId, message);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9F9FB),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AdminStatus(adminUserId: widget.receiverId),
          ),
          Expanded(
            child: StreamBuilder(
              stream: logic.getMessages(widget.chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    showCommonQuestions.value = true;
                  });
                  return const Center(child: Text("No messages yet."));
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  showCommonQuestions.value = false;
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == logic.myFbAuth.currentUser?.uid;
                    final current = msg.timestamp ?? DateTime.now();

                    final next = index + 1 < messages.length
                        ? messages[index + 1].timestamp
                        : null;

                    final showDate = next == null ||
                        current.day != next.day ||
                        current.month != next.month ||
                        current.year != next.year;

                    return Column(
                      children: [
                        if (showDate) DateLabel(timestamp: current),
                        MessageBubble(message: msg.messageText, isMe: isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          MsgAnimIcon(guestUserId: widget.receiverId),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: CommonQuestions(
                onSelect: sendWithNameCheck, showToggle: showCommonQuestions),
          ),
          MessageInputField(
            controller: _messageController,
            onSend: (text) async {
              if (text.trim().isNotEmpty) {
                await sendWithNameCheck(text.trim());
                _messageController.clear();
              }
            },
            onChanged: (text) {
              final isTyping = text.trim().isNotEmpty;
              print("onChanged called. text: '$text', isTyping: $isTyping");

              logic.setTypingStatus(isTyping);

              if (_typingTimer != null && _typingTimer!.isActive) {
                print("Timer cancelled");
                _typingTimer!.cancel();
              }

              if (isTyping) {
                _typingTimer = Timer(const Duration(seconds: 1), () {
                  print("Timer expired, setting isTyping to false");
                  logic.setTypingStatus(false);
                });
              } else {
                print("Text field is empty");
              }
            },
          ),
        ],
      ),
    );
  }
}
