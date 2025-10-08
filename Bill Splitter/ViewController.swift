import UIKit

final class ViewController: UIViewController, UITextFieldDelegate {
    // MARK: - UI Elements
    private let mainStackView = UIStackView()
    private let titleLabel = UILabel()
    private let billAmountTextField = UITextField()
    private let taxControlsStackView = UIStackView()
    private let gstRow = UIStackView()
    private let serviceRow = UIStackView()
    private let gstTitleLabel = UILabel()
    private let serviceTitleLabel = UILabel()
    private let gstSwitch = UISwitch()
    private let serviceChargeSwitch = UISwitch()
    private let partyStackView = UIStackView()
    private let partySizeLabel = UILabel()
    private let partySizeStepper = UIStepper()
    private let resultsContainerView = UIView()
    private let resultsStackView = UIStackView()
    private let subtotalLabel = UILabel()
    private let gstAmountLabel = UILabel()
    private let serviceChargeAmountLabel = UILabel()
    private let totalAmountLabel = UILabel()
    private let perPersonLabel = UILabel()
    private let roundingNoteLabel = UILabel()
    private let buttonsStackView = UIStackView()
    private let roundingButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)

    // MARK: - State
    private var billAmount: Decimal = 0
    private var partySize: Int = 2
    private var currentSummary: BillModel? { didSet { updateCalculationDisplay() } }
    private var roundingStrategy: RoundingStrategy = .none {
        didSet { updateRoundingButtonUI() }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupLayout()
        setupAccessibility()
        setupKeyboardHandling()
        updatePartySizeLabel()
        clearAllDisplays()
    }

    // MARK: - Setup
    private func setupView() {
        view.backgroundColor = .systemBackground
        view.layoutMargins = UIEdgeInsets(top: 36, left: 24, bottom: 24, right: 24)
        view.tintColor = .systemPink
        title = "Eat Split"

        mainStackView.axis = .vertical
        mainStackView.spacing = 24
        mainStackView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = "Eat Split"
        titleLabel.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .systemPink

        billAmountTextField.placeholder = "Enter bill amount (SGD)"
        billAmountTextField.keyboardType = .decimalPad
        billAmountTextField.borderStyle = .none
        billAmountTextField.layer.cornerRadius = 12
        billAmountTextField.backgroundColor = UIColor.systemGray6
        billAmountTextField.textAlignment = .center
        billAmountTextField.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
        billAmountTextField.delegate = self

        taxControlsStackView.axis = .vertical
        taxControlsStackView.spacing = 16

        configureTaxRow(label: serviceTitleLabel, title: "Service Charge (10%)", toggle: serviceChargeSwitch, container: serviceRow)
        configureTaxRow(label: gstTitleLabel, title: "GST (9%)", toggle: gstSwitch, container: gstRow)

        gstSwitch.isOn = true
        serviceChargeSwitch.isOn = true
        gstSwitch.addTarget(self, action: #selector(taxSettingChanged), for: .valueChanged)
        serviceChargeSwitch.addTarget(self, action: #selector(taxSettingChanged), for: .valueChanged)

        partyStackView.axis = .horizontal
        partyStackView.spacing = 12
        partyStackView.alignment = .center

        partySizeLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        partySizeLabel.textColor = .label

        let partySpacer = UIView()
        partySpacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        partySizeStepper.minimumValue = 1
        partySizeStepper.maximumValue = 20
        partySizeStepper.stepValue = 1
        partySizeStepper.value = Double(partySize)
        partySizeStepper.addTarget(self, action: #selector(partySizeChanged), for: .valueChanged)

        partyStackView.addArrangedSubview(partySizeLabel)
        partyStackView.addArrangedSubview(partySpacer)
        partyStackView.addArrangedSubview(partySizeStepper)

        resultsContainerView.backgroundColor = .secondarySystemBackground
        resultsContainerView.layer.cornerRadius = 16
        resultsContainerView.layer.borderWidth = 1
        resultsContainerView.layer.borderColor = UIColor.separator.cgColor
        resultsContainerView.translatesAutoresizingMaskIntoConstraints = false

        resultsStackView.axis = .vertical
        resultsStackView.spacing = 8
        resultsStackView.translatesAutoresizingMaskIntoConstraints = false

        subtotalLabel.font = UIFont.preferredFont(forTextStyle: .body)
        gstAmountLabel.font = UIFont.preferredFont(forTextStyle: .body)
        serviceChargeAmountLabel.font = UIFont.preferredFont(forTextStyle: .body)

        totalAmountLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        totalAmountLabel.textColor = .systemGreen

        perPersonLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        perPersonLabel.textColor = .systemPink

        roundingNoteLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        roundingNoteLabel.textColor = .secondaryLabel
        roundingNoteLabel.numberOfLines = 0
        roundingNoteLabel.isHidden = true

        resultsStackView.addArrangedSubview(subtotalLabel)
        resultsStackView.addArrangedSubview(serviceChargeAmountLabel)
        resultsStackView.addArrangedSubview(gstAmountLabel)
        resultsStackView.addArrangedSubview(totalAmountLabel)
        resultsStackView.addArrangedSubview(perPersonLabel)
        resultsStackView.addArrangedSubview(roundingNoteLabel)

        buttonsStackView.axis = .horizontal
        buttonsStackView.spacing = 12
        buttonsStackView.distribution = .fillEqually

        styleButton(roundingButton, title: "Rounding", backgroundColor: .systemBlue, titleColour: .white)
        styleButton(resetButton, title: "Reset", backgroundColor: .systemGray5, titleColour: .label)
        styleButton(shareButton, title: "Share", backgroundColor: .systemPink, titleColour: .white)

        roundingButton.showsMenuAsPrimaryAction = true
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)

        buttonsStackView.addArrangedSubview(roundingButton)
        buttonsStackView.addArrangedSubview(resetButton)
        buttonsStackView.addArrangedSubview(shareButton)

        updateRoundingButtonUI()

        let roundingControlStack = UIStackView(arrangedSubviews: [roundingButton])
        roundingControlStack.axis = .horizontal
        roundingControlStack.alignment = .fill
        roundingControlStack.distribution = .fillEqually

        [titleLabel,
         billAmountTextField,
         taxControlsStackView,
         partyStackView,
         roundingControlStack,
         resultsContainerView,
         buttonsStackView].forEach { mainStackView.addArrangedSubview($0) }

        view.addSubview(mainStackView)
        resultsContainerView.addSubview(resultsStackView)
    }

    private func setupLayout() {
        let margins = view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            mainStackView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            mainStackView.bottomAnchor.constraint(lessThanOrEqualTo: margins.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            resultsStackView.leadingAnchor.constraint(equalTo: resultsContainerView.leadingAnchor, constant: 16),
            resultsStackView.trailingAnchor.constraint(equalTo: resultsContainerView.trailingAnchor, constant: -16),
            resultsStackView.topAnchor.constraint(equalTo: resultsContainerView.topAnchor, constant: 16),
            resultsStackView.bottomAnchor.constraint(equalTo: resultsContainerView.bottomAnchor, constant: -16),
            roundingButton.heightAnchor.constraint(equalToConstant: 50),
            resetButton.heightAnchor.constraint(equalTo: roundingButton.heightAnchor),
            shareButton.heightAnchor.constraint(equalTo: roundingButton.heightAnchor),
        ])
    }

    private func setupAccessibility() {
        billAmountTextField.accessibilityLabel = "Bill amount in Singapore dollars"
        billAmountTextField.accessibilityHint = "Enter the total bill before taxes"

        gstSwitch.accessibilityLabel = "GST nine percent tax"
        gstSwitch.accessibilityHint = "Toggle GST on or off"
        serviceChargeSwitch.accessibilityLabel = "Service charge ten percent"
        serviceChargeSwitch.accessibilityHint = "Toggle service charge on or off"

        partySizeStepper.accessibilityLabel = "Number of people"
        partySizeStepper.accessibilityHint = "Adjust how many people are splitting the bill"

        totalAmountLabel.accessibilityTraits.insert(.summaryElement)
        perPersonLabel.accessibilityTraits.insert(.summaryElement)

        roundingButton.accessibilityLabel = "Choose rounding option"
        resetButton.accessibilityLabel = "Reset bill"
        shareButton.accessibilityLabel = "Share split"
    }

    private func setupKeyboardHandling() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    private func configureTaxRow(label: UILabel, title: String, toggle: UISwitch, container: UIStackView) {
        label.text = title
        label.font = UIFont.preferredFont(forTextStyle: .body)

        container.axis = .horizontal
        container.alignment = .center
        container.spacing = 12

        let spacer = UIView()
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        container.addArrangedSubview(label)
        container.addArrangedSubview(spacer)
        container.addArrangedSubview(toggle)

        taxControlsStackView.addArrangedSubview(container)
    }

    private func styleButton(_ button: UIButton, title: String, backgroundColor: UIColor, titleColour: UIColor) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(titleColour, for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    }

    private func updateRoundingButtonUI() {
        roundingButton.setTitle("Rounding: \(roundingStrategy.title)", for: .normal)
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
