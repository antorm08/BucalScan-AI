enum MembershipStatus { pending, active, rejected, inactive }

class ClinicalWorkspace {
  final String id;
  final String name;
  final String type;
  final String status;
  final MembershipStatus membershipStatus;
  final String? role;

  const ClinicalWorkspace({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.membershipStatus,
    this.role,
  });

  bool get canEnter =>
      status == 'active' && membershipStatus == MembershipStatus.active;
}

class Patient {
  final String id;
  final String clinicalCode;
  final String fullName;
  final String? identityDocument;

  const Patient({
    required this.id,
    required this.clinicalCode,
    required this.fullName,
    this.identityDocument,
  });
}

class OralLesion {
  final String id;
  final String anatomicalSite;
  final String status;
  final String temporalDescription;
  final String? notes;

  const OralLesion({
    required this.id,
    required this.anatomicalSite,
    required this.status,
    required this.temporalDescription,
    this.notes,
  });
}
