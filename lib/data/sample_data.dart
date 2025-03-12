import 'package:splitgasy/Models/app_user.dart';
import 'package:splitgasy/Models/group.dart';

// Function to get sample users
List<AppUser> getSampleUsers() {
  return [
    AppUser(
      id: '1',
      profile: 'https://example.com/profile1.png',
      name: 'David',
      email: 'david@example.com',
    ),
    AppUser(
      id: '2',
      profile: 'https://example.com/profile2.png',
      name: 'Nael',
      email: 'nael@example.com',
    ),
    AppUser(
      id: '3',
      profile: 'https://example.com/profile3.png',
      name: 'Mbola',
      email: 'mbola@example.com',
    ),
  ];
}

// Function to get sample groups
List<Group> getSampleGroups() {
  final sampleUsers = getSampleUsers();
  
  return [
    Group(
      id: 'group1',
      profile: 'https://example.com/group1.png',
      name: 'Trip to Paris',
      members: [sampleUsers[0], sampleUsers[1], sampleUsers[2]],
    ),
    Group(
      id: 'group2',
      profile: 'https://example.com/group2.png',
      name: 'Dinner Party',
      members: [sampleUsers[1], sampleUsers[2]],
    ),
    Group(
      id: 'group3',
      profile: 'https://example.com/group3.png',
      name: 'Shared Rent',
      members: [sampleUsers[0], sampleUsers[2]],
    ),
  ];
}
