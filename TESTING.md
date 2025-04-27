# E-COMCEN Testing Guide

This guide provides instructions for testing both the E-COMCEN main application and the E-COMCEN-DSM dispatcher application.

## Testing Environment Setup

Before starting the testing process, ensure you have the following:

1. Both applications installed on separate Windows machines (or on the same machine with different user accounts)
2. Test user accounts for both admin and dispatcher roles
3. Test data for dispatches

## Test Cases for E-COMCEN (Main Application)

### 1. Authentication Testing

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Admin Login | 1. Launch E-COMCEN<br>2. Enter admin credentials<br>3. Click Login | User is logged in and directed to the dashboard |
| Invalid Login | 1. Launch E-COMCEN<br>2. Enter incorrect credentials<br>3. Click Login | Error message is displayed |
| Session Timeout | 1. Login to E-COMCEN<br>2. Leave the application idle for the configured timeout period | User is logged out and directed to the lock screen |

### 2. Dispatch Management Testing

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Create Incoming Dispatch | 1. Navigate to Dispatches<br>2. Select Incoming Dispatch<br>3. Fill in the form<br>4. Submit | New incoming dispatch is created and appears in the list |
| Create Outgoing Dispatch | 1. Navigate to Dispatches<br>2. Select Outgoing Dispatch<br>3. Fill in the form<br>4. Submit | New outgoing dispatch is created and appears in the list |
| Create Local Dispatch | 1. Navigate to Dispatches<br>2. Select Local Dispatch<br>3. Fill in the form<br>4. Submit | New local dispatch is created and appears in the list |
| Create External Dispatch | 1. Navigate to Dispatches<br>2. Select External Dispatch<br>3. Fill in the form<br>4. Submit | New external dispatch is created and appears in the list |
| Create COMCEN Log | 1. Navigate to COMCEN Log<br>2. Click Add New Log<br>3. Fill in the form<br>4. Submit | New COMCEN log is created and appears in the list |

### 3. Dispatch Tracking Testing

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Track Dispatch by Reference | 1. Navigate to Dispatch Tracking<br>2. Enter a reference number<br>3. Click Track | Dispatch details and status are displayed |
| View Dispatch Progress | 1. Track a dispatch<br>2. View the progress visualization | Progress is displayed correctly with all status updates |

### 4. User Management Testing

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Create New User | 1. Navigate to Users<br>2. Click Add User<br>3. Fill in the form<br>4. Submit | New user is created and appears in the list |
| Edit User | 1. Navigate to Users<br>2. Select a user<br>3. Click Edit<br>4. Modify details<br>5. Submit | User details are updated |
| Assign Dispatcher Role | 1. Navigate to Users<br>2. Select a user<br>3. Click Edit<br>4. Change role to Dispatcher<br>5. Submit | User role is updated to Dispatcher |

### 5. Settings Testing

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Change Language | 1. Navigate to Settings<br>2. Select Language<br>3. Choose a different language<br>4. Save | Application language is changed |
| Toggle Dark Mode | 1. Navigate to Settings<br>2. Toggle Dark Mode | Application theme changes to dark/light mode |
| Configure Security Settings | 1. Navigate to Settings<br>2. Select Security<br>3. Modify settings<br>4. Save | Security settings are updated |

## Test Cases for E-COMCEN-DSM (Dispatcher Application)

### 1. Authentication Testing

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Dispatcher Login | 1. Launch E-COMCEN-DSM<br>2. Enter dispatcher credentials<br>3. Click Login | User is logged in and directed to the dashboard |
| Invalid Login | 1. Launch E-COMCEN-DSM<br>2. Enter incorrect credentials<br>3. Click Login | Error message is displayed |
| Admin Login Attempt | 1. Launch E-COMCEN-DSM<br>2. Enter admin credentials<br>3. Click Login | Error message indicating invalid dispatcher credentials |

### 2. Dispatch Management Testing

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| View Assigned Dispatches | 1. Login to E-COMCEN-DSM<br>2. Navigate to Assigned Dispatches | Only dispatches assigned to the logged-in dispatcher are displayed |
| Update Dispatch Status | 1. Select an assigned dispatch<br>2. Click Update Status<br>3. Select a new status<br>4. Add notes and location<br>5. Submit | Dispatch status is updated |
| Complete Dispatch | 1. Select an assigned dispatch<br>2. Click Update Status<br>3. Select "Delivered" status<br>4. Fill in receiver details<br>5. Submit | Dispatch is marked as delivered and moved to completed dispatches |

### 3. Synchronization Testing

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Manual Sync | 1. Login to E-COMCEN-DSM<br>2. Click the Sync button in the app bar | Data is synchronized with the main application |
| Auto Sync | 1. Update a dispatch status<br>2. Wait for the auto-sync interval | Data is automatically synchronized with the main application |
| Verify Sync in Main App | 1. Update a dispatch in E-COMCEN-DSM<br>2. Login to E-COMCEN<br>3. View the same dispatch | Dispatch status is updated in the main application |

## Integration Testing

### 1. End-to-End Dispatch Flow

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Complete Dispatch Lifecycle | 1. Create a new dispatch in E-COMCEN<br>2. Assign it to a dispatcher<br>3. Login to E-COMCEN-DSM with the dispatcher account<br>4. Update the dispatch status multiple times<br>5. Mark as delivered<br>6. Verify in E-COMCEN | The dispatch progresses through all stages correctly and all updates are synchronized between applications |

### 2. Multi-User Testing

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Concurrent Updates | 1. Have multiple dispatchers logged in to E-COMCEN-DSM<br>2. Have an admin logged in to E-COMCEN<br>3. Make updates from different users<br>4. Sync data | All updates are correctly synchronized without conflicts |

## Performance Testing

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Load Testing | 1. Create a large number of dispatches (100+)<br>2. Measure application response time | Application remains responsive |
| Sync Performance | 1. Create a large number of updates in E-COMCEN-DSM<br>2. Trigger synchronization<br>3. Measure sync time | Synchronization completes within acceptable time limits |

## Security Testing

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Role-Based Access | 1. Login as a dispatcher<br>2. Attempt to access admin-only features | Access is denied |
| Session Management | 1. Login to either application<br>2. Close the application without logging out<br>3. Reopen the application | User is required to log in again |
| Data Protection | 1. Examine the application's data storage<br>2. Check if sensitive data is encrypted | Sensitive data is properly protected |

## Reporting Issues

When reporting issues, please include:

1. The application version
2. Steps to reproduce the issue
3. Expected vs. actual behavior
4. Screenshots if applicable
5. Error messages if any

Submit issues to the project repository or contact the development team directly.
