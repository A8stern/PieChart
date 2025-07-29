// The Swift Programming Language
// https://docs.swift.org/swift-book

//
//  PieChart.swift
//  Yandex_SMD_Summer_2025
//
//  Created by Kovalev Gleb on 29.07.2025.
//

import Foundation
import UIKit

public struct Entity: Equatable {
    public let value: Decimal
    public let label: String

    public init(value: Decimal, label: String) {
        self.value = value
        self.label = label
    }
}

public final class PieChart: UIView {
    static let size: CGFloat = 150
    
    private enum Constants {
        static let radius: CGFloat = 75
        static let fontSize: CGFloat = 7
        static let legendSpacing: CGFloat = 14
        static let legendStartYOffset: CGFloat = -40
        static let legendCircleSize: CGFloat = 6
    }
    
    private let segmentColors: [UIColor] = [
        .systemGreen,
        .systemYellow,
        .systemBlue,
        .systemOrange,
        .systemPurple,
        .systemGray
    ]
    
    public var entities: [Entity] = [] {
        didSet {
            animateChartChange()
        }
    }
    
    private var displayEntities: [Entity] = []
    private var totalValue: Decimal = 0
    private var oldEntities: [Entity] = []
    
    private var displayLink: CADisplayLink?
    private var animationProgress: CGFloat = 0
    private var isAnimating = false
    
    public init() {
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: Self.size, height: Self.size)))
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        frame = CGRect(origin: .zero, size: CGSize(width: Self.size, height: Self.size))
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        contentMode = .redraw
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Self.size),
            heightAnchor.constraint(equalToConstant: Self.size)
        ])
    }
    
    public override func draw(_ rect: CGRect) {
        guard !entities.isEmpty || isAnimating else { return }

        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let outerRadius = Constants.radius
        let innerRadius = outerRadius - 8

        let data = isAnimating ? oldEntities : entities
        prepareDisplayData(from: data)

        let sum = totalValue == 0 ? 1 : totalValue
        var startAngle: CGFloat = -.pi / 2

        for (index, entity) in displayEntities.enumerated() {
            let fraction = CGFloat((entity.value / sum as NSDecimalNumber).doubleValue)
            let endAngle = startAngle + fraction * .pi * 2
            let color = segmentColors[index % segmentColors.count]

            let path = UIBezierPath()
            path.addArc(withCenter: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            path.addArc(withCenter: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: false)
            path.close()

            color.setFill()
            path.fill()

            drawLegend(for: entity, at: index, center: center)

            startAngle = endAngle
        }

        context?.restoreGState()
    }
    
    private func prepareDisplayData(from data: [Entity]) {
        totalValue = data.reduce(0) { $0 + $1.value }
        
        if data.count <= 5 {
            displayEntities = data
        } else {
            let firstFive = data.prefix(5)
            let others = data.dropFirst(5)
            let othersSum = others.reduce(Decimal(0)) { $0 + $1.value }
            displayEntities = Array(firstFive) + [Entity(value: othersSum, label: "Остальные")]
        }
    }
    
    private func drawLegend(for entity: Entity, at index: Int, center: CGPoint) {
        let yOffset = center.y + Constants.legendStartYOffset + CGFloat(index) * Constants.legendSpacing
        let xOffset: CGFloat = center.x - 40
        
        let circleRect = CGRect(x: xOffset,
                                y: yOffset + 2,
                                width: Constants.legendCircleSize,
                                height: Constants.legendCircleSize)
        let circlePath = UIBezierPath(ovalIn: circleRect)
        segmentColors[index % segmentColors.count].setFill()
        circlePath.fill()
        
        let percent = Int((entity.value / totalValue as NSDecimalNumber).doubleValue * 100)
        let text = "\(percent)% \(entity.label)"
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: Constants.fontSize),
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraph
        ]
        
        let textRect = CGRect(x: xOffset + 10, y: yOffset, width: 90, height: 10)
        NSAttributedString(string: text, attributes: attributes).draw(in: textRect)
    }
    
    private func animateChartChange() {
        guard !isAnimating else { return }
        oldEntities = displayEntities
        isAnimating = true
        animationProgress = 0
        
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(handleAnimationFrame))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func handleAnimationFrame() {
        animationProgress += 0.02
        
        if animationProgress >= 1 {
            displayLink?.invalidate()
            isAnimating = false
            transform = .identity
            alpha = 1
            setNeedsDisplay()
            return
        }
        
        let angle = CGFloat(animationProgress) * .pi * 2
        transform = CGAffineTransform(rotationAngle: angle)
        alpha = animationProgress < 0.5 ? 1 - animationProgress * 2 : (animationProgress - 0.5) * 2
        
        if animationProgress >= 0.5 && oldEntities == displayEntities {
            oldEntities = []
            setNeedsDisplay()
        }
    }
}
