import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:we_chat/api/apis.dart';
import 'package:we_chat/helper/dialogs.dart';
import 'package:we_chat/helper/my_date_util.dart';

import '../main.dart';
import '../models/message.dart';

class MessageCard extends StatefulWidget {
  const MessageCard({super.key, required this.message});

  final Message message;

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  @override
  Widget build(BuildContext context) {

    bool isMe = APIs.user.uid == widget.message.fromID;
    return InkWell(
      onLongPress: (){
        _showBottomSheet(isMe);
      },
      child: isMe ? _greenMessage() : _blueMessage());  
  }

  Widget _blueMessage(){

    if(widget.message.read.isEmpty){
      APIs.updateMessageReadStatus(widget.message);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            // ignore: unrelated_type_equality_checks
            padding: EdgeInsets.all(widget.message.type == Type.image 
                ? mq.width * 0
                : mq.width * .04),
            margin: EdgeInsets.symmetric(
              horizontal: mq.width * .04, vertical: mq.height * .01),
            decoration: widget.message.type == Type.image ? null :BoxDecoration(color: Color(0xFFe4e6eb),
            borderRadius: widget.message.type == Type.image ? null : BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20))),
            child: widget.message.type == Type.text ?
            Text(
              widget.message.msg,
              style: const TextStyle(fontSize: 15, color: Colors.black87)
              ) : ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: widget.message.msg,                
                  placeholder: (context, url) => 
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2,),
                    ),
                  errorWidget: (context, url, error) => 
                    const Icon(Icons.image, size: 70,),
                ),
              ),
            ),
        ),

        Padding(
          padding: EdgeInsets.only(right: mq.width * .04),
          child: Text(
            MyDateUtil.getFormattedTime(context: context, time: widget.message.sent),
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        )
      ],
    );
  }

  Widget _greenMessage(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [     
        Row(
          children: [

            SizedBox(width: mq.width * .04,),

            if(widget.message.read.isNotEmpty)
              const Icon(Icons.done_all_rounded, color: Colors.blue, size: 20),

            const SizedBox(width: 2,),

            Text(
              MyDateUtil.getFormattedTime(context: context, time: widget.message.sent),
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),

        Flexible(
          child: Container(
            // ignore: unrelated_type_equality_checks
            padding: EdgeInsets.all(widget.message.type == Type.image 
                ? mq.width * 0
                : mq.width * .04),
            margin: EdgeInsets.symmetric(
              horizontal: mq.width * .04, vertical: mq.height * .01),
            decoration: widget.message.type == Type.image ? null :BoxDecoration(color: Colors.blue,
            borderRadius: widget.message.type == Type.image ? null : BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20))),
            child: widget.message.type == Type.text ?
            Text(
              widget.message.msg,
              style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500)
              ) : ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: widget.message.msg,                
                  placeholder: (context, url) => 
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2,),
                    ),
                  errorWidget: (context, url, error) => 
                    const Icon(Icons.image, size: 70,),
                ),
              ),
          ),
        ),
      ],
    );
  }

 void _showBottomSheet(bool isMe) {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        builder: (_) {
          return ListView(
            shrinkWrap: true,
            children: [
              //black divider
              Container(
                height: 4,
                margin: EdgeInsets.symmetric(
                    vertical: mq.height * .015, horizontal: mq.width * .4),
                decoration: BoxDecoration(
                    color: Colors.grey, borderRadius: BorderRadius.circular(8)),
              ),

              widget.message.type == Type.text
                  ?
                  //copy option
                  _OptionItem(
                      icon: const Icon(Icons.copy_all_rounded,
                          color: Colors.blue, size: 26),
                      name: 'Copy Text',
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: widget.message.msg)).then((value) {
                          Navigator.pop(context);

                          Dialogs.showSnackbar(context, 'Text Copied');
                        });
                      })
                  :
                  //save option
                  _OptionItem(
                      icon: const Icon(Icons.download_rounded,
                          color: Colors.blue, size: 26),
                      name: 'Save Image',
                      onTap: () async {
                        try{
                          log('Image Url: ${widget.message.msg}');
                          await GallerySaver.saveImage(widget.message.msg, albumName: 'We Chat')
                            .then((success) {
                              Navigator.pop(context);
                              if(success != null && success){
                                Dialogs.showSnackbar(context, 'Image Successfully Saved');
                              }
                          });
                        }
                        catch(e){
                          log('ErrorWhileSavingImg: $e');
                        }
                      }),

              //separator or divider
              if (isMe)
                Divider(
                  color: Colors.black54,
                  endIndent: mq.width * .04,
                  indent: mq.width * .04,
                ),

              //edit option
             

              //delete option
              if (isMe)
                _OptionItem(
                    icon: const Icon(Icons.delete_forever,
                        color: Colors.red, size: 26),
                    name: 'Delete Message',
                    onTap: () async {
                    await APIs.deleteMessage(widget.message).then((value) {
                      Navigator.pop(context);
                    });
                }),

              //separator or divider
              Divider(
                color: Colors.black54,
                endIndent: mq.width * .04,
                indent: mq.width * .04,
              ),

              //sent time
              _OptionItem(
                  icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                  name:
                      'Sent At: ${MyDateUtil.getMessageTime(context: context, time: widget.message.sent)}',
                  onTap: () {}),

              //read time
              _OptionItem(
                  icon: const Icon(Icons.remove_red_eye, color: Colors.green),
                  name: widget.message.read.isEmpty
                      ? 'Read At: Not seen yet'
                      : 'Read At: ${MyDateUtil.getMessageTime(context: context, time: widget.message.read)}',
                  onTap: () {}),
            ],
          );
        });
  }

}

class _OptionItem extends StatelessWidget {
  final Icon icon;
  final String name;
  final VoidCallback onTap;

  const _OptionItem(
      {required this.icon, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () => onTap(),
        child: Padding(
          padding: EdgeInsets.only(
              left: mq.width * .05,
              top: mq.height * .015,
              bottom: mq.height * .015),
          child: Row(children: [
            icon,
            Flexible(
                child: Text('    $name',
                    style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        letterSpacing: 0.5)))
          ]),
        ));
  }
}