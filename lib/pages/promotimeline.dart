import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:fluttershare/widgets/promopost.dart';

final usersRef = Firestore.instance.collection('users');

class PromoTimeline extends StatefulWidget {
  final User currentUser;

  PromoTimeline({this.currentUser});

  @override
  _PromoTimelineState createState() => _PromoTimelineState();
}

class _PromoTimelineState extends State<PromoTimeline> {
  List<PromoPosts> promoposts;

  @override
  void initState() {
    super.initState();
  getPromoTimeline();
  }

  getPromoTimeline() async {
    QuerySnapshot snapshots = await promoTimelineRef
        .document(widget.currentUser.id)
        .collection('timelinePromoPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    List<PromoPosts> promoposts =
        snapshots.documents.map((doc) => PromoPosts.fromDocuments(doc)).toList();
    setState(() {
      this.promoposts = promoposts;
    });
  }

  buildPromoTimeline() {
    if (promoposts == null) {
      return circularProgress();
    } else if (promoposts.isEmpty) {
      return Text("No posts");
    } else {
      return ListView(children: promoposts);
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
        appBar: header(context, isAppTitle: true),
        body: RefreshIndicator(
            onRefresh: () => getPromoTimeline(), child: buildPromoTimeline()));
  }
}
