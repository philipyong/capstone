import 'package:capstone/controller/firestore_controller.dart';
import 'package:capstone/model/constants.dart';
import 'package:capstone/viewpage/view/kirby_loading.dart';
import 'package:chart_components/chart_components.dart';
import 'package:flutter/material.dart';

import '../controller/auth_controller.dart';
import '../model/history_screen_model.dart';

class HistoryScreen extends StatefulWidget {
  static const routeName = "/history";
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _HistoryState();
  }
}

class _HistoryState extends State<HistoryScreen> {
  late _Controller con;
  late HistoryScreenModel screenModel;
  String title = "History";

  @override
  void initState() {
    super.initState();
    con = _Controller(this);
    screenModel = HistoryScreenModel(user: Auth.user!);
    con.getKirbyUser();
    con.initScreen();
  }

  void render(fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weekly Stats"),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[700]!, Colors.deepOrange],
            ),
          ),
        ),
      ),
      body: screenModel.loading
          ? const Center(
              child: KirbyLoading(),
            )
          : historyScreenBody(),
    );
  }

  Widget historyScreenBody() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.55,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.only(bottom: 20, left: 8, right: 8, top: 20),
              child: BarChart(
                data: screenModel.completionRatings,
                labels: screenModel.getDays(),
                displayValue: true,
                reverse: true,
                getColor: con.getColor,
                getIcon: con.getIcon,
                barWidth: 38,
                barSeparation: 12,
                animationDuration: const Duration(milliseconds: 1800),
                animationCurve: Curves.easeInOutSine,
                itemRadius: 30,
                iconHeight: 24,
                footerHeight: 24,
                headerValueHeight: 16,
                roundValuesOnText: false,
                lineGridColor: Colors.lightBlue,
              ),
            ),
            const Text('Percentage of tasks completed in the last 7 days.'),
          ],
        ),
      ),
    );
  }
}

class _Controller {
  _HistoryState state;
  _Controller(this.state);

  void initScreen() async {
    state.screenModel.loading = true;
    await state.screenModel.setCompletionRatings();
    state.render(() {});

    state.screenModel.loading = false;
  }

  // gets user info
  Future<void> getKirbyUser() async {
    try {
      state.screenModel.loading = true;
      state.screenModel.kirbyUser =
          await FirestoreController.getKirbyUser(userId: Auth.getUser().uid);
      state.render(() {});
    } catch (e) {
      // ignore: avoid_print
      if (Constants.devMode) print(" ==== loading error $e");
      state.render(() => state.screenModel.loadingErrorMessage = "$e");
    }
    state.screenModel.loading = false;
  }

  // assigns color of bars
  Color getColor(double value) {
    if (value < 2) {
      return Colors.amber.shade300;
    } else if (value < 4) {
      return Colors.amber.shade600;
    } else {
      return Colors.amber.shade900;
    }
  }

  // returns star fill grades
  Icon getIcon(double value) {
    if (value < 1) {
      return Icon(
        Icons.star_border,
        size: 24,
        color: getColor(value),
      );
    } else if (value < 5) {
      return Icon(
        Icons.star_half,
        size: 24,
        color: getColor(value),
      );
    } else {
      return Icon(
        Icons.star,
        size: 24,
        color: getColor(value),
      );
    }
  }
}
