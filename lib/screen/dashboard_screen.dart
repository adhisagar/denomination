import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:number_to_words_english/number_to_words_english.dart';
import 'package:denomination/component/helper.dart';
import 'package:denomination/component/my_text.dart';
import 'package:denomination/database/database_helper.dart';
import 'package:denomination/screen/history_Screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Controllers for denominations
  final List<TextEditingController> controllers = List.generate(10, (_) => TextEditingController());

  // Denominations for currency notes
  final List<int> denominations = [2000, 500, 200, 100, 50,20,10,5,2,1];

  // Map to track amounts per denomination
  final Map<int, int> amounts = {};

  // Total amount
  int totalAmount = 0;

  // Fetched Items Id
  int fetchedId=0;

  // Dropdown values
  String selectedCategory = "General";
  List<DropdownMenuItem<String>> get dropdownItems{
    List<DropdownMenuItem<String>> menuItems = [
      DropdownMenuItem(child: Text("General"),value: "General"),
      DropdownMenuItem(child: Text("Income"),value: "Income"),
      DropdownMenuItem(child: Text("Expense"),value: "Expense"),
    ];
    return menuItems;
  }
  TextEditingController remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize amounts with 0 for each denomination
    denominations.forEach((denom) => amounts[denom] = 0);
  }

  // Update the amount for a specific denomination
  void _updateAmount(int index, String value) {
    setState(() {
      int count = int.tryParse(value) ?? 0;
      amounts[denominations[index]] = count * denominations[index];
      _updateTotalAmount();
    });
  }

  // Calculate the total amount
  void _updateTotalAmount() {
    totalAmount = amounts.values.fold(0, (sum, element) => sum + element);
    print(totalAmount);
  }

  // Build the dynamic denominations list
  List<Map<String, dynamic>> _buildDenominations() {
    return List.generate(controllers.length, (index) {
      String countText = controllers[index].text;
      if (countText.isEmpty) return null;
      int count = int.tryParse(countText) ?? 0;
      return {
        'denomination': '₹ ${denominations[index]}',
        'count': count,
        'total': count * denominations[index],
      };
    }).whereType<Map<String, dynamic>>().toList(); // Filter out null entries
  }

  // Save data to the database
  Future<void> saveData() async {
    List<Denomination> denominationList = _buildDenominations().map((denom) {
      return Denomination(
        id: 0,
        denomination: denom['denomination'],
        count: denom['count'],
        total: denom['total'],
        summaryId: 0,
      );
    }).toList();

    try {
      await _dbHelper.insertSummaryAndDenominations(
        date: DateTime.now().toString(),
        description: remarksController.text,
        totalCounts: denominationList.length,
        grandTotal: totalAmount,
        category: selectedCategory,
        denominations: denominationList,
      );

      clearScreen();
      print("Data Saved Successfully!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data Saved Successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to Save Data: $e')),
      );
    }
  }

  // Update data to the database
  Future<void> updateData(int id) async {
    List<Denomination> denominationList = _buildDenominations().map((denom) {
      return Denomination(
        id: 0,
        denomination: denom['denomination'],
        count: denom['count'],
        total: denom['total'],
        summaryId: 0,
      );
    }).toList();

    try {
      await _dbHelper.updateSummaryAndDenominations(
        summaryId: id,
        date: DateTime.now().toString(),
        description: remarksController.text,
        totalCounts: denominationList.length,
        grandTotal: totalAmount,
        category: selectedCategory,
        denominations: denominationList,
      );

      print("Data Updated Successfully!  ${remarksController.text}");

      clearScreen();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data Updated Successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to Update Data: $e')),
      );
    }
  }

  // Clear data in screen
  void clearScreen(){
    setState(() {
      for (var controller in controllers) {
        controller.clear();
      }

      // Reset all amounts
      amounts.clear();

      totalAmount = 0;
      fetchedId=0;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        type: ExpandableFabType.up,
        childrenAnimation: ExpandableFabAnimation.rotate,
        distance: 60,
        openButtonBuilder: DefaultFloatingActionButtonBuilder(
          child: SizedBox(
            height: 18,
            child: Image.asset('assets/icons/flash.png',color: Colors.white,),),
          fabSize: ExpandableFabSize.regular,
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue,
          shape: const CircleBorder(),
        ),
        closeButtonBuilder: DefaultFloatingActionButtonBuilder(
          child: SizedBox(
            height: 18,
            child: Image.asset('assets/icons/flash.png',color: Colors.white,),),
          fabSize: ExpandableFabSize.regular,
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue,
          shape: const CircleBorder(),
        ),
        overlayStyle: ExpandableFabOverlayStyle(
          color: Colors.black.withOpacity(0.1),

        ),
        children:  [
          InkWell(
            onTap: (){
              setState(() {

                clearScreen();
                Helper().showToast(context, 'Data Cleared Successfully!');
              });
            },
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8,vertical: 4),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      color: Colors.grey
                  ),
                  child: MyText(title: 'Clear',color: Colors.white,),
                ),
                SizedBox(width: 20),
                Container(
                  height: 40,
                  width: 50,
                  padding: EdgeInsets.symmetric(vertical: 8,horizontal: 12),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey
                  ),
                  child: Image.asset('assets/icons/cancel.png',color: Colors.white,),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: (){
              saveDialog(context);
            },
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8,vertical: 4),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      color: Colors.grey
                  ),
                  child: MyText(title: 'Save',color: Colors.white,),
                ),
                SizedBox(width: 20),
                Container(
                  height: 40,
                  width: 50,
                  padding: EdgeInsets.symmetric(vertical: 8,horizontal: 12),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey
                  ),
                  child: Image.asset('assets/icons/download_icon.png',color: Colors.white,),
                ),
              ],
            ),
          ),

        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              collapsedHeight: 100,
              backgroundColor: Colors.black,
              actions: [

                InkWell(
                  onTap: (){
                    _showPopupMenu(context);
                  },
                  child: Container(
                      margin: EdgeInsets.only(top: 24, right: 12),
                      child: Icon(Icons.more_vert,color: Colors.white,)),
                )

              ],
              flexibleSpace: FlexibleSpaceBar(
                  titlePadding:
                  EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  title: totalAmount == 1
                      ? MyText(
                    title: 'Denomination',
                    fontSize: 21,
                    color: Colors.white,
                  )
                      : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        title: 'Total Amount',
                        fontSize: 15,
                        color: Colors.white,
                      ),
                      MyText(
                        title: '\u{20B9} ${totalAmount}',
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      MyText(
                        title:
                        '${NumberToWordsEnglish.convert(totalAmount)} only/-',
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  background: Image.asset(
                    "assets/images/currency_banner.jpg",
                    fit: BoxFit.cover,
                  )),
            ),

          ];
        },
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: denominations.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: _buildRow(index),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }



  Widget _buildRow(int index) {
    return Row(
      children: [
        Icon(Icons.currency_rupee, color: Colors.white),
        const SizedBox(width: 8),
        SizedBox(
            width: 40,
            child: MyText(title: denominations[index].toString(), fontSize: 15, color: Colors.white)),
        const SizedBox(width: 8),
        MyText(title: 'X', fontSize: 15, color: Colors.white),
        const SizedBox(width: 8),
        Container(
          height: 60,
          width: 120,
          margin: EdgeInsets.only(left: 12,right: 12),
          padding: EdgeInsets.only(left: 16,right: 8,),
          decoration: BoxDecoration(
              color: Color(0xFF39424b),
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(7)
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: TextStyle(color: Colors.white),
                  controller: controllers[index],
                  onChanged: (value) => _updateAmount(index, value),
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'^[1-9][0-9]*$')),
                  ],
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '',
                    labelStyle: TextStyle(color: Colors.white),


                  ),
                ),
              ),
              InkWell(
                onTap: (){
                  controllers[index].clear();
                  amounts[index]=0;
                  _updateAmount(index, "0");
                },
                child: const Icon(Icons.cancel,color: Colors.white,),
              ),
            ],
          ),
        ),


        const SizedBox(width: 8),
        Expanded(
          child: MyText(
            title: "= ₹ ${amounts[denominations[index]] ?? 0}",
            fontSize: 15,
            color: Colors.white,
            isOverflow: 1,
          ),
        ),
      ],
    );
  }


  saveDialog(BuildContext context){
    return showDialog(
        context: context,
        builder: (context){
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.all(12),
            child: StatefulBuilder(
              builder: (context,setState){
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    color: Colors.black.withOpacity(1),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16,),
                      Container(
                        margin: EdgeInsets.only(right: 12),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                              onTap: (){
                                Navigator.pop(context);
                              },
                              child: Icon(Icons.cancel_outlined,size: 24,color: Colors.red,)),
                        ),
                      ),
                      const SizedBox(height: 16,),
                      DropdownButtonFormField(
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.blue, width: 1),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.blue, width: 2),
                                borderRadius: BorderRadius.circular(7),
                              ),

                              filled: true,
                              fillColor: Color(0XFF39424B),
                              labelText: 'Category',
                              labelStyle: TextStyle(color: Colors.white)

                          ),
                          validator: (value) => value == null ? "Category" : null,
                          dropdownColor: Colors.white,
                          value: selectedCategory,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCategory = newValue!;
                            });
                          },
                          items: dropdownItems),
                      const SizedBox(height: 16,),
                      TextField(
                        controller: remarksController,
                        style: TextStyle(color: Colors.white),
                        maxLines: 2,
                        maxLength: 40,
                        decoration: InputDecoration(
                          hintText: 'Fill your Remarks(if any)',
                          hintStyle: TextStyle(color: Colors.grey,fontSize: 12),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue, width: 1),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue, width: 2),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue), // Border when typing
                          ),
                          filled: true,
                          fillColor: Color(0XFF39424B),
                        ),
                      ),
                      const SizedBox(height: 16,),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            elevation: 6,

                          ),
                          onPressed: (){
                            confirmationDialog(context);
                          },
                          child: MyText(title: 'Submit',color: Colors.white,)
                      ),
                      const SizedBox(height: 16,),

                    ],
                  ),
                );
              },
            ),
          );
        }
    );
  }



  confirmationDialog(BuildContext context,)async{
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context){
        return AlertDialog(
          backgroundColor: Colors.black,
          surfaceTintColor: Colors.transparent,
          actionsAlignment: MainAxisAlignment.end,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(title: 'Are You sure?',fontWeight: FontWeight.w300,color: Colors.white,fontSize: 18,)

            ],
          ),
          title: MyText(title: 'Confirmation',fontWeight: FontWeight.w800,color: Colors.blue,fontSize: 13,),
          actions: [

            GestureDetector(
              onTap: (){

                Navigator.pop(context);

              },
              child: Container(
                padding: EdgeInsets.only(left: 16,right: 16,top: 8,bottom: 8),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.blueGrey
                ),
                child: MyText(title: 'No',color: Colors.white,),
              ),
            ),
            GestureDetector(
              onTap: ()async{
                if(fetchedId == 0){
                  await saveData();
                }else{
                  await updateData(fetchedId);
                }

                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Container(
                padding: EdgeInsets.only(left: 16,right: 16,top: 8,bottom: 8),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white
                ),
                child: MyText(title: 'Yes',color: Colors.blue,),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPopupMenu(BuildContext context) async {
    await showMenu(
      context: context,
      color: Colors.black,
      position: RelativeRect.fromLTRB(100, 40, 0, 0), // Position the popup
      items: [
        PopupMenuItem(
          value: 1,
          child: Row(children: [
            SizedBox(height: 24,width: 24,child: Image.asset('assets/icons/history.png',color: Colors.white,),),
            const SizedBox(width: 4,),
            MyText(title: 'History',color: Colors.white,)
          ],),
          onTap: (){
            _navigateAndDisplaySelection(context);
          },
        ),
      ],
      elevation: 8.0,
    ).then((value) {
      if (value != null) {
        print("Selected Option: $value");
      }
    });
  }

  Future<void> _navigateAndDisplaySelection(BuildContext context) async {

    final result = await Navigator.push(
      context,MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );

    if (!context.mounted) return;
    if(result.toString().isNotEmpty && result !=null){
      fetchedId=int.parse(result.toString());
      fetchDataAndSetUI(int.parse(result.toString()));
    }
  }



  Future<void> fetchDataAndSetUI(int summaryId) async {
    final summaryWithDenominations = await _dbHelper.fetchSummaryWithDenominationsById(summaryId);

    if (summaryWithDenominations != null) {
      setState(() {
        // Set selected category
        selectedCategory = summaryWithDenominations.summary.category;

        // Set remarks
        remarksController.text = summaryWithDenominations.summary.description;

        // Reset amounts and controllers
        amounts.clear();
        for (int i = 0; i < denominations.length; i++) {
          final denomination = summaryWithDenominations.denominations.firstWhere(
                  (denom) => denom.denomination == '₹ ${denominations[i]}',
              orElse: () => Denomination(
                id: 0,
                denomination: '₹ ${denominations[i]}',
                count: 0,
                total: 0,
                summaryId: 0,
              ));

          if (denomination != null) {
            controllers[i].text = denomination.count.toString();
            amounts[denominations[i]] = denomination.count * denominations[i];
          } else {
            controllers[i].clear();
            amounts[denominations[i]] = 0;
          }
        }

        // Calculate the total amount again after setting values
        _updateTotalAmount();
      });
    } else {
      print('No summary found with the provided id.');
    }
  }


}


