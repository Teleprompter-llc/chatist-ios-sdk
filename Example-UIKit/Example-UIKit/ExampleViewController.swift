import Combine
import ChatistSdk
import UIKit

class ExampleViewController: UIViewController {
    
    // MARK: Properties
    
    private let openButton = UIButton()
    private let authButtonsStack = UIStackView()
    private let loginButton = UIButton()
    private let logoutButton = UIButton()
    private let unreadLabel = UILabel()
    
    private var cancellables = Set<AnyCancellable>()
    private var notificationView: ChatistNotificationUIView?
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupObservers()
    }
}

// MARK: - Setups

extension ExampleViewController {
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.99, green: 0.90, blue: 0.54, alpha: 1.00)
        
        setupOpenButton()
        setupAuthButtonsStack()
        setupUnreadLabel()
    }
    
    private func setupOpenButton() {
        view.addSubview(openButton)
        openButton.translatesAutoresizingMaskIntoConstraints = false
        openButton.setTitle("Open Chatist", for: .normal)
        openButton.setTitleColor(.black, for: .normal)
        openButton.addTarget(self, action: #selector(openChatistTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            openButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            openButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
    private func setupAuthButtonsStack() {
        view.addSubview(authButtonsStack)
        authButtonsStack.translatesAutoresizingMaskIntoConstraints = false
        authButtonsStack.axis = .horizontal
        authButtonsStack.spacing = 20
        
        loginButton.setTitle("Login", for: .normal)
        loginButton.setTitleColor(.systemGreen, for: .normal)
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        
        logoutButton.setTitle("Logout", for: .normal)
        logoutButton.setTitleColor(.red, for: .normal)
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        
        authButtonsStack.addArrangedSubview(loginButton)
        authButtonsStack.addArrangedSubview(logoutButton)
        
        NSLayoutConstraint.activate([
            authButtonsStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            authButtonsStack.topAnchor.constraint(equalTo: openButton.bottomAnchor, constant: 20),
        ])
    }
    
    private func setupUnreadLabel() {
        view.addSubview(unreadLabel)
        unreadLabel.translatesAutoresizingMaskIntoConstraints = false
        unreadLabel.text = "Loading..."
        unreadLabel.textColor = .black
        unreadLabel.font = .systemFont(ofSize: 16, weight: .medium)
        
        NSLayoutConstraint.activate([
            unreadLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            unreadLabel.bottomAnchor.constraint(equalTo: openButton.topAnchor, constant: -20),
        ])
    }
    
    private func setupObservers() {
        Chatist.getUnreadMessagesCount()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.unreadLabel.text = "Unread messages: \(count)"
            }
            .store(in: &cancellables)
        
        Chatist.observeNotifications()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.showNotification(notification)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Functions

extension ExampleViewController {
    private func showNotification(_ notification: ChatistNotification) {
        hideNotification()
        
        let notificationView = ChatistNotificationUIView(
            notification: notification,
            onTap: { [weak self] in
                self?.hideNotification()
                Chatist.open(with: notification.ticketID)
            },
            onClose: { [weak self] in
                self?.hideNotification()
            }
        )
        
        view.addSubview(notificationView)
        self.notificationView = notificationView
        
        notificationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            notificationView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            notificationView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            notificationView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        
        notificationView.alpha = 0
        notificationView.transform = CGAffineTransform(translationX: 0, y: -20)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            notificationView.alpha = 1
            notificationView.transform = .identity
        }
    }
    
    private func hideNotification() {
        guard let notificationView = notificationView else { return }
        
        UIView.animate(withDuration: 0.2, animations: {
            notificationView.alpha = 0
            notificationView.transform = CGAffineTransform(translationX: 0, y: -20)
        }, completion: { [weak self] _ in
            notificationView.removeFromSuperview()
            self?.notificationView = nil
        })
    }
}

// MARK: - Actions

extension ExampleViewController {
    @objc private func openChatistTapped() {
        Chatist.open()
    }
    
    @objc private func loginTapped() {
        Chatist.login()
    }
    
    @objc private func logoutTapped() {
        Chatist.logout()
    }
}
