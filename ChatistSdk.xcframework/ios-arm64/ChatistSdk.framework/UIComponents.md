# UI Components Documentation

The Chatist Swift SDK provides a comprehensive set of SwiftUI components for building customer support chat interfaces. These components are designed to work seamlessly together while maintaining customizable theming and responsive design.

## Overview

The UI components are organized into several categories:
- **Chat Interface**: Core messaging and conversation components
- **Media Components**: Image handling and display components  
- **Input Components**: User input and interaction components
- **Layout Components**: Container and structural components

All components use the `ColorScheme.shared` theming system and integrate with the SDK's data management layer through SwiftUI environments.

## Chat Interface Components

### MessageItem

A SwiftUI view that displays individual messages in a chat conversation with support for different sender types, attachments, and custom styling.

**Features:**
- Differentiated styling for customer, AI agent, and human agent messages
- Profile picture display with fallback icons
- Image attachment support with tap-to-expand functionality
- Timestamp and sender information
- Custom bubble shapes and colors

**Usage Example:**
```swift
struct ChatView: View {
    @Namespace private var imageNamespace
    @State private var messageData = MessageData()
    let message: MessageDto
    
    var body: some View {
        MessageItem(namespace: imageNamespace, message: message)
            .environment(messageData)
    }
}

// With custom styling
MessageItem(namespace: imageNamespace, message: message)
    .environment(messageData)
    .padding(.horizontal, 16)
```

**Key Properties:**
- `namespace: Namespace.ID` - For image transition animations
- `message: MessageDto` - The message data to display

**Styling Behavior:**
- Customer messages: Aligned right with `bubbleUser` background
- AI Agent messages: Shows robot emoji avatar
- Human Agent messages: Shows profile picture or default icon
- Attachments: Displays as tappable thumbnails

### MessageList

A scrollable list container that displays a conversation's messages with automatic scrolling and real-time updates.

**Features:**
- Automatic scroll to bottom on new messages
- Keyboard-aware scrolling
- Real-time message updates via NotificationCenter
- Closed ticket status indicator
- Custom list styling with hidden separators

**Usage Example:**
```swift
struct ConversationView: View {
    @Namespace private var imageNamespace
    @Environment(TicketData.self) var ticketData
    
    var body: some View {
        VStack {
            MessageList(namespace: imageNamespace)
                .environment(ticketData)
        }
    }
}
```

**Integration:**
```swift
// Automatic scrolling on keyboard appearance
MessageList(namespace: imageNamespace)
    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
        // Handles automatic scrolling
    }
```

### AITypingindicator

An animated component that shows when the AI agent is typing a response.

**Features:**
- Animated typing dots with wave effect
- Robot emoji avatar
- Localized "AI is typing" text
- Capsule-shaped bubble design
- Automatic infinite animation loop

**Usage Example:**
```swift
struct ChatView: View {
    @State private var isAITyping = false
    
    var body: some View {
        VStack {
            MessageList(namespace: imageNamespace)
            
            if isAITyping {
                AITypingindicator()
                    .transition(.opacity)
            }
            
            Composer()
        }
    }
}

// Toggle typing indicator
func sendMessage() async {
    isAITyping = true
    await apiClient.sendMessage(ticketId, messageData)
    isAITyping = false
}
```

### Composer

A message composition interface with text input, image attachment, and send functionality.

**Features:**
- Multi-line text input with placeholder
- Image attachment picker integration
- Send button with loading states
- Horizontal image thumbnail display
- Integrated with TicketData environment

**Usage Example:**
```swift
struct ChatInterface: View {
    @Environment(TicketData.self) var ticketData
    
    var body: some View {
        VStack {
            MessageList(namespace: imageNamespace)
            Composer()
                .environment(ticketData)
        }
    }
}

// Custom composer with additional actions
VStack {
    ImageThumbnails() // Shows selected images
    
    HStack {
        TextField("Type a message...", text: $ticketData.message)
        PickImagesButton()
        SendMessageButton()
    }
}
.environment(ticketData)
```

## Media Components

### CachedAsyncImage

A high-performance async image component with automatic caching using URLCache.

**Features:**
- Automatic image caching with URLCache
- Customizable content and placeholder views
- Memory and disk cache management
- Generic design for flexible usage
- Async/await loading

**Usage Example:**
```swift
// Basic usage with default placeholder
CachedAsyncImage(url: URL(string: "https://example.com/image.jpg")) { image in
    image
        .resizable()
        .aspectRatio(contentMode: .fit)
}

// With custom placeholder
CachedAsyncImage(
    url: profileImageURL,
    content: { image in
        image
            .resizable()
            .clipShape(Circle())
            .frame(width: 50, height: 50)
    },
    placeholder: {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 50, height: 50)
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.gray)
            )
    }
)
```

**Performance Benefits:**
- Reduces network requests through caching
- Improves scroll performance in lists
- Automatic cache size management

### ImageThumbnail

A component for displaying image thumbnails with a remove button overlay.

**Features:**
- Fixed 150x150 frame with aspect fill
- Overlay remove button with semi-transparent background
- Corner radius styling
- Custom remove action callback

**Usage Example:**
```swift
struct AttachmentPreview: View {
    @State private var selectedImages: [UIImage] = []
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(selectedImages.indices, id: \.self) { index in
                    ImageThumbnail(
                        image: selectedImages[index],
                        onRemove: {
                            selectedImages.remove(at: index)
                        }
                    )
                }
            }
            .padding()
        }
    }
}

// Integration with data management
ImageThumbnail(
    image: image,
    onRemove: {
        ticketData.attachments.remove(attachment)
    }
)
```

### ImageThumbnails

A horizontal scrolling container for displaying multiple image thumbnails.

**Features:**
- Horizontal scroll view layout
- Automatic visibility based on attachment count
- Integration with TicketData environment
- Proper spacing and padding

**Usage Example:**
```swift
struct MessageComposer: View {
    @Environment(TicketData.self) var ticketData
    
    var body: some View {
        VStack {
            // Shows thumbnails only when attachments exist
            ImageThumbnails()
            
            HStack {
                TextField("Message", text: $ticketData.message)
                PickImagesButton()
                SendMessageButton()
            }
        }
        .environment(ticketData)
    }
}
```

### ImageViewer

A full-screen image viewer with matched geometry animations.

**Features:**
- Full-screen overlay presentation
- Tap-to-dismiss functionality
- Smooth transition animations with `matchedGeometryEffect`
- Dark background overlay
- Integration with MessageData environment

**Usage Example:**
```swift
struct ChatView: View {
    @Namespace private var imageNamespace
    @Environment(MessageData.self) var messageData
    
    var body: some View {
        ZStack {
            // Chat interface
            VStack {
                MessageList(namespace: imageNamespace)
                Composer()
            }
            
            // Full-screen image viewer
            ImageViewer(namespace: imageNamespace)
                .environment(messageData)
        }
    }
}

// Trigger image viewer
Button(action: {
    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
        messageData.selectedAttachment = imageURL
    }
}) {
    CachedAsyncImage(url: imageURL) { image in
        image
            .resizable()
            .matchedGeometryEffect(id: imageURL, in: imageNamespace)
    }
}
```

## Input Components

### PickImagesButton

A button component that opens the system photo picker for selecting multiple images.

**Features:**
- PhotosPicker integration for image selection
- Multiple image selection support
- Automatic data conversion to AttachmentDto
- Loading state management
- ULID generation for unique identifiers

**Usage Example:**
```swift
struct CustomComposer: View {
    @Environment(TicketData.self) var ticketData
    
    var body: some View {
        HStack {
            TextField("Type message...", text: $ticketData.message)
            
            PickImagesButton()
                .disabled(ticketData.sendMessageInFlight)
            
            SendMessageButton()
        }
        .environment(ticketData)
    }
}

// Custom styling
PickImagesButton()
    .foregroundColor(.blue)
    .background(Circle().fill(.blue.opacity(0.1)))
```

**Integration Details:**
- Automatically adds selected images to `ticketData.attachments`
- Handles image data conversion asynchronously
- Supports MIME type detection
- Generates unique file names using ULID

### SendMessageButton

A context-aware send button that shows loading states and handles message sending.

**Features:**
- Automatic loading state display with ProgressView
- Integrated with TicketData for send functionality
- Disabled state management
- Custom styling with ColorScheme integration

**Usage Example:**
```swift
struct MessageInput: View {
    @Environment(TicketData.self) var ticketData
    
    var body: some View {
        HStack {
            TextField("Message", text: $ticketData.message)
                .textFieldStyle(.roundedBorder)
            
            SendMessageButton()
                .disabled(ticketData.message.isEmpty)
        }
        .environment(ticketData)
    }
}

// Custom send button with additional validation
Button(action: {
    Task {
        if !ticketData.message.isEmpty {
            await ticketData.sendDidTap()
        }
    }
}) {
    if ticketData.sendMessageInFlight {
        ProgressView()
            .tint(ColorScheme.shared.accent)
    } else {
        Image(systemName: "paperplane.fill")
            .foregroundColor(ColorScheme.shared.accent)
    }
}
.disabled(ticketData.sendButtonDisabled || ticketData.message.isEmpty)
```

## Layout Components

### TicketItem

A component for displaying ticket previews in lists with sender information and read status.

**Features:**
- Sender avatar display with type-specific styling
- Last message preview with truncation
- Read/unread status indicator
- Timestamp with relative formatting
- Closed ticket status indication
- Responsive layout with proper spacing

**Usage Example:**
```swift
struct TicketRow: View {
    let ticket: TicketPreviewDto
    let onTap: (TicketPreviewDto) -> Void
    
    var body: some View {
        TicketItem(ticket: ticket)
            .onTapGesture {
                onTap(ticket)
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 2)
    }
}

// In a list
List(tickets) { ticket in
    TicketItem(ticket: ticket)
        .onTapGesture {
            selectedTicket = ticket
        }
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
}
```

**Visual Elements:**
- **Closed tickets**: Checkmark circle icon
- **AI messages**: Robot emoji in circular background
- **Human agents**: Profile picture or default person icon
- **Unread indicator**: Red dot for unread messages from agents

### TicketList

A container component for displaying multiple tickets with proper spacing and animations.

**Features:**
- Vertical stack layout with consistent spacing
- Header title with localization support
- Tap gesture handling for ticket selection
- Smooth animations for list updates
- Proper padding and background styling

**Usage Example:**
```swift
struct SupportView: View {
    @State private var tickets: [TicketPreviewDto] = []
    @State private var selectedTicket: TicketPreviewDto?
    
    var body: some View {
        NavigationView {
            TicketList(
                tickets: tickets,
                action: { ticket in
                    selectedTicket = ticket
                }
            )
            .navigationTitle("Support")
            .task {
                await loadTickets()
            }
        }
        .sheet(item: $selectedTicket) { ticket in
            TicketDetailView(ticket: ticket)
        }
    }
    
    private func loadTickets() async {
        tickets = try await APIClient.shared.getTickets()
    }
}

// Custom ticket list with search
VStack {
    SearchBar(text: $searchText)
    
    TicketList(
        tickets: filteredTickets,
        action: { ticket in
            navigationPath.append(ticket)
        }
    )
}
```

### NewTicketButton

A call-to-action button for creating new support tickets.

**Features:**
- Title and subtitle text display
- Prominent styling with primary colors
- Paper plane icon indicator
- Custom action callback
- Responsive layout with proper spacing

**Usage Example:**
```swift
struct SupportLanding: View {
    @State private var showNewTicket = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("How can we help?")
                .font(.largeTitle)
                .bold()
            
            NewTicketButton(
                title: "Send us a message",
                subtitle: "We typically reply in a few minutes.",
                action: {
                    showNewTicket = true
                }
            )
            
            ExistingTicketsButton()
        }
        .padding()
        .sheet(isPresented: $showNewTicket) {
            NewTicketView()
        }
    }
}

// Different contexts
NewTicketButton(
    title: "Report a Bug",
    subtitle: "Tell us what went wrong",
    action: {
        // Create bug report ticket
        createTicket(type: .bug)
    }
)

NewTicketButton(
    title: "Feature Request",
    subtitle: "Share your ideas with us",
    action: {
        // Create feature request ticket
        createTicket(type: .feature)
    }
)
```

## Environment Integration

### TicketData Environment

Most components integrate with the TicketData environment for state management:

```swift
@Environment(TicketData.self) var ticketData

// Available properties:
- ticketData.message: String               // Current message text
- ticketData.attachments: Set<AttachmentDto> // Selected attachments
- ticketData.sendMessageInFlight: Bool     // Send operation status
- ticketData.sendButtonDisabled: Bool      // Send button state
- ticketData.ticket: TicketDto?           // Current ticket data

// Available methods:
- await ticketData.sendDidTap()           // Send message action
- await ticketData.fetch(ticketId:)       // Fetch ticket data
```

### MessageData Environment

Image viewing components use MessageData:

```swift
@Environment(MessageData.self) var messageData

// Available properties:
- messageData.selectedAttachment: URL?     // Currently viewed image
```

## Theming and Customization

All components use the ColorScheme.shared theming system:

```swift
// Color properties used across components:
ColorScheme.shared.primary          // Primary brand color
ColorScheme.shared.accent           // Accent color for interactive elements
ColorScheme.shared.chatBackground   // Chat area background
ColorScheme.shared.bubbleUser       // Customer message bubbles
ColorScheme.shared.bubbleAgent      // Agent message bubbles
ColorScheme.shared.fontBasic        // Basic text color
ColorScheme.shared.fontUserBubble   // Customer message text
ColorScheme.shared.fontAgentBubble  // Agent message text
```

**Custom Theming Example:**
```swift
// Apply custom colors before using components
ColorScheme.shared.primary = Color.blue
ColorScheme.shared.accent = Color.orange
ColorScheme.shared.bubbleUser = Color.blue.opacity(0.8)

// Components automatically use updated colors
VStack {
    MessageList(namespace: imageNamespace)
    Composer()
}
```

## Animations and Transitions

### Image Transitions

Components use `matchedGeometryEffect` for smooth image transitions:

```swift
@Namespace private var imageNamespace

// In MessageItem - thumbnail
CachedAsyncImage(url: imageURL) { image in
    image
        .matchedGeometryEffect(id: imageURL, in: imageNamespace)
}

// In ImageViewer - full screen
CachedAsyncImage(url: imageURL) { image in
    image
        .matchedGeometryEffect(id: imageURL, in: imageNamespace)
}
```

### List Animations

```swift
// Smooth list updates
TicketList(tickets: tickets, action: handleTicketTap)
    .animation(.easeOut(duration: 0.1), value: tickets)

// Message list transitions
MessageList(namespace: imageNamespace)
    .transition(.opacity)
```

## Best Practices

### 1. Environment Setup

Always provide necessary environments:

```swift
VStack {
    MessageList(namespace: imageNamespace)
    Composer()
}
.environment(ticketData)
.environment(messageData)
```

### 2. Namespace Management

Use consistent namespaces for image transitions:

```swift
struct ChatView: View {
    @Namespace private var imageNamespace
    
    var body: some View {
        ZStack {
            // Use same namespace throughout
            MessageList(namespace: imageNamespace)
            ImageViewer(namespace: imageNamespace)
        }
    }
}
```

### 3. Performance Optimization

```swift
// Use CachedAsyncImage for better performance
CachedAsyncImage(url: profileURL) { image in
    image.resizable()
} placeholder: {
    ProgressView()
}

// Lazy loading in lists
LazyVStack {
    ForEach(messages) { message in
        MessageItem(namespace: imageNamespace, message: message)
    }
}
```

### 4. Accessibility

```swift
// Add accessibility labels
PickImagesButton()
    .accessibilityLabel("Attach images")
    .accessibilityHint("Select images from photo library")

SendMessageButton()
    .accessibilityLabel("Send message")
    .accessibilityHint("Send the current message")
```

### 5. Error Handling

```swift
struct SafeMessageList: View {
    @Environment(TicketData.self) var ticketData
    
    var body: some View {
        Group {
            if let ticket = ticketData.ticket {
                MessageList(namespace: imageNamespace)
            } else if ticketData.fetchTicketInFlight {
                ProgressView("Loading messages...")
            } else {
                Text("Unable to load messages")
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

## Complete Integration Example

Here's a complete example showing how to integrate multiple components:

```swift
struct ChatInterface: View {
    @Namespace private var imageNamespace
    @State private var ticketData = TicketData()
    @State private var messageData = MessageData()
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Message list
                    MessageList(namespace: imageNamespace)
                        .environment(ticketData)
                        .environment(messageData)
                    
                    // AI typing indicator
                    if ticketData.isAITyping {
                        AITypingindicator()
                            .transition(.opacity)
                    }
                    
                    // Message composer
                    Composer()
                        .environment(ticketData)
                }
                .background(ColorScheme.shared.chatBackground)
                
                // Full-screen image viewer
                ImageViewer(namespace: imageNamespace)
                    .environment(messageData)
            }
        }
        .task {
            await ticketData.fetch(ticketId: "ticket_123")
        }
    }
}

struct TicketListInterface: View {
    @State private var tickets: [TicketPreviewDto] = []
    @State private var selectedTicket: TicketPreviewDto?
    
    var body: some View {
        NavigationView {
            VStack {
                // New ticket button
                NewTicketButton(
                    title: "Start a conversation",
                    subtitle: "We're here to help!",
                    action: {
                        // Create new ticket
                    }
                )
                .padding()
                
                // Existing tickets
                TicketList(
                    tickets: tickets,
                    action: { ticket in
                        selectedTicket = ticket
                    }
                )
            }
            .navigationTitle("Support")
        }
        .sheet(item: $selectedTicket) { ticket in
            ChatInterface(ticketId: ticket.id)
        }
    }
}
```