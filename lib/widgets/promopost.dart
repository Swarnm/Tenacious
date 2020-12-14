import 'dart:async';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/pages/promoactivity_feed.dart';
import 'package:fluttershare/pages/promocomments.dart';
import 'package:fluttershare/widgets/custom_image.dart';
import 'package:fluttershare/widgets/progress.dart';

class PromoPosts extends StatefulWidget {
  final String promopostsId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String promomediaUrl;
  final dynamic promolikes;

  PromoPosts({
  this.promopostsId,
  this.ownerId,
  this.username,
  this.location,
  this.description,
  this.promomediaUrl,
  this.promolikes,
});

factory PromoPosts.fromDocuments(DocumentSnapshot docs){
  return PromoPosts(
    promopostsId: docs['promopostsId'],
    ownerId: docs['ownerId'],
    username: docs['username'],
    location: docs['location'],
    description: docs['description'],
    promomediaUrl: docs['promomediaUrl'],
    promolikes: docs['promolikes'],
  );
}

int getPromoLikeCount(promolikes){
  if(promolikes==null){
    return 0;
  }
  int count=0;
  promolikes.values.forEach((val){
    if(val==true){
      count+=1;
    }
  });
  return count;
}

  @override
  _PromoPostsState createState() => _PromoPostsState(
    promopostsId: this.promopostsId,
    ownerId: this.ownerId,
    username: this.username,
    location: this.location,
    description: this.description,
    promomediaUrl: this.promomediaUrl,
    promolikes: this.promolikes,
    promolikeCount: getPromoLikeCount(this.promolikes),
      );
}

class _PromoPostsState extends State<PromoPosts> {
  final String currentUserId=currentUser?.id;
  final String promopostsId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String promomediaUrl;
  int promolikeCount;
  Map promolikes;
  bool ispromoLiked;
  bool showHeart=false;

  _PromoPostsState({
  this.promopostsId,
  this.ownerId,
  this.username,
  this.location,
  this.description,
  this.promomediaUrl,
  this.promolikes,
  this.promolikeCount,
  });

  buildPromoPostHeader() {
    return FutureBuilder(
      future: usersRef.document(ownerId).get(),
      builder: (context,snapshot) {
        if(!snapshot.hasData) {
          return circularProgress();
        }
        User user=User.fromDocument(snapshot.data);
        bool isPromoPostOwner = currentUserId == ownerId;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: () => showProfile(context,profileId: user.id),
            child:Text(
              user.username ==null? ' ' : user.username,
              style:TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(location),
          trailing: isPromoPostOwner ? IconButton(
            onPressed: () =>handleDeletePromoPost(context),
            icon: Icon(Icons.more_vert),
          )
          :Text(''),
        );
      },
    );
  }

   handleDeletePromoPost(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Remove this post?"),
            children: <Widget>[
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context);
                    deletePromoPost();
                  },
                  child: Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  )),
              SimpleDialogOption(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel')),
            ],
          );
        });
  }

  // Note: To delete post, ownerId and currentUserId must be equal, so they can be used interchangeably
  deletePromoPost() async {
    // delete post itself
    promopostsRef
        .document(ownerId)
        .collection('userPromoPosts')
        .document(promopostsId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // delete uploaded image for thep ost
    storageRef.child("promoposts_$promopostsId.jpg").delete();
    // then delete all activity feed notifications
    QuerySnapshot activityPromoFeedSnapshot = await activityPromoFeedRef
        .document(ownerId)
        .collection("promofeedItems")
        .where('promopostsId', isEqualTo: promopostsId)
        .getDocuments();
    activityPromoFeedSnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // then delete all comments
    QuerySnapshot promocommentsSnapshot = await promocommentsRef
        .document(promopostsId)
        .collection('promocomments')
        .getDocuments();
    promocommentsSnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }


  handlePromoLikePost() {
    bool _ispromoLiked=promolikes[currentUserId]==true;

    if(_ispromoLiked) {
      promopostsRef.document(ownerId).collection('userPromoPosts').document(promopostsId).updateData({'promolikes.$currentUserId': false});
      removePromoLikeFromActivityFeed();
      setState(() {
        promolikeCount -=1;
        ispromoLiked=false;
        promolikes[currentUserId]=false;
      });
    } else if(!_ispromoLiked){
      promopostsRef.document(ownerId).collection('userPromoPosts').document(promopostsId).updateData({'promolikes.$currentUserId': true});
      addPromoLikeToActivityFeed();
      setState(() {
        promolikeCount +=1;
        ispromoLiked=true;
        promolikes[currentUserId]==true;
        showHeart=true;
      });
      Timer(Duration(milliseconds: 500),(){
        setState(() {
          showHeart=false;
        });
      });
    }
  }

  addPromoLikeToActivityFeed() {
    // add a notification to the postOwner's activity feed only if comment made by OTHER user (to avoid getting notification for our own like)
    bool isNotPromoPostOwner = currentUserId != ownerId;
    if (isNotPromoPostOwner) {
      activityPromoFeedRef
          .document(ownerId)
          .collection("promofeedItems")
          .document(promopostsId)
          .setData({
        "type": "like",
        "username": currentUser.username,
        "userId": currentUser.id,
        "userProfileImg": currentUser.photoUrl,
        "promopostsId": promopostsId,
        "promomediaUrl": promomediaUrl,
        "timestamp": timestamp,
      });
    }
  }

   removePromoLikeFromActivityFeed() {
    bool isNotPromoPostOwner = currentUserId != ownerId;
    if (isNotPromoPostOwner) {
      activityPromoFeedRef
          .document(ownerId)
          .collection("promofeedItems")
          .document(promopostsId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    }
  }

  buildPromoPostImage() {
    return GestureDetector(
      onDoubleTap: handlePromoLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
         cachedNetworkImage(promomediaUrl),
         showHeart ? Animator(duration:  Duration(milliseconds: 300),tween: Tween(begin: 0.8,end: 1.4),
         curve: Curves.elasticOut,
         cycles: 0,
         builder: (anim)=> Transform.scale(scale: anim.value,
          child:Icon(Icons.favorite,size: 80.0,color: Colors.red),
          ),
         ): Text(""),
        ],
      ),
    );
  }

  buildPromoPostFooter() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 40.0,left: 20.0)),
            GestureDetector(
              onTap: handlePromoLikePost,
              child:Icon(
                ispromoLiked ? Icons.favorite : Icons.favorite_border,
                size: 28.0,
                color: Colors.pink,
              ),
            ),
            Padding(padding: EdgeInsets.only(right: 20.0)),
            GestureDetector(
              onTap: () => showPromoComments(
                context,
                promopostsId: promopostsId,
                ownerId: ownerId,
               promomediaUrl: promomediaUrl,
              ),
              child:Icon(
                Icons.chat,
                size: 28.0,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$promolikeCount likes",
                style: TextStyle(color: Colors.black,
                fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
         Row(
           crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$username ",
                style: TextStyle(color: Colors.black,
                fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: Text(description)),
          ],
        ),
      ],
    );
  }
  

  @override
  Widget build(BuildContext context) {
    ispromoLiked =( promolikes[currentUserId]== true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPromoPostHeader(),
        buildPromoPostImage(),
        buildPromoPostFooter(),
      ],
    );
  }
}
showPromoComments(BuildContext context,{String promopostsId,String ownerId,String promomediaUrl}){
  Navigator.push(context, MaterialPageRoute(builder: (context){
    return PromoComments(
      promopostsId: promopostsId,
      promopostsOwnerId: ownerId,
      promopostsMediaUrl: promomediaUrl,
     );
  }));
}