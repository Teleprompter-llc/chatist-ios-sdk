# Follow-Up Actions for Chatist Swift SDK

## Executive Summary

This document outlines critical improvements needed for the Chatist Swift SDK based on a comprehensive code review conducted on 2025-01-17. The SDK currently functions but has significant architectural issues affecting performance, reliability, and user experience.

## Priority Matrix

### 🔴 Critical (Immediate Action Required)

#### 1. Fix Notification System Architecture
**Current Issue**: The NotificationSystemIssues.md documentation is outdated and incorrectly states there are triple subscriptions. However, the real issue is the lack of real-time updates for active sessions.

**Actions**:
- [ ] Update NotificationSystemIssues.md to reflect actual implementation
- [ ] Implement WebSocket connection for active chat sessions
- [ ] Add fallback polling mechanism when WebSocket fails
- [ ] Ensure push notifications are only used when app is backgrounded

**Implementation Steps**:
```swift
// Add to APIClient.swift
var connectWebSocket: (TicketID) async throws -> AsyncStream<MessageDto>
var disconnectWebSocket: (TicketID) async -> Void

// Add to TicketData.swift
private var webSocketTask: Task<Void, Never>?

func startRealtimeUpdates() {
    webSocketTask = Task {
        let stream = try await APIClient.shared.connectWebSocket(ticketId)
        for await message in stream {
            await MainActor.run {
                self.ticket?.messages.append(message)
            }
        }
    }
}
```

#### 2. Fix AI Typing Indicator Logic
**Current Issue**: The typing indicator doesn't show when it should because `ticket.assignee` isn't updated optimistically.

**Actions**:
- [ ] Implement optimistic assignee updates when sending messages
- [ ] Add local state tracking for expected AI responses
- [ ] Create proper state machine for typing indicator

**Implementation**:
```swift
// In TicketData.swift
@Published private var expectingAIResponse = false

func send(message: String, attachments: [AttachmentDto]?) async {
    // Optimistically set AI response expectation
    if ticket?.assignee == "human agent" {
        expectingAIResponse = true
    }
    
    // Send message...
    
    // Update typing indicator logic
    var typingIndicatorVisible: Bool {
        guard let ticket else { return false }
        return expectingAIResponse || 
               (ticket.assignee == "ai agent" && 
                ticket.messages.last?.sender.type == "customer")
    }
}
```

### 🟡 High Priority (Complete within 2 weeks)

#### 3. Implement Efficient Update Mechanisms
**Current Issue**: Full ticket refetch after every message send causes unnecessary API calls and UI flickers.

**Actions**:
- [ ] Implement message-level API endpoints for incremental updates
- [ ] Add local message deduplication logic
- [ ] Implement proper diff algorithm for message lists
- [ ] Add request debouncing for rapid updates

**API Changes Needed**:
```swift
// Add to APIClient
var getMessagesSince: (TicketID, MessageID) async throws -> [MessageDto]
var getMessageUpdates: (TicketID, UpdatedAt) async throws -> MessageUpdates

struct MessageUpdates {
    let newMessages: [MessageDto]
    let updatedMessages: [MessageDto]
    let deletedMessageIds: [String]
}
```

#### 4. Add Centralized State Management
**Current Issue**: Disconnected state between views causes inconsistencies and requires manual refreshes.

**Actions**:
- [ ] Create `ChatistStore` as single source of truth
- [ ] Implement proper caching layer with TTL
- [ ] Add state synchronization between views
- [ ] Implement optimistic updates with rollback

**Architecture**:
```swift
@MainActor
final class ChatistStore: ObservableObject {
    static let shared = ChatistStore()
    
    @Published private(set) var tickets: [TicketID: TicketDto] = [:]
    @Published private(set) var ticketPreviews: [TicketPreviewDto] = []
    
    private let cache = NSCache<NSString, TicketDto>()
    
    func updateTicket(_ ticket: TicketDto) {
        tickets[ticket.id] = ticket
        cache.setObject(ticket, forKey: ticket.id as NSString)
        updateTicketPreview(from: ticket)
    }
}
```

### 🟢 Medium Priority (Complete within 1 month)

#### 5. Implement Offline Support
**Current Issue**: No offline message queue, messages fail silently when offline.

**Actions**:
- [ ] Create persistent message queue using CoreData/SQLite
- [ ] Implement retry mechanism with exponential backoff
- [ ] Add offline indicator in UI
- [ ] Sync queued messages when connection restored

**Message Queue Structure**:
```swift
struct QueuedMessage {
    let id: String
    let ticketId: String
    let content: String
    let attachments: [AttachmentDto]?
    let createdAt: Date
    let retryCount: Int
    let lastRetryAt: Date?
}

class OfflineMessageQueue {
    func enqueue(_ message: QueuedMessage)
    func dequeue() -> QueuedMessage?
    func processQueue() async
}
```

#### 6. Improve Error Handling
**Current Issue**: Network errors not properly surfaced, no user feedback for failures.

**Actions**:
- [ ] Add comprehensive error types for all failure modes
- [ ] Implement user-friendly error messages
- [ ] Add retry UI for failed operations
- [ ] Log errors for debugging (with privacy considerations)

### 🔵 Low Priority (Nice to have)

#### 7. Performance Optimizations
- [ ] Implement virtual scrolling for large message lists
- [ ] Add message pagination (load older messages on demand)
- [ ] Optimize image loading and caching
- [ ] Add performance monitoring

#### 8. Enhanced Features
- [ ] Add message search functionality
- [ ] Implement message reactions
- [ ] Add voice message support
- [ ] Implement file preview for attachments

## Testing Strategy

### Unit Tests
- [ ] Test notification handling logic
- [ ] Test message deduplication
- [ ] Test offline queue behavior
- [ ] Test state synchronization

### Integration Tests
- [ ] Test WebSocket connection lifecycle
- [ ] Test notification flow end-to-end
- [ ] Test offline-to-online transition
- [ ] Test concurrent update handling

### UI Tests
- [ ] Test typing indicator visibility
- [ ] Test message send/receive flow
- [ ] Test error state handling
- [ ] Test navigation state persistence

## Migration Plan

1. **Phase 1**: Fix critical issues without breaking changes
   - Update typing indicator logic
   - Fix notification documentation
   - Add WebSocket support (optional fallback)

2. **Phase 2**: Introduce new architecture with compatibility
   - Add ChatistStore alongside existing data classes
   - Migrate views incrementally to use central store
   - Maintain backward compatibility

3. **Phase 3**: Complete migration
   - Remove old data classes
   - Update public API if needed
   - Update documentation and examples

## Success Metrics

- **Performance**: 50% reduction in API calls per session
- **Reliability**: 99.9% message delivery success rate
- **UX**: <100ms typing indicator response time
- **Efficiency**: 75% reduction in unnecessary re-renders

## Timeline

- Week 1-2: Critical fixes (typing indicator, documentation)
- Week 3-4: WebSocket implementation
- Week 5-6: State management refactor
- Week 7-8: Offline support
- Week 9-12: Testing and optimization

## Resources Required

- 1 Senior iOS Developer (full-time for 3 months)
- 1 Backend Developer (part-time for API changes)
- 1 QA Engineer (part-time for testing)
- Access to WebSocket infrastructure
- Testing devices for various iOS versions

## Risk Mitigation

1. **Breaking Changes**: Use feature flags for gradual rollout
2. **Performance Regression**: Implement comprehensive benchmarking
3. **Compatibility Issues**: Maintain extensive device testing matrix
4. **User Disruption**: Provide migration guides and support

## Conclusion

The Chatist Swift SDK requires significant architectural improvements to meet modern standards for real-time communication apps. While the current implementation is functional, addressing these issues will greatly improve reliability, performance, and user experience. The phased approach ensures minimal disruption while delivering continuous improvements.