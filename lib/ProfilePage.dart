import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doom_chain/GlobalValues.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePage extends StatefulWidget{

  final void Function(String, Map<String, dynamic>?) changePageHeader;
  final String userIdToDisplay;
  final String originalUserId;
  final bool isThisUser;
  final Key? key;

  ProfilePage({
    required this.changePageHeader,
    required this.userIdToDisplay,
    required this.originalUserId,
    required this.isThisUser,
    required this.key
  }) : super(key: key);

  @override
  _ProfilePage createState() => _ProfilePage();
}

class _ProfilePage extends State<ProfilePage> with SingleTickerProviderStateMixin{

  final FirebaseFirestore _firebase = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  late AnimationController animationControllerSlide;

  late Map<String, dynamic> profileInfo;

  late String profileImageUrl;
  bool dataRetreived = false;
  bool hasProfileImage = false;
  bool userDataRetreived = false;
  int totalPoints = 0;
  int totalContributions = 0;
  int totalFriends = 0;
  int userRank = 1;
  DateFormat format = DateFormat("dd-MM-yyyy");
  late DateTime accountSince;

  @override
  void initState() {
    super.initState();

    animationControllerSlide = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    retreiveDataFirebase();
  }

  @override
  Widget build(BuildContext context){

    final double width = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: widget.isThisUser,
      onPopInvoked: (didPop) {
        if(!didPop){

          if(!widget.isThisUser){
            widget.changePageHeader('Go Back', null);
          }

          if(fromProfileToChainView){
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => chainViewToPushInNavigator!));
          }

          fromProfileToChainView = false;
        }
      },
      child: Scaffold(
        backgroundColor: globalBackground,
        body: Column(
          children: [
            Wrap(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset('assets/image/roundchain.png', width: width * 0.5, height: width * 0.5, color: dataRetreived ? _getProfileChainColor() : Colors.grey),

                        ClipOval(
                          child: dataRetreived 
                            ? (hasProfileImage

                              ? CachedNetworkImage(
                                imageUrl: profileImageUrl,
                                width: width * 0.2,
                                height: width * 0.2,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const CircularProgressIndicator(),
                                errorWidget: (context, url, error) => Icon(Icons.error, size: width * 0.25)
                              )
                              : Image.asset('assets/image/profile.png', width: width * 0.25, height: width * 0.25, color: globalTextBackground)
                            )
                            : const CircularProgressIndicator()
                        )
                      ],
                    ),
                  )      
                ),

                Align(
                  alignment: Alignment.center,
                  child: Text(userDataRetreived ? '${profileInfo['nickname']} | Rank $userRank' : '', style: GoogleFonts.nunito(fontSize: width * 0.05, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
                )
              ],
            ),

            Padding(
              padding: EdgeInsets.only(top: width * 0.025, bottom: width * 0.01),
              child: Divider(
                height: 2.0,
                color: globalDrawerBackground,
              ),
            ),

            Expanded(
              child: Padding(
                padding: EdgeInsets.all(width * 0.025),
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(width * 0.01),
                            child: Image.asset('assets/image/logo.png', width: width * 0.12, height: width * 0.12, color: globalTextBackground),
                          ),
                          Padding(
                            padding: EdgeInsets.all(width * 0.01),
                            child: Text(userDataRetreived ? totalPoints.toString() : '-', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalPurple, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          ),
                          Padding(
                            padding: EdgeInsets.all(width * 0.01),
                            child: Text('Total points', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          ),
                        ],
                      ),

                      InkWell(
                        onTap: () {
                          if(userDataRetreived){
                            Map<String, dynamic> profileInfoWithUserId = profileInfo;
                            profileInfoWithUserId['userId'] = widget.userIdToDisplay;
                            widget.changePageHeader('Profile (chains)', profileInfoWithUserId);
                          }
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(width * 0.01),
                              child: Image.asset('assets/image/infinite.png', width: width * 0.12, height: width * 0.12, color: globalTextBackground),
                            ),
                            Padding(
                              padding: EdgeInsets.all(width * 0.01),
                              child: Text(userDataRetreived ? totalContributions.toString() : '-', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalPurple, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            ),
                            Padding(
                              padding: EdgeInsets.all(width * 0.01),
                              child: Text('All chains', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            ),
                          ],
                        )
                      ),
                      
                      InkWell(
                        onTap: () {
                          widget.changePageHeader('Friends', {
                            'userId' : widget.userIdToDisplay
                          });
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(width * 0.01),
                              child: Image.asset('assets/image/friends.png', width: width * 0.12, height: width * 0.12, color: globalTextBackground),
                            ),
                            Padding(
                              padding: EdgeInsets.all(width * 0.01),
                              child: Text(userDataRetreived ? totalFriends.toString() : '-', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalPurple, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            ),
                            Padding(
                              padding: EdgeInsets.all(width * 0.01),
                              child: Text('Friends', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            ),
                          ],
                        )
                      ),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(width * 0.01),
                            child: Image.asset('assets/image/time.png', width: width * 0.12, height: width * 0.12, color: globalTextBackground),
                          ),
                          Padding(
                            padding: EdgeInsets.all(width * 0.01),
                            child: Text(userDataRetreived ? format.format(accountSince) : '-', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalPurple, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          ),
                          Padding(
                            padding: EdgeInsets.all(width * 0.01),
                            child: Text('User since', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          ),
                        ],
                      ),
                    ],
                )
              ),
            )
          ],
        ),
      )
    );
  }

  Future<void> retreiveDataFirebase() async {
    try{

      profileInfo = (await _firebase.collection('UserDetails').doc(widget.userIdToDisplay).get()).data() as Map<String, dynamic>;

      int numberOfFriends = profileInfo['friendsCount'] ?? 0;
      Timestamp accountSinceTimestamp = (await _firebase.collection('UserDetails').doc(widget.userIdToDisplay).get()).get('accountSince');

      accountSince = accountSinceTimestamp.toDate();

      setState(() {
        userDataRetreived = true;
        totalPoints = profileInfo['totalPoints'];
        totalContributions = profileInfo['totalContributions'];
        totalFriends = numberOfFriends;
      });

      if(profileInfo['avatarPath'] != '-'){
        Reference avatarPath = _storage.ref().child(profileInfo['avatarPath']);
        profileImageUrl = await avatarPath.getDownloadURL();
        setState(() {
          hasProfileImage = true;
        });
      }
      else{
        
      }
    }
    catch(e){
      print(e);
    }

    if(mounted){
      setState(() {
        dataRetreived = true;
      });
    }
  }

  Color _getProfileChainColor(){
    double normalizedPoints = (totalPoints % 100).clamp(50, 100) / 100;
    Color secondColor;

    if(totalPoints < 100){
      secondColor = globalRank1;
      userRank = 1;
    }else if(totalPoints < 200){
      secondColor = globalRank2;
      userRank = 2;
    }else if(totalPoints < 300){
      secondColor = globalRank3;
      userRank = 3;
    }else if(totalPoints < 400){
      secondColor = globalRank4;
      userRank = 4;
    }else if(totalPoints < 500){
      secondColor = globalRank5;
      userRank = 5;
    }else if(totalPoints < 600){
      secondColor = globalRank6;
      userRank = 6;
    }else if(totalPoints < 700){
      secondColor = globalRank7;
      userRank = 7;
    }else{
      secondColor = globalRank8;
      userRank = 8;

      if(totalPoints > 899){
        normalizedPoints = 1;
      }
    }

    return Color.lerp(Colors.grey[200], secondColor, normalizedPoints) ?? Colors.grey;
  }

  @override
  void dispose() {
    animationControllerSlide.dispose();
    super.dispose();
  }
}