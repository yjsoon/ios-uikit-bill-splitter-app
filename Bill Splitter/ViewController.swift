import UIKit

final class ViewController: UIViewController, UITextFieldDelegate {
    // MARK: - State
    private var billAmount: Decimal = 0
    private var partySize: Int = 2
    private var currentSummary: BillModel? { didSet { updateCalculationDisplay() } }
    private var roundingStrategy: RoundingStrategy = .none {
        didSet { updateRoundingButtonUI() }
    }

    // MARK: - Header
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Eat Split"
        label.font = .preferredFont(forTextStyle: .largeTitle)
        label.textAlignment = .center
        label.textColor = .systemPink
        return label
    }()

    // MARK: - Bill Input
    private lazy var billAmountTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter bill amount (SGD)"
        textField.keyboardType = .decimalPad
        textField.borderStyle = .none
        textField.layer.cornerRadius = 12
        textField.backgroundColor = .systemGray6
        textField.textAlignment = .center
        textField.font = .systemFont(ofSize: 28, weight: .semibold)
        textField.delegate = self
        textField.accessibilityLabel = "Bill amount in Singapore dollars"
        textField.accessibilityHint = "Enter the total bill before taxes"
        return textField
    }()

    // MARK: - Tax Controls
    private lazy var serviceChargeSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.isOn = true
        toggle.addTarget(self, action: #selector(taxSettingChanged), for: .valueChanged)
        toggle.accessibilityLabel = "Service charge ten percent"
        toggle.accessibilityHint = "Toggle service charge on or off"
        return toggle
    }()

    private lazy var gstSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.isOn = true
        toggle.addTarget(self, action: #selector(taxSettingChanged), for: .valueChanged)
        toggle.accessibilityLabel = "GST nine percent tax"
        toggle.accessibilityHint = "Toggle GST on or off"
        return toggle
    }()

    private lazy var taxControlsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            makeRow(title: "Service Charge (10%)", control: serviceChargeSwitch),
            makeRow(title: "GST (9%)", control: gstSwitch)
        ])
        stackView.axis = .vertical
        stackView.spacing = 16
        return stackView
    }()

    // MARK: - Party Size
    private let partySizeLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .label
        return label
    }()

    private lazy var partySizeStepper: UIStepper = {
        let stepper = UIStepper()
        stepper.minimumValue = 1
        stepper.maximumValue = 20
        stepper.stepValue = 1
        stepper.value = Double(partySize)
        stepper.addTarget(self, action: #selector(partySizeChanged), for: .valueChanged)
        stepper.accessibilityLabel = "Number of people"
        stepper.accessibilityHint = "Adjust how many people are splitting the bill"
        return stepper
    }()

    private lazy var partyStackView: UIStackView = makeRow(label: partySizeLabel, control: partySizeStepper)

    // MARK: - Rounding
    private lazy var roundingButton: UIButton = {
        let button = makeButton(title: "Rounding", backgroundColor: .systemBlue, titleColour: .white)
        button.showsMenuAsPrimaryAction = true
        button.accessibilityLabel = "Choose rounding option"
        return button
    }()

    // MARK: - Results
    private let subtotalLabel = ViewController.makeResultLabel(style: .body)
    private let serviceChargeAmountLabel = ViewController.makeResultLabel(style: .body)
    private let gstAmountLabel = ViewController.makeResultLabel(style: .body)

    private let totalAmountLabel: UILabel = {
        let label = ViewController.makeResultLabel(style: .title2, colour: .systemGreen)
        label.accessibilityTraits.insert(.summaryElement)
        return label
    }()

    private let perPersonLabel: UILabel = {
        let label = ViewController.makeResultLabel(style: .title2, colour: .systemPink)
        label.accessibilityTraits.insert(.summaryElement)
        return label
    }()

    private let roundingNoteLabel: UILabel = {
        let label = ViewController.makeResultLabel(style: .footnote, colour: .secondaryLabel)
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private lazy var resultsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            subtotalLabel,
            serviceChargeAmountLabel,
            gstAmountLabel,
            totalAmountLabel,
            perPersonLabel,
            roundingNoteLabel
        ])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var resultsContainerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.separator.cgColor
        containerView.addSubview(resultsStackView)
        NSLayoutConstraint.activate([
            resultsStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            resultsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            resultsStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            resultsStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
        return containerView
    }()

    // MARK: - Action Buttons
    private lazy var resetButton: UIButton = {
        let button = makeButton(title: "Reset", backgroundColor: .systemGray5, titleColour: .label)
        button.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        button.accessibilityLabel = "Reset bill"
        return button
    }()

    private lazy var shareButton: UIButton = {
        let button = makeButton(title: "Share", backgroundColor: .systemPink, titleColour: .white)
        button.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        button.accessibilityLabel = "Share split"
        return button
    }()

    private lazy var buttonsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [resetButton, shareButton])
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()

    // MARK: - Main Layout
    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            billAmountTextField,
            taxControlsStackView,
            partyStackView,
            roundingButton,
            resultsContainerView,
            buttonsStackView
        ])
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupLayout()
        setupKeyboardHandling()
        updateRoundingButtonUI()
        updatePartySizeLabel()
        clearAllDisplays()
    }

    // MARK: - Setup
    private func setupView() {
        view.backgroundColor = .systemBackground
        view.layoutMargins = UIEdgeInsets(top: 36, left: 24, bottom: 24, right: 24)
        view.tintColor = .systemPink
        title = "Eat Split"
        view.addSubview(mainStackView)
    }

    private func setupLayout() {
        let margins = view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            mainStackView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            mainStackView.bottomAnchor.constraint(lessThanOrEqualTo: margins.bottomAnchor),

            roundingButton.heightAnchor.constraint(equalToConstant: 50),
            resetButton.heightAnchor.constraint(equalTo: roundingButton.heightAnchor),
            shareButton.heightAnchor.constraint(equalTo: roundingButton.heightAnchor)
        ])
    }

    private func setupKeyboardHandling() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    // MARK: - View Factories
    private func makeRow(title: String, control: UIView) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = .preferredFont(forTextStyle: .body)
        return makeRow(label: label, control: control)
    }

    private func makeRow(label: UILabel, control: UIView) -> UIStackView {
        let spacer = UIView()
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [label, spacer, control])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        return row
    }

    private static func makeResultLabel(style: UIFont.TextStyle, colour: UIColor = .label) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: style)
        label.textColor = colour
        return label
    }

    private func makeButton(title: String, backgroundColor: UIColor, titleColour: UIColor) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseBackgroundColor = backgroundColor
        configuration.baseForegroundColor = titleColour
        configuration.background.cornerRadius = 12
        configuration.cornerStyle = .fixed
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = .preferredFont(forTextStyle: .headline)
            return attributes
        }
        return UIButton(configuration: configuration)
    }

    private func updateRoundingButtonUI() {
        roundingButton.configuration?.title = "Rounding: \(roundingStrategy.title)"
        roundingButton.menu = makeRoundingMenu()
    }

    private func makeRoundingMenu() -> UIMenu {
        let actions = RoundingStrategy.allCases.map { strategy in
            UIAction(title: strategy.title, state: strategy == roundingStrategy ? .on : .off) { [weak self] _ in
                self?.selectRoundingStrategy(strategy)
            }
        }
        return UIMenu(title: "Rounding", children: actions)
    }

    // MARK: - Actions
    @objc private func taxSettingChanged() {
        recalculate()
    }

    @objc private func partySizeChanged() {
        partySize = max(1, Int(partySizeStepper.value))
        updatePartySizeLabel()
        recalculate()
    }

    @objc private func resetTapped() {
        billAmountTextField.resignFirstResponder()
        billAmount = 0
        billAmountTextField.text = ""
        gstSwitch.setOn(true, animated: true)
        serviceChargeSwitch.setOn(true, animated: true)
        partySize = 2
        partySizeStepper.value = Double(partySize)
        updatePartySizeLabel()
        roundingStrategy = .none
        recalculate()
    }

    @objc private func shareTapped() {
        guard let summary = currentSummary else { return }

        dismissKeyboard()

        guard let snapshot = snapshotResultsCard() else {
            presentFallbackShare(for: summary)
            return
        }

        let controller = UIActivityViewController(activityItems: [snapshot], applicationActivities: nil)
        present(controller, animated: true)
    }

    private func selectRoundingStrategy(_ strategy: RoundingStrategy) {
        guard roundingStrategy != strategy else { return }
        roundingStrategy = strategy
        recalculate()
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField === billAmountTextField else { return true }

        let currentText = textField.text ?? ""
        guard let result = CurrencyFormatter.shared.formattedReplacement(currentText: currentText, range: range, replacement: string) else {
            return false
        }

        textField.text = result.formatted

        if let newAmount = result.decimal, newAmount > 0 {
            billAmount = newAmount
            recalculate()
        } else {
            billAmount = 0
            roundingStrategy = .none
            currentSummary = nil
            clearAllDisplays()
        }

        return false
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: - Calculation
    private func recalculate() {
        guard billAmount > 0 else {
            currentSummary = nil
            return
        }

        let summary = BillModel(
            billAmount: billAmount,
            gstEnabled: gstSwitch.isOn,
            serviceEnabled: serviceChargeSwitch.isOn,
            serviceRate: 0.10,
            gstRate: 0.09,
            partySize: partySize,
            roundingStrategy: roundingStrategy
        )

        currentSummary = summary
    }

    private func updateCalculationDisplay() {
        guard let summary = currentSummary else {
            if !billAmountTextField.isFirstResponder {
                billAmountTextField.text = billAmount > 0 ? CurrencyFormatter.shared.string(from: billAmount) : ""
            }
            clearAllDisplays()
            return
        }

        let formatter = CurrencyFormatter.shared

        subtotalLabel.text = "Subtotal: \(formatter.string(from: summary.subtotal))"
        serviceChargeAmountLabel.text = "Service (10%): \(formatter.string(from: summary.serviceChargeAmount))"
        gstAmountLabel.text = "GST (9%): \(formatter.string(from: summary.gstAmount))"

        let total = summary.displayTotal
        let perPerson = summary.displayPerPerson

        totalAmountLabel.text = "Total: \(formatter.string(from: total))"
        let splitLabel = "Split Between \(summary.partySize)"
        perPersonLabel.text = "\(splitLabel): \(formatter.string(from: perPerson))"

        roundingNoteLabel.text = summary.roundingDescription(using: formatter)
        roundingNoteLabel.isHidden = roundingNoteLabel.text == nil

        if !billAmountTextField.isFirstResponder {
            billAmountTextField.text = formatter.string(from: billAmount)
        }

        animateCalculationUpdate()
    }

    private func clearAllDisplays() {
        let zero = CurrencyFormatter.shared.string(from: 0)
        subtotalLabel.text = "Subtotal: \(zero)"
        serviceChargeAmountLabel.text = "Service (10%): \(zero)"
        gstAmountLabel.text = "GST (9%): \(zero)"
        totalAmountLabel.text = "Total: \(zero)"
        perPersonLabel.text = "Split Between \(partySize): \(zero)"
        roundingNoteLabel.isHidden = true
    }

    private func animateCalculationUpdate() {
        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       options: [.curveEaseInOut, .allowUserInteraction]) {
            self.totalAmountLabel.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
            self.perPersonLabel.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        } completion: { _ in
            UIView.animate(withDuration: 0.2,
                           delay: 0,
                           options: [.curveEaseInOut, .allowUserInteraction]) {
                self.totalAmountLabel.transform = .identity
                self.perPersonLabel.transform = .identity
            }
        }
    }

    private func updatePartySizeLabel() {
        let descriptor = partySize == 1 ? "person" : "people"
        partySizeLabel.text = "\(partySize) \(descriptor)"
    }

    private func snapshotResultsCard() -> UIImage? {
        resultsContainerView.layoutIfNeeded()

        return UIGraphicsImageRenderer(bounds: resultsContainerView.bounds).image { context in
            resultsContainerView.drawHierarchy(in: resultsContainerView.bounds, afterScreenUpdates: true)
        }
    }

    private func presentFallbackShare(for summary: BillModel) {
        let formatter = CurrencyFormatter.shared
        let total = summary.displayTotal
        let perPerson = summary.displayPerPerson

        let message = """
        Bill: \(formatter.string(from: summary.subtotal))
        Service: \(formatter.string(from: summary.serviceChargeAmount))
        GST: \(formatter.string(from: summary.gstAmount))
        Total: \(formatter.string(from: total))
        Each: \(formatter.string(from: perPerson))
        """

        let controller = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = shareButton
        controller.popoverPresentationController?.sourceRect = shareButton.bounds
        present(controller, animated: true)
    }
}
