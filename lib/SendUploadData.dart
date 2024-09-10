import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doom_chain/GlobalColors.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SendUploadData{
  static Future<bool> uploadData({
    required FirebaseFirestore firebase,
    required FirebaseStorage storage,
    required Map<String, dynamic>? addData,
    required Map<String, dynamic>? chainMap,
    required List<List<String>>? contributorsList,
    required bool disableFirstPhraseForChallange,
    required String theme,
    required String title,
    required bool photoSkipped,
    required String chainIdentifier,
    required String categoryName,
    required bool chainSkipped,
    required String? photoPath,
    required bool mounted,
    required BuildContext? context,
    required void Function(String, Map<String, dynamic>?)? changePageHeader,
    required newChainOrExtend}
  ) async {

    String userId = addData!['userId'];
    DocumentSnapshot userDetails = await firebase.collection('UserDetails').doc(userId).get();
    String userNationality = userDetails.get('countryName');

    QuerySnapshot? allUsersFromSameCountry;
    QuerySnapshot? allUserNotFromSameCountry;
    QuerySnapshot? allFriends;

    //UPLOADING

    if(newChainOrExtend){
  
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      userId = sharedPreferences.getString('userId') ?? 'root';

      if(userDetails.exists){  
        
        allUsersFromSameCountry = await firebase.collection('UserDetails').where('countryName', isEqualTo: userNationality).get();   
        allUserNotFromSameCountry = await firebase.collection('UserDetails').where('countryName', isNotEqualTo: userNationality).get();

        if(addData['randomOrFriends']){

          if(addData['chainPieces'] > allUserNotFromSameCountry.docs.length && addData['chainPieces'] > allUsersFromSameCountry.docs.length){
            Fluttertoast.showToast(msg: 'Not enough users', toastLength: Toast.LENGTH_LONG, backgroundColor: globalBlue);
            return Future.value(false);
          }
        }
        else{
          allFriends = await firebase.collection('UserDetails').doc(newChainOrExtend ? addData['userId'] : chainMap!['userIdForFriendList']).collection('Friends').get();

          if(addData['chainPieces'] > allFriends.docs.length){
            Fluttertoast.showToast(msg: 'Not enough users', toastLength: Toast.LENGTH_LONG, backgroundColor: globalBlue);
            return Future.value(false);
          }
        }

        String? tagJSON;

        if(addData!['tagList'] != null){
          tagJSON = jsonEncode(addData['tagList']);
        }

        updateGlobalTagList(addData['tagList'], chainIdentifier, categoryName, userNationality, firebase);

        contributorsList = List.empty(growable: true);
        String firstPhrase = ' ';

        String finalPhotoStorageId = '-';

        if(!photoSkipped){
          finalPhotoStorageId = 'uploads/$chainIdentifier/${addData['chainPieces']}_$userId';
        }

        if(disableFirstPhraseForChallange){
          firstPhrase = theme;
        }
        else{
          firstPhrase = title;
          contributorsList.add([userId, firstPhrase, finalPhotoStorageId]);
        }

        chainMap = {
          'random' : addData['randomOrFriends'],
          'allPieces' : addData['allOrPartChain'],
          'remainingOfContrib' : addData['chainPieces'],
          'totalContrib' : addData['chainPieces'],
          'tagList' : tagJSON,
          'theme' : addData['theme'],
          'title' : addData['title'].isEmpty ? categoryName : addData['title'] ,
          'contributions' : jsonEncode(contributorsList),
          'userIdForFriendList' : userId,
          'totalPoints' : 0,
          'totalContributions' : 0,
          'likes' : 0,
          'chainNationality' : userNationality};

        firebase.collection('PendingChains').doc(categoryName).collection(userNationality).doc(chainIdentifier).set(chainMap);
      }
      else{
        return Future.value(false);
      }

      if(!photoSkipped){
        Reference reference = storage.ref().child('uploads/$chainIdentifier/${addData['chainPieces']}_$userId');
        reference.putFile(File(photoPath!));
      }
    }

    //SENDING TO

    Random random = Random();
    String userIdToSendChain = '';

    if(addData['randomOrFriends']){

      List<int> userRandomIndexes = [-1, -1, -1];

      allUsersFromSameCountry ??= await firebase.collection('UserDetails').where('countryName', isEqualTo: userNationality).get();
      allUserNotFromSameCountry ??= await firebase.collection('UserDetails').where('countryName', isNotEqualTo: userNationality).get();

      if(allUsersFromSameCountry.docs.isNotEmpty){
        userRandomIndexes[0] = random.nextInt(allUsersFromSameCountry.docs.length);

        if(allUsersFromSameCountry.docs.length > 1){
          userRandomIndexes[1] = random.nextInt(allUsersFromSameCountry.docs.length);

          while(userRandomIndexes[0] == userRandomIndexes[1]){
            userRandomIndexes[1] = random.nextInt(allUsersFromSameCountry.docs.length);
          }
        }
      }

      if(allUserNotFromSameCountry.docs.isNotEmpty){
        userRandomIndexes[2] = random.nextInt(allUserNotFromSameCountry.docs.length);
      }

      int randomFinalUserIndex = random.nextInt(userRandomIndexes.length);

      if(randomFinalUserIndex == 0 && userRandomIndexes[0] != -1){
        if(allUsersFromSameCountry.docs[userRandomIndexes[0]].id == userId){
          if(userRandomIndexes[1] != -1){
            userIdToSendChain = allUsersFromSameCountry.docs[userRandomIndexes[1]].id;
          }
          else{
            randomFinalUserIndex = 2;
            userIdToSendChain = allUserNotFromSameCountry.docs[userRandomIndexes[2]].id;
          }
        }
      }
      else if(randomFinalUserIndex == 1 && userRandomIndexes[1] != -1){
        if(allUsersFromSameCountry.docs[userRandomIndexes[1]].id == userId){
          if(userRandomIndexes[0] != -1){
            randomFinalUserIndex = 0;
            userIdToSendChain = allUsersFromSameCountry.docs[userRandomIndexes[0]].id;
          }
          else{
            userRandomIndexes[1] = -1;
          }
        }
      }
      else if(randomFinalUserIndex == 2 && userRandomIndexes[2] != -1){
        userIdToSendChain = allUserNotFromSameCountry.docs[userRandomIndexes[2]].id;
      }

      if(userRandomIndexes[randomFinalUserIndex] == -1){
        Fluttertoast.showToast(msg: 'Please retry', toastLength: Toast.LENGTH_LONG, backgroundColor: globalBlue);
        return Future.value(false);
      }
    }
    else{
      
      allFriends ??= await firebase.collection('UserDetails').doc(newChainOrExtend ? userId : chainMap!['userIdForFriendList']).collection('Friends').get();

      if(allFriends.docs.isEmpty){
        return Future.value(false);
      }

      int randomFriendIndex = random.nextInt(allFriends.docs.length);

      while((chainMap!['contributions'] as String).contains(allFriends.docs[randomFriendIndex].id)){
        randomFriendIndex = random.nextInt(allFriends.docs.length);
      }

      userIdToSendChain = allFriends.docs[randomFriendIndex].id;
    }

    if(!newChainOrExtend){
      String phrase = ' ';
        if(disableFirstPhraseForChallange){
          phrase = theme;
        }
        else{
          phrase = title;
        }

        String finalPhotoStorageId = '-';

        if(!photoSkipped){
          finalPhotoStorageId = 'uploads/$chainIdentifier/${addData['chainPieces']}_$userId';
        }

        if(!chainSkipped){
          contributorsList?.add([userId, phrase, finalPhotoStorageId]);
          chainMap!['contributions'] = jsonEncode(contributorsList);
        }
    }

    if(userIdToSendChain != ''){
      sendToSpecificUser(userIdToSendChain, chainIdentifier, firebase, categoryName, chainMap!['chainNationality'], chainMap['userIdForFriendList'], chainMap['contributions'], newChainOrExtend ? addData['randomOrFriend'] : chainMap['randomOrFriend']);
    }

    if(!chainSkipped){

      int categoryTypeContributions = userDetails.get('${categoryName}Contributions');
      int totalContributions = userDetails.get('totalContributions');

      firebase.collection('UserDetails').doc(userId).update({
        '${categoryName}Contributions' : categoryTypeContributions + 1,
        'totalContributions' : totalContributions + 1
      });
    }

    if(context != null && mounted && context.mounted){
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    if(changePageHeader != null){
      changePageHeader('Unchained (refresh)', null);
    }

    if(newChainOrExtend){
      Fluttertoast.showToast(msg: 'Chain sent', toastLength: Toast.LENGTH_LONG, backgroundColor: globalBlue);
    }

    return Future.value(true);
  }
  
  static void sendToSpecificUser(String userId, String chainId, FirebaseFirestore firebase, String categoryName, String chainNationality, String chainAuthor, String contributors, bool randomOrFriend) async {
    firebase.collection('UserDetails').doc(userId).collection('PendingPersonalChains').doc(chainId).set({
      'categoryName' : categoryName,
      'chainNationality' : chainNationality,
      'receivedTime' : Timestamp.now(),
      'userIdForFriendList' : chainAuthor,
      'contributions' : contributors,
      'randomOrFriend' : randomOrFriend
    });
  }

  static void updateGlobalTagList(List<String> tagList, String chainId, String categoryName, String chainNationality, FirebaseFirestore firebase) async {

    if(tagList.isEmpty){
      return;
    }

    await firebase.collection('ChainTags').doc(tagList.first.toLowerCase().trim()).set({
      chainId : jsonEncode([categoryName, chainNationality])
    });

    for(int i = 1; i < tagList.length; i++){
      firebase.collection('ChainTags').doc(tagList[i].toLowerCase().trim()).update({
        chainId : jsonEncode([categoryName, chainNationality])
      });
    }
  }
}