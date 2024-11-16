import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:number_to_words_english/number_to_words_english.dart';
//import 'package:share_plus/share_plus.dart';
import 'package:denomination/component/my_text.dart';
import 'package:denomination/database/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:vocsy_esys_flutter_share/vocsy_esys_flutter_share.dart';


class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {


  late Future<List<SummaryWithDenominations>> _summaryWithDenominations;

  @override
  void initState() {
    super.initState();
    _summaryWithDenominations = DatabaseHelper.instance.fetchSummaryWithDenominations();
  }

  shareFile(BuildContext context,SummaryWithDenominations sum) async {
    final summary = sum.summary;
    final denominations = sum.denominations;

    // String formattedDenominations = denominations.map((d) {
    //   return '₹ ${d.denomination} x ${d.count} = ₹ ${d.total}';
    // }).join('\n');

    String formattedDenominations = denominations
        .where((d) => d.total != 0) // Only include denominations with a non-zero total
        .map((d) {
      return '₹ ${d.denomination} x ${d.count} = ₹ ${d.total}';
    })
        .join('\n');

    int totalCount = denominations
        .where((d) => d.total != 0) // Filter out denominations with zero total
        .fold(0, (sum, d) => sum + d.count);

    String formattedText = '''
    
    
    
${summary.category}
Denomination
${formatDate(summary.date)} ${formatTime(summary.date)}
Test1
---------------------------------------
Rupee x Counts = Total
$formattedDenominations
---------------------------------------
Total Counts:
${totalCount}
Grand Total Amount:
₹ ${summary.grandTotal}
${NumberToWordsEnglish.convert(summary.grandTotal)} only/-
''';
    VocsyShare.text('my text title', formattedText, 'text/plain'
    );

  }

  void deleteFile(BuildContext context, int summaryId)async{
    try {
      await DatabaseHelper.instance.deleteSummaryWithDenominations(summaryId);

      // Refresh the data by assigning a new Future
      setState(() {
        _summaryWithDenominations = DatabaseHelper.instance.fetchSummaryWithDenominations();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete record: $e')),
      );
    }
  }

  editFile(BuildContext context,String id){
    Navigator.pop(context,id);
  }



  String formatDate(String dateString) {
    DateTime date = DateTime.parse(dateString); // Parse the input string to DateTime
    return DateFormat('dd-MMM-yyyy').format(date); // Format for date only
  }

  String formatTime(String dateString) {
    DateTime date = DateTime.parse(dateString);
    return DateFormat('hh:mm a').format(date);
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: MyText(title: 'History',color: Colors.white,),
            leading: InkWell(
                onTap: (){
                  Navigator.pop(context);
                },
                child: Icon(Icons.arrow_back,color: Colors.white,)),
          ),
          body: FutureBuilder<List<SummaryWithDenominations>>(
            future: _summaryWithDenominations,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No data available'));
              }

              final summaryWithDenominations = snapshot.data!;

              return ListView.separated(
                itemCount: summaryWithDenominations.length,
                itemBuilder: (context, index) {
                  final summaryWithDenom = summaryWithDenominations[index];
                  final summary = summaryWithDenom.summary;

                  return Slidable(
                      key: const ValueKey(0),

                  startActionPane: ActionPane(
                  motion: const ScrollMotion(),

                  children:  [
                    SlidableAction(
                  onPressed: (context){
                      deleteFile(context,summaryWithDenom.summary.id);
                  },
                  backgroundColor: Color(0xFFFE4A49),
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Delete',
                  ),
                    SlidableAction(
                  onPressed: (context){
                    shareFile(context, summaryWithDenom);
                  },
                  backgroundColor: Color(0xFF21B7CA),
                  foregroundColor: Colors.white,
                  icon: Icons.share,
                  label: 'Share',
                  ),
                    SlidableAction(
                      onPressed: (context){
                        editFile(context, summaryWithDenom.summary.id.toString());
                      },
                      backgroundColor: Color(0xD3011936),
                      foregroundColor: Colors.white,
                      icon: Icons.edit,
                      label: 'Edit',
                    ),
                  ],
                  ), child: Container(
                    margin: EdgeInsets.only(left: 8,right: 8),
                    padding: EdgeInsets.only(left: 8,right: 8,top: 8,bottom: 8),
                    decoration: BoxDecoration(
                        color: Color(0XFF16212A),
                        borderRadius: BorderRadius.circular(12)
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12,),
                        MyText(title: '${summary.category}',fontSize: 13,color: Colors.white,),
                        Row(

                          children: [
                            Expanded(
                                flex: 2,
                                child: MyText(title: '\u{20B9} ${summary.grandTotal}',fontSize: 21,color: Colors.blue,)),
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  MyText(title: '${formatDate(summary.date)}',fontSize: 11,color: Colors.grey,),
                                  MyText(title: '${formatTime(summary.date)}',fontSize: 11,color: Colors.grey,)
                                ],
                              ),
                            ),

                          ],
                        ),
                        MyText(title: summary.description,fontSize: 13,color: Colors.white,),
                        const SizedBox(height: 12,),
                      ],
                    ),
                  ),
                  );
                },
                separatorBuilder: (context,index){
                  return SizedBox(height: 12,);
                },
              );
            },
          ),
        )
    );
  }
}

/*
Container(
              margin: EdgeInsets.only(left: 8,right: 8),
              padding: EdgeInsets.only(left: 8,right: 8,top: 8,bottom: 8),
              decoration: BoxDecoration(
                color: Color(0XFF16212A),
                borderRadius: BorderRadius.circular(12)
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12,),
                  MyText(title: 'General',fontSize: 13,color: Colors.white,),
                  Row(

                    children: [
                      Expanded(
                          flex: 2,
                          child: MyText(title: '\u{20B9} 2000',fontSize: 21,color: Colors.blue,)),
                      Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              MyText(title: 'Nov 16,2024',fontSize: 11,color: Colors.grey,),
                              MyText(title: '5:00 Pm',fontSize: 11,color: Colors.grey,)
                            ],
                          ),
                      ),

                    ],
                  ),
                  MyText(title: 'Remark 1',fontSize: 13,color: Colors.white,),
                  const SizedBox(height: 12,),
                ],
              ),
            )
 */
