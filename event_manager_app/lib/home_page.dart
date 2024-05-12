import 'package:event_manager_app/event_detail_page.dart';
import 'package:event_manager_app/new_event.dart';
import  'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class Event {
  String title;
  String desctiption;
  bool completed;
  DateTime startDate;
  DateTime endDate;
  TimeOfDay startHour;
  int expectedParticipants;
  int actualParticipants;
  String img;
  

  Event({
    required this.title,
    required this.desctiption,
    required this.completed,
    required this.startDate,
    required this.endDate,
    required this.startHour,
    required this.expectedParticipants,
    required this.actualParticipants,
    required this.img,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Event> events = [
    Event(
      title: 'Coachella',
      desctiption: 'Il Coachella Valley Music and Arts Festival, comunemente conosciuto come Coachella, è uno dei festival musicali più celebri al mondo. Si tiene annualmente nella Valle di Coachella, nella contea di Riverside, in California, vicino alla città di Indio. Fondato nel 1999 da Paul Tollett e organizzato dalla società di promozione Goldenvoice, il Coachella Festival è diventato un\'icona della cultura musicale e dei festival.',
      completed: false,
      startDate: DateTime(2024, 5, 7, 15, 30),
      endDate: DateTime(2024, 6, 7, 15, 30),
      startHour: TimeOfDay(hour: 12, minute: 00),
      expectedParticipants: 300,
      actualParticipants:  200,
      img: 'assets/romantico.jpg',
      /*img: File('./storage/emulated/0/Pictures/IMG_20240508_104350.jpg'),*/
    ),
    Event(
      title: 'Milano Fashon Week',
      desctiption: 'parade',
      completed: false,
      startDate: DateTime(2024, 2, 11, 08, 30),
      endDate: DateTime(2024, 6, 7, 15, 30),
      startHour: TimeOfDay(hour: 22, minute: 30),
      expectedParticipants: 5000,
      actualParticipants: 4600,
      img: 'assets/cena.png',
      /*img: File('./storage/emulated/0/Pictures/IMG_20240508_104350.jpg'),*/
    ),
  ];

  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.tealAccent[700],
          title: Text('Event Manager'),
        ),
        body: <Widget>[
          SafeArea(
          child: ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final eventsIndex = index;
              Event ev = events[eventsIndex];
              return InkWell(
                child: Card(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: Image.asset(
                            ev.img,
                            fit: BoxFit.cover
                          ),
                        ),
                      ),
                      ListTile(
                        title: Text(
                          ev.title,
                        ),
                        subtitle:  Text("From ${DateFormat('EEE, MMM d, yyyy').format(ev.startDate)} at ${DateFormat('h:mm a').format(DateTime(1, 1, 1, ev.startHour.hour, ev.startHour.minute))}\nTo ${DateFormat('EEE, MMM d, yyyy').format(ev.endDate)}"),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(ev.desctiption),
                      )
                    ],
                  ),
                ),
                onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EventDetailPage(event: ev))
                    );
                  },
              );
            }
          )
        ),
        Text("Paperino"),
        Text("Pippo"),
        ][currentPageIndex],
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NewEvent())
            ).then((newEvent) {
                  print(newEvent);
                  if(newEvent != null) {
                    setState((){
                      events.add(newEvent);
                    });
                  }
              });
          },
          child: const Icon(Icons.add),
        ),
        bottomNavigationBar: NavigationBar(
            onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_rounded),
            label: 'Menage',
          ),
          NavigationDestination(
            icon: Icon(Icons.ssid_chart_rounded),
            label: 'Statistics',
          ),
        ],)
      );
  }
}