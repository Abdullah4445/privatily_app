import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:privatily_app/widgets/translationsController.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:seo/seo.dart'; // SEO package
import '../animations/animated_on_scrool.dart';
import '../modules/cart/cart_logic.dart';
import '../modules/cart/cart_view.dart';
import '../modules/chat_page/chat/view/chatting_page.dart';
import '../modules/chat_page/view.dart';
import '../modules/preview/privatily_preview_image.dart';
import '../modules/sections/FAQ_section.dart';
import '../modules/sections/FooterSection.dart';
import '../modules/sections/contact_us_seaction.dart';
import '../modules/sections/featuredProducts/featuredProducts.dart';
import '../modules/sections/home_stats_section.dart';
import '../modules/sections/how_much_time_section.dart';
import '../modules/sections/launch_any_whered_ection.dart';
import '../modules/sections/our_mission_section.dart';
import '../modules/sections/premium_bonuses_section.dart';
import '../modules/sections/testimonial_section.dart';
import '../modules/sections/transparent_pricing_seaction.dart';
import '../modules/sections/why_incorporate_us_section.dart';
import '../modules/sections/why_privatily_section.dart';
import 'homellogic.dart';
import 'myProgressIndicator.dart';

/// Home page with SEO enhancements
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final ScrollController _scrollController = ScrollController();
  final HomeLogic logic = Get.put(HomeLogic());
  final GlobalKey _faqKey = GlobalKey();
  final GlobalKey _testimonialKey = GlobalKey();
  final GlobalKey _featuredKey = GlobalKey();
  final GlobalKey _whyUsKey = GlobalKey();
  final GlobalKey _contactUsKey = GlobalKey();

  bool showChatBox = false;
  bool showLoginForm = false;
  bool showSignupForm = false;

  //New Variables
  bool showRoleSelection = false;
  RxBool showStudentCourses = false.obs;
  bool isStudent = false; // Track if the user is a student or a client
  RxBool isLoggedIn = false.obs;
  String? selectedCourse;
  RxString selectedLang = 'en'.obs;

  //Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Check initial login state
    isLoggedIn.value = FirebaseAuth.instance.currentUser != null;
    // Listen for authentication changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      isLoggedIn.value = user != null;
    });
  }

  void scrollToSection(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final offset = box.localToGlobal(Offset.zero).dy - kToolbarHeight;
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget fiveStars(double screenWidth) {
    final iconSize = screenWidth < 600 ? 18 : screenWidth < 1024 ? 22 : 26;
    return GestureDetector(
        onTap: () => scrollToSection(_testimonialKey),
        child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(children: List.generate(5, (_) => Icon(Icons.star, color: Colors.orange, size: double.parse(iconSize.toString())))),
                const SizedBox(width: 12),
                Text('rated_stars'.tr, style: TextStyle(fontSize: iconSize * 0.6, fontWeight: FontWeight.bold)),
              ],
            ),
           ),
       );}

  Widget chatPopup() {
    return Positioned(
      bottom: 100,
      right: 24,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
                  .animate(anim),
              child: child,
            ),
          ),
        ),
        child: showChatBox
            ? Material(
          key: const ValueKey('chatbox'),
          borderRadius: BorderRadius.circular(20),
          elevation: 8,
          color: Colors.transparent,
          child: Container(
            width: 360,
            height: 480,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 25)],
              image: DecorationImage(
                image: NetworkImage(
                    'https://i.gifer.com/origin/0f/0f412581c9c78dec416072c7a42ef1b4.gif'), // Animated image URL
                fit: BoxFit.cover,
              ),
            ),
            child: ClipRRect( // To clip the content inside the container
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Adjust blur intensity
                child: Container(
                  color: Colors.white.withOpacity(0.7), // Adjust opacity for content visibility
                  padding: const EdgeInsets.all(16),
                  child: Obx(() {
                    if (logic.isLoading.value) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (logic.showChatScreen.value) {
                      return ChattingPage(
                        chatRoomId: logic.chatRoomIdForPopup.value,
                        receiverId: logic.receiverIdForPopup.value,
                        receiverName: logic.receiverNameForPopup.value,
                      );
                    } else if (showRoleSelection) {
                      // Show role selection screen
                      return _buildRoleSelection();
                    } else if (showLoginForm) {
                      return _buildLoginForm();
                    } else if (showSignupForm) {
                      return _buildSignupForm();
                    } else {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                showLoginForm = true;
                                showSignupForm = false;
                              });
                            },
                            child: Text('Login'),
                          ),
                          SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                showSignupForm = true;
                                showLoginForm = false;
                              });
                            },
                            child: Text('Create an account'),
                          ),
                        ],
                      );
                    }
                  }),
                ),
              ),
            ),
          ),
        )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget floatingMessageButton() => FloatingActionButton(
    backgroundColor: Colors.deepPurple,
    onPressed: () async {
      _openChatPopup();
    },
    child: Icon(showChatBox ? Icons.close : Icons.chat_bubble_outline,
        color: Colors.white),
  );

  void _openChatPopup() {
    setState(() {
      showChatBox = !showChatBox;
      showLoginForm = false;
      showSignupForm = false;
      showRoleSelection = false;
    });
    // Check if the user is already logged in
    if (FirebaseAuth.instance.currentUser != null) {
      // User is already logged in, generate chatRoomId and show chat screen
      String chatRoomId = logic.generateChatRoomId(
          FirebaseAuth.instance.currentUser!.uid, logic.fixedAdminId);
      logic.chatRoomIdForPopup.value = chatRoomId;
      logic.receiverIdForPopup.value = logic.fixedAdminId;
      logic.receiverNameForPopup.value = logic.adminName;
      logic.showChatScreen.value = true;
    } else {
      // Show login/signup options
      setState(() {
        showRoleSelection =
            showChatBox; // Show role selection on opening chatbox
      });
    }
  }

  Widget _buildRoleSelection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                isStudent = true;
                showRoleSelection = false;
                showSignupForm = true;
              });
            },
            child: Text('Login as Student'),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isStudent = false;
                showRoleSelection = false;
                showLoginForm = true; // Show login form after role selection
              });
            },
            child: Text('Login as Client'),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    List<String> courses = [
      'Software Engineers',
      'Digital Marketing',
      'Spoken English '
    ];
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Create Account',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple, // Primary Color
            ),
          ),
          const Gap(15),
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'Enter your name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
          const Gap(12),
          TextFormField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
          const Gap(12),
          TextFormField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
            obscureText: true,
          ),
          const Gap(12),
          if (isStudent)
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Course',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              value: selectedCourse,
              items: courses.map((String course) {
                return DropdownMenuItem<String>(
                  value: course,
                  child: Text(course),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  selectedCourse = value;
                });
              },
              validator: (value) =>
              isStudent && value == null ? 'Please select a course' : null,
            ),
          const Gap(12),
          ElevatedButton(
            onPressed: () async {
              if (isStudent && selectedCourse == null) {
                Get.snackbar('Error', 'Please select a course');
                return;
              }

              try {
                await logic.createUserWithEmailAndPassword(
                  emailController.text,
                  passwordController.text,
                  nameController.text,
                  selectedCourse ?? '', // Pass empty string if no course selected
                  isStudent: isStudent,
                );

                if (logic.auth.currentUser != null) {
                  setState(() {
                    showSignupForm = false;
                  });
                }
              } catch (e) {
                Get.snackbar('Error', 'Signup failed: ${e.toString()}');
                // Log the error for debugging
                print("Signup Error: $e");
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple, // Primary Color
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
              textStyle: const TextStyle(fontSize: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Create Account',
                style: TextStyle(color: Colors.white)),
          ),
          const Gap(4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: TextButton(
              key: ValueKey<bool>(showLoginForm),
              onPressed: () {
                setState(() {
                  showSignupForm = false;
                  showLoginForm = true;
                });
              },
              child: const Text('Already have an account? Login',
                  style: TextStyle(color: Colors.deepPurple)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Login',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple, // Primary Color
            ),
          ),
          const Gap(24),
          TextFormField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
          const Gap(16),
          TextFormField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
            obscureText: true,
          ),
          const Gap(32),
          ElevatedButton(
            onPressed: () async {
              // Your login logic here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple, // Primary Color
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
              textStyle: const TextStyle(fontSize: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Login', style: TextStyle(color: Colors.white)),
          ),
          const Gap(16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: TextButton(
              key: ValueKey<bool>(showSignupForm),
              onPressed: () {
                setState(() {
                  showLoginForm = false;
                  showSignupForm = true;
                });
              },
              child: const Text('Create an account',
                  style: TextStyle(color: Colors.deepPurple)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Seo.head(
      tags: [
        MetaTag(
            name: 'description',
            content:
            'LaunchCode: launch sooner and grow faster with our software marketplace.'),
        LinkTag(rel: 'canonical', href: 'https://launchcode.shop/'),
      ],
      child: Builder(
        builder: (ctx) {
          final screenWidth = MediaQuery.of(context).size.width;
          return Stack(
            children: [
              Scaffold(
                appBar: AppBar(
                  title: Image.asset('assets/images/logo_white.png',
                      height: 120),
                  backgroundColor: Colors.white,
                  actions: [
                    if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
                      TextButton(
                          onPressed: () => scrollToSection(_whyUsKey),
                          child: Text('Why Us?'.tr)),
                    TextButton(
                        onPressed: () => scrollToSection(_contactUsKey),
                        child: Text('Contact Us!'.tr)),
                    if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
                      TextButton(
                          onPressed: () => scrollToSection(_faqKey),
                          child: Text('FAQ'.tr)),
                    FirebaseAuth.instance.currentUser == null
                        ? TextButton(
                        onPressed: _openChatPopup, child: Text('Login'.tr))
                        : TextButton(
                        onPressed: logic.logOut, child: Text('Logout'.tr)),
                    const Gap(10),
                    Obx(() {
                      final count = Get.find<CartLogic>().itemCount;
                      return Badge(
                        label: Text(count.toString()),
                        isLabelVisible: count > 0,
                        child: IconButton(
                          icon: const Icon(Icons.shopping_cart),
                          onPressed: () => Get.toNamed(CartPage.routeName),
                        ),
                      );
                    }),
                    // Language selector
                    Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 8),
                      child: Obx(() => DropdownButton<String>(
                        value: selectedLang.value,
                        underline: const SizedBox.shrink(),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                              value: 'en', child: Text('English')),
                          DropdownMenuItem(
                              value: 'fr', child: Text('Français')),
                          DropdownMenuItem(
                              value: 'es', child: Text('Español')),
                          DropdownMenuItem(
                              value: 'ar', child: Text('عربي')),
                        ],
                        onChanged: (val) {
                          selectedLang.value = val!;
                          Get.put(TranslationController()).changeLanguage(val);
                        },
                      )),
                    ),
                  ],
                ),
                body: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Hero with SEO text
                      AnimatedOnScroll(
                        child: Seo.text(
                          text: 'launch_sooner'.tr + ' ' + 'grow_faster'.tr,
                          style: TextTagStyle.h1,
                          child: _buildLaunchCodeHero(ctx),
                        ),
                      ),
                      const Gap(20),
                      AnimatedOnScroll(
                        child: Seo.text(
                          text: 'ready_to_launch'.tr,
                          style: TextTagStyle.h2,
                          child: Text('ready_to_launch'.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: screenWidth < 600
                                      ? 24
                                      : screenWidth < 1024
                                      ? 36
                                      : 46,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const Gap(10),
                      AnimatedOnScroll(
                        child: Seo.text(
                          text: 'leverageOur'.tr,
                          style: TextTagStyle.p,
                          child: Text('leverageOur'.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: screenWidth < 600 ? 14 : 16,
                                  color: Colors.black87)),
                        ),
                      ),
                      const Gap(30),
                      AnimatedOnScroll(
                        child: Seo.image(
                          src: 'assets/images/preview.png',
                          alt: 'LaunchCode app preview',
                          child: const PrivatilyPreviewImage(),
                        ),
                      ),
                      // Sections
                      Padding(
                        key: _featuredKey,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const FeaturedProductsSection(),
                      ),
                      const AnimatedOnScroll(child: HomeStatsSection()),
                      AnimatedOnScroll(
                          child: WhyLaunchCodeSection(key: _whyUsKey)),
                      const AnimatedOnScroll(child: PremiumBonusSection()),
                      const AnimatedOnScroll(child: HowMuchTimeSection()),
                      const AnimatedOnScroll(child: WhyLaunchCodeSection2()),
                      const AnimatedOnScroll(child: TransparentPricingSection()),
                      AnimatedOnScroll(
                          child: TestimonialSection(key: _testimonialKey)),
                      const AnimatedOnScroll(child: OurMissionSection()),
                      AnimatedOnScroll(child: FaqSection(key: _faqKey)),
                      const AnimatedOnScroll(child: LaunchAnywhereSection()),
                      AnimatedOnScroll(
                          child: ContactUsSection(key: _contactUsKey)),
                      const AnimatedOnScroll(child: FooterSection()),
                    ],
                  ),
                ),
                floatingActionButton: floatingMessageButton(),
              ),
              chatPopup(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLaunchCodeHero(BuildContext ctx) {
    final width = MediaQuery.of(ctx).size.width;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8F9FF), Color(0xFFEDEFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              const Icon(Icons.rocket_launch,
                  color: Colors.deepPurple, size: 28),
              Text('launch_sooner'.tr,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              const Icon(Icons.trending_up, color: Colors.green, size: 28),
              Text('grow_faster'.tr,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
          const Gap(6),
          Text('discover_software'.tr,
              textAlign: TextAlign.center,
              style:
              TextStyle(fontSize: width < 600 ? 16 : 18, color: Colors.black54)),
          const Gap(16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => scrollToSection(_featuredKey),
                icon: const Icon(Icons.explore),
                label: Text('explore_products'.tr),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12)),
              ),
              OutlinedButton.icon(
                onPressed: () => scrollToSection(_featuredKey),
                icon: const Icon(Icons.code),
                label: Text('browse_categories'.tr),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}