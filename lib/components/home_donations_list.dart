import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodboard/components/main_button.dart';
import 'package:foodboard/constants.dart';
import 'package:foodboard/components/gradient_icon.dart';
import 'package:foodboard/utils/database.dart';
import 'package:foodboard/loading.dart';

import 'package:intl/intl.dart';

import '../screens/donation_form.dart';

class HomeDonationsList extends StatelessWidget {
  final uid;
  final userType;
  final status;

  HomeDonationsList(this.uid, this.userType, this.status);

  @override
  Widget build(BuildContext context) {
    var stream;
    if (userType == "donor")
      stream = FirebaseFirestore.instance
          .collection('donations')
          .where('donorID', isEqualTo: uid)
          .where('status', isEqualTo: status);
    else if (userType == "pantry") {
      if (status == "pending") {
        stream = FirebaseFirestore.instance
            .collection('donations')
            .where('status', isEqualTo: status); // Show all pending
      } else {
        stream = FirebaseFirestore.instance
            .collection('donations')
            .where('pantryID', isEqualTo: uid)
            .where('status', isEqualTo: status);
      }
    } else if (userType == "rescuer") {
      if (status == "pending") {
        stream = FirebaseFirestore.instance
            .collection('donations')
            .where('rescuerID',
                isEqualTo: "") // TODO: Change Band-aid solution here
            .where('status', isEqualTo: "accepted");
      } else {
        stream = FirebaseFirestore.instance
            .collection('donations')
            .where('rescuerID', isEqualTo: uid)
            .where('status', isEqualTo: status);
      }
    } else
      return Text("Firebase error.");
    return StreamBuilder<QuerySnapshot>(
        stream: stream.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadingCards();
          }

          return Container(
              constraints: BoxConstraints.expand(),
              color: cards_background_color,
              child: ListView(
                children: snapshot.data.docs.map((DocumentSnapshot doc) {
                  return DonationCard(
                      doc.id, uid, doc.data(), userType, status);
                }).toList(),
              ));
        });
  }
}

class DonationCard extends StatelessWidget {
  final donationID;
  final uid;
  final cardData;
  final cardType;
  final status;

  DonationCard(
      this.donationID, this.uid, this.cardData, this.cardType, this.status);

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(
              offset: Offset(4, 0),
              color: shadow_color,
              spreadRadius: -13.0,
              blurRadius: 8.0)
        ]),
        child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: EdgeInsets.fromLTRB(20, 0, 20, 15),
            child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Wrap(children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Donation ID: " + donationID,
                                  style: style_donation_no,
                                )),
                            Container(
                              width: 320,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  cardData["category"],
                                  style: style_donation_name,
                                ),
                              ),
                            ),
                            Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  cardData["subcategory"],
                                  style: style_donation_food_tag,
                                )),
                            Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  cardData["deliverTo"],
                                  style: style_donation_address,
                                )),
                          ]),
                    ]),
                    // SizedBox(height: 10.0),
                    // DonationCardFoodTags(cardData["tags"]),
                    SizedBox(height: 10.0),
                    DonationDetailItem(Icons.warning, "Expiration Date",
                        cardData["expiry"], true),
                    SizedBox(height: 5.0),
                    DonationDetailItem(Icons.location_on, "Pick-Up Address",
                        cardData["deliverFrom"], false),
                    SizedBox(height: 5.0),
                    DonationDetailItem(
                        // TODO: Change this icon too.
                        Icons.attach_money,
                        "Estimated Weight",
                        cardData["estWeight"].toString() + " kg",
                        false),
                    SizedBox(height: 5.0),
                    DonationDetailItem(Icons.note, "Notes", "", false),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        cardData["notes"],
                        style: style_donation_notes,
                      ),
                    ),
                    SizedBox(height: 10.0),
                    (cardType == "donor")
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: InkWell(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    WidgetSpan(
                                      child: Icon(
                                        Icons.edit,
                                        color: header_item_color,
                                        size: 18,
                                      ),
                                    ),
                                    TextSpan(
                                        text: "Edit Donation",
                                        style: TextStyle(
                                            color: header_item_color,
                                            decoration:
                                                TextDecoration.underline)),
                                  ],
                                ),
                              ),
                              onTap: () {
                                FirebaseFirestore.instance
                                    .collection("donations")
                                    .doc(donationID)
                                    .get()
                                    .then((DocumentSnapshot snapshot) {
                                  if (snapshot.exists) {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => DonationForm(
                                                  uid,
                                                  true,
                                                  donationID,
                                                  snapshot.data()["category"],
                                                  snapshot
                                                      .data()["subcategory"],
                                                  snapshot.data()["expiry"],
                                                  snapshot
                                                      .data()["deliverFrom"],
                                                  snapshot.data()["estWeight"],
                                                  snapshot.data()["notes"],
                                                )));
                                  } else {}
                                });
                              },
                            ),
                          )
                        : SizedBox(),
                    (cardType != "donor")
                        ? DonationContactDetails(
                            cardData, (cardType == "rescuer"))
                        : SizedBox(),
                    (cardType == "rescuer" && status == "pending")
                        ? MainButton(
                            text: "Accept",
                            press: () {
                              Database.acceptDonationDelivery(uid, donationID);
                            },
                            gradient: LinearGradient(
                              colors: <Color>[
                                light_green,
                                dark_green,
                              ],
                            ))
                        : SizedBox(),
                    (cardType == "rescuer" && status == "accepted")
                        ? MainButton(
                            text: "Mark as Delivered",
                            press: () {
                              Database.deliverDonationDelivery(uid, donationID);
                            },
                            gradient: LinearGradient(
                              colors: <Color>[
                                light_green,
                                dark_green,
                              ],
                            ))
                        : SizedBox(),
                    (cardType == "pantry" && cardData["status"] == "pending")
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                Container(
                                    width:
                                        MediaQuery.of(context).size.width / 2.7,
                                    // child: MainIconButton(
                                    //     icon: Icons.check_circle,
                                    //     press: () {
                                    //       Database.acceptDonation(
                                    //           uid, donationID);
                                    //     },
                                    //     gradient: LinearGradient(
                                    //       colors: <Color>[
                                    //         light_green,
                                    //         dark_green,
                                    //       ],
                                    //     ))
                                    child: MainTextButton(
                                        text: "Accept",
                                        press: () {
                                          Database.acceptDonation(
                                              uid, donationID);
                                        },
                                        gradient: LinearGradient(
                                          colors: <Color>[
                                            light_green,
                                            dark_green,
                                          ],
                                        ))),
                                Container(
                                    width:
                                        MediaQuery.of(context).size.width / 2.7,
                                    // child: MainIconButton(
                                    //     icon: Icons.remove_circle,
                                    //     press: () {},
                                    //     gradient: LinearGradient(
                                    //       colors: <Color>[
                                    //         light_red,
                                    //         dark_red,
                                    //       ],
                                    //     )),
                                    child: MainTextButton(
                                        text: "Reject",
                                        press: () {
                                          Database.rejectDonation(
                                              uid, donationID);
                                        },
                                        gradient: LinearGradient(
                                          colors: <Color>[
                                            light_red,
                                            dark_red,
                                          ],
                                        ))),
                              ])
                        : SizedBox(),
                  ],
                ))));
  }
}

class DonationContactDetails extends StatelessWidget {
  final cardData;
  final isRescuer;

  DonationContactDetails(this.cardData, this.isRescuer);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        (isRescuer)
            ? Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Donor:",
                  style: style_header_title,
                ))
            : SizedBox(),
        SizedBox(height: (isRescuer) ? 5.0 : 0.0),
        DonationContactDetailSection(cardData["donorID"]),
        (isRescuer)
            ? Column(
                children: [
                  SizedBox(height: 10.0),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Pantry:",
                        style: style_header_title,
                      )),
                  SizedBox(height: 5.0),
                  DonationContactDetailSection(cardData["pantryID"]),
                ],
              )
            : SizedBox(),
        SizedBox(height: 10.0),
      ],
    );
  }
}

class DonationContactDetailSection extends StatelessWidget {
  final String uid;

  DonationContactDetailSection(this.uid);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection("users").doc(uid).get(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text("Firebase Error");
        }

        if (snapshot.connectionState == ConnectionState.done) {
          Map<String, dynamic> user = snapshot.data.data();
          return Column(
            children: [
              DonationContactDetailItem(Icons.person, user["displayName"]),
              Divider(color: header_item_color, height: 10),
              DonationContactDetailItem(Icons.home, user["address"]),
              Divider(color: header_item_color, height: 10),
              DonationContactDetailItem(Icons.phone, user["phoneNumber"]),
            ],
          );
        }

        return LoadingHeader();
      },
    );
  }
}

class DonationContactDetailItem extends StatelessWidget {
  final IconData icon;
  final String text;

  DonationContactDetailItem(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.centerLeft,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            GradientIcon(icon),
            SizedBox(width: 5),
            Text(
              text,
              style: style_header_item,
            )
          ]),
        ]));
  }
}

class DonationCardFoodTags extends StatelessWidget {
  final tags;

  DonationCardFoodTags(this.tags);

  @override
  Widget build(BuildContext context) {
    if (tags == null) return Container();
    var foodTags = <Widget>[];
    tags.forEach((element) => foodTags.add(Container(
        padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
        margin: EdgeInsets.fromLTRB(0, 0, 8, 0),
        decoration: BoxDecoration(
          border: Border.all(
            color: text_green,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          this.tags,
          style: style_donation_food_tag,
        ))));

    return Row(
      children: foodTags,
    );
  }
}

class DonationDetailItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final String content;
  final bool is_expiry;

  DonationDetailItem(this.icon, this.text, this.content, this.is_expiry);

  @override
  Widget build(BuildContext context) {
    var style_text =
        (is_expiry) ? style_donation_detail_expiry : style_donation_detail_text;
    var style_content = (is_expiry)
        ? style_donation_detail_expiry
        : style_donation_detail_content;

    var iconWidget =
        (is_expiry) ? Icon(icon, color: text_red) : GradientIcon(icon);

    return Align(
        alignment: Alignment.centerLeft,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            iconWidget,
            SizedBox(width: 5),
            Text(
              text,
              style: style_text,
            )
          ]),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              content,
              style: style_content,
              overflow: TextOverflow.ellipsis,
            ),
          )
        ]));
  }
}
