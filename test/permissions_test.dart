import 'package:flutter_test/flutter_test.dart';
import 'package:evergreen/core/auth/permissions.dart';
import 'package:evergreen/core/router/routes.dart';
import 'package:evergreen/features/auth/domain/models/user_model.dart';

void main() {
  group('RBAC — Permissions.canAccessRoute', () {
    test('Super Admin can access every role-restricted route', () {
      const routes = [
        Routes.usersList,
        Routes.createAmc,
        Routes.uploadEquipments,
        Routes.analytics,
        Routes.auditLog,
        Routes.pmSchedule,
        Routes.technicianPerformance,
      ];
      for (final r in routes) {
        expect(
          Permissions.canAccessRoute(UserRole.superAdmin, r),
          isTrue,
          reason: 'super admin should access $r',
        );
      }
    });

    test('Technician cannot access managerial routes', () {
      expect(
        Permissions.canAccessRoute(UserRole.technician, Routes.createAmc),
        isFalse,
      );
      expect(
        Permissions.canAccessRoute(UserRole.technician, Routes.usersList),
        isFalse,
      );
      expect(
        Permissions.canAccessRoute(
          UserRole.technician,
          Routes.uploadEquipments,
        ),
        isFalse,
      );
      expect(
        Permissions.canAccessRoute(UserRole.technician, Routes.analytics),
        isFalse,
      );
    });

    test('Technician can access common + their own routes', () {
      expect(
        Permissions.canAccessRoute(UserRole.technician, Routes.home),
        isTrue,
      );
      expect(
        Permissions.canAccessRoute(UserRole.technician, Routes.taskBoard),
        isTrue,
      );
      expect(
        Permissions.canAccessRoute(
          UserRole.technician,
          Routes.technicianTasks,
        ),
        isTrue,
      );
    });

    test('Client cannot manage users or AMCs', () {
      expect(
        Permissions.canAccessRoute(UserRole.client, Routes.usersList),
        isFalse,
      );
      expect(
        Permissions.canAccessRoute(UserRole.client, Routes.createAmc),
        isFalse,
      );
    });

    test('Client (POC) can view their AMCs but not renewals or users', () {
      expect(Permissions.canAccessRoute(UserRole.client, Routes.amcs), isTrue);
      expect(
        Permissions.canAccessRoute(UserRole.client, Routes.amcRenewals),
        isFalse,
      );
      expect(
        Permissions.canAccessRoute(UserRole.client, Routes.usersList),
        isFalse,
      );
    });

    test('Client Admin keeps renewals and their users list', () {
      expect(
        Permissions.canAccessRoute(UserRole.clientAdmin, Routes.amcRenewals),
        isTrue,
      );
      expect(
        Permissions.canAccessRoute(UserRole.clientAdmin, Routes.usersList),
        isTrue,
      );
    });

    test('every role can open Activity History and Change Password', () {
      for (final role in UserRole.values) {
        expect(
          Permissions.canAccessRoute(role, Routes.auditLog),
          isTrue,
          reason: '$role audit log',
        );
        expect(
          Permissions.canAccessRoute(role, Routes.changePassword),
          isTrue,
          reason: '$role change password',
        );
      }
    });

    test('All roles can access global search and task board', () {
      for (final role in UserRole.values) {
        expect(Permissions.canAccessRoute(role, Routes.globalSearch), isTrue);
        expect(Permissions.canAccessRoute(role, Routes.taskBoard), isTrue);
      }
    });
  });

  group('RBAC — capability helpers', () {
    test('only Super Admin manages users; Super Admin + Manager bulk upload',
        () {
      expect(Permissions.canManageUsers(UserRole.superAdmin), isTrue);
      expect(Permissions.canManageUsers(UserRole.manager), isFalse);
      expect(Permissions.canBulkUpload(UserRole.manager), isTrue);
      expect(Permissions.canBulkUpload(UserRole.superAdmin), isTrue);
      for (final role in [
        UserRole.seniorTechnician,
        UserRole.technician,
        UserRole.clientAdmin,
        UserRole.client,
      ]) {
        expect(Permissions.canBulkUpload(role), isFalse);
        expect(Permissions.canAccessRoute(role, Routes.uploadAmc), isFalse);
      }
      expect(
        Permissions.canAccessRoute(UserRole.manager, Routes.uploadAmc),
        isTrue,
      );
    });

    test('Super Admin + Manager manage AMCs/tasks and view analytics', () {
      for (final role in [UserRole.superAdmin, UserRole.manager]) {
        expect(Permissions.canManageAmcs(role), isTrue);
        expect(Permissions.canManageTasks(role), isTrue);
        expect(Permissions.canViewAnalytics(role), isTrue);
        expect(Permissions.canViewTechnicianPerformance(role), isTrue);
      }
    });

    test('Client is read-only', () {
      expect(Permissions.isReadOnly(UserRole.client), isTrue);
      expect(Permissions.isReadOnly(UserRole.technician), isFalse);
      expect(Permissions.canManageTasks(UserRole.client), isFalse);
    });

    test('renewals visible to admin/manager/client admin only', () {
      expect(Permissions.canViewRenewals(UserRole.superAdmin), isTrue);
      expect(Permissions.canViewRenewals(UserRole.manager), isTrue);
      expect(Permissions.canViewRenewals(UserRole.clientAdmin), isTrue);
      expect(Permissions.canViewRenewals(UserRole.client), isFalse);
      expect(Permissions.canViewRenewals(UserRole.technician), isFalse);
      expect(Permissions.canViewRenewals(UserRole.seniorTechnician), isFalse);
    });
  });

  group('RBAC — navigation and home layout', () {
    const admins = [UserRole.superAdmin, UserRole.manager];

    test('only Super Admin and Manager keep the Profile tab', () {
      for (final role in UserRole.values) {
        expect(
          Permissions.hasProfileTab(role),
          admins.contains(role),
          reason: '$role',
        );
      }
    });

    test('Change Password is in the drawer for roles without Profile', () {
      for (final role in UserRole.values) {
        expect(
          Permissions.showChangePasswordInDrawer(role),
          !admins.contains(role),
          reason: '$role',
        );
      }
    });

    test('center "+" is hidden for service engineers only', () {
      for (final role in UserRole.values) {
        expect(
          Permissions.hasCenterAction(role),
          !role.isTechnicianLevel,
          reason: '$role',
        );
      }
    });

    test('org overview + entity audit filters are admin-only', () {
      for (final role in UserRole.values) {
        expect(
          Permissions.canViewOrgOverview(role),
          admins.contains(role),
          reason: '$role overview',
        );
        expect(
          Permissions.canFilterAuditByEntity(role),
          admins.contains(role),
          reason: '$role audit filters',
        );
        expect(Permissions.canViewAuditLog(role), isTrue, reason: '$role');
      }
    });
  });

  group('RBAC — new roles (Senior Technician, Client Admin)', () {
    test('there are six roles', () {
      expect(UserRole.values.length, 6);
    });

    test('Senior Technician can assign tasks and view performance', () {
      expect(Permissions.canAssignTasks(UserRole.seniorTechnician), isTrue);
      expect(
        Permissions.canViewTechnicianPerformance(UserRole.seniorTechnician),
        isTrue,
      );
    });

    test('Senior Technician cannot manage AMCs/users or bulk upload', () {
      expect(Permissions.canManageAmcs(UserRole.seniorTechnician), isFalse);
      expect(Permissions.canManageUsers(UserRole.seniorTechnician), isFalse);
      expect(Permissions.canBulkUpload(UserRole.seniorTechnician), isFalse);
    });

    test('Senior Technician can reach assign + performance routes', () {
      expect(
        Permissions.canAccessRoute(
          UserRole.seniorTechnician,
          Routes.assignTasks,
        ),
        isTrue,
      );
      expect(
        Permissions.canAccessRoute(
          UserRole.seniorTechnician,
          Routes.technicianPerformance,
        ),
        isTrue,
      );
      expect(
        Permissions.canAccessRoute(
          UserRole.seniorTechnician,
          Routes.createAmc,
        ),
        isFalse,
      );
    });

    test('Client Admin manages their users but stays read-only on ops', () {
      expect(Permissions.canManageUsers(UserRole.clientAdmin), isTrue);
      expect(Permissions.isReadOnly(UserRole.clientAdmin), isTrue);
      expect(Permissions.canManageTasks(UserRole.clientAdmin), isFalse);
      expect(Permissions.canManageAmcs(UserRole.clientAdmin), isFalse);
    });

    test('Client Admin can view renewals and audit log', () {
      expect(Permissions.canViewRenewals(UserRole.clientAdmin), isTrue);
      expect(Permissions.canViewAuditLog(UserRole.clientAdmin), isTrue);
    });

    test('role helper groupings are correct', () {
      expect(UserRole.seniorTechnician.isTechnicianLevel, isTrue);
      expect(UserRole.technician.isTechnicianLevel, isTrue);
      expect(UserRole.clientAdmin.isClientSide, isTrue);
      expect(UserRole.client.isClientSide, isTrue);
      expect(UserRole.manager.isTechnicianLevel, isFalse);
      expect(UserRole.manager.isClientSide, isFalse);
    });
  });

  group('UserRole serialization', () {
    test('key round-trips through fromKey', () {
      for (final role in UserRole.values) {
        expect(UserRoleX.fromKey(role.key), role);
      }
    });

    test('unknown key defaults to least-privileged client', () {
      expect(UserRoleX.fromKey('nonsense'), UserRole.client);
      expect(UserRoleX.fromKey(null), UserRole.client);
    });

    test('unknown role gets no role-specific routes', () {
      expect(
        Permissions.canAccessRoute(
          UserRoleX.fromKey('nonsense'),
          Routes.usersList,
        ),
        isFalse,
      );
      expect(
        Permissions.canAccessRoute(UserRoleX.fromKey(null), Routes.amcRenewals),
        isFalse,
      );
    });

    test('backend access levels map to roles', () {
      expect(
        UserRoleX.fromBackend('eg_super_admin', null),
        UserRole.superAdmin,
      );
      expect(UserRoleX.fromBackend('eg_admin', null), UserRole.manager);
      expect(
        UserRoleX.fromBackend('technician', UserRoleX.seniorDesignation),
        UserRole.seniorTechnician,
      );
      expect(UserRoleX.fromBackend('technician', null), UserRole.technician);
      expect(UserRoleX.fromBackend('client_admin', null), UserRole.clientAdmin);
      expect(UserRoleX.fromBackend('others', null), UserRole.client);
    });

    test('labels are human readable', () {
      expect(UserRole.superAdmin.label, 'Super Admin');
      expect(UserRole.manager.label, 'Manager');
      expect(UserRole.seniorTechnician.label, 'Senior Service Engineer');
      expect(UserRole.technician.label, 'Junior Service Engineer');
    });

    test('no role label says "Technician"', () {
      for (final role in UserRole.values) {
        expect(role.label.toLowerCase(), isNot(contains('technician')));
      }
    });

    test('junior designation is the new value; legacy value still parses', () {
      expect(UserRoleX.juniorDesignation, 'Junior Service Engineer');
      expect(UserRole.technician.designation, 'Junior Service Engineer');
      expect(
        UserRoleX.fromBackend('technician', 'Junior Service Engineer'),
        UserRole.technician,
      );
      expect(
        UserRoleX.fromBackend('technician', 'Junior Technician'),
        UserRole.technician,
      );
      expect(UserRoleX.isJuniorDesignation('Junior Technician'), isTrue);
      expect(UserRoleX.isJuniorDesignation('Junior Service Engineer'), isTrue);
      expect(UserRoleX.isJuniorDesignation('Senior Service Engineer'), isFalse);
    });
  });

  group('RBAC — Create Individual Task', () {
    test('only Super Admin and Manager may create individual tasks', () {
      for (final role in UserRole.values) {
        final allowed = role == UserRole.superAdmin || role == UserRole.manager;
        expect(
          Permissions.canCreateIndividualTask(role),
          allowed,
          reason: '$role capability',
        );
        expect(
          Permissions.canAccessRoute(role, Routes.createIndividualTask),
          allowed,
          reason: '$role route',
        );
      }
    });

    test('route path', () {
      expect(Routes.createIndividualTask, '/create-individual-task');
    });
  });

  group('User model JSON', () {
    test('toJson/fromJson preserves role', () {
      const user = User(
        id: 'u1',
        email: '9999999999',
        name: 'Test',
        role: UserRole.manager,
      );
      final restored = User.fromJson(user.toJson());
      expect(restored.role, UserRole.manager);
      expect(restored.id, 'u1');
      expect(restored.name, 'Test');
    });

    test('copyWith changes only the role', () {
      const user = User(id: 'u1', email: 'e', name: 'N');
      final updated = user.copyWith(role: UserRole.manager);
      expect(updated.role, UserRole.manager);
      expect(updated.name, 'N');
      expect(user.role, UserRole.client); // original unchanged
    });
  });
}
