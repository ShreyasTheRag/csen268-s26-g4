import 'package:santa_clara/blocs/authentication/bloc/authentication_bloc.dart';
import 'package:santa_clara/widgets/user_avatar_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum UserAvatarSize {
  small,
  medium,
  large,
}

class LoggedInUserAvatar extends StatelessWidget {
  final UserAvatarSize userAvatarSize;
  final String? imageUrl;
  final String? userHandle;

  const LoggedInUserAvatar({
    super.key, 
    required this.userAvatarSize,
    this.imageUrl, // Defaults to null if not passed
    this.userHandle
  });

  @override
  Widget build(BuildContext context) {
    late double radius;
    switch (userAvatarSize) {
      case UserAvatarSize.small:
        radius = 15;
        break;
      case UserAvatarSize.medium:
        radius = 25;
        break;
      case UserAvatarSize.large:
        radius = 40;
        break;
    }

    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      builder: (context, state) {
        switch (state) {
          case AuthenticationSignedInState _:
            
            // 2. Determine whether to show the database image or fallback widget
            final bool hasValidImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 3. Conditional rendering based on string validity
                  hasValidImage
                      ? CircleAvatar(
                          radius: radius,
                          backgroundImage: NetworkImage(imageUrl!),
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        )
                      : UserAvatarImage(
                          user: state.user,
                          radius: radius,
                        ),
                  if (userAvatarSize == UserAvatarSize.large)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(userHandle ?? state.user.email,
                                maxLines: 1, overflow: TextOverflow.clip),
                          ),
                          if (state.user.emailVerified)
                            const Padding(
                              padding: EdgeInsets.only(left: 5.0),
                              child: Icon(
                                Icons.verified_user_outlined,
                              ),
                            )
                        ],
                      ),
                    ),
                ],
              ),
            );
          default:
            return Container();
        }
      },
    );
  }
}