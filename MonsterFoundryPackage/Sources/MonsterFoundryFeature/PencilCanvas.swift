import PencilKit
import SwiftUI
import UIKit

enum DrawingTool: String, CaseIterable, Identifiable {
    case fountainPen
    case ink
    case monoline
    case marker
    case sketch
    case crayon
    case watercolor
    case eraser

    var id: Self { self }

    var symbol: String {
        switch self {
        case .fountainPen: "pencil.and.outline"
        case .ink: "applepencil.tip"
        case .monoline: "line.diagonal"
        case .marker: "highlighter"
        case .sketch: "pencil"
        case .crayon: "scribble"
        case .watercolor: "paintbrush.pointed"
        case .eraser: "eraser.fill"
        }
    }

    var title: String {
        switch self {
        case .fountainPen: "Fountain"
        case .ink: "Ink"
        case .monoline: "Monoline"
        case .marker: "Marker"
        case .sketch: "Sketch"
        case .crayon: "Crayon"
        case .watercolor: "Watercolor"
        case .eraser: "Eraser"
        }
    }

    var defaultWidth: Double {
        switch self {
        case .fountainPen: 6
        case .ink: 7
        case .monoline: 5
        case .marker: 22
        case .sketch: 5
        case .crayon: 14
        case .watercolor: 24
        case .eraser: 30
        }
    }

    var defaultOpacity: Double {
        switch self {
        case .marker: 0.65
        case .sketch: 0.72
        case .crayon: 0.82
        case .watercolor: 0.52
        default: 1
        }
    }

    var widthRange: ClosedRange<Double> {
        switch self {
        case .fountainPen, .ink, .monoline: 1...20
        case .marker, .watercolor: 6...60
        case .sketch: 1...28
        case .crayon: 3...48
        case .eraser: 8...80
        }
    }
}

struct PencilCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var tool: DrawingTool
    var color: UIColor
    var width: Double
    var opacity: Double
    var command: CanvasCommand?

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView(frame: .zero)
        canvas.delegate = context.coordinator
        canvas.drawing = drawing
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.alwaysBounceVertical = false
        canvas.alwaysBounceHorizontal = false
        canvas.isScrollEnabled = false
        canvas.contentInset = .zero
        canvas.contentInsetAdjustmentBehavior = .never
        canvas.drawingPolicy = .anyInput
        canvas.minimumZoomScale = 1
        canvas.maximumZoomScale = 1
        applyTool(on: canvas)
        context.coordinator.lastToolToken = toolToken
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        if canvas.drawing != drawing {
            canvas.drawing = drawing
        }
        if context.coordinator.lastToolToken != toolToken {
            applyTool(on: canvas)
            context.coordinator.lastToolToken = toolToken
        }

        guard let command, context.coordinator.lastCommandID != command.id else { return }
        context.coordinator.lastCommandID = command.id
        switch command.kind {
        case .undo:
            canvas.undoManager?.undo()
        case .redo:
            canvas.undoManager?.redo()
        }
        drawing = canvas.drawing
    }

    private var toolToken: String {
        "\(tool.rawValue)|\(color.description)|\(width)|\(opacity)"
    }

    private func applyTool(on canvas: PKCanvasView) {
        let inkColor = color.withAlphaComponent(CGFloat(max(0.08, min(opacity, 1))))
        switch tool {
        case .fountainPen:
            canvas.tool = PKInkingTool(.fountainPen, color: inkColor, width: width)
        case .ink:
            canvas.tool = PKInkingTool(.pen, color: inkColor, width: width)
        case .monoline:
            canvas.tool = PKInkingTool(.monoline, color: inkColor, width: width)
        case .marker:
            canvas.tool = PKInkingTool(.marker, color: inkColor, width: width)
        case .sketch:
            canvas.tool = PKInkingTool(.pencil, color: inkColor, width: width)
        case .crayon:
            canvas.tool = PKInkingTool(.crayon, color: inkColor, width: width)
        case .watercolor:
            canvas.tool = PKInkingTool(.watercolor, color: inkColor, width: width)
        case .eraser:
            canvas.tool = PKEraserTool(.bitmap, width: width)
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        private var drawing: Binding<PKDrawing>
        var lastCommandID: UUID?
        var lastToolToken: String?

        init(drawing: Binding<PKDrawing>) {
            self.drawing = drawing
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing.wrappedValue = canvasView.drawing
        }
    }
}

struct CanvasCommand: Equatable {
    enum Kind {
        case undo
        case redo
    }

    let id = UUID()
    let kind: Kind
}

extension PKDrawing {
    @MainActor
    func monsterJPEGData(size: CGFloat = 1_280) -> Data? {
        guard !strokes.isEmpty else { return nil }

        let contentBounds = bounds.insetBy(dx: -40, dy: -40)
        let sourceImage = image(from: contentBounds, scale: 2)
        let outputSize = CGSize(width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: outputSize)

        let rendered = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: outputSize))

            let usable = outputSize.width * 0.82
            let scale = min(usable / sourceImage.size.width, usable / sourceImage.size.height)
            let targetSize = CGSize(width: sourceImage.size.width * scale, height: sourceImage.size.height * scale)
            let targetRect = CGRect(
                x: (outputSize.width - targetSize.width) / 2,
                y: (outputSize.height - targetSize.height) / 2,
                width: targetSize.width,
                height: targetSize.height
            )
            sourceImage.draw(in: targetRect)
        }

        return rendered.jpegData(compressionQuality: 0.88)
    }
}
