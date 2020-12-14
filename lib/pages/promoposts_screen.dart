import 'package:flutter/material.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/promopost.dart';
import 'package:fluttershare/widgets/progress.dart';

class PromoPostsScreen extends StatelessWidget {
  final String userId;
  final String promopostsId;

  PromoPostsScreen({this.userId, this.promopostsId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: promopostsRef
          .document(userId)
          .collection('userPromoPosts')
          .document(promopostsId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        PromoPosts promoposts = PromoPosts.fromDocuments(snapshot.data);
        return Center(
          child: Scaffold(
            appBar: header(context, titleText: promoposts.description),
            body: ListView(
              children: <Widget>[
                Container(
                  child: promoposts,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

