  import 'dart:ui';

  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:get/get.dart';

  import '../../models/messages.dart';
  import 'chat/view/widgets/variables/globalVariables.dart';

  class ChattingPageLogic extends GetxController {
    var messages = <Messages>[].obs;
    final FirebaseFirestore myFbFs = FirebaseFirestore.instance;
    final FirebaseAuth myFbAuth = FirebaseAuth.instance;

    // ✅ Send Message to chatoom → chatRoomId → Messages
    Future<void> sendMessage(String chatRoomId, String receiverId, String messageText) async {
      try {
        String senderId = myFbAuth.currentUser!.uid;

        // Get user data from Firestore
        DocumentSnapshot userDoc = await myFbFs.collection('Users').doc(senderId).get();
        String name = (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown User';

        // Reference to the chat room document
        DocumentReference chatRoomRef = myFbFs.collection('ChatsRoomId').doc(chatRoomId);
        DocumentSnapshot chatRoomDoc = await chatRoomRef.get();

        // ✅ Create chat room if it doesn't exist
        if (!chatRoomDoc.exists) {
          await chatRoomRef.set({
            'id': senderId,
            'chatRoomId': chatRoomId,
            'participants': [senderId, receiverId],
            'createdAt': FieldValue.serverTimestamp(),
            'name': name, // Add sender's name
          });
        }

        // ✅ Add message to the chat room
        await myFbFs
            .collection('ChatsRoomId')
            .doc(chatRoomId)
            .collection('Messages')
            .add({
          'senderId': senderId,
          'senderName': name, // ✅ Save name inside message
          'messageText': messageText,
          'receiverId': receiverId,
          'timestamp': FieldValue.serverTimestamp(),
        });

      } catch (e) {
        print("Error sending message: $e");
        Get.snackbar('Error', 'Failed to send message: $e');
      }
    }

    // ✅ Get Messages from chatoom → chatRoomId → Messages
    Stream<List<Messages>> getMessages(String chatRoomId) {
      return myFbFs
          .collection('ChatsRoomId') // CHANGED COLLECTION NAME
          .doc(chatRoomId)
          .collection('Messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => Messages.fromJson(doc.data(), doc.id))
          .toList());
    }

    void updateMessages(List<Messages> newMessages) {
      messages.value = newMessages;
    }

    // setUserOffline, didChangeAppLifecycleState, setTypingStatus, setUserOnline functions - NO CHANGES NEEDED HERE (unless you want to also change collection name here)
    Future<void> setUserOffline() async {
      final user = myFbAuth.currentUser;
      if (user != null) {
        await myFbFs.collection('ChatsRoomId').doc(globalChatRoomId).collection("usersStatus").doc(user.uid).set({   // CHANGED COLLECTION NAME
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    void didChangeAppLifecycleState(AppLifecycleState state) {
      if (state == AppLifecycleState.resumed) {
        setUserOnline(globalChatRoomId!);
      } else if (state == AppLifecycleState.inactive ||
          state == AppLifecycleState.paused ||
          state == AppLifecycleState.detached) {
        setUserOffline();
      }
    }
    void setTypingStatus(bool isTyping) async {
      final user = myFbAuth.currentUser;
      if (user != null) {
        print("setTypingStatus called with isTyping: $isTyping"); //ADDED
        await myFbFs.collection('ChatsRoomId').doc(globalChatRoomId).collection("usersStatus").doc(user.uid).set({ // CHANGED COLLECTION NAME
          'isTyping': isTyping,
        }, SetOptions(merge: true));
      }
    }

    Future<void> setUserOnline(String globalChatRoomId) async {
      final user = myFbAuth.currentUser;
      if (user != null) {
        try {
          await myFbFs.collection('ChatsRoomId').doc(globalChatRoomId).collection("usersStatus").doc(user.uid).set({  // CHANGED COLLECTION NAME
            'isOnline': true,
            'lastSeen': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print("User ${user.uid} set to online in chatroom $globalChatRoomId");
        } catch (e) {
          print("Error setting user online: $e");
        }
      } else {
        print("No user logged in, cannot set online status.");
      }
    }
  }