import 'package:flutter_application_2/firebase_options.dart';
import 'package:flutter_application_2/services/firestore_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirestoreService firestore;

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firestore = FirestoreService();
  });

  testWidgets('Add and fetch user from real Firestore', (WidgetTester tester) async {
    // Add a user
    await firestore.addUser('TEST_USER');

    // Fetch all users and validate if the user is added
    final users = await firestore.getAllUsers();
    final user = users.firstWhere((u) => u['name'] == 'TEST_USER', orElse: () => {});
    String userId = user['id'];
    expect(user.isNotEmpty, true);

    await firestore.deleteUser(userId);
  });

  testWidgets('Update user name in Firestore', (WidgetTester tester) async {
    // Add a user first
    await firestore.addUser('TEST_USER');

    // Get the user to update
    final users = await firestore.getAllUsers();
    final user = users.firstWhere((u) => u['name'] == 'TEST_USER', orElse: () => {});
    final userId = user['id'];

    // Update the user's name
    await firestore.updateUser(userId, 'UPDATED_USER');

    // Fetch the updated user and check the name
    final updatedUser = await firestore.getUserByID(userId);
    expect(updatedUser['name'], 'UPDATED_USER');

    await firestore.deleteUser(userId);
  });

  testWidgets('Delete user from Firestore', (WidgetTester tester) async {
    // Add a user first
    await firestore.addUser('TEST_USER');

    // Get the user to delete
    final users = await firestore.getAllUsers();
    final user = users.firstWhere((u) => u['name'] == 'TEST_USER', orElse: () => {});
    final userId = user['id'];

    // Delete the user
    await firestore.deleteUser(userId);

    // Try fetching the user, should throw an exception
    try {
      await firestore.getUserByID(userId);
      fail('User should not exist');
    } catch (e) {
      expect(e.toString(), contains('User with ID $userId not found'));
    }
  });

  testWidgets('Add group and fetch it from Firestore', (WidgetTester tester) async {
    // Add a group
    final memberIds = ['user1', 'user2'];
    await firestore.addGroup('Test Group', memberIds);

    // Fetch all groups and validate if the group is added
    final groups = await firestore.getGroupsByUser('user1');
    final group = groups.firstWhere((g) => g['name'] == 'Test Group', orElse: () => {});
    String groupId = group['id'];
    expect(group.isNotEmpty, true);

    await firestore.deleteGroup(groupId);
  });

  testWidgets('Add and remove member from a group', (WidgetTester tester) async {
    // Add a group
    final memberIds = ['user1', 'user2'];
    await firestore.addGroup('Test Group', memberIds);

    // Get the group's ID
    final groups = await firestore.getGroupsByUser('user1');
    final group = groups.firstWhere((g) => g['name'] == 'Test Group', orElse: () => {});
    final groupId = group['id'];

    // Add a new member to the group
    await firestore.addMemberToGroup(groupId, 'user3');

    // Fetch the group again and check members
    final updatedGroup = await firestore.getGroupById(groupId);
    expect(updatedGroup['members'], contains('user3'));

    // Remove a member from the group
    await firestore.removeMemberFromGroup(groupId, 'user3');

    // Fetch the group again and check members
    final finalGroup = await firestore.getGroupById(groupId);
    expect(finalGroup['members'], isNot(contains('user3')));

    await firestore.deleteGroup(groupId);
  });

  testWidgets('Add a payment to a group and fetch it from Firestore', (WidgetTester tester) async {
    final memberIds = ['user1', 'user2'];
    await firestore.addGroup('Test Group', memberIds);
    final groups = await firestore.getGroupsByUser('user1');
    final group = groups.firstWhere((g) => g['name'] == 'Test Group', orElse: () => {});
    final groupId = group['id'];

    // Add a payment to the group
    await firestore.addPayment(groupId, 100.0, 'Test Payment', 'user1');

    // Fetch all payments in the group and validate if the payment is added
    final payments = await firestore.getPaymentsByGroup(groupId);
    final payment = payments.firstWhere((p) => p['description'] == 'Test Payment', orElse: () => {});
    expect(payment.isNotEmpty, true);

    await firestore.deleteGroup(groupId);
  });

  testWidgets('Update a payment in Firestore', (WidgetTester tester) async {
    // Add a group first
    final memberIds = ['user1', 'user2'];
    await firestore.addGroup('Test Group', memberIds);
    final groups = await firestore.getGroupsByUser('user1');
    final group = groups.firstWhere((g) => g['name'] == 'Test Group', orElse: () => {});
    final groupId = group['id'];

    // Add a payment to the group
    await firestore.addPayment(groupId, 100.0, 'Test Payment', 'user1');
    final payments = await firestore.getPaymentsByGroup(groupId);
    final payment = payments.firstWhere((p) => p['description'] == 'Test Payment', orElse: () => {});
    final paymentId = payment['id'];

    // Update the payment
    await firestore.updatePayment(groupId, paymentId, 150.0, 'Updated Payment');

    // Fetch the updated payment and check the amount
    final updatedPayment = await firestore.getPaymentById(groupId, paymentId);
    expect(updatedPayment['amount'], 150.0);

    await firestore.deleteGroup(groupId);
  });

  testWidgets('Delete payment from Firestore', (WidgetTester tester) async {
    // Add a group first
    final memberIds = ['user1', 'user2'];
    await firestore.addGroup('Test Group', memberIds);
    final groups = await firestore.getGroupsByUser('user1');
    final group = groups.firstWhere((g) => g['name'] == 'Test Group', orElse: () => {});
    final groupId = group['id'];

    // Add a payment to the group
    await firestore.addPayment(groupId, 100.0, 'Test Payment', 'user1');
    final payments = await firestore.getPaymentsByGroup(groupId);
    final payment = payments.firstWhere((p) => p['description'] == 'Test Payment', orElse: () => {});
    final paymentId = payment['id'];

    // Delete the payment
    await firestore.deletePayment(groupId, paymentId);

    // Try fetching the payment, should throw an exception
    try {
      await firestore.getPaymentById(groupId, paymentId);
      fail('Payment should not exist');
    } catch (e) {
      expect(e.toString(), contains('Payment with ID $paymentId not found'));
    }

    await firestore.deleteGroup(groupId);
  });
}
