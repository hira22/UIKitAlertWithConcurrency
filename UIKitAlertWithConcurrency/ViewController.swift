//
//  ViewController.swift
//  UIKitAlertWithConcurrency
//
//  Created by hiraoka on 2022/01/23.
//

import UIKit

class ViewController: UIViewController {

    private var label: UILabel?

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        title = "Swift Concurrency を使ってアラートの選択を await する"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.systemBackground

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -64),
        ])


        let label = UILabel()
        label.text = "未選択"
        stackView.addArrangedSubview(label)
        self.label = label

        let button = UIButton()
        button.setTitle("アラートを表示する", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        view.addSubview(button)
        button.addTarget(self, action: #selector(buttonTapAction), for: .touchUpInside)
        stackView.addArrangedSubview(button)

    }

    @objc func buttonTapAction(_ sender: AnyObject) {
        Task { @MainActor in
            let selection = await showAlert()
            self.label?.text = selection.title
        }
    }
}

extension ViewController {

    enum AlertSelection: CaseIterable {
        case cancel
        case positive

        var title: String {
            switch self {
            case .cancel:
                return "キャンセル"
            case .positive:
                return "ポジティブ"
            }
        }

        var style: UIAlertAction.Style {
            switch self {
            case .cancel:
                return .cancel
            case .positive:
                return .default
            }
        }

        func makeAlertAction(continuation: CheckedContinuation<Self, Never>) -> UIAlertAction {
            UIAlertAction(title: self.title, style: self.style) { _ in
                continuation.resume(returning: self)
            }
        }
    }

    @MainActor
    func showAlert() async  -> AlertSelection {
        return await withCheckedContinuation { [weak self] continuation in
            let alertController = UIAlertController(title: "タイトル",
                                                    message: "メッセージ",
                                                    preferredStyle: .alert)
            for selection in AlertSelection.allCases {
                alertController.addAction(selection.makeAlertAction(continuation: continuation))
            }

            self?.present(alertController, animated: true)
        }
    }

}
