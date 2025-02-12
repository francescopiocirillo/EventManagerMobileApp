import 'package:thirty_green_events/database_helper.dart';
import 'package:thirty_green_events/event.dart';
import 'package:thirty_green_events/event_detail_page.dart';
import 'package:thirty_green_events/new_event.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:thirty_green_events/person.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  /** Attributi relativi a tutte le pagine */
  int currentPageIndex = 0;
  List<Event> events = [];
  /** Attributi relativi alla prima pagina (Dashboard) */
  List<bool> isSelectedTogglePastIncomingEvents = [true, false];
  String invalidParticipant = "";
  DateTime birthDate = DateTime.now();
  String datePrompt = "Select date of birth*";
  final TextEditingController controller1 = TextEditingController();
  final TextEditingController controller2 = TextEditingController();
  /** Attributi relativi alla seconda pagina (Gestione evento) */
  List<bool> _isOpen = [];
  List<Event> filteredEvents = [];
  List<bool> isSelectedThemeFilter = [true, true, true];
  final TextEditingController searchBarController = TextEditingController();
  /** Attributi relativi alla quarta pagina (Statistiche) */
  LineChartBarData get lineChartBarDataExpected => LineChartBarData(
        isCurved: true,
        color: Colors.tealAccent.withOpacity(0.7),
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
        
        spots: lineGenerator('expected')
      );

  LineChartBarData get lineChartBarDataActual => LineChartBarData(
        isCurved: true,
        color: Colors.tealAccent[600],
        barWidth: 5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true, color: Theme.of(context).colorScheme.secondary.withOpacity(0.7)),
        spots: lineGenerator('actual'),
      );
  
  List<LineChartBarData> get linesBarsData => [
    lineChartBarDataActual,
    lineChartBarDataExpected
  ];

  _HomePageState() {
    _fetchEventi();
  }

  /** Metodi e funzioni relative alla prima pagina (Dashboard) */
  /** questa funzione preleva eventi e partecipanti dal db in modo
   * da popolare la lista che viene visualizzata
   */
  void _fetchEventi() async {
    final db = DatabaseHelper.instance;
    final List<Map<String, dynamic>> maps =
        await db.database.then((db) => db.query('event'));
    final List<Map<String, dynamic>> mapsParticipants =
        await db.database.then((db) => db.query('participant'));

    setState(() {
      events = List.generate(maps.length, (i) {
        final title = maps[i]['title'];
        final description = maps[i]['description'];
        final startDate = maps[i]['startDate'];
        final endDate = maps[i]['endDate'];
        final startHour = maps[i]['startHour'];
        final expectedParticipants = maps[i]['expectedParticipants'];
        final actualParticipants = maps[i]['actualParticipants'];
        final img = maps[i]['img'];
        final newEvent = Event(
            title: title as String,
            description: description as String,
            startDate: DateTime.parse(startDate),
            endDate: DateTime.parse(endDate),
            startHour: parseTimeOfDay(startHour),
            expectedParticipants: expectedParticipants as int,
            actualParticipants: actualParticipants as int,
            img: img as String,
          );
        List<Person?> participants = List.generate(mapsParticipants.length, (index) {
          if(mapsParticipants[index]['event_title'] == newEvent.title) {
            return Person(name: mapsParticipants[index]['name'], lastName: mapsParticipants[index]['last_name'], birth: DateTime.parse(mapsParticipants[index]['birth']));
          }
          else {
            return null;
          }
        });
        List<Person> participantsNotNull = participants.whereType<Person>().toList();
        newEvent.setParticipants(participantsNotNull);
        return newEvent;
      });
      filteredEvents = events;
      _isOpen = List.generate(events.length, (index) => false);
    });
  }

  /** questa funzione permette di convertire una stringa in un oggetto TimeOfDay */
  TimeOfDay parseTimeOfDay(String time) {
    final format = RegExp(r'^([0-9]{2}):([0-9]{2})$');
    final match = format.firstMatch(time.toString().substring(10, time.toString().length-1));
    if (match != null) {
      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      return TimeOfDay(hour: hour, minute: minute);
    } else {
      throw FormatException("Invalid time format");
    }
  }

  /** questa funzione permette di aprire un AlertDialog per aggiungere un nuovo
   * partecipante ad un evento
   */
  Future<Person?> openAddParticipantDialog(eventTitle) => showDialog<Person>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Add new participant'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Name*',
                        suffixText: 'required',
                      ),
                      controller: controller1,
                  ),
                  TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Surname*',
                        suffixText: 'required'
                      ),
                      controller: controller2,
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(datePrompt),
                        ElevatedButton(
                          onPressed: () => _selectDates(context, setState),
                          child: Icon(Icons.date_range_outlined),
                        ),
                    ],),
                  ),
                  Text(invalidParticipant, 
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error, 
                      fontWeight: FontWeight.bold),
                  )
              ],),
            ),
            actions: [
              TextButton(
                clipBehavior: Clip.antiAlias,
                onPressed: () => submitAddPerson(setState, eventTitle),
                child: Text('ADD'),
              ),
            ],
            
          );
        }
      );
    }
  );

  /** questa funzione permette di selezionare una data per il compleanno di 
   * un partecipante attraverso un DatePicker
   */
  Future<void> _selectDates(BuildContext context, setState) async {
    final DateTime? picked = await showDatePicker(
      context: context, 
      firstDate: DateTime(1900, 1, 1), 
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        birthDate = picked;
        datePrompt = "Selected:" + DateFormat("yMd").format(birthDate);
      });
    }
  }

  /** questa funzione gestisce l'aggiunta di un nuovo partecipante ad un evento */
  void submitAddPerson(setState, eventTitle) {
    if(controller1.text == "" || controller2.text == "" || birthDate.isAtSameMomentAs(DateTime.now()) ){
      setState(() {
        invalidParticipant= "ERROR: In order to add a new partecipant you should have to insert all the fields";      
      });
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data are being processed...'), backgroundColor: Colors.teal),
            );
      Person new_participant = Person(
        name: controller1.text,
        lastName: controller2.text,
        birth: birthDate);
      DatabaseHelper.instance.insertParticipant(eventTitle, new_participant);
      Navigator.of(context).pop(new_participant);
      controller1.clear();
      controller2.clear();
      datePrompt = "Select date of birth";
      invalidParticipant = "";
    }
  }

  @override
  void dispose() {
    controller1.dispose();
    controller2.dispose();
    super.dispose();
  }

  /** Metodi e funzioni relative alla seconda pagina (Gestione evento) */
  /** questa funzione filtra gli eventi sulla base del contenuto della searchbar */
  void filterEvents(String query) {
    setState(() {
      filteredEvents = events
          .where((ev) => ev.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  /** questa funzione filtra gli eventi sulla base del contenuto della searchbar 
   * e dei temi selezionati, l'attributo close indica se bisogna chiudere una finestra
   * di dialogo oppure se non è necessario
   */
  void applyFilters(close) {
    filterEvents(searchBarController.text);
    setState(() {
      if(!isSelectedThemeFilter[0] && !isSelectedThemeFilter[1] && !isSelectedThemeFilter[2]) {
        filteredEvents = [];
      }
      if(!isSelectedThemeFilter[0] && !isSelectedThemeFilter[1] && isSelectedThemeFilter[2]) {
        filteredEvents = filteredEvents
          .where((element) => element.img == 'assets/romantico.jpg')
          .toList();
      }
      if(!isSelectedThemeFilter[0] && isSelectedThemeFilter[1] && !isSelectedThemeFilter[2]) {
        filteredEvents = filteredEvents
          .where((element) => element.img == 'assets/cena.png')
          .toList();
      }
      if(!isSelectedThemeFilter[0] && isSelectedThemeFilter[1] && isSelectedThemeFilter[2]) {
        filteredEvents = filteredEvents
          .where((element) => element.img == 'assets/cena.png' || element.img == 'assets/romantico.jpg')
          .toList();
      }
      if(isSelectedThemeFilter[0] && !isSelectedThemeFilter[1] && !isSelectedThemeFilter[2]) {
        filteredEvents = filteredEvents
          .where((element) => element.img == 'assets/lavoro.jpg')
          .toList();
      }
      if(isSelectedThemeFilter[0] && !isSelectedThemeFilter[1] && isSelectedThemeFilter[2]) {
        filteredEvents = filteredEvents
          .where((element) => element.img == 'assets/lavoro.jpg' || element.img == 'assets/romantico.jpg')
          .toList();
      }
      if(isSelectedThemeFilter[0] && isSelectedThemeFilter[1] && !isSelectedThemeFilter[2]) {
        filteredEvents = filteredEvents
          .where((element) => element.img == 'assets/cena.png' || element.img == 'assets/lavoro.jpg')
          .toList();
      }
      if(isSelectedThemeFilter[0] && isSelectedThemeFilter[1] && isSelectedThemeFilter[2]) {
        filteredEvents = filteredEvents;
      }
    });
    if(close) {
      Navigator.of(context).pop();
    }
  }

  /** questa funzione apre una finestra di dialogo per la selezione
   * dei temi desidarati per l'applicazione di filtri agli eventi
   */
  Future<Person?> openApplyFiltersDialog() => showDialog<Person>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            /**queste tre variabili servono per la responsività dell'alert:
             * la dimensione dei circleAvatar che contiene variano in base alla dimensione dello
             * schermo e in base all'orientamento del dispositivo per permettere di avere una ui 
             * ideale per tutte le casistiche
             */
            double radius = MediaQuery.of(context).size.width* 0.1;
            double redius_ori = MediaQuery.of(context).size.height*0.13;
            double radius_respo = (MediaQuery.of(context).orientation == Orientation.portrait ? radius : redius_ori) ;
            return AlertDialog(
              title: Text('Filter the events'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    Text("Filter by theme:"),
                    ToggleButtons(
                      fillColor: Theme.of(context).colorScheme.primary,
                      isSelected: isSelectedThemeFilter,
                      onPressed: (int index) {
                        setState(() {
                          isSelectedThemeFilter[index] = !isSelectedThemeFilter[index];
                        });
                      },
                      children: <Widget>[
                        CircleAvatar(backgroundImage: AssetImage("assets/lavoro.jpg"), radius: radius_respo),
                        CircleAvatar(backgroundImage: AssetImage("assets/cena.png"), radius: radius_respo),
                        CircleAvatar(backgroundImage: AssetImage("assets/romantico.jpg"), radius: radius_respo),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  clipBehavior: Clip.antiAlias,
                  onPressed: () {
                    applyFilters(true);
                  },
                  child: Text('FILTER'),
                )
              ],
            );
          },
        ));

  /** Metodi e funzioni relative alla quarta pagina (Statistiche) */
  /** questa funzione restituisce un array di due valori, il primo è il
   * numero totale di partecipanti a tutti gli eventi, il secondo è il numero
   * di partecipanti ancora non registrati a tutti gli eventi
   */
  List<int> numeroPartecipantiAttivi() {
    List<int> numeri= [0,0];
    int i;
    for(i=0; i<events.length; i++){
      numeri[0] += events[i].actualParticipants;
      numeri[1] += (events[i].expectedParticipants - events[i].actualParticipants);
    }
    return numeri;
  }

  /** restituisce il numero totale di partecipanti effettivi o attesi 
   * (a seconda della stringa tipo) per il mese fornito come parametro
  */
  double numLineChart(int mese, String tipo){
    List<double> partecipanti= [0,0];
    int i;
    int ret=0;
    for(i=0; i<events.length; i++){
      if(mese == events[i].startDate.month.toInt() && DateTime.now().year == events[i].startDate.year){
        if(tipo == 'actual'){
          partecipanti[0] += events[i].actualParticipants;
          ret=0;
        }
        else{
          partecipanti[1] += events[i].expectedParticipants;
          ret=1;
        }
      }
    }
    return partecipanti[ret];
  }

  /** fornisce una lista di punti per un linechart */
  List<FlSpot> lineGenerator(String tipo){
    List<FlSpot> punti = [];
    int i=0;
    for(i=0; i<12; i++){
      punti.add(FlSpot((i + 1).toDouble(), numLineChart(i + 1, tipo)));
    }
    return punti;
  }

  /** questa funzione genera le etichette sull'asse x del LineChart */
  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 15,
    );
    Widget text;
    switch (value.toInt()) {
      case 1:
        text = const Text('J', style: style); 
        break;
      case 2:
        text = const Text('F', style: style);
        break;
      case 3:
        text = const Text('M', style: style);
        break;
      case 4:
        text = const Text('A', style: style); 
        break;
      case 5:
        text = const Text('M', style: style);
        break;
      case 6:
        text = const Text('J', style: style);
        break;
      case 7:
        text = const Text('J', style: style); 
        break;
      case 8:
        text = const Text('A', style: style);
        break;
      case 9:
        text = const Text('S', style: style);
        break;
      case 10:
        text = const Text('O', style: style); 
        break;
      case 11:
        text = const Text('N', style: style);
        break;
      case 12:
        text = const Text('D', style: style);
        break;
      default:
        text = const Text('');
        break;
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 10,
      child: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: Center(
            child: Text('Thirty Green Events',
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 30, color: Colors.teal.shade900 ),
            ),
          ),
        ),
        body: <Widget>[
          /** prima pagina */
          SafeArea(
              child:
                Column(
                  children: [
                    /** in cima alla pagina ci sono dei ToggleButtons per scegliere se visualizzare 
                     * gli eventi passati o quelli futuri */
                    ToggleButtons(
                      isSelected: isSelectedTogglePastIncomingEvents,
                      onPressed: (index) {
                        setState(() {
                          for (int buttonIndex = 0;
                              buttonIndex < isSelectedTogglePastIncomingEvents.length;
                              buttonIndex++) {
                            if (buttonIndex == index) {
                              isSelectedTogglePastIncomingEvents[buttonIndex] = true;
                            } else {
                              isSelectedTogglePastIncomingEvents[buttonIndex] = false;
                            }
                          }
                        });
                      },
                      children: const <Widget>[
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Past events"),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Incoming events"),
                        ),
                      ],
                    ),
                    /** la prima pagina contiene la lista degli eventi, a seconda della scelta del
                     * ToggleButton cambiano gli eventi mostrati
                     */
                    Expanded(
                      child: ListView.builder(
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final eventsIndex = index;
                            Event ev = events[eventsIndex];
                            if (isSelectedTogglePastIncomingEvents[0] &&
                                    ev.endDate.compareTo(DateTime.now()) < 0 ||
                                isSelectedTogglePastIncomingEvents[1] &&
                                    ev.endDate.compareTo(DateTime.now()) >= 0) {
                              return InkWell(
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Card( 
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(top: 10),
                                          child: Container(
                                            height: (MediaQuery.of(context).orientation == Orientation.portrait ?
                                              200 : 100),
                                            width:
                                                MediaQuery.of(context).size.width * 0.8,
                                            child:
                                                Image.asset(ev.img, fit: BoxFit.cover),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            ev.title,
                                          ),
                                          subtitle: Text(
                                              "From ${DateFormat('EEE, MMM d, yyyy').format(ev.startDate)} at ${DateFormat('h:mm a').format(DateTime(1, 1, 1, ev.startHour.hour, ev.startHour.minute))}\nTo ${DateFormat('EEE, MMM d, yyyy').format(ev.endDate)}\nParticipants ${ev.actualParticipants} of ${ev.expectedParticipants}"),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Text(ev.description),
                                        ),
                                        ElevatedButton(
                                          child: Text('new participant'),
                                          onPressed: () async {
                                            controller1.clear();
                                            controller2.clear();
                                            datePrompt = "Select date of birth";
                                            invalidParticipant = "";
                                            final person =
                                                await openAddParticipantDialog(ev.title);
                                            if (person == null) return;
                                            setState(
                                              () {
                                                ev.actualParticipants++;
                                                ev.participants.add(person);
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                /** onTap su un Evento porta alla quinta pagina dedicata a quell'evento */
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              EventDetailPage(event: ev)));
                                },
                              );
                            } else {
                              /** visto che bisogna necessariamente specificare il numero di elementi
                               * in un listview.builder questo è stato impostato al numero totale di eventi
                               * ma il numero reale mostrato è più basso in quanto si distingue tra passati e futuri,
                               * gli elementi in eccesso sono SizedBox.shrink() che in Flutter è l'equivalente di un Widget nullo
                               */
                              return const SizedBox.shrink();
                            }
                          }
                        ),
                    ),
                  ],
                )
            ),
          /** seconda pagina */
          SafeArea(
              child:
              Column(
                children: [
                  /** la seconda pagina presenta in alto una Row che contiene la SearchBar e il tasto
                   * per accedere al menu di scelta del filtro
                   */
                  Row(
                    children: [
                      Expanded(
                        child: SearchBar(
                          leading: const Icon(Icons.search_rounded),
                          onChanged: (value) {
                            applyFilters(false);
                          },
                          hintText: "Search by title",
                          controller: searchBarController,
                          
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(7.0),
                        child: SizedBox(
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 7, // Imposta l'elevazione desiderata
                            ),
                            onPressed: () {
                              openApplyFiltersDialog();
                            },
                            child: Text("Filter")),
                          
                        ),
                      )
                    ],
                  ),
                  Expanded(
                    /** la pagina presenta la lista di tutti gli eventi che rientrano nella selezione
                     * della searchbar e del filtro
                     */
                    child: ListView.builder(
                        itemCount: filteredEvents.length,
                        itemBuilder: (context, index) {
                          final eventsIndex = index;
                          Event ev = filteredEvents[eventsIndex];
                          return InkWell(
                            child: Card(
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration:
                                              BoxDecoration(shape: BoxShape.circle),
                                          child: CircleAvatar(
                                            backgroundImage: AssetImage(ev.img),
                                            radius: 60,
                                          ),
                                        ),
                                        Expanded(
                                          child: ListTile(
                                            title: Text(
                                              ev.title,
                                            ),
                                            subtitle: Text(
                                                "From ${DateFormat('EEE, MMM d, yyyy').format(ev.startDate)} at ${DateFormat('h:mm a').format(DateTime(1, 1, 1, ev.startHour.hour, ev.startHour.minute))}\nTo ${DateFormat('EEE, MMM d, yyyy').format(ev.endDate)}"),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  /** per ogni evento è presente una Row con un TextButton per la modifica 
                                   * dell'evento e un TextButton per l'eliminazione dello stesso
                                  */
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        clipBehavior: Clip.antiAlias,
                                        onPressed: () {
                                          Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) => NewEvent(event: ev, events: events)))
                                              .then((newEvent) {
                                            if (newEvent != null) {
                                                setState(() {
                                                  newEvent.participants = ev.participants;
                                                  newEvent.actualParticipants = ev.actualParticipants;
                                                  if(newEvent.title != ev.title) {
                                                    DatabaseHelper.instance.insertEvento(newEvent);
                                                    DatabaseHelper.instance.updateParticipants(newEvent.title, ev.title);
                                                    DatabaseHelper.instance.deleteEvento(ev);
                                                  }
                                                  else {
                                                    DatabaseHelper.instance.updateEvent(ev, newEvent);
                                                  }
                                                  events.remove(ev);
                                                  events.add(newEvent);
                                                  applyFilters(false);
                                                });
                                            }
                                          });
                                        },
                                        child: Text('Modify',
                                                style: TextStyle(color: Theme.of(context).colorScheme.primary,
                                                                decoration: TextDecoration.underline,
                                                                decorationColor: Theme.of(context).colorScheme.primary)
                                            ),
                                      ),
                                      TextButton(
                                        clipBehavior: Clip.antiAlias,
                                        onPressed: () {
                                          DatabaseHelper.instance.deleteEvento(ev);
                                          events.remove(ev);
                                          applyFilters(false);
                                        },
                                        child: Text('Delete',
                                                  style: TextStyle(color: Theme.of(context).colorScheme.secondary,
                                                                  decoration: TextDecoration.underline,
                                                                  decorationColor: Theme.of(context).colorScheme.secondary)
                                              ),
                                      ),
                                    ],
                                  ),
                                /**La parte inferirore di ogni card contiene un pannello che può nascondere o mostrare la lista dei partecipanti
                                 * questa organizzazione serve per non affollare la view e fornire una visione d'insieme all'utente.
                                 */
                                ExpansionPanelList(
                                  animationDuration:
                                    Duration(milliseconds: 1000),
                                  expandedHeaderPadding:
                                    EdgeInsets.all(8),
                                  children: [
                                    ExpansionPanel(
                                      headerBuilder: (context, isExpanded) {
                                        return Text( (isExpanded? "Hide Attendees" : "View Attendees" ), 
                                            textAlign: TextAlign.right, 
                                            style: TextStyle(
                                              height: 3.3, /*per allineare il testo alla freccia*/
                                              color: const Color.fromARGB(225, 62,158,135),
                                              fontWeight: FontWeight.bold)  
                                            );
                                      }, 
                                      canTapOnHeader: true,
                                      body: ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: ev.participants.length, 
                                        itemBuilder: (context, index) {
                                        
                                        return Padding(
                                          padding: const EdgeInsets.only(left: 20.0),
                                          child: Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Row(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.only(right: 8.0),
                                                  /**gli elenchi puntati sono decorati dipendentemente dal tema scelto per l'evento*/
                                                  child: Icon( (ev.img == 'assets/cena.png' ? 
                                                        Icons.fastfood_rounded : 
                                                        ev.img == 'assets/romantico.jpg' ? 
                                                          Icons.favorite_rounded : 
                                                          Icons.cases_rounded),
                                                    color: Theme.of(context).colorScheme.primary ),
                                                ),                                            
                                                Text( "${ev.participants[index].name} ${ev.participants[index].lastName} ${DateFormat('yMd').format(ev.participants[index].birth)}"),
                                              ],
                                            ),
                                          ),
                                        );
                                      },),
                                      isExpanded: _isOpen[index],
                                    ),
                                  ],
                                  expansionCallback: (i, isOpen) =>
                                    setState(() =>
                                      _isOpen[index] = !_isOpen[index]
                                    )
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          EventDetailPage(event: ev)));
                            },
                          );
                        }),
                  ),
                ],
              )
          ),
          /**terza schermata : statistiche 
           * -una statistica che mostra quanti eventi sono registrati sull'app
           * -un grafico a torta che mostra la percentuale di partecipanti reale 
           * rispetto a quelli attesi considerando tutti gli eventi registrati sull'app
           * -un garfico temporale che mostra due linee per mettere in comparazione 
           * il numero di partecipanti attesi rispetto a quelli realmente iscritti 
           * nei diversi mesi
           */
          SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                    Text("Here you can find all the statistics about your events!",
                      style: TextStyle(color: Colors.teal[800], 
                                      fontSize: 30, 
                                      fontWeight: FontWeight.bold,),
                      textAlign: TextAlign.center,
                    ),
                    Text("Number of events saved", 
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, 
                                fontSize: 20, 
                                fontWeight: FontWeight.bold,),
                      textAlign: TextAlign.center,),
                    Text(events.length.toString(),
                        style: TextStyle(color: Colors.teal[400], 
                                    fontSize: 50, 
                                    fontWeight: FontWeight.bold,),
                          textAlign: TextAlign.center,),
                    Divider(color: Colors.teal.shade100,
                            thickness: 2.0,),
                    Text("Percentage of active participation in events", 
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, 
                                fontSize: 20, 
                                fontWeight: FontWeight.bold,),
                      textAlign: TextAlign.center,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          /**i SizedBox evitano l'Overflow per i grafici della libreria flchart.
                           * Le dimensioni sono relative alla dimensione dello schermo per 
                           * garantire un comportamento responsivo e ottimizzare la visualizzazione 
                           * da dispositivi differenti
                          */
                          width: MediaQuery.of(context).size.width * 0.7,
                          height: MediaQuery.of(context).size.width * 0.7,
                          child: PieChart(
                            PieChartData(
                              centerSpaceRadius: 0.0, /*spazio vuoto al centro del grafico nullo per ottenere un pie chart */
                              sectionsSpace: 3, /* spazio di separazione sta le differenti sezioni */
                              sections: [
                                PieChartSectionData(
                                  radius: MediaQuery.of(context).size.width * 0.3, /*demensione del raggio della sezione*/
                                  value: numeroPartecipantiAttivi()[0].toDouble(), 
                                  title: '${(numeroPartecipantiAttivi()[0] / (numeroPartecipantiAttivi()[0]+numeroPartecipantiAttivi()[1]) * 100).toStringAsFixed(1)}%', 
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.teal.shade800,
                                      Colors.teal.shade300,
                                    ],
                                  ),
                                  ),
                                PieChartSectionData(
                                  radius: MediaQuery.of(context).size.width * 0.27, /*demensione del raggio della sezione*/
                                  value: numeroPartecipantiAttivi()[1].toDouble(), 
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.tealAccent.shade700,
                                      Colors.tealAccent.shade100,
                                    ],
                                  ),
                                  title: '${(numeroPartecipantiAttivi()[1] / (numeroPartecipantiAttivi()[0]+numeroPartecipantiAttivi()[1]) * 100).toStringAsFixed(1)}%'),],
                            ),
                            
                          ),
                        ),
                        /*legenda del grafico a torta*/
                        Column(
                          children: [
                            Icon(Icons.person_2_rounded, color: Colors.tealAccent ),
                            Text('absent',
                             style: TextStyle(
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.tealAccent,
                                decorationThickness: 3)
                              ),
                            Icon(Icons.person_2_rounded, color: Colors.tealAccent.shade700 ),
                            Text('active', 
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.tealAccent.shade700,
                                decorationThickness: 3)
                              ),
                          ],
                        )
                      ],
                    ),     
                    Divider(color: Colors.teal.shade100,
                            thickness: 2.0,),
                    Text("Temporal distribution of partecipants during the year", 
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, 
                                fontSize: 20, 
                                fontWeight: FontWeight.bold,),
                      textAlign: TextAlign.center,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        /*comportamento differente per adattare il grafico a una visione orizzontale dello schermo*/
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,
                          height: (MediaQuery.of(context).orientation == Orientation.portrait ?
                              300 : 200),
                          child: LineChart(
                            /**cliccando sul grafico si possono sapere gli esatti valore nel punto d'interesse 
                             * vengono renderizzati solo i titoli inferiore e sinistro
                             * - quello inferirore (asse x) mostra le iniziali dei mesi contenute in bottomTitleWidgets
                             * - quello sinistro (asse y) mostra i valori di riferimento che variano in base ai 
                             *     dati presenti nell'app
                            */
                                    LineChartData(
                                      lineTouchData: LineTouchData(
                                        enabled: true,
                                        touchTooltipData: LineTouchTooltipData(    
                                          tooltipRoundedRadius: 20.0,
                                          fitInsideHorizontally: true,
                                          fitInsideVertically: true,
                                        )
                                      ),
                                      borderData: FlBorderData(show: false), 
                                      lineBarsData: linesBarsData,
                                      titlesData: FlTitlesData(
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 32,
                                            interval: 1,
                                            getTitlesWidget: bottomTitleWidgets,
                                          ),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        topTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        )
                                    ),
                                    
                                  ),
                        ),
                        /**legenda per grafico temporale*/
                        Column(
                          children: [
                            Icon(Icons.person_2_rounded, color: Colors.tealAccent ),
                            Text('expected',
                             style: TextStyle(
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.tealAccent,
                                decorationThickness: 3)
                              ),
                            Icon(Icons.person_2_rounded, color: Colors.tealAccent.shade700 ),
                            Text('real',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.tealAccent.shade700,
                                decorationThickness: 3)
                              ),
                          ],
                        )
                      ],
                    )],
                  ),
            )]
            ),
          )
        ),
        ][currentPageIndex],
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(context,
                    MaterialPageRoute(builder: (context) => NewEvent(events: events)))
                .then((newEvent) {
              if (newEvent != null) {
                setState(() {
                  events.add(newEvent);
                  _isOpen.add(false);
                  applyFilters(false);
                  DatabaseHelper.instance.insertEvento(newEvent);
                  //_notificationService.scheduleNotification(newEvent);
                });
              }
            });
          },
          child: const Icon(Icons.add),
        ),
        bottomNavigationBar: NavigationBar(
          height: (MediaQuery.of(context).orientation == Orientation.portrait ?
                  100 : 50),
          backgroundColor: Theme.of(context).colorScheme.primary,
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          selectedIndex: currentPageIndex,
          destinations: const <Widget>[
            NavigationDestination(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.manage_accounts_rounded),
              label: 'Manage',
            ),
            NavigationDestination(
              icon: Icon(Icons.ssid_chart_rounded),
              label: 'Statistics',
            ),
          ],
        ));
  }
}
