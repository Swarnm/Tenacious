import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/pages/promoposts_screen.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityPromoFeed extends StatefulWidget {
  @override
  _ActivityPromoFeedState createState() => _ActivityPromoFeedState();
}

class _ActivityPromoFeedState extends State<ActivityPromoFeed> {
  getActivityPromoFeed() async {
    QuerySnapshot snapshot = await activityPromoFeedRef
        .document(currentUser.id)
        .collection('promofeedItems')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .getDocuments();
    List<ActivityPromoFeedItem> promofeedItems = [];
    snapshot.documents.forEach((doc) {
      promofeedItems.add(ActivityPromoFeedItem.fromDocument(doc));
      // print('Activity Feed Item: ${doc.data}');
    });
    return promofeedItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: header(context, titleText: "Activity PromoFeed"),
      body: Container(
          child: FutureBuilder(
        future: getActivityPromoFeed(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          return ListView(
            children: snapshot.data,
          );
        },
      )),
    );
  }
}

Widget mediaPreview;
String activityPromoItemText;

class ActivityPromoFeedItem extends StatelessWidget {
  final String username;
  final String userId;
  final String type; // 'like', 'follow', 'comment'
  final String promomediaUrl;
  final String promopostsId;
  final String userProfileImg;
  final String promocommentData;
  final Timestamp timestamp;

  ActivityPromoFeedItem({
    this.username,
    this.userId,
    this.type,
    this.promomediaUrl,
    this.promopostsId,
    this.userProfileImg,
    this.promocommentData,
    this.timestamp,
  });

  factory ActivityPromoFeedItem.fromDocument(DocumentSnapshot doc) {
    return ActivityPromoFeedItem(
      username: doc['username'],
      userId: doc['userId'],
      type: doc['type'],
      promopostsId: doc['promopostsId'],
      userProfileImg: doc['userProfileImg'],
      promocommentData: doc['promocommentData'],
      timestamp: doc['timestamp'],
      promomediaUrl: doc['promomediaUrl'],
    );
  }

  showPromoPosts(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PromoPostsScreen(
          promopostsId: promopostsId,
          userId: userId,
        ),
      ),
    );
  }

  configureMediaPreview(context) {
    if (type == "promolike" || type == 'promocomment') {
      mediaPreview = GestureDetector(
        onTap: () => showPromoPosts(context),
        child: Container(
          height: 50.0,
          width: 50.0,
          child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: CachedNetworkImageProvider(promomediaUrl),
                  ),
                ),
              )),
        ),
      );
    } else {
      mediaPreview = Text('');
    }

    if (type == 'promolike') {
      activityPromoItemText = "liked your promopost";
    } else if (type == 'comment') {
      activityPromoItemText = 'replied: $promocommentData';
    } else {
      activityPromoItemText = "Error: Unknown type '$type'";
    }
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 2.0),
      child: Container(
        color: Colors.white54,
        child: ListTile(
          title: GestureDetector(
            onTap: () =>showProfile(context,profileId: userId),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                      text: username,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ' $activityPromoItemText',
                    ),
                  ]),
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(userProfileImg),
          ),
          subtitle: Text(
            timeago.format(timestamp.toDate()),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: mediaPreview,
        ),
      ),
    );
  }
}

showProfile(BuildContext context, {String profileId}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Profile(
        profileId: profileId,
      ),
    ),
  );
}