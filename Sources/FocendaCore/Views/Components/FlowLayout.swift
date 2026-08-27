import SwiftUI

/// A native SwiftUI `Layout` container that arranges its subviews in a flowing, wrapping row-by-row layout.
///
/// When horizontal space is constrained, items wrap onto subsequent lines based on their intrinsic sizes.
public struct FlowLayout: Layout {
    public var spacing: CGFloat
    public var lineSpacing: CGFloat
    public var horizontalAlignment: HorizontalAlignment
    public var verticalAlignment: VerticalAlignment

    public init(
        spacing: CGFloat = 8,
        lineSpacing: CGFloat = 8,
        horizontalAlignment: HorizontalAlignment = .leading,
        verticalAlignment: VerticalAlignment = .center
    ) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let maxWidth = proposal.width ?? .infinity
        let result = Self.calculateLayout(
            itemSizes: sizes,
            maxWidth: maxWidth,
            spacing: spacing,
            lineSpacing: lineSpacing
        )
        return result.size
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let result = Self.calculateLayout(
            itemSizes: sizes,
            maxWidth: bounds.width,
            spacing: spacing,
            lineSpacing: lineSpacing
        )
        guard !result.rows.isEmpty else { return }

        var currentY = bounds.minY

        for row in result.rows {
            var currentX: CGFloat
            switch horizontalAlignment {
            case .leading:
                currentX = bounds.minX
            case .trailing:
                currentX = bounds.maxX - row.width
            case .center:
                currentX = bounds.minX + max(0, (bounds.width - row.width) / 2)
            default:
                currentX = bounds.minX
            }

            for (itemIndex, itemSize) in zip(row.itemIndices, row.itemSizes) {
                let subview = subviews[itemIndex]
                let itemY: CGFloat
                switch verticalAlignment {
                case .top:
                    itemY = currentY
                case .bottom:
                    itemY = currentY + (row.height - itemSize.height)
                case .center:
                    itemY = currentY + (row.height - itemSize.height) / 2
                default:
                    itemY = currentY + (row.height - itemSize.height) / 2
                }

                subview.place(
                    at: CGPoint(x: currentX, y: itemY),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(itemSize)
                )

                currentX += itemSize.width + spacing
            }

            currentY += row.height + lineSpacing
        }
    }

    // MARK: - Layout Calculation Engine

    public struct Row: Equatable {
        public let itemIndices: [Int]
        public let itemSizes: [CGSize]
        public let width: CGFloat
        public let height: CGFloat

        public init(itemIndices: [Int], itemSizes: [CGSize], width: CGFloat, height: CGFloat) {
            self.itemIndices = itemIndices
            self.itemSizes = itemSizes
            self.width = width
            self.height = height
        }
    }

    public struct LayoutResult: Equatable {
        public let rows: [Row]
        public let size: CGSize

        public init(rows: [Row], size: CGSize) {
            self.rows = rows
            self.size = size
        }
    }

    /// Computes the flow layout rows and total required size for a given set of item sizes and maximum row width.
    public static func calculateLayout(
        itemSizes: [CGSize],
        maxWidth: CGFloat,
        spacing: CGFloat = 8,
        lineSpacing: CGFloat = 8
    ) -> LayoutResult {
        guard !itemSizes.isEmpty else {
            return LayoutResult(rows: [], size: .zero)
        }

        var rows: [Row] = []
        var currentIndices: [Int] = []
        var currentSizes: [CGSize] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0

        for (index, itemSize) in itemSizes.enumerated() {
            let proposedWidth: CGFloat
            if currentIndices.isEmpty {
                proposedWidth = itemSize.width
            } else {
                proposedWidth = currentWidth + spacing + itemSize.width
            }

            if !currentIndices.isEmpty && proposedWidth > maxWidth {
                rows.append(Row(
                    itemIndices: currentIndices,
                    itemSizes: currentSizes,
                    width: currentWidth,
                    height: currentHeight
                ))
                currentIndices = []
                currentSizes = []
                currentWidth = 0
                currentHeight = 0
            }

            let itemSpacing = currentIndices.isEmpty ? 0 : spacing
            currentIndices.append(index)
            currentSizes.append(itemSize)
            currentWidth += itemSpacing + itemSize.width
            currentHeight = max(currentHeight, itemSize.height)
        }

        if !currentIndices.isEmpty {
            rows.append(Row(
                itemIndices: currentIndices,
                itemSizes: currentSizes,
                width: currentWidth,
                height: currentHeight
            ))
        }

        let totalHeight = rows.map(\.height).reduce(0, +) + CGFloat(max(0, rows.count - 1)) * lineSpacing
        let maxRowWidth = rows.map(\.width).max() ?? 0

        return LayoutResult(
            rows: rows,
            size: CGSize(width: maxRowWidth, height: totalHeight)
        )
    }
}
