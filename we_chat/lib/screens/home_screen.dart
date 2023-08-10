import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:we_chat/models/chat_user.dart';
import 'package:we_chat/screens/profile_screen.dart';


import '../api/apis.dart';
import '../main.dart';
import '../widgets/chat_user_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ChatUser> _list = [];
  final List<ChatUser> _searchList = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();    
    
    SystemChannels.lifecycle.setMessageHandler((message) {
      log('Message: $message');

      if(APIs.auth.currentUser != null){
        if(message.toString().contains('resume')) APIs.updateActiveStatus(true);
        if(message.toString().contains('pause')) APIs.updateActiveStatus(false);
      }
      

      return Future.value(message);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: (){
          if(_isSearching){
            setState(() {
              _isSearching = !_isSearching;
            });
            return Future.value(false);
          }
          else{
            return Future.value(true);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.lightBlue,
            leading: const Icon(CupertinoIcons.home, color: Colors.white,),
            title: _isSearching
              ?TextField(
                decoration: InputDecoration(
                  iconColor: Colors.white,
                  border: InputBorder.none,
                  hintText: 'Tên, Email, ...',
                  hintStyle: TextStyle(color: Colors.white)),
                autofocus: true,
                style: TextStyle(fontSize: 17, letterSpacing: 0.5, ),
                onChanged: (val){
                  _searchList.clear();
          
                  for (var i in _list) {
                    if(i.name.toLowerCase().contains(val.toLowerCase()) || 
                       i.email.toLowerCase().contains(val.toLowerCase())){
                      _searchList.add(i);
                    }
                    setState(() {
                      // ignore: unnecessary_statements
                      _searchList;
                    });
                  }
                },
              )
              :Text('We Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),),
            actions: [
              IconButton(
                onPressed: (){
                  setState(() {
                    _isSearching =!_isSearching;
                  });
                }, 
                icon: Icon(_isSearching 
                  ?CupertinoIcons.clear_circled_solid 
                  :Icons.search, color: Colors.white
                )
              ),
          
              IconButton(onPressed: (){
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ProfileScreen(user: APIs.me,)));
              }, icon: const Icon(Icons.more_vert),
                  color: Colors.white)
            ],
          ),

          body: StreamBuilder(
            stream: APIs.getAllUsers(),
            builder: (context, snapshot){
          
              switch(snapshot.connectionState){
                //if data is loading
                case ConnectionState.waiting:
                case ConnectionState.none:
                  return const Center(child: CircularProgressIndicator());
          
                //if some or all data is loaded then show it
                case ConnectionState.active:
                case ConnectionState.done:
                  final data = snapshot.data?.docs;
                  _list = data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];
                    
                 
                  if(_list.isNotEmpty) {
                    return ListView.builder(
                    itemCount: _isSearching ? _searchList.length :_list.length,         
                    padding: EdgeInsets.only(top: mq.height * .01),
                    physics: const BouncingScrollPhysics(),   
                    itemBuilder: (context, index){
                      return ChatUserCard(user: _isSearching ? _searchList[index] :_list[index],);
                      // return Text('Name: ${list[index]}');
                      }
                    );
                  } else {
                    return Center(
                      child: Text('Chưa có tin nhắn',
                        style: TextStyle(fontSize: 20),),
                    );
                  }
                  
              }      
            },
          ),
        ),
      ),
    );
  }
}