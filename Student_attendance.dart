import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudentAttendance extends StatefulWidget {
  final String studentId;

  const StudentAttendance({super.key, required this.studentId});

  @override
  State<StudentAttendance> createState() => _StudentAttendanceState();
}

class _StudentAttendanceState extends State<StudentAttendance> {
  List<Map<String, dynamic>> attendanceList = [];
  double presentCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAttendance();
  }

  Future<void> fetchAttendance() async {
    setState(() {
      isLoading = true;
      presentCount = 0;
    });

    final now = DateTime.now();
    final pastDate = DateTime(now.year, now.month - 5, now.day);

    final snapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .doc(widget.studentId)
        .collection('records')
        .orderBy('date', descending: true)
        .get();

    List<Map<String, dynamic>> tempList = [];

    for (var doc in snapshot.docs) {
      DateTime entryDate = (doc['date'] as Timestamp).toDate();
      if (entryDate.isAfter(pastDate)) {
        tempList.add({
          'date': entryDate,
          'status': doc['status'],
        });

        if (doc['status'] == 'Present') {
          presentCount++;
        }
      }
    }

    setState(() {
      attendanceList = tempList;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double percentage = attendanceList.isNotEmpty
        ? (presentCount / attendanceList.length) * 100
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: fetchAttendance, // 🔄 Reload data
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : attendanceList.isEmpty
          ? const Center(
        child: Text(
          'No attendance records found for the last 6 months.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              "Attendance (Last 6 Months)",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: attendanceList.length,
              itemBuilder: (context, index) {
                final entry = attendanceList[index];
                return ListTile(
                  leading: Icon(
                    entry['status'] == 'Present'
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: entry['status'] == 'Present'
                        ? Colors.green
                        : Colors.red,
                  ),
                  title: Text(
                      DateFormat('yyyy-MM-dd').format(entry['date'])),
                  trailing: Text(entry['status']),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              "Attendance Percentage: ${percentage.toStringAsFixed(1)}%",
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
