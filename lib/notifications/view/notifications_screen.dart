import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: 10,
      shrinkWrap: true,
      separatorBuilder: (c, i) => const Divider(thickness: 1),
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          contentPadding: EdgeInsets.all(8.0),
          title: Padding(
            padding: const EdgeInsetsDirectional.only(start: 8.0),
            child: Text('Notification', maxLines: 3),
          ),
          onTap: () {},
          trailing: Column(
            children: [
              Expanded(child: Text('5h')),
              Expanded(
                child: IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              )
            ],
          ),
        );
      },
    );
  }
}