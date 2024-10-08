import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doom_chain/Auth.dart';
import 'package:doom_chain/CreateChainCategory.dart';
import 'package:doom_chain/CreateChainDetails.dart';
import 'package:doom_chain/CreateChainPage.dart';
import 'package:doom_chain/CreateChainTagsPage.dart';
import 'package:doom_chain/GlobalValues.dart';
import 'package:doom_chain/ProfileEditDetails.dart';
import 'package:doom_chain/ProfileSettings.dart';
import 'package:doom_chain/ProfileViewChains.dart';
import 'package:doom_chain/UnchainedPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ExplorePage.dart';
import 'ProfilePage.dart';
import 'FriendsPage.dart';
import 'FriendsPageStrangers.dart';
import 'package:workmanager/workmanager.dart';

class AbstractMenu extends StatefulWidget{

  final String uid;

  AbstractMenu({required this.uid});

  @override
  _AbstractMenu createState() => _AbstractMenu();

  static String generateRandomId(int length){
    String val = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    Random random = Random.secure();

    return List.generate(length, (index) => val[random.nextInt(val.length)]).join('');
  }
}

class _AbstractMenu extends State<AbstractMenu> with TickerProviderStateMixin{

  late final DocumentSnapshot userDetails;

  late AnimationController _animationOpacity;
  late AnimationController _animationOpacityIconExplore;
  late AnimationController _animationOpacityIconUnchained;
  late AnimationController _animationOpacityIconFriends;
  late AnimationController _animationOpacityIconProfile;

  late Widget currentPage;
  late Widget lastCurrentPage;

  String topImageAsset = 'assets/image/explore.png';
  String currentPageDisplayedTitle = 'Explore';
  String lastCurrentPageDisplayedTitle = 'Explore';
  String lastAssetsPath = 'assets/image/explore.png';
  String assetPath = 'assets/image/explore.png';
  List<bool> lastPageBools = List.filled(5, false);
  Color topTitleColor = globalPurple;

  bool friendsPage = false;
  bool lastFriendsButtonMode = false;
  bool profilePage = false;
  bool unchainedPage = false;
  bool explorePage = true;
  bool unchainedPageRefresh = false;

  bool displayProgressBool = false;

  @override
  void initState(){
    super.initState();

    _setUserIdentifier();
    
    currentPage = ExplorePage(exploreData: {
      'userId' : widget.uid
      }, changePageHeader: changePageHeader, 
      displayProgress: displayProgress,
      key: UniqueKey());

    lastCurrentPage = currentPage;

    _animationOpacity = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250)  
    );

    _animationOpacityIconExplore = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250)  
    );

    _animationOpacityIconUnchained = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250)  
    );

    _animationOpacityIconFriends = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250)  
    );

    _animationOpacityIconProfile = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250)  
    );

    _animationOpacity.forward();
    _animationOpacityIconExplore.forward();
    _animationOpacityIconUnchained.forward();
    _animationOpacityIconFriends.forward();
    _animationOpacityIconProfile.forward();
  }

  @override
  Widget build(BuildContext context){

    final double width = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        backgroundColor: globalBackground,
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: width * 0.05, right: width * 0.025, top: width * 0.025, bottom: width * 0.025),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationOpacity, curve: Curves.easeOut)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(width * 0.02),
                      child: Image.asset(topImageAsset, fit: BoxFit.fill, width: width * 0.1, height: width * 0.1, color: globalTextBackground),
                    ),

                    Padding(
                      padding: EdgeInsets.all(width * 0.02),
                      child: Text(currentPageDisplayedTitle, style: GoogleFonts.nunito(fontSize: width * 0.05, color: topTitleColor, fontWeight: FontWeight.bold))
                    ),

                    Visibility(
                      visible: friendsPage,
                      child: const Spacer(),
                    ),

                    Visibility(
                      visible: friendsPage,
                      child: Padding(
                        padding: EdgeInsets.all(width * 0.02),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              lastFriendsButtonMode = false;
                            });
                            
                            changePageHeader('Friends', {
                              'userId' : widget.uid
                            });
                          }, 
                          icon: Image.asset('assets/image/list.png', width: width * 0.1, height: width * 0.1, color: globalPurple)
                        )
                      )
                    ),

                    Visibility(
                      visible: friendsPage,
                      child: Padding(
                        padding: EdgeInsets.all(width * 0.02),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              lastFriendsButtonMode = true;
                            });
                            changePageHeader('Strangers', {
                              'userId' : widget.uid
                            });
                          }, 
                          icon: Image.asset('assets/image/addfriends.png', width: width * 0.1, height: width * 0.1, color: globalPurple)
                        )
                      )
                    ),

                    Visibility(
                      visible: profilePage,
                      child: const Spacer()
                    ),

                    Visibility(
                      visible: profilePage,
                      child: Builder(
                        builder: (context) {
                          return Padding(
                            padding: EdgeInsets.all(width * 0.02),
                            child: IconButton(
                              onPressed: () {
                                Scaffold.of(context).openEndDrawer();
                              }, 
                              icon: Image.asset('assets/image/slidemenu.png', width: width * 0.1, height: width * 0.1, color: globalPurple)
                            )
                          );
                        }
                      )
                    ),

                    Visibility(
                      visible: displayProgressBool,
                      child: const CircularProgressIndicator(),
                    ),

                    Visibility(
                      visible: unchainedPageRefresh,
                      child: const Spacer()
                    ),

                    Visibility(
                      visible: unchainedPageRefresh,
                      child: Padding(
                        padding: EdgeInsets.all(width * 0.02),
                        child: IconButton(
                          onPressed: () {
                            changePageHeader('Unchained (refresh)', null);
                          }, 
                          icon: Image.asset('assets/image/refresh.png', width: width * 0.05, height: width * 0.05, color: globalPurple)
                        )
                      )
                    ),

                    Visibility(
                      visible: explorePage,
                      child: const Spacer()
                    ),

                    Visibility(
                      visible: explorePage,
                      child: Padding(
                        padding: EdgeInsets.all(width * 0.02),
                        child: IconButton(
                          onPressed: () {
                            changePageHeader('Explore (refresh)', null);
                          }, 
                          icon: Image.asset('assets/image/refresh.png', width: width * 0.05, height: width * 0.05, color: globalPurple)
                        )
                      )
                    ),
                  ],
                )
              )
            ),

            Expanded(
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationOpacity, curve: Curves.easeOut)),
                      child: Column(
                        children: [
                          Expanded(
                            child: currentPage
                          ),
                        ],
                      ),
                    )
                  ),

                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [globalBackground.withOpacity(0.1), globalBackground.withOpacity(0.9), globalBackground, globalBackground]
                        )
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(top: width * 0.05, bottom: width * 0.05),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FadeTransition(
                              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationOpacityIconExplore, curve: Curves.easeOut)),
                              child: Padding(
                                padding: EdgeInsets.only(left: width * 0.025, right: width * 0.025),
                                child: IconButton(
                                  onPressed: () {
                                    changePageHeader('Explore', null);
                                    animateOpacity(_animationOpacityIconExplore);
                                  }, 
                                  icon: Image.asset('assets/image/explore.png', fit: BoxFit.fill, width: width * 0.12, height: width * 0.12, color: globalTextBackground)
                                ),
                              )
                            ),

                            FadeTransition(
                              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationOpacityIconUnchained, curve: Curves.easeOut)),
                              child: Padding(
                                padding: EdgeInsets.only(left: width * 0.025, right: width * 0.025),
                                child: IconButton(
                                  onPressed: () {
                                    changePageHeader('Unchained', null);
                                    animateOpacity(_animationOpacityIconUnchained);
                                  }, 
                                  icon: Image.asset('assets/image/newchain.png', fit: BoxFit.fill, width: width * 0.12, height: width * 0.12, color: globalTextBackground)
                                ),
                              )
                            ),

                            FadeTransition(
                              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationOpacityIconFriends, curve: Curves.easeOut)),
                              child: Padding(
                                padding: EdgeInsets.only(left: width * 0.025, right: width * 0.025),
                                child: IconButton(
                                  onPressed: () {
                                    changePageHeader('Friends', {
                                      'userId' : widget.uid
                                    });
                                    animateOpacity(_animationOpacityIconFriends);
                                  }, 
                                  icon: Image.asset('assets/image/friends.png', fit: BoxFit.fill, width: width * 0.12, height: width * 0.12, color: globalTextBackground)
                                ),
                              )
                            ),

                            FadeTransition(
                              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationOpacityIconProfile, curve: Curves.easeOut)),
                              child: Padding(
                                padding: EdgeInsets.only(left: width * 0.025, right: width * 0.025),
                                child: IconButton(
                                  onPressed: () {
                                    changePageHeader('Profile', {
                                      'userId' : widget.uid
                                    });
                                    animateOpacity(_animationOpacityIconProfile);
                                  }, 
                                  icon: Image.asset('assets/image/profile.png', fit: BoxFit.fill, width: width * 0.12, height: width * 0.12, color: globalTextBackground)
                                ),
                              )
                            )
                          ],
                        ),
                      )
                    )
                  ),
                ],
              )
            )
          ],
        ),

        endDrawer: Builder(
          builder: (context) {
            return Drawer(
              backgroundColor: globalDrawerBackground.withOpacity(0.85),
              child: ListView(
                children: [

                  Padding(
                    padding: EdgeInsets.only(left: width * 0.05, right: width * 0.05, top: width * 0.1, bottom: width * 0.025),
                    child: ListTile(
                      leading: Image.asset('assets/image/star.png', width: width * 0.075, height: width * 0.075, color: globalPurple),
                      trailing: const Icon(Icons.arrow_right),
                      splashColor: globalPurple.withOpacity(0.1),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15))
                      ),
                      title: Text('Liked Chains', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      onTap: () {
                        changePageHeader('Profile (liked chains)', {
                          'userId' : widget.uid
                        });

                        Scaffold.of(context).closeEndDrawer();
                      },
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(left: width * 0.05, right: width * 0.05, top: width * 0.025, bottom: width * 0.025),
                    child: ListTile(
                      leading: Image.asset('assets/image/save.png', width: width * 0.075, height: width * 0.075, color: globalPurple),
                      trailing: const Icon(Icons.arrow_right),
                      splashColor: globalPurple.withOpacity(0.1),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15))
                      ),
                      title: Text('Saved Chains', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      onTap: () {
                        changePageHeader('Profile (saved chains)', {
                          'userId' : widget.uid
                        });

                        Scaffold.of(context).closeEndDrawer();
                      },
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(left: width * 0.05, right: width * 0.05, top: width * 0.025, bottom: width * 0.025),
                    child: ListTile(
                      leading: Image.asset('assets/image/profile.png', width: width * 0.075, height: width * 0.075, color: globalPurple),
                      trailing: const Icon(Icons.arrow_right),
                      splashColor: globalPurple.withOpacity(0.1),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15))
                      ),
                      title: Text('Friend requests', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      onTap: () {
                        changePageHeader('Friend requests', null);
                        Scaffold.of(context).closeEndDrawer();
                      },
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(left: width * 0.05, right: width * 0.05, top: width * 0.025, bottom: width * 0.025),
                    child: ListTile(
                      leading: Image.asset('assets/image/info.png', width: width * 0.075, height: width * 0.075, color: globalPurple),
                      trailing: const Icon(Icons.arrow_right),
                      splashColor: globalPurple.withOpacity(0.1),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15))
                      ),
                      title: Text('Edit profile', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      onTap: () {
                        changePageHeader('Profile (edit profile)', null);
                        Scaffold.of(context).closeEndDrawer();
                      },
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(left: width * 0.05, right: width * 0.05, top: width * 0.025, bottom: width * 0.025),
                    child: ListTile(
                      leading: Image.asset('assets/image/key.png', width: width * 0.075, height: width * 0.075, color: globalPurple),
                      trailing: const Icon(Icons.arrow_right),
                      splashColor: globalPurple.withOpacity(0.1),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15))
                      ),
                      title: Text('Settings', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      onTap: () {
                        changePageHeader('Settings', null);
                        Scaffold.of(context).closeEndDrawer();
                      },
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(left: width * 0.05, right: width * 0.05, top: width * 0.025, bottom: width * 0.025),
                    child: ListTile(
                      leading: Image.asset('assets/image/signout.png', width: width * 0.075, height: width * 0.075, color: globalPurple),
                      trailing: const Icon(Icons.arrow_right),
                      splashColor: globalPurple.withOpacity(0.1),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15))
                      ),
                      title: Text('Sign Out', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      onTap: () {
                        
                        showDialog(
                          context: context, 
                          builder: (context){
                            return AlertDialog(
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset('assets/image/info.png', width: width * 0.1, height: width * 0.1),
                                  Text('Sign Out', style: GoogleFonts.nunito(fontSize: width * 0.06, color: Colors.black87, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              actionsAlignment: MainAxisAlignment.center,
                              content: Text('Are you sure you want to sign out?', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                              actions: [
                                Padding(
                                  padding: EdgeInsets.all(width * 0.01),
                                  child: Material(
                                    color: globalPurple,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(15))
                                    ),
                                    child: InkWell(
                                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                                      onTap: () async {
                                        await FirebaseAuth.instance.currentUser!.reload();
                                        await FirebaseAuth.instance.signOut();
                                        await GoogleSignIn().signOut();
                                        Workmanager().cancelByUniqueName('1');
                                        OneSignal.User.pushSubscription.optOut();

                                        if(mounted){
                                          Navigator.of(context).popUntil((route) => route.isFirst);
                                        }

                                        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => Auth(width: width)));
                                      }, 
                                      splashColor: globalBlue,
                                      child: Padding(
                                        padding: EdgeInsets.all(width * 0.025),
                                        child: Text('Yeah', style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.white, fontWeight: FontWeight.bold))
                                      )
                                    )
                                  )
                                ),

                                Padding(
                                  padding: EdgeInsets.all(width * 0.01),
                                  child: Material(
                                    color: globalPurple,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(15))
                                    ),
                                    child: InkWell(
                                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                                      onTap: () async {
                                        if(mounted){
                                          Navigator.of(context).popUntil((route) => route.isFirst);
                                        }
                                      }, 
                                      splashColor: globalBlue,
                                      child: Padding(
                                        padding: EdgeInsets.all(width * 0.025),
                                        child: Text('Close', style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.white, fontWeight: FontWeight.bold))
                                      )
                                    )
                                  )
                                )
                              ]
                            );
                          }
                        );

                        Scaffold.of(context).closeEndDrawer();
                      },
                    ),
                  ),

                  Text('©Copyright omuletzu\nRandomChain', style: GoogleFonts.nunito(fontSize: width * 0.025, color: Colors.grey[800], fontWeight: FontWeight.bold), textAlign: TextAlign.center)
                ]
              )
            );
          }
        )
      ),
    );
  }

  void changePageHeader(String title, Map<String, dynamic>? addData) {

    _animationOpacity.reset();
    _animationOpacity.forward();
    
    String tempCurrentTitle = lastCurrentPageDisplayedTitle;
    Widget page;

    if(title != 'Go Back'){
      lastAssetsPath = assetPath;
      lastPageBools[0] = friendsPage;
      lastPageBools[1] = profilePage;
      lastPageBools[2] = unchainedPage;
      lastPageBools[3] = explorePage;
      lastPageBools[4] = unchainedPageRefresh;
    }

    switch(title){
      case 'Explore' :
        assetPath = 'assets/image/explore.png';
        page = ExplorePage(
          exploreData: {'userId' : widget.uid}, 
          changePageHeader: changePageHeader, 
          displayProgress: displayProgress,
          key: null
        );
        setState(() {
          tempCurrentTitle = 'Explore';
          topTitleColor = globalPurple;
          friendsPage = false;
          profilePage = false;
          unchainedPage = false;
          unchainedPageRefresh = false;
          explorePage = true;
        });
        break;

      case 'Explore (refresh)' :
        assetPath = 'assets/image/explore.png';
        page = ExplorePage(
          exploreData: {'userId' : widget.uid}, 
          changePageHeader: changePageHeader, 
          displayProgress: displayProgress,
          key: UniqueKey()
        );
        setState(() {
          tempCurrentTitle = 'Explore';
          topTitleColor = globalPurple;
          friendsPage = false;
          profilePage = false;
          unchainedPage = false;
          unchainedPageRefresh = false;
        });
        break;

      case 'Unchained' :
        assetPath = 'assets/image/newchain.png';
        page = UnchainedPage(changePageHeader: changePageHeader, userId: widget.uid, key: null, displayProgress: displayProgress);
        setState(() {
          tempCurrentTitle = 'Unchained';
          topTitleColor = globalPurple;
          friendsPage = false;
          profilePage = false;
          unchainedPage = true;
          unchainedPageRefresh = true;
          explorePage = false;
        });
        break;

      case 'Unchained (refresh)' :
        assetPath = 'assets/image/newchain.png';
        page = UnchainedPage(changePageHeader: changePageHeader, userId: widget.uid, key: UniqueKey(), displayProgress: displayProgress);
        setState(() {
          tempCurrentTitle = 'Unchained';
          topTitleColor = globalPurple;
          friendsPage = false;
          profilePage = false;
          unchainedPage = true;
          unchainedPageRefresh = true;
          explorePage = false;
        });
        break;

      case 'Friends' :
        assetPath = 'assets/image/friends.png';
        setState(() {
          tempCurrentTitle = 'Friends';
          topTitleColor = globalPurple;
          friendsPage = true;
          profilePage = false;
          unchainedPage = false;
          unchainedPageRefresh = false;
          explorePage = false;
        });

        page = FriendsPage(
          userId: addData!['userId'],
          changePageHeader: changePageHeader,
          isThisRequests: false,
          key: UniqueKey()
        );

        break;

      case 'Strangers' :
        assetPath = 'assets/image/friends.png';
        setState(() {
          tempCurrentTitle = 'New people';
          topTitleColor = globalPurple;
          friendsPage = true;
          profilePage = false;
          unchainedPage = false;
          unchainedPageRefresh = false;
          explorePage = false;
        });

        page = FriendsPageStrangers(
          userId: addData!['userId'],
          changePageHeader: changePageHeader,
        );

        break;

      case 'Friend requests' :
        assetPath = 'assets/image/friends.png';
        setState(() {
          tempCurrentTitle = 'Friend requests';
          topTitleColor = globalPurple;
          friendsPage = true;
          profilePage = false;
          unchainedPage = false;
          unchainedPageRefresh = false;
          explorePage = false;
        });

        page = FriendsPage(
          userId: widget.uid,
          changePageHeader: changePageHeader,
          isThisRequests: true,
          key: UniqueKey()
        );
        
        break;

      case 'Profile' :
        assetPath = 'assets/image/profile.png';
        setState(() {
          tempCurrentTitle = 'Profile';
          topTitleColor = globalPurple;
          friendsPage = false;
          profilePage = true;
          unchainedPage = false;
          unchainedPageRefresh = false;
          explorePage = false;
        });

        page = ProfilePage(
          changePageHeader: changePageHeader,
          userIdToDisplay: addData!['userId'],
          originalUserId: widget.uid,
          isThisUser: true,
          key: UniqueKey());

        break;

      case 'Profile (friend)' :
        assetPath = 'assets/image/profile.png';
        setState(() {
          tempCurrentTitle = 'Profile';
          topTitleColor = globalPurple;
          friendsPage = false;
          profilePage = false;
          unchainedPage = false;
          unchainedPageRefresh = false;
        });

        page = ProfilePage(
          changePageHeader: changePageHeader,
          userIdToDisplay: addData!['userId'],
          originalUserId: widget.uid,
          isThisUser: false,
          key: null);

        break;

      case 'Profile (chains)' :
        assetPath = 'assets/image/profile.png';
        setState(() {
          tempCurrentTitle = 'Profile (${addData!['nickname']})';
          topTitleColor = globalPurple;
          friendsPage = false;
          unchainedPage = false;
          unchainedPageRefresh = false;
        });

        page = ProfileViewChains(
          changePageHeader: changePageHeader, 
          userData: addData!,
          personalLikedSavedChains: 0);
        break;

      case 'Profile (liked chains)' :
        assetPath = 'assets/image/star.png';
        setState(() {
          tempCurrentTitle = 'Profile (liked)';
          topTitleColor = globalPurple;
          friendsPage = false;
          unchainedPage = false;
          unchainedPageRefresh = false;
        });

        page = ProfileViewChains(
          changePageHeader: changePageHeader, 
          userData: addData!,
          personalLikedSavedChains: 1);
        break;

      case 'Profile (saved chains)' :
        assetPath = 'assets/image/save.png';
        setState(() {
          tempCurrentTitle = 'Profile (saved)';
          topTitleColor = globalPurple;
          friendsPage = false;
          unchainedPage = false;
          unchainedPageRefresh = false;
        });

        page = ProfileViewChains(
          changePageHeader: changePageHeader, 
          userData: addData!,
          personalLikedSavedChains: 2);
        break;

      case 'Profile (edit profile)' :
        assetPath = 'assets/image/info.png';
        setState(() {
          tempCurrentTitle = 'Edit profile';
          topTitleColor = globalPurple;
          friendsPage = false;
          unchainedPage = false;
          unchainedPageRefresh = false;
        });

        page = ProfileEditDetails(
          changePageHeader: changePageHeader, 
          userId: widget.uid
        );

      case 'Settings' :
        assetPath = 'assets/image/key.png';
        tempCurrentTitle = 'Settings';
        setState(() {
          topTitleColor = globalPurple;
          friendsPage = false;
          unchainedPage = false;
          unchainedPageRefresh = false;
        });

        page = ProfileSettings(
          changePageHeader: changePageHeader, 
          userId: widget.uid,
          updateUIFromSetting: updateUIFromSetting,
        );
        break;

      case 'New chain (story)' :
        assetPath = 'assets/image/book.png';
        addData!['categoryType'] = 0;
        page = CreateChain(changePageHeader: changePageHeader, addData: addData);

        setState(() {
          topTitleColor = globalPurple;
        });

      case 'New chain (category)' :
        assetPath = 'assets/image/create.png';
        page = CreateChainCategory(changePageHeader: changePageHeader, userId: widget.uid);

        setState(() {
          topTitleColor = globalPurple;
          unchainedPageRefresh = false;
        });

      case 'New chain (details)' :
        assetPath = 'assets/image/book.png';
        page = CreateChainTagsPage(changePageHeader: changePageHeader, addData: addData);

      case 'New chain (tags)' :
        assetPath = 'assets/image/book.png';
        page = CreateChainDetails(changePageHeader: changePageHeader, addData: addData);

      case 'New chain (random)' :
        assetPath = 'assets/image/random.png';
        addData!['categoryType'] = 1;
        page = CreateChain(changePageHeader: changePageHeader, addData: addData);

        setState(() {
          topTitleColor = globalBlue;
        });

      case 'New chain (random details)' :
        assetPath = 'assets/image/random.png';
        page = CreateChainTagsPage(changePageHeader: changePageHeader, addData: addData);

      case 'New chain (random tags)' :
        assetPath = 'assets/image/random.png';
        page = CreateChainDetails(changePageHeader: changePageHeader, addData: addData);

      case 'New chain (challange)' :
        assetPath = 'assets/image/challange.png';
        addData!['categoryType'] = 2;
        page = CreateChain(changePageHeader: changePageHeader, addData: addData);

        setState(() {
          topTitleColor = globalGreen;
        });

      case 'New chain (challange details)' :
        assetPath = 'assets/image/challange.png';
        page = CreateChainTagsPage(changePageHeader: changePageHeader, addData: addData);

      case 'New chain (challange tags)' :
        assetPath = 'assets/image/challange.png';
        page = CreateChainDetails(changePageHeader: changePageHeader, addData: addData);

      case 'Go Back' :
        assetPath = lastAssetsPath;
        page = lastCurrentPage;
        setState(() {
          friendsPage = lastPageBools[0];
          profilePage = lastPageBools[1];
          unchainedPage = lastPageBools[2];
          explorePage = lastPageBools[3];
          unchainedPageRefresh = lastPageBools[4];
        });

      default :
        assetPath = 'assets/image/explore.png';
        page = ExplorePage(
          exploreData: {'userId' : widget.uid}, 
          changePageHeader: changePageHeader, 
          displayProgress: displayProgress,
          key: null
        );
        break;
    }
    
    lastCurrentPage = currentPage;
    lastCurrentPageDisplayedTitle = currentPageDisplayedTitle;

    if(mounted){
      setState(() {
        currentPageDisplayedTitle = tempCurrentTitle;
        topImageAsset = assetPath;
        currentPage = page;
      });
    }
  }

  void animateOpacity(AnimationController animationOpacity){
    animationOpacity.reset();
    animationOpacity.forward();

    _animationOpacity.reset();
    _animationOpacity.forward();
  }

  Future<void> _setUserIdentifier() async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString('userId', widget.uid);

    _checkIfWorkmanagerMustBeEnabled(sharedPreferences, widget.uid);
  }

  void updateUIFromSetting(){
    setState(() {});
  }

  void displayProgress(bool display){
    if(mounted){
      setState(() {
        displayProgressBool = display;
      });
    }
  }

  void _checkIfWorkmanagerMustBeEnabled(SharedPreferences sharedPreferences, String userId){

    if(sharedPreferences.getBool('notificationsEnabled${widget.uid}') ?? true){
      Workmanager().registerPeriodicTask(
        '1', 
        'listenerTask',
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        inputData: {
          'userId' : widget.uid
        }
      );

      OneSignal.User.pushSubscription.optIn();
    }
  }
}