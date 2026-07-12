## ADDED Requirements

### Requirement: Camera and gallery platform declarations
The mobile application SHALL declare the platform permissions and user-facing purpose descriptions required to capture a clinical image or select one from the device gallery.

#### Scenario: iOS user opens the camera
- **WHEN** an iOS user selects camera capture for the first time
- **THEN** the operating system displays the BucalScan AI camera-purpose description before granting or denying access

#### Scenario: iOS user opens the gallery
- **WHEN** an iOS user selects an image from the photo library for the first time
- **THEN** the operating system displays the BucalScan AI photo-library-purpose description before granting or denying access

#### Scenario: Permission is denied
- **WHEN** the operating system denies camera or gallery access
- **THEN** the application explains that permission is required for the selected action and remains usable for other permitted actions

### Requirement: Consistent mobile product identity
Supported mobile platform metadata SHALL identify the application as BucalScan AI rather than a legacy product name.

#### Scenario: Application is installed
- **WHEN** the application appears on a supported device launcher or system permission prompt
- **THEN** the displayed product name is BucalScan AI
