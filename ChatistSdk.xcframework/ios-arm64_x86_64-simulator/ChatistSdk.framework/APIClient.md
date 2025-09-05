# APIClient Documentation

The `APIClient` is the core networking component of the Chatist Swift SDK that provides methods for interacting with the Chatist customer support API. It handles all communication between your iOS app and the Chatist backend services.

## Overview

The APIClient is implemented as a struct with closure-based functions that provide async/await support for all network operations. It automatically handles authentication using API keys and supports both regular JSON requests and multipart form data for file uploads.

## Configuration

The APIClient uses the shared instance (`APIClient.shared`) which is automatically configured with:
- API URL from environment or Chatist configuration
- API key from Chatist configuration
- URLSession for network requests

## Available Functions

### 1. getBranding

Retrieves the branding configuration for your chat interface, including colors, fonts, and logos for both light and dark themes.

**Signature:**
```swift
var getBranding: (UpdatedAt) async throws -> BrandingDto?
```

**Parameters:**
- `updatedAt: String?` - Optional timestamp to check for updates since last fetch

**Returns:**
- `BrandingDto?` - Branding configuration or nil if no updates available

**Usage Example:**
```swift
do {
    // Get latest branding
    let branding = try await APIClient.shared.getBranding(nil)
    
    // Check for updates since specific date
    let updatedBranding = try await APIClient.shared.getBranding("2025-01-01 12:00:00")
    
    if let branding = branding {
        // Apply branding colors
        primaryColor = Color(hex: branding.primaryLight)
        backgroundColor = Color(hex: branding.chatBackgroundLight)
    }
} catch {
    print("Failed to fetch branding: \(error)")
}
```

### 2. createTicket

Creates a new support ticket with an initial message and optional file attachments.

**Signature:**
```swift
var createTicket: (CreateTicketDto, [AttachmentDto]?) async throws -> TicketDto
```

**Parameters:**
- `data: CreateTicketDto` - Ticket creation data including message, channel, and device info
- `attachments: [AttachmentDto]?` - Optional array of file attachments

**Returns:**
- `TicketDto` - The created ticket with its ID and initial state

**Usage Example:**
```swift
do {
    // Create device info
    let deviceInfo = DeviceInfoDto(
        deviceModel: UIDevice.current.model,
        deviceName: UIDevice.current.name,
        osVersion: UIDevice.current.systemVersion,
        appVersion: "1.0.0",
        appBuild: "100",
        screenWidth: Int(UIScreen.main.bounds.width),
        screenHeight: Int(UIScreen.main.bounds.height),
        batteryLevel: UIDevice.current.batteryLevel,
        batteryState: "charging",
        locale: Locale.current.identifier,
        timezone: TimeZone.current.identifier
    )
    
    // Create ticket data
    let ticketData = CreateTicketDto(
        message: "I need help with my account",
        channel: "ios",
        deviceInfo: deviceInfo
    )
    
    // Optional: Add attachments
    let imageData = UIImage(named: "screenshot")?.pngData()
    let attachments = imageData.map { [AttachmentDto(
        name: "screenshot.png",
        mimeType: "image/png",
        data: $0
    )] }
    
    let ticket = try await APIClient.shared.createTicket(ticketData, attachments)
    print("Created ticket with ID: \(ticket.id)")
    
} catch {
    print("Failed to create ticket: \(error)")
}
```

### 3. getTicket

Retrieves detailed information about a specific ticket, including all messages and schedules.

**Signature:**
```swift
var getTicket: (TicketID) async throws -> TicketDto
```

**Parameters:**
- `ticketID: String` - The unique identifier of the ticket

**Returns:**
- `TicketDto` - Complete ticket information including messages and schedules

**Usage Example:**
```swift
do {
    let ticket = try await APIClient.shared.getTicket("ticket_123")
    
    print("Ticket state: \(ticket.state)")
    print("Assigned to: \(ticket.assignee)")
    print("Message count: \(ticket.messages.count)")
    
    // Display messages
    for message in ticket.messages {
        print("\(message.sender.name): \(message.content)")
    }
    
} catch {
    print("Failed to fetch ticket: \(error)")
}
```

### 4. getTickets

Retrieves a list of all tickets with preview information including the last message.

**Signature:**
```swift
var getTickets: () async throws -> [TicketPreviewDto]
```

**Parameters:**
- None

**Returns:**
- `[TicketPreviewDto]` - Array of ticket previews

**Usage Example:**
```swift
do {
    let tickets = try await APIClient.shared.getTickets()
    
    for ticketPreview in tickets {
        print("Ticket \(ticketPreview.id): \(ticketPreview.state)")
        print("Last message: \(ticketPreview.lastMessage.content)")
    }
    
} catch {
    print("Failed to fetch tickets: \(error)")
}
```

### 5. sendMessage

Sends a new message to an existing ticket with optional file attachments.

**Signature:**
```swift
var sendMessage: (TicketID, SendMessageDto) async throws -> MessageDto
```

**Parameters:**
- `ticketID: String` - The ID of the ticket to send the message to
- `data: SendMessageDto` - Message data including content and optional attachments

**Returns:**
- `MessageDto` - The sent message with its ID and metadata

**Usage Example:**
```swift
do {
    // Send a simple text message
    let messageData = SendMessageDto(message: "Thank you for your help!")
    let message = try await APIClient.shared.sendMessage("ticket_123", messageData)
    
    // Send message with attachments
    let imageData = UIImage(named: "screenshot")?.jpegData(compressionQuality: 0.8)
    let attachments = imageData.map { [AttachmentDto(
        name: "screenshot.jpg",
        mimeType: "image/jpeg",
        data: $0
    )] }
    
    let messageWithAttachment = SendMessageDto(
        message: "Here's a screenshot of the issue",
        attachments: attachments
    )
    
    let sentMessage = try await APIClient.shared.sendMessage("ticket_123", messageWithAttachment)
    print("Message sent with ID: \(sentMessage.id)")
    
} catch {
    print("Failed to send message: \(error)")
}
```

### 6. updateCustomer

Updates customer information such as email and original ID.

**Signature:**
```swift
var updateCustomer: (UpdateCustomerDto) async throws -> Void
```

**Parameters:**
- `data: UpdateCustomerDto` - Customer update data

**Returns:**
- `Void` - No return value on success

**Usage Example:**
```swift
do {
    let customerUpdate = UpdateCustomerDto(
        email: "newemail@example.com",
        originalId: "user_12345"
    )
    
    try await APIClient.shared.updateCustomer(customerUpdate)
    print("Customer information updated successfully")
    
} catch {
    print("Failed to update customer: \(error)")
}
```

### 7. updateDevice

Updates device information such as device token for push notifications.

**Signature:**
```swift
var updateDevice: (UpdateDeviceDto) async throws -> Void
```

**Parameters:**
- `data: UpdateDeviceDto` - Device update data

**Returns:**
- `Void` - No return value on success

**Usage Example:**
```swift
do {
    let deviceUpdate = UpdateDeviceDto(
        originalId: "device_67890",
        deviceToken: "apns_token_string"
    )
    
    try await APIClient.shared.updateDevice(deviceUpdate)
    print("Device information updated successfully")
    
} catch {
    print("Failed to update device: \(error)")
}
```

## Data Transfer Objects (DTOs)

### BrandingDto
Contains theming and branding information for both light and dark modes:
```swift
struct BrandingDto {
    let primaryLight: String        // Primary color for light mode
    let accentLight: String         // Accent color for light mode
    let chatBackgroundLight: String // Chat background for light mode
    let fontColorBasicLight: String // Basic font color for light mode
    // ... additional color properties for light/dark modes
    let logoLight: String?          // Optional logo URL for light mode
    let logoDark: String?           // Optional logo URL for dark mode
    let updatedAt: String          // Last update timestamp
}
```

### CreateTicketDto
Data required to create a new ticket:
```swift
struct CreateTicketDto {
    let message: String            // Initial message content
    let channel: String           // Channel identifier (e.g., "ios")
    let deviceInfo: DeviceInfoDto // Device information
}
```

### TicketDto
Complete ticket information:
```swift
struct TicketDto {
    let id: String                 // Unique ticket identifier
    var state: String             // Ticket state (e.g., "open", "closed")
    var assignee: String          // Assigned agent name
    var messages: [MessageDto]    // All messages in the ticket
    var schedules: [ScheduleDto]  // Scheduled actions
}
```

### MessageDto
Individual message information:
```swift
struct MessageDto {
    let id: String               // Unique message identifier
    let ticketId: String        // Parent ticket ID
    let sender: SenderDto       // Message sender information
    let content: String         // Message content
    let isRead: Bool           // Read status
    let timestamp: String      // When the message was sent
    let attachments: [String]? // Optional attachment URLs
}
```

### AttachmentDto
File attachment data:
```swift
struct AttachmentDto {
    let name: String      // File name
    let mimeType: String  // MIME type (e.g., "image/png")
    let data: Data       // File data
}
```

### SendMessageDto
Data for sending a new message:
```swift
struct SendMessageDto {
    let message: String              // Message content
    let attachments: [AttachmentDto]? // Optional file attachments
}
```

### UpdateCustomerDto
Customer update information:
```swift
struct UpdateCustomerDto {
    let email: String?      // Optional email update
    let originalId: String? // Optional original ID update
}
```

### UpdateDeviceDto
Device update information:
```swift
struct UpdateDeviceDto {
    let originalId: String? // Optional device original ID
    let deviceToken: String // APNs device token
}
```

### DeviceInfoDto
Comprehensive device information:
```swift
struct DeviceInfoDto {
    let deviceModel: String    // Device model (e.g., "iPhone14,2")
    let deviceName: String     // Device name (e.g., "John's iPhone")
    let osVersion: String      // iOS version
    let appVersion: String     // App version
    let appBuild: String       // App build number
    let screenWidth: Int       // Screen width in points
    let screenHeight: Int      // Screen height in points
    let batteryLevel: Float    // Battery level (0.0-1.0)
    let batteryState: String   // Battery state description
    let locale: String         // Device locale
    let timezone: String       // Device timezone
}
```

## Error Handling

All APIClient functions are async and can throw errors. Common error scenarios include:

- **Network connectivity issues**: No internet connection or server unreachable
- **Authentication errors**: Invalid or expired API key
- **Validation errors**: Invalid data format or missing required fields
- **Server errors**: Internal server errors or rate limiting

**Example Error Handling:**
```swift
do {
    let ticket = try await APIClient.shared.getTicket("ticket_123")
    // Handle success
} catch let error as APIError {
    switch error {
    case .unauthorized:
        // Handle authentication error
        print("API key is invalid or expired")
    case .notFound:
        // Handle not found error
        print("Ticket not found")
    case .serverError(let message):
        // Handle server error
        print("Server error: \(message)")
    }
} catch {
    // Handle other errors
    print("Unexpected error: \(error)")
}
```

## Mock Support

In DEBUG builds, the APIClient provides mock implementations for testing and SwiftUI previews:

```swift
#if DEBUG
let mockClient = APIClient.mock
// Use mock client for testing
#endif
```

## Best Practices

1. **Error Handling**: Always wrap API calls in do-catch blocks
2. **Loading States**: Show loading indicators during async operations
3. **Retry Logic**: Implement retry mechanisms for transient failures
4. **Caching**: Cache branding and ticket data when appropriate
5. **Background Updates**: Use background app refresh for checking new messages
6. **File Size Limits**: Validate attachment sizes before upload
7. **Network Efficiency**: Use the `updatedAt` parameter for branding to avoid unnecessary downloads

## Integration Example

Here's a complete example of integrating the APIClient in a SwiftUI view:

```swift
struct TicketListView: View {
    @State private var tickets: [TicketPreviewDto] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            List(tickets) { ticket in
                TicketRow(ticket: ticket)
            }
            .navigationTitle("Support Tickets")
            .refreshable {
                await loadTickets()
            }
            .task {
                await loadTickets()
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    private func loadTickets() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            tickets = try await APIClient.shared.getTickets()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load tickets: \(error.localizedDescription)"
        }
    }
}
``` 