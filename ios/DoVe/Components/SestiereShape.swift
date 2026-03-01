import SwiftUI

/// Disegna la silhouette geografica reale di un sestiere.
struct SestiereShape: Shape {
    let sestiere: Sestiere

    func path(in rect: CGRect) -> Path {
        guard let shapeData = SestiereShapeData.shared.shape(for: sestiere) else {
            return Path(ellipseIn: rect)
        }

        let points = shapeData.points
        guard points.count >= 3 else { return Path() }

        // Calcola il bounding box mantenendo aspect ratio
        let shapeAspect = shapeData.aspectRatio
        let rectAspect = rect.width / rect.height

        let drawWidth: CGFloat
        let drawHeight: CGFloat
        let offsetX: CGFloat
        let offsetY: CGFloat

        if shapeAspect > rectAspect {
            // Shape più larga del rect: fit per width
            drawWidth = rect.width
            drawHeight = rect.width / shapeAspect
            offsetX = rect.minX
            offsetY = rect.minY + (rect.height - drawHeight) / 2
        } else {
            // Shape più alta del rect: fit per height
            drawHeight = rect.height
            drawWidth = rect.height * shapeAspect
            offsetX = rect.minX + (rect.width - drawWidth) / 2
            offsetY = rect.minY
        }

        var path = Path()
        for (index, point) in points.enumerated() {
            let x = offsetX + point[0] * drawWidth
            let y = offsetY + point[1] * drawHeight

            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()

        return path
    }
}

// MARK: - Data loading

struct SestiereShapeInfo {
    let points: [[CGFloat]]
    let aspectRatio: CGFloat
}

final class SestiereShapeData: Sendable {
    static let shared = SestiereShapeData()

    private let shapes: [String: SestiereShapeInfo]

    private init() {
        guard let url = Bundle.main.url(forResource: "sestieri_shapes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]]
        else {
            shapes = [:]
            return
        }

        var result: [String: SestiereShapeInfo] = [:]
        for (key, value) in json {
            guard let pointsRaw = value["points"] as? [[Double]],
                  let aspect = value["aspectRatio"] as? Double
            else { continue }

            let points = pointsRaw.map { $0.map { CGFloat($0) } }
            result[key] = SestiereShapeInfo(points: points, aspectRatio: CGFloat(aspect))
        }
        shapes = result
    }

    func shape(for sestiere: Sestiere) -> SestiereShapeInfo? {
        shapes[sestiere.rawValue]
    }
}
