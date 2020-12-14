import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;


class PromoComments extends StatefulWidget {
  final String promopostsOwnerId;
  final String promopostsMediaUrl;
  final String promopostsId;

  PromoComments({
    this.promopostsMediaUrl,
    this.promopostsOwnerId,
    this.promopostsId,
  });
  @override
  PromoCommentsState createState() => PromoCommentsState(
    promopostsMediaUrl: this.promopostsMediaUrl,
    promopostsOwnerId: this.promopostsOwnerId,
    promopostsId: this.promopostsId,
  );
}

class PromoCommentsState extends State<PromoComments> {
  TextEditingController promocommentController=TextEditingController();
  final String promopostsOwnerId;
  final String promopostsMediaUrl;
  final String promopostsId;

  PromoCommentsState({
    this.promopostsMediaUrl,
    this.promopostsOwnerId,
    this.promopostsId,
  });

 buildPromoComments() {
   return StreamBuilder(
    stream: promocommentsRef.document(promopostsId).collection('promocomments').orderBy("timestamp",descending : false).snapshots(),
    builder: (BuildContext context,snapshot) {
      if(!snapshot.hasData){
        return circularProgress();
      }
      List<PromoComment> promocomments=[];
      snapshot.data.documents.forEach((doc){
        promocomments.add(PromoComment.fromDocuments(doc));
      });
      return ListView(children: promocomments,
      );
    });
 }

 addPromoComment() {
   promocommentsRef
   .document(promopostsId)
   .collection("promocomments")
   .add({
     "username": currentUser.username,
     "promocomments": promocommentController.text,
     "timestamp": timestamp,
     "avatarUrl": currentUser.photoUrl,
     "userId": currentUser.id,
   });
    bool isNotPromoPostOwner = promopostsOwnerId != currentUser.id;
    if (isNotPromoPostOwner) {
      activityPromoFeedRef.document(promopostsOwnerId).collection('promofeedItems').add({
        "type": "promocomments",
        "promocommentData": promocommentController.text,
        "timestamp": timestamp,
        "promopostsId": promopostsId,
        "userId": currentUser.id,
        "username": currentUser.username,
        "userProfileImg": currentUser.photoUrl,
        "promomediaUrl": promopostsMediaUrl,
      });
    }
   promocommentController.clear();
 }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context,titleText: "Promo Comments"),
      body: Column(
        children: <Widget>[
          Expanded(child: buildPromoComments()),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: promocommentController,
              decoration: InputDecoration(labelText: "Write a comment...."),
              ),
              trailing: OutlineButton(
                onPressed: ()=> addPromoComment(),
                borderSide: BorderSide.none,
                child: Text('Post'),
              ),
          ),
        ],
      ),
    );
  }
}

class PromoComment extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final String promocomments;
  final Timestamp timestamp;

  PromoComment({
    this.username,
    this.userId,
    this.avatarUrl,
    this.promocomments,
    this.timestamp,
  });

  factory PromoComment.fromDocuments(DocumentSnapshot doc){
    return PromoComment(
      username: doc['username'],
      userId: doc['userId'],
      promocomments: doc['promocomments'],
      timestamp: doc['timestamp'],
      avatarUrl: doc['avatarUrl'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children:<Widget>[
        ListTile(
          title: Text(promocomments),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          subtitle: Text(timeago.format(timestamp.toDate())),

        ),
        Divider(),
      ],
    );
  }
}
