import 'package:capstone/controller/firestore_controller.dart';
import 'package:capstone/model/constants.dart';
import 'package:capstone/model/kirby_task_model.dart';
import 'package:capstone/model/todo_screen_model.dart';
import 'package:capstone/viewpage/todo_item.dart';
import 'package:capstone/viewpage/view/kirby_loading.dart';
import 'package:capstone/viewpage/view/view_util.dart';
import 'package:flutter/material.dart';

import '../controller/auth_controller.dart';
import 'history_screen.dart';
import 'home_screen.dart';

enum DurationLabel {
  none('None', 0),
  daily('Daily', 1),
  weekly('Weekly', 7),
  monthly('Monthly', 30);

  const DurationLabel(this.label, this.duration);
  final String label;
  final int duration;
}

class ToDoScreen extends StatefulWidget {
  static const routeName = '/todoScreen';

  const ToDoScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ToDoScreenState();
  }
}

class _ToDoScreenState extends State<ToDoScreen> {
  late _Controller con;
  DateTime? datePicked;
  TimeOfDay? timePicked;
  var formKey = GlobalKey<FormState>();
  late TodoScreenModel screenModel;

  void render(fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    con = _Controller(this);
    screenModel = TodoScreenModel(user: Auth.getUser());
    con.initScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple[300],
        title: const Text('To Do List'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, HomeScreen.routeName);
          },
        ), // override WillPopScope() from home_screen.dart so home_screen can update completed tasks
        actions: [
          IconButton(
            onPressed: con.historyScreen,
            icon: const Icon(Icons.assessment_outlined),
            tooltip: 'Weekly Stats',
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.purple[200]!],
            ),
          ),
        ),
      ),
      floatingActionButton: addTaskButton(),
      body: screenModel.loading
          ? const Center(
              child: KirbyLoading(),
            )
          : body(),
    );
  }

  Widget addTaskButton() {
    return FloatingActionButton(
      onPressed: bottomSheet,
      backgroundColor: Colors.purple[200],
      elevation: 10,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      child: const Text(
        '+',
        style: TextStyle(
          fontSize: 32,
        ),
      ),
    );
  }

  void bottomSheet({e = false, KirbyTask? t}) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Form(
          key: formKey,
          child: Padding(
            padding: EdgeInsets.only(
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SizedBox(
              height: 430,
              child: addTaskBody(e: e, t: t),
            ),
          ),
        );
      },
      isScrollControlled: true,
    );
  }

  Widget addTaskBody({e = false, KirbyTask? t}) {
    return Stack(
      children: [
        Column(
          children: [
            Text(
              e ? 'Edit Task' : 'Add a New Task',
              style: TextStyle(
                  fontSize: 30,
                  color: Colors.purple[300],
                  fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: addTaskInputs(e: e, t: t),
            ),
          ],
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: OutlinedButton(
                  onPressed: () {
                    con.datePickedController.clear();
                    con.timePickedController.clear();
                    screenModel.tempTask = KirbyTask(
                      userId: screenModel.user.uid,
                      isCompleted: false,
                      isReoccuring: false,
                    );
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.purple[200]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 30, 20),
                child: ElevatedButton(
                  onPressed: () => con.save(e: e),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[200],
                    elevation: 5,
                  ),
                  child: Text(
                    e ? "Edit Task" : 'Add New Task',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget addTaskInputs({e = false, KirbyTask? t}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            // ignore: prefer_const_literals_to_create_immutables
            boxShadow: [
              const BoxShadow(
                color: Colors.grey,
                offset: Offset(0.0, 0.0),
                blurRadius: 5.0,
                spreadRadius: 0.0,
              ),
            ],
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            initialValue: e ? t!.title : "",
            decoration: const InputDecoration(
              hintText: "Task Name...",
              border: InputBorder.none,
            ),
            validator: KirbyTask.validateTaskName,
            onSaved: screenModel.saveTaskName,
          ),
        ),
        Row(
          children: [
            addTaskDateInput(e: e, t: t),
            addTaskTimeInput(e: e, t: t),
          ],
        ),
        addReoccuringInfo(e: e, t: t),
      ],
    );
  }

  Widget addReoccuringInfo({e = false, KirbyTask? t}) {
    final durationEntries = <DropdownMenuEntry<DurationLabel>>[];
    for (final DurationLabel duration in DurationLabel.values) {
      durationEntries.add(
        DropdownMenuEntry<DurationLabel>(
          value: duration,
          label: duration.label,
          enabled: duration.label != 'None',
        ),
      );
    }
    var durationController = TextEditingController();

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: StatefulBuilder(
        builder: (context, setInnerState) => Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 15, 20, 0),
              child: Container(
                width: 170,
                decoration: BoxDecoration(
                  color: Colors.white,
                  // ignore: prefer_const_literals_to_create_immutables
                  boxShadow: [
                    const BoxShadow(
                      color: Colors.grey,
                      offset: Offset(0.0, 0.0),
                      blurRadius: 5.0,
                      spreadRadius: 0.0,
                    ),
                  ],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: e
                    ? CheckboxListTile(
                        title: const Text("Reoccuring"),
                        value: t!.isReoccuring,
                        onChanged: (newValue) {
                          setInnerState(() {
                            t.isReoccuring = newValue;
                          });
                        },
                      )
                    : CheckboxListTile(
                        title: const Text("Reoccuring"),
                        value: screenModel.tempTask.isReoccuring,
                        onChanged: (newValue) {
                          setInnerState(() {
                            screenModel.tempTask.isReoccuring = newValue;
                          });
                        },
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: SizedBox(
                width: 130,
                child: DropdownMenu<DurationLabel>(
                  initialSelection: screenModel.tempTask.isReoccuring!
                      ? getDurationEnum(
                          screenModel.tempTask.reocurringDuration ??= 1)
                      : DurationLabel.none,
                  controller: durationController,
                  enabled: screenModel.tempTask.isReoccuring!,
                  textStyle: TextStyle(
                    color: screenModel.tempTask.isReoccuring!
                        ? Colors.black
                        : Colors.grey,
                  ),
                  dropdownMenuEntries: durationEntries,
                  label: const Text('Duration'),
                  onSelected: (DurationLabel? duration) {
                    setInnerState(() {
                      screenModel.tempTask.reocurringDuration =
                          duration!.duration;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DurationLabel getDurationEnum(int d) {
    for (DurationLabel durartion in DurationLabel.values) {
      if (durartion.duration == d) {
        return durartion;
      }
    }
    return DurationLabel.none;
  }

  Widget addTaskDateInput({e = false, KirbyTask? t}) {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
        child: Container(
          width: 150,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.grey,
                offset: Offset(0.0, 0.0),
                blurRadius: 5.0,
                spreadRadius: 0.0,
              ),
            ],
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            decoration: const InputDecoration(
              hintText: "Task Date...",
              border: InputBorder.none,
            ),
            controller: con.datePickedController,
            validator: KirbyTask.validateDatePicked,
            onSaved: screenModel.saveDatePicked,
            onTap: () async {
              datePicked = await showDatePicker(
                context: context,
                initialDate: e ? getDueDate(t) : DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(3000),
              );
              setState(() {
                if (datePicked != null) {
                  con.datePickedController.text =
                      '${datePicked!.month}/${datePicked!.day}/${datePicked!.year}';
                }
              });
            },
          ),
        ),
      ),
    );
  }

  DateTime getDueDate(KirbyTask? t) {
    if (t?.dueDate == null) {
      return DateTime(0000, 0, 0);
    }

    return DateTime(t!.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
  }

  Widget addTaskTimeInput({e = false, KirbyTask? t}) {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 15, 0, 0),
        child: Container(
          width: 150,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.grey,
                offset: Offset(0.0, 0.0),
                blurRadius: 5.0,
                spreadRadius: 0.0,
              ),
            ],
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            decoration: const InputDecoration(
              hintText: "Task Time...",
              border: InputBorder.none,
            ),
            controller: con.timePickedController,
            validator: KirbyTask.validateTimePicked,
            onSaved: screenModel.saveTimePicked,
            onTap: () async {
              timePicked = await showTimePicker(
                context: context,
                initialTime: e ? getDueTime(t) : TimeOfDay.now(),
              );
              setState(() {
                if (timePicked != null) {
                  con.timePickedController.text =
                      "${(timePicked!.hour) < 10 ? '0${timePicked!.hour}' : timePicked!.hour}:${(timePicked!.minute < 10) ? '0${timePicked!.minute}' : timePicked!.minute}";
                }
              });
            },
          ),
        ),
      ),
    );
  }

  TimeOfDay getDueTime(KirbyTask? t) {
    if (t?.dueDate == null ||
        t!.dueDate?.hour == null ||
        t.dueDate?.minute == null) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
    return TimeOfDay(hour: t.dueDate!.hour, minute: t.dueDate!.minute);
  }

  Widget body() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: con.searchController,
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Icon(
                      Icons.search,
                      size: 30,
                      color: Colors.deepPurple,
                    ),
                  ),
                  suffixIcon: con.searchController.text.isNotEmpty ||
                          screenModel.tempTaskList != null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          child: IconButton(
                            onPressed: con.clearSearchBox,
                            icon: const Icon(Icons.close),
                          ),
                        )
                      : const SizedBox.shrink(),
                  contentPadding: const EdgeInsets.all(25), // padding needed
                  prefixIconConstraints: const BoxConstraints(
                    maxHeight: 50,
                    minWidth: 25,
                  ),
                  border: InputBorder.none,
                  hintText: 'Search Keywords',
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                onEditingComplete: con.submitSearch,
                onChanged: (hello) {
                  render(() {});
                },
              ),
            ),
            screenModel.taskList.isEmpty 
              ? emptyTaskList()
              : screenModel.tempTaskList != null &&
                        screenModel.tempTaskList!.isEmpty
                ? noSearchResults()
                : tasks()
          ],
        ),
      ),
    );
  }

  Widget emptyTaskList() {
    return Center(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 75, bottom: 40),
            child: SizedBox(
              height: 200,
              child: Image.asset('images/kirby-happy-jumping.png'),
            ),
          ),
          const Text(
            'All Tasks Completed!\nGreat Job!',
            style: TextStyle(
              fontSize: 30,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget noSearchResults() {
    return Center(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 75, bottom: 40),
            child: SizedBox(
              height: 200,
              child: Image.asset('images/disappointed-kirby.png'),
            ),
          ),
          const Text(
            'No search results!',
            style: TextStyle(
              fontSize: 30,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget tasks() {
    return Column(
      children: [
        SizedBox(
          height: 500,
          child: ListView(
            //shrinkWrap: true,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 50,
                  bottom: 20,
                ),
                child: const Text(
                  'All Tasks',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              screenModel.tempTaskList != null &&
                      screenModel.tempTaskList!.isNotEmpty
                  ? Column(
                      children: [
                        for (var t in screenModel.tempTaskList!)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ToDoItem(
                              task: t,
                              taskIndex: screenModel.tempTaskList!.indexOf(t),
                              deleteFn: con.deleteTask,
                              editFn: con.editTask,
                            ),
                          ),
                      ],
                    )
                  : Column(
                      children: [
                        for (var t in screenModel.taskList)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ToDoItem(
                              task: t,
                              taskIndex: screenModel.taskList.indexOf(t),
                              deleteFn: con.deleteTask,
                              editFn: con.editTask,
                            ),
                          ),
                      ],
                    )
            ],
          ),
        ),
      ],
    );
  }
}

class _Controller {
  _ToDoScreenState state;
  _Controller(this.state);

  //Used to edit the text on the textformfields
  var datePickedController = TextEditingController();
  var timePickedController = TextEditingController();
  var searchController = TextEditingController();

  Future<void> save({e = false}) async {
    // added this so the keyboard is retracted
    FocusManager.instance.primaryFocus?.unfocus();

    FormState? currentSate = state.formKey.currentState;
    if (currentSate == null || !currentSate.validate()) {
      return;
    }
    try {
      currentSate.save();

      if (e) {
        if (state.screenModel.tempTask.dueDate!.compareTo(DateTime.now()) > 0) {
          state.screenModel.tempTask.isPastDue = false;
        }
        Map<String, dynamic> update = {
          DocKeyKirbyTask.userId.name: state.screenModel.tempTask.userId,
          DocKeyKirbyTask.title.name: state.screenModel.tempTask.title,
          DocKeyKirbyTask.dueDate.name: state.screenModel.tempTask.dueDate,
          DocKeyKirbyTask.isCompleted.name:
              state.screenModel.tempTask.isCompleted,
          DocKeyKirbyTask.isPreloaded.name:
              state.screenModel.tempTask.isPreloaded,
          DocKeyKirbyTask.isReoccuring.name:
              state.screenModel.tempTask.isReoccuring,
          DocKeyKirbyTask.isPastDue.name: state.screenModel.tempTask.isPastDue,
          DocKeyKirbyTask.completeDate.name:
              state.screenModel.tempTask.completeDate,
          DocKeyKirbyTask.reocurringDuration.name:
              state.screenModel.tempTask.reocurringDuration,
        };
        // state.screenModel.tempTask.dueDate =
        await FirestoreController.updateKirbyTask(
          taskId: state.screenModel.tempTask.taskId!,
          update: update,
        );
      } else {
        String docId = await FirestoreController.addKirbyTask(
          kirbyTask: state.screenModel.tempTask,
        );
        state.screenModel.tempTask.taskId = docId;
        state.screenModel.taskList.add(state.screenModel.tempTask);
      }

      state.screenModel.tempTask = KirbyTask(
        userId: Auth.getUser().uid,
        isCompleted: false,
        completeDate: null,
        isReoccuring: false,
        isPastDue: false,
      );

      datePickedController.clear();
      timePickedController.clear();
      if (!state.mounted) return;
      Navigator.pop(state.context);
      showSnackBar(
        context: state.context,
        seconds: 3,
        message: e ? 'Task Editted' : 'Task Added!',
      );

      state.render(() {});
    } catch (e) {
      showSnackBar(
        context: state.context,
        message: "Something went wrong...\nTry again!",
      );
      // ignore: avoid_print
      print("======== upload task error: $e");
    }
  }

  void initScreen() async {
    state.screenModel.loading = true;
    await loadKirbyUser();
    getTaskList();
    state.screenModel.loading = false;
  }

  // gets all tasks from user & creates preloaded tasks if they are enabled & if
  // they were not already created
  void getTaskList() async {
    if (state.screenModel.kirbyUser!.preloadedTasks!) {
      var results = await FirestoreController.getPreloadedTaskList(
        uid: Auth.getUser().uid,
      );
      if (results.isEmpty) {
        // make new preloaded tasks
        state.screenModel.taskList =
            await state.screenModel.addPreloadedTasks();
      } else {
        // update preloaded tasks
        await state.screenModel.updateDrinkTask();
        await state.screenModel.updateSleepTask();
        await state.screenModel.updateEatTask();

        // fetch updated preloaded tasks
        results = await FirestoreController.getPreloadedTaskList(
          uid: Auth.getUser().uid,
        );
        state.screenModel.taskList = results;
      }
    }

    var results = await FirestoreController.getKirbyTaskList(
      uid: Auth.getUser().uid,
    );
    for (var result in results) {
      result.isPreloaded ??= false;
      if (!result.isPreloaded! && !result.isCompleted) state.screenModel.taskList.add(result);
    }
    state.render(() {});
  }

  Future<void> loadKirbyUser() async {
    try {
      state.screenModel.kirbyUser =
          await FirestoreController.getKirbyUser(userId: Auth.getUser().uid);
      state.render(() {});
    } catch (e) {
      // ignore: avoid_print
      if (Constants.devMode) print(" ==== loading error $e");
      state.render(() => state.screenModel.loadingErrorMessage = "$e");
    }
  }

  void deleteTask(String taskId) async {
    /*  Eli
      - the function takes in the taskId and removes it from the taskList and 
        from the database
  */
    try {
      await FirestoreController.deleteKirbyTask(taskId: taskId);
      if (!state.mounted) return;
      showSnackBar(
        context: state.context,
        message: "Deleted Task",
      );
      state.screenModel.taskList.removeWhere((task) => task.taskId == taskId);
    } catch (e) {
      if (Constants.devMode) {
        // ignore: avoid_print
        print("===== Delete task error: $e");
      }
      showSnackBar(
        context: state.context,
        message: "Something went wrong...\n Try again!",
      );
    }
    state.render(() {});
  }

  void editTask(String taskId) async {
    /*  Eli
      - the task takes in the task id and retrieves the task information from 
        the database
      - it is then passed into the bottomSheet function which edits the 
        information
      - then the original task is deleted from the database and the taskList 
        and the new version added to both 
  */
    try {
      state.screenModel.tempTask =
          await FirestoreController.getKirbyTask(taskId: taskId);
      state.bottomSheet(e: true, t: state.screenModel.tempTask);
      state.screenModel.taskList.removeWhere((task) => task.taskId == taskId);
      state.screenModel.taskList.add(state.screenModel.tempTask);
    } catch (e) {
      if (Constants.devMode) {
        // ignore: avoid_print
        print("===== Edit task error: $e");
      }
      showSnackBar(
        context: state.context,
        message: "Something went wrong...\n Try again!",
      );
    }
    state.render(() {});
  }

  void submitSearch() {
    FocusManager.instance.primaryFocus?.unfocus();

    if (searchController.text.isEmpty) {
      return clearSearchBox();
    }

    state.screenModel.tempTaskList = [];
    for (var i = 0; i < state.screenModel.taskList.length; i++) {
      if (state.screenModel.taskList[i].title!
          .contains(searchController.text)) {
        var tempTask = state.screenModel.taskList[i];
        state.screenModel.tempTaskList!.add(tempTask);
      }
    }
    state.render(() {});
  }

  void clearSearchBox() async {
    FocusManager.instance.primaryFocus?.unfocus();
    searchController.text = "";
    state.screenModel.tempTaskList = null;
    state.render(() {});
  }

    void historyScreen() async {
    await Navigator.pushNamed(state.context, HistoryScreen.routeName);
  }
}
